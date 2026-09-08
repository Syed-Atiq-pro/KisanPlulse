-- AgriSense Phase 2: farms, fields and crops
create table if not exists public.farms (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  location_name text,
  latitude double precision,
  longitude double precision,
  total_area_acres numeric(12,2),
  soil_type text,
  irrigation_type text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.fields (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references public.farms(id) on delete cascade,
  name text not null,
  area_acres numeric(12,2),
  boundary jsonb,
  soil_type text,
  irrigation_type text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.crops (
  id uuid primary key default gen_random_uuid(),
  field_id uuid not null references public.fields(id) on delete cascade,
  crop_name text not null,
  variety text,
  planting_date date,
  expected_harvest_date date,
  actual_harvest_date date,
  status text not null default 'planned' check (status in ('planned','growing','harvested','failed')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.farms enable row level security;
alter table public.fields enable row level security;
alter table public.crops enable row level security;

grant select, insert, update, delete on public.farms, public.fields, public.crops to authenticated;

create policy "farms_owner_all" on public.farms for all to authenticated
using ((select auth.uid()) = owner_id)
with check ((select auth.uid()) = owner_id);

create policy "fields_owner_all" on public.fields for all to authenticated
using (exists (select 1 from public.farms f where f.id = farm_id and f.owner_id = (select auth.uid())))
with check (exists (select 1 from public.farms f where f.id = farm_id and f.owner_id = (select auth.uid())));

create policy "crops_owner_all" on public.crops for all to authenticated
using (exists (select 1 from public.fields fi join public.farms f on f.id = fi.farm_id where fi.id = field_id and f.owner_id = (select auth.uid())))
with check (exists (select 1 from public.fields fi join public.farms f on f.id = fi.farm_id where fi.id = field_id and f.owner_id = (select auth.uid())));

create index if not exists farms_owner_id_idx on public.farms(owner_id);
create index if not exists fields_farm_id_idx on public.fields(farm_id);
create index if not exists crops_field_id_idx on public.crops(field_id);
