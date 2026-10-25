-- Rollback zu leads_letzte_klassenarbeit_note: Spalte entfernen, danach den Eintrag in
-- supabase_migrations.schema_migrations löschen.
alter table public.leads drop column if exists letzte_klassenarbeit_note;
