# Zweitprüfung A1 (Migration 20261027130250_reihe1_a1_pool_trennung)

Frischer Subagent ohne Kontext, nur Migration, Konzept §3–6 und §9, Frage „Was ist falsch, was fehlt, was bricht?“ (27.10.2026).

| # | Befund (Kurzfassung) | Schwere | Abarbeitung |
|---|---|---|---|
| 1 | Einfügewege ohne `einsatz` scheitern bzw. erzeugen NULL | hoch | Spalte ist schon `not null` (A0, dbread). pg_proc: keine Funktion mit `insert into tasks(` (dbread). pgTAP-Fixtures angepasst (47 Dateien, Grundstand wieder 73 grün / 8 bekannt rot). Alte Chargen-Generatoren unter `tools/`, `scripts/` im Kopf der Migration genannt. |
| 2 | `cardinality(NULL)` lässt NULL durch | hoch | entfällt: `not null` besteht schon. |
| 3 | Bestehende `{}`/NULL brächen die Migration | mittel | dbread: 0 leer, 0 NULL; Werte sind durch `tasks_einsatz_check` begrenzt. |
| 4 | Vorher-Stand nicht rückverfolgbar, Zahl nur behauptet | mittel | Rollback stellt `{lsa,session}` exakt her (alle vor A1 außer drei namentlich genannten IDs). Nachprüfung in der Migration: `raise`, wenn noch eine Aufgabe beide trägt. |
| 5 | `disable trigger` könnte mehr abschalten | mittel | `tasks_pruef_version` setzt nur `pruef_version` (Prod-Definition gelesen). Andere UPDATE-Trigger laufen weiter und reagieren nicht auf `einsatz`. |
| 6 | `create or replace` des Guards könnte Attribute verlieren | mittel | Gegen Prod-Fassung verglichen: ohne `security definer`, ohne `search_path`; neu ist nur die Zeile `einsatz`. |
| 7 | `drop`/`create pruef_board`: Kommentar, Grants, Abhängigkeiten | mittel | Prod: kein Kommentar, Grants nur `authenticated` (übernommen), keine pg_depend-Kante, keine View. pgTAP-Signaturtest und TS-Typ nachgezogen. |
| 8 | Session-Anlässe fallen für den Bestand still weg | mittel | gewollt; im Kopf der Migration und in der PR genannt. |
| 9 | Session vor Ort zieht ab dem Einspielen nichts | mittel | Entscheidung Rasit Punkt 5; Zeitpunkt des Einspielens wählt Rasit; im Skript und in der PR genannt. 0 Aufgaben nur `{session}` (dbread). |
| 10 | Views, Policies, Frontend nicht durchsucht | mittel | dbread: keine View, keine Policy mit `einsatz`; `src/lib` filtert nicht auf `einsatz`. |
| 11 | Sperren | niedrig | unkritisch, keine Änderung. |
| 12 | `{lsa,check}` zeigt nur lsa | niedrig | Kommentar ergänzt. |
| 13 | „Pool“ = `einsatz` in den Datenvertrag | niedrig | DATENVERTRAG §13.2. |
| 14 | INSERT durch Nicht-Admins | – | RLS `admin_write_tasks`: nur Admins schreiben `tasks`. |
