create table if not exists public.market_sync_runs (
  id uuid primary key default gen_random_uuid(),
  source text not null default 'data.gov.in',
  status text not null check (status in ('running','success','partial','failed')),
  records_seen integer not null default 0,
  records_upserted integer not null default 0,
  markets_upserted integer not null default 0,
  error_message text,
  started_at timestamptz not null default now(),
  finished_at timestamptz
);

create index if not exists market_sync_runs_started_idx
  on public.market_sync_runs (started_at desc);

alter table public.market_sync_runs enable row level security;

drop policy if exists "Authenticated users can read market sync status" on public.market_sync_runs;
create policy "Authenticated users can read market sync status"
  on public.market_sync_runs for select
  to authenticated
  using (true);

grant select on public.market_sync_runs to authenticated;
