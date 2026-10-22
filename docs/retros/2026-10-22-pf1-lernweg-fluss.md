# Retro 2026-10-22 · PF-1 Station 03 Lernweg: flüssiger Aufbau

Bauauftrag: `docs/report/praesentation/Bauauftrag-PF-1.md`. Branch `feat/rasit-lernweg-fluss` (von `origin/dev`).

## Gebaut

- **Stabile Ref-Callbacks** (`useLinienZeichnen.ts`): `pfadRef(key, art)` kommt aus einem Cache und bleibt
  über Renders gleich. Vermessen wird nur ein neuer Pfad oder ein neues `d` (`abgleichen()` nach dem
  Rendern; Messung je key mit ihrem `d` gemerkt). Front-Tabelle und Bereich einmal je Messung gecacht.
  `stroke-dashoffset` und die Klasse der Spitze gehen nur bei Änderung ins DOM.
- **Sichtbarkeit ohne State** (neu `useLernwegSicht.ts`): Inseln und Zonen bekommen `tp-s3-da` je Bild
  per `classList`, „Sie sind hier“ wird immer gerendert und über `hidden` per Ref geschaltet. Der State
  (`sicht`, `hier`) zieht einmal nach, wenn alles aufgedeckt ist (Pause, Ende, Unterbrechen, ruhig).
- **Kästen vor Linie**: Sichtgrenze nach Kamera (`sichtGrenze` in `lernwegFahrt.ts`, rechte Kante minus
  `FAHRT.vorlauf`); „Sie sind hier“ bleibt an der Front. `VOR_ZONE`/`VOR_INSEL` entfallen.
- **Insel als Ganzes**: kein `tp-zeile-ein`/`--tp-i` mehr in Station 03, `--tp-s3-zeit-insel` 1 s → 500 ms.
- **Tempo**: 115 → 240 px/s, 6–14 s → 3,5–8 s, Warten 1,5 → 0,6 s.
- **Grafik**: keine Transition auf `filter`, die Unschärfe der Zukunft steht schon vor dem Einblenden;
  Wolken mit `will-change: transform`; `background`-Übergang der Einträge entfällt; Balken per `transform`
  statt `left`.
- **Außerhalb der Dateiliste, bewusst**: `useLernwegBedienung.ts` (onScroll). Der Handler setzte die
  Balken-Variablen am gemeinsamen Elternteil der Bühne und las danach Layout: Jede Insel erbte die
  Variablen, jedes Bild rechnete die Stile der ganzen Bühne neu (≈ 4,4 s von 4,9 s Layout in der
  Messung). Jetzt erst lesen, dann nur am Balken schreiben.
- Scroller-Maße (Breite, größtes scrollLeft) werden beim Messen gemerkt statt je Bild gelesen.

## Messung

Chromium (Playwright), `vorschau/praesentation.html?fall=dreiSchwerpunkte` (6 Linien, meiste aller
Attrappen-Fälle), 1180×820, CPU 4× über CDP, Trace über die Fahrt bis `data-phase=fertig`. Frames als
rAF-Abstände; Scripting/Layout/Paint als Selbstzeit im Renderer-Hauptthread (Paint inkl. PrePaint,
Layerize, Commit). Dev-Server, je drei Läufe abwechselnd vorher/nachher, Median; die Maschine war stark
belastet (Load 8–11, parallele Agenten), absolute Zahlen schwanken, der Vergleich ist unter gleicher Last.

| | vorher (dev) | nachher |
|---|---|---|
| Dauer der Fahrt (ab „warten“) | 21,3 s | 14,1 s |
| Frames gesamt | 539 | 742 |
| Frames > 16,7 ms | 323 (60 %) | 260 (35 %) |
| Frames > 50 ms | 62 | 9 |
| längster Frame | 766 ms | 250 ms |
| Scripting | 8 621 ms | 2 183 ms |
| Layout (inkl. Style) | 5 231 ms | 1 748 ms |
| Paint (inkl. Layerize/Commit) | 2 280 ms | 2 992 ms |
| `getPointAtLength` während der Fahrt | 31 056 | 0 |

Paint steigt, weil fast doppelt so viele Bilder fertig werden (≈ 52/s statt ≈ 25/s) und die Wolken eigene
Ebenen haben; das Rastern selbst (`Paint`) sank (312 → 237 ms).

Drosselung erst ab „warten“: Unter 4× fällt beim weichen Scrollen zur Station `motion-complete` auf
Station 03 (useStationen/Praesentation), die Fahrt bricht ab. Siehe offene Punkte.

## Tests

- Neu: `useLinienZeichnen.test.tsx` (stabile Refs, kein Neuvermessen ohne neues `d`, Front-Cache),
  `useLernwegSicht.test.tsx` (Klassen je Bild ohne Render, State zieht einmal nach),
  `Station3.fluss.test.tsx` (ruhig: alles sofort; Unterbrechen deckt alles auf; kein `--tp-i`).
- `lernwegFahrt.test.ts`: Dauer- und Warten-Erwartungen auf die neuen Konstanten angepasst
  (115 → 240 px/s, 6000/14000 → 3500/8000, 1499 → 599 ms); neu: Sichtgrenze nach Kamera.
- Playwright `playwright.praesentation.config.ts`: 343/343 grün. Ein erster Volllauf bei Load ≈ 11 hatte
  drei Ausreißer (zwei Fahrt-Tests, ein Intro-Test), einzeln und im zweiten Volllauf grün.

## Offen

- Abbruch durch `motion-complete` bei langsamem Gerät (siehe Messung): Auf einem langsamen iPad könnte
  die Fahrt beim Hinscrollen sofort als „unterbrochen“ enden. Gehört in den Rahmen (useStationen), nicht
  in PF-1.
- 240 px/s: Bei `dreiSchwerpunkte` dauert das Schieben jetzt ≈ 7,3 s statt ≈ 13,6 s. Sehr lange Wege stoßen an 8 s (dann
  schneller als 240 px/s), sehr kurze an 3,5 s (dann langsamer). Am iPad prüfen, ob 3,5 s bei kurzen Wegen
  träge oder 8 s bei langen zu hastig wirkt.
- WebKit nicht gemessen (kein WebKit in WSL); die Abnahme am iPad steht aus.
