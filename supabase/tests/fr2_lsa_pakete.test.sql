-- ============================================================================
-- FR-2 F1: Pakete je Klassenarbeit, Ampel, gezielte Prüfliste (20261109114850_fr2_lsa_pakete)
--
-- Zusagen:
--   1) Pakete: 1 Unterrichtsvorhaben = 1 Arbeit, Lage aus kumulierten Stunden, Quartal nach der Mitte.
--   2) Fall A = Einstieg + direkte Voraussetzung (Pflicht) + Tiefe; Fall B = Rand wie lsa_select_next_core
--      (Voraussetzung eines späteren Themas → deren Rand; Klassengrenze), Rand-Tiefe = lsa_abschluss(Rand).
--   3) Ampel: gelb = Pflicht erfüllt, Tiefe fehlt; grün = alles erfüllt + Einstieg; rot sonst / ohne Einstieg.
--   4) Die Regel hängt an den Stellschrauben (lsa_regel_texte).
--   5) Eine bestätigte Folge ersetzt die geschätzten Pakete der Schule und Klasse (quelle 'bestaetigt').
--   6) Fokus ändert die Reihenfolge in pruef_ziel_liste.
--   7) pruef_ziel_liste schlägt keinen Entwurf mit einem Textschlüssel aus dem Pool vor und nie mehr als
--      fehlende_texte + 1 je Skill; Entwürfe außerhalb des Pilots stehen unter pilot_fehlt.
--   8) Sammelfreigabe: pruef_sammel('freigeben') nimmt nur Aufgaben mit pruef_freigabe_erlaubt, das Gate greift,
--      Lena darf nicht.
--   9) Rechte: Lena (darf_pruefen) ja, Kind nein; Zwischenspeicher = Live-Rechnung.
--
-- Isoliert wie inv10: Fundament transaktionslokal ausgeblendet, eigener Graph (Präfix zf_).
--
-- Graph (Klasse), Pfeil = setzt voraus:
--   Thema zf_t1: zf_e1 (9) -> zf_v1 (8) -> zf_d1 (6)              Einstieg zf_e1 (zf_v1, zf_d1, zf_q, zf_hoch: Thema zf_t0)
--   Thema zf_t2: zf_e2 (9) -> zf_e1, zf_e2 -> zf_hoch (10)         Einstieg zf_e2
--                zf_s2 (9) -> zf_s3 (Thema zf_t3) -> zf_q (7)
--   Thema zf_t3: zf_s3 (9)                                        ohne Einstieg
--   Thema zf_t4: zf_x (9)                                         Einstieg zf_x (nur Schule B)
-- Schule A Kl. 9: zf_t1, zf_t2, zf_t3 (je 10 Stunden). Schule B Kl. 9: zf_t4.
-- ============================================================================
begin;
alter table public.tasks alter column einsatz set default '{lsa}';
create extension if not exists pgtap with schema extensions;

select plan(39);

-- --- Isolation --------------------------------------------------------------
update tasks set skill_key = null where skill_key is not null;
delete from thema_einstieg;
delete from skill_kante;
delete from skill_thema;
delete from erklaer_kernidee;
alter table bauformen drop constraint bauformen_skill_key_fkey;
alter table skill_pruefung drop constraint skill_pruefung_skill_key_fkey;
delete from skills;
delete from schul_themenplan;
delete from schul_klassenarbeiten;

-- --- Graph -------------------------------------------------------------------
insert into skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe) values
  ('zf_e1', 'E1', 'mathematik', 9, 4), ('zf_v1', 'V1', 'mathematik', 8, 3), ('zf_d1', 'D1', 'mathematik', 6, 1),
  ('zf_e2', 'E2', 'mathematik', 9, 5), ('zf_hoch', 'Hoch', 'mathematik', 10, 2), ('zf_s2', 'S2', 'mathematik', 9, 4),
  ('zf_s3', 'S3', 'mathematik', 9, 3), ('zf_q', 'Q', 'mathematik', 7, 1), ('zf_x', 'X', 'mathematik', 9, 1);
insert into skill_kante (skill_key, voraussetzt_skill_key) values
  ('zf_e1', 'zf_v1'), ('zf_v1', 'zf_d1'), ('zf_e2', 'zf_e1'), ('zf_e2', 'zf_hoch'), ('zf_s2', 'zf_s3'),
  ('zf_s3', 'zf_q');
insert into themen (thema_key, fach, klasse, label, stufe, sort) values
  ('zf_t0', 'mathematik', 9, 'ZF Null', 'erste', 9900),
  ('zf_t1', 'mathematik', 9, 'ZF Eins', 'erste', 9901), ('zf_t2', 'mathematik', 9, 'ZF Zwei', 'erste', 9902),
  ('zf_t3', 'mathematik', 9, 'ZF Drei', 'erste', 9903), ('zf_t4', 'mathematik', 9, 'ZF Vier', 'erste', 9904);
-- Stufe 'erste': die Kernlehrplan-Folge der Klasse 10 (Stufe 'zweite') nimmt sie nicht als spätere Themen.
-- zf_t0 steht in keinem Plan: Seine Skills gelten im Rand wie Skills früherer Themen (pruef_ausschluss braucht ein Thema).
insert into skill_thema (skill_key, thema_key) values
  ('zf_e1', 'zf_t1'), ('zf_e2', 'zf_t2'), ('zf_s2', 'zf_t2'), ('zf_s3', 'zf_t3'), ('zf_x', 'zf_t4'),
  ('zf_v1', 'zf_t0'), ('zf_d1', 'zf_t0'), ('zf_q', 'zf_t0'), ('zf_hoch', 'zf_t0');
insert into thema_einstieg (thema_key, skill_key) values ('zf_t1', 'zf_e1'), ('zf_t2', 'zf_e2'), ('zf_t4', 'zf_x');

-- --- Personen ------------------------------------------------------------------
\set admin_uid 'dddddddd-dddd-dddd-dddd-0000000000f1'
\set lena_uid  'dddddddd-dddd-dddd-dddd-0000000000f2'
\set kind_uid  'dddddddd-dddd-dddd-dddd-0000000000f3'
insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid', 'fr2-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'lena_uid',  'fr2-lena@test.local',  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'kind_uid',  'fr2-kind@test.local',  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name, darf_pruefen) values
  (:'admin_uid', 'fr2-admin@test.local', 'admin', 'FR2 Admin', false),
  (:'lena_uid',  'fr2-lena@test.local',  'coach', 'FR2 Lena', true),
  (:'kind_uid',  'fr2-kind@test.local',  'student', 'FR2 Kind', false);
select set_config('request.jwt.claims', json_build_object('sub', :'admin_uid', 'role', 'authenticated')::text, true);

insert into schulen (name, ort) values ('ZF Schule A', 'Testort'), ('ZF Schule B', 'Testort');
select id as schule_a from schulen where name = 'ZF Schule A' \gset
select id as schule_b from schulen where name = 'ZF Schule B' \gset
create function pg_temp.sa() returns uuid language sql stable as $$ select id from schulen where name = 'ZF Schule A' $$;
create function pg_temp.sb() returns uuid language sql stable as $$ select id from schulen where name = 'ZF Schule B' $$;
insert into schul_themenplan (schule_id, fach, klasse, position, thema_key, uv_titel, stunden, quelle_url) values
  (:'schule_a', 'mathematik', 9, 1, 'zf_t1', 'UV 1', 10, 'https://test.invalid'),
  (:'schule_a', 'mathematik', 9, 2, 'zf_t2', 'UV 2', 10, 'https://test.invalid'),
  (:'schule_a', 'mathematik', 9, 3, 'zf_t3', 'UV 3', 10, 'https://test.invalid'),
  (:'schule_b', 'mathematik', 9, 1, 'zf_t4', 'UV 1', 10, 'https://test.invalid');

-- Aufgabe anlegen: Skill, Text, Typ, Status (ready über task_status_set wie im Bestand).
create function pg_temp.aufgabe(p_skill text, p_text text, p_typ text default 'NUMERIC', p_status text default 'ready',
                                 p_pilot boolean default true)
returns uuid language plpgsql as $$
declare v uuid;
begin
  insert into tasks (cluster_id, content_type, input_type, status, question, source, source_ref, skill_key,
                     sondierrang, class_level, afb, curriculum_grade, pruef_pilot)
  values ((select c.id from skill_clusters c join subjects sub on sub.id = c.subject_id
            where sub.name = 'Mathematik' order by c.sort_order limit 1),
          'exercise', p_typ, 'draft', p_text, 'test', 'zf-' || gen_random_uuid(), p_skill, 1, 9, 'I', 9, p_pilot)
  returning id into v;
  insert into task_solutions (task_id, correct_answers) values (v, '["5"]');
  if p_status = 'ready' then perform public.task_status_set(v, 'ready'); end if;
  return v;
end $$;

-- ============================================================================
-- 1) Pakete
-- ============================================================================
select results_eq(
  $$select paket_nr, quelle, quartal, thema_keys from lsa_pakete(9) where schule = 'ZF Schule A' order by paket_nr$$,
  $$values (1, 'geschaetzt', 1, array['zf_t1']), (2, 'geschaetzt', 3, array['zf_t2']), (3, 'geschaetzt', 4, array['zf_t3'])$$,
  '1: drei geschätzte Pakete, Quartal nach der Mitte (1/6, 1/2, 5/6)');

-- ============================================================================
-- 2) Skills je Paket
-- ============================================================================
select results_eq(
  $$select skill_key, teil, pflicht from lsa_paket_skills(pg_temp.sa(), 9, 2) where fall = 'A' order by skill_key$$,
  $$values ('zf_d1', 'tiefe', false), ('zf_e1', 'voraussetzung', true), ('zf_e2', 'einstieg', true),
           ('zf_hoch', 'voraussetzung', true), ('zf_v1', 'tiefe', false)$$,
  '2a: Fall A = Einstieg, eine Kante Voraussetzung, Rest Tiefe (ohne Klassengrenze)');
select results_eq(
  $$select skill_key, teil, pflicht from lsa_paket_skills(pg_temp.sa(), 9, 2) where fall = 'B' order by skill_key$$,
  $$values ('zf_d1', 'rand_tiefe', false), ('zf_e1', 'rand', true), ('zf_q', 'rand', true),
           ('zf_v1', 'rand_tiefe', false)$$,
  '2b: Fall B = Rand (zf_s3 aus späterem Thema → dessen Rand zf_q), zf_hoch über der Klasse fehlt');
select is((select count(*)::int from lsa_paket_skills(pg_temp.sa(), 9, 3) where fall = 'A'), 0,
  '2c: Thema ohne Einstieg hat keinen Fall-A-Teil');

-- ============================================================================
-- 3) Ampel
-- ============================================================================
select is((select ampel from lsa_paket_status(pg_temp.sa(), 9, 1)), 'rot', '3a: ohne Aufgaben rot');
-- Paket 1: Pflicht = zf_e1 (Einstieg), zf_v1 (Voraussetzung, Rand); Tiefe = zf_d1.
select pg_temp.aufgabe('zf_e1', 'Text E1 eins'), pg_temp.aufgabe('zf_e1', 'Text E1 zwei'),
       pg_temp.aufgabe('zf_v1', 'Text V1 eins'), pg_temp.aufgabe('zf_v1', 'Text V1 zwei');
select results_eq($$select ampel, fehlende_pflicht_skills, fehlende_skills, fehlende_texte, hat_einstieg
                      from lsa_paket_status(pg_temp.sa(), 9, 1)$$,
  $$values ('gelb', 0, 1, 2, true)$$, '3b: Pflicht erfüllt, Tiefe fehlt → gelb (zf_d1 fehlen 2 Texte)');
select pg_temp.aufgabe('zf_d1', 'Text D1 eins');
select pg_temp.aufgabe('zf_d1', 'Text D1 eins');  -- gleicher Text: kein zweiter Schlüssel
select is((select ampel from lsa_paket_status(pg_temp.sa(), 9, 1)), 'gelb', '3c: gleicher Text zählt einmal');
select pg_temp.aufgabe('zf_d1', 'Text D1 zwei', 'MC');
select is((select ampel from lsa_paket_status(pg_temp.sa(), 9, 1)), 'gruen', '3d: alles erfüllt + Einstieg → grün');
select results_eq($$select texte_im_pool, ohne_mc_im_pool, erfuellt from lsa_skill_bereit('zf_d1')$$,
  $$values (2, 2, true)$$, '3e: lsa_skill_bereit zählt Texte und Nicht-MC');
select is((select ampel from lsa_paket_status(pg_temp.sa(), 9, 3)), 'rot', '3f: ohne Einstieg rot');
select is((select hat_einstieg from lsa_paket_status(pg_temp.sa(), 9, 3)), false, '3g: hat_einstieg false');

-- ============================================================================
-- 4) Stellschraube
-- ============================================================================
select is((select ampel from lsa_paket_status(pg_temp.sb(), 9, 1)), 'rot', '4a: zf_x ohne Aufgabe rot');
select pg_temp.aufgabe('zf_x', 'Text X eins');
select is((select ampel from lsa_paket_status(pg_temp.sb(), 9, 1)), 'rot', '4b: ein Text reicht bei 2 nicht');
update session_einstellungen set wert = '1' where schluessel = 'lsa_regel_texte';
select is((select ampel from lsa_paket_status(pg_temp.sb(), 9, 1)), 'gruen', '4c: lsa_regel_texte = 1 → grün');
update session_einstellungen set wert = '2' where schluessel = 'lsa_regel_texte';
select is((select ampel from lsa_paket_status(pg_temp.sb(), 9, 1)), 'rot', '4d: zurück auf 2 → rot');

-- ============================================================================
-- 5) Bestätigte Folge ersetzt die geschätzten Pakete
-- ============================================================================
insert into schul_klassenarbeiten (schule_id, klasse, schuljahr, nr, thema_keys, datum, bestaetigt_von)
values (:'schule_a', 9, lsa_schuljahr_heute(), 1, array['zf_t1', 'zf_t2'],
        make_date(left(lsa_schuljahr_heute(), 4)::int + 1, 2, 10), :'admin_uid');
select results_eq(
  $$select paket_nr, quelle, quartal, thema_keys from lsa_pakete(9) where schule = 'ZF Schule A'$$,
  $$values (1, 'bestaetigt', 3, array['zf_t1', 'zf_t2'])$$,
  '5a: bestätigte Arbeit ersetzt die drei geschätzten (Datum 10.2. → Quartal 3)');
select is((select quelle from lsa_abdeckung(9) where schule = 'ZF Schule A'), 'bestaetigt', '5b: Übersicht zeigt bestaetigt');
select is((select count(*)::int from lsa_paket_skills(pg_temp.sa(), 9, 1) where fall = 'A' and teil = 'einstieg'), 2,
  '5c: zwei Themen → beide Einstiege');
delete from schul_klassenarbeiten where schule_id = :'schule_a';
select is((select count(*)::int from lsa_pakete(9) where schule = 'ZF Schule A'), 3, '5d: ohne Bestätigung wieder geschätzt');

-- ============================================================================
-- 6) Fokus in pruef_ziel_liste
-- ============================================================================
-- Fehlend mit Entwurf: zf_q (Schule A, Pakete 1–2 … nur Paket 2 Fall B) und zf_x (Schule B, ein Paket, Quartal 3).
select pg_temp.aufgabe('zf_q', 'Text Q eins', 'NUMERIC', 'draft'), pg_temp.aufgabe('zf_q', 'Text Q zwei', 'NUMERIC', 'draft');
select pg_temp.aufgabe('zf_x', 'Text X zwei', 'NUMERIC', 'draft');
-- Schule A bekommt einen weiteren Plan in Klasse 8 mit Thema zf_t2, damit zf_q dort mehr Pakete hat.
insert into schul_themenplan (schule_id, fach, klasse, position, thema_key, uv_titel, stunden, quelle_url)
values (:'schule_a', 'mathematik', 10, 1, 'zf_t2', 'UV 10', 10, 'https://test.invalid');
select is((select skill_key from pruef_ziel_liste(false, 3) where abschnitt = 'gezielt' order by sort limit 1), 'zf_q',
  '6a: ohne Fokus zuerst der größere Hebel (zf_q)');
insert into schule_fokus (schule_id) values (:'schule_b');
select is((select skill_key from pruef_ziel_liste(false, 3) where abschnitt = 'gezielt' order by sort limit 1), 'zf_x',
  '6b: Fokus-Schule im Quartal zuerst (zf_x)');
select is((select fokus_treffer from pruef_ziel_liste(false, 3) where abschnitt = 'gezielt' and skill_key = 'zf_x'), 1, '6c: fokus_treffer = 1');
select is((select count(*)::int from pruef_ziel_liste(true, null) where abschnitt = 'gezielt' and skill_key = 'zf_q'), 0,
  '6d: nur Fokus → zf_q (nur Schule A) fällt heraus');

-- ============================================================================
-- 7) Vorschläge: kein Schlüssel aus dem Pool, höchstens fehlende_texte + 1
-- ============================================================================
select pg_temp.aufgabe('zf_x', 'Text X eins', 'NUMERIC', 'draft');  -- gleicher Text wie die ready-Aufgabe
select is((select count(*)::int from pruef_ziel_liste() z cross join unnest(z.task_ids) i join tasks t on t.id = i
            where z.abschnitt = 'gezielt' and z.skill_key = 'zf_x' and t.question = 'Text X eins'), 0, '7a: Entwurf mit Pool-Text nie vorgeschlagen');
select is((select cardinality(task_ids) from pruef_ziel_liste() where abschnitt = 'gezielt' and skill_key = 'zf_x'), 1,
  '7b: zf_x fehlt 1 Text, ein neuer Entwurf da → 1 Vorschlag');
select pg_temp.aufgabe('zf_q', 'Text Q drei', 'NUMERIC', 'draft'), pg_temp.aufgabe('zf_q', 'Text Q vier', 'NUMERIC', 'draft');
select is((select cardinality(task_ids) from pruef_ziel_liste() where abschnitt = 'gezielt' and skill_key = 'zf_q'), 3,
  '7c: zf_q fehlen 2 Texte, 4 Entwürfe → 2 + 1 Reserve');
select ok(not exists (select 1 from pruef_ziel_liste() z where z.abschnitt = 'gezielt' and
                       cardinality(z.task_ids) + cardinality(z.freigabe_ids) > z.fehlende_texte + 1),
  '7d: nie mehr als fehlende_texte + 1 je Skill');
update pruef_einstellungen set nur_pilot = true;  -- Pilot an (Stand vor 20261109123016)
select pg_temp.aufgabe('zf_e2', 'Text E2 eins', 'NUMERIC', 'draft', false) as e2_draft \gset
select is((select pilot_fehlt from pruef_ziel_liste() where abschnitt = 'gezielt' and skill_key = 'zf_e2'),
          array[:'e2_draft'::uuid], '7e: Entwurf außerhalb des Pilots steht unter pilot_fehlt');
update pruef_einstellungen set nur_pilot = false;  -- O2: aus
select is((select pilot_fehlt from pruef_ziel_liste() where abschnitt = 'gezielt' and skill_key = 'zf_e2'),
          '{}'::uuid[], '7f: nur_pilot aus → pilot_fehlt leer');

-- ============================================================================
-- 8) Sammelfreigabe mit Gate, Lena darf nicht
-- ============================================================================
select task_ids[1] as q1, task_ids[2] as q2 from pruef_ziel_liste() where abschnitt = 'gezielt' and skill_key = 'zf_q' \gset
select set_config('request.jwt.claims', json_build_object('sub', :'lena_uid', 'role', 'authenticated')::text, true);
select pruef_entscheiden(:'q1', (select pruef_version from tasks where id = :'q1'), 'passt');
select pruef_entscheiden(:'q2', (select pruef_version from tasks where id = :'q2'), 'passt');
select throws_ok(format('select pruef_sammel(%L, array[%L::uuid], %L, false)', 'freigeben', :'q1', '{}'), '42501', null,
  '8a: Lena kann nicht sammelfreigeben');
select set_config('request.jwt.claims', json_build_object('sub', :'admin_uid', 'role', 'authenticated')::text, true);
select is((select cardinality(freigabe_ids) from pruef_ziel_liste() where abschnitt = 'gezielt' and skill_key = 'zf_q'), 2,
  '8b: Lenas „passt“ steht unter freigabe_ids');
update tasks set curriculum_grade = null where id = :'q2';   -- q2 scheitert jetzt am Gate
select is((pruef_sammel('freigeben', array[:'q1'::uuid, :'q2'::uuid], '{}', false)) -> 'betrifft',
          jsonb_build_array(:'q1'), '8c: nur q1 freigegeben');
select is((select status from tasks where id = :'q2'), 'review', '8d: q2 bleibt review (Gate)');

-- ============================================================================
-- 9) Rechte und Zwischenspeicher
-- ============================================================================
select set_config('request.jwt.claims', json_build_object('sub', :'kind_uid', 'role', 'authenticated')::text, true);
select throws_ok($$select * from lsa_abdeckung()$$, '42501', null, '9a: Kind darf nicht');
select set_config('request.jwt.claims', json_build_object('sub', :'lena_uid', 'role', 'authenticated')::text, true);
select lives_ok($$select * from pruef_ziel_liste()$$, '9b: Lena darf die Prüfliste lesen');
select set_config('request.jwt.claims', json_build_object('sub', :'admin_uid', 'role', 'authenticated')::text, true);
select is((select veraltet from lsa_paket_cache_stand), true, '9c: Schreiben in den Plan markiert den Speicher veraltet');
select is(lsa_abdeckung_auffrischen(), true, '9d: auffrischen rechnet neu');
select is(lsa_abdeckung_auffrischen(), false, '9e: frisch → nichts zu tun');
select is((select count(*)::int from (
             select schule_id, klasse, paket_nr, skill_key, fall, teil, pflicht from lsa_paket_skills_roh(lsa_schuljahr_heute())
             except select schule_id, klasse, paket_nr, skill_key, fall, teil, pflicht from lsa_paket_skill_cache) x), 0,
  '9f: Zwischenspeicher = Live-Rechnung');

select * from finish();
rollback;
