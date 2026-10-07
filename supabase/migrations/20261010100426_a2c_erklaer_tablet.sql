-- A2c: Erklaersequenz vom Tablet ohne student_id (Datenvertrag Abschnitt 8: das Kind steht nie im Aufruf).
-- Grundlage: die Prod-Definitionen (pg_get_functiondef, 07.10.2026) aus 20261008124412_a2_verdrahtung_a1_e1
-- bzw. 20261008124414_a2_erklaer_testlauf. Signaturen und Rechte bleiben (create or replace).
--   erklaer_start, erklaer_check_abgeben  p_student_id = null: das Kind kommt aus der Tablet-Zuweisung
--                                         (session_tablet_platz, ohne Platz 42501). Nennt der Aufrufer ein
--                                         Kind, gilt erklaer_zugang wie bisher.
--   erklaer_nachlesen                     p_student_id = null: das Kind des aufrufenden Tablets in seiner
--                                         laufenden Session, sonst 42501. Mit Kind unveraendert.
-- Ein Default null ist nicht moeglich: nach p_student_id folgen Parameter ohne Default. Das Tablet uebergibt
-- p_student_id ausdruecklich als null.

CREATE OR REPLACE FUNCTION public.erklaer_start(p_session_id uuid, p_student_id uuid, p_skill_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_letzt public.erklaer_fortschritt;
  v_k     public.erklaer_kernidee;
  v_tl    boolean;
begin
  -- A2c: ohne Kind das Kind des Tablets (42501 ohne Platz).
  if p_student_id is null then
    p_student_id := (public.session_tablet_platz(p_session_id, 'erklaer_start')).student_id;
  end if;
  perform public.erklaer_zugang(p_session_id, p_student_id);
  perform public.erklaer_sperren(p_session_id, p_student_id);
  v_tl := coalesce((select cs.testlauf from public.coaching_sessions cs where cs.id = p_session_id), false);

  select f.* into v_letzt from public.erklaer_fortschritt f
    join public.erklaer_kernidee k on k.id = f.kernidee_id
   where f.session_id = p_session_id and f.student_id = p_student_id and k.skill_key = p_skill_key
   order by f.id desc limit 1;

  if v_letzt.id is not null then
    -- Wiederaufnahme: dasselbe Paket, derselbe offene Check, ohne neue Zeile.
    select * into v_k from public.erklaer_kernidee where id = v_letzt.kernidee_id;
    if v_letzt.ergebnis = 'signal' then
      return jsonb_build_object('aktion', 'signal');
    elsif v_letzt.ergebnis = 'richtig' then
      return jsonb_build_object('aktion', 'weiter', 'uebergang', 'ueben');
    end if;
    -- Inzwischen nicht mehr freigegeben (Kernidee, Variante oder Check): nicht ausliefern.
    if not public.erklaer_status_ok(v_k.status, v_tl)
       or not (v_letzt.variante = any (public.erklaer_varianten(v_k.id, v_tl)))
       or not (v_letzt.check_task_id = any (public.erklaer_checks(v_k.id, v_tl))) then
      raise exception 'erklaer_start: Erklaerung inzwischen nicht mehr freigegeben' using errcode = 'P0002';
    end if;
    return jsonb_build_object(
      'aktion', 'start',
      'kernidee', jsonb_build_object('nr', v_k.nr, 'titel', v_k.titel,
                    'von', (select count(*) from public.erklaer_kernidee k
                             where k.skill_key = p_skill_key and public.erklaer_status_ok(k.status, v_tl))),
      'variante', v_letzt.variante, 'runde', v_letzt.runde,
      'schritte', public.erklaer_schritte_json(v_k.id, v_letzt.variante, v_tl),
      'check', jsonb_build_object('task_id', v_letzt.check_task_id,
                                  'aufgabe', public.lsa_question_payload(v_letzt.check_task_id)));
  end if;

  v_k := public.erklaer_naechste_kernidee(p_skill_key, 0, v_tl);
  if v_k.id is null then
    raise exception 'erklaer_start: keine freigegebene Erklaerung fuer %', p_skill_key using errcode = 'P0002';
  end if;
  return public.erklaer_zeigen(p_session_id, p_student_id, v_k,
                               (public.erklaer_varianten(v_k.id, v_tl))[1], 1, 'start', v_tl);
end;
$function$;

CREATE OR REPLACE FUNCTION public.erklaer_check_abgeben(p_session_id uuid, p_student_id uuid, p_check_task_id uuid, p_eingabe jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_letzt    public.erklaer_fortschritt;
  v_k        public.erklaer_kernidee;
  v_naechste public.erklaer_kernidee;
  v_urteil   jsonb;
  v_fb       text;
  v_var      text[];
  v_gezeigt  text[];
  v_wahl     text;
  v_tl       boolean;
begin
  -- A2c: ohne Kind das Kind des Tablets (42501 ohne Platz).
  if p_student_id is null then
    p_student_id := (public.session_tablet_platz(p_session_id, 'erklaer_check_abgeben')).student_id;
  end if;
  perform public.erklaer_zugang(p_session_id, p_student_id);
  perform public.erklaer_sperren(p_session_id, p_student_id);
  v_tl := coalesce((select cs.testlauf from public.coaching_sessions cs where cs.id = p_session_id), false);

  select * into v_letzt from public.erklaer_fortschritt
   where session_id = p_session_id and student_id = p_student_id
   order by id desc limit 1;
  if v_letzt.id is null or v_letzt.ergebnis <> 'gezeigt'
     or v_letzt.check_task_id is distinct from p_check_task_id then
    raise exception 'erklaer_check_abgeben: nicht der offene Check' using errcode = 'P0001';
  end if;
  select * into v_k from public.erklaer_kernidee where id = v_letzt.kernidee_id;
  if not public.erklaer_status_ok(v_k.status, v_tl) or not (p_check_task_id = any (public.erklaer_checks(v_k.id, v_tl))) then
    raise exception 'erklaer_check_abgeben: Check inzwischen nicht mehr freigegeben' using errcode = 'P0002';
  end if;

  v_urteil := public.erklaer_bewerten(p_check_task_id, p_eingabe);
  v_fb := v_urteil ->> 'fehlbild';
  insert into public.erklaer_fortschritt
    (session_id, student_id, kernidee_id, runde, variante, check_task_id, ergebnis, fehlbild_slug)
  values (p_session_id, p_student_id, v_k.id, v_letzt.runde, v_letzt.variante, p_check_task_id,
          case when (v_urteil ->> 'richtig')::boolean then 'richtig' else 'falsch' end, v_fb);
  -- A2: Ereignis fuer raum_signale (Signal nach erklaerrunden_bis_signal falschen Checks je Kernidee).
  perform public.session_ereignis(p_session_id, p_student_id, 'check',
    jsonb_build_object('kernidee', v_k.id, 'ergebnis',
                       case when (v_urteil ->> 'richtig')::boolean then 'richtig' else 'falsch' end,
                       'runde', v_letzt.runde, 'skill_key', v_k.skill_key));

  -- Richtig: naechste Kernidee, sonst Uebergang ins Ueben. Kein Mastery-Signal.
  if (v_urteil ->> 'richtig')::boolean then
    v_naechste := public.erklaer_naechste_kernidee(v_k.skill_key, v_k.nr, v_tl);
    if v_naechste.id is null then
      return jsonb_build_object('aktion', 'weiter', 'uebergang', 'ueben');
    end if;
    return public.erklaer_zeigen(p_session_id, p_student_id, v_naechste,
                                 (public.erklaer_varianten(v_naechste.id, v_tl))[1], 1, 'weiter', v_tl);
  end if;

  -- Falsch: nach erklaerrunden_bis_signal Runden ein Signal an den Coach.
  if (select count(*) from public.erklaer_fortschritt
       where session_id = p_session_id and student_id = p_student_id
         and kernidee_id = v_k.id and ergebnis = 'falsch') >= public.erklaer_runden_bis_signal(p_session_id) then
    insert into public.erklaer_fortschritt
      (session_id, student_id, kernidee_id, runde, variante, check_task_id, ergebnis, fehlbild_slug)
    values (p_session_id, p_student_id, v_k.id, v_letzt.runde, v_letzt.variante, p_check_task_id,
            'signal', v_fb);
    return jsonb_build_object('aktion', 'signal');
  end if;

  -- Sonst eine andere Variante: passend zum Fehlbild, sonst die naechste ungezeigte.
  v_var := public.erklaer_varianten(v_k.id, v_tl);
  select coalesce(array_agg(distinct variante), '{}') into v_gezeigt
    from public.erklaer_fortschritt
   where session_id = p_session_id and student_id = p_student_id
     and kernidee_id = v_k.id and ergebnis = 'gezeigt';

  select s.variante into v_wahl from public.erklaer_schritt s
   where s.kernidee_id = v_k.id and s.art = 'erklaerung' and public.erklaer_status_ok(s.status, v_tl)
     and s.variante <> v_letzt.variante and v_fb is not null and v_fb = any (s.fehlbild_slugs)
   order by (s.variante = any (v_gezeigt)), s.variante limit 1;
  if v_wahl is null then
    select v into v_wahl from unnest(v_var) v
     where v <> v_letzt.variante
     order by (v = any (v_gezeigt)), (v < v_letzt.variante), v limit 1;
  end if;

  return public.erklaer_zeigen(p_session_id, p_student_id, v_k,
                               coalesce(v_wahl, v_letzt.variante), v_letzt.runde + 1, 'variante', v_tl);
end;
$function$;

CREATE OR REPLACE FUNCTION public.erklaer_nachlesen(p_student_id uuid, p_skill_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
begin
  -- A2c: ohne Kind das Kind des aufrufenden Tablets in seiner laufenden Session (wie tablet_stand).
  if p_student_id is null then
    select st.student_id into p_student_id
      from public.session_tablets st
      join public.coaching_sessions cs on cs.id = st.session_id and cs.status = 'active'
     where st.geraet_id = auth.uid() and st.geloest_am is null;
    if p_student_id is null then
      raise exception 'erklaer_nachlesen: kein zugewiesener Platz an diesem Tablet' using errcode = '42501';
    end if;
  end if;
  -- A2: NULL-sicher (Befund X0b); zusaetzlich das Tablet des Kindes in einer laufenden Session.
  if not coalesce(coalesce(public.get_my_role(), '') = 'admin'
          or public.get_my_student_id() = p_student_id
          or exists (select 1 from public.session_students ss
                       join public.coaching_sessions cs on cs.id = ss.session_id
                      where ss.student_id = p_student_id and cs.coach_id = auth.uid())
          or exists (select 1 from public.session_tablets st
                       join public.coaching_sessions cs on cs.id = st.session_id and cs.status = 'active'
                      where st.student_id = p_student_id and st.geraet_id = auth.uid() and st.geloest_am is null),
          false) then
    raise exception 'erklaer_nachlesen: kein Zugriff' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'skill_key', p_skill_key,
    'kernideen', (select coalesce(jsonb_agg(jsonb_build_object(
                           'nr', k.nr, 'titel', k.titel,
                           'schritte', public.erklaer_schritte_json(k.id, 'A')) order by k.nr), '[]')
                    from public.erklaer_kernidee k
                   where k.skill_key = p_skill_key and k.status = 'freigegeben'
                     and 'A' = any (public.erklaer_varianten(k.id))));
end;
$function$;
