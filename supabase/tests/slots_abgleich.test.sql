-- ============================================================================
-- Slots SL1 — Abgleich und Überspringen (Bauauftrag Slots, Tests 5 und 12; Entscheidung 11).
--
--   5) Eine Absage und eine Rücknahme ändern nur die betroffenen Zeilen. Ein Raum-Stift überlebt
--      termine_planen. Ein Zusatztermin bei vollem Budget verdrängt den letzten Stammplatz-Termin.
--  12) Ein Stammplatz-Datum, das per Zusatz voll ist, bekommt keinen Termin; das nächste rückt nach, und
--      die Planbilanz nennt es. Eine Einzel-Session-Buchung ohne Kind-Termin belegt Budget und sperrt den Tag.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

\ir slots_fixture.sql
select pg_temp.als(:'admin');
\set jetzt '''2028-03-13 09:12 Europe/Berlin'''

-- ── 5) Absage und Rücknahme ändern nur die betroffenen Zeilen ────────────────
-- Basic Halbjahr ab 01.11.2027, Di 16 Uhr: 19 Termine bis 28.03.2028, danach ohne Budget.
select pg_temp.kind('Ada Abgleich', 'Basic', 6, '2027-11-01', '2028-06-15') as ka \gset
select stammplatz_vergeben(:'ka', pg_temp.zeilen('2:16:woechentlich'), '2027-11-01', '2027-11-01 08:00 Europe/Berlin') is not null;
create temp table s0 as select id, datum, zustand from kind_termine where student_id = :'ka';
select is((select count(*)::int from s0), 19, '5 Ausgangslage: 19 Termine');

select termin_absagen(pg_temp.termin(:'ka', '2028-03-14'), '2028-03-13 09:00 Europe/Berlin', :jetzt) is not null;
select ok((select count(*) = 19 from s0 where s0.id in (select id from kind_termine)), '5 Absage: alle bisherigen Zeilen bleiben (gleiche id)');
select is((select count(*)::int from kind_termine where student_id = :'ka' and id not in (select id from s0)), 1,
          '5 Absage: genau eine Zeile kommt dazu (die Einheit landet hinten)');
select is((select datum from kind_termine where student_id = :'ka' and id not in (select id from s0)), date '2028-04-04',
          '5 Absage: der neue Termin ist der nächste Stammplatz-Termin nach dem bisher letzten (04.04.)');
select is((select count(*)::int from kind_termine kt join s0 using (id) where kt.zustand <> s0.zustand), 1,
          '5 Absage: nur der abgesagte Termin ändert seinen Zustand');

select absage_zuruecknehmen(pg_temp.termin(:'ka', '2028-03-14'), :jetzt) is not null;
select set_eq(format('select id, datum, zustand from kind_termine where student_id = %L', :'ka'),
              'select id, datum, zustand from s0', '5 Rücknahme: wieder genau die Zeilen von vorher');

-- Raum-Stift überlebt termine_planen.
select pg_temp.termin(:'ka', '2028-03-21') as t21 \gset
select termin_raum_setzen(:'t21', pg_temp.raum('Raum 2'), :jetzt) is not null;
select termine_planen(:'ka', :jetzt);
select results_eq(format('select raum_id, raum_fest from kind_termine where id = %L', :'t21'),
                  format('values (%L::uuid, true)', pg_temp.raum('Raum 2')),
                  '5 Raum-Stift: Zeile, id und Raum bleiben nach termine_planen');
select is((select raum_id from slot_zuteilung('2028-03-21', pg_temp.zeit(16)) where termin_id = :'t21'), pg_temp.raum('Raum 2'),
          '5 Raum-Stift: die Zuteilung legt das Kind in seinen Raum');

-- Zusatztermin bei vollem Budget verdrängt den letzten Stammplatz-Termin.
select is(zusatztermin_buchen(:'ka', '2028-03-15', pg_temp.zeit(15), :jetzt) -> 'verdraengt', '["2028-03-28"]'::jsonb,
          '5 Zusatztermin bei vollem Budget verdrängt den letzten Stammplatz-Termin (28.03.)');
select is((select count(*)::int from kind_termine where student_id = :'ka' and zustand = 'planned'), 19,
          '5 die Zahl der geplanten Termine bleibt beim Budget (19)');

-- ── 12) Überspringen eines vollen Datums ─────────────────────────────────────
-- Mo 12.06.2028, 14 Uhr: Raum 2 geschlossen, fünf andere Kinder per Zusatztermin -> voll.
select termin_coach_setzen('2028-06-12', pg_temp.zeit(14), pg_temp.raum('Raum 2'), null, :jetzt) is not null;
create temp table voll as
select n, pg_temp.kind('Voll' || n || ' Kind', 'Basic', 12, '2027-09-01', '2028-08-31') as student from generate_series(1, 5) n;
select count(*) from voll, lateral zusatztermin_buchen(student, '2028-06-12', pg_temp.zeit(14), :jetzt) x;
select is(slot_belegt('2028-06-12', pg_temp.zeit(14)), slot_kapazitaet('2028-06-12', pg_temp.zeit(14)), '12 Mo 12.06. 14 Uhr ist voll');

-- Basic Halbjahr 01.02.–30.09.2028, Stammplatz Mo 14 Uhr ab Beginn: 19 Einheiten, mehr als 19 Montage;
-- ohne das volle Datum wäre der 12.06. einer der 19 Termine.
select pg_temp.kind('Ole Überspringen', 'Basic', 6, '2028-02-01', '2028-09-30') as ko \gset
select stammplatz_vergeben(:'ko', pg_temp.zeilen('1:14:woechentlich'), '2028-02-01', '2028-02-01 08:00 Europe/Berlin')
       -> 'planbilanz' as pb12 \gset
select ok((:'pb12'::jsonb ->> 'letzter_termin')::date > '2028-06-12', '12 Vorbedingung: der Plan reicht über den 12.06. hinaus');
select is((select count(*)::int from kind_termine where student_id = :'ko' and datum = '2028-06-12'), 0,
          '12 das volle Datum bekommt keinen Termin');
select is((select count(*)::int from kind_termine where student_id = :'ko'), 19, '12 das nächste Datum rückt nach (19 Termine)');
select ok(:'pb12'::jsonb -> 'uebersprungen' @> '["2028-06-12"]'::jsonb, '12 die Planbilanz nennt das übersprungene Datum');

-- Einzel-Session ohne Kind-Termin: Di 21.03.2028, 15 Uhr (Raum-Termin-frei, wie /admin/schedule).
select pg_temp.kind('Cem Einzel', 'Basic', 6, '2027-11-01', '2028-06-15') as kc \gset
select stammplatz_vergeben(:'kc', pg_temp.zeilen('2:17:woechentlich'), '2027-11-01', '2027-11-01 08:00 Europe/Berlin') is not null;
insert into coaching_sessions (coach_id, room, scheduled_at) values (:'coach_c', 'Einzelraum', '2028-03-21 15:00 Europe/Berlin')
returning id as se \gset
insert into session_students (session_id, student_id, attendance) values (:'se', :'kc', 'planned');
select termine_planen(:'kc', :jetzt);
select is((select count(*)::int from kind_termine where student_id = :'kc' and datum = '2028-03-21'), 0,
          '12 Einzel-Session sperrt den Tag (kein Slot-Termin am 21.03.)');
select is((select count(*)::int from kind_termine where student_id = :'kc'), 18, '12 Einzel-Session belegt eine Einheit (18 Slot-Termine)');
select is((slots_planbilanz(pg_temp.vertrag(:'kc'), '2028-03-13') ->> 'geplant')::int, 19,
          '12 Planbilanz: geplant zählt die Einzel-Session mit (19)');

select * from finish();
rollback;
