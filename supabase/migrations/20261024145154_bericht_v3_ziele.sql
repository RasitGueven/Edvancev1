-- Eltern-Bericht v3 (Gründerrunde 24.10.2026): Ziele nur nach Bestätigung im Gespräch.
--
-- lsa_report_notes.ziele_bestaetigt — der Coach hat die Ziele für die nächsten 6 Monate im
-- Gespräch bestätigt. Erst dann zeigt Seite 5 Ziele: das Zielbild des Coachs (zielbild), sonst
-- den Systemvorschlag aus Schwerpunkten und Paket. Ohne Bestätigung entfällt der Abschnitt; so
-- erscheinen unbestätigte Freitexte oder Testeingaben nie im Bericht.
--
-- RLS: Spalte fällt unter die bestehende Policy lsa_report_notes_coach_admin_all. Keine
-- Rechteänderung. Rollback: supabase/rollback/20261024145154_bericht_v3_ziele.sql.

alter table public.lsa_report_notes
  add column ziele_bestaetigt boolean not null default false;

comment on column public.lsa_report_notes.ziele_bestaetigt is
  'Bericht v3: true, wenn die Ziele (Zielbild oder Systemvorschlag) im Gespräch bestätigt sind; sonst zeigt der Bericht keine Ziele.';
