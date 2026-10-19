# Retro 19.10.2026 – R7-4 · Seite 3 (Pyramide) und Seite 4 (Kurve)

## Gebaut
- Seite 3: Kicker, Titel (`s3.titel` / ohne Sicheres `s3.titelOhneSicher`), Intro (`s3.intro` nur bei
  genau aktuell + weiterführend + grundlagen, sonst `s3.introKurz`), Zwischenzeile und Legende auf
  einer Grundlinie, Pyramide aus `bericht.pyramide` und Lesehilfe.
  - `Pyramide.tsx`: je Ebene ein Kasten, Breite als feste Klasse nach Position von unten
    (`eb-s3-ebene-p0` … `p3` = 507 / 451 / 395 / 339 pt). Kopf mit Ebene, Klassenangabe über
    `klassenAngabe()` (eine Stufe oder Spanne) und Zählung nur der von null verschiedenen Teile.
    Höchstens vier Themenfelder je Reihe, höchstens sechs Einträge je Gruppe, dann „+n weitere“.
    Jeder Eintrag mit Punkt und `aria-label` aus `s3.eintragAria`.
  - `Lesehilfe.tsx`: Zeile je Ebene mit Mini-Pyramide (SVG, Balken 16 / 12,2 / 8,4 / 4,6 von unten,
    eigener navy), Text mit Klassen bzw. den ersten zwei Themenfeldern (`Intl.ListFormat`,
    disjunction, Sprache aus i18n), dann „gilt nur für“ und Hinweis.
- Seite 4: Fazit aus `gruppiereFehlbilderNachFamilie` (höchstens zwei Elterntexte + `s4.fazit.coach`,
  Familienschlüssel nur als key), Titel nach Anzahl, Reihenfolge-Hinweis ab zwei, Schwerpunkte mit
  „Sicher: … Noch nicht sicher: …“ (bis drei Labels als Aufzählung, sonst „A, B, C und n weitere“),
  „Danach …“ unter dem letzten, ohne Schwerpunkt `s4.titelKeiner` + Baustein `fazit`/`keine`,
  Lernziel mit Zeilenumbrüchen, Fußnote.
  - `kurve.ts`: reine Pfadrechnung nach dem Maßblatt (Stücke, Auslauf, Spitze).
  - `Kurve.tsx`: SVG in Seitenkoordinaten, misst Titel-Grundlinien und Lernziel-Kasten nach dem Layout
    (`useLayoutEffect`, `document.fonts.ready`, `ResizeObserver`).
- Neuer Schlüssel `s3.lesen.ebene` („{{ebene}}:“). Tests: `kurve.test.ts`, `Seite3.test.tsx`,
  `Seite4.test.tsx` (38 Tests).

## Entscheidungen
- Gruppen der Pyramide als Grid mit `auto`-Spalten statt `flex: 1 1 auto`: Mit echten, langen Labels
  ließ flex auch kurze Namen umbrechen.
- Die Kurve misst `svg.parentElement` statt eines Refs am Eltern-`div`. Der Ref ist im Layout-Effekt
  des Kinds noch null; in der Vorschau verdeckt StrictMode das. Gefunden vom jsdom-Test.
- Zahlen im d-Attribut über `Intl.NumberFormat('en-US')` statt `Math.round(n * 100) / 100`: INV-4.11
  verbietet `* 100` im Bogen (gegen Prozentrechnung) — die Regel bleibt, die Rundung geht anders.
- „Danach …“ in der Reserve des letzten Schwerpunkts mit kleinerem Abstand darunter: Mit fünfzeiligem
  Fazit und Lernziel lief Seite 4 sonst um 8 pt über.
- Seite 4 verdichtet sich nur bei Überlauf (`data-dicht`, gemessen nach dem Layout): Die Zweitprüfung
  zeigte, dass echte Elterntexte (128–208 Zeichen) zu sechs bis sieben Zeilen Fazit führen, das
  Muster hat Platz für fünf. Im Normalfall bleiben die Maße des Musters.

## Ergebnis
- Typecheck, Lint, Vitest grün; `inv4-elternbericht.test.ts` grün. Druck-Tests (Port 5184) für alle
  13 Fälle grün, PDFs unter `docs/report/r7/abnahme/r7-4/`.
- Ilkay: Grundlinien auf Seite 3 und 4 höchstens 0,8 pt neben dem Muster (bei verschobenem Fluss
  relativ gemessen); Knoten im Druck auf 0,000 pt an den Titeln.

## Offen
- `docs/report/r7/offene-punkte-r7-4.md`: Fixture mit Fazit fehlt (Foundation), Verdichtung hat Grenzen,
  `fazit.keine.a` sagt noch „tragen“, Lernziel ohne Schwerpunkt eingerückt.
