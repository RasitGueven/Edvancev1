-- ============================================================================
-- INV-9 (A08): Bild-Notwendigkeit ist Didaktik, nicht Schueler-Payload.
--
-- Drei Invarianten:
--
--   A) SPEICHERUNG: tasks.needs_image (Stamm) und tasks.parts[].needs_image
--      (Teilaufgabe) halten NULL/true/false. Fehlt das Feld, ist es NULL —
--      "noch nicht beurteilt", ohne Altdaten-Migration.
--
--   B) VERTRAG BLEIBT GRUEN: ein Teilaufgaben-`needs_image` besteht
--      tasks_multipart_check / lsa_parts_valid. Der Validator hat kein festes
--      Key-Set — das optionale Feld ist bereits zugelassen, ohne Aufweichung.
--
--   C) KEIN LECK ZUM KIND: needs_image ist ein Autoren-Feld. Es taucht auf
--      KEINER Ebene im lsa_question_payload auf — weder am Item (flach wie
--      Multi-Part) noch in der Teilaufgabe. Die Whitelist baut, sie reicht nicht
--      durch.
--
-- Lauf: npx supabase test db
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(7);

-- --- Fixtures --------------------------------------------------------------

-- Multi-Part: Item braucht laut Beurteilung ein Bild (needs_image=true), und
-- Teilaufgabe 1 ebenfalls (parts[0].needs_image=true) — Teilaufgabe 2 ist noch
-- nicht beurteilt (Feld fehlt = NULL).
insert into tasks (
  cluster_id, content_type, input_type, status, question,
  afb, competency_content, est_duration_sec, class_level, source, source_ref,
  needs_image, parts
)
select c.id, 'exercise', 'MULTI_PART', 'ready',
       'Betrachte die Abbildung der Verkaufsflaeche.',
       'II', 'Multi-Stamm', 420, 8, 'test', 'inv9-mp',
       true,
       '[
          {"nr":1,"kind":"short_input","prompt":"Wie viel Prozent sind schraffiert?",
           "unit":"%","needs_image":true},
          {"nr":2,"kind":"mc","prompt":"Welcher Term beschreibt den Rest?",
           "options":[{"id":"a","label":"1 minus p"},{"id":"b","label":"p"}]}
        ]'::jsonb
  from skill_clusters c order by c.sort_order limit 1;

-- Flaches Item: beurteilt als "braucht KEIN Bild" (needs_image=false).
insert into tasks (
  cluster_id, content_type, input_type, status, question, question_payload,
  afb, competency_content, est_duration_sec, class_level, source, source_ref, unit,
  needs_image
)
select c.id, 'exercise', 'SHORT_TEXT', 'ready',
       'Berechne 20 % von 80 m.',
       '{"input_type":"SHORT_TEXT"}'::jsonb,
       'I', 'Prozent und Zinsen', 120, 8, 'test', 'inv9-flat', 'm',
       false
  from skill_clusters c order by c.sort_order limit 1;

-- Bestand ohne Beurteilung: needs_image bleibt NULL (kein Vorschlag).
insert into tasks (
  cluster_id, content_type, input_type, status, question,
  afb, competency_content, est_duration_sec, class_level, source, source_ref, unit
)
select c.id, 'exercise', 'SHORT_TEXT', 'ready',
       'Wie lang ist die Strecke?',
       'II', 'Groessen und Messen', 120, 8, 'test', 'inv9-unjudged', 'm'
  from skill_clusters c order by c.sort_order limit 1;

select (select id from tasks where source_ref = 'inv9-mp')       as t_mp,
       (select id from tasks where source_ref = 'inv9-flat')     as t_flat,
       (select id from tasks where source_ref = 'inv9-unjudged') as t_open,
       (select c.id from skill_clusters c order by c.sort_order limit 1) as cid
\gset

-- ============================================================================
-- A) Speicherung: NULL / true / false halten — Item und Teilaufgabe
-- ============================================================================

select is(
  (select needs_image from tasks where id = :'t_mp'),
  true,
  'tasks.needs_image haelt die Beurteilung "braucht Bild" am Stamm'
);

select is(
  (select needs_image from tasks where id = :'t_flat'),
  false,
  'tasks.needs_image haelt auch das explizite "kein Bild noetig"'
);

select is(
  (select needs_image from tasks where id = :'t_open'),
  null::boolean,
  'Fehlt die Beurteilung, ist needs_image NULL — noch nicht beurteilt'
);

-- ============================================================================
-- B) Vertrag bleibt gruen: parts[].needs_image besteht den CHECK
-- ============================================================================

select lives_ok(
  format($f$insert into tasks (cluster_id, content_type, input_type, status, question,
                               est_duration_sec, source, parts)
            values (%L, 'exercise', 'MULTI_PART', 'ready', 'Stamm', 300, 'test',
              '[{"nr":1,"kind":"short_input","prompt":"a","needs_image":true},
                {"nr":2,"kind":"short_input","prompt":"b","needs_image":false}]'::jsonb)$f$,
         :'cid'),
  'tasks.parts[].needs_image besteht tasks_multipart_check / lsa_parts_valid'
);

-- ============================================================================
-- C) Kein Leck: needs_image bleibt aus dem Schueler-Payload draussen
-- ============================================================================

-- Multi-Part: weder Item- noch Teilaufgaben-needs_image im gesamten Payload-Text.
select is(
  (select public.lsa_question_payload(:'t_mp')::text ~* 'needs_image'),
  false,
  'Multi-Part-Payload traegt auf KEINER Ebene needs_image (Item wie Teilaufgabe)'
);

-- Feldgenau: die Teilaufgaben werden GEBAUT — nr/kind/prompt/unit/options, sonst
-- nichts. needs_image der Teilaufgabe 1 ist weggefiltert.
select is(
  (select public.lsa_question_payload(:'t_mp') -> 'parts'),
  '[
     {"nr":1,"kind":"short_input","prompt":"Wie viel Prozent sind schraffiert?","unit":"%"},
     {"nr":2,"kind":"mc","prompt":"Welcher Term beschreibt den Rest?",
      "options":[{"id":"a","label":"1 minus p"},{"id":"b","label":"p"}]}
   ]'::jsonb,
  'parts[] traegt exakt nr/kind/prompt/unit/options(id,label) — kein needs_image'
);

-- Flaches Item: die needs_image-Spalte des Items leckt auch hier nicht.
select is(
  (select public.lsa_question_payload(:'t_flat')::text ~* 'needs_image'),
  false,
  'Flaches Item: needs_image des Stamms bleibt aus dem Payload draussen'
);

select * from finish();
rollback;
