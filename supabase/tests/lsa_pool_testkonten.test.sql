-- ============================================================================
-- F1 E2: LSA-Pool fuer Testkonten (Migration 20261011140200; Entscheidung Rasit 08.10.2026).
--   P1 echtes Kind: nur 'ready' (Thema ohne ready: Auswahl ohne Thema, weiter nur ready)
--   P2 Testkonto ohne Testlauf: Entwuerfe ohne pruef_ausschluss, die Session ist KEIN Testlauf
--   P3 Testkonto: Entwuerfe mit pruef_ausschluss kommen nie
--   P4 Testlauf wie bisher
--   P5 session_im_pool unveraendert (Session-Pool fuer Testkonten ohne Testlauf weiter nur 'ready')
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(11);

\ir session_a2_fixture.sql

-- Thema mit zwei Einstiegen, nur Entwuerfe: e1 mit Fertigkeit (kein pruef_ausschluss), e2 ohne skill_thema
-- (pruef_ausschluss 'ohne_fertigkeit'). Zweites Thema: ein ready und fuenf Entwuerfe.
insert into skills (skill_key, label, klasse_herkunft, fundament_tiefe) values
  ('zz_f1_e1', 'ZZ F1 Einstieg eins', 9, 3), ('zz_f1_e2', 'ZZ F1 Einstieg zwei', 9, 3), ('zz_f1_e3', 'ZZ F1 Einstieg drei', 9, 3);
insert into themen (thema_key, fach, klasse, stufe, label, sort) values
  ('zz_f1_entwurf', 'mathematik', 9, 'erste', 'ZZ F1 Entwurf', 9311), ('zz_f1_gemischt', 'mathematik', 9, 'erste', 'ZZ F1 Gemischt', 9312);
insert into thema_einstieg (thema_key, skill_key) values
  ('zz_f1_entwurf', 'zz_f1_e1'), ('zz_f1_entwurf', 'zz_f1_e2'), ('zz_f1_gemischt', 'zz_f1_e3');
insert into skill_thema (skill_key, thema_key) values ('zz_f1_e1', 'zz_f1_entwurf'), ('zz_f1_e3', 'zz_f1_gemischt');
select pg_temp.aufgaben('zz_f1_e1', 6, 'draft'), pg_temp.aufgaben('zz_f1_e2', 6, 'draft'),
       pg_temp.aufgaben('zz_f1_e3', 1, 'ready'), pg_temp.aufgaben('zz_f1_e3', 5, 'draft', '{lsa,session}', 'f1-e3-entwurf');
select is((select count(*) from tasks where skill_key = 'zz_f1_e2' and public.pruef_ausschluss(id) is not null), 6::bigint,
          'Vorbedingung: e2-Entwuerfe haben pruef_ausschluss');

create or replace function pg_temp.kind_thema(p_name text, p_test boolean, p_thema text) returns uuid language plpgsql as $$
declare v_k uuid := pg_temp.kind(p_name, p_test);
begin
  update students set class_level = 9 where id = v_k;
  insert into lead_themen (lead_id, fach, thema_key, status, quelle)
  select l.id, 'mathematik', p_thema, 'aktuell', 'gespraech' from leads l where l.converted_student_id = v_k;
  return v_k;
end $$;
-- Erstes ausgegebenes Item einer LSA.
create or replace function pg_temp.erstes(p_sess jsonb) returns uuid language sql as $$
  select task_id from lsa_ausgegeben where session_id = (p_sess ->> 'session_id')::uuid limit 1
$$;

select pg_temp.kind_thema('ZZ Echt F1', false, 'zz_f1_entwurf') as k_echt \gset
select pg_temp.kind_thema('ZZ Echt2 F1', false, 'zz_f1_gemischt') as k_echt2 \gset
select pg_temp.kind_thema('ZZ Test F1', true, 'zz_f1_entwurf') as k_test \gset
select pg_temp.kind_thema('ZZ Test2 F1', true, 'zz_f1_entwurf') as k_test2 \gset

select pg_temp.act_as(:'admin');

-- P1 echtes Kind
-- Thema nur mit Entwuerfen: die Auswahl laeuft ohne Thema weiter (alte Logik) und nimmt nur ready-Items.
select lsa_start(:'k_echt', 9, 'Mathematik', 'adaptiv') as l_echt \gset
select is((select t.status from tasks t where t.id = pg_temp.erstes(:'l_echt')), 'ready',
          'P1 echtes Kind, Thema nur mit Entwuerfen: kein Entwurf, nur ready (wie bisher)');
select lsa_start(:'k_echt2', 9, 'Mathematik', 'adaptiv') as l_echt2 \gset
select is((select status from tasks where id = pg_temp.erstes(:'l_echt2')), 'ready', 'P1 echtes Kind: das erste Item ist ready');

-- P2/P3 Testkonto ohne Testlauf
select lsa_start(:'k_test', 9, 'Mathematik', 'adaptiv') as l_test \gset
select is((:'l_test'::jsonb ->> 'testlauf')::boolean, false, 'P2 die LSA des Testkontos ist kein Testlauf');
select is((select testlauf from lsa_sessions where id = (:'l_test'::jsonb ->> 'session_id')::uuid), false, 'P2 lsa_sessions.testlauf = false');
select is((select t.skill_key || '/' || t.status from tasks t where t.id = pg_temp.erstes(:'l_test')), 'zz_f1_e1/draft',
          'P2 Testkonto bekommt einen Entwurf ohne pruef_ausschluss');
-- ein paar Antworten, damit die Auswahl mehrfach laeuft
do $$
declare v_s uuid := (select id from lsa_sessions where student_id = (select id from students s where exists
          (select 1 from leads l where l.converted_student_id = s.id and l.full_name = 'ZZ Test F1')) limit 1);
        v_t uuid; i int;
begin
  for i in 1 .. 4 loop
    select a.task_id into v_t from lsa_ausgegeben a where a.session_id = v_s
       and not exists (select 1 from lsa_responses r where r.session_id = v_s and r.task_id = a.task_id) limit 1;
    exit when v_t is null;
    perform public.lsa_submit(v_s, v_t, '{"text": "0"}'::jsonb);
  end loop;
end $$;
select ok((select count(*) from lsa_ausgegeben where session_id = (:'l_test'::jsonb ->> 'session_id')::uuid) >= 2,
          'P3 mehrere Items ausgegeben');
select is((select count(*) from lsa_ausgegeben a join tasks t on t.id = a.task_id
            where a.session_id = (:'l_test'::jsonb ->> 'session_id')::uuid and public.pruef_ausschluss(t.id) is not null),
          0::bigint, 'P3 nie ein Entwurf mit pruef_ausschluss');

-- P4 Testlauf wie bisher
select lsa_start(:'k_test2', 9, 'Mathematik', 'adaptiv', now(), true) as l_tl \gset
select is((select testlauf from lsa_sessions where id = (:'l_tl'::jsonb ->> 'session_id')::uuid), true, 'P4 Testlauf bleibt Testlauf');
select is((select t.skill_key || '/' || t.status from tasks t where t.id = pg_temp.erstes(:'l_tl')), 'zz_f1_e1/draft',
          'P4 Testlauf zieht wie bisher Entwuerfe ohne pruef_ausschluss');

-- P5 Session-Pool unveraendert
select is(public.session_im_pool((select id from tasks where skill_key = 'zz_f1_e1' limit 1), false), false,
          'P5 session_im_pool ohne Testlauf: kein Entwurf, auch nicht fuer Testkonten');

select * from finish();
rollback;
