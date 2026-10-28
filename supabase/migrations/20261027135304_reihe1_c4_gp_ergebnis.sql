-- Reihe 1 · C4 Coach-Sicht: Generalprobe-Ergebnis je Skill für Kind-Detail und Live-Kachel (Bauauftrag C4.1).
-- Gleiche Regel wie gp_ergebnis am Tablet (session_plan_gp, 20261027133413): sicher = jede Generalprobe-Aufgabe des
-- Skills beim ersten Versuch ohne Hinweis richtig. Bis zum Ergebnis am Tablet: sicher = null, offen = true.
-- Nur Coach der Session oder Admin. Leer ohne Generalprobe.
-- Rollback: supabase/rollback/20261027135304_reihe1_c4_gp_ergebnis.sql.

create function public.session_gp_ergebnis(p_session_id uuid, p_student_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_fertig boolean := exists (select 1 from public.session_schritte s where s.session_id = p_session_id
                               and s.student_id = p_student_id and s.art = 'gp_ergebnis');
begin
  perform public.session_coach_pruefen(p_session_id, 'session_gp_ergebnis');
  return coalesce((
    -- Zweitprüfung C4-3: „sicher / noch üben“ erst, wenn das Tablet das Ergebnis zeigt (gp_ergebnis), vorher null.
    select jsonb_agg(jsonb_build_object('skill_key', x.skill_key, 'label', public.session_label(x.skill_key),
                                        'sicher', case when v_fertig then x.sicher end, 'offen', not v_fertig) order by x.erst)
      from (select s.skill_key, min(s.id) as erst,
                   bool_and(coalesce((public.session_aufgabe_stand(p_session_id, p_student_id, s.task_id)).erfolg, false)) as sicher
              from public.session_schritte s
             where s.session_id = p_session_id and s.student_id = p_student_id and s.art = 'generalprobe'
             group by s.skill_key) x), '[]'::jsonb);
end;
$$;

revoke all on function public.session_gp_ergebnis(uuid, uuid) from public, anon;
grant execute on function public.session_gp_ergebnis(uuid, uuid) to authenticated;
comment on function public.session_gp_ergebnis(uuid, uuid) is
  'Reihe 1 C4: Generalprobe je Skill (sicher, offen) für den Coach der Session oder Admin.';
