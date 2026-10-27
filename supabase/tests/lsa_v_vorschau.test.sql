-- ============================================================================
-- LSA-V: Auswahl mit Thema — Vorschau, Thema vertiefen, Rueckblick, Ende
-- (docs/lsa/Bauauftrag-LSA-V.md, Entscheidungen 1–12)
--
--   a) Vorschau mit Plan: Randknoten mehrerer kommender Themen zuerst, dann das
--      naechste Plan-Thema; danach Rueckblick, dann null statt Fuellaufgabe.
--   b) Skills kommender Themen werden nie gezogen; eine Voraussetzung aus einem
--      Thema, das noch kommt (auch naechste Klasse), wird durch ihren Rand ersetzt.
--   c) Klassengrenze in der Vorschau.
--   d) Abstieg in der Vorschau nur unter Bruechen, Rand vor Tiefe.
--   e) Zeitgrenze 16 Minuten.
--   f) Position nach Halbjahr; Plan ohne Halbjahr: von vorn.
--   g) Ohne Plan: Kernlehrplan nach sort.
--   h) Thema vertiefen (ohne Klassengrenze), Rueckblick erst danach.
--   i) lsa_schule_von_sitzung: drei Wege wie R7-9.
--   j) Ohne Thema: dieselbe Folge wie vor LSA-V.
--
-- LSA-V2 (20261022131358): Wer nach der Vorschau mindestens 6 direkte Urteile mit 75 % traegt hat, bekommt vor
-- dem Rueckblick den Ausblick (Einstiege der naechsten Plan-Themen: zv_u2a, zv_u1a). Die Faelle a, d und f
-- zeigen ihn jetzt; die Vorschau selbst ist unveraendert. Mehr dazu in lsa_v2_ausblick.
-- LSA-L2 (20261025144025): Die Vorschau nimmt drei kommende Themen (c_vorschau_themen = 3). Mit Plan ZV ist zv_spaet
-- das dritte; sein Rand zv_r3 gehoert damit zu zwei kommenden Themen (direkt und als Ersatz fuer zv_x) und kommt
-- gleich nach zv_r1 (a, d, e, f). Ohne Plan (g) kommt zv_u2 als drittes Thema dazu, mit Rand zv_r5, zv_r7.
-- LSA-L3 (20261025223011): Kommen im Plan weniger als drei Themen, fuellt die Vorschau aus Klasse 10 auf (f): mit
-- Plan ZV zv_n (Rand zv_r7 statt zv_r6), ohne Plan der Klasse 10 (ZV2) aus dem Kernlehrplan, also ebenfalls zv_n.
--
-- Isoliert wie inv10 (eigener Graph, tasks.skill_key -> NULL). Antworten ueber
-- lsa_submit: {"value":"5"} richtig (r), {"value":"7"} falsch (f).
--
-- Graph (Klasse, Tiefe), Pfeil = setzt voraus; alles Fach Mathematik, Kind Klasse 9:
--   zv_akt   (sort 9010) : zv_a1 (9,4) -> zv_a2 (8,2)
--   zv_u1    (sort 9020) : zv_u1a (9,5) -> zv_r1, zv_x, zv_u1b ; zv_u1b (9,4) -> zv_r2
--   zv_u2    (sort 9030) : zv_u2a (9,5) -> zv_r1, zv_r4, zv_r5, zv_r6
--   zv_spaet (sort 9040) : zv_x (9,4) -> zv_r3
--   zv_n     (sort 9050) : zv_r6 (9,2) -> zv_r7          (Plan Klasse 10)
--   zv_hj    (sort 9015) : zv_h1 (9,1)                    (in keinem Plan)
--   zv_tief  (sort 9999) : zv_c1 (9,3) -> zv_c2 (8,2), zv_c3 (10,1)
--   zv_alt   (sort 8000) : zv_b1 (8,1)                    ('behandelt')
--   ohne Thema           : zv_r1 (7,3) -> zv_t1 (6,2) -> zv_t2 (5,1); zv_r2 (7,2); zv_r3 (6,3);
--                          zv_r4 (10,1); zv_r5 (8,2); zv_r7 (7,1); zv_f1 (7,1)
-- Plan Schule ZV (Mathematik): Kl. 9: 1 zv_akt HJ1, 2 zv_u2 HJ1, 3 (ohne Thema) HJ1, 4 zv_u1 HJ2,
--   5 zv_spaet HJ2; Kl. 10: 1 zv_n.  Plan Schule ZV2 (ohne Halbjahr): Kl. 9: 1 zv_u1, 2 zv_u2.
-- ============================================================================
begin;
-- Reihe 1 A1: einsatz hat keinen Default mehr; die Aufgaben dieses Tests gehören zum Pool {lsa} (nur in dieser Transaktion).
alter table public.tasks alter column einsatz set default '{lsa}';
create extension if not exists pgtap with schema extensions;

select plan(29);
-- LSA ohne Ausblick (20261025220449): der Ausblick ist in Prod aus; dieser Test prueft den Mechanismus mit Schalter.
set local lsa.ausblick = 'an';

-- --- Isolation --------------------------------------------------------------
update tasks set skill_key = null where skill_key is not null;
delete from thema_einstieg;
delete from skill_kante;
delete from erklaer_kernidee;
-- Reihe 1: Bauformen haengen per FK an skills; fuer die Isolation nur in dieser Transaktion loesen.
alter table bauformen drop constraint bauformen_skill_key_fkey;
delete from skills;

-- --- Graph -------------------------------------------------------------------
insert into skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
select k, upper(k), 'mathematik', kl, tf from (values
  ('zv_a1', 9, 4), ('zv_a2', 8, 2), ('zv_u1a', 9, 5), ('zv_u1b', 9, 4), ('zv_u2a', 9, 5),
  ('zv_x', 9, 4), ('zv_r6', 9, 2), ('zv_h1', 9, 1), ('zv_c1', 9, 3), ('zv_c2', 8, 2), ('zv_c3', 10, 1),
  ('zv_b1', 8, 1), ('zv_r1', 7, 3), ('zv_t1', 6, 2), ('zv_t2', 5, 1), ('zv_r2', 7, 2), ('zv_r3', 6, 3),
  ('zv_r4', 10, 1), ('zv_r5', 8, 2), ('zv_r7', 7, 1), ('zv_f1', 7, 1)) v(k, kl, tf);

insert into skill_kante (skill_key, voraussetzt_skill_key) values
  ('zv_a1', 'zv_a2'), ('zv_u1a', 'zv_r1'), ('zv_u1a', 'zv_x'), ('zv_u1a', 'zv_u1b'), ('zv_u1b', 'zv_r2'),
  ('zv_u2a', 'zv_r1'), ('zv_u2a', 'zv_r4'), ('zv_u2a', 'zv_r5'), ('zv_u2a', 'zv_r6'), ('zv_x', 'zv_r3'),
  ('zv_r6', 'zv_r7'), ('zv_c1', 'zv_c2'), ('zv_c1', 'zv_c3'), ('zv_r1', 'zv_t1'), ('zv_t1', 'zv_t2');

insert into themen (thema_key, fach, klasse, label, stufe, sort) values
  ('zv_akt', 'mathematik', 9, 'ZV aktuell', 'zweite', 9010),
  ('zv_hj', 'mathematik', 9, 'ZV ohne Plan', 'zweite', 9015),
  ('zv_u1', 'mathematik', 9, 'ZV U1', 'zweite', 9020),
  ('zv_u2', 'mathematik', 9, 'ZV U2', 'zweite', 9030),
  ('zv_spaet', 'mathematik', 9, 'ZV spaeter', 'zweite', 9040),
  ('zv_n', 'mathematik', 10, 'ZV Klasse 10', 'zweite', 9050),
  ('zv_tief', 'mathematik', 9, 'ZV vertiefen', 'zweite', 9999),
  ('zv_alt', 'mathematik', 7, 'ZV behandelt', 'erste', 8000);

insert into skill_thema (skill_key, thema_key) values
  ('zv_a1', 'zv_akt'), ('zv_a2', 'zv_akt'), ('zv_u1a', 'zv_u1'), ('zv_u1b', 'zv_u1'), ('zv_u2a', 'zv_u2'),
  ('zv_x', 'zv_spaet'), ('zv_r6', 'zv_n'), ('zv_h1', 'zv_hj'), ('zv_c1', 'zv_tief'), ('zv_c2', 'zv_tief'),
  ('zv_c3', 'zv_tief'), ('zv_b1', 'zv_alt');

insert into thema_einstieg (thema_key, skill_key) values
  ('zv_akt', 'zv_a1'), ('zv_hj', 'zv_h1'), ('zv_tief', 'zv_c1'), ('zv_alt', 'zv_b1'),
  ('zv_u1', 'zv_u1a'), ('zv_u2', 'zv_u2a');

insert into tasks (cluster_id, content_type, input_type, status, question,
                   source, source_ref, skill_key, sondierrang, class_level)
select (select c.id from skill_clusters c join subjects sub on sub.id = c.subject_id
         where sub.name = 'Mathematik' order by c.sort_order limit 1),
       'exercise', 'NUMERIC', 'ready', 'Wie viel ist 2 + 3?',
       'test', 'zv-' || s.skill_key || '-' || n, s.skill_key, n, 9
  from skills s cross join generate_series(1, 2) n;
insert into task_solutions (task_id, correct_answers)
select id, '["5"]'::jsonb from tasks where source = 'test' and source_ref like 'zv-%';
-- LSA-L2 (20261025144025): eindeutige Texte, sonst waere jede weitere Aufgabe ein Fast-Duplikat (lsa_text_schluessel)
-- der ersten — die Fixture nutzt ueberall denselben Aufgabentext.
update tasks set question = question || ' ' || translate(md5(id::text), '0123456789', 'ghijklmnop')
 where source = 'test' and source_ref like 'zv-%';

-- --- Schulen und Plaene -------------------------------------------------------
\set admin_uid 'dddddddd-dddd-dddd-dddd-0000000000b5'
insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid', 'lsav-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values (:'admin_uid', 'lsav-admin@test.local', 'admin', 'LSA-V Admin');
select set_config('request.jwt.claims', json_build_object('sub', :'admin_uid', 'role', 'authenticated')::text, true);

insert into schulen (name, ort) values ('ZV Schule', 'Testort'), ('ZV2 Schule', 'Testort'),
  ('ZV Doppelt', 'A'), ('zv doppelt', 'B');
insert into schul_themenplan (schule_id, fach, klasse, position, thema_key, uv_titel, halbjahr, quelle_url)
select s.id, 'mathematik', p.kl, p.pos, p.th, coalesce(p.th, 'Projekt'), p.hj, 'https://test.invalid'
  from schulen s cross join (values (9, 1, 'zv_akt', 1), (9, 2, 'zv_u2', 1), (9, 3, null, 1),
                                    (9, 4, 'zv_u1', 2), (9, 5, 'zv_spaet', 2), (10, 1, 'zv_n', null)) p(kl, pos, th, hj)
 where s.name = 'ZV Schule'
union all
select s.id, 'mathematik', 9, p.pos, p.th, p.th, null, 'https://test.invalid'
  from schulen s cross join (values (1, 'zv_u1'), (2, 'zv_u2')) p(pos, th)
 where s.name = 'ZV2 Schule';

-- Ein Kind der Klasse 9: Lead mit aktuell-Thema (und zv_alt 'behandelt'), Schule am Lead.
create function pg_temp.kind(p_aktuell text, p_schule text, p_behandelt boolean default true)
returns uuid language plpgsql as $$
declare v_lead uuid; v_student uuid;
begin
  insert into leads (full_name, class_level, status, schule_id)
  values ('ZV Kind', 9, 'contacted', (select id from schulen where name = p_schule))
  returning id into v_lead;
  if p_aktuell is not null then
    insert into lead_themen (lead_id, fach, thema_key, status, quelle)
    values (v_lead, 'mathematik', p_aktuell, 'aktuell', 'gespraech');
  end if;
  if p_behandelt then
    insert into lead_themen (lead_id, fach, thema_key, status, quelle)
    values (v_lead, 'mathematik', 'zv_alt', 'behandelt', 'schulplan');
  end if;
  perform set_config('edvance.allow_provisional', '1', true);
  insert into students (class_level, is_provisional, lead_id) values (9, true, v_lead) returning id into v_student;
  return v_student;
end $$;

create function pg_temp.t0() returns timestamptz language sql immutable as $$
  select '2026-10-05 08:00:00+00'::timestamptz
$$;

create function pg_temp.start(p_student uuid, p_t0 timestamptz default pg_temp.t0()) returns uuid
language sql as $$
  select (public.lsa_start(p_student, 9, 'Mathematik', 'adaptiv', p_t0) ->> 'session_id')::uuid
$$;

create function pg_temp.offen(p_sess uuid) returns uuid language sql as $$
  select a.task_id from lsa_ausgegeben a
   where a.session_id = p_sess
     and not exists (select 1 from lsa_responses r where r.session_id = p_sess and r.task_id = a.task_id)
   limit 1
$$;

-- Wie inv10: beantwortet nach Muster im Abstand p_schritt ab p_t0, liefert die Folge der Knoten; '-' = nichts.
create function pg_temp.folge(p_sess uuid, p_muster text, p_schritt interval,
                              p_t0 timestamptz default pg_temp.t0())
returns text language plpgsql as $$
declare v_task uuid; v_out text[]; i int;
begin
  v_task := pg_temp.offen(p_sess);
  v_out := array[coalesce((select skill_key from tasks where id = v_task), '-')];
  for i in 1 .. length(p_muster) loop
    exit when v_task is null;
    perform public.lsa_submit(
      p_sess, v_task,
      case substr(p_muster, i, 1) when 'r' then '{"value":"5"}' else '{"value":"7"}' end::jsonb,
      1000, p_t0 + i * p_schritt);
    v_task := pg_temp.offen(p_sess);
    v_out := v_out || coalesce((select skill_key from tasks where id = v_task), '-');
  end loop;
  return array_to_string(v_out, ',');
end $$;

-- Alle Knoten, die eine Sitzung je gezogen hat.
create function pg_temp.gezogen(p_sess uuid) returns text[] language sql as $$
  select coalesce(array_agg(distinct t.skill_key), '{}') from lsa_ausgegeben a join tasks t on t.id = a.task_id
   where a.session_id = p_sess
$$;

-- ============================================================================
-- a) Vorschau mit Plan
-- ============================================================================
select pg_temp.kind('zv_akt', 'ZV Schule') as k_a \gset
select pg_temp.start(:'k_a') as s_a \gset
select is(pg_temp.folge(:'s_a', repeat('r', 10), '1 minute'),
  'zv_a1,zv_r1,zv_r3,zv_r5,zv_r7,zv_r2,zv_u2a,zv_u1a,zv_b1,-',
  'a: Thema, dann zv_r1, zv_r3 (Rand mehrerer kommender Themen), Rand von zv_u2 (Plan-Position 2), von zv_u1 (4), Ausblick (LSA-V2), Rueckblick, Ende');
select is(public.lsa_select_next_core(:'s_a', array['ready'], pg_temp.t0() + interval '8 minutes'), null::uuid,
  'a: in Minute 8 kommt null — keine Fuellaufgabe, obwohl zv_f1 frei ist');
select ok(not ('zv_f1' = any (pg_temp.gezogen(:'s_a'))), 'a: zv_f1 (ohne Grund) nie gezogen');

-- ============================================================================
-- b) Skills kommender Themen nie; Ersetzung durch den Rand
-- ============================================================================
-- LSA-V2: Die Einstiege zv_u1a und zv_u2a kommen jetzt im Ausblick, nach dem ganzen Rand (Folge in a).
select ok(not ('zv_u1b' = any (pg_temp.gezogen(:'s_a'))),
  'b: Skills der kommenden Themen nie in der Vorschau; der Ausblick nimmt nur Einstiege (zv_u1b nie)');
select ok(not ('zv_x' = any (pg_temp.gezogen(:'s_a'))) and 'zv_r3' = any (pg_temp.gezogen(:'s_a')),
  'b: zv_x (Thema zv_spaet kommt noch) ersetzt durch seinen Rand zv_r3');
select ok(not ('zv_r6' = any (pg_temp.gezogen(:'s_a'))) and 'zv_r7' = any (pg_temp.gezogen(:'s_a')),
  'b: zv_r6 (Thema der naechsten Klasse) ersetzt durch seinen Rand zv_r7');

-- ============================================================================
-- c) Klassengrenze
-- ============================================================================
select ok(not ('zv_r4' = any (pg_temp.gezogen(:'s_a'))), 'c: zv_r4 (Klasse 10) nie in der Vorschau');

-- ============================================================================
-- d) Abstieg nur unter Bruechen
-- ============================================================================
select ok(not (pg_temp.gezogen(:'s_a') && array['zv_t1', 'zv_t2']), 'd: zv_r1 traegt -> kein Abstieg zu zv_t1');
select pg_temp.kind('zv_akt', 'ZV Schule') as k_d \gset
select pg_temp.start(:'k_d') as s_d \gset
select is(pg_temp.folge(:'s_d', 'rffrrrrrrrr', '1 minute'),
  'zv_a1,zv_r1,zv_r1,zv_r3,zv_r5,zv_r7,zv_t1,zv_r2,zv_u2a,zv_u1a,zv_b1,-',
  'd: zv_r1 bricht -> zv_t1 nach dem Rand von zv_u2 (Rand vor Tiefe), vor dem Rand von zv_u1');
select ok(not ('zv_t2' = any (pg_temp.gezogen(:'s_d'))), 'd: zv_t1 traegt -> keine zweite Stufe zu zv_t2');

-- ============================================================================
-- e) Zeitgrenze 16 Minuten
-- ============================================================================
select pg_temp.kind('zv_akt', 'ZV Schule') as k_e \gset
select pg_temp.start(:'k_e') as s_e \gset
select is(pg_temp.folge(:'s_e', 'rrrrrr', '4 minutes'),
  'zv_a1,zv_r1,zv_r3,zv_r5,zv_b1,-',
  'e: Auswahl in Minute 16 -> keine Vorschau mehr, Rueckblick; Minute 20 -> Ende');

-- ============================================================================
-- f) Position nach Halbjahr, Plan ohne Halbjahr
-- ============================================================================
select pg_temp.kind('zv_hj', 'ZV Schule') as k_f1 \gset
select pg_temp.start(:'k_f1') as s_f1 \gset
select is(pg_temp.folge(:'s_f1', 'rrrrrrrrr', '1 minute'),
  'zv_h1,zv_r1,zv_r3,zv_r5,zv_r7,zv_r2,zv_u2a,zv_u1a,zv_b1,-',
  'f: Thema nicht im Plan, Oktober -> erstes Halbjahr, Position 1: es kommen zv_u2 und zv_u1');
select pg_temp.kind('zv_hj', 'ZV Schule') as k_f2 \gset
select pg_temp.start(:'k_f2', '2026-03-02 08:00:00+00') as s_f2 \gset
select is(pg_temp.folge(:'s_f2', 'rrrr', '1 minute', '2026-03-02 08:00:00+00'),
  'zv_h1,zv_r3,zv_r7,zv_b1,-',
  'f: Maerz -> zweites Halbjahr, Position 4: es kommt nur zv_spaet (Rand zv_r3), dazu zv_n aus Klasse 10 (L3)');
select pg_temp.kind('zv_hj', 'ZV2 Schule', false) as k_f3 \gset
select pg_temp.start(:'k_f3') as s_f3 \gset
select is(pg_temp.folge(:'s_f3', 'rrrrrrrrr', '1 minute'),
  'zv_h1,zv_r1,zv_r7,zv_x,zv_r2,zv_r5,zv_u1a,zv_u2a,-',
  'f: Plan ohne Halbjahr -> von vorn (zv_u1, zv_u2), dazu zv_n aus dem Kernlehrplan Klasse 10 (L3): zv_r6 ersetzt durch zv_r7; zv_x bleibt Rand');

-- ============================================================================
-- g) Ohne Plan: Kernlehrplan
-- ============================================================================
select pg_temp.kind('zv_akt', null) as k_g \gset
select pg_temp.start(:'k_g') as s_g \gset
select is(pg_temp.folge(:'s_g', repeat('r', 10), '1 minute'),
  'zv_a1,zv_r1,zv_r3,zv_r2,zv_r5,zv_r7,zv_h1,zv_u1a,zv_u2a,zv_b1,-',
  'g: ohne Schule -> nach sort die naechsten drei: zv_hj (ohne Rand), zv_u1, zv_u2; zv_x ersetzt (zv_spaet liegt spaeter); Ausblick');

-- ============================================================================
-- h) Thema vertiefen, Rueckblick erst danach
-- ============================================================================
select pg_temp.kind('zv_tief', null) as k_h \gset
select pg_temp.start(:'k_h') as s_h \gset
select is(pg_temp.folge(:'s_h', 'frrrr', '1 minute'),
  'zv_c1,zv_c1,zv_c2,zv_c3,zv_b1,-',
  'h: zv_c1 traegt teilweise (kein Abstieg, keine Mitbelegung) -> zv_c2, zv_c3 vertiefen, dann Rueckblick');
select is((select zustand from lsa_skill_urteil where session_id = :'s_h' and skill_key = 'zv_c1'),
  'traegt_teilweise', 'h: ... zv_c1 ist traegt_teilweise');
select ok('zv_c3' = any (pg_temp.gezogen(:'s_h')), 'h: Thema vertiefen ohne Klassengrenze (zv_c3 ist Klasse 10)');
select is((select count(*)::int from lsa_skill_urteil u where u.session_id = :'s_h' and u.belegt_direkt
             and u.skill_key in ('zv_c1', 'zv_c2', 'zv_c3')), 3, 'h: alle drei Knoten des Themenraums direkt geprueft');

-- ============================================================================
-- i) lsa_schule_von_sitzung
-- ============================================================================
create function pg_temp.sitzung_mit(p_schule uuid, p_lead_schule text, p_name text) returns uuid
language plpgsql as $$
declare v_lead uuid; v_st uuid; v_s uuid;
begin
  if p_lead_schule is not null then
    insert into leads (full_name, class_level, status, schule_id)
    values ('ZV Weg', 9, 'contacted', (select id from schulen where name = p_lead_schule)) returning id into v_lead;
  end if;
  perform set_config('edvance.allow_provisional', '1', true);
  insert into students (class_level, is_provisional, lead_id, schule_id, school_name)
  values (9, v_lead is not null, v_lead, p_schule, p_name) returning id into v_st;
  insert into lsa_sessions (student_id, subject, grade, item_ids, started_at, status, modus)
  values (v_st, 'Mathematik', 9, '{}', pg_temp.t0(), 'in_progress', 'adaptiv') returning id into v_s;
  return v_s;
end $$;

-- Erst anlegen, dann fragen: die STABLE-Funktion saehe in derselben Anweisung die neue Sitzung nicht.
select pg_temp.sitzung_mit((select id from schulen where name = 'ZV2 Schule'), 'ZV Schule', ' zv schule ') as i1 \gset
select pg_temp.sitzung_mit(null, 'ZV Schule', 'ZV2 Schule') as i2 \gset
select pg_temp.sitzung_mit(null, null, '  zv2 SCHULE ') as i3 \gset
select pg_temp.sitzung_mit(null, null, 'ZV Doppelt') as i4 \gset
select pg_temp.sitzung_mit(null, null, E'\tzv2 schule\u00a0') as i5 \gset
select is(public.lsa_schule_von_sitzung(:'i1'), (select id from schulen where name = 'ZV2 Schule'),
  'i: zuerst students.schule_id');
select is(public.lsa_schule_von_sitzung(:'i2'), (select id from schulen where name = 'ZV Schule'),
  'i: dann leads.schule_id ueber students.lead_id');
select is(public.lsa_schule_von_sitzung(:'i3'), (select id from schulen where name = 'ZV2 Schule'),
  'i: dann der Name, ohne Gross/Klein');
select is(public.lsa_schule_von_sitzung(:'i4'), null::uuid, 'i: zwei Schulen mit dem Namen -> keine');
select is(public.lsa_schule_von_sitzung(:'i5'), (select id from schulen where name = 'ZV2 Schule'),
  'i: Tab und geschuetztes Leerzeichen zaehlen wie in plan.ts nicht');
select ok(not has_function_privilege('authenticated', 'public.lsa_schule_von_sitzung(uuid)', 'execute')
          and not has_function_privilege('anon', 'public.lsa_schule_von_sitzung(uuid)', 'execute'),
  'i: lsa_schule_von_sitzung ist fuer anon/authenticated nicht aufrufbar');

-- ============================================================================
-- j) Ohne Thema. Bis LSA-L4 wie vor LSA-V (Erwartungen aus einem Lauf mit 20261021083026:
--    j1 'zv_u1a,zv_u2a,zv_c1,zv_a1,zv_b1,zv_f1,zv_h1,-',
--    j2 'zv_u1a,zv_u1a,zv_u1b,zv_x,zv_x,zv_r1,zv_r1,zv_t1,zv_u2a,zv_c1,zv_c1,zv_c2,zv_c2,zv_a1,zv_b1,zv_b1,zv_f1,zv_f1,zv_h1,zv_r3,-').
-- LSA-L4 (20261025232926, Entscheidungen 7/8): Plan ZV mit Halbjahr 1 (Oktober) -> Planposition bekannt. Die Vorschau
-- laeuft auch ohne Thema (Rand zv_r1, zv_r3, zv_r5, zv_r7, zv_r2), danach Breite b; Skills kommender Themen (zv_u1a,
-- zv_u1b, zv_u2a, zv_x) kommen nicht mehr.
-- ============================================================================
\set j1_erwartet 'zv_r1,zv_r3,zv_r5,zv_r7,zv_r2,zv_c1,zv_a1,zv_b1,zv_f1,zv_h1,-'
\set j2_erwartet 'zv_r1,zv_r1,zv_t1,zv_r3,zv_r3,zv_r5,zv_r5,zv_r7,zv_r2,zv_c1,zv_c1,zv_c2,zv_c2,zv_a1,zv_b1,zv_b1,zv_f1,zv_f1,zv_h1,-'
select pg_temp.kind(null, 'ZV Schule') as k_j1 \gset
select pg_temp.start(:'k_j1') as s_j1 \gset
select is(pg_temp.folge(:'s_j1', 'rrrrrrrrrrrrrrrrrrrrrrrrrrrrrr', '35 seconds'),
  :'j1_erwartet', 'j: ohne Thema, alles richtig — Vorschau, dann Breite b (LSA-L4)');
select pg_temp.kind(null, 'ZV Schule') as k_j2 \gset
select pg_temp.start(:'k_j2') as s_j2 \gset
select is(pg_temp.folge(:'s_j2', 'ffrfrffrrfffrrfrffrrrfrfffrfrr', '35 seconds'),
  :'j2_erwartet', 'j: ohne Thema, gemischt — Vorschau mit Abstieg, dann Breite b (LSA-L4)');
select ok(exists (select 1 from lsa_skill_urteil where session_id = :'s_j2' and zustand = 'traegt_nicht'),
  'j: ... die gemischte Folge bricht wirklich (Abstieg und Breite b laufen)');
select ok((select count(*) from lsa_ausgegeben a join tasks t on t.id = a.task_id join skills s using (skill_key)
            where a.session_id in (:'s_j1', :'s_j2') and s.klasse_herkunft > 9) = 0,
  'j: ... mit Klassengrenze');

select * from finish();
rollback;
