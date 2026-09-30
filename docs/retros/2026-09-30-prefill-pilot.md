# Retro 30.09.2026: Vorbefüllung für Lenas Prüfung, Pilot Mathe 8

## Was gebaut wurde

- **Bestandsaufnahme** (`docs/prefill/bestandsaufnahme.md`):
  - alle Felder, die Lena in der Item-Pflege sieht oder bearbeitet, mit Aufgaben- und Teilaufgabenebene getrennt
  - erlaubte Werte je Feld
  - Leerstand aus der Live-DB (nur gelesen)
  - fünf Lücken in der UI (L1–L5)
- **Pilot-Charge `mathe8-pilot`**: die ersten 25 offenen Aufgaben aus Lenas Warteschlange (Themengebiet „Algebra &
  Funktionen"). Die Quelle ist `docs/prefill/mathe8-pilot.json`, jeder Wert mit Sicherheit und Begründung. Daraus
  erzeugt `tools/prefill-build.mjs`:
  - die Migration `supabase/migrations/20260930120000_prefill_mathe8_pilot.sql`
  - die CSV für Lena
  - eine rein lesende Validator-SQL
- **Prüfer**: `tools/verify-tasks.mjs --prefill` (Kern in `tools/verify-prefill.mjs`, Rechnen in
  `tools/prefill-rechnen.mjs`). Er prüft Constraints und Kataloge, die Vollständigkeit je Feld und rechnet exakt
  mit Brüchen und Polynomen nach: Rechnung, Probe, Formel und Termäquivalenz einschließlich „vollständig
  faktorisiert". Dazu kommt der Abgleich mit einem Blind-Löser. Tests: `tests/prefill.test.ts`, mit Mutanten.

## Entscheidungen

- **Stoffanker** ist `tasks.curriculum_grade`. Es gibt keine Katalogtabelle, der Katalog ist 5–13. Wo die
  Klassenstufe nicht eindeutig ist, bleibt das Feld leer, auch wenn das C10-Audit dieselbe Aufgabe schon offen
  gelassen hat.
- **Herkunft** (`source`, `source_ref`) ist im ganzen Bestand gesetzt. Es gibt nichts zu tun.
- **Zeitbudget:** eine feste Regel statt Einzelschätzung. Gesetzte MULTI_PART-Platzhalter bleiben stehen und werden
  als Befund gemeldet.
- **Nicht vorbefüllt wird, was Lena nicht sieht:** `acceptance`, `option_scores` und `parts[].competency_process`.
  Ebenso wenig die Fachentscheidung `needs_image`. `coach_hints` bleibt vorerst leer und ist offen für die
  Entscheidung.
- **Blind-Löser statt LLM-Stufe:** Der `ANTHROPIC_API_KEY` in `.env` liefert weiter 401. Stattdessen hat ein separater
  Agent ohne Zugriff auf die Lösungen gelöst, und das Skript vergleicht. Alle 28 eindeutigen Antworten stimmen
  überein; die einzige Abweichung ist ein defekter Bestandswert (#18 Teil 2).
- **Kein Ziel-DB-Guard in der Migration:** CI spielt in die DB `neuaufbau` ein. Der Check steht in der Apply-Kette.
- **Syntax gegen das Live-Schema geprüft:** mit `EXPLAIN` für jede Anweisung in einer read-only-Transaktion, ohne
  Ausführung. Die lokale Shadow-DB war laut Auftrag tabu.

## Offene Punkte

- **Rasit:** Migration einspielen (Befehl in `docs/prefill/README.md`), dann mit Lena prüfen und den Rest freigeben.
- **Entscheidungen:** `coach_hints` vorbefüllen, ja oder nein. Marker „vorbefüllt vs. geprüft" nach
  `docs/prefill/vorschlag-prefill-marker.sql` (Auth/RLS, Consensus-Trigger).
- **L1:** `cluster_id` wird in der Item-Pflege nicht gespeichert. Eigener Fix-PR, bevor im Restbestand Themengebiete
  vorbefüllt werden.
- **Befunde A1–A3** (falsch wertende Bestandsantworten): Korrektur durch Lena oder einen beaufsichtigten Fix.
- **Restbestand (Schritt 5)** erst nach Freigabe: pro Themengebiet eine Charge, dazu vorher einen frischen Snapshot
  ziehen.
