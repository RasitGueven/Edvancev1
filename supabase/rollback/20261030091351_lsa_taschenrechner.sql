-- Rollback zu 20261030091351_lsa_taschenrechner. Funktionskörper: Prod-Stand vor der Migration.
--
-- Einspielen wie eine Migration (-v ON_ERROR_STOP=1 -1), danach die Zeile 20261030091351 aus
-- supabase_migrations.schema_migrations löschen und tools/schema-snapshot.sh laufen lassen.
-- calculator_opened in lsa_responses.response bleibt stehen (Rohdaten, append-only).

drop function public.pruef_taschenrechner_setzen(uuid, bigint, boolean);

CREATE OR REPLACE FUNCTION public.lsa_question_payload(p_task_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select jsonb_strip_nulls(
    case
      when t.input_type = 'MULTI_PART' then jsonb_build_object(
        'task_id',    t.id,
        'kind',       'multi_part',
        'themenfeld', public.lsa_themenfeld(t.skill_key),
        'stem',       coalesce(t.question, ''),
        'assets',     public.lsa_task_assets(t.id),
        'table',      public.lsa_public_table(t.question_payload -> 'table'),
        'parts',      public.lsa_public_parts(t.parts, s.correct_answers)
      )
      when t.input_type = 'MC' then jsonb_build_object(
        'task_id',    t.id,
        'kind',       'mc',
        'themenfeld', public.lsa_themenfeld(t.skill_key),
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

drop function public.pruef_hilfsmittel(boolean);

alter table public.pruef_einstellungen alter column hilfsmittel set default 'Taschenrechner, Stift und Zettel';
update public.pruef_einstellungen set hilfsmittel = 'Taschenrechner, Stift und Zettel';

alter table public.tasks drop column taschenrechner;
