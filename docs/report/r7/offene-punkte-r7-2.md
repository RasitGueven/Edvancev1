# R7-2 · Offene Punkte und Abweichungen

Stand 19.10.2026, Branch `feat/rasit-report-r7-bogen`. Bogen, Rahmen, Seite 1, Vorschau und
Druck-Tests; Seiten 2–5 stehen als leere Hüllen für R7-3 und R7-4.

## Abnahme-Material

- PDFs aller Fälle: `docs/report/r7/abnahme/r7-2/<fall>.pdf` (fünf Seiten, Seiten 2–5 leer).
  `ohneKatalog` hat kein PDF: Dort steht statt des Bogens der Hinweis (Entscheidung 3).
- Bildschirmfoto der Ansicht mit Umschalter: `docs/report/r7/abnahme/r7-2/ansicht-r7.png`
  (Fall `testlauf` in der Admin-Hülle, gemockte Wrapper, Daten aus den Fixtures).
- Vorschau: `npx vite`, dann `/vorschau/elternbericht.html?fall=ilkay` (ohne `?fall` eine Liste).
- Druck-Tests: `EB_PORT=5182 EB_AUSGABE=docs/report/r7/abnahme/r7-2 npx playwright test -c
  playwright.elternbericht.config.ts`.

## Abweichungen vom Muster (Seite 1 und Rahmen)

| Stelle | Muster E7 | R7-2 | Grund |
|---|---|---|---|
| Überschrift | drei Größen (27,7 / 25,7 / 24,4) | eine Größe 26 pt, Zeilenabstand 32, höchstens drei Zeilen | Entscheidung 7 des Pakets |
| Überschrift (Text) | „Ilkay zeigt sichere Ansätze. …“ | „Was wir bei Ilkay gesehen haben“ | Kopfsätze noch nicht abgenommen (Lena) |
| Kopfdaten | „10, Gymnasium“ | „10, Gesamtschule“ | Wert aus `students.school_type` (R7-1) |
| Zählung | 25 von 41 | 27 von 130 | Nenner aus Entscheidung 4, offen für die Abnahme |
| Erster Ansatz | Flächen- und Raummaße | Geometrie | Titel = Themenfeld (Bauauftrag, Entscheidung 11) |
| Anliegen-Kasten | Rückbezug zwei Zeilen | Ilkays abgenommener Rückbezug hat drei Zeilen, der Kasten wird 10 pt höher, der Weg rückt mit | Kästen wachsen im Fluss |
| Einträge der Karten | einzeilig | ein langer Name („Gleichungen mit negativem Koeffizienten“) bricht um; die nächste Zeile rückt nach | Labels aus `skills.label` |
| Seitenschatten am Bildschirm | – | `--shadow-md` | Ein `shadow-card` gibt es im Repo nicht |
| PDF-Seitengröße | 595,28 × 841,89 | 594,96 × 841,92 (A4 in Chromium) | Die Seite ist 0,3 pt breiter als das Blatt; abgeschnitten wird nur Papierfläche rechts außen |

Gemessen in Chromium (Bildschirm und Druckmedium, Fall `ilkay`): alle Grundlinien von Seite 1 liegen
höchstens 0,4 pt neben dem Muster (bei der einzeiligen Ersatzüberschrift um zwei Zeilen = 64 pt
nach oben verschoben). Kopf- und Fußlinie, Chip und Navigationspunkte prüft der Druck-Test (±1 pt).

## Hinweise für R7-3 und R7-4

- Props jeder Seite: `SeitenProps` in `src/components/edvance/elternbericht/seitenProps.ts`.
  Schraffur für Seite 2: `fill="url(#eb-schraffur)"` (`SCHRAFFUR_ID`), Linienfarbe über CSS.
- Grundlinien im Fluss: Bei Zeilenhöhe L und Größe f liegt die Grundlinie L/2 + 0,36·f unter der
  Zeilenoberkante. Chromium rundet Ascent/Descent auf ganze px; deshalb vorher nachmessen
  (Unterkante eines leeren `inline-block` vor dem Text = Grundlinie) und mit
  `position: relative; top` korrigieren. `.eb-kicker` trägt schon `top: 0.5pt`.
- Text im SVG: Schriftgrößen in px = pt (1 Einheit = 1 pt bei viewBox in Seitenkoordinaten).
- Der Druck-Test prüft je Seite nur Rahmen und Überlauf; Inhaltsmaße testen die Pakete selbst.

## Offene Punkte

1. **Kopfsätze** (Lena, `docs/report/r7/kopf-texte.md`): Bis zur Abnahme steht die
   Ersatzüberschrift. Seite 1 ist für drei Zeilen Überschrift ausgelegt; mehr schneidet die
   Zeilenbegrenzung ab. Bei der Abnahme die längste Fassung mit einem langen Namen ansehen.
2. **Ansicht unter 800 px:** Der ganze Inhalt der R7-Ansicht scrollt seitlich (auch Kopf und
   Ausblick, sie bleiben aber in der Breite des Fensters). Falls störend: nur den Bogen in einen
   eigenen Scroll-Wrapper legen.
3. **Druck aus der App in Chrome von Hand** (Abnahme Punkt 2) steht noch aus. Automatisch
   geprüft: Druck der Vorschau (alle Fälle) und einmal der Ansicht in der Admin-Hülle über einen
   Harness mit gemockten Wrappern (fünf Seiten, randlos, ohne Leiste, Banner und Ausblick).
4. **Druck-Tests in CI:** laufen nur lokal (wie `e2e/`), weil sie Google Fonts laden.
5. **Browser für den Eltern-Druck:** Benannte Seiten (`page: eb`) sind in Chromium geprüft. Ältere
   Safari-/Firefox-Fassungen nehmen sonst die globale `@page` aus `print.css` (16/14 mm Rand), und
   jede Seite liefe über. Für den Druck Chrome oder Edge verwenden.
6. **Stresstest Seite 1:** `.eb-inhalt` schneidet Überlauf ab; der Druck-Test fängt ihn nur für die
   vorhandenen Fixtures. Seite 1 hat bei `ilkay` rund 40 pt Reserve. Ein Fall mit sehr langem Namen,
   vielen Anlässen und drei langen Rückbezügen fehlt noch (Fixture liegt in `src/lib/**`, also
   Foundation; deshalb nicht in R7-2).
7. **0,03 pt** weißer Streifen unten im PDF (Blatt 841,92 pt, Seite 841,89 pt). Unsichtbar.

## Zweitprüfung

Frische Instanz, Schwerpunkt Druck: nicht blockierend, abnahmefähig. Umgesetzt: `Intl.ListFormat`
mit `i18n.language` statt fest `'de'`; Schrift-Check im Druck-Test über die geladenen FontFaces
(`document.fonts.check` gäbe auch ohne Schrift `true`); INV-4.11 erkennt Farbnamen in
JSX-Attributen und verbietet `style={{…}}`. Gemessen von der Zweitprüfung: fünf Seiten auch mit
nachgebauter AppShell bei 500/900/1400 px Fensterhöhe; R6-Druck unberührt (Diff gelesen).
