-- Reihe 1 · VERA8 entfernen (Migration 20261028143121_reihe1_vera8_entfernen).
--   Neuaufbau: kein VERA8. Prod-Weg: angelegte VERA8-Aufgabe mit Loesung wird von der Migration (hier noch einmal
--   eingelesen) entfernt, eine andere Aufgabe bleibt unveraendert. Den Abbruch des Waechters (fremder Verweis) hat die
--   Zweitpruefung in einer zurueckgerollten Transaktion belegt. Am Ende rollback.
begin;
create extension if not exists pgtap with schema extensions;
select plan(4);
select is((select count(*)::int from tasks where source = 'VERA8_IQB'), 0, 'Neuaufbau: keine VERA8-Aufgabe');

insert into tasks (content_type, input_type, status, is_active, question, est_duration_sec, source, source_ref, einsatz)
values ('exercise', 'NUMERIC', 'draft', true, 'ZZ VERA8 Probe', 60, 'VERA8_IQB', 'zz-v8-1', '{lsa}'),
       ('exercise', 'NUMERIC', 'draft', true, 'ZZ andere Probe', 60, 'reihe1_v8_test', 'zz-andere', '{lsa}');
insert into task_solutions (task_id, correct_answers)
select id, '["1"]'::jsonb from tasks where source_ref in ('zz-v8-1', 'zz-andere');
select md5(t::text) as andere from tasks t where source_ref = 'zz-andere' \gset

\ir ../migrations/20261028143121_reihe1_vera8_entfernen.sql

select is((select count(*)::int from tasks where source = 'VERA8_IQB'), 0, 'die Migration entfernt VERA8');
select is((select count(*)::int from task_solutions s join tasks t on t.id = s.task_id where t.source_ref = 'zz-andere'), 1,
          'die Loesung der anderen Aufgabe bleibt');
select is((select md5(t::text) from tasks t where source_ref = 'zz-andere'), :'andere', 'die andere Aufgabe bleibt unveraendert');
select * from finish();
rollback;
