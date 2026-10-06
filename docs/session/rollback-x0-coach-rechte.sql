-- Rollback zu 20261007100600_x0_coach_rechte.sql — stellt die Coach-Policies und
-- lsa_may_act_for auf den Stand vor X0 zurueck (pg_policies, dbread 06.10.2026).
-- NUR auf Anweisung von Rasit, nach CLAUDE.md §10 einspielen.

create or replace function public.lsa_may_act_for(p_student_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select public.get_my_role() in ('coach','admin')
      or public.get_my_student_id() = p_student_id
$$;

drop policy if exists lsa_sessions_admin_all on public.lsa_sessions;
drop policy if exists lsa_sessions_coach_select on public.lsa_sessions;
create policy lsa_sessions_coach_admin_all on public.lsa_sessions for all
  using (get_my_role() = any (array['coach','admin'])) with check (get_my_role() = any (array['coach','admin']));

drop policy if exists lsa_responses_admin_read on public.lsa_responses;
drop policy if exists lsa_responses_coach_select on public.lsa_responses;
create policy lsa_responses_coach_admin_read on public.lsa_responses for select
  using (get_my_role() = any (array['coach','admin']));

drop policy if exists lsa_ausgegeben_admin_read on public.lsa_ausgegeben;
drop policy if exists lsa_ausgegeben_coach_select on public.lsa_ausgegeben;
create policy lsa_ausgegeben_coach_admin_read on public.lsa_ausgegeben for select
  using (get_my_role() = any (array['coach','admin']));

drop policy if exists lsa_skill_urteil_admin_read on public.lsa_skill_urteil;
drop policy if exists lsa_skill_urteil_coach_select on public.lsa_skill_urteil;
create policy lsa_skill_urteil_coach_admin_read on public.lsa_skill_urteil for select
  using (get_my_role() = any (array['coach','admin']));

drop policy if exists lsa_report_notes_admin_all on public.lsa_report_notes;
drop policy if exists lsa_report_notes_coach_select on public.lsa_report_notes;
create policy lsa_report_notes_coach_admin_all on public.lsa_report_notes for all
  using (get_my_role() = any (array['coach','admin'])) with check (get_my_role() = any (array['coach','admin']));

drop policy if exists parent_reports_admin_all on public.parent_reports;
drop policy if exists parent_reports_coach_select on public.parent_reports;
create policy parent_reports_coach_admin_all on public.parent_reports for all
  using (get_my_role() = any (array['coach','admin'])) with check (get_my_role() = any (array['coach','admin']));

drop policy if exists student_focus_areas_admin_all on public.student_focus_areas;
drop policy if exists student_focus_areas_coach_select on public.student_focus_areas;
create policy student_focus_areas_coach_all on public.student_focus_areas for all
  using (get_my_role() = any (array['coach','admin'])) with check (get_my_role() = any (array['coach','admin']));

drop policy if exists student_progress_admin_read on public.student_progress;
drop policy if exists student_progress_coach_select on public.student_progress;
create policy student_progress_coach_admin_read on public.student_progress for select
  using (get_my_role() = any (array['coach','admin']));

drop policy if exists student_task_progress_admin_read on public.student_task_progress;
drop policy if exists student_task_progress_coach_select on public.student_task_progress;
create policy student_task_progress_coach_admin_read on public.student_task_progress for select
  using (get_my_role() = any (array['coach','admin']));

drop policy if exists xp_events_admin_read on public.xp_events;
drop policy if exists xp_events_coach_select on public.xp_events;
create policy xp_events_coach_admin_read on public.xp_events for select
  using (get_my_role() = any (array['coach','admin']));

drop policy if exists behavior_snapshots_admin_read on public.behavior_snapshots;
drop policy if exists behavior_snapshots_coach_select on public.behavior_snapshots;
create policy coaches_admins_see_all_snapshots on public.behavior_snapshots for select
  using (get_my_role() = any (array['coach','admin']));

drop policy if exists student_badges_self_read on public.student_badges;
create policy student_badges_self_read on public.student_badges for select using (
  student_id in (select students.id from students where students.profile_id = auth.uid())
  or get_my_role() = any (array['coach','admin'])
  or exists (select 1 from parent_student ps where ps.student_id = student_badges.student_id and ps.parent_id = auth.uid()));

drop function if exists public.lsa_session_akte_aktiv(uuid);
