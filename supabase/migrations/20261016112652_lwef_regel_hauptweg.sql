-- loesungsweg_endet_falsch ohne Fehlalarm bei Probe oder Erklaerung nach dem Ergebnis
--
-- Bisher las die Regel die letzte Zahl nach dem letzten "=" oder "≈". Folgt dem richtigen Ergebnis noch eine
-- Probe oder Begruendung ("√30 ≈ 5,48. Probe: 5² = 25 < 30 < 36 = 6²"), las sie 6² und meldete einen Fehler
-- (6 Pilot-Aufgaben, docs/themen/pruefung-batu-inhalte.md).
--
-- Neu liest sie zusaetzlich das Ende des Hauptwegs: Klammer-Einschuebe mit Wort oder "=" fallen weg, ab
-- "Probe", "Kontrolle", "Check" oder "denn" wird abgeschnitten, und es zaehlt die erste Zahl nach dem letzten
-- "=" oder "≈". Befund nur, wenn beide Lesarten nicht voll sind. Jede Aufgabe ohne Befund bleibt ohne Befund.
-- Befunde werden nicht gespeichert (pruef_aufgabe und pruef_speichern rechnen sie bei jedem Aufruf neu),
-- daher kein Datenteil. Pruefstatus, Ausgangsfassung und Notizen bleiben unberuehrt.

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
  kand text; s text; wert text;
  muster constant text := '([-+−–]?\s?[0-9]+(?:[.,][0-9]+)?(?:/[0-9]+)?(?:\s?[a-zA-ZäöüßÄÖÜ°%€²³]+)?)';
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
    -- loesungsweg_endet_falsch: zwei Lesarten, Befund nur, wenn keine voll ist.
    --   Ende des Hauptwegs: ohne Klammer-Einschuebe (mit Wort oder "="), abgeschnitten ab Probe/Kontrolle/
    --   Check/denn, erste Zahl nach dem letzten "=" oder "≈". Gemeldet wird diese Zahl, falls vorhanden.
    --   Bisherige Lesart: letzte Zahl nach dem letzten "=" oder "≈" im ganzen Weg.
    if it = 'NUMERIC' and p_solution is not null then
      x := regexp_replace(regexp_replace(p_solution, '\([^()]*(=|[[:alpha:]]{2})[^()]*\)', '', 'g'),
                          '\m(probe|kontrolle|check|denn)\M.*$', '', 'i');
      rest := substring(p_solution from '.*[=≈](.*)$');
      select m[1] into zahl
        from regexp_matches(coalesce(rest, ''), muster, 'g') with ordinality t(m, i)
       order by i desc limit 1;
      foreach kand in array array_remove(array[
          btrim((regexp_match(coalesce(substring(x from '.*[=≈](.*)$'), ''), muster))[1]), btrim(zahl)], null) loop
        s := case when flach then public.lsa_grade(it, acc, ca, jsonb_build_object('text', kand))
                  when coalesce(public.lsa_is_correct(it, ca, jsonb_build_object('text', kand)), false)
                  then 'voll' else 'nicht' end;
        if s = 'voll' then
          stufe := 'voll';
          exit;
        end if;
        if stufe is null then
          stufe := s; wert := kand;
        end if;
      end loop;
      if stufe <> 'voll' then
        r := r || jsonb_build_array(jsonb_build_object('code', 'loesungsweg_endet_falsch', 'teil', null,
                                                       'wert', wert, 'stufe', stufe));
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

revoke all on function public.pruef_auffaelligkeiten(public.tasks, jsonb, jsonb, text) from public, anon, authenticated;
