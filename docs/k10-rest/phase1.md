# K10-Rest – Phase 1: gemeinsame Planung

Stand 03.10.2026 · Branch `feat/k10-rest` (Worktree `~/wt/k10-rest`, ab `origin/dev` 805124c) ·
Auftrag `W4-k10-rest.md`. Gelesen ausschließlich über `~/bin/dbread`. Letzte Migration in Prod:
`20261003113055_skill_thema_nachtrag`.

Diese Datei ist die **verbindliche Grundlage** für Teil 2. Der Graph steht maschinenlesbar in
[`graph.json`](graph.json), geprüft mit `node tools/k10-rest-graph-check.mjs docs/k10-rest/bestand-prod.json`
(Abzug des Prod-Graphen per dbread). Entscheidungen mit Begründung: [`entscheidungen.md`](entscheidungen.md).

## Vorab: Die Lage ist anders als im Auftrag angenommen

Der Auftrag geht davon aus, dass K9 (Pythagoras, Ähnlichkeit, Potenzgesetze, Wurzeln, quadratische
Funktionen) **noch nicht in Prod** ist und parallel in `feat/k9-rest` entsteht. Tatsächlich sind
**K8-Rest (#193), K9-Rest (#194) und der skill_thema-Nachtrag (#195) nach dev gemergt und in Prod
eingespielt** (`schema_migrations` bis `20261003113055`). „Die DB gewinnt": Alle Voraussetzungen
dieses Laufs existieren in origin/dev **und** in Prod. Folgen (E1, E2 in `entscheidungen.md`):

- Keine eigene `kanten_k10_k9.sql`: Kanten auf K9-Knoten stehen direkt in den Substraten, die damit
  trotzdem unabhängig von noch offenen Läufen einspielbar sind.
- Keine zweite Wegwerf-DB mit K9-Migrationen aus `~/wt/k9-rest`: Sie sind Teil der Repo-Basis jeder
  Wegwerf-DB.
- K8/K9-Fehlbilder sind Teil des Prod-Bestands (137 Slugs) und wurden darüber geprüft.

## a) Bestand (live, per dbread)

- **115 Knoten**, **198 Kanten**, Tiefe max. 9, **137 Fehlbild-Slugs**, 39 Einstiegszeilen,
  `skill_thema` für alle K8/K9-Knoten gesetzt.
- Kein Knoten zu Exponentialfunktionen, Trigonometrie oder Sinusfunktion.

### Themen-Keys dieses Laufs (`public.themen`, alle `stufe = 'zweite'`, ohne Einstieg)

| Thema | thema_key | `themen.klasse` | KLP im Katalog |
|---|---|---|---|
| 1 Exponentialfunktionen | `exponentialfunktionen` (Label „Exponentielles Wachstum") | 9 | Fkt-10, Fkt-11, Fkt-12, Ari-10 |
| 2 Trigonometrie | `trigonometrie` | 9 | Geo-7, Geo-8, Geo-9, Geo-10 |
| 3 Sinusfunktion | `sinusfunktion` | 9 | Fkt-13, Fkt-14 |

Der Katalog führt die Zweite Stufe (9/10) unter `klasse = 9`. **Alle 25 Kölner Schulpläne** in
`docs/themen/schulplaene.csv` legen die drei Themen in **Klasse 10** → `klasse_herkunft = 10`,
`class_level = 10`, `curriculum_grade = 10` (Auftrag; E3).

### KLP-Wortlaut (G9 NRW 2019, Zweite Stufe; über den Stoffverteilungsplan mathe.delta 10 geprüft)

- **Geo-7** Sinus, Kosinus, Tangens als invariante Seitenverhältnisse ähnlicher Dreiecke.
  **Geo-8** Kosinussatz als Verallgemeinerung des Satzes des Pythagoras. **Geo-9** Größen mit
  trigonometrischen Beziehungen berechnen. **Geo-10** Maßangaben in Sachsituationen.
  → **Kosinussatz gehört dazu** (eigener Knoten). **Sinussatz steht nicht im KLP** der Sek I → Befund, nicht angelegt.
- **Fkt-10** Wachstumsmodelle begründet wählen, langfristige Entwicklung. **Fkt-12** exponentielle
  Funktionen anwenden. **Ari-10** Exponentialgleichungen bˣ = c **durch Probieren, durch
  Logarithmieren** und digital lösen. **Ari-11** Exponentialgleichungen in Sachproblemen.
  → Logarithmus gehört dazu (eigener Knoten), aber nur als `log c : log b` mit Taschenrechner.
- **Fkt-13** Sinus/Kosinus am Einheitskreis, Sinusfunktion als Verallgemeinerung.
  **Fkt-14** zeitlich periodische Vorgänge mit Sinusfunktionen beschreiben.
- Fkt-11 (Messreihen mit digitalen Werkzeugen) ist ohne Werkzeug im Player nicht prüfbar → Befund.

### Darstellung im Schülerpfad (wie K9, `docs/k9-rest/phase1.md`)

- Aufgabentext ist **reiner Text**: keine Tabellen, kein LaTeX. Hochzahlen als Unicode (`1,05ˣ`, `2⁻³`),
  Winkel mit `°`, π als Zeichen.
- **Eingabe nur Zahl** (Komma, Minus) oder Bruch (`1/3`). Kein Term, keine Hochzahl, kein π, kein √.
  Deshalb: f(x) = a·bˣ und a·sin(b·x) werden über **MULTI_PART-Teile** abgefragt (a und b,
  Amplitude und Periode); Bogenmaß als Dezimalzahl mit Rundung **oder** als Faktor k in „k·π"
  (Bruch erlaubt).

### Figuren (`scripts/figures`)

`koordinatensystem` zeichnet nur `linear {m,b}`, `quadratisch {a,b,c}` und Punkte mit Label;
`winkel` genau einen Winkel. **Weder Exponential- noch Sinuskurven** (Befund).
- Exponentialfunktionen: „Graph lesen" über **Punkte des Graphen** im Koordinatensystem (2–3 Aufgaben
  in `fkt_exp_term`), Text sagt ausdrücklich „Die Punkte liegen auf dem Graphen von f(x) = a·bˣ".
- Sinusfunktion: **ohne Abbildung**; Graph-Eigenschaften (Hoch-/Tiefpunkte, Nullstellen) werden
  im Text beschrieben oder aus dem Term bestimmt.
- Trigonometrie: Dreiecke als Text mit allen Maßen und eindeutiger Benennung (Muster unten), kein Generator.

## b) Graph: 15 neue Knoten, 26 Kanten, Tiefe 7…12

Jede Kante echt flacher, Tiefe = 1 + tiefste direkte Voraussetzung, keine transitiv redundante
Kante. Alle Vorgänger außerhalb des Laufs existieren in Prod. Begründung je Kante in `graph.json`
und im Kommentar der Substrat-Migration.

| Thema | Knoten | Tiefe | direkte Voraussetzungen (Tiefe) |
|---|---|---|---|
| exp | `fkt_exp_wachstum` Lineares und exponentielles Wachstum, Wachstumsfaktor | 10 | prozent_zins_zinseszins (9), fkt_linear_gleichung (7) |
| | `fkt_exp_term` Exponentialfunktion f(x) = a·bˣ aufstellen und auswerten | 11 | fkt_exp_wachstum, zahl_potenz_negativ (6) |
| | `fkt_exp_halbwert` Verdopplungszeit und Halbwertszeit | 11 | fkt_exp_wachstum |
| | `fkt_exp_gleichung` Exponentialgleichungen bˣ = c lösen (Probieren, Logarithmus) | 7 | zahl_potenz_negativ (6), runden_ueberschlag (2) |
| | `fkt_exp_anwendung` Exponentielle Modelle: Zeitpunkte berechnen | 12 | fkt_exp_term, fkt_exp_gleichung |
| trigo | `geo_trigo_verhaeltnis` Sinus, Kosinus und Tangens als Seitenverhältnisse | 7 | geo_aehnlich_streckfaktor (6), geo_pythagoras_hypotenuse (6) |
| | `geo_trigo_seite` Seiten im rechtwinkligen Dreieck berechnen | 8 | geo_trigo_verhaeltnis, gleichung_einschrittig (5) |
| | `geo_trigo_winkel` Winkel im rechtwinkligen Dreieck berechnen | 8 | geo_trigo_verhaeltnis |
| | `geo_trigo_anwendung` Trigonometrie in Sachsituationen (Steigung, Höhe, Entfernung) | 9 | geo_trigo_seite, geo_trigo_winkel, fkt_linear_steigung (5) |
| | `geo_trigo_kosinussatz` Kosinussatz im allgemeinen Dreieck | 9 | geo_trigo_winkel, term_einsetzen (5) |
| sinus | `fkt_sinus_einheitskreis` Sinus und Kosinus am Einheitskreis | 8 | geo_trigo_verhaeltnis (7), geo_koordinaten (2) |
| | `fkt_sinus_bogenmass` Bogenmaß und Gradmaß | 8 | geo_kreis_sektor (7) |
| | `fkt_sinus_graph` Graph der Sinusfunktion | 9 | fkt_sinus_einheitskreis, fkt_sinus_bogenmass |
| | `fkt_sinus_parameter` Amplitude und Periode bei a·sin(b·x) | 10 | fkt_sinus_graph |
| | `fkt_sinus_periodisch` Periodische Vorgänge mit Sinusfunktionen beschreiben | 11 | fkt_sinus_parameter |

**Tiefen-Reserve:** max. 12 von 12, nur beim Blatt `fkt_exp_anwendung`. Grund: Exponentielles
Wachstum hängt am Zinseszins (Tiefe 9, K7-Prozentkette). Nichts musste zusammengelegt werden;
`fkt_exp_gleichung` ist bewusst flach (7), weil bˣ = c reine Arithmetik ist (Ari-10). Ein späterer
Oberstufen-Knoten unter `fkt_exp_anwendung` hätte keinen Platz — dort müsste er an
`fkt_exp_term` (11) hängen (Befund).

**Einspiel-Reihenfolge:** `substrat_k10_trigo` vor `substrat_k10_sinus` (Kante
`fkt_sinus_einheitskreis → geo_trigo_verhaeltnis`); `exp` ist unabhängig.

**Kante auf Prod-Knoten** (alle 26 – es gibt keine „Kante auf K9-Knoten" mehr, die nicht in Prod steht):
- aus K9-Rest (in Prod seit #194): `zahl_potenz_negativ`, `geo_aehnlich_streckfaktor`, `geo_pythagoras_hypotenuse`;
  aus K9-Kreis: `geo_kreis_sektor`; aus K8-Linear/Zins/Fundament: `fkt_linear_gleichung`, `fkt_linear_steigung`,
  `prozent_zins_zinseszins`, `gleichung_einschrittig`, `term_einsetzen`, `geo_koordinaten`, `runden_ueberschlag`.
- innerhalb des Laufs: die übrigen 15.

## c) Voraussetzungen aus dem Fundament

„ready" = aktiv und `ready`. „Rang" = Sondierränge unter den ready-Aufgaben (in Klammern: unter allen).
„ohne ke" = ready-Aufgaben ohne `acceptance.known_errors`. Urteil: **trägt** = ≥ 4 ready, Rang 1+2,
known_errors; **dünn** = weniger; **fehlt** = kein Knoten.

| skill_key | Tiefe | ready (aktiv) | Rang 1+2 | ohne ke | Urteil | gebraucht von |
|---|---|---|---|---|---|---|
| `prozent_zins_zinseszins` | 9 | 0 (6 draft) | – (1, 2) | – | dünn: Zins-Lauf wartet auf Lena, **nicht zugeteilt** | exp |
| `fkt_linear_gleichung` | 7 | 0 (6 draft) | – (1, 2) | – | dünn: Linear-Lauf wartet auf Lena, **nicht zugeteilt** | exp |
| `fkt_linear_steigung` | 5 | 0 (6 draft) | – (1, 2) | – | dünn: wie oben, **nicht zugeteilt** | trigo |
| `zahl_potenz_negativ` | 6 | 0 (6 draft) | – (1, 2) | – | dünn: K9-Rest wartet auf Lena, **nicht zugeteilt** | exp |
| `runden_ueberschlag` | 2 | 10 (13) | 1, 2 | 0 | trägt | exp |
| `geo_aehnlich_streckfaktor` | 6 | 0 (6 draft) | – (1, 2) | – | dünn: K9-Rest, **nicht zugeteilt** | trigo |
| `geo_pythagoras_hypotenuse` | 6 | 0 (6 draft) | – (1, 2) | – | dünn: K9-Rest, **nicht zugeteilt** | trigo |
| `gleichung_einschrittig` | 5 | 6 (6) | 1, 2 | 0 | trägt | trigo |
| `term_einsetzen` | 5 | 0 (6 draft) | – (1, 2) | – | dünn: Vorlauf wartet auf Lena, **nicht zugeteilt** | trigo |
| `geo_koordinaten` | 2 | 0 (6 draft) | – (1, 2) | – | dünn: Vorlauf wartet auf Lena, **nicht zugeteilt** | sinus |
| `geo_kreis_sektor` | 7 | 0 (6 draft) | – (1, 2) | – | dünn: Kreis-Lauf wartet auf Lena, **nicht zugeteilt** | sinus |

**Zuteilung zum Auffüllen: keine.** Wie in K8-Rest und K9-Rest (E4 dort): Jede „dünne"
Voraussetzung hat sechs Entwürfe mit Rang 1+2 und known_errors; es fehlt Lenas Freigabe, nicht
Inhalt. Weder K8 noch K9 haben sie zum Auffüllen zugeteilt, weil sie selbst die Urheber sind.
Weitere Entwürfe daneben verlängern nur die Freigabe-Warteschlange (Befund B2: Freigabe-Reihenfolge).

## d) Zentrale Fehlbild-Liste

### Wiederverwenden (Bestand, unverändert)

| Thema | Slugs (Bedeutung im Bestand) |
|---|---|
| exp | `wachstumsfaktor_falsch` (1,5 statt 1,05 bei 5 %), `prozente_addiert` (Prozentsätze aufsummiert = linear fortgeschrieben bei Prozent-Wachstum), `zu_frueh_gerundet`, `falsche_groesse_beantwortet`, `negativer_exponent_negativ` (b⁻ⁿ als −bⁿ), `potenzgesetz_verwechselt`, `mal_exponent` (bⁿ als b·n), `basis_exponent_vertauscht` |
| trigo | `hypotenuse_verwechselt` (Pythagoras-Schritt mit falscher Seite), `multipliziert_statt_dividiert` (a·sin α statt a : sin α), `zu_frueh_gerundet` (mit gerundetem sin-Wert weitergerechnet), `falsche_groesse_beantwortet`, `wurzel_vergessen` (Kosinussatz: c² statt c) |
| sinus | `kreisanteil_falsch` (Bogenlänge mit falschem Anteil), `pi_vergessen`, `zu_frueh_gerundet`, `falsche_groesse_beantwortet`, `vorzeichen_ignoriert` |

Andere Bestands-Slugs nur, wenn sie wörtlich passen (Liste: `docs/k10-rest/fehlbild-bestand.json`).
`additiv_statt_multiplikativ` wird **nicht** für Wachstum benutzt: Seine Erklärung spricht von
ähnlichen Figuren (Elternreport-Text wäre falsch) → neuer Slug `linear_statt_exponentiell` (E6).

### Neu (16 Slugs, Text wörtlich in `graph.json`)

Familie nur aus den fünf vorhandenen, sonst NULL. `freigegeben_am` NULL. Mindestens drei Aufgaben
im **erstnennenden** Thema (fett).

| Slug | Familie | Themen | Klartext |
|---|---|---|---|
| `linear_statt_exponentiell` | sachaufgaben | **exp** | Schreibt einen exponentiellen Vorgang linear fort: addiert in jedem Schritt denselben Betrag, statt mit demselben Faktor zu multiplizieren. |
| `abnahmefaktor_falsch` | einheiten_massstab | **exp** | Bildet bei einer prozentualen Abnahme den Faktor falsch: 0,2 oder 1,2 statt 0,8 bei 20 % Abnahme. |
| `rate_aus_faktor_falsch` | einheiten_massstab | **exp** | Liest aus dem Wachstumsfaktor die Rate falsch ab: 1,05 als 105 % Zunahme oder 0,8 als 80 % Abnahme. |
| `zeit_statt_perioden` | sachaufgaben | **exp** | Setzt die vergangene Zeit direkt als Hochzahl ein, statt sie durch die Verdopplungs- oder Halbwertszeit zu teilen. |
| `anfangswert_faktor_vertauscht` | – | **exp** | Vertauscht in f(x) = a·bˣ den Anfangswert und den Wachstumsfaktor. |
| `log_falsch_geteilt` | – | **exp** | Rechnet bei bˣ = c mit c : b oder log(c : b) statt mit log c : log b. |
| `sin_cos_vertauscht` | – | **trigo** | Verwechselt Gegenkathete und Ankathete: nimmt den Sinus statt des Kosinus oder umgekehrt, beim Tangens den Kehrwert. |
| `tangens_verwechselt` | – | **trigo** | Nimmt den Tangens, wo Sinus oder Kosinus gebraucht wird, oder umgekehrt: Hypotenuse und Kathete verwechselt. |
| `umkehrfunktion_vergessen` | – | **trigo** | Gibt den Sinus-, Kosinus- oder Tangenswert als Winkel an, statt mit sin⁻¹, cos⁻¹ oder tan⁻¹ den Winkel zu bestimmen. |
| `bogenmass_modus` | – | **trigo**, sinus | Rechnet mit dem Taschenrechner im falschen Winkelmodus: Bogenmaß statt Gradmaß oder umgekehrt. |
| `kosinussatz_vorzeichen` | vorzeichen | **trigo** | Addiert im Kosinussatz den Term 2ab·cos γ, statt ihn abzuziehen. |
| `pythagoras_ohne_rechten_winkel` | – | **trigo** | Wendet den Satz des Pythagoras an, obwohl das Dreieck keinen rechten Winkel hat. |
| `periode_falsch` | – | **sinus** | Verwechselt bei a·sin(b·x) die Periode mit dem Faktor b: gibt b als Periode an oder rechnet 2π · b bzw. p : 2π statt 2π : b. |
| `amplitude_verwechselt` | – | **sinus** | Verwechselt die Amplitude mit dem Abstand zwischen Hoch- und Tiefpunkt (doppelt so groß) oder halbiert sie. |
| `quadrant_vorzeichen` | vorzeichen | **sinus** | Übersieht das Vorzeichen von Sinus oder Kosinus im zweiten bis vierten Viertel des Einheitskreises. |
| `grad_bogen_faktor_falsch` | einheiten_massstab | **sinus** | Rechnet beim Umrechnen zwischen Gradmaß und Bogenmaß mit dem umgekehrten Faktor: 180/π statt π/180 oder umgekehrt. |

Typische Kandidaten aus dem Auftrag: sin/cos vertauscht und Gegen-/Ankathete verwechselt sind am
Zahlenwert **nicht zu trennen** (beide liefern den jeweils anderen Wert) → ein Slug
`sin_cos_vertauscht` (E7). Grad-/Bogenmaß-Modus → `bogenmass_modus`. Wachstumsfaktor = Prozentsatz →
Bestand `wachstumsfaktor_falsch` (Hinrichtung) und neu `rate_aus_faktor_falsch` (Rückrichtung).
Linear statt exponentiell → `prozente_addiert` (Prozent-Kontext) bzw. neu `linear_statt_exponentiell`.

## e) Feld- und Schema-Regeln

Wie K9-Rest (`docs/k9-rest/phase1.md` e) mit diesen Abweichungen:

| Feld | Regel |
|---|---|
| `input_type` | `NUMERIC` oder `MULTI_PART` mit `short_input`-Teilen. Kein MC, kein TERM, keine neuen Formate. |
| `afb` | `'I'` / `'II'` / `'III'`, Begründung je Aufgabe (`afbGrund`); je Knoten 2× I, 3× II, 1× III (Muster K9). |
| `class_level` | 10 (Charge-Feld, setzt die Bibliothek) |
| `curriculum_grade` | 10 (`stoff: 10`), Grund mit KLP-Bezug |
| `competency_content` | exp und sinus `funktionen`, trigo `geometrie` |
| `cluster_id` | exp/sinus `Algebra & Funktionen` (`CLUSTER.algebra`, wie quadratische/lineare Funktionen), trigo `Geometrie & Messen` (`CLUSTER.geo`) |
| `est_duration_sec` | AFB I 45 s, II 60 s, III 90 s, +30 s Sachkontext (macht die Bibliothek) |
| `needs_image` | true nur mit Figur (`koordinatensystem`, nur Punkte, nur in `fkt_exp_term`) |
| `source` / `source_ref` | `edvance_k10_<kurz>` / `<ref>-<knoten>-NN` (z. B. `exp-term-03`, `trigo-seite-01`, `sinus-graph-05`) |
| `unit` | fester Zusatz am Eingabefeld, getippt wird nur die Zahl (nur NUMERIC). Winkel `°`, Prozent `%`. |
| Hinweise | keine |
| Lösung | `task_solution_upsert`, Systemrolle je `do`-Block (`ohne_transaktion`, wie K8/K9) |
| `correct_answers` | jede gleichwertige Schreibweise (macht die Bibliothek): Komma/Punkt, ohne Endnull, `-3`/`−3`/`- 3`, `+3`, Bruch/Dezimal bei `bruch: true`, mit Einheit (`36,87°`, `36,87 °`). **Keine Tausenderpunkte.** |
| Rundung | **Jede Aufgabe nennt die Rundung** („Runde auf zwei Stellen nach dem Komma.", „auf ganze Grad", „auf ganze Jahre"). Zwischenergebnisse werden nicht gerundet; wer mit gerundetem sin-Wert rechnet, trifft `zu_frueh_gerundet`. |
| Winkel und Einheit | **Jede Aufgabe nennt die Einheit des Winkels**: Gradmaß mit `°` im Text („α = 35°"); Bogenmaß ausdrücklich („x = π/6 im Bogenmaß"). Taschenrechner: Winkel-Aufgaben setzen den Taschenrechner voraus wie Kreis/Pythagoras im Bestand (π-Taste/Wurzel-Taste); der Text sagt bei Trigonometrie nicht „ohne Taschenrechner". Exakte Werte (sin 30° = 0,5) nur, wo sie exakt sind. |
| π | Wie K9-Kreis (`befunde-k9-kreis.md`): Wo mit π gerechnet und gerundet wird, Satz „Rechne mit der π-Taste oder mit π ≈ 3,14." und `pi: true` (beide Ergebnisse richtig). Wo π nur als Faktor k·π abgefragt wird, kein π-Satz. |
| Terme | f(x) = a·bˣ und a·sin(b·x) **nicht als Term-Eingabe** (Player kennt nur `ax+b`), sondern a und b als zwei MULTI_PART-Teile. |
| `acceptance` | `canonical` + `equivalents` (`acceptance_equivalents: true`), `known_errors` `{wert: slug}` in allen Schreibweisen |
| `sondierrang` | Rang 1 und 2 je Knoten aus verschiedenen Fehlbildprofilen (macht `vorlauf-build.mjs`) |
| Sprache | keine Mastery-Sprache, keine fiktiven Personen mit Namen, keine echten Firmen/Marken |

### Dreiecke als Text (Trigonometrie)

Feste Benennung, immer vollständig: „Im Dreieck ABC ist der Winkel bei C ein rechter Winkel. Die
Seite a liegt der Ecke A gegenüber, b der Ecke B, c ist die Hypotenuse. α ist der Winkel bei A."
Dann alle gegebenen Maße mit Einheit. Im Kosinussatz-Knoten: „Das Dreieck hat **keinen** rechten
Winkel" bzw. γ ≠ 90° ausdrücklich, Seiten a, b, c gegenüber A, B, C.

### Charge-Felder für `tools/vorlauf-build.mjs`

`batch`, `source`, `auswahl`, `kopf`, `zeitregel`, `class_level: 10`, `acceptance_equivalents: true`,
`ohne_transaktion: true`. Die Bibliothek `tools/k10-rest-lib.mjs` setzt sie alle.

### Werkzeuge dieses Laufs

- `tools/k10-rest-lib.mjs`: aus `k9-rest-lib.mjs`, erweitert um `S`/`C`/`T` (Grad), `SR`/`CR`/`TR`
  (Bogenmaß), `AS`/`AC`/`AT` (Umkehrfunktionen in Grad), `L` (ln), `H(b;x)` (bˣ, beliebiges x) –
  auf 60 Stellen über decimal.js, eingesetzt als Bruch mit 40 Nachkommastellen.
- `tools/k10-rest-substrat.mjs <kurz>`, `tools/k10-rest-pruefung.mjs <kurz>`,
  `tools/k10-rest-graph-check.mjs`, `tools/k10-rest-minuscheck.mjs`, `tools/k10-rest-wegwerf-db.sh`:
  aus den K9-Fassungen, Klasse 10.
- `tools/vorlauf-build.mjs` unverändert aus origin/dev.

## Versionen (zentral vergeben, Erstellungszeitpunkt UTC, `versionen.txt`)

Substrate: `20261003121328` exp, `20261003121329` trigo, `20261003121331` sinus (neu vergeben um 12:13:28–31 UTC, nachdem #196 (20261003120051) in Prod kam).
Aufgaben, Einstieg und skill_thema bekommen ihre Version beim Anlegen der Datei (`date -u`).
