-- Reihe 1 · VERA8 entfernt (Migration 20261028143121_reihe1_vera8_entfernen): keine VERA8-Aufgabe, keine Loesung,
-- keine LSA-Antwort auf eine VERA8-Aufgabe; die uebrigen Prefill-Aufgaben bleiben.
begin;
create extension if not exists pgtap with schema extensions;
select plan(3);
select is((select count(*)::int from tasks where source = 'VERA8_IQB'), 0, 'keine VERA8-Aufgabe');
select is((select count(*)::int from task_solutions s where not exists (select 1 from tasks t where t.id = s.task_id)), 0,
          'keine Loesung ohne Aufgabe');
select cmp_ok((select count(*)::int from tasks where source <> 'VERA8_IQB'), '>', 0, 'die uebrigen Aufgaben bleiben');
select * from finish();
rollback;
