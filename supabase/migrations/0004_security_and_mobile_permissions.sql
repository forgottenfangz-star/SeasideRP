-- Kiwi CAD 0004: mobile permissions, trusted audit writes and Discord sync support.

insert into public.permissions(key,name,description,category) values
('phone.view','Use phone','Use the in-CAD phone and messaging features.','Phone'),
('phone.manage','Manage phone system','Manage organization phone numbers and settings.','Administration'),
('wallet.view','View virtual wallet','View your virtual AUD balance and transactions.','Phone'),
('wallet.transfer','Transfer virtual AUD','Send virtual AUD to another organization member.','Phone'),
('services.book','Book services','Book taxis, accommodation and other listed services.','Phone'),
('services.manage','Manage services','Create and manage organization service providers.','Administration'),
('reports.submit','Submit police reports','Submit police reports through the phone.','Police'),
('reports.manage','Manage police reports','Review, assign and resolve police reports.','Police')
on conflict(key) do update set name=excluded.name,description=excluded.description,category=excluded.category;

create or replace function public.record_audit_log(
 target_org uuid,
 action_name text,
 category_name text default 'system',
 target_type_name text default null,
 target_id_value text default null,
 target_label_value text default null,
 metadata_value jsonb default '{}'::jsonb
) returns uuid
language plpgsql security definer set search_path=public
as $$
declare audit_id uuid;
begin
 if auth.uid() is null or not public.is_org_member(target_org) then raise exception 'Not authorized'; end if;
 insert into public.audit_logs(organization_id,actor_user_id,action,category,target_type,target_id,target_label,metadata)
 values(target_org,auth.uid(),action_name,category_name,target_type_name,target_id_value,target_label_value,coalesce(metadata_value,'{}'::jsonb))
 returning id into audit_id;
 return audit_id;
end;
$$;

grant execute on function public.record_audit_log(uuid,text,text,text,text,text,jsonb) to authenticated;

create or replace function public.claim_primary_organization()
returns uuid
language plpgsql security definer set search_path=public
as $$
declare org_id uuid; owner_role uuid; membership_id uuid;
begin
 if auth.uid() is null then raise exception 'Not authenticated'; end if;
 select id into org_id from public.organizations where is_primary=true and created_by is null limit 1 for update;
 if org_id is null then raise exception 'Primary organization has already been claimed'; end if;
 update public.organizations set created_by=auth.uid() where id=org_id and created_by is null;
 select id into membership_id from public.organization_memberships where organization_id=org_id and user_id=auth.uid();
 if membership_id is null then
   insert into public.organization_memberships(organization_id,user_id,status) values(org_id,auth.uid(),'active') returning id into membership_id;
 end if;
 select id into owner_role from public.organization_roles where organization_id=org_id and name='Owner' limit 1;
 if owner_role is not null then
   insert into public.organization_member_roles(membership_id,role_id,assigned_by)
   values(membership_id,owner_role,(select id from public.profiles where user_id=auth.uid()))
   on conflict do nothing;
 end if;
 return org_id;
end;
$$;

grant execute on function public.claim_primary_organization() to authenticated;

drop policy if exists "audit_logs_staff_insert" on public.audit_logs;
