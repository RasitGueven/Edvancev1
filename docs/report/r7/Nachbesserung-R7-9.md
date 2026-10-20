# Nachbesserung R7-9 · im selben PR #289, vor dem Merge

Stand 20.10.2026, aus dem Review von #289. Der Druck (Seite 3) ist abgenommen; diese Punkte betreffen fast nur
die Präsentation. Alle Entscheidungen des Bauauftrags R7-9 gelten weiter.

## Prompt

```
Du arbeitest im Repo Edvancev1 (WSL), Worktree ../Edvancev1-r7i, Branch feat/rasit-report-r7-lernweg (PR #289). Nachbesserung aus Rasits Review, im selben PR, kein neuer Branch. Lies diese Datei ganz und lege sie als docs/report/r7/Nachbesserung-R7-9.md im PR ab. Die Entscheidungen aus docs/report/r7/Bauauftrag-R7-9.md gelten weiter.

## Befund
- Querformat 1180x820: s ≈ 0,6, die Schrift der Inseln ist rund 9 px. Auf dem Tablet können Eltern das nicht lesen.
  - Ursachen: Die Bühne ist nur etwa 420 px hoch (Kopf, Satz, Legende in zwei Reihen, Fuß und Infofeld darüber und darunter). Die Spur ist höher als 510, weil Weiterführend drei Inseln übereinander stapelt.
  - Folge: Der Scrollbereich ist nur 78 px breit. Die Fahrt („der Pfeil schiebt die Fläche“) ist im Querformat praktisch nicht zu sehen.
- Der Synchron-Test in e2e-praesentation/lernweg.spec.ts zählt nur Bilder, in denen gescrollt wird. Bei 78 px Scrollbereich sind das wenige, der Test ist dadurch zu schwach.
- Senkrechte Stücke einer Linie erscheinen auf einen Schlag, weil der Fortschritt nur der x-Lage folgt. Im Video steht der Stamm neben Weiterführend schon zu Beginn in voller Höhe da.
- Bogen.tsx: Das useMemo nennt data.erzaehlung und data.analysedAt nicht als Abhängigkeiten.
- Kernlehrplan, Klasse 10: Kommt noch zeigt auch Themen der Klasse 9 (themen.klasse ist für 9/10 überall 9).
- neuaufbau ist rot, nur session_a2 (bekannte Laufzeitmessung).

## Entscheidungen
1. Lesbarkeit hat Vorrang: S_MIN = 0,85. Ein Eintrag hat im Bild nie weniger als 13 px Schrift, auf allen Maßen aus MASSE.
2. Die Spur hat eine feste Entwurfshöhe von höchstens 510 (ENTWURF_HOEHE). Inseln einer Zone brechen in weitere Spalten um, statt die Spur höher zu machen: Spalten der Zone mit flex-flow column wrap und fester Höhe, Reihenfolge der Themenfelder bleibt, Lücken zwischen den Spalten bleiben Gassen für die Linienführung. Das gilt auch für Kommt noch und die nächste Klasse. Die Breite wächst; mehr Scrollen ist gewollt. Eine Insel, die allein höher ist als die Spur, bekommt nur dann eine Ausnahme (Spur so hoch wie diese Insel), wenn es nicht anders geht; nenne den Fall in den offenen Punkten.
3. Mehr Höhe für die Bühne im Querformat (Höhe < Breite):
   - Legende in einer Reihe: kleinere Abstände; „kommt noch“ steht in derselben Reihe.
   - Der Satz unter dem Titel (s3.weg.desc) steht einzeilig neben „Weg abspielen“ oder entfällt im Querformat, wenn er nicht in eine Zeile passt.
   - Zonennamen und Infofeld teilen sich eine Zeile: Infofeld links, Balken und Namen rechts.
   - Titel und Kicker bleiben.
   - Ziel: Bühne ≥ 480 px bei 1180x820 und ≥ 440 px bei 1133x744. Hochformat bleibt, wie es ist.
4. Laufkoordinate statt x:
   - Jeder Pfad bekommt die Koordinate w = x + Summe der senkrechten Wege bis zu diesem Punkt. Für Stücke, die sich decken (gemeinsamer Stamm), ist w gleich, damit sie gleich schnell wachsen.
   - Die Spitze läuft auf w mit 115 Entwurfs-px/s (Dauer 6–14 s wie bisher).
   - Die Kamera folgt dem größten x, das die Front zu diesem Zeitpunkt erreicht hat.
   - Inseln und Zonen erscheinen weiter nach x.
   - Tabelle in useLinienZeichnen: w → Länge statt x → Länge. lernwegFahrt.ts rechnet auf w und gibt zusätzlich x der Front für Kamera und Aufdecken.
   - Tests in lernwegFahrt.test.ts.
5. Fahrt robust:
   - Ändert sich während der Fahrt die Größe (ResizeObserver, Drehung), wird unterbrochen (fertiger Zustand, Ansicht bleibt).
   - Maus-Ziehen mit setPointerCapture; onPointerCancel wie onPointerUp.
6. Bogen.tsx: Die Abhängigkeiten des useMemo werden [kompetenzen, katalog, data.grade, data.erzaehlung, data.analysedAt]. Das ist die zweite und letzte erlaubte Zeile in Bogen.tsx.
7. Kernlehrplan, zweites Jahr einer Stufe (Klasse 6, 8, 10):
   - klpPlan nimmt nur Themen mit themen.klasse ≥ Klasse des Kindes, wenn es solche gibt; sonst wie bisher alle Themen der Stufe. So wirkt es, sobald Rasit themen.klasse für die Themen der Klassen 6, 8 und 10 korrigiert (Daten-Migration, nicht in diesem PR).
   - Nenne in den offenen Punkten die betroffenen thema_keys je Stufe, mit dbread gelesen, als Vorlage für diese Migration. Reihenfolge nach Lambacher Schweizer.
8. CLAUDE.md §11: Ergänze den Verlauf von Kommt noch in der Präsentation in der Liste der erlaubten Verläufe, mit einer Zeile Begründung. Sonst nichts an CLAUDE.md ändern.
9. neuaufbau: nur den roten Job neu starten (gh run rerun <id> --failed); bleibt nur session_a2 rot, im PR vermerken.

## Tests
- e2e-praesentation, je Maß aus MASSE:
  - Schriftgröße jedes Eintrags im Bild ≥ 13 px (getComputedStyle × s, oder getBoundingClientRect der Textzeile).
  - Bühnenhöhe bei 1180x820 ≥ 480 px.
  - Weiter grün: kein Text aus einer Insel, keine Insel über einer Zonen-Überschrift, keine Linie durch eine Insel.
- Synchron-Test (abgestuft):
  - Bei 1180x820 und 820x1180 muss der Scrollbereich mindestens 1,5 Bildbreiten sein (sonst schlägt der Test fehl und meldet die Breite).
  - Mindestens 60 gemessene Bilder mit Spitze bei 55–70 %.
  - Kein Bild, in dem eine Linie in einem Schritt um mehr als 40 Entwurfs-px senkrecht wächst.
- Vitest: Spaltenumbruch (Zone mit 1, 3, 5 Inseln; Höhe ≤ 510), Laufkoordinate (gemeinsamer Stamm gleich schnell, senkrechtes Stück wächst stetig), klpPlan Klasse 10 mit und ohne korrigierte themen.klasse.
- Druck-Tests, Ansichtstests, inv4-*, Typecheck, Lint, Vitest grün. Seite 3 im Druck darf sich nicht ändern; prüfe das mit den PDFs aus abnahme/r7-9.
- Neues Video fahrt.webm (abgestuft, 1180x820), dazu fahrt-hoch.webm (820x1180).

## Umfang
Wie R7-9, dazu die Zeile aus Entscheidung 6 in Bogen.tsx und eine Zeile in CLAUDE.md §11. Am Druck nur, was Entscheidung 7 im gemeinsamen plan.ts ändert.

## Leitplanken
- Kein DDL, keine Migration, Prod nur lesend über dbread.
- INV-4.11 und INV-4.12, Dateien ≤ 400 Zeilen.
- Zweitprüfung durch eine frische Instanz. Schwerpunkt:
  - Lesbarkeit im Querformat
  - Fahrt sichtbar und gleichmäßig, auch die senkrechten Stücke
  - nichts überlappt
- STOPP nach dem Push.

## Melden
- PR-Link, neue CI
- Fotos Station 03 abgestuft und ilkay bei 1180x820, 1133x744 und 820x1180
- beide Videos
- gemessene Bühnenhöhe und kleinste Schrift je Maß als Tabelle
- Liste der thema_keys für die themen.klasse-Korrektur
- offene Punkte
```
