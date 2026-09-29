-- Kiwi CAD 0005: property, businesses, commerce and player-owned assets.

create table if not exists public.properties (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  property_type text not null check(property_type in ('land','house','apartment','commercial','industrial','public','other')),
  name text not null,
  address text,
  description text,
  latitude numeric,
  longitude numeric,
  price_cents bigint not null default 0 check(price_cents >= 0),
  currency text not null default 'AUD' check(currency='AUD'),
  status text not null default 'available' check(status in ('available','reserved','sold','leased','inactive')),
  owner_user_id uuid references public.profiles(id) on delete set null,
  owner_character_id uuid references public.characters(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists properties_org_status_idx on public.properties(organization_id,status);
create index if not exists properties_owner_idx on public.properties(owner_user_id);

create table if not exists public.businesses (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  property_id uuid references public.properties(id) on delete set null,
  owner_user_id uuid references public.profiles(id) on delete set null,
  owner_character_id uuid references public.characters(id) on delete set null,
  name text not null,
  business_type text not null check(business_type in ('shop','restaurant','taxi','mechanic','property','media','security','transport','other')),
  description text,
  phone_number text,
  address text,
  status text not null default 'active' check(status in ('active','closed','suspended','for_sale')),
  sale_price_cents bigint check(sale_price_cents is null or sale_price_cents >= 0),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists businesses_org_status_idx on public.businesses(organization_id,status);
create index if not exists businesses_owner_idx on public.businesses(owner_user_id);

create table if not exists public.business_employees (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  character_id uuid references public.characters(id) on delete set null,
  job_title text not null default 'Employee',
  wage_cents bigint not null default 0 check(wage_cents >= 0),
  status text not null default 'active' check(status in ('active','inactive')),
  hired_at timestamptz not null default now(),
  unique(business_id,user_id)
);

create table if not exists public.business_listings (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  seller_user_id uuid not null references public.profiles(id) on delete cascade,
  property_id uuid references public.properties(id) on delete set null,
  business_id uuid references public.businesses(id) on delete set null,
  listing_type text not null check(listing_type in ('property','business')),
  title text not null,
  description text,
  price_cents bigint not null check(price_cents > 0),
  currency text not null default 'AUD' check(currency='AUD'),
  status text not null default 'active' check(status in ('active','reserved','sold','cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check((listing_type='property' and property_id is not null) or (listing_type='business' and business_id is not null))
);

create index if not exists business_listings_org_status_idx on public.business_listings(organization_id,status);

create table if not exists public.property_transactions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  property_id uuid not null references public.properties(id) on delete cascade,
  buyer_user_id uuid not null references public.profiles(id) on delete restrict,
  seller_user_id uuid references public.profiles(id) on delete set null,
  amount_cents bigint not null check(amount_cents > 0),
  transaction_type text not null check(transaction_type in ('purchase','sale','lease','refund')),
  created_at timestamptz not null default now()
);

create table if not exists public.business_transactions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  business_id uuid not null references public.businesses(id) on delete cascade,
  buyer_user_id uuid not null references public.profiles(id) on delete restrict,
  seller_user_id uuid references public.profiles(id) on delete set null,
  amount_cents bigint not null check(amount_cents > 0),
  transaction_type text not null check(transaction_type in ('purchase','sale','transfer','refund')),
  created_at timestamptz not null default now()
);

create index if not exists property_transactions_property_idx on public.property_transactions(property_id,created_at desc);
create index if not exists business_transactions_business_idx on public.business_transactions(business_id,created_at desc);

alter table public.properties enable row level security;
alter table public.businesses enable row level security;
alter table public.business_employees enable row level security;
alter table public.business_listings enable row level security;
alter table public.property_transactions enable row level security;
alter table public.business_transactions enable row level security;

create policy "properties_member_read" on public.properties for select using(public.is_org_member(organization_id));
create policy "properties_manage" on public.properties for all using(public.has_org_permission(organization_id,'org.manage')) with check(public.has_org_permission(organization_id,'org.manage'));

create policy "businesses_member_read" on public.businesses for select using(public.is_org_member(organization_id));
create policy "businesses_owner_manage" on public.businesses for all using(owner_user_id=auth.uid() or public.has_org_permission(organization_id,'org.manage')) with check(owner_user_id=auth.uid() or public.has_org_permission(organization_id,'org.manage'));

create policy "employees_business_read" on public.business_employees for select using(exists(select 1 from public.businesses b where b.id=business_id and (b.owner_user_id=auth.uid() or public.is_org_member(b.organization_id))));
create policy "employees_owner_manage" on public.business_employees for all using(exists(select 1 from public.businesses b where b.id=business_id and b.owner_user_id=auth.uid())) with check(exists(select 1 from public.businesses b where b.id=business_id and b.owner_user_id=auth.uid()));

create policy "listings_member_read" on public.business_listings for select using(public.is_org_member(organization_id));
create policy "listings_seller_manage" on public.business_listings for all using(seller_user_id=auth.uid() or public.has_org_permission(organization_id,'org.manage')) with check(seller_user_id=auth.uid() or public.has_org_permission(organization_id,'org.manage'));

create policy "property_transactions_participant_read" on public.property_transactions for select using(buyer_user_id=auth.uid() or seller_user_id=auth.uid() or public.has_org_permission(organization_id,'org.manage'));
create policy "business_transactions_participant_read" on public.business_transactions for select using(buyer_user_id=auth.uid() or seller_user_id=auth.uid() or public.has_org_permission(organization_id,'org.manage'));

create or replace function public.purchase_property(target_org uuid,target_property uuid)
returns uuid
language plpgsql security definer set search_path=public
as $$
declare p public.properties%rowtype; wallet public.wallets%rowtype; tx uuid;
begin
 if auth.uid() is null or not public.is_org_member(target_org) then raise exception 'Not authorized'; end if;
 select * into p from public.properties where id=target_property and organization_id=target_org and status='available' for update;
 if not found then raise exception 'Property is not available'; end if;
 if p.price_cents<=0 then raise exception 'Property has no purchase price'; end if;
 insert into public.wallets(organization_id,user_id) values(target_org,auth.uid()) on conflict(organization_id,user_id) do nothing;
 select * into wallet from public.wallets where organization_id=target_org and user_id=auth.uid() for update;
 if wallet.balance_cents<p.price_cents then raise exception 'Insufficient virtual AUD'; end if;
 update public.wallets set balance_cents=balance_cents-p.price_cents,updated_at=now() where id=wallet.id;
 update public.properties set owner_user_id=auth.uid(),status='sold',updated_at=now() where id=p.id;
 insert into public.property_transactions(organization_id,property_id,buyer_user_id,seller_user_id,amount_cents,transaction_type) values(target_org,p.id,auth.uid(),p.owner_user_id,p.price_cents,'purchase') returning id into tx;
 return tx;
end;
$$;

grant execute on function public.purchase_property(uuid,uuid) to authenticated;
