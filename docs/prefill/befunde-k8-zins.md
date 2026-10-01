# Befunde K8 Zinsrechnung

Stand 01.10.2026. Auftrag `W1-2-zinsrechnung.md`, Phase-0-Bericht und Entscheidungen in `docs/k8/zins-phase0.md`.
Gelesen wurde die Live-DB nur lesend, ab Phase B ausschließlich über `~/bin/dbread`. Beide Migrationen hat dieser Lauf
selbst eingespielt; die Freigabe dafür hat Rasit im Chat erteilt.

## Einspiel-Reihenfolge (erledigt)

| Nr. | Datei | Inhalt | Stand |
|---|---|---|---|
| – | Vorlauf `20261001115718` / `115812` / `120554` | Tiefe 1..12, `term_einsetzen` | vom Vorlauf eingespielt, Voraussetzung per SELECT geprüft |
| 1 | `20261001123347_substrat_k8_zins.sql` | 4 Knoten, 11 Kanten, 5 Fehlbilder | **eingespielt**, History md5-gleich |
| 2 | `20261001125349_aufgaben_k8_zins.sql` | 24 Zins- und 6 potenzen-Aufgaben | **eingespielt** nach bestandener Blind-Prüfung, History md5-gleich |

Prüfabfragen: `docs/k8/zins-pruefung-m1.sql` (7 von 7 `t`) und `docs/k8/zins-pruefung-m2.sql` (17 von 17 `t`), beide
nach dem Einspielen gegen Prod. Keine Schemaänderung, deshalb kein `schema-snapshot.sh`.

**Merge-Reihenfolge:** `feat/k8-vorlauf` (PR #182) ist in diesen Branch gemergt. Der Vorlauf-PR muss vor diesem PR nach
`dev`, sonst trägt dieser PR dessen Commits mit.

## Prüfprotokoll (Phase C)

| Stufe | Werkzeug | Ergebnis |
|---|---|---|
| Rechnung beim Erzeugen | `tools/k8-zins-charge.mjs` (exakt, Brüche) | jede Antwort, jeder falsche Wert, jede Probe und die Probier-Tabelle nachgerechnet |
| Alle Lena-Felder | `verify-tasks --prefill` (verify-prefill) | **0 Gate-Fehler**, 111 Nachrechnungen ok → `k8-zins-verifikation.md` |
| Struktur | `verify-tasks --from-file` Stufe 1 | 30 ok, 0 beanstandet |
| Blind-Löser | frischer Subagent, nur `aufgaben.json` (Export ohne Lösungen) | 30 Antworten, 0 unsicher → `k8-zins-blind.json` |
| Abgleich | `verify-tasks --from-file … --answers-from … --min-pass 1.0` | **30/30, 100 %**. Kein zweiter Löser nötig |
| Gegenprobe Prod | `lsa_grade` und `lsa_is_correct` (ohne Toleranz) auf die Blind-Antworten | 30/30 und 30/30 |
| Wegwerf-DB | Grundlage + alle 86 Migrationen, zweiter Lauf | grün, idempotent (30 Aufgaben, 30 Lösungen) |
| Trockenlauf Prod | begin → Migration → Prüfabfrage → rollback | beide Migrationen grün, danach 0 Zeilen übrig |

`verify-prefill` lief **ohne** `--migration`, wie beim Vorlauf. Der Migrations-Check ist für UPDATE-Prefills auf
bestehende Aufgaben gebaut: Er meldet jeden INSERT einer neuen Aufgabe als „ohne VERA8-Ausschluss" und die Cluster-UUID
als „fremde Aufgabe" (31 Scheinfehler). Neue Aufgaben mit `source = 'edvance_k8_zins'` können VERA8 nicht berühren.

## Befunde: wo die DB vom Auftrag abweicht

| Nr. | Befund | Umgang |
|---|---|---|
| Z1 | `afb` ist `I/II/III`, nicht 1–3. | Römisch vergeben. Begründung je Aufgabe in der CSV (`afb`-Zeile) und unten. |
| Z2 | `known_errors` ist keine Spalte, sondern `task_solutions.acceptance.known_errors`. | Objektform `{falscher_wert: slug}`. |
| Z3 | Cent-Beträge sind im Bestand neu. `lsa_fehlbild_match` vergleicht Text, nicht Zahlen. | Jeder falsche Wert steht in allen Schreibweisen: mit/ohne Endnull, Komma/Punkt, mit „ €" und „€". Prüfabfrage M2 belegt, dass jeder Schlüssel seinen Slug trifft. |
| Z4 | Ein Tausenderpunkt („1.102,50") wird als falsch gewertet. | Alle richtigen Antworten liegen unter 1000 €. |
| Z5 | „Zu früh gerundet" kollidiert mit „Jahr für Jahr lösbar": Banken runden die Jahreszinsen auf Cent. | Zinseszins-Zahlen gehen jedes Jahr glatt auf Cent auf. Das Fehlbild entsteht nur durch Runden des Faktors (1,157625 → 1,16) oder des Zeitanteils (7/12 → 0,58). |
| Z6 | `vorlauf-build.mjs` hatte den Migrationskopf fest auf den Vorlauf geschrieben und vergibt Rang 1+2 für jeden Skill der Charge. | Zwei optionale Charge-Felder `kopf` und `ohne_sondierrang`. Der Vorlauf wird byte-gleich reproduziert (geprüft). |
| Z7 | `potenzen`: die drei freigegebenen Aufgaben sind `-2^2`, `√36`, `√144`. **Wurzeln hängen unter `potenzen`**, einen eigenen Wurzel-Knoten gibt es nicht. | Die √-Aufgaben bleiben unverändert. Für Lena und den Kreis-Lauf vermerkt: Wer `potenzen` nicht trägt, kann am Wurzelziehen gescheitert sein. |
| Z8 | `potenzen` hat Rang 1+2 schon auf freigegebenen Aufgaben (`potenzen-14`, `potenzen-15`). | Die sechs neuen Entwürfe bekommen keinen Rang (`ohne_sondierrang`). |
| Z9 | `class_level`: `vorlauf-build.mjs` setzt `null`, wie der Fundament-Bestand. | Übernommen. Das Board zählt `null` als „Klasse 8". |
| Z10 | Fehlbild-Eingabe mit „€" ohne Leerzeichen nach anderer Schreibweise (z. B. „44,1€") trifft nur, weil die Varianten mit „€" mitgegeben sind. Die eigentliche Ursache liegt in `lsa_fehlbild_match` (Textvergleich). | Fundament, nicht in diesem Lauf. Vorschlag: Zahlvergleich wie `lsa_values_equal`. |
| Z11 | `nur_prozentwert`, `multipliziert_statt_dividiert`, `faktor_100_vergessen`, `bezug_vertauscht`, `grundwert_verwechselt`, `kommastellen_zu_wenig`, `mal_exponent`, `basis_exponent_vertauscht` haben **keinen Klartext**. | Wiederverwendet wie entschieden. Für den Elternreport brauchen sie Klartext und Familie (Fundament-Entscheidung). |

## Die Aufgaben

Je Zins-Knoten vier reine Anwendung mit steigender Schwierigkeit, zwei mit Sachkontext oder Rückrichtung. Alle `NUMERIC`,
`status = 'draft'`, `curriculum_grade = 7`, Themengebiet „Zahl & Rechnen", `needs_image = false`, keine Hinweise.
`competency_content`: Zins `funktionen`, potenzen `arithmetik_algebra`. Zeitregel: AFB I 45 s, II 60 s, III 90 s,
+30 s bei Sachkontext.

| source_ref | Knoten | AFB | Rang | Antwort | Fehlbilder | AFB-Begründung |
|---|---|---|---|---|---|---|
| jahreszins-01 | jahreszins | I | – | 18 € | dezimalverschiebung, falsche_groesse_beantwortet | Prozentwert, ganzzahliger Zinssatz, ein Schritt |
| jahreszins-02 | jahreszins | I | – | 17 € | dezimalverschiebung, falsche_groesse_beantwortet | ein Schritt, Kapital nicht rund |
| jahreszins-03 | jahreszins | II | – | 16 € | dezimalverschiebung, falsche_groesse_beantwortet | Zinssatz 2,5 % als Dezimalzahl |
| jahreszins-04 | jahreszins | II | **1** | 496,80 € | nur_prozentwert, dezimalverschiebung | zwei Schritte, Ergebnis mit Cent |
| jahreszins-05 | jahreszins | II | – | 954 € | nur_prozentwert, dezimalverschiebung | Sachkontext Kredit übersetzen |
| jahreszins-06 | jahreszins | III | **2** | 1,25 € | bedingung_unvollstaendig, falsche_groesse_beantwortet | zwei Angebote modellieren, Bonus, Differenz |
| teilzins-01 | teilzins | I | – | 6 € | zeitfaktor_vergessen, zinszeit_falsch_umgerechnet | glatter Zeitanteil 1/4 |
| teilzins-02 | teilzins | I | – | 10 € | zeitfaktor_vergessen, zinszeit_falsch_umgerechnet | Zeitanteil 5/12, glattes Ergebnis |
| teilzins-03 | teilzins | II | – | 4 € | zeitfaktor_vergessen, zinszeit_falsch_umgerechnet | Tage nach 360-Tage-Konvention |
| teilzins-04 | teilzins | II | **2** | 15 € | zeitfaktor_vergessen, zinszeit_falsch_umgerechnet, zu_frueh_gerundet | Dezimal-Zinssatz, 8/12 geht nicht auf |
| teilzins-05 | teilzins | II | – | 8,33 € | zeitfaktor_vergessen, zinszeit_falsch_umgerechnet, zu_frueh_gerundet | Sachkontext Überziehung, Rundung am Ende |
| teilzins-06 | teilzins | III | **1** | 884,10 € | nur_prozentwert, zeitfaktor_vergessen, zu_frueh_gerundet | Ratenkauf, mehrere Schritte selbst ordnen |
| rueckrechnung-01 | rueckrechnung | I | – | 700 € | multipliziert_statt_dividiert, faktor_100_vergessen | Grundwert, glatter Satz |
| rueckrechnung-02 | rueckrechnung | I | – | 3 % | faktor_100_vergessen, bezug_vertauscht | Prozentsatz aus glatten Werten |
| rueckrechnung-03 | rueckrechnung | II | **2** | 600 € | multipliziert_statt_dividiert, faktor_100_vergessen | Grundwert mit Satz 3,5 % |
| rueckrechnung-04 | rueckrechnung | II | – | 3,25 % | faktor_100_vergessen, bezug_vertauscht | Prozentsatz mit Cent-Betrag |
| rueckrechnung-05 | rueckrechnung | III | – | 750 € | grundwert_verwechselt, multipliziert_statt_dividiert | Rückrichtung über 1,02; naheliegender Weg ist falsch |
| rueckrechnung-06 | rueckrechnung | II | **1** | 7 % | falsche_groesse_beantwortet, faktor_100_vergessen, grundwert_verwechselt | Sachkontext Kredit, erst Differenz |
| zinseszins-01 | zinseszins | I | – | 540,80 € | prozente_addiert, nur_prozentwert, wachstumsfaktor_falsch | zwei Jahre, Faktor 1,04² |
| zinseszins-02 | zinseszins | II | **1** | 926,10 € | prozente_addiert, nur_prozentwert, zu_frueh_gerundet, wachstumsfaktor_falsch | drei Jahre, Faktor 1,05³ |
| zinseszins-03 | zinseszins | II | – | 36,54 € | prozente_addiert, falsche_groesse_beantwortet, wachstumsfaktor_falsch | Zinsen statt Kontostand gefragt |
| zinseszins-04 | zinseszins | III | – | 4 Jahre | prozente_addiert | Laufzeit durch Probieren (Ari-8), Probier-Tabelle im Lösungsweg |
| zinseszins-05 | zinseszins | II | **2** | 384 € | prozente_addiert, grundwert_verwechselt, bedingung_unvollstaendig | +20 %, dann −20 % (Fkt-9) |
| zinseszins-06 | zinseszins | III | – | 5 % | prozente_addiert, falsche_groesse_beantwortet, wachstumsfaktor_falsch | Rückrichtung: 1,1025 als 1,05² erkennen |
| potenzen-01 | potenzen | I | – | 64 | mal_exponent, basis_exponent_vertauscht | natürliche Basis, Hochzahl 3 |
| potenzen-02 | potenzen | I | – | 0,16 | mal_exponent, kommastellen_zu_wenig | Quadrat einer Dezimalzahl |
| potenzen-03 | potenzen | II | – | 6,25 | mal_exponent, quadrat_gliedweise | Quadrat mit zwei Nachkommastellen |
| potenzen-04 | potenzen | II | – | 1,1025 | mal_exponent, quadrat_gliedweise | Wachstumsfaktor zum Quadrat |
| potenzen-05 | potenzen | II | – | 1,157625 | mal_exponent, basis_exponent_vertauscht | dritte Potenz einer Dezimalzahl |
| potenzen-06 | potenzen | II | – | 0,064 m³ | mal_exponent, kommastellen_zu_wenig | Sachkontext Würfelvolumen |

Fehlbild-Abdeckung der neuen Slugs: `zeitfaktor_vergessen` 6 · `prozente_addiert` 6 · `zinszeit_falsch_umgerechnet` 5 ·
`wachstumsfaktor_falsch` 4 · `zu_frueh_gerundet` 4 Aufgaben. Sondierrang nach `docs/sondierrang_vorschlag.md`
(Rang 1 aus dem breitesten Profil, Rang 2 aus dem Profil mit den meisten neuen Fehlbildern), je Knoten verschiedene Profile.

## Test-LSA mit Einstieg Zinsrechnung (läuft erst nach Lenas Freigabe)

**Zwei Voraussetzungen, die heute beide fehlen:**

1. **Freigabe.** Die LSA zieht nur `status = 'ready'` (`lsa_start` → `lsa_select_next_core(…, array['ready'])`). Lena muss
   die 30 Aufgaben freigeben, und für einen tragfähigen Abstieg auch die Vorlauf-Aufgaben zu `term_einsetzen`.
2. **Themen-Einstieg.** `lsa_start` hat keinen Themen-Parameter. Schritt 4 wählt das erste Blatt nach Abdeckung. Lesend
   gemessen liegt heute `fkt_linear_nullstelle` (18) vor `prozent_zins_teilzins` (15) und `prozent_zins_zinseszins` (13).
   Ein Einstieg „Zinsrechnung" lässt sich erst mit W3-6 (Thema → Tiefe → Breite) erzwingen.

**Befehlsfolge, sobald beides steht** (Testschüler aus `tools/seed/zz_schuelerakten_seed.sql`, Kennung `ZZ_S2B`):

```bash
# 0. Ziel-DB prüfen; Testakten anlegen, falls nicht vorhanden
psql "$DATABASE_URL" -tAc "select current_database()" | grep -qx postgres
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f tools/seed/zz_schuelerakten_seed.sql

# 1. Freigabe-Stand prüfen (lesend): 30 ready, Voraussetzungen ready
~/bin/dbread -c "select skill_key, count(*) filter (where status='ready') ready from tasks
  where skill_key like 'prozent_zins_%' or skill_key in ('potenzen','term_einsetzen','prozent_veraenderung') group by 1 order by 1"

# 2. Session starten als Test-Coach (lsa_may_act_for), Einstieg Zinsrechnung über W3-6
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'SQL'
begin;
select set_config('request.jwt.claims', json_build_object('sub', p.id, 'role', 'authenticated')::text, true)
  from profiles p where p.email = 'zz_testcoach@edvance.invalid';
select public.lsa_start(
  (select l.converted_student_id from leads l where l.full_name = 'ZZ_S2B Mia Plan'), 8, 'Mathematik', 'adaptiv');
commit;
SQL

# 3. Je Item: Abgabe mit einem bekannten falschen Wert (z. B. 540 bei zinseszins-01),
#    dann lsa_select_next → erwartet: Abstieg nach prozent_veraenderung (Tiefe 8) bzw. potenzen
#    lsa_submit(<session>, <task>, '{"value":"540"}'::jsonb)

# 4. Auswertung (lesend): Fehlbild erfasst und Abstieg gelaufen
~/bin/dbread -c "select t.skill_key, r.correct, r.fehlbild_slug from lsa_responses r join tasks t on t.id = r.task_id
  where r.session_id = '<session>' order by r.created_at"
~/bin/dbread -c "select skill_key, zustand, offen from lsa_skill_urteil where session_id = '<session>'"

# 5. Aufräumen
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f tools/seed/zz_schuelerakten_teardown.sql
```

Erwartung: `fehlbild_slug = 'prozente_addiert'` für 540 bei zinseszins-01; danach Abstieg in die Voraussetzung mit der
größten Tiefe (`prozent_veraenderung`, 8), dann `prozent_zins_jahreszins` (7).
