# Retro 2026-10-08 · Session P1 · C3 Schublade der Coach-Live-Sicht

**Gebaut**
- `session_schritte.details` (jsonb, Standard `{}`): Die Engine legt beim Auswerten des Fensters richtig, von, Ziel
  und Änderung ab, beim Einmischen den Mischanteil. `session_naechster_schritt` schreibt das mit. Sonst ändert sich
  am Verhalten nichts (Migration `20261011100100`).
- `coach_kind_detail`: `pfad_vorschlag`, `heute`, `erklaer_kernideen`, `schritt_details` (Migration `20261011100200`).
- Abbildung `coachLiveSchublade.ts`. Fehlende Felder bleiben null und die Schublade lässt die Zeile weg.
  Texte in `coachLive.json`, Datenvertrag Abschnitt 9 (nur Coach).
- Tests: pgTAP `session_c3` (54), Vitest Abbildung und Schublade (21), Fixtures aus der Wegwerf-DB
  (`docs/session/c3-coach-beispiele.sql`).

**Entscheidungen**
- Ablage der Zahlen in einer neuen Spalte `session_schritte.details`. Kein neues Ereignis und kein Nachrechnen
  beim Lesen (Rasit, 08.10.).
- Der Pfad-Vorschlag erscheint nur bei offenem Signal oder nach „Ändern“. Danach gilt die Entscheidung wie in C2.
- Gibt es einen Warm-up-Beleg von heute, entfällt der Session-Beleg derselben Session (sonst doppelt gezählt).

**Offen:** `docs/session/offene-punkte-c3.md` (Schema-Abzug nach dem Einspielen, Grund im Zielbereich,
Fehlbild-Datum über alle Skills).
