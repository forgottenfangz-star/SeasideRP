-- Kiwi CAD 0006: harden commerce and virtual economy.
create or replace function public.claim_primary_organization()
returns uuid language plpgsql security definer set search_path=public as $$
declare org_id uuid; owner_role uuid; membership_id uuid;
begin
 if auth.uid() is null then raise exception 'Not authenticated'; end if;
 select id into org_id from public.organizations where is_primary=true and created_by is null limit 1 for update;
 if org_id is null then raise exception 'Primary organization has already been claimed'; end if;
 update public.organizations set created_by=auth.uid() where id=org_id and created_by is null;
 select id into membership_id from public.organization_memberships where organization_id=org_id and user_id=auth.uid();
 if membership_id is null then insert into public.organization_memberships(organization_id,user_id,status) values(org_id,auth.uid(),'active') returning id into membership_id; end if;
 select id into owner_role from public.organization_roles where organization_id=org_id and name='Owner' limit 1;
 if owner_role is not null then insert into public.organization_member_roles(membership_id,role_id,assigned_by) values(membership_id,owner_role,auth.uid()) on conflict do nothing; end if;
 return org_id;
end; $$;

create or replace function public.transfer_virtual_aud(target_org uuid, recipient uuid, amount_cents bigint, note text default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare sender_wallet uuid; recipient_wallet uuid; sender_balance bigint; tx uuid;
begin
 if auth.uid() is null or amount_cents <= 0 or recipient=auth.uid() then raise exception 'Invalid transfer'; end if;
 if not public.is_org_member(target_org) then raise exception 'Not an organization member'; end if;
 if not exists(select 1 from public.organization_memberships where organization_id=target_org and user_id=recipient and status='active') then raise exception 'Recipient is not an organization member'; end if;
 insert into public.wallets(organization_id,user_id) values(target_org,auth.uid()) on conflict(organization_id,user_id) do nothing;
 insert into public.wallets(organization_id,user_id) values(target_org,recipient) on conflict(organization_id,user_id) do nothing;
 select id,balance_cents into sender_wallet,sender_balance from public.wallets where organization_id=target_org and user_id=auth.uid() for update;
 select id into recipient_wallet from public.wallets where organization_id=target_org and user_id=recipient for update;
 if sender_balance < amount_cents then raise exception 'Insufficient virtual AUD'; end if;
 update public.wallets set balance_cents=balance_cents-amount_cents,updated_at=now() where id=sender_wallet;
 update public.wallets set balance_cents=balance_cents+amount_cents,updated_at=now() where id=recipient_wallet;
 insert into public.wallet_transactions(organization_id,wallet_id,sender_user_id,recipient_user_id,amount_cents,transaction_type,description) values(target_org,sender_wallet,auth.uid(),recipient,amount_cents,'transfer',note) returning id into tx;
 return tx;
end; $$;

create or replace function public.purchase_business(target_org uuid,target_business uuid)
returns uuid language plpgsql security definer set search_path=public as $$
declare b public.businesses%rowtype; wallet public.wallets%rowtype; price bigint; tx uuid;
begin
 if auth.uid() is null or not public.is_org_member(target_org) then raise exception 'Not authorized'; end if;
 select * into b from public.businesses where id=target_business and organization_id=target_org and status='for_sale' for update;
 if not found then raise exception 'Business is not for sale'; end if;
 price:=coalesce(b.sale_price_cents,0); if price<=0 then raise exception 'Business has no sale price'; end if;
 insert into public.wallets(organization_id,user_id) values(target_org,auth.uid()) on conflict(organization_id,user_id) do nothing;
 select * into wallet from public.wallets where organization_id=target_org and user_id=auth.uid() for update;
 if wallet.balance_cents<price then raise exception 'Insufficient virtual AUD'; end if;
 update public.wallets set balance_cents=balance_cents-price,updated_at=now() where id=wallet.id;
 update public.businesses set owner_user_id=auth.uid(),status='active',sale_price_cents=null,updated_at=now() where id=b.id;
 insert into public.business_transactions(organization_id,business_id,buyer_user_id,seller_user_id,amount_cents,transaction_type) values(target_org,b.id,auth.uid(),b.owner_user_id,price,'purchase') returning id into tx;
 return tx;
end; $$;

create or replace function public.book_service(target_org uuid,target_provider uuid,scheduled_at_value timestamptz default null,pickup text default null,destination text default null,notes_value text default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare p public.service_providers%rowtype; w public.wallets%rowtype; booking_id uuid;
begin
 if auth.uid() is null or not public.is_org_member(target_org) then raise exception 'Not authorized'; end if;
 select * into p from public.service_providers where id=target_provider and organization_id=target_org and active=true for update;
 if not found then raise exception 'Service provider is unavailable'; end if;
 insert into public.wallets(organization_id,user_id) values(target_org,auth.uid()) on conflict(organization_id,user_id) do nothing;
 select * into w from public.wallets where organization_id=target_org and user_id=auth.uid() for update;
 if w.balance_cents<p.price_cents then raise exception 'Insufficient virtual AUD'; end if;
 insert into public.service_bookings(organization_id,provider_id,customer_user_id,booking_type,status,scheduled_at,pickup_address,destination_address,notes,amount_cents)
 values(target_org,p.id,auth.uid(),p.provider_type,'requested',scheduled_at_value,nullif(trim(pickup),''),nullif(trim(destination),''),nullif(trim(notes_value),''),p.price_cents) returning id into booking_id;
 update public.wallets set balance_cents=balance_cents-p.price_cents,updated_at=now() where id=w.id;
 insert into public.wallet_transactions(organization_id,wallet_id,sender_user_id,amount_cents,transaction_type,description,reference_type,reference_id) values(target_org,w.id,auth.uid(),p.price_cents,'booking','Service booking','service_booking',booking_id);
 return booking_id;
end; $$;

create or replace function public.cancel_service_booking(target_booking uuid)
returns boolean language plpgsql security definer set search_path=public as $$
declare b public.service_bookings%rowtype; w public.wallets%rowtype;
begin
 select * into b from public.service_bookings where id=target_booking for update;
 if not found then raise exception 'Booking not found'; end if;
 if auth.uid() is null or (b.customer_user_id<>auth.uid() and not public.has_org_permission(b.organization_id,'dispatch.incidents.manage')) then raise exception 'Not authorized'; end if;
 if b.status not in ('requested','confirmed') then raise exception 'Booking cannot be cancelled'; end if;
 update public.service_bookings set status='cancelled',updated_at=now() where id=b.id;
 insert into public.wallets(organization_id,user_id) values(b.organization_id,b.customer_user_id) on conflict(organization_id,user_id) do nothing;
 select * into w from public.wallets where organization_id=b.organization_id and user_id=b.customer_user_id for update;
 update public.wallets set balance_cents=balance_cents+b.amount_cents,updated_at=now() where id=w.id;
 insert into public.wallet_transactions(organization_id,wallet_id,recipient_user_id,amount_cents,transaction_type,description,reference_type,reference_id) values(b.organization_id,w.id,b.customer_user_id,b.amount_cents,'refund','Cancelled service booking','service_booking',b.id);
 return true;
end; $$;

grant execute on function public.purchase_business(uuid,uuid) to authenticated;
grant execute on function public.book_service(uuid,uuid,timestamptz,text,text,text) to authenticated;
grant execute on function public.cancel_service_booking(uuid) to authenticated;