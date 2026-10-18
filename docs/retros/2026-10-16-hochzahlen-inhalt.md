# Retro 16.10.2026 – Hochzahlen im Aufgabentext

## Gebaut
- `20261016151208_hochzahlen_inhalt.sql`: 15 Pilot-Aufgaben (Knoten `potenzen`) zeigen Hochzeichen statt `^`
  („-2^2“ → „-2²“). Geändert werden nur `tasks.question` und die Kopie in `question_payload.prompt`, gezielt per id
  mit dem Vorher-Text in der WHERE-Bedingung. Ein zweiter Lauf ändert 0 Zeilen.
- `tools/hoch-wegwerf-db.sh` + `tools/hoch-abnahme.sql`: Prod-Fixture, Migration zweimal, Abnahme (nur Text geändert,
  Lösungen, Hinweise, Prüfstatus und Befunde unverändert), Neuaufbau wie CI.

## Entscheidungen
- Minus bleibt „-“: `potenzen` und alle Knoten bis Klasse 8 schreiben im Pilot „-“.
- 5c73a51d (2^5) ausgelassen: Fraunces 500 (Schrift des Aufgabentexts auf dem Tablet) hat kein ⁵ (auch kein ⁶–⁹, ⁻, ⁿ).

## Befunde (nichts geändert)
- `^` steht im Pilot nur im Aufgabentext. Nicht in Teilaufgaben, MC-Optionen, Musterlösungen, Hinweisen,
  `correct_answers` oder `acceptance`.
- Das Tablet kennt die Eingabemodi Zahl, Bruch und Term (nur `ax+b`). Eine Hochzahl kann ein Kind nicht eintippen.
- Die TERM-Bewertung ist ein Stringvergleich: `x²+6x+9` gilt als richtig, `x^2+6x+9`, `x*x+6x+9` und `9+6x+x²` nicht.
  Heute betrifft das keine Aufgabe: Die offenen Binom-Aufgaben aus #258 sind NUMERIC, und keine TERM- oder
  SHORT_TEXT-Aufgabe hat eine Hochzahl in der Antwort.
- `lsa_ziffernfolge` zählt „²“ nicht als Ziffer. Das betrifft nur `tasks_zahlen_guard` (für Rolle authenticated).

## Offen
- 5c73a51d: Fraunces um ⁵ ergänzen bzw. Hochzahl im Tablet in der Grotesk setzen, oder Aufgabe als „2 · 2 · 2 · 2 · 2“.
- Bevor offene Term-Aufgaben mit Quadrat kommen, braucht das Tablet eine Eingabe für Hochzahlen und die Bewertung
  eine Normalisierung (x^2 = x² = x*x, Reihenfolge).
