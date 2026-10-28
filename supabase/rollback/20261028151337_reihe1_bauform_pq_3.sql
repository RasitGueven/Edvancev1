-- Rollback zu 20261028151337_reihe1_bauform_pq_3: nichts loeschen (Leitplanke A),
-- sondern stilllegen — die Instanzen dieser Bauform werden inaktiv (nie mehr gezogen), die Bauform geht auf entwurf
-- (nicht im Board). Danach den Eintrag in supabase_migrations.schema_migrations loeschen.
update public.tasks set is_active = false where source = 'bauform' and source_ref like 'PQ-3-v%';
update public.bauformen set status = 'entwurf' where schluessel = 'PQ-3';
