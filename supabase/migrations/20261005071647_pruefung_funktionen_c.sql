-- Lena-Board, Migration 2c: Entwurf anwenden, task_status_set, task_solution_upsert
-- (Entscheidungen 12, 16, 21, 23)

-- ── Typische Fehler eines Teils (NULL = flach) als known_errors {wert: slug} ─
-- p_ids: Option-IDs bei MC bzw. MC-Teil, sonst NULL. Werte, die eine bestehende Gruppe desselben
-- Fehlbilds anfuehren, behalten deren Schreibweisen; sonst pruef_schreibweisen.
create or replace function public.pruef_known_errors(
  p_fehler jsonb, p_teil int, p_ids jsonb, p_acc jsonb, p_acc_alt jsonb, p_einheit text)
returns jsonb language plpgsql stable set search_path = public, pg_temp as $$
declare aus jsonb := '{}'; f jsonb; v jsonb; w text; schl jsonb; alt jsonb;
begin
  for f in select x from jsonb_array_elements(coalesce(p_fehler, '[]')) x loop
    if not exists (select 1 from public.fehlbild_labels where slug = f ->> 'slug') then
      perform public.pruef_fehler('fehlbild_unbekannt');
    end if;
    for v in select x from jsonb_array_elements(coalesce(f -> 'werte', '[]')) x
              where (x ->> 'teil')::int is not distinct from p_teil loop
      w := btrim(v ->> 'wert');
      if coalesce(w, '') = '' then perform public.pruef_fehler('fehler_wert_fehlt'); end if;
      if p_ids is not null then
        if not p_ids @> jsonb_build_array(w) then perform public.pruef_fehler('mc_unbekannt'); end if;
        schl := jsonb_build_array(w);
      else
        alt := coalesce((select jsonb_agg(g) from (
                 select jsonb_array_elements(gruppen) g from public.pruef_fehler_gruppen(p_acc)
                  where slug = f ->> 'slug' and teil is not distinct from p_teil
                 union all
                 select jsonb_array_elements(gruppen) from public.pruef_fehler_gruppen(p_acc_alt)
                  where slug = f ->> 'slug' and teil is not distinct from p_teil) q), '[]');
        schl := public.pruef_werte_schreiben(jsonb_build_array(w), alt, p_einheit, true);
      end if;
      -- Schon vergebene Schluessel behalten ihr Fehlbild.
      aus := coalesce((select jsonb_object_agg(k, f ->> 'slug') from jsonb_array_elements_text(schl) k), '{}') || aus;
    end loop;
  end loop;
  return aus;
end $$;

-- Werte als "Wert Einheit" (Einheit muss dabei sein): lsa_grade ueberspringt jeden Kandidaten
-- mit anderer Einheit als acceptance.unit.
create or replace function public.pruef_mit_einheit(p_liste jsonb, p_einheit text)
returns jsonb language sql immutable as $$
  select coalesce(jsonb_agg(to_jsonb(x) order by i), '[]') from (
    select x, min(i) i from (
      select case when public.pruef_ist_zahl(v) and public.pruef_einheit_von(v) is null
                  then public.pruef_zahl_von(v) || ' ' || p_einheit else v end x, i
        from jsonb_array_elements_text(coalesce(p_liste, '[]')) with ordinality e(v, i)) a
    group by x) b
$$;

-- ── 16 · Lenas Entwurf auf eine Fassung anwenden (schreibt nichts) ──────────
-- Liest aus dem Entwurf ausschliesslich werte, mc, regel, fehler, skill_key und afb. Alles andere
-- (Text, Typ, Optionen, Teile, Einheit, Bilder, Status) ist hier gar nicht erreichbar.
create or replace function public.pruef_entwurf_anwenden(
  p_task public.tasks, p_jetzt jsonb, p_ausgang jsonb, p_entwurf jsonb, p_option_scores jsonb)
returns jsonb language plpgsql stable set search_path = public, pg_temp as $$
declare
  it       text := p_task.input_type;
  e        jsonb := coalesce(p_entwurf, '{}');
  ca       jsonb := coalesce(p_jetzt -> 'correct_answers', '[]');
  acc0     jsonb := nullif(p_jetzt -> 'acceptance', 'null'::jsonb);
  acc      jsonb := nullif(p_jetzt -> 'acceptance', 'null'::jsonb);
  acc_alt  jsonb := nullif(p_ausgang -> 'acceptance', 'null'::jsonb);
  te       jsonb := coalesce(nullif(p_jetzt -> 'typical_errors', 'null'::jsonb), '[]');
  flach    boolean := public.pruef_flach_regel(it, acc0);
  regel_ok boolean := public.pruef_regel_erlaubt(it, coalesce(p_jetzt -> 'correct_answers', '[]'), acc0);
  einheit  text := public.pruef_einheit(acc0, coalesce(p_jetzt -> 'correct_answers', '[]'));
  regel    jsonb := nullif(e -> 'regel', 'null'::jsonb);
  pflicht  boolean := coalesce((acc0 ->> 'unit_graded')::boolean, false);
  bereich  boolean := false;
  mitte    text;
  tol      numeric;
  sk       text := p_jetzt ->> 'skill_key';
  afb      text := p_jetzt ->> 'afb';
  sr       jsonb := coalesce(p_jetzt -> 'sondierrang', 'null');
  p jsonb; nr text; liste jsonb; ids jsonb; scope jsonb; ke jsonb;
begin
  -- Teilangaben der typischen Fehler muessen zu den Teilen passen.
  if exists (select 1 from jsonb_array_elements(coalesce(e -> 'fehler', '[]')) f,
                           jsonb_array_elements(coalesce(f -> 'werte', '[]')) v
              where case when it = 'MULTI_PART'
                         then not exists (select 1 from jsonb_array_elements(p_task.parts) q
                                           where q ->> 'nr' = v ->> 'teil')
                         else v ->> 'teil' is not null end) then
    perform public.pruef_fehler('teil_unbekannt');
  end if;

  -- Richtige Antwort
  if it = 'MC' and (e ? 'mc' or e ? 'werte') then
    liste := jsonb_build_array(coalesce(e ->> 'mc', e #>> '{werte,0,werte,0}'));
    ids := coalesce((select jsonb_agg(o -> 'id') from jsonb_array_elements(
             coalesce(p_task.question_payload -> 'options', '[]')) o), '[]');
    if liste ->> 0 is null or not ids @> liste then perform public.pruef_fehler('mc_unbekannt'); end if;
    if jsonb_typeof(p_option_scores) = 'object' and p_option_scores <> '{}' and liste is distinct from ca then
      perform public.pruef_fehler('options_bewertet');
    end if;
    ca := liste;
  elsif it = 'MULTI_PART' and e ? 'werte' then
    for p in select x from jsonb_array_elements(p_task.parts) x loop
      nr := p ->> 'nr';
      liste := (select x -> 'werte' from jsonb_array_elements(e -> 'werte') x where x ->> 'teil' = nr limit 1);
      continue when liste is null;
      liste := public.pruef_werte_schreiben(liste, '[]', null, false);
      if p ->> 'kind' = 'mc' then
        ids := coalesce((select jsonb_agg(o -> 'id') from jsonb_array_elements(coalesce(p -> 'options', '[]')) o), '[]');
        if not ids @> liste then perform public.pruef_fehler('mc_unbekannt'); end if;
        if jsonb_typeof(p_option_scores -> nr) = 'object' and (p_option_scores -> nr) <> '{}'
           and liste is distinct from ca -> nr then
          perform public.pruef_fehler('options_bewertet');
        end if;
      end if;
      ca := case when jsonb_typeof(ca) = 'object' then ca else '{}' end || jsonb_build_object(nr, liste);
    end loop;
  elsif e ? 'werte' then
    liste := coalesce((select x -> 'werte' from jsonb_array_elements(e -> 'werte') x limit 1), '[]');
    ca := case when flach
      then public.pruef_werte_schreiben(liste,
             public.pruef_gruppen(ca) || public.pruef_gruppen(coalesce(p_ausgang -> 'correct_answers', '[]')),
             einheit, true)
      else public.pruef_werte_schreiben(liste, '[]', null, false) end;
  end if;

  -- Gewertet wird (nur flach mit Regel)
  if regel is not null and it not in ('MC', 'MULTI_PART', 'TERM') then
    if regel ->> 'art' = 'bereich' then
      mitte := public.pruef_zahl_von(regel ->> 'mitte');
      begin
        tol := replace(regel ->> 'toleranz', ',', '.')::numeric;
      exception when others then
        tol := null;
      end;
      -- Der Bereich bleibt um den Wert: hoechstens so breit wie der Wert selbst (mindestens 1).
      if not regel_ok or mitte is null or tol is null or tol <= 0
         or tol > greatest(abs((public.lsa_parse_fraction(mitte))[1] / (public.lsa_parse_fraction(mitte))[2]), 1) then
        perform public.pruef_fehler('bereich_ungueltig');
      end if;
      bereich := true;
    end if;
    if coalesce((regel ->> 'einheit_pflicht')::boolean, false) <> pflicht then
      if not regel_ok then perform public.pruef_fehler('einheit_unzulaessig'); end if;
      if not pflicht and einheit is null then perform public.pruef_fehler('einheit_fehlt'); end if;
      if not pflicht and coalesce(btrim(p_task.unit), '') <> '' then perform public.pruef_fehler('einheit_am_feld'); end if;
      pflicht := not pflicht;
    end if;
  end if;

  -- acceptance: richtige Antwort, Regel, typische Fehler
  if it = 'MULTI_PART' then
    for p in select x from jsonb_array_elements(p_task.parts) x loop
      nr := p ->> 'nr';
      scope := nullif(acc -> nr, 'null'::jsonb);
      liste := case when jsonb_typeof(ca -> nr) = 'array' then ca -> nr else '[]' end;
      ke := case when e ? 'fehler'
        then public.pruef_known_errors(e -> 'fehler', nr::int,
               case when p ->> 'kind' = 'mc' then coalesce((select jsonb_agg(o -> 'id')
                 from jsonb_array_elements(coalesce(p -> 'options', '[]')) o), '[]') end,
               acc0, acc_alt, null)
        else scope -> 'known_errors' end;
      continue when scope is null and (coalesce(ke, '{}') = '{}' or jsonb_array_length(liste) = 0);
      scope := public.pruef_liste_setzen(coalesce(scope, '{}'), liste);
      scope := case when coalesce(ke, '{}') = '{}' then scope - 'known_errors'
                    else scope || jsonb_build_object('known_errors', ke) end;
      acc := coalesce(acc, '{}') || jsonb_build_object(nr, scope);
    end loop;
  elsif it = 'MC' then
    ke := case when e ? 'fehler'
      then public.pruef_known_errors(e -> 'fehler', null, coalesce((select jsonb_agg(o -> 'id')
             from jsonb_array_elements(coalesce(p_task.question_payload -> 'options', '[]')) o), '[]'),
             acc0, acc_alt, null)
      else acc -> 'known_errors' end;
    if acc is not null or coalesce(ke, '{}') <> '{}' then
      acc := public.pruef_liste_setzen(coalesce(acc, '{}'), ca);
      acc := case when coalesce(ke, '{}') = '{}' then acc - 'known_errors'
                  else acc || jsonb_build_object('known_errors', ke) end;
    end if;
  elsif flach then
    if bereich then
      acc := acc || jsonb_build_object(
        'canonical', mitte || case when pflicht then ' ' || einheit else '' end,
        'equivalents', '[]'::jsonb,
        'tolerance', jsonb_build_object('mode', 'absolute', 'value', tol));
    else
      acc := public.pruef_liste_setzen(acc, case when pflicht then public.pruef_mit_einheit(ca, einheit) else ca end);
      if regel is not null and acc #>> '{tolerance,mode}' = 'absolute' then acc := acc - 'tolerance'; end if;
    end if;
    if pflicht then
      acc := (acc || jsonb_build_object('unit_graded', true, 'unit', einheit)) #- '{notation,unit_optional}';
      if acc -> 'notation' = '{}'::jsonb then acc := acc - 'notation'; end if;
    elsif regel is not null then
      acc := acc - 'unit_graded';
    end if;
    if e ? 'fehler' then
      ke := public.pruef_known_errors(e -> 'fehler', null, null, acc0, acc_alt, einheit);
      acc := case when ke = '{}' then acc - 'known_errors' else acc || jsonb_build_object('known_errors', ke) end;
    end if;
  end if;
  -- TERM und flach ohne Regel: acceptance bleibt, wie es ist (TERM darf keins tragen, OP-3).

  -- Saetze zu den typischen Fehlern (typical_errors[].fehlbild)
  if e ? 'fehler' and (it in ('MC', 'MULTI_PART') or flach) then
    te := coalesce((select jsonb_agg(case when coalesce(t ->> 'fehlbild', '') = '' then t
                                          else t || jsonb_build_object('error', fl.satz) end order by i)
                      from jsonb_array_elements(te) with ordinality q(t, i)
                      left join lateral (select nullif(btrim(fx ->> 'text'), '') satz
                                           from jsonb_array_elements(e -> 'fehler') fx
                                          where fx ->> 'slug' = t ->> 'fehlbild' limit 1) fl on true
                     where coalesce(t ->> 'fehlbild', '') = '' or fl.satz is not null), '[]');
    te := te || coalesce((select jsonb_agg(jsonb_build_object('error', btrim(fx ->> 'text'),
                                   'socratic_question', '', 'fehlbild', fx ->> 'slug') order by i)
                            from jsonb_array_elements(e -> 'fehler') with ordinality q(fx, i)
                           where coalesce(btrim(fx ->> 'text'), '') <> ''
                             and not exists (select 1 from jsonb_array_elements(te) t
                                              where t ->> 'fehlbild' = fx ->> 'slug')), '[]');
  end if;

  -- Einordnung
  if e ? 'skill_key' and (e ->> 'skill_key') is distinct from sk then
    if not exists (select 1 from jsonb_array_elements(public.pruef_fertigkeit_optionen(
                     coalesce(p_ausgang ->> 'skill_key', sk))) o where o ->> 'key' = e ->> 'skill_key') then
      perform public.pruef_fehler('fertigkeit_unzulaessig');
    end if;
    sk := e ->> 'skill_key';
    -- Der Sondierrang gilt nur fuer die Fertigkeit, fuer die er berechnet wurde.
    sr := case when sk = p_ausgang ->> 'skill_key' then coalesce(p_ausgang -> 'sondierrang', 'null') else 'null' end;
  end if;
  if e ? 'afb' and (e ->> 'afb') is distinct from afb then
    if coalesce(e ->> 'afb', '') not in ('I', 'II', 'III') then perform public.pruef_fehler('afb_ungueltig'); end if;
    afb := e ->> 'afb';
  end if;

  if acc is not null and not public.lsa_acceptance_valid(acc) then
    perform public.pruef_fehler('regel_ungueltig');
  end if;
  return jsonb_build_object('skill_key', sk, 'afb', afb, 'sondierrang', sr,
    'correct_answers', ca, 'acceptance', acc, 'typical_errors', te);
end $$;

revoke all on function public.pruef_known_errors(jsonb, int, jsonb, jsonb, jsonb, text),
  public.pruef_mit_einheit(jsonb, text),
  public.pruef_entwurf_anwenden(public.tasks, jsonb, jsonb, jsonb, jsonb)
  from public, anon, authenticated;

-- ── 12 · task_status_set: Gate ausgelagert, Ausgangsfassung beim Zuruecksetzen ─
-- Unveraendert: setzt nur draft, review, ready; P0001 mit demselben Text wie bisher (die
-- freigabe_*-Schleifen fangen genau P0001). Neu: setzt ein Admin eine Aufgabe von review,
-- rueckfrage oder beanstandet zurueck auf draft, faellt ihre Ausgangsfassung weg; die naechste
-- entsteht beim naechsten Oeffnen. Der Pruefer-Zweig faellt erst mit Migration 3 weg.
create or replace function public.task_status_set(p_task_id uuid, p_status text)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_task  tasks%rowtype;
  v_admin boolean := public.get_my_role() is not distinct from 'admin'
                     or public.ist_systemaufruf();
  v_gate  text;
begin
  if not (v_admin or public.darf_pruefen()) then
    raise exception 'task_status_set: kein Pruefrecht' using errcode = '42501';
  end if;
  if p_status not in ('draft', 'review', 'ready') then
    raise exception 'task_status_set: unbekannter Status %', p_status using errcode = '22023';
  end if;
  -- for update: sonst liest ein Pruefer 'review', waehrend admin gerade freigibt.
  select * into v_task from tasks where id = p_task_id for update;
  if not found then
    raise exception 'task_status_set: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if not v_admin and (p_status = 'ready' or v_task.status = 'ready') then
    raise exception 'task_status_set: freigeben und zuruecknehmen nur admin' using errcode = '42501';
  end if;
  if p_status in ('review', 'ready') then
    v_gate := public.freigabe_gate_fehler(p_task_id);
    if v_gate is not null then
      raise exception '%', v_gate using errcode = 'P0001';
    end if;
  end if;

  update tasks
     set status      = p_status,
         reviewed_by = case when p_status = 'ready' then auth.uid() else null end,
         reviewed_at = case when p_status = 'ready' then now()      else null end
   where id = p_task_id;

  if v_admin and p_status = 'draft' and v_task.status in ('review', 'rueckfrage', 'beanstandet') then
    delete from task_pruefung_ausgang where task_id = p_task_id;
  end if;

  return jsonb_build_object('ok', true, 'task_id', p_task_id, 'status', p_status);
end $$;

-- ── 23 · task_solution_upsert: acceptance an correct_answers angleichen ──────
-- Der Editor schickt nur correct_answers. Steht schon ein canonical (flach oder je Teil), gilt
-- danach canonical = erster Eintrag, equivalents = uebrige; alles andere bleibt. Nicht fuer TERM.
-- Sonst unveraendert; der Pruefer-Zweig faellt erst mit Migration 3 weg.
create or replace function public.task_solution_upsert(
  p_task_id uuid, p_correct_answers jsonb default null, p_solution text default null,
  p_hints jsonb default null, p_coach_hints jsonb default null, p_typical_errors jsonb default null,
  p_beleg jsonb default null, p_acceptance jsonb default null, p_option_scores jsonb default null)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_admin  boolean := public.get_my_role() is not distinct from 'admin'
                      or public.ist_systemaufruf();
  v_status text;
  v_typ    text;
  v_alt    jsonb;
begin
  if not (v_admin or public.darf_pruefen()) then
    raise exception 'task_solution_upsert: kein Pruefrecht' using errcode = '42501';
  end if;
  select status, input_type into v_status, v_typ from tasks where id = p_task_id for update;
  if not found then
    raise exception 'task_solution_upsert: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if not v_admin and v_status = 'ready' then
    raise exception 'task_solution_upsert: eine freigegebene Aufgabe aendert nur admin'
      using errcode = '42501';
  end if;
  if p_beleg is not null and jsonb_typeof(p_beleg) not in ('array', 'null') then
    raise exception 'task_solution_upsert: beleg muss ein Array sein (oder JSON-null zum Leeren)'
      using errcode = '22023';
  end if;
  if p_correct_answers is not null and p_acceptance is null and v_typ is distinct from 'TERM' then
    select acceptance into v_alt from task_solutions where task_id = p_task_id;
    if v_alt is not null and public.pruef_acceptance_angleichen(v_alt, p_correct_answers) is distinct from v_alt then
      p_acceptance := public.pruef_acceptance_angleichen(v_alt, p_correct_answers);
    end if;
  end if;
  if p_acceptance is not null and jsonb_typeof(p_acceptance) <> 'null'
     and not public.lsa_acceptance_valid(p_acceptance) then
    raise exception 'task_solution_upsert: acceptance verletzt den Strukturvertrag '
                    '(canonical fehlt, unbekanntes notation-Flag, tolerance ungueltig '
                    'oder unit_graded zusammen mit unit_optional)'
      using errcode = '22023';
  end if;
  if p_option_scores is not null and jsonb_typeof(p_option_scores) <> 'null'
     and not public.lsa_option_scores_valid(p_option_scores) then
    raise exception 'task_solution_upsert: option_scores verletzt den Strukturvertrag '
                    '(nur voll|teilweise|nicht, hoechstens eine ''voll'' und eine '
                    '''teilweise'' je Aufgabe/Teilaufgabe)'
      using errcode = '22023';
  end if;

  insert into task_solutions as s
    (task_id, correct_answers, solution, hints, coach_hints, typical_errors, beleg,
     acceptance, option_scores, updated_at)
  values
    (p_task_id, coalesce(p_correct_answers, '[]'::jsonb), nullif(p_solution, ''),
     coalesce(p_hints, '[]'::jsonb), coalesce(p_coach_hints, '[]'::jsonb),
     coalesce(p_typical_errors, '[]'::jsonb),
     case when p_beleg is null or jsonb_typeof(p_beleg) = 'null' then null else p_beleg end,
     case when p_acceptance is null or jsonb_typeof(p_acceptance) = 'null' then null else p_acceptance end,
     case when p_option_scores is null or jsonb_typeof(p_option_scores) = 'null' then null else p_option_scores end,
     now())
  on conflict (task_id) do update
     set correct_answers = coalesce(p_correct_answers, s.correct_answers),
         solution        = case when p_solution is null then s.solution else nullif(p_solution, '') end,
         hints           = coalesce(p_hints, s.hints),
         coach_hints     = coalesce(p_coach_hints, s.coach_hints),
         typical_errors  = coalesce(p_typical_errors, s.typical_errors),
         beleg           = case when p_beleg is null then s.beleg
                                when jsonb_typeof(p_beleg) = 'null' then null else p_beleg end,
         acceptance      = case when p_acceptance is null then s.acceptance
                                when jsonb_typeof(p_acceptance) = 'null' then null else p_acceptance end,
         option_scores   = case when p_option_scores is null then s.option_scores
                                when jsonb_typeof(p_option_scores) = 'null' then null else p_option_scores end,
         updated_at      = now();

  return jsonb_build_object('ok', true, 'task_id', p_task_id);
end $$;
