# T1 — Altbestand-Leak: Schritt 1 (Backfill), Drop vertagt

**Datum:** 2026-07-14
**Branch:** `fix/T1-altbestand-leak` → PR gegen `dev`
**Status:** Schritt 1 von 2 erledigt. **Das Leck ist noch offen.**

## Das Problem

`tasks.solution` und die Lösungsfelder in `tasks.question_payload`
(`correct`/`accepted`/`pairs`/`blanks`/`expected`) sind für die Rolle
`authenticated` lesbar. Die Baseline-Policy `authenticated_read_tasks` gibt die
ganze Zeile frei, PostgREST bietet `select=*` an. Ein eingeloggter Schüler kann
die Lösungen direkt abfragen. P01 hat mit `task_solutions` die sichere
Extension-Tabelle gebaut — der Altbestand wurde nie saniert.

## Warum der Drop NICHT in dieser Session kam

Der Grep nach Lesern hat einen Befund geliefert, der die Aufgabe umdreht:
**das Leck ist die Architektur der Live-Session, nicht ein vergessenes Feld.**

Es gibt zwei Stacks:

- **Stack A (P01, sicher, aber im Frontend tot):** `task_solutions` +
  `lsa_question_payload` (Whitelist) + `lsa_submit` (bewertet serverseitig).
  Ein Grep über `src/` nach `lsa_start|lsa_submit|task_solutions` liefert
  **null Treffer**. In der DB fertig, nirgends angebunden.

- **Stack B (live, unsicher):** `/student/session/:id` lädt über
  `getTasksByCluster` — ein `select('*')` auf `tasks`
  (`src/lib/supabase/tasks.ts:35`). `sessionQueue.ts:28` reicht
  `question_payload` unverändert an den Client, `SessionWork.tsx:46` ruft
  `evaluate(task.payload, …)` — **Bewertung im Browser**.

Der kanonische `AnswerPayload` (`src/types/answerPayload.ts`) *ist* die Lösung:
MC trägt `correct`, NUMERIC/SHORT_TEXT `accepted`, MATCHING `pairs`, CLOZE
`blanks[].accepted`, COORDINATE `expected`. Wer die Felder entfernt, nimmt der
Session das Einzige, wogegen sie prüfen kann. Der Drop ist also kein
Refactoring, sondern setzt den **Port der Session auf serverseitiges Grading**
voraus.

Entscheidung (Rasit): Backfill + RLS-Test jetzt, Port als eigener Branch.

## Was drin ist

1. **`supabase/migrations/20260714110000_t1_altbestand_backfill.sql`**
   Überführt den Bestand nach `task_solutions`. **Droppt nichts.**
   - `correct_answers` nur für die Typen, die `lsa_is_correct` auch bewerten
     kann (MC über Option-Ids, NUMERIC/SHORT_TEXT/TRUE_FALSE über text/value).
   - **Neue Spalte `task_solutions.legacy_payload`:** `correct_answers` ist ein
     flaches Text-Array — MATCHING, CLOZE und COORDINATE sind darin strukturell
     *nicht* abbildbar. Ohne verlustfreie Ablage wäre der spätere Drop ein
     Datenverlust. `legacy_payload` konserviert die Lösungsstruktur roh, in der
     Server-Only-Zone. Die LSA liest sie nicht (`lsa_question_payload` baut aus
     einer Whitelist und kann sie strukturell nicht mitschleppen).
   - `on conflict do nothing`: von Lena über `task_solution_upsert` gepflegte
     Zeilen (z.B. `scripts/import-lsa-items.ts`) sind kuratiert und gewinnen.
   - Abschließender `do`-Block bricht hart ab, wenn eine Aufgabe mit Lösung
     ohne `task_solutions`-Zeile bliebe. Lieber laut scheitern als still
     verlieren.

2. **`supabase/tests/inv4_rls_coverage.test.sql`** — INV-4: keine Tabelle in
   `public` ohne aktives RLS, plus: `task_solutions` hat kein Grant für
   `anon`/`authenticated`. Fragt den Katalog, pflegt keine Liste. Grund: die
   DEFAULT PRIVILEGES aus `20260711120000_api_role_grants.sql` geben *jeder*
   neuen Tabelle automatisch DML an `authenticated` — wer `enable row level
   security` vergisst, öffnet sie im selben Moment. Genau so ist dieser Leak
   entstanden.

3. **`src/pages/student/TaskPlayerBlocks.tsx`** — `VideoBlock` rendert
   `task.solution` nicht mehr. Das war ein eigenständiges Leck auf der
   Schüler-Fläche, unabhängig von der Session.

## Verifikation

- `npx supabase db reset` → Migration läuft sauber.
- `npx supabase test db` → **50/50, 4 Dateien PASS** (inkl. neuem INV-4).
- `npx tsc --noEmit` → 0 Fehler. `npx vitest run` → 53/53.
- **Achtung, Fallstrick:** Die lokale DB hat *null* `tasks` (der Seed legt keine
  an). „Migration läuft durch" beweist also nichts über den Backfill. Das
  Mapping wurde deshalb separat gegen die realen Payload-Formen geprüft
  (Fixtures für alle 8 `input_type`, Transaktion + Rollback): MC/NUMERIC/
  SHORT_TEXT/TRUE_FALSE landen korrekt in `correct_answers` und werden von
  `lsa_is_correct` richtig bewertet; MATCHING/COORDINATE landen verlustfrei in
  `legacy_payload`; eine Aufgabe ohne Lösung bekommt keine Zeile.
  **Gegen echten Prod-Bestand ist der Backfill noch nicht gelaufen.**

## Offen — Schritt 2 (eigener Branch)

1. **Port der Schüler-Session auf serverseitiges Grading** (`lsa_start` /
   `lsa_submit`). Das ist die Voraussetzung für alles Weitere.
2. **Erst danach:** `tasks.solution` droppen, `correct`/`accepted`/`pairs`/
   `blanks`/`expected` aus `question_payload` entfernen.
3. **Admin-/Autoren-Schreibpfad umstellen:** `NewTaskForm.tsx:181`,
   `createDiagnosticTask` (`tasks.ts:281`), `LambacherPreview.tsx:113` sowie
   `scripts/seed_session_tasks.sql` und `scripts/import/lambacher.ts` schreiben
   bzw. lesen `solution` weiterhin direkt. Sie müssen über
   `task_solution_upsert` gehen. **Nicht geraten — das ist Lenas Fläche und
   braucht ihre Abnahme.**
4. **pgTAP-Test „Schüler kommt über KEINEN Weg an eine Lösung"** (Punkt 5 des
   Auftrags) ist bewusst *nicht* geschrieben: Er würde heute fehlschlagen, weil
   das Leck noch offen ist. Er gehört in denselben Commit wie der Drop — dann
   ist er der Beweis, nicht ein roter Test.

## Nebenbefund: paralleles Arbeiten im selben Worktree

Während dieser Session hat eine zweite Claude-Session im **selben Verzeichnis**
den Branch auf `feat/F01-tabellen` gewechselt und dort F01 committet. Folge:
identischer Migrations-Präfix (`20260714100000`) und doppelt vergebene
INV-Nummer. Beides wurde aufgelöst (T1 liegt jetzt auf `20260714110000`, Test
auf INV-4), aber es hätte still Arbeit zerstören können.

**Konsequenz:** Parallele Sessions brauchen je einen eigenen `git worktree`
(wie `/home/rasit/Edvancev1-autoren` für A01) — nicht denselben Ordner.
