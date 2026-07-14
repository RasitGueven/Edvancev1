# T1 — Altbestand-Leak: Backfill + Drop. Abgeschlossen.

**Datum:** 2026-07-14
**Branch:** `fix/T1-altbestand-leak` (Schritt 1) → `fix/T1b-drop-altfelder` (Schritt 2), je PR gegen `dev`
**Status:** **Beide Schritte erledigt. Das Leck ist zu.**

> **Nachtrag 14.07. (Schritt 2).** Der Drop ist durch: `tasks.solution` ist weg,
> die Lösungsfelder sind aus `question_payload` entfernt, ein CHECK verhindert
> ihre Rückkehr, und INV-6 beweist, dass ein Schüler-Kontext über keinen Weg an
> eine Lösung kommt. Details unten unter „Schritt 2".

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

## Schritt 2 — der Drop (Branch `fix/T1b-drop-altfelder`)

### Was die Lage gedreht hat

Der Drop hing an genau einem Blocker: `/student/session/:id` bewertete im
Browser und brauchte die Lösungsfelder im Payload. **Dieser Blocker ist
entfallen** — die Vite-Prototyp-App ist tot und wurde am 14.07. vom Netz
genommen (Vercel-Projekt gelöscht). Die Launch-App ist das native Frontend im
Repo `edvance-app`; sie bewertet serverseitig über `lsa_submit`. Damit hatte
`tasks` keinen Leser der Lösung mehr, und der Port der Session (bisher
Voraussetzung für den Drop) war nicht mehr nötig — die Session wurde stattdessen
**gelöscht**.

### Der Leak war nicht theoretisch — er war erreichbar

Der wichtigste Befund dieser Session, und der Grund, warum T1 keine Fleißarbeit war:

- Die Vite-App lief bis zum **14.07.2026 öffentlich unter `edvancev1.vercel.app`**.
- Vercel publiziert **jeden Branch als Preview-Deployment**. Es gab also nicht
  eine exponierte URL, sondern eine pro Branch — auch für Branches, in denen der
  Leak längst bekannt war.
- Die Policy `authenticated_read_tasks` gibt `tasks` an **jeden eingeloggten
  Nutzer** frei (qual: `auth.role() = 'authenticated'` — *keine* Rollen-,
  Klassen- oder Zuweisungs-Einschränkung), und PostgREST bietet `select=*` an.
  Jede:r Schüler:in konnte damit die Lösung zu **jeder** Aufgabe abfragen, auch
  zu nie zugewiesenen.

**Präzisierung, damit die Lehre stimmt:** Ein *anonymer* Besucher kam nicht an
die Lösungen — `anon` hat zwar ein SELECT-**Grant** auf `tasks`, aber die
RLS-Policy hält es zurück. Der Leak war „öffentlich erreichbar" in dem Sinn, dass
die App öffentlich stand und **ein beliebiger Account genügte**; er war nicht
ohne Login abrufbar. Dass dort trotzdem nur *eine* Bedingung zwischen `anon` und
den Aufgaben steht, ist der eigentliche Schrecken — deshalb pinnt INV-6
(Abschnitt D) genau diese Schicht fest.

### Was drin ist

4. **`supabase/migrations/20260714120000_t1b_drop_altbestand.sql`**
   - **Eigener Vorbedingungs-Guard.** Er prüft den Backfill selbst, statt sich
     auf T1a zu verlassen — inklusive der Lücke, die T1as Guard *nicht* sah:
     T1a fügte mit `on conflict do nothing` ein, eine kuratierte Zeile gewinnt
     und behält `legacy_payload = null`. Trägt dieselbe Aufgabe MATCHING/CLOZE/
     COORDINATE im Payload, wäre die Struktur nach dem Drop weg — und T1as Guard
     hätte grün gezeigt, weil eine Zeile ja *existiert*. Der neue Guard bricht
     hart ab, wenn irgendeine Lösung nicht verlustfrei angekommen ist.
   - `alter table tasks drop column solution`.
   - `correct`/`accepted`/`pairs`/`blanks`/`expected` aus `question_payload`
     entfernt (dieselbe Liste wie T1a).
   - **`CHECK tasks_question_payload_no_solution`.** Daten zu löschen schließt
     den Leak für *heute*; `question_payload` ist jsonb, und ein einziges
     späteres Insert mit `correct` darin macht ihn lautlos wieder auf. Erst der
     CHECK macht den Zustand unrepräsentierbar. **Das ist der eigentliche
     Verschluss**, nicht der Drop.

5. **`supabase/tests/inv6_keine_loesung_fuer_schueler.test.sql`** — der Beweis.
   Methode: ein **Sentinel-String** in `task_solutions`, dann jede Tür abklopfen,
   die ein Schüler aufbekommt: `select *` auf `tasks` (**alle Spalten**, via
   `to_jsonb(t)::text` — der Test nennt bewusst keine Feldnamen, damit auch ein
   künftiges `tasks.loesung_v2` auffliegt), `lsa_question_payload`, und die
   komplette LSA-Schleife (`start`/`submit`/`hint`/`finish`). Taucht der Sentinel
   irgendwo auf, ist der Test rot.
   - Enthält eine **Anti-Vakuum-Assertion**: Der Schüler muss die Aufgabe
     *sehen*. Ohne sie wäre „kein Sentinel gefunden" trivial wahr, sobald RLS die
     Zeile filtert — grün, ohne etwas geprüft zu haben. (Beim Schreiben genau in
     diese Falle getappt: eine erste Negativkontrolle meldete „kein Leak", weil
     die JWT-Claims fehlten und RLS die Zeile versteckte. Der Test wurde erst
     scharf, nachdem ein *absichtlich* gepflanzter Leak ihn rot machte.)

6. **Tote Vite-Oberfläche entfernt:** `src/pages/student/session/` (5 Dateien)
   und alles, was ausschließlich daran hing — `src/lib/answer/evaluators.ts`
   (die clientseitige Bewertung, also die Ursache), `src/components/edvance/
   tasks/answer/` (12 Dateien), `scripts/seed_session_tasks.sql`. Dazu die
   Route + der Link im `StudentDashboard`. **`vercel.json` gelöscht**, damit das
   Projekt nie wieder versehentlich verknüpft wird.

7. **Schreibpfade auf `task_solution_upsert` umgestellt** — nicht kosmetisch,
   sondern zwingend: sie schrieben `tasks.solution` und wären mit dem Drop
   **kaputt gegangen** (PostgREST: column does not exist). Betroffen:
   `createDiagnosticTask` (`src/lib/supabase/tasks.ts`) und
   `scripts/import/lambacher.ts`. Die Lösung geht jetzt über die RPC in die
   Server-Only-Zone; das Mapping (`solution` → `task_solutions.solution`) ist
   nicht geraten, sondern dasselbe wie in T1a.

### Verifikation

- `npx supabase db reset` → alle Migrationen laufen sauber in Reihenfolge
  (T1a *vor* T1b; T1as Backfill-Guard grün, dann der Drop).
- `npx supabase test db` → **6/6 Dateien PASS** (inkl. INV-6 mit 17 Assertions).
- `npx tsc --noEmit` → 0 Fehler. `npx vitest run` → 28/28. `npm run test:mock` → 19/19.
- ESLint auf `src/` sauber. (`scripts/` hat 39 **vorbestehende** Fehler, unverändert.)
- **Negativkontrolle:** ein absichtlich gepflanzter Leak (Payload mit `correct`,
  CHECK lokal entfernt) wird von INV-6 gesehen — der Test ist nicht vakuum-grün.
- **Prod-Bestand:** Die Remote-DB trägt **0** Aufgaben mit Lösung in
  `tasks.solution` oder `question_payload` (14 Aufgaben, alle 14 haben eine
  kuratierte `task_solutions`-Zeile mit `correct_answers` *und* `solution`). Der
  Drop kostet dort also nichts. **Achtung:** T1a war zum Zeitpunkt dieser Session
  auf der Remote-DB **noch nicht angewandt** (Stand: `20260713100000`) — T1a und
  T1b landen beim nächsten Deploy gemeinsam, in dieser Reihenfolge. Der Guard in
  T1b greift dann gegen den *echten* Bestand.

## Offen — bewusst NICHT in dieser Session entschieden

1. **Coach-Sicht auf die Lösung ist jetzt leer.**
   `TaskPedagogyAccordion.tsx:65,77` rendert `task.solution` — die Spalte gibt es
   nicht mehr, die Sektion bleibt still leer (kein Crash). Coaches *sollen* die
   Lösung sehen dürfen, aber `task_solutions` hat bewusst kein Grant für
   `authenticated`. Das braucht eine **eigene Coach-RPC** (`SECURITY DEFINER`,
   Rollen-Gate auf `coach`/`admin`) — die zu erfinden ist Lenas/Rasits
   Entscheidung, nicht meine. **Bis dahin ist das eine Feature-Regression, kein
   Bug.**
2. **`Task.solution` im Typ (`src/types/content.ts:53,74,93`) ist jetzt
   vestigial** — die Spalte ist weg, das Feld kommt nie mehr befüllt zurück. Der
   Typ wurde stehen gelassen, weil sein Entfernen den Accordion-Code (Punkt 1)
   zum Compile-Fehler macht und damit eine Produktentscheidung erzwingen würde.
   Gehört in denselben Commit wie Punkt 1.
3. **`tasks.typical_errors` bleibt.** Typische *Fehler* sind nicht die Lösung;
   T1a hat sie nach `task_solutions` mitgenommen, ein späterer Schnitt kann die
   Spalte folgen lassen. War nicht Auftrag von T1b.

## Nebenbefund: paralleles Arbeiten im selben Worktree

Während dieser Session hat eine zweite Claude-Session im **selben Verzeichnis**
den Branch auf `feat/F01-tabellen` gewechselt und dort F01 committet. Folge:
identischer Migrations-Präfix (`20260714100000`) und doppelt vergebene
INV-Nummer. Beides wurde aufgelöst (T1 liegt jetzt auf `20260714110000`, Test
auf INV-4), aber es hätte still Arbeit zerstören können.

**Konsequenz:** Parallele Sessions brauchen je einen eigenen `git worktree`
(wie `/home/rasit/Edvancev1-autoren` für A01) — nicht denselben Ordner.
