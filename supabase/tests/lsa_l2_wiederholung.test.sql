-- ============================================================================
-- LSA-L2: keine Fast-Duplikate in einer Sitzung, nie drei Aufgaben desselben Skills hintereinander, Vorschau auf
-- drei kommende Themen (docs/lsa/Bauauftrag-L2.md; Migration 20261025144025_lsa_l2_wiederholung)
--
--   a) lsa_text_schluessel: gleich bei Texten, die sich nur in Zahlen, Leerraum oder Groß/Klein unterscheiden;
--      die prompts der parts zählen mit; immutable; keine Rechte für anon/authenticated.
--   b) Zweitbeleg: kein Fast-Duplikat der ersten Probe, sondern die nächste andere Aufgabe des Skills.
--   c) Bleiben für den Zweitbeleg nur Fast-Duplikate, entfällt er: Urteil mit einer Probe, final.
--   d) Auch über Skills hinweg: eine Aufgabe, deren Text einer ausgegebenen gleicht, wird übersprungen.
--   e) Nie drei Aufgaben desselben Skills hintereinander, in jeder Folge dieses Tests.
--   f) Vorschau: der Rand der dritten kommenden Klassenarbeit kommt dran (c_vorschau_themen = 3).
--   g) Ohne Text (Inhalt nur in Payload oder Bild) kein Schlüssel: solche Aufgaben gleichen nichts.
--   h) Zweitbeleg nach MC richtig, nur Fast-Duplikate übrig: entfällt, Urteil traegt mit einer Probe.
--
-- Isoliert wie lsa_v2_ausblick (eigener Graph, tasks.skill_key -> NULL). Antworten über lsa_submit: r richtig,
-- f falsch (NUMERIC 5/7, MC a/b).
--
-- Graph (Klasse, Tiefe), Kind Klasse 8, ohne behandelte Themen:
--   zl_akt: Einstiege zl_a (8,3), zl_b (8,2), zl_c (8,1)
--   zl_u1, zl_u2, zl_u3 (die drei nächsten Plan-Themen): je ein Skill zl_u1s.. ohne Aufgabe, der zl_ra, zl_rb
--   bzw. zl_rc (7,1) voraussetzt
-- Aufgaben: zl_a „Berechne 2 + 3.“ (Rang 1), „Berechne 4 + 1.“ (Rang 2, Fast-Duplikat), „Wie viel ist 2 + 3?“
--   (Rang 3); zl_b „Löse 2x = 10.“, „Löse 3x = 15.“ (nur Fast-Duplikate); zl_c „Berechne 1 + 4.“ (Rang 1,
--   Fast-Duplikat von zl_a), „Rechne aus: 1 + 4“ (Rang 2); zl_ra/rb/rc je eine eigene Aufgabe.
-- Plan Schule ZL, Kl. 8: 1 zl_akt, 2 zl_u1, 3 zl_u2, 4 zl_u3.
-- ============================================================================
begin;
-- Reihe 1 A1: einsatz hat keinen Default mehr; die Aufgaben dieses Tests gehören zum Pool {lsa} (nur in dieser Transaktion).
alter table public.tasks alter column einsatz set default '{lsa}';
create extension if not exists pgtap with schema extensions;

select plan(19);

-- --- a) lsa_text_schluessel ---------------------------------------------------
select is(public.lsa_text_schluessel('Berechne 2 + 3.', '[]'), public.lsa_text_schluessel('  BERECHNE   14 + 3,5. ', null),
  'a: nur Zahlen, Leerraum und Groß/Klein verschieden → gleicher Schlüssel');
select isnt(public.lsa_text_schluessel('Berechne 2 + 3.', '[]'), public.lsa_text_schluessel('Berechne 2 - 3.', '[]'),
  'a: anderes Rechenzeichen → anderer Schlüssel');
select isnt(public.lsa_text_schluessel('Löse.', '[{"nr":1,"prompt":"x + 2 = 5"}]'),
            public.lsa_text_schluessel('Löse.', '[{"nr":1,"prompt":"x · 2 = 5"}]'),
  'a: die prompts der parts zählen mit');
select is((select provolatile from pg_proc where oid = 'public.lsa_text_schluessel(text, jsonb)'::regprocedure), 'i'::"char",
  'a: lsa_text_schluessel ist immutable');
select ok(not has_function_privilege('authenticated', 'public.lsa_text_schluessel(text, jsonb)', 'execute')
          and not has_function_privilege('anon', 'public.lsa_text_schluessel(text, jsonb)', 'execute')
          and not has_function_privilege('authenticated', 'public.lsa_ausgegebene_schluessel(uuid)', 'execute')
          and not has_function_privilege('anon', 'public.lsa_ausgegebene_schluessel(uuid)', 'execute'),
  'a: keine Rechte für anon und authenticated');

select is(public.lsa_text_schluessel('  ', '[{"nr":1}]'), null, 'g: ohne Text kein Schlüssel');
select is(public.lsa_text_schluessel(null, null), null, 'g: question und parts leer: kein Schlüssel');

-- --- Isolation --------------------------------------------------------------
update tasks set skill_key = null where skill_key is not null;
delete from thema_einstieg;
delete from skill_kante;
delete from erklaer_kernidee;
delete from skills;

-- --- Graph -------------------------------------------------------------------
insert into skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
select k, upper(k), 'mathematik', kl, tf from (values
  ('zl_a', 8, 3), ('zl_b', 8, 2), ('zl_c', 8, 1), ('zl_u1s', 8, 2), ('zl_u2s', 8, 2), ('zl_u3s', 8, 2),
  ('zl_ra', 7, 1), ('zl_rb', 7, 1), ('zl_rc', 7, 1), ('zl_m', 8, 1)) v(k, kl, tf);
insert into skill_kante (skill_key, voraussetzt_skill_key) values
  ('zl_u1s', 'zl_ra'), ('zl_u2s', 'zl_rb'), ('zl_u3s', 'zl_rc');

insert into themen (thema_key, fach, klasse, label, stufe, sort) values
  ('zl_akt', 'mathematik', 8, 'ZL aktuell', 'erste', 8010), ('zl_u1', 'mathematik', 8, 'ZL U1', 'erste', 8020),
  ('zl_u2', 'mathematik', 8, 'ZL U2', 'erste', 8030), ('zl_u3', 'mathematik', 8, 'ZL U3', 'erste', 8040),
  ('zl_mc', 'mathematik', 8, 'ZL MC', 'erste', 8050);
insert into skill_thema (skill_key, thema_key) values
  ('zl_a', 'zl_akt'), ('zl_b', 'zl_akt'), ('zl_c', 'zl_akt'),
  ('zl_u1s', 'zl_u1'), ('zl_u2s', 'zl_u2'), ('zl_u3s', 'zl_u3'), ('zl_m', 'zl_mc');
insert into thema_einstieg (thema_key, skill_key) select thema_key, skill_key from skill_thema
 where skill_key like 'zl_%';

insert into tasks (cluster_id, content_type, input_type, status, question, source, source_ref, skill_key,
                   sondierrang, class_level)
select (select c.id from skill_clusters c join subjects sub on sub.id = c.subject_id
         where sub.name = 'Mathematik' order by c.sort_order limit 1),
       'exercise', 'NUMERIC', 'ready', v.q, 'test', 'zl-' || v.ref, v.sk, v.rang, 8
  from (values ('zl_a', 'Berechne 2 + 3.', 'a1', 1), ('zl_a', 'Berechne 4 + 1.', 'a2', 2),
               ('zl_a', 'Wie viel ist 2 + 3?', 'a3', 3),
               ('zl_b', 'Löse 2x = 10.', 'b1', 1), ('zl_b', 'Löse 3x = 15.', 'b2', 2),
               ('zl_c', 'Berechne 1 + 4.', 'c1', 1), ('zl_c', 'Rechne aus: 1 + 4', 'c2', 2),
               ('zl_ra', 'Rand A: 2 + 3', 'ra', 1), ('zl_rb', 'Rand B: 2 + 3', 'rb', 1),
               ('zl_rc', 'Rand C: 2 + 3', 'rc', 1)) v(sk, q, ref, rang);
-- zl_m (Thema zl_mc): zwei MC-Aufgaben, Fast-Duplikate.
insert into tasks (cluster_id, content_type, input_type, status, question, question_payload, source, source_ref,
                   skill_key, sondierrang, class_level)
select (select c.id from skill_clusters c join subjects sub on sub.id = c.subject_id
         where sub.name = 'Mathematik' order by c.sort_order limit 1),
       'exercise', 'MC', 'ready', v.q, '{"input_type":"MC","options":[{"id":"a","label":"5"},{"id":"b","label":"7"}]}'::jsonb,
       'test', 'zl-' || v.ref, 'zl_m', v.rang, 8
  from (values ('Welche Zahl ist 2 + 3?', 'm1', 1), ('Welche Zahl ist 1 + 4?', 'm2', 2)) v(q, ref, rang);
insert into task_solutions (task_id, correct_answers)
select id, case when input_type = 'MC' then '["a"]' else '["5"]' end::jsonb
  from tasks where source = 'test' and source_ref like 'zl-%';

-- --- Schule, Plan, Kind ---------------------------------------------------------
\set admin_uid 'dddddddd-dddd-dddd-dddd-0000000000c3'
insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid', 'lsal2-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values (:'admin_uid', 'lsal2-admin@test.local', 'admin', 'LSA-L2 Admin');
select set_config('request.jwt.claims', json_build_object('sub', :'admin_uid', 'role', 'authenticated')::text, true);

insert into schulen (name, ort) values ('ZL Schule', 'Testort');
insert into schul_themenplan (schule_id, fach, klasse, position, thema_key, uv_titel, halbjahr, quelle_url)
select s.id, 'mathematik', 8, p.pos, p.th, p.th, null::int, 'https://test.invalid'
  from schulen s cross join (values (1, 'zl_akt'), (2, 'zl_u1'), (3, 'zl_u2'), (4, 'zl_u3')) p(pos, th)
 where s.name = 'ZL Schule';

create function pg_temp.kind() returns uuid language plpgsql as $$
declare v_lead uuid; v_student uuid;
begin
  insert into leads (full_name, class_level, status, schule_id)
  values ('ZL Kind', 8, 'contacted', (select id from schulen where name = 'ZL Schule'))
  returning id into v_lead;
  insert into lead_themen (lead_id, fach, thema_key, status, quelle)
  values (v_lead, 'mathematik', 'zl_akt', 'aktuell', 'gespraech');
  perform set_config('edvance.allow_provisional', '1', true);
  insert into students (class_level, is_provisional, lead_id) values (8, true, v_lead) returning id into v_student;
  return v_student;
end $$;

create function pg_temp.t0() returns timestamptz language sql immutable as $$
  select '2026-10-05 08:00:00+00'::timestamptz
$$;

create function pg_temp.offen(p_sess uuid) returns uuid language sql as $$
  select a.task_id from lsa_ausgegeben a
   where a.session_id = p_sess
     and not exists (select 1 from lsa_responses r where r.session_id = p_sess and r.task_id = a.task_id)
   limit 1
$$;

-- Beantwortet nach Muster (r/f) im Minutenabstand; liefert die Folge der Aufgaben (source_ref ohne „zl-“), '-' = Ende.
create function pg_temp.folge(p_sess uuid, p_muster text) returns text language plpgsql as $$
declare v_task uuid; v_out text[]; i int;
begin
  v_task := pg_temp.offen(p_sess);
  v_out := array[coalesce((select substr(source_ref, 4) from tasks where id = v_task), '-')];
  for i in 1 .. length(p_muster) loop
    exit when v_task is null;
    perform public.lsa_submit(p_sess, v_task,
      jsonb_build_object('value', case when substr(p_muster, i, 1) = 'r' then '5' else '7' end),
      1000, pg_temp.t0() + i * interval '1 minute');
    v_task := pg_temp.offen(p_sess);
    v_out := v_out || coalesce((select substr(source_ref, 4) from tasks where id = v_task), '-');
  end loop;
  return array_to_string(v_out, ',');
end $$;

create function pg_temp.urteil(p_sess uuid, p_skill text) returns text language sql as $$
  select zustand || '/' || proben_anzahl || '/' || case when offen then 'offen' else 'final' end
    from lsa_skill_urteil where session_id = p_sess and skill_key = p_skill
$$;

-- Längste Folge gleicher Skills hintereinander in den ausgegebenen Aufgaben (Reihenfolge = Antwortreihenfolge).
create function pg_temp.laengster_lauf(p_folge text) returns int language sql as $$
  select coalesce(max(n), 0) from (
    select count(*) as n from (
      select s.sk, nr - row_number() over (partition by s.sk order by nr) as grp
        from unnest(string_to_array(p_folge, ',')) with ordinality u(x, nr)
        join tasks t on t.source_ref = 'zl-' || u.x
        cross join lateral (select t.skill_key as sk) s) y
     group by sk, grp) z
$$;

-- ============================================================================
-- b)–d), f): eine Sitzung
-- ============================================================================
select pg_temp.kind() as k1 \gset
select (public.lsa_start(:'k1', 8, 'Mathematik', 'adaptiv', pg_temp.t0()) ->> 'session_id')::uuid as s1 \gset
select pg_temp.folge(:'s1', 'frfrrrr') as f1 \gset
select is(:'f1'::text, 'a1,a3,b1,c2,ra,rb,rc,-',
  'Folge: zl_a Zweitbeleg ohne Fast-Duplikat (a3), zl_b ohne Zweitbeleg, zl_c ohne Fast-Duplikat von a1 (c2), Vorschau U1–U3');
select is(substr(:'f1', 1, 5), 'a1,a3', 'b: Zweitbeleg zu „Berechne 2 + 3.“ ist nicht „Berechne 4 + 1.“, sondern die andere Aufgabe');
select is(pg_temp.urteil(:'s1', 'zl_a'), 'traegt_teilweise/2/final', 'b: Zweitbeleg gewertet (falsch, dann richtig)');
select is(pg_temp.urteil(:'s1', 'zl_b'), 'traegt_nicht/1/final', 'c: nur Fast-Duplikate übrig → Zweitbeleg entfällt, Urteil mit einer Probe');
select ok(not exists (select 1 from lsa_ausgegeben a join tasks t on t.id = a.task_id
                       where a.session_id = :'s1' and t.source_ref = 'zl-b2'),
  'c: „Löse 3x = 15.“ wird nie ausgegeben');
select ok(not exists (select 1 from lsa_ausgegeben a join tasks t on t.id = a.task_id
                       where a.session_id = :'s1' and t.source_ref = 'zl-c1'),
  'd: „Berechne 1 + 4.“ (zl_c) gleicht der ausgegebenen „Berechne 2 + 3.“ (zl_a) und wird übersprungen');
select is((select count(*) - count(distinct public.lsa_text_schluessel(t.question, t.parts))
             from lsa_ausgegeben a join tasks t on t.id = a.task_id where a.session_id = :'s1'), 0::bigint,
  'b–d: kein Text-Schlüssel zweimal in der Sitzung');
select is(public.lsa_ausgegebene_schluessel(:'s1') @> array[public.lsa_text_schluessel('Berechne 9 + 9.', null)], true,
  'lsa_ausgegebene_schluessel enthält den Schlüssel der ausgegebenen Aufgaben');
select is(pg_temp.urteil(:'s1', 'zl_rc'), 'traegt/1/final',
  'f: Rand der dritten kommenden Klassenarbeit (zl_rc) wird direkt geprüft');

-- ============================================================================
-- e) Nie drei Aufgaben desselben Skills hintereinander
-- ============================================================================
select ok(pg_temp.laengster_lauf(:'f1') <= 2, 'e: Folge 1 — höchstens zwei Aufgaben eines Skills hintereinander');
select pg_temp.kind() as k2 \gset
select (public.lsa_start(:'k2', 8, 'Mathematik', 'adaptiv', pg_temp.t0()) ->> 'session_id')::uuid as s2 \gset
select pg_temp.folge(:'s2', 'ffffffffff') as f2 \gset
select ok(pg_temp.laengster_lauf(:'f2') <= 2 and :'f2' like 'a1,a3,%',
  'e: Folge 2 (alles falsch) — nach dem Zweitbeleg nie eine dritte Aufgabe desselben Skills: ' || :'f2');

-- ============================================================================
-- h) MC richtig, Zweitbeleg nur als Fast-Duplikat: entfällt
-- ============================================================================
create function pg_temp.kind_mc() returns uuid language plpgsql as $$
declare v_lead uuid; v_student uuid;
begin
  insert into leads (full_name, class_level, status) values ('ZL Kind MC', 8, 'contacted') returning id into v_lead;
  insert into lead_themen (lead_id, fach, thema_key, status, quelle) values (v_lead, 'mathematik', 'zl_mc', 'aktuell', 'gespraech');
  perform set_config('edvance.allow_provisional', '1', true);
  insert into students (class_level, is_provisional, lead_id) values (8, true, v_lead) returning id into v_student;
  return v_student;
end $$;
select pg_temp.kind_mc() as k3 \gset
select (public.lsa_start(:'k3', 8, 'Mathematik', 'adaptiv', pg_temp.t0()) ->> 'session_id')::uuid as s3 \gset
select public.lsa_submit(:'s3', pg_temp.offen(:'s3'), '{"selected":["a"]}'::jsonb, 1000, pg_temp.t0() + interval '1 minute')
  is not null as gesendet \gset
select is(pg_temp.urteil(:'s3', 'zl_m'), 'traegt/1/final',
  'h: MC richtig, als Zweitbeleg nur „Welche Zahl ist 1 + 4?“ (Fast-Duplikat) — Zweitbeleg entfällt, traegt mit einer Probe');

select * from finish();
rollback;
