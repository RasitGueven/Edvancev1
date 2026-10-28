-- Rollback zu reihe1_c4_gp_ergebnis: Funktion entfernen, danach Eintrag 20261027135304 in
-- supabase_migrations.schema_migrations löschen.
drop function if exists public.session_gp_ergebnis(uuid, uuid);
