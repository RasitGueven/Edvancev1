-- ============================================================================
-- INV-1 (FernUSG): "Mastered" darf ausschliesslich der Coach setzen.
--
-- Warum das ein Regressionsschutz sein muss:
--   Rechtlich (FernUSG) ist Edvance nur dann kein genehmigungspflichtiger
--   Fernunterricht, wenn die Lernerfolgskontrolle bei einem Menschen liegt.
--   Kippt dieser Gate, kippt die Rechtsposition — nicht nur ein Feature.
--
-- Die Invariante ist zweifach abgesichert; dieser Test prueft BEIDE Schichten:
--   1. RLS   — student/parent haben ueberhaupt keinen Schreibpfad
--              (Policies scm_coach_admin_insert / scm_coach_admin_update).
--   2. Trigger trg_enforce_mastery_gate — der Backstop. Er greift auch dann,
--              wenn RLS umgangen wird — und genau das tut ein service_role-Key.
--              Ohne ihn koennte jeder serverseitige Code mastered=true setzen.
--
-- Lauf: npx supabase test db
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(8);

-- --- Fixtures --------------------------------------------------------------
\set student_uid '11111111-1111-1111-1111-111111111111'
\set coach_uid   '22222222-2222-2222-2222-222222222222'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'student_uid', 'student@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach_uid',   'coach@test.local',   '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');

insert into profiles (id, email, role, full_name) values
  (:'student_uid', 'student@test.local', 'student', 'Test Schuelerin'),
  (:'coach_uid',   'coach@test.local',   'coach',   'Test Coach');

insert into students (profile_id, class_level) values (:'student_uid', 8);

-- microskill an einem geseedeten KMK-Cluster
insert into microskills (cluster_id, code, name, class_level)
select c.id, 'INV1-TEST', 'Testskill', 8 from skill_clusters c order by c.sort_order limit 1;

-- Fixture-IDs als psql-Variablen — bewusst NICHT als Tabelle: die getesteten
-- Statements laufen als `authenticated` und muessten sonst zusaetzlich eine
-- Fixture-Tabelle lesen duerfen. Das wuerde den Test verwaessern.
select (select id from students where profile_id = :'student_uid')       as sid,
       (select id from microskills where code = 'INV1-TEST')             as mid,
       (select id from process_competencies order by sort_order limit 1) as cid
\gset

-- Rolle simulieren = auth.uid() ueber die JWT-Claims setzen.
create or replace function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;

-- ============================================================================
-- Schicht 1: RLS — der Schueler hat gar keinen Schreibpfad
-- ============================================================================
set local role authenticated;
select pg_temp.act_as(:'student_uid');

select is(public.get_my_role(), 'student', 'Fixture: der Testnutzer ist ein student');

-- Bewusst mit mastered=false: der BEFORE-Trigger feuert VOR dem RLS-WITH-CHECK
-- und wuerde mit mastered=true bereits vorher abbrechen (P0001). Nur so sieht
-- man wirklich die RLS-Schicht — der Schueler hat gar keinen Schreibpfad, auch
-- nicht fuer den blossen Score.
select throws_ok(
  format($f$insert into student_competency_mastery
              (student_id, microskill_id, competency_id, score, mastered)
            values (%L, %L, %L, 60, false)$f$, :'sid', :'mid', :'cid'),
  '42501',
  'new row violates row-level security policy for table "student_competency_mastery"',
  'RLS: student darf student_competency_mastery gar nicht beschreiben'
);

-- ============================================================================
-- Schicht 2: Trigger — der Backstop, wenn RLS umgangen wird (service_role!)
-- ============================================================================
reset role;  -- postgres = BYPASSRLS. Genau die Lage eines service_role-Keys.
select pg_temp.act_as(:'student_uid');

select is(public.get_my_role(), 'student', 'Fixture: auth.uid() zeigt weiter auf den student');

select throws_ok(
  format($f$insert into student_competency_mastery
              (student_id, microskill_id, competency_id, score, mastered)
            values (%L, %L, %L, 100, true)$f$, :'sid', :'mid', :'cid'),
  'Mastered darf nur durch Coach gesetzt werden (FernUSG)',
  'Trigger: mastered=true wird auch OHNE RLS abgelehnt, wenn die Rolle kein Coach ist'
);

-- Der Gate blockt nur "mastered", nicht den Score — sonst koennte die Engine
-- keinen Lernfortschritt mehr schreiben.
select lives_ok(
  format($f$insert into student_competency_mastery
              (student_id, microskill_id, competency_id, score, mastered)
            values (%L, %L, %L, 60, false)$f$, :'sid', :'mid', :'cid'),
  'Trigger: score-Fortschritt ohne mastered bleibt erlaubt'
);

-- Auch das nachtraegliche Hochstufen per UPDATE muss scheitern.
select throws_ok(
  format($f$update student_competency_mastery set mastered = true
            where student_id = %L$f$, :'sid'),
  'Mastered darf nur durch Coach gesetzt werden (FernUSG)',
  'Trigger: auch das nachtraegliche UPDATE auf mastered=true wird abgelehnt'
);

-- ============================================================================
-- Der Coach darf — und wird dabei protokolliert
-- ============================================================================
select pg_temp.act_as(:'coach_uid');

select lives_ok(
  format($f$update student_competency_mastery set mastered = true
            where student_id = %L$f$, :'sid'),
  'Coach: darf mastered=true setzen'
);

select results_eq(
  format($f$select mastered, mastered_by is not null, mastered_at is not null
            from student_competency_mastery where student_id = %L$f$, :'sid'),
  $$ values (true, true, true) $$,
  'Coach-Freigabe wird mit mastered_by + mastered_at protokolliert (Nachweisbarkeit)'
);

select * from finish();
rollback;
