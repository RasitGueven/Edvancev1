-- ============================================================================
-- LSA-Erlebnis L1, Punkte 4 bis 6 am Platz-Konto (Kiosk-Tablet).
-- Migrationen 20261021083026_lsa_diagnose_ab und 20261021083033_platz_avatar_helle_abbildung.
--   P1 platz_los setzt lsa_sessions.diagnose_ab einmalig; ohne Platz-Konto 42501
--   P2 Abnahme 23: fuenf Minuten Einfuehrung kuerzen das 19-Minuten-Fenster nicht
--   P3 platz_state liefert avatar (aus avatar_choice) und diagnose_ab, weiter kein progress (adaptiv)
--   P4 lsa_task_assets: url bleibt dunkel, helle Fassung zusaetzlich als url_hell
--   P5 Abnahme 14 ueber platz_submit: Mehrteiler je Teil Antwort bzw. {"dont_know":true}
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(21);

\ir lsa_l1_fixture.sql

select pg_temp.l1_aufgabe('p-1', 'NUMERIC', '["7"]') as t1 \gset
select pg_temp.l1_aufgabe('p-2', 'NUMERIC', '["8"]') as t2 \gset
select pg_temp.l1_aufgabe('p-mp', 'MULTI_PART', '{"1":["7"],"2":["8"]}',
  '[{"nr":1,"kind":"short_input","prompt":"Teil a"},{"nr":2,"kind":"short_input","prompt":"Teil b"}]') as t_mp \gset

-- Freigabe vor 22 Minuten (lsa_start setzt started_at), Zuweisung an das Tablet.
select pg_temp.l1_kind('Lina ZZ L1') as kind \gset
select pg_temp.l1_session(:'kind', now() - interval '22 minutes') as s \gset
insert into lsa_ausgegeben (session_id, task_id) values (:'s', :'t_mp');
select pg_temp.act_as(:'admin');
select public.platz_assign(:'tablet', :'s');

-- P2 vorher: ohne platz_los zaehlt started_at, nach 22 Minuten kommt nichts mehr.
select is(public.lsa_select_next_core(:'s', array['ready'], now()), null::uuid,
          'P2 vorher: 22 min nach der Freigabe zieht die Auswahl nichts mehr');

-- P1 platz_los ------------------------------------------------------------
select throws_ok($$ select public.platz_los() $$, '42501', null, 'P1 ohne Platz-Konto: 42501');
select pg_temp.act_as(:'tablet');
select is(public.platz_state() ->> 'diagnose_ab', null, 'P1 vor „Los geht’s“: diagnose_ab leer');
-- „Los geht’s“ fuenf Minuten nach der Freigabe (Einfuehrung und Tutorial).
select is(public.platz_los(now() - interval '17 minutes'), '{"ok": true}'::jsonb, 'P1 platz_los → {ok:true}');
select is((select diagnose_ab from lsa_sessions where id = :'s'), now() - interval '17 minutes', 'P1 diagnose_ab gesetzt');
select public.platz_los(now());
select is((select diagnose_ab from lsa_sessions where id = :'s'), now() - interval '17 minutes',
          'P1 ein zweiter Aufruf (Neuladen) verschiebt den Beginn nicht');

select public.platz_los(now() + interval '1 hour');
select is((select diagnose_ab from lsa_sessions where id = :'s'), now() - interval '17 minutes',
          'P1 … auch nicht mit einem Zeitpunkt in der Zukunft');
select ok(has_function_privilege('authenticated', 'public.platz_los(timestamptz)', 'execute')
          and not has_function_privilege('anon', 'public.platz_los(timestamptz)', 'execute'),
          'P1 platz_los: authenticated ja, anon nein');

-- P2 Abnahme 23 -----------------------------------------------------------
select ok(public.lsa_select_next_core(:'s', array['ready'], now()) is not null,
          'P2 Abnahme 23: 17 min nach „Los geht’s“ (22 nach der Freigabe) gibt es noch Aufgaben');
select is(public.lsa_select_next_core(:'s', array['ready'], now() + interval '2 minutes 1 second'), null::uuid,
          'P2 nach 19 min ab „Los geht’s“ ist das Fenster zu');

-- P3 platz_state ----------------------------------------------------------
select pg_temp.act_as(:'tablet');
select is(public.platz_state() ->> 'avatar', null, 'P3 noch kein Avatar');
select public.platz_avatar_set('avatar_3');
select is(public.platz_state() ->> 'avatar', 'avatar_3', 'P3 platz_state liefert den gewaehlten Avatar');
select is((public.platz_state() ->> 'diagnose_ab')::timestamptz, now() - interval '17 minutes',
          'P3 platz_state liefert diagnose_ab (Neuladen nach „Los geht’s“)');
select is(public.platz_state() ->> 'first_name', 'Lina', 'P3 Vorname wie bisher');
select ok(not (public.platz_state() ?| array['progress', 'total_items']), 'P3 adaptiv: weiter keine Zahl zum Fortschritt');

-- P4 helle Abbildung ------------------------------------------------------
insert into task_figures (task_id, generator, params, alt_text, svg_hash)
values (:'t1', 'winkel', '{}', 'Ein Winkel mit Scheitel A.', 'zz-l1-hash');
select is(public.lsa_task_assets(:'t1') -> 0 ->> 'url',
          public.lsa_storage_base() || 'generiert/' || :'t1' || '/winkel-dunkel.svg', 'P4 url bleibt die dunkle Fassung (rueckwaertskompatibel)');
select is(public.lsa_task_assets(:'t1') -> 0 ->> 'url_hell',
          public.lsa_storage_base() || 'generiert/' || :'t1' || '/winkel-hell.svg', 'P4 die helle kommt zusaetzlich als url_hell');
select is(public.lsa_question_payload(:'t1') -> 'assets' -> 0 ->> 'content_type', 'image/svg+xml', 'P4 im Payload angekommen');

-- P5 Abnahme 14 -----------------------------------------------------------
select pg_temp.act_as(:'tablet');
select ok(public.platz_submit(:'t_mp', '{"1":{"dont_know":true},"2":{"text":"8"}}') ->> 'ok' = 'true',
          'P5 platz_submit nimmt je Teil Antwort bzw. dont_know an');
select is((select array_agg(r.abgabeart || '/' || coalesce(r.correct::text, '-') order by r.part_nr)
             from lsa_responses r where r.session_id = :'s' and r.task_id = :'t_mp'),
          array['weiss_nicht/-', 'antwort/true'], 'P5 Teil a ausgelassen, Teil b beantwortet: je Teil der richtige Zustand');

-- Zukunft wird gekappt: ein frischer Beginn liegt nie nach now().
update lsa_sessions set diagnose_ab = null where id = :'s';
select pg_temp.act_as(:'tablet');
select public.platz_los(now() + interval '1 hour');
select is((select diagnose_ab from lsa_sessions where id = :'s'), now(), 'P1 platz_los kappt einen Zeitpunkt in der Zukunft auf now()');

select * from finish();
rollback;
