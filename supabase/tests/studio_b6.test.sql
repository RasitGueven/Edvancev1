-- ============================================================================
-- Reihe 1 · Bauauftrag B6 — Ausspielung (Anforderung Studio §14 Fälle 6, 7, 9, 10).
--
--   6) Kind der Welt Fußball antwortet im Mini-Check 32: Rückmeldung, Sprung auf b5, danach dieselbe Frage mit anderen Zahlen.
--   7) Ist die Fußball-Variante nicht freigegeben, sieht das Fußball-Kind die Skelett-Fassung.
--   9) Mediathek zuhause: keine Mini-Checks, gespeichert wird höchstens „angesehen“.
--  10) Eddie verlinkt nie eine Sequenz im Entwurf.
-- kompetenz_offen (Auftrag D) ist hier eine Attrappe nur in dieser Testtransaktion.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(26);

\ir session_e1_fixture.sql

\set autor 'b6b6b6b6-0001-4000-8000-000000000001'
insert into auth.users (id, email, instance_id, aud, role) values
  (:'autor', 'b6-autor@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values (:'autor', 'b6-autor@test.local', 'coach', 'B6 Autor');
insert into studio_rolle (person_id, rolle) values (:'autor', 'autor');
insert into skills (skill_key, label, klasse_herkunft, fundament_tiefe) values
  ('zz_b6_wurzel', 'B6 Wurzel', 8, 1), ('zz_b6_entwurf', 'B6 Entwurf', 8, 1), ('zz_b6_zu', 'B6 gesperrt', 8, 1);
insert into fehlbild_labels (slug, klartext) values ('zz_b6_haelfte', 'Hälfte'), ('zz_b6_quadriert', 'Quadriert')
  on conflict do nothing;

create or replace function pg_temp.als(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;
create function pg_temp.skript(p_skill text) returns jsonb language sql as $$
  select jsonb_build_object('skill_key', p_skill, 'titel', 'Was die Wurzel bedeutet', 'welten', jsonb_build_array('skelett', 'fussball'),
    'beats', (select jsonb_agg(jsonb_build_object('id', 'b' || i, 'titel', 'Beat ' || i, 'kernidee', 'k1', 'baustein', 'merksatz',
                'params', jsonb_build_object('text', 'x'),
                'text', jsonb_build_object('skelett', 'Satz ' || i || '.', 'fussball', 'Am Platz ' || i || '.')) order by i)
                from generate_series(1, 7) i),
    'minichecks', jsonb_build_array(jsonb_build_object('nach_beat', 'b7',
      'frage', jsonb_build_object('skelett', 'Ein Quadrat hat 64 Kästchen. Wie lang ist eine Seite?',
                                  'fussball', 'Ein Feld hat 64 Platten. Wie lang ist eine Seitenlinie?'),
      'optionen', jsonb_build_array(
        jsonb_build_object('antwort', '8', 'richtig', true, 'rueckmeldung', 'Genau.'),
        jsonb_build_object('antwort', '32', 'fehlbild', 'zz_b6_haelfte', 'ruecksprung', 'b5', 'rueckmeldung', '32 ist die Hälfte von 64.'),
        jsonb_build_object('antwort', '4096', 'fehlbild', 'zz_b6_quadriert', 'rueckmeldung', 'Das ist quadriert.')),
      'zwillinge', jsonb_build_array(jsonb_build_object(
        'frage', jsonb_build_object('skelett', 'Ein Quadrat hat 81 Kästchen. Wie lang ist eine Seite?',
                                    'fussball', 'Ein Feld hat 81 Platten. Wie lang ist eine Seitenlinie?'),
        'optionen', jsonb_build_array(jsonb_build_object('antwort', '9', 'richtig', true, 'rueckmeldung', 'Genau.'),
          jsonb_build_object('antwort', '40,5', 'fehlbild', 'zz_b6_haelfte', 'ruecksprung', 'b5', 'rueckmeldung', 'Hälfte.')))))))
$$;
-- Freigabe wie nach B5, ohne den Prüfweg (der ist in studio_b5 getestet): Render fertig, Ausgabe, Aufgaben ready.
create function pg_temp.ausgeben(p_seq uuid, p_welt text) returns void language plpgsql as $$
declare r public.studio_render;
begin
  insert into public.studio_render (sequenz_id, welt, fingerabdruck, status, mp4, kapitel, untertitel, poster, dauer_ms,
                                    angelegt_von, fertig_am)
  values (p_seq, p_welt, repeat('a', 64), 'fertig', 'render/' || p_welt || '.mp4',
          (select jsonb_agg(jsonb_build_object('beat', 'b' || i, 'start', (i - 1) * 2.5, 'titel', 'Beat ' || i) order by i)
             from generate_series(1, 7) i),
          'render/' || p_welt || '.vtt', 'render/' || p_welt || '.jpg', 17500,
          (select autor_id from public.studio_sequenz where id = p_seq), now())
  returning * into r;
  insert into public.studio_ausgabe (sequenz_id, welt, render_id, version_skelett, version_welt, inhalt)
  values (p_seq, p_welt, r.id, public.studio_version(p_seq, 'skelett'), public.studio_version(p_seq, p_welt),
          public.studio_ausgabe_inhalt(p_seq, p_welt, r));
  update public.tasks t set status = 'ready' from public.studio_minicheck_aufgabe a join public.studio_minicheck m on m.id = a.minicheck_id
   where m.sequenz_id = p_seq and t.id = a.task_id;
end $$;

select pg_temp.als(:'autor');
set local role authenticated;
select set_config('b6.seq', public.studio_skript_speichern(null, pg_temp.skript('zz_b6_wurzel'), '{}')::text, true) is not null as s1;
select set_config('b6.entwurf', public.studio_skript_speichern(null, pg_temp.skript('zz_b6_entwurf'), '{}')::text, true) is not null as s2;
reset role;
select pg_temp.ausgeben(current_setting('b6.seq')::uuid, 'skelett');
select set_config('b6.check1', (select a.task_id::text from studio_minicheck_aufgabe a join studio_minicheck m on m.id = a.minicheck_id
  where m.sequenz_id = current_setting('b6.seq')::uuid and a.nr = 0), true) is not null as c1;
select set_config('b6.check2', (select a.task_id::text from studio_minicheck_aufgabe a join studio_minicheck m on m.id = a.minicheck_id
  where m.sequenz_id = current_setting('b6.seq')::uuid and a.nr = 1), true) is not null as c2;

-- Fall 7: Kind in der Welt Fußball, Fußball nicht freigegeben → Skelett
select pg_temp.als(:'kind_uid');
set local role authenticated;
select lives_ok(format($$ select public.studio_welt_setzen(%L, 'fussball') $$, :'kind_id'), 'Kind wählt Fußball');
create temp table b6_a (fall text, a jsonb);
insert into b6_a select 'start7', public.erklaer_start(:'session_id', :'kind_id', 'zz_b6_wurzel');
select is((select a ->> 'aktion' from b6_a where fall = 'start7'), 'start', 'Video-Kernidee ohne Karten-Variante startet');
select is((select a -> 'video' ->> 'welt' from b6_a where fall = 'start7'), 'skelett', 'Fall 7: Fußball nicht freigegeben → Skelett');
select is((select a -> 'video' -> 'bereich' from b6_a where fall = 'start7'), '{"von": "b1", "bis": "b7"}'::jsonb, 'Beat-Bereich der Kernidee');
select is((select a -> 'check' ->> 'task_id' from b6_a where fall = 'start7'), current_setting('b6.check1'), 'Hauptfrage als Check');
select is((select a -> 'video' -> 'minichecks' -> 0 ->> 'nach_beat' from b6_a where fall = 'start7'), 'b7', 'Anker nach b7');
reset role;

-- Fall 6: Fußball freigegeben → Fußball-Video (Wiederaufnahme), 32 springt auf b5, danach andere Zahlen
select pg_temp.ausgeben(current_setting('b6.seq')::uuid, 'fussball');
select pg_temp.als(:'kind_uid');
set local role authenticated;
insert into b6_a select 'start6', public.erklaer_start(:'session_id', :'kind_id', 'zz_b6_wurzel');
select is((select a -> 'video' ->> 'welt' from b6_a where fall = 'start6'), 'fussball', 'Fall 6: Video der Welt des Kindes');
select is((select a -> 'check' -> 'aufgabe' ->> 'prompt' from b6_a where fall = 'start6'),
          'Ein Feld hat 64 Platten. Wie lang ist eine Seitenlinie?', 'Frage in der Welt des Kindes');
insert into b6_a select 'falsch', public.erklaer_check_abgeben(:'session_id', :'kind_id', current_setting('b6.check1')::uuid,
  jsonb_build_object('selected', jsonb_build_array('b')));
select is((select a ->> 'aktion' from b6_a where fall = 'falsch'), 'ruecksprung', 'Fall 6: Antwortart ruecksprung');
select is((select a -> 'ruecksprung' ->> 'beat' from b6_a where fall = 'falsch'), 'b5', 'Fall 6: Sprung auf b5');
select is((select a -> 'ruecksprung' ->> 'rueckmeldung' from b6_a where fall = 'falsch'), '32 ist die Hälfte von 64.', 'Fall 6: Rückmeldung');
select is((select a -> 'check' ->> 'task_id' from b6_a where fall = 'falsch'), current_setting('b6.check2'),
          'Fall 6: danach dieselbe Frage mit anderen Zahlen');
select is((select a -> 'check' -> 'aufgabe' ->> 'prompt' from b6_a where fall = 'falsch'),
          'Ein Feld hat 81 Platten. Wie lang ist eine Seitenlinie?', 'Zwilling in der Welt des Kindes');
-- Ohne Rücksprung zum Fehlbild: Signal nach erklaerrunden_bis_signal (Standard 2) wie bisher
insert into b6_a select 'signal', public.erklaer_check_abgeben(:'session_id', :'kind_id', current_setting('b6.check2')::uuid,
  jsonb_build_object('selected', jsonb_build_array('b')));
select is((select a ->> 'aktion' from b6_a where fall = 'signal'), 'signal', 'nach zwei falschen Runden Signal an den Coach');
reset role;

-- Fall 9 und 10: Mediathek und Eddie (Attrappe kompetenz_offen nur in dieser Transaktion)
create or replace function public.kompetenz_offen(p_kind uuid) returns table (skill_key text, zustand text, grund text)
language sql as $$ values ('zz_b6_wurzel', 'noch_nicht_sicher', 'aktuell'), ('zz_b6_entwurf', 'nicht_angeschaut', 'start') $$;
select pg_temp.als(:'kind_uid');
set local role authenticated;
select is((select count(*)::int from public.mediathek_kind(:'kind_id')), 1, 'Mediathek: nur Freigegebenes, nie der Entwurf');
select is((select welt || ' ' || mp4_url from public.mediathek_kind(:'kind_id')), 'fussball render/fussball.mp4', 'Mediathek: Welt des Kindes');
select ok(not exists (select 1 from information_schema.columns c where c.table_name = 'studio_angesehen'
                       and c.column_name not in ('student_id', 'sequenz_id', 'erstmals_am', 'zuletzt_am')),
          'Fall 9: gespeichert wird nur „angesehen“ (keine Antworten, keine Checks)');
select lives_ok(format($$ select public.mediathek_angesehen(%L, %L) $$, :'kind_id', current_setting('b6.seq')), 'Kind markiert angesehen');
select ok((select count(*) = 0 from public.mediathek_kind(:'kind_id') m where m.kapitel::text like '%task_id%'),
          'Fall 9: keine Mini-Checks in der Mediathek');
select is((select count(distinct sequenz_id)::int from public.eddie_index(:'kind_id')), 1, 'Fall 10: Eddie kennt nur Freigegebenes');
select ok(not exists (select 1 from public.eddie_index(:'kind_id') where sequenz_id = current_setting('b6.entwurf')::uuid),
          'Fall 10: Sequenz im Entwurf nie verlinkt');
reset role;
select pg_temp.als(:'coach_uid');
set local role authenticated;
select throws_ok(format($$ select public.mediathek_angesehen(%L, %L) $$, :'kind_id', current_setting('b6.seq')), '42501', null,
  'angesehen speichert nur das Kind selbst');
reset role;

-- Review B6: Kinder sehen nur die eingefrorene Ausgabe
select is(public.studio_datei_freigegeben('render/fussball.mp4'), true, 'freigegebene Datei lesbar');
select is(public.studio_datei_freigegeben('render/entwurf.mp4'), false, 'andere Datei im Bucket nicht');
-- Der Autor ändert den Entwurf (Kernidee k2 statt k1): die Ausgabe bleibt, das Kind merkt nichts.
select pg_temp.als(:'autor');
set local role authenticated;
select public.studio_skript_speichern(current_setting('b6.seq')::uuid,
  jsonb_set(pg_temp.skript('zz_b6_wurzel'), '{beats,6,kernidee}', '"k2"'), '{}') is not null as entwurf_geaendert;
reset role;
select is((public.studio_ausgabe_fuer((select id from erklaer_kernidee where skill_key = 'zz_b6_wurzel' and nr = 1), :'kind_id')).welt,
          'fussball', 'Entwurf ändert die ausgegebene Fassung nicht (Bereich aus der Ausgabe)');
-- Eine gemeldete (inaktive) Check-Aufgabe: kein Video-Check mehr, Kartenweg (hier ohne Karten → nichts)
update tasks set is_active = false where id in (current_setting('b6.check1')::uuid, current_setting('b6.check2')::uuid);
select is(public.studio_kernidee_hat_video((select id from erklaer_kernidee where skill_key = 'zz_b6_wurzel' and nr = 1)), false,
          'gemeldete Check-Aufgaben: keine Video-Kernidee mehr');

select * from finish();
rollback;
