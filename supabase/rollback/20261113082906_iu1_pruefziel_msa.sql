-- Rollback zu 20261113082906_iu1_pruefziel_msa (IU-1 U1). Entfernt nur das Prüfziel msa_zp10 samt Zuordnung und Ausschluss
-- (on delete cascade). Danach die Zeile 20261113082906 aus supabase_migrations.schema_migrations löschen.
delete from public.pruefziele where key = 'msa_zp10';
