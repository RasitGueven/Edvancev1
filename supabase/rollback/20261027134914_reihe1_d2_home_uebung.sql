-- Rollback zu reihe1_d2_home_uebung: Funktionen und die vier Tabellen dieser Migration entfernen, danach den Eintrag
-- in supabase_migrations.schema_migrations löschen. Achtung: home_uebung, zeigs_mir und coach_fragen sind dann weg
-- (gebuchte XP in xp_events bleiben). Vorher prüfen, ob C (session_naechster_schritt) zeigs_mir_offen schon aufruft.
drop function if exists public.coach_frage_erledigt(uuid);
drop function if exists public.coach_fragen_offen(uuid);
drop function if exists public.eddie_frage_merken(text);
drop function if exists public.zeigs_mir_entscheiden(uuid, uuid, text, text);
drop function if exists public.zeigs_mir_offen(uuid, uuid);
drop function if exists public.zeigs_mir_darf(uuid, uuid);
drop function if exists public.kompetenz_offen_merken(uuid);
drop function if exists public.kompetenz_offen(uuid);
drop function if exists public.home_pfad(uuid);
drop function if exists public.home_uebung_kurz(uuid, timestamptz);
drop function if exists public.home_uebung_melden(text, integer, integer);
drop function if exists public.home_letzte_session(uuid, timestamptz);
drop function if exists public.home_darf_lesen(uuid);
drop table if exists public.coach_fragen;
drop table if exists public.zeigs_mir;
drop table if exists public.schueler_kompetenz_offen;
drop table if exists public.home_uebung;
delete from supabase_migrations.schema_migrations where version = '20261027134914';
