-- ============================================================================
-- SP-1 · S1 Datenmodell (Migration 20261111191054_sp1_bauform_kommentare) mit den Bauformen der Reihe 1.
--   Passt ohne Kommentar; Rückfrage mit Kommentar; Kommentar ohne Grund und Text scheitert; Zeitänderung lässt
--   Version und Status unverändert; Rückfrage erledigt → zur Freigabe ohne „Zu prüfen“; fehlende Notiz oder rote
--   Prüfmaschine → kein Wechsel; Lena setzt nie ready und ruft bauform_rueckfrage_erledigt nicht auf; ein
--   gewöhnlicher Versionswechsel öffnet weiterhin für Lena; Kinder lesen keine Kommentare.
-- Am Ende rollback.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(50);

\set lena  '5b100000-0000-4000-8000-0000000000b1'
\set admin '5b100000-0000-4000-8000-0000000000a1'
\set kindp '5b100000-0000-4000-8000-0000000000c1'
insert into auth.users (id, email, instance_id, aud, role) values
  (:'lena', 'sp1-lena@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'admin', 'sp1-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'kindp', 'sp1-kind@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name, darf_pruefen) values
  (:'lena', 'sp1-lena@test.local', 'coach', 'SP1 Lena', true),
  (:'admin', 'sp1-admin@test.local', 'admin', 'SP1 Admin', false),
  (:'kindp', 'sp1-kind@test.local', 'student', 'SP1 Kind', false);
create function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;
-- Neue Version wie aus dem Export (tools/bauform.sh): Steckbrief geaendert, Protokoll und Blindloeser neu.
create function pg_temp.export(p_key text, p_rot numeric default 0, p_blind boolean default true) returns int
language plpgsql as $$
declare v int;
begin
  perform set_config('edvance.bauform_export', '1', true);
  update bauformen set steckbrief = steckbrief || jsonb_build_object('generator_hash', md5(random()::text)),
         pruefprotokoll = jsonb_build_object('gruen', 10, 'rot', 0, 'rot_anteil', p_rot, 'lauf_am', '20261111000000'),
         blindloeser = jsonb_build_object('bestanden', p_blind)
   where schluessel = p_key returning version into v;
  -- Instanzen der neuen Version (gruen), wie die Export-Migration sie anlegt
  insert into tasks (content_type, input_type, status, is_active, question, question_payload, parts, params, skill_key,
                     est_duration_sec, source, source_ref, einsatz, bauform_id, bauform_version, stufe, rolle, pruefmaschine)
  select 'exercise', t.input_type, 'draft', true, t.question, t.question_payload, t.parts, t.params, t.skill_key,
         t.est_duration_sec, 'bauform',
         t.source_ref || '-sp1v' || v, '{session}', t.bauform_id, v, t.stufe, t.rolle, t.pruefmaschine
    from tasks t join bauformen b on b.id = t.bauform_id
   where b.schluessel = p_key and t.bauform_version = v - 1;
  perform set_config('edvance.bauform_export', '', true);
  return v;
end $$;

select id as ein1 from bauformen where schluessel = 'EIN-1' \gset
select id as ko1 from bauformen where schluessel = 'KO-1' \gset
select id as np2 from bauformen where schluessel = 'NP-2' \gset
select id as gl1 from bauformen where schluessel = 'GL-1' \gset
select id as qw1 from bauformen where schluessel = 'QW-1' \gset
select id as aus1 from bauformen where schluessel = 'AUS-1' \gset
select t.id as ein1_s3 from tasks t where t.bauform_id = :'ein1' and t.stufe = 3 order by t.id limit 1 \gset
select t.id as np2_t from tasks t where t.bauform_id = :'np2' order by t.id limit 1 \gset
select t.id as ko1_t from tasks t where t.bauform_id = :'ko1' order by t.id limit 1 \gset

-- ── Stufen und Vorbelegung ──────────────────────────────────────────────────
select is((select count(*)::int from bauform_stufen),
          (select sum((select count(*) from jsonb_object_keys(steckbrief -> 'stufen')))::int from bauformen),
          'Stufen: je Bauform und Stufe eine Zeile');
select is((select zeit_min from bauform_stufen where bauform_id = :'ein1' and stufe = 3), 1.0::numeric,
          'Vorbelegung: EIN-1 Stufe 3 = 1 Min (zeit_sek 60)');
select is((select zeit_min from bauform_stufen s join bauformen b on b.id = s.bauform_id
            where b.schluessel = 'QW-1' and stufe = 1), 0.5::numeric, 'Vorbelegung: 30 s → 0,5 Min');

-- ── Passt ohne Kommentar ────────────────────────────────────────────────────
select pg_temp.act_as(:'lena');
select is(bauform_pruefung_senden(:'ein1', 1, '[]', '{}', 40) ->> 'status', 'zur_freigabe', 'Passt ohne Kommentar → zur Freigabe');
select is((select entscheidung from bauform_pruefungen where bauform_id = :'ein1'), 'passt', 'Passt nutzt bauform_pruefen');
select is((select count(*)::int from bauform_kommentare where bauform_id = :'ein1'), 0, 'Passt: keine Kommentare');

-- ── Kommentar ohne Grund und ohne Text, falscher Grund, doppelter Anker ────
select throws_ok(format($q$select bauform_pruefung_senden(%L, 1, '[{"anker":"grundgeruest","gruende":[],"text":"  "}]')$q$, :'ko1'),
                 '22023', null, 'Kommentar ohne Grund und Text scheitert');
select throws_ok(format($q$select bauform_pruefung_senden(%L, 1, '[{"anker":"stufen","gruende":["rechnung_falsch"]}]')$q$, :'ko1'),
                 '22023', null, 'Grund passt nicht zum Anker');
select throws_ok(format($q$select bauform_pruefung_senden(%L, 1, '[{"anker":"beispiel","gruende":["text_unklar"]}]')$q$, :'ko1'),
                 '22023', null, 'Beispiel-Kommentar ohne Instanz scheitert');
select throws_ok(format($q$select bauform_pruefung_senden(%L, 1, '[{"anker":"beispiel","task_id":"%s","gruende":["text_unklar"]}]')$q$, :'ko1', :'np2_t'),
                 '22023', null, 'Instanz einer anderen Bauform scheitert');
select throws_ok(format($q$select bauform_pruefung_senden(%L, 1, '[{"anker":"stufen","text":"a"},{"anker":"stufen","text":"b"}]')$q$, :'ko1'),
                 '22023', null, 'je Anker hoechstens ein Kommentar');
select is((select status from bauformen where id = :'ko1'), 'zur_pruefung', 'nach abgelehnten Kommentaren: Status unveraendert');
select is((select count(*)::int from bauform_pruefungen where bauform_id = :'ko1'), 0, 'nach abgelehnten Kommentaren: keine Pruefung');

-- ── Rückfrage mit Kommentar an einem Beispiel ───────────────────────────────
select bauform_pruefung_senden(:'ko1', 1,
  format('[{"anker":"beispiel","task_id":"%s","gruende":["rechnung_falsch"]},{"anker":"fehlbilder","text":"Fehlbild fehlt: x und y vertauscht"}]', :'ko1_t')::jsonb,
  '{}', 90) as r1 \gset
select is(:'r1'::jsonb ->> 'status', 'rueckfrage', 'mit Kommentaren → Rueckfrage');
select is((select entscheidung from bauform_pruefungen where bauform_id = :'ko1'), 'unsicher', 'Rueckfrage nutzt bauform_pruefen (unsicher)');
select is((select count(*)::int from bauform_kommentare where pruefung_id = (:'r1'::jsonb ->> 'pruefung_id')::uuid), 2,
          'zwei Kommentare an der Pruefung');
select is((select task_id from bauform_kommentare where bauform_id = :'ko1' and anker = 'beispiel'), :'ko1_t'::uuid,
          'Kommentar am Beispiel mit Instanz gespeichert');
select is((select gruende from bauform_kommentare where bauform_id = :'ko1' and anker = 'beispiel'), '{rechnung_falsch}'::text[],
          'Grund rechnung_falsch gespeichert');

-- ── Zeit je Stufe ───────────────────────────────────────────────────────────
select is(bauform_zeit_setzen(:'np2', 3, 2), 2::numeric, 'Zeit Stufe 3 → 2');
select is((select (version, status)::text from bauformen where id = :'np2'), '(1,zur_pruefung)', 'Zeitaenderung: Version und Status unveraendert');
select is((select (alt_min, neu_min, geaendert_von)::text from bauform_zeit_aenderungen where bauform_id = :'np2'),
          format('(1.5,2.0,%s)', :'lena'), 'Zeitaenderung protokolliert (alt, neu, wer)');
select throws_ok(format('select bauform_zeit_setzen(%L, 3, 1.25)', :'np2'), '22023', null, 'Zeit nur in Schritten von 0,5');
select throws_ok(format('select bauform_zeit_setzen(%L, 3, 10.5)', :'np2'), '22023', null, 'Zeit hoechstens 10');
select throws_ok(format('select bauform_zeit_setzen(%L, 3, 0)', :'np2'), '22023', null, 'Zeit mindestens 0,5');
select is(bauform_zeit_setzen(:'ein1', 3, 1.5), 1.5::numeric, 'EIN-1 Stufe 3: 1 → 1,5');
select is(aufgabe_zeit_sek(:'ein1_s3'), 90, 'aufgabe_zeit_sek liest die Zeit der Stufe');
select is((select version from bauformen where id = :'ein1'), 1, 'EIN-1 Version unveraendert');
-- Zeit mit der Entscheidung
select is(bauform_pruefung_senden(:'gl1', 1, '[]', '{"2": 2}') ->> 'status', 'zur_freigabe', 'Passt mit Zeitaenderung');
select ok((select pruefung_id is not null and neu_min = 2 from bauform_zeit_aenderungen where bauform_id = :'gl1'),
          'Zeitaenderung mit der Pruefung verknuepft');
select is((select version from bauformen where id = :'gl1'), 1, 'Passt mit Zeit: Version unveraendert');

-- ── Lena: nie ready, keine Rückfrage abschließen ────────────────────────────
select throws_ok(format('select bauform_rueckfrage_erledigt(%L, 2)', :'ko1'), '42501', null, 'Lena ruft bauform_rueckfrage_erledigt nicht auf');
select throws_ok(format('select bauform_kommentar_erledigen(id, %L) from bauform_kommentare where bauform_id = %L limit 1', 'x', :'ko1'),
                 '42501', null, 'Lena markiert keinen Kommentar erledigt');
select throws_ok($q$select bauform_freigeben('quadratische_funktionen_gleichungen')$q$, '42501', null, 'Lena gibt nicht frei');
select throws_ok(format($q$select task_status_set(%L, 'ready')$q$, :'ein1_s3'), null, null, 'Lena setzt keine Aufgabe ready');
set local role authenticated;
update tasks set status = 'ready' where id = :'ein1_s3';
reset role;
select isnt((select status from tasks where id = :'ein1_s3'), 'ready', 'direkter Update auf ready greift nicht');

-- ── Rückfrage erledigt ──────────────────────────────────────────────────────
reset role;
select set_config('request.jwt.claims', json_build_object('role', 'service_role')::text, true);
select is(pg_temp.export('KO-1'), 2, 'Ueberarbeitung: KO-1 Version 2');
select is((select status from bauformen where id = :'ko1'), 'rueckfrage', 'Ueberarbeitung oeffnet nicht fuer Lena');
select pg_temp.act_as(:'lena');
select ok(not exists (select 1 from bauform_pruef_liste() where schluessel = 'KO-1' and status = 'zur_pruefung'),
          'KO-1 erscheint nicht unter Zu pruefen');
select pg_temp.act_as(:'admin');
select throws_ok(format('select bauform_rueckfrage_erledigt(%L, 2)', :'ko1'), 'P0001', null, 'Kommentar offen → kein Wechsel');
select throws_ok(format($q$select bauform_kommentar_erledigen(id, '  ') from bauform_kommentare where bauform_id = %L limit 1$q$, :'ko1'),
                 '22023', null, 'erledigt ohne Notiz scheitert');
select bauform_kommentar_erledigen(id, 'Rechnung korrigiert') from bauform_kommentare where bauform_id = :'ko1' and anker = 'beispiel';
select throws_ok(format('select bauform_rueckfrage_erledigt(%L, 2)', :'ko1'), 'P0001', null, 'eine Notiz fehlt → kein Wechsel');
select is((select status from bauformen where id = :'ko1'), 'rueckfrage', 'ohne alle Notizen bleibt die Rueckfrage');
select bauform_kommentar_erledigen(id, 'Fehlbild ergaenzt') from bauform_kommentare where bauform_id = :'ko1' and anker = 'fehlbilder';
select is(bauform_rueckfrage_erledigt(:'ko1', 2), 'zur_freigabe', 'alle Notizen, Pruefmaschine gruen, Blindloeser bestanden → zur Freigabe');
select ok((select k ->> 'erledigt_notiz' = 'Rechnung korrigiert'
             from jsonb_array_elements(bauform_pruef_detail(:'ko1') -> 'rueckfrage' -> 'kommentare') k where k ->> 'anker' = 'beispiel'),
          'Admin sieht Kommentare mit Notiz');

-- Prüfmaschine rot / Blindlöser durchgefallen
select pg_temp.act_as(:'lena');
select bauform_pruefung_senden(:'qw1', 1, '[{"anker":"grundgeruest","gruende":["text_unklar"]}]');
select bauform_pruefung_senden(:'aus1', 1, '[{"anker":"stufen","gruende":["zahlen_anders_waehlen"]}]');
select set_config('request.jwt.claims', json_build_object('role', 'service_role')::text, true);
select pg_temp.export('QW-1', 0.5);
select pg_temp.export('AUS-1', 0, false);
select bauform_kommentar_erledigen(id, 'geaendert') from bauform_kommentare where bauform_id in (:'qw1', :'aus1');
select throws_ok(format('select bauform_rueckfrage_erledigt(%L, 2)', :'qw1'), 'P0001', null, 'Pruefmaschine rot → kein Wechsel (Systemaufruf)');
select throws_ok(format('select bauform_rueckfrage_erledigt(%L, 2)', :'aus1'), 'P0001', null, 'Blindloeser durchgefallen → kein Wechsel');

-- ── Gewöhnlicher Versionswechsel öffnet weiterhin ───────────────────────────
select pg_temp.export('EIN-1');
select is((select status from bauformen where id = :'ein1'), 'zur_pruefung', 'zur Freigabe + neue Version → wieder zu pruefen');

-- ── Andere Beispiele behalten das kommentierte ──────────────────────────────
select pg_temp.act_as(:'lena');
select ok(bauform_pruef_detail(:'np2', 7, array[:'np2_t'::uuid]) -> 'beispiele' @> format('[{"task_id":"%s"}]', :'np2_t')::jsonb
          and bauform_pruef_detail(:'np2', 8, array[:'np2_t'::uuid]) -> 'beispiele' @> format('[{"task_id":"%s"}]', :'np2_t')::jsonb,
          'Andere Beispiele: behaltenes Beispiel bleibt');

-- ── Kinder lesen nichts, Auswertung für Admins ──────────────────────────────
select pg_temp.act_as(:'kindp');
set local role authenticated;
select is((select count(*)::int from bauform_kommentare), 0, 'Kind liest keine Kommentare');
reset role;
select pg_temp.act_as(:'admin');
set local role authenticated;
select ok((select anzahl >= 1 from bauform_kommentar_auswertung where grund = 'rechnung_falsch' and bauform = 'KO-1'),
          'Admin sieht die Auswertung');
reset role;

select * from finish();
rollback;
