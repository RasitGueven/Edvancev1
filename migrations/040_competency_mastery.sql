-- ============================================================================
-- Migration 040 – student_competency_mastery (DAS HERZSTÜCK der Matrix)
--
-- ⚠️  Auth/RLS-AENDERUNG – per CLAUDE.md mit Rasit explizit abstimmen
-- vor Ausfuehrung im Supabase SQL Editor.
--
-- Manueller Schritt: Im Supabase SQL Editor ausfuehren.
--
-- Die Zwei-Achsen-Matrix als Mastery-Zustand pro
-- (Schüler × Mikroskill × Prozesskompetenz). "stage" wird NICHT gespeichert,
-- sondern als generated column aus der IMMUTABLE-Funktion mastery_stage(score)
-- abgeleitet (Migration 033). mastery_stage existiert bereits -> die generierte
-- Spalte ist beim Anwenden auf den Live-Stand zulaessig.
--
-- FernUSG: "mastered" darf strukturell NUR von Coach/Admin gesetzt werden.
-- Das erzwingt der Gate-Trigger (unten) – unabhaengig von RLS, also auch fuer
-- service-role-Pfade. score schreibt nur coach/admin via RLS (Messlogik laeuft
-- serverseitig/service-role und umgeht RLS ohnehin).
-- ============================================================================

create table public.student_competency_mastery (
  student_id    uuid not null references public.students(id) on delete cascade,
  microskill_id uuid not null references public.microskills(id) on delete cascade,
  competency_id uuid not null references public.process_competencies(id) on delete cascade,
  score         numeric(5,2) not null default 0 check (score between 0 and 100),
  mastered      boolean not null default false,
  mastered_by   uuid references public.profiles(id),
  mastered_at   timestamptz,
  updated_at    timestamptz not null default now(),
  -- abgeleitete 5-Stufen-Anzeige; nicht materialisiert gepflegt:
  stage         text generated always as (public.mastery_stage(score)) stored,
  primary key (student_id, microskill_id, competency_id)
);

-- Falls eine PG-Version generated columns mit Funktionsaufruf ablehnt:
-- stage-Spalte weglassen und stattdessen eine View ergaenzen:
--   create view public.v_competency_mastery as
--     select scm.*, public.mastery_stage(scm.score) as stage
--       from public.student_competency_mastery scm;

create index student_competency_mastery_student_idx
  on public.student_competency_mastery (student_id);

alter table public.student_competency_mastery enable row level security;

-- Lesen: exakt analog student_task_progress
-- (student eigene, parent verknuepfte Kinder, coach/admin alle).
create policy "scm_student_read" on public.student_competency_mastery
  for select using (student_id = public.get_my_student_id());
create policy "scm_parent_read" on public.student_competency_mastery
  for select using (public.is_parent_of_student(student_id));
create policy "scm_coach_admin_read" on public.student_competency_mastery
  for select using (public.get_my_role() in ('coach','admin'));

-- Schreiben (score): nur coach/admin. KEIN student/parent-Schreibpfad.
create policy "scm_coach_admin_insert" on public.student_competency_mastery
  for insert with check (public.get_my_role() in ('coach','admin'));
create policy "scm_coach_admin_update" on public.student_competency_mastery
  for update using (public.get_my_role() in ('coach','admin'))
  with check (public.get_my_role() in ('coach','admin'));

-- FernUSG-GATE: mastered nur durch Coach/Admin; setzt mastered_by/_at beim
-- Gewaehren und updated_at bei jedem Schreibvorgang.
create or replace function public.enforce_mastery_gate()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_was_mastered boolean := false;
begin
  new.updated_at := now();

  if tg_op = 'UPDATE' then
    v_was_mastered := coalesce(old.mastered, false);
  end if;

  if new.mastered and not v_was_mastered then
    if public.get_my_role() not in ('coach','admin') then
      raise exception 'Mastered darf nur durch Coach gesetzt werden (FernUSG)';
    end if;
    new.mastered_by := auth.uid();
    new.mastered_at := now();
  end if;

  return new;
end;
$$;

create trigger trg_enforce_mastery_gate
  before insert or update on public.student_competency_mastery
  for each row execute function public.enforce_mastery_gate();
