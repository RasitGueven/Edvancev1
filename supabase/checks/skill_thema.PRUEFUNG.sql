-- PRUEFUNG zu W4 (skill_thema + freigabe_thema).
--
--   psql "postgresql:///edvance_neuaufbau" -v ON_ERROR_STOP=1 \
--        -f supabase/checks/skill_thema.PRUEFUNG.sql
--
-- Laeuft gegen eine leere Neuaufbau-Datenbank (alle Migrationen): legt Fach,
-- Cluster, Profile und Aufgaben selbst an. Die Aufgaben haengen an Skills, die
-- die Datenmigration dem Thema 'kreis' bzw. 'lineare_funktionen' zuordnet.
-- Alles in begin/rollback.
--
--   T1  skill_thema: jeder Skill ausser potenzen hat genau ein Heimat-Thema
--   T2  freigabe_thema('kreis', 8): nur class_level <= 8 oder leer
--   T3  freigabe_thema('kreis', 9): der Rest; VERA8, fremdes Thema und ein
--       vom Gate abgelehntes Item bleiben 'review'
--   T4  freigabe_thema als coach: 42501
--   T5  RLS: coach liest skill_thema, student nicht

begin;

do $$
declare
  v_admin   uuid := gen_random_uuid();
  v_coach   uuid := gen_random_uuid();
  v_student uuid := gen_random_uuid();
  v_subj    uuid := gen_random_uuid();
  v_cl      uuid := gen_random_uuid();
  v_k9      uuid := gen_random_uuid();
  v_k8      uuid := gen_random_uuid();
  v_leer    uuid := gen_random_uuid();
  v_vera    uuid := gen_random_uuid();
  v_linear  uuid := gen_random_uuid();
  v_luecke  uuid := gen_random_uuid();
  v_n       integer;
  v_ohne    text;
begin
  -- ══ T1: Abdeckung ═════════════════════════════════════════════════════════

  select string_agg(s.skill_key, ',' order by s.skill_key) into v_ohne
    from public.skills s
    left join public.skill_thema st on st.skill_key = s.skill_key
   where st.skill_key is null;
  if v_ohne is distinct from 'potenzen' then
    raise exception 'T1: ohne Heimat-Thema: %, erwartet nur potenzen', coalesce(v_ohne, '<keiner>');
  end if;
  raise notice 'T1 ok: alle Skills ausser potenzen zugeordnet';

  -- ══ Testdaten ═════════════════════════════════════════════════════════════

  insert into auth.users (id, email) values
    (v_admin, 'w4-admin@edvance.test'),
    (v_coach, 'w4-coach@edvance.test'),
    (v_student, 'w4-student@edvance.test');
  insert into public.profiles (id, email, role) values
    (v_admin, 'w4-admin@edvance.test', 'admin'),
    (v_coach, 'w4-coach@edvance.test', 'coach'),
    (v_student, 'w4-student@edvance.test', 'student');

  insert into public.subjects (id, name) values (v_subj, 'W4 Mathe');
  insert into public.skill_clusters (id, subject_id, name, class_level_min, class_level_max)
    values (v_cl, v_subj, 'W4 Cluster', 5, 10);

  -- Vollstaendige Items, direkt auf 'review' (als Owner, am Gate vorbei).
  insert into public.tasks (id, content_type, skill_key, question, input_type, afb,
                            cluster_id, curriculum_grade, class_level, status, source)
  values
    (v_k9,     'exercise', 'geo_kreis_umfang',    'W4 k9',     'NUMERIC', 'I', v_cl, 9, 9,    'review', 'w4_test'),
    (v_k8,     'exercise', 'geo_kreis_flaeche',   'W4 k8',     'NUMERIC', 'I', v_cl, 9, 8,    'review', 'w4_test'),
    (v_leer,   'exercise', 'geo_kreis_rueck',     'W4 leer',   'NUMERIC', 'I', v_cl, 9, null, 'review', 'w4_test'),
    (v_vera,   'exercise', 'geo_kreis_sektor',    'W4 vera',   'NUMERIC', 'I', v_cl, 9, 8,    'review', 'VERA8_IQB'),
    (v_linear, 'exercise', 'fkt_linear_steigung', 'W4 linear', 'NUMERIC', 'I', v_cl, 8, 8,    'review', 'w4_test'),
    (v_luecke, 'exercise', 'geo_kreis_umfang',    'W4 luecke', 'NUMERIC', 'I', v_cl, 9, 9,    'review', 'w4_test');
  insert into public.task_solutions (task_id, correct_answers)
  select id, '["7"]'::jsonb
    from unnest(array[v_k9, v_k8, v_leer, v_vera, v_linear]) as id;
  -- v_luecke hat keine Loesung: das Gate lehnt ab (P0001), es bleibt 'review'.

  -- ══ T2/T3: freigabe_thema als admin ═══════════════════════════════════════

  perform set_config('request.jwt.claim.sub', v_admin::text, true);

  v_n := public.freigabe_thema('kreis', 8);
  if v_n <> 2 then
    raise exception 'T2: Klasse 8 gab % frei, erwartet 2', v_n;
  end if;
  if (select status from public.tasks where id = v_k9) <> 'review' then
    raise exception 'T2: class_level 9 wurde in Klasse 8 freigegeben';
  end if;
  raise notice 'T2 ok: Klasse 8 gibt class_level 8 und leer frei';

  v_n := public.freigabe_thema('kreis', 9);
  if v_n <> 1 then
    raise exception 'T3: Klasse 9 gab % frei, erwartet 1', v_n;
  end if;
  if exists (select 1 from public.tasks
              where id in (v_vera, v_linear, v_luecke) and status <> 'review') then
    raise exception 'T3: VERA8, fremdes Thema oder Gate-Ausfall wurde freigegeben';
  end if;
  if (select status from public.tasks where id = v_k9) <> 'ready' then
    raise exception 'T3: class_level 9 nicht freigegeben';
  end if;
  raise notice 'T3 ok: VERA8, fremdes Thema und Gate-Ausfall bleiben review';

  -- ══ T4: coach darf nicht freigeben ════════════════════════════════════════

  perform set_config('request.jwt.claim.sub', v_coach::text, true);
  begin
    perform public.freigabe_thema('kreis', 9);
    raise exception 'T4: coach konnte freigeben';
  exception
    when sqlstate '42501' then null;
  end;
  raise notice 'T4 ok: coach -> 42501';

  -- Fuer T5: profiles ist unter RLS nicht lesbar, die IDs reisen per GUC mit.
  perform set_config('w4.coach', v_coach::text, true);
  perform set_config('w4.student', v_student::text, true);
end $$;

-- ══ T5: RLS ══════════════════════════════════════════════════════════════════

set local role authenticated;

select set_config('request.jwt.claim.sub', current_setting('w4.coach'), true);
do $$
begin
  if (select count(*) from public.skill_thema) = 0 then
    raise exception 'T5: coach sieht skill_thema nicht';
  end if;
end $$;

select set_config('request.jwt.claim.sub', current_setting('w4.student'), true);
do $$
begin
  if (select count(*) from public.skill_thema) <> 0 then
    raise exception 'T5: student sieht skill_thema';
  end if;
  raise notice 'T5 ok: coach liest, student nicht';
end $$;

rollback;
