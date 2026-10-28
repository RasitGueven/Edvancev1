-- ============================================================================
-- Reihe 1 · A6 Bauformen der Reihe: gilt fuer jede eingespielte Bauform und jede Instanz (Datenmigrationen
-- …_reihe1_bauform_<key>).
--   1 jede Instanz: Pool session, Status draft, gruene Pruefmaschine, drei Hinweise, Loesungsweg
--   2 jeder Fehlbild-Schluessel der Steckbriefe steht im Katalog (fehlbild_labels)
--   3 klassische Formate (NUMERIC, MC, MULTI_PART): session_bewerten — die echte Wertung der Session — wertet die
--     kanonische Antwort jedes Teils richtig und jede bekannte falsche Antwort mit ihrem Fehlbild (dieselbe Abfrage
--     nutzt die Pruefmaschine, scripts/bauformen/klassisch.py)
--   4 Instanzen mit Figur haben ihre Figur-Zeile; Graph-Auswahl je Option eine
-- Am Ende rollback.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select plan(8);

select cmp_ok((select count(*)::int from bauformen), '>=', 2, '0 es gibt Bauformen');
select is((select count(*)::int from tasks t where t.bauform_id is not null
            and not (t.einsatz = '{session}' and public.instanz_gruen(t.pruefmaschine))), 0,
          '1 jede Instanz: Pool session, Pruefmaschine gruen');
select is((select count(*)::int from tasks t join task_solutions s on s.task_id = t.id
            where t.bauform_id is not null
              and (jsonb_array_length(coalesce(s.hints, '[]')) <> 3 or coalesce(btrim(s.solution), '') = '')), 0,
          '1 jede Instanz: drei Hinweise und ein Loesungsweg');
select is((select count(*)::int from tasks t where t.bauform_id is not null
            and not exists (select 1 from task_solutions s where s.task_id = t.id)), 0, '1 jede Instanz hat eine Loesung');
select is((select coalesce(jsonb_agg(distinct f ->> 'key'), '[]') from bauformen b,
                  jsonb_array_elements(case when jsonb_typeof(b.steckbrief -> 'fehlbilder') = 'array'
                                            then b.steckbrief -> 'fehlbilder' else '[]' end) f
            where not exists (select 1 from fehlbild_labels l where l.slug = f ->> 'key')), '[]'::jsonb,
          '2 jeder Fehlbild-Schluessel steht im Katalog');

-- 3) Probefaelle aus den gespeicherten Loesungen
create temp table probe on commit drop as
select t.id, null::int as teil, jsonb_build_object('text', s.acceptance ->> 'canonical') as eingabe, 'richtig' as soll,
       null::text as soll_key
  from tasks t join task_solutions s on s.task_id = t.id
 where t.bauform_id is not null and t.input_type = 'NUMERIC'
union all
select t.id, null, to_jsonb(array[s.acceptance ->> 'canonical']), 'richtig', null
  from tasks t join task_solutions s on s.task_id = t.id
 where t.bauform_id is not null and t.input_type = 'MC'
union all
select t.id, p.key::int, jsonb_build_object('text', p.value ->> 'canonical'), 'richtig', null
  from tasks t join task_solutions s on s.task_id = t.id, jsonb_each(s.acceptance) p
 where t.bauform_id is not null and t.input_type = 'MULTI_PART'
   and (select x ->> 'kind' from jsonb_array_elements(t.parts) x where x ->> 'nr' = p.key) = 'short_input'
union all
select t.id, null, case when t.input_type = 'MC' then to_jsonb(array[k.key]) else jsonb_build_object('text', k.key) end,
       'falsch', k.value #>> '{}'
  from tasks t join task_solutions s on s.task_id = t.id, jsonb_each(coalesce(s.acceptance -> 'known_errors', '{}')) k
 where t.bauform_id is not null and t.input_type in ('NUMERIC', 'MC')
union all
select t.id, p.key::int, jsonb_build_object('text', k.key), 'falsch', k.value #>> '{}'
  from tasks t join task_solutions s on s.task_id = t.id, jsonb_each(s.acceptance) p,
       jsonb_each(coalesce(p.value -> 'known_errors', '{}')) k
 where t.bauform_id is not null and t.input_type = 'MULTI_PART';

select is((select count(*)::int from probe pr, lateral public.session_bewerten(pr.id, pr.teil, pr.eingabe) r
            where r.ergebnis is distinct from pr.soll or (pr.soll = 'falsch' and r.fehlbild_slug is distinct from pr.soll_key)), 0,
          '3 session_bewerten wertet jede kanonische Antwort richtig und jede bekannte falsche mit ihrem Fehlbild');

select is((select count(*)::int from tasks t where t.bauform_id is not null and t.input_type <> 'GRAPH_AUSWAHL'
            and t.question ~ 'Koordinatensystem|Graph|abgebildet|Bild'
            and not exists (select 1 from task_figures f where f.task_id = t.id)), 0,
          '4 Aufgaben, die auf ein Bild verweisen, haben eine Figur');
select is((select count(*)::int from tasks t where t.input_type = 'GRAPH_AUSWAHL' and t.bauform_id is not null
            and (select count(*) from task_figur_optionen f where f.task_id = t.id)
                <> jsonb_array_length(t.question_payload -> 'optionen')), 0,
          '4 Graph-Auswahl: je Option eine Figur');

select * from finish();
rollback;
