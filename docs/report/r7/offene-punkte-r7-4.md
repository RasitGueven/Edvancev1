# R7-4 · Offene Punkte und Abweichungen

Stand 19.10.2026, Branch `feat/rasit-report-r7-seiten34`. Seite 3 (Einordnung als Pyramide) und
Seite 4 (Lernplan als Kurve).

## Abnahme-Material

- PDFs aller Fälle: `docs/report/r7/abnahme/r7-4/<fall>.pdf` (Seiten 3 und 4 sind die Seiten dieses
  Pakets; Seiten 2 und 5 stehen leer, bis R7-3 gemergt ist). `ohneKatalog` hat kein PDF (Hinweis
  statt Bogen, Entscheidung 3).
- Vergleich mit dem Muster: `ilkay.pdf` Seiten 3 und 4 neben `Edvance_Elternreport_E7.pdf` Seiten 3
  und 4.
- Druck-Tests: `EB_PORT=5184 EB_AUSGABE=docs/report/r7/abnahme/r7-4 npx playwright test -c
  playwright.elternbericht.config.ts` — alle 13 Fälle grün.

## Abweichungen vom Muster

| Stelle | Muster E7 | R7-4 | Grund |
|---|---|---|---|
| Pyramide Ilkay | drei Ebenen | zwei (Weiterführende Themen · Klasse 7/8, Grundlagen · Klasse 5/6) | Daten, Bauauftrag Entscheidung 6 |
| Klassenangabe | „darauf aufbauend“, „frühere Klassenstufen“ | „Klasse 7/8“, „Klasse 5/6“, über mehrere Stufen „Klasse 7–10“ | Entscheidung 6 |
| Intro Seite 3 | zwei Zeilen | bei Ilkay `s3.introKurz` (eine Zeile), alles darunter 13,5 pt höher | nur zwei Ebenen |
| Zwischenzeile / Legende | Grundlinien 234,9 / 237,0 | eine gemeinsame Grundlinie | Auftrag R7-4 („auf einer Grundlinie“) |
| Gruppen einer Ebene | `flex: 1 1 auto` | Grid mit `auto`-Spalten | Mit flex schrumpft jede Gruppe anteilig und auch kurze Namen brechen um („Prozentwert / berechnen“). Im Grid wachsen die Spalten gleichmäßig bis zu ihrer Inhaltsbreite; zuerst bricht die Gruppe mit den langen Namen. Bei genug Platz wie flex. |
| Abstand zwischen zwei Gruppenreihen | – (Muster hat nie mehr als vier Felder) | 7,5 pt, wie Kopfzeile → Gruppen | nicht im Maßblatt |
| Lesehilfe | „was in Klasse 10 gerade im Unterricht dran ist“, Beispiele als Themen | Texte aus Anhang A (`s3.lesen.*`), Beispiele = erste zwei Themenfelder der Ebene | Entscheidungen 8, 11 |
| Ebenenname in der Lesehilfe | „Aktueller Unterrichtsstoff:“ (Doppelpunkt fest) | neuer Schlüssel `s3.lesen.ebene` = „{{ebene}}:“ | i18n, kein Satzzeichen im Code |
| Fazit Ilkay | Kasten mit vier Zeilen | entfällt | Die Fixture `ilkay` hat keine Fehlbilder mit abgenommenem Elterntext. Titel und Rest rücken nach oben (Titel-Grundlinie 119,8 statt 296,1). |
| Schwerpunkte Ilkay | Flächen-/Raummaße, Prozent, Brüche, Terme | Geometrie, Brüche & Dezimalzahlen, Größen, Prozent & Dreisatz | Entscheidung 7, Abnahme Punkt 5 |
| Texte der Schwerpunkte | Fließtext je Thema | „Sicher: …. Noch nicht sicher: ….“ | Entscheidung 7, Anhang A |
| „Danach …“ | – | unter dem letzten Schwerpunkt, in dessen Reserve (4 pt unter dem Text, darunter 8 statt 19,5 pt) | sonst läuft Seite 4 im ungünstigsten Fall über, siehe unten |
| Lernziel-Kicker / -Text | Kasten + 19,2 / + 39,8 | + 18,7 / + 39,0 | Rundung der Schriftmetrik, innerhalb 1 pt |

Gemessen in Chromium (Bildschirm und Druckmedium, Fall `ilkay`): Seite 3 Kicker, Titel und Intro auf
0,1 pt; Ebenenkopf, Gruppennamen und Einträge relativ zur Ebene höchstens 0,5 pt neben dem Muster;
Lesehilfe (Abstände 34 / 5,5 / 9 / 13) auf 0,4 pt. Seite 4 Abstände Titel → Hinweis → erster
Schwerpunkt → Text → nächster Titel (79,6 statt 79,5) auf 0,6 pt. Knotenmitten liegen im Bildschirm
und im Druckmedium auf 0,000 pt bei Titel-Grundlinie − 3,4; die Spitze endet bei x 84,49.

## Kurve: wie gemessen wird

- `Kurve.tsx` rendert immer ein SVG (absolut über `.eb-s4`, viewBox in Seitenkoordinaten
  `44 80 507 720`, also 1 Einheit = 1 pt wie das Maßblatt) und misst dessen Elternelement: Grundlinie
  jedes Titels über einen leeren `inline-block` (`.eb-s4-grund`), Oberkante des Lernziel-Kastens.
  Gemessen wird im `useLayoutEffect`, nach `document.fonts.ready` und bei jeder Größenänderung
  (`ResizeObserver`). Der Bogen skaliert nie, deshalb gelten die Lagen im Druck genauso.
- Ein Ref am Eltern-`div` funktioniert hier nicht: React setzt ihn erst nach dem Layout-Effekt des
  Kinds. In der Vorschau fiel das nicht auf (StrictMode führt Effekte doppelt aus), im
  Produktions-Build wäre die Kurve leer geblieben. Der jsdom-Test „je Schwerpunkt ein Knoten“ rendert
  ohne StrictMode und fängt das ab.
- Die Rechnung (Knoten-y, Lernziel-y oder null → d-Attribute) ist rein: `kurve.ts`, Test
  `kurve.test.ts` (1–4 Knoten, mit und ohne Lernziel, Richtung und Lage der Spitze gegen das Muster).

## Offene Punkte

1. **Fazit im Druck nicht abgedeckt.** Keine Fixture hat Fehlbilder mit Elterntext, die PDFs zeigen
   den Fazit-Kasten deshalb nie. Ein Fall `mitFazit` mit zwei langen Familien (z. B. `figuren`,
   `geraden_schaubilder`) gehört in die Fixtures (`src/lib/**`, also Foundation), damit der
   Druck-Test ihn sieht.
2. **Verdichtung von Seite 4 statt Überlauf.** Die echten Elterntexte haben 128–208 Zeichen; zwei
   davon mit `s4.fazit.coach` ergeben sechs bis sieben Zeilen, das Feld des Musters hat Platz für
   fünf (Zweitprüfung: bei sechs Zeilen Fußnote bei 812,8 pt, abgeschnitten). Seite 4 prüft deshalb
   nach dem Layout (und nach dem Laden der Schriften), ob `.eb-inhalt` überläuft, und setzt dann
   `data-dicht`: kleinere Abstände (Titel 20, Liste 22, Schwerpunkt mindestens 56 / unten 13,
   zwischen Schwerpunkten 10, Lernziel 12 pt), Fazit ohne Mindesthöhe. Im Normalfall bleiben die
   Maße des Musters. Lokal geprüft (vorübergehend geänderte Vorschau): sieben Zeilen Fazit + vier
   Schwerpunkte + „Danach …“ + sechszeiliges Lernziel → Fußnote bei 791,4 pt, Knoten auf 0,000 pt.
   Noch längere Inhalte würden weiter abgeschnitten; ob dann `s4.fazit.coach` entfällt oder nur ein
   Elterntext steht, entscheiden die Gründer.
3. **`fazit.keine.a` sagt noch „tragen“** („die Grundlagen darunter tragen“), sichtbar im Fall
   `allesSicher` auf Seite 4. Bekannt, wartet auf Lenas Abnahme der W5-d-Entwürfe (Abnahme 8).
4. **Ohne Schwerpunkt** steht das Lernziel weiter bei x 93 (eingerückt, ohne Kurve daneben). Falls
   es dann über die volle Breite gehen soll: eine Regel in `seite4.css`.
5. **Eintrag mit sehr langem Label** in einer Ebene mit vier Gruppen bricht in drei Zeilen um; die
   Pyramide wächst dann im Fluss. Mit den Fixtures endet Seite 3 spätestens bei 703,6 pt
   (`klasse10neu`, drei Ebenen), knapp 100 pt vor der Grenze; Seite 4 bei 621,2 pt.
6. **Kicker der Lesehilfe** sitzt per `top: 2,9pt` auf der Grundlinie des Musters (600,0); bei einer
   ersten Lesehilfe-Zeile über zwei Zeilen bleibt er an der ersten Zeile ausgerichtet.

## Zweitprüfung

Frische Instanz, Schwerpunkt Kurve im Druck. Gemessen in zehn Fällen mit Kurve, je normal, mit
um 1,5 s verzögerten Schriften und im Druckmedium: Knotenmitten auf Titel-Grundlinie − 3,4 (0 pt
Abweichung), Auslauf endet bei Lernziel-Oberkante + 16,3, PDFs zeigen Knoten, Kurve und Spitze.
Pfadrechnung entspricht dem Maßblatt. Blockierend war nur der Überlauf mit langen Elterntexten
(Punkt 2, umgesetzt). Nicht umgesetzt (kann): zweite Messung per requestAnimationFrame nach
`fonts.ready`; die Messwerte waren in allen Modi gleich.
