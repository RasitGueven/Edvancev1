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
- ~~**Befunde A1–A3**~~: Diese falsch wertenden Bestandsantworten betrafen nur VERA8. Nach dem Nachtrag entfallen sie
  für Lenas Prüfung, die Daten bleiben unverändert.
- **Restbestand (Schritt 5)** erst nach Freigabe: pro Themengebiet eine Charge, dazu vorher einen frischen Snapshot
  ziehen.

## Nachtrag: VERA8 ausgeschlossen

Neue Entscheidung: VERA8 wird nicht vorbefüllt und erscheint nicht im Lena-Board. Die Daten bleiben unverändert.

**Definition:** `tasks.source = 'VERA8_IQB'`, einmal zentral in `src/lib/authoring/vera8.json` und `vera8.ts`.
Stand heute sind das 299 Aufgaben, Grenzfälle gibt es keine. Die drei verstreuten Literale in `grounding.ts`,
`flags.ts` und `attribution.ts` nutzen jetzt diese Definition.

**Pilot:** Die ursprüngliche Auswahl enthielt **7** VERA8-Aufgaben, nicht 10 wie im ersten Bericht angegeben. Übrig
bleiben 18 Binom-Aufgaben, aufgefüllt wurde nicht. Die Migration ist in derselben Datei neu erzeugt: 72 Anweisungen,
jede mit VERA8-Ausschluss. Ergebnis: 0 Charge-Fehler und 0 Bestands-Befunde.

**Board:**

- `boardBestand()` filtert VERA8 direkt nach dem Laden. Das Board zeigt dadurch 362 statt 661 Aufgaben.
- Die Pflege-Strecke überspringt VERA8 im Board-Kontext.
- `freigabe_cluster` bekommt den Ausschluss als eigene Migration (**nicht eingespielt**).
- Expertenliste, Content-Gesundheit und Editor bleiben unverändert. Die Expertenliste nutzt dieselbe Abfrage
  (`listAuthoringTasks`), deshalb sitzt der Filter im Board.

**Offen:** `supabase/schema-erwartet.sql` ist noch nicht neu erzeugt. Ein Hook sperrt das Handeditieren, und
`tools/schema-snapshot.sh` braucht eine lokale DB. Bis zum neuen Snapshot bleibt der Schema-Job in CI rot.
