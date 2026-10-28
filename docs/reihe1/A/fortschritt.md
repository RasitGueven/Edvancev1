# Bauauftrag A · Fortschritt

Protokoll für Rasit. Eine Zeile je Schritt: Datum · Phase · Ergebnis · PR.

| Datum | Phase | Ergebnis | PR |
|---|---|---|---|
| 2026-10-27 | Schritt 0 | Worktrees `../Edvancev1-A` (feat/rasit-reihe1-a0 ab origin/dev 74b5b4b8) und `../edvance-app-A` (feat/rasit-reihe1-a3-app ab origin/dev e4cf268) angelegt, `.env` kopiert (ignoriert), Paket nach docs/reihe1 entpackt, Unterlagen gelesen | – |
| 2026-10-27 | A0 · HALTEPUNKT | Doppel-Aufgaben: 1184 mit `einsatz @> {lsa,session}`, 146 davon ready, 144 tatsächlich in beiden Pools, 12 in beiden gezogen. Keine Lesart ergibt „rund 40“; Grenze 10–80 überschritten. Liste: `doppel-aufgaben.md`, `doppel-aufgaben-im-pool.csv`. **STOPP bis Rasit antwortet.** | – |
| 2026-10-27 | A0 · Entscheidung | Rasit: alle 1184 → lsa, Default entfällt, VERA8 komplett löschen (eigene Migration, Sicherung außerhalb des Repos), siehe `entscheidung-rasit-a0.md`. Weiter. | – |
| 2026-10-27 | A1 · VERA8 · HALTEPUNKT | VERA8 = `source='VERA8_IQB'`, 299 Aufgaben. 66 LSA-Antworten aus 9 LSA-Sitzungen (Juli, 2 Kinder) verweisen darauf → **STOPP für das Löschen von VERA8** (Entscheidung 2b). Liste: `vera8-verweise.md`. Pool-Trennung und alles andere laufen weiter. | – |
| 2026-10-27 | A0 | Ist-Analyse `ist-analyse.md` fertig (Fragen 1–11, Zuordnung Konzept → Schema, 39 fehlende `qf_`-Schlüssel). Wegwerf-DB `~/wegwerf-db-reihe1a` (Port 55461): Grundstand 73 Tests grün, 8 rot = genau `bekannt-rot.txt`. | [#333](https://github.com/RasitGueven/Edvancev1/pull/333) |
| 2026-10-27 | A0b | Schnittstellen-PR edvance-app: `src/components/aufgaben/formate/` (AufgabeFormatProps, 6 Platzhalter, `AufgabeFormat`), `Loesungsbeispiel.tsx`; Props im DATENVERTRAG §13.1. **Bitte zuerst mergen, C und D warten darauf.** | (PR folgt) |
| 2026-10-27 | A1 | Migration `20261027130250_reihe1_a1_pool_trennung`: 1184 → lsa, Default weg, CHECK nie beide/nie leer, Guard, `pruef_board.pool`. pgTAP `reihe1_a1_pool` 16/16, Suite 74 grün / 8 bekannt rot. Zweitprüfung: `zweitpruefung-a1.md`. Pool in Lena-Board und Item-Pflege. Einspielen: `~/einspielen/A-1-pool_trennung.sh` (wartet auf Rasit). | (PR folgt) |
| 2026-10-27 | A2 | Vier Migrationen: Schema (bauformen, Versionen, Prüfungen, Bewährung, Meldungen, gesehen, tasks-Spalten), 39 `qf_`-Schlüssel, A-Funktionen §9, Prüfung/Freigabe/Bewährung. pgTAP `reihe1_a2_funktionen` 43/43 (Abnahme 6–10 ohne Board), Suite 75 grün / 8 bekannt rot. Zweitprüfung `zweitpruefung-a2.md` (18 Befunde, alle abgearbeitet). Einspielen: `~/einspielen/A-2-datenmodell.sh` (setzt A-1 voraus). | (PR folgt) |
| 2026-10-27 | Einspielen | Anweisung Rasit: „alle Migrationen selbst einspielen“ — ab jetzt EINSPIELEN = orchestrator (nach grüner Zweitprüfung, Prüfung per dbread, bei Fehler Rollback + STOPP der Phase). | – |
| 2026-10-27 | A3 Backend | Zwei Migrationen: sechs Formate (input_type, CHECKs), reine Wertung `format_werten_daten`, `session_bewerten` für neue Formate, Generator `parabel` + `pruefe_parabel` (18 pytest), Optionsfiguren, Kindersicht. pgTAP `reihe1_a3_formate` 44/44, Suite 76 grün / 8 bekannt rot. Zweitprüfung `zweitpruefung-a3.md` (16 Befunde abgearbeitet). | (PR folgt) |
| 2026-10-27 | A3 Vorschau + Player | Migration `20261027141615_reihe1_a3_vorschau` (Lenas Vorschau = Tablet-Payload für Formate und Instanzen), Web-`FormatAnsicht` in `PreviewStage`. Player edvance-app: sechs Formate + Lösungsbeispiel, Vorschau `/aufgaben/vorschau`, Ansichtstests 56/56 (4 Größen × 7 × leer/beantwortet), Fotos `abnahme/formate/`. Web-Gate grün (3120 Tests). | #342 |
| 2026-10-27 | A4 | Bauform-Motor `scripts/bauformen/` (Basis, sympy-Nachrechnen, Prüfmaschine 7 Prüfungen mit Wertung gegen Prod, Export, CLI `tools/bauform.sh`), 13 Negativkontrollen grün. Trigger-Migration `20261027142701_reihe1_a4_versionswechsel` (pgTAP `reihe1_a4_motor` 6/6). Pilot WZ-1 (26 grün) und NP-2 (83 grün), Blindlöser je 10/10. Zweitprüfung `zweitpruefung-a4.md` (11 Befunde). Suite 77 grün / 8 bekannt rot. | (PR folgt) |
| 2026-10-27 | A5 (Zwischenstand) | Migration `20261027143548_reihe1_a5_board` (Liste, Detail mit 6 Beispielen, Auffällig, Prüffragen), pgTAP `reihe1_a5_board` 16/16 (Abnahme 6 und 7). Web: Bauform-Liste mit Reitern, Prüfansicht (Tasten 1/2/3), Melde-Knopf im Coach-Live-Kind-Detail; Tests grün. **Offen:** Zweitprüfung, Einspielen, Ansichtsfotos, PR fertigstellen. Danach A6, A7. | Draft |
| 2026-10-28 | A5 | Branch per `git merge origin/dev` aktualisiert (kein Rebase). Merge-Bericht `docs/reihe1/merge/bericht.md` gibt es nicht; die Session-Auswahl-Tests (session_a2/a2b/a2d, session_f1/f2, reihe1_d2) sind nach #358 grün, Auftragspunkt 4 entfällt. Zweitprüfung `zweitpruefung-a5.md` (kein P1, 10 Befunde abgearbeitet/begründet), pgTAP `reihe1_a5_board` 21/21, Suite 91 grün / 8 bekannt rot, Web-Gate grün (3224). Melde-Knopf jetzt über den Einbaupunkt von C (`AufgabeEinbau`), keine Änderung mehr an `SchubladeBloecke`. Eingespielt (Orchestrator): `~/einspielen/A-5-board.sh`, Prüfabfrage `5` ✓. Fotos `abnahme/board/` (7). | [#352](https://github.com/RasitGueven/Edvancev1/pull/352) |

## Abweichungen

- **pruefung_entscheiden** heißt im Schema `pruef_entscheiden`; **wertung_testen** heißt `pruef_wertung_testen`.
- **Coach-Prüffragen** haben schon einen Ort: `skill_pruefung` (leer). A2.8 legt keine neue Tabelle an, sondern ergänzt `geprueft_von`.
- **Kein pg_cron, kein Vercel-Cron:** Die Bewährung läuft als Trigger nach dem Speichern einer Session-Antwort.
- **Pool = `tasks.einsatz`** statt neuer Spalte (Auftrag A1.1 „vorhandene Markierung wiederverwenden“). `check`/`quest` bleiben eigene Einsätze ohne Pool; „not null“ besteht schon.
- **Pool ändern in der Oberfläche:** Item-Pflege und Lena-Board zeigen den Pool; ein Bearbeiten-Feld für Admins gibt es nicht (Bestand ist ganz lsa, Instanzen setzen session über die Migration). Ändern geht für Admins über die Datenbank; der Guard sperrt alle anderen.
- **Rollback ohne Entfernen von Tabellen:** Guard-Hook und Leitplanke sperren das. Der Rollback des A2-Schemas legt das Modell still (Trigger, Policies, Rechte weg) und lässt die leeren Tabellen und Spalten stehen.
- **Offen (Auth/RLS, braucht Rasit):** `read_tasks_by_role` lässt angemeldete Rollen `ready`-Zeilen aus `tasks` direkt lesen, also auch `params`/`pruefmaschine` freigegebener Instanzen. Vorschlag in `zweitpruefung-a2.md`.
- **Types edvance-app (offen, braucht Rasit):** `src/types/database.ts` neu erzeugen geht nur über die Windows-CLI (`cmd.exe /c "supabase gen types typescript --project-id ztcppihxqcphlqaguhma --schema public"`). Das Schreiben in die gesperrte Datei hat die Rechteprüfung abgelehnt. Die Ausgabe vom 27.10. liegt im Scratchpad (`database.ts`). Die A-Komponenten nutzen eigene Typen (`formate/typen.ts`), typecheck ist grün.
- **WZ-1 Stufe 1:** Zahlenraum c = 9…400 (bis 20², wie QW-1) statt bis 144, sonst gäbe es zu wenige verschiedene Aufgaben. Kleine Zahlenräume (WZ-1, NP-2 Stufe 1/2) ergeben 4–5 statt 8 Instanzen je Rolle, weil ein Kind dieselbe Aufgabe nie in zwei Rollen sehen soll.
- **Types in Edvancev1** sind handgeschrieben (kein Generator); „Types neu generieren“ betrifft nur edvance-app (`supabase gen types`, Datei per Hook gesperrt).

## Einspielen (wartend / erledigt)

| Skript | Stand | Prüfabfrage |
|---|---|---|
| `~/einspielen/A-5-board.sh` | eingespielt 28.10.2026 (Orchestrator) | `5` ✓; Prod-Abzug = Branch (bis auf Server-Version) |
| `~/einspielen/A-1-pool_trennung.sh` | eingespielt 27.10.2026 (Orchestrator) | `0 \| 1186` ✓ |
| `~/einspielen/A-4-motor_pilot.sh` | eingespielt 27.10.2026 (Orchestrator) | `NP-2 zur_pruefung 83 \| WZ-1 zur_pruefung 26` ✓ |
| `~/einspielen/A-3b-vorschau.sh` | eingespielt 27.10.2026 (Orchestrator) | `true` ✓ |
| `~/einspielen/A-3-formate.sh` | eingespielt 27.10.2026 (Orchestrator) | `2 \| 1 \| 1 \| 1` ✓ |
| `~/einspielen/A-2-datenmodell.sh` | eingespielt 27.10.2026 (Orchestrator) | `15 \| 39 \| 6` ✓; Prod-Abzug enthält alle A-Objekte des Branches (Abweichung nur `get_my_student_id`, von Auftrag D geändert) |
