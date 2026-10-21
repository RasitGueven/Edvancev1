-- LSA-Erlebnis L1, Punkt 1: Eingabeformat je Aufgabe und je Teil (input_hint number | fraction | term).
--
-- Anforderung „LSA-Erlebnis nach Prototyp V1.3.1“ (Fassung 1.1), Daten und Backend, Punkt 1; Entscheidungen
-- Rasit 21.10.2026 (7.8) und Orchestrator a) und b).
--
-- Die Bruch-Angabe:
--   tasks.bruch          boolean  — an der Aufgabe (short_input). NULL = nicht festgelegt.
--   tasks.parts[i].bruch boolean  — am short_input-Teil eines Mehrteilers. Fehlt = nicht festgelegt.
-- Ein Teil wird Term über tasks.parts[i].input_type = 'TERM' (wie eine Aufgabe über tasks.input_type);
-- heute hat kein Teil diesen Schlüssel (L0: 0 von 606).
--
-- Regel (lsa_input_hint):
--   input_type TERM → 'term'
--   bruch true → 'fraction', bruch false → 'number'
--   bruch NULL → Vorschlag aus den Lösungen (lsa_bruch_vorschlag): JEDE Lösung passt (nach btrim) auf
--   ^-?\d+/\d+$ → 'fraction'; KEINE → 'number'; gemischt oder leer → kein Hinweis.
--   Die Bruch-Regel bleibt wörtlich (Orchestrator a): „+1/3“ und typografisches Minus sind kein Bruch.
--
-- Vorbefüllung: Die Migration schreibt den Vorschlag für alle vorhandenen Aufgaben und Teile fest
-- (bruch true/false), gemischte bleiben NULL und landen auf der Prüfliste
-- (supabase/checks/lsa_eingabeformat_pruefliste.sql). Bruch-Treffer bekommen das Vorbefüllt-Kennzeichen
-- (tasks.vorbefuellt 'bruch' bzw. 'parts.<nr>.bruch'), damit Rasit/Lena sie in der Item-Pflege bestätigen.
-- Compare-and-set: nur wo noch nichts steht; ein zweiter Lauf ändert nichts. tasks.pruef_version zählt per
-- Trigger hoch (wie bei jeder Änderung an tasks) — eine offene Prüfansicht meldet „neu laden“.
--
-- Gate (lsa_im_pool): Eine short_input-Aufgabe ohne eindeutigen Hinweis kommt nicht in den LSA-Pool, ebenso
-- ein Mehrteiler, bei dem ein short_input-Teil keinen hat (Orchestrator b). Neue Aufgaben ohne Angabe
-- bekommen den Vorschlag aus ihren Lösungen; nur gemischte fallen heraus.
--
-- Payload: short_input und short_input-Teile tragen input_hint (jsonb_strip_nulls: fehlt ohne Hinweis).

alter table public.tasks add column if not exists bruch boolean;

-- ── Regel ──────────────────────────────────────────────────────────────────

create or replace function public.lsa_bruch_vorschlag(p_answers jsonb)
returns boolean
language sql
immutable
as $$
  -- true: jede Lösung ist ein Bruch · false: keine (und keine sieht nach Bruch aus)
  -- NULL: gemischt, leer, oder ein Bruch, der die Regel nicht erfüllt („+1/3“, „−3/4“) → Prüfliste
  select case
    when jsonb_typeof(p_answers) is distinct from 'array' then null
    when jsonb_array_length(p_answers) = 0 then null
    when not exists (select 1 from jsonb_array_elements_text(p_answers) a
                      where btrim(a) !~ '^-?\d+/\d+$') then true
    when exists (select 1 from jsonb_array_elements_text(p_answers) a
                  where btrim(a) ~ '^-?\d+/\d+$' or a ~ '/') then null
    else false
  end
$$;

create or replace function public.lsa_input_hint(p_input_type text, p_bruch boolean, p_answers jsonb)
returns text
language sql
immutable
as $$
  select case
    when p_input_type in ('MC', 'MULTI_PART') then null
    when p_input_type = 'TERM' then 'term'
    when coalesce(p_bruch, public.lsa_bruch_vorschlag(p_answers)) then 'fraction'
    when not coalesce(p_bruch, public.lsa_bruch_vorschlag(p_answers)) then 'number'
  end
$$;

-- Ein Teil aus tasks.parts mit seinen Lösungen (correct_answers -> nr).
create or replace function public.lsa_teil_input_hint(p_part jsonb, p_answers jsonb)
returns text
language sql
immutable
as $$
  select case
    when p_part ->> 'kind' is distinct from 'short_input' then null
    else public.lsa_input_hint(
           coalesce(p_part ->> 'input_type', 'SHORT_TEXT'),
           case when jsonb_typeof(p_part -> 'bruch') = 'boolean' then (p_part ->> 'bruch')::boolean end,
           p_answers)
  end
$$;

-- Gate: hat die Aufgabe (bzw. jeder short_input-Teil) einen eindeutigen Hinweis?
create or replace function public.lsa_eingabeformat_eindeutig(p_input_type text, p_bruch boolean,
                                                              p_parts jsonb, p_answers jsonb)
returns boolean
language sql
immutable
as $$
  select case
    when p_input_type = 'MC' then true
    when p_input_type = 'MULTI_PART' then not exists (
      select 1
        from jsonb_array_elements(case when jsonb_typeof(p_parts) = 'array' then p_parts else '[]'::jsonb end) e(p)
       where p ->> 'kind' = 'short_input'
         and public.lsa_teil_input_hint(p,
               case when jsonb_typeof(p_answers) = 'object'
                     and jsonb_typeof(p_answers -> (p ->> 'nr')) = 'array'
                    then p_answers -> (p ->> 'nr') end) is null)
    else public.lsa_input_hint(p_input_type, p_bruch, p_answers) is not null
  end
$$;

revoke all on function public.lsa_bruch_vorschlag(jsonb) from public, anon, authenticated;
revoke all on function public.lsa_input_hint(text, boolean, jsonb) from public, anon, authenticated;
revoke all on function public.lsa_teil_input_hint(jsonb, jsonb) from public, anon, authenticated;
revoke all on function public.lsa_eingabeformat_eindeutig(text, boolean, jsonb, jsonb) from public, anon, authenticated;

-- ── Vorbefüllung ───────────────────────────────────────────────────────────

do $vb$
declare
  v_aufgaben integer;
  v_teile    integer;
begin
  -- Aufgaben (alles, was lsa_question_payload als short_input ausgibt; TERM ist immer term).
  update public.tasks t
     set bruch = v.vorschlag,
         vorbefuellt = case when v.vorschlag
           then t.vorbefuellt || jsonb_build_object('bruch', jsonb_build_object('art', 'neu',
                  'grund', 'LSA-Erlebnis L1: alle Lösungen in Bruchschreibweise'))
           else t.vorbefuellt end
    from (select t2.id, public.lsa_bruch_vorschlag(s.correct_answers) as vorschlag
            from public.tasks t2 join public.task_solutions s on s.task_id = t2.id
           where t2.input_type not in ('MC', 'MULTI_PART', 'TERM')) v
   where v.id = t.id
     and t.bruch is null
     and v.vorschlag is not null;
  get diagnostics v_aufgaben = row_count;

  -- short_input-Teile ohne Angabe (nicht Term).
  with neu as (
    select t.id,
           jsonb_agg(case when x.v is not null then e.p || jsonb_build_object('bruch', x.v) else e.p end
                     order by e.o) as parts,
           coalesce(jsonb_object_agg('parts.' || (e.p ->> 'nr') || '.bruch',
                      jsonb_build_object('art', 'neu',
                        'grund', 'LSA-Erlebnis L1: alle Lösungen in Bruchschreibweise'))
                    filter (where x.v), '{}'::jsonb) as kennzeichen,
           count(*) filter (where x.v is not null) as gesetzt
      from public.tasks t
      join public.task_solutions s on s.task_id = t.id
      cross join lateral jsonb_array_elements(t.parts) with ordinality as e(p, o)
      cross join lateral (
        select case
          when e.p ->> 'kind' = 'short_input' and not e.p ? 'bruch'
               and e.p ->> 'input_type' is distinct from 'TERM'
               and jsonb_typeof(s.correct_answers) = 'object'
               and jsonb_typeof(s.correct_answers -> (e.p ->> 'nr')) = 'array'
          then public.lsa_bruch_vorschlag(s.correct_answers -> (e.p ->> 'nr'))
        end as v
      ) x
     where t.input_type = 'MULTI_PART' and jsonb_typeof(t.parts) = 'array'
     group by t.id
  )
  update public.tasks t
     set parts = neu.parts,
         vorbefuellt = t.vorbefuellt || neu.kennzeichen
    from neu
   where neu.id = t.id and neu.gesetzt > 0;
  get diagnostics v_teile = row_count;

  raise notice 'lsa_eingabeformat: % Aufgaben, % Mehrteiler vorbefuellt', v_aufgaben, v_teile;
end $vb$;

-- ── Gate im LSA-Pool ───────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.lsa_im_pool(p_task_id uuid, p_testlauf boolean DEFAULT false)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  select exists (
    select 1
      from public.tasks t
     where t.id = p_task_id
       and coalesce(t.is_active, false)
       and not coalesce(t.is_tutorial, false)
       and t.content_type = 'exercise'
       and 'lsa' = any (t.einsatz)
       and exists (select 1 from public.task_solutions s
                    where s.task_id = t.id
                      and public.lsa_has_answers(t.input_type, t.parts, s.correct_answers)
                      -- LSA-Erlebnis L1: ohne eindeutiges Eingabeformat nicht in den Pool.
                      and public.lsa_eingabeformat_eindeutig(t.input_type, t.bruch, t.parts, s.correct_answers))
       and (t.status = 'ready'
            or (coalesce(p_testlauf, false) and public.testlauf_inhalt_sichtbar(t.id)))
  )
$function$;

-- ── Payload ────────────────────────────────────────────────────────────────

-- Teile mit input_hint. Die Lösungen braucht nur der Vorschlag für Teile ohne Angabe; sie gehen nie
-- in den Payload. Die einstellige Fassung bleibt für Altaufrufer und liest nur die gespeicherte Angabe.
CREATE OR REPLACE FUNCTION public.lsa_public_parts(p_parts jsonb, p_answers jsonb)
 RETURNS jsonb
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select coalesce((
    select jsonb_agg(
             jsonb_strip_nulls(jsonb_build_object(
               'nr',     (p ->> 'nr')::int,
               'kind',   p ->> 'kind',
               'prompt', p ->> 'prompt',
               'unit',   p ->> 'unit',
               'input_hint', public.lsa_teil_input_hint(p,
                   case when jsonb_typeof(p_answers) = 'object'
                         and jsonb_typeof(p_answers -> (p ->> 'nr')) = 'array'
                        then p_answers -> (p ->> 'nr') end),
               'table',  public.lsa_public_table(p -> 'table'),
               'options', case when p ->> 'kind' = 'mc' then coalesce((
                   select jsonb_agg(
                            jsonb_build_object('id', o ->> 'id', 'label', o ->> 'label')
                            order by ord
                          )
                     from jsonb_array_elements(
                            case when jsonb_typeof(p -> 'options') = 'array'
                                 then p -> 'options' else '[]'::jsonb end
                          ) with ordinality as oe(o, ord)
                 ), '[]'::jsonb) end
             ))
             order by (p ->> 'nr')::int
           )
      from jsonb_array_elements(
             case when jsonb_typeof(p_parts) = 'array' then p_parts else '[]'::jsonb end
           ) as e(p)
     where p ->> 'kind' in ('short_input', 'mc')
  ), '[]'::jsonb)
$function$;

CREATE OR REPLACE FUNCTION public.lsa_public_parts(p_parts jsonb)
 RETURNS jsonb
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select public.lsa_public_parts(p_parts, null::jsonb)
$function$;

revoke all on function public.lsa_public_parts(jsonb, jsonb) from public, anon, authenticated;

CREATE OR REPLACE FUNCTION public.lsa_question_payload(p_task_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select jsonb_strip_nulls(
    case
      when t.input_type = 'MULTI_PART' then jsonb_build_object(
        'task_id', t.id,
        'kind',    'multi_part',
        'stem',    coalesce(t.question, ''),
        'assets',  public.lsa_task_assets(t.id),
        'table',   public.lsa_public_table(t.question_payload -> 'table'),
        'parts',   public.lsa_public_parts(t.parts, s.correct_answers)
      )
      when t.input_type = 'MC' then jsonb_build_object(
        'task_id', t.id,
        'kind',    'mc',
        'prompt',  coalesce(t.question, ''),
        'assets',  public.lsa_task_assets(t.id),
        'table',   public.lsa_public_table(t.question_payload -> 'table'),
        'options', coalesce((
          select jsonb_agg(
                   jsonb_build_object('id', o ->> 'id', 'label', o ->> 'label')
                   order by ord
                 )
            from jsonb_array_elements(
                   case
                     when jsonb_typeof(t.question_payload -> 'options') = 'array'
                       then t.question_payload -> 'options'
                     else '[]'::jsonb
                   end
                 ) with ordinality as e(o, ord)
        ), '[]'::jsonb)
      )
      else jsonb_build_object(
        'task_id',    t.id,
        'kind',       'short_input',
        'prompt',     coalesce(t.question, ''),
        'assets',     public.lsa_task_assets(t.id),
        'table',      public.lsa_public_table(t.question_payload -> 'table'),
        'unit',       t.unit,
        'input_hint', public.lsa_input_hint(t.input_type, t.bruch, s.correct_answers)
      )
    end
  )
  from tasks t
  left join task_solutions s on s.task_id = t.id
  where t.id = p_task_id
$function$;
