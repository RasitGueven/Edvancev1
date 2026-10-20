# Retro 20.10.2026 – T4 · Station 03 und 04 der Tablet-Präsentation

## Gebaut
- `src/components/edvance/praesentation/`:
  - `Station3.tsx` + `Pyramide.tsx`: Ebenen aus `p.pyramide` (oben → unten), Breite über feste Klassen je
    Position von unten (100/81/62/43 %), Lücke 4/2/1 px nach Segmentzahl, Klassenangabe als Pille, Zählung je
    Zählweise (nur Teile ≠ 0), Vorlesetext `s3.ebeneAria…` an der Spur, Lesehilfe mit `hinweisEineEbene`.
  - `Station4.tsx` + `Kurve.tsx` (Pfad mit `data-tp-kurve`, Startpunkt, Pfeil, Punkte als `role="tab"` mit
    Pfeiltasten und Umlauf), `Foerderfokus.tsx` (Tabpanel, Pille, Titel, zwei Kästen mit je bis zu drei
    Bereichen und „+n weitere“), `Empfehlung.tsx` (`Trans` mit fettem Paket, Basic-Satz), Danach-Zeile, Hinweis,
    Fall ohne Schwerpunkt (`titelKeiner`, `ansatzKeiner`, Empfehlung bleibt).
  - `useKlassen.ts` (Klassenangabe wie im Druckbogen), `testStation34.tsx` (Testhilfe).
- `src/styles/praesentation/station3.css`, `station4.css`, `station4-kurve.css` (per `@import` aus
  `station4.css`, damit `index.css` von T2 unberührt bleibt und jede Datei ≤ 400 Zeilen).
- Zwei neue Texte: `praesentation:s3.pyramideAria`, `s4.punkteAria`.
- Tests: `Station3.test.tsx` (11), `Station4.test.tsx` (20); Fotos der Stationen 03/04 unter
  `docs/report/praesentation/abnahme/t4/`.

## Entscheidungen
- Keine Datei von T3 importiert oder angelegt; Punktmuster und Zählung deshalb vorerst doppelt
  (offene-punkte-t4.md 2–3).
- Feld- und Ebenenschlüssel in i18n-Vorlagen über eine lokale Variable (`feld.${feldKey}`): Die Regel
  INV-4.12 trifft `${x.feld}` auch in einer erlaubten Vorlage.
- Beschriftung „links“ nach oben versetzt, damit sie bei schmaler Kurve frei von der Linie bleibt.

## Gelernt
- `test.use({ reducedMotion: 'reduce' })` wirkt in Playwright nicht; richtig ist
  `contextOptions: { reducedMotion: 'reduce' }`. Die T2-Ansichtstests waren für verzögert einblendende Teile
  leer grün. Ein Blick auf die Fotos hätte es sofort gezeigt – Fotos immer ansehen, nicht nur zählen.
- Die Überlappungsprüfung misst nur „Punkt in Box“. Den Abstand Kurve–Beschriftung zusätzlich gemessen.

## Offen
- `docs/report/praesentation/offene-punkte-t4.md` (Spec-Korrektur, doppelte Bausteine, Abnahmepunkte).
