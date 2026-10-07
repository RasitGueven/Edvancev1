-- ============================================================================
-- R1: Session-Datenmodell und Server-Funktionen (Bauauftrag Session-Rahmen P1).
--
-- Zusagen (Nummern wie im Auftrag):
--    1) einstellung_setzen: ausserhalb der Spanne abgelehnt, innerhalb Protokollzeile.
--    2) session_starten speichert den Snapshot; spaetere Aenderungen aendern ihn nicht.
--    3) tablet_zuweisen: Kind ohne Buchung, sechstes Kind, fremder Coach abgelehnt;
--       gueltig -> anwesend.
--    4) fall_vorschlag: Klassenarbeit in 2 Tagen -> klassenarbeit; in 21 Tagen mit
--       aktuellem Thema -> schulthema; ohne Thema -> lernpfad.
--    5) Neues Schulthema ueber den Coach: altes behandelt, neues aktuell.
--    6) antwort_abgeben wertet wie die LSA-Engine, Fehlbild aus known_errors, ohne Loesung.
--    7) hinweis_abrufen liefert keinen Hinweis ohne Pruefstatus.
--    8) Zwei Fehlversuche -> Signal; nach signal_erledigen weg; Reihenfolge
--       kandidat vor entscheidung vor haengt.
--    9) eingriff_notieren Stufe 3 ohne Fehlbild abgelehnt.
--   10) coach_raum_live / coach_kind_detail: fremder Coach und Schuelerkonto -> 42501.
--   11) session_abschliessen setzt Anwesenheit, schreibt Notiz und Flags in die Akte.
--
-- Lauf: npx supabase test db
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(90);

\set admin 'eeeeeeee-0001-4000-8000-000000000001'
\set coach_a 'eeeeeeee-0001-4000-8000-000000000002'
\set coach_b 'eeeeeeee-0001-4000-8000-000000000003'
\set schueler 'eeeeeeee-0001-4000-8000-000000000004'

insert into auth.users (id, email, instance_id, aud, role)
select u, 'r1-' || n || '@test.local', '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated'
  from (values (:'admin'::uuid, 'admin'), (:'coach_a', 'coach-a'), (:'coach_b', 'coach-b'), (:'schueler', 'schueler')) v(u, n)
union all
select ('eeeeeeee-0002-4000-8000-00000000000' || i)::uuid, 'r1-tablet' || i || '@test.local',
       '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated'
  from generate_series(1, 6) i;

insert into profiles (id, email, role, full_name) values
  (:'admin', 'r1-admin@test.local', 'admin', 'R1 Admin'),
  (:'coach_a', 'r1-coach-a@test.local', 'coach', 'R1 Coach A'),
  (:'coach_b', 'r1-coach-b@test.local', 'coach', 'R1 Coach B'),
  (:'schueler', 'r1-schueler@test.local', 'student', 'R1 Schueler');
insert into profiles (id, email, role, full_name)
select ('eeeeeeee-0002-4000-8000-00000000000' || i)::uuid, 'r1-tablet' || i || '@test.local', 'student', 'Tablet ' || i
  from generate_series(1, 6) i;
insert into platz_devices (profile_id, label, tablet_nr)
select ('eeeeeeee-0002-4000-8000-00000000000' || i)::uuid, 'ZZ R1 Tablet ' || i, i
  from generate_series(1, 6) i;

create or replace function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;
create or replace function pg_temp.als_system() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('role', 'service_role')::text, true);
end $$;
create or replace function pg_temp.tablet(i int) returns uuid language sql as $$
  select ('eeeeeeee-0002-4000-8000-00000000000' || i)::uuid
$$;

-- Kind mit Lead und laufendem Vertrag (Weg Kind -> Lead ueber converted_student_id).
create or replace function pg_temp.kind(p_name text) returns uuid language plpgsql as $$
declare v_lead uuid; v_st uuid;
begin
  insert into leads (full_name, first_name, status, class_level) values (p_name, split_part(p_name, ' ', 1), 'vertrag', 8)
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

select pg_temp.kind('ZZ Eins R1') as k1, pg_temp.kind('ZZ Zwei R1') as k2, pg_temp.kind('ZZ Drei R1') as k3,
       pg_temp.kind('ZZ Vier R1') as k4, pg_temp.kind('ZZ Fuenf R1') as k5, pg_temp.kind('ZZ Sechs R1') as k6,
       pg_temp.kind('ZZ Sieben R1') as k7
\gset

insert into themen (thema_key, fach, klasse, stufe, label, sort) values
  ('zz_r1_alt', 'mathematik', 8, 'erste', 'R1 Alt', 9101),
  ('zz_r1_neu', 'mathematik', 8, 'erste', 'R1 Neu', 9102);
insert into lead_themen (lead_id, fach, thema_key, status, quelle)
select l.id, 'mathematik', 'zz_r1_alt', 'aktuell', 'gespraech' from leads l where l.converted_student_id = :'k1';

insert into coaching_sessions (coach_id, room, scheduled_at) values (:'coach_a', 'ZZ R1', now()) returning id as s \gset
insert into coaching_sessions (coach_id, room, scheduled_at) values (:'coach_b', 'ZZ R1b', now()) returning id as s2 \gset
insert into session_students (session_id, student_id)
select :'s', k from unnest(array[:'k1', :'k2', :'k3', :'k4', :'k5', :'k6']::uuid[]) k;

insert into fehlbild_labels (slug, klartext, freigegeben_am) values ('zz_r1_fb', 'ZZ Klartext R1', now());
insert into tasks (cluster_id, content_type, input_type, status, question, question_payload, afb, competency_content,
                   est_duration_sec, class_level, source, source_ref)
select null, 'exercise', 'SHORT_TEXT', st, 'Wie viel ist 2 * 5?',
       '{"input_type":"SHORT_TEXT","kind":"short_input","prompt":"Wie viel ist 2 * 5?"}'::jsonb,
       'I', 'Terme und Gleichungen', 60, 8, 'test', ref
  from (values ('ready', 'r1-ready'), ('draft', 'r1-draft')) v(st, ref);
select (select id from tasks where source_ref = 'r1-ready') as t1, (select id from tasks where source_ref = 'r1-draft') as t2
\gset
-- Gepruefter Hinweis als Fixture: E1 (20261007135106_hinweis_status) setzt den Status nur
-- mit diesem Schalter, sonst faellt ein neuer Hinweis auf entwurf. Ohne E1 wirkungslos.
select set_config('edvance.hinweis_status', 'setzen', true);
insert into task_solutions (task_id, correct_answers, solution, hints, acceptance)
values (:'t1', '["10"]', 'ZZ-Musterloesung: 2 * 5 = 10',
        '[{"level":1,"text":"ZZ Hinweis ungeprueft"},{"level":2,"text":"ZZ Hinweis geprueft","status":"geprueft"}]',
        '{"canonical":"10","known_errors":{"14":"zz_r1_fb"}}');
select set_config('edvance.hinweis_status', '', true);

-- ── 1) Stellschrauben ──────────────────────────────────────────────────────
select is((select count(*)::int from session_einstellungen), 29, '1 alle 29 Stellschrauben mit Startwert (A2b: session_xp_je_aufgabe)');
select pg_temp.act_as(:'coach_a');
select throws_ok($$select einstellung_setzen('quest_xp', '60', 'Test')$$, '42501', null, '1 Coach darf nicht setzen');
select pg_temp.act_as(:'admin');
select throws_ok($$select einstellung_setzen('quest_xp', '101', 'Test')$$, '22023', null, '1 ausserhalb der Spanne abgelehnt');
select throws_ok($$select einstellung_setzen('ziel_erfolgsquote', '0.95', 'Test')$$, '22023', null, '1 Anteil ausserhalb abgelehnt');
select throws_ok($$select einstellung_setzen('erklaerung_bei_neuem_skill', '"immer"', 'Test')$$, '22023', null, '1 Auswahl ausserhalb abgelehnt');
select throws_ok($$select einstellung_setzen('quest_xp', '60', ' ')$$, '22023', null, '1 ohne Grund abgelehnt');
select lives_ok($$select einstellung_setzen('quest_xp', '60', 'Pilot')$$, '1 innerhalb der Spanne gesetzt');
select results_eq($$select alt, neu, grund, von from session_einstellungen_protokoll where schluessel = 'quest_xp'$$,
  format($$values ('50'::jsonb, '60'::jsonb, 'Pilot'::text, %L::uuid)$$, :'admin'), '1 Protokollzeile alt/neu/grund/von');

-- ── 2) Start und Snapshot ──────────────────────────────────────────────────
select pg_temp.act_as(:'coach_b');
select throws_ok(format('select session_starten(%L)', :'s'), '42501', null, '2 fremder Coach startet nicht');
select pg_temp.act_as(:'coach_a');
select throws_ok(format($$update coaching_sessions set status = 'active' where id = %L$$, :'s'), '42501', null,
  '2 Status direkt per UPDATE gesperrt');
select lives_ok(format('select session_starten(%L)', :'s'), '2 Coach startet die Session');
select pg_temp.act_as(:'admin');
select einstellung_setzen('ka_tage', '14', 'Snapshot-Test');
select is((select einstellungen ->> 'ka_tage' from coaching_sessions where id = :'s'), '7', '2 Snapshot bleibt bei 7');
select is((select einstellungen ->> 'quest_xp' from coaching_sessions where id = :'s'), '60', '2 Snapshot enthaelt den Stand beim Start');
select is((select status from coaching_sessions where id = :'s'), 'active', '2 Status laeuft (active)');
select throws_ok(format('select session_starten(%L)', :'s'), 'P0001', null, '2 zweiter Start abgelehnt');

-- ── 3) Tablets ─────────────────────────────────────────────────────────────
select pg_temp.act_as(:'coach_a');
select throws_ok(format('select tablet_zuweisen(%L, %L, 1)', :'s', :'k7'), 'P0001', null, '3 Kind ohne Buchung abgelehnt');
select pg_temp.act_as(:'coach_b');
select throws_ok(format('select tablet_zuweisen(%L, %L, 1)', :'s', :'k1'), '42501', null, '3 fremder Coach abgelehnt');
select pg_temp.act_as(:'coach_a');
select throws_ok(format('select tablet_zuweisen(%L, %L, 7)', :'s', :'k1'), '22023', null, '3 Tablet-Nummer ausserhalb 1 bis 5 abgelehnt');
select lives_ok(format($$select tablet_zuweisen(%L, k, i::int) from unnest(array[%L, %L, %L, %L, %L]::uuid[]) with ordinality u(k, i)$$,
  :'s', :'k1', :'k2', :'k3', :'k4', :'k5'), '3 fuenf Kinder an Tablet 1 bis 5');
select throws_ok(format('select tablet_zuweisen(%L, %L, 6)', :'s', :'k6'), 'P0001', null, '3 sechstes Kind abgelehnt');
select is((select attendance from session_students where session_id = :'s' and student_id = :'k1'), 'present', '3 gueltig -> anwesend');
select is((select attendance from session_students where session_id = :'s' and student_id = :'k6'), 'planned', '3 abgelehntes Kind bleibt geplant');

-- ── 4) Check-in und Fall ───────────────────────────────────────────────────
select pg_temp.act_as(pg_temp.tablet(1));
select checkin_kind_speichern(:'s', 'gut', current_date + 21, 'zz_r1_alt', 'noch_dran');
select pg_temp.act_as(pg_temp.tablet(2));
select checkin_kind_speichern(:'s', 'angespannt', current_date + 2, 'zz_r1_neu', 'noch_dran');
select throws_ok(format($$select checkin_kind_speichern(%L, 'gut', null, null, 'noch_dran')$$, :'s2'), '42501', null,
  '4 Tablet nur fuer den eigenen Platz');
select pg_temp.act_as(pg_temp.tablet(3));
select checkin_kind_speichern(:'s', 'geht_so', null, null, 'neu', 'Steigung');
select pg_temp.act_as(pg_temp.tablet(4));
select checkin_kind_speichern(:'s', 'gut', (now() at time zone 'Europe/Berlin')::date + 7, 'zz_r1_neu', 'noch_dran');
select pg_temp.act_as(pg_temp.tablet(5));
select checkin_kind_speichern(:'s', 'gut', (now() at time zone 'Europe/Berlin')::date + 8, 'zz_r1_neu', 'noch_dran');
select pg_temp.act_as(:'coach_a');
select is(fall_vorschlag(:'s', :'k2'), 'klassenarbeit', '4 Klassenarbeit in 2 Tagen -> klassenarbeit');
select is(fall_vorschlag(:'s', :'k4'), 'klassenarbeit', '4 Klassenarbeit in genau ka_tage (7) Tagen zaehlt (einschliesslich)');
select is(fall_vorschlag(:'s', :'k5'), 'lernpfad', '4 Klassenarbeit in 8 Tagen zaehlt nicht');
select is(fall_vorschlag(:'s', :'k1'), 'schulthema', '4 Klassenarbeit in 21 Tagen mit Thema -> schulthema');
select is(fall_vorschlag(:'s', :'k3'), 'lernpfad', '4 ohne Thema -> lernpfad');
select results_eq(format($$select fall_vorschlag, ziel_thema_key, thema_stichwort from session_checkin
  where session_id = %L and student_id = %L$$, :'s', :'k2'), $$values ('klassenarbeit'::text, 'zz_r1_neu'::text, null::text)$$,
  '4 Vorschlag und Ziel gespeichert');
select is(session_phase(:'s', :'k1'), 'warmup', '4 nach dem Check-in beginnt das Warm-up');

-- ── 5) Neues Schulthema ────────────────────────────────────────────────────
select checkin_coach_setzen(:'s', :'k1', 'schulthema', 'zz_r1_neu');
select results_eq(format($$select thema_key, status from lead_themen
  where lead_id = (select id from leads where converted_student_id = %L) order by thema_key$$, :'k1'),
  $$values ('zz_r1_alt'::text, 'behandelt'::text), ('zz_r1_neu', 'aktuell')$$, '5 altes behandelt, neues aktuell');
select results_eq(format($$select fall_vorschlag, fall_coach, ziel_thema_key from session_checkin
  where session_id = %L and student_id = %L$$, :'s', :'k1'),
  $$values ('schulthema'::text, 'schulthema'::text, 'zz_r1_neu'::text)$$, '5 Vorschlag und Coach-Wahl getrennt, Ziel neu');
select checkin_coach_setzen(:'s', :'k2', 'lernpfad');
select results_eq(format($$select fall_vorschlag, fall_coach from session_checkin where session_id = %L and student_id = %L$$,
  :'s', :'k2'), $$values ('klassenarbeit'::text, 'lernpfad'::text)$$, '5 Entscheidung ueberschreibt den Vorschlag nicht');

-- ── 6) Antworten ───────────────────────────────────────────────────────────
select throws_ok(format('select aufgabe_ausgeben(%L, %L, %L)', :'s', :'k3', :'t2'), 'P0001', null, '6 Entwurf wird nicht ausgegeben');
select aufgabe_ausgeben(:'s', k, :'t1') from unnest(array[:'k3', :'k4']::uuid[]) k;
select pg_temp.act_as(pg_temp.tablet(3));
select antwort_abgeben(:'s', :'t1', null, '"14"', 4200) as a1 \gset
select is((:'a1'::jsonb) ->> 'ergebnis',
  (select case lsa_grade('SHORT_TEXT', '{"canonical":"10","known_errors":{"14":"zz_r1_fb"}}', '["10"]', '{"text":"14"}')
          when 'voll' then 'richtig' when 'teilweise' then 'teilweise' else 'falsch' end), '6 Ergebnis wie lsa_grade');
select is((:'a1'::jsonb) ->> 'fehlbild_klartext', 'ZZ Klartext R1', '6 Fehlbild-Klartext aus known_errors');
select is((select fehlbild_slug from session_antworten where session_id = :'s' and student_id = :'k3'), 'zz_r1_fb',
  '6 Fehlbild-Slug gespeichert');
select ok(:'a1' not like '%Musterloesung%' and :'a1' not like '%10%' and not ((:'a1'::jsonb) ?| array['solution', 'correct_answers', 'acceptance']),
  '6 Antwort enthaelt keine Loesung');
select results_eq(format($$select student_id, geraet_id, angemeldet_als, versuch_nr from session_antworten where session_id = %L$$, :'s'),
  format($$values (%L::uuid, %L::uuid, %L::uuid, 1)$$, :'k3', pg_temp.tablet(3), pg_temp.tablet(3)),
  '6 Kind, Geraet und Konto getrennt gespeichert');
select pg_temp.act_as(pg_temp.tablet(4));
select is((antwort_abgeben(:'s', :'t1', null, '{"text":"10"}')) ->> 'ergebnis', 'richtig', '6 richtige Antwort');
select pg_temp.act_as(pg_temp.tablet(5));
select throws_ok(format($$select antwort_abgeben(%L, %L, null, '"10"')$$, :'s', :'t1'), 'P0001', null,
  '6 nicht ausgegebene Aufgabe abgelehnt');
select pg_temp.act_as(:'schueler');
select throws_ok(format($$select antwort_abgeben(%L, %L, null, '"10"')$$, :'s', :'t1'), '42501', null,
  '6 Schuelerkonto ohne Platz abgelehnt');

-- ── 7) Hinweise ────────────────────────────────────────────────────────────
select pg_temp.act_as(pg_temp.tablet(3));
select results_eq(format('select hinweis_abrufen(%L, %L, 1)', :'s', :'t1'),
  $$values ('{"stufe":1,"text":null,"verfuegbar":false}'::jsonb)$$, '7 Hinweis ohne Pruefstatus wird nicht geliefert');
select is((hinweis_abrufen(:'s', :'t1', 2)) ->> 'text', 'ZZ Hinweis geprueft', '7 gepruefter Hinweis wird geliefert');
select throws_ok(format('select hinweis_abrufen(%L, %L, 4)', :'s', :'t1'), '22023', null, '7 Stufe ueber hinweisstufen abgelehnt');
select pg_temp.act_as(pg_temp.tablet(4));
select throws_ok(format('select hinweis_abrufen(%L, %L, 2)', :'s', :'t1'), '22023', null, '7 Stufe 2 erst nach Stufe 1');
select pg_temp.act_as(pg_temp.tablet(3));
select is((select count(*)::int from session_ereignisse where session_id = :'s' and typ = 'hinweis'), 2, '7 beide Abrufe protokolliert');

-- ── 8) Signale ─────────────────────────────────────────────────────────────
select antwort_abgeben(:'s', :'t1', null, '"15"');
select is((select hinweisstufe_max from session_antworten where session_id = :'s' and student_id = :'k3' and versuch_nr = 2), 2,
  '8 Hinweisstufe an der Antwort');
select pg_temp.act_as(:'coach_a');
select is((select count(*)::int from raum_signale(:'s') where student_id = :'k3' and art = 'haengt'), 1,
  '8 zwei Fehlversuche in Folge -> Signal haengt');
select signal_melden(:'s', :'k5', 'entscheidung', '{"grund":"warmup_luecke"}');
select throws_ok(format($$select signal_melden(%L, %L, 'kandidat')$$, :'s', :'k1'), '42501', null,
  '8 Mastery-Kandidat meldet nur das System');
select pg_temp.als_system();
select signal_melden(:'s', :'k1', 'kandidat', '{"skill_key":"zz_skill"}');
select pg_temp.act_as(:'coach_a');
select results_eq(format('select art from raum_signale(%L)', :'s'),
  $$values ('kandidat'::text), ('entscheidung'), ('haengt'), ('hinweis')$$, '8 Reihenfolge kandidat, entscheidung, haengt, hinweis');
select signal_erledigen(:'s', :'k3', 'haengt');
select is((select count(*)::int from raum_signale(:'s') where student_id = :'k3'), 0, '8 nach signal_erledigen weg');
select pg_temp.act_as(pg_temp.tablet(3));
select antwort_abgeben(:'s', :'t1', null, '"16"');
select pg_temp.act_as(:'coach_a');
select is((select count(*)::int from raum_signale(:'s') where student_id = :'k3'), 0, '8 ein neuer Fehlversuch allein loest noch nichts aus');

-- ── 9) Eingriffe ───────────────────────────────────────────────────────────
select throws_ok(format('select eingriff_notieren(%L, %L, 3)', :'s', :'k3'), '22023', null, '9 Stufe 3 ohne Fehlbild abgelehnt');
select lives_ok(format('select eingriff_notieren(%L, %L, 2)', :'s', :'k3'), '9 Stufe 2 ohne Fehlbild');
select eingriff_notieren(:'s', :'k3', 4, 'zz_r1_fb');
select is((select count(*)::int from session_ereignisse where session_id = :'s' and student_id = :'k3' and typ = 'entscheidung_pfad'),
  1, '9 Stufe 4 schreibt entscheidung_pfad');

-- ── Rohdaten nur anhaengen, keine Loeschung ueber die Kaskade ──────────────
select throws_ok(format($$update session_antworten set ergebnis = 'richtig' where session_id = %L$$, :'s'), '42501', null,
  'Antworten werden nicht geaendert');
select throws_ok(format($$delete from session_ereignisse where session_id = %L$$, :'s'), '42501', null,
  'Ereignisse werden nicht geloescht');
select throws_ok(format('delete from coaching_sessions where id = %L', :'s'), '42501', null,
  'Coach loescht keine gestartete Session (Kaskade)');
select throws_ok(format('delete from session_students where session_id = %L and student_id = %L', :'s', :'k3'), '42501', null,
  'Coach loescht keine Buchung mit Antworten (Kaskade)');

-- ── 10) Live-Sicht ─────────────────────────────────────────────────────────
select pg_temp.act_as(:'coach_b');
select throws_ok(format('select coach_raum_live(%L)', :'s'), '42501', null, '10 fremder Coach: coach_raum_live 42501');
select throws_ok(format('select coach_kind_detail(%L, %L)', :'s', :'k3'), '42501', null, '10 fremder Coach: coach_kind_detail 42501');
select pg_temp.act_as(:'schueler');
select throws_ok(format('select coach_raum_live(%L)', :'s'), '42501', null, '10 Schuelerkonto: coach_raum_live 42501');
select throws_ok(format('select coach_kind_detail(%L, %L)', :'s', :'k3'), '42501', null, '10 Schuelerkonto: coach_kind_detail 42501');
select pg_temp.act_as(pg_temp.tablet(3));
select throws_ok(format('select coach_kind_detail(%L, %L)', :'s', :'k3'), '42501', null, '10 Tablet-Konto: coach_kind_detail 42501');
select pg_temp.act_as(:'coach_a');
select coach_raum_live(:'s') as live \gset
select ok(jsonb_array_length((:'live'::jsonb) -> 'kinder') = 6 and :'live' not like '%Musterloesung%',
  '10 Live: alle sechs gebuchten Kinder, keine Musterloesung');
select is((coach_kind_detail(:'s', :'k3')) -> 'aufgabe_detail' ->> 'musterloesung', 'ZZ-Musterloesung: 2 * 5 = 10',
  '10 Detail: Musterloesung fuer den Coach');

-- ── Coach-Rechte: keine eigenen Sessions/Buchungen, Anwesenheit nur ueber RPC ──
grant usage on schema extensions to authenticated;
select pg_temp.act_as(:'coach_a');
set local role authenticated;
select throws_ok($$insert into coaching_sessions (coach_id, scheduled_at) values (auth.uid(), now())$$, '42501', null,
  'Coach legt keine Session an');
select throws_ok(format('insert into session_students (session_id, student_id) values (%L, %L)', :'s', :'k7'), '42501', null,
  'Coach bucht kein Kind');
select is((select count(*)::int from coaching_sessions where id = :'s'), 1, 'Coach liest seine Session weiter');
reset role;
select is((select count(*)::int from (select 1 from session_students where session_id = :'s') x), 6, 'Buchungen unveraendert');
select pg_temp.act_as(:'coach_a');
set local role authenticated;
update session_students set attendance = 'present' where session_id = :'s' and student_id = :'k6';
reset role;
select is((select attendance from session_students where session_id = :'s' and student_id = :'k6'), 'planned',
  'Coach aendert die Anwesenheit nicht direkt');
select is((anwesenheit_setzen(:'s', :'k6', 'unexcused')).attendance, 'unexcused', 'anwesenheit_setzen: Coach setzt nicht erschienen');
select throws_ok(format($$select anwesenheit_setzen(%L, %L, 'cancelled')$$, :'s', :'k6'), '22023', null,
  'anwesenheit_setzen: Coach sagt nicht ab');
select pg_temp.act_as(:'admin');
select anwesenheit_setzen(:'s', :'k6', 'cancelled');
select pg_temp.act_as(:'coach_a');
select throws_ok(format($$select anwesenheit_setzen(%L, %L, 'present')$$, :'s', :'k6'), '42501', null,
  'anwesenheit_setzen: abgesagte Buchung aendert nur ein Admin');
select pg_temp.act_as(:'coach_b');
select throws_ok(format($$select anwesenheit_setzen(%L, %L, 'present')$$, :'s', :'k1'), '42501', null,
  'anwesenheit_setzen: fremder Coach abgelehnt');
select pg_temp.act_as(:'admin');
select anwesenheit_setzen(:'s', :'k6', 'planned');
select pg_temp.act_as(:'coach_a');

-- ── 11) Abschluss ──────────────────────────────────────────────────────────
select throws_ok(format($$select abschluss_setzen(%L, %L, p_notiz => 'braucht Therapie')$$, :'s', :'k1'), '22023', null,
  '11 Gesundheitsangabe in der Notiz abgelehnt');
select abschluss_setzen(:'s', :'k1', 'Du rechnest die Kathete fast allein.', true, 'Arbeitet zuegig.', true, false);
select pg_temp.act_as(pg_temp.tablet(1));
select throws_ok(format($$select quest_termin_setzen(%L, null, now() + interval '15 days')$$, :'s'), '22023', null,
  '11 Quest-Termin hoechstens 14 Tage');
select lives_ok(format($$select quest_termin_setzen(%L, null, now() + interval '2 days')$$, :'s'), '11 Quest-Termin vom Tablet');
select pg_temp.act_as(:'coach_a');
select session_abschliessen(:'s') as ab \gset
select results_eq(format($$select student_id, attendance from session_students where session_id = %L
  and student_id in (%L, %L) order by attendance$$, :'s', :'k1', :'k6'),
  format($$values (%L::uuid, 'present'::text), (%L::uuid, 'unexcused')$$, :'k1', :'k6'),
  '11 Anwesenheit final (anwesend / nicht erschienen)');
select is(((:'ab'::jsonb) ->> 'einheit_verbraucht')::int, 6, '11 sechs Einheiten verbraucht (einheit_verbraucht)');
select results_eq(format($$select kategorie, text from schueler_notizen where student_id = %L order by kategorie$$, :'k1'),
  format($$values ('lernen'::text, 'Arbeitet zuegig.'::text), ('organisatorisch', 'Session %s: Elternkontakt nötig')$$,
         to_char(now() at time zone 'Europe/Berlin', 'DD.MM.YYYY')),
  '11 Notiz und Flag in der Akte');
select is((select status from coaching_sessions where id = :'s'), 'done', '11 Status abgeschlossen');
select is((select count(*)::int from session_tablets where session_id = :'s' and geloest_am is null), 0, '11 Tablets frei');
select pg_temp.act_as(:'admin');
select results_eq('select student_id, flag from session_flags_offen()',
  format($$values (%L::uuid, 'eltern'::text)$$, :'k1'), '11 offenes Flag fuer die Admin-Startseite');

-- ── Loeschregel (wie E1): Session restrict, Kind cascade ────────────────────
select results_eq($$
  select c.conrelid::regclass::text, c.confrelid::regclass::text, c.confdeltype::text
    from pg_constraint c
   where c.contype = 'f' and c.confrelid in ('coaching_sessions'::regclass, 'students'::regclass)
     and c.conrelid::regclass::text in ('session_ereignisse', 'session_tablets', 'session_checkin',
                                        'session_ausgegeben', 'session_antworten', 'session_kind_abschluss')
   order by 1, 2$$,
  $$values ('session_antworten', 'coaching_sessions', 'r'), ('session_antworten', 'students', 'c'),
           ('session_ausgegeben', 'coaching_sessions', 'r'), ('session_ausgegeben', 'students', 'c'),
           ('session_checkin', 'coaching_sessions', 'r'), ('session_checkin', 'students', 'c'),
           ('session_ereignisse', 'coaching_sessions', 'r'), ('session_ereignisse', 'students', 'c'),
           ('session_kind_abschluss', 'coaching_sessions', 'r'), ('session_kind_abschluss', 'students', 'c'),
           ('session_tablets', 'coaching_sessions', 'r'), ('session_tablets', 'students', 'c')$$,
  'Loeschregel: Lernverlauf an der Session restrict, am Kind cascade');
-- restrict meldet Postgres 18 als 23001, Postgres 16 (CI) als 23503; die Meldung ist gleich.
select throws_like(format('delete from coaching_sessions where id = %L', :'s'), '%violates%foreign key constraint%',
  'Loeschregel: auch ein Admin loescht keine Session mit Verlauf');
select throws_ok(format('delete from session_students where session_id = %L and student_id = %L', :'s', :'k3'), '23503', null,
  'Loeschregel: eine Buchung mit Verlauf bleibt');
delete from vertraege where student_id = :'k3';
delete from students where id = :'k3';
select is((select count(*)::int from session_antworten where student_id = :'k3')
        + (select count(*)::int from session_ereignisse where student_id = :'k3')
        + (select count(*)::int from session_kind_abschluss where student_id = :'k3'), 0,
  'Loeschregel: Loeschen des Kindes nimmt seinen Verlauf mit');
select ok((select count(*) from session_antworten where session_id = :'s') > 0
          and exists (select 1 from coaching_sessions where id = :'s'),
  'Loeschregel: der Verlauf der anderen Kinder und die Session bleiben');

select * from finish();
rollback;
