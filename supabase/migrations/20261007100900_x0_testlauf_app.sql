-- X0.3 Die App bekommt das Feld testlauf (Auftrag Punkt 11, Entscheidung 27).
--
-- platz_state (Kiosk, von edvance-app alle 3 s abgefragt) liefert zusaetzlich
-- 'testlauf' der zugewiesenen LSA. Sonst zeilengleich mit dem geltenden Stand
-- (pg_get_functiondef aus allen Migrationen). lsa_start liefert das Feld seit
-- 20261007100500 ebenfalls. Das Banner in der App baut P2 (offener Punkt).

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
