-- SeasideRP foundation schema
create extension if not exists pgcrypto;

create type public.character_status as enum ('ACTIVE','DECEASED','LIFE_IMPRISONED');
create type public.licence_status as enum ('VALID','SUSPENDED','REVOKED','EXPIRED');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  discord_id text unique,
  roblox_id text unique,
  created_at timestamptz not null default now()
);

create table public.characters (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete restrict,
  full_name text not null,
  date_of_birth date,
  address text,
  status public.character_status not null default 'ACTIVE',
  created_at timestamptz not null default now(),
  retired_at timestamptz
);

create table public.licence_types (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  minimum_character_age_minutes integer not null default 0,
  requires_review boolean not null default false,
  enabled boolean not null default true
);

create table public.character_licences (
  id uuid primary key default gen_random_uuid(),
  character_id uuid not null references public.characters(id) on delete restrict,
  licence_type_id uuid not null references public.licence_types(id) on delete restrict,
  status public.licence_status not null default 'VALID',
  issued_at timestamptz not null default now(),
  expires_at timestamptz,
  suspended_at timestamptz,
  revoked_at timestamptz,
  unique(character_id, licence_type_id)
);

create table public.demerit_entries (
  id uuid primary key default gen_random_uuid(),
  character_id uuid not null references public.characters(id) on delete restrict,
  points integer not null check (points > 0),
  reason text not null,
  incident_id uuid,
  issued_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create index characters_name_idx on public.characters(full_name);
create index demerits_character_idx on public.demerit_entries(character_id);
create index licences_character_idx on public.character_licences(character_id);

insert into public.licence_types(name,description,minimum_character_age_minutes) values
('Driver Licence','Road vehicle licence',0),
('Fishing Licence','Fishing licence',15),
('Boat Licence','Boating licence',25),
('Hunting Licence','Hunting licence',0),
('Firearms Licence','Firearms licence; server can require review',0)
on conflict (name) do nothing;

-- Create a profile automatically whenever a Supabase Auth user is created.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id) values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Row-level security: users can only access their own account/character data.
alter table public.profiles enable row level security;
alter table public.characters enable row level security;
alter table public.licence_types enable row level security;
alter table public.character_licences enable row level security;
alter table public.demerit_entries enable row level security;

create policy "profiles_select_own" on public.profiles
for select using (id = auth.uid());

create policy "profiles_update_own" on public.profiles
for update using (id = auth.uid()) with check (id = auth.uid());

create policy "characters_select_own" on public.characters
for select using (user_id = auth.uid());

create policy "characters_insert_own" on public.characters
for insert with check (user_id = auth.uid());

create policy "characters_update_own" on public.characters
for update using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "licence_types_read_enabled" on public.licence_types
for select using (enabled = true);

create policy "character_licences_select_own" on public.character_licences
for select using (
  exists (
    select 1 from public.characters c
    where c.id = character_id and c.user_id = auth.uid()
  )
);

create policy "demerits_select_own" on public.demerit_entries
for select using (
  exists (
    select 1 from public.characters c
    where c.id = character_id and c.user_id = auth.uid()
  )
);
