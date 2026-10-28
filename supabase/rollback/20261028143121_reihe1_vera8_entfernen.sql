-- Rollback zu 20261028143121_reihe1_vera8_entfernen: aus der Sicherung ausserhalb des Repos wiederherstellen
-- (enthaelt urheberrechtlich geschuetzte Inhalte, deshalb nicht hier):
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f ~/backups/vera8-2026-10-28.sql
-- Reihenfolge in der Datei: tasks, task_solutions, lsa_responses. Danach den Eintrag in
-- supabase_migrations.schema_migrations loeschen.
select 1;
