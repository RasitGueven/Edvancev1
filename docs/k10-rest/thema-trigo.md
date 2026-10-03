# K10-Rest – Thema trigo (Trigonometrie)

Stand 03.10.2026 · Branch `feat/k10-rest` · KLP G9 NRW, Zweite Stufe, Geo-7 bis Geo-10 (Klasse 10).
Quelle `tools/k10-trigo-charge.mjs` → `docs/prefill/k10-trigo.json` (ids: `docs/prefill/k10-trigo-ids.json`)
→ Aufgaben-Migration über `tools/vorlauf-build.mjs` (noch nicht erzeugt).
Einspiel-Reihenfolge: nach `20261003121329_substrat_k10_trigo.sql`.

30 Aufgaben, je sechs zu `geo_trigo_verhaeltnis`, `_seite`, `_winkel`, `_anwendung`,
`_kosinussatz`. 29 `NUMERIC`, 1 `MULTI_PART` (`trigo-winkel-04`: α und β). `curriculum_grade = 10`,
`class_level = 10`, „Geometrie & Messen", `competency_content = geometrie`, keine Hinweise,
keine Abbildung, `source = edvance_k10_trigo`. AFB je Knoten 2× I, 3× II, 1× III.

## Ergebnis der Kette

- Charge: 30 Aufgaben, keine Ablehnung (Rundungsgrenzen, Kollisionen richtig/falsch, Doppel-Slugs
  prüft `tools/k10-rest-lib.mjs`).
- `k10-rest-minuscheck.mjs`: keine mehrdeutigen Ausdrücke (negative Werte als `(0-0.4)`).
- verify-prefill / Wegwerf-DB / Prüfskript: noch nicht gelaufen (gehört zum Zusammenbau).

Fehlbild-Häufigkeiten (Aufgaben): `tangens_verwechselt` 21, `sin_cos_vertauscht` 17,
`bogenmass_modus` 16, `umkehrfunktion_vergessen` 10, `kosinussatz_vorzeichen` 6,
`pythagoras_ohne_rechten_winkel` 4 (alle sechs neu, Mindestzahl 3 erfüllt); Bestand:
`zu_frueh_gerundet` 4, `multipliziert_statt_dividiert` 3, `wurzel_vergessen` 3,
`halbieren_vergessen` 2, `hypotenuse_verwechselt` 1, `additiv_statt_multiplikativ` 1,
`falsche_groesse_beantwortet` 1.

## Entscheidungen

- **Feste Benennung** aus phase1.md e) in jeder Dreiecksaufgabe wörtlich („Im Dreieck ABC ist der
  Winkel bei C ein rechter Winkel …"), bei β-Aufgaben ergänzt um „β ist der Winkel bei B.". Im
  Kosinussatz-Knoten: „… c der Ecke C. γ ist der Winkel bei C. Das Dreieck hat keinen rechten
  Winkel." Sachaufgaben beschreiben das Dreieck in Worten (waagerecht/senkrecht, „gegen die
  Waagerechte").
- **Gradmaß** steht in jeder Aufgabe: gegebene Winkel mit `°` und, in Sachaufgaben und bei
  verhaeltnis-02, dem Satz „Winkel sind im Gradmaß angegeben."; gesuchte Winkel mit „Gib den Winkel
  im Gradmaß an." und `unit = °`. Winkel auf eine Stelle, Längen auf zwei Stellen bzw. ganze Meter,
  Verhältnisse exakt (abbrechend) oder auf vier Stellen.
- **Jede Zahl über Ausdrücke**, auch die Zwischenwerte im Lösungsweg (Helfer `z()` über `wert()` der
  Bibliothek, Minus als `−`).
- **Fehlwerte in der Aufgabenrundung**, wo das kollisionsfrei geht (wer falsch rechnet, rundet
  trotzdem wie verlangt). Eigene Rundung nur: `trigo-winkel-01` Bogenmaß-Wert 0,64 (auf eine Stelle
  wäre er 0,6 = Sinuswert von `umkehrfunktion_vergessen`), nicht abbrechende Fehlwerte in
  „exakt"-Aufgaben (verhaeltnis-03: 1,33 / 0,51), `umkehrfunktion_vergessen` mit 0,6 / 0,625 / 0,12
  exakt.
- **Winkel so gewählt, dass alle Fehlwerte verschieden sind** (kein 45°; winkel-02 von b = 7 cm auf
  9 cm geändert, weil sin⁻¹(4 : 7) an einer Rundungsgrenze lag; anwendung-01 ohne Bogenmaß-Eintrag,
  weil der Bogenmaß-Winkel 0,119 auf eine Stelle mit dem Tangenswert 0,12 nicht sauber trennbar ist).
- **`sin_cos_vertauscht` beim Tangens** (verhaeltnis-03, seite-02, winkel-02, anwendung-02): Der
  Klartext beginnt mit „Verwechselt Gegenkathete und Ankathete" – beim Tangens führt genau das zum
  Kehrwert (b : a). Wörtlich passt der erste Halbsatz, der zweite („Sinus statt Kosinus") nicht.
- **`tangens_verwechselt`** in beide Richtungen: tan statt sin/cos (Hypotenuse als Kathete) und
  sin statt tan (Kathete als Hypotenuse, z. B. Steigung mit „100 m entlang der Straße").
- **`bogenmass_modus`** mit `SR/CR/TR` bzw. bei Umkehrfunktionen `AS(x)*P/180`. Viele Modus-Werte
  sind negativ (sin 35 im Bogenmaß); die sokratische Frage zielt darauf („Kann eine Seite negativ
  lang sein?").
- **`zu_frueh_gerundet`**: gerundeter sin/cos-Wert (seite-04 0,62; seite-06 0,62 und 0,79;
  kosinussatz-04 −0,4) bzw. gerundeter Winkel (anwendung-06 4,6°); diese Aufgaben sagen
  ausdrücklich „Rechne ohne gerundete Zwischenergebnisse."
- **`wurzel_vergessen`** nur im Kosinussatz (c² als Ergebnis), **`multipliziert_statt_dividiert`**
  nur bei gesuchter Seite im Nenner (a · sin α statt a : sin α, 25 · tan 9° statt 25 : tan 9°).
- **`halbieren_vergessen`** wie in K9 (Faktor ½ beim Dreiecksflächeninhalt): seite-06 und die
  Rückrichtung winkel-06 (b = A : a statt 2A : a).
- **`additiv_statt_multiplikativ`** in verhaeltnis-05 (ähnliche Dreiecke: a wächst um denselben
  Betrag wie c) – die Bestandserklärung spricht von ähnlichen Figuren, passt wörtlich.
- **`falsche_groesse_beantwortet`** in kosinussatz-06 (Winkel gegenüber der kürzesten statt der
  längsten Seite). In winkel-04 ist die Verwechslung α/β als `sin_cos_vertauscht` erfasst.
- **MULTI_PART nur einmal** (winkel-04, α und β); Teil 2 trägt den Folgefehler `bogenmass_modus`
  (90 − α im Bogenmaß).
- **Sinussatz nicht angelegt** (nicht im KLP Sek I). Keine Personennamen, keine Marken; Kontexte:
  ähnliche Dreiecke, Rampe, Dachsparren, Straße/Verkehrsschild, Turm, Leuchtturm/Boot, Leiter,
  Weg, See.
- `geo_trigo_anwendung` ist durchgehend Sachkontext (`sach: true`, +30 s); Rückrichtung dort:
  Winkel → Prozent (03) und Prozent → Winkel → Höhe (06).

## Aufgaben

| source_ref | Knoten | AFB | Begründung | Antwort | Fehlbilder | Format |
|---|---|---|---|---|---|---|
| `trigo-verhaeltnis-01` | verhaeltnis | I | Reproduzieren: sin α = Gegenkathete : Hypotenuse mit allen drei gegebenen Seiten. | 0,6 | `sin_cos_vertauscht`, `tangens_verwechselt` | – |
| `trigo-verhaeltnis-02` | verhaeltnis | I | Reproduzieren: einen Sinuswert im Gradmaß mit dem Taschenrechner bestimmen und runden. | 0,5736 | `bogenmass_modus`, `sin_cos_vertauscht`, `tangens_verwechselt` | – |
| `trigo-verhaeltnis-03` | verhaeltnis | II | Anwenden: fehlende Kathete mit dem Satz des Pythagoras, dann tan α als Kathetenverhältnis. | 0,75 | `tangens_verwechselt`, `sin_cos_vertauscht`, `hypotenuse_verwechselt` | – |
| `trigo-verhaeltnis-04` | verhaeltnis | II | Anwenden: Gegen- und Ankathete für den Winkel β neu zuordnen, Bruch runden. | 0,3846 | `sin_cos_vertauscht`, `tangens_verwechselt` | – |
| `trigo-verhaeltnis-05` | verhaeltnis | II | Rückrichtung: Das Seitenverhältnis bleibt in ähnlichen Dreiecken gleich; aus ihm eine Seite des zweiten Dreiecks bestimmen. | 7,2 cm | `sin_cos_vertauscht`, `tangens_verwechselt`, `additiv_statt_multiplikativ` | – |
| `trigo-verhaeltnis-06` | verhaeltnis | III | Problemlösen: Rückrichtung vom Verhältnis zu den Seiten; Seitenverhältnis 3 : 4 erkennen, mit Pythagoras auf die Hypotenuse schließen. | 12 cm | `tangens_verwechselt`, `sin_cos_vertauscht` | – |
| `trigo-seite-01` | seite | I | Reproduzieren: a = c · sin α, gesuchte Seite im Zähler. | 5,74 cm | `sin_cos_vertauscht`, `tangens_verwechselt`, `bogenmass_modus` | – |
| `trigo-seite-02` | seite | I | Reproduzieren: a = b · tan α, zwei Katheten im Verhältnis. | 5,03 cm | `sin_cos_vertauscht`, `tangens_verwechselt`, `bogenmass_modus` | – |
| `trigo-seite-03` | seite | II | Anwenden: Die gesuchte Seite steht im Nenner; sin α = a : c nach c umstellen. | 9,59 cm | `multipliziert_statt_dividiert`, `sin_cos_vertauscht`, `tangens_verwechselt`, `bogenmass_modus` | – |
| `trigo-seite-04` | seite | II | Anwenden: Ankathete erkennen, Kosinus wählen, ohne gerundeten Zwischenwert rechnen. | 5,17 cm | `sin_cos_vertauscht`, `zu_frueh_gerundet`, `bogenmass_modus` | – |
| `trigo-seite-05` | seite | II | Anwenden im Sachkontext: Rampe als Hypotenuse erkennen, gesuchte Länge im Nenner. | 7,65 m | `multipliziert_statt_dividiert`, `tangens_verwechselt`, `bogenmass_modus` | – |
| `trigo-seite-06` | seite | III | Problemlösen: beide Katheten über Sinus und Kosinus bestimmen und den Flächeninhalt bilden. | 34,93 cm² | `halbieren_vergessen`, `zu_frueh_gerundet`, `bogenmass_modus` | – |
| `trigo-winkel-01` | winkel | I | Reproduzieren: sin α aus zwei Seiten, dann α mit sin⁻¹. | 36,9° | `umkehrfunktion_vergessen`, `sin_cos_vertauscht`, `tangens_verwechselt`, `bogenmass_modus` | – |
| `trigo-winkel-02` | winkel | I | Reproduzieren: tan α aus zwei Katheten, dann α mit tan⁻¹. | 24,0° | `umkehrfunktion_vergessen`, `sin_cos_vertauscht`, `tangens_verwechselt` | – |
| `trigo-winkel-03` | winkel | II | Anwenden: Ankathete erkennen, Kosinus wählen, Dezimalzahlen. | 43,8° | `sin_cos_vertauscht`, `tangens_verwechselt`, `umkehrfunktion_vergessen`, `bogenmass_modus` | – |
| `trigo-winkel-04` | winkel | II | Anwenden: α mit sin⁻¹, dann β über die Winkelsumme als 90° − α. | 38,7° / 51,3° | `umkehrfunktion_vergessen`, `sin_cos_vertauscht`, `bogenmass_modus` | MULTI_PART |
| `trigo-winkel-05` | winkel | II | Anwenden im Sachkontext: Sparren als Hypotenuse und Dachhöhe als Gegenkathete erkennen. | 27,5° | `sin_cos_vertauscht`, `tangens_verwechselt`, `umkehrfunktion_vergessen` | – |
| `trigo-winkel-06` | winkel | III | Problemlösen: Rückrichtung über den Flächeninhalt zur zweiten Kathete, dann Winkel mit tan⁻¹. | 33,7° | `halbieren_vergessen`, `tangens_verwechselt`, `umkehrfunktion_vergessen` | – |
| `trigo-anwendung-01` | anwendung | I | Reproduzieren: Steigung in Prozent als tan α lesen, Winkel mit tan⁻¹. | 6,8° | `umkehrfunktion_vergessen`, `tangens_verwechselt` | – |
| `trigo-anwendung-02` | anwendung | I | Reproduzieren: Höhe = Entfernung · tan(Höhenwinkel), Standardsituation. | 31,3 m | `tangens_verwechselt`, `sin_cos_vertauscht`, `bogenmass_modus` | – |
| `trigo-anwendung-03` | anwendung | II | Anwenden: Rückrichtung vom Winkel zur Steigung, tan α in Prozent umrechnen. | 14,1 % | `tangens_verwechselt`, `bogenmass_modus` | – |
| `trigo-anwendung-04` | anwendung | II | Anwenden: Wechselwinkel erkennen, gesuchte Strecke im Nenner (Entfernung = Höhe : tan). | 158 m | `multipliziert_statt_dividiert`, `tangens_verwechselt`, `bogenmass_modus` | – |
| `trigo-anwendung-05` | anwendung | II | Anwenden im Sachkontext: Leiter als Hypotenuse, Höhe an der Wand als Gegenkathete. | 5,64 m | `sin_cos_vertauscht`, `tangens_verwechselt`, `bogenmass_modus` | – |
| `trigo-anwendung-06` | anwendung | III | Problemlösen: Steigung zuerst in einen Winkel umrechnen, dann mit der Straßenlänge als Hypotenuse die Höhe bestimmen. | 39,9 m | `tangens_verwechselt`, `zu_frueh_gerundet`, `umkehrfunktion_vergessen` | – |
| `trigo-kosinussatz-01` | kosinussatz | I | Reproduzieren: Kosinussatz c² = a² + b² − 2ab · cos γ direkt anwenden. | 5,39 cm | `kosinussatz_vorzeichen`, `pythagoras_ohne_rechten_winkel`, `wurzel_vergessen` | – |
| `trigo-kosinussatz-02` | kosinussatz | I | Reproduzieren: Kosinussatz mit anderen Zahlen, Taschenrechner im Gradmaß. | 9,14 cm | `kosinussatz_vorzeichen`, `pythagoras_ohne_rechten_winkel`, `bogenmass_modus` | – |
| `trigo-kosinussatz-03` | kosinussatz | II | Anwenden: Kosinussatz nach cos γ umstellen, dann cos⁻¹. | 83,3° | `kosinussatz_vorzeichen`, `umkehrfunktion_vergessen`, `bogenmass_modus` | – |
| `trigo-kosinussatz-04` | kosinussatz | II | Anwenden: stumpfer Winkel, cos γ ist negativ; das Minus im Kosinussatz macht c länger. | 8,96 cm | `kosinussatz_vorzeichen`, `pythagoras_ohne_rechten_winkel`, `zu_frueh_gerundet`, `wurzel_vergessen` | – |
| `trigo-kosinussatz-05` | kosinussatz | II | Anwenden im Sachkontext: Messpunkt als Ecke C mit eingeschlossenem Winkel erkennen, Kosinussatz. | 423 m | `kosinussatz_vorzeichen`, `pythagoras_ohne_rechten_winkel`, `wurzel_vergessen` | – |
| `trigo-kosinussatz-06` | kosinussatz | III | Problemlösen: den größten Winkel der längsten Seite gegenüber erkennen, Kosinussatz umstellen, negativer Kosinuswert. | 109,5° | `kosinussatz_vorzeichen`, `falsche_groesse_beantwortet`, `umkehrfunktion_vergessen` | – |

Sondierrang vergibt `vorlauf-build.mjs` beim Zusammenbau.

## Offene Punkte / Befunde

- **`sin_cos_vertauscht` beim Tangens** (s. o.) bei der Freigabe ansehen; Alternative wäre ein
  eigener Slug „Kehrwert des Tangens", den phase1.md d) nicht vorsieht.
- **Negative Modus-Werte**: Ein Kind tippt einen negativen Wert für eine Länge selten ab; diagnostisch
  bleibt der Eintrag trotzdem richtig. Positive Modus-Werte z. B. bei seite-03 (16,61),
  anwendung-02 (12,4), kosinussatz-02 (14,88).
- **verhaeltnis-02** fragt sin 35° ohne Dreieck (reiner Taschenrechnerwert, AFB I) – laut Auftrag.
- **anwendung-04** setzt den Wechselwinkel voraus (Sichtlinie gegen die Waagerechte oben = Winkel
  beim Boot); steht im Lösungsweg, nicht im Text.
- Voraussetzungen `geo_aehnlich_streckfaktor`, `geo_pythagoras_hypotenuse`, `fkt_linear_steigung`,
  `term_einsetzen` sind selbst noch Entwurf (phase1.md c); Freigabe durch Lena steht aus.
