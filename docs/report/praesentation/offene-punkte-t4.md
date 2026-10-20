# T4 · Station 03 und 04 – Abweichungen und offene Punkte

Stand 20.10.2026, Branch `feat/rasit-praesentation-stationen34`.

## Wichtig: Die Ansichtstests prüfen mit Bewegung, nicht ruhig

`e2e-praesentation/praesentation.spec.ts` setzt `test.use({ reducedMotion: 'reduce' })`. Das ist in Playwright
**keine** Test-Option und wird still ignoriert; im Browser gilt `prefers-reduced-motion: no-preference`
(geprüft mit `matchMedia` im Test). Folge:

- Gemessen und fotografiert wird direkt nach dem Sprung, mitten in der Bewegung des ersten Besuchs. Alles,
  was erst nach einer Verzögerung einblendet (`tp-reveal` mit `--tp-verzoegerung` ab etwa 800 ms), hat dann
  noch `opacity: 0` und wird von `verstoesse()` als „nicht gezeigt“ übersprungen.
- In Station 03 und 04 betrifft das alles unter dem Untertitel: Pyramide, Lesehilfe, Kurve, Beschriftungen,
  Förderfokus, Hinweis, Empfehlung. Der offizielle Lauf war deshalb 164/164 grün, ohne diese Teile zu messen,
  und seine Fotos zeigen nur Kicker, Titel und Untertitel. T3 (Station 02, Zahlen ab 330 ms, Zeilen ab
  1560 ms) ist genauso betroffen, ebenso die T2-Fotos.
- **Korrektur (eine Zeile, gehört T2/Rasit):** `test.use({ contextOptions: { reducedMotion: 'reduce' } })`.
  T4 darf `e2e-praesentation/**` nicht ändern und hat es nicht geändert.
- **So hat T4 geprüft:** mit einer nicht eingecheckten Kopie der Spec mit genau dieser Korrektur, gleicher
  Config (Port 5187). Ergebnis: zuerst 8 echte Fehler bei 1133×744 (Kurve durch die Beschriftung
  „Brüche & Dezimalzahlen“), nach der Korrektur in `station4-kurve.css` 164/164 grün. Die Fotos in
  `abnahme/t4/` stammen aus diesem Lauf (nur Stationen 03 und 04).
- Der offizielle Lauf (unverändert) ist ebenfalls 164/164 grün.

## Abweichungen vom Dummy (mit Grund)

- **03:** Ebenen, Namen und Lesehilfe aus den Daten und Anhang A; „Aktueller Unterrichtsstoff“ statt
  „Aktueller Stoff“, keine Aussage „baut auf den Stufen darunter auf“ (Entscheidung 12). „Übersprungen“ als
  Punktmuster (`radial-gradient` aus `--color-tp-ueber-*`, getrennt `--color-tp-ueber-neutral-*`), nie
  Streifen. Zählung je Ebene als eigene Teile („4 sicher“ · „8 Übungsbedarf“ · „davon 3 übersprungen“) statt
  „(davon …)“ in Klammern. Pyramide als `<ul>` mit Vorlesetext an der Spur (`role="img"`, `s3.ebeneAria…`).
- **04:** Bereiche als Liste statt Symbolen und ohne Fließtext je Schwerpunkt (Entscheidung 12). Die
  Mint-Kugel oben rechts in der Karte entfällt (Verläufe nur für die Kugeln nach CLAUDE.md §11). Die Fläche
  „Hier üben wir“ ist `color-mix(in srgb, var(--color-eb-uebung) 14%, transparent)` statt `#F6E7E2`, „Sicher im
  Test“ `--color-eb-mint`.
- **Beschriftung „links“** (2. von 4, 2. von 3 Punkten) ist um 90 % ihrer Höhe nach oben versetzt statt mittig zum Punkt
  (`translateY(-90%)` statt `-50%`): Bei schmaler Kurve (1133×744: 445 px) lief die Kurve durch die untere linke Ecke von
  „Brüche & Dezimalzahlen“. Kleinster Abstand Kurve–Beschriftung jetzt 5 px (1133×744), sonst 9–19 px; mit
  1–3 Punkten 16–27 px. Beschriftungen untereinander mindestens 29 px.
- **Farben gerundet:** Kurve und Startpunkt `--color-eb-navy` (Dummy `--logo-navy`), Pfeil `--color-eb-gold`,
  Beschriftung `#5A6D7D` → `--color-eb-text`, `#8897A1`/`#72838D`/`#91A09F` → `--color-eb-leise`, Ebenen-Titel
  `#294560` → `--color-eb-navy`, Rand des weißen Punkts `#FFFCF5` → `--color-eb-weiss`, Kugelverlauf der
  nicht gewählten Punkte (`#FFF3D6`, `#F8D08A`, `#EDAA52`) → `--color-tp-kugel-hell/-mitte/-warm`, Schatten
  `rgba(51,77,122,…)` → `color-mix` mit `--color-eb-navy`, gelbe Ringe mit `--color-eb-gold`.

## Offen

1. **Spec-Korrektur** (siehe oben) vor der iPad-Abnahme einspielen; danach T3 und T4 noch einmal offiziell
   laufen lassen und die Fotos neu ziehen.
2. **Punktmuster doppelt:** T3 baut das Muster „übersprungen“ für Station 02 parallel in `station2.css`; T4
   hat es in `station3.css` unter `.tp-s3-seg-ueber`. Nach dem Merge beider an eine Stelle ziehen
   (z. B. eine gemeinsame Klasse in `rahmen.css`, gehört T2/Rasit).
3. **Zählung doppelt:** Die Zählung „x sicher · y Übungsbedarf · davon z übersprungen“ hat T4 als kleine
   Funktion in `Pyramide.tsx`; T3 hat eine eigene für die Zeilen in 02. Zusammenlegen nach dem Merge.
4. **Lage des Förderfokus im Hochformat** (unter der Kurve) bei der Abnahme bestätigen (Abnahme 7).
5. **Zeile „Basic ist ebenfalls möglich“** bei der Abnahme bestätigen (Beschluss vom 17.10.).
6. **WebKit** wie in T2 nicht gelaufen (Systembibliotheken fehlen in WSL); Safari bleibt Teil der iPad-Abnahme.
7. **Vier Ebenen** kommen nach der R7-Regel nicht vor (höchstens drei); `tp-s3-breite-3` (43 %) ist nur
   Vorsorge.
