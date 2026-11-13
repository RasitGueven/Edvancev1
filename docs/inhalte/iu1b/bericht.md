# IU-1b · Bericht: Nachzug Inhalte-Übersicht

**Stand:** 13.11.2026. Grundlage: `docs/inhalte/iu1/bericht.md`, `offen.md` (O6). Keine Migration.

## Was sich ändert

1. **Lauf mit Prüfziel (O6):**
   - „Gezielt prüfen“ öffnet die Prüfansicht mit `?liste=gezielt&ziel=msa_zp10` (bzw. `&skill=…`). Die Prüfansicht
     lädt die Liste mit demselben Filter.
   - Nach einer Entscheidung geht es mit der nächsten Aufgabe derselben Liste weiter. Ist nichts mehr offen, führt
     der Lauf zurück zur gefilterten Liste. „Pause“ führt im gezielten Lauf ebenfalls dorthin zurück.
   - Ohne `ziel` und `skill` bleibt alles wie bisher. Entscheidungen und Korrekturrecht sind unverändert.
2. **Lenas MSA-Liste:**
   - Die vier Bereiche sind einklappbar. Anfangs ist nur der erste Bereich mit offenen Aufgaben offen.
   - Im Kopf jedes Bereichs steht „n Aufgaben offen“.
   - Der Klappzustand bleibt in der Sitzung erhalten (`sessionStorage`; ohne Speicher gilt der Anfangszustand).
3. **Inhalte-Übersicht, Reiter Lernstandsanalyse:**
   - Oben steht die MSA-Zeile, darunter die laufenden und kommenden Themen (Quartal, dann Schulen).
   - Themen, deren letztes Datum vor heute (Europe/Berlin) liegt, stehen am Ende unter der Zwischenzeile
     „Schon geschrieben“. `EdvanceTable` hat dafür jetzt eine optionale Abschnittszeile.
   - Stand 13.11.: 5 Themen unter „Schon geschrieben“ (Terme und Gleichungen, Zufall und Wahrscheinlichkeit,
     Pyramide/Kegel/Kugel, Reelle Zahlen, Quadratische Gleichungen).
4. **Zeitfenster:** Sind Anfangs- und Endmonat gleich, steht nur ein Monat da, ausgeschrieben („Q3 · März“).

## Belege

- typecheck, lint, Vitest 3416/3416. Neu sind:
  - Prüfansicht: Lauf mit Ziel und Kompetenz, Rückkehr zur MSA-Liste, Pause, ohne Ziel wie bisher
  - Liste: Bereiche einklappbar, Zustand bleibt
  - Seite: „Schon geschrieben“
  - Rechnungen: Reihenfolge, ein Monat, Pfad
- **Ansichtstests** bei 1180 × 820 und 1440 × 900, Fotos in `abnahme/`:
  - **Lauf** (`e2e-lauf`, 8/8), echte Prüfansicht mit Prod-Daten der U3-Vorschau:
    - Drei Entscheidungen in Folge bleiben in der MSA-Liste (`lauf-msa-nach-3`).
    - Der gefilterte Lauf bleibt bei einer Kompetenz und endet in der gefilterten Liste (`lauf-gefiltert-*`).
    - Bereiche und Rückkehr per Pause (`msa-bereiche`).
    - Ohne Prüfziel läuft es wie bisher.
  - **Sortierung** (`e2e-inhalte/sortierung.spec.ts`, 2/2, `sortierung-*`). Die bisherigen Inhalte- und
    Gezielt-Ansichtstests sind weiter grün (12/12, 6/6).

## Offen

- **O6** aus IU-1 ist erledigt.
- Die Lauf-Vorschau nutzt die Aufgaben-Fixture der Vitest-Tests als Inhalt. Geprüft werden Reihenfolge und Adresse,
  nicht der Aufgabentext.
