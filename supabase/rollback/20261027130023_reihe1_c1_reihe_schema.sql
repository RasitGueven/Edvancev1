-- Rollback zu reihe1_c1_reihe_schema (nach dem Rollback von 20261027130145): Tabellen der Reihe und die
-- Stellschrauben reihe_* entfernen, danach den Eintrag 20261027130023 in supabase_migrations.schema_migrations löschen.
-- Achtung: löscht geplante Reihen und Coach-Änderungen. Vorher prüfen, ob schon Daten da sind:
--   select count(*) from public.reihen;
drop table if exists public.reihe_ist;
drop table if exists public.reihe_coach_aenderungen;
drop table if exists public.reihe_plan_versionen;
drop table if exists public.reihen;
drop table if exists public.reihe_kann_entfallen;
drop table if exists public.reihe_kernideen;
drop function if exists public.reihe_nur_anhaengen();
delete from public.session_einstellungen
 where schluessel in ('reihe_kapazitaet_min', 'reihe_spielraum', 'reihe_min_neu', 'reihe_min_gesehen',
                      'reihe_min_gesehen_knapp', 'reihe_transfer_min', 'reihe_rollierend_sessions');
