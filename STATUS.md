# Ist-Stand Edvance — faktischer Bericht

**Erhebung Stand 1:** 2026-08-10, nur `/home/rasit/Edvancev1`, Branch `dev` @ `c07dd20`.
**Erhebung Stand 2 (dieses Dokument):** 2026-08-11, zusätzlich `/home/rasit/edvance-app`, Branch `dev` @ `faecd34`.
**Quellen:** Git, Dateisystem, npm-Skripte, Live-Datenbank (PostgreSQL 17.6) über SELECT-only-`psql`. Alle DB-Ausgaben liefen durch `sed 's#postgresql://[^ ]*#[REDACTED]#g'`.

**Zur Vorgeschichte dieses Dokuments:** Eine Datei `STATUS.md` existierte vor diesem Lauf nirgends im Home-Verzeichnis (`find ~ -iname "STATUS.md"` → 0 Treffer). Der Bericht vom 10.08. wurde nie als Datei abgelegt; er endet mit der offenen Frage „Soll ich den Bericht als Datei unter `docs/` ablegen?". Rekonstruiert wurde er aus dem Lauf-Log `/home/rasit/logs/agent-20260810-1011.log`. Dieses Dokument ist die fortgeschriebene Fassung — eine zweite Datei wurde nicht angelegt.

**Sicherheitsrelevant, unverändert aus Stand 1:** Bei einem fehlgeschlagenen SQL hat `psql` am 10.08. die vollständige Connection-URL inklusive DB-Passwort in die Fehlerausgabe geschrieben. Der Wert steht im Log jener Session.

---

## 0. Status der Befunde aus Stand 1

| Befund aus Stand 1 | Status nach Prüfung von `edvance-app` |
|---|---|
| 1 · Git/Stillstand Edvancev1 | Nicht erneut geprüft — aus Stand 1 übernommen |
| 2 · Qualitäts-Gates Edvancev1 grün | Nicht erneut geprüft — aus Stand 1 übernommen |
| 3 · Schema/Migrationen ohne Drift | Teilweise geprüft: 87 Funktionen in `public` **bestätigt** |
| 4 · Vier Tabellen ohne RLS | **Bestätigt**, inklusive Mechanismus (§9) |
| 5 · Datenbestand | Kernzahlen **bestätigt** (§10) |
| **6 · Kernschleife ohne Konsumenten im Client** | **Korrigiert am 11.08. nach Prüfung von `edvance-app`** — fällt in der Hauptaussage (§4) |
| 6a · „128 `lsa_responses` aus manuellen Prüfläufen" | **Korrigiert am 11.08.** — widerlegt (§4, §5) |
| 6b · „Eltern-Report als Leseansicht" | **Korrigiert am 11.08.** — es gibt einen Schreibpfad (§7) |
| 7 · CLAUDE.md-Regeln Edvancev1 | Nicht erneut geprüft — aus Stand 1 übernommen |

---

## 1. `edvance-app` — Repository und Git

`git fetch --all` lief ohne Ausgabe und ohne Fehler; die Analyse steht damit auf frischem `origin`-Stand.

| Fakt | Wert | Beleg |
|---|---|---|
| Remote | `github.com/RasitGueven/edvance-app` | `git remote -v` |
| Lokaler Branch | `dev` | `git branch --show-current` |
| HEAD | `faecd34` | `git rev-parse HEAD` |
| `origin/dev` | `faecd34` — **identisch** | `git rev-parse origin/dev` |
| Unpushed Commits | **keine** | `git log --oneline origin/dev..HEAD` → leer |
| Rückstand zu origin | **keiner** | `git log --oneline HEAD..origin/dev` → leer |
| Letzter Commit | 2026-07-24 08:59:38 +0200, `test(lsa): cover the adaptive contract …` (#27) | `git log -1 --date=iso` |
| Stillstand seit | 18 Tagen (24.07. → 11.08.) | ebd. |
| Lokale Branches | 28 | `git branch -vv` |
| Remote-Branches | 29 inkl. `origin/HEAD` | `git branch -r` |
| Worktrees | **einer** (`/home/rasit/edvance-app`, `dev`) | `git worktree list` |
| Arbeitsverzeichnis | sauber bis auf untracked `.expo-web.log`, `.pr15-body.md`, `supabase/` | `git status --porcelain` |

Drei lokale Branches liegen hinter ihrem Remote (`chore/claude-md` −3, `feat/hub-und-lsa-live` −4, `feat/lsa-aufgabenscreen` −1, `feat/lsa-buehne-begleiter` −1); `feat/hub-split-layout` hat gar kein Remote-Tracking mehr. Kein Branch trägt unveröffentlichte Arbeit gegenüber `origin`.

**Wichtig für die Datierung:** `edvance-app` steht seit dem **24.07.** still, `Edvancev1` seit dem **30.07.** Die LSA-Session vom **06.08.** liegt nach beiden (§5).

## 2. `edvance-app` — RPC- und Tabellenzugriffe

`grep -rn "rpc(" --include=*.ts --include=*.tsx .` (ohne `node_modules`, ohne `dist/`) — **10 Aufrufstellen, 9 verschiedene Funktionen:**

| RPC | Datei:Zeile |
|---|---|
| `platz_state` | `src/lib/queries/usePlatzState.ts:67`, `src/lib/queries/useIsPlatz.ts:24` |
| `lsa_start` | `src/lib/queries/lsa.ts:126` |
| `lsa_submit` | `src/lib/queries/lsa.ts:154` |
| `lsa_finish` | `src/lib/queries/lsa.ts:173` |
| `get_my_student_id` | `src/lib/queries/student.ts:34` |
| `platz_next` | `src/lib/queries/platz.ts:48` |
| `platz_submit` | `src/lib/queries/platz.ts:73` |
| `platz_avatar_set` | `src/lib/queries/platz.ts:102` |
| `platz_finish` | `src/lib/queries/platz.ts:114` |

`grep -rn "\.from(" …` — **genau 2 direkte Tabellenzugriffe**, beide lesend:

| Tabelle | Datei:Zeile | Art | DB-Gegenprüfung |
|---|---|---|---|
| `students` | `src/lib/queries/student.ts:41` | `select` | Tabelle existiert, RLS **an**, `authenticated` hat SELECT |
| `student_progress` | `src/lib/queries/student.ts:74` | `select` | Tabelle existiert, RLS **an**, `authenticated` hat SELECT |

Beide über `get_my_student_id()` gefiltert. Kein `.from()` in `app/`, kein `.from()` mit Schreiboperation. Die Regel aus CLAUDE.md §3 („kein direkter `supabase.from(...)` in Komponenten oder in `app/`") ist eingehalten — alle Treffer liegen in `src/lib/queries/`.

### Die 15 konkret nachgefragten Funktionen

| Funktion | in `edvance-app` aufgerufen | Datei:Zeile | DB-intern erreicht über |
|---|---|---|---|
| `lsa_start` | **ja** | `src/lib/queries/lsa.ts:126` | zusätzlich `lead_lsa_freigeben`, `platz_next` |
| `lsa_select_next` | nein | — | `platz_submit` (Kern: `lsa_select_next_core` ← `lsa_start`, `lsa_submit`) |
| `lsa_submit` | **ja** | `src/lib/queries/lsa.ts:154` | zusätzlich `platz_submit`, `platz_next` |
| `lsa_finish` | **ja** | `src/lib/queries/lsa.ts:173` | zusätzlich `platz_finish` |
| `lsa_hint` | nein | — | **kein Aufrufer** |
| `lsa_confirm_focus` | nein | — | `lsa_finish` |
| `lsa_urteil_buchen` | nein | — | **kein Aufrufer** (Kern: `lsa_urteil_buchen_core` ← `lsa_submit`) |
| `lsa_uebernahme` | nein | — | **kein Aufrufer** |
| `lsa_fehlbild_auswertung` | nein | — | **kein Aufrufer** |
| `lsa_fehlbild_report` | nein | — | **kein Aufrufer** |
| `platz_next` | **ja** | `src/lib/queries/platz.ts:48` | — |
| `platz_submit` | **ja** | `src/lib/queries/platz.ts:73` | — |
| `platz_state` | **ja** | `usePlatzState.ts:67`, `useIsPlatz.ts:24` | — |
| `platz_finish` | **ja** | `src/lib/queries/platz.ts:114` | — |
| `platz_avatar_set` | **ja** | `src/lib/queries/platz.ts:102` | — |

Beleg für die internen Aufrufer: Abgleich der Funktionsrümpfe über `pg_proc.prosrc ~ '\mNAME\M'` im Schema `public`.

**Ein Kommentar im Code ist überholt:** `src/lib/queries/platz.ts:86–89` sagt, `platz_avatar_set` werde „parallel im Backend gebaut" und sei noch nicht deployt; deshalb der Cast und das stille Schlucken von Fehlern. Die Funktion **existiert in der Live-DB** (`pg_proc`), fehlt aber weiterhin in `src/types/database.ts` (`grep platz_avatar_set src/types/database.ts` → kein Treffer). Der Zustand ist also nicht „RPC fehlt", sondern „generierte Typen sind veraltet".

---

## 3. Repo-übergreifende RPC-Abdeckung

Gegenprüfung der `Edvancev1`-Liste aus Stand 1: bestätigt. 12 Aufrufe laufen über `.rpc(`, 3 weitere (`authoring_review_meta`, `freigabe_muster`, `freigabe_zuruecknehmen`) über einen bloßen `rpc(`-Helper und wären einem `\.rpc(`-Grep entgangen. Dazu `app_provision_student` außerhalb von `src` (Edge Function + Seed-Skript). Macht **16** für `Edvancev1`.

**Vereinigungsmenge: 25 verschiedene RPCs.** Die beiden Repos sind dabei **überschneidungsfrei** — 16 + 9 = 25, kein einziger RPC wird von beiden gerufen.

### Kategorie A — existiert in der DB und wird aufgerufen (25)

| RPC | aufgerufen von |
|---|---|
| `app_provision_student` | Edvancev1 (`supabase/functions/provision_student/index.ts:148`, `scripts/seed-test-student.ts:120`) |
| `authoring_review_meta` | Edvancev1 (`src/lib/supabase/taskAuthoring.ts:142`) |
| `complete_task` | Edvancev1 (`src/lib/supabase/taskProgress.ts:34`) |
| `freigabe_muster` | Edvancev1 (`src/lib/supabase/freigabe.ts:35`) |
| `freigabe_zuruecknehmen` | Edvancev1 (`src/lib/supabase/freigabe.ts:56`) |
| `lead_assessment_upsert` | Edvancev1 (`src/lib/supabase/leadLsa.ts:103`) |
| `lead_convert` | Edvancev1 (`src/lib/supabase/leadLsa.ts:82`) |
| `lead_lsa_freigeben` | Edvancev1 (`src/lib/supabase/leadLsa.ts:23`) |
| `platz_assign` | Edvancev1 (`src/lib/supabase/platz.ts:87`) |
| `platz_release` | Edvancev1 (`src/lib/supabase/platz.ts:68`) |
| `slot_assign` | Edvancev1 (`src/lib/supabase/slots.ts:167`) |
| `slot_release` | Edvancev1 (`src/lib/supabase/slots.ts:186`) |
| `task_preview_payload` | Edvancev1 (`src/lib/supabase/taskPreview.ts:41`) |
| `task_solution_get` | Edvancev1 (`src/lib/supabase/taskAuthoring.ts:75,226`) |
| `task_solution_upsert` | Edvancev1 (`src/lib/supabase/taskAuthoring.ts:265`, `tasks.ts:300`, 3 Skripte) |
| `task_status_set` | Edvancev1 (`src/lib/supabase/taskAuthoring.ts:78,295`) |
| `get_my_student_id` | **edvance-app** (`src/lib/queries/student.ts:34`) |
| `lsa_finish` | **edvance-app** (`src/lib/queries/lsa.ts:173`) |
| `lsa_start` | **edvance-app** (`src/lib/queries/lsa.ts:126`) |
| `lsa_submit` | **edvance-app** (`src/lib/queries/lsa.ts:154`) |
| `platz_avatar_set` | **edvance-app** (`src/lib/queries/platz.ts:102`) |
| `platz_finish` | **edvance-app** (`src/lib/queries/platz.ts:114`) |
| `platz_next` | **edvance-app** (`src/lib/queries/platz.ts:48`) |
| `platz_state` | **edvance-app** (`usePlatzState.ts:67`, `useIsPlatz.ts:24`) |
| `platz_submit` | **edvance-app** (`src/lib/queries/platz.ts:73`) |

### Kategorie B — existiert in der DB, von **keinem** Repo aufgerufen (62)

Aufgeschlüsselt, weil „nicht aufgerufen" hier drei sehr verschiedene Dinge heißt:

| Untergruppe | Anzahl | Bedeutung |
|---|---|---|
| B1 · DB-intern erreicht | **46** | Von einer anderen `public`-Funktion gerufen oder als Trigger angehängt — im Betrieb aktiv |
| B2 · über Constraint/Policy genutzt | **3** | `is_parent_of_student` (in **21** RLS-Policies), `lsa_answers_valid` (1 CHECK), `lsa_parts_valid` (1 CHECK) |
| B3 · **ohne jeden Aufrufer** | **13** | Weder Client, noch Funktion, noch Trigger, noch Constraint, noch Policy, noch Default |

Kontrolle: 25 + 46 + 3 + 13 = **87**. Deckt sich mit der Funktionszahl aus Stand 1.

Alle 11 Trigger-Funktionen sind tatsächlich an eine Tabelle angehängt (`pg_trigger` join `pg_class`, `not tgisinternal`) — auch `apply_xp_event` (`xp_events`) und `lsa_fehlbild_capture` (`lsa_responses`). Die Fehlbild-Erfassung läuft damit automatisch bei jedem Insert einer Antwort, ohne dass ein Client etwas rufen muss.

**Die 13 wirklich verwaisten Funktionen (B3):**
`calc_presence_multiplier`, `lead_delete`, `lena_beanstande`, `lena_beanstande_muster`, `lena_text_aendern`, `lsa_fehlbild_auswertung`, `lsa_fehlbild_report`, `lsa_hint`, `lsa_option_scores_complete`, `lsa_public_assets`, `lsa_uebernahme`, `lsa_urteil_buchen`, `mastery_stage_from_level`.

Belege: `pg_proc` gegen `called_union`, `pg_trigger`, `pg_constraint`, `pg_policies`, `pg_attrdef`.

### Kategorie C — Code ruft RPC, der in der DB nicht existiert

**Leer.** `comm -23 <(Vereinigungsmenge) <(pg_proc public)` liefert keine Zeile. Alle 25 aufgerufenen RPCs existieren in der Live-Datenbank. Der kritische Fall tritt nicht ein.

Einschränkung: Geprüft wurde die **Existenz** des Funktionsnamens, nicht die Übereinstimmung der Signaturen. Ein Aufruf mit falschen Parameternamen wäre hier nicht aufgefallen.

---

## 4. Befund 6 neu bewertet — die Hauptaussage fällt

> Stand 1 behauptete: „Das ist die eigentliche Kernschleife — Sitzung starten, Aufgabe ziehen, Antwort einreichen, Urteil buchen, Fehlbild auswerten. Sie existiert serverseitig und hat keinen Konsumenten im Client."

**Korrigiert am 11.08. nach Prüfung von `edvance-app`.** Die Aussage war eine Folge der Erhebungslücke: Sie wurde gegen `Edvancev1` erhoben, während die Schülerstrecke in `edvance-app` liegt. Im Einzelnen:

**Was fällt.** Die Kernschleife hat einen Konsumenten. `edvance-app` ruft `lsa_start`, `lsa_submit`, `lsa_finish` sowie die vollständige `platz_*`-Familie (`state`, `next`, `submit`, `finish`, `avatar_set`). Das ist Sitzung starten, Aufgabe ziehen, Antwort einreichen, Sitzung schließen — clientseitig angeschlossen und, wie §5 zeigt, tatsächlich gelaufen.

**Was sich als Fehlschluss erweist.** Stand 1 hat aus „kein Client-Aufruf" auf „tot" geschlossen. Für vier der acht als LSA-Laufzeit gelisteten Funktionen ist das auch ohne `edvance-app` falsch, weil sie serverseitig verkettet sind:

- `lsa_select_next` ← `platz_submit`; der Kern `lsa_select_next_core` ← `lsa_start`, `lsa_submit`
- `lsa_confirm_focus` ← `lsa_finish`
- `lsa_urteil_buchen_core` ← `lsa_submit` — das Urteil wird bei jeder Abgabe automatisch gebucht
- `lsa_fehlbild_capture` ist ein Trigger auf `lsa_responses` und ruft `lsa_fehlbild_match`

Die Fehlbild-Erfassung der letzten Arbeitswochen ist damit **aktiv**, nicht unbenutzt — sichtbar an 72 Zeilen in `fehlbild_labels`.

**Was bleibt.** Von der ursprünglichen Liste haben tatsächlich keinen Aufrufer: `lsa_hint`, `lsa_uebernahme`, `lsa_urteil_buchen` (der manuelle Wrapper, nicht der `_core`-Pfad), `lsa_fehlbild_auswertung`, `lsa_fehlbild_report`, dazu `lena_beanstande`, `lena_beanstande_muster`, `lena_text_aendern`, `lead_delete`. Die beiden Fehlbild-**Auswertungs**funktionen (`_auswertung`, `_report`, beide `TABLE(...)`-Rückgaben, also Leseberichte für Coach und Eltern) sind gebaut und werden von keiner Oberfläche gelesen.

**Fazit:** Befund 6 ist in der Hauptaussage nicht haltbar und wird ersetzt durch: *Die Kernschleife ist serverseitig und clientseitig verdrahtet und produktiv gelaufen. Ohne Konsumenten sind die Auswertungs- und Review-Schicht darüber — 13 Funktionen, darunter die gesamte Fehlbild-Auswertung und alle drei `lena_*`-Review-Werkzeuge.*

**Ebenfalls korrigiert:** Stand 1 schloss, die 128 `lsa_responses` stammten „aus manuellen Prüfläufen, nicht aus der Anwendung". Das ist widerlegt — siehe §5.

---

## 5. Die LSA-Session vom 06.08. — rekonstruierbar

Session `ed93da46-7076-4cfa-96b4-26e6be429768`, `in_progress`, Modus `adaptiv`, Fach Mathematik, Klasse 9. `item_ids` leer, `result_summary` leer, `completed_at` leer — die Session wurde nie abgeschlossen.

**Zeitverlauf** (alle Zeiten UTC, aus `lsa_sessions`, `platz_assignments`, `auth.users`, `lsa_responses`):

| Zeit | Ereignis | Beleg |
|---|---|---|
| 16:48:15.93 | Admin `rasit@edvanceacademy.de` meldet sich an | `auth.users.last_sign_in_at` |
| 16:49:05.99 | `lsa_sessions`-Zeile entsteht (`created_at` = `started_at`) | `lsa_sessions` |
| 16:49:08.97 | Platz-Zuweisung auf Konto `platz1@edvance.invalid`, `created_by` = derselbe Admin, `expires_at` +2 h | `platz_assignments` |
| 16:50:22.35 | Antwort 1, `abgabeart` `antwort`, korrekt, 20 153 ms | `lsa_responses` |
| 16:50:31.77 | Antwort 2, `abgabeart` `antwort`, falsch, 9 005 ms | `lsa_responses` |
| 16:50:34.76 | Antwort 3, `abgabeart` `weiss_nicht`, 2 613 ms | `lsa_responses` |
| — | `released_at` der Zuweisung ist **leer**; die Session steht bis heute offen | `platz_assignments` |

Dazu 4 Zeilen in `lsa_ausgegeben`: ein viertes Item wurde ausgegeben und nie beantwortet.

**Wodurch erzeugt — die Kette ist belegbar:**

1. **Erzeuger der Session:** Nur **eine** Funktion im Schema schreibt in `lsa_sessions` — `lsa_start` (`prosrc ~* 'insert into (public\.)?lsa_sessions'` → genau ein Treffer). Aufrufer von `lsa_start` sind `lead_lsa_freigeben` und `platz_next`.
2. **Es war `lead_lsa_freigeben`, nicht `platz_next`:** `platz_next` setzt eine bestehende Zuweisung voraus, die Zuweisung entstand aber erst **3 Sekunden nach** der Session. Passend dazu ist der Schüler `c017bf9e…` **provisorisch** (`is_provisional = t`, `profile_id` leer) und hängt an Lead `d9c9b82a…`, dessen Status auf `lsa_freigegeben` steht — genau das, was `lead_lsa_freigeben` setzt.
3. **Repo für Schritt 1 und 2:** `lead_lsa_freigeben` wird ausschließlich von `Edvancev1` gerufen (`src/lib/supabase/leadLsa.ts:23`), `platz_assign` ebenfalls (`src/lib/supabase/platz.ts:87`). `edvance-app` ruft beide nirgends. Der Admin saß also in der **Edvancev1-Weboberfläche** (Lead-/Intake-Strecke).
4. **Repo für die Antworten:** Die Antworten liefen über den **Kiosk-Pfad**. Das Konto `platz1@edvance.invalid` ist der einzige Eintrag in `platz_devices`, und `platz_submit` verweigert ohne `platz_devices`-Zeile mit `42501`. `platz_submit` delegiert intern an `lsa_submit` (die einzige Funktion, die `lsa_responses` schreibt). `platz_next`/`platz_submit` werden **nur** von `edvance-app` gerufen. Die Antworten kamen damit vom **Tablet mit `edvance-app`**.
5. **Nutzer:** Handelnd war durchgehend **ein** Mensch — Admin `rasit@edvanceacademy.de` (Anmeldung 16:48:15, `created_by` der Zuweisung). Das Tablet-Konto `platz1@edvance.invalid` hat sich zuletzt am **2026-07-29 08:09** angemeldet, am 06.08. also nicht neu — es lief auf einer fortgeschriebenen Sitzung.

**Nicht ermittelbar:** ob am Tablet ein Kind oder derselbe Admin saß. Die DB kennt nur das Platz-Konto, nicht die Person davor. Ebenso wenig, warum die Session offen blieb (kein `platz_finish`, kein `lsa_finish`).

**Konsequenz für Befund 6a:** Die Behauptung, die `lsa_responses` stammten aus manuellen Prüfläufen, ist widerlegt. **11 der 13 Sessions** haben eine Platz-Zuweisung, und **alle 128 Antworten** tragen ein `duration_ms` — eine clientseitig gemessene Bearbeitungszeit, die ein `psql`-Prüflauf nicht mitliefert. Die zwei Sessions ohne Zuweisung (12.07., 15.07.) passen zum direkten `lsa_start`/`lsa_submit`-Weg in `app/(student)/lsa/task.tsx`.

---

## 6. Frontend-Reifegrad `edvance-app` — Hub und LSA, sonst nichts

15 Routen-Dateien unter `app/` (`find app -type f -name "*.tsx"`):

| Route | Zweck |
|---|---|
| `app/_layout.tsx` | Root: QueryClient, Fonts, Auth-Gate, Kiosk-Weiche über `platz_state()` |
| `app/login.tsx` | Login |
| `app/(student)/_layout.tsx` · `index.tsx` | **Hub** — Level-Ring, Streak-Pill, XP-Multiplikator, Abmelden |
| `app/(student)/lsa/_layout.tsx` | LSA-Layout |
| `app/(student)/lsa/willkommen.tsx` | Kiosk-Einstieg, pollt `platz_state()` |
| `app/(student)/lsa/avatar.tsx` | Begleiterwahl → `platz_avatar_set` |
| `app/(student)/lsa/begruessung.tsx` · `intro.tsx` · `tutorial.tsx` · `horizont.tsx` | Einführungsstrecke |
| `app/(student)/lsa/task.tsx` | Aufgabenscreen, Session-Weg (`lsa_start`/`lsa_submit`) |
| `app/(student)/lsa/platz-task.tsx` | Aufgabenscreen, Kiosk-Weg (`platz_next`/`platz_submit`) |
| `app/(student)/lsa/done.tsx` | Abschluss |
| `app/(student)/lsa/asset-probe.tsx` | Entwicklungs-Hilfsscreen für SVG-Assets |

**Einen Session- oder Lernpfad-Screen gibt es nicht.** Vorhanden sind genau zwei Strecken: der Hub und die LSA — letztere in zwei parallelen Ausprägungen (Session-Weg und Kiosk-Weg). Kein Screen für die betreute Session, keine Lernpfad-Ansicht, keine Home-Quests, keine Badges.

Der Hub liest `student_progress` (XP, Level, Streaks) und hält die drei Skalen aus CLAUDE.md §5 getrennt — der Kommentar in `src/lib/queries/student.ts:63–67` nennt das ausdrücklich, und `student_competency_mastery` kommt im Client nicht vor.

**CLAUDE.md §8 ist an einer Stelle überholt:** Dort steht, die LSA laufe „noch auf Mocks (`src/mocks/lsaItems.ts`)" und die echten RPCs existierten erst nach dem P01-Merge. Ein Verzeichnis `src/mocks/` existiert nicht (`ls src/mocks` → nicht vorhanden), und `grep -rn "mocks/" src app` liefert keinen Treffer. Die LSA läuft gegen die echten RPCs.

## 7. Eltern-Report

**Korrigiert am 11.08.** Stand 1 führte den Eltern-Report als „Leseansicht". Es gibt einen vollständigen Schreibpfad.

| Ort | Repo | Art |
|---|---|---|
| `src/lib/supabase/parentReports.ts:11–12` | Edvancev1 | **`insert`** in `parent_reports` |
| `src/lib/supabase/parentReports.ts:35–36` | Edvancev1 | `select` |
| `src/lib/supabase/parentReports.ts:53–54` | Edvancev1 | **`update`** — Status `published`, `published_at` |
| `src/lib/supabase/generateParentReport.ts:17` | Edvancev1 | `supabase.functions.invoke(...)` — Edge Function |
| `supabase/functions/generate_parent_report/index.ts` | Edvancev1 | Generator; schreibt Zählzeilen in `parent_report_generations` (Z. 246, 428) |
| `src/pages/parent/ParentDashboard.tsx` | Edvancev1 | Oberfläche |
| `src/types/database.ts:581, 613` | edvance-app | **nur generierte Typen** — kein Code-Pfad |

`parent_reports` wird also in `Edvancev1` gelesen **und** beschrieben. In `edvance-app` gibt es dazu keinerlei Code außer den generierten Typen — der Eltern-Report ist kein Teil der App.

**Beide Tabellen sind leer:** `parent_reports` 0 Zeilen, `parent_report_generations` 0 Zeilen. Der Schreibpfad ist gebaut und nie gelaufen. Dazu passt, dass die beiden Auswertungsfunktionen, die ihn füttern würden — `lsa_fehlbild_auswertung` und `lsa_fehlbild_report` — keinen Aufrufer haben (§3), und dass es kein einziges `parent`-Profil gibt (§10).

## 8. Qualitätskette `edvance-app`

| Gate | Ergebnis | Beleg |
|---|---|---|
| TypeScript | **0 Fehler** | `npx tsc --noEmit`, Exit 0 |
| Vitest | **73 Tests in 5 Dateien, alle grün**, 434 ms | `npm run test` |
| ESLint | **existiert nicht** | keine `eslint.config.*`/`.eslintrc*`, kein `lint`-Script, ESLint nicht in `devDependencies` |

Testdateien: `eingabeWert.test.ts` (44), `himmel.test.ts` (9), `adaptiv.test.ts` (9), `assetTyp.test.ts` (6), `eingabeModus.test.ts` (5).

**CI ist hinter dem Repo zurück.** `.github/workflows/ci.yml` ist der einzige Workflow und fährt auf Push und PR nach `dev` genau: `npm ci` + `npm run typecheck`. Der Kommentar am Dateiende begründet das so:

> „Lint/Test bewusst NICHT im Gate: dieses Repo hat (Stand 12.07.2026) weder ein lint- noch ein test-Script in package.json. Sobald eines existiert, hier ergänzen."

Ein `test`-Script existiert inzwischen (`"test": "vitest run"`), die CI ruft es aber nicht. **Die 73 Tests laufen in keiner Pipeline.** Das ist die strukturelle Entsprechung zur Lücke in `Edvancev1`, wo die 15 SQL-Invariantentests ebenfalls von keiner Pipeline angefasst werden (Stand 1, §2).

Kein Schema- oder E2E-Workflow in diesem Repo.

## 9. RLS-Befund gegengeprüft — bestätigt, inklusive Mechanismus

`pg_class` / `pg_policies` / `has_table_privilege`:

| Tabelle | RLS an | forced | Policies | anon SELECT | auth SELECT | auth INSERT | auth UPDATE | auth DELETE |
|---|---|---|---|---|---|---|---|---|
| `skills` | **nein** | nein | **0** | ja | ja | **ja** | **ja** | **ja** |
| `skill_kante` | **nein** | nein | **0** | ja | ja | **ja** | **ja** | **ja** |
| `skill_voraussetzung` | **nein** | nein | **0** | ja | ja | **ja** | **ja** | **ja** |
| `themen` | **nein** | nein | **0** | ja | ja | **ja** | **ja** | **ja** |

Befund aus Stand 1 **bestätigt**, und schärfer: nicht nur RLS aus, sondern auch **null Policies**. Jeder eingeloggte Nutzer kann Skill-Substrat und Themenbaum schreiben und löschen.

**Der beschriebene Mechanismus greift genau so — belegt statt übernommen:**

1. `supabase/migrations/20260722130000_a14_skill_substrat.sql` legt alle vier Tabellen an (`CREATE TABLE` in Z. 51, 66, 83, 110) und enthält **kein** `row level security`, **keine** `policy`, **keinen** `grant` (`grep -in "row level security\|policy\|grant"` → kein Treffer).
2. `supabase/migrations/20260711120000_api_role_grants.sql` Z. 43–44 setzt:
   `alter default privileges for role postgres in schema public grant select, insert, update, delete on tables to authenticated, service_role;`
   Z. 45–46 dasselbe mit `select` für `anon`.
3. Die hinterlegten Default-Privilegien stehen so in der Live-DB (`pg_default_acl`):
   `postgres | r | {anon=r/postgres,authenticated=arwd/postgres,service_role=arwd/postgres}`
   — `arwd` ist genau INSERT/SELECT/UPDATE/DELETE.
4. Die Bedingung dafür ist erfüllt: Default-Privilegien greifen nur bei Tabellen, die der genannte Erzeuger anlegt. Alle vier Tabellen gehören **`postgres`** (`pg_get_userbyid(relowner)`).

Die Kette ist damit lückenlos: `a14` legt ohne RLS an, die Default-Privilegien der früheren Migration hängen `authenticated` volles DML an — automatisch, ohne dass es in `a14` sichtbar wäre.

## 10. Datenbestand — nachgezählt

Unverändert gegenüber Stand 1 (11.08. erneut abgefragt):

| | |
|---|---|
| `lsa_responses` | 128 |
| `lsa_skill_urteil` | 80 |
| `fehlbild_labels` | 72 |
| `platz_assignments` | 21 |
| `xp_events` | 1 |
| `parent_reports` / `parent_report_generations` | **0 / 0** |
| Profile | 2 `student`, 1 `admin` — **kein `coach`, kein `parent`** |
| LSA-Sessions | 13: 9 completed/fest (12.–22.07.), 2 completed/adaptiv (29.–30.07.), 1 in_progress/fest (15.07.), 1 in_progress/adaptiv (**06.08.**) |
| `platz_devices` | 1 (`platz1@edvance.invalid`) |

Antworten pro Session: 7–8 im festen Modus, 35 bzw. 24 in den beiden abgeschlossenen adaptiven Sessions, 3 in der offenen vom 06.08.

Nicht erneut geprüft und aus Stand 1 übernommen: 627 Aufgaben, 38 Skills, Aufgabentyp-Verteilung, 28 leere Tabellen, 35 Migrationen ohne Drift.

## 11. Nicht ermittelbar

- **Wer am 06.08. am Tablet saß.** Die DB kennt nur das Platz-Konto.
- **Warum die Session vom 06.08. offen blieb.** Kein `platz_finish`, kein `lsa_finish`, `released_at` leer.
- **Deployment-Stand beider Repos.** `vercel.json` liegt in beiden vor; welcher Commit live ist, geht aus Repo und DB nicht hervor.
- **Ob Signaturen der 25 aufgerufenen RPCs zu den Aufrufen passen.** Geprüft wurde nur die Existenz der Namen.
- **Ob die vier RLS-offenen Tabellen ausgenutzt wurden.** Ohne Audit-Log nicht feststellbar.
- **Grund des Entwicklungsstopps** (edvance-app 24.07., Edvancev1 30.07.). Aus Code und Git nicht ableitbar.

---

## Kurzfassung

Der Bericht vom 10.08. war gegen nur eines von zwei Repos erhoben. Mit `edvance-app` dazu verschiebt sich das Bild an einer zentralen Stelle.

**Befund 6 fällt in seiner Hauptaussage.** Die Kernschleife hat einen Konsumenten: `edvance-app` ruft `lsa_start`, `lsa_submit`, `lsa_finish` und die vollständige `platz_*`-Familie. Zusätzlich war ein Teil des ursprünglichen Schlusses auch unabhängig davon zu scharf — `lsa_select_next`, `lsa_confirm_focus`, `lsa_urteil_buchen_core` und die Fehlbild-Erfassung sind serverseitig verkettet bzw. als Trigger angehängt und laufen ohne jeden Client-Aufruf. Die 128 Antworten stammen nicht aus manuellen Prüfläufen: 11 von 13 Sessions haben eine Platz-Zuweisung, alle 128 tragen eine clientseitig gemessene Bearbeitungszeit.

**Was stattdessen ohne Konsumenten ist,** liegt eine Schicht höher: 13 von 87 Funktionen haben weder Client- noch DB-internen Aufrufer. Darunter die beiden Fehlbild-**Auswertungen** (`lsa_fehlbild_auswertung`, `lsa_fehlbild_report`), die Übernahme (`lsa_uebernahme`), der Hinweis (`lsa_hint`) und alle drei `lena_*`-Review-Werkzeuge. Die Erhebung läuft, die Auswertung darüber wird von keiner Oberfläche gelesen. Dazu passt der Eltern-Report: Lese- **und** Schreibpfad sind in `Edvancev1` gebaut — `parent_reports` hat 0 Zeilen, und ein `parent`-Profil existiert nicht.

**Kein kritischer Fall.** Alle 25 aufgerufenen RPCs existieren in der Live-DB; kein Aufruf zeigt ins Leere. Die beiden Repos sind überschneidungsfrei: 16 RPCs ruft nur `Edvancev1` (Autorentool, Leads, Slots, Platz-Verwaltung), 9 nur `edvance-app` (LSA- und Kiosk-Laufzeit).

**Der RLS-Befund bleibt bestehen** und ist jetzt bis zur Ursache belegt: `skills`, `skill_kante`, `skill_voraussetzung`, `themen` haben RLS aus **und null Policies**; `a14_skill_substrat` legt sie ohne RLS an, die `ALTER DEFAULT PRIVILEGES` aus `api_role_grants.sql` hängen `authenticated` volles DML an, und die Bedingung dafür — Eigentümer `postgres` — ist bei allen vieren erfüllt.

**Die Qualitätskette von `edvance-app`** ist grün, wo sie existiert: Typecheck 0 Fehler, 73 Tests grün. Sie ist aber schmaler als die des Backends — kein ESLint im Repo, und die CI fährt nur `typecheck`, weil ihr Kommentar vom 12.07. stammt, als es noch kein `test`-Script gab. Die 73 Tests laufen in keiner Pipeline. Dieselbe Lücke wie bei den 15 SQL-Invariantentests in `Edvancev1`.

**Frontend-Reifegrad:** `edvance-app` hat Hub und LSA — letztere in zwei Strecken (Session-Weg und Kiosk-Weg). Einen Session- oder Lernpfad-Screen gibt es nicht. Beide Repos stehen still: `edvance-app` seit 24.07., `Edvancev1` seit 30.07., beide ohne unveröffentlichte Commits. Die einzige Aktivität danach ist die LSA-Session vom 06.08., angelegt aus der Edvancev1-Oberfläche über `lead_lsa_freigeben` und beantwortet vom Tablet über den Kiosk-Pfad.
