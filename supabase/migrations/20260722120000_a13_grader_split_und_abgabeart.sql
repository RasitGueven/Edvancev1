-- 20260722120000_a13_grader_split_und_abgabeart
--
-- Rekonstruiert aus dem Prod-Schema am 2026-07-28.
-- Der ursprüngliche Wortlaut ist verloren; die Version steht bereits in
-- supabase_migrations.schema_migrations. Massgeblich ist allein, dass ein
-- Neuaufbau aus dem Repo denselben Zustand erreicht.
--
-- NICHT einspielen. Die Version gilt als angewandt.

--
-- Name: lsa_abgabeart(text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

ALTER TABLE public.lsa_responses ADD COLUMN IF NOT EXISTS abgabeart text DEFAULT 'antwort'::text NOT NULL;

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
-- Name: FUNCTION lsa_abgabeart(p_input_type text, p_response jsonb); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.lsa_abgabeart(p_input_type text, p_response jsonb) IS 'Ist das eine Antwort, ein bewusstes "weiss nicht" oder gar nichts? Entscheidet, ob bewertet wird.';

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
-- Name: FUNCTION lsa_is_unit(p_rest text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.lsa_is_unit(p_rest text) IS 'Sieht der Rest hinter der Zahl plausibel nach einer Einheit aus? Weicher Guard fuer den Wert-Einheit-Pfad in lsa_grade.';

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
-- Name: FUNCTION lsa_normalize_term(p_raw text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.lsa_normalize_term(p_raw text) IS 'Normalisierung fuer TERM-Antworten: wie lsa_normalize_answer, aber ohne jeden Leerraum.';

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
-- Name: task_solutions task_solutions_term_acceptance; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER task_solutions_term_acceptance BEFORE INSERT OR UPDATE OF acceptance, task_id ON public.task_solutions FOR EACH ROW EXECUTE FUNCTION public.lsa_term_acceptance_guard();

--
-- Name: tasks tasks_term_acceptance; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tasks_term_acceptance BEFORE UPDATE OF input_type ON public.tasks FOR EACH ROW WHEN ((new.input_type = 'TERM'::text)) EXECUTE FUNCTION public.lsa_term_acceptance_guard();

-- Ersetzte Funktionen. A13 überschreibt die Fassungen aus P01/P02/A11
-- um die Abgabeart-Unterscheidung. Aus Prod nachgetragen — der Zuordner
-- hat Ersetzungen bestehender Funktionen nicht erkannt.

CREATE OR REPLACE FUNCTION public.lsa_finish(p_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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

  update lsa_sessions
     set status         = 'completed',
         completed_at   = now(),
         result_summary = v_summary
   where id = p_session_id;

  return v_summary;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.lsa_grade(p_input_type text, p_acceptance jsonb, p_correct_answers jsonb, p_response jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.lsa_is_correct(p_input_type text, p_correct_answers jsonb, p_response jsonb)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
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
$function$
;


-- Check-Constraints. pg_dump faltet sie ins CREATE TABLE der Ursprungstabelle,
-- deshalb fehlten sie in der Rekonstruktion.
ALTER TABLE public.lsa_responses ADD CONSTRAINT lsa_responses_abgabeart_check CHECK ((abgabeart = ANY (ARRAY['antwort'::text, 'weiss_nicht'::text, 'leer'::text])));
ALTER TABLE public.lsa_responses ADD CONSTRAINT lsa_responses_correct_nur_bei_antwort CHECK (((abgabeart = 'antwort'::text) = (correct IS NOT NULL)));

-- TERM als Eingabetyp zulassen. Der Check stammt aus P02 und kennt ihn nicht;
-- pg_dump zeigt nur den Endzustand im CREATE TABLE.
ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS tasks_input_type_check;
ALTER TABLE public.tasks ADD CONSTRAINT tasks_input_type_check
  CHECK ((input_type = ANY (ARRAY['MC'::text, 'NUMERIC'::text, 'SHORT_TEXT'::text, 'TRUE_FALSE'::text, 'FREE_TEXT'::text, 'MATCHING'::text, 'CLOZE'::text, 'COORDINATE'::text, 'MULTI_PART'::text, 'TERM'::text])));
