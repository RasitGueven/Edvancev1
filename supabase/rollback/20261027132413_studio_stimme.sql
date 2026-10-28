-- Rollback zu 20261027132413_studio_stimme: Funktionen, Policies und Tabellen der Stimme entfernen, danach den
-- Eintrag in supabase_migrations.schema_migrations löschen. Der Bucket 'studio' und seine Dateien bleiben
-- (Inhalte werden nicht gelöscht).
drop function if exists public.studio_einstellung_setzen(text, jsonb);
drop function if exists public.studio_audio_eintragen(text, text, text, text, integer, jsonb, boolean);
drop function if exists public.studio_stimme_bedarf(uuid, text);
drop function if exists public.studio_fingerabdruck(text, text, text);
drop function if exists public.studio_audio_fassung();
drop function if exists public.studio_sprechfassung(text);
drop function if exists public.studio_wert(text);
drop policy if exists studio_storage_schreiben on storage.objects;
drop policy if exists studio_storage_lesen on storage.objects;
drop table if exists public.studio_audio;
drop table if exists public.studio_einstellung;
