# K9-Rest – Thema `koerper` (Prisma, Zylinder, Pyramide, Kegel, Kugel)

Stand 03.10.2026 · Branch `feat/k9-rest` · Quelle `tools/k9-koerper-charge.mjs` → `docs/prefill/k9-koerper.json` →
`supabase/migrations/20261003105906_aufgaben_k9_koerper.sql` (vorlauf-build). 30 Aufgaben, je sechs zu
`geo_koerper_prisma`, `geo_koerper_zylinder`, `geo_koerper_pyramide`, `geo_koerper_kegel`, `geo_koerper_kugel`
(KLP Geo-5, Zweite Stufe). Alle `NUMERIC`, `needs_image = false`, keine Hinweise, `source = edvance_k9_koerper`,
Geometrie & Messen, `competency_content = geometrie`, Stoff 9. Einspielen nach `20261003105858_substrat_k9_koerper.sql`.

Alle Körper stehen als Text mit allen Maßen da. Der einzige zusammengesetzte Körper (`kugel-06`) ist eine Halbkugel auf
einem Zylinder mit gleichem Durchmesser.

## Entscheidungen

- **Nur NUMERIC.** Jede Aufgabe fragt genau eine Größe (Volumen, Oberfläche, Mantel, Länge, Liter). MULTI_PART war
  nicht nötig. Die Einheit steht im Feld `unit`.
- **π nur, wo ein Kreis vorkommt.** Zylinder, Kegel (außer `kegel-02`) und Kugel haben `pi: true` und nennen den Satz
  „Rechne mit der π-Taste oder mit π ≈ 3,14." plus die Rundung. Beide Ergebnisse stehen als Varianten in
  `correct_answers` und `acceptance.equivalents`. `kegel-02` fragt nur nach der Mantellinie (Pythagoras), dort kommt
  kein π vor. Prisma und Pyramide sind π-frei.
- **Rundung je nach Ergebnis.** Ganzzahlige oder abbrechende Ergebnisse ohne Wurzel: „Gib das Ergebnis genau an, ohne
  zu runden." (`exakt`). Aufgaben, bei denen ein typischer Fehlwert eine nicht aufgehende Wurzel ergibt
  (`pyramide-06`, `kegel-02`): „Runde, falls nötig, auf zwei Stellen". Die richtige Antwort geht dort
  auf (8, 13); `8` und `8,00` werden angenommen (Komma oder Punkt). Sachaufgaben in Litern/Millilitern runden
  auf ganze Einheiten (`zylinder-05`, `kegel-05`) oder auf eine Stelle (`zylinder-06`, `kugel-05`), weil
  Hundertstel-Liter dort keinen Sinn haben. Bei vier π-Aufgaben fallen dadurch beide Rechenwege auf denselben Wert.
- **Zahlen bewusst gewählt.** Pythagoras-Tripel (3-4-5, 6-8-10, 5-12-13, 8-15-17, 6-8-10 im Kegel), damit Höhen
  und Mantellinie ohne Rundung aufgehen und keine Zwischenrundung nötig ist. Werte an einer Rundungsgrenze wurden
  vermieden (z. B. ist 3,14 · 26,25 = 82,425 genau eine Grenze; deshalb hat `zylinder-03` r = 1,5 m und h = 3,2 m).
  Die Bibliothek prüft das.
- **`falsche_hoehe` nur, wenn beide Höhen dastehen oder eine abgeleitet wird.** `pyramide-02` und `pyramide-05` nennen
  Körperhöhe und h_s (beide passen zusammen: 3-4-5). `pyramide-04` nennt zwei verschiedene Seitenhöhen (rechteckige
  Grundfläche 10 cm × 4 cm, h_s 10 cm und 11 cm; stimmig, h² = 96 cm²); der Fehler ist das Vertauschen. `kegel-04/06`
  nennen nur die Körperhöhe bzw. nur s; der Fehler ist dann, die gegebene Höhe direkt zu verwenden.
- **Pythagoras nur im Kegel-Knoten.** Nur `geo_koerper_kegel` hat in graph.json eine Kante auf
  `geo_pythagoras_hypotenuse`. Die Pyramiden-Aufgaben geben deshalb jede Seitenhöhe direkt an.
- **Bestands-Slugs außerhalb der vorgeschlagenen Liste:** `falsche_groesse_beantwortet` (nur Grundfläche, nur Mantel,
  Boden mitgezählt, nur der Zylinder; 8 Aufgaben), `mal_exponent` (r² als 2r, r³ als 3r, a² als 2a; `zylinder-03`,
  `kugel-03`, `pyramide-06`) und `multipliziert_statt_dividiert` (`prisma-04`). Alle drei passen wörtlich zur
  Bestandsbedeutung; phase1 d) erlaubt das.
- **`liter_kubik_falsch`** steht für eine falsche Beziehung zwischen Liter und Kubikeinheit: Kubikzentimeter als Liter
  (`prisma-05`), Kubikmeter als Liter (`zylinder-05`), 1 l = 100 cm³ (`zylinder-06`, `kugel-05`). Gemischte Einheiten
  ohne Umrechnung sind `einheit_uebersprungen`.
- **`volumen_statt_oberflaeche` in `prisma-06`:** die gegebene Oberfläche wird wie ein Volumen durch die Grundfläche
  geteilt (288 : 24 = 12). Das ist die Volumenformel an der Stelle der Oberflächenformel.
- Neues Fehlbild `drittel_vergessen` in 6 Aufgaben (Pflicht ≥ 3). Mitbenutzt: `wurzel_vergessen` (3),
  `hypotenuse_verwechselt` (3, nur Kegel).

## Die Aufgaben

Zeitregel wie Kreis: AFB I 45 s, II 60 s, III 90 s, +30 s bei Sachkontext. Rang aus der vorlauf-build-Ausgabe.

| source_ref | Knoten | AFB | Begründung | Antwort (π / 3,14) | Fehlbilder | Rang |
|---|---|---|---|---|---|---|
| `koerper-prisma-01` | prisma | I | Reproduzieren: Dreiecksfläche als Grundfläche, dann V = G · h. | 120 cm³ | `halbieren_vergessen`, `falsche_groesse_beantwortet` | – |
| `koerper-prisma-02` | prisma | I | Reproduzieren: O = 2 · G + Mantel mit gegebenen Dreiecksseiten. | 108 cm² | `mal_zwei_vergessen`, `halbieren_vergessen`, `volumen_statt_oberflaeche` | 1 |
| `koerper-prisma-03` | prisma | II | Anwenden: Grundfläche ist ein Trapez, erst die Fläche bestimmen, dann V = G · h. | 312 cm³ | `halbieren_vergessen`, `falsche_groesse_beantwortet` | – |
| `koerper-prisma-04` | prisma | II | Anwenden: V = G · h nach h umstellen, Grundfläche erst aus dem Dreieck bestimmen. | 9 cm | `halbieren_vergessen`, `multipliziert_statt_dividiert` | – |
| `koerper-prisma-05` | prisma | II | Anwenden im Sachkontext: Trog als Dreiecksprisma erkennen, Einheiten angleichen, in Liter umrechnen. | 240 l | `halbieren_vergessen`, `liter_kubik_falsch`, `einheit_uebersprungen` | 2 |
| `koerper-prisma-06` | prisma | III | Problemlösen: Rückrichtung über die Oberfläche – Grundflächen abziehen, durch den Umfang teilen. | 10 cm | `mal_zwei_vergessen`, `halbieren_vergessen`, `volumen_statt_oberflaeche` | – |
| `koerper-zylinder-01` | zylinder | I | Reproduzieren: Volumenformel mit gegebenem Radius und gegebener Höhe. | 282,74 / 282,60 cm³ | `radius_durchmesser_verwechselt`, `pi_vergessen`, `oberflaeche_statt_volumen` | – |
| `koerper-zylinder-02` | zylinder | I | Reproduzieren: Radius aus dem Durchmesser, dann O = 2 · G + M. | 226,19 / 226,08 cm² | `radius_durchmesser_verwechselt`, `mal_zwei_vergessen`, `volumen_statt_oberflaeche` | 2 |
| `koerper-zylinder-03` | zylinder | II | Anwenden: Quadrat einer Dezimalzahl in der Volumenformel. | 22,62 / 22,61 m³ | `mal_exponent`, `radius_durchmesser_verwechselt`, `pi_vergessen`, `oberflaeche_statt_volumen` | 1 |
| `koerper-zylinder-04` | zylinder | II | Anwenden: Oberflächenformel, vorher Zentimeter in Meter umrechnen. | 3,27 / 3,27 m² | `einheit_uebersprungen`, `mal_zwei_vergessen`, `radius_durchmesser_verwechselt` | – |
| `koerper-zylinder-05` | zylinder | II | Anwenden im Sachkontext: Durchmesser halbieren, Volumen in m³, in Liter umrechnen. | 1696 / 1696 l | `radius_durchmesser_verwechselt`, `liter_kubik_falsch`, `pi_vergessen` | – |
| `koerper-zylinder-06` | zylinder | III | Problemlösen (Sachkontext): Rückrichtung – Liter in cm³, Volumenformel nach h umstellen. | 12,7 / 12,7 cm | `radius_durchmesser_verwechselt`, `liter_kubik_falsch`, `pi_vergessen` | – |
| `koerper-pyramide-01` | pyramide | I | Reproduzieren: V = ⅓ · G · h mit quadratischer Grundfläche. | 120 cm³ | `drittel_vergessen`, `falsche_groesse_beantwortet` | – |
| `koerper-pyramide-02` | pyramide | I | Reproduzieren: Grundfläche plus vier Dreiecke; die passende Höhe (h_s) auswählen. | 144 cm² | `falsche_hoehe`, `halbieren_vergessen`, `volumen_statt_oberflaeche` | – |
| `koerper-pyramide-03` | pyramide | II | Anwenden: rechteckige Grundfläche mit Dezimalzahlen, dann V = ⅓ · G · h. | 24 m³ | `drittel_vergessen`, `falsche_groesse_beantwortet` | – |
| `koerper-pyramide-04` | pyramide | II | Anwenden: zwei Sorten Seitendreiecke mit verschiedenen Seitenhöhen richtig zuordnen, dann Grundfläche plus Mantel. | 184 cm² | `falsche_hoehe`, `halbieren_vergessen`, `falsche_groesse_beantwortet` | – |
| `koerper-pyramide-05` | pyramide | II | Anwenden im Sachkontext: Dachfläche als vier Seitendreiecke, ohne Boden, mit der Seitenhöhe. | 60 m² | `halbieren_vergessen`, `falsche_hoehe`, `falsche_groesse_beantwortet` | 1 |
| `koerper-pyramide-06` | pyramide | III | Problemlösen: Rückrichtung in zwei Schritten – Grundfläche aus V = ⅓ · G · h, daraus die Seitenlänge. | 8 cm | `drittel_vergessen`, `wurzel_vergessen`, `mal_exponent` | 2 |
| `koerper-kegel-01` | kegel | I | Reproduzieren: V = ⅓ · π · r² · h mit gegebenem Radius und Höhe. | 75,40 / 75,36 cm³ | `drittel_vergessen`, `pi_vergessen`, `radius_durchmesser_verwechselt` | 1 |
| `koerper-kegel-02` | kegel | I | Reproduzieren: Mantellinie per Pythagoras, s = √(r² + h²) (ohne π). | 13 cm | `wurzel_vergessen`, `hypotenuse_verwechselt` | – |
| `koerper-kegel-03` | kegel | II | Anwenden: Radius aus dem Durchmesser, Grundfläche und Mantel M = π · r · s addieren. | 301,59 / 301,44 cm² | `radius_durchmesser_verwechselt`, `falsche_groesse_beantwortet`, `pi_vergessen` | – |
| `koerper-kegel-04` | kegel | II | Anwenden: erst die Mantellinie per Pythagoras, dann Grundfläche plus Mantel. | 452,39 / 452,16 cm² | `falsche_hoehe`, `wurzel_vergessen`, `hypotenuse_verwechselt` | 2 |
| `koerper-kegel-05` | kegel | II | Anwenden im Sachkontext: Trichter als Kegel, Durchmesser halbieren, cm³ als ml. | 113 / 113 ml | `drittel_vergessen`, `radius_durchmesser_verwechselt`, `pi_vergessen` | – |
| `koerper-kegel-06` | kegel | III | Problemlösen: fehlende Höhe per Pythagoras aus s und r, dann das Volumen. | 1005,31 / 1004,80 cm³ | `hypotenuse_verwechselt`, `falsche_hoehe`, `drittel_vergessen` | – |
| `koerper-kugel-01` | kugel | I | Reproduzieren: V = 4/3 · π · r³ mit gegebenem Radius. | 904,78 / 904,32 cm³ | `oberflaeche_statt_volumen`, `radius_durchmesser_verwechselt`, `pi_vergessen` | – |
| `koerper-kugel-02` | kugel | I | Reproduzieren: Radius aus dem Durchmesser, dann O = 4 · π · r². | 314,16 / 314,00 cm² | `radius_durchmesser_verwechselt`, `volumen_statt_oberflaeche`, `pi_vergessen` | – |
| `koerper-kugel-03` | kugel | II | Anwenden: dritte Potenz einer Dezimalzahl in der Volumenformel. | 65,45 / 65,42 m³ | `mal_exponent`, `oberflaeche_statt_volumen`, `radius_durchmesser_verwechselt` | – |
| `koerper-kugel-04` | kugel | II | Anwenden: Oberflächenformel plus Umrechnung von Zentimetern in Meter. | 2,01 / 2,01 m² | `einheit_uebersprungen`, `volumen_statt_oberflaeche`, `radius_durchmesser_verwechselt` | – |
| `koerper-kugel-05` | kugel | II | Anwenden im Sachkontext: Durchmesser halbieren, in Dezimeter umrechnen, Volumen als Liter. | 33,5 / 33,5 l | `radius_durchmesser_verwechselt`, `oberflaeche_statt_volumen`, `liter_kubik_falsch`, `pi_vergessen` | 2 |
| `koerper-kugel-06` | kugel | III | Problemlösen: zusammengesetzten Körper zerlegen, Halbkugel als halbe Kugel erkennen, Volumen addieren. | 339,29 / 339,12 cm³ | `halbieren_vergessen`, `radius_durchmesser_verwechselt`, `falsche_groesse_beantwortet`, `pi_vergessen` | 1 |

## Prüfung

- `node tools/k9-koerper-charge.mjs`: 30 Aufgaben, keine Ablehnung (Rundungsgrenzen, Kollisionen, Slugs, 6 je Knoten).
- `vorlauf-build`: Rang 1 und 2 je Knoten aus verschiedenen Profilen (siehe Tabelle).
- `verify-tasks`: Charge-Fehler **0**, Bestands-Befunde 0, Überschreibungen 0 (`docs/prefill/k9-koerper-verifikation.md`).
- Wegwerf-DB `k9rest_koerper` (8 Substrate + Aufgaben Körper): **idempotent** (Zeilenzahlen nach Lauf 1 = Lauf 2).
- `node tools/k9-rest-minuscheck.mjs docs/prefill/k9-koerper.json`: keine mehrdeutigen Ausdrücke.
- `supabase/checks/k9_koerper_aufgaben.PRUEFUNG.sql` mit `lokal=true`: **16 von 16 ok = t**; Substrat-Prüfung 6 von 6.
- Jede Aufgabe von Hand nachgerechnet (beide π-Wege), Lösungsweg nennt das Ergebnis, alle Figuren geometrisch stimmig
  (Pyramiden mit h und h_s, Kegel mit r, h, s erfüllen den Satz des Pythagoras).

## Offene Punkte / Befunde

- **Voraussetzungen noch Entwürfe:** `geo_kreis_flaeche`/`_umfang` (Kante für Zylinder, Kugel) und
  `geo_pythagoras_hypotenuse` (Kegel) sind selbst nur `draft`. Ein Abstieg aus Zylinder/Kegel/Kugel trägt erst nach
  Lenas Freigabe dieser Läufe.
- **Erledigt – `pyramide-04` ohne Pythagoras:** Die erste Fassung berechnete h_s per Pythagoras, obwohl
  `geo_koerper_pyramide` keine Kante auf `geo_pythagoras_hypotenuse` hat. Hub-Entscheidung: graph.json bleibt, denn
  Pythagoras gehört zum Kegel-Knoten, der die Kante hat. `pyramide-04` ist jetzt eine Oberfläche mit rechteckiger
  Grundfläche und zwei direkt gegebenen Seitenhöhen (184 cm²). Rang 1/2 der Pyramide unverändert (`pyramide-05`, `-06`).
- **Zweite Kanonik-Schreibweise:** Bei „Runde, falls nötig, auf zwei Stellen" ist der kanonische Wert `8,00` bzw.
  `13,00`; `8` usw. stehen als Variante. Anzeige der Musterlösung im Coach-Bereich zeigt damit die Endnullen.
- Keine Werkzeugänderung nötig, kein Werkzeug hat blockiert.
