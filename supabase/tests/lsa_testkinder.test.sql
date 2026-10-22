-- ============================================================================
-- LSA-T: tools/lsa-testkinder/erzeugen.sql im Neuaufbau (Bauauftrag docs/lsa/Bauauftrag-LSA-T.md).
--
-- Der Neuaufbau hat Skills, Kanten, Themen, Einstiege und den FWG-Plan aus den Migrationen, aber keine
-- LSA-Aufgaben. Die Fixture gibt deshalb jedem Skill drei Aufgaben (Zahl, MC, Multi-Part; richtig ist
-- 7 bzw. a) mit hinterlegten Fehlbildern. Dann laeuft das Skript zweimal, unveraendert.
--
-- Bewiesen wird je Kind:
--   1. Die neueste Sitzung ist abgeschlossen, mit result_summary und Themenraum.
--   2. Jeder direkt beurteilte Bereich passt zum Profil (sicher → traegt, uebung → traegt_nicht,
--      teilweise → traegt oder traegt_teilweise, nicht_angesetzt → nicht_angesetzt).
--   3. Die simulierte Uhr deckt die 19 Minuten ab (Summe der Antwortdauern 18,5 bis 21 Minuten).
--   4. Lina hat mindestens 80 % sicher, Jonas hoechstens 20 %.
--   5. Emre, Sophie und Nele loesen ihr bevorzugtes Fehlbild aus.
--   6. Der zweite Lauf legt neue Sitzungen an, findet dieselben Leads und Schueler und loescht nichts.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(32);

\set admin 'a5a7c41d-adad-4000-8000-000000000001'
insert into auth.users (id, email, instance_id, aud, role)
values (:'admin', 'lsat-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name, created_at)
values (:'admin', 'lsat-admin@test.local', 'admin', 'ZZ LSA-T Admin', '2000-01-01');

-- Drei Aufgaben je Skill. Das hinterlegte Fehlbild folgt dem Skill, damit die Familien der Kinder etwas
-- zum Ausloesen haben; "-7" ist bei jeder Zahl-Aufgabe ein Vorzeichenfehler.
insert into skill_clusters (name, class_level_min, class_level_max) values ('ZZ LSA-T Cluster', 5, 13);
create temp table zz_lsat_skill as
select s.skill_key,
       case when s.skill_key = 'zahl_wurzel_gesetze' then 'wurzel_gliedweise'
            when s.skill_key like 'zahl_wurzel%' then 'faktor_ohne_wurzel'
            when s.skill_key like 'fkt_linear%' then 'steigung_kehrwert'
            when s.skill_key like 'prozent%' then 'multipliziert_statt_dividiert'
            else 'falsche_operation' end as slug
  from skills s;

insert into tasks (cluster_id, content_type, input_type, status, question, question_payload, parts, afb,
                   competency_content, est_duration_sec, class_level, curriculum_grade, source, source_ref,
                   skill_key, difficulty, einsatz, is_active)
select (select id from skill_clusters where name = 'ZZ LSA-T Cluster'), 'exercise', a.typ, 'ready',
       'ZZ LSA-T ' || z.skill_key || ' ' || a.typ || ': Wie viel ist 3 + 4?',
       case when a.typ = 'MC' then '{"input_type":"MC","options":[{"id":"a","label":"7"},{"id":"b","label":"8"},{"id":"c","label":"6"}]}'::jsonb end,
       case when a.typ = 'MULTI_PART' then
         '[{"nr":1,"afb":"I","kind":"short_input","unit":null,"prompt":"Wie viel ist 3 + 4?","competency_content":"zahlen","competency_process":null},
           {"nr":2,"afb":"I","kind":"short_input","unit":null,"prompt":"Wie viel ist 1 + 2?","competency_content":"zahlen","competency_process":null}]'::jsonb
       else '[]'::jsonb end,
       'I', 'Zahlen und Operationen', 60, 8, 8, 'test', 'lsat-' || z.skill_key || '-' || a.typ,
       z.skill_key, 1, '{lsa}', true
  from zz_lsat_skill z
 cross join (values ('NUMERIC'), ('MC'), ('MULTI_PART')) a(typ);

insert into task_solutions (task_id, correct_answers, solution, acceptance)
select t.id,
       case t.input_type when 'MC' then '["a"]'::jsonb when 'MULTI_PART' then '{"1":["7"],"2":["3"]}'::jsonb
                         else '["7"]'::jsonb end,
       'ZZ-LOESUNGSWEG',
       case t.input_type
         when 'MC' then jsonb_build_object('canonical', 'a', 'known_errors', jsonb_build_object('b', z.slug))
         when 'MULTI_PART' then jsonb_build_object(
           '1', jsonb_build_object('canonical', '7', 'known_errors', jsonb_build_object('8', z.slug)),
           '2', jsonb_build_object('canonical', '3'))
         else jsonb_build_object('canonical', '7',
                                 'known_errors', jsonb_build_object('8', z.slug, '-7', 'vorzeichen_ignoriert')) end
  from tasks t join zz_lsat_skill z on z.skill_key = t.skill_key
 where t.source = 'test' and t.source_ref like 'lsat-%';

select is((select count(*) from tasks where source_ref like 'lsat-%' and public.lsa_im_pool(id, false)),
          (select 3 * count(*) from skills), 'Fixture: drei Aufgaben je Skill im Pool');

-- Erwarteter Zustand eines direkt beurteilten Bereichs laut Profil des Kindes; true = passt.
create function pg_temp.passt(p_kind jsonb, p_skill text, p_zustand text) returns boolean language sql as $$
  select p_zustand = any (case coalesce(p_kind -> 'ausnahmen' ->> p_skill,
                                        p_kind -> 'grund' ->> (select case when s.klasse_herkunft <= 6 then '56'
                                                                           when s.klasse_herkunft <= 8 then '78'
                                                                           else '910' end
                                                                  from skills s where s.skill_key = p_skill))
                            when 'sicher' then array['traegt']
                            when 'uebung' then array['traegt_nicht']
                            when 'teilweise' then array['traegt', 'traegt_teilweise']
                            else array['nicht_angesetzt'] end)
$$;
create function pg_temp.kind(p_name text) returns jsonb language sql as $$
  select k from jsonb_array_elements(current_setting('lsat.kinder')::jsonb) k where k ->> 'kind' = p_name
$$;
-- Die Sitzung des letzten Laufs (das Skript merkt sie sich in lsat.sitzungen).
create function pg_temp.sitzung(p_name text) returns uuid language sql as $$
  select (current_setting('lsat.sitzungen')::jsonb ->> p_name)::uuid
$$;
create function pg_temp.anteil_sicher(p_name text) returns numeric language sql as $$
  select round(count(*) filter (where u.zustand = 'traegt')::numeric / nullif(count(*), 0), 2)
    from lsa_skill_urteil u
   where u.session_id = pg_temp.sitzung(p_name) and u.belegt_direkt and u.zustand <> 'ungeprueft'
$$;

-- ── Erster Lauf ─────────────────────────────────────────────────────────────
\ir ../../tools/lsa-testkinder/erzeugen.sql
create temp table zz_lsat_lauf1 as select l.id from lsa_sessions l where l.student_id::text like 'a5a7c41d-5c00-%';

-- 1–3 je Kind
select is((select l.status from lsa_sessions l where l.id = pg_temp.sitzung(n)), 'completed', n || ': Sitzung abgeschlossen')
  from unnest(array['Lina', 'Emre', 'Sophie', 'Jonas', 'Nele']) n;
select ok((select l.result_summary ? 'themenraum' and l.thema_key = pg_temp.kind(n) ->> 'thema'
             from lsa_sessions l where l.id = pg_temp.sitzung(n)),
          n || ': result_summary mit Themenraum des Themas aus dem Erstgespraech')
  from unnest(array['Lina', 'Emre', 'Sophie', 'Jonas', 'Nele']) n;
select is((select string_agg(u.skill_key || '=' || u.zustand, ', ') from lsa_skill_urteil u
            where u.session_id = pg_temp.sitzung(n) and u.belegt_direkt and u.zustand <> 'ungeprueft'
              and not pg_temp.passt(pg_temp.kind(n), u.skill_key, u.zustand)),
          null, n || ': jeder direkt beurteilte Bereich passt zum Profil')
  from unnest(array['Lina', 'Emre', 'Sophie', 'Jonas', 'Nele']) n;
select ok((select sum(r.d) between 18.5 * 60000 and 21 * 60000
             from (select distinct r.task_id, r.duration_ms as d from lsa_responses r
                    where r.session_id = pg_temp.sitzung(n)) r),
          n || ': die simulierte Uhr deckt die 19 Minuten ab')
  from unnest(array['Lina', 'Emre', 'Sophie', 'Jonas', 'Nele']) n;

-- 4
select ok(pg_temp.anteil_sicher('Lina') >= 0.8, 'Lina: mindestens 80 % sicher (' || pg_temp.anteil_sicher('Lina') || ')');
select ok(pg_temp.anteil_sicher('Jonas') <= 0.2, 'Jonas: hoechstens 20 % sicher (' || pg_temp.anteil_sicher('Jonas') || ')');

-- 5
select ok(exists (select 1 from lsa_responses r join fehlbild_labels f on f.slug = r.fehlbild_slug
                   where r.session_id = pg_temp.sitzung(n)
                     and (f.slug in (select jsonb_array_elements_text(pg_temp.kind(n) -> 'fehlbilder'))
                          or f.familie = pg_temp.kind(n) ->> 'familie')),
          n || ': das bevorzugte Fehlbild ist ausgeloest')
  from unnest(array['Emre', 'Sophie', 'Nele']) n;

-- ── Zweiter Lauf ────────────────────────────────────────────────────────────
\ir ../../tools/lsa-testkinder/erzeugen.sql

-- 6
select is((select count(*) from leads where id::text like 'a5a7c41d-1ead-%'), 5::bigint, 'Zweiter Lauf: dieselben fuenf Leads');
select is((select count(*) from students where id::text like 'a5a7c41d-5c00-%' and ist_test and is_provisional),
          5::bigint, 'Zweiter Lauf: dieselben fuenf Testkonten');
select is((select count(*) from lsa_sessions where student_id::text like 'a5a7c41d-5c00-%' and status = 'completed'),
          10::bigint, 'Zweiter Lauf: zehn abgeschlossene Sitzungen, je Kind zwei');
select is((select count(*) from zz_lsat_lauf1 a join lsa_sessions l on l.id = a.id), 5::bigint,
          'Zweiter Lauf: die Sitzungen des ersten Laufs stehen noch');
select ok(pg_temp.sitzung('Lina') not in (select id from zz_lsat_lauf1), 'Zweiter Lauf: die neueste Sitzung ist neu');
select is((select count(*) from leads where id::text like 'a5a7c41d-1ead-%' and status = 'lsa_fertig'), 5::bigint,
          'Zweiter Lauf: alle Leads stehen auf lsa_fertig');

select * from finish();
rollback;
