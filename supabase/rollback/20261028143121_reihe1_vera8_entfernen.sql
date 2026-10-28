-- Rollback zu 20261028143121_reihe1_vera8_entfernen: aus der Sicherung ausserhalb des Repos wiederherstellen
-- (enthaelt urheberrechtlich geschuetzte Inhalte, deshalb nicht hier):
--   { echo 'set session_replication_role = replica;'; cat ~/backups/vera8-2026-10-28.sql; } \
--     | psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1
-- (replica: die Trigger auf task_solutions und lsa_responses sollen die gesicherten Zeilen nicht veraendern)
-- Reihenfolge in der Datei: tasks, task_solutions, lsa_responses. Danach den Eintrag in
-- supabase_migrations.schema_migrations loeschen.
select 1;
