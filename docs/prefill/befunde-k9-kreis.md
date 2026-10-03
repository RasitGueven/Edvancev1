# Befunde K9 Kreis

Stand 03.10.2026. Auftrag `W1-3-kreis-k9.md`, Phase-0-Bericht und Entscheidungen in `docs/k9/kreis-phase0.md`.
Die Live-DB wurde nur lesend und ausschließlich über `~/bin/dbread` gelesen.

## Einspiel-Reihenfolge

| Nr. | Datei | Inhalt | Stand |
|---|---|---|---|
| – | Vorlauf `20261001115718` / `115812` / `120554` | Tiefe 1..12, `term_einsetzen` (Tiefe 5) | eingespielt, per SELECT geprüft |
| 1 | `20261003091339_substrat_k9_kreis.sql` | 5 Knoten, 16 Kanten, 3 neue Fehlbilder (+ `zu_frueh_gerundet` idempotent) | **nicht eingespielt** (siehe unten) |
| 2 | `20261003092051_aufgaben_k9_kreis.sql` | 24 Aufgaben (je 6 zu umfang, flaeche, rueck, sektor) | **nicht eingespielt**, Blind-Prüfung bestanden |

**Warum nicht eingespielt:** Das Einspielen von Migration 1 über `scripts/db-migrate.sh` hat die Rechteprüfung der
Session als „Production Deploy" abgelehnt. Die Freigabe im Chat reicht der Prüfung nicht. Beide Dateien sind fertig
geprüft (lokal, CI, Blind-Löser), müssen aber von Hand eingespielt werden:

```bash
cd ~/wt/k9-kreis
~/bin/dbread -tAc "select current_database()" | grep -qx postgres && \
  bash scripts/db-migrate.sh supabase/migrations/20261003091339_substrat_k9_kreis.sql
~/bin/dbread -f supabase/checks/k9_kreis_substrat.PRUEFUNG.sql            # 7 von 7 t erwartet
~/bin/dbread -tAc "select current_database()" | grep -qx postgres && \
  bash scripts/db-migrate.sh supabase/migrations/20261003092051_aufgaben_k9_kreis.sql
~/bin/dbread -f supabase/checks/k9_kreis_aufgaben.PRUEFUNG.sql            # 17 von 17 t erwartet
```

**Versionen:** Vor dem Einspielen `max(version)` prüfen. Kommt in Prod etwas Neueres dazu, beide Dateien neu
versionieren (`date -u +%Y%m%d%H%M%S`) und Migration 2 mit
`node tools/vorlauf-build.mjs docs/prefill/k9-kreis.json <neue Version> aufgaben_k9_kreis` neu erzeugen. Die Version
musste in diesem Lauf schon zweimal wandern, weil Zins, Schulpläne und Lineare Funktionen dazwischen eingespielt wurden.

## Prüfprotokoll (Phase C)

| Stufe | Werkzeug | Ergebnis |
|---|---|---|
| Rechnung beim Erzeugen | `tools/k9-kreis-charge.mjs` (exakt, Brüche, π auf 35 Stellen und 3,14) | jede Antwort und jeder falsche Wert für **beide** π-Wege nachgerechnet, keiner an einer Rundungsgrenze |
| Alle Lena-Felder | `verify-tasks --prefill` (verify-prefill) | **0 Charge-Fehler**, 0 Bestands-Befunde → `k9-kreis-verifikation.md` |
| Struktur | `verify-tasks --from-file` Stufe 1 | 24 ok, 0 beanstandet |
| Blind-Löser, Lauf 1 | frischer Subagent, nur `aufgaben.json` | 24 Antworten, 0 unsicher → `k9-kreis-blind-lauf1.json`, Abgleich **24/24** |
| Textkorrektur 1 | `kreis-umfang-06` nannte die Rundung nicht (eigene Prüfabfrage rot) | Satz „Runde auf ganze Umdrehungen." ergänzt |
| Blind-Löser, Lauf 2 | frischer Subagent auf den korrigierten Export | Abgleich 24/24, aber **`umfang-06` unsicher**: „Runde auf ganze Umdrehungen" widerspricht „mindestens" (kaufmännisch 53, verlangt 54). Berechtigt, die Korrektur selbst war mehrdeutig → `k9-kreis-blind-lauf2.json` |
| Textkorrektur 2 | `umfang-06` wie `rueck-06` formuliert | „Gib eine ganze Zahl an und runde dafür auf." |
| Blind-Löser, Lauf 3 (Endstand) | frischer Subagent auf den Endstand | Abgleich **24/24, 100 %** → `k9-kreis-blind.json`. `umfang-06` jetzt eindeutig. 15 Aufgaben „unsicher" nur, weil π-Taste und 3,14 verschieden runden. Alle 15 vom Löser genannten 3,14-Werte stehen in `correct_answers` (geprüft). Kein zweiter Löser je Aufgabe nötig, keine Abweichung |
| Wegwerf-DB | Grundlage + alle Migrationen, zweiter Lauf beider Kreis-Dateien | grün, idempotent |
| Prüfabfrage M2 lokal | `k9_kreis_aufgaben.PRUEFUNG.sql` (nach dem Merge von dev, 95 Migrationen) | 16 von 17 t. Rot nur „alle Slugs existieren": Die Alt-Slugs fehlen lokal (Datenimport), in Prod sind alle 9 vorhanden (geprüft) |
| Gegenprobe Bewertung | Prüfabfrage: `lsa_is_correct` und `lsa_grade` auf jede Variante, `lsa_fehlbild_match` auf jeden falschen Wert | alle Varianten richtig und „voll", jeder falsche Wert „nicht richtig" und trifft seinen Slug |

Der **Trockenlauf gegen Prod** (begin → apply → assert → rollback) fehlt. Er schreibt in Prod, auch wenn er
zurückrollt, und fällt damit unter dieselbe Sperre wie das Einspielen. Ersatz ist die Wegwerf-DB aus allen
Migrationen (identisches Schema laut CI `neuaufbau`).

## Befunde

| Nr. | Befund | Umgang |
|---|---|---|
| K1 | `afb` ist `I/II/III`, nicht 1–3. | Römisch vergeben, Begründung je Aufgabe unten und in der CSV. |
| K2 | `known_errors` liegt in `task_solutions.acceptance.known_errors`. | Objektform `{falscher_wert: slug}`. |
| K3 | **`lsa_is_correct` (Flag `correct`, Fehlbild-Erfassung) vergleicht Text exakt, `lsa_grade` (Skill-Urteil) nur `canonical` + `equivalents`.** `vorlauf-build.mjs` schrieb bisher nur `canonical`. Der 3,14-Weg wäre im Urteil „nicht" gewesen. | Neues Charge-Feld `acceptance_equivalents` in `vorlauf-build.mjs` (opt-in, andere Chargen unverändert). Beide π-Ergebnisse stehen in `correct_answers` **und** in `equivalents`, je mit Komma, Punkt, Endnull und Einheit. Keine Toleranz. |
| K4 | **`mal_exponent` (r² als 2r) und `umfang_statt_flaeche` sind am Kreis nicht zu trennen:** π · r · 2 = 2 · π · r, für jeden Radius. | Ein Wert kann nur einen Slug tragen. Die Kreisflächen-Aufgaben führen ihn als `umfang_statt_flaeche`, `mal_exponent` wird in dieser Charge nicht vergeben. Wenn Lena den Denkfehler „Quadrat als Verdopplung" höher gewichtet, lässt sich der Slug in den sieben betroffenen Aufgaben tauschen. Die Kante `flaeche → potenzen` bleibt fachlich richtig. |
| K5 | `flaecheneinheit_nicht_quadriert`: Mit festem `tasks.unit` ist der Fehler nicht sichtbar. | **Nicht angelegt** (Entscheidung Rasit). Flächeneinheiten prüft das Fundament (`groessen_flaechen`). |
| K6 | `halbieren_vergessen` und `seite_vergessen` sind bestätigt, kommen aber erst mit `geo_kreis_zusammen` (Halbkreis) zum Einsatz. | In dieser Charge nicht verwendet. Aufgaben zu `zusammen` folgen nach dem Generator (`specs/active/figur-kreis.md`). |
| K7 | Alt-Slugs **ohne Klartext**, die diese Charge benutzt: `flaeche_statt_umfang`, `umfang_statt_flaeche`, `multipliziert_statt_dividiert`, `abgeschnitten`. Bestätigt, aber noch nicht benutzt: `mal_exponent`, `halbieren_vergessen`, `seite_vergessen`. | Wiederverwendet wie entschieden, bestehende Zeilen nicht geändert. Für den Elternreport brauchen sie Klartext und Familie (Fundament, Spec `fehlbild-labels-eltern.md`). |
| K8 | Die drei neuen Slugs haben die Familie NULL. Keine der fünf Familien beschreibt eine falsch eingesetzte Größe in einer Formel. | Entscheidung Lena. |
| K9 | Rückrichtung nur aus dem Umfang. r aus A bräuchte die Quadratwurzel (KLP Ari-6/7), dafür gibt es keinen Knoten. | Bewusste Lücke, `geo_kreis_rueck` = r/d aus U. |
| K10 | Zwei Aufgaben (`umfang-06`, `rueck-06`) verlangen sinnvolles **Aufrunden**. Der Parser von `verify-prefill` kennt kein ceil. | Der Prüfeintrag belegt den Wert vor dem Runden (4 Stellen), das Aufrunden prüft `k9-kreis-charge.mjs`. Abrunden ist als Fehlbild `abgeschnitten` hinterlegt. |
| K11 | `class_level` setzt `vorlauf-build.mjs` auf `null` (wie Fundament). Das Board zählt `null` als „Klasse 8". Der Stoffanker steht korrekt auf 9. | Übernommen. Folge für Lena: Die Kreis-Aufgaben erscheinen im Board unter „Klasse 8". |
| K12 | `thema_einstieg` liest keine DB-Funktion, `lsa_start` hat keinen Themen-Parameter. | Kein Eintrag für `kreis`. Ein Einstieg „Kreis" erst mit W3-6. |

## Die Aufgaben

Alle `NUMERIC`, `status = 'draft'`, `curriculum_grade = 9`, Themengebiet „Geometrie & Messen", `competency_content =
geometrie`, `needs_image = false`, keine Hinweise, `source = edvance_k9_kreis`. Zeitregel wie Zins: AFB I 45 s, II 60 s,
III 90 s, +30 s bei Sachkontext. Jede Aufgabe nennt „π-Taste oder π ≈ 3,14" und die Rundung.

| source_ref | AFB | Begründung | Antwort (π / 3,14) | Fehlbilder | Rang |
|---|---|---|---|---|---|
| `kreis-umfang-01` | I | Reproduzieren: Umfangsformel mit gegebenem Radius, ein Schritt. | 25,13 / 25,12 cm | `pi_vergessen`, `radius_durchmesser_verwechselt`, `flaeche_statt_umfang` | – |
| `kreis-umfang-02` | I | Reproduzieren: Umfang aus dem Durchmesser, ein Schritt. | 31,42 / 31,40 cm | `pi_vergessen`, `radius_durchmesser_verwechselt`, `flaeche_statt_umfang` | – |
| `kreis-umfang-03` | II | Anwenden: Dezimalradius, Ergebnis nicht im Kopf überschlagbar. | 22,62 / 22,61 m | `radius_durchmesser_verwechselt`, `pi_vergessen`, `flaeche_statt_umfang` | 1 |
| `kreis-umfang-04` | II | Anwenden: Umfang plus Umrechnung von Zentimetern in Meter. | 2,83 m | `einheit_uebersprungen`, `radius_durchmesser_verwechselt`, `pi_vergessen` | 2 |
| `kreis-umfang-05` | II | Anwenden im Sachkontext: Eine Radumdrehung muss als Umfang erkannt werden. | 219,91 / 219,80 cm | `pi_vergessen`, `radius_durchmesser_verwechselt`, `flaeche_statt_umfang` | – |
| `kreis-umfang-06` | III | Problemlösen: Strecke durch Umfang teilen, Einheiten angleichen und sinnvoll aufrunden. | 54 Umdrehungen | `radius_durchmesser_verwechselt`, `abgeschnitten`, `pi_vergessen` | – |
| `kreis-flaeche-01` | I | Reproduzieren: Flächenformel mit gegebenem Radius. | 113,10 / 113,04 cm² | `pi_vergessen`, `umfang_statt_flaeche`, `radius_durchmesser_verwechselt` | – |
| `kreis-flaeche-02` | I | Reproduzieren: Radius aus dem Durchmesser, dann Flächenformel. | 78,54 / 78,50 cm² | `pi_vergessen`, `radius_durchmesser_verwechselt`, `umfang_statt_flaeche` | – |
| `kreis-flaeche-03` | II | Anwenden: Quadrat einer Dezimalzahl in der Flächenformel. | 18,10 / 18,09 m² | `umfang_statt_flaeche`, `pi_vergessen`, `radius_durchmesser_verwechselt` | – |
| `kreis-flaeche-04` | II | Anwenden: Flächenformel plus Umrechnung in eine Flächeneinheit. | 2,01 m² | `einheit_uebersprungen`, `linearer_faktor`, `pi_vergessen`, `umfang_statt_flaeche` | 1 |
| `kreis-flaeche-05` | II | Anwenden im Sachkontext: Der Durchmesser muss als solcher erkannt und halbiert werden. | 706,86 / 706,50 cm² | `pi_vergessen`, `radius_durchmesser_verwechselt`, `umfang_statt_flaeche` | – |
| `kreis-flaeche-06` | III | Problemlösen: zwei Flächen modellieren, verdoppeln und vergleichen – Rechenweg selbst wählen. | 78,54 / 78,50 cm² | `pi_vergessen`, `radius_durchmesser_verwechselt`, `falsche_groesse_beantwortet` | 2 |
| `kreis-rueck-01` | I | Reproduzieren: Umfangsformel nach d umstellen, eine Division. | 15,92 cm | `pi_vergessen`, `multipliziert_statt_dividiert`, `radius_durchmesser_verwechselt` | – |
| `kreis-rueck-02` | I | Reproduzieren: Umfangsformel nach r umstellen. | 6,37 cm | `pi_vergessen`, `radius_durchmesser_verwechselt`, `multipliziert_statt_dividiert` | – |
| `kreis-rueck-03` | II | Anwenden: Umstellen und dabei von Metern in Zentimeter umrechnen. | 63,66 / 63,69 cm | `pi_vergessen`, `einheit_uebersprungen`, `radius_durchmesser_verwechselt` | 2 |
| `kreis-rueck-04` | II | Anwenden: Dezimalumfang, Division durch 2π, Rundung erst am Ende. | 1,99 m | `radius_durchmesser_verwechselt`, `zu_frueh_gerundet`, `pi_vergessen` | – |
| `kreis-rueck-05` | II | Anwenden im Sachkontext: gemessener Umfang, Durchmesser in anderer Einheit gesucht. | 70,03 / 70,06 cm | `pi_vergessen`, `radius_durchmesser_verwechselt`, `einheit_uebersprungen` | – |
| `kreis-rueck-06` | III | Problemlösen: den nötigen Umfang erst aus der Situation bilden, dann umstellen und sinnvoll aufrunden. | 153 cm | `bedingung_unvollstaendig`, `radius_durchmesser_verwechselt`, `abgeschnitten`, `pi_vergessen` | 1 |
| `kreis-sektor-01` | I | Reproduzieren: Viertel des Umfangs, Anteil direkt erkennbar. | 9,42 cm | `pi_vergessen`, `kreisanteil_falsch`, `flaeche_statt_umfang` | – |
| `kreis-sektor-02` | I | Reproduzieren: Viertel der Kreisfläche, Anteil direkt erkennbar. | 12,57 / 12,56 cm² | `pi_vergessen`, `kreisanteil_falsch`, `umfang_statt_flaeche` | – |
| `kreis-sektor-03` | II | Anwenden: Anteil 120°/360° = 1/3, als Dezimalzahl nicht abbrechend. | 18,85 / 18,84 cm | `pi_vergessen`, `zu_frueh_gerundet`, `kreisanteil_falsch`, `flaeche_statt_umfang` | 2 |
| `kreis-sektor-04` | II | Anwenden: Anteil 72°/360° muss erst gekürzt werden (1/5). | 15,71 / 15,70 m² | `pi_vergessen`, `kreisanteil_falsch`, `umfang_statt_flaeche` | – |
| `kreis-sektor-05` | II | Anwenden im Sachkontext: Anteil aus der Stückzahl, Radius aus dem Durchmesser. | 44,24 / 44,22 cm² | `radius_durchmesser_verwechselt`, `kreisanteil_falsch`, `zu_frueh_gerundet`, `pi_vergessen` | 1 |
| `kreis-sektor-06` | III | Problemlösen: Rückrichtung im Sektor – Anteil aus Bogen und Umfang bilden, dann in Grad umrechnen. | 72 ° | `radius_durchmesser_verwechselt`, `pi_vergessen`, `falsche_groesse_beantwortet` | – |

## Test-LSA mit Einstieg Kreis (läuft erst nach Lenas Freigabe)

Es gelten dieselben zwei Voraussetzungen wie bei Zins:

1. **Freigabe:** `lsa_start` zieht nur `status = 'ready'`. Lena muss die 24 Aufgaben freigeben, für einen tragfähigen
   Abstieg auch die Vorlauf-Aufgaben zu `term_einsetzen`.
2. **Themen-Einstieg:** `lsa_start(p_student_id, p_grade, p_subject, p_modus)` hat keinen Themen-Parameter. Einen
   Einstieg „Kreis" erzwingt erst W3-6.

Testschüler aus `tools/seed/zz_schuelerakten_seed.sql`, Klasse 9: `ZZ_S2B Efe Leicht`.

```bash
# 0. Ziel-DB prüfen; Testakten anlegen, falls nicht vorhanden
~/bin/dbread -tAc "select current_database()" | grep -qx postgres
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f tools/seed/zz_schuelerakten_seed.sql

# 1. Freigabe-Stand (lesend): 24 ready, Voraussetzungen ready
~/bin/dbread -c "select skill_key, count(*) filter (where status='ready') ready from tasks
  where skill_key like 'geo_kreis_%' or skill_key in ('term_einsetzen','geo_umfang','potenzen','groessen_flaechen',
  'dezimal_div','proportionalitaet','runden_ueberschlag') group by 1 order by 1"

# 2. Session als Test-Coach starten, Klasse 9, Einstieg Kreis über W3-6
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'SQL'
begin;
select set_config('request.jwt.claims', json_build_object('sub', p.id, 'role', 'authenticated')::text, true)
  from profiles p where p.email = 'zz_testcoach@edvance.invalid';
select public.lsa_start(
  (select l.converted_student_id from leads l where l.full_name = 'ZZ_S2B Efe Leicht'), 9, 'Mathematik', 'adaptiv');
commit;
SQL

# 3. Je Item eine Abgabe mit einem bekannten falschen Wert, dann lsa_select_next. Erwartet:
#    kreis-flaeche-02 mit "314"   -> radius_durchmesser_verwechselt, Abstieg nach term_einsetzen / groessen_flaechen
#    kreis-umfang-01 mit "8"      -> pi_vergessen, Abstieg nach geo_umfang / term_einsetzen
#    kreis-sektor-01 mit "37,70"  -> kreisanteil_falsch, Abstieg nach proportionalitaet
#    lsa_submit(<session>, <task>, '{"value":"314"}'::jsonb)
#    Gegenprobe beider π-Wege: kreis-umfang-01 mit "25,12" muss correct = true und Urteil "traegt" liefern.

# 4. Auswertung (lesend)
~/bin/dbread -c "select t.source_ref, r.correct, r.fehlbild_slug from lsa_responses r join tasks t on t.id = r.task_id
  where r.session_id = '<session>' order by r.created_at"
~/bin/dbread -c "select skill_key, zustand, offen from lsa_skill_urteil where session_id = '<session>'"

# 5. Aufräumen: Testsession über den Seed-Abbau (Kennung ZZ_S2B) entfernen
```

## Offen

1. **Einspielen** beider Migrationen (Befehle oben). Gesperrt durch die Rechteprüfung, nicht durch einen Befund.
2. `geo_kreis_zusammen`: Generator nach `specs/active/figur-kreis.md` bauen, dann 6 Aufgaben (Halbkreis, Viertelkreis,
   Kreisring, Rechteck mit Halbkreis) mit `halbieren_vergessen` und `seite_vergessen`.
3. Klartext und Familie für die Alt-Slugs aus K7 und die drei neuen Slugs (K8).
4. K4: `mal_exponent` oder `umfang_statt_flaeche` für π · 2r. Lena entscheidet.
