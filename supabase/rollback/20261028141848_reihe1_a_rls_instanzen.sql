-- Rollback zu 20261028141848_reihe1_a_rls_instanzen: alte Bedingung der Policy wiederherstellen.
-- Danach den Eintrag in supabase_migrations.schema_migrations loeschen.
alter policy read_tasks_by_role on public.tasks
  using ((public.get_my_role() = any (array['coach'::text, 'admin'::text]))
         or (public.get_my_role() is not null and status = 'ready'::text));
comment on table public.tasks is
  'Aufgaben. Lesen (read_tasks_by_role): coach/admin alles, jede andere Rolle nur status=''ready''. Draft-Content bleibt in der Redaktion. Die LSA-RPCs sind SECURITY DEFINER und von der Policy nicht betroffen.';
