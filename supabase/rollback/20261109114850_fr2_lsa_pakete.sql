-- Rollback zu 20261109114850_fr2_lsa_pakete (FR-2 F1).
--
-- Einspielen wie eine Migration (-v ON_ERROR_STOP=1 -1), danach die Zeile 20261109114850 aus
-- supabase_migrations.schema_migrations löschen und tools/schema-snapshot.sh laufen lassen.
-- Entfernt nur, was die Migration angelegt hat. Die drei Stellschrauben werden nur gelöscht, wenn niemand sie
-- geändert hat (sonst bleiben sie mit Protokoll stehen).

drop trigger if exists lsa_paket_cache_schul_themenplan on public.schul_themenplan;
drop trigger if exists lsa_paket_cache_schul_klassenarbeiten on public.schul_klassenarbeiten;
drop trigger if exists lsa_paket_cache_thema_einstieg on public.thema_einstieg;
drop trigger if exists lsa_paket_cache_skill_kante on public.skill_kante;
drop trigger if exists lsa_paket_cache_skill_thema on public.skill_thema;
drop trigger if exists lsa_paket_cache_skills on public.skills;
drop trigger if exists lsa_paket_cache_themen on public.themen;

drop function if exists public.pruef_ziel_liste(boolean, integer, text);
drop function if exists public.lsa_wirkung(text, text[], integer, text);
drop function if exists public.lsa_abdeckung(integer, integer, boolean, text);
drop function if exists public.lsa_paket_status(uuid, integer, integer, text);
drop function if exists public.lsa_paket_skills(uuid, integer, integer, text);
drop function if exists public.lsa_skill_bereit(text);
drop function if exists public.lsa_pakete(integer, text);
drop function if exists public.lsa_schuljahr_heute();
drop function if exists public.pruef_ziel_roh();
drop function if exists public.lsa_status_roh(text, text[]);
drop function if exists public.lsa_skill_bereit_roh(text);
drop function if exists public.lsa_paket_skills_basis(text);
drop function if exists public.lsa_pakete_basis(text);
drop function if exists public.lsa_abdeckung_auffrischen();
drop function if exists public.lsa_paket_cache_trigger();
drop function if exists public.lsa_paket_cache_auffrischen();
drop function if exists public.lsa_paket_skills_roh(text);
drop function if exists public.lsa_pakete_roh(text);
drop function if exists public.lsa_regel();

drop table if exists public.lsa_paket_skill_cache;
drop table if exists public.lsa_paket_cache;
drop table if exists public.lsa_paket_cache_stand;
drop table if exists public.schule_fokus;

delete from public.session_einstellungen
 where schluessel in ('lsa_regel_texte', 'lsa_regel_ohne_mc', 'lsa_fokus_quartal') and geaendert_am is null;
