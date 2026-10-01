# Befunde K8 Lineare Funktionen

Auftrag W1-1 „Klasse 8: Lineare Funktionen prüfbar machen“. KLP NRW G9, Funktionen, Erste Stufe, Fkt-4 bis Fkt-7.
Branch `feat/k8-linfkt`, PR #186.

Gelesen wurde die Live-DB nur lesend, ab Phase A ausschließlich über `~/bin/dbread`. Beide Migrationen hat dieser Lauf
selbst eingespielt; Rasit hatte das für diesen Chat freigegeben. Der Ablauf war jedes Mal derselbe:
1. Guard auf `current_database() = postgres`.
2. Versionsprüfung.
3. `psql -1 -f` auf die Migration.
4. Eintrag in `schema_migrations`.

Danach wurde der Stand per `dbread` nachgeprüft.

## Einspiel-Reihenfolge (erledigt)

| Version | Datei | Inhalt | Prod |
|---|---|---|---|
| 20261001124808 | `substrat_k8_linfkt.sql` | 5 Knoten, 12 Kanten, 3 Fehlbild-Entwürfe | eingespielt, per `dbread` geprüft |
| 20261001133106 | `aufgaben_k8_linfkt.sql` | 30 Aufgaben `draft`, 30 Lösungen, 6 Figurzeilen | eingespielt, per `dbread` geprüft |

Voraussetzung waren die Vorlauf-Migrationen (`20261001115718`, `…115812`), jetzt in `dev`.

## Prüfprotokoll (Phase C)

| Prüfung | Werkzeug | Ergebnis |
|---|---|---|
| Alle Lena-Felder | `verify-tasks --prefill` (verify-prefill) | **0 Gate-Fehler**, 92 Nachrechnungen ok → `k8-linfkt-verifikation.md` |
| Blind-Löser, Stufe 2 | frischer Subagent nach `tools/blind-loeser/AUFTRAG.md`, `verify-tasks --from-file … --answers-from … --min-pass 1.0` | **30/30 = 100 %**, 0 Abweichungen, 0 unsicher → `k8-linfkt-blind.json` |
| Struktur, Stufe 1 | dieselbe `verify-tasks`-Runde | erster Lauf: 1 „wortgleiche Dublette“ (graph-02/graph-03), siehe B1; nach der Korrektur 0 |
| Zweiter Blind-Löser | frischer Subagent, nur graph-03 nach der Textänderung | 0.5 = Soll 1/2, nicht unsicher |
| PRUEFUNG Substrat | `supabase/checks/k8_linfkt_substrat.PRUEFUNG.sql` (L1–L6, zwei Bruchproben) | Wegwerf-DB grün |
| PRUEFUNG Aufgaben | `supabase/checks/k8_linfkt_aufgaben.PRUEFUNG.sql` (A1–A10, eine Bruchprobe) | Wegwerf-DB grün; A4 dort übersprungen (B3) |
| Idempotenz | Wegwerf-DB: Grundlage + alle 93 Migrationen, Aufgaben-Migration ein zweites Mal | weiter 30 Aufgaben, 30 Lösungen, 6 Figuren |
| Prod nach dem Einspielen | `dbread`, Assertions aus A1–A9 ohne Bruchprobe | 30/30 Felder, 30/30 Lösungen, Sondierrang 5×(1,2), 0 unbekannte Slugs, Stichproben Bruch/Unicode-Minus/Fehlbild ok |
| Figuren | `upload_figures.py --dry-run` gegen eine **lokale** Wegwerf-DB | alle 6 linfkt-Figuren erzeugt und geprüft (dunkel + hell), `fehler=0` |
| Dubletten | `dbread`: Fragetext gegen 703 Prod-Aufgaben, ids, Quelle | 0 |
| Frontend-Gate | `npm ci && typecheck && lint && test` | grün, 598/598 |
| `schema/neuaufbau` (CI) | PR #186 | grün |

`verify-prefill` lief **ohne** `--migration`, wie bei Vorlauf und Zins. Der Migrations-Check ist für UPDATE-Prefills
gebaut. Er meldet jeden INSERT einer neuen Aufgabe als „ohne VERA8-Ausschluss“ und die Cluster-UUID als „fremde
Aufgabe“; das sind hier 37 Scheinfehler. Neue Aufgaben mit `source = 'edvance_k8_linfkt'` können VERA8 nicht berühren.

**Nicht gelaufen:**
- **PRUEFUNG-Skripte gegen Prod:** Ihre Bruchproben schreiben in einer Rollback-Transaktion, das geht über das
  schreibgeschützte `dbread` nicht, und ein eigener Helfer ist gesperrt. Ersatz ist die `dbread`-Nachprüfung oben.
  Wer es in Prod sehen will: `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/checks/k8_linfkt_<substrat|aufgaben>.PRUEFUNG.sql`.
- **`upload_figures.py` gegen Prod:** Das Skript sagt im Kopf „WIRD VON RASIT AUSGEFUEHRT, NICHT VON CLAUDE“. Die
  6 Figuren tragen deshalb noch keinen `svg_hash`, und der Payload liefert bis zum Upload kein Bild.
- **Trockenlauf in Prod** (begin → apply → assert → rollback): Er braucht Schreibrechte außerhalb von `dbread`.
  Ersetzt wurde er durch den Trockenlauf in der Wegwerf-DB mit allen Migrationen.

## Befunde: wo die DB oder der Ablauf vom Auftrag abweicht

| # | Befund | Entscheidung |
|---|---|---|
| B1 | graph-02 und graph-03 hatten wortgleichen Text, sie unterschieden sich nur in der Abbildung; Stufe 1 meldet das als Dublette. | graph-03 heißt jetzt Funktion **g** (Text und Figur). Lösung unverändert, nichts neu gewürfelt. Ein zweiter, frischer Löser hat die Aufgabe danach neu gelöst. |
| B2 | Der Blind-Löser merkt an: Bei graph-04 ist die Beschriftung „f“ am rechten Bildrand halb abgeschnitten. Er hält das für unkritisch. | Generator-Sache (Label-Anker bei steilen Geraden), nicht in diesem Lauf. Offener Punkt fürs Foundation-Fenster. |
| B3 | `nur_einmal_addiert` (steigung-06) ist Altbestand ohne Familie, von A20 aus Prod-Daten geseedet. Ein Neuaufbau kennt ihn nicht. | Der Slug existiert live und passt fachlich. A4 prüft streng, sobald der Altbestand da ist, sonst Hinweis. Im Elternbericht erscheint er erst mit Familie und Klartext. |
| B4 | Seit W1-4 (`themen_katalog_mathe`) steht `themen.lineare_funktionen` auf **Klasse 7** (Stufe erste), nicht mehr auf 8. Der Kommentar in Migration 1 und der Stoffanker-Grund in `tasks.vorbefuellt` sagen noch „Katalog auf Klasse 8“. | Wert bleibt **8**: Alle 30 Kölner Schulpläne mit diesem Thema legen es in Klasse 8 (`schul_themenplan`, 30/30). Nur der Begründungstext ist überholt. Korrektur-Vorschlag unten, nicht eingespielt. |
| B5 | `thema_einstieg` hat keinen Eintrag für `lineare_funktionen`. | Nicht Teil von W1-1. Vorschlag: `fkt_linear_nullstelle` (8) und `fkt_linear_graph` (7) als Einstieg. Die Entscheidung liegt beim Themen-Lauf. |
| B6 | Keine MULTI_PART-Aufgaben. | `vorlauf-build.mjs` erzwingt dort Teilbudgets mit Summe gleich Aufgabe, und die Summenregel ist gestrichen (Rasit). Alle 30 sind NUMERIC. Damit greift die Fehlbild-Erkennung, und „Lösung je Teilaufgabe“ entfällt. |
| B7 | Aufgaben, deren Ergebnis ein Funktionsterm ist, gibt es nicht. | TERM sperrt Fehlbilder (`lsa_term_acceptance_guard`), MC kennt `vorlauf-build` nicht. Die Gleichungs-Aufgaben fragen deshalb nach einem Funktionswert oder nach b; dafür muss die Gleichung vorher aufgestellt sein. |

Korrektur zu B4, falls gewünscht. Es ist eine reine Textänderung im Kennzeichen, der Wert bleibt:

```sql
update public.tasks
   set vorbefuellt = jsonb_set(vorbefuellt, '{curriculum_grade,grund}',
         to_jsonb('Stoffanker Klasse 8: KLP G9 Funktionen, Erste Stufe (Fkt-4 bis Fkt-7); alle 30 Kölner Schulpläne mit dem Thema legen es in Klasse 8.'::text))
 where source = 'edvance_k8_linfkt' and status = 'draft';
```

## Die Aufgaben

**Je Knoten:** vier reine Anwendungen mit steigender Schwierigkeit und zwei mit Sachkontext (Fkt-6) oder Rückrichtung.

**Fest für alle 30 Aufgaben:**
- `status draft`
- Stoffanker 8
- Cluster „Algebra & Funktionen“
- Inhaltsfeld `funktionen`
- keine Hinweise
- keine Personen

**Zeitregel:**

| AFB | Zeit |
|---|---|
| I | 45 s |
| II | 60 s |
| III | 90 s |

Bei Sachkontext kommen 30 s dazu.

**Sondierrang** nach `docs/sondierrang_vorschlag.md`, Rang 1 und 2 je Knoten aus verschiedenen Fehlbildprofilen:

| Knoten | Rang 1 | Rang 2 |
|---|---|---|
| steigung | steigung-06 | steigung-02 |
| yabschnitt | yabschnitt-03 | yabschnitt-05 |
| graph | graph-01 | graph-06 |
| gleichung | gleichung-01 | gleichung-04 |
| nullstelle | nullstelle-02 | nullstelle-04 |

**AFB-Raster:**

| AFB | Was es heißt |
|---|---|
| I | Reproduzieren: ein Verfahren direkt, ganzzahlig, ohne Vorzeichenfalle |
| II | Anwenden: ein zusätzlicher Schritt (negative Werte, Bruch, Sachkontext übersetzen, Rückrichtung) |
| III | Bedingung selbst aufstellen und nach einem Parameter auflösen |

| source_ref | Knoten | AFB | Zeit (s) | Lösung | Fehlbilder | AFB-Begründung |
|---|---|---|---|---|---|---|
| linfkt-steigung-01 | steigung | I | 45 | 3 | seiten_verwechselt, steigung_kehrwert | Reproduzieren: Steigungsformel mit positiven, ganzzahligen Koordinaten, Ergebnis ganzzahlig. |
| linfkt-steigung-02 | steigung | I | 45 | 2 | seiten_verwechselt, steigung_kehrwert | Reproduzieren: Steigungsformel, ein Punkt auf der y-Achse, kleine ganze Zahlen. |
| linfkt-steigung-03 | steigung | II | 60 | -2 | betrag_fehler, steigung_kehrwert | Anwenden: Differenzen mit negativen Koordinaten, Minus vor Minus im Nenner. |
| linfkt-steigung-04 | steigung | II | 60 | 1/2 | seiten_verwechselt, steigung_kehrwert | Anwenden: negative Koordinaten in beiden Punkten, Ergebnis als gekürzter Bruch. |
| linfkt-steigung-05 | steigung | II | 90 | 1,5 | b_ignoriert, steigung_kehrwert | Anwenden: Sachsituation als zwei Punkte lesen, Steigung als Preis je km deuten (Fkt-6). |
| linfkt-steigung-06 | steigung | II | 60 | 9 | b_ignoriert, nur_einmal_addiert, steigung_kehrwert | Anwenden in Rückrichtung: aus Steigung und Punkt den Zuwachs über drei Schritte bestimmen. |
| linfkt-yabschnitt-01 | yabschnitt | I | 45 | 5 | m_b_vertauscht | Reproduzieren: b direkt aus y = mx + b ablesen, beide Zahlen positiv. |
| linfkt-yabschnitt-02 | yabschnitt | I | 45 | 7 | achsenabschnitt_verwechselt, m_b_vertauscht | Reproduzieren: b ablesen, Steigung negativ als Ablenkung. |
| linfkt-yabschnitt-03 | yabschnitt | II | 60 | -6 | achsenabschnitt_verwechselt, betrag_fehler, m_b_vertauscht | Anwenden: b steht als Subtraktion da und muss als negative Zahl gelesen werden. |
| linfkt-yabschnitt-04 | yabschnitt | II | 60 | -2 | addiert_statt_subtrahiert, betrag_fehler | Anwenden: Punkt in y = mx + b einsetzen und nach b auflösen. |
| linfkt-yabschnitt-05 | yabschnitt | II | 90 | 8 | achsenabschnitt_verwechselt, groessen_vertauscht | Anwenden: Parameter b in der Sachsituation als Grundpreis deuten (Fkt-6). |
| linfkt-yabschnitt-06 | yabschnitt | II | 90 | 120 | achsenabschnitt_verwechselt, groessen_vertauscht | Anwenden: y-Achsenabschnitt als Anfangswert einer Sachsituation deuten (Fkt-6). |
| linfkt-graph-01 | graph | I | 45 | 1 | achsenabschnitt_verwechselt, m_b_vertauscht | Reproduzieren: Schnittpunkt mit der y-Achse auf einem Gitterpunkt ablesen. |
| linfkt-graph-02 | graph | I | 45 | -1 | betrag_fehler, m_b_vertauscht | Reproduzieren: Steigungsdreieck mit einem Schritt nach rechts, Steigung ganzzahlig. |
| linfkt-graph-03 | graph | II | 60 | 1/2 | m_b_vertauscht, steigung_kehrwert | Anwenden: Steigungsdreieck über zwei Kästchen nach rechts, Steigung als Bruch. |
| linfkt-graph-04 | graph | II | 60 | -1 | koordinate_vorzeichen_verloren, koordinaten_vertauscht | Anwenden: Funktionswert im vierten Quadranten ablesen, Ergebnis negativ. |
| linfkt-graph-05 | graph | II | 60 | 2 | falsche_groesse_beantwortet, koordinaten_vertauscht | Anwenden in Rückrichtung: vom y-Wert waagerecht zum Graphen, dann die Stelle ablesen. |
| linfkt-graph-06 | graph | II | 90 | 2 | groessen_vertauscht, steigung_kehrwert | Anwenden: Steigung am Graphen ablesen und als Preis pro Stunde deuten (Fkt-6). |
| linfkt-gleichung-01 | gleichung | I | 45 | 10 | m_b_vertauscht, vorzeichen_ignoriert | Reproduzieren: m und b in y = mx + b einsetzen, dann einen Wert berechnen. |
| linfkt-gleichung-02 | gleichung | I | 45 | -1 | betrag_fehler, m_b_vertauscht | Reproduzieren: Gleichung aus m und b, Einsetzen mit negativem Faktor. |
| linfkt-gleichung-03 | gleichung | II | 60 | 19 | m_b_vertauscht, seiten_verwechselt | Anwenden: m aus zwei Punkten, b aus dem Punkt auf der y-Achse, dann einsetzen. |
| linfkt-gleichung-04 | gleichung | II | 60 | -2 | addiert_statt_subtrahiert, steigung_kehrwert | Anwenden: erst m aus zwei Punkten, dann b durch Einsetzen; kein Punkt auf der y-Achse. |
| linfkt-gleichung-05 | gleichung | II | 90 | 11 | b_ignoriert, groessen_vertauscht | Anwenden: Grundgebühr und Preis pro km als b und m deuten, Gleichung aufstellen und auswerten (Fkt-6). |
| linfkt-gleichung-06 | gleichung | II | 90 | 15 | falsche_groesse_beantwortet, vorzeichen_ignoriert | Anwenden: fallende Größe als negative Steigung modellieren, dann auswerten (Fkt-6). |
| linfkt-nullstelle-01 | nullstelle | I | 45 | 4 | betrag_fehler, division_vergessen | Reproduzieren: f(x) = 0 setzen, zwei Umformungsschritte, Ergebnis ganzzahlig. |
| linfkt-nullstelle-02 | nullstelle | I | 45 | -2 | achsenabschnitt_verwechselt, betrag_fehler, division_vergessen | Reproduzieren: f(x) = 0 setzen und auflösen, Ergebnis negativ und ganzzahlig. |
| linfkt-nullstelle-03 | nullstelle | II | 60 | 2,5 | achsenabschnitt_verwechselt, vorzeichen_beim_umstellen | Anwenden: Division durch einen negativen Koeffizienten, Ergebnis als Dezimalzahl. |
| linfkt-nullstelle-04 | nullstelle | II | 60 | -6 | betrag_fehler, falsche_gegenoperation | Anwenden: Division durch eine Dezimalzahl kleiner als eins, das Ergebnis wird betragsmäßig größer. |
| linfkt-nullstelle-05 | nullstelle | II | 90 | 5 | achsenabschnitt_verwechselt, vorzeichen_beim_umstellen | Anwenden: die Frage „leer" als Nullstelle erkennen und im Sachkontext deuten (Fkt-6/7). |
| linfkt-nullstelle-06 | nullstelle | III | 90 | -6 | achsenabschnitt_verwechselt, betrag_fehler | Verallgemeinern/Rückrichtung: die Bedingung f(2) = 0 selbst aufstellen und nach dem Parameter b auflösen. |

**Abdeckung der neuen Fehlbilder:**

| Fehlbild | Aufgaben |
|---|---|
| `steigung_kehrwert` | 9 |
| `m_b_vertauscht` | 9 |
| `achsenabschnitt_verwechselt` | 9 |

Verlangt waren je mindestens 3.

Schreibweisen: Jede Lösung und jeder Falschwert steht mit Komma und Punkt, mit `-`, `−` und `- ` bzw. `+`, als Bruch
und als Dezimalzahl und mit Einheit. `lsa_is_correct` normalisiert das Unicode-Minus nicht.

## Freigabe durch Lena

1. **Fehlbilder:**
   ```sql
   update public.fehlbild_labels set freigegeben_am = now(), freigegeben_von = '<profil-uuid>'
    where slug in ('steigung_kehrwert','m_b_vertauscht','achsenabschnitt_verwechselt');
   ```
2. **Aufgaben** einzeln im Editor prüfen und auf `ready` setzen: `task_status_set`, das Freigabe-Gate prüft die Pflichtfelder.
   Für einen Abstieg müssen auch die Vorlauf-Aufgaben zu `geo_koordinaten` und `term_einsetzen` freigegeben sein;
   beide stehen heute auf `draft`.
3. **Figuren:** Rasit lädt sie hoch mit `python3 scripts/figures/upload_figures.py`. Danach haben die 6 `task_figures`-Zeilen einen `svg_hash`.

## Test-LSA mit Einstieg Lineare Funktionen (läuft erst nach Lenas Freigabe)

**Voraussetzungen, die heute fehlen:**

1. **Freigabe.** `lsa_start` zieht nur `status = 'ready'`. Gebraucht werden: die 30 Aufgaben, die Vorlauf-Aufgaben zu
   `geo_koordinaten` und `term_einsetzen` und die 6 Figur-Uploads.
2. **Themen-Einstieg.** `lsa_start(uuid, integer, text, text, timestamptz)` hat keinen Themen-Parameter, und
   `thema_einstieg` kennt `lineare_funktionen` noch nicht (B5). Der Einstieg lässt sich erst mit W3-6
   (Thema → Tiefe → Breite) erzwingen. Bis dahin nimmt die Auswahl das erste Blatt nach Abdeckung.

**Befehlsfolge, sobald beides steht** (Testschüler aus `tools/seed/zz_schuelerakten_seed.sql`, Kennung `ZZ_`):

```bash
# 0. Ziel-DB prüfen; Testakten anlegen, falls nicht vorhanden
psql "$DATABASE_URL" -tAc "select current_database()" | grep -qx postgres
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f tools/seed/zz_schuelerakten_seed.sql

# 1. Freigabe-Stand prüfen (lesend): 30 ready, Voraussetzungen ready, Figuren mit Hash
~/bin/dbread -c "select skill_key, count(*) filter (where status='ready') ready from tasks
  where skill_key like 'fkt_linear_%' or skill_key in ('geo_koordinaten','term_einsetzen','gleichung_neg_koeffizient','proportionalitaet') group by 1 order by 1"
~/bin/dbread -c "select count(*) filter (where svg_hash is null) ohne_hash from task_figures f join tasks t on t.id=f.task_id where t.source='edvance_k8_linfkt'"

# 2. Session starten als Test-Coach (lsa_may_act_for), Einstieg Lineare Funktionen über W3-6
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'SQL'
begin;
select set_config('request.jwt.claims', json_build_object('sub', p.id, 'role', 'authenticated')::text, true)
  from profiles p where p.email = 'zz_testcoach@edvance.invalid';
select public.lsa_start(
  (select l.converted_student_id from leads l where l.full_name = 'ZZ_S2B Mia Plan'), 8, 'Mathematik', 'adaptiv');
commit;
SQL

# 3. Je Item: Abgabe mit einem bekannten falschen Wert, dann lsa_select_next.
#    Beispiel nullstelle-01 (f(x) = 2x - 8): '{"value":"-4"}' -> erwartet betrag_fehler,
#    danach Abstieg nach fkt_linear_gleichung (7) bzw. gleichung_neg_koeffizient (7).
#    lsa_submit(<session>, <task>, '{"value":"-4"}'::jsonb)

# 4. Auswertung (lesend): Fehlbild erfasst und Abstieg gelaufen
~/bin/dbread -c "select t.skill_key, r.correct, r.fehlbild_slug from lsa_responses r join tasks t on t.id = r.task_id
  where r.session_id = '<session>' order by r.created_at"
~/bin/dbread -c "select skill_key, zustand, offen from lsa_skill_urteil where session_id = '<session>'"

# 5. Aufräumen
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f tools/seed/zz_schuelerakten_teardown.sql
```

**Erwartung:**
1. Bei nullstelle-01 ergibt `-4` → `fehlbild_slug = 'betrag_fehler'`.
2. Danach führt der Abstieg in die tiefste Voraussetzung, also `fkt_linear_gleichung` oder `gleichung_neg_koeffizient` (beide 7).
3. Von dort geht es über Steigung und y-Achsenabschnitt (5/6) ins Fundament: `geo_koordinaten`, `term_einsetzen`, `proportionalitaet`.

## Dateien

| Datei | Rolle |
|---|---|
| `tools/k8-linfkt-aufgaben.mjs` | die 30 Aufgabendefinitionen (Quelle) |
| `tools/k8-linfkt-charge.mjs` | baut `k8-linfkt.json`, rechnet jede Zahl exakt nach |
| `docs/prefill/k8-linfkt.json`, `-ids.json`, `-snapshot.json` | Charge, stabile ids, Rohzustand für verify-prefill |
| `docs/prefill/k8-linfkt.csv` | alle Felder mit Wert, Unsicherheit und Begründung, für Lena |
| `docs/prefill/k8-linfkt-blind.json` | Antworten des Blind-Lösers |
| `docs/prefill/k8-linfkt-verifikation.md` | Protokoll von `verify-tasks --prefill` |
| `supabase/checks/k8_linfkt_{substrat,aufgaben}.PRUEFUNG.sql` | Prüfskripte |
