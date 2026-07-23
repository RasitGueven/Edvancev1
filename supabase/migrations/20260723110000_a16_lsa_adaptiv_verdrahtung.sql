-- ============================================================================
-- A16: adaptiven Pfad an lsa_start / lsa_submit verdrahten
--
-- Schliesst die Luecke aus A15 (PR #91): lsa_select_next war nicht erreichbar,
-- weil lsa_start eine feste item_ids-Liste waehlte und lsa_submit darauf gated.
--
-- Fasst lsa_grade, lsa_select_next(_core)-LOGIK und lsa_urteil_buchen NICHT an —
-- Ausnahme laut Auftrag 2: die Ausschluss-Quelle von lsa_select_next_core wird
-- von lsa_responses auf lsa_ausgegeben (bzw. beides) umgestellt.
--
-- ----------------------------------------------------------------------------
-- GEMESSENER BEFUND (vor der Aenderung) — im PR zusammengefasst
-- ----------------------------------------------------------------------------
--   lsa_start(student,grade,subject): baut EINMALIG item_ids (Pool status=ready,
--     input_type in MC/SHORT_TEXT/NUMERIC/MULTI_PART, Zeitbudget 1200 s als Cap),
--     insert lsa_sessions (started_at=now()), Rueckgabe {session_id, total_items,
--     item}. total_items = array_length(item_ids).
--   lsa_submit(session,task,response,dur): Gate p_task_id=any(item_ids); schreibt
--     lsa_responses (abgabeart via lsa_abgabeart; correct via lsa_is_correct nur
--     bei abgabeart='antwort'); next = naechstes unbeantwortetes item_ids-Item.
--
--   AUFRUFER (Kollisionsflaeche, gemessen):
--     lead_lsa_freigeben ruft lsa_start(3 Args) und liest total_items.
--     platz_next / platz_submit sind item_ids-GEKOPPELT (Kiosk, S9).
--
-- ----------------------------------------------------------------------------
-- DAS LOCH, DAS DER AUFTRAG OEFFNET (Auftrag 1: p_modus default 'adaptiv')
-- ----------------------------------------------------------------------------
--   Ein adaptiver Default liesse lead_lsa_freigeben adaptive Sitzungen anlegen
--   (item_ids leer). platz_next liest aber item_ids, um das naechste Item zu
--   finden — der KIOSK braeche. Das ist ausserhalb dieses PR (Auftrag: platz
--   nicht anfassen) und darf nicht regredieren ("Kein Verhalten bestehender
--   Sitzungen darf sich aendern").
--
--   KORREKTUR (hier begruendet): lsa_start bekommt p_modus DEFAULT 'adaptiv' wie
--   beauftragt — der DIREKTE App-Start (Browser-Testmodus, 3-Arg-Aufruf) wird
--   damit adaptiv. Der EINE item_ids-gekoppelte Bestandsaufrufer,
--   lead_lsa_freigeben, wird minimal auf p_modus:='fest' gepinnt. So bleibt der
--   Kiosk unveraendert (fest, item_ids, total_items), bis die platz-Ebene
--   adaptiv verdrahtet ist (Folge-PR, ausdruecklich NICHT hier). platz_next/
--   platz_submit werden NICHT angefasst; sie treffen die neuen Signaturen ueber
--   Default-Parameter und bleiben auf dem fest-Pfad.
-- ============================================================================

begin;

-- ============================================================================
-- 1. Betriebsart an der Sitzung
-- ============================================================================

alter table lsa_sessions
  add column if not exists modus text not null default 'fest'
    check (modus in ('fest','adaptiv'));

comment on column lsa_sessions.modus is
  'Ablaufart der Sitzung (A16). fest = feste item_ids-Liste (Bestand, Kiosk). '
  'adaptiv = lsa_select_next zieht zur Laufzeit, item_ids bleibt leer. '
  'Bestehende Zeilen sind fest; der Rueckfall ist ein Parameter, keine Migration.';

-- ============================================================================
-- 2. Ausgabe-Historie — Ersatz fuer das item_ids-Gate im adaptiven Modus
--
--    Zwei Aufgaben: (a) Sicherheit — lsa_submit akzeptiert eine task_id nur,
--    wenn sie in DIESER Sitzung ausgegeben wurde (sonst koennte jemand Antworten
--    zu beliebigen Aufgaben einreichen). (b) "schon gestellt" fuer die Auswahl.
-- ============================================================================

create table if not exists lsa_ausgegeben (
  session_id    uuid not null references lsa_sessions(id) on delete cascade,
  task_id       uuid not null references tasks(id),
  ausgegeben_am timestamptz not null default now(),
  primary key (session_id, task_id)
);

comment on table lsa_ausgegeben is
  'Welche Aufgabe in welcher adaptiven Sitzung ausgegeben wurde (A16). Gate fuer '
  'lsa_submit und "schon gestellt" fuer lsa_select_next. Verraet die '
  'Aufgabenzahl — daher KEIN Schueler-/anon-Zugriff.';

alter table lsa_ausgegeben enable row level security;

revoke all on table lsa_ausgegeben from anon, authenticated;
grant select on table lsa_ausgegeben to authenticated;
grant select, insert, update, delete on table lsa_ausgegeben to service_role;

drop policy if exists lsa_ausgegeben_coach_admin_read on lsa_ausgegeben;
drop policy if exists lsa_ausgegeben_parent_read on lsa_ausgegeben;
create policy lsa_ausgegeben_coach_admin_read on lsa_ausgegeben
  for select using (public.get_my_role() in ('coach','admin'));
create policy lsa_ausgegeben_parent_read on lsa_ausgegeben
  for select using (
    session_id in (select id from lsa_sessions where public.is_parent_of_student(student_id))
  );
-- KEIN Schueler-/anon-Policy: die Zeilenzahl ist die Aufgabenzahl.

-- ============================================================================
-- 3. Auswahl: "schon gestellt" aus lsa_ausgegeben statt lsa_responses (Auftrag 2)
--
--    A15 leitete "schon gestellt" aus lsa_responses ab. Eine AUSGEGEBENE, aber
--    nie beantwortete Aufgabe (Kind bricht ab, App laedt neu) waere damit erneut
--    gezogen worden. Jetzt: eine Aufgabe gilt als gestellt, sobald sie
--    ausgegeben ODER beantwortet ist (Vereinigung). Die Vereinigung haelt
--    zugleich die Isolationstests aus A15 gruen, die ueber lsa_responses
--    simulieren.
-- ============================================================================

create or replace function public.lsa_select_next_core(
  p_session_id    uuid,
  p_status_filter text[] default array['ready'],
  p_jetzt         timestamptz default now()
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sess    lsa_sessions;
  v_open    text;
  v_prefer_nonmc boolean;
  v_desc    text;
  v_leaf    text;
  v_task    uuid;
  v_iter    int := 0;
begin
  select * into v_sess from lsa_sessions where id = p_session_id;
  if not found or v_sess.status <> 'in_progress' then
    return null;
  end if;

  if p_jetzt > coalesce(v_sess.started_at, v_sess.created_at) + interval '19 minutes' then
    return null;
  end if;

  loop
    v_iter := v_iter + 1;
    if v_iter > 100 then
      return null;
    end if;

    -- Schritt 2: offener Zweitbeleg, immer Vorrang.
    select u.skill_key into v_open
      from lsa_skill_urteil u
     where u.session_id = p_session_id and u.offen = true
     order by u.skill_key
     limit 1;

    if v_open is not null then
      select (zustand = 'traegt') into v_prefer_nonmc
        from lsa_skill_urteil where session_id = p_session_id and skill_key = v_open;

      select t.id into v_task
        from tasks t
       where t.skill_key = v_open
         and t.status = any (p_status_filter)
         and t.id not in (
               select task_id from lsa_ausgegeben where session_id = p_session_id
               union
               select task_id from lsa_responses  where session_id = p_session_id)
       order by (case when coalesce(v_prefer_nonmc,false) and t.input_type <> 'MC' then 0 else 1 end),
                t.sondierrang nulls last,
                md5(p_session_id::text || t.id::text)
       limit 1;

      if v_task is not null then
        return v_task;
      end if;
      update lsa_skill_urteil set offen = false, aktualisiert = now()
        where session_id = p_session_id and skill_key = v_open;
      continue;
    end if;

    -- Schritt 3: Abstieg.
    select x.q into v_desc from (
      select k.voraussetzt_skill_key as q, s.fundament_tiefe as tf
        from lsa_skill_urteil u
        join skill_kante k on k.skill_key = u.skill_key
        join skills s on s.skill_key = k.voraussetzt_skill_key
       where u.session_id = p_session_id
         and u.offen = false
         and u.zustand in ('traegt_nicht','nicht_angesetzt')
         and not exists (
               select 1 from lsa_skill_urteil d
                where d.session_id = p_session_id and d.skill_key = k.voraussetzt_skill_key)
       order by s.fundament_tiefe desc, k.voraussetzt_skill_key
       limit 1
    ) x;

    if v_desc is not null then
      select t.id into v_task
        from tasks t
       where t.skill_key = v_desc
         and t.status = any (p_status_filter)
         and t.id not in (
               select task_id from lsa_ausgegeben where session_id = p_session_id
               union
               select task_id from lsa_responses  where session_id = p_session_id)
       order by t.sondierrang nulls last, md5(p_session_id::text || t.id::text)
       limit 1;
      if v_task is not null then
        return v_task;
      end if;
      insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl)
        values (p_session_id, v_desc, 'ungeprueft', false, false, 0)
        on conflict (session_id, skill_key) do nothing;
      continue;
    end if;

    -- Schritt 4: neues Blatt nach gieriger Deckung.
    select y.leaf into v_leaf from (
      select b.skill_key as leaf, s.fundament_tiefe as tf,
             1 + (select count(*) from public.lsa_abschluss(b.skill_key) a
                   where not exists (
                     select 1 from lsa_skill_urteil u
                      where u.session_id = p_session_id and u.skill_key = a.skill_key)) as neu
        from skills b join skills s on s.skill_key = b.skill_key
       where not exists (select 1 from skill_kante k where k.voraussetzt_skill_key = b.skill_key)
         and not exists (
               select 1 from lsa_skill_urteil u
                where u.session_id = p_session_id and u.skill_key = b.skill_key)
       order by neu desc, s.fundament_tiefe desc, b.skill_key
       limit 1
    ) y;

    if v_leaf is not null then
      select t.id into v_task
        from tasks t
       where t.skill_key = v_leaf
         and t.status = any (p_status_filter)
         and t.id not in (
               select task_id from lsa_ausgegeben where session_id = p_session_id
               union
               select task_id from lsa_responses  where session_id = p_session_id)
       order by t.sondierrang nulls last, md5(p_session_id::text || t.id::text)
       limit 1;
      if v_task is not null then
        return v_task;
      end if;
      insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl)
        values (p_session_id, v_leaf, 'ungeprueft', false, false, 0)
        on conflict (session_id, skill_key) do nothing;
      continue;
    end if;

    -- Schritt 5: Restzeit.
    select t.id into v_task
      from tasks t
     where t.skill_key is not null
       and t.status = any (p_status_filter)
       and t.id not in (
             select task_id from lsa_ausgegeben where session_id = p_session_id
             union
             select task_id from lsa_responses  where session_id = p_session_id)
       and not exists (
             select 1 from lsa_skill_urteil u
              where u.session_id = p_session_id and u.skill_key = t.skill_key)
     order by t.sondierrang nulls last, md5(p_session_id::text || t.id::text)
     limit 1;
    if v_task is not null then
      return v_task;
    end if;

    return null;
  end loop;
end;
$$;

revoke execute on function public.lsa_select_next_core(uuid, text[], timestamptz) from public;
grant  execute on function public.lsa_select_next_core(uuid, text[], timestamptz) to service_role;

-- ============================================================================
-- 4. lsa_start — fest (Bestand) ODER adaptiv (neu). Alte 3-Arg-Signatur droppen.
-- ============================================================================

drop function if exists public.lsa_start(uuid, integer, text);

create or replace function public.lsa_start(
  p_student_id uuid,
  p_grade      integer,
  p_subject    text,
  p_modus      text        default 'adaptiv',
  p_jetzt      timestamptz default now()
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session_id uuid;
  v_items      uuid[];
  v_first      uuid;
begin
  if not public.lsa_may_act_for(p_student_id) then
    raise exception 'LSA: kein Zugriff auf diesen Schueler' using errcode = '42501';
  end if;
  if not exists (select 1 from students where id = p_student_id) then
    raise exception 'LSA: Schueler nicht gefunden' using errcode = 'P0002';
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
    insert into lsa_sessions (student_id, subject, grade, item_ids, started_at, status, modus)
    values (p_student_id, p_subject, p_grade, '{}'::uuid[], p_jetzt, 'in_progress', 'adaptiv')
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
     where t.status = 'ready'
       and coalesce(t.is_active, true)
       and coalesce(t.is_tutorial, false) = false
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

  insert into lsa_sessions (student_id, subject, grade, item_ids, started_at, status, modus)
  values (p_student_id, p_subject, p_grade, v_items, p_jetzt, 'in_progress', 'fest')
  returning id into v_session_id;

  return jsonb_build_object(
    'session_id',  v_session_id,
    'total_items', array_length(v_items, 1),
    'item',        public.lsa_question_payload(v_items[1])
  );
end;
$$;

revoke execute on function public.lsa_start(uuid, integer, text, text, timestamptz) from public;
grant  execute on function public.lsa_start(uuid, integer, text, text, timestamptz)
  to authenticated, service_role;

-- ============================================================================
-- 5. lsa_submit — fest (Bestand) ODER adaptiv. Alte 4-Arg-Signatur droppen.
-- ============================================================================

drop function if exists public.lsa_submit(uuid, uuid, jsonb, integer);

create or replace function public.lsa_submit(
  p_session_id  uuid,
  p_task_id     uuid,
  p_response    jsonb,
  p_duration_ms integer     default null,
  p_jetzt       timestamptz default now()
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
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
$$;

revoke execute on function public.lsa_submit(uuid, uuid, jsonb, integer, timestamptz) from public;
grant  execute on function public.lsa_submit(uuid, uuid, jsonb, integer, timestamptz)
  to authenticated, service_role;

-- ============================================================================
-- 6. lead_lsa_freigeben auf 'fest' pinnen (Loch-Fix, s. Kopf)
--    Nur diese eine Zeile aendert sich; alles andere byte-identisch.
-- ============================================================================

create or replace function public.lead_lsa_freigeben(p_lead_id uuid, p_grade integer, p_subject text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
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

  -- A16: der Kiosk laeuft weiter ueber die feste item_ids-Liste (platz_next
  -- ist item_ids-gekoppelt). Bis die platz-Ebene adaptiv verdrahtet ist, wird
  -- der Modus hier bewusst auf 'fest' gepinnt.
  v_result := public.lsa_start(v_student_id, p_grade, p_subject, 'fest');

  update leads set status = 'lsa_freigegeben' where id = p_lead_id;

  return jsonb_build_object(
    'session_id',  v_result -> 'session_id',
    'student_id',  to_jsonb(v_student_id),
    'total_items', v_result -> 'total_items'
  );
end;
$$;

commit;
