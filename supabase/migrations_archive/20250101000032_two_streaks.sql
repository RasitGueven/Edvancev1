-- 032_two_streaks.sql
-- Zwei unabhängige Streaks ersetzen den einfachen streak_days-Zähler.
-- Vorhandenes streak_days bleibt vorerst als Spalte (für Lib-Layer-Übergang)
-- und wird in Migration 036 gedroppt.

alter table public.student_progress
  add column if not exists presence_streak_weeks integer not null default 0,
  add column if not exists presence_streak_last_week_start timestamptz,
  add column if not exists presence_streak_multiplier numeric(3,2) not null default 1.00,
  add column if not exists home_streak_sessions integer not null default 0,
  add column if not exists home_streak_last_completed_at timestamptz;

-- Initialer Backfill: alten streak_days verwerfen, beide neu bei 0 starten.
update public.student_progress
   set presence_streak_weeks = 0,
       home_streak_sessions  = 0,
       presence_streak_multiplier = 1.00;

-- Multiplikator-Berechnung als Hilfsfunktion
create or replace function public.calc_presence_multiplier(weeks int)
returns numeric(3,2)
language sql
immutable
as $$
  select case
    when weeks >= 8 then 1.30
    when weeks >= 5 then 1.20
    when weeks >= 3 then 1.10
    else 1.00
  end::numeric(3,2)
$$;
