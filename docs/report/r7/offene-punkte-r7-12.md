# R7-12 · Offene Punkte

Stand 22.10.2026, Branch `feat/rasit-r7-12-lernweg-grenzen`.

## 1. Stufe 4 in der Bühne kürzt auch Linien und Kommt noch
Entscheidung 9 sagt „KUERZUNGEN[4] (6 je Insel, nichts zusammengefasst)“. Nach Entscheidung 2 baut
Stufe 4 aber auf Stufe 3 auf und bringt deren Grenzen mit: nicht geprüft 1 je Insel, Linien 4,
Kommt noch 4. So ist es gebaut. Die volle Karte zeigt deshalb in allen Fällen weniger als vorher:

| Fall | Linien vorher → nachher | Kommt noch vorher → nachher |
|---|---|---|
| abgestuft (Batu) | 4 → 3 | 5 → 4 |
| ilkay | 5 → 2 | 6 → 4 |
| vieleKanten | 5 → 2 | 6 → 4 |
| sehrViele | 3 → 3 | 5 → 4 |

Wenn die Bühne nur die Höhe kürzen soll: In `Station3.tsx` statt `KUERZUNGEN[stufe]` die Grenzen
`{ ...GRENZEN, eintraegeJeInsel, zusammenfassen }` der Stufe nehmen (eine Zeile).

## 2. Seite 2 läuft bei vielen Bereichen in einem Themenfeld über
Der Druck-Test `e2e-druck/elternbericht.spec.ts` ist für `sehrViele` rot: In der Profilzeile
Geometrie (24 geprüft, „3 sicher · 21 Übungsbedarf“) endet die Spur 8,8 pt **hinter** dem Beginn des
rechten Textes (Soll: 6 pt davor). Seite 2 war in diesem Paket tabu. Eine LSA wie Tolunays dürfte
dasselbe zeigen. Eigener Auftrag. Seite 3 der Fixture ist grün (kein `data-ueberlauf`, Fußnote da).

## 3. Texte
`docs/report/r7/r7-12-texte.md`, Fragen an Lena dort.

## 4. Was „+ n weitere“ zählt
Die Grenze gilt für Einträge und ↳ zusammen. Die Zeile „+ n weitere“ zählt nicht mit. Eine Insel
mit 12 Einträgen zeigt auf Stufe 0 also 8 Zeilen und darunter „+ 4 weitere …“. Linienenden bleiben
immer, auch über die Grenze.

## 5. Reduzierte Bewegung und die Höhe der Spur
`rahmen.css` setzt bei reduzierter Bewegung für alle Elemente `transition-duration: .01ms`. Damit
„animierte“ die Spur ihre Höhe, und `useLernwegFahrt` maß noch die alte (Linien durch Inseln, sobald
eine Insel höher als die Spur ist). Behoben mit `transition: none` an der Spur
(`station3-weg.css`). Die Ausnahme „Spur höher“ misst jetzt im selben Durchgang nach, bis die Höhe
steht.
