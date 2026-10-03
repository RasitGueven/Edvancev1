# K9-Rest – Thema bedingt (Bedingte Wahrscheinlichkeit und Vierfeldertafel)

Stand 03.10.2026 · Branch `feat/k9-rest` · Quelle `tools/k9-bedingt-charge.mjs` → `docs/prefill/k9-bedingt.json` →
`supabase/migrations/20261003105907_aufgaben_k9_bedingt.sql` (über `tools/vorlauf-build.mjs`).

30 Aufgaben, je sechs zu den fünf Knoten aus `graph.json` (Stochastik, Zweite Stufe, Sto-3 bis Sto-5).
Alle `draft`, `source = edvance_k9_bedingt`, Themengebiet „Daten & Zufall“, `competency_content = stochastik`,
`curriculum_grade = 9`, keine Abbildung, keine Hinweise. Alle Daten frei erfunden, keine Personen mit Namen, keine Marken.

**Darstellung der Vierfeldertafel.** Der Tablet-Player setzt den Aufgabentext als reinen Text (keine
Markdown-Tabelle, kein LaTeX, nur Zeilenumbrüche). Eine Tabelle käme als Zeichensalat an. Darum steht jede Tafel
als Liste benannter Felder da, eine Zeile je Feld bzw. Summe („Mädchen mit Haustier: 48“, „Mädchen insgesamt: 110“,
„Alle Befragten: 200“). Gesuchte Felder tragen „?“ und sind MULTI_PART-Teile, deren Prompt genau den Feldnamen
wiederholt („Mädchen ohne Haustier“). Summen enden immer auf „insgesamt“.

## Entscheidungen

- **Jede Tafel in sich stimmig.** Das Beispiel aus dem Auftrag (Jungen ohne Haustier: 40) passt nicht zu seinen
  Summen (Jungen = 90, mit Haustier 60 → ohne 30). Verwendet ist 30. Alle Tafeln sind über beide Randsummen
  nachgerechnet; die Lösungswege enthalten eine Probe.
- **Antwortformen.** Anzahlen exakt als ganze Zahl; Anteile exakt (`vierfeld-05`) oder „Dezimalzahl, zwei Stellen“;
  Prozent „ohne %-Zeichen, eine Stelle“; `wkeit-03` als gekürzter Bruch oder Dezimalzahl (`bruch: true`; 9/25 = 0,36
  bricht ab, beide Formen stehen in `correct_answers`). Jede Aufgabe nennt Form und Rundung im Text.
- **Fehlerwerte unterscheidbar.** Zahlen so gewählt, dass kein Fehlerwert gleich der richtigen Antwort desselben
  Teils ist. Beispiel `irrefuehrend-03`: 36 von 240 gegen 22 von 88 statt 30/200 gegen 20/80 aus dem Auftrag, wo die
  absolute Differenz 10 mit der richtigen Antwort 10 zusammenfiele.
- **Profile je Knoten.** Bei `wkeit` hatten zuerst alle sechs Aufgaben dasselbe Profil (gesamtheit/bedingung/bezug);
  vorlauf-build lehnte ab. `wkeit-04` trägt jetzt `randsumme_verwechselt` (Kinder falsch ergänzt), `wkeit-06`
  `falsche_groesse_beantwortet` (Anzahl statt Wahrscheinlichkeit).
- **Bestands-Slugs nur wörtlich passend:** `bezug_vertauscht` = Kehrwert, `grundwert_verwechselt` = Prozent vom
  falschen Grundwert (z. B. Fehlalarmquote von allen statt von den Gesunden), `dezimalverschiebung` = 5 % als 0,5 bzw.
  Anteil statt Prozentzahl, `zu_frueh_gerundet`, `falsche_operation`, `falsche_groesse_beantwortet`. Zusätzlich
  `halbieren_vergessen` (Bestand) in `irrefuehrend-06`: bei 2s = 96 nicht durch 2 geteilt.
- **Unabhängigkeit nur über Zahlen**, keine Ja/Nein-Antworten: erwartete Anzahl, Abstand in Prozentpunkten,
  fehlende Zahl für Unabhängigkeit.
- **Umkehr mit natürlichen Häufigkeiten**, Kontexte neutral (Pflanzenkrankheit, Pilz auf Saatgut, Prüfgerät,
  Schweißnähte). `umkehr-06` nennt keine Gesamtzahl: die Wahl (z. B. 1000) gehört zur Problemlöseleistung.
- **Sachkontext-Zuschlag** nur für 05 und 06 je Knoten (echte Übersetzungsleistung), obwohl fast jede Aufgabe einen
  Kontext hat.
- Rechenausdrücke ohne `^` – der Parser-Hinweis zum vorangestellten Minus betrifft diese Charge nicht.

## Aufgaben

| source_ref | Knoten | AFB | Begründung | Antwort | Fehlbilder | Rang |
|---|---|---|---|---|---|---|
| `bedingt-vierfeld-01` | `stoch_bedingt_vierfeld` | I | Reproduzieren: je ein fehlendes Feld als Randsumme minus bekanntes Feld. | 62 / 60 | `randsumme_verwechselt`, `falsche_operation` | – |
| `bedingt-vierfeld-02` | `stoch_bedingt_vierfeld` | I | Reproduzieren: drei fehlende Felder nacheinander über Randsummen. | 88 / 54 / 86 | `randsumme_verwechselt`, `falsche_operation`, `falsche_groesse_beantwortet` | – |
| `bedingt-vierfeld-03` | `stoch_bedingt_vierfeld` | II | Anwenden: fehlendes Feld ergänzen und als relative Häufigkeit (Anteil an allen) mit Rundung angeben. | 54 / 0,22 | `randsumme_verwechselt`, `falsche_operation`, `bezug_vertauscht`, `dezimalverschiebung` | 2 |
| `bedingt-vierfeld-04` | `stoch_bedingt_vierfeld` | II | Anwenden: Felder erst aus Prozentangaben bestimmen, dann über Randsummen ergänzen. | 12 / 14 / 146 | `grundwert_verwechselt`, `dezimalverschiebung`, `falsche_operation`, `falsche_groesse_beantwortet`, `randsumme_verwechselt` | 1 |
| `bedingt-vierfeld-05` | `stoch_bedingt_vierfeld` | II | Anwenden im Sachkontext: Tafel mit relativen Häufigkeiten ergänzen und auf die Zahl der Fahrzeuge zurückrechnen. | 0,47 / 0,12 / 0,23 / 48 | `randsumme_verwechselt`, `falsche_operation`, `falsche_groesse_beantwortet`, `dezimalverschiebung` | – |
| `bedingt-vierfeld-06` | `stoch_bedingt_vierfeld` | III | Problemlösen im Sachkontext: Tafel selbst anlegen, Prozent vom richtigen Grundwert nehmen und über zwei Summen ergänzen. | 18 / 72 | `randsumme_verwechselt`, `falsche_operation`, `falsche_groesse_beantwortet` | – |
| `bedingt-wkeit-01` | `stoch_bedingt_wkeit` | I | Reproduzieren: Zellwert durch die passende Randsumme, Werte direkt ablesbar. | 0,67 | `gesamtheit_statt_bedingung`, `bedingung_vertauscht`, `bezug_vertauscht` | – |
| `bedingt-wkeit-02` | `stoch_bedingt_wkeit` | I | Reproduzieren: Zellwert durch Spaltensumme, Ergebnis in Prozent mit Rundung. | 37,9 | `gesamtheit_statt_bedingung`, `bedingung_vertauscht`, `bezug_vertauscht` | – |
| `bedingt-wkeit-03` | `stoch_bedingt_wkeit` | II | Anwenden: richtige Teilgruppe wählen und das Ergebnis als gekürzten Bruch angeben. | 0,36 | `gesamtheit_statt_bedingung`, `bedingung_vertauscht`, `bezug_vertauscht` | 2 |
| `bedingt-wkeit-04` | `stoch_bedingt_wkeit` | II | Anwenden: zwei Felder der Tafel erst ergänzen, dann die bedingte Wahrscheinlichkeit bilden. | 0,60 | `gesamtheit_statt_bedingung`, `bedingung_vertauscht`, `randsumme_verwechselt` | – |
| `bedingt-wkeit-05` | `stoch_bedingt_wkeit` | II | Anwenden im Sachkontext: Tafel aus einem Text gewinnen, Bedingung „Roman“ erkennen und in Prozent angeben. | 23,3 | `gesamtheit_statt_bedingung`, `bedingung_vertauscht`, `bezug_vertauscht` | – |
| `bedingt-wkeit-06` | `stoch_bedingt_wkeit` | III | Problemlösen: aus einer bedingten Wahrscheinlichkeit die Tafel aufbauen und die umgekehrte Bedingung bestimmen. | 0,44 | `falsche_groesse_beantwortet`, `bedingung_vertauscht`, `gesamtheit_statt_bedingung` | 1 |
| `bedingt-unabhaengig-01` | `stoch_bedingt_unabhaengig` | I | Reproduzieren: erwartete Anzahl = Zeilensumme · Spaltensumme : Gesamtzahl. | 54 | `falsche_operation`, `falsche_groesse_beantwortet` | 2 |
| `bedingt-unabhaengig-02` | `stoch_bedingt_unabhaengig` | I | Reproduzieren: zwei Anteile in Prozent berechnen und ihren Abstand angeben. | 7,5 | `bedingung_vertauscht`, `gesamtheit_statt_bedingung` | – |
| `bedingt-unabhaengig-03` | `stoch_bedingt_unabhaengig` | II | Anwenden: Bedingung für Unabhängigkeit (gleiche Anteile) als Rechnung umsetzen. | 78 | `absolut_statt_relativ`, `gesamtheit_statt_bedingung` | – |
| `bedingt-unabhaengig-04` | `stoch_bedingt_unabhaengig` | II | Anwenden: zwei bedingte Anteile aus der Tafel bilden und vergleichen, Rundung erst am Ende. | 14,7 | `absolut_statt_relativ`, `zu_frueh_gerundet`, `gesamtheit_statt_bedingung` | – |
| `bedingt-unabhaengig-05` | `stoch_bedingt_unabhaengig` | II | Anwenden im Sachkontext: erwartete Anzahl aus zwei Prozentangaben bilden und mit dem beobachteten Wert vergleichen. | 77 / 18 | `falsche_operation`, `falsche_groesse_beantwortet` | – |
| `bedingt-unabhaengig-06` | `stoch_bedingt_unabhaengig` | III | Problemlösen im Sachkontext: Bedingung für Unabhängigkeit selbst ansetzen und die beobachteten Anteile vergleichen. | 90 / 12 | `absolut_statt_relativ`, `grundwert_verwechselt`, `gesamtheit_statt_bedingung` | 1 |
| `bedingt-umkehr-01` | `stoch_bedingt_umkehr` | I | Reproduzieren: zwei Prozentwerte nacheinander als natürliche Häufigkeiten. | 20 / 18 | `dezimalverschiebung`, `grundwert_verwechselt` | – |
| `bedingt-umkehr-02` | `stoch_bedingt_umkehr` | I | Reproduzieren: Gegenwahrscheinlichkeit als Anzahl und Fehlalarmquote auf die richtige Gruppe anwenden. | 4800 / 144 | `falsche_groesse_beantwortet`, `dezimalverschiebung`, `grundwert_verwechselt` | 2 |
| `bedingt-umkehr-03` | `stoch_bedingt_umkehr` | II | Anwenden: Tafel mit natürlichen Häufigkeiten aufbauen, positive Tests zählen und umkehren. | 67 / 26,9 | `falsche_groesse_beantwortet`, `grundwert_verwechselt`, `bedingung_vertauscht`, `gesamtheit_statt_bedingung` | – |
| `bedingt-umkehr-04` | `stoch_bedingt_umkehr` | II | Anwenden: ganze Umkehrung in einem Zug, ohne vorgegebene Zwischenschritte. | 32,4 | `bedingung_vertauscht`, `gesamtheit_statt_bedingung`, `grundwert_verwechselt` | – |
| `bedingt-umkehr-05` | `stoch_bedingt_umkehr` | II | Anwenden im Sachkontext: aus der Beschreibung eines Prüfverfahrens die Tafel aufbauen und umkehren. | 156 / 51,3 | `falsche_groesse_beantwortet`, `grundwert_verwechselt`, `gesamtheit_statt_bedingung`, `bedingung_vertauscht`, `bezug_vertauscht` | 1 |
| `bedingt-umkehr-06` | `stoch_bedingt_umkehr` | III | Problemlösen im Sachkontext: Eine Gesamtzahl selbst wählen, Tafel aufbauen und umkehren. | 28,4 | `bedingung_vertauscht`, `gesamtheit_statt_bedingung`, `grundwert_verwechselt` | – |
| `bedingt-irrefuehrend-01` | `stoch_bedingt_irrefuehrend` | I | Reproduzieren: sichtbare Säulenhöhen ab Achsenbeginn ins Verhältnis setzen. | 2 | `falsche_operation`, `achse_abgeschnitten_uebersehen` | – |
| `bedingt-irrefuehrend-02` | `stoch_bedingt_irrefuehrend` | I | Reproduzieren: das echte Verhältnis der Werte bestimmen, unabhängig von der Zeichnung. | 1,25 | `falsche_operation`, `achse_abgeschnitten_uebersehen`, `bezug_vertauscht` | 1 |
| `bedingt-irrefuehrend-03` | `stoch_bedingt_irrefuehrend` | II | Anwenden: zwei Anteile mit verschiedenen Grundwerten bilden und in Prozentpunkten vergleichen. | 10 | `absolut_statt_relativ`, `dezimalverschiebung` | – |
| `bedingt-irrefuehrend-04` | `stoch_bedingt_irrefuehrend` | II | Anwenden: die Bedingung einer Schlagzeile prüfen und die gemeinte bedingte Wahrscheinlichkeit richtig berechnen. | 7,5 | `falsche_groesse_beantwortet`, `bedingung_vertauscht`, `gesamtheit_statt_bedingung` | 2 |
| `bedingt-irrefuehrend-05` | `stoch_bedingt_irrefuehrend` | II | Anwenden im Sachkontext: eine Aussage über absolute Zahlen durch eine Rate je 1000 Einwohner prüfen. | 1,5 | `absolut_statt_relativ`, `dezimalverschiebung` | – |
| `bedingt-irrefuehrend-06` | `stoch_bedingt_irrefuehrend` | III | Problemlösen: aus dem gezeichneten Verhältnis eine Gleichung für den Achsenbeginn aufstellen und lösen. | 48 | `achse_abgeschnitten_uebersehen`, `halbieren_vergessen` | – |

Neue Fehlbilder (Zahl der Aufgaben): `gesamtheit_statt_bedingung` 15, `bedingung_vertauscht` 12,
`randsumme_verwechselt` 7, `absolut_statt_relativ` 5, `achse_abgeschnitten_uebersehen` 3.

## Prüfungen

- `node tools/k9-bedingt-charge.mjs`: 30 Aufgaben, keine Kollision richtig/falsch, keine Rundungsgrenze.
- `vorlauf-build`: Sondierrang 1+2 je Knoten aus verschiedenen Profilen (Spalte „Rang“).
- `verify-tasks --prefill`: Charge-Fehler **0**, Bestands-Befunde 0 (`docs/prefill/k9-bedingt-verifikation.md`).
- Wegwerf-DB (acht Substrate + diese Aufgaben, zweimal eingespielt): IDEMPOTENT ok;
  `supabase/checks/k9_bedingt_aufgaben.PRUEFUNG.sql` 16 von 16 `t`.

## Offene Punkte / Befunde

- `wkeit-03`: Ein **ungekürzter** Bruch (18/50) gilt nicht als richtig, nur 9/25 und 0,36. Der Text verlangt
  „gekürzt“; ob der Player ungekürzte Brüche normalisiert, ist nicht geprüft.
- MULTI_PART mit Randsummen-Verwechslung (`vierfeld-01/02/05`): Der Fehlerwert eines Teils ist teils die richtige
  Antwort des anderen Teils (z. B. 62/60). Fachlich ist das genau der Fehler (falsche Summe); bei bloß vertauschter
  Eingabe entstehen aber zwei Fehlbild-Treffer statt „Teile vertauscht“.
- Fachlich fehlende Kanten zu Laplace/Baumdiagramm (K8) wie in `phase1.md` b) vermerkt; nicht Teil dieses Laufs.
- Blind-Löser (Stufe 2) nicht gelaufen.
