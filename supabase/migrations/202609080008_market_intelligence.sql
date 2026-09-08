-- AgriSense Phase 8: market intelligence
-- Source data is intended to be synchronized from official government market-price datasets.

create table if not exists public.markets (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  state text,
  district text,
  market_type text not null default 'mandi',
  latitude double precision,
  longitude double precision,
  created_at timestamptz not null default now(),
  unique(name, district, state)
);

create table if not exists public.market_prices (
  id uuid primary key default gen_random_uuid(),
  market_id uuid not null references public.markets(id) on delete cascade,
  commodity text not null,
  variety text,
  grade text,
  price_date date not null,
  min_price numeric(12,2),
  max_price numeric(12,2),
  modal_price numeric(12,2) not null,
  arrivals_tonnes numeric(14,3),
  unit text not null default 'quintal',
  source text not null default 'data.gov.in',
  source_record_id text,
  created_at timestamptz not null default now(),
  unique(market_id, commodity, variety, grade, price_date)
);

create table if not exists public.market_price_alerts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  commodity text not null,
  market_id uuid references public.markets(id) on delete cascade,
  target_price numeric(12,2) not null check (target_price >= 0),
  direction text not null check (direction in ('above','below')),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.markets enable row level security;
alter table public.market_prices enable row level security;
alter table public.market_price_alerts enable row level security;

grant select on public.markets, public.market_prices to authenticated;
grant select, insert, update, delete on public.market_price_alerts to authenticated;

drop policy if exists markets_read_authenticated on public.markets;
create policy markets_read_authenticated on public.markets
for select to authenticated using (true);

drop policy if exists market_prices_read_authenticated on public.market_prices;
create policy market_prices_read_authenticated on public.market_prices
for select to authenticated using (true);

drop policy if exists market_alerts_own on public.market_price_alerts;
create policy market_alerts_own on public.market_price_alerts
for all to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create index if not exists markets_state_district_idx on public.markets(state, district);
create index if not exists market_prices_lookup_idx on public.market_prices(commodity, price_date desc, market_id);
create index if not exists market_prices_market_date_idx on public.market_prices(market_id, price_date desc);
create index if not exists market_alerts_user_active_idx on public.market_price_alerts(user_id, active);
