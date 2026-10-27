-- Rollback zu reihe1_d4b_tablet_lesen: home_darf_lesen in der Fassung aus 20261027134914, danach den Eintrag in
-- supabase_migrations.schema_migrations löschen.
create or replace function public.home_darf_lesen(p_kind uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(public.get_my_role(), '') = 'admin'
      or (coalesce(public.get_my_role(), '') = 'coach' and public.akte_aktiv(p_kind))
      or coalesce(public.get_my_student_id() = p_kind, false);
$$;
comment on function public.home_darf_lesen(uuid) is 'Intern: Kind selbst, Coach mit aktiver Akte, Admin.';
delete from supabase_migrations.schema_migrations where version = '20261027160142';
