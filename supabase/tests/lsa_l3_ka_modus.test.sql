-- ============================================================================
-- LSA-L3: Auswahl nach Klassenarbeits-Stand (docs/lsa/Bauauftrag-L3.md, Migration 20261025223011)
--
--   a) Modus je Status: geschrieben → vorschau_zuerst, bevorstehend und null → thema_zuerst.
--   b) 'thema_zuerst': Folge wie vor L3 bis auf das Auffuellen (Entscheidung 4) und die Klassengrenze (7).
--   c) 'vorschau_zuerst', Note 4: Thema kurz (4 Minuten, nur Einstiege), Vorschau, Rueckblick; kein vertiefen.
--   d) Note 2: Thema kurz endet nach 1 Minute.
--   e) Tiefe 'vorschau_zuerst' erst nach der Vorschau.
--   f) Modus bleibt in der Sitzung fest, auch wenn das Erstgespraech danach geaendert wird.
--   g) Auffuellen aus Klasse + 1: nur Voraussetzungen, nie ueber Klasse 9, nie Skills der Klasse-10-Themen.
--   h) Kein Ausblick ohne Schalter; 'vorschau_zuerst' auch mit Schalter nicht.
--   i) Klassengrenze (Entscheidung 7) ausserhalb des Themenraums; der Themenraum bleibt ohne (Stoff des aktuellen
--      Themas, auch wenn ein Einstieg im Kernlehrplan eine Klasse hoeher steht).
--   j) Fehlende Spalte letzte_klassenarbeit_note zaehlt wie null.
--
-- Isoliert wie lsa_v_vorschau (eigener Graph, tasks.skill_key -> NULL). Antworten ueber lsa_submit:
-- r = richtig, f = falsch, Abstand 1 Minute.
--
-- Graph (Klasse, Tiefe), Pfeil = setzt voraus; Kind Klasse 9:
--   zl_akt (aktuell)  : Einstiege zl_a1 (9,6) -> zl_g1 (8,1); zl_a2 (9,5), zl_a3 (9,4), zl_a5 (9,3), zl_a4 (10,2)
--   zl_u1  (Kl. 9, 2) : zl_u1a (9,5) -> zl_r1 (7,3)
--   zl_n1  (Kl. 10, 1): zl_n1a (10,5) -> zl_r2 (8,2), zl_r4 (10,1)
--   zl_n2  (Kl. 10, 2): zl_n2a (10,6) -> zl_r3 (6,2), zl_n1a
--   zl_alt (behandelt): zl_b1 (8,1)
-- Plan Schule ZL: Kl. 9: 1 zl_akt, 2 zl_u1; Kl. 10: 1 zl_n1, 2 zl_n2. Nach zl_akt kommt im Schuljahr nur zl_u1,
-- die Vorschau fuellt mit zl_n1, zl_n2 auf: Rand zl_r1, zl_r2 (zweimal: direkt und fuer zl_n1a), zl_r3; zl_r4 ist
-- Klasse 10.
-- ============================================================================
begin;
-- Reihe 1 A1: einsatz hat keinen Default mehr; die Aufgaben dieses Tests gehören zum Pool {lsa} (nur in dieser Transaktion).
alter table public.tasks alter column einsatz set default '{lsa}';
create extension if not exists pgtap with schema extensions;

select plan(23);

-- --- Isolation --------------------------------------------------------------
update tasks set skill_key = null where skill_key is not null;
delete from thema_einstieg;
delete from skill_kante;
delete from erklaer_kernidee;
delete from skills;

insert into skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
select k, upper(k), 'mathematik', kl, tf from (values
  ('zl_a1', 9, 6), ('zl_g1', 8, 1), ('zl_a2', 9, 5), ('zl_a3', 9, 4), ('zl_a5', 9, 3), ('zl_a4', 10, 2),
  ('zl_u1a', 9, 5), ('zl_r1', 7, 3), ('zl_n1a', 10, 5), ('zl_r2', 8, 2), ('zl_r4', 10, 1), ('zl_n2a', 10, 6),
  ('zl_r3', 6, 2), ('zl_b1', 8, 1)) v(k, kl, tf);

insert into skill_kante (skill_key, voraussetzt_skill_key) values
  ('zl_a1', 'zl_g1'), ('zl_u1a', 'zl_r1'), ('zl_n1a', 'zl_r2'), ('zl_n1a', 'zl_r4'), ('zl_n2a', 'zl_r3'),
  ('zl_n2a', 'zl_n1a');

insert into themen (thema_key, fach, klasse, label, stufe, sort) values
  ('zl_akt', 'mathematik', 9, 'ZL aktuell', 'zweite', 9110),
  ('zl_u1', 'mathematik', 9, 'ZL U1', 'zweite', 9120),
  ('zl_n1', 'mathematik', 10, 'ZL N1', 'zweite', 9130),
  ('zl_n2', 'mathematik', 10, 'ZL N2', 'zweite', 9140),
  ('zl_alt', 'mathematik', 8, 'ZL behandelt', 'erste', 8100);

insert into skill_thema (skill_key, thema_key) values
  ('zl_a1', 'zl_akt'), ('zl_g1', 'zl_akt'), ('zl_a2', 'zl_akt'), ('zl_a3', 'zl_akt'), ('zl_a5', 'zl_akt'),
  ('zl_a4', 'zl_akt'), ('zl_u1a', 'zl_u1'), ('zl_n1a', 'zl_n1'), ('zl_n2a', 'zl_n2'), ('zl_b1', 'zl_alt');

insert into thema_einstieg (thema_key, skill_key) values
  ('zl_akt', 'zl_a1'), ('zl_akt', 'zl_a2'), ('zl_akt', 'zl_a3'), ('zl_akt', 'zl_a5'), ('zl_akt', 'zl_a4'),
  ('zl_u1', 'zl_u1a'), ('zl_n1', 'zl_n1a'), ('zl_n2', 'zl_n2a'), ('zl_alt', 'zl_b1');

insert into tasks (cluster_id, content_type, input_type, status, question,
                   source, source_ref, skill_key, sondierrang, class_level)
select (select c.id from skill_clusters c join subjects sub on sub.id = c.subject_id
         where sub.name = 'Mathematik' order by c.sort_order limit 1),
       'exercise', 'NUMERIC', 'ready', 'Wie viel ist 2 + 3?',
       'test', 'zl-' || s.skill_key || '-' || n, s.skill_key, n, 9
  from skills s cross join generate_series(1, 2) n;
insert into task_solutions (task_id, correct_answers)
select id, '["5"]'::jsonb from tasks where source = 'test' and source_ref like 'zl-%';
update tasks set question = question || ' ' || translate(md5(id::text), '0123456789', 'ghijklmnop')
 where source = 'test' and source_ref like 'zl-%';

\set admin_uid 'dddddddd-dddd-dddd-dddd-0000000000c3'
insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid', 'lsal3-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values (:'admin_uid', 'lsal3-admin@test.local', 'admin', 'LSA-L3 Admin');
select set_config('request.jwt.claims', json_build_object('sub', :'admin_uid', 'role', 'authenticated')::text, true);

insert into schulen (name, ort) values ('ZL Schule', 'Testort');
insert into schul_themenplan (schule_id, fach, klasse, position, thema_key, uv_titel, halbjahr, quelle_url)
select s.id, 'mathematik', p.kl, p.pos, p.th, p.th, null, 'https://test.invalid'
  from schulen s cross join (values (9, 1, 'zl_akt'), (9, 2, 'zl_u1'), (10, 1, 'zl_n1'), (10, 2, 'zl_n2')) p(kl, pos, th)
 where s.name = 'ZL Schule';

-- Ein Kind der Klasse 9 mit Klassenarbeits-Stand; die Note per to_jsonb-freiem Update, damit j) ohne Spalte laeuft.
create function pg_temp.kind(p_status text, p_note int default null) returns uuid language plpgsql as $$
declare v_lead uuid; v_student uuid;
begin
  insert into leads (full_name, class_level, status, schule_id, klassenarbeit_status)
  values ('ZL Kind', 9, 'contacted', (select id from schulen where name = 'ZL Schule'), p_status)
  returning id into v_lead;
  if p_note is not null then
    execute 'update leads set letzte_klassenarbeit_note = $1 where id = $2' using p_note, v_lead;
  end if;
  insert into lead_themen (lead_id, fach, thema_key, status, quelle) values
    (v_lead, 'mathematik', 'zl_akt', 'aktuell', 'gespraech'), (v_lead, 'mathematik', 'zl_alt', 'behandelt', 'schulplan');
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

-- Beantwortet nach Muster im Abstand von einer Minute, liefert die Folge der Knoten; '-' = nichts mehr.
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

create function pg_temp.gezogen(p_sess uuid) returns text[] language sql as $$
  select coalesce(array_agg(distinct t.skill_key), '{}') from lsa_ausgegeben a join tasks t on t.id = a.task_id
   where a.session_id = p_sess
$$;

create function pg_temp.modus(p_sess uuid) returns text language sql as $$
  select ka_modus || coalesce('/' || ka_note, '') from lsa_sessions where id = p_sess
$$;

-- ============================================================================
-- a) Modus je Status
-- ============================================================================
select pg_temp.start(pg_temp.kind('geschrieben', 4)) as s_c \gset
select pg_temp.start(pg_temp.kind('geschrieben', 2)) as s_d \gset
select pg_temp.start(pg_temp.kind('bevorstehend')) as s_b \gset
select pg_temp.start(pg_temp.kind(null)) as s_n \gset
select is(pg_temp.modus(:'s_c'), 'vorschau_zuerst/4', 'a: geschrieben, Note 4 -> vorschau_zuerst');
select is(pg_temp.modus(:'s_b'), 'thema_zuerst', 'a: bevorstehend -> thema_zuerst');
select is(pg_temp.modus(:'s_n'), 'thema_zuerst', 'a: Status unbekannt (null) -> thema_zuerst');

-- ============================================================================
-- b) 'thema_zuerst': Thema mit vertiefen wie vor L3, Vorschau mit Auffuellen
-- ============================================================================
select is(pg_temp.folge(:'s_b', repeat('r', 12)),
  'zl_a1,zl_a2,zl_a3,zl_a5,zl_a4,zl_r2,zl_r1,zl_r3,zl_b1,-',
  'b: thema_zuerst: alle Einstiege, dann Vorschau (zl_r2 fuer zwei Themen zuerst), Rueckblick, Ende');
select is(pg_temp.folge(:'s_n', repeat('r', 12)),
  'zl_a1,zl_a2,zl_a3,zl_a5,zl_a4,zl_r2,zl_r1,zl_r3,zl_b1,-', 'b: Status null wie bevorstehend');

-- ============================================================================
-- c) 'vorschau_zuerst', Note 4
-- ============================================================================
select pg_temp.kind('geschrieben', 4) as k_c2 \gset
select pg_temp.start(:'k_c2') as s_c2 \gset
select is(pg_temp.folge(:'s_c', repeat('r', 12)),
  'zl_a1,zl_a2,zl_a3,zl_a5,zl_r2,zl_r1,zl_r3,zl_b1,-',
  'c: Note 4: vier Einstiege in vier Minuten, dann Vorschau, Rueckblick');
-- Mit fuenf Minuten je Antwort endet Thema kurz nach dem ersten Einstieg (Minute 5 > 4).
create function pg_temp.folge5(p_sess uuid, p_n int) returns text language plpgsql as $$
declare v_task uuid; v_out text[]; i int;
begin
  v_task := pg_temp.offen(p_sess);
  v_out := array[coalesce((select skill_key from tasks where id = v_task), '-')];
  for i in 1 .. p_n loop
    exit when v_task is null;
    perform public.lsa_submit(p_sess, v_task, '{"value":"5"}', 1000, pg_temp.t0() + i * interval '5 minutes');
    v_task := pg_temp.offen(p_sess);
    v_out := v_out || coalesce((select skill_key from tasks where id = v_task), '-');
  end loop;
  return array_to_string(v_out, ',');
end $$;
select is(pg_temp.folge5(:'s_c2', 5), 'zl_a1,zl_r2,zl_r1,zl_r3,-',
  'c: nach Minute 4 kein Einstieg mehr, kein Thema vertiefen; Minute 20 -> Ende');
select ok(not (pg_temp.gezogen(:'s_c2') && array['zl_a2', 'zl_a3', 'zl_a5']),
  'c: ... die uebrigen Einstiege kommen nicht (kein vertiefen in vorschau_zuerst)');

-- ============================================================================
-- d) Note 2: Thema kurz 1 Minute
-- ============================================================================
select is(pg_temp.modus(:'s_d'), 'vorschau_zuerst/2', 'd: Note 2 gespeichert');
select is(pg_temp.folge(:'s_d', repeat('r', 12)), 'zl_a1,zl_r2,zl_r1,zl_r3,zl_b1,-',
  'd: Note 2: nach zl_a1 ist Minute 1 erreicht, Thema kurz endet, dann Vorschau');

-- ============================================================================
-- e) Tiefe 'vorschau_zuerst' nach der Vorschau, 'thema_zuerst' davor (nach Phase T, wie vor L3)
-- ============================================================================
select pg_temp.start(pg_temp.kind('geschrieben', 4)) as s_e \gset
select is(pg_temp.folge(:'s_e', 'ffrrrrrrrrrr'), 'zl_a1,zl_a1,zl_a2,zl_a3,zl_r2,zl_r1,zl_r3,zl_g1,zl_b1,-',
  'e: zl_a1 bricht -> zl_g1 erst nach der Vorschau');
select pg_temp.start(pg_temp.kind('bevorstehend')) as s_e2 \gset
select is(pg_temp.folge(:'s_e2', 'ffrrrrrrrrrr'), 'zl_a1,zl_a1,zl_a2,zl_a3,zl_a5,zl_a4,zl_g1,zl_r2,zl_r1,zl_r3,zl_b1,-',
  'e: thema_zuerst: Tiefe zl_g1 nach den Einstiegen, vor der Vorschau (wie vor L3)');

-- ============================================================================
-- f) Modus fest
-- ============================================================================
select pg_temp.kind('geschrieben', 4) as k_f \gset
select pg_temp.start(:'k_f') as s_f \gset
update leads set klassenarbeit_status = 'bevorstehend'
 where id = (select lead_id from students where id = :'k_f');
select is(pg_temp.folge5(:'s_f', 5), 'zl_a1,zl_r2,zl_r1,zl_r3,-',
  'f: Erstgespraech nach dem Start auf bevorstehend -> Auswahl bleibt vorschau_zuerst');
select is(pg_temp.modus(:'s_f'), 'vorschau_zuerst/4', 'f: ka_modus unveraendert');
-- Eine Sitzung, die schon Aufgaben hat, bevor der Modus feststeht (vor L3 gestartet), bleibt thema_zuerst.
select pg_temp.start(pg_temp.kind('geschrieben', 4)) as s_f2 \gset
update lsa_sessions set ka_modus = null, ka_note = null where id = :'s_f2';
select public.lsa_select_next_core(:'s_f2', array['ready'], pg_temp.t0()) is not null as f2 \gset
select is(pg_temp.modus(:'s_f2'), 'thema_zuerst/4',
  'f: vor L3 gestartete Sitzung (schon Aufgaben, kein Modus) -> thema_zuerst');

-- ============================================================================
-- g) Auffuellen aus Klasse + 1
-- ============================================================================
select ok(pg_temp.gezogen(:'s_c') @> array['zl_r2', 'zl_r3'], 'g: Rand der Klasse-10-Themen zl_n1, zl_n2 geprueft');
select ok(not (pg_temp.gezogen(:'s_c') && array['zl_r4', 'zl_n1a', 'zl_n2a', 'zl_a4']),
  'g: nie zl_r4 (Klasse 10), nie Skills der Klasse-10-Themen (zl_n1a, zl_n2a)');
select is((select count(*)::int from lsa_ausgegeben a join tasks t on t.id = a.task_id join skills s using (skill_key)
            where a.session_id in (:'s_b', :'s_c', :'s_c2', :'s_d', :'s_e', :'s_e2', :'s_f', :'s_n')
              and s.klasse_herkunft > 9 and s.skill_key <> 'zl_a4'), 0,
  'g: in keiner Sitzung eine Aufgabe ueber Klasse 9 ausser dem Einstieg zl_a4 des aktuellen Themas');

-- ============================================================================
-- h) Kein Ausblick
-- ============================================================================
select ok(not (pg_temp.gezogen(:'s_b') && array['zl_u1a', 'zl_n1a', 'zl_n2a']),
  'h: thema_zuerst ohne Schalter: kein Einstieg kommender Themen');
set local lsa.ausblick = 'an';
select pg_temp.start(pg_temp.kind('geschrieben', 4)) as s_h \gset
select is(pg_temp.folge(:'s_h', repeat('r', 12)), 'zl_a1,zl_a2,zl_a3,zl_a5,zl_r2,zl_r1,zl_r3,zl_b1,-',
  'h: vorschau_zuerst mit Schalter lsa.ausblick: trotzdem kein Ausblick (zl_u1a)');
reset lsa.ausblick;

-- ============================================================================
-- i) Klassengrenze in Phase T
-- ============================================================================
select ok('zl_a4' = any (pg_temp.gezogen(:'s_b')) and not ('zl_r4' = any (pg_temp.gezogen(:'s_b'))),
  'i: Einstieg zl_a4 (Klasse 10) im Thema wie vor L3, Vorschau-Knoten zl_r4 (Klasse 10) nie');

-- ============================================================================
-- j) Spalte letzte_klassenarbeit_note fehlt
-- ============================================================================
alter table leads drop column letzte_klassenarbeit_note;
select pg_temp.start(pg_temp.kind('geschrieben')) as s_j \gset
select is(pg_temp.modus(:'s_j'), 'vorschau_zuerst', 'j: ohne Spalte: vorschau_zuerst, Note null');
select ok(not has_function_privilege('authenticated', 'public.lsa_klp_themen(text, integer)', 'execute')
          and not has_function_privilege('anon', 'public.lsa_klp_themen(text, integer)', 'execute'),
  'lsa_klp_themen ist fuer anon/authenticated nicht aufrufbar');

select * from finish();
rollback;
