# W3-6 — LSA-Auswahl: erst das Thema, dann die Tiefe, dann die Breite

Branch `feat/lsa-thema-einstieg`. Migrationen:

- `20261003092850_lsa_thema_einstieg.sql`: Funktionen und Einstiegsknoten für Linear und Zins
- `20261003093007_lsa_thema_einstieg_kreis.sql`: Einstiegsknoten für Kreis, erst nach dem Kreis-Substrat einspielen

Test: `supabase/tests/inv10_lsa_thema_auswahl.test.sql`.
Trockenlauf: `supabase/checks/lsa_thema_einstieg_trockenlauf.PRUEFUNG.sql`.

## Voraussetzungen (per `dbread` am 03.10.2026)

| Prüfung | Befund |
|---|---|
| `themen.stufe`, `thema_einstieg`, `lead_themen`, `lsa_sessions.thema_key` | vorhanden |
| `fkt_linear_*` (5 Knoten) | vorhanden, 30 Aufgaben, **alle `draft`** |
| `prozent_zins_*` (4 Knoten) | vorhanden, 24 Aufgaben, **alle `draft`** |
| `geo_kreis_*` | **fehlen in Prod** (`20261001131855` steht nicht in der History) |
| `thema_einstieg` | 5 Zeilen (Binom 4, Gleichungen 1), werden nicht angefasst |
| `lead_themen` | 0 Zeilen |
| Repo und Prod | `lsa_select_next_core`, `lsa_start`, `lead_lsa_freigeben`, `lsa_submit`, `lsa_abschluss` und `lsa_urteil_buchen_core` sind im Repo und in Prod zeichengleich (`schema-erwartet.sql` gegen `pg_get_functiondef`) |

## Abhängige Funktionen (pg_proc)

Diese Funktionen lesen `lsa_select_next_core`, `lsa_skill_urteil` oder `skills.fundament_tiefe`. Views sind nicht betroffen.

| Funktion | liest | geändert |
|---|---|---|
| `lsa_select_next(uuid,text[])` | select_next_core | nein |
| `lsa_start(uuid,integer,text,text,timestamptz)` | select_next_core | **ja**, nur Zweig adaptiv: setzt `thema_key` |
| `lsa_submit(uuid,uuid,jsonb,integer,timestamptz)` | select_next_core | nein |
| `lsa_select_next_core(uuid,text[],timestamptz)` | skill_urteil, fundament_tiefe | **ja**, neue Reihenfolge |
| `lsa_urteil_buchen_core(uuid,uuid)` | skill_urteil | nein |
| `lsa_mitbelegung(uuid,text)` | skill_urteil | nein |
| `lsa_uebernahme(uuid,uuid,timestamptz)` | skill_urteil | nein |
| `skill_kante_tiefe_guard()` | fundament_tiefe | nein |

Neu ist `lsa_lead_von_schueler(uuid)`. Der Name war frei. Ausführen darf sie nur `service_role` (wie bei `lsa_abschluss`). Die Signaturen von `lsa_start` und `lead_lsa_freigeben` bleiben gleich.

## Teil 1 — Vom Schüler zum Lead

Belegt aus dem Bestand:

- `lead_lsa_freigeben` legt die provisorische Schülerzeile mit `students.lead_id` an.
- `students_provisional_lead_ck` erzwingt `is_provisional = (lead_id is not null)`.
- Nach der Konversion zeigt `leads.converted_student_id` auf den Schüler, und `lead_id` ist leer.
- `lsa_lead_kontext` und `lsa_uebernahme` gehen schon genauso vor: erst `lead_id`, dann `converted_student_id`.

`lsa_lead_von_schueler` übernimmt diese Reihenfolge. `lsa_start` setzt im Modus adaptiv `thema_key` auf das `aktuell`-Thema des Leads im Fach der Sitzung. Groß- und Kleinschreibung zählt dabei nicht, denn die Sitzung trägt `Mathematik`, der Katalog `mathematik`. Ein Thema ohne Einstiegsknoten oder ohne ready-Aufgaben wird trotzdem eingetragen, es entfällt dann nur Phase T. Im Modus `fest` bleibt alles wie bisher, `thema_key` ist dort NULL.

## Teil 2 — Neue Reihenfolge

1. **Schritt 2, Zweitbeleg:** unverändert und immer zuerst.
2. **Phase T:** der nächste ungeprüfte Einstiegsknoten des Themas. Es gilt „größter offener Abschluss zuerst“, dieselbe Kennzahl wie in der gierigen Deckung.
   - Zuerst werden **alle** Einstiegsknoten geprüft, dann folgt der Abstieg. Ein Einstieg, der trägt, belegt seinen Abschluss mit, und ein zweiter Einstieg darin fällt dann weg.
   - In Frage kommen nur Knoten mit einer noch freien Aufgabe. Ein Thema ohne Aufgaben überspringt Phase T, ohne `ungeprueft`-Zeilen anzulegen.
3. **Phase Tiefe:** der bisherige Schritt 3 mit zwei Einschränkungen.
   - Der Abstieg beginnt nur an Knoten aus dem *Themenraum*, also den Einstiegsknoten plus ihrem `lsa_abschluss`.
   - Er läuft nur, solange `p_jetzt < Beginn + c_tiefe_bis` gilt. `c_tiefe_bis` ist die benannte Konstante (12 Minuten) mit Kommentar.
4. **Breite a:** die Einstiegsknoten der `behandelt`-Themen.
   - Rang ist die Stellung im Schulplan der Lead-Schule als `klasse * 1000 + position`, denn `position` beginnt je Klasse neu. Ein Thema, das mehrmals im Plan steht, zählt mit seinem spätesten Vorkommen.
   - Ohne Plan entscheidet `themen.sort` absteigend.
   - Innerhalb eines Themas gilt wieder „größter offener Abschluss“.
5. **Breite b:** der bisherige Schritt 4, also die gierige Deckung.
6. **Schritt 5, Restzeit:** unverändert.

**Kein Abstieg in der Breite:** Schritt 3 steigt nur noch unter dem Themenraum ab. Ein Knoten aus der Breite, der bricht, wird nach der Zweitbeleg-Regel fertig geprüft, danach kommt der nächste Knoten.

**Klassengrenze:** `skills.klasse_herkunft <= lsa_sessions.grade` gilt in Phase T, Tiefe, Breite a/b und Schritt 5. Nur für Schritt 2 gilt sie nicht, weil dort ein schon gezogener Knoten seinen Zweitbeleg bekommt.

Unverändert bleiben das 19-Minuten-Fenster, das Schleifenlimit von 100 Durchläufen, `lsa_urteil_buchen_core` mit Mit-Belegung, der Modus `fest` und die RLS.

## Teil 3 — Reicht `thema_key` + `lsa_abschluss` für den Report?

**Ja.** `lsa_skill_urteil` bekommt keine Spalte. Geprüft wurden diese Fälle:

| Fall | Ableitung aus `thema_key` + Abschluss |
|---|---|
| Knoten in der Breite geprüft, liegt aber unter dem Thema | Er liegt tatsächlich unter dem Thema. „Unter dem Thema“ beschreibt die Lage im Graphen, nicht die Phase, in der geprüft wurde. Der Befund stimmt also. |
| Mitbelegt unter dem Thema | `belegt_direkt = false` unterscheidet ihn |
| Knoten ohne Aufgabe im Abstieg | `zustand = 'ungeprueft'` unterscheidet ihn |
| Abstieg bei Minute 12 abgebrochen | Knoten im Themenraum ohne Urteilszeile, während ein Knoten darüber gebrochen ist |
| Einstieg eines `behandelt`-Themas, der zugleich im Themenraum liegt | Beides ist ableitbar, das zweite über `lead_themen` |

Ein Vorbehalt: Die Ableitung liest `thema_einstieg` und `skill_kante` so, wie sie *heute* stehen. Ändern sie sich später, verschiebt sich „unter dem Thema“ auch für alte Sitzungen. Das betrifft die Mit-Belegung und die Ebenen im Report (`fundament_tiefe`) heute schon genauso. Wenn alte Reports stabil bleiben sollen, gehört der Themenraum beim Abschluss in `result_summary`. Das ist kein Stopp-Grund für W3-6.

Der Report selbst (`src/lib/report/rueckbezug.ts`, `strukturell()`) erzählt weiterhin alles unterhalb der Einstiegsebene als „darunter geprüft“. Die Umstellung auf den Themenraum ist ein Folgeauftrag.

## Teil 4 — Einstiegsknoten

| Thema | Einstieg | Begründung |
|---|---|---|
| `lineare_funktionen` | `fkt_linear_gleichung`, `fkt_linear_steigung`, `fkt_linear_yabschnitt` | Die Gleichung ist der Kern und hängt an Steigung und y-Abschnitt. Trägt sie, sind beide mitbelegt. Bricht sie, werden beide eigens geprüft. |
| `zinsrechnung` | `prozent_zins_zinseszins`, `prozent_zins_jahreszins` | Zinseszins hat den größten Abschluss (Jahreszins, Potenzen, prozentuale Veränderung). Jahreszins ist der Grundfall, den Teil- und Rückrechnung voraussetzen. |
| `kreis` | `geo_kreis_umfang`, `geo_kreis_flaeche` | Zwei Grundfälle auf Tiefe 6, die sich nicht gegenseitig tragen. Sektor, Rückrechnung und zusammengesetzte Figuren hängen an ihnen. |

Nicht aufgenommen:

- `fkt_linear_graph` hat dieselben Voraussetzungen wie die Gleichung und brächte nichts Neues.
- `fkt_linear_nullstelle` lässt der Auftrag weg. Seine Begründung „Abstiegsziel“ stimmt aber nicht mit der DB überein: Die Nullstelle *setzt die Gleichung voraus*, liegt also über ihr und nicht darunter. Weggelassen bleibt sie trotzdem, weil sie eine Anwendung ist und nicht der Kern. Die Breite erreicht sie als Blatt.

Je Thema gibt es höchstens drei Einstiege. Ein dritter Einstieg bei Zins oder Kreis würde nur den Befund des Grundfalls wiederholen.

## Teil 5 — Tests

`inv10_lsa_thema_auswahl` hat 28 Zusicherungen und arbeitet auf einem eigenen Graphen. Das echte Fundament wird dafür transaktionslokal ausgeblendet. Die Zeitpunkte sind fest über `p_jetzt`, die Antworten laufen über `lsa_submit`.

| # | Zusage | Folge der gezogenen Knoten |
|---|---|---|
| 0 | `thema_key` über `lead_id` und über `converted_student_id`; ohne Lead NULL; Thema ohne Aufgaben wird gesetzt und Phase T entfällt | — |
| 1 | Thema trägt sofort | `e1, e2, ba, bb, g1, –`: zuerst Einstiege, dann behandelt (Schulplan schlägt `sort`), dann gierig |
| 2 | Thema bricht | `e1, e1, e2, p1, p1, p2, ba, ba, bb`: kein Abstieg unter `ba` |
| 3 | bricht tief, Minute 12 | 3-Minuten-Takt: `e1, e1, e2, e2, ba`; Kontrolle mit 2,5-Minuten-Takt: `…, p1` |
| 4 | kein Thema | erste Aufgabe `bb` (`themen.sort`); ohne Lead `e1, e1, ba` (kein Abstieg) |
| 5 | Klasse 7 | bis zum Ende alles falsch: kein Knoten der Klasse 8/9; Kontrolle Klasse 9 zieht `h9` |
| 6 | Zweitbeleg zuerst | in T, Tiefe, Breite a, Breite b und nach Minute 12 |
| 7 | `fest` | `total_items`, kein Thema, Antwort über `item_ids`, keine Urteile |

**Lokaler CI-Nachbau** (`test-grundlage` → alle Migrationen → pgTAP → `seed.sql` → Tests, wie `schema.yml`):

```
Migrationen ok
  ok     a11_abgestufte_bewertung (29 Zusicherungen)
  ok     a2_lead_delete (8 Zusicherungen)
  wartet a3_lead_assessments (rot)
  wartet a4_is_tutorial (rot)
  ok     inv10_lsa_thema_auswahl (28 Zusicherungen)
  ok     inv1_mastery_gate (8 Zusicherungen)
  wartet inv2_lsa_datenvertrag (rot)
  wartet inv3_lsa_multipart (rot)
  ok     inv4_rls_coverage (2 Zusicherungen)
  ok     inv5_lsa_tabellen (15 Zusicherungen)
  wartet inv6_keine_loesung_fuer_schueler (rot)
  wartet inv7_draft_nicht_fuer_schueler (rot)
  ok     inv8_vorschau_ohne_loesung (16 Zusicherungen)
  ok     inv9_bild_notwendigkeit (7 Zusicherungen)
  wartet s7_lead_lsa (rot)
  wartet s9_platz_mechanik (rot)
```

Die acht wartenden Tests stehen unverändert in `bekannt-rot.txt` und waren vor der Änderung genauso rot.

**Gegenprobe:** Mit den alten Funktionen (Live-Fassung) scheitern 17 der 28 Zusicherungen. Ein Beispiel ist Fall 2 mit `zt_h9, zt_h9, zt_h8, …, zt_ba, zt_ba, zt_q`: Das ist genau der alte Fehler, nämlich Start im ganzen Fundament, über der Klasse und mit Abstieg in der Breite. Grün bleiben in beiden Fassungen nur die Invarianten (19-Minuten-Fenster, Mitbelegung, Zweitbeleg-Urteil, `fest`) und die Kontrollfälle (ohne Lead kein Thema, Klasse 9 zieht `h9`).

## Trockenlauf gegen die echte DB

Das Skript `supabase/checks/lsa_thema_einstieg_trockenlauf.PRUEFUNG.sql` läuft so ab:

1. Ziel-DB-Check, dann `begin`.
2. Die Migration wird eingespielt.
3. Vier Sitzungen mit ZZ-Testleads an echten Knoten:
   - S0: heutiger Stand
   - S1: Linear trägt
   - S2: Linear bricht
   - S3: Klasse 7, Zins bricht tief
4. Ab S1 werden Linear- und Zins-Aufgaben transaktionslokal auf `ready` gesetzt, wie nach Lenas Freigabe.
5. `rollback`, danach die Gegenprobe, dass kein ZZ-Lead stehen bleibt.

Der Lauf gegen Prod steht noch aus. Er schreibt in einer Transaktion, die zurückgerollt wird, und das hat die Sitzungsprüfung abgelehnt. Lokal ist das Skript gegen eine Wegwerf-DB aus allen Migrationen gelaufen (Exit 0, keine Zeile über der Klasse, 0 ZZ-Leads nach dem Rollback). Dort gibt es aber weniger Aufgaben als in Prod. Die Abläufe aus Prod kommen in den PR, sobald der Lauf gemacht ist.

## Befunde und offene Punkte

1. **9 Sitzungen stehen auf `in_progress`.** Alle sind verwaist: Sie wurden zwischen dem 15.07. und dem 20.09. gestartet und liegen weit außerhalb des 19-Minuten-Fensters. Laut Auftrag wird `lsa_select_next_core` erst eingespielt, wenn keine mehr läuft. Rasit entscheidet, ob sie abgeschlossen werden oder als „läuft nicht“ gelten.
2. **Bis Erstgespräch und Freigabe greifen, läuft jede LSA nur in der Breite.**
   - `lead_themen` ist leer, und alle Linear-, Zins- und Binom-Aufgaben stehen auf `draft`.
   - Ohne Thema fällt der Abstieg ganz weg. Das ist so gewollt („Ohne Phase T: direkt Breite“, „In der Breite kein Abstieg“).
   - Gegenüber heute fehlt damit bis dahin die Ursachensuche unter gebrochenen Blättern.
3. **Klasse 7 mit Thema Lineare Funktionen:**
   - `themen.lineare_funktionen` steht in der Stufe `erste` (7/8), die `fkt_linear_*`-Knoten tragen aber `klasse_herkunft = 8`.
   - Für ein Kind der Klasse 7 entfällt Phase T deshalb wegen der Klassengrenze.
   - Für Kreis (Knoten Klasse 9) gilt dasselbe unterhalb der Klasse 9.
   - `feat/report-stufen` korrigiert gerade `klasse_herkunft`-Werte gegen den KLP. Beides gehört zusammen betrachtet.
4. **CI wird erst nach dem Einspielen grün.** `schema-erwartet.sql` wird aus Prod gezogen, und die neuen Funktionsrümpfe weichen davon ab, bis sie eingespielt sind und `tools/schema-snapshot.sh` neu gelaufen ist.
5. **Kreis-Migration** erst einspielen, wenn per `dbread` alle fünf `geo_kreis_*` existieren. Fehlt einer, scheitert sie laut am Fremdschlüssel. Der parallele Kreis-Lauf versioniert sein Substrat auf `20261003091339` um. `20261003093007` liegt in beiden Fällen dahinter.
6. **Report-Folgeauftrag:** „darunter geprüft“ soll auf den Themenraum umgestellt werden (siehe Teil 3).

## Einspielen (Rasit)

1. Per `dbread` prüfen, dass `select count(*) from lsa_sessions where status = 'in_progress'` 0 ergibt (siehe Punkt 1).
2. Den Trockenlauf gegen Prod laufen lassen und die Ausgabe in den PR übernehmen.
3. `20261003092850_lsa_thema_einstieg.sql` mit `--single-transaction` einspielen und in die History eintragen.
4. `bash tools/schema-snapshot.sh` laufen lassen und `supabase/schema-erwartet.sql` committen.
5. Sobald alle `geo_kreis_*` in Prod existieren: `20261003093007_lsa_thema_einstieg_kreis.sql` einspielen.
