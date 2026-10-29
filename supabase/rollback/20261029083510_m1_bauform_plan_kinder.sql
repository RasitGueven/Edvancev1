-- Rollback zu 20261029083510_m1_bauform_plan_kinder. Danach den Eintrag in supabase_migrations.schema_migrations loeschen.
drop function if exists public.bauform_plan_kinder();
