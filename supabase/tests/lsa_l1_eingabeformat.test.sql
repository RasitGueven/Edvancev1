-- ============================================================================
-- LSA-Erlebnis L1, Punkt 1: Eingabeformat (input_hint) je Aufgabe und je Teil, Gate im LSA-Pool.
-- Migration 20261021082756_lsa_eingabeformat. Anforderung Fassung 1.1, Daten Punkt 1; Abnahme 12.
--   E1 Regel lsa_bruch_vorschlag: jede Loesung -?\d+/\d+ → Bruch; keine → Zahl; gemischt/leer → offen
--   E2 Payload: input_hint an short_input (number | fraction | term), nie an MC, nie die Loesung
--   E3 Teile: input_hint je short_input-Teil, Term ueber parts[i].input_type = 'TERM'
--   E4 Gate: ohne eindeutigen Hinweis nicht im Pool (Aufgabe und Mehrteiler); die Angabe in der
--      Item-Pflege (tasks.bruch / parts[i].bruch) macht ihn eindeutig
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(31);

\ir lsa_l1_fixture.sql

-- E1 Regel ----------------------------------------------------------------
select is(public.lsa_bruch_vorschlag('["3/4","-6/8"]'), true, 'E1 nur Brueche → Bruch');
select is(public.lsa_bruch_vorschlag('["12","12,5"]'), false, 'E1 keine Brueche → Zahl');
select is(public.lsa_bruch_vorschlag('["3/4","0,75"]'), null::boolean, 'E1 gemischt → kein Hinweis');
select is(public.lsa_bruch_vorschlag('["1/3","+1/3"]'), null::boolean,
          'E1 Regel woertlich: „+1/3“ ist kein Bruch, die Aufgabe kommt auf die Pruefliste');
select is(public.lsa_bruch_vorschlag('[]'), null::boolean, 'E1 ohne Loesung → kein Hinweis');
select is(public.lsa_bruch_vorschlag('["+1/3"]'), null::boolean,
          'E1 nur Brueche ausserhalb der Regel („+1/3“) → Pruefliste, nicht Zahl');
select is(public.lsa_bruch_vorschlag('"3/4"'), null::boolean, 'E1 keine Liste → kein Hinweis');

-- Fixture-Aufgaben
select pg_temp.l1_aufgabe('num', 'NUMERIC', '["12","12,0"]') as t_num \gset
select pg_temp.l1_aufgabe('frac', 'NUMERIC', '["3/4","6/8"]') as t_frac \gset
select pg_temp.l1_aufgabe('mix', 'NUMERIC', '["3/4","0,75"]') as t_mix \gset
select pg_temp.l1_aufgabe('term', 'TERM', '["3x-6"]') as t_term \gset
select pg_temp.l1_aufgabe('expl', 'NUMERIC', '["3/4"]', '[]', false) as t_expl \gset
select pg_temp.l1_aufgabe('mc', 'MC', '["b"]') as t_mc \gset
select pg_temp.l1_aufgabe('mp', 'MULTI_PART', '{"1":["1/2"],"2":["x+5"],"3":["a"]}',
  '[{"nr":1,"kind":"short_input","prompt":"Teil a"},
    {"nr":2,"kind":"short_input","prompt":"Teil b","input_type":"TERM"},
    {"nr":3,"kind":"mc","prompt":"Teil c","options":[{"id":"a","label":"ja"},{"id":"b","label":"nein"}]}]') as t_mp \gset
select pg_temp.l1_aufgabe('mpmix', 'MULTI_PART', '{"1":["0,5","1/2"],"2":["7"]}',
  '[{"nr":1,"kind":"short_input","prompt":"Teil a"},{"nr":2,"kind":"short_input","prompt":"Teil b"}]') as t_mpmix \gset

-- E2 Payload --------------------------------------------------------------
select is(public.lsa_question_payload(:'t_num') ->> 'input_hint', 'number', 'E2 Zahl-Aufgabe: number');
select is(public.lsa_question_payload(:'t_frac') ->> 'input_hint', 'fraction', 'E2 Bruch-Aufgabe: fraction');
select is(public.lsa_question_payload(:'t_term') ->> 'input_hint', 'term', 'E2 TERM-Aufgabe: term');
select is(public.lsa_question_payload(:'t_expl') ->> 'input_hint', 'number',
          'E2 die Angabe der Item-Pflege (bruch = false) gilt vor dem Vorschlag');
select ok(not (public.lsa_question_payload(:'t_mix') ? 'input_hint'), 'E2 gemischt: kein input_hint im Payload');
select ok(not (public.lsa_question_payload(:'t_mc') ? 'input_hint'), 'E2 MC: kein input_hint');
select ok(public.lsa_question_payload(:'t_frac')::text !~ '3/4|6/8|bruch',
          'E2 der Payload traegt weder die Loesung noch die Bruch-Angabe');

-- E3 Teile ----------------------------------------------------------------
select is((select array_agg(coalesce(p ->> 'input_hint', '-') order by (p ->> 'nr')::int)
             from jsonb_array_elements(public.lsa_question_payload(:'t_mp') -> 'parts') p),
          array['fraction', 'term', '-'], 'E3 Teile: Bruch, Term (input_type TERM), MC ohne Hinweis');
select ok(not (public.lsa_question_payload(:'t_mp') ? 'input_hint'), 'E3 der Mehrteiler selbst traegt keinen Hinweis');
select ok(public.lsa_question_payload(:'t_mp')::text !~ 'input_type|x\+5', 'E3 kein input_type, keine Loesung im Teil');
select is((select p ->> 'input_hint' from jsonb_array_elements(public.lsa_question_payload(:'t_mpmix') -> 'parts') p
            where p ->> 'nr' = '1'), null, 'E3 gemischter Teil: kein Hinweis');

-- E4 Gate -----------------------------------------------------------------
select is(public.lsa_im_pool(:'t_num'), true, 'E4 Zahl-Aufgabe im Pool');
select is(public.lsa_im_pool(:'t_frac'), true, 'E4 Bruch-Aufgabe im Pool');
select is(public.lsa_im_pool(:'t_term'), true, 'E4 TERM-Aufgabe im Pool');
select is(public.lsa_im_pool(:'t_mc'), true, 'E4 MC im Pool');
select is(public.lsa_im_pool(:'t_mp'), true, 'E4 Mehrteiler mit Hinweis je Teil im Pool');
select is(public.lsa_im_pool(:'t_mix'), false, 'E4 gemischt: nicht im Pool (Befund „Vor der Freigabe klaeren“)');
select is(public.lsa_im_pool(:'t_mpmix'), false, 'E4 Mehrteiler mit einem Teil ohne Hinweis: nicht im Pool');

update tasks set bruch = true where id = :'t_mix';
select is(public.lsa_im_pool(:'t_mix'), true, 'E4 nach der Angabe „Bruch“ in der Item-Pflege im Pool');
update tasks set parts = jsonb_set(parts, '{0,bruch}', 'false') where id = :'t_mpmix';
select is(public.lsa_im_pool(:'t_mpmix'), true, 'E4 Mehrteiler nach der Angabe am Teil im Pool');
select is((select p ->> 'input_hint' from jsonb_array_elements(public.lsa_question_payload(:'t_mpmix') -> 'parts') p
            where p ->> 'nr' = '1'), 'number', 'E4 … und der Teil traegt jetzt number');

-- Rechte: die Hilfsfunktionen sind nicht ueber die API aufrufbar.
select ok(not has_function_privilege('authenticated', 'public.lsa_input_hint(text, boolean, jsonb)', 'execute')
          and not has_function_privilege('anon', 'public.lsa_input_hint(text, boolean, jsonb)', 'execute'),
          'R lsa_input_hint nicht fuer anon/authenticated');
select ok(not has_function_privilege('authenticated', 'public.lsa_eingabeformat_eindeutig(text, boolean, jsonb, jsonb)', 'execute'),
          'R lsa_eingabeformat_eindeutig nicht fuer authenticated');
select ok(not has_function_privilege('authenticated', 'public.lsa_public_parts(jsonb, jsonb)', 'execute'),
          'R lsa_public_parts(jsonb, jsonb) nicht fuer authenticated');

select * from finish();
rollback;
