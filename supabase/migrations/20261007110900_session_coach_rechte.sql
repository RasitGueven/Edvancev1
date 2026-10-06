-- R1: Coaches legen Sessions und Buchungen nicht mehr selbst an und aendern sie
-- nicht (Rasit, 06.10.). Buchungen machen nur Admin und Slots. Sonst koennte ein
-- Coach die LSA-Startbedingung aus X0 (gebuchte, nicht abgesagte Session,
-- 20261007100500_x0_lsa_start.sql) selbst erfuellen.
--
-- Vorher (baseline / 20260903120500_rls_rekursion_sessions.sql:66-68):
--   coaching_sessions_coach_rw  FOR ALL  coach_id = auth.uid()
--   session_students_coach_rw   FOR ALL  session_id in session_ids_fuer_coach()
-- Nachher: nur noch SELECT fuer den Coach. Admin-, Eltern- und Schueler-Regeln
-- bleiben unveraendert.
--
-- Einziger Coach-Schreibweg im Frontend war die Anwesenheit im CoachDashboard
-- (src/pages/coach/CoachDashboard.tsx:185 -> src/lib/supabase/sessions.ts setAttendance,
-- UPDATE session_students). Er geht jetzt ueber anwesenheit_setzen: der Coach der
-- Session setzt nur 'present' oder 'unexcused' (src/types/session.ts:3-5) und nur
-- bei Buchungen, die nicht abgesagt sind. Abgesagte Buchungen aendert nur ein Admin.

drop policy if exists coaching_sessions_coach_rw on public.coaching_sessions;
create policy coaching_sessions_coach_read on public.coaching_sessions
  for select using (coach_id = auth.uid());

drop policy if exists session_students_coach_rw on public.session_students;
create policy session_students_coach_read on public.session_students
  for select using (session_id in (select public.session_ids_fuer_coach()));

create function public.anwesenheit_setzen(p_session_id uuid, p_student_id uuid, p_attendance text)
returns public.session_students
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_admin boolean := coalesce(public.get_my_role(), '') = 'admin';
  b       public.session_students;
begin
  perform public.session_coach_pruefen(p_session_id, 'anwesenheit_setzen');
  if p_attendance is null
     or p_attendance not in ('planned', 'present', 'cancelled', 'unexcused', 'cancelled_by_us')
     or (not v_admin and p_attendance not in ('present', 'unexcused')) then
    raise exception 'anwesenheit_setzen: Wert % nicht erlaubt', p_attendance using errcode = '22023';
  end if;

  select * into b from public.session_students
   where session_id = p_session_id and student_id = p_student_id for update;
  if not found then
    raise exception 'anwesenheit_setzen: Kind ist in dieser Session nicht gebucht' using errcode = 'P0002';
  end if;
  if not v_admin and b.attendance in ('cancelled', 'cancelled_by_us') then
    raise exception 'anwesenheit_setzen: eine abgesagte Buchung aendert nur ein Admin' using errcode = '42501';
  end if;

  update public.session_students set attendance = p_attendance
   where session_id = p_session_id and student_id = p_student_id
  returning * into b;
  return b;
end;
$$;

comment on function public.anwesenheit_setzen(uuid, uuid, text) is
  'R1: Anwesenheit setzen. Coach der Session: present/unexcused, nicht bei abgesagten Buchungen. Admin: alle Werte.';

revoke all on function public.anwesenheit_setzen(uuid, uuid, text) from public, anon, authenticated;
grant execute on function public.anwesenheit_setzen(uuid, uuid, text) to authenticated;
