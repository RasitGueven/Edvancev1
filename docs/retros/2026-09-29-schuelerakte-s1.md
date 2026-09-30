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

- 30.09., Rasit:
  - Coaches aus `/admin/leads` und `/admin/slot-auswahl` genommen (`ProtectedRoute` mit Umleitung aufs Coach-Dashboard, Kachel entfernt).
  - Im Sessionplan keine Ausnahme; „Unbenannt“ bei Testkindern ohne Vertrag ist gewollt.
  - Rest-Lesezugriff → Folgepaket S1b (`docs/schuelerakte/folgepaket-s1b-coach-lesezugriff.md`).

## Prod-Belege (30.09.2026, eingespielt mit einmaliger Freigabe Rasit)

Vorher lief Vercel Production seit 08:26 UTC mit `f6ce875` (#174), aber ohne diese Migrationen.

| Migration | eingespielt (UTC) | Ergebnis |
|---|---|---|
| `20260929100000_schuelerakte_basis` | 08:37:35 | rc=0; `schule_id` bei 1 Kind vorbelegt, 2 Anwesenheitszeilen `unknown` → `planned` |
| `20260929100100_schuelerakte_akte` | 08:37:46 | rc=0; Report 1 für 3 Kinder nachgetragen |
| `20260929100200_coach_rls` | 08:42:46 | rc=0; Vorbedingung (12 Admin-Policies auf Vertragstabellen) erfüllt |

- **pg_proc-Scan (Prod):**
  - `attendance` nur in `einheit_verbraucht`, `akte_basis`, `einheiten_stand_intern`.
  - Kein Aufrufer von `vertrag_abschliessen`.
  - Einzige INVOKER-Funktion auf `students`/`leads`/`profiles`/`parent_student` ist `students_guard_provisional`.
  - Dieselben 5 fremden Policies wie lokal.
  - 18 Funktionen ohne Überladung.
- **EXPLAIN ANALYZE `board_schueler` (Admin, Prod):** 5 Akten, `Execution Time: 4.662 ms`.
- **Tests gegen Prod** (alle mit ROLLBACK):
  - `einheiten_stand_test.sql` 58/58 OK.
  - `supabase/checks/schuelerakte_abschluss.PRUEFUNG.sql` 6/6 ok.
  - `coach_rls_test.sql` 42/42 OK (nach P5b erneut 42/42).
- **Rollback-Datei:** gegen die eingespielte Version gelesen (4 Policies wortgleich wiederherstellbar), nicht ausgeführt.
- **Veraltet seit P5b:** Der Kommentar in `20260929100100_schuelerakte_akte.sql:32` („Abweichung zu hat_zugang, nicht angeglichen“) stimmt nicht mehr. `hat_zugang` schließt jetzt den widerrufenen Folgevertrag aus (P5b, `20260930100200`).

## Offen
- Befund zur Annahme „jedes Kind in einer regulären Session hat eine aktive Akte“: Das stimmt nicht.
  - `platz_assign` prüft kein `hat_zugang` und betrifft ohnehin nur `lsa_sessions`.
  - Reguläre Sessions füllt `addStudentToSession` (direkter INSERT) ohne Prüfung.
  - `session_students_coach_rw` erlaubt Coaches, beliebige Kinder in eigene Sessions einzutragen.
  - Gemeldet, nicht geändert.
- Coaches lesen weiter `parent_reports`, `intake_sessions`, `lead_assessments`, `lsa_sessions` aller Kinder → S1b.
- Prod-Belege (pg_proc-Scan, EXPLAIN ANALYZE, Testdateien, Screenshots als Coach) nach dem Einspielen.
- `supabase/functions/generate_parent_report/index.ts` ist schon vor S1 über 400 Zeilen.
