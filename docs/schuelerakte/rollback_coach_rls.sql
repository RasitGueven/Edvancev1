-- Rollback zu supabase/migrations/20260929100200_coach_rls.sql.
--
-- Stellt die Policies wortgleich wieder her, wie sie vor S1 galten
-- (schema-erwartet.sql vor S1). Schema-Objekte aus Teil 1 und 2 bleiben.
--
-- Einspielen (Rasit):
--   dbcheck && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f docs/schuelerakte/rollback_coach_rls.sql \
--     && psql "$DATABASE_URL" -c "delete from supabase_migrations.schema_migrations where version = '20260929100200'" \
--     && tools/schema-snapshot.sh

-- leads
drop policy if exists leads_admin_all on public.leads;
create policy leads_coach_admin_all on public.leads
  using ((public.get_my_role() = any (array['coach'::text, 'admin'::text])))
  with check ((public.get_my_role() = any (array['coach'::text, 'admin'::text])));

-- parent_student
drop policy if exists parent_student_admin_all on public.parent_student;
create policy parent_student_coach_admin_all on public.parent_student
  using ((public.get_my_role() = any (array['coach'::text, 'admin'::text])))
  with check ((public.get_my_role() = any (array['coach'::text, 'admin'::text])));

-- students
drop policy if exists students_admin_all on public.students;
drop policy if exists students_coach_select on public.students;
create policy students_coach_admin_all on public.students
  using ((public.get_my_role() = any (array['coach'::text, 'admin'::text])))
  with check ((public.get_my_role() = any (array['coach'::text, 'admin'::text])));

-- profiles
drop policy if exists profiles_admin_select on public.profiles;
drop policy if exists profiles_coach_select on public.profiles;
create policy coaches_admins_see_all_profiles on public.profiles
  for select using ((public.get_my_role() = any (array['coach'::text, 'admin'::text])));
drop function if exists public.profil_fuer_coach_sichtbar(uuid);
