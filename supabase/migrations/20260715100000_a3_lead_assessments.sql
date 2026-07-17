-- ============================================================================
-- A3 (S5-Intake Ebene A): Die zwei Einschätzungen — Eltern + Kind, getrennt.
--
-- `lead_assessments` hält je eine Einschätzung „wo liegen die Schwierigkeiten"
-- pro Quelle (Eltern / Kind), an einem Lead. Metadatum für den späteren Reveal
-- (Eltern-Vermutung vs. Kind-Vermutung vs. gemessenes LSA-Ergebnis).
--
-- KRITISCH — die Einschätzung darf die LSA NICHT steuern:
--   Sie ist NIE Input für `lsa_start` / die Aufgabenauswahl. Sonst testet die LSA
--   das, was das Kind ohnehin für sein Problem hält, statt neutral zu messen — und
--   der Reveal-Moment (das Verkaufsargument) bricht.
--   Die Trennung ist STRUKTURELL gesichert, nicht per Konvention:
--     - `lead_assessments` hängt ausschließlich an `leads`, NICHT an `tasks`,
--       `task_solutions`, `skill_clusters`, `subjects` oder `lsa_sessions`.
--     - Keine Pool-Tabelle referenziert `lead_assessments`; es gibt also keinen
--       Join-Pfad, über den eine Einschätzung in `lsa_start` sichtbar würde.
--     - `lsa_start` nimmt (student_id, grade, subject) — kein Lead, keine
--       Einschätzung. inv_a3 beweist das (nicht behauptet).
--
-- Migration: ja. Kein Eingriff in `lsa_start` (das ist A4/A1). Kein Screen.
-- ============================================================================

begin;

create table if not exists lead_assessments (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  lead_id     uuid not null references leads(id) on delete cascade,
  -- Wer schätzt ein. Genau zwei Quellen, verdeckt voneinander (UI: Ebene B).
  source      text not null check (source in ('parent','child')),
  -- Freitext: „wo liegen die Schwierigkeiten". Die eigentliche Einschätzung.
  note        text,
  -- Optionale strukturierte Themen-Tags, an leads.known_weak_topics angelehnt
  -- (gleicher Typ text[]). NIE Input für die Aufgabenauswahl — nur Reveal-Metadatum.
  weak_topics text[] not null default '{}',
  -- Je eine Eltern- und eine Kind-Einschätzung pro Lead.
  constraint lead_assessments_one_per_source unique (lead_id, source)
);

comment on table lead_assessments is
  'Zwei getrennte, verdeckte Einschätzungen (Eltern + Kind) pro Lead: „wo liegen '
  'die Schwierigkeiten". Reveal-Metadatum, NIE Input für lsa_start / die '
  'Aufgabenauswahl — strukturell entkoppelt (kein Join-Pfad in den LSA-Pool).';
comment on column lead_assessments.weak_topics is
  'Optionale Themen-Tags (an leads.known_weak_topics angelehnt). Reveal-Metadatum, '
  'NICHT der Ziehalgorithmus. lsa_start liest diese Spalte nicht.';

create index if not exists lead_assessments_lead_idx
  on lead_assessments (lead_id);

-- ============================================================================
-- RLS: nur coach/admin lesen und schreiben. Kein Schüler, kein Eltern-Konto
-- (die Erhebung läuft über das Coach-/Autoren-Tool, Ebene B). anon bekommt nicht
-- einmal das Tabellen-Tor — Kind-Einschätzungen sind sensibel (Defense in Depth;
-- es gibt ohnehin keine anon-Policy). authenticated behält das Tabellen-Tor,
-- RLS gated auf coach/admin.
-- ============================================================================
alter table lead_assessments enable row level security;
revoke all on lead_assessments from anon;

create policy "lead_assessments_coach_admin_all" on lead_assessments
  for all
  using (public.get_my_role() in ('coach','admin'))
  with check (public.get_my_role() in ('coach','admin'));

commit;
