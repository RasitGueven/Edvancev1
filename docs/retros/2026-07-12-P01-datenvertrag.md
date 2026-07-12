# Retro 2026-07-12 — P01: Datenvertrag + LSA-Logik

**Branch:** `feat/P01-datenvertrag` → PR gegen `dev`
**Spec:** `docs/specs/P01-datenvertrag.md` (mit den unten dokumentierten Korrekturen)

## Was gebaut wurde

- **Migration** `supabase/migrations/20260712100000_p01_datenvertrag.sql`
  - `tasks` + Lenas öffentliche Metadaten (`status`, `competency_content`,
    `competency_process`, `afb`, `est_duration_sec`, `unit`, `dialog_enabled`)
  - `task_solutions` — 1:1-Extension, **Server-Only-Zone**
  - `lsa_sessions` / `lsa_responses` (append-only)
  - `lsa_normalize_answer`, `lsa_is_correct`, `lsa_public_assets`,
    `lsa_question_payload`, `lsa_may_act_for`
  - RPCs: `lsa_start`, `lsa_submit`, `lsa_hint`, `lsa_finish`,
    `lsa_confirm_focus`, `task_solution_upsert`
- **pgTAP** `supabase/tests/inv2_lsa_datenvertrag.test.sql` (17 Assertions)
- **Doku** `docs/api/DATENVERTRAG.md` (der Vertrag fürs Frontend-Repo), `schema.sql` §15

## Entscheidungen (Abweichungen von der Spec)

1. **§4 ersetzt: Extension-Tabelle statt Column-Revoke.** Spaltenweise Grants auf
   `tasks` sind nicht verlässlich additiv (ein späteres `grant select on tasks`
   hebt sie auf), und PostgREST böte `select=*` weiter an. `task_solutions` hat
   schlicht kein Grant für `anon`/`authenticated`. Die pgTAP-Assertion zielt auf
   `task_solutions.correct_answers`.
   **Fallstrick:** `20260711120000_api_role_grants.sql` setzt `alter default
   privileges … grant … to authenticated`. Jede neue Tabelle bekommt sonst
   automatisch ein Tabellen-Tor — der explizite `REVOKE` ist der eigentliche
   Schutz, nicht Kosmetik.
2. **Diskriminator ist `input_type`, nicht `content_type`.** `content_type` ist
   das Medienformat und zugleich PK von `xp_rules` — nicht angefasst.
   Mapping: `MC` → `kind:'mc'`, `SHORT_TEXT`/`NUMERIC` → `kind:'short_input'`.
3. **`status` (draft|review|ready) neu.** Existierte nicht; `is_active` ist
   Sichtbarkeit, nicht Redaktions-Freigabe. Backfill: `is_active` → `'ready'`.
4. **`screening_tests` NICHT wiederverwendet** — `generate_parent_report` liest
   dessen `result_summary`-Format; eine LSA-Auswertung dort hätte den
   Eltern-Report gekippt. `student_focus_areas` **wird** wiederverwendet: der
   coach-bestätigte Fokus ist genau das, was die Tabelle schon modelliert.
5. **`lsa_normalize_answer` spiegelt `evaluators.ts` (SHORT_TEXT) exakt** —
   inklusive „nur das erste Komma" (`String.replace(',', '.')`). Eine Konvention
   an zwei Orten, nicht zwei Konventionen. Keine Einheiten-Umrechnung.

## FernUSG

`lsa_finish` liefert einen **Vorschlag** (`proposal.applied = false`) und
schreibt weder `student_focus_areas` noch `student_competency_mastery` — zwei
pgTAP-Assertions halten das fest. Erst `lsa_confirm_focus` (nur Coach/Admin)
macht daraus einen Lernpfad. Das bestehende Mastery-Gate ist unberührt; INV-1
bleibt grün.

Das Kind bekommt **kein** Richtig/Falsch: `lsa_submit` gibt nur `{ok, next}`
zurück, und Schüler haben auf `lsa_sessions`/`lsa_responses` bewusst *kein*
SELECT — die Zeilen tragen die Korrektheit. Das Frontend kann nichts
Verräterisches anzeigen, weil es nichts erfährt.

## Verifikation

- `npx supabase db reset` sauber · `db lint` sauber
- `npx supabase test db` → 25/25 (INV-1: 8, INV-2: 17)
- `npx tsc --noEmit` sauber · `npm run test` → 53/53

## Offene Punkte

- **Eltern-Report-Deploy:** Der Code-Fix (`skill_clusters`, kein `streak_days`)
  ist seit `ca32b5e` im Tree. `npx supabase functions deploy
  generate_parent_report` macht Rasit selbst — bewusst nicht Teil dieses Laufs.
- Der LSA-Pool ist leer, bis Lena Aufgaben auf `status='ready'` setzt **und**
  `task_solutions` befüllt (`task_solution_upsert`). `lsa_start` wirft dann ein
  klares `P0002`. Ein Autoren-UI dafür gibt es noch nicht.
- Bestandszeilen tragen die Lösung weiterhin in `tasks.question_payload`
  (kanonisches `AnswerPayload` mit `correct`/`accepted`) und `tasks.solution` /
  `tasks.hint` — beides für `authenticated` lesbar. Der neue Builder schleppt das
  nicht mit, aber der **Altbestand ist damit nicht saniert**. Neue LSA-Inhalte
  gehören ausschließlich in `task_solutions`. Eine Migration des Altbestands
  (Lösungsfelder aus `tasks` nach `task_solutions` ziehen, dann droppen) ist
  eigener Scope.
- Fehler-Dialog: `typical_errors` + `dialog_enabled` sind angelegt, **ohne
  Logik** (Spec §7).
