# K8 Zinsrechnung — Phase 0 (nur gelesen)

Stand: 01.10.2026. Branch `feat/k8-zins`, Worktree `~/wt/k8-zins` (abgezweigt von `origin/dev` @ `96fabf5`).
Notion-Item: „Klasse 8: Zinsrechnung prüfbar machen". Auftrag: `W1-2-zinsrechnung.md`.

Nichts wurde angelegt oder geschrieben. Alle Abfragen liefen lesend gegen die Live-DB.

## Verbindung

- `.env` setzt `DATABASE_URL`, **kein `DBURL`**. In der Session-Umgebung ist `DATABASE_URL` ebenfalls gesetzt.
  Gelesen wurde über `DATABASE_URL`.
- Vor jeder Abfrage lief `select current_database()` mit dem Ergebnis `postgres`. Die Verbindung war mit
  `PGOPTIONS=-c default_transaction_read_only=on` auf Lesen gesperrt. Ein Host `127.0.0.1` oder `localhost`
  war ausgeschlossen.

## Sperrbefund für Phase A: Der Vorlauf ist noch nicht eingespielt

| Prüfung | Ist (Live) | Soll vor Phase A |
|---|---|---|
| `skills_fundament_tiefe_check` | `fundament_tiefe >= 1 AND <= 8` | 1..12 |
| `term_einsetzen` in `skills` | fehlt | vorhanden (Vorlauf-Spec: Tiefe 5, Kanten → `vorzeichen_vorrang`, `potenzen`) |
| letzte Migration | `20260930150200 prefill_rest_02` | + Vorlauf-Migrationen `_k8_vorlauf.sql` |

`feat/k8-vorlauf` steht noch auf `origin/dev`. Bis zum Lesen gab es dort keinen Commit und keine geänderte Datei.
Phase 0 ist davon nicht betroffen. Phase A beginnt erst, wenn diese Prüfung grün ist.

---

## a) skill_key: Liste und Vorschlag

Es gibt 43 Skills, alle mit `fach = 'mathematik'`. Klasse 5–8, Tiefe 1–8. Die Familienpräfixe im Bestand sind
`bruch_`, `dezimal_`, `geo_`, `gleichung_`, `groessen_`, `potenzen`, `proportionalitaet`, `prozent_`, `runden_`,
`term_` und `vorzeichen_`. Für eine Unterfamilie gibt es zwei Vorbilder: `geo_flaeche_*` und, seit #150,
`term_binom_*`.

Relevanter Ausschnitt:

| skill_key | Klasse | Tiefe |
|---|---|---|
| `dezimal_mult` | 6 | 2 |
| `bruch_mult` | 6 | 2 |
| `runden_ueberschlag` | 5 | 2 |
| `groessen_zeit` | 5 | 4 |
| `potenzen` | 7 | 4 |
| `proportionalitaet` | 7 | 4 |
| `prozent_prozentwert` | 7 | 6 |
| `prozent_grundwert` | 7 | 7 |
| `prozent_prozentsatz` | 7 | 7 |
| `prozent_veraenderung` | 7 | 8 |

**Vorschlag für die Kürzel: `prozent_zins_*` statt `zins_*`.** Die Begründung folgt demselben Muster wie bei
#150 (`term_binom_*` statt `binom_*`): Zinsen *sind* Prozentwerte. Alle vier Knoten hängen am `prozent_`-Ast,
und eine Unterfamilie hat im Bestand Vorbilder.

| Vorschlag aus dem Auftrag | Vorschlag nach Bestandsmuster | Label | klasse_herkunft | Tiefe |
|---|---|---|---|---|
| `zins_jahreszins` | `prozent_zins_jahreszins` | Jahreszinsen berechnen | 7 | 7 |
| `zins_teilzins` | `prozent_zins_teilzins` | Zinsen für Monate und Tage | 7 | 8 |
| `zins_rueckrechnung` | `prozent_zins_rueckrechnung` | Kapital oder Zinssatz aus den Zinsen | 7 | 8 |
| `zins_zinseszins` | `prozent_zins_zinseszins` | Zinseszins und Wachstumsfaktor | 7 | 9 |

Beide Varianten sind gültig. Bitte eine wählen.

---

## b) Voraussetzungen

Grundlage: aktive Aufgaben ohne VERA8. „Ohne known_errors" bezieht sich auf die **ready**-Aufgaben. Gemeint ist
`task_solutions.acceptance → known_errors`, denn eine eigene Spalte `known_errors` gibt es nicht (siehe d).
Das Urteil folgt der Regel aus dem Auftrag: „dünn" heißt weniger als 4 ready, kein Rang 1+2 oder mehr als die
Hälfte ohne known_errors.

| skill_key | Tiefe | ready | sondierrang 1+2 | ready ohne known_errors | Urteil |
|---|---|---|---|---|---|
| `prozent_prozentwert` | 6 | 6 | ja | 0 | **trägt** |
| `prozent_grundwert` | 7 | 6 | ja | 0 | **trägt** |
| `prozent_prozentsatz` | 7 | 6 | ja | 0 | **trägt** |
| `prozent_veraenderung` | 8 | 5 | ja | 0 | **trägt** |
| `term_einsetzen`* | – | 0 | – | – | **fehlt** (legt der Vorlauf an; danach 6 Entwürfe, ready erst nach Lenas Freigabe) |
| `groessen_zeit` | 4 | 6 | ja | 0 | **trägt** formal, fachlich mit Lücke (siehe unten) |
| `dezimal_mult` | 2 | 6 | ja | 0 | **trägt** |
| `runden_ueberschlag` | 2 | 10 | ja | 0 | **trägt** |
| `potenzen` | 4 | **3** | ja | 0 | **dünn** (unter 4 ready) |

\* aus dem Vorlauf

Alle ready-Aufgaben dieser Skills sind `NUMERIC` und haben known_errors in Objektform.

### Fachliche Anmerkungen zu den Voraussetzungen

- **`potenzen` ist dünn und fachlich eng.** Die drei ready-Aufgaben sind `-2^2`, `√36` und `√144`. Keine davon
  hat einen Exponenten ≥ 3 oder eine Dezimalbasis. Der Zinseszins braucht aber genau das, nämlich 1,05³.
  Weitere 13 Aufgaben stehen auf `beanstandet`, 2 auf `draft` (`5^2`, `3^2`). Ein Auffüllen sollte
  Dezimalbasen und Exponent 3 enthalten.
- **`groessen_zeit` deckt nur Minuten → Stunden ab.** Alle sechs ready-Aufgaben haben die Form „66 min = ? h".
  Monate oder Tage als Anteil eines Jahres (m/12, t/360) kommen nicht vor. Die Kante bleibt trotzdem
  sinnvoll, denn das Fehlbild „Faktor 100 statt 60" ist dieselbe Denkfigur wie „Monate durch 100". Der
  Abstieg landet dann aber auf Aufgaben, die die Teilzins-Hürde nur indirekt prüfen.

### Fachlich nötig und in der Liste nicht enthalten

| skill_key | Tiefe | ready | Rang 1+2 | ohne known_errors | Urteil | Vorschlag |
|---|---|---|---|---|---|---|
| `bruch_mult` | 2 | 7 | ja | 0 | trägt | **Zusätzliche Kante `teilzins → bruch_mult`.** Der Zeitfaktor 7/12 oder 45/360 ist ein Bruchteil des Jahres. Diese Hürde deckt `groessen_zeit` (nur min ↔ h) nicht ab. |
| `proportionalitaet` | 4 | 14 | ja | 0 | trägt | Keine eigene Kante. Der Dreisatz für Teilzinsen ist über `prozent_prozentwert → proportionalitaet` schon im Abstieg. |
| `gleichung_einschrittig` | 5 | 6 | ja | 0 | trägt | Keine eigene Kante. Das Umstellen in der Rückrechnung läuft über `prozent_grundwert → gleichung_einschrittig`. |
| `dezimal_div` | 3 | 6 | ja | 0 | trägt | Keine eigene Kante. Läuft über `prozent_prozentsatz → dezimal_div`. |

`runden_ueberschlag` und `dezimal_mult` bekommen ebenfalls keine direkte Kante. Das Runden auf Cent ist
Formsache. Das passende Fehlbild „zu früh gerundet" betrifft den Zeitpunkt des Rundens, nicht das Können.
`dezimal_mult` hängt bereits unter `prozent_prozentwert` und `potenzen`.

---

## Kanten mit Tiefen

Nur direkte Kanten. Der Guard verlangt, dass die Voraussetzung **echt** flacher liegt. Das ist überall erfüllt.

| Knoten (Tiefe) | → Voraussetzung (Tiefe) | Begründung |
|---|---|---|
| jahreszins (7) | → `prozent_prozentwert` (6) | Jahreszinsen sind der Prozentwert von K mit p %. |
| teilzins (8) | → jahreszins (7) | Teilzinsen sind Jahreszinsen mal Zeitanteil. |
| teilzins (8) | → `groessen_zeit` (4) | Monate und Tage müssen in Jahresanteile umgerechnet werden. |
| teilzins (8) | → `term_einsetzen` (5) | Z = K · p/100 · t/360: mehrere Werte gleichzeitig in eine Formel einsetzen. |
| teilzins (8) | → `bruch_mult` (2) **(neu vorgeschlagen)** | Der Zeitanteil ist ein Bruch, der mit einem Betrag multipliziert wird. |
| rueckrechnung (8) | → jahreszins (7) | Rückrichtung derselben Beziehung Z = K · p/100. |
| rueckrechnung (8) | → `prozent_grundwert` (7) | Kapital gesucht heißt Grundwert gesucht. |
| rueckrechnung (8) | → `prozent_prozentsatz` (7) | Zinssatz gesucht heißt Prozentsatz gesucht. |
| zinseszins (9) | → jahreszins (7) | Jedes Jahr ist eine Jahreszins-Rechnung auf dem neuen Kapital. |
| zinseszins (9) | → `prozent_veraenderung` (8) | Der Wachstumsfaktor 1 + p/100 ist die prozentuale Veränderung als Faktor. |
| zinseszins (9) | → `potenzen` (4) | Bei n Jahren ist der Faktor qⁿ, und die Laufzeit findet man durch Probieren mit Potenzen (Ari-8). |

Tiefe 9 für den Zinseszins setzt den Vorlauf voraus (Check 1..12). Ohne ihn scheitert die Migration am CHECK.

---

## c) Muster aus PR #150 und #152 (Binom), das übernommen wird

- **Zwei Migrationen.** Substrat (`skills`, `skill_kante`, `fehlbild_labels`) und Aufgaben werden getrennt.
  Jede Datei hat `begin;` … `commit;`, weil `db-migrate.sh` ohne `--single-transaction` läuft.
  `on conflict do nothing` sorgt für Idempotenz.
- **Kein DB-Namens-Guard in der Datei**, weil CI in `neuaufbau` einspielt. Der Guard steht im Einspielbefehl.
- **Kommentarkopf** mit KLP-Bezug (hier Fkt-8, Fkt-9, Ari-8), ohne behauptete Bindung an ein Schuljahr. Jede
  Kante wird in einem Satz begründet.
- **Fehlbild-Slugs** mit `familie`, `klartext` und optional `erklaerung`, `freigegeben_am` bleibt NULL.
- **Aufgaben:**
  - `question` und `question_payload {"kind":"short_input","prompt":…[,"unit":"€"]}`
  - `acceptance {"canonical":…, "unit":"€", "known_errors":{wert: slug}}`
  - `source_ref` nach dem Muster `zins-jahreszins-01`
- **#152, Befund 3:** Fehlbilder funktionieren in Produktion nur bei `NUMERIC` und `MC`, denn TERM darf kein
  `acceptance` tragen. Zinsaufgaben haben ohnehin Zahlenantworten, deshalb wird es **flach `NUMERIC`**.
- **Unterschied zu #152:** Dort schrieb die Migration `task_solutions` per `insert`. Dieser Auftrag verlangt
  `task_solution_upsert`. Ohne JWT-Rolle (Migration als `postgres`) gilt der Aufruf als Systemaufruf
  (`ist_systemaufruf()`). Das wird im Trockenlauf belegt.

---

## d) Felder der Item-Pflege und erlaubte Werte

Quelle: `docs/prefill/bestandsaufnahme.md`, gegen das Schema und die Live-DB geprüft.

### Aufgabenebene

| Feld | Erlaubte Werte (DB/Katalog) | Vorgesehen für Zins |
|---|---|---|
| `skill_key` | FK-artig auf `skills` | die vier neuen Keys |
| `source` / `source_ref` | frei, NOT NULL | `edvance_k8_zins` / `zins-<knoten>-NN` |
| `status` | draft · review · ready · beanstandet | **`draft`**. Der vorbefüllte Bestand steht auf draft (92 draft, 1 ready). |
| `content_type` | exercise · … | `exercise` |
| `input_type` | MC, NUMERIC, SHORT_TEXT, TRUE_FALSE, FREE_TEXT, MATCHING, CLOZE, COORDINATE, MULTI_PART, TERM | `NUMERIC` (bestehendes Format) |
| `afb` | **`I` / `II` / `III`** (CHECK, römisch) | Der Auftrag sagt „1–3", die DB verlangt römische Zahlen. Vergabe römisch. |
| `competency_content` | Katalog `INHALTSFELDER`: arithmetik_algebra, funktionen, geometrie, stochastik | **`funktionen`** (Fkt-8/Fkt-9). Am Item selbst gesetzt. |
| `competency_process` | Bestand: Argumentieren, Problemlösen, Modellieren, Darstellen, Operieren, Kommunizieren | Operieren, bei Sachkontext „Modellieren, Operieren" |
| `curriculum_grade` (Stoffanker) | 5–13. Es gibt **keine Katalogtabelle**, der Katalog sind die Klassenstufen. | `7` |
| `class_level` | 5–13 | `7` (Muster Binom: = klasse_herkunft). Das Board zählt ≤ 8 als „Klasse 8". |
| `est_duration_sec` | 10–3600 | gesetzt, nach Zeitregel AFB/Sachkontext |
| `cluster_id` | FK auf 5 Mathe-Cluster | **Bitte entscheiden**, siehe Befund 6 |
| `needs_image` | true / false / NULL | `false` |
| `unit` | frei | `€`, bei Zinssatz `%`, bei Laufzeit `Jahre` |
| `sondierrang` | NULL oder ≥ 1 | Rang 1+2 je Knoten aus verschiedenen Profilen, Rest NULL |
| `vorbefuellt` | `{feld:{art: neu\|ueberschrieben\|ergaenzt\|leer, grund, charge}}`, ohne Werte | je gesetztem Feld `art: neu`, Charge `k8-zins` |

### Lösung (`task_solutions`, über `task_solution_upsert`)

| Feld | Form | Vorgesehen |
|---|---|---|
| `correct_answers` | Array (flach) | z. B. `["1102,50"]` |
| `acceptance` | `{canonical, unit, equivalents?, tolerance?, known_errors}` | `known_errors` **nur hier**, in Objektform |
| `solution` | Text | Lösungsweg. Bei der Laufzeit mit Probier-Tabelle. |
| `hints` | `[{level,text}]` | **leer** (Auftrag: keine Hinweise). Im `vorbefuellt` steht dazu `art: leer` mit Grund, sonst meldet `verify-prefill` eine Lücke. |
| `typical_errors` | `[{error, socratic_question}]` | aus den known_errors abgeleitet (Muster rest-01/02) |
| `coach_hints` | Array, höchstens 3 | leer (verify-prefill: „Entscheidung 2", keine Lücke) |

### Teilaufgaben (nur bei MULTI_PART)

Mögliche Felder sind `parts[].prompt`, `kind` (short_input/mc), `unit`, `afb`, `competency_content` und
`needs_image`. Die Lösung je Teil steht in `correct_answers{"nr":[…]}`. Auf Teilebene gibt es **weder
Zeitbudget noch Stoffanker**, die Summenregel „Teile = Aufgabe" hat also nichts, worauf sie greift.

**Vorschlag:** keine MULTI_PART-Aufgaben. Zinseszins über höchstens drei Jahre ist als eine Zahlenantwort
lösbar. Ein Jahr-für-Jahr-Weg gehört in den Lösungsweg, nicht in Teilaufgaben. Damit entfällt die
Teilaufgaben-Pflege.

---

## e) Fehlbilder

Gelesen: alle 85 Einträge in `fehlbild_labels` und 5 Familien. Die Familien `einheiten_massstab`,
`gleichungen_umformen`, `rechenreihenfolge`, `sachaufgaben` und `vorzeichen` sind freigegeben.

### Wiederverwendung aus dem Prozent-Fundament

| Fehlbild im Auftrag | vorhandener Slug | Familie | Klartext heute | Nutzung |
|---|---|---|---|---|
| p statt p/100 gerechnet | **`dezimalverschiebung`** | sachaufgaben | „Multipliziert mit der Prozentzahl, ohne durch 100 zu teilen." | 20 Aufgaben. Passt wörtlich, **kein neuer Slug nötig.** |
| Zinsen statt Endkapital angegeben | **`nur_prozentwert`** | – | – | 10 Aufgaben (prozent_veraenderung): gibt die Änderung statt des neuen Werts an. Gleicher Denkfehler. |
| Endkapital statt Zinsen angegeben | **`falsche_groesse_beantwortet`** | sachaufgaben | „Rechnet richtig, gibt aber die andere gesuchte Größe an." | 0 Aufgaben bisher |
| Rückrechnung multipliziert statt dividiert | **`multipliziert_statt_dividiert`** | – | – | 11 Aufgaben (prozent_grundwert) |
| (Zinssatz) Faktor 100 fehlt | `faktor_100_vergessen` | – | – | 9 (prozent_prozentsatz): 0,04 statt 4 % |
| (Zinssatz) Bezug vertauscht | `bezug_vertauscht` | – | – | 8 (prozent_prozentsatz): K/Z statt Z/K |

`nur_prozentwert` und `multipliziert_statt_dividiert` haben weder Klartext noch Familie (Alt-Bestand). Für die
Elternansicht bräuchten sie einen Klartext. Das ist eine Änderung an Fundament-Zeilen, also deine
Entscheidung und nicht Teil dieses Laufs.

### Neue Slugs (Vorschlag, noch nicht abgeglichen)

| Slug | Familie (Vorschlag) | Klartext (elterntauglich) |
|---|---|---|
| `zeitfaktor_vergessen` | sachaufgaben | Rechnet die Zinsen für ein ganzes Jahr, obwohl das Geld nur einige Monate oder Tage angelegt ist. |
| `zinszeit_falsch_umgerechnet` | einheiten_massstab | Rechnet Monate oder Tage mit dem falschen Teiler in Jahre um, zum Beispiel durch 100 statt durch 12 oder 360. |
| `zinseszins_linear` | sachaufgaben | Rechnet jedes Jahr nur die Zinsen vom Startkapital – dass auch die Zinsen selbst Zinsen bringen, fehlt. |
| `wachstumsfaktor_falsch` | einheiten_massstab | Bildet den Faktor für eine prozentuale Zunahme falsch, zum Beispiel 1,5 statt 1,05 bei 5 %. |
| `veraenderungen_addiert` | sachaufgaben | Zählt Prozentsätze einfach zusammen (plus 20 % und minus 20 % ergibt 0 %), statt die Änderungen nacheinander auszurechnen. |
| `zu_frueh_gerundet` | sachaufgaben | Rundet Zwischenergebnisse zu früh – das Endergebnis weicht dadurch um einige Cent ab. |
| *(optional)* `laufzeit_ein_jahr_zu_frueh` | sachaufgaben | Nennt bei „Nach wie vielen Jahren übersteigt …" das letzte Jahr, in dem der Betrag noch darunter liegt. |

Damit ersetzen zwei Bestandsslugs zwei der neun Fehlbilder aus dem Auftrag: `dezimalverschiebung` und
`multipliziert_statt_dividiert`. „Zinsen statt Endkapital und umgekehrt" decken `nur_prozentwert` und
`falsche_groesse_beantwortet` ab.

**Zum Abgleich:**

1. **`zinseszins_linear` und `veraenderungen_addiert` sind derselbe Denkkern.** In beiden Fällen wird
   additiv statt multiplikativ verkettet. Getrennt muss jeder Slug in mindestens drei Aufgaben sichtbar
   sein. `veraenderungen_addiert` hat aber nur in den Aufgaben zu kombinierten Veränderungen Platz, und davon
   gibt es bei sechs Zinseszins-Aufgaben realistisch ein bis zwei. **Empfehlung:** zu einem Slug
   `prozente_addiert` zusammenlegen. Er deckt dann Zinseszins-Endkapital, Laufzeit (linear gerechnet ergibt
   mehr Jahre) und kombinierte Veränderung ab.
2. **`wachstumsfaktor_falsch` mit 0,05 statt 1,05** ergibt nach einem Jahr genau die Zinsen. Das kollidiert
   mit `nur_prozentwert`. Ein falscher Wert kann je Aufgabe nur einen Slug tragen. Deshalb wird der Fall bei
   n ≥ 2 eingesetzt oder als Variante 1,5 statt 1,05.
3. **`zu_frueh_gerundet` gegen „Jahr für Jahr lösbar".** Banken runden die Jahreszinsen jährlich auf Cent.
   Wer Jahr für Jahr rechnet und rundet, macht also keinen Fehler. Die Zahlen müssen deshalb so gewählt
   werden, dass jedes Jahr glatt auf Cent aufgeht (z. B. 2000 € zu 5 %: 2100 → 2205 → 2315,25). Das
   Fehlbild entsteht dann nur durch Runden des Faktors (1,05³ ≈ 1,16) oder des Zeitanteils (7/12 ≈ 0,58).
4. `zinszeit_falsch_umgerechnet` mit 365 statt 360 ist kein Denkfehler, sondern eine andere Konvention. Als
   Fehlbild zählen nur Teiler wie 100 oder 30 statt 12. Die 360-Tage-Konvention steht im Aufgabentext.

---

## f) Tiefenplan

| Knoten | Tiefe | tiefste Kante darunter | Guard |
|---|---|---|---|
| jahreszins | 7 | `prozent_prozentwert` 6 | ✓ |
| teilzins | 8 | jahreszins 7 | ✓ |
| rueckrechnung | 8 | jahreszins / `prozent_grundwert` / `prozent_prozentsatz` 7 | ✓ |
| zinseszins | 9 | `prozent_veraenderung` 8 | ✓ nur mit Vorlauf (1..12) |

Der Vorschlag aus dem Auftrag (7 · 8 · 8 · 9) passt unverändert.

---

## Befunde, die vom Auftrag abweichen oder Phase A–C betreffen

1. **Vorlauf fehlt** (siehe oben). Phase A ist gesperrt, bis der Check 1..12 erlaubt und `term_einsetzen` existiert.
2. **`afb` ist `I/II/III`, nicht 1–3.** Vergabe römisch.
3. **`known_errors` ist keine Spalte.** Die Werte stehen in `task_solutions.acceptance.known_errors`.
4. **Cent-Beträge sind im Bestand neu.** Von 26 Euro-Aufgaben hat nur eine eine Dezimallösung
   (`sk-dezimal-mult-01`, `3,6`, review). Keine einzige hat zwei Nachkommastellen. Lesend gemessen
   mit `lsa_grade`, `canonical "1102,50"`, `unit "€"`:
   - als **richtig** gewertet: `1102,50` · `1102,5` · `1102.50` · `1102.5` · `1102,50 €` · `1102,50€`
   - als **falsch** gewertet: `1.102,50` (Tausenderpunkt). Ein richtiges Ergebnis würde damit als Fehler
     gezählt.
   - **Das Fehlbild-Matching vergleicht Text, nicht Zahlen.** Der Schlüssel `"102,50"` trifft `102,5` nicht,
     und `102,50 €` ebenso wenig.

   Folge für Phase B:
   - Lösungen **unter 1000 €** halten, damit kein Tausenderpunkt vorkommt. Ein Punkt in Lösungen über
     1000 € lässt sich nicht als Variante abbilden.
   - known_errors-Schlüssel in **beiden Schreibweisen** hinterlegen, also `"102,5"` und `"102,50"`.
   - Eine Eingabe mit `€`-Zeichen verliert das Fehlbild weiterhin, obwohl die Bewertung stimmt. Das liegt
     am Fundament (`lsa_fehlbild_match`) und wird in diesem Lauf nicht behoben.
5. **Inhaltsfeld im Prozent-Fundament.** Alle Prozent-Aufgaben stehen auf `arithmetik_algebra`, der KLP G9
   führt Prozentrechnung aber unter Funktionen (Fkt-8). Die Zins-Charge setzt `funktionen` wie im Auftrag.
   Das Fundament bleibt unverändert, ist hier aber vermerkt.
6. **Cluster:** Die Prozent-Voraussetzungen liegen in „Zahl & Rechnen", Binom in „Algebra & Funktionen".
   „Sachrechnen & Modellieren" hat 0 Aufgaben. Der Editor speichert `cluster_id` nicht (Lücke L1), Lena kann
   den Wert also nicht korrigieren. **Empfehlung:** „Zahl & Rechnen", damit ein Fokusbereich Prozent und
   Zins bündelt. Bitte bestätigen.
7. **`falsche_richtung`:** Der Klartext („Kehrwert oder Komma um zwei Stellen") passt nicht zu seiner
   Verwendung in `prozent_veraenderung`, wo der Slug für Zunahme statt Abnahme steht. Der Slug wird in der
   Zins-Charge nicht genutzt und ist nur vermerkt.
8. **Thema `zinsrechnung`** existiert schon in `themen` (Klasse 8), hat aber keine Zeilen in
   `skill_voraussetzung` (Tabelle insgesamt leer). Das ist Sache des Themenkatalog-Laufs (W1-4). Die
   Klasse 8 dort weicht von klasse_herkunft 7 ab, ohne dass das ein Widerspruch ist.
9. **Prüfwerkzeuge für Phase C:**
   - `verify-tasks.mjs` lädt Aufgaben nur aus Prod (Befund #152).
   - `verify-prefill.mjs` arbeitet mit Charge-JSON und Snapshot, gebaut zum Vorbefüllen *bestehender*
     Aufgaben.
   - `ANTHROPIC_API_KEY` in `.env` war zuletzt ungültig (401).
   - Ob der Blindlöser für neu angelegte Aufgaben überhaupt läuft, klärt Phase C. Fällt er aus, halte ich an
     und melde, statt die Prüfung selbst zu ersetzen.
10. **LSA zieht nur `ready`.** `lsa_select_next_core` filtert standardmäßig auf `status = 'ready'`. Ein Abstieg
    nach `term_einsetzen` findet erst nach Lenas Freigabe der Vorlauf-Aufgaben etwas. Bis dahin endet der
    Abstieg aus teilzins dort leer.

---

## Zur Entscheidung (danach „weiter")

1. Kürzel: `prozent_zins_*` (Empfehlung) oder `zins_*`?
2. Zusätzliche Kante `teilzins → bruch_mult`: ja/nein?
3. `potenzen` (dünn) diesem Lauf zuteilen? Wenn ja, wird mit Exponent 3 und Dezimalbasis aufgefüllt.
4. Fehlbilder: Wiederverwendung wie oben, `prozente_addiert` zusammengelegt (Empfehlung), Familien und Klartexte bestätigen?
5. Cluster „Zahl & Rechnen" bestätigen?

---

## Entscheidungen (Rasit, 01.10.2026)

1. Kürzel `prozent_zins_*`: `prozent_zins_jahreszins` (7), `prozent_zins_teilzins` (8),
   `prozent_zins_rueckrechnung` (8), `prozent_zins_zinseszins` (9).
2. Kante `prozent_zins_teilzins → bruch_mult` wird aufgenommen.
3. `potenzen` ist diesem Lauf zugeteilt. Aufgefüllt wird so, dass auch der Kreis-Lauf die Aufgaben nutzen kann:
   Exponent 2 und 3, Dezimalbasis (1,05²; 1,05³), Quadrat einer Dezimalzahl (2,5²; 0,4²). Die vorhandenen
   √-Aufgaben bleiben unverändert. In `befunde-k8-zins.md` wird vermerkt, dass Wurzeln unter `potenzen` hängen.
4. Fehlbilder wie vorgeschlagen bestätigt, `zinseszins_linear` und `veraenderungen_addiert` werden zu
   `prozente_addiert` zusammengelegt. Ausnahme: `zu_frueh_gerundet` ist verbindlich, weil der Kreis-Lauf ihn
   auch braucht. Familie nach Bestand, Anlage mit `on conflict (slug) do nothing`, Klartext gleich wie im
   Kreis-Lauf: „Rundet ein Zwischenergebnis und rechnet mit dem gerundeten Wert weiter – das Endergebnis
   weicht deshalb leicht ab."
5. Themengebiet „Zahl & Rechnen".

Außerdem: Beträge unter 1000 €, falsche Werte in beiden Schreibweisen. Geprüft wird in Phase C mit
`verify-tasks --from-file` aus dem Vorlauf. Phase A beginnt erst, wenn der Vorlauf eingespielt ist.
