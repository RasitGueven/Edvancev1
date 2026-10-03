# K9-Rest – Phase 1: gemeinsame Planung

Stand 03.10.2026 · Branch `feat/k9-rest` (Worktree `~/wt/k9-rest`, ab `origin/dev` 42e52a4) ·
Auftrag `W4-k9-rest.md`. Gelesen ausschließlich über `~/bin/dbread`. Letzte Migration in Prod:
`20261003101556_lsa_grade_vorzeichen_normalisierung` (Kreis-Substrat und -Aufgaben sind eingespielt).

Diese Datei ist die **verbindliche Grundlage** für Teil 2. Der Graph steht maschinenlesbar in
[`graph.json`](graph.json), geprüft mit `node tools/k9-rest-graph-check.mjs <bestand.json>`.
Entscheidungen mit Begründung: [`entscheidungen.md`](entscheidungen.md).

## a) Bestand (live, per dbread)

- **59 Knoten**, **105 Kanten**, Tiefe max. 9 (`prozent_zins_zinseszins`), **98 Fehlbild-Slugs**,
  37 Themen, 12 Einstiegszeilen (kreis 2, lineare_funktionen 3, terme_binomische_formeln 4,
  terme_gleichungen 1, zinsrechnung 2).
- Kreis ist fertig: `geo_kreis_umfang`/`_flaeche` (Tiefe 6), `_rueck`/`_sektor`/`_zusammen` (7),
  24 Aufgaben im Status `draft`.
- Kein Knoten zu Wurzeln, Potenzgesetzen, quadratischen Funktionen/Gleichungen, Pythagoras,
  Körpern außer dem Quader, Stochastik oder Ähnlichkeit. `potenzen` (Kl. 7, Tiefe 4) enthält
  einfache Quadratwurzeln (√36, √144, Fehlbild `wurzel_halbiert`) und bleibt unverändert.

### Themen-Keys dieses Laufs (`public.themen`, alle `stufe = 'zweite'`, klasse 9, ohne Einstieg)

| Thema | thema_key | KLP im Katalog |
|---|---|---|
| 1 Reelle Zahlen, Quadratwurzeln | `reelle_zahlen` | Ari-2, Ari-5, Ari-6, Ari-7, Ari-9 |
| 2 Potenzen | `potenzen` | Ari-1, Ari-3, Ari-4, Ari-5 |
| 3a Quadratische Gleichungen | `quadratische_gleichungen` | Ari-8, Ari-11 |
| 3b Quadratische Funktionen | `quadratische_funktionen` | Fkt-1 … Fkt-9, Fkt-12 |
| 4 Satz des Pythagoras | `pythagoras` | Geo-1, Geo-10 |
| 5 Körper | `prismen_zylinder` und `koerper_pyramide_kegel_kugel` | Geo-5, Geo-6 (, Geo-10) |
| 6 Bedingte Wahrscheinlichkeit | `bedingte_wahrscheinlichkeit` | Sto-3, Sto-4, Sto-5 |
| 7 Ähnlichkeit, Strahlensätze | `aehnlichkeit` | Geo-2, Geo-9 |

Thema 3 hat im Katalog zwei Keys; es wird deshalb als zwei Themen geführt (je 4–5 Knoten,
eigene Migrationen `quadrgl` und `quadrfkt`). Ebenso Körper mit zwei Keys, aber einer Charge.

### Darstellung im Schülerpfad (gelesen in `~/edvance-app`)

- Der Tablet-Player (`LsaAufgabe` → `Buehne`) setzt den Aufgabentext als **reinen Text**:
  **keine Markdown-Tabellen, kein LaTeX**. Zeilenumbrüche wirken. Vierfeldertafeln deshalb als Text
  mit benannten Feldern (Zeilen „Mädchen: …"), gesuchte Felder als MULTI_PART-Teile.
- Eingabe: Zahl (Ziffernblock mit Komma und Minus), Bruch (`3/4`) oder linearer Term `ax+b`.
  **Kein √, keine Hochzahl, keine Scheitelpunktform als Eingabe.** Antworten sind deshalb immer
  Zahlen; Scheitelpunkt, zwei Lösungen, a·10ⁿ werden als MULTI_PART-Teile abgefragt.
- Hochzahlen im Text als Unicode (`2⁻³`, `10⁴`, `x²`), Wurzeln als `√` mit Klammer (`√(9 + 16)`).

### Figuren (`scripts/figures`)

`koordinatensystem`: Fenster (ganzzahlig), Gitter, Funktionen `linear {m,b}` und
`quadratisch {a,b,c}` (Normalform!), Punkte mit Label. **Keine Strecken, keine Polygone.**
`winkel`: genau ein Winkel. Damit: Parabeln über `quadratisch`, Pythagoras im
Koordinatensystem nur über Punkte (Abstand zweier Punkte). Dreiecke, Körper, Strahlensätze als
Text mit allen Maßen. Kein neuer Generator.

## b) Graph: 37 neue Knoten, 57 Kanten, Tiefe 5…9

Jede Kante echt flacher, Tiefe = 1 + tiefste direkte Voraussetzung, keine transitiv redundante
Kante, keine Kante auf Knoten aus `feat/k8-rest`. Begründung je Kante in `graph.json` und im
Kommentar der Substrat-Migration.

| Thema | Knoten | Tiefe | direkte Voraussetzungen |
|---|---|---|---|
| wurzel | `zahl_wurzel_quadrat` Quadratwurzel als Umkehrung des Quadrierens | 5 | potenzen (4) |
| | `zahl_wurzel_naeherung` Wurzeln abschätzen und Näherungswerte | 6 | zahl_wurzel_quadrat, runden_ueberschlag (2) |
| | `zahl_wurzel_irrational` Rationale und irrationale Zahlen | 6 | zahl_wurzel_quadrat, bruch_dezimal (4) |
| | `zahl_wurzel_gesetze` Wurzelgesetze für Produkt und Quotient | 6 | zahl_wurzel_quadrat |
| | `zahl_wurzel_teilweise` Teilweise die Wurzel ziehen | 7 | zahl_wurzel_gesetze |
| potenz | `zahl_potenz_gesetze` Potenzgesetze | 5 | potenzen (4) |
| | `zahl_potenz_negativ` Negative Hochzahlen und Hochzahl null | 6 | zahl_potenz_gesetze, bruch_dezimal (4) |
| | `zahl_potenz_zehner` Zehnerpotenzen und wissenschaftliche Schreibweise | 7 | zahl_potenz_negativ |
| | `zahl_potenz_rechnen` Rechnen in wissenschaftlicher Schreibweise | 8 | zahl_potenz_zehner |
| quadrgl | `gleichung_quadr_wurzel` Quadratische Gleichungen durch Wurzelziehen | 7 | zahl_wurzel_quadrat (5), gleichung_zweischrittig (6) |
| | `gleichung_quadr_faktor` … durch Ausklammern (Nullprodukt) | 8 | term_ausklammern (7), gleichung_einschrittig (5) |
| | `gleichung_quadr_formel` Lösungsformel (p-q- bzw. abc-Formel) | 8 | gleichung_quadr_wurzel, term_einsetzen (5) |
| | `gleichung_quadr_anzahl` Anzahl der Lösungen (Diskriminante) | 9 | gleichung_quadr_formel |
| quadrfkt | `fkt_quadr_parabel` Normalparabel verschieben und strecken | 6 | term_einsetzen (5), geo_koordinaten (2) |
| | `fkt_quadr_scheitel` Scheitelpunkt aus der Scheitelpunktform | 7 | fkt_quadr_parabel |
| | `fkt_quadr_normalform` Von der Normalform zur Scheitelpunktform | 8 | fkt_quadr_scheitel, term_binom_quadrat (7) |
| | `fkt_quadr_nullstellen` Nullstellen quadratischer Funktionen | 9 | gleichung_quadr_formel (8), fkt_quadr_parabel |
| | `fkt_quadr_extrem` Extremwertaufgaben | 9 | fkt_quadr_normalform, gleichung_modellieren (8) |
| pythagoras | `geo_pythagoras_hypotenuse` Hypotenuse | 6 | zahl_wurzel_quadrat (5) |
| | `geo_pythagoras_kathete` Kathete | 7 | geo_pythagoras_hypotenuse |
| | `geo_pythagoras_umkehrung` Rechtwinklig? Umkehrung | 7 | geo_pythagoras_hypotenuse |
| | `geo_pythagoras_abstand` Abstand zweier Punkte im Koordinatensystem | 7 | geo_pythagoras_hypotenuse, geo_koordinaten (2) |
| | `geo_pythagoras_anwendung` Pythagoras in Figuren und Körpern | 8 | geo_pythagoras_kathete |
| koerper | `geo_koerper_prisma` Prisma | 5 | geo_volumen_quader (4), geo_flaeche_dreieck (4) |
| | `geo_koerper_zylinder` Zylinder | 7 | geo_koerper_prisma, geo_kreis_flaeche (6), geo_kreis_umfang (6) |
| | `geo_koerper_pyramide` Pyramide | 6 | geo_koerper_prisma |
| | `geo_koerper_kegel` Kegel | 8 | geo_koerper_zylinder, geo_koerper_pyramide, geo_pythagoras_hypotenuse (6) |
| | `geo_koerper_kugel` Kugel | 7 | geo_kreis_flaeche (6) |
| bedingt | `stoch_bedingt_vierfeld` Vierfeldertafel ergänzen | 5 | bruch_dezimal (4) |
| | `stoch_bedingt_wkeit` Bedingte Wahrscheinlichkeit aus der Vierfeldertafel | 6 | stoch_bedingt_vierfeld |
| | `stoch_bedingt_unabhaengig` Stochastische Unabhängigkeit prüfen | 7 | stoch_bedingt_wkeit |
| | `stoch_bedingt_umkehr` Bedingte Wahrscheinlichkeiten umkehren (Tests) | 7 | stoch_bedingt_wkeit, prozent_prozentwert (6) |
| | `stoch_bedingt_irrefuehrend` Irreführende Aussagen und Darstellungen | 8 | stoch_bedingt_wkeit, prozent_prozentsatz (7) |
| aehnlich | `geo_aehnlich_streckfaktor` Streckfaktor und zentrische Streckung | 6 | geo_massstab (5) |
| | `geo_aehnlich_flaeche` Flächen und Volumen bei Ähnlichkeit | 7 | geo_aehnlich_streckfaktor, potenzen (4) |
| | `geo_aehnlich_strahlen_abschnitt` Erster Strahlensatz | 7 | geo_aehnlich_streckfaktor, gleichung_einschrittig (5) |
| | `geo_aehnlich_strahlen_parallel` Zweiter Strahlensatz | 8 | geo_aehnlich_strahlen_abschnitt |

Tiefen-Reserve: max. 9 von 12. Nichts musste zusammengelegt werden.

**Fachlich fehlende Kanten auf Knoten des K8-Laufs** (bewusst nicht gesetzt, Befund):
`stoch_bedingt_*` → Laplace/Baumdiagramm (K8 Stochastik); `geo_aehnlich_strahlen_*` →
Stufen-/Wechselwinkel an Parallelen (K8 Winkel); `geo_pythagoras_anwendung` → Trapez/Raute
(K8 Flächen). Nachtragen, sobald beide Läufe eingespielt sind.

## c) Voraussetzungen aus dem Fundament

„ready" = aktiv und `ready` (in Klammern: aktiv gesamt). „Rang" = Sondierränge unter den ready-Aufgaben.
„ohne ke" = ready-Aufgaben ohne `acceptance.known_errors`. Urteil: **trägt** = ≥ 4 ready, Rang 1+2,
known_errors; **dünn** = weniger; **fehlt** = kein Knoten.

| skill_key | Tiefe | ready (aktiv) | Rang 1+2 | ohne ke | Urteil | gebraucht von |
|---|---|---|---|---|---|---|
| `potenzen` | 4 | 3 (24) | 1, 2 | 0 | trägt inhaltlich; 21 Entwürfe (Fundament-AFB I, Zins) warten auf Freigabe | wurzel, potenz, aehnlich |
| `runden_ueberschlag` | 2 | 10 (13) | 1, 2 | 0 | trägt | wurzel |
| `bruch_dezimal` | 4 | 6 (6) | 1, 2 | 0 | trägt (auch K8 Stochastik, nur gelesen) | wurzel, potenz, bedingt |
| `gleichung_zweischrittig` | 6 | 6 (6) | 1, 2 | 0 | trägt (auch K8 LGS) | quadrgl |
| `gleichung_einschrittig` | 5 | 6 (6) | 1, 2 | 0 | trägt (auch K8 Flächen) | quadrgl, aehnlich |
| `term_ausklammern` | 7 | 6 (6) | 1, 2 | **6** | trägt; **MC ohne acceptance** → Befund, kein Auffüllen | quadrgl |
| `term_einsetzen` | 5 | 0 (6 draft) | – (Rang unter Entwürfen) | – | dünn: Vorlauf wartet auf Lena, **nicht zugeteilt** | quadrgl, quadrfkt |
| `geo_koordinaten` | 2 | 0 (6 draft) | – | – | dünn: Vorlauf wartet auf Lena, **nicht zugeteilt** | quadrfkt, pythagoras |
| `term_binom_quadrat` | 7 | 1 (6) | – | 0 | dünn: Binom-Lauf wartet auf Lena, **nicht zugeteilt** | quadrfkt |
| `gleichung_modellieren` | 8 | 10 (10) | 1, 2 | 0 (MULTI_PART, ke je Teil) | trägt | quadrfkt |
| `geo_volumen_quader` | 4 | 7 (9) | 1, 2 | 0 | trägt | koerper |
| `geo_flaeche_dreieck` | 4 | 7 (9) | 1, 2 | 0 | trägt (auch K8 Flächen) | koerper |
| `geo_kreis_flaeche`, `geo_kreis_umfang` | 6 | 0 (je 6 draft) | – | – | dünn: Kreis-Lauf wartet auf Lena, **nicht zugeteilt** | koerper |
| `prozent_prozentwert` | 6 | 6 (9) | 1, 2 | 0 | trägt | bedingt |
| `prozent_prozentsatz` | 7 | 6 (9) | 1, 2 | 0 | trägt | bedingt |
| `geo_massstab` | 5 | 6 (11) | 1, 2 | 0 | trägt | aehnlich |

**Zuteilung zum Auffüllen: keine.** Alle „dünnen" Voraussetzungen sind Entwürfe anderer Läufe
mit Rang 1+2 und known_errors; ihnen fehlt Lenas Freigabe, nicht Inhalt. Weitere Entwürfe
daneben würden die Freigabe-Warteschlange nur verlängern. `term_ausklammern` hat sechs ready
MC-Aufgaben ohne `acceptance`; die Fehlbilder ließen sich über die Options-IDs nachtragen — das
ist ein UPDATE bestehender Aufgaben und nicht Teil dieses Laufs (Befund). Gleiche Linie wie
`docs/k8-rest/phase1.md` c) für die TERM-Knoten. Kein Knoten fehlt.

## d) Zentrale Fehlbild-Liste

### Wiederverwenden (Bestand, unverändert lassen, auch ohne Klartext)

| Thema | Slugs (Bedeutung im Bestand) |
|---|---|
| wurzel | `wurzel_halbiert` (√36 → 18), `mal_exponent` (a² als 2a), `abgeschnitten` (abgeschnitten statt gerundet), `zu_frueh_gerundet`, `vorzeichen_potenz` |
| potenz | `mal_exponent`, `basis_exponent_vertauscht`, `vorzeichen_potenz` ((−2)² vs −2²), `faktor_zehn_daneben` (Zehnerexponent um 1 daneben), `komma_nicht_verschoben` |
| quadrgl | `vorzeichen_potenz`, `division_vergessen`, `falsche_gegenoperation`, `quadrat_gliedweise` |
| quadrfkt | `vorzeichen_potenz`, `vorrang_ignoriert` (a·(x−d)² falsch ausgewertet), `koordinaten_vertauscht`, `falsche_groesse_beantwortet` (x statt Extremwert), `halbieren_vergessen`, `quadrat_gliedweise` |
| pythagoras | `vorzeichen_ignoriert` (Koordinatendifferenz über Achsen), `halbieren_vergessen`, `falsche_groesse_beantwortet` |
| koerper | `pi_vergessen`, `radius_durchmesser_verwechselt`, `oberflaeche_statt_volumen`, `volumen_statt_oberflaeche`, `mal_zwei_vergessen` (eine Grundfläche fehlt), `halbieren_vergessen` (Dreiecksgrundfläche), `falsche_hoehe` (Körper- statt Seitenhöhe), `zu_frueh_gerundet` |
| bedingt | `bezug_vertauscht` (Kehrwert des Anteils), `falsche_groesse_beantwortet` |
| aehnlich | `linearer_faktor` (k statt k² bzw. k³), `falsche_groesse_beantwortet` |

Andere Bestands-Slugs nur, wenn sie wörtlich passen (Liste: `fehlbild-bestand.json`).

### Neu (22 Slugs, Text wörtlich in `graph.json`)

Familie nur aus den fünf vorhandenen, sonst NULL (Muster Kreis). `freigegeben_am` NULL. Jeder
Slug steht in jedem Substrat, dessen Thema ihn braucht (on conflict do nothing, wortgleich).
Mindestens drei Aufgaben im **erstnennenden** Thema (Spalte „Thema", fett).

| Slug | Familie | Themen | Klartext |
|---|---|---|---|
| `wurzel_gliedweise` | rechenreihenfolge | **wurzel**, pythagoras | Zieht die Wurzel aus einer Summe Glied für Glied: √(9 + 16) als √9 + √16. |
| `irrational_verwechselt` | – | **wurzel** | Hält Wurzeln aus Quadratzahlen oder periodische Dezimalzahlen für irrational, oder umgekehrt. |
| `faktor_ohne_wurzel` | – | **wurzel** | Zieht beim teilweisen Wurzelziehen den Faktor heraus, ohne aus ihm die Wurzel zu ziehen: √72 = 36·√2. |
| `potenzgesetz_verwechselt` | – | **potenz** | Verwechselt die Potenzgesetze: multipliziert die Hochzahlen, wo sie addiert werden, oder umgekehrt. |
| `negativer_exponent_negativ` | vorzeichen | **potenz** | Liest eine negative Hochzahl als negatives Ergebnis: 2⁻³ = −8 statt 1/8. |
| `zehnerexponent_vorzeichen` | vorzeichen | **potenz** | Gibt bei kleinen Zahlen einen positiven Zehnerexponenten an, bei großen einen negativen. |
| `negative_loesung_vergessen` | gleichungen_umformen | **quadrgl** | Gibt bei x² = c nur die positive Lösung an und übersieht die negative. |
| `pq_vorzeichen` | vorzeichen | **quadrgl**, quadrfkt | Setzt p in der p-q-Formel mit falschem Vorzeichen ein, beide Lösungen kippen ins Gegenteil. |
| `vorzeichen_aus_klammer` | vorzeichen | **quadrgl**, quadrfkt | Liest aus einer Klammer wie (x − 3) den Wert mit falschem Vorzeichen ab: −3 statt 3. |
| `loesung_null_verloren` | gleichungen_umformen | **quadrgl** | Teilt durch x und verliert dabei die Lösung x = 0. |
| `ergaenzung_vorzeichen` | gleichungen_umformen | **quadrfkt** | Addiert bei der quadratischen Ergänzung das Quadrat, statt es danach wieder abzuziehen. |
| `wurzel_vergessen` | gleichungen_umformen | **pythagoras**, quadrgl, koerper | Rechnet bis zum Quadrat richtig, zieht am Ende aber nicht die Wurzel. |
| `hypotenuse_verwechselt` | – | **pythagoras**, koerper | Behandelt eine Kathete wie die Hypotenuse: addiert die Quadrate, wo subtrahiert werden muss, oder umgekehrt. |
| `drittel_vergessen` | – | **koerper** | Vergisst bei Pyramide oder Kegel den Faktor ⅓ im Volumen. |
| `randsumme_verwechselt` | sachaufgaben | **bedingt** | Zieht beim Ergänzen der Vierfeldertafel von der falschen Summe ab (Zeile statt Spalte). |
| `gesamtheit_statt_bedingung` | sachaufgaben | **bedingt** | Teilt durch die Gesamtzahl statt durch die Größe der Gruppe, auf die sich die Frage bezieht. |
| `bedingung_vertauscht` | sachaufgaben | **bedingt** | Verwechselt die Wahrscheinlichkeit von A unter der Bedingung B mit der von B unter der Bedingung A. |
| `achse_abgeschnitten_uebersehen` | sachaufgaben | **bedingt** | Vergleicht Säulenhöhen, ohne zu bemerken, dass die Achse nicht bei null beginnt. |
| `absolut_statt_relativ` | sachaufgaben | **bedingt** | Vergleicht absolute Anzahlen, wo Anteile verglichen werden müssen. |
| `streckfaktor_kehrwert` | einheiten_massstab | **aehnlich** | Rechnet mit dem Kehrwert des Streckfaktors: Bild und Original vertauscht. |
| `strahlensatz_falsch_zugeordnet` | – | **aehnlich** | Setzt beim Strahlensatz Strecken ins Verhältnis, die nicht zueinander gehören. |
| `additiv_statt_multiplikativ` | einheiten_massstab | **aehnlich** | Vergrößert mit einem gleichen Zuwachs statt mit einem Faktor. |

Abgleich mit `docs/k8-rest/phase1.md` (Stand 10:49 UTC): Keiner der 17 K8-Slugs deckt eine dieser
Bedeutungen ab (`verhaeltnis_statt_anteil` meint Laplace „günstig zu ungünstig", nicht die
Bezugsgruppe einer bedingten Wahrscheinlichkeit). Die K8-Slugs werden hier nicht verwendet.

## e) Feld- und Schema-Regeln

| Feld | Regel |
|---|---|
| `input_type` | `NUMERIC` (eine Zahl) oder `MULTI_PART` mit `short_input`-Teilen. Kein MC, kein TERM. |
| `afb` | `'I'` / `'II'` / `'III'`, Begründung je Aufgabe (`afbGrund`) |
| `class_level` | 9 (Charge-Feld) |
| `curriculum_grade` | 9, Grund mit KLP-Bezug |
| `competency_content` | am Item: wurzel/potenz/quadrgl `arithmetik_algebra`, quadrfkt `funktionen`, pythagoras/koerper/aehnlich `geometrie`, bedingt `stochastik` |
| `cluster_id` | wurzel/potenz `Zahl & Rechnen`, quadrgl/quadrfkt `Algebra & Funktionen` (wie Binom/Linear), Geometrie `Geometrie & Messen`, bedingt `Daten & Zufall` |
| `est_duration_sec` | AFB I 45 s, II 60 s, III 90 s, +30 s Sachkontext; MULTI_PART: `zeit_teile` summiert genau dazu (macht die Bibliothek) |
| `needs_image` | true nur mit Figur (`koordinatensystem`) |
| `source` / `source_ref` | `edvance_k9_<kurz>` / `<ref>-<knoten>-NN` (ref aus graph.json) |
| `unit` | fester Zusatz am Eingabefeld, getippt wird nur die Zahl. Nur bei NUMERIC. |
| Hinweise | keine (`leer.hints` mit Grund) |
| Lösung | `task_solution_upsert`; Systemrolle je `do`-Block (`ohne_transaktion`, siehe unten) |
| `correct_answers` | jede gleichwertige Schreibweise (macht `tools/k9-rest-lib.mjs`): Komma/Punkt, ohne Endnull, `-3`/`−3`/`- 3`, positiv auch `+3` (ohne Einheit), Bruch und Dezimal bei `bruch: true`, Einheit angehängt. **Keine Tausenderpunkte.** |
| Rundung | Jede Aufgabe nennt, ob exakt oder auf wie viele Stellen gerundet wird. Wurzeln: exakt nur, wenn die Zahl ein Quadrat ist; sonst „Runde auf … Stellen". π wie beim Kreis: „Rechne mit der π-Taste oder mit π ≈ 3,14." + beide Ergebnisse als Varianten. |
| wissenschaftliche Schreibweise | **nie** als Eingabe „4,5·10⁻⁴". Abgefragt werden Vorfaktor und Hochzahl als zwei Teile (MULTI_PART) oder die Hochzahl allein. |
| `acceptance` | `canonical` + `equivalents` (`acceptance_equivalents: true`), `known_errors` `{wert: slug}` in allen Schreibweisen |
| `sondierrang` | Rang 1 und 2 je Knoten aus verschiedenen Fehlbildprofilen (macht `vorlauf-build.mjs`); jeder Knoten braucht dafür mindestens zwei verschiedene Profile |
| Sprache | keine Mastery-Sprache, keine fiktiven Personen mit Namen („Eine Klasse …", „Ein Rad …"), keine echten Firmen/Marken |

**Charge-Felder für `tools/vorlauf-build.mjs`:** `batch`, `source`, `auswahl`, `kopf`, `zeitregel`,
`class_level: 9`, `acceptance_equivalents: true`, `ohne_transaktion: true`. Die Bibliothek
`tools/k9-rest-lib.mjs` setzt sie alle.

### Werkzeuge dieses Laufs

- `tools/vorlauf-build.mjs` **wortgleich aus `feat/k8-rest` übernommen** (ohne_transaktion mit
  Systemrolle je `do`-Block, MC, Generator-Feld). Beide Branches ändern die Datei identisch, der
  Merge bleibt konfliktfrei. Kreis, Zins und Linear erzeugen damit byte-gleich dieselben Dateien.
- `tools/k9-rest-lib.mjs`: exakte Rechnung (Brüche, `W(x)` = Wurzel auf 40 Stellen, `P` = π auf
  35 Stellen), Rundung mit Grenzprüfung, Schreibweisen, Kollisionsprüfung known_errors/richtig,
  MULTI_PART, Prüfeinträge für verify-prefill, erlaubte Slugs (Bestand + Plan).
- `tools/k9-rest-substrat.mjs <kurz>`: Substrat-Migration aus `graph.json`.
- `tools/k9-rest-pruefung.mjs <kurz>`: beide Prüfskripte (Substrat aus `graph.json`, Aufgaben aus der Charge).
- `tools/k9-rest-graph-check.mjs <bestand.json>`: Tiefen, Kanten, Transitivität gegen Prod.
- `tools/k9-rest-wegwerf-db.sh <db> [dateien]`: Wegwerf-DB (Vorlage aus allen Basis-Migrationen,
  dann die eigenen Dateien zweimal, Idempotenz über Zeilenzahlen).

## Versionen (zentral vergeben, Erstellungszeitpunkt UTC, `versionen.txt`)

| # | Version | Name |
|---|---|---|
| 1 | 20261003105852 | substrat_k9_wurzel |
| 2 | 20261003105853 | substrat_k9_potenz |
| 3 | 20261003105854 | substrat_k9_quadrgl |
| 4 | 20261003105856 | substrat_k9_quadrfkt |
| 5 | 20261003105857 | substrat_k9_pythagoras |
| 6 | 20261003105858 | substrat_k9_koerper |
| 7 | 20261003105859 | substrat_k9_bedingt |
| 8 | 20261003105900 | substrat_k9_aehnlich |
| 9 | 20261003105901 | aufgaben_k9_wurzel |
| 10 | 20261003105902 | aufgaben_k9_potenz |
| 11 | 20261003105903 | aufgaben_k9_quadrgl |
| 12 | 20261003105904 | aufgaben_k9_quadrfkt |
| 13 | 20261003105905 | aufgaben_k9_pythagoras |
| 14 | 20261003105906 | aufgaben_k9_koerper |
| 15 | 20261003105907 | aufgaben_k9_bedingt |
| 16 | 20261003105909 | aufgaben_k9_aehnlich |
| 17 | 20261003105910 | thema_einstieg_k9_rest |

Geprüft: keine Version in `schema_migrations` (Prod, lesend; max. dort `20261003101556`), in einem
Git-Branch oder in `~/wt/k8-rest` (dort `20261003104943` … `104951`).
