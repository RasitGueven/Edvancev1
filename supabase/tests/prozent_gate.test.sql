-- ============================================================================
-- Prozent-Gate (Migration 20261021081417): zwei blockierende Regeln im Freigabe-Gate.
--
-- Zusagen:
--   A) prozent_ohne_marker: Feld zeigt „%“ (tasks.unit), Wertungsregel ohne acceptance.unit = '%'.
--      Mit Marker (Zinsaufgabe) frei; ohne Wertungsregel frei (lsa_grade wertet dann über correct_answers).
--   B) prozentzahl_ohne_zeichen: eine richtige Antwort ohne Einheit ist das 100-Fache der kanonischen
--      Antwort (kanonisch „20 %“ zählt als 0,2), ohne Marker. „60 %“, „60%“, „60/100“ sind frei; andere
--      Einheiten (0,5 m gegen 50) und der Wert 0 auch.
--   C) freigabe_gate_fehler liefert die Schlüssel mit dem bisherigen Präfix „task_status_set: “, die
--      bisherigen Prüfungen kommen zuerst.
-- Eigene Fixtures (Quelle 'pz_test'), alles in einer Transaktion, am Ende rollback.
-- ============================================================================
begin;
-- Reihe 1 A1: einsatz hat keinen Default mehr; die Aufgaben dieses Tests gehören zum Pool {lsa} (nur in dieser Transaktion).
alter table public.tasks alter column einsatz set default '{lsa}';
create extension if not exists pgtap with schema extensions;

select plan(18);

-- --- A) / B) prozent_gate_fehler ---------------------------------------------
select is(public.prozent_gate_fehler('%', '{"canonical":"12","equivalents":["12 %"]}', '["12","12 %"]'),
          'prozent_ohne_marker', 'A: % am Feld ohne Marker');
select is(public.prozent_gate_fehler('%', '{"canonical":"3","unit":"%"}', '["3","3 %"]'),
          null, 'A: Zinsaufgabe mit Marker bleibt frei');
select is(public.prozent_gate_fehler('%', null, '["10"]'),
          null, 'A: ohne Wertungsregel frei');
select is(public.prozent_gate_fehler(null, '{"canonical":"3/5"}', '["3/5","0,6","60 %","60"]'),
          'prozentzahl_ohne_zeichen', 'B: 60 bei 3/5 in correct_answers');
select is(public.prozent_gate_fehler(null, '{"canonical":"3/5","equivalents":["60"]}', '["3/5"]'),
          'prozentzahl_ohne_zeichen', 'B: 60 bei 3/5 in equivalents');
select is(public.prozent_gate_fehler(null, '{"canonical":"20 %"}', '["20 %","0,2","20"]'),
          'prozentzahl_ohne_zeichen', 'B: 20 bei kanonisch 20 %');
select is(public.prozent_gate_fehler(null, '{"canonical":"0,488"}', '["0,488","48,8"]'),
          'prozentzahl_ohne_zeichen', 'B: Dezimalzahl 48,8 bei 0,488');
select is(public.prozent_gate_fehler(null, '{"canonical":"3/5"}', '["3/5","0,6","60 %","60%","60/100"]'),
          null, 'B: nur richtige Schreibweisen');
select is(public.prozent_gate_fehler(null, '{"canonical":"20 %"}', '["20 %","1/5","0,2","20%","20/100"]'),
          null, 'B: kanonisch 20 % mit freier Schreibweise ohne 20 frei (5bcca7e7 nach M2)');
select is(public.prozent_gate_fehler(null, '{"canonical":"0,5 m"}', '["0,5 m","50"]'),
          null, 'B: andere Einheit (0,5 m gegen 50) frei');
select is(public.prozent_gate_fehler(null, '{"canonical":"0"}', '["0"]'),
          null, 'B: Wert 0 frei');
select is(public.prozent_gate_fehler(null, '{"canonical":"3","unit":"%"}', '["3","300"]'),
          null, 'B: mit Marker frei');

-- --- C) Verdrahtung im Gate --------------------------------------------------
create function pg_temp.aufgabe(p_ref text, p_unit text, p_ca jsonb, p_acc jsonb, p_cluster boolean default true)
returns uuid language plpgsql as $$
declare v uuid;
begin
  insert into tasks (content_type, input_type, title, question, afb, cluster_id, curriculum_grade,
                     skill_key, source, source_ref, status, unit)
  values ('exercise', 'NUMERIC', 'PZ · ' || p_ref, 'Wie groß ist die Wahrscheinlichkeit?', 'I',
          case when p_cluster then (select id from skill_clusters order by id limit 1) end, 8,
          'geo_kreis_umfang', 'pz_test', p_ref, 'draft', p_unit)
  returning id into v;
  insert into task_solutions (task_id, correct_answers, acceptance, solution)
  values (v, p_ca, p_acc, 'Rechnung');
  return v;
end $$;

select pg_temp.aufgabe('pz-60', null, '["3/5","0,6","60 %","60"]', '{"canonical":"3/5","equivalents":["0,6","60 %","60"]}') as p60 \gset
select pg_temp.aufgabe('pz-sauber', null, '["3/5","0,6","60 %","60/100"]', '{"canonical":"3/5","equivalents":["0,6","60 %","60/100"]}') as sauber \gset
select pg_temp.aufgabe('pz-zins', '%', '["3","3 %"]', '{"canonical":"3","equivalents":["3 %"],"unit":"%"}') as zins \gset
select pg_temp.aufgabe('pz-zins-ohne', '%', '["3","3 %"]', '{"canonical":"3","equivalents":["3 %"]}') as zinsohne \gset
select pg_temp.aufgabe('pz-cluster', null, '["3/5","60"]', '{"canonical":"3/5","equivalents":["60"]}', false) as cluster \gset

select is(public.freigabe_gate_fehler(:'p60'), 'task_status_set: prozentzahl_ohne_zeichen', 'C: Gate hält 60 bei 3/5 auf');
select is(public.freigabe_gate_fehler(:'sauber'), null, 'C: bereinigte Aufgabe frei');
select is(public.freigabe_gate_fehler(:'zins'), null, 'C: Zinsaufgabe mit Marker frei');
select is(public.freigabe_gate_fehler(:'zinsohne'), 'task_status_set: prozent_ohne_marker', 'C: Zinsaufgabe ohne Marker aufgehalten');
select is(public.freigabe_gate_fehler(:'cluster'), 'task_status_set: Cluster fehlt (sonst nie im LSA-Pool)',
          'C: bisherige Prüfungen kommen zuerst');
select ok(not has_function_privilege('authenticated', 'public.prozent_gate_fehler(text, jsonb, jsonb)', 'execute'),
          'prozent_gate_fehler ist nicht für Clients freigegeben');

select * from finish();
rollback;
