-- ============================================================================
-- M1 Phase 2 · Session-Muster nach Sessions (Migration 20261029083054)
--   a) Standardplan ohne Kind: Zuordnung wie Konzept §2.2 (Session 1 PAR-1/2/5 + KO-1, EIN-1; Session 2 PAR-3/4,
--      SCH-1–4). QW-1 landet in Session 4: laut skill_kante braucht nur gleichung_quadr_wurzel die Quadratwurzel.
--   b) Testkind mit aktiver Reihe: Zuordnung folgt dessen wirksamem Plan (Coach verschiebt scheitel in Session 3).
--   c) bauform_freigeben mit p_schluessel gibt genau diese Muster frei; alte Signatur bleibt aufrufbar.
--   d) ohne Prüfrecht 42501, Kind ohne Reihe P0002.
--   e) bauform_plan_kinder (Migration 20261029083510): nur Kinder mit aktiver Reihe, nur mit Prüfrecht.
-- Am Ende rollback.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(25);

\set lena  'dddd0001-0000-4000-8000-0000000000b1'
\set admin 'dddd0001-0000-4000-8000-0000000000a1'
\set coach 'dddd0001-0000-4000-8000-0000000000c1'
insert into auth.users (id, email, instance_id, aud, role) values
  (:'lena', 'm1-lena@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'admin', 'm1-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach', 'm1-coach@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name, darf_pruefen) values
  (:'lena', 'm1-lena@test.local', 'coach', 'M1 Lena', true),
  (:'admin', 'm1-admin@test.local', 'admin', 'M1 Admin', false),
  (:'coach', 'm1-coach@test.local', 'coach', 'M1 Coach', false);
create function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;
-- Schlüssel einer Session als sortierte Liste
create function pg_temp.sess(p_kind uuid, p_nr int) returns text language sql as $$
  select string_agg(schluessel, ' ' order by schluessel) from public.bauform_pruef_plan(p_kind) where session_nr = p_nr
$$;

-- ── a) Standardplan ─────────────────────────────────────────────────────────
select pg_temp.act_as(:'lena');
select is((select count(*)::int from bauform_pruef_plan()), (select count(*)::int from bauform_pruef_liste()),
          'a1 dieselben Muster wie bauform_pruef_liste');
select is(pg_temp.sess(null, 1), 'EIN-1 KO-1 PAR-1 PAR-2 PAR-5', 'a2 Session 1: PAR-1, PAR-2, PAR-5, KO-1, EIN-1');
select is(pg_temp.sess(null, 2), 'PAR-3 PAR-4 SCH-1 SCH-2 SCH-3 SCH-4', 'a3 Session 2: PAR-3, PAR-4, SCH-1 bis SCH-4');
select is((select session_nr from bauform_pruef_plan() where schluessel = 'QW-1'), 4,
          'a4 QW-1 in Session 4 (skill_kante: nur Wurzelziehen braucht die Quadratwurzel)');
select is((select string_agg(schluessel, ' ' order by schluessel) from bauform_pruef_plan() where ist_voraussetzung),
          'AUS-1 BIN-1 BIN-2 EIN-1 GL-1 KO-1 QW-1', 'a5 sieben Voraussetzungs-Muster');
select is((select count(*)::int from bauform_pruef_plan() where session_nr is null), 0, 'a6 jedes Muster hat eine Session');
select is((select max(session_nr) from bauform_pruef_plan()), 7, 'a7 sieben Sessions mit Kernarbeit, die achte ist die Generalprobe');
select is((select array_agg(schluessel order by o) from bauform_pruef_plan() with ordinality x(bauform_id, schluessel, skill_key,
             skill_label, reihe, format, rollen, version, status, gruen, letzte_entscheidung, letzte_notiz, geprueft_am,
             session_nr, session_titel, kernidee_key, kernidee_titel, ist_voraussetzung, o) where session_nr = 1),
          array['EIN-1', 'KO-1', 'PAR-1', 'PAR-2', 'PAR-5'], 'a8 innerhalb der Session Voraussetzungen zuerst');
select is((select session_titel || ' | ' || kernidee_titel from bauform_pruef_plan() where schluessel = 'PAR-1'),
          'Normalparabel verschieben und strecken | Normalparabel: Wertetabelle, Symmetrie, Scheitel im Ursprung',
          'a9 Session-Titel aus den Skills, Kernidee-Titel');

-- ── b) Testkind mit aktiver Reihe ──────────────────────────────────────────
select pg_temp.act_as(:'admin');
select set_config('request.jwt.claims', json_build_object('role', 'service_role')::text, true);
insert into auth.users (id, email, instance_id, aud, role) values
  ('dddd0001-0000-4000-8000-0000000000d1', 'm1-kind@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values ('dddd0001-0000-4000-8000-0000000000d1', 'm1-kind@test.local', 'student', 'M1 Kind');
insert into students (profile_id, class_level, ist_test) values ('dddd0001-0000-4000-8000-0000000000d1', 9, true) returning id as kind \gset
insert into students (class_level, ist_test) values (9, true) returning id as ohne \gset
select pg_temp.act_as(:'admin');
select reihe_anlegen(:'kind', array['quadratische_funktionen', 'quadratische_gleichungen'], '2027-03-02', 1, '2027-01-11') ->> 'reihe_id' as rid \gset
select pg_temp.act_as(:'lena');
select is((select string_agg(name, ',') from bauform_plan_kinder() where student_id in (:'kind', :'ohne')), 'M1 Kind',
          'e1 bauform_plan_kinder: nur das Kind mit aktiver Reihe, mit Namen');
select is(pg_temp.sess(:'kind', 2), pg_temp.sess(null, 2), 'b1 ohne Änderung gleicht der Plan des Kindes dem Standard');
select pg_temp.act_as(:'admin');
select reihe_coach_aendern(:'rid', 'verschieben', 'fkt_quadr_scheitel', '2027-01-25', 'erst Normalform') is not null as ok_ \gset
select pg_temp.act_as(:'lena');
select is(pg_temp.sess(:'kind', 2), 'PAR-3 PAR-4', 'b2 Session 2 des Kindes ohne Scheitel');
select is((select string_agg(distinct session_nr::text, ',') from bauform_pruef_plan(:'kind') where skill_key = 'fkt_quadr_scheitel'),
          '3', 'b3 Scheitel-Muster folgen dem wirksamen Plan in Session 3');
select is((select session_nr from bauform_pruef_plan() where schluessel = 'SCH-1'), 2, 'b4 Standardplan bleibt unverändert');
select throws_ok(format('select * from bauform_pruef_plan(%L)', :'ohne'), 'P0002', null, 'b5 Kind ohne aktive Reihe');

-- ── c) Freigabe einzelner Muster ───────────────────────────────────────────
update bauformen set status = 'zur_freigabe' where schluessel in ('PAR-1', 'PAR-2', 'SCH-1');
select pg_temp.act_as(:'admin');
select is(bauform_freigeben('quadratische_funktionen_gleichungen', null, array['PAR-1', 'PAR-2', 'PAR-3']), 2,
          'c1 p_schluessel: zwei von drei (PAR-3 steht nicht zur Freigabe)');
select is((select string_agg(schluessel || '=' || status, ' ' order by schluessel) from bauformen
            where schluessel in ('PAR-1', 'PAR-2', 'PAR-3', 'SCH-1')),
          'PAR-1=freigegeben PAR-2=freigegeben PAR-3=zur_pruefung SCH-1=zur_freigabe', 'c2 genau diese Muster freigegeben');
select ok((select bool_and(t.status = 'ready') from tasks t join bauformen b on b.id = t.bauform_id
            where b.schluessel = 'PAR-1' and t.bauform_version = b.version and instanz_gruen(t.pruefmaschine)),
          'c3 grüne Instanzen von PAR-1 sind ready');
select is((select count(*)::int from tasks t join bauformen b on b.id = t.bauform_id
            where b.schluessel = 'SCH-1' and t.status = 'ready'), 0, 'c4 SCH-1-Instanzen bleiben ungezogen');
select is(bauform_freigeben(null, null, array['SCH-1']), 1, 'c5 p_schluessel ohne Reihe');
update bauformen set status = 'zur_freigabe' where schluessel = 'PAR-4';
select is(bauform_freigeben('quadratische_funktionen_gleichungen'), 1, 'c6 alte Signatur gibt die ganze Reihe frei');

-- ── d) Rechte ──────────────────────────────────────────────────────────────
select pg_temp.act_as(:'coach');
select throws_ok('select * from bauform_pruef_plan()', '42501', null, 'd1 Coach ohne Prüfrecht sieht den Plan nicht');
select pg_temp.act_as(:'lena');
select throws_ok($$select bauform_freigeben(null, null, array['PAR-5'])$$, '42501', null, 'd2 Lena gibt nicht frei');
select ok(exists (select 1 from bauform_plan_kinder() where student_id = :'kind' and ist_test), 'e2 Lena sieht das Testkind im Umschalter');
select pg_temp.act_as(:'coach');
select throws_ok('select * from bauform_plan_kinder()', '42501', null, 'e3 Coach ohne Prüfrecht sieht keine Kinder');

select * from finish();
rollback;
