-- ============================================================================
-- P2 · Sollzahlen je Knoten (Migrationen 20261014150200 pruef_soll, 20261014150300 pruef_board_soll).
-- Rechte der Tabelle und der Funktion, Zählregel (review/ready, ohne MC), doppelter Anlass.
-- Eigene Fixtures (Quelle 'p2_test', Knoten geo_kreis_umfang mit eigenen Anlässen), am Ende rollback.
--
-- Lauf: npx supabase test db
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(30);

-- --- Fixtures --------------------------------------------------------------
\set admin_uid   '2c100000-0000-4000-8000-00000000000a'
\set lena_uid    '2c100000-0000-4000-8000-00000000000b'
\set coach_uid   '2c100000-0000-4000-8000-00000000000c'
\set student_uid '2c100000-0000-4000-8000-00000000000d'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid',   'p2-admin@test.local',   '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'lena_uid',    'p2-lena@test.local',    '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach_uid',   'p2-coach@test.local',   '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'student_uid', 'p2-student@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name, darf_pruefen) values
  (:'admin_uid',   'p2-admin@test.local',   'admin',   'P2 Admin',   false),
  (:'lena_uid',    'p2-lena@test.local',    'coach',   'P2 Lena',    true),
  (:'coach_uid',   'p2-coach@test.local',   'coach',   'P2 Coach',   false),
  (:'student_uid', 'p2-student@test.local', 'student', 'P2 Schueler', false);
-- Der Pilot laeuft wie in Prod: das Board zeigt nur markierte Aufgaben.
update pruef_einstellungen set nur_pilot = true;
-- P4 (20261025210952) gibt geo_kreis_umfang ein batu_lsa-Soll; der Test braucht den Knoten ohne Soll.
delete from pruef_soll where skill_key = 'geo_kreis_umfang';

-- Eine vollstaendige Kreis-Aufgabe (wie admin_pruefansicht), im Pilot, mit Status und Eingabetyp.
create function pg_temp.aufgabe(p_ref text, p_status text, p_typ text default 'MC')
returns uuid language plpgsql as $$
declare v uuid;
begin
  insert into tasks (content_type, input_type, title, question, afb, cluster_id, curriculum_grade,
                     skill_key, sondierrang, source, source_ref, status, pruef_pilot)
  values ('exercise', 'NUMERIC', 'AFB II · ' || p_ref, 'Ein Kreis hat den Radius 3,6 m. Wie groß ist sein Umfang?',
          'II', (select id from skill_clusters order by id limit 1), 9, 'geo_kreis_umfang', 3,
          'p2_test', p_ref, p_status, true)
  returning id into v;
  insert into task_solutions (task_id, correct_answers, acceptance, solution)
  values (v, '["22,62", "22.62"]', '{"canonical": "22,62", "equivalents": ["22.62"]}', 'U = 2 · π · 3,6 m ≈ 22,62 m');
  -- Der Eingabetyp zaehlt nur fuer "ohne Multiple Choice"; die Fixture braucht keine echten Optionen.
  update tasks set input_type = p_typ where id = v;
  return v;
end $$;

create function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;
create function pg_temp.fehler(p_sql text) returns text language plpgsql as $$
declare s text;
begin
  execute p_sql;
  return 'kein Fehler';
exception when others then
  get stacked diagnostics s = returned_sqlstate;
  return s;
end $$;
create function pg_temp.zeilen(p_sql text) returns bigint language plpgsql as $$
declare n bigint;
begin
  execute p_sql;
  get diagnostics n = row_count;
  return n;
end $$;

-- Soll fuer den Fixture-Knoten: soll 3, mindestens 1 ohne MC.
insert into pruef_soll (skill_key, anlass, soll, min_ohne_mc, sort) values ('geo_kreis_umfang', 'p2_test', 3, 1, 900);

select pg_temp.aufgabe('p2-a', 'review') as a \gset
select pg_temp.aufgabe('p2-b', 'review') as b \gset
select pg_temp.aufgabe('p2-c', 'ready') as c \gset
select pg_temp.aufgabe('p2-d', 'beanstandet') as d \gset
select pg_temp.aufgabe('p2-e', 'rueckfrage') as e \gset
select pg_temp.aufgabe('p2-f', 'draft') as f \gset

-- ============================================================================
-- 2 · pruef_soll: Pruefrolle liest, schreibt nicht; admin schreibt; ohne Pruefrecht und anon nichts
-- ============================================================================
set local role authenticated;

select pg_temp.act_as(:'lena_uid');
select ok((select count(*) from pruef_soll where anlass = 'p2_test') = 1, '2: Lena (Pruefrecht) liest pruef_soll');
select is(pg_temp.fehler($$insert into pruef_soll (skill_key, anlass, soll, sort) values ('geo_kreis_umfang', 'lena', 1, 1)$$),
  '42501', '2: Lena → insert verweigert (RLS)');
select is(pg_temp.zeilen($$update pruef_soll set soll = 1 where anlass = 'p2_test'$$), 0::bigint,
  '2: Lena → update trifft 0 Zeilen');
select is(pg_temp.zeilen($$delete from pruef_soll where anlass = 'p2_test'$$), 0::bigint,
  '2: Lena → delete trifft 0 Zeilen');

select pg_temp.act_as(:'coach_uid');
select is((select count(*) from pruef_soll), 0::bigint, '2: Coach ohne Pruefrecht sieht nichts');
select pg_temp.act_as(:'student_uid');
select is((select count(*) from pruef_soll), 0::bigint, '2: Schueler sieht nichts');
select is(pg_temp.fehler($$insert into pruef_soll (skill_key, anlass, soll, sort) values ('geo_kreis_umfang', 'kind', 1, 1)$$),
  '42501', '2: Schueler → insert verweigert');

select pg_temp.act_as(:'admin_uid');
select is(pg_temp.zeilen($$insert into pruef_soll (skill_key, anlass, soll, min_ohne_mc, sort)
                            values ('geo_kreis_umfang', 'p2_admin', 1, 0, 950)$$), 1::bigint, '2: admin → insert');
select is(pg_temp.zeilen($$update pruef_soll set soll = 2 where anlass = 'p2_admin'$$), 1::bigint, '2: admin → update');
select is(pg_temp.zeilen($$delete from pruef_soll where anlass = 'p2_admin'$$), 1::bigint, '2: admin → delete');
select is(pg_temp.fehler($$insert into pruef_soll (skill_key, anlass, soll, min_ohne_mc, sort)
                           values ('geo_kreis_umfang', 'p2_admin', 1, 2, 950)$$),
  '23514', '2: admin → min_ohne_mc > soll verletzt den Check');
reset role;

set local role anon;
select is(pg_temp.fehler('select count(*) from public.pruef_soll'), '42501', '2: anon → pruef_soll verweigert');
select is(pg_temp.fehler('select count(*) from public.pruef_board_soll()'), '42501', '2: anon → pruef_board_soll verweigert');
reset role;

set local role authenticated;
select pg_temp.act_as(:'coach_uid');
select is(pg_temp.fehler('select count(*) from public.pruef_board_soll()'), '42501',
  '2: Coach ohne Pruefrecht → pruef_board_soll 42501');
select pg_temp.act_as(:'student_uid');
select is(pg_temp.fehler('select count(*) from public.pruef_board_soll()'), '42501', '2: Schueler → pruef_board_soll 42501');
reset role;

-- ============================================================================
-- 3 · Rechnung: soll 3, zwei review + eine ready, alle MC → gezaehlt 3, reicht nein; eine NUMERIC → reicht ja
-- ============================================================================
create function pg_temp.knoten()
returns table (im_board int, gezaehlt int, gezaehlt_ohne_mc int, rest int, reicht boolean, soll int,
               anlaesse text[], sort int)
language sql as $$
  select k.im_board, k.gezaehlt, k.gezaehlt_ohne_mc, k.rest, k.reicht, k.soll, k.anlaesse, k.sort
    from public.pruef_board_soll() k where k.skill_key = 'geo_kreis_umfang'
$$;

set local role authenticated;
select pg_temp.act_as(:'lena_uid');
select is((select im_board from pg_temp.knoten()), 6, '3: alle sechs Fixture-Aufgaben im Board');
select is((select gezaehlt from pg_temp.knoten()), 3, '3: review + review + ready = 3 (beanstandet, rueckfrage, draft nicht)');
select is((select gezaehlt_ohne_mc from pg_temp.knoten()), 0, '3: alle MC → 0 ohne MC');
select is((select reicht from pg_temp.knoten()), false, '3: soll erreicht, aber min_ohne_mc 1 offen → reicht nein');
select is((select rest from pg_temp.knoten()), 1, '3: Rest 1 (eine Aufgabe ohne MC fehlt)');
reset role;

update tasks set input_type = 'NUMERIC' where id = :'b';
set local role authenticated;
select pg_temp.act_as(:'lena_uid');
select is((select gezaehlt_ohne_mc from pg_temp.knoten()), 1, '3: eine NUMERIC → 1 ohne MC');
select is((select reicht from pg_temp.knoten()), true, '3: eine NUMERIC → reicht ja');
select is((select rest from pg_temp.knoten()), 0, '3: Rest 0');
reset role;

-- beanstandet zaehlt nicht: die ready-Aufgabe wird beanstandet → nur noch 2.
update tasks set status = 'beanstandet' where id = :'c';
set local role authenticated;
select pg_temp.act_as(:'lena_uid');
select is((select gezaehlt from pg_temp.knoten()), 2, '3: beanstandet zaehlt nicht');
select is((select reicht from pg_temp.knoten()), false, '3: dann reicht nein');
reset role;

-- ============================================================================
-- 4 · Doppelter Anlass: der hoehere Sollwert zaehlt; inaktive Anlaesse zaehlen nicht
-- ============================================================================
insert into pruef_soll (skill_key, anlass, soll, min_ohne_mc, sort) values ('geo_kreis_umfang', 'p2_zwei', 5, 0, 800);
set local role authenticated;
select pg_temp.act_as(:'lena_uid');
select is((select soll from pg_temp.knoten()), 5, '4: zwei aktive Anlaesse → hoeherer Sollwert 5');
select is((select array_to_string(anlaesse, ',') || ' ' || sort from pg_temp.knoten()), 'p2_zwei,p2_test 800',
  '4: beide Anlaesse, sort = kleinster Wert');
reset role;
update pruef_soll set aktiv = false where anlass = 'p2_zwei';
set local role authenticated;
select pg_temp.act_as(:'lena_uid');
select is((select soll from pg_temp.knoten()), 3, '4: Anlass inaktiv → wieder 3');
reset role;

-- Der echte Fall aus der Migration, wo die Knoten im Neuaufbau existieren: vorzeichen_add_sub 7 statt 3.
select is((select max(soll) from pruef_soll where skill_key = 'vorzeichen_add_sub' and aktiv),
          (select max(soll) from pruef_soll where skill_key = 'vorzeichen_add_sub' and anlass = 'batu_session'),
  '4: vorzeichen_add_sub: batu_session liefert den Hoechstwert');
select ok((select count(*) from pruef_soll where skill_key = 'vorzeichen_add_sub') in (0, 2),
  '4: vorzeichen_add_sub hat beide Anlaesse (oder fehlt im Neuaufbau ganz)');

select * from finish();
rollback;
