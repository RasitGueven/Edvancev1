# A0 · Ist-Analyse (Bauauftrag A)

Stand 27.10.2026. Grundlage: `origin/dev` 74b5b4b8 (Edvancev1), e4cf268 (edvance-app). Belege: `Datei:Zeile`
auf diesem Stand oder Abfrage per `~/bin/dbread` (lesend) gegen Prod samt Ausgabe. Migrationspfade kurz
`mig/<datei>` = `supabase/migrations/<datei>`.

## 1 · Markierung LSA / Session

- Spalte `tasks.einsatz text[] not null default '{lsa,session}'`, angelegt in
  `mig/20261007100300_x0_einsatz_pool.sql:15`. Erlaubte Werte `lsa, session, check, quest`
  (`tasks_einsatz_check`), `quest` nie zusammen mit lsa/session (`tasks_einsatz_quest_allein`).
  Kommentar dort: „Bestand: {lsa,session}". Es gibt keine andere Pool-Markierung (`is_diagnostic` steuert
  nur die Diagnose-Herkunft, nicht den Pool).
- Zählung (dbread):

```sql
select einsatz, status, count(*) from tasks group by 1,2 order by 1,2;
```
```
 {check}       | draft  |     1
 {lsa}         | draft  |     1
 {lsa}         | ready  |     1
 {lsa,session} | draft  |  1038
 {lsa,session} | ready  |   146
```

- Beide Markierungen: **1184** (146 ready), tatsächlich in beiden Pools 144, in beiden gezogen 12. Nach
  Skill und Status: `doppel-aufgaben.md`, Liste `doppel-aufgaben-im-pool.csv`. Haltepunkt ausgelöst,
  Entscheidung Rasit in `entscheidung-rasit-a0.md`: alle 1184 werden lsa, Default entfällt.

## 2 · Auswahl in LSA und Session

**LSA.** `lsa_select_next_core(uuid,text[],timestamptz)` (`mig/20261011140200_f1_lsa_pool_testkonten.sql`,
zuletzt geändert in späteren LSA-Migrationen) zieht jede Aufgabe über
`lsa_freie_aufgabe(p_session, p_skill, p_pool, …)` (`mig/20261025144025_lsa_l2_wiederholung.sql:95`). Dort
steht der Filter: Schleife über die Kandidaten, `if public.lsa_im_pool(v_id, p_pool) then return v_id`.
Außerdem prüft der Core beim Themen-Einstieg `lsa_im_pool(t.id, v_pool)` direkt (Prod-Definition, Zeile 123).
`lsa_im_pool` (`mig/20261013161533_t4_pool_regel.sql:34`) verlangt `'lsa' = any(t.einsatz)`, aktiv, kein
Tutorial, `exercise`, Antworten (`lsa_has_answers`), eindeutiges Eingabeformat, `ready` (im Testlauf auch
ungeprüfte ohne `pruef_ausschluss`). Weitere Nutzer von `lsa_im_pool`: `lsa_start`, `lsa_ausblick_knoten`.

**Session.** `session_naechster_schritt(uuid,uuid)` (`mig/20261009101205_a2b_session_xp.sql`) plant über
`session_schritt_planen` (`mig/20261008122232_a2_naechster_schritt.sql:11`) und wählt mit
`session_aufgabe_waehlen(p_session, p_student, p_skill, p_schwierigkeit, p_testlauf, p_mit_loesungsweg)`
(`mig/20261008122230_a2_bausteine.sql:133`). Filter dort: `public.session_im_pool(t.id, p_testlauf)`, plus
„nicht in dieser Session benutzt" (`session_ausgegeben`, `session_schritte`, Lösungsbeispiele `art='beispiel'`
sitzungsübergreifend), Sortierung nach Abstand zur Schwierigkeit, dann ungesehen zuerst.
`session_im_pool` (`mig/20261013161533_t4_pool_regel.sql:12`) verlangt `'session' = any(t.einsatz)`, aktiv,
kein Tutorial, `exercise`, Antworten, `ready` (Testlauf: `testlauf_inhalt_sichtbar`). Zweiter Filterpunkt:
`aufgabe_ausgeben` (`mig/20261008124410_a2_verdrahtung_r1.sql`) lehnt Aufgaben außerhalb von
`session_im_pool` ab (Hinweis `nicht_ready`). Weitere Nutzer: `session_pool_anzahl`.

**Folge für A1:** Weil beide Wege nur über `einsatz` filtern, reicht die Datenänderung (alle → `{lsa}`),
damit die Session keine LSA-Aufgabe mehr zieht. `session_naechster_schritt` muss dafür nicht geändert werden;
C muss aber den leeren Pool ruhig behandeln (`an-C.md`).

## 3 · Aufgabenmodell

| Teil | Ort | Form |
|---|---|---|
| Aufgabe | `tasks` (46 Spalten, dbread `information_schema.columns`) | `question`, `question_payload` (Kindersicht, CHECK `tasks_question_payload_no_solution` verbietet `correct/accepted/pairs/blanks/expected`), `input_type` ∈ MC, NUMERIC, SHORT_TEXT, TRUE_FALSE, FREE_TEXT, MATCHING, CLOZE, COORDINATE, MULTI_PART, TERM; `difficulty` 1–5, `afb` I–III, `skill_key` → `skills`, `status` ∈ draft, review, ready, beanstandet, rueckfrage, `pruef_version` (Trigger `tasks_pruef_version` zählt bei jedem UPDATE hoch) |
| Teile | `tasks.parts jsonb` | Liste `{nr, kind: mc|short_input, prompt, options?, unit, afb …}`, CHECK `tasks_multipart_check` über `lsa_parts_valid` |
| Lösung | `task_solutions` (1:1) | `correct_answers` (Liste, bei MULTI_PART Objekt `{"1": [...], "2": [...]}`), `solution` (Lösungsweg Text), `hints` (Liste `{level 1–3, text, status entwurf|geprueft}`), `coach_hints`, `typical_errors`, `acceptance`, `option_scores` |
| Akzeptanz | `task_solutions.acceptance` | `{canonical, equivalents[], unit?, require_reduced?, known_errors{wert: slug}}`, bei MULTI_PART je Teil unter `"nr"` |
| Fehlbild-Zuordnung | `acceptance.known_errors` | Objekt `{falsche Antwort: slug}`; Treffer über `lsa_fehlbild_match(kind, known_errors, response)` (`mig/20260726100000_af1_fehlbild_capture.sql:83`), normalisiert über `lsa_normalize_answer` bzw. `lsa_normalize_term` |
| Fehlbild-Katalog | `fehlbild_labels(slug, klartext, erklaerung, familie, freigegeben_am, freigegeben_von)` | 162 Schlüssel, davon 0 mit `qf_` (dbread) |
| Figuren | `task_figures(task_id, generator, params, alt_text, svg_hash, erzeugt_am)` | siehe §6 |
| Beispiel (Abfrage) | NUMERIC aus `edvance_k9_quadrgl`: `correct_answers ["1","+1"]`, `acceptance {"canonical":"1","equivalents":["+1"],"known_errors":{"0":"vorzeichen_potenz","2":"division_vergessen"}}` | |

## 4 · Wertung

- `lsa_is_correct(text,jsonb,jsonb)` (`mig/20260722120000_a13_grader_split_und_abgabeart.sql:433`) und
  `lsa_grade(input_type, acceptance, correct_answers, response[, …])`
  (`mig/20261021082844_lsa_bruch_term_wertung.sql:188`, IMMUTABLE): MC über Mengengleichheit, TERM über
  `lsa_term_kanonisch`, sonst Wert-Einheit-Pfad mit `canonical`, `equivalents`, Bruch/Dezimal
  (`lsa_bruch_wert_gleich`), Unicode-Minus-tolerant ab PR #191.
- Session: `session_bewerten(p_task, p_teil, p_eingabe)` (`mig/20261007110500_session_antworten.sql:105`,
  STABLE) ruft `lsa_part_answer`, `lsa_is_correct`, `lsa_grade`, `lsa_fehlbild_match` und liefert
  `(ergebnis richtig|teilweise|falsch, fehlbild_slug)`. Geschrieben wird erst in `antwort_abgeben`
  (`mig/20261009103015_a2b_regeln.sql:8`): Zeile in `session_antworten`, Lernpfad-Beleg, Rückmeldung mit
  `fehlbild_klartext` aus `fehlbild_labels` (nur freigegebene; im Testlauf jeder).
- Prüfweg: `pruef_wertung_testen(p_task, p_teil, p_antwort, p_entwurf)`
  (`mig/20261005071648_pruefung_funktionen_d.sql:273`) ist STABLE, schreibt nicht, verlangt aber
  `darf_pruefen()` (über dbread als Systemaufruf erlaubt, siehe A4) und eine vorhandene Aufgabe.
- **Neue Antwortart anschließen:** Die Kernfunktionen sind rein (IMMUTABLE) und nehmen `acceptance`,
  `correct_answers`, `response` als jsonb. Eine neue Antwortart bekommt eine eigene reine Wertungsfunktion,
  die je Feld bzw. Element `lsa_grade`/`lsa_is_correct` aufruft; `session_bewerten` bzw. die neue
  `aufgabe_werten` verzweigen nach Format. Weil die Kernfunktionen ohne Aufgabe aufrufbar sind, kann die
  Prüfmaschine sie per dbread vor dem Einspielen aufrufen.

Stand: Edvancev1-A `74b5b4b8` (Branch feat/rasit-reihe1-a0, = origin/dev), edvance-app-A `e4cf268`. Nur gelesen; DB nur per `~/bin/dbread`.

## 5 · Lena-Board und Item-Pflege

### Task-Status
- CHECK `tasks_status_check`: `draft, review, ready, beanstandet, rueckfrage`
  (dbread: `select pg_get_constraintdef(oid) from pg_constraint where conrelid='public.tasks'::regclass …` → `CHECK ((status = ANY (ARRAY['draft','review','ready','beanstandet','rueckfrage'])))`).
- Bestand (dbread `select status,count(*) from tasks group by 1`): `draft 1040`, `ready 147`; review/rueckfrage/beanstandet derzeit 0.
- Abbildung auf Lenas Sprache: `pruef_lena_status(text)`: draft→offen, review→passt, rueckfrage→unsicher, beanstandet→passt_nicht, ready→freigegeben (dbread pg_get_functiondef).
- Wer setzt was:
  - Lena (coach mit `profiles.darf_pruefen`) oder Admin über `pruef_entscheiden`: passt→`review`, unsicher→`rueckfrage`, passt_nicht→`beanstandet`. Lena gibt nie frei (reviewed_by/at bleiben null).
  - Nur Admin → `ready`: `pruef_admin_freigeben`, `pruef_rueckfrage_klaeren(…'freigeben')`, `freigabe_thema` (Sammel), jeweils über `task_status_set(id,'ready')` (prüft `freigabe_gate_fehler`).
  - Nur Admin → `beanstandet`: `pruef_admin_zurueckweisen`, `pruef_rueckfrage_klaeren(…'zurueckweisen')` (schreibt `task_reviews`).
  - Admin → zurück `draft`: `pruef_rueckfrage_klaeren(…'an_lena')` (löscht `task_pruefung_ausgang`).
  - Rollenprüfung: `darf_pruefen()` = `role='admin' or (role='coach' and darf_pruefen)`; `pruef_nur_admin(fn)` / `get_my_role() is distinct from 'admin'` → errcode 42501.

### Tabelle `task_pruefungen` (supabase/migrations/20261005071058_pruefung_basis.sql:83-99)
`id uuid pk, task_id uuid → tasks (cascade), entscheidung text CHECK in ('passt','unsicher','passt_nicht','zurueckgenommen'), gruende text[] default '{}', notiz text, aenderungen jsonb default '[]' (Array {feld,teil,vorher,nachher}), aenderung_grund text, dauer_sek int 0..86400, geprueft_von uuid → profiles, geprueft_am timestamptz default now(), antwort text, beantwortet_von uuid, beantwortet_am timestamptz`.
RLS: select nur `darf_pruefen()` (:104-107), Trigger `task_pruefungen_nur_anhaengen` (append-only, :109ff; Ausnahme: `pruef_rueckfrage_klaeren` setzt antwort/beantwortet_* an der letzten Zeile).

### Funktionen (Signaturen per dbread aus pg_proc)
- Hinweis: Eine Funktion `pruefung_entscheiden` gibt es nicht; sie heißt **`pruef_entscheiden`**.
- `pruef_entscheiden(p_task_id uuid, p_version bigint, p_entscheidung text, p_gruende text[] default null, p_notiz text default null, p_aenderung_grund text default null, p_dauer_sek int default null) → jsonb`, SECURITY DEFINER. Letzte Fassung: supabase/migrations/20261005082412_pruefung_team_beanstandet.sql:133.
  Ablauf: `pruef_sperren` (darf_pruefen, Versionsvergleich `pruef_version` → ED409, nicht ready, nicht ausgeschlossen vera8/inaktiv/typ; für Nicht-Admin `pruef_lena_sperren`) → `pruef_ausgang_sichern` → Änderungen berechnen (`pruef_aenderungen`; Grund Pflicht wenn `pruef_einstellungen.grund_pflicht`) → passt: braucht Lösung + `freigabe_gate_fehler` null; unsicher: Notiz Pflicht; passt_nicht: Gründe aus festen 9 (`aufgabe_fehlerhaft, aufgabe_unklar, bild_falsch, sprache_zu_schwer, tablet_umbauen, passt_nicht_in_lsa, sonstiges, hinweis_verraet_loesung, hinweis_passt_nicht`), je Grund Zeile in `task_reviews` → `update tasks set status` + insert `task_pruefungen`. Rückgabe `{pruef_version, lena_status}`.
- `freigabe_thema(p_thema_key text, p_klasse int) → int`, SECURITY DEFINER, nur admin (42501). Letzte Fassung supabase/migrations/20261005071649_pruefung_funktionen_e.sql:99. Gibt alle `status='review'`-Tasks des Themas (über `skill_thema`) frei, ohne VERA8_IQB, `class_level <= p_klasse`, wenn `pruef_freigabe_erlaubt` (letzte Prüfung = passt **ohne** Änderungen, keine Admin-/System-Beanstandung, Fassung = Ausgang); P0001-Fehler je Task werden geschluckt; liefert Anzahl. Aufruf: src/lib/supabase/freigabe.ts:133, UI src/components/edvance/authoring/board/Arbeitsbereich.tsx:86.
- `pruef_board() → table(task_id, stufe, thema_key, thema_label, thema_sort, skill_key, skill_label, kurztitel, reihenfolge bigint, lena_status, geaendert bool, letzte_dauer_sek, anlaesse text[], hat_hinweise bool)`, STABLE SECURITY DEFINER, `darf_pruefen()` sonst 42501. Letzte Fassung supabase/migrations/20261022080744_p3_vorschau_pruefen.sql:33. Alle nicht ausgeschlossenen Tasks (`pruef_ausschluss` null; bei `pruef_einstellungen.nur_pilot` nur `pruef_pilot`), Reihenfolge Stufe (erste/zweite) → Thema-Sort → fundament_tiefe → Skill → sondierrang; `anlaesse` aus `pruef_soll`. Aufruf src/lib/supabase/pruefung.ts:52.
- Weitere: `pruef_board_soll(p_anlass)`, `pruef_admin_liste()`, `pruef_aufgabe(id)`, `pruef_speichern`, `pruef_rueckgaengig`, `pruef_wertung_testen`, `pruef_sammel`, `pruef_an_lena` (vollständige Liste: dbread `proname ~ '^(pruefung_|freigabe_|pruef_)'`).
- `pruef_einstellungen` (dbread): `id=t | hilfsmittel='Taschenrechner, Stift und Zettel' | nur_pilot=t | grund_pflicht=f`.

### Prüf-Vorschau „wie Tablet“ (PR #263, Commit d97e47d8)
- Änderung: src/components/edvance/authoring/PreviewStage.tsx (Text roh mit `whitespace-pre-wrap` statt MathContent/Markdown+KaTeX), Test AuthoringPreview.test.tsx, Retro docs/retros/2026-10-16-vorschau-wie-kind.md.
- Kette: `Kinderansicht` (src/components/edvance/pruefen/Kinderansicht.tsx:35) → `AuthoringPreview` (src/components/edvance/authoring/AuthoringPreview.tsx; RPC `task_preview_payload` via src/lib/supabase/taskPreview.ts:41, der intern `lsa_question_payload` ruft; Debounce 400 ms; mit/ohne Entwurf) → `PreviewStage` (Bühne: `Figuren` = -dunkel.svg in voller Breite, `KindText`, `Table`, `ShortInput` mit Einheit, `McOptions` A/B/C…, `Part` je Teilaufgabe, deaktivierter Weiter-Knopf).
- Formate (src/types/preview.ts:20-40): `kind` = `short_input` | `mc` | `multi_part` (Teile `short_input`|`mc`), plus `assets`, `table`, `unit`. Kein eigener Renderer für Bruch/Term (`input_hint`), Koordinate, Zuordnung o. ä.; Eingaben nur Attrappen (disabled). Tabelle hat auf dem Tablet keinen Renderer (Kommentar PreviewStage.tsx:28).
- #270 (22e23c39) ergänzte die Figuren auf dunkler Bühne.

### Tastenkürzel
- Lena-Prüfansicht `/coach/pruefen/:taskId`: src/pages/coach/pruefen/useTasten.ts:40-44 — `1` = Passt nicht (Panel), `2` = Unsicher (Panel), `3` oder Enter (nicht auf Knopf) = Passt, ←/→ = zurück/überspringen, Esc gestaffelt. Gleich in erklaer/ErklaerDetailPage.tsx:50-52.
- Admin-Prüfansicht `/admin/pruefen/:taskId`: src/pages/admin/pruefen/useAdminTasten.ts:1-5 — Enter = Freigeben, ←/→, `E` = Editor, Esc. Keine 1/2/3.
- Board-Übersichten (ItemBoardPage, PruefenUebersichtPage) haben keine Tastenkürzel (kein useTasten-Import).

### Seiten, Hülle, Komponenten
- Routen src/App.tsx: `/coach/pruefen` → PruefenUebersichtPage (:124-131, `ProtectedRoute allowedRoles={['admin','coach']} pruefrecht`), `/coach/pruefen/:taskId` → PruefansichtPage (:133-139), `/admin/authoring` → ItemBoardPage (:368-374, nur admin), `/admin/pruefen/:taskId` → AdminPruefansichtPage (:449-455).
- Hülle: `AdminLayout` (src/components/edvance/admin/AdminLayout.tsx, mit adminNav.ts, KennzahlenLeiste.tsx, useAdminZaehler.ts; App.tsx:47/97/208), Seitenkopf `PageHeader` (src/components/edvance/shell/PageHeader).
- Board-Bausteine: src/components/edvance/authoring/board/{Arbeitsbereich, BoardKachel, FortschrittsBalken, LenaInfo, PruefEinstellungenKarte, RueckfrageKlaeren, ThemaZeile}.tsx; Prüfansicht: src/components/edvance/pruefen/{Einordnung, Entscheidungsleiste, InfoTip, KinderHinweise, Kinderansicht, KnotenListe, PruefKopf, RegelUndTesten, RichtigeAntwort, Themenwechsel, TypischeFehler, Uebersicht}.tsx; Admin-Spezifika src/pages/admin/pruefen/{AdminKopf, AdminLeiste, HinweiseAdmin, KarteZusatz, LenasErgebnis, ReiheEndePage, useAdminAktionen, useAdminPruefung}.
- Lib: src/lib/supabase/pruefung.ts (pruef_board :52, pruef_entscheiden :84, pruef_rueckfrage_klaeren :190), pruefungAdmin.ts (:49 freigeben, :68 zurückweisen), freigabe.ts; Logik src/lib/pruefung/*.

## 6 · Werkzeuge

- **tools/verify-tasks.mjs** (465 Z.; Kopf :1-46): prüft Aufgaben unabhängig vom Generator. Stufe 1 Struktur (kostenlos), Stufe 2 Rechnung blind per LLM, Stufe 3 Plausibilität (nur Bericht). Quellen `--quelle prod` (SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY, liest `.env` per loadEnvFile) oder `--quelle datei --pfad x`, `--from-file <charge.json>`, `--answers-from <antworten.json>` (Blind-Löser-Subagent statt API, tools/blind-loeser/), `--prefill … --snapshot …` (ohne LLM/DB). Filter `--skill`, `--seit`, `--status`, `--source`, `--nur-struktur`, Gate `--min-pass 0.95`. Beispiel: `node tools/verify-tasks.mjs --from-file docs/prefill/k8-vorlauf.json --answers-from x.json`.
- **scripts/figures/**: Generatoren `koordinatensystem.py, winkel.py, thales.py, rechtecke.py, rechteck.py` (letzterer ruft rechteck.ts per tsx, braucht node_modules), Prüfer `pruefe_<name>.py` mit `pruefe(svg, params) -> (bool, meldung)`, die das erzeugte SVG zurückmessen (z. B. pruefe_winkel.py:1-30); Generatorschnittstelle `zeichne(params, theme) -> svg` (upload_figures.py:52-56); gemeinsame Basis svg_basis.py/svgBasis.ts, tokens.py, pruefungen.py (Eingabeprüfungen), Tests `test_<name>.py` (pytest), `sichtproben_koordinatensystem.py`.
- **Registrierung eines Generators**: (1) `<name>.py` + `pruefe_<name>.py` im Paket `figures`, (2) Eintrag in `GENERATOREN` in scripts/figures/upload_figures.py:61 (`("koordinatensystem","winkel","thales","rechtecke","rechteck")`, Kommentar: muss mit CHECK übereinstimmen), (3) Migration, die `task_figures_generator_check` erweitert. Laden: `importlib.import_module(f"figures.{name}")` / `figures.pruefe_{name}` (:64-77).
- **CHECK aktuell** (dbread pg_constraint): `task_figures_generator_check CHECK (generator = ANY (ARRAY['koordinatensystem','winkel','thales','rechtecke','rechteck']))`; außerdem `task_figures_alt_no_digit` (alt_text ohne Ziffern) und `task_figures_alt_not_empty`.
- **upload_figures.py** (scripts/figures/upload_figures.py:1-35): liest task_figures ohne/mit abweichendem `svg_hash`, erzeugt je Zeile dunkel+hell, prüft beide vor Upload, lädt nach Bucket `task-assets` `generiert/<task_id>/<generator>-{dunkel,hell}.svg`, stempelt `svg_hash`+`erzeugt_am`; `--dry-run`, `--force`. Env: DATABASE_URL, SUPABASE_URL, SUPABASE_SERVICE_KEY; psycopg2. „WIRD VON RASIT AUSGEFUEHRT, NICHT VON CLAUDE.“
- **tools/spec-figuren.sh**: erzeugt Specs `specs/active/figur-<id>.md` nach dem Muster koordinatensystem (Gates: pytest test_<id>.py, Import von <id>/pruefe_<id>, ≥3 `def pruefe_`, Negativkontrolle) für saeulendiagramm, baumdiagramm, urne, dreieck, winkel (:125-170); `bash tools/spec-figuren.sh [--force]`.
- **Python**: kein venv im Repo (`ls -a scripts/figures | grep venv` leer; keine pyvenv.cfg bis Tiefe 4). System-Python 3.14.4 (/usr/bin/python3), pip 25.1.1, `python3 -m venv` verfügbar, pytest 9.1.1 und psycopg2 vorhanden. **sympy fehlt** (`ModuleNotFoundError`). Netz geht: `pip download sympy --no-deps` → `sympy-1.14.0-py3-none-any.whl` (in scratchpad/pipdl, nichts installiert); apt-Kandidat `python3-sympy 1.14.0-2`. Hinweis: sympy braucht zusätzlich `mpmath`.

## 7 · Player in edvance-app-A

- Backend-`input_type` (CHECK an tasks): `MC, NUMERIC, SHORT_TEXT, TRUE_FALSE, FREE_TEXT, MATCHING, CLOZE, COORDINATE, MULTI_PART, TERM`. Bestand (dbread): NUMERIC 772 (129 ready), MULTI_PART 250 (7 ready), MC 85 (4 ready), TERM 20 (7 ready), FREE_TEXT 15, SHORT_TEXT 7, null 38.
- Die App kennt nur den Payload `kind` (src/types/content.ts:37-60): `mc` (options {id,label}), `short_input` (unit?, `input_hint` `number|fraction|term`), `multi_part` (Teile `short_input|mc`). Unbekannte kind → Fehler (src/lib/queries/lsa.ts:79-80, :162). Eingabemodi `zahl|bruch|term` (src/components/tasks/eingabeWert.ts:11; Abbildung src/components/tasks/eingabeModus.ts, Rückfall `zahl`).
- Komponenten: Einstieg `LsaAufgabe` (src/components/tasks/LsaAufgabe.tsx:27-35) verzweigt `layout='flaeche'` → `FlaecheAufgabe` (src/components/tasks/flaeche/**: Antwort, Felder, McKarten, Tastatur, TeilListe, Material, BildZoom, …; LSA platz-task/tutorial) sonst `ZweispaltigLayout` (src/components/tasks/aufgabe/ZweispaltigLayout.tsx; Session, Sequenz, task.tsx). Weitere: Buehne, AntwortKarten, EingabeFeld, Zahleneingabe, Ziffernblock, Teilaufgaben, AssetBild, WeiterKnopf.
- **src/components/aufgaben/ existiert nicht** (`ls` → No such file).
- Antwort-Kodierung (src/types/content.ts:120-162): MC `{"selected":["<id>"]}`, short_input `{"text":"…"}`, Ich-weiß-es-nicht `{"dont_know":true}`, MULTI_PART `{"1":"20","2":"b"}` (Session) bzw. `{"1":{"text":"7"},"2":{"dont_know":true}}` (LSA-Fläche); jede Teilaufgabe muss vorkommen.
- Datenfluss LSA: src/lib/queries/lsa.ts — `lsa_start(p_student_id,p_grade,p_subject)` :170, `lsa_submit(p_session_id,p_task_id,p_response,p_duration_ms)` :198 → `{next}`, `lsa_finish` :217 (app/(student)/lsa/task.tsx:94). Platz-LSA: src/lib/queries/platz.ts — `platz_next` :48, `platz_submit(p_task_id,p_response[,p_duration_ms])` :100, `platz_finish` :170 (app/(student)/lsa/platz-task.tsx:277). Keine Korrektheit zurück.
- Datenfluss Session: src/lib/queries/session.ts — `session_naechster_schritt` :108, `antwort_abgeben(p_session_id,p_task_id,p_teil,p_eingabe,p_dauer_ms)` :149 (eine Abgabe **je Teil**, `{text}`/`{selected}`), `hinweis_abrufen(p_session_id,p_task_id,p_stufe)` :168; Aufruf src/components/session/SessionAblauf.tsx:239.
- Rückmeldung/Hinweise in der Session: `parseRueckmeldung` (src/lib/queries/sessionVertrag.ts:244-250) → `{ergebnis richtig|teilweise|falsch, fehlbild_klartext}` oder neutral (Exit). `rueckmeldungAnzeige` (src/components/session/ablauf.ts:168-179): alle richtig → Ton gold „richtig“; sonst Ton `fehler`, Titel teilweise/falsch, `saetze` = deduplizierte `fehlbild_klartext`; Exit/neutral → „gespeichert“. Anzeige in src/components/session/AufgabeSchritt.tsx: Rückmeldung rechts unter der Eingabe (`feedback`, :153-155; roter Rand bei ton fehler), Hinweise links unter der Aufgabe (`buehneZusatz`, :163-166), nur bei `hinweise_erlaubt` und vor der ersten Antwort, Stufe für Stufe (:29-31, :117-141); kein zweiter Versuch (ablauf.ts:195).
- Ansichtstests: `npm run test:views` = `test:views:build` (expo export web nach `dist-views` mit `EXPO_PUBLIC_SESSION_VORSCHAU=1`, Supabase-URL `http://supabase.ansichtstest.invalid`) + `playwright test -c tests/views/playwright.config.ts` (package.json). Config: chromium, workers 1, nicht parallel, hasTouch, de-DE, serviceWorkers block, Port 47613 (`VIEWS_PORT`), webServer `node tests/views/server.mjs dist-views`, Attrappen in tests/views/kiosk.ts, Netzsperre fixtures.ts; nie `playwright install` (Chromium in ~/.cache/ms-playwright, `PLAYWRIGHT_CHROMIUM_EXECUTABLE`). Viewports tests/views/geraete.ts: 1180×820, 1180×740, 1133×744, 1024×768, 1366×1024 (alle quer).
- **src/types/database.ts** (9211 Z.) ist generiert per `supabase gen types --project-id …` (docs/lsa-erlebnis/durchlauf-bericht.md:78), **kein package.json-Skript**; Edit per Hook gesperrt (.claude/hooks/guard-paths.sh:24, CLAUDE.md:55/64).

## 8 · Einstellungen / Cron

- Stellschrauben: `session_einstellungen` (`schluessel, beschreibung, typ, wert jsonb, startwert jsonb, min, max, ganzzahl, werte text[], einheit, geaendert_am, geaendert_von`) + `session_einstellungen_protokoll` (`id, schluessel, alt jsonb, neu jsonb, grund, von, am`), Migration supabase/migrations/20261007110100_session_einstellungen.sql (RLS :118-127: Lesen alle authenticated, Protokoll nur admin).
- Schreiben: `einstellung_setzen(p_schluessel text, p_wert jsonb, p_grund text) → void`, SECURITY DEFINER, nur admin, Grund Pflicht, prüft `session_einstellung_gueltig(typ,min,max,ganzzahl,werte,wert)`, schreibt Protokoll.
- Lesen: `session_wert(p_session_id, p_schluessel) → jsonb` (Snapshot `coaching_sessions.einstellungen`, sonst Tabelle; 20261007110200_session_ablauf.sql:149-159), `session_wert_zahl`, `quest_einstellung(_zahl)`, `slots_einstellungen`; Snapshot bei `session_starten` (:214). Frontend src/lib/supabase/sessionEinstellungen.ts:18/31, UI src/pages/admin/stellschrauben/StellschraubenPage.tsx.
- Beispielzeilen (dbread, 30 Zeilen gesamt): `check_aufgaben_je_kernidee 1 zahl 1..3`, `erklaerrunden_bis_signal 2 zahl 1..3`, `erklaerung_anbieten_nach_fehlversuchen 2 zahl 1..4`, `erklaerung_bei_neuem_skill "vorgeschaltet" auswahl`, `exit_aufgaben 2`, `hinweisstufen 3 zahl 0..3`, `home_quests_aktiv false schalter`, `ka_tage 7 zahl 0..14`. Protokoll: 1 Eintrag (2026-10-10).
- Weitere Einzeiler-Einstellungstabellen: `pruef_einstellungen`, `akte_einstellungen`, `vertrag_einstellungen` (ohne Protokoll).
- **pg_cron: nein** (dbread `select extname from pg_extension`: pg_stat_statements, pgcrypto, plpgsql, supabase_vault, uuid-ossp). **Vercel-Cron: nein** (vercel.json nur SPA-Rewrite, kein `api/`-Ordner). Edge Functions supabase/functions/* (mail_senden, vertrag_pdf, …) ohne Zeitplan; GitHub-Workflows ci.yml/schema.yml ohne `schedule`.

## 9 · Was die Session speichert

| Was | Tabelle | Beleg |
|---|---|---|
| Ausgabe (gezeigt) | `session_ausgegeben(session_id, student_id, task_id, phase, eingemischt, zeit, von)` | `aufgabe_ausgeben` |
| Antwort, Versuch, Hinweis | `session_antworten(… teil, versuch_nr, eingabe jsonb, ergebnis, fehlbild_slug, hinweisstufe_max, dauer_ms, phase …)`, append-only (Trigger `session_antworten_nur_anhaengen`) | `antwort_abgeben` |
| Hinweisabrufe | `session_ereignisse(typ='hinweis', payload {task_id, stufe, geliefert})` | `hinweis_abrufen` (`mig/20261013151305_t3_session_testlauf_inhalte.sql:15`) |
| Lösungsbeispiel, Schritte | `session_schritte(art, phase, skill_key, task_id, modus, schwierigkeit, grund, details …)`; `art='beispiel'` gilt sitzungsübergreifend als benutzt | `session_aufgabe_waehlen` |
| Ein Versuch je Ausgabe | `antwort_abgeben` lehnt einen zweiten Versuch ab (`schon_beantwortet`, Entscheidung 29) | |

Für Bewährung und „schon gesehen" reichen `session_antworten` und `session_ausgegeben`/`session_schritte`.

## 10 · Coach-Prüffragen am Skill

- Ja: Tabelle **`skill_pruefung`** (supabase/migrations/20261007120412_lernpfad_schema.sql:100-116): `id, skill_key → skills, frage, erwartung, kriterium (alle not null), status ('entwurf','geprueft','freigegeben', default entwurf), quelle ('ki','mensch'), angelegt, aktualisiert`. Kommentar: „Pruefgespraech fuer die Mastery-Pruefung am Platz (Entscheidung 16) … Ausgeliefert wird nur status = freigegeben.“
- RLS: direkt nur admin (:245-252); Coaches über `skill_pruefung_lesen(p_skill_key)` (nur freigegeben) und `skill_pruefung_session(p_session_id, p_skill_key)` (gibt id, skill_key, frage, erwartung, kriterium, quelle, freigegeben; 20261014104355_t5_pruefung_session.sql:18-28). Tablet bekommt nur Label+Frage (`pruefung_aufs_tablet`/`pruefung_vom_tablet`; 20261009102010_a2b_pruefung.sql:2, 20261013160957_t4_pruefung_testlauf.sql:61).
- **Inhalt: 0 Zeilen** (dbread `select count(*) from skill_pruefung` → 0).
- Sonst keine passenden Spalten (dbread information_schema: nur `leads.erstgespraech_*`, `skill_pruefung.erwartung/kriterium`; keine Tabelle mit „frage“/„gespraech“ im Namen).

## 11 · Projekt-Ref von Prod

`.env`: `VITE_SUPABASE_URL` und `DATABASE_URL` enthalten beide die Ref **`ztcppihxqcphlqaguhma`**
(`supabase/config.toml:5` trägt nur `project_id = "Edvancev1"`, keine Ref). Die Einspiel-Skripte prüfen
`current_database() = postgres` und dass `$DATABASE_URL` diese Ref enthält.

## 12 · Zusatz: Types, pgTAP, Docker

- **Types in Edvancev1**: kein Generator-Skript in package.json, keine database.ts; Typen handgeschrieben in src/types/*.ts (pruefung.ts, preview.ts, …), Client untypisiert `createClient(URL, ANON)` (src/lib/supabase/client.ts:6). Typprüfung `npm run typecheck` (`tsc -b --noEmit`).
- **pgTAP in CI**: .github/workflows/schema.yml Job `neuaufbau` (postgres:16-Service): Namensschema prüfen → supabase/test-grundlage.sql → alle Migrationen sortiert → Schemavergleich gegen supabase/schema-erwartet.sql (pg_dump) → `apt-get install postgresql-16-pgtap` im Container, `create extension pgtap with schema extensions` → supabase/seed.sql → jede `supabase/tests/*.test.sql` mit `psql -X … PGOPTIONS='-c search_path=public,extensions -c jit=off'`, rot = `^not ok|^# Looks like`, Ausnahmen in supabase/tests/bekannt-rot.txt. ci.yml: npm ci, typecheck, lint, test (kein E2E).
- **pgTAP lokal**: Wegwerf-DB-Skripte tools/*-wegwerf-db.sh (z. B. `bash tools/lena-board-wegwerf-db.sh <db> --tests`, `PGTAP_SQL=…/pgtap--1.3.4.sql` aus `apt-get download postgresql-18-pgtap`, Vorlage per `createdb -T`), weitere: p1/p2/l1/slots/k8/k9/k10/… ; tools/neuaufbau-test.sh. supabase/tests: 88 Einträge (Tests + Fixtures lsa_l1_fixture.sql, session_*_fixture.sql, slots_fixture.sql, lsa_v_daten.sql, fixtures/).
- **Docker/Supabase CLI**: `which docker` → nicht gefunden; `supabase` → /mnt/c/Users/rasit/AppData/Roaming/npm/supabase (Windows-CLI); psql /usr/bin/psql; Postgres-Binärdateien unter /usr/lib/postgresql/18 (pg_ctl/initdb nicht auf PATH).

## 13 · Konzept-Feld → Ort

| Konzept | Ort heute | vorhanden / neu |
|---|---|---|
| Pool lsa \| session | `tasks.einsatz` (text[], Werte lsa/session/check/quest) | vorhanden, wird wiederverwendet: Default entfällt, CHECK „nie lsa und session zugleich" (A1) |
| Bauform (Schlüssel, Skill, Kernidee, Format, Rollen, Steckbrief, Version, Status …) | – | neu: Tabelle `bauformen` (A2) |
| Kernidee | `erklaer_kernidee(skill_key, nr, titel …)` | vorhanden; `tasks.kernidee_key` neu (Text `<skill>:K<n>`, A2) |
| Instanz → Bauform, Version, Parameter, Stufe, Rolle, Prüfmaschine | – | neu: Spalten an `tasks` (A2) |
| Stufe 1–5 | `tasks.difficulty` (1–5) | vorhanden für Altbestand; `tasks.stufe` neu für Instanzen (Rückfall: Stufe aus `difficulty`) |
| Aufgabentext | `tasks.question`, `question_payload` | vorhanden |
| Lösungsweg | `task_solutions.solution` (Text) | vorhanden; strukturierte Schritte und Warum-Bausteine neu im Payload des Formats bzw. im Steckbrief |
| Hinweise 3 Stufen | `task_solutions.hints [{level, text, status}]` | vorhanden |
| Fehlbild je Antwort | `task_solutions.acceptance.known_errors {wert: slug}` | vorhanden; für Lösungsmenge/Feldmaske neu als Liste von Bedeutungen je Format (A3) |
| Rückmeldung je Fehlbild | `fehlbild_labels.klartext` (je Schlüssel, nicht je Aufgabe) | vorhanden; Rückmeldung je Bauform neu im Steckbrief und in der Lösung der Instanz |
| Fehlbild-Katalog | `fehlbild_labels(slug, klartext, familie, freigegeben_am)` | vorhanden; `qf_`-Schlüssel neu (A2.2a) |
| Figur | `task_figures(generator, params, alt_text)`, CHECK der Generatoren | vorhanden; Generator `parabel` neu (A3) |
| Formate MC, Zahl, Bruch, Mehrteiler, Tabelle | `input_type` MC, NUMERIC, MULTI_PART, `question_payload.table` | vorhanden |
| Feldmaske, Lösungsmenge, Graph-Auswahl, Fehler finden, Bausteine, Schritte ordnen | – | neu (A3) |
| Wertung | `lsa_is_correct`, `lsa_grade`, `lsa_fehlbild_match`, `session_bewerten`, `pruef_wertung_testen` | vorhanden; `aufgabe_werten` neu (rein) |
| Payload Kindersicht | `lsa_question_payload`, `task_preview_payload` | vorhanden; `aufgabe_payload` neu |
| Lena-Entscheidung je Bauform | `task_pruefungen` (je Aufgabe) | Muster vorhanden; `bauform_pruefungen` neu |
| Sammelfreigabe | `freigabe_thema`, `pruef_sammel`, `task_status_set` | Muster vorhanden; Bauform-Sammelfreigabe neu |
| Gesehen (Session vor Ort) | `session_ausgegeben`, `session_schritte` (`art='beispiel'`) | vorhanden; `aufgabe_gezeigt` schreibt dorthin bzw. in eine eigene Tabelle (A2) |
| Bewährung (Zähler, Status) | `session_antworten` liefert die Rohdaten | Auswertung neu (A2, Trigger nach Insert, weil es kein pg_cron gibt) |
| Stellschrauben | `session_einstellungen` + `_protokoll`, `einstellung_setzen` | vorhanden; neue Schlüssel für Bewährung (A2) |
| Meldungen der Coaches | – | neu: `aufgabe_meldungen`, `aufgabe_melden` (A2) |
| Coach-Prüffragen | `skill_pruefung(frage, erwartung, kriterium, status, quelle)`, leer | vorhanden; `geprueft_von` fehlt (A2.8) |
| Kann entfallen | – | neu: Feld im Steckbrief, `skill_kann_entfallen` liest es (A2) |
| Cron | kein pg_cron, kein Vercel-Cron | Bewährung per Trigger |

## 14 · Fehlbild-Schlüssel, die im Katalog fehlen

Im Katalog stehen 162 Schlüssel, kein einziger mit `qf_` (dbread `select count(*) filter (where slug like 'qf_%') from fehlbild_labels` → 0).
Es fehlen also alle. Die acht aus Konzept §8:

`qf_quadrat_negativ`, `qf_streckfaktor_umgekehrt`, `qf_verschiebung_vorzeichen`, `qf_ergaenzung_nicht_abgezogen`,
`qf_nur_positive_loesung`, `qf_null_vergessen`, `qf_halbes_p_nicht_quadriert`, `qf_scheitel_statt_nullstelle`.

Aus den Fehlbildern in Konzept §4, je Denkfehler ein Schlüssel (mehrfach genannte Denkfehler bekommen einen gemeinsamen Schlüssel):

| Schlüssel | Denkfehler | Bauformen |
|---|---|---|
| `qf_ax_statt_ax2` | a·x statt a·x² gerechnet | PAR-1 |
| `qf_ax_quadriert` | (a·x)² statt a·x² gerechnet | PAR-1 |
| `qf_oeffnung_vertauscht` | nach oben und nach unten geöffnet verwechselt | PAR-2 |
| `qf_d_e_vertauscht` | Verschiebung nach rechts und nach oben vertauscht | PAR-3 |
| `qf_scheitel_koordinaten_vertauscht` | x- und y-Koordinate vertauscht | SCH-1, KO-1 |
| `qf_a_als_koordinate` | Streckfaktor als Koordinate genommen | SCH-1 |
| `qf_streckfaktor_vergessen` | Streckfaktor a nicht beachtet | SCH-2 |
| `qf_oeffnung_aus_e` | Öffnung aus e statt aus a gelesen | SCH-3 |
| `qf_binom_quadrat_differenz` | (x − d)² als x² − d² gerechnet | NF-1, BIN-1 |
| `qf_binom_mittelglied_fehlt` | das Glied 2dx vergessen | NF-1, BIN-1, BIN-2 |
| `qf_binom_vorzeichen` | Vorzeichen des Mittelglieds falsch | NF-1, BIN-1 |
| `qf_ergaenzung_b_statt_halb` | b statt b/2 in die Klammer | NF-2 |
| `qf_ausklammern_a_verloren` | a beim Ausklammern verloren | NF-3 |
| `qf_ergaenzung_ohne_a` | Ergänzung nicht mit a multipliziert | NF-3 |
| `qf_wurzel_als_haelfte` | Wurzel als Hälfte gerechnet | WZ-1, WZ-5, QW-1 |
| `qf_wurzel_aus_negativ` | Lösungen bei c < 0 angegeben | WZ-1 |
| `qf_umstellen_reihenfolge` | nicht zuerst b abgezogen | WZ-2, GL-1 |
| `qf_durch_a_vergessen` | nicht durch a geteilt | WZ-2, PQ-1, GL-1 |
| `qf_nullprodukt_vorzeichen` | Vorzeichen der Nullstellen aus den Faktoren falsch | NP-1, NP-2, NS-3 |
| `qf_a_uebersehen` | Faktor a in der zweiten Lösung übersehen | NP-2 |
| `qf_durch_x_geteilt` | durch x geteilt, Lösung 0 verloren | NP-3, NP-4 |
| `qf_p_vorzeichen` | −p/2 mit falschem Vorzeichen | PQ-1, PQ-2, NS-2 |
| `qf_q_vorzeichen` | q mit falschem Vorzeichen | PQ-2, DI-1 |
| `qf_nur_eine_loesung` | nur eine der zwei Lösungen | PQ-2, NS-2 |
| `qf_e_vorzeichen` | e mit falschem Vorzeichen | NS-1 |
| `qf_stelle_statt_wert` | Stelle (x, t) statt Funktionswert angegeben | EX-0, EX-1, EX-2 |
| `qf_hoch_tief_verwechselt` | Hoch- und Tiefpunkt verwechselt | EX-0 |
| `qf_umfang_statt_flaeche` | Umfang statt Fläche maximiert | EX-1 |
| `qf_ausklammern_unvollstaendig` | nicht der ganze gemeinsame Faktor ausgeklammert | AUS-1 |
| `qf_einsetzen_vorzeichen` | negative Zahl ohne Klammer eingesetzt | EIN-1 |
| `qf_gegenoperation_vorzeichen` | beim Umstellen das Vorzeichen nicht gewechselt | GL-1 |

„Wie WZ-3", „wie PQ-2" und „wie NF-2" in §4 verweisen auf diese Schlüssel. Die Rückmeldung „Eine Lösung fehlt noch."
ist kein Fehlbild, sondern die feste Rückmeldung der Lösungsmenge.
