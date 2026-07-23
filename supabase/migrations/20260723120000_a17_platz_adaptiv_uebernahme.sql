-- ============================================================================
-- A17: Platz-Ebene adaptiv + Uebernahme Platz -> Schueler + Konversions-Spur
--
-- Setzt A16 (20260723110000) voraus: lsa_sessions.modus, lsa_ausgegeben, der
-- adaptive lsa_start/lsa_submit. Fasst lsa_grade / lsa_select_next-Logik /
-- lsa_urteil_buchen NICHT an. Kein sondierrang.
--
-- ----------------------------------------------------------------------------
-- GEMESSENER BEFUND (Zusammenfassung, Details im PR)
-- ----------------------------------------------------------------------------
--   Platzlauf heute (fest): lead_lsa_freigeben legt provisorischen Schueler +
--     Session an (A16 hatte lsa_start hier auf 'fest' gepinnt); platz_assign
--     verknuepft ein Geraet mit der Session; platz_next/platz_submit lesen
--     item_ids (naechstes/aktuelles offenes Item); platz_finish -> lsa_finish;
--     platz_state zeigt {answered,total} aus item_ids.
--
--   FRAGE 1 (provisorischer Schueler bleibt?): JA. lead_convert flippt DIESELBE
--     students-Zeile (is_provisional=false, lead_id=null) und setzt
--     leads.converted_student_id. lsa_sessions.student_id ueberlebt die
--     Konversion unveraendert. => Die "Uebernahme" ist KEIN Datentransfer:
--     lsa_sessions/lsa_responses/lsa_skill_urteil/lsa_ausgegeben haengen bereits
--     am (spaeter echten) Schueler. Neu noetig sind nur (a) Fokus-Vorschlaege
--     aus den Urteilen und (b) die Konversions-Zeitstempel. Der Auftrag war
--     insoweit ueberdimensioniert (im PR begruendet).
--
--   FRAGE 2 (Platz wiederverwendet?): JA. 1 platz_device trug 7 verschiedene
--     Sessions ueber 15 Zuweisungen. Der Platz ist ein SITZ, keine Person — die
--     Konversionsspur darf NICHT am Platz haengen (naechstes Kind ueberschriebe
--     sie). Sie liegt auf leads (Erstkontakt) + lsa_sessions (der Sitzung).
--
--   KEINE ZWEITE WAHRHEIT: leads.converted_student_id existiert bereits (von
--     lead_convert). Es wird WIEDERVERWENDET; nur der Zeitstempel konvertiert_am
--     kommt neu dazu. Kein zusaetzliches konvertiert_zu_student_id.
-- ============================================================================

-- ============================================================================
-- TEIL A — PLATZ-EBENE ADAPTIV
-- ============================================================================

-- Auftrag 3: der 'fest'-Pin faellt (weiter unten). Der Modus bleibt als
-- Rueckfallschalter.
comment on column lsa_sessions.modus is
  'fest = Altpfad mit item_ids, seit A17 ohne produktiven Aufrufer. '
  'Nur noch Rueckfallschalter. adaptiv = lsa_select_next zieht zur Laufzeit.';

-- ----------------------------------------------------------------------------
-- platz_next: adaptiv liest die AUSGEGEBENE, noch offene Aufgabe (kein zweites
-- Ausgeben — lsa_submit/lsa_start haben sie bereits in lsa_ausgegeben getragen).
-- fest: unveraendert ueber item_ids.
-- ----------------------------------------------------------------------------
create or replace function public.platz_next()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
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

-- ----------------------------------------------------------------------------
-- platz_submit: +p_jetzt (Zeit-Ende testbar). adaptiv delegiert an den
-- adaptiven lsa_submit (Gate ueber lsa_ausgegeben, Antwort, dann Urteil, dann
-- next). Die Ordnung "aktuell offenes Item" kommt adaptiv aus lsa_ausgegeben.
-- fest: unveraendert.
-- ----------------------------------------------------------------------------
drop function if exists public.platz_submit(uuid, jsonb, integer);

create or replace function public.platz_submit(
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

-- ----------------------------------------------------------------------------
-- platz_finish: +p_jetzt (API-Symmetrie; lsa_finish selbst ist zeitunabhaengig
-- und markiert nur completed). Das SITZUNGSENDE wird ueber platz_next/
-- platz_submit sichtbar (adaptiv: kein weiteres Item, weil lsa_select_next bei
-- Zeitablauf NULL liefert). Logik sonst unveraendert.
-- ----------------------------------------------------------------------------
drop function if exists public.platz_finish();

create or replace function public.platz_finish(p_jetzt timestamptz default now())
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
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

-- ----------------------------------------------------------------------------
-- platz_state: adaptiv OHNE Aufgabenzahl. Fortschritt laeuft ueber Zeit als
-- Licht (expires_at). fest: unveraendert mit {answered,total}.
-- ----------------------------------------------------------------------------
create or replace function public.platz_state()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
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

-- ----------------------------------------------------------------------------
-- Auftrag 3: lead_lsa_freigeben entpinnen — neue Platz-Sitzungen sind adaptiv.
-- Nur die eine lsa_start-Zeile aendert sich (kein 'fest'-Argument mehr).
-- Bestehende 'fest'-Sitzungen laufen ueber die obigen fest-Zweige unveraendert.
-- ----------------------------------------------------------------------------
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

-- ============================================================================
-- TEIL B — UEBERNAHME PLATZ -> SCHUELER
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Auftrag 4: Konversions-Spur. converted_student_id existiert schon (lead_convert);
-- nur der Zeitstempel kommt neu. Plus die Sitzungs-Spur.
-- ----------------------------------------------------------------------------
alter table leads
  add column if not exists konvertiert_am timestamptz;
comment on column leads.konvertiert_am is
  'Zeitpunkt der Uebernahme (A17). konvertiert_am - lsa_sessions.started_at = '
  'Konversionsdauer (FWG-Pilot). Die Person haelt weiterhin converted_student_id.';

alter table lsa_sessions
  add column if not exists uebernommen_zu_student_id uuid references students(id),
  add column if not exists uebernommen_am timestamptz;
comment on column lsa_sessions.uebernommen_zu_student_id is
  'In welchen Schueler die Ergebnisse dieser Sitzung uebernommen wurden (A17). '
  'Bei Frage-1=JA identisch mit student_id; dient der Idempotenz-/Konflikt-Sperre '
  '(eine Sitzung gehoert zu genau einem Schueler) und markiert "uebernommen".';

-- ----------------------------------------------------------------------------
-- Auftrag 5/6: student_focus_areas minimal erweitern (KEINE zweite Tabelle).
-- Die Tabelle war cluster-basiert (Screening). Jetzt zusaetzlich skill-basiert
-- (LSA). Genau EINES von cluster_id / skill_key ist gesetzt.
--   status: der Vorschlags-Lebenszyklus (FernUSG). active: "im Lernpfad".
--   Ein Vorschlag ist NICHT aktiv (active=false), bis ein Coach ihn bestaetigt.
-- ----------------------------------------------------------------------------
alter table student_focus_areas
  alter column cluster_id drop not null,
  add column if not exists skill_key           text references skills(skill_key),
  add column if not exists herkunfts_session_id uuid references lsa_sessions(id) on delete set null,
  add column if not exists zustand             text,
  add column if not exists belegt_direkt       boolean,
  add column if not exists status              text not null default 'vorgeschlagen'
    check (status in ('vorgeschlagen','bestaetigt','verworfen'));

-- Genau eine Quelle je Zeile.
alter table student_focus_areas drop constraint if exists sfa_cluster_xor_skill;
alter table student_focus_areas
  add constraint sfa_cluster_xor_skill
  check ((cluster_id is not null) <> (skill_key is not null));

-- Idempotenz der Uebernahme: ein Skill je Herkunftssitzung genau einmal.
create unique index if not exists sfa_skill_herkunft_unique
  on student_focus_areas (student_id, skill_key, herkunfts_session_id)
  where skill_key is not null;

comment on column student_focus_areas.status is
  'Fokus-Lebenszyklus fuer SKILL-Fokus (A17): vorgeschlagen -> bestaetigt|verworfen. '
  'Das System schlaegt vor, der Coach entscheidet einzeln (FernUSG). Cluster-Fokus '
  '(Screening) fuehrt seine Wahrheit weiter in active.';
comment on column student_focus_areas.belegt_direkt is
  'Wurde der Skill in der LSA wirklich geprueft (true) oder ueber den Graphen '
  'abgeleitet (false)? Wandert aus lsa_skill_urteil mit — der Coach braucht die '
  'Unterscheidung in der ersten Session.';

-- Schueler-Sicht bleibt wie bisher: es gibt KEINE Schueler-Policy auf
-- student_focus_areas (nur coach/admin all, parent read). Ein 'vorgeschlagen'
-- ist damit schon heute fuer den Schueler unsichtbar — kein neuer Zugriff.

-- ----------------------------------------------------------------------------
-- Auftrag 5/6/7: lsa_uebernahme — kopiert nicht (Frage 1), erzeugt Fokus-
-- Vorschlaege aus den Luecken und setzt die Konversions-Spur. Coach/Admin.
-- ----------------------------------------------------------------------------
create or replace function public.lsa_uebernahme(
  p_session_id uuid,
  p_student_id uuid,
  p_jetzt      timestamptz default now()
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
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

-- ============================================================================
-- GRANTS (S9). lsa_uebernahme ist KEIN Schueler-Aufruf.
-- ============================================================================

revoke execute on function public.platz_next()                                  from public;
revoke execute on function public.platz_submit(uuid, jsonb, integer, timestamptz) from public;
revoke execute on function public.platz_finish(timestamptz)                     from public;
revoke execute on function public.platz_state()                                 from public;
revoke execute on function public.lsa_uebernahme(uuid, uuid, timestamptz)       from public;

grant execute on function public.platz_next()                                   to authenticated, service_role;
grant execute on function public.platz_submit(uuid, jsonb, integer, timestamptz) to authenticated, service_role;
grant execute on function public.platz_finish(timestamptz)                      to authenticated, service_role;
grant execute on function public.platz_state()                                  to authenticated, service_role;
grant execute on function public.lsa_uebernahme(uuid, uuid, timestamptz)        to authenticated, service_role;
-- lead_lsa_freigeben behaelt seine Grants (create or replace ruehrt die ACL nicht an).
