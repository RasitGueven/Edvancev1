-- ============================================================================
-- T3: Im Testlauf Inhalte wie freigegeben (Migrationen 20261013151236, …151305, …151404; Entscheidung Rasit 08.10.).
--
-- Zusagen (Nummern wie im Auftrag):
--   1) Testlauf-Session bzw. LSA eines Testkontos: hinweis_abrufen, antwort_abgeben (Fehlbild-Satz),
--      erklaer_nachlesen, lsa_fehlbild_report liefern ungepruefte Inhalte (lsa_hint seit E3 nie, s. u.); in einer echten Session bzw.
--      der LSA eines echten Kindes mit denselben Aufgaben unveraendert nichts bzw. "nicht verfuegbar".
--   2) Inhalt einer Aufgabe, die die Pruefung des Lena-Boards nicht besteht (pruef_ausschluss), bleibt auch im
--      Testlauf unsichtbar. Ein Hinweis ohne Text bleibt "nicht verfuegbar".
--   3) Rechte unveraendert: fremdes/unbelegtes Tablet, fremder Coach, Konto ohne Profil -> 42501.
--   4) Echtes Kind: eine Session mit echtem Kind kann kein Testlauf sein (Trigger, 22023); LSA unveraendert.
--   H) Die Hilfen sind fuer Clients nicht aufrufbar.
-- Eigene Fixtures (session_a2_fixture), alles in einer Transaktion, am Ende rollback.
-- Lauf: npx supabase test db  (lokal: Wegwerf-DB aus allen Migrationen + seed.sql + pgTAP,
--       PGOPTIONS='-c search_path=public,extensions')
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(60);

\ir session_a2_fixture.sql

-- SQLSTATE eines Aufrufs, "kein Fehler" wenn er durchlaeuft.
create or replace function pg_temp.fehler(p_sql text) returns text language plpgsql as $f$
declare v_state text;
begin
  execute p_sql;
  return 'kein Fehler';
exception when others then
  get stacked diagnostics v_state = returned_sqlstate;
  return v_state;
end $f$;
grant execute on function pg_temp.fehler(text) to authenticated;

-- ── Inhalte ─────────────────────────────────────────────────────────────────
-- Drei Aufgaben zu zz_t3_s, alle mit Hinweisen ohne Freigabe und einem unfreigegebenen Fehlbild bei "0":
--   D draft, besteht die Pruefung    R ready, besteht die Pruefung (dazu ein gepruefter Hinweis)
--   X draft, wird nach der Ausgabe von Hand ausgeschlossen (pruef_ausschluss 'hand')
insert into skills (skill_key, label, klasse_herkunft, fundament_tiefe) values ('zz_t3_s', 'ZZ T3 Skill', 8, 1);
insert into skill_thema (skill_key, thema_key) values ('zz_t3_s', 'zz_a2_terme');
select pg_temp.aufgaben('zz_t3_s', 1, 'draft', '{session}', 't3-d'),
       pg_temp.aufgaben('zz_t3_s', 1, 'ready', '{session}', 't3-r'),
       pg_temp.aufgaben('zz_t3_s', 1, 'draft', '{session}', 't3-x');
select (select id from tasks where source_ref = 't3-d-1') as d,
       (select id from tasks where source_ref = 't3-r-1') as r,
       (select id from tasks where source_ref = 't3-x-1') as x \gset

select set_config('edvance.hinweis_status', 'setzen', true);
update task_solutions set
  hints = case task_id
    when :'d'::uuid then '[{"level":1,"text":"ZZ-T3-D-ENTWURF-1","status":"entwurf"},{"level":2,"text":"   ","status":"entwurf"}]'::jsonb
    when :'r'::uuid then '[{"level":1,"text":"ZZ-T3-A-ENTWURF","status":"entwurf"},{"level":1,"text":"ZZ-T3-B-GEPRUEFT","status":"geprueft"},{"level":2,"text":"ZZ-T3-R-ENTWURF-2","status":"entwurf"}]'::jsonb
    else '[{"level":1,"text":"ZZ-T3-X-ENTWURF-1","status":"entwurf"}]'::jsonb end,
  acceptance = case when task_id = :'x'::uuid then '{"canonical":"7","known_errors":{"0":"zz_t3_fb_x"}}'::jsonb
                    else '{"canonical":"7","known_errors":{"0":"zz_t3_fb"}}'::jsonb end
 where task_id in (:'d', :'r', :'x');
select set_config('edvance.hinweis_status', '', true);
-- Stufe 3 von R ohne status-Schluessel, wie alle 186 Hinweise in Prod (dbread 12.10.); der Trigger setzt sonst entwurf.
alter table task_solutions disable trigger task_solutions_hinweise_status;
update task_solutions set hints = hints || '[{"level":3,"text":"ZZ-T3-R-OHNE-STATUS-3"}]'::jsonb where task_id = :'r';
alter table task_solutions enable trigger task_solutions_hinweise_status;
insert into fehlbild_labels (slug, klartext, freigegeben_am) values
  ('zz_t3_fb', 'ZZ-T3-FEHLBILD', null), ('zz_t3_fb_x', 'ZZ-T3-FEHLBILD-X', null);

-- Erklaersequenz zu zz_t3_s im Entwurf (eine Kernidee, Variante A).
select pg_temp.act_as(:'admin');
select public.erklaer_kernidee_speichern(null, 'zz_t3_s', 1, 'ZZ T3 Kernidee', 'mensch') as kern \gset
select public.erklaer_schritt_speichern(:'kern', 'A', 'erklaerung', 'ZZ T3 Erklaerung', null, '{}');
select set_config('request.jwt.claims', '', true);

select is(array[public.pruef_ausschluss(:'d'), public.pruef_ausschluss(:'r'), public.pruef_ausschluss(:'x')],
          array[null, null, null]::text[], 'Vorbedingung: D, R, X bestehen die Pruefung');
select is((select status from erklaer_kernidee where id = :'kern'), 'entwurf', 'Vorbedingung: Kernidee im Entwurf');

-- ── Kinder und Testlauf-Session ────────────────────────────────────────────
select pg_temp.kind_mit('ZZ Test1 T3', null, '{}', '{}', true) as k_t1,
       pg_temp.kind_mit('ZZ Test2 T3', null, '{}', '{}', true) as k_t2,
       pg_temp.kind_mit('ZZ Echt T3', null, '{}') as k_echt \gset
select pg_temp.neue_session(array[:'k_t1', :'k_t2']::uuid[], 20, true) as s_tl \gset
select is((select testlauf from coaching_sessions where id = :'s_tl'), true, 'Vorbedingung: Session ist Testlauf');

select pg_temp.als_system();
select public.aufgabe_ausgeben(:'s_tl', :'k_t1', t) from unnest(array[:'d', :'r', :'x']::uuid[]) t;
select set_config('request.jwt.claims', '', true);
-- Lena schliesst X nach der Ausgabe aus.
insert into task_pruef_ausschluss (task_id, grund) values (:'x', 'ZZ T3 Ausschluss');
select is(public.pruef_ausschluss(:'x'), 'hand', 'Vorbedingung: X hat pruef_ausschluss hand');

-- ── 1) Testlauf-Session: ungepruefte Inhalte ─────────────────────────────────
select pg_temp.act_as(pg_temp.tablet(1));
select is(public.hinweis_abrufen(:'s_tl', :'d', 1) - 'weitere',
          '{"stufe":1,"text":"ZZ-T3-D-ENTWURF-1","verfuegbar":true}'::jsonb, '1 hinweis_abrufen Testlauf: Hinweis im Entwurf');
select is(public.hinweis_abrufen(:'s_tl', :'r', 1) ->> 'text', 'ZZ-T3-B-GEPRUEFT',
          '1 hinweis_abrufen Testlauf: auf derselben Stufe geht der gepruefte vor');
select is(public.hinweis_abrufen(:'s_tl', :'r', 2) ->> 'text', 'ZZ-T3-R-ENTWURF-2',
          '1 hinweis_abrufen Testlauf: ready-Aufgabe, Stufe 2 im Entwurf');
select is(public.hinweis_abrufen(:'s_tl', :'r', 3) ->> 'text', 'ZZ-T3-R-OHNE-STATUS-3',
          '1 hinweis_abrufen Testlauf: Hinweis ohne status-Schluessel (Bestand)');
select is(public.hinweis_abrufen(:'s_tl', :'d', 2) - 'weitere', '{"stufe":2,"text":null,"verfuegbar":false}'::jsonb,
          '2 hinweis_abrufen Testlauf: Hinweis ohne Text bleibt nicht verfuegbar');
select is(public.hinweis_abrufen(:'s_tl', :'x', 1) - 'weitere', '{"stufe":1,"text":null,"verfuegbar":false}'::jsonb,
          '2 hinweis_abrufen Testlauf: Aufgabe mit pruef_ausschluss bleibt nicht verfuegbar');
select is(public.antwort_abgeben(:'s_tl', :'d', null, '"0"') ->> 'fehlbild_klartext', 'ZZ-T3-FEHLBILD',
          '1 antwort_abgeben Testlauf: Fehlbild-Satz ohne Freigabe');
select is(public.antwort_abgeben(:'s_tl', :'x', null, '"0"'),
          jsonb_build_object('gespeichert', true, 'ergebnis', 'falsch', 'versuch_nr', 1, 'fehlbild_klartext', null),
          '2 antwort_abgeben Testlauf: Aufgabe mit pruef_ausschluss ohne Fehlbild-Satz');
select is(jsonb_array_length(public.erklaer_nachlesen(null, 'zz_t3_s') -> 'kernideen'), 1,
          '1 erklaer_nachlesen Testlauf-Tablet: Kernidee im Entwurf');
select is(public.erklaer_nachlesen(null, 'zz_t3_s') #>> '{kernideen,0,schritte,0,inhalt}', 'ZZ T3 Erklaerung',
          '1 erklaer_nachlesen Testlauf-Tablet: Schritt im Entwurf');
select is(jsonb_array_length(public.erklaer_nachlesen(:'k_t1', 'zz_t3_s') -> 'kernideen'), 1,
          '1 erklaer_nachlesen Testlauf-Tablet mit eigener id: dasselbe');
select is(jsonb_array_length(public.erklaer_nachlesen(null, 'zz_a2_n1') -> 'kernideen'), 1,
          '1 erklaer_nachlesen Testlauf-Tablet: freigegebene Sequenz unveraendert');

-- Coach-Sicht zeigt den gelieferten Hinweis und den Fehlbild-Satz.
select pg_temp.act_as(:'coach_a');
select is((select h ->> 'text' from jsonb_array_elements(public.coach_kind_detail(:'s_tl', :'k_t1') -> 'hinweise') h
            where h ->> 'task_id' = :'d' and (h ->> 'stufe')::int = 1), 'ZZ-T3-D-ENTWURF-1',
          '1 coach_kind_detail Testlauf: gelieferter Hinweis');
select is((select v ->> 'fehlbild_klartext' from jsonb_array_elements(public.coach_kind_detail(:'s_tl', :'k_t1') -> 'versuche') v
            where v ->> 'task_id' = :'d'), 'ZZ-T3-FEHLBILD', '1 coach_kind_detail Testlauf: Fehlbild-Satz');
-- Ausserhalb des Tablets: nur Freigegebenes (Schuelerkonto, Coach, Admin wie bisher).
select is(jsonb_array_length(public.erklaer_nachlesen(:'k_t1', 'zz_t3_s') -> 'kernideen'), 0,
          '1 erklaer_nachlesen Coach der Testlauf-Session: Entwurf bleibt verborgen');

-- ── 3) Rechte ────────────────────────────────────────────────────────────────
select pg_temp.act_as(pg_temp.tablet(5));
select is(pg_temp.fehler(format('select hinweis_abrufen(%L, %L, 1)', :'s_tl', :'r')), '42501', '3 hinweis_abrufen: Tablet ohne Platz');
select is(pg_temp.fehler(format($$select antwort_abgeben(%L, %L, null, '"7"')$$, :'s_tl', :'r')), '42501', '3 antwort_abgeben: Tablet ohne Platz');
select is(pg_temp.fehler($$select erklaer_nachlesen(null, 'zz_t3_s')$$), '42501', '3 erklaer_nachlesen: Tablet ohne Platz');
select pg_temp.act_as(pg_temp.tablet(2));
select is(pg_temp.fehler(format('select hinweis_abrufen(%L, %L, 1)', :'s_tl', :'r')), 'P0001',
          '3 hinweis_abrufen: Tablet des zweiten Kindes bekommt die Aufgabe des ersten nicht');
select is(pg_temp.fehler(format($$select erklaer_nachlesen(%L, 'zz_t3_s')$$, :'k_t1')), '42501',
          '3 erklaer_nachlesen: Tablet nur fuer das zugewiesene Kind');
select pg_temp.act_as(:'coach_b');
select is(pg_temp.fehler(format('select hinweis_abrufen(%L, %L, 1)', :'s_tl', :'r')), '42501', '3 hinweis_abrufen: fremder Coach');
select is(pg_temp.fehler(format('select coach_kind_detail(%L, %L)', :'s_tl', :'k_t1')), '42501', '3 coach_kind_detail: fremder Coach');
select pg_temp.act_as(:'ohne');
select is(pg_temp.fehler(format('select hinweis_abrufen(%L, %L, 1)', :'s_tl', :'r')), '42501', '3 hinweis_abrufen: Konto ohne Profil');
select is(pg_temp.fehler(format($$select antwort_abgeben(%L, %L, null, '"7"')$$, :'s_tl', :'r')), '42501', '3 antwort_abgeben: Konto ohne Profil');
select is(pg_temp.fehler($$select erklaer_nachlesen(null, 'zz_t3_s')$$), '42501', '3 erklaer_nachlesen: Konto ohne Profil');

-- Nach dem Loesen des Platzes gilt der Testlauf am Tablet nicht mehr (42501, wie bisher).
select pg_temp.act_as(:'admin');
select public.tablet_loesen(:'s_tl', :'k_t2');
select pg_temp.act_as(pg_temp.tablet(2));
select is(pg_temp.fehler($$select erklaer_nachlesen(null, 'zz_t3_s')$$), '42501', '3 erklaer_nachlesen: Platz geloest -> 42501');

-- ── 4) Echtes Kind: nie Testlauf ─────────────────────────────────────────────
select pg_temp.act_as(:'admin');
select is(pg_temp.fehler(format('insert into session_students (session_id, student_id) values (%L, %L)', :'s_tl', :'k_echt')),
          '22023', '4 Trigger: echtes Kind in eine Testlauf-Session buchen -> 22023');
select set_config('request.jwt.claims', '', true);

-- Echte Session mit denselben Aufgaben. D darf hier nicht ausgegeben werden (Pool); fuer die Probe der
-- Lesefunktionen wird D direkt eingetragen.
select pg_temp.neue_session(array[:'k_echt']::uuid[], 20) as s_echt \gset
-- Noch nicht gestartet (T2: eine gestartete Session lehnt session_testlauf_setzen schon vorher mit 55000 ab).
select pg_temp.act_as(:'admin');
insert into coaching_sessions (coach_id, room, scheduled_at) values (:'coach_a', 'ZZ T3 echt', now() + interval '1 day')
returning id as s_echt_neu \gset
insert into session_students (session_id, student_id) values (:'s_echt_neu', :'k_echt');
select is(pg_temp.fehler(format('select session_testlauf_setzen(%L, true)', :'s_echt_neu')), '22023',
          '4 Trigger: Session mit echtem Kind kann kein Testlauf werden -> 22023');
select pg_temp.als_system();
select is(pg_temp.fehler(format('select aufgabe_ausgeben(%L, %L, %L)', :'s_echt', :'k_echt', :'d')), 'P0001',
          '4 echte Session: Entwurf kommt nicht in den Pool (unveraendert)');
select public.aufgabe_ausgeben(:'s_echt', :'k_echt', :'r');
select set_config('request.jwt.claims', '', true);
insert into session_ausgegeben (session_id, student_id, task_id) values (:'s_echt', :'k_echt', :'d');

select pg_temp.act_as(pg_temp.tablet(1));
select is(public.hinweis_abrufen(:'s_echt', :'d', 1) - 'weitere', '{"stufe":1,"text":null,"verfuegbar":false}'::jsonb,
          '1 hinweis_abrufen echte Session: Entwurf nicht verfuegbar (unveraendert)');
select is(public.hinweis_abrufen(:'s_echt', :'r', 1) ->> 'text', 'ZZ-T3-B-GEPRUEFT',
          '1 hinweis_abrufen echte Session: gepruefter Hinweis wie bisher');
select is(public.hinweis_abrufen(:'s_echt', :'r', 2) - 'weitere', '{"stufe":2,"text":null,"verfuegbar":false}'::jsonb,
          '1 hinweis_abrufen echte Session: Stufe 2 im Entwurf nicht verfuegbar');
select is(public.hinweis_abrufen(:'s_echt', :'r', 3) - 'weitere', '{"stufe":3,"text":null,"verfuegbar":false}'::jsonb,
          '1 hinweis_abrufen echte Session: Hinweis ohne status-Schluessel nicht verfuegbar (unveraendert)');
select is(public.antwort_abgeben(:'s_echt', :'d', null, '"0"'),
          jsonb_build_object('gespeichert', true, 'ergebnis', 'falsch', 'versuch_nr', 1, 'fehlbild_klartext', null),
          '1 antwort_abgeben echte Session: kein Fehlbild-Satz ohne Freigabe (unveraendert)');
select is(jsonb_array_length(public.erklaer_nachlesen(null, 'zz_t3_s') -> 'kernideen'), 0,
          '1 erklaer_nachlesen echte Session: Entwurf bleibt verborgen');
select is(jsonb_array_length(public.erklaer_nachlesen(null, 'zz_a2_n1') -> 'kernideen'), 1,
          '1 erklaer_nachlesen echte Session: freigegebene Sequenz wie bisher');
select set_config('request.jwt.claims', '', true);
update fehlbild_labels set freigegeben_am = now() where slug = 'zz_t3_fb';
select pg_temp.act_as(pg_temp.tablet(1));
select is(public.antwort_abgeben(:'s_echt', :'r', null, '"0"') ->> 'fehlbild_klartext', 'ZZ-T3-FEHLBILD',
          '1 antwort_abgeben echte Session: freigegebener Fehlbild-Satz wie bisher');
select set_config('request.jwt.claims', '', true);
update fehlbild_labels set freigegeben_am = null where slug = 'zz_t3_fb';

-- ── LSA: Testkonto gegen echtes Kind ─────────────────────────────────────────
select pg_temp.act_as(:'admin');  -- lsa_sessions_testlauf_trg: Testlauf nur durch Admin
insert into lsa_sessions (student_id, subject, grade, item_ids, started_at, status, modus)
values (:'k_t1', 'Mathematik', 8, array[:'d', :'r', :'x']::uuid[], now(), 'in_progress', 'fest') returning id as l_test \gset
insert into lsa_sessions (student_id, subject, grade, item_ids, started_at, status, modus)
values (:'k_echt', 'Mathematik', 8, array[:'d', :'r', :'x']::uuid[], now(), 'in_progress', 'fest') returning id as l_echt \gset
insert into lsa_sessions (student_id, subject, grade, item_ids, started_at, status, modus, testlauf)
values (:'k_t2', 'Mathematik', 8, array[:'d']::uuid[], now(), 'in_progress', 'fest', true) returning id as l_tl \gset
insert into lsa_responses (session_id, task_id, response, correct, fehlbild_slug)
select l, t, '{"text":"0"}', false, case when t = :'x'::uuid then 'zz_t3_fb_x' else 'zz_t3_fb' end
  from unnest(array[:'l_test', :'l_echt']::uuid[]) l, unnest(array[:'d', :'x']::uuid[]) t;
select is((select count(*)::int from lsa_responses where session_id in (:'l_test', :'l_echt') and fehlbild_slug like 'zz_t3_fb%'), 4,
          'Vorbedingung: vier falsche LSA-Antworten mit Fehlbild');

select pg_temp.act_as(:'admin');
-- E3 (Entscheidung Rasit 12.10.2026, Migration 20261013173601): die LSA laeuft ohne Hinweise, auch fuer Testkonten.
select is(public.lsa_hint(:'l_test', :'d', 1), '{"level":1,"text":null,"available":false}'::jsonb,
          '1 lsa_hint Testkonto: auch der Entwurf kommt nicht (E3: LSA ohne Hinweise)');
select is(public.lsa_hint(:'l_tl', :'d', 1) ->> 'available', 'false', '1 lsa_hint Testlauf-LSA: kein Hinweis (E3)');
select is(public.lsa_hint(:'l_test', :'r', 1) ->> 'available', 'false', '1 lsa_hint Testkonto: auch der gepruefte kommt nicht (E3)');
select is(public.lsa_hint(:'l_test', :'d', 2), '{"level":2,"text":null,"available":false}'::jsonb,
          '2 lsa_hint Testkonto: Hinweis ohne Text nicht verfuegbar');
select is(public.lsa_hint(:'l_test', :'x', 1), '{"level":1,"text":null,"available":false}'::jsonb,
          '2 lsa_hint Testkonto: Aufgabe mit pruef_ausschluss nicht verfuegbar');
select is(public.lsa_hint(:'l_echt', :'d', 1), '{"level":1,"text":null,"available":false}'::jsonb,
          '4 lsa_hint echtes Kind: Entwurf nicht verfuegbar (unveraendert)');
select is(public.lsa_hint(:'l_echt', :'r', 1) ->> 'available', 'false', '4 lsa_hint echtes Kind: auch der gepruefte kommt nicht (E3)');
select is((select klartext from public.lsa_fehlbild_report(:'l_test') where fehlbild_slug = 'zz_t3_fb'), 'ZZ-T3-FEHLBILD',
          '1 lsa_fehlbild_report Testkonto: Klartext ohne Freigabe');
select is((select count(*)::int from public.lsa_fehlbild_report(:'l_test') where fehlbild_slug = 'zz_t3_fb_x' and klartext is null), 1,
          '2 lsa_fehlbild_report Testkonto: Fehlbild nur an Aufgabe mit pruef_ausschluss bleibt ohne Klartext');
select is((select count(*)::int from public.lsa_fehlbild_report(:'l_echt') where klartext is null), 2,
          '4 lsa_fehlbild_report echtes Kind: kein Klartext ohne Freigabe (unveraendert)');

select pg_temp.act_as(:'schueler');
select is(pg_temp.fehler(format('select lsa_hint(%L, %L, 1)', :'l_test', :'d')), '42501', '3 lsa_hint: fremdes Schuelerkonto');
select is((select count(*)::int from public.lsa_fehlbild_report(:'l_test')), 0, '3 lsa_fehlbild_report: fremdes Schuelerkonto sieht nichts');
select pg_temp.act_as(:'ohne');
select is(pg_temp.fehler(format('select lsa_hint(%L, %L, 1)', :'l_test', :'d')), '42501', '3 lsa_hint: Konto ohne Profil');
select is((select count(*)::int from public.lsa_fehlbild_report(:'l_test')), 0, '3 lsa_fehlbild_report: Konto ohne Profil sieht nichts');

-- ── H) Hilfen nur intern ─────────────────────────────────────────────────────
select set_config('request.jwt.claims', '', true);
select is(array[has_function_privilege('authenticated', 'public.testlauf_inhalt_sichtbar(uuid)', 'execute'),
                has_function_privilege('anon', 'public.testlauf_inhalt_sichtbar(uuid)', 'execute'),
                has_function_privilege('authenticated', 'public.lsa_testinhalte(uuid)', 'execute'),
                has_function_privilege('anon', 'public.lsa_testinhalte(uuid)', 'execute')],
          array[false, false, false, false], 'H Hilfen fuer anon/authenticated nicht aufrufbar');

-- Status der Aufgabe in der Hilfe: review besteht, beanstandet nie.
update tasks set status = 'review' where id = :'d';
select is(public.testlauf_inhalt_sichtbar(:'d'), true, 'H testlauf_inhalt_sichtbar: review ohne pruef_ausschluss');
update tasks set status = 'beanstandet' where id = :'d';
select is(public.testlauf_inhalt_sichtbar(:'d'), false, 'H testlauf_inhalt_sichtbar: beanstandet nie');
select is(public.testlauf_inhalt_sichtbar(gen_random_uuid()), false, 'H testlauf_inhalt_sichtbar: unbekannte Aufgabe');

select * from finish();
rollback;
