# K9-Rest – Thema wurzel (Reelle Zahlen und Quadratwurzeln)

Stand 03.10.2026 · Branch `feat/k9-rest` · KLP Ari-2/Ari-6/Ari-7 · Thema-Key `reelle_zahlen`.

30 Aufgaben, je sechs zu den fünf Knoten `zahl_wurzel_quadrat`, `_naeherung`, `_irrational`,
`_gesetze` und `_teilweise`. Quelle `tools/k9-wurzel-charge.mjs` → `docs/prefill/k9-wurzel.json` →
`supabase/migrations/20261003105901_aufgaben_k9_wurzel.sql` (vorlauf-build). Alle `draft`,
`curriculum_grade = 9`, Themengebiet „Zahl & Rechnen", `competency_content = arithmetik_algebra`,
`needs_image = false`, keine Hinweise, `source = edvance_k9_wurzel`. Zeitregel: AFB I 45 s,
II 60 s, III 90 s, +30 s bei Sachkontext.

## Ergebnis der Kette

- `node tools/k9-wurzel-charge.mjs`: 30 Aufgaben, neue Fehlbilder `faktor_ohne_wurzel` (6 Aufgaben),
  `irrational_verwechselt` (4), `wurzel_gliedweise` (3).
- `verify-tasks --prefill`: **Charge-Fehler 0**, Bestands-Befunde 0, Überschreibungen 0.
- Wegwerf-DB (alle acht Substrate + Aufgaben-Migration): **IDEMPOTENT: ok**.
- `k9_wurzel_aufgaben.PRUEFUNG.sql` (lokal): **16 von 16 ok = t**; `k9_wurzel_substrat.PRUEFUNG.sql`: 6 von 6.

## Entscheidungen

- **Antworten nur als Zahl.** Das Tablet kann kein √ eingeben. Beim teilweisen Wurzelziehen wird
  deshalb die Form vorgegeben („√72 = a · √2. Bestimme a."), in der Rückrichtung „6 · √3 = √b".
- **Rundung steht in jeder Aufgabe.** Quadratwurzeln aus Quadraten „exakt", Näherungen „auf eine
  bzw. zwei Stellen nach dem Komma", der Teppich „ganze Zentimeter, aufrunden", Anzahlen „als ganze Zahl".
- **Abschneiden als Rechnung.** Der Fehlwert „abgeschnitten statt gerundet" wird als
  W(x) − 0,5·10⁻ⁿ, gerundet auf n Stellen, gerechnet statt eingetippt. Nur Zahlen, bei denen
  Abschneiden und Runden verschieden ausfallen (√10, √30, √0,9, √11, √6).
- **Listen mit Semikolon.** In den Abzählaufgaben (irrational-01/-04/-05) trennen Semikolons die
  Zahlen, weil das Komma Dezimaltrenner ist. Periodische Zahlen ausdrücklich als
  „0,333… (Periode 3)" bzw. „0,454545… (Periode 45)".
- **`wurzel_gliedweise` im Knoten Gesetze.** Drei Aufgaben (gesetze-03, -04, -06) zeigen, dass es für
  Summen kein Wurzelgesetz gibt; gesetze-06 als Sachkontext (zwei Beete zu einem).
- **Bestands-Slugs nur bei passender Bedeutung.** `falsche_gegenoperation` (Klartext „wiederholt
  die sichtbare Rechenart") nur bei „Welche positive Zahl ergibt quadriert 225?" → 225²; bei √0,9
  wieder gestrichen, weil dort das Quadrieren nicht die sichtbare Rechenart ist.
  `faktorisierung_unvollstaendig` verworfen (Klartext meint binomische Formeln).
  `falsche_groesse_beantwortet` für „Radikand ohne Wurzel angegeben" bzw. „Näherungswert statt a".
  `klammer_vergessen` für √(9/16) als √9 / 16. `teilgekuerzt` für nicht oder nicht vollständig
  gekürzte Nenner. `abgeschnitten` bei irrational-03 für die abgeschnittene Periode (0,45 = 9/20).
- **√(9/16) mit `bruch: true`**: 3/4 und 0,75 werden beide angenommen.
- **Sachkontexte ohne Namen und Marken**: Tischplatte, eingezäunter Platz, Beet, Teppich,
  Fliesen eines Betriebs, rechteckiges Feld, Spielplatz.

## Die Aufgaben

Rang = Sondierrang aus der vorlauf-build-Ausgabe.

| source_ref | Knoten | AFB | Begründung | Antwort | Fehlbilder | Rang |
|---|---|---|---|---|---|---|
| `wurzel-quadrat-01` | quadrat | I | Wurzel aus bekannter Quadratzahl, ein Schritt („ergibt quadriert 225"). | 15 | `falsche_gegenoperation`, `wurzel_halbiert` | – |
| `wurzel-quadrat-02` | quadrat | I | √0,49, Dezimalzahl zu bekannter Quadratzahl. | 0,7 | `kommastellen_zu_viel`, `kommastellen_zu_wenig`, `wurzel_halbiert` | – |
| `wurzel-quadrat-03` | quadrat | II | √(9/16), Zähler und Nenner getrennt. | 3/4 bzw. 0,75 | `klammer_vergessen`, `wurzel_halbiert` | – |
| `wurzel-quadrat-04` | quadrat | II | √0,0016, Kommastellen müssen stimmen. | 0,04 | `kommastellen_zu_wenig`, `kommastellen_zu_viel`, `wurzel_halbiert` | 1 |
| `wurzel-quadrat-05` | quadrat | II | Sachkontext: Seite einer Tischplatte mit 2,25 m², in cm. | 150 cm | `einheit_uebersprungen`, `kommastellen_zu_viel`, `wurzel_halbiert` | 2 |
| `wurzel-quadrat-06` | quadrat | III | Sachkontext: Zaun um quadratischen Platz mit 1296 m² (Seite, dann Umfang). | 144 m | `falsche_groesse_beantwortet`, `wurzel_halbiert` | – |
| `wurzel-naeherung-01` | naeherung | I | √50 zwischen zwei aufeinanderfolgenden ganzen Zahlen (MULTI_PART). | 7 / 8 | `falsche_groesse_beantwortet`, `wurzel_halbiert` | – |
| `wurzel-naeherung-02` | naeherung | I | √10 auf eine Stelle. | 3,2 | `abgeschnitten`, `wurzel_halbiert` | – |
| `wurzel-naeherung-03` | naeherung | II | √30 auf zwei Stellen, keine nahe Quadratzahl. | 5,48 | `abgeschnitten`, `wurzel_halbiert` | – |
| `wurzel-naeherung-04` | naeherung | II | √0,9 auf zwei Stellen, Wurzel größer als die Zahl. | 0,95 | `wurzel_halbiert`, `abgeschnitten` | – |
| `wurzel-naeherung-05` | naeherung | II | Sachkontext: Seite eines Beets mit 11 m², zwei Stellen. | 3,32 m | `abgeschnitten`, `wurzel_halbiert`, `kommastellen_zu_wenig` | 2 |
| `wurzel-naeherung-06` | naeherung | III | Sachkontext: Teppich mit mindestens 6 m², ganze cm aufrunden. | 245 cm | `abgeschnitten`, `einheit_uebersprungen`, `wurzel_halbiert` | 1 |
| `wurzel-irrational-01` | irrational | I | Anzahl irrationaler Zahlen unter √2; √9; 0,5; √5; 3/7. | 2 | `irrational_verwechselt` | – |
| `wurzel-irrational-02` | irrational | I | 0,375 als gekürzter Bruch, Nenner. | 8 | `teilgekuerzt` | – |
| `wurzel-irrational-03` | irrational | II | 0,454545… (Periode 45) als gekürzter Bruch, Nenner. | 11 | `teilgekuerzt`, `abgeschnitten` | 1 |
| `wurzel-irrational-04` | irrational | II | Anzahl rationaler Zahlen unter √16; √12; 0,333… (Periode 3); π; √0,25; −5. | 4 | `irrational_verwechselt` | – |
| `wurzel-irrational-05` | irrational | II | Sachkontext: Fliesenflächen, bei wie vielen ist die Seite rational. | 3 | `irrational_verwechselt` | – |
| `wurzel-irrational-06` | irrational | III | Für wie viele n von 1 bis 60 ist √n rational (= Quadratzahlen). | 7 | `falsche_groesse_beantwortet`, `irrational_verwechselt` | 2 |
| `wurzel-gesetze-01` | gesetze | I | √2 · √8 mit dem Produktgesetz. | 4 | `falsche_groesse_beantwortet`, `wurzel_halbiert` | – |
| `wurzel-gesetze-02` | gesetze | I | √50 : √2 mit dem Quotientengesetz. | 5 | `falsche_groesse_beantwortet`, `wurzel_halbiert` | – |
| `wurzel-gesetze-03` | gesetze | II | √(36 + 64): kein Gesetz für Summen. | 10 | `wurzel_gliedweise`, `falsche_groesse_beantwortet`, `wurzel_halbiert` | – |
| `wurzel-gesetze-04` | gesetze | II | √(1,44 + 0,81) mit Dezimalzahlen. | 1,5 | `wurzel_gliedweise`, `falsche_groesse_beantwortet`, `wurzel_halbiert` | 1 |
| `wurzel-gesetze-05` | gesetze | II | Sachkontext: Rechteck √8 m × √18 m, Flächeninhalt. | 12 m² | `falsche_groesse_beantwortet`, `umfang_statt_flaeche`, `plus_statt_mal` | 2 |
| `wurzel-gesetze-06` | gesetze | III | Sachkontext: ein Beet so groß wie zwei (9 m² + 16 m²), Seite. | 5 m | `wurzel_gliedweise`, `falsche_groesse_beantwortet`, `wurzel_halbiert` | – |
| `wurzel-teilweise-01` | teilweise | I | √72 = a · √2. | 6 | `faktor_ohne_wurzel`, `wurzel_halbiert`, `falsche_groesse_beantwortet` | – |
| `wurzel-teilweise-02` | teilweise | I | √48 = a · √3. | 4 | `faktor_ohne_wurzel`, `wurzel_halbiert`, `falsche_groesse_beantwortet` | – |
| `wurzel-teilweise-03` | teilweise | II | √200 = a · √2, Faktor 100 finden. | 10 | `faktor_ohne_wurzel`, `falsche_groesse_beantwortet` | – |
| `wurzel-teilweise-04` | teilweise | II | √18 · √6 = a · √3, erst Produktgesetz. | 6 | `faktor_ohne_wurzel`, `wurzel_halbiert`, `falsche_groesse_beantwortet` | 1 |
| `wurzel-teilweise-05` | teilweise | II | Sachkontext: Spielplatz 180 m², Seite = a · √5 m. | 6 | `faktor_ohne_wurzel`, `wurzel_halbiert`, `falsche_groesse_beantwortet` | – |
| `wurzel-teilweise-06` | teilweise | III | Rückrichtung 6 · √3 = √b. | 108 | `faktor_ohne_wurzel`, `mal_exponent` | 2 |

## Offene Punkte / Befunde

- **Bestands-Slugs ohne Klartext**: `wurzel_halbiert`, `kommastellen_zu_viel`/`_zu_wenig`,
  `abgeschnitten`, `teilgekuerzt`, `plus_statt_mal`, `umfang_statt_flaeche`, `klammer_vergessen`,
  `mal_exponent` haben in Prod keinen Klartext. Benutzt nach Name und Bestandsbedeutung (phase1 d).
- **`abgeschnitten` bei irrational-03** meint die abgeschnittene Periode, nicht abgeschnitten statt
  gerundet. Bedeutungsnah, aber eine Erweiterung; bei Freigabe prüfen.
- **`faktor_ohne_wurzel` in der Rückrichtung** (teilweise-06, 6 · √3 = √18): spiegelbildlicher Fehler
  (Faktor ohne Quadrieren unter die Wurzel). Erklärung des Slugs nennt nur die Hinrichtung.
- **Knoten irrational mit Bruch-Umwandlungen** (irrational-02/-03): laut Auftrag gewünscht; sie üben
  die Voraussetzung `bruch_dezimal` am Begriff „rational".
- Die Profile im Knoten teilweise sind fünfmal fast gleich; vorlauf-build fand trotzdem zwei
  verschiedene Profile (teilweise-06 mit `mal_exponent`).
