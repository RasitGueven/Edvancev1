-- Lesender Abzug fuer tools/lena-board-daten.mjs (Lena-Board, Datenmigration 4).
-- Aufruf: ~/bin/dbread -tA -f tools/lena-board-snapshot.sql -o docs/lena-board/daten-snapshot.json
-- Board-Logik wie pruef_ausschluss / pruef_board (Entscheidungen 13, 14), hier ohne Ausgangsfassung,
-- weil es sie vor dem Einspielen nicht gibt.
\pset format unaligned
\pset tuples_only on
with a as (
  select t.*,
    case
      when t.source = 'VERA8_IQB' then 'vera8'
      when not coalesce(t.is_active, false) or t.is_tutorial or t.content_type <> 'exercise' then 'inaktiv'
      when t.input_type is null or t.input_type not in ('MC','NUMERIC','SHORT_TEXT','MULTI_PART','TERM') then 'typ'
      when t.skill_key is null or not exists (select 1 from skill_thema st where st.skill_key = t.skill_key) then 'ohne_fertigkeit'
      when not exists (select 1 from task_solutions s where s.task_id = t.id
                         and lsa_has_answers(t.input_type, t.parts, s.correct_answers)) then 'ohne_loesung'
      when coalesce(btrim(t.question), '') = '' or t.input_type is null or t.afb is null or t.cluster_id is null
           or t.curriculum_grade is null then 'gate'
      when (coalesce(t.needs_image, false) or exists (select 1 from jsonb_array_elements(t.parts) p where p -> 'needs_image' = 'true'::jsonb))
           and jsonb_array_length(t.assets) = 0
           and not exists (select 1 from task_figures f where f.task_id = t.id and f.svg_hash is not null) then 'bild_fehlt'
    end grund
  from tasks t),
b as (
  select a.id, th.stufe, th.thema_key, th.label thema_label, th.sort thema_sort, a.input_type, a.afb, a.title, a.status,
         row_number() over (order by case th.stufe when 'erste' then 1 when 'zweite' then 2 else 3 end,
                            th.sort nulls last, s.fundament_tiefe, a.skill_key, a.sondierrang nulls last, a.source_ref, a.id) reihenfolge
    from a join skills s on s.skill_key = a.skill_key
    join skill_thema st on st.skill_key = a.skill_key join themen th on th.thema_key = st.thema_key
   where a.grund is null)
select json_build_object(
  'abgezogen_am', now(),
  'board', (select json_agg(row_to_json(b) order by reihenfolge) from b),
  'aufgaben', (select json_agg(json_build_object('id', t.id, 'status', t.status, 'vera8', t.source = 'VERA8_IQB',
                 'vorbefuellt', t.vorbefuellt, 'typical_errors', s.typical_errors) order by t.id)
                 from tasks t left join task_solutions s on s.task_id = t.id),
  'review_ohne_pruefung', (select count(*) from tasks where status = 'review' and source is distinct from 'VERA8_IQB'));
