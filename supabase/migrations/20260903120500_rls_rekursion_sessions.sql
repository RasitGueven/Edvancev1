-- Rekursion zwischen coaching_sessions und session_students aufloesen.
--
-- Bestandsfehler, sichtbar als
--   infinite recursion detected in policy for relation "coaching_sessions"
--
-- Der Ring:
--   coaching_sessions_parent_read  liest session_students
--   session_students_coach_rw      liest coaching_sessions
-- Sobald ein Zugriff auf coaching_sessions beide Policy-Saetze auswerten
-- muss, dreht es sich.
--
-- Aufgeloest wie bei is_parent_of_student: die Unterabfragen wandern in
-- SECURITY DEFINER-Funktionen, die intern ohne RLS lesen. Die Zugriffslogik
-- bleibt exakt dieselbe -- Eltern sehen die Termine ihrer Kinder, Schueler
-- ihre eigenen, Coaches ihre eigenen, Admin alles.
--
-- session_students_coach_rw bleibt unveraendert: die Funktion darunter liest
-- coaching_sessions nun ohne RLS, damit ist die Rueckrichtung entschaerft.

create or replace function public.session_ids_fuer_eltern()
returns setof uuid
language sql
stable
security definer
set search_path to 'public'
as $function$
  select ss.session_id
  from session_students ss
  where public.is_parent_of_student(ss.student_id);
$function$;

create or replace function public.session_ids_fuer_schueler()
returns setof uuid
language sql
stable
security definer
set search_path to 'public'
as $function$
  select ss.session_id
  from session_students ss
  where ss.student_id = public.get_my_student_id();
$function$;

create or replace function public.session_ids_fuer_coach()
returns setof uuid
language sql
stable
security definer
set search_path to 'public'
as $function$
  select cs.id
  from coaching_sessions cs
  where cs.coach_id = auth.uid();
$function$;

drop policy if exists coaching_sessions_parent_read  on public.coaching_sessions;
drop policy if exists coaching_sessions_student_read on public.coaching_sessions;
drop policy if exists session_students_coach_rw      on public.session_students;

create policy coaching_sessions_parent_read on public.coaching_sessions
  for select using (id in (select public.session_ids_fuer_eltern()));

create policy coaching_sessions_student_read on public.coaching_sessions
  for select using (id in (select public.session_ids_fuer_schueler()));

create policy session_students_coach_rw on public.session_students
  using      (session_id in (select public.session_ids_fuer_coach()))
  with check (session_id in (select public.session_ids_fuer_coach()));
