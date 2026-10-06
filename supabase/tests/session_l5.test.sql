-- ============================================================================
-- Session-Rahmen P1, Paket L5: Kinder-Hinweise pruefen und mit der Aufgabe freigeben
-- (Migrationen 20261008110100 … 20261008110400).
--   1  pruef_aufgabe liefert Hinweise mit Status; ohne Pruefrecht 42501; Konto ohne Profil 42501.
--      pruef_speichern nimmt Hinweise im Entwurf an; Beanstandungsgruende fuer Hinweise.
--   2  Freigabe (einzeln, nach Rueckfrage, gesammelt) setzt alle Hinweise auf geprueft;
--      lsa_hint und hinweis_abrufen liefern sie danach.
--   3  Ruecknahme setzt sie auf entwurf; danach liefern lsa_hint und hinweis_abrufen sie nicht.
--   4  Textaenderung nach der Freigabe -> entwurf.
--   5  hinweise_bestaetigen nur durch Admin und nur fuer freigegebene Aufgaben; Protokollzeile.
--   6  Sammelaktion: Vorschau aendert nichts; Ausfuehrung setzt genau die gewaehlten Aufgaben.
--   7  Lena (Pruefrecht, kein Admin) kann Hinweise nicht auf geprueft setzen.
--   8  Rollenpruefungen aller ersetzten Funktionen der Familie NULL-sicher (Konto ohne Profil).
-- Eigene Fixtures (Quelle 'l5_test'), alles in einer Transaktion, am Ende rollback.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(72);

-- --- Fixtures --------------------------------------------------------------
\set admin_uid  '15000000-0000-4000-8000-00000000000a'
\set lena_uid   '15000000-0000-4000-8000-00000000000b'
\set coach_uid  '15000000-0000-4000-8000-00000000000c'
\set kind_uid   '15000000-0000-4000-8000-00000000000d'
\set ohne_uid   '15000000-0000-4000-8000-00000000000e'
\set tablet_uid '15000000-0000-4000-8000-00000000000f'

insert into auth.users (id, email, instance_id, aud, role)
select u, 'l5-' || n || '@test.local', '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated'
  from (values (:'admin_uid'::uuid, 'admin'), (:'lena_uid', 'lena'), (:'coach_uid', 'coach'), (:'kind_uid', 'kind'),
               (:'ohne_uid', 'ohne-profil'), (:'tablet_uid', 'tablet')) v(u, n);
insert into profiles (id, email, role, full_name, darf_pruefen) values
  (:'admin_uid',  'l5-admin@test.local',  'admin',   'L5 Admin',  false),
  (:'lena_uid',   'l5-lena@test.local',   'coach',   'L5 Lena',   true),
  (:'coach_uid',  'l5-coach@test.local',  'coach',   'L5 Coach',  false),
  (:'kind_uid',   'l5-kind@test.local',   'student', 'L5 Kind',   false),
  (:'tablet_uid', 'l5-tablet@test.local', 'student', 'L5 Tablet', false);
insert into students (profile_id, class_level) values (:'kind_uid', 8);
select id as kind_id from students where profile_id = :'kind_uid' \gset
insert into platz_devices (profile_id, label, tablet_nr) values (:'tablet_uid', 'ZZ L5 Tablet', 1);

-- Eine vollstaendige Kreis-Aufgabe (Gate erfuellt, wie admin_pruefansicht) mit zwei Kinder-Hinweisen.
create function pg_temp.aufgabe(p_ref text, p_status text default 'draft')
returns uuid language plpgsql as $$
declare v uuid;
begin
  insert into tasks (content_type, input_type, title, question, afb, cluster_id, curriculum_grade,
                     skill_key, sondierrang, source, source_ref, status, pruef_pilot)
  values ('exercise', 'NUMERIC', 'AFB II · ' || p_ref, 'Ein Kreis hat den Radius 3,6 m. Wie groß ist sein Umfang?',
          'II', (select id from skill_clusters order by id limit 1), 9, 'geo_kreis_umfang', 3,
          'l5_test', p_ref, p_status, true)
  returning id into v;
  insert into task_solutions (task_id, correct_answers, acceptance, solution, hints)
  values (v, '["22,62", "22.62"]', '{"canonical": "22,62", "equivalents": ["22.62"], "known_errors": {"7,2": "pi_vergessen"}}',
          'U = 2 · π · 3,6 m ≈ 22,62 m',
          jsonb_build_array(jsonb_build_object('level', 1, 'text', 'L5 Stufe 1 ' || p_ref),
                            jsonb_build_object('level', 2, 'text', 'L5 Stufe 2 ' || p_ref)));
  return v;
end $$;
create function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;
create function pg_temp.v(p_id uuid) returns bigint language sql as $$ select pruef_version from tasks where id = p_id $$;
-- Status je Stufe, z. B. 'entwurf,entwurf'.
create function pg_temp.hs(p_id uuid) returns text language sql as $$
  select string_agg(coalesce(h ->> 'status', '-'), ',' order by (h ->> 'level')::int)
    from task_solutions s, jsonb_array_elements(s.hints) h where s.task_id = p_id
$$;
create function pg_temp.fehler(p_sql text) returns text language plpgsql as $$
declare s text; h text;
begin
  execute p_sql;
  return 'kein Fehler';
exception when others then
  get stacked diagnostics s = returned_sqlstate, h = pg_exception_hint;
  return s || ':' || coalesce(h, '');
end $$;
create function pg_temp.lena(p_id uuid) returns void language sql as $$
  insert into task_pruefungen (task_id, entscheidung, aenderungen, geprueft_von, geprueft_am)
  values (p_id, 'passt', '[]', '15000000-0000-4000-8000-00000000000b', clock_timestamp())
$$;
create function pg_temp.protokoll(p_id uuid, p_aktion text) returns bigint language sql as $$
  select count(*) from task_admin_protokoll where task_id = p_id and aktion = p_aktion
$$;

select pg_temp.aufgabe('l5-lena') as lena_t, pg_temp.aufgabe('l5-frei', 'review') as frei,
       pg_temp.aufgabe('l5-rueckfrage', 'rueckfrage') as rueck, pg_temp.aufgabe('l5-sammel', 'review') as sammel,
       pg_temp.aufgabe('l5-alt1', 'ready') as alt1, pg_temp.aufgabe('l5-alt2', 'ready') as alt2,
       pg_temp.aufgabe('l5-alt3', 'ready') as alt3, pg_temp.aufgabe('l5-draft') as entwurf_t
\gset
select pg_temp.lena(:'frei'), pg_temp.lena(:'sammel');

-- ============================================================================
-- 1  pruef_aufgabe und pruef_speichern
-- ============================================================================
select is(pg_temp.hs(:'lena_t'), 'entwurf,entwurf', '1 neue Hinweise starten im entwurf (E1-Trigger)');
select pg_temp.act_as(:'lena_uid');
select pruef_aufgabe(:'lena_t') as pa \gset
select is((:'pa'::jsonb) -> 'hinweise',
          jsonb_build_array(jsonb_build_object('stufe', 1, 'text', 'L5 Stufe 1 l5-lena', 'status', 'entwurf'),
                            jsonb_build_object('stufe', 2, 'text', 'L5 Stufe 2 l5-lena', 'status', 'entwurf')),
          '1 pruef_aufgabe liefert Hinweise mit Stufe, Text und Status in Stufenreihenfolge');
select is(jsonb_array_length((:'pa'::jsonb) #> '{ausgang,hinweise}'), 2, '1 die Ausgangsfassung traegt die Hinweise');
select pg_temp.act_as(:'coach_uid');
select throws_ok(format('select pruef_aufgabe(%L)', :'lena_t'), '42501', null, '1 Coach ohne Pruefrecht -> 42501');
select pg_temp.act_as(:'ohne_uid');
select throws_ok(format('select pruef_aufgabe(%L)', :'lena_t'), '42501', null, '1 Konto ohne Profil -> 42501');
select pg_temp.act_as(:'kind_uid');
select throws_ok(format('select pruef_aufgabe(%L)', :'lena_t'), '42501', null, '1 Kind -> 42501');

-- Lena aendert Stufe 1, laesst Stufe 2 und ergaenzt Stufe 3.
select pg_temp.act_as(:'lena_uid');
select pg_temp.v(:'lena_t') as v0 \gset
select pruef_speichern(:'lena_t', :'v0',
  '{"hinweise":[{"stufe":1,"text":"  Was ist der Durchmesser?  "},{"stufe":2,"text":"L5 Stufe 2 l5-lena"},{"stufe":3,"text":"Rechne 2 · π · r."}]}')
  as ps \gset
select is((select hints from task_solutions where task_id = :'lena_t'),
  '[{"level":1,"text":"Was ist der Durchmesser?","status":"entwurf"},{"level":2,"text":"L5 Stufe 2 l5-lena","status":"entwurf"},{"level":3,"text":"Rechne 2 · π · r.","status":"entwurf"}]'::jsonb,
  '1 pruef_speichern schreibt die Hinweise (Text getrimmt, neue Stufe 3)');
select cmp_ok((:'ps'::jsonb ->> 'pruef_version')::bigint, '>', :'v0'::bigint, '1 Versionierung: pruef_version steigt');
select is((select jsonb_agg(e ->> 'teil' order by e ->> 'teil') from jsonb_array_elements(:'ps'::jsonb -> 'aenderungen') e
            where e ->> 'feld' = 'hinweis'), '["1", "3"]'::jsonb, '1 Aenderungsliste: Hinweis Stufe 1 und 3');
select is(jsonb_array_length(:'ps'::jsonb -> 'hinweise'), 3, '1 pruef_speichern liefert die Hinweise zurueck');
select is(pg_temp.fehler(format($$select pruef_speichern(%L, %s, '{"hinweise":[{"stufe":1,"text":"a"},{"stufe":3,"text":"c"}]}')$$,
          :'lena_t', pg_temp.v(:'lena_t'))), 'ED422:hinweis_luecke', '1 Luecke in den Stufen abgelehnt');
select is(pg_temp.fehler(format($$select pruef_speichern(%L, %s, '{"hinweise":[{"stufe":4,"text":"d"}]}')$$,
          :'lena_t', pg_temp.v(:'lena_t'))), 'ED422:hinweis_ungueltig', '1 Stufe 4 abgelehnt');
select is(pg_temp.fehler(format($$select pruef_speichern(%L, %s, %L)$$, :'lena_t', pg_temp.v(:'lena_t'),
          jsonb_build_object('hinweise', jsonb_build_array(jsonb_build_object('stufe', 1, 'text', repeat('x', 501)))))),
          'ED422:hinweis_zu_lang', '1 zu langer Hinweis abgelehnt');
select pg_temp.v(:'lena_t') as v1 \gset
select pruef_speichern(:'lena_t', :'v1', '{"afb":"II"}');
select is(pg_temp.v(:'lena_t'), :'v1'::bigint, '1 Speichern ohne Hinweis-Schluessel laesst die Hinweise (keine neue Version)');
select pruef_speichern(:'lena_t', :'v1',
  '{"hinweise":[{"stufe":1,"text":"Was ist der Durchmesser?"},{"stufe":2,"text":"L5 Stufe 2 l5-lena"}]}');
select is((select count(*)::int from task_solutions s, jsonb_array_elements(s.hints) h where s.task_id = :'lena_t'), 2,
          '1 leerer bzw. fehlender Text: Stufe 3 entfaellt');
select is(pg_temp.fehler(format($$select pruef_entscheiden(%L, %s, 'passt_nicht', array['hinweis_verraet_loesung', 'hinweis_passt_nicht'])$$,
          :'lena_t', pg_temp.v(:'lena_t'))), 'kein Fehler', '1 Beanstandung mit den Hinweis-Gruenden');
select is((select array_agg(kategorie order by kategorie) from task_reviews where task_id = :'lena_t'),
          array['hinweis_passt_nicht', 'hinweis_verraet_loesung'], '1 beide Gruende in task_reviews');
select ok(array['hinweis_verraet_loesung', 'hinweis_passt_nicht'] <@ pruef_admin_gruende(), '1 Admin kennt die Gruende auch');

-- ============================================================================
-- 7  Lena kann Hinweise nicht auf geprueft setzen
-- ============================================================================
select pg_temp.act_as(:'lena_uid');
select throws_ok(format($$select hinweis_status_setzen(%L, 1, 'geprueft')$$, :'entwurf_t'), '42501', null,
                 '7 hinweis_status_setzen geprueft -> 42501 (Lena)');
select pruef_speichern(:'entwurf_t', pg_temp.v(:'entwurf_t'),
  '{"hinweise":[{"stufe":1,"text":"L5 Stufe 1 l5-draft","status":"geprueft"},{"stufe":2,"text":"neu","status":"geprueft"}]}');
select is(pg_temp.hs(:'entwurf_t'), 'entwurf,entwurf', '7 status im Entwurf wird nicht uebernommen');
select throws_ok(format('select hinweise_bestaetigen(%L)', :'alt1'), '42501', null, '7 hinweise_bestaetigen -> 42501 (Lena)');
select throws_ok(format($$select pruef_sammel('hinweise_bestaetigen', array[%L]::uuid[], '{}', false)$$, :'alt1'),
                 '42501', null, '7 Sammelaktion -> 42501 (Lena)');
select throws_ok(format('select pruef_admin_freigeben(%L)', :'frei'), '42501', null, '7 Freigabe -> 42501 (Lena)');
select is(pg_temp.fehler(format($$select task_solution_upsert(%L, '["22,62"]', null, '[{"level":1,"text":"x","status":"geprueft"}]')$$,
          :'entwurf_t')), '42501:', '7 task_solution_upsert -> 42501 (Lena, seit Lena-Board)');
select is(pg_temp.hs(:'alt1'), 'entwurf,entwurf', '7 alles weiter entwurf');
select pg_temp.act_as(:'admin_uid');
select throws_ok(format($$select hinweis_status_setzen(%L, 1, 'geprueft')$$, :'entwurf_t'), '42501', null,
                 '7 auch Admin: geprueft nur ueber die Freigabe');
select lives_ok(format($$select hinweis_status_setzen(%L, 1, 'entwurf')$$, :'entwurf_t'), '7 zurueck auf entwurf geht weiter');

-- ============================================================================
-- 2  Freigabe setzt alle Hinweise auf geprueft
-- ============================================================================
select pg_temp.act_as(:'admin_uid');
select lives_ok(format('select pruef_admin_freigeben(%L)', :'frei'), '2 Einzelfreigabe');
select is(pg_temp.hs(:'frei'), 'geprueft,geprueft', '2 Einzelfreigabe: alle Hinweise geprueft');
select is(pg_temp.protokoll(:'frei', 'freigeben'), 1::bigint, '2 Protokoll wie bisher');
select lives_ok(format($$select pruef_rueckfrage_klaeren(%L, 'freigeben', 'ok')$$, :'rueck'), '2 Freigabe nach Rueckfrage');
select is(pg_temp.hs(:'rueck'), 'geprueft,geprueft', '2 Freigabe nach Rueckfrage: alle geprueft');
select is(pruef_sammel('freigeben', array[:'sammel']::uuid[], '{}', true) -> 'betrifft', jsonb_build_array(:'sammel'),
          '2 Sammelfreigabe-Vorschau trifft die Aufgabe');
select is(pg_temp.hs(:'sammel'), 'entwurf,entwurf', '2 Vorschau aendert nichts');
select pruef_sammel('freigeben', array[:'sammel']::uuid[], '{}', false);
select is(pg_temp.hs(:'sammel'), 'geprueft,geprueft', '2 Sammelfreigabe: alle geprueft');

-- lsa_hint (Kind selbst) und hinweis_abrufen (Tablet in der Session) liefern sie.
insert into lsa_sessions (student_id, subject, grade, item_ids) values (:'kind_id', 'Mathematik', 8, array[:'frei'::uuid])
returning id as lsa_sid \gset
select pg_temp.act_as(:'kind_uid');
select is(lsa_hint(:'lsa_sid', :'frei', 1) ->> 'text', 'L5 Stufe 1 l5-frei', '2 lsa_hint liefert Stufe 1 nach der Freigabe');
select is(lsa_hint(:'lsa_sid', :'frei', 2) ->> 'available', 'true', '2 lsa_hint liefert Stufe 2');

-- Session wie R1: Kind mit Lead und Vertrag, Coach startet, Tablet zugewiesen, Aufgabe ausgegeben.
create function pg_temp.sitzungskind() returns uuid language plpgsql as $$
declare v_lead uuid; v_st uuid;
begin
  insert into leads (full_name, first_name, status, class_level) values ('ZZ Lina L5', 'ZZ Lina', 'vertrag', 8)
  returning id into v_lead;
  insert into students (class_level) values (8) returning id into v_st;
  update leads set converted_student_id = v_st where id = v_lead;
  insert into vertraege (lead_id, status, vertrag_status, abgeschlossen_at, abgeschlossen_am, abschluss_weg,
                         student_id, vertragsbeginn, vertrag_ende, widerruf_bis)
  values (v_lead, 'abgeschlossen', 'aktiv', now(), date_trunc('month', current_date)::date - 31, 'vor_ort', v_st,
          date_trunc('month', current_date - 31)::date,
          (date_trunc('month', current_date) + interval '7 month' - interval '1 day')::date, current_date - 16);
  return v_st;
end $$;
reset role;
select pg_temp.sitzungskind() as skind \gset
insert into coaching_sessions (coach_id, room, scheduled_at) values (:'coach_uid', 'ZZ L5', now()) returning id as sid \gset
insert into session_students (session_id, student_id) values (:'sid', :'skind');
select pg_temp.act_as(:'coach_uid');
select session_starten(:'sid');
select tablet_zuweisen(:'sid', :'skind', 1);
select aufgabe_ausgeben(:'sid', :'skind', t) from unnest(array[:'frei', :'alt3']::uuid[]) t;
select pg_temp.act_as(:'tablet_uid');
select is(hinweis_abrufen(:'sid', :'frei', 1) ->> 'text', 'L5 Stufe 1 l5-frei', '2 hinweis_abrufen liefert Stufe 1 nach der Freigabe');
select is(hinweis_abrufen(:'sid', :'alt3', 1) ->> 'verfuegbar', 'false', '2 freigegeben, Hinweis ungeprueft: nichts');

-- ============================================================================
-- 4  Textaenderung nach der Freigabe -> entwurf
-- ============================================================================
select pg_temp.act_as(:'admin_uid');
select task_solution_upsert(:'rueck', '["22,62", "22.62"]', 'U = 2 · π · 3,6 m ≈ 22,62 m',
  '[{"level":1,"text":"L5 Stufe 1 l5-rueckfrage"},{"level":2,"text":"Neuer Text"}]', '[]', '[]', null,
  '{"canonical": "22,62", "equivalents": ["22.62"], "known_errors": {"7,2": "pi_vergessen"}}', null);
select is(pg_temp.hs(:'rueck'), 'geprueft,entwurf', '4 geaenderter Text faellt auf entwurf, der andere bleibt geprueft');

-- ============================================================================
-- 3  Ruecknahme setzt die Hinweise auf entwurf
-- ============================================================================
select pg_temp.act_as(:'admin_uid');
select lives_ok(format('select pruef_freigabe_zuruecknehmen(%L)', :'frei'), '3 Ruecknahme');
select is(pg_temp.hs(:'frei'), 'entwurf,entwurf', '3 Ruecknahme: alle Hinweise entwurf');
select pg_temp.act_as(:'kind_uid');
select is(lsa_hint(:'lsa_sid', :'frei', 1) ->> 'available', 'false', '3 lsa_hint liefert nach der Ruecknahme nichts');
select pg_temp.act_as(:'tablet_uid');
select is(hinweis_abrufen(:'sid', :'frei', 2) ->> 'verfuegbar', 'false', '3 hinweis_abrufen liefert nach der Ruecknahme nichts');
select pg_temp.act_as(:'admin_uid');
select is(freigabe_zuruecknehmen('geo_kreis_umfang') >= 1, true, '3 Ruecknahme je Fertigkeit');
select is(pg_temp.hs(:'sammel'), 'entwurf,entwurf', '3 freigabe_zuruecknehmen setzt die Hinweise auf entwurf');
-- alt1..alt3 sind damit auch draft; fuer 5 und 6 wieder freigeben, ohne die Hinweise zu beruehren.
update tasks set status = 'ready' where id in (:'alt1', :'alt2', :'alt3');
select is(pg_temp.hs(:'alt1') || '|' || pg_temp.hs(:'alt2'), 'entwurf,entwurf|entwurf,entwurf', '3 Fixture: alt1/alt2 ready, Hinweise entwurf');

-- ============================================================================
-- 5  hinweise_bestaetigen
-- ============================================================================
select pg_temp.act_as(:'admin_uid');
select is(pg_temp.fehler(format('select hinweise_bestaetigen(%L)', :'entwurf_t')), 'ED422:nicht_freigegeben',
          '5 nur fuer freigegebene Aufgaben');
select hinweise_bestaetigen(:'alt1') as hb \gset
select is(pg_temp.hs(:'alt1'), 'geprueft,geprueft', '5 Admin bestaetigt: alle geprueft');
select is(pg_temp.protokoll(:'alt1', 'hinweise_bestaetigen'), 1::bigint, '5 eine Protokollzeile');
select results_eq(format($$select aenderungen, sammel, von from task_admin_protokoll
                          where task_id = %L and aktion = 'hinweise_bestaetigen'$$, :'alt1'),
  format($$values ('[{"feld":"hinweis_status","teil":1,"vorher":"entwurf","nachher":"geprueft"},{"feld":"hinweis_status","teil":2,"vorher":"entwurf","nachher":"geprueft"}]'::jsonb, false, %L::uuid)$$, :'admin_uid'),
  '5 Protokoll: Stufen vorher/nachher, einzeln, von Admin');
select is(pg_temp.fehler(format('select hinweise_bestaetigen(%L)', :'alt1')), 'ED422:keine_hinweise_offen',
          '5 zweiter Aufruf: nichts offen');
select is(pg_temp.fehler(format('select hinweise_bestaetigen(%L)', gen_random_uuid())), 'P0002:', '5 unbekannte Aufgabe P0002');
select pg_temp.act_as(:'coach_uid');
select throws_ok(format('select hinweise_bestaetigen(%L)', :'alt2'), '42501', null, '5 Coach -> 42501');

-- ============================================================================
-- 6  Sammelaktion hinweise_bestaetigen
-- ============================================================================
select pg_temp.act_as(:'admin_uid');
select pruef_sammel('hinweise_bestaetigen', array[:'alt1', :'alt2', :'alt3', :'entwurf_t']::uuid[], '{}', true) as vs \gset
select is(:'vs'::jsonb -> 'betrifft', jsonb_build_array(:'alt2', :'alt3'), '6 Vorschau: betrifft alt2 und alt3');
select is((select jsonb_object_agg(a ->> 'task_id', a ->> 'grund') from jsonb_array_elements(:'vs'::jsonb -> 'ausgelassen') a),
          jsonb_build_object(:'alt1', 'keine_hinweise_offen', :'entwurf_t', 'nicht_freigegeben'), '6 Vorschau: Auslassgruende');
select is(pg_temp.hs(:'alt2') || '|' || pg_temp.hs(:'alt3'), 'entwurf,entwurf|entwurf,entwurf', '6 Vorschau aendert nichts');
select pruef_sammel('hinweise_bestaetigen', array[:'alt2']::uuid[], '{"grund":"Altbestand"}', false);
select is(pg_temp.hs(:'alt2') || '|' || pg_temp.hs(:'alt3'), 'geprueft,geprueft|entwurf,entwurf',
          '6 Ausfuehrung setzt genau die gewaehlte Aufgabe');
select results_eq(format($$select sammel, grund from task_admin_protokoll where task_id = %L and aktion = 'hinweise_bestaetigen'$$, :'alt2'),
  $$values (true, 'Altbestand'::text)$$, '6 Protokoll: gesammelt, mit Grund');
select is((select hinweise_ungeprueft from pruef_admin_liste() where task_id = :'alt3'), 2, '6 Admin-Liste: alt3 hat 2 ungepruefte');
select is((select hinweise_ungeprueft || '/' || hinweise from pruef_admin_liste() where task_id = :'alt2'), '0/2',
          '6 Admin-Liste: alt2 0 von 2 ungeprueft');

-- ============================================================================
-- 8  Rollenpruefungen NULL-sicher: Konto ohne Profil
-- ============================================================================
select pg_temp.act_as(:'ohne_uid');
select is(pg_temp.fehler(format('select pruef_speichern(%L, 1, %L)', :'entwurf_t', '{}')), '42501:', '8 pruef_speichern');
select is(pg_temp.fehler(format($$select pruef_entscheiden(%L, 1, 'passt')$$, :'entwurf_t')), '42501:', '8 pruef_entscheiden');
select is(pg_temp.fehler(format('select pruef_admin_freigeben(%L)', :'entwurf_t')), '42501:', '8 pruef_admin_freigeben');
select is(pg_temp.fehler(format('select pruef_freigabe_zuruecknehmen(%L)', :'alt3')), '42501:', '8 pruef_freigabe_zuruecknehmen');
select is(pg_temp.fehler($$select freigabe_zuruecknehmen('geo_kreis_umfang')$$), '42501:', '8 freigabe_zuruecknehmen');
select is(pg_temp.fehler(format($$select pruef_rueckfrage_klaeren(%L, 'freigeben', null)$$, :'entwurf_t')), '42501:', '8 pruef_rueckfrage_klaeren');
select is(pg_temp.fehler(format($$select pruef_sammel('freigeben', array[%L]::uuid[], '{}', true)$$, :'entwurf_t')), '42501:', '8 pruef_sammel');
select is(pg_temp.fehler('select count(*) from pruef_admin_liste()'), '42501:', '8 pruef_admin_liste');
select is(pg_temp.fehler(format('select hinweise_bestaetigen(%L)', :'alt3')), '42501:', '8 hinweise_bestaetigen');
select is(pg_temp.fehler(format($$select hinweis_status_setzen(%L, 1, 'entwurf')$$, :'alt3')), '42501:', '8 hinweis_status_setzen');
select is(pg_temp.hs(:'alt3'), 'entwurf,entwurf', '8 nichts geaendert');

select * from finish();
rollback;
