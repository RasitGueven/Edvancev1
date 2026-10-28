-- Rollback zu 20261027130817_studio_modell: Studio-Funktionen und -Tabellen entfernen, danach den Eintrag in
-- supabase_migrations.schema_migrations löschen. Bleiben: die angelegten erklaer_kernidee-Zeilen (quelle 'mensch'),
-- die Check-Aufgaben (tasks.source 'edvance_studio') und ihre erklaer_check-Verknüpfungen — Inhalte werden nicht
-- gelöscht. Wer sie entfernen will, tut das bewusst von Hand.
drop function if exists public.studio_rolle_setzen(uuid, text, boolean);
drop function if exists public.studio_skript_speichern(uuid, jsonb, jsonb);
drop function if exists public.studio_check_aufgabe(uuid, text, text, text, jsonb);
drop function if exists public.studio_inhalt_hash(uuid, text);
drop table if exists public.studio_ruecksprung;
drop table if exists public.studio_minicheck_aufgabe;
drop table if exists public.studio_minicheck;
drop table if exists public.studio_bereich;
drop table if exists public.studio_beat_text;
drop table if exists public.studio_beat;
drop table if exists public.studio_welt;
drop table if exists public.studio_sequenz;
drop function if exists public.studio_darf_sehen();
drop function if exists public.studio_hat_rolle(text);
drop table if exists public.studio_rolle;
