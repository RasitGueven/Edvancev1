-- ============================================================================
-- SF-1 · S1 (Migrationen 20261113082727_sf1_schulformen_kurs, 20261113082851_sf1_schulen)
--   A) Schulform „Sekundarschule“ in schulen, leads, students; „Primusschule“ nicht.
--   B) Schulnummer: sechs Ziffern, eindeutig; die 46 amtlichen Schulen sind da (Datenmigration).
--   C) kind_kurs nur anhängen; kind_kurs_aktuell liefert den neuesten gültigen Stand, vor dem Vertrag den Lead.
--   D) Übernahme vom Lead beim Vertragsabschluss (converted_student_id).
--   E) Rechte: Admin schreibt/liest, Coach liest nur aktive Kinder, Kind nie.
-- Am Ende rollback.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(39);

\set admin '5f100000-0000-4000-8000-0000000000a1'
\set coach '5f100000-0000-4000-8000-0000000000c1'
\set kindp '5f100000-0000-4000-8000-0000000000d1'
insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin', 'sf1-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach', 'sf1-coach@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'kindp', 'sf1-kind@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values
  (:'admin', 'sf1-admin@test.local', 'admin', 'SF1 Admin'),
  (:'coach', 'sf1-coach@test.local', 'coach', 'SF1 Coach'),
  (:'kindp', 'sf1-kind@test.local', 'student', 'SF1 Kind');

create function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;
create function pg_temp.system() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', '', true);
end $$;
-- SQLSTATE eines Aufrufs, 'ok' wenn er durchläuft.
create function pg_temp.fehler(p_sql text) returns text language plpgsql as $$
declare s text;
begin
  execute p_sql;
  return 'ok';
exception when others then
  get stacked diagnostics s = returned_sqlstate;
  return s;
end $$;

-- Fixture: ein Kind mit laufendem Vertrag (aktiv), eins ohne, ein provisorisches mit Lead.
create function pg_temp.kind_aktiv(p_name text) returns uuid language plpgsql as $$
declare v_lead uuid; v_st uuid;
begin
  insert into leads (full_name, status, class_level, ist_test) values (p_name, 'vertrag', 9, true) returning id into v_lead;
  insert into students (class_level, ist_test) values (9, true) returning id into v_st;
  update leads set converted_student_id = v_st where id = v_lead;
  insert into vertraege (lead_id, status, vertrag_status, abgeschlossen_at, abgeschlossen_am, abschluss_weg,
                         student_id, vertragsbeginn, vertrag_ende, widerruf_bis)
  values (v_lead, 'abgeschlossen', 'aktiv', now(), date_trunc('month', current_date)::date - 31, 'vor_ort', v_st,
          date_trunc('month', current_date - 31)::date,
          (date_trunc('month', current_date) + interval '7 month' - interval '1 day')::date, current_date - 16);
  return v_st;
end $$;
select pg_temp.kind_aktiv('SF1 Aktiv') as aktiv \gset
insert into students (class_level, ist_test) values (9, true) returning id as ohne \gset
insert into leads (full_name, status, class_level, school_type, kurs_mathe, abschlussziel, ist_test)
values ('SF1 Lead', 'lsa_freigegeben', 9, 'Gesamtschule', 'E', 'MSA', true) returning id as lead \gset
select set_config('edvance.allow_provisional', '1', true);
insert into students (class_level, is_provisional, lead_id, ist_test) values (9, true, :'lead', true) returning id as prov \gset
select set_config('edvance.allow_provisional', '', true);

-- ============================================================================
-- A · Schulformen
-- ============================================================================
select is(pg_temp.fehler($$insert into schulen (name, ort, schulform) values ('SF1 Sek', 'Köln', 'Sekundarschule')$$),
          'ok', 'A schulen: Sekundarschule zulässig');
select is(pg_temp.fehler($$insert into schulen (name, ort, schulform) values ('SF1 Primus', 'Köln', 'Primusschule')$$),
          '23514', 'A schulen: Primusschule abgewiesen');
select is(pg_temp.fehler($$insert into leads (full_name, school_type, ist_test) values ('SF1 L', 'Sekundarschule', true)$$),
          'ok', 'A leads: Sekundarschule zulässig');
select is(pg_temp.fehler($$insert into students (school_type, ist_test) values ('Sekundarschule', true)$$),
          'ok', 'A students: Sekundarschule zulässig');
select is(pg_temp.fehler($$insert into students (school_type, ist_test) values ('Primusschule', true)$$),
          '23514', 'A students: Primusschule abgewiesen');
select is(pg_temp.fehler($$update leads set kurs_mathe = 'X' where full_name = 'SF1 Lead'$$),
          '23514', 'A leads.kurs_mathe nur E/G');
select is(pg_temp.fehler($$update leads set abschlussziel = 'ABI' where full_name = 'SF1 Lead'$$),
          '23514', 'A leads.abschlussziel nur EESA/MSA/MSA-Q/GYM');

-- ============================================================================
-- B · Schulnummer und Schulen
-- ============================================================================
select is(pg_temp.fehler($$insert into schulen (name, schulnummer) values ('SF1 Nr', '12345')$$),
          '23514', 'B Schulnummer: sechs Ziffern');
select is(pg_temp.fehler($$insert into schulen (name, ort, schulnummer) values ('SF1 Doppelt', 'Köln', '183726')$$),
          '23505', 'B Schulnummer eindeutig');
select is((select count(*)::int from schulen where schulnummer is not null), 46, 'B 46 Schulen mit Schulnummer');
select is((select count(*)::int from schulen where schulnummer is not null and schulform = 'Realschule' and ort = 'Köln'),
          20, 'B Köln: 20 Realschulen');
select is((select count(*)::int from schulen where schulnummer is not null and schulform = 'Gesamtschule' and ort = 'Köln'),
          25, 'B Köln: 25 Gesamtschulen');
select is((select name from schulen where ort = 'Kerpen' and schulform = 'Gesamtschule'),
          'Willy-Brandt-Gesamtschule Kerpen', 'B Kerpen: Willy-Brandt-Gesamtschule');
select is((select schulform from schulen where schulnummer = '183726'), 'Gesamtschule', 'B IGS Holweide angelegt');
select is((select count(*)::int from schulen where schulform = 'Gymnasium'), 43, 'B Gymnasien unverändert (43)');
-- Datenmigration ein zweites Mal: nichts doppelt.
\ir ../migrations/20261113082851_sf1_schulen.sql
select is((select count(*)::int from schulen where schulnummer is not null), 46, 'B zweiter Lauf: weiter 46');

-- ============================================================================
-- C · kind_kurs: nur anhängen, aktueller Stand
-- ============================================================================
select pg_temp.act_as(:'admin');
set local role authenticated;
select is(pg_temp.fehler(format($$insert into kind_kurs (student_id, fach, kurs, abschlussziel, ab_datum, erfasst_am)
                                  values (%L, 'mathematik', 'G', 'EESA', current_date - 100, '2020-01-01')$$, :'aktiv')),
          'ok', 'C Admin legt eine Zeile an');
select is(pg_temp.fehler(format($$insert into kind_kurs (student_id, fach, kurs, abschlussziel, ab_datum)
                                  values (%L, 'mathematik', 'E', 'MSA', current_date - 10)$$, :'aktiv')),
          'ok', 'C Admin legt den Kurswechsel an');
select is(pg_temp.fehler(format($$insert into kind_kurs (student_id, fach, kurs, ab_datum)
                                  values (%L, 'mathematik', 'G', current_date + 30)$$, :'aktiv')),
          'ok', 'C Admin legt einen künftigen Wechsel an');
select is(pg_temp.fehler(format($$insert into kind_kurs (student_id, fach) values (%L, 'mathematik')$$, :'aktiv')),
          '23514', 'C leere Zeile abgewiesen');
select is(pg_temp.fehler(format($$insert into kind_kurs (student_id, fach, kurs, erfasst_von)
                                  values (%L, 'mathematik', 'E', %L)$$, :'aktiv', :'coach')),
          '42501', 'C erfasst_von muss der Admin selbst sein');
select is((select count(*)::int from kind_kurs where student_id = :'aktiv' and erfasst_am < now() - interval '1 minute'),
          0, 'C erfasst_am setzt die Datenbank');
select is((select kurs || '/' || abschlussziel || '/' || quelle from kind_kurs_aktuell(:'aktiv', 'Mathematik')),
          'E/MSA/kind', 'C aktueller Stand: Kurswechsel, nicht der künftige');
select is((select count(*)::int from kind_kurs where student_id = :'aktiv'), 3, 'C Verlauf: drei Zeilen');
reset role;
select is(pg_temp.fehler(format($$update kind_kurs set kurs = 'G' where student_id = %L$$, :'aktiv')),
          '42501', 'C UPDATE verboten (auch ohne RLS)');
select is(pg_temp.fehler(format($$delete from kind_kurs where student_id = %L$$, :'aktiv')),
          '42501', 'C DELETE verboten (auch ohne RLS)');

-- Vor dem Vertrag: Stand am Lead (als Admin; ohne Rolle 42501).
select pg_temp.system();
select is(pg_temp.fehler(format($$select * from kind_kurs_aktuell(%L, 'mathematik')$$, :'prov')),
          '42501', 'C ohne Rolle: kind_kurs_aktuell 42501');
select pg_temp.act_as(:'admin');
select is((select kurs || '/' || abschlussziel || '/' || quelle from kind_kurs_aktuell(:'prov', 'mathematik')),
          'E/MSA/lead', 'C provisorisches Kind: Stand vom Lead');
select is((select count(*)::int from kind_kurs_aktuell(:'ohne', 'mathematik')), 0, 'C ohne Angaben: keine Zeile');
select pg_temp.system();

-- ============================================================================
-- D · Übernahme beim Vertragsabschluss
-- ============================================================================
update leads set converted_student_id = :'prov', status = 'converted' where id = :'lead';
select is((select count(*)::int from kind_kurs where student_id = :'prov' and fach = 'mathematik'
             and kurs = 'E' and abschlussziel = 'MSA'), 1, 'D Lead-Stand wird erste Verlaufszeile');
update leads set converted_student_id = null where id = :'lead';
update leads set converted_student_id = :'prov' where id = :'lead';
select is((select count(*)::int from kind_kurs where student_id = :'prov'), 1, 'D kein zweites Mal');

-- ============================================================================
-- E · Rechte
-- ============================================================================
select pg_temp.act_as(:'coach');
set local role authenticated;
select is((select count(*)::int from kind_kurs where student_id = :'aktiv'), 3, 'E Coach liest aktives Kind');
select is((select count(*)::int from kind_kurs where student_id = :'prov'), 0, 'E Coach liest Kind ohne Vertrag nicht');
select is(pg_temp.fehler(format($$insert into kind_kurs (student_id, fach, kurs) values (%L, 'mathematik', 'E')$$,
                                :'aktiv')), '42501', 'E Coach schreibt nicht');
select is((select kurs from kind_kurs_aktuell(:'aktiv', 'mathematik')), 'E', 'E Coach: kind_kurs_aktuell aktives Kind');
select is(pg_temp.fehler(format($$select * from kind_kurs_aktuell(%L, 'mathematik')$$, :'ohne')),
          '42501', 'E Coach: kind_kurs_aktuell ohne aktive Akte 42501');
reset role;
select pg_temp.act_as(:'kindp');
set local role authenticated;
select is((select count(*)::int from kind_kurs), 0, 'E Kind liest nichts');
select is(pg_temp.fehler(format($$select * from kind_kurs_aktuell(%L, 'mathematik')$$, :'aktiv')),
          '42501', 'E Kind: kind_kurs_aktuell 42501');
reset role;
select pg_temp.system();

-- Kind löschen: der Verlauf geht per Kaskade mit (kein Blockieren durch „nur anhängen“).
delete from vertraege where student_id = :'aktiv';
update leads set converted_student_id = null where converted_student_id = :'aktiv';
select is(pg_temp.fehler(format($$delete from students where id = %L$$, :'aktiv')), 'ok', 'E Kaskade beim Löschen des Kindes');

select * from finish();
rollback;
