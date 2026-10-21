-- Rollback zu 20261021082844_lsa_bruch_term_wertung (LSA-Erlebnis L1, Punkt 3).
-- Vorher: Rollback zu 20261021083001_lsa_urteil_eingabeformat (ruft die fünfstellige lsa_grade).
-- Stellt lsa_submit wieder her (correct über lsa_is_correct, Teile immer SHORT_TEXT), wörtlich nach
-- pg_get_functiondef aus Prod vom 21.10.2026 (vor L1). Die neuen Funktionen bleiben (nicht löschend).

CREATE OR REPLACE FUNCTION public.lsa_submit(p_session_id uuid, p_task_id uuid, p_response jsonb, p_duration_ms integer DEFAULT NULL::integer, p_jetzt timestamp with time zone DEFAULT now())
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_session lsa_sessions;
  v_task    tasks;
  v_answers jsonb;
  v_next    uuid;
  v_art     text;
begin
  select * into v_session from lsa_sessions where id = p_session_id;
  if not found then
    raise exception 'LSA: Session nicht gefunden' using errcode = 'P0002';
  end if;
  if not public.lsa_may_act_for(v_session.student_id) then
    raise exception 'LSA: kein Zugriff auf diese Session' using errcode = '42501';
  end if;
  if v_session.status <> 'in_progress' then
    raise exception 'LSA: Session ist nicht aktiv' using errcode = 'P0001';
  end if;

  -- Gate: adaptiv ueber die Ausgabe-Historie, fest ueber item_ids.
  if v_session.modus = 'adaptiv' then
    if not exists (
      select 1 from lsa_ausgegeben
       where session_id = p_session_id and task_id = p_task_id
    ) then
      raise exception 'LSA: Item gehoert nicht zu dieser Session' using errcode = 'P0001';
    end if;
  else
    if not (p_task_id = any (v_session.item_ids)) then
      raise exception 'LSA: Item gehoert nicht zu dieser Session' using errcode = 'P0001';
    end if;
  end if;

  select * into v_task from tasks where id = p_task_id;
  select s.correct_answers into v_answers from task_solutions s where s.task_id = p_task_id;

  v_art := public.lsa_abgabeart(v_task.input_type, p_response);

  -- Antwort schreiben — unveraenderte A13-Logik.
  if v_task.input_type = 'MULTI_PART' then
    if p_response is not null and jsonb_typeof(p_response) <> 'object' then
      raise exception 'LSA: Multi-Part erwartet ein Objekt {"<nr>": <antwort>}'
        using errcode = 'P0001';
    end if;
    insert into lsa_responses (session_id, task_id, part_nr, response, abgabeart, correct, duration_ms)
    select p_session_id, p_task_id, (p ->> 'nr')::int, p_response -> (p ->> 'nr'), teil.art,
           case when teil.art = 'antwort'
                then coalesce(public.lsa_is_correct(
                       case when p ->> 'kind' = 'mc' then 'MC' else 'SHORT_TEXT' end,
                       case when jsonb_typeof(v_answers -> (p ->> 'nr')) = 'array'
                            then v_answers -> (p ->> 'nr') else '[]'::jsonb end,
                       public.lsa_part_answer(p ->> 'kind', p_response -> (p ->> 'nr'))
                     ), false)
                else null end,
           p_duration_ms
      from jsonb_array_elements(v_task.parts) as e(p)
      cross join lateral (
        select case when v_art = 'weiss_nicht' then 'weiss_nicht'
                    else public.lsa_abgabeart(
                           case when p ->> 'kind' = 'mc' then 'MC' else 'SHORT_TEXT' end,
                           public.lsa_part_answer(p ->> 'kind', p_response -> (p ->> 'nr')))
               end as art
      ) teil
    on conflict (session_id, task_id, coalesce(part_nr, 0)) do nothing;
  else
    insert into lsa_responses (session_id, task_id, part_nr, response, abgabeart, correct, duration_ms)
    values (
      p_session_id, p_task_id, null, p_response, v_art,
      case when v_art = 'antwort'
           then coalesce(public.lsa_is_correct(v_task.input_type, v_answers, p_response), false)
           else null end,
      p_duration_ms
    )
    on conflict (session_id, task_id, coalesce(part_nr, 0)) do nothing;
  end if;

  -- Naechstes Item.
  if v_session.modus = 'adaptiv' then
    -- Reihenfolge zwingend: erst die Antwort steht (oben), DANN das Urteil, das
    -- sie liest.
    perform public.lsa_urteil_buchen_core(p_session_id, p_task_id);

    v_next := public.lsa_select_next_core(p_session_id, array['ready'], p_jetzt);
    if v_next is not null then
      insert into lsa_ausgegeben (session_id, task_id) values (p_session_id, v_next)
        on conflict (session_id, task_id) do nothing;
    end if;
  else
    select i.id into v_next
      from unnest(v_session.item_ids) with ordinality as i(id, ord)
     where not exists (
             select 1 from lsa_responses r
              where r.session_id = v_session.id and r.task_id = i.id)
     order by i.ord
     limit 1;
  end if;

  return jsonb_build_object(
    'ok',   true,
    'next', case when v_next is null then null
                 else public.lsa_question_payload(v_next) end
  );
end;
$function$;

-- Optional, nur bewusst ausführen (erst nach dem Rollback von …083001):
-- drop function public.lsa_grade(text, jsonb, jsonb, jsonb, text);
-- drop function public.lsa_antwort_korrekt(text, text, jsonb, jsonb);
-- drop function public.lsa_term_kanonisch(text);
-- drop function public.lsa_bruch_wert_gleich(text, jsonb);
-- drop function public.lsa_bruch_zahl(text);
