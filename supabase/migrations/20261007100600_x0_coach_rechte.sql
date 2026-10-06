-- X0.2 Coach-Rechte (Entscheidung 26, schliesst S1b fuer diese Tabellen).
--
-- Ein Coach liest LSA-Antworten, Urteile, Reports, Fortschritt/Lernpfad, XP
-- und Badges nur fuer Kinder mit laufendem Vertrag — Muster der Akte:
-- akte_aktiv(student_id) (vertraege_aktuell.wirksamer_status in aktiv,
-- im_widerruf). Nie fuer Leads ohne Vertrag oder ruhende Akten. Coaches
-- schreiben in diese Tabellen nichts direkt; Admin unveraendert.
--
-- Rollback: docs/session/rollback-x0-coach-rechte.sql

-- Hilfsfunktion fuer Tabellen, die nur ueber lsa_sessions am Kind haengen
-- (DEFINER gegen RLS-Ketten, wie in S1b vorgeschlagen).
create function public.lsa_session_akte_aktiv(p_session_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.lsa_sessions l
     where l.id = p_session_id and public.akte_aktiv(l.student_id)
  )
$$;
revoke all on function public.lsa_session_akte_aktiv(uuid) from public, anon, authenticated;
grant execute on function public.lsa_session_akte_aktiv(uuid) to authenticated;
comment on function public.lsa_session_akte_aktiv(uuid) is
  'true, wenn das Kind der LSA eine aktive Akte hat (Coach-Lesegrenze, X0).';

-- Die LSA-Funktionen (lsa_submit, lsa_finish, lsa_hint, lsa_fehlbild_*,
-- lsa_urteil_buchen, lsa_select_next) pruefen ueber lsa_may_act_for.
-- Coach nur noch bei aktiver Akte; Admin und das Kind selbst unveraendert.
create or replace function public.lsa_may_act_for(p_student_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.get_my_role() = 'admin'
      or (public.get_my_role() = 'coach' and public.akte_aktiv(p_student_id))
      or public.get_my_student_id() = p_student_id
$$;

-- lsa_sessions: Coach nur lesen, nur aktive Akte (auch kein direktes Anlegen).
drop policy if exists lsa_sessions_coach_admin_all on public.lsa_sessions;
create policy lsa_sessions_admin_all on public.lsa_sessions
  for all using (public.get_my_role() = 'admin') with check (public.get_my_role() = 'admin');
create policy lsa_sessions_coach_select on public.lsa_sessions
  for select using (public.get_my_role() = 'coach' and public.akte_aktiv(student_id));

-- Antworten, Ausgabe, Urteile, Report-Notizen: ueber die Sitzung am Kind.
drop policy if exists lsa_responses_coach_admin_read on public.lsa_responses;
create policy lsa_responses_admin_read on public.lsa_responses
  for select using (public.get_my_role() = 'admin');
create policy lsa_responses_coach_select on public.lsa_responses
  for select using (public.get_my_role() = 'coach' and public.lsa_session_akte_aktiv(session_id));

drop policy if exists lsa_ausgegeben_coach_admin_read on public.lsa_ausgegeben;
create policy lsa_ausgegeben_admin_read on public.lsa_ausgegeben
  for select using (public.get_my_role() = 'admin');
create policy lsa_ausgegeben_coach_select on public.lsa_ausgegeben
  for select using (public.get_my_role() = 'coach' and public.lsa_session_akte_aktiv(session_id));

drop policy if exists lsa_skill_urteil_coach_admin_read on public.lsa_skill_urteil;
create policy lsa_skill_urteil_admin_read on public.lsa_skill_urteil
  for select using (public.get_my_role() = 'admin');
create policy lsa_skill_urteil_coach_select on public.lsa_skill_urteil
  for select using (public.get_my_role() = 'coach' and public.lsa_session_akte_aktiv(session_id));

drop policy if exists lsa_report_notes_coach_admin_all on public.lsa_report_notes;
create policy lsa_report_notes_admin_all on public.lsa_report_notes
  for all using (public.get_my_role() = 'admin') with check (public.get_my_role() = 'admin');
create policy lsa_report_notes_coach_select on public.lsa_report_notes
  for select using (public.get_my_role() = 'coach' and public.lsa_session_akte_aktiv(session_id));

-- Alte Eltern-Reports (parent_reports): Coach nur lesen, nur aktive Akte.
drop policy if exists parent_reports_coach_admin_all on public.parent_reports;
create policy parent_reports_admin_all on public.parent_reports
  for all using (public.get_my_role() = 'admin') with check (public.get_my_role() = 'admin');
create policy parent_reports_coach_select on public.parent_reports
  for select using (public.get_my_role() = 'coach' and public.akte_aktiv(student_id));

-- Lernpfad (student_focus_areas): Coach nur lesen, nur aktive Akte. Die
-- Uebernahme-Funktionen (lsa_uebernahme, lsa_confirm_focus) laufen als DEFINER.
drop policy if exists student_focus_areas_coach_all on public.student_focus_areas;
create policy student_focus_areas_admin_all on public.student_focus_areas
  for all using (public.get_my_role() = 'admin') with check (public.get_my_role() = 'admin');
create policy student_focus_areas_coach_select on public.student_focus_areas
  for select using (public.get_my_role() = 'coach' and public.akte_aktiv(student_id));

-- Fortschritt und XP.
drop policy if exists student_progress_coach_admin_read on public.student_progress;
create policy student_progress_admin_read on public.student_progress
  for select using (public.get_my_role() = 'admin');
create policy student_progress_coach_select on public.student_progress
  for select using (public.get_my_role() = 'coach' and public.akte_aktiv(student_id));

drop policy if exists student_task_progress_coach_admin_read on public.student_task_progress;
create policy student_task_progress_admin_read on public.student_task_progress
  for select using (public.get_my_role() = 'admin');
create policy student_task_progress_coach_select on public.student_task_progress
  for select using (public.get_my_role() = 'coach' and public.akte_aktiv(student_id));

drop policy if exists xp_events_coach_admin_read on public.xp_events;
create policy xp_events_admin_read on public.xp_events
  for select using (public.get_my_role() = 'admin');
create policy xp_events_coach_select on public.xp_events
  for select using (public.get_my_role() = 'coach' and public.akte_aktiv(student_id));

-- behavior_snapshots haengt am Nutzerkonto (user_id = profiles.id).
drop policy if exists coaches_admins_see_all_snapshots on public.behavior_snapshots;
create policy behavior_snapshots_admin_read on public.behavior_snapshots
  for select using (public.get_my_role() = 'admin');
create policy behavior_snapshots_coach_select on public.behavior_snapshots
  for select using (
    public.get_my_role() = 'coach'
    and exists (select 1 from public.students s
                 where s.profile_id = behavior_snapshots.user_id and public.akte_aktiv(s.id))
  );

-- Badges: Lesen fuer das Kind und Eltern unveraendert; Coach nur aktive Akte.
-- (Schreiben nur Admin seit 20261007100100.)
drop policy if exists student_badges_self_read on public.student_badges;
create policy student_badges_self_read on public.student_badges
  for select using (
    student_id in (select s.id from public.students s where s.profile_id = auth.uid())
    or public.get_my_role() = 'admin'
    or (public.get_my_role() = 'coach' and public.akte_aktiv(student_id))
    or exists (select 1 from public.parent_student ps
                where ps.student_id = student_badges.student_id and ps.parent_id = auth.uid())
  );
