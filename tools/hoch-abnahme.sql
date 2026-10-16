-- hoch-abnahme.sql — Abnahme für 20261016151208_hochzahlen_inhalt in der Wegwerf-DB (tools/hoch-wegwerf-db.sh).
-- Erwartet das Schema "vorher" mit Kopien von tasks/task_solutions/task_pruefungen und den Befunden von vorher.
\set ON_ERROR_STOP 1
\pset format aligned
\pset footer off

\echo '── vorher → nachher (Aufgabentext, letzte Zeile)'
select left(t.id::text, 8) id, t.skill_key,
       split_part(v.question, E'\n', 3) vorher, split_part(t.question, E'\n', 3) nachher,
       public.lsa_question_payload(t.id) ->> 'prompt' payload_prompt
  from public.tasks t join vorher.tasks v using (id)
 where t.question is distinct from v.question
 order by 4;

do $$
declare n int; b int;
begin
  -- 1. Genau 15 Aufgabentexte geändert, kein "^" mehr außer in der ausgelassenen 5c73a51d.
  select count(*) into n from public.tasks t join vorher.tasks v using (id) where t.question is distinct from v.question;
  if n <> 15 then raise exception 'hoch-abnahme: % statt 15 Texte geaendert', n; end if;
  select count(*) into n from public.tasks where pruef_pilot and question like '%^%' and id::text not like '5c73a51d%';
  if n <> 0 then raise exception 'hoch-abnahme: noch % Pilot-Texte mit ^', n; end if;
  -- 2. question_payload.prompt folgt dem Text; sonst nichts an question_payload geändert.
  select count(*) into n from public.tasks t join vorher.tasks v using (id)
   where t.question is distinct from v.question
     and (t.question_payload ->> 'prompt' is distinct from t.question
          or t.question_payload - 'prompt' is distinct from v.question_payload - 'prompt');
  if n <> 0 then raise exception 'hoch-abnahme: question_payload bei % Aufgaben abweichend', n; end if;
  -- 3. Nur question, question_payload und pruef_version geändert.
  select count(*) into n from public.tasks t join vorher.tasks v using (id)
   where (to_jsonb(t) - '{question,question_payload,pruef_version}'::text[])
         is distinct from (to_jsonb(v) - '{question,question_payload,pruef_version}'::text[]);
  if n <> 0 then raise exception 'hoch-abnahme: % Aufgaben mit weiteren Aenderungen', n; end if;
  -- 4. task_solutions (Antworten, acceptance, Lösung, Hinweise samt Status) und Prüfstatus unverändert.
  select count(*) into n from (select * from public.task_solutions except select * from vorher.sol) x;
  if n <> 0 then raise exception 'hoch-abnahme: % task_solutions geaendert', n; end if;
  select count(*) into n from (select * from public.task_pruefungen except select * from vorher.pruef) x;
  if n <> 0 then raise exception 'hoch-abnahme: % task_pruefungen geaendert', n; end if;
  -- 5. Keine neuen Befunde in pruef_auffaelligkeiten.
  select count(*) into b
    from public.tasks t join public.task_solutions s on s.task_id = t.id join vorher.befunde vb on vb.id = t.id
   where public.pruef_auffaelligkeiten(t, s.correct_answers, s.acceptance, s.solution) is distinct from vb.befunde;
  if b <> 0 then raise exception 'hoch-abnahme: Befunde bei % Aufgaben veraendert', b; end if;
  raise notice 'hoch-abnahme: ok (15 Texte, Loesungen/Pruefstatus unveraendert, Befunde gleich)';
end $$;

\echo '── Befunde der 16 Aufgaben mit Hochzahl (vorher = nachher)'
select left(t.id::text, 8) id, vb.befunde::text vorher,
       public.pruef_auffaelligkeiten(t, s.correct_answers, s.acceptance, s.solution)::text nachher
  from public.tasks t join public.task_solutions s on s.task_id = t.id join vorher.befunde vb on vb.id = t.id
 order by 1;
