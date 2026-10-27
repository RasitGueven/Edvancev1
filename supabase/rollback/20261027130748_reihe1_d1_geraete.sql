-- Rollback zu reihe1_d1_geraete: Funktionen und die beiden neuen Tabellen entfernen, den Kommentar an
-- vertraege.zugangscode zurücksetzen, danach den Eintrag in supabase_migrations.schema_migrations löschen.
-- Entfernt nur Objekte dieser Migration (Geräte und Versuchsprotokoll), keine Inhalte anderer Pakete.
-- Vorher die Edge Function geraet_anmelden stilllegen, sonst antwortet sie mit 500.
drop function if exists public.zugangscode_freischalten(uuid);
drop function if exists public.zugangscode_neu(uuid);
drop function if exists public.kind_geraet_abmelden(uuid);
drop function if exists public.kind_geraete_liste(uuid);
drop function if exists public.geraet_status();
drop function if exists public.geraet_abgemeldet();
drop function if exists public.geraet_session_setzen(uuid, uuid);
drop function if exists public.geraet_auth_session_loeschen(uuid);
drop function if exists public.geraet_einloesen(text, text, text, text, text);
drop function if exists public.zugangscode_normalisieren(text);
drop table if exists public.zugangscode_versuche;
drop table if exists public.kind_geraete;
comment on column public.vertraege.zugangscode is
  'Anzeigeform EDV-XXXX-XXXX. Acht Zeichen aus einem Alphabet ohne 0/O/1/I/L. Kein Login-Mittel in dieser Runde.';
delete from supabase_migrations.schema_migrations where version = '20261027130748';
