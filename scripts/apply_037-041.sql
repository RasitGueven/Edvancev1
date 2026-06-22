-- ============================================================================
-- Edvance · APPLY-BUNDLE Migrationen 037–041 (Kompetenz-Matrix + XP-Fix)
-- ----------------------------------------------------------------------------
-- ZWECK: Ein einziges, geordnetes, idempotentes Skript zum Einfügen in den
--        Supabase SQL Editor. Wendet 037 → 038 → 039 → 040 → 041 in genau
--        dieser Reihenfolge an. Mehrfaches Ausführen ist gefahrlos (Guards).
--
-- VORAUSSETZUNG: Migrationen 001–036 sind bereits angewendet (insb. existieren
--   tasks, screening_items, students, microskills, profiles, student_progress,
--   xp_events und die IMMUTABLE-Funktion mastery_stage(numeric) aus 033).
--
-- ⚠️  Enthält Auth/RLS-Änderungen (037 Trigger-Fn, 040 RLS + FernUSG-Gate) und
--     eine DATEN-MUTATION (041: Cluster deprecaten, Tasks competency=Mod +
--     is_active=false). Bewusst im SQL Editor ausführen (CLAUDE.md §4/§7).
--
-- NACH "Run": Die NOTICE-Ausgaben von 041 (Zählungen + quarantänierte Task-IDs)
--   stehen im Reiter "Messages"/"Notices". Das finale SELECT zeigt die Checks.
-- ============================================================================

begin;

-- ============================================================================
-- 037 — fix apply_xp_event (D-01): streak_days-Bezug entfernen
-- ============================================================================
create or replace function public.apply_xp_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform 1 from student_progress where student_id = new.student_id;

  if not found then
    insert into student_progress
      (student_id, xp_total, level, last_activity)
    values
      (new.student_id, new.xp, 1 + (new.xp / 500), now());
    return new;
  end if;

  update student_progress
     set xp_total = xp_total + new.xp,
         level = 1 + ((xp_total + new.xp) / 500),
         last_activity = now()
   where student_id = new.student_id;

  return new;
end;
$$;

-- ============================================================================
-- 038 — process_competencies (Achse B: Prozesskompetenzen)
-- ============================================================================
create table if not exists public.process_competencies (
  id          uuid primary key default gen_random_uuid(),
  code        text not null unique,        -- Ope|Mod|Pro|Arg|Kom|Wkz
  name        text not null,               -- interner Klartext
  sort_order  integer not null
);

insert into public.process_competencies (code, name, sort_order)
values
  ('Ope', 'Operieren',        1),
  ('Mod', 'Modellieren',      2),
  ('Pro', 'Problemlösen',     3),
  ('Arg', 'Argumentieren',    4),
  ('Kom', 'Kommunizieren',    5),
  ('Wkz', 'Werkzeuge nutzen', 6)
on conflict (code) do nothing;

alter table public.process_competencies enable row level security;

drop policy if exists "authenticated_read_process_competencies" on public.process_competencies;
create policy "authenticated_read_process_competencies"
  on public.process_competencies for select
  using (auth.role() = 'authenticated');

drop policy if exists "process_competencies_admin_write" on public.process_competencies;
create policy "process_competencies_admin_write"
  on public.process_competencies for all
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');

-- ============================================================================
-- 039 — competency_id-Tagging an Inhalten (Achse B)
-- ============================================================================
alter table public.tasks
  add column if not exists competency_id uuid
  references public.process_competencies(id) on delete set null;

alter table public.screening_items
  add column if not exists competency_id uuid
  references public.process_competencies(id) on delete set null;

create index if not exists tasks_competency_idx
  on public.tasks (competency_id);
create index if not exists screening_items_competency_idx
  on public.screening_items (competency_id);

comment on column public.screening_items.competency_id is
  'Strukturierte Wahrheit der Prozesskompetenz (Achse B). kompetenzfelder (text[]) bleibt als Legacy/VERA-8-Historie erhalten.';

-- ============================================================================
-- 040 — student_competency_mastery (Matrix) + FernUSG-Gate
-- ============================================================================
create table if not exists public.student_competency_mastery (
  student_id    uuid not null references public.students(id) on delete cascade,
  microskill_id uuid not null references public.microskills(id) on delete cascade,
  competency_id uuid not null references public.process_competencies(id) on delete cascade,
  score         numeric(5,2) not null default 0 check (score between 0 and 100),
  mastered      boolean not null default false,
  mastered_by   uuid references public.profiles(id),
  mastered_at   timestamptz,
  updated_at    timestamptz not null default now(),
  stage         text generated always as (public.mastery_stage(score)) stored,
  primary key (student_id, microskill_id, competency_id)
);

create index if not exists student_competency_mastery_student_idx
  on public.student_competency_mastery (student_id);

alter table public.student_competency_mastery enable row level security;

-- Lesen: exakt analog student_task_progress.
drop policy if exists "scm_student_read" on public.student_competency_mastery;
create policy "scm_student_read" on public.student_competency_mastery
  for select using (student_id = public.get_my_student_id());

drop policy if exists "scm_parent_read" on public.student_competency_mastery;
create policy "scm_parent_read" on public.student_competency_mastery
  for select using (public.is_parent_of_student(student_id));

drop policy if exists "scm_coach_admin_read" on public.student_competency_mastery;
create policy "scm_coach_admin_read" on public.student_competency_mastery
  for select using (public.get_my_role() in ('coach','admin'));

-- Schreiben (score): nur coach/admin.
drop policy if exists "scm_coach_admin_insert" on public.student_competency_mastery;
create policy "scm_coach_admin_insert" on public.student_competency_mastery
  for insert with check (public.get_my_role() in ('coach','admin'));

drop policy if exists "scm_coach_admin_update" on public.student_competency_mastery;
create policy "scm_coach_admin_update" on public.student_competency_mastery
  for update using (public.get_my_role() in ('coach','admin'))
  with check (public.get_my_role() in ('coach','admin'));

-- FernUSG-GATE: mastered nur durch Coach/Admin; setzt mastered_by/_at + updated_at.
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

drop trigger if exists trg_enforce_mastery_gate on public.student_competency_mastery;
create trigger trg_enforce_mastery_gate
  before insert or update on public.student_competency_mastery
  for each row execute function public.enforce_mastery_gate();

-- ============================================================================
-- 041 — Auflösung "Sachrechnen & Modellieren" (non-destruktiv, daten-sensibel)
-- ============================================================================
alter table public.skill_clusters
  add column if not exists is_deprecated boolean not null default false;

do $$
declare
  v_cluster_ids uuid[];
  v_mod_id      uuid;
  c_tasks_direct    int;
  c_tasks_via_skill int;
  c_microskills     int;
  c_screening       int;
  c_focus           int;
  v_task_ids        uuid[];
begin
  select array_agg(id) into v_cluster_ids
    from public.skill_clusters
   where name = 'Sachrechnen & Modellieren';

  if v_cluster_ids is null then
    raise notice '[041] Kein Cluster "Sachrechnen & Modellieren" gefunden – nichts zu tun.';
    return;
  end if;

  select id into v_mod_id
    from public.process_competencies
   where code = 'Mod';

  -- (a) ZÄHLEN (vor jeder Änderung)
  select count(*) into c_tasks_direct
    from public.tasks where cluster_id = any(v_cluster_ids);

  select count(*) into c_tasks_via_skill
    from public.tasks t
    join public.microskills m on m.id = t.microskill_id
   where m.cluster_id = any(v_cluster_ids);

  select count(*) into c_microskills
    from public.microskills where cluster_id = any(v_cluster_ids);

  select count(*) into c_screening
    from public.screening_items where cluster_id = any(v_cluster_ids);

  select count(*) into c_focus
    from public.student_focus_areas where cluster_id = any(v_cluster_ids);

  raise notice '[041] Betroffene Zeilen (Cluster ids=%):', v_cluster_ids;
  raise notice '[041]   tasks via cluster_id               = %', c_tasks_direct;
  raise notice '[041]   tasks via microskill_id -> cluster  = %', c_tasks_via_skill;
  raise notice '[041]   microskills                        = %', c_microskills;
  raise notice '[041]   screening_items                    = %', c_screening;
  raise notice '[041]   student_focus_areas                = %', c_focus;

  -- (b) DEPRECATEN (kein Delete)
  update public.skill_clusters
     set is_deprecated = true
   where id = any(v_cluster_ids);

  -- (c) KOMPETENZ-BACKFILL competency_id = 'Mod' (nur wo NULL)
  update public.tasks t
     set competency_id = v_mod_id
   where t.competency_id is null
     and (
       t.cluster_id = any(v_cluster_ids)
       or t.microskill_id in (
            select id from public.microskills where cluster_id = any(v_cluster_ids)
       )
     );

  update public.screening_items si
     set competency_id = v_mod_id
   where si.competency_id is null
     and si.cluster_id = any(v_cluster_ids);

  -- (d) QUARANTÄNE: betroffene tasks deaktivieren
  select array_agg(t.id) into v_task_ids
    from public.tasks t
   where t.cluster_id = any(v_cluster_ids)
      or t.microskill_id in (
           select id from public.microskills where cluster_id = any(v_cluster_ids)
      );

  update public.tasks t
     set is_active = false
   where t.id = any(coalesce(v_task_ids, '{}'::uuid[]));

  raise notice '[041] Quarantänierte task-ids (is_active=false): %', coalesce(v_task_ids, '{}'::uuid[]);
  raise notice '[041] Offen für Lena: korrektes Inhaltsfeld (Achse A) zuweisen, dann is_active reaktivieren.';
end $$;

commit;

-- ============================================================================
-- VERIFIKATION (ein Result-Set; nach dem Lauf prüfen)
-- ============================================================================
select 'process_competencies count (=6)'            as label,
       count(*)::text                               as value
  from public.process_competencies
union all
select 'process_competencies codes',
       string_agg(code, ',' order by sort_order)
  from public.process_competencies
union all
select 'apply_xp_event referenziert streak_days?',
       case when pg_get_functiondef('public.apply_xp_event'::regproc) ilike '%streak_days%'
            then 'JA (FEHLER)' else 'nein (ok)' end
union all
select 'student_competency_mastery existiert?',
       case when to_regclass('public.student_competency_mastery') is not null
            then 'ja' else 'nein' end
union all
select 'Gate-Trigger trg_enforce_mastery_gate?',
       case when exists (select 1 from pg_trigger where tgname = 'trg_enforce_mastery_gate')
            then 'ja' else 'nein' end
union all
select 'skill_clusters.is_deprecated Spalte?',
       case when exists (
              select 1 from information_schema.columns
               where table_schema='public' and table_name='skill_clusters'
                 and column_name='is_deprecated')
            then 'ja' else 'nein' end;
