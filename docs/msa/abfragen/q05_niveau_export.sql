-- Q05 · Abschnitt 2 (Niveau-Prüfung): freigegebene LSA-Aufgaben (ready) und vorgeschlagene Entwürfe (pruef_ziel_roh.task_ids)
--       der MSA-Skills mit Text, Teilaufgaben, Lösung — Grundlage für den Subagenten
-- braucht: msa_basis.sql
\set QUIET on
\pset format unaligned
\pset tuples_only on
, vorschlag as (select unnest(z.task_ids) id from public.pruef_ziel_roh() z)
select json_agg(json_build_object(
         'id', t.id, 'skill', t.skill_key, 'label', s.label, 'herk', s.klasse_herkunft,
         'art', case when t.status = 'ready' then 'freigegeben' else 'vorgeschlagen' end,
         'format', t.input_type, 'afb', t.afb, 'rechner', t.taschenrechner,
         'frage', t.question,
         'teile', (select json_agg(e.p ->> 'prompt' order by e.nr) from jsonb_array_elements(
                     case when jsonb_typeof(t.parts) = 'array' then t.parts else '[]' end) with ordinality e(p, nr)),
         'loesung', (select so.correct_answers from task_solutions so where so.task_id = t.id limit 1),
         'optionen', t.question_payload -> 'options')
       order by t.skill_key, t.status desc, t.id)
  from tasks t join skills s using (skill_key) join msa m using (skill_key)
 where m.msa and 'lsa' = any (t.einsatz)
   and (t.status = 'ready' or t.id in (select id from vorschlag));
