-- ============================================================================
-- Migration 027 – parent_report_generations (Kosten-Guardrail KI-Elternreport)
--
-- ⚠️  Auth/RLS-AENDERUNG – per CLAUDE.md §4/§7 mit Rasit explizit abstimmen
-- vor Ausfuehrung im Supabase SQL Editor.
--
-- Append-only Log JEDER erfolgreichen KI-Report-Generierung (ein bezahlter
-- Anthropic-Call ~0,02 $). Die Edge Function generate_parent_report zaehlt
-- daraus VOR dem teuren Call die Nutzung pro Coach/Schueler/global und
-- blockt fail-closed bei Limit-Ueberschreitung. Insert erfolgt
-- ausschliesslich via Service-Role aus der Edge Function (umgeht RLS) und
-- NUR bei erfolgreichem Call.
--
-- Append-only (wie xp_events, Migration 019): KEIN update/delete-Policy.
-- Sichtbarkeit: Coach + Admin read (Nutzungs-/Kostentransparenz).
-- Schueler/Eltern: keine Policy => kein Zugriff.
-- ============================================================================

create table parent_report_generations (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  coach_id uuid,                       -- auth-User des Aufrufers; null = System/Service-Role
  student_id uuid not null references students (id) on delete cascade,
  model text
);

create index parent_report_gen_coach_idx
  on parent_report_generations (coach_id, created_at);
create index parent_report_gen_student_idx
  on parent_report_generations (student_id, created_at);
create index parent_report_gen_created_idx
  on parent_report_generations (created_at);

alter table parent_report_generations enable row level security;

-- append-only: KEIN insert-Policy (Insert nur via Service-Role aus der
-- Edge Function, das umgeht RLS), KEIN update/delete-Policy.
create policy "prg_coach_admin_read" on parent_report_generations
  for select using (public.get_my_role() in ('coach', 'admin'));
