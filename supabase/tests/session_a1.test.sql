-- ============================================================================
-- Session-Rahmen P1, Paket A1 — Lernpfad und Mastery auf skill_key.
--
-- Zusagen (Bauauftrag, Prompt A1, TESTS):
--   1) lernpfad_aus_lsa legt Zeilen aus den Urteilen an, ohne Microskill-
--      Tabellen zu aendern.
--   2) Zwei Belege ohne Hinweis in derselben Session → kein Kandidat; in einer
--      spaeteren Session → kandidat.
--   3) Belege mit Hinweis zaehlen nicht.
--   4) mastery_entscheiden: fremder Coach / Schuelerkonto → 42501; ohne
--      kandidat → abgelehnt; vertagt ohne Grund → abgelehnt; gemeistert →
--      stand_coach gesetzt, stand_system unveraendert.
--   5) ziel_fertigkeiten: Einstieg plus fehlende Voraussetzungen in
--      Graph-Reihenfolge.
--   6) pfad_tiefer aktiviert eine Voraussetzung.
--   7) skill_pruefung liefert keine Entwuerfe.
--   Dazu: naechste_luecke vor und nach der Uebernahme, mein_lernpfad.
--
-- Eigene Fixtures (zz_a1_*). Vertrag und Buchung werden mit abgeschalteten
-- Triggern angelegt (session_replication_role), damit der Test nicht vom
-- Vertragsablauf abhaengt; akte_aktiv liest sie wie echte.
--
-- Skill-Graph (A setzt B voraus: A → B):
--   zz_a1_thema2 → zz_a1_einstieg → zz_a1_vor    → zz_a1_basis
--                                 → zz_a1_sicher → zz_a1_basis
--   Thema zz_a1_t: Einstieg zz_a1_einstieg, Heimat von einstieg und thema2.
--
-- Lauf: npx supabase test db
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(59);

\set admin_uid  'a1a1a1a1-0001-4000-8000-000000000001'
\set coach_uid  'a1a1a1a1-0001-4000-8000-000000000002'
\set fremd_uid  'a1a1a1a1-0001-4000-8000-000000000003'
\set kind_uid   'a1a1a1a1-0001-4000-8000-000000000004'
\set lead_id    'a1a1a1a1-0002-4000-8000-000000000001'
\set kind       'a1a1a1a1-0003-4000-8000-000000000001'
\set lsa        'a1a1a1a1-0004-4000-8000-000000000001'
\set s1         'a1a1a1a1-0005-4000-8000-000000000001'
\set s2         'a1a1a1a1-0005-4000-8000-000000000002'
\set sf         'a1a1a1a1-0005-4000-8000-000000000003'
\set s3         'a1a1a1a1-0005-4000-8000-000000000004'
\set s4         'a1a1a1a1-0005-4000-8000-000000000005'
\set ohne       'a1a1a1a1-0003-4000-8000-000000000002'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid', 'a1-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach_uid', 'a1-coach@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'fremd_uid', 'a1-fremd@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'kind_uid',  'a1-kind@test.local',  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values
  (:'admin_uid', 'a1-admin@test.local', 'admin',   'A1 Admin'),
  (:'coach_uid', 'a1-coach@test.local', 'coach',   'A1 Coach'),
  (:'fremd_uid', 'a1-fremd@test.local', 'coach',   'A1 Fremd'),
  (:'kind_uid',  'a1-kind@test.local',  'student', 'A1 Kind');

insert into skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe) values
  ('zz_a1_basis',     'A1 Basis',     'mathematik', 6, 1),
  ('zz_a1_vor',       'A1 Vor',       'mathematik', 7, 2),
  ('zz_a1_sicher',    'A1 Sicher',    'mathematik', 7, 2),
  ('zz_a1_einstieg',  'A1 Einstieg',  'mathematik', 9, 3),
  ('zz_a1_thema2',    'A1 Thema2',    'mathematik', 9, 4),
  ('zz_a1_fokus',     'A1 Fokus',     'mathematik', 5, 1),
  ('zz_a1_verworfen', 'A1 Verworfen', 'mathematik', 5, 1),
  ('zz_a1_vertag',    'A1 Vertagt',   'mathematik', 6, 1);
insert into skill_kante (skill_key, voraussetzt_skill_key) values
  ('zz_a1_vor', 'zz_a1_basis'), ('zz_a1_sicher', 'zz_a1_basis'),
  ('zz_a1_einstieg', 'zz_a1_vor'), ('zz_a1_einstieg', 'zz_a1_sicher'),
  ('zz_a1_thema2', 'zz_a1_einstieg');
insert into themen (thema_key, fach, klasse, stufe, label, sort) values
  ('zz_a1_t', 'mathematik', 9, 'zweite', 'A1 Thema', 9101);
insert into thema_einstieg (thema_key, skill_key) values ('zz_a1_t', 'zz_a1_einstieg');
insert into skill_thema (skill_key, thema_key) values
  ('zz_a1_einstieg', 'zz_a1_t'), ('zz_a1_thema2', 'zz_a1_t');

set local session_replication_role = replica;
insert into leads (id, full_name, class_level, subjects, status)
values (:'lead_id', 'A1 Kind', 9, '{Mathematik}', 'contacted');
insert into students (id, profile_id, class_level, is_provisional, lead_id)
values (:'kind', :'kind_uid', 9, true, :'lead_id');
-- Zweites Kind ohne Vertrag (Lead-Stand): Coaches sehen seinen Lernpfad nicht.
insert into leads (id, full_name, class_level, subjects, status)
values ('a1a1a1a1-0002-4000-8000-000000000002', 'A1 Ohne', 8, '{Mathematik}', 'contacted');
insert into students (id, class_level, is_provisional, lead_id)
values (:'ohne', 8, true, 'a1a1a1a1-0002-4000-8000-000000000002');
insert into lernpfad (student_id, skill_key, stand_system, quelle) values (:'ohne', 'zz_a1_basis', 'sicher', 'lsa');
insert into vertraege (lead_id, student_id, status, vertrag_status, abgeschlossen_am,
                       vertragsbeginn, vertrag_ende, widerruf_bis)
values (:'lead_id', :'kind', 'abgeschlossen', 'aktiv',
        (date_trunc('month', current_date) - interval '2 months')::date,
        (date_trunc('month', current_date) - interval '1 month')::date,
        (date_trunc('month', current_date) + interval '11 months')::date - 1,
        (date_trunc('month', current_date) - interval '1 month')::date + 14);
insert into coaching_sessions (id, coach_id, scheduled_at, status) values
  (:'s1', :'coach_uid', now() - interval '7 days', 'done'),
  (:'s2', :'coach_uid', now(), 'upcoming'),
  (:'sf', :'fremd_uid', now(), 'upcoming'),
  (:'s3', :'coach_uid', now() + interval '7 days', 'upcoming'),
  (:'s4', :'coach_uid', now() + interval '14 days', 'upcoming');
insert into session_students (session_id, student_id, attendance) values
  (:'s1', :'kind', 'present'), (:'s2', :'kind', 'present'), (:'s3', :'kind', 'planned'), (:'s4', :'kind', 'present');
set local session_replication_role = origin;

insert into lsa_sessions (id, student_id, subject, grade, status, completed_at, modus)
values (:'lsa', :'kind', 'mathematik', 9, 'completed', now() - interval '14 days', 'adaptiv');
insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl) values
  (:'lsa', 'zz_a1_basis',    'traegt',      true, false, 2),
  (:'lsa', 'zz_a1_vor',      'traegt_nicht', true, false, 2),
  (:'lsa', 'zz_a1_sicher',   'traegt',      true, false, 2),
  (:'lsa', 'zz_a1_einstieg', 'ungeprueft',  false, false, 0);
insert into student_focus_areas (student_id, skill_key, status, active, source) values
  (:'kind', 'zz_a1_fokus',     'vorgeschlagen', false, 'lsa'),
  (:'kind', 'zz_a1_verworfen', 'verworfen',     false, 'lsa');

create or replace function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
                     json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
end $$;

create temporary table micro_vorher as
  select (select md5(coalesce(string_agg(t::text, '|' order by t::text), '')) from student_competency_mastery t) as scm,
         (select md5(coalesce(string_agg(t::text, '|' order by t::text), '')) from microskills t) as ms;

-- naechste_luecke vor der Uebernahme: direkt aus den LSA-Urteilen
select pg_temp.act_as(:'coach_uid');
select results_eq(
  format($f$select skill_key, quelle from public.naechste_luecke(%L)$f$, :'kind'),
  $$values ('zz_a1_vor'::text, 'lsa'::text)$$,
  'naechste_luecke ohne Lernpfad: Luecke aus der LSA');

-- 1) Uebernahme ----------------------------------------------------------------
select pg_temp.act_as(:'kind_uid');
select throws_ok(format($f$select public.lernpfad_aus_lsa(%L)$f$, :'kind'),
  '42501', NULL, '1: Schuelerkonto darf nicht uebernehmen');

select pg_temp.act_as(:'coach_uid');
select is(
  public.lernpfad_aus_lsa(:'kind') ->> 'angelegt', '4',
  '1: Uebernahme legt vier Zeilen an (drei Urteile ohne ungeprueft, eine Fokus-Zeile)');
select results_eq(
  format($f$select skill_key, stand_system, quelle, stand_coach from lernpfad where student_id = %L order by skill_key$f$, :'kind'),
  $$values ('zz_a1_basis'::text, 'sicher'::text, 'lsa'::text, null::text),
           ('zz_a1_fokus', 'noch_nicht_sicher', 'lsa', null),
           ('zz_a1_sicher', 'sicher', 'lsa', null),
           ('zz_a1_vor', 'noch_nicht_sicher', 'lsa', null)$$,
  '1: traegt → sicher, traegt_nicht/Fokus → noch_nicht_sicher; ungeprueft und verworfen fehlen');
select is(public.lernpfad_aus_lsa(:'kind') ->> 'angelegt', '0', '1: zweiter Lauf ist idempotent');
select ok(
  (select scm = (select md5(coalesce(string_agg(t::text, '|' order by t::text), '')) from student_competency_mastery t)
      and ms = (select md5(coalesce(string_agg(t::text, '|' order by t::text), '')) from microskills t)
     from micro_vorher),
  '1: Microskill-Tabellen unveraendert');
select results_eq(
  format($f$select skill_key, quelle from public.naechste_luecke(%L)$f$, :'kind'),
  $$values ('zz_a1_vor'::text, 'lsa'::text)$$,
  'naechste_luecke nach der Uebernahme: unterste Luecke, Quelle LSA');

-- 5) Ziel der Stunde ---------------------------------------------------------
select results_eq(
  format($f$select reihenfolge, skill_key, rolle, stand from public.ziel_fertigkeiten(%L, 'zz_a1_t')$f$, :'kind'),
  $$values (1, 'zz_a1_sicher'::text, 'voraussetzung_sicher'::text, 'sicher'::text),
           (2, 'zz_a1_vor', 'voraussetzung', 'noch_nicht_sicher'),
           (3, 'zz_a1_einstieg', 'einstieg', 'offen'),
           (4, 'zz_a1_thema2', 'thema', 'offen')$$,
  '5: Einstieg plus fehlende Voraussetzungen in Graph-Reihenfolge (sichere Basis unter der Voraussetzung fehlt)');
select pg_temp.act_as(:'kind_uid');
select throws_ok(format($f$select * from public.ziel_fertigkeiten(%L, 'zz_a1_t')$f$, :'kind'),
  '42501', NULL, '5: Schuelerkonto liest ziel_fertigkeiten nicht');

-- 6) Pfad tiefer ---------------------------------------------------------------
select pg_temp.act_as(:'fremd_uid');
select throws_ok(format($f$select public.pfad_tiefer(%L, 'zz_a1_einstieg', %L)$f$, :'kind', :'sf'),
  '42501', NULL, '6: fremder Coach darf den Pfad nicht tiefer setzen');
select pg_temp.act_as(:'coach_uid');
select lives_ok(format($f$select public.lernpfad_beleg(%L, 'zz_a1_einstieg', %L, 'falsch', false)$f$, :'kind', :'s1'),
  '6: Beleg auf dem Einstieg macht ihn aktiv');
select is(public.pfad_tiefer(:'kind', 'zz_a1_einstieg', :'s1'), 'zz_a1_vor',
  '6: pfad_tiefer waehlt die noch nicht sichere Voraussetzung');
select results_eq(
  format($f$select skill_key, stand_system from lernpfad where student_id = %L and skill_key in ('zz_a1_vor','zz_a1_einstieg') order by 1$f$, :'kind'),
  $$values ('zz_a1_einstieg'::text, 'offen'::text), ('zz_a1_vor', 'aktiv')$$,
  '6: Voraussetzung aktiv, bisheriger Skill wartet');
select results_eq(
  format($f$select von, session_id, anlass, (am is not null) from lernpfad_protokoll where student_id = %L and aktion = 'pfad_tiefer'$f$, :'kind'),
  format($f$values (%L::uuid, %L::uuid, 'warmup'::text, true)$f$, :'coach_uid', :'s1'),
  '6: Pfad-Entscheidung protokolliert: wer, wann, Session, Anlass');
select throws_ok(format($f$select public.pfad_tiefer(%L, 'zz_a1_thema2', %L, null, 'irgendwas')$f$, :'kind', :'s1'),
  '22023', NULL, '6: unbekannter Anlass → abgelehnt, nichts protokolliert');
select results_eq(
  format($f$select skill_key, quelle from public.naechste_luecke(%L)$f$, :'kind'),
  $$values ('zz_a1_vor'::text, 'lsa'::text)$$,
  'naechste_luecke: aktiver Skill zuerst');

-- 2) Kandidat erst in einer spaeteren Session ------------------------------
select is(public.lernpfad_beleg(:'kind', 'zz_a1_vor', :'s1', 'richtig', false), 'aktiv', '2: erster Beleg → aktiv');
select is(public.lernpfad_beleg(:'kind', 'zz_a1_vor', :'s1', 'richtig', false), 'sicher',
  '2: zwei Belege ohne Hinweis in derselben Session → sicher, kein Kandidat');
select is(public.lernpfad_beleg(:'kind', 'zz_a1_vor', :'s2', 'richtig', false), 'sicher', '2: spaetere Session, ein Beleg → noch kein Kandidat');
select is(public.lernpfad_beleg(:'kind', 'zz_a1_vor', :'s2', 'richtig', false), 'kandidat',
  '2: zwei Belege ohne Hinweis in einer spaeteren Session → kandidat');
select is((select jsonb_array_length(belege) from lernpfad where student_id = :'kind' and skill_key = 'zz_a1_vor'), 2,
  '2: belege verdichtet je Session');

select pg_temp.act_as(:'kind_uid');
select is((select stand from public.mein_lernpfad() where skill_key = 'zz_a1_vor'), 'sicher',
  '2: Kind sieht einen Mastery-Kandidaten als sicher (Entscheidung 6)');
select pg_temp.act_as(:'coach_uid');

-- 3) Belege mit Hinweis zaehlen nicht --------------------------------------
select public.lernpfad_beleg(:'kind', 'zz_a1_basis', :'s1', 'richtig', false) \g /dev/null
select public.lernpfad_beleg(:'kind', 'zz_a1_basis', :'s1', 'richtig', false) \g /dev/null
select public.lernpfad_beleg(:'kind', 'zz_a1_basis', :'s2', 'richtig', true) \g /dev/null
select isnt(public.lernpfad_beleg(:'kind', 'zz_a1_basis', :'s2', 'richtig', true), 'kandidat',
  '3: zwei richtige Belege mit Hinweis in der spaeteren Session → kein Kandidat');
select pg_temp.act_as(:'fremd_uid');
select throws_ok(format($f$select public.lernpfad_beleg(%L, 'zz_a1_basis', %L, 'richtig', false)$f$, :'kind', :'s1'),
  '42501', NULL, '3: fremder Coach bucht keinen Beleg');

select pg_temp.act_as(:'coach_uid');
select throws_ok(format($f$select public.lernpfad_beleg(%L, 'zz_a1_basis', %L, 'richtig', false)$f$, :'kind', :'s3'),
  'P0001', NULL, '3: kein Beleg aus einer Session, in der das Kind nicht anwesend ist (Entscheidung 4)');
select pg_temp.act_as(:'fremd_uid');

-- 4) Mastery-Entscheidung ----------------------------------------------------
select throws_ok(format($f$select public.mastery_entscheiden(%L, 'zz_a1_vor', 'gemeistert', null, %L)$f$, :'kind', :'sf'),
  '42501', NULL, '4: fremder Coach (eigene Session ohne das Kind) → 42501');
select throws_ok(format($f$select public.mastery_entscheiden(%L, 'zz_a1_vor', 'gemeistert', null, %L)$f$, :'kind', :'s2'),
  '42501', NULL, '4: fremder Coach mit fremder Session → 42501');
select pg_temp.act_as(:'kind_uid');
select throws_ok(format($f$select public.mastery_entscheiden(%L, 'zz_a1_vor', 'gemeistert', null, %L)$f$, :'kind', :'s2'),
  '42501', NULL, '4: Schuelerkonto → 42501');
select pg_temp.act_as(:'coach_uid');
select throws_ok(format($f$select public.mastery_entscheiden(%L, 'zz_a1_basis', 'gemeistert', null, %L)$f$, :'kind', :'s2'),
  'P0001', NULL, '4: ohne kandidat → abgelehnt');
select throws_ok(format($f$select public.mastery_entscheiden(%L, 'zz_a1_vor', 'vertagt', '  ', %L)$f$, :'kind', :'s2'),
  '22023', NULL, '4: vertagt ohne Grund → abgelehnt');
select lives_ok(format($f$select public.mastery_entscheiden(%L, 'zz_a1_vor', 'gemeistert', null, %L)$f$, :'kind', :'s2'),
  '4: Coach der Session bucht gemeistert');
select results_eq(
  format($f$select stand_system, stand_coach, coach_von, coach_session_id from lernpfad where student_id = %L and skill_key = 'zz_a1_vor'$f$, :'kind'),
  format($f$values ('kandidat'::text, 'gemeistert'::text, %L::uuid, %L::uuid)$f$, :'coach_uid', :'s2'),
  '4: stand_coach gesetzt, stand_system unveraendert');
select results_eq(
  format($f$select anlass, von, session_id from lernpfad_protokoll where student_id = %L and aktion = 'mastery'$f$, :'kind'),
  format($f$values ('pruefung'::text, %L::uuid, %L::uuid)$f$, :'coach_uid', :'s2'),
  '4: Entscheidung protokolliert (Anlass pruefung)');

-- 4b) Vertagen und neuer Vorschlag (Rasit 06.10.) ------------------------------
select public.lernpfad_beleg(:'kind', 'zz_a1_vertag', :'s1', 'richtig', false) \g /dev/null
select public.lernpfad_beleg(:'kind', 'zz_a1_vertag', :'s1', 'richtig', false) \g /dev/null
select public.lernpfad_beleg(:'kind', 'zz_a1_vertag', :'s2', 'richtig', false) \g /dev/null
select is(public.lernpfad_beleg(:'kind', 'zz_a1_vertag', :'s2', 'richtig', false), 'kandidat', '4b: Kandidat erreicht');
select results_eq(format($f$select skill_key from public.mastery_vorschlaege(%L)$f$, :'kind'),
  $$values ('zz_a1_vertag'::text)$$, '4b: Kandidat ohne Entscheidung ist vorgeschlagen (gemeisterter fehlt)');
select lives_ok(format($f$select public.mastery_entscheiden(%L, 'zz_a1_vertag', 'vertagt', 'Ging nur mit Hilfe', %L)$f$, :'kind', :'s2'),
  '4b: Coach vertagt mit Grund');
select is((select stand_system from lernpfad where student_id = :'kind' and skill_key = 'zz_a1_vertag'), 'kandidat',
  '4b: nach vertagt bleibt der Kandidat Kandidat');
select is((select count(*)::int from public.mastery_vorschlaege(:'kind')), 0, '4b: nach vertagt nicht mehr vorgeschlagen');
select throws_ok(format($f$select public.mastery_entscheiden(%L, 'zz_a1_vertag', 'gemeistert', null, %L)$f$, :'kind', :'s2'),
  'P0001', NULL, '4b: ohne neuen Vorschlag keine erneute Entscheidung');
select public.lernpfad_beleg(:'kind', 'zz_a1_vertag', :'s2', 'richtig', false) \g /dev/null
select public.lernpfad_beleg(:'kind', 'zz_a1_vertag', :'s2', 'richtig', false) \g /dev/null
select ok(not public.lernpfad_pruefung_faellig(:'kind', 'zz_a1_vertag'),
  '4b: weitere Belege in derselben Session schlagen nicht neu vor');
select public.lernpfad_beleg(:'kind', 'zz_a1_vertag', :'s4', 'richtig', true) \g /dev/null
select public.lernpfad_beleg(:'kind', 'zz_a1_vertag', :'s4', 'falsch', false) \g /dev/null
select public.lernpfad_beleg(:'kind', 'zz_a1_vertag', :'s4', 'richtig', false) \g /dev/null
select ok(not public.lernpfad_pruefung_faellig(:'kind', 'zz_a1_vertag'),
  '4b: spaetere Session mit nur einem Beleg ohne Hinweis (einer mit Hinweis) → noch kein Vorschlag');
select is((select stand_system from lernpfad where student_id = :'kind' and skill_key = 'zz_a1_vertag'), 'kandidat',
  '4b: ein Fehlversuch nimmt den Kandidaten nicht zurueck');
select public.lernpfad_beleg(:'kind', 'zz_a1_vertag', :'s4', 'richtig', false) \g /dev/null
select results_eq(format($f$select skill_key, stand_coach from public.mastery_vorschlaege(%L)$f$, :'kind'),
  $$values ('zz_a1_vertag'::text, 'vertagt'::text)$$,
  '4b: neue Belege nach Entscheidung 16 in einer spaeteren Session → wieder vorgeschlagen');
select lives_ok(format($f$select public.mastery_entscheiden(%L, 'zz_a1_vertag', 'gemeistert', null, %L)$f$, :'kind', :'s4'),
  '4b: Coach bestaetigt in der spaeteren Session');
select public.lernpfad_beleg(:'kind', 'zz_a1_vertag', :'s4', 'falsch', false) \g /dev/null
select public.lernpfad_beleg(:'kind', 'zz_a1_vertag', :'s4', 'falsch', false) \g /dev/null
select results_eq(
  format($f$select stand_system, stand_coach from lernpfad where student_id = %L and skill_key = 'zz_a1_vertag'$f$, :'kind'),
  $$values ('kandidat'::text, 'gemeistert'::text)$$,
  '4b: gemeistert nimmt das System nie zurueck, auch nicht nach Fehlversuchen');
select throws_ok(format($f$select public.mastery_entscheiden(%L, 'zz_a1_vertag', 'vertagt', 'x', %L)$f$, :'kind', :'s4'),
  'P0001', NULL, '4b: gemeistert ist endgueltig (Ruecknahme kommt mit C2)');

-- Kind liest den eigenen Stand: gemeistert nur aus stand_coach, nie „kandidat“
select pg_temp.act_as(:'kind_uid');
select is((select stand from public.mein_lernpfad() where skill_key = 'zz_a1_vor'), 'gemeistert',
  'Kind sieht gemeistert nach Coach-Bestaetigung');
select is((select count(*)::int from public.mein_lernpfad() where stand = 'kandidat'), 0,
  'Kind sieht nie den Zustand kandidat');
set local role authenticated;
select is((select count(*)::int from lernpfad), 0, '9: Kind liest die Tabelle lernpfad nicht direkt (RLS)');
reset role;
select pg_temp.act_as(:'coach_uid');
set local role authenticated;
select is((select count(*)::int from lernpfad where student_id = :'kind'), 6,
  '9: Coach liest den Lernpfad eines Kindes mit laufendem Vertrag direkt (RLS)');
select is((select count(*)::int from lernpfad where student_id = :'ohne'), 0,
  '9: Coach liest keinen Lernpfad eines Kindes ohne laufenden Vertrag (RLS)');
reset role;
select throws_ok(format($f$select * from public.naechste_luecke(%L)$f$, :'ohne'),
  '42501', NULL, '9: Coach ruft naechste_luecke nicht fuer ein Kind ohne Vertrag');
select pg_temp.act_as(:'kind_uid');

-- 7) Pruefgespraech --------------------------------------------------------
insert into skill_pruefung (skill_key, frage, erwartung, kriterium, status, quelle) values
  ('zz_a1_vor', 'Frage Entwurf',  'E', 'K', 'entwurf',     'ki'),
  ('zz_a1_vor', 'Frage geprueft', 'E', 'K', 'geprueft',    'ki'),
  ('zz_a1_vor', 'Frage frei',     'E', 'K', 'freigegeben', 'mensch');
select throws_ok($$select * from public.skill_pruefung_lesen('zz_a1_vor')$$,
  '42501', NULL, '7: Schuelerkonto liest keine Pruefgespraeche');
select pg_temp.act_as(:'coach_uid');
select results_eq($$select frage from public.skill_pruefung_lesen('zz_a1_vor')$$,
  $$values ('Frage frei'::text)$$,
  '7: nur freigegebene Pruefgespraeche, keine Entwuerfe');

-- Rechte (Consensus-Check): interne Helfer nicht aufrufbar, kein Schreiben, nichts fuer anon
select ok(not bool_or(has_function_privilege(r, f, 'execute')),
  'Rechte: interne Helfer sind fuer anon und authenticated nicht aufrufbar')
  from unnest(array['anon','authenticated']) r,
       unnest(array['public.lernpfad_beleg_core(uuid,text,uuid,text,boolean)',
                    'public.lernpfad_stellschraube(text,uuid)',
                    'public.lernpfad_coach_der_session(uuid,uuid)',
                    'public.lernpfad_lsa_urteile(uuid)',
                    'public.lernpfad_pruefung_faellig(uuid,text)']) f;
select ok(not bool_or(has_function_privilege('anon', f, 'execute')),
  'Rechte: anon ruft keine Lernpfad-Funktion auf')
  from unnest(array['public.lernpfad_beleg(uuid,text,uuid,text,boolean)',
                    'public.lernpfad_aus_lsa(uuid)', 'public.naechste_luecke(uuid)',
                    'public.ziel_fertigkeiten(uuid,text)', 'public.pfad_tiefer(uuid,text,uuid,text,text)',
                    'public.mastery_vorschlaege(uuid)',
                    'public.mastery_entscheiden(uuid,text,text,text,uuid)',
                    'public.skill_pruefung_lesen(text)', 'public.mein_lernpfad()',
                    'public.lernpfad_darf_lesen(uuid)']) f;
select ok(not bool_or(has_table_privilege(r, t, p)),
  'Rechte: kein INSERT/UPDATE/DELETE/TRUNCATE fuer anon und authenticated, kein SELECT fuer anon')
  from unnest(array['public.lernpfad','public.lernpfad_belege','public.lernpfad_protokoll','public.skill_pruefung']) t,
       (values ('anon','select'), ('anon','insert'), ('authenticated','insert'), ('authenticated','update'),
               ('authenticated','delete'), ('authenticated','truncate')) as x(r, p);
select pg_temp.act_as(:'coach_uid');
set local role authenticated;
select throws_ok($$insert into lernpfad (student_id, skill_key, quelle) values ('a1a1a1a1-0003-4000-8000-000000000001', 'zz_a1_thema2', 'coach')$$,
  '42501', NULL, 'Rechte: Coach schreibt nicht direkt in lernpfad');
select is((select count(*)::int from skill_pruefung), 0, 'Rechte: Coach liest skill_pruefung nicht direkt (nur ueber die Funktion)');
reset role;

select * from finish();
rollback;
