# Retro 20.10.2026 – T5 · Aufräumen nach T3/T4 der Tablet-Präsentation

## Gebaut
- `Zaehlung.tsx` für Station 02 und 03: Prop `className` (Größe der Station) und `farbig` (03). Die lokale
  Zählung in `Pyramide.tsx` entfällt. Trenner „·“ und Farben der Teile in `rahmen.css` (`.tp-zaehlung`).
- Ein Punktmuster `.tp-muster-ueber` in `rahmen.css`, liest `--tp-ueber-punkt/-grund/-rand` (Standard
  `--color-tp-ueber-*`) sowie `--tp-muster-punkt/-weich/-raster` (Standard 1.15/1.6/5 px). „Getrennt“ setzt die
  neutralen Werte an `.tp-s2-getrennt` bzw. `.tp-s3-getrennt`, die Legende in 02 nur das kleine Raster.
- `--tp-s2-punkt/-grund/-rand` entfallen; `station2-zahlen.css` liest den Rand jetzt über `--tp-ueber-rand`.
- `Zaehlung.test.tsx` (6 Tests). Code ohne Tests netto −3 Zeilen.

## Entscheidungen
- `tp-s2-segment-ueber` und `tp-s3-seg-ueber` bleiben im Markup (ohne CSS) als Haken für die unveränderten
  Station-Tests; das Muster kommt nur noch über `.tp-muster-ueber`.
- Damit das Muster nicht vom Grundton der Segmente überdeckt wird, trägt in 03 nur noch `.tp-s3-seg-sicher` das
  Grün (vorher `.tp-s3-seg` für alle).
- Zwei Dateien außerhalb der Liste mit je einer Zeile: `Station2.tsx` (Legende bekommt `tp-muster-ueber`),
  `station2-zahlen.css` (Rand über `--tp-ueber-rand`). Ohne sie bliebe das Muster doppelt bzw. eine Variable verwaist.
- In 03 ist die Zählung jetzt Fließtext wie in 02 statt Flex mit 12 px Lücke, damit der Trenner gleich aussieht.

## Gelernt
- Pixelvergleich gegen ältere Abnahmefotos taugt nur bedingt: `abnahme/t3` stammt aus einem älteren Stand
  (laeuftNoch 02 weicht schon auf unverändertem dev ab). Verlässlich ist ein Referenzlauf auf origin/dev im
  zweiten Worktree, gleiche Basis, gleicher Port.
- Die Leiste (Eddie mit Lichtschein) und die Stationsanzeige im Kopf wackeln zwischen Läufen um einzelne Pixel;
  beim Vergleich Bereich x < 160 bzw. den Kopf getrennt betrachten.
- dev hatte während der Arbeit #283 bekommen (neue Grenzfälle): 236 statt 164 Ansichtstests.

## Offen
- Nichts Neues. Abnahmepunkte stehen weiter in `offene-punkte-t3.md` und `offene-punkte-t4.md`.
