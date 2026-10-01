# K8 Lineare Funktionen – Phase 0 (nur gelesen)

Stand 2026-10-01, Branch `feat/k8-linfkt` auf `96fabf5` (= origin/dev).
Auftrag: `W1-1-lineare-funktionen.md`, Phase 0 a–f. Es wurde nichts angelegt.

## Wie gelesen wurde

Die Verbindung kommt aus `.env` → `DATABASE_URL`. `DBURL` ist nicht gesetzt.
Vor jeder Abfrage lief der Guard `select current_database()` = `postgres` (remote, nicht 127.0.0.1).
Danach lief die Abfrage in `begin read only … rollback`.

**Lücke:** Nach der ersten Abfrage (Schema von `public.skills`) wurden weitere
Live-Abfragen vom Session-Klassifikator als „Production Read“ gesperrt. Diese
Werte sind deshalb **nicht live geprüft**:

- die Zahl der `ready`-Aufgaben je Voraussetzung
- der heutige `sondierrang`
- die Aufgaben ohne `known_errors`
- die vollständige Liste von `fehlbild_labels`

Sie stammen aus dem Repo: den Migrationen, `docs/sondierrang_vorschlag.md` und
den Bodies von PR #150/#152. Jede so gewonnene Zahl ist mit **(Doku)** markiert.
Für Phase A sind die Queries in Abschnitt 7 nachzuholen.

## Befunde, die vom Prompt abweichen (anhalten/melden)

1. **Die Tiefengrenze ist live 1..8, nicht 1..12.**
   Live gelesen: `skills_fundament_tiefe_check CHECK (fundament_tiefe >= 1 AND fundament_tiefe <= 8)`.
2. **Der Vorlauf ist nicht da.**
   - `feat/k8-vorlauf` hat keine Commits über origin/dev hinaus und hat keinen PR.
   - `geo_koordinaten` und `term_einsetzen` gibt es weder im Repo noch, laut Repo-Stand, in der DB.
   - Damit sind ihre Tiefen unbekannt. Die Bedingung für Phase A ist nicht erfüllt.
3. **`task_solution_upsert` wird im Binom-Muster nicht benutzt.**
   - Die Signatur ist `(p_task_id, p_correct_answers, p_solution, p_hints, p_coach_hints, p_typical_errors, p_beleg, p_acceptance, p_option_scores)`, `SECURITY DEFINER`. Aufrufer ist nur der Editor.
   - PR #152 schreibt `task_solutions` direkt und legt `known_errors` in `acceptance` ab.
   - Ob die RPC im Migrationskontext ohne JWT-Rolle durchläuft: siehe Memory „PRUEFUNG-Claims brauchen Rolle“. Ohne Rolle gilt der Aufruf als Systemaufruf. **Vor Phase B entscheiden:** RPC oder direkter Insert wie in #152.
4. **„est_duration_sec = Summe der Teilaufgaben“ lässt sich nicht umsetzen.**
   - Teilaufgaben haben weder Zeitbudget noch Stoffanker (`docs/prefill/bestandsaufnahme.md:80`).
   - Die Regel entfällt. Gesetzt wird nur `tasks.est_duration_sec` (10–3600). Bei MULTI_PART ist es Pflicht.
5. **„Kästchen statt Einheiten gezählt“ ist mit dem Generator nicht auslösbar.**
   - `koordinatensystem.py` zeichnet immer ein Einheitsraster (`gitter` = „Einheitsraster“, ein Skalenfaktor `einheit`). Achsen in 2er-Schritten gibt es nicht.
   - Vorschlag: Slug nicht anlegen, oder erst nach einer Generator-Erweiterung im Foundation-Fenster.
6. **Fehlbild-Diagnose greift nur bei NUMERIC und MC.**
   - TERM ist durch `lsa_term_acceptance_guard` gesperrt (PR #152).
   - Gleichungsaufgaben wie „y = 2x − 3“ müssen deshalb als MC laufen, wenn sie Fehlbilder tragen sollen.
   - COORDINATE: Fehlbild-Matching ist nicht belegt. Für `fkt_linear_graph` (Figur gegeben, ablesen) also MC oder NUMERIC.

## a) Skill-Keys

Bestandsmuster: `<familie>_<unterfamilie>_<spezifikum>`, ASCII, ohne Umlaute (PR #150, z. B. `term_binom_quadrat`).
Es gibt noch keine Familie `fkt_`. Sie ist neu, folgt aber dem Muster.

Die vorgeschlagenen Keys passen:

| skill_key | Label (Vorschlag) | Kompetenz |
|---|---|---|
| `fkt_linear_steigung` | Steigung einer linearen Funktion bestimmen | Fkt-4/5 |
| `fkt_linear_yabschnitt` | y-Achsenabschnitt bestimmen und deuten | Fkt-5/6 |
| `fkt_linear_graph` | Graph einer linearen Funktion lesen und zeichnen | Fkt-4 |
| `fkt_linear_gleichung` | Funktionsgleichung y = mx + b aufstellen | Fkt-4/5/6 |
| `fkt_linear_nullstelle` | Nullstelle einer linearen Funktion berechnen | Fkt-7 |

Das Thema `lineare_funktionen` (Klasse 8) steht schon in `themen` (a14).

## b) Voraussetzungen

**Tiefen** stammen aus den Seeds in `20260722130000_a14_skill_substrat.sql` (Repo).
**Aufgaben und Profile** stammen aus `docs/sondierrang_vorschlag.md`
(245 ready-Fundament-Aufgaben, `source = edvance_fundament`). Dort heißt es: „sondierrang steht überall auf NULL“.
Die Spalte *sondierrang gesetzt?* zeigt nur den Doku-Vorschlag. Ob `scripts/sql/sondierrang_setzen.sql` eingespielt ist, ist live nicht geprüft.

Die Spalte „ohne known_errors“ ist abgeleitet: Jede Aufgabe in der Doku steht in einem Fehlbildprofil, trägt also known_errors (Objektform).

| skill_key | Tiefe | ready-Aufgaben (Doku) | Rang 1+2 vorgeschlagen (Doku) | ohne known_errors (Doku) | Urteil |
|---|---|---|---|---|---|
| `geo_koordinaten`* | – | 0 | – | – | **fehlt** (Vorlauf) |
| `term_einsetzen`* | – | 0 | – | – | **fehlt** (Vorlauf) |
| `vorzeichen_add_sub` | 1 | 7 | ja (1 Profil) | 0 | trägt¹ |
| `vorzeichen_mult_div` | 2 | 7 | ja (1 Profil) | 0 | trägt¹ |
| `bruch_kuerzen` | 1 | 7 | ja (1 Profil) | 0 | trägt¹ |
| `bruch_dezimal` | 4 | 6 | ja (2 Profile) | 0 | trägt |
| `proportionalitaet` | 4 | 14 | ja (4 Profile) | 0 | trägt |
| `gleichung_zweischrittig` | 6 | 6 | ja (1 Profil) | 0 | trägt¹ |
| `gleichung_neg_koeffizient` | 7 | 5 | ja (1 Profil) | 0 | trägt¹ |

\* aus dem Vorlauf.
¹ Formal „trägt“: mindestens 4 Aufgaben, Rang 1+2 vorgeschlagen, alle mit known_errors.
Bei nur einem Fehlbildprofil liegen Rang 1 und 2 aber zwangsläufig im selben Profil. Die zweite Sondierung bringt dort keine neue Information. Für die Zuteilung ist das kein „dünn“, aber erwähnenswert.

**Live nachzuholen:** Status `ready`, gesetzter `sondierrang` und known_errors-Form. Query in Abschnitt 7.
Zur Erinnerung die Regel für „dünn“: weniger als 4 ready-Aufgaben, kein Rang 1+2, oder mehr als die Hälfte ohne known_errors.

### Fachlich nötige Ergänzungen

- **`gleichung_einschrittig`** (Tiefe 5, 6 Aufgaben, 2 Profile; trägt). Sie wird nur transitiv gebraucht, über neg_koeffizient → zweischrittig → einschrittig. **Keine direkte Kante.**
- **`proportionalitaet`** (4). Fachlich ist y = m·x die proportionale Zuordnung aus Klasse 7. Sie ist der direkte Vorläufer der Steigung als „Zuwachs je Einheit“ (Fkt-6, Preis pro km). Deshalb schlage ich die Kante `fkt_linear_steigung → proportionalitaet` vor.
  **Konflikt:** Bei Steigung = 4 ist die Kante unzulässig, weil der Guard echt flacher verlangt. Siehe f).
- **`bruch_dezimal`** (4). Eine Steigung wie 1/2 = 0,5 wird in beiden Schreibweisen abgefragt. Die Kante ist optional. Hängt man sie an, gilt derselbe Tiefenkonflikt wie bei `proportionalitaet`.
  Mein Vorschlag: keine Kante. `bruch_kuerzen` deckt den Bruchanteil, die Dezimalform läuft als Lösungsvariante.
- **`vorzeichen_add_sub`** (1). Die Differenz y₂ − y₁ mit negativen Werten ist genau das Fehlbild „Vorzeichenfehler in der Differenz“. Transitiv ist sie über `vorzeichen_mult_div` schon abgedeckt. **Keine direkte Kante nötig.**

## c) Muster aus PR #150 / #152 (übernommen)

**Substrat-Migration (#150):**
- Kopfkommentar mit Lehrplanbezug, Begründung der Tiefen und Grund für `begin;`/`commit;` in der Datei. Grund: `db-migrate.sh` klammert nicht.
- Reihenfolge: zuerst `insert into public.skills … on conflict (skill_key) do nothing`, danach erst `skill_kante`. Der Trigger `skill_kante_tiefe` ist `DEFERRABLE INITIALLY IMMEDIATE`.
- Jede Kante bekommt **einen Begründungssatz** als Kommentar direkt darüber.
- Nur direkte Kanten. Jeder Knoten hat mindestens eine Kante nach unten, sonst ist er praktisch unerreichbar (`lsa_select_next_core`).
- `fehlbild_labels (slug, familie, klartext, erklaerung) … on conflict (slug) do nothing`.
  - `freigegeben_am` bleibt NULL.
  - Es werden nur die fünf vorhandenen Familien benutzt. Keine neue Familie.
- Dazu eine `supabase/checks/<name>.PRUEFUNG.sql` mit Asserts plus einer Bruchprobe. Sie bindet die Migration **nicht** per `\ir` ein.

**Aufgaben-Migration (#152):**
- Eine CTE `neu(...)` mit allen Zeilen, danach `insert into tasks … returning`, danach `insert into task_solutions`.
- Feste Werte:
  - `status 'draft'`, `source 'edvance_k8_<thema>'`, `source_ref '<kurz>-NN'`
  - `class_level 8`, `curriculum_grade 8`
  - `cluster_id` per Subquery auf `skill_clusters.name = 'Algebra & Funktionen'` (wird per Script geseedet)
  - `competency_content` am Item selbst
  - `parts '[]'`, `needs_image false`
- MC-Distraktoren tragen die Fehlbilder (Options-ID → Slug). Bei NUMERIC ist es Falschwert → Slug.
- Im PR-Text:
  - AFB-Begründung je Aufgabe nach dem Raster I/II/III
  - Abdeckung je Slug (mindestens 3 Aufgaben)
  - Sondierrang-Tabelle mit Begründung
  - Dublettenprüfung gegen den Prod-Bestand

## d) Felder der Item-Pflege und erlaubte Werte

Quelle: `docs/prefill/bestandsaufnahme.md:44-81`, CHECKs aus `schema-erwartet.sql`.

### Aufgabe (`tasks` / `task_solutions`)

| Feld | Erlaubte Werte |
|---|---|
| `status` | `draft`/`review`/`ready`/`beanstandet`. **Vorbefüllt vor Lenas Prüfung: `draft`** |
| `title` | frei |
| `question` | Pflicht für review/ready; `tasks_zahlen_guard` |
| `input_type` | MC, NUMERIC, SHORT_TEXT, TRUE_FALSE, FREE_TEXT, MATCHING, CLOZE, COORDINATE, MULTI_PART, TERM. Keine neuen |
| `afb` | `I`/`II`/`III` (Pflicht) |
| `est_duration_sec` | 10–3600; Pflicht bei MULTI_PART |
| `curriculum_grade` (Stoffanker) | 5–13; keine Katalogtabelle. Lin. Fkt.: 8; Fundament: echter Stoffjahrgang |
| `cluster_id` | FK `skill_clusters`, 5 Cluster; Pflicht für Freigabe |
| `competency_content` | `arithmetik_algebra`/`funktionen`/`geometrie`/`stochastik`. Lin. Fkt.: `funktionen` |
| `competency_process` | frei (Bestand: Argumentieren, Problemlösen, Modellieren, Operieren, Kommunizieren) |
| `unit` | frei (nur Anzeige, nicht bei MC) |
| `needs_image` | true/false/NULL |
| `source`, `source_ref` (Herkunft) | NOT NULL; `edvance_k8_linfkt`, `linfkt-<kurz>-NN` |
| `sondierrang` | NULL oder ≥ 1; je Knoten genau 1 und 2 |
| `question_payload` | ohne `correct, accepted, pairs, blanks, expected` |
| `task_solutions.correct_answers` | Array (flach) / `{"nr":[…]}` (MULTI_PART); bei MC Options-IDs |
| `task_solutions.solution` (Lösungsweg) | frei |
| `acceptance.known_errors` | Objekt `{falscher_wert\|option_id: slug}` |
| `hints` | `[{level,text}]`; laut Prompt leer („keine Hinweise“) |
| `typical_errors` | `[{error, socratic_question}]`; Bestand `[]` |
| `coach_hints` | Array, höchstens 3 |
| `task_figures` | generator `koordinatensystem`; `alt_text` ohne Ziffern; server-only |

### Teilaufgabe (`parts[]`, nur MULTI_PART)

| Feld | Erlaubte Werte |
|---|---|
| `prompt` | Pflicht |
| `kind` | `short_input`/`mc` |
| `unit` | frei |
| `afb` | I/II/III |
| `competency_content` | Katalog wie oben |
| `needs_image` | bool |
| Lösung | `correct_answers["nr"]`, String-Array; bei mc die Options-ID |

Teilaufgaben haben **kein** Zeitbudget und **keinen** Stoffanker.
Freigabe-Gate `task_status_set` für review/ready verlangt: question, input_type, afb, cluster_id, curriculum_grade, Lösung je Teil.

## e) fehlbild_labels

**Nicht live gelesen.** PR #150 nennt 82 Slugs zum 30.08., davon 53 Altbestand ohne Familie.
Aus dem Repo nachweisbar sind 33 Slugs mit Familie: AF4 (20), P5 (9), Binom (3), dazu `falsche_operation` aus AF3 ohne Familie.

Für Lineare Funktionen relevante vorhandene Slugs:

| vorhandener Slug | Familie | Klartext | passt zu Prompt-Fehlbild |
|---|---|---|---|
| `seiten_verwechselt` | vorzeichen | Subtrahiert in umgekehrter Reihenfolge, Ergebnis mit falschem Vorzeichen. | **Vorzeichenfehler in der Differenz** → wiederverwenden |
| `betrag_fehler` | vorzeichen | Betrag richtig, Vorzeichen des Ergebnisses gekippt. | **Nullstelle b/m statt −b/m** → wiederverwenden |
| `vorzeichen_beim_umstellen` | vorzeichen | Betrag richtig, das Minus des Koeffizienten bleibt am Ergebnis hängen. | Alternative für die Nullstelle bei negativem m |
| `groessen_vertauscht` | sachaufgaben | Vertauscht Grundbetrag und Rate beim Aufstellen. | **m und b vertauscht**, aber nur im Sachkontext (Grundgebühr/Preis pro km) |
| `falsche_richtung` | sachaufgaben | Rechnet den Kehrwert oder verschiebt das Komma um zwei Stellen. | Kehrwert, aber an Prozent/Komma gebunden → nicht passend |
| `division_vergessen`, `b_ignoriert` | gleichungen_umformen | – | für Nullstellen-Aufgaben direkt nutzbar |

### Neue Slugs (nur Vorschlag, zum Abgleich)

| Slug | Familie | Klartext (Coach-Satz) | Anmerkung |
|---|---|---|---|
| `steigung_kehrwert` | gleichungen_umformen | Teilt die waagerechte durch die senkrechte Änderung – die Steigung steht auf dem Kopf. | neu; kein vorhandener Slug passt allgemein |
| `m_b_vertauscht` | gleichungen_umformen | Liest Steigung und y-Achsenabschnitt vertauscht aus der Gleichung ab. | neu für reine Form; im Sachkontext `groessen_vertauscht` nutzen |
| `achsenabschnitt_verwechselt` | gleichungen_umformen | Gibt die Nullstelle als y-Achsenabschnitt an oder umgekehrt. | neu |
| ~~`kaestchen_gezaehlt`~~ | einheiten_massstab | Zählt Kästchen statt Einheiten auf der Achse. | **nicht anlegen**, siehe Befund 5 |
| ~~Vorzeichen Differenz~~ | – | – | → `seiten_verwechselt` |
| ~~Nullstelle b/m~~ | – | – | → `betrag_fehler` |

Die Familien sind gegen die fünf vorhandenen geprüft. `gleichungen_umformen`
(„kennt das Verfahren, … wendet sie in der falschen Richtung an“) trägt schon die
Strukturfehler aus der Binom-Reihe. Eine neue Familie ist nicht nötig.
Vor dem Anlegen der neuen Slugs live auf Altbestand-Dubletten prüfen (Abschnitt 7).

## f) Tiefenplan und Kanten

Schranke heute 1..8. Der Plan unten passt **auch ohne** Anhebung.

| Knoten | Prompt-Vorschlag | Mein Vorschlag | Grund |
|---|---|---|---|
| `fkt_linear_steigung` | 4 | **5** | erlaubt Kanten auf `proportionalitaet` (4) und optional `bruch_dezimal` (4) |
| `fkt_linear_yabschnitt` | 6 | 6 | |
| `fkt_linear_graph` | 7 | 7 | |
| `fkt_linear_gleichung` | 7 | 7 | |
| `fkt_linear_nullstelle` | 8 | 8 | über `gleichung_neg_koeffizient` (7); damit ist 8 das Dach |

Ohne die `proportionalitaet`-Kante bleibt Steigung = 4 gültig. Dann muss aber `geo_koordinaten` ≤ 3 liegen.

| Kante (skill → voraussetzt) | Tiefen | Begründung (Kurzfassung) |
|---|---|---|
| steigung → geo_koordinaten* | 5 → ≤4 | Δx und Δy werden aus Punktkoordinaten abgelesen |
| steigung → vorzeichen_mult_div | 5 → 2 | m = Δy/Δx bei negativen Differenzen |
| steigung → bruch_kuerzen | 5 → 1 | m als gekürzter Bruch |
| steigung → proportionalitaet *(neu)* | 5 → 4 | y = m·x ist die proportionale Zuordnung; m = Wert je Einheit |
| yabschnitt → term_einsetzen* | 6 → ≤5 | b = f(0): x = 0 einsetzen |
| yabschnitt → geo_koordinaten* | 6 → ≤5 | Schnittpunkt (0 \| b) ablesen |
| gleichung → steigung | 7 → 5 | m ist eine der zwei Größen der Gleichung |
| gleichung → yabschnitt | 7 → 6 | b ist die andere |
| graph → steigung | 7 → 5 | Steigungsdreieck zeichnen/lesen |
| graph → yabschnitt | 7 → 6 | Startpunkt auf der y-Achse |
| nullstelle → gleichung | 8 → 7 | 0 = mx + b setzt die Gleichung voraus |
| nullstelle → gleichung_neg_koeffizient | 8 → 7 | mx = −b, oft mit negativem m |

\* Tiefe aus dem Vorlauf. Bedingungen: `geo_koordinaten` ≤ 4, `term_einsetzen` ≤ 5.

Es gibt keine transitiven Doppelungen:
- `vorzeichen_add_sub` läuft über `vorzeichen_mult_div`.
- `gleichung_zweischrittig` läuft über `gleichung_neg_koeffizient`.

Ein Hinweis zu `nullstelle` auf Tiefe 8: Kein späterer Knoten, etwa für LGS oder Schnittpunkte, kann auf ihr aufbauen, solange die Schranke bei 8 steht.

## 7. Live nachzuholen (vor Phase A, nur lesend)

```sql
-- Schranke + Vorlauf-Knoten
select pg_get_constraintdef(oid) from pg_constraint where conname='skills_fundament_tiefe_check';
select skill_key, fundament_tiefe from public.skills where skill_key in ('geo_koordinaten','term_einsetzen');
-- Tabelle b)
select t.skill_key, s.fundament_tiefe,
       count(*) filter (where t.status='ready') ready,
       bool_or(t.sondierrang=1) r1, bool_or(t.sondierrang=2) r2,
       count(*) filter (where t.status='ready' and jsonb_typeof(ts.acceptance->'known_errors') is distinct from 'object') ohne_ke
  from public.tasks t join public.skills s using (skill_key)
  left join public.task_solutions ts on ts.task_id=t.id
 where t.skill_key in ('geo_koordinaten','term_einsetzen','vorzeichen_add_sub','vorzeichen_mult_div','bruch_kuerzen','bruch_dezimal','proportionalitaet','gleichung_zweischrittig','gleichung_neg_koeffizient')
 group by 1,2 order by 2;
-- e) vollständig
select slug, familie, klartext, freigegeben_am is not null frei from public.fehlbild_labels order by familie nulls last, slug;
```

## Entscheidungen für Rasit

1. **Fundament-Zuteilung.** Alle Fundament-Knoten tragen laut Doku. „Fehlt“ sind nur die zwei Vorlauf-Knoten, und die liefert der Vorlauf.
2. **Fehlbild-Slugs.** Neu: `steigung_kehrwert`, `m_b_vertauscht`, `achsenabschnitt_verwechselt`. Wiederverwendet: `seiten_verwechselt`, `betrag_fehler`, `groessen_vertauscht`. Kein Kästchen-Slug.
3. **Steigung auf 5** mit der Kante zu `proportionalitaet`, ja oder nein.
4. **Lösungen:** über `task_solution_upsert` oder per direktem Insert wie in #152.
5. **Live-Lesezugriff** für die Queries in Abschnitt 7 freigeben.
