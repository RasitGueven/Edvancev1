-- 20260726100000_af1_fehlbild_capture
--
-- Rekonstruiert aus dem Prod-Schema am 2026-07-28.
-- Der ursprüngliche Wortlaut ist verloren; die Version steht bereits in
-- supabase_migrations.schema_migrations. Massgeblich ist allein, dass ein
-- Neuaufbau aus dem Repo denselben Zustand erreicht.
--
-- NICHT einspielen. Die Version gilt als angewandt.

--
-- Name: lsa_fehlbild_capture(); Type: FUNCTION; Schema: public; Owner: -
--

ALTER TABLE public.lsa_responses ADD COLUMN IF NOT EXISTS fehlbild_slug text;

CREATE FUNCTION public.lsa_fehlbild_capture() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_kind text;
  v_ke   jsonb;
begin
  -- Nur echte, falsche Abgaben sind Fehlbild-Kandidaten.
  -- CHECK lsa_responses_correct_nur_bei_antwort haelt correct NULL fuer
  -- 'weiss_nicht' und 'leer' — ein "weiss nicht" ist kein Denkfehler und darf
  -- nie als einer gelabelt werden.
  if new.abgabeart <> 'antwort' or new.correct is not false then
    return null;
  end if;

  -- Fehlbild-Erfassung ist Diagnostik-Beiwerk. Ein Fehler hier darf die Abgabe
  -- eines Kindes NIE blockieren — deshalb faengt der Block alles und meldet per
  -- WARNING in die Logs, statt den Insert scheitern zu lassen.
  begin

  -- known_errors pro Teil aus acceptance ziehen.
  -- Multi-Part: acceptance -> '<nr>' -> 'known_errors'; flach: acceptance -> 'known_errors'.
  -- Der coalesce-Fallback auf die flache Form ist defensiv: in Prod sind heute
  -- ALLE acceptance-Zeilen flach und auf Ein-Teil-Items; schreibt ein kuenftiger
  -- Submit-Pfad part_nr auch dort, matcht die strikte Variante sonst stillschweigend nichts.
  select coalesce(
           ts.acceptance -> coalesce(new.part_nr::text, '') -> 'known_errors',
           ts.acceptance -> 'known_errors'
         ),
         coalesce(
           (select e.p ->> 'kind'
              from jsonb_array_elements(t.parts) as e(p)
             where (e.p ->> 'nr') = new.part_nr::text
             limit 1),
           lower(t.input_type)
         )
    into v_ke, v_kind
    from public.tasks t
    join public.task_solutions ts on ts.task_id = t.id
   where t.id = new.task_id;

  if v_ke is null then
    return null;
  end if;

  -- Auf die Primaerschluessel-Zeile schreiben. Kein Match ueber
  -- (session_id, task_id, part_nr): darauf existiert KEIN Unique-Constraint,
  -- eine Wiederholung derselben Aufgabe wuerde sonst fremde Zeilen treffen.
  update public.lsa_responses
     set fehlbild_slug = public.lsa_fehlbild_match(v_kind, v_ke, new.response)
   where id = new.id
     and fehlbild_slug is null;

  exception when others then
    raise warning 'lsa_fehlbild_capture: response=% task=% part=% -> %',
      new.id, new.task_id, new.part_nr, sqlerrm;
  end;

  return null;
end;
$$;

--
-- Name: lsa_fehlbild_match(text, jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lsa_fehlbild_match(p_kind text, p_known_errors jsonb, p_response jsonb) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
declare
  v_kind  text := lower(coalesce(p_kind, ''));
  v_term  boolean := (v_kind = 'term');
  v_given text;
  v_slug  text;
begin
  if p_known_errors is null or p_response is null then
    return null;
  end if;

  if v_kind = 'mc' then
    -- Ein known_errors-Schlüssel kann keine Auswahl-MENGE abbilden. Deshalb
    -- matcht MC nur bei genau einer gewählten Option; Mehrfachauswahl ist
    -- bewusst kein Fehlbild-Kandidat.
    if jsonb_typeof(p_response -> 'selected') <> 'array'
       or jsonb_array_length(p_response -> 'selected') <> 1 then
      return null;
    end if;
    v_given := public.lsa_normalize_answer(p_response -> 'selected' ->> 0);
  else
    v_given := coalesce(p_response ->> 'text', p_response ->> 'value');
    if v_given is null then
      return null;
    end if;
    v_given := case when v_term then public.lsa_normalize_term(v_given)
                    else public.lsa_normalize_answer(v_given) end;
  end if;

  if v_given is null or v_given = '' then
    return null;
  end if;

  case jsonb_typeof(p_known_errors)
    -- object {wert: slug}: labeled -> gibt den slug zurueck
    when 'object' then
      select ke.value #>> '{}'
        into v_slug
        from jsonb_each(p_known_errors) as ke(key, value)
       where case when v_term then public.lsa_normalize_term(ke.key)
                  else public.lsa_normalize_answer(ke.key) end = v_given
       limit 1;
    -- array [wert]: nur "bekannt-falsch", kein Label -> generischer Marker
    when 'array' then
      select '__known__'
        into v_slug
        from jsonb_array_elements_text(p_known_errors) as k(w)
       where case when v_term then public.lsa_normalize_term(k.w)
                  else public.lsa_normalize_answer(k.w) end = v_given
       limit 1;
    else
      v_slug := null;
  end case;

  return v_slug;
end;
$$;

--
-- Name: lsa_responses_fehlbild_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX lsa_responses_fehlbild_idx ON public.lsa_responses USING btree (session_id) WHERE (fehlbild_slug IS NOT NULL);

--
-- Name: lsa_responses trg_lsa_fehlbild_capture; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_lsa_fehlbild_capture AFTER INSERT ON public.lsa_responses FOR EACH ROW EXECUTE FUNCTION public.lsa_fehlbild_capture();
