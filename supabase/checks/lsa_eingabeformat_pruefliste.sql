-- Prüfliste Eingabeformat (LSA-Erlebnis L1, Punkt 1) — nur lesend, z. B. `dbread -f supabase/checks/lsa_eingabeformat_pruefliste.sql`.
--
-- Einheiten: jede short_input-Aufgabe und jeder short_input-Teil eines Mehrteilers. Der Pool wird hier OHNE das
-- neue Gate bestimmt (sonst fehlten genau die Fälle, um die es geht): aktiv, kein Tutorial, exercise, Einsatz lsa,
-- Lösungen vorhanden, Status ready (Pool echt) bzw. testlauf_inhalt_sichtbar (Pool Testlauf).
--
-- Abfrage 1: Zählung je Pool und Hinweis. Abfrage 2: die Prüfliste (kein eindeutiger Hinweis), Abfrage 3: die
-- Bruch-Treffer, die Rasit/Lena von Hand ansehen (Vorbefüllt-Kennzeichen 'bruch' bzw. 'parts.<nr>.bruch').

with basis as (
  select t.*, s.correct_answers,
         t.status = 'ready' as echt,
         t.status = 'ready' or public.testlauf_inhalt_sichtbar(t.id) as testlauf
    from public.tasks t join public.task_solutions s on s.task_id = t.id
   where coalesce(t.is_active, false) and not coalesce(t.is_tutorial, false) and t.content_type = 'exercise'
     and 'lsa' = any (t.einsatz) and public.lsa_has_answers(t.input_type, t.parts, s.correct_answers)
), einheiten as (
  select b.id as task_id, null::int as teil, b.status, b.echt, b.testlauf,
         public.lsa_input_hint(b.input_type, b.bruch, b.correct_answers, b.unit) as hinweis, b.correct_answers as loesungen
    from basis b where b.input_type not in ('MC', 'MULTI_PART')
  union all
  select b.id, (p ->> 'nr')::int, b.status, b.echt, b.testlauf,
         public.lsa_teil_input_hint(p, b.correct_answers -> (p ->> 'nr')), b.correct_answers -> (p ->> 'nr')
    from basis b, jsonb_array_elements(b.parts) p
   where b.input_type = 'MULTI_PART' and p ->> 'kind' = 'short_input'
)
select pool, (teil is not null) as ist_teil, coalesce(hinweis, 'kein Hinweis') as hinweis, count(*)
  from (select 'echt' as pool, * from einheiten where echt
        union all select 'testlauf', * from einheiten where testlauf) x
 group by 1, 2, 3 order by 1, 2, 3;

-- Abfrage 2: Prüfliste
select t.id as task_id, p.teil, t.status, p.loesungen::text as correct_answers
  from public.tasks t
  join public.task_solutions s on s.task_id = t.id
  cross join lateral (
    select null::int as teil, s.correct_answers as loesungen,
           public.lsa_input_hint(t.input_type, t.bruch, s.correct_answers, t.unit) as hinweis
     where t.input_type not in ('MC', 'MULTI_PART')
    union all
    select (q ->> 'nr')::int, s.correct_answers -> (q ->> 'nr'), public.lsa_teil_input_hint(q, s.correct_answers -> (q ->> 'nr'))
      from jsonb_array_elements(t.parts) q
     where t.input_type = 'MULTI_PART' and q ->> 'kind' = 'short_input'
  ) p
 where p.hinweis is null
   and coalesce(t.is_active, false) and not coalesce(t.is_tutorial, false) and t.content_type = 'exercise'
   and 'lsa' = any (t.einsatz) and public.lsa_has_answers(t.input_type, t.parts, s.correct_answers)
   and (t.status = 'ready' or public.testlauf_inhalt_sichtbar(t.id))
 order by t.status, t.id, p.teil;

-- Abfrage 3: Bruch-Treffer zur Handprüfung
select t.id as task_id, k.key as kennzeichen, t.status
  from public.tasks t, jsonb_each(t.vorbefuellt) k
 where k.key = 'bruch' or k.key ~ '^parts\.[0-9]+\.bruch$'
 order by t.status, t.id, k.key;
