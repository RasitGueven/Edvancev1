-- ============================================================================
-- Migration 015 – tiers + student_subscriptions (Tarif/Abo-Subsystem)
--
-- ⚠️  Auth/RLS-AENDERUNG – per CLAUDE.md mit Rasit explizit abstimmen
-- vor Ausfuehrung im Supabase SQL Editor.
--
-- Ersetzt die hardcodierte TIERS-Konstante (onboarding/constants.ts) durch
-- einen DB-Katalog. student_subscriptions persistiert die Tarifwahl.
-- ============================================================================

create table tiers (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  price_cents integer not null,
  features jsonb not null default '[]'::jsonb,
  sort_order integer not null default 0,
  active boolean not null default true
);

insert into tiers (name, price_cents, features, sort_order) values
  ('Basic', 8900,
   '["2 Sessions/Woche","Basis-Lernpfad","Monatlicher Eltern-Report"]'::jsonb, 1),
  ('Standard', 12900,
   '["3 Sessions/Woche","KI-Lernpfad","2x Eltern-Report/Monat","Coach-Chat"]'::jsonb, 2),
  ('Premium', 16900,
   '["Unbegrenzte Sessions","Voller KI-Lernpfad","Woechentlicher Report","Prioritaets-Coach","Fachwechsel flexibel"]'::jsonb, 3);

alter table tiers enable row level security;

create policy "tiers_authenticated_read" on tiers
  for select using (auth.role() = 'authenticated');

create policy "tiers_admin_write" on tiers
  for all
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');

create table student_subscriptions (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  student_id uuid not null references students (id) on delete cascade,
  tier_id uuid not null references tiers (id),
  status text not null default 'active' check (
    status in ('active','paused','cancelled')
  ),
  started_at timestamptz default now(),
  ended_at timestamptz
);

create index student_subscriptions_student_idx
  on student_subscriptions (student_id);

alter table student_subscriptions enable row level security;

create policy "student_subscriptions_select_own" on student_subscriptions
  for select using (student_id = public.get_my_student_id());

create policy "student_subscriptions_parent_read" on student_subscriptions
  for select using (public.is_parent_of_student(student_id));

create policy "student_subscriptions_coach_admin_all" on student_subscriptions
  for all
  using (public.get_my_role() in ('coach','admin'))
  with check (public.get_my_role() in ('coach','admin'));
