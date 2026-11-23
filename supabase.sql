-- Attendance System — run once in Supabase → SQL Editor
create table if not exists public.attendance_sessions (
  id          uuid primary key default gen_random_uuid(),
  taken_on    date not null,
  class_name  text not null,
  batch       text not null,
  subject     text not null,
  mentor      text not null,
  present     text[] not null default '{}',
  absent      text[] not null default '{}',
  total       int  not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists att_date_idx  on public.attendance_sessions (taken_on desc);
create index if not exists att_batch_idx on public.attendance_sessions (class_name, batch);

alter table public.attendance_sessions enable row level security;

-- Open access for now (password system still to be decided).
-- Tighten these policies once login/PIN is chosen.
drop policy if exists att_read   on public.attendance_sessions;
drop policy if exists att_insert on public.attendance_sessions;
drop policy if exists att_update on public.attendance_sessions;
create policy att_read   on public.attendance_sessions for select using (true);
create policy att_insert on public.attendance_sessions for insert with check (true);
create policy att_update on public.attendance_sessions for update using (true);
