-- Phase 5: crop lifecycle and farm intelligence fields.
-- Apply only to the dedicated AgriSense Supabase project.

alter table public.crops
  add column if not exists stage text not null default 'seedling'
    check (stage in ('seedling','vegetative','flowering','fruiting','maturing','ready_to_harvest')),
  add column if not exists notes text,
  add column if not exists expected_yield_kg numeric(14,2)
    check (expected_yield_kg is null or expected_yield_kg >= 0),
  add column if not exists actual_harvest_date date;

create index if not exists crops_status_stage_idx
on public.crops(status, stage);

create index if not exists crops_harvest_date_idx
on public.crops(expected_harvest_date)
where expected_harvest_date is not null;
