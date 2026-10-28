# Bauauftrag B · Abnahmefälle (Anforderung Studio §14)

Stand 27.10.2026. pgTAP lokal im eigenen Wegwerf-Cluster (alle Migrationen + Seed, wie die CI); Vitest im Repo;
Ansichtstests per Playwright. „Live“ = zusätzlich nach dem Merge laut `../live-checkliste.md`.

| # | Fall | Ergebnis | Beleg |
|---|---|---|---|
| 1 | Unbekannter Baustein: Studio speichert nichts und nennt den Beat | bestanden | Vitest `src/studio/skript/pruefen.test.ts` („unbekannter Baustein …“, Beat b4); Datenbank lehnt ungültige Skripte zusätzlich ab (`studio_b1`) |
| 2 | Variante sagt „fünfzig“ statt „neunundvierzig“: nur diese Variante gesperrt, Skelett prüfbar | bestanden | Vitest (Fehlerfall-Datei: Musik b3, fehlt 49, neu 50); pgTAP `studio_b1`; Bildschirm `b9/studio-*-einfuegen-befunde.png` |
| 3 | Satz geändert: nur dieser Satz neu vertont, Render „veraltet“ | bestanden (lokal), live offen | pgTAP `studio_b2` („nur der geänderte Satz ist fällig“), `studio_b4` („Welt-/Skelett-Änderung: veraltet“); echte Stimme live |
| 4 | Autor gibt eigene Sequenz frei: Knopf gesperrt, Datenbank lehnt ab | bestanden | pgTAP `studio_b5` (auch direkter Insert); `studio_freigabe_stand.darf` für den Autor false |
| 5 | Lena „passt nicht“ an b4: zurück an den Autor, Kommentar am Beat | bestanden | pgTAP `studio_b5` (an b2); Bildschirm `b9/studio-*-freigabe.png` (Anmerkung an b4) |
| 6 | Fußball-Kind antwortet 32: Rückmeldung, Sprung auf b5, danach andere Zahlen | bestanden | pgTAP `studio_b6`; Vitest App `src/components/sequenz/video.test.ts`; Ansichtstest `erklaer-video.spec.ts` (Rückmeldung, Sprung) |
| 7 | Fußball-Variante nicht freigegeben: Skelett-Fassung | bestanden | pgTAP `studio_b6` |
| 8 | Freigegebene Sequenz geändert: Kinder sehen die alte Fassung | bestanden | pgTAP `studio_b5`; `studio_b6` („Entwurf ändert die ausgegebene Fassung nicht“) |
| 9 | Mediathek: keine Mini-Checks, höchstens „angesehen“ | bestanden | pgTAP `studio_b6`; Ansichtstest „Zuhause: keine Mini-Checks“ |
| 10 | Eddie verlinkt nie einen Entwurf | bestanden | pgTAP `studio_b6` |

Weitere Abnahmen je Phase:
- B1 Referenz-Skript importiert ohne Befund (Vitest), Fehlerfall sperrt nur Musik.
- B3 Quadratwurzeln in allen vier Welten: `b3/quadratwurzel-*.jpg`.
- B4 MP4 und Kapitel gegen die Vorschau, frame-genau: `b4/abgleich.md`.
- B7 Bausteine in allen vier Welten: `b7/bausteine-*.jpg` (Abnahme durch Ashkan live).
- B8 Skripte: `../skripte/pruefung.md`.
- B9 Ansichten Studio 1440 × 900 und iPad quer 1180 × 820: `b9/studio-*.png`; ErklaerVideo in vier Größen: edvance-app `docs/reihe1/B/abnahme/erklaer-video/`.
