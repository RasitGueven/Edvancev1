-- Rollback zu bericht_v3_ziele: Spalte entfernen, danach den Eintrag in
-- supabase_migrations.schema_migrations löschen.
alter table public.lsa_report_notes drop column if exists ziele_bestaetigt;
