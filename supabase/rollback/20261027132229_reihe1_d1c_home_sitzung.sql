-- Rollback zu reihe1_d1c_home_sitzung: beide Grundfunktionen in der Fassung vor D1c (Prod, 27.10.2026),
-- danach den Eintrag in supabase_migrations.schema_migrations löschen.
create or replace function public.get_my_student_id()
returns uuid
language sql
stable
security definer
set search_path to 'public'
as $function$
  select id from students where profile_id = auth.uid() limit 1;
$function$;

create or replace function public.lsa_may_act_for(p_student_id uuid)
returns boolean
language sql
stable
security definer
set search_path to 'public', 'pg_temp'
as $function$
  select coalesce(public.get_my_role(), '') = 'admin'
      or (coalesce(public.get_my_role(), '') = 'coach' and public.akte_aktiv(p_student_id))
      -- coalesce: ohne Profil/Schuelerzeile ist der Vergleich NULL, und ein
      -- "if not lsa_may_act_for(…)" liesse NULL durch.
      or coalesce(public.get_my_student_id() = p_student_id, false)
$function$;

delete from supabase_migrations.schema_migrations where version = '20261027132229';
