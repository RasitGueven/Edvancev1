-- ============================================================================
-- Reihe 1 · Bauauftrag B2 — Stimme: Fingerabdruck, Bedarf, Eintragen.
--
-- Zusagen:
--   1) Eine Welt ohne eigenen Satz hat denselben Fingerabdruck wie das Skelett (übernimmt die Datei).
--   2) Ein eingetragener, unveränderter Satz gilt als vorhanden und wird nicht neu verlangt.
--   3) Nur der geänderte Satz wird wieder fällig.
--   4) Platzhalter und echte Stimme haben verschiedene Fingerabdrücke.
--   5) Das Wörterbuch ändert die gesprochene Fassung.
--   6) Eintragen nur Autor/Admin; Stimme setzen nur Admin.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(15);

\set autor 'b2b2b2b2-0001-4000-8000-000000000001'
\set coach 'b2b2b2b2-0001-4000-8000-000000000002'
\set admin 'b2b2b2b2-0001-4000-8000-000000000003'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'autor', 'b2-autor@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach', 'b2-coach@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'admin', 'b2-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values
  (:'autor', 'b2-autor@test.local', 'coach', 'B2 Autor'),
  (:'coach', 'b2-coach@test.local', 'coach', 'B2 Coach'),
  (:'admin', 'b2-admin@test.local', 'admin', 'B2 Admin');
insert into studio_rolle (person_id, rolle) values (:'autor', 'autor');
insert into skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe) values ('zz_b2', 'B2', 'mathematik', 8, 1);

create function pg_temp.als(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;
create function pg_temp.skript(p_b2 text) returns jsonb language sql as $$
  select jsonb_build_object('skill_key', 'zz_b2', 'titel', 'B2', 'welten', jsonb_build_array('skelett', 'fussball'),
    'beats', jsonb_build_array(
      jsonb_build_object('id', 'b1', 'titel', 'Eins', 'kernidee', 'k1', 'baustein', 'titelkarte',
        'params', jsonb_build_object('titel', 'B2'), 'text', jsonb_build_object('skelett', 'Los geht es.')),
      jsonb_build_object('id', 'b2', 'titel', 'Zwei', 'kernidee', 'k1', 'baustein', 'merksatz',
        'params', jsonb_build_object('text', 'x'),
        'text', jsonb_build_object('skelett', p_b2, 'fussball', 'Auf dem Platz sind es sieben.'))),
    'minichecks', '[]'::jsonb)
$$;

select pg_temp.als(:'autor');
set local role authenticated;
select set_config('b2.seq', public.studio_skript_speichern(null, pg_temp.skript('Es sind sieben.'), '{}')::text, true);
reset role;

select is((select count(distinct fingerabdruck)::int from studio_stimme_bedarf(current_setting('b2.seq')::uuid)
            where beat_key = 'b1'), 1, 'Welt ohne eigenen Satz: derselbe Fingerabdruck wie das Skelett');
select is((select count(distinct fingerabdruck)::int from studio_stimme_bedarf(current_setting('b2.seq')::uuid)
            where beat_key = 'b2'), 2, 'eigener Welt-Satz: eigener Fingerabdruck');
select is((select davor || ' | ' || coalesce(danach, '-') from studio_stimme_bedarf(current_setting('b2.seq')::uuid)
            where beat_key = 'b2' and welt = 'skelett'), 'Los geht es. | -', 'Kontext: Satz davor und danach');
select isnt(public.studio_fingerabdruck('platzhalter', 'm', 'Satz'), public.studio_fingerabdruck('v1', 'm', 'Satz'),
            'Platzhalter und echte Stimme unterscheiden sich');

-- Alles eintragen (wie die Route), dann ist nichts mehr fällig.
set local role authenticated;
select lives_ok($$ select public.studio_audio_eintragen(fingerabdruck, 'audio/' || fingerabdruck || '.wav', 'platzhalter',
                     'eleven_multilingual_v2', 1000, '{}', true)
                     from (select distinct fingerabdruck from studio_stimme_bedarf(current_setting('b2.seq')::uuid)) x $$,
  'Autor trägt Audio ein');
select is((select count(*)::int from studio_stimme_bedarf(current_setting('b2.seq')::uuid) where not vorhanden), 0,
          'unverändert: nichts fällig');
select lives_ok($$ select public.studio_skript_speichern(current_setting('b2.seq')::uuid, pg_temp.skript('Es sind genau sieben.'), '{}') $$,
  'Skelett-Satz b2 geändert');
select results_eq($$ select beat_key || '/' || welt from studio_stimme_bedarf(current_setting('b2.seq')::uuid)
                      where not vorhanden order by 1 $$,
  array['b2/skelett'], 'nur der geänderte Satz ist fällig');
reset role;

-- Wörterbuch
select pg_temp.als(:'admin');
set local role authenticated;
select lives_ok($$ select public.studio_einstellung_setzen('aussprache', '[{"wort":"los","sprich":"Lohs"},{"wort":"es.","sprich":"es & so."}]') $$,
  'Admin setzt Wörterbuch');
select throws_ok($$ select public.studio_einstellung_setzen('aussprache', '[{"wort":"x"}]') $$, '22023', null,
  'Wörterbuch ohne Ersatz abgelehnt');
select throws_ok($$ select public.studio_einstellung_setzen('modell', 'null') $$, '22023', null, 'Modell null abgelehnt');
reset role;
select is((select satz from studio_stimme_bedarf(current_setting('b2.seq')::uuid) where beat_key = 'b1' and welt = 'skelett'),
          'Lohs geht es & so.', 'Wörterbuch: ganze Wörter, ohne Groß/Klein, Sonderzeichen im Ersatz bleiben');
-- Gesperrte Welt wird nicht vertont
update studio_welt set gesperrt = true where sequenz_id = current_setting('b2.seq')::uuid and welt = 'fussball';
select is((select count(*)::int from studio_stimme_bedarf(current_setting('b2.seq')::uuid) where welt = 'fussball'), 0,
          'gesperrte Welt wird nicht vertont');

select pg_temp.als(:'coach');
set local role authenticated;
select throws_ok($$ select public.studio_audio_eintragen(repeat('a', 64), 'x', 's', 'm', 1, '{}', false) $$, '42501', null,
  'ohne Autor-Rolle kein Eintragen');
select throws_ok($$ select public.studio_wert('stimme_id') $$, '42501', null, 'Einstellungen nicht über studio_wert lesbar');
reset role;

select * from finish();
rollback;
