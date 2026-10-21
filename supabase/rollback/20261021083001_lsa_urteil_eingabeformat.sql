-- Rollback zu 20261021083001_lsa_urteil_eingabeformat (LSA-Erlebnis L1, Punkt 3, Urteil).
-- Stellt lsa_urteil_buchen_core wieder her (vierstellige lsa_grade), wörtlich nach pg_get_functiondef aus Prod
-- vom 21.10.2026 (vor L1).

CREATE OR REPLACE FUNCTION public.lsa_urteil_buchen_core(p_session_id uuid, p_task_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
$function$;

