-- ============================================================================
-- Slots SL1 — Kontrollwerte der Anforderung (Bauauftrag Slots, Tests 1–3).
--
--   1) K 60: sieben Fälle mit Terminzahl und Planbilanz, p_jetzt = Vertragsbeginn.
--   2) K 61: 10-Uhr-Regel (vier Fälle) und ein Termin am Montag nach der Zeitumstellung.
--   3) K 62: Wochengrenze und "schon ein Termin an dem Tag".
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

\ir slots_fixture.sql
select pg_temp.als(:'admin');

-- ── 1) K 60 ────────────────────────────────────────────────────────────────
create temp table k60 (fall int, paket text, laufzeit int, beginn date, stichtag date, zeilen jsonb,
                       termine int, art text, datum date, abweichung jsonb, student uuid, pb jsonb);
insert into k60 (fall, paket, laufzeit, beginn, stichtag, zeilen, termine, art, datum, abweichung) values
  (1, 'Basic',    6,  '2027-11-01', '2028-06-15', pg_temp.zeilen('2:16:woechentlich'), 27, 'reicht_bis', '2028-03-28', null),
  (2, 'Standard', 6,  '2027-11-01', '2028-06-15', pg_temp.zeilen('2:16:woechentlich'), 27, 'passt', null,
      '{"art": "ohne_termin", "zahl": 2}'),
  (3, 'Premium',  6,  '2027-11-01', '2028-06-15', pg_temp.zeilen('2:16:woechentlich', '4:16:a_woche'), 40, 'passt', '2028-05-30',
      '{"art": "ohne_einheit", "zahl": 2}'),
  (4, 'Basic',    12, '2027-09-01', '2028-08-31', pg_temp.zeilen('1:16:woechentlich'), 37, 'passt', null,
      '{"art": "ohne_termin", "zahl": 1}'),
  (5, 'Standard', 12, '2027-09-01', '2028-08-31', pg_temp.zeilen('2:16:woechentlich', '4:16:a_woche'), 58, 'passt', '2028-08-29',
      '{"art": "ohne_einheit", "zahl": 1}'),
  (6, 'Premium',  12, '2027-09-01', '2028-08-31', pg_temp.zeilen('2:16:woechentlich', '4:16:woechentlich'), 77, 'passt', '2028-08-29',
      '{"art": "ohne_einheit", "zahl": 1}'),
  (7, 'Basic',    6,  '2028-02-01', '2028-09-30', pg_temp.zeilen('3:16:woechentlich'), 27, 'reicht_bis', '2028-06-21', null);
update k60 set student = pg_temp.kind('K60 Fall' || fall, paket, laufzeit, beginn, stichtag);
update k60 set pb = stammplatz_vergeben(student, zeilen, beginn, (beginn + time '08:00') at time zone 'Europe/Berlin') -> 'planbilanz';

select results_eq($$select fall, (pb ->> 'terminzahl')::int from k60 order by fall$$,
                  $$select fall, termine from k60 order by fall$$, '1 K 60: Terminzahl aller sieben Fälle');
select results_eq($$select fall, pb ->> 'art' from k60 order by fall$$,
                  $$select fall, art from k60 order by fall$$, '1 K 60: Art der Planbilanz aller sieben Fälle');
select results_eq($$select fall, (pb ->> 'datum')::date from k60 where art = 'reicht_bis' order by fall$$,
                  $$values (1, date '2028-03-28'), (7, date '2028-06-21')$$, '1 K 60: reicht bis 28.03.2028 und 21.06.2028');
select results_eq($$select fall, (pb ->> 'letzter_termin')::date from k60 where datum is not null and art = 'passt' order by fall$$,
                  $$values (3, date '2028-05-30'), (5, date '2028-08-29'), (6, date '2028-08-29')$$,
                  '1 K 60: letzter Termin bei passt (30.05., 29.08., 29.08.)');
select results_eq($$select fall, pb -> 'abweichung' from k60 where abweichung is not null order by fall$$,
                  $$select fall, abweichung from k60 where abweichung is not null order by fall$$,
                  '1 K 60: Abweichungen innerhalb der Toleranz (2 ohne Termin, 2 ohne Einheit, 1, 1, 1)');
select is((select count(*)::int from kind_termine kt join k60 on k60.student = kt.student_id where k60.fall = 1),
          19, '1 K 60 Fall 1: genau 19 Termine gespeichert (so viele, wie das Budget hergibt)');
select is((select max(kt.datum) from kind_termine kt join k60 on k60.student = kt.student_id where k60.fall = 1),
          date '2028-03-28', '1 K 60 Fall 1: letzter gespeicherter Termin 28.03.2028');

-- ── 2) K 61: Termin Donnerstag, 16.03.2028, 16 Uhr ───────────────────────────
select pg_temp.kind('K61 Lina', 'Basic', 12, '2027-09-01', '2028-08-31') as k61 \gset
select stammplatz_vergeben(:'k61', pg_temp.zeilen('4:16:woechentlich'), '2028-03-01', '2028-03-01 08:00 Europe/Berlin') is not null;
\set jetzt '''2028-03-16 12:00 Europe/Berlin'''

select is(termin_absagen(pg_temp.termin(:'k61', '2028-03-16'), '2028-03-15 18:40 Europe/Berlin', :jetzt) ->> 'zustand',
          'cancelled', '2 K 61: Eingang Mi 18:40 -> abgesagt');
select is(einheit_verbraucht((select zustand from kind_termine where id = pg_temp.termin(:'k61', '2028-03-16'))), false,
          '2 K 61: Mi 18:40 -> Einheit bleibt offen');
select absage_zuruecknehmen(pg_temp.termin(:'k61', '2028-03-16'), :jetzt) is not null;
select is(termin_absagen(pg_temp.termin(:'k61', '2028-03-16'), '2028-03-16 09:59 Europe/Berlin', :jetzt) ->> 'zustand',
          'cancelled', '2 K 61: Eingang Do 09:59 -> abgesagt, Einheit bleibt offen');
select absage_zuruecknehmen(pg_temp.termin(:'k61', '2028-03-16'), :jetzt) is not null;
select is(termin_absagen(pg_temp.termin(:'k61', '2028-03-16'), '2028-03-16 10:00 Europe/Berlin', :jetzt) ->> 'zustand',
          'unexcused', '2 K 61: Eingang Do 10:00 -> unentschuldigt');
select is(einheit_verbraucht((select zustand from kind_termine where id = pg_temp.termin(:'k61', '2028-03-16'))), true,
          '2 K 61: Do 10:00 -> Einheit verbraucht');
select is(slot_belegt('2028-03-16', pg_temp.zeit(16)), slot_belegt('2028-03-16', pg_temp.zeit(16), :'k61'),
          '2 K 61: auch bei später Absage wird der Platz frei (das Kind belegt keinen Platz mehr)');

-- keine Absage, nicht erschienen: Session am Tag, Coach setzt "nicht erschienen".
select pg_temp.kind('K61 Ohne Absage', 'Basic', 12, '2027-09-01', '2028-08-31') as k61b \gset
select stammplatz_vergeben(:'k61b', pg_temp.zeilen('4:16:woechentlich'), '2028-03-01', '2028-03-01 08:00 Europe/Berlin') is not null;
select termin_session_anlegen('2028-03-16', pg_temp.zeit(16), pg_temp.raum('Raum 1'), :jetzt) ->> 'session_id' as s61 \gset
select pg_temp.als(:'coach_a');
select anwesenheit_setzen(:'s61', :'k61b', 'unexcused') is not null;
select pg_temp.als(:'admin');
select is((select zustand from kind_termine where id = pg_temp.termin(:'k61b', '2028-03-16')), 'unexcused',
          '2 K 61: keine Absage, nicht erschienen -> unentschuldigt (Spiegel aus der Session)');
select is(einheit_verbraucht('unexcused'), true, '2 K 61: nicht erschienen -> Einheit verbraucht');

-- Zeitumstellung: Sommerzeit ab So 26.03.2028. Termin Mo 27.03., Eingang 09:59 Sommerzeit (07:59 UTC).
select pg_temp.kind('K61 Sommerzeit', 'Basic', 12, '2027-09-01', '2028-08-31') as k61c \gset
select stammplatz_vergeben(:'k61c', pg_temp.zeilen('1:16:woechentlich'), '2028-03-01', '2028-03-01 08:00 Europe/Berlin') is not null;
select is(termin_absagen(pg_temp.termin(:'k61c', '2028-03-27'), '2028-03-27 07:59:00+00', '2028-03-27 12:00 Europe/Berlin') ->> 'zustand',
          'cancelled', '2 K 61: Mo 27.03.2028 (Sommerzeit), Eingang 09:59 -> abgesagt');
select absage_zuruecknehmen(pg_temp.termin(:'k61c', '2028-03-27'), '2028-03-27 12:00 Europe/Berlin') is not null;
select is(termin_absagen(pg_temp.termin(:'k61c', '2028-03-27'), '2028-03-27 08:00:00+00', '2028-03-27 12:00 Europe/Berlin') ->> 'zustand',
          'unexcused', '2 K 61: Mo 27.03.2028 (Sommerzeit), Eingang 10:00 -> unentschuldigt');
select throws_ok(format($f$select termin_absagen(%L, '2028-03-27 13:00 Europe/Berlin', '2028-03-27 12:00 Europe/Berlin')$f$,
                        pg_temp.termin(:'k61c', '2028-04-03')),
                 '22023', null, '2 Eingang in der Zukunft wird abgelehnt');

-- ── 3) K 62: 1× pro Woche, Stammplatz Dienstag; Woche 13.–17.03.2028 ─────────
select pg_temp.kind('K62 Mo', 'Basic', 12, '2027-09-01', '2028-08-31') as k62 \gset
select stammplatz_vergeben(:'k62', pg_temp.zeilen('2:16:woechentlich'), '2028-03-01', '2028-03-01 08:00 Europe/Berlin') is not null;
\set jetzt62 '''2028-03-13 09:12 Europe/Berlin'''
select lives_ok(format($f$select zusatztermin_buchen(%L, '2028-03-15', %L, %s)$f$, :'k62', pg_temp.zeit(15), :'jetzt62'),
                '3 K 62: erster Zusatztermin in der Woche (Mi)');
select lives_ok(format($f$select zusatztermin_buchen(%L, '2028-03-16', %L, %s)$f$, :'k62', pg_temp.zeit(15), :'jetzt62'),
                '3 K 62: zweiter Zusatztermin in der Woche (Do)');
select throws_ok(format($f$select zusatztermin_buchen(%L, '2028-03-17', %L, %s)$f$, :'k62', pg_temp.zeit(15), :'jetzt62'),
                 'SL004', null, '3 K 62: dritter Zusatztermin -> Wochengrenze erreicht');
select throws_ok(format($f$select zusatztermin_buchen(%L, '2028-03-14', %L, %s)$f$, :'k62', pg_temp.zeit(17), :'jetzt62'),
                 'SL003', null, '3 K 62: zweiter Termin am Dienstag -> schon ein Termin an dem Tag');

select * from finish();
rollback;
