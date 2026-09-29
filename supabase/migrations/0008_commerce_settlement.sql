-- Kiwi CAD 0008: settle seller proceeds for player-to-player commerce.
create or replace function public.purchase_business(target_org uuid,target_business uuid)
returns uuid language plpgsql security definer set search_path=public as $$
declare b public.businesses%rowtype; buyer_wallet public.wallets%rowtype; seller_wallet public.wallets%rowtype; price bigint; tx uuid;
begin
 if auth.uid() is null or not public.is_org_member(target_org) then raise exception 'Not authorized'; end if;
 select * into b from public.businesses where id=target_business and organization_id=target_org and status='for_sale' for update;
 if not found then raise exception 'Business is not for sale'; end if;
 price:=coalesce(b.sale_price_cents,0); if price<=0 then raise exception 'Business has no sale price'; end if;
 if b.owner_user_id=auth.uid() then raise exception 'You already own this business'; end if;
 insert into public.wallets(organization_id,user_id) values(target_org,auth.uid()) on conflict(organization_id,user_id) do nothing;
 select * into buyer_wallet from public.wallets where organization_id=target_org and user_id=auth.uid() for update;
 if buyer_wallet.balance_cents<price then raise exception 'Insufficient virtual AUD'; end if;
 update public.wallets set balance_cents=balance_cents-price,updated_at=now() where id=buyer_wallet.id;
 if b.owner_user_id is not null then
   insert into public.wallets(organization_id,user_id) values(target_org,b.owner_user_id) on conflict(organization_id,user_id) do nothing;
   select * into seller_wallet from public.wallets where organization_id=target_org and user_id=b.owner_user_id for update;
   update public.wallets set balance_cents=balance_cents+price,updated_at=now() where id=seller_wallet.id;
   insert into public.wallet_transactions(organization_id,wallet_id,recipient_user_id,amount_cents,transaction_type,description,reference_type)
   values(target_org,seller_wallet.id,b.owner_user_id,price,'deposit','Business sale proceeds','business');
 end if;
 update public.businesses set owner_user_id=auth.uid(),status='active',sale_price_cents=null,updated_at=now() where id=b.id;
 insert into public.business_transactions(organization_id,business_id,buyer_user_id,seller_user_id,amount_cents,transaction_type)
 values(target_org,b.id,auth.uid(),b.owner_user_id,price,'purchase') returning id into tx;
 insert into public.wallet_transactions(organization_id,wallet_id,sender_user_id,amount_cents,transaction_type,description,reference_type,reference_id)
 values(target_org,buyer_wallet.id,auth.uid(),price,'withdrawal','Business purchase','business',b.id);
 return tx;
end; $$;
grant execute on function public.purchase_business(uuid,uuid) to authenticated;