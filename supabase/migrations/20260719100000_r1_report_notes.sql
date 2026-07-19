-- ============================================================================
-- R1: lsa_report_notes — die einzige schreibbare Flaeche des Eltern-Reports
--
-- Der Eltern-Report (src/pages/admin/ReportPage.tsx) liest die Sitzung und ihre
-- Antworten READ-ONLY. Genau drei Felder gehoeren dem Coach und muessen bleiben:
-- Zielbild, Empfehlung, Paket. Sie sind KEINE Auswertung — sie aendern weder
-- lsa_sessions noch lsa_responses und erzeugen keinen Score. Deshalb eine
-- eigene Tabelle statt Spalten an der Sitzung: die Sitzungsdaten bleiben
-- unberuehrt, und der Report kann geloescht/neu geschrieben werden, ohne dass
-- ein Rohdatensatz angefasst wird (§6: Rohdaten append-only).
--
-- 1:1 zur Sitzung (session_id unique) — der Client schreibt per upsert auf
-- session_id, ein Report pro Sitzung. on delete cascade haengt die Notizen an
-- den bestehenden DSGVO-Loeschanker (leads → students → lsa_sessions → hier).
--
-- paket ist ein CHECK statt eines Enums: die Paketnamen sind Vertriebs-Sprache
-- und aendern sich schneller als ein Typ, der in Funktionssignaturen einfriert.
-- ============================================================================

begin;

create table if not exists lsa_report_notes (
  id         uuid primary key default gen_random_uuid(),
  session_id uuid not null unique references lsa_sessions(id) on delete cascade,
  zielbild   text,
  empfehlung text,
  paket      text check (paket in ('basis','standard','premium')),
  updated_at timestamptz not null default now(),
  updated_by uuid references profiles(id) on delete set null
);

comment on table lsa_report_notes is
  'Coach-Freitexte am Eltern-Report (Zielbild, Empfehlung, Paket). Kein '
  'Auswertungsdatum — die Sitzungsdaten bleiben unberuehrt.';

create index if not exists lsa_report_notes_session_idx
  on lsa_report_notes (session_id);

alter table lsa_report_notes enable row level security;
revoke all on lsa_report_notes from anon;

create policy "lsa_report_notes_coach_admin_all" on lsa_report_notes
  for all
  using (public.get_my_role() in ('coach','admin'))
  with check (public.get_my_role() in ('coach','admin'));

commit;
