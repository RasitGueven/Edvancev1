-- Rollback zu reihe1_c2_bausteine (nach dem Rollback von 20261027133413): Bausteine, Spalten, Stellschrauben und
-- erweiterte Prüfregeln zurück; danach Eintrag 20261027133007 in supabase_migrations.schema_migrations löschen.
-- Die alten Prüfregeln kommen NOT VALID zurück, damit vorhandene Zeilen mit den neuen Arten erhalten bleiben
-- (Session-Daten werden nie gelöscht). Vorher ansehen: select art, count(*) from public.session_schritte group by 1;
drop function if exists public.session_abruf_faellig(uuid, uuid);
drop function if exists public.session_zwilling(uuid, uuid, uuid, text);
drop function if exists public.session_ziehen(uuid, uuid, text, text, int, boolean, boolean);
drop function if exists public.session_ausschluss(uuid, uuid, boolean);
drop function if exists public.session_stufe_sicher(uuid, text);
drop function if exists public.session_stufe(uuid);
delete from public.session_einstellungen
 where schluessel in ('warmup_abruf_max', 'warmup_voraus_max', 'abruf_abstand_max', 'transfer_ab_stufe', 'transfer_hinweisstufen',
                      'recap_aufgaben', 'recap_min', 'gp_skills_max', 'gp_stufe', 'gp_transfer', 'gp_ueben_aufgaben');
alter table public.session_schritte drop column if exists hinweise_max, drop column if exists rolle;
alter table public.session_schritte drop constraint session_schritte_art_check;
alter table public.session_schritte add constraint session_schritte_art_check check (art = any (array[
  'erklaerung', 'beispiel', 'aufgabe', 'erklaerung_angebot', 'exit', 'termin', 'fertig', 'warten'])) not valid;
alter table public.session_ereignisse drop constraint session_ereignisse_typ_check;
alter table public.session_ereignisse add constraint session_ereignisse_typ_check check (typ = any (array[
  'phase_wechsel', 'hinweis', 'erklaerschritt', 'check', 'signal', 'signal_erledigt', 'eingriff',
  'entscheidung_pfad', 'pruefung'])) not valid;
