-- Q10 · Abschnitt 3d: Was hängt an den nicht notwendigen LSA-Aufgaben (je Variante)? Aufgaben mit mindestens einem Verweis je
--       Tabelle (alle Tabellen mit FK auf tasks plus lsa_sessions.item_ids) und Zahl der Zeilen; gezeigt = lsa_ausgegeben,
--       lsa_responses oder session_ausgegeben, getrennt nach echten Kindern und Testdaten (students.ist_test, lsa_sessions.testlauf)
-- braucht: msa_basis.sql soll.sql
\set QUIET on
, nn as (select v.n, l.id from var v cross join lt l where not exists (select 1 from notwendig w where w.n = v.n and w.id = l.id)),
gez as (                  -- je gezeigter Aufgabe: echtes Kind ja/nein
  select a.task_id id, not (coalesce(st.ist_test, false) or coalesce(s.testlauf, false)) echt
    from lsa_ausgegeben a join lsa_sessions s on s.id = a.session_id left join students st on st.id = s.student_id
  union all
  select r.task_id, not (coalesce(st.ist_test, false) or coalesce(s.testlauf, false))
    from lsa_responses r join lsa_sessions s on s.id = r.session_id left join students st on st.id = s.student_id
  union all
  select g.task_id, not coalesce(st.ist_test, false)
    from session_ausgegeben g left join students st on st.id = g.student_id)
select nn.n,
       count(*) nicht_notwendig,
       count(*) filter (where exists (select 1 from lsa_responses x where x.task_id = nn.id)) lsa_antworten,
       (select count(*) from lsa_responses x where x.task_id in (select id from nn n2 where n2.n = nn.n)) lsa_antworten_zeilen,
       count(*) filter (where exists (select 1 from lsa_ausgegeben x where x.task_id = nn.id)) lsa_ausgegeben,
       count(*) filter (where exists (select 1 from lsa_sessions x where nn.id = any (x.item_ids))) in_sitzung_item_ids,
       count(*) filter (where exists (select 1 from session_ausgegeben x where x.task_id = nn.id)) session_ausgegeben,
       count(*) filter (where exists (select 1 from session_antworten x where x.task_id = nn.id)) session_antworten,
       count(*) filter (where exists (select 1 from task_pruefungen x where x.task_id = nn.id)) task_pruefungen,
       count(*) filter (where exists (select 1 from task_figures x where x.task_id = nn.id)) figuren,
       count(*) filter (where exists (select 1 from task_figur_optionen x where x.task_id = nn.id)) figur_optionen,
       count(*) filter (where exists (select 1 from task_solutions x where x.task_id = nn.id
                                      and jsonb_typeof(x.acceptance -> 'known_errors') = 'object'
                                      and x.acceptance -> 'known_errors' <> '{}'::jsonb)) mit_fehlbildern,
       count(*) filter (where exists (select 1 from quest_aufgaben x where x.task_id = nn.id)) quest_aufgaben,
       count(*) filter (where exists (select 1 from behavior_snapshots x where x.task_id = nn.id)) behavior_snapshots,
       count(*) filter (where exists (select 1 from student_task_progress x where x.task_id = nn.id)) task_progress,
       count(*) filter (where exists (select 1 from xp_events x where x.task_id = nn.id)) xp_events,
       count(*) filter (where exists (select 1 from aufgabe_gesehen x where x.task_id = nn.id)) aufgabe_gesehen,
       count(*) filter (where exists (select 1 from aufgabe_meldungen x where x.task_id = nn.id)) aufgabe_meldungen,
       count(*) filter (where exists (select 1 from aufgabe_bewaehrung x where x.task_id = nn.id)) aufgabe_bewaehrung,
       count(*) filter (where exists (select 1 from task_admin_protokoll x where x.task_id = nn.id)) admin_protokoll,
       count(*) filter (where exists (select 1 from task_reviews x where x.task_id = nn.id)) task_reviews,
       count(*) filter (where exists (select 1 from task_pruef_ausschluss x where x.task_id = nn.id)) pruef_ausschluss,
       count(*) filter (where exists (select 1 from task_pruefung_ausgang x where x.task_id = nn.id)) pruefung_ausgang,
       count(*) filter (where exists (select 1 from task_coach_metadata x where x.task_id = nn.id)) coach_metadata,
       count(*) filter (where exists (select 1 from erklaer_check x where x.task_id = nn.id)
                           or exists (select 1 from erklaer_fortschritt x where x.check_task_id = nn.id)
                           or exists (select 1 from studio_minicheck_aufgabe x where x.task_id = nn.id)) erklaer_studio,
       count(*) filter (where exists (select 1 from session_schritte x where x.task_id = nn.id)
                           or exists (select 1 from bauform_kommentare x where x.task_id = nn.id)) session_bauform,
       count(*) filter (where exists (select 1 from gez g where g.id = nn.id and g.echt)) einem_echten_kind_gezeigt,
       count(*) filter (where exists (select 1 from gez g where g.id = nn.id)
                           and not exists (select 1 from gez g where g.id = nn.id and g.echt)) nur_testdaten_gezeigt
  from nn group by 1 order by 1;
