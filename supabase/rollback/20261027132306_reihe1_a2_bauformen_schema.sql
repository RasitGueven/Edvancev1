-- Rollback zu reihe1_a2_bauformen_schema (nach den Rollbacks von pruefung_bewaehrung und aufgabe_funktionen).
-- Leitplanke Bauauftrag A: kein Entfernen von Tabellen oder Spalten. Der Rollback legt das Datenmodell still: kein
-- Versionswechsel-Trigger mehr, keine Lese-Policies, keine Rechte; die (leeren) Tabellen und Spalten bleiben stehen.
-- Danach den Eintrag in supabase_migrations.schema_migrations NICHT loeschen: ein zweites Einspielen scheiterte an den
-- vorhandenen Tabellen. Endgueltig entfernen nur mit Rasits Freigabe.
drop trigger if exists bauformen_versionswechsel on public.bauformen;
drop function if exists public.bauform_versionswechsel();
alter table public.tasks drop constraint if exists tasks_bauform_instanz;
drop policy if exists bauformen_pruefer_lesen on public.bauformen;
drop policy if exists bauform_versionen_pruefer_lesen on public.bauform_versionen;
drop policy if exists bauform_pruefungen_pruefer_lesen on public.bauform_pruefungen;
drop policy if exists aufgabe_bewaehrung_pruefer_lesen on public.aufgabe_bewaehrung;
drop policy if exists aufgabe_meldungen_lesen on public.aufgabe_meldungen;
drop policy if exists aufgabe_gesehen_admin_lesen on public.aufgabe_gesehen;
revoke all on public.bauformen, public.bauform_versionen, public.bauform_pruefungen, public.aufgabe_bewaehrung,
              public.aufgabe_meldungen, public.aufgabe_gesehen from authenticated;
