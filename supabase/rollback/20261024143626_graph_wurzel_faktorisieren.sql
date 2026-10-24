-- Rollback zu 20261024143626_graph_wurzel_faktorisieren.sql: die zwei Kanten wieder entfernen.
-- Danach den Eintrag in supabase_migrations.schema_migrations löschen.
delete from public.skill_kante
where (skill_key, voraussetzt_skill_key) in (
  ('geo_pythagoras_anwendung', 'zahl_wurzel_teilweise'),
  ('fkt_quadr_nullstellen', 'term_binom_faktorisieren')
);
