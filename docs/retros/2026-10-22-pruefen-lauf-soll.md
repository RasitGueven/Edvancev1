# Retro 22.10.2026 – P4: Lenas Prüflauf folgt dem Bedarf

## Ausgang
Lena landete beim Durchgang in anderen Themen, ohne es zu merken: `naechsteOffene()` lief stur die
Board-Reihenfolge ab und kannte die Sollzahlen nicht. Bauauftrag docs/pruefen/Bauauftrag-P4.md.

## Gebaut
- `src/lib/pruefung/lauf.ts`: `naechsteNoetige(board, soll, aktuell, uebersprungen, opt)` mit grund
  `gleiches_thema | themenwechsel | stufenwechsel | ohne_soll | fertig`. Reihenfolge wie die Übersicht:
  aktueller Reiter zuerst (nur LSA), Thema nach `sortiereThemen`, Knoten nach `knotenDesThemas`, Aufgabe nach
  Board. Übersprungene ans Ende ihres Themas. Ohne Sollzahlen der alte Weg. Dazu `ersteNoetigeImThema`,
  `restImThema`, `knotenOhneAufgabe` (Entscheidung 8) und `nachrechnen` (lokal wie `pruef_board_soll`).
- `usePruefLauf.ts`: lädt die Sollzeilen des Bereichs (`ladeSoll`, auch von der Übersicht benutzt), rechnet nach
  einer Entscheidung und bei „Rückgängig“ sofort nach und gleicht im Hintergrund ab.
- Prüfansicht: Zwischenbild `Themenwechsel.tsx` bei Themen- und Stufenwechsel (Enter = Weiter, kein Modal).
  Im Kopf steht „Thema · Knoten · noch n nötig im Thema“. `?ohneSoll=1` nach „Weitere Aufgaben ohne Soll prüfen“.
- Übersicht: „Als Nächstes“, Enter und „Prüfen“ je Thema folgen dem Bedarf. Ist alles erfüllt, zeigen Karte und
  Abschluss „Alles Nötige geprüft“ mit zwei Knöpfen, der Abschluss dazu die Knoten ohne offene Aufgabe.
- Tests: `lauf.test.ts` (18), je drei neue Fälle in Prüfansicht und Übersicht. `Umstieg.test.tsx` braucht den
  Mock für `getPruefSoll`, weil die Prüfansicht die Sollzahlen jetzt selbst lädt.

## Entscheidungen
- Ohne aktuelle Aufgabe (Start aus der Übersicht) meldet `naechsteNoetige` `gleiches_thema`, also kein Zwischenbild.
- Ist das aktuelle Thema fertig, kommt erst das nächste Thema der Stufe und danach die Themen davor (wie
  `naechsteOffene`: „danach, dann von vorn“). Erst dann wechselt die Stufe.
- Session-Bereich: eine Folge über alle Stufen, nur `themenwechsel`.
- „Weitere Aufgaben ohne Soll prüfen“ erscheint nur, wenn noch offene Aufgaben da sind, damit kein Knopf ohne
  Wirkung bleibt.

## Offen
- Knoten mit Restbedarf nur wegen `min_ohne_mc` (z. B. `term_binom_quadrat` in Prod: 6 MC vor der einzigen
  Aufgabe ohne MC): Lena prüft nach Entscheidung 2 und Board-Reihenfolge erst alle MC-Aufgaben, die den Rest
  nicht senken. Ob dann Aufgaben ohne MC zuerst kommen sollen, entscheidet Rasit.
- Ändert Lena die Fertigkeit einer Aufgabe, rechnet die Seite den alten Knoten nach. Der Abgleich im
  Hintergrund korrigiert die Zahl, die Wahl der nächsten Aufgabe bleibt aber einmal ungenau.
