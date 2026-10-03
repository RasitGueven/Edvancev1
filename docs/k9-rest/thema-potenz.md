# K9-Rest – Thema potenz (Potenzen und Potenzgesetze)

Stand 03.10.2026 · Branch `feat/k9-rest` · KLP G9 NRW, Zweite Stufe, Ari-1/Ari-3/Ari-4.
24 Aufgaben, je sechs zu `zahl_potenz_gesetze`, `zahl_potenz_negativ`, `zahl_potenz_zehner` und
`zahl_potenz_rechnen`. Der Fundament-Knoten `potenzen` (Kl. 7) bleibt unberührt.

Quelle: `tools/k9-potenz-charge.mjs` → `docs/prefill/k9-potenz.json` →
`supabase/migrations/20261003105902_aufgaben_k9_potenz.sql` (vorlauf-build) →
`supabase/checks/k9_potenz_aufgaben.PRUEFUNG.sql` (Generator). Alle `status = 'draft'`,
`source = edvance_k9_potenz`, Themengebiet „Zahl & Rechnen", `competency_content = arithmetik_algebra`,
`curriculum_grade = 9`, `needs_image = false`, keine Hinweise.

## Entscheidungen

- **Alle Antworten exakt.** Potenzen mit ganzzahligen Hochzahlen ergeben ganze oder abbrechende
  Zahlen; Rundung würde nur Rauschen erzeugen. Jede Aufgabe sagt „als ganze Zahl" bzw. „exakt".
- **Negative Hochzahlen mit `bruch: true`.** 2⁻³ wird als `1/8` und als `0,125` akzeptiert; der
  Aufgabentext nennt beide Formen. Die Frage, ob ein Kind lieber Bruch oder Dezimalzahl tippt,
  ist nicht Gegenstand des Knotens.
- **Wissenschaftliche Schreibweise nie als Eingabe.** Beim Knoten `zahl_potenz_zehner` wird die
  Hochzahl allein abgefragt (oder in der Rückrichtung die Dezimalzahl), bei `zahl_potenz_rechnen`
  Vorfaktor und Hochzahl als zwei MULTI_PART-Teile. Grund: Das Tablet kennt keine Hochzahl-Eingabe.
- **„Nicht normiert" als `faktor_zehn_daneben`** (wie im Auftrag vorgeschlagen): 20 · 10⁸ statt
  2 · 10⁹ ist im Vorfaktor und in der Hochzahl je um eine Zehnerstelle daneben. Ebenso
  Kommaverschiebung um eine Stelle zu viel/zu wenig bei `zahl_potenz_zehner`.
- **`potenzgesetz_verwechselt` auch für Quotienten.** Hochzahlen beim Teilen addiert oder geteilt
  statt subtrahiert ist dieselbe Verwechslung der Gesetze; die Bedeutung „multipliziert, wo addiert
  wird, oder umgekehrt" wird sinngemäß auf das Quotientengesetz übertragen (gesetze-03/-06,
  negativ-06, rechnen-02/-04).
- **`mal_exponent` für 5⁰ = 0** (5 · 0): passt wörtlich („aⁿ als a·n"). Der zweite typische Fehler
  5⁰ = 5 hat keinen passenden Slug und ist deshalb nicht erfasst.
- **Zahlen im Text:** ganze Zahlen ab fünf Stellen mit Leerzeichen gruppiert (3 200 000), nie mit
  Punkt. Dezimalzahlen ungruppiert (0,00045, 0,0000075), damit die Nullen nach dem Komma direkt
  zählbar bleiben. Eingabe immer ohne Gruppierung (`405000`).
- **Sachkontexte ohne Namen und Marken:** Zellkultur, Würfelzerlegung, Halbierung einer Stoffmenge,
  rotes Blutkörperchen, Virus und Sandkorn, Licht (Minute, Sonne–Erde).

## Aufgaben

Rang = Sondierrang aus vorlauf-build.

| source_ref | Knoten | AFB | Begründung | Antwort | Fehlbilder | Rang |
|---|---|---|---|---|---|---|
| `potenz-gesetze-01` | gesetze | I | Reproduzieren: Produkt gleicher Basen, Hochzahlen addieren. | n = 7 | `potenzgesetz_verwechselt` (12), `falsche_groesse_beantwortet` (128) | – |
| `potenz-gesetze-02` | gesetze | I | Reproduzieren: Potenz einer Potenz, Hochzahlen multiplizieren. | n = 8 | `potenzgesetz_verwechselt` (6), `falsche_groesse_beantwortet` (6561) | – |
| `potenz-gesetze-03` | gesetze | II | Anwenden: zwei Potenzgesetze nacheinander. (a⁴)³ : a⁵ | n = 7 | `potenzgesetz_verwechselt` (2, 17) | – |
| `potenz-gesetze-04` | gesetze | II | Anwenden: gleiche Hochzahl, Basen multiplizieren. 2⁵ · 5⁵ = 10ⁿ | n = 5 | `potenzgesetz_verwechselt` (10), `falsche_groesse_beantwortet` (100000) | – |
| `potenz-gesetze-05` | gesetze | II | Sachkontext: Verdoppeln als · 2³, Wert berechnen (Zellkultur). | 256 | `potenzgesetz_verwechselt` (32768), `mal_exponent` (16), `falsche_groesse_beantwortet` (8) | 1 |
| `potenz-gesetze-06` | gesetze | III | Problemlösen: Anzahl kleiner Würfel als Volumenquotient, als 2ⁿ. | n = 9 | `linearer_faktor` (3), `potenzgesetz_verwechselt` (4), `falsche_groesse_beantwortet` (512) | 2 |
| `potenz-negativ-01` | negativ | I | Reproduzieren: negative Hochzahl als Kehrwert. 2⁻³ | 1/8 = 0,125 | `negativer_exponent_negativ` (−8), `mal_exponent` (−6) | – |
| `potenz-negativ-02` | negativ | I | Reproduzieren: 10⁻² als Dezimalzahl. | 0,01 | `negativer_exponent_negativ` (−100), `mal_exponent` (−20), `faktor_zehn_daneben` (0,1) | 2 |
| `potenz-negativ-03` | negativ | II | Anwenden: Produktgesetz mit negativer Hochzahl. 4⁻¹ · 4³ | 16 | `negativer_exponent_negativ` (−256), `potenzgesetz_verwechselt` (1/64) | – |
| `potenz-negativ-04` | negativ | II | Anwenden: Bruch mit negativer Hochzahl und Hochzahl null. (1/2)⁻² + 5⁰ | 5 | `negativer_exponent_negativ` (3/4), `mal_exponent` (4, −1) | – |
| `potenz-negativ-05` | negativ | II | Sachkontext: Halbierungen zählen, 2⁻⁵ berechnen. | 1/32 = 0,03125 | `negativer_exponent_negativ` (−32), `mal_exponent` (1/10) | – |
| `potenz-negativ-06` | negativ | III | Problemlösen: „um welchen Faktor" als Quotient 2³ : 2⁻². | 32 | `potenzgesetz_verwechselt` (2), `negativer_exponent_negativ` (−2), `falsche_groesse_beantwortet` (7,75) | 1 |
| `potenz-zehner-01` | zehner | I | Reproduzieren: große Zahl, Kommaverschiebung zählen. 3 200 000 | n = 6 | `zehnerexponent_vorzeichen` (−6), `faktor_zehn_daneben` (7, 5) | – |
| `potenz-zehner-02` | zehner | I | Reproduzieren: kleine Zahl, negative Hochzahl. 0,00045 | n = −4 | `zehnerexponent_vorzeichen` (4), `faktor_zehn_daneben` (−5, −3) | – |
| `potenz-zehner-03` | zehner | II | Rückrichtung: 7,2 · 10⁻³ als Dezimalzahl. | 0,0072 | `zehnerexponent_vorzeichen` (7200), `faktor_zehn_daneben` (0,072; 0,00072), `negativer_exponent_negativ` (−7200) | 2 |
| `potenz-zehner-04` | zehner | II | Rückrichtung mit Null im Vorfaktor: 4,05 · 10⁵ als Zahl. | 405000 | `zehnerexponent_vorzeichen` (0,0000405), `faktor_zehn_daneben` (40500; 4050000), `mal_exponent` (202,5) | 1 |
| `potenz-zehner-05` | zehner | II | Sachkontext: Durchmesser eines roten Blutkörperchens. | n = −6 | `zehnerexponent_vorzeichen` (6), `faktor_zehn_daneben` (−7, −5) | – |
| `potenz-zehner-06` | zehner | III | Problemlösen: Anzahl als Quotient zweier Längen (Virus, Sandkorn). | 10000 | `zehnerexponent_vorzeichen` (0,0001), `faktor_zehn_daneben` (1000; 100000) | – |
| `potenz-rechnen-01` | rechnen | I | Reproduzieren: (3 · 10⁴) · (2 · 10⁻⁶), schon normiert. | a = 6, n = −2 | `plus_statt_mal` (5), `potenzgesetz_verwechselt` (−24), `zehnerexponent_vorzeichen` (2) | 1 |
| `potenz-rechnen-02` | rechnen | I | Reproduzieren: (8 · 10⁶) : (2 · 10²), schon normiert. | a = 4, n = 4 | `multipliziert_statt_dividiert` (16), `potenzgesetz_verwechselt` (3, 8) | – |
| `potenz-rechnen-03` | rechnen | II | Anwenden: (5 · 10³) · (4 · 10⁵), normieren. | a = 2, n = 9 | `faktor_zehn_daneben` (20; 8), `potenzgesetz_verwechselt` (15) | – |
| `potenz-rechnen-04` | rechnen | II | Anwenden: (3 · 10⁵) : (6 · 10⁻²), Vorfaktor unter 1 normieren. | a = 5, n = 6 | `faktor_zehn_daneben` (0,5; 7), `multipliziert_statt_dividiert` (18), `potenzgesetz_verwechselt` (3) | 2 |
| `potenz-rechnen-05` | rechnen | II | Sachkontext: Lichtweg in einer Minute (Strecke = v · t). | a = 1,8, n = 10 | `faktor_zehn_daneben` (18; 9), `potenzgesetz_verwechselt` (8) | – |
| `potenz-rechnen-06` | rechnen | III | Problemlösen: Lichtlaufzeit Sonne–Erde (t = s : v), normieren. | a = 5, n = 2 | `faktor_zehn_daneben` (0,5; 3), `multipliziert_statt_dividiert` (4,5; 19) | – |

Neue Fehlbilder: `potenzgesetz_verwechselt` 13 Aufgaben, `negativer_exponent_negativ` 7,
`zehnerexponent_vorzeichen` 7. Wiederverwendet: `faktor_zehn_daneben`, `mal_exponent`,
`falsche_groesse_beantwortet`, `multipliziert_statt_dividiert`, `plus_statt_mal`, `linearer_faktor`.

## Prüfung

- `verify-tasks --prefill`: 24 Aufgaben, Charge-Fehler **0**.
- `k9_potenz_aufgaben.PRUEFUNG.sql` auf Wegwerf-DB (alle acht Substrate + Potenz-Aufgaben): **16 von 16 `t`**.
- Wegwerf-DB: zweiter Lauf ohne Zeilenänderung, **IDEMPOTENT: ok**.
- Jede Aufgabe von Hand nachgerechnet; Lösungsweg nennt das Ergebnis.

## Offene Punkte / Befunde

- `potenzgesetz_verwechselt` deckt laut Klartext nur „multipliziert statt addiert und umgekehrt" ab;
  hier wird es auch für Quotienten (geteilt oder addiert statt subtrahiert) benutzt. Falls die
  Freigabe das enger sieht, wäre der Klartext um „beim Teilen" zu ergänzen (Substrat, nicht diese Charge).
- 5⁰ = 5 (Basis stehen gelassen) und 2ⁿ-Rückrichtungen mit nur vertauschtem Vorzeichen haben keinen
  passenden Slug; bewusst nicht als known_error erfasst.
- `plus_statt_mal` und `multipliziert_statt_dividiert` haben im Bestand keinen Klartext; sie werden
  nach ihrem wörtlichen Namen benutzt. `linearer_faktor` (k statt k³, phase1 d) passt in gesetze-06
  wörtlich: Kantenzahl 8 = 2³ statt 8³ = 2⁹.
- `falsche_groesse_beantwortet` steht auch für „Wert statt Hochzahl" und „Differenz statt Faktor" –
  sinngemäß „richtig gerechnet, andere Größe angegeben".
