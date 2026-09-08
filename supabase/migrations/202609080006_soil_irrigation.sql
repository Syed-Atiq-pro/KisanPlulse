create table if not exists public.soil_profiles (
  id uuid primary key default gen_random_uuid(),
  field_id uuid not null references public.fields(id) on delete cascade,
  ph numeric(4,2),
  nitrogen_ppm numeric(8,2),
  phosphorus_ppm numeric(8,2),
  potassium_ppm numeric(8,2),
  moisture_percent numeric(5,2),
  organic_matter_percent numeric(5,2),
  texture text,
  recorded_at timestamptz not null default now(),
  notes text
);

create table if not exists public.irrigation_records (
  id uuid primary key default gen_random_uuid(),
  field_id uuid not null references public.fields(id) on delete cascade,
  crop_id uuid references public.crops(id) on delete set null,
  irrigation_date date not null default current_date,
  water_mm numeric(8,2) not null check (water_mm >= 0),
  duration_minutes integer check (duration_minutes is null or duration_minutes >= 0),
  method text not null default 'manual',
  source text not null default 'farmer',
  notes text,
  created_at timestamptz not null default now()
);

alter table public.soil_profiles enable row level security;
alter table public.irrigation_records enable row level security;

grant select, insert, update, delete on public.soil_profiles to authenticated;
grant select, insert, update, delete on public.irrigation_records to authenticated;

create policy soil_profiles_own on public.soil_profiles for all to authenticated
using (exists (select 1 from public.fields f join public.farms fm on fm.id = f.farm_id where f.id = field_id and fm.user_id = (select auth.uid())))
with check (exists (select 1 from public.fields f join public.farms fm on fm.id = f.farm_id where f.id = field_id and fm.user_id = (select auth.uid())));

create policy irrigation_records_own on public.irrigation_records for all to authenticated
using (exists (select 1 from public.fields f join public.farms fm on fm.id = f.farm_id where f.id = field_id and fm.user_id = (select auth.uid())))
with check (exists (select 1 from public.fields f join public.farms fm on fm.id = f.farm_id where f.id = field_id and fm.user_id = (select auth.uid())));

create index if not exists soil_profiles_field_recorded_idx on public.soil_profiles(field_id, recorded_at desc);
create index if not exists irrigation_records_field_date_idx on public.irrigation_records(field_id, irrigation_date desc);
