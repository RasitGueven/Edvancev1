# Retro 22.10.2026 – P4-MC: Aufgaben ohne MC im Prüflauf vorziehen

## Ausgang
Offener Punkt aus P4 (#304): In Knoten mit Restbedarf nur wegen `min_ohne_mc` hat Lena erst alle MC-Aufgaben
geprüft, obwohl die den Rest nicht senken (Prod: `term_binom_quadrat`, sechs MC vor `49²`). Entscheidung Rasit:
Aufgaben ohne MC kommen zuerst.

## Gebaut
- `lauf.ts`: `noetigImKnoten`. Ist `gezaehlt_ohne_mc < min_ohne_mc`, kommen erst die offenen Aufgaben ohne MC und
  danach die MC-Aufgaben. Ist dazu `gezaehlt >= soll`, fallen die MC-Aufgaben aus dem Lauf. In der Übersicht
  bleiben sie sichtbar. Die Typen kommen als `opt.mc` (Set der MC-task_ids), auch in `ersteNoetigeImThema`.
- `getAufgabenTypen(taskIds)` in `src/lib/supabase/pruefung.ts`: liest `tasks.input_type` in Blöcken zu 200.
  `ladeMc` in `usePruefLauf.ts`. Beide Seiten laden die Typen nach dem Board. Bei einem Fehler gilt die Regel
  nicht und der Lauf bleibt wie nach #304.
- RLS geprüft (dbread, Claims von Lena, `set local role authenticated`): `read_tasks_by_role` lässt Coaches
  alle Aufgaben lesen. Alle 366 Aufgaben im Board sind sichtbar, 35 davon MC. Keine Migration nötig.
- Tests: sechs Fälle in `lauf.test.ts`, zwei in der Übersicht (`Als Nächstes` und Enter mit und ohne Typen).
- Die fünf Bildschirmfotos aus #304 liegen jetzt unter `docs/pruefen/p4/`.

## Entscheidungen
- Fehlt einer Aufgabe der Typ (nicht in der Antwort), gilt sie als „ohne MC“.
- `knotenOhneAufgabe` (Entscheidung 8) ist unverändert. Ein Knoten, dem nur „ohne MC“ fehlt und der nur noch
  MC offen hat, steht dort nicht. Er fällt still aus dem Lauf.

## Offen
- Soll ein solcher Knoten (nur noch MC offen, es fehlt „ohne MC“) in der Liste „Hier fehlen noch Aufgaben“
  erscheinen? In Prod gibt es derzeit keinen. Das entscheidet Rasit.
