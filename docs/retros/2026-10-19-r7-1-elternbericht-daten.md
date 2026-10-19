# Retro 19.10.2026 – R7-1 · Daten, Rechnung und Texte für den Eltern-Bericht R7

## Gebaut
- Muster E7, Maßblatt und Bauauftrag unter `docs/report/r7/`.
- Lesepfad: `ReportErzaehlung` bekommt `kompetenzen` (unveränderte Liste aus `loadUrteile`) und
  `katalog` (`skill_key` mit `klasse_herkunft`); R6 bekommt weiter nur die Schlüssel. `ReportData`
  bekommt `schulform` aus `students.school_type` (`loadSchulform`, Fehler → null).
- Typen in `src/types/elternbericht.ts`. Rechnung unter `src/lib/report/elternbericht/`:
  `themenfelder` (acht Felder), `bereiche` (Listen für Seite 1, `kopfFall`), `einordnung`
  (`ebeneFuer`, `bauePyramide`, `klassenAngabe`), `zaehlung` (Nenner „bis Klasse k“ als Vereinigung),
  `schwerpunkte` (Regel aus Entscheidung 7), `genitiv`, `bericht` (`baueElternbericht`).
- Fixtures: Ilkays echte Analyse (dbread, Auswahl über die ID), zwölf synthetische Fälle, Notizen,
  Pakete, `FAELLE`. Ein Test prüft transitiv, dass kein Fixture-Modul den Supabase-Client lädt.
- Namespace `elternbericht` (Anhang A wörtlich), Tokens `--color-eb-*`/`--font-eb-*` (Werte E7),
  Migration `20261019080220_r7_kopf_entwuerfe` (sechs Kopfsätze als Entwurf), Abnahmeliste
  `docs/report/r7/kopf-texte.md`, Invarianten INV-4.9/4.10.

## Entscheidungen
- Kein „Marke“-Wunsch vor dem Start → Muster-Werte (Fraunces, Navy #304969). Keine Einwände gegen
  Grün/Rosé → E7-Farben, INV-4.4-Ausnahme im Kommentar der Tokens; CLAUDE.md §11 folgt in R7-2.
- Fixture-Erzählung mit denselben reinen Funktionen wie der Lesepfad gerechnet statt als JSON
  abgelegt: kleiner, und sie folgt Änderungen an den Funktionen.
- `bereicheAus` entdoppelt nach Schlüssel, damit `sicher + uebung = untersucht` immer gilt.

## Ergebnis
- Ilkay: 27 von 130 untersucht, 11 sicher, 16 Übungsbedarf, 103 nicht untersucht. Zwei Ebenen.
  Schwerpunkte Geometrie, Brüche & Dezimalzahlen, Größen, Prozent & Dreisatz — wie im Bauauftrag
  vorhergesagt. Weitere Zahlen: `docs/report/r7/offene-punkte-r7-1.md`.

## Offen
- `docs/report/r7/offene-punkte-r7-1.md`: Nenner und Reihenfolge in der Abnahme entscheiden,
  Migration einspielen, Kopfsätze abnehmen, doppelte Komposition in `fixtures/basis.ts`.
