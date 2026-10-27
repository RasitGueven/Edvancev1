-- ============================================================================
-- Reihe 1 · A2 Datenmodell Bauformen und Funktionen (Migrationen 20261027132306, 132428, 132530, 132653).
--   1 vor der Freigabe zieht niemand eine Instanz; Lena prueft, Admin gibt frei (Abnahme 6, ohne Board)
--   2 aufgabe_ziehen: genau die Rolle, Stufe, home nur Stufe 1–3, gezeigtes Beispiel nie wieder (Abnahme 9)
--   3 aufgabe_melden pausiert Instanz, zwei Meldungen pausieren die Bauform (Abnahme 7)
--   4 Bewaehrung: zehn Antworten, viermal dieselbe unbekannte falsche → auffaellig (Abnahme 8)
--   5 Versionswechsel oeffnet die Bauform und nimmt alte Instanzen aus der Ziehung (Abnahme 10)
--   6 aufgabe_werten schreibt nichts, liefert Fehlbild und Rueckmeldung des Steckbriefs
--   7 Rechte: Kind nur fuer sich, nie LSA-Aufgaben; Steckbriefe nur Lena/Admin; Katalog qf_; kann_entfallen
-- Fixtures: session_a2_fixture (zz_a2), eigene Bauform ZZ-1 am Skill zz_r1a2. Am Ende rollback.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(40);

\ir session_a2_fixture.sql

\set lena '2c400000-0000-4000-8000-0000000000b2'
insert into auth.users (id, email, instance_id, aud, role)
values (:'lena', 'r1a2-lena@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name, darf_pruefen) values (:'lena', 'r1a2-lena@test.local', 'coach', 'R1A2 Lena', true);

insert into skills (skill_key, label, klasse_herkunft, fundament_tiefe) values ('zz_r1a2', 'ZZ R1 A2', 9, 1);
insert into skill_thema (skill_key, thema_key) values ('zz_r1a2', 'zz_a2_terme');

insert into bauformen (schluessel, skill_key, kernidee_key, format, rollen, steckbrief, status, pruefprotokoll)
values ('ZZ-1', 'zz_r1a2', 'zz_r1a2:K1', 'zahl', '{uebung,beispiel,home,generalprobe}',
        '{"text": "Wie viel ist {a} + {b}?", "kann_entfallen": true,
          "fehlbilder": [{"key": "qf_null_vergessen", "rueckmeldung": "ZZ: Du hast etwas vergessen.", "gilt_fuer_stufen": [1,2,3,4,5]}],
          "warum": {"bei_schritt": 0, "frage": "Warum?", "bausteine": [{"id": "a", "text": "A"}], "richtig": "a"}}',
        'zur_pruefung', '{"gruen": 8, "rot": 0}')
returning id as bf, version as bf_v \gset

create function pg_temp.instanz(p_ref text, p_rolle text, p_stufe int, p_gruen boolean default true) returns uuid
language plpgsql as $$
declare v uuid;
begin
  insert into tasks (content_type, input_type, status, is_active, question, skill_key, est_duration_sec, source, source_ref,
                     einsatz, bauform_id, bauform_version, stufe, rolle, kernidee_key, params, pruefmaschine)
  select 'exercise', 'NUMERIC', 'draft', true, 'ZZ R1A2 ' || p_ref || ': Wie viel ist 3 + 4?', 'zz_r1a2', 60,
         'reihe1_a2_test', p_ref, '{session}', b.id, b.version, p_stufe, p_rolle, 'zz_r1a2:K1', '{"a":3,"b":4}',
         jsonb_build_object('1', jsonb_build_object('ok', true), '4', jsonb_build_object('ok', p_gruen))
    from bauformen b where b.schluessel = 'ZZ-1'
  returning id into v;
  perform set_config('edvance.hinweis_status', 'setzen', true);
  insert into task_solutions (task_id, correct_answers, solution, hints, acceptance)
  values (v, '["7"]', E'3 + 4\n= 7', '[{"level":1,"text":"ZZ Zaehle weiter.","status":"entwurf"}]',
          '{"canonical":"7","known_errors":{"0":"qf_null_vergessen"}}');
  perform set_config('edvance.hinweis_status', '', true);
  return v;
end $$;

select pg_temp.instanz('u2a', 'uebung', 2) as u2a, pg_temp.instanz('u2b', 'uebung', 2) as u2b,
       pg_temp.instanz('u4', 'uebung', 4) as u4, pg_temp.instanz('urot', 'uebung', 1, false) as urot,
       pg_temp.instanz('h2', 'home', 2) as h2, pg_temp.instanz('h5', 'home', 5) as h5,
       pg_temp.instanz('b1', 'beispiel', 1) as b1, pg_temp.instanz('g3', 'generalprobe', 3) as g3 \gset

select pg_temp.kind('ZZ R1A2 Kind') as kind \gset
select pg_temp.kind('ZZ R1A2 Anderes') as anderes \gset
update students set profile_id = :'schueler' where id = :'kind';

-- ── 1) Pruefung und Freigabe ────────────────────────────────────────────────
select pg_temp.als_system();
select is(aufgabe_ziehen(:'kind', 'zz_r1a2', 'uebung'), null, '1 vor der Freigabe wird nichts gezogen');
select pg_temp.act_as(:'lena');
select throws_ok(format('select bauform_pruefen(%L, 99, %L)', :'bf', 'passt'), 'ED409', null, '1 falsche Version: Sperre');
select throws_ok(format('select bauform_pruefen(%L, %s, %L)', :'bf', :'bf_v', 'unsicher'), '22023', null,
                 '1 unsicher ohne Notiz scheitert');
select is(bauform_pruefen(:'bf', :'bf_v', 'passt') ->> 'status', 'zur_freigabe', '1 passt setzt zur Freigabe');
select throws_ok($$select bauform_freigeben('quadratische_funktionen_gleichungen')$$, '42501', null,
                 '1 Lena gibt nicht frei');
select pg_temp.act_as('a2a2a2a2-0001-4000-8000-000000000001');
select is(bauform_freigeben(p_thema_key => 'zz_a2_terme'), 1, '1 Admin gibt das Thema frei (eine Bauform)');
select is((select status from bauformen where id = :'bf'), 'freigegeben', '1 Bauform freigegeben');
select is((select count(*)::int from tasks where bauform_id = :'bf' and status = 'ready'), 7,
          '1 die sieben gruenen Instanzen sind ready');
select is((select status from tasks where id = :'urot'), 'draft', '1 eine rote Instanz bleibt draft');
select is((select h -> 0 ->> 'status' from (select hints h from task_solutions where task_id = :'u2a') x), 'geprueft',
          '1 die Hinweise der freigegebenen Instanzen sind geprueft');

-- ── 2) Ziehen ───────────────────────────────────────────────────────────────
select pg_temp.als_system();
select ok(aufgabe_ziehen(:'kind', 'zz_r1a2', 'uebung', 2) in (:'u2a', :'u2b'), '2 Uebung Stufe 2: eine Instanz der Stufe 2');
select is(aufgabe_ziehen(:'kind', 'zz_r1a2', 'uebung', 4), :'u4'::uuid, '2 Uebung Stufe 4');
select is(aufgabe_ziehen(:'kind', 'zz_r1a2', 'uebung', 2, array[:'u2a', :'u2b']::uuid[]), :'u4'::uuid,
          '2 Ausschluss: die naechste vorhandene Stufe');
select is(aufgabe_ziehen(:'kind', 'zz_r1a2', 'home', 5), :'h2'::uuid, '2 home liefert nie Stufe 4 oder 5');
select ok(not exists (select 1 from (values ('uebung', 1), ('uebung', 5), ('generalprobe', 3), ('beispiel', 1),
                                          ('transfer', 2), ('warmup', 2)) v(r, st)
                       where aufgabe_ziehen(:'kind', 'zz_r1a2', v.r, v.st) in (:'h2', :'h5')),
          '2 home-Instanzen kommen ueber keine andere Rolle');
select is(aufgabe_zwilling(:'kind', :'u2a'), :'u2b'::uuid, '2 Zwilling: andere Instanz derselben Rolle und Stufe');
select pg_temp.neue_session(array[:'kind']::uuid[]) as s1 \gset
select pg_temp.als_system();
select is(aufgabe_ziehen(:'kind', 'zz_r1a2', 'beispiel', 1), :'b1'::uuid, '2 Beispiel vor dem Zeigen');
select lives_ok(format('select aufgabe_gezeigt(%L, %L, %L)', :'kind', :'b1', :'s1'), '2 aufgabe_gezeigt merkt das Beispiel');
select is(aufgabe_ziehen(:'kind', 'zz_r1a2', 'beispiel', 1), null, '2 ein gezeigtes Beispiel kommt fuer dasselbe Kind nie wieder');
select is(aufgabe_ziehen(:'anderes', 'zz_r1a2', 'beispiel', 1), :'b1'::uuid, '2 fuer ein anderes Kind schon');
select throws_ok(format('select aufgabe_gezeigt(%L, %L, %L)', :'anderes', :'b1', :'s1'), 'P0001', null,
                 '2 gezeigt nur in einer Session, in der das Kind sitzt');

-- ── 3) Melden ───────────────────────────────────────────────────────────────
select pg_temp.act_as('a2a2a2a2-0001-4000-8000-000000000002');
select lives_ok(format('select aufgabe_melden(%L, %L)', :'u4', 'ZZ falsch'), '3 der Coach meldet eine Instanz');
select pg_temp.als_system();
select isnt(aufgabe_ziehen(:'kind', 'zz_r1a2', 'uebung', 4), :'u4'::uuid, '3 die gemeldete Instanz wird nicht mehr gezogen');
select pg_temp.act_as('a2a2a2a2-0001-4000-8000-000000000002');
select aufgabe_melden(:'u2a', 'ZZ auch falsch');
select is((select status from bauformen where id = :'bf'), 'pausiert', '3 zwei gemeldete Instanzen pausieren die Bauform');
select pg_temp.als_system();
select is(aufgabe_ziehen(:'kind', 'zz_r1a2', 'uebung', 2), null, '3 aus einer pausierten Bauform wird nichts gezogen');
update bauformen set status = 'freigegeben' where id = :'bf';

-- ── 4) Bewaehrung ───────────────────────────────────────────────────────────
insert into session_antworten (session_id, student_id, task_id, versuch_nr, eingabe, ergebnis, hinweisstufe_max, eingemischt)
select :'s1', :'kind', :'u2b', i, case when i <= 4 then '{"text":"8"}' else '{"text":"7"}' end::jsonb,
       case when i <= 4 then 'falsch' else 'richtig' end, 0, false
  from generate_series(1, 9) i;
select is((select status from aufgabe_bewaehrung where task_id = :'u2b'), 'in_bewaehrung', '4 nach neun Antworten noch in Bewaehrung');
insert into session_antworten (session_id, student_id, task_id, versuch_nr, eingabe, ergebnis, hinweisstufe_max, eingemischt)
values (:'s1', :'kind', :'u2b', 10, '{"text":"7"}', 'richtig', 0, false);
select is((select status || '/' || haeufigste_unbekannte from aufgabe_bewaehrung where task_id = :'u2b'), 'auffaellig/8',
          '4 zehn Antworten, viermal dieselbe unbekannte falsche → auffaellig');

-- ── 5) Versionswechsel ──────────────────────────────────────────────────────
select pg_temp.act_as(:'lena');
select lives_ok(format('select aufgabe_reaktivieren(%L)', :'u2b'), '5 Lena aktiviert die Instanz wieder');
select pg_temp.als_system();
select is(aufgabe_ziehen(:'kind', 'zz_r1a2', 'uebung', 2), :'u2b'::uuid, '5 vor der Textaenderung wird sie gezogen');
update bauformen set steckbrief = jsonb_set(steckbrief, '{text}', '"Rechne {a} + {b}."') where id = :'bf';
select is((select version || '/' || status from bauformen where id = :'bf'), '2/zur_pruefung',
          '5 eine Textaenderung erhoeht die Version und oeffnet die Bauform fuer Lena');
select is(aufgabe_ziehen(:'kind', 'zz_r1a2', 'uebung', 2), null, '5 alte Instanzen werden nicht mehr gezogen');

-- ── 6) Wertung ──────────────────────────────────────────────────────────────
select coalesce(sum(n_tup_ins + n_tup_upd + n_tup_del), 0) as vor from pg_stat_xact_user_tables where schemaname <> 'pg_temp' and schemaname not like 'pg_temp_%' \gset
select is((select row(richtig, fehlbild_key, rueckmeldung)::text from aufgabe_werten(:'u2b', '{"eingabe":{"text":"0"}}')),
          '(f,qf_null_vergessen,"ZZ: Du hast etwas vergessen.")', '6 Fehlbild mit der Rueckmeldung des Steckbriefs');
select is((select richtig from aufgabe_werten(:'u2b', '{"eingabe":{"text":"7"}}')), true, '6 richtig');
select is((select coalesce(sum(n_tup_ins + n_tup_upd + n_tup_del), 0) from pg_stat_xact_user_tables where schemaname <> 'pg_temp' and schemaname not like 'pg_temp_%'), :'vor'::numeric,
          '6 aufgabe_werten laesst alle Tabellen unveraendert');

-- ── 7) Rechte, Katalog, kann_entfallen ──────────────────────────────────────
select pg_temp.act_as(:'schueler');
select throws_ok(format('select aufgabe_ziehen(%L, %L, %L)', :'anderes', 'zz_r1a2', 'uebung'), '42501', null,
                 '7 ein Kind zieht nicht fuer ein anderes');
select throws_ok(format('select aufgabe_payload(%L)', (select id from tasks where 'lsa' = any (einsatz) limit 1)), '42501', null,
                 '7 ein Kind liest keine LSA-Aufgabe');
set local role authenticated;
select is((select count(*)::int from bauformen), 0, '7 ein Kind liest keine Steckbriefe');
select pg_temp.act_as(:'lena');
select is((select count(*)::int from bauformen where schluessel = 'ZZ-1'), 1, '7 Lena liest Steckbriefe');
reset role;
select is((select count(*)::int from fehlbild_labels where slug like 'qf\_%'), 39, '7 die 39 qf_-Schluessel stehen im Katalog');
select ok(skill_kann_entfallen('zz_r1a2') and not skill_kann_entfallen('zz_a2_s1'), '7 skill_kann_entfallen');

select * from finish();
rollback;
