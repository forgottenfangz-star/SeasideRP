-- Kiwi CAD 0010: ensure the seeded primary organization's Owner has every permission.
insert into public.role_permissions(role_id,permission_key)
select r.id,p.key
from public.organization_roles r
cross join public.permissions p
join public.organizations o on o.id=r.organization_id
where o.is_primary=true and r.name='Owner'
on conflict do nothing;