-- L5.1 Kinder-Hinweise pruefen und freigeben, Teil 3: pruef_aufgabe, pruef_speichern, pruef_entscheiden.
--
-- Grundlage ist die Prod-Fassung (pg_get_functiondef, dbread 06.10.2026); Aenderungen sind mit L5 markiert.
-- Braucht Teil 2 (pruef_hinweise_anwenden, hinweise in pruef_sicht).

-- Prod-Fassung + hinweise (L5). Rollenpruefung: darf_pruefen() ist NULL-sicher (coalesce false),
-- admin per is not distinct from.
CREATE OR REPLACE FUNCTION public.pruef_aufgabe(p_task_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  t public.tasks; s public.task_solutions; aus jsonb; sicht jsonb; sicht_aus jsonb;
  ausschluss text; sk_aus text; th record; lp record;
  admin boolean := public.get_my_role() is not distinct from 'admin';
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
     and (admin or (ausschluss is distinct from 'hand' and public.pruef_im_pilot(t)
                    and not public.pruef_team_beanstandet(p_task_id))) then
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
      'team_beanstandet', public.pruef_team_beanstandet(p_task_id),
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
    'hinweise', coalesce(sicht -> 'hinweise', '[]'),
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
end $function$;

-- Prod-Fassung + Hinweise (L5). Rollenpruefung in pruef_sperren (darf_pruefen, NULL-sicher).
CREATE OR REPLACE FUNCTION public.pruef_speichern(p_task_id uuid, p_version bigint, p_entwurf jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare t public.tasks; aus jsonb; jetzt jsonb; neu jsonb; os jsonb; sol text; nh jsonb;
begin
  t := public.pruef_sperren(p_task_id, p_version);
  aus := public.pruef_ausgang_sichern(p_task_id);
  jetzt := public.pruef_fassung(p_task_id);
  select option_scores, solution into os, sol from public.task_solutions where task_id = p_task_id;
  neu := public.pruef_entwurf_anwenden(t, jetzt, aus, p_entwurf, os);
  nh := public.pruef_hinweise_anwenden(jetzt, p_entwurf);

  if (neu -> 'correct_answers', neu -> 'acceptance', neu -> 'typical_errors')
     is distinct from (jetzt -> 'correct_answers', jetzt -> 'acceptance', jetzt -> 'typical_errors') then
    insert into public.task_solutions as x (task_id, correct_answers, acceptance, typical_errors, updated_at)
    values (p_task_id, neu -> 'correct_answers', nullif(neu -> 'acceptance', 'null'::jsonb), neu -> 'typical_errors', now())
    on conflict (task_id) do update
      set correct_answers = excluded.correct_answers, acceptance = excluded.acceptance,
          typical_errors = excluded.typical_errors, updated_at = now();
  end if;
  -- L5: Hinweise im Entwurf. Der Trigger hinweise_status_folgt_text setzt geaenderte Texte auf entwurf.
  if nh is distinct from coalesce(jetzt -> 'hints', '[]') then
    insert into public.task_solutions as x (task_id, hints, updated_at)
    values (p_task_id, nh, now())
    on conflict (task_id) do update set hints = excluded.hints, updated_at = now();
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
    'hinweise', coalesce(public.pruef_sicht(t, public.pruef_fassung(p_task_id)) -> 'hinweise', '[]'),
    'auffaelligkeiten', public.pruef_auffaelligkeiten(t, neu -> 'correct_answers', neu -> 'acceptance', sol),
    'aenderungen', public.pruef_aenderungen(public.pruef_sicht(t, aus), public.pruef_sicht(t, public.pruef_fassung(p_task_id))));
end $function$;

-- Prod-Fassung + zwei Gruende (L5 Entscheidung 1). Rollenpruefung in pruef_sperren.
CREATE OR REPLACE FUNCTION public.pruef_entscheiden(p_task_id uuid, p_version bigint, p_entscheidung text, p_gruende text[] DEFAULT NULL::text[], p_notiz text DEFAULT NULL::text, p_aenderung_grund text DEFAULT NULL::text, p_dauer_sek integer DEFAULT NULL::integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  t public.tasks; aus jsonb; aend jsonb; neu text; g text;
  notiz text := nullif(btrim(p_notiz), '');
  grund text := nullif(btrim(p_aenderung_grund), '');
  gruende text[] := array(select distinct btrim(x) from unnest(coalesce(p_gruende, '{}')) x where btrim(x) <> '');
begin
  t := public.pruef_sperren(p_task_id, p_version);
  perform public.pruef_lena_sperren(t);
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
                 'bild_falsch', 'sprache_zu_schwer', 'tablet_umbauen', 'passt_nicht_in_lsa', 'sonstiges',
                 'hinweis_verraet_loesung', 'hinweis_passt_nicht')) then
      perform public.pruef_fehler('grund_unbekannt');
    end if;
    if 'sonstiges' = any (gruende) and notiz is null then perform public.pruef_fehler('notiz_fehlt'); end if;
    neu := 'beanstandet';
    foreach g in array gruende loop
      insert into public.task_reviews (task_id, kategorie, notiz, geprueft_von, geprueft_am)
      values (p_task_id, g, notiz, auth.uid(), clock_timestamp());
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
end $function$;
