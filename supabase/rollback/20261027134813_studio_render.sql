-- Rollback zu 20261027134813_studio_render: Render-Funktionen und -Tabelle entfernen, danach den Eintrag in
-- supabase_migrations.schema_migrations löschen. Die gerenderten Dateien im Bucket studio bleiben.
drop function if exists public.studio_render_melden(uuid, text, jsonb, text);
drop function if exists public.studio_render_anlegen(uuid, text, text);
drop function if exists public.studio_render_stand(uuid);
drop function if exists public.studio_render_fingerabdruck(uuid, text);
drop function if exists public.studio_render_fassung();
drop table if exists public.studio_render;
