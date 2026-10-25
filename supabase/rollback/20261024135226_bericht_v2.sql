-- Rollback zu 20261024135226_bericht_v2.sql: beide Spalten wieder entfernen.
-- Danach den Eintrag in supabase_migrations.schema_migrations löschen.
alter table public.lsa_report_notes drop column if exists paket_bestaetigt;
alter table public.leads drop column if exists klassenarbeit_status;
