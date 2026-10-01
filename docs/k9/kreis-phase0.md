# K9 Kreis – Phase 0 (nur gelesen)

Stand 01.10.2026 · Branch `feat/k9-kreis` (Worktree `~/wt/k9-kreis`, ab `origin/dev` 96fabf5) ·
Auftrag `W1-3-kreis-k9.md`

> **Der Bericht ist unvollständig.** Nach den ersten Abfragen hat die Rechte-Prüfung der
> Session weitere Lesezugriffe auf die Produktions-DB abgelehnt („Production Reads").
> Die Teile a), b) und e) brauchen die Live-DB und sind deshalb **offen**. Sie werden nicht
> aus Migrationsdateien rekonstruiert, denn im Auftrag gilt: Die DB gewinnt. Alles, was
> unten aus Repo-Quellen stammt, ist als solches gekennzeichnet.

## Verbindung

- `.env` setzt **`DATABASE_URL`**, ein **`DBURL`** gibt es nicht (weder in `.env` noch in der Umgebung).
  Gelesen wurde ausschließlich über `DATABASE_URL`.
- Guard vor jeder Abfrage: `select current_database()` muss `postgres` liefern. Ein Host
  `127.0.0.1`/`localhost` wird abgewiesen. Die Session lief mit
  `set session characteristics as transaction read only` (geprüft: `transaction_read_only = on`).
  `PGOPTIONS` allein greift am Pooler **nicht**, `default_transaction_read_only` blieb dort `off`.
- Aus der Live-DB gelesen, bevor die Rechte-Prüfung weitere Abfragen ablehnte:
  - **43 Zeilen in `public.skills`.** Das sind die 39 aus PR #150 plus die 4 `term_binom_*`.
    `term_einsetzen` ist damit **noch nicht** angelegt. Passend dazu enthalten weder `dev`
    noch die Remote-Branches einen Vorlauf-Branch (`feat/k8-vorlauf`) oder die
    Zeichenfolge `term_einsetzen`.
  - Spalten von `skills`, `tasks`, `task_solutions`, `fehlbild_labels`,
    `fehlbild_familien`, `skill_clusters`, `themen` (siehe d)).

**Konsequenz für Phase A:** Der Vorlauf fehlt. Phase A ist laut Auftrag gesperrt, bis
`term_einsetzen` per SELECT nachweisbar ist.

## a) skill_key – Kürzel

**Offen (Live-Liste nicht gelesen).** Nach der Konvention aus PR #150 (Themenfamilie zuerst,
drittes Segment als Unterfamilie, vgl. `geo_flaeche_rechteck`) passt der Vorschlag:

| skill_key | label (Vorschlag) | Klasse | Tiefe (Vorschlag) |
|---|---|---|---|
| `geo_kreis_umfang` | Umfang des Kreises | 9 | 6 |
| `geo_kreis_flaeche` | Flächeninhalt des Kreises | 9 | 6 |
| `geo_kreis_rueck` | Radius und Durchmesser aus dem Umfang | 9 | 7 |
| `geo_kreis_sektor` | Kreisbogen und Kreisausschnitt | 9 | 7 |
| `geo_kreis_zusammen` | Zusammengesetzte Kreisfiguren | 9 | 7 |

`geo_kreis_*` liegt als Unterfamilie neben `geo_flaeche_*` und `geo_volumen_*`. Ob ein Key
schon vergeben ist, prüft der SELECT, der noch fehlt.

## b) Voraussetzungen

**Offen.** Alle Spalten außer der Tiefe brauchen die Live-DB: ready-Aufgaben,
sondierrang 1+2, Aufgaben ohne known_errors und damit auch das Urteil.

Die Tiefen stammen aus PR #150 (gelesen im September), **nicht** frisch aus der DB:

| skill_key | Tiefe (lt. #150) | ready | sondierrang 1+2 | ohne known_errors | Urteil |
|---|---|---|---|---|---|
| `term_einsetzen`* | – (Vorlauf fehlt) | – | – | – | **fehlt** (Vorlauf) |
| `potenzen` | 4 | offen | offen | offen | offen |
| `dezimal_mult` | 2 | offen | offen | offen | offen |
| `dezimal_div` | 3 | offen | offen | offen | offen |
| `runden_ueberschlag` | 2 | offen | offen | offen | offen |
| `groessen_laengen` | 3 | offen | offen | offen | offen |
| `groessen_flaechen` | 5 | offen | offen | offen | offen |
| `geo_umfang` | 3 | offen | offen | offen | offen |
| `geo_flaeche_rechteck` | 3 | offen | offen | offen | offen |
| `geo_flaeche_dreieck` | 4 | offen | offen | offen | offen |
| `proportionalitaet` | 4 | offen | offen | offen | offen |

Abfrage für die offenen Spalten, sobald Lesen wieder geht:
`known_errors` liegt in `task_solutions.acceptance -> 'known_errors'` (PR #152),
`sondierrang` in `tasks.sondierrang`, der Status in `tasks.status`.

### Ergänzungsvorschläge (fachlich, nicht in der Liste)

| Voraussetzung | für | Begründung |
|---|---|---|
| `dezimal_add_sub` (Tiefe 1) | `zusammen` | Der Kreisring ist eine Differenz zweier Flächen, und der Umfang des Halbkreises ist d + πd/2. Ohne sicheres Addieren und Subtrahieren von Dezimalzahlen scheitern beide, auch wenn die Kreisformel sitzt. |
| `dezimal_mult` als **direkte** Kante | `umfang`, `flaeche` | π·d und π·r² sind Dezimalmultiplikationen. Steht `dezimal_mult` nur indirekt über `term_einsetzen` im Graphen, führt der Abstieg bei einem Rechenfehler nicht dorthin. |
| `runden_ueberschlag` als direkte Kante | `umfang`, `flaeche` | Jede π-Aufgabe endet mit dem Runden auf vorgegebene Stellen. Das Fehlbild „zu früh gerundet" gehört genau dorthin. |
| `bruch_kuerzen` (Tiefe 1) | `sektor` | α/360° ist ein Bruch, und 90/360 = 1/4 erkennt nur, wer kürzen kann. `proportionalitaet` deckt die Dreisatzrichtung ab, nicht den Anteil. |

Der Auftrag fordert ausdrücklich „nur direkte Kanten". Die Vorschläge oben sind
deshalb **Kandidaten**, die du zuteilst. Fehlen sie, prüft der Abstieg die
Dezimalrechnung nur über `term_einsetzen`.

### Rückrichtung nur aus dem Umfang

`geo_kreis_rueck` bekommt nur die Aufgabenform r bzw. d aus U. Für r aus A bräuchte es die
Quadratwurzel, und dafür gibt es keinen Knoten (KLP Ari-6/7, selbst Zweite Stufe).
Diese Lücke wird bewusst gelassen und nicht durch einen Ad-hoc-Knoten gefüllt.

## Kanten mit Tiefen (Vorschlag aus dem Auftrag, gegen den Guard geprüft)

`skill_kante_tiefe_guard` verlangt, dass jede Voraussetzung echt flacher liegt als ihr
Knoten. Der CHECK lässt laut #150 Tiefen von 1 bis 8 zu.

| Knoten (Tiefe) | → Voraussetzung (Tiefe) | Guard |
|---|---|---|
| `umfang` (6) | `term_einsetzen` (?), `geo_umfang` (3) | ok, wenn `term_einsetzen` ≤ 5 |
| `flaeche` (6) | `term_einsetzen` (?), `potenzen` (4), `groessen_flaechen` (5) | ok, wenn `term_einsetzen` ≤ 5 |
| `rueck` (7) | `umfang` (6), `dezimal_div` (3) | ok |
| `sektor` (7) | `umfang` (6), `flaeche` (6), `proportionalitaet` (4) | ok |
| `zusammen` (7) | `umfang` (6), `flaeche` (6), `geo_flaeche_rechteck` (3), `geo_flaeche_dreieck` (4) | ok |

Die Tiefe von `term_einsetzen` legt der Vorlauf fest. Liegt sie auf 6 oder höher, brechen
`umfang` und `flaeche` am Guard. Dann müssten beide auf 7 und die drei Folgeknoten auf 8
rücken. Das wäre noch erlaubt, aber nur, wenn der Vorlauf die Decke nicht schon
anderweitig verbraucht.

## c) Muster aus PR #150 / #152

Übernommen werden:

1. **Zwei Migrationen**: Substrat (Knoten, Kanten, Fehlbilder) und Aufgaben getrennt, jede
   Kante mit einem Satz begründet.
2. **`afb` ist `'I' | 'II' | 'III'`** (CHECK `tasks_afb_check`), nicht 1/2/3. Der Auftrag
   sagt „afb 1–3" und meint dasselbe. Geschrieben wird römisch.
3. **`known_errors` ist keine Spalte.** Es liegt in `task_solutions.acceptance ->
   'known_errors'`, und zwar in Objektform `{wert: slug}`. Nur so gibt `lsa_fehlbild_match`
   den Slug zurück.
4. **Nur NUMERIC trägt Fehlbilder.** TERM darf kein `acceptance` haben
   (`lsa_term_acceptance_guard`). Kreisaufgaben haben ohnehin Zahlantworten, also NUMERIC.
   Kein Konflikt.
5. `status` bleibt `draft` wie bei der Binom-Charge.
6. Trockenlauf mit `tools/neuaufbau-test.sh` vor der Übergabe.

## d) Felder der Item-Pflege

Quelle: `docs/prefill/bestandsaufnahme.md` (Stand 30.09.) und `supabase/schema-erwartet.sql`.

### Aufgabe

| Feld | erlaubte Werte |
|---|---|
| `input_type` | CHECK: MC, NUMERIC, SHORT_TEXT, TRUE_FALSE, FREE_TEXT, MATCHING, CLOZE, COORDINATE, MULTI_PART, TERM. Für Kreis: **NUMERIC**, für Teilaufgaben-Items MULTI_PART. |
| `afb` | I / II / III |
| `competency_content` | `arithmetik_algebra`, `funktionen`, **`geometrie`**, `stochastik` (`INHALTSFELDER`). Bei MULTI_PART setzt der Editor das Feld am Item auf NULL. Der Auftrag verlangt es aber am Item. **Konflikt, siehe unten.** |
| `competency_process` | frei, im Bestand: Operieren, Modellieren, Problemlösen, Argumentieren, Kommunizieren |
| `curriculum_grade` (Stoffanker) | CHECK 5–13 |
| `est_duration_sec` | CHECK 10–3600, Pflicht bei MULTI_PART |
| `cluster_id` | FK `skill_clusters`, hier „Geometrie & Messen" |
| `needs_image` | true / false / NULL. Kreis-Charge: false |
| `source` / `source_ref` | `edvance_k9_kreis` / `kreis-<knoten>-NN` |
| `unit` | frei, nur Anzeige |
| `task_solutions.correct_answers` | Array (flach) oder `{"nr":[…]}` (MULTI_PART) |
| `task_solutions.solution` | Lösungsweg, frei |
| `task_solutions.acceptance` | Regelobjekt: `canonical`, `equivalents[]`, `tolerance{mode: exact/absolute/decimals, value}`, `unit`, `unit_graded`, `notation{decimal_comma, unit_optional, …}`, `known_errors`. Für MULTI_PART je Teil unter `"<nr>"`. **Ohne UI**, Lena sieht es nicht. |

### Teilaufgabe (`parts[]`)

`prompt` (Pflicht), `kind` (short_input / mc), `unit`, `afb` (I/II/III),
`competency_content` (INHALTSFELDER), `needs_image`. Die Lösung je Teil steht in
`correct_answers["nr"]`.

**Auf Teilaufgabenebene gibt es weder Zeitbudget noch Stoffanker**, weder in der DB noch
in der UI. Die Summenregel aus dem Auftrag („est_duration_sec Summe der Teilaufgaben =
Aufgabe") ist deshalb **nicht abbildbar**. Es gibt kein Feld, das man summieren könnte.
Vorschlag: Die Kreis-Charge bleibt flach (NUMERIC, ein Wert je Aufgabe). Damit entfällt
die Frage, und `competency_content` steht wie verlangt am Item.

### Stoffanker Jahrgang 9

Es gibt **keine Katalogtabelle**. Der Stoffanker ist `tasks.curriculum_grade`, CHECK 5–13.
Die UI bietet an:

- Editor und `QsPage`: 5–13
- Pflege-Strecke (`RequiredFields.tsx`, `StepAnchor.tsx`): **5–9**

**Jahrgang 9 ist damit überall zulässig und wählbar.** Die Taxonomie-Datei
`src/lib/taxonomy/nrw_math_klasse8.json` gibt es nur für Klasse 8. Für Klasse 9 existiert
**keine** Taxonomie-Datei. Sie wird von der Pflege nicht gebraucht, fehlt aber, falls
sie anderswo als Katalog gilt.

### Befunde zur Auswertung (wichtig für Phase B)

1. **Toleranz:** `lsa_values_equal` kennt `exact`, `absolute` (Betrag ≤ value) und
   `decimals` (auf n Stellen gerundet gleich). Die beiden π-Wege liegen je nach Größe
   unterschiedlich weit auseinander: r = 4 cm ergibt beim Umfang 25,13 gegen 25,12, bei
   r = 12 cm die Fläche 452,39 gegen 452,16. Eine feste absolute Toleranz, die bei großen
   Radien beide Wege akzeptiert, schluckt bei kleinen auch das Fehlbild „zu früh
   gerundet". **Vorschlag:** `canonical` = Ergebnis mit π-Taste, `equivalents` = Ergebnis
   mit 3,14, `tolerance` `exact`. Beide richtigen Rundungen zählen genau, alles andere
   nicht.
2. **known_errors vergleicht exakt den String.** `lsa_fehlbild_match` normalisiert nur
   Kleinschreibung, Komma und Leerraum. Es gibt keine Toleranz, und die **Einheit bleibt
   Teil des Strings**: `"50,27 cm²"` trifft den Schlüssel `"50.27"` nicht. Jedes Fehlbild
   braucht deshalb Schlüssel für beide π-Wege **und** für die Formen mit und ohne Einheit.
   Das sind bis zu vier Schlüssel je Fehlbild und Aufgabe.
3. **Einheit als Teil der Lösung** (`unit_graded: true`) wird per String-Vergleich der
   Einheit geprüft. `cm²` und `cm2` sind **verschieden**, beide Schreibweisen gehören in
   `equivalents`. Mit `unit_graded` wird eine Antwort ohne Einheit „teilweise".
   `unit_optional` und `unit_graded` schließen sich per CHECK aus.
4. `acceptance` hat **keine UI**. Lena sieht die Toleranz und die Fehlbild-Zuordnung
   nicht. Was dort steht, prüft nur `verify-prefill`.

## e) fehlbild_labels

**Offen (nicht gelesen).** PR #150 nannte für September 82 Slugs, davon 29 mit Familie und
Klartext, sowie fünf Familien: `einheiten_massstab`, `gleichungen_umformen`,
`rechenreihenfolge`, `sachaufgaben`, `vorzeichen`. Der Abgleich auf vorhandene Slugs
(z. B. ein bestehendes „Einheit nicht quadriert" aus `groessen_flaechen`) steht aus.

### Neue Slugs (nur Vorschlag, vor dem Abgleich)

| Slug | Klartext (elterntauglich) | Familie (Vorschlag) |
|---|---|---|
| `radius_durchmesser_verwechselt` | Ihr Kind setzt den Durchmesser ein, wo der Radius gebraucht wird, oder umgekehrt. | neu: `kreis_formeln`? |
| `kreisformeln_vertauscht` | Ihr Kind rechnet mit der Formel für die Fläche, wo der Umfang gefragt ist, oder umgekehrt. | `kreis_formeln` |
| `r_quadrat_als_2r` | Ihr Kind verdoppelt den Radius, statt ihn mit sich selbst zu malnehmen. | `kreis_formeln` |
| `pi_vergessen` | Ihr Kind lässt die Kreiszahl π in der Rechnung weg. | `kreis_formeln` |
| `flaecheneinheit_nicht_quadriert` | Ihr Kind rechnet die Fläche richtig, gibt sie aber in einer Längeneinheit an (cm statt cm²). | `einheiten_massstab` |
| `kreisanteil_falsch` | Ihr Kind rechnet beim Kreisausschnitt mit dem ganzen Kreis oder dreht den Anteil um. | `kreis_formeln` |
| `halbkreis_nicht_halbiert` | Ihr Kind rechnet beim Halbkreis mit dem ganzen Kreis weiter. | `kreis_formeln` |
| `halbkreis_gerade_kante_vergessen` | Ihr Kind zählt beim Umfang des Halbkreises nur den Bogen und vergisst die gerade Seite. | `kreis_formeln` |
| `zu_frueh_gerundet` | Ihr Kind rundet schon im Zwischenergebnis, dadurch weicht das Ergebnis ab. | offen (wäre themenübergreifend, z. B. auch für Zins) |

Eine neue Familie `kreis_formeln` ist ebenfalls nur ein Vorschlag. Mit Zins und
Lineare Funktionen abgleichen, vor allem `zu_frueh_gerundet`, das beide Läufe ebenfalls
brauchen könnten.

Zwei der Fehlbilder lassen sich über eine einzelne Zahlantwort schwer erfassen:

- `zu_frueh_gerundet` liefert je nach Zwischenrundung **verschiedene** Werte. Pro
  Aufgabe sind ein bis zwei typische Zwischenrundungen als Schlüssel nötig.
- `flaecheneinheit_nicht_quadriert` ist nur dann ein eigener Schlüssel, wenn
  `unit_graded` gilt **und** die Einheit im String steht (`"50,27 cm"`). Nach Befund 3
  landet das Ergebnis bei `unit_graded` aber auf „teilweise" (richtig gerechnet), nicht
  auf „falsch". Der Capture-Trigger erfasst nur `correct is false`. Wie `lsa_submit` das
  Flag `correct` bei „teilweise" setzt, ist aus `schema-erwartet.sql` **nicht belegt**
  (das Urteil `lsa_skill_urteil` wertet „teilweise" wie „nicht"). Wird es als
  `correct = true` gespeichert, erfasst das System dieses Fehlbild **nie**. Das ist zu
  prüfen und betrifft im Zweifel das Fundament, nicht diesen Lauf.

## f) Figuren

- Generatoren laut `task_figures_generator_check`: nur `koordinatensystem` und `winkel`.
  Es gibt **keinen** Kreis-Generator. Spec-Dateien gibt es zusätzlich für
  `dreieck`, `baumdiagramm`, `saeulendiagramm` und `urne`, aber nicht als Generator.
- **Spec geschrieben:** `specs/active/figur-kreis.md` (zeichne + pruefe nach dem
  Winkel-Muster). Formen: kreis, halbkreis, viertelkreis, sektor, kreisring,
  rechteck_halbkreis. Die Kernprüfung misst den überstrichenen Bogen (Sweep-Flag), damit
  der Halbkreis nicht unbemerkt ins Rechteck kippt. **Nicht gebaut.**
- **Konflikt mit dem Auftrag:** Nach dem Figurenmuster gehört der neue Generator in
  `upload_figures.py` (`_lade_generator`). Der Auftrag sagt „upload_figures nicht
  anfassen". Die Spec nimmt diesen Schritt deshalb ausdrücklich heraus. Er braucht deine
  Freigabe, sonst lässt sich der Generator zwar testen, aber nicht hochladen.
- Außerdem braucht der Generator eine Migration, die den CHECK um `'kreis'` erweitert
  (Schema-Zone, `ALLOW_MIGRATIONS=1`).

## g) Tiefenplan

umfang 6 · flaeche 6 · rueck 7 · sektor 7 · zusammen 7. Bedingung: `term_einsetzen` ≤ 5
(siehe Kanten). Sonst eine Stufe höher, wobei dann die Decke 8 erreicht ist.

## Offen / zu entscheiden

1. **Lesezugriff auf die Live-DB freigeben.** Danach lassen sich a), b) und e)
   nachtragen. Die Abfragen sind rein lesend und laufen hinter Guard und
   Read-only-Transaktion.
2. **Vorlauf einspielen** (`term_einsetzen`, Tiefe ≤ 5, Decke angehoben). Bis dahin ist
   Phase A gesperrt.
3. Zuteilung der Voraussetzungen „dünn"/„fehlt", sobald b) vollständig ist.
4. Ergänzungskanten: `dezimal_add_sub`, `dezimal_mult`, `runden_ueberschlag`,
   `bruch_kuerzen`. Ja oder nein?
5. Fehlbild-Slugs und Familie `kreis_formeln` mit Zins und Lineare Funktionen abgleichen.
6. Summenregel für `est_duration_sec` entfällt mangels Feld. Die Charge bleibt flach.
   Einverstanden?
7. `flaecheneinheit_nicht_quadriert` bei „teilweise": möglicherweise nicht erfassbar.
   Zu prüfen; im Zweifel eine Fundament-Frage.
8. Spec `figur-kreis` ohne `upload_figures`-Eintrag. Wann wird er freigegeben?
9. `geo_kreis_zusammen`: Knoten und Kanten in Phase A, Aufgaben erst nach dem Generator.
   Bleibt offen.
