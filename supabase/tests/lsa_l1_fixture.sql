-- Fixtures fuer die L1-Tests des LSA-Erlebnisses (lsa_l1_*.test.sql). Alles mit Praefix zz_l1 / ZZ L1.
--
-- Laeuft auch gegen die Live-DB folgenlos: jeder Test steht in begin … rollback, eigene UUIDs
-- (b1e1b1e1-…), das Tablet ohne tablet_nr (die Nummern 1–5 sind live vergeben), keine Abhaengigkeit von
-- Seed oder Bestand. Alle Aufgaben haengen an einem eigenen Skill; die Auswahl wird ueber einen offenen
-- Zweitbeleg (lsa_skill_urteil.offen) auf diesen Skill gelenkt, damit sie deterministisch ist.

\set admin  'b1e1b1e1-0001-4000-8000-000000000001'
\set tablet 'b1e1b1e1-0002-4000-8000-000000000001'

insert into auth.users (id, email, instance_id, aud, role)
select u, 'l1-' || n || '@test.local', '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated'
  from (values (:'admin'::uuid, 'admin'), (:'tablet'::uuid, 'tablet')) v(u, n);
insert into profiles (id, email, role, full_name) values
  (:'admin', 'l1-admin@test.local', 'admin', 'ZZ L1 Admin'),
  (:'tablet', 'l1-tablet@test.local', 'student', 'ZZ L1 Tablet');
insert into platz_devices (profile_id, label, tablet_nr) values (:'tablet', 'ZZ L1 Tablet', null);

create or replace function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;

insert into skills (skill_key, label, klasse_herkunft, fundament_tiefe) values ('zz_l1_s1', 'ZZ L1 Bruchrechnen', 7, 1);
insert into skill_clusters (name, class_level_min, class_level_max) values ('ZZ L1 Cluster', 5, 13);

-- Lead ohne Vertrag mit provisorischem Schuelerdatensatz, wie ihn lead_lsa_freigeben anlegt
-- (Vorname = erstes Wort von p_name); liefert die students.id.
create or replace function pg_temp.l1_kind(p_name text) returns uuid language plpgsql as $$
declare v_lead uuid; v_st uuid;
begin
  insert into leads (full_name, first_name, status, class_level)
  values (p_name, split_part(p_name, ' ', 1), 'lsa_freigegeben', 8)
  returning id into v_lead;
  perform set_config('edvance.allow_provisional', '1', true);
  insert into students (class_level, lead_id, is_provisional) values (8, v_lead, true) returning id into v_st;
  perform set_config('edvance.allow_provisional', '', true);
  return v_st;
end $$;

-- Eine LSA-Aufgabe (ready, Einsatz lsa, Skill zz_l1_s1) samt Loesung; liefert die tasks.id.
create or replace function pg_temp.l1_aufgabe(p_ref text, p_input_type text, p_answers jsonb,
                                              p_parts jsonb default '[]', p_bruch boolean default null,
                                              p_acceptance jsonb default null)
returns uuid language plpgsql as $$
declare v_id uuid;
begin
  insert into tasks (cluster_id, content_type, input_type, status, question, question_payload, afb, competency_content,
                     est_duration_sec, class_level, curriculum_grade, source, source_ref, skill_key, difficulty, einsatz,
                     is_active, parts, bruch)
  values ((select id from skill_clusters where name = 'ZZ L1 Cluster'), 'exercise', p_input_type, 'ready',
          'ZZ L1 ' || p_ref || ': Wie viel ist das?',
          case when p_input_type = 'MC'
               then '{"input_type":"MC","options":[{"id":"a","label":"1/2"},{"id":"b","label":"3/4"}]}'::jsonb end,
          'I', 'Zahlen und Operationen', 60, 8, 8, 'test', 'l1-' || p_ref, 'zz_l1_s1', 1, '{lsa}', true,
          coalesce(p_parts, '[]'::jsonb), p_bruch)
  returning id into v_id;
  insert into task_solutions (task_id, correct_answers, solution, acceptance)
  values (v_id, p_answers, 'ZZ-LOESUNGSWEG', p_acceptance);
  return v_id;
end $$;

-- Laufende adaptive LSA des Kindes, begonnen um p_start; mit offenem Zweitbeleg auf zz_l1_s1, damit
-- lsa_select_next_core (Schritt 2) eine Aufgabe dieses Skills zieht, solange das Zeitfenster offen ist.
create or replace function pg_temp.l1_session(p_kind uuid, p_start timestamptz default now()) returns uuid
language plpgsql as $$
declare v_s uuid;
begin
  insert into lsa_sessions (student_id, subject, grade, item_ids, started_at, status, modus)
  values (p_kind, 'Mathematik', 8, '{}', p_start, 'in_progress', 'adaptiv') returning id into v_s;
  insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl)
  values (v_s, 'zz_l1_s1', 'traegt_nicht', true, true, 1);
  return v_s;
end $$;

-- Aufgabe als ausgegeben eintragen (wie lsa_start/lsa_submit) und als Admin abgeben.
create or replace function pg_temp.l1_abgabe(p_s uuid, p_task uuid, p_response jsonb) returns void
language plpgsql as $$
begin
  insert into lsa_ausgegeben (session_id, task_id) values (p_s, p_task) on conflict do nothing;
  perform pg_temp.act_as('b1e1b1e1-0001-4000-8000-000000000001');
  perform public.lsa_submit(p_s, p_task, p_response);
end $$;

-- correct bzw. abgabeart einer Antwortzeile (Teil: p_teil, flach: null).
create or replace function pg_temp.l1_zeile(p_s uuid, p_task uuid, p_teil int default null) returns text
language sql as $$
  select r.abgabeart || '/' || coalesce(r.correct::text, '-')
    from lsa_responses r
   where r.session_id = p_s and r.task_id = p_task and r.part_nr is not distinct from p_teil
$$;
