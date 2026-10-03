# K10-Rest – Thema sinus (Sinusfunktion)

Stand 03.10.2026 · Branch `feat/k10-rest` · KLP G9 NRW, Zweite Stufe, Fkt-13/Fkt-14 (Klasse 10).
Quelle `tools/k10-sinus-charge.mjs` → `docs/prefill/k10-sinus.json` (ids in `docs/prefill/k10-sinus-ids.json`).
Einspiel-Reihenfolge: nach `20261003121329_substrat_k10_trigo.sql` und `20261003121331_substrat_k10_sinus.sql`.

30 Aufgaben, je sechs zu `fkt_sinus_einheitskreis`, `_bogenmass`, `_graph`, `_parameter`,
`_periodisch`. 23 `NUMERIC`, 7 `MULTI_PART` (alle Teile `short_input`). `curriculum_grade = 10`,
`class_level = 10`, „Algebra & Funktionen", `competency_content = funktionen`, keine Hinweise,
**keine Abbildungen**, `source = edvance_k10_sinus`. AFB je Knoten 2× I, 3× II, 1× III.

## Ergebnis der Kette

- Charge: 30 Aufgaben, keine Ablehnung (Kollisionen, Rundungsgrenzen, Lösungsweg, Slugs geprüft).
- Fehlbilder (Anzahl Aufgaben): `quadrant_vorzeichen` 9, `bogenmass_modus` 9, `amplitude_verwechselt` 8,
  `periode_falsch` 8, `grad_bogen_faktor_falsch` 6, `pi_vergessen` 6, `falsche_groesse_beantwortet` 4,
  `kreisanteil_falsch` 3; je 1: `betrag_fehler`, `einheit_uebersprungen`, `koordinaten_vertauscht`,
  `multipliziert_statt_dividiert`, `wurzel_vergessen`, `zu_frueh_gerundet`. Die vier neuen Slugs des
  Themas stehen je in mindestens sechs Aufgaben (Mindestzahl 3).
- `k10-rest-minuscheck.mjs`: keine mehrdeutigen Ausdrücke (negative Werte als `(0-…)`).
- Noch nicht gelaufen (nicht Teil dieses Schritts): `vorlauf-build.mjs` (Migration, Sondierrang),
  verify-prefill, Wegwerf-DB, Prüfskript, Blind-Löser.

## Entscheidungen

- **Winkeleinheit in jeder Aufgabe**: Gradmaß mit `°` und „im Gradmaß", Bogenmaß ausdrücklich
  („x im Bogenmaß", „das Argument des Sinus ist im Bogenmaß"). Rundung in jeder Aufgabe
  („Gib den exakten Wert an." / „Runde auf eine/zwei Stellen nach dem Komma." / „Gib eine ganze Zahl an.").
- **Sinuswerte an π-Stellen als Gradmaß-Ausdruck** (`S(210)` für sin(7π/6), `S(60)` für sin(π/3)),
  damit kein π im Rechenweg steht. `pi: true` mit `SATZ_PI` nur bei acht Aufgaben, in denen mit π
  gerechnet und gerundet wird (Grad → Bogenmaß als Dezimalzahl, Bogen → Grad, Periode als Dezimalzahl,
  b = 2π : p). Bei bogenmass-02, -05, -06 und periodisch-03, -05, -06 (b) fallen beide Rechenwege auf denselben Wert.
- **k · π**: „Gib k exakt an, als ganze Zahl oder als Bruch (zum Beispiel 2/3)." mit `bruch: true`.
  Abbrechende k (1/2, 3/2, 4/5) gelten als Bruch und als Dezimalzahl; **1/3 (bogenmass-01) nur als Bruch**
  (0,33 ist nicht exakt und wird nicht angenommen – der Text verlangt „exakt").
- **Exakte Werte nur, wo exakt**: sin 150° = 0,5, sin(7π/6) = −0,5, x = 0,8 aus 1 − 0,6²; alle übrigen
  Sinus-/Kosinuswerte gerundet.
- **`bogenmass_modus`** (aus trigo mitbenutzt): Taschenrechner im falschen Modus, in beide Richtungen
  (Grad-Aufgabe im RAD-Modus, Bogenmaß-Stelle im DEG-Modus). Bei „exakt"-Aufgaben trägt der falsche Wert
  eine eigene Rundung auf zwei Stellen (so tippt ein Kind den Taschenrechnerwert ab).
- **`quadrant_vorzeichen`** sowohl beim Einzelwert (Minus fehlt/zu viel) als auch bei der Rückrichtung
  (zweiter Winkel bzw. zweite Stelle im falschen Viertel, dort hat der Sinus das andere Vorzeichen).
- **`periode_falsch`** in drei Formen: b als Periode, 2π · b statt 2π : b, und in der Rückrichtung
  b = p : 2π statt 2π : p (der umgekehrte Quotient; der Klartext nennt ihn seit der Nachbearbeitung ausdrücklich).
- **`amplitude_verwechselt`** nur als Verdoppeln (Abstand Hoch–Tief) und Halbieren. „Amplitude als b angegeben"
  (periodisch-05) trägt `falsche_groesse_beantwortet` (Nachbearbeitung im Hauptlauf).
- **Bestands-Slugs nur bei wörtlicher Bedeutung**: `koordinaten_vertauscht` (sin/cos als x/y vertauscht),
  `wurzel_vergessen` (x² statt x), `betrag_fehler` (größter Wert −4 statt 4 bei a = −4),
  `einheit_uebersprungen` (Grad 90 statt k = 1/2 angegeben), `multipliziert_statt_dividiert`
  (Bogen · Radius statt Bogen : Radius), `falsche_groesse_beantwortet` (Tief- statt Hochpunkt,
  Amplitude statt Mittellinie, Halbperiode als Periode), `kreisanteil_falsch` (π als 360° bzw.
  Anteil umgedreht), `zu_frueh_gerundet` (sin-Wert auf 0,8 gerundet).
- **Keine Abbildungen**: Hoch-/Tiefpunkte, Nullstellen und Perioden werden aus dem Term oder aus im
  Text genannten Punkten bestimmt. Sachkontexte: Karussell, Riesenrad, Gezeiten (zweimal), Tageslänge,
  Schaukel; keine Personen, keine Marken.

## Aufgaben

| source_ref | Knoten | AFB | Typ | Begründung | Antwort | Fehlbilder | π-Regel |
|---|---|---|---|---|---|---|---|
| `sinus-einheitskreis-01` | einheitskreis | I | NUM | Reproduzieren: Sinuswert im zweiten Viertel über den Bezugswinkel 30° bestimmen. | 0,5 | `quadrant_vorzeichen`, `bogenmass_modus` | – |
| `sinus-einheitskreis-02` | einheitskreis | I | NUM | Reproduzieren: Kosinuswert im dritten Viertel mit dem Taschenrechner bestimmen und runden. | -0,94 | `quadrant_vorzeichen`, `bogenmass_modus` | – |
| `sinus-einheitskreis-03` | einheitskreis | II | MP | Anwenden: Koordinaten (cos α \| sin α) im dritten Viertel mit beiden Vorzeichen angeben. | -0,50 / -0,87 | `quadrant_vorzeichen`, `koordinaten_vertauscht` | – |
| `sinus-einheitskreis-04` | einheitskreis | II | NUM | Anwenden: Winkel aus einem negativen Kosinuswert mit cos⁻¹ bestimmen und das Viertel prüfen. | 126,9 ° | `quadrant_vorzeichen`, `bogenmass_modus` | – |
| `sinus-einheitskreis-05` | einheitskreis | II | NUM | Anwenden in der Rückrichtung: den zweiten Winkel mit gleichem Sinuswert über die Symmetrie zur y-Achse finden. | 130 ° | `quadrant_vorzeichen` | – |
| `sinus-einheitskreis-06` | einheitskreis | III | MP | Problemlösen: aus der y-Koordinate über x² + y² = 1 die x-Koordinate und über sin⁻¹ den Winkel im vierten Viertel bestimmen. | 0,80 / 323,13 | `quadrant_vorzeichen`, `wurzel_vergessen`, `bogenmass_modus` | – |
| `sinus-bogenmass-01` | bogenmass | I | NUM | Reproduzieren: Gradmaß über 180° = π in einen Faktor von π umrechnen. | 1/3 | `grad_bogen_faktor_falsch`, `kreisanteil_falsch` | – |
| `sinus-bogenmass-02` | bogenmass | I | NUM | Reproduzieren: Gradmaß mit dem Faktor π/180 ins Bogenmaß umrechnen und runden. | 0,87 (beide Wege) | `grad_bogen_faktor_falsch`, `pi_vergessen` | ja |
| `sinus-bogenmass-03` | bogenmass | II | NUM | Anwenden: Rückrichtung vom Bogenmaß ins Gradmaß ohne π im Ausgangswert. | 229,2 (π-Taste) / 229,3 (3,14) ° | `pi_vergessen`, `grad_bogen_faktor_falsch` | ja |
| `sinus-bogenmass-04` | bogenmass | II | NUM | Anwenden: Bogenmaß mit π im Bruch ins Gradmaß umrechnen, π kürzt sich. | 225 ° | `kreisanteil_falsch`, `grad_bogen_faktor_falsch` | – |
| `sinus-bogenmass-05` | bogenmass | II | NUM | Anwenden im Sachkontext: Am Kreis mit Radius 1 ist die Bogenlänge gleich dem Bogenmaß des Winkels. | 2,27 (beide Wege) m | `grad_bogen_faktor_falsch`, `kreisanteil_falsch`, `pi_vergessen` | ja |
| `sinus-bogenmass-06` | bogenmass | III | NUM | Problemlösen: Bogenmaß als Bogenlänge durch Radius bilden, dann ins Gradmaß umrechnen. | 95,5 (beide Wege) ° | `multipliziert_statt_dividiert`, `grad_bogen_faktor_falsch` | ja |
| `sinus-graph-01` | graph | I | NUM | Reproduzieren: Funktionswert an einer Bogenmaß-Stelle über den Einheitskreis bestimmen. | -0,5 | `quadrant_vorzeichen`, `bogenmass_modus` | – |
| `sinus-graph-02` | graph | I | NUM | Reproduzieren: Funktionswert an einer Bogenmaß-Stelle im ersten Viertel bestimmen und runden. | 0,87 | `bogenmass_modus` | – |
| `sinus-graph-03` | graph | II | MP | Anwenden: Lage von Hoch- und Tiefpunkt des Graphen aus dem Einheitskreis ins Bogenmaß übertragen. | 0,5 / 1,5 | `einheit_uebersprungen`, `falsche_groesse_beantwortet` | – |
| `sinus-graph-04` | graph | II | NUM | Anwenden: Bogenmaß-Stelle ohne π, Lage im vierten Viertel erkennen, negatives Ergebnis. | -0,96 | `bogenmass_modus`, `quadrant_vorzeichen` | – |
| `sinus-graph-05` | graph | II | NUM | Anwenden in der Rückrichtung: Symmetrie des Graphen zur Geraden x = π/2 nutzen. | 0,8 | `quadrant_vorzeichen` | – |
| `sinus-graph-06` | graph | III | NUM | Problemlösen: Nullstellen als Vielfache von π erkennen und im Intervall abzählen, Randstelle 0 mitzählen. | 7 | `bogenmass_modus`, `pi_vergessen` | – |
| `sinus-parameter-01` | parameter | I | NUM | Reproduzieren: Amplitude als Faktor a vor dem Sinus ablesen. | 3 | `amplitude_verwechselt` | – |
| `sinus-parameter-02` | parameter | I | NUM | Reproduzieren: Periode mit p = 2π : b bestimmen. | 0,5 | `periode_falsch` | – |
| `sinus-parameter-03` | parameter | II | NUM | Anwenden: Periode bei b < 1 berechnen (Streckung) und als Dezimalzahl runden. | 12,57 (π-Taste) / 12,56 (3,14) | `pi_vergessen`, `periode_falsch` | ja |
| `sinus-parameter-04` | parameter | II | MP | Anwenden: negativer Faktor a – größter Funktionswert ist \|a\|; Periode als Vielfaches von π. | 4 / 1 | `amplitude_verwechselt`, `betrag_fehler`, `periode_falsch` | – |
| `sinus-parameter-05` | parameter | II | MP | Anwenden in der Rückrichtung: a aus der Amplitude, b aus b = 2π : p. | 1,5 / 2 | `amplitude_verwechselt`, `periode_falsch` | – |
| `sinus-parameter-06` | parameter | III | MP | Problemlösen: aus benachbartem Hoch- und Tiefpunkt Amplitude und halbe Periode gewinnen, dann b bestimmen. | 2,5 / 4 | `amplitude_verwechselt`, `falsche_groesse_beantwortet`, `periode_falsch` | – |
| `sinus-periodisch-01` | periodisch | I | NUM | Reproduzieren im Sachkontext: Höchstwert als Mittellinie plus Amplitude ablesen. | 38 m | `falsche_groesse_beantwortet`, `amplitude_verwechselt` | – |
| `sinus-periodisch-02` | periodisch | I | NUM | Reproduzieren im Sachkontext: Abstand von Höchst- und Tiefstwert als doppelte Amplitude. | 3,6 m | `amplitude_verwechselt` | – |
| `sinus-periodisch-03` | periodisch | II | NUM | Anwenden im Sachkontext: Umlaufzeit als Periode 2π : b deuten. | 31,4 (beide Wege) min | `pi_vergessen`, `periode_falsch` | ja |
| `sinus-periodisch-04` | periodisch | II | NUM | Anwenden im Sachkontext: Zeitpunkt in einen Sinusterm mit Mittellinie einsetzen, Taschenrechner im Bogenmaß. | 15,5 h | `bogenmass_modus`, `zu_frueh_gerundet` | – |
| `sinus-periodisch-05` | periodisch | II | NUM | Anwenden im Sachkontext, Rückrichtung: aus der Periode den Faktor b = 2π : p bestimmen. | 2,09 (beide Wege) | `periode_falsch`, `falsche_groesse_beantwortet` | ja |
| `sinus-periodisch-06` | periodisch | III | MP | Problemlösen: Amplitude, Mittellinie und Periode aus Hoch- und Niedrigwasser selbst bestimmen, b aus der Periode. | 2,5 / 4 / 0,51 | `amplitude_verwechselt`, `falsche_groesse_beantwortet`, `periode_falsch` | ja |

MP-Antworten in Teil-Reihenfolge; bei π-Aufgaben mit Teilen gilt der π-Tasten-Wert, der 3,14-Wert ist
ebenfalls hinterlegt. Rang: nach `vorlauf-build.mjs` (je Knoten Rang 1 und 2 aus verschiedenen Profilen).

## Offene Punkte / Befunde

- **Ohne Graph-Abbildung nicht prüfbar**: Ablesen von Amplitude, Periode, Nullstellen oder
  Hoch-/Tiefpunkten am Graphen sowie „Term zum Graphen finden" (Fkt-13 „Sinusfunktion als
  Verallgemeinerung" nur über Term und Einheitskreis). Ebenso der Einheitskreis als Bild (Punkt
  einzeichnen). Ersatz: Punkte und Werte im Text (parameter-06 mit H und T, graph-03/-05/-06).
  Generator `koordinatensystem` müsste dafür `sinus {a, b, d}` kennen (Befund aus phase1.md).
- **Phasenverschiebung (sin(x − c)) und Kosinusfunktion** nicht abgefragt (nicht im Auftrag; KLP nennt
  nur a und b). Mittellinie + d nur in periodisch-01/-04/-06, jeweils im Text benannt.
- **bogenmass-01**: Dezimaleingabe 0,33 wird nicht angenommen (nur 1/3); der Text verlangt exakt.
- **Eigenrundung von Fehlwerten bei „exakt"-Aufgaben** (einheitskreis-01, bogenmass-04, graph-01,
  parameter-05): der Fehlwert greift nur, wenn das Kind auf zwei Stellen rundet.
- **graph-06**: Die Intervallgrenzen gehören laut Text dazu; wer x = 0 nicht mitzählt (6), hat kein
  Fehlbild (kein Bestands-Slug passt wörtlich).
- **periodisch-04**: Der Satz „Rechne ohne Zwischenrunden." ist eine Arbeitsanweisung (wie die
  Rundungsangabe), kein Hinweis.
- Voraussetzungen `geo_koordinaten` und `geo_kreis_sektor` sind selbst noch Entwurf (phase1.md c).
- Freigabe durch Lena steht aus (`draft`).
