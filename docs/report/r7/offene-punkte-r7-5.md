# R7-5 · Offene Punkte und Messwerte

Stand 20.10.2026, Branch `feat/rasit-report-r7-haerten`. Grenzfälle für den Druck und vier Regeln für
Inhalt, der nicht passt (Gründer-Entscheidungen 1–4 im Paket R7-5).

## Abnahme-Material

- PDFs aller Fälle: `docs/report/r7/abnahme/r7-5/<fall>.pdf`. Neu: `mitFazit`, `fazitLang`,
  `langerName`, `zuLangerName`, `weitereBereiche`, `vieleAnliegen`, `keinSchwerpunktMitZiel`.
  `ohneKatalog` hat weiter kein PDF (Hinweis statt Bogen).
- Druck-Tests: `EB_PORT=5186 EB_AUSGABE=docs/report/r7/abnahme/r7-5 npx playwright test -c
  playwright.elternbericht.config.ts` — alle 20 Fälle grün.

## Geschlossen

| Punkt | Wie |
|---|---|
| r7-2 Punkt 6 (Stresstest Seite 1) | `vieleAnliegen`, `langerName`, `zuLangerName` |
| r7-3 Punkt 5 (Grenze Seite 2) | `weitereBereiche` (neun Zeilen), `langerName` / `zuLangerName` |
| r7-4 Punkt 1 (Fazit im Druck) | `mitFazit`, `fazitLang` |
| r7-4 Punkt 2 (Verdichtung reicht nicht) | Stufen in `Seite4.tsx` (`useStufe`), Entscheidung 2 |
| r7-4 Punkt 4 (Lernziel ohne Schwerpunkt) | `.eb-s4-lernziel-voll` in `seite4.css`, Entscheidung 3 |

## Regeln

- **Seite 4, Stufen (Entscheidung 2):** `data-stufe` auf `.eb-s4`. 1 = verdichtet (`data-dicht`, wie
  bisher), 2 = dazu ohne `s4.fazit.coach`, 3 = dazu nur der erste Elterntext. Höchste Stufe: ohne
  Fazit 1, mit einem Elterntext 2, mit zweien 3. Geprüft nach dem Layout und nach
  `document.fonts.ready`, eine Stufe je Durchgang; eine erreichte Stufe bleibt. Elterntexte werden
  nie gekürzt, nur weggelassen.
- **Lernziel ohne Schwerpunkt (Entscheidung 3):** Klasse `eb-s4-lernziel-voll`, `margin-left: 0` —
  Kasten bei x 44, Breite 507 pt (gemessen in `keinSchwerpunktMitZiel`).
- **Rufname (Entscheidung 4):** In `Bogen.tsx` nach `trim`, gezählt in Zeichen (Codepoints). Ab 25
  sind `name` und `wessen` null; alle Seiten, Fuß und Anliegen nehmen die Fassung ohne Namen.

## Gemessen (Chromium, Bildschirm und Druckmedium gleich)

Unterkante des Inhalts je Seite in pt (Grenze 800), größtes `bottom` aller Elemente in `.eb-inhalt`
ohne das SVG der Kurve. Kein Fall läuft über (`scrollHeight − clientHeight` = 0 auf allen Seiten).

| Fall | S1 | S2 | S3 | S4 | S5 | knappste Seite, Rest |
|---|---|---|---|---|---|---|
| `mitFazit` | 703,9 | 773,7 | 662,7 | 749,3 (Stufe 1) | 767,1 | S2, 26,3 pt |
| `fazitLang` | 703,9 | 749,4 | 557,2 | 775,3 (Stufe 1) | 767,1 | S4, 24,7 pt |
| `langerName` | 760,9 | 783,7 | 662,7 | 621,2 | 799,1 | **S5, 0,9 pt** |
| `zuLangerName` | 728,9 | 783,7 | 662,7 | 621,2 | 767,1 | S2, 16,3 pt |
| `weitereBereiche` | 703,9 | 776,6 | 691,8 | 621,2 | 767,1 | S2, 23,4 pt |
| `vieleAnliegen` | 737,9 | 773,7 | 682,7 | 621,2 | 767,1 | S2, 26,3 pt |
| `keinSchwerpunktMitZiel` | 703,9 | 736,8 | 662,7 | 262,7 | 767,1 | S5, 32,9 pt |

- `fazitLang`: Fazit sechs Zeilen (zwei Elterntexte mit 221 und 208 Zeichen + Coach-Satz), vier
  Schwerpunkte + „Danach …“, Lernziel sieben Zeilen. **Es greift nur Stufe 1** (Verdichtung); der
  Coach-Satz bleibt. Stufe 2 und 3 werden mit den heutigen Texten im Druck nicht erreicht und sind
  in Vitest mit gemessener Höhe gemockt geprüft.
- `mitFazit` braucht schon Stufe 1 (wie in r7-4 Punkt 2 vorhergesagt).

## STOPP: Entscheidung 4 reicht nicht für jeden Namen mit 24 Zeichen

Gefunden von der Zweitprüfung, nachgemessen (Fall `langerName`, Name vorübergehend getauscht, Fixture
unverändert eingecheckt):

| Rufname (Zeichen) | S2 Titel | S2 Unterkante | Überlauf `.eb-inhalt` |
|---|---|---|---|
| Anna-Katharina Henriette (24) | zweizeilig | 783,7 | 0 |
| Mohammed-Ali Wilhelm (20) | zweizeilig | 783,7 | 0 |
| Mohammed-Mustafa Wilhelm (24) | **dreizeilig** | **813,7** | **18 px = 13,7 pt** |
| Mohammed Mustafa Wilhelm (24) | **dreizeilig** | **813,7** | **18 px** |
| Muhammed Mustafa Wilhelm (24) | **dreizeilig** | **813,7** | **18 px** |

Der Titel „{{wessen}} Lernstand in den untersuchten Bereichen.“ auf Seite 2 bricht bei breiten
Buchstaben schon unter 25 Zeichen dreizeilig um; dann wird der Kasten „Was die Grafik zeigt“ am
Inhaltskasten abgeschnitten. Die Grenze zählt Zeichen, nicht Breite. Nicht selbst gelöst (keine neue
Regel erfinden, keine Schriftgrößen ändern). Mögliche Wege für die Gründer: kleinere Grenze (etwa 20),
Grenze nach gemessener Breite des Seite-2-Titels, oder Seite 2 nimmt bei dreizeiligem Titel die
Fassung ohne Namen. Mit neun Profilzeilen wird es knapper (`weitereBereiche` mit kurzem Namen: 23,4 pt).

## Offene Punkte

1. **Seite 5 mit 24 Zeichen Rufnamen: 0,9 pt Rest** (gilt schon ab etwa 20 Zeichen, z. B.
   „Mohammed-Ali Wilhelm“). Der Titel „Welcher Rhythmus zu … passt, …“
   wird zweizeilig, der Kontakt-Kasten endet bei 799,1. Mit „Maximilian Wolfgang Mohr“ (24, breite
   Buchstaben) gleich. Ein Name aus einem einzigen Wort ohne Bindestrich mit 24 breiten Buchstaben
   (Kunstwort „WWWW…“, „Mmmm…“) bricht nicht um und läuft über: Seite 2 um 18 pt (813,7), Seite 5 um
   28 pt (821,0) — vorübergehend gemessen, nicht als Fall eingetragen. Echte Namen dieser Art sind
   unwahrscheinlich; sonst müsste die Grenze nach Breite statt nach Zeichen gehen (Gründer).
2. **Mehrere Anliegen bei einem Rückbezug** gibt es mit den Werten des Intake-Formulars heute nicht:
   Alle sechs Werte haben eine Zeile in `report_anlass_zuordnung` und damit einen Rückbezug. Die
   Fälle `langerName`, `zuLangerName` und `vieleAnliegen` nutzen dafür synthetische Anliegen
   („Hausaufgaben“, „Motivation“) außerhalb der Zuordnung.
3. **„Weitere Bereiche“** ist in Prod heute leer: Jeder Skill hat ein Themenfeld. `weitereBereiche`
   nutzt einen synthetischen Skill (`daten_diagramme`).
4. **Fußnote ohne Schwerpunkt:** Entscheidung 3 rückt nur den Lernziel-Kasten nach links; die Fußnote
   „Stand …“ darunter steht weiter bei x 93. Bitte im PDF `keinSchwerpunktMitZiel` ansehen.
5. `vieleAnliegen` mit vier Anliegen nennt sie im Satz „Sie machen sich Sorgen um Ilkays
   Textverständnis, Rechenwege, fehlende Grundlagen und Hausaufgaben.“ — sprachlich holprig bei
   Mischformen, Text `s1.anliegen.genannt` (Lena).

## Zweitprüfung

Frische Instanz, Schwerpunkt Grenzfälle im Druck, alle neuen Fälle Seite für Seite in Bildschirm und
Druckmedium (Werte wie oben auf 0,1 pt), dazu mit um 1,5 s verzögerten Schriften (Werte und Stufen
gleich). Fachlich bestätigt: `fazitLang` nur Stufe 1, beide Elterntexte wörtlich, nichts abgeschnitten
(ohne Verdichtung liefe Seite 4 um 79 px über); `zuLangerName` ohne jeden Namensteil auf allen Seiten;
neun Profilzeilen mit 30 pt; Lernziel ohne Schwerpunkt bei x 44, 507 pt breit; `vieleAnliegen` ohne Weg.

- Blockierend: die 24-Zeichen-Grenze (oben, STOPP).
- Umgesetzt: Stufen eskalieren erst nach `document.fonts.ready`, solange Schriften laden (vorher
  stand Stufe 1 schon beim ersten Rendern mit der Ersatzschrift fest und blieb). Kommentare in
  `seite4.css` (`useStufe`) und `grenzfaelle.ts` (Stufe 2/3 nur im Vitest) richtiggestellt.
- Nicht umgesetzt (kann): Warnhinweis, wenn Stufe 3 noch überläuft (heute nur Druck-Test fängt das);
  Stufe bei Datenwechsel ohne Remount nicht zurückgesetzt (Bogen wird je Sitzung neu gerendert);
  Namen in NFD zählen länger (`normalize('NFC')`).
