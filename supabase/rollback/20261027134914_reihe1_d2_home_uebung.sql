-- Rollback zu reihe1_d2_home_uebung: Trigger, Funktionen und die vier Tabellen dieser Migration entfernen, danach den
-- Eintrag in supabase_migrations.schema_migrations löschen. Achtung: home_uebung, zeigs_mir und coach_fragen sind dann
-- weg (gebuchte XP in xp_events bleiben). Mit psql -1 ausführen. Der Guard bricht ab, solange eine Funktion eines
-- anderen Pakets (C: session_naechster_schritt) D2 aufruft.
do $$
begin
  if exists (select 1 from pg_proc p where p.pronamespace = 'public'::regnamespace
              and p.prosrc ~ '(zeigs_mir_(offen|uebernommen)|kompetenz_offen|home_uebung_kurz)'
              and p.proname !~ '^(zeigs_mir_|kompetenz_offen|home_|coach_frage|eddie_frage)') then
    raise exception 'Rollback D2 abgebrochen: fremde Funktionen nutzen D2 noch';
  end if;
end $$;
drop trigger if exists lernpfad_kompetenz_offen_vorher on public.lernpfad;
drop trigger if exists lernpfad_kompetenz_offen_nachher on public.lernpfad;
drop trigger if exists lead_themen_kompetenz_offen_vorher on public.lead_themen;
drop trigger if exists lead_themen_kompetenz_offen_nachher on public.lead_themen;
drop trigger if exists lead_klassenarbeiten_kompetenz_offen_vorher on public.lead_klassenarbeiten;
drop trigger if exists lead_klassenarbeiten_kompetenz_offen_nachher on public.lead_klassenarbeiten;
drop function if exists public.kompetenz_offen_trigger();
drop function if exists public.zeigs_mir_uebernommen(uuid, uuid);
drop function if exists public.coach_frage_erledigt(uuid);
drop function if exists public.coach_fragen_offen(uuid);
drop function if exists public.eddie_frage_merken(text);
drop function if exists public.zeigs_mir_entscheiden(uuid, uuid, text, text);
drop function if exists public.zeigs_mir_offen(uuid, uuid);
drop function if exists public.zeigs_mir_darf(uuid, uuid);
drop function if exists public.kompetenz_offen_merken(uuid);
drop function if exists public.kompetenz_offen_merken_intern(uuid);
drop function if exists public.kompetenz_offen(uuid);
drop function if exists public.kompetenz_offen_roh(uuid);
drop function if exists public.home_pfad(uuid);
drop function if exists public.home_uebung_kurz(uuid, timestamptz);
drop function if exists public.home_uebung_melden(text, integer, integer);
drop function if exists public.home_letzte_session(uuid, timestamptz);
drop function if exists public.home_darf_lesen(uuid);
drop table if exists public.coach_fragen;
drop table if exists public.zeigs_mir;
drop table if exists public.schueler_kompetenz_offen;
drop table if exists public.home_uebung;
drop function if exists public.home_uebung_append_only();
delete from supabase_migrations.schema_migrations where version = '20261027134914';
