-- ============================================================================
-- LSA-L4: Bericht-Voraussetzungen direkt prüfen, ohne Thema kein kommender Stoff
-- (docs/lsa/Bauauftrag-L4.md, Migration 20261025232926)
--
--   a) Ein mitbelegter ★-Knoten (Bericht-Voraussetzung) wird in der Vorschau nachgeprüft, nach den Knoten ohne
--      Urteil; ein mitbelegter Knoten ohne ★ nicht.
--   b) Das direkte Ergebnis ersetzt das mitbelegte Urteil (belegt_direkt, eine Probe).
--   c) Falsch gewinnt gegen mitbelegt-sicher (mit Zweitbeleg wie immer).
--   d) Ohne Thema mit Planposition: Vorschau läuft, keine Skills kommender Themen, nichts über der Klasse.
--
-- Isoliert wie lsa_l3_ka_modus. Graph (Klasse, Tiefe), Pfeil = setzt voraus; Kind Klasse 9:
--   zm_akt (aktuell): Einstieg zm_a1 (9,6) -> zm_s1 (8,2), zm_n1 (7,1)   (zm_a1 richtig belegt zm_s1, zm_n1 mit)
--   zm_u1  (kommt)  : zm_u1a (9,5) -> zm_s1, zm_r1 (7,3)                  (★ = zm_s1, zm_r1; zm_n1 ist kein ★)
--   zm_leer         : Einstieg zm_le (9,1) ohne Aufgabe                   (Thema ohne freie Aufgabe)
--   zm_alt (behandelt): zm_b1 (8,1);  zm_h (10,1) ohne Thema, über der Klasse
-- Plan Schule ZM:  Kl. 9: 1 zm_akt, 2 zm_u1, 3 zm_u2, 4 zm_u3 (zm_u2, zm_u3 ohne Skills).
-- Plan Schule ZM2: Kl. 9: 1 zm_leer, 2 zm_u1, 3 zm_u2, 4 zm_u3.
-- ============================================================================
begin;
-- Reihe 1 A1: einsatz hat keinen Default mehr; die Aufgaben dieses Tests gehören zum Pool {lsa} (nur in dieser Transaktion).
alter table public.tasks alter column einsatz set default '{lsa}';
create extension if not exists pgtap with schema extensions;

select plan(12);

update tasks set skill_key = null where skill_key is not null;
delete from thema_einstieg;
delete from skill_kante;
delete from erklaer_kernidee;
delete from skills;

insert into skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
select k, upper(k), 'mathematik', kl, tf from (values
  ('zm_a1', 9, 6), ('zm_s1', 8, 2), ('zm_n1', 7, 1), ('zm_u1a', 9, 5), ('zm_r1', 7, 3), ('zm_le', 9, 1),
  ('zm_b1', 8, 1), ('zm_h', 10, 1)) v(k, kl, tf);
insert into skill_kante (skill_key, voraussetzt_skill_key) values
  ('zm_a1', 'zm_s1'), ('zm_a1', 'zm_n1'), ('zm_u1a', 'zm_s1'), ('zm_u1a', 'zm_r1');
insert into themen (thema_key, fach, klasse, label, stufe, sort) values
  ('zm_akt', 'mathematik', 9, 'ZM aktuell', 'zweite', 9210), ('zm_leer', 'mathematik', 9, 'ZM leer', 'zweite', 9211),
  ('zm_u1', 'mathematik', 9, 'ZM U1', 'zweite', 9220), ('zm_u2', 'mathematik', 9, 'ZM U2', 'zweite', 9230),
  ('zm_u3', 'mathematik', 9, 'ZM U3', 'zweite', 9240), ('zm_alt', 'mathematik', 8, 'ZM behandelt', 'erste', 8200);
insert into skill_thema (skill_key, thema_key) values
  ('zm_a1', 'zm_akt'), ('zm_s1', 'zm_akt'), ('zm_n1', 'zm_akt'), ('zm_u1a', 'zm_u1'), ('zm_le', 'zm_leer'),
  ('zm_b1', 'zm_alt');
insert into thema_einstieg (thema_key, skill_key) values
  ('zm_akt', 'zm_a1'), ('zm_u1', 'zm_u1a'), ('zm_leer', 'zm_le'), ('zm_alt', 'zm_b1');

insert into tasks (cluster_id, content_type, input_type, status, question, source, source_ref, skill_key, sondierrang,
                   class_level)
select (select c.id from skill_clusters c join subjects sub on sub.id = c.subject_id
         where sub.name = 'Mathematik' order by c.sort_order limit 1),
       'exercise', 'NUMERIC', 'ready', 'Wie viel ist 2 + 3? ' || s.skill_key || ' ' || n,
       'test', 'zm-' || s.skill_key || '-' || n, s.skill_key, n, 9
  from skills s cross join generate_series(1, 2) n
 where s.skill_key <> 'zm_le';
insert into task_solutions (task_id, correct_answers)
select id, '["5"]'::jsonb from tasks where source = 'test' and source_ref like 'zm-%';
update tasks set question = question || ' ' || translate(md5(id::text), '0123456789', 'ghijklmnop')
 where source = 'test' and source_ref like 'zm-%';

\set admin_uid 'dddddddd-dddd-dddd-dddd-0000000000c4'
insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid', 'lsal4-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values (:'admin_uid', 'lsal4-admin@test.local', 'admin', 'LSA-L4 Admin');
select set_config('request.jwt.claims', json_build_object('sub', :'admin_uid', 'role', 'authenticated')::text, true);

insert into schulen (name, ort) values ('ZM Schule', 'Testort'), ('ZM2 Schule', 'Testort');
insert into schul_themenplan (schule_id, fach, klasse, position, thema_key, uv_titel, halbjahr, quelle_url)
select s.id, 'mathematik', 9, p.pos, case when p.pos = 1 and s.name = 'ZM2 Schule' then 'zm_leer' else p.th end,
       p.th, null, 'https://test.invalid'
  from schulen s cross join (values (1, 'zm_akt'), (2, 'zm_u1'), (3, 'zm_u2'), (4, 'zm_u3')) p(pos, th)
 where s.name in ('ZM Schule', 'ZM2 Schule');

create function pg_temp.kind(p_thema text, p_schule text) returns uuid language plpgsql as $$
declare v_lead uuid; v_student uuid;
begin
  insert into leads (full_name, class_level, status, schule_id)
  values ('ZM Kind', 9, 'contacted', (select id from schulen where name = p_schule)) returning id into v_lead;
  insert into lead_themen (lead_id, fach, thema_key, status, quelle) values
    (v_lead, 'mathematik', p_thema, 'aktuell', 'gespraech'), (v_lead, 'mathematik', 'zm_alt', 'behandelt', 'schulplan');
  perform set_config('edvance.allow_provisional', '1', true);
  insert into students (class_level, is_provisional, lead_id) values (9, true, v_lead) returning id into v_student;
  return v_student;
end $$;

create function pg_temp.t0() returns timestamptz language sql immutable as $$
  select '2026-10-05 08:00:00+00'::timestamptz
$$;

create function pg_temp.start(p_student uuid) returns uuid language sql as $$
  select (public.lsa_start(p_student, 9, 'Mathematik', 'adaptiv', pg_temp.t0()) ->> 'session_id')::uuid
$$;

create function pg_temp.offen(p_sess uuid) returns uuid language sql as $$
  select a.task_id from lsa_ausgegeben a
   where a.session_id = p_sess
     and not exists (select 1 from lsa_responses r where r.session_id = p_sess and r.task_id = a.task_id)
   limit 1
$$;

create function pg_temp.folge(p_sess uuid, p_muster text) returns text language plpgsql as $$
declare v_task uuid; v_out text[]; i int;
begin
  v_task := pg_temp.offen(p_sess);
  v_out := array[coalesce((select skill_key from tasks where id = v_task), '-')];
  for i in 1 .. length(p_muster) loop
    exit when v_task is null;
    perform public.lsa_submit(p_sess, v_task,
      case substr(p_muster, i, 1) when 'r' then '{"value":"5"}' else '{"value":"7"}' end::jsonb,
      1000, pg_temp.t0() + i * interval '1 minute');
    v_task := pg_temp.offen(p_sess);
    v_out := v_out || coalesce((select skill_key from tasks where id = v_task), '-');
  end loop;
  return array_to_string(v_out, ',');
end $$;

create function pg_temp.urteil(p_sess uuid, p_sk text) returns text language sql as $$
  select zustand || '/' || belegt_direkt || '/' || proben_anzahl from lsa_skill_urteil
   where session_id = p_sess and skill_key = p_sk
$$;

-- ============================================================================
-- a) und b): alles richtig
-- ============================================================================
select pg_temp.start(pg_temp.kind('zm_akt', 'ZM Schule')) as s_a \gset
select is(pg_temp.folge(:'s_a', 'rrrrrrrr'), 'zm_a1,zm_r1,zm_s1,zm_b1,-',
  'a: zm_a1 belegt zm_s1 mit; die Vorschau nimmt erst zm_r1 (ohne Urteil), dann den mitbelegten ★ zm_s1');
select ok(not ('zm_n1' = any (array(select t.skill_key from lsa_ausgegeben a join tasks t on t.id = a.task_id
                                     where a.session_id = :'s_a'))),
  'a: zm_n1 (mitbelegt, kein ★) wird nicht nachgeprueft');
select is(pg_temp.urteil(:'s_a', 'zm_n1'), 'traegt/false/0', 'a: ... und bleibt mitbelegt');
select is(pg_temp.urteil(:'s_a', 'zm_s1'), 'traegt/true/1', 'b: direktes Ergebnis ersetzt das mitbelegte Urteil');

-- ============================================================================
-- c) falsch gewinnt gegen mitbelegt-sicher
-- ============================================================================
select pg_temp.start(pg_temp.kind('zm_akt', 'ZM Schule')) as s_c \gset
select is(pg_temp.folge(:'s_c', 'rrffrrr'), 'zm_a1,zm_r1,zm_s1,zm_s1,zm_b1,-',
  'c: zm_s1 falsch -> Zweitbeleg wie immer');
select is(pg_temp.urteil(:'s_c', 'zm_s1'), 'traegt_nicht/true/2', 'c: falsch gewinnt gegen mitbelegt sicher');
select is(pg_temp.urteil(:'s_c', 'zm_a1'), 'traegt/true/1', 'c: zm_a1 bleibt, wie es war');

-- ============================================================================
-- d) Ohne Thema: Vorschau, nichts Kommendes, nichts über der Klasse
-- ============================================================================
select pg_temp.start(pg_temp.kind('zm_leer', 'ZM2 Schule')) as s_d \gset
select pg_temp.folge(:'s_d', repeat('r', 20)) as d_folge \gset
select ok(not ('zm_u1a' = any (string_to_array(:'d_folge', ','))),
  'd: ohne Thema nie zm_u1a (Skill des kommenden Themas zm_u1)');
select ok(not ('zm_h' = any (string_to_array(:'d_folge', ','))), 'd: ohne Thema nichts ueber Klasse 9 (zm_h)');
select ok(string_to_array(:'d_folge', ',') @> array['zm_r1', 'zm_s1'],
  'd: ohne Thema laeuft die Vorschau (Rand zm_r1, zm_s1)');
select is((string_to_array(:'d_folge', ','))[1:2], array['zm_r1', 'zm_s1'],
  'd: ... und zwar zuerst (Vorschau vor Breite), Rand nach Tiefe: zm_r1 (3) vor zm_s1 (2)');

select ok(not has_function_privilege('authenticated', 'public.lsa_urteil_buchen_core(uuid, uuid)', 'execute'),
  'lsa_urteil_buchen_core bleibt fuer authenticated gesperrt');

select * from finish();
rollback;
