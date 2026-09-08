create table if not exists public.disease_diagnoses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  image_path text,
  crop text not null,
  disease text not null,
  confidence numeric(5,4) not null default 0 check (confidence >= 0 and confidence <= 1),
  advice jsonb not null default '[]'::jsonb,
  model_name text,
  created_at timestamptz not null default now()
);

alter table public.disease_diagnoses enable row level security;
grant select, insert on public.disease_diagnoses to authenticated;

create policy disease_diagnoses_own_select on public.disease_diagnoses
for select to authenticated using (user_id = (select auth.uid()));

create policy disease_diagnoses_own_insert on public.disease_diagnoses
for insert to authenticated with check (user_id = (select auth.uid()));

create index if not exists disease_diagnoses_user_created_idx
on public.disease_diagnoses(user_id, created_at desc);
