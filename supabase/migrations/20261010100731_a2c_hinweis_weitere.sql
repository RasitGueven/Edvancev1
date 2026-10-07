-- A2c: hinweis_abrufen sagt dem Tablet, ob es eine weitere Stufe gibt (Tablet-Luecke aus dem Abgleich
-- Datenvertrag 8.2). Die Obergrenze hinweisstufen ist eine Stellschraube je Session; sie steht weder im
-- QuestionPayload noch in session_naechster_schritt, das Tablet konnte sie nur per Fehler ertasten.
--   - Antwort zusaetzlich 'weitere': p_stufe < hinweisstufen. Additiv, sonst unveraendert.
--   - Stufe ausserhalb 1..hinweisstufen: 22023 jetzt mit hint 'stufe_gesperrt' (wie die uebrigen Gruende).
-- Grundlage: Prod-Definition (pg_get_functiondef, 07.10.2026) aus 20261009104120_a2b_ein_versuch.
-- Signatur und Rechte bleiben (create or replace).

CREATE OR REPLACE FUNCTION public.hinweis_abrufen(p_session_id uuid, p_task_id uuid, p_stufe integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  t      public.session_tablets := public.session_tablet_platz(p_session_id, 'hinweis_abrufen');
  v_text text;
begin
  if not exists (select 1 from public.session_ausgegeben where session_id = p_session_id
                  and student_id = t.student_id and task_id = p_task_id) then
    raise exception 'hinweis_abrufen: Aufgabe wurde diesem Kind nicht gegeben' using errcode = 'P0001';
  end if;
  -- A2b (Entscheidung 32): nur vor dem Abgeben; Hinweise haengen an der Aufgabe, also zaehlt jede Antwort
  -- auf irgendeinen Teil seit der juengsten Ausgabe.
  if exists (select 1 from public.session_antworten r where r.session_id = p_session_id and r.student_id = t.student_id
              and r.task_id = p_task_id
              and r.zeit >= (select max(x.zeit) from public.session_ausgegeben x where x.session_id = p_session_id
                              and x.student_id = t.student_id and x.task_id = p_task_id)) then
    raise exception 'hinweis_abrufen: zu dieser Aufgabe liegt schon eine Antwort vor' using errcode = 'P0001',
      hint = 'hinweis_nach_antwort';
  end if;
  -- A2 (K): Exit-Aufgaben im Check-out ohne Hinweise.
  if exists (select 1 from public.session_schritte x where x.session_id = p_session_id
              and x.student_id = t.student_id and x.task_id = p_task_id and x.art = 'exit') then
    raise exception 'hinweis_abrufen: Exit-Aufgaben ohne Hinweise' using errcode = '22023', hint = 'exit_ohne_hinweis';
  end if;
  -- A2b (Entscheidung 32): keine Hinweise im Warm-up.
  if exists (select 1 from public.session_schritte x where x.session_id = p_session_id
              and x.student_id = t.student_id and x.task_id = p_task_id and x.phase = 'warmup') then
    raise exception 'hinweis_abrufen: im Warm-up keine Hinweise' using errcode = '22023', hint = 'warmup_ohne_hinweis';
  end if;
  if p_stufe is null or p_stufe < 1 or p_stufe > public.session_wert_zahl(p_session_id, 'hinweisstufen') then
    raise exception 'hinweis_abrufen: Stufe % ist nicht freigeschaltet', p_stufe using errcode = '22023',
      hint = 'stufe_gesperrt';
  end if;
  -- Prinzip der minimalen Hilfe (Entscheidung 11): Stufe n erst nach Stufe n-1.
  if p_stufe > 1 and not exists (select 1 from public.session_ereignisse e
       where e.session_id = p_session_id and e.student_id = t.student_id and e.typ = 'hinweis'
         and e.payload ->> 'task_id' = p_task_id::text and (e.payload ->> 'stufe')::int = p_stufe - 1) then
    raise exception 'hinweis_abrufen: erst Stufe %', p_stufe - 1 using errcode = '22023', hint = 'hinweis_reihenfolge';
  end if;

  select h ->> 'text' into v_text
    from public.task_solutions s, jsonb_array_elements(s.hints) as e(h)
   where s.task_id = p_task_id and h ->> 'level' = p_stufe::text and h ->> 'status' = 'geprueft'
   order by h ->> 'text'
   limit 1;

  perform public.session_ereignis(p_session_id, t.student_id, 'hinweis',
    jsonb_build_object('task_id', p_task_id, 'stufe', p_stufe, 'geliefert', v_text is not null));
  -- A2c: weitere = es gibt eine naechste Stufe (hinweisstufen sieht das Tablet sonst nicht).
  return jsonb_build_object('stufe', p_stufe, 'text', v_text, 'verfuegbar', v_text is not null,
                            'weitere', p_stufe < public.session_wert_zahl(p_session_id, 'hinweisstufen'));
end;
$function$;
