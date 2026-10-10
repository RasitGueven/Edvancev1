-- ============================================================================
-- Slots SL1 — Abnahmefälle 2–13 und 15 der Anforderung auf Datenebene (Bauauftrag Slots, Test 4).
-- Ausgangslage wie im Dummy: Montag, 13.03.2028, 09:12 Uhr. Abnahmefall 1 und 14 sind Oberfläche (SL2).
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

\ir slots_fixture.sql
select pg_temp.als(:'admin');
\set jetzt '''2028-03-13 09:12 Europe/Berlin'''
\set ab '''2028-03-01 08:00 Europe/Berlin'''

-- Sieben Kinder am Donnerstag 16 Uhr (4 × Mathematik, 3 × Deutsch), zwei Räume mit Stammschicht.
create temp table do16 as
select n, pg_temp.kind('Do' || n || ' Kind', 'Basic', 12, '2027-09-01', '2028-08-31',
                       case when n <= 4 then 'Mathematik' else 'Deutsch' end) as student
  from generate_series(1, 7) n;
select count(*) from do16, lateral stammplatz_vergeben(student, pg_temp.zeilen('4:16:woechentlich'), '2028-03-01', :ab) x;

-- ── Abnahmefall 2: Coach in Raum 2 fällt aus ─────────────────────────────────
select is(slot_kapazitaet('2028-03-16', pg_temp.zeit(16)), 10, '2 vorher: zwei Räume mit Stammschicht, Kapazität 10');
select termin_coach_setzen('2028-03-16', pg_temp.zeit(16), pg_temp.raum('Raum 2'), null, :jetzt) is not null;
select slots_termin('2028-03-16', pg_temp.zeit(16), :jetzt) as t2 \gset
select is((:'t2'::jsonb ->> 'kapazitaet')::int, 5, '2 Kapazität sinkt um fünf');
select is(jsonb_array_length(:'t2'::jsonb -> 'ohne_raum'), 2, '2 überzählige Kinder stehen unter "Ohne Raum"');
select (c) as z2 from jsonb_array_elements(slots_woche('2028-03-13', :jetzt) -> 'zellen') c
 where c ->> 'datum' = '2028-03-16' and c ->> 'zeit_id' = pg_temp.zeit(16)::text \gset
select ok((:'z2'::jsonb ->> 'coach_fehlt')::int = 1 and (:'z2'::jsonb ->> 'belegt')::int > (:'z2'::jsonb ->> 'kapazitaet')::int,
          '2 Wochenplan: Zelle mit "Coach fehlt" und mehr Kindern als Plätzen');

-- ── Abnahmefall 3: Ausgefallen (durch uns) für ein Kind ohne Raum ─────────────
select (:'t2'::jsonb -> 'ohne_raum' -> 0 ->> 'termin_id') as t3 \gset
select termin_ausgefallen(:'t3', :jetzt) is not null;
select slots_termin('2028-03-16', pg_temp.zeit(16), :jetzt) as t3b \gset
select ok(exists (select 1 from jsonb_array_elements(:'t3b'::jsonb -> 'nicht_dabei') x
                   where x ->> 'termin_id' = :'t3' and x ->> 'zustand' = 'cancelled_by_us'),
          '3 der Termin steht unter "Nicht dabei" als ausgefallen');
select is(einheit_verbraucht((select zustand from kind_termine where id = :'t3')), false, '3 die Einheit bleibt offen');
select is(jsonb_array_length(:'t3b'::jsonb -> 'ohne_raum'), 1, '3 "Ohne Raum" hat ein Kind weniger');

-- ── Abnahmefall 4: Absage Do 09:59 / 10:00 ───────────────────────────────────
select student as k4 from do16 where n = 1 \gset
select is(termin_absagen(pg_temp.termin(:'k4', '2028-03-23'), '2028-03-23 09:59 Europe/Berlin', '2028-03-23 12:00 Europe/Berlin') ->> 'zustand',
          'cancelled', '4 Eingang Do 09:59 -> abgesagt, Einheit offen');
select absage_zuruecknehmen(pg_temp.termin(:'k4', '2028-03-23'), '2028-03-23 12:00 Europe/Berlin') is not null;
select is(termin_absagen(pg_temp.termin(:'k4', '2028-03-23'), '2028-03-23 10:00 Europe/Berlin', '2028-03-23 12:00 Europe/Berlin') ->> 'zustand',
          'unexcused', '4 Eingang Do 10:00 -> unentschuldigt, Einheit verbraucht');

-- ── Abnahmefall 5: Umbuchen zeigt nur gültige Ziele ──────────────────────────
-- Mi 15.03. 16 Uhr ist voll (Raum 2 geschlossen, fünf Kinder in Raum 1). Kind U: Stammplatz Di 16 Uhr,
-- Zusatztermin Fr 17.03. 15 Uhr.
create temp table mi16 as
select n, pg_temp.kind('Mi' || n || ' Kind', 'Basic', 12, '2027-09-01', '2028-08-31') as student from generate_series(1, 5) n;
select count(*) from mi16, lateral stammplatz_vergeben(student, pg_temp.zeilen('3:16:woechentlich'), '2028-03-01', :ab) x;
select termin_coach_setzen('2028-03-15', pg_temp.zeit(16), pg_temp.raum('Raum 2'), null, :jetzt) is not null;
select pg_temp.kind('Uma Umbuch', 'Basic', 12, '2027-09-01', '2028-08-31') as ku \gset
select stammplatz_vergeben(:'ku', pg_temp.zeilen('2:16:woechentlich'), '2028-03-01', :ab) is not null;
select zusatztermin_buchen(:'ku', '2028-03-17', pg_temp.zeit(15), :jetzt) is not null;
select slots_ziele(:'ku', pg_temp.termin(:'ku', '2028-03-14'), '2028-03-13 09:00 Europe/Berlin', '2028-03-13', 1, :jetzt) as z5 \gset
select ok(jsonb_array_length(:'z5'::jsonb -> 'ziele') > 0, '5 es gibt gültige Ziele');
select ok(not exists (select 1 from jsonb_array_elements(:'z5'::jsonb -> 'ziele') x
                       where x ->> 'datum' = '2028-03-15' and x ->> 'zeit_id' = pg_temp.zeit(16)::text),
          '5 kein Ziel ohne freien Platz (Mi 16 Uhr voll)');
select ok(not exists (select 1 from jsonb_array_elements(:'z5'::jsonb -> 'ziele') x where x ->> 'datum' = '2028-03-17'),
          '5 kein Ziel an einem Tag, an dem das Kind schon einen Termin hat (Fr)');
select ok(not exists (select 1 from jsonb_array_elements(:'z5'::jsonb -> 'ziele') x where (x ->> 'frei')::int < 1),
          '5 jedes Ziel hat einen freien Platz');
select ok(exists (select 1 from jsonb_array_elements(:'z5'::jsonb -> 'ziele') x
                   where x ->> 'datum' = '2028-03-15' and x ->> 'zeit_id' = pg_temp.zeit(15)::text),
          '5 Mi 15 Uhr ist ein gültiges Ziel');

-- ── Abnahmefall 6: 1× pro Woche mit schon drei Terminen ──────────────────────
select pg_temp.kind('Wim Woche', 'Basic', 12, '2027-09-01', '2028-08-31') as kw \gset
select stammplatz_vergeben(:'kw', pg_temp.zeilen('2:17:woechentlich'), '2028-03-01', :ab) is not null;
select zusatztermin_buchen(:'kw', '2028-03-15', pg_temp.zeit(17), :jetzt) is not null;
select zusatztermin_buchen(:'kw', '2028-03-16', pg_temp.zeit(17), :jetzt) is not null;
select is(jsonb_array_length(slots_ziele(:'kw', null, null, '2028-03-13', 1, :jetzt) -> 'ziele'), 0,
          '6 in der Woche wird kein weiterer Termin angeboten (Ziele)');
select ok(not exists (select 1 from jsonb_array_elements(slots_kandidaten('2028-03-17', pg_temp.zeit(15), :jetzt)) x
                       where x ->> 'student_id' = :'kw'), '6 und auch nicht als Kandidat im Termin');

-- ── Abnahmefall 7: Rücknahme einer Absage aus einer Umbuchung ────────────────
select termin_umbuchen(pg_temp.termin(:'ku', '2028-03-14'), '2028-03-13 09:00 Europe/Berlin', '2028-03-15', pg_temp.zeit(15), :jetzt)
       ->> 'termin_id' as neu7 \gset
select is((select zustand from kind_termine where id = pg_temp.termin(:'ku', '2028-03-14')), 'cancelled', '7 vorher: alter Termin abgesagt');
select absage_zuruecknehmen(pg_temp.termin(:'ku', '2028-03-14'), :jetzt) is not null;
select is((select zustand from kind_termine where id = pg_temp.termin(:'ku', '2028-03-14')), 'planned', '7 der alte Termin ist wieder geplant');
select is((select count(*)::int from kind_termine where id = :'neu7'), 0, '7 der neue Termin ist verschwunden');

-- ── Abnahmefall 8: laufender Vertrag ohne Stammplatz ─────────────────────────
select pg_temp.kind('Jonas Köhler', 'Basic', 12, '2027-09-01', '2028-08-31') as kj \gset
select (x) as k8 from jsonb_array_elements(slots_kinder(:jetzt)) x where x ->> 'student_id' = :'kj' \gset
select ok((:'k8'::jsonb ->> 'ohne_stammplatz')::boolean and (:'k8'::jsonb ->> 'vertrag_laeuft')::boolean
          and :'k8'::jsonb -> 'planbilanz' ->> 'art' = 'kein_stammplatz', '8 Kinder-Liste: ohne Stammplatz, Vertrag läuft (rot)');
select ok((slots_woche('2028-03-13', :jetzt) -> 'kopf' ->> 'ohne_stammplatz_laufend')::int >= 1, '8 die Kopfzeile zählt es mit');

-- ── Abnahmefall 9: Speichern gesperrt mit Grund ──────────────────────────────
select ok(exists (select 1 from jsonb_array_elements(slots_planbilanz_vorschau(:'kj', pg_temp.zeilen('3:16:woechentlich'),
                                                                               '2028-03-14', null, :jetzt) -> 'gruende') g
                   where g ->> 'code' = 'SL001'), '9 voller Slot (Mi 16 Uhr) -> Grund SL001');
select ok(exists (select 1 from jsonb_array_elements(slots_planbilanz_vorschau(:'kj', pg_temp.zeilen('1:16:woechentlich', '1:17:woechentlich'),
                                                                               '2028-03-14', null, :jetzt) -> 'gruende') g
                   where g ->> 'code' = 'SL008'), '9 zwei Stammplätze am selben Tag -> Grund SL008');
select throws_ok(format($f$select stammplatz_vergeben(%L, %L, '2028-03-14', %s)$f$, :'kj', pg_temp.zeilen('3:16:woechentlich'), :'jetzt'),
                 'SL001', null, '9 Speichern mit vollem Slot scheitert (SL001)');
select throws_ok(format($f$select stammplatz_vergeben(%L, %L, '2028-03-14', %s)$f$, :'kj',
                        pg_temp.zeilen('1:16:woechentlich', '1:17:woechentlich'), :'jetzt'),
                 'SL008', null, '9 Speichern mit zwei Stammplätzen am selben Tag scheitert (SL008)');

-- ── Abnahmefall 10: Basic Halbjahr ab 01.11.2027, Dienstag wöchentlich ───────
select pg_temp.kind('Zoe Basic', 'Basic', 6, '2027-11-01', '2028-06-15') as kz \gset
select is(slots_planbilanz_vorschau(:'kz', pg_temp.zeilen('2:15:woechentlich'), '2027-11-01', null,
                                    '2027-11-01 08:00 Europe/Berlin') -> 'planbilanz' ->> 'datum',
          '2028-03-28', '10 Vorschau: reicht bis 28.03.');
select is(stammplatz_vergeben(:'kz', pg_temp.zeilen('2:15:woechentlich'), '2027-11-01', '2027-11-01 08:00 Europe/Berlin')
          -> 'planbilanz' ->> 'datum', '2028-03-28', '10 nach dem Speichern: reicht bis 28.03.');

-- ── Abnahmefall 11: Stammplatz ab einem Datum ändern ────────────────────────
select pg_temp.kind('Ali Ändern', 'Basic', 12, '2027-09-01', '2028-08-31') as ka \gset
select stammplatz_vergeben(:'ka', pg_temp.zeilen('2:14:woechentlich'), '2028-03-01', :ab) -> 'stammplatz_ids' ->> 0 as sp11 \gset
create temp table vor11 as select id, datum from kind_termine where student_id = :'ka' and datum < '2028-04-25';
select stammplatz_aendern(:'sp11', '2028-04-25', 4, pg_temp.zeit(17), 'woechentlich', :jetzt) is not null;
select set_eq($$select id, datum from kind_termine where student_id = $$ || quote_literal(:'ka') || $$ and datum < '2028-04-25'$$,
              $$select id, datum from vor11$$, '11 die Termine davor bleiben unverändert (gleiche Zeilen)');
select ok(not exists (select 1 from kind_termine kt where kt.student_id = :'ka' and kt.datum >= '2028-04-25'
                       and (extract(isodow from kt.datum) <> 4 or kt.slot_zeit_id <> pg_temp.zeit(17)))
          and exists (select 1 from kind_termine kt where kt.student_id = :'ka' and kt.datum >= '2028-04-25'),
          '11 die Termine danach liegen auf dem neuen Slot (Do 17 Uhr)');
select ok(exists (select 1 from jsonb_array_elements(slots_kind(:'ka', '2028-04-26 09:00 Europe/Berlin') -> 'fruehere_stammplaetze') x
                   where x ->> 'id' = :'sp11'), '11 der alte Stammplatz steht als Historie in der Termin-Übersicht');

-- ── Abnahmefall 12: Zusatztermin, obwohl alle offenen Einheiten verplant sind ─
select (x ->> 'verdraengt') as v12 from jsonb_array_elements(slots_kandidaten('2028-03-15', pg_temp.zeit(15), :jetzt)) x
 where x ->> 'student_id' = :'kz' \gset
select is(:'v12'::text, '2028-03-28', '12 vorher: das System nennt den Termin, der wegfällt (28.03.)');
select is(zusatztermin_buchen(:'kz', '2028-03-15', pg_temp.zeit(15), :jetzt) -> 'verdraengt', '["2028-03-28"]'::jsonb,
          '12 Buchen meldet den verdrängten Termin');
select is((select count(*)::int from kind_termine where student_id = :'kz' and datum = '2028-03-28'), 0,
          '12 danach fehlt der letzte Stammplatz-Termin vor dem Stichtag');

-- ── Abnahmefall 13: Stammschicht doppelt ─────────────────────────────────────
select throws_ok(format($f$select stammschicht_anlegen(%L, 2, %L, %L, null, %s)$f$, :'coach_c', pg_temp.zeit(16),
                        pg_temp.raum('Raum 1'), :'jetzt'), 'SL009', null, '13 Raum doppelt belegt -> abgelehnt');
select throws_ok(format($f$select stammschicht_anlegen(%L, 2, %L, %L, null, %s)$f$, :'coach_a', pg_temp.zeit(16),
                        pg_temp.raum('Raum 3'), :'jetzt'), 'SL009', null, '13 Coach zweimal zur selben Zeit -> abgelehnt');
select lives_ok(format($f$select stammschicht_anlegen(%L, 2, %L, %L, null, %s)$f$, :'coach_c', pg_temp.zeit(16),
                       pg_temp.raum('Raum 3'), :'jetzt'), '13 freier Raum, freier Coach -> angelegt');

-- ── Abnahmefall 15: Feiertag und Pfingstferientag ────────────────────────────
select pg_temp.kind('Fia Feiertag', 'Standard', 12, '2027-09-01', '2028-08-31') as kf \gset
select stammplatz_vergeben(:'kf', pg_temp.zeilen('2:18:woechentlich', '4:18:woechentlich'), '2028-03-01', :ab) is not null;
select is((select count(*)::int from kind_termine where student_id = :'kf' and datum = '2028-06-06'), 0,
          '15 Pfingstferientag (Di 06.06.2028): kein Termin');
select is((select count(*)::int from kind_termine where student_id = :'kf' and datum = '2028-05-25'), 0,
          '15 Christi Himmelfahrt (Do 25.05.2028): kein Termin');
select is((select count(*)::int from kind_termine where student_id = :'kf' and datum in ('2028-05-30', '2028-06-13')), 2,
          '15 die Dienstage davor und danach haben Termine');

select * from finish();
rollback;
