-- ============================================================================
-- C2: Coach-Live-Sicht mit echten Daten, Briefing, Satz-Bausteine, offene Sessions
-- (Bauauftrag Session-P1, Paket C2).
--
-- Zusagen (Nummern wie im Auftrag):
--   1) session_briefing: fremder Coach, Schuelerkonto, Konto ohne Profil -> 42501; Kind ohne laufenden
--      Vertrag fehlt; Thema ueber thema_alt_tage ist markiert; Quests nur erledigt/offen.
--   2) satz_vorschlaege: zwei Vorschlaege aus aktiven Bausteinen; Platzhalter ersetzt; inaktive nie;
--      Testlauf erlaubt.
--   3) sessions_offen: genau die ueber der Grenze und nicht abgeschlossenen.
--   4) X0b-Waechter: laeuft in session_x0b.test.sql ueber alle Funktionen (auch die neuen); hier
--      zusaetzlich der Katalog: neue Funktionen sind SECURITY DEFINER mit festem search_path.
--   L) coach_raum_live: testlauf, abschluss, eingriffe, pfad_entscheidung je Kind.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(38);

\ir session_a2_fixture.sql

select pg_temp.kind_mit('ZZ Emir C2', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}') as k_emir,
       pg_temp.kind_mit('ZZ Deniz C2', 'zz_a2_linear', '{zz_a2_v1}') as k_deniz,
       pg_temp.kind_mit('ZZ Lea C2', 'zz_a2_terme', '{zz_a2_v1}') as k_lea,
       pg_temp.kind_mit('ZZ Tim C2', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}', true) as k_tim
\gset
-- Deniz' Schulthema ist alt (30 Tage, thema_alt_tage = 21), Emirs frisch.
update lead_themen set angelegt = now() - interval '30 days'
 where lead_id = (select id from leads where converted_student_id = :'k_deniz');
-- Emir hat einen Mastery-Kandidaten mit faelliger Pruefung.
update lernpfad set stand_system = 'kandidat' where student_id = :'k_emir' and skill_key = 'zz_a2_v1';
-- Quests der letzten Woche fuer Emir: eine erledigt, eine offen; eine alte zaehlt nicht.
insert into quests (student_id, session_id, art, ka_thema_key, faellig_ab, termin, status, erledigt_am) values
  (:'k_emir', :'s_alt', 'A', null, current_date - 3, now() - interval '3 days', 'erledigt', now() - interval '2 days'),
  (:'k_emir', :'s_alt', 'B', null, current_date - 1, now() - interval '1 day', 'offen', null),
  (:'k_emir', :'s_alt', 'KA', 'zz_a2_terme', current_date - 20, now() - interval '20 days', 'erledigt', now() - interval '19 days');

select pg_temp.neue_session(array[:'k_emir', :'k_deniz', :'k_lea']::uuid[], 20) as s \gset
-- Lea verliert ihren Vertrag nach der Buchung (Widerruf).
update vertraege set widerrufen_am = current_date where student_id = :'k_lea';

-- ── 1) Briefing ───────────────────────────────────────────────────────────
select pg_temp.act_as(:'coach_b');
select throws_ok(format('select session_briefing(%L)', :'s'), '42501', null, '1 briefing: fremder Coach -> 42501');
select pg_temp.act_as(:'schueler');
select throws_ok(format('select session_briefing(%L)', :'s'), '42501', null, '1 briefing: Schuelerkonto -> 42501');
select pg_temp.act_as(:'ohne');
select throws_ok(format('select session_briefing(%L)', :'s'), '42501', null, '1 briefing: Konto ohne Profil -> 42501');
select pg_temp.act_as(pg_temp.tablet(1));
select throws_ok(format('select session_briefing(%L)', :'s'), '42501', null, '1 briefing: Tablet -> 42501');

select pg_temp.act_as(:'coach_a');
select session_briefing(:'s') as br \gset
select is(jsonb_array_length(:'br'::jsonb), 2, '1 zwei Kinder mit laufendem Vertrag');
select ok(not (:'br'::jsonb @> jsonb_build_array(jsonb_build_object('student_id', :'k_lea'))),
          '1 Kind ohne laufenden Vertrag fehlt');
select is((select b -> 'schulthema' ->> 'nachfragen' from jsonb_array_elements(:'br'::jsonb) b
            where b ->> 'student_id' = :'k_deniz'), 'true', '1 Thema ueber thema_alt_tage ist markiert');
select is((select b -> 'schulthema' ->> 'nachfragen' from jsonb_array_elements(:'br'::jsonb) b
            where b ->> 'student_id' = :'k_emir'), 'false', '1 frisches Thema ist nicht markiert');
select is((select (b -> 'schulthema' ->> 'tage')::int from jsonb_array_elements(:'br'::jsonb) b
            where b ->> 'student_id' = :'k_deniz'), 30, '1 Alter des Themas in Tagen');
select is((select b -> 'quests_woche' from jsonb_array_elements(:'br'::jsonb) b where b ->> 'student_id' = :'k_emir'),
          '{"erledigt": 1, "offen": 1}'::jsonb, '1 Quests der letzten Woche: nur erledigt/offen, alte zaehlt nicht');
select is((select array_agg(k order by k) from jsonb_array_elements(:'br'::jsonb) b, jsonb_object_keys(b -> 'quests_woche') k
            where b ->> 'student_id' = :'k_emir'), array['erledigt', 'offen'], '1 Quests ohne Inhalte');
select is((select b -> 'pruefungen_faellig' -> 0 ->> 'skill_key' from jsonb_array_elements(:'br'::jsonb) b
            where b ->> 'student_id' = :'k_emir'), 'zz_a2_v1', '1 faellige Mastery-Pruefung');
select is((select b ->> 'erste_session' from jsonb_array_elements(:'br'::jsonb) b where b ->> 'student_id' = :'k_emir'),
          'true', '1 ohne fruehere Session: erste_session');
select pg_temp.act_as(:'admin');
select is(jsonb_array_length(session_briefing(:'s')), 2, '1 Admin liest das Briefing');

-- ── L) coach_raum_live ────────────────────────────────────────────────────
select pg_temp.checkin(:'s', 1), pg_temp.checkin(:'s', 2);
select pg_temp.act_as(:'coach_a');
select checkin_coach_setzen(:'s', :'k_emir', 'schulthema'), checkin_coach_setzen(:'s', :'k_deniz', 'lernpfad');
select abschluss_setzen(:'s', :'k_emir', 'ZZ-SATZ', true, 'ZZ Notiz', true, null);
select eingriff_notieren(:'s', :'k_deniz', 2);
select pfad_entscheiden(:'s', :'k_deniz', 'plan');
select coach_raum_live(:'s') as rl \gset
select is(:'rl'::jsonb -> 'session' ->> 'testlauf', 'false', 'L session.testlauf');
select is((select k -> 'abschluss' ->> 'satz_text' from jsonb_array_elements(:'rl'::jsonb -> 'kinder') k
            where k ->> 'student_id' = :'k_emir'), 'ZZ-SATZ', 'L abschluss.satz_text');
select is((select (k -> 'abschluss' ->> 'satz_gesagt') || '/' || (k -> 'abschluss' ->> 'flag_eltern')
             from jsonb_array_elements(:'rl'::jsonb -> 'kinder') k where k ->> 'student_id' = :'k_emir'),
          'true/true', 'L abschluss: gesagt und Flag');
select is((select k -> 'eingriffe' -> 0 ->> 'stufe' from jsonb_array_elements(:'rl'::jsonb -> 'kinder') k
            where k ->> 'student_id' = :'k_deniz'), '2', 'L eingriffe je Kind');
select is((select k -> 'pfad_entscheidung' ->> 'entscheidung' from jsonb_array_elements(:'rl'::jsonb -> 'kinder') k
            where k ->> 'student_id' = :'k_deniz'), 'plan', 'L pfad_entscheidung je Kind');
select is((select k -> 'abschluss' from jsonb_array_elements(:'rl'::jsonb -> 'kinder') k
            where k ->> 'student_id' = :'k_lea'), 'null'::jsonb, 'L ohne Check-out: abschluss null');

-- ── 2) satz_vorschlaege ───────────────────────────────────────────────────
select pg_temp.stell('phase_checkin_min', '3');
select count(*) from pg_temp.lauf(:'s', 1, 6, true);
select pg_temp.act_as(:'coach_b');
select throws_ok(format('select satz_vorschlaege(%L, %L)', :'s', :'k_emir'), '42501', null, '2 fremder Coach -> 42501');
select pg_temp.act_as(:'ohne');
select throws_ok(format('select satz_vorschlaege(%L, %L)', :'s', :'k_emir'), '42501', null, '2 Konto ohne Profil -> 42501');
select pg_temp.act_as(:'coach_a');
select satz_vorschlaege(:'s', :'k_emir') as sv \gset
select is(jsonb_array_length(:'sv'::jsonb), 2, '2 zwei Vorschlaege');
select ok((select bool_and(z.aktiv) from jsonb_array_elements(:'sv'::jsonb) v
             join session_satz_bausteine z on z.id = (v ->> 'baustein_id')::uuid), '2 beide aus aktiven Bausteinen');
select ok((select bool_and(v ->> 'text' !~ '[{}]') from jsonb_array_elements(:'sv'::jsonb) v), '2 Platzhalter ersetzt');
select isnt(:'sv'::jsonb -> 0 ->> 'anlass', :'sv'::jsonb -> 1 ->> 'anlass', '2 zwei verschiedene Anlaesse');
select ok((select bool_and(v ->> 'text' !~ '[0-9]+ ?(%|Prozent)') from jsonb_array_elements(:'sv'::jsonb) v),
          '2 keine Quoten im Satz');
-- Alle Bausteine der gewaehlten Anlaesse deaktivieren: sie kommen nie mehr.
update session_satz_bausteine set aktiv = false
 where anlass in (select v ->> 'anlass' from jsonb_array_elements(:'sv'::jsonb) v) and anlass <> 'allgemein';
select satz_vorschlaege(:'s', :'k_emir') as sv2 \gset
select is(jsonb_array_length(:'sv2'::jsonb), 2, '2 nach dem Deaktivieren weiter zwei Vorschlaege');
select ok(not exists (select 1 from jsonb_array_elements(:'sv2'::jsonb) v
                        join session_satz_bausteine z on z.id = (v ->> 'baustein_id')::uuid where not z.aktiv),
          '2 inaktive Bausteine nie');
select ok((select bool_and(v ->> 'text' not like '%{%') from jsonb_array_elements(:'sv2'::jsonb) v), '2 Platzhalter ersetzt (2)');
update session_satz_bausteine set aktiv = true;
-- Testlauf: erlaubt, mit Testkonto.
select pg_temp.neue_session(array[:'k_tim']::uuid[], 20, true) as st \gset
select pg_temp.act_as(:'coach_a');
select is(jsonb_array_length(satz_vorschlaege(:'st', :'k_tim')), 2, '2 Testlauf erlaubt');
select is((coach_raum_live(:'st')) -> 'session' ->> 'testlauf', 'true', 'L Testlauf im Kopf');

-- ── 3) sessions_offen ─────────────────────────────────────────────────────
select pg_temp.act_as(:'admin');
insert into coaching_sessions (coach_id, room, scheduled_at) values
  (:'coach_a', 'ZZ C2 offen alt', now() - interval '2 hours'),
  (:'coach_a', 'ZZ C2 knapp', now() - interval '80 minutes'),
  (:'coach_a', 'ZZ C2 fertig', now() - interval '3 hours'),
  (:'coach_b', 'ZZ C2 fremd', now() - interval '2 hours');
select set_config('edvance.session_rpc', '1', true);
update coaching_sessions set status = 'done' where room = 'ZZ C2 fertig';
update coaching_sessions set status = 'active', gestartet_am = scheduled_at where room = 'ZZ C2 fremd';
select set_config('edvance.session_rpc', '', true);
select is((select array_agg(room order by room) from sessions_offen() where room like 'ZZ C2%'),
          array['ZZ C2 fremd', 'ZZ C2 offen alt'], '3 Admin: genau die ueber der Grenze und nicht abgeschlossenen');
select pg_temp.act_as(:'coach_a');
select is((select array_agg(room order by room) from sessions_offen() where room like 'ZZ C2%'),
          array['ZZ C2 offen alt'], '3 Coach: nur die eigenen');
select pg_temp.act_as(:'schueler');
select throws_ok('select * from sessions_offen()', '42501', null, '3 Schuelerkonto -> 42501');
select pg_temp.act_as(:'ohne');
select throws_ok('select * from sessions_offen()', '42501', null, '3 Konto ohne Profil -> 42501');

-- ── 4) Katalog ────────────────────────────────────────────────────────────
select is((select count(*)::int from pg_proc p
            where p.pronamespace = 'public'::regnamespace
              and p.proname in ('session_briefing', 'satz_vorschlaege', 'sessions_offen', 'coach_raum_live')
              and p.prosecdef and array_to_string(p.proconfig, ',') like 'search_path=%'), 4,
          '4 neue Funktionen: SECURITY DEFINER mit festem search_path');
select ok(not has_function_privilege('anon', 'public.session_briefing(uuid)', 'execute')
          and not has_function_privilege('anon', 'public.satz_vorschlaege(uuid, uuid)', 'execute')
          and not has_function_privilege('anon', 'public.sessions_offen()', 'execute'), '4 anon darf nichts ausfuehren');

select * from finish();
rollback;
