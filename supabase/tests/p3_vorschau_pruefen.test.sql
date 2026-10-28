-- ============================================================================
-- P3 Vorschau prüfen (Migration 20261022080744): pruef_soll.einsatz, Anlässe je Aufgabe nach tasks.einsatz,
-- Zählung je Anlass, lsa_vorschau-Zeilen, alte Stufe 3 (seit P4 wieder aktiv).
-- Fixtures am Knoten gleichung_zweischrittig (batu_session + lsa_vorschau): je eine Aufgabe nur LSA, nur Session,
-- je eine MC-Aufgabe nur LSA und nur Session (seit Reihe 1 A1 gibt es keine Aufgabe in beiden Pools). Die übrigen Aufgaben des Knotens verlieren in dieser Transaktion ihr Pilot-Flag. Am Ende rollback.
--
-- Lauf: npx supabase test db
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(14);

\set lena_uid '3c300000-0000-4000-8000-00000000000b'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'lena_uid', 'p3-lena@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name, darf_pruefen) values
  (:'lena_uid', 'p3-lena@test.local', 'coach', 'P3 Lena', true);
update pruef_einstellungen set nur_pilot = true;
update tasks set pruef_pilot = false where skill_key = 'gleichung_zweischrittig';

create function pg_temp.aufgabe(p_ref text, p_einsatz text[], p_typ text)
returns uuid language plpgsql as $$
declare v uuid;
begin
  insert into tasks (content_type, input_type, title, question, afb, cluster_id, curriculum_grade, skill_key,
                     sondierrang, source, source_ref, status, pruef_pilot, einsatz, question_payload)
  values ('exercise', p_typ, 'AFB I · ' || p_ref, 'Löse die Gleichung 2x + 3 = 11.', 'I',
          (select id from skill_clusters order by id limit 1), 7, 'gleichung_zweischrittig', 3, 'p3_test', p_ref,
          'review', true, p_einsatz,
          case when p_typ = 'MC' then '{"input_type": "MC", "options": [{"id": "a", "label": "x = 4"},
            {"id": "b", "label": "x = 7"}, {"id": "c", "label": "x = 3"}, {"id": "d", "label": "x = 5,5"}]}'::jsonb end)
  returning id into v;
  insert into task_solutions (task_id, correct_answers, acceptance, solution, hints)
  values (v, (case when p_typ = 'MC' then '["a"]' else '["4"]' end)::jsonb,
          (case when p_typ = 'MC' then '{"canonical": "a"}' else '{"canonical": "4"}' end)::jsonb,
          '2x = 8, also x = 4', '[]');
  return v;
end $$;

create function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;

select pg_temp.aufgabe('p3-lsa', '{lsa}', 'NUMERIC') as nur_lsa \gset
select pg_temp.aufgabe('p3-session', '{session}', 'NUMERIC') as nur_session \gset
select pg_temp.aufgabe('p3-lsa-mc', '{lsa}', 'MC') as lsa_mc \gset
select pg_temp.aufgabe('p3-session-mc', '{session}', 'MC') as session_mc \gset

-- ============================================================================
-- 1 · Daten der Migration
-- ============================================================================
select is((select string_agg(distinct einsatz, ',') from pruef_soll where anlass = 'batu_session'), 'session',
  '1: batu_session zählt für Session');
select is((select count(*)::int from pruef_soll where anlass <> 'batu_session' and einsatz <> 'lsa'), 0,
  '1: alle übrigen Anlässe zählen für die LSA');
select is((select soll || '/' || min_ohne_mc || ' ' || aktiv from pruef_soll
            where anlass = 'lsa_vorschau' and skill_key = 'gleichung_zweischrittig'), '2/1 true',
  '1: gleichung_zweischrittig hat trotz batu_session eine lsa_vorschau-Zeile');
select is((select count(*)::int from pruef_soll p where p.aktiv and p.einsatz = 'lsa'
            group by p.skill_key order by 1 desc limit 1), 1, '1: je Knoten höchstens eine aktive LSA-Zeile');
select is((select array_agg(skill_key order by sort) from pruef_soll
            where anlass = 'lsa_vorschau' and skill_key in ('term_einsetzen', 'geo_koordinaten',
              'gleichung_modellieren', 'gleichung_zweischrittig', 'geo_umfang', 'groessen_laengen')),
  '{term_einsetzen,geo_koordinaten,gleichung_modellieren,gleichung_zweischrittig,geo_umfang,groessen_laengen}'::text[],
  '1: sort in der beauftragten Reihenfolge');
select is((select aktiv from pruef_soll where anlass = 'batu_lsa' and skill_key = 'term_binom_quadrat'), true,
  '1: term_binom_quadrat bleibt aktiv');
-- P4 (20261025210952) setzt die alte Stufe 3 wieder aktiv; hier bleibt nur, dass keine Zeile gelöscht wurde.
select is((select count(*)::int from pruef_soll where anlass = 'batu_lsa' and not aktiv and sort between 410 and 899), 0,
  '1: alte Stufe 3 nach P4 wieder aktiv');
select is((select count(*)::int from pruef_soll where anlass = 'batu_lsa'
            and skill_key in ('fkt_linear_gleichung', 'fkt_linear_steigung', 'fkt_linear_yabschnitt',
              'term_binom_faktorisieren', 'term_binom_gemischt', 'term_binom_quadrat', 'term_binom_quadratdifferenz',
              'gleichung_lgs_addition', 'gleichung_lgs_einsetzen', 'gleichung_lgs_grafisch',
              'geo_flaeche_drachen_raute', 'geo_flaeche_term', 'geo_flaeche_trapez', 'stoch_pfad_summe',
              'geo_winkel_thales')), 15,
  '1: keine Zeile der alten Stufe 3 gelöscht');

-- ============================================================================
-- 2 · Anlässe je Aufgabe nach tasks.einsatz
-- ============================================================================
create function pg_temp.an(p_id uuid) returns text[] language sql as $$
  select b.anlaesse from public.pruef_board() b where b.task_id = p_id $$;

set local role authenticated;
select pg_temp.act_as(:'lena_uid');
select is(pg_temp.an(:'nur_lsa'), '{lsa_vorschau}'::text[], '2: nur LSA → nur lsa_vorschau');
select is(pg_temp.an(:'nur_session'), '{batu_session}'::text[], '2: nur Session → nur batu_session');
select is(pg_temp.an(:'lsa_mc') || pg_temp.an(:'session_mc'), '{lsa_vorschau,batu_session}'::text[],
          '2: MC je Pool → nur der Anlass ihres Pools (Reihe 1 A1: keine Aufgabe in beiden)');

-- ============================================================================
-- 3 · Zählung je Reiter: LSA nur Aufgaben mit 'lsa', Session nur Session-Aufgaben
-- ============================================================================
create function pg_temp.zahl(p_anlass text) returns text language sql as $$
  select k.im_board || '/' || k.gezaehlt || '/' || k.gezaehlt_ohne_mc || ' rest ' || k.rest || ' ' || k.reicht
    from public.pruef_board_soll(p_anlass) k where k.skill_key = 'gleichung_zweischrittig' $$;

select is(pg_temp.zahl('lsa_vorschau'), '2/2/1 rest 0 true', '3: LSA zählt nur die LSA-Aufgaben (eine ohne MC)');
select is(pg_temp.zahl('batu_session'), '2/2/1 rest 4 false', '3: Session zählt nur die Session-Aufgaben, Soll 6');
select is(pg_temp.zahl('batu_lsa'), null, '3: kein batu_lsa-Soll am Knoten');
reset role;

select * from finish();
rollback;
