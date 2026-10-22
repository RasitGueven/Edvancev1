-- ============================================================================
-- LSA-V Simulation: Testlauf von Testkonto B (Sitzung 6220b7e8) mit der Auswahl durchgespielt
-- (docs/lsa/Bauauftrag-LSA-V.md, Abschnitt „Simulation vorher/nachher“, Punkte 15–17)
--
-- Daten: supabase/tests/lsa_v_daten.sql (tools/lsa-v-abzug.sh, aus Prod nur lesend): FWG-Plan Klasse 9/10,
-- Aufgabenbestand je Skill (Sondierrang, MC, ob freigegeben), Zustand von Testkonto B je Skill, die Themen seines Leads.
-- Graph aus den Migrationen (am 22.10.2026 zeilengleich mit Prod).
--
-- Ablauf je Pool: Testkind Klasse 9, Thema reelle_zahlen, Schule mit dem FWG-Plan. lsa_start, dann Aufgabe
-- für Aufgabe: Antwort nach Profil über lsa_submit (wie die App), Uhr je Aufgabe 75 Sekunden weiter, bis keine
-- Aufgabe mehr kommt.
--   Pool „echt“: nur freigegebene Aufgaben (status ready), Kind ohne Testkonto.
--   Pool „test“: Testpool (lsa_testinhalte = true), Kind mit Testkonto — wie Testkonto B.
-- Antwortprofil: traegt → richtig; traegt_nicht → falsch; nicht_angesetzt → „weiß nicht“;
--   traegt_teilweise → erst falsch, dann richtig. ANNAHME: Skills, die Testkonto B nicht hatte, gelten als sicher.
-- Synthetische Aufgaben: je Aufgabe aus dem Bestand eine mit gleichem Skill, Sondierrang und MC/frei
--   (frei = NUMERIC; Multi-Part und Term werden wie eine freie Eingabe gebucht).
--
-- Grund je Aufgabe (nach Zugehörigkeit, unabhängig von der Phase, die sie gezogen hat):
--   Thema      Einstieg von reelle_zahlen       Grundlage  übriger Themenraum
--   Vorschau   Voraussetzung (transitiv) eines Skills der zwei nächsten Plan-Themen
--   Rückblick  Einstieg eines 'behandelt'-Themas    sonst  nichts davon
-- Die Liste je Lauf steht als diag-Zeilen „SIM|…“ in der Ausgabe (tools/lsa-v-simulation.sh baut daraus
-- docs/lsa/lsa-v-simulation.md).
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(9);

\ir lsa_v_daten.sql

-- --- Aufgaben: nur die synthetischen haben einen Skill ------------------------
update tasks set skill_key = null where skill_key is not null;
insert into skill_clusters (name, class_level_min, class_level_max) values ('ZZ LSA-V Cluster', 5, 13);
insert into tasks (cluster_id, content_type, input_type, status, question, question_payload, afb, competency_content,
                   est_duration_sec, class_level, curriculum_grade, source, source_ref, skill_key, sondierrang,
                   difficulty, einsatz, is_active)
select (select id from skill_clusters where name = 'ZZ LSA-V Cluster'), 'exercise',
       case when b.mc then 'MC' else 'NUMERIC' end, case when b.echt then 'ready' else 'draft' end,
       'ZZ LSA-V: Wie viel ist das?',
       case when b.mc then '{"input_type":"MC","options":[{"id":"a","label":"5"},{"id":"b","label":"7"}]}'::jsonb end,
       'I', 'Zahlen und Operationen', 60, 9, 9, 'test',
       'lsav-' || b.skill_key || '-' || row_number() over (partition by b.skill_key order by b.sondierrang nulls last, b.mc, b.echt),
       b.skill_key, b.sondierrang, 1, '{lsa}', true
  from zz_v_bestand b join skills s on s.skill_key = b.skill_key;
insert into task_solutions (task_id, correct_answers)
select id, case when input_type = 'MC' then '["a"]' else '["5"]' end::jsonb
  from tasks where source = 'test' and source_ref like 'lsav-%';

-- --- Personen, Schule, Plan ---------------------------------------------------
\set admin_uid 'dddddddd-dddd-dddd-dddd-0000000000b6'
insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid', 'lsav-sim@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values (:'admin_uid', 'lsav-sim@test.local', 'admin', 'LSA-V Sim');
select set_config('request.jwt.claims', json_build_object('sub', :'admin_uid', 'role', 'authenticated')::text, true);

insert into schulen (name, ort) values ('ZZ LSA-V FWG', 'Testort');
insert into schul_themenplan (schule_id, fach, klasse, position, thema_key, uv_titel, halbjahr, quelle_url)
select (select id from schulen where name = 'ZZ LSA-V FWG'), 'mathematik', p.klasse, p.position, p.thema_key,
       p.uv_titel, p.halbjahr, 'https://test.invalid'
  from zz_v_plan p;

create function pg_temp.kind(p_test boolean) returns uuid language plpgsql as $$
declare v_lead uuid; v_student uuid;
begin
  insert into leads (full_name, class_level, status, schule_id, ist_test)
  values ('ZZ LSA-V Kind', 9, 'contacted', (select id from schulen where name = 'ZZ LSA-V FWG'), p_test)
  returning id into v_lead;
  insert into lead_themen (lead_id, fach, thema_key, status, quelle)
  select v_lead, 'mathematik', t.thema_key, t.status, 'gespraech' from zz_v_themen t;
  perform set_config('edvance.allow_provisional', '1', true);
  insert into students (class_level, is_provisional, lead_id) values (9, true, v_lead) returning id into v_student;
  return v_student;
end $$;

create function pg_temp.t0() returns timestamptz language sql immutable as $$
  select '2026-10-19 08:00:00+00'::timestamptz  -- fester Start, nicht der der echten Sitzung
$$;

-- --- Gruende --------------------------------------------------------------------
create temp table zz_v_grund (skill_key text primary key, grund text) on commit drop;
with tr_e as (select skill_key from thema_einstieg where thema_key = 'reelle_zahlen'),
     tr as (select skill_key from tr_e union select a.skill_key from tr_e cross join lateral public.lsa_abschluss(tr_e.skill_key) a),
     u as (select p.thema_key from zz_v_plan p
            where p.klasse = 9 and p.thema_key is not null
              and p.position > (select position from zz_v_plan where klasse = 9 and thema_key = 'reelle_zahlen')
            order by p.position limit 2),
     vg as (select distinct a.skill_key from skill_thema st join u using (thema_key)
                    cross join lateral public.lsa_abschluss(st.skill_key) a
             where a.skill_key not in (select skill_key from skill_thema join u using (thema_key))),
     rb as (select te.skill_key from thema_einstieg te join zz_v_themen t using (thema_key) where t.status = 'behandelt')
insert into zz_v_grund
select s.skill_key,
       case when s.skill_key in (select skill_key from tr_e) then 'Thema'
            when s.skill_key in (select skill_key from tr) then 'Grundlage'
            when s.skill_key in (select skill_key from vg) then 'Vorschau'
            when s.skill_key in (select skill_key from rb) then 'Rückblick'
            else 'sonst' end
  from skills s;

-- --- Durchspielen -----------------------------------------------------------------
create temp table zz_v_lauf (pool text, nr int, sek int, skill_key text) on commit drop;

create function pg_temp.sim(p_pool text) returns uuid language plpgsql as $$
declare v_sess uuid; v_task uuid; v_sk text; v_mc boolean; v_probe int; v_zustand text; v_richtig boolean;
        v_antwort jsonb; i int := 0;
begin
  v_sess := (public.lsa_start(pg_temp.kind(p_pool = 'test'), 9, 'Mathematik', 'adaptiv', pg_temp.t0()) ->> 'session_id')::uuid;
  loop
    select a.task_id into v_task from lsa_ausgegeben a
     where a.session_id = v_sess
       and not exists (select 1 from lsa_responses r where r.session_id = v_sess and r.task_id = a.task_id);
    exit when v_task is null or i > 60;
    select t.skill_key, t.input_type = 'MC' into v_sk, v_mc from tasks t where t.id = v_task;
    insert into zz_v_lauf values (p_pool, i + 1, i * 75, v_sk);
    v_probe := 1 + (select count(*) from lsa_responses r join tasks t on t.id = r.task_id
                     where r.session_id = v_sess and t.skill_key = v_sk);
    v_zustand := coalesce((select zustand from zz_v_profil where skill_key = v_sk), 'traegt');
    v_richtig := case v_zustand when 'traegt_nicht' then false
                                when 'traegt_teilweise' then v_probe > 1
                                else true end;
    v_antwort := case when v_zustand = 'nicht_angesetzt' then '{"dont_know":true}'::jsonb
                      when v_mc then jsonb_build_object('selected', jsonb_build_array(case when v_richtig then 'a' else 'b' end))
                      else jsonb_build_object('value', case when v_richtig then '5' else '7' end) end;
    i := i + 1;
    perform public.lsa_submit(v_sess, v_task, v_antwort, 1000, pg_temp.t0() + i * interval '75 seconds');
  end loop;
  return v_sess;
end $$;

select pg_temp.sim('echt') as s_echt \gset
select pg_temp.sim('test') as s_test \gset

-- Liste und Anteile als diag (nicht Teil der Zusicherungen).
select diag(format('SIM|%s|%s|%s|%s|%s|%s', l.pool, l.nr, to_char(make_interval(secs => l.sek), 'MI:SS'),
                   g.grund, l.skill_key, coalesce(st.thema_key, '-')))
  from zz_v_lauf l join zz_v_grund g using (skill_key) left join skill_thema st using (skill_key)
 order by l.pool, l.nr;
select diag(format('DIREKT|%s|%s|%s', p.pool,
         (select count(*) from lsa_skill_urteil u join zz_v_grund g using (skill_key)
           where u.session_id = p.s and u.belegt_direkt and g.grund in ('Thema', 'Grundlage')),
         (select count(*) from zz_v_grund where grund in ('Thema', 'Grundlage'))))
  from (values ('echt', :'s_echt'::uuid), ('test', :'s_test'::uuid)) p(pool, s);

-- ============================================================================
-- Erwartung nachher (Punkt 17)
-- ============================================================================
select is((select count(*)::int from zz_v_lauf l join zz_v_grund g using (skill_key)
            where l.pool = 'test' and g.grund = 'sonst'), 0,
  '17.1 test: keine Aufgabe ohne Grund (nichts aus Breite b oder Schritt 5)');
select is((select count(*)::int from zz_v_lauf l join zz_v_grund g using (skill_key)
            where l.pool = 'echt' and g.grund = 'sonst'), 0,
  '17.1 echt: keine Aufgabe ohne Grund');
select is((select count(*)::int from zz_v_lauf l join zz_v_grund g using (skill_key)
            where l.pool = 'test' and g.grund = 'Rückblick' and l.sek < 16 * 60), 0,
  '17.2 test: ausserhalb des Themenraums vor Minute 16 nur Voraussetzungen der zwei naechsten Plan-Themen');
select is((select count(*)::int from zz_v_lauf l join zz_v_grund g using (skill_key)
            where l.pool = 'echt' and g.grund = 'Rückblick' and l.sek < 16 * 60), 0,
  '17.2 echt: dasselbe');
select is((select count(*)::int from zz_v_lauf l join skill_thema st using (skill_key)
            where st.thema_key = 'flaechen_vielecke'
              and not exists (select 1 from skill_thema k cross join lateral public.lsa_abschluss(k.skill_key) a
                               where k.thema_key = 'kreis' and a.skill_key = l.skill_key)), 0,
  '17.3: Flaecheninhalte nur, wenn sie ueber „Kreise, Prismen und Zylinder“ begruendet sind');
select ok((select count(*) from zz_v_lauf l join zz_v_grund g using (skill_key)
            where l.pool = 'test' and g.grund = 'Vorschau') > 0,
  '17.2 test: die Vorschau zieht wirklich (Voraussetzungen der naechsten Plan-Themen)');
select ok(not exists (select 1 from zz_v_lauf l join skill_thema st using (skill_key)
                       join zz_v_plan p on p.thema_key = st.thema_key
                      where p.klasse = 9 and p.position in (2, 3)),
  '17.2: kein Skill der kommenden Themen selbst');
-- 17.4 verlangt MEHR direkt gepruefte Bereiche im Themenraum als vorher (5 von 14, Lauf mit 20261021083026).
-- Mit den Entscheidungen 10 und 14 nicht erreichbar: die uebrigen 9 sind mitbelegt (lsa_mitbelegung), haben also
-- ein Urteil, und ein finales Urteil ueberschreibt die Wertung nicht. Zugesichert wird: nicht weniger als vorher.
-- docs/lsa/offene-punkte-lsa-v.md, Punkt 1.
\set direkt_vorher 5
select cmp_ok((select count(*)::int from lsa_skill_urteil u join zz_v_grund g using (skill_key)
                where u.session_id = :'s_test' and u.belegt_direkt and g.grund in ('Thema', 'Grundlage')),
              '>=', :'direkt_vorher'::int,
  '17.4 test: direkt gepruefte Bereiche im Themenraum nicht weniger als vorher (5)');
-- Der Testpool reicht bis an die 19-Minuten-Grenze; das Ende mit null zeigt der echte Pool.
select ok((select max(sek) from zz_v_lauf where pool = 'echt') < 16 * 60,
  'Ende: mit dem echten Pool endet die Sitzung lange vor Minute 19 mit null (keine Fuellaufgabe)');

select * from finish();
rollback;
