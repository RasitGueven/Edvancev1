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
