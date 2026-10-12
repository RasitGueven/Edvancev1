-- ============================================================================
-- Slots SL1 — Kalender (Bauauftrag Slots, Test 10; Entscheidungen 18 und 21).
--
--  10) A-/B-Woche über KW 52, 53 und 1. Feiertag und Pfingstferientag erzeugen keinen Termin.
--      Ein Stichtag hinter max(ferien_nrw.bis) plant bis dorthin und meldet SL012 in der Planbilanz.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

\ir slots_fixture.sql
select pg_temp.als(:'admin');

-- ── A- und B-Woche: ISO-KW, ungerade = A ─────────────────────────────────────
-- 2026 hat 53 ISO-Wochen: KW 52 (21.12.) gerade = B, KW 53 (28.12.) ungerade = A, KW 1 2027 (04.01.) = A.
select results_eq($$select extract(week from d)::int, slots_takt_passt('a_woche', d), slots_takt_passt('b_woche', d),
                           slots_takt_passt('woechentlich', d)
                      from unnest(array[date '2026-12-21', date '2026-12-28', date '2027-01-04', date '2027-01-11']) d$$,
                  $$values (52, false, true, true), (53, true, false, true), (1, true, false, true), (2, false, true, true)$$,
                  '10 KW 52 = B, KW 53 = A, KW 1 = A (zwei A-Wochen hintereinander), KW 2 = B');

-- Plan über den Jahreswechsel 2027/28: alle A-Wochen-Termine liegen in ungeraden, alle B-Wochen-Termine in
-- geraden Kalenderwochen.
select pg_temp.kind('Abe Wechsel', 'Premium', 6, '2027-11-01', '2028-06-15') as ka \gset
select stammplatz_vergeben(:'ka', pg_temp.zeilen('2:14:a_woche', '4:14:b_woche'), '2027-11-01', '2027-11-01 08:00 Europe/Berlin') is not null;
select is((select count(*)::int from kind_termine kt join stammplaetze s on s.id = kt.stammplatz_id
            where kt.student_id = :'ka'
              and ((s.takt = 'a_woche' and extract(week from kt.datum)::int % 2 = 0)
                or (s.takt = 'b_woche' and extract(week from kt.datum)::int % 2 = 1))), 0,
          '10 kein Termin in der falschen Woche (über KW 52/1)');
select ok((select count(*) from kind_termine where student_id = :'ka' and datum between '2028-01-01' and '2028-01-31') > 0
          and (select count(*) from kind_termine where student_id = :'ka' and datum between '2027-12-01' and '2027-12-23') > 0,
          '10 Termine vor und nach dem Jahreswechsel');

-- ── Feiertag und Pfingstferientag ────────────────────────────────────────────
-- 2028: Ostermontag 17.04. liegt in den Osterferien; Tag der Arbeit Mo 01.05., Pfingstmontag 05.06.,
-- Pfingstferientag Di 06.06., Fronleichnam Do 15.06.
select pg_temp.kind('Fee Feiertag', 'Premium', 12, '2027-09-01', '2028-08-31') as kf \gset
select stammplatz_vergeben(:'kf', pg_temp.zeilen('1:15:woechentlich', '2:15:woechentlich'), '2028-04-24', '2028-04-24 08:00 Europe/Berlin') is not null;
select is((select count(*)::int from kind_termine where student_id = :'kf' and datum in ('2028-05-01', '2028-06-05', '2028-06-06')), 0,
          '10 Tag der Arbeit, Pfingstmontag und Pfingstferientag: kein Termin');
select is((select count(*)::int from kind_termine where student_id = :'kf' and datum in ('2028-05-02', '2028-06-12', '2028-06-13')), 3,
          '10 die Tage daneben haben Termine');

-- ── Stichtag hinter der Ferientabelle (Ende 06.08.2030) ──────────────────────
select pg_temp.kind('Zack Zukunft', 'Basic', 12, '2030-03-01', '2031-02-28') as kz \gset
select stammplatz_vergeben(:'kz', pg_temp.zeilen('1:16:woechentlich'), '2030-03-01', '2030-03-01 08:00 Europe/Berlin') -> 'planbilanz' as pbz \gset
select is(:'pbz'::jsonb ->> 'hinweis', 'SL012', '10 Planbilanz meldet SL012 (Stichtag hinter der Ferientabelle)');
select ok((select max(datum) from kind_termine where student_id = :'kz') <= (select max(bis) from ferien_nrw),
          '10 geplant wird höchstens bis zum Ende der Ferientabelle');
select ok((select count(*) from kind_termine where student_id = :'kz') > 0, '10 bis dorthin wird geplant');
select throws_ok(format($f$select stammplatz_vergeben(%L, %L, '2030-08-12', '2030-03-01 08:00 Europe/Berlin')$f$,
                        :'kz', pg_temp.zeilen('3:16:woechentlich')), 'SL012', null, '10 Stammplatz ab hinter der Ferientabelle -> SL012');
select throws_ok(format($f$select zusatztermin_buchen(%L, '2030-09-03', %L, '2030-03-01 08:00 Europe/Berlin')$f$,
                        :'kz', pg_temp.zeit(15)), 'SL012', null, '10 Zusatztermin hinter der Ferientabelle -> SL012');

select * from finish();
rollback;
