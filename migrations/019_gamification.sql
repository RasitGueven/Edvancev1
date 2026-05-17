-- ============================================================================
-- Migration 019 – student_progress + xp_events (Gamification)
--
-- ⚠️  Auth/RLS-AENDERUNG – per CLAUDE.md mit Rasit explizit abstimmen
-- vor Ausfuehrung im Supabase SQL Editor.
--
-- Ersetzt hardcodierte XP/Streak (StudentDashboard). xp_events ist
-- APPEND-ONLY; student_progress wird AUSSCHLIESSLICH vom Security-Definer-
-- Trigger apply_xp_event abgeleitet -> Client kann Totals nicht faelschen
-- (kein direktes Schreib-Policy auf student_progress).
-- Level-/Streak-Regel ist eine erste Default-Fassung (Epic U9 mit Rasit
-- schaerfen): level = 1 + xp_total / 500; Streak +1 bei Aktivitaet am
-- Folgetag, Reset bei Luecke.
-- ============================================================================

create table student_progress (
  student_id uuid primary key references students (id) on delete cascade,
  xp_total integer not null default 0,
  streak_days integer not null default 0,
  level integer not null default 1,
  last_activity timestamptz
);

alter table student_progress enable row level security;

create policy "student_progress_select_own" on student_progress
  for select using (student_id = public.get_my_student_id());

create policy "student_progress_parent_read" on student_progress
  for select using (public.is_parent_of_student(student_id));

create policy "student_progress_coach_admin_read" on student_progress
  for select using (public.get_my_role() in ('coach','admin'));

create table xp_events (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  student_id uuid not null references students (id) on delete cascade,
  task_id uuid references tasks (id) on delete set null,
  xp integer not null,
  reason text
);

create index xp_events_student_idx on xp_events (student_id);

alter table xp_events enable row level security;

-- append-only: KEIN update-, KEIN delete-Policy
create policy "xp_events_insert_own" on xp_events
  for insert with check (student_id = public.get_my_student_id());

create policy "xp_events_select_own" on xp_events
  for select using (student_id = public.get_my_student_id());

create policy "xp_events_parent_read" on xp_events
  for select using (public.is_parent_of_student(student_id));

create policy "xp_events_coach_admin_read" on xp_events
  for select using (public.get_my_role() in ('coach','admin'));

create or replace function public.apply_xp_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_last date;
  v_today date := (now() at time zone 'utc')::date;
  v_streak integer;
begin
  select (last_activity at time zone 'utc')::date, streak_days
    into v_last, v_streak
    from student_progress
    where student_id = new.student_id;

  if not found then
    insert into student_progress
      (student_id, xp_total, streak_days, level, last_activity)
    values
      (new.student_id, new.xp, 1, 1 + (new.xp / 500), now());
    return new;
  end if;

  if v_last = v_today then
    v_streak := v_streak;
  elsif v_last = v_today - 1 then
    v_streak := v_streak + 1;
  else
    v_streak := 1;
  end if;

  update student_progress
     set xp_total = xp_total + new.xp,
         level = 1 + ((xp_total + new.xp) / 500),
         streak_days = v_streak,
         last_activity = now()
   where student_id = new.student_id;

  return new;
end;
$$;

create trigger xp_events_apply
  after insert on xp_events
  for each row execute function public.apply_xp_event();
