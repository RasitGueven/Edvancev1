# K8-Rest – Phase 1: gemeinsame Bestandsaufnahme

Stand 03.10.2026 · Branch `feat/k8-rest` (Worktree `~/wt/k8-rest`, ab `origin/dev` 42e52a4) ·
Auftrag `W4-k8-rest.md`. Gelesen ausschließlich über `~/bin/dbread` (geprüft:
`transaction_read_only = on`). Letzte Migration in Prod: `20261003101556_lsa_grade_vorzeichen_normalisierung`.

Diese Datei ist die **verbindliche Grundlage** für die vier Themen (Teil 2). Abweichungen
begründet das jeweilige Thema in `docs/k8-rest/entscheidungen.md`.

## a) Bestand (live)

- **59 Knoten**, **105 Kanten**, **98 Fehlbild-Slugs** (vollständige Liste unten), 37 Themen, 12 Einstiege.
- Es gibt **keinen** Knoten zu LGS, Wahrscheinlichkeit, Daten-Kenngrößen, Trapez/Drachen/Raute,
  Neben-/Scheitel-/Stufen-/Wechselwinkel oder Thales. Vorhanden und thematisch nah:
  `geo_winkel_summe` (Kl. 7, Tiefe 3: Winkelsumme Dreieck/Viereck) und `geo_flaeche_dreieck`
  (Kl. 7, Tiefe 4: Dreieck **und Parallelogramm**, drei der sieben ready-Aufgaben sind Parallelogramme).
- Tiefen-Guard: `fundament_tiefe` 1..12, jede Kante echt flacher (`skill_kante_tiefe`).

### Themen-Keys (`public.themen`) – alle ohne Einstieg

| Thema dieses Laufs | thema_key | klasse | stufe | KLP |
|---|---|---|---|---|
| 1 Lineare Gleichungssysteme | `lineare_gleichungen_lgs` | 7 | erste | Ari-6, Ari-9, Ari-10 |
| 2 Daten und Wahrscheinlichkeit | `zufallsexperimente` | 7 | erste | Sto-1 … Sto-5 |
| 3 Flächen | `flaechen_vielecke` | 7 | erste | Geo-8 |
| 4 Thales und Winkelsätze | `winkel_dreiecke` | 7 | erste | Geo-1 … Geo-5 |
| 4 Thales und Winkelsätze | `thales_konstruktionen` | 7 | erste | Geo-3, Geo-6, Geo-7 |

`themen.klasse` ist bei der Ersten Stufe überall 7 (Stufenbeginn). Die neuen Knoten tragen
`klasse_herkunft = 8` (Auftrag; Kölner Gymnasien behandeln die vier Themen in Klasse 8).
Median/Quartile stehen im Katalog unter `daten_streumasse` (Klasse 5, Erprobungsstufe) und
`statistik_beurteilen` (Klasse 9); beide werden in diesem Lauf nicht verändert.

### Bestehende Einstiege (`thema_einstieg`)

`kreis` (2), `lineare_funktionen` (3), `terme_binomische_formeln` (4), `terme_gleichungen` (1),
`zinsrechnung` (2). Keiner der fünf Keys oben hat einen Einstieg.

### Figuren-Generatoren (`scripts/figures`, `upload_figures.GENERATOREN`)

| Generator | kann | kann nicht |
|---|---|---|
| `koordinatensystem` | Fenster, Gitter, Funktionen `linear` (m, b) und `quadratisch`, Punkte mit Label | **keine Strecken, keine Polygone, keine Flächen** |
| `winkel` | genau EIN Winkel: `grad` 1..359, `benennung`, `mit_bogen` | zwei Geraden, Parallelen, Dreiecke, Kreise |

Folgen: **LGS grafisch** zeichnet zwei Geraden (`funktionen: [{typ:'linear',…},{…}]`) und liest den
Schnittpunkt ab. **Flächen**: kein Generator kann Trapez, Drachen oder Raute sauber zeichnen,
deshalb Text mit allen Maßen. **Winkel**: Parallelen-, Dreiecks- und Thales-Situationen gehen nur
als Text. `winkel` taugt höchstens für „Nebenwinkel zu einem abgebildeten Winkel“. Ein neuer
Generator entsteht in diesem Lauf nicht (Befund).

## b) Voraussetzungen je Thema

„ready“ = aktiv und Status `ready`. „Rang“ = Sondierränge unter den ready-Aufgaben. „ohne ke“ =
ready-Aufgaben ohne `acceptance.known_errors` (bei MULTI_PART je Teil geprüft).
Urteil: **trägt** = ≥ 4 ready, Rang 1+2, known_errors vorhanden; **dünn** = weniger;
**fehlt** = kein Knoten.

| skill_key | Tiefe | ready (aktiv) | Rang 1+2 | ohne ke | Urteil | Thema |
|---|---|---|---|---|---|---|
| `gleichung_zweischrittig` | 6 | 6 (6) | 1, 2 | 0 | trägt | LGS |
| `gleichung_beidseitig` | 7 | 5 (7) | 1, 2 | 0 | trägt | LGS |
| `gleichung_neg_koeffizient` | 7 | 5 (5) | 1, 2 | 0 | trägt | LGS |
| `gleichung_modellieren` | 8 | 10 (10) | 1, 2 | 0 (MULTI_PART, ke je Teil) | trägt | LGS |
| `term_minusklammer` | 6 | 6 (6) | 1, 2 | 6 | trägt; **TERM**, Fehlbilder formatbedingt unmöglich | LGS |
| `fkt_linear_graph` | 7 | 0 (6 draft) | – | – | dünn: Lauf Lineare Funktionen, wartet auf Lena, **nicht zugeteilt** | LGS |
| `fkt_linear_steigung` | 5 | 0 (6 draft) | – | – | wie oben, **nicht zugeteilt** | LGS |
| `bruch_kuerzen` | 1 | 7 (7) | 1, 2 | 0 | trägt | Stochastik |
| `bruch_add` | 2 | 7 (7) | 1, 2 | 0 | trägt | Stochastik |
| `bruch_mult` | 2 | 7 (7) | 1, 2 | 0 | trägt | Stochastik |
| `bruch_dezimal` | 4 | 6 (6) | 1, 2 | 0 | trägt | Stochastik |
| `dezimal_div` | 3 | 6 (9) | 1, 2 | 0 | trägt | Stochastik |
| `geo_flaeche_rechteck` | 3 | 6 (6) | 1, 2 | 0 | trägt | Flächen |
| `geo_flaeche_dreieck` | 4 | 7 (9) | 1, 2 | 0 | trägt | Flächen |
| `term_zusammenfassen` | 4 | 7 (7) | 1, 2 | 7 | trägt; **TERM** | Flächen |
| `term_ausmultiplizieren` | 5 | 7 (7) | 1, 2 | 7 | trägt; **TERM** | Flächen |
| `gleichung_einschrittig` | 5 | 6 (6) | 1, 2 | 0 | trägt | Flächen |
| `dezimal_add_sub` | 1 | 8 (11) | 1, 2 | 0 | trägt | Winkel |
| `geo_winkel_summe` | 3 | 6 (6) | 1, 2 | 0 | trägt | Winkel |

## c) Zuteilung

**Keine Voraussetzung ist dünn im Sinne des Auftrags, keine fehlt.** Die dünnen Knoten
(`fkt_linear_*`) sind Drafts eines anderen Laufs und bleiben dort. Die TERM-Knoten tragen
keine known_errors, weil `TERM` kein `acceptance` haben darf (Bestand, Kreis-Phase-0 c4).
Daraus folgt ein Befund, kein Auffüllen: Neue NUMERIC-Aufgaben an einem Termknoten wären
konstruiert und gehören in einen eigenen Lauf. **Kein Thema füllt Voraussetzungen auf.**
Gemeinsam genutzte Voraussetzungen (`gleichung_einschrittig` u. a.) werden nur gelesen.

Fehlende Knoten legt jedes Thema selbst an. Das ist der Kern des Laufs, die Voraussetzungen
stehen ja. Die **Daten-Kenngrößen** (Median, Quartile, Spannweite) bekommen einen Knoten im
Thema Stochastik.

## d) Gemeinsame Fehlbild-Liste

**Wiederverwenden** (vorhanden, unverändert lassen, auch wenn ohne Klartext):

| Thema | Slugs |
|---|---|
| LGS | `klammer_vergessen` (beim Einsetzen ohne Klammer), `vorzeichen_ignoriert`, `falsches_vorzeichen_beim_zusammenfuehren`, `variablen_nicht_zusammengefuehrt`, `koordinaten_vertauscht` (Schnittpunkt abgelesen), `groessen_vertauscht`, `bedingung_unvollstaendig`, `division_vergessen`, `vorzeichen_beim_umstellen` |
| Stochastik | `teilgekuerzt`, `nenner_addiert`, `umgekehrt_geteilt` |
| Flächen | `halbieren_vergessen`, `halbieren_faelschlich`, `falsche_hoehe`, `umfang_statt_flaeche`, `plus_statt_mal`, `klammer_vergessen` |
| Winkel | `summe_180_statt_360`, `summe_360_statt_180`, `differenz_vergessen` |

**Neu, zentral festgelegt** (17 Slugs). `freigegeben_am` bleibt NULL. Jedes Thema legt **nur
seine** Slugs in seinem Substrat an, Text **wörtlich** wie hier. Jeder neue Slug muss in
mindestens drei Aufgaben seines Themas als known_error vorkommen. Familien sind nur
vorhandene (`gleichungen_umformen` …), sonst NULL (Muster Kreis).

| Thema | Slug | Familie | Klartext | Erklärung (für Eltern) |
|---|---|---|---|---|
| LGS | `nicht_alle_glieder_multipliziert` | gleichungen_umformen | Multipliziert beim Additionsverfahren nur einen Teil der Gleichung mit dem Faktor. | Beim Additionsverfahren wird eine Gleichung mit einer Zahl malgenommen, damit sich danach eine Variable weghebt. Das muss für jedes Glied auf beiden Seiten gelten, sonst ist es nicht mehr dieselbe Gleichung. Hier wurde ein Glied vergessen, meist die Zahl auf der rechten Seite. Geübt wird, nach dem Malnehmen jedes Glied einzeln abzuhaken. |
| LGS | `seiten_ungleich_verknuepft` | gleichungen_umformen | Verknüpft die beiden Gleichungen links und rechts unterschiedlich – links subtrahiert, rechts addiert oder umgekehrt. | Beim Additionsverfahren werden zwei Gleichungen Seite für Seite verrechnet: Was links passiert, muss genauso rechts passieren. Hier wurden die linken Seiten voneinander abgezogen, die rechten aber zusammengezählt (oder umgekehrt). Die Variable fällt zwar weg, das Ergebnis stimmt aber nicht. Geübt wird, die Rechenart einmal für beide Seiten festzulegen und dazuzuschreiben. |
| LGS | `loesungsanzahl_verwechselt` | gleichungen_umformen | Verwechselt „keine Lösung“ und „unendlich viele Lösungen“. | Ein Gleichungssystem kann genau eine, keine oder unendlich viele Lösungen haben. Parallele Geraden schneiden sich nie: keine Lösung. Liegen beide Geraden aufeinander, ist jeder Punkt gemeinsam: unendlich viele. Hier wurden die beiden Sonderfälle vertauscht. Geübt wird, das Ende der Rechnung zu lesen: Eine falsche Aussage wie 0 = 5 heißt keine Lösung, eine wahre wie 0 = 0 heißt unendlich viele. |
| LGS | `parallele_uebersehen` | gleichungen_umformen | Nimmt genau eine Lösung an, obwohl die Geraden parallel sind oder aufeinander liegen. | Zwei Geraden schneiden sich genau dann in einem Punkt, wenn ihre Steigungen verschieden sind. Bei gleicher Steigung sind sie parallel oder liegen aufeinander. Hier wurde ein Schnittpunkt angenommen, ohne die Steigungen zu vergleichen. Geübt wird, beide Gleichungen in die Form y = mx + b zu bringen und zuerst die Steigungen zu vergleichen. |
| Stochastik | `verhaeltnis_statt_anteil` | – | Teilt die günstigen durch die übrigen statt durch alle möglichen Ergebnisse. | Eine Wahrscheinlichkeit ist der Anteil der günstigen Ergebnisse an allen möglichen. Liegen 3 rote und 2 blaue Kugeln in einer Urne, ist „rot“ also 3 von 5, nicht 3 zu 2. Hier wurden die günstigen Ergebnisse mit den übrigen verglichen statt mit allen. Geübt wird, zuerst die Gesamtzahl aufzuschreiben. |
| Stochastik | `zuruecklegen_ignoriert` | – | Rechnet beim Ziehen ohne Zurücklegen im zweiten Zug mit der alten Anzahl weiter (oder umgekehrt). | Wird eine gezogene Kugel nicht zurückgelegt, liegt beim zweiten Zug eine Kugel weniger in der Urne, und von der gezogenen Farbe auch eine weniger. Hier wurde der zweite Zug so gerechnet, als wäre noch alles da (oder beim Zurücklegen so, als fehlte eine). Geübt wird, vor jedem Zug den neuen Inhalt der Urne kurz aufzuschreiben. |
| Stochastik | `pfadregel_addiert` | – | Addiert die Wahrscheinlichkeiten entlang eines Pfades, statt sie zu multiplizieren. | Bei Zufallsversuchen in mehreren Stufen wird entlang eines Pfades multipliziert: Erst rot und dann noch einmal rot ist ein Anteil vom Anteil. Wer addiert, bekommt ein zu großes Ergebnis, manchmal sogar mehr als 1, und das kann keine Wahrscheinlichkeit sein. Geübt wird die Merkregel „erst …, dann … heißt mal“. |
| Stochastik | `nur_ein_pfad` | – | Berücksichtigt bei einem Ereignis nur einen von mehreren passenden Pfaden. | Gehören zu einem Ereignis mehrere Pfade, etwa „einmal rot und einmal blau“ in beiden Reihenfolgen, werden ihre Wahrscheinlichkeiten addiert. Hier wurde nur ein Pfad gezählt, das Ergebnis ist deshalb zu klein. Geübt wird, vor dem Rechnen alle passenden Pfade aufzulisten. |
| Stochastik | `gegenereignis_nicht_abgezogen` | – | Gibt die Wahrscheinlichkeit des Gegenereignisses an statt der gesuchten. | Oft ist das Gegenteil leichter zu berechnen, etwa „keine Sechs“ statt „mindestens eine Sechs“. Danach muss das Ergebnis noch von 1 abgezogen werden. Hier fehlt dieser letzte Schritt, die Rechnung davor stimmt. Geübt wird, am Ende noch einmal nachzulesen, nach welchem Ereignis gefragt war. |
| Stochastik | `mittelwert_statt_median` | – | Berechnet den Durchschnitt, obwohl der Median gefragt ist. | Der Median ist der Wert in der Mitte der geordneten Liste, der Durchschnitt die Summe geteilt durch die Anzahl. Bei einzelnen sehr großen oder sehr kleinen Werten liegen beide weit auseinander. Hier wurde der Durchschnitt berechnet. Geübt wird, den Median durch Ordnen und Abzählen zu finden. |
| Stochastik | `median_ohne_sortieren` | – | Nimmt den mittleren Wert der Liste, ohne sie vorher zu ordnen. | Der Median ist nur in einer der Größe nach geordneten Liste der mittlere Wert. Wer die Werte in der gegebenen Reihenfolge abzählt, trifft eine zufällige Zahl. Geübt wird, die Liste immer zuerst zu ordnen und dann abzuzählen. |
| Flächen | `nur_eine_grundseite` | – | Rechnet beim Trapez nur mit einer der beiden parallelen Seiten. | Die Fläche eines Trapezes ist der Mittelwert der beiden parallelen Seiten mal der Höhe. Hier wurde nur eine der beiden Seiten verwendet, so als wäre das Trapez ein Parallelogramm. Geübt wird, zuerst beide parallelen Seiten zu markieren. |
| Flächen | `teilflaeche_vergessen` | – | Lässt bei einer zusammengesetzten Figur eine Teilfläche weg. | Zusammengesetzte Figuren werden in einfache Teile zerlegt, deren Flächen man addiert oder abzieht. Hier fehlt eine Teilfläche im Ergebnis. Geübt wird, die Zerlegung erst vollständig zu skizzieren und jede Teilfläche abzuhaken. |
| Winkel | `winkelbeziehung_verwechselt` | – | Hält zwei Winkel für gleich groß, die sich zu 180° ergänzen, oder umgekehrt. | Scheitelwinkel sowie Stufen- und Wechselwinkel an Parallelen sind gleich groß, Nebenwinkel ergänzen sich zu 180°. Hier wurde die eine Beziehung mit der anderen verwechselt. Das Ergebnis passt dann oft nicht zur Lage: Aus einem spitzen Winkel wird ein stumpfer. Geübt wird, vor dem Rechnen zu benennen, welche Winkelbeziehung vorliegt. |
| Winkel | `basiswinkel_falsch_zugeordnet` | – | Verwechselt im gleichschenkligen Dreieck den Winkel an der Spitze mit einem Basiswinkel. | Im gleichschenkligen Dreieck sind die beiden Winkel an der Grundseite gleich groß, der dritte Winkel liegt an der Spitze zwischen den gleich langen Seiten. Hier wurde der gegebene Winkel der falschen Ecke zugeordnet. Geübt wird, zuerst die gleich langen Seiten zu markieren. |
| Winkel | `rechter_winkel_falsche_ecke` | – | Setzt beim Satz des Thales den rechten Winkel an die falsche Ecke. | Liegt eine Dreiecksseite als Durchmesser in einem Kreis und die dritte Ecke auf dem Kreis, dann ist der Winkel an dieser dritten Ecke ein rechter. Hier wurde der rechte Winkel an einer Ecke des Durchmessers angenommen. Geübt wird, den Durchmesser zu suchen und den Winkel gegenüber zu markieren. |
| Winkel | `aussenwinkel_verwechselt` | – | Rechnet mit dem Innenwinkel, wo der Außenwinkel gefragt ist, oder umgekehrt. | Der Außenwinkel an einer Dreiecksecke ergänzt den Innenwinkel dort zu 180°. Er ist so groß wie die beiden anderen Innenwinkel zusammen. Hier wurde der Innenwinkel statt des Außenwinkels angegeben (oder umgekehrt). Geübt wird, den gefragten Winkel in einer Skizze einzuzeichnen. |

(`aussenwinkel_verwechselt` ist der 17. Slug; ihn braucht das Winkel-Thema nur, wenn es
Außenwinkel-Aufgaben stellt. Sonst wird er nicht angelegt und im Befund vermerkt.)

## e) Schema- und Feldregeln (aus Bestand, K8-Zins, K8-Linear, K9-Kreis)

| Feld | Regel |
|---|---|
| `afb` | `'I'` / `'II'` / `'III'` |
| `class_level` | 8 (Charge-Feld `class_level: 8`) |
| `curriculum_grade` (Stoffanker) | 8, Grund: KLP-Bezug |
| `competency_content` | am Item: LGS `arithmetik_algebra`, Stochastik `stochastik`, Flächen und Winkel `geometrie` |
| `competency_process` | Operieren / Modellieren / Problemlösen / Argumentieren / Darstellen / Kommunizieren |
| `cluster_id` | LGS `edbb548a-54d9-4a8f-8be4-3052f9025524` (Algebra & Funktionen), Stochastik `9fdfed01-ebda-4c79-89ea-5accacefee93` (Daten & Zufall), Flächen/Winkel `3156b22e-ad3b-46c8-8c76-4155176cc52a` (Geometrie & Messen) |
| `est_duration_sec` | AFB I 45 s, II 60 s, III 90 s, +30 s Sachkontext; MULTI_PART: `zeit_teile` summiert genau dazu |
| `needs_image` | true nur mit Figur |
| `source` / `source_ref` | `edvance_k8_lgs` / `lgs-<knoten>-NN`, `edvance_k8_stoch` / `stoch-…`, `edvance_k8_flaeche` / `flaeche-…`, `edvance_k8_winkel` / `winkel-…` |
| `unit` | fester Zusatz am Eingabefeld (`cm²`, `°`), getippt wird nur die Zahl |
| `status` | `draft`, Kennzeichen `vorbefuellt` (macht `vorlauf-build.mjs`) |
| Hinweise | keine (`leer.hints` mit Grund) |
| Lösung | über `task_solution_upsert`, Systemrolle per `set_config('request.jwt.claim.role','service_role',true)` |
| `correct_answers` | **jede** gleichwertige Schreibweise: Komma/Punkt, `-3`/`−3`/`- 3`, positiv auch `+3`, Bruch gekürzt **und** ungekürzt (außer die Aufgabe verlangt „gekürzt“), Dezimal, wo endlich; bei Wahrscheinlichkeiten zusätzlich Prozent (`60 %`, `60%`). **Keine Tausenderpunkte** (die Bewertung liest „1.102,50“ nicht) |
| `acceptance` | `canonical` = erste Form, `equivalents` = übrige (Charge-Feld `acceptance_equivalents: true`), `known_errors` Objektform `{falscher_wert: slug}`, **jeder falsche Wert in allen Schreibweisen** |
| MULTI_PART | `correct_answers` je Teil `{"1": [...], "2": [...]}`, `known_errors` je Teil; LGS: Teil 1 = x, Teil 2 = y |
| MC | `basis.options` `[{id:'a',label:…}]`, `correct_answers` `["b"]`, known_errors `{"a": slug}`; MC-Teil in MULTI_PART: `kind: 'mc'` + `options` |
| `sondierrang` | Rang 1 und 2 je Knoten aus verschiedenen Fehlbildprofilen, Rest NULL (`vorlauf-build.mjs`, `docs/sondierrang_vorschlag.md`) |

**Charge-Felder für `tools/vorlauf-build.mjs`:** `batch`, `source`, `auswahl`, `zeitregel`,
`kopf` (Kopfzeilen der Migration), `class_level: 8`, `acceptance_equivalents: true`,
`ohne_transaktion: true` (neu in diesem Lauf), `ohne_sondierrang: []` (kein Auffüllen).

### Neu in diesem Lauf an den Werkzeugen

- `vorlauf-build.mjs` kennt jetzt MC (`basis.options`), MC-Teile (`parts[].options`),
  `basis.figur.generator` (`koordinatensystem` | `winkel`) und `ohne_transaktion`: Die Datei hat
  kein `begin/commit` (Auftrag: `mig` spielt mit `psql -1` ein). CI und Wegwerf-DB spielen ohne
  Klammer ein, deshalb setzt jeder Lösungs-Upsert die Systemrolle in einem eigenen `do`-Block.
  Ohne die neuen Felder bleibt die Ausgabe byte-gleich (Vorlauf, Linear, Kreis neu erzeugt: kein Diff).
- `tools/blind-loeser/exportiere.mjs` gibt bei MC die Optionen mit (id + Text), sonst sähe der
  Blind-Löser die Auswahl nicht.
- `tools/k8-rest-wegwerf-db.sh <db> [eigene Dateien]`: Wegwerf-DB aus Basis plus eigenen Dateien,
  zweiter Lauf, Zeilenzahlen gleich = idempotent.

### Bekannte Eigenheit der Wegwerf-DB

Lokal stehen 46 statt 98 Fehlbilder (die Alt-Slugs kommen aus einem Datenimport, nicht aus
Migrationen) und keine `skill_clusters`. Prüfskripte schalten diese beiden Prüfungen über die
psql-Variable `lokal` ab (`-v lokal=true`). Gegen Prod laufen sie ohne Variable vollständig.

## Versionen (zentral vergeben, Erstellungszeitpunkt UTC)

| # | Version | Name |
|---|---|---|
| 1 | 20261003104943 | substrat_k8_lgs |
| 2 | 20261003104944 | substrat_k8_stoch |
| 3 | 20261003104945 | substrat_k8_flaeche |
| 4 | 20261003104946 | substrat_k8_winkel |
| 5 | 20261003104947 | aufgaben_k8_lgs |
| 6 | 20261003104948 | aufgaben_k8_stoch |
| 7 | 20261003104949 | aufgaben_k8_flaeche |
| 8 | 20261003104950 | aufgaben_k8_winkel |
| 9 | 20261003104951 | thema_einstieg_k8_rest |

Geprüft: keine der Versionen in `schema_migrations` (Prod, lesend), keine in einem Git-Branch.

## Anhang: alle 98 Fehlbild-Slugs (live)

| Slug | Familie | Klartext | freigegeben |
|---|---|---|---|
| `abgeschnitten` | – | – | nein |
| `achsenabschnitt_verwechselt` | gleichungen_umformen | Gibt die Nullstelle als y-Achsenabschnitt an oder umgekehrt. | nein |
| `addiert_statt_subtrahiert` | gleichungen_umformen | Addiert die Konstante auf beiden Seiten statt sie abzuziehen. | ja |
| `additiv_gekuerzt` | – | – | nein |
| `anteil_falsch_verteilt` | sachaufgaben | Zählt den Anteil falsch – der eigene Anteil fehlt in der Summe. | ja |
| `antiproportional_verwechselt` | sachaufgaben | Proportional und antiproportional vertauscht. | ja |
| `b_ignoriert` | gleichungen_umformen | Teilt sofort, ohne die Konstante vorher wegzurechnen. | ja |
| `basis_exponent_vertauscht` | – | – | nein |
| `bedingung_unvollstaendig` | sachaufgaben | Lässt beim Aufstellen einen Teil der Textangabe weg. | ja |
| `betrag_fehler` | vorzeichen | Betrag richtig, Vorzeichen des Ergebnisses gekippt. | ja |
| `bezug_vertauscht` | – | – | nein |
| `dezimal_statt_sexagesimal` | – | – | nein |
| `dezimalverschiebung` | sachaufgaben | Multipliziert mit der Prozentzahl, ohne durch 100 zu teilen. | ja |
| `differenz_ignoriert` | sachaufgaben | Verteilt gleichmäßig, der genannte Unterschied entfällt. | ja |
| `differenz_vergessen` | – | – | nein |
| `division_vergessen` | gleichungen_umformen | Umformung richtig, der letzte Schritt (Division durch den Koeffizienten) fehlt. | ja |
| `einheit_ignoriert` | – | – | nein |
| `einheit_uebersprungen` | einheiten_massstab | Rechnet gar nicht um, die Ausgangszahl bleibt stehen. | ja |
| `einheit_verrutscht` | sachaufgaben | Multipliziert den Grundwert direkt mit der neuen Anzahl, der Zwischenschritt fehlt. | ja |
| `faktor_100_vergessen` | – | – | nein |
| `faktor_hundert_statt_sechzig` | – | – | nein |
| `faktor_hundert_statt_tausend` | – | – | nein |
| `faktor_zehn_daneben` | einheiten_massstab | Ergebnis um den Faktor 10 daneben, in beide Richtungen. | ja |
| `faktorisierung_unvollstaendig` | gleichungen_umformen | Klammert aus, erkennt die binomische Form darin aber nicht. | nein |
| `falsche_gegenoperation` | gleichungen_umformen | Wiederholt die im Term sichtbare Rechenart statt sie umzukehren. | ja |
| `falsche_groesse_beantwortet` | sachaufgaben | Rechnet richtig, gibt aber die andere gesuchte Größe an. | ja |
| `falsche_hoehe` | – | – | nein |
| `falsche_operation` | – | – | nein |
| `falsche_richtung` | sachaufgaben | Rechnet den Kehrwert oder verschiebt das Komma um zwei Stellen. | ja |
| `falsche_stelle` | – | – | nein |
| `falschen_gestuerzt` | – | – | nein |
| `falscher_bezug` | – | – | nein |
| `falsches_vorzeichen_beim_zusammenfuehren` | vorzeichen | x-Terme richtig zusammengefasst, die Konstante addiert statt subtrahiert. | ja |
| `flaeche_statt_umfang` | – | – | nein |
| `fuehrende_null_ignoriert` | – | – | nein |
| `groessen_vertauscht` | sachaufgaben | Vertauscht Grundbetrag und Rate beim Aufstellen. | ja |
| `grundwert_verwechselt` | – | – | nein |
| `halbieren_faelschlich` | – | – | nein |
| `halbieren_vergessen` | – | – | nein |
| `hauptnenner_bei_mult` | – | – | nein |
| `immer_aufgerundet` | – | – | nein |
| `klammer_falsch_gesetzt` | gleichungen_umformen | Klammer gesetzt, aber um den falschen Teil oder mit falschem Faktor. | ja |
| `klammer_vergessen` | gleichungen_umformen | Setzt keine Klammer, die Operation trifft nur einen Teil des Terms. | ja |
| `komma_als_trenner` | – | – | nein |
| `komma_ignoriert` | – | – | nein |
| `komma_nicht_verschoben` | – | – | nein |
| `kommastellen_zu_viel` | – | – | nein |
| `kommastellen_zu_wenig` | – | – | nein |
| `koordinate_vorzeichen_verloren` | vorzeichen | Koordinate richtig abgelesen, aber das Minus fehlt. | nein |
| `koordinaten_vertauscht` | – | Liest x- und y-Koordinate in vertauschter Reihenfolge ab. | nein |
| `kreisanteil_falsch` | – | Rechnet beim Kreisausschnitt mit dem ganzen Kreis oder dreht den Anteil um. | nein |
| `linearer_faktor` | einheiten_massstab | Nutzt den linearen Umrechnungsfaktor, wo der quadrierte gilt. | ja |
| `liter_kubik_falsch` | – | – | nein |
| `m_b_vertauscht` | gleichungen_umformen | Liest Steigung und y-Achsenabschnitt vertauscht aus der Gleichung ab. | nein |
| `mal_exponent` | – | – | nein |
| `mal_zwei_vergessen` | – | – | nein |
| `mult_add_verwechslung` | rechenreihenfolge | Führt die Strichoperation als Punktoperation aus. | ja |
| `multipliziert_statt_dividiert` | – | – | nein |
| `nenner_addiert` | – | – | nein |
| `nenner_addiert_zaehler_ok` | – | – | nein |
| `nicht_gestuerzt` | – | – | nein |
| `nur_eine_seite` | – | – | nein |
| `nur_einmal_addiert` | – | – | nein |
| `nur_prozentwert` | – | – | nein |
| `oberflaeche_statt_volumen` | – | – | nein |
| `pi_vergessen` | – | Lässt die Kreiszahl π in der Rechnung weg. | nein |
| `plus_statt_mal` | – | – | nein |
| `prozente_addiert` | sachaufgaben | Zählt Prozentsätze einfach zusammen, statt die Änderungen nacheinander auszurechnen. | nein |
| `quadrat_gliedweise` | gleichungen_umformen | Quadriert die Klammer gliedweise – das mittlere Glied 2ab fehlt. | nein |
| `quadratdifferenz_vorzeichen` | vorzeichen | Vorzeichen im Ergebnis gekippt – a²+b² statt a²−b². | nein |
| `radius_durchmesser_verwechselt` | – | Setzt den Durchmesser ein, wo der Radius gebraucht wird, oder umgekehrt. | nein |
| `richtung_vertauscht` | einheiten_massstab | Teilt durch die Maßstabszahl statt zu multiplizieren. | ja |
| `seite_vergessen` | – | – | nein |
| `seiten_verwechselt` | vorzeichen | Subtrahiert in umgekehrter Reihenfolge, Ergebnis mit falschem Vorzeichen. | ja |
| `steigung_kehrwert` | gleichungen_umformen | Teilt die waagerechte durch die senkrechte Änderung – die Steigung steht auf dem Kopf. | nein |
| `stellenwert_ignoriert` | – | – | nein |
| `summe_180_statt_360` | – | – | nein |
| `summe_360_statt_180` | – | – | nein |
| `teilgekuerzt` | – | – | nein |
| `text_direkt_gerechnet` | sachaufgaben | Wendet die Operationen aus dem Text direkt an, statt sie umzukehren. | ja |
| `uebertrag_vergessen` | – | – | nein |
| `umfang_falsch_modelliert` | sachaufgaben | Setzt den Umfang mit zwei statt vier Seiten an. | ja |
| `umfang_statt_flaeche` | – | – | nein |
| `umgekehrt_geteilt` | – | – | nein |
| `variablen_nicht_zusammengefuehrt` | gleichungen_umformen | Teilt durch den linken Koeffizienten statt durch die Differenz beider. | ja |
| `volumen_statt_oberflaeche` | – | – | nein |
| `vorrang_ignoriert` | rechenreihenfolge | Rechnet strikt von links nach rechts, Punkt vor Strich ignoriert. | ja |
| `vorzeichen_beim_umstellen` | vorzeichen | Betrag richtig, das Minus des Koeffizienten bleibt am Ergebnis hängen. | ja |
| `vorzeichen_ignoriert` | vorzeichen | Lässt die Minuszeichen weg und addiert die Beträge. | ja |
| `vorzeichen_potenz` | – | – | nein |
| `wachstumsfaktor_falsch` | einheiten_massstab | Bildet den Faktor für eine prozentuale Zunahme falsch, zum Beispiel 1,5 statt 1,05 bei 5 %. | nein |
| `wurzel_halbiert` | – | – | nein |
| `zaehler_nicht_erweitert` | – | – | nein |
| `zeitfaktor_vergessen` | sachaufgaben | Rechnet die Zinsen für ein ganzes Jahr, obwohl das Geld nur einige Monate oder Tage angelegt ist. | nein |
| `ziffern_gelesen` | – | – | nein |
| `zinszeit_falsch_umgerechnet` | einheiten_massstab | Rechnet Monate oder Tage mit dem falschen Teiler in Jahre um, zum Beispiel durch 100 statt durch 12 oder 360. | nein |
| `zu_frueh_gerundet` | sachaufgaben | Rundet ein Zwischenergebnis und rechnet mit dem gerundeten Wert weiter – das Endergebnis weicht deshalb leicht ab. | nein |
| `zwei_kanten` | – | – | nein |
