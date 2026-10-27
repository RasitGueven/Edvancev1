-- ============================================================================
-- LSA-V2: Ausblick, „Weiß ich nicht“ ohne Zweitbeleg, Deckel 40
-- (docs/lsa/Bauauftrag-LSA-V2.md, Entscheidungen 1–10; Migration 20261022131358_lsa_v2_ausblick)
--
--   a) Starkes Kind: nach Vorschau und Thema vertiefen der Ausblick, vor dem Rueckblick; Reihenfolge naechstes
--      Thema zuerst, im Thema kleinste Tiefe, dann Schluessel; Plan der Klasse + 1, wenn der Plan der Klasse
--      nicht reicht; Klassengrenze grade + 1; ohne freie Aufgabe uebersprungen; nach MC-„voll“ ein Zweitbeleg.
--   b) Nicht stark (unter 75 % traegt) oder zu wenig Urteile (unter 6): kein Ausblick.
--   c) Stopp nach zwei Ausblick-Knoten hintereinander nicht traegt; eine falsche erste Probe ist final; kein
--      Abstieg unter Ausblick-Knoten; ein einzelner Fehler stoppt nicht.
--   d) „Weiß ich nicht“ als erste Probe final (auch im Thema); falsch und MC richtig behalten den Zweitbeleg.
--   e) Deckel: null ab 40 ausgegebenen Aufgaben, mit und ohne Thema.
--   f) lsa_ausblick_knoten / lsa_ist_ausblick: Definition, behandelte Themen, ohne Plan, ohne Thema, Rechte.
--
-- Isoliert wie lsa_v_vorschau (eigener Graph, tasks.skill_key -> NULL). Antworten ueber lsa_submit: r richtig,
-- f falsch, w „Weiß ich nicht“ (NUMERIC 5/7, MC a/b).
--
-- Graph (Klasse, Tiefe), Pfeil = setzt voraus; Kind Klasse 8:
--   za_akt   (sort 8010): Einstiege za_a1..za_a6 (8,6), za_a6 nur MC
--   za_u1    (sort 8020): Einstiege za_u1a (8,5) -> za_r1 (7,2); za_u1b (8,3); za_u1c (8,3) ohne Aufgabe
--   za_u2    (sort 8030): Einstiege za_u2a (8,2) nur MC; za_u2x (10,1)
--   za_klp3  (sort 8040): Einstieg za_k3 (8,4)
--   za_n     (Kl. 9)    : Einstieg za_n1 (9,4) -> za_n0 (9,1)
--   za_n2    (Kl. 9)    : Einstieg za_n2a (9,1)
--   za_klein (sort 8005): Einstiege za_k1, za_k2 (8,3)
--   za_alt   (Kl. 7, behandelt): Einstieg za_b1 (7,1)
--   ohne Thema: za_f01..za_f30 (7,1), Fuellmaterial fuer den Deckel
-- Plan Schule ZA: Kl. 8: 1 za_akt, 2 za_u1, 3 za_u2; Kl. 9: 1 za_n, 2 za_n2. Schule ZB: Kl. 8: 1 za_klein, 2 za_u1.
-- LSA-L3 (20261025223011): Die Vorschau fuellt jetzt aus Klasse 9 auf (za_n, za_n2). za_n0 steht deshalb auf
-- Klasse 9 statt 8, sonst zoege die Vorschau ihn als Rand von za_n; der Ausblick bleibt, wie er war.
-- ============================================================================
begin;
-- Reihe 1 A1: einsatz hat keinen Default mehr; die Aufgaben dieses Tests gehören zum Pool {lsa} (nur in dieser Transaktion).
alter table public.tasks alter column einsatz set default '{lsa}';
create extension if not exists pgtap with schema extensions;

select plan(37);
-- LSA ohne Ausblick (20261025220449): der Ausblick ist in Prod aus; dieser Test prueft den Mechanismus mit Schalter.
set local lsa.ausblick = 'an';

-- --- Isolation --------------------------------------------------------------
update tasks set skill_key = null where skill_key is not null;
delete from thema_einstieg;
delete from skill_kante;
delete from erklaer_kernidee;
delete from skills;

-- --- Graph -------------------------------------------------------------------
insert into skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
select k, upper(k), 'mathematik', kl, tf from (values
  ('za_a1', 8, 6), ('za_a2', 8, 6), ('za_a3', 8, 6), ('za_a4', 8, 6), ('za_a5', 8, 6), ('za_a6', 8, 6),
  ('za_u1a', 8, 5), ('za_r1', 7, 2), ('za_u1b', 8, 3), ('za_u1c', 8, 3), ('za_u2a', 8, 2), ('za_u2x', 10, 1),
  ('za_k3', 8, 4), ('za_n1', 9, 4), ('za_n0', 9, 1), ('za_n2a', 9, 1), ('za_k1', 8, 3), ('za_k2', 8, 3),
  ('za_b1', 7, 1)) v(k, kl, tf)
union all
select 'za_f' || lpad(i::text, 2, '0'), 'ZA F', 'mathematik', 7, 1 from generate_series(1, 30) i;

insert into skill_kante (skill_key, voraussetzt_skill_key) values ('za_u1a', 'za_r1'), ('za_n1', 'za_n0');

insert into themen (thema_key, fach, klasse, label, stufe, sort) values
  ('za_alt', 'mathematik', 7, 'ZA behandelt', 'erste', 7000),
  ('za_klein', 'mathematik', 8, 'ZA klein', 'erste', 8005),
  ('za_akt', 'mathematik', 8, 'ZA aktuell', 'erste', 8010),
  ('za_u1', 'mathematik', 8, 'ZA U1', 'erste', 8020),
  ('za_u2', 'mathematik', 8, 'ZA U2', 'erste', 8030),
  ('za_klp3', 'mathematik', 8, 'ZA KLP 3', 'erste', 8040),
  ('za_n', 'mathematik', 9, 'ZA Klasse 9', 'zweite', 9010),
  ('za_n2', 'mathematik', 9, 'ZA Klasse 9 b', 'zweite', 9020);

insert into skill_thema (skill_key, thema_key)
select k, th from (values
  ('za_a1', 'za_akt'), ('za_a2', 'za_akt'), ('za_a3', 'za_akt'), ('za_a4', 'za_akt'), ('za_a5', 'za_akt'),
  ('za_a6', 'za_akt'), ('za_u1a', 'za_u1'), ('za_u1b', 'za_u1'), ('za_u1c', 'za_u1'), ('za_u2a', 'za_u2'),
  ('za_u2x', 'za_u2'), ('za_k3', 'za_klp3'), ('za_n1', 'za_n'), ('za_n2a', 'za_n2'), ('za_k1', 'za_klein'),
  ('za_k2', 'za_klein'), ('za_b1', 'za_alt')) v(k, th);
insert into thema_einstieg (thema_key, skill_key) select thema_key, skill_key from skill_thema
 where skill_key like 'za_%';

-- Zwei Aufgaben je Skill (za_a6, za_u2a nur MC; za_u1c keine).
insert into tasks (cluster_id, content_type, input_type, status, question, question_payload,
                   source, source_ref, skill_key, sondierrang, class_level)
select (select c.id from skill_clusters c join subjects sub on sub.id = c.subject_id
         where sub.name = 'Mathematik' order by c.sort_order limit 1),
       'exercise', case when s.skill_key in ('za_a6', 'za_u2a') then 'MC' else 'NUMERIC' end, 'ready',
       'Wie viel ist 2 + 3?',
       case when s.skill_key in ('za_a6', 'za_u2a')
            then '{"input_type":"MC","options":[{"id":"a","label":"5"},{"id":"b","label":"7"}]}'::jsonb end,
       'test', 'za-' || s.skill_key || '-' || n, s.skill_key, n, 8
  from skills s cross join generate_series(1, 2) n
 where s.skill_key <> 'za_u1c';
insert into task_solutions (task_id, correct_answers)
select id, case when input_type = 'MC' then '["a"]' else '["5"]' end::jsonb
  from tasks where source = 'test' and source_ref like 'za-%';
-- LSA-L2 (20261025144025): eindeutige Texte, sonst waere jede weitere Aufgabe ein Fast-Duplikat (lsa_text_schluessel)
-- der ersten — die Fixture nutzt ueberall denselben Aufgabentext.
update tasks set question = question || ' ' || translate(md5(id::text), '0123456789', 'ghijklmnop')
 where source = 'test' and source_ref like 'za-%';

-- --- Schulen und Plaene -------------------------------------------------------
\set admin_uid 'dddddddd-dddd-dddd-dddd-0000000000c2'
insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid', 'lsav2-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values (:'admin_uid', 'lsav2-admin@test.local', 'admin', 'LSA-V2 Admin');
select set_config('request.jwt.claims', json_build_object('sub', :'admin_uid', 'role', 'authenticated')::text, true);

insert into schulen (name, ort) values ('ZA Schule', 'Testort'), ('ZB Schule', 'Testort');
insert into schul_themenplan (schule_id, fach, klasse, position, thema_key, uv_titel, halbjahr, quelle_url)
select s.id, 'mathematik', p.kl, p.pos, p.th, p.th, null::int, 'https://test.invalid'
  from schulen s cross join (values (8, 1, 'za_akt'), (8, 2, 'za_u1'), (8, 3, 'za_u2'),
                                    (9, 1, 'za_n'), (9, 2, 'za_n2')) p(kl, pos, th)
 where s.name = 'ZA Schule'
union all
select s.id, 'mathematik', 8, p.pos, p.th, p.th, null::int, 'https://test.invalid'
  from schulen s cross join (values (1, 'za_klein'), (2, 'za_u1')) p(pos, th)
 where s.name = 'ZB Schule';

-- Ein Kind der Klasse 8: Lead mit aktuell-Thema und behandelten Themen, Schule am Lead.
create function pg_temp.kind(p_aktuell text, p_schule text, p_behandelt text[] default array['za_alt'])
returns uuid language plpgsql as $$
declare v_lead uuid; v_student uuid;
begin
  insert into leads (full_name, class_level, status, schule_id)
  values ('ZA Kind', 8, 'contacted', (select id from schulen where name = p_schule))
  returning id into v_lead;
  if p_aktuell is not null then
    insert into lead_themen (lead_id, fach, thema_key, status, quelle)
    values (v_lead, 'mathematik', p_aktuell, 'aktuell', 'gespraech');
  end if;
  insert into lead_themen (lead_id, fach, thema_key, status, quelle)
  select v_lead, 'mathematik', b, 'behandelt', 'schulplan' from unnest(p_behandelt) b;
  perform set_config('edvance.allow_provisional', '1', true);
  insert into students (class_level, is_provisional, lead_id) values (8, true, v_lead) returning id into v_student;
  return v_student;
end $$;

create function pg_temp.t0() returns timestamptz language sql immutable as $$
  select '2026-10-05 08:00:00+00'::timestamptz
$$;

create function pg_temp.start(p_student uuid) returns uuid language sql as $$
  select (public.lsa_start(p_student, 8, 'Mathematik', 'adaptiv', pg_temp.t0()) ->> 'session_id')::uuid
$$;

create function pg_temp.offen(p_sess uuid) returns uuid language sql as $$
  select a.task_id from lsa_ausgegeben a
   where a.session_id = p_sess
     and not exists (select 1 from lsa_responses r where r.session_id = p_sess and r.task_id = a.task_id)
   limit 1
$$;

-- Beantwortet nach Muster (r/f/w) im Abstand p_schritt, liefert die Folge der Knoten; '-' = nichts mehr.
create function pg_temp.folge(p_sess uuid, p_muster text, p_schritt interval default '1 minute')
returns text language plpgsql as $$
declare v_task uuid; v_mc boolean; v_out text[]; i int; c text;
begin
  v_task := pg_temp.offen(p_sess);
  v_out := array[coalesce((select skill_key from tasks where id = v_task), '-')];
  for i in 1 .. length(p_muster) loop
    exit when v_task is null;
    c := substr(p_muster, i, 1);
    v_mc := (select input_type = 'MC' from tasks where id = v_task);
    perform public.lsa_submit(
      p_sess, v_task,
      case when c = 'w' then '{"dont_know":true}'::jsonb
           when v_mc then jsonb_build_object('selected', jsonb_build_array(case when c = 'r' then 'a' else 'b' end))
           else jsonb_build_object('value', case when c = 'r' then '5' else '7' end) end,
      1000, pg_temp.t0() + i * p_schritt);
    v_task := pg_temp.offen(p_sess);
    v_out := v_out || coalesce((select skill_key from tasks where id = v_task), '-');
  end loop;
  return array_to_string(v_out, ',');
end $$;

create function pg_temp.urteil(p_sess uuid, p_skill text) returns text language sql as $$
  select zustand || '/' || proben_anzahl || '/' || case when offen then 'offen' else 'final' end
    from lsa_skill_urteil where session_id = p_sess and skill_key = p_skill
$$;

-- ============================================================================
-- a) Starkes Kind: Ausblick vor dem Rueckblick
-- ============================================================================
select pg_temp.kind('za_akt', 'ZA Schule') as k_a \gset
select pg_temp.start(:'k_a') as s_a \gset
select is(pg_temp.folge(:'s_a', repeat('r', 14)),
  'za_a1,za_a2,za_a3,za_a4,za_a5,za_a6,za_a6,za_r1,za_u1b,za_u1a,za_u2a,za_u2a,za_n1,za_b1,-',
  'a: Thema, Vorschau (za_r1), Ausblick U1 (Tiefe 3 vor 5, za_u1c ohne Aufgabe), U2 (MC: Zweitbeleg), Kl. 9, Rueckblick, Ende');
select is(public.lsa_ausblick_knoten(:'s_a'), array['za_u1b', 'za_u1c', 'za_u1a', 'za_u2a', 'za_n1'],
  'a: Ausblick-Knoten: naechstes Thema zuerst, kleinste Tiefe, Schluessel; drittes Thema aus dem Plan der Klasse 9');
select ok(not ('za_u2x' = any (public.lsa_ausblick_knoten(:'s_a'))) and not ('za_n2a' = any (public.lsa_ausblick_knoten(:'s_a'))),
  'a: Klassengrenze grade + 1 (za_u2x ist Klasse 10), hoechstens drei Themen (za_n2 ist das vierte)');
select is(pg_temp.urteil(:'s_a', 'za_u1b'), 'traegt/1/final', 'a: NUMERIC „voll“ im Ausblick ist sofort final');
select is(pg_temp.urteil(:'s_a', 'za_u2a'), 'traegt/2/final', 'a: MC „voll“ im Ausblick bekommt den Zweitbeleg');

-- ============================================================================
-- b) Nicht stark genug: kein Ausblick
-- ============================================================================
select pg_temp.kind('za_akt', 'ZA Schule') as k_b \gset
select pg_temp.start(:'k_b') as s_b \gset
select is(pg_temp.folge(:'s_b', 'ffffffrrrrrr'),
  'za_a1,za_a1,za_a2,za_a2,za_a3,za_a3,za_a4,za_a5,za_a6,za_a6,za_r1,za_b1,-',
  'b: 4 von 7 traegt (57 %) — kein Ausblick, gleich der Rueckblick, dann Ende (5 von 8)');
-- Die Staerke gilt bei jedem Aufruf: Hebt erst das Urteil im Rueckblick das Kind auf 75 %, kommt der Ausblick danach.
select pg_temp.kind('za_akt', 'ZA Schule') as k_b3 \gset
select pg_temp.start(:'k_b3') as s_b3 \gset
select is(pg_temp.folge(:'s_b3', 'ffffrrrrrrr'),
  'za_a1,za_a1,za_a2,za_a2,za_a3,za_a4,za_a5,za_a6,za_a6,za_r1,za_b1,za_u1b',
  'b: 5 von 7 (71 %) — Rueckblick; mit za_b1 sind es 6 von 8 (75 %), dann der Ausblick');
select pg_temp.kind('za_klein', 'ZB Schule') as k_b2 \gset
select pg_temp.start(:'k_b2') as s_b2 \gset
select is(pg_temp.folge(:'s_b2', 'rrrr'), 'za_k1,za_k2,za_r1,za_b1,-',
  'b: alles sicher, aber nur 3 Urteile (unter 6) — kein Ausblick');
select is(public.lsa_ausblick_knoten(:'s_b2'), array['za_u1b', 'za_u1c', 'za_u1a'],
  'b: ... obwohl es Ausblick-Knoten gibt (Plan ZB: nur za_u1 kommt)');

-- ============================================================================
-- c) Stopp, finale Fehler, kein Abstieg
-- ============================================================================
select pg_temp.kind('za_akt', 'ZA Schule') as k_c \gset
select pg_temp.start(:'k_c') as s_c \gset
select is(pg_temp.folge(:'s_c', 'rrrrrrrrffr'),
  'za_a1,za_a2,za_a3,za_a4,za_a5,za_a6,za_a6,za_r1,za_u1b,za_u1a,za_b1,-',
  'c: zwei Ausblick-Knoten hintereinander nicht traegt (noch 78 % traegt) -> Ausblick endet, Rueckblick');
select is(pg_temp.urteil(:'s_c', 'za_u1b'), 'traegt_nicht/1/final', 'c: falsche erste Probe im Ausblick ist final');
select ok(not exists (select 1 from lsa_ausgegeben a join tasks t on t.id = a.task_id
                       where a.session_id = :'s_c' and t.skill_key = 'za_r1' and a.task_id not in (
                         select a2.task_id from lsa_ausgegeben a2 join tasks t2 on t2.id = a2.task_id
                          where a2.session_id = :'s_c' and t2.skill_key = 'za_r1' order by a2.ausgegeben_am limit 1)),
  'c: unter dem gebrochenen za_u1a kein Abstieg (za_r1 nur einmal, aus der Vorschau)');

select pg_temp.kind('za_akt', 'ZA Schule') as k_c2 \gset
select pg_temp.start(:'k_c2') as s_c2 \gset
select is(pg_temp.folge(:'s_c2', 'rrrrrrrrfrffr'),
  'za_a1,za_a2,za_a3,za_a4,za_a5,za_a6,za_a6,za_r1,za_u1b,za_u1a,za_u2a,za_n1,za_b1,-',
  'c: ein einzelner Fehler stoppt nicht; MC falsch im Ausblick ohne Zweitbeleg');
select is(pg_temp.urteil(:'s_c2', 'za_u2a'), 'traegt_nicht/1/final', 'c: ... za_u2a (MC falsch) final mit einer Probe');
select ok(not exists (select 1 from lsa_ausgegeben a join tasks t on t.id = a.task_id
                       where a.session_id = :'s_c2' and t.skill_key = 'za_n0'),
  'c: unter dem gebrochenen za_n1 kein Abstieg zu za_n0');

-- ============================================================================
-- d) „Weiß ich nicht“ ohne Zweitbeleg
-- ============================================================================
select pg_temp.kind('za_akt', 'ZA Schule') as k_d \gset
select pg_temp.start(:'k_d') as s_d \gset
select is(pg_temp.folge(:'s_d', 'wffrrrrr'),
  'za_a1,za_a2,za_a2,za_a3,za_a4,za_a5,za_a6,za_a6,za_r1',
  'd: „Weiß ich nicht“ im Thema -> naechster Knoten; falsch und MC richtig behalten den Zweitbeleg');
select is(pg_temp.urteil(:'s_d', 'za_a1'), 'nicht_angesetzt/1/final', 'd: za_a1 nicht_angesetzt, eine Probe, final');
select is(pg_temp.urteil(:'s_d', 'za_a2'), 'traegt_nicht/2/final', 'd: za_a2 nach zwei Fehlern final');
select is(pg_temp.urteil(:'s_d', 'za_a6'), 'traegt/2/final', 'd: za_a6 (MC richtig) mit Zweitbeleg');
select pg_temp.kind(null, 'ZA Schule') as k_d2 \gset
select pg_temp.start(:'k_d2') as s_d2 \gset
select pg_temp.folge(:'s_d2', 'w') as d2 \gset
select is((select count(*)::int from lsa_skill_urteil where session_id = :'s_d2' and offen), 0,
  'd: auch ohne Thema kein offenes Urteil nach „Weiß ich nicht“');
select is((select string_agg(zustand || '/' || proben_anzahl, ',') from lsa_skill_urteil
            where session_id = :'s_d2' and belegt_direkt), 'nicht_angesetzt/1', 'd: ... nicht_angesetzt mit einer Probe');

-- Direkt ueber lsa_urteil_buchen_core: „leer“ (flach) und „Weiß ich nicht“ in allen Teilen (Multi-Part).
insert into skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe) values ('za_m', 'ZA M', 'mathematik', 7, 1);
insert into tasks (cluster_id, content_type, input_type, status, question, parts, est_duration_sec, source, source_ref, skill_key, class_level)
select (select c.id from skill_clusters c join subjects sub on sub.id = c.subject_id
         where sub.name = 'Mathematik' order by c.sort_order limit 1),
       'exercise', 'MULTI_PART', 'ready', 'Zwei Teile',
       '[{"nr":1,"afb":"I","kind":"short_input","unit":null,"prompt":"3 + 4?","competency_content":"zahlen","competency_process":null},
         {"nr":2,"afb":"I","kind":"short_input","unit":null,"prompt":"1 + 2?","competency_content":"zahlen","competency_process":null}]'::jsonb,
       120, 'test', 'za-m-mp', 'za_m', 7;
insert into lsa_responses (session_id, task_id, response, abgabeart, part_nr)
select :'s_d2', t.id, '{}'::jsonb, 'weiss_nicht', n from tasks t cross join generate_series(1, 2) n
 where t.source_ref = 'za-m-mp';
select is(public.lsa_urteil_buchen_core(:'s_d2', (select id from tasks where source_ref = 'za-m-mp')), 'nicht_angesetzt',
  'd: Multi-Part, alle Teile „Weiß ich nicht“ -> nicht_angesetzt');
select is(pg_temp.urteil(:'s_d2', 'za_m'), 'nicht_angesetzt/1/final', 'd: ... final mit einer Probe');
insert into lsa_responses (session_id, task_id, response, abgabeart)
select :'s_d2', t.id, '{}'::jsonb, 'leer' from tasks t where t.source_ref = 'za-za_k1-1';
select is(public.lsa_urteil_buchen_core(:'s_d2', (select id from tasks where source_ref = 'za-za_k1-1')), 'nicht_angesetzt',
  'd: flach, leer abgegeben -> nicht_angesetzt');
select is(pg_temp.urteil(:'s_d2', 'za_k1'), 'nicht_angesetzt/1/final', 'd: ... final mit einer Probe');

-- ============================================================================
-- e) Deckel 40
-- ============================================================================
-- Durchklicker ohne Thema: alles falsch, alle 5 Sekunden.
select pg_temp.kind(null, 'ZA Schule') as k_e \gset
select pg_temp.start(:'k_e') as s_e \gset
select pg_temp.folge(:'s_e', repeat('f', 60), '5 seconds') as e_folge \gset
select is((select count(*)::int from lsa_ausgegeben where session_id = :'s_e'), 40,
  'e: Durchklicker ohne Thema — genau 40 Aufgaben ausgegeben');
select is(public.lsa_select_next_core(:'s_e', array['ready'], pg_temp.t0() + interval '4 minutes'), null::uuid,
  'e: ... danach null, nach knapp 4 Minuten (die Zeit greift nicht)');
select ok(exists (select 1 from tasks t where t.skill_key like 'za_f%' and not exists (
                    select 1 from lsa_ausgegeben a where a.session_id = :'s_e' and a.task_id = t.id)),
  'e: ... obwohl noch freie Aufgaben da sind');
-- Mit Thema: 39 ausgegeben -> weiter, 40 -> null.
select pg_temp.kind('za_akt', 'ZA Schule') as k_e2 \gset
select pg_temp.start(:'k_e2') as s_e2 \gset
insert into lsa_ausgegeben (session_id, task_id)
select :'s_e2', t.id from tasks t where t.skill_key like 'za_f%' order by t.source_ref limit 38;
select isnt(public.lsa_select_next_core(:'s_e2', array['ready'], pg_temp.t0() + interval '1 minute'), null::uuid,
  'e: mit Thema, 39 ausgegeben -> die Auswahl liefert noch');
insert into lsa_ausgegeben (session_id, task_id)
select :'s_e2', t.id from tasks t where t.skill_key like 'za_f%' order by t.source_ref offset 38 limit 1;
select is(public.lsa_select_next_core(:'s_e2', array['ready'], pg_temp.t0() + interval '1 minute'), null::uuid,
  'e: mit Thema, 40 ausgegeben -> null');

-- ============================================================================
-- f) Definition
-- ============================================================================
select ok(public.lsa_ist_ausblick(:'s_a', 'za_u1b') and public.lsa_ist_ausblick(:'s_a', 'za_n1'),
  'f: lsa_ist_ausblick fuer Einstiege der naechsten Themen');
select ok(not public.lsa_ist_ausblick(:'s_a', 'za_a1') and not public.lsa_ist_ausblick(:'s_a', 'za_r1')
          and not public.lsa_ist_ausblick(:'s_a', 'za_n0') and not public.lsa_ist_ausblick(:'s_a', 'za_b1'),
  'f: nicht fuer Thema, Vorschau-Rand, Voraussetzungen und Rueckblick');
select pg_temp.kind('za_akt', 'ZA Schule', array['za_alt', 'za_u2']) as k_f \gset
select pg_temp.start(:'k_f') as s_f \gset
select is(public.lsa_ausblick_knoten(:'s_f'), array['za_u1b', 'za_u1c', 'za_u1a', 'za_n1'],
  'f: Einstiege behandelter Themen gehoeren dem Rueckblick, nicht dem Ausblick (za_u2a faellt weg)');
select pg_temp.kind('za_akt', null) as k_f2 \gset
select pg_temp.start(:'k_f2') as s_f2 \gset
select is(public.lsa_ausblick_knoten(:'s_f2'), array['za_u1b', 'za_u1c', 'za_u1a', 'za_u2a', 'za_k3'],
  'f: ohne Plan die Kernlehrplan-Folge der Stufe (za_n liegt in der naechsten Stufe)');
select is(public.lsa_ausblick_knoten(:'s_e'), '{}'::text[], 'f: ohne Thema keine Ausblick-Knoten');
select ok(not has_function_privilege('authenticated', 'public.lsa_ist_ausblick(uuid, text)', 'execute')
          and not has_function_privilege('anon', 'public.lsa_ist_ausblick(uuid, text)', 'execute')
          and not has_function_privilege('authenticated', 'public.lsa_ausblick_knoten(uuid, boolean)', 'execute')
          and not has_function_privilege('anon', 'public.lsa_ausblick_knoten(uuid, boolean)', 'execute'),
  'f: beide Hilfsfunktionen sind fuer anon/authenticated nicht aufrufbar');

-- LSA ohne Ausblick (20261025220449): ohne Schalter liefert lsa_ausblick_knoten nichts, auch fuer ein starkes Kind.
reset lsa.ausblick;
select is((select count(*)::int from lsa_sessions x, unnest(public.lsa_ausblick_knoten(x.id, true)) k
            where x.thema_key is not null), 0, 'ohne Schalter: kein Ausblick-Knoten in keiner Sitzung');

select * from finish();
rollback;
