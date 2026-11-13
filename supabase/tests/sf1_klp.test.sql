-- ============================================================================
-- SF-1 · S2 (Migrationen 20261113153241_sf1_klp_themenplan, 20261113153302_sf1_pakete_klp)
--   A) klp_themenplan: Daten je Schulform, Fassung und Doppeljahrgang; Gymnasien 'g9' Kl. 7–10.
--   B) skill_schulform / skill_zulaessig: G9-Skills für RS/GE/SK gesperrt, G-Kurs-Einschränkungen.
--   C) Pakete: Schule ohne Plan bekommt Quelle 'klp', Fassung nach Klasse und Schuljahr, Doppeljahrgang linear.
--   D) Bestätigte Klassenarbeiten gehen vor; Schule mit Plan unverändert 'geschaetzt'; ohne Schulform keine Pakete.
--   E) Paket-Skills ohne gesperrte Skills; Speicher nimmt 'klp' an.
--   F) Rechte: Admin und Coach lesen, Kind nicht, niemand schreibt.
-- Am Ende rollback.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(37);

\set admin '5f200000-0000-4000-8000-0000000000a1'
\set coach '5f200000-0000-4000-8000-0000000000c1'
\set kindp '5f200000-0000-4000-8000-0000000000d1'
\set ge    '5f200000-0000-4000-8000-0000000000e1'
\set rs    '5f200000-0000-4000-8000-0000000000e2'
\set gy    '5f200000-0000-4000-8000-0000000000e3'
\set gyp   '5f200000-0000-4000-8000-0000000000e4'
\set leer  '5f200000-0000-4000-8000-0000000000e5'
insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin', 'sf1s2-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach', 'sf1s2-coach@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'kindp', 'sf1s2-kind@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values
  (:'admin', 'sf1s2-admin@test.local', 'admin', 'SF1 Admin'),
  (:'coach', 'sf1s2-coach@test.local', 'coach', 'SF1 Coach'),
  (:'kindp', 'sf1s2-kind@test.local', 'student', 'SF1 Kind');

create function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;
create function pg_temp.system() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', '', true);
end $$;
create function pg_temp.fehler(p_sql text) returns text language plpgsql as $$
declare s text;
begin
  execute p_sql;
  return 'ok';
exception when others then
  get stacked diagnostics s = returned_sqlstate;
  return s;
end $$;

-- A · Daten -------------------------------------------------------------------
select is((select count(*)::int from (
             select distinct schulform, klp_fassung, doppeljahrgang from klp_themenplan
              where schulform <> 'Gymnasium') x), 12,
          'A je RS/GE/SK × 2004/2022 × 7/8, 9/10 Zeilen');
select is((select array_agg(distinct doppeljahrgang order by doppeljahrgang) from klp_themenplan where klp_fassung = 'g9'),
          array['10', '7', '8', '9'], 'A Gymnasium g9 für Kl. 7–10');
select is((select count(*)::int from klp_themenplan where fundstelle is null or btrim(fundstelle) = ''), 0,
          'A jede Zeile mit Fundstelle');
select is((select count(*)::int from (
             select schulform, klp_fassung, doppeljahrgang, kurs, thema_key from klp_themenplan where schulform = 'Gesamtschule'
             except select 'Gesamtschule', klp_fassung, doppeljahrgang, kurs, thema_key from klp_themenplan
              where schulform = 'Sekundarschule') x), 0, 'A Sekundarschule hat dieselben Zeilen wie die Gesamtschule');
select ok(not exists (select 1 from klp_themenplan where klp_fassung = '2004' and thema_key = 'bedingte_wahrscheinlichkeit')
          and exists (select 1 from klp_themenplan where klp_fassung = '2022' and schulform = 'Realschule'
                        and thema_key = 'bedingte_wahrscheinlichkeit'),
          'A bedingte Wahrscheinlichkeit erst im KLP 2022');

-- B · Sperren -----------------------------------------------------------------
select is((select count(distinct skill_key)::int from skill_schulform where kurs = 'alle' and not zulaessig
             and klp_fassung in ('alle', '2004')
             and skill_key = any (array['stoch_bedingt_wkeit', 'stoch_bedingt_vierfeld', 'stoch_bedingt_umkehr',
                                        'stoch_bedingt_unabhaengig', 'geo_trigo_kosinussatz', 'fkt_sinus_einheitskreis',
                                        'fkt_sinus_bogenmass', 'fkt_sinus_parameter'])), 8,
          'B die 8 nur-gymnasialen Skills sind gesperrt');
select ok(not skill_zulaessig('geo_trigo_kosinussatz', 'Realschule'), 'B Kosinussatz Realschule gesperrt');
select ok(skill_zulaessig('geo_trigo_kosinussatz', 'Gymnasium'), 'B Kosinussatz Gymnasium zulässig');
select ok(not skill_zulaessig('gleichung_quadr_formel', 'Gesamtschule', 'G'), 'B p-q-Formel im G-Kurs gesperrt');
select ok(skill_zulaessig('gleichung_quadr_formel', 'Gesamtschule', 'E'), 'B p-q-Formel im E-Kurs zulässig');
select ok(skill_zulaessig('gleichung_quadr_formel', 'Gesamtschule'), 'B ohne Kurs gilt E');
select ok(skill_zulaessig('gleichung_quadr_wurzel', 'Gesamtschule', 'G'), 'B rein-quadratisch im G-Kurs zulässig');
select ok(not skill_zulaessig('stoch_bedingt_vierfeld', 'Realschule', null, '2004')
          and skill_zulaessig('stoch_bedingt_vierfeld', 'Realschule', null, '2022'), 'B Vierfeldertafel RS: 2004 gesperrt, 2022 zulässig');
select is(array[klp_fassung('2026/27', 10, 'Realschule'), klp_fassung('2026/27', 9, 'Realschule'),
                klp_fassung('2027/28', 10, 'Gesamtschule'), klp_fassung('2026/27', 10, 'Gymnasium')],
          array['2004', '2022', '2022', 'g9'], 'B klp_fassung nach Klasse und Schuljahr');
select is((select count(*)::int from skill_schulform where fundstelle is null or btrim(fundstelle) = ''), 0,
          'B jede Sperre mit Fundstelle');

-- C · Pakete aus dem Kernlehrplan ---------------------------------------------
insert into schulen (id, name, ort, schulform) values
  (:'ge', 'SF1 Test-Gesamtschule', 'Testort', 'Gesamtschule'),
  (:'rs', 'SF1 Test-Realschule', 'Testort', 'Realschule'),
  (:'gy', 'SF1 Test-Gymnasium ohne Plan', 'Testort', 'Gymnasium'),
  (:'gyp', 'SF1 Test-Gymnasium mit Plan', 'Testort', 'Gymnasium'),
  (:'leer', 'SF1 Test-Schule ohne Schulform', 'Testort', null);
insert into schul_themenplan (schule_id, fach, klasse, position, thema_key, uv_titel, quelle_url)
values (:'gyp', 'mathematik', 8, 1, 'lineare_funktionen', 'Lineare Funktionen', 'https://example.invalid/plan');

create temp table p26 as select * from lsa_pakete_roh('2026/27') where schule_id = any (array[:'ge', :'rs', :'gy', :'gyp', :'leer']::uuid[]);
create temp table p27 as select * from lsa_pakete_roh('2027/28') where schule_id = any (array[:'ge', :'rs', :'gy', :'gyp', :'leer']::uuid[]);

select is((select array_agg(distinct klasse order by klasse) from p26 where schule_id = :'ge' and quelle = 'klp'),
          array[7, 8, 9, 10], 'C Gesamtschule ohne Plan: klp-Pakete Kl. 7–10');
select is((select count(*)::int from p26 where schule_id = :'ge' and quelle <> 'klp'), 0, 'C nur Quelle klp');
select is((select count(*)::int from p26 where schule_id = :'ge' and cardinality(thema_keys) <> 1), 0, 'C 1 Thema = 1 Arbeit');
select ok((select bool_and(lage >= 0 and lage < 1) from p26 where schule_id = :'ge'), 'C Lage im Schuljahr');
-- 2026/27: Kl. 10 nach KLP 2004, Kl. 9 nach KLP 2022.
select is((select count(*)::int from p26 p cross join unnest(p.thema_keys) t
            where p.schule_id = :'ge' and p.klasse = 10
              and not exists (select 1 from klp_themenplan k where k.schulform = 'Gesamtschule' and k.klp_fassung = '2004'
                                and k.doppeljahrgang = '9/10' and k.kurs in ('alle', 'E') and k.thema_key = t)), 0,
          'C 2026/27 Kl. 10 nach KLP 2004');
select is((select count(*)::int from p26 p cross join unnest(p.thema_keys) t
            where p.schule_id = :'ge' and p.klasse = 9
              and not exists (select 1 from klp_themenplan k where k.schulform = 'Gesamtschule' and k.klp_fassung = '2022'
                                and k.doppeljahrgang = '9/10' and k.kurs in ('alle', 'E') and k.thema_key = t)), 0,
          'C 2026/27 Kl. 9 nach KLP 2022');
-- 2027/28: Kl. 9 und 10 nach 2022 → beide Jahre zusammen genau der Doppeljahrgang, ohne Doppelung.
select is((select array_agg(t order by t) from p27 p cross join unnest(p.thema_keys) t
            where p.schule_id = :'ge' and p.klasse in (9, 10)),
          (select array_agg(distinct thema_key order by thema_key) from klp_themenplan
            where schulform = 'Gesamtschule' and klp_fassung = '2022' and doppeljahrgang = '9/10' and kurs in ('alle', 'E')),
          'C Doppeljahrgang linear über zwei Jahre, jedes Thema genau einmal');
select is((select array_agg(distinct klasse order by klasse) from p26 where schule_id = :'gy'),
          array[7, 8, 9, 10], 'C Gymnasium ohne Plan: Pakete aus g9');
select is((select count(*)::int from p26 where schule_id = :'gyp' and quelle = 'klp'), 0, 'D Gymnasium mit Plan: kein klp');
select is((select count(*)::int from p26 where schule_id = :'gyp'), 1, 'D Gymnasium mit Plan: nur das Plan-Paket');
select is((select count(*)::int from p26 where schule_id = :'leer'), 0, 'D ohne Schulform keine Pakete');

-- D · bestätigte Klassenarbeit ersetzt die klp-Pakete der Klasse ------------
insert into schul_klassenarbeiten (schule_id, fach, klasse, schuljahr, nr, thema_keys, bestaetigt)
values (:'ge', 'mathematik', 8, '2026/27', 1, array['lineare_funktionen'], true);
select is((select array_agg(distinct quelle) from lsa_pakete_roh('2026/27') where schule_id = :'ge' and klasse = 8),
          array['bestaetigt'], 'D bestätigte Klassenarbeit verdrängt klp in Kl. 8');
select ok(exists (select 1 from lsa_pakete_roh('2026/27') where schule_id = :'ge' and klasse = 7 and quelle = 'klp'),
          'D andere Klassen bleiben klp');

-- E · Skills ------------------------------------------------------------------
select is((select count(*)::int from lsa_paket_skills_roh('2026/27') k
             join skill_schulform ss on ss.skill_key = k.skill_key and ss.schulform = 'Realschule'
            where k.schule_id = :'rs' and not ss.zulaessig and ss.kurs in ('alle', 'E')
              and ss.klp_fassung in ('alle', klp_fassung('2026/27', k.klasse, 'Realschule'))), 0,
          'E Realschule: kein gesperrter Skill im Paket');
select is(pg_temp.fehler('select lsa_paket_cache_auffrischen()'), 'ok', 'E Speicher nimmt klp an');
select ok(exists (select 1 from thema_einstieg te
                   join klp_themenplan k on k.thema_key = te.thema_key and k.schulform = 'Realschule'
                   join skill_schulform ss on ss.skill_key = te.skill_key and ss.schulform = 'Realschule'
                  where not ss.zulaessig and ss.klp_fassung in ('alle', k.klp_fassung)),
          'E Positivkontrolle: ohne Filter stünden gesperrte Einstiege in RS-Paketen');
select is((select count(*)::int from lsa_pakete_roh('2026/27') p
            where p.schule_id = :'rs'
              and p.hat_einstieg is distinct from (
                    select bool_and(exists (select 1 from thema_einstieg te where te.thema_key = x
                                              and skill_zulaessig(te.skill_key, 'Realschule', 'E',
                                                                  klp_fassung('2026/27', p.klasse, 'Realschule'))))
                      from unnest(p.thema_keys) x)), 0,
          'E hat_einstieg zählt nur zulässige Einstiege');
select is((select hat_einstieg from lsa_pakete_roh('2026/27')
            where schule_id = :'rs' and klasse = 10 and thema_keys = array['sinusfunktion']), false,
          'E Sinus Kl. 10 (KLP 2004): einziger Einstieg a·sin(b·x) gesperrt → ohne Einstieg');

-- F · Rechte ------------------------------------------------------------------
select pg_temp.act_as(:'admin');
set local role authenticated;
select ok((select count(*) from klp_themenplan) > 0 and (select count(*) from skill_schulform) > 0, 'F Admin liest');
reset role;
select pg_temp.act_as(:'coach');
set local role authenticated;
select ok((select count(*) from klp_themenplan) > 0 and (select count(*) from skill_schulform) > 0, 'F Coach liest');
select is(pg_temp.fehler($$insert into skill_schulform values ('term_einsetzen', 'Realschule', 'alle', 'alle', false, 'x')$$),
          '42501', 'F Coach schreibt nicht');
reset role;
select pg_temp.act_as(:'kindp');
set local role authenticated;
select is((select count(*)::int from klp_themenplan) + (select count(*)::int from skill_schulform), 0, 'F Kind liest nichts');
reset role;
select pg_temp.system();

select * from finish();
rollback;
