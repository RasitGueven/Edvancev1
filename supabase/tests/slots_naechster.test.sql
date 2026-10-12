-- ============================================================================
-- Slots SL1 — Nächster Termin (Bauauftrag Slots, Test 13; Entscheidung 14).
--
--  13) quest_erzeugen findet bei 2× pro Woche den nächsten Slot-Termin vor dem Festschreiben (nicht
--      Session-Tag + 7). session_abschluss_kind liefert naechste_session wieder. session_kind_kontext und
--      coach_raum_live rechnen Quest B vom selben Termin.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

\ir slots_fixture.sql
select pg_temp.als(:'admin');

-- Aufgaben für Quests (wie session_q1).
insert into skills (skill_key, label, fundament_tiefe, klasse_herkunft) values ('zz_sl1_neu', 'SL1 Neu', 1, 8);
insert into tasks (content_type, input_type, status, is_active, question, skill_key, est_duration_sec, source, source_ref, einsatz)
select 'exercise', 'SHORT_TEXT', 'ready', true, 'SL1 Frage ' || n, 'zz_sl1_neu', 180, 'test', 'sl1-neu-' || n, '{quest}'
  from generate_series(1, 4) n;
insert into task_solutions (task_id, correct_answers, solution)
select t.id, '["1"]'::jsonb, 'Lösungsweg' from tasks t where t.source_ref like 'sl1-neu-%';

-- Premium Jahr, 2× pro Woche: Di und Do 16 Uhr. Festgeschrieben ist nur Di 16.11.2027.
select pg_temp.kind('Nia Nächster', 'Premium', 12, '2027-09-01', '2028-08-31') as kn \gset
select stammplatz_vergeben(:'kn', pg_temp.zeilen('2:16:woechentlich', '4:16:woechentlich'), '2027-11-01',
                           '2027-11-01 08:00 Europe/Berlin') is not null;
select termin_session_anlegen('2027-11-16', pg_temp.zeit(16), pg_temp.raum('Raum 1'), '2027-11-16 12:00 Europe/Berlin')
       ->> 'session_id' as s \gset
select is((select count(*)::int from coaching_sessions where scheduled_at > '2027-11-16 16:00 Europe/Berlin'), 0,
          '13 Vorbedingung: nach Di 16.11. gibt es noch keine Session');

select is(naechster_termin(:'kn', '2027-11-16 16:00 Europe/Berlin'), '2027-11-18 16:00 Europe/Berlin'::timestamptz,
          '13 naechster_termin: Do 18.11., 16 Uhr (Slot-Termin vor dem Festschreiben)');

-- quest_erzeugen: Der nächste Termin ist Do 18.11. (vor dem Festschreiben). Damit fällt Quest A auf den
-- 17.11. (Tag vor dem nächsten Termin), und eine Quest B entfällt (B nur, wenn sie nach A liegt).
-- Mit der alten Suche (keine Session -> Session-Tag + 7) wären es A am 18.11. und B am 22.11.
select pg_temp.als_system();
create temp table q13 as select * from quest_erzeugen(:'s', :'kn', array['zz_sl1_neu']);
select results_eq('select art, faellig_ab from q13 order by art', $$values ('A'::text, date '2027-11-17')$$,
                  '13 quest_erzeugen: rechnet mit dem nächsten Slot-Termin (A am 17.11., keine B), nicht mit Session-Tag + 7');

-- Session läuft, Tablet 1 ist dem Kind zugewiesen.
select set_config('edvance.session_rpc', '1', true);
update coaching_sessions set status = 'active', gestartet_am = '2027-11-16 16:00 Europe/Berlin' where id = :'s';
select set_config('edvance.session_rpc', '', true);
insert into session_tablets (session_id, student_id, tablet_nr, geraet_id) values (:'s', :'kn', 1, :'tablet');
update session_einstellungen set wert = 'true' where schluessel = 'home_quests_aktiv';

select pg_temp.als(:'tablet');
select is((session_abschluss_kind(:'s') ->> 'naechste_session')::timestamptz, '2027-11-18 16:00 Europe/Berlin'::timestamptz,
          '13 session_abschluss_kind: naechste_session ist wieder da (Do 18.11.)');
select is(session_kind_kontext(:'s') -> 'quest_termine' ->> 'quest_b', '2027-11-17',
          '13 session_kind_kontext: Quest B am 17.11.');
select pg_temp.als(:'coach_a');
select is((select k ->> 'quest_b' from jsonb_array_elements(coach_raum_live(:'s') -> 'kinder') k
            where k ->> 'student_id' = :'kn'), '2027-11-17', '13 coach_raum_live: Quest B am 17.11.');

-- Abgesagter Termin zählt nicht als nächster.
select pg_temp.als(:'admin');
select termin_absagen(pg_temp.termin(:'kn', '2027-11-18'), '2027-11-17 12:00 Europe/Berlin', '2027-11-17 13:00 Europe/Berlin') is not null;
select is(naechster_termin(:'kn', '2027-11-16 16:00 Europe/Berlin'), '2027-11-23 16:00 Europe/Berlin'::timestamptz,
          '13 nach einer Absage ist der nächste Termin Di 23.11.');

select * from finish();
rollback;
