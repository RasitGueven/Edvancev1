-- Lena-Board, Migration 5: vom Team beanstandete Aufgaben (Entscheidung Rasit zu PR 208)
--
-- Hat ein Admin eine Aufgabe beanstandet (lena_beanstande, "Zurueckweisen" bei einer Rueckfrage oder
-- eine eigene Entscheidung "Passt nicht"), kann Lena sie nicht neu bewerten. Sie sieht sie nur lesend
-- mit dem Hinweis "Vom Team beanstandet, wird ueberarbeitet". Nach der Ueberarbeitung setzt der Admin
-- sie per task_status_set auf draft; die Ausgangsfassung faellt weg (Entscheidung 7), und die Aufgabe
-- kommt als offen zu Lena zurueck.
-- Lenas eigenes "Passt nicht" bleibt neu bewertbar.
--
-- "Vom Team" = Status beanstandet und die juengste task_reviews-Zeile stammt von einem Admin oder einem
-- Systemaufruf (geprueft_von leer). Damit die Reihenfolge auch innerhalb einer Transaktion stimmt,
-- schreiben alle Beanstandungs-Wege geprueft_am jetzt als clock_timestamp() (vorher Default now()).
-- Ersetzt (gleiche Signaturen): pruef_sperren, pruef_aufgabe, pruef_entscheiden,
-- pruef_rueckfrage_klaeren, lena_beanstande.

create or replace function public.pruef_team_beanstandet(p_task_id uuid)
returns boolean language sql stable set search_path = public, pg_temp as $$
  select coalesce((
    select t.status = 'beanstandet'
       and coalesce((select r.geprueft_von is null or pr.role = 'admin'
                       from public.task_reviews r
                       left join public.profiles pr on pr.id = r.geprueft_von
                      where r.task_id = t.id
                      order by r.geprueft_am desc limit 1), true)
      from public.tasks t where t.id = p_task_id), false)
$$;

revoke all on function public.pruef_team_beanstandet(uuid) from public, anon, authenticated;

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
  -- Vom Team beanstandet: wird ueberarbeitet, Lena liest nur (Rasit, PR 208).
  if public.pruef_team_beanstandet(p_task_id) then
    perform public.pruef_fehler('team_beanstandet');
  end if;
  return t;
end $$;

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
     and public.pruef_im_pilot(t) and not public.pruef_team_beanstandet(p_task_id) then
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
end $$;

create or replace function public.pruef_rueckfrage_klaeren(
  p_task_id uuid, p_aktion text, p_antwort text, p_gruende text[] default null)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  t public.tasks; v_id uuid; g text;
  gruende text[] := array(select distinct btrim(x) from unnest(coalesce(p_gruende, '{}')) x where btrim(x) <> '');
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'pruef_rueckfrage_klaeren: nur admin' using errcode = '42501';
  end if;
  if p_aktion is null or p_aktion not in ('freigeben', 'zurueckweisen', 'an_lena') then
    raise exception 'pruef_rueckfrage_klaeren: unbekannte Aktion %', p_aktion using errcode = '22023';
  end if;
  select * into t from public.tasks where id = p_task_id for update;
  if not found then
    raise exception 'pruef_rueckfrage_klaeren: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if t.status <> 'rueckfrage' then perform public.pruef_fehler('keine_rueckfrage'); end if;

  if p_aktion = 'freigeben' then
    perform public.task_status_set(p_task_id, 'ready');
  elsif p_aktion = 'zurueckweisen' then
    if cardinality(gruende) = 0 then perform public.pruef_fehler('grund_fehlt'); end if;
    if exists (select 1 from unnest(gruende) x where x not in (
         'aufgabe_fehlerhaft', 'aufgabe_unklar', 'bild_falsch', 'sprache_zu_schwer', 'tablet_umbauen',
         'passt_nicht_in_lsa', 'sonstiges', 'fehlbild_falsch', 'fehlbild_unrealistisch',
         'zahlen_unguenstig', 'formulierung', 'didaktisch', 'kontext', 'loesung_passt_nicht')) then
      perform public.pruef_fehler('grund_unbekannt');
    end if;
    update public.tasks set status = 'beanstandet', reviewed_by = null, reviewed_at = null where id = p_task_id;
    foreach g in array gruende loop
      insert into public.task_reviews (task_id, kategorie, notiz, geprueft_von, geprueft_am)
      values (p_task_id, g, nullif(btrim(p_antwort), ''), auth.uid(), clock_timestamp());
    end loop;
  else
    update public.tasks set status = 'draft', reviewed_by = null, reviewed_at = null where id = p_task_id;
    delete from public.task_pruefung_ausgang where task_id = p_task_id;
  end if;

  select p.id into v_id from public.task_pruefungen p where p.task_id = p_task_id
   order by p.geprueft_am desc limit 1;
  if v_id is not null then
    update public.task_pruefungen
       set antwort = nullif(btrim(p_antwort), ''), beantwortet_von = auth.uid(), beantwortet_am = now()
     where id = v_id;
  end if;

  return jsonb_build_object('status', (select x.status from public.tasks x where x.id = p_task_id));
end $$;

create or replace function public.lena_beanstande(p_task_id uuid, p_kategorie text, p_notiz text default null)
returns integer language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if not (public.get_my_role() is not distinct from 'admin' or public.ist_systemaufruf()) then
    raise exception 'A20: Beanstandungen nur admin' using errcode = '42501';
  end if;
  perform 1 from public.tasks where id = p_task_id for update;
  if not found then
    raise exception 'A20: Aufgabe % nicht gefunden', p_task_id using errcode = 'P0002';
  end if;
  update public.tasks
     set status = 'beanstandet', reviewed_by = null, reviewed_at = null
   where id = p_task_id;
  insert into public.task_reviews (task_id, kategorie, notiz, geprueft_von, geprueft_am)
    values (p_task_id, p_kategorie, p_notiz, auth.uid(), clock_timestamp());
  return 1;
end $$;
