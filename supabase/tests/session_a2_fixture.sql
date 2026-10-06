-- Fixtures fuer session_a2.test.sql (Session-Engine A2). Alles mit Praefix zz_a2 / ZZ A2.
--
-- Skill-Graph: v1, v2 (Voraussetzungen) -> s1 (Einstieg Thema "Terme") -> s2 (Thema "Terme");
-- v2 -> n1 (Einstieg "Lineare Funktionen", freigegebene Erklaersequenz); k2 -> k1 (Thema
-- "Quadratische Gleichungen", k2 Teil des Themas). Jede Aufgabe: richtig ist "7".

\set admin    'a2a2a2a2-0001-4000-8000-000000000001'
\set coach_a  'a2a2a2a2-0001-4000-8000-000000000002'
\set coach_b  'a2a2a2a2-0001-4000-8000-000000000003'
\set schueler 'a2a2a2a2-0001-4000-8000-000000000004'
\set ohne     'a2a2a2a2-0001-4000-8000-000000000005'

insert into auth.users (id, email, instance_id, aud, role)
select u, 'a2-' || n || '@test.local', '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated'
  from (values (:'admin'::uuid, 'admin'), (:'coach_a', 'coach-a'), (:'coach_b', 'coach-b'),
               (:'schueler', 'schueler'), (:'ohne', 'ohne-profil')) v(u, n)
union all
select ('a2a2a2a2-0002-4000-8000-00000000000' || i)::uuid, 'a2-tablet' || i || '@test.local',
       '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated'
  from generate_series(1, 6) i;

insert into profiles (id, email, role, full_name) values
  (:'admin', 'a2-admin@test.local', 'admin', 'A2 Admin'),
  (:'coach_a', 'a2-coach-a@test.local', 'coach', 'A2 Coach A'),
  (:'coach_b', 'a2-coach-b@test.local', 'coach', 'A2 Coach B'),
  (:'schueler', 'a2-schueler@test.local', 'student', 'A2 Schueler');
insert into profiles (id, email, role, full_name)
select ('a2a2a2a2-0002-4000-8000-00000000000' || i)::uuid, 'a2-tablet' || i || '@test.local', 'student', 'A2 Tablet ' || i
  from generate_series(1, 6) i;
insert into platz_devices (profile_id, label, tablet_nr)
select ('a2a2a2a2-0002-4000-8000-00000000000' || i)::uuid, 'ZZ A2 Tablet ' || i, i from generate_series(1, 6) i;

create or replace function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;
create or replace function pg_temp.als_system() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('role', 'service_role')::text, true);
end $$;
create or replace function pg_temp.tablet(i int) returns uuid language sql as $$
  select ('a2a2a2a2-0002-4000-8000-00000000000' || i)::uuid
$$;

-- Kind mit Lead und laufendem Vertrag; p_test = Testkonto.
create or replace function pg_temp.kind(p_name text, p_test boolean default false) returns uuid language plpgsql as $$
declare v_lead uuid; v_st uuid;
begin
  insert into leads (full_name, first_name, status, class_level, ist_test)
  values (p_name, split_part(p_name, ' ', 1), 'vertrag', 8, p_test) returning id into v_lead;
  insert into students (class_level, ist_test) values (8, p_test) returning id into v_st;
  update leads set converted_student_id = v_st where id = v_lead;
  insert into vertraege (lead_id, status, vertrag_status, abgeschlossen_at, abgeschlossen_am, abschluss_weg,
                         student_id, vertragsbeginn, vertrag_ende, widerruf_bis)
  values (v_lead, 'abgeschlossen', 'aktiv', now(), date_trunc('month', current_date)::date - 31, 'vor_ort', v_st,
          date_trunc('month', current_date - 31)::date,
          (date_trunc('month', current_date) + interval '7 month' - interval '1 day')::date, current_date - 16);
  return v_st;
end $$;

insert into skills (skill_key, label, klasse_herkunft, fundament_tiefe) values
  ('zz_a2_v1', 'ZZ Minus vor der Klammer', 7, 1),
  ('zz_a2_v2', 'ZZ Proportionale Zuordnung', 7, 1),
  ('zz_a2_s1', 'ZZ Klammern ausmultiplizieren', 8, 2),
  ('zz_a2_s2', 'ZZ Ausklammern', 8, 3),
  ('zz_a2_n1', 'ZZ Steigung', 8, 2),
  ('zz_a2_k1', 'ZZ p-q-Formel', 9, 2),
  ('zz_a2_k2', 'ZZ Binomische Formeln', 8, 1);
insert into skill_kante (skill_key, voraussetzt_skill_key) values
  ('zz_a2_s1', 'zz_a2_v1'), ('zz_a2_s1', 'zz_a2_v2'), ('zz_a2_s2', 'zz_a2_s1'),
  ('zz_a2_n1', 'zz_a2_v2'), ('zz_a2_k1', 'zz_a2_k2');
insert into themen (thema_key, fach, klasse, stufe, label, sort) values
  ('zz_a2_basis', 'mathematik', 7, 'erste', 'ZZ Grundlagen', 9201),
  ('zz_a2_terme', 'mathematik', 8, 'erste', 'ZZ Terme', 9202),
  ('zz_a2_linear', 'mathematik', 8, 'erste', 'ZZ Lineare Funktionen', 9203),
  ('zz_a2_quad', 'mathematik', 9, 'erste', 'ZZ Quadratische Gleichungen', 9204);
insert into thema_einstieg (thema_key, skill_key) values
  ('zz_a2_terme', 'zz_a2_s1'), ('zz_a2_linear', 'zz_a2_n1'), ('zz_a2_quad', 'zz_a2_k1');
insert into skill_thema (skill_key, thema_key) values
  ('zz_a2_v1', 'zz_a2_basis'), ('zz_a2_v2', 'zz_a2_basis'), ('zz_a2_s1', 'zz_a2_terme'), ('zz_a2_s2', 'zz_a2_terme'),
  ('zz_a2_n1', 'zz_a2_linear'), ('zz_a2_k1', 'zz_a2_quad'), ('zz_a2_k2', 'zz_a2_quad');

insert into skill_clusters (name, class_level_min, class_level_max) values ('ZZ A2 Cluster', 5, 13);

-- p_n Aufgaben je Skill, Schwierigkeit reihum 1..5, ready, Einsatz lsa+session, mit Loesungsweg
-- und einem gepruefen Hinweis Stufe 1.
create or replace function pg_temp.aufgaben(p_skill text, p_n int, p_status text default 'ready',
                                            p_einsatz text[] default '{lsa,session}', p_ref text default null)
returns void language plpgsql as $$
begin
  insert into tasks (cluster_id, content_type, input_type, status, question, question_payload, afb, competency_content,
                     est_duration_sec, class_level, curriculum_grade, source, source_ref, skill_key, difficulty, einsatz, is_active)
  select (select id from skill_clusters where name = 'ZZ A2 Cluster'), 'exercise', 'SHORT_TEXT', p_status, 'ZZ A2 ' || p_skill || ' Nr ' || i || ': Wie viel ist 3 + 4?',
         jsonb_build_object('input_type', 'SHORT_TEXT', 'kind', 'short_input', 'prompt', 'Wie viel ist 3 + 4?'),
         'I', 'Terme und Gleichungen', 60, 8, 8, 'test', coalesce(p_ref, 'a2-' || p_skill) || '-' || i,
         p_skill, ((i - 1) % 5) + 1, p_einsatz, true
    from generate_series(1, p_n) i;
  perform set_config('edvance.hinweis_status', 'setzen', true);
  insert into task_solutions (task_id, correct_answers, solution, hints, acceptance)
  select t.id, '["7"]', 'ZZ-LOESUNGSWEG: 3 + 4 = 7',
         '[{"level":1,"text":"ZZ Hinweis: Zaehle weiter.","status":"geprueft"}]', '{"canonical":"7"}'
    from tasks t where t.source = 'test' and t.source_ref like coalesce(p_ref, 'a2-' || p_skill) || '-%'
     and not exists (select 1 from task_solutions s where s.task_id = t.id);
  perform set_config('edvance.hinweis_status', '', true);
end $$;

select pg_temp.aufgaben('zz_a2_v1', 15), pg_temp.aufgaben('zz_a2_v2', 15), pg_temp.aufgaben('zz_a2_s1', 30),
       pg_temp.aufgaben('zz_a2_s2', 15), pg_temp.aufgaben('zz_a2_n1', 15), pg_temp.aufgaben('zz_a2_k1', 25),
       pg_temp.aufgaben('zz_a2_k2', 15);

-- Erklaersequenz fuer n1: eine Kernidee, Variante A, ein Check (Einsatz check), freigegeben.
select pg_temp.aufgaben('zz_a2_n1', 1, 'ready', '{check}', 'a2-check');
select pg_temp.act_as(:'admin');
select public.erklaer_kernidee_speichern(null, 'zz_a2_n1', 1, 'ZZ Steigung pro Schritt', 'mensch') as kern_n1 \gset
select public.erklaer_schritt_speichern(:'kern_n1', 'A', a.art, 'ZZ A2 Erklaerung ' || a.art, null, '{}')
  from (values ('erklaerung'), ('beispiel')) a(art);
select public.erklaer_check_setzen(:'kern_n1', (select id from tasks where source_ref = 'a2-check-1'), 1);
do $$
declare r record;
begin
  for r in select s.id, s.kernidee_id from erklaer_schritt s join erklaer_kernidee k on k.id = s.kernidee_id
            where k.skill_key = 'zz_a2_n1' loop
    perform public.erklaer_status_setzen('schritt', r.id, 'geprueft', (select pruef_version from erklaer_kernidee where id = r.kernidee_id));
    perform public.erklaer_status_setzen('schritt', r.id, 'freigegeben', (select pruef_version from erklaer_kernidee where id = r.kernidee_id));
  end loop;
  for r in select id from erklaer_kernidee where skill_key = 'zz_a2_n1' loop
    perform public.erklaer_status_setzen('kernidee', r.id, 'geprueft', (select pruef_version from erklaer_kernidee where id = r.id));
    perform public.erklaer_status_setzen('kernidee', r.id, 'freigegeben', (select pruef_version from erklaer_kernidee where id = r.id));
  end loop;
end $$;
select set_config('request.jwt.claims', '', true);

-- Eine fruehere Session fuer Belege (macht Skills "nicht neu").
insert into coaching_sessions (coach_id, room, scheduled_at) values (:'coach_a', 'ZZ A2 alt', now() - interval '7 days')
returning id as s_alt \gset

-- Session-Helfer: neue Session mit den Kindern auf Tablet 1..n, gestartet vor p_minuten.
create or replace function pg_temp.neue_session(p_kinder uuid[], p_minuten numeric default 0,
                                                p_testlauf boolean default false, p_coach uuid default null)
returns uuid language plpgsql as $$
declare v_s uuid; i int;
begin
  update session_tablets set geloest_am = clock_timestamp() where geloest_am is null;
  perform pg_temp.act_as('a2a2a2a2-0001-4000-8000-000000000001');
  insert into coaching_sessions (coach_id, room, scheduled_at)
  values (coalesce(p_coach, 'a2a2a2a2-0001-4000-8000-000000000002'), 'ZZ A2', now()) returning id into v_s;
  insert into session_students (session_id, student_id) select v_s, k from unnest(p_kinder) k;
  if p_testlauf then perform public.session_testlauf_setzen(v_s, true); end if;
  perform public.session_starten(v_s);
  for i in 1 .. cardinality(p_kinder) loop
    perform public.tablet_zuweisen(v_s, p_kinder[i], i);
  end loop;
  perform pg_temp.uhr(v_s, p_minuten);
  perform set_config('request.jwt.claims', '', true);
  return v_s;
end $$;

-- Uhr der Session: gestartet vor p_minuten (now() steht in der Transaktion still).
create or replace function pg_temp.uhr(p_s uuid, p_minuten numeric) returns void language plpgsql as $$
begin
  perform set_config('edvance.session_rpc', '1', true);
  update coaching_sessions set gestartet_am = now() - p_minuten * interval '1 minute' where id = p_s;
  perform set_config('edvance.session_rpc', '', true);
end $$;

create or replace function pg_temp.checkin(p_s uuid, p_tablet int, p_ka date default null, p_ka_thema text default null)
returns void language plpgsql as $$
begin
  perform pg_temp.act_as(pg_temp.tablet(p_tablet));
  perform public.checkin_kind_speichern(p_s, 'gut', p_ka, p_ka_thema, 'noch_dran');
end $$;

create or replace function pg_temp.schritt(p_s uuid, p_tablet int) returns jsonb language plpgsql as $$
begin
  perform pg_temp.act_as(pg_temp.tablet(p_tablet));
  return public.session_naechster_schritt(p_s, null);
end $$;

-- Antwort auf die offene Aufgabe des Tablets (richtig = "7"), optional nach Hinweis Stufe 1.
create or replace function pg_temp.antwort(p_s uuid, p_tablet int, p_richtig boolean, p_hinweis boolean default false)
returns jsonb language plpgsql as $$
declare v_task uuid;
begin
  perform pg_temp.act_as(pg_temp.tablet(p_tablet));
  select x.task_id into v_task from session_schritte x
    join session_tablets t on t.session_id = x.session_id and t.student_id = x.student_id
   where x.session_id = p_s and t.tablet_nr = p_tablet and t.geloest_am is null and x.art in ('aufgabe', 'exit')
   order by x.id desc limit 1;
  if p_hinweis then perform public.hinweis_abrufen(p_s, v_task, 1); end if;
  return public.antwort_abgeben(p_s, v_task, null, case when p_richtig then '"7"' else '"0"' end::jsonb);
end $$;

-- Schritt holen und, wenn es eine Aufgabe ist, beantworten.
create or replace function pg_temp.loese(p_s uuid, p_tablet int, p_richtig boolean, p_hinweis boolean default false)
returns jsonb language plpgsql as $$
declare v jsonb := pg_temp.schritt(p_s, p_tablet);
begin
  if v ->> 'art' in ('aufgabe', 'exit') then perform pg_temp.antwort(p_s, p_tablet, p_richtig, p_hinweis); end if;
  return v;
end $$;

-- Kind mit Schulthema, sicheren Skills (Lernpfad) und Belegen aus der frueheren Session.
create or replace function pg_temp.kind_mit(p_name text, p_thema text, p_sicher text[], p_alt text[] default '{}',
                                            p_test boolean default false) returns uuid language plpgsql as $$
declare v_k uuid := pg_temp.kind(p_name, p_test);
begin
  if p_thema is not null then
    insert into lead_themen (lead_id, fach, thema_key, status, quelle)
    select l.id, 'mathematik', p_thema, 'aktuell', 'gespraech' from leads l where l.converted_student_id = v_k;
  end if;
  insert into lernpfad (student_id, skill_key, stand_system, quelle, letzte_uebung_am)
  select v_k, sk, 'sicher', 'lsa', now() - interval '20 days' from unnest(p_sicher) sk;
  insert into lernpfad_belege (student_id, skill_key, session_id, ergebnis, hinweis_genutzt)
  select v_k, sk, (select id from coaching_sessions where room = 'ZZ A2 alt'), 'falsch', false from unnest(p_alt) sk;
  return v_k;
end $$;

-- Stellschraube als Admin setzen (wirkt auf Sessions, die danach starten).
create or replace function pg_temp.stell(p_schluessel text, p_wert jsonb) returns void language plpgsql as $$
begin
  perform pg_temp.act_as('a2a2a2a2-0001-4000-8000-000000000001');
  perform public.einstellung_setzen(p_schluessel, p_wert, 'A2-Test');
  perform set_config('request.jwt.claims', '', true);
end $$;

-- n Schritte vom Tablet, Aufgaben richtig (p_richtig) beantwortet; liefert die Schritte.
create or replace function pg_temp.lauf(p_s uuid, p_tablet int, p_n int, p_richtig boolean,
                                        p_hinweis boolean default false)
returns setof jsonb language plpgsql as $$
declare i int;
begin
  for i in 1 .. p_n loop
    return next pg_temp.loese(p_s, p_tablet, p_richtig, p_hinweis);
  end loop;
end $$;

-- Vorschau des Coaches A (bucht nichts).
create or replace function pg_temp.vorschau(p_s uuid, p_kind uuid) returns jsonb language plpgsql as $$
declare v jsonb;
begin
  perform pg_temp.act_as('a2a2a2a2-0001-4000-8000-000000000002');
  v := public.session_naechster_schritt(p_s, p_kind);
  perform set_config('request.jwt.claims', '', true);
  return v;
end $$;
