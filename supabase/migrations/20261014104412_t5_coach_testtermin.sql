-- T5.2 Testtermin durch den eingeteilten Coach (Entscheidungen Rasit 12.10.2026, Paket T5; offene-punkte-sl2b Punkt 1).
--
-- Bisher liess der Trigger coaching_sessions_testlauf_pruefen ein INSERT mit testlauf = true nur dem Admin;
-- termin_session_anlegen meldete fuer den Coach eines reinen Testtermins (SL2b, Entscheidung 5) 42501 mit Hinweis
-- testlauf_nur_admin.
--
-- Jetzt (Entscheidung 4): termin_session_anlegen setzt direkt vor dem INSERT die transaktionslokale Einstellung
-- edvance.testlauf_anlegen = '1' und nimmt sie direkt danach zurueck (scheitert das INSERT, nimmt der Abbruch des
-- inneren Blocks sie mit zurueck). Der Trigger laesst ein INSERT mit testlauf ohne Admin nur durch, wenn
--   (a) diese Einstellung gesetzt ist, (b) raum_id und slot_zeit_id gesetzt sind und
--   (c) der Aufrufer der Coach in new.coach_id ist (Rolle coach, auth.uid() = coach_id).
-- Wer den Termin anlegen darf, prueft termin_session_anlegen wie bisher (nur der eingeteilte Coach dieses Raums).
-- Alles andere bleibt (Entscheidung 5): UPDATE von testlauf nur Admin (42501), nicht nach dem Start (55000), nur mit
-- Testkonten (22023); ein direktes INSERT mit testlauf durch einen Coach (ohne Systemweg) bleibt 42501.
-- Einen Client-Weg, die Einstellung zu setzen, gibt es nicht (Entscheidung 6, Beleg im PR): set_config liegt in
-- pg_catalog (nicht von PostgREST ausgeliefert), keine public-Funktion setzt einen Einstellungsnamen aus Parametern.
-- Signatur, SECURITY DEFINER, search_path und Grants beider Funktionen sind unveraendert.

CREATE OR REPLACE FUNCTION public.coaching_sessions_testlauf_pruefen()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
begin
  if (tg_op = 'INSERT' and new.testlauf)
     or (tg_op = 'UPDATE' and new.testlauf is distinct from old.testlauf) then
    -- T5: Ausnahme nur beim Anlegen ueber den Systemweg aus termin_session_anlegen, nur fuer den eingeteilten Coach.
    -- NULL-sicher: Ist ein Teil unbekannt (z. B. auth.uid() leer), gilt die Ausnahme nicht.
    if coalesce(public.get_my_role(), '') <> 'admin'
       and not coalesce(tg_op = 'INSERT'
                        and current_setting('edvance.testlauf_anlegen', true) = '1'
                        and new.raum_id is not null and new.slot_zeit_id is not null
                        and public.get_my_role() = 'coach' and new.coach_id = auth.uid(), false) then
      raise exception 'Testlauf: nur Admin' using errcode = '42501';
    end if;
    -- T4: nach dem Start nicht mehr, auch nicht ueber direkte Zeilenrechte (wie session_testlauf_setzen).
    if tg_op = 'UPDATE'
       and (old.gestartet_am is not null or old.status is distinct from 'upcoming'
            or new.gestartet_am is not null or new.status is distinct from 'upcoming') then
      raise exception 'Testlauf: Session ist schon gestartet' using errcode = '55000', hint = 'session_gestartet';
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
$function$
;

CREATE OR REPLACE FUNCTION public.termin_session_anlegen(p_datum date, p_zeit_id uuid, p_raum_id uuid, p_jetzt timestamp with time zone DEFAULT now())
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_rolle text := coalesce(public.get_my_role(), '');
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  r       record;
  v_sess  public.coaching_sessions;
  v_neu   boolean := false;
  v_aus   jsonb;
  v_x     jsonb;
  v_test  boolean;
begin
  if not public.ist_systemaufruf() and v_rolle not in ('admin', 'coach') then
    raise exception 'termin_session_anlegen: nur Admin oder Coach' using errcode = '42501';
  end if;
  perform public.slots_sperren();

  select * into r from public.slot_raeume(p_datum, p_datum) x
   where x.slot_zeit_id = p_zeit_id and x.raum_id = p_raum_id;
  -- Coach: nur der eingeteilte Coach dieses Raums (Entscheidung 20), auch über die direkte Adresse.
  if v_rolle = 'coach' and not public.ist_systemaufruf()
     and (r.raum_id is null or r.coach_id is distinct from auth.uid()) then
    raise exception 'termin_session_anlegen: nur der eingeteilte Coach dieses Raums' using errcode = '42501';
  end if;
  if p_datum <> public.slots_berlin_tag(v_jetzt) then
    perform public.slots_fehler('22023', 'termin_session_anlegen: nur am Tag des Termins', 'nur_am_tag');
  end if;

  v_sess := public.slots_session(p_datum, p_zeit_id, p_raum_id);
  if v_sess.id is null then
    if r.raum_id is null or not r.offen then
      perform public.slots_fehler('SL002', 'termin_session_anlegen: kein Raum mit Coach');
    end if;
    -- SL2b (Entscheidung 5): Sitzen im Termin nur Testkonten, entsteht die Session als Testlauf (beim Anlegen,
    -- also vor dem Start). Ohne Kinder richtet sie sich nach den übrigen Sessions des Termins.
    select bool_and(s.ist_test) into v_test
      from public.slot_zuteilung(p_datum, p_zeit_id) t join public.students s on s.id = t.student_id;
    if v_test is null then
      select bool_and(cs.testlauf) into v_test from public.coaching_sessions cs
       where cs.slot_zeit_id = p_zeit_id and cs.scheduled_at = public.slots_termin_beginn(p_datum, p_zeit_id);
    end if;
    v_test := coalesce(v_test, false);
    begin
      -- T5: Systemweg fuer den Trigger, nur fuer dieses INSERT (scheitert es, nimmt der Blockabbruch ihn zurueck).
      perform set_config('edvance.testlauf_anlegen', '1', true);
      insert into public.coaching_sessions (coach_id, room, scheduled_at, status, raum_id, slot_zeit_id, testlauf)
      values (r.coach_id, r.raum_name, public.slots_termin_beginn(p_datum, p_zeit_id), 'upcoming', p_raum_id, p_zeit_id,
              v_test)
      returning * into v_sess;
      perform set_config('edvance.testlauf_anlegen', '', true);
    exception when insufficient_privilege then
      -- Wer testlauf beim Anlegen setzen darf, entscheidet der Trigger coaching_sessions_testlauf_pruefen (T4, T5:
      -- Admin oder der eingeteilte Coach ueber den Systemweg); hier bekommt seine Ablehnung nur einen Hinweis.
      if not v_test then
        raise;
      end if;
      raise exception 'termin_session_anlegen: Testtermin, nur Admin' using errcode = '42501', hint = 'testlauf_nur_admin';
    end;
    v_neu := true;
  end if;

  v_aus := public.slots_festschreibung_nachziehen(p_datum, p_zeit_id);
  for v_x in select * from jsonb_array_elements(v_aus) loop
    perform public.termine_planen((v_x ->> 'student_id')::uuid, v_jetzt);
  end loop;

  return jsonb_build_object(
    'session_id', v_sess.id, 'neu', v_neu,
    'ausgelassen', coalesce((select jsonb_agg(x || public.slots_kind_info((x ->> 'student_id')::uuid,
                                                (select kt.vertrag_id from public.kind_termine kt
                                                  where kt.id = (x ->> 'termin_id')::uuid)))
                               from jsonb_array_elements(v_aus) x), '[]'));
end;
$function$
;
