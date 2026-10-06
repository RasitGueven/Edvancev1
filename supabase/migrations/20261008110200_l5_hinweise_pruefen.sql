-- L5.1 Kinder-Hinweise pruefen und freigeben, Teil 2: Lenas Pruefansicht.
--
-- Grundlage jeder ersetzten Funktion ist die Prod-Fassung (pg_get_functiondef, dbread 06.10.2026).
--   - pruef_fassung traegt die Hinweise (hints), pruef_sicht zeigt sie als hinweise [{stufe, text, status}],
--     pruef_aenderungen meldet geaenderte Texte als Feld 'hinweis' (teil = Stufe). Damit gelten
--     Ausgangsfassung, Aenderungsliste, "geaendert" im Board und die Sammelfreigabe-Regel
--     (pruef_freigabe_erlaubt) auch fuer Hinweise.
--   - Neu: pruef_hinweise_anwenden. pruef_aufgabe und pruef_speichern (Teil 3) nehmen Hinweise im Entwurf an
--     (Schluessel 'hinweise': [{stufe, text}], leerer Text = Stufe entfaellt).
--     Teil 3: pruef_entscheiden kennt die Gruende hinweis_verraet_loesung und hinweis_passt_nicht.
-- Status setzt hier niemand: der Trigger aus E1 laesst unveraenderte Hinweise, wie sie sind, und setzt
-- geaenderte auf entwurf. Lena (Pruefrecht, kein Admin) kommt so nie an geprueft.

-- Prod-Fassung + hints (L5).
CREATE OR REPLACE FUNCTION public.pruef_fassung(p_task_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
  select jsonb_build_object(
    'skill_key', t.skill_key, 'afb', t.afb, 'sondierrang', t.sondierrang,
    'correct_answers', coalesce(s.correct_answers, '[]'), 'acceptance', s.acceptance,
    'typical_errors', coalesce(s.typical_errors, '[]'),
    'hints', coalesce(s.hints, '[]'))
  from public.tasks t left join public.task_solutions s on s.task_id = t.id
  where t.id = p_task_id
$function$;

-- Prod-Fassung + hinweise (L5).
CREATE OR REPLACE FUNCTION public.pruef_sicht(p_task tasks, p_fassung jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  it    text := p_task.input_type;
  ca    jsonb := coalesce(p_fassung -> 'correct_answers', '[]');
  acc   jsonb := nullif(p_fassung -> 'acceptance', 'null'::jsonb);
  te    jsonb := coalesce(nullif(p_fassung -> 'typical_errors', 'null'::jsonb), '[]');
  flach boolean := public.pruef_flach_regel(it, acc);
  werte jsonb;
  regel jsonb;
begin
  if it = 'MULTI_PART' then
    werte := coalesce((select jsonb_agg(jsonb_build_object('teil', (p ->> 'nr')::int, 'werte',
      coalesce((select jsonb_agg(jsonb_build_object('wert', x, 'schreibweisen', jsonb_build_array(x)) order by i)
                  from jsonb_array_elements_text(case when jsonb_typeof(ca -> (p ->> 'nr')) = 'array'
                                                      then ca -> (p ->> 'nr') else '[]' end)
                       with ordinality y(x, i)), '[]')) order by o)
      from jsonb_array_elements(p_task.parts) with ordinality q(p, o)), '[]');
  else
    werte := jsonb_build_array(jsonb_build_object('teil', null, 'werte', coalesce(case when flach then
      (select jsonb_agg(jsonb_build_object('wert', g ->> 0, 'schreibweisen', g) order by i)
         from jsonb_array_elements(public.pruef_gruppen(ca)) with ordinality z(g, i))
    else
      (select jsonb_agg(jsonb_build_object('wert', x, 'schreibweisen', jsonb_build_array(x)) order by i)
         from jsonb_array_elements_text(case when jsonb_typeof(ca) = 'array' then ca else '[]' end)
              with ordinality y(x, i))
    end, '[]')));
  end if;

  if public.pruef_regel_erlaubt(it, ca, acc) then
    regel := jsonb_build_object(
      'art', case when acc #>> '{tolerance,mode}' = 'absolute' then 'bereich' else 'wert' end,
      'mitte', case when acc #>> '{tolerance,mode}' = 'absolute'
                    then coalesce(public.pruef_zahl_von(acc ->> 'canonical'), acc ->> 'canonical') end,
      'toleranz', case when acc #>> '{tolerance,mode}' = 'absolute' then acc #> '{tolerance,value}' end,
      'einheit_pflicht', coalesce((acc ->> 'unit_graded')::boolean, false),
      'einheit', public.pruef_einheit(acc, ca),
      'einheit_am_feld', coalesce(btrim(p_task.unit), '') <> '');
  end if;

  return jsonb_build_object(
    'werte', werte,
    'mc', case when it = 'MC' then ca ->> 0 end,
    'regel', regel,
    'fehler', case when it = 'TERM' then '[]'::jsonb else coalesce((
      select jsonb_agg(jsonb_build_object(
               'slug', f.slug,
               'werte', f.werte,
               'text', (select e ->> 'error' from jsonb_array_elements(te) e
                         where e ->> 'fehlbild' = f.slug limit 1)) order by f.slug)
        from (select fg.slug, jsonb_agg(jsonb_build_object('teil', fg.teil, 'wert', g ->> 0)
                                        order by fg.teil nulls first, g ->> 0) werte
                from public.pruef_fehler_gruppen(acc) fg, jsonb_array_elements(fg.gruppen) g
               group by fg.slug) f), '[]') end,
    'weitere_hinweise', coalesce((select jsonb_agg(e) from jsonb_array_elements(te) e
                                   where coalesce(e ->> 'fehlbild', '') = ''), '[]'),
    -- L5: Kinder-Hinweise in Stufenreihenfolge. Eine Fassung ohne hints (vor L5) liefert null.
    'hinweise', case when jsonb_typeof(p_fassung -> 'hints') = 'array' then coalesce((
      select jsonb_agg(jsonb_build_object('stufe', (h ->> 'level')::int, 'text', h ->> 'text',
                                          'status', coalesce(h ->> 'status', 'entwurf'))
                       order by (h ->> 'level')::int)
        from jsonb_array_elements(p_fassung -> 'hints') h), '[]') end,
    'skill_key', p_fassung ->> 'skill_key',
    'afb', p_fassung ->> 'afb',
    'flach_regel', flach,
    'ohne_erkennung', it = 'TERM' or (it not in ('MC', 'MULTI_PART') and not flach));
end $function$;

-- Prod-Fassung + Feld hinweis (L5).
CREATE OR REPLACE FUNCTION public.pruef_aenderungen(p_vorher jsonb, p_nachher jsonb)
 RETURNS jsonb
 LANGUAGE sql
 IMMUTABLE
AS $function$
  with
  wv as (select (w ->> 'teil')::int teil, coalesce((select jsonb_agg(x ->> 'wert') from jsonb_array_elements(w -> 'werte') x), '[]') l
           from jsonb_array_elements(coalesce(p_vorher -> 'werte', '[]')) w),
  wn as (select (w ->> 'teil')::int teil, coalesce((select jsonb_agg(x ->> 'wert') from jsonb_array_elements(w -> 'werte') x), '[]') l
           from jsonb_array_elements(coalesce(p_nachher -> 'werte', '[]')) w),
  -- L5: Hinweise nur vergleichen, wenn beide Fassungen sie tragen.
  hv as (select (h ->> 'stufe')::int stufe, h ->> 'text' txt
           from jsonb_array_elements(case when jsonb_typeof(p_vorher -> 'hinweise') = 'array'
                                           and jsonb_typeof(p_nachher -> 'hinweise') = 'array'
                                          then p_vorher -> 'hinweise' else '[]' end) h),
  hn as (select (h ->> 'stufe')::int stufe, h ->> 'text' txt
           from jsonb_array_elements(case when jsonb_typeof(p_vorher -> 'hinweise') = 'array'
                                           and jsonb_typeof(p_nachher -> 'hinweise') = 'array'
                                          then p_nachher -> 'hinweise' else '[]' end) h),
  rv as (select nullif(p_vorher -> 'regel', 'null') r), rn as (select nullif(p_nachher -> 'regel', 'null') r),
  fv as (select f ->> 'slug' slug, f - 'slug' || jsonb_build_object('werte', (select jsonb_agg(x order by x ->> 'teil', x ->> 'wert') from jsonb_array_elements(f -> 'werte') x)) f
           from jsonb_array_elements(coalesce(p_vorher -> 'fehler', '[]')) f),
  fn as (select f ->> 'slug' slug, f - 'slug' || jsonb_build_object('werte', (select jsonb_agg(x order by x ->> 'teil', x ->> 'wert') from jsonb_array_elements(f -> 'werte') x)) f
           from jsonb_array_elements(coalesce(p_nachher -> 'fehler', '[]')) f),
  l(n, e) as (
    select 1, jsonb_build_object('feld', 'richtige_antwort', 'teil', coalesce(wv.teil, wn.teil),
                                 'vorher', coalesce(wv.l, '[]'), 'nachher', coalesce(wn.l, '[]'))
      from wv full join wn on coalesce(wv.teil, 0) = coalesce(wn.teil, 0)
     where wv.l is distinct from wn.l
    union all
    select 2, jsonb_build_object('feld', 'wertung', 'teil', null,
             'vorher', rv.r - array['einheit_pflicht', 'einheit', 'einheit_am_feld'],
             'nachher', rn.r - array['einheit_pflicht', 'einheit', 'einheit_am_feld'])
      from rv, rn
     where (rv.r - array['einheit_pflicht', 'einheit', 'einheit_am_feld'])
           is distinct from (rn.r - array['einheit_pflicht', 'einheit', 'einheit_am_feld'])
    union all
    select 3, jsonb_build_object('feld', 'einheit_pflicht', 'teil', null,
             'vorher', coalesce(rv.r -> 'einheit_pflicht', 'false'), 'nachher', coalesce(rn.r -> 'einheit_pflicht', 'false'))
      from rv, rn
     where coalesce(rv.r -> 'einheit_pflicht', 'false') <> coalesce(rn.r -> 'einheit_pflicht', 'false')
    union all
    select 4, jsonb_build_object('feld', 'typischer_fehler', 'teil', null,
             'vorher', case when fv.slug is not null then jsonb_build_object('slug', fv.slug) || fv.f end,
             'nachher', case when fn.slug is not null then jsonb_build_object('slug', fn.slug) || fn.f end)
      from fv full join fn on fv.slug = fn.slug
     where fv.f is distinct from fn.f
    union all
    select 5, jsonb_build_object('feld', 'fertigkeit', 'teil', null,
             'vorher', p_vorher -> 'skill_key', 'nachher', p_nachher -> 'skill_key')
     where p_vorher -> 'skill_key' is distinct from p_nachher -> 'skill_key'
    union all
    select 6, jsonb_build_object('feld', 'anforderungsbereich', 'teil', null,
             'vorher', p_vorher -> 'afb', 'nachher', p_nachher -> 'afb')
     where p_vorher -> 'afb' is distinct from p_nachher -> 'afb'
    union all
    select 7, jsonb_build_object('feld', 'hinweis', 'teil', coalesce(hv.stufe, hn.stufe),
             'vorher', to_jsonb(hv.txt), 'nachher', to_jsonb(hn.txt))
      from hv full join hn on hv.stufe = hn.stufe
     where hv.txt is distinct from hn.txt)
  select coalesce(jsonb_agg(e order by n, e ->> 'teil', e -> 'vorher' ->> 'slug', e -> 'nachher' ->> 'slug'), '[]') from l
$function$;

-- Hinweise aus Lenas Entwurf. p_jetzt ist pruef_fassung. Ohne Schluessel 'hinweise' bleibt alles.
-- Unveraenderte Stufen behalten ihr Objekt samt Status; der Trigger entscheidet den Rest.
create function public.pruef_hinweise_anwenden(p_jetzt jsonb, p_entwurf jsonb)
returns jsonb
language plpgsql
stable
set search_path = public, pg_temp
as $$
declare
  alt jsonb := case when jsonb_typeof(p_jetzt -> 'hints') = 'array' then p_jetzt -> 'hints' else '[]' end;
  e   jsonb := coalesce(p_entwurf, '{}');
  neu jsonb;
  n   int;
begin
  if not (e ? 'hinweise') then
    return alt;
  end if;
  if jsonb_typeof(e -> 'hinweise') <> 'array'
     or exists (select 1 from jsonb_array_elements(e -> 'hinweise') h
                 where jsonb_typeof(h) <> 'object' or jsonb_typeof(h -> 'stufe') <> 'number'
                    or (h ->> 'stufe')::numeric not in (1, 2, 3)
                    or (h ? 'text' and jsonb_typeof(h -> 'text') not in ('string', 'null')))
     or (select count(*) <> count(distinct (h ->> 'stufe')::numeric) from jsonb_array_elements(e -> 'hinweise') h) then
    perform public.pruef_fehler('hinweis_ungueltig');
  end if;
  if exists (select 1 from jsonb_array_elements(e -> 'hinweise') h where length(btrim(h ->> 'text')) > 500) then
    perform public.pruef_fehler('hinweis_zu_lang');
  end if;

  select coalesce(jsonb_agg(coalesce(a.h, '{}'::jsonb)
                              || jsonb_build_object('level', x.stufe, 'text', x.txt) order by x.stufe), '[]'),
         count(*)
    into neu, n
    from (select (h ->> 'stufe')::int stufe, btrim(h ->> 'text') txt
            from jsonb_array_elements(e -> 'hinweise') h
           where coalesce(btrim(h ->> 'text'), '') <> '') x
    left join lateral (select o.h from jsonb_array_elements(alt) o(h)
                        where (o.h ->> 'level')::int = x.stufe limit 1) a on true;
  -- Das Kind bekommt Stufe n erst nach Stufe n-1: keine Luecken.
  if n > 0 and (select max((h ->> 'level')::int) from jsonb_array_elements(neu) h) <> n then
    perform public.pruef_fehler('hinweis_luecke');
  end if;
  -- Unveraenderte Hinweise byte-gleich lassen, damit kein Speichern ohne Aenderung schreibt.
  if (select coalesce(jsonb_agg(jsonb_build_object('l', (h ->> 'level')::int, 't', h ->> 'text') order by (h ->> 'level')::int), '[]')
        from jsonb_array_elements(neu) h)
     = (select coalesce(jsonb_agg(jsonb_build_object('l', (h ->> 'level')::int, 't', h ->> 'text') order by (h ->> 'level')::int), '[]')
          from jsonb_array_elements(alt) h) then
    return alt;
  end if;
  return neu;
end;
$$;

revoke all on function public.pruef_hinweise_anwenden(jsonb, jsonb) from public, anon, authenticated;
