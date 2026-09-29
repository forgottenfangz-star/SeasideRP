-- Kiwi CAD 0007: multi-tenant organization creation and safe Discord role provenance.
alter table public.organization_member_roles add column if not exists source text not null default 'manual' check(source in ('manual','discord','system'));
create index if not exists organization_member_roles_source_idx on public.organization_member_roles(membership_id,source);

create or replace function public.create_organization(org_slug text,org_name text,org_region text default null,org_description text default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare oid uuid; mid uuid; rid uuid;
begin
 if auth.uid() is null then raise exception 'Not authenticated'; end if;
 if length(trim(org_slug))<3 or trim(org_slug) !~ '^[a-z0-9-]+$' then raise exception 'Invalid organization slug'; end if;
 if length(trim(org_name))<2 then raise exception 'Organization name is required'; end if;
 insert into public.organizations(slug,name,description,region,is_public,is_primary,created_by)
 values(lower(trim(org_slug)),trim(org_name),nullif(trim(org_description),''),nullif(trim(org_region),''),true,false,auth.uid())
 returning id into oid;
 insert into public.organization_memberships(organization_id,user_id,status) values(oid,auth.uid(),'active') returning id into mid;
 select id into rid from public.organization_roles where organization_id=oid and name='Owner';
 if rid is null then insert into public.organization_roles(organization_id,name,description,hierarchy_level,is_system) values(oid,'Owner','Organization owner',100,true) returning id into rid; end if;
 insert into public.organization_member_roles(membership_id,role_id,assigned_by,source) values(mid,rid,auth.uid(),'system');
 return oid;
end; $$;
grant execute on function public.create_organization(text,text,text,text) to authenticated;