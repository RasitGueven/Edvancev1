-- ============================================================================
-- W3-6: LSA-Auswahl — erst das Thema, dann die Tiefe, dann die Breite
-- ============================================================================
--
-- Bisher (A15/A16) beginnt lsa_select_next_core bei den Blaettern mit dem
-- groessten offenen Abschluss im ganzen Fundament, unabhaengig vom Thema des
-- Kindes, und steigt unter JEDEM gebrochenen Knoten ab. Neu:
--
--   Schritt 2  offener Zweitbeleg — unveraendert, immer vorneweg
--   Phase T    Einstiegsknoten des Sitzungsthemas (thema_einstieg)
--   Tiefe      Abstieg (alter Schritt 3) nur unter dem Thema, bis Minute 12
--   Breite     a) Einstiegsknoten der 'behandelt'-Themen des Leads,
--                 zuletzt behandelt zuerst
--              b) gierige Deckung (alter Schritt 4) ueber das uebrige Fundament
--              — ohne Abstieg: jeder Knoten bekommt seine Probe(n), dann der naechste
--   Schritt 5  Restzeit — unveraendert bis auf die Klassengrenze
--
-- Ueberall ausser Schritt 2: nur Knoten mit skills.klasse_herkunft <= grade.
--
-- Unveraendert: lsa_urteil_buchen_core (Zweitbeleg-Regel, Mit-Belegung), das
-- 19-Minuten-Fenster, der Modus 'fest', RLS, die Signaturen von lsa_start und
-- lead_lsa_freigeben (die iPad-App ruft sie). Das Thema ermittelt lsa_start
-- selbst und haelt es in lsa_sessions.thema_key fest.
--
-- Der Report leitet "unter dem Thema" aus lsa_sessions.thema_key und
-- lsa_abschluss der Einstiegsknoten ab; lsa_skill_urteil bekommt keine Spalte.

-- ============================================================================
-- 1. lsa_lead_von_schueler — vom Schueler zum Lead
-- ============================================================================
--
-- Vor der Konversion haengt die (provisorische) Schuelerzeile per
-- students.lead_id am Lead (lead_lsa_freigeben legt sie so an), danach zeigt
-- leads.converted_student_id auf den Schueler. Dieselbe Reihenfolge wie in
-- lsa_lead_kontext und lsa_uebernahme.

create function public.lsa_lead_von_schueler(p_student_id uuid)
returns uuid
language sql
stable
set search_path = public
as $$
  select coalesce(
    (select s.lead_id from students s where s.id = p_student_id),
    (select l.id from leads l
      where l.converted_student_id = p_student_id
      order by l.created_at desc
      limit 1)
  )
$$;

revoke execute on function public.lsa_lead_von_schueler(uuid) from public, anon, authenticated;
grant  execute on function public.lsa_lead_von_schueler(uuid) to service_role;

-- ============================================================================
-- 2. lsa_start — thema_key festhalten (nur adaptiv)
-- ============================================================================
--
-- thema_key = das 'aktuell'-Thema des Leads fuer das Fach der Sitzung. Es wird
-- auch gesetzt, wenn das Thema (noch) keine Einstiegsknoten mit Aufgaben hat:
-- dann entfaellt nur Phase T, der Report kennt das Thema trotzdem.

create or replace function public.lsa_start(
  p_student_id uuid,
  p_grade      integer,
  p_subject    text,
  p_modus      text default 'adaptiv'::text,
  p_jetzt      timestamp with time zone default now()
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_session_id uuid;
  v_items      uuid[];
  v_first      uuid;
  v_thema      text;
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
    -- W3-6: Thema aus dem Erstgespraech. Fach ohne Gross/klein: die Sitzung
    -- traegt 'Mathematik', der Themenkatalog 'mathematik'.
    select lt.thema_key into v_thema
      from lead_themen lt
     where lt.lead_id = public.lsa_lead_von_schueler(p_student_id)
       and lt.status = 'aktuell'
       and lower(lt.fach) = lower(p_subject);

    insert into lsa_sessions (student_id, subject, grade, item_ids, started_at, status, modus, thema_key)
    values (p_student_id, p_subject, p_grade, '{}'::uuid[], p_jetzt, 'in_progress', 'adaptiv', v_thema)
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
$function$;

-- ============================================================================
-- 3. lsa_select_next_core — Thema, Tiefe, Breite
-- ============================================================================

create or replace function public.lsa_select_next_core(
  p_session_id    uuid,
  p_status_filter text[] default array['ready'::text],
  p_jetzt         timestamp with time zone default now()
)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $function$
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

  v_einstieg := array(
    select te.skill_key from thema_einstieg te where te.thema_key = v_sess.thema_key);
  v_themenraum := v_einstieg || array(
    select distinct a.skill_key
      from unnest(v_einstieg) e(sk)
      cross join lateral public.lsa_abschluss(e.sk) a);

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

    -- Phase T: naechster ungepruefter Einstiegsknoten des Themas, groesster
    -- offener Abschluss zuerst. Nur Knoten mit einer noch freien Aufgabe —
    -- ein Thema ohne Aufgaben laesst Phase T einfach aus.
    select y.leaf into v_leaf from (
      select s.skill_key as leaf,
             1 + (select count(*) from public.lsa_abschluss(s.skill_key) a
                   where not exists (
                     select 1 from lsa_skill_urteil u
                      where u.session_id = p_session_id and u.skill_key = a.skill_key)) as neu
        from skills s
       where s.skill_key = any (v_einstieg)
         and s.klasse_herkunft <= v_sess.grade
         and not exists (
               select 1 from lsa_skill_urteil u
                where u.session_id = p_session_id and u.skill_key = s.skill_key)
         and exists (
               select 1 from tasks t
                where t.skill_key = s.skill_key
                  and t.status = any (p_status_filter)
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
         and t.status = any (p_status_filter)
         and t.id not in (
               select task_id from lsa_ausgegeben where session_id = p_session_id
               union
               select task_id from lsa_responses  where session_id = p_session_id)
       order by t.sondierrang nulls last, md5(p_session_id::text || t.id::text)
       limit 1;
      return v_task;
    end if;

    -- Phase Tiefe (alter Schritt 3): Abstieg nur unter Knoten des Themenraums
    -- und nur bis c_tiefe_bis nach Sitzungsbeginn.
    v_desc := null;
    if p_jetzt < v_beginn + c_tiefe_bis then
      select x.q into v_desc from (
        select k.voraussetzt_skill_key as q, s.fundament_tiefe as tf
          from lsa_skill_urteil u
          join skill_kante k on k.skill_key = u.skill_key
          join skills s on s.skill_key = k.voraussetzt_skill_key
         where u.session_id = p_session_id
           and u.offen = false
           and u.zustand in ('traegt_nicht','nicht_angesetzt')
           and u.skill_key = any (v_themenraum)
           and s.klasse_herkunft <= v_sess.grade
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
       where lt.lead_id = v_lead
         and lt.status = 'behandelt'
         and lower(lt.fach) = v_fach
         and s.klasse_herkunft <= v_sess.grade
         and not exists (
               select 1 from lsa_skill_urteil u
                where u.session_id = p_session_id and u.skill_key = te.skill_key)
         and exists (
               select 1 from tasks t
                where t.skill_key = te.skill_key
                  and t.status = any (p_status_filter)
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
         and t.status = any (p_status_filter)
         and t.id not in (
               select task_id from lsa_ausgegeben where session_id = p_session_id
               union
               select task_id from lsa_responses  where session_id = p_session_id)
       order by t.sondierrang nulls last, md5(p_session_id::text || t.id::text)
       limit 1;
      return v_task;
    end if;

    -- Breite b (alter Schritt 4): neues Blatt nach gieriger Deckung.
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
      join skills s on s.skill_key = t.skill_key
     where s.klasse_herkunft <= v_sess.grade
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
$function$;

-- ============================================================================
-- 4. thema_einstieg — Lineare Funktionen, Prozent- und Zinsrechnung
-- ============================================================================
--
-- Hoechstens drei Einstiegsknoten je Thema. Phase T prueft sie nach
-- "groesster offener Abschluss zuerst"; ein Knoten, der dabei schon
-- mitbelegt wurde, faellt heraus. Kreis folgt in einer eigenen Migration
-- (die geo_kreis_*-Knoten sind in Produktion noch nicht eingespielt).
--
-- lineare_funktionen:
--   fkt_linear_gleichung  — Kern des Themas, haengt an Steigung und
--                           y-Abschnitt; traegt sie, sind beide mitbelegt
--   fkt_linear_steigung   — eigener Einstieg, falls die Gleichung bricht
--   fkt_linear_yabschnitt — dito
--   Nicht: fkt_linear_graph (dieselben Voraussetzungen wie die Gleichung,
--   bringt fuer den Einstieg nichts Neues) und fkt_linear_nullstelle (setzt
--   die Gleichung voraus, ist Anwendung statt Kern; die Breite erreicht sie
--   als Blatt).
-- zinsrechnung:
--   prozent_zins_zinseszins — groesster Abschluss (Jahreszins, Potenzen,
--                             prozentuale Veraenderung)
--   prozent_zins_jahreszins — der Grundfall, den Teil- und Rueckrechnung
--                             voraussetzen
--   Teilzins und Rueckrechnung bleiben Blaetter der Breite: beide haengen am
--   Jahreszins, ein dritter Einstieg wuerde nur dessen Befund wiederholen.

-- Kein exists-Waechter: fehlt ein Knoten oder Thema, soll der Fremdschluessel
-- laut scheitern, statt still nichts einzutragen. Die fuenf Bestandszeilen
-- (Binom, Gleichungen) bleiben unberuehrt.
insert into public.thema_einstieg (thema_key, skill_key) values
  ('lineare_funktionen', 'fkt_linear_gleichung'),
  ('lineare_funktionen', 'fkt_linear_steigung'),
  ('lineare_funktionen', 'fkt_linear_yabschnitt'),
  ('zinsrechnung',       'prozent_zins_zinseszins'),
  ('zinsrechnung',       'prozent_zins_jahreszins')
on conflict (thema_key, skill_key) do nothing;
