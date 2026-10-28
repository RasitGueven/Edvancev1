-- Reihe 1 · A2.6 Aufgabe-Funktionen fuer B, C und D (Konzept §9, verbindlich; Signaturen im DATENVERTRAG §13.4).
--
--   aufgabe_ziehen(p_kind, p_skill, p_rolle, p_stufe, p_ausschluss) → task_id | null
--   aufgabe_zwilling(p_kind, p_task, p_rolle)                     → task_id | null
--   aufgabe_payload(p_task)                                       → jsonb (Kindersicht ohne Loesung)
--   aufgabe_werten(p_task, p_antwort)                             → (richtig, fehlbild_key, rueckmeldung), schreibt nie
--   aufgabe_meta(p_task)                                          → (skill_key, kernidee_key, bauform_key, rolle, stufe)
--   aufgabe_gezeigt(p_kind, p_task, p_session)                    → void, nur Session vor Ort
--   skill_kann_entfallen(p_skill)                                 → boolean
--
-- Ziehbar ist eine Instanz, wenn: Pool session, Bauform freigegeben und Instanz in deren aktueller Version, Instanz
-- ready, aktiv und nicht pausiert (aufgabe_bewaehrung.status nicht pausiert/auffaellig), genau die Rolle; Rolle home
-- nur Stufe 1–3. Bevorzugt in der Session ungesehene Instanzen; ein gezeigtes Loesungsbeispiel und eine gesehene
-- Generalprobe-Aufgabe kommen fuer dasselbe Kind nie wieder. Nur fuer uebung und warmup faellt aufgabe_ziehen auf
-- freigegebene Session-Aufgaben ohne Bauform zurueck (Stufe aus difficulty).
-- Neue Antwortformate (Feldmaske, Loesungsmenge, …) wertet format_werten aus A3; bis dahin meldet aufgabe_werten
-- sie als noch nicht wertbar.

-- Wer ruft fuer ein Kind auf (Zweitpruefung A2, Befund 9):
--   'voll'   Systemaufruf, Admin, Coach mit aktiver Akte — alle Rollen
--   'tablet' das Tablet, an dem das Kind gerade in einer aktiven Session sitzt — alle Rollen ausser home
--   'kind'   das Kind selbst (zuhause) — nur Rolle home (FernUSG: kein Zugriff auf Session-Aufgaben von zuhause)
--   null     sonst
create function public.aufgabe_aufrufer(p_kind uuid)
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
    when public.ist_systemaufruf() or coalesce(public.get_my_role(), '') = 'admin'
         or (coalesce(public.get_my_role(), '') = 'coach' and coalesce(public.lsa_may_act_for(p_kind), false)) then 'voll'
    when exists (select 1 from public.session_tablets st
                   join public.coaching_sessions cs on cs.id = st.session_id
                  where st.student_id = p_kind and st.geraet_id = auth.uid() and st.geloest_am is null
                    and cs.status = 'active') then 'tablet'
    when coalesce(public.get_my_student_id() = p_kind, false) then 'kind'
  end
$$;

create function public.aufgabe_recht(p_kind uuid, p_rolle text)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case public.aufgabe_aufrufer(p_kind)
           when 'voll' then true
           when 'tablet' then p_rolle is distinct from 'home'
           when 'kind' then p_rolle = 'home'
           else false end
$$;

-- Gruen heisst: jede Pruefung der Pruefmaschine ok (tasks.pruefmaschine {"1": {"ok": true}, …}, nicht leer).
create function public.instanz_gruen(p_pruefmaschine jsonb)
returns boolean language sql immutable as $$
  select jsonb_typeof(p_pruefmaschine) = 'object' and p_pruefmaschine <> '{}'::jsonb
     and not exists (select 1 from jsonb_each(p_pruefmaschine) e where coalesce((e.value ->> 'ok')::boolean, false) = false)
$$;

-- Ziehbare Instanz (ohne Rolle/Kind): siehe Kopf.
create function public.aufgabe_ziehbar(p_task uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
      from public.tasks t
      join public.bauformen b on b.id = t.bauform_id
     where t.id = p_task
       and b.status = 'freigegeben' and t.bauform_version = b.version
       and t.status = 'ready' and coalesce(t.is_active, false) and 'session' = any (t.einsatz)
       and public.instanz_gruen(t.pruefmaschine)
       and not exists (select 1 from public.aufgabe_bewaehrung w
                        where w.task_id = t.id and w.status in ('pausiert', 'auffaellig')))
$$;

-- Aufgaben, die das Kind in einer Session vor Ort schon gesehen hat (als Aufgabe oder Loesungsbeispiel).
create function public.aufgabe_gesehen_von(p_kind uuid)
returns table (task_id uuid, als_beispiel boolean, zuletzt timestamptz)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select x.task_id, bool_or(x.beispiel), max(x.zeit)
    from (select g.task_id, coalesce(t.rolle = 'beispiel', false) as beispiel, g.am as zeit
            from public.aufgabe_gesehen g join public.tasks t on t.id = g.task_id where g.student_id = p_kind
          union all
          select a.task_id, false, a.zeit from public.session_ausgegeben a where a.student_id = p_kind
          union all
          select s.task_id, s.art = 'beispiel', s.zeit from public.session_schritte s
           where s.student_id = p_kind and s.task_id is not null) x
   group by x.task_id
$$;

create function public.aufgabe_ziehen(p_kind uuid, p_skill text, p_rolle text, p_stufe int default null,
                                      p_ausschluss uuid[] default '{}')
returns uuid
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_id uuid;
begin
  if p_rolle is null or p_rolle not in ('warmup', 'uebung', 'transfer', 'recap', 'beispiel', 'home', 'generalprobe') then
    raise exception 'aufgabe_ziehen: unbekannte Rolle %', p_rolle using errcode = '22023';
  end if;
  if not public.aufgabe_recht(p_kind, p_rolle) then
    raise exception 'aufgabe_ziehen: kein Recht fuer dieses Kind und diese Rolle' using errcode = '42501';
  end if;

  with gesehen as (select * from public.aufgabe_gesehen_von(p_kind))
  select t.id into v_id
    from public.tasks t
    left join gesehen g on g.task_id = t.id
   where t.skill_key = p_skill
     and t.rolle = p_rolle
     and t.id <> all (coalesce(p_ausschluss, '{}'))
     and (p_rolle <> 'home' or t.stufe <= 3)
     and public.aufgabe_ziehbar(t.id)
     and not coalesce(g.als_beispiel, false)
     and (p_rolle not in ('generalprobe', 'beispiel') or g.task_id is null)
   -- Stufe vor "ungesehen" (Befund 11): gleich, dann darunter, dann darueber; ohne p_stufe die leichteste.
   order by case when p_stufe is null then t.stufe
                 when t.stufe = p_stufe then 0
                 when t.stufe < p_stufe then p_stufe - t.stufe
                 else 10 + t.stufe - p_stufe end,
            (g.task_id is not null),
            g.zuletzt nulls first,
            md5(p_kind::text || t.id::text)
   limit 1;

  -- Rueckfall nur fuer Uebung und Warm-up: freigegebene Session-Aufgaben ohne Bauform, Stufe aus difficulty.
  if v_id is null and p_rolle in ('uebung', 'warmup') then
    with gesehen as (select * from public.aufgabe_gesehen_von(p_kind))
    select t.id into v_id
      from public.tasks t
      left join gesehen g on g.task_id = t.id
     where t.skill_key = p_skill
       and t.bauform_id is null
       and t.id <> all (coalesce(p_ausschluss, '{}'))
       and public.session_im_pool(t.id, false)
       and not exists (select 1 from public.aufgabe_bewaehrung w
                        where w.task_id = t.id and w.status in ('pausiert', 'auffaellig'))
       and not coalesce(g.als_beispiel, false)
     order by case when p_stufe is null then coalesce(t.difficulty, 1)
                   when coalesce(t.difficulty, 1) = p_stufe then 0
                   when coalesce(t.difficulty, 1) < p_stufe then p_stufe - coalesce(t.difficulty, 1)
                   else 10 + coalesce(t.difficulty, 1) - p_stufe end,
              (g.task_id is not null),
              g.zuletzt nulls first,
              md5(p_kind::text || t.id::text)
     limit 1;
  end if;
  return v_id;
end $$;

create function public.aufgabe_zwilling(p_kind uuid, p_task uuid, p_rolle text default null)
returns uuid
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  t public.tasks;
  v_id uuid;
begin
  select * into t from public.tasks where id = p_task;
  if not public.aufgabe_recht(p_kind, coalesce(p_rolle, t.rolle)) then
    raise exception 'aufgabe_zwilling: kein Recht fuer dieses Kind und diese Rolle' using errcode = '42501';
  end if;
  if t.bauform_id is null then
    return null;
  end if;
  with gesehen as (select * from public.aufgabe_gesehen_von(p_kind))
  select z.id into v_id
    from public.tasks z
    left join gesehen g on g.task_id = z.id
   where z.bauform_id = t.bauform_id
     and z.rolle = coalesce(p_rolle, t.rolle)
     and z.stufe = t.stufe
     and z.id <> t.id
     and public.aufgabe_ziehbar(z.id)
     and not coalesce(g.als_beispiel, false)
     and (coalesce(p_rolle, t.rolle) not in ('generalprobe', 'beispiel') or g.task_id is null)
   order by (g.task_id is not null), g.zuletzt nulls first, md5(p_kind::text || z.id::text)
   limit 1;
  return v_id;
end $$;

-- Lesen (Payload, Wertung, Meta): Admin, Coach, Lena alles. Ein Tablet in einer aktiven Session: was es dort schon
-- bekommen hat (auch wenn die Instanz inzwischen pausiert ist, Befund 2) und Ziehbares ausser home. Das Kind selbst
-- (zuhause): nur ziehbare Instanzen der Rolle home. Sonst niemand (Eltern, fremde Kinder). LSA-Aufgaben nie.
create function public.aufgabe_lesbar(p_task uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with t as (select x.id, x.rolle, x.bauform_id from public.tasks x where x.id = p_task),
       meine_tablets as (select st.session_id, st.student_id from public.session_tablets st
                           join public.coaching_sessions cs on cs.id = st.session_id
                          where st.geraet_id = auth.uid() and st.geloest_am is null and cs.status = 'active')
  select public.ist_systemaufruf()
      or coalesce(public.get_my_role(), '') in ('admin', 'coach')
      or public.darf_pruefen()
      or exists (select 1 from meine_tablets m join public.session_ausgegeben a
                   on a.session_id = m.session_id and a.student_id = m.student_id where a.task_id = p_task)
      or (exists (select 1 from meine_tablets)
          and exists (select 1 from t where t.rolle is distinct from 'home'
                        and (public.aufgabe_ziehbar(t.id)
                             or (t.bauform_id is null and public.session_im_pool(t.id, false)))))
      or (public.get_my_student_id() is not null
          and exists (select 1 from t where t.rolle = 'home' and public.aufgabe_ziehbar(t.id)))
$$;

create function public.aufgabe_payload(p_task uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  t public.tasks;
  b public.bauformen;
  v jsonb;
  v_loesung text;
begin
  if not public.aufgabe_lesbar(p_task) then
    raise exception 'aufgabe_payload: Aufgabe nicht freigegeben' using errcode = '42501';
  end if;
  select * into t from public.tasks where id = p_task;
  if not found then
    raise exception 'aufgabe_payload: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  select * into b from public.bauformen where id = t.bauform_id;

  if jsonb_typeof(t.question_payload) = 'object' and t.question_payload ? 'format' then
    -- Neue Formate (A3): question_payload IST die Kindersicht (CHECK tasks_question_payload_no_solution).
    v := jsonb_build_object('task_id', t.id, 'kind', 'format', 'prompt', coalesce(t.question, ''),
                            'assets', public.lsa_task_assets(t.id), 'format', t.question_payload ->> 'format',
                            'payload', t.question_payload);
  else
    v := public.lsa_question_payload(p_task) - 'themenfeld';
  end if;

  v := v || jsonb_strip_nulls(jsonb_build_object('rolle', t.rolle, 'stufe', t.stufe, 'bauform_key', b.schluessel));
  if t.rolle = 'beispiel' then
    select s.solution into v_loesung from public.task_solutions s where s.task_id = t.id;
    v := v || jsonb_build_object('loesungsbeispiel', jsonb_build_object(
      'aufgabe', coalesce(t.question, ''),
      'schritte', coalesce((select jsonb_agg(jsonb_build_object('text', btrim(z)) order by n)
                              from unnest(string_to_array(coalesce(v_loesung, ''), E'\n')) with ordinality u(z, n)
                             where btrim(z) <> ''), '[]'::jsonb),
      'warum', b.steckbrief -> 'warum'));
  end if;
  return v;
end $$;

-- Rueckmeldung zu einem Fehlbild: der Satz aus dem Steckbrief der Bauform (fehlbilder[].rueckmeldung), sonst der
-- freigegebene Klartext des Katalogs.
create function public.aufgabe_rueckmeldung(p_task uuid, p_slug text)
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(
    (select f ->> 'rueckmeldung'
       from public.tasks t join public.bauformen b on b.id = t.bauform_id,
            jsonb_array_elements(case when jsonb_typeof(b.steckbrief -> 'fehlbilder') = 'array'
                                      then b.steckbrief -> 'fehlbilder' else '[]'::jsonb end) f
      where t.id = p_task and f ->> 'key' = p_slug limit 1),
    -- Ohne Bauform wie bisher in antwort_abgeben der freigegebene Klartext; Instanzen nur ihr Steckbrief-Satz
    -- (der Klartext ist fuer Coach und Lena geschrieben, Befund 18).
    (select fl.klartext from public.fehlbild_labels fl
      where fl.slug = p_slug and fl.freigegeben_am is not null
        and exists (select 1 from public.tasks t where t.id = p_task and t.bauform_id is null)))
$$;

-- p_antwort: neue Formate die Antwort-JSON aus DATENVERTRAG §13.1; alte Formate {"eingabe": <wie antwort_abgeben>}
-- und bei MULTI_PART zusaetzlich {"teil": n}. Rein: liest nur, schreibt nie (pgTAP reihe1_a2_funktionen).
create function public.aufgabe_werten(p_task uuid, p_antwort jsonb)
returns table (richtig boolean, fehlbild_key text, rueckmeldung text)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  t public.tasks;
  r record;
begin
  if not public.aufgabe_lesbar(p_task) then
    raise exception 'aufgabe_werten: Aufgabe nicht freigegeben' using errcode = '42501';
  end if;
  select * into t from public.tasks where id = p_task;
  if not found then
    raise exception 'aufgabe_werten: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if jsonb_typeof(t.question_payload) = 'object' and t.question_payload ? 'format' then
    -- late binding: format_werten kommt mit A3
    begin
      execute 'select * from public.format_werten($1, $2)' into r using p_task, p_antwort;
    exception when undefined_function then
      raise exception 'aufgabe_werten: dieses Format ist noch nicht wertbar' using errcode = 'P0001',
        hint = 'format_noch_nicht_wertbar';
    end;
    richtig := r.richtig; fehlbild_key := r.fehlbild_key; rueckmeldung := r.rueckmeldung;
  else
    select * into r from public.session_bewerten(
      p_task,
      case when jsonb_typeof(p_antwort -> 'teil') = 'number' then (p_antwort ->> 'teil')::numeric::int end,
      case when p_antwort ? 'eingabe' then p_antwort -> 'eingabe' else p_antwort end);
    richtig := r.ergebnis = 'richtig';
    fehlbild_key := nullif(r.fehlbild_slug, '__known__');
    rueckmeldung := case when fehlbild_key is not null then public.aufgabe_rueckmeldung(p_task, fehlbild_key) end;
  end if;
  return next;
end $$;

create function public.aufgabe_meta(p_task uuid)
returns table (skill_key text, kernidee_key text, bauform_key text, rolle text, stufe int)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select t.skill_key, coalesce(t.kernidee_key, b.kernidee_key), b.schluessel, t.rolle,
         coalesce(t.stufe::int, t.difficulty)
    from public.tasks t left join public.bauformen b on b.id = t.bauform_id
   where t.id = p_task and public.aufgabe_lesbar(p_task)
$$;

create function public.aufgabe_gezeigt(p_kind uuid, p_task uuid, p_session uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- Nur Session vor Ort (FernUSG: zuhause wird nichts je Aufgabe gespeichert): Coach, Admin, System oder das Tablet,
  -- nie das Kind selbst. Die Session ist aktiv, das Kind steht in ihr.
  if coalesce(public.aufgabe_aufrufer(p_kind), 'kind') not in ('voll', 'tablet') then
    raise exception 'aufgabe_gezeigt: kein Recht fuer dieses Kind' using errcode = '42501';
  end if;
  if not exists (select 1 from public.session_students ss join public.coaching_sessions cs on cs.id = ss.session_id
                  where ss.session_id = p_session and ss.student_id = p_kind and cs.status = 'active') then
    raise exception 'aufgabe_gezeigt: das Kind ist nicht in dieser laufenden Session' using errcode = 'P0001';
  end if;
  if coalesce((select cs.testlauf from public.coaching_sessions cs where cs.id = p_session), false) then
    return;  -- Testlaeufe merken nichts (Entscheidung 27)
  end if;
  insert into public.aufgabe_gesehen (student_id, task_id, session_id)
  values (p_kind, p_task, p_session)
  on conflict do nothing;
end $$;

create function public.skill_kann_entfallen(p_skill text)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(bool_and(coalesce(b.steckbrief ->> 'kann_entfallen', '') = 'true'), false)
    from public.bauformen b where b.skill_key = p_skill and b.status <> 'entwurf'
$$;

do $$
declare f text;
begin
  foreach f in array array[
    'aufgabe_aufrufer(uuid)', 'aufgabe_recht(uuid,text)', 'aufgabe_ziehbar(uuid)', 'aufgabe_gesehen_von(uuid)', 'aufgabe_lesbar(uuid)',
    'aufgabe_rueckmeldung(uuid,text)'] loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
  end loop;
  foreach f in array array[
    'aufgabe_ziehen(uuid,text,text,int,uuid[])', 'aufgabe_zwilling(uuid,uuid,text)', 'aufgabe_payload(uuid)',
    'aufgabe_werten(uuid,jsonb)', 'aufgabe_meta(uuid)', 'aufgabe_gezeigt(uuid,uuid,uuid)',
    'skill_kann_entfallen(text)', 'instanz_gruen(jsonb)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
    execute format('comment on function public.%s is %L', f, 'reihe1 fertig');
  end loop;
end $$;
