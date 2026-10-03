# K9-Rest – Thema quadrgl (Quadratische Gleichungen)

Stand 03.10.2026 · Branch `feat/k9-rest` · KLP Ari-8, Zweite Stufe · Quelle `tools/k9-quadrgl-charge.mjs`
→ `docs/prefill/k9-quadrgl.json` → `supabase/migrations/20261003105903_aufgaben_k9_quadrgl.sql`.

24 Aufgaben, je sechs zu `gleichung_quadr_wurzel`, `_faktor`, `_formel`, `_anzahl`. Alle `draft`,
`source = edvance_k9_quadrgl`, Klasse 9, Themengebiet „Algebra & Funktionen", `arithmetik_algebra`,
keine Abbildung, keine Hinweise. Muster je Knoten wie beim Kreis: 01/02 AFB I, 03/04 AFB II, 05 AFB II mit
Sachkontext, 06 AFB III (Sachkontext oder Rückrichtung).

## Entscheidungen

- **Zwei Lösungen immer MULTI_PART**: Teil 1 „kleinere Lösung", Teil 2 „größere Lösung". So ist jede
  Eingabe eine einzelne Zahl, die Reihenfolge eindeutig, und Fehlbilder lassen sich je Teil zuordnen
  (z. B. bei x² = 49 ist 7 in Teil 1 `negative_loesung_vergessen`, in Teil 2 richtig).
- **Sachaufgaben mit nur einer sinnvollen Lösung sind NUMERIC mit Einheit** (Beet, Quadrat, Ball,
  Rechteck, Weg). Der Text sagt, dass eine Länge positiv ist, bzw. der Lösungsweg verwirft die negative
  Lösung ausdrücklich.
- **Exakt vs. gerundet**: Exakt, wo die Lösungen abbrechen; gerundet auf zwei Stellen nur bei
  `wurzel-04` (√20) und `formel-04` (√5). Fehlerwerte, die bei einer exakt gestellten Aufgabe auf eine
  Nicht-Quadratwurzel führen (`division_vergessen` in `wurzel-05`, `formel-03`, `formel-06`,
  `quadrat_gliedweise` in `wurzel-06`), haben eine eigene Rundung auf zwei Stellen – das ist der Wert, den
  jemand mit dem Taschenrechner eintippt.
- **`division_vergessen` bei 2x² − 4x − 6 = 0** nur, weil er einen eigenen Wert erzeugt (2 ± √10 ≈ −1,16 /
  5,16), der mit keiner richtigen Antwort kollidiert.
- **Diskriminanten-Knoten ohne q-Vorzeichenfehler**: Der naheliegende Fehler „−q falsch eingesetzt"
  passt auf keinen erlaubten Slug wörtlich (`vorzeichen_beim_umstellen` meint im Bestand „Betrag richtig,
  Minus bleibt hängen"). Stattdessen `vorzeichen_potenz` ((−3)² als −9), `halbieren_vergessen`
  (p statt p/2 quadriert), `division_vergessen` (nicht auf Normalform gebracht) und `betrag_fehler`
  (q = −9 statt 9). `halbieren_vergessen`, `falsche_groesse_beantwortet` und `betrag_fehler` sind
  Bestands-Slugs, die laut phase1 d) wörtlich passen müssen – sie tun es hier.
- **pq-Fehler bei Rechteck-Aufgaben**: Bei x(x + a) = A ergibt der p-Vorzeichenfehler als „Breite" genau
  die richtige Länge. Deshalb fragt `formel-05` nach der *längeren Seite* (10 cm); der pq-Fehler gibt dann
  14 cm, die Breite 6 cm ist `falsche_groesse_beantwortet`.
- **Unäres Minus**: Der Rechen-Parser bindet `-` vor `^` (−(6/2)² = +9). Ausdrücke mit negativem Quadrat
  stehen deshalb als `0-(6/2)^2`.
- **Neue Fehlbilder** dieses Themas: `negative_loesung_vergessen` (4 Aufgaben), `pq_vorzeichen` (6),
  `vorzeichen_aus_klammer` (6), `loesung_null_verloren` (3). Mitbenutzt: `wurzel_vergessen` (10).

## Aufgaben

Antwort bei MULTI_PART: Teil 1 / Teil 2. Rang = Sondierrang aus `vorlauf-build.mjs`.

| source_ref | Knoten | AFB | Begründung | Antwort | Fehlbilder | Rang |
|---|---|---|---|---|---|---|
| `quadrgl-wurzel-01` | wurzel | I | x² = 49, Wurzel einer Quadratzahl, beide Vorzeichen | −7 / 7 | `negative_loesung_vergessen`, `wurzel_vergessen` | – |
| `quadrgl-wurzel-02` | wurzel | I | 2x² − 18 = 0, erst nach x² umstellen | −3 / 3 | `negative_loesung_vergessen`, `falsche_gegenoperation`, `wurzel_vergessen` | 2 |
| `quadrgl-wurzel-03` | wurzel | II | (x − 2)² = 25, zwei Fälle getrennt auflösen | −3 / 7 | `vorzeichen_aus_klammer`, `negative_loesung_vergessen`, `wurzel_vergessen` | – |
| `quadrgl-wurzel-04` | wurzel | II | 3x² = 60, Nicht-Quadratzahl, runden (2 Stellen) | −4,47 / 4,47 | `negative_loesung_vergessen`, `division_vergessen`, `wurzel_vergessen` | – |
| `quadrgl-wurzel-05` | wurzel | II | Beet doppelt so lang wie breit, 98 m², nur positive Lösung | 7 m | `division_vergessen`, `wurzel_vergessen`, `falsche_gegenoperation` | – |
| `quadrgl-wurzel-06` | wurzel | III | Quadratseite +3 cm ergibt 121 cm², Gleichung selbst aufstellen | 8 cm | `vorzeichen_aus_klammer`, `falsche_groesse_beantwortet`, `quadrat_gliedweise`, `wurzel_vergessen` | 1 |
| `quadrgl-faktor-01` | faktor | I | x² − 5x = 0, x ausklammern | 0 / 5 | `loesung_null_verloren`, `vorzeichen_aus_klammer` | – |
| `quadrgl-faktor-02` | faktor | I | (x − 3)(x + 5) = 0, schon Produkt | −5 / 3 | `vorzeichen_aus_klammer` | – |
| `quadrgl-faktor-03` | faktor | II | 3x² = 12x, erst auf null bringen, Versuchung durch x zu teilen | 0 / 4 | `loesung_null_verloren`, `division_vergessen` | – |
| `quadrgl-faktor-04` | faktor | II | x(2x − 7) = 0, Lösung als Dezimalzahl | 0 / 3,5 | `loesung_null_verloren`, `vorzeichen_aus_klammer`, `division_vergessen` | 1 |
| `quadrgl-faktor-05` | faktor | II | Ball h = 20t − 5t², Landezeitpunkt | 4 s | `division_vergessen`, `vorzeichen_beim_umstellen` | 2 |
| `quadrgl-faktor-06` | faktor | III | Rückrichtung: 2x² + bx = 0 hat Lösung 3, b gesucht | −6 | `vorzeichen_aus_klammer`, `division_vergessen` | – |
| `quadrgl-formel-01` | formel | I | x² + 2x − 15 = 0, p und q ablesbar | −5 / 3 | `pq_vorzeichen`, `wurzel_vergessen` | – |
| `quadrgl-formel-02` | formel | I | x² − 6x + 5 = 0, negatives p | 1 / 5 | `pq_vorzeichen`, `wurzel_vergessen` | – |
| `quadrgl-formel-03` | formel | II | 2x² − 4x − 6 = 0, erst durch 2 teilen | −1 / 3 | `pq_vorzeichen`, `division_vergessen` | 2 |
| `quadrgl-formel-04` | formel | II | x² + 4x − 1 = 0, √5, runden (2 Stellen) | −4,24 / 0,24 | `pq_vorzeichen`, `wurzel_vergessen` | – |
| `quadrgl-formel-05` | formel | II | Rechteck 4 cm länger als breit, 60 cm², längere Seite | 10 cm | `pq_vorzeichen`, `falsche_groesse_beantwortet`, `wurzel_vergessen` | 1 |
| `quadrgl-formel-06` | formel | III | Weg um Beet 20 m × 15 m, gesamt 500 m², Modell selbst aufstellen | 2,5 m | `pq_vorzeichen`, `division_vergessen` | – |
| `quadrgl-anzahl-01` | anzahl | I | x² + 4x + 5 = 0, D < 0 deuten | 0 | `halbieren_vergessen` | – |
| `quadrgl-anzahl-02` | anzahl | I | D von x² − 6x + 8 = 0 | 1 | `vorzeichen_potenz`, `halbieren_vergessen` | – |
| `quadrgl-anzahl-03` | anzahl | II | D von x² − 5x − 6 = 0, p/2 dezimal, q negativ | 12,25 | `vorzeichen_potenz`, `halbieren_vergessen` | – |
| `quadrgl-anzahl-04` | anzahl | II | 2x² − 8x + 8 = 0, erst Normalform, D = 0 | 1 | `division_vergessen`, `vorzeichen_potenz` | 2 |
| `quadrgl-anzahl-05` | anzahl | II | Zaun 20 m, Fläche 25 m², x(10 − x) = 25 | 1 | `vorzeichen_potenz`, `halbieren_vergessen` | – |
| `quadrgl-anzahl-06` | anzahl | III | Rückrichtung: q für genau eine Lösung von x² + 6x + q = 0 | 9 | `betrag_fehler`, `halbieren_vergessen` | 1 |

## Prüfergebnisse

- `node tools/k9-quadrgl-charge.mjs`: 24 Aufgaben, keine Kollision.
- `verify-tasks --prefill`: Charge-Fehler **0**, Bestands-Befunde 0, Überschreibungen 0.
- Wegwerf-DB (alle acht Substrate + Aufgaben-Migration): zweiter Lauf zeilengleich, **IDEMPOTENT: ok**.
- `supabase/checks/k9_quadrgl_aufgaben.PRUEFUNG.sql`: **16 von 16 ok = t**.
- Zweiter Lauf von Charge-Skript und vorlauf-build erzeugt byte-gleiche Dateien.

## Offene Punkte / Befunde

- **Lösungsweg-Minus**: Ergebnisse im Lösungsweg kommen aus den Platzhaltern und stehen mit ASCII-Minus
  (`-7`), Zwischenschritte mit Unicode-Minus (`−5`). Grund: die Bibliothek prüft, dass der Weg die erste
  Antwort wörtlich (ASCII) nennt. Rein optisch; bei Bedarf in `k9-rest-lib.mjs` zentral lösen.
- **Reihenfolge vertauscht**: Wer in Teil 1 die größere Lösung tippt, wird bei manchen Aufgaben als
  Fehlbild erkannt (z. B. `wurzel-01` Teil 1 = 7 → `negative_loesung_vergessen`). Das ist bewusst so
  (je Teil geprüft, Prompt benennt die Reihenfolge), kann aber eine Vertauschung als Fehlbild deuten.
- **q-Vorzeichenfehler in der Diskriminante** (D = (p/2)² + q) hat keinen passenden Slug; er wird nicht
  erfasst. Kandidat für ein späteres Fehlbild.
- `term_einsetzen` (Voraussetzung von `gleichung_quadr_formel`) ist laut phase1 c) noch dünn (nur Entwürfe).
