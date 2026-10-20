# R7-9 · Offene Punkte, Abweichungen und Messwerte

Stand 20.10.2026, Branch `feat/rasit-report-r7-lernweg`. Der Lernweg ersetzt die Pyramide auf Seite 3
des Berichts und in Station 03 der Präsentation. Eine Rechnung (`lernweg.ts`), zwei Darstellungen.

## Entscheidungen während des Pakets (Rasit, 20.10.2026)

1. **Eine Zeile in `Bogen.tsx`** (bewusste Ausnahme von „Nicht anfassen“): `baueElternbericht` bekommt
   `lernweg: { erzaehlung: data.erzaehlung, datum: data.analysedAt }`. Ohne sie käme der Lernweg nicht zum
   Druck, weil der Bogen nur Kompetenzen, Katalog und Klasse weitergab. `bauePraesentation` gibt dieselbe
   Eingabe mit. Ein Test prüft, dass `bericht.lernweg` und `PraesentationDaten.lernweg` für abgestuft
   gleich sind.
   - Das Datum ist `data.analysedAt`, dasselbe wie im Kopf von Seite 1 (Europe/Berlin). Ein Test prüft
     „Oktober“ auf Seite 1 und auf dem Schild von Seite 3.
   - Die Abhängigkeiten des `useMemo` in `Bogen.tsx` nennen `data.erzaehlung` und `data.analysedAt`
     nicht, weil die Zeile darunter nicht angefasst werden sollte. In der Praxis wechselt `data` immer als
     Ganzes, und `kompetenzen` (aus derselben Erzählung) steht drin. Lint meldet nichts.

## Abweichungen vom Bauauftrag (technisch nötig)

- **Kein `color-mix` im Druck:** INV-4.11 verbietet `color-mix(` in `src/styles/elternbericht/**`.
  Die Tönung der Zonen (Navy) und „gebröckelt“ (Rosé) sind deshalb Pseudo-Elemente in der Token-Farbe mit
  geringer Deckkraft. Das sieht gleich aus, braucht keine neue Farbe, und die Invariante bleibt unverändert.
  In der Präsentation erlaubt INV-4.12 `color-mix` mit transparent; dort steht es so wie im Auftrag.
- **Verlauf in Kommt noch (Präsentation)** wie in Entscheidung 21. CLAUDE.md §11 („Verläufe nur für die
  Kugeln, den Lichtschein im Intro und das Punktmuster“) sollte um diesen Verlauf ergänzt werden. Die
  Wolken sind ohne Verlauf gebaut (weiße Fläche, Unschärfe).
- **Neue Datei `src/lib/supabase/lsaReportPlan.ts`** (Schulweg, Plan, Heimat-Themen) neben
  `lsaReportErzaehlung.ts`: Beides in einer Datei wären über 400 Zeilen. Die Rechnung dazu steht rein in
  `src/lib/report/elternbericht/plan.ts`.
- **`LwUnter.basen` ist eine Liste von Kennungen** statt einer Zahl. Antippen soll beide Basen eines ↳
  hervorheben; die Unterzeile nutzt die Länge.
- **Kernlehrplan:** `themen.klasse` ist die erste Klasse der Stufe (für 9/10 überall 9). Ein Kind der 10
  ohne passendes Thema sieht deshalb ab dem Anfang die Themen von 9 und 10 („Kommt noch“ bei Ilkay: Reelle
  Zahlen, Potenzen …). Abhilfe bräuchte eine Klasse je Thema in `themen`.
- **Plan-Titel** kommen aus `schul_themenplan.uv_titel` und sind länger als im Entwurf („Der Satz des
  Pythagoras und Berechnungen in Körpern“ statt „Pythagoras und Körper“). Die Inseln wachsen mit.
- **Linienführung:** Es bleibt immer ein Gang unter allen Inseln frei (14 pt im Druck, 18 px in der
  Präsentation). Deshalb musste die Rechnung nie Inseln verschieben. Ein Rücken der Inseln ist nicht gebaut.
  Gelangt eine Linie nicht in einen Gang zwischen zwei Inseln, nimmt sie den nächsten freien, notfalls den
  unten. Linien verschiedener Basen bekommen eigene Spuren in den Gassen; kreuzen dürfen sie sich, eine
  Insel schneiden nicht (geprüft in Vitest mit simulierter Lage für alle Fälle sowie im Druck- und
  Ansichtstest an der echten Lage).
- **Druck-Tests:** Neben den neuen Fällen prüft `e2e-druck` jetzt auf Seite 3 auch: kein Überlauf des
  Lernwegs (auch nach dem Kürzen), kein Text ragt aus einer Insel, keine Linie schneidet eine Insel. Sonst
  bliebe „Seite 3 darf nicht überlaufen“ ungeprüft: der Bereich schneidet ab, `.eb-inhalt` merkt nichts.
- **Präsentation, 44 px:** Einträge sind Knöpfe. Ihre Trefferfläche (`::before`) wächst mit der Skala, so
  dass sie körperlich mindestens 44 px hoch ist (`--tp-s3-treffer` aus `useLernwegFahrt.ts`).
- **Die Pfeilspitze der Fahrt** ist die Front der wachsenden Linien, kein eigenes Element (wie im Prototyp).
  Für den Ansichtstest steht ihre Lage im Bild als `data-spitze` am Scroller.

## Offen

1. **Elternbezeichnung je Skill in der Datenbank** (Migration durch Rasit). Bis dahin löst `elternLabel.ts`
   Fachkürzel auf (LGS → Gleichungssysteme, Sachsituationen → Sachaufgaben).
2. **„baut auf beiden Verfahren auf“** passt nur bei Verfahren. Mit Batus echten Daten steht es in
   Geometrie unter „Zusammengesetzte Vielecke“, das auf Trapez und Drachen/Raute aufbaut (siehe
   Gegenrechnung). Vorschlag für Lena: „baut auf beiden auf“.
3. **Coach-Sicht:** `schulen` und `leads` liest nur der Admin. Für einen Coach fallen der Weg über den
   Lead und der Abgleich über den Namen weg (Batu: Kernlehrplan statt Schulplan). Gilt
   `students.schule_id`, kommt der Plan auch beim Coach, aber ohne Schulnamen. Abhilfe wäre eine
   Leserechte-Funktion; das ist RLS und gehört Rasit.
4. **Batus Schule** steht in `leads.schule_id` (Weg 2). `students.schule_id` ist leer; über den Namen
   (Weg 3) würde sie auch gefunden. Den Eintrag in `students.schule_id` nachziehen?
5. **Halbjahr:** Der FWG-Plan hat in Prod kein Halbjahr. Ohne Thema der Sitzung zeigt Kommt noch dann den
   ganzen Plan (Fall `planOhneThema` nutzt deshalb synthetische Halbjahre).
6. **`nicht_angesetzt` zählt als Übungsbedarf** (seit R7-1). Bei Batu kommt so „Flächeninhalt des
   Trapezes“ in Geometrie, mit einem weiteren ↳ (siehe Gegenrechnung).
7. **Aufräumkandidaten** (nicht entfernt, Entscheidung 27):
   - `einordnung.ts`, `bericht.pyramide`, `PraesentationDaten.pyramide` und `TpEbene`;
   - in `rahmen.css` der Präsentation die Zeiten der Pyramide (`--tp-ebene-*`, `--tp-strich-*`, `--tp-lesehilfe*`).
8. **Nicht mehr genutzte Texte** (bleiben stehen, Anhang A wird wörtlich geprüft):
   - `elternbericht`: `s3.intro`, `s3.introKurz`, `s3.zwischenzeile`, `s3.legende.*`, `s3.ebene.*`,
     `s3.zaehlung.*`, `s3.weitere`, `s3.eintragAria`, `s3.lesen.*`;
   - `praesentation`: `s3.titel`, `s3.desc`, `s3.ebeneAria*`, `s3.lesen.*`, `s3.pyramideAria`.
9. **Seite 1, Weg durch den Bericht:** `elternbericht:s1.weg.station.3` heißt weiter „Einordnung“. Das
   betrifft Seite 1 und die Seitenleiste aus R7-7, also nicht diesen Auftrag. Soll es „Lernweg“ heißen?
10. **Querformat der Präsentation:** Bei 1180×820 ist s ≈ 0,6, die Schrift der Inseln also etwa 9 px. Die
    Fläche passt dort fast ganz ins Bild (Scrollbereich 78 px), und die Markierung unten bleibt bei
    „Grundlagen“, solange deren Rand links sichtbar ist.

## Was die Grenzen weglassen (Entscheidung 8 und 9, alle Fälle)

| Fall | Linien | Linien weg | nicht geprüft weg | Kommt noch weg |
|---|---|---|---|---|
| ilkay | 5 | 19 | 11 | 8 |
| testlauf | 5 | 19 | 11 | 8 |
| klasse10neu | 3 | 0 | 6 | 8 |
| klasse7 | 6 | 0 | 6 | 1 |
| spaeter | 6 | 0 | 9 | 1 |
| allesSicher | 5 | 31 | 11 | 8 |
| nichtsSicher | 0 | 0 | 7 | 8 |
| sechsFelderMitUebung | 1 | 0 | 0 | 8 |
| alleFelder | 1 | 0 | 2 | 8 |
| ohneName | 5 | 19 | 11 | 8 |
| vieleRueckbezuege | 5 | 19 | 11 | 8 |
| ohneNotizen | 5 | 19 | 11 | 8 |
| ohneKatalog | – | – | – | – |
| mitFazit | 5 | 19 | 11 | 8 |
| fazitLang | 1 | 0 | 0 | 8 |
| langerName | 5 | 19 | 11 | 8 |
| zuLangerName | 5 | 19 | 11 | 8 |
| breiterName | 5 | 19 | 11 | 8 |
| weitereBereiche | 5 | 19 | 11 | 8 |
| vieleAnliegen | 5 | 23 | 12 | 8 |
| keinSchwerpunktMitZiel | 5 | 31 | 11 | 8 |
| abgestuft | 4 | 0 | 0 | 0 |
| abgestuftMitOffen | 2 | 0 | 0 | 0 |
| abgestuftLang | 0 | 0 | 0 | 0 |
| ohneKanten | 0 | 0 | 0 | 0 |
| planOhneThema | 4 | 0 | 0 | 0 |
| vieleKanten | 5 | 31 | 11 | 8 |
| langeLabels | 4 | 0 | 0 | 0 |

Auf Seite 3 musste in keinem Fall gekürzt werden (Stufe 0 überall), seit die Spalten nach Inhalt breit werden.

## Abnahme

- Druck-Tests: `EB_PORT=5190 EB_AUSGABE=docs/report/r7/abnahme/r7-9 npx playwright test -c playwright.elternbericht.config.ts`: 28/28 grün.
- Ansichtstests: `TP_PORT=5191 TP_AUSGABE=docs/report/praesentation/abnahme/r7-9 npx playwright test -c playwright.praesentation.config.ts`: 305/305 grün,
  mit Fahrt (Spitze 55–70 % in jedem Bild, Ende bei scrollLeft 0 und „Grundlagen“), Rad senkrecht zu Station 04, Ziehen über 60 px.
- Video der Fahrt: `docs/report/praesentation/abnahme/r7-9/fahrt.webm` (abgestuft, 1180×820).

## Gegenrechnung Batu Test1 (6220b7e8, dbread nur lesend, 20.10.2026)

Schulweg: `students.schule_id` leer → **Weg 2, `leads.schule_id` über `students.lead_id`**: Friedrich-Wilhelm-Gymnasium
(Weg 3 über den Namen fände dieselbe Schule). Plan: `schul_themenplan` Klasse 9 und 10, Fach Mathematik, ohne
Halbjahr. Thema der Sitzung: Reelle Zahlen (Position 1) → Kommt noch ab Position 2. Datum 18.10.2026 → „Oktober“.

| Zone | Insel | Einträge (↳ = baut direkt darauf auf) | gebröckelt |
|---|---|---|---|
| Grundlagen | Brüche & Dezimalzahlen | Bruch in Dezimalzahl (sicher) | – |
| Weiterführend | Terme & Gleichungen | Einsetzungsverfahren (sicher); Gleichungssysteme grafisch lösen (sicher); Additionsverfahren (Übung) ↳ Gleichungssysteme aus Sachaufgaben aufstellen und lösen (noch nicht geprüft; Basen Einsetzungs- und Additionsverfahren) | – |
| Weiterführend | Geometrie | Flächeninhalt des Trapezes (Übung) ↳ Seite oder Höhe aus dem Flächeninhalt (noch nicht geprüft); Flächeninhalt von Drachen und Raute (Übung) ↳ Zusammengesetzte Vielecke (noch nicht geprüft; Basen Trapez und Drachen/Raute); Satz des Thales (Übung); Terme für Flächeninhalte (Übung) | ja |
| Weiterführend | Daten & Zufall | Mehrstufige Zufallsexperimente: Summenregel (Übung); Laplace-Wahrscheinlichkeit (noch nicht geprüft) | – |
| Aktuell | Zahlen & Rechnen | Wurzeln abschätzen und Näherungswerte (sicher); Rationale und irrationale Zahlen (Übung); Wurzelgesetze für Produkt und Quotient (Übung) ↳ Teilweise die Wurzel ziehen (Übung) | ja |
| Kommt noch | Quadratische Funktionen | – | – |
| Kommt noch | Kreise, Prismen und Zylinder | – | – |
| Kommt noch | Potenzen und Potenzgesetze | Negative Hochzahlen und Hochzahl null (noch nicht geprüft) | – |
| Kommt noch | Der Satz des Pythagoras und Berechnungen in Körpern | – | – |
| Kommt noch | Daten und Wahrscheinlichkeit | Vierfeldertafel ergänzen (noch nicht geprüft) | – |

- **Linien** (alle von der sicheren Basis „Bruch in Dezimalzahl“): → Vierfeldertafel ergänzen,
  → Negative Hochzahlen und Hochzahl null, → Rationale und irrationale Zahlen, → Laplace-Wahrscheinlichkeit.
- **Nächste Klasse (nur Präsentation):** Klasse 10 mit Daten und Wahrscheinlichkeit; Quadratische Funktionen und
  Gleichungen; Ähnlichkeit; Exponentialfunktionen; Trigonometrie; Trigonometrische Funktionen.
- **Weggelassen:** nichts.

Abweichung von der Fixture `abgestuft`: Prod hat ein 13. direktes Urteil („Flächeninhalt des Trapezes“,
`nicht_angesetzt`), das die Fixture bewusst weglässt. Daraus kommen das zusätzliche ↳ in Geometrie und die
zweite Basis von „Zusammengesetzte Vielecke“. Sonst ist alles wie in Entwurf, Prototyp und Fixture.

## Nachbesserung (Review #289, 20.10.2026)

Auftrag: `docs/report/r7/Nachbesserung-R7-9.md`. Der Druck ist unverändert: Alle 27 PDFs in `abnahme/r7-9`
sind bis auf das Erstellungsdatum byteweise gleich wie vor der Nachbesserung. Der Druck misst weiter mit
getBoundingClientRect, die Präsentation mit Layoutwerten (`messeLernweg(…, 'layout')`).

- **Lesbarkeit (Entscheidung 1):** S_MIN = 0,85. Einträge sind 17 px groß, Unterzeilen und Inseltitel
  15,5 px, Titel in Kommt noch 17 px (Entwurfsmaß). Im Bild ist damit nichts kleiner als 13 px. Die
  Ansichtstests prüfen das für jedes Maß und jeden Fall.
- **Spalten statt Höhe (Entscheidung 2):** Die Spur ist fest 510 Entwurfs-px hoch. Die Inseln einer
  Gruppe (Zone; in Kommt noch dieses Schuljahr und die nächste Klasse) brechen in weitere Spalten um
  (`packeSpalten`, `lernwegSpalten.ts`), die Reihenfolge bleibt, die Lücken bleiben Gassen.
  - Statt `flex-flow: column wrap` zählt das Programm die Spalten: Chromium macht einen Container mit
    `column wrap` nicht breiter, wenn er umbricht; die Spur würde abgeschnitten. Das Ergebnis ist dasselbe.
  - **Ausnahme (wie erlaubt):** `abgestuftMitOffen`, Insel „Zahlen & Rechnen“ in Aktuell: zu hoch für
    den Platz bei 510. Die Spur ist dort 548 px hoch. In allen anderen Fällen bleibt sie bei 510.
  - Fund der zweiten Zweitprüfung: Die Ausnahme hob sich zuerst selbst auf. Die zweite Messung sah den Platz
    der schon höheren Spur und setzte sie auf 510 zurück; die Insel ragte 14 px aus der Zone. Jetzt zählt
    der Platz immer bei 510.
  - Neu im Ansichtstest: jede Insel liegt ganz in ihrer Zone, für alle Fälle und Maße. Die Gegenprobe
    ohne die Korrektur ist rot.
- **Querformat (Entscheidung 3):**
  - Titel, Satz und „Weg abspielen“ stehen in einer Zeile. Der Satz entfällt, wenn er nicht einzeilig
    passt; bei 1180×820 ist das der Fall.
  - Legende in einer Reihe.
  - Infofeld links, Balken und Zonennamen rechts.
  - Hochformat unverändert.
- **Laufkoordinate (Entscheidung 4):**
  - w = x + alle senkrechten Wege; gerechnet als Weglänge entlang der Linie (|Δx| + |Δy|), damit auch
    Stücke nach links streng steigen.
  - Die Spitze läuft auf w, die Kamera und das Aufdecken folgen dem größten erreichten x.
  - Im Ansichtstest wächst keine Linie in einem Bild um mehr als 40 Entwurfs-px.
- **Robust (Entscheidung 5):**
  - Eine Größenänderung während der Fahrt unterbricht sie.
  - Ziehen mit Pointer-Capture (erst ab 5 px, damit ein Tippen ein Klick bleibt); `pointercancel` wie `pointerup`.
  - Antippen fokussiert ohne Scrollsprung: Der Browser schob die Fläche sonst zum Knopf, und die Ansicht
    blieb beim Abbruch nicht stehen (Fund aus dem Review).
- **Linien beim Einblenden (Fund aus dem Review):** Gemessen wurde mit getBoundingClientRect, also mit
  dem translateY des Einblendens. Die Linien lagen dadurch während der ersten Fahrt etwa 10 Entwurfs-px zu
  tief. Neu geprüft: im Ansichtstest in der Pause der ersten Fahrt und nach einem Abbruch mitten im Schieben.
  Die Gegenprobe mit der alten Messung ist rot.
- **Bogen.tsx:** zweite und letzte Zeile, `useMemo`-Abhängigkeiten mit `data.erzaehlung` und `data.analysedAt`.
- **CLAUDE.md §11:** Der Verlauf von Kommt noch in Station 03 steht jetzt in der Liste der erlaubten Verläufe.
- **Abstand der Linie zu den Inseln** (Hinweis der Zweitprüfung): Zwischen Zonenkopf und Inseln liegen
  jetzt 22 Entwurfs-px; die waagrechte Linie läuft mittig darin (Abstand 9), nicht mehr 4 px über der Kante.
- **neuaufbau:** rot nur durch `session_a2` (Test 15, Median unter 200 ms), bekannte Laufzeitmessung;
  der rote Job ist neu gestartet.

### Gemessen (Chromium, ruhige Bewegung, Station 03)

| Fall | Maß | Bühne (px) | Skala | kleinste Schrift im Bild (px) | Scrollbereich / Breite |
|---|---|---|---|---|---|
| abgestuft | 820x1180 | 783 | 1.35 | 20.93 | 5.7 |
| abgestuft | 820x1100 | 709 | 1.35 | 20.93 | 5.7 |
| abgestuft | 1180x820 | 560 | 1.086 | 16.84 | 2.6 |
| abgestuft | 1180x740 | 480 | 0.929 | 14.41 | 2.1 |
| abgestuft | 744x1133 | 740 | 1.35 | 20.93 | 5.9 |
| abgestuft | 744x1060 | 672 | 1.306 | 20.24 | 5.6 |
| abgestuft | 1133x744 | 485 | 0.939 | 14.56 | 2.3 |
| abgestuft | 1032x1376 | 979 | 1.35 | 20.93 | 4.0 |
| abgestuft | 1376x1032 | 782 | 1.35 | 20.93 | 2.8 |
| ilkay | 820x1180 | 805 | 1.35 | 20.93 | 6.3 |
| ilkay | 820x1100 | 731 | 1.35 | 20.93 | 6.3 |
| ilkay | 1180x820 | 560 | 1.086 | 16.84 | 2.9 |
| ilkay | 1180x740 | 480 | 0.929 | 14.41 | 2.4 |
| ilkay | 744x1133 | 762 | 1.35 | 20.93 | 6.5 |
| ilkay | 744x1060 | 694 | 1.349 | 20.91 | 6.5 |
| ilkay | 1133x744 | 485 | 0.939 | 14.56 | 2.6 |
| ilkay | 1032x1376 | 979 | 1.35 | 20.93 | 4.4 |
| ilkay | 1376x1032 | 782 | 1.35 | 20.93 | 3.2 |

### Kernlehrplan, zweites Jahr einer Stufe (Entscheidung 7) — Vorlage für Rasits Daten-Migration

`klpPlan` nimmt im zweiten Jahr (Klasse 6, 8, 10) nur noch Themen mit `themen.klasse ≥ Klasse`, sobald es
solche gibt. Heute steht `themen.klasse` je Stufe überall auf dem ersten Jahr (dbread 20.10.2026: 5, 7 bzw. 9).
Vorschlag nach dem Aufbau von Lambacher Schweizer NRW (G9). **Vor der Migration gegen das Inhaltsverzeichnis
prüfen**: Die Zuordnung stammt aus dem Gedächtnis, nicht aus dem Buch. Unsicheres ist markiert.

| Stufe | bleibt beim ersten Jahr | neu `klasse` = zweites Jahr |
|---|---|---|
| 5/6 | natuerliche_zahlen, rechnen_natuerliche_zahlen, daten_streumasse, geometrische_grundbegriffe, symmetrie, flaeche_umfang | **6:** teilbarkeit, brueche, rechnen_brueche_dezimalzahlen, winkel, koerper_quader (?), ganze_zahlen_groessen |
| 7/8 | rationale_zahlen, zuordnungen, zinsrechnung, terme_gleichungen, winkel_dreiecke | **8:** lineare_funktionen, terme_binomische_formeln, zufallsexperimente (?), flaechen_vielecke, lineare_gleichungen_lgs, thales_konstruktionen |
| 9/10 | reelle_zahlen, potenzen, quadratische_funktionen, quadratische_gleichungen (?), pythagoras, kreis, prismen_zylinder | **10:** aehnlichkeit (?), koerper_pyramide_kegel_kugel, trigonometrie, exponentialfunktionen, sinusfunktion, bedingte_wahrscheinlichkeit (?), statistik_beurteilen |

Zum Vergleich der FWG-Plan: Klasse 10 hat dort bedingte Wahrscheinlichkeit (auch 9), quadratische
Gleichungen, Ähnlichkeit, Exponentialfunktionen, Trigonometrie und trigonometrische Funktionen.
