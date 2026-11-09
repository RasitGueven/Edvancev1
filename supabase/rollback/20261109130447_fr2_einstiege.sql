-- Rollback zu 20261109130447_fr2_einstiege: die drei Einstiege wieder entfernen (vorher hatten die drei Themen
-- keine Zeile in thema_einstieg, dbread 09.11.2026). Danach die Version aus supabase_migrations.schema_migrations
-- löschen.
delete from public.thema_einstieg
 where (thema_key, skill_key) in (('rationale_zahlen', 'vorzeichen_vorrang'), ('zuordnungen', 'proportionalitaet'),
                                  ('statistik_beurteilen', 'stoch_bedingt_irrefuehrend'));
