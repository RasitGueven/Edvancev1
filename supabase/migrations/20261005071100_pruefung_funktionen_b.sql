-- Lena-Board, Migration 2b: Sicht, Aenderungen, Auffaelligkeiten, Entwurf (Entscheidungen 15, 16, 19)
--
-- Weiter nur interne Bausteine (kein Grant). pruef_entwurf_anwenden ist das gemeinsame Stueck von
-- pruef_speichern (schreibt) und pruef_wertung_testen (schreibt nicht).

-- ── Sicht: eine Fassung so, wie Lena sie sieht ──────────────────────────────
-- werte:   [{teil, werte: [{wert, schreibweisen}]}]. Flach mit Regel zusammengefasst (die Engine
--          wertet dort nach Zahlenwert), sonst jeder Eintrag einzeln (dort vergleicht sie Text).
-- regel:   nur bei "flach mit Regel" und NUMERIC bzw. SHORT_TEXT mit lauter Zahlwerten.
-- fehler:  je Fehlbild eine Gruppe [{slug, werte: [{teil, wert}], text}], Werte zusammengefasst.
create or replace function public.pruef_sicht(p_task public.tasks, p_fassung jsonb)
returns jsonb language plpgsql stable set search_path = public, pg_temp as $$
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
    'skill_key', p_fassung ->> 'skill_key',
    'afb', p_fassung ->> 'afb',
    'flach_regel', flach,
    'ohne_erkennung', it = 'TERM' or (it not in ('MC', 'MULTI_PART') and not flach));
end $$;

-- ── Aenderungen: Ausgangsfassung ↔ jetzt, als [{feld, teil, vorher, nachher}] ─
create or replace function public.pruef_aenderungen(p_vorher jsonb, p_nachher jsonb)
returns jsonb language sql immutable as $$
  with
  wv as (select (w ->> 'teil')::int teil, coalesce((select jsonb_agg(x ->> 'wert') from jsonb_array_elements(w -> 'werte') x), '[]') l
           from jsonb_array_elements(coalesce(p_vorher -> 'werte', '[]')) w),
  wn as (select (w ->> 'teil')::int teil, coalesce((select jsonb_agg(x ->> 'wert') from jsonb_array_elements(w -> 'werte') x), '[]') l
           from jsonb_array_elements(coalesce(p_nachher -> 'werte', '[]')) w),
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
     where p_vorher -> 'afb' is distinct from p_nachher -> 'afb')
  select coalesce(jsonb_agg(e order by n, e ->> 'teil', e -> 'vorher' ->> 'slug', e -> 'nachher' ->> 'slug'), '[]') from l
$$;

-- ── 19 · Auffaelligkeiten (Code + Parameter, Text kommt aus i18n) ──────────
create or replace function public.pruef_auffaelligkeiten(
  p_task public.tasks, p_ca jsonb, p_acc jsonb, p_solution text)
returns jsonb language plpgsql stable set search_path = public, pg_temp as $$
declare
  it    text := p_task.input_type;
  acc   jsonb := nullif(p_acc, 'null'::jsonb);
  ca    jsonb := coalesce(p_ca, '[]');
  flach boolean := public.pruef_flach_regel(it, acc);
  ke    jsonb;
  r     jsonb := '[]';
  treffer jsonb;
  x text; rest text; zahl text; stufe text; p jsonb; kind text; liste jsonb;
begin
  if it not in ('MULTI_PART', 'MC', 'TERM') then
    ke := case when jsonb_typeof(acc -> 'known_errors') = 'object' then acc -> 'known_errors' else '{}' end;
    -- fehler_als_richtig: ein typischer Fehler wuerde als voll gewertet
    treffer := coalesce((select jsonb_agg(k order by length(k), k) from jsonb_object_keys(ke) k
      where case when flach then public.lsa_grade(it, acc, ca, jsonb_build_object('text', k)) = 'voll'
                 else coalesce(public.lsa_is_correct(it, ca, jsonb_build_object('text', k)), false) end), '[]');
    r := r || coalesce((select jsonb_agg(jsonb_build_object('code', 'fehler_als_richtig', 'teil', null, 'wert', g ->> 0))
                          from jsonb_array_elements(public.pruef_gruppen(treffer)) g), '[]');
    -- werte_widersprechen: ein richtiger Wert waere nach lsa_grade nicht voll. Fehlt bei
    -- "Einheit muss dabei sein" nur die Einheit, ist "teilweise" gewollt und kein Widerspruch.
    if flach then
      treffer := coalesce((select jsonb_agg(v) from jsonb_array_elements_text(ca) v
        where public.lsa_grade(it, acc, ca, jsonb_build_object('text', v)) is distinct from 'voll'
          and not (coalesce((acc ->> 'unit_graded')::boolean, false) and public.pruef_einheit_von(v) is null
                   and public.lsa_grade(it, acc, ca, jsonb_build_object('text', v)) = 'teilweise')), '[]');
      r := r || coalesce((select jsonb_agg(jsonb_build_object('code', 'werte_widersprechen', 'teil', null, 'wert', g ->> 0))
                            from jsonb_array_elements(public.pruef_gruppen(treffer)) g), '[]');
    end if;
    -- loesungsweg_endet_falsch: letzte Zahl nach dem letzten "=" oder "≈"
    if it = 'NUMERIC' and p_solution is not null then
      rest := substring(p_solution from '.*[=≈](.*)$');
      select m[1] into zahl
        from regexp_matches(coalesce(rest, ''),
               '([-+−–]?\s?[0-9]+(?:[.,][0-9]+)?(?:/[0-9]+)?(?:\s?[a-zA-ZäöüßÄÖÜ°%€²³]+)?)', 'g')
             with ordinality t(m, i)
       order by i desc limit 1;
      if zahl is not null then
        stufe := case when flach then public.lsa_grade(it, acc, ca, jsonb_build_object('text', btrim(zahl)))
                      when coalesce(public.lsa_is_correct(it, ca, jsonb_build_object('text', btrim(zahl))), false)
                      then 'voll' else 'nicht' end;
        if stufe <> 'voll' then
          r := r || jsonb_build_array(jsonb_build_object('code', 'loesungsweg_endet_falsch', 'teil', null,
                                                         'wert', btrim(zahl), 'stufe', stufe));
        end if;
      end if;
    end if;
  elsif it = 'MC' then
    ke := case when jsonb_typeof(acc -> 'known_errors') = 'object' then acc -> 'known_errors' else '{}' end;
    if ke ? (ca ->> 0) then
      r := r || jsonb_build_array(jsonb_build_object('code', 'mc_richtig_ist_fehler', 'teil', null, 'wert', ca ->> 0));
    end if;
    r := r || coalesce((select jsonb_agg(jsonb_build_object('code', 'mc_ablenker_ohne_fehlbild', 'teil', null, 'wert', o ->> 'id') order by i)
                          from jsonb_array_elements(coalesce(p_task.question_payload -> 'options', '[]')) with ordinality q(o, i)
                         where not (ca ? (o ->> 'id')) and not (ke ? (o ->> 'id'))), '[]');
  elsif it = 'MULTI_PART' then
    for p in select e from jsonb_array_elements(p_task.parts) e loop
      kind := p ->> 'kind';
      liste := case when jsonb_typeof(ca -> (p ->> 'nr')) = 'array' then ca -> (p ->> 'nr') else '[]' end;
      ke := case when jsonb_typeof(acc -> (p ->> 'nr') -> 'known_errors') = 'object'
                 then acc -> (p ->> 'nr') -> 'known_errors' else '{}' end;
      r := r || coalesce((select jsonb_agg(jsonb_build_object('code', 'teil_fehler_ist_richtig', 'teil', (p ->> 'nr')::int, 'wert', k) order by length(k), k)
                            from jsonb_object_keys(ke) k
                           where coalesce(public.lsa_is_correct(case when kind = 'mc' then 'MC' else 'SHORT_TEXT' end,
                                   liste, public.lsa_part_answer(kind, to_jsonb(k))), false)), '[]');
      if kind = 'mc' then
        r := r || coalesce((select jsonb_agg(jsonb_build_object('code', 'mc_ablenker_ohne_fehlbild', 'teil', (p ->> 'nr')::int, 'wert', o ->> 'id') order by i)
                              from jsonb_array_elements(coalesce(p -> 'options', '[]')) with ordinality q(o, i)
                             where not (liste ? (o ->> 'id')) and not (ke ? (o ->> 'id'))), '[]');
      end if;
    end loop;
  end if;
  return r;
end $$;

-- ── Fertigkeiten zur Auswahl: das Ausgangs-Thema plus direkte Voraussetzungen ─
-- Nur Fertigkeiten mit Heimat-Thema: ohne skill_thema fiele die Aufgabe aus dem Board.
create or replace function public.pruef_fertigkeit_optionen(p_skill_key text)
returns jsonb language sql stable set search_path = public, pg_temp as $$
  with thema as (select thema_key from public.skill_thema where skill_key = p_skill_key),
  im_thema as (
    select s.skill_key, s.label, 'thema' gruppe, 1 n, s.fundament_tiefe t
      from public.skills s join public.skill_thema st on st.skill_key = s.skill_key
     where st.thema_key = (select thema_key from thema)),
  vor as (
    select s.skill_key, s.label, 'voraussetzung' gruppe, 2 n, s.fundament_tiefe t
      from public.skill_kante k join public.skills s on s.skill_key = k.voraussetzt_skill_key
     where k.skill_key = p_skill_key
       and exists (select 1 from public.skill_thema st where st.skill_key = s.skill_key)
       and s.skill_key not in (select skill_key from im_thema))
  select coalesce(jsonb_agg(jsonb_build_object('key', skill_key, 'label', label, 'gruppe', gruppe)
                            order by n, t, skill_key), '[]')
    from (select * from im_thema union all select * from vor) o
$$;

revoke all on function public.pruef_sicht(public.tasks, jsonb), public.pruef_aenderungen(jsonb, jsonb),
  public.pruef_auffaelligkeiten(public.tasks, jsonb, jsonb, text), public.pruef_fertigkeit_optionen(text)
  from public, anon, authenticated;
