-- ============================================================================
-- Reihe 1 · Bauauftrag B1 — Studio-Datenmodell und studio_skript_speichern.
--
-- Zusagen:
--   1) Ein Autor speichert ein Skript: Beats, Texte je Welt, Beat-Bereiche je Kernidee,
--      fehlende Kernideen im E1-Modell, Mini-Check als MC-Check-Aufgabe mit known_errors,
--      Rücksprünge, Verknüpfung in erklaer_check.
--   2) Ohne Autor-Rolle, fremde Sequenz, Fehlbild außerhalb des Katalogs: abgelehnt.
--   3) Versionen steigen nur bei geändertem Inhalt, je Welt getrennt; gesperrte Welten bleiben gespeichert.
--   4) Eine Kernidee liegt in höchstens einem Video.
--   5) Kinder lesen keine Studio-Tabellen.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(28);

\set autor 'b1b1b1b1-0001-4000-8000-000000000001'
\set autor2 'b1b1b1b1-0001-4000-8000-000000000002'
\set coach 'b1b1b1b1-0001-4000-8000-000000000003'
\set kind 'b1b1b1b1-0001-4000-8000-000000000004'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'autor', 'b1-autor@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'autor2', 'b1-autor2@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach', 'b1-coach@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'kind', 'b1-kind@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values
  (:'autor', 'b1-autor@test.local', 'coach', 'B1 Autor'),
  (:'autor2', 'b1-autor2@test.local', 'coach', 'B1 Autor 2'),
  (:'coach', 'b1-coach@test.local', 'coach', 'B1 Coach'),
  (:'kind', 'b1-kind@test.local', 'student', 'B1 Kind');
insert into studio_rolle (person_id, rolle) values (:'autor', 'autor'), (:'autor2', 'autor');
insert into skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe) values
  ('zz_b1_wurzel', 'B1 Wurzel', 'mathematik', 8, 1), ('zz_b1_zwei', 'B1 Zwei', 'mathematik', 8, 1);
insert into fehlbild_labels (slug, klartext) values
  ('zz_b1_haelfte', 'Hälfte'), ('zz_b1_umfang', 'Umfang'), ('zz_b1_quadriert', 'Quadriert')
  on conflict do nothing;

create function pg_temp.als(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;

create function pg_temp.skript(p_musik_b3 text default 'Die Bühne hat also neunundvierzig Platten.',
                               p_skelett_b5 text default 'Zählen wir nach: eins, zwei, drei, vier, fünf, sechs, sieben.',
                               p_fehlbild text default 'zz_b1_haelfte',
                               p_skill text default 'zz_b1_wurzel',
                               p_frage text default 'Ein Quadrat hat 64 Kästchen. Wie lang ist eine Seite?',
                               p_richtig2 boolean default false) returns jsonb
language sql as $$
  select jsonb_build_object(
    'skill_key', p_skill, 'titel', 'Was die Wurzel bedeutet',
    'welten', jsonb_build_array('skelett', 'fussball', 'musik'),
    'beats', jsonb_build_array(
      jsonb_build_object('id', 'b1', 'titel', 'Worum es geht', 'kernidee', 'k1', 'baustein', 'titelkarte',
        'params', jsonb_build_object('titel', 'Quadratwurzeln'),
        'text', jsonb_build_object('skelett', 'Quadratwurzeln.')),
      jsonb_build_object('id', 'b3', 'titel', 'Die Fläche ist 49', 'kernidee', 'k1', 'baustein', 'raster',
        'params', jsonb_build_object('zeilen', 7, 'spalten', 7),
        'text', jsonb_build_object('skelett', 'Seine Fläche ist also neunundvierzig.',
                                   'fussball', 'Das Feld ist also neunundvierzig Platten groß.',
                                   'musik', p_musik_b3),
        'bild', jsonb_build_object('fussball', jsonb_build_object('einheit', 'Platten'))),
      jsonb_build_object('id', 'b5', 'titel', 'Seite zählen', 'kernidee', 'k1', 'baustein', 'raster',
        'params', jsonb_build_object('zeilen', 7, 'spalten', 7),
        'text', jsonb_build_object('skelett', p_skelett_b5)),
      jsonb_build_object('id', 'b8', 'titel', 'Heben sich auf', 'kernidee', 'k2', 'baustein', 'term_zeile',
        'params', jsonb_build_object('terme', jsonb_build_array('3^2 = 9')),
        'text', jsonb_build_object('skelett', 'Drei hoch zwei ist neun.'))),
    'minichecks', jsonb_build_array(jsonb_build_object(
      'nach_beat', 'b5',
      'frage', jsonb_build_object('skelett', p_frage,
                                  'fussball', 'Ein Feld hat 64 Platten. Wie lang ist eine Seitenlinie?'),
      'optionen', jsonb_build_array(
        jsonb_build_object('antwort', '8', 'richtig', true, 'rueckmeldung', 'Genau.'),
        jsonb_build_object('antwort', '32', 'fehlbild', p_fehlbild, 'ruecksprung', 'b5', 'rueckmeldung', 'Die Hälfte.'),
        case when p_richtig2 then jsonb_build_object('antwort', '16', 'richtig', true, 'rueckmeldung', 'Auch?')
             else jsonb_build_object('antwort', '16', 'fehlbild', 'zz_b1_umfang', 'ruecksprung', 'b3', 'rueckmeldung', 'Umfang.') end,
        jsonb_build_object('antwort', '4096', 'fehlbild', 'zz_b1_quadriert', 'ruecksprung', 'b8', 'rueckmeldung', 'Quadriert.')),
      'zwillinge', jsonb_build_array(jsonb_build_object(
        'frage', jsonb_build_object('skelett', 'Ein Quadrat hat 81 Kästchen. Wie lang ist eine Seite?'),
        'optionen', jsonb_build_array(
          jsonb_build_object('antwort', '9', 'richtig', true, 'rueckmeldung', 'Genau.'),
          jsonb_build_object('antwort', '40,5', 'fehlbild', 'zz_b1_haelfte', 'ruecksprung', 'b5', 'rueckmeldung', 'Hälfte.')))))))
$$;

-- 1) Speichern als Autor
select pg_temp.als(:'autor');
set local role authenticated;
select lives_ok($$ select set_config('b1.seq', public.studio_skript_speichern(null, pg_temp.skript(), '{"gesperrteWelten":[]}')::text, true) $$,
  'Autor speichert ein Skript');
reset role;
select is((select count(*)::int from studio_beat where sequenz_id = current_setting('b1.seq')::uuid), 4, 'vier Beats');
select is((select count(*)::int from studio_beat_text t join studio_beat b on b.id = t.beat_id
            where b.sequenz_id = current_setting('b1.seq')::uuid), 6, 'Texte je Welt (fehlende Welt = Skelett)');
select is((select string_agg(k.nr || ':' || r.von_beat || '-' || r.bis_beat, ',' order by k.nr) from studio_bereich r
             join erklaer_kernidee k on k.id = r.kernidee_id where r.sequenz_id = current_setting('b1.seq')::uuid),
          '1:b1-b5,2:b8-b8', 'Beat-Bereiche je Kernidee');
select is((select count(*)::int from erklaer_kernidee where skill_key = 'zz_b1_wurzel' and quelle = 'mensch' and status = 'entwurf'),
          2, 'fehlende Kernideen als Entwurf angelegt');
select is((select count(*)::int from studio_minicheck_aufgabe a join studio_minicheck m on m.id = a.minicheck_id
            where m.sequenz_id = current_setting('b1.seq')::uuid), 2, 'Hauptfrage und Zwilling je eine Aufgabe');
select is((select t.input_type || '/' || t.status || '/' || array_to_string(t.einsatz, ',') from tasks t
             join studio_minicheck_aufgabe a on a.task_id = t.id and a.nr = 0
             join studio_minicheck m on m.id = a.minicheck_id where m.sequenz_id = current_setting('b1.seq')::uuid),
          'MC/draft/check', 'Check-Aufgabe: MC, Entwurf, nur Einsatz check');
select is((select s.acceptance from task_solutions s join studio_minicheck_aufgabe a on a.task_id = s.task_id and a.nr = 0
             join studio_minicheck m on m.id = a.minicheck_id where m.sequenz_id = current_setting('b1.seq')::uuid),
          '{"canonical": "a", "known_errors": {"b": "zz_b1_haelfte", "c": "zz_b1_umfang", "d": "zz_b1_quadriert"}}'::jsonb,
          'Fehlbilder als known_errors');
select is((select count(*)::int from erklaer_check c join studio_minicheck_aufgabe a on a.task_id = c.task_id and a.nr = 0), 1,
          'Hauptfrage im E1-Modell verknüpft');
select is((select count(*)::int from erklaer_check c join studio_minicheck_aufgabe a on a.task_id = c.task_id and a.nr = 1), 0,
          'Zwilling nicht als eigener E1-Check');
select is((select string_agg(r.fehlbild_key || '>' || b.beat_key, ',' order by r.fehlbild_key) from studio_ruecksprung r
             join studio_beat b on b.id = r.beat_id),
          'zz_b1_haelfte>b5,zz_b1_quadriert>b8,zz_b1_umfang>b3', 'Rücksprünge je Fehlbild');

-- 3) Versionen
select pg_temp.als(:'autor');
set local role authenticated;
select lives_ok($$ select public.studio_skript_speichern(current_setting('b1.seq')::uuid, pg_temp.skript(), '{}') $$,
  'unverändert erneut speichern');
reset role;
select is((select version from studio_sequenz where id = current_setting('b1.seq')::uuid), 1::bigint, 'unverändert: Version bleibt');
select is((select count(*)::int from tasks where source = 'edvance_studio'), 2, 'unverändert: keine neuen Check-Aufgaben');
set local role authenticated;
select lives_ok($$ select public.studio_skript_speichern(current_setting('b1.seq')::uuid,
  pg_temp.skript('Die Bühne hat also fünfzig Platten.'), '{"gesperrteWelten":["musik"],"befunde":[{"stufe":"welt","code":"zahlen_sperre","welt":"musik","beat":"b3"}]}') $$,
  'Musik-Text geändert');
reset role;
select results_eq($$ select welt || ':' || version || ':' || gesperrt from studio_welt
                      where sequenz_id = current_setting('b1.seq')::uuid order by welt $$,
  array['fussball:1:false', 'musik:2:true', 'skelett:1:false'], 'nur die Musik-Welt steigt und ist gesperrt');
select is((select version from studio_sequenz where id = current_setting('b1.seq')::uuid), 1::bigint, 'Skelett bleibt');
set local role authenticated;
select lives_ok($$ select public.studio_skript_speichern(current_setting('b1.seq')::uuid,
  pg_temp.skript(p_skelett_b5 => 'Wir zählen: eins, zwei, drei, vier, fünf, sechs, sieben.'), '{}') $$, 'Skelett-Satz geändert');
reset role;
select is((select version from studio_sequenz where id = current_setting('b1.seq')::uuid), 2::bigint, 'Skelett-Version steigt');

-- Geänderte Frage: neue Aufgabe, die alte verliert ihre E1-Verknüpfung
select pg_temp.als(:'autor');
set local role authenticated;
select lives_ok($$ select public.studio_skript_speichern(current_setting('b1.seq')::uuid,
  pg_temp.skript(p_skelett_b5 => 'Wir zählen: eins, zwei, drei, vier, fünf, sechs, sieben.',
                 p_frage => 'Ein Quadrat hat 64 Kästchen. Wie viele liegen an einer Seite?'), '{}') $$, 'Frage geändert');
reset role;
select is((select count(*)::int from erklaer_check c join erklaer_kernidee k on k.id = c.kernidee_id
            where k.skill_key = 'zz_b1_wurzel'), 1, 'nur die aktuelle Fassung hängt im E1-Modell');

-- 2) Ablehnungen
select pg_temp.als(:'coach');
set local role authenticated;
select throws_ok($$ select public.studio_skript_speichern(null, pg_temp.skript(), '{}') $$, '42501', null,
  'ohne Autor-Rolle abgelehnt');
reset role;
select pg_temp.als(:'autor2');
set local role authenticated;
select throws_ok($$ select public.studio_skript_speichern(current_setting('b1.seq')::uuid, pg_temp.skript(), '{}') $$,
  '42501', null, 'fremde Sequenz abgelehnt');
select throws_like($$ select public.studio_skript_speichern(null, pg_temp.skript(p_fehlbild => 'zz_b1_gibt_es_nicht', p_skill => 'zz_b1_zwei'), '{}') $$,
  '%fehlt im Katalog%', 'Fehlbild außerhalb des Katalogs abgelehnt');
select throws_like($$ select public.studio_skript_speichern(null, pg_temp.skript(p_skill => 'zz_b1_zwei', p_richtig2 => true), '{}') $$,
  '%genau eine richtige%', 'zwei richtige Antworten abgelehnt');
-- 4) Kernidee schon belegt
select throws_ok($$ select public.studio_skript_speichern(null, pg_temp.skript(), '{}') $$, '23505', null,
  'Kernidee liegt schon in einem anderen Video');
reset role;

-- 5) Kinder lesen nichts
select pg_temp.als(:'kind');
set local role authenticated;
select is((select count(*)::int from studio_sequenz), 0, 'Kind sieht keine Sequenz');
select is((select count(*)::int from studio_beat_text), 0, 'Kind sieht keine Texte');
reset role;

select * from finish();
rollback;
