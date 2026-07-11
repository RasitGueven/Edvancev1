-- ============================================================================
-- Migration 001 – Cluster auf KMK-Kompetenzbereiche umstellen (Mathe Kl. 8-10)
--
-- Manueller Schritt: Im Supabase SQL Editor ausfuehren.
--
-- Was passiert:
--   1. Alle existing skill_clusters fuer Mathematik werden geloescht.
--      → Cascade entfernt zugehoerige microskills automatisch.
--      → tasks behalten ihre Daten, cluster_id wird auf NULL gesetzt
--        (siehe `on delete set null` in schema_content.sql).
--   2. Die 5 KMK-Kompetenzbereiche werden frisch angelegt.
--
-- Hintergrund:
--   Der erste Seed (seed-microskills.ts alt) hat fachliche Cluster wie
--   "Rationale Zahlen" angelegt. Die echte Edvance-Struktur folgt aber
--   den 5 KMK-Kompetenzbereichen, die klassenstufenuebergreifend stabil
--   sind. Mikroskills + ggf. Makroskills werden in einer Folge-Migration
--   neu definiert.
-- ============================================================================

-- 1. Alte Mathematik-Cluster (inkl. cascading microskills) loeschen
delete from skill_clusters
where subject_id in (select id from subjects where name = 'Mathematik');

-- 2. Die 5 KMK-Kompetenzbereiche fuer Mathematik Kl. 8-10 anlegen
insert into skill_clusters (subject_id, name, class_level_min, class_level_max, sort_order)
select id, 'Zahl & Rechnen',            8, 10, 1 from subjects where name = 'Mathematik'
union all
select id, 'Algebra & Funktionen',      8, 10, 2 from subjects where name = 'Mathematik'
union all
select id, 'Geometrie & Messen',        8, 10, 3 from subjects where name = 'Mathematik'
union all
select id, 'Daten & Zufall',            8, 10, 4 from subjects where name = 'Mathematik'
union all
select id, 'Sachrechnen & Modellieren', 8, 10, 5 from subjects where name = 'Mathematik';
