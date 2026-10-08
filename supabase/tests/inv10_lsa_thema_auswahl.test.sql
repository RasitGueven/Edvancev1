-- ============================================================================
-- INV10: LSA-Auswahl — erst das Thema, dann die Tiefe, dann die Breite (W3-6)
--
-- Zusagen:
--   0) lsa_start haelt das 'aktuell'-Thema des Leads in thema_key fest — ueber
--      students.lead_id wie ueber leads.converted_student_id. Kein Lead/kein
--      Thema: NULL. Thema ohne Aufgaben: thema_key gesetzt, gilt als ohne Thema.
--   1) Thema traegt sofort -> nach den Einstiegsknoten die Breite, zuerst ein
--      'behandelt'-Thema (Schulplan vor themen.sort).
--   2) Thema bricht -> Abstieg nur unter dem Thema, bis sicher; danach Breite,
--      dort kein Abstieg mehr.
--   3) Thema bricht tief -> ab Minute 12 keine Tiefe, die Breite beginnt.
--   4) Kein Thema -> bisherige Auswahl: gierige Deckung MIT Abstieg, keine
--      Breite a, Klassengrenze.
--   5) Klassengrenze nur in Breite/Restzeit (und ohne Thema): Klasse 7 zieht
--      dort nie Klasse 8/9 — aber Klasse 7 mit einem Thema der Klasse 8
--      bekommt Phase T und den Abstieg darunter.
--   6) Offener Zweitbeleg hat in jeder Phase Vorrang.
--   7) Modus 'fest' unveraendert.
--
-- Isoliert: der Test blendet das echte Fundament transaktionslokal aus
-- (tasks.skill_key -> NULL, skills/skill_kante/thema_einstieg leer) und baut
-- einen eigenen Graphen. Feste Zeitpunkte ueber p_jetzt, Antworten ueber
-- lsa_submit: {"value":"5"} ist richtig (r), {"value":"7"} falsch (f).
--
-- Fixture-Graph (Tiefe, Klasse), Pfeil = setzt voraus:
--   Thema zt_akt   : zt_e1 (5,7) -> zt_p1 (3,6) -> zt_p2 (2,5)
--                    zt_e2 (4,7) -> zt_p3 (2,6)
--   behandelt A    : zt_ba (4,7) -> zt_q (1,5)    Schulplan Kl. 7 Pos. 2, sort 900
--   behandelt B    : zt_bb (3,6)                  Schulplan Kl. 6 Pos. 9, sort 950
--   uebriges       : zt_g1 (3,7) -> zt_r (1,5)
--                    zt_h9 (7,9) -> zt_h8 (6,8) -> zt_r
--   Thema zt_leer  : zt_leer_e (2,7) ohne Aufgaben
--   Thema zt_hoch  : Einstieg zt_h8 (Klasse 8, wie fkt_linear_* fuer Klasse 7)
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(33);

-- --- Isolation --------------------------------------------------------------
update tasks set skill_key = null where skill_key is not null;
delete from thema_einstieg;
delete from skill_kante;
-- Erklaersequenzen haengen per FK an skills (seit E2b mit echten Daten fuer fkt_linear_*).
delete from erklaer_kernidee;
delete from skills;

-- --- Graph -------------------------------------------------------------------
insert into skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe) values
  ('zt_e1', 'E1', 'mathematik', 7, 5), ('zt_p1', 'P1', 'mathematik', 6, 3),
  ('zt_p2', 'P2', 'mathematik', 5, 2), ('zt_e2', 'E2', 'mathematik', 7, 4),
  ('zt_p3', 'P3', 'mathematik', 6, 2), ('zt_ba', 'BA', 'mathematik', 7, 4),
  ('zt_q',  'Q',  'mathematik', 5, 1), ('zt_bb', 'BB', 'mathematik', 6, 3),
  ('zt_g1', 'G1', 'mathematik', 7, 3), ('zt_r',  'R',  'mathematik', 5, 1),
  ('zt_h8', 'H8', 'mathematik', 8, 6), ('zt_h9', 'H9', 'mathematik', 9, 7),
  ('zt_leer_e', 'LE', 'mathematik', 7, 2);

insert into skill_kante (skill_key, voraussetzt_skill_key) values
  ('zt_e1', 'zt_p1'), ('zt_p1', 'zt_p2'), ('zt_e2', 'zt_p3'),
  ('zt_ba', 'zt_q'),  ('zt_g1', 'zt_r'),  ('zt_h8', 'zt_r'), ('zt_h9', 'zt_h8');

insert into themen (thema_key, fach, klasse, label, stufe, sort) values
  ('zt_akt',   'mathematik', 7, 'ZT aktuell',     'erste', 990),
  ('zt_alt_a', 'mathematik', 7, 'ZT behandelt A', 'erste', 900),
  ('zt_alt_b', 'mathematik', 7, 'ZT behandelt B', 'erste', 950),
  ('zt_leer',  'mathematik', 7, 'ZT ohne Aufgaben', 'erste', 995),
  ('zt_hoch',  'mathematik', 8, 'ZT Klasse 8',     'erste', 980);

insert into thema_einstieg (thema_key, skill_key) values
  ('zt_akt', 'zt_e1'), ('zt_akt', 'zt_e2'),
  ('zt_alt_a', 'zt_ba'), ('zt_alt_b', 'zt_bb'),
  ('zt_leer', 'zt_leer_e'), ('zt_hoch', 'zt_h8');

-- Zwei NUMERIC-Aufgaben je Knoten (ausser zt_leer_e), Antwort "5".
insert into tasks (cluster_id, content_type, input_type, status, question,
                   source, source_ref, skill_key, sondierrang, class_level)
select (select c.id from skill_clusters c join subjects sub on sub.id = c.subject_id
         where sub.name = 'Mathematik' order by c.sort_order limit 1),
       'exercise', 'NUMERIC', 'ready', 'Wie viel ist 2 + 3?',
       'test', 'zt-' || s.skill_key || '-' || n, s.skill_key, n, 5
  from skills s cross join generate_series(1, 2) n
 where s.skill_key <> 'zt_leer_e';

insert into task_solutions (task_id, correct_answers)
select id, '["5"]'::jsonb from tasks where source = 'test' and source_ref like 'zt-%';

-- --- Personen -----------------------------------------------------------------
\set admin_uid 'dddddddd-dddd-dddd-dddd-0000000000a1'
insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid', 'inv10-admin@test.local', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name)
values (:'admin_uid', 'inv10-admin@test.local', 'admin', 'INV10 Admin');
select set_config('request.jwt.claims',
                  json_build_object('sub', :'admin_uid', 'role', 'authenticated')::text, true);

insert into schulen (name, ort) values ('ZT Testgymnasium', 'Testort');
insert into schul_themenplan (schule_id, fach, klasse, position, thema_key, uv_titel, quelle_url)
select id, 'mathematik', 7, 2, 'zt_alt_a', 'UV A', 'https://test.invalid' from schulen where name = 'ZT Testgymnasium'
union all
select id, 'mathematik', 6, 9, 'zt_alt_b', 'UV B', 'https://test.invalid' from schulen where name = 'ZT Testgymnasium';

-- Ein Kind: Lead (+ Schule) + Themen + Schuelerzeile. p_aktuell/p_behandelt
-- steuern lead_themen, p_konvertiert haengt den Schueler ueber
-- leads.converted_student_id statt students.lead_id an.
create function pg_temp.kind(p_name text, p_aktuell text, p_behandelt boolean,
                             p_schule boolean, p_konvertiert boolean default false)
returns uuid language plpgsql as $$
declare v_lead uuid; v_student uuid;
begin
  insert into leads (full_name, class_level, status, schule_id)
  values (p_name, 7, 'contacted',
          case when p_schule then (select id from schulen where name = 'ZT Testgymnasium') end)
  returning id into v_lead;
  if p_aktuell is not null then
    insert into lead_themen (lead_id, fach, thema_key, status, quelle)
    values (v_lead, 'mathematik', p_aktuell, 'aktuell', 'gespraech');
  end if;
  if p_behandelt then
    insert into lead_themen (lead_id, fach, thema_key, status, quelle) values
      (v_lead, 'mathematik', 'zt_alt_a', 'behandelt', 'schulplan'),
      (v_lead, 'mathematik', 'zt_alt_b', 'behandelt', 'schulplan');
  end if;
  -- Vor der Konversion provisorisch mit lead_id (wie lead_lsa_freigeben),
  -- danach ohne lead_id (students_provisional_lead_ck).
  perform set_config('edvance.allow_provisional', '1', true);
  insert into students (class_level, is_provisional, lead_id)
  values (7, not p_konvertiert, case when p_konvertiert then null else v_lead end)
  returning id into v_student;
  if p_konvertiert then
    update leads set converted_student_id = v_student where id = v_lead;
  end if;
  return v_student;
end $$;

create function pg_temp.kind_ohne_lead() returns uuid language sql as $$
  insert into students (class_level, is_provisional) values (7, false) returning id
$$;

-- Startzeit aller Sitzungen.
create function pg_temp.t0() returns timestamptz language sql immutable as $$
  select '2026-10-05 08:00:00+00'::timestamptz
$$;

create function pg_temp.start(p_student uuid, p_grade int default 7) returns uuid
language sql as $$
  select (public.lsa_start(p_student, p_grade, 'Mathematik', 'adaptiv', pg_temp.t0())
          ->> 'session_id')::uuid
$$;

-- Die ausgegebene, noch unbeantwortete Aufgabe einer Sitzung.
create function pg_temp.offen(p_sess uuid) returns uuid language sql as $$
  select a.task_id from lsa_ausgegeben a
   where a.session_id = p_sess
     and not exists (select 1 from lsa_responses r
                      where r.session_id = p_sess and r.task_id = a.task_id)
   limit 1
$$;

-- Beantwortet nach Muster ('r'/'f') im Abstand p_schritt und liefert die
-- Folge der gezogenen Knoten, beginnend mit der ersten Aufgabe. '-' = nichts.
create function pg_temp.folge(p_sess uuid, p_muster text, p_schritt interval)
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
      1000, pg_temp.t0() + i * p_schritt);
    v_task := pg_temp.offen(p_sess);
    v_out := v_out || coalesce((select skill_key from tasks where id = v_task), '-');
  end loop;
  return array_to_string(v_out, ',');
end $$;

-- ============================================================================
-- 0) Thema der Sitzung
-- ============================================================================
select pg_temp.kind('ZT Null', 'zt_akt', true, true) as k_null \gset
select pg_temp.start(:'k_null') as s_null \gset
select is((select thema_key from lsa_sessions where id = :'s_null'), 'zt_akt',
  '0a: lsa_start uebernimmt das aktuell-Thema ueber students.lead_id');

select pg_temp.kind('ZT Konv', 'zt_akt', false, false, true) as k_konv \gset
select pg_temp.start(:'k_konv') as s_konv \gset
select is((select thema_key from lsa_sessions where id = :'s_konv'), 'zt_akt',
  '0b: ... und ueber leads.converted_student_id');

select pg_temp.kind_ohne_lead() as k_ohne \gset
select pg_temp.start(:'k_ohne') as s_ohne \gset
select is((select thema_key from lsa_sessions where id = :'s_ohne'), null,
  '0c: ohne Lead kein Thema');

select pg_temp.kind('ZT Leer', 'zt_leer', false, false) as k_leer \gset
select pg_temp.start(:'k_leer') as s_leer \gset
select is((select thema_key from lsa_sessions where id = :'s_leer'), 'zt_leer',
  '0d: Thema ohne Aufgaben wird trotzdem festgehalten');
select is(pg_temp.folge(:'s_leer', '', '1 minute'), 'zt_e1',
  '0d: ... gilt als ohne Thema, die erste Aufgabe kommt aus der gierigen Deckung');

select pg_temp.kind('ZT Fach', null, false, false) as k_fach \gset
insert into lead_themen (lead_id, fach, thema_key, status, quelle)
select lead_id, 'physik', 'zt_akt', 'aktuell', 'gespraech' from students where id = :'k_fach';
select pg_temp.start(:'k_fach') as s_fach \gset
select is((select thema_key from lsa_sessions where id = :'s_fach'), null,
  '0e: ein aktuell-Thema in einem anderen Fach zaehlt nicht');

select ok(not has_function_privilege('authenticated', 'public.lsa_lead_von_schueler(uuid)', 'execute')
          and not has_function_privilege('anon', 'public.lsa_lead_von_schueler(uuid)', 'execute'),
  '0f: lsa_lead_von_schueler ist fuer anon/authenticated nicht aufrufbar');

-- ============================================================================
-- 1) Thema traegt sofort
-- ============================================================================
select is(pg_temp.folge(:'s_null', 'rrrrr', '1 minute'),
  'zt_e1,zt_e2,zt_ba,zt_bb,zt_g1,-',
  '1: Einstiegsknoten (groesster Abschluss zuerst), dann behandelt (Schulplan), dann gierige Deckung');
select is((select zustand from lsa_skill_urteil where session_id = :'s_null' and skill_key = 'zt_p2'),
  'traegt', '1: der Abschluss des Themas ist mitbelegt, nicht gezogen');

-- ============================================================================
-- 2) Thema bricht -> Abstieg unter dem Thema, danach Breite ohne Abstieg
-- ============================================================================
select pg_temp.kind('ZT Zwei', 'zt_akt', true, true) as k_zwei \gset
select pg_temp.start(:'k_zwei') as s_zwei \gset
select is(pg_temp.folge(:'s_zwei', 'ffrffrff', '1 minute'),
  'zt_e1,zt_e1,zt_e2,zt_p1,zt_p1,zt_p2,zt_ba,zt_ba,zt_bb',
  '2: alle Einstiege, dann Abstieg e1 -> p1 -> p2 bis sicher, dann Breite');
select ok(not exists (select 1 from lsa_ausgegeben a join tasks t on t.id = a.task_id
                       where a.session_id = :'s_zwei' and t.skill_key = 'zt_q'),
  '2: unter dem gebrochenen Breite-Knoten zt_ba wird nicht abgestiegen');
select is((select zustand from lsa_skill_urteil where session_id = :'s_zwei' and skill_key = 'zt_e1'),
  'traegt_nicht', '2: Einstieg e1 ist nach zwei Fehlern final gebrochen');

-- ============================================================================
-- 3) Thema bricht tief -> ab Minute 12 keine Tiefe
-- ============================================================================
select pg_temp.kind('ZT Drei', 'zt_akt', true, true) as k_drei \gset
select pg_temp.start(:'k_drei') as s_drei \gset
select is(pg_temp.folge(:'s_drei', 'ffff', '3 minutes'),
  'zt_e1,zt_e1,zt_e2,zt_e2,zt_ba',
  '3: Auswahl in Minute 12 -> kein Abstieg mehr, die Breite beginnt');

select pg_temp.kind('ZT Drei Kontrolle', 'zt_akt', true, true) as k_drei_k \gset
select pg_temp.start(:'k_drei_k') as s_drei_k \gset
select is(pg_temp.folge(:'s_drei_k', 'ffff', '150 seconds'),
  'zt_e1,zt_e1,zt_e2,zt_e2,zt_p1',
  '3: Kontrolle — dieselben Antworten bis Minute 10 steigen ab (tiefster Knoten zuerst)');

select is(public.lsa_select_next_core(:'s_drei_k', array['ready'], pg_temp.t0() + interval '19 minutes 1 second'),
  null::uuid, '3: das 19-Minuten-Fenster gilt unveraendert');

-- ============================================================================
-- 4) Kein Thema -> Breite
-- ============================================================================
select pg_temp.kind('ZT Vier', null, true, false) as k_vier \gset
select pg_temp.start(:'k_vier') as s_vier \gset
select is((select thema_key from lsa_sessions where id = :'s_vier'), null,
  '4: Lead ohne aktuell-Thema -> thema_key NULL');
select is(pg_temp.folge(:'s_vier', '', '1 minute'), 'zt_e1',
  '4: ohne aktuell-Thema bisherige Auswahl — groesstes Blatt, keine Breite a trotz behandelter Themen');

select is(pg_temp.folge(:'s_ohne', 'ff', '1 minute'), 'zt_e1,zt_e1,zt_p1',
  '4: ohne Thema steigt die Sitzung unter dem gebrochenen Blatt ab (wie vor W3-6)');

-- ============================================================================
-- 5) Klassengrenze
-- ============================================================================
select pg_temp.kind_ohne_lead() as k_neun \gset
select pg_temp.start(:'k_neun', 9) as s_neun \gset
select is(pg_temp.folge(:'s_neun', '', '1 minute'), 'zt_h9',
  '5: Kontrolle — Klasse 9 zieht zt_h9 als groesstes Blatt');

select pg_temp.kind_ohne_lead() as k_fuenf \gset
select pg_temp.start(:'k_fuenf') as s_fuenf \gset
select is(pg_temp.folge(:'s_fuenf', repeat('f', 40), '25 seconds') ~ 'zt_h[89]', false,
  '5: Klasse 7, alles falsch bis zum Ende — kein Knoten mit Klasse 8 oder 9');
select is((select count(*)::int from lsa_ausgegeben a join tasks t on t.id = a.task_id
             join skills s on s.skill_key = t.skill_key
            where a.session_id = :'s_fuenf' and s.klasse_herkunft > 7), 0,
  '5: ... auch in lsa_ausgegeben nicht (Schritt 5 eingeschlossen)');
select ok((select count(*) from lsa_ausgegeben where session_id = :'s_fuenf') >= 20,
  '5: die Sitzung lief bis zum Ende (alle 10 Knoten der Klasse <= 7 doppelt geprobt)');

select is(pg_temp.folge(:'s_null', '', '1 minute'), '-',
  '5: Fall 1 ist am Ende — zt_h8/zt_h9 bleiben auch in Schritt 5 aussen vor');
select is((select count(*)::int from lsa_ausgegeben a join tasks t on t.id = a.task_id
             join skills s on s.skill_key = t.skill_key
            where a.session_id in (:'s_null', :'s_zwei', :'s_drei') and s.klasse_herkunft > 7), 0,
  '5: mit Thema bleibt die Breite unter der Klassengrenze');

select pg_temp.kind('ZT Hoch', 'zt_hoch', false, false) as k_hoch \gset
select pg_temp.start(:'k_hoch') as s_hoch \gset
select is(pg_temp.folge(:'s_hoch', 'ffr', '1 minute'), 'zt_h8,zt_h8,zt_r,zt_e1',
  '5: Klasse 7 mit Thema der Klasse 8 — Phase T und Abstieg laufen, danach Breite ohne zt_h9');

-- ============================================================================
-- 6) Zweitbeleg hat in jeder Phase Vorrang
-- ============================================================================
-- Die Folgen oben zeigen ihn: Phase T (zt_e1,zt_e1), Tiefe (zt_p1,zt_p1),
-- Breite a (zt_ba,zt_ba), nach Minute 12 (zt_e2,zt_e2 in Fall 3). Hier
-- zusaetzlich in der gierigen Deckung und gegen einen offenen Einstieg:
select is(pg_temp.folge(:'s_ohne', 'ff', '1 minute'), 'zt_p1,zt_p1,zt_p2',
  '6: ohne Thema im Abstieg — erst der Zweitbeleg zu zt_p1, dann tiefer');
select is(pg_temp.folge(:'s_zwei', 'f', '1 minute'), 'zt_bb,zt_bb',
  '6: Breite a — der Zweitbeleg zu zt_bb kommt vor dem naechsten Knoten');

select pg_temp.kind('ZT Sechs', 'zt_akt', false, false) as k_sechs \gset
select pg_temp.start(:'k_sechs') as s_sechs \gset
select is(pg_temp.folge(:'s_sechs', 'f', '1 minute'), 'zt_e1,zt_e1',
  '6: Phase T — der offene Zweitbeleg zu zt_e1 kommt vor dem offenen Einstieg zt_e2');
select is((select offen from lsa_skill_urteil where session_id = :'s_sechs' and skill_key = 'zt_e1'),
  true, '6: ... und das Urteil zu zt_e1 ist dabei noch offen');

-- ============================================================================
-- 7) Modus 'fest'
-- ============================================================================
select pg_temp.kind('ZT Sieben', 'zt_akt', true, true) as k_sieben \gset
select (public.lsa_start(:'k_sieben', 7, 'Mathematik', 'fest', pg_temp.t0())) as r_fest \gset
select ok((:'r_fest'::jsonb ? 'total_items') and (:'r_fest'::jsonb ->> 'total_items')::int > 0,
  '7: fest liefert weiter total_items');
select is((select (modus, thema_key)::text from lsa_sessions where id = (:'r_fest'::jsonb ->> 'session_id')::uuid),
  '(fest,)', '7: fest setzt kein Thema');
select lives_ok(
  format($f$select public.lsa_submit(%L, (select item_ids[1] from lsa_sessions where id = %L), '{"value":"7"}'::jsonb)$f$,
         :'r_fest'::jsonb ->> 'session_id', :'r_fest'::jsonb ->> 'session_id'),
  '7: fest nimmt Antworten ueber item_ids an');
select is((select count(*)::int from lsa_skill_urteil
            where session_id = (:'r_fest'::jsonb ->> 'session_id')::uuid), 0,
  '7: fest bucht keine Skill-Urteile');

select * from finish();
rollback;
