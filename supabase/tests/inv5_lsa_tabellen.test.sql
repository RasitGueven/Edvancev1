-- ============================================================================
-- INV-5 (F01): Die Tabelle im Aufgabenstamm ist strukturiert — und traegt keine
-- Loesung.
--
-- Drei Invarianten:
--
--   A) STRUKTUR: eine kaputte Tabelle kommt gar nicht erst in die Tabelle. Ragged
--      rows, Zahl statt String, Loesungsfeld im Tabellen-Objekt — CHECK, nicht
--      Bitte. Und: der neue CHECK beisst NICHT die 299 Bestandszeilen, deren
--      question_payload das kanonische AnswerPayload (inkl. 'accepted') traegt.
--
--   B) SICHERHEIT (der Kern): das Payload mit Tabelle enthaelt KEINE Loesung. Das
--      ist hier scharf, weil die Tabelle als erstes Feld des Vertrags aus
--      tasks.question_payload gelesen wird — genau der Spalte, in der bei
--      Bestandszeilen `accepted` liegt. Geprueft wird gegen den GESAMTEN
--      Payload-Text, auf jeder Ebene: Stamm und Teilaufgabe.
--
--   C) BAUEN, NICHT DURCHREICHEN: lsa_public_table konstruiert headers/rows Zelle
--      fuer Zelle. Ein geschmuggeltes Feld im Quell-Objekt kommt nicht heraus —
--      auch dann nicht, wenn es den CHECK je an einem CHECK vorbei in die Zeile
--      schaffen sollte.
--
-- Lauf: npx supabase test db
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(15);

-- T1b verbietet Loesungsfelder in tasks.question_payload
-- (`tasks_question_payload_no_solution`). INV-5 lebt genau davon: es legt die
-- Tabelle direkt NEBEN `accepted` in denselben Payload, um zu zeigen, dass der
-- Builder die Tabelle mitnimmt und die Loesung liegen laesst. Lokal aufgehoben;
-- die Transaktion endet in `rollback`.
alter table tasks drop constraint tasks_question_payload_no_solution;

-- --- Fixtures --------------------------------------------------------------
\set student_uid '66666666-6666-6666-6666-666666666666'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'student_uid', 'tbl-student@test.local', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated');

insert into profiles (id, email, role, full_name) values
  (:'student_uid', 'tbl-student@test.local', 'student', 'Tabellen-Schuelerin');

insert into students (profile_id, class_level) values (:'student_uid', 8);

-- Das flache Item MIT Tabelle. question_payload traegt daneben bewusst das
-- kanonische AnswerPayload inklusive 'accepted' — genau die Nachbarschaft, aus
-- der nichts durchsickern darf.
insert into tasks (
  cluster_id, content_type, input_type, status, question, question_payload,
  afb, competency_content, est_duration_sec, class_level, source, source_ref, unit
)
select c.id, 'exercise', 'SHORT_TEXT', 'ready',
       'Wie viele Einwohner pro km2 hat Bayern?',
       '{"input_type":"SHORT_TEXT","accepted":["177"],
         "table":{"headers":["Bundesland","Einwohner pro km2"],
                  "rows":[["Baden-Wuerttemberg","301"],
                          ["Bayern","177"],
                          ["Berlin","3.861"]]}}'::jsonb,
       'I', 'Daten und Zufall', 240, 8, 'test', 'inv4-flat', 'E/km2'
  from skill_clusters c order by c.sort_order limit 1;

-- Ein Item OHNE Tabelle — der Schluessel darf im Payload dann gar nicht auftauchen.
insert into tasks (
  cluster_id, content_type, input_type, status, question, question_payload,
  afb, competency_content, est_duration_sec, class_level, source, source_ref
)
select c.id, 'exercise', 'SHORT_TEXT', 'ready', 'Wie lang ist die Strecke?',
       '{"input_type":"SHORT_TEXT","accepted":["0,3 m"]}'::jsonb,
       'I', 'Groessen und Messen', 180, 8, 'test', 'inv4-plain'
  from skill_clusters c order by c.sort_order limit 1;

-- Multi-Part: eine Datentabelle im STAMM (gilt fuer alle Teilaufgaben — der
-- VERA-Regelfall) und zusaetzlich eine eigene Tabelle in Teilaufgabe 2.
insert into tasks (
  cluster_id, content_type, input_type, status, question, question_payload,
  afb, competency_content, est_duration_sec, class_level, source, source_ref, parts
)
select c.id, 'exercise', 'MULTI_PART', 'ready',
       'Die Tabelle zeigt die Bevoelkerungsdichte einiger Bundeslaender.',
       '{"table":{"headers":["Bundesland","Einwohner pro km2"],
                  "rows":[["Baden-Wuerttemberg","301"],["Bayern","177"]]}}'::jsonb,
       'II', 'Multi-Stamm', 480, 8, 'test', 'inv4-mp',
       '[
          {"nr":1,"kind":"short_input","prompt":"Wie gross ist die Differenz?",
           "unit":"E/km2","competency_content":"Daten und Zufall","afb":"I"},
          {"nr":2,"kind":"mc","prompt":"Welches Land liegt darueber?",
           "table":{"headers":["Land","Wert"],"rows":[["Hessen","297"]]},
           "options":[{"id":"a","label":"Hessen"},{"id":"b","label":"Bayern"}],
           "competency_content":"Daten und Zufall","afb":"II"}
        ]'::jsonb
  from skill_clusters c order by c.sort_order limit 1;

select (select id from tasks where source_ref = 'inv4-flat')  as t_flat,
       (select id from tasks where source_ref = 'inv4-plain') as t_plain,
       (select id from tasks where source_ref = 'inv4-mp')    as t_mp,
       (select c.id from skill_clusters c order by c.sort_order limit 1) as cid
\gset

insert into task_solutions (task_id, correct_answers, solution) values
  (:'t_flat',  '["177"]'::jsonb,                'GEHEIM-TABELLE'),
  (:'t_plain', '["0,3 m"]'::jsonb,              'GEHEIM-PLAIN'),
  (:'t_mp',    '{"1":["124"],"2":["a"]}'::jsonb, 'GEHEIM-MULTI');

create or replace function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
                     json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;

-- ============================================================================
-- A) Die Tabelle ist ein Vertrag — durchgesetzt, nicht erhofft
-- ============================================================================

-- Der klassische Zerfall beim Plattwalzen: verbundene Zellen → Zeile zu kurz.
-- Sie waere stillschweigend falsch ausgerichtet und damit eine falsche Aufgabe.
select throws_ok(
  format($f$insert into tasks (cluster_id, content_type, input_type, status, question,
                               source, source_ref, question_payload)
            values (%L, 'exercise', 'SHORT_TEXT', 'ready', 'Stamm', 'test', 'inv4-x1',
              '{"table":{"headers":["Land","Wert"],
                         "rows":[["Bayern","177"],["Berlin"]]}}'::jsonb)$f$, :'cid'),
  '23514', NULL,
  'Ragged row (Zeile schmaler als die Header) wird abgewiesen'
);

-- "301", nicht 301: der Client rendert, er rechnet nicht. Eine Zahl heisst, das
-- Extraktionsskript hat geraten.
select throws_ok(
  format($f$insert into tasks (cluster_id, content_type, input_type, status, question,
                               source, source_ref, question_payload)
            values (%L, 'exercise', 'SHORT_TEXT', 'ready', 'Stamm', 'test', 'inv4-x2',
              '{"table":{"headers":["Land","Wert"],
                         "rows":[["Bayern",177]]}}'::jsonb)$f$, :'cid'),
  '23514', NULL,
  'Zelle als JSON-Number statt String wird abgewiesen (Zellen sind Strings)'
);

select throws_ok(
  format($f$insert into tasks (cluster_id, content_type, input_type, status, question,
                               source, source_ref, question_payload)
            values (%L, 'exercise', 'SHORT_TEXT', 'ready', 'Stamm', 'test', 'inv4-x3',
              '{"table":{"headers":["Land"],"rows":[["Bayern"]],
                         "accepted":["177"]}}'::jsonb)$f$, :'cid'),
  '23514', NULL,
  'Ein Loesungsfeld IM Tabellen-Objekt wird abgewiesen'
);

select throws_ok(
  format($f$insert into tasks (cluster_id, content_type, input_type, status, question,
                               source, source_ref, question_payload)
            values (%L, 'exercise', 'SHORT_TEXT', 'ready', 'Stamm', 'test', 'inv4-x4',
              '{"table":{"headers":["Land","Wert"],"rows":[]}}'::jsonb)$f$, :'cid'),
  '23514', NULL,
  'Eine Tabelle ohne Zeilen ist keine Tabelle'
);

-- Dieselbe Zusage eine Ebene tiefer: die Teilaufgabe darf eine Tabelle tragen —
-- aber nur eine wohlgeformte (lsa_parts_valid → tasks_multipart_check).
select throws_ok(
  format($f$insert into tasks (cluster_id, content_type, input_type, status, question,
                               est_duration_sec, source, source_ref, parts)
            values (%L, 'exercise', 'MULTI_PART', 'ready', 'Stamm', 300, 'test', 'inv4-x5',
              '[{"nr":1,"kind":"short_input","prompt":"a",
                 "table":{"headers":["Land","Wert"],"rows":[["Bayern"]]}},
                {"nr":2,"kind":"short_input","prompt":"b"}]'::jsonb)$f$, :'cid'),
  '23514', NULL,
  'Eine kaputte Tabelle IN einer Teilaufgabe wird ebenso abgewiesen'
);

-- Die Regression, die zaehlt: der neue CHECK darf die 299 Bestandsitems nicht
-- anfassen. Ihr question_payload traegt das AnswerPayload inkl. 'accepted' und
-- gar keinen 'table'-Schluessel — der CHECK beisst dort nicht.
select lives_ok(
  format($f$insert into tasks (cluster_id, content_type, input_type, status, question,
                               source, source_ref, question_payload)
            values (%L, 'exercise', 'MC', 'ready', 'Bestand', 'test', 'inv4-legacy',
              '{"input_type":"MC","options":[{"id":"a","label":"A"}],
                "correct":["a"],"accepted":["a"]}'::jsonb)$f$, :'cid'),
  'Bestandszeilen ohne table-Schluessel bleiben unberuehrt (kein pauschaler Vertrag auf die Spalte)'
);

-- ============================================================================
-- B) Der Payload: strukturiert — und ohne Loesung
-- ============================================================================
set local role authenticated;
select pg_temp.act_as(:'student_uid');

-- Kein Pipe-Fliesstext mehr. headers und rows, feldgenau.
select is(
  (select public.lsa_question_payload(:'t_flat') -> 'table'),
  '{"headers":["Bundesland","Einwohner pro km2"],
    "rows":[["Baden-Wuerttemberg","301"],["Bayern","177"],["Berlin","3.861"]]}'::jsonb,
  'Das flache Item liefert die Tabelle strukturiert aus (headers + rows, Zeilenfolge stabil)'
);

-- DIE Assertion aus der Aufgabe. Der ganze Payload-Text, nicht nur die oberste
-- Ebene: 'accepted' liegt im selben question_payload direkt neben der Tabelle.
select is(
  (select public.lsa_question_payload(:'t_flat')::text
          ~* '(correct|accepted|solution|correct_answers|hints|typical_errors|geheim)'),
  false,
  'Payload MIT Tabelle enthaelt KEINE Loesung — obwohl accepted im selben question_payload liegt'
);

select is(
  (select public.lsa_question_payload(:'t_plain') ? 'table'),
  false,
  'Ein Item ohne Tabelle traegt den Schluessel table gar nicht erst (jsonb_strip_nulls)'
);

-- Multi-Part: die Tabelle steht im STAMM und gilt fuer alle Teilaufgaben.
select is(
  (select public.lsa_question_payload(:'t_mp') -> 'table'),
  '{"headers":["Bundesland","Einwohner pro km2"],
    "rows":[["Baden-Wuerttemberg","301"],["Bayern","177"]]}'::jsonb,
  'Multi-Part: die Stamm-Tabelle steht oben — neben stem und assets'
);

select is(
  (select public.lsa_question_payload(:'t_mp') -> 'parts' -> 1 -> 'table'),
  '{"headers":["Land","Wert"],"rows":[["Hessen","297"]]}'::jsonb,
  'Multi-Part: eine Teilaufgabe kann eine EIGENE Tabelle tragen'
);

select is(
  (select (public.lsa_question_payload(:'t_mp') -> 'parts' -> 0) ? 'table'),
  false,
  'Eine Teilaufgabe ohne Tabelle traegt den Schluessel nicht'
);

-- Rekursiv: Stamm-Tabelle, Teilaufgaben-Tabelle, Optionen — auf keiner Ebene ein
-- Loesungsfeld, obwohl task_solutions fuer dieses Item GEHEIM-MULTI haelt.
select is(
  (select public.lsa_question_payload(:'t_mp')::text
          ~* '(correct|accepted|solution|correct_answers|hints|typical_errors|geheim)'),
  false,
  'Multi-Part-Payload mit Tabellen traegt auf KEINER Ebene ein Loesungsfeld (rekursiv geprueft)'
);

-- ============================================================================
-- C) Gebaut, nicht durchgereicht
-- ============================================================================
reset role;

-- Der Builder liest headers und rows — und sonst nichts. Selbst wenn ein
-- Loesungsfeld je an einem CHECK vorbei in die Zeile kaeme, kaeme es hier nicht
-- heraus. Das ist die Zusage, die nicht von einem CHECK abhaengt.
select is(
  public.lsa_public_table(
    '{"headers":["Land"],"rows":[["Bayern"]],
      "accepted":["177"],"solution":"GEHEIM","hints":[{"level":1,"text":"GEHEIM"}]}'::jsonb
  ),
  '{"headers":["Land"],"rows":[["Bayern"]]}'::jsonb,
  'lsa_public_table baut Zelle fuer Zelle neu — geschmuggelte Felder kommen nicht heraus'
);

select is(
  public.lsa_public_table('"Bayern | 177"'::jsonb),
  NULL::jsonb,
  'Pipe-Fliesstext ist keine Tabelle: der Builder liefert NULL, kein Scheinergebnis'
);

select * from finish();
rollback;
