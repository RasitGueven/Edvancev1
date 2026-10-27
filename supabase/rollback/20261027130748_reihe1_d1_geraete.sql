-- Rollback zu reihe1_d1_geraete: zuerst die Auth-Sessions aller Geräte löschen (sonst blieben die Geräte mit dem
-- Kinderkonto angemeldet, ohne dass sie sich noch widerrufen lassen), dann Funktionen und die beiden neuen Tabellen
-- entfernen, den Kommentar an vertraege.zugangscode zurücksetzen, den Eintrag in schema_migrations löschen.
-- Entfernt nur Objekte dieser Migration (Geräte und Versuchsprotokoll), keine Inhalte anderer Pakete.
-- Voraussetzungen: D1c ist zurückgerollt (supabase/rollback/20261027132229_reihe1_d1c_home_sitzung.sql), und die
-- Edge Function ist gelöscht: npx supabase functions delete geraet_anmelden --project-ref ztcppihxqcphlqaguhma
do $$
begin
  -- Guard: Solange D1c gilt, hängen get_my_student_id() und alle Kind-Richtlinien an geraet_jwt_session — ein
  -- Drop hier ließe sie bei jedem Aufruf scheitern.
  if pg_get_functiondef('public.get_my_student_id()'::regprocedure) like '%geraet_%' then
    raise exception 'Rollback D1 abgebrochen: zuerst D1c zurückrollen (20261027132229)';
  end if;
  if to_regclass('auth.sessions') is not null then
    delete from auth.sessions s using public.kind_geraete g where g.auth_session_id = s.id;
  end if;
end $$;
drop function if exists public.zugangscode_freischalten(uuid);
drop function if exists public.kind_geraet_abmelden(uuid);
drop function if exists public.kind_geraete_liste(uuid);
drop function if exists public.geraet_abmelden_selbst();
drop function if exists public.geraet_status();
drop function if exists public.geraet_session();
drop function if exists public.geraet_abgemeldet();
drop function if exists public.geraet_jwt_session();
drop function if exists public.geraet_session_setzen(uuid, uuid);
drop function if exists public.geraet_einloesen(text, text, text, text, text);
drop function if exists public.geraet_auth_session_loeschen(uuid);
drop function if exists public.zugangscode_normalisieren(text);
drop table if exists public.zugangscode_versuche;
drop table if exists public.kind_geraete;
comment on column public.vertraege.zugangscode is
  'Anzeigeform EDV-XXXX-XXXX. Acht Zeichen aus einem Alphabet ohne 0/O/1/I/L. Kein Login-Mittel in dieser Runde.';
delete from supabase_migrations.schema_migrations where version = '20261027130748';
