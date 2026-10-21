-- LSA-Erlebnis L1, Punkt 3: Bruch nach Wert und Term in Abgabeform im correct-Pfad der LSA.
--
-- Anforderung „LSA-Erlebnis nach Prototyp V1.3.1“ (Fassung 1.1), Daten und Backend, Punkt 3; Entscheidung
-- Rasit 21.10.2026 (7.9) und Orchestrator c).
--
-- Gekapselt in lsa_antwort_korrekt(input_type, input_hint, correct_answers, response):
--   1. Zuerst der bisherige Vergleich (lsa_is_correct). Was dort trifft, trifft weiter — es gibt nie einen
--      Treffer weniger (Orchestrator c; z. B. nackte Prozentwerte wie „50“ in 939baa76).
--   2. input_hint 'fraction': zusätzlich nach Wert (lsa_bruch_wert_gleich). Nur wenn die Antwort ein Bruch
--      oder eine Zahl ist (-?\d+/\d+ bzw. -?\d+(,\d+)?); verglichen wird gegen jede Lösung derselben Form,
--      über Kreuzprodukt ohne Rundung. „-3/4“ trifft „-3/4“, „-6/8“ und „-0,75“. Nenner 0 trifft nie.
--      Lösungen mit Prozentzeichen oder Einheit nehmen am Wertvergleich nicht teil.
--   3. input_hint 'term' (bzw. input_type TERM): zusätzlich über die kanonische Form ax+b
--      (lsa_term_kanonisch). Die Abgabeform der App (ax+b, x+b, -x+b, ax, b; a, b ganz) trifft damit auch
--      „1x+5“, „5-x“, „0x+7“, „3x+-6“ oder „3·x - 6“. Andere Terme bleiben beim Zeichenkettenvergleich.
--
-- Benutzt von lsa_submit (correct je Aufgabe und je Teil; Teile mit input_type 'TERM' wie TERM-Aufgaben)
-- und von der neuen fünfstelligen lsa_grade(…, p_input_hint), die lsa_urteil_buchen_core aufruft
-- (Folgemigration). Die vierstellige lsa_grade, lsa_is_correct und die Session-Wertung (session_bewerten,
-- erklaer_bewerten, pruef_*) bleiben unverändert.
--
-- lsa_submit: Grundlage pg_get_functiondef aus Prod vom 21.10.2026; geändert sind nur die beiden
-- correct-Ausdrücke (markiert mit „L1“).

-- Zahl oder Bruch in Kindform → {Zähler, Nenner} (Nenner > 0), sonst NULL.
create or replace function public.lsa_bruch_zahl(p_raw text)
returns numeric[]
language sql
immutable
as $$
  select case when v ~ '^-?[0-9]+/[0-9]+$' or v ~ '^-?[0-9]+(\.[0-9]+)?$'
              then public.lsa_parse_fraction(v) end
    from (select regexp_replace(public.lsa_normalize_number(p_raw), '[[:space:]]*/[[:space:]]*', '/', 'g') as v) x
$$;

-- Ein Fehler (unlesbare Zahl, Überlauf) heisst „kein Treffer“, nie Abbruch der Abgabe.
create or replace function public.lsa_bruch_wert_gleich(p_antwort text, p_loesungen jsonb)
returns boolean
language plpgsql
immutable
as $$
declare
  v_a numeric[];
begin
  v_a := public.lsa_bruch_zahl(p_antwort);
  if v_a is null or jsonb_typeof(p_loesungen) is distinct from 'array' then
    return false;
  end if;
  return exists (
    select 1
      from jsonb_array_elements_text(p_loesungen) l(x)
     cross join lateral (select public.lsa_bruch_zahl(l.x) as b) y
     where y.b is not null and v_a[1] * y.b[2] = y.b[1] * v_a[2]);
exception
  when others then
    return false;
end;
$$;

-- Linearer Term in x → kanonische Abgabeform der App; alles andere → normalisiert, sonst unverändert.
create or replace function public.lsa_term_kanonisch(p_raw text)
returns text
language plpgsql
immutable
as $$
declare
  z  constant text := '[0-9]+(?:\.[0-9]+)?';
  v  text;
  v2 text;
  m  text[];
  a  numeric;
  b  numeric;
begin
  if p_raw is null then
    return null;
  end if;
  -- Minuszeichen vereinheitlichen, jedes Komma zum Punkt, Malzeichen nur zwischen Ziffer und x
  -- („3·x“ → „3x“; „2·3“ bleibt, wie es ist).
  v := replace(translate(public.lsa_normalize_term(p_raw), chr(8722) || chr(8211) || chr(8212), '---'), ',', '.');
  v := regexp_replace(v, '([0-9])[*' || chr(183) || chr(8901) || ']x', '\1x', 'g');
  loop
    v2 := replace(replace(replace(replace(v, '+-', '-'), '-+', '-'), '--', '+'), '++', '+');
    exit when v2 = v;
    v := v2;
  end loop;

  m := regexp_match(v, '^([+-]?)(' || z || ')?x([+-]' || z || ')?$');          -- ax+b
  if m is not null then
    a := (case when m[1] = '-' then -1 else 1 end) * coalesce(m[2]::numeric, 1);
    b := coalesce(m[3]::numeric, 0);
  else
    m := regexp_match(v, '^([+-]?' || z || ')(?:([+-])(' || z || ')?x)?$');      -- b oder b+ax
    if m is null then
      return v;
    end if;
    b := m[1]::numeric;
    a := case when m[2] is null then 0
              else (case when m[2] = '-' then -1 else 1 end) * coalesce(m[3]::numeric, 1) end;
  end if;

  if a = 0 then
    return trim_scale(b)::text;
  end if;
  return case when a = 1 then '' when a = -1 then '-' else trim_scale(a)::text end || 'x'
      || case when b > 0 then '+' || trim_scale(b)::text when b < 0 then trim_scale(b)::text else '' end;
exception
  when others then
    return v;
end;
$$;

create or replace function public.lsa_antwort_korrekt(p_input_type text, p_input_hint text,
                                                      p_correct_answers jsonb, p_response jsonb)
returns boolean
language plpgsql
immutable
as $$
declare
  v_term boolean := p_input_type = 'TERM' or (p_input_hint = 'term' and p_input_type is distinct from 'MC');
  v_text text;
begin
  -- 1. Der bisherige Vergleich. Was hier trifft, bleibt ein Treffer.
  if coalesce(public.lsa_is_correct(case when v_term then 'TERM' else p_input_type end,
                                    p_correct_answers, p_response), false) then
    return true;
  end if;
  if p_input_type = 'MC' or jsonb_typeof(p_response) is distinct from 'object'
     or jsonb_typeof(p_correct_answers) is distinct from 'array' then
    return false;
  end if;
  v_text := coalesce(p_response ->> 'text', p_response ->> 'value');
  if v_text is null or btrim(v_text) = '' then
    return false;
  end if;
  -- Ab hier nur zusätzliche Treffer: ein Fehler heisst „kein Treffer“, nie Abbruch der Abgabe.
  begin
    -- 3. Term: kanonische Form ax+b.
    if v_term then
      return exists (select 1 from jsonb_array_elements_text(p_correct_answers) l(x)
                      where public.lsa_term_kanonisch(l.x) = public.lsa_term_kanonisch(v_text));
    end if;
    -- 2. Bruch: nach Wert.
    if p_input_hint = 'fraction' then
      return public.lsa_bruch_wert_gleich(v_text, p_correct_answers);
    end if;
    return false;
  exception
    when others then
      return false;
  end;
end;
$$;

-- Fertigkeitsurteil mit Eingabeformat: dieselbe Wertung wie bisher. Nur bei 'fraction' und 'term' gilt: wo sie
-- 'nicht' sagt, aber lsa_antwort_korrekt trifft, gilt 'voll' — bzw. 'teilweise', wenn die gepflegte Regel einen
-- gekürzten Bruch verlangt. So laufen correct und Urteil dort nicht auseinander. Bei 'number' (und ohne
-- Hinweis) bleibt es exakt bei der vierstelligen lsa_grade aus #294 (Prozent als Faktor).
create or replace function public.lsa_grade(p_input_type text, p_acceptance jsonb, p_correct_answers jsonb,
                                            p_response jsonb, p_input_hint text)
returns text
language plpgsql
immutable
as $$
declare
  v_res text := public.lsa_grade(p_input_type, p_acceptance, p_correct_answers, p_response);
begin
  if v_res is distinct from 'nicht' or p_input_type = 'MC'
     or p_input_hint is null or p_input_hint not in ('fraction', 'term') then
    return v_res;
  end if;
  if not public.lsa_antwort_korrekt(p_input_type, p_input_hint, p_correct_answers, p_response) then
    return v_res;
  end if;
  if p_input_hint = 'fraction'
     and jsonb_typeof(p_acceptance) = 'object' and p_acceptance ? 'canonical'
     and coalesce((p_acceptance ->> 'require_reduced')::boolean, false)
     and not coalesce(public.lsa_is_reduced(coalesce(p_response ->> 'text', p_response ->> 'value')), false) then
    return 'teilweise';
  end if;
  return 'voll';
end;
$$;

revoke all on function public.lsa_bruch_zahl(text) from public, anon, authenticated;
revoke all on function public.lsa_bruch_wert_gleich(text, jsonb) from public, anon, authenticated;
revoke all on function public.lsa_term_kanonisch(text) from public, anon, authenticated;
revoke all on function public.lsa_antwort_korrekt(text, text, jsonb, jsonb) from public, anon, authenticated;
revoke all on function public.lsa_grade(text, jsonb, jsonb, jsonb, text) from public, anon, authenticated;

CREATE OR REPLACE FUNCTION public.lsa_submit(p_session_id uuid, p_task_id uuid, p_response jsonb, p_duration_ms integer DEFAULT NULL::integer, p_jetzt timestamp with time zone DEFAULT now())
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
                -- L1: Eingabeformat je Teil (Bruch nach Wert, Term kanonisch; Teil mit input_type TERM wie TERM).
                then coalesce(public.lsa_antwort_korrekt(
                       case when p ->> 'kind' = 'mc' then 'MC'
                            when p ->> 'input_type' = 'TERM' then 'TERM' else 'SHORT_TEXT' end,
                       public.lsa_teil_input_hint(p, teil.loesungen),
                       teil.loesungen,
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
               end as art,
               case when jsonb_typeof(v_answers -> (p ->> 'nr')) = 'array'
                    then v_answers -> (p ->> 'nr') else '[]'::jsonb end as loesungen
      ) teil
    on conflict (session_id, task_id, coalesce(part_nr, 0)) do nothing;
  else
    insert into lsa_responses (session_id, task_id, part_nr, response, abgabeart, correct, duration_ms)
    values (
      p_session_id, p_task_id, null, p_response, v_art,
      -- L1: Eingabeformat der Aufgabe (Bruch nach Wert, Term kanonisch).
      case when v_art = 'antwort'
           then coalesce(public.lsa_antwort_korrekt(
                  v_task.input_type,
                  public.lsa_input_hint(v_task.input_type, v_task.bruch, v_answers, v_task.unit),
                  v_answers, p_response), false)
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
$function$;
