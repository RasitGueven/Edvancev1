-- ============================================================================
-- LSA-D Fix A/B: dieselbe Auswahl wie vor der Umstellung
-- (docs/lsa/diagnose-weiter.md, Abschnitt 7; Migration 20261022065539_lsa_v_vorschau)
--
-- lsa_select_next_core prueft lsa_im_pool jetzt zuletzt und nur bis zum ersten Treffer (lsa_freie_aufgabe,
-- Schleife in Schritt 5). Dieser Test spielt vier Sitzungen auf einer festen Fixture durch und vergleicht die
-- Aufgabenfolge (Aufgaben-Kennung, nicht nur Skill) mit einem Lauf der Fassung VOR der Umstellung (Commit
-- c5d2c18, gleiche Fixture, gleiche Antworten).
--
-- Fixture, eigener Graph (isoliert wie inv10), alles deterministisch:
--   40 Skills zg01..zg40, Klasse 5..10, Tiefe 1 + i/4, Kanten i -> j (j flacher) nach einer festen Regel, vier Themen zu je zehn Skills.
--   Je Skill vier Aufgaben, gemischt: MC/NUMERIC, ready/draft (draft nur im Testpool), ohne LSA-Einsatz
--   (nie im Pool), Sondierrang 1–3 oder leer. Damit liegt vor einer Pool-Aufgabe oft eine, die nicht im Pool ist.
--   Kind Klasse 9; Plan der Schule ZG: zg_a, zg_b, zg_c; zg_d 'behandelt'.
--   Antworten je Skill nach i % 4: falsch / richtig / „weiß nicht“ / erst falsch, dann richtig.
-- LSA-V2 (20261022131358): „Weiß ich nicht“ als erste Probe ist final. Die Folgen von c5d2c18 bleiben unten
-- stehen; erwartet wird jetzt genau diese Folge ohne den zweiten Eintrag der Skills mit i % 4 = 2 (pg_temp.ohne_wn).
-- Kein Kind hier ist stark genug für den Ausblick (höchstens die Hälfte traegt).
-- Sitzungen: Thema zg_a mit Testkonto und ohne; kein Thema mit Testkonto und ohne. Uhr 20 s je Aufgabe, damit
-- ohne Thema Breite b auslaeuft und die Restzeit (Schritt 5, die langsame Stelle aus LSA-D) drankommt.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(5);

-- --- Isolation --------------------------------------------------------------
update tasks set skill_key = null where skill_key is not null;
delete from thema_einstieg;
delete from skill_kante;
delete from erklaer_kernidee;
delete from skills;

-- --- Graph -------------------------------------------------------------------
insert into skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
select format('zg%s', lpad(i::text, 2, '0')), 'ZG ' || i, 'mathematik', 5 + i % 6, 1 + i / 4
  from generate_series(1, 40) i;
insert into skill_kante (skill_key, voraussetzt_skill_key)
select format('zg%s', lpad(i::text, 2, '0')), format('zg%s', lpad(j::text, 2, '0'))
  from generate_series(1, 40) i cross join generate_series(1, 40) j
 where j / 4 < i / 4 and i - j <= 12 and (i * 31 + j * 17) % 7 = 0;  -- Voraussetzung echt flacher

insert into themen (thema_key, fach, klasse, label, stufe, sort) values
  ('zg_a', 'mathematik', 9, 'ZG A', 'zweite', 9101), ('zg_b', 'mathematik', 9, 'ZG B', 'zweite', 9102),
  ('zg_c', 'mathematik', 9, 'ZG C', 'zweite', 9103), ('zg_d', 'mathematik', 5, 'ZG D', 'erprobung', 9001);
insert into skill_thema (skill_key, thema_key)
select format('zg%s', lpad(i::text, 2, '0')),
       case when i > 30 then 'zg_a' when i > 20 then 'zg_b' when i > 10 then 'zg_c' else 'zg_d' end
  from generate_series(1, 40) i;
insert into thema_einstieg (thema_key, skill_key) values
  ('zg_a', 'zg40'), ('zg_a', 'zg37'), ('zg_b', 'zg30'), ('zg_b', 'zg28'),
  ('zg_c', 'zg20'), ('zg_c', 'zg19'), ('zg_d', 'zg10'), ('zg_d', 'zg09');

-- Feste IDs: md5(Sitzung || Aufgabe) entscheidet Gleichstaende, zufaellige IDs gaeben jedes Mal eine andere Folge.
insert into tasks (id, cluster_id, content_type, input_type, status, question, question_payload,
                   source, source_ref, skill_key, sondierrang, class_level, einsatz, is_active,
                   afb, competency_content, curriculum_grade)
select md5(format('zg-%s-%s', i, n))::uuid,
       (select c.id from skill_clusters c join subjects sub on sub.id = c.subject_id
         where sub.name = 'Mathematik' order by c.sort_order limit 1),
       'exercise', case when (i + n) % 3 = 0 then 'MC' else 'NUMERIC' end,
       case when (i * n) % 4 = 1 then 'draft' else 'ready' end, 'Wie viel ist 2 + 3?',
       case when (i + n) % 3 = 0
            then '{"input_type":"MC","options":[{"id":"a","label":"5"},{"id":"b","label":"7"}]}'::jsonb end,
       'test', format('zg-%s-%s', i, n), format('zg%s', lpad(i::text, 2, '0')),
       case when n = 1 then 1 end, 9,   -- n = 2..4 ohne Sondierrang: md5 entscheidet
       case when (i + n) % 5 = 0 then '{}'::text[] else '{lsa}'::text[] end, true,
       'I', 'Zahlen und Operationen', 9   -- Gate-Felder: Entwuerfe sind im Testpool sichtbar
  from generate_series(1, 40) i cross join generate_series(1, 4) n;
insert into task_solutions (task_id, correct_answers)
select id, case when input_type = 'MC' then '["a"]' else '["5"]' end::jsonb
  from tasks where source = 'test' and source_ref like 'zg-%';

-- --- Personen, Schule ----------------------------------------------------------
\set admin_uid 'dddddddd-dddd-dddd-dddd-0000000000b7'
insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid', 'lsav-gleich@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values (:'admin_uid', 'lsav-gleich@test.local', 'admin', 'LSA-V Gleich');
select set_config('request.jwt.claims', json_build_object('sub', :'admin_uid', 'role', 'authenticated')::text, true);

insert into schulen (name, ort) values ('ZG Schule', 'Testort');
insert into schul_themenplan (schule_id, fach, klasse, position, thema_key, uv_titel, quelle_url)
select id, 'mathematik', 9, p.pos, p.th, p.th, 'https://test.invalid'
  from schulen cross join (values (1, 'zg_a'), (2, 'zg_b'), (3, 'zg_c')) p(pos, th)
 where name = 'ZG Schule';

create function pg_temp.kind(p_thema text, p_test boolean) returns uuid language plpgsql as $$
declare v_lead uuid; v_student uuid;
begin
  insert into leads (full_name, class_level, status, schule_id, ist_test)
  values ('ZG Kind', 9, 'contacted', (select id from schulen where name = 'ZG Schule'), p_test)
  returning id into v_lead;
  if p_thema is not null then
    insert into lead_themen (lead_id, fach, thema_key, status, quelle)
    values (v_lead, 'mathematik', p_thema, 'aktuell', 'gespraech');
  end if;
  insert into lead_themen (lead_id, fach, thema_key, status, quelle)
  values (v_lead, 'mathematik', 'zg_d', 'behandelt', 'schulplan');
  perform set_config('edvance.allow_provisional', '1', true);
  insert into students (class_level, is_provisional, lead_id) values (9, true, v_lead) returning id into v_student;
  return v_student;
end $$;

-- Spielt eine Sitzung durch; liefert die Folge der Aufgaben als 'i-n' (aus source_ref), '-' am Ende.
-- Start wie lsa_start (adaptiv), aber mit fester Sitzungs-ID p_id: md5(Sitzung || Aufgabe) entscheidet
-- Gleichstaende, mit zufaelliger ID waere die Folge von Lauf zu Lauf eine andere.
create function pg_temp.folge(p_id uuid, p_thema text, p_test boolean) returns text language plpgsql as $$
declare v_sess uuid; v_task uuid; v_i int; v_mc boolean; v_probe int; v_art int; v_richtig boolean;
        v_out text[] := '{}'; v_t0 timestamptz := '2026-10-05 08:00:00+00'; k int := 0;
begin
  insert into lsa_sessions (id, student_id, subject, grade, item_ids, started_at, status, modus, thema_key, testlauf)
  values (p_id, pg_temp.kind(p_thema, p_test), 'Mathematik', 9, '{}', v_t0, 'in_progress', 'adaptiv', p_thema, false)
  returning id into v_sess;
  insert into lsa_ausgegeben (session_id, task_id)
  values (v_sess, public.lsa_select_next_core(v_sess, array['ready'], v_t0));
  loop
    select a.task_id into v_task from lsa_ausgegeben a
     where a.session_id = v_sess
       and not exists (select 1 from lsa_responses r where r.session_id = v_sess and r.task_id = a.task_id);
    if v_task is null or k >= 70 then
      return array_to_string(v_out || '-'::text, ',');
    end if;
    select split_part(t.source_ref, '-', 2)::int, t.input_type = 'MC', v_out || replace(t.source_ref, 'zg-', '')
      into v_i, v_mc, v_out from tasks t where t.id = v_task;
    v_probe := (select count(*) from lsa_responses r join tasks t on t.id = r.task_id
                 where r.session_id = v_sess and t.skill_key = format('zg%s', lpad(v_i::text, 2, '0'))) + 1;
    v_art := v_i % 4;
    v_richtig := case v_art when 0 then false when 1 then true when 3 then v_probe > 1 end;
    k := k + 1;
    perform public.lsa_submit(v_sess, v_task,
      case when v_art = 2 then '{"dont_know":true}'::jsonb
           when v_mc then jsonb_build_object('selected', jsonb_build_array(case when v_richtig then 'a' else 'b' end))
           else jsonb_build_object('value', case when v_richtig then '5' else '7' end) end,
      1000, v_t0 + k * interval '20 seconds');
  end loop;
end $$;

-- ============================================================================
-- Folgen der Fassung vor der Umstellung (c5d2c18)
-- ============================================================================
\set thema_test '40-1,40-4,37-1,8-1,8-4,10-1,10-2,6-1,6-2,7-1,7-4,1-1,3-1,3-3,4-3,4-2,-'
\set thema_echt '40-1,40-4,37-4,8-1,8-4,10-1,10-2,6-1,6-2,7-1,7-4,1-3,3-1,3-4,4-2,4-4,-'
\set ohne_test '40-1,40-3,37-1,36-1,36-3,34-2,34-3,27-1,27-2,22-1,22-2,13-1,38-1,38-4,32-1,32-4,31-1,31-2,24-2,24-4,18-1,18-3,10-1,10-4,4-2,4-3,3-1,3-4,39-3,39-4,7-1,7-4,28-1,28-3,21-1,20-1,20-4,15-1,15-3,25-1,-'
\set ohne_echt '40-1,40-3,37-2,37-4,36-1,36-2,34-4,34-3,27-1,27-4,22-1,22-4,13-3,38-1,38-3,32-1,32-4,31-1,31-2,24-3,24-4,18-1,18-4,10-1,10-4,4-4,4-2,3-1,3-4,39-2,39-4,28-1,28-4,21-3,21-2,20-1,20-3,15-1,15-4,25-3,-'

-- LSA-V2: die Folge ohne die zweite Probe nach „Weiß ich nicht“ (Skills mit i % 4 = 2), sonst unverändert.
create function pg_temp.ohne_wn(p text) returns text language sql as $$
  select string_agg(x.e, ',' order by x.nr)
    from (select u.e, u.nr, row_number() over (partition by split_part(u.e, '-', 1) order by u.nr) as probe
            from unnest(string_to_array(p, ',')) with ordinality u(e, nr)) x
   where not (x.e <> '-' and split_part(x.e, '-', 1)::int % 4 = 2 and x.probe > 1)
$$;

select is(pg_temp.folge('eeeeeeee-0000-4000-8000-000000000001', 'zg_a', true),  pg_temp.ohne_wn(:'thema_test'), 'Thema, Testpool: dieselbe Aufgabenfolge wie vor der Umstellung (ohne WN-Zweitbeleg)');
select is(pg_temp.folge('eeeeeeee-0000-4000-8000-000000000002', 'zg_a', false), pg_temp.ohne_wn(:'thema_echt'), 'Thema, echter Pool: dieselbe Aufgabenfolge (ohne WN-Zweitbeleg)');
select is(pg_temp.folge('eeeeeeee-0000-4000-8000-000000000003', null, true), pg_temp.ohne_wn(:'ohne_test'),  'ohne Thema, Testpool (Breite b, Restzeit): dieselbe Aufgabenfolge (ohne WN-Zweitbeleg)');
select is(pg_temp.folge('eeeeeeee-0000-4000-8000-000000000004', null, false), pg_temp.ohne_wn(:'ohne_echt'),  'ohne Thema, echter Pool: dieselbe Aufgabenfolge (ohne WN-Zweitbeleg)');

select ok(not has_function_privilege('authenticated', 'public.lsa_freie_aufgabe(uuid, text, boolean, boolean)', 'execute')
          and not has_function_privilege('anon', 'public.lsa_freie_aufgabe(uuid, text, boolean, boolean)', 'execute'),
  'lsa_freie_aufgabe ist fuer anon/authenticated nicht aufrufbar');

select * from finish();
rollback;
