-- Kiwi CAD organization, staff, permissions, Discord mapping, audit, and map foundation
-- Safe migration: adds new multi-tenant staff infrastructure without replacing existing tables.

create table if not exists public.organization_settings (
  organization_id uuid primary key references public.organizations(id) on delete cascade,
  timezone text not null default 'Australia/Sydney',
  dispatch_enabled boolean not null default true,
  staff_enabled boolean not null default true,
  discord_sync_enabled boolean not null default false,
  roblox_sync_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.organization_departments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  slug text not null,
  description text,
  color text,
  enabled boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  unique(organization_id, slug)
);

create table if not exists public.permissions (
  key text primary key,
  name text not null,
  description text,
  category text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.organization_roles (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  department_id uuid references public.organization_departments(id) on delete set null,
  name text not null,
  description text,
  hierarchy_level integer not null default 0,
  parent_role_id uuid references public.organization_roles(id) on delete set null,
  color text,
  is_system boolean not null default false,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(organization_id, name)
);

create index if not exists organization_roles_org_idx on public.organization_roles(organization_id);
create index if not exists organization_roles_department_idx on public.organization_roles(department_id);

create table if not exists public.role_permissions (
  role_id uuid not null references public.organization_roles(id) on delete cascade,
  permission_key text not null references public.permissions(key) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(role_id, permission_key)
);

create table if not exists public.organization_member_roles (
  membership_id uuid not null references public.organization_memberships(id) on delete cascade,
  role_id uuid not null references public.organization_roles(id) on delete cascade,
  assigned_by uuid references public.profiles(id) on delete set null,
  assigned_at timestamptz not null default now(),
  primary key(membership_id, role_id)
);

create table if not exists public.discord_role_mappings (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  discord_guild_id text not null,
  discord_role_id text not null,
  role_id uuid not null references public.organization_roles(id) on delete cascade,
  sync_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  unique(organization_id, discord_guild_id, discord_role_id)
);

create index if not exists discord_role_mappings_role_idx on public.discord_role_mappings(role_id);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  actor_user_id uuid references public.profiles(id) on delete set null,
  action text not null,
  category text not null default 'system',
  target_type text,
  target_id text,
  target_label text,
  metadata jsonb not null default '{}'::jsonb,
  ip_address inet,
  user_agent text,
  created_at timestamptz not null default now()
);

create index if not exists audit_logs_org_created_idx on public.audit_logs(organization_id, created_at desc);
create index if not exists audit_logs_actor_idx on public.audit_logs(actor_user_id);
create index if not exists audit_logs_target_idx on public.audit_logs(target_type, target_id);

create table if not exists public.staff_shifts (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  membership_id uuid not null references public.organization_memberships(id) on delete cascade,
  department_id uuid references public.organization_departments(id) on delete set null,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  status text not null default 'active' check(status in ('active','ended','cancelled')),
  notes text
);

create index if not exists staff_shifts_org_idx on public.staff_shifts(organization_id, started_at desc);
create index if not exists staff_shifts_membership_idx on public.staff_shifts(membership_id, started_at desc);

create table if not exists public.organization_maps (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  slug text not null,
  image_url text,
  map_width numeric,
  map_height numeric,
  enabled boolean not null default true,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(organization_id, slug)
);

create unique index if not exists organization_maps_one_default_idx
  on public.organization_maps(organization_id)
  where is_default = true;

create table if not exists public.map_markers (
  id uuid primary key default gen_random_uuid(),
  map_id uuid not null references public.organization_maps(id) on delete cascade,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  marker_type text not null,
  label text,
  x numeric not null,
  y numeric not null,
  rotation numeric default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists map_markers_map_idx on public.map_markers(map_id);
create index if not exists map_markers_org_idx on public.map_markers(organization_id);

insert into public.permissions(key,name,description,category) values
('cad.view_dashboard','View dashboard','Access the organization dashboard.','CAD'),
('cad.view_organization','View organization','View organization information and configuration.','CAD'),
('org.manage','Manage organization','Change organization settings and core configuration.','Administration'),
('people.view','View persons','Search and view person records.','People'),
('people.create','Create persons','Create person records.','People'),
('people.edit','Edit persons','Edit person records.','People'),
('records.view','View records','View incident and record history.','People'),
('records.create','Create records','Create records and reports.','People'),
('records.delete','Delete records','Delete records where permitted.','People'),
('police.mdt','Access MDT','Access police MDT tools.','Police'),
('police.vehicles.view','View vehicles','Search and view vehicle records.','Police'),
('police.persons.search','Search persons','Search persons from the MDT.','Police'),
('police.bolo.create','Create BOLO','Create BOLO alerts.','Police'),
('police.warrant.create','Create warrant','Create warrants.','Police'),
('police.infringement.issue','Issue infringement','Issue infringements.','Police'),
('police.arrest','Arrest person','Create and manage arrest records.','Police'),
('dispatch.calls.view','View calls','View active and historical calls.','Dispatch'),
('dispatch.calls.create','Create calls','Create dispatch calls.','Dispatch'),
('dispatch.units.dispatch','Dispatch units','Dispatch units to incidents.','Dispatch'),
('dispatch.units.assign','Assign units','Assign units to calls.','Dispatch'),
('dispatch.incidents.manage','Manage active incidents','Manage active incidents and their lifecycle.','Dispatch'),
('staff.view','View staff','View organization staff.','Staff'),
('staff.manage','Manage staff','Manage staff membership and assignments.','Staff'),
('roles.create','Create roles','Create custom organization roles.','Staff'),
('roles.edit','Edit roles','Edit custom organization roles.','Staff'),
('roles.permissions','Manage permissions','Assign permissions and inheritance to roles.','Staff'),
('audit.view','View audit logs','View staff and security audit logs.','Staff'),
('departments.manage','Manage departments','Create and configure departments.','Administration'),
('settings.manage','Manage organization settings','Change organization settings.','Administration'),
('discord.manage','Manage Discord integration','Configure Discord role synchronization.','Administration'),
('roblox.manage','Manage Roblox integration','Configure Roblox integration.','Administration'),
('maps.view','View maps','View organization dispatch maps.','Dispatch'),
('maps.manage','Manage maps','Create, edit, and configure organization maps and markers.','Dispatch')
on conflict(key) do update set
  name=excluded.name,
  description=excluded.description,
  category=excluded.category;

insert into public.organization_settings(organization_id)
select id from public.organizations
on conflict(organization_id) do nothing;

insert into public.organization_departments(organization_id,name,slug,description,sort_order)
select o.id,v.name,v.slug,v.description,v.sort_order
from public.organizations o
cross join (values
  ('Police','police','Police and law enforcement operations.',10),
  ('Fire & Rescue','fire','Fire and rescue operations.',20),
  ('Emergency Medical Services','ems','Emergency medical services.',30),
  ('Dispatch','dispatch','Central dispatch and communications.',40),
  ('Staff','staff','Community and platform staff.',50)
) as v(name,slug,description,sort_order)
on conflict(organization_id,slug) do nothing;

insert into public.organization_roles(organization_id,name,description,hierarchy_level,is_system)
select o.id,v.name,v.description,v.hierarchy_level,true
from public.organizations o
cross join (values
  ('Owner','Full organization control.',100),
  ('Executive','Senior organization administration.',90),
  ('Department Command','Department leadership.',70),
  ('Supervisor','Supervisory staff.',50),
  ('Officer','Operational staff.',30),
  ('Member','Standard organization member.',0)
) as v(name,description,hierarchy_level)
where not exists (
  select 1 from public.organization_roles r
  where r.organization_id=o.id and r.name=v.name
);

alter table public.organization_settings enable row level security;
alter table public.organization_departments enable row level security;
alter table public.permissions enable row level security;
alter table public.organization_roles enable row level security;
alter table public.role_permissions enable row level security;
alter table public.organization_member_roles enable row level security;
alter table public.discord_role_mappings enable row level security;
alter table public.audit_logs enable row level security;
alter table public.staff_shifts enable row level security;
alter table public.organization_maps enable row level security;
alter table public.map_markers enable row level security;

create or replace function public.is_org_member(target_org uuid)
returns boolean
language sql
stable
security definer
set search_path=public
as $$
  select exists(
    select 1 from public.organization_memberships m
    where m.organization_id=target_org
      and m.user_id=auth.uid()
      and m.status='active'
  );
$$;

create or replace function public.has_org_permission(target_org uuid, permission text)
returns boolean
language sql
stable
security definer
set search_path=public
as $$
  with recursive role_tree as (
    select r.id, r.parent_role_id
    from public.organization_roles r
    join public.organization_member_roles mr on mr.role_id=r.id
    join public.organization_memberships m on m.id=mr.membership_id
    where m.organization_id=target_org
      and m.user_id=auth.uid()
      and m.status='active'
      and r.enabled=true
    union
    select parent.id, parent.parent_role_id
    from public.organization_roles parent
    join role_tree child on child.parent_role_id=parent.id
    where parent.organization_id=target_org
      and parent.enabled=true
  )
  select exists(
    select 1
    from public.role_permissions rp
    join role_tree rt on rt.id=rp.role_id
    where rp.permission_key=permission
  );
$$;

create policy "organization_settings_member_read" on public.organization_settings
for select using(public.is_org_member(organization_id));

create policy "organization_settings_manage" on public.organization_settings
for all using(public.has_org_permission(organization_id,'settings.manage'))
with check(public.has_org_permission(organization_id,'settings.manage'));

create policy "departments_member_read" on public.organization_departments
for select using(public.is_org_member(organization_id));

create policy "departments_manage" on public.organization_departments
for all using(public.has_org_permission(organization_id,'departments.manage'))
with check(public.has_org_permission(organization_id,'departments.manage'));

create policy "permissions_authenticated_read" on public.permissions
for select using(auth.uid() is not null);

create policy "roles_member_read" on public.organization_roles
for select using(public.is_org_member(organization_id));

create policy "roles_manage" on public.organization_roles
for all using(public.has_org_permission(organization_id,'roles.edit') or public.has_org_permission(organization_id,'roles.create'))
with check(public.has_org_permission(organization_id,'roles.edit') or public.has_org_permission(organization_id,'roles.create'));

create policy "role_permissions_member_read" on public.role_permissions
for select using(exists(
  select 1 from public.organization_roles r
  where r.id=role_id and public.is_org_member(r.organization_id)
));

create policy "role_permissions_manage" on public.role_permissions
for all using(exists(
  select 1 from public.organization_roles r
  where r.id=role_id and public.has_org_permission(r.organization_id,'roles.permissions')
))
with check(exists(
  select 1 from public.organization_roles r
  where r.id=role_id and public.has_org_permission(r.organization_id,'roles.permissions')
));

create policy "member_roles_member_read" on public.organization_member_roles
for select using(exists(
  select 1 from public.organization_memberships m
  where m.id=membership_id and public.is_org_member(m.organization_id)
));

create policy "member_roles_manage" on public.organization_member_roles
for all using(exists(
  select 1 from public.organization_memberships m
  where m.id=membership_id and public.has_org_permission(m.organization_id,'staff.manage')
))
with check(exists(
  select 1 from public.organization_memberships m
  where m.id=membership_id and public.has_org_permission(m.organization_id,'staff.manage')
));

create policy "discord_mappings_member_read" on public.discord_role_mappings
for select using(public.is_org_member(organization_id));

create policy "discord_mappings_manage" on public.discord_role_mappings
for all using(public.has_org_permission(organization_id,'discord.manage'))
with check(public.has_org_permission(organization_id,'discord.manage'));

create policy "audit_logs_staff_read" on public.audit_logs
for select using(public.has_org_permission(organization_id,'audit.view'));

create policy "audit_logs_staff_insert" on public.audit_logs
for insert with check(public.is_org_member(organization_id));

create policy "staff_shifts_member_read" on public.staff_shifts
for select using(public.is_org_member(organization_id));

create policy "staff_shifts_manage" on public.staff_shifts
for all using(public.has_org_permission(organization_id,'staff.manage'))
with check(public.has_org_permission(organization_id,'staff.manage'));

create policy "maps_member_read" on public.organization_maps
for select using(public.is_org_member(organization_id));

create policy "maps_manage" on public.organization_maps
for all using(public.has_org_permission(organization_id,'maps.manage'))
with check(public.has_org_permission(organization_id,'maps.manage'));

create policy "map_markers_member_read" on public.map_markers
for select using(public.is_org_member(organization_id));

create policy "map_markers_manage" on public.map_markers
for all using(public.has_org_permission(organization_id,'maps.manage'))
with check(public.has_org_permission(organization_id,'maps.manage'));

-- Seed the original SeasideRP organization with its standard departments.
-- The Owner role is intentionally not auto-assigned here; that should happen
-- after the organization's owner account is known.
