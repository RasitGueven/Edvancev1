-- schema-erwartet.sql
-- Erzeugt von tools/schema-snapshot.sh (read-only Abzug der Ziel-DB, Schema public).
-- Nicht von Hand bearbeiten — nach dem Einspielen einer Schemaaenderung neu erzeugen.

--
-- PostgreSQL database dump
--


-- Dumped from database version 17.6
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
-- Name: akte_aktiv(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.akte_aktiv(p_student_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  select exists (
    select 1
      from public.vertraege_aktuell v
     where v.student_id = p_student_id
       and v.wirksamer_status in ('aktiv', 'im_widerruf')
  );
$$;


--
-- Name: akte_basis(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.akte_basis() RETURNS TABLE(student_id uuid, name text, klasse integer, schule_id uuid, schule text, akte_seit date, zustand text, ruhend_seit date, letzte_session timestamp with time zone)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  with ich as (
    select coalesce(public.get_my_role(), '') as rolle
  ),
  vertrag as (
    select v.student_id,
           min(v.abgeschlossen_am) as akte_seit,
           bool_or(v.wirksamer_status in ('aktiv', 'im_widerruf')) as aktiv,
           -- Ende des letzten Vertrags, der gelaufen ist: gekuendigt_zum vor
           -- vertrag_ende; ein widerrufener Vertrag ist nie gelaufen und zaehlt
           -- nur, wenn es keinen anderen gibt (dann ab dem Widerruf).
           coalesce(max(coalesce(v.gekuendigt_zum, v.vertrag_ende)) filter (where v.widerrufen_am is null),
                    max(v.widerrufen_am)) as letztes_ende,
           (array_agg(nullif(btrim(concat_ws(' ', v.kind_vorname, v.kind_nachname)), '')
                      order by v.vertragsbeginn desc nulls last))[1] as kindname
      from public.vertraege_aktuell v
     where v.student_id is not null
     group by v.student_id
  ),
  anwesend as (
    select ss.student_id, max(cs.scheduled_at) as letzte_session
      from public.session_students ss
      join public.coaching_sessions cs on cs.id = ss.session_id
     where ss.attendance = 'present'
       and not cs.testlauf
     group by ss.student_id
  )
  select s.id,
         coalesce(nullif(btrim(p.full_name), ''), vt.kindname),
         s.class_level,
         s.schule_id,
         coalesce(sch.name, s.school_name),
         vt.akte_seit,
         case when vt.aktiv then 'aktiv' else 'ruhend' end,
         case when vt.aktiv then null else vt.letztes_ende end,
         a.letzte_session
    from vertrag vt
    join public.students s   on s.id = vt.student_id
    left join public.profiles p   on p.id = s.profile_id
    left join public.schulen  sch on sch.id = s.schule_id
    left join anwesend a on a.student_id = s.id
    cross join ich
   where ich.rolle = 'admin'
      or (ich.rolle = 'coach' and vt.aktiv);
$$;


--
-- Name: akte_sessions(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.akte_sessions(p_student_id uuid) RETURNS TABLE(session_id uuid, scheduled_at timestamp with time zone, coach_id uuid, coach_name text, attendance text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_rolle text := coalesce(public.get_my_role(), '');
  v_seit  date;
begin
  if v_rolle = 'admin' then
    null;
  elsif v_rolle = 'coach' and public.akte_aktiv(p_student_id) then
    null;
  else
    raise exception 'akte_sessions: keine Berechtigung fuer diese Akte' using errcode = '42501';
  end if;

  select min(v.abgeschlossen_am) into v_seit
    from public.vertraege v
   where v.student_id = p_student_id and v.status = 'abgeschlossen';

  return query
    select cs.id, cs.scheduled_at, cs.coach_id, p.full_name, ss.attendance
      from public.session_students ss
      join public.coaching_sessions cs on cs.id = ss.session_id
      left join public.profiles p on p.id = cs.coach_id
     where ss.student_id = p_student_id
       and not cs.testlauf
       and v_seit is not null
       and (cs.scheduled_at at time zone 'Europe/Berlin')::date >= v_seit
     order by cs.scheduled_at desc;
end;
$$;


--
-- Name: akte_stammdaten_aendern(uuid, text, integer, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.akte_stammdaten_aendern(p_student_id uuid, p_name text, p_klasse integer, p_schule_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_profil uuid;
  v_name   text := nullif(btrim(coalesce(p_name, '')), '');
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'akte_stammdaten_aendern: nur Admin' using errcode = '42501';
  end if;

  select s.profile_id into v_profil from public.students s where s.id = p_student_id for update;
  if not found then
    raise exception 'akte_stammdaten_aendern: Kind nicht gefunden' using errcode = 'P0002';
  end if;
  if not exists (select 1 from public.vertraege v where v.student_id = p_student_id and v.status = 'abgeschlossen') then
    raise exception 'akte_stammdaten_aendern: keine Akte zu diesem Kind' using errcode = 'P0002';
  end if;
  if v_name is null then
    raise exception 'akte_stammdaten_aendern: der Name ist leer' using errcode = '22023';
  end if;
  if p_klasse is not null and (p_klasse < 5 or p_klasse > 13) then
    raise exception 'akte_stammdaten_aendern: Klasse % ist nicht 5 bis 13', p_klasse using errcode = '22023';
  end if;
  if p_schule_id is not null and not exists (select 1 from public.schulen where id = p_schule_id) then
    raise exception 'akte_stammdaten_aendern: Schule nicht gefunden' using errcode = 'P0002';
  end if;

  -- Der Name lebt am Profil. Eine Akte ohne Profil (Kind ohne Konto, etwa
  -- Testdaten) zeigt den Namen aus dem Vertrag; aendern laesst er sich dann
  -- nicht — der Aufruf meldet das, statt still nichts zu tun. Bleibt der Name
  -- gleich, gehen Klasse und Schule trotzdem durch.
  if v_profil is null then
    if v_name is distinct from (
      select nullif(btrim(concat_ws(' ', v.kind_vorname, v.kind_nachname)), '')
        from public.vertraege v
       where v.student_id = p_student_id and v.status = 'abgeschlossen'
       order by v.vertragsbeginn desc nulls last
       limit 1
    ) then
      raise exception 'akte_stammdaten_aendern: das Kind hat kein Profil, der Name steht nur im Vertrag'
        using errcode = 'P0001';
    end if;
  else
    update public.profiles set full_name = v_name where id = v_profil;
  end if;

  update public.students
     set class_level = p_klasse,
         schule_id   = p_schule_id
   where id = p_student_id;

  perform public.audit_log_schreiben('akte_stammdaten_aendern', 'student', p_student_id);
end;
$$;


--
-- Name: akte_wortliste_treffer(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.akte_wortliste_treffer(p_liste text, p_text text) RETURNS text
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
  select w.wort
    from public.akte_wortliste w
   where w.liste = p_liste
     and case
           when w.nur_ganzes_wort then
             lower(coalesce(p_text, '')) ~ ('\m' || regexp_replace(w.wort, '([.*+?^${}()|\[\]\\])', '\\\1', 'g') || '\M')
           else
             strpos(lower(coalesce(p_text, '')), w.wort) > 0
         end
   order by w.wort
   limit 1;
$_$;


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
-- Name: audit_log_schreiben(text, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.audit_log_schreiben(p_aktion text, p_objekt_typ text, p_objekt_id uuid DEFAULT NULL::uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_id uuid;
begin
  if auth.uid() is null then
    raise exception 'audit_log_schreiben: kein angemeldeter Aufrufer' using errcode = '42501';
  end if;
  -- SECURITY DEFINER haengt an dieser Zeile: ohne sie duerfte jeder Angemeldete
  -- beliebige Eintraege ins Protokoll schreiben und es damit unbrauchbar machen.
  if public.get_my_role() <> 'admin' then
    raise exception 'audit_log_schreiben: nur Admin' using errcode = '42501';
  end if;

  insert into public.audit_log (actor, aktion, objekt_typ, objekt_id)
  values (auth.uid(), p_aktion, p_objekt_typ, p_objekt_id)
  returning id into v_id;

  return v_id;
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
-- Name: betriebstag(date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.betriebstag(p_datum date) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  select extract(isodow from p_datum) between 1 and 5
     and not exists (select 1 from public.feiertage_nrw f where f.datum = p_datum)
     and not exists (select 1 from public.ferien_nrw f where p_datum between f.von and f.bis);
$$;


--
-- Name: betriebstage(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.betriebstage(p_von date, p_bis date) RETURNS integer
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  select public.werktage(p_von, p_bis)
       - (select count(distinct g.t)::integer
            from public.ferien_nrw f
            cross join lateral generate_series(greatest(f.von, p_von), least(f.bis, p_bis), interval '1 day') g(t)
           where f.von <= p_bis and f.bis >= p_von
             and extract(isodow from g.t) between 1 and 5)
       - (select count(*)::integer
            from public.feiertage_nrw h
           where h.datum between p_von and p_bis
             and extract(isodow from h.datum) between 1 and 5
             and not exists (select 1 from public.ferien_nrw f where h.datum between f.von and f.bis));
$$;


--
-- Name: board_schueler(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.board_schueler() RETURNS TABLE(student_id uuid, name text, klasse integer, schule text, zustand text, ruhend_seit date, letzte_session timestamp with time zone, art text, einheiten integer, beginn date, stichtag date, verbraucht integer, offen integer, soll numeric, rueckstand numeric, ampel text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  select a.student_id, a.name, a.klasse, a.schule, a.zustand, a.ruhend_seit, a.letzte_session,
         e.art, e.einheiten, e.beginn, e.stichtag, e.verbraucht, e.offen, e.soll, e.rueckstand, e.ampel
    from public.akte_basis() a
    cross join lateral public.einheiten_stand_intern(a.student_id, current_date) e;
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
-- Name: coach_hat_platz(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.coach_hat_platz(p_student_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  select coalesce(public.get_my_role(), '') = 'coach'
     and public.akte_aktiv(p_student_id)
     and exists (
       select 1
         from public.session_students ss
         join public.coaching_sessions cs on cs.id = ss.session_id
        where ss.student_id = p_student_id
          and cs.coach_id = auth.uid()
          and cs.status <> 'done'
          -- nur eine Session um heute (Berlin), nicht irgendeine alte offene
          and (cs.scheduled_at at time zone 'Europe/Berlin')::date
              between (now() at time zone 'Europe/Berlin')::date - 1
                  and (now() at time zone 'Europe/Berlin')::date + 1
          and ss.attendance not in ('cancelled', 'cancelled_by_us')
     )
$$;


--
-- Name: coaching_sessions_testlauf_pruefen(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.coaching_sessions_testlauf_pruefen() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  if (tg_op = 'INSERT' and new.testlauf)
     or (tg_op = 'UPDATE' and new.testlauf is distinct from old.testlauf) then
    if coalesce(public.get_my_role(), '') <> 'admin' then
      raise exception 'Testlauf: nur Admin' using errcode = '42501';
    end if;
    if new.testlauf and exists (
      select 1 from public.session_students ss
        join public.students s on s.id = ss.student_id
       where ss.session_id = new.id and not s.ist_test
    ) then
      raise exception 'Testlauf: nur mit Testkonten' using errcode = '22023';
    end if;
  end if;
  return new;
end;
$$;


--
-- Name: complete_task(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.complete_task(p_task_id uuid) RETURNS TABLE(newly_completed boolean, awarded_xp integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
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
    perform public.xp_buchen_intern(v_student, least(v_xp, 1000), 'Aufgabe abgeschlossen',
                                    'task:' || v_student || ':' || p_task_id, p_task_id);
  end if;

  return query select true, v_xp;
end;
$$;


--
-- Name: darf_pruefen(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.darf_pruefen() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select coalesce(
    (select p.role = 'admin' or (p.role = 'coach' and p.darf_pruefen)
       from public.profiles p where p.id = auth.uid()),
    false)
$$;


--
-- Name: dokument_fassung_eintragen(text, text, text, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.dokument_fassung_eintragen(p_art text, p_fassung text, p_pfad text, p_sha256 text, p_bytes integer DEFAULT NULL::integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_erwartet text;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'dokument_fassung_eintragen: nur Admin' using errcode = '42501';
  end if;

  -- Die Fassung muss im Katalog stehen. Sonst entstuende eine Datei zu einer
  -- Fassung, der niemand zustimmen kann — vertrag_zustimmungen zeigt per
  -- Fremdschluessel auf genau diesen Katalog.
  perform 1 from public.vertrag_dokumente
   where schluessel = p_art and version = p_fassung;
  if not found then
    raise exception 'dokument_fassung_eintragen: % in Fassung % steht nicht im Katalog', p_art, p_fassung
      using errcode = 'P0002';
  end if;

  v_erwartet := 'fassungen/' || p_art || '/' || p_fassung || '.pdf';
  if p_pfad <> v_erwartet then
    raise exception 'dokument_fassung_eintragen: Pfad muss % sein, nicht %', v_erwartet, p_pfad
      using errcode = 'P0001';
  end if;

  -- Einmal erzeugt, bleibt es. Eine Fassung ist der Text zu einem Zeitpunkt;
  -- aendert er sich, bekommt er eine neue Fassungskennung, keine neue Datei
  -- unter altem Namen.
  insert into public.dokument_fassungen (art, fassung, pfad, sha256, bytes, erzeugt_von)
  values (p_art, p_fassung, p_pfad, lower(p_sha256), p_bytes, auth.uid())
  on conflict (art, fassung) do nothing;
end;
$$;


--
-- Name: einheit_verbraucht(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.einheit_verbraucht(p_attendance text) RETURNS boolean
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  select coalesce(p_attendance in ('present', 'unexcused'), false);
$$;


--
-- Name: einheiten_rechnung(integer, date, date, integer, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.einheiten_rechnung(p_einheiten integer, p_beginn date, p_stichtag date, p_verbraucht integer, p_heute date) RETURNS TABLE(art text, soll numeric, rueckstand numeric, offen integer, wochen_rest numeric, noetig_pro_woche numeric, gleichmaessig_pro_woche numeric, ampel text, betriebstage_gesamt integer, betriebstage_bis_gestern integer, betriebstage_ab_heute integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_verbraucht integer := coalesce(p_verbraucht, 0);
  v_s1         numeric;
  v_s2         numeric;
begin
  -- Ohne Vertrag keine Rechnung: keine Zeile statt Fehler. einheiten_stand_intern
  -- ruft die Funktion per LEFT JOIN LATERAL auch fuer Kinder ohne laufenden
  -- Vertrag auf (ruhende Akte); ein Fehler braeche dort Board und Akte.
  if p_einheiten is null or p_beginn is null or p_stichtag is null or p_heute is null then
    return;
  end if;

  betriebstage_gesamt := public.betriebstage(p_beginn, p_stichtag);
  gleichmaessig_pro_woche := case when betriebstage_gesamt > 0
                                  then p_einheiten / (betriebstage_gesamt / 5.0) end;

  if p_heute < p_beginn then
    art := 'vorher';
    return next;
    return;
  end if;

  art := 'laufend';
  betriebstage_bis_gestern := public.betriebstage(p_beginn, least(p_heute - 1, p_stichtag));
  betriebstage_ab_heute    := public.betriebstage(p_heute, p_stichtag);

  soll := case when betriebstage_gesamt > 0
               then p_einheiten * betriebstage_bis_gestern::numeric / betriebstage_gesamt
               else 0 end;
  rueckstand := soll - v_verbraucht;
  offen := greatest(p_einheiten - v_verbraucht, 0);
  wochen_rest := betriebstage_ab_heute / 5.0;
  noetig_pro_woche := case when wochen_rest > 0 then offen / wochen_rest else offen end;

  select e.schwelle_1, e.schwelle_2 into v_s1, v_s2 from public.akte_einstellungen e;
  ampel := case when rueckstand <= v_s1 then 'im_plan'
                when rueckstand <= v_s2 then 'leicht_im_rueckstand'
                else 'deutlich_im_rueckstand' end;

  return next;
end;
$$;


--
-- Name: einheiten_stand(uuid, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.einheiten_stand(p_student_id uuid, p_heute date DEFAULT CURRENT_DATE) RETURNS TABLE(art text, einheiten integer, beginn date, stichtag date, verbraucht integer, offen integer, soll numeric, rueckstand numeric, ampel text, wochen_rest numeric, noetig_pro_woche numeric, gleichmaessig_pro_woche numeric)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_rolle text := public.get_my_role();
begin
  if v_rolle = 'admin' then
    null;
  elsif v_rolle = 'coach' and public.akte_aktiv(p_student_id) then
    null;
  else
    raise exception 'einheiten_stand: keine Berechtigung fuer diese Akte' using errcode = '42501';
  end if;

  return query select * from public.einheiten_stand_intern(p_student_id, coalesce(p_heute, current_date));
end;
$$;


--
-- Name: einheiten_stand_intern(uuid, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.einheiten_stand_intern(p_student_id uuid, p_heute date) RETURNS TABLE(art text, einheiten integer, beginn date, stichtag date, verbraucht integer, offen integer, soll numeric, rueckstand numeric, ampel text, wochen_rest numeric, noetig_pro_woche numeric, gleichmaessig_pro_woche numeric)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  with vertrag as (
    select v.einheiten, v.vertragsbeginn, v.vertrag_ende
      from public.vertraege_aktuell v
     where v.student_id = p_student_id
       and v.wirksamer_status in ('aktiv', 'im_widerruf')
       and v.einheiten is not null
       and v.vertragsbeginn is not null
       and v.vertrag_ende is not null
       and v.vertrag_ende >= p_heute
     order by (v.vertragsbeginn <= p_heute) desc,
              case when v.vertragsbeginn <= p_heute then v.vertragsbeginn end desc nulls last,
              v.vertragsbeginn asc
     limit 1
  ),
  zaehlung as (
    select count(*)::integer as verbraucht
      from vertrag vt
      join public.session_students ss on ss.student_id = p_student_id
      join public.coaching_sessions cs on cs.id = ss.session_id
     where public.einheit_verbraucht(ss.attendance)
       and not cs.testlauf
       and (cs.scheduled_at at time zone 'Europe/Berlin')::date
           between vt.vertragsbeginn and vt.vertrag_ende
  )
  select coalesce(r.art, 'keiner'),
         vt.einheiten,
         vt.vertragsbeginn,
         vt.vertrag_ende,
         case when r.art = 'laufend' then z.verbraucht end,
         r.offen,
         r.soll,
         r.rueckstand,
         r.ampel,
         r.wochen_rest,
         r.noetig_pro_woche,
         r.gleichmaessig_pro_woche
    from (select 1) eins
    left join vertrag vt on true
    left join zaehlung z on true
    left join lateral public.einheiten_rechnung(
      vt.einheiten, vt.vertragsbeginn, vt.vertrag_ende, z.verbraucht, p_heute
    ) r on true;
$$;


--
-- Name: eltern_report_eintragen(uuid, text, date, jsonb, uuid, timestamp with time zone, timestamp with time zone, text, text, uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.eltern_report_eintragen(p_student_id uuid, p_art text, p_berichtsmonat date DEFAULT NULL::date, p_kernaussagen jsonb DEFAULT NULL::jsonb, p_freigegeben_von uuid DEFAULT NULL::uuid, p_freigegeben_am timestamp with time zone DEFAULT NULL::timestamp with time zone, p_versendet_am timestamp with time zone DEFAULT NULL::timestamp with time zone, p_versendet_an text DEFAULT NULL::text, p_pdf_pfad text DEFAULT NULL::text, p_parent_report_id uuid DEFAULT NULL::uuid, p_lsa_session_id uuid DEFAULT NULL::uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_nr integer;
  v_id uuid;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'eltern_report_eintragen: nur Admin' using errcode = '42501';
  end if;

  perform 1 from public.students where id = p_student_id for update;
  if not found then
    raise exception 'eltern_report_eintragen: Kind nicht gefunden' using errcode = 'P0002';
  end if;

  if p_lsa_session_id is not null and not exists (
    select 1 from public.lsa_sessions where id = p_lsa_session_id and student_id = p_student_id
  ) then
    raise exception 'eltern_report_eintragen: die LSA gehoert nicht zu diesem Kind' using errcode = '22023';
  end if;
  -- X0: aus einem Testlauf entsteht nie ein Eltern-Report.
  if p_lsa_session_id is not null and exists (
    select 1 from public.lsa_sessions where id = p_lsa_session_id and testlauf
  ) then
    raise exception 'eltern_report_eintragen: Testlauf ergibt keinen Report' using errcode = '22023';
  end if;

  select coalesce(max(nr), 0) + 1 into v_nr from public.eltern_reports where student_id = p_student_id;

  insert into public.eltern_reports
    (student_id, nr, art, berichtsmonat, kernaussagen, freigegeben_von, freigegeben_am,
     versendet_am, versendet_an, pdf_pfad, parent_report_id, lsa_session_id)
  values
    (p_student_id, v_nr, p_art, p_berichtsmonat, p_kernaussagen, p_freigegeben_von, p_freigegeben_am,
     p_versendet_am, nullif(btrim(coalesce(p_versendet_an, '')), ''), p_pdf_pfad, p_parent_report_id,
     p_lsa_session_id)
  returning id into v_id;

  perform public.audit_log_schreiben('eltern_report_eintragen', 'eltern_report', v_id);

  return jsonb_build_object('id', v_id, 'nr', v_nr);
end;
$$;


--
-- Name: eltern_reports_guard(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.eltern_reports_guard() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  if (new.id, new.student_id, new.nr, new.art, new.berichtsmonat, new.kernaussagen,
      new.freigegeben_am, new.versendet_am, new.versendet_an, new.parent_report_id,
      new.lsa_session_id, new.created_at)
     is distinct from
     (old.id, old.student_id, old.nr, old.art, old.berichtsmonat, old.kernaussagen,
      old.freigegeben_am, old.versendet_am, old.versendet_an, old.parent_report_id,
      old.lsa_session_id, old.created_at)
  then
    raise exception 'eltern_reports: ein versendeter Report ist unveraenderlich' using errcode = '42501';
  end if;

  -- freigegeben_von darf nur durch das Loeschen des Profils leer werden.
  if new.freigegeben_von is distinct from old.freigegeben_von and new.freigegeben_von is not null then
    raise exception 'eltern_reports: ein versendeter Report ist unveraenderlich' using errcode = '42501';
  end if;

  if new.pdf_pfad is distinct from old.pdf_pfad and old.pdf_pfad is not null then
    raise exception 'eltern_reports: pdf_pfad ist schon gesetzt' using errcode = '42501';
  end if;

  return new;
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
-- Name: fortschritt(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fortschritt(p_student_id uuid) RETURNS TABLE(fach_id uuid, fach text, thema text, station integer, stationen integer, kompetenzen jsonb)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_rolle  text := public.get_my_role();
  v_klasse integer;
begin
  if v_rolle = 'admin' then
    null;
  elsif v_rolle = 'coach' and public.akte_aktiv(p_student_id) then
    null;
  else
    raise exception 'fortschritt: keine Berechtigung fuer diese Akte' using errcode = '42501';
  end if;

  select s.class_level into v_klasse from public.students s where s.id = p_student_id;

  return query
  with faecher as (
    select ss.subject_id as id from public.student_subjects ss where ss.student_id = p_student_id
    union
    select c.subject_id from public.student_focus_areas f
      join public.skill_clusters c on c.id = f.cluster_id
     where f.student_id = p_student_id and f.active and f.status <> 'verworfen' and c.subject_id is not null
    union
    select c.subject_id from public.student_competency_mastery m
      join public.microskills ms on ms.id = m.microskill_id
      join public.skill_clusters c on c.id = ms.cluster_id
     where m.student_id = p_student_id and m.mastered_by is not null and c.subject_id is not null
  ),
  pfad as (
    select c.id, c.subject_id, c.name,
           row_number() over (partition by c.subject_id order by c.sort_order, c.name)::integer as pos,
           count(*) over (partition by c.subject_id)::integer as laenge
      from public.skill_clusters c
     where not c.is_deprecated
       and (v_klasse is null or v_klasse between c.class_level_min and c.class_level_max)
  ),
  aktuell as (
    select distinct on (p.subject_id) p.subject_id, p.name, p.pos, p.laenge
      from public.student_focus_areas f
      join pfad p on p.id = f.cluster_id
     where f.student_id = p_student_id and f.active and f.status <> 'verworfen'
     order by p.subject_id, p.pos
  ),
  laengen as (
    select p.subject_id, max(p.laenge) as laenge from pfad p group by p.subject_id
  ),
  bestaetigt as (
    select c.subject_id,
           jsonb_agg(jsonb_build_object(
             'kompetenz', ms.name,
             'prozess',   pc.name,
             'coach',     pr.full_name,
             'am',        m.mastered_at
           ) order by m.mastered_at desc nulls last, ms.name) as liste
      from public.student_competency_mastery m
      join public.microskills ms on ms.id = m.microskill_id
      join public.skill_clusters c on c.id = ms.cluster_id
      left join public.process_competencies pc on pc.id = m.competency_id
      left join public.profiles pr on pr.id = m.mastered_by
     where m.student_id = p_student_id
       and m.mastered_by is not null
     group by c.subject_id
  )
  select s.id, s.name, a.name, a.pos,
         coalesce(a.laenge, l.laenge),
         coalesce(b.liste, '[]'::jsonb)
    from faecher f
    join public.subjects s on s.id = f.id
    left join aktuell a on a.subject_id = s.id
    left join laengen l on l.subject_id = s.id
    left join bestaetigt b on b.subject_id = s.id
   order by s.name;
end;
$$;


--
-- Name: freigabe_cluster(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.freigabe_cluster(p_cluster_id uuid) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_id uuid;
  v_n  integer := 0;
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'freigabe_cluster: nur admin darf freigeben' using errcode = '42501';
  end if;
  for v_id in
    select id from public.tasks
     where cluster_id = p_cluster_id and status = 'review'
       and source is distinct from 'VERA8_IQB'
       and public.pruef_freigabe_erlaubt(id)
  loop
    begin
      perform public.task_status_set(v_id, 'ready');
      v_n := v_n + 1;
    exception
      when sqlstate 'P0001' then null;
    end;
  end loop;
  return v_n;
end $$;


--
-- Name: freigabe_gate_fehler(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.freigabe_gate_fehler(p_task_id uuid) RETURNS text
    LANGUAGE plpgsql STABLE
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare v public.tasks%rowtype;
begin
  select * into v from public.tasks where id = p_task_id;
  if not found then return null; end if;
  if coalesce(btrim(v.question), '') = '' then return 'task_status_set: Stamm fehlt'; end if;
  if v.input_type is null then return 'task_status_set: input_type fehlt'; end if;
  if v.afb is null then return 'task_status_set: AFB fehlt'; end if;
  if v.cluster_id is null then return 'task_status_set: Cluster fehlt (sonst nie im LSA-Pool)'; end if;
  if v.curriculum_grade is null then return 'task_status_set: Stoffanker (curriculum_grade) fehlt'; end if;
  if not exists (select 1 from public.task_solutions s
                  where s.task_id = p_task_id
                    and public.lsa_has_answers(v.input_type, v.parts, s.correct_answers)) then
    return 'task_status_set: Loesung unvollstaendig';
  end if;
  return null;
end $$;


--
-- Name: freigabe_muster(text, uuid[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.freigabe_muster(p_skill_key text, p_task_ids uuid[] DEFAULT NULL::uuid[]) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_id uuid;
  v_n  integer := 0;
begin
  -- `is distinct from` statt `<>`: get_my_role() ist NULL fuer einen nicht angemeldeten Aufrufer.
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'A21: nur die fachliche Freigabe (admin) darf freigeben' using errcode = '42501';
  end if;
  for v_id in
    select t.id from public.tasks t
     where t.skill_key = p_skill_key
       and t.status = 'draft'
       and (p_task_ids is null or t.id = any (p_task_ids))
       and not exists (select 1 from public.task_pruefungen p where p.task_id = t.id)
  loop
    begin
      perform public.task_status_set(v_id, 'ready');
      v_n := v_n + 1;
    exception
      -- P0001 = Pflichtfeld oder Loesung unvollstaendig (task_status_set-Gate).
      when sqlstate 'P0001' then null;
    end;
  end loop;
  return v_n;
end $$;


--
-- Name: freigabe_thema(text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.freigabe_thema(p_thema_key text, p_klasse integer) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_id uuid;
  v_n  integer := 0;
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'freigabe_thema: nur admin darf freigeben' using errcode = '42501';
  end if;
  for v_id in
    select t.id
      from public.tasks t
      join public.skill_thema st on st.skill_key = t.skill_key
     where st.thema_key = p_thema_key
       and t.status = 'review'
       and t.source is distinct from 'VERA8_IQB'
       and (t.class_level is null or t.class_level <= p_klasse)
       and public.pruef_freigabe_erlaubt(t.id)
  loop
    begin
      perform public.task_status_set(v_id, 'ready');
      v_n := v_n + 1;
    exception
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
-- Name: hat_zugang(uuid, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.hat_zugang(p_student_id uuid, p_datum date DEFAULT CURRENT_DATE) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  select exists (
    select 1
      from public.vertraege v
     where v.student_id = p_student_id
       and v.status = 'abgeschlossen'
       and public.vertrag_wirksamer_status(
             v.widerrufen_am, v.gekuendigt_zum, v.vertrag_ende, v.widerruf_bis, p_datum
           ) in ('im_widerruf', 'aktiv')
  )
  or public.vertrag_bruecke(p_student_id, p_datum);
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
-- Name: ist_systemaufruf(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ist_systemaufruf() RETURNS boolean
    LANGUAGE sql STABLE
    SET search_path TO 'public'
    AS $$
  select coalesce(auth.role(), 'service_role') = 'service_role'
$$;


--
-- Name: ist_test_schuetzen(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ist_test_schuetzen() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  if new.ist_test is distinct from old.ist_test
     and not (public.ist_systemaufruf() or coalesce(public.get_my_role(), '') = 'admin') then
    raise exception 'ist_test: nur Admin' using errcode = '42501';
  end if;
  return new;
end;
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
-- Name: lead_lsa_freigeben(uuid, integer, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lead_lsa_freigeben(p_lead_id uuid, p_grade integer, p_subject text, p_testlauf boolean DEFAULT false) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_lead       leads%rowtype;
  v_student_id uuid;
  v_result     jsonb;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
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
  -- X0: Testlauf nur mit Test-Lead. Das Kind erbt ist_test beim Anlegen;
  -- lsa_start prueft danach Admin und Testkonto noch einmal.
  if coalesce(p_testlauf, false) and not v_lead.ist_test then
    raise exception 'lead_lsa_freigeben: Testlauf nur mit Test-Lead' using errcode = '22023';
  end if;
  v_result := public.lsa_start(v_student_id, p_grade, p_subject, p_testlauf => coalesce(p_testlauf, false));

  -- Ein Test-Lead laeuft den Trichter normal durch (Platz, Report); er zaehlt
  -- in keinem Lead-Zaehler (Oberflaeche filtert leads.ist_test, X0).
  update leads set status = 'lsa_freigegeben' where id = p_lead_id;

  -- total_items existiert im adaptiven Rueckgabeobjekt bewusst nicht (die
  -- Aufgabenzahl bleibt verborgen) -> jsonb-Feldzugriff liefert dann NULL.
  return jsonb_build_object(
    'session_id',  v_result -> 'session_id',
    'student_id',  to_jsonb(v_student_id),
    'total_items', v_result -> 'total_items',
    'testlauf',    to_jsonb(coalesce(p_testlauf, false))
  );
end;
$$;


--
-- Name: lead_mail_protokollieren(uuid, text, text, text, timestamp with time zone, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lead_mail_protokollieren(p_lead_id uuid, p_anlass text, p_empfaenger text, p_ort text, p_termin_at timestamp with time zone DEFAULT NULL::timestamp with time zone, p_fehler text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_id uuid;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'lead_mail_protokollieren: nur Admin' using errcode = '42501';
  end if;
  if not exists (select 1 from public.leads where id = p_lead_id) then
    raise exception 'lead_mail_protokollieren: Lead nicht gefunden' using errcode = 'P0002';
  end if;

  insert into public.lead_mail_versand
    (lead_id, anlass, empfaenger, ort, termin_at, fehler, erfolgt_von)
  values
    (p_lead_id, p_anlass, p_empfaenger, btrim(p_ort), p_termin_at,
     nullif(btrim(coalesce(p_fehler, '')), ''), auth.uid())
  returning id into v_id;

  return v_id;
end;
$$;


--
-- Name: lead_thema_setzen(uuid, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lead_thema_setzen(p_lead_id uuid, p_fach text, p_thema_key text, p_quelle text DEFAULT 'gespraech'::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'lead_thema_setzen: nur Admin' using errcode = '42501';
  end if;
  if p_lead_id is null or nullif(btrim(coalesce(p_fach, '')), '') is null then
    raise exception 'lead_thema_setzen: Lead und Fach sind Pflicht' using errcode = '22023';
  end if;

  delete from public.lead_themen
   where lead_id = p_lead_id
     and fach = p_fach
     and status = 'aktuell'
     and thema_key is distinct from p_thema_key;

  if p_thema_key is null then
    return;
  end if;

  insert into public.lead_themen (lead_id, fach, thema_key, status, quelle, angelegt)
  values (p_lead_id, p_fach, p_thema_key, 'aktuell', p_quelle, now())
  on conflict (lead_id, thema_key) do update
     set fach     = excluded.fach,
         status   = 'aktuell',
         quelle   = excluded.quelle,
         angelegt = excluded.angelegt;
end;
$$;


--
-- Name: leads_status_zeitstempel(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.leads_status_zeitstempel() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if new.status is distinct from old.status then
    if new.status = 'lsa_freigegeben' and new.lsa_freigegeben_at is null then
      new.lsa_freigegeben_at := now();
    elsif new.status = 'lsa_fertig' and new.lsa_fertig_at is null then
      new.lsa_fertig_at := now();
    elsif new.status = 'rejected' then
      -- Anders als die LSA-Zeitstempel immer neu: ein reaktivierter und
      -- erneut abgelehnter Lead zaehlt ab der letzten Ablehnung.
      new.rejected_at := now();
    end if;
  end if;
  return new;
end;
$$;


--
-- Name: lena_beanstande(uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lena_beanstande(p_task_id uuid, p_kategorie text, p_notiz text DEFAULT NULL::text) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  if not (public.get_my_role() is not distinct from 'admin' or public.ist_systemaufruf()) then
    raise exception 'A20: Beanstandungen nur admin' using errcode = '42501';
  end if;
  perform 1 from public.tasks where id = p_task_id for update;
  if not found then
    raise exception 'A20: Aufgabe % nicht gefunden', p_task_id using errcode = 'P0002';
  end if;
  update public.tasks
     set status = 'beanstandet', reviewed_by = null, reviewed_at = null
   where id = p_task_id;
  insert into public.task_reviews (task_id, kategorie, notiz, geprueft_von, geprueft_am)
    values (p_task_id, p_kategorie, p_notiz, auth.uid(), clock_timestamp());
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
  if public.get_my_role() is distinct from 'admin' then
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
  if public.get_my_role() is distinct from 'admin' then
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
-- Name: lernpfad_aus_lsa(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lernpfad_aus_lsa(p_student_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_angelegt     int;
  v_aktualisiert int;
begin
  if not (public.ist_systemaufruf() or public.lernpfad_darf_lesen(p_student_id)) then
    raise exception 'lernpfad_aus_lsa: nur Admin oder Coach bei laufendem Vertrag' using errcode = '42501';
  end if;
  if not exists (select 1 from public.students where id = p_student_id) then
    raise exception 'lernpfad_aus_lsa: Kind nicht gefunden' using errcode = 'P0002';
  end if;

  with quelle as (
    select u.skill_key,
           case when u.zustand = 'traegt' then 'sicher' else 'noch_nicht_sicher' end as stand,
           u.lsa_session_id
      from public.lernpfad_lsa_urteile(p_student_id) u
    union all
    -- Fokus-Zeilen auf Skill-Ebene ohne eigenes Urteil (z. B. von Hand angelegt).
    select * from (
      select distinct on (f.skill_key) f.skill_key, 'noch_nicht_sicher', f.herkunfts_session_id
        from public.student_focus_areas f
       where f.student_id = p_student_id
         and f.skill_key is not null
         and f.status <> 'verworfen'
         and f.skill_key not in (select u.skill_key from public.lernpfad_lsa_urteile(p_student_id) u)
       order by f.skill_key, f.created_at desc
    ) fokus
  ),
  geschrieben as (
    insert into public.lernpfad as l (student_id, skill_key, stand_system, quelle, lsa_session_id)
    select p_student_id, q.skill_key, q.stand, 'lsa', q.lsa_session_id
      from quelle q
    on conflict (student_id, skill_key) do update
       set stand_system      = excluded.stand_system,
           stand_system_seit = now(),
           lsa_session_id    = excluded.lsa_session_id,
           aktualisiert      = now()
     -- Nur reine LSA-Zeilen auffrischen: nie nach Session-Belegen, nie nach
     -- einer Coach-Entscheidung, nie ohne Aenderung.
     where l.quelle = 'lsa'
       and l.belege = '[]'::jsonb
       and l.stand_coach is null
       and (l.stand_system, l.lsa_session_id) is distinct from (excluded.stand_system, excluded.lsa_session_id)
    returning l.skill_key, l.stand_system, l.lsa_session_id, (xmax = 0) as angelegt
  ),
  protokolliert as (
    insert into public.lernpfad_protokoll (student_id, skill_key, aktion, anlass, neu, von)
    select p_student_id, g.skill_key, 'uebernahme', 'lsa',
           jsonb_build_object('stand_system', g.stand_system, 'lsa_session_id', g.lsa_session_id,
                              'angelegt', g.angelegt),
           auth.uid()
      from geschrieben g
  )
  select count(*) filter (where g.angelegt), count(*) filter (where not g.angelegt)
    into v_angelegt, v_aktualisiert
    from geschrieben g;

  return jsonb_build_object('ok', true, 'angelegt', v_angelegt, 'aktualisiert', v_aktualisiert);
end;
$$;


--
-- Name: lernpfad_beleg(uuid, text, uuid, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lernpfad_beleg(p_student_id uuid, p_skill_key text, p_session_id uuid, p_ergebnis text, p_hinweis_genutzt boolean) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  if not (public.ist_systemaufruf()
          or coalesce(public.get_my_role(), '') = 'admin'
          or public.lernpfad_coach_der_session(p_session_id, p_student_id)) then
    raise exception 'lernpfad_beleg: nur Coach der Session oder Admin' using errcode = '42501';
  end if;
  return public.lernpfad_beleg_core(p_student_id, p_skill_key, p_session_id, p_ergebnis, p_hinweis_genutzt);
end;
$$;


--
-- Name: lernpfad_beleg_core(uuid, text, uuid, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lernpfad_beleg_core(p_student_id uuid, p_skill_key text, p_session_id uuid, p_ergebnis text, p_hinweis_genutzt boolean) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_abstand  numeric := public.lernpfad_stellschraube('mastery_abstand_sessions', p_session_id);
  v_n        numeric := public.lernpfad_stellschraube('mastery_richtig_ohne_hinweis', p_session_id);
  v_alt      text;
  v_neu      text;
  v_kandidat boolean;
  v_heute    record;
  v_belege   jsonb;
begin
  if p_ergebnis is null or p_ergebnis not in ('richtig', 'teilweise', 'falsch') then
    raise exception 'lernpfad_beleg: ergebnis muss richtig, teilweise oder falsch sein' using errcode = '22023';
  end if;
  if p_hinweis_genutzt is null then
    raise exception 'lernpfad_beleg: hinweis_genutzt ist Pflicht' using errcode = '22023';
  end if;
  if not exists (select 1 from public.skills where skill_key = p_skill_key) then
    raise exception 'lernpfad_beleg: Skill % unbekannt', p_skill_key using errcode = 'P0002';
  end if;
  -- Nur Sessions vor Ort, in denen das Kind gebucht und anwesend ist
  -- (Entscheidung 4; R1 setzt 'present' bei der Tablet-Zuweisung).
  if not exists (select 1 from public.session_students ss
                  where ss.session_id = p_session_id and ss.student_id = p_student_id
                    and ss.attendance = 'present') then
    raise exception 'lernpfad_beleg: Kind ist in dieser Session nicht anwesend' using errcode = 'P0001';
  end if;

  insert into public.lernpfad_belege (student_id, skill_key, session_id, ergebnis, hinweis_genutzt)
  values (p_student_id, p_skill_key, p_session_id, p_ergebnis, p_hinweis_genutzt);

  insert into public.lernpfad (student_id, skill_key, quelle)
  values (p_student_id, p_skill_key, 'session')
  on conflict (student_id, skill_key) do nothing;

  select stand_system into v_alt
    from public.lernpfad
   where student_id = p_student_id and skill_key = p_skill_key
   for update;

  with je_session as (
    select b.session_id,
           cs.scheduled_at,
           min(b.zeit) as am,
           count(*)::int as gesamt,
           count(*) filter (where b.ergebnis = 'richtig' and not b.hinweis_genutzt)::int as ohne_hinweis,
           count(*) filter (where b.ergebnis = 'richtig')::int as richtig,
           count(*) filter (where b.ergebnis = 'falsch')::int as falsch
      from public.lernpfad_belege b
      join public.coaching_sessions cs on cs.id = b.session_id
     where b.student_id = p_student_id and b.skill_key = p_skill_key
     group by b.session_id, cs.scheduled_at
  ),
  nummeriert as (
    select *, row_number() over (order by scheduled_at, session_id) as nr
      from je_session
  )
  select bool_or(nr > v_abstand and ohne_hinweis >= v_n),
         jsonb_agg(jsonb_build_object('session_id', session_id, 'am', am, 'gesamt', gesamt,
                                      'richtig_ohne_hinweis', ohne_hinweis) order by nr)
    into v_kandidat, v_belege
    from nummeriert;

  select count(*) filter (where ergebnis = 'richtig' and not hinweis_genutzt) as ohne_hinweis,
         count(*) filter (where ergebnis = 'richtig') as richtig,
         count(*) filter (where ergebnis = 'falsch') as falsch
    into v_heute
    from public.lernpfad_belege
   where student_id = p_student_id and skill_key = p_skill_key and session_id = p_session_id;

  v_neu := case
             when v_kandidat then 'kandidat'
             when v_heute.ohne_hinweis >= v_n then 'sicher'
             when v_alt = 'sicher' and v_heute.falsch > v_heute.richtig then 'noch_nicht_sicher'
             when v_alt = 'sicher' then 'sicher'
             else 'aktiv'
           end;

  update public.lernpfad
     set stand_system      = v_neu,
         stand_system_seit = case when v_neu is distinct from v_alt then now() else stand_system_seit end,
         letzte_uebung_am  = now(),
         letzte_session_id = p_session_id,
         belege            = coalesce(v_belege, '[]'::jsonb),
         aktualisiert      = now()
   where student_id = p_student_id and skill_key = p_skill_key;

  return v_neu;
end;
$$;


--
-- Name: lernpfad_coach_der_session(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lernpfad_coach_der_session(p_session_id uuid, p_student_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  select public.get_my_role() = 'coach'
     and exists (
       select 1
         from public.coaching_sessions cs
         join public.session_students ss on ss.session_id = cs.id
        where cs.id = p_session_id
          and cs.coach_id = auth.uid()
          and ss.student_id = p_student_id
     );
$$;


--
-- Name: lernpfad_darf_lesen(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lernpfad_darf_lesen(p_student_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  select case public.get_my_role()
           when 'admin' then true
           when 'coach' then public.akte_aktiv(p_student_id)
           else false
         end;
$$;


--
-- Name: lernpfad_lsa_urteile(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lernpfad_lsa_urteile(p_student_id uuid) RETURNS TABLE(skill_key text, zustand text, lsa_session_id uuid)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  select distinct on (u.skill_key) u.skill_key, u.zustand, u.session_id
    from public.lsa_skill_urteil u
    join public.lsa_sessions ls on ls.id = u.session_id
   where (ls.student_id = p_student_id or ls.uebernommen_zu_student_id = p_student_id)
     and ls.status = 'completed'
     -- Testlauf-Spalte kommt mit X0; ueber to_jsonb, damit A1 auch ohne sie laeuft.
     and not coalesce((to_jsonb(ls) ->> 'testlauf')::boolean, false)
     and u.zustand <> 'ungeprueft'
   order by u.skill_key, ls.completed_at desc nulls last, u.aktualisiert desc;
$$;


--
-- Name: lernpfad_pruefung_faellig(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lernpfad_pruefung_faellig(p_student_id uuid, p_skill_key text) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  select coalesce((
    select case
             when l.stand_system <> 'kandidat' or l.stand_coach = 'gemeistert' then false
             when l.stand_coach is null then true
             else exists (
               select 1
                 from public.lernpfad_belege b
                 join public.coaching_sessions cs on cs.id = b.session_id
                where b.student_id = l.student_id
                  and b.skill_key = l.skill_key
                  and b.zeit > l.coach_am
                  and b.session_id is distinct from l.coach_session_id
                  and (l.coach_session_id is null
                       or cs.scheduled_at > (select c2.scheduled_at from public.coaching_sessions c2
                                              where c2.id = l.coach_session_id))
                group by b.session_id
               having count(*) filter (where b.ergebnis = 'richtig' and not b.hinweis_genutzt)
                      >= public.lernpfad_stellschraube('mastery_richtig_ohne_hinweis', b.session_id))
           end
      from public.lernpfad l
     where l.student_id = p_student_id and l.skill_key = p_skill_key), false);
$$;


--
-- Name: lernpfad_stellschraube(text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lernpfad_stellschraube(p_schluessel text, p_session_id uuid DEFAULT NULL::uuid) RETURNS numeric
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $_$
declare
  v_wert  text;
  v_start numeric := case p_schluessel
                       when 'mastery_abstand_sessions'     then 1
                       when 'mastery_richtig_ohne_hinweis' then 2
                     end;
begin
  if p_session_id is not null then
    begin
      select to_jsonb(cs) -> 'einstellungen' ->> p_schluessel
        into v_wert
        from public.coaching_sessions cs
       where cs.id = p_session_id;
    exception when others then
      v_wert := null;
    end;
  end if;

  if v_wert is null and to_regclass('public.session_einstellungen') is not null then
    begin
      execute 'select to_jsonb(e) ->> ''wert'' from public.session_einstellungen e
                where to_jsonb(e) ->> ''schluessel'' = $1'
         into v_wert
        using p_schluessel;
    exception when others then
      v_wert := null;
    end;
  end if;

  begin
    return coalesce(v_wert::numeric, v_start);
  exception when others then
    return v_start;
  end;
end;
$_$;


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
  if coalesce(public.get_my_role(), '') not in ('coach','admin') then
    raise exception 'LSA: Lernpfad-Freigabe nur durch Coach (FernUSG)' using errcode = '42501';
  end if;

  select * into v_session from lsa_sessions where id = p_session_id;
  if not found then
    raise exception 'LSA: Session nicht gefunden' using errcode = 'P0002';
  end if;
  -- X0: ein Testlauf geht nie in den Lernpfad.
  if v_session.testlauf then
    raise exception 'LSA: Testlauf wird nicht uebernommen' using errcode = '22023';
  end if;
  -- X0 (Entscheidung 26): Coach nur fuer Kinder mit aktiver Akte.
  if coalesce(public.get_my_role(), '') = 'coach' and not public.akte_aktiv(v_session.student_id) then
    raise exception 'LSA: keine aktive Akte' using errcode = '42501';
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
-- Name: lsa_darf_starten(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_darf_starten(p_student_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  select coalesce(public.get_my_role(), '') = 'admin'
      or public.coach_hat_platz(p_student_id)
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

  -- W5-d: den Themenraum der Sitzung festhalten, wie er JETZT gilt. Der
  -- Report liest ihn spaeter von hier statt aus den heutigen Kanten — die
  -- aendern sich mit jedem Inhalts-Lauf, ein alter Report saehe sonst anders
  -- aus als am Tag des Gespraechs. Ohne thema_key kein Feld. Nur ergaenzt:
  -- alle bisherigen Felder entstehen oben unveraendert.
  if v_session.thema_key is not null then
    v_summary := v_summary || jsonb_build_object(
      'themenraum',
      public.lsa_themenraum(v_session.thema_key)
        || jsonb_build_object('stand', to_jsonb(now())));
  end if;

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
-- Name: lsa_im_pool(uuid, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_im_pool(p_task_id uuid, p_testlauf boolean DEFAULT false) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
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
            or (coalesce(p_testlauf, false)
                and t.status in ('draft', 'review', 'rueckfrage')
                and public.pruef_ausschluss(t.id) is null))
  )
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
-- Name: lsa_lead_kontext(uuid[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_lead_kontext(p_student_ids uuid[]) RETURNS TABLE(student_id uuid, lead_id uuid, rufname text, next_exam_topic text, current_topic_cluster_id uuid, eltern_note text, eltern_weak_topics text[])
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_rolle text := public.get_my_role();
begin
  if coalesce(v_rolle, '') not in ('admin', 'coach') then
    raise exception 'lsa_lead_kontext: nur Admin oder Coach' using errcode = '42501';
  end if;

  return query
  select s.id,
         l.id,
         coalesce(l.first_name, l.full_name),
         l.next_exam_topic,
         l.current_topic_cluster_id,
         la.note,
         coalesce(la.weak_topics, '{}'::text[])
    from public.students s
    join lateral (
      select l2.*
        from public.leads l2
       where l2.id = s.lead_id
          or (s.lead_id is null and l2.converted_student_id = s.id)
       order by (l2.id = s.lead_id) desc nulls last, l2.created_at desc
       limit 1
    ) l on true
    left join public.lead_assessments la on la.lead_id = l.id and la.source = 'parent'
   where s.id = any(coalesce(p_student_ids, '{}'::uuid[]))
     and (v_rolle = 'admin' or s.is_provisional or public.akte_aktiv(s.id));
end;
$$;


--
-- Name: lsa_lead_von_schueler(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_lead_von_schueler(p_student_id uuid) RETURNS uuid
    LANGUAGE sql STABLE
    SET search_path TO 'public'
    AS $$
  select coalesce(
    (select s.lead_id from students s where s.id = p_student_id),
    (select l.id from leads l
      where l.converted_student_id = p_student_id
      order by l.created_at desc
      limit 1)
  )
$$;


--
-- Name: lsa_may_act_for(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_may_act_for(p_student_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  select coalesce(public.get_my_role(), '') = 'admin'
      or (coalesce(public.get_my_role(), '') = 'coach' and public.akte_aktiv(p_student_id))
      -- coalesce: ohne Profil/Schuelerzeile ist der Vergleich NULL, und ein
      -- "if not lsa_may_act_for(…)" liesse NULL durch.
      or coalesce(public.get_my_student_id() = p_student_id, false)
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
-- Name: lsa_normalize_number(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_normalize_number(p_raw text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  -- Auf lsa_normalize_answer aufgesetzt, nicht daneben: was dort gilt
  -- (trimmen, Leerraum zusammenfassen, Komma -> Punkt, klein), gilt hier auch.
  -- Die Vorzeichenregeln greifen nur unmittelbar vor einer Ziffer — "+ x" oder
  -- ein Wort mit Bindestrich bleiben, wie sie sind.
  select case
    when p_raw is null then null
    else btrim(
      regexp_replace(
        regexp_replace(
          translate(public.lsa_normalize_answer(p_raw),
                    chr(8722) || chr(8211) || chr(8212), '---'),
          '^\+ ?(?=[0-9])', ''),
        '^- (?=[0-9])', '-'))
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
  -- Phase Tiefe endet spaetestens so lange nach Sitzungsbeginn. Die Restzeit
  -- bis zum 19-Minuten-Fenster gehoert der Breite: lieber ein Befund fuer
  -- viele Bereiche als eine Ursachensuche, die die ganze Sitzung frisst.
  c_tiefe_bis constant interval := interval '12 minutes';

  v_sess    lsa_sessions;
  v_open    text;
  v_prefer_nonmc boolean;
  v_desc    text;
  v_leaf    text;
  v_task    uuid;
  v_iter    int := 0;
  v_beginn  timestamptz;
  v_fach    text;
  v_lead    uuid;
  v_schule  uuid;
  v_einstieg   text[];  -- Einstiegsknoten des Sitzungsthemas
  v_themenraum text[];  -- Einstiegsknoten + ihr Abschluss = "unter dem Thema"
  v_mit_thema  boolean; -- Thema mit Einstiegsknoten, die Aufgaben haben
begin
  select * into v_sess from lsa_sessions where id = p_session_id;
  if not found or v_sess.status <> 'in_progress' then
    return null;
  end if;

  v_beginn := coalesce(v_sess.started_at, v_sess.created_at);
  if p_jetzt > v_beginn + interval '19 minutes' then
    return null;
  end if;

  v_fach   := lower(v_sess.subject);
  v_lead   := public.lsa_lead_von_schueler(v_sess.student_id);
  v_schule := (select l.schule_id from leads l where l.id = v_lead);

  -- Ohne Thema (kein aktuell-Thema, oder keine Einstiegsknoten mit Aufgaben
  -- im Status-Filter) laeuft die bisherige Auswahl: Abstieg unter jedem
  -- gebrochenen Knoten, ohne Zeitgrenze, keine Breite a.
  v_mit_thema := exists (
    select 1 from thema_einstieg te join tasks t on t.skill_key = te.skill_key
     where te.thema_key = v_sess.thema_key and public.lsa_im_pool(t.id, v_sess.testlauf));

  if v_mit_thema then
    v_einstieg := array(
      select te.skill_key from thema_einstieg te where te.thema_key = v_sess.thema_key);
    v_themenraum := v_einstieg || array(
      select distinct a.skill_key
        from unnest(v_einstieg) e(sk)
        cross join lateral public.lsa_abschluss(e.sk) a);
  else
    v_einstieg   := '{}';
    v_themenraum := '{}';
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
         and public.lsa_im_pool(t.id, v_sess.testlauf)
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

    -- Phase T: naechster ungepruefter Einstiegsknoten des Themas, groesster
    -- offener Abschluss zuerst. Nur Knoten mit einer noch freien Aufgabe —
    -- ein Thema ohne Aufgaben laesst Phase T einfach aus. KEINE Klassengrenze:
    -- das Thema hat das Erstgespraech gewaehlt.
    select y.leaf into v_leaf from (
      select s.skill_key as leaf,
             1 + (select count(*) from public.lsa_abschluss(s.skill_key) a
                   where not exists (
                     select 1 from lsa_skill_urteil u
                      where u.session_id = p_session_id and u.skill_key = a.skill_key)) as neu
        from skills s
       where s.skill_key = any (v_einstieg)
         and not exists (
               select 1 from lsa_skill_urteil u
                where u.session_id = p_session_id and u.skill_key = s.skill_key)
         and exists (
               select 1 from tasks t
                where t.skill_key = s.skill_key
                  and public.lsa_im_pool(t.id, v_sess.testlauf)
                  and t.id not in (
                        select task_id from lsa_ausgegeben where session_id = p_session_id
                        union
                        select task_id from lsa_responses  where session_id = p_session_id))
       order by neu desc, s.fundament_tiefe desc, s.skill_key
       limit 1
    ) y;

    if v_leaf is not null then
      select t.id into v_task
        from tasks t
       where t.skill_key = v_leaf
         and public.lsa_im_pool(t.id, v_sess.testlauf)
         and t.id not in (
               select task_id from lsa_ausgegeben where session_id = p_session_id
               union
               select task_id from lsa_responses  where session_id = p_session_id)
       order by t.sondierrang nulls last, md5(p_session_id::text || t.id::text)
       limit 1;
      return v_task;
    end if;

    -- Phase Tiefe (alter Schritt 3). Mit Thema: nur unter Knoten des
    -- Themenraums, nur bis c_tiefe_bis nach Sitzungsbeginn, ohne Klassengrenze.
    -- Ohne Thema: wie bisher unter jedem gebrochenen Knoten, ohne Zeitgrenze,
    -- mit Klassengrenze.
    v_desc := null;
    if not v_mit_thema or p_jetzt < v_beginn + c_tiefe_bis then
      select x.q into v_desc from (
        select k.voraussetzt_skill_key as q, s.fundament_tiefe as tf
          from lsa_skill_urteil u
          join skill_kante k on k.skill_key = u.skill_key
          join skills s on s.skill_key = k.voraussetzt_skill_key
         where u.session_id = p_session_id
           and u.offen = false
           and u.zustand in ('traegt_nicht','nicht_angesetzt')
           and (not v_mit_thema or u.skill_key = any (v_themenraum))
           and (v_mit_thema or s.klasse_herkunft <= v_sess.grade)
           and not exists (
                 select 1 from lsa_skill_urteil d
                  where d.session_id = p_session_id and d.skill_key = k.voraussetzt_skill_key)
         order by s.fundament_tiefe desc, k.voraussetzt_skill_key
         limit 1
      ) x;
    end if;

    if v_desc is not null then
      select t.id into v_task
        from tasks t
       where t.skill_key = v_desc
         and public.lsa_im_pool(t.id, v_sess.testlauf)
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

    -- Breite a: Einstiegsknoten der schon behandelten Themen, zuletzt
    -- behandelt zuerst — nach der Stellung im Schulplan der Schule des Leads
    -- (Klasse, dann Position; die Position beginnt je Klasse neu), ohne Plan
    -- nach themen.sort absteigend.
    select y.leaf into v_leaf from (
      select te.skill_key as leaf,
             (select max(p.klasse * 1000 + p.position)
                from schul_themenplan p
               where p.schule_id = v_schule
                 and p.thema_key = lt.thema_key
                 and lower(p.fach) = v_fach) as planrang,
             th.sort,
             1 + (select count(*) from public.lsa_abschluss(te.skill_key) a
                   where not exists (
                     select 1 from lsa_skill_urteil u
                      where u.session_id = p_session_id and u.skill_key = a.skill_key)) as neu,
             s.fundament_tiefe as tf
        from lead_themen lt
        join themen th         on th.thema_key = lt.thema_key
        join thema_einstieg te on te.thema_key = lt.thema_key
        join skills s          on s.skill_key  = te.skill_key
       where v_mit_thema
         and lt.lead_id = v_lead
         and lt.status = 'behandelt'
         and lower(lt.fach) = v_fach
         and s.klasse_herkunft <= v_sess.grade
         and not exists (
               select 1 from lsa_skill_urteil u
                where u.session_id = p_session_id and u.skill_key = te.skill_key)
         and exists (
               select 1 from tasks t
                where t.skill_key = te.skill_key
                  and public.lsa_im_pool(t.id, v_sess.testlauf)
                  and t.id not in (
                        select task_id from lsa_ausgegeben where session_id = p_session_id
                        union
                        select task_id from lsa_responses  where session_id = p_session_id))
       order by planrang desc nulls last, th.sort desc nulls last, neu desc, tf desc, leaf
       limit 1
    ) y;

    if v_leaf is not null then
      select t.id into v_task
        from tasks t
       where t.skill_key = v_leaf
         and public.lsa_im_pool(t.id, v_sess.testlauf)
         and t.id not in (
               select task_id from lsa_ausgegeben where session_id = p_session_id
               union
               select task_id from lsa_responses  where session_id = p_session_id)
       order by t.sondierrang nulls last, md5(p_session_id::text || t.id::text)
       limit 1;
      return v_task;
    end if;

    -- Breite b (alter Schritt 4): neues Blatt nach gieriger Deckung. Mit Thema
    -- ohne Abstieg (die Tiefe oben greift nur im Themenraum), ohne Thema mit.
    select y.leaf into v_leaf from (
      select b.skill_key as leaf, s.fundament_tiefe as tf,
             1 + (select count(*) from public.lsa_abschluss(b.skill_key) a
                   where not exists (
                     select 1 from lsa_skill_urteil u
                      where u.session_id = p_session_id and u.skill_key = a.skill_key)) as neu
        from skills b join skills s on s.skill_key = b.skill_key
       where not exists (select 1 from skill_kante k where k.voraussetzt_skill_key = b.skill_key)
         and b.klasse_herkunft <= v_sess.grade
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
         and public.lsa_im_pool(t.id, v_sess.testlauf)
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
      join skills s on s.skill_key = t.skill_key
     where s.klasse_herkunft <= v_sess.grade
       and public.lsa_im_pool(t.id, v_sess.testlauf)
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
-- Name: lsa_session_akte_aktiv(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_session_akte_aktiv(p_session_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  select exists (
    select 1 from public.lsa_sessions l
     where l.id = p_session_id and public.akte_aktiv(l.student_id)
  )
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
-- Name: lsa_sessions_testlauf_pruefen(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_sessions_testlauf_pruefen() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  if tg_op = 'UPDATE' then
    if new.testlauf is distinct from old.testlauf then
      raise exception 'Testlauf: nur beim Start einer LSA setzbar' using errcode = '42501';
    end if;
    if new.testlauf and new.student_id is distinct from old.student_id then
      raise exception 'Testlauf: das Kind eines Testlaufs ist fest' using errcode = '42501';
    end if;
    return new;
  end if;
  if new.testlauf then
    if coalesce(public.get_my_role(), '') <> 'admin' then
      raise exception 'Testlauf: nur Admin' using errcode = '42501';
    end if;
    if not coalesce((select s.ist_test from public.students s where s.id = new.student_id), false) then
      raise exception 'Testlauf: nur mit Testkonto' using errcode = '22023';
    end if;
  end if;
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
        substring(public.lsa_normalize_number(p_raw)
                  from '^(-?[0-9]+(?:[[:space:]]+[0-9]+/[0-9]+|/[0-9]+|\.[0-9]+)?)'),
        ''),
      btrim(coalesce(
        substring(public.lsa_normalize_number(p_raw)
                  from '^-?[0-9]+(?:[[:space:]]+[0-9]+/[0-9]+|/[0-9]+|\.[0-9]+)?[[:space:]]*(.*)$'),
        public.lsa_normalize_number(p_raw)))
    ]
  end
$_$;


--
-- Name: lsa_start(uuid, integer, text, text, timestamp with time zone, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_start(p_student_id uuid, p_grade integer, p_subject text, p_modus text DEFAULT 'adaptiv'::text, p_jetzt timestamp with time zone DEFAULT now(), p_testlauf boolean DEFAULT false) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
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
-- Name: lsa_themenraum(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_themenraum(p_thema_key text) RETURNS jsonb
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  with e as (
    select te.skill_key from thema_einstieg te where te.thema_key = p_thema_key
  ),
  d as (
    select distinct a.skill_key
      from e cross join lateral public.lsa_abschluss(e.skill_key) a
     where a.skill_key not in (select skill_key from e)
  )
  select jsonb_build_object(
           'thema_key', p_thema_key,
           'einstieg',  coalesce((select jsonb_agg(skill_key order by skill_key) from e), '[]'::jsonb),
           'darunter',  coalesce((select jsonb_agg(skill_key order by skill_key) from d), '[]'::jsonb))
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
  if coalesce(public.get_my_role(), '') not in ('coach','admin') then
    raise exception 'lsa_uebernahme: nur Coach/Admin' using errcode = '42501';
  end if;

  select * into v_session from lsa_sessions where id = p_session_id;
  if not found then
    raise exception 'lsa_uebernahme: Session nicht gefunden' using errcode = 'P0002';
  end if;
  -- X0: ein Testlauf geht nie in den Lernpfad.
  if v_session.testlauf then
    raise exception 'lsa_uebernahme: Testlauf wird nicht uebernommen' using errcode = '22023';
  end if;
  -- X0 (Entscheidung 26): Coach nur fuer Kinder mit aktiver Akte.
  if coalesce(public.get_my_role(), '') = 'coach' and not public.akte_aktiv(v_session.student_id) then
    raise exception 'lsa_uebernahme: keine aktive Akte' using errcode = '42501';
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
-- Name: mastery_entscheiden(uuid, text, text, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.mastery_entscheiden(p_student_id uuid, p_skill_key text, p_entscheidung text, p_grund text DEFAULT NULL::text, p_session_id uuid DEFAULT NULL::uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_alt public.lernpfad;
begin
  -- Kein Systemaufruf: „gemeistert“ entsteht nur durch einen Menschen (FernUSG).
  if not (coalesce(public.get_my_role(), '') = 'admin'
          or public.lernpfad_coach_der_session(p_session_id, p_student_id)) then
    raise exception 'mastery_entscheiden: nur Coach der Session oder Admin' using errcode = '42501';
  end if;
  if p_entscheidung is null or p_entscheidung not in ('gemeistert', 'vertagt') then
    raise exception 'mastery_entscheiden: Entscheidung muss gemeistert oder vertagt sein' using errcode = '22023';
  end if;

  select * into v_alt from public.lernpfad
   where student_id = p_student_id and skill_key = p_skill_key
   for update;
  if not found or v_alt.stand_system <> 'kandidat' then
    raise exception 'mastery_entscheiden: % ist kein Mastery-Kandidat', p_skill_key using errcode = 'P0001';
  end if;
  if v_alt.stand_coach = 'gemeistert' then
    raise exception 'mastery_entscheiden: % ist bereits gemeistert', p_skill_key using errcode = 'P0001';
  end if;
  if not public.lernpfad_pruefung_faellig(p_student_id, p_skill_key) then
    raise exception 'mastery_entscheiden: % ist vertagt; neu vorgeschlagen erst mit neuen Belegen aus einer spaeteren Session',
      p_skill_key using errcode = 'P0001';
  end if;
  if p_entscheidung = 'vertagt' and nullif(btrim(coalesce(p_grund, '')), '') is null then
    raise exception 'mastery_entscheiden: Vertagen braucht einen Grund' using errcode = '22023';
  end if;

  update public.lernpfad
     set stand_coach      = p_entscheidung,
         coach_grund      = nullif(btrim(coalesce(p_grund, '')), ''),
         coach_von        = auth.uid(),
         coach_am         = clock_timestamp(),
         coach_session_id = p_session_id,
         aktualisiert     = now()
   where id = v_alt.id;

  insert into public.lernpfad_protokoll (student_id, skill_key, aktion, anlass, alt, neu, grund, von, session_id)
  values (p_student_id, p_skill_key, 'mastery', 'pruefung',
          jsonb_build_object('stand_system', v_alt.stand_system, 'stand_coach', v_alt.stand_coach),
          jsonb_build_object('stand_coach', p_entscheidung),
          nullif(btrim(coalesce(p_grund, '')), ''), auth.uid(), p_session_id);

  return jsonb_build_object('ok', true, 'skill_key', p_skill_key,
                            'stand_system', v_alt.stand_system, 'stand_coach', p_entscheidung);
end;
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
-- Name: mastery_vorschlaege(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.mastery_vorschlaege(p_student_id uuid) RETURNS TABLE(skill_key text, label text, stand_coach text, coach_grund text, letzte_uebung_am timestamp with time zone)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
#variable_conflict use_column
begin
  if not (public.ist_systemaufruf() or public.lernpfad_darf_lesen(p_student_id)) then
    raise exception 'mastery_vorschlaege: nur Admin oder Coach bei laufendem Vertrag' using errcode = '42501';
  end if;
  return query
    select l.skill_key, s.label, l.stand_coach, l.coach_grund, l.letzte_uebung_am
      from public.lernpfad l
      join public.skills s on s.skill_key = l.skill_key
     where l.student_id = p_student_id
       and public.lernpfad_pruefung_faellig(l.student_id, l.skill_key)
     order by l.stand_system_seit, l.skill_key;
end;
$$;


--
-- Name: mein_lernpfad(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.mein_lernpfad() RETURNS TABLE(skill_key text, label text, stand text, seit timestamp with time zone)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
#variable_conflict use_column
declare
  v_student uuid := public.get_my_student_id();
begin
  if v_student is null then
    raise exception 'mein_lernpfad: nur fuer Schuelerkonten' using errcode = '42501';
  end if;
  return query
    select l.skill_key, s.label,
           case when l.stand_coach = 'gemeistert' then 'gemeistert'
                when l.stand_system = 'kandidat'  then 'sicher'
                else l.stand_system end,
           case when l.stand_coach = 'gemeistert' then l.coach_am else l.stand_system_seit end
      from public.lernpfad l
      join public.skills s on s.skill_key = l.skill_key
     where l.student_id = v_student
     order by s.klasse_herkunft, s.fundament_tiefe, l.skill_key;
end;
$$;


--
-- Name: naechste_luecke(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.naechste_luecke(p_student_id uuid) RETURNS TABLE(skill_key text, label text, thema_key text, stand_system text, quelle text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
#variable_conflict use_column
begin
  if not (public.ist_systemaufruf() or public.lernpfad_darf_lesen(p_student_id)) then
    raise exception 'naechste_luecke: nur Admin oder Coach bei laufendem Vertrag' using errcode = '42501';
  end if;

  return query
    select l.skill_key, s.label, st.thema_key, l.stand_system,
           case when l.quelle = 'lsa' and l.belege = '[]'::jsonb then 'lsa' else 'lernpfad' end
      from public.lernpfad l
      join public.skills s on s.skill_key = l.skill_key
      left join public.skill_thema st on st.skill_key = l.skill_key
     where l.student_id = p_student_id
       and l.stand_system = 'aktiv'
       and l.stand_coach is distinct from 'gemeistert'
     order by l.stand_system_seit desc, l.skill_key
     limit 1;
  if found then
    return;
  end if;

  return query
    with luecke as (
      select l.skill_key, l.stand_system, l.quelle, l.belege
        from public.lernpfad l
       where l.student_id = p_student_id
         and l.stand_system = 'noch_nicht_sicher'
         and l.stand_coach is distinct from 'gemeistert'
    )
    select g.skill_key, s.label, st.thema_key, g.stand_system,
           case when g.quelle = 'lsa' and g.belege = '[]'::jsonb then 'lsa' else 'lernpfad' end
      from luecke g
      join public.skills s on s.skill_key = g.skill_key
      left join public.skill_thema st on st.skill_key = g.skill_key
     order by (select count(*) from public.lsa_abschluss(g.skill_key) a
                where a.skill_key in (select skill_key from luecke)),
              s.klasse_herkunft desc, s.fundament_tiefe desc, g.skill_key
     limit 1;
  if found then
    return;
  end if;

  -- Erste Session nach der LSA, Lernpfad noch nicht uebernommen.
  if not exists (select 1 from public.lernpfad l where l.student_id = p_student_id) then
    return query
      with luecke as (
        select u.skill_key from public.lernpfad_lsa_urteile(p_student_id) u where u.zustand <> 'traegt'
      )
      select g.skill_key, s.label, st.thema_key, 'noch_nicht_sicher'::text, 'lsa'::text
        from luecke g
        join public.skills s on s.skill_key = g.skill_key
        left join public.skill_thema st on st.skill_key = g.skill_key
       order by (select count(*) from public.lsa_abschluss(g.skill_key) a
                  where a.skill_key in (select skill_key from luecke)),
                s.klasse_herkunft desc, s.fundament_tiefe desc, g.skill_key
       limit 1;
  end if;
end;
$$;


--
-- Name: notiz_anlegen(uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notiz_anlegen(p_student_id uuid, p_kategorie text, p_text text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_rolle  text := public.get_my_role();
  v_text   text := nullif(btrim(coalesce(p_text, '')), '');
  v_treffer text;
  v_id     uuid;
begin
  if auth.uid() is null or v_rolle not in ('admin', 'coach') then
    raise exception 'notiz_anlegen: nur Admin oder Coach' using errcode = '42501';
  end if;
  if not exists (select 1 from public.vertraege_aktuell v where v.student_id = p_student_id) then
    raise exception 'notiz_anlegen: keine Akte zu diesem Kind' using errcode = 'P0002';
  end if;
  if v_rolle = 'coach' and not public.akte_aktiv(p_student_id) then
    raise exception 'notiz_anlegen: Coaches schreiben nur in aktive Akten' using errcode = '42501';
  end if;
  if p_kategorie is null or p_kategorie not in ('lernen', 'verhalten', 'organisatorisch') then
    raise exception 'notiz_anlegen: unbekannte Kategorie %', p_kategorie using errcode = '22023';
  end if;
  if v_text is null then
    raise exception 'notiz_anlegen: die Notiz ist leer' using errcode = '22023';
  end if;

  v_treffer := public.akte_wortliste_treffer('gesundheit', v_text);
  if v_treffer is not null then
    raise exception 'notiz_anlegen: Die Notiz enthaelt "%". Das deutet auf eine Gesundheitsangabe hin, und die gehoert nicht in die Akte. Bitte umformulieren.', v_treffer
      using errcode = '22023',
            hint = 'gesundheitsbegriff:' || v_treffer;
  end if;

  insert into public.schueler_notizen (student_id, kategorie, text, autor_id, autor_rolle)
  values (p_student_id, p_kategorie, v_text, auth.uid(), v_rolle)
  returning id into v_id;

  insert into public.audit_log (actor, aktion, objekt_typ, objekt_id)
  values (auth.uid(), 'notiz_anlegen', 'schueler_notiz', v_id);

  return v_id;
end;
$$;


--
-- Name: notiz_ausblenden(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notiz_ausblenden(p_notiz_id uuid, p_grund text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_grund text := nullif(btrim(coalesce(p_grund, '')), '');
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'notiz_ausblenden: nur Admin' using errcode = '42501';
  end if;
  if v_grund is null then
    raise exception 'notiz_ausblenden: ein Grund ist Pflicht' using errcode = '22023';
  end if;

  update public.schueler_notizen
     set ausgeblendet_am = now(), ausgeblendet_von = auth.uid(), ausgeblendet_grund = v_grund
   where id = p_notiz_id and entfernt_am is null;
  if not found then
    raise exception 'notiz_ausblenden: Notiz nicht gefunden oder schon entfernt' using errcode = 'P0002';
  end if;

  perform public.audit_log_schreiben('notiz_ausblenden', 'schueler_notiz', p_notiz_id);
end;
$$;


--
-- Name: notiz_einblenden(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notiz_einblenden(p_notiz_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'notiz_einblenden: nur Admin' using errcode = '42501';
  end if;

  update public.schueler_notizen
     set ausgeblendet_am = null, ausgeblendet_von = null, ausgeblendet_grund = null
   where id = p_notiz_id and entfernt_am is null;
  if not found then
    raise exception 'notiz_einblenden: Notiz nicht gefunden oder schon entfernt' using errcode = 'P0002';
  end if;

  perform public.audit_log_schreiben('notiz_einblenden', 'schueler_notiz', p_notiz_id);
end;
$$;


--
-- Name: notiz_gesundheit_entfernen(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notiz_gesundheit_entfernen(p_notiz_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'notiz_gesundheit_entfernen: nur Admin' using errcode = '42501';
  end if;

  update public.schueler_notizen
     set text = null, entfernt_am = now(), entfernt_von = auth.uid(), entfernt_grund = 'gesundheitsangabe'
   where id = p_notiz_id and entfernt_am is null;
  if not found then
    raise exception 'notiz_gesundheit_entfernen: Notiz nicht gefunden oder schon entfernt' using errcode = 'P0002';
  end if;

  perform public.audit_log_schreiben('notiz_gesundheit_entfernen', 'schueler_notiz', p_notiz_id);
end;
$$;


--
-- Name: pfad_tiefer(uuid, text, uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pfad_tiefer(p_student_id uuid, p_skill_key text, p_session_id uuid DEFAULT NULL::uuid, p_voraussetzung text DEFAULT NULL::text, p_anlass text DEFAULT 'warmup'::text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_ziel     text;
  v_alt      public.lernpfad;
begin
  if not (public.ist_systemaufruf()
          or coalesce(public.get_my_role(), '') = 'admin'
          or public.lernpfad_coach_der_session(p_session_id, p_student_id)) then
    raise exception 'pfad_tiefer: nur Coach der Session oder Admin' using errcode = '42501';
  end if;
  if p_anlass is null or p_anlass not in ('warmup', 'eingriff') then
    raise exception 'pfad_tiefer: Anlass muss warmup oder eingriff sein' using errcode = '22023';
  end if;
  if not exists (select 1 from public.skills where skill_key = p_skill_key) then
    raise exception 'pfad_tiefer: Skill % unbekannt', p_skill_key using errcode = 'P0002';
  end if;

  if p_voraussetzung is not null then
    if p_voraussetzung not in (select a.skill_key from public.lsa_abschluss(p_skill_key) a) then
      raise exception 'pfad_tiefer: % ist keine Voraussetzung von %', p_voraussetzung, p_skill_key
        using errcode = '22023';
    end if;
    v_ziel := p_voraussetzung;
  else
    -- Direkte Voraussetzung, die noch nicht sicher ist: zuerst belegte
    -- Luecken, dann aktive, dann unbekannte; bei Gleichstand die hoehere Klasse.
    select k.voraussetzt_skill_key into v_ziel
      from public.skill_kante k
      join public.skills s on s.skill_key = k.voraussetzt_skill_key
      left join public.lernpfad l on l.student_id = p_student_id and l.skill_key = k.voraussetzt_skill_key
     where k.skill_key = p_skill_key
       and coalesce(l.stand_system, 'offen') not in ('sicher', 'kandidat')
       and l.stand_coach is distinct from 'gemeistert'
     order by case coalesce(l.stand_system, 'offen')
                when 'noch_nicht_sicher' then 0 when 'aktiv' then 1 else 2 end,
              s.klasse_herkunft desc, k.voraussetzt_skill_key
     limit 1;
    if v_ziel is null then
      raise exception 'pfad_tiefer: % hat keine offene Voraussetzung', p_skill_key using errcode = 'P0002';
    end if;
  end if;

  select * into v_alt from public.lernpfad
   where student_id = p_student_id and skill_key = v_ziel
   for update;
  if v_alt.stand_system = 'kandidat' or v_alt.stand_coach = 'gemeistert' then
    raise exception 'pfad_tiefer: % ist Mastery-Kandidat oder gemeistert', v_ziel using errcode = 'P0001';
  end if;

  insert into public.lernpfad (student_id, skill_key, stand_system, quelle)
  values (p_student_id, v_ziel, 'aktiv', 'coach')
  on conflict (student_id, skill_key) do update
     set stand_system      = 'aktiv',
         stand_system_seit = case when public.lernpfad.stand_system = 'aktiv'
                                  then public.lernpfad.stand_system_seit else now() end,
         aktualisiert      = now();

  -- Der bisherige Skill wartet, bis die Voraussetzung sitzt.
  insert into public.lernpfad (student_id, skill_key, stand_system, quelle)
  values (p_student_id, p_skill_key, 'offen', 'coach')
  on conflict (student_id, skill_key) do update
     set stand_system      = 'offen',
         stand_system_seit = now(),
         aktualisiert      = now()
   where public.lernpfad.stand_system = 'aktiv';

  -- Jeder Aufruf wird protokolliert: wer, wann, Session, Anlass (Rasit 06.10.).
  insert into public.lernpfad_protokoll (student_id, skill_key, aktion, anlass, alt, neu, von, session_id)
  values (p_student_id, v_ziel, 'pfad_tiefer', p_anlass,
          jsonb_build_object('stand_system', v_alt.stand_system),
          jsonb_build_object('stand_system', 'aktiv', 'statt', p_skill_key),
          auth.uid(), p_session_id);

  return v_ziel;
end;
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
-- Name: profil_fuer_coach_sichtbar(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.profil_fuer_coach_sichtbar(p_profile_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  select exists (
    select 1 from public.profiles p
     where p.id = p_profile_id
       and (p.id = auth.uid()
            or p.role in ('admin', 'coach')
            or (p.role = 'student'
                and exists (select 1 from public.students s
                             where s.profile_id = p.id and public.akte_aktiv(s.id))))
  );
$$;


--
-- Name: pruef_acceptance_angleichen(jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_acceptance_angleichen(p_acc jsonb, p_ca jsonb) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
  select case
    when jsonb_typeof(p_acc) is distinct from 'object' then p_acc
    when p_acc ? 'canonical' then public.pruef_liste_setzen(p_acc, p_ca)
    when jsonb_typeof(p_ca) = 'object' then coalesce((
      select jsonb_object_agg(k, case when jsonb_typeof(v) = 'object' and v ? 'canonical'
                                      then public.pruef_liste_setzen(v, p_ca -> k) else v end)
        from jsonb_each(p_acc) e(k, v)), p_acc)
    else p_acc end
$$;


--
-- Name: pruef_admin_freigeben(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_admin_freigeben(p_task_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare t public.tasks;
begin
  perform public.pruef_nur_admin('pruef_admin_freigeben');
  select * into t from public.tasks where id = p_task_id for update;
  if not found then
    raise exception 'pruef_admin_freigeben: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if t.status = 'ready' then perform public.pruef_fehler('freigegeben'); end if;
  perform public.task_status_set(p_task_id, 'ready');
  perform public.pruef_protokoll(p_task_id, 'freigeben', '[]', null, false);
  return jsonb_build_object('status', 'ready');
end $$;


--
-- Name: pruef_admin_gruende(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_admin_gruende() RETURNS text[]
    LANGUAGE sql IMMUTABLE
    AS $$
  select array['aufgabe_fehlerhaft', 'aufgabe_unklar', 'bild_falsch', 'sprache_zu_schwer', 'tablet_umbauen',
               'passt_nicht_in_lsa', 'sonstiges', 'fehlbild_falsch', 'fehlbild_unrealistisch',
               'zahlen_unguenstig', 'formulierung', 'didaktisch', 'kontext', 'loesung_passt_nicht']
$$;


--
-- Name: pruef_admin_liste(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_admin_liste() RETURNS TABLE(task_id uuid, lena_status text, ausschluss text, pilot boolean, entscheidung text, gruende text[], notiz text, aenderungen jsonb, aenderung_grund text, dauer_sek integer, geprueft_von text, geprueft_am timestamp with time zone, antwort text, beantwortet_am timestamp with time zone, geaendert boolean, ausschluss_grund text, ausschluss_von text, ausschluss_am timestamp with time zone)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'pruef_admin_liste: nur admin' using errcode = '42501';
  end if;
  return query
  select t.id, public.pruef_lena_status(t.status), public.pruef_ausschluss(t.id), t.pruef_pilot,
         lp.entscheidung, lp.gruende, lp.notiz, lp.aenderungen, lp.aenderung_grund, lp.dauer_sek,
         pr.full_name, lp.geprueft_am, lp.antwort, lp.beantwortet_am,
         coalesce(jsonb_array_length(lp.aenderungen) > 0, false),
         h.grund, hv.full_name, h.am
    from public.tasks t
    left join lateral (select p.* from public.task_pruefungen p where p.task_id = t.id
                        order by p.geprueft_am desc limit 1) lp on true
    left join public.profiles pr on pr.id = lp.geprueft_von
    left join public.task_pruef_ausschluss h on h.task_id = t.id
    left join public.profiles hv on hv.id = h.von;
end $$;


--
-- Name: pruef_admin_zurueckweisen(uuid, text[], text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_admin_zurueckweisen(p_task_id uuid, p_gruende text[], p_notiz text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  t public.tasks; g text;
  notiz text := nullif(btrim(p_notiz), '');
  gruende text[] := array(select distinct btrim(x) from unnest(coalesce(p_gruende, '{}')) x where btrim(x) <> '');
begin
  perform public.pruef_nur_admin('pruef_admin_zurueckweisen');
  select * into t from public.tasks where id = p_task_id for update;
  if not found then
    raise exception 'pruef_admin_zurueckweisen: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if t.status = 'ready' then perform public.pruef_fehler('freigegeben'); end if;
  if cardinality(gruende) = 0 then perform public.pruef_fehler('grund_fehlt'); end if;
  if not gruende <@ public.pruef_admin_gruende() then perform public.pruef_fehler('grund_unbekannt'); end if;
  update public.tasks set status = 'beanstandet', reviewed_by = null, reviewed_at = null where id = p_task_id;
  foreach g in array gruende loop
    insert into public.task_reviews (task_id, kategorie, notiz, geprueft_von, geprueft_am)
    values (p_task_id, g, notiz, auth.uid(), clock_timestamp());
  end loop;
  perform public.pruef_protokoll(p_task_id, 'zurueckweisen', '[]', notiz, false);
  return jsonb_build_object('status', 'beanstandet');
end $$;


--
-- Name: pruef_aenderungen(jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_aenderungen(p_vorher jsonb, p_nachher jsonb) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
  with
  wv as (select (w ->> 'teil')::int teil, coalesce((select jsonb_agg(x ->> 'wert') from jsonb_array_elements(w -> 'werte') x), '[]') l
           from jsonb_array_elements(coalesce(p_vorher -> 'werte', '[]')) w),
  wn as (select (w ->> 'teil')::int teil, coalesce((select jsonb_agg(x ->> 'wert') from jsonb_array_elements(w -> 'werte') x), '[]') l
           from jsonb_array_elements(coalesce(p_nachher -> 'werte', '[]')) w),
  rv as (select nullif(p_vorher -> 'regel', 'null') r), rn as (select nullif(p_nachher -> 'regel', 'null') r),
  fv as (select f ->> 'slug' slug, f - 'slug' || jsonb_build_object('werte', (select jsonb_agg(x order by x ->> 'teil', x ->> 'wert') from jsonb_array_elements(f -> 'werte') x)) f
           from jsonb_array_elements(coalesce(p_vorher -> 'fehler', '[]')) f),
  fn as (select f ->> 'slug' slug, f - 'slug' || jsonb_build_object('werte', (select jsonb_agg(x order by x ->> 'teil', x ->> 'wert') from jsonb_array_elements(f -> 'werte') x)) f
           from jsonb_array_elements(coalesce(p_nachher -> 'fehler', '[]')) f),
  l(n, e) as (
    select 1, jsonb_build_object('feld', 'richtige_antwort', 'teil', coalesce(wv.teil, wn.teil),
                                 'vorher', coalesce(wv.l, '[]'), 'nachher', coalesce(wn.l, '[]'))
      from wv full join wn on coalesce(wv.teil, 0) = coalesce(wn.teil, 0)
     where wv.l is distinct from wn.l
    union all
    select 2, jsonb_build_object('feld', 'wertung', 'teil', null,
             'vorher', rv.r - array['einheit_pflicht', 'einheit', 'einheit_am_feld'],
             'nachher', rn.r - array['einheit_pflicht', 'einheit', 'einheit_am_feld'])
      from rv, rn
     where (rv.r - array['einheit_pflicht', 'einheit', 'einheit_am_feld'])
           is distinct from (rn.r - array['einheit_pflicht', 'einheit', 'einheit_am_feld'])
    union all
    select 3, jsonb_build_object('feld', 'einheit_pflicht', 'teil', null,
             'vorher', coalesce(rv.r -> 'einheit_pflicht', 'false'), 'nachher', coalesce(rn.r -> 'einheit_pflicht', 'false'))
      from rv, rn
     where coalesce(rv.r -> 'einheit_pflicht', 'false') <> coalesce(rn.r -> 'einheit_pflicht', 'false')
    union all
    select 4, jsonb_build_object('feld', 'typischer_fehler', 'teil', null,
             'vorher', case when fv.slug is not null then jsonb_build_object('slug', fv.slug) || fv.f end,
             'nachher', case when fn.slug is not null then jsonb_build_object('slug', fn.slug) || fn.f end)
      from fv full join fn on fv.slug = fn.slug
     where fv.f is distinct from fn.f
    union all
    select 5, jsonb_build_object('feld', 'fertigkeit', 'teil', null,
             'vorher', p_vorher -> 'skill_key', 'nachher', p_nachher -> 'skill_key')
     where p_vorher -> 'skill_key' is distinct from p_nachher -> 'skill_key'
    union all
    select 6, jsonb_build_object('feld', 'anforderungsbereich', 'teil', null,
             'vorher', p_vorher -> 'afb', 'nachher', p_nachher -> 'afb')
     where p_vorher -> 'afb' is distinct from p_nachher -> 'afb')
  select coalesce(jsonb_agg(e order by n, e ->> 'teil', e -> 'vorher' ->> 'slug', e -> 'nachher' ->> 'slug'), '[]') from l
$$;


--
-- Name: pruef_an_lena(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_an_lena(p_task_id uuid, p_nachricht text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare t public.tasks;
begin
  perform public.pruef_nur_admin('pruef_an_lena');
  select * into t from public.tasks where id = p_task_id for update;
  if not found then
    raise exception 'pruef_an_lena: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if t.status = 'ready' then perform public.pruef_fehler('freigegeben'); end if;
  perform public.pruef_an_lena_schreiben(p_task_id, p_nachricht, null, false);
  return jsonb_build_object('status', 'draft');
end $$;


--
-- Name: pruef_an_lena_schreiben(uuid, text, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_an_lena_schreiben(p_task_id uuid, p_nachricht text, p_grund text, p_sammel boolean) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare v_id uuid; n text := nullif(btrim(p_nachricht), '');
begin
  update public.tasks set status = 'draft', reviewed_by = null, reviewed_at = null where id = p_task_id;
  delete from public.task_pruefung_ausgang where task_id = p_task_id;
  if n is not null then
    select p.id into v_id from public.task_pruefungen p where p.task_id = p_task_id
     order by p.geprueft_am desc limit 1;
    if v_id is not null then
      update public.task_pruefungen
         set antwort = n, beantwortet_von = auth.uid(), beantwortet_am = now()
       where id = v_id;
    end if;
  end if;
  perform public.pruef_protokoll(p_task_id, 'an_lena', '[]', coalesce(nullif(btrim(p_grund), ''), n), p_sammel);
end $$;


--
-- Name: vorbefuellt_valid(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.vorbefuellt_valid(p jsonb) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $$
  select jsonb_typeof(p) = 'object'
     and not exists (
       select 1 from jsonb_each(p) as e(k, v)
        where btrim(k) = ''
           or jsonb_typeof(v) <> 'object'
           or coalesce(v ->> 'art', '') not in ('neu', 'ueberschrieben', 'ergaenzt', 'leer')
           or coalesce(btrim(v ->> 'grund'), '') = ''
           or v ?| array['alt', 'wert', 'neu']
     )
$$;


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
    vorbefuellt jsonb DEFAULT '{}'::jsonb NOT NULL,
    vorbefuellt_am timestamp with time zone,
    pruef_version bigint DEFAULT 1 NOT NULL,
    pruef_pilot boolean DEFAULT false NOT NULL,
    einsatz text[] DEFAULT '{lsa,session}'::text[] NOT NULL,
    CONSTRAINT tasks_afb_check CHECK ((afb = ANY (ARRAY['I'::text, 'II'::text, 'III'::text]))),
    CONSTRAINT tasks_class_level_check CHECK (((class_level >= 5) AND (class_level <= 13))),
    CONSTRAINT tasks_cognitive_type_check CHECK ((cognitive_type = ANY (ARRAY['FACT'::text, 'TRANSFER'::text, 'ANALYSIS'::text]))),
    CONSTRAINT tasks_content_type_check CHECK ((content_type = ANY (ARRAY['exercise'::text, 'exercise_group'::text, 'article'::text, 'video'::text, 'course'::text]))),
    CONSTRAINT tasks_curriculum_grade_check CHECK (((curriculum_grade IS NULL) OR ((curriculum_grade >= 5) AND (curriculum_grade <= 13)))),
    CONSTRAINT tasks_difficulty_check CHECK (((difficulty >= 1) AND (difficulty <= 5))),
    CONSTRAINT tasks_einsatz_check CHECK ((einsatz <@ ARRAY['lsa'::text, 'session'::text, 'check'::text, 'quest'::text])),
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
    CONSTRAINT tasks_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'review'::text, 'ready'::text, 'beanstandet'::text, 'rueckfrage'::text]))),
    CONSTRAINT tasks_vorbefuellt_check CHECK (public.vorbefuellt_valid(vorbefuellt))
);


--
-- Name: pruef_auffaelligkeiten(public.tasks, jsonb, jsonb, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_auffaelligkeiten(p_task public.tasks, p_ca jsonb, p_acc jsonb, p_solution text) RETURNS jsonb
    LANGUAGE plpgsql STABLE
    SET search_path TO 'public', 'pg_temp'
    AS $_$
declare
  it    text := p_task.input_type;
  acc   jsonb := nullif(p_acc, 'null'::jsonb);
  ca    jsonb := coalesce(p_ca, '[]');
  flach boolean := public.pruef_flach_regel(it, acc);
  ke    jsonb;
  r     jsonb := '[]';
  treffer jsonb;
  x text; rest text; zahl text; stufe text; p jsonb; kind text; liste jsonb;
begin
  if it not in ('MULTI_PART', 'MC', 'TERM') then
    ke := case when jsonb_typeof(acc -> 'known_errors') = 'object' then acc -> 'known_errors' else '{}' end;
    -- fehler_als_richtig: ein typischer Fehler wuerde als voll gewertet
    treffer := coalesce((select jsonb_agg(k order by length(k), k) from jsonb_object_keys(ke) k
      where case when flach then public.lsa_grade(it, acc, ca, jsonb_build_object('text', k)) = 'voll'
                 else coalesce(public.lsa_is_correct(it, ca, jsonb_build_object('text', k)), false) end), '[]');
    r := r || coalesce((select jsonb_agg(jsonb_build_object('code', 'fehler_als_richtig', 'teil', null, 'wert', g ->> 0))
                          from jsonb_array_elements(public.pruef_gruppen(treffer)) g), '[]');
    -- werte_widersprechen: ein richtiger Wert waere nach lsa_grade nicht voll. Fehlt bei
    -- "Einheit muss dabei sein" nur die Einheit, ist "teilweise" gewollt und kein Widerspruch.
    if flach then
      treffer := coalesce((select jsonb_agg(v) from jsonb_array_elements_text(ca) v
        where public.lsa_grade(it, acc, ca, jsonb_build_object('text', v)) is distinct from 'voll'
          and not (coalesce((acc ->> 'unit_graded')::boolean, false) and public.pruef_einheit_von(v) is null
                   and public.lsa_grade(it, acc, ca, jsonb_build_object('text', v)) = 'teilweise')), '[]');
      r := r || coalesce((select jsonb_agg(jsonb_build_object('code', 'werte_widersprechen', 'teil', null, 'wert', g ->> 0))
                            from jsonb_array_elements(public.pruef_gruppen(treffer)) g), '[]');
    end if;
    -- loesungsweg_endet_falsch: letzte Zahl nach dem letzten "=" oder "≈"
    if it = 'NUMERIC' and p_solution is not null then
      rest := substring(p_solution from '.*[=≈](.*)$');
      select m[1] into zahl
        from regexp_matches(coalesce(rest, ''),
               '([-+−–]?\s?[0-9]+(?:[.,][0-9]+)?(?:/[0-9]+)?(?:\s?[a-zA-ZäöüßÄÖÜ°%€²³]+)?)', 'g')
             with ordinality t(m, i)
       order by i desc limit 1;
      if zahl is not null then
        stufe := case when flach then public.lsa_grade(it, acc, ca, jsonb_build_object('text', btrim(zahl)))
                      when coalesce(public.lsa_is_correct(it, ca, jsonb_build_object('text', btrim(zahl))), false)
                      then 'voll' else 'nicht' end;
        if stufe <> 'voll' then
          r := r || jsonb_build_array(jsonb_build_object('code', 'loesungsweg_endet_falsch', 'teil', null,
                                                         'wert', btrim(zahl), 'stufe', stufe));
        end if;
      end if;
    end if;
  elsif it = 'MC' then
    ke := case when jsonb_typeof(acc -> 'known_errors') = 'object' then acc -> 'known_errors' else '{}' end;
    if ke ? (ca ->> 0) then
      r := r || jsonb_build_array(jsonb_build_object('code', 'mc_richtig_ist_fehler', 'teil', null, 'wert', ca ->> 0));
    end if;
    r := r || coalesce((select jsonb_agg(jsonb_build_object('code', 'mc_ablenker_ohne_fehlbild', 'teil', null, 'wert', o ->> 'id') order by i)
                          from jsonb_array_elements(coalesce(p_task.question_payload -> 'options', '[]')) with ordinality q(o, i)
                         where not (ca ? (o ->> 'id')) and not (ke ? (o ->> 'id'))), '[]');
  elsif it = 'MULTI_PART' then
    for p in select e from jsonb_array_elements(p_task.parts) e loop
      kind := p ->> 'kind';
      liste := case when jsonb_typeof(ca -> (p ->> 'nr')) = 'array' then ca -> (p ->> 'nr') else '[]' end;
      ke := case when jsonb_typeof(acc -> (p ->> 'nr') -> 'known_errors') = 'object'
                 then acc -> (p ->> 'nr') -> 'known_errors' else '{}' end;
      r := r || coalesce((select jsonb_agg(jsonb_build_object('code', 'teil_fehler_ist_richtig', 'teil', (p ->> 'nr')::int, 'wert', k) order by length(k), k)
                            from jsonb_object_keys(ke) k
                           where coalesce(public.lsa_is_correct(case when kind = 'mc' then 'MC' else 'SHORT_TEXT' end,
                                   liste, public.lsa_part_answer(kind, to_jsonb(k))), false)), '[]');
      if kind = 'mc' then
        r := r || coalesce((select jsonb_agg(jsonb_build_object('code', 'mc_ablenker_ohne_fehlbild', 'teil', (p ->> 'nr')::int, 'wert', o ->> 'id') order by i)
                              from jsonb_array_elements(coalesce(p -> 'options', '[]')) with ordinality q(o, i)
                             where not (liste ? (o ->> 'id')) and not (ke ? (o ->> 'id'))), '[]');
      end if;
    end loop;
  end if;
  return r;
end $_$;


--
-- Name: pruef_aufgabe(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_aufgabe(p_task_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  t public.tasks; s public.task_solutions; aus jsonb; sicht jsonb; sicht_aus jsonb;
  ausschluss text; sk_aus text; th record; lp record;
  admin boolean := public.get_my_role() is not distinct from 'admin';
begin
  if not public.darf_pruefen() then
    raise exception 'pruef_aufgabe: kein Pruefrecht' using errcode = '42501';
  end if;
  select * into t from public.tasks where id = p_task_id;
  if not found then
    raise exception 'pruef_aufgabe: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  ausschluss := public.pruef_ausschluss(p_task_id);
  if t.status <> 'ready' and coalesce(ausschluss, '') not in ('vera8', 'inaktiv', 'typ')
     and (admin or (ausschluss is distinct from 'hand' and public.pruef_im_pilot(t)
                    and not public.pruef_team_beanstandet(p_task_id))) then
    aus := public.pruef_ausgang_sichern(p_task_id);
  else
    select a.ausgang into aus from public.task_pruefung_ausgang a where a.task_id = p_task_id;
  end if;
  select * into s from public.task_solutions where task_id = p_task_id;
  sicht := public.pruef_sicht(t, public.pruef_fassung(p_task_id));
  sicht_aus := case when aus is not null then public.pruef_sicht(t, aus) end;
  sk_aus := coalesce(aus ->> 'skill_key', t.skill_key);
  select x.thema_key, x.label, x.stufe into th
    from public.skill_thema st join public.themen x on x.thema_key = st.thema_key
   where st.skill_key = sk_aus;
  select * into lp from public.task_pruefungen where task_id = p_task_id order by geprueft_am desc limit 1;

  return jsonb_build_object(
    'task_id', t.id,
    'kopf', jsonb_build_object('kurztitel', public.pruef_kurztitel(t.title), 'stufe', th.stufe,
              'thema_key', th.thema_key, 'thema_label', th.label,
              'hilfsmittel', (select e.hilfsmittel from public.pruef_einstellungen e limit 1)),
    'aufgabe', jsonb_build_object(
      'input_type', t.input_type, 'unit', t.unit, 'status', t.status,
      'lena_status', public.pruef_lena_status(t.status), 'pruef_version', t.pruef_version,
      'ausschluss', ausschluss, 'pilot', t.pruef_pilot,
      'team_beanstandet', public.pruef_team_beanstandet(p_task_id),
      'parts', coalesce((select jsonb_agg(jsonb_build_object('nr', (p ->> 'nr')::int, 'kind', p ->> 'kind',
                 'prompt', p ->> 'prompt', 'unit', p ->> 'unit',
                 'options', coalesce((select jsonb_agg(jsonb_build_object('id', o ->> 'id', 'label', o ->> 'label') order by i)
                                        from jsonb_array_elements(coalesce(p -> 'options', '[]')) with ordinality z(o, i)), '[]'))
                 order by k) from jsonb_array_elements(t.parts) with ordinality q(p, k)), '[]'),
      'optionen', coalesce((select jsonb_agg(jsonb_build_object('id', o ->> 'id', 'label', o ->> 'label') order by i)
                              from jsonb_array_elements(case when t.input_type = 'MC'
                                     then coalesce(t.question_payload -> 'options', '[]') else '[]' end)
                                   with ordinality z(o, i)), '[]'),
      'bild_vorhanden', jsonb_array_length(t.assets) > 0
                        or exists (select 1 from public.task_figures f where f.task_id = t.id and f.svg_hash is not null)),
    'werte', sicht -> 'werte', 'mc', sicht -> 'mc', 'regel', sicht -> 'regel',
    'fehler', coalesce((select jsonb_agg(f || jsonb_build_object('klartext', fl.klartext) order by f ->> 'slug')
                          from jsonb_array_elements(sicht -> 'fehler') f
                          left join public.fehlbild_labels fl on fl.slug = f ->> 'slug'), '[]'),
    'weitere_hinweise', sicht -> 'weitere_hinweise',
    'flach_regel', sicht -> 'flach_regel', 'ohne_erkennung', sicht -> 'ohne_erkennung',
    'loesungsweg', s.solution,
    'fertigkeit', (select jsonb_build_object('key', k.skill_key, 'label', k.label, 'thema_key', x.thema_key,
                     'thema_label', x.label, 'stufe', x.stufe,
                     'voraussetzungen', coalesce((select jsonb_agg(v.label order by v.fundament_tiefe, v.skill_key)
                                                    from public.skill_kante sk join public.skills v on v.skill_key = sk.voraussetzt_skill_key
                                                   where sk.skill_key = k.skill_key), '[]'))
                     from public.skills k
                     left join public.skill_thema st on st.skill_key = k.skill_key
                     left join public.themen x on x.thema_key = st.thema_key
                    where k.skill_key = t.skill_key),
    'fertigkeit_optionen', public.pruef_fertigkeit_optionen(sk_aus),
    'afb', t.afb, 'afb_sicher', t.vorbefuellt #>> '{afb,sicher}',
    'ausgang', sicht_aus,
    'aenderungen', case when sicht_aus is not null then public.pruef_aenderungen(sicht_aus, sicht) else '[]'::jsonb end,
    'letzte_pruefung', case when lp.id is not null then jsonb_build_object(
      'entscheidung', lp.entscheidung, 'gruende', to_jsonb(lp.gruende), 'notiz', lp.notiz,
      'antwort', lp.antwort, 'beantwortet_am', lp.beantwortet_am, 'geprueft_am', lp.geprueft_am) end,
    'auffaelligkeiten', public.pruef_auffaelligkeiten(t, coalesce(s.correct_answers, '[]'), s.acceptance, s.solution));
end $$;


--
-- Name: pruef_ausgang_sichern(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_ausgang_sichern(p_task_id uuid) RETURNS jsonb
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare v jsonb;
begin
  insert into public.task_pruefung_ausgang (task_id, ausgang)
  values (p_task_id, public.pruef_fassung(p_task_id))
  on conflict (task_id) do nothing;
  select ausgang into v from public.task_pruefung_ausgang where task_id = p_task_id;
  return v;
end $$;


--
-- Name: pruef_ausschluss(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_ausschluss(p_task_id uuid) RETURNS text
    LANGUAGE sql STABLE
    SET search_path TO 'public', 'pg_temp'
    AS $$
  select case
    when t.source = 'VERA8_IQB' then 'vera8'
    when not coalesce(t.is_active, false) or t.is_tutorial or t.content_type <> 'exercise' then 'inaktiv'
    when t.input_type is null
      or t.input_type not in ('MC', 'NUMERIC', 'SHORT_TEXT', 'MULTI_PART', 'TERM') then 'typ'
    when exists (select 1 from public.task_pruef_ausschluss h where h.task_id = t.id) then 'hand'
    when t.skill_key is null
      or not exists (select 1 from public.skill_thema st where st.skill_key = t.skill_key) then 'ohne_fertigkeit'
    when not exists (select 1 from public.task_solutions s where s.task_id = t.id
                        and public.lsa_has_answers(t.input_type, t.parts, s.correct_answers)) then 'ohne_loesung'
    when public.freigabe_gate_fehler(t.id) is not null then 'gate'
    when (coalesce(t.needs_image, false)
          or exists (select 1 from jsonb_array_elements(t.parts) p where p -> 'needs_image' = 'true'::jsonb))
     and jsonb_array_length(t.assets) = 0
     and not exists (select 1 from public.task_figures f where f.task_id = t.id and f.svg_hash is not null)
      then 'bild_fehlt'
  end
  from public.tasks t where t.id = p_task_id
$$;


--
-- Name: pruef_board(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_board() RETURNS TABLE(task_id uuid, stufe text, thema_key text, thema_label text, thema_sort integer, skill_key text, skill_label text, kurztitel text, reihenfolge bigint, lena_status text, geaendert boolean, letzte_dauer_sek integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  if not public.darf_pruefen() then
    raise exception 'pruef_board: kein Pruefrecht' using errcode = '42501';
  end if;
  return query
  with b as (
    select t.id, t.title, t.status, t.source_ref, t.skill_key sk_jetzt,
           coalesce(a.ausgang ->> 'skill_key', t.skill_key) sk,
           case when a.task_id is not null then (a.ausgang ->> 'sondierrang')::int else t.sondierrang end sr
      from public.tasks t
      left join public.task_pruefung_ausgang a on a.task_id = t.id
     where public.pruef_ausschluss(t.id) is null
       and (t.pruef_pilot or not coalesce((select e.nur_pilot from public.pruef_einstellungen e limit 1), false)))
  select b.id, th.stufe, th.thema_key, th.label, th.sort, b.sk_jetzt, sj.label,
         public.pruef_kurztitel(b.title),
         row_number() over (order by case th.stufe when 'erste' then 1 when 'zweite' then 2 else 3 end,
                                     th.sort nulls last, s.fundament_tiefe, b.sk, b.sr nulls last,
                                     b.source_ref, b.id),
         public.pruef_lena_status(b.status),
         coalesce(jsonb_array_length(lp.aenderungen) > 0, false),
         lp.dauer_sek
    from b
    join public.skills s on s.skill_key = b.sk
    join public.skill_thema st on st.skill_key = b.sk
    join public.themen th on th.thema_key = st.thema_key
    left join public.skills sj on sj.skill_key = b.sk_jetzt
    left join lateral (select p.aenderungen, p.dauer_sek from public.task_pruefungen p
                        where p.task_id = b.id order by p.geprueft_am desc limit 1) lp on true;
end $$;


--
-- Name: pruef_einheit(jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_einheit(p_acceptance jsonb, p_ca jsonb) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  select coalesce(nullif(btrim(p_acceptance ->> 'unit'), ''),
                  public.pruef_einheit_von(p_acceptance ->> 'canonical'),
                  (select public.pruef_einheit_von(x) from jsonb_array_elements_text(
                     case when jsonb_typeof(p_ca) = 'array' then p_ca else '[]' end)
                     with ordinality e(x, i)
                    where public.pruef_einheit_von(x) is not null order by i limit 1))
$$;


--
-- Name: pruef_einheit_von(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_einheit_von(p_wert text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  select case when public.pruef_ist_zahl(p_wert) then nullif(btrim(regexp_replace(btrim(p_wert),
    '^[-+−–]?\s?[0-9]+(?:\s+[0-9]+/[0-9]+|/[0-9]+|[.,][0-9]+)?', '')), '') end
$$;


--
-- Name: pruef_entscheiden(uuid, bigint, text, text[], text, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_entscheiden(p_task_id uuid, p_version bigint, p_entscheidung text, p_gruende text[] DEFAULT NULL::text[], p_notiz text DEFAULT NULL::text, p_aenderung_grund text DEFAULT NULL::text, p_dauer_sek integer DEFAULT NULL::integer) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  t public.tasks; aus jsonb; aend jsonb; neu text; g text;
  notiz text := nullif(btrim(p_notiz), '');
  grund text := nullif(btrim(p_aenderung_grund), '');
  gruende text[] := array(select distinct btrim(x) from unnest(coalesce(p_gruende, '{}')) x where btrim(x) <> '');
begin
  t := public.pruef_sperren(p_task_id, p_version);
  perform public.pruef_lena_sperren(t);
  if p_entscheidung is null or p_entscheidung not in ('passt', 'unsicher', 'passt_nicht') then
    raise exception 'pruef_entscheiden: unbekannte Entscheidung %', p_entscheidung using errcode = '22023';
  end if;
  aus := public.pruef_ausgang_sichern(p_task_id);
  aend := public.pruef_aenderungen(public.pruef_sicht(t, aus), public.pruef_sicht(t, public.pruef_fassung(p_task_id)));
  if jsonb_array_length(aend) > 0 and grund is null
     and coalesce((select e.grund_pflicht from public.pruef_einstellungen e limit 1), false) then
    perform public.pruef_fehler('aenderung_grund_fehlt');
  end if;

  if p_entscheidung = 'passt' then
    if not exists (select 1 from public.task_solutions s where s.task_id = p_task_id
                      and public.lsa_has_answers(t.input_type, t.parts, s.correct_answers)) then
      perform public.pruef_fehler('antwort_fehlt');
    end if;
    if public.freigabe_gate_fehler(p_task_id) is not null then
      perform public.pruef_fehler('gate', public.freigabe_gate_fehler(p_task_id));
    end if;
    neu := 'review';
    gruende := '{}';
  elsif p_entscheidung = 'unsicher' then
    if notiz is null then perform public.pruef_fehler('notiz_fehlt'); end if;
    neu := 'rueckfrage';
    gruende := '{}';
  else
    if cardinality(gruende) = 0 then perform public.pruef_fehler('grund_fehlt'); end if;
    if exists (select 1 from unnest(gruende) x where x not in ('aufgabe_fehlerhaft', 'aufgabe_unklar',
                 'bild_falsch', 'sprache_zu_schwer', 'tablet_umbauen', 'passt_nicht_in_lsa', 'sonstiges')) then
      perform public.pruef_fehler('grund_unbekannt');
    end if;
    if 'sonstiges' = any (gruende) and notiz is null then perform public.pruef_fehler('notiz_fehlt'); end if;
    neu := 'beanstandet';
    foreach g in array gruende loop
      insert into public.task_reviews (task_id, kategorie, notiz, geprueft_von, geprueft_am)
      values (p_task_id, g, notiz, auth.uid(), clock_timestamp());
    end loop;
  end if;

  -- Lena gibt nie frei: reviewed_by/at bleiben leer, die Freigabe stempelt task_status_set.
  update public.tasks set status = neu, reviewed_by = null, reviewed_at = null where id = p_task_id;
  insert into public.task_pruefungen (task_id, entscheidung, gruende, notiz, aenderungen, aenderung_grund,
                                      dauer_sek, geprueft_von, geprueft_am)
  values (p_task_id, p_entscheidung, gruende, notiz, aend, grund,
          least(greatest(p_dauer_sek, 0), 86400), auth.uid(), clock_timestamp());

  select * into t from public.tasks where id = p_task_id;
  return jsonb_build_object('pruef_version', t.pruef_version, 'lena_status', public.pruef_lena_status(t.status));
end $$;


--
-- Name: pruef_entwurf_anwenden(public.tasks, jsonb, jsonb, jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_entwurf_anwenden(p_task public.tasks, p_jetzt jsonb, p_ausgang jsonb, p_entwurf jsonb, p_option_scores jsonb) RETURNS jsonb
    LANGUAGE plpgsql STABLE
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  it       text := p_task.input_type;
  e        jsonb := coalesce(p_entwurf, '{}');
  ca       jsonb := coalesce(p_jetzt -> 'correct_answers', '[]');
  acc0     jsonb := nullif(p_jetzt -> 'acceptance', 'null'::jsonb);
  acc      jsonb := nullif(p_jetzt -> 'acceptance', 'null'::jsonb);
  acc_alt  jsonb := nullif(p_ausgang -> 'acceptance', 'null'::jsonb);
  te       jsonb := coalesce(nullif(p_jetzt -> 'typical_errors', 'null'::jsonb), '[]');
  flach    boolean := public.pruef_flach_regel(it, acc0);
  regel_ok boolean := public.pruef_regel_erlaubt(it, coalesce(p_jetzt -> 'correct_answers', '[]'), acc0);
  einheit  text := public.pruef_einheit(acc0, coalesce(p_jetzt -> 'correct_answers', '[]'));
  regel    jsonb := nullif(e -> 'regel', 'null'::jsonb);
  pflicht  boolean := coalesce((acc0 ->> 'unit_graded')::boolean, false);
  bereich  boolean := false;
  mitte    text;
  tol      numeric;
  sk       text := p_jetzt ->> 'skill_key';
  afb      text := p_jetzt ->> 'afb';
  sr       jsonb := coalesce(p_jetzt -> 'sondierrang', 'null');
  p jsonb; nr text; liste jsonb; ids jsonb; scope jsonb; ke jsonb;
begin
  -- Teilangaben der typischen Fehler muessen zu den Teilen passen.
  if exists (select 1 from jsonb_array_elements(coalesce(e -> 'fehler', '[]')) f,
                           jsonb_array_elements(coalesce(f -> 'werte', '[]')) v
              where case when it = 'MULTI_PART'
                         then not exists (select 1 from jsonb_array_elements(p_task.parts) q
                                           where q ->> 'nr' = v ->> 'teil')
                         else v ->> 'teil' is not null end) then
    perform public.pruef_fehler('teil_unbekannt');
  end if;

  -- Richtige Antwort
  if it = 'MC' and (e ? 'mc' or e ? 'werte') then
    liste := jsonb_build_array(coalesce(e ->> 'mc', e #>> '{werte,0,werte,0}'));
    ids := coalesce((select jsonb_agg(o -> 'id') from jsonb_array_elements(
             coalesce(p_task.question_payload -> 'options', '[]')) o), '[]');
    if liste ->> 0 is null or not ids @> liste then perform public.pruef_fehler('mc_unbekannt'); end if;
    if jsonb_typeof(p_option_scores) = 'object' and p_option_scores <> '{}' and liste is distinct from ca then
      perform public.pruef_fehler('options_bewertet');
    end if;
    ca := liste;
  elsif it = 'MULTI_PART' and e ? 'werte' then
    for p in select x from jsonb_array_elements(p_task.parts) x loop
      nr := p ->> 'nr';
      liste := (select x -> 'werte' from jsonb_array_elements(e -> 'werte') x where x ->> 'teil' = nr limit 1);
      continue when liste is null;
      liste := public.pruef_werte_schreiben(liste, '[]', null, false);
      if p ->> 'kind' = 'mc' then
        ids := coalesce((select jsonb_agg(o -> 'id') from jsonb_array_elements(coalesce(p -> 'options', '[]')) o), '[]');
        if not ids @> liste then perform public.pruef_fehler('mc_unbekannt'); end if;
        if jsonb_typeof(p_option_scores -> nr) = 'object' and (p_option_scores -> nr) <> '{}'
           and liste is distinct from ca -> nr then
          perform public.pruef_fehler('options_bewertet');
        end if;
      end if;
      ca := case when jsonb_typeof(ca) = 'object' then ca else '{}' end || jsonb_build_object(nr, liste);
    end loop;
  elsif e ? 'werte' then
    liste := coalesce((select x -> 'werte' from jsonb_array_elements(e -> 'werte') x limit 1), '[]');
    ca := case when flach
      then public.pruef_werte_schreiben(liste,
             public.pruef_gruppen(ca) || public.pruef_gruppen(coalesce(p_ausgang -> 'correct_answers', '[]')),
             einheit, true)
      else public.pruef_werte_schreiben(liste, '[]', null, false) end;
  end if;

  -- Gewertet wird (nur flach mit Regel)
  if regel is not null and it not in ('MC', 'MULTI_PART', 'TERM') then
    if regel ->> 'art' = 'bereich' then
      mitte := public.pruef_zahl_von(regel ->> 'mitte');
      begin
        tol := replace(regel ->> 'toleranz', ',', '.')::numeric;
      exception when others then
        tol := null;
      end;
      -- Der Bereich bleibt um den Wert: hoechstens so breit wie der Wert selbst (mindestens 1).
      if not regel_ok or mitte is null or tol is null or tol <= 0
         or tol > greatest(abs((public.lsa_parse_fraction(mitte))[1] / (public.lsa_parse_fraction(mitte))[2]), 1) then
        perform public.pruef_fehler('bereich_ungueltig');
      end if;
      bereich := true;
    end if;
    if coalesce((regel ->> 'einheit_pflicht')::boolean, false) <> pflicht then
      if not regel_ok then perform public.pruef_fehler('einheit_unzulaessig'); end if;
      if not pflicht and einheit is null then perform public.pruef_fehler('einheit_fehlt'); end if;
      if not pflicht and coalesce(btrim(p_task.unit), '') <> '' then perform public.pruef_fehler('einheit_am_feld'); end if;
      pflicht := not pflicht;
    end if;
  end if;

  -- acceptance: richtige Antwort, Regel, typische Fehler
  if it = 'MULTI_PART' then
    for p in select x from jsonb_array_elements(p_task.parts) x loop
      nr := p ->> 'nr';
      scope := nullif(acc -> nr, 'null'::jsonb);
      liste := case when jsonb_typeof(ca -> nr) = 'array' then ca -> nr else '[]' end;
      ke := case when e ? 'fehler'
        then public.pruef_known_errors(e -> 'fehler', nr::int,
               case when p ->> 'kind' = 'mc' then coalesce((select jsonb_agg(o -> 'id')
                 from jsonb_array_elements(coalesce(p -> 'options', '[]')) o), '[]') end,
               acc0, acc_alt, null)
        else scope -> 'known_errors' end;
      continue when scope is null and (coalesce(ke, '{}') = '{}' or jsonb_array_length(liste) = 0);
      scope := public.pruef_liste_setzen(coalesce(scope, '{}'), liste);
      scope := case when coalesce(ke, '{}') = '{}' then scope - 'known_errors'
                    else scope || jsonb_build_object('known_errors', ke) end;
      acc := coalesce(acc, '{}') || jsonb_build_object(nr, scope);
    end loop;
  elsif it = 'MC' then
    ke := case when e ? 'fehler'
      then public.pruef_known_errors(e -> 'fehler', null, coalesce((select jsonb_agg(o -> 'id')
             from jsonb_array_elements(coalesce(p_task.question_payload -> 'options', '[]')) o), '[]'),
             acc0, acc_alt, null)
      else acc -> 'known_errors' end;
    if acc is not null or coalesce(ke, '{}') <> '{}' then
      acc := public.pruef_liste_setzen(coalesce(acc, '{}'), ca);
      acc := case when coalesce(ke, '{}') = '{}' then acc - 'known_errors'
                  else acc || jsonb_build_object('known_errors', ke) end;
    end if;
  elsif flach then
    if bereich then
      acc := acc || jsonb_build_object(
        'canonical', mitte || case when pflicht then ' ' || einheit else '' end,
        'equivalents', '[]'::jsonb,
        'tolerance', jsonb_build_object('mode', 'absolute', 'value', tol));
    else
      acc := public.pruef_liste_setzen(acc, case when pflicht then public.pruef_mit_einheit(ca, einheit) else ca end);
      if regel is not null and acc #>> '{tolerance,mode}' = 'absolute' then acc := acc - 'tolerance'; end if;
    end if;
    if pflicht then
      acc := (acc || jsonb_build_object('unit_graded', true, 'unit', einheit)) #- '{notation,unit_optional}';
      if acc -> 'notation' = '{}'::jsonb then acc := acc - 'notation'; end if;
    elsif regel is not null then
      acc := acc - 'unit_graded';
    end if;
    if e ? 'fehler' then
      ke := public.pruef_known_errors(e -> 'fehler', null, null, acc0, acc_alt, einheit);
      acc := case when ke = '{}' then acc - 'known_errors' else acc || jsonb_build_object('known_errors', ke) end;
    end if;
  end if;
  -- TERM und flach ohne Regel: acceptance bleibt, wie es ist (TERM darf keins tragen, OP-3).

  -- Saetze zu den typischen Fehlern (typical_errors[].fehlbild)
  if e ? 'fehler' and (it in ('MC', 'MULTI_PART') or flach) then
    te := coalesce((select jsonb_agg(case when coalesce(t ->> 'fehlbild', '') = '' then t
                                          else t || jsonb_build_object('error', fl.satz) end order by i)
                      from jsonb_array_elements(te) with ordinality q(t, i)
                      left join lateral (select nullif(btrim(fx ->> 'text'), '') satz
                                           from jsonb_array_elements(e -> 'fehler') fx
                                          where fx ->> 'slug' = t ->> 'fehlbild' limit 1) fl on true
                     where coalesce(t ->> 'fehlbild', '') = '' or fl.satz is not null), '[]');
    te := te || coalesce((select jsonb_agg(jsonb_build_object('error', btrim(fx ->> 'text'),
                                   'socratic_question', '', 'fehlbild', fx ->> 'slug') order by i)
                            from jsonb_array_elements(e -> 'fehler') with ordinality q(fx, i)
                           where coalesce(btrim(fx ->> 'text'), '') <> ''
                             and not exists (select 1 from jsonb_array_elements(te) t
                                              where t ->> 'fehlbild' = fx ->> 'slug')), '[]');
  end if;

  -- Einordnung
  if e ? 'skill_key' and (e ->> 'skill_key') is distinct from sk then
    if not exists (select 1 from jsonb_array_elements(public.pruef_fertigkeit_optionen(
                     coalesce(p_ausgang ->> 'skill_key', sk))) o where o ->> 'key' = e ->> 'skill_key') then
      perform public.pruef_fehler('fertigkeit_unzulaessig');
    end if;
    sk := e ->> 'skill_key';
    -- Der Sondierrang gilt nur fuer die Fertigkeit, fuer die er berechnet wurde.
    sr := case when sk = p_ausgang ->> 'skill_key' then coalesce(p_ausgang -> 'sondierrang', 'null') else 'null' end;
  end if;
  if e ? 'afb' and (e ->> 'afb') is distinct from afb then
    if coalesce(e ->> 'afb', '') not in ('I', 'II', 'III') then perform public.pruef_fehler('afb_ungueltig'); end if;
    afb := e ->> 'afb';
  end if;

  if acc is not null and not public.lsa_acceptance_valid(acc) then
    perform public.pruef_fehler('regel_ungueltig');
  end if;
  return jsonb_build_object('skill_key', sk, 'afb', afb, 'sondierrang', sr,
    'correct_answers', ca, 'acceptance', acc, 'typical_errors', te);
end $$;


--
-- Name: pruef_fassung(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_fassung(p_task_id uuid) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'public', 'pg_temp'
    AS $$
  select jsonb_build_object(
    'skill_key', t.skill_key, 'afb', t.afb, 'sondierrang', t.sondierrang,
    'correct_answers', coalesce(s.correct_answers, '[]'), 'acceptance', s.acceptance,
    'typical_errors', coalesce(s.typical_errors, '[]'))
  from public.tasks t left join public.task_solutions s on s.task_id = t.id
  where t.id = p_task_id
$$;


--
-- Name: pruef_fehler(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_fehler(p_hint text, p_text text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
  raise exception '%', coalesce(p_text, 'pruefen: ' || p_hint) using errcode = 'ED422', hint = p_hint;
end $$;


--
-- Name: pruef_fehler_gruppen(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_fehler_gruppen(p_acc jsonb) RETURNS TABLE(slug text, teil integer, gruppen jsonb)
    LANGUAGE sql IMMUTABLE
    AS $_$
  with ke(teil, k, slug) as (
    select null::int, e.key, e.value #>> '{}'
      from jsonb_each(case when jsonb_typeof(p_acc -> 'known_errors') = 'object'
                           then p_acc -> 'known_errors' else '{}' end) e
    union all
    select p.key::int, e.key, e.value #>> '{}'
      from jsonb_each(case when jsonb_typeof(p_acc) = 'object' and not (p_acc ? 'canonical')
                           then p_acc else '{}' end) p,
           jsonb_each(case when jsonb_typeof(p.value -> 'known_errors') = 'object'
                           then p.value -> 'known_errors' else '{}' end) e
     where p.key ~ '^[1-9][0-9]*$')
  select slug, teil, public.pruef_gruppen(jsonb_agg(k order by length(k), k))
    from ke group by slug, teil
$_$;


--
-- Name: pruef_fertigkeit_optionen(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_fertigkeit_optionen(p_skill_key text) RETURNS jsonb
    LANGUAGE sql STABLE
    SET search_path TO 'public', 'pg_temp'
    AS $$
  with thema as (select thema_key from public.skill_thema where skill_key = p_skill_key),
  im_thema as (
    select s.skill_key, s.label, 'thema' gruppe, 1 n, s.fundament_tiefe t
      from public.skills s join public.skill_thema st on st.skill_key = s.skill_key
     where st.thema_key = (select thema_key from thema)),
  vor as (
    select s.skill_key, s.label, 'voraussetzung' gruppe, 2 n, s.fundament_tiefe t
      from public.skill_kante k join public.skills s on s.skill_key = k.voraussetzt_skill_key
     where k.skill_key = p_skill_key
       and exists (select 1 from public.skill_thema st where st.skill_key = s.skill_key)
       and s.skill_key not in (select skill_key from im_thema))
  select coalesce(jsonb_agg(jsonb_build_object('key', skill_key, 'label', label, 'gruppe', gruppe)
                            order by n, t, skill_key), '[]')
    from (select * from im_thema union all select * from vor) o
$$;


--
-- Name: pruef_flach_regel(text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_flach_regel(p_input_type text, p_acceptance jsonb) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $$
  select coalesce(p_input_type not in ('MULTI_PART', 'MC', 'TERM')
                  and jsonb_typeof(p_acceptance) = 'object' and p_acceptance ? 'canonical', false)
$$;


--
-- Name: pruef_freigabe_erlaubt(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_freigabe_erlaubt(p_task_id uuid) RETURNS boolean
    LANGUAGE sql STABLE
    SET search_path TO 'public', 'pg_temp'
    AS $$
  select coalesce((select p.entscheidung = 'passt' and p.aenderungen = '[]'::jsonb
                     from public.task_pruefungen p where p.task_id = t.id
                    order by p.geprueft_am desc limit 1), false)
     and not exists (select 1 from public.task_reviews r
                      left join public.profiles pr on pr.id = r.geprueft_von
                     where r.task_id = t.id and (r.geprueft_von is null or pr.role = 'admin'))
     and (a.task_id is null
          or public.pruef_aenderungen(public.pruef_sicht(t, a.ausgang),
                                      public.pruef_sicht(t, public.pruef_fassung(t.id))) = '[]'::jsonb)
    from public.tasks t left join public.task_pruefung_ausgang a on a.task_id = t.id
   where t.id = p_task_id
$$;


--
-- Name: pruef_freigabe_zuruecknehmen(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_freigabe_zuruecknehmen(p_task_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare t public.tasks;
begin
  perform public.pruef_nur_admin('pruef_freigabe_zuruecknehmen');
  select * into t from public.tasks where id = p_task_id for update;
  if not found then
    raise exception 'pruef_freigabe_zuruecknehmen: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if t.status <> 'ready' then perform public.pruef_fehler('nicht_freigegeben'); end if;
  perform public.task_status_set(p_task_id, 'draft');
  perform public.pruef_protokoll(p_task_id, 'freigabe_zurueck', '[]', null, false);
  return jsonb_build_object('status', 'draft');
end $$;


--
-- Name: pruef_gleich(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_gleich(p_a text, p_b text) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $$
  select public.lsa_normalize_answer(p_a) = public.lsa_normalize_answer(p_b)
      or (public.pruef_ist_zahl(p_a) and public.pruef_ist_zahl(p_b)
          and public.lsa_values_equal(p_a, p_b)
          and (coalesce(public.pruef_einheit_von(p_a), '') = ''
               or coalesce(public.pruef_einheit_von(p_b), '') = ''
               or lower(public.pruef_einheit_von(p_a)) = lower(public.pruef_einheit_von(p_b))))
$$;


--
-- Name: pruef_gruppen(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_gruppen(p_liste jsonb) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    AS $$
declare g jsonb := '[]'; x text; i int; hit boolean;
begin
  if jsonb_typeof(p_liste) <> 'array' then return '[]'; end if;
  for x in select e from jsonb_array_elements_text(p_liste) e loop
    hit := false;
    for i in 0 .. jsonb_array_length(g) - 1 loop
      if public.pruef_gleich(g -> i ->> 0, x) then
        g := jsonb_set(g, array[i::text], (g -> i) || to_jsonb(x)); hit := true; exit;
      end if;
    end loop;
    if not hit then g := g || jsonb_build_array(jsonb_build_array(x)); end if;
  end loop;
  return g;
end $$;


--
-- Name: pruef_im_pilot(public.tasks); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_im_pilot(p_task public.tasks) RETURNS boolean
    LANGUAGE sql STABLE
    SET search_path TO 'public', 'pg_temp'
    AS $$
  select p_task.pruef_pilot
      or not coalesce((select e.nur_pilot from public.pruef_einstellungen e limit 1), false)
$$;


--
-- Name: pruef_ist_zahl(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_ist_zahl(p_wert text) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $$
  select coalesce(public.lsa_parse_fraction(p_wert) is not null
                  and public.lsa_is_unit((public.lsa_split_value_unit(p_wert))[2]), false)
$$;


--
-- Name: pruef_known_errors(jsonb, integer, jsonb, jsonb, jsonb, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_known_errors(p_fehler jsonb, p_teil integer, p_ids jsonb, p_acc jsonb, p_acc_alt jsonb, p_einheit text) RETURNS jsonb
    LANGUAGE plpgsql STABLE
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare aus jsonb := '{}'; f jsonb; v jsonb; w text; schl jsonb; alt jsonb;
begin
  for f in select x from jsonb_array_elements(coalesce(p_fehler, '[]')) x loop
    if not exists (select 1 from public.fehlbild_labels where slug = f ->> 'slug') then
      perform public.pruef_fehler('fehlbild_unbekannt');
    end if;
    for v in select x from jsonb_array_elements(coalesce(f -> 'werte', '[]')) x
              where (x ->> 'teil')::int is not distinct from p_teil loop
      w := btrim(v ->> 'wert');
      if coalesce(w, '') = '' then perform public.pruef_fehler('fehler_wert_fehlt'); end if;
      if p_ids is not null then
        if not p_ids @> jsonb_build_array(w) then perform public.pruef_fehler('mc_unbekannt'); end if;
        schl := jsonb_build_array(w);
      else
        alt := coalesce((select jsonb_agg(g) from (
                 select jsonb_array_elements(gruppen) g from public.pruef_fehler_gruppen(p_acc)
                  where slug = f ->> 'slug' and teil is not distinct from p_teil
                 union all
                 select jsonb_array_elements(gruppen) from public.pruef_fehler_gruppen(p_acc_alt)
                  where slug = f ->> 'slug' and teil is not distinct from p_teil) q), '[]');
        schl := public.pruef_werte_schreiben(jsonb_build_array(w), alt, p_einheit, true);
      end if;
      -- Schon vergebene Schluessel behalten ihr Fehlbild.
      aus := coalesce((select jsonb_object_agg(k, f ->> 'slug') from jsonb_array_elements_text(schl) k), '{}') || aus;
    end loop;
  end loop;
  return aus;
end $$;


--
-- Name: pruef_kurztitel(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_kurztitel(p_title text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  select regexp_replace(coalesce(p_title, ''), '^AFB (I|II|III) · ', '')
$$;


--
-- Name: pruef_lena_bewertet(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_lena_bewertet(p_task_id uuid) RETURNS boolean
    LANGUAGE sql STABLE
    SET search_path TO 'public', 'pg_temp'
    AS $$
  select coalesce((
    select p.entscheidung <> 'zurueckgenommen'
       and p.geprueft_am > coalesce((select max(x.am) from public.task_admin_protokoll x
                                      where x.task_id = p_task_id
                                        and x.aktion in ('an_lena', 'rueckfrage_an_lena')), '-infinity')
      from public.task_pruefungen p where p.task_id = p_task_id
     order by p.geprueft_am desc limit 1), false)
$$;


--
-- Name: pruef_lena_sperren(public.tasks); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_lena_sperren(t public.tasks) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  if public.pruef_ausschluss(t.id) = 'hand' or not public.pruef_im_pilot(t) then
    perform public.pruef_fehler('ausgeschlossen');
  end if;
  -- Vom Team beanstandet, wird ueberarbeitet (Rasit, PR 208).
  if public.pruef_team_beanstandet(t.id) then perform public.pruef_fehler('team_beanstandet'); end if;
end $$;


--
-- Name: pruef_lena_status(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_lena_status(p_status text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  select case p_status when 'draft' then 'offen' when 'review' then 'passt'
    when 'rueckfrage' then 'unsicher' when 'beanstandet' then 'passt_nicht'
    when 'ready' then 'freigegeben' end
$$;


--
-- Name: pruef_liste_setzen(jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_liste_setzen(p_scope jsonb, p_liste jsonb) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
  with l as (
    select coalesce(jsonb_agg(to_jsonb(btrim(x)) order by i), '[]') l
      from jsonb_array_elements_text(case when jsonb_typeof(p_liste) = 'array' then p_liste else '[]' end)
           with ordinality e(x, i)
     where btrim(x) <> '')
  select case when jsonb_array_length(l) = 0 then p_scope
    else coalesce(p_scope, '{}') || jsonb_build_object('canonical', l ->> 0)
         || case when jsonb_array_length(l) > 1 or coalesce(p_scope ? 'equivalents', false)
                 then jsonb_build_object('equivalents', l - 0) else '{}' end end
  from l
$$;


--
-- Name: pruef_mit_einheit(jsonb, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_mit_einheit(p_liste jsonb, p_einheit text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
  select coalesce(jsonb_agg(to_jsonb(x) order by i), '[]') from (
    select x, min(i) i from (
      select case when public.pruef_ist_zahl(v) and public.pruef_einheit_von(v) is null
                  then public.pruef_zahl_von(v) || ' ' || p_einheit else v end x, i
        from jsonb_array_elements_text(coalesce(p_liste, '[]')) with ordinality e(v, i)) a
    group by x) b
$$;


--
-- Name: pruef_nur_admin(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_nur_admin(p_fn text) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception '%: nur admin', p_fn using errcode = '42501';
  end if;
end $$;


--
-- Name: pruef_protokoll(uuid, text, jsonb, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_protokoll(p_task_id uuid, p_aktion text, p_aenderungen jsonb, p_grund text, p_sammel boolean) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  insert into public.task_admin_protokoll (task_id, aktion, aenderungen, grund, sammel, von, am)
  values (p_task_id, p_aktion, coalesce(p_aenderungen, '[]'), nullif(btrim(p_grund), ''),
          coalesce(p_sammel, false), auth.uid(), clock_timestamp());
end $$;


--
-- Name: pruef_regel_erlaubt(text, jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_regel_erlaubt(p_input_type text, p_ca jsonb, p_acceptance jsonb) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $$
  select public.pruef_flach_regel(p_input_type, p_acceptance)
     and (p_input_type = 'NUMERIC'
          or (p_input_type = 'SHORT_TEXT' and jsonb_typeof(p_ca) = 'array'
              and jsonb_array_length(p_ca) > 0
              and not exists (select 1 from jsonb_array_elements_text(p_ca) x
                               where not public.pruef_ist_zahl(x))))
$$;


--
-- Name: pruef_rueckfrage_klaeren(uuid, text, text, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_rueckfrage_klaeren(p_task_id uuid, p_aktion text, p_antwort text, p_gruende text[] DEFAULT NULL::text[]) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  t public.tasks; v_id uuid; g text;
  gruende text[] := array(select distinct btrim(x) from unnest(coalesce(p_gruende, '{}')) x where btrim(x) <> '');
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'pruef_rueckfrage_klaeren: nur admin' using errcode = '42501';
  end if;
  if p_aktion is null or p_aktion not in ('freigeben', 'zurueckweisen', 'an_lena') then
    raise exception 'pruef_rueckfrage_klaeren: unbekannte Aktion %', p_aktion using errcode = '22023';
  end if;
  select * into t from public.tasks where id = p_task_id for update;
  if not found then
    raise exception 'pruef_rueckfrage_klaeren: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if t.status <> 'rueckfrage' then perform public.pruef_fehler('keine_rueckfrage'); end if;

  if p_aktion = 'freigeben' then
    perform public.task_status_set(p_task_id, 'ready');
  elsif p_aktion = 'zurueckweisen' then
    if cardinality(gruende) = 0 then perform public.pruef_fehler('grund_fehlt'); end if;
    if not gruende <@ public.pruef_admin_gruende() then perform public.pruef_fehler('grund_unbekannt'); end if;
    update public.tasks set status = 'beanstandet', reviewed_by = null, reviewed_at = null where id = p_task_id;
    foreach g in array gruende loop
      insert into public.task_reviews (task_id, kategorie, notiz, geprueft_von, geprueft_am)
      values (p_task_id, g, nullif(btrim(p_antwort), ''), auth.uid(), clock_timestamp());
    end loop;
  else
    update public.tasks set status = 'draft', reviewed_by = null, reviewed_at = null where id = p_task_id;
    delete from public.task_pruefung_ausgang where task_id = p_task_id;
  end if;

  select p.id into v_id from public.task_pruefungen p where p.task_id = p_task_id
   order by p.geprueft_am desc limit 1;
  if v_id is not null then
    update public.task_pruefungen
       set antwort = nullif(btrim(p_antwort), ''), beantwortet_von = auth.uid(), beantwortet_am = now()
     where id = v_id;
  end if;
  perform public.pruef_protokoll(p_task_id, 'rueckfrage_' || p_aktion, '[]', p_antwort, false);

  return jsonb_build_object('status', (select x.status from public.tasks x where x.id = p_task_id));
end $$;


--
-- Name: pruef_rueckgaengig(uuid, bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_rueckgaengig(p_task_id uuid, p_version bigint) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare t public.tasks; aus jsonb;
begin
  t := public.pruef_sperren(p_task_id, p_version);
  perform public.pruef_lena_sperren(t);
  if t.status not in ('review', 'rueckfrage', 'beanstandet') then
    perform public.pruef_fehler('nicht_bewertet');
  end if;
  select a.ausgang into aus from public.task_pruefung_ausgang a where a.task_id = p_task_id;
  update public.tasks set status = 'draft', reviewed_by = null, reviewed_at = null where id = p_task_id;
  insert into public.task_pruefungen (task_id, entscheidung, aenderungen, geprueft_von, geprueft_am)
  values (p_task_id, 'zurueckgenommen',
          case when aus is null then '[]'::jsonb
               else public.pruef_aenderungen(public.pruef_sicht(t, aus), public.pruef_sicht(t, public.pruef_fassung(p_task_id))) end,
          auth.uid(), clock_timestamp());
  select * into t from public.tasks where id = p_task_id;
  return jsonb_build_object('pruef_version', t.pruef_version, 'lena_status', public.pruef_lena_status(t.status));
end $$;


--
-- Name: pruef_sammel(text, uuid[], jsonb, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_sammel(p_aktion text, p_task_ids uuid[], p_werte jsonb DEFAULT '{}'::jsonb, p_nur_vorschau boolean DEFAULT true) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  w jsonb := coalesce(p_werte, '{}');
  betrifft uuid[] := '{}';
  ausgelassen jsonb := '[]';
  v_id uuid; t public.tasks; g jsonb; st text; h text; m text;
begin
  perform public.pruef_nur_admin('pruef_sammel');
  if p_aktion is null or p_aktion not in ('freigeben', 'an_lena', 'pilot_an', 'pilot_aus', 'ausschliessen',
                                          'aufnehmen', 'fertigkeit', 'afb') then
    raise exception 'pruef_sammel: unbekannte Aktion %', p_aktion using errcode = '22023';
  end if;
  -- Eingaben, ohne die die Aktion fuer keine Aufgabe Sinn ergibt: Fehler fuer den ganzen Aufruf.
  if p_aktion = 'fertigkeit' and coalesce(btrim(w ->> 'skill_key'), '') = '' then
    perform public.pruef_fehler('wert_fehlt');
  end if;
  if p_aktion = 'afb' and coalesce(w ->> 'afb', '') not in ('I', 'II', 'III') then
    perform public.pruef_fehler('afb_ungueltig');
  end if;
  -- Der Grund wird erst zum Schreiben gebraucht; die Vorschau zeigt schon vorher, was die Aktion trifft.
  if p_aktion = 'ausschliessen' and not coalesce(p_nur_vorschau, true)
     and coalesce(btrim(w ->> 'grund'), '') = '' then
    perform public.pruef_fehler('grund_fehlt');
  end if;

  for v_id in select u.x from unnest(coalesce(p_task_ids, '{}')) with ordinality u(x, i)
               where u.x is not null group by u.x order by min(u.i) loop
    begin
      select * into t from public.tasks where id = v_id for update;
      if not found then
        g := jsonb_build_object('grund', 'nicht_gefunden');
      else
        g := public.pruef_sammel_grund(p_aktion, t, w);
        if g is null and not coalesce(p_nur_vorschau, true) then
          perform public.pruef_sammel_schreiben(p_aktion, t, w);
        end if;
      end if;
    exception when others then
      get stacked diagnostics st = returned_sqlstate, h = pg_exception_hint, m = message_text;
      g := jsonb_build_object(
        'grund', case when st = 'ED422' and coalesce(h, '') <> '' then h
                      when st = 'P0001' and p_aktion = 'freigeben' then 'befund' else 'fehler' end,
        'text', m);
    end;
    if g is null then
      betrifft := betrifft || v_id;
    else
      ausgelassen := ausgelassen || jsonb_build_array(jsonb_build_object('task_id', v_id) || g);
    end if;
  end loop;

  return jsonb_build_object('betrifft', to_jsonb(betrifft), 'ausgelassen', ausgelassen);
end $$;


--
-- Name: pruef_sammel_grund(text, public.tasks, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_sammel_grund(p_aktion text, t public.tasks, p_werte jsonb) RETURNS jsonb
    LANGUAGE plpgsql STABLE
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  aus text := public.pruef_ausschluss(t.id);
  lp public.task_pruefungen;
  gate text;
  basis text;
begin
  if p_aktion = 'freigeben' then
    if t.status = 'ready' then return jsonb_build_object('grund', 'schon_freigegeben'); end if;
    if t.source = 'VERA8_IQB' then return jsonb_build_object('grund', 'vera8'); end if;
    if t.status = 'rueckfrage' then return jsonb_build_object('grund', 'rueckfrage_offen'); end if;
    if t.status = 'beanstandet' then
      return jsonb_build_object('grund', case when public.pruef_team_beanstandet(t.id)
                                              then 'team_beanstandet' else 'lena_passt_nicht' end);
    end if;
    select * into lp from public.task_pruefungen p where p.task_id = t.id order by p.geprueft_am desc limit 1;
    if t.status <> 'review' or lp.id is null or lp.entscheidung <> 'passt' then
      return jsonb_build_object('grund', 'noch_nicht_bewertet');
    end if;
    -- Eine fruehere Admin-Beanstandung ueberstimmt Lenas spaeteres "Passt" nicht still (Lena-Board OP-9).
    if exists (select 1 from public.task_reviews r left join public.profiles pr on pr.id = r.geprueft_von
                where r.task_id = t.id and (r.geprueft_von is null or pr.role = 'admin')) then
      return jsonb_build_object('grund', 'team_beanstandet');
    end if;
    if not public.pruef_freigabe_erlaubt(t.id) then return jsonb_build_object('grund', 'geaendert'); end if;
    gate := public.freigabe_gate_fehler(t.id);
    if gate is not null then return jsonb_build_object('grund', 'befund', 'text', gate); end if;
  elsif p_aktion = 'an_lena' then
    if t.status = 'ready' then return jsonb_build_object('grund', 'freigegeben'); end if;
    if aus is not null then return jsonb_build_object('grund', 'nicht_bei_lena', 'text', aus); end if;
    if t.status = 'draft' and not public.pruef_lena_bewertet(t.id) then
      return jsonb_build_object('grund', 'schon_offen');
    end if;
  elsif p_aktion = 'pilot_an' then
    if aus is not null then return jsonb_build_object('grund', 'nicht_bei_lena', 'text', aus); end if;
    if t.pruef_pilot then return jsonb_build_object('grund', 'schon_im_pilot'); end if;
  elsif p_aktion = 'pilot_aus' then
    if not t.pruef_pilot then return jsonb_build_object('grund', 'nicht_im_pilot'); end if;
  elsif p_aktion = 'ausschliessen' then
    -- Ein berechneter Grund (ohne Loesung, Gate …) haelt die Aufgabe nur, bis er behoben ist; von Hand
    -- herausnehmen geht deshalb trotzdem (Consensus-Check G-b). Nur feste Ausschluesse sperren.
    if aus in ('vera8', 'inaktiv', 'typ', 'hand') then
      return jsonb_build_object('grund', 'schon_ausgeschlossen', 'text', aus);
    end if;
    if t.status = 'ready' then return jsonb_build_object('grund', 'freigegeben'); end if;
  elsif p_aktion = 'aufnehmen' then
    if exists (select 1 from public.task_pruef_ausschluss h where h.task_id = t.id) then return null; end if;
    if aus is not null then return jsonb_build_object('grund', 'nicht_von_hand', 'text', aus); end if;
    return jsonb_build_object('grund', 'schon_drin');
  elsif p_aktion in ('fertigkeit', 'afb') then
    if t.status = 'ready' then return jsonb_build_object('grund', 'freigegeben'); end if;
    -- Wie pruef_sperren fuer admin: VERA8, inaktiv und fremde Typen nur ueber den Editor.
    if aus in ('vera8', 'inaktiv', 'typ') then return jsonb_build_object('grund', 'ausgeschlossen', 'text', aus); end if;
    if p_aktion = 'afb' then
      if t.afb is not distinct from p_werte ->> 'afb' then return jsonb_build_object('grund', 'schon_gesetzt'); end if;
    else
      if t.skill_key is not distinct from p_werte ->> 'skill_key' then
        return jsonb_build_object('grund', 'schon_gesetzt');
      end if;
      -- Dieselbe Auswahl wie in der Pruefkarte: Thema der Ausgangsfassung plus direkte Voraussetzungen.
      basis := coalesce((select a.ausgang ->> 'skill_key' from public.task_pruefung_ausgang a where a.task_id = t.id),
                        t.skill_key);
      if not exists (select 1 from jsonb_array_elements(public.pruef_fertigkeit_optionen(basis)) o
                      where o ->> 'key' = p_werte ->> 'skill_key') then
        return jsonb_build_object('grund', 'nicht_erlaubt');
      end if;
    end if;
  end if;
  return null;
end $$;


--
-- Name: pruef_sammel_schreiben(text, public.tasks, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_sammel_schreiben(p_aktion text, t public.tasks, p_werte jsonb) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  grund text := nullif(btrim(p_werte ->> 'grund'), '');
  aus jsonb; jetzt jsonb; neu jsonb; danach public.tasks;
begin
  if p_aktion = 'freigeben' then
    perform public.task_status_set(t.id, 'ready');
    perform public.pruef_protokoll(t.id, 'freigeben', '[]', grund, true);
  elsif p_aktion = 'an_lena' then
    perform public.pruef_an_lena_schreiben(t.id, p_werte ->> 'nachricht', grund, true);
  elsif p_aktion in ('pilot_an', 'pilot_aus') then
    update public.tasks set pruef_pilot = (p_aktion = 'pilot_an') where id = t.id;
    perform public.pruef_protokoll(t.id, p_aktion, '[]', grund, true);
  elsif p_aktion = 'ausschliessen' then
    insert into public.task_pruef_ausschluss (task_id, grund, von, am)
    values (t.id, grund, auth.uid(), clock_timestamp());
    perform public.pruef_protokoll(t.id, 'ausschliessen', '[]', grund, true);
  elsif p_aktion = 'aufnehmen' then
    delete from public.task_pruef_ausschluss where task_id = t.id;
    perform public.pruef_protokoll(t.id, 'aufnehmen', '[]', grund, true);
  elsif p_aktion in ('fertigkeit', 'afb') then
    aus := public.pruef_ausgang_sichern(t.id);
    jetzt := public.pruef_fassung(t.id);
    neu := public.pruef_entwurf_anwenden(t, jetzt, aus,
             case when p_aktion = 'fertigkeit' then jsonb_build_object('skill_key', p_werte ->> 'skill_key')
                  else jsonb_build_object('afb', p_werte ->> 'afb') end,
             (select s.option_scores from public.task_solutions s where s.task_id = t.id));
    update public.tasks
       set skill_key = neu ->> 'skill_key', afb = neu ->> 'afb', sondierrang = (neu ->> 'sondierrang')::int
     where id = t.id;
    select * into danach from public.tasks where id = t.id;
    perform public.pruef_protokoll(t.id, p_aktion,
      public.pruef_aenderungen(public.pruef_sicht(t, jetzt), public.pruef_sicht(danach, public.pruef_fassung(t.id))),
      grund, true);
  end if;
end $$;


--
-- Name: pruef_schreibweisen(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_schreibweisen(p_wert text, p_einheit text) RETURNS text[]
    LANGUAGE plpgsql IMMUTABLE
    AS $$
declare
  w text := btrim(p_wert); n text; body text; e text; f text; basis text[]; formen text[]; aus text[];
begin
  if w is null or w = '' then return '{}'; end if;
  if not public.pruef_ist_zahl(w) then return array[w]; end if;
  n := (public.lsa_split_value_unit(w))[1];
  body := ltrim(n, '-');
  basis := case when position('.' in body) > 0 then array[replace(body, '.', ','), body]
                else array[body] end;
  formen := case when left(n, 1) = '-'
    then array(select s || b from unnest(basis) b, unnest(array['-', '−']) s)
    else basis || array(select '+' || b from unnest(basis) b) end;
  e := coalesce(public.pruef_einheit_von(w), nullif(btrim(p_einheit), ''));
  aus := array[w];
  foreach f in array formen loop
    aus := aus || f;
    if e is not null then aus := aus || (f || ' ' || e) || (f || e); end if;
  end loop;
  return array(select x from unnest(aus) with ordinality u(x, i)
                group by x order by min(i));
end $$;


--
-- Name: pruef_sicht(public.tasks, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_sicht(p_task public.tasks, p_fassung jsonb) RETURNS jsonb
    LANGUAGE plpgsql STABLE
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  it    text := p_task.input_type;
  ca    jsonb := coalesce(p_fassung -> 'correct_answers', '[]');
  acc   jsonb := nullif(p_fassung -> 'acceptance', 'null'::jsonb);
  te    jsonb := coalesce(nullif(p_fassung -> 'typical_errors', 'null'::jsonb), '[]');
  flach boolean := public.pruef_flach_regel(it, acc);
  werte jsonb;
  regel jsonb;
begin
  if it = 'MULTI_PART' then
    werte := coalesce((select jsonb_agg(jsonb_build_object('teil', (p ->> 'nr')::int, 'werte',
      coalesce((select jsonb_agg(jsonb_build_object('wert', x, 'schreibweisen', jsonb_build_array(x)) order by i)
                  from jsonb_array_elements_text(case when jsonb_typeof(ca -> (p ->> 'nr')) = 'array'
                                                      then ca -> (p ->> 'nr') else '[]' end)
                       with ordinality y(x, i)), '[]')) order by o)
      from jsonb_array_elements(p_task.parts) with ordinality q(p, o)), '[]');
  else
    werte := jsonb_build_array(jsonb_build_object('teil', null, 'werte', coalesce(case when flach then
      (select jsonb_agg(jsonb_build_object('wert', g ->> 0, 'schreibweisen', g) order by i)
         from jsonb_array_elements(public.pruef_gruppen(ca)) with ordinality z(g, i))
    else
      (select jsonb_agg(jsonb_build_object('wert', x, 'schreibweisen', jsonb_build_array(x)) order by i)
         from jsonb_array_elements_text(case when jsonb_typeof(ca) = 'array' then ca else '[]' end)
              with ordinality y(x, i))
    end, '[]')));
  end if;

  if public.pruef_regel_erlaubt(it, ca, acc) then
    regel := jsonb_build_object(
      'art', case when acc #>> '{tolerance,mode}' = 'absolute' then 'bereich' else 'wert' end,
      'mitte', case when acc #>> '{tolerance,mode}' = 'absolute'
                    then coalesce(public.pruef_zahl_von(acc ->> 'canonical'), acc ->> 'canonical') end,
      'toleranz', case when acc #>> '{tolerance,mode}' = 'absolute' then acc #> '{tolerance,value}' end,
      'einheit_pflicht', coalesce((acc ->> 'unit_graded')::boolean, false),
      'einheit', public.pruef_einheit(acc, ca),
      'einheit_am_feld', coalesce(btrim(p_task.unit), '') <> '');
  end if;

  return jsonb_build_object(
    'werte', werte,
    'mc', case when it = 'MC' then ca ->> 0 end,
    'regel', regel,
    'fehler', case when it = 'TERM' then '[]'::jsonb else coalesce((
      select jsonb_agg(jsonb_build_object(
               'slug', f.slug,
               'werte', f.werte,
               'text', (select e ->> 'error' from jsonb_array_elements(te) e
                         where e ->> 'fehlbild' = f.slug limit 1)) order by f.slug)
        from (select fg.slug, jsonb_agg(jsonb_build_object('teil', fg.teil, 'wert', g ->> 0)
                                        order by fg.teil nulls first, g ->> 0) werte
                from public.pruef_fehler_gruppen(acc) fg, jsonb_array_elements(fg.gruppen) g
               group by fg.slug) f), '[]') end,
    'weitere_hinweise', coalesce((select jsonb_agg(e) from jsonb_array_elements(te) e
                                   where coalesce(e ->> 'fehlbild', '') = ''), '[]'),
    'skill_key', p_fassung ->> 'skill_key',
    'afb', p_fassung ->> 'afb',
    'flach_regel', flach,
    'ohne_erkennung', it = 'TERM' or (it not in ('MC', 'MULTI_PART') and not flach));
end $$;


--
-- Name: pruef_speichern(uuid, bigint, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_speichern(p_task_id uuid, p_version bigint, p_entwurf jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare t public.tasks; aus jsonb; jetzt jsonb; neu jsonb; os jsonb; sol text;
begin
  t := public.pruef_sperren(p_task_id, p_version);
  aus := public.pruef_ausgang_sichern(p_task_id);
  jetzt := public.pruef_fassung(p_task_id);
  select option_scores, solution into os, sol from public.task_solutions where task_id = p_task_id;
  neu := public.pruef_entwurf_anwenden(t, jetzt, aus, p_entwurf, os);

  if (neu -> 'correct_answers', neu -> 'acceptance', neu -> 'typical_errors')
     is distinct from (jetzt -> 'correct_answers', jetzt -> 'acceptance', jetzt -> 'typical_errors') then
    insert into public.task_solutions as x (task_id, correct_answers, acceptance, typical_errors, updated_at)
    values (p_task_id, neu -> 'correct_answers', nullif(neu -> 'acceptance', 'null'::jsonb), neu -> 'typical_errors', now())
    on conflict (task_id) do update
      set correct_answers = excluded.correct_answers, acceptance = excluded.acceptance,
          typical_errors = excluded.typical_errors, updated_at = now();
  end if;
  if (neu ->> 'skill_key', neu ->> 'afb', neu -> 'sondierrang')
     is distinct from (jetzt ->> 'skill_key', jetzt ->> 'afb', jetzt -> 'sondierrang') then
    update public.tasks
       set skill_key = neu ->> 'skill_key', afb = neu ->> 'afb', sondierrang = (neu ->> 'sondierrang')::int
     where id = p_task_id;
  end if;

  select * into t from public.tasks where id = p_task_id;
  return jsonb_build_object(
    'pruef_version', t.pruef_version,
    'auffaelligkeiten', public.pruef_auffaelligkeiten(t, neu -> 'correct_answers', neu -> 'acceptance', sol),
    'aenderungen', public.pruef_aenderungen(public.pruef_sicht(t, aus), public.pruef_sicht(t, public.pruef_fassung(p_task_id))));
end $$;


--
-- Name: pruef_sperren(uuid, bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_sperren(p_task_id uuid, p_version bigint) RETURNS public.tasks
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare t public.tasks;
begin
  if not public.darf_pruefen() then
    raise exception 'pruefen: kein Pruefrecht' using errcode = '42501';
  end if;
  select * into t from public.tasks where id = p_task_id for update;
  if not found then
    raise exception 'pruefen: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if t.pruef_version is distinct from p_version then
    raise exception 'pruefen: Die Aufgabe wurde inzwischen geaendert. Bitte neu laden.'
      using errcode = 'ED409', hint = 'version';
  end if;
  if t.status = 'ready' then perform public.pruef_fehler('freigegeben'); end if;
  -- Fuer alle: VERA8, inaktiv und fremde Antworttypen bearbeitet nur der Editor.
  if public.pruef_ausschluss(p_task_id) in ('vera8', 'inaktiv', 'typ') then
    perform public.pruef_fehler('ausgeschlossen');
  end if;
  if public.get_my_role() is distinct from 'admin' then perform public.pruef_lena_sperren(t); end if;
  return t;
end $$;


--
-- Name: pruef_team_beanstandet(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_team_beanstandet(p_task_id uuid) RETURNS boolean
    LANGUAGE sql STABLE
    SET search_path TO 'public', 'pg_temp'
    AS $$
  select coalesce((
    select t.status = 'beanstandet'
       and coalesce((select r.geprueft_von is null or pr.role = 'admin'
                       from public.task_reviews r
                       left join public.profiles pr on pr.id = r.geprueft_von
                      where r.task_id = t.id
                      order by r.geprueft_am desc limit 1), true)
      from public.tasks t where t.id = p_task_id), false)
$$;


--
-- Name: pruef_werte_schreiben(jsonb, jsonb, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_werte_schreiben(p_werte jsonb, p_alt jsonb, p_einheit text, p_erweitern boolean) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    AS $$
declare aus text[] := '{}'; w text; g jsonb;
begin
  for w in select btrim(e) from jsonb_array_elements_text(coalesce(p_werte, '[]')) e loop
    continue when w = '';
    select x into g from jsonb_array_elements(coalesce(p_alt, '[]')) x where x ->> 0 = w limit 1;
    if g is not null then
      aus := aus || array(select jsonb_array_elements_text(g));
    elsif p_erweitern then
      aus := aus || public.pruef_schreibweisen(w, p_einheit);
    else
      aus := aus || w;
    end if;
  end loop;
  return coalesce((select jsonb_agg(x order by i) from (
    select x, min(i) i from unnest(aus) with ordinality u(x, i) group by x) d), '[]');
end $$;


--
-- Name: pruef_wertung_testen(uuid, integer, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_wertung_testen(p_task_id uuid, p_teil integer, p_antwort text, p_entwurf jsonb DEFAULT NULL::jsonb) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  t public.tasks; aus jsonb; neu jsonb; ca jsonb; acc jsonb; kind text; resp jsonb; ke jsonb;
  richtig boolean; stufe text; v_slug text; p jsonb; h text;
begin
  if not public.darf_pruefen() then
    raise exception 'pruef_wertung_testen: kein Pruefrecht' using errcode = '42501';
  end if;
  select * into t from public.tasks where id = p_task_id;
  if not found then
    raise exception 'pruef_wertung_testen: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if coalesce(btrim(p_antwort), '') = '' then return jsonb_build_object('stufe', null); end if;
  select a.ausgang into aus from public.task_pruefung_ausgang a where a.task_id = p_task_id;
  begin
    neu := public.pruef_entwurf_anwenden(t, public.pruef_fassung(p_task_id), coalesce(aus, public.pruef_fassung(p_task_id)),
             p_entwurf, (select option_scores from public.task_solutions where task_id = p_task_id));
  exception when sqlstate 'ED422' then
    get stacked diagnostics h = pg_exception_hint;
    return jsonb_build_object('stufe', null, 'fehler', h);
  end;
  ca := neu -> 'correct_answers';
  acc := nullif(neu -> 'acceptance', 'null'::jsonb);

  if t.input_type = 'MULTI_PART' then
    select x into p from jsonb_array_elements(t.parts) x where (x ->> 'nr')::int = p_teil;
    if p is null then perform public.pruef_fehler('teil_unbekannt'); end if;
    kind := p ->> 'kind';
    resp := public.lsa_part_answer(kind, to_jsonb(btrim(p_antwort)));
    richtig := coalesce(public.lsa_is_correct(case when kind = 'mc' then 'MC' else 'SHORT_TEXT' end,
                 case when jsonb_typeof(ca -> (p ->> 'nr')) = 'array' then ca -> (p ->> 'nr') else '[]' end, resp), false);
    stufe := case when richtig then 'voll' else 'nicht' end;
    ke := coalesce(acc -> (p ->> 'nr') -> 'known_errors', acc -> 'known_errors');
  else
    kind := lower(t.input_type);
    resp := case when t.input_type = 'MC' then jsonb_build_object('selected', jsonb_build_array(btrim(p_antwort)))
                 else jsonb_build_object('text', p_antwort) end;
    richtig := coalesce(public.lsa_is_correct(t.input_type, ca, resp), false);
    stufe := case when t.input_type in ('MC', 'TERM') then case when richtig then 'voll' else 'nicht' end
                  else public.lsa_grade(t.input_type, acc, ca, resp) end;
    ke := acc -> 'known_errors';
  end if;

  if not richtig then
    v_slug := public.lsa_fehlbild_match(kind, ke, public.lsa_part_answer(kind, resp));
  end if;
  return jsonb_build_object('stufe', stufe, 'fehlbild_slug', v_slug,
    'fehlbild_klartext', (select fl.klartext from public.fehlbild_labels fl where fl.slug = v_slug));
end $$;


--
-- Name: pruef_zahl_von(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pruef_zahl_von(p_wert text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  select case when public.pruef_ist_zahl(p_wert) then
    (regexp_match(btrim(p_wert), '^([-+−–]?\s?[0-9]+(?:\s+[0-9]+/[0-9]+|/[0-9]+|[.,][0-9]+)?)'))[1] end
$$;


--
-- Name: schueler_notizen_guard(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.schueler_notizen_guard() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  if new.id <> old.id
     or new.student_id  <> old.student_id
     or new.kategorie   <> old.kategorie
     or new.autor_rolle <> old.autor_rolle
     or new.created_at  <> old.created_at then
    raise exception 'schueler_notizen: Notizen werden nicht bearbeitet' using errcode = '42501';
  end if;

  -- Verweise auf Profile duerfen nur durch das Loeschen des Profils leer werden.
  if new.autor_id is distinct from old.autor_id and new.autor_id is not null then
    raise exception 'schueler_notizen: Autor ist unveraenderlich' using errcode = '42501';
  end if;

  -- Text: unveraendert, oder einmalig endgueltig entfernt.
  if new.text is distinct from old.text
     and not (old.text is not null and new.text is null
              and old.entfernt_am is null and new.entfernt_am is not null) then
    raise exception 'schueler_notizen: Notizen werden nicht bearbeitet' using errcode = '42501';
  end if;

  -- Entfernt bleibt entfernt.
  if old.entfernt_am is not null
     and (new.entfernt_am is distinct from old.entfernt_am
          or new.entfernt_grund is distinct from old.entfernt_grund
          or (new.entfernt_von is distinct from old.entfernt_von and new.entfernt_von is not null)) then
    raise exception 'schueler_notizen: eine entfernte Notiz bleibt entfernt' using errcode = '42501';
  end if;

  return new;
end;
$$;


--
-- Name: session_ids_fuer_coach(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.session_ids_fuer_coach() RETURNS SETOF uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select cs.id
  from coaching_sessions cs
  where cs.coach_id = auth.uid();
$$;


--
-- Name: session_ids_fuer_eltern(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.session_ids_fuer_eltern() RETURNS SETOF uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select ss.session_id
  from session_students ss
  where public.is_parent_of_student(ss.student_id);
$$;


--
-- Name: session_ids_fuer_schueler(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.session_ids_fuer_schueler() RETURNS SETOF uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select ss.session_id
  from session_students ss
  where ss.student_id = public.get_my_student_id();
$$;


--
-- Name: session_platz_kandidaten(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.session_platz_kandidaten(p_session_id uuid) RETURNS SETOF uuid
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_rolle text := public.get_my_role();
  v_datum date;
begin
  if v_rolle = 'admin' then
    null;
  elsif v_rolle = 'coach' and p_session_id in (select public.session_ids_fuer_coach()) then
    null;
  else
    raise exception 'session_platz_kandidaten: keine Berechtigung fuer diese Session' using errcode = '42501';
  end if;

  select (cs.scheduled_at at time zone 'Europe/Berlin')::date into v_datum
    from public.coaching_sessions cs where cs.id = p_session_id;
  if v_datum is null then
    raise exception 'session_platz_kandidaten: Session nicht gefunden' using errcode = 'P0002';
  end if;

  return query
    select s.id
      from public.students s
     where not s.is_provisional
       and public.session_platz_zugang(s.id, v_datum);
end;
$$;


--
-- Name: session_platz_zugang(uuid, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.session_platz_zugang(p_student_id uuid, p_datum date) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  select public.hat_zugang(p_student_id, p_datum)
     and (
       exists (
         select 1
           from public.vertraege v
          where v.student_id = p_student_id
            and v.status = 'abgeschlossen'
            and v.vertragsbeginn is not null
            and v.vertrag_ende is not null
            and p_datum between v.vertragsbeginn and v.vertrag_ende
            and public.vertrag_wirksamer_status(
                  v.widerrufen_am, v.gekuendigt_zum, v.vertrag_ende, v.widerruf_bis, p_datum
                ) in ('im_widerruf', 'aktiv')
       )
       or public.vertrag_bruecke(p_student_id, p_datum)
     );
$$;


--
-- Name: session_platz_zugang_pruefen(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.session_platz_zugang_pruefen() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_datum date;
begin
  select (cs.scheduled_at at time zone 'Europe/Berlin')::date
    into v_datum
    from public.coaching_sessions cs
   where cs.id = new.session_id;

  -- Keine Session: der Fremdschluessel meldet das selbst.
  if v_datum is null then
    return new;
  end if;

  if not public.session_platz_zugang(new.student_id, v_datum) then
    raise exception 'Kein laufender Vertrag am % — Platz kann nicht vergeben werden.',
                    to_char(v_datum, 'DD.MM.YYYY')
      using errcode = 'ZG001',
            hint    = 'datum:' || to_char(v_datum, 'YYYY-MM-DD');
  end if;

  return new;
end;
$$;


--
-- Name: session_students_testlauf_pruefen(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.session_students_testlauf_pruefen() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  if exists (select 1 from public.coaching_sessions cs where cs.id = new.session_id and cs.testlauf)
     and not coalesce((select s.ist_test from public.students s where s.id = new.student_id), false) then
    raise exception 'Testlauf: nur Testkonten in einer Test-Session' using errcode = '22023';
  end if;
  return new;
end;
$$;


--
-- Name: session_testlauf_setzen(uuid, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.session_testlauf_setzen(p_session_id uuid, p_testlauf boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'session_testlauf_setzen: nur Admin' using errcode = '42501';
  end if;
  update public.coaching_sessions set testlauf = coalesce(p_testlauf, false) where id = p_session_id;
  if not found then
    raise exception 'session_testlauf_setzen: Session nicht gefunden' using errcode = 'P0002';
  end if;
end;
$$;


--
-- Name: session_verschieben_zugang_pruefen(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.session_verschieben_zugang_pruefen() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_neu date := (new.scheduled_at at time zone 'Europe/Berlin')::date;
begin
  if v_neu = (old.scheduled_at at time zone 'Europe/Berlin')::date then
    return new;
  end if;

  if exists (
    select 1 from public.session_students ss
     where ss.session_id = new.id
       and not public.session_platz_zugang(ss.student_id, v_neu)
  ) then
    raise exception 'Kein laufender Vertrag am % — Platz kann nicht vergeben werden.',
                    to_char(v_neu, 'DD.MM.YYYY')
      using errcode = 'ZG001',
            hint    = 'datum:' || to_char(v_neu, 'YYYY-MM-DD');
  end if;

  return new;
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
-- Name: skill_pruefung_lesen(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.skill_pruefung_lesen(p_skill_key text) RETURNS TABLE(id uuid, skill_key text, frage text, erwartung text, kriterium text, quelle text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
#variable_conflict use_column
begin
  if coalesce(public.get_my_role(), '') not in ('coach', 'admin') then
    raise exception 'skill_pruefung_lesen: nur Coach oder Admin' using errcode = '42501';
  end if;
  return query
    select p.id, p.skill_key, p.frage, p.erwartung, p.kriterium, p.quelle
      from public.skill_pruefung p
     where p.skill_key = p_skill_key
       and p.status = 'freigegeben'
     order by p.angelegt, p.id;
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

  -- Der Lock: sperrt die Slot-Zeile fuer die Dauer der Transaktion. Erst
  -- danach wird gezaehlt, eine zweite gleichzeitige Zuweisung wartet hier.
  select * into v_slot from slots where id = p_slot_id for update;
  if not found then
    raise exception 'slot_assign: Slot nicht gefunden' using errcode = 'P0002';
  end if;

  if v_slot.valid_until is not null then
    raise exception 'slot_assign: Slot ist beendet' using errcode = 'P0001';
  end if;

  if v_slot.valid_from > current_date then
    raise exception 'slot_assign: Slot beginnt erst am %', v_slot.valid_from
      using errcode = 'P0001';
  end if;

  -- Nur eine bestehende Zuordnung im selben Slot loesen. Zuordnungen zu
  -- anderen Slots bleiben: ein Lead darf mehrere Sessions pro Woche haben.
  update slot_assignments
     set released_at = now()
   where lead_id = p_lead_id
     and slot_id = p_slot_id
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
-- Name: students_ist_test_erben(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.students_ist_test_erben() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  if new.lead_id is not null and not new.ist_test then
    new.ist_test := coalesce((select l.ist_test from public.leads l where l.id = new.lead_id), false);
  end if;
  return new;
end;
$$;


--
-- Name: subscriptions_guard_provisional(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.subscriptions_guard_provisional() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  if exists (select 1 from public.students where id = new.student_id and is_provisional) then
    raise exception
      'student_subscriptions: provisorischer Schueler traegt kein Abo (erst der Vertragsabschluss)'
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
-- Name: task_pruefungen_nur_anhaengen(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.task_pruefungen_nur_anhaengen() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  if (new.id, new.task_id, new.entscheidung, new.gruende, new.notiz, new.aenderungen,
      new.aenderung_grund, new.dauer_sek, new.geprueft_von, new.geprueft_am)
     is distinct from
     (old.id, old.task_id, old.entscheidung, old.gruende, old.notiz, old.aenderungen,
      old.aenderung_grund, old.dauer_sek, old.geprueft_von, old.geprueft_am) then
    raise exception 'task_pruefungen: das Protokoll wird nur angehaengt, nicht geaendert'
      using errcode = '42501';
  end if;
  return new;
end $$;


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
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_typ text;
  v_alt jsonb;
begin
  if not (public.get_my_role() is not distinct from 'admin' or public.ist_systemaufruf()) then
    raise exception 'task_solution_upsert: nur admin' using errcode = '42501';
  end if;
  select input_type into v_typ from tasks where id = p_task_id for update;
  if not found then
    raise exception 'task_solution_upsert: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if p_beleg is not null and jsonb_typeof(p_beleg) not in ('array', 'null') then
    raise exception 'task_solution_upsert: beleg muss ein Array sein (oder JSON-null zum Leeren)'
      using errcode = '22023';
  end if;
  -- Sicherheitsnetz (Entscheidung 23): acceptance an correct_answers angleichen.
  if p_correct_answers is not null and p_acceptance is null and v_typ is distinct from 'TERM' then
    select acceptance into v_alt from task_solutions where task_id = p_task_id;
    if v_alt is not null and public.pruef_acceptance_angleichen(v_alt, p_correct_answers) is distinct from v_alt then
      p_acceptance := public.pruef_acceptance_angleichen(v_alt, p_correct_answers);
    end if;
  end if;
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
    (p_task_id, coalesce(p_correct_answers, '[]'::jsonb), nullif(p_solution, ''),
     coalesce(p_hints, '[]'::jsonb), coalesce(p_coach_hints, '[]'::jsonb),
     coalesce(p_typical_errors, '[]'::jsonb),
     case when p_beleg is null or jsonb_typeof(p_beleg) = 'null' then null else p_beleg end,
     case when p_acceptance is null or jsonb_typeof(p_acceptance) = 'null' then null else p_acceptance end,
     case when p_option_scores is null or jsonb_typeof(p_option_scores) = 'null' then null else p_option_scores end,
     now())
  on conflict (task_id) do update
     set correct_answers = coalesce(p_correct_answers, s.correct_answers),
         solution        = case when p_solution is null then s.solution else nullif(p_solution, '') end,
         hints           = coalesce(p_hints, s.hints),
         coach_hints     = coalesce(p_coach_hints, s.coach_hints),
         typical_errors  = coalesce(p_typical_errors, s.typical_errors),
         beleg           = case when p_beleg is null then s.beleg
                                when jsonb_typeof(p_beleg) = 'null' then null else p_beleg end,
         acceptance      = case when p_acceptance is null then s.acceptance
                                when jsonb_typeof(p_acceptance) = 'null' then null else p_acceptance end,
         option_scores   = case when p_option_scores is null then s.option_scores
                                when jsonb_typeof(p_option_scores) = 'null' then null else p_option_scores end,
         updated_at      = now();

  return jsonb_build_object('ok', true, 'task_id', p_task_id);
end $$;


--
-- Name: task_solutions_pruef_version(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.task_solutions_pruef_version() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  update public.tasks set pruef_version = pruef_version where id = new.task_id;
  return null;
end $$;


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
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_task tasks%rowtype;
  v_gate text;
begin
  if not (public.get_my_role() is not distinct from 'admin' or public.ist_systemaufruf()) then
    raise exception 'task_status_set: nur admin' using errcode = '42501';
  end if;
  if p_status not in ('draft', 'review', 'ready') then
    raise exception 'task_status_set: unbekannter Status %', p_status using errcode = '22023';
  end if;
  select * into v_task from tasks where id = p_task_id for update;
  if not found then
    raise exception 'task_status_set: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  -- "Passt nicht" und "Vom Team beanstandet" werden nicht freigegeben, auch nicht ueber review: erst
  -- ueberarbeiten, dann zurueck an Lena (Entscheidung Rasit, 05.10.2026; Consensus-Check W2).
  if p_status in ('review', 'ready') and v_task.status = 'beanstandet' then
    perform public.pruef_fehler('erst_an_lena', 'task_status_set: erst zurueck an Lena');
  end if;
  -- Das Gate (Migration 2c). Was hier durchfaellt, kommt nicht in den LSA-Pool.
  if p_status in ('review', 'ready') then
    v_gate := public.freigabe_gate_fehler(p_task_id);
    if v_gate is not null then
      raise exception '%', v_gate using errcode = 'P0001';
    end if;
  end if;

  update tasks
     set status      = p_status,
         reviewed_by = case when p_status = 'ready' then auth.uid() else null end,
         reviewed_at = case when p_status = 'ready' then now()      else null end
   where id = p_task_id;

  if p_status = 'draft' and v_task.status in ('review', 'rueckfrage', 'beanstandet') then
    delete from task_pruefung_ausgang where task_id = p_task_id;
  end if;

  return jsonb_build_object('ok', true, 'task_id', p_task_id, 'status', p_status);
end $$;


--
-- Name: tasks_pruef_version(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.tasks_pruef_version() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  new.pruef_version := old.pruef_version + 1;
  return new;
end $$;


--
-- Name: tasks_pruefer_guard(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.tasks_pruefer_guard() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if current_user = 'authenticated'
     and public.get_my_role() is distinct from 'admin' then
    if new.status      is distinct from old.status
       or new.reviewed_by is distinct from old.reviewed_by
       or new.reviewed_at is distinct from old.reviewed_at then
      raise exception 'Freigabe: Status nur ueber task_status_set / lena_beanstande'
        using errcode = '42501';
    end if;
    -- Herkunft und Steuerung des Bestands pflegt der Pruefer nicht: sie
    -- entscheiden, woher eine Aufgabe kommt und ob/wie die LSA sie zieht.
    if new.id is distinct from old.id
       or new.source        is distinct from old.source
       or new.source_ref    is distinct from old.source_ref
       or new.created_at    is distinct from old.created_at
       or new.content_type  is distinct from old.content_type
       or new.is_active     is distinct from old.is_active
       or new.is_diagnostic is distinct from old.is_diagnostic
       or new.is_tutorial   is distinct from old.is_tutorial
       or new.skill_key     is distinct from old.skill_key
       or new.sondierrang   is distinct from old.sondierrang then
      raise exception 'Freigabe: Herkunfts- und Steuerfelder aendert nur admin'
        using errcode = '42501';
    end if;
    if old.status = 'ready' then
      raise exception 'Freigabe: eine freigegebene Aufgabe aendert nur admin'
        using errcode = '42501';
    end if;
  end if;
  return new;
end $$;


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
-- Name: testkonto_setzen(text, uuid, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.testkonto_setzen(p_art text, p_id uuid, p_wert boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_n integer;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'testkonto_setzen: nur Admin' using errcode = '42501';
  end if;
  if p_id is null or p_wert is null or p_art not in ('student', 'lead') then
    raise exception 'testkonto_setzen: Art student|lead, Id und Wert sind Pflicht' using errcode = '22023';
  end if;
  if p_art = 'student' then
    update public.students set ist_test = p_wert where id = p_id;
    get diagnostics v_n = row_count;
  else
    update public.leads set ist_test = p_wert where id = p_id;
    get diagnostics v_n = row_count;
    -- Ein Lead hat vor der LSA-Freigabe meist noch kein Kind; dann nur der Lead.
    update public.students set ist_test = p_wert where lead_id = p_id;
  end if;
  if v_n = 0 then
    raise exception 'testkonto_setzen: nicht gefunden' using errcode = 'P0002';
  end if;
end;
$$;


--
-- Name: vertraege_guard(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.vertraege_guard() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.updated_at := now();

  -- Innerhalb einer vertrag_*-RPC gilt, was die RPC schreibt.
  if coalesce(current_setting('edvance.vertrag_rpc', true), '') = '1' then
    return new;
  end if;

  if new.status is distinct from old.status then
    raise exception 'vertraege: Status nur ueber vertrag_*-RPCs aendern' using errcode = '42501';
  end if;
  if new.vertrag_status is distinct from old.vertrag_status then
    raise exception 'vertraege: vertrag_status nur ueber vertrag_*-RPCs aendern' using errcode = '42501';
  end if;

  -- Preis und Einheiten folgen aus (Paket, Laufzeit) — nie aus dem Formular.
  if new.status = 'in_vorbereitung'
     and (new.tier_id is distinct from old.tier_id
          or new.laufzeit_monate is distinct from old.laufzeit_monate) then
    new.preis_cents := null;
    new.einheiten   := null;
    select tl.preis_cents, tl.einheiten
      into new.preis_cents, new.einheiten
      from public.tier_laufzeiten tl
     where tl.tier_id = new.tier_id
       and tl.laufzeit_monate = new.laufzeit_monate;
  else
    new.preis_cents := old.preis_cents;
    new.einheiten   := old.einheiten;
  end if;

  return new;
end;
$$;


--
-- Name: vertrag_ablehnen(uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.vertrag_ablehnen(p_vertrag_id uuid, p_grund text, p_notiz text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_vertrag vertraege%rowtype;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_ablehnen: nur Admin' using errcode = '42501';
  end if;

  select * into v_vertrag from vertraege where id = p_vertrag_id for update;
  if not found then
    raise exception 'vertrag_ablehnen: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;
  if v_vertrag.status = 'abgelehnt' then
    return;
  end if;
  if v_vertrag.status = 'abgeschlossen' then
    raise exception 'vertrag_ablehnen: Vertrag ist bereits abgeschlossen' using errcode = 'P0001';
  end if;

  perform set_config('edvance.vertrag_rpc', '1', true);
  update vertraege
     set status = 'abgelehnt', abgelehnt_at = now(),
         abgelehnt_grund = p_grund, abgelehnt_notiz = p_notiz
   where id = p_vertrag_id;
  perform set_config('edvance.vertrag_rpc', '', true);

  update leads
     set status = 'rejected', rejection_reason = p_grund, rejection_note = p_notiz
   where id = v_vertrag.lead_id;
end;
$$;


--
-- Name: vertrag_abschliessen(uuid, text, jsonb, text, text, date, date, text, text, uuid, integer, date, uuid, text, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.vertrag_abschliessen(p_vertrag_id uuid, p_weg text, p_zustimmungen jsonb DEFAULT '[]'::jsonb, p_signatur_vertrag text DEFAULT NULL::text, p_signatur_sepa text DEFAULT NULL::text, p_unterschrieben_am date DEFAULT NULL::date, p_eingang_datum date DEFAULT NULL::date, p_scan_pfad text DEFAULT NULL::text, p_abweichung_vermerk text DEFAULT NULL::text, p_tier_id uuid DEFAULT NULL::uuid, p_laufzeit_monate integer DEFAULT NULL::integer, p_vertragsbeginn date DEFAULT NULL::date, p_student_uid uuid DEFAULT NULL::uuid, p_student_email text DEFAULT NULL::text, p_parent_uid uuid DEFAULT NULL::uuid, p_parent_email text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v            vertraege%rowtype;
  v_heute      date := (now() at time zone 'Europe/Berlin')::date;
  v_tier       uuid;
  v_laufzeit   integer;
  v_beginn     date;
  v_preis      integer;
  v_einheiten  integer;
  v_ende       record;
  v_widerruf   date;
  v_code       text;
  v_student    uuid;
  v_vorgaenger uuid;
  v_fehlt      text;
  v_abweichung boolean;
  v_kindname   text;
  v_subject    uuid;
  v_erstvertrag boolean;
  v_lsa        uuid;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_abschliessen: nur Admin' using errcode = '42501';
  end if;
  if p_weg not in ('vor_ort', 'papier') then
    raise exception 'vertrag_abschliessen: unbekannter Weg %', p_weg using errcode = '22023';
  end if;

  select * into v from public.vertraege where id = p_vertrag_id for update;
  if not found then
    raise exception 'vertrag_abschliessen: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;

  -- Idempotent: ein zweiter Aufruf liefert dasselbe Ergebnis, ohne etwas zu tun.
  if v.status = 'abgeschlossen' then
    return jsonb_build_object(
      'ok', true, 'bereits_abgeschlossen', true,
      'student_id', v.student_id, 'zugangscode', v.zugangscode,
      'vertrag_ende', v.vertrag_ende, 'widerruf_bis', v.widerruf_bis,
      'ferientage', v.ferientage);
  end if;
  if v.status = 'abgelehnt' then
    raise exception 'vertrag_abschliessen: Vertrag ist abgelehnt' using errcode = 'P0001';
  end if;

  -- -------------------------------------------------------- Konditionen
  -- Auf dem Papierweg gilt, was unterschrieben wurde, nicht was versendet war.
  v_tier     := coalesce(p_tier_id,         v.tier_id);
  v_laufzeit := coalesce(p_laufzeit_monate, v.laufzeit_monate);
  v_beginn   := coalesce(p_vertragsbeginn,  v.vertragsbeginn);

  if v_tier is null or v_laufzeit is null or v_beginn is null then
    raise exception 'vertrag_abschliessen: Paket, Laufzeit oder Vertragsbeginn fehlt'
      using errcode = 'P0001';
  end if;

  select tl.preis_cents, tl.einheiten into v_preis, v_einheiten
    from public.tier_laufzeiten tl
   where tl.tier_id = v_tier and tl.laufzeit_monate = v_laufzeit;
  if v_preis is null then
    raise exception 'vertrag_abschliessen: kein Tarif fuer Paket und Laufzeit %', v_laufzeit
      using errcode = 'P0001';
  end if;

  -- -------------------------------------------------------- Weg A: vor Ort
  if p_weg = 'vor_ort' then
    if v.status <> 'in_vorbereitung' then
      raise exception 'vertrag_abschliessen: vor Ort geht nur aus der Vorbereitung (status=%)', v.status
        using errcode = 'P0001';
    end if;
    if not exists (select 1 from public.vertrag_bankdaten where vertrag_id = p_vertrag_id) then
      raise exception 'vertrag_abschliessen: IBAN fehlt' using errcode = 'P0001';
    end if;
    if nullif(p_signatur_vertrag, '') is null or nullif(p_signatur_sepa, '') is null then
      raise exception 'vertrag_abschliessen: Unterschrift fehlt' using errcode = 'P0001';
    end if;

    select string_agg(d.schluessel, ', ') into v_fehlt
      from public.vertrag_dokumente d
     where d.aktiv and d.pflicht
       and not exists (
         select 1 from jsonb_array_elements(p_zustimmungen) z
          where z ->> 'schluessel' = d.schluessel and z ->> 'version' = d.version);
    if v_fehlt is not null then
      raise exception 'vertrag_abschliessen: Zustimmung fehlt fuer %', v_fehlt
        using errcode = 'P0001';
    end if;

    insert into public.vertrag_zustimmungen
      (vertrag_id, dokument_schluessel, dokument_version, akzeptiert_at, erfasst_von)
    select p_vertrag_id, z ->> 'schluessel', z ->> 'version',
           coalesce((z ->> 'akzeptiert_at')::timestamptz, now()), auth.uid()
      from jsonb_array_elements(p_zustimmungen) z
    on conflict (vertrag_id, dokument_schluessel, dokument_version) do nothing;

    insert into public.vertrag_unterschriften (vertrag_id, art, signatur) values
      (p_vertrag_id, 'vertrag',     p_signatur_vertrag),
      (p_vertrag_id, 'sepa_mandat', p_signatur_sepa)
    on conflict (vertrag_id, art) do nothing;

    p_unterschrieben_am := v_heute;
    v_abweichung := false;

  -- -------------------------------------------------------- Weg B/C: Papier
  else
    if v.status <> 'unterschrift_ausstehend' then
      raise exception 'vertrag_abschliessen: Einpflegen geht nur bei versendeten Unterlagen (status=%)', v.status
        using errcode = 'P0001';
    end if;
    if nullif(btrim(coalesce(p_scan_pfad, '')), '') is null then
      raise exception 'vertrag_abschliessen: ohne hochgeladenen Scan kein Abschluss'
        using errcode = 'P0001';
    end if;
    if p_unterschrieben_am is null or p_eingang_datum is null then
      raise exception 'vertrag_abschliessen: Unterschriftsdatum und Eingangsdatum sind Pflicht'
        using errcode = 'P0001';
    end if;

    -- Abgleich Soll/Ist. Weicht etwas ab, ist der Vermerk Pflicht — es gilt das
    -- Papier, der Vermerk haelt fest, was die Eltern geaendert haben.
    v_abweichung := (v_tier     is distinct from v.tier_id)
                 or (v_laufzeit is distinct from v.laufzeit_monate)
                 or (v_beginn   is distinct from v.vertragsbeginn);
    if v_abweichung and nullif(btrim(coalesce(p_abweichung_vermerk, '')), '') is null then
      raise exception 'vertrag_abschliessen: Abweichung zum versendeten Stand braucht einen Vermerk'
        using errcode = 'P0001';
    end if;
  end if;

  -- -------------------------------------------------------- Ende und Frist
  -- Einzige Quelle. Wirft, wenn die Rechnung ueber ferien_nrw hinauslaeuft.
  select * into v_ende from public.vertrag_ende_berechnen(v_beginn, v_laufzeit);
  v_widerruf := public.vertrag_widerruf_bis(v_beginn);

  -- -------------------------------------------------------- Schuelerkonto
  v_erstvertrag := v.student_id is null;

  if v.student_id is not null then
    -- Folgevertrag: das Kind gibt es schon, es bekommt kein zweites Konto.
    v_student := v.student_id;

    select id into v_vorgaenger
      from public.vertraege
     where student_id = v_student
       and id <> p_vertrag_id
       and vertrag_status is not null
     order by vertrag_ende desc nulls last, abgeschlossen_am desc nulls last
     limit 1;
  else
    v_kindname := nullif(btrim(concat_ws(' ', v.kind_vorname, v.kind_nachname)), '');

    -- Der provisorische Schueler aus lead_lsa_freigeben traegt die LSA-Historie.
    select id into v_student from public.students where lead_id = v.lead_id;

    if p_student_uid is null then
      raise exception 'vertrag_abschliessen: p_student_uid fehlt — das Auth-Konto legt die Edge Function an'
        using errcode = '22023';
    end if;

    insert into public.profiles (id, email, role, full_name)
    values (p_student_uid, p_student_email, 'student', v_kindname)
    on conflict (id) do update
      set email = excluded.email, role = 'student', full_name = excluded.full_name;

    if p_parent_uid is not null then
      insert into public.profiles (id, email, role, full_name)
      values (p_parent_uid, p_parent_email, 'parent', null)
      on conflict (id) do update set email = excluded.email, role = 'parent';
      insert into public.parent_student (parent_id, student_id)
      values (p_parent_uid, p_student_uid)
      on conflict do nothing;
    end if;

    if v_student is null then
      -- Kein Lead-Schueler (Antrag ohne LSA): neue Zeile wie bisher.
      insert into public.students (profile_id, class_level, school_name)
      values (p_student_uid, v.klasse, v.schule)
      returning id into v_student;
    else
      -- Uebernahme: dieselbe Zeile, jetzt mit Konto. lead_id wird genullt,
      -- damit eine spaetere Lead-Loeschung den Schueler nicht mitreisst.
      update public.students
         set profile_id     = p_student_uid,
             is_provisional = false,
             lead_id        = null,
             class_level    = coalesce(v.klasse, class_level),
             school_name    = coalesce(v.schule, school_name)
       where id = v_student;
    end if;

    update public.leads
       set status = 'converted', converted_student_id = v_student
     where id = v.lead_id;
  end if;

  -- S1 (Entscheidung 11): Faecher auch beim Folgevertrag nachziehen.
  if v.fach is not null then
    select id into v_subject from public.subjects where name = v.fach;
    if v_subject is not null
       and not exists (select 1 from public.student_subjects
                        where student_id = v_student and subject_id = v_subject) then
      insert into public.student_subjects (student_id, subject_id) values (v_student, v_subject);
    end if;
  end if;

  -- S1: Schule der Akte aus dem Vertrag, solange die Akte keine hat. Eine in der
  -- Akte gepflegte Schule wird nicht ueberschrieben.
  if v.schule_id is not null then
    update public.students set schule_id = v.schule_id
     where id = v_student and schule_id is null;
  end if;

  -- Abo: eins je laufendem Vertrag. Der Guard verlangt, dass der Schueler
  -- vorher nicht mehr provisorisch ist — deshalb steht es hier unten.
  if not exists (select 1 from public.student_subscriptions
                  where student_id = v_student and tier_id = v_tier and status = 'active') then
    insert into public.student_subscriptions (student_id, tier_id) values (v_student, v_tier);
  end if;

  -- -------------------------------------------------------- Zugangscode
  v_code := coalesce(v.zugangscode, public.zugangscode_erzeugen());

  -- -------------------------------------------------------- Der Vertrag
  perform set_config('edvance.vertrag_rpc', '1', true);

  -- Zuerst der Vorgaenger: er ist verlaengert und faellt damit aus dem
  -- Partial-Unique-Index. Andersherum schluegen beide Vertraege gleichzeitig
  -- als "laufend" auf und der Index wuerde den Abschluss abweisen.
  if v_vorgaenger is not null then
    update public.vertraege
       set verlaengerung_status = 'verlaengert'
     where id = v_vorgaenger;
  end if;

  update public.vertraege
     set status                 = 'abgeschlossen',
         vertrag_status         = 'im_widerruf',
         abgeschlossen_at       = now(),
         abgeschlossen_am       = coalesce(p_unterschrieben_am, v_heute),
         abschluss_weg          = p_weg,
         unterschrieben_am      = p_unterschrieben_am,
         eingang_datum          = p_eingang_datum,
         scan_pfad              = coalesce(p_scan_pfad, scan_pfad),
         abweichung_vermerk     = coalesce(nullif(btrim(coalesce(p_abweichung_vermerk, '')), ''),
                                           abweichung_vermerk),
         tier_id                = v_tier,
         laufzeit_monate        = v_laufzeit,
         vertragsbeginn         = v_beginn,
         preis_cents            = v_preis,
         einheiten              = v_einheiten,
         vertrag_ende           = v_ende.ende,
         ferientage             = v_ende.ferientage,
         widerruf_bis           = v_widerruf,
         zugangscode            = v_code,
         zugangscode_erzeugt_am = coalesce(zugangscode_erzeugt_am, v_heute),
         student_id             = v_student,
         vorgaenger_id          = coalesce(vorgaenger_id, v_vorgaenger),
         glaeubiger_id          = coalesce(glaeubiger_id,
                                    (select glaeubiger_id from public.vertrag_einstellungen))
   where id = p_vertrag_id;

  perform set_config('edvance.vertrag_rpc', '', true);

  -- S1 (Entscheidung 10): Report 1 = die LSA, beim ersten Vertrag des Kindes.
  -- Die letzte abgeschlossene LSA; ohne LSA kein Report 1.
  if v_erstvertrag then
    select l.id into v_lsa
      from public.lsa_sessions l
     where l.student_id = v_student and l.status = 'completed'
       and not l.testlauf
     order by l.completed_at desc nulls last
     limit 1;
    if v_lsa is not null
       and not exists (select 1 from public.eltern_reports where lsa_session_id = v_lsa) then
      perform public.eltern_report_eintragen(
        p_student_id     => v_student,
        p_art            => 'lernstandsanalyse',
        p_lsa_session_id => v_lsa);
    end if;
  end if;

  return jsonb_build_object(
    'ok', true,
    'student_id',   v_student,
    'zugangscode',  v_code,
    'vertrag_ende', v_ende.ende,
    'ferientage',   v_ende.ferientage,
    'ferien',       to_jsonb(v_ende.ferien),
    'widerruf_bis', v_widerruf,
    'abweichung',   coalesce(v_abweichung, false));
end;
$$;


--
-- Name: vertrag_bankdaten_maskieren(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.vertrag_bankdaten_maskieren() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  update vertraege
     set iban_masked = left(new.iban, 2) || '** **** ' || right(new.iban, 4)
   where id = new.vertrag_id;
  return new;
end;
$$;


--
-- Name: vertrag_bruecke(uuid, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.vertrag_bruecke(p_student_id uuid, p_datum date) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  select exists (
    select 1
      from public.vertraege alt
      join public.vertraege neu on neu.vorgaenger_id = alt.id
     where alt.student_id = p_student_id
       and alt.status = 'abgeschlossen'
       and alt.widerrufen_am is null
       and alt.vertrag_ende is not null
       and alt.vertrag_ende < p_datum
       and neu.status = 'abgeschlossen'
       and neu.widerrufen_am is null
       and neu.vertragsbeginn is not null
       and neu.vertragsbeginn > p_datum
  );
$$;


--
-- Name: vertrag_datei_eintragen(uuid, text, text, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.vertrag_datei_eintragen(p_vertrag_id uuid, p_art text, p_pfad text, p_sha256 text, p_bytes integer DEFAULT NULL::integer) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_status text;
  v_id     uuid;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_datei_eintragen: nur Admin' using errcode = '42501';
  end if;

  select status into v_status from public.vertraege where id = p_vertrag_id;
  if v_status is null then
    raise exception 'vertrag_datei_eintragen: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;

  -- Ein Vertragsdokument gibt es erst, wenn der Vertrag steht. Vorher waere es
  -- ein Entwurf mit dem Aussehen einer Urkunde.
  if p_art in ('vertrag', 'unterschrift') and v_status <> 'abgeschlossen' then
    raise exception 'vertrag_datei_eintragen: Vertrag ist nicht abgeschlossen (%)', v_status
      using errcode = 'P0001';
  end if;

  -- Der Pfad muss unter dem Vertrag liegen. Sonst koennte ein Eintrag auf ein
  -- fremdes Dokument zeigen und die Zuordnung waere nur noch Behauptung.
  if p_pfad !~ ('^' || p_vertrag_id::text || '/') then
    raise exception 'vertrag_datei_eintragen: Pfad gehoert nicht zu diesem Vertrag (%)', p_pfad
      using errcode = 'P0001';
  end if;

  begin
    insert into public.vertrag_dateien (vertrag_id, art, pfad, sha256, bytes, erzeugt_von)
    values (p_vertrag_id, p_art, p_pfad, lower(p_sha256), p_bytes, auth.uid())
    returning id into v_id;
  exception when unique_violation then
    raise exception 'vertrag_datei_eintragen: fuer diesen Vertrag gibt es "%" schon', p_art
      using errcode = '23505';
  end;

  -- Kein audit_log-Eintrag: Die Zeile selbst ist das Protokoll — sie traegt
  -- erzeugt_von und erzeugt_am, und geloescht wird hier nichts. audit_log ist
  -- fuer Zugriffe gedacht, die sonst spurlos blieben (etwa die volle IBAN).

  return v_id;
end;
$$;


--
-- Name: vertrag_ende_berechnen(date, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.vertrag_ende_berechnen(p_beginn date, p_laufzeit_monate integer) RETURNS TABLE(nominal date, ferientage integer, ende date, ferien text[])
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  c_max_runden constant integer := 500;
  v_nominal  date;
  v_fix      date;
  v_neu      date;
  v_ende     date;
  v_tage     integer;
  v_runde    integer;
  v_bis      date;
  v_erster   date;
  v_letzter  date;
  v_namen    text[];
begin
  if p_beginn is null or p_laufzeit_monate is null then
    raise exception 'vertrag_ende_berechnen: p_beginn und p_laufzeit_monate sind Pflicht'
      using errcode = '22023';
  end if;
  if p_laufzeit_monate not in (6, 12) then
    raise exception 'vertrag_ende_berechnen: Laufzeit ist 6 oder 12 Monate, nicht %', p_laufzeit_monate
      using errcode = '22023';
  end if;
  if extract(day from p_beginn) <> 1 then
    raise exception 'vertrag_ende_berechnen: Vertragsbeginn ist immer der Monatserste (% ist es nicht)', p_beginn
      using errcode = '22023';
  end if;

  v_nominal := (p_beginn + make_interval(months => p_laufzeit_monate))::date - 1;

  -- ------------------------------------------------------------- Jahresvertrag
  if p_laufzeit_monate = 12 then
    nominal    := v_nominal;
    ferientage := 0;
    ende       := v_nominal;
    ferien     := array[]::text[];
    return next;
    return;
  end if;

  -- ---------------------------------------------------------- Halbjahresvertrag
  select min(f.von), max(f.bis) into v_erster, v_letzter from public.ferien_nrw f;

  if v_letzter is null then
    raise exception 'vertrag_ende_berechnen: ferien_nrw ist leer — ohne Ferien gibt es kein Halbjahresende'
      using errcode = 'P0001';
  end if;
  if p_beginn < v_erster then
    raise exception 'vertrag_ende_berechnen: Beginn % liegt vor dem ersten gepflegten Ferientag (%) — die Rechnung waere unvollstaendig', p_beginn, v_erster
      using errcode = 'P0001';
  end if;

  -- Fixpunkt: schieben, bis das Schieben nichts Neues mehr findet.
  v_fix   := v_nominal;
  v_runde := 0;
  loop
    v_runde := v_runde + 1;
    if v_runde > c_max_runden then
      raise exception 'vertrag_ende_berechnen: kein Fixpunkt nach % Runden (Beginn %)', c_max_runden, p_beginn
        using errcode = 'P0001';
    end if;

    select coalesce(sum((least(f.bis, v_fix) - greatest(f.von, p_beginn)) + 1), 0)::integer
      into v_tage
      from public.ferien_nrw f
     where f.von <= v_fix and f.bis >= p_beginn;

    v_neu := v_nominal + v_tage;
    exit when v_neu = v_fix;
    v_fix := v_neu;
  end loop;

  -- Aufrunden und, falls noetig, aus den Ferien heraus — bis beides stimmt.
  v_ende  := v_fix;
  v_runde := 0;
  loop
    v_runde := v_runde + 1;
    if v_runde > 50 then
      raise exception 'vertrag_ende_berechnen: Aufrunden findet keinen ferienfreien Tag (Beginn %)', p_beginn
        using errcode = 'P0001';
    end if;

    v_ende := case
                when extract(day from v_ende) < 15 then date_trunc('month', v_ende)::date + 14
                when extract(day from v_ende) = 15 then v_ende
                else (date_trunc('month', v_ende) + interval '1 month')::date - 1
              end;

    v_bis := null;
    select f.bis into v_bis
      from public.ferien_nrw f
     where v_ende between f.von and f.bis
     limit 1;

    exit when v_bis is null;
    v_ende := v_bis + 1;
  end loop;

  if v_ende > v_letzter then
    raise exception 'vertrag_ende_berechnen: Ende % liegt nach dem letzten gepflegten Ferientag (%). Ferien in ferien_nrw ergaenzen — hier wird nicht still gerechnet.', v_ende, v_letzter
      using errcode = 'P0001';
  end if;

  -- Die Ferien, die gezaehlt haben (Fenster des Fixpunkts, nicht des gerundeten
  -- Endes) — als Nachweis fuer die Vertragsunterlage.
  select coalesce(array_agg(f.name order by f.von), array[]::text[])
    into v_namen
    from public.ferien_nrw f
   where f.von <= v_fix and f.bis >= p_beginn;

  nominal    := v_nominal;
  ferientage := v_tage;
  ende       := v_ende;
  ferien     := v_namen;
  return next;
end;
$$;


--
-- Name: vertrag_folgevertrag_starten(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.vertrag_folgevertrag_starten(p_vorgaenger_id uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_alt   vertraege%rowtype;
  v_id    uuid;
  v_preis integer;
  v_einh  integer;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_folgevertrag_starten: nur Admin' using errcode = '42501';
  end if;

  select * into v_alt from public.vertraege where id = p_vorgaenger_id for update;
  if not found then
    raise exception 'vertrag_folgevertrag_starten: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;
  if v_alt.status <> 'abgeschlossen' then
    raise exception 'vertrag_folgevertrag_starten: ein Folgevertrag entsteht nur aus einem abgeschlossenen Vertrag'
      using errcode = 'P0001';
  end if;
  if v_alt.student_id is null then
    raise exception 'vertrag_folgevertrag_starten: der Vorgaenger haengt an keinem Kind'
      using errcode = 'P0001';
  end if;

  -- Idempotent: der Knopf darf zweimal gedrueckt werden.
  select id into v_id
    from public.vertraege
   where vorgaenger_id = p_vorgaenger_id
     and status in ('in_vorbereitung', 'unterschrift_ausstehend');
  if v_id is not null then
    return v_id;
  end if;

  select tl.preis_cents, tl.einheiten into v_preis, v_einh
    from public.tier_laufzeiten tl
   where tl.tier_id = v_alt.tier_id
     and tl.laufzeit_monate = v_alt.laufzeit_monate;

  insert into public.vertraege (
    created_by, lead_id, student_id, vorgaenger_id,
    eltern_vorname, eltern_nachname, strasse, hausnummer, plz, ort,
    eltern_telefon, eltern_email,
    kind_vorname, kind_nachname, kind_geburtsdatum, klasse, fach,
    schule, schule_id, kontoinhaber,
    tier_id, laufzeit_monate, preis_cents, einheiten
  ) values (
    auth.uid(), v_alt.lead_id, v_alt.student_id, p_vorgaenger_id,
    v_alt.eltern_vorname, v_alt.eltern_nachname, v_alt.strasse, v_alt.hausnummer,
    v_alt.plz, v_alt.ort, v_alt.eltern_telefon, v_alt.eltern_email,
    v_alt.kind_vorname, v_alt.kind_nachname, v_alt.kind_geburtsdatum,
    v_alt.klasse, v_alt.fach,
    v_alt.schule, v_alt.schule_id, v_alt.kontoinhaber,
    v_alt.tier_id, v_alt.laufzeit_monate, v_preis, v_einh
  )
  returning id into v_id;

  -- Ein eigenes Mandat je Vertrag (Dokument 1), aber dieselbe Bankverbindung.
  -- Die Mandatsreferenz zieht der Default aus der Sequenz; die IBAN wird
  -- uebernommen und laesst sich in Schritt 1 aendern.
  insert into public.vertrag_bankdaten (vertrag_id, iban)
  select v_id, b.iban
    from public.vertrag_bankdaten b
   where b.vertrag_id = p_vorgaenger_id;

  return v_id;
end;
$$;


--
-- Name: vertrag_iban_anzeigen(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.vertrag_iban_anzeigen(p_vertrag_id uuid) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_iban text;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_iban_anzeigen: nur Admin' using errcode = '42501';
  end if;

  select b.iban into v_iban
    from public.vertrag_bankdaten b where b.vertrag_id = p_vertrag_id;
  if v_iban is null then
    raise exception 'vertrag_iban_anzeigen: zu diesem Vertrag ist keine IBAN hinterlegt'
      using errcode = 'P0002';
  end if;

  perform public.audit_log_schreiben('iban_angezeigt', 'vertrag', p_vertrag_id);
  return v_iban;
end;
$$;


--
-- Name: vertrag_sonderkuendigung_erfassen(uuid, date, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.vertrag_sonderkuendigung_erfassen(p_vertrag_id uuid, p_zum date, p_grund text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v vertraege%rowtype;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_sonderkuendigung_erfassen: nur Admin' using errcode = '42501';
  end if;
  if p_zum is null then
    raise exception 'vertrag_sonderkuendigung_erfassen: Kuendigungsdatum fehlt' using errcode = '22023';
  end if;
  if nullif(btrim(coalesce(p_grund, '')), '') is null then
    raise exception 'vertrag_sonderkuendigung_erfassen: Grund ist Pflicht' using errcode = 'P0001';
  end if;

  select * into v from public.vertraege where id = p_vertrag_id for update;
  if not found then
    raise exception 'vertrag_sonderkuendigung_erfassen: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;
  if v.status <> 'abgeschlossen' then
    raise exception 'vertrag_sonderkuendigung_erfassen: nur ein abgeschlossener Vertrag ist kuendbar'
      using errcode = 'P0001';
  end if;

  update public.vertraege
     set gekuendigt_zum   = p_zum,
         kuendigung_grund = btrim(p_grund)
   where id = p_vertrag_id;

  return jsonb_build_object('ok', true, 'gekuendigt_zum', p_zum);
end;
$$;


--
-- Name: vertrag_starten(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.vertrag_starten(p_lead_id uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_lead     leads%rowtype;
  v_id       uuid;
  v_schule   uuid;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_starten: nur Admin' using errcode = '42501';
  end if;

  select * into v_lead from public.leads where id = p_lead_id for update;
  if not found then
    raise exception 'vertrag_starten: Lead nicht gefunden' using errcode = 'P0002';
  end if;

  select id into v_id from public.vertraege
   where lead_id = p_lead_id and status <> 'abgelehnt';
  if v_id is not null then
    return v_id;   -- idempotent: der Knopf darf zweimal gedrueckt werden
  end if;

  if v_lead.status <> 'lsa_fertig' then
    raise exception 'vertrag_starten: Lead steht nicht auf "Analyse abgeschlossen"'
      using errcode = 'P0001';
  end if;

  select s.id into v_schule
    from public.schulen s
   where lower(s.name) = lower(btrim(coalesce(v_lead.school_name, '')))
   limit 1;

  insert into public.vertraege (
    created_by, lead_id, eltern_telefon, eltern_email,
    kind_vorname, kind_nachname, kind_geburtsdatum, klasse, fach, schule, schule_id
  ) values (
    auth.uid(), p_lead_id, v_lead.contact_phone, v_lead.contact_email,
    coalesce(v_lead.first_name, split_part(v_lead.full_name, ' ', 1)),
    nullif(regexp_replace(v_lead.full_name, '^\S+\s*', ''), ''),
    v_lead.birth_date, v_lead.class_level, v_lead.subjects[1], v_lead.school_name, v_schule
  )
  returning id into v_id;

  update public.leads set status = 'vertrag' where id = p_lead_id;
  return v_id;
end;
$$;


--
-- Name: vertrag_verlaengerung_setzen(uuid, text, text, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.vertrag_verlaengerung_setzen(p_vertrag_id uuid, p_status text, p_grund text DEFAULT NULL::text, p_wiedervorlage_am date DEFAULT NULL::date) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v vertraege%rowtype;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_verlaengerung_setzen: nur Admin' using errcode = '42501';
  end if;
  if p_status = 'verlaengert' then
    raise exception 'vertrag_verlaengerung_setzen: verlaengert entsteht nur aus einem Folgevertrag'
      using errcode = 'P0001';
  end if;
  if p_status not in ('offen','kontaktiert','gespraech_vereinbart','keine_verlaengerung') then
    raise exception 'vertrag_verlaengerung_setzen: unbekannter Status %', p_status using errcode = '22023';
  end if;
  if p_status = 'keine_verlaengerung'
     and nullif(btrim(coalesce(p_grund, '')), '') is null then
    raise exception 'vertrag_verlaengerung_setzen: keine_verlaengerung braucht einen Grund'
      using errcode = 'P0001';
  end if;

  select * into v from public.vertraege where id = p_vertrag_id for update;
  if not found then
    raise exception 'vertrag_verlaengerung_setzen: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;

  update public.vertraege
     set verlaengerung_status = p_status,
         verlaengerung_grund  = nullif(btrim(coalesce(p_grund, '')), ''),
         wiedervorlage_am     = p_wiedervorlage_am
   where id = p_vertrag_id;

  return jsonb_build_object('ok', true, 'verlaengerung_status', p_status);
end;
$$;


--
-- Name: vertrag_versand_protokollieren(uuid, text, text, text, jsonb, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.vertrag_versand_protokollieren(p_vertrag_id uuid, p_weg text, p_anlass text, p_empfaenger text DEFAULT NULL::text, p_anhaenge jsonb DEFAULT NULL::jsonb, p_fehler text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_status text;
  v_id     uuid;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_versand_protokollieren: nur Admin' using errcode = '42501';
  end if;

  select status into v_status from public.vertraege where id = p_vertrag_id for update;
  if not found then
    raise exception 'vertrag_versand_protokollieren: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;
  if v_status = 'abgelehnt' then
    raise exception 'vertrag_versand_protokollieren: Vertrag ist abgelehnt' using errcode = 'P0001';
  end if;

  insert into public.vertrag_versand
    (vertrag_id, weg, anlass, empfaenger, anhaenge, fehler, erfolgt_von)
  values
    (p_vertrag_id, p_weg, p_anlass, p_empfaenger, p_anhaenge,
     nullif(btrim(coalesce(p_fehler, '')), ''), auth.uid())
  returning id into v_id;

  -- Unveraendert aus der alten Fassung: wer die Unterlagen rausgibt, wartet
  -- ab da auf Post. Beim Mailweg hat vertrag_versenden das schon getan, dann
  -- greift die Bedingung nicht.
  if p_anlass = 'unterlagen' and v_status = 'in_vorbereitung' then
    perform set_config('edvance.vertrag_rpc', '1', true);
    update public.vertraege
       set status = 'unterschrift_ausstehend',
           unterschrift_ausstehend_at = now(),
           glaeubiger_id = coalesce(glaeubiger_id,
             (select glaeubiger_id from public.vertrag_einstellungen))
     where id = p_vertrag_id;
    perform set_config('edvance.vertrag_rpc', '', true);
  end if;

  return v_id;
end;
$$;


--
-- Name: vertrag_versenden(uuid, text, text, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.vertrag_versenden(p_vertrag_id uuid, p_weg text, p_empfaenger text DEFAULT NULL::text, p_rueckmeldung_bis date DEFAULT NULL::date) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v     vertraege%rowtype;
  v_bis date;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_versenden: nur Admin' using errcode = '42501';
  end if;
  if p_weg not in ('email', 'druck') then
    raise exception 'vertrag_versenden: unbekannter Weg %', p_weg using errcode = '22023';
  end if;

  select * into v from public.vertraege where id = p_vertrag_id for update;
  if not found then
    raise exception 'vertrag_versenden: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;
  if v.status = 'abgelehnt' then
    raise exception 'vertrag_versenden: Vertrag ist abgelehnt' using errcode = 'P0001';
  end if;
  if v.status = 'abgeschlossen' then
    raise exception 'vertrag_versenden: Vertrag ist bereits abgeschlossen' using errcode = 'P0001';
  end if;
  if v.tier_id is null or v.laufzeit_monate is null or v.vertragsbeginn is null then
    raise exception 'vertrag_versenden: Paket, Laufzeit oder Vertragsbeginn fehlt'
      using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.vertrag_bankdaten where vertrag_id = p_vertrag_id) then
    raise exception 'vertrag_versenden: IBAN fehlt' using errcode = 'P0001';
  end if;

  -- Fassungen festhalten: ALLE aktiven Dokumente, nicht nur die Pflichtstuecke.
  -- Rechtlich notwendig ist das Buendel, nicht die Auswahl daraus.
  insert into public.vertrag_zustimmungen
    (vertrag_id, dokument_schluessel, dokument_version, akzeptiert_at, erfasst_von)
  select p_vertrag_id, d.schluessel, d.version, now(), auth.uid()
    from public.vertrag_dokumente d
   where d.aktiv
  on conflict (vertrag_id, dokument_schluessel, dokument_version) do nothing;

  if p_weg = 'druck' then
    insert into public.vertrag_versand (vertrag_id, weg, anlass, empfaenger, erfolgt_von)
    values (p_vertrag_id, p_weg, 'unterlagen', p_empfaenger, auth.uid());
  end if;

  v_bis := coalesce(p_rueckmeldung_bis,
                    v.rueckmeldung_bis,
                    (now() at time zone 'Europe/Berlin')::date + 14);

  perform set_config('edvance.vertrag_rpc', '1', true);
  update public.vertraege
     set status = 'unterschrift_ausstehend',
         unterschrift_ausstehend_at = coalesce(unterschrift_ausstehend_at, now()),
         abschluss_weg   = 'papier',
         rueckmeldung_bis = v_bis,
         glaeubiger_id   = coalesce(glaeubiger_id,
                             (select glaeubiger_id from public.vertrag_einstellungen))
   where id = p_vertrag_id;
  perform set_config('edvance.vertrag_rpc', '', true);

  return jsonb_build_object('ok', true, 'rueckmeldung_bis', v_bis);
end;
$$;


--
-- Name: vertrag_widerruf_bis(date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.vertrag_widerruf_bis(p_beginn date) RETURNS date
    LANGUAGE sql IMMUTABLE
    AS $$
  select p_beginn + 29;
$$;


--
-- Name: vertrag_widerruf_erfassen(uuid, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.vertrag_widerruf_erfassen(p_vertrag_id uuid, p_datum date DEFAULT CURRENT_DATE) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v vertraege%rowtype;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_widerruf_erfassen: nur Admin' using errcode = '42501';
  end if;

  select * into v from public.vertraege where id = p_vertrag_id for update;
  if not found then
    raise exception 'vertrag_widerruf_erfassen: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;
  if v.status <> 'abgeschlossen' then
    raise exception 'vertrag_widerruf_erfassen: nur ein abgeschlossener Vertrag ist widerrufbar'
      using errcode = 'P0001';
  end if;
  if v.widerrufen_am is not null then
    return jsonb_build_object('ok', true, 'bereits_widerrufen', true,
                              'widerrufen_am', v.widerrufen_am);
  end if;
  if v.widerruf_bis is null or p_datum > v.widerruf_bis then
    raise exception 'vertrag_widerruf_erfassen: Widerrufsfrist endete am %', v.widerruf_bis
      using errcode = 'P0001';
  end if;

  update public.vertraege
     set widerrufen_am           = p_datum,
         zugangscode_gesperrt_am = coalesce(zugangscode_gesperrt_am, p_datum)
   where id = p_vertrag_id;

  return jsonb_build_object('ok', true, 'widerrufen_am', p_datum);
end;
$$;


--
-- Name: vertrag_wirksamer_status(date, date, date, date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.vertrag_wirksamer_status(p_widerrufen_am date, p_gekuendigt_zum date, p_vertrag_ende date, p_widerruf_bis date, p_datum date DEFAULT CURRENT_DATE) RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select case
    when p_widerrufen_am  is not null                          then 'widerrufen'
    when p_gekuendigt_zum is not null and p_gekuendigt_zum <= p_datum then 'gekuendigt'
    when p_vertrag_ende   is not null and p_vertrag_ende   <  p_datum then 'ausgelaufen'
    when p_widerruf_bis   is not null and p_datum <= p_widerruf_bis   then 'im_widerruf'
    else 'aktiv'
  end;
$$;


--
-- Name: vertrag_zahlungsstatus_setzen(uuid, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.vertrag_zahlungsstatus_setzen(p_vertrag_id uuid, p_status text, p_offener_betrag_cents integer DEFAULT NULL::integer) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  c_stufen constant text[] := array['in_ordnung','zahlung_offen','mahnung_1','mahnung_2','inkasso'];
  v        vertraege%rowtype;
  v_alt    integer;
  v_neu    integer;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_zahlungsstatus_setzen: nur Admin' using errcode = '42501';
  end if;

  v_neu := array_position(c_stufen, p_status);
  if v_neu is null then
    raise exception 'vertrag_zahlungsstatus_setzen: unbekannte Stufe %', p_status using errcode = '22023';
  end if;

  select * into v from public.vertraege where id = p_vertrag_id for update;
  if not found then
    raise exception 'vertrag_zahlungsstatus_setzen: Vertrag nicht gefunden' using errcode = 'P0002';
  end if;

  v_alt := array_position(c_stufen, v.zahlungsstatus);
  if p_status <> 'in_ordnung' and v_neu <> v_alt + 1 then
    raise exception 'vertrag_zahlungsstatus_setzen: von % geht es nur eine Stufe weiter oder zurueck auf in_ordnung', v.zahlungsstatus
      using errcode = 'P0001';
  end if;

  update public.vertraege
     set zahlungsstatus       = p_status,
         zahlungsstatus_seit  = current_date,
         -- Zurueck auf in_ordnung heisst: nichts mehr offen.
         offener_betrag_cents = case when p_status = 'in_ordnung' then null
                                     else p_offener_betrag_cents end
   where id = p_vertrag_id;

  return jsonb_build_object('ok', true, 'zahlungsstatus', p_status, 'seit', current_date);
end;
$$;


--
-- Name: vertrag_zugangscode_neu(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.vertrag_zugangscode_neu(p_vertrag_id uuid) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_gueltig boolean;
  v_code    text;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'vertrag_zugangscode_neu: nur Admin' using errcode = '42501';
  end if;

  select a.zugangscode_gueltig into v_gueltig
    from public.vertraege_aktuell a where a.id = p_vertrag_id;
  if v_gueltig is null then
    raise exception 'vertrag_zugangscode_neu: kein abgeschlossener Vertrag' using errcode = 'P0002';
  end if;
  if not v_gueltig then
    raise exception 'vertrag_zugangscode_neu: der Zugangscode dieses Vertrags gilt nicht mehr'
      using errcode = 'P0001';
  end if;

  v_code := public.zugangscode_erzeugen();
  update public.vertraege
     set zugangscode = v_code, zugangscode_erzeugt_am = current_date
   where id = p_vertrag_id;

  return v_code;
end;
$$;


--
-- Name: werktage(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.werktage(p_von date, p_bis date) RETURNS integer
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
  select case when p_bis < p_von then 0 else
    ((p_bis - date '1970-01-05' + 1) / 7) * 5 + least((p_bis - date '1970-01-05' + 1) % 7, 5)
    - (((p_von - date '1970-01-05') / 7) * 5 + least((p_von - date '1970-01-05') % 7, 5))
  end;
$$;


--
-- Name: xp_buchen(uuid, integer, text, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.xp_buchen(p_student_id uuid, p_xp integer, p_grund text, p_schluessel text, p_task_id uuid DEFAULT NULL::uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  if not (public.ist_systemaufruf() or coalesce(public.get_my_role(), '') = 'admin') then
    raise exception 'xp_buchen: nur Admin oder Systemaufruf' using errcode = '42501';
  end if;
  return public.xp_buchen_intern(p_student_id, p_xp, p_grund, p_schluessel, p_task_id);
end;
$$;


--
-- Name: xp_buchen_intern(uuid, integer, text, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.xp_buchen_intern(p_student_id uuid, p_xp integer, p_grund text, p_schluessel text, p_task_id uuid DEFAULT NULL::uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_n integer;
begin
  if p_student_id is null or p_xp is null or p_xp < 1 or p_xp > 1000 then
    raise exception 'xp_buchen: Kind und Betrag 1..1000 sind Pflicht' using errcode = '22023';
  end if;
  if nullif(btrim(coalesce(p_grund, '')), '') is null
     or nullif(btrim(coalesce(p_schluessel, '')), '') is null then
    raise exception 'xp_buchen: Grund und Buchungsschluessel sind Pflicht' using errcode = '22023';
  end if;
  if not exists (select 1 from public.students where id = p_student_id) then
    raise exception 'xp_buchen: Kind nicht gefunden' using errcode = 'P0002';
  end if;

  insert into public.xp_events (student_id, task_id, xp, reason, buchungs_schluessel)
  values (p_student_id, p_task_id, p_xp, p_grund, p_schluessel)
  on conflict (student_id, buchungs_schluessel) do nothing;
  get diagnostics v_n = row_count;
  return v_n = 1;
end;
$$;


--
-- Name: ziel_fertigkeiten(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ziel_fertigkeiten(p_student_id uuid, p_thema_key text) RETURNS TABLE(reihenfolge integer, skill_key text, label text, klasse_herkunft integer, rolle text, stand_system text, stand_coach text, stand text, pruefung_faellig boolean)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
#variable_conflict use_column
begin
  if not (public.ist_systemaufruf() or public.lernpfad_darf_lesen(p_student_id)) then
    raise exception 'ziel_fertigkeiten: nur Admin oder Coach bei laufendem Vertrag' using errcode = '42501';
  end if;
  if not exists (select 1 from public.themen t where t.thema_key = p_thema_key) then
    raise exception 'ziel_fertigkeiten: Thema % unbekannt', p_thema_key using errcode = 'P0002';
  end if;

  return query
    with thema as (
      select te.skill_key, 'einstieg'::text as rolle
        from public.thema_einstieg te where te.thema_key = p_thema_key
      union
      select st.skill_key, 'thema'
        from public.skill_thema st
       where st.thema_key = p_thema_key
         and st.skill_key not in (select te.skill_key from public.thema_einstieg te
                                   where te.thema_key = p_thema_key)
    ),
    darunter as (
      select distinct a.skill_key
        from thema t cross join lateral public.lsa_abschluss(t.skill_key) a
       where a.skill_key not in (select skill_key from thema)
    ),
    direkt as (
      select distinct k.voraussetzt_skill_key as skill_key
        from public.skill_kante k
       where k.skill_key in (select skill_key from thema)
         and k.voraussetzt_skill_key not in (select skill_key from thema)
    ),
    voraus as (
      select d.skill_key,
             case when l.stand_coach = 'gemeistert' or l.stand_system in ('sicher', 'kandidat')
                  then 'voraussetzung_sicher' else 'voraussetzung' end as rolle
        from darunter d
        join public.lernpfad l on l.student_id = p_student_id and l.skill_key = d.skill_key
       where (l.stand_system in ('offen', 'aktiv', 'noch_nicht_sicher') and l.stand_coach is distinct from 'gemeistert')
          or d.skill_key in (select skill_key from direkt)
    ),
    liste as (
      select skill_key, rolle from thema
      union all
      select skill_key, rolle from voraus
    )
    select (row_number() over (
              order by (select count(*) from public.lsa_abschluss(li.skill_key) a
                         where a.skill_key in (select skill_key from liste)),
                       s.klasse_herkunft, s.fundament_tiefe, li.skill_key))::int,
           li.skill_key, s.label, s.klasse_herkunft, li.rolle,
           l.stand_system, l.stand_coach,
           case when l.stand_coach = 'gemeistert' then 'gemeistert'
                else coalesce(l.stand_system, 'offen') end,
           public.lernpfad_pruefung_faellig(p_student_id, li.skill_key)
      from liste li
      join public.skills s on s.skill_key = li.skill_key
      left join public.lernpfad l on l.student_id = p_student_id and l.skill_key = li.skill_key
     order by 1;
end;
$$;


--
-- Name: zugangscode_erzeugen(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.zugangscode_erzeugen() RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  c_alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_roh   text;
  v_code  text;
  v_runde integer := 0;
begin
  loop
    v_runde := v_runde + 1;
    if v_runde > 100 then
      raise exception 'zugangscode_erzeugen: 100 Kollisionen in Folge — Alphabet oder Laenge pruefen'
        using errcode = 'P0001';
    end if;

    v_roh := '';
    for i in 1..8 loop
      v_roh := v_roh || substr(c_alphabet, 1 + floor(random() * length(c_alphabet))::integer, 1);
    end loop;

    v_code := 'EDV-' || substr(v_roh, 1, 4) || '-' || substr(v_roh, 5, 4);

    exit when not exists (select 1 from public.vertraege t where t.zugangscode = v_code);
  end loop;

  return v_code;
end;
$$;


--
-- Name: akte_einstellungen; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.akte_einstellungen (
    id boolean DEFAULT true NOT NULL,
    schwelle_1 numeric DEFAULT 1.5 NOT NULL,
    schwelle_2 numeric DEFAULT 3.5 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT akte_einstellungen_eine_zeile CHECK (id),
    CONSTRAINT akte_einstellungen_schwellen CHECK (((schwelle_1 >= (0)::numeric) AND (schwelle_1 < schwelle_2)))
);


--
-- Name: akte_wortliste; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.akte_wortliste (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    liste text NOT NULL,
    wort text NOT NULL,
    nur_ganzes_wort boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid,
    CONSTRAINT akte_wortliste_liste_check CHECK ((liste = ANY (ARRAY['gesundheit'::text, 'report_verbot'::text]))),
    CONSTRAINT akte_wortliste_wort_form CHECK (((wort = lower(btrim(wort))) AND (wort <> ''::text)))
);


--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    actor uuid,
    aktion text NOT NULL,
    objekt_typ text NOT NULL,
    objekt_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT audit_log_aktion_nicht_leer CHECK ((NULLIF(btrim(aktion), ''::text) IS NOT NULL)),
    CONSTRAINT audit_log_objekt_typ_nicht_leer CHECK ((NULLIF(btrim(objekt_typ), ''::text) IS NOT NULL))
);


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
    coach_id uuid,
    room text,
    scheduled_at timestamp with time zone NOT NULL,
    status text DEFAULT 'upcoming'::text NOT NULL,
    slot_id uuid,
    testlauf boolean DEFAULT false NOT NULL,
    CONSTRAINT coaching_sessions_status_check CHECK ((status = ANY (ARRAY['upcoming'::text, 'active'::text, 'done'::text])))
);


--
-- Name: dokument_fassungen; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dokument_fassungen (
    art text NOT NULL,
    fassung text NOT NULL,
    pfad text NOT NULL,
    sha256 text NOT NULL,
    bytes integer,
    erzeugt_am timestamp with time zone DEFAULT now() NOT NULL,
    erzeugt_von uuid,
    CONSTRAINT dokument_fassungen_art_check CHECK ((art = ANY (ARRAY['agb'::text, 'widerruf'::text, 'datenschutz_vertrag'::text, 'einwilligung_fotos'::text]))),
    CONSTRAINT dokument_fassungen_bytes_check CHECK (((bytes IS NULL) OR (bytes > 0))),
    CONSTRAINT dokument_fassungen_pfad_check CHECK ((NULLIF(btrim(pfad), ''::text) IS NOT NULL)),
    CONSTRAINT dokument_fassungen_sha256_check CHECK ((sha256 ~ '^[0-9a-f]{64}$'::text))
);


--
-- Name: eltern_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eltern_reports (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    student_id uuid NOT NULL,
    nr integer NOT NULL,
    art text NOT NULL,
    berichtsmonat date,
    kernaussagen jsonb,
    freigegeben_von uuid,
    freigegeben_am timestamp with time zone,
    versendet_am timestamp with time zone,
    versendet_an text,
    pdf_pfad text,
    parent_report_id uuid,
    lsa_session_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT eltern_reports_art_check CHECK ((art = ANY (ARRAY['lernstandsanalyse'::text, 'zwischenbericht'::text]))),
    CONSTRAINT eltern_reports_berichtsmonat_erster CHECK (((berichtsmonat IS NULL) OR (EXTRACT(day FROM berichtsmonat) = (1)::numeric))),
    CONSTRAINT eltern_reports_kernaussagen_objekt CHECK (((kernaussagen IS NULL) OR (jsonb_typeof(kernaussagen) = 'object'::text))),
    CONSTRAINT eltern_reports_nr_positiv CHECK ((nr >= 1)),
    CONSTRAINT eltern_reports_pdf_pfad_nicht_leer CHECK (((pdf_pfad IS NULL) OR (NULLIF(btrim(pdf_pfad), ''::text) IS NOT NULL)))
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
-- Name: feiertage_nrw; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feiertage_nrw (
    datum date NOT NULL,
    art text NOT NULL,
    name text NOT NULL,
    CONSTRAINT feiertage_nrw_art_check CHECK ((art = ANY (ARRAY['feiertag'::text, 'pfingstferien'::text]))),
    CONSTRAINT feiertage_nrw_name_nicht_leer CHECK ((NULLIF(btrim(name), ''::text) IS NOT NULL))
);


--
-- Name: ferien_nrw; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ferien_nrw (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    art text NOT NULL,
    name text NOT NULL,
    von date NOT NULL,
    bis date NOT NULL,
    CONSTRAINT ferien_nrw_art_check CHECK ((art = ANY (ARRAY['herbst'::text, 'weihnachten'::text, 'ostern'::text, 'sommer'::text]))),
    CONSTRAINT ferien_nrw_zeitraum_check CHECK ((von <= bis))
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
-- Name: lead_mail_versand; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lead_mail_versand (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    lead_id uuid NOT NULL,
    anlass text NOT NULL,
    empfaenger text NOT NULL,
    termin_at timestamp with time zone,
    fehler text,
    erfolgt_at timestamp with time zone DEFAULT now() NOT NULL,
    erfolgt_von uuid,
    ort text NOT NULL,
    CONSTRAINT lead_mail_versand_anlass_check CHECK ((anlass = 'terminbestaetigung'::text)),
    CONSTRAINT lead_mail_versand_ort_check CHECK (((btrim(ort) <> ''::text) AND (char_length(ort) <= 300)))
);


--
-- Name: lead_themen; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lead_themen (
    lead_id uuid NOT NULL,
    fach text NOT NULL,
    thema_key text NOT NULL,
    status text NOT NULL,
    quelle text NOT NULL,
    angelegt timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT lead_themen_quelle_check CHECK ((quelle = ANY (ARRAY['gespraech'::text, 'schulplan'::text]))),
    CONSTRAINT lead_themen_status_check CHECK ((status = ANY (ARRAY['aktuell'::text, 'behandelt'::text])))
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
    lsa_freigegeben_at timestamp with time zone,
    lsa_fertig_at timestamp with time zone,
    erstgespraech_at timestamp with time zone,
    erstgespraech_standort text,
    rejected_at timestamp with time zone,
    rejection_reason text,
    rejection_note text,
    schule_id uuid,
    ist_test boolean DEFAULT false NOT NULL,
    CONSTRAINT leads_class_level_check CHECK (((class_level >= 5) AND (class_level <= 13))),
    CONSTRAINT leads_erstgespraech_standort_check CHECK (((erstgespraech_standort IS NULL) OR (erstgespraech_standort = 'koeln'::text))),
    CONSTRAINT leads_goal_check CHECK ((goal = ANY (ARRAY['IMPROVE_GRADES'::text, 'CLOSE_GAPS'::text, 'EXAM_PREP'::text, 'GENERAL'::text]))),
    CONSTRAINT leads_grade_trend_check CHECK (((grade_trend IS NULL) OR (grade_trend = ANY (ARRAY['besser'::text, 'stabil'::text, 'schlechter'::text])))),
    CONSTRAINT leads_rejection_note_check CHECK (((rejection_reason IS DISTINCT FROM 'sonstiges'::text) OR (NULLIF(btrim(rejection_note), ''::text) IS NOT NULL))),
    CONSTRAINT leads_rejection_reason_check CHECK (((rejection_reason IS NULL) OR (rejection_reason = ANY (ARRAY['preis'::text, 'zeit'::text, 'anderer_anbieter'::text, 'kein_bedarf'::text, 'kein_kontakt'::text, 'sonstiges'::text])))),
    CONSTRAINT leads_school_type_check CHECK ((school_type = ANY (ARRAY['Gymnasium'::text, 'Gesamtschule'::text, 'Realschule'::text, 'Hauptschule'::text]))),
    CONSTRAINT leads_status_check CHECK ((status = ANY (ARRAY['new'::text, 'contacted'::text, 'onboarding_scheduled'::text, 'converted'::text, 'rejected'::text, 'lsa_freigegeben'::text, 'lsa_fertig'::text, 'vertrag'::text]))),
    CONSTRAINT leads_struggling_since_check CHECK (((struggling_since IS NULL) OR (struggling_since = ANY (ARRAY['dieses_halbjahr'::text, 'letztes_schuljahr'::text, 'laenger'::text]))))
);


--
-- Name: lernpfad; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lernpfad (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    student_id uuid NOT NULL,
    skill_key text NOT NULL,
    stand_system text DEFAULT 'offen'::text NOT NULL,
    stand_system_seit timestamp with time zone DEFAULT now() NOT NULL,
    stand_coach text,
    coach_grund text,
    coach_von uuid,
    coach_am timestamp with time zone,
    coach_session_id uuid,
    quelle text NOT NULL,
    lsa_session_id uuid,
    letzte_uebung_am timestamp with time zone,
    letzte_session_id uuid,
    belege jsonb DEFAULT '[]'::jsonb NOT NULL,
    angelegt timestamp with time zone DEFAULT now() NOT NULL,
    aktualisiert timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT lernpfad_coach_vollstaendig CHECK (((stand_coach IS NULL) OR (coach_am IS NOT NULL))),
    CONSTRAINT lernpfad_quelle_check CHECK ((quelle = ANY (ARRAY['lsa'::text, 'session'::text, 'coach'::text]))),
    CONSTRAINT lernpfad_stand_coach_check CHECK ((stand_coach = ANY (ARRAY['gemeistert'::text, 'vertagt'::text]))),
    CONSTRAINT lernpfad_stand_system_check CHECK ((stand_system = ANY (ARRAY['offen'::text, 'aktiv'::text, 'sicher'::text, 'noch_nicht_sicher'::text, 'kandidat'::text]))),
    CONSTRAINT lernpfad_vertagt_braucht_grund CHECK (((stand_coach IS DISTINCT FROM 'vertagt'::text) OR (NULLIF(btrim(coach_grund), ''::text) IS NOT NULL)))
);


--
-- Name: lernpfad_belege; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lernpfad_belege (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    student_id uuid NOT NULL,
    skill_key text NOT NULL,
    session_id uuid NOT NULL,
    ergebnis text NOT NULL,
    hinweis_genutzt boolean NOT NULL,
    zeit timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT lernpfad_belege_ergebnis_check CHECK ((ergebnis = ANY (ARRAY['richtig'::text, 'teilweise'::text, 'falsch'::text])))
);


--
-- Name: lernpfad_protokoll; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lernpfad_protokoll (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    student_id uuid NOT NULL,
    skill_key text NOT NULL,
    aktion text NOT NULL,
    anlass text NOT NULL,
    alt jsonb,
    neu jsonb,
    grund text,
    von uuid,
    session_id uuid,
    am timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    CONSTRAINT lernpfad_protokoll_aktion_check CHECK ((aktion = ANY (ARRAY['mastery'::text, 'pfad_tiefer'::text, 'uebernahme'::text]))),
    CONSTRAINT lernpfad_protokoll_anlass_check CHECK ((anlass = ANY (ARRAY['lsa'::text, 'pruefung'::text, 'warmup'::text, 'eingriff'::text])))
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
    thema_key text,
    testlauf boolean DEFAULT false NOT NULL,
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
    darf_pruefen boolean DEFAULT false NOT NULL,
    CONSTRAINT profiles_role_check CHECK ((role = ANY (ARRAY['student'::text, 'parent'::text, 'coach'::text, 'admin'::text])))
);


--
-- Name: pruef_einstellungen; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pruef_einstellungen (
    id boolean DEFAULT true NOT NULL,
    hilfsmittel text DEFAULT 'Taschenrechner, Stift und Zettel'::text NOT NULL,
    nur_pilot boolean DEFAULT false NOT NULL,
    grund_pflicht boolean DEFAULT false NOT NULL,
    CONSTRAINT pruef_einstellungen_id_check CHECK (id)
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
    entwurf text,
    CONSTRAINT report_bausteine_entwurf_check CHECK (((entwurf IS NULL) OR ((btrim(entwurf) <> ''::text) AND (entwurf <> text)))),
    CONSTRAINT report_bausteine_variante_check CHECK ((variante = ANY (ARRAY['a'::text, 'b'::text])))
);


--
-- Name: schueler_notizen; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schueler_notizen (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    student_id uuid NOT NULL,
    kategorie text NOT NULL,
    text text,
    autor_id uuid,
    autor_rolle text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    ausgeblendet_am timestamp with time zone,
    ausgeblendet_von uuid,
    ausgeblendet_grund text,
    entfernt_am timestamp with time zone,
    entfernt_von uuid,
    entfernt_grund text,
    CONSTRAINT schueler_notizen_ausgeblendet_mit_grund CHECK ((((ausgeblendet_am IS NULL) AND (ausgeblendet_grund IS NULL)) OR ((ausgeblendet_am IS NOT NULL) AND (NULLIF(btrim(ausgeblendet_grund), ''::text) IS NOT NULL)))),
    CONSTRAINT schueler_notizen_autor_rolle_check CHECK ((autor_rolle = ANY (ARRAY['admin'::text, 'coach'::text]))),
    CONSTRAINT schueler_notizen_entfernt_grund CHECK ((((entfernt_am IS NULL) AND (entfernt_grund IS NULL)) OR ((entfernt_am IS NOT NULL) AND (entfernt_grund = 'gesundheitsangabe'::text)))),
    CONSTRAINT schueler_notizen_kategorie_check CHECK ((kategorie = ANY (ARRAY['lernen'::text, 'verhalten'::text, 'organisatorisch'::text]))),
    CONSTRAINT schueler_notizen_text_nicht_leer CHECK (((text IS NULL) OR (NULLIF(btrim(text), ''::text) IS NOT NULL))),
    CONSTRAINT schueler_notizen_text_oder_entfernt CHECK (((entfernt_am IS NULL) = (text IS NOT NULL)))
);


--
-- Name: schuelerakten; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.schuelerakten WITH (security_invoker='true') AS
 SELECT student_id,
    name,
    klasse,
    schule_id,
    schule,
    akte_seit,
    zustand,
    ruhend_seit,
    letzte_session
   FROM public.akte_basis() akte_basis(student_id, name, klasse, schule_id, schule, akte_seit, zustand, ruhend_seit, letzte_session);


--
-- Name: schul_themenplan; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schul_themenplan (
    schule_id uuid NOT NULL,
    fach text NOT NULL,
    klasse integer NOT NULL,
    "position" integer NOT NULL,
    thema_key text,
    uv_titel text NOT NULL,
    stunden integer,
    halbjahr integer,
    quelle_url text NOT NULL,
    stand text,
    CONSTRAINT schul_themenplan_halbjahr_check CHECK (((halbjahr IS NULL) OR (halbjahr = ANY (ARRAY[1, 2])))),
    CONSTRAINT schul_themenplan_klasse_check CHECK (((klasse >= 5) AND (klasse <= 10))),
    CONSTRAINT schul_themenplan_position_check CHECK (("position" >= 1)),
    CONSTRAINT schul_themenplan_quelle_url_check CHECK ((NULLIF(btrim(quelle_url), ''::text) IS NOT NULL)),
    CONSTRAINT schul_themenplan_stunden_check CHECK (((stunden IS NULL) OR (stunden > 0))),
    CONSTRAINT schul_themenplan_uv_titel_check CHECK ((NULLIF(btrim(uv_titel), ''::text) IS NOT NULL))
);


--
-- Name: schulen; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schulen (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    ort text DEFAULT 'Köln'::text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid,
    schulform text,
    stadtteil text,
    traeger text,
    website text,
    CONSTRAINT schulen_name_nicht_leer CHECK ((NULLIF(btrim(name), ''::text) IS NOT NULL)),
    CONSTRAINT schulen_schulform_check CHECK (((schulform IS NULL) OR (schulform = ANY (ARRAY['Gymnasium'::text, 'Gesamtschule'::text, 'Realschule'::text, 'Hauptschule'::text])))),
    CONSTRAINT schulen_traeger_check CHECK (((traeger IS NULL) OR (traeger = ANY (ARRAY['öffentlich'::text, 'privat'::text]))))
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
    attendance text DEFAULT 'planned'::text NOT NULL,
    CONSTRAINT session_students_attendance_check CHECK ((attendance = ANY (ARRAY['planned'::text, 'present'::text, 'cancelled'::text, 'unexcused'::text, 'cancelled_by_us'::text])))
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
-- Name: skill_pruefung; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skill_pruefung (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    skill_key text NOT NULL,
    frage text NOT NULL,
    erwartung text NOT NULL,
    kriterium text NOT NULL,
    status text DEFAULT 'entwurf'::text NOT NULL,
    quelle text NOT NULL,
    angelegt timestamp with time zone DEFAULT now() NOT NULL,
    aktualisiert timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT skill_pruefung_quelle_check CHECK ((quelle = ANY (ARRAY['ki'::text, 'mensch'::text]))),
    CONSTRAINT skill_pruefung_status_check CHECK ((status = ANY (ARRAY['entwurf'::text, 'geprueft'::text, 'freigegeben'::text])))
);


--
-- Name: skill_thema; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skill_thema (
    skill_key text NOT NULL,
    thema_key text NOT NULL
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
    CONSTRAINT skills_fundament_tiefe_check CHECK (((fundament_tiefe >= 1) AND (fundament_tiefe <= 12)))
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
    schule_id uuid,
    ist_test boolean DEFAULT false NOT NULL,
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
-- Name: task_admin_protokoll; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_admin_protokoll (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    task_id uuid NOT NULL,
    aktion text NOT NULL,
    aenderungen jsonb DEFAULT '[]'::jsonb NOT NULL,
    grund text,
    sammel boolean DEFAULT false NOT NULL,
    von uuid,
    am timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT task_admin_protokoll_aenderungen_check CHECK ((jsonb_typeof(aenderungen) = 'array'::text)),
    CONSTRAINT task_admin_protokoll_aktion_check CHECK ((aktion = ANY (ARRAY['freigeben'::text, 'an_lena'::text, 'zurueckweisen'::text, 'freigabe_zurueck'::text, 'ausschliessen'::text, 'aufnehmen'::text, 'pilot_an'::text, 'pilot_aus'::text, 'fertigkeit'::text, 'afb'::text, 'rueckfrage_freigeben'::text, 'rueckfrage_an_lena'::text, 'rueckfrage_zurueckweisen'::text])))
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
-- Name: task_pruef_ausschluss; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_pruef_ausschluss (
    task_id uuid NOT NULL,
    grund text NOT NULL,
    von uuid,
    am timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT task_pruef_ausschluss_grund_check CHECK ((btrim(grund) <> ''::text))
);


--
-- Name: task_pruefung_ausgang; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_pruefung_ausgang (
    task_id uuid NOT NULL,
    ausgang jsonb NOT NULL,
    erstellt_am timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT task_pruefung_ausgang_ausgang_check CHECK ((jsonb_typeof(ausgang) = 'object'::text))
);


--
-- Name: task_pruefungen; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_pruefungen (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    task_id uuid NOT NULL,
    entscheidung text NOT NULL,
    gruende text[] DEFAULT '{}'::text[] NOT NULL,
    notiz text,
    aenderungen jsonb DEFAULT '[]'::jsonb NOT NULL,
    aenderung_grund text,
    dauer_sek integer,
    geprueft_von uuid,
    geprueft_am timestamp with time zone DEFAULT now() NOT NULL,
    antwort text,
    beantwortet_von uuid,
    beantwortet_am timestamp with time zone,
    CONSTRAINT task_pruefungen_aenderungen_check CHECK ((jsonb_typeof(aenderungen) = 'array'::text)),
    CONSTRAINT task_pruefungen_dauer_sek_check CHECK (((dauer_sek >= 0) AND (dauer_sek <= 86400))),
    CONSTRAINT task_pruefungen_entscheidung_check CHECK ((entscheidung = ANY (ARRAY['passt'::text, 'unsicher'::text, 'passt_nicht'::text, 'zurueckgenommen'::text])))
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
    CONSTRAINT task_reviews_kategorie_check CHECK ((kategorie = ANY (ARRAY['fehlbild_falsch'::text, 'fehlbild_unrealistisch'::text, 'zahlen_unguenstig'::text, 'formulierung'::text, 'didaktisch'::text, 'kontext'::text, 'loesung_passt_nicht'::text, 'aufgabe_fehlerhaft'::text, 'aufgabe_unklar'::text, 'bild_falsch'::text, 'sprache_zu_schwer'::text, 'tablet_umbauen'::text, 'passt_nicht_in_lsa'::text, 'sonstiges'::text])))
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
-- Name: thema_einstieg; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.thema_einstieg (
    thema_key text NOT NULL,
    skill_key text NOT NULL
);


--
-- Name: themen; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.themen (
    thema_key text NOT NULL,
    fach text NOT NULL,
    klasse integer NOT NULL,
    label text,
    stufe text NOT NULL,
    schlagworte text[] DEFAULT '{}'::text[] NOT NULL,
    klp text[] DEFAULT '{}'::text[] NOT NULL,
    sort integer,
    CONSTRAINT themen_stufe_check CHECK ((stufe = ANY (ARRAY['erprobung'::text, 'erste'::text, 'zweite'::text])))
);


--
-- Name: tier_laufzeiten; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tier_laufzeiten (
    tier_id uuid NOT NULL,
    laufzeit_monate integer NOT NULL,
    preis_cents integer NOT NULL,
    einheiten integer NOT NULL,
    CONSTRAINT tier_laufzeiten_einheiten_check CHECK ((einheiten > 0)),
    CONSTRAINT tier_laufzeiten_laufzeit_check CHECK ((laufzeit_monate = ANY (ARRAY[6, 12]))),
    CONSTRAINT tier_laufzeiten_preis_check CHECK ((preis_cents > 0))
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
-- Name: vertrag_mandat_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vertrag_mandat_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vertraege; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vertraege (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid,
    lead_id uuid NOT NULL,
    status text DEFAULT 'in_vorbereitung'::text NOT NULL,
    in_vorbereitung_at timestamp with time zone DEFAULT now() NOT NULL,
    unterschrift_ausstehend_at timestamp with time zone,
    abgeschlossen_at timestamp with time zone,
    abgelehnt_at timestamp with time zone,
    abgelehnt_grund text,
    abgelehnt_notiz text,
    abschluss_weg text,
    unterschrieben_am date,
    eltern_vorname text,
    eltern_nachname text,
    strasse text,
    hausnummer text,
    plz text,
    ort text,
    eltern_telefon text,
    eltern_email text,
    kind_vorname text,
    kind_nachname text,
    kind_geburtsdatum date,
    klasse integer,
    fach text,
    schule text,
    laufzeit_monate integer,
    tier_id uuid,
    preis_cents integer,
    vertragsbeginn date,
    kontoinhaber text,
    iban_masked text,
    mandatsreferenz text DEFAULT ((('EDV-'::text || to_char((now() AT TIME ZONE 'Europe/Berlin'::text), 'YYYY'::text)) || '-'::text) || lpad((nextval('public.vertrag_mandat_seq'::regclass))::text, 6, '0'::text)) NOT NULL,
    glaeubiger_id text,
    einheiten integer,
    student_id uuid,
    schule_id uuid,
    vorgaenger_id uuid,
    vertrag_status text,
    abgeschlossen_am date,
    eingang_datum date,
    vertrag_ende date,
    ferientage integer,
    widerruf_bis date,
    widerrufen_am date,
    gekuendigt_zum date,
    kuendigung_grund text,
    zahlungsstatus text DEFAULT 'in_ordnung'::text NOT NULL,
    zahlungsstatus_seit date,
    offener_betrag_cents integer,
    verlaengerung_status text,
    verlaengerung_grund text,
    wiedervorlage_am date,
    rueckmeldung_bis date,
    abweichung_vermerk text,
    zugangscode text,
    zugangscode_erzeugt_am date,
    zugangscode_gesperrt_am date,
    scan_pfad text,
    CONSTRAINT vertraege_abgelehnt_grund_check CHECK (((abgelehnt_grund IS NULL) OR (abgelehnt_grund = ANY (ARRAY['preis'::text, 'zeit'::text, 'anderer_anbieter'::text, 'kein_bedarf'::text, 'kein_kontakt'::text, 'sonstiges'::text])))),
    CONSTRAINT vertraege_abgelehnt_notiz_check CHECK (((abgelehnt_grund IS DISTINCT FROM 'sonstiges'::text) OR (NULLIF(btrim(abgelehnt_notiz), ''::text) IS NOT NULL))),
    CONSTRAINT vertraege_abschluss_weg_check CHECK (((abschluss_weg IS NULL) OR (abschluss_weg = ANY (ARRAY['vor_ort'::text, 'papier'::text])))),
    CONSTRAINT vertraege_beginn_monatserster CHECK (((vertragsbeginn IS NULL) OR (EXTRACT(day FROM vertragsbeginn) = (1)::numeric))),
    CONSTRAINT vertraege_ende_nach_beginn CHECK (((vertrag_ende IS NULL) OR (vertragsbeginn IS NULL) OR (vertrag_ende > vertragsbeginn))),
    CONSTRAINT vertraege_ferientage_nicht_negativ CHECK (((ferientage IS NULL) OR (ferientage >= 0))),
    CONSTRAINT vertraege_gekuendigt_braucht_datum_und_grund CHECK (((vertrag_status IS DISTINCT FROM 'gekuendigt'::text) OR ((gekuendigt_zum IS NOT NULL) AND (NULLIF(btrim(kuendigung_grund), ''::text) IS NOT NULL)))),
    CONSTRAINT vertraege_keine_verlaengerung_braucht_grund CHECK (((verlaengerung_status IS DISTINCT FROM 'keine_verlaengerung'::text) OR (NULLIF(btrim(verlaengerung_grund), ''::text) IS NOT NULL))),
    CONSTRAINT vertraege_klasse_check CHECK (((klasse IS NULL) OR ((klasse >= 5) AND (klasse <= 13)))),
    CONSTRAINT vertraege_laufzeit_check CHECK (((laufzeit_monate IS NULL) OR (laufzeit_monate = ANY (ARRAY[6, 12])))),
    CONSTRAINT vertraege_offener_betrag_nicht_negativ CHECK (((offener_betrag_cents IS NULL) OR (offener_betrag_cents >= 0))),
    CONSTRAINT vertraege_scan_bei_papier CHECK (((status <> 'abgeschlossen'::text) OR (abschluss_weg IS DISTINCT FROM 'papier'::text) OR (NULLIF(btrim(scan_pfad), ''::text) IS NOT NULL))),
    CONSTRAINT vertraege_status_check CHECK ((status = ANY (ARRAY['in_vorbereitung'::text, 'unterschrift_ausstehend'::text, 'abgeschlossen'::text, 'abgelehnt'::text]))),
    CONSTRAINT vertraege_verlaengerung_status_check CHECK (((verlaengerung_status IS NULL) OR (verlaengerung_status = ANY (ARRAY['offen'::text, 'kontaktiert'::text, 'gespraech_vereinbart'::text, 'verlaengert'::text, 'keine_verlaengerung'::text])))),
    CONSTRAINT vertraege_vertrag_status_check CHECK (((vertrag_status IS NULL) OR (vertrag_status = ANY (ARRAY['im_widerruf'::text, 'aktiv'::text, 'gekuendigt'::text, 'ausgelaufen'::text, 'widerrufen'::text])))),
    CONSTRAINT vertraege_vertrag_status_nach_abschluss CHECK (((status = 'abgeschlossen'::text) = (vertrag_status IS NOT NULL))),
    CONSTRAINT vertraege_vorgaenger_nicht_selbst CHECK (((vorgaenger_id IS NULL) OR (vorgaenger_id <> id))),
    CONSTRAINT vertraege_widerruf_nach_beginn CHECK (((widerruf_bis IS NULL) OR (vertragsbeginn IS NULL) OR (widerruf_bis >= vertragsbeginn))),
    CONSTRAINT vertraege_widerrufen_braucht_datum CHECK (((vertrag_status IS DISTINCT FROM 'widerrufen'::text) OR (widerrufen_am IS NOT NULL))),
    CONSTRAINT vertraege_zahlungsstatus_braucht_datum CHECK (((zahlungsstatus = 'in_ordnung'::text) OR (zahlungsstatus_seit IS NOT NULL))),
    CONSTRAINT vertraege_zahlungsstatus_check CHECK ((zahlungsstatus = ANY (ARRAY['in_ordnung'::text, 'zahlung_offen'::text, 'mahnung_1'::text, 'mahnung_2'::text, 'inkasso'::text]))),
    CONSTRAINT vertraege_zugangscode_form CHECK (((zugangscode IS NULL) OR (zugangscode ~ '^EDV-[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{4}-[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{4}$'::text))),
    CONSTRAINT vertraege_zugangscode_sperre_braucht_code CHECK (((zugangscode_gesperrt_am IS NULL) OR (zugangscode IS NOT NULL)))
);


--
-- Name: vertraege_aktuell; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vertraege_aktuell WITH (security_invoker='true') AS
 WITH basis AS (
         SELECT v.id,
            v.created_at,
            v.updated_at,
            v.created_by,
            v.lead_id,
            v.status,
            v.in_vorbereitung_at,
            v.unterschrift_ausstehend_at,
            v.abgeschlossen_at,
            v.abgelehnt_at,
            v.abgelehnt_grund,
            v.abgelehnt_notiz,
            v.abschluss_weg,
            v.unterschrieben_am,
            v.eltern_vorname,
            v.eltern_nachname,
            v.strasse,
            v.hausnummer,
            v.plz,
            v.ort,
            v.eltern_telefon,
            v.eltern_email,
            v.kind_vorname,
            v.kind_nachname,
            v.kind_geburtsdatum,
            v.klasse,
            v.fach,
            v.schule,
            v.laufzeit_monate,
            v.tier_id,
            v.preis_cents,
            v.vertragsbeginn,
            v.kontoinhaber,
            v.iban_masked,
            v.mandatsreferenz,
            v.glaeubiger_id,
            v.einheiten,
            v.student_id,
            v.schule_id,
            v.vorgaenger_id,
            v.vertrag_status,
            v.abgeschlossen_am,
            v.eingang_datum,
            v.vertrag_ende,
            v.ferientage,
            v.widerruf_bis,
            v.widerrufen_am,
            v.gekuendigt_zum,
            v.kuendigung_grund,
            v.zahlungsstatus,
            v.zahlungsstatus_seit,
            v.offener_betrag_cents,
            v.verlaengerung_status,
            v.verlaengerung_grund,
            v.wiedervorlage_am,
            v.rueckmeldung_bis,
            v.abweichung_vermerk,
            v.zugangscode,
            v.zugangscode_erzeugt_am,
            v.zugangscode_gesperrt_am,
            v.scan_pfad,
            public.vertrag_wirksamer_status(v.widerrufen_am, v.gekuendigt_zum, v.vertrag_ende, v.widerruf_bis) AS wirksamer_status,
                CASE
                    WHEN ((v.vertragsbeginn IS NULL) OR (CURRENT_DATE < v.vertragsbeginn)) THEN NULL::integer
                    ELSE ((1 + (((EXTRACT(year FROM CURRENT_DATE))::integer * 12) + (EXTRACT(month FROM CURRENT_DATE))::integer)) - (((EXTRACT(year FROM v.vertragsbeginn))::integer * 12) + (EXTRACT(month FROM v.vertragsbeginn))::integer))
                END AS laufzeit_monat
           FROM public.vertraege v
          WHERE (v.status = 'abgeschlossen'::text)
        )
 SELECT id,
    created_at,
    updated_at,
    created_by,
    lead_id,
    status,
    in_vorbereitung_at,
    unterschrift_ausstehend_at,
    abgeschlossen_at,
    abgelehnt_at,
    abgelehnt_grund,
    abgelehnt_notiz,
    abschluss_weg,
    unterschrieben_am,
    eltern_vorname,
    eltern_nachname,
    strasse,
    hausnummer,
    plz,
    ort,
    eltern_telefon,
    eltern_email,
    kind_vorname,
    kind_nachname,
    kind_geburtsdatum,
    klasse,
    fach,
    schule,
    laufzeit_monate,
    tier_id,
    preis_cents,
    vertragsbeginn,
    kontoinhaber,
    iban_masked,
    mandatsreferenz,
    glaeubiger_id,
    einheiten,
    student_id,
    schule_id,
    vorgaenger_id,
    vertrag_status,
    abgeschlossen_am,
    eingang_datum,
    vertrag_ende,
    ferientage,
    widerruf_bis,
    widerrufen_am,
    gekuendigt_zum,
    kuendigung_grund,
    zahlungsstatus,
    zahlungsstatus_seit,
    offener_betrag_cents,
    verlaengerung_status,
    verlaengerung_grund,
    wiedervorlage_am,
    rueckmeldung_bis,
    abweichung_vermerk,
    zugangscode,
    zugangscode_erzeugt_am,
    zugangscode_gesperrt_am,
    scan_pfad,
    wirksamer_status,
    laufzeit_monat,
    (row_number() OVER (PARTITION BY COALESCE(student_id, id) ORDER BY vertragsbeginn DESC NULLS LAST, abgeschlossen_am DESC NULLS LAST, created_at DESC) = 1) AS ist_aktueller_vertrag,
        CASE
            WHEN ((preis_cents IS NULL) OR (laufzeit_monat IS NULL) OR (laufzeit_monate IS NULL)) THEN 0
            WHEN ((laufzeit_monat >= 1) AND (laufzeit_monat <= laufzeit_monate)) THEN preis_cents
            ELSE 0
        END AS beitrag_diesen_monat_cents,
    ((zugangscode IS NOT NULL) AND (zugangscode_gesperrt_am IS NULL) AND (wirksamer_status = ANY (ARRAY['im_widerruf'::text, 'aktiv'::text]))) AS zugangscode_gueltig,
    (vertrag_ende - CURRENT_DATE) AS endet_in_tagen
   FROM basis b;


--
-- Name: vertrag_bankdaten; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vertrag_bankdaten (
    vertrag_id uuid NOT NULL,
    iban text NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT vertrag_bankdaten_iban_check CHECK ((iban ~ '^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$'::text))
);


--
-- Name: vertrag_dateien; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vertrag_dateien (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    vertrag_id uuid NOT NULL,
    art text NOT NULL,
    pfad text NOT NULL,
    sha256 text NOT NULL,
    bytes integer,
    erzeugt_am timestamp with time zone DEFAULT now() NOT NULL,
    erzeugt_von uuid,
    CONSTRAINT vertrag_dateien_art_check CHECK ((art = ANY (ARRAY['vertrag'::text, 'unterschrift'::text, 'unterlagen_versand'::text, 'sepa_mandat'::text]))),
    CONSTRAINT vertrag_dateien_bytes_check CHECK (((bytes IS NULL) OR (bytes > 0))),
    CONSTRAINT vertrag_dateien_pfad_check CHECK ((NULLIF(btrim(pfad), ''::text) IS NOT NULL)),
    CONSTRAINT vertrag_dateien_sha256_check CHECK ((sha256 ~ '^[0-9a-f]{64}$'::text))
);


--
-- Name: vertrag_dokumente; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vertrag_dokumente (
    schluessel text NOT NULL,
    version text NOT NULL,
    titel text NOT NULL,
    pflicht boolean NOT NULL,
    aktiv boolean DEFAULT true NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL
);


--
-- Name: vertrag_einstellungen; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vertrag_einstellungen (
    id boolean DEFAULT true NOT NULL,
    glaeubiger_id text,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT vertrag_einstellungen_id_check CHECK (id)
);


--
-- Name: vertrag_unterschriften; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vertrag_unterschriften (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    vertrag_id uuid NOT NULL,
    art text NOT NULL,
    signatur text NOT NULL,
    unterschrieben_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT vertrag_unterschriften_art_check CHECK ((art = ANY (ARRAY['vertrag'::text, 'sepa_mandat'::text])))
);


--
-- Name: vertrag_versand; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vertrag_versand (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    vertrag_id uuid NOT NULL,
    weg text NOT NULL,
    anlass text NOT NULL,
    empfaenger text,
    erfolgt_at timestamp with time zone DEFAULT now() NOT NULL,
    erfolgt_von uuid,
    anhaenge jsonb,
    fehler text,
    CONSTRAINT vertrag_versand_anlass_check CHECK ((anlass = ANY (ARRAY['unterlagen'::text, 'bestaetigung'::text, 'zugangscode'::text]))),
    CONSTRAINT vertrag_versand_weg_check CHECK ((weg = ANY (ARRAY['email'::text, 'druck'::text])))
);


--
-- Name: vertrag_zustimmungen; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vertrag_zustimmungen (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    vertrag_id uuid NOT NULL,
    dokument_schluessel text NOT NULL,
    dokument_version text NOT NULL,
    akzeptiert_at timestamp with time zone NOT NULL,
    erfasst_von uuid
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
    reason text,
    buchungs_schluessel text
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
-- Name: akte_einstellungen akte_einstellungen_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.akte_einstellungen
    ADD CONSTRAINT akte_einstellungen_pkey PRIMARY KEY (id);


--
-- Name: akte_wortliste akte_wortliste_eindeutig; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.akte_wortliste
    ADD CONSTRAINT akte_wortliste_eindeutig UNIQUE (liste, wort);


--
-- Name: akte_wortliste akte_wortliste_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.akte_wortliste
    ADD CONSTRAINT akte_wortliste_pkey PRIMARY KEY (id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


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
-- Name: dokument_fassungen dokument_fassungen_pfad_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dokument_fassungen
    ADD CONSTRAINT dokument_fassungen_pfad_uniq UNIQUE (pfad);


--
-- Name: dokument_fassungen dokument_fassungen_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dokument_fassungen
    ADD CONSTRAINT dokument_fassungen_pkey PRIMARY KEY (art, fassung);


--
-- Name: eltern_reports eltern_reports_nr_je_kind; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eltern_reports
    ADD CONSTRAINT eltern_reports_nr_je_kind UNIQUE (student_id, nr);


--
-- Name: eltern_reports eltern_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eltern_reports
    ADD CONSTRAINT eltern_reports_pkey PRIMARY KEY (id);


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
-- Name: feiertage_nrw feiertage_nrw_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feiertage_nrw
    ADD CONSTRAINT feiertage_nrw_pkey PRIMARY KEY (datum);


--
-- Name: ferien_nrw ferien_nrw_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ferien_nrw
    ADD CONSTRAINT ferien_nrw_pkey PRIMARY KEY (id);


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
-- Name: lead_mail_versand lead_mail_versand_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lead_mail_versand
    ADD CONSTRAINT lead_mail_versand_pkey PRIMARY KEY (id);


--
-- Name: lead_themen lead_themen_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lead_themen
    ADD CONSTRAINT lead_themen_pkey PRIMARY KEY (lead_id, thema_key);


--
-- Name: leads leads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_pkey PRIMARY KEY (id);


--
-- Name: lernpfad_belege lernpfad_belege_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lernpfad_belege
    ADD CONSTRAINT lernpfad_belege_pkey PRIMARY KEY (id);


--
-- Name: lernpfad lernpfad_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lernpfad
    ADD CONSTRAINT lernpfad_pkey PRIMARY KEY (id);


--
-- Name: lernpfad_protokoll lernpfad_protokoll_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lernpfad_protokoll
    ADD CONSTRAINT lernpfad_protokoll_pkey PRIMARY KEY (id);


--
-- Name: lernpfad lernpfad_student_skill_uq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lernpfad
    ADD CONSTRAINT lernpfad_student_skill_uq UNIQUE (student_id, skill_key);


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
-- Name: pruef_einstellungen pruef_einstellungen_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pruef_einstellungen
    ADD CONSTRAINT pruef_einstellungen_pkey PRIMARY KEY (id);


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
-- Name: schueler_notizen schueler_notizen_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schueler_notizen
    ADD CONSTRAINT schueler_notizen_pkey PRIMARY KEY (id);


--
-- Name: schul_themenplan schul_themenplan_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schul_themenplan
    ADD CONSTRAINT schul_themenplan_uniq UNIQUE (schule_id, fach, klasse, "position");


--
-- Name: schulen schulen_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schulen
    ADD CONSTRAINT schulen_pkey PRIMARY KEY (id);


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
-- Name: skill_pruefung skill_pruefung_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_pruefung
    ADD CONSTRAINT skill_pruefung_pkey PRIMARY KEY (id);


--
-- Name: skill_thema skill_thema_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_thema
    ADD CONSTRAINT skill_thema_pkey PRIMARY KEY (skill_key);


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
-- Name: task_admin_protokoll task_admin_protokoll_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_admin_protokoll
    ADD CONSTRAINT task_admin_protokoll_pkey PRIMARY KEY (id);


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
-- Name: task_pruef_ausschluss task_pruef_ausschluss_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_pruef_ausschluss
    ADD CONSTRAINT task_pruef_ausschluss_pkey PRIMARY KEY (task_id);


--
-- Name: task_pruefung_ausgang task_pruefung_ausgang_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_pruefung_ausgang
    ADD CONSTRAINT task_pruefung_ausgang_pkey PRIMARY KEY (task_id);


--
-- Name: task_pruefungen task_pruefungen_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_pruefungen
    ADD CONSTRAINT task_pruefungen_pkey PRIMARY KEY (id);


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
-- Name: thema_einstieg thema_einstieg_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.thema_einstieg
    ADD CONSTRAINT thema_einstieg_pkey PRIMARY KEY (thema_key, skill_key);


--
-- Name: themen themen_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.themen
    ADD CONSTRAINT themen_pkey PRIMARY KEY (thema_key);


--
-- Name: tier_laufzeiten tier_laufzeiten_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tier_laufzeiten
    ADD CONSTRAINT tier_laufzeiten_pkey PRIMARY KEY (tier_id, laufzeit_monate);


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
-- Name: vertraege vertraege_mandatsreferenz_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertraege
    ADD CONSTRAINT vertraege_mandatsreferenz_key UNIQUE (mandatsreferenz);


--
-- Name: vertraege vertraege_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertraege
    ADD CONSTRAINT vertraege_pkey PRIMARY KEY (id);


--
-- Name: vertraege vertraege_zugangscode_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertraege
    ADD CONSTRAINT vertraege_zugangscode_uniq UNIQUE (zugangscode);


--
-- Name: vertrag_bankdaten vertrag_bankdaten_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertrag_bankdaten
    ADD CONSTRAINT vertrag_bankdaten_pkey PRIMARY KEY (vertrag_id);


--
-- Name: vertrag_dateien vertrag_dateien_art_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertrag_dateien
    ADD CONSTRAINT vertrag_dateien_art_uniq UNIQUE (vertrag_id, art);


--
-- Name: vertrag_dateien vertrag_dateien_pfad_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertrag_dateien
    ADD CONSTRAINT vertrag_dateien_pfad_uniq UNIQUE (pfad);


--
-- Name: vertrag_dateien vertrag_dateien_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertrag_dateien
    ADD CONSTRAINT vertrag_dateien_pkey PRIMARY KEY (id);


--
-- Name: vertrag_dokumente vertrag_dokumente_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertrag_dokumente
    ADD CONSTRAINT vertrag_dokumente_pkey PRIMARY KEY (schluessel, version);


--
-- Name: vertrag_einstellungen vertrag_einstellungen_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertrag_einstellungen
    ADD CONSTRAINT vertrag_einstellungen_pkey PRIMARY KEY (id);


--
-- Name: vertrag_unterschriften vertrag_unterschriften_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertrag_unterschriften
    ADD CONSTRAINT vertrag_unterschriften_pkey PRIMARY KEY (id);


--
-- Name: vertrag_unterschriften vertrag_unterschriften_vertrag_id_art_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertrag_unterschriften
    ADD CONSTRAINT vertrag_unterschriften_vertrag_id_art_key UNIQUE (vertrag_id, art);


--
-- Name: vertrag_versand vertrag_versand_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertrag_versand
    ADD CONSTRAINT vertrag_versand_pkey PRIMARY KEY (id);


--
-- Name: vertrag_zustimmungen vertrag_zustimmungen_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertrag_zustimmungen
    ADD CONSTRAINT vertrag_zustimmungen_pkey PRIMARY KEY (id);


--
-- Name: vertrag_zustimmungen vertrag_zustimmungen_vertrag_id_dokument_schluessel_dokumen_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertrag_zustimmungen
    ADD CONSTRAINT vertrag_zustimmungen_vertrag_id_dokument_schluessel_dokumen_key UNIQUE (vertrag_id, dokument_schluessel, dokument_version);


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
-- Name: audit_log_actor_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_log_actor_idx ON public.audit_log USING btree (actor, created_at DESC);


--
-- Name: audit_log_objekt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_log_objekt_idx ON public.audit_log USING btree (objekt_typ, objekt_id, created_at DESC);


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
-- Name: eltern_reports_lsa_einmal; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX eltern_reports_lsa_einmal ON public.eltern_reports USING btree (lsa_session_id) WHERE (lsa_session_id IS NOT NULL);


--
-- Name: ferien_nrw_bis_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ferien_nrw_bis_idx ON public.ferien_nrw USING btree (bis);


--
-- Name: ferien_nrw_von_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ferien_nrw_von_idx ON public.ferien_nrw USING btree (von);


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
-- Name: lead_mail_versand_lead_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX lead_mail_versand_lead_idx ON public.lead_mail_versand USING btree (lead_id, erfolgt_at DESC);


--
-- Name: lead_themen_ein_aktuelles; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX lead_themen_ein_aktuelles ON public.lead_themen USING btree (lead_id, fach) WHERE (status = 'aktuell'::text);


--
-- Name: lead_themen_thema_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX lead_themen_thema_idx ON public.lead_themen USING btree (thema_key);


--
-- Name: leads_owner_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX leads_owner_idx ON public.leads USING btree (owner_id);


--
-- Name: leads_schule_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX leads_schule_idx ON public.leads USING btree (schule_id);


--
-- Name: leads_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX leads_status_idx ON public.leads USING btree (status);


--
-- Name: lernpfad_belege_student_skill_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX lernpfad_belege_student_skill_idx ON public.lernpfad_belege USING btree (student_id, skill_key);


--
-- Name: lernpfad_protokoll_student_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX lernpfad_protokoll_student_idx ON public.lernpfad_protokoll USING btree (student_id, am);


--
-- Name: lernpfad_student_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX lernpfad_student_idx ON public.lernpfad USING btree (student_id);


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
-- Name: schueler_notizen_student_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX schueler_notizen_student_idx ON public.schueler_notizen USING btree (student_id, created_at DESC);


--
-- Name: schul_themenplan_thema_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX schul_themenplan_thema_idx ON public.schul_themenplan USING btree (thema_key);


--
-- Name: schulen_name_ort_uniq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX schulen_name_ort_uniq ON public.schulen USING btree (lower(name), COALESCE(ort, ''::text));


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
-- Name: skill_pruefung_skill_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX skill_pruefung_skill_idx ON public.skill_pruefung USING btree (skill_key);


--
-- Name: skill_thema_thema_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX skill_thema_thema_idx ON public.skill_thema USING btree (thema_key);


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
-- Name: students_schule_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX students_schule_idx ON public.students USING btree (schule_id);


--
-- Name: task_admin_protokoll_task_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX task_admin_protokoll_task_idx ON public.task_admin_protokoll USING btree (task_id, am DESC);


--
-- Name: task_pruefungen_task_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX task_pruefungen_task_idx ON public.task_pruefungen USING btree (task_id, geprueft_am DESC);


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
-- Name: thema_einstieg_skill_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX thema_einstieg_skill_idx ON public.thema_einstieg USING btree (skill_key);


--
-- Name: vertraege_lead_offen_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX vertraege_lead_offen_idx ON public.vertraege USING btree (lead_id) WHERE (status = ANY (ARRAY['in_vorbereitung'::text, 'unterschrift_ausstehend'::text]));


--
-- Name: vertraege_schule_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX vertraege_schule_idx ON public.vertraege USING btree (schule_id);


--
-- Name: vertraege_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX vertraege_status_idx ON public.vertraege USING btree (status);


--
-- Name: vertraege_student_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX vertraege_student_idx ON public.vertraege USING btree (student_id);


--
-- Name: vertraege_student_laufend_uniq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX vertraege_student_laufend_uniq ON public.vertraege USING btree (student_id) WHERE ((student_id IS NOT NULL) AND (vertrag_status = ANY (ARRAY['im_widerruf'::text, 'aktiv'::text])) AND (verlaengerung_status IS DISTINCT FROM 'verlaengert'::text));


--
-- Name: vertraege_vorgaenger_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX vertraege_vorgaenger_idx ON public.vertraege USING btree (vorgaenger_id);


--
-- Name: vertraege_wiedervorlage_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX vertraege_wiedervorlage_idx ON public.vertraege USING btree (wiedervorlage_am) WHERE (wiedervorlage_am IS NOT NULL);


--
-- Name: vertrag_dokumente_aktiv_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX vertrag_dokumente_aktiv_idx ON public.vertrag_dokumente USING btree (schluessel) WHERE aktiv;


--
-- Name: vertrag_versand_vertrag_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX vertrag_versand_vertrag_idx ON public.vertrag_versand USING btree (vertrag_id);


--
-- Name: xp_events_buchungs_schluessel_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX xp_events_buchungs_schluessel_key ON public.xp_events USING btree (student_id, buchungs_schluessel);


--
-- Name: xp_events_student_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX xp_events_student_idx ON public.xp_events USING btree (student_id);


--
-- Name: coaching_sessions coaching_sessions_testlauf_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER coaching_sessions_testlauf_trg BEFORE INSERT OR UPDATE OF testlauf ON public.coaching_sessions FOR EACH ROW EXECUTE FUNCTION public.coaching_sessions_testlauf_pruefen();


--
-- Name: coaching_sessions coaching_sessions_verschieben_zugang_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER coaching_sessions_verschieben_zugang_trg BEFORE UPDATE OF scheduled_at ON public.coaching_sessions FOR EACH ROW EXECUTE FUNCTION public.session_verschieben_zugang_pruefen();


--
-- Name: eltern_reports eltern_reports_guard_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER eltern_reports_guard_trg BEFORE UPDATE ON public.eltern_reports FOR EACH ROW EXECUTE FUNCTION public.eltern_reports_guard();


--
-- Name: leads leads_ist_test_schuetzen_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER leads_ist_test_schuetzen_trg BEFORE UPDATE OF ist_test ON public.leads FOR EACH ROW EXECUTE FUNCTION public.ist_test_schuetzen();


--
-- Name: leads leads_status_zeitstempel_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER leads_status_zeitstempel_trg BEFORE UPDATE ON public.leads FOR EACH ROW EXECUTE FUNCTION public.leads_status_zeitstempel();


--
-- Name: lsa_sessions lsa_session_lead_fertig_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER lsa_session_lead_fertig_trg AFTER UPDATE OF status ON public.lsa_sessions FOR EACH ROW WHEN (((new.status = 'completed'::text) AND (old.status IS DISTINCT FROM new.status))) EXECUTE FUNCTION public.lsa_session_lead_fertig();


--
-- Name: lsa_sessions lsa_session_platz_release_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER lsa_session_platz_release_trg AFTER UPDATE OF status ON public.lsa_sessions FOR EACH ROW WHEN (((new.status = ANY (ARRAY['completed'::text, 'aborted'::text])) AND (old.status IS DISTINCT FROM new.status))) EXECUTE FUNCTION public.lsa_session_platz_release();


--
-- Name: lsa_sessions lsa_sessions_testlauf_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER lsa_sessions_testlauf_trg BEFORE INSERT OR UPDATE OF testlauf, student_id ON public.lsa_sessions FOR EACH ROW EXECUTE FUNCTION public.lsa_sessions_testlauf_pruefen();


--
-- Name: schueler_notizen schueler_notizen_guard_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER schueler_notizen_guard_trg BEFORE UPDATE ON public.schueler_notizen FOR EACH ROW EXECUTE FUNCTION public.schueler_notizen_guard();


--
-- Name: session_students session_students_testlauf_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER session_students_testlauf_trg BEFORE INSERT OR UPDATE OF student_id, session_id ON public.session_students FOR EACH ROW EXECUTE FUNCTION public.session_students_testlauf_pruefen();


--
-- Name: session_students session_students_zugang_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER session_students_zugang_trg BEFORE INSERT OR UPDATE OF student_id, session_id ON public.session_students FOR EACH ROW EXECUTE FUNCTION public.session_platz_zugang_pruefen();


--
-- Name: skill_kante skill_kante_tiefe; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER skill_kante_tiefe AFTER INSERT OR UPDATE ON public.skill_kante DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.skill_kante_tiefe_guard();


--
-- Name: students students_guard_provisional_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER students_guard_provisional_trg BEFORE INSERT OR UPDATE OF is_provisional ON public.students FOR EACH ROW EXECUTE FUNCTION public.students_guard_provisional();


--
-- Name: students students_ist_test_erben_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER students_ist_test_erben_trg BEFORE INSERT ON public.students FOR EACH ROW EXECUTE FUNCTION public.students_ist_test_erben();


--
-- Name: students students_ist_test_schuetzen_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER students_ist_test_schuetzen_trg BEFORE UPDATE OF ist_test ON public.students FOR EACH ROW EXECUTE FUNCTION public.ist_test_schuetzen();


--
-- Name: student_subscriptions subscriptions_guard_provisional_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER subscriptions_guard_provisional_trg BEFORE INSERT OR UPDATE OF student_id ON public.student_subscriptions FOR EACH ROW EXECUTE FUNCTION public.subscriptions_guard_provisional();


--
-- Name: task_pruefungen task_pruefungen_nur_anhaengen; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER task_pruefungen_nur_anhaengen BEFORE UPDATE ON public.task_pruefungen FOR EACH ROW EXECUTE FUNCTION public.task_pruefungen_nur_anhaengen();


--
-- Name: task_solutions task_solutions_pruef_version; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER task_solutions_pruef_version AFTER INSERT OR UPDATE ON public.task_solutions FOR EACH ROW EXECUTE FUNCTION public.task_solutions_pruef_version();


--
-- Name: task_solutions task_solutions_term_acceptance; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER task_solutions_term_acceptance BEFORE INSERT OR UPDATE OF acceptance, task_id ON public.task_solutions FOR EACH ROW EXECUTE FUNCTION public.lsa_term_acceptance_guard();


--
-- Name: task_solutions task_solutions_zahlen_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER task_solutions_zahlen_guard BEFORE UPDATE OF correct_answers, acceptance ON public.task_solutions FOR EACH ROW EXECUTE FUNCTION public.task_solutions_zahlen_guard();


--
-- Name: tasks tasks_pruef_version; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tasks_pruef_version BEFORE UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.tasks_pruef_version();


--
-- Name: tasks tasks_pruefer_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tasks_pruefer_guard BEFORE UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.tasks_pruefer_guard();


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
-- Name: vertraege vertraege_guard_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER vertraege_guard_trg BEFORE UPDATE ON public.vertraege FOR EACH ROW EXECUTE FUNCTION public.vertraege_guard();


--
-- Name: vertrag_bankdaten vertrag_bankdaten_maskieren_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER vertrag_bankdaten_maskieren_trg AFTER INSERT OR UPDATE OF iban ON public.vertrag_bankdaten FOR EACH ROW EXECUTE FUNCTION public.vertrag_bankdaten_maskieren();


--
-- Name: xp_events xp_events_apply; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER xp_events_apply AFTER INSERT ON public.xp_events FOR EACH ROW EXECUTE FUNCTION public.apply_xp_event();


--
-- Name: akte_wortliste akte_wortliste_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.akte_wortliste
    ADD CONSTRAINT akte_wortliste_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: audit_log audit_log_actor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_actor_fkey FOREIGN KEY (actor) REFERENCES public.profiles(id) ON DELETE SET NULL;


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
-- Name: dokument_fassungen dokument_fassungen_erzeugt_von_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dokument_fassungen
    ADD CONSTRAINT dokument_fassungen_erzeugt_von_fkey FOREIGN KEY (erzeugt_von) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: eltern_reports eltern_reports_freigegeben_von_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eltern_reports
    ADD CONSTRAINT eltern_reports_freigegeben_von_fkey FOREIGN KEY (freigegeben_von) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: eltern_reports eltern_reports_lsa_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eltern_reports
    ADD CONSTRAINT eltern_reports_lsa_session_id_fkey FOREIGN KEY (lsa_session_id) REFERENCES public.lsa_sessions(id);


--
-- Name: eltern_reports eltern_reports_parent_report_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eltern_reports
    ADD CONSTRAINT eltern_reports_parent_report_id_fkey FOREIGN KEY (parent_report_id) REFERENCES public.parent_reports(id);


--
-- Name: eltern_reports eltern_reports_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eltern_reports
    ADD CONSTRAINT eltern_reports_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


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
-- Name: lead_mail_versand lead_mail_versand_erfolgt_von_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lead_mail_versand
    ADD CONSTRAINT lead_mail_versand_erfolgt_von_fkey FOREIGN KEY (erfolgt_von) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: lead_mail_versand lead_mail_versand_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lead_mail_versand
    ADD CONSTRAINT lead_mail_versand_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- Name: lead_themen lead_themen_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lead_themen
    ADD CONSTRAINT lead_themen_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- Name: lead_themen lead_themen_thema_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lead_themen
    ADD CONSTRAINT lead_themen_thema_key_fkey FOREIGN KEY (thema_key) REFERENCES public.themen(thema_key);


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
-- Name: leads leads_schule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_schule_id_fkey FOREIGN KEY (schule_id) REFERENCES public.schulen(id) ON DELETE SET NULL;


--
-- Name: lernpfad_belege lernpfad_belege_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lernpfad_belege
    ADD CONSTRAINT lernpfad_belege_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.coaching_sessions(id) ON DELETE RESTRICT;


--
-- Name: lernpfad_belege lernpfad_belege_skill_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lernpfad_belege
    ADD CONSTRAINT lernpfad_belege_skill_key_fkey FOREIGN KEY (skill_key) REFERENCES public.skills(skill_key);


--
-- Name: lernpfad_belege lernpfad_belege_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lernpfad_belege
    ADD CONSTRAINT lernpfad_belege_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: lernpfad lernpfad_coach_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lernpfad
    ADD CONSTRAINT lernpfad_coach_session_id_fkey FOREIGN KEY (coach_session_id) REFERENCES public.coaching_sessions(id) ON DELETE SET NULL;


--
-- Name: lernpfad lernpfad_coach_von_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lernpfad
    ADD CONSTRAINT lernpfad_coach_von_fkey FOREIGN KEY (coach_von) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: lernpfad lernpfad_letzte_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lernpfad
    ADD CONSTRAINT lernpfad_letzte_session_id_fkey FOREIGN KEY (letzte_session_id) REFERENCES public.coaching_sessions(id) ON DELETE SET NULL;


--
-- Name: lernpfad lernpfad_lsa_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lernpfad
    ADD CONSTRAINT lernpfad_lsa_session_id_fkey FOREIGN KEY (lsa_session_id) REFERENCES public.lsa_sessions(id) ON DELETE SET NULL;


--
-- Name: lernpfad_protokoll lernpfad_protokoll_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lernpfad_protokoll
    ADD CONSTRAINT lernpfad_protokoll_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.coaching_sessions(id) ON DELETE SET NULL;


--
-- Name: lernpfad_protokoll lernpfad_protokoll_skill_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lernpfad_protokoll
    ADD CONSTRAINT lernpfad_protokoll_skill_key_fkey FOREIGN KEY (skill_key) REFERENCES public.skills(skill_key);


--
-- Name: lernpfad_protokoll lernpfad_protokoll_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lernpfad_protokoll
    ADD CONSTRAINT lernpfad_protokoll_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: lernpfad_protokoll lernpfad_protokoll_von_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lernpfad_protokoll
    ADD CONSTRAINT lernpfad_protokoll_von_fkey FOREIGN KEY (von) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: lernpfad lernpfad_skill_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lernpfad
    ADD CONSTRAINT lernpfad_skill_key_fkey FOREIGN KEY (skill_key) REFERENCES public.skills(skill_key);


--
-- Name: lernpfad lernpfad_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lernpfad
    ADD CONSTRAINT lernpfad_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


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
-- Name: lsa_sessions lsa_sessions_thema_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsa_sessions
    ADD CONSTRAINT lsa_sessions_thema_key_fkey FOREIGN KEY (thema_key) REFERENCES public.themen(thema_key);


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
-- Name: schueler_notizen schueler_notizen_ausgeblendet_von_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schueler_notizen
    ADD CONSTRAINT schueler_notizen_ausgeblendet_von_fkey FOREIGN KEY (ausgeblendet_von) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: schueler_notizen schueler_notizen_autor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schueler_notizen
    ADD CONSTRAINT schueler_notizen_autor_id_fkey FOREIGN KEY (autor_id) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: schueler_notizen schueler_notizen_entfernt_von_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schueler_notizen
    ADD CONSTRAINT schueler_notizen_entfernt_von_fkey FOREIGN KEY (entfernt_von) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: schueler_notizen schueler_notizen_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schueler_notizen
    ADD CONSTRAINT schueler_notizen_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: schul_themenplan schul_themenplan_schule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schul_themenplan
    ADD CONSTRAINT schul_themenplan_schule_id_fkey FOREIGN KEY (schule_id) REFERENCES public.schulen(id) ON DELETE CASCADE;


--
-- Name: schul_themenplan schul_themenplan_thema_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schul_themenplan
    ADD CONSTRAINT schul_themenplan_thema_key_fkey FOREIGN KEY (thema_key) REFERENCES public.themen(thema_key);


--
-- Name: schulen schulen_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schulen
    ADD CONSTRAINT schulen_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;


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
-- Name: skill_pruefung skill_pruefung_skill_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_pruefung
    ADD CONSTRAINT skill_pruefung_skill_key_fkey FOREIGN KEY (skill_key) REFERENCES public.skills(skill_key);


--
-- Name: skill_thema skill_thema_skill_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_thema
    ADD CONSTRAINT skill_thema_skill_key_fkey FOREIGN KEY (skill_key) REFERENCES public.skills(skill_key) ON DELETE CASCADE;


--
-- Name: skill_thema skill_thema_thema_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_thema
    ADD CONSTRAINT skill_thema_thema_key_fkey FOREIGN KEY (thema_key) REFERENCES public.themen(thema_key);


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
-- Name: students students_schule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_schule_id_fkey FOREIGN KEY (schule_id) REFERENCES public.schulen(id) ON DELETE RESTRICT;


--
-- Name: task_admin_protokoll task_admin_protokoll_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_admin_protokoll
    ADD CONSTRAINT task_admin_protokoll_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE;


--
-- Name: task_admin_protokoll task_admin_protokoll_von_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_admin_protokoll
    ADD CONSTRAINT task_admin_protokoll_von_fkey FOREIGN KEY (von) REFERENCES public.profiles(id);


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
-- Name: task_pruef_ausschluss task_pruef_ausschluss_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_pruef_ausschluss
    ADD CONSTRAINT task_pruef_ausschluss_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE;


--
-- Name: task_pruef_ausschluss task_pruef_ausschluss_von_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_pruef_ausschluss
    ADD CONSTRAINT task_pruef_ausschluss_von_fkey FOREIGN KEY (von) REFERENCES public.profiles(id);


--
-- Name: task_pruefung_ausgang task_pruefung_ausgang_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_pruefung_ausgang
    ADD CONSTRAINT task_pruefung_ausgang_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE;


--
-- Name: task_pruefungen task_pruefungen_beantwortet_von_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_pruefungen
    ADD CONSTRAINT task_pruefungen_beantwortet_von_fkey FOREIGN KEY (beantwortet_von) REFERENCES public.profiles(id);


--
-- Name: task_pruefungen task_pruefungen_geprueft_von_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_pruefungen
    ADD CONSTRAINT task_pruefungen_geprueft_von_fkey FOREIGN KEY (geprueft_von) REFERENCES public.profiles(id);


--
-- Name: task_pruefungen task_pruefungen_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_pruefungen
    ADD CONSTRAINT task_pruefungen_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE;


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
-- Name: thema_einstieg thema_einstieg_skill_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.thema_einstieg
    ADD CONSTRAINT thema_einstieg_skill_key_fkey FOREIGN KEY (skill_key) REFERENCES public.skills(skill_key) ON DELETE CASCADE;


--
-- Name: thema_einstieg thema_einstieg_thema_key_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.thema_einstieg
    ADD CONSTRAINT thema_einstieg_thema_key_fkey FOREIGN KEY (thema_key) REFERENCES public.themen(thema_key) ON DELETE CASCADE;


--
-- Name: tier_laufzeiten tier_laufzeiten_tier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tier_laufzeiten
    ADD CONSTRAINT tier_laufzeiten_tier_id_fkey FOREIGN KEY (tier_id) REFERENCES public.tiers(id) ON DELETE CASCADE;


--
-- Name: vertraege vertraege_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertraege
    ADD CONSTRAINT vertraege_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: vertraege vertraege_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertraege
    ADD CONSTRAINT vertraege_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE RESTRICT;


--
-- Name: vertraege vertraege_schule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertraege
    ADD CONSTRAINT vertraege_schule_id_fkey FOREIGN KEY (schule_id) REFERENCES public.schulen(id) ON DELETE RESTRICT;


--
-- Name: vertraege vertraege_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertraege
    ADD CONSTRAINT vertraege_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE RESTRICT;


--
-- Name: vertraege vertraege_tier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertraege
    ADD CONSTRAINT vertraege_tier_id_fkey FOREIGN KEY (tier_id) REFERENCES public.tiers(id);


--
-- Name: vertraege vertraege_vorgaenger_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertraege
    ADD CONSTRAINT vertraege_vorgaenger_id_fkey FOREIGN KEY (vorgaenger_id) REFERENCES public.vertraege(id) ON DELETE RESTRICT;


--
-- Name: vertrag_bankdaten vertrag_bankdaten_vertrag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertrag_bankdaten
    ADD CONSTRAINT vertrag_bankdaten_vertrag_id_fkey FOREIGN KEY (vertrag_id) REFERENCES public.vertraege(id) ON DELETE CASCADE;


--
-- Name: vertrag_dateien vertrag_dateien_erzeugt_von_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertrag_dateien
    ADD CONSTRAINT vertrag_dateien_erzeugt_von_fkey FOREIGN KEY (erzeugt_von) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: vertrag_dateien vertrag_dateien_vertrag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertrag_dateien
    ADD CONSTRAINT vertrag_dateien_vertrag_id_fkey FOREIGN KEY (vertrag_id) REFERENCES public.vertraege(id) ON DELETE RESTRICT;


--
-- Name: vertrag_unterschriften vertrag_unterschriften_vertrag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertrag_unterschriften
    ADD CONSTRAINT vertrag_unterschriften_vertrag_id_fkey FOREIGN KEY (vertrag_id) REFERENCES public.vertraege(id) ON DELETE CASCADE;


--
-- Name: vertrag_versand vertrag_versand_erfolgt_von_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertrag_versand
    ADD CONSTRAINT vertrag_versand_erfolgt_von_fkey FOREIGN KEY (erfolgt_von) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: vertrag_versand vertrag_versand_vertrag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertrag_versand
    ADD CONSTRAINT vertrag_versand_vertrag_id_fkey FOREIGN KEY (vertrag_id) REFERENCES public.vertraege(id) ON DELETE CASCADE;


--
-- Name: vertrag_zustimmungen vertrag_zustimmungen_dokument_schluessel_dokument_version_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertrag_zustimmungen
    ADD CONSTRAINT vertrag_zustimmungen_dokument_schluessel_dokument_version_fkey FOREIGN KEY (dokument_schluessel, dokument_version) REFERENCES public.vertrag_dokumente(schluessel, version);


--
-- Name: vertrag_zustimmungen vertrag_zustimmungen_erfasst_von_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertrag_zustimmungen
    ADD CONSTRAINT vertrag_zustimmungen_erfasst_von_fkey FOREIGN KEY (erfasst_von) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: vertrag_zustimmungen vertrag_zustimmungen_vertrag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertrag_zustimmungen
    ADD CONSTRAINT vertrag_zustimmungen_vertrag_id_fkey FOREIGN KEY (vertrag_id) REFERENCES public.vertraege(id) ON DELETE CASCADE;


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
-- Name: akte_einstellungen; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.akte_einstellungen ENABLE ROW LEVEL SECURITY;

--
-- Name: akte_einstellungen akte_einstellungen_admin_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY akte_einstellungen_admin_update ON public.akte_einstellungen FOR UPDATE USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


--
-- Name: akte_einstellungen akte_einstellungen_authenticated_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY akte_einstellungen_authenticated_read ON public.akte_einstellungen FOR SELECT USING ((auth.role() = 'authenticated'::text));


--
-- Name: akte_wortliste; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.akte_wortliste ENABLE ROW LEVEL SECURITY;

--
-- Name: akte_wortliste akte_wortliste_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY akte_wortliste_admin_all ON public.akte_wortliste USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


--
-- Name: akte_wortliste akte_wortliste_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY akte_wortliste_read ON public.akte_wortliste FOR SELECT USING ((public.get_my_role() = ANY (ARRAY['admin'::text, 'coach'::text])));


--
-- Name: audit_log; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

--
-- Name: audit_log audit_log_admin_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY audit_log_admin_read ON public.audit_log FOR SELECT USING ((public.get_my_role() = 'admin'::text));


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
-- Name: behavior_snapshots behavior_snapshots_admin_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY behavior_snapshots_admin_read ON public.behavior_snapshots FOR SELECT USING ((COALESCE(public.get_my_role(), ''::text) = 'admin'::text));


--
-- Name: behavior_snapshots behavior_snapshots_coach_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY behavior_snapshots_coach_select ON public.behavior_snapshots FOR SELECT USING (((COALESCE(public.get_my_role(), ''::text) = 'coach'::text) AND (EXISTS ( SELECT 1
   FROM public.students s
  WHERE ((s.profile_id = behavior_snapshots.user_id) AND public.akte_aktiv(s.id))))));


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

CREATE POLICY coaching_sessions_parent_read ON public.coaching_sessions FOR SELECT USING ((id IN ( SELECT public.session_ids_fuer_eltern() AS session_ids_fuer_eltern)));


--
-- Name: coaching_sessions coaching_sessions_student_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY coaching_sessions_student_read ON public.coaching_sessions FOR SELECT USING ((id IN ( SELECT public.session_ids_fuer_schueler() AS session_ids_fuer_schueler)));


--
-- Name: dokument_fassungen; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.dokument_fassungen ENABLE ROW LEVEL SECURITY;

--
-- Name: dokument_fassungen dokument_fassungen_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY dokument_fassungen_select ON public.dokument_fassungen FOR SELECT USING ((auth.uid() IS NOT NULL));


--
-- Name: eltern_reports; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.eltern_reports ENABLE ROW LEVEL SECURITY;

--
-- Name: eltern_reports eltern_reports_admin_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY eltern_reports_admin_select ON public.eltern_reports FOR SELECT USING ((public.get_my_role() = 'admin'::text));


--
-- Name: eltern_reports eltern_reports_admin_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY eltern_reports_admin_update ON public.eltern_reports FOR UPDATE USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


--
-- Name: eltern_reports eltern_reports_coach_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY eltern_reports_coach_select ON public.eltern_reports FOR SELECT USING (((public.get_my_role() = 'coach'::text) AND public.akte_aktiv(student_id)));


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
-- Name: feiertage_nrw; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.feiertage_nrw ENABLE ROW LEVEL SECURITY;

--
-- Name: feiertage_nrw feiertage_nrw_authenticated_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY feiertage_nrw_authenticated_read ON public.feiertage_nrw FOR SELECT USING ((auth.role() = 'authenticated'::text));


--
-- Name: ferien_nrw; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.ferien_nrw ENABLE ROW LEVEL SECURITY;

--
-- Name: ferien_nrw ferien_nrw_authenticated_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY ferien_nrw_authenticated_read ON public.ferien_nrw FOR SELECT USING ((auth.role() = 'authenticated'::text));


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
-- Name: lead_mail_versand; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lead_mail_versand ENABLE ROW LEVEL SECURITY;

--
-- Name: lead_mail_versand lead_mail_versand_admin_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lead_mail_versand_admin_select ON public.lead_mail_versand FOR SELECT USING ((public.get_my_role() = 'admin'::text));


--
-- Name: lead_themen; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lead_themen ENABLE ROW LEVEL SECURITY;

--
-- Name: lead_themen lead_themen_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lead_themen_admin_all ON public.lead_themen USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


--
-- Name: leads; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;

--
-- Name: leads leads_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY leads_admin_all ON public.leads USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


--
-- Name: lernpfad; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lernpfad ENABLE ROW LEVEL SECURITY;

--
-- Name: lernpfad_belege; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lernpfad_belege ENABLE ROW LEVEL SECURITY;

--
-- Name: lernpfad_belege lernpfad_belege_lesen; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lernpfad_belege_lesen ON public.lernpfad_belege FOR SELECT TO authenticated USING (public.lernpfad_darf_lesen(student_id));


--
-- Name: lernpfad lernpfad_lesen; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lernpfad_lesen ON public.lernpfad FOR SELECT TO authenticated USING (public.lernpfad_darf_lesen(student_id));


--
-- Name: lernpfad_protokoll; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lernpfad_protokoll ENABLE ROW LEVEL SECURITY;

--
-- Name: lernpfad_protokoll lernpfad_protokoll_lesen; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lernpfad_protokoll_lesen ON public.lernpfad_protokoll FOR SELECT TO authenticated USING (public.lernpfad_darf_lesen(student_id));


--
-- Name: lsa_ausgegeben; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lsa_ausgegeben ENABLE ROW LEVEL SECURITY;

--
-- Name: lsa_ausgegeben lsa_ausgegeben_admin_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lsa_ausgegeben_admin_read ON public.lsa_ausgegeben FOR SELECT USING ((COALESCE(public.get_my_role(), ''::text) = 'admin'::text));


--
-- Name: lsa_ausgegeben lsa_ausgegeben_coach_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lsa_ausgegeben_coach_select ON public.lsa_ausgegeben FOR SELECT USING (((COALESCE(public.get_my_role(), ''::text) = 'coach'::text) AND public.lsa_session_akte_aktiv(session_id)));


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
-- Name: lsa_report_notes lsa_report_notes_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lsa_report_notes_admin_all ON public.lsa_report_notes USING ((COALESCE(public.get_my_role(), ''::text) = 'admin'::text)) WITH CHECK ((COALESCE(public.get_my_role(), ''::text) = 'admin'::text));


--
-- Name: lsa_report_notes lsa_report_notes_coach_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lsa_report_notes_coach_select ON public.lsa_report_notes FOR SELECT USING (((COALESCE(public.get_my_role(), ''::text) = 'coach'::text) AND public.lsa_session_akte_aktiv(session_id)));


--
-- Name: lsa_responses; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lsa_responses ENABLE ROW LEVEL SECURITY;

--
-- Name: lsa_responses lsa_responses_admin_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lsa_responses_admin_read ON public.lsa_responses FOR SELECT USING ((COALESCE(public.get_my_role(), ''::text) = 'admin'::text));


--
-- Name: lsa_responses lsa_responses_coach_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lsa_responses_coach_select ON public.lsa_responses FOR SELECT USING (((COALESCE(public.get_my_role(), ''::text) = 'coach'::text) AND public.lsa_session_akte_aktiv(session_id)));


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
-- Name: lsa_sessions lsa_sessions_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lsa_sessions_admin_all ON public.lsa_sessions USING ((COALESCE(public.get_my_role(), ''::text) = 'admin'::text)) WITH CHECK ((COALESCE(public.get_my_role(), ''::text) = 'admin'::text));


--
-- Name: lsa_sessions lsa_sessions_coach_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lsa_sessions_coach_select ON public.lsa_sessions FOR SELECT USING (((COALESCE(public.get_my_role(), ''::text) = 'coach'::text) AND public.akte_aktiv(student_id)));


--
-- Name: lsa_sessions lsa_sessions_parent_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lsa_sessions_parent_read ON public.lsa_sessions FOR SELECT USING (public.is_parent_of_student(student_id));


--
-- Name: lsa_skill_urteil; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lsa_skill_urteil ENABLE ROW LEVEL SECURITY;

--
-- Name: lsa_skill_urteil lsa_skill_urteil_admin_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lsa_skill_urteil_admin_read ON public.lsa_skill_urteil FOR SELECT USING ((COALESCE(public.get_my_role(), ''::text) = 'admin'::text));


--
-- Name: lsa_skill_urteil lsa_skill_urteil_coach_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lsa_skill_urteil_coach_select ON public.lsa_skill_urteil FOR SELECT USING (((COALESCE(public.get_my_role(), ''::text) = 'coach'::text) AND public.lsa_session_akte_aktiv(session_id)));


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
-- Name: parent_reports parent_reports_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY parent_reports_admin_all ON public.parent_reports USING ((COALESCE(public.get_my_role(), ''::text) = 'admin'::text)) WITH CHECK ((COALESCE(public.get_my_role(), ''::text) = 'admin'::text));


--
-- Name: parent_reports parent_reports_coach_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY parent_reports_coach_select ON public.parent_reports FOR SELECT USING (((COALESCE(public.get_my_role(), ''::text) = 'coach'::text) AND public.akte_aktiv(student_id)));


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
-- Name: parent_student parent_student_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY parent_student_admin_all ON public.parent_student USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


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
-- Name: profiles profiles_admin_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profiles_admin_select ON public.profiles FOR SELECT USING ((public.get_my_role() = 'admin'::text));


--
-- Name: profiles profiles_coach_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profiles_coach_select ON public.profiles FOR SELECT USING (((public.get_my_role() = 'coach'::text) AND public.profil_fuer_coach_sichtbar(id)));


--
-- Name: pruef_einstellungen; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pruef_einstellungen ENABLE ROW LEVEL SECURITY;

--
-- Name: pruef_einstellungen pruef_einstellungen_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pruef_einstellungen_admin ON public.pruef_einstellungen FOR UPDATE TO authenticated USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


--
-- Name: pruef_einstellungen pruef_einstellungen_lesen; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pruef_einstellungen_lesen ON public.pruef_einstellungen FOR SELECT TO authenticated USING (true);


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
-- Name: schueler_notizen; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.schueler_notizen ENABLE ROW LEVEL SECURITY;

--
-- Name: schueler_notizen schueler_notizen_admin_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY schueler_notizen_admin_select ON public.schueler_notizen FOR SELECT USING ((public.get_my_role() = 'admin'::text));


--
-- Name: schueler_notizen schueler_notizen_coach_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY schueler_notizen_coach_select ON public.schueler_notizen FOR SELECT USING (((public.get_my_role() = 'coach'::text) AND public.akte_aktiv(student_id) AND (ausgeblendet_am IS NULL) AND (entfernt_am IS NULL)));


--
-- Name: schul_themenplan; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.schul_themenplan ENABLE ROW LEVEL SECURITY;

--
-- Name: schul_themenplan schul_themenplan_admin_write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY schul_themenplan_admin_write ON public.schul_themenplan USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


--
-- Name: schul_themenplan schul_themenplan_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY schul_themenplan_read ON public.schul_themenplan FOR SELECT USING ((public.get_my_role() = ANY (ARRAY['admin'::text, 'coach'::text])));


--
-- Name: schulen; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.schulen ENABLE ROW LEVEL SECURITY;

--
-- Name: schulen schulen_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY schulen_admin_all ON public.schulen USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


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

CREATE POLICY session_students_coach_rw ON public.session_students USING ((session_id IN ( SELECT public.session_ids_fuer_coach() AS session_ids_fuer_coach))) WITH CHECK ((session_id IN ( SELECT public.session_ids_fuer_coach() AS session_ids_fuer_coach)));


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
-- Name: skill_pruefung; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.skill_pruefung ENABLE ROW LEVEL SECURITY;

--
-- Name: skill_pruefung skill_pruefung_admin_lesen; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY skill_pruefung_admin_lesen ON public.skill_pruefung FOR SELECT TO authenticated USING ((public.get_my_role() = 'admin'::text));


--
-- Name: skill_thema; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.skill_thema ENABLE ROW LEVEL SECURITY;

--
-- Name: skill_thema skill_thema_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY skill_thema_read ON public.skill_thema FOR SELECT TO authenticated USING ((public.get_my_role() = ANY (ARRAY['admin'::text, 'coach'::text])));


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

CREATE POLICY student_badges_admin_write ON public.student_badges USING ((COALESCE(public.get_my_role(), ''::text) = 'admin'::text)) WITH CHECK ((COALESCE(public.get_my_role(), ''::text) = 'admin'::text));


--
-- Name: student_badges student_badges_self_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_badges_self_read ON public.student_badges FOR SELECT USING (((student_id IN ( SELECT s.id
   FROM public.students s
  WHERE (s.profile_id = auth.uid()))) OR (COALESCE(public.get_my_role(), ''::text) = 'admin'::text) OR ((COALESCE(public.get_my_role(), ''::text) = 'coach'::text) AND public.akte_aktiv(student_id)) OR (EXISTS ( SELECT 1
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
-- Name: student_focus_areas student_focus_areas_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_focus_areas_admin_all ON public.student_focus_areas USING ((COALESCE(public.get_my_role(), ''::text) = 'admin'::text)) WITH CHECK ((COALESCE(public.get_my_role(), ''::text) = 'admin'::text));


--
-- Name: student_focus_areas student_focus_areas_coach_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_focus_areas_coach_select ON public.student_focus_areas FOR SELECT USING (((COALESCE(public.get_my_role(), ''::text) = 'coach'::text) AND public.akte_aktiv(student_id)));


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
-- Name: student_progress student_progress_admin_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_progress_admin_read ON public.student_progress FOR SELECT USING ((COALESCE(public.get_my_role(), ''::text) = 'admin'::text));


--
-- Name: student_progress student_progress_coach_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_progress_coach_select ON public.student_progress FOR SELECT USING (((COALESCE(public.get_my_role(), ''::text) = 'coach'::text) AND public.akte_aktiv(student_id)));


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
-- Name: student_task_progress student_task_progress_admin_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_task_progress_admin_read ON public.student_task_progress FOR SELECT USING ((COALESCE(public.get_my_role(), ''::text) = 'admin'::text));


--
-- Name: student_task_progress student_task_progress_coach_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_task_progress_coach_select ON public.student_task_progress FOR SELECT USING (((COALESCE(public.get_my_role(), ''::text) = 'coach'::text) AND public.akte_aktiv(student_id)));


--
-- Name: student_task_progress student_task_progress_parent_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_task_progress_parent_read ON public.student_task_progress FOR SELECT USING (public.is_parent_of_student(student_id));


--
-- Name: student_task_progress student_task_progress_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY student_task_progress_select_own ON public.student_task_progress FOR SELECT USING ((student_id = public.get_my_student_id()));


--
-- Name: students; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;

--
-- Name: students students_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY students_admin_all ON public.students USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


--
-- Name: students students_coach_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY students_coach_select ON public.students FOR SELECT USING (((public.get_my_role() = 'coach'::text) AND public.akte_aktiv(id)));


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
-- Name: task_admin_protokoll; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.task_admin_protokoll ENABLE ROW LEVEL SECURITY;

--
-- Name: task_admin_protokoll task_admin_protokoll_lesen; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY task_admin_protokoll_lesen ON public.task_admin_protokoll FOR SELECT TO authenticated USING ((public.get_my_role() = 'admin'::text));


--
-- Name: task_coach_metadata; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.task_coach_metadata ENABLE ROW LEVEL SECURITY;

--
-- Name: task_figures; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.task_figures ENABLE ROW LEVEL SECURITY;

--
-- Name: task_pruef_ausschluss; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.task_pruef_ausschluss ENABLE ROW LEVEL SECURITY;

--
-- Name: task_pruef_ausschluss task_pruef_ausschluss_lesen; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY task_pruef_ausschluss_lesen ON public.task_pruef_ausschluss FOR SELECT TO authenticated USING (public.darf_pruefen());


--
-- Name: task_pruefung_ausgang; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.task_pruefung_ausgang ENABLE ROW LEVEL SECURITY;

--
-- Name: task_pruefung_ausgang task_pruefung_ausgang_lesen; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY task_pruefung_ausgang_lesen ON public.task_pruefung_ausgang FOR SELECT TO authenticated USING (public.darf_pruefen());


--
-- Name: task_pruefungen; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.task_pruefungen ENABLE ROW LEVEL SECURITY;

--
-- Name: task_pruefungen task_pruefungen_lesen; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY task_pruefungen_lesen ON public.task_pruefungen FOR SELECT TO authenticated USING (public.darf_pruefen());


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
-- Name: thema_einstieg; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.thema_einstieg ENABLE ROW LEVEL SECURITY;

--
-- Name: thema_einstieg thema_einstieg_admin_write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY thema_einstieg_admin_write ON public.thema_einstieg USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


--
-- Name: thema_einstieg thema_einstieg_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY thema_einstieg_read ON public.thema_einstieg FOR SELECT USING ((public.get_my_role() = ANY (ARRAY['admin'::text, 'coach'::text])));


--
-- Name: themen; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.themen ENABLE ROW LEVEL SECURITY;

--
-- Name: themen themen_read_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY themen_read_all ON public.themen FOR SELECT TO anon, authenticated, service_role USING (true);


--
-- Name: tier_laufzeiten; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.tier_laufzeiten ENABLE ROW LEVEL SECURITY;

--
-- Name: tier_laufzeiten tier_laufzeiten_admin_write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tier_laufzeiten_admin_write ON public.tier_laufzeiten USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


--
-- Name: tier_laufzeiten tier_laufzeiten_authenticated_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tier_laufzeiten_authenticated_read ON public.tier_laufzeiten FOR SELECT USING ((auth.role() = 'authenticated'::text));


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
-- Name: profiles users_see_own_profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY users_see_own_profile ON public.profiles FOR SELECT USING ((auth.uid() = id));


--
-- Name: behavior_snapshots users_see_own_snapshots; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY users_see_own_snapshots ON public.behavior_snapshots FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: vertraege; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.vertraege ENABLE ROW LEVEL SECURITY;

--
-- Name: vertraege vertraege_admin_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY vertraege_admin_select ON public.vertraege FOR SELECT USING ((public.get_my_role() = 'admin'::text));


--
-- Name: vertraege vertraege_admin_update_vorbereitung; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY vertraege_admin_update_vorbereitung ON public.vertraege FOR UPDATE USING (((public.get_my_role() = 'admin'::text) AND (status = 'in_vorbereitung'::text))) WITH CHECK (((public.get_my_role() = 'admin'::text) AND (status = 'in_vorbereitung'::text)));


--
-- Name: vertrag_bankdaten; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.vertrag_bankdaten ENABLE ROW LEVEL SECURITY;

--
-- Name: vertrag_bankdaten vertrag_bankdaten_admin_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY vertrag_bankdaten_admin_select ON public.vertrag_bankdaten FOR SELECT USING ((public.get_my_role() = 'admin'::text));


--
-- Name: vertrag_bankdaten vertrag_bankdaten_admin_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY vertrag_bankdaten_admin_update ON public.vertrag_bankdaten FOR UPDATE USING (((public.get_my_role() = 'admin'::text) AND (EXISTS ( SELECT 1
   FROM public.vertraege v
  WHERE ((v.id = vertrag_bankdaten.vertrag_id) AND (v.status = 'in_vorbereitung'::text)))))) WITH CHECK ((public.get_my_role() = 'admin'::text));


--
-- Name: vertrag_bankdaten vertrag_bankdaten_admin_write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY vertrag_bankdaten_admin_write ON public.vertrag_bankdaten FOR INSERT WITH CHECK (((public.get_my_role() = 'admin'::text) AND (EXISTS ( SELECT 1
   FROM public.vertraege v
  WHERE ((v.id = vertrag_bankdaten.vertrag_id) AND (v.status = 'in_vorbereitung'::text))))));


--
-- Name: vertrag_dateien; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.vertrag_dateien ENABLE ROW LEVEL SECURITY;

--
-- Name: vertrag_dateien vertrag_dateien_admin_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY vertrag_dateien_admin_select ON public.vertrag_dateien FOR SELECT USING ((public.get_my_role() = 'admin'::text));


--
-- Name: vertrag_dokumente; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.vertrag_dokumente ENABLE ROW LEVEL SECURITY;

--
-- Name: vertrag_dokumente vertrag_dokumente_admin_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY vertrag_dokumente_admin_select ON public.vertrag_dokumente FOR SELECT USING ((public.get_my_role() = 'admin'::text));


--
-- Name: vertrag_einstellungen; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.vertrag_einstellungen ENABLE ROW LEVEL SECURITY;

--
-- Name: vertrag_einstellungen vertrag_einstellungen_admin_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY vertrag_einstellungen_admin_select ON public.vertrag_einstellungen FOR SELECT USING ((public.get_my_role() = 'admin'::text));


--
-- Name: vertrag_einstellungen vertrag_einstellungen_admin_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY vertrag_einstellungen_admin_update ON public.vertrag_einstellungen FOR UPDATE USING ((public.get_my_role() = 'admin'::text)) WITH CHECK ((public.get_my_role() = 'admin'::text));


--
-- Name: vertrag_unterschriften; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.vertrag_unterschriften ENABLE ROW LEVEL SECURITY;

--
-- Name: vertrag_unterschriften vertrag_unterschriften_admin_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY vertrag_unterschriften_admin_select ON public.vertrag_unterschriften FOR SELECT USING ((public.get_my_role() = 'admin'::text));


--
-- Name: vertrag_versand; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.vertrag_versand ENABLE ROW LEVEL SECURITY;

--
-- Name: vertrag_versand vertrag_versand_admin_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY vertrag_versand_admin_select ON public.vertrag_versand FOR SELECT USING ((public.get_my_role() = 'admin'::text));


--
-- Name: vertrag_zustimmungen; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.vertrag_zustimmungen ENABLE ROW LEVEL SECURITY;

--
-- Name: vertrag_zustimmungen vertrag_zustimmungen_admin_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY vertrag_zustimmungen_admin_select ON public.vertrag_zustimmungen FOR SELECT USING ((public.get_my_role() = 'admin'::text));


--
-- Name: xp_events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.xp_events ENABLE ROW LEVEL SECURITY;

--
-- Name: xp_events xp_events_admin_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY xp_events_admin_read ON public.xp_events FOR SELECT USING ((COALESCE(public.get_my_role(), ''::text) = 'admin'::text));


--
-- Name: xp_events xp_events_coach_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY xp_events_coach_select ON public.xp_events FOR SELECT USING (((COALESCE(public.get_my_role(), ''::text) = 'coach'::text) AND public.akte_aktiv(student_id)));


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


