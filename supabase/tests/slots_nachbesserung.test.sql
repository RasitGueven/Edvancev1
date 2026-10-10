-- ============================================================================
-- Slots SL1 — Nachbesserungen aus dem Consensus-Check (Migration 20261013125413).
--   1  "fällt aus" löscht keine Session mit Interventionen (sonst gingen sie per CASCADE verloren).
--   2  Rücknahme prüft Wochengrenze und Einzel-Session am Tag (SL010).
--   3  Ein ausgelassenes Kind (ZG001) wird neu geplant.
--   4  Rücknahme einer festgeschriebenen Umbuchung: die neue Zeile bleibt als cancelled_by_us.
--   5  termin_coach_setzen hinter der Ferientabelle: SL012.
--   7  Spiegel-Trigger: umgehängte Buchung löst kind_termine.session_id.
--   8  service_role schreibt nicht direkt in die Slot-Tabellen.
--  12  slot_zeit_anlegen: keine zweite Uhrzeit mit gleichem Beginn, solange die erste gilt.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

\ir slots_fixture.sql
select pg_temp.als(:'admin');
\set jetzt '''2028-03-13 09:12 Europe/Berlin'''

-- ── 1 ────────────────────────────────────────────────────────────────────────
select pg_temp.kind('Ina Intervention', 'Basic', 12, '2027-09-01', '2028-08-31') as ki \gset
select stammplatz_vergeben(:'ki', pg_temp.zeilen('4:18:woechentlich'), '2028-03-01', '2028-03-01 08:00 Europe/Berlin') is not null;
select termin_session_anlegen('2028-03-16', pg_temp.zeit(18), pg_temp.raum('Raum 1'), '2028-03-16 12:00 Europe/Berlin') ->> 'session_id' as si \gset
insert into interventions (session_id, student_id, coach_id, note) values (:'si', :'ki', :'coach_a', 'ZZ Notiz vor dem Start');
select throws_ok(format($f$select termin_coach_setzen('2028-03-16', %L, %L, null, '2028-03-16 12:00 Europe/Berlin')$f$,
                        pg_temp.zeit(18), pg_temp.raum('Raum 1')), 'SL011', null, '1 fällt aus: Session mit Intervention -> SL011');
select is((select count(*)::int from interventions where session_id = :'si'), 1, '1 die Intervention ist noch da');

-- ── 2 ────────────────────────────────────────────────────────────────────────
-- 1× pro Woche, Di; Absage Di, dann zwei Zusatztermine (Mi, Do): Rücknahme wäre der vierte Termin.
select pg_temp.kind('Rolf Rücknahme', 'Basic', 12, '2027-09-01', '2028-08-31') as kr \gset
select stammplatz_vergeben(:'kr', pg_temp.zeilen('2:17:woechentlich'), '2028-03-01', '2028-03-01 08:00 Europe/Berlin') is not null;
select termin_absagen(pg_temp.termin(:'kr', '2028-03-14'), '2028-03-13 09:00 Europe/Berlin', :jetzt) is not null;
select zusatztermin_buchen(:'kr', '2028-03-15', pg_temp.zeit(17), :jetzt) is not null;
select zusatztermin_buchen(:'kr', '2028-03-16', pg_temp.zeit(17), :jetzt) is not null;
select zusatztermin_buchen(:'kr', '2028-03-17', pg_temp.zeit(17), :jetzt) is not null;
select throws_ok(format('select absage_zuruecknehmen(%L, %s)', pg_temp.termin(:'kr', '2028-03-14'), :'jetzt'),
                 'SL010', null, '2 Rücknahme über die Wochengrenze -> SL010');
-- Einzel-Session am Tag der Absage
select termin_absagen(pg_temp.termin(:'kr', '2028-03-21'), '2028-03-13 09:00 Europe/Berlin', :jetzt) is not null;
insert into coaching_sessions (coach_id, room, scheduled_at) values (:'coach_c', 'Einzelraum', '2028-03-21 15:00 Europe/Berlin')
returning id as se \gset
insert into session_students (session_id, student_id) values (:'se', :'kr');
select throws_ok(format('select absage_zuruecknehmen(%L, %s)', pg_temp.termin(:'kr', '2028-03-21'), :'jetzt'),
                 'SL010', null, '2 Rücknahme an einem Tag mit Einzel-Session -> SL010');

-- ── 3 ────────────────────────────────────────────────────────────────────────
-- Mi 15.03. 18 Uhr: fünf Kinder in Raum 1 (festgeschrieben), Gina in Raum 2. Ginas Kündigung zum 15.03. ist
-- erfasst, die Planung noch nicht nachgezogen. Nach einer Absage in Raum 1 setzt der Admin Gina dorthin:
-- termin_raum_setzen trägt sie in die Session nach, lässt sie aus (ZG001) und plant sie neu.
create temp table mi18 as
select n, pg_temp.kind('Mi18 ' || n, 'Basic', 12, '2027-09-01', '2028-08-31') as student from generate_series(1, 5) n;
select count(*) from mi18, lateral stammplatz_vergeben(student, pg_temp.zeilen('3:18:woechentlich'), '2028-03-01',
                                                       '2028-03-01 08:00 Europe/Berlin') x;
select pg_temp.kind('Gina Gekündigt', 'Basic', 12, '2027-09-01', '2028-08-31') as kg \gset
select stammplatz_vergeben(:'kg', pg_temp.zeilen('3:18:woechentlich'), '2028-03-01', '2028-03-01 08:00 Europe/Berlin') is not null;
select termin_session_anlegen('2028-03-15', pg_temp.zeit(18), pg_temp.raum('Raum 1'), '2028-03-15 12:00 Europe/Berlin') is not null;
select is((select raum_id from slot_zuteilung('2028-03-15', pg_temp.zeit(18)) where student_id = :'kg'), pg_temp.raum('Raum 2'),
          '3 Vorbedingung: Gina sitzt in Raum 2 (nicht festgeschrieben)');
alter table vertraege disable trigger vertraege_slots_trg;
update vertraege set gekuendigt_zum = '2028-03-15', kuendigung_grund = 'Umzug' where id = pg_temp.vertrag(:'kg');
alter table vertraege enable trigger vertraege_slots_trg;
select termin_absagen(pg_temp.termin((select student from mi18 where n = 1), '2028-03-15'), '2028-03-15 08:00 Europe/Berlin',
                      '2028-03-15 12:00 Europe/Berlin') is not null;
select termin_raum_setzen(pg_temp.termin(:'kg', '2028-03-15'), pg_temp.raum('Raum 1'), '2028-03-15 12:00 Europe/Berlin') is not null;
select is((select zustand from kind_termine where id = pg_temp.termin(:'kg', '2028-03-15')), 'cancelled_by_us', '3 ausgelassen (ZG001)');
select is((select count(*)::int from kind_termine where student_id = :'kg' and datum > '2028-03-15'), 0,
          '3 das ausgelassene Kind ist neu geplant (keine Termine nach der Kündigung)');

-- ── 4 ────────────────────────────────────────────────────────────────────────
select pg_temp.kind('Uli Umbuchung', 'Basic', 12, '2027-09-01', '2028-08-31') as ku \gset
select stammplatz_vergeben(:'ku', pg_temp.zeilen('5:17:woechentlich'), '2028-03-01', '2028-03-01 08:00 Europe/Berlin') is not null;
select termin_umbuchen(pg_temp.termin(:'ku', '2028-03-24'), '2028-03-16 08:00 Europe/Berlin', '2028-03-16', pg_temp.zeit(19),
                       '2028-03-16 09:00 Europe/Berlin') ->> 'termin_id' as neu4 \gset
select termin_session_anlegen('2028-03-16', pg_temp.zeit(19), pg_temp.raum('Raum 1'), '2028-03-16 12:00 Europe/Berlin') is not null;
select absage_zuruecknehmen(pg_temp.termin(:'ku', '2028-03-24'), '2028-03-16 12:30 Europe/Berlin') is not null;
select results_eq(format($$select kt.zustand, ss.attendance from kind_termine kt
                           join session_students ss on ss.session_id = kt.session_id and ss.student_id = kt.student_id where kt.id = %L$$, :'neu4'),
                  $$values ('cancelled_by_us'::text, 'cancelled_by_us'::text)$$,
                  '4 festgeschriebene Umbuchung: Zeile bleibt, beide Tabellen cancelled_by_us');

-- ── 5 ────────────────────────────────────────────────────────────────────────
select throws_ok(format($f$select termin_coach_setzen('2030-09-03', %L, %L, null, %s)$f$, pg_temp.zeit(16), pg_temp.raum('Raum 1'), :'jetzt'),
                 'SL012', null, '5 termin_coach_setzen hinter der Ferientabelle -> SL012');
select throws_ok(format($f$select termin_faellt_aus('2030-09-03', %L, %s)$f$, pg_temp.zeit(16), :'jetzt'),
                 'SL012', null, '5 termin_faellt_aus hinter der Ferientabelle -> SL012');

-- ── 7 ────────────────────────────────────────────────────────────────────────
select set_config('request.jwt.claim.role', 'service_role', true);
update session_students set session_id = :'se' where session_id = :'si' and student_id = :'ki';
select pg_temp.als(:'admin');
select is((select session_id from kind_termine where id = pg_temp.termin(:'ki', '2028-03-16')), null,
          '7 umgehängte Buchung: kind_termine.session_id ist leer');

-- ── 8 ────────────────────────────────────────────────────────────────────────
select ok(not exists (select 1 from information_schema.role_table_grants
                       where grantee = 'service_role' and privilege_type in ('INSERT', 'UPDATE', 'DELETE')
                         and table_name in ('slot_zeiten', 'raeume', 'stammschichten', 'schicht_abweichungen',
                                            'slot_rhythmus', 'stammplaetze', 'kind_termine')),
          '8 service_role hat keine Schreibrechte auf den Slot-Tabellen');

-- ── 12 ───────────────────────────────────────────────────────────────────────
select slot_zeit_deaktivieren(pg_temp.zeit(19), '2028-06-01', :jetzt);
select throws_ok(format($f$select slot_zeit_anlegen('19:00', '2028-04-01', %s)$f$, :'jetzt'), '22023', null,
                 '12 Uhrzeit mit gleichem Beginn, solange die alte noch gilt -> abgelehnt');
select lives_ok(format($f$select slot_zeit_anlegen('19:00', '2028-06-01', %s)$f$, :'jetzt'),
                '12 ab dem Ende der alten Uhrzeit geht es');

select * from finish();
rollback;
