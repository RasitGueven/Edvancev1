-- lena-rf-abnahme.sql — Abnahmefälle für lsa_grade („%“ als Faktor), aufgerufen von tools/lena-rf-wegwerf-db.sh.
--   psql … -v phase=vorher -f tools/lena-rf-abnahme.sql   (vor M1: hält die alte Wertung fest)
--   psql … -v phase=nachher -f tools/lena-rf-abnahme.sql  (nach M1–M3: neue Wertung, Liste aller Unterschiede)
-- Eingaben je Aufgabe mit Prozent-Schreibweise: alle correct_answers, equivalents und known_errors-Schlüssel,
-- dazu jede Antwort ohne % mit angehängtem „ %“ und jede Antwort mit % ohne das Zeichen.
create table if not exists public.zz_abnahme (phase text, task_id uuid, eingabe text, stufe text, richtig boolean,
                                               primary key (phase, task_id, eingabe));
delete from public.zz_abnahme where phase = :'phase';
with a as (
  select t.id, t.input_type, s.acceptance acc, s.correct_answers ca
    from public.tasks t join public.task_solutions s on s.task_id = t.id
   where t.input_type not in ('MC', 'TERM', 'MULTI_PART')
     and jsonb_typeof(s.acceptance) = 'object' and s.acceptance ? 'canonical'
     and jsonb_typeof(s.correct_answers) = 'array'
     and (s.acceptance::text like '%\%%' or s.correct_answers::text like '%\%%' or t.unit = '%')
), w as (
  select a.id, x from a, jsonb_array_elements_text(a.ca) x
  union select a.id, x from a, jsonb_array_elements_text(case when jsonb_typeof(a.acc -> 'equivalents') = 'array'
                                                          then a.acc -> 'equivalents' else '[]' end) x
  union select a.id, k from a, jsonb_object_keys(case when jsonb_typeof(a.acc -> 'known_errors') = 'object'
                                                 then a.acc -> 'known_errors' else '{}' end) k
  union select a.id, a.acc ->> 'canonical' from a
), e as (
  select id, x from w
  union select id, btrim(x) || ' %' from w where x not like '%\%%'
  union select id, btrim(replace(x, '%', '')) from w where x like '%\%%'
)
insert into public.zz_abnahme
select :'phase', a.id, e.x, public.lsa_grade(a.input_type, a.acc, a.ca, jsonb_build_object('text', e.x)),
       coalesce(public.lsa_is_correct(a.input_type, a.ca, jsonb_build_object('text', e.x)), false)
  from a join e on e.id = a.id
on conflict do nothing;

\if :{?vergleich}
\pset footer off
select count(distinct task_id) as aufgaben, count(*) as eingaben from public.zz_abnahme where phase = 'vorher';
\echo 'Unterschiede alt → neu (Wertung lsa_grade; correct = lsa_is_correct):'
select left(n.task_id::text, 8) as aufgabe, t.skill_key, n.eingabe,
       v.stufe || ' → ' || n.stufe as grade, v.richtig || ' → ' || n.richtig as correct
  from public.zz_abnahme n
  join public.zz_abnahme v on v.phase = 'vorher' and v.task_id = n.task_id and v.eingabe = n.eingabe
  join public.tasks t on t.id = n.task_id
 where n.phase = 'nachher' and (v.stufe, v.richtig) is distinct from (n.stufe, n.richtig)
 order by t.skill_key, 1, n.eingabe;
\echo 'Uneinig nach M1–M3 (lsa_is_correct richtig, lsa_grade nicht voll oder umgekehrt):'
select left(n.task_id::text, 8) as aufgabe, t.skill_key, t.status, n.eingabe, n.stufe, n.richtig
  from public.zz_abnahme n join public.tasks t on t.id = n.task_id
 where n.phase = 'nachher' and (n.richtig <> (n.stufe = 'voll'))
 order by t.skill_key, 1, n.eingabe;
\endif
