# K9-Rest – Thema pythagoras (Satz des Pythagoras)

Stand 03.10.2026 · Branch `feat/k9-rest` · KLP G9 NRW, Zweite Stufe, Geo-1/Geo-2.
Quelle `tools/k9-pythagoras-charge.mjs` → `docs/prefill/k9-pythagoras.json` →
`supabase/migrations/20261003105905_aufgaben_k9_pythagoras.sql` (vorlauf-build),
Prüfskript `supabase/checks/k9_pythagoras_aufgaben.PRUEFUNG.sql`.

30 Aufgaben, je sechs zu `geo_pythagoras_hypotenuse`, `_kathete`, `_umkehrung`, `_abstand`,
`_anwendung`. Alle `NUMERIC`, `status = 'draft'`, `curriculum_grade = 9`, „Geometrie & Messen",
`competency_content = geometrie`, keine Hinweise, `source = edvance_k9_pythagoras`. Drei Aufgaben
mit Abbildung (Generator `koordinatensystem`, nur Punkte).

## Ergebnis der Kette

- Charge: 30 Aufgaben; `wurzel_vergessen` in 23, `hypotenuse_verwechselt` in 20 Aufgaben (Mindestzahl 3).
- verify-prefill: **Charge-Fehler 0**, Bestands-Befunde 0, Überschreibungen 0.
- `k9-rest-minuscheck.mjs`: keine mehrdeutigen Ausdrücke (kein vorangestelltes Minus vor einer Potenz;
  negative Koordinaten als `(0-2)` geschrieben).
- Wegwerf-DB (alle acht Substrate + Aufgaben-Migration): **IDEMPOTENT ok**; Prüfskript **16 von 16 t**.
- Figuren: alle drei mit `zeichne(params, 'hell')` erzeugt (kein Punkt außerhalb des Fensters).

## Entscheidungen

- **Jede Zahl über Ausdrücke** (`W(5^2+7^2)`), richtige und falsche Werte; die Bibliothek prüft
  Rundungsgrenzen und Kollisionen. Falsche Werte, die bei einer „exakt"-Aufgabe nicht abbrechen
  (z. B. √28 bei vertauschter Hypotenuse), haben eine eigene Rundung auf zwei Stellen – so tippt
  ein Kind den Wert vom Taschenrechner ab.
- **Rundung im Text**: „Gib das Ergebnis exakt an." nur bei Quadratzahlen unter der Wurzel, sonst
  „Runde auf eine/zwei Stellen nach dem Komma." bzw. „auf ganze Meter/Zentimeter".
- **Kathete**: Jede Kathete-Aufgabe nennt das Dreieck mit „rechtem Winkel bei C" und benennt die
  Hypotenuse c ausdrücklich, damit die Rolle der Seiten eindeutig ist.
- **Umkehrung in drei Formen**: dritte Seite für einen rechten Winkel (01, 05), Auswahl aus vier
  Dreiecken (02), Abstand zur Rechtwinkligkeit als `a² + b² − c²` (03) bzw. als fehlende Länge
  (04, 06). Grund: Die Eingabe kennt nur Zahlen; „ja/nein" ist nicht eingebbar.
- **Auswahl-Aufgabe mit vier statt drei Dreiecken** (`pyth-umkehrung-02`): Ein Fehler „mit der
  falschen Seite als Hypotenuse geprüft" kann bei einem nicht rechtwinkligen Dreieck nie eine
  Gleichheit ergeben (dazu müsste eine kürzere Seite die längste sein) und taugt deshalb nicht als
  Fehlbild einer Nummer. Die Ablenker tragen stattdessen `zu_frueh_gerundet` (5; 7; 8,6 – 8,6² =
  73,96 ≈ 74) und `mal_exponent` (2; 2,5; 3 – 2,5² als 5 gibt 4 + 5 = 9 = 3²).
  `hypotenuse_verwechselt` steht in der Umkehrung bei 01, 03 (falsche Seite als c), 05.
- **Abbildungen**: nur bei `_abstand` 02, 04, 05; Koordinaten stehen dort nicht im Text, das Fenster
  ist so gewählt, dass alle Punkte auf Gitterpunkten liegen und jede ganze Zahl beschriftet ist.
  alt_text ohne Ziffern. Keine Strecken (Generator kann keine).
- **`vorzeichen_ignoriert`** nur dort, wo Punkte über eine Achse hinweg liegen (03–06): Beträge der
  Koordinaten voneinander abgezogen (−2 und 4 → 2 statt 6).
- **`halbieren_vergessen`** nur beim Flächeninhalt eines Dreiecks (kathete-04, anwendung-04) –
  bei der Höhe im gleichseitigen Dreieck ergäbe „Grundseite nicht halbiert" √(a² − a²) = 0, das
  ist kein glaubwürdiger Schülerwert.
- **`einheit_uebersprungen`** (Bestand, wie beim Kreis) bei hypotenuse-04 (cm/m gemischt) und
  umkehrung-06 (Ergebnis in Metern statt Zentimetern).
- Keine Personen mit Namen, keine Marken; Sachkontexte: Boot, Feld, Drachen, Mast, Gartenhaus,
  Latten, Karte mit Hafen und Leuchtturm, Leiter.

## Aufgaben

| source_ref | Knoten | AFB | Begründung | Antwort | Fehlbilder | Rang | Abbildung |
|---|---|---|---|---|---|---|---|
| `pyth-hypotenuse-01` | hypotenuse | I | Reproduzieren: Satz des Pythagoras mit zwei gegebenen Katheten, Ergebnis ganzzahlig. | 10 cm | `wurzel_gliedweise`, `wurzel_vergessen`, `hypotenuse_verwechselt` | – | – |
| `pyth-hypotenuse-02` | hypotenuse | I | Reproduzieren: Satz des Pythagoras, Wurzel aus einer Nicht-Quadratzahl runden. | 8,60 cm | `wurzel_gliedweise`, `wurzel_vergessen`, `hypotenuse_verwechselt` | – | – |
| `pyth-hypotenuse-03` | hypotenuse | II | Anwenden: Quadrat einer Dezimalzahl und Wurzel aus einer Dezimalzahl. | 7,5 cm | `wurzel_vergessen`, `wurzel_gliedweise`, `mal_exponent`, `hypotenuse_verwechselt` | 1 | – |
| `pyth-hypotenuse-04` | hypotenuse | II | Anwenden: Einheiten angleichen, dann Satz des Pythagoras mit größeren Zahlen. | 37 cm | `wurzel_gliedweise`, `wurzel_vergessen`, `einheit_uebersprungen` | 2 | – |
| `pyth-hypotenuse-05` | hypotenuse | II | Anwenden im Sachkontext: Die Luftlinie muss als Hypotenuse eines rechtwinkligen Dreiecks erkannt werden. | 9,8 km | `wurzel_gliedweise`, `wurzel_vergessen`, `hypotenuse_verwechselt` | – | – |
| `pyth-hypotenuse-06` | hypotenuse | III | Problemlösen: Diagonale als Hypotenuse erkennen und mit dem Weg entlang zweier Seiten vergleichen. | 40 m | `hypotenuse_verwechselt`, `falsche_groesse_beantwortet` | – | – |
| `pyth-kathete-01` | kathete | I | Reproduzieren: Satz des Pythagoras nach einer Kathete umstellen, Ergebnis ganzzahlig. | 12 cm | `wurzel_gliedweise`, `wurzel_vergessen`, `hypotenuse_verwechselt` | – | – |
| `pyth-kathete-02` | kathete | I | Reproduzieren: Kathete berechnen, Wurzel aus einer Nicht-Quadratzahl runden. | 7,14 cm | `wurzel_gliedweise`, `wurzel_vergessen`, `hypotenuse_verwechselt` | – | – |
| `pyth-kathete-03` | kathete | II | Anwenden: Kathete aus Dezimalzahlen, Quadrate von Dezimalzahlen. | 6 cm | `wurzel_gliedweise`, `wurzel_vergessen`, `hypotenuse_verwechselt` | 1 | – |
| `pyth-kathete-04` | kathete | II | Anwenden: erst die fehlende Kathete, dann den Flächeninhalt des Dreiecks berechnen. | 84 cm² | `falsche_groesse_beantwortet`, `halbieren_vergessen`, `hypotenuse_verwechselt` | 2 | – |
| `pyth-kathete-05` | kathete | II | Anwenden im Sachkontext: Schnur als Hypotenuse erkennen, die Höhe ist eine Kathete. | 54,5 m | `wurzel_gliedweise`, `hypotenuse_verwechselt`, `wurzel_vergessen` | – | – |
| `pyth-kathete-06` | kathete | III | Problemlösen: rechtwinkliges Dreieck in der Situation finden, Kathete berechnen und das Reststück ergänzen. | 26 m | `wurzel_gliedweise`, `falsche_groesse_beantwortet`, `hypotenuse_verwechselt` | – | – |
| `pyth-umkehrung-01` | umkehrung | I | Reproduzieren: Länge der dritten Seite aus der Umkehrung a² + b² = c², Ergebnis ganzzahlig. | 15 cm | `wurzel_gliedweise`, `wurzel_vergessen`, `hypotenuse_verwechselt` | – | – |
| `pyth-umkehrung-02` | umkehrung | I | Reproduzieren: a² + b² = c² für vier gegebene Dreiecke prüfen. | 2 | `zu_frueh_gerundet`, `mal_exponent` | – | – |
| `pyth-umkehrung-03` | umkehrung | II | Anwenden: Summe der Kathetenquadrate mit dem Quadrat der längsten Seite vergleichen und den Unterschied angeben. | 4 cm² | `mal_exponent`, `hypotenuse_verwechselt`, `falsche_groesse_beantwortet` | – | – |
| `pyth-umkehrung-04` | umkehrung | II | Anwenden: Soll-Länge der längsten Seite aus der Umkehrung bestimmen und mit der Ist-Länge vergleichen. | 0,22 cm | `wurzel_vergessen`, `falsche_groesse_beantwortet`, `zu_frueh_gerundet` | 2 | – |
| `pyth-umkehrung-05` | umkehrung | II | Anwenden im Sachkontext: Die Umkehrung des Satzes als Prüfverfahren für einen rechten Winkel erkennen. | 2 m | `wurzel_vergessen`, `wurzel_gliedweise`, `hypotenuse_verwechselt` | 1 | – |
| `pyth-umkehrung-06` | umkehrung | III | Problemlösen: Soll-Länge über die Umkehrung bestimmen, mit der Ist-Länge vergleichen und in Zentimeter umrechnen. | 10 cm | `wurzel_vergessen`, `falsche_groesse_beantwortet`, `einheit_uebersprungen` | – | – |
| `pyth-abstand-01` | abstand | I | Reproduzieren: Koordinatendifferenzen bilden und den Satz des Pythagoras anwenden, Ergebnis ganzzahlig. | 5 | `wurzel_gliedweise`, `wurzel_vergessen` | – | – |
| `pyth-abstand-02` | abstand | I | Reproduzieren: Koordinaten im ersten Quadranten ablesen, Abstand mit dem Satz des Pythagoras, Ergebnis ganzzahlig. | 10 | `wurzel_gliedweise`, `wurzel_vergessen`, `hypotenuse_verwechselt` | 2 | ja |
| `pyth-abstand-03` | abstand | II | Anwenden: Koordinatendifferenzen über die Achsen hinweg mit Vorzeichen bilden. | 10 | `wurzel_gliedweise`, `wurzel_vergessen`, `vorzeichen_ignoriert` | – | – |
| `pyth-abstand-04` | abstand | II | Anwenden: Koordinaten in verschiedenen Quadranten ablesen, Differenzen mit Vorzeichen, Wurzel runden. | 5,83 | `wurzel_gliedweise`, `wurzel_vergessen`, `vorzeichen_ignoriert` | – | ja |
| `pyth-abstand-05` | abstand | II | Anwenden im Sachkontext: Karte als Koordinatensystem lesen, Luftlinie als Abstand zweier Punkte berechnen. | 9,2 km | `wurzel_gliedweise`, `wurzel_vergessen`, `vorzeichen_ignoriert` | – | ja |
| `pyth-abstand-06` | abstand | III | Problemlösen: Rückrichtung – aus Abstand und einer Koordinatendifferenz die andere Differenz und daraus die Koordinate bestimmen. | 6 | `wurzel_gliedweise`, `falsche_groesse_beantwortet`, `wurzel_vergessen`, `vorzeichen_ignoriert` | 1 | – |
| `pyth-anwendung-01` | anwendung | I | Reproduzieren: Diagonale als Hypotenuse im Rechteck erkennen, Ergebnis ganzzahlig. | 13 cm | `wurzel_gliedweise`, `wurzel_vergessen`, `hypotenuse_verwechselt` | – | – |
| `pyth-anwendung-02` | anwendung | I | Reproduzieren: Höhe teilt das gleichseitige Dreieck in zwei rechtwinklige Dreiecke mit halber Grundseite. | 5,20 cm | `wurzel_gliedweise`, `wurzel_vergessen`, `hypotenuse_verwechselt` | 1 | – |
| `pyth-anwendung-03` | anwendung | II | Anwenden: zweimal Satz des Pythagoras – erst Flächendiagonale der Grundfläche, dann Raumdiagonale. | 12,3 cm | `wurzel_gliedweise`, `wurzel_vergessen`, `falsche_groesse_beantwortet` | – | – |
| `pyth-anwendung-04` | anwendung | II | Anwenden: Höhe mit dem Satz des Pythagoras, dann Flächeninhalt des Dreiecks. | 27,71 cm² | `halbieren_vergessen`, `falsche_groesse_beantwortet`, `hypotenuse_verwechselt` | 2 | – |
| `pyth-anwendung-05` | anwendung | II | Anwenden im Sachkontext: Leiter als Hypotenuse, Wandhöhe als Kathete erkennen. | 4,8 m | `hypotenuse_verwechselt`, `wurzel_vergessen`, `wurzel_gliedweise` | – | – |
| `pyth-anwendung-06` | anwendung | III | Problemlösen: zwei Lagen der Leiter je mit dem Satz des Pythagoras berechnen, den Unterschied bilden und umrechnen. | 49 cm | `hypotenuse_verwechselt`, `zu_frueh_gerundet`, `falsche_groesse_beantwortet` | – | – |

Rang aus der Ausgabe von `vorlauf-build.mjs`; je Knoten Rang 1 und 2 aus verschiedenen Fehlbildprofilen.

## Offene Punkte / Befunde

- **`mal_exponent` in umkehrung-02** setzt einen inkonsequenten Fehler voraus (2,5² als 5, aber 3²
  richtig als 9). Fachlich typisch bei Dezimalzahlen, aber bei der Freigabe ansehen.
- **umkehrung-02** nennt „Die Antwort ist eine ganze Zahl" statt einer Rundungsangabe (Nummer, keine
  Größe). Plus-Schreibweise `+2` wird wie bei allen einheitenlosen Antworten akzeptiert.
- **hypotenuse-06 / anwendung-06** runden „falls nötig" auf ganze Meter/Zentimeter; bei hypotenuse-06
  ist das Ergebnis ohnehin ganzzahlig (40), die Angabe deckt nur den Fehlerwert (61) ab.
- Die Kante `geo_pythagoras_anwendung` → Trapez/Raute (K8 Flächen) fehlt weiterhin (Befund aus
  phase1.md b); die Aufgaben setzen nur Rechteck, gleichseitiges Dreieck und Quader voraus.
- Freigabe durch Lena steht aus (`draft`); `geo_koordinaten` als Voraussetzung von `_abstand` ist
  selbst noch Entwurf (phase1.md c).
