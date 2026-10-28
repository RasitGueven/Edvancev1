-- ============================================================================
-- Reihe 1 · Bauauftrag B5 — Prüfung und Freigabe (Anforderung Studio §14 Fälle 4, 5, 8).
--
--   4) Der Autor kann seine eigene Sequenz nicht freigeben — die Datenbank lehnt es auch direkt ab.
--   5) „passt nicht“ an b2 schickt die Sequenz an den Autor zurück, der Kommentar steht an b2.
--   8) Nach einer Änderung an einer freigegebenen Sequenz bleibt die alte Ausgabe stehen, bis neu freigegeben ist.
--   Dazu: Freigabe nur mit Stimme und aktuellem Render; Welt erst mit Varianten-Freigabe; Mini-Checks werden ready.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(25);

\set autor 'b5b5b5b5-0001-4000-8000-000000000001'
\set gruender 'b5b5b5b5-0001-4000-8000-000000000002'
\set lena 'b5b5b5b5-0001-4000-8000-000000000003'
\set admin 'b5b5b5b5-0001-4000-8000-000000000004'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'autor', 'b5-autor@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'gruender', 'b5-gruender@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'lena', 'b5-lena@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'admin', 'b5-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name, darf_pruefen) values
  (:'autor', 'b5-autor@test.local', 'coach', 'B5 Autor', false),
  (:'gruender', 'b5-gruender@test.local', 'admin', 'B5 Gründer', false),
  (:'lena', 'b5-lena@test.local', 'coach', 'B5 Lena', true),
  (:'admin', 'b5-admin@test.local', 'admin', 'B5 Admin', false);
-- Der Autor ist auch Gründer und fachlich (wie Ashkan bzw. Rasit) — trotzdem prüft er sich nie selbst.
insert into studio_rolle (person_id, rolle) values
  (:'autor', 'autor'), (:'autor', 'gruender'), (:'autor', 'fachlich'), (:'gruender', 'gruender'), (:'lena', 'fachlich'),
  (:'admin', 'fachlich'), (:'admin', 'gruender');
insert into skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe) values ('zz_b5', 'B5', 'mathematik', 8, 1);
insert into fehlbild_labels (slug, klartext) values ('zz_b5_fb', 'B5') on conflict do nothing;
update studio_einstellung set wert = '"stimme_test"' where schluessel = 'stimme_id';

create function pg_temp.als(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;
create function pg_temp.skript(p_b2 text) returns jsonb language sql as $$
  select jsonb_build_object('skill_key', 'zz_b5', 'titel', 'B5', 'welten', jsonb_build_array('skelett', 'fussball'),
    'beats', jsonb_build_array(
      jsonb_build_object('id', 'b1', 'titel', 'Eins', 'kernidee', 'k1', 'baustein', 'titelkarte',
        'params', jsonb_build_object('titel', 'B5'), 'text', jsonb_build_object('skelett', 'Los geht es.')),
      jsonb_build_object('id', 'b2', 'titel', 'Zwei', 'kernidee', 'k1', 'baustein', 'merksatz',
        'params', jsonb_build_object('text', 'x'), 'text', jsonb_build_object('skelett', p_b2, 'fussball', 'Am Platz: sieben.'))),
    'minichecks', jsonb_build_array(jsonb_build_object('nach_beat', 'b2', 'frage', jsonb_build_object('skelett', 'Wie viel ist 7?'),
      'optionen', jsonb_build_array(jsonb_build_object('antwort', '7', 'richtig', true, 'rueckmeldung', 'Ja.'),
        jsonb_build_object('antwort', '8', 'fehlbild', 'zz_b5_fb', 'ruecksprung', 'b2', 'rueckmeldung', 'Nochmal.')))))
$$;
-- Hochgeladene Dateien (security definer: der Test schreibt als Superuser in den Bucket).
create function pg_temp.dateien(p_namen text[]) returns void language sql security definer as $$
  insert into storage.objects (bucket_id, name) select 'studio', n from unnest(p_namen) n
$$;
-- Stimme und Render wie nach „Fehlende erzeugen“ und einem fertigen Render (als Autor).
create function pg_temp.vertonen_und_rendern(p_seq uuid) returns void language plpgsql as $$
declare
  w text;
  r uuid;
  b text;
begin
  perform public.studio_audio_eintragen(x.fingerabdruck, 'audio/' || x.fingerabdruck || '.mp3', 'stimme_test', 'm', 1000, '{}', false)
    from (select distinct fingerabdruck from public.studio_stimme_bedarf(p_seq) where not vorhanden) x;
  foreach w in array array['skelett', 'fussball'] loop
    r := public.studio_render_anlegen(p_seq, w, 'lokal');
    select 'render/' || sequenz_id || '/' || welt || '/' || fingerabdruck || '/' || id || '/' into b from public.studio_render where id = r;
    perform public.studio_render_melden(r, 'laeuft');
    perform pg_temp.dateien(array[b || 'v.mp4', b || 'u.vtt', b || 'p.jpg']);
    perform public.studio_render_melden(r, 'fertig', jsonb_build_object('mp4', b || 'v.mp4', 'untertitel', b || 'u.vtt',
      'poster', b || 'p.jpg', 'kapitel', '[]'::jsonb, 'dauer_ms', 2700));
  end loop;
end $$;

select pg_temp.als(:'autor');
set local role authenticated;
select set_config('b5.seq', public.studio_skript_speichern(null, pg_temp.skript('Es sind sieben.'), '{}')::text, true) is not null as s;
select pg_temp.vertonen_und_rendern(current_setting('b5.seq')::uuid);
select lives_ok($$ select public.studio_einreichen(current_setting('b5.seq')::uuid) $$, 'Autor reicht ein');
-- Fall 4
select is((public.studio_freigabe_stand(current_setting('b5.seq')::uuid) -> 'darf' ->> 'fachlich')::boolean, false,
          'Fall 4: Knopf für den Autor gesperrt');
select throws_like($$ select public.studio_pruefen(current_setting('b5.seq')::uuid, 'fachlich', 'skelett', 'passt') $$,
  '%eigene Sequenz%', 'Fall 4: Datenbank lehnt Freigabe durch den Autor ab');
reset role;
select throws_like(format($$ insert into studio_freigabe (sequenz_id, art, person_id, ergebnis, version, fingerabdruck)
                             values (%L, 'fachlich', %L, 'passt', 1, 'x') $$, current_setting('b5.seq'), :'autor'),
  '%eigene Sequenz%', 'Fall 4: auch direkt in der Tabelle abgelehnt');

-- Wer bearbeitet hat, prüft nicht (Admin ändert fremdes Skript)
select pg_temp.als(:'admin');
set local role authenticated;
select lives_ok($$ select public.studio_skript_speichern(current_setting('b5.seq')::uuid, pg_temp.skript('Es sind sieben.'), '{}') $$,
  'Admin speichert die fremde Sequenz (unverändert)');
select throws_like($$ select public.studio_pruefen(current_setting('b5.seq')::uuid, 'fachlich', 'skelett', 'passt') $$,
  '%eigene Sequenz%', 'wer bearbeitet hat, prüft nicht');
reset role;
select throws_like(format($$ insert into studio_freigabe (sequenz_id, art, person_id, ergebnis, version, fingerabdruck)
                             values (%1$L, 'verstaendlich', %2$L, 'passt', 1, 'x'), (%1$L, 'fachlich', %2$L, 'passt', 1, 'x') $$,
                          current_setting('b5.seq'), :'lena'),
  '%zwei verschiedene Personen%', 'verständlich und fachlich nicht von derselben Person');

-- Fall 5
select pg_temp.als(:'lena');
set local role authenticated;
select lives_ok($$ select public.studio_pruefen(current_setting('b5.seq')::uuid, 'fachlich', 'skelett', 'passt_nicht', 'b2',
  'Sieben stimmt hier nicht.') $$, 'Lena: passt nicht an b2');
reset role;
select is((select status from studio_sequenz where id = current_setting('b5.seq')::uuid), 'entwurf', 'Fall 5: zurück an den Autor');
select is((select beat_key || ': ' || kommentar from studio_freigabe where sequenz_id = current_setting('b5.seq')::uuid
            and ergebnis = 'passt_nicht'), 'b2: Sieben stimmt hier nicht.', 'Fall 5: Kommentar steht an b2');

-- Wieder einreichen, beide Prüfungen → Skelett freigegeben, Welt noch nicht
select pg_temp.als(:'autor');
set local role authenticated;
select public.studio_einreichen(current_setting('b5.seq')::uuid);
reset role;
select pg_temp.als(:'gruender');
set local role authenticated;
select lives_ok($$ select public.studio_pruefen(current_setting('b5.seq')::uuid, 'verstaendlich', 'skelett', 'passt') $$,
  'Gründer bestätigt verständlich');
reset role;
select is((select count(*)::int from studio_ausgabe where sequenz_id = current_setting('b5.seq')::uuid), 0,
          'eine Freigabe allein gibt nichts aus');
select pg_temp.als(:'lena');
set local role authenticated;
select results_eq($$ select unnest(public.studio_pruefen(current_setting('b5.seq')::uuid, 'fachlich', 'skelett', 'passt')) $$,
  array['skelett'], 'fachlich passt: Skelett wird ausgegeben, Fußball noch nicht');
reset role;
select is((select status from studio_sequenz where id = current_setting('b5.seq')::uuid), 'freigegeben', 'Status freigegeben');
select is((select count(*)::int from tasks t join studio_minicheck_aufgabe a on a.task_id = t.id
             join studio_minicheck m on m.id = a.minicheck_id
            where m.sequenz_id = current_setting('b5.seq')::uuid and t.status = 'ready'), 1, 'Mini-Check-Aufgabe ready');
select is((select inhalt -> 'minichecks' -> 0 -> 'ruecksprung' -> 'zz_b5_fb' ->> 'beat' from studio_ausgabe
            where sequenz_id = current_setting('b5.seq')::uuid and welt = 'skelett'), 'b2', 'Ausgabe trägt den Rücksprung');
select pg_temp.als(:'lena');
set local role authenticated;
select results_eq($$ select unnest(public.studio_pruefen(current_setting('b5.seq')::uuid, 'variante', 'fussball', 'passt')) $$,
  array['fussball'], 'Varianten-Text Fußball freigegeben → Welt wird ausgegeben');
reset role;

-- Fall 8
select set_config('b5.render_alt', (select render_id::text from studio_ausgabe where sequenz_id = current_setting('b5.seq')::uuid
                                     and welt = 'skelett'), true) is not null as merken;
select pg_temp.als(:'autor');
set local role authenticated;
select lives_ok($$ select public.studio_skript_speichern(current_setting('b5.seq')::uuid, pg_temp.skript('Es sind genau sieben.'), '{}') $$,
  'Autor ändert einen Satz nach der Freigabe');
reset role;
select is((select status from studio_sequenz where id = current_setting('b5.seq')::uuid), 'entwurf', 'Fall 8: Sequenz wieder Entwurf');
select is((public.studio_freigabe_gueltig(current_setting('b5.seq')::uuid, 'fachlich', 'skelett')), false,
          'Fall 8: fachliche Freigabe zurückgesetzt');
select is((select render_id::text || '/' || version_skelett from studio_ausgabe where sequenz_id = current_setting('b5.seq')::uuid
            and welt = 'skelett'), current_setting('b5.render_alt') || '/1', 'Fall 8: Kinder sehen weiter die alte Fassung');
select pg_temp.als(:'autor');
set local role authenticated;
select pg_temp.vertonen_und_rendern(current_setting('b5.seq')::uuid);
select public.studio_einreichen(current_setting('b5.seq')::uuid);
reset role;
select pg_temp.als(:'gruender');
set local role authenticated;
select public.studio_pruefen(current_setting('b5.seq')::uuid, 'verstaendlich', 'skelett', 'passt');
reset role;
select pg_temp.als(:'lena');
set local role authenticated;
select public.studio_pruefen(current_setting('b5.seq')::uuid, 'fachlich', 'skelett', 'passt');
reset role;
select isnt((select render_id::text from studio_ausgabe where sequenz_id = current_setting('b5.seq')::uuid and welt = 'skelett'),
            current_setting('b5.render_alt'), 'nach neuer Freigabe: neue Fassung');
select is((select version_skelett from studio_ausgabe where sequenz_id = current_setting('b5.seq')::uuid and welt = 'fussball'),
          1::bigint, 'Varianten-Freigabe galt dem alten Skelett: Fußball bleibt bis zur neuen Prüfung auf der alten Fassung');
select pg_temp.als(:'admin');
set local role authenticated;
select lives_ok($$ select public.studio_zurueckziehen(current_setting('b5.seq')::uuid) $$, 'Admin zieht zurück');
reset role;
select pg_temp.als(:'autor');
set local role authenticated;
select public.studio_einreichen(current_setting('b5.seq')::uuid);
select is(cardinality(public.studio_ausgabe_pruefen(current_setting('b5.seq')::uuid)), 0,
          'nach dem Zurückziehen: alte Freigaben gelten nicht mehr');
reset role;

select * from finish();
rollback;
