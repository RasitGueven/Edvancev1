# Retro 20.10.2026 – T3 · Stationen 01 und 02 der Tablet-Präsentation

## Gebaut
- `src/components/edvance/praesentation/`:
  - `Station1.tsx`: Kopfsatz bzw. Ersatzüberschrift (Größe nach Länge über Klassen), Leitsatz je `kopfFall`,
    „Mathematik · Klasse 10 · Im Blick: …“, Fußzeile.
  - `UeberblickKarten.tsx`: „Schon gelungen“ / „Gezielt üben“ aus `p.ueberblick` (Felder per `Intl.ListFormat`,
    sonst `s1.sicherEinzeln`/`uebungEinzeln` mit `count` bzw. `elternbericht:s1.blick.keinSicher`/`keineUebung`),
    Kreise und Kugel ab 800 px, darunter Karten ohne Bild. Beide Karten `data-tp-pflicht`.
  - `Station2.tsx`: Zahlen über `anzeigeZahlen`, Erklärtext, Profil mit Liste (`data-tp-liste`), Legende, Hinweis;
    höchstens ein Detail offen, die geöffnete Zeile wird nach dem Aufklappen in die Liste geholt (nur die Liste scrollt).
  - `Profilzeile.tsx`: Segmente sicher → Übungsbedarf → übersprungen, „x von y“, Zählung, Vorlesetext je Zählweise,
    Pfeil, Detail mit Spalten nur, wenn nicht leer. `Zaehlung.tsx`: Teile ≠ 0 je Zählweise.
  - `testStation.tsx` (nur Tests), `Station1.test.tsx` (17), `Station2.test.tsx` (21).
- `src/styles/praesentation/station1.css`, `station2.css`: Maße und Choreografie nach Dummy V7 (V6-Zeiten aus
  `rahmen.css`), Punktmuster „übersprungen“ als `radial-gradient`, kombiniert rosé, getrennt neutral.
- Fotos unter `docs/report/praesentation/abnahme/t3/` (01 und 02 aller Fälle, Dummy zum Vergleich).

## Entscheidungen
- Die Ansicht zählt nichts selbst: Zahlen, Zeilen und Zählung kommen aus `anzeigeZahlen`/`anteileZeile` (T1).
- Segmente höchstens 96 px breit, damit wenige Bereiche nicht wie ein voller Balken wirken.
- Zählung je Zeile bricht nur zwischen den Teilen um (Leerzeichen zwischen den Teilen, Punkt per `::after`).
- Zeiten der Station 01 als Variablen in `station1.css`, weil `rahmen.css` sie nicht führt.

## Gelernt
- `test.use({ reducedMotion: 'reduce' })` wirkt in Playwright 1.61 nicht; es braucht `contextOptions`. Ohne das
  messen die Ansichtstests mitten in der Bewegung, und Elemente mit Opacity 0 fallen still aus der Prüfung.
- `scrollIntoView` scrollt auch Vorfahren mit `overflow: hidden` (Station). Deshalb scrollt nur die Liste per
  `scrollBy`, gemessen nach dem Aufklappen.
- React setzt zwischen benachbarten `<span>` kein Leerzeichen: ohne eigenes Leerzeichen gibt es keinen Umbruch.

## Offen
- `docs/report/praesentation/offene-punkte-t3.md` (Ansichtstests ohne reduzierte Bewegung, Port, Zeiten 01,
  INV-4.12-Muster, Kopfsätze, Listenformat in den Karten).
