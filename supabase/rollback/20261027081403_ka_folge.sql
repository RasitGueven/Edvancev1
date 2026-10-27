-- Rollback zu ka_folge (L5 Teil A): Funktionen, Trigger, Tabellen und Spalte entfernen, danach den Eintrag in
-- supabase_migrations.schema_migrations löschen. Die Angaben aus Erstgespräch und Check-in gehen dabei verloren.
drop function if exists public.ka_erstgespraech_speichern(uuid, int, text, date, text[], int);
drop function if exists public.ka_folge_lead(uuid, text, text);
drop function if exists public.ka_folge_uebersicht(text, text);
drop function if exists public.ka_folge_schule(uuid, int, text, text);
drop function if exists public.ka_folge_schule_roh(uuid, int, text, text);
drop trigger if exists session_checkin_klassenarbeit on public.session_checkin;
drop function if exists public.ka_aus_checkin();
drop table if exists public.schul_klassenarbeiten;
drop table if exists public.lead_klassenarbeiten;
drop function if exists public.ka_themen_pruefen();
alter table public.leads drop column if exists ka_anzahl_schuljahr;
drop function if exists public.ka_schuljahr(date);
