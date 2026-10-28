-- Rollback zu reihe1_a2_pruefung_bewaehrung: Trigger und Funktionen entfernen, die Stellschrauben der Bewaehrung
-- loeschen (nur wenn unveraendert: kein Protokolleintrag), danach den Eintrag in supabase_migrations.schema_migrations
-- loeschen. Die Daten in aufgabe_bewaehrung, aufgabe_meldungen und bauform_pruefungen bleiben.
drop trigger if exists session_antworten_bewaehrung on public.session_antworten;
drop function if exists public.bewaehrung_nach_antwort();
drop function if exists public.bauform_stufen_vorschlag(uuid);
drop function if exists public.aufgabe_melden(uuid, text);
drop function if exists public.aufgabe_reaktivieren(uuid);
drop function if exists public.bauform_zur_ueberarbeitung(uuid, text);
drop function if exists public.bauform_freigeben(text, text);
drop function if exists public.bauform_reaktivieren(uuid, text);
drop function if exists public.bauform_pruefen(uuid, int, text, text[], text, int);
drop function if exists public.reihe1_wert(text);
delete from public.session_einstellungen e
 where e.schluessel like 'bewaehrung\_%'
   and not exists (select 1 from public.session_einstellungen_protokoll p where p.schluessel = e.schluessel);
