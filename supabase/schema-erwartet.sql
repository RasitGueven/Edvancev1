-- schema-erwartet.sql
-- Erzeugt von tools/schema-snapshot.sh.
-- Stand nach allen Migrationen in supabase/migrations/.
-- Nicht von Hand bearbeiten — nach Schemaänderungen neu erzeugen.

--
-- PostgreSQL database dump
--


-- Dumped from database version 18.6 (Ubuntu 18.6-0ubuntu0.26.04.1)
-- Dumped by pg_dump version 18.6 (Ubuntu 18.6-0ubuntu0.26.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: badge_form; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.badge_form AS ENUM (
    'round',
    'shield'
);


--
-- Name: badge_rarity; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.badge_rarity AS ENUM (
    'bronze',
    'silver',
    'gold',
    'platinum'
);


--
-- Name: app_provision_student(uuid, text, uuid, text, text, integer, text, text, text[], uuid, uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.app_provision_student(p_student_uid uuid, p_student_email text, p_parent_uid uuid, p_parent_email text, p_full_name text, p_class_level integer, p_school_type text, p_school_name text, p_subjects text[], p_coach_id uuid, p_tier_id uuid, p_lead_id uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_student_id uuid;
  v_subj text;
  v_subject_id uuid;
begin
  insert into profiles (id, email, role, full_name)
  values (p_student_uid, p_student_email, 'student', p_full_name)
  on conflict (id) do update
    set email = excluded.email,
        role = 'student',
        full_name = excluded.full_name;

  if p_parent_uid is not null then
    insert into profiles (id, email, role, full_name)
    values (p_parent_uid, p_parent_email, 'parent', null)
    on conflict (id) do update
      set email = excluded.email,
          role = 'parent';
  end if;

  insert into students (profile_id, class_level, school_name, school_type)
  values (p_student_uid, p_class_level, p_school_name, p_school_type)
  returning id into v_student_id;

  if p_parent_uid is not null then
    insert into parent_student (parent_id, student_id)
    values (p_parent_uid, p_student_uid);
  end if;

  if p_subjects is not null then
    foreach v_subj in array p_subjects loop
      select id into v_subject_id from subjects where name = v_subj;
      if v_subject_id is null then
        raise exception 'Fach unbekannt: %', v_subj;
      end if;
      insert into student_subjects (student_id, subject_id)
      values (v_student_id, v_subject_id);
    end loop;
  end if;

  if p_coach_id is not null then
    insert into student_coach (student_id, coach_id)
    values (v_student_id, p_coach_id);
  end if;

  if p_tier_id is not null then
    insert into student_subscriptions (student_id, tier_id)
    values (v_student_id, p_tier_id);
  end if;

  if p_lead_id is not null then
    update leads
       set status = 'converted',
           converted_student_id = v_student_id
     where id = p_lead_id;
  end if;

  return v_student_id;
end;
$$;


--
-- Name: apply_xp_event(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apply_xp_event() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  perform 1 from student_progress where student_id = new.student_id;

  if not found then
    insert into student_progress
      (student_id, xp_total, level, last_activity)
    values
      (new.student_id, new.xp, 1 + (new.xp / 500), now());
    return new;
  end if;

  update student_progress
     set xp_total = xp_total + new.xp,
         level = 1 + ((xp_total + new.xp) / 500),
         last_activity = now()
   where student_id = new.student_id;

  return new;
end;
$$;


--
-- Name: authoring_review_meta(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.authoring_review_meta() RETURNS TABLE(task_id uuid, labels text[], has_incomplete boolean)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select t.id,
         coalesce(array_agg(distinct kv.value) filter (where kv.value is not null), '{}'::text[]),
         coalesce(bool_or(fl.klartext is null or fl.erklaerung is null), false)
    from public.tasks t
    join public.task_solutions s on s.task_id = t.id
    left join lateral jsonb_each_text(
      case when jsonb_typeof(s.acceptance -> 'known_errors') = 'object'
           then s.acceptance -> 'known_errors' else '{}'::jsonb end) as kv(key, value) on true
    left join public.fehlbild_labels fl on fl.slug = kv.value
   where public.get_my_role() = any (array['admin', 'coach'])
   group by t.id
$$;


--
-- Name: calc_presence_multiplier(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calc_presence_multiplier(weeks integer) RETURNS numeric
    LANGUAGE sql IMMUTABLE
    AS $$
  select case
    when weeks >= 8 then 1.30
    when weeks >= 5 then 1.20
    when weeks >= 3 then 1.10
    else 1.00
  end::numeric(3,2)
$$;


--
-- Name: complete_task(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.complete_task(p_task_id uuid) RETURNS TABLE(newly_completed boolean, awarded_xp integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_student uuid;
  v_ins integer;
  v_xp integer;
begin
  v_student := public.get_my_student_id();
  if v_student is null then
    return;
  end if;

  insert into student_task_progress (student_id, task_id)
  values (v_student, p_task_id)
  on conflict (student_id, task_id) do nothing;
  get diagnostics v_ins = row_count;

  if v_ins = 0 then
    return query select false, 0;
    return;
  end if;

  select r.base_xp + r.difficulty_multiplier * coalesce(t.difficulty, 0)
    into v_xp
    from tasks t
    join xp_rules r on r.content_type = t.content_type
   where t.id = p_task_id;

  v_xp := coalesce(v_xp, 0);

  if v_xp > 0 then
    insert into xp_events (student_id, task_id, xp, reason)
    values (v_student, p_task_id, v_xp, 'Aufgabe abgeschlossen');
  end if;

  return query select true, v_xp;
end;
$$;


--
-- Name: enforce_mastery_gate(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enforce_mastery_gate() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_was_mastered boolean := false;
begin
  new.updated_at := now();

  if tg_op = 'UPDATE' then
    v_was_mastered := coalesce(old.mastered, false);
  end if;

  if new.mastered and not v_was_mastered then
    if public.get_my_role() not in ('coach','admin') then
      raise exception 'Mastered darf nur durch Coach gesetzt werden (FernUSG)';
    end if;
    new.mastered_by := auth.uid();
    new.mastered_at := now();
  end if;

  return new;
end;
$$;


--
-- Name: freigabe_muster(text, uuid[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.freigabe_muster(p_skill_key text, p_task_ids uuid[] DEFAULT NULL::uuid[]) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_id uuid;
  v_n  integer := 0;
begin
  -- `is distinct from` statt `<>`: get_my_role() ist NULL fuer einen nicht
  -- angemeldeten Aufrufer, und `NULL <> 'admin'` waere NULL — die Pruefung
  -- feuerte dann nicht. `is distinct from` liefert bei NULL true.
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'A21: nur die fachliche Freigabe (admin) darf freigeben'
      using errcode = '42501';
  end if;

  for v_id in
    select id from public.tasks
     where skill_key = p_skill_key
       and status = 'draft'
       and (p_task_ids is null or id = any (p_task_ids))
  loop
    begin
      perform public.task_status_set(v_id, 'ready');
      v_n := v_n + 1;
    exception
      -- P0001 = Pflichtfeld oder Loesung unvollstaendig (task_status_set-Gate).
      -- Das Item bleibt 'draft', die Gruppe laeuft weiter.
      when sqlstate 'P0001' then null;
    end;
  end loop;

  return v_n;
end $$;


--
-- Name: freigabe_zuruecknehmen(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.freigabe_zuruecknehmen(p_skill_key text) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_n integer;
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'A21: nur die fachliche Freigabe (admin) darf Freigaben zuruecknehmen'
      using errcode = '42501';
  end if;

  update public.tasks
     set status      = 'draft',
         reviewed_by = null,
         reviewed_at = null
   where skill_key = p_skill_key
     and status    = 'ready';

  get diagnostics v_n = row_count;
  return v_n;
end $$;


--
-- Name: get_my_role(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_my_role() RETURNS text
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select role from profiles where id = auth.uid() limit 1;
$$;


--
-- Name: get_my_student_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_my_student_id() RETURNS uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select id from students where profile_id = auth.uid() limit 1;
$$;


--
-- Name: is_parent_of_student(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_parent_of_student(p_student_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1
    from parent_student ps
    where ps.parent_id = auth.uid()
      and ps.student_id in (
        select profile_id from students where id = p_student_id
      )
  );
$$;


--
-- Name: lead_assessment_upsert(uuid, text, text, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lead_assessment_upsert(p_lead_id uuid, p_source text, p_note text, p_weak_topics text[]) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_id uuid;
begin
  if public.get_my_role() not in ('coach','admin') then
    raise exception 'lead_assessment_upsert: nur Coach/Admin' using errcode = '42501';
  end if;

  if p_source not in ('parent','child') then
    raise exception 'lead_assessment_upsert: source muss parent oder child sein'
      using errcode = '23514';
  end if;

  if not exists (select 1 from leads where id = p_lead_id) then
    raise exception 'lead_assessment_upsert: Lead nicht gefunden' using errcode = 'P0002';
  end if;

  insert into lead_assessments (lead_id, source, note, weak_topics)
  values (p_lead_id, p_source, p_note, coalesce(p_weak_topics, '{}'))
  on conflict (lead_id, source) do update
     set note = excluded.note, weak_topics = excluded.weak_topics
  returning id into v_id;

  return jsonb_build_object('ok', true, 'assessment_id', v_id);
end;
$$;


--
-- Name: lead_convert(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lead_convert(p_lead_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_lead       leads%rowtype;
  v_student_id uuid;
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'lead_convert: nur Admin' using errcode = '42501';
  end if;

  select * into v_lead from leads where id = p_lead_id;
  if not found then
    raise exception 'lead_convert: Lead nicht gefunden' using errcode = 'P0002';
  end if;

  if v_lead.status = 'converted' then
    raise exception 'lead_convert: Lead ist bereits konvertiert'
      using errcode = 'P0001';
  end if;

  select id into v_student_id
    from students where lead_id = p_lead_id and is_provisional;
  if v_student_id is null then
    raise exception 'lead_convert: kein provisorischer Schueler zu diesem Lead'
      using errcode = 'P0002';
  end if;

  -- lead_id nullen: eine spätere Lead-Löschung darf NIE den echten Schüler
  -- kaskadieren. Die Verbindung hält ab jetzt leads.converted_student_id.
  update students
     set is_provisional = false, lead_id = null
   where id = v_student_id;

  update leads
     set status = 'converted', converted_student_id = v_student_id
   where id = p_lead_id;

  return jsonb_build_object('ok', true, 'student_id', v_student_id);
end;
$$;


--
-- Name: lead_delete(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lead_delete(p_lead_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_lead leads%rowtype;
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'lead_delete: nur Admin' using errcode = '42501';
  end if;

  select * into v_lead from leads where id = p_lead_id;
  if not found then
    raise exception 'lead_delete: Lead nicht gefunden' using errcode = 'P0002';
  end if;

  -- Aufbewahrungspflicht: ein konvertierter Lead wird nicht über diesen Weg
  -- gelöscht.
  if v_lead.status = 'converted' then
    raise exception 'lead_delete: konvertierter Lead — Aufbewahrungspflicht'
      using errcode = 'P0001';
  end if;

  -- Kaskade (S7): leads → lead_assessments (A3) UND
  -- leads → students(lead_id) → lsa_sessions → lsa_responses (A1 Option 1).
  -- Der provisorische Schüler und seine LSA-Daten fallen restlos mit.
  delete from leads where id = p_lead_id;

  return jsonb_build_object('ok', true, 'lead_id', p_lead_id);
end;
$$;


--
-- Name: lead_lsa_freigeben(uuid, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lead_lsa_freigeben(p_lead_id uuid, p_grade integer, p_subject text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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
  v_result := public.lsa_start(v_student_id, p_grade, p_subject);

  update leads set status = 'lsa_freigegeben' where id = p_lead_id;

  -- total_items existiert im adaptiven Rueckgabeobjekt bewusst nicht (die
  -- Aufgabenzahl bleibt verborgen) -> jsonb-Feldzugriff liefert dann NULL.
  return jsonb_build_object(
    'session_id',  v_result -> 'session_id',
    'student_id',  to_jsonb(v_student_id),
    'total_items', v_result -> 'total_items'
  );
end;
$$;


--
-- Name: lena_beanstande(uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lena_beanstande(p_task_id uuid, p_kategorie text, p_notiz text DEFAULT NULL::text) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'A20: nur die fachliche Freigabe (admin) darf beanstanden'
      using errcode = '42501';
  end if;
  update public.tasks set status = 'beanstandet' where id = p_task_id;
  if not found then
    raise exception 'A20: Aufgabe % nicht gefunden', p_task_id using errcode = 'P0002';
  end if;
  insert into public.task_reviews (task_id, kategorie, notiz, geprueft_von)
    values (p_task_id, p_kategorie, p_notiz, auth.uid());
  return 1;
end $$;


--
-- Name: lena_beanstande_muster(text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lena_beanstande_muster(p_skill_key text, p_fehlbild_label text, p_kategorie text, p_notiz text DEFAULT NULL::text) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare v_n integer;
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'A20: nur die fachliche Freigabe (admin) darf beanstanden'
      using errcode = '42501';
  end if;

  create temporary table _betroffen on commit drop as
    select t.id
      from public.tasks t
      join public.task_solutions s on s.task_id = t.id
     where t.skill_key = p_skill_key
       and jsonb_typeof(s.acceptance -> 'known_errors') = 'object'
       and exists (
         select 1 from jsonb_each_text(s.acceptance -> 'known_errors') as kv(key, value)
          where kv.value = p_fehlbild_label);

  update public.tasks set status = 'beanstandet'
   where id in (select id from _betroffen);

  insert into public.task_reviews (task_id, kategorie, notiz, geprueft_von)
    select id, p_kategorie, p_notiz, auth.uid() from _betroffen;

  select count(*) into v_n from _betroffen;
  return v_n;
end $$;


--
-- Name: lena_text_aendern(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lena_text_aendern(p_task_id uuid, p_question text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare v_alt text;
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'A20: nur die fachliche Freigabe (admin) darf den Text aendern'
      using errcode = '42501';
  end if;
  select question into v_alt from public.tasks where id = p_task_id;
  if not found then
    raise exception 'A20: Aufgabe % nicht gefunden', p_task_id using errcode = 'P0002';
  end if;
  if public.lsa_ziffernfolge(p_question) is distinct from public.lsa_ziffernfolge(v_alt) then
    raise exception 'A20: Der Text darf geaendert werden, die Zahlen nicht.'
      using errcode = '23514';
  end if;
  update public.tasks set question = p_question where id = p_task_id;
  -- Status bewusst unberuehrt: wer den Text aendert, setzt KEINE Freigabe.
end $$;


--
-- Name: lsa_abgabeart(text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_abgabeart(p_input_type text, p_response jsonb) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  select case
    -- Der bewusste Knopf. Steht vor allem anderen: er IST die Aussage.
    when p_response ->> 'dont_know' = 'true' then 'weiss_nicht'
    when p_response is null or jsonb_typeof(p_response) = 'null' then 'leer'
    when p_input_type = 'MC' then
      case when jsonb_typeof(p_response -> 'selected') = 'array'
                and jsonb_array_length(p_response -> 'selected') > 0
           then 'antwort' else 'leer' end
    when p_input_type = 'MULTI_PART' then
      -- Auf Item-Ebene zaehlt nur, ob ueberhaupt etwas kam; die einzelnen
      -- Teilaufgaben werden je fuer sich eingeordnet.
      case when jsonb_typeof(p_response) = 'object' and p_response <> '{}'::jsonb
           then 'antwort' else 'leer' end
    when btrim(coalesce(p_response ->> 'text', p_response ->> 'value', '')) = ''
      then 'leer'
    else 'antwort'
  end
$$;


--
-- Name: lsa_abschluss(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_abschluss(p_skill_key text) RETURNS TABLE(skill_key text)
    LANGUAGE sql STABLE
    AS $$
  with recursive dep(sk) as (
    select k.voraussetzt_skill_key
      from skill_kante k where k.skill_key = p_skill_key
    union
    select k.voraussetzt_skill_key
      from skill_kante k join dep on k.skill_key = dep.sk
  )
  select sk from dep
$$;


--
-- Name: lsa_acceptance_rule_valid(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_acceptance_rule_valid(p_rule jsonb) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$
  select jsonb_typeof(p_rule) = 'object'
     and jsonb_typeof(p_rule -> 'canonical') = 'string'
     and btrim(p_rule ->> 'canonical') <> ''
     and (p_rule -> 'equivalents' is null
          or (jsonb_typeof(p_rule -> 'equivalents') = 'array'
              and not exists (
                select 1 from jsonb_array_elements(p_rule -> 'equivalents') as e(v)
                 where jsonb_typeof(v) <> 'string' or btrim(v #>> '{}') = ''
              )))
     and (p_rule -> 'notation' is null
          or (jsonb_typeof(p_rule -> 'notation') = 'object'
              and not exists (
                select 1 from jsonb_each(p_rule -> 'notation') as e(k, v)
                 where k not in ('decimal_comma', 'unit_optional',
                                 'ignore_case', 'ignore_space')
                    or jsonb_typeof(v) <> 'boolean'
              )))
     and (p_rule -> 'tolerance' is null
          or (jsonb_typeof(p_rule -> 'tolerance') = 'object'
              and (p_rule #>> '{tolerance,mode}') in ('exact', 'absolute', 'decimals')
              and case p_rule #>> '{tolerance,mode}'
                    when 'exact' then p_rule -> 'tolerance' -> 'value' is null
                    when 'absolute' then
                      jsonb_typeof(p_rule -> 'tolerance' -> 'value') = 'number'
                      and (p_rule #>> '{tolerance,value}')::numeric > 0
                    else
                      jsonb_typeof(p_rule -> 'tolerance' -> 'value') = 'number'
                      and (p_rule #>> '{tolerance,value}') ~ '^[0-6]$'
                  end))
     and (p_rule -> 'unit' is null or jsonb_typeof(p_rule -> 'unit') = 'string')
     and (p_rule -> 'unit_graded' is null
          or jsonb_typeof(p_rule -> 'unit_graded') = 'boolean')
     and (p_rule -> 'require_reduced' is null
          or jsonb_typeof(p_rule -> 'require_reduced') = 'boolean')
     -- NEU (A12): die bekannten Fehlbilder. Objekt (Wert → Fehlertyp) ODER
     -- Array (nur die Werte) — die Wahl der Form ist noch nicht getroffen und
     -- wird hier bewusst nicht erzwungen. Fehlt das Feld, ist alles wie vorher.
     and (p_rule -> 'known_errors' is null
          or jsonb_typeof(p_rule -> 'known_errors') in ('object', 'array'))
     and not (coalesce((p_rule ->> 'unit_graded')::boolean, false)
              and coalesce((p_rule #>> '{notation,unit_optional}')::boolean, false))
$_$;


--
-- Name: lsa_acceptance_valid(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_acceptance_valid(p_acceptance jsonb) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$
  select case
    when jsonb_typeof(p_acceptance) <> 'object' then false
    -- leer = "noch nicht gepflegt"; die Spalte ist nullable, '{}' ist der
    -- gleichwertige Zwischenstand eines Entwurfs
    when p_acceptance = '{}'::jsonb then true
    when p_acceptance ? 'canonical' then public.lsa_acceptance_rule_valid(p_acceptance)
    else not exists (
      select 1 from jsonb_each(p_acceptance) as e(k, v)
       where k !~ '^[1-9][0-9]*$' or not public.lsa_acceptance_rule_valid(v)
    )
  end
$_$;


--
-- Name: lsa_answers_valid(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_answers_valid(p_answers jsonb) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$
  select case jsonb_typeof(p_answers)
    when 'array'  then true
    when 'object' then not exists (
      select 1
        from jsonb_each(p_answers) as e(k, v)
       where k !~ '^[1-9][0-9]*$' or jsonb_typeof(v) <> 'array'
    )
    else false
  end
$_$;


--
-- Name: lsa_confirm_focus(uuid, uuid[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_confirm_focus(p_session_id uuid, p_cluster_ids uuid[] DEFAULT NULL::uuid[]) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_session  lsa_sessions;
  v_clusters uuid[];
  v_written  integer := 0;
begin
  if public.get_my_role() not in ('coach','admin') then
    raise exception 'LSA: Lernpfad-Freigabe nur durch Coach (FernUSG)' using errcode = '42501';
  end if;

  select * into v_session from lsa_sessions where id = p_session_id;
  if not found then
    raise exception 'LSA: Session nicht gefunden' using errcode = 'P0002';
  end if;
  if v_session.status <> 'completed' then
    raise exception 'LSA: Session ist noch nicht ausgewertet' using errcode = 'P0001';
  end if;

  v_clusters := coalesce(
    p_cluster_ids,
    (select array_agg((x)::uuid)
       from jsonb_array_elements_text(
              coalesce(v_session.result_summary -> 'proposal' -> 'focus_cluster_ids',
                       '[]'::jsonb)
            ) as t(x))
  );

  if v_clusters is null or array_length(v_clusters, 1) is null then
    return jsonb_build_object('applied', true, 'focus_areas_written', 0);
  end if;

  insert into student_focus_areas (student_id, cluster_id, coach_id, source, note)
  select v_session.student_id, c, auth.uid(), 'lsa',
         'Aus LSA-Vorschlag bestaetigt (' || p_session_id::text || ')'
    from unnest(v_clusters) as c
   where not exists (
           select 1 from student_focus_areas f
            where f.student_id = v_session.student_id
              and f.cluster_id = c
              and f.active
         );
  get diagnostics v_written = row_count;

  update lsa_sessions
     set result_summary = jsonb_set(
           result_summary,
           '{proposal,applied}',
           'true'::jsonb,
           true
         )
   where id = p_session_id;

  return jsonb_build_object('applied', true, 'focus_areas_written', v_written);
end;
$$;


--
-- Name: lsa_fehlbild_auswertung(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_fehlbild_auswertung(p_session_id uuid) RETURNS TABLE(fehlbild_slug text, familie text, familie_elterntext text, anzahl bigint, aufgaben bigint, skills text[], skill_uebergreifend boolean, einstufung text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  with falsch as (
    select r.fehlbild_slug as slug,
           r.task_id       as task_id,
           t.skill_key     as sk
      from public.lsa_responses r
      join public.tasks t on t.id = r.task_id
     where r.session_id = p_session_id
       and exists (
         select 1 from public.lsa_sessions s
          where s.id = p_session_id
            and coalesce(public.lsa_may_act_for(s.student_id), false)
       )
       and r.abgabeart  = 'antwort'
       and r.correct is false
       and r.fehlbild_slug is not null
  ),
  je_slug as (
    -- `aufgaben` zaehlt AUFGABEN, nicht Zeilen: zwei Teilaufgaben desselben
    -- Items sind eine Aufgabe. Genau darauf steht die Einstufung.
    -- count(distinct sk) ignoriert NULL — eine Aufgabe ohne Skill ist kein
    -- zweiter Skill und macht ein Fehlbild nicht uebergreifend.
    select f.slug,
           count(*)                  as n,
           count(distinct f.task_id) as n_aufgaben,
           count(distinct f.sk)      as n_skills,
           coalesce(
             array_agg(distinct f.sk order by f.sk) filter (where f.sk is not null),
             '{}'::text[])           as sk_liste
      from falsch f
     group by f.slug
  )
  select g.slug,
         l.familie,
         case when fam.freigegeben_am is null then null else fam.elterntext end,
         g.n,
         g.n_aufgaben,
         g.sk_liste,
         (g.n_skills >= 2),
         case when g.n >= 2 and g.n_aufgaben >= 2 then 'befund' else 'beobachtung' end
    from je_slug g
    left join public.fehlbild_labels l   on l.slug       = g.slug
    -- Zweiter LEFT JOIN aus demselben Grund wie der erste: ein Slug ohne
    -- Familie muss seine Zeile behalten. INNER JOIN liesse 53 der 73 Slugs
    -- aus dem Report verschwinden.
    left join public.fehlbild_familien fam on fam.schluessel = l.familie
   -- Befunde zuerst, darin das haeufigste — der Report liest von oben.
   -- Innerhalb dessen nach Familie, damit gleiche Buendel beieinander stehen
   -- und der Konsument sie in einem Durchlauf zusammenfassen kann.
   order by (case when g.n >= 2 and g.n_aufgaben >= 2 then 0 else 1 end),
            g.n desc, l.familie asc nulls last, g.slug asc
$$;


--
-- Name: lsa_fehlbild_capture(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_fehlbild_capture() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_kind text;
  v_ke   jsonb;
begin
  -- Nur echte, falsche Abgaben sind Fehlbild-Kandidaten.
  -- CHECK lsa_responses_correct_nur_bei_antwort haelt correct NULL fuer
  -- 'weiss_nicht' und 'leer' — ein "weiss nicht" ist kein Denkfehler und darf
  -- nie als einer gelabelt werden.
  if new.abgabeart <> 'antwort' or new.correct is not false then
    return null;
  end if;

  -- Fehlbild-Erfassung ist Diagnostik-Beiwerk. Ein Fehler hier darf die Abgabe
  -- eines Kindes NIE blockieren — deshalb faengt der Block alles und meldet per
  -- WARNING in die Logs, statt den Insert scheitern zu lassen.
  begin

  -- known_errors pro Teil aus acceptance ziehen.
  -- Multi-Part: acceptance -> '<nr>' -> 'known_errors'; flach: acceptance -> 'known_errors'.
  -- Der coalesce-Fallback auf die flache Form ist defensiv: in Prod sind heute
  -- ALLE acceptance-Zeilen flach und auf Ein-Teil-Items; schreibt ein kuenftiger
  -- Submit-Pfad part_nr auch dort, matcht die strikte Variante sonst stillschweigend nichts.
  select coalesce(
           ts.acceptance -> coalesce(new.part_nr::text, '') -> 'known_errors',
           ts.acceptance -> 'known_errors'
         ),
         coalesce(
           (select e.p ->> 'kind'
              from jsonb_array_elements(t.parts) as e(p)
             where (e.p ->> 'nr') = new.part_nr::text
             limit 1),
           lower(t.input_type)
         )
    into v_ke, v_kind
    from public.tasks t
    join public.task_solutions ts on ts.task_id = t.id
   where t.id = new.task_id;

  if v_ke is null then
    return null;
  end if;

  -- Auf die Primaerschluessel-Zeile schreiben. Kein Match ueber
  -- (session_id, task_id, part_nr): darauf existiert KEIN Unique-Constraint,
  -- eine Wiederholung derselben Aufgabe wuerde sonst fremde Zeilen treffen.
  --
  -- AF6: die Antwort wird VOR dem Matchen normalisiert — dieselbe Funktion, die
  -- lsa_submit fuer die Bewertung benutzt. Damit haengt die Diagnosefaehigkeit
  -- nicht mehr daran, in welcher der drei zulaessigen Formen der Client die
  -- Antwort geschickt hat. Objekte gibt lsa_part_answer unveraendert zurueck.
  update public.lsa_responses
     set fehlbild_slug = public.lsa_fehlbild_match(
                           v_kind, v_ke,
                           public.lsa_part_answer(v_kind, new.response))
   where id = new.id
     and fehlbild_slug is null;

  exception when others then
    raise warning 'lsa_fehlbild_capture: response=% task=% part=% -> %',
      new.id, new.task_id, new.part_nr, sqlerrm;
  end;

  return null;
end;
$$;


--
-- Name: lsa_fehlbild_match(text, jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_fehlbild_match(p_kind text, p_known_errors jsonb, p_response jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
declare
  v_kind  text := lower(coalesce(p_kind, ''));
  v_term  boolean := (v_kind = 'term');
  v_given text;
  v_slug  text;
begin
  if p_known_errors is null or p_response is null then
    return null;
  end if;

  if v_kind = 'mc' then
    -- Ein known_errors-Schlüssel kann keine Auswahl-MENGE abbilden. Deshalb
    -- matcht MC nur bei genau einer gewählten Option; Mehrfachauswahl ist
    -- bewusst kein Fehlbild-Kandidat.
    if jsonb_typeof(p_response -> 'selected') <> 'array'
       or jsonb_array_length(p_response -> 'selected') <> 1 then
      return null;
    end if;
    v_given := public.lsa_normalize_answer(p_response -> 'selected' ->> 0);
  else
    v_given := coalesce(p_response ->> 'text', p_response ->> 'value');
    if v_given is null then
      return null;
    end if;
    v_given := case when v_term then public.lsa_normalize_term(v_given)
                    else public.lsa_normalize_answer(v_given) end;
  end if;

  if v_given is null or v_given = '' then
    return null;
  end if;

  case jsonb_typeof(p_known_errors)
    -- object {wert: slug}: labeled -> gibt den slug zurueck
    when 'object' then
      select ke.value #>> '{}'
        into v_slug
        from jsonb_each(p_known_errors) as ke(key, value)
       where case when v_term then public.lsa_normalize_term(ke.key)
                  else public.lsa_normalize_answer(ke.key) end = v_given
       limit 1;
    -- array [wert]: nur "bekannt-falsch", kein Label -> generischer Marker
    when 'array' then
      select '__known__'
        into v_slug
        from jsonb_array_elements_text(p_known_errors) as k(w)
       where case when v_term then public.lsa_normalize_term(k.w)
                  else public.lsa_normalize_answer(k.w) end = v_given
       limit 1;
    else
      v_slug := null;
  end case;

  return v_slug;
end;
$$;


--
-- Name: lsa_fehlbild_report(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_fehlbild_report(p_session_id uuid) RETURNS TABLE(skill_key text, fehlbild_slug text, klartext text, anzahl bigint, anteil numeric)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  with falsch as (
    select t.skill_key     as sk,
           r.fehlbild_slug as slug
      from public.lsa_responses r
      join public.tasks t on t.id = r.task_id
     where r.session_id = p_session_id
       and exists (
         select 1 from public.lsa_sessions s
          where s.id = p_session_id
            and coalesce(public.lsa_may_act_for(s.student_id), false)
       )
       and r.abgabeart  = 'antwort'
       and r.correct is false
  ),
  je_slug as (
    -- group by trifft slug null als eigene Gruppe (NULLs gelten hier als
    -- gleich) — das ist die "nicht zugeordnet"-Zeile.
    -- Das Fenster ueber der Aggregation liefert den Nenner je Skill, ohne die
    -- Basis ein zweites Mal zu lesen.
    select f.sk,
           f.slug,
           count(*)                            as n,
           sum(count(*)) over (partition by f.sk) as n_skill
      from falsch f
     group by f.sk, f.slug
  )
  select g.sk,
         g.slug,
         -- "nicht zugeordnet" bleibt unabhaengig von der Abnahme sichtbar: es
         -- ist kein Klartext ueber ein Kind, sondern ein Befund ueber die
         -- Registry — genau die Luecke, die Lena sehen muss (AF2).
         case when g.slug is null then 'nicht zugeordnet'
              when l.freigegeben_am is null then null
              else l.klartext end,
         g.n,
         -- Anteil als Bruchteil 0..1, auf 4 Stellen gerundet. Gerundete
         -- Anteile summieren sich nicht zwingend exakt auf 1 — massgeblich
         -- ist `anzahl`.
         round(g.n::numeric / g.n_skill, 4)
    from je_slug g
    left join public.fehlbild_labels l on l.slug = g.slug
   order by g.sk asc, g.n desc, g.slug asc
$$;


--
-- Name: lsa_finish(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_finish(p_session_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_session lsa_sessions;
  v_summary jsonb;
begin
  select * into v_session from lsa_sessions where id = p_session_id;
  if not found then
    raise exception 'LSA: Session nicht gefunden' using errcode = 'P0002';
  end if;
  if not public.lsa_may_act_for(v_session.student_id) then
    raise exception 'LSA: kein Zugriff auf diese Session' using errcode = '42501';
  end if;
  if v_session.status = 'completed' then
    return v_session.result_summary;
  end if;

  with answered as (
    -- Die Einheit der Auswertung ist die ZEILE in lsa_responses — also die
    -- Teilaufgabe, wo es eine gibt, sonst das flache Item. Kompetenz und AFB
    -- kommen bei Multi-Part aus der Teilaufgabe (tasks.parts), nicht aus dem Item.
    select r.correct,
           r.abgabeart,
           r.duration_ms,
           r.task_id,
           r.part_nr,
           coalesce(part.competency, t.competency_content, '?') as competency,
           coalesce(part.afb,        t.afb,                'II') as afb,
           t.cluster_id
      from lsa_responses r
      join tasks t on t.id = r.task_id
      left join lateral (
        select p ->> 'competency_content' as competency,
               p ->> 'afb'                as afb
          from jsonb_array_elements(t.parts) as e(p)
         where r.part_nr is not null
           and (p ->> 'nr')::int = r.part_nr
         limit 1
      ) part on true
     where r.session_id = p_session_id
  ),
  by_competency as (
    select competency,
           count(*) filter (where abgabeart = 'antwort')      as total,
           count(*) filter (where correct)                    as correct_count,
           count(*) filter (where abgabeart <> 'antwort')     as unbeantwortet,
           round(avg(duration_ms) filter (where abgabeart = 'antwort')::numeric, 0)
                                                              as avg_duration_ms,
           round(
             count(*) filter (where correct)::numeric
             / nullif(count(*) filter (where abgabeart = 'antwort'), 0), 2
           )                                                  as hit_rate
      from answered
     group by competency
  ),
  by_afb as (
    select afb,
           count(*) filter (where abgabeart = 'antwort')  as total,
           count(*) filter (where correct)                as correct_count,
           count(*) filter (where abgabeart <> 'antwort') as unbeantwortet
      from answered
     group by afb
  ),
  weak_clusters as (
    select cluster_id,
           round(
             count(*) filter (where correct)::numeric
             / nullif(count(*) filter (where abgabeart = 'antwort'), 0), 2
           ) as hit_rate
      from answered
     where cluster_id is not null
     group by cluster_id
    -- Ein Cluster, in dem nichts geprueft wurde, hat keine Quote und wird
    -- nicht als schwach vorgeschlagen. Der Coach sieht ihn ueber
    -- 'unbeantwortet' — geraten wird hier nicht.
    having count(*) filter (where abgabeart = 'antwort') > 0
       and count(*) filter (where correct)::numeric
           / count(*) filter (where abgabeart = 'antwort') < 0.6
  )
  select jsonb_build_object(
           -- 'answered' zaehlt ITEMS (Fortschritt gegen 'planned'),
           -- 'answered_parts' die Datenpunkte. Kein Score, keine Quote.
           'answered',       (select count(distinct task_id) from answered),
           'answered_parts', (select count(*) from answered),
           'planned',        array_length(v_session.item_ids, 1),
           -- Getrennt ausgewiesen, nicht verrechnet: das Kind hat abgegeben,
           -- nur nichts, was sich pruefen laesst.
           'unbeantwortet', jsonb_build_object(
             'weiss_nicht', (select count(*) from answered where abgabeart = 'weiss_nicht'),
             'leer',        (select count(*) from answered where abgabeart = 'leer')
           ),
           'competencies', coalesce((
             select jsonb_agg(jsonb_build_object(
                      'competency',      competency,
                      'total',           total,
                      'correct',         correct_count,
                      'unbeantwortet',   unbeantwortet,
                      'hit_rate',        hit_rate,
                      'avg_duration_ms', avg_duration_ms
                    ) order by hit_rate nulls first)
               from by_competency), '[]'::jsonb),
           'afb', coalesce((
             select jsonb_agg(jsonb_build_object(
                      'afb', afb, 'total', total, 'correct', correct_count,
                      'unbeantwortet', unbeantwortet
                    ) order by afb)
               from by_afb), '[]'::jsonb),
           'proposal', jsonb_build_object(
             'is_proposal', true,
             'applied',     false,
             'focus_cluster_ids', coalesce((
               select jsonb_agg(cluster_id order by hit_rate) from weak_clusters
             ), '[]'::jsonb),
             'clusters', coalesce((
               select jsonb_agg(jsonb_build_object(
                        'cluster_id', w.cluster_id,
                        'name',       c.name,
                        'hit_rate',   w.hit_rate
                      ) order by w.hit_rate)
                 from weak_clusters w
                 join skill_clusters c on c.id = w.cluster_id
             ), '[]'::jsonb),
             'note', 'Vorschlag. Der Lernpfad wird erst durch die Coach-Bestaetigung aktiv (lsa_confirm_focus).'
           )
         )
    into v_summary;

  update lsa_sessions
     set status         = 'completed',
         completed_at   = now(),
         result_summary = v_summary
   where id = p_session_id;

  return v_summary;
end;
$$;


--
-- Name: lsa_grade(text, jsonb, jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_grade(p_input_type text, p_acceptance jsonb, p_correct_answers jsonb, p_response jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
declare
  v_rule      jsonb;
  v_given     text;
  v_parts     text[];
  v_g_num     text;
  v_g_unit    text;
  v_cand      text;
  v_c_parts   text[];
  v_c_num     text;
  v_c_unit    text;
  v_req_unit  text;
  v_tol       jsonb;
  v_unit_grad boolean;
  v_reduced   boolean;
  v_hit       boolean := false;
  v_unit_ok   boolean := false;
begin
  -- MC: unveraendert binaer, ueber die bestehende Mengengleichheit.
  if p_input_type = 'MC' then
    return case
      when coalesce(public.lsa_is_correct(p_input_type, p_correct_answers, p_response), false)
      then 'voll' else 'nicht' end;
  end if;

  -- TERM: nie ueber den Wert-Einheit-Pfad. Ein acceptance an dieser Stelle ist
  -- ein Pflegefehler und wird laut — der Trigger verhindert ihn in den Daten,
  -- hier faellt auf, wenn ihn doch jemand von Hand hereinreicht.
  if p_input_type = 'TERM' then
    if jsonb_typeof(p_acceptance) = 'object' and p_acceptance ? 'canonical' then
      raise exception
        'LSA: TERM-Aufgabe mit acceptance.canonical — der Wert-Einheit-Pfad kann Terme nicht bewerten'
        using errcode = 'P0001';
    end if;
    return case
      when coalesce(public.lsa_is_correct(p_input_type, p_correct_answers, p_response), false)
      then 'voll' else 'nicht' end;
  end if;

  -- Eine Regel ist ein Objekt MIT canonical. Alles andere (NULL, '{}', die
  -- Teilaufgaben-Abbildung) heisst: hier ist nichts gepflegt.
  v_rule := case
    when jsonb_typeof(p_acceptance) = 'object' and p_acceptance ? 'canonical'
    then p_acceptance else null end;

  if v_rule is null then
    return case
      when coalesce(public.lsa_is_correct(p_input_type, p_correct_answers, p_response), false)
      then 'voll' else 'nicht' end;
  end if;

  begin
    v_given := coalesce(p_response ->> 'text', p_response ->> 'value');
    if v_given is null or btrim(v_given) = '' then
      return 'nicht';
    end if;

    v_parts     := public.lsa_split_value_unit(v_given);
    v_g_num     := btrim(v_parts[1]);
    v_g_unit    := btrim(v_parts[2]);
    v_tol       := v_rule -> 'tolerance';
    v_unit_grad := coalesce((v_rule ->> 'unit_graded')::boolean, false);
    v_reduced   := coalesce((v_rule ->> 'require_reduced')::boolean, false);

    -- Die geforderte Einheit: explizit gepflegt, sonst die der kanonischen Antwort.
    v_req_unit := btrim(coalesce(
      v_rule ->> 'unit',
      (public.lsa_split_value_unit(v_rule ->> 'canonical'))[2],
      ''));
    v_req_unit := lower(v_req_unit);

    -- Kandidaten: die kanonische Antwort und ihre Aequivalente. Reihenfolge
    -- zaehlt — der erste Treffer MIT passender Einheit gewinnt.
    for v_cand in
      select c from unnest(
        array[v_rule ->> 'canonical'] ||
        coalesce(
          (select array_agg(e #>> '{}')
             from jsonb_array_elements(
                    case when jsonb_typeof(v_rule -> 'equivalents') = 'array'
                         then v_rule -> 'equivalents' else '[]'::jsonb end) as e),
          '{}'::text[])
      ) as t(c)
    loop
      if v_cand is null or btrim(v_cand) = '' then
        continue;
      end if;

      v_c_parts := public.lsa_split_value_unit(v_cand);
      v_c_num   := btrim(v_c_parts[1]);
      v_c_unit  := lower(btrim(v_c_parts[2]));

      -- Ist die Einheit Teil der Kompetenz, zaehlen Aequivalente in ANDERER
      -- Einheit gar nicht mit (A10).
      if v_unit_grad and v_c_unit <> v_req_unit then
        continue;
      end if;

      if v_g_num <> '' and v_c_num <> ''
         and public.lsa_is_unit(v_g_unit) and public.lsa_is_unit(v_c_unit) then
        -- Zahlen: mathematisch vergleichen. NUR wenn der Rest auf beiden Seiten
        -- plausibel eine Einheit ist — sonst waere "5x+9" gegen "5x+4" ein
        -- Treffer auf der 5 (Befund 1).
        if not public.lsa_values_equal(v_g_num, v_c_num, v_tol) then
          continue;
        end if;
      else
        -- Wortantworten und alles, was keine Zahl-mit-Einheit ist: der
        -- normalisierte Vergleich, den lsa_is_correct auch fuehrt.
        if public.lsa_normalize_answer(v_given) is distinct from
           public.lsa_normalize_answer(v_cand) then
          continue;
        end if;
      end if;

      v_hit := true;
      -- Bei ungewerteter Einheit ist die Form der Einheit kein Kriterium.
      if not v_unit_grad or v_g_unit = v_c_unit then
        v_unit_ok := true;
        exit;
      end if;
    end loop;

    if not v_hit then
      return 'nicht';
    end if;

    -- Richtig gerechnet, Form verfehlt — die diagnostisch teure Zwischenstufe.
    if v_unit_grad and not v_unit_ok then
      return 'teilweise';
    end if;
    if v_reduced and not public.lsa_is_reduced(v_given) then
      return 'teilweise';
    end if;

    return 'voll';
  exception
    when others then
      -- Eine Auswertung darf an einer kaputten Regel nicht sterben. Im Zweifel
      -- wie vorher: die bestehende Bewertung entscheidet.
      return case
        when coalesce(public.lsa_is_correct(p_input_type, p_correct_answers, p_response), false)
        then 'voll' else 'nicht' end;
  end;
end;
$$;


--
-- Name: lsa_has_answers(text, jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_has_answers(p_input_type text, p_parts jsonb, p_correct_answers jsonb) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $$
  select case
    when p_input_type = 'MULTI_PART' then
      jsonb_typeof(p_correct_answers) = 'object'
      and jsonb_typeof(p_parts) = 'array'
      and jsonb_array_length(p_parts) > 0
      and not exists (
        select 1
          from jsonb_array_elements(p_parts) as e(p)
         where coalesce(jsonb_array_length(
                 case when jsonb_typeof(p_correct_answers -> (p ->> 'nr')) = 'array'
                      then p_correct_answers -> (p ->> 'nr') else '[]'::jsonb end
               ), 0) = 0
      )
    else
      jsonb_typeof(p_correct_answers) = 'array'
      and jsonb_array_length(p_correct_answers) > 0
  end
$$;


--
-- Name: lsa_hint(uuid, uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_hint(p_session_id uuid, p_task_id uuid, p_level integer DEFAULT 1) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_session lsa_sessions;
  v_hint    jsonb;
begin
  select * into v_session from lsa_sessions where id = p_session_id;
  if not found then
    raise exception 'LSA: Session nicht gefunden' using errcode = 'P0002';
  end if;
  if not public.lsa_may_act_for(v_session.student_id) then
    raise exception 'LSA: kein Zugriff auf diese Session' using errcode = '42501';
  end if;
  if not (p_task_id = any (v_session.item_ids)) then
    raise exception 'LSA: Item gehoert nicht zu dieser Session' using errcode = 'P0001';
  end if;

  select h
    into v_hint
    from task_solutions s,
         lateral jsonb_array_elements(s.hints) as e(h)
   where s.task_id = p_task_id
     and (h ->> 'level')::int = p_level
   limit 1;

  if v_hint is null then
    return jsonb_build_object('level', p_level, 'text', null, 'available', false);
  end if;

  return jsonb_build_object(
    'level',     p_level,
    'text',      v_hint ->> 'text',
    'available', true
  );
end;
$$;


--
-- Name: lsa_is_correct(text, jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_is_correct(p_input_type text, p_correct_answers jsonb, p_response jsonb) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
declare
  v_accepted text[];
  v_given    text[];
  v_answer   text;
  v_term     boolean := (p_input_type = 'TERM');
begin
  if p_correct_answers is null
     or jsonb_typeof(p_correct_answers) <> 'array'
     or jsonb_array_length(p_correct_answers) = 0 then
    return false;
  end if;

  select array_agg(case when v_term then public.lsa_normalize_term(x)
                        else public.lsa_normalize_answer(x) end)
    into v_accepted
    from jsonb_array_elements_text(p_correct_answers) as t(x);

  if p_input_type = 'MC' then
    -- StudentAnswer: { selected: string[] } (Option-Ids). Mengengleichheit.
    if p_response is null or jsonb_typeof(p_response -> 'selected') <> 'array' then
      return false;
    end if;
    select array_agg(public.lsa_normalize_answer(x))
      into v_given
      from jsonb_array_elements_text(p_response -> 'selected') as t(x);
    if v_given is null then
      return false;
    end if;
    return not exists (
      select 1 from unnest(v_accepted) a where a <> all (v_given)
    ) and not exists (
      select 1 from unnest(v_given) g where g <> all (v_accepted)
    );
  end if;

  -- short_input (SHORT_TEXT: {text}, NUMERIC: {value}, TERM: {text}).
  v_answer := coalesce(p_response ->> 'text', p_response ->> 'value');
  if v_answer is null then
    return false;
  end if;
  v_answer := case when v_term then public.lsa_normalize_term(v_answer)
                   else public.lsa_normalize_answer(v_answer) end;
  if v_answer = '' then
    return false;
  end if;
  return v_answer = any (v_accepted);
end;
$$;


--
-- Name: lsa_is_reduced(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_is_reduced(p_raw text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
declare
  v_val  text;
  v_frac text;
  v_num  numeric;
  v_den  numeric;
begin
  v_val := btrim(coalesce((public.lsa_split_value_unit(p_raw))[1], ''));
  if v_val = '' then return true; end if;
  if position('/' in v_val) = 0 then return true; end if;

  -- gemischt: der geschriebene Bruchteil ist der, der gekuerzt sein muss
  v_frac := case when v_val ~ '[[:space:]]' then split_part(v_val, ' ', 2) else v_val end;
  v_num  := abs(replace(split_part(v_frac, '/', 1), '-', '')::numeric);
  v_den  := split_part(v_frac, '/', 2)::numeric;
  if v_den = 0 then return true; end if;

  return gcd(v_num, v_den) = 1;
exception
  when others then
    -- Unlesbares wird nicht als "ungekuerzt" bestraft — die Wertgleichheit hat
    -- es dann ohnehin schon abgewiesen.
    return true;
end;
$$;


--
-- Name: lsa_is_unit(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_is_unit(p_rest text) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$
  select case
    -- Keine Einheit ist die haeufigste und unverdaechtigste Form.
    when p_rest is null or btrim(p_rest) = '' then true
    -- Rechenzeichen und Klammern kommen in keiner Einheit vor. Sie sind das
    -- sichere Kennzeichen eines Terms: "x+4", "x-4", "(x+2)".
    when p_rest ~ '[-+*=^()·]' then false
    -- Ziffern nur als Exponent am Ende: cm2, m3. Alles andere ist Rechnung.
    when p_rest ~ '[0-9]' and p_rest !~ '^[^0-9]*[23]$' then false
    -- Und es muss ueberhaupt etwas Einheitenartiges dastehen.
    else p_rest ~ '[a-zäöüß°%€]'
  end
$_$;


--
-- Name: lsa_may_act_for(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_may_act_for(p_student_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select public.get_my_role() in ('coach','admin')
      or public.get_my_student_id() = p_student_id
$$;


--
-- Name: lsa_mitbelegung(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_mitbelegung(p_session_id uuid, p_skill_key text) RETURNS void
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl)
  select p_session_id, a.skill_key, 'traegt', false, false, 0
    from public.lsa_abschluss(p_skill_key) a
  on conflict (session_id, skill_key) do nothing
$$;


--
-- Name: lsa_normalize_answer(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_normalize_answer(p_raw text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  select case
    when p_raw is null then null
    else lower(regexp_replace(regexp_replace(btrim(p_raw), '\s+', ' ', 'g'), ',', '.'))
  end
$$;


--
-- Name: lsa_normalize_term(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_normalize_term(p_raw text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  select case
    when p_raw is null then null
    else regexp_replace(public.lsa_normalize_answer(p_raw), '[[:space:]]', '', 'g')
  end
$$;


--
-- Name: lsa_option_scores_complete(text, jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_option_scores_complete(p_afb text, p_options jsonb, p_scale jsonb) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $$
  select case
    -- Nur AFB III kennt Abstufung. I/II bleibt binaer (correct_answers).
    when coalesce(p_afb, '') <> 'III' then true
    when not public.lsa_option_scores_scale_valid(p_scale) then false
    when jsonb_typeof(p_options) <> 'array' or jsonb_array_length(p_options) < 2
      then false
    else
      (select count(*) from jsonb_each_text(p_scale) as e(k, v) where v = 'voll') = 1
      and (select count(*) from jsonb_each_text(p_scale) as e(k, v)
            where v = 'teilweise') = 1
      -- jede Option ist bewertet …
      and not exists (
        select 1 from jsonb_array_elements(p_options) as o(opt)
         where not (p_scale ? (opt ->> 'id'))
      )
      -- … und die Skala kennt keine Option, die es nicht gibt
      and not exists (
        select 1 from jsonb_object_keys(p_scale) as k(id)
         where not exists (
           select 1 from jsonb_array_elements(p_options) as o(opt)
            where opt ->> 'id' = k.id
         )
      )
  end
$$;


--
-- Name: lsa_option_scores_scale_valid(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_option_scores_scale_valid(p_scale jsonb) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $$
  select jsonb_typeof(p_scale) = 'object'
     and not exists (
       select 1 from jsonb_each(p_scale) as e(k, v)
        where btrim(k) = ''
           or jsonb_typeof(v) <> 'string'
           or (v #>> '{}') not in ('voll', 'teilweise', 'nicht')
     )
     and (select count(*) from jsonb_each_text(p_scale) as e(k, v)
           where v = 'voll') <= 1
     and (select count(*) from jsonb_each_text(p_scale) as e(k, v)
           where v = 'teilweise') <= 1
$$;


--
-- Name: lsa_option_scores_valid(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_option_scores_valid(p_scores jsonb) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$
  select case
    when jsonb_typeof(p_scores) <> 'object' then false
    when p_scores = '{}'::jsonb then true
    when (select bool_and(jsonb_typeof(v) = 'object')
            from jsonb_each(p_scores) as e(k, v)) then
      not exists (
        select 1 from jsonb_each(p_scores) as e(k, v)
         where k !~ '^[1-9][0-9]*$'
            or not public.lsa_option_scores_scale_valid(v)
      )
    else public.lsa_option_scores_scale_valid(p_scores)
  end
$_$;


--
-- Name: lsa_parse_fraction(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_parse_fraction(p_raw text) RETURNS numeric[]
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
declare
  v_val   text;
  v_sign  numeric := 1;
  v_body  text;
  v_whole numeric;
  v_num   numeric;
  v_den   numeric;
  v_frac  text;
begin
  v_val := btrim(coalesce((public.lsa_split_value_unit(p_raw))[1], ''));
  if v_val = '' then
    return null;
  end if;

  if left(v_val, 1) = '-' then
    v_sign := -1;
    v_body := substr(v_val, 2);
  else
    v_body := v_val;
  end if;

  -- gemischter Bruch: "1 1/2"
  if v_body ~ '^[0-9]+[[:space:]]+[0-9]+/[0-9]+$' then
    v_whole := split_part(v_body, ' ', 1)::numeric;
    v_frac  := split_part(v_body, ' ', 2);
    v_num   := split_part(v_frac, '/', 1)::numeric;
    v_den   := split_part(v_frac, '/', 2)::numeric;
    if v_den = 0 then return null; end if;
    return array[v_sign * (v_whole * v_den + v_num), v_den];

  -- echter Bruch: "11/12"
  elsif v_body ~ '^[0-9]+/[0-9]+$' then
    v_num := split_part(v_body, '/', 1)::numeric;
    v_den := split_part(v_body, '/', 2)::numeric;
    if v_den = 0 then return null; end if;
    return array[v_sign * v_num, v_den];

  -- Dezimal: "0.75" → 75/100 (die Nachkommastellen bleiben als Nenner stehen,
  -- weil `require_reduced` spaeter nur Bruecke prueft, nie Dezimalzahlen)
  elsif v_body ~ '^[0-9]+\.[0-9]+$' then
    v_den := power(10::numeric, length(split_part(v_body, '.', 2)));
    v_num := (split_part(v_body, '.', 1) || split_part(v_body, '.', 2))::numeric;
    return array[v_sign * v_num, v_den];

  -- ganze Zahl
  elsif v_body ~ '^[0-9]+$' then
    return array[v_sign * v_body::numeric, 1];
  end if;

  return null;
exception
  when others then
    -- Ein Parser darf die Auswertung nicht abschiessen. Unlesbar = NULL.
    return null;
end;
$_$;


--
-- Name: lsa_part_answer(text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_part_answer(p_kind text, p_value jsonb) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
  select case
    when p_value is null or jsonb_typeof(p_value) = 'null' then null
    when p_kind = 'mc' then case jsonb_typeof(p_value)
      when 'object' then p_value                                     -- {"selected":[…]}
      when 'array'  then jsonb_build_object('selected', p_value)     -- ["b"]
      else jsonb_build_object('selected', jsonb_build_array(p_value #>> '{}'))  -- "b"
    end
    else case jsonb_typeof(p_value)
      when 'object' then p_value                                     -- {"text":…}/{"value":…}
      else jsonb_build_object('text', p_value #>> '{}')              -- "20" / 20
    end
  end
$$;


--
-- Name: lsa_parts_valid(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_parts_valid(p_parts jsonb) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$
  select jsonb_typeof(p_parts) = 'array'
     and jsonb_array_length(p_parts) >= 2
     and not exists (
       select 1
         from jsonb_array_elements(p_parts) as e(p)
        where coalesce(p ->> 'nr', '') !~ '^[1-9][0-9]*$'
           or coalesce(p ->> 'kind', '') not in ('short_input', 'mc')
           or coalesce(btrim(p ->> 'prompt'), '') = ''
           or (p ->> 'kind' = 'mc' and coalesce(jsonb_array_length(
                case when jsonb_typeof(p -> 'options') = 'array'
                     then p -> 'options' else '[]'::jsonb end), 0) < 2)
              -- F01: eine Teilaufgabe darf eine eigene Tabelle tragen — aber nur
              -- eine wohlgeformte.
           or (p ? 'table' and not public.lsa_table_valid(p -> 'table'))
           or p ?| array['correct', 'accepted', 'solution', 'correct_answers',
                         'hints', 'coach_hints', 'typical_errors']
     )
     and (select count(distinct (p ->> 'nr')) from jsonb_array_elements(p_parts) as e(p))
         = jsonb_array_length(p_parts)
$_$;


--
-- Name: lsa_public_assets(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_public_assets(p_assets jsonb) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
  select coalesce((
    select jsonb_agg(
             jsonb_strip_nulls(jsonb_build_object('url', a ->> 'url', 'alt', a ->> 'alt'))
             order by ord
           )
      from jsonb_array_elements(
             case when jsonb_typeof(p_assets) = 'array' then p_assets else '[]'::jsonb end
           ) with ordinality as e(a, ord)
     where a ->> 'url' is not null
  ), '[]'::jsonb)
$$;


--
-- Name: lsa_public_parts(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_public_parts(p_parts jsonb) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
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
$$;


--
-- Name: lsa_public_table(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_public_table(p_table jsonb) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
  select case
    -- p_table IS NULL zuerst und explizit: jsonb_typeof(null) ist NULL, nicht
    -- 'null' — jedes WHEN waere damit unbekannt, und die CASE fiele in den
    -- ELSE-Zweig. Heraus kaeme ein leeres {"headers":[],"rows":[]} an JEDEM
    -- tabellenlosen Item; jsonb_strip_nulls raeumt das nicht mehr weg, weil es
    -- kein NULL mehr ist. Genau daran ist inv5 zuerst gescheitert.
    when p_table is null                                then null
    when jsonb_typeof(p_table) <> 'object'              then null
    when jsonb_typeof(p_table -> 'headers') <> 'array'  then null
    when jsonb_typeof(p_table -> 'rows')    <> 'array'  then null
    else jsonb_build_object(
      'headers', coalesce((
        select jsonb_agg(h #>> '{}' order by ord)
          from jsonb_array_elements(p_table -> 'headers') with ordinality as e(h, ord)
      ), '[]'::jsonb),
      'rows', coalesce((
        select jsonb_agg(
                 coalesce((
                   select jsonb_agg(c #>> '{}' order by cord)
                     from jsonb_array_elements(
                            case when jsonb_typeof(r) = 'array' then r else '[]'::jsonb end
                          ) with ordinality as ce(c, cord)
                 ), '[]'::jsonb)
                 order by rord
               )
          from jsonb_array_elements(p_table -> 'rows') with ordinality as re(r, rord)
      ), '[]'::jsonb)
    )
  end
$$;


--
-- Name: lsa_question_payload(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_question_payload(p_task_id uuid) RETURNS jsonb
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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
$$;


--
-- Name: lsa_select_next(uuid, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_select_next(p_session_id uuid, p_status_filter text[] DEFAULT ARRAY['ready'::text]) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare v_student uuid;
begin
  select student_id into v_student from lsa_sessions where id = p_session_id;
  if v_student is null then
    raise exception 'LSA: Session nicht gefunden' using errcode = 'P0002';
  end if;
  if not public.lsa_may_act_for(v_student) then
    raise exception 'LSA: kein Zugriff auf diese Session' using errcode = '42501';
  end if;
  return public.lsa_select_next_core(p_session_id, p_status_filter, now());
end;
$$;


--
-- Name: lsa_select_next_core(uuid, text[], timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_select_next_core(p_session_id uuid, p_status_filter text[] DEFAULT ARRAY['ready'::text], p_jetzt timestamp with time zone DEFAULT now()) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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


--
-- Name: lsa_session_lead_fertig(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_session_lead_fertig() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  update leads l
     set status = 'lsa_fertig'
    from students s
   where s.id = new.student_id
     and s.is_provisional
     and l.id = s.lead_id
     and l.status = 'lsa_freigegeben';
  return new;
end;
$$;


--
-- Name: lsa_session_platz_release(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_session_platz_release() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  update platz_assignments
     set released_at = now()
   where session_id = new.id
     and released_at is null;
  return new;
end;
$$;


--
-- Name: lsa_split_value_unit(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_split_value_unit(p_raw text) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $_$
  -- Ein Muster, zweimal verwendet: einmal faengt es die Zahl, einmal ueberspringt
  -- es sie. Die inneren Gruppen sind bewusst nicht-fangend, damit `substring`
  -- die gemeinte Gruppe liefert.
  select case
    when p_raw is null then null
    else array[
      coalesce(
        substring(public.lsa_normalize_answer(p_raw)
                  from '^(-?[0-9]+(?:[[:space:]]+[0-9]+/[0-9]+|/[0-9]+|\.[0-9]+)?)'),
        ''),
      btrim(coalesce(
        substring(public.lsa_normalize_answer(p_raw)
                  from '^-?[0-9]+(?:[[:space:]]+[0-9]+/[0-9]+|/[0-9]+|\.[0-9]+)?[[:space:]]*(.*)$'),
        public.lsa_normalize_answer(p_raw)))
    ]
  end
$_$;


--
-- Name: lsa_start(uuid, integer, text, text, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_start(p_student_id uuid, p_grade integer, p_subject text, p_modus text DEFAULT 'adaptiv'::text, p_jetzt timestamp with time zone DEFAULT now()) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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


--
-- Name: lsa_storage_base(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_storage_base() RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  select 'https://ztcppihxqcphlqaguhma.supabase.co/storage/v1/object/public/task-assets/'
$$;


--
-- Name: lsa_submit(uuid, uuid, jsonb, integer, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_submit(p_session_id uuid, p_task_id uuid, p_response jsonb, p_duration_ms integer DEFAULT NULL::integer, p_jetzt timestamp with time zone DEFAULT now()) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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


--
-- Name: lsa_table_valid(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_table_valid(p_table jsonb) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $$
  select jsonb_typeof(p_table) = 'object'
     and jsonb_typeof(p_table -> 'headers') = 'array'
     and jsonb_array_length(p_table -> 'headers') >= 1
     and jsonb_typeof(p_table -> 'rows') = 'array'
     and jsonb_array_length(p_table -> 'rows') >= 1
     -- Header: nicht-leere Strings
     and not exists (
       select 1
         from jsonb_array_elements(p_table -> 'headers') as e(h)
        where jsonb_typeof(h) <> 'string' or btrim(h #>> '{}') = ''
     )
     -- Zeilen: Array von Strings, Breite == Header-Breite
     and not exists (
       select 1
         from jsonb_array_elements(p_table -> 'rows') as e(r)
        where jsonb_typeof(r) <> 'array'
           or jsonb_array_length(r) <> jsonb_array_length(p_table -> 'headers')
           or exists (
                select 1
                  from jsonb_array_elements(r) as c(cell)
                 where jsonb_typeof(cell) <> 'string'
              )
     )
     -- Die Loesung hat auch hier nichts zu suchen.
     and not p_table ?| array['correct', 'accepted', 'solution', 'correct_answers',
                              'hints', 'coach_hints', 'typical_errors']
$$;


--
-- Name: lsa_task_assets(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_task_assets(p_task_id uuid) RETURNS jsonb
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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
$$;


--
-- Name: lsa_term_acceptance_guard(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_term_acceptance_guard() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  v_input_type text;
begin
  if tg_table_name = 'task_solutions' then
    if new.acceptance is null then
      return new;
    end if;
    select t.input_type into v_input_type from public.tasks t where t.id = new.task_id;
    if v_input_type = 'TERM' then
      raise exception
        'LSA: TERM-Aufgabe % darf kein acceptance tragen — der Wert-Einheit-Pfad kann Terme nicht bewerten',
        new.task_id using errcode = '23514';
    end if;
    return new;
  end if;

  -- tasks: auf TERM umstellen, waehrend eine Loesung ein acceptance traegt
  if exists (select 1 from public.task_solutions s
              where s.task_id = new.id and s.acceptance is not null) then
    raise exception
      'LSA: Aufgabe % kann nicht auf TERM gestellt werden, die Loesung traegt ein acceptance',
      new.id using errcode = '23514';
  end if;
  return new;
end;
$$;


--
-- Name: lsa_uebernahme(uuid, uuid, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_uebernahme(p_session_id uuid, p_student_id uuid, p_jetzt timestamp with time zone DEFAULT now()) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_session lsa_sessions;
  v_lead_id uuid;
  v_n       int;
begin
  if public.get_my_role() not in ('coach','admin') then
    raise exception 'lsa_uebernahme: nur Coach/Admin' using errcode = '42501';
  end if;

  select * into v_session from lsa_sessions where id = p_session_id;
  if not found then
    raise exception 'lsa_uebernahme: Session nicht gefunden' using errcode = 'P0002';
  end if;

  -- Frage 1 = JA: die Sitzung haengt am (spaeter echten) Schueler. Der
  -- uebergebene Schueler MUSS dieser sein. Nie "die neueste Sitzung" raten.
  if v_session.student_id <> p_student_id then
    raise exception 'lsa_uebernahme: Sitzung gehoert zu Schueler %, nicht %',
      v_session.student_id, p_student_id using errcode = 'P0001';
  end if;
  -- Konfliktsperre: eine Sitzung gehoert zu genau einem Schueler.
  if v_session.uebernommen_zu_student_id is not null
     and v_session.uebernommen_zu_student_id <> p_student_id then
    raise exception 'lsa_uebernahme: Sitzung bereits an Schueler % uebernommen',
      v_session.uebernommen_zu_student_id using errcode = 'P0001';
  end if;

  -- Fokus-Vorschlaege NUR aus den Luecken. 'traegt' bestaetigt, 'ungeprueft'
  -- gehoert in den Report, nicht in den Pfad. belegt_direkt wandert mit.
  -- ON CONFLICT DO NOTHING: idempotent, und ein bereits bestaetigter/
  -- verworfener Eintrag wird nie ueberschrieben (der Konflikt trifft dieselbe
  -- (student, skill, herkunft) und laesst die Coach-Entscheidung stehen).
  insert into student_focus_areas
    (student_id, cluster_id, skill_key, herkunfts_session_id, zustand,
     belegt_direkt, status, active, source)
  select p_student_id, null, u.skill_key, p_session_id, u.zustand,
         u.belegt_direkt, 'vorgeschlagen', false, 'lsa'
    from lsa_skill_urteil u
   where u.session_id = p_session_id
     and u.zustand in ('traegt_nicht','nicht_angesetzt','traegt_teilweise')
  on conflict (student_id, skill_key, herkunfts_session_id)
    where skill_key is not null
    do nothing;
  get diagnostics v_n = row_count;

  -- Sitzungs-Spur.
  update lsa_sessions
     set uebernommen_zu_student_id = p_student_id,
         uebernommen_am = coalesce(uebernommen_am, p_jetzt)
   where id = p_session_id;

  -- Lead-Spur (Frage 2: am Lead, nicht am Platz). Vor der Konversion ueber
  -- students.lead_id, danach ueber converted_student_id.
  select id into v_lead_id from leads
   where converted_student_id = p_student_id
      or id = (select lead_id from students where id = p_student_id)
   limit 1;
  if v_lead_id is not null then
    update leads set konvertiert_am = coalesce(konvertiert_am, p_jetzt)
     where id = v_lead_id;
  end if;

  return jsonb_build_object('ok', true, 'student_id', p_student_id, 'fokus_erzeugt', v_n);
end;
$$;


--
-- Name: lsa_urteil_aufloesung(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_urteil_aufloesung(a text, b text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  select case a
    when 'mc_ja' then case b
      when 'voll' then 'traegt'                 -- MC-ja bestaetigt durch freie Eingabe
      else 'traegt_teilweise' end               -- MC-ja, aber frei falsch/leer -> teilweise
    when 'nicht' then case b
      when 'voll' then 'traegt_teilweise'       -- Vorlage: nicht + voll
      else 'traegt_nicht' end                   -- Vorlage: nicht + nicht; Fuellung: nicht + weiss_nicht
    when 'weiss_nicht' then case b
      when 'voll' then 'traegt_teilweise'       -- Vorlage: weiss_nicht + voll
      when 'weiss_nicht' then 'nicht_angesetzt' -- Vorlage: weiss_nicht + weiss_nicht
      else 'traegt_nicht' end                   -- Fuellung: weiss_nicht + nicht (hat angesetzt, falsch)
    else 'traegt_nicht'
  end
$$;


--
-- Name: lsa_urteil_buchen(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_urteil_buchen(p_session_id uuid, p_task_id uuid) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare v_student uuid;
begin
  select student_id into v_student from lsa_sessions where id = p_session_id;
  if v_student is null then
    raise exception 'LSA: Session nicht gefunden' using errcode = 'P0002';
  end if;
  if not public.lsa_may_act_for(v_student) then
    raise exception 'LSA: kein Zugriff auf diese Session' using errcode = '42501';
  end if;
  return public.lsa_urteil_buchen_core(p_session_id, p_task_id);
end;
$$;


--
-- Name: lsa_urteil_buchen_core(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_urteil_buchen_core(p_session_id uuid, p_task_id uuid) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_task    tasks;
  v_resp    lsa_responses;
  v_sk      text;
  v_is_mc   boolean;
  v_res     text;   -- voll | teilweise | nicht | weiss_nicht | leer
  v_row     lsa_skill_urteil;
  v_prov    text;
  v_a       text;
  v_b       text;
  v_final   text;
  -- AF7, nur fuer den Multi-Part-Zweig
  v_teile   integer;
  v_zeilen  integer;
  v_falsch  integer;
  v_richtig integer;
  v_wn      integer;
begin
  select * into v_task from tasks where id = p_task_id;
  v_sk := v_task.skill_key;
  if v_sk is null then
    return null;  -- Nicht-Fundament-Aufgabe: kein Skill-Urteil.
  end if;

  if v_task.input_type = 'MULTI_PART' then
    -- ── AF7: Urteil aus den Teilzeilen ────────────────────────────────────
    --
    -- Gezaehlt wird ueber ALLE Teile der Aufgabe, nicht ueber die gefundenen
    -- Zeilen: nur so faellt auf, wenn eine Teilzeile fehlt.
    select jsonb_array_length(v_task.parts) into v_teile;

    select count(*),
           count(*) filter (where r.abgabeart = 'antwort' and r.correct is false),
           count(*) filter (where r.abgabeart = 'antwort' and r.correct is true),
           count(*) filter (where r.abgabeart = 'weiss_nicht')
      into v_zeilen, v_falsch, v_richtig, v_wn
      from lsa_responses r
     where r.session_id = p_session_id and r.task_id = p_task_id
       and r.part_nr is not null;

    if v_zeilen = 0 then
      return null;  -- ohne Antwort kein Urteil (wie im flachen Pfad).
    end if;

    -- UNVOLLSTAENDIG ERFASST: weniger Zeilen als Teile.
    -- lsa_submit legt normalerweise JE Teil eine Zeile an, auch fuer leere und
    -- fuer "weiss nicht" — dieser Fall entsteht also nur durch eine Reparatur
    -- von Hand oder einen kuenftigen Submit-Pfad. Dann gibt es KEIN Urteil:
    -- die Verdichtungsregel fragt "sind ALLE Teile richtig", und diese Frage
    -- ist bei unbekanntem Nenner nicht beantwortbar. Lieber kein Beleg als ein
    -- Beleg auf halber Grundlage — dieselbe Haltung wie beim `return null`
    -- oben, wenn gar keine Antwort vorliegt.
    if v_zeilen < v_teile then
      return null;
    end if;

    v_res := case
      -- Ein falscher Teil genuegt. Das ist die Verdichtungsregel, und sie steht
      -- VOR allem anderen: ein belegter Fehler wiegt schwerer als eine
      -- ausgelassene Teilaufgabe daneben.
      when v_falsch > 0 then 'nicht'
      -- Kein Fehler und alle Teile beantwortet -> alle richtig.
      when v_richtig = v_teile then 'voll'
      -- Kein Fehler, aber nicht alle beantwortet: kein Beleg, kein Negativbeleg.
      -- Beide Werte fliessen ohnehin gleich weiter (nicht_angesetzt bzw.
      -- v_b = 'weiss_nicht'); unterschieden wird nur, was naeher an der Wahrheit
      -- ist — hat das Kind "weiss nicht" gedrueckt oder das Feld leer gelassen.
      when v_wn > 0 then 'weiss_nicht'
      else 'leer'
    end;

    -- v_is_mc steuert unten NUR die Abkuerzung in Probe 1: bei MC wird ein
    -- 'voll' nicht sofort final, weil eine einzelne MC-Antwort geraten sein
    -- kann. Genau diese Begruendung traegt bei Multi-Part nur, wenn ALLE Teile
    -- MC sind. Sobald ein Teil eine freie Eingabe ist, ist das Gesamtergebnis
    -- nicht mehr ratbar — ein 'voll' heisst dann, dass das Kind modelliert UND
    -- gerechnet hat, und das ist mindestens so tragfaehig wie ein 'voll' auf
    -- einem flachen NUMERIC-Item.
    select not exists (
             select 1 from jsonb_array_elements(v_task.parts) as e(p)
              where coalesce(p ->> 'kind', '') <> 'mc')
      into v_is_mc;
  else
    -- ── Flacher Pfad, unveraendert ────────────────────────────────────────
    -- Die flache Antwortzeile dieser Aufgabe.
    select * into v_resp
      from lsa_responses
     where session_id = p_session_id and task_id = p_task_id and part_nr is null
     order by created_at desc limit 1;
    if not found then
      return null;  -- ohne Antwort kein Urteil.
    end if;

    v_is_mc := (v_task.input_type = 'MC');

    -- Regel 6: Ergebnis aus abgabeart ableiten.
    if v_resp.abgabeart = 'weiss_nicht' then
      v_res := 'weiss_nicht';
    elsif v_resp.abgabeart = 'leer' then
      v_res := 'leer';
    elsif v_is_mc then
      v_res := case when coalesce(v_resp.correct, false) then 'voll' else 'nicht' end;
    else
      -- NUMERIC/TERM: die dreistufige Bewertung.
      select public.lsa_grade(v_task.input_type, s.acceptance, s.correct_answers, v_resp.response)
        into v_res
        from task_solutions s where s.task_id = p_task_id;
      v_res := coalesce(v_res, 'nicht');
    end if;
  end if;

  select * into v_row from lsa_skill_urteil
   where session_id = p_session_id and skill_key = v_sk;

  -- Vorhandenes FINALES Urteil wird nie ueberschrieben.
  if found and not v_row.offen then
    return v_row.zustand;
  end if;

  if not found then
    -- PROBE 1
    if not v_is_mc and v_res = 'voll' then
      insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl)
        values (p_session_id, v_sk, 'traegt', true, false, 1);
      perform public.lsa_mitbelegung(p_session_id, v_sk);
      return 'traegt';
    end if;
    -- Zweitprobe faellig -> provisorisch schreiben. Der provisorische Zustand
    -- kodiert die erste Probe: traegt=mc_ja, traegt_nicht=nicht, nicht_angesetzt=weiss_nicht.
    v_prov := case
      when v_res = 'voll' then 'traegt'                         -- nur MC richtig
      when v_res in ('nicht','teilweise') then 'traegt_nicht'
      else 'nicht_angesetzt' end;                               -- weiss_nicht/leer
    insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl)
      values (p_session_id, v_sk, v_prov, true, true, 1);
    return v_prov;
  else
    -- PROBE 2 (offen=true)
    v_a := case v_row.zustand
             when 'traegt' then 'mc_ja'
             when 'traegt_nicht' then 'nicht'
             else 'weiss_nicht' end;               -- nicht_angesetzt
    v_b := case
             when v_res = 'voll' then 'voll'
             when v_res in ('weiss_nicht','leer') then 'weiss_nicht'
             else 'nicht' end;                     -- nicht/teilweise
    v_final := public.lsa_urteil_aufloesung(v_a, v_b);
    update lsa_skill_urteil
       set zustand = v_final, proben_anzahl = 2, offen = false, aktualisiert = now()
     where session_id = p_session_id and skill_key = v_sk;
    if v_final = 'traegt' then
      perform public.lsa_mitbelegung(p_session_id, v_sk);
    end if;
    return v_final;
  end if;
end;
$$;


--
-- Name: lsa_values_equal(text, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_values_equal(p_a text, p_b text, p_tolerance jsonb DEFAULT NULL::jsonb) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
declare
  v_a    numeric[];
  v_b    numeric[];
  v_mode text;
  v_val  numeric;
begin
  v_a := public.lsa_parse_fraction(p_a);
  v_b := public.lsa_parse_fraction(p_b);
  if v_a is null or v_b is null then
    return false;
  end if;

  v_mode := coalesce(p_tolerance ->> 'mode', 'exact');

  if v_mode = 'exact' then
    -- Kreuzprodukt statt Division: keine Rundung, kein Genauigkeitsverlust.
    return v_a[1] * v_b[2] = v_b[1] * v_a[2];
  end if;

  v_val := (p_tolerance ->> 'value')::numeric;
  if v_val is null then
    return v_a[1] * v_b[2] = v_b[1] * v_a[2];
  end if;

  if v_mode = 'absolute' then
    return abs(v_a[1] / v_a[2] - v_b[1] / v_b[2]) <= v_val;
  elsif v_mode = 'decimals' then
    return round(v_a[1] / v_a[2], v_val::int) = round(v_b[1] / v_b[2], v_val::int);
  end if;

  return v_a[1] * v_b[2] = v_b[1] * v_a[2];
exception
  when others then
    return false;
end;
$$;


--
-- Name: lsa_ziffernfolge(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_ziffernfolge(p_text text) RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $$
  select coalesce(
    array(select m[1] from regexp_matches(coalesce(p_text, ''), '\d+', 'g') as m),
    '{}'::text[])
$$;


--
-- Name: mastery_stage(numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.mastery_stage(score numeric) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  select case
    when score >= 85 then 'mastered'
    when score >= 75 then 'proficient'
    when score >= 60 then 'progressing'
    when score >= 40 then 'developing'
    else 'introduced'
  end
$$;


--
-- Name: mastery_stage_from_level(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.mastery_stage_from_level(lvl integer) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  select public.mastery_stage(lvl * 10.0)
$$;


--
-- Name: platz_assign(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.platz_assign(p_platz_profile_id uuid, p_session_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_session lsa_sessions;
  v_id      uuid;
  v_expires timestamptz;
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'platz_assign: nur Admin' using errcode = '42501';
  end if;

  if not exists (select 1 from platz_devices where profile_id = p_platz_profile_id) then
    raise exception 'platz_assign: kein Platz-Konto (platz_devices)'
      using errcode = 'P0002';
  end if;

  select * into v_session from lsa_sessions where id = p_session_id;
  if not found then
    raise exception 'platz_assign: Session nicht gefunden' using errcode = 'P0002';
  end if;
  if v_session.status <> 'in_progress' then
    raise exception 'platz_assign: Session ist nicht in Durchfuehrung (status=%)',
      v_session.status using errcode = 'P0001';
  end if;

  -- Aktive Zuweisung → verweigern (bewusste Entscheidung am Empfang noetig).
  if exists (
    select 1 from platz_assignments
     where platz_profile_id = p_platz_profile_id
       and released_at is null
       and expires_at > now()
  ) then
    raise exception 'platz_assign: Platz hat bereits eine aktive Zuweisung'
      using errcode = 'P0001';
  end if;

  -- Abgelaufene, nie freigegebene Zeile aufraeumen — sonst blockierte der
  -- Partial-Unique-Index den Platz dauerhaft (siehe Kommentar am Index).
  update platz_assignments
     set released_at = now()
   where platz_profile_id = p_platz_profile_id
     and released_at is null;

  insert into platz_assignments (platz_profile_id, session_id, created_by)
  values (p_platz_profile_id, p_session_id, auth.uid())
  returning id, expires_at into v_id, v_expires;

  return jsonb_build_object('ok', true, 'assignment_id', v_id, 'expires_at', v_expires);
end;
$$;


--
-- Name: platz_avatar_set(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.platz_avatar_set(p_avatar text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_a       platz_assignments;
  v_session lsa_sessions;
  v_avatar  text;
begin
  if not exists (select 1 from platz_devices where profile_id = auth.uid()) then
    raise exception 'platz_avatar_set: kein Platz-Konto' using errcode = '42501';
  end if;

  v_a := public.platz_current_assignment();
  if v_a.id is null then
    raise exception 'platz_avatar_set: keine aktive Zuweisung' using errcode = '42501';
  end if;

  select * into v_session from lsa_sessions where id = v_a.session_id;
  if not found or v_session.status <> 'in_progress' then
    raise exception 'platz_avatar_set: keine aktive Session' using errcode = '42501';
  end if;

  -- Form pruefen, bevor der CHECK es tut — so bekommt der Kiosk einen
  -- sprechenden P0001 statt eines 23514 aus der Tiefe.
  v_avatar := btrim(coalesce(p_avatar, ''));
  if v_avatar = '' or length(v_avatar) > 40 then
    raise exception 'platz_avatar_set: ungueltiger Avatar-Schluessel'
      using errcode = 'P0001';
  end if;

  update lsa_sessions
     set avatar_choice = v_avatar
   where id = v_session.id;

  -- Wie platz_finish: exakt {ok:true}. Der Platz bekommt nichts zurueck, was
  -- er nicht selbst geschickt hat.
  return jsonb_build_object('ok', true);
end;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: platz_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.platz_assignments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    platz_profile_id uuid NOT NULL,
    session_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid NOT NULL,
    expires_at timestamp with time zone DEFAULT (now() + '02:00:00'::interval) NOT NULL,
    released_at timestamp with time zone
);


--
-- Name: platz_current_assignment(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.platz_current_assignment() RETURNS public.platz_assignments
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select a.*
    from platz_assignments a
   where a.platz_profile_id = auth.uid()
     and a.released_at is null
     and a.expires_at > now()
   limit 1
$$;


--
-- Name: platz_finish(timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.platz_finish(p_jetzt timestamp with time zone DEFAULT now()) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_a       platz_assignments;
  v_session lsa_sessions;
  v_claims  text;
begin
  if not exists (select 1 from platz_devices where profile_id = auth.uid()) then
    raise exception 'platz_finish: kein Platz-Konto' using errcode = '42501';
  end if;

  v_a := public.platz_current_assignment();
  if v_a.id is null then
    raise exception 'platz_finish: keine aktive Zuweisung' using errcode = '42501';
  end if;

  select * into v_session from lsa_sessions where id = v_a.session_id;
  if not found or v_session.status <> 'in_progress' then
    raise exception 'platz_finish: keine aktive Session' using errcode = '42501';
  end if;

  v_claims := current_setting('request.jwt.claims', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_a.created_by, 'role', 'authenticated')::text, true);

  perform public.lsa_finish(v_session.id);   -- zeitunabhaengig; p_jetzt nicht benoetigt

  perform set_config('request.jwt.claims', coalesce(v_claims, ''), true);

  return jsonb_build_object('ok', true);
end;
$$;


--
-- Name: platz_next(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.platz_next() RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_a       platz_assignments;
  v_session lsa_sessions;
  v_next    uuid;
begin
  if not exists (select 1 from platz_devices where profile_id = auth.uid()) then
    raise exception 'platz_next: kein Platz-Konto' using errcode = '42501';
  end if;

  v_a := public.platz_current_assignment();
  if v_a.id is null then
    raise exception 'platz_next: keine aktive Zuweisung' using errcode = '42501';
  end if;

  select * into v_session from lsa_sessions where id = v_a.session_id;
  if not found or v_session.status <> 'in_progress' then
    raise exception 'platz_next: keine aktive Session' using errcode = '42501';
  end if;

  if v_session.modus = 'adaptiv' then
    -- Die aktuell ausgegebene, noch unbeantwortete Aufgabe. Es gibt hoechstens
    -- eine. NICHTS wird hier gezogen oder eingetragen — das taten lsa_start
    -- (erste) bzw. lsa_submit (jede weitere). Keine zweite Wahrheit.
    select a.task_id into v_next
      from lsa_ausgegeben a
     where a.session_id = v_session.id
       and not exists (select 1 from lsa_responses r
                        where r.session_id = v_session.id and r.task_id = a.task_id)
     order by a.ausgegeben_am
     limit 1;
  else
    select i.id into v_next
      from unnest(v_session.item_ids) with ordinality as i(id, ord)
     where not exists (select 1 from lsa_responses r
                        where r.session_id = v_session.id and r.task_id = i.id)
     order by i.ord
     limit 1;
  end if;

  if v_next is null then
    return jsonb_build_object('item', null, 'done', true);
  end if;

  return jsonb_build_object('item', public.lsa_question_payload(v_next), 'done', false);
end;
$$;


--
-- Name: platz_release(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.platz_release(p_assignment_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_count integer;
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'platz_release: nur Admin' using errcode = '42501';
  end if;

  update platz_assignments
     set released_at = now()
   where id = p_assignment_id
     and released_at is null;
  get diagnostics v_count = row_count;

  if v_count = 0 and not exists (
    select 1 from platz_assignments where id = p_assignment_id
  ) then
    raise exception 'platz_release: Zuweisung nicht gefunden' using errcode = 'P0002';
  end if;

  -- Bereits freigegeben → idempotent (released=false meldet das ehrlich).
  return jsonb_build_object('ok', true, 'released', v_count = 1);
end;
$$;


--
-- Name: platz_state(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.platz_state() RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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
      'expires_at', v_a.expires_at
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
    'expires_at', v_a.expires_at
  );
end;
$$;


--
-- Name: platz_submit(uuid, jsonb, integer, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.platz_submit(p_task_id uuid, p_response jsonb, p_duration_ms integer DEFAULT NULL::integer, p_jetzt timestamp with time zone DEFAULT now()) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_a       platz_assignments;
  v_session lsa_sessions;
  v_open    uuid;
  v_claims  text;
  v_result  jsonb;
begin
  if not exists (select 1 from platz_devices where profile_id = auth.uid()) then
    raise exception 'platz_submit: kein Platz-Konto' using errcode = '42501';
  end if;

  v_a := public.platz_current_assignment();
  if v_a.id is null then
    raise exception 'platz_submit: keine aktive Zuweisung' using errcode = '42501';
  end if;

  select * into v_session from lsa_sessions where id = v_a.session_id;
  if not found or v_session.status <> 'in_progress' then
    raise exception 'platz_submit: keine aktive Session' using errcode = '42501';
  end if;

  -- Aktuell offenes Item — Quelle je nach Modus.
  if v_session.modus = 'adaptiv' then
    select a.task_id into v_open
      from lsa_ausgegeben a
     where a.session_id = v_session.id
       and not exists (select 1 from lsa_responses r
                        where r.session_id = v_session.id and r.task_id = a.task_id)
     order by a.ausgegeben_am
     limit 1;
  else
    select i.id into v_open
      from unnest(v_session.item_ids) with ordinality as i(id, ord)
     where not exists (select 1 from lsa_responses r
                        where r.session_id = v_session.id and r.task_id = i.id)
     order by i.ord
     limit 1;
  end if;

  if v_open is null or v_open <> p_task_id then
    raise exception 'platz_submit: nicht das aktuell offene Item' using errcode = 'P0001';
  end if;

  -- Durchreichen an die UNVERAENDERTE lsa_submit mit der Auftrags-Identitaet.
  -- lsa_submit verzweigt intern nach modus (A16): adaptiv gated ueber
  -- lsa_ausgegeben, schreibt die Antwort, bucht das Urteil und traegt die
  -- naechste Aufgabe selbst ein. p_jetzt steuert das Zeit-Ende in
  -- lsa_select_next.
  v_claims := current_setting('request.jwt.claims', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_a.created_by, 'role', 'authenticated')::text, true);

  v_result := public.lsa_submit(v_session.id, p_task_id, p_response, p_duration_ms, p_jetzt);

  perform set_config('request.jwt.claims', coalesce(v_claims, ''), true);

  return v_result;   -- {ok, next} — kein correct, kein Score, kein Zaehler.
end;
$$;


--
-- Name: skill_kante_tiefe_guard(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.skill_kante_tiefe_guard() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  v_tiefe_skill      int;
  v_tiefe_voraussetzt int;
begin
  select fundament_tiefe into v_tiefe_skill
    from public.skills where skill_key = new.skill_key;
  select fundament_tiefe into v_tiefe_voraussetzt
    from public.skills where skill_key = new.voraussetzt_skill_key;

  if v_tiefe_voraussetzt >= v_tiefe_skill then
    raise exception
      'skill_kante: % (Tiefe %) setzt % (Tiefe %) voraus — eine Voraussetzung muss ECHT flacher liegen',
      new.skill_key, v_tiefe_skill, new.voraussetzt_skill_key, v_tiefe_voraussetzt
      using errcode = '23514';
  end if;
  return null;
end;
$$;


--
-- Name: slot_assign(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.slot_assign(p_slot_id uuid, p_lead_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_slot   slots;
  v_belegt integer;
  v_id     uuid;
begin
  if public.get_my_role() not in ('coach','admin') then
    raise exception 'slot_assign: nur Coach oder Admin' using errcode = '42501';
  end if;

  if not exists (select 1 from leads where id = p_lead_id) then
    raise exception 'slot_assign: Lead nicht gefunden' using errcode = 'P0002';
  end if;

  -- DER LOCK (Header „Kapazitaets-Garantie"): sperrt die Slot-Zeile fuer die
  -- Dauer der Transaktion. Erst DANACH wird gezaehlt — eine zweite gleichzeitige
  -- Zuweisung in denselben Slot wartet hier und sieht den Stand nach uns.
  select * into v_slot from slots where id = p_slot_id for update;
  if not found then
    raise exception 'slot_assign: Slot nicht gefunden' using errcode = 'P0002';
  end if;
  if not v_slot.active then
    raise exception 'slot_assign: Slot ist deaktiviert' using errcode = 'P0001';
  end if;

  -- Bestehende aktive Zuweisung des Leads loesen — ein Kind sitzt in genau
  -- einer Gruppe. Das laeuft VOR dem Zaehlen, damit ein Wechsel innerhalb
  -- desselben Slots (Re-Assign) sich nicht selbst als Ueberbuchung sieht.
  update slot_assignments
     set released_at = now()
   where lead_id = p_lead_id
     and released_at is null;

  select count(*)::int into v_belegt
    from slot_assignments
   where slot_id = p_slot_id
     and released_at is null;

  if v_belegt >= v_slot.capacity then
    raise exception 'slot_assign: Slot ist ausgebucht (%/%)',
      v_belegt, v_slot.capacity using errcode = 'P0001';
  end if;

  insert into slot_assignments (slot_id, lead_id, created_by)
  values (p_slot_id, p_lead_id, auth.uid())
  returning id into v_id;

  -- belegt inkl. der gerade angelegten Zeile — das Frontend zeigt den Stand
  -- unmittelbar an, ohne nachzuladen.
  return jsonb_build_object(
    'ok',            true,
    'assignment_id', v_id,
    'belegt',        v_belegt + 1,
    'capacity',      v_slot.capacity
  );
end;
$$;


--
-- Name: slot_release(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.slot_release(p_assignment_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_count integer;
begin
  if public.get_my_role() not in ('coach','admin') then
    raise exception 'slot_release: nur Coach oder Admin' using errcode = '42501';
  end if;

  update slot_assignments
     set released_at = now()
   where id = p_assignment_id
     and released_at is null;
  get diagnostics v_count = row_count;

  if v_count = 0 and not exists (
    select 1 from slot_assignments where id = p_assignment_id
  ) then
    raise exception 'slot_release: Zuweisung nicht gefunden' using errcode = 'P0002';
  end if;

  -- Bereits freigegeben → idempotent (released=false meldet das ehrlich).
  -- Muster wie platz_release (S9).
  return jsonb_build_object(
    'ok',            true,
    'assignment_id', p_assignment_id,
    'released',      v_count = 1
  );
end;
$$;


--
-- Name: students_guard_provisional(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.students_guard_provisional() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if new.is_provisional
     and (tg_op = 'INSERT' or old.is_provisional is distinct from new.is_provisional)
     and coalesce(current_setting('edvance.allow_provisional', true), '') <> '1'
  then
    raise exception
      'students: provisorische Zeilen entstehen nur ueber lead_lsa_freigeben'
      using errcode = '42501';
  end if;
  return new;
end;
$$;


--
-- Name: subscriptions_guard_provisional(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.subscriptions_guard_provisional() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if exists (select 1 from students where id = new.student_id and is_provisional) then
    raise exception
      'student_subscriptions: provisorischer Schueler traegt kein Abo (erst lead_convert)'
      using errcode = 'P0001';
  end if;
  return new;
end;
$$;


--
-- Name: task_preview_payload(uuid, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.task_preview_payload(p_task_id uuid, p_draft jsonb DEFAULT NULL::jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_payload jsonb;
begin
  -- Das Tor, das der Builder selbst nicht hat. Ein Schueler kommt hier nicht durch
  -- — auch nicht fuer sein eigenes Item, auch nicht ohne Entwurf.
  if public.get_my_role() not in ('coach', 'admin') then
    raise exception 'task_preview_payload: nur Coach/Admin' using errcode = '42501';
  end if;

  -- Ohne diese Pruefung liefe der Entwurfspfad ins Leere (update trifft 0 Zeilen)
  -- und gaebe stumm NULL zurueck — der Editor koennte "leeres Item" nicht von
  -- "Item weg" unterscheiden.
  if not exists (select 1 from tasks where id = p_task_id) then
    raise exception 'task_preview_payload: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;

  -- Der gespeicherte Stand: direkt durchgereicht. Kein Zwischenschritt, keine
  -- Kopie, keine Interpretation.
  if p_draft is null or jsonb_typeof(p_draft) <> 'object' then
    return public.lsa_question_payload(p_task_id);
  end if;

  -- Der Entwurfsstand. Uebernommen werden ausschliesslich die sechs Spalten, die
  -- lsa_question_payload ueberhaupt liest — alles andere im Draft (afb, competency,
  -- curriculum_grade, title) ist Diagnostik-Metadatum und geht das Kind nichts an.
  -- `p_draft ? key` unterscheidet "nicht mitgeschickt" von "auf null gesetzt".
  begin
    update tasks t set
      question         = case when p_draft ? 'question'
                              then p_draft ->> 'question' else t.question end,
      input_type       = case when p_draft ? 'input_type'
                              then p_draft ->> 'input_type' else t.input_type end,
      unit             = case when p_draft ? 'unit'
                              then p_draft ->> 'unit' else t.unit end,
      parts            = case when p_draft ? 'parts'
                              then coalesce(nullif(p_draft -> 'parts', 'null'::jsonb), '[]'::jsonb)
                              else t.parts end,
      assets           = case when p_draft ? 'assets'
                              then coalesce(nullif(p_draft -> 'assets', 'null'::jsonb), '[]'::jsonb)
                              else t.assets end,
      question_payload = case when p_draft ? 'question_payload'
                              then nullif(p_draft -> 'question_payload', 'null'::jsonb)
                              else t.question_payload end
     where t.id = p_task_id;

    -- DIESELBE Funktion. Das ist der ganze Punkt dieser Migration.
    v_payload := public.lsa_question_payload(p_task_id);

    -- Und zurueck. Der Entwurf war ein Gedankenspiel, kein Schreibvorgang.
    raise exception 'task_preview_payload: rollback' using errcode = 'ED001';
  exception
    when sqlstate 'ED001' then
      null;  -- erwartet. v_payload ueberlebt, die Zeilenaenderung nicht.
  end;

  return v_payload;
end;
$$;


--
-- Name: task_solution_get(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.task_solution_get(p_task_id uuid) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_row task_solutions%rowtype;
begin
  if public.get_my_role() not in ('coach', 'admin') then
    raise exception 'task_solution_get: nur Coach/Admin' using errcode = '42501';
  end if;

  select * into v_row from task_solutions where task_id = p_task_id;

  if not found then
    return jsonb_build_object('exists', false, 'task_id', p_task_id);
  end if;

  return jsonb_build_object(
    'exists',          true,
    'task_id',         v_row.task_id,
    'correct_answers', v_row.correct_answers,
    'acceptance',      v_row.acceptance,
    'option_scores',   v_row.option_scores,
    'solution',        v_row.solution,
    'beleg',           v_row.beleg,
    'hints',           v_row.hints,
    'coach_hints',     v_row.coach_hints,
    'typical_errors',  v_row.typical_errors,
    'updated_at',      v_row.updated_at
  );
end;
$$;


--
-- Name: task_solution_upsert(uuid, jsonb, text, jsonb, jsonb, jsonb, jsonb, jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.task_solution_upsert(p_task_id uuid, p_correct_answers jsonb DEFAULT NULL::jsonb, p_solution text DEFAULT NULL::text, p_hints jsonb DEFAULT NULL::jsonb, p_coach_hints jsonb DEFAULT NULL::jsonb, p_typical_errors jsonb DEFAULT NULL::jsonb, p_beleg jsonb DEFAULT NULL::jsonb, p_acceptance jsonb DEFAULT NULL::jsonb, p_option_scores jsonb DEFAULT NULL::jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'task_solution_upsert: nur Admin' using errcode = '42501';
  end if;
  if not exists (select 1 from tasks where id = p_task_id) then
    raise exception 'task_solution_upsert: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if p_beleg is not null and jsonb_typeof(p_beleg) not in ('array', 'null') then
    raise exception 'task_solution_upsert: beleg muss ein Array sein (oder JSON-null zum Leeren)'
      using errcode = '22023';
  end if;
  -- Frueh und mit Klartext statt erst im CHECK: der Editor soll wissen, WAS
  -- nicht stimmt, nicht nur dass ein Constraint gefeuert hat.
  if p_acceptance is not null and jsonb_typeof(p_acceptance) <> 'null'
     and not public.lsa_acceptance_valid(p_acceptance) then
    raise exception 'task_solution_upsert: acceptance verletzt den Strukturvertrag '
                    '(canonical fehlt, unbekanntes notation-Flag, tolerance ungueltig '
                    'oder unit_graded zusammen mit unit_optional)'
      using errcode = '22023';
  end if;
  if p_option_scores is not null and jsonb_typeof(p_option_scores) <> 'null'
     and not public.lsa_option_scores_valid(p_option_scores) then
    raise exception 'task_solution_upsert: option_scores verletzt den Strukturvertrag '
                    '(nur voll|teilweise|nicht, hoechstens eine ''voll'' und eine '
                    '''teilweise'' je Aufgabe/Teilaufgabe)'
      using errcode = '22023';
  end if;

  insert into task_solutions as s
    (task_id, correct_answers, solution, hints, coach_hints, typical_errors, beleg,
     acceptance, option_scores, updated_at)
  values
    (p_task_id,
     coalesce(p_correct_answers, '[]'::jsonb),
     nullif(p_solution, ''),
     coalesce(p_hints, '[]'::jsonb),
     coalesce(p_coach_hints, '[]'::jsonb),
     coalesce(p_typical_errors, '[]'::jsonb),
     case when p_beleg is null or jsonb_typeof(p_beleg) = 'null' then null else p_beleg end,
     case when p_acceptance is null or jsonb_typeof(p_acceptance) = 'null'
          then null else p_acceptance end,
     case when p_option_scores is null or jsonb_typeof(p_option_scores) = 'null'
          then null else p_option_scores end,
     now())
  on conflict (task_id) do update
     set correct_answers = coalesce(p_correct_answers, s.correct_answers),
         solution        = case when p_solution is null then s.solution
                                else nullif(p_solution, '') end,
         hints           = coalesce(p_hints, s.hints),
         coach_hints     = coalesce(p_coach_hints, s.coach_hints),
         typical_errors  = coalesce(p_typical_errors, s.typical_errors),
         beleg           = case when p_beleg is null then s.beleg
                                when jsonb_typeof(p_beleg) = 'null' then null
                                else p_beleg end,
         acceptance      = case when p_acceptance is null then s.acceptance
                                when jsonb_typeof(p_acceptance) = 'null' then null
                                else p_acceptance end,
         option_scores   = case when p_option_scores is null then s.option_scores
                                when jsonb_typeof(p_option_scores) = 'null' then null
                                else p_option_scores end,
         updated_at      = now();

  return jsonb_build_object('ok', true, 'task_id', p_task_id);
end;
$$;


--
-- Name: task_solutions_zahlen_guard(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.task_solutions_zahlen_guard() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if current_user = 'authenticated'
     and (new.correct_answers is distinct from old.correct_answers
          or new.acceptance is distinct from old.acceptance) then
    raise exception
      'A20: Loesungszahlen (correct_answers/acceptance) duerfen nicht von Hand geaendert werden.'
      using errcode = '23514';
  end if;
  return new;
end $$;


--
-- Name: task_status_set(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.task_status_set(p_task_id uuid, p_status text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_task tasks%rowtype;
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'task_status_set: nur Admin' using errcode = '42501';
  end if;
  if p_status not in ('draft', 'review', 'ready') then
    raise exception 'task_status_set: unbekannter Status %', p_status
      using errcode = '22023';
  end if;

  select * into v_task from tasks where id = p_task_id;
  if not found then
    raise exception 'task_status_set: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;

  -- Das Gate. Was hier durchfaellt, kommt nicht in den LSA-Pool — unabhaengig
  -- davon, was das Frontend meint. Es sind dieselben Pflichtfelder, die
  -- src/lib/authoring/flags.ts prueft; hier stehen die, die die DB selbst
  -- beantworten kann (das Tool prueft zusaetzlich Alt-Texte u.a.).
  if p_status = 'ready' then
    if coalesce(btrim(v_task.question), '') = '' then
      raise exception 'task_status_set: Stamm fehlt' using errcode = 'P0001';
    end if;
    if v_task.input_type is null then
      raise exception 'task_status_set: input_type fehlt' using errcode = 'P0001';
    end if;
    if v_task.afb is null then
      raise exception 'task_status_set: AFB fehlt' using errcode = 'P0001';
    end if;
    if v_task.cluster_id is null then
      raise exception 'task_status_set: Cluster fehlt (sonst nie im LSA-Pool)'
        using errcode = 'P0001';
    end if;
    -- Der Stoffanker ist der Grund, warum es dieses Tool gibt. Ohne ihn zieht die
    -- LSA das Item auf dem falschen Jahrgang.
    if v_task.curriculum_grade is null then
      raise exception 'task_status_set: Stoffanker (curriculum_grade) fehlt'
        using errcode = 'P0001';
    end if;
    -- Loesung: lsa_has_answers (P02) kennt beide Formen — flach + Multi-Part — und
    -- verlangt bei MULTI_PART eine Loesung JE Teilaufgabe. Kein zweites Regelwerk.
    if not exists (
      select 1 from task_solutions s
       where s.task_id = p_task_id
         and public.lsa_has_answers(v_task.input_type, v_task.parts, s.correct_answers)
    ) then
      raise exception 'task_status_set: Loesung unvollstaendig' using errcode = 'P0001';
    end if;
  end if;

  update tasks
     set status      = p_status,
         reviewed_by = case when p_status = 'ready' then auth.uid() else null end,
         reviewed_at = case when p_status = 'ready' then now()      else null end
   where id = p_task_id;

  return jsonb_build_object('ok', true, 'task_id', p_task_id, 'status', p_status);
end;
$$;


--
-- Name: tasks_zahlen_guard(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.tasks_zahlen_guard() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if current_user = 'authenticated'
     and public.lsa_ziffernfolge(new.question)
         is distinct from public.lsa_ziffernfolge(old.question) then
    raise exception
      'A20: Zahlen im Aufgabentext duerfen nicht von Hand geaendert werden — nur der Text. Eine geaenderte Zahl umgeht das Sieb.'
      using errcode = '23514';
  end if;
  return new;
end $$;


--
-- Name: badge_catalog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.badge_catalog (
    id text NOT NULL,
    label text NOT NULL,
    description text,
    rarity public.badge_rarity NOT NULL,
    form public.badge_form DEFAULT 'round'::public.badge_form NOT NULL,
    klasse integer,
    trigger text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: behavior_snapshots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.behavior_snapshots (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    task_id uuid,
    submitted_at timestamp with time zone DEFAULT now(),
    answer_text text,
    thinking_time_ms integer,
    task_duration_ms integer,
    revision_count integer,
    rewrite_count integer,
    hint_used boolean,
    hint_request_time_ms integer,
    answer_length integer,
    time_after_completion_ms integer,
    screening_test_id uuid
);


--
-- Name: coaching_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.coaching_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    coach_id uuid NOT NULL,
    room text,
    scheduled_at timestamp with time zone NOT NULL,
    status text DEFAULT 'upcoming'::text NOT NULL,
    slot_id uuid,
    CONSTRAINT coaching_sessions_status_check CHECK ((status = ANY (ARRAY['upcoming'::text, 'active'::text, 'done'::text])))
);


--
-- Name: fehlbild_familien; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fehlbild_familien (
    schluessel text NOT NULL,
    elterntext text,
    freigegeben_am timestamp with time zone,
    freigegeben_von uuid
);


--
-- Name: fehlbild_labels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fehlbild_labels (
    slug text NOT NULL,
    klartext text,
    erklaerung text,
    erstellt_am timestamp with time zone DEFAULT now() NOT NULL,
    freigegeben_am timestamp with time zone,
    freigegeben_von uuid,
    familie text
);


--
-- Name: intake_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.intake_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    student_id uuid NOT NULL,
    lead_id uuid,
    coach_id uuid,
    conducted_at timestamp with time zone,
    goals text,
    motivation text,
    learning_history text,
    parent_expectations text,
    known_weak_topics text[] DEFAULT '{}'::text[],
    agreed_next_steps text,
    notes text,
    status text DEFAULT 'draft'::text NOT NULL,
    CONSTRAINT intake_sessions_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'final'::text])))
);


--
-- Name: interventions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.interventions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    session_id uuid NOT NULL,
    student_id uuid NOT NULL,
    coach_id uuid NOT NULL,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    resolved_at timestamp with time zone,
    note text
);


--
-- Name: lead_assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lead_assessments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    lead_id uuid NOT NULL,
    source text NOT NULL,
    note text,
    weak_topics text[] DEFAULT '{}'::text[] NOT NULL,
    CONSTRAINT lead_assessments_source_check CHECK ((source = ANY (ARRAY['parent'::text, 'child'::text])))
);


--
-- Name: leads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leads (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    full_name text NOT NULL,
    contact_email text,
    contact_phone text,
    class_level integer,
    school_type text,
    school_name text,
    subjects text[] DEFAULT '{}'::text[],
    goal text,
    known_weak_topics text[] DEFAULT '{}'::text[],
    source text,
    status text DEFAULT 'new'::text NOT NULL,
    owner_id uuid,
    notes text,
    converted_student_id uuid,
    contacted_at timestamp with time zone,
    onboarding_scheduled_at timestamp with time zone,
    first_name text,
    birth_date date,
    last_grade text,
    grade_trend text,
    struggling_since text,
    tried_before text[],
    next_exam_date date,
    next_exam_topic text,
    consent_dsgvo_at timestamp with time zone,
    consent_dsgvo_by uuid,
    konvertiert_am timestamp with time zone,
    current_topic_cluster_id uuid,
    consent_dsgvo_signature text,
    consent_dsgvo_document_version text,
    CONSTRAINT leads_class_level_check CHECK (((class_level >= 5) AND (class_level <= 13))),
    CONSTRAINT leads_goal_check CHECK ((goal = ANY (ARRAY['IMPROVE_GRADES'::text, 'CLOSE_GAPS'::text, 'EXAM_PREP'::text, 'GENERAL'::text]))),
    CONSTRAINT leads_grade_trend_check CHECK (((grade_trend IS NULL) OR (grade_trend = ANY (ARRAY['besser'::text, 'stabil'::text, 'schlechter'::text])))),
    CONSTRAINT leads_school_type_check CHECK ((school_type = ANY (ARRAY['Gymnasium'::text, 'Gesamtschule'::text, 'Realschule'::text, 'Hauptschule'::text]))),
    CONSTRAINT leads_status_check CHECK ((status = ANY (ARRAY['new'::text, 'contacted'::text, 'onboarding_scheduled'::text, 'converted'::text, 'rejected'::text, 'lsa_freigegeben'::text, 'lsa_fertig'::text]))),
    CONSTRAINT leads_struggling_since_check CHECK (((struggling_since IS NULL) OR (struggling_since = ANY (ARRAY['dieses_halbjahr'::text, 'letztes_schuljahr'::text, 'laenger'::text]))))
);


--
-- Name: lsa_ausgegeben; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lsa_ausgegeben (
    session_id uuid NOT NULL,
    task_id uuid NOT NULL,
    ausgegeben_am timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: lsa_report_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lsa_report_notes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    session_id uuid NOT NULL,
    zielbild text,
    empfehlung text,
    paket text,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid,
    CONSTRAINT lsa_report_notes_paket_check CHECK ((paket = ANY (ARRAY['basis'::text, 'standard'::text, 'premium'::text])))
);


--
-- Name: lsa_responses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lsa_responses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    session_id uuid NOT NULL,
    task_id uuid NOT NULL,
    response jsonb,
    correct boolean,
    duration_ms integer,
    part_nr integer,
    abgabeart text DEFAULT 'antwort'::text NOT NULL,
    fehlbild_slug text,
    CONSTRAINT lsa_responses_abgabeart_check CHECK ((abgabeart = ANY (ARRAY['antwort'::text, 'weiss_nicht'::text, 'leer'::text]))),
    CONSTRAINT lsa_responses_correct_nur_bei_antwort CHECK (((abgabeart = 'antwort'::text) = (correct IS NOT NULL))),
    CONSTRAINT lsa_responses_part_nr_check CHECK (((part_nr IS NULL) OR (part_nr >= 1)))
);


--
-- Name: lsa_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lsa_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    student_id uuid NOT NULL,
    subject text NOT NULL,
    grade integer NOT NULL,
    status text DEFAULT 'in_progress'::text NOT NULL,
    item_ids uuid[] DEFAULT '{}'::uuid[] NOT NULL,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    result_summary jsonb,
    avatar_choice text,
    modus text DEFAULT 'fest'::text NOT NULL,
    uebernommen_zu_student_id uuid,
    uebernommen_am timestamp with time zone,
    CONSTRAINT lsa_sessions_avatar_choice_form CHECK (((avatar_choice IS NULL) OR (((length(avatar_choice) >= 1) AND (length(avatar_choice) <= 40)) AND (avatar_choice = btrim(avatar_choice))))),
    CONSTRAINT lsa_sessions_grade_check CHECK (((grade >= 5) AND (grade <= 13))),
    CONSTRAINT lsa_sessions_modus_check CHECK ((modus = ANY (ARRAY['fest'::text, 'adaptiv'::text]))),
    CONSTRAINT lsa_sessions_status_check CHECK ((status = ANY (ARRAY['in_progress'::text, 'completed'::text, 'aborted'::text])))
);


--
-- Name: lsa_skill_urteil; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lsa_skill_urteil (
    session_id uuid NOT NULL,
    skill_key text NOT NULL,
    zustand text NOT NULL,
    belegt_direkt boolean NOT NULL,
    offen boolean DEFAULT false NOT NULL,
    proben_anzahl integer DEFAULT 0 NOT NULL,
    aktualisiert timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT lsa_skill_urteil_zustand_check CHECK ((zustand = ANY (ARRAY['traegt'::text, 'traegt_teilweise'::text, 'traegt_nicht'::text, 'nicht_angesetzt'::text, 'ungeprueft'::text])))
);


--
-- Name: microskills; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.microskills (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    cluster_id uuid,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    class_level integer NOT NULL,
    prerequisite_ids uuid[] DEFAULT '{}'::uuid[],
    sort_order integer DEFAULT 0,
    cognitive_type text,
    estimated_minutes integer,
    curriculum_ref text,
    CONSTRAINT microskills_class_level_check CHECK (((class_level >= 5) AND (class_level <= 13))),
    CONSTRAINT microskills_cognitive_type_check CHECK ((cognitive_type = ANY (ARRAY['FACT'::text, 'TRANSFER'::text, 'ANALYSIS'::text])))
);


--
-- Name: parent_report_generations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parent_report_generations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    coach_id uuid,
    student_id uuid NOT NULL,
    model text
);


--
-- Name: parent_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parent_reports (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    student_id uuid NOT NULL,
    period_start date NOT NULL,
    period_end date NOT NULL,
    summary jsonb,
    coach_note text,
    status text DEFAULT 'draft'::text NOT NULL,
    published_at timestamp with time zone,
    CONSTRAINT parent_reports_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'published'::text])))
);


--
-- Name: parent_student; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parent_student (
    parent_id uuid NOT NULL,
    student_id uuid NOT NULL
);


--
-- Name: platz_devices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.platz_devices (
    profile_id uuid NOT NULL,
    label text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: process_competencies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.process_competencies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    sort_order integer NOT NULL
);


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    id uuid NOT NULL,
    email text NOT NULL,
    role text NOT NULL,
    full_name text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT profiles_role_check CHECK ((role = ANY (ARRAY['student'::text, 'parent'::text, 'coach'::text, 'admin'::text])))
);


--
-- Name: report_anlass_zuordnung; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.report_anlass_zuordnung (
    thema text NOT NULL,
    skill_keys text[] DEFAULT '{}'::text[] NOT NULL,
    fehlbild_familien text[] DEFAULT '{}'::text[] NOT NULL,
    strukturell boolean DEFAULT false NOT NULL,
    anzeigename text NOT NULL,
    messbar boolean DEFAULT true NOT NULL
);


--
-- Name: report_bausteine; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.report_bausteine (
    schluessel text NOT NULL,
    slot text NOT NULL,
    fall text NOT NULL,
    variante text NOT NULL,
    text text NOT NULL,
    freigegeben_am timestamp with time zone,
    freigegeben_von uuid,
    CONSTRAINT report_bausteine_variante_check CHECK ((variante = ANY (ARRAY['a'::text, 'b'::text])))
);


--
-- Name: screening_item_ratings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.screening_item_ratings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    screening_item_result_id uuid NOT NULL,
    coach_id uuid,
    reached_afb text,
    note text,
    CONSTRAINT screening_item_ratings_reached_afb_check CHECK ((reached_afb = ANY (ARRAY['I'::text, 'II'::text, 'III'::text])))
);


--
-- Name: screening_item_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.screening_item_results (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    screening_test_id uuid NOT NULL,
    screening_item_id uuid NOT NULL,
    cluster_id uuid NOT NULL,
    level smallint NOT NULL,
    correct boolean,
    answer jsonb,
    duration_ms integer,
    CONSTRAINT screening_item_results_level_check CHECK ((level = ANY (ARRAY[1, 2, 3])))
);


--
-- Name: screening_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.screening_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    cluster_id uuid,
    class_level integer NOT NULL,
    topic text,
    skill_code text,
    skill_label text,
    level smallint,
    curriculum_seq integer,
    input_type text NOT NULL,
    prompt text,
    payload jsonb,
    canonical jsonb,
    check_type text NOT NULL,
    tolerance numeric,
    typical_errors text[] DEFAULT '{}'::text[],
    explanation text,
    source text DEFAULT 'edvance_original'::text NOT NULL,
    active boolean DEFAULT false NOT NULL,
    afb text,
    phase text,
    iqb_titel text,
    kompetenzfelder text[],
    aufgabe_typ text,
    teilaufgaben jsonb,
    kontext text,
    loesung_pro_ta jsonb,
    akzeptierte_antworten jsonb,
    kodierung text,
    kommentar_highlights jsonb,
    urls jsonb,
    datei_ext text,
    quelle text,
    fix_anker boolean DEFAULT false,
    meta jsonb,
    competency_id uuid,
    microskill_id uuid,
    CONSTRAINT screening_items_afb_check CHECK ((afb = ANY (ARRAY['I'::text, 'II'::text, 'III'::text]))),
    CONSTRAINT screening_items_check_type_check CHECK ((check_type = ANY (ARRAY['mc_index'::text, 'numeric'::text, 'matching_set'::text, 'normalized'::text, 'manual'::text]))),
    CONSTRAINT screening_items_class_level_check CHECK (((class_level >= 5) AND (class_level <= 13))),
    CONSTRAINT screening_items_input_type_check CHECK ((input_type = ANY (ARRAY['MC'::text, 'NUMERIC'::text, 'SHORT_TEXT'::text, 'TRUE_FALSE'::text, 'FREE_TEXT'::text, 'MATCHING'::text, 'CLOZE'::text, 'COORDINATE'::text]))),
    CONSTRAINT screening_items_level_check CHECK ((level = ANY (ARRAY[1, 2, 3]))),
    CONSTRAINT screening_items_phase_check CHECK ((phase = ANY (ARRAY['sprint'::text, 'tiefe'::text])))
);


--
-- Name: screening_ratings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.screening_ratings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    behavior_snapshot_id uuid NOT NULL,
    screening_test_id uuid NOT NULL,
    rating smallint NOT NULL,
    coach_id uuid,
    CONSTRAINT screening_ratings_rating_check CHECK ((rating = ANY (ARRAY[1, 2, 3, 4])))
);


--
-- Name: screening_tests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.screening_tests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    student_id uuid NOT NULL,
    subject text NOT NULL,
    status text DEFAULT 'in_progress'::text NOT NULL,
    coach_id uuid,
    coach_note text,
    generated_test jsonb,
    generated_test_version smallint DEFAULT 1 NOT NULL,
    result_summary jsonb,
    estimated_total_minutes integer,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    CONSTRAINT screening_tests_status_check CHECK ((status = ANY (ARRAY['in_progress'::text, 'completed'::text, 'aborted'::text])))
);


--
-- Name: session_students; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.session_students (
    session_id uuid NOT NULL,
    student_id uuid NOT NULL,
    attendance text DEFAULT 'unknown'::text NOT NULL,
    CONSTRAINT session_students_attendance_check CHECK ((attendance = ANY (ARRAY['present'::text, 'absent'::text, 'unknown'::text])))
);


--
-- Name: skill_clusters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skill_clusters (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    subject_id uuid,
    name text NOT NULL,
    class_level_min integer NOT NULL,
    class_level_max integer NOT NULL,
    sort_order integer DEFAULT 0,
    is_deprecated boolean DEFAULT false NOT NULL,
    school_types text[],
    CONSTRAINT skill_clusters_class_level_max_check CHECK (((class_level_max >= 5) AND (class_level_max <= 13))),
    CONSTRAINT skill_clusters_class_level_min_check CHECK (((class_level_min >= 5) AND (class_level_min <= 13)))
);


--
-- Name: skill_kante; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skill_kante (
    skill_key text NOT NULL,
    voraussetzt_skill_key text NOT NULL
);


--
-- Name: skill_voraussetzung; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skill_voraussetzung (
    thema_key text NOT NULL,
    skill_key text NOT NULL,
    tragkraft integer NOT NULL,
    CONSTRAINT skill_voraussetzung_tragkraft_check CHECK ((tragkraft = ANY (ARRAY[1, 2])))
);


--
-- Name: skills; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skills (
    skill_key text NOT NULL,
    label text NOT NULL,
    fach text DEFAULT 'mathematik'::text NOT NULL,
    klasse_herkunft integer NOT NULL,
    fundament_tiefe integer NOT NULL,
    CONSTRAINT skills_fundament_tiefe_check CHECK (((fundament_tiefe >= 1) AND (fundament_tiefe <= 8)))
);


--
-- Name: slot_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.slot_assignments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    slot_id uuid NOT NULL,
    lead_id uuid NOT NULL,
    assigned_at timestamp with time zone DEFAULT now() NOT NULL,
    released_at timestamp with time zone,
    created_by uuid
);


--
-- Name: slot_wishes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.slot_wishes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    lead_id uuid NOT NULL,
    slot_id uuid NOT NULL,
    rang smallint NOT NULL,
    CONSTRAINT slot_wishes_rang_check CHECK (((rang >= 1) AND (rang <= 3)))
);


--
-- Name: slots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.slots (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    weekday smallint NOT NULL,
    start_time time without time zone NOT NULL,
    room text NOT NULL,
    capacity integer DEFAULT 5 NOT NULL,
    valid_from date DEFAULT CURRENT_DATE NOT NULL,
    valid_until date,
    class_level_min smallint,
    class_level_max smallint,
    CONSTRAINT slots_capacity_check CHECK (((capacity >= 1) AND (capacity <= 5))),
    CONSTRAINT slots_class_level_max_check CHECK (((class_level_max IS NULL) OR ((class_level_max >= 5) AND (class_level_max <= 13)))),
    CONSTRAINT slots_class_level_min_check CHECK (((class_level_min IS NULL) OR ((class_level_min >= 5) AND (class_level_min <= 13)))),
    CONSTRAINT slots_klassenstufe_check CHECK (((class_level_max IS NULL) OR (class_level_min IS NULL) OR (class_level_max >= class_level_min))),
    CONSTRAINT slots_laufzeit_check CHECK (((valid_until IS NULL) OR (valid_until >= valid_from))),
    CONSTRAINT slots_room_check CHECK ((length(btrim(room)) > 0)),
    CONSTRAINT slots_weekday_check CHECK (((weekday >= 0) AND (weekday <= 6)))
);


--
-- Name: streak_repair_inventory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.streak_repair_inventory (
    student_id uuid NOT NULL,
    tokens integer DEFAULT 0 NOT NULL,
    earned_total integer DEFAULT 0 NOT NULL,
    used_total integer DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: student_badges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.student_badges (
    student_id uuid NOT NULL,
    badge_id text NOT NULL,
    awarded_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: student_coach; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.student_coach (
    student_id uuid NOT NULL,
    coach_id uuid NOT NULL,
    assigned_at timestamp with time zone DEFAULT now(),
    active boolean DEFAULT true NOT NULL
);


--
-- Name: student_competency_mastery; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.student_competency_mastery (
    student_id uuid NOT NULL,
    microskill_id uuid NOT NULL,
    competency_id uuid NOT NULL,
    score numeric(5,2) DEFAULT 0 NOT NULL,
    mastered boolean DEFAULT false NOT NULL,
    mastered_by uuid,
    mastered_at timestamp with time zone,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    stage text GENERATED ALWAYS AS (public.mastery_stage(score)) STORED,
    CONSTRAINT student_competency_mastery_score_check CHECK (((score >= (0)::numeric) AND (score <= (100)::numeric)))
);


--
-- Name: student_focus_areas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.student_focus_areas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    student_id uuid NOT NULL,
    cluster_id uuid,
    coach_id uuid,
    source text DEFAULT 'klassenarbeit'::text,
    note text,
    active boolean DEFAULT true NOT NULL,
    skill_key text,
    herkunfts_session_id uuid,
    zustand text,
    belegt_direkt boolean,
    status text DEFAULT 'vorgeschlagen'::text NOT NULL,
    CONSTRAINT sfa_cluster_xor_skill CHECK (((cluster_id IS NOT NULL) <> (skill_key IS NOT NULL))),
    CONSTRAINT student_focus_areas_status_check CHECK ((status = ANY (ARRAY['vorgeschlagen'::text, 'bestaetigt'::text, 'verworfen'::text])))
);


--
-- Name: student_progress; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.student_progress (
    student_id uuid NOT NULL,
    xp_total integer DEFAULT 0 NOT NULL,
    level integer DEFAULT 1 NOT NULL,
    last_activity timestamp with time zone,
    presence_streak_weeks integer DEFAULT 0 NOT NULL,
    presence_streak_last_week_start timestamp with time zone,
    presence_streak_multiplier numeric(3,2) DEFAULT 1.00 NOT NULL,
    home_streak_sessions integer DEFAULT 0 NOT NULL,
    home_streak_last_completed_at timestamp with time zone
);


--
-- Name: student_subjects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.student_subjects (
    student_id uuid NOT NULL,
    subject_id uuid NOT NULL
);


--
-- Name: student_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.student_subscriptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    student_id uuid NOT NULL,
    tier_id uuid NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    started_at timestamp with time zone DEFAULT now(),
    ended_at timestamp with time zone,
    CONSTRAINT student_subscriptions_status_check CHECK ((status = ANY (ARRAY['active'::text, 'paused'::text, 'cancelled'::text])))
);


--
-- Name: student_task_progress; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.student_task_progress (
    student_id uuid NOT NULL,
    task_id uuid NOT NULL,
    completed_at timestamp with time zone DEFAULT now()
);


--
-- Name: students; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.students (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    profile_id uuid,
    class_level integer,
    school_name text,
    school_type text,
    is_provisional boolean DEFAULT false NOT NULL,
    lead_id uuid,
    CONSTRAINT students_class_level_check CHECK (((class_level >= 5) AND (class_level <= 13))),
    CONSTRAINT students_provisional_lead_ck CHECK ((is_provisional = (lead_id IS NOT NULL))),
    CONSTRAINT students_school_type_check CHECK ((school_type = ANY (ARRAY['Gymnasium'::text, 'Gesamtschule'::text, 'Realschule'::text, 'Hauptschule'::text])))
);


--
-- Name: subjects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subjects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL
);


--
-- Name: task_coach_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_coach_metadata (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    task_id uuid,
    typical_errors text,
    observation_hints text,
    intervention_triggers text,
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: task_figures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_figures (
    task_id uuid NOT NULL,
    generator text NOT NULL,
    params jsonb NOT NULL,
    alt_text text NOT NULL,
    svg_hash text,
    erzeugt_am timestamp with time zone,
    CONSTRAINT task_figures_alt_no_digit CHECK ((alt_text !~ '[0-9]'::text)),
    CONSTRAINT task_figures_alt_not_empty CHECK ((btrim(alt_text) <> ''::text)),
    CONSTRAINT task_figures_generator_check CHECK ((generator = ANY (ARRAY['koordinatensystem'::text, 'winkel'::text])))
);


--
-- Name: task_reviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_reviews (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    task_id uuid NOT NULL,
    kategorie text NOT NULL,
    notiz text,
    geprueft_von uuid,
    geprueft_am timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT task_reviews_kategorie_check CHECK ((kategorie = ANY (ARRAY['fehlbild_falsch'::text, 'fehlbild_unrealistisch'::text, 'zahlen_unguenstig'::text, 'formulierung'::text, 'didaktisch'::text, 'kontext'::text])))
);


--
-- Name: task_solutions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_solutions (
    task_id uuid NOT NULL,
    correct_answers jsonb DEFAULT '[]'::jsonb NOT NULL,
    solution text,
    hints jsonb DEFAULT '[]'::jsonb NOT NULL,
    coach_hints jsonb DEFAULT '[]'::jsonb NOT NULL,
    typical_errors jsonb DEFAULT '[]'::jsonb NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    legacy_payload jsonb,
    beleg jsonb,
    acceptance jsonb,
    option_scores jsonb,
    CONSTRAINT task_solutions_acceptance_check CHECK (((acceptance IS NULL) OR public.lsa_acceptance_valid(acceptance))),
    CONSTRAINT task_solutions_beleg_check CHECK (((beleg IS NULL) OR (jsonb_typeof(beleg) = 'array'::text))),
    CONSTRAINT task_solutions_coach_hints_check CHECK (((jsonb_typeof(coach_hints) = 'array'::text) AND (jsonb_array_length(coach_hints) <= 3))),
    CONSTRAINT task_solutions_correct_answers_check CHECK (public.lsa_answers_valid(correct_answers)),
    CONSTRAINT task_solutions_hints_check CHECK ((jsonb_typeof(hints) = 'array'::text)),
    CONSTRAINT task_solutions_option_scores_check CHECK (((option_scores IS NULL) OR public.lsa_option_scores_valid(option_scores))),
    CONSTRAINT task_solutions_typical_errors_check CHECK ((jsonb_typeof(typical_errors) = 'array'::text))
);


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tasks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    microskill_id uuid,
    cluster_id uuid,
    content_type text NOT NULL,
    title text,
    question text,
    hint text,
    common_errors text,
    coach_note text,
    difficulty integer,
    estimated_minutes integer DEFAULT 3,
    class_level integer,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    cognitive_type text,
    input_type text,
    is_diagnostic boolean DEFAULT false,
    curriculum_ref text,
    question_payload jsonb,
    typical_errors text[],
    source text DEFAULT 'unbekannt'::text NOT NULL,
    source_ref text,
    assets jsonb DEFAULT '[]'::jsonb NOT NULL,
    competency_id uuid,
    status text DEFAULT 'draft'::text NOT NULL,
    competency_content text,
    competency_process text,
    afb text,
    est_duration_sec integer,
    unit text,
    dialog_enabled boolean DEFAULT false NOT NULL,
    parts jsonb DEFAULT '[]'::jsonb NOT NULL,
    curriculum_grade smallint,
    reviewed_by uuid,
    reviewed_at timestamp with time zone,
    is_tutorial boolean DEFAULT false NOT NULL,
    needs_image boolean,
    licence_text text,
    skill_key text,
    sondierrang integer,
    CONSTRAINT tasks_afb_check CHECK ((afb = ANY (ARRAY['I'::text, 'II'::text, 'III'::text]))),
    CONSTRAINT tasks_class_level_check CHECK (((class_level >= 5) AND (class_level <= 13))),
    CONSTRAINT tasks_cognitive_type_check CHECK ((cognitive_type = ANY (ARRAY['FACT'::text, 'TRANSFER'::text, 'ANALYSIS'::text]))),
    CONSTRAINT tasks_content_type_check CHECK ((content_type = ANY (ARRAY['exercise'::text, 'exercise_group'::text, 'article'::text, 'video'::text, 'course'::text]))),
    CONSTRAINT tasks_curriculum_grade_check CHECK (((curriculum_grade IS NULL) OR ((curriculum_grade >= 5) AND (curriculum_grade <= 13)))),
    CONSTRAINT tasks_difficulty_check CHECK (((difficulty >= 1) AND (difficulty <= 5))),
    CONSTRAINT tasks_est_duration_sec_check CHECK (((est_duration_sec IS NULL) OR ((est_duration_sec >= 10) AND (est_duration_sec <= 3600)))),
    CONSTRAINT tasks_input_type_check CHECK ((input_type = ANY (ARRAY['MC'::text, 'NUMERIC'::text, 'SHORT_TEXT'::text, 'TRUE_FALSE'::text, 'FREE_TEXT'::text, 'MATCHING'::text, 'CLOZE'::text, 'COORDINATE'::text, 'MULTI_PART'::text, 'TERM'::text]))),
    CONSTRAINT tasks_multipart_check CHECK (
CASE
    WHEN (input_type = 'MULTI_PART'::text) THEN (public.lsa_parts_valid(parts) AND (COALESCE(btrim(question), ''::text) <> ''::text) AND (est_duration_sec IS NOT NULL))
    ELSE (parts = '[]'::jsonb)
END),
    CONSTRAINT tasks_question_payload_no_solution CHECK (((question_payload IS NULL) OR (NOT (question_payload ?| ARRAY['correct'::text, 'accepted'::text, 'pairs'::text, 'blanks'::text, 'expected'::text])))),
    CONSTRAINT tasks_question_table_check CHECK (((question_payload IS NULL) OR (NOT (question_payload ? 'table'::text)) OR public.lsa_table_valid((question_payload -> 'table'::text)))),
    CONSTRAINT tasks_sondierrang_check CHECK (((sondierrang IS NULL) OR (sondierrang >= 1))),
    CONSTRAINT tasks_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'review'::text, 'ready'::text, 'beanstandet'::text])))
);


--
-- Name: themen; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.themen (
    thema_key text NOT NULL,
    fach text NOT NULL,
    klasse integer NOT NULL,
    label text
);


--
-- Name: tiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tiers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    price_cents integer NOT NULL,
    features jsonb DEFAULT '[]'::jsonb NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    active boolean DEFAULT true NOT NULL
);


--
-- Name: xp_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.xp_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    student_id uuid NOT NULL,
    task_id uuid,
    xp integer NOT NULL,
    reason text
);


--
-- Name: xp_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.xp_rules (
    content_type text NOT NULL,
    base_xp integer DEFAULT 0 NOT NULL,
    difficulty_multiplier integer DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: badge_catalog badge_catalog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badge_catalog
    ADD CONSTRAINT badge_catalog_pkey PRIMARY KEY (id);


--
-- Name: behavior_snapshots behavior_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.behavior_snapshots
    ADD CONSTRAINT behavior_snapshots_pkey PRIMARY KEY (id);


--
-- Name: coaching_sessions coaching_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coaching_sessions
    ADD CONSTRAINT coaching_sessions_pkey PRIMARY KEY (id);


--
-- Name: fehlbild_familien fehlbild_familien_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fehlbild_familien
    ADD CONSTRAINT fehlbild_familien_pkey PRIMARY KEY (schluessel);


--
-- Name: fehlbild_labels fehlbild_labels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fehlbild_labels
    ADD CONSTRAINT fehlbild_labels_pkey PRIMARY KEY (slug);


--
-- Name: intake_sessions intake_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intake_sessions
    ADD CONSTRAINT intake_sessions_pkey PRIMARY KEY (id);


--
-- Name: interventions interventions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interventions
    ADD CONSTRAINT interventions_pkey PRIMARY KEY (id);


--
-- Name: lead_assessments lead_assessments_one_per_source; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lead_assessments
    ADD CONSTRAINT lead_assessments_one_per_source UNIQUE (lead_id, source);


--
-- Name: lead_assessments lead_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lead_assessments
    ADD CONSTRAINT lead_assessments_pkey PRIMARY KEY (id);


--
-- Name: leads leads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_pkey PRIMARY KEY (id);


--
-- Name: lsa_ausgegeben lsa_ausgegeben_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsa_ausgegeben
    ADD CONSTRAINT lsa_ausgegeben_pkey PRIMARY KEY (session_id, task_id);


--
-- Name: lsa_report_notes lsa_report_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsa_report_notes
    ADD CONSTRAINT lsa_report_notes_pkey PRIMARY KEY (id);


--
-- Name: lsa_report_notes lsa_report_notes_session_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsa_report_notes
    ADD CONSTRAINT lsa_report_notes_session_id_key UNIQUE (session_id);


--
-- Name: lsa_responses lsa_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsa_responses
    ADD CONSTRAINT lsa_responses_pkey PRIMARY KEY (id);


--
-- Name: lsa_sessions lsa_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsa_sessions
    ADD CONSTRAINT lsa_sessions_pkey PRIMARY KEY (id);


--
-- Name: lsa_skill_urteil lsa_skill_urteil_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsa_skill_urteil
    ADD CONSTRAINT lsa_skill_urteil_pkey PRIMARY KEY (session_id, skill_key);


--
-- Name: microskills microskills_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.microskills
    ADD CONSTRAINT microskills_code_key UNIQUE (code);


--
-- Name: microskills microskills_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.microskills
    ADD CONSTRAINT microskills_pkey PRIMARY KEY (id);


--
-- Name: parent_report_generations parent_report_generations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parent_report_generations
    ADD CONSTRAINT parent_report_generations_pkey PRIMARY KEY (id);


--
-- Name: parent_reports parent_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parent_reports
    ADD CONSTRAINT parent_reports_pkey PRIMARY KEY (id);


--
-- Name: parent_student parent_student_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parent_student
    ADD CONSTRAINT parent_student_pkey PRIMARY KEY (parent_id, student_id);


--
-- Name: platz_assignments platz_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platz_assignments
    ADD CONSTRAINT platz_assignments_pkey PRIMARY KEY (id);


--
-- Name: platz_devices platz_devices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platz_devices
    ADD CONSTRAINT platz_devices_pkey PRIMARY KEY (profile_id);


--
-- Name: process_competencies process_competencies_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_competencies
    ADD CONSTRAINT process_competencies_code_key UNIQUE (code);


--
-- Name: process_competencies process_competencies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_competencies
    ADD CONSTRAINT process_competencies_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: report_anlass_zuordnung report_anlass_zuordnung_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_anlass_zuordnung
    ADD CONSTRAINT report_anlass_zuordnung_pkey PRIMARY KEY (thema);


--
-- Name: report_bausteine report_bausteine_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_bausteine
    ADD CONSTRAINT report_bausteine_pkey PRIMARY KEY (schluessel);


--
-- Name: report_bausteine report_bausteine_slot_fall_variante_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_bausteine
    ADD CONSTRAINT report_bausteine_slot_fall_variante_key UNIQUE (slot, fall, variante);


--
-- Name: screening_item_ratings screening_item_ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.screening_item_ratings
    ADD CONSTRAINT screening_item_ratings_pkey PRIMARY KEY (id);


--
-- Name: screening_item_results screening_item_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.screening_item_results
    ADD CONSTRAINT screening_item_results_pkey PRIMARY KEY (id);


--
-- Name: screening_items screening_items_iqb_titel_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.screening_items
    ADD CONSTRAINT screening_items_iqb_titel_uniq UNIQUE (iqb_titel);


--
-- Name: screening_items screening_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.screening_items
    ADD CONSTRAINT screening_items_pkey PRIMARY KEY (id);


--
-- Name: screening_ratings screening_ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.screening_ratings
    ADD CONSTRAINT screening_ratings_pkey PRIMARY KEY (id);


--
-- Name: screening_tests screening_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.screening_tests
    ADD CONSTRAINT screening_tests_pkey PRIMARY KEY (id);


--
-- Name: session_students session_students_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_students
    ADD CONSTRAINT session_students_pkey PRIMARY KEY (session_id, student_id);


--
-- Name: skill_clusters skill_clusters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_clusters
    ADD CONSTRAINT skill_clusters_pkey PRIMARY KEY (id);


--
-- Name: skill_kante skill_kante_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_kante
    ADD CONSTRAINT skill_kante_pkey PRIMARY KEY (skill_key, voraussetzt_skill_key);


--
-- Name: skill_voraussetzung skill_voraussetzung_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_voraussetzung
    ADD CONSTRAINT skill_voraussetzung_pkey PRIMARY KEY (thema_key, skill_key);


--
-- Name: skills skills_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skills
    ADD CONSTRAINT skills_pkey PRIMARY KEY (skill_key);


--
-- Name: slot_assignments slot_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slot_assignments
    ADD CONSTRAINT slot_assignments_pkey PRIMARY KEY (id);


--
-- Name: slot_wishes slot_wishes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slot_wishes
    ADD CONSTRAINT slot_wishes_pkey PRIMARY KEY (id);


--
-- Name: slots slots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slots
    ADD CONSTRAINT slots_pkey PRIMARY KEY (id);


--
-- Name: streak_repair_inventory streak_repair_inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.streak_repair_inventory
    ADD CONSTRAINT streak_repair_inventory_pkey PRIMARY KEY (student_id);


--
-- Name: student_badges student_badges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_badges
    ADD CONSTRAINT student_badges_pkey PRIMARY KEY (student_id, badge_id);


--
-- Name: student_coach student_coach_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_coach
    ADD CONSTRAINT student_coach_pkey PRIMARY KEY (student_id, coach_id);


--
-- Name: student_competency_mastery student_competency_mastery_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_competency_mastery
    ADD CONSTRAINT student_competency_mastery_pkey PRIMARY KEY (student_id, microskill_id, competency_id);


--
-- Name: student_focus_areas student_focus_areas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_focus_areas
    ADD CONSTRAINT student_focus_areas_pkey PRIMARY KEY (id);


--
-- Name: student_progress student_progress_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_progress
    ADD CONSTRAINT student_progress_pkey PRIMARY KEY (student_id);


--
-- Name: student_subjects student_subjects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_subjects
    ADD CONSTRAINT student_subjects_pkey PRIMARY KEY (student_id, subject_id);


--
-- Name: student_subscriptions student_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_subscriptions
    ADD CONSTRAINT student_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: student_task_progress student_task_progress_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_task_progress
    ADD CONSTRAINT student_task_progress_pkey PRIMARY KEY (student_id, task_id);


--
-- Name: students students_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_pkey PRIMARY KEY (id);


--
-- Name: subjects subjects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT subjects_pkey PRIMARY KEY (id);


--
-- Name: task_coach_metadata task_coach_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_coach_metadata
    ADD CONSTRAINT task_coach_metadata_pkey PRIMARY KEY (id);


--
-- Name: task_figures task_figures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_figures
    ADD CONSTRAINT task_figures_pkey PRIMARY KEY (task_id);


--
-- Name: task_reviews task_reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_reviews
    ADD CONSTRAINT task_reviews_pkey PRIMARY KEY (id);


--
-- Name: task_solutions task_solutions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_solutions
    ADD CONSTRAINT task_solutions_pkey PRIMARY KEY (task_id);


--
-- Name: tasks tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: tasks tasks_source_ref_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_source_ref_unique UNIQUE (source, source_ref);


--
-- Name: themen themen_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.themen
    ADD CONSTRAINT themen_pkey PRIMARY KEY (thema_key);


--
-- Name: tiers tiers_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tiers
    ADD CONSTRAINT tiers_name_key UNIQUE (name);


--
-- Name: tiers tiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tiers
    ADD CONSTRAINT tiers_pkey PRIMARY KEY (id);


--
-- Name: xp_events xp_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.xp_events
    ADD CONSTRAINT xp_events_pkey PRIMARY KEY (id);


--
-- Name: xp_rules xp_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.xp_rules
    ADD CONSTRAINT xp_rules_pkey PRIMARY KEY (content_type);


--
-- Name: behavior_snapshots_screening_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX behavior_snapshots_screening_idx ON public.behavior_snapshots USING btree (screening_test_id);


--
-- Name: behavior_snapshots_submitted_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX behavior_snapshots_submitted_idx ON public.behavior_snapshots USING btree (submitted_at DESC);


--
-- Name: behavior_snapshots_user_task_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX behavior_snapshots_user_task_idx ON public.behavior_snapshots USING btree (user_id, task_id);


--
-- Name: coaching_sessions_coach_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX coaching_sessions_coach_idx ON public.coaching_sessions USING btree (coach_id);


--
-- Name: coaching_sessions_scheduled_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX coaching_sessions_scheduled_idx ON public.coaching_sessions USING btree (scheduled_at);


--
-- Name: coaching_sessions_slot_datum_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX coaching_sessions_slot_datum_unique ON public.coaching_sessions USING btree (slot_id, (((scheduled_at AT TIME ZONE 'Europe/Berlin'::text))::date)) WHERE (slot_id IS NOT NULL);


--
-- Name: coaching_sessions_slot_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX coaching_sessions_slot_idx ON public.coaching_sessions USING btree (slot_id) WHERE (slot_id IS NOT NULL);


--
-- Name: intake_sessions_student_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX intake_sessions_student_idx ON public.intake_sessions USING btree (student_id);


--
-- Name: interventions_session_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX interventions_session_idx ON public.interventions USING btree (session_id);


--
-- Name: interventions_student_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX interventions_student_idx ON public.interventions USING btree (student_id);


--
-- Name: lead_assessments_lead_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX lead_assessments_lead_idx ON public.lead_assessments USING btree (lead_id);


--
-- Name: leads_owner_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX leads_owner_idx ON public.leads USING btree (owner_id);


--
-- Name: leads_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX leads_status_idx ON public.leads USING btree (status);


--
-- Name: lsa_report_notes_session_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX lsa_report_notes_session_idx ON public.lsa_report_notes USING btree (session_id);


--
-- Name: lsa_responses_fehlbild_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX lsa_responses_fehlbild_idx ON public.lsa_responses USING btree (session_id) WHERE (fehlbild_slug IS NOT NULL);


--
-- Name: lsa_responses_once_per_part; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX lsa_responses_once_per_part ON public.lsa_responses USING btree (session_id, task_id, COALESCE(part_nr, 0));


--
-- Name: lsa_responses_session_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX lsa_responses_session_idx ON public.lsa_responses USING btree (session_id);


--
-- Name: lsa_sessions_active_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX lsa_sessions_active_unique ON public.lsa_sessions USING btree (student_id, subject) WHERE (status = 'in_progress'::text);


--
-- Name: lsa_sessions_student_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX lsa_sessions_student_idx ON public.lsa_sessions USING btree (student_id);


--
-- Name: parent_report_gen_coach_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX parent_report_gen_coach_idx ON public.parent_report_generations USING btree (coach_id, created_at);


--
-- Name: parent_report_gen_created_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX parent_report_gen_created_idx ON public.parent_report_generations USING btree (created_at);


--
-- Name: parent_report_gen_student_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX parent_report_gen_student_idx ON public.parent_report_generations USING btree (student_id, created_at);


--
-- Name: parent_reports_student_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX parent_reports_student_idx ON public.parent_reports USING btree (student_id);


--
-- Name: platz_assignments_active_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX platz_assignments_active_unique ON public.platz_assignments USING btree (platz_profile_id) WHERE (released_at IS NULL);


--
-- Name: platz_assignments_session_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX platz_assignments_session_idx ON public.platz_assignments USING btree (session_id);


--
-- Name: screening_item_ratings_coach_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX screening_item_ratings_coach_idx ON public.screening_item_ratings USING btree (coach_id);


--
-- Name: screening_item_ratings_result_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX screening_item_ratings_result_idx ON public.screening_item_ratings USING btree (screening_item_result_id);


--
-- Name: screening_item_results_test_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX screening_item_results_test_idx ON public.screening_item_results USING btree (screening_test_id);


--
-- Name: screening_items_active_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX screening_items_active_idx ON public.screening_items USING btree (active);


--
-- Name: screening_items_cluster_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX screening_items_cluster_idx ON public.screening_items USING btree (cluster_id);


--
-- Name: screening_items_cluster_level_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX screening_items_cluster_level_idx ON public.screening_items USING btree (cluster_id, level) WHERE (active = true);


--
-- Name: screening_items_competency_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX screening_items_competency_idx ON public.screening_items USING btree (competency_id);


--
-- Name: screening_items_microskill_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX screening_items_microskill_idx ON public.screening_items USING btree (microskill_id);


--
-- Name: screening_items_quelle_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX screening_items_quelle_idx ON public.screening_items USING btree (quelle);


--
-- Name: screening_items_skill_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX screening_items_skill_idx ON public.screening_items USING btree (skill_code);


--
-- Name: screening_items_v2_pool_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX screening_items_v2_pool_idx ON public.screening_items USING btree (cluster_id, phase, afb) WHERE ((active = true) AND (afb IS NOT NULL) AND (phase IS NOT NULL));


--
-- Name: screening_ratings_snapshot_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX screening_ratings_snapshot_idx ON public.screening_ratings USING btree (behavior_snapshot_id);


--
-- Name: screening_ratings_test_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX screening_ratings_test_idx ON public.screening_ratings USING btree (screening_test_id);


--
-- Name: screening_tests_active_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX screening_tests_active_unique ON public.screening_tests USING btree (student_id, subject) WHERE (status = 'in_progress'::text);


--
-- Name: screening_tests_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX screening_tests_status_idx ON public.screening_tests USING btree (status);


--
-- Name: screening_tests_student_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX screening_tests_student_idx ON public.screening_tests USING btree (student_id);


--
-- Name: session_students_student_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX session_students_student_idx ON public.session_students USING btree (student_id);


--
-- Name: sfa_skill_herkunft_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sfa_skill_herkunft_unique ON public.student_focus_areas USING btree (student_id, skill_key, herkunfts_session_id) WHERE (skill_key IS NOT NULL);


--
-- Name: skill_kante_voraussetzt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX skill_kante_voraussetzt_idx ON public.skill_kante USING btree (voraussetzt_skill_key);


--
-- Name: slot_assignments_active_lead_slot_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX slot_assignments_active_lead_slot_unique ON public.slot_assignments USING btree (lead_id, slot_id) WHERE (released_at IS NULL);


--
-- Name: slot_assignments_active_slot_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX slot_assignments_active_slot_idx ON public.slot_assignments USING btree (slot_id) WHERE (released_at IS NULL);


--
-- Name: slot_wishes_lead_rang_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX slot_wishes_lead_rang_unique ON public.slot_wishes USING btree (lead_id, rang);


--
-- Name: slot_wishes_lead_slot_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX slot_wishes_lead_slot_unique ON public.slot_wishes USING btree (lead_id, slot_id);


--
-- Name: slot_wishes_slot_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX slot_wishes_slot_idx ON public.slot_wishes USING btree (slot_id);


--
-- Name: slots_laufend_coord_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX slots_laufend_coord_unique ON public.slots USING btree (weekday, start_time, room) WHERE (valid_until IS NULL);


--
-- Name: slots_weekday_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX slots_weekday_idx ON public.slots USING btree (weekday, start_time);


--
-- Name: student_coach_coach_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX student_coach_coach_idx ON public.student_coach USING btree (coach_id);


--
-- Name: student_competency_mastery_student_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX student_competency_mastery_student_idx ON public.student_competency_mastery USING btree (student_id);


--
-- Name: student_focus_areas_cluster_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX student_focus_areas_cluster_idx ON public.student_focus_areas USING btree (cluster_id) WHERE (active = true);


--
-- Name: student_focus_areas_student_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX student_focus_areas_student_idx ON public.student_focus_areas USING btree (student_id) WHERE (active = true);


--
-- Name: student_subscriptions_student_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX student_subscriptions_student_idx ON public.student_subscriptions USING btree (student_id);


--
-- Name: student_task_progress_student_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX student_task_progress_student_idx ON public.student_task_progress USING btree (student_id);


--
-- Name: students_lead_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX students_lead_unique ON public.students USING btree (lead_id) WHERE (lead_id IS NOT NULL);


--
-- Name: task_reviews_task_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX task_reviews_task_idx ON public.task_reviews USING btree (task_id);


--
-- Name: tasks_competency_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tasks_competency_idx ON public.tasks USING btree (competency_id);


--
-- Name: tasks_curriculum_grade_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tasks_curriculum_grade_idx ON public.tasks USING btree (curriculum_grade, status) WHERE (curriculum_grade IS NOT NULL);


--
-- Name: tasks_diagnostic_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tasks_diagnostic_idx ON public.tasks USING btree (is_diagnostic) WHERE (is_diagnostic = true);


--
-- Name: tasks_has_assets_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tasks_has_assets_idx ON public.tasks USING btree (((jsonb_array_length(assets) > 0))) WHERE (jsonb_array_length(assets) > 0);


--
-- Name: tasks_lsa_pool_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tasks_lsa_pool_idx ON public.tasks USING btree (status, input_type, afb) WHERE (status = 'ready'::text);


--
-- Name: tasks_microskill_diagnostic_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tasks_microskill_diagnostic_idx ON public.tasks USING btree (microskill_id, is_diagnostic, difficulty) WHERE (is_diagnostic = true);


--
-- Name: tasks_parts_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tasks_parts_idx ON public.tasks USING gin (parts) WHERE (input_type = 'MULTI_PART'::text);


--
-- Name: tasks_skill_key_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tasks_skill_key_idx ON public.tasks USING btree (skill_key) WHERE (skill_key IS NOT NULL);


--
-- Name: tasks_source_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tasks_source_idx ON public.tasks USING btree (source);


--
-- Name: xp_events_student_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX xp_events_student_idx ON public.xp_events USING btree (student_id);


--
-- Name: lsa_sessions lsa_session_lead_fertig_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER lsa_session_lead_fertig_trg AFTER UPDATE OF status ON public.lsa_sessions FOR EACH ROW WHEN (((new.status = 'completed'::text) AND (old.status IS DISTINCT FROM new.status))) EXECUTE FUNCTION public.lsa_session_lead_fertig();


--
-- Name: lsa_sessions lsa_session_platz_release_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER lsa_session_platz_release_trg AFTER UPDATE OF status ON public.lsa_sessions FOR EACH ROW WHEN (((new.status = ANY (ARRAY['completed'::text, 'aborted'::text])) AND (old.status IS DISTINCT FROM new.status))) EXECUTE FUNCTION public.lsa_session_platz_release();


--
-- Name: skill_kante skill_kante_tiefe; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER skill_kante_tiefe AFTER INSERT OR UPDATE ON public.skill_kante DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.skill_kante_tiefe_guard();


--
-- Name: students students_guard_provisional_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER students_guard_provisional_trg BEFORE INSERT OR UPDATE OF is_provisional ON public.students FOR EACH ROW EXECUTE FUNCTION public.students_guard_provisional();


--
-- Name: student_subscriptions subscriptions_guard_provisional_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER subscriptions_guard_provisional_trg BEFORE INSERT OR UPDATE OF student_id ON public.student_subscriptions FOR EACH ROW EXECUTE FUNCTION public.subscriptions_guard_provisional();


--
-- Name: task_solutions task_solutions_term_acceptance; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER task_solutions_term_acceptance BEFORE INSERT OR UPDATE OF acceptance, task_id ON public.task_solutions FOR EACH ROW EXECUTE FUNCTION public.lsa_term_acceptance_guard();


--
-- Name: task_solutions task_solutions_zahlen_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER task_solutions_zahlen_guard BEFORE UPDATE OF correct_answers, acceptance ON public.task_solutions FOR EACH ROW EXECUTE FUNCTION public.task_solutions_zahlen_guard();


--
-- Name: tasks tasks_term_acceptance; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tasks_term_acceptance BEFORE UPDATE OF input_type ON public.tasks FOR EACH ROW WHEN ((new.input_type = 'TERM'::text)) EXECUTE FUNCTION public.lsa_term_acceptance_guard();


--
-- Name: tasks tasks_zahlen_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tasks_zahlen_guard BEFORE UPDATE OF question ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.tasks_zahlen_guard();


--
-- Name: student_competency_mastery trg_enforce_mastery_gate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_enforce_mastery_gate BEFORE INSERT OR UPDATE ON public.student_competency_mastery FOR EACH ROW EXECUTE FUNCTION public.enforce_mastery_gate();


--
-- Name: lsa_responses trg_lsa_fehlbild_capture; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_lsa_fehlbild_capture AFTER INSERT ON public.lsa_responses FOR EACH ROW EXECUTE FUNCTION public.lsa_fehlbild_capture();


--
-- Name: xp_events xp_events_apply; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER xp_events_apply AFTER INSERT ON public.xp_events FOR EACH ROW EXECUTE FUNCTION public.apply_xp_event();


--
-- Name: behavior_snapshots behavior_snapshots_screening_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.behavior_snapshots
    ADD CONSTRAINT behavior_snapshots_screening_test_id_fkey FOREIGN KEY (screening_test_id) REFERENCES public.screening_tests(id) ON DELETE CASCADE;


--
-- Name: behavior_snapshots behavior_snapshots_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.behavior_snapshots
    ADD CONSTRAINT behavior_snapshots_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE;


--
-- Name: behavior_snapshots behavior_snapshots_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.behavior_snapshots
    ADD CONSTRAINT behavior_snapshots_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: coaching_sessions coaching_sessions_coach_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coaching_sessions
    ADD CONSTRAINT coaching_sessions_coach_id_fkey FOREIGN KEY (coach_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: coaching_sessions coaching_sessions_slot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coaching_sessions
    ADD CONSTRAINT coaching_sessions_slot_id_fkey FOREIGN KEY (slot_id) REFERENCES public.slots(id) ON DELETE SET NULL;


--
-- Name: fehlbild_familien fehlbild_familien_freigegeben_von_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fehlbild_familien
    ADD CONSTRAINT fehlbild_familien_freigegeben_von_fkey FOREIGN KEY (freigegeben_von) REFERENCES public.profiles(id);


--
-- Name: fehlbild_labels fehlbild_labels_familie_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fehlbild_labels
    ADD CONSTRAINT fehlbild_labels_familie_fkey FOREIGN KEY (familie) REFERENCES public.fehlbild_familien(schluessel) ON UPDATE CASCADE;


--
-- Name: fehlbild_labels fehlbild_labels_freigegeben_von_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fehlbild_labels
    ADD CONSTRAINT fehlbild_labels_freigegeben_von_fkey FOREIGN KEY (freigegeben_von) REFERENCES public.profiles(id);


--
-- Name: intake_sessions intake_sessions_coach_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intake_sessions
    ADD CONSTRAINT intake_sessions_coach_id_fkey FOREIGN KEY (coach_id) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: intake_sessions intake_sessions_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intake_sessions
    ADD CONSTRAINT intake_sessions_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE SET NULL;


--
-- Name: intake_sessions intake_sessions_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intake_sessions
    ADD CONSTRAINT intake_sessions_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: interventions interventions_coach_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interventions
    ADD CONSTRAINT interventions_coach_id_fkey FOREIGN KEY (coach_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: interventions interventions_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interventions
    ADD CONSTRAINT interventions_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.coaching_sessions(id) ON DELETE CASCADE;


--
-- Name: interventions interventions_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interventions
    ADD CONSTRAINT interventions_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: lead_assessments lead_assessments_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lead_assessments
    ADD CONSTRAINT lead_assessments_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- Name: leads leads_consent_dsgvo_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_consent_dsgvo_by_fkey FOREIGN KEY (consent_dsgvo_by) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: leads leads_converted_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_converted_student_id_fkey FOREIGN KEY (converted_student_id) REFERENCES public.students(id) ON DELETE SET NULL;


--
-- Name: leads leads_current_topic_cluster_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_current_topic_cluster_id_fkey FOREIGN KEY (current_topic_cluster_id) REFERENCES public.skill_clusters(id);


--
-- Name: leads leads_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: lsa_ausgegeben lsa_ausgegeben_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsa_ausgegeben
    ADD CONSTRAINT lsa_ausgegeben_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.lsa_sessions(id) ON DELETE CASCADE;


--
-- Name: lsa_ausgegeben lsa_ausgegeben_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsa_ausgegeben
    ADD CONSTRAINT lsa_ausgegeben_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id);


--
-- Name: lsa_report_notes lsa_report_notes_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsa_report_notes
    ADD CONSTRAINT lsa_report_notes_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.lsa_sessions(id) ON DELETE CASCADE;


--
-- Name: lsa_report_notes lsa_report_notes_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsa_report_notes
    ADD CONSTRAINT lsa_report_notes_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: lsa_responses lsa_responses_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsa_responses
    ADD CONSTRAINT lsa_responses_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.lsa_sessions(id) ON DELETE CASCADE;


--
-- Name: lsa_responses lsa_responses_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsa_responses
    ADD CONSTRAINT lsa_responses_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE;


--
-- Name: lsa_sessions lsa_sessions_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsa_sessions
    ADD CONSTRAINT lsa_sessions_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: lsa_sessions lsa_sessions_uebernommen_zu_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsa_sessions
    ADD CONSTRAINT lsa_sessions_uebernommen_zu_student_id_fkey FOREIGN KEY (uebernommen_zu_student_id) REFERENCES public.students(id);


--
-- Name: lsa_skill_urteil lsa_skill_urteil_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsa_skill_urteil
    ADD CONSTRAINT lsa_skill_urteil_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.lsa_sessions(id) ON DELETE CASCADE;


--
-- Name: lsa_skill_urteil lsa_skill_urteil_skill_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsa_skill_urteil
    ADD CONSTRAINT lsa_skill_urteil_skill_key_fkey FOREIGN KEY (skill_key) REFERENCES public.skills(skill_key);


--
-- Name: microskills microskills_cluster_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.microskills
    ADD CONSTRAINT microskills_cluster_id_fkey FOREIGN KEY (cluster_id) REFERENCES public.skill_clusters(id) ON DELETE CASCADE;


--
-- Name: parent_report_generations parent_report_generations_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parent_report_generations
    ADD CONSTRAINT parent_report_generations_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: parent_reports parent_reports_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parent_reports
    ADD CONSTRAINT parent_reports_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: parent_student parent_student_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parent_student
    ADD CONSTRAINT parent_student_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: parent_student parent_student_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parent_student
    ADD CONSTRAINT parent_student_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: platz_assignments platz_assignments_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platz_assignments
    ADD CONSTRAINT platz_assignments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: platz_assignments platz_assignments_platz_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platz_assignments
    ADD CONSTRAINT platz_assignments_platz_profile_id_fkey FOREIGN KEY (platz_profile_id) REFERENCES public.platz_devices(profile_id) ON DELETE CASCADE;


--
-- Name: platz_assignments platz_assignments_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platz_assignments
    ADD CONSTRAINT platz_assignments_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.lsa_sessions(id) ON DELETE CASCADE;


--
-- Name: platz_devices platz_devices_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platz_devices
    ADD CONSTRAINT platz_devices_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: profiles profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: report_bausteine report_bausteine_freigegeben_von_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_bausteine
    ADD CONSTRAINT report_bausteine_freigegeben_von_fkey FOREIGN KEY (freigegeben_von) REFERENCES public.profiles(id);


--
-- Name: screening_item_ratings screening_item_ratings_coach_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.screening_item_ratings
    ADD CONSTRAINT screening_item_ratings_coach_id_fkey FOREIGN KEY (coach_id) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: screening_item_ratings screening_item_ratings_screening_item_result_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.screening_item_ratings
    ADD CONSTRAINT screening_item_ratings_screening_item_result_id_fkey FOREIGN KEY (screening_item_result_id) REFERENCES public.screening_item_results(id) ON DELETE CASCADE;


--
-- Name: screening_item_results screening_item_results_cluster_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.screening_item_results
    ADD CONSTRAINT screening_item_results_cluster_id_fkey FOREIGN KEY (cluster_id) REFERENCES public.skill_clusters(id) ON DELETE CASCADE;


--
-- Name: screening_item_results screening_item_results_screening_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.screening_item_results
    ADD CONSTRAINT screening_item_results_screening_item_id_fkey FOREIGN KEY (screening_item_id) REFERENCES public.screening_items(id) ON DELETE CASCADE;


--
-- Name: screening_item_results screening_item_results_screening_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.screening_item_results
    ADD CONSTRAINT screening_item_results_screening_test_id_fkey FOREIGN KEY (screening_test_id) REFERENCES public.screening_tests(id) ON DELETE CASCADE;


--
-- Name: screening_items screening_items_cluster_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.screening_items
    ADD CONSTRAINT screening_items_cluster_id_fkey FOREIGN KEY (cluster_id) REFERENCES public.skill_clusters(id) ON DELETE CASCADE;


--
-- Name: screening_items screening_items_competency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.screening_items
    ADD CONSTRAINT screening_items_competency_id_fkey FOREIGN KEY (competency_id) REFERENCES public.process_competencies(id) ON DELETE SET NULL;


--
-- Name: screening_items screening_items_microskill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.screening_items
    ADD CONSTRAINT screening_items_microskill_id_fkey FOREIGN KEY (microskill_id) REFERENCES public.microskills(id) ON DELETE SET NULL;


--
-- Name: screening_ratings screening_ratings_behavior_snapshot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.screening_ratings
    ADD CONSTRAINT screening_ratings_behavior_snapshot_id_fkey FOREIGN KEY (behavior_snapshot_id) REFERENCES public.behavior_snapshots(id) ON DELETE CASCADE;


--
-- Name: screening_ratings screening_ratings_coach_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.screening_ratings
    ADD CONSTRAINT screening_ratings_coach_id_fkey FOREIGN KEY (coach_id) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: screening_ratings screening_ratings_screening_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.screening_ratings
    ADD CONSTRAINT screening_ratings_screening_test_id_fkey FOREIGN KEY (screening_test_id) REFERENCES public.screening_tests(id) ON DELETE CASCADE;


--
-- Name: screening_tests screening_tests_coach_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.screening_tests
    ADD CONSTRAINT screening_tests_coach_id_fkey FOREIGN KEY (coach_id) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: screening_tests screening_tests_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.screening_tests
    ADD CONSTRAINT screening_tests_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: session_students session_students_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_students
    ADD CONSTRAINT session_students_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.coaching_sessions(id) ON DELETE CASCADE;


--
-- Name: session_students session_students_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_students
    ADD CONSTRAINT session_students_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: skill_clusters skill_clusters_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_clusters
    ADD CONSTRAINT skill_clusters_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE CASCADE;


--
-- Name: skill_kante skill_kante_skill_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_kante
    ADD CONSTRAINT skill_kante_skill_key_fkey FOREIGN KEY (skill_key) REFERENCES public.skills(skill_key) ON DELETE CASCADE;


--
-- Name: skill_kante skill_kante_voraussetzt_skill_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_kante
    ADD CONSTRAINT skill_kante_voraussetzt_skill_key_fkey FOREIGN KEY (voraussetzt_skill_key) REFERENCES public.skills(skill_key) ON DELETE CASCADE;


--
-- Name: skill_voraussetzung skill_voraussetzung_skill_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_voraussetzung
    ADD CONSTRAINT skill_voraussetzung_skill_key_fkey FOREIGN KEY (skill_key) REFERENCES public.skills(skill_key) ON DELETE CASCADE;


--
-- Name: skill_voraussetzung skill_voraussetzung_thema_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_voraussetzung
    ADD CONSTRAINT skill_voraussetzung_thema_key_fkey FOREIGN KEY (thema_key) REFERENCES public.themen(thema_key) ON DELETE CASCADE;


--
-- Name: slot_assignments slot_assignments_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slot_assignments
    ADD CONSTRAINT slot_assignments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: slot_assignments slot_assignments_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slot_assignments
    ADD CONSTRAINT slot_assignments_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- Name: slot_assignments slot_assignments_slot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slot_assignments
    ADD CONSTRAINT slot_assignments_slot_id_fkey FOREIGN KEY (slot_id) REFERENCES public.slots(id) ON DELETE CASCADE;


--
-- Name: slot_wishes slot_wishes_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slot_wishes
    ADD CONSTRAINT slot_wishes_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- Name: slot_wishes slot_wishes_slot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slot_wishes
    ADD CONSTRAINT slot_wishes_slot_id_fkey FOREIGN KEY (slot_id) REFERENCES public.slots(id) ON DELETE CASCADE;


--
-- Name: streak_repair_inventory streak_repair_inventory_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.streak_repair_inventory
    ADD CONSTRAINT streak_repair_inventory_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: student_badges student_badges_badge_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_badges
    ADD CONSTRAINT student_badges_badge_id_fkey FOREIGN KEY (badge_id) REFERENCES public.badge_catalog(id);


--
-- Name: student_badges student_badges_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_badges
    ADD CONSTRAINT student_badges_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: student_coach student_coach_coach_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_coach
    ADD CONSTRAINT student_coach_coach_id_fkey FOREIGN KEY (coach_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: student_coach student_coach_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_coach
    ADD CONSTRAINT student_coach_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: student_competency_mastery student_competency_mastery_competency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_competency_mastery
    ADD CONSTRAINT student_competency_mastery_competency_id_fkey FOREIGN KEY (competency_id) REFERENCES public.process_competencies(id) ON DELETE CASCADE;


--
-- Name: student_competency_mastery student_competency_mastery_mastered_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_competency_mastery
    ADD CONSTRAINT student_competency_mastery_mastered_by_fkey FOREIGN KEY (mastered_by) REFERENCES public.profiles(id);


--
-- Name: student_competency_mastery student_competency_mastery_microskill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_competency_mastery
    ADD CONSTRAINT student_competency_mastery_microskill_id_fkey FOREIGN KEY (microskill_id) REFERENCES public.microskills(id) ON DELETE CASCADE;


--
-- Name: student_competency_mastery student_competency_mastery_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_competency_mastery
    ADD CONSTRAINT student_competency_mastery_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: student_focus_areas student_focus_areas_cluster_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_focus_areas
    ADD CONSTRAINT student_focus_areas_cluster_id_fkey FOREIGN KEY (cluster_id) REFERENCES public.skill_clusters(id) ON DELETE CASCADE;


--
-- Name: student_focus_areas student_focus_areas_coach_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_focus_areas
    ADD CONSTRAINT student_focus_areas_coach_id_fkey FOREIGN KEY (coach_id) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: student_focus_areas student_focus_areas_herkunfts_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_focus_areas
    ADD CONSTRAINT student_focus_areas_herkunfts_session_id_fkey FOREIGN KEY (herkunfts_session_id) REFERENCES public.lsa_sessions(id) ON DELETE SET NULL;


--
-- Name: student_focus_areas student_focus_areas_skill_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_focus_areas
    ADD CONSTRAINT student_focus_areas_skill_key_fkey FOREIGN KEY (skill_key) REFERENCES public.skills(skill_key);


--
-- Name: student_focus_areas student_focus_areas_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_focus_areas
    ADD CONSTRAINT student_focus_areas_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: student_progress student_progress_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_progress
    ADD CONSTRAINT student_progress_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: student_subjects student_subjects_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_subjects
    ADD CONSTRAINT student_subjects_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: student_subjects student_subjects_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_subjects
    ADD CONSTRAINT student_subjects_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE CASCADE;


--
-- Name: student_subscriptions student_subscriptions_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_subscriptions
    ADD CONSTRAINT student_subscriptions_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: student_subscriptions student_subscriptions_tier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_subscriptions
    ADD CONSTRAINT student_subscriptions_tier_id_fkey FOREIGN KEY (tier_id) REFERENCES public.tiers(id);


--
-- Name: student_task_progress student_task_progress_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_task_progress
    ADD CONSTRAINT student_task_progress_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: student_task_progress student_task_progress_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_task_progress
    ADD CONSTRAINT student_task_progress_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE;


--
-- Name: students students_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- Name: students students_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: task_coach_metadata task_coach_metadata_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_coach_metadata
    ADD CONSTRAINT task_coach_metadata_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE;


--
-- Name: task_figures task_figures_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_figures
    ADD CONSTRAINT task_figures_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE;


--
-- Name: task_reviews task_reviews_geprueft_von_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_reviews
    ADD CONSTRAINT task_reviews_geprueft_von_fkey FOREIGN KEY (geprueft_von) REFERENCES public.profiles(id);


--
-- Name: task_reviews task_reviews_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_reviews
    ADD CONSTRAINT task_reviews_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE;


--
-- Name: task_solutions task_solutions_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_solutions
    ADD CONSTRAINT task_solutions_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE;


--
-- Name: tasks tasks_cluster_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_cluster_id_fkey FOREIGN KEY (cluster_id) REFERENCES public.skill_clusters(id) ON DELETE SET NULL;


--
-- Name: tasks tasks_competency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_competency_id_fkey FOREIGN KEY (competency_id) REFERENCES public.process_competencies(id) ON DELETE SET NULL;


--
-- Name: tasks tasks_microskill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_microskill_id_fkey FOREIGN KEY (microskill_id) REFERENCES public.microskills(id) ON DELETE SET NULL;


--
-- Name: tasks tasks_reviewed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: tasks tasks_skill_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_skill_key_fkey FOREIGN KEY (skill_key) REFERENCES public.skills(skill_key);


--
-- Name: xp_events xp_events_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.xp_events
    ADD CONSTRAINT xp_events_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: xp_events xp_events_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.xp_events
    ADD CONSTRAINT xp_events_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE SET NULL;


--
-- Name: tasks admin_write_tasks; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY admin_write_tasks ON public.tasks USING ((EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = 'admin'::text)))));


--
-- Name: skill_clusters authenticated_read_clusters; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY authenticated_read_clusters ON public.skill_clusters FOR SELECT USING ((auth.role() = 'authenticated'::text));


--
-- Name: microskills authenticated_read_microskills; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY authenticated_read_microskills ON public.microskills FOR SELECT USING ((auth.role() = 'authenticated'::text));


--
-- Name: process_competencies authenticated_read_process_competencies; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY authenticated_read_process_competencies ON public.process_competencies FOR SELECT USING ((auth.role() = 'authenticated'::text));


--
-- Name: subjects authenticated_read_subjects; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY authenticated_read_subjects ON public.subjects FOR SELECT USING ((auth.role() = 'authenticated'::text));


--
-- Name: badge_catalog; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.badge_catalog ENABLE ROW LEVEL SECURITY;

--
-- Name: badge_catalog badge_catalog_admin_write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY badge_catalog_admin_write ON public.badge_catalog USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


--
-- Name: badge_catalog badge_catalog_read_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY badge_catalog_read_all ON public.badge_catalog FOR SELECT USING (true);


--
-- Name: behavior_snapshots; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.behavior_snapshots ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles coaches_admins_see_all_profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY coaches_admins_see_all_profiles ON public.profiles FOR SELECT USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: behavior_snapshots coaches_admins_see_all_snapshots; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY coaches_admins_see_all_snapshots ON public.behavior_snapshots FOR SELECT USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: task_coach_metadata coaches_read_task_metadata; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY coaches_read_task_metadata ON public.task_coach_metadata FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['coach'::text, 'admin'::text]))))));


--
-- Name: coaching_sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.coaching_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: coaching_sessions coaching_sessions_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY coaching_sessions_admin_all ON public.coaching_sessions USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


--
-- Name: coaching_sessions coaching_sessions_coach_rw; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY coaching_sessions_coach_rw ON public.coaching_sessions USING ((coach_id = auth.uid())) WITH CHECK ((coach_id = auth.uid()));


--
-- Name: coaching_sessions coaching_sessions_parent_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY coaching_sessions_parent_read ON public.coaching_sessions FOR SELECT USING ((id IN ( SELECT ss.session_id
   FROM public.session_students ss
  WHERE public.is_parent_of_student(ss.student_id))));


--
-- Name: coaching_sessions coaching_sessions_student_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY coaching_sessions_student_read ON public.coaching_sessions FOR SELECT USING ((id IN ( SELECT session_students.session_id
   FROM public.session_students
  WHERE (session_students.student_id = public.get_my_student_id()))));


--
-- Name: fehlbild_familien; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.fehlbild_familien ENABLE ROW LEVEL SECURITY;

--
-- Name: fehlbild_familien fehlbild_familien_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY fehlbild_familien_read ON public.fehlbild_familien FOR SELECT USING ((public.get_my_role() = ANY (ARRAY['admin'::text, 'coach'::text])));


--
-- Name: fehlbild_labels; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.fehlbild_labels ENABLE ROW LEVEL SECURITY;

--
-- Name: fehlbild_labels fehlbild_labels_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY fehlbild_labels_read ON public.fehlbild_labels FOR SELECT USING ((public.get_my_role() = ANY (ARRAY['admin'::text, 'coach'::text])));


--
-- Name: intake_sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.intake_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: intake_sessions intake_sessions_coach_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY intake_sessions_coach_admin_all ON public.intake_sessions USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text]))) WITH CHECK ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: intake_sessions intake_sessions_parent_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY intake_sessions_parent_read ON public.intake_sessions FOR SELECT USING (public.is_parent_of_student(student_id));


--
-- Name: interventions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.interventions ENABLE ROW LEVEL SECURITY;

--
-- Name: interventions interventions_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY interventions_admin_all ON public.interventions USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


--
-- Name: interventions interventions_coach_rw; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY interventions_coach_rw ON public.interventions USING ((session_id IN ( SELECT coaching_sessions.id
   FROM public.coaching_sessions
  WHERE (coaching_sessions.coach_id = auth.uid())))) WITH CHECK ((session_id IN ( SELECT coaching_sessions.id
   FROM public.coaching_sessions
  WHERE (coaching_sessions.coach_id = auth.uid()))));


--
-- Name: interventions interventions_parent_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY interventions_parent_read ON public.interventions FOR SELECT USING (public.is_parent_of_student(student_id));


--
-- Name: lead_assessments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lead_assessments ENABLE ROW LEVEL SECURITY;

--
-- Name: lead_assessments lead_assessments_coach_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lead_assessments_coach_admin_all ON public.lead_assessments USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text]))) WITH CHECK ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: leads; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;

--
-- Name: leads leads_coach_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY leads_coach_admin_all ON public.leads USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text]))) WITH CHECK ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: lsa_ausgegeben; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lsa_ausgegeben ENABLE ROW LEVEL SECURITY;

--
-- Name: lsa_ausgegeben lsa_ausgegeben_coach_admin_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lsa_ausgegeben_coach_admin_read ON public.lsa_ausgegeben FOR SELECT USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: lsa_ausgegeben lsa_ausgegeben_parent_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lsa_ausgegeben_parent_read ON public.lsa_ausgegeben FOR SELECT USING ((session_id IN ( SELECT lsa_sessions.id
   FROM public.lsa_sessions
  WHERE public.is_parent_of_student(lsa_sessions.student_id))));


--
-- Name: lsa_report_notes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lsa_report_notes ENABLE ROW LEVEL SECURITY;

--
-- Name: lsa_report_notes lsa_report_notes_coach_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lsa_report_notes_coach_admin_all ON public.lsa_report_notes USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text]))) WITH CHECK ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: lsa_responses; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lsa_responses ENABLE ROW LEVEL SECURITY;

--
-- Name: lsa_responses lsa_responses_coach_admin_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lsa_responses_coach_admin_read ON public.lsa_responses FOR SELECT USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: lsa_responses lsa_responses_parent_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lsa_responses_parent_read ON public.lsa_responses FOR SELECT USING ((session_id IN ( SELECT lsa_sessions.id
   FROM public.lsa_sessions
  WHERE public.is_parent_of_student(lsa_sessions.student_id))));


--
-- Name: lsa_sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lsa_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: lsa_sessions lsa_sessions_coach_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lsa_sessions_coach_admin_all ON public.lsa_sessions USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text]))) WITH CHECK ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: lsa_sessions lsa_sessions_parent_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lsa_sessions_parent_read ON public.lsa_sessions FOR SELECT USING (public.is_parent_of_student(student_id));


--
-- Name: lsa_skill_urteil; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lsa_skill_urteil ENABLE ROW LEVEL SECURITY;

--
-- Name: lsa_skill_urteil lsa_skill_urteil_coach_admin_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lsa_skill_urteil_coach_admin_read ON public.lsa_skill_urteil FOR SELECT USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: lsa_skill_urteil lsa_skill_urteil_parent_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lsa_skill_urteil_parent_read ON public.lsa_skill_urteil FOR SELECT USING ((session_id IN ( SELECT lsa_sessions.id
   FROM public.lsa_sessions
  WHERE public.is_parent_of_student(lsa_sessions.student_id))));


--
-- Name: microskills; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.microskills ENABLE ROW LEVEL SECURITY;

--
-- Name: parent_report_generations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.parent_report_generations ENABLE ROW LEVEL SECURITY;

--
-- Name: parent_reports; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.parent_reports ENABLE ROW LEVEL SECURITY;

--
-- Name: parent_reports parent_reports_coach_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY parent_reports_coach_admin_all ON public.parent_reports USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text]))) WITH CHECK ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: parent_reports parent_reports_parent_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY parent_reports_parent_read ON public.parent_reports FOR SELECT USING (((status = 'published'::text) AND public.is_parent_of_student(student_id)));


--
-- Name: parent_reports parent_reports_student_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY parent_reports_student_read ON public.parent_reports FOR SELECT USING (((status = 'published'::text) AND (student_id = public.get_my_student_id())));


--
-- Name: parent_student; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.parent_student ENABLE ROW LEVEL SECURITY;

--
-- Name: parent_student parent_student_coach_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY parent_student_coach_admin_all ON public.parent_student USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text]))) WITH CHECK ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: parent_student parent_student_parent_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY parent_student_parent_read ON public.parent_student FOR SELECT USING ((parent_id = auth.uid()));


--
-- Name: parent_student parent_student_student_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY parent_student_student_read ON public.parent_student FOR SELECT USING ((student_id = auth.uid()));


--
-- Name: profiles parents_see_own_children; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY parents_see_own_children ON public.profiles FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.parent_student ps
  WHERE ((ps.parent_id = auth.uid()) AND (ps.student_id = profiles.id)))));


--
-- Name: platz_assignments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.platz_assignments ENABLE ROW LEVEL SECURITY;

--
-- Name: platz_assignments platz_assignments_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY platz_assignments_admin_all ON public.platz_assignments USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


--
-- Name: platz_assignments platz_assignments_select_own_active; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY platz_assignments_select_own_active ON public.platz_assignments FOR SELECT USING (((platz_profile_id = auth.uid()) AND (released_at IS NULL) AND (expires_at > now())));


--
-- Name: platz_devices; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.platz_devices ENABLE ROW LEVEL SECURITY;

--
-- Name: platz_devices platz_devices_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY platz_devices_admin_all ON public.platz_devices USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


--
-- Name: platz_devices platz_devices_select_self; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY platz_devices_select_self ON public.platz_devices FOR SELECT USING ((profile_id = auth.uid()));


--
-- Name: parent_report_generations prg_coach_admin_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY prg_coach_admin_read ON public.parent_report_generations FOR SELECT USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: process_competencies; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.process_competencies ENABLE ROW LEVEL SECURITY;

--
-- Name: process_competencies process_competencies_admin_write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY process_competencies_admin_write ON public.process_competencies USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: tasks read_tasks_by_role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY read_tasks_by_role ON public.tasks FOR SELECT USING (((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])) OR ((public.get_my_role() IS NOT NULL) AND (status = 'ready'::text))));


--
-- Name: report_anlass_zuordnung; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.report_anlass_zuordnung ENABLE ROW LEVEL SECURITY;

--
-- Name: report_anlass_zuordnung report_anlass_zuordnung_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY report_anlass_zuordnung_read ON public.report_anlass_zuordnung FOR SELECT USING ((public.get_my_role() = ANY (ARRAY['admin'::text, 'coach'::text])));


--
-- Name: report_bausteine; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.report_bausteine ENABLE ROW LEVEL SECURITY;

--
-- Name: report_bausteine report_bausteine_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY report_bausteine_read ON public.report_bausteine FOR SELECT USING ((public.get_my_role() = ANY (ARRAY['admin'::text, 'coach'::text])));


--
-- Name: student_competency_mastery scm_coach_admin_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY scm_coach_admin_insert ON public.student_competency_mastery FOR INSERT WITH CHECK ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: student_competency_mastery scm_coach_admin_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY scm_coach_admin_read ON public.student_competency_mastery FOR SELECT USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: student_competency_mastery scm_coach_admin_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY scm_coach_admin_update ON public.student_competency_mastery FOR UPDATE USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text]))) WITH CHECK ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: student_competency_mastery scm_parent_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY scm_parent_read ON public.student_competency_mastery FOR SELECT USING (public.is_parent_of_student(student_id));


--
-- Name: student_competency_mastery scm_student_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY scm_student_read ON public.student_competency_mastery FOR SELECT USING ((student_id = public.get_my_student_id()));


--
-- Name: screening_item_ratings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.screening_item_ratings ENABLE ROW LEVEL SECURITY;

--
-- Name: screening_item_ratings screening_item_ratings_coach_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY screening_item_ratings_coach_insert ON public.screening_item_ratings FOR INSERT WITH CHECK ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: screening_item_ratings screening_item_ratings_coach_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY screening_item_ratings_coach_read ON public.screening_item_ratings FOR SELECT USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: screening_item_results; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.screening_item_results ENABLE ROW LEVEL SECURITY;

--
-- Name: screening_item_results screening_item_results_coach_admin_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY screening_item_results_coach_admin_read ON public.screening_item_results FOR SELECT USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: screening_item_results screening_item_results_insert_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY screening_item_results_insert_own ON public.screening_item_results FOR INSERT WITH CHECK ((screening_test_id IN ( SELECT screening_tests.id
   FROM public.screening_tests
  WHERE (screening_tests.student_id = public.get_my_student_id()))));


--
-- Name: screening_item_results screening_item_results_parent_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY screening_item_results_parent_read ON public.screening_item_results FOR SELECT USING ((screening_test_id IN ( SELECT screening_tests.id
   FROM public.screening_tests
  WHERE public.is_parent_of_student(screening_tests.student_id))));


--
-- Name: screening_item_results screening_item_results_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY screening_item_results_select_own ON public.screening_item_results FOR SELECT USING ((screening_test_id IN ( SELECT screening_tests.id
   FROM public.screening_tests
  WHERE (screening_tests.student_id = public.get_my_student_id()))));


--
-- Name: screening_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.screening_items ENABLE ROW LEVEL SECURITY;

--
-- Name: screening_items screening_items_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY screening_items_admin_all ON public.screening_items USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


--
-- Name: screening_items screening_items_coach_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY screening_items_coach_read ON public.screening_items FOR SELECT USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: screening_items screening_items_read_active; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY screening_items_read_active ON public.screening_items FOR SELECT USING (((auth.role() = 'authenticated'::text) AND (active = true)));


--
-- Name: screening_ratings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.screening_ratings ENABLE ROW LEVEL SECURITY;

--
-- Name: screening_ratings screening_ratings_coach_admin_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY screening_ratings_coach_admin_read ON public.screening_ratings FOR SELECT USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: screening_ratings screening_ratings_coach_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY screening_ratings_coach_insert ON public.screening_ratings FOR INSERT WITH CHECK ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: screening_ratings screening_ratings_parent_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY screening_ratings_parent_read ON public.screening_ratings FOR SELECT USING ((screening_test_id IN ( SELECT screening_tests.id
   FROM public.screening_tests
  WHERE public.is_parent_of_student(screening_tests.student_id))));


--
-- Name: screening_ratings screening_ratings_student_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY screening_ratings_student_read ON public.screening_ratings FOR SELECT USING ((screening_test_id IN ( SELECT screening_tests.id
   FROM public.screening_tests
  WHERE (screening_tests.student_id = public.get_my_student_id()))));


--
-- Name: screening_tests; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.screening_tests ENABLE ROW LEVEL SECURITY;

--
-- Name: screening_tests screening_tests_coach_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY screening_tests_coach_admin_all ON public.screening_tests USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text]))) WITH CHECK ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: screening_tests screening_tests_parent_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY screening_tests_parent_read ON public.screening_tests FOR SELECT USING (public.is_parent_of_student(student_id));


--
-- Name: screening_tests screening_tests_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY screening_tests_select_own ON public.screening_tests FOR SELECT USING ((student_id = public.get_my_student_id()));


--
-- Name: screening_tests screening_tests_student_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY screening_tests_student_insert ON public.screening_tests FOR INSERT WITH CHECK ((student_id = public.get_my_student_id()));


--
-- Name: screening_tests screening_tests_student_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY screening_tests_student_update ON public.screening_tests FOR UPDATE USING ((student_id = public.get_my_student_id())) WITH CHECK ((student_id = public.get_my_student_id()));


--
-- Name: session_students; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.session_students ENABLE ROW LEVEL SECURITY;

--
-- Name: session_students session_students_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY session_students_admin_all ON public.session_students USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


--
-- Name: session_students session_students_coach_rw; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY session_students_coach_rw ON public.session_students USING ((session_id IN ( SELECT coaching_sessions.id
   FROM public.coaching_sessions
  WHERE (coaching_sessions.coach_id = auth.uid())))) WITH CHECK ((session_id IN ( SELECT coaching_sessions.id
   FROM public.coaching_sessions
  WHERE (coaching_sessions.coach_id = auth.uid()))));


--
-- Name: session_students session_students_parent_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY session_students_parent_read ON public.session_students FOR SELECT USING (public.is_parent_of_student(student_id));


--
-- Name: session_students session_students_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY session_students_select_own ON public.session_students FOR SELECT USING ((student_id = public.get_my_student_id()));


--
-- Name: skill_clusters; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.skill_clusters ENABLE ROW LEVEL SECURITY;

--
-- Name: skill_kante; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.skill_kante ENABLE ROW LEVEL SECURITY;

--
-- Name: skill_kante skill_kante_read_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY skill_kante_read_all ON public.skill_kante FOR SELECT TO anon, authenticated, service_role USING (true);


--
-- Name: skill_voraussetzung; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.skill_voraussetzung ENABLE ROW LEVEL SECURITY;

--
-- Name: skill_voraussetzung skill_voraussetzung_read_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY skill_voraussetzung_read_all ON public.skill_voraussetzung FOR SELECT TO anon, authenticated, service_role USING (true);


--
-- Name: skills; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.skills ENABLE ROW LEVEL SECURITY;

--
-- Name: skills skills_read_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY skills_read_all ON public.skills FOR SELECT TO anon, authenticated, service_role USING (true);


--
-- Name: slot_assignments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.slot_assignments ENABLE ROW LEVEL SECURITY;

--
-- Name: slot_assignments slot_assignments_coach_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY slot_assignments_coach_admin_all ON public.slot_assignments USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text]))) WITH CHECK ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: slot_wishes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.slot_wishes ENABLE ROW LEVEL SECURITY;

--
-- Name: slot_wishes slot_wishes_coach_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY slot_wishes_coach_admin_all ON public.slot_wishes USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text]))) WITH CHECK ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: slots; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.slots ENABLE ROW LEVEL SECURITY;

--
-- Name: slots slots_coach_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY slots_coach_admin_all ON public.slots USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text]))) WITH CHECK ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: streak_repair_inventory streak_repair_admin_write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY streak_repair_admin_write ON public.streak_repair_inventory USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


--
-- Name: streak_repair_inventory; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.streak_repair_inventory ENABLE ROW LEVEL SECURITY;

--
-- Name: streak_repair_inventory streak_repair_self_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY streak_repair_self_read ON public.streak_repair_inventory FOR SELECT USING (((student_id IN ( SELECT students.id
   FROM public.students
  WHERE (students.profile_id = auth.uid()))) OR (public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text]))));


--
-- Name: student_badges; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.student_badges ENABLE ROW LEVEL SECURITY;

--
-- Name: student_badges student_badges_admin_write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_badges_admin_write ON public.student_badges USING ((public.get_my_role() = ANY (ARRAY['admin'::text, 'coach'::text]))) WITH CHECK ((public.get_my_role() = ANY (ARRAY['admin'::text, 'coach'::text])));


--
-- Name: student_badges student_badges_self_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_badges_self_read ON public.student_badges FOR SELECT USING (((student_id IN ( SELECT students.id
   FROM public.students
  WHERE (students.profile_id = auth.uid()))) OR (public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])) OR (EXISTS ( SELECT 1
   FROM public.parent_student ps
  WHERE ((ps.student_id = student_badges.student_id) AND (ps.parent_id = auth.uid()))))));


--
-- Name: student_coach; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.student_coach ENABLE ROW LEVEL SECURITY;

--
-- Name: student_coach student_coach_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_coach_admin_all ON public.student_coach USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


--
-- Name: student_coach student_coach_coach_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_coach_coach_read ON public.student_coach FOR SELECT USING ((coach_id = auth.uid()));


--
-- Name: student_coach student_coach_parent_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_coach_parent_read ON public.student_coach FOR SELECT USING (public.is_parent_of_student(student_id));


--
-- Name: student_coach student_coach_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_coach_select_own ON public.student_coach FOR SELECT USING ((student_id = public.get_my_student_id()));


--
-- Name: student_competency_mastery; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.student_competency_mastery ENABLE ROW LEVEL SECURITY;

--
-- Name: student_focus_areas; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.student_focus_areas ENABLE ROW LEVEL SECURITY;

--
-- Name: student_focus_areas student_focus_areas_coach_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_focus_areas_coach_all ON public.student_focus_areas USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text]))) WITH CHECK ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: student_focus_areas student_focus_areas_parent_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_focus_areas_parent_read ON public.student_focus_areas FOR SELECT USING (((public.get_my_role() = 'parent'::text) AND (EXISTS ( SELECT 1
   FROM public.students s
  WHERE ((s.id = student_focus_areas.student_id) AND public.is_parent_of_student(s.id))))));


--
-- Name: student_progress; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.student_progress ENABLE ROW LEVEL SECURITY;

--
-- Name: student_progress student_progress_coach_admin_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_progress_coach_admin_read ON public.student_progress FOR SELECT USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: student_progress student_progress_parent_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_progress_parent_read ON public.student_progress FOR SELECT USING (public.is_parent_of_student(student_id));


--
-- Name: student_progress student_progress_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_progress_select_own ON public.student_progress FOR SELECT USING ((student_id = public.get_my_student_id()));


--
-- Name: student_subjects; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.student_subjects ENABLE ROW LEVEL SECURITY;

--
-- Name: student_subjects student_subjects_coach_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_subjects_coach_admin_all ON public.student_subjects USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text]))) WITH CHECK ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: student_subjects student_subjects_parents_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_subjects_parents_read ON public.student_subjects FOR SELECT USING (public.is_parent_of_student(student_id));


--
-- Name: student_subjects student_subjects_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_subjects_select_own ON public.student_subjects FOR SELECT USING ((student_id = public.get_my_student_id()));


--
-- Name: student_subscriptions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.student_subscriptions ENABLE ROW LEVEL SECURITY;

--
-- Name: student_subscriptions student_subscriptions_coach_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_subscriptions_coach_admin_all ON public.student_subscriptions USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text]))) WITH CHECK ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: student_subscriptions student_subscriptions_parent_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_subscriptions_parent_read ON public.student_subscriptions FOR SELECT USING (public.is_parent_of_student(student_id));


--
-- Name: student_subscriptions student_subscriptions_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_subscriptions_select_own ON public.student_subscriptions FOR SELECT USING ((student_id = public.get_my_student_id()));


--
-- Name: student_task_progress; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.student_task_progress ENABLE ROW LEVEL SECURITY;

--
-- Name: student_task_progress student_task_progress_coach_admin_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_task_progress_coach_admin_read ON public.student_task_progress FOR SELECT USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: student_task_progress student_task_progress_own_rw; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_task_progress_own_rw ON public.student_task_progress USING ((student_id = public.get_my_student_id())) WITH CHECK ((student_id = public.get_my_student_id()));


--
-- Name: student_task_progress student_task_progress_parent_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_task_progress_parent_read ON public.student_task_progress FOR SELECT USING (public.is_parent_of_student(student_id));


--
-- Name: students; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;

--
-- Name: students students_coach_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY students_coach_admin_all ON public.students USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text]))) WITH CHECK ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: students students_parents_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY students_parents_read ON public.students FOR SELECT USING (public.is_parent_of_student(id));


--
-- Name: students students_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY students_select_own ON public.students FOR SELECT USING ((profile_id = auth.uid()));


--
-- Name: subjects; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;

--
-- Name: task_coach_metadata; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.task_coach_metadata ENABLE ROW LEVEL SECURITY;

--
-- Name: task_figures; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.task_figures ENABLE ROW LEVEL SECURITY;

--
-- Name: task_reviews; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.task_reviews ENABLE ROW LEVEL SECURITY;

--
-- Name: task_reviews task_reviews_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY task_reviews_read ON public.task_reviews FOR SELECT USING ((public.get_my_role() = ANY (ARRAY['admin'::text, 'coach'::text])));


--
-- Name: task_solutions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.task_solutions ENABLE ROW LEVEL SECURITY;

--
-- Name: tasks; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

--
-- Name: themen; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.themen ENABLE ROW LEVEL SECURITY;

--
-- Name: themen themen_read_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY themen_read_all ON public.themen FOR SELECT TO anon, authenticated, service_role USING (true);


--
-- Name: tiers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.tiers ENABLE ROW LEVEL SECURITY;

--
-- Name: tiers tiers_admin_write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tiers_admin_write ON public.tiers USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


--
-- Name: tiers tiers_authenticated_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tiers_authenticated_read ON public.tiers FOR SELECT USING ((auth.role() = 'authenticated'::text));


--
-- Name: behavior_snapshots users_insert_own_snapshots; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY users_insert_own_snapshots ON public.behavior_snapshots FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: profiles users_see_own_profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY users_see_own_profile ON public.profiles FOR SELECT USING ((auth.uid() = id));


--
-- Name: behavior_snapshots users_see_own_snapshots; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY users_see_own_snapshots ON public.behavior_snapshots FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: xp_events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.xp_events ENABLE ROW LEVEL SECURITY;

--
-- Name: xp_events xp_events_coach_admin_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY xp_events_coach_admin_read ON public.xp_events FOR SELECT USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- Name: xp_events xp_events_insert_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY xp_events_insert_own ON public.xp_events FOR INSERT WITH CHECK ((student_id = public.get_my_student_id()));


--
-- Name: xp_events xp_events_parent_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY xp_events_parent_read ON public.xp_events FOR SELECT USING (public.is_parent_of_student(student_id));


--
-- Name: xp_events xp_events_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY xp_events_select_own ON public.xp_events FOR SELECT USING ((student_id = public.get_my_student_id()));


--
-- Name: xp_rules; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.xp_rules ENABLE ROW LEVEL SECURITY;

--
-- Name: xp_rules xp_rules_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY xp_rules_admin_all ON public.xp_rules USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


--
-- Name: xp_rules xp_rules_staff_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY xp_rules_staff_read ON public.xp_rules FOR SELECT USING ((public.get_my_role() = ANY (ARRAY['coach'::text, 'admin'::text])));


--
-- PostgreSQL database dump complete
--


