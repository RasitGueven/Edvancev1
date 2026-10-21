-- Rollback zu 20261021083033_platz_avatar_helle_abbildung (LSA-Erlebnis L1, Punkte 5 und 6).
-- Stellt platz_state (ohne avatar/diagnose_ab) und lsa_task_assets (dunkle Fassung) wieder her, wörtlich nach
-- pg_get_functiondef aus Prod vom 21.10.2026 (vor L1).

CREATE OR REPLACE FUNCTION public.platz_state()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_a          platz_assignments;
  v_session    lsa_sessions;
  v_first_name text;
  v_answered   integer;
begin
  if not exists (select 1 from platz_devices where profile_id = auth.uid()) then
    raise exception 'platz_state: kein Platz-Konto' using errcode = '42501';
  end if;

  v_a := public.platz_current_assignment();
  if v_a.id is null then
    return jsonb_build_object('status', 'wartet');
  end if;

  select * into v_session from lsa_sessions where id = v_a.session_id;
  if not found or v_session.status <> 'in_progress' then
    return jsonb_build_object('status', 'wartet');
  end if;

  select l.first_name into v_first_name
    from students s join leads l on l.id = s.lead_id
   where s.id = v_session.student_id;

  if v_session.modus = 'adaptiv' then
    -- KEIN progress: die Aufgabenzahl ist adaptiv und darf dem Kind nie
    -- gezeigt werden. Der Fortschritt kommt allein aus der Zeit (expires_at).
    return jsonb_build_object(
      'status',     'zugewiesen',
      'first_name', v_first_name,
      'expires_at', v_a.expires_at,
      'testlauf',   v_session.testlauf
    );
  end if;

  select count(distinct r.task_id)::int into v_answered
    from lsa_responses r where r.session_id = v_session.id;

  return jsonb_build_object(
    'status',     'zugewiesen',
    'first_name', v_first_name,
    'progress',   jsonb_build_object(
                    'answered', v_answered,
                    'total',    coalesce(array_length(v_session.item_ids, 1), 0)),
    'expires_at', v_a.expires_at,
    'testlauf',   v_session.testlauf
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.lsa_task_assets(p_task_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce(jsonb_agg(item order by ord), '[]'::jsonb)
  from (
    -- Bestandsassets (VERA): unveraenderte Form {url, alt}.
    select jsonb_strip_nulls(jsonb_build_object('url', a ->> 'url', 'alt', a ->> 'alt')) as item,
           ord as ord
      from tasks t
      cross join lateral jsonb_array_elements(
        case when jsonb_typeof(t.assets) = 'array' then t.assets else '[]'::jsonb end
      ) with ordinality as e(a, ord)
     where t.id = p_task_id and a ->> 'url' is not null

    union all

    -- Generierte Abbildung (dunkel), Typ bekannt. Hinten einsortiert.
    select jsonb_build_object(
             'url', public.lsa_storage_base()
                    || 'generiert/' || f.task_id::text || '/' || f.generator || '-dunkel.svg',
             'alt', f.alt_text,
             'content_type', 'image/svg+xml'
           ) as item,
           1000000 as ord
      from task_figures f
     where f.task_id = p_task_id and f.svg_hash is not null
  ) s
$function$;

