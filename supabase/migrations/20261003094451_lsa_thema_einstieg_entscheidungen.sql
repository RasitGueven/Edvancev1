-- ============================================================================
-- W3-6, Korrektur nach Rasits Entscheidungen vom 03.10.2026
-- ============================================================================
--
-- Ersetzt lsa_select_next_core aus 20261003092850_lsa_thema_einstieg.sql
-- (dieselbe Signatur, create or replace; Grants bleiben). Beide Dateien sind
-- noch nicht eingespielt; sie werden zusammen eingespielt, diese danach.
--
-- 1. Ohne Thema — kein aktuell-Thema oder keine Einstiegsknoten mit Aufgaben —
--    gilt die bisherige Auswahl einschliesslich Abstieg (Schritte 3 und 4 wie
--    vor W3-6), nur mit der Klassengrenze. Reine Breite ohne Abstieg gibt es
--    nur NACH Phase T und Tiefe einer Sitzung mit Thema; Breite a (behandelte
--    Themen) ebenfalls nur dann.
-- 2. Klassengrenze (klasse_herkunft <= grade) nur in der Breite, in den
--    Schritten 3/4 ohne Thema und in der Restzeit. Die Einstiegsknoten des
--    gewaehlten Themas und der Abstieg darunter sind ausgenommen: Klasse 7
--    mit Thema Lineare Funktionen (fkt_linear_* = Klasse 8) bekommt Phase T.
--
-- Zu thema_einstieg (unveraendert): fkt_linear_nullstelle ist kein Einstieg.
-- Sie liegt UEBER der Gleichung (setzt fkt_linear_gleichung voraus) und ist
-- deren Anwendung, kein Abstiegsziel; die Breite erreicht sie als Blatt.

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
     where te.thema_key = v_sess.thema_key and t.status = any (p_status_filter));

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
