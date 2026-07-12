-- Verifikation des P01-Datenvertrags GEGEN DIE LAUFENDE DB.
-- Read-only. Im Supabase SQL Editor ausfuehren (oder: psql "$DATABASE_URL" -f ...).
--
-- Beantwortet:
--   1. Ist der LSA-Pool gefuellt? (tasks.status = 'ready')
--   2. Haben die SECURITY-DEFINER-RPCs REVOKE EXECUTE FROM PUBLIC + search_path?
--   3./4. Schreiben lsa_submit/lsa_finish XP?

-- 1) LSA-Pool
select 'tasks_ready'              as pruefung, count(*)::text as wert from tasks where status = 'ready'
union all
select 'tasks_gesamt',            count(*)::text from tasks
union all
select 'tasks_ready_mit_loesung', count(*)::text
  from tasks t
  join task_solutions s on s.task_id = t.id
 where t.status = 'ready' and jsonb_array_length(s.correct_answers) > 0;

-- 2) SECURITY DEFINER / search_path / EXECUTE-Rechte
select p.proname                                          as funktion,
       p.prosecdef                                        as security_definer,
       coalesce(array_to_string(p.proconfig, ','), '-')   as proconfig,
       has_function_privilege('public', p.oid, 'EXECUTE') as public_darf_ausfuehren,
       coalesce(array_to_string(p.proacl, ' | '), 'NULL (= default: PUBLIC)') as acl
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public'
   and p.proname in ('lsa_start','lsa_submit','lsa_finish','lsa_hint','task_solution_upsert')
 order by p.proname;

-- 3)/4) Beruehren die LSA-RPCs die XP-Zone?
select p.proname,
       pg_get_functiondef(p.oid) ~* 'xp_events'        as nennt_xp_events,
       pg_get_functiondef(p.oid) ~* 'student_progress' as nennt_student_progress
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public' and p.proname in ('lsa_submit','lsa_finish')
 order by p.proname;
