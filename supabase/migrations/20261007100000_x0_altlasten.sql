-- X0.1 Altlasten stilllegen (Bauauftrag Session-Rahmen P1, Entscheidung 24).
--
-- Der Web-TaskPlayer in Edvancev1 (/student/task/:taskId) schrieb ohne Coach
-- und ohne Session-Bezug in behavior_snapshots und student_task_progress und
-- buchte ueber complete_task XP. Die Route ist stillgelegt; hier verlieren
-- Clients die Schreibrechte. Tabellen, Daten und Code bleiben stehen.
--
-- Lesen bleibt wie bisher (eigene Zeilen, Eltern); die Coach-Lesegrenze zieht
-- 20261007100600_x0_coach_rechte.sql nach.

-- behavior_snapshots: append-only Rohdaten (CLAUDE.md §6), kein Client schreibt mehr.
drop policy if exists users_insert_own_snapshots on public.behavior_snapshots;
revoke insert, update, delete on public.behavior_snapshots from anon, authenticated;

-- student_task_progress: aus ALL fuer das eigene Kind wird reines Lesen.
drop policy if exists student_task_progress_own_rw on public.student_task_progress;
create policy student_task_progress_select_own on public.student_task_progress
  for select using (student_id = public.get_my_student_id());
revoke insert, update, delete on public.student_task_progress from anon, authenticated;

-- complete_task ist der Schreibweg des Web-TaskPlayers (Fortschritt + XP).
-- Als SECURITY DEFINER umginge er die Rechte oben; Clients rufen ihn nicht mehr.
revoke all on function public.complete_task(uuid) from public, anon, authenticated;

comment on table public.behavior_snapshots is
  'Altlast (X0, Entscheidung 24): Web-TaskPlayer stillgelegt, keine Client-Schreibrechte. Nicht loeschen.';
comment on table public.student_task_progress is
  'Altlast (X0, Entscheidung 24): Web-TaskPlayer stillgelegt, Clients lesen nur. Nicht loeschen.';
