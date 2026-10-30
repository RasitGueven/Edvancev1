-- LSA-Taschenrechner (Auftrag 30.10.2026): Hilfsmittel je Aufgabe statt nur global.
--
-- Die App stellt den Rechner nur bei freigegebenen Aufgaben bereit. Das Kind bringt keinen eigenen mehr
-- mit, deshalb gilt global nur noch „Stift und Zettel“.
--
-- 1. tasks.taschenrechner (false = kein Rechner), gesetzt für fünf Näherungsaufgaben, die ohne Rechner
--    nicht sinnvoll lösbar sind. Sie gehören zu den 42 Aufgaben aus zahl_wurzel_* und term_binom_*; die
--    übrigen 37 bleiben false (docs/lsa/methoden-aufgaben-rechner.md).
-- 2. lsa_question_payload liefert das Feld aus. Über die Funktion erreicht es auch platz_next, platz_submit,
--    lsa_start, lsa_submit, task_preview_payload, session_payload und aufgabe_payload; die Session wertet es
--    nicht aus. Aufgaben mit question_payload.format tragen es nicht, ein fehlendes Feld heißt also „kein
--    Rechner“. Es ist kein Lösungsfeld.
-- 3. Prüfansicht: pruef_aufgabe zeigt das Feld, pruef_taschenrechner_setzen ändert es.
--
-- calculator_opened braucht keine Schemaänderung: lsa_submit speichert p_response bzw. p_response -> nr
-- wortwörtlich, die App legt das Flag nur in LSA-Abgaben direkt in das Antwortobjekt (Beleg: supabase/tests/lsa_taschenrechner.test.sql).

alter table public.tasks add column taschenrechner boolean not null default false;

comment on column public.tasks.taschenrechner is
  'Hilfsmittel: true = das Kind darf bei dieser Aufgabe den Rechner der App nutzen. Geht als taschenrechner in lsa_question_payload.';

-- Schreibt nur das Flag; Text, Lösung und Status bleiben. Der Trigger tasks_pruef_version zählt die Version hoch.
update public.tasks
   set taschenrechner = true
 where id in (
   '0b9229a0-db38-4fc4-8b64-1213b5198f50',  -- Berechne √30, zwei Stellen
   '9af2a3ce-78dc-48b8-b5bc-c50b2fc1f9bd',  -- Berechne √0,9, zwei Stellen
   'cd35f4b2-62da-4f01-9215-bc9504f8e67a',  -- Beet 11 m², Seite auf zwei Stellen
   'fde9c9a1-f05a-42ff-ab98-d94ee6894d07',  -- Berechne √10, eine Stelle
   '81015f65-8ac0-4ef3-abb8-9a7b87c44940'   -- Teppich 6 m², ganze Zentimeter
 );

alter table public.pruef_einstellungen alter column hilfsmittel set default 'Stift und Zettel';
update public.pruef_einstellungen set hilfsmittel = 'Stift und Zettel';

-- Was im Kopf der Prüfansicht hinter „Erlaubt:“ steht.
create function public.pruef_hilfsmittel(p_taschenrechner boolean) returns text
language sql stable set search_path = public, pg_temp
as $$
  select case when p_taschenrechner then 'Taschenrechner, ' else '' end || e.hilfsmittel
    from public.pruef_einstellungen e limit 1
$$;

create or replace function public.lsa_question_payload(p_task_id uuid)
returns jsonb
language sql
stable security definer
set search_path = public
as $function$
  select jsonb_strip_nulls(
    case
      when t.input_type = 'MULTI_PART' then jsonb_build_object(
        'task_id',    t.id,
        'kind',       'multi_part',
        'themenfeld', public.lsa_themenfeld(t.skill_key),
        'taschenrechner', t.taschenrechner,
        'stem',       coalesce(t.question, ''),
        'assets',     public.lsa_task_assets(t.id),
        'table',      public.lsa_public_table(t.question_payload -> 'table'),
        'parts',      public.lsa_public_parts(t.parts, s.correct_answers)
      )
      when t.input_type = 'MC' then jsonb_build_object(
        'task_id',    t.id,
        'kind',       'mc',
        'themenfeld', public.lsa_themenfeld(t.skill_key),
        'taschenrechner', t.taschenrechner,
        'prompt',     coalesce(t.question, ''),
        'assets',     public.lsa_task_assets(t.id),
        'table',      public.lsa_public_table(t.question_payload -> 'table'),
        'options',    coalesce((
          select jsonb_agg(
                   jsonb_build_object('id', o ->> 'id', 'label', o ->> 'label')
                   order by ord
                 )
            from jsonb_array_elements(
                   case
                     when jsonb_typeof(t.question_payload -> 'options') = 'array'
                       then t.question_payload -> 'options'
                     else '[]'::jsonb
                   end
                 ) with ordinality as e(o, ord)
        ), '[]'::jsonb)
      )
      else jsonb_build_object(
        'task_id',    t.id,
        'kind',       'short_input',
        'themenfeld', public.lsa_themenfeld(t.skill_key),
        'taschenrechner', t.taschenrechner,
        'prompt',     coalesce(t.question, ''),
        'assets',     public.lsa_task_assets(t.id),
        'table',      public.lsa_public_table(t.question_payload -> 'table'),
        'unit',       t.unit,
        'input_hint', public.lsa_input_hint(t.input_type, t.bruch, s.correct_answers, t.unit)
      )
    end
  )
  from tasks t
  left join task_solutions s on s.task_id = t.id
  where t.id = p_task_id
$function$;

create or replace function public.pruef_aufgabe(p_task_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
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
              'hilfsmittel', public.pruef_hilfsmittel(t.taschenrechner)),
    'aufgabe', jsonb_build_object(
      'input_type', t.input_type, 'unit', t.unit, 'status', t.status,
      'lena_status', public.pruef_lena_status(t.status), 'pruef_version', t.pruef_version,
      'ausschluss', ausschluss, 'pilot', t.pruef_pilot, 'taschenrechner', t.taschenrechner,
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

-- Lena: wie jedes Speichern (pruef_sperren: nicht bei freigegebenen Aufgaben). Admin: auch bei freigegebenen,
-- wie tasks_pruefer_guard es vorsieht; pruef_sperren sperrt ready für alle, deshalb hier ein eigener Zweig.
create function public.pruef_taschenrechner_setzen(p_task_id uuid, p_version bigint, p_wert boolean)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare t public.tasks;
begin
  if public.get_my_role() is distinct from 'admin' then
    t := public.pruef_sperren(p_task_id, p_version);
  else
    select * into t from public.tasks where id = p_task_id for update;
    if not found then
      raise exception 'pruefen: Aufgabe nicht gefunden' using errcode = 'P0002';
    end if;
    if t.pruef_version is distinct from p_version then
      raise exception 'pruefen: Die Aufgabe wurde inzwischen geaendert. Bitte neu laden.'
        using errcode = 'ED409', hint = 'version';
    end if;
    if public.pruef_ausschluss(p_task_id) in ('vera8', 'inaktiv', 'typ') then
      perform public.pruef_fehler('ausgeschlossen');
    end if;
  end if;

  update public.tasks set taschenrechner = p_wert where id = p_task_id
  returning * into t;
  return jsonb_build_object('pruef_version', t.pruef_version, 'taschenrechner', t.taschenrechner,
                            'hilfsmittel', public.pruef_hilfsmittel(t.taschenrechner));
end $function$;

revoke all on function public.pruef_hilfsmittel(boolean) from public, anon, authenticated;
revoke all on function public.pruef_taschenrechner_setzen(uuid, bigint, boolean) from public, anon;
grant execute on function public.pruef_taschenrechner_setzen(uuid, bigint, boolean) to authenticated;
