-- Lena-Board, Migration 2d: Lenas Funktionen (Entscheidungen 14 bis 18 und 20)
--
-- Muster 20261004001333_lead_thema_setzen: SECURITY DEFINER, search_path = public, pg_temp, Grant
-- nur an authenticated. Zugang nur mit darf_pruefen() (admin oder coach mit Pruefrecht), sonst 42501.
-- Fehler fuer das Frontend: ED409 = Version veraltet, ED422 = Eingabe ungueltig (HINT = Schluessel).
-- tasks_pruefer_guard und task_solutions_zahlen_guard greifen in Definer-Funktionen nicht; den
-- Schutz liefern die Koerper: geschrieben werden nur correct_answers, acceptance, typical_errors,
-- skill_key, afb, sondierrang und status.

-- Laeuft der Pilot (nur_pilot), gehoeren nur markierte Aufgaben dazu, auch ueber die direkte Adresse.
create or replace function public.pruef_im_pilot(p_task public.tasks)
returns boolean language sql stable set search_path = public, pg_temp as $$
  select p_task.pruef_pilot
      or not coalesce((select e.nur_pilot from public.pruef_einstellungen e limit 1), false)
$$;

-- Zugang, Sperre, Version, Status. Gibt die gesperrte Zeile zurueck.
create or replace function public.pruef_sperren(p_task_id uuid, p_version bigint)
returns public.tasks language plpgsql set search_path = public, pg_temp as $$
declare t public.tasks;
begin
  if not public.darf_pruefen() then
    raise exception 'pruefen: kein Pruefrecht' using errcode = '42501';
  end if;
  select * into t from public.tasks where id = p_task_id for update;
  if not found then
    raise exception 'pruefen: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if t.pruef_version is distinct from p_version then
    raise exception 'pruefen: Die Aufgabe wurde inzwischen geaendert. Bitte neu laden.'
      using errcode = 'ED409', hint = 'version';
  end if;
  if t.status = 'ready' then perform public.pruef_fehler('freigegeben'); end if;
  if public.pruef_ausschluss(p_task_id) in ('vera8', 'inaktiv', 'typ')
     or not public.pruef_im_pilot(t) then
    perform public.pruef_fehler('ausgeschlossen');
  end if;
  return t;
end $$;

-- ── 14 · Das Board: eine Zeile je Aufgabe, eine Abfrage ─────────────────────
-- Thema und Reihenfolge folgen der Fertigkeit der Ausgangsfassung: eine Aufgabe bleibt bis zur
-- Freigabe in ihrem Thema, auch wenn Lena die Fertigkeit aendert.
create or replace function public.pruef_board()
returns table (task_id uuid, stufe text, thema_key text, thema_label text, thema_sort int,
               skill_key text, skill_label text, kurztitel text, reihenfolge bigint,
               lena_status text, geaendert boolean, letzte_dauer_sek int)
language plpgsql stable security definer set search_path = public, pg_temp as $$
begin
  if not public.darf_pruefen() then
    raise exception 'pruef_board: kein Pruefrecht' using errcode = '42501';
  end if;
  return query
  with b as (
    select t.id, t.title, t.status, t.source_ref, t.skill_key sk_jetzt,
           coalesce(a.ausgang ->> 'skill_key', t.skill_key) sk,
           case when a.task_id is not null then (a.ausgang ->> 'sondierrang')::int else t.sondierrang end sr
      from public.tasks t
      left join public.task_pruefung_ausgang a on a.task_id = t.id
     where public.pruef_ausschluss(t.id) is null
       and (t.pruef_pilot or not coalesce((select e.nur_pilot from public.pruef_einstellungen e limit 1), false)))
  select b.id, th.stufe, th.thema_key, th.label, th.sort, b.sk_jetzt, sj.label,
         public.pruef_kurztitel(b.title),
         row_number() over (order by case th.stufe when 'erste' then 1 when 'zweite' then 2 else 3 end,
                                     th.sort nulls last, s.fundament_tiefe, b.sk, b.sr nulls last,
                                     b.source_ref, b.id),
         public.pruef_lena_status(b.status),
         coalesce(jsonb_array_length(lp.aenderungen) > 0, false),
         lp.dauer_sek
    from b
    join public.skills s on s.skill_key = b.sk
    join public.skill_thema st on st.skill_key = b.sk
    join public.themen th on th.thema_key = st.thema_key
    left join public.skills sj on sj.skill_key = b.sk_jetzt
    left join lateral (select p.aenderungen, p.dauer_sek from public.task_pruefungen p
                        where p.task_id = b.id order by p.geprueft_am desc limit 1) lp on true;
end $$;

-- ── 15 · Alles fuer die Pruefkarte ──────────────────────────────────────────
-- VOLATILE: legt beim ersten Oeffnen die Ausgangsfassung an (nur bei status <> 'ready').
create or replace function public.pruef_aufgabe(p_task_id uuid)
returns jsonb language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare
  t public.tasks; s public.task_solutions; aus jsonb; sicht jsonb; sicht_aus jsonb;
  ausschluss text; sk_aus text; th record; lp record;
begin
  if not public.darf_pruefen() then
    raise exception 'pruef_aufgabe: kein Pruefrecht' using errcode = '42501';
  end if;
  select * into t from public.tasks where id = p_task_id;
  if not found then
    raise exception 'pruef_aufgabe: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  ausschluss := public.pruef_ausschluss(p_task_id);
  if t.status <> 'ready' and coalesce(ausschluss, '') not in ('vera8', 'inaktiv', 'typ')
     and public.pruef_im_pilot(t) then
    aus := public.pruef_ausgang_sichern(p_task_id);
  else
    select a.ausgang into aus from public.task_pruefung_ausgang a where a.task_id = p_task_id;
  end if;
  select * into s from public.task_solutions where task_id = p_task_id;
  sicht := public.pruef_sicht(t, public.pruef_fassung(p_task_id));
  sicht_aus := case when aus is not null then public.pruef_sicht(t, aus) end;
  sk_aus := coalesce(aus ->> 'skill_key', t.skill_key);
  select x.thema_key, x.label, x.stufe into th
    from public.skill_thema st join public.themen x on x.thema_key = st.thema_key
   where st.skill_key = sk_aus;
  select * into lp from public.task_pruefungen where task_id = p_task_id order by geprueft_am desc limit 1;

  return jsonb_build_object(
    'task_id', t.id,
    'kopf', jsonb_build_object('kurztitel', public.pruef_kurztitel(t.title), 'stufe', th.stufe,
              'thema_key', th.thema_key, 'thema_label', th.label,
              'hilfsmittel', (select e.hilfsmittel from public.pruef_einstellungen e limit 1)),
    'aufgabe', jsonb_build_object(
      'input_type', t.input_type, 'unit', t.unit, 'status', t.status,
      'lena_status', public.pruef_lena_status(t.status), 'pruef_version', t.pruef_version,
      'ausschluss', ausschluss, 'pilot', t.pruef_pilot,
      'parts', coalesce((select jsonb_agg(jsonb_build_object('nr', (p ->> 'nr')::int, 'kind', p ->> 'kind',
                 'prompt', p ->> 'prompt', 'unit', p ->> 'unit',
                 'options', coalesce((select jsonb_agg(jsonb_build_object('id', o ->> 'id', 'label', o ->> 'label') order by i)
                                        from jsonb_array_elements(coalesce(p -> 'options', '[]')) with ordinality z(o, i)), '[]'))
                 order by k) from jsonb_array_elements(t.parts) with ordinality q(p, k)), '[]'),
      'optionen', coalesce((select jsonb_agg(jsonb_build_object('id', o ->> 'id', 'label', o ->> 'label') order by i)
                              from jsonb_array_elements(case when t.input_type = 'MC'
                                     then coalesce(t.question_payload -> 'options', '[]') else '[]' end)
                                   with ordinality z(o, i)), '[]'),
      'bild_vorhanden', jsonb_array_length(t.assets) > 0
                        or exists (select 1 from public.task_figures f where f.task_id = t.id and f.svg_hash is not null)),
    'werte', sicht -> 'werte', 'mc', sicht -> 'mc', 'regel', sicht -> 'regel',
    'fehler', coalesce((select jsonb_agg(f || jsonb_build_object('klartext', fl.klartext) order by f ->> 'slug')
                          from jsonb_array_elements(sicht -> 'fehler') f
                          left join public.fehlbild_labels fl on fl.slug = f ->> 'slug'), '[]'),
    'weitere_hinweise', sicht -> 'weitere_hinweise',
    'flach_regel', sicht -> 'flach_regel', 'ohne_erkennung', sicht -> 'ohne_erkennung',
    'loesungsweg', s.solution,
    'fertigkeit', (select jsonb_build_object('key', k.skill_key, 'label', k.label, 'thema_key', x.thema_key,
                     'thema_label', x.label, 'stufe', x.stufe,
                     'voraussetzungen', coalesce((select jsonb_agg(v.label order by v.fundament_tiefe, v.skill_key)
                                                    from public.skill_kante sk join public.skills v on v.skill_key = sk.voraussetzt_skill_key
                                                   where sk.skill_key = k.skill_key), '[]'))
                     from public.skills k
                     left join public.skill_thema st on st.skill_key = k.skill_key
                     left join public.themen x on x.thema_key = st.thema_key
                    where k.skill_key = t.skill_key),
    'fertigkeit_optionen', public.pruef_fertigkeit_optionen(sk_aus),
    'afb', t.afb, 'afb_sicher', t.vorbefuellt #>> '{afb,sicher}',
    'ausgang', sicht_aus,
    'aenderungen', case when sicht_aus is not null then public.pruef_aenderungen(sicht_aus, sicht) else '[]'::jsonb end,
    'letzte_pruefung', case when lp.id is not null then jsonb_build_object(
      'entscheidung', lp.entscheidung, 'gruende', to_jsonb(lp.gruende), 'notiz', lp.notiz,
      'antwort', lp.antwort, 'beantwortet_am', lp.beantwortet_am, 'geprueft_am', lp.geprueft_am) end,
    'auffaelligkeiten', public.pruef_auffaelligkeiten(t, coalesce(s.correct_answers, '[]'), s.acceptance, s.solution));
end $$;

-- ── 16 · Speichern (gesammelt, entprellt; kein Statuswechsel) ──────────────
create or replace function public.pruef_speichern(p_task_id uuid, p_version bigint, p_entwurf jsonb)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare t public.tasks; aus jsonb; jetzt jsonb; neu jsonb; os jsonb; sol text;
begin
  t := public.pruef_sperren(p_task_id, p_version);
  aus := public.pruef_ausgang_sichern(p_task_id);
  jetzt := public.pruef_fassung(p_task_id);
  select option_scores, solution into os, sol from public.task_solutions where task_id = p_task_id;
  neu := public.pruef_entwurf_anwenden(t, jetzt, aus, p_entwurf, os);

  if (neu -> 'correct_answers', neu -> 'acceptance', neu -> 'typical_errors')
     is distinct from (jetzt -> 'correct_answers', jetzt -> 'acceptance', jetzt -> 'typical_errors') then
    insert into public.task_solutions as x (task_id, correct_answers, acceptance, typical_errors, updated_at)
    values (p_task_id, neu -> 'correct_answers', nullif(neu -> 'acceptance', 'null'::jsonb), neu -> 'typical_errors', now())
    on conflict (task_id) do update
      set correct_answers = excluded.correct_answers, acceptance = excluded.acceptance,
          typical_errors = excluded.typical_errors, updated_at = now();
  end if;
  if (neu ->> 'skill_key', neu ->> 'afb', neu -> 'sondierrang')
     is distinct from (jetzt ->> 'skill_key', jetzt ->> 'afb', jetzt -> 'sondierrang') then
    update public.tasks
       set skill_key = neu ->> 'skill_key', afb = neu ->> 'afb', sondierrang = (neu ->> 'sondierrang')::int
     where id = p_task_id;
  end if;

  select * into t from public.tasks where id = p_task_id;
  return jsonb_build_object(
    'pruef_version', t.pruef_version,
    'auffaelligkeiten', public.pruef_auffaelligkeiten(t, neu -> 'correct_answers', neu -> 'acceptance', sol),
    'aenderungen', public.pruef_aenderungen(public.pruef_sicht(t, aus), public.pruef_sicht(t, public.pruef_fassung(p_task_id))));
end $$;

-- ── 17 · Entscheiden ────────────────────────────────────────────────────────
create or replace function public.pruef_entscheiden(
  p_task_id uuid, p_version bigint, p_entscheidung text, p_gruende text[] default null,
  p_notiz text default null, p_aenderung_grund text default null, p_dauer_sek int default null)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  t public.tasks; aus jsonb; aend jsonb; neu text; g text;
  notiz text := nullif(btrim(p_notiz), '');
  grund text := nullif(btrim(p_aenderung_grund), '');
  gruende text[] := array(select distinct btrim(x) from unnest(coalesce(p_gruende, '{}')) x where btrim(x) <> '');
begin
  t := public.pruef_sperren(p_task_id, p_version);
  if p_entscheidung is null or p_entscheidung not in ('passt', 'unsicher', 'passt_nicht') then
    raise exception 'pruef_entscheiden: unbekannte Entscheidung %', p_entscheidung using errcode = '22023';
  end if;
  aus := public.pruef_ausgang_sichern(p_task_id);
  aend := public.pruef_aenderungen(public.pruef_sicht(t, aus), public.pruef_sicht(t, public.pruef_fassung(p_task_id)));
  if jsonb_array_length(aend) > 0 and grund is null
     and coalesce((select e.grund_pflicht from public.pruef_einstellungen e limit 1), false) then
    perform public.pruef_fehler('aenderung_grund_fehlt');
  end if;

  if p_entscheidung = 'passt' then
    if not exists (select 1 from public.task_solutions s where s.task_id = p_task_id
                      and public.lsa_has_answers(t.input_type, t.parts, s.correct_answers)) then
      perform public.pruef_fehler('antwort_fehlt');
    end if;
    if public.freigabe_gate_fehler(p_task_id) is not null then
      perform public.pruef_fehler('gate', public.freigabe_gate_fehler(p_task_id));
    end if;
    neu := 'review';
    gruende := '{}';
  elsif p_entscheidung = 'unsicher' then
    if notiz is null then perform public.pruef_fehler('notiz_fehlt'); end if;
    neu := 'rueckfrage';
    gruende := '{}';
  else
    if cardinality(gruende) = 0 then perform public.pruef_fehler('grund_fehlt'); end if;
    if exists (select 1 from unnest(gruende) x where x not in ('aufgabe_fehlerhaft', 'aufgabe_unklar',
                 'bild_falsch', 'sprache_zu_schwer', 'tablet_umbauen', 'passt_nicht_in_lsa', 'sonstiges')) then
      perform public.pruef_fehler('grund_unbekannt');
    end if;
    if 'sonstiges' = any (gruende) and notiz is null then perform public.pruef_fehler('notiz_fehlt'); end if;
    neu := 'beanstandet';
    foreach g in array gruende loop
      insert into public.task_reviews (task_id, kategorie, notiz, geprueft_von) values (p_task_id, g, notiz, auth.uid());
    end loop;
  end if;

  -- Lena gibt nie frei: reviewed_by/at bleiben leer, die Freigabe stempelt task_status_set.
  update public.tasks set status = neu, reviewed_by = null, reviewed_at = null where id = p_task_id;
  insert into public.task_pruefungen (task_id, entscheidung, gruende, notiz, aenderungen, aenderung_grund,
                                      dauer_sek, geprueft_von, geprueft_am)
  values (p_task_id, p_entscheidung, gruende, notiz, aend, grund,
          least(greatest(p_dauer_sek, 0), 86400), auth.uid(), clock_timestamp());

  select * into t from public.tasks where id = p_task_id;
  return jsonb_build_object('pruef_version', t.pruef_version, 'lena_status', public.pruef_lena_status(t.status));
end $$;

-- ── 18 · Rueckgaengig: zurueck auf offen, Lenas Aenderungen bleiben ─────────
create or replace function public.pruef_rueckgaengig(p_task_id uuid, p_version bigint)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare t public.tasks; aus jsonb;
begin
  t := public.pruef_sperren(p_task_id, p_version);
  if t.status not in ('review', 'rueckfrage', 'beanstandet') then
    perform public.pruef_fehler('nicht_bewertet');
  end if;
  select a.ausgang into aus from public.task_pruefung_ausgang a where a.task_id = p_task_id;
  update public.tasks set status = 'draft', reviewed_by = null, reviewed_at = null where id = p_task_id;
  insert into public.task_pruefungen (task_id, entscheidung, aenderungen, geprueft_von, geprueft_am)
  values (p_task_id, 'zurueckgenommen',
          case when aus is null then '[]'::jsonb
               else public.pruef_aenderungen(public.pruef_sicht(t, aus), public.pruef_sicht(t, public.pruef_fassung(p_task_id))) end,
          auth.uid(), clock_timestamp());
  select * into t from public.tasks where id = p_task_id;
  return jsonb_build_object('pruef_version', t.pruef_version, 'lena_status', public.pruef_lena_status(t.status));
end $$;

-- ── 20 · Antwort ausprobieren: dieselbe Wertung wie die Engine ─────────────
-- Baut correct_answers und acceptance aus dem Entwurf (pruef_entwurf_anwenden), schreibt nichts.
-- Urteil: flach lsa_grade, TERM/MC lsa_is_correct, Teil lsa_is_correct mit lsa_part_answer.
-- Fehlbild wie lsa_fehlbild_capture: nur wenn lsa_is_correct auf correct_answers false liefert.
create or replace function public.pruef_wertung_testen(
  p_task_id uuid, p_teil int, p_antwort text, p_entwurf jsonb default null)
returns jsonb language plpgsql stable security definer set search_path = public, pg_temp as $$
declare
  t public.tasks; aus jsonb; neu jsonb; ca jsonb; acc jsonb; kind text; resp jsonb; ke jsonb;
  richtig boolean; stufe text; v_slug text; p jsonb; h text;
begin
  if not public.darf_pruefen() then
    raise exception 'pruef_wertung_testen: kein Pruefrecht' using errcode = '42501';
  end if;
  select * into t from public.tasks where id = p_task_id;
  if not found then
    raise exception 'pruef_wertung_testen: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if coalesce(btrim(p_antwort), '') = '' then return jsonb_build_object('stufe', null); end if;
  select a.ausgang into aus from public.task_pruefung_ausgang a where a.task_id = p_task_id;
  begin
    neu := public.pruef_entwurf_anwenden(t, public.pruef_fassung(p_task_id), coalesce(aus, public.pruef_fassung(p_task_id)),
             p_entwurf, (select option_scores from public.task_solutions where task_id = p_task_id));
  exception when sqlstate 'ED422' then
    get stacked diagnostics h = pg_exception_hint;
    return jsonb_build_object('stufe', null, 'fehler', h);
  end;
  ca := neu -> 'correct_answers';
  acc := nullif(neu -> 'acceptance', 'null'::jsonb);

  if t.input_type = 'MULTI_PART' then
    select x into p from jsonb_array_elements(t.parts) x where (x ->> 'nr')::int = p_teil;
    if p is null then perform public.pruef_fehler('teil_unbekannt'); end if;
    kind := p ->> 'kind';
    resp := public.lsa_part_answer(kind, to_jsonb(btrim(p_antwort)));
    richtig := coalesce(public.lsa_is_correct(case when kind = 'mc' then 'MC' else 'SHORT_TEXT' end,
                 case when jsonb_typeof(ca -> (p ->> 'nr')) = 'array' then ca -> (p ->> 'nr') else '[]' end, resp), false);
    stufe := case when richtig then 'voll' else 'nicht' end;
    ke := coalesce(acc -> (p ->> 'nr') -> 'known_errors', acc -> 'known_errors');
  else
    kind := lower(t.input_type);
    resp := case when t.input_type = 'MC' then jsonb_build_object('selected', jsonb_build_array(btrim(p_antwort)))
                 else jsonb_build_object('text', p_antwort) end;
    richtig := coalesce(public.lsa_is_correct(t.input_type, ca, resp), false);
    stufe := case when t.input_type in ('MC', 'TERM') then case when richtig then 'voll' else 'nicht' end
                  else public.lsa_grade(t.input_type, acc, ca, resp) end;
    ke := acc -> 'known_errors';
  end if;

  if not richtig then
    v_slug := public.lsa_fehlbild_match(kind, ke, public.lsa_part_answer(kind, resp));
  end if;
  return jsonb_build_object('stufe', stufe, 'fehlbild_slug', v_slug,
    'fehlbild_klartext', (select fl.klartext from public.fehlbild_labels fl where fl.slug = v_slug));
end $$;

revoke all on function public.pruef_sperren(uuid, bigint), public.pruef_im_pilot(public.tasks) from public, anon, authenticated;
revoke all on function public.pruef_board(), public.pruef_aufgabe(uuid),
  public.pruef_speichern(uuid, bigint, jsonb),
  public.pruef_entscheiden(uuid, bigint, text, text[], text, text, int),
  public.pruef_rueckgaengig(uuid, bigint), public.pruef_wertung_testen(uuid, int, text, jsonb)
  from public, anon, authenticated;
grant execute on function public.pruef_board(), public.pruef_aufgabe(uuid),
  public.pruef_speichern(uuid, bigint, jsonb),
  public.pruef_entscheiden(uuid, bigint, text, text[], text, text, int),
  public.pruef_rueckgaengig(uuid, bigint), public.pruef_wertung_testen(uuid, int, text, jsonb)
  to authenticated;
