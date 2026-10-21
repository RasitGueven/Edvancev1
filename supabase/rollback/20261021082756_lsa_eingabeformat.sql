-- Rollback zu 20261021082756_lsa_eingabeformat (LSA-Erlebnis L1, Punkt 1).
-- Reihenfolge: zuerst die Rollbacks der späteren L1-Migrationen (…083033, …083026, …083001, …082844), dann dieses.
-- Stellt lsa_im_pool (ohne Gate), lsa_public_parts(jsonb) und lsa_question_payload (ohne input_hint) wieder her,
-- wörtlich nach pg_get_functiondef aus Prod vom 21.10.2026 (vor L1).
-- Nicht löschend: tasks.bruch, die Bruch-Angaben in tasks.parts (nur Bruch-Treffer) und die neuen Hilfsfunktionen bleiben stehen;
-- nach dem Rollback liest sie niemand mehr. Wer sie wirklich entfernen will, siehe Ende (auskommentiert).

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
                      and public.lsa_has_answers(t.input_type, t.parts, s.correct_answers))
       and (t.status = 'ready'
            or (coalesce(p_testlauf, false) and public.testlauf_inhalt_sichtbar(t.id)))
  )
$function$;

CREATE OR REPLACE FUNCTION public.lsa_public_parts(p_parts jsonb)
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
        'parts',   public.lsa_public_parts(t.parts)
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
        'task_id', t.id,
        'kind',    'short_input',
        'prompt',  coalesce(t.question, ''),
        'assets',  public.lsa_task_assets(t.id),
        'table',   public.lsa_public_table(t.question_payload -> 'table'),
        'unit',    t.unit
      )
    end
  )
  from tasks t
  where t.id = p_task_id
$function$;

-- Optional, nur bewusst ausführen:
-- update public.tasks set vorbefuellt = (select coalesce(jsonb_object_agg(k, v), '{}'::jsonb)
--          from jsonb_each(vorbefuellt) e(k, v) where k <> 'bruch' and k !~ '^parts\.[0-9]+\.bruch$')
--  where vorbefuellt ? 'bruch' or exists (select 1 from jsonb_object_keys(vorbefuellt) k where k ~ '^parts\.[0-9]+\.bruch$');
-- update public.tasks set parts = (select jsonb_agg(p - 'bruch' order by o) from jsonb_array_elements(parts) with ordinality e(p, o))
--  where jsonb_typeof(parts) = 'array' and exists (select 1 from jsonb_array_elements(parts) p where p ? 'bruch');
-- drop function public.lsa_public_parts(jsonb, jsonb);
-- drop function public.lsa_eingabeformat_eindeutig(text, boolean, text, jsonb, jsonb);
-- drop function public.lsa_teil_input_hint(jsonb, jsonb);
-- drop function public.lsa_input_hint(text, boolean, jsonb, text);
-- drop function public.lsa_format_vorschlag(jsonb, text);
-- drop function public.lsa_loesung_ist_zahl(text, text);
-- alter table public.tasks drop column bruch;
