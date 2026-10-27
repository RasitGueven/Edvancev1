-- ============================================================================
-- L5 Teil A: Klassenarbeiten statt Themen-Nummern (docs/report/Bauauftrag-L5.md, Migration 20261027081403)
--
--   a) Nichts vorbelegt, Schuljahr nach NRW-Zählung.
--   b) RLS: nur Admin liest und schreibt; Coach und anon nicht, auch nicht über die Funktionen.
--   c) Check-in mit Datum und Thema erzeugt eine Zeile (quelle 'checkin'); gleiches Kind und Datum ergänzt sie.
--   d) Erstgespräch: Anzahl, eine Zeile je Schuljahr, ersetzt beim nächsten Speichern.
--   e) Schulwert erst ab zwei übereinstimmenden Kindern (und mehr als die Gegenstimme) oder Bestätigung.
--   f) Eigene Angaben mit Nummer gehen vor; vom Schulwert kommt keine Zeile eines anderen Kindes zurück.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(32);

-- a) Nichts vorbelegt (Entscheidung 5)
select is((select count(*)::int from lead_klassenarbeiten), 0, 'a1 keine Arbeit eines Kindes vorbelegt');
select is((select count(*)::int from schul_klassenarbeiten), 0, 'a2 keine Arbeit einer Schule vorbelegt');
select is(ka_schuljahr('2026-10-27'), '2026/27', 'a3 Oktober gehört zum laufenden Schuljahr');
select is(ka_schuljahr('2027-03-01'), '2026/27', 'a4 März gehört zum Schuljahr seit August davor');
select is(ka_schuljahr('2026-07-31'), '2025/26', 'a5 31. Juli gehört zum alten Schuljahr');

\set admin_uid 'dddddddd-dddd-dddd-dddd-0000000000f5'
\set coach_uid 'dddddddd-dddd-dddd-dddd-0000000000f6'
insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid', 'kafolge-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach_uid', 'kafolge-coach@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values
  (:'admin_uid', 'kafolge-admin@test.local', 'admin', 'KA Admin'),
  (:'coach_uid', 'kafolge-coach@test.local', 'coach', 'KA Coach');

insert into themen (thema_key, fach, klasse, label, stufe, sort) values
  ('kf_a', 'mathematik', 9, 'KF A', 'zweite', 9510), ('kf_b', 'mathematik', 9, 'KF B', 'zweite', 9520),
  ('kf_c', 'mathematik', 9, 'KF C', 'zweite', 9530), ('kf_d', 'mathematik', 9, 'KF D', 'zweite', 9540);
insert into schulen (name, ort) values ('KF Schule', 'Testort');
select id as schule from schulen where name = 'KF Schule' \gset

create function pg_temp.lead(p_name text) returns uuid language sql as $$
  insert into leads (full_name, class_level, status, schule_id)
  values (p_name, 9, 'contacted', (select id from schulen where name = 'KF Schule')) returning id
$$;
select pg_temp.lead('KF Kind 1') as l1, pg_temp.lead('KF Kind 2') as l2, pg_temp.lead('KF Kind 3') as l3,
       pg_temp.lead('KF Kind 4') as l4, pg_temp.lead('KF Kind 5') as l5 \gset

select set_config('edvance.allow_provisional', '1', true);
insert into students (class_level, is_provisional, lead_id) values (9, true, :'l1') returning id as k1 \gset
insert into coaching_sessions (coach_id, room, scheduled_at) values (:'coach_uid', 'KF 1', '2026-10-20 14:00+00') returning id as s1 \gset
insert into coaching_sessions (coach_id, room, scheduled_at) values (:'coach_uid', 'KF 2', '2026-10-22 14:00+00') returning id as s2 \gset
insert into coaching_sessions (coach_id, room, scheduled_at) values (:'coach_uid', 'KF 3', '2026-10-24 14:00+00') returning id as s3 \gset
-- Buchung ohne Vertragsprüfung (die gehört nicht zu diesem Test); danach laufen Trigger wieder.
set local session_replication_role = replica;
insert into session_students (session_id, student_id) values (:'s1', :'k1'), (:'s2', :'k1'), (:'s3', :'k1');
set local session_replication_role = origin;

-- c) Check-in
insert into session_checkin (session_id, student_id, stimmung, klassenarbeit_datum, klassenarbeit_thema_key, thema_antwort)
values (:'s1', :'k1', 'gut', '2026-11-12', 'kf_a', 'noch_dran');
select results_eq(
  format($$select schuljahr, datum, thema_keys, status, quelle, nr from lead_klassenarbeiten where lead_id = %L$$, :'l1'),
  $$values ('2026/27', '2026-11-12'::date, array['kf_a'], 'bevorstehend', 'checkin', null::int)$$,
  'c1 Check-in mit Datum und Thema legt eine Zeile an');
insert into session_checkin (session_id, student_id, stimmung, klassenarbeit_datum, klassenarbeit_thema_key, thema_antwort)
values (:'s2', :'k1', 'gut', '2026-11-12', 'kf_b', 'noch_dran');
select results_eq(
  format($$select count(*)::int, max(thema_keys::text) from lead_klassenarbeiten where lead_id = %L$$, :'l1'),
  $$values (1, '{kf_a,kf_b}')$$,
  'c2 gleiches Kind, gleiches Datum: dieselbe Zeile, um das Thema ergänzt');
update session_checkin set klassenarbeit_thema_key = 'kf_a' where session_id = :'s2' and student_id = :'k1';
select is((select thema_keys from lead_klassenarbeiten where lead_id = :'l1'), array['kf_a', 'kf_b'],
  'c3 Thema schon dabei: keine Doppelung');
insert into session_checkin (session_id, student_id, stimmung, klassenarbeit_datum, thema_antwort)
values (:'s3', :'k1', 'gut', '2026-12-01', 'noch_dran');
select is((select count(*)::int from lead_klassenarbeiten where lead_id = :'l1'), 1, 'c4 ohne Thema keine Zeile');

-- b) RLS und Rechte
select ok(not has_table_privilege('anon', 'public.lead_klassenarbeiten', 'select'), 'b1 anon liest lead_klassenarbeiten nicht');
select ok(not has_table_privilege('anon', 'public.schul_klassenarbeiten', 'select'), 'b2 anon liest schul_klassenarbeiten nicht');
select set_config('request.jwt.claims', json_build_object('sub', :'coach_uid', 'role', 'authenticated')::text, true);
set local role authenticated;
select is((select count(*)::int from lead_klassenarbeiten), 0, 'b3 Coach sieht keine Zeile');
select throws_ok(format($$insert into lead_klassenarbeiten (lead_id, schuljahr, thema_keys, quelle) values (%L, '2026/27', '{kf_a}', 'admin')$$, :'l2'),
  '42501', null, 'b4 Coach schreibt nicht');
select throws_ok(format($$select * from ka_folge_schule(%L, 9, '2026/27')$$, :'schule'), '42501', null, 'b5 Coach ruft ka_folge_schule nicht');
select throws_ok(format($$select * from ka_folge_lead(%L, '2026/27')$$, :'l1'), '42501', null, 'b6 Coach ruft ka_folge_lead nicht');
select throws_ok(format($$select ka_erstgespraech_speichern(%L, 5, null, null, null, null)$$, :'l1'), '42501', null,
  'b7 Coach speichert kein Erstgespräch');
reset role;

select set_config('request.jwt.claims', json_build_object('sub', :'admin_uid', 'role', 'authenticated')::text, true);
set local role authenticated;

-- d) Erstgespräch
select ka_erstgespraech_speichern(:'l2', 5, 'bevorstehend', '2026-11-13', array['kf_a', 'kf_c'], null);
select results_eq(
  format($$select l.ka_anzahl_schuljahr::int, k.status, k.datum, k.thema_keys, k.quelle
             from leads l join lead_klassenarbeiten k on k.lead_id = l.id where l.id = %L$$, :'l2'),
  $$values (5, 'bevorstehend', '2026-11-13'::date, array['kf_a', 'kf_c'], 'erstgespraech')$$,
  'd1 Anzahl am Lead, eine Zeile aus dem Erstgespräch');
select ka_erstgespraech_speichern(:'l2', 5, 'geschrieben', null, array['kf_a'], 3);
select results_eq(
  format($$select count(*)::int, max(status), max(note)::int, bool_and(datum is null) from lead_klassenarbeiten where lead_id = %L$$, :'l2'),
  $$values (1, 'geschrieben', 3, true)$$,
  'd2 erneut gespeichert: Zeile ersetzt, Note nur bei geschrieben');
select ka_erstgespraech_speichern(:'l2', null, null, null, null, null);
select results_eq(
  format($$select (select ka_anzahl_schuljahr::int from leads where id = %L), (select count(*)::int from lead_klassenarbeiten where lead_id = %L)$$, :'l2', :'l2'),
  $$values (null::int, 0)$$,
  'd3 „weiß nicht“: Anzahl leer, Zeile entfällt');
select lives_ok(format($$select ka_erstgespraech_speichern(%L, 4, 'bevorstehend', '2026-11-12', array['kf_c'], null)$$, :'l1'),
  'd4 gleiches Datum wie ein Check-in: kein Fehler');
select is((select thema_keys from lead_klassenarbeiten where lead_id = :'l1'), array['kf_a', 'kf_b', 'kf_c'],
  'd5 … die Arbeit des Check-ins wird um das Thema ergänzt');
select throws_ok(format($$insert into lead_klassenarbeiten (lead_id, schuljahr, thema_keys, quelle) values (%L, '2026/27', '{kf_zz}', 'admin')$$, :'l3'),
  '23503', null, 'd6 unbekanntes Thema abgelehnt');
select throws_ok(format($$insert into lead_klassenarbeiten (lead_id, schuljahr, thema_keys, status, note, quelle) values (%L, '2026/27', '{kf_a}', 'bevorstehend', 2, 'admin')$$, :'l3'),
  '23514', null, 'd7 Note nur bei geschriebener Arbeit');

-- e) Schulwert. Kind 3 sagt: Arbeit 2 = kf_b + kf_c.
insert into lead_klassenarbeiten (lead_id, schuljahr, nr, thema_keys, quelle) values (:'l3', '2026/27', 2, '{kf_c,kf_b}', 'admin');
select results_eq(
  format($$select nr, kinder, gueltig from ka_folge_schule(%L, 9, '2026/27') where nr = 2$$, :'schule'),
  $$values (2, 1, false)$$,
  'e1 ein Kind allein: kein Schulwert');
select is_empty(format($$select * from ka_folge_lead(%L, '2026/27')$$, :'l5'), 'e2 … und nichts im Bericht eines anderen Kindes');
insert into lead_klassenarbeiten (lead_id, schuljahr, nr, thema_keys, quelle) values (:'l4', '2026/27', 2, '{kf_b,kf_c}', 'admin');
select results_eq(
  format($$select nr, thema_keys, kinder, bestaetigt, gueltig from ka_folge_schule(%L, 9, '2026/27') where nr = 2$$, :'schule'),
  $$values (2, array['kf_b', 'kf_c'], 2, false, true)$$,
  'e3 zwei Kinder stimmen überein (Reihenfolge der Themen egal): Schulwert gilt');
select results_eq(
  format($$select nr, thema_keys, status, note, herkunft from ka_folge_lead(%L, '2026/27')$$, :'l5'),
  $$values (2, array['kf_b', 'kf_c'], null::text, null::smallint, 'schule')$$,
  'e4 Bericht von Kind 5: nur die abgeleitete Arbeit, ohne Stand und Note eines anderen Kindes');
-- Gegenstimme mit gleich vielen Kindern: unentschieden, kein Schulwert.
insert into lead_klassenarbeiten (lead_id, schuljahr, nr, thema_keys, quelle) values
  (:'l2', '2026/27', 3, '{kf_d}', 'admin'), (:'l3', '2026/27', 3, '{kf_d}', 'admin'),
  (:'l4', '2026/27', 3, '{kf_a}', 'admin'), (:'l5', '2026/27', 3, '{kf_a}', 'admin');
select results_eq(
  format($$select kinder, gueltig from ka_folge_schule(%L, 9, '2026/27') where nr = 3$$, :'schule'),
  $$values (2, false)$$,
  'e5 zwei gegen zwei: kein Schulwert');
insert into schul_klassenarbeiten (schule_id, klasse, schuljahr, nr, thema_keys, bestaetigt_von)
values (:'schule', 9, '2026/27', 4, '{kf_d}', :'admin_uid');
select results_eq(
  format($$select nr, kinder, bestaetigt, gueltig from ka_folge_schule(%L, 9, '2026/27') where nr = 4$$, :'schule'),
  $$values (4, 0, true, true)$$,
  'e6 vom Admin bestätigt: gilt auch ohne Kinder');
-- Ohne Nummer zählt das Datum: Kind 1 (Check-in) und Kind 4 nennen dieselbe Arbeit am 12.11.
insert into lead_klassenarbeiten (lead_id, schuljahr, datum, thema_keys, quelle)
values (:'l4', '2026/27', '2026-11-12', '{kf_c,kf_a,kf_b}', 'admin');
select results_eq(
  format($$select nr, datum, kinder, gueltig from ka_folge_schule(%L, 9, '2026/27') where nr is null$$, :'schule'),
  $$values (null::int, '2026-11-12'::date, 2, true)$$,
  'e7 ohne Nummer: gleiche Arbeit über das Datum erkannt (Nummer vergibt der Admin)');

-- f) Eigene Angaben vor Schulwert: Kind 5 hat selbst Arbeit 3 = kf_a; Arbeit 4 (kf_d) kommt von der Schule.
select results_eq(
  format($$select nr, thema_keys, herkunft from ka_folge_lead(%L, '2026/27')$$, :'l5'),
  $$values (2, array['kf_b', 'kf_c'], 'schule'), (3, array['kf_a'], 'eigen'), (4, array['kf_d'], 'schule')$$,
  'f1 eigene Arbeit 3, dazu die gültigen Arbeiten 2 und 4 der Schule');
-- Kind 2 sagt Arbeit 3 = kf_d; die Schule hat kf_d als Arbeit 4: das eigene Kind geht vor, Arbeit 4 entfällt.
select results_eq(
  format($$select nr, thema_keys, herkunft from ka_folge_lead(%L, '2026/27') where nr is not null$$, :'l2'),
  $$values (2, array['kf_b', 'kf_c'], 'schule'), (3, array['kf_d'], 'eigen')$$,
  'f2 gemeinsames Thema mit eigener Arbeit: die Arbeit der Schule entfällt');
reset role;

select * from finish();
rollback;
