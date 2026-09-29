# Retro 2026-09-29 — Schülerakte S1 (Datenmodell, Einheiten-Stand, Notizen, Reports, Coach-Rechte)

## Was gebaut wurde
- Drei Migrationen (nur Datei, Rasit spielt ein): `20260929100000_schuelerakte_basis`, `20260929100100_schuelerakte_akte`, `20260929100200_coach_rls`, dazu `docs/schuelerakte/rollback_coach_rls.sql`.
- Akte = students-Zeile, Zustand abgeleitet (`akte_aktiv`, `akte_basis`, View `schuelerakten`), `einheiten_rechnung` / `einheiten_stand` / `board_schueler`, Notizen nur anhängen mit Wortliste, `eltern_reports` unveränderlich, Report 1 = LSA in `vertrag_abschliessen`, Fächer beim Folgevertrag.
- Anwesenheit: `planned | present | cancelled | unexcused | cancelled_by_us`; Session-UI mit „anwesend“ / „nicht erschienen“.
- `lsaReport.ts`: Lead-Rückweg über `leads.converted_student_id`, gelesen über die schmale RPC `lsa_lead_kontext`.
- Tests: `tests/sql/einheiten_stand_test.sql` (58 Zeilen), `tests/sql/coach_rls_test.sql` (42), `supabase/checks/schuelerakte_abschluss.PRUEFUNG.sql` (6), alle lokal grün auf einer Wegwerf-DB aus allen Migrationen.

## Entscheidungen
- `betriebstage` rechnerisch statt Tag für Tag: 300 Akten ~100 ms statt ~500 ms (lokal). Gleichheit mit `betriebstag()` ist ein eigener Prüfpunkt.
- Pfingstferientage 2028-06-06 und 2030-06-11 stehen nicht in der amtlichen Ferienordnung — Rasit: bleiben wie im Bauauftrag.
- `ruhend_seit`: widerrufene Verträge zählen nicht, `gekuendigt_zum` vor `vertrag_ende` (Befund Consensus-Check).
- `einheiten_rechnung` liefert ohne Vertrag keine Zeile statt eines Fehlers (sonst brach das Board an jeder ruhenden Akte).

## Offen
- Coach-Strecke `/admin/leads` und `/admin/slot-auswahl` (Lead anlegen, Kiosk starten) funktioniert nach `coach_rls` für Coaches nicht mehr; Namen von Kindern ohne aktive Akte fehlen im Sessionplan. Entscheidung Rasit nötig, bevor Migration 3 eingespielt wird.
- Coaches lesen weiter `parent_reports`, `intake_sessions`, `lead_assessments`, `student_subscriptions`, `lsa_sessions` aller Kinder (außerhalb Entscheidung 12).
- Prod-Belege (pg_proc-Scan, EXPLAIN ANALYZE, Testdateien, Screenshots als Coach) nach dem Einspielen.
- `supabase/functions/generate_parent_report/index.ts` ist schon vor S1 über 400 Zeilen.
