-- Rollback zu reihe1_d4_themenbaum: die Funktion entfernen, danach den Eintrag in supabase_migrations.schema_migrations löschen.
drop function if exists public.themenbaum_themen(uuid);
delete from supabase_migrations.schema_migrations where version = '20261027141641';
