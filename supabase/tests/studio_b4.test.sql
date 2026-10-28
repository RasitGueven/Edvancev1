-- ============================================================================
-- Reihe 1 · Bauauftrag B4 — Render-Aufträge.
--
-- Zusagen:
--   1) Ein fertiger Render ist aktuell, bis sich Text, Baustein oder Stimme ändern („Render veraltet“).
--   2) Eine Welt-Änderung macht nur diese Welt veraltet.
--   3) Status nur vorwärts; fertig nur mit vollständigem Ergebnis unter dem richtigen Pfad.
--   4) Anlegen und Melden nur Autor/Admin; gesperrte Welten werden nicht gerendert.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(15);

\set autor 'b4b4b4b4-0001-4000-8000-000000000001'
\set coach 'b4b4b4b4-0001-4000-8000-000000000002'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'autor', 'b4-autor@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach', 'b4-coach@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values
  (:'autor', 'b4-autor@test.local', 'coach', 'B4 Autor'), (:'coach', 'b4-coach@test.local', 'coach', 'B4 Coach');
insert into studio_rolle (person_id, rolle) values (:'autor', 'autor');
insert into skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe) values ('zz_b4', 'B4', 'mathematik', 8, 1);

create function pg_temp.als(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;
create function pg_temp.skript(p_skelett text, p_fussball text) returns jsonb language sql as $$
  select jsonb_build_object('skill_key', 'zz_b4', 'titel', 'B4', 'welten', jsonb_build_array('skelett', 'fussball'),
    'beats', jsonb_build_array(jsonb_build_object('id', 'b1', 'titel', 'Eins', 'kernidee', 'k1', 'baustein', 'merksatz',
      'params', jsonb_build_object('text', 'x'), 'text', jsonb_build_object('skelett', p_skelett, 'fussball', p_fussball))),
    'minichecks', '[]'::jsonb)
$$;
create function pg_temp.ergebnis(p_id uuid) returns jsonb language sql as $$
  select jsonb_build_object('mp4', b || 'v.mp4', 'untertitel', b || 'untertitel.vtt', 'poster', b || 'poster.jpg',
                            'kapitel', '[{"beat":"b1","start":0,"titel":"Eins"}]'::jsonb, 'dauer_ms', 1500)
    from (select 'render/' || sequenz_id || '/' || welt || '/' || fingerabdruck || '/' || id || '/' as b
            from studio_render where id = p_id) x
$$;
-- Dateien wie nach dem Hochladen (die Tests laufen als Superuser in den Bucket).
create function pg_temp.hochladen(p_id uuid) returns void language sql as $$
  insert into storage.objects (bucket_id, name)
  select 'studio', e.value from jsonb_each_text(pg_temp.ergebnis(p_id)) e where e.key in ('mp4', 'untertitel', 'poster')
$$;

select pg_temp.als(:'autor');
set local role authenticated;
select set_config('b4.seq', public.studio_skript_speichern(null, pg_temp.skript('Ein Satz.', 'Ein Satz am Platz.'), '{}')::text, true) is not null as angelegt;
select set_config('b4.r1', public.studio_render_anlegen(current_setting('b4.seq')::uuid, 'skelett', 'lokal')::text, true) is not null as r1;
select set_config('b4.r2', public.studio_render_anlegen(current_setting('b4.seq')::uuid, 'fussball', 'lokal')::text, true) is not null as r2;
select throws_ok($$ select public.studio_render_melden(current_setting('b4.r1')::uuid, 'fertig', pg_temp.ergebnis(current_setting('b4.r1')::uuid)) $$,
  '22023', null, 'wartet → fertig nicht erlaubt');
select throws_ok($$ select public.studio_render_anlegen(current_setting('b4.seq')::uuid, 'skelett', 'lokal') $$, '23505', null,
  'je Welt nur ein laufender Auftrag');
select lives_ok($$ select public.studio_render_melden(current_setting('b4.r1')::uuid, 'laeuft') $$, 'wartet → läuft');
select throws_ok($$ select public.studio_render_melden(current_setting('b4.r1')::uuid, 'fertig', '{}') $$, '22023', null,
  'fertig ohne Ergebnis abgelehnt');
select throws_like($$ select public.studio_render_melden(current_setting('b4.r1')::uuid, 'fertig', pg_temp.ergebnis(current_setting('b4.r1')::uuid)) $$,
  '%Dateien fehlen%', 'fertig ohne Dateien im Bucket abgelehnt');
reset role;
select pg_temp.hochladen(current_setting('b4.r1')::uuid);
select pg_temp.hochladen(current_setting('b4.r2')::uuid);
set local role authenticated;
select throws_ok($$ select public.studio_render_melden(current_setting('b4.r1')::uuid, 'fertig',
  jsonb_set(pg_temp.ergebnis(current_setting('b4.r1')::uuid), '{mp4}', '"render/anderswo/v.mp4"')) $$, '22023', null,
  'fremder Pfad abgelehnt');
select lives_ok($$ select public.studio_render_melden(current_setting('b4.r1')::uuid, 'fertig', pg_temp.ergebnis(current_setting('b4.r1')::uuid)) $$,
  'läuft → fertig');
select lives_ok($$ select public.studio_render_melden(current_setting('b4.r2')::uuid, 'laeuft') $$, 'Fußball läuft');
select lives_ok($$ select public.studio_render_melden(current_setting('b4.r2')::uuid, 'fertig', pg_temp.ergebnis(current_setting('b4.r2')::uuid)) $$,
  'Fußball fertig');
select throws_ok($$ select public.studio_render_melden(current_setting('b4.r1')::uuid, 'laeuft') $$, '22023', null,
  'fertig ist endgültig');
select results_eq($$ select welt || ':' || aktuell from public.studio_render_stand(current_setting('b4.seq')::uuid) $$,
  array['skelett:true', 'fussball:true'], 'beide Renders aktuell');
-- Nur der Fußball-Satz ändert sich
select public.studio_skript_speichern(current_setting('b4.seq')::uuid, pg_temp.skript('Ein Satz.', 'Ein Satz im Stadion.'), '{}') is not null as geaendert;
select results_eq($$ select welt || ':' || aktuell from public.studio_render_stand(current_setting('b4.seq')::uuid) $$,
  array['skelett:true', 'fussball:false'], 'Welt-Änderung: nur Fußball veraltet');
-- Skelett-Satz ändert sich: alles veraltet
select public.studio_skript_speichern(current_setting('b4.seq')::uuid, pg_temp.skript('Ein anderer Satz.', 'Ein Satz im Stadion.'), '{}') is not null as geaendert2;
select results_eq($$ select welt || ':' || aktuell from public.studio_render_stand(current_setting('b4.seq')::uuid) $$,
  array['skelett:false', 'fussball:false'], 'Skelett-Änderung: alle veraltet');
reset role;
update studio_welt set gesperrt = true where sequenz_id = current_setting('b4.seq')::uuid and welt = 'fussball';
set local role authenticated;
select throws_ok($$ select public.studio_render_anlegen(current_setting('b4.seq')::uuid, 'fussball') $$, '22023', null,
  'gesperrte Welt wird nicht gerendert');
reset role;
select pg_temp.als(:'coach');
set local role authenticated;
select throws_ok($$ select public.studio_render_anlegen(current_setting('b4.seq')::uuid, 'skelett') $$, '42501', null,
  'ohne Autor-Rolle kein Auftrag');
reset role;

select * from finish();
rollback;
