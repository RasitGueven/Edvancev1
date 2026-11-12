-- Rollback zu 20261112130215_reihe1_bauform_nf_2 (SP-1c C2, NF-2 Version 2): nichts loeschen (Leitplanke A),
-- sondern stilllegen — die Instanzen der Version 2 werden inaktiv (nie mehr gezogen), die Bauform geht auf entwurf
-- (nicht im Board). Die Version bleibt 2 (bauform_versionen ist nur anhaengend); Version 1 liegt in
-- bauform_versionen. Danach den Eintrag in supabase_migrations.schema_migrations loeschen.
update public.tasks set is_active = false where source = 'bauform' and source_ref like 'NF-2-v2-%';
update public.bauformen set status = 'entwurf' where schluessel = 'NF-2';
