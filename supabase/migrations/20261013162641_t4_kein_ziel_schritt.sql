-- T4.6 Jedes Warten hinterlaesst eine Zeile in session_schritte, auch das erste (Entscheidung Rasit 12.10.2026,
-- Paket T4; offene-punkte-f2 Abschnitt 3 Punkt 1).
--
-- session_naechster_schritt traegt wiederholtes Warten nicht erneut ein:
--   if not (art in ('warten','erklaerung') and v_letzt.art = art and v_letzt.grund_code = grund_code
--           and v_letzt.skill_key is not distinct from skill_key)
-- Gibt es noch keinen Schritt, ist v_letzt leer und v_letzt.art = art ergibt null. Bei skill_key null (kein_ziel)
-- bleibt der ganze Ausdruck null, und "if null" schrieb nichts (Prod d3e7510f am 10.10.: Phasenwechsel kern ohne
-- Schritt). Jetzt: ohne vorigen Schritt wird immer eingetragen. Danach greift der Vergleich wie bisher, ein
-- wiederholtes kein_ziel beim naechsten Takt bleibt eine Zeile. Sonst unveraendert (Prod-Definition 12.10.2026).

CREATE OR REPLACE FUNCTION public.session_naechster_schritt(p_session_id uuid, p_student_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  t       public.session_tablets;
  v       jsonb;
  v_letzt public.session_schritte;
  v_sig   jsonb;
begin
  -- Vorschau: Coach der Session oder Admin. Bucht nichts.
  if coalesce(public.session_ist_coach(p_session_id), false) then
    if not exists (select 1 from public.session_students where session_id = p_session_id and student_id = p_student_id) then
      raise exception 'session_naechster_schritt: Kind ist in dieser Session nicht gebucht' using errcode = 'P0002';
    end if;
    return public.session_schritt_oeffentlich(public.session_schritt_planen(p_session_id, p_student_id), true)
           || jsonb_build_object('vorschau', true);
  end if;

  -- Tablet: das Kind ergibt sich aus dem Platz (42501 ohne Platz, also auch fuer fremde
  -- Tablets, Schuelerkonten und Konten ohne Profil).
  t := public.session_tablet_platz(p_session_id, 'session_naechster_schritt');
  if p_student_id is not null and p_student_id <> t.student_id then
    raise exception 'session_naechster_schritt: nur der eigene Platz' using errcode = '42501';
  end if;
  perform pg_advisory_xact_lock(hashtext('session_schritt:' || p_session_id::text || ':' || t.student_id::text));

  v := public.session_schritt_planen(p_session_id, t.student_id);
  if coalesce((v ->> 'offen')::boolean, false) then
    return public.session_schritt_oeffentlich(v);
  end if;

  if v ->> 'phase' in ('warmup', 'kern', 'checkout')
     and public.session_phase(p_session_id, t.student_id) is distinct from v ->> 'phase' then
    perform public.session_ereignis(p_session_id, t.student_id, 'phase_wechsel',
                                    jsonb_build_object('phase', v ->> 'phase'));
  end if;

  select * into v_letzt from public.session_schritte x
   where x.session_id = p_session_id and x.student_id = t.student_id order by x.id desc limit 1;
  -- Wiederholtes Warten bzw. dieselbe laufende Erklaerung wird nicht erneut eingetragen.
  -- T4: ohne vorigen Schritt immer eintragen (sonst blieb der Vergleich bei skill_key null ohne Ergebnis).
  if v_letzt.id is null or not (v ->> 'art' in ('warten', 'erklaerung') and v_letzt.art = v ->> 'art'
          and v_letzt.grund_code = v ->> 'grund_code'
          and v_letzt.skill_key is not distinct from v ->> 'skill_key') then
    insert into public.session_schritte (session_id, student_id, art, phase, skill_key, task_id, modus, eingemischt,
           nach_beispiel, schwierigkeit, grund, grund_code, details)
    values (p_session_id, t.student_id, v ->> 'art', v ->> 'phase', v ->> 'skill_key', (v ->> 'task_id')::uuid,
            v ->> 'modus', coalesce((v ->> 'eingemischt')::boolean, false),
            coalesce((v ->> 'nach_beispiel')::boolean, false), (v ->> 'schwierigkeit')::int,
            v ->> 'grund', v ->> 'grund_code',
            -- C3: Zahlen zum Grund (nur Coach; session_schritt_oeffentlich gibt sie nicht weiter).
            coalesce(v -> 'details', '{}'::jsonb));
  end if;

  if v ->> 'art' in ('aufgabe', 'exit') then
    insert into public.session_ausgegeben (session_id, student_id, task_id, phase, eingemischt, von)
    values (p_session_id, t.student_id, (v ->> 'task_id')::uuid, v ->> 'phase',
            coalesce((v ->> 'eingemischt')::boolean, false), auth.uid());
  end if;

  for v_sig in select * from jsonb_array_elements(coalesce(v -> 'signale', '[]')) loop
    perform public.session_ereignis(p_session_id, t.student_id, 'signal', v_sig);
  end loop;

  -- A2b (Entscheidung 30): beim ersten "fertig" die XP der Session buchen (genau einmal je Kind).
  if v ->> 'art' = 'fertig' then
    perform public.session_xp_buchen(p_session_id, t.student_id);
  end if;

  if v ? 'exit_ergebnis' then
    insert into public.session_kind_abschluss as k (session_id, student_id, exit_ergebnis, aktualisiert_von)
    values (p_session_id, t.student_id, v -> 'exit_ergebnis', auth.uid())
    on conflict (session_id, student_id) do update
       set exit_ergebnis = excluded.exit_ergebnis, aktualisiert_am = clock_timestamp(), aktualisiert_von = auth.uid()
     where k.exit_ergebnis is distinct from excluded.exit_ergebnis;
  end if;

  return public.session_schritt_oeffentlich(v);
end;
$function$;
