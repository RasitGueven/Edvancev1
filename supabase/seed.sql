-- ============================================================================
-- Edvance – Seed-/Katalogdaten
--
-- Generiert von scripts/db/build_baseline.py aus schema.sql (Abschnitt 14).
-- Laeuft automatisch bei `supabase db reset` / `supabase start`.
-- Alle Inserts sind idempotent (where not exists / on conflict do nothing).
-- ============================================================================

-- ============================================================================
-- 14. SEED- / KATALOGDATEN
--     Idempotent gehaltene Stammdaten aus schema.sql + Migrationen 001/015/026/034.
-- ============================================================================

-- subjects (schema.sql)
insert into subjects (name)
  select v from (values ('Mathematik'),('Deutsch'),('Englisch')) as s(v)
  where not exists (select 1 from subjects where subjects.name = s.v);

-- skill_clusters: 5 KMK-Kompetenzbereiche Mathematik Kl. 8-10 (Migration 001).
insert into skill_clusters (subject_id, name, class_level_min, class_level_max, sort_order)
select s.id, c.name, 8, 10, c.sort_order
from subjects s
cross join (values
  ('Zahl & Rechnen', 1),
  ('Algebra & Funktionen', 2),
  ('Geometrie & Messen', 3),
  ('Daten & Zufall', 4),
  ('Sachrechnen & Modellieren', 5)
) as c(name, sort_order)
where s.name = 'Mathematik'
  and not exists (
    select 1 from skill_clusters sc
    where sc.subject_id = s.id and sc.name = c.name
  );

-- process_competencies: 6 KMK-Prozesskompetenzen / Achse B (Migration 038).
insert into process_competencies (code, name, sort_order)
values
  ('Ope', 'Operieren',        1),
  ('Mod', 'Modellieren',      2),
  ('Pro', 'Problemlösen',     3),
  ('Arg', 'Argumentieren',    4),
  ('Kom', 'Kommunizieren',    5),
  ('Wkz', 'Werkzeuge nutzen', 6)
on conflict (code) do nothing;

-- tiers (Migration 015)
insert into tiers (name, price_cents, features, sort_order)
select v.name, v.price_cents, v.features::jsonb, v.sort_order
from (values
  ('Basic', 8900,
   '["2 Sessions/Woche","Basis-Lernpfad","Monatlicher Eltern-Report"]', 1),
  ('Standard', 12900,
   '["3 Sessions/Woche","KI-Lernpfad","2x Eltern-Report/Monat","Coach-Chat"]', 2),
  ('Premium', 16900,
   '["Unbegrenzte Sessions","Voller KI-Lernpfad","Woechentlicher Report","Prioritaets-Coach","Fachwechsel flexibel"]', 3)
) as v(name, price_cents, features, sort_order)
where not exists (select 1 from tiers where tiers.name = v.name);

-- xp_rules (Migration 026)
insert into xp_rules (content_type, base_xp, difficulty_multiplier) values
  ('exercise', 20, 5),
  ('video', 10, 0),
  ('article', 10, 0),
  ('exercise_group', 0, 0),
  ('course', 0, 0)
on conflict (content_type) do nothing;

-- badge_catalog: 10 reguläre Badges (Migration 034)
insert into public.badge_catalog (id, label, description, rarity, form, trigger) values
  ('first_step',        'Erster Schritt',         'Erste Session abgeschlossen',                   'bronze', 'round', 'first_session_done'),
  ('warmed_up',         'Aufgewärmt',             'Erste 3 Sessions abgeschlossen',                'bronze', 'round', 'three_sessions_done'),
  ('persistent_3',      'Dranbleiber',            '3-Wochen-Präsenz-Streak',                       'silver', 'round', 'presence_streak_3'),
  ('machine_7',         'Maschine',               '7-Wochen-Präsenz-Streak',                       'gold',   'round', 'presence_streak_7'),
  ('hw_hero',           'Hausaufgaben-Held',      '5 Hausaufgaben hochgeladen',                    'silver', 'round', 'hw_uploaded_5'),
  ('exam_warrior',      'Klassenarbeit-Krieger',  'Case A vollständig durchlaufen',                'gold',   'round', 'case_a_complete'),
  ('thinker',           'Durchdenker',            'Erste Reflection als valide bestätigt',         'silver', 'round', 'first_reflection_valid'),
  ('tenacious',         'Hartnäckig',             'Nach 3 Fehlversuchen korrekt gelöst',           'bronze', 'round', 'comeback_correct'),
  ('level_5_reached',   'Level 5 erreicht',       'XP-Level 5 erreicht',                           'silver', 'round', 'xp_level_5'),
  ('master_of_topic',   'Meister des Themas',     'Mastery-Level 7+ in einem Mikro-Skill',         'gold',   'round', 'mastered_microskill')
on conflict (id) do nothing;

-- badge_catalog: Platin (Shield) für Klassen-Abschlüsse 8/9/10 (Migration 034)
insert into public.badge_catalog (id, label, description, rarity, form, klasse, trigger) values
  ('class_8_complete',  'Klasse 8 gemeistert',    'Alle Mikro-Skills Klasse 8 auf Mastered',       'platinum', 'shield', 8,  'class_complete'),
  ('class_9_complete',  'Klasse 9 gemeistert',    'Alle Mikro-Skills Klasse 9 auf Mastered',       'platinum', 'shield', 9,  'class_complete'),
  ('class_10_complete', 'Klasse 10 gemeistert',   'Alle Mikro-Skills Klasse 10 auf Mastered',      'platinum', 'shield', 10, 'class_complete')
on conflict (id) do nothing;

-- ============================================================================
-- ENDE – konsolidiertes Schema (33 Tabellen, 9 Funktionen, 2 Enums, 1 Trigger).
-- ============================================================================
