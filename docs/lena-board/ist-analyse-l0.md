# L0 — Ist-Analyse Lena-Board

**Stand:** 05.10.2026, Prod über `~/bin/dbread` (read-only, `transaction_read_only = on`), Repo `dev` 93fb3d6.
Letzte eingespielte Migration in Prod: `20261004095314` = letzte Datei im Repo (Prod und Repo gleich).
Abfragen: Board-Logik nach Entscheidung 13 als CTE nachgebaut (nur lesend).

## 1. Bestand und Ausschlüsse

| Ausschlussgrund (Entscheidung 13) | Aufgaben |
|---|---|
| im Board | **859** |
| vera8 | 299 (286 draft, 13 ready) |
| ohne_fertigkeit | 24 (13 beanstandet, 11 draft; alle „Potenzen · …“ ohne skill_thema-Zeile bzw. ohne skill_key) |
| gate | 1 (status review, „Sachkontext · Dezimal · Äpfel“, `cluster_id` leer) |
| inaktiv, typ, ohne_loesung, bild_fehlt | 0 |

Statusverteilung gesamt: draft 1156 (870 eigene + 286 VERA8), ready 13 (alle VERA8), beanstandet 13, review 1.
Im Board stehen **nur draft-Aufgaben** (859): NUMERIC 704, MULTI_PART 99, MC 36, TERM 20.

Regelart im Board: NUMERIC 705 mit `acceptance.canonical` („flach mit Regel“), MULTI_PART 99 mit
Teil-acceptance, MC 30 mit und 6 ohne acceptance, TERM 20 ohne acceptance.

### Board je Stufe und Thema (alle draft)

| Stufe | Thema | Aufgaben |
|---|---|---|
| 7/8 | Rationale Zahlen (`rationale_zahlen`) | 23 |
| 7/8 | Proportionale und antiproportionale Zuordnungen (`zuordnungen`) | 17 |
| 7/8 | Prozent- und Zinsrechnung (`zinsrechnung`) | 63 |
| 7/8 | Terme und Gleichungen (`terme_gleichungen`) | 66 |
| 7/8 | Winkelsätze, Dreiecke und Konstruktionen (`winkel_dreiecke`) | 24 |
| 7/8 | Lineare Funktionen (`lineare_funktionen`) | 30 |
| 7/8 | Terme mit mehreren Variablen und binomische Formeln (`terme_binomische_formeln`) | 24 |
| 7/8 | Zufall und Wahrscheinlichkeit (`zufallsexperimente`) | 24 |
| 7/8 | Flächen von Dreiecken und Vierecken (`flaechen_vielecke`) | 39 |
| 7/8 | Lineare Gleichungssysteme (`lineare_gleichungen_lgs`) | 30 |
| 7/8 | Kreise und Dreiecke: Thales und besondere Linien (`thales_konstruktionen`) | 6 |
| 9/10 | Reelle Zahlen und Wurzeln (`reelle_zahlen`) | 30 |
| 9/10 | Potenzen (`potenzen`) | 24 |
| 9/10 | Quadratische Funktionen (`quadratische_funktionen`) | 30 |
| 9/10 | Quadratische Gleichungen (`quadratische_gleichungen`) | 24 |
| 9/10 | Satz des Pythagoras (`pythagoras`) | 30 |
| 9/10 | Ähnlichkeit und zentrische Streckung (`aehnlichkeit`) | 24 |
| 9/10 | Kreis: Umfang und Fläche (`kreis`) | 24 |
| 9/10 | Prismen und Zylinder (`prismen_zylinder`) | 12 |
| 9/10 | Pyramide, Kegel und Kugel (`koerper_pyramide_kegel_kugel`) | 18 |
| 9/10 | Trigonometrie (`trigonometrie`) | 30 |
| 9/10 | Exponentielles Wachstum (`exponentialfunktionen`) | 30 |
| 9/10 | Sinusfunktion und periodische Vorgänge (`sinusfunktion`) | 30 |
| 9/10 | Bedingte Wahrscheinlichkeit (`bedingte_wahrscheinlichkeit`) | 24 |
| 9/10 | Statistische Erhebungen beurteilen (`statistik_beurteilen`) | 6 |
| 5/6 | Natürliche Zahlen und Größen (`natuerliche_zahlen`) | 50 |
| 5/6 | Daten, Diagramme und Kenngrößen (`daten_streumasse`) | 6 |
| 5/6 | Geometrische Grundbegriffe und Figuren (`geometrische_grundbegriffe`) | 6 |
| 5/6 | Flächen und Umfang (`flaeche_umfang`) | 23 |
| 5/6 | Körper, Netze und Quadervolumen (`koerper_quader`) | 19 |
| 5/6 | Brüche und Anteile (`brueche`) | 7 |
| 5/6 | Rechnen mit Brüchen und Dezimalzahlen (`rechnen_brueche_dezimalzahlen`) | 55 |
| 5/6 | Negative Zahlen, Zuordnungen und Dreisatz (`ganze_zahlen_groessen`) | 11 |

Summe 7/8: 346 · 9/10: 336 · 5/6: 177.

## 2. Lenas Profil

`select id, role, darf_pruefen from profiles where darf_pruefen or role in ('admin','coach')`:

| id | role | darf_pruefen | Name |
|---|---|---|---|
| 35e4f9ac-… | admin | false | Rasit Güven |
| 225c82d6-… | admin | false | Tolunay |
| f130a783-… | coach | false | Rasit |
| eb08e750-… | coach | false | Can |
| d66474b5-… | coach | false | ZZ Test Coach |

**Es gibt in Prod kein Konto für Lena und keinen Coach mit `darf_pruefen = true`.** → offene-punkte.md (OP-1).

## 3. werte_widersprechen

Für alle flachen Aufgaben mit Regel (nicht MC/TERM/MULTI_PART): jeder Eintrag aus `correct_answers` durch
`lsa_grade(input_type, acceptance, correct_answers, {"text": wert})` → **0 Treffer**. Kein Wert würde heute
abweichend gewertet.

## 4. Fehlbild-Slugs im Board ohne freigegebene Familie (nur Liste für das PR)

`fehlbild_familien`: 10 Familien, davon 5 freigegeben. `fehlbild_labels`: 153 Slugs, 101 mit Familie.
85 Slugs, die in `known_errors` von Board-Aufgaben stehen, haben keine freigegebene Familie
(Slug — Anzahl Aufgaben):

halbieren_vergessen (59, ohne Familie), mal_exponent (48, Familie potenzen_wurzeln nicht freigegeben), pi_vergessen (41, ohne Familie), radius_durchmesser_verwechselt (34, ohne Familie), multipliziert_statt_dividiert (25, Familie rechenart_formel nicht freigegeben), bogenmass_modus (25, ohne Familie), hypotenuse_verwechselt (24, ohne Familie), wurzel_halbiert (24, Familie potenzen_wurzeln nicht freigegeben), teilgekuerzt (23, ohne Familie), plus_statt_mal (23, Familie rechenart_formel nicht freigegeben), tangens_verwechselt (21, ohne Familie), umfang_statt_flaeche (21, Familie rechenart_formel nicht freigegeben), koordinaten_vertauscht (20, ohne Familie), grundwert_verwechselt (18, ohne Familie), bezug_vertauscht (17, Familie brueche_anteile nicht freigegeben), sin_cos_vertauscht (17, ohne Familie), abgeschnitten (16, Familie runden nicht freigegeben), nur_prozentwert (15, ohne Familie), falsche_hoehe (14, ohne Familie), vorzeichen_potenz (14, Familie potenzen_wurzeln nicht freigegeben), faktor_100_vergessen (14, ohne Familie), falsche_operation (13, Familie rechenart_formel nicht freigegeben), potenzgesetz_verwechselt (13, Familie potenzen_wurzeln nicht freigegeben), falsche_stelle (13, Familie runden nicht freigegeben), summe_360_statt_180 (13, ohne Familie), kommastellen_zu_wenig (12, Familie kommazahlen nicht freigegeben), umgekehrt_geteilt (12, Familie brueche_anteile nicht freigegeben), basis_exponent_vertauscht (12, Familie potenzen_wurzeln nicht freigegeben), dezimal_statt_sexagesimal (12, ohne Familie), strahlensatz_falsch_zugeordnet (12, ohne Familie), falscher_bezug (12, ohne Familie), kommastellen_zu_viel (12, Familie kommazahlen nicht freigegeben), winkelbeziehung_verwechselt (11, ohne Familie), differenz_vergessen (10, ohne Familie), umkehrfunktion_vergessen (10, ohne Familie), flaeche_statt_umfang (9, Familie rechenart_formel nicht freigegeben), oberflaeche_statt_volumen (9, Familie rechenart_formel nicht freigegeben), volumen_statt_oberflaeche (9, Familie rechenart_formel nicht freigegeben), mal_zwei_vergessen (9, ohne Familie), einheit_ignoriert (9, ohne Familie), faktor_hundert_statt_sechzig (9, ohne Familie), komma_nicht_verschoben (9, Familie kommazahlen nicht freigegeben), komma_ignoriert (9, Familie kommazahlen nicht freigegeben), nur_eine_grundseite (9, ohne Familie), pfadregel_addiert (9, ohne Familie), liter_kubik_falsch (9, ohne Familie), periode_falsch (8, ohne Familie), faktor_hundert_statt_tausend (8, ohne Familie), gegenereignis_nicht_abgezogen (8, ohne Familie), nenner_addiert (8, Familie brueche_anteile nicht freigegeben), verhaeltnis_statt_anteil (8, ohne Familie), stellenwert_ignoriert (8, Familie kommazahlen nicht freigegeben), kreisanteil_falsch (8, ohne Familie), nenner_addiert_zaehler_ok (7, Familie brueche_anteile nicht freigegeben), komma_als_trenner (7, ohne Familie), hauptnenner_bei_mult (7, Familie brueche_anteile nicht freigegeben), nicht_gestuerzt (7, Familie brueche_anteile nicht freigegeben), falschen_gestuerzt (7, Familie brueche_anteile nicht freigegeben), teilflaeche_vergessen (7, ohne Familie), amplitude_verwechselt (7, ohne Familie), additiv_gekuerzt (7, Familie brueche_anteile nicht freigegeben), zaehler_nicht_erweitert (7, Familie brueche_anteile nicht freigegeben), zwei_kanten (6, ohne Familie), drittel_vergessen (6, ohne Familie), faktor_ohne_wurzel (6, Familie potenzen_wurzeln nicht freigegeben), ziffern_gelesen (6, Familie brueche_anteile nicht freigegeben), zuruecklegen_ignoriert (6, ohne Familie), basiswinkel_falsch_zugeordnet (5, ohne Familie), nur_ein_pfad (5, ohne Familie), median_ohne_sortieren (5, ohne Familie), immer_aufgerundet (5, Familie runden nicht freigegeben), log_falsch_geteilt (5, ohne Familie), anfangswert_faktor_vertauscht (5, ohne Familie), halbieren_faelschlich (5, ohne Familie), fuehrende_null_ignoriert (5, ohne Familie), pythagoras_ohne_rechten_winkel (4, ohne Familie), irrational_verwechselt (4, Familie potenzen_wurzeln nicht freigegeben), nur_einmal_addiert (4, ohne Familie), mittelwert_statt_median (3, ohne Familie), uebertrag_vergessen (3, Familie kommazahlen nicht freigegeben), rechter_winkel_falsche_ecke (3, ohne Familie), summe_180_statt_360 (3, ohne Familie), aussenwinkel_verwechselt (3, ohne Familie), seite_vergessen (3, ohne Familie), nur_eine_seite (3, ohne Familie)

Diese Befunde fallen im Report heute still aus (Feldkatalog 3). Nicht Teil dieses Auftrags.

## 5. Aufrufer

### pg_proc-Scan (Prod)

`prosrc ~ 'beanstandet' | '''review''' | 'darf_pruefen\(' | task_status_set | task_solution_upsert | lena_beanstande`:

| Funktion | beanstandet | 'review' | darf_pruefen() |
|---|---|---|---|
| task_status_set(uuid,text) | – | ja | ja |
| task_solution_upsert(uuid,jsonb,text,jsonb,jsonb,jsonb,jsonb,jsonb,jsonb) | – | – | ja |
| lena_beanstande(uuid,text,text) | ja | – | ja |
| lena_beanstande_muster(text,text,text,text) | ja | – | – (nur admin) |
| freigabe_muster(text,uuid[]) | – | – | – (draft → ready) |
| freigabe_cluster(uuid) | – | ja | – |
| freigabe_thema(text,integer) | – | ja | – |
| tasks_pruefer_guard() | – | – | – |

Weitere Sammelwege: `freigabe_zuruecknehmen(text)` (ready → draft je Skill, nur admin).
Policies mit `darf_pruefen`: nur `tasks.pruefer_update_tasks`. CHECK mit Status: `tasks_status_check`.
Views mit Aufgabenstatus: keine (`vertraege_aktuell` meint Verträge).

### Repo: task_status_set

- `src/lib/supabase/taskAuthoring.ts:302` (`setTaskStatus`) ← `src/pages/admin/AuthoringEditorPage.tsx:198`,
  `src/components/edvance/authoring/wizard/useReleaseActions.ts:68` (PflegeWizard; Prüfer setzt dort review).
- `src/lib/supabase/taskAuthoring.ts:81` (Schema-Probe mit NIL_UUID).
- SQL: `freigabe_muster`, `freigabe_thema`, `freigabe_cluster` (als admin).
- Prüfskripte: `supabase/checks/20260922100000_item_freigabe_pruefrecht.PRUEFUNG.sql:64-149` (verlangt den
  Prüfer-Weg), `20260723160000_a21_freigabe_muster.PRUEFUNG.sql`.

### Repo: task_solution_upsert

- `src/lib/supabase/taskAuthoring.ts:272` (`upsertTaskSolution`) ← `AuthoringEditorPage.tsx:181`.
- `src/lib/supabase/tasks.ts:300` (Import-Pfad).
- Skripte (Systemaufruf/service_role): `scripts/import-lsa-items.ts:279`, `scripts/import-vera8-draft.ts:126`,
  `scripts/import/lambacher.ts:197`, `tools/vorlauf-build.mjs:182`.
- Datenmigrationen (Systemaufruf): 27 Dateien `aufgaben_k*`, `p5_*`, `t1_altbestand_backfill` u. a.
- Prüfskript `20260922100000_item_freigabe_pruefrecht.PRUEFUNG.sql:68-148`.

### Repo: lena_beanstande

- `src/lib/supabase/freigabe.ts:108` (`beanstandeAufgabe`) ← `wizard/useReleaseActions.ts:79` (PflegeWizard).
- Prüfskript `20260922100000_item_freigabe_pruefrecht.PRUEFUNG.sql:66,100,104`.

### pruefer_update_tasks (direktes UPDATE)

Policy `tasks.pruefer_update_tasks` (UPDATE, authenticated, `darf_pruefen()`). Frontend-Schreiber auf `tasks`:
`src/lib/supabase/taskAuthoring.ts` (`updateTaskFields` u. a.) ← `AuthoringEditorPage`, `PflegeWizardPage`
(`canWrite = darfPruefen && …`, `AuthoringEditorPage.tsx:76`, `PflegeWizardPage.tsx:178`).

**Folge:** Ein Prüfer braucht diese Wege nur in Editor und Pflege-Strecke. Beide werden mit Entscheidung 3 admin-only.
Kein anderer Prüfer-Weg hängt daran → Migration 3 bricht nichts außer dem überholten Prüfskript (wird angepasst).

### Status-Aufzählungen

- SQL: `tasks_status_check`; `task_status_set` (draft/review/ready); `freigabe_*` (review/draft).
- TS: `src/types/authoring.ts:15` (`TaskStatus`), `src/lib/authoring/board.ts:31` (`STATUS_JE_FILTER`),
  `src/components/edvance/authoring/ui.tsx:189` (`STATUS_VARIANT`), `AuthoringItemsPage.tsx:79`
  (`STATUS_ORDER`), `ContentHealthPage.tsx:40`, `HealthOverview.tsx:16`, `AuthoringFilters.tsx:107`.
- i18n: `authoring.json` `status.*` (Z. 69) und Board-Reiter (Z. 548).

## 6. Rechte heute (Prod)

- `tasks`: Policies `admin_write_tasks` (ALL, admin), `pruefer_update_tasks` (UPDATE, darf_pruefen),
  `read_tasks_by_role` (coach/admin alles, sonst nur ready). Grants: authenticated S/I/U/D, anon SELECT.
- `task_solutions`: RLS ohne Policy → nur über Definer-Funktionen.
- `task_reviews`: nur SELECT-Policy für admin/coach.
- Trigger `tasks`: `tasks_pruefer_guard`, `tasks_zahlen_guard` (question), `tasks_term_acceptance`.
  Trigger `task_solutions`: `task_solutions_zahlen_guard`, `task_solutions_term_acceptance`.
