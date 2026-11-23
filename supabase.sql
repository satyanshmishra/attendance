-- ============================================================
--  Attendance System — run once in Supabase → SQL Editor
--  (safe to run again; re-running only resets the PINs)
-- ============================================================

create extension if not exists pgcrypto with schema extensions;

-- 1. Attendance records
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

-- 2. PINs (stored only as bcrypt hashes)
create table if not exists public.attendance_pins (
  role     text primary key check (role in ('mentor','admin')),
  pin_hash text not null
);

-- Lock both tables: no direct access from the website.
-- Everything goes through the PIN-checked functions below.
alter table public.attendance_sessions enable row level security;
alter table public.attendance_pins     enable row level security;
drop policy if exists att_read   on public.attendance_sessions;
drop policy if exists att_insert on public.attendance_sessions;
drop policy if exists att_update on public.attendance_sessions;

-- 3. Functions
create or replace function public.att_role(p_pin text)
returns text language sql stable security definer
set search_path = public, extensions as $$
  select role from public.attendance_pins
  where pin_hash = crypt(coalesce(p_pin,''), pin_hash)
  order by (role = 'admin') desc limit 1;
$$;

-- returns 'admin', 'mentor' or null
create or replace function public.att_check(p_pin text)
returns text language plpgsql security definer
set search_path = public, extensions as $$
begin
  perform pg_sleep(0.4);              -- slows down PIN guessing
  return public.att_role(p_pin);
end $$;

-- save / update one attendance (mentor or admin PIN)
create or replace function public.att_save(p_pin text, p_id uuid, p_rec jsonb)
returns public.attendance_sessions language plpgsql security definer
set search_path = public, extensions as $$
declare r public.attendance_sessions;
begin
  if public.att_role(p_pin) is null then raise exception 'Invalid PIN'; end if;
  if p_id is null then
    insert into public.attendance_sessions (taken_on, class_name, batch, subject, mentor, present, absent, total)
    values ((p_rec->>'taken_on')::date, p_rec->>'class_name', p_rec->>'batch', p_rec->>'subject', p_rec->>'mentor',
            array(select jsonb_array_elements_text(p_rec->'present')),
            array(select jsonb_array_elements_text(p_rec->'absent')),
            (p_rec->>'total')::int)
    returning * into r;
  else
    update public.attendance_sessions set
      taken_on = (p_rec->>'taken_on')::date, class_name = p_rec->>'class_name', batch = p_rec->>'batch',
      subject = p_rec->>'subject', mentor = p_rec->>'mentor',
      present = array(select jsonb_array_elements_text(p_rec->'present')),
      absent  = array(select jsonb_array_elements_text(p_rec->'absent')),
      total = (p_rec->>'total')::int, updated_at = now()
    where id = p_id returning * into r;
  end if;
  return r;
end $$;

-- previous attendance (admin PIN only)
create or replace function public.att_list(p_pin text, p_class text, p_batch text, p_from date, p_to date)
returns setof public.attendance_sessions language plpgsql security definer
set search_path = public, extensions as $$
begin
  if public.att_role(p_pin) is distinct from 'admin' then raise exception 'Admin PIN required'; end if;
  return query
    select * from public.attendance_sessions s
    where (p_class is null or p_class = '' or s.class_name = p_class)
      and (p_batch is null or p_batch = '' or s.batch = p_batch)
      and (p_from is null or s.taken_on >= p_from)
      and (p_to   is null or s.taken_on <= p_to)
    order by s.taken_on desc, s.created_at desc
    limit 1000;
end $$;

revoke all on function public.att_role(text) from public, anon, authenticated;
grant execute on function public.att_check(text) to anon, authenticated;
grant execute on function public.att_save(text, uuid, jsonb) to anon, authenticated;
grant execute on function public.att_list(text, text, text, date, date) to anon, authenticated;

-- 4. ►►► SET YOUR PINs HERE (change the two values, then Run) ◄◄◄
insert into public.attendance_pins (role, pin_hash) values
  ('mentor', extensions.crypt('MENTOR_PIN_HERE', extensions.gen_salt('bf'))),
  ('admin',  extensions.crypt('ADMIN_PIN_HERE',  extensions.gen_salt('bf')))
on conflict (role) do update set pin_hash = excluded.pin_hash;
