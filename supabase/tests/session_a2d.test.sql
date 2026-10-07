-- ============================================================================
-- A2d: Planer nach der Erklaersequenz, Zahlen im Entscheidungssignal
-- (Migrationen 20261010101318, 20261010101644; offene-punkte-a2d).
--
-- Zusagen:
--   D) Testlauf mit Entwuerfen ohne Schwierigkeit (wie im Durchstich): Erklaersequenz, danach
--      Loesungsbeispiel und aehnliche Aufgabe zum selben Skill.
--   P) Neuer Skill mit freigegebener Erklaersequenz, aber ohne Aufgabe im Pool: keine Erklaersequenz
--      (sonst erklaert die Sequenz einen Skill, den das Kind danach nicht ueben kann), sondern pool_leer.
--   S) Entscheidungssignal "eine Stufe tiefer?": Payload mit Voraussetzung (Key und Label), Zahl der
--      Warm-up-Aufgaben auf ihr und davon richtig; beim Coach ja, am Tablet nie.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(20);

\ir session_a2_fixture.sql

-- ── D) Testlauf mit Entwuerfen ohne Schwierigkeit ──────────────────────────
-- Die Aufgaben zu n1 werden Entwuerfe ohne difficulty (Bestand im Durchstich: draft, difficulty null, AFB gesetzt).
update tasks set status = 'draft', difficulty = null where source_ref like 'a2-zz_a2_n1-%';
select pg_temp.kind_mit('ZZ Jonas A2d', 'zz_a2_linear', '{zz_a2_v2}', '{}', true) as k_d \gset
select pg_temp.neue_session(array[:'k_d']::uuid[], 1, true) as s_d \gset
select pg_temp.checkin(:'s_d', 1);
select pg_temp.act_as(:'coach_a');
select checkin_coach_setzen(:'s_d', :'k_d', 'schulthema');
select pg_temp.uhr(:'s_d', 20);

select ok((select bool_and(public.session_im_pool(id, true) and difficulty is null) from tasks
            where source_ref like 'a2-zz_a2_n1-%'), 'D Entwuerfe ohne Schwierigkeit stehen im Testlauf-Pool');
select is(pg_temp.schritt_tablet(:'s_d', 1) ->> 'art', 'erklaerung', 'D neuer Skill: Erklaersequenz vorgeschaltet');
select (erklaer_start(:'s_d', null, 'zz_a2_n1')) -> 'check' ->> 'task_id' as chk_d \gset
select is((erklaer_check_abgeben(:'s_d', null, :'chk_d', '{"text":"7"}')) ->> 'uebergang', 'ueben', 'D Sequenz durch');
select pg_temp.schritt(:'s_d', 1) as d1 \gset
select is(:'d1'::jsonb ->> 'art' || ':' || (:'d1'::jsonb ->> 'skill_key') || ':' || (:'d1'::jsonb ->> 'grund_code'),
          'beispiel:zz_a2_n1:neu_beispiel', 'D nach der Sequenz: Loesungsbeispiel zum selben Skill');
select is((select difficulty from tasks where id = (:'d1'::jsonb ->> 'task_id')::uuid), null,
          'D das Beispiel ist ein Entwurf ohne Schwierigkeit');
select is(pg_temp.schritt(:'s_d', 1) ->> 'grund_code', 'neu_aehnliche_aufgabe', 'D danach die aehnliche Aufgabe');

-- ── P) Sequenz da, Pool leer ───────────────────────────────────────────────
-- Ohne Testlauf zaehlen die Entwuerfe zu n1 nicht: der Pool ist leer, die Sequenz ist freigegeben.
select pg_temp.kind_mit('ZZ Mia A2d', 'zz_a2_linear', '{zz_a2_v2}') as k_p \gset
select pg_temp.neue_session(array[:'k_p']::uuid[], 1) as s_p \gset
select pg_temp.checkin(:'s_p', 1);
select pg_temp.act_as(:'coach_a');
select checkin_coach_setzen(:'s_p', :'k_p', 'schulthema');
select pg_temp.uhr(:'s_p', 20);

select ok((public.erklaer_naechste_kernidee('zz_a2_n1', 0, false)).id is not null
          and not exists (select 1 from tasks where skill_key = 'zz_a2_n1' and public.session_im_pool(id, false)),
          'P Voraussetzung: freigegebene Sequenz, kein Pool');
select pg_temp.schritt(:'s_p', 1) as p1 \gset
select is(:'p1'::jsonb ->> 'art' || ':' || (:'p1'::jsonb ->> 'grund_code'), 'warten:pool_leer',
          'P keine Erklaersequenz fuer einen Skill ohne Aufgabe, sondern pool_leer');
select is((select count(*)::int from session_schritte where session_id = :'s_p' and art = 'erklaerung'), 0,
          'P keine Erklaerung eingetragen');
select is(pg_temp.vorschau(:'s_p', :'k_p') ->> 'grund_code', 'pool_leer', 'P Coach-Vorschau sieht dasselbe');

-- ── S) Entscheidungssignal mit Zahlen ──────────────────────────────────────
-- Wie A2 Fall 4: drei Warm-up-Aufgaben, nur die zweite richtig -> zwei Fehlversuche auf einer Voraussetzung.
select pg_temp.kind_mit('ZZ Mila A2d', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}') as k_s \gset
select pg_temp.neue_session(array[:'k_s']::uuid[], 6) as s_s \gset
select pg_temp.checkin(:'s_s', 1);
create temp table w_s as select n, pg_temp.loese(:'s_s', 1, n = 2) as x from generate_series(1, 4) n;
select is((select x ->> 'grund_code' from w_s where n = 4), 'warten_entscheidung', 'S Warm-up fertig, Entscheidung offen');

select pg_temp.act_as(:'coach_a');
select details as sig from raum_signale(:'s_s') where art = 'entscheidung' \gset
reset role;
-- Orakel wie definiert: je Aufgabe richtig, wenn alle beantworteten Teile richtig sind.
select x.skill_key as vor_key, count(*)::int as vor_n, (count(*) filter (where x.alle))::int as vor_r
  from (select t.skill_key, a.task_id, bool_and(a.ergebnis = 'richtig') as alle
          from session_antworten a join tasks t on t.id = a.task_id
         where a.session_id = :'s_s' and a.phase = 'warmup' and t.skill_key = (:'sig'::jsonb ->> 'skill_key')
         group by t.skill_key, a.task_id) x
 group by x.skill_key \gset
select is(:'sig'::jsonb ->> 'voraussetzung_skill_key', :'vor_key', 'S Payload: Skill der Voraussetzung (Key)');
select is(:'sig'::jsonb ->> 'voraussetzung_label', public.session_label(:'vor_key'), 'S Payload: Label der Voraussetzung');
select is((:'sig'::jsonb ->> 'warmup_aufgaben')::int, :'vor_n', 'S Payload: Warm-up-Aufgaben auf der Voraussetzung');
select is((:'sig'::jsonb ->> 'warmup_richtig')::int, :'vor_r', 'S Payload: davon richtig');
select ok(:vor_n >= 2 and :vor_r < :vor_n, 'S Zahlen passen zum Ablauf (mindestens zwei Aufgaben, nicht alle richtig)');
select is((:'sig'::jsonb ->> 'grund_code'), 'entscheidung_tiefer', 'S grund_code unveraendert');
select pg_temp.act_as(:'coach_a');
select ok((coach_raum_live(:'s_s'))::text like '%"warmup_aufgaben"%', 'S coach_raum_live zeigt die Zahlen');

-- Tablet: weder Schritt noch Stand tragen Signal oder Zahlen.
select pg_temp.act_as(pg_temp.tablet(1));
select ok((session_naechster_schritt(:'s_s', null))::text !~ 'warmup_aufgaben|warmup_richtig|voraussetzung|signale|entscheidung_tiefer',
          'S Tablet: session_naechster_schritt ohne Signal und Zahlen');
select ok((tablet_stand())::text !~ 'warmup_aufgaben|warmup_richtig|voraussetzung|entscheidung',
          'S Tablet: tablet_stand ohne Signal und Zahlen');

select * from finish();
rollback;
