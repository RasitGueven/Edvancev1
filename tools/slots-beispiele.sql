-- slots-beispiele.sql — echtes JSON der Slot-Funktionen für docs/slots/datenvertrag-beispiele.md.
--
-- Nur gegen eine Wegwerf-DB (tools/slots-wegwerf-db.sh), läuft in einer Transaktion und rollt zurück:
--   bash tools/slots-wegwerf-db.sh sl1_beispiele
--   PGHOST=/tmp/claude-1000 PGPORT=55450 psql -X -q -t -A "dbname=sl1_beispiele user=postgres" -f tools/slots-beispiele.sql
--
-- Ausgangslage wie im Dummy: Montag, 13.03.2028, 09:12 Uhr. Alle Namen sind erfunden.
--   Coaches: Tom Berg (Raum 1), Jana Keller (Raum 2), beide Mo–Fr 15–18 Uhr; Paul Weber (Raum 3, Di und Do 16 Uhr).
--   Do 16.03. 16 Uhr: Jana Keller fällt aus -> 11 Kinder auf 10 Plätzen, eines ohne Raum.
--   Lena Hoffmann: von Di 14.03. auf Mi 15.03. umgebucht (rechtzeitig). Emir Yılmaz: Absage heute 07:55.
--   Noah Schmitt: Zusatztermin Fr 17.03. Jonas Köhler: Vertrag läuft, kein Stammplatz.
--   Efe Demir und Mara Kowalski: Vertrag ab 01.04. Weitere Kinder zeigen die Planbilanz-Arten.

begin;
\set jetzt '''2028-03-13 09:12 Europe/Berlin'''
select set_config('request.jwt.claim.role', 'service_role', true) \g /dev/null

insert into auth.users (id, email, instance_id, aud, role)
select ('aaaaaaaa-5100-4000-8000-00000000000' || n)::uuid, 'bsp' || n || '@edvance.invalid',
       '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated' from generate_series(1, 5) n;
insert into profiles (id, email, role, full_name) values
  ('aaaaaaaa-5100-4000-8000-000000000001', 'bsp1@edvance.invalid', 'admin', 'Admin Beispiel'),
  ('aaaaaaaa-5100-4000-8000-000000000002', 'bsp2@edvance.invalid', 'coach', 'Tom Berg'),
  ('aaaaaaaa-5100-4000-8000-000000000003', 'bsp3@edvance.invalid', 'coach', 'Jana Keller'),
  ('aaaaaaaa-5100-4000-8000-000000000004', 'bsp4@edvance.invalid', 'coach', 'Paul Weber'),
  ('aaaaaaaa-5100-4000-8000-000000000005', 'bsp5@edvance.invalid', 'coach', 'Selin Aydın');

select raum_anlegen(n, '2027-09-01', '2027-08-01 08:00 Europe/Berlin') from unnest(array['Raum 1', 'Raum 2', 'Raum 3']) n \g /dev/null
create function pg_temp.zeit(h int) returns uuid language sql as $$ select id from slot_zeiten where beginn = make_time(h, 0, 0) $$;
create function pg_temp.raum(n text) returns uuid language sql as $$ select id from raeume where name = n $$;
select count(*) from (
  select stammschicht_anlegen(c::uuid, w, pg_temp.zeit(h), pg_temp.raum(r), '2027-09-01', '2027-08-01 08:00 Europe/Berlin')
    from (values ('aaaaaaaa-5100-4000-8000-000000000002', 'Raum 1'), ('aaaaaaaa-5100-4000-8000-000000000003', 'Raum 2')) x(c, r),
         generate_series(1, 5) w, generate_series(15, 17) h
  union all
  select stammschicht_anlegen('aaaaaaaa-5100-4000-8000-000000000004', w, pg_temp.zeit(16), pg_temp.raum('Raum 3'), '2027-09-01', '2027-08-01 08:00 Europe/Berlin')
    from unnest(array[2, 4]) w) x \g /dev/null

create function pg_temp.kind(p_name text, p_paket text, p_laufzeit int, p_beginn date, p_stichtag date, p_fach text, p_klasse int)
returns uuid language plpgsql as $$
declare v_lead uuid; v_st uuid;
begin
  insert into leads (full_name, first_name, status, class_level) values (p_name, split_part(p_name, ' ', 1), 'vertrag', p_klasse)
  returning id into v_lead;
  insert into students (class_level) values (p_klasse) returning id into v_st;
  insert into vertraege (lead_id, status, vertrag_status, abgeschlossen_at, abgeschlossen_am, abschluss_weg, student_id, vertragsbeginn,
                         vertrag_ende, widerruf_bis, tier_id, laufzeit_monate, einheiten, fach, klasse, kind_vorname, kind_nachname)
  select v_lead, 'abgeschlossen', 'aktiv', now(), p_beginn - 20, 'vor_ort', v_st, p_beginn, p_stichtag, p_beginn + 13, t.id, p_laufzeit,
         tl.einheiten, p_fach, p_klasse, split_part(p_name, ' ', 1), split_part(p_name, ' ', 2)
    from tiers t join tier_laufzeiten tl on tl.tier_id = t.id and tl.laufzeit_monate = p_laufzeit where t.name = p_paket;
  return v_st;
end $$;
create function pg_temp.sp(p_student uuid, p_zeilen text, p_ab date) returns jsonb language sql as $$
  select stammplatz_vergeben(p_student,
           (select jsonb_agg(jsonb_build_object('wochentag', split_part(x, ':', 1)::int, 'slot_zeit_id', pg_temp.zeit(split_part(x, ':', 2)::int),
                                                'takt', split_part(x, ':', 3))) from unnest(string_to_array(p_zeilen, ',')) x),
           p_ab, (p_ab + time '08:00') at time zone 'Europe/Berlin')
$$;
create temp table k (name text primary key, id uuid);
insert into k values
  ('Lena Hoffmann',  pg_temp.kind('Lena Hoffmann',  'Standard', 12, '2027-09-01', '2028-08-31', 'Mathematik', 8)),
  ('Emir Yılmaz',    pg_temp.kind('Emir Yılmaz',    'Basic',    12, '2027-09-01', '2028-08-31', 'Mathematik', 9)),
  ('Noah Schmitt',   pg_temp.kind('Noah Schmitt',   'Premium',  12, '2027-09-01', '2028-08-31', 'Englisch', 10)),
  ('Jonas Köhler',   pg_temp.kind('Jonas Köhler',   'Basic',    12, '2028-02-01', '2029-01-31', 'Mathematik', 8)),
  ('Efe Demir',      pg_temp.kind('Efe Demir',      'Standard', 6,  '2028-04-01', '2028-11-30', 'Deutsch', 7)),
  ('Mara Kowalski',  pg_temp.kind('Mara Kowalski',  'Basic',    6,  '2028-04-01', '2028-11-30', 'Englisch', 8)),
  ('Ida Brandt',     pg_temp.kind('Ida Brandt',     'Basic',    6,  '2027-11-01', '2028-06-15', 'Mathematik', 8)),
  ('Ben Albers',     pg_temp.kind('Ben Albers',     'Basic',    12, '2028-03-01', '2029-02-28', 'Deutsch', 9));
insert into k select 'Do' || n, pg_temp.kind(case n when 1 then 'Mia Schulz' when 2 then 'Finn Wolf' when 3 then 'Lea Krüger'
                                      when 4 then 'Paul Neumann' when 5 then 'Sara Lang' when 6 then 'Tim Vogel'
                                      when 7 then 'Ela Kaya' when 8 then 'Luis Roth' when 9 then 'Jan Peters' else 'Nele Busch' end,
                                    'Basic', 12, '2027-09-01', '2028-08-31', case when n <= 5 then 'Mathematik' else 'Deutsch' end, 8)
  from generate_series(1, 10) n;

select count(*) from (
  select pg_temp.sp((select id from k where name = 'Lena Hoffmann'), '2:16:woechentlich,4:16:a_woche', '2028-01-10')
  union all select pg_temp.sp((select id from k where name = 'Emir Yılmaz'), '1:15:woechentlich', '2028-01-10')
  union all select pg_temp.sp((select id from k where name = 'Noah Schmitt'), '2:17:woechentlich,4:17:woechentlich', '2028-01-10')
  union all select pg_temp.sp((select id from k where name = 'Ida Brandt'), '2:15:woechentlich', '2027-11-01')
  union all select pg_temp.sp((select id from k where name = 'Ben Albers'), '3:17:woechentlich', '2028-03-01')
  union all select pg_temp.sp(id, '4:16:woechentlich', '2028-01-10') from k where name like 'Do%') x \g /dev/null

-- Abweichungen und Termin-Änderungen der Woche
select termin_coach_setzen('2028-03-16', pg_temp.zeit(16), pg_temp.raum('Raum 2'), null, :jetzt) \g /dev/null
select termin_coach_setzen('2028-03-14', pg_temp.zeit(17), pg_temp.raum('Raum 1'), 'aaaaaaaa-5100-4000-8000-000000000005', :jetzt) \g /dev/null
select termin_umbuchen((select id from kind_termine where student_id = (select id from k where name = 'Lena Hoffmann') and datum = '2028-03-14'),
                       '2028-03-13 08:30 Europe/Berlin', '2028-03-15', pg_temp.zeit(16), :jetzt) \g /dev/null
select termin_absagen((select id from kind_termine where student_id = (select id from k where name = 'Emir Yılmaz') and datum = '2028-03-13'),
                      '2028-03-13 07:55 Europe/Berlin', :jetzt) \g /dev/null
select zusatztermin_buchen((select id from k where name = 'Noah Schmitt'), '2028-03-17', pg_temp.zeit(15), :jetzt) \g /dev/null

\echo '### slots_woche'
select jsonb_pretty(slots_woche('2028-03-13', :jetzt));
\echo '### slots_termin'
select jsonb_pretty(slots_termin('2028-03-16', pg_temp.zeit(16), :jetzt));
\echo '### slots_tag'
select jsonb_pretty(slots_tag('2028-03-13', :jetzt));
\echo '### slots_zaehler'
select jsonb_pretty(slots_zaehler(:jetzt));
\echo '### slots_kinder'
select jsonb_pretty(slots_kinder(:jetzt));
\echo '### slots_kind'
select jsonb_pretty(slots_kind((select id from k where name = 'Lena Hoffmann'), :jetzt));
\echo '### slots_frei'
select jsonb_pretty(slots_frei('woechentlich', '2028-03-14', (select id from k where name = 'Jonas Köhler'), :jetzt));
\echo '### slots_planbilanz_vorschau'
select jsonb_pretty(slots_planbilanz_vorschau((select id from k where name = 'Jonas Köhler'),
  jsonb_build_array(jsonb_build_object('wochentag', 4, 'slot_zeit_id', pg_temp.zeit(16), 'takt', 'woechentlich'),
                    jsonb_build_object('wochentag', 4, 'slot_zeit_id', pg_temp.zeit(17), 'takt', 'a_woche')), '2028-03-14', null, :jetzt));
\echo '### slots_ziele'
select jsonb_pretty(slots_ziele((select id from k where name = 'Do1'),
  (select id from kind_termine where student_id = (select id from k where name = 'Do1') and datum = '2028-03-16'),
  '2028-03-15 18:40 Europe/Berlin', '2028-03-13', 1, :jetzt));
\echo '### slots_kandidaten'
select jsonb_pretty(slots_kandidaten('2028-03-17', pg_temp.zeit(16), :jetzt));
\echo '### slots_coaches'
select jsonb_pretty(slots_coaches('2028-03-13', :jetzt));
\echo '### slots_einstellungen'
select jsonb_pretty(slots_einstellungen(:jetzt));
\echo '### naechste_termine'
select jsonb_pretty(naechste_termine((select id from k where name = 'Ben Albers'), 3));
\echo '### termin_session_anlegen'
select jsonb_pretty(termin_session_anlegen('2028-03-13', pg_temp.zeit(15), pg_temp.raum('Raum 1'), :jetzt));
\echo '### meine_einsaetze'
select set_config('request.jwt.claim.role', 'authenticated', true), set_config('request.jwt.claim.sub', 'aaaaaaaa-5100-4000-8000-000000000002', true) \g /dev/null
select jsonb_pretty(meine_einsaetze('2028-03-13'));
rollback;
