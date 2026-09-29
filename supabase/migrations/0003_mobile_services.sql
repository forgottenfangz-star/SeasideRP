-- Kiwi CAD 0003: mobile services, virtual AUD wallet, reports, bookings and dispatch.
-- All money in this migration is virtual roleplay currency. It is NOT a payment system.

create table if not exists public.wallets (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  balance_cents bigint not null default 0 check(balance_cents >= 0),
  currency text not null default 'AUD' check(currency='AUD'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(organization_id,user_id)
);

create table if not exists public.wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  wallet_id uuid not null references public.wallets(id) on delete cascade,
  sender_user_id uuid references public.profiles(id) on delete set null,
  recipient_user_id uuid references public.profiles(id) on delete set null,
  amount_cents bigint not null check(amount_cents > 0),
  currency text not null default 'AUD' check(currency='AUD'),
  transaction_type text not null check(transaction_type in ('transfer','deposit','withdrawal','booking','refund','admin_adjustment')),
  description text,
  reference_type text,
  reference_id uuid,
  created_at timestamptz not null default now()
);

create index if not exists wallet_transactions_wallet_idx on public.wallet_transactions(wallet_id,created_at desc);
create index if not exists wallet_transactions_org_idx on public.wallet_transactions(organization_id,created_at desc);

create table if not exists public.phone_numbers (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete set null,
  character_id uuid references public.characters(id) on delete set null,
  number text not null,
  display_name text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(organization_id,number)
);

create table if not exists public.phone_contacts (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  owner_user_id uuid not null references public.profiles(id) on delete cascade,
  contact_user_id uuid references public.profiles(id) on delete set null,
  contact_phone_number_id uuid references public.phone_numbers(id) on delete set null,
  display_name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.phone_messages (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  sender_phone_id uuid not null references public.phone_numbers(id) on delete cascade,
  recipient_phone_id uuid not null references public.phone_numbers(id) on delete cascade,
  body text not null check(length(body) between 1 and 4000),
  sent_at timestamptz not null default now(),
  read_at timestamptz
);

create index if not exists phone_messages_recipient_idx on public.phone_messages(recipient_phone_id,sent_at desc);

create table if not exists public.service_providers (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  provider_type text not null check(provider_type in ('bnb','taxi','mechanic','tow','restaurant','other')),
  name text not null,
  description text,
  phone_number text,
  address text,
  latitude numeric,
  longitude numeric,
  price_cents bigint not null default 0 check(price_cents >= 0),
  currency text not null default 'AUD' check(currency='AUD'),
  active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists service_providers_org_type_idx on public.service_providers(organization_id,provider_type,active);

create table if not exists public.service_bookings (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  provider_id uuid not null references public.service_providers(id) on delete cascade,
  customer_user_id uuid not null references public.profiles(id) on delete cascade,
  booking_type text not null check(booking_type in ('bnb','taxi','mechanic','tow','restaurant','other')),
  status text not null default 'requested' check(status in ('requested','confirmed','in_progress','completed','cancelled','declined')),
  scheduled_at timestamptz,
  pickup_address text,
  destination_address text,
  notes text,
  amount_cents bigint not null default 0 check(amount_cents >= 0),
  currency text not null default 'AUD' check(currency='AUD'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists service_bookings_customer_idx on public.service_bookings(customer_user_id,created_at desc);
create index if not exists service_bookings_provider_idx on public.service_bookings(provider_id,created_at desc);

create table if not exists public.police_reports (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  reporter_user_id uuid references public.profiles(id) on delete set null,
  reporter_character_id uuid references public.characters(id) on delete set null,
  report_number text not null,
  category text not null check(category in ('theft','damage','fraud','assault','missing_person','traffic','suspicious_activity','property','other')),
  title text not null,
  description text not null,
  location text,
  latitude numeric,
  longitude numeric,
  status text not null default 'submitted' check(status in ('submitted','under_review','assigned','investigating','resolved','closed','rejected')),
  priority text not null default 'normal' check(priority in ('low','normal','high','urgent')),
  assigned_membership_id uuid references public.organization_memberships(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(organization_id,report_number)
);

create index if not exists police_reports_org_idx on public.police_reports(organization_id,created_at desc);
create index if not exists police_reports_status_idx on public.police_reports(organization_id,status);

create table if not exists public.police_report_updates (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null references public.police_reports(id) on delete cascade,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  author_user_id uuid references public.profiles(id) on delete set null,
  update_type text not null check(update_type in ('note','status','assignment','evidence','contact','system')),
  body text not null,
  created_at timestamptz not null default now()
);

create index if not exists police_report_updates_report_idx on public.police_report_updates(report_id,created_at);

create table if not exists public.emergency_calls (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  caller_user_id uuid references public.profiles(id) on delete set null,
  caller_phone_id uuid references public.phone_numbers(id) on delete set null,
  service text not null check(service in ('police','fire','ems','dispatch')),
  call_type text not null,
  description text,
  location text,
  latitude numeric,
  longitude numeric,
  status text not null default 'open' check(status in ('open','dispatched','active','resolved','cancelled')),
  priority text not null default 'normal' check(priority in ('low','normal','high','urgent')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists emergency_calls_org_status_idx on public.emergency_calls(organization_id,status,created_at desc);

alter table public.wallets enable row level security;
alter table public.wallet_transactions enable row level security;
alter table public.phone_numbers enable row level security;
alter table public.phone_contacts enable row level security;
alter table public.phone_messages enable row level security;
alter table public.service_providers enable row level security;
alter table public.service_bookings enable row level security;
alter table public.police_reports enable row level security;
alter table public.police_report_updates enable row level security;
alter table public.emergency_calls enable row level security;

create policy "wallet_owner_read" on public.wallets for select using(user_id=auth.uid() or public.has_org_permission(organization_id,'staff.manage'));
create policy "wallet_transactions_owner_read" on public.wallet_transactions for select using(exists(select 1 from public.wallets w where w.id=wallet_id and (w.user_id=auth.uid() or public.has_org_permission(organization_id,'staff.manage'))));

create policy "phone_numbers_org_read" on public.phone_numbers for select using(public.is_org_member(organization_id));
create policy "phone_contacts_owner" on public.phone_contacts for all using(owner_user_id=auth.uid()) with check(owner_user_id=auth.uid());
create policy "phone_messages_participant" on public.phone_messages for select using(exists(select 1 from public.phone_numbers p where p.id=sender_phone_id and p.user_id=auth.uid()) or exists(select 1 from public.phone_numbers p where p.id=recipient_phone_id and p.user_id=auth.uid()));
create policy "phone_messages_sender_insert" on public.phone_messages for insert with check(exists(select 1 from public.phone_numbers p where p.id=sender_phone_id and p.user_id=auth.uid()));

create policy "service_providers_member_read" on public.service_providers for select using(public.is_org_member(organization_id));
create policy "service_providers_manage" on public.service_providers for all using(public.has_org_permission(organization_id,'org.manage')) with check(public.has_org_permission(organization_id,'org.manage'));

create policy "bookings_customer_read" on public.service_bookings for select using(customer_user_id=auth.uid() or public.has_org_permission(organization_id,'dispatch.incidents.manage'));
create policy "bookings_customer_create" on public.service_bookings for insert with check(customer_user_id=auth.uid() and public.is_org_member(organization_id));
create policy "bookings_manage" on public.service_bookings for update using(public.has_org_permission(organization_id,'dispatch.incidents.manage')) with check(public.has_org_permission(organization_id,'dispatch.incidents.manage'));

create policy "reports_reporter_read" on public.police_reports for select using(reporter_user_id=auth.uid() or public.has_org_permission(organization_id,'police.mdt'));
create policy "reports_submit" on public.police_reports for insert with check(reporter_user_id=auth.uid() and public.is_org_member(organization_id));
create policy "reports_police_update" on public.police_reports for update using(public.has_org_permission(organization_id,'police.mdt')) with check(public.has_org_permission(organization_id,'police.mdt'));

create policy "report_updates_participant_read" on public.police_report_updates for select using(exists(select 1 from public.police_reports r where r.id=report_id and (r.reporter_user_id=auth.uid() or public.has_org_permission(organization_id,'police.mdt'))));
create policy "report_updates_police_insert" on public.police_report_updates for insert with check(author_user_id=auth.uid() and public.has_org_permission(organization_id,'police.mdt'));

create policy "emergency_calls_member_read" on public.emergency_calls for select using(caller_user_id=auth.uid() or public.has_org_permission(organization_id,'dispatch.calls.view'));
create policy "emergency_calls_caller_create" on public.emergency_calls for insert with check(caller_user_id=auth.uid() and public.is_org_member(organization_id));
create policy "emergency_calls_dispatch_manage" on public.emergency_calls for update using(public.has_org_permission(organization_id,'dispatch.incidents.manage')) with check(public.has_org_permission(organization_id,'dispatch.incidents.manage'));

-- Transaction helper for virtual AUD transfers. The caller cannot alter another
-- user's balance without the server-side function checking the source wallet.
create or replace function public.transfer_virtual_aud(
  target_org uuid,
  recipient uuid,
  amount_cents bigint,
  note text default null
) returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare
  sender_wallet uuid;
  recipient_wallet uuid;
  sender_balance bigint;
  tx uuid;
begin
  if auth.uid() is null or amount_cents <= 0 or recipient=auth.uid() then
    raise exception 'Invalid transfer';
  end if;
  if not public.is_org_member(target_org) then raise exception 'Not an organization member'; end if;

  insert into public.wallets(organization_id,user_id) values(target_org,auth.uid())
  on conflict(organization_id,user_id) do nothing;
  insert into public.wallets(organization_id,user_id) values(target_org,recipient)
  on conflict(organization_id,user_id) do nothing;

  select id,balance_cents into sender_wallet,sender_balance from public.wallets where organization_id=target_org and user_id=auth.uid() for update;
  select id into recipient_wallet from public.wallets where organization_id=target_org and user_id=recipient;

  if recipient_wallet is null then raise exception 'Recipient is not an organization member'; end if;
  if sender_balance < amount_cents then raise exception 'Insufficient virtual AUD'; end if;

  update public.wallets set balance_cents=balance_cents-amount_cents,updated_at=now() where id=sender_wallet;
  update public.wallets set balance_cents=balance_cents+amount_cents,updated_at=now() where id=recipient_wallet;

  insert into public.wallet_transactions(organization_id,wallet_id,sender_user_id,recipient_user_id,amount_cents,transaction_type,description)
  values(target_org,sender_wallet,auth.uid(),recipient,amount_cents,'transfer',note)
  returning id into tx;
  return tx;
end;
$$;

grant execute on function public.transfer_virtual_aud(uuid,uuid,bigint,text) to authenticated;
