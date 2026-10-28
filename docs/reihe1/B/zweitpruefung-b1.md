# Zweitprüfung B1 · Migration 20261027130817_studio_modell

Frischer Subagent ohne Kontext, Eingaben: Migration, Anforderung §12 (mit §2/§4), Konzept §9. Frage: „Was ist falsch, was fehlt, was bricht?“

| # | Befund | Schwere | Umgang |
|---|---|---|---|
| 1 | Erneutes Speichern lässt alte Check-Aufgaben in `erklaer_check` | kritisch | behoben: weggefallene Fassungen werden gelöst (nur Entwurfs-Kernideen), Test „nur die aktuelle Fassung hängt im E1-Modell“ |
| 2 | Fremdschlüssel auf `tasks` (Konzept §9) | kritisch | Fremdschlüssel entfernt; Schreiben nur aus plpgsql; Bedarf an A in `an-A.md` |
| 3 | E1-Prüfweg umgangen (geprüfte Kernidee bekommt neue Checks) | kritisch | behoben: Checks nur an Kernideen im Status `entwurf` |
| 4 | Prüfergebnis kommt vom Client | mittel | dokumentiert (Kopf der Migration); DB prüft Welten, Beats, Sprungmarke, Kernidee, Katalog, eine richtige Antwort |
| 5 | Hash ohne Rücksprünge und Skelett-Bildparameter | mittel | behoben |
| 6 | Langform `skill:kN` kann fremde Kernideen belegen | mittel | bewusst offen: V3 und V7 brauchen zwei Skills; Autoren sind vertrauenswürdig, Admin löst per Neuspeichern |
| 7 | Mini-Check ohne genau eine richtige Antwort | mittel | behoben (22023), Test |
| 8 | Zwillinge als eigene E1-Checks | mittel | behoben: nur `nr = 0` in `erklaer_check`, Test |
| 9 | Aufgaben bleiben `draft` | mittel | B5 setzt sie bei fachlicher Freigabe auf `ready` (im Kopf dokumentiert) |
| 10–12 | Meldungen bei fehlender Kernidee/Frage/Rückmeldung, widersprüchliche Rücksprünge | gering | behoben |
| 13 | Race bei `reihenfolge` | gering | offen (durch `unique(kernidee_id)` praktisch ausgeschlossen) |
| 14 | `beat_id` statt `beat_key` in `studio_ruecksprung` | gering | bleibt: Beats und Rücksprünge entstehen je Speichern gemeinsam neu; Freigaben (B5) verweisen auf `beat_key` |
| 15 | `studio_rolle_setzen` ohne Vorprüfung | gering | offen (Check-Constraint greift) |
