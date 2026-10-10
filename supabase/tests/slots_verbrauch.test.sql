-- ============================================================================
-- Slots SL1 — Verbrauch, Widerruf und Kündigung (Bauauftrag Slots, Tests 8 und 9; Entscheidungen 13, 22).
--
--   8) einheiten_stand zählt jede Buchung genau einmal: Slot-Termin festgeschrieben, Slot-Termin ohne
--      Session, Einzel-Session ohne Kind-Termin. Testläufe nie.
--   9) Widerruf: Stammplätze enden am Widerrufstag, künftige Termine fallen weg, festgeschriebene werden
--      cancelled_by_us. Kündigung: Stammplätze enden am Tag vor gekuendigt_zum, Termine ab dann weg.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

\ir slots_fixture.sql
select pg_temp.als(:'admin');

-- ── 8) Verbrauch ─────────────────────────────────────────────────────────────
select pg_temp.kind('Vera Verbrauch', 'Basic', 12, '2027-09-01', '2028-08-31') as kv \gset
select stammplatz_vergeben(:'kv', pg_temp.zeilen('2:16:woechentlich'), '2027-11-01', '2027-11-01 08:00 Europe/Berlin') is not null;
select is((select verbraucht from einheiten_stand(:'kv', '2027-12-01')), 0, '8 vorher: nichts verbraucht');

-- a) Slot-Termin festgeschrieben, anwesend (Di 16.11.)
select termin_session_anlegen('2027-11-16', pg_temp.zeit(16), pg_temp.raum('Raum 1'), '2027-11-16 12:00 Europe/Berlin')
       ->> 'session_id' as sa \gset
select pg_temp.als(:'coach_a');
select anwesenheit_setzen(:'sa', :'kv', 'present') is not null;
select pg_temp.als(:'admin');
select is((select verbraucht from einheiten_stand(:'kv', '2027-12-01')), 1, '8 festgeschriebener Slot-Termin zählt einmal (nicht doppelt)');

-- b) Slot-Termin ohne Session, zu spät abgesagt (Di 23.11., Eingang 11:00)
select termin_absagen(pg_temp.termin(:'kv', '2027-11-23'), '2027-11-23 11:00 Europe/Berlin', '2027-11-23 12:00 Europe/Berlin') is not null;
select is((select verbraucht from einheiten_stand(:'kv', '2027-12-01')), 2, '8 Slot-Termin ohne Session (unentschuldigt) zählt');

-- c) Einzel-Session ohne Kind-Termin (Mi 24.11., /admin/schedule), anwesend
insert into coaching_sessions (coach_id, room, scheduled_at) values (:'coach_c', 'Einzelraum', '2027-11-24 15:00 Europe/Berlin')
returning id as se \gset
insert into session_students (session_id, student_id, attendance) values (:'se', :'kv', 'present');
select is((select verbraucht from einheiten_stand(:'kv', '2027-12-01')), 3, '8 Einzel-Session ohne Kind-Termin zählt');
select is((select count(*)::int from slots_einzelbuchungen(:'kv')), 1, '8 nur die Einzel-Session ist eine Buchung ohne Kind-Termin');

-- d) Testlauf zählt nie (Testkonto mit Vertrag, Testlauf-Session anwesend)
select pg_temp.kind('Theo Testkonto', 'Basic', 12, '2027-09-01', '2028-08-31') as kt \gset
update students set ist_test = true where id = :'kt';
insert into coaching_sessions (coach_id, room, scheduled_at, testlauf) values (:'coach_c', 'Testraum', '2027-11-24 16:00 Europe/Berlin', true)
returning id as st \gset
insert into session_students (session_id, student_id, attendance) values (:'st', :'kt', 'present');
select is((select verbraucht from einheiten_stand(:'kt', '2027-12-01')), 0, '8 Testlauf zählt nie');
select is((select count(*)::int from kind_termine where student_id = :'kt'), 0, '8 Testkonten bekommen keine Slot-Termine');
select throws_ok(format($f$select stammplatz_vergeben(%L, %L, '2027-11-01', '2027-11-01 08:00 Europe/Berlin')$f$,
                        :'kt', pg_temp.zeilen('2:16:woechentlich')), '22023', null, '8 Testkonto: kein Stammplatz (Entscheidung 8)');

-- ── 9) Widerruf ──────────────────────────────────────────────────────────────
-- Beginn 01.12.2027, Widerrufsfrist bis 14.12. Session am Di 14.12. ist festgeschrieben, Widerruf am 10.12.
select pg_temp.kind('Wim Widerruf', 'Basic', 12, '2027-12-01', '2028-11-30') as kw \gset
select stammplatz_vergeben(:'kw', pg_temp.zeilen('2:17:woechentlich'), '2027-12-01', '2027-12-01 08:00 Europe/Berlin')
       -> 'stammplatz_ids' ->> 0 as spw \gset
select termin_session_anlegen('2027-12-14', pg_temp.zeit(17), pg_temp.raum('Raum 1'), '2027-12-14 12:00 Europe/Berlin')
       ->> 'session_id' as sw \gset
update vertraege set zugangscode = 'EDV-ABCD-EFGH' where id = pg_temp.vertrag(:'kw');  -- Widerruf sperrt den Zugangscode
select vertrag_widerruf_erfassen(pg_temp.vertrag(:'kw'), '2027-12-10') is not null;
select is((select gueltig_bis from stammplaetze where id = :'spw'), date '2027-12-10', '9 Widerruf: Stammplatz endet am Widerrufstag');
select is((select count(*)::int from kind_termine where student_id = :'kw' and datum >= '2027-12-10' and session_id is null), 0,
          '9 Widerruf: künftige geplante Termine fallen weg');
select results_eq(format($$select kt.zustand, ss.attendance from kind_termine kt
                           join session_students ss on ss.session_id = kt.session_id and ss.student_id = kt.student_id
                          where kt.student_id = %L and kt.datum = '2027-12-14'$$, :'kw'),
                  $$values ('cancelled_by_us'::text, 'cancelled_by_us'::text)$$,
                  '9 Widerruf: festgeschriebener Termin wird cancelled_by_us');
select is((select count(*)::int from kind_termine where student_id = :'kw' and datum < '2027-12-10'), 1,
          '9 Widerruf: der Termin davor (07.12.) bleibt');

-- ── 9) Kündigung ─────────────────────────────────────────────────────────────
select pg_temp.kind('Kai Kündigung', 'Basic', 12, '2027-09-01', '2028-08-31') as kk \gset
select stammplatz_vergeben(:'kk', pg_temp.zeilen('2:18:woechentlich'), '2027-11-01', '2027-11-01 08:00 Europe/Berlin')
       -> 'stammplatz_ids' ->> 0 as spk \gset
select vertrag_sonderkuendigung_erfassen(pg_temp.vertrag(:'kk'), '2028-01-11', 'Umzug') is not null;
select is((select gueltig_bis from stammplaetze where id = :'spk'), date '2028-01-10',
          '9 Kündigung: Stammplatz endet am Tag vor gekuendigt_zum');
select is((select count(*)::int from kind_termine where student_id = :'kk' and datum >= '2028-01-11'), 0,
          '9 Kündigung: ab gekuendigt_zum keine Termine');
select ok((select count(*) from kind_termine where student_id = :'kk' and datum < '2028-01-11') > 0,
          '9 Kündigung: Termine davor bleiben');

select * from finish();
rollback;
