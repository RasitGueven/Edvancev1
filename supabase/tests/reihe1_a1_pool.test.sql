-- ============================================================================
-- Reihe 1 · A1 Pool-Trennung (Migration 20261027130250):
--   1 keine Aufgabe in beiden Pools; eine solche Zeile scheitert (Insert und Update), ebenso {} und ohne Einsatz
--   2 die LSA-Auswahl zieht nur Pool lsa (lsa_im_pool, lsa_freie_aufgabe)
--   3 die Session-Auswahl zieht nach der Datenaenderung keine LSA-Aufgabe (session_im_pool, session_aufgabe_waehlen)
--   4 den Einsatz aendert nur ein Admin (tasks_pruefer_guard)
--   5 pruef_board liefert den Pool
-- Eigene Fixtures (Quelle 'reihe1_a1_test', Skill zz_r1a1), am Ende rollback.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(16);

\set admin_uid '2c300000-0000-4000-8000-0000000000a1'
\set lena_uid  '2c300000-0000-4000-8000-0000000000b1'
insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid', 'r1a1-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'lena_uid',  'r1a1-lena@test.local',  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name, darf_pruefen) values
  (:'admin_uid', 'r1a1-admin@test.local', 'admin', 'R1A1 Admin', false),
  (:'lena_uid',  'r1a1-lena@test.local',  'coach', 'R1A1 Lena',  true);

create function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;

insert into skills (skill_key, label, klasse_herkunft, fundament_tiefe) values ('zz_r1a1', 'ZZ R1 A1', 9, 1);
insert into themen (thema_key, fach, klasse, stufe, label, sort) values ('zz_r1a1_thema', 'mathematik', 9, 'erste', 'ZZ R1 A1', 9401);
insert into skill_thema (skill_key, thema_key) values ('zz_r1a1', 'zz_r1a1_thema');

create function pg_temp.aufgabe(p_ref text, p_einsatz text[]) returns uuid language plpgsql as $$
declare v uuid;
begin
  insert into tasks (content_type, input_type, status, is_active, question, skill_key, difficulty, est_duration_sec,
                     source, source_ref, einsatz, afb, competency_content, class_level, curriculum_grade, cluster_id)
  values ('exercise', 'NUMERIC', 'ready', true, 'ZZ R1 A1 ' || p_ref || ': Wie viel ist 3 + 4?', 'zz_r1a1', 2, 60,
          'reihe1_a1_test', p_ref, p_einsatz, 'I', 'Zahlen und Operationen', 9, 9,  -- Gate-Felder fuer pruef_board
          (select id from skill_clusters order by id limit 1))
  returning id into v;
  insert into task_solutions (task_id, correct_answers, acceptance) values (v, '["7"]', '{"canonical":"7"}');
  return v;
end $$;

-- ── 1) Nie beide Pools ───────────────────────────────────────────────────────
select is((select count(*) from tasks where einsatz @> array['lsa', 'session']), 0::bigint,
          '1 keine Aufgabe ist nach der Migration in beiden Pools');
select throws_like($$select pg_temp.aufgabe('beide', '{lsa,session}')$$, '%tasks_einsatz_ein_pool%',
                   '1 eine neue Aufgabe in beiden Pools scheitert');
select pg_temp.aufgabe('lsa', '{lsa}') as t_lsa \gset
select pg_temp.aufgabe('session', '{session}') as t_session \gset
select throws_like(format($$update tasks set einsatz = '{lsa,session}' where id = %L$$, :'t_lsa'),
                   '%tasks_einsatz_ein_pool%', '1 eine Aufgabe nachtraeglich in beide Pools zu legen scheitert');
select throws_like($$select pg_temp.aufgabe('leer', '{}')$$, '%tasks_einsatz_nicht_leer%',
                   '1 eine Aufgabe ohne jeden Einsatz scheitert');
select throws_ok($$insert into tasks (content_type, question, source, source_ref) values ('exercise', 'ZZ', 'reihe1_a1_test', 'ohne')$$,
                 '23502', null, '1 ohne Angabe gibt es keinen Default mehr (not null)');

-- ── 2) LSA-Auswahl nur Pool lsa ──────────────────────────────────────────────
select ok(lsa_im_pool(:'t_lsa', false) and not lsa_im_pool(:'t_session', false), '2 lsa_im_pool: nur die LSA-Aufgabe');
select is(lsa_freie_aufgabe(gen_random_uuid(), 'zz_r1a1', false), :'t_lsa'::uuid,
          '2 lsa_freie_aufgabe zieht die LSA-Aufgabe, nie die Session-Aufgabe');
update tasks set is_active = false where id = :'t_lsa';
select is(lsa_freie_aufgabe(gen_random_uuid(), 'zz_r1a1', false), null,
          '2 ohne LSA-Aufgabe zieht die LSA nichts, auch wenn eine Session-Aufgabe da ist');
update tasks set is_active = true where id = :'t_lsa';

-- ── 3) Session-Auswahl nie eine LSA-Aufgabe ──────────────────────────────────
select ok(session_im_pool(:'t_session', false) and not session_im_pool(:'t_lsa', false), '3 session_im_pool: nur die Session-Aufgabe');
select is((select task_id from session_aufgabe_waehlen(gen_random_uuid(), gen_random_uuid(), 'zz_r1a1', 2, false)), :'t_session'::uuid,
          '3 session_aufgabe_waehlen zieht die Session-Aufgabe');
update tasks set is_active = false where id = :'t_session';
select is((select task_id from session_aufgabe_waehlen(gen_random_uuid(), gen_random_uuid(), 'zz_r1a1', 2, false)), null,
          '3 ohne Session-Aufgabe zieht die Session nichts, auch wenn eine LSA-Aufgabe da ist');
update tasks set is_active = true where id = :'t_session';
select is((select count(*) from tasks t where coalesce(t.is_active, false) and session_im_pool(t.id, false)
              and 'lsa' = any (t.einsatz)), 0::bigint,
          '3 im ganzen Bestand ist keine LSA-Aufgabe im Session-Pool');

-- ── 4) Einsatz nur durch Admins ──────────────────────────────────────────────
-- Direktes Schreiben auf tasks erlaubt RLS nur Admins; der Guard sichert die Pruefwege (SECURITY DEFINER laeuft als
-- Eigentuemer, aber current_user ist dort nicht 'authenticated') und jede kuenftige Policy. Fuer den Test eine Policy,
-- die auch Lena schreiben liesse — der Guard muss trotzdem greifen.
create policy zz_r1a1_alle on tasks for update to authenticated using (true) with check (true);
grant update on tasks to authenticated;
select pg_temp.aufgabe('entwurf', '{session}') as t_entwurf \gset
update tasks set status = 'draft' where id = :'t_entwurf';  -- ready aendert ohnehin nur ein Admin
set local role authenticated;
select pg_temp.act_as(:'lena_uid');
select throws_ok(format($$update tasks set einsatz = '{lsa}' where id = %L$$, :'t_entwurf'), '42501', null,
                 '4 Lena aendert den Einsatz nicht');
select pg_temp.act_as(:'admin_uid');
select lives_ok(format($$update tasks set einsatz = '{lsa}' where id = %L$$, :'t_entwurf'), '4 ein Admin aendert den Einsatz');

-- ── 5) pruef_board zeigt den Pool ────────────────────────────────────────────
select pg_temp.act_as(:'lena_uid');
reset role;
update pruef_einstellungen set nur_pilot = false;
set local role authenticated;
select pg_temp.act_as(:'lena_uid');
select is((select b.pool from pruef_board() b where b.task_id = :'t_lsa'), 'lsa', '5 pruef_board: Pool lsa');
select is((select b.pool from pruef_board() b where b.task_id = :'t_session'), 'session', '5 pruef_board: Pool session');

reset role;
select * from finish();
rollback;
