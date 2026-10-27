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

## Abweichungen

- **pruefung_entscheiden** heißt im Schema `pruef_entscheiden`; **wertung_testen** heißt `pruef_wertung_testen`.
- **Coach-Prüffragen** haben schon einen Ort: `skill_pruefung` (leer). A2.8 legt keine neue Tabelle an, sondern ergänzt `geprueft_von`.
- **Kein pg_cron, kein Vercel-Cron:** Die Bewährung läuft als Trigger nach dem Speichern einer Session-Antwort.
- **Pool = `tasks.einsatz`** statt neuer Spalte (Auftrag A1.1 „vorhandene Markierung wiederverwenden“). `check`/`quest` bleiben eigene Einsätze ohne Pool; „not null“ besteht schon.
- **Pool ändern in der Oberfläche:** Item-Pflege und Lena-Board zeigen den Pool; ein Bearbeiten-Feld für Admins gibt es nicht (Bestand ist ganz lsa, Instanzen setzen session über die Migration). Ändern geht für Admins über die Datenbank; der Guard sperrt alle anderen.
- **Rollback ohne Entfernen von Tabellen:** Guard-Hook und Leitplanke sperren das. Der Rollback des A2-Schemas legt das Modell still (Trigger, Policies, Rechte weg) und lässt die leeren Tabellen und Spalten stehen.
- **Offen (Auth/RLS, braucht Rasit):** `read_tasks_by_role` lässt angemeldete Rollen `ready`-Zeilen aus `tasks` direkt lesen, also auch `params`/`pruefmaschine` freigegebener Instanzen. Vorschlag in `zweitpruefung-a2.md`.
- **Types in Edvancev1** sind handgeschrieben (kein Generator); „Types neu generieren“ betrifft nur edvance-app (`supabase gen types`, Datei per Hook gesperrt).

## Einspielen (wartend / erledigt)
