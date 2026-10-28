-- Rollback zu reihe1_a5_board: die Lesefunktionen und skill_pruefung_entscheiden entfernen; die Spalte
-- skill_pruefung.pruef_notiz bleibt (keine Spalten entfernen). Danach den Eintrag in
-- supabase_migrations.schema_migrations NICHT loeschen (ein zweites Einspielen scheiterte an der Spalte).
drop function if exists public.skill_pruefung_entscheiden(uuid, text, text);
drop function if exists public.skill_pruefung_liste();
drop function if exists public.bauform_auffaellig();
drop function if exists public.bauform_pruef_detail(uuid, int);
drop function if exists public.bauform_pruef_liste();
