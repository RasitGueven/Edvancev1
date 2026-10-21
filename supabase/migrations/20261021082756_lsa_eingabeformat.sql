-- LSA-Erlebnis L1, Punkt 1: Eingabeformat je Aufgabe und je Teil (input_hint number | fraction | term).
--
-- Anforderung „LSA-Erlebnis nach Prototyp V1.3.1“ (Fassung 1.1), Daten und Backend, Punkt 1; Entscheidungen
-- Rasit 21.10.2026 (7.8) und Orchestrator a), b) sowie Befundrunde 1 (Punkte 5 und 6).
--
-- Die Bruch-Angabe (Item-Pflege, Feld „Bruch“):
--   tasks.bruch          boolean  — an der Aufgabe (short_input). NULL = automatisch nach der Regel.
--   tasks.parts[i].bruch boolean  — am short_input-Teil eines Mehrteilers. Fehlt = automatisch.
-- Ein Teil wird Term über tasks.parts[i].input_type = 'TERM' (wie eine Aufgabe über tasks.input_type);
-- heute hat kein Teil diesen Schlüssel (L0: 0 von 606).
--
-- Regel (lsa_input_hint):
--   input_type TERM → 'term'
--   bruch true → 'fraction', bruch false → 'number'
--   bruch NULL → Vorschlag aus den Lösungen (lsa_format_vorschlag):
--     JEDE Lösung passt (nach btrim) auf ^-?\d+/\d+$                              → 'fraction'
--     JEDE Lösung ist eine Zahl (lsa_loesung_ist_zahl: Vorzeichen auch „+“/„−“,
--       Dezimalkomma/-punkt, Tausender mit Leerzeichen, dahinter höchstens die
--       Einheit, die das Feld selbst zeigt — tasks.unit bzw. parts[i].unit)      → 'number'
--     sonst (gemischt, Text wie „x = 9“, Einheit ohne Feld-Einheit, leer)          → kein Hinweis
--   Die Bruch-Regel bleibt wörtlich (Orchestrator a): „+1/3“ und typografisches Minus sind kein Bruch.
--
-- Vorbefüllung (Befundrunde 1, Punkt 6): Die Migration schreibt nur die Bruch-Treffer fest (bruch = true,
-- mit Vorbefüllt-Kennzeichen 'bruch' bzw. 'parts.<nr>.bruch', damit Rasit/Lena sie in der Item-Pflege
-- bestätigen). Alles andere bleibt NULL und wird zur Laufzeit nach der Regel abgeleitet — so veraltet nichts,
-- und tasks.pruef_version zählt nur bei den Treffern hoch. Compare-and-set; ein zweiter Lauf ändert nichts.
--
-- Gate (lsa_im_pool): Eine short_input-Aufgabe ohne eindeutigen Hinweis kommt nicht in den LSA-Pool, ebenso
-- ein Mehrteiler, bei dem ein short_input-Teil keinen hat (Orchestrator b). Prüfliste:
-- supabase/checks/lsa_eingabeformat_pruefliste.sql.
--
-- Payload: short_input und short_input-Teile tragen input_hint (jsonb_strip_nulls: fehlt ohne Hinweis).

alter table public.tasks add column if not exists bruch boolean;

-- ── Regel ──────────────────────────────────────────────────────────────────

-- Ist diese Lösung eine Zahl, die das Kind auf der Zifferntastatur tippen kann? Eine Einheit dahinter zählt nur,
-- wenn das Feld genau diese Einheit selbst anzeigt (p_unit).
create or replace function public.lsa_loesung_ist_zahl(p_loesung text, p_unit text)
returns boolean
language sql
immutable
as $$
  select case
    when m is null then false
    when btrim(m[2]) = '' then true
    else coalesce(btrim(p_unit), '') <> ''
         and replace(btrim(m[2]), ' ', '') = replace(lower(btrim(p_unit)), ' ', '')
  end
    from (select regexp_match(public.lsa_normalize_number(p_loesung),
                              '^(-?(?:[0-9]{1,3}(?: [0-9]{3})+|[0-9]+)(?:\.[0-9]+)?)(.*)$') as m) x
$$;

-- 'fraction' · 'number' · NULL (Prüfliste)
create or replace function public.lsa_format_vorschlag(p_answers jsonb, p_unit text)
returns text
language sql
immutable
as $$
  select case
    when jsonb_typeof(p_answers) is distinct from 'array' then null
    when jsonb_array_length(p_answers) = 0 then null
    when not exists (select 1 from jsonb_array_elements_text(p_answers) a
                      where btrim(a) !~ '^-?\d+/\d+$') then 'fraction'
    when not exists (select 1 from jsonb_array_elements_text(p_answers) a
                      where not public.lsa_loesung_ist_zahl(a, p_unit)) then 'number'
  end
$$;

create or replace function public.lsa_input_hint(p_input_type text, p_bruch boolean, p_answers jsonb, p_unit text)
returns text
language sql
immutable
as $$
  select case
    when p_input_type in ('MC', 'MULTI_PART') then null
    when p_input_type = 'TERM' then 'term'
    when p_bruch then 'fraction'
    when not p_bruch then 'number'
    else public.lsa_format_vorschlag(p_answers, p_unit)
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
           p_answers,
           p_part ->> 'unit')
  end
$$;

-- Gate: hat die Aufgabe (bzw. jeder short_input-Teil) einen eindeutigen Hinweis?
create or replace function public.lsa_eingabeformat_eindeutig(p_input_type text, p_bruch boolean, p_unit text,
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
    else public.lsa_input_hint(p_input_type, p_bruch, p_answers, p_unit) is not null
  end
$$;

revoke all on function public.lsa_loesung_ist_zahl(text, text) from public, anon, authenticated;
revoke all on function public.lsa_format_vorschlag(jsonb, text) from public, anon, authenticated;
revoke all on function public.lsa_input_hint(text, boolean, jsonb, text) from public, anon, authenticated;
revoke all on function public.lsa_teil_input_hint(jsonb, jsonb) from public, anon, authenticated;
revoke all on function public.lsa_eingabeformat_eindeutig(text, boolean, text, jsonb, jsonb) from public, anon, authenticated;

-- ── Vorbefüllung: nur Bruch-Treffer ────────────────────────────────────────

do $vb$
declare
  v_aufgaben integer;
  v_teile    integer;
begin
  update public.tasks t
     set bruch = true,
         vorbefuellt = t.vorbefuellt || jsonb_build_object('bruch', jsonb_build_object('art', 'neu',
                         'grund', 'LSA-Erlebnis L1: alle Lösungen in Bruchschreibweise'))
    from public.task_solutions s
   where s.task_id = t.id
     and t.input_type not in ('MC', 'MULTI_PART', 'TERM')
     and t.bruch is null
     and public.lsa_format_vorschlag(s.correct_answers, t.unit) = 'fraction';
  get diagnostics v_aufgaben = row_count;

  with neu as (
    select t.id,
           jsonb_agg(case when x.treffer then e.p || '{"bruch": true}'::jsonb else e.p end order by e.o) as parts,
           coalesce(jsonb_object_agg('parts.' || (e.p ->> 'nr') || '.bruch',
                      jsonb_build_object('art', 'neu',
                        'grund', 'LSA-Erlebnis L1: alle Lösungen in Bruchschreibweise'))
                    filter (where x.treffer), '{}'::jsonb) as kennzeichen,
           count(*) filter (where x.treffer) as gesetzt
      from public.tasks t
      join public.task_solutions s on s.task_id = t.id
      cross join lateral jsonb_array_elements(t.parts) with ordinality as e(p, o)
      cross join lateral (
        select coalesce(
                 e.p ->> 'kind' = 'short_input' and not e.p ? 'bruch'
                 and e.p ->> 'input_type' is distinct from 'TERM'
                 and jsonb_typeof(s.correct_answers) = 'object'
                 and public.lsa_format_vorschlag(s.correct_answers -> (e.p ->> 'nr'), e.p ->> 'unit') = 'fraction',
               false) as treffer
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

  raise notice 'lsa_eingabeformat: % Aufgaben, % Mehrteiler als Bruch vorbefuellt', v_aufgaben, v_teile;
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
                      and public.lsa_eingabeformat_eindeutig(t.input_type, t.bruch, t.unit, t.parts, s.correct_answers))
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
        'input_hint', public.lsa_input_hint(t.input_type, t.bruch, s.correct_answers, t.unit)
      )
    end
  )
  from tasks t
  left join task_solutions s on s.task_id = t.id
  where t.id = p_task_id
$function$;
