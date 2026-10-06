-- X0.1/X0.3 LSA-Start (Entscheidungen 24, 27).
--
-- Jeder Weg, der eine lsa_session anlegt, laeuft ueber lsa_start (pg_proc-Scan:
-- nur lsa_start enthaelt "insert into lsa_sessions"; lead_lsa_freigeben ruft
-- lsa_start). Direktes INSERT per RLS sperrt 20261007100600 (Coach nur noch lesen).
--
-- lsa_darf_starten: Admin ja; Coach nur fuer ein Kind, das in einer seiner nicht
-- abgeschlossenen Sessions einen Platz (session_students, nicht abgesagt) hat;
-- Schuelerkonten (auch das Platz-Geraetekonto, Rolle student) nie -> 42501.
--
-- lsa_start und lead_lsa_freigeben bekommen p_testlauf (Default false). Weil
-- sich die Stelligkeit aendert: alte Signatur droppen, neu anlegen, gleiche
-- Defaults, damit bestehende Aufrufe (App: benannte Argumente) gleich aufloesen.
--
-- lsa_select_next: Wrapper bleibt, der Statusfilter des Aufrufers wirkt nicht
-- mehr (Core ignoriert ihn, 20261007100400).

create function public.coach_hat_platz(p_student_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.get_my_role() = 'coach'
     and exists (
       select 1
         from public.session_students ss
         join public.coaching_sessions cs on cs.id = ss.session_id
        where ss.student_id = p_student_id
          and cs.coach_id = auth.uid()
          and cs.status <> 'done'
          and ss.attendance not in ('cancelled', 'cancelled_by_us')
     )
$$;
revoke all on function public.coach_hat_platz(uuid) from public, anon, authenticated;
comment on function public.coach_hat_platz(uuid) is
  'true, wenn der angemeldete Coach das Kind in einer eigenen, nicht abgeschlossenen Session gebucht hat (Session-Platz).';

create function public.lsa_darf_starten(p_student_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(public.get_my_role(), '') = 'admin'
      or public.coach_hat_platz(p_student_id)
$$;
revoke all on function public.lsa_darf_starten(uuid) from public, anon, authenticated;
comment on function public.lsa_darf_starten(uuid) is
  'LSA-Start (X0, Entscheidung 24): Admin oder Coach ueber einen Platz. Schuelerkonten nie.';

drop function public.lsa_start(uuid, integer, text, text, timestamptz);
CREATE FUNCTION public.lsa_start(p_student_id uuid, p_grade integer, p_subject text, p_modus text DEFAULT 'adaptiv'::text, p_jetzt timestamp with time zone DEFAULT now(), p_testlauf boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_session_id uuid;
  v_items      uuid[];
  v_first      uuid;
  v_thema      text;
begin
  -- X0 (Entscheidung 24): kein Schuelerkonto startet eine LSA; Admin ja,
  -- Coach nur fuer ein Kind mit Platz in einer seiner Sessions.
  if not public.lsa_darf_starten(p_student_id) then
    raise exception 'LSA: Start nur durch Admin oder Coach ueber einen Platz' using errcode = '42501';
  end if;
  if not exists (select 1 from students where id = p_student_id) then
    raise exception 'LSA: Schueler nicht gefunden' using errcode = 'P0002';
  end if;
  if coalesce(p_testlauf, false) then
    if coalesce(public.get_my_role(), '') <> 'admin' then
      raise exception 'LSA: Testlauf nur durch Admin' using errcode = '42501';
    end if;
    if not coalesce((select ist_test from students where id = p_student_id), false) then
      raise exception 'LSA: Testlauf nur mit Testkonto' using errcode = '22023';
    end if;
  end if;
  if p_modus not in ('fest','adaptiv') then
    raise exception 'LSA: unbekannter Modus %', p_modus using errcode = '22023';
  end if;
  if exists (
    select 1 from lsa_sessions
     where student_id = p_student_id and subject = p_subject and status = 'in_progress'
  ) then
    raise exception 'LSA: fuer % laeuft bereits eine Session', p_subject
      using errcode = 'P0001';
  end if;

  -- ---------------------------------------------------------------- ADAPTIV --
  if p_modus = 'adaptiv' then
    -- W3-6: Thema aus dem Erstgespraech. Fach ohne Gross/klein: die Sitzung
    -- traegt 'Mathematik', der Themenkatalog 'mathematik'.
    select lt.thema_key into v_thema
      from lead_themen lt
     where lt.lead_id = public.lsa_lead_von_schueler(p_student_id)
       and lt.status = 'aktuell'
       and lower(lt.fach) = lower(p_subject);

    insert into lsa_sessions (student_id, subject, grade, item_ids, started_at, status, modus, thema_key, testlauf)
    values (p_student_id, p_subject, p_grade, '{}'::uuid[], p_jetzt, 'in_progress', 'adaptiv', v_thema, coalesce(p_testlauf, false))
    returning id into v_session_id;

    v_first := public.lsa_select_next_core(v_session_id, array['ready'], p_jetzt);
    if v_first is null then
      raise exception 'LSA: kein freigegebener Item-Pool fuer % / Klasse %', p_subject, p_grade
        using errcode = 'P0002';
    end if;
    insert into lsa_ausgegeben (session_id, task_id) values (v_session_id, v_first);

    -- KEIN total_items: die Aufgabenzahl ist adaptiv und wird dem Kind nie
    -- gezeigt (Fortschritt laeuft ueber Zeit als Licht). Die App-Seite darf
    -- daraus keinen Zaehler rendern — siehe PR (Folge-PR in edvance-app,
    -- falls sie total_items liest).
    return jsonb_build_object(
      'session_id', v_session_id,
      'testlauf',   coalesce(p_testlauf, false),
      'item',       public.lsa_question_payload(v_first)
    );
  end if;

  -- ------------------------------------------------------------------- FEST --
  -- Unveraendert gegenueber dem Bestand (nur modus='fest' explizit gesetzt).
  with pool as (
    select t.id,
           coalesce(t.afb, 'II')                as afb,
           coalesce(t.competency_content, '?')  as comp,
           coalesce(t.est_duration_sec, t.estimated_minutes * 60, 180) as secs
      from tasks t
      join task_solutions s on s.task_id = t.id
      join skill_clusters c on c.id = t.cluster_id
      join subjects sub     on sub.id = c.subject_id
     where public.lsa_im_pool(t.id, coalesce(p_testlauf, false))
       and t.input_type in ('MC','SHORT_TEXT','NUMERIC','MULTI_PART')
       and public.lsa_has_answers(t.input_type, t.parts, s.correct_answers)
       and sub.name = p_subject
       and coalesce(t.class_level, p_grade) <= p_grade
  ),
  mixed as (
    select id, secs,
           row_number() over (partition by afb, comp order by random()) as rn,
           row_number() over (order by random())                        as tiebreak
      from pool
  ),
  ordered as (
    select id,
           sum(secs) over (order by rn, tiebreak
                           rows between unbounded preceding and current row) as cum,
           secs, rn, tiebreak
      from mixed
  )
  select array_agg(id order by rn, tiebreak)
    into v_items
    from ordered
   where cum - secs < 1200;

  if v_items is null or array_length(v_items, 1) = 0 then
    raise exception 'LSA: kein freigegebener Item-Pool fuer % / Klasse %', p_subject, p_grade
      using errcode = 'P0002';
  end if;

  insert into lsa_sessions (student_id, subject, grade, item_ids, started_at, status, modus, testlauf)
  values (p_student_id, p_subject, p_grade, v_items, p_jetzt, 'in_progress', 'fest', coalesce(p_testlauf, false))
  returning id into v_session_id;

  return jsonb_build_object(
    'session_id',  v_session_id,
    'testlauf',    coalesce(p_testlauf, false),
    'total_items', array_length(v_items, 1),
    'item',        public.lsa_question_payload(v_items[1])
  );
end;
$function$
;

revoke all on function public.lsa_start(uuid, integer, text, text, timestamptz, boolean) from public, anon;
grant execute on function public.lsa_start(uuid, integer, text, text, timestamptz, boolean) to authenticated;
comment on function public.lsa_start(uuid, integer, text, text, timestamptz, boolean) is
  'Startet eine LSA. Nur Admin oder Coach ueber einen Platz (X0); p_testlauf nur Admin und Testkonto.';

drop function public.lead_lsa_freigeben(uuid, integer, text);
CREATE FUNCTION public.lead_lsa_freigeben(p_lead_id uuid, p_grade integer, p_subject text, p_testlauf boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_lead       leads%rowtype;
  v_student_id uuid;
  v_result     jsonb;
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'lead_lsa_freigeben: nur Admin' using errcode = '42501';
  end if;

  select * into v_lead from leads where id = p_lead_id;
  if not found then
    raise exception 'lead_lsa_freigeben: Lead nicht gefunden' using errcode = 'P0002';
  end if;
  if v_lead.status = 'converted' then
    raise exception 'lead_lsa_freigeben: Lead ist bereits konvertiert' using errcode = 'P0001';
  end if;
  if v_lead.consent_dsgvo_at is null then
    raise exception 'lead_lsa_freigeben: DSGVO-Einwilligung fehlt (consent_dsgvo_at ist null)'
      using errcode = 'P0001';
  end if;

  select id into v_student_id from students where lead_id = p_lead_id;
  if v_student_id is null then
    perform set_config('edvance.allow_provisional', '1', true);
    insert into students (profile_id, class_level, school_name, school_type,
                          is_provisional, lead_id)
    values (null, coalesce(v_lead.class_level, p_grade), v_lead.school_name,
            v_lead.school_type, true, p_lead_id)
    returning id into v_student_id;
    perform set_config('edvance.allow_provisional', '', true);
  end if;

  -- A17: adaptiv (Default). Der 'fest'-Pin aus A16 ist entfernt.
  -- X0: ob ein Testlauf erlaubt ist, prueft lsa_start (Admin, Kind ist
  -- Testkonto; ein neu angelegtes Kind erbt ist_test vom Lead).
  v_result := public.lsa_start(v_student_id, p_grade, p_subject, p_testlauf => coalesce(p_testlauf, false));

  -- Ein Testlauf bewegt den Lead nicht im Trichter (Lead-Board-Zaehler, X0).
  if not coalesce(p_testlauf, false) then
    update leads set status = 'lsa_freigegeben' where id = p_lead_id;
  end if;

  -- total_items existiert im adaptiven Rueckgabeobjekt bewusst nicht (die
  -- Aufgabenzahl bleibt verborgen) -> jsonb-Feldzugriff liefert dann NULL.
  return jsonb_build_object(
    'session_id',  v_result -> 'session_id',
    'student_id',  to_jsonb(v_student_id),
    'total_items', v_result -> 'total_items',
    'testlauf',    to_jsonb(coalesce(p_testlauf, false))
  );
end;
$function$
;

revoke all on function public.lead_lsa_freigeben(uuid, integer, text, boolean) from public, anon;
grant execute on function public.lead_lsa_freigeben(uuid, integer, text, boolean) to authenticated;
comment on function public.lead_lsa_freigeben(uuid, integer, text, boolean) is
  'Admin gibt die LSA eines Leads frei (legt bei Bedarf das Kind an). Testlauf: nur Testkonto, Lead-Status bleibt (X0).';
