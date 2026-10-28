-- ============================================================================
-- Reihe 1 · C1 Reihenplanung (docs/reihe1/Bauauftrag-C-Session-Workflow.md C1.5, Konzept §2.1–2.3)
--
-- Testkind „Batu“ (nur in dieser Transaktion), alle Skills ohne Befund. Termine montags ab 11.01.2027
-- (keine Ferien bis März), Takt eine Session pro Woche.
--   a) Klassenarbeit am 02.03.2027 → acht Sessions, Kernideen-Reihenfolge und Aufteilung wie Konzept §2.2,
--      je Session höchstens 36 + 10 %, letzte = Generalprobe.
--   b) Start 18.01., Klassenarbeit am 23.02.2027 → sechs Sessions, Extremwerte fällt zuerst weg, Warnung für den Coach.
--   c) ohne Datum → rollierend vier Sessions ohne Generalprobe.
--   d) Graph-Abschluss, sicher/gesehen, Coach-Änderung getrennt, Neu planen nach der Session, Rechte.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(44);

\set admin_uid 'cccccccc-0c01-4000-8000-0000000000a1'
\set kind_uid  'cccccccc-0c01-4000-8000-0000000000b1'
insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid', 'reihe-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'kind_uid', 'reihe-kind@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values
  (:'admin_uid', 'reihe-admin@test.local', 'admin', 'Reihe Admin'),
  (:'kind_uid', 'reihe-kind@test.local', 'student', 'Batu Reihe');
insert into students (profile_id, class_level, ist_test) values (:'kind_uid', 9, true) returning id as batu \gset

create function pg_temp.als(p_uid text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', p_uid, 'role', 'authenticated')::text, true);
$$;
-- Kernideen einer Session als 'skill.K'-Liste
create function pg_temp.ki(p jsonb, p_nr int) returns text language sql as $$
  select string_agg((e ->> 'skill_key') || '.' || (e ->> 'kernidee_key'), ' ' order by o)
    from jsonb_array_elements(p -> 'sessions' -> (p_nr - 1) -> 'kernideen') with ordinality x(e, o)
$$;

select pg_temp.als(:'admin_uid');
set local role authenticated;

-- a) acht Sessions bis zur Arbeit
select reihe_anlegen(:'batu', array['quadratische_funktionen', 'quadratische_gleichungen'], '2027-03-02', 1, '2027-01-11') as k8 \gset
select :'k8'::jsonb -> 'plan' as p8, :'k8'::jsonb ->> 'reihe_id' as rid \gset
select is(jsonb_array_length(:'p8'::jsonb -> 'sessions'), 8, 'a1 acht Sessions bis zum Tag vor der Arbeit');
select is((select string_agg(s ->> 'datum', ',' order by o) from jsonb_array_elements(:'p8'::jsonb -> 'sessions') with ordinality x(s, o)),
          '2027-01-11,2027-01-18,2027-01-25,2027-02-01,2027-02-08,2027-02-15,2027-02-22,2027-03-01', 'a2 Daten: montags, letzte am Tag vor der Arbeit');
select is(:'p8'::jsonb -> 'sessions' -> 7 ->> 'art', 'generalprobe', 'a3 letzte Session ist die Generalprobe');
select is((select count(*)::int from jsonb_array_elements(:'p8'::jsonb -> 'sessions') s where s ->> 'art' = 'generalprobe'), 1, 'a4 genau eine Generalprobe');
select is((select string_agg((e ->> 'skill_key') || '.' || (e ->> 'kernidee_key'), ' ' order by so, eo)
             from jsonb_array_elements(:'p8'::jsonb -> 'sessions') with ordinality x(s, so),
                  jsonb_array_elements(s -> 'kernideen') with ordinality y(e, eo)),
          (select string_agg(skill_key || '.' || kernidee_key, ' ' order by nr) from reihe_kernideen), 'a5 alle 19 Kernideen in Katalog-Reihenfolge');
select is(pg_temp.ki(:'p8', 1), 'fkt_quadr_parabel.K1 fkt_quadr_parabel.K2', 'a6 Session 1 wie §2.2');
select is(pg_temp.ki(:'p8', 2), 'fkt_quadr_parabel.K3 fkt_quadr_scheitel.K1 fkt_quadr_scheitel.K2', 'a7 Session 2 wie §2.2');
select is(pg_temp.ki(:'p8', 3), 'fkt_quadr_normalform.K1 fkt_quadr_normalform.K2 fkt_quadr_normalform.K3', 'a8 Session 3 wie §2.2');
select is(pg_temp.ki(:'p8', 4), 'gleichung_quadr_wurzel.K1 gleichung_quadr_wurzel.K2 gleichung_quadr_wurzel.K3', 'a9 Session 4 wie §2.2');
select is(pg_temp.ki(:'p8', 5), 'gleichung_quadr_faktor.K1 gleichung_quadr_faktor.K2 gleichung_quadr_formel.K1', 'a10 Session 5 wie §2.2');
select is(pg_temp.ki(:'p8', 6), 'gleichung_quadr_formel.K2 gleichung_quadr_anzahl.K1 fkt_quadr_nullstellen.K1', 'a11 Session 6 wie §2.2');
select is(pg_temp.ki(:'p8', 7), 'fkt_quadr_nullstellen.K2 fkt_quadr_extrem.K1', 'a12 Session 7 wie §2.2');
select ok((:'p8'::jsonb -> 'sessions' -> 6 ->> 'transfer')::boolean, 'a13 Transferblock in Session 7');
select ok((select bool_and((s ->> 'minuten')::numeric <= 36 * 1.1) from jsonb_array_elements(:'p8'::jsonb -> 'sessions') s),
          'a14 keine Session über 36 Minuten plus 10 %');
select ok((:'p8'::jsonb #>> '{warnung,passt}')::boolean, 'a15 passt: keine Warnung');
select is(:'p8'::jsonb -> 'sessions' -> 0 -> 'skills', '["fkt_quadr_parabel"]'::jsonb, 'a16 Skills je Session');

-- reihenplan_kind (für Auftrag D), auch für das Kind selbst
select is((select array_agg(art order by session_nr) from reihenplan_kind(:'batu'))[8], 'generalprobe', 'a17 reihenplan_kind liefert die Generalprobe');
select is((select kernideen from reihenplan_kind(:'batu') where session_nr = 1), array['fkt_quadr_parabel.K1', 'fkt_quadr_parabel.K2'], 'a18 Kernideen als skill.K');
select pg_temp.als(:'kind_uid');
select is((select count(*)::int from reihenplan_kind(:'batu')), 8, 'a19 das Kind liest den eigenen Plan');
select throws_ok(format('select reihe_coach_lesen(%L)', :'batu'), '42501', null, 'a20 das Kind liest die Coach-Karte nicht');
select pg_temp.als(:'admin_uid');

-- d) Coach verschiebt scheitel in Session 3: wirksam getrennt vom Systemvorschlag
select reihe_coach_aendern(:'rid', 'verschieben', 'fkt_quadr_scheitel', '2027-01-25', 'erst Normalform') as k \gset
select is(pg_temp.ki(:'k'::jsonb -> 'plan', 3),
          'fkt_quadr_normalform.K1 fkt_quadr_normalform.K2 fkt_quadr_normalform.K3 fkt_quadr_scheitel.K1 fkt_quadr_scheitel.K2', 'd1 wirksam: scheitel in Session 3');
select is(pg_temp.ki(:'k'::jsonb -> 'system', 2), 'fkt_quadr_parabel.K3 fkt_quadr_scheitel.K1 fkt_quadr_scheitel.K2', 'd2 Systemvorschlag bleibt unverändert');
select ok((:'k'::jsonb -> 'plan' -> 'sessions' -> 2 -> 'kernideen' -> 3 ->> 'coach')::boolean, 'd3 verschobene Kernidee ist als Coach-Änderung markiert');
select is((select count(*)::int from reihe_coach_aenderungen where reihe_id = :'rid'), 1, 'd4 Coach-Änderung eigene Zeile');

-- Neu planen beim Abschluss der Session vom 11.01. (Kind anwesend): Ist-Zeile, neue Version, Änderung bleibt
reset role;
insert into coaching_sessions (room, scheduled_at) values ('ZZ Reihe', '2027-01-11 15:00 Europe/Berlin') returning id as s1 \gset
set local session_replication_role = replica;
insert into session_students (session_id, student_id, attendance) values (:'s1', :'batu', 'present');
set local session_replication_role = origin;
select set_config('edvance.session_rpc', '1', true);
update coaching_sessions set status = 'done' where id = :'s1';
select set_config('edvance.session_rpc', '', true);
select is((select jsonb_array_length(kernideen) from reihe_ist where session_id = :'s1'), 2, 'd5 Ist: zwei Kernideen in Session 1');
select is((select anlass from reihe_plan_versionen where reihe_id = :'rid' order by version desc limit 1), 'session', 'd6 neue Version nach der Session');
select pg_temp.als(:'admin_uid');
set local role authenticated;
select reihe_coach_lesen(:'batu') as k2 \gset
select is((:'k2'::jsonb #>> '{plan,sessions,0,nr}')::int, 2, 'd7 nächste Session ist Nummer 2');
select is(:'k2'::jsonb #>> '{plan,sessions,0,kernideen,0,minuten}', '6', 'd8 gesehene Kernidee kostet 6 Minuten');
select ok((select bool_or((a ->> 'gueltig')::boolean) from jsonb_array_elements(:'k2'::jsonb #> '{plan,aenderungen}') a), 'd9 Coach-Änderung bleibt gültig');

-- b) sechs Sessions: Extremwerte fällt zuerst weg, Warnung
select reihe_anlegen(:'batu', array['quadratische_funktionen', 'quadratische_gleichungen'], '2027-02-23', 1, '2027-01-18') as k6 \gset
select is(jsonb_array_length(:'k6'::jsonb #> '{plan,sessions}'), 6, 'b1 sechs Sessions');
select ok(not (:'k6'::jsonb #>> '{plan,warnung,passt}')::boolean, 'b2 passt nicht: Warnung für den Coach');
select is(:'k6'::jsonb #>> '{plan,warnung,entfallen,0,skill_key}', 'fkt_quadr_extrem', 'b3 zuerst fällt Extremwerte weg');
select ok((select bool_and((s ->> 'minuten')::numeric <= 39.6) from jsonb_array_elements(:'k6'::jsonb #> '{plan,sessions}') s), 'b4 auch gekürzt höchstens 36 + 10 %');

-- c) ohne Datum: rollierend vier Sessions
select reihe_anlegen(:'batu', array['quadratische_funktionen'], null, 1, '2027-01-11') as kr \gset
select is(jsonb_array_length(:'kr'::jsonb #> '{plan,sessions}'), 4, 'c1 rollierend vier Sessions');
select ok(not exists (select 1 from jsonb_array_elements(:'kr'::jsonb #> '{plan,sessions}') s where s ->> 'art' = 'generalprobe'), 'c2 ohne Generalprobe');
-- Rechte und nur anhängen
reset role;
-- Graph-Abschluss: nur quadratische_funktionen zieht formel und wurzel hinein, faktor und anzahl nicht
select ok(exists (select 1 from reihe_skills(array['quadratische_funktionen']) where skill_key = 'gleichung_quadr_formel')
          and not exists (select 1 from reihe_skills(array['quadratische_funktionen']) where skill_key = 'gleichung_quadr_faktor'),
          'd10 Graph zieht gleichung_quadr_formel hinein, gleichung_quadr_faktor nicht');

-- Zweitprüfung 8: Rechte, Sonderfälle der Kürzung
\set coach_uid 'cccccccc-0c01-4000-8000-0000000000c1'
insert into auth.users (id, email, instance_id, aud, role) values
  (:'coach_uid', 'reihe-coach@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values (:'coach_uid', 'reihe-coach@test.local', 'coach', 'Reihe Coach');
select pg_temp.als(:'coach_uid');
set local role authenticated;
select throws_ok(format('select reihe_coach_lesen(%L)', :'batu'), '42501', null, 'd12 Coach ohne laufenden Vertrag liest nicht');
select throws_ok(format('select reihe_anlegen(%L, array[%L])', :'batu', 'quadratische_funktionen'), '42501', null, 'd13 Coach ohne Vertrag legt keine Reihe an');
select pg_temp.als(:'kind_uid');
select throws_ok(format('select reihe_anlegen(%L, array[%L])', :'batu', 'quadratische_funktionen'), '42501', null, 'd14 das Kind legt keine Reihe an');
select throws_ok(format('insert into reihen (student_id, thema_keys, start) values (%L, array[%L], current_date)', :'batu', 'x'), '42501', null, 'd15 kein direktes Schreiben als authenticated');
reset role;
insert into students (class_level, ist_test) values (9, true) returning id as k2 \gset
insert into reihen (student_id, thema_keys, ka_datum, start) values (:'k2', array['quadratische_funktionen'], '2027-01-12', '2027-01-11') returning id as r1 \gset
select is(jsonb_array_length(reihe_plan_rechnen(:'r1') -> 'sessions'), 1, 'd16 eine Session vor der Arbeit: nur die Generalprobe');
select ok(not (reihe_plan_rechnen(:'r1') #>> '{warnung,passt}')::boolean, 'd17 dann passt die Reihe nicht');
-- Gesehene Kernideen (Ist der Session) werden bei Knappheit mit 4 Minuten geplant
insert into students (class_level, ist_test) values (9, true) returning id as k3 \gset
insert into reihen (student_id, thema_keys, ka_datum, start) values (:'k3', array['quadratische_gleichungen'], '2027-01-19', '2027-01-11') returning id as r2 \gset
insert into reihe_ist (reihe_id, session_id, datum, kernideen)
select :'r2', :'s1', '2027-01-04', jsonb_agg(jsonb_build_object('skill_key', skill_key, 'kernidee_key', kernidee_key))
  from reihe_kernideen where skill_key like 'gleichung_quadr_%';
select ok((reihe_plan_rechnen(:'r2') #>> '{warnung,gesehen_knapp}')::boolean
          and (reihe_plan_rechnen(:'r2') #>> '{sessions,0,kernideen,0,minuten}') = '4', 'd18 Kürzen Stufe 3: gesehen 4 statt 6 Minuten, im Plan vermerkt');
select throws_ok(format('update reihe_plan_versionen set grund = %L where reihe_id = %L', 'x', :'rid'), '55000', null, 'd11 Versionen nur anhängen');

select * from finish();
rollback;
