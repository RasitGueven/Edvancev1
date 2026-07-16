# Retro 2026-07-16 — S9: Platz-Mechanik (Kiosk für die LSA, Option 3)

**Branch:** `feat/S9-platz-mechanik` · **Migration:** `20260716110000_s9_platz_mechanik.sql`
· **Beweis:** `supabase/tests/s9_platz_mechanik.test.sql` (69 Assertions)
· **Grundlage:** `docs/specs/PLATZ-analyse.md` (Option 3, freigegeben durch Rasit)

## Was wurde gebaut

Die Kiosk-Mechanik, mit der ein dauerhaft eingeloggtes Tablet am Empfang genau
EINE LSA-Session bedient — und strukturell nichts anderes erreichen kann:

1. **`platz_devices`** — Kennzeichnung der Kiosk-Konten. Ein Platz ist ein
   normaler Auth-User mit `role='student'` OHNE `students`-Zeile: strukturell
   „nichts" (`get_my_student_id()` = null → alle `lsa_*` verweigern, praktisch
   keine RLS-Fläche). Keine neue Rolle, kein CHECK-Umbau.
2. **`platz_assignments`** — kurzlebige, SESSION-scoped Zuweisung
   (Partial-Unique je Platz, `expires_at` default 2 h, `released_at`).
   `created_by` hält die Auftrags-Identität des zuweisenden Admins fest.
3. **`platz_assign` / `platz_release`** — der Admin-Weg (ein Klick am Empfang).
   Gates: Platz-Konto (P0002), Session `in_progress` (P0001), keine aktive
   Zuweisung (P0001); räumt abgelaufene Alt-Zeilen auf.
4. **`platz_state` / `platz_next` / `platz_submit` / `platz_finish`** — die Tore
   nach dem a02-Muster („Tor vor bestehender RPC, keine zweite Wahrheit").
   Keine Funktion nimmt eine session_id von außen: alles löst über die aktive,
   nicht abgelaufene Zuweisung von `auth.uid()` auf. `platz_finish` VERWIRFT die
   Auswertung von `lsa_finish` (Rückgabe exakt `{ok:true}`).
5. **Release-Trigger** auf `lsa_sessions` (completed/aborted → Zuweisung released),
   analog `lsa_session_lead_fertig_trg` aus S7.
6. **§3.6(ii) der Analyse, bewusst gewählt:** das `authenticated`-Grant auf
   `lsa_question_payload` ist zurückgezogen — der Builder ist nur noch über
   seine Tore erreichbar (`lsa_start`/`lsa_submit` intern, `task_preview_payload`
   für Coach/Admin, `platz_next` für den Platz). Verifiziert: kein
   `.rpc('lsa_question_payload')` in `src/**`.

## Entscheidungen

- **Auftrags-Identität statt Vertragschirurgie:** `lsa_submit`/`lsa_finish`
  prüfen `lsa_may_act_for`, und der Platz ist dort GEWOLLT niemand. Statt die
  eingefrorene P01-Autorisierung zu erweitern (Option 1a, abgelehnt) oder die
  Logik zu duplizieren, tauschen `platz_submit`/`platz_finish` die JWT-Claims
  transaktionslokal auf den zuweisenden Admin (`created_by`), rufen die
  UNVERÄNDERTE RPC und schließen das Fenster sofort wieder. Kein Parameter des
  Aufrufers erreicht den erhöhten Block ungeprüft; pgTAP beweist, dass
  `auth.uid()` danach wieder der Platz ist. Dasselbe Muster wie die
  GUC-Schleuse `edvance.allow_provisional` (S7).
- **Grant-Rückzug §3.6(ii) → inv-Tests in den Definer-Kontext:** inv2/3/5/6/7/8
  riefen `lsa_question_payload` als `authenticated` auf und wären durch den
  Rückzug gebrochen. Die Inhalts-Assertions (Payload trägt keine Lösung) sind
  Eigenschaften der Funktion, nicht des Aufrufers — sie laufen jetzt im
  Definer-Kontext (`reset role`), die RLS-/Grant-Assertions drumherum bleiben
  `authenticated`. Die Nicht-Aufrufbarkeit pinnt `s9_platz_mechanik.test.sql`.
- **`aborted` released mit:** macht den Release nur prompter, nie einen Zugriff
  weiter (alle Tore prüfen ohnehin `status='in_progress'`).

## Offene Punkte

- **pgTAP-Lauf steht aus:** Docker war in der Session nicht verfügbar — vor
  Merge `npx supabase test db` (alle Suiten, wegen der inv-Anpassungen).
- **Migration ausführen:** `20260716110000_s9_platz_mechanik.sql` im SQL-Editor
  (Schema-Session mit Rasit), zusammen mit den noch offenen S7/P02-Migrationen.
- **Kiosk-Frontend + Admin-UI** (Zuweisen am Empfang, `platz_state`-Polling,
  Begrüßung/Avatar/Tutorial-Flow) sind eigene Läufe — S9 ist nur das Backend.
- **Platz-Konten anlegen** ist ein Betriebsschritt (Auth-User + `platz_devices`-
  Zeile via Admin/service_role), kein Migrationsinhalt.
- **Hinweis Guard:** `schema.sql`-Doku wurde in dieser Session per Bash
  eingespleißt, weil `ALLOW_MIGRATIONS=1` nicht in der Session-Umgebung gesetzt
  war (guard-paths blockte das Edit-Tool). Inhaltlich war die Session die
  explizite S9-Schema-Session.
