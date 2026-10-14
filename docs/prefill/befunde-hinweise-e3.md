# Befunde und offene Punkte: Hinweise als Entwurf (E3)

Stand 12.10.2026, Branch `feat/rasit-session-e3-hinweise`. Alles ist KI-Entwurf (`status = 'entwurf'`); geprüft
wird in L5 (Lena), freigegeben vom Admin. Nichts wird automatisch geprüft oder freigegeben.

## Dateien

| Datei | Inhalt |
|---|---|
| `tools/hinweise-e3/<skill>.mjs` | **Quelle**: drei Stufen je Aufgabe (Schlüssel `tasks.source_ref`), mit Belegen für jede Zahl |
| `tools/hinweise-e3-lib.mjs` | Nachrechnung (exakt, über `tools/prefill-rechnen.mjs`), ohne DB und ohne LLM |
| `tools/hinweise-e3.mjs` | `pruefen`, `vorschau`, `migration`, `fixture` (nur Wegwerf-DB) |
| `tests/hinweise-e3.test.ts` | Gate: echte Quellen grün, gezielt verdorbene Kopien rot |
| `supabase/migrations/20261013173601_lsa_ohne_hinweise.sql` | Riegel: `lsa_hint` liefert nie einen Hinweis (Entscheidung Rasit 12.10.) |
| `supabase/migrations/20261013175427_hinweise_e3_batu.sql` | Daten-Migration: Hinweise und Kennzeichen (erzeugt, nicht von Hand ändern) |
| `supabase/tests/session_e3_hinweise.test.sql` | pgTAP: Entwurf, kein Überschreiben, zweiter Lauf, `hinweis_abrufen` |
| `tools/hinweise-e3-wegwerf-db.sh`, `tools/hinweise-e3-abgleich.sql` | Wegwerf-DB (Port 55453) und Abgleich vor/nach der Migration |
| `hinweise-e3-snapshot.json` | Bestand der Aufgaben per dbread (Prod, nur gelesen) |
| `hinweise-e3-vorschau.md` | Vorschau: Aufgabe, Lösungsweg, Stufe 1–3 nebeneinander (alle 49) |
| `hinweise-e3-zweitpruefung-<skill>.md` | Protokolle der Zweitprüfung |

## Neu bauen und prüfen

```bash
node tools/hinweise-e3.mjs pruefen                       # Exit 1 bei jedem Befund
node tools/hinweise-e3.mjs vorschau docs/prefill/hinweise-e3-vorschau.md
node tools/hinweise-e3.mjs migration 20261013175427 hinweise_e3_batu
npx vitest run tests/hinweise-e3.test.ts
PGTAP_SQL=…/pgtap--1.3.4.sql bash tools/hinweise-e3-wegwerf-db.sh e3_test --tests
```

## Bestand (Schritt 1)

dbread 12.10.2026, Prod. Session-Aufgaben = `'session' = any(tasks.einsatz)`; „ohne Hinweise“ = `hints` leer oder null.

| Skill | Aufgaben gesamt | davon Session | davon ohne Hinweise | Status der Session-Aufgaben | VERA8 |
|---|---|---|---|---|---|
| `gleichung_quadr_faktor` | 7 | 6 | 6 | 6 × `draft` | 0 |
| `gleichung_quadr_wurzel` | 6 | 6 | 6 | 6 × `draft` | 0 |
| `gleichung_quadr_formel` | 6 | 6 | 6 | 6 × `draft` | 0 |
| `gleichung_quadr_anzahl` | 6 | 6 | 6 | 6 × `draft` | 0 |
| `gleichung_einschrittig` | 6 | 6 | 6 | 6 × `draft` | 0 |
| `gleichung_zweischrittig` | 6 | 6 | 6 | 6 × `draft` | 0 |
| `term_ausklammern` | 6 | 6 | 6 | 6 × `draft` | 0 |
| `vorzeichen_add_sub` | 7 | 7 | 7 | 7 × `draft` | 0 |
| **Summe** | 50 | **49** | **49** | 49 × `draft` | 0 |

- `gleichung_quadr_*` (alle) umfasst auch `gleichung_quadr_anzahl` (fünftes Ziel im Szenario Batu, `docs/szenario/batu.md`);
  `offene-punkte-t3.md` Punkt 1 nennt es nicht. Es ist hier dabei.
- Die siebte Aufgabe von `gleichung_quadr_faktor` hat keinen Einsatz `session` und bleibt unberührt.
- Herkunft: 24 Aufgaben `edvance_k9_quadrgl` (die vier `gleichung_quadr_*`), 25 `edvance_fundament` (die übrigen
  vier Skills), keine VERA8. Eingabe: 31 `NUMERIC`, 12 `MULTI_PART`, 6 `MC` (`term_ausklammern`).
- Nebenwirkung beim Setzen: Der Trigger `task_solutions_pruef_version` zählt `tasks.pruef_version` der Aufgabe
  hoch (L5 sieht einen neuen Stand). Sonst ändert sich an `tasks` nichts.

## Regeln, die das Nachrechen-Skript durchsetzt (`tools/hinweise-e3-lib.mjs`)

- Genau drei Stufen, jede höchstens zwei Sätze und 200 Zeichen, keine zwei gleichen Texte.
- Kein „richtig“, „falsch“, „Fehler“, keine Wertung („super“, „leicht“, „einfach“), keine Sie-Form.
- Schreibweise wie in den Lösungen: `−`, `·`, `x²`; kein ASCII-Minus zwischen Termen, kein `*`, `^`, `$`.
- Jede Zahl ist belegt: Sie steht in der Aufgabe, ist `0` (Nullprodukt, „= 0“), oder ein Beleg rechnet sie
  exakt nach — Termumformung (`≡`, gleichwertig als Polynom), Gleichungsumformung (`gl`, (L−R) bleibt bis auf
  einen Faktor gleich) oder Rechnung (`=`). Die Eingangszahlen eines Belegs müssen selbst belegt sein; der
  umgeformte Term steht wörtlich im Text.
- Stufe 1 nennt nur Zahlen aus der Aufgabe.
- Keine Stufe nennt ein Ergebnis: keine Zuweisung „x = Lösung“ (bzw. die gesuchte Größe, z. B. `b`, `t`), kein
  „die Lösung ist …“, keine Lösungszahl frei im Text. Eine Lösungszahl darf nur innerhalb eines belegten Terms
  stehen (z. B. `3x · (x − 4)` in Stufe 3).
- Ein genanntes Fehlbild steht in `known_errors` der Aufgabe.
- Abdeckung: jede Session-Aufgabe des Skills aus dem Bestand hat einen Eintrag, kein Eintrag ohne Aufgabe; keine
  Aufgabe mit vorhandenen Hinweisen, ohne Einsatz `session` oder aus VERA8.

Was das Skript nicht sieht (Inhalt, Passung zum Lösungsweg, indirektes Verraten), prüft die Zweitprüfung.

## Abweichungen vom Auftrag

1. **Keine Formeln in `$…$`.** Der Auftrag sagt „Formeln in $…$ wie in den Lösungen“. Keine einzige Lösung in Prod
   nutzt `$` (dbread 12.10.: 0 von 1128 `task_solutions.solution`); die Lösungen der 49 Aufgaben schreiben
   `3x² − 12x = 0` als Klartext mit Unicode. Die Hinweise folgen den Lösungen. Ob das Tablet `$…$` in Hinweisen
   setzen würde, ist offen (Hinweise haben kein `formeln`-Feld wie die Erklärschritte).
2. **„Wir-Form (F2b)“:** Eine Datei F2b gibt es im Repo nicht (Suche in `docs/` und `git log --all`). Umgesetzt:
   Du-Form; Wir-Form in Stufe 3, wo wir den Weg gemeinsam gehen („Wir klammern x aus: …“).

## Zweitprüfung

Frischer Claude-Code-Subagent, der die Hinweise nicht geschrieben hat, nur lesend (keine API, kein Schlüssel).
Er rechnet jede Aufgabe und jede Zahl selbst nach und urteilt je Aufgabe „ok“, „muss“ oder „kann“. Protokoll je
Skill: `hinweise-e3-zweitpruefung-<skill>.md`.

### gleichung_quadr_faktor (Muster)

| Aufgabe | Runde 1 | Was daraus wurde | Runde 2 |
|---|---|---|---|
| faktor-01 | ok; kann: Fehlbild `vorzeichen_aus_klammer` fehlt | Stufe 3 spricht es an („wann die Klammer null wird“) | ok; kann: Satz vom Nullprodukt fehlt jetzt → wieder aufgenommen |
| faktor-02 | **muss**: Stufe 3 „auf beiden Seiten − 5“ verrät x = −5 (Teilaufgabe 1) | Stufe 3 neu: „die Zahl neben x auf die andere Seite bringen“ | ok |
| faktor-03 | ok; kann: Stufe 1 nennt den Ansatz schon | bleibt: Stufe 1 soll laut Regel den passenden Ansatz nennen | – (Prüfer: tragfähig) |
| faktor-04 | ok; kann: Stufe 3 verkürzt | Vorschlag übernommen | ok |
| faktor-05 | ok; kann: Fehlbild `division_vergessen` fehlt | Stufe 3: „rechne, bis t allein steht“ | ok |
| faktor-06 | ok | – | – |

Rechenfehler: keiner. Jedes genannte Fehlbild steht in `known_errors` der Aufgabe.

### Entscheidungen Rasit zum Muster (12.10.)

- Muster ok. Bei jeder `MULTI_PART`-Aufgabe mit „kleinere Lösung“ / „größere Lösung“ erinnert Stufe 3 daran, die
  kleinere Lösung zuerst einzutragen (faktor-01, -03, -04 nachgezogen; -02 hatte es schon). Grund: Vertauschen löst
  sonst falsche Fehlbilder aus. Das Nachrechen-Skript verlangt das jetzt für alle solchen Aufgaben.
- Das Kind sieht nur `text`. Fehlbild-Angaben stehen in der Quelle in einem eigenen Feld und gehen nicht nach
  `task_solutions.hints` (nur `level`, `text`, `status`); das Skript lehnt Slugs und Unterstriche im Text ab.
- Formeln als Unicode wie in den Lösungen (kein `$…$`).

## Für Lena (L5): Datenpunkte an den Aufgaben

E3 ändert weder Aufgabe noch Lösung noch `known_errors`. Diese Punkte sind beim Schreiben der Hinweise aufgefallen:

| Aufgabe | Punkt | Vorschlag |
|---|---|---|
| quadrgl-faktor-04 · x(2x − 7) = 0 | „Gib die Lösungen exakt an“ lädt zu `7/2` ein; akzeptiert sind in Teil 2 nur `3,5`, `+3,5`, `3.5`, `+3.5`. Eine richtige Antwort `7/2` würde als falsch gewertet. | `7/2` in Teil 2 aufnehmen |
| quadrgl-faktor-01 und -04 | Teil 2: `0 → vorzeichen_aus_klammer` ist dasselbe wie ein Vertauschen der Reihenfolge. Das Vorzeichen-Fehlbild fängt Teil 1 (`−5` bzw. `−3,5`) schon ab. | in Teil 2 streichen |
| quadrgl-faktor-06 · 2x² + bx = 0 | `−18 → division_vergessen` ist ein echter Fehler auf dem Einsetz-Weg (2 · 3² + 3b = 0, also 18 + 3b = 0, nicht durch 3 geteilt). Der gespeicherte Lösungsweg geht über den Faktor (2 · 3 + b = 0); dort entsteht −18 nicht. | den Einsetz-Weg als zweiten Weg in die Musterlösung aufnehmen |

## Zweitprüfung der übrigen Skills (Schritt 3)

Je Skill-Gruppe ein frischer Subagent, nur lesend, nach denselben Regeln wie beim Muster. Rechenfehler: keiner.
Keine Stufe verrät eine Lösung. Alle Muss- und fast alle Kann-Befunde sind übernommen; die Prüfregel dazu steht
jetzt im Skript, wo sie sich maschinell fassen lässt.

| Skill | Aufgaben | Urteil | Übernommen |
|---|---|---|---|
| `gleichung_quadr_faktor` (Nachtrag Reihenfolge) | 3 | 03, 04 ok; 01 kann („wann die Klammer null wird“ ging verloren) | 01 Stufe 3 neu |
| `gleichung_quadr_wurzel` | 6 | **muss** 01 (Stufe 3 half nicht mehr als Stufe 2), **muss** 04 (Rundung „zwei Stellen“ statt „zwei Stellen nach dem Komma“) | 01 Stufen 2/3 neu, 04 Rundung; Skript prüft den Rundungswortlaut |
| `gleichung_quadr_formel` | 6 | **muss** 04 (Rundung wie oben); kann 06 (Stufe 3 endete bei der Normalform) | 04 Rundung, 06 Stufe 3 mit eingesetzter Formel |
| `gleichung_quadr_anzahl` | 6 | ok; kann 02, 03, 04, 05, 06 | alle fünf Vorschläge |
| `gleichung_einschrittig`, `gleichung_zweischrittig` | 12 | ok; kann an der Schablone (Wortlaut der Gegenrechnung, Reihenfolge, „links steht noch 2x“) | K1, K2, K4, K5, K6 |
| `term_ausklammern`, `vorzeichen_add_sub` | 13 | ok; kann: Probe beim Ausklammern, Zahlenstrahl-Bild in Stufe 3 | alle drei |

Nicht übernommen: Stufe 1 von faktor-03 (Regel verlangt den Ansatz), K3 bei einschrittig (gleicher Stufe-1-Satz für
alle sechs Aufgaben ist zulässig).

## Für Lena (L5): weitere Datenpunkte

| Aufgaben | Punkt | Vorschlag |
|---|---|---|
| `gleichung_einschrittig`, `gleichung_zweischrittig`, `term_ausklammern`, `vorzeichen_add_sub` (25) | Kein Lösungsweg (`solution` null), keine `typical_errors`. Die Hinweise folgen dem Standardweg (Gegenrechnung, ggT, Zahlenstrahl). | Lösungsweg ergänzen; dann die Hinweise daran prüfen |
| `term_ausklammern` (6) | Keine `known_errors`, obwohl die Ablenker typische Fehler sind (nicht ganz ausgeklammert, nur einen Summanden geteilt). | Fehlbilder für die Ablenker (MC: `option_scores`) |
| `gleichung_einschrittig` 01, 02, 04, 05 | Negative `known_errors` nur mit Bindestrich (`-8`), ohne `−8` und `- 8`; andere Skills führen die Schreibweisen mit. | Varianten ergänzen |
| `vorzeichen_add_sub` 01, 04 | `betrag_fehler` steht hier für „Beträge subtrahiert“ (−2 bzw. 4), in 02, 03, 05–07 für „richtiger Betrag, falsches Vorzeichen“. | einheitlich belegen |
| `vorzeichen_add_sub` (7) | Die Aufgabe schreibt das Minus als Bindestrich (`-3 - 5`), die Hinweise schreiben `−`. | Aufgabentext angleichen |

## Offene Punkte

1. **Fundament-Aufgaben nur in Prod.** Die 25 Aufgaben von `gleichung_einschrittig`, `…_zweischrittig`,
   `term_ausklammern` und `vorzeichen_add_sub` stehen in keiner Migration und nicht in `seed.sql`. In der CI greift
   die Migration für sie ins Leere (kein Fehler); der Abgleich über alle 49 läuft in der Wegwerf-DB mit einer
   Fixture aus dem Prod-Snapshot (`node tools/hinweise-e3.mjs fixture`).
2. **`tasks.vorbefuellt.hints` sagte „leer“ (erledigt, Entscheidung Rasit 12.10.).** Bei den 24 Aufgaben
   `gleichung_quadr_*` stand `{"art": "leer", "grund": "Auftrag W4-k9-rest: ohne Hilfe lösbar (LSA), keine Hinweise."}`.
   Die E3-Migration setzt dort `{"art": "neu", "grund": "E3: drei Hinweisstufen für die Session. In der LSA gibt es
   keine Hinweise (lsa_hint gesperrt)."}` und `vorbefuellt_am = now()`, nur wo „leer“ steht und die drei Hinweise
   gesetzt sind. Die 25 Fundament-Aufgaben haben kein Kennzeichen und bleiben ohne.
3. **LSA ohne Hinweise (erledigt, Entscheidung Rasit 12.10.).** Siehe nächster Abschnitt.
4. **Gate in der Wegwerf-DB.** Dort fehlt den Aufgaben der Cluster (Prod: gesetzt, `pruef_ausschluss` leer für alle
   49, dbread 12.10.). Der pgTAP-Test setzt ihn transaktionslokal für `quadrgl-faktor-03`.
5. **Versionen.** Bereich 20261013170000–175959 vorgegeben; Minute und Sekunde aus `date -u` (17:54:27 → `…175427`).
   Per dbread am 12.10. frei; in Prod stehen bereits T4 (`2026101316…`) und SL2b (`20261013181427`, `…183052`), die
   noch nicht auf dev sind. Vor dem Einspielen erneut prüfen.

## LSA ohne Hinweise (Entscheidung Rasit 12.10.2026)

Die Aufgaben haben Einsatz `lsa` und `session`; `lsa_hint` hätte geprüfte Hinweise auch in einer echten LSA geliefert,
für Testkonten (T3) sogar Entwürfe. Entscheidung: Die LSA läuft ohne Hinweise, für echte Kinder und für Testkonten.

- **Riegel** `20261013173601_lsa_ohne_hinweise.sql` (vor der Hinweis-Migration): `lsa_hint` liefert immer
  `{"level": p_level, "text": null, "available": false}`. Session- (P0002), Zugriffs- (42501) und Item-Prüfung
  (P0001) bleiben unverändert davor; Signatur, `SECURITY DEFINER`, `search_path` und Rechte unverändert.
  `schema-erwartet.sql`: nur der `lsa_hint`-Block (gefiltert gleich dem Neuaufbau).
- **Aufrufer** (12.10.): keine andere Funktion in Prod (`pg_proc.prosrc`), kein Aufruf in `src/` oder
  `supabase/functions`; `scripts/sql/verify_p01.sql` liest nur die Rechte. Tests: `session_t3`, `session_l5`,
  `session_e1`, `inv2_lsa_datenvertrag`, `inv6_keine_loesung_fuer_schueler` umgestellt (Zusagen erhalten, Erwartung
  jetzt „kein Hinweis“), `s9_platz_mechanik` (42501) unverändert. `inv2`, `inv6` stehen in `bekannt-rot.txt` und
  brechen vorher an `lsa_start` ab; ihre umgestellten Zeilen laufen erst, wenn diese Tests wieder grün sind.
- **edvance-app (nur gelesen, Explore-Agent):** Der LSA-Player ruft `lsa_hint` nirgends auf (alle 75 Branches,
  `git grep`); es gibt keinen Hinweis-Knopf. Der einzige Knopf ist Eddie mit „Ich weiß es nicht“
  (`src/components/lsa/Eddie.tsx:21-24`: „WAS EDDIE HIER NIEMALS TUT: einen inhaltlichen Hinweis geben …“,
  `:194`, `LsaAufgabe.tsx:212-213` → `dont_know`). `available=false` läuft also nirgends ins Leere.
  `lsa_submit`/`platz_submit` melden keine Hinweisnutzung; `lsa_responses` hat keine Hinweis-Spalte; keine
  Urteils-, Auswertungs- oder Lernpfad-Funktion der LSA liest Hinweise (`hinweis_genutzt` gibt es nur im
  Session-Pfad, `lernpfad_belege`). `lsa_hint` steht in der App nur in `src/types/database.ts:2044`,
  `docs/DATENVERTRAG.md:55, 149` („Hinweise kommen einzeln auf Anfrage über `lsa_hint`“, jetzt veraltet) und
  `docs/lsa-rpc-referenz.sql`.
- **Nebenbefund:** Die alte Fassung hätte bei adaptiven LSA-Sitzungen (Standard, `item_ids = '{}'`) ohnehin mit
  P0001 abgebrochen, weil sie `item_ids` prüft, `lsa_submit` dagegen `lsa_ausgegeben`. Der Riegel behält die Prüfung
  unverändert (Auftrag); bei adaptiven Sitzungen bleibt es also bei P0001.
- **Web-Frontend:** kein LSA-Player mit `lsa_hint`; der alte Web-TaskPlayer (lokaler Hinweis-Knopf, `hint_used` in
  `behavior_snapshots`) ist stillgelegt (`src/App.tsx:77-78`).

## Einspielen (nach „E3 einspielen“)

Reihenfolge: erst der Riegel `20261013173601_lsa_ohne_hinweise`, dbread-Kontrolle (`pg_get_functiondef`,
`proacl`), dann `20261013175427_hinweise_e3_batu`, dbread-Kontrolle (Hinweise je Skill, alle entwurf, Kennzeichen),
danach `tools/schema-snapshot.sh`.

## Test (Schritt 5)

Wegwerf-DB: eigener Cluster Port 55453, `~/wegwerf-db-e3`, 263 Migrationen (mit Riegel) + `seed.sql` wie in der
CI, dann Fixture, E3-Migration zweimal. Ausgabe von `tools/hinweise-e3-wegwerf-db.sh e3_test --tests` (12.10.2026):

```
ok  Bestand: 49 Aufgaben (Session, ohne Hinweise, nicht VERA8)
ok  geändert: genau diese 49 task_solutions-Zeilen, nur Spalte hints
ok  je Aufgabe Stufe 1–3 mit Text, alle entwurf; geprüft: 0
ok  563 andere task_solutions-Zeilen unverändert
ok  tasks: pruef_version der 49 Aufgaben hochgezählt, sonst unverändert
ok  Kennzeichen vorbefuellt.hints leer → neu: 24 Aufgaben (gleichung_quadr_anzahl, gleichung_quadr_faktor, gleichung_quadr_formel, gleichung_quadr_wurzel)
ok  zweiter Lauf: keine Änderung
je Skill: gleichung_einschrittig 6, gleichung_quadr_anzahl 6, gleichung_quadr_faktor 6, gleichung_quadr_formel 6, gleichung_quadr_wurzel 6, gleichung_zweischrittig 6, term_ausklammern 6, vorzeichen_add_sub 7
1..22
ok 1 - 1 Vorbedingung: die Session-Aufgaben gleichung_quadr_* stehen in der DB
ok 2 - 1 jede Aufgabe hat genau Stufe 1, 2 und 3
ok 3 - 1 jeder Hinweis hat Text und steht auf entwurf (keiner geprüft)
ok 4 - 1 Stufe 1 von quadrgl-faktor-03 wie in der Quelle
ok 5 - 1 kein Fehlbild-Slug im Text
ok 6 - 2 vorhandener Hinweis bleibt (Migration setzt nur bei hints = [])
ok 7 - 2 zweiter Lauf ändert keine Zeile in task_solutions
ok 8 - 3 Vorbedingung: quadrgl-faktor-03 besteht die Prüfung
ok 9 - 3 Testlauf: Stufe 1 kommt
ok 10 - 3 Testlauf: Stufe 2 kommt
ok 11 - 3 Testlauf: Stufe 3 kommt
ok 12 - 3 echte Session: Entwurf Stufe 1 nicht verfügbar
ok 13 - 3 echte Session: Entwurf Stufe 2 nicht verfügbar
ok 14 - 3 echte Session: Entwurf Stufe 3 nicht verfügbar
ok 15 - 4 vorbefuellt.hints der Aufgaben gleichung_quadr_* steht auf neu
ok 16 - 4 vorbefuellt_am ist gesetzt
ok 17 - 5 Vorbedingung: Stufe 1 von quadrgl-faktor-03 ist geprüft
ok 18 - 5 lsa_hint echtes Kind: auch der geprüfte Hinweis kommt nicht
ok 19 - 5 lsa_hint Testkonto: kein Hinweis (auch nicht im Testmodus)
ok 20 - 5 lsa_hint Testkonto: Stufe 2 ebenso
ok 21 - 5 lsa_hint: fremdes Item weiter P0001
ok 22 - 5 lsa_hint: unbekannte Session weiter P0002
```

Gegenproben:
- Ohne E3-Migration ist `session_e3_hinweise` rot (Zusage 2: „have 24, want 0“).
- Mit der alten `lsa_hint`-Fassung (T3-Migration erneut eingespielt) sind genau Zusage 18 und 19 rot.
- Alle 52 pgTAP-Dateien gegen die CI-gleiche DB mit Riegel und E3: 44 grün, 8 rot — genau die 8 aus
  `supabase/tests/bekannt-rot.txt`, keiner davon wegen Hinweisen; ohne E3 dieselben 8.
- Vitest 128 Dateien / 1105 Tests, Typecheck, Lint grün.
- `schema-erwartet.sql`: nur der `lsa_hint`-Block, gefiltert gleich dem Neuaufbau (`pg_dump` wie in der CI).

## Konsensprüfung Riegel (CLAUDE.md §8)

Zweite unabhängige Instanz (Reviewer-Agent, nur lesend, mit dbread gegen Prod), 12.10.2026: **freigeben mit Hinweisen.**

- `lsa_hint` neu gegen Prod: Signatur samt `DEFAULT 1`, `RETURNS`, `SECURITY DEFINER`, `search_path`, drei Prüfungen in
  derselben Reihenfolge mit denselben Codes gleich; ACL `postgres, authenticated, service_role` bleibt (kein DROP,
  kein GRANT/REVOKE). Aufrufer: keine. Testzusagen: Anzahl `is()` und `plan()` je Datei vorher = nachher.
  `schema-erwartet.sql`: nur der `lsa_hint`-Block. Hinweis-Migration: kein Recht, keine Auth, keine RLS.
- Übernommen: `session_l5` prüft jetzt das volle JSON statt nur `text = null`; `docs/api/DATENVERTRAG.md` (`:82`,
  `:194`) beschreibt die LSA ohne Hinweise; Riegel-Migration mit im Commit.
- Beim Einspielen zu erledigen: `origin/dev` einmischen (T4 #242 und SL3 #241 sind inzwischen auf dev, T4 berührt
  `schema-erwartet.sql`), dann `schema-erwartet.sql` erneut gegen den Neuaufbau prüfen; beide Versionen liegen unter
  dem Prod-Maximum (`20261013183052`, SL2b) und werden nachträglich eingetragen — die CI prüft keine Reihenfolge,
  CLAUDE.md §10 prüft nur, dass die Version frei ist.
- Nur genannt, nicht geändert (veraltete Beschreibungen von `lsa_hint`): `docs/session/Bauauftrag-Session-P1.md`
  (Entscheidung 20, E1.2), `docs/session/offene-punkte-t3.md`, `offene-punkte-l5.md`, `offene-punkte-e1.md`,
  `docs/retros/2026-10-06-session-e1.md`; in edvance-app `docs/DATENVERTRAG.md:55, 149` (App-Seite übernimmt Rasit).

## Eingespielt (12.10.2026)

Nach „E3 einspielen“: `origin/dev` eingemischt (T4 #242, SL3 #241, ohne Konflikt), Test erneut (Wegwerf-DB 268
Migrationen: Abgleich ok, pgTAP 22/22; alle 53 pgTAP-Dateien: 45 grün, 8 rot = `bekannt-rot.txt`; Vitest 132 Dateien /
1128 Tests, Typecheck, Lint grün; `schema-erwartet.sql` gefiltert gleich dem Neuaufbau). Dann per `~/bin/mig` (Muster
CLAUDE.md §10: DB-Check, Versionsprüfung, eine Transaktion, History):

1. `20261013173601_lsa_ohne_hinweise` → `CREATE FUNCTION`, History-Eintrag. dbread: `lsa_hint` wie in der Migration,
   `SECURITY DEFINER`, `search_path=public`, ACL `postgres, authenticated, service_role` unverändert.
2. Vorher per dbread: 49 Aufgaben ohne Hinweise, 24 mit Kennzeichen „leer“, alle `draft` (gleich dem Snapshot).
   `20261013175427_hinweise_e3_batu` → `UPDATE 49`, `UPDATE 24`, History-Eintrag.

dbread danach:

| Skill | Session-Aufgaben | mit Stufe 1–3 | nicht entwurf | Kennzeichen neu | Status |
|---|---|---|---|---|---|
| `gleichung_einschrittig` | 6 | 6 | 0 | 0 | draft |
| `gleichung_quadr_anzahl` | 6 | 6 | 0 | 6 | draft |
| `gleichung_quadr_faktor` | 6 | 6 | 0 | 6 | draft |
| `gleichung_quadr_formel` | 6 | 6 | 0 | 6 | draft |
| `gleichung_quadr_wurzel` | 6 | 6 | 0 | 6 | draft |
| `gleichung_zweischrittig` | 6 | 6 | 0 | 0 | draft |
| `term_ausklammern` | 6 | 6 | 0 | 0 | draft |
| `vorzeichen_add_sub` | 7 | 7 | 0 | 0 | draft |

147 Hinweise, 0 geprüft. Texte feldweise (Stufe, Text, Status) gleich der Quelle: 49 von 49.

Schema-Abzug: `tools/schema-snapshot.sh` aus Prod weicht vom Neuaufbau nur in Slots-Funktionen ab. Prod trägt SL2b
(`20261013181427`, `…183052`), das noch nicht auf dev ist. Neuaufbau + E3 + SL2b-Migrationen (aus `febc4d6`) ist
gefiltert gleich dem Prod-Abzug, Prod ist also sauber. Committet bleibt der Neuaufbau ohne SL2b (sonst wäre der
CI-Vergleich rot); `lsa_hint` ist darin wie in Prod.
