# Bauauftrag PF-1 · Station 03 Lernweg: flüssiger Aufbau

Stand 22.10.2026. Anlass: Rasit am iPad. Die Pfeile malen sich sehr langsam und stocken. Gleichzeitig
bauen sich die Kästen Zeile für Zeile auf. Das wirkt unruhig und nicht sauber.

## Befund (dev 1013913, gelesen in useLernwegFahrt.ts, useLinienZeichnen.ts, LernwegBuehne.tsx, station3*.css)

1. **Hauptursache Stocken:** `f.pfadRef(key, 'linie')` erzeugt bei jedem Render eine neue Ref-Funktion.
   React ruft dann die alte mit `null` und die neue mit dem Element auf. Jedes Mal wird jeder Pfad neu
   vermessen: `getPointAtLength` alle 4 px, und jeder Aufruf erzwingt Layout. Gerendert wird bei jedem
   `setSicht`, also jedes Mal, wenn während der Fahrt eine Insel oder Zone erscheint. Genau dann ruckelt es.
2. Je Bild baut `geometrie()` über `front()` die Front-Tabelle neu: alle Stichproben aller Linien,
   kopiert und sortiert, 60-mal pro Sekunde. Dazu kommt `bereich()` mit Spread und `Math.min/max`.
   Das erzeugt Müll und Pausen der Speicherbereinigung.
3. Sichtbarkeit läuft über React-State (`sicht`, `hier`). Jede neue Insel rendert die ganze Bühne neu,
   mitten in der Animation.
4. Teure Grafik: Zukunfts-Inseln blenden `filter: blur()` mit einer Transition ein. Dazu ziehen fünf große
   Wolken mit `blur(14px)` dauerhaft hin und her, ohne eigene Ebene.
5. Choreografie: Eine Insel erscheint erst kurz bevor die Spitze ankommt (VOR_INSEL 20 px). Dann laufen
   ihre Zeilen einzeln ein (300 ms Takt, je 800 ms). Linie und Kästen bauen sich also gleichzeitig auf.
6. Tempo: Die Spitze läuft mit 115 px/s (6–14 s), davor 1,5 s Warten. Das ist zu langsam.

## Prompt

```
Du arbeitest im Repo Edvancev1 (WSL). Paket PF-1: Station 03 (Lernweg) der Tablet-Präsentation baut sich flüssig und in klarer Reihenfolge auf. Lies zuerst CLAUDE.md (§11 Tablet-Präsentation), src/components/edvance/praesentation/useLernwegFahrt.ts, useLinienZeichnen.ts, LernwegBuehne.tsx, src/lib/report/praesentation/lernwegFahrt.ts, src/styles/praesentation/station3.css und station3-weg.css. Lege diesen Bauauftrag als docs/report/praesentation/Bauauftrag-PF-1.md im PR ab.

## Ziel
Am iPad (Safari) läuft die Fahrt ohne sichtbares Stocken. Die Kästen stehen schon, wenn die Linie kommt. Die Linie zieht zügig und gleichmäßig durch. Nichts baut sich gleichzeitig Zeile für Zeile auf.

## Entscheidungen (nicht neu verhandeln)

### A. Leistung
1. Stabile Ref-Callbacks: pfadRef liefert je (key, art) dieselbe Funktion über Renders hinweg, z. B. aus einem Cache-Map im Hook. Ein Pfad wird nur neu vermessen, wenn sich sein d geändert hat; merk dir dafür das d je key. Ein Test sichert ab, dass ein Re-Render ohne Änderung von d getTotalLength/getPointAtLength nicht erneut aufruft.
2. Front-Tabelle und Bereich werden einmal nach dem Messen berechnet und gecacht. Ungültig werden sie nur, wenn sich Pfade ändern. Je Bild keine Arrays kopieren, nicht sortieren, kein Spread.
3. Sichtbarkeit während der Fahrt ohne React-State: Inseln, Zonen und „Du bist hier“ bekommen ihre Klasse (tp-s3-da) bzw. ihr Attribut je Bild über Refs bzw. classList, wie es der Kopf von useLernwegFahrt schon verspricht („setState nur, wenn eine Schwelle überschritten wird“). Während der Fahrt kein setState je Insel. Nach Ende oder Unterbrechen darf der State einmal nachziehen, damit React und DOM übereinstimmen.
4. Grafik:
   - Keine Transition auf filter. Zukunfts-Inseln blenden nur opacity/transform ein, die Unschärfe steht sofort.
   - Die Wolken bekommen will-change: transform (eigene Ebene).
   - Animiert werden in Station 03 nur opacity, transform und stroke-dashoffset.
   - Optik, Farben und Verläufe bleiben unverändert.

### B. Choreografie
5. Kästen vor Linie: Eine Insel und ihre Zone erscheinen, sobald sie in den sichtbaren Ausschnitt kommen, also von der Kamera aus gemessen (rechte Kante minus ein kleiner Rand) und nicht von der Spitze aus. Die Linie läuft dann durch Kästen, die schon stehen.
6. Eine Insel erscheint als Ganzes: Kasten und alle Zeilen zusammen in einem Einblenden, Dauer --tp-s3-zeit-insel, die auf 500 ms sinkt. Das Zeile-für-Zeile-Einlaufen (tp-zeile-ein mit --tp-s3-takt) entfällt in Station 03. Die Variablen bleiben in rahmen.css bzw. station3.css.
7. Tempo:
   - FAHRT.pxProSekunde 115 → 240, minDauer 6000 → 3500, maxDauer 14000 → 8000, warten 1500 → 600.
   - kamera, pause und zurueck bleiben.
   - Die Laufkoordinate (gleich schnelle senkrechte Stücke, gemeinsamer Stamm) bleibt, wie sie ist.
8. Alles andere bleibt unverändert: Unterbrechen per Antippen, Wischen und Rad; prefers-reduced-motion (alles sofort fertig); motion-complete; Drehung während der Fahrt; Rastpunkte; Infofeld.

## Umfang
- src/components/edvance/praesentation/useLernwegFahrt.ts, useLinienZeichnen.ts, LernwegBuehne.tsx
- src/lib/report/praesentation/lernwegFahrt.ts (nur Konstanten aus 7, ggf. reine Hilfsfunktion für die Sichtgrenze)
- src/styles/praesentation/station3.css, station3-weg.css
- Tests, docs/report/praesentation/Bauauftrag-PF-1.md, Retro
- Nicht anfassen: Druckbogen (elternbericht/**), andere Stationen, src/styles/tokens.css, supabase/**, src/lib/supabase/**. Dateien ≤ 400 Zeilen; wird useLernwegFahrt.ts zu groß, die Sichtlogik in eine eigene Datei auslagern.

## Messung (Pflicht, vorher und nachher)
- Chromium per Playwright: Präsentation eines Testkinds mit vielen Linien, Station 03, iPad-Viewport 1180×820, CPU-Drosselung 4× über CDP (Emulation.setCPUThrottlingRate). Ein Performance-Trace über die ganze Fahrt.
- Melde vorher und nachher: Anzahl Frames über 16,7 ms und über 50 ms, längster Frame, Gesamtzeit Scripting, Layout und Paint, und wie oft getPointAtLength während der Fahrt aufgerufen wird (nachher: 0).
- Datenquelle: Attrappen-Daten wie in den bestehenden Station-3-Tests. Keine echte Anmeldung, keine Prod-Daten, keine echten Namen.
- Bildschirmaufnahme (GIF oder WebM) der Fahrt nachher im PR unter docs/report/praesentation/pf-1/.

## Tests
- Vitest: stabile Refs (siehe 1), Front-Cache wird nur bei neuem d neu gebaut, Sichtgrenze nach Kamera (reine Funktion), neue FAHRT-Konstanten, reduzierte Bewegung zeigt alles sofort, Unterbrechen deckt alles auf.
- Bestehende Tests Station3*.test.tsx, Praesentation*.test.tsx und Invarianten (inv4-praesentation) bleiben grün. Erwartungen, die nur an alten Zeiten hängen, auf die neuen Werte anpassen und im PR nennen.
- npm run typecheck && npm run lint && npm run test grün.

## Leitplanken
- Worktree ../Edvancev1-pf1 auf feat/rasit-lernweg-fluss von origin/dev. PR gegen dev, nie main.
- Keine Migration, kein DDL, keine Prod-Zugriffe.
- Keine Hex-Werte, Inline-Styles nur für berechnete Werte, Texte nur über i18n (es kommen keine neuen dazu).
- STOPP nach dem PR.

## Melden
- PR-Link
- Messtabelle vorher/nachher
- Aufnahme der Fahrt
- Offene Punkte (z. B. falls 240 px/s bei sehr langen Wegen noch zu langsam oder bei kurzen zu hastig wirkt)
```
