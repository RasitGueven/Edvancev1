-- ============================================================================
-- IU-1 U1: Inhalte-Übersicht (20261113082550_iu1_inhalte, 20261113082906_iu1_pruefziel_msa)
--
-- Zusagen:
--   1) Themenraum je Thema = Fall A der Pakete (lsa_paket_skills), Pflicht = Einstieg + direkte Voraussetzung.
--   2) Ampel je Thema: vollständig (alles bereit, Einstieg), eingeschränkt (Pflicht bereit), sonst noch nicht.
--   3) Archivierte Aufgaben zählen nicht.
--   4) Prüfziel: ausgeschlossene (zu schwere) Aufgaben zählen nicht als Beleg und werden nicht vorgeschlagen;
--      zu leichte zählen und werden gezählt. Skills ohne Paket stehen mit Prüfziel in Lenas Liste (Hebel 0).
--   5) pruef_ziel_liste ohne neue Parameter: unverändert (ohne Skills ohne Paket, gleiche Zeilen wie mit null);
--      pruef_ziel_roh() = pruef_ziel_roh('{}'), lsa_skill_bereit_roh(null) = (null, '{}').
--   6) Zwischenspeicher = Live-Rechnung; Schreiben auf tasks macht ihn veraltet.
--   7) Rechte: Admin alles; Lena (darf_pruefen) pruef_ziel_liste mit Prüfziel und pruef_ziel_stand, aber keine
--      inhalte_*; Coach ohne Prüfrecht und Kind nichts.
--   8) Session-Reihen: Zahlen aus bauformen und studio_sequenz; Themen ohne Reihe ohne Themen der Reihe.
--   9) Paket-Speicher frischt sich auf (DELETE/UPDATE mit WHERE, safeupdate).
--
-- Isolation: Pläne und Klassenarbeiten transaktionslokal leer, eigene Skills und Themen (Präfix iu_).
-- Graph (Pfeil = setzt voraus): iu_e1 -> iu_v1 -> iu_d1 (Thema iu_t1, Einstieg iu_e1)
--                               iu_e2 -> iu_v2            (Thema iu_t2, Einstieg iu_e2)
--                               iu_x                      (Thema iu_t9, in keinem Plan)
-- Schule A Kl. 9: iu_t1, iu_t2. Schule B Kl. 9: iu_t1.
-- ============================================================================
begin;
alter table public.tasks alter column einsatz set default '{lsa}';
create extension if not exists pgtap with schema extensions;

select plan(54);

delete from schul_themenplan;
delete from schul_klassenarbeiten;

insert into skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe) values
  ('iu_e1', 'IU E1', 'mathematik', 9, 3), ('iu_v1', 'IU V1', 'mathematik', 8, 2), ('iu_d1', 'IU D1', 'mathematik', 6, 1),
  ('iu_e2', 'IU E2', 'mathematik', 9, 2), ('iu_v2', 'IU V2', 'mathematik', 8, 1), ('iu_x', 'IU X', 'mathematik', 9, 1);
insert into skill_kante (skill_key, voraussetzt_skill_key) values
  ('iu_e1', 'iu_v1'), ('iu_v1', 'iu_d1'), ('iu_e2', 'iu_v2');
insert into themen (thema_key, fach, klasse, label, stufe, sort) values
  ('iu_t0', 'mathematik', 9, 'IU Null', 'erste', 9800), ('iu_t1', 'mathematik', 9, 'IU Eins', 'erste', 9801),
  ('iu_t2', 'mathematik', 9, 'IU Zwei', 'erste', 9802), ('iu_t9', 'mathematik', 9, 'IU Neun', 'erste', 9809);
insert into skill_thema (skill_key, thema_key) values
  ('iu_e1', 'iu_t1'), ('iu_e2', 'iu_t2'), ('iu_x', 'iu_t9'),
  ('iu_v1', 'iu_t0'), ('iu_d1', 'iu_t0'), ('iu_v2', 'iu_t0');
insert into thema_einstieg (thema_key, skill_key) values ('iu_t1', 'iu_e1'), ('iu_t2', 'iu_e2');

\set admin_uid 'dddddddd-dddd-dddd-dddd-0000000001a1'
\set lena_uid  'dddddddd-dddd-dddd-dddd-0000000001a2'
\set coach_uid 'dddddddd-dddd-dddd-dddd-0000000001a3'
\set kind_uid  'dddddddd-dddd-dddd-dddd-0000000001a4'
insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid', 'iu1-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'lena_uid',  'iu1-lena@test.local',  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach_uid', 'iu1-coach@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'kind_uid',  'iu1-kind@test.local',  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name, darf_pruefen) values
  (:'admin_uid', 'iu1-admin@test.local', 'admin', 'IU1 Admin', false),
  (:'lena_uid',  'iu1-lena@test.local',  'coach', 'IU1 Lena', true),
  (:'coach_uid', 'iu1-coach@test.local', 'coach', 'IU1 Coach', false),
  (:'kind_uid',  'iu1-kind@test.local',  'student', 'IU1 Kind', false);
select set_config('request.jwt.claims', json_build_object('sub', :'admin_uid', 'role', 'authenticated')::text, true);

insert into schulen (name, ort) values ('IU Schule A', 'Testort'), ('IU Schule B', 'Testort');
select id as schule_a from schulen where name = 'IU Schule A' \gset
select id as schule_b from schulen where name = 'IU Schule B' \gset
insert into schul_themenplan (schule_id, fach, klasse, position, thema_key, uv_titel, stunden, quelle_url) values
  (:'schule_a', 'mathematik', 9, 1, 'iu_t1', 'UV 1', 10, 'https://test.invalid'),
  (:'schule_a', 'mathematik', 9, 2, 'iu_t2', 'UV 2', 10, 'https://test.invalid'),
  (:'schule_b', 'mathematik', 9, 1, 'iu_t1', 'UV 1', 10, 'https://test.invalid');

create function pg_temp.aufgabe(p_skill text, p_text text, p_typ text default 'NUMERIC', p_status text default 'ready')
returns uuid language plpgsql as $$
declare v uuid;
begin
  insert into tasks (cluster_id, content_type, input_type, status, question, source, source_ref, skill_key,
                     sondierrang, class_level, afb, curriculum_grade, pruef_pilot)
  values ((select c.id from skill_clusters c join subjects sub on sub.id = c.subject_id
            where sub.name = 'Mathematik' order by c.sort_order limit 1),
          'exercise', p_typ, 'draft', p_text, 'test', 'iu-' || gen_random_uuid(), p_skill, 1, 9, 'I', 9, true)
  returning id into v;
  insert into task_solutions (task_id, correct_answers) values (v, '["5"]');
  if p_status = 'ready' then perform public.task_status_set(v, 'ready'); end if;
  return v;
end $$;
create function pg_temp.zeile(p text) returns text language sql as $$
  select (ampel, komp_bereit, komp_teil, komp_offen, pflicht_bereit, pflicht_gesamt)::text
    from inhalte_lsa_themen(9) where thema_key = p $$;

-- ============================================================================
-- 1) Themenraum
-- ============================================================================
select results_eq(
  $$select skill_key, teil, pflicht from inhalte_thema_raum(lsa_schuljahr_heute()) where thema_key = 'iu_t1'
     order by skill_key$$,
  $$select skill_key, teil, pflicht from lsa_paket_skills(
      (select id from schulen where name = 'IU Schule A'), 9, 1) where fall = 'A' order by skill_key$$,
  '1a: Themenraum = Fall A der Pakete');
select results_eq(
  $$select skill_key, teil, rolle from inhalte_lsa_thema('iu_t1')$$,
  $$values ('iu_e1', 'pflicht', 'einstieg'), ('iu_v1', 'pflicht', 'voraussetzung'), ('iu_d1', 'tiefe', 'tiefe')$$,
  '1b: Pflicht = Einstieg und direkte Voraussetzung, Tiefe = Rest, Pflicht zuerst');
select results_eq(
  $$select klasse, schulen, schulen_bestaetigt, hat_einstieg from inhalte_lsa_themen(9) where thema_key = 'iu_t1'$$,
  $$values (9, 2, 0, true)$$, '1c: Thema mit Klasse, Schulen (davon bestätigt), Einstieg');
select is((select count(*)::int from inhalte_lsa_themen(8) where thema_key like 'iu_%'), 0,
  '1d: Klassenfilter: in Klasse 8 kein iu-Thema');

-- ============================================================================
-- 2) Ampel
-- ============================================================================
select is(pg_temp.zeile('iu_t1'), '(noch_nicht,0,0,3,0,2)', '2a: ohne Aufgaben noch nicht');
select pg_temp.aufgabe('iu_e1', 'Text E1 eins') e1a \gset
select pg_temp.aufgabe('iu_e1', 'Text E1 zwei') e1b \gset
select pg_temp.aufgabe('iu_v1', 'Text V1 eins') v1a \gset
select is(pg_temp.zeile('iu_t1'), '(noch_nicht,1,1,1,1,2)', '2b: eine Pflicht teilweise → noch nicht');
select is((select (texte, erfuellt)::text from inhalte_lsa_thema('iu_t1') where skill_key = 'iu_v1'), '(1,f)',
  '2c: 1 von 2');
select pg_temp.aufgabe('iu_v1', 'Text V1 zwei') v1b \gset
select is(pg_temp.zeile('iu_t1'), '(eingeschraenkt,2,0,1,2,2)', '2d: Pflicht bereit, Tiefe fehlt → eingeschränkt');
select pg_temp.aufgabe('iu_d1', 'Text D1 eins') d1a \gset
select pg_temp.aufgabe('iu_d1', 'Text D1 zwei') d1b \gset
select is(pg_temp.zeile('iu_t1'), '(vollstaendig,3,0,0,2,2)', '2e: alles bereit und Einstieg → vollständig');
select is((select aufgaben_frei from inhalte_lsa_themen(9) where thema_key = 'iu_t1'), 6, '2f: 6 Aufgaben frei');
-- Zwei MC-Texte reichen nicht (1 ohne MC fehlt): 1 von 2.
select pg_temp.aufgabe('iu_e2', 'Text E2 eins', 'MC'), pg_temp.aufgabe('iu_e2', 'Text E2 zwei', 'MC');
select is((select (texte, erfuellt)::text from inhalte_lsa_thema('iu_t2') where skill_key = 'iu_e2'), '(1,f)',
  '2g: zwei MC-Texte = 1 von 2 (ohne MC fehlt)');

-- ============================================================================
-- 3) Archiv
-- ============================================================================
update tasks set is_active = false, archiviert_am = now(), archiviert_von = :'admin_uid', archiviert_grund = 'nicht_notwendig'
 where id = :'d1b';
select is(pg_temp.zeile('iu_t1'), '(eingeschraenkt,2,1,0,2,2)', '3a: archivierte Aufgabe zählt nicht');
select is((select aufgaben_frei from inhalte_lsa_themen(9) where thema_key = 'iu_t1'), 5, '3b: 5 frei ohne Archiv');
update tasks set is_active = true, archiviert_am = null, archiviert_von = null, archiviert_grund = null
 where id = :'d1b';

-- ============================================================================
-- 4) Prüfziel
-- ============================================================================
insert into pruefziele (key, titel) values ('iu_ziel', 'IU Ziel');
insert into pruefziel_skills (pruefziel, skill_key, bereich) values
  ('iu_ziel', 'iu_e1', 'bereich_a'), ('iu_ziel', 'iu_d1', 'bereich_a'), ('iu_ziel', 'iu_x', 'bereich_b');
select pg_temp.aufgabe('iu_x', 'Text X eins', 'NUMERIC', 'draft') x1 \gset
select pg_temp.aufgabe('iu_x', 'Text X zwei', 'NUMERIC', 'draft') x2 \gset
select pg_temp.aufgabe('iu_x', 'Text X drei', 'NUMERIC', 'draft') x3 \gset
select pg_temp.aufgabe('iu_e1', 'Text E1 drei', 'NUMERIC', 'draft') e1c \gset
insert into pruefziel_ausschluss (pruefziel, task_id, grund) values
  ('iu_ziel', :'e1a', 'zu_schwer'), ('iu_ziel', :'d1a', 'zu_leicht'), ('iu_ziel', :'x3', 'zu_schwer');

select results_eq(
  $$select bereich, komp_bereit, komp_teil, komp_offen, fehlende_texte, aufgaben_frei, zu_leicht, ampel
      from inhalte_lsa_pruefziel('iu_ziel')$$,
  $$values (null::text, 1, 1, 1, 3, 3, 1, 'noch_nicht'), ('bereich_a', 1, 1, 0, 1, 3, 1, 'noch_nicht'),
           ('bereich_b', 0, 0, 1, 2, 0, 0, 'noch_nicht')$$,
  '4a: Kopf und je Bereich; zu schwer zählt nicht, zu leicht zählt (markiert)');
select is((select (texte, erfuellt)::text from inhalte_lsa_thema('iu_t1') where skill_key = 'iu_e1'), '(2,t)',
  '4b: ohne Prüfziel zählt die zu schwere Aufgabe');
select is((select task_ids from pruef_ziel_liste(p_pruefziel => 'iu_ziel') where abschnitt = 'gezielt'
            and skill_key = 'iu_e1'), array[:'e1c'::uuid], '4c: mit Prüfziel: Vorschlag für den nicht mehr erfüllten Skill');
select results_eq($$select hebel_pakete, array(select u from unnest(task_ids) u order by u)
      from pruef_ziel_liste(p_pruefziel => 'iu_ziel') where skill_key = 'iu_x'$$,
  format($$select 0, array(select u from unnest(array[%L::uuid, %L::uuid]) u order by u)$$, :'x1', :'x2'), '4d: Skill ohne Paket mit Hebel 0, ohne ausgeschlossene Aufgabe');
select is((select count(*)::int from pruef_ziel_liste(p_pruefziel => 'iu_ziel') where skill_key not like 'iu_%'), 0,
  '4e: mit Prüfziel nur dessen Skills');
select results_eq($$select skill_key from pruef_ziel_liste(p_pruefziel => 'iu_ziel', p_skill => 'iu_x')$$,
  $$values ('iu_x')$$, '4f: mit Kompetenz nur diese');
select results_eq($$select skill_key, bereich, texte, erfuellt, zu_leicht from pruef_ziel_stand('iu_ziel')$$,
  $$values ('iu_d1', 'bereich_a', 2, true, 1), ('iu_e1', 'bereich_a', 1, false, 0), ('iu_x', 'bereich_b', 0, false, 0)$$,
  '4g: pruef_ziel_stand je Kompetenz');
select throws_ok($$select * from inhalte_lsa_pruefziel('gibt_es_nicht')$$, 'P0002', null, '4h: unbekanntes Ziel');

-- ============================================================================
-- 5) Unverändert ohne neue Parameter
-- ============================================================================
select is((select count(*)::int from pruef_ziel_liste() where skill_key = 'iu_x'), 0,
  '5a: ohne Prüfziel kein Skill ohne Paket');
select results_eq($$select * from pruef_ziel_liste()$$,
  $$select * from pruef_ziel_liste(false, null, null, null, null)$$, '5b: ohne Parameter = mit null');
select is((select task_ids from pruef_ziel_liste() where abschnitt = 'gezielt' and skill_key = 'iu_e1'), null,
  '5c: ohne Prüfziel ist iu_e1 erfüllt, kein Vorschlag');
select results_eq($$select * from pruef_ziel_roh() order by skill_key$$,
  $$select * from pruef_ziel_roh('{}') order by skill_key$$, '5d: pruef_ziel_roh() = pruef_ziel_roh(''{}'')');
select results_eq($$select * from lsa_skill_bereit_roh(null) order by skill_key$$,
  $$select * from lsa_skill_bereit_roh(null, '{}') order by skill_key$$, '5e: lsa_skill_bereit_roh unverändert');
select results_eq(
  $$select skill_key, rest, task_ids from pruef_ziel_liste(p_skill => 'iu_x')$$,
  $$select skill_key, rest, task_ids from pruef_ziel_liste() where skill_key = 'iu_x'$$,
  '5f: p_skill allein filtert die bisherige Liste');

-- ============================================================================
-- 6) Zwischenspeicher
-- ============================================================================
create temp table live as select * from inhalte_lsa_themen(9);
create temp table live_ziel as select * from inhalte_lsa_pruefziel('iu_ziel');
select is(inhalte_auffrischen(), true, '6a: auffrischen rechnet neu');
select is(inhalte_cache_frisch(), true, '6b: Speicher frisch');
select results_eq($$select * from inhalte_lsa_themen(9)$$, $$select * from live$$, '6c: Speicher = live (Themen)');
select results_eq($$select * from inhalte_lsa_pruefziel('iu_ziel')$$, $$select * from live_ziel$$,
  '6d: Speicher = live (Prüfziel)');
select is(inhalte_auffrischen(), false, '6e: frisch → nichts zu tun');
select pg_temp.aufgabe('iu_e2', 'Text E2 drei');
select is(inhalte_cache_frisch(), false, '6f: neue Aufgabe → nicht mehr frisch');
select is((select (texte, erfuellt)::text from inhalte_lsa_thema('iu_t2') where skill_key = 'iu_e2'), '(2,t)',
  '6g: veraltet → live (neue Aufgabe zählt sofort)');

-- ============================================================================
-- 7) Rechte
-- ============================================================================
select set_config('request.jwt.claims', json_build_object('sub', :'lena_uid', 'role', 'authenticated')::text, true);
select ok((select count(*) from pruef_ziel_liste(p_pruefziel => 'iu_ziel')) > 0, '7a: Lena: Liste mit Prüfziel');
select ok((select count(*) from pruef_ziel_stand('iu_ziel')) = 3, '7b: Lena: Stand je Kompetenz');
select throws_ok($$select * from inhalte_lsa_themen()$$, '42501', null, '7c: Lena: keine inhalte_*');
select throws_ok($$select inhalte_auffrischen()$$, '42501', null, '7d: Lena: kein Auffrischen');
select set_config('request.jwt.claims', json_build_object('sub', :'coach_uid', 'role', 'authenticated')::text, true);
select throws_ok($$select * from pruef_ziel_liste(p_pruefziel => 'iu_ziel')$$, '42501', null,
  '7e: Coach ohne Prüfrecht: keine Liste');
select throws_ok($$select * from inhalte_session_reihen()$$, '42501', null, '7f: Coach: keine Reihen');
select set_config('request.jwt.claims', json_build_object('sub', :'kind_uid', 'role', 'authenticated')::text, true);
select throws_ok($$select * from pruef_ziel_stand('iu_ziel')$$, '42501', null, '7g: Kind: kein Stand');
select throws_ok($$select * from inhalte_lsa_pruefziel('iu_ziel')$$, '42501', null, '7h: Kind: kein Prüfziel');
-- Grants als Rolle authenticated: öffentliche Funktionen ja, innere nein, Tabellen nur über RLS.
select set_config('request.jwt.claims', json_build_object('sub', :'admin_uid', 'role', 'authenticated')::text, true);
set local role authenticated;
select ok((select count(*) from inhalte_lsa_themen(9)) > 0, '7i: authenticated (Admin) darf inhalte_lsa_themen');
select throws_ok($$select * from inhalte_skill_stand_roh(null)$$, '42501', null, '7j: innere Funktion gesperrt');
select throws_ok($$select * from pruef_ziel_roh()$$, '42501', null, '7k: pruef_ziel_roh gesperrt');
select ok((select count(*) from pruefziel_skills where pruefziel = 'iu_ziel') = 3, '7l: Admin liest Prüfziel (RLS)');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :'kind_uid', 'role', 'authenticated')::text, true);
set local role authenticated;
select is((select count(*)::int from pruefziel_skills), 0, '7m: Kind sieht keine Prüfziel-Zeilen (RLS)');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :'admin_uid', 'role', 'authenticated')::text, true);

-- ============================================================================
-- 8) Session-Reihen
-- ============================================================================
insert into bauformen (schluessel, reihe, skill_key, kernidee_key, format, rollen, status) values
  ('IU-1', 'iu_reihe', 'iu_e2', 'iu_e2:K1', 'zahl', '{uebung}', 'freigegeben'),
  ('IU-2', 'iu_reihe', 'iu_e2', 'iu_e2:K1', 'zahl', '{uebung}', 'zur_pruefung'),
  ('IU-3', 'iu_reihe', 'iu_v2', null, 'zahl', '{warmup}', 'rueckfrage');
insert into studio_sequenz (skill_key, titel, autor_id, status, skript) values
  ('iu_e2', 'IU Video', :'admin_uid', 'in_pruefung', '{}');
select results_eq(
  $$select thema_keys, klasse, bf_freigegeben, bf_zur_freigabe, bf_rueckfrage, bf_offen, bf_zu_pruefen,
           vid_freigegeben, vid_in_pruefung, vid_fehlt, vid_gesamt, ampel, schulen
      from inhalte_session_reihen(9) where reihe = 'iu_reihe'$$,
  $$values (array['iu_t2'], 9, 1, 0, 1, 1, 1, 0, 1, 0, 1, 'in_arbeit', 1)$$,
  '8a: Reihe mit Bauformen nach Status, Videos, Ampel, Schulen');
select results_eq(
  $$select sum(bauformen)::int, sum(rueckfrage)::int, sum(zu_pruefen)::int from inhalte_session_reihe('iu_reihe')$$,
  $$values (3, 1, 1)$$, '8b: Sessions summieren sich zur Reihe');
update bauformen set status = 'entwurf' where reihe = 'iu_reihe';
select is((select naechster_schritt from inhalte_session_reihe('iu_reihe')), 'entwurf', '8e: nur Entwürfe → Entwurf, nicht fertig');
select is((select array_agg(thema_key order by thema_key) from inhalte_themen_ohne_reihe(9) where thema_key like 'iu_%'),
  array['iu_t1'], '8c: Themen ohne Reihe: iu_t2 hat eine Reihe');
select is((select (bauformen, vorarbeit)::text from inhalte_themen_ohne_reihe(9) where thema_key = 'iu_t1'),
  '(0,lsa)', '8d: Vorarbeit: LSA-Aufgaben, keine Bauformen');

-- ============================================================================
-- 9) Paket-Speicher unter safeupdate-Regeln (WHERE vorhanden)
-- ============================================================================
insert into schul_themenplan (schule_id, fach, klasse, position, thema_key, uv_titel, stunden, quelle_url)
  values (:'schule_b', 'mathematik', 9, 2, 'iu_t2', 'UV 2', 10, 'https://test.invalid');
select is(lsa_abdeckung_auffrischen(), true, '9a: Plan geändert (Trigger mit WHERE) → Paket-Speicher frischt auf');
select is((select (veraltet, fehler)::text from lsa_paket_cache_stand), '(f,)', '9b: frisch, ohne Fehler');

select * from finish();
rollback;
