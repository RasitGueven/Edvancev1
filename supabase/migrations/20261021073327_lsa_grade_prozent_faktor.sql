-- lsa_grade: „%“ ist ein Faktor 1/100, keine Deko-Einheit (Lenas Rückfrage vom 20.10.2026 zu 54f5e1df).
--
-- Bisher verglich lsa_grade die Zahl und ließ die Einheit liegen, solange unit_graded nicht gesetzt war.
-- Bei der Lösung 12/25 galten deshalb auch „0,48 %“, „12/25 %“ und „48“ (ohne %, über das Äquivalent
-- „48 %“) als 'voll'. Fachlich (Rasit, 21.10.2026): richtig sind 12/25, 0,48 und 48 %, falsch sind
-- 0,48 %, 12/25 % und 48 ohne Prozentzeichen.
--
-- Neu im Zahlenzweig der Kandidatenschleife: Steht „%“ nur auf einer Seite und hat die andere Seite gar
-- keine Einheit, wird die Eingabe vor dem Vergleich in die Skala des Kandidaten umgerechnet. Das Wort
-- „Prozent“ zählt dabei wie „%“
-- (Eingabe mit %, Kandidat ohne → Eingabe / 100; Eingabe ohne, Kandidat mit % → Eingabe · 100). Die
-- Toleranz bleibt so in der Skala des Kandidaten. Andere Einheitenpaare (% gegen €, cm gegen m)
-- bleiben wie bisher.
--
-- Ausnahme: Ist die Antwort selbst ein Prozentsatz (Zinssatz, Prozentsatz, Wachstumsrate; das Feld zeigt
-- „%“ über tasks.unit), steht ausdrücklich acceptance.unit = '%'. Dann meinen „3“ und „3 %“ dasselbe,
-- und lsa_grade wertet genau wie bisher. Der aus canonical abgeleitete Wert zählt dafür nicht: Bei
-- Wahrscheinlichkeiten steht canonical auch mal als „20 %“ (5bcca7e7).
--
-- lsa_is_correct (exakter Vergleich gegen correct_answers) bleibt unverändert; die Daten der
-- betroffenen Aufgaben zieht die folgende Migration nach. Grundlage ist pg_get_functiondef aus Prod
-- vom 21.10.2026; außer den markierten Stellen (v_pct_satz, v_frac, v_g_cmp) ist der Text gleich.

-- Vorab (Voraussetzung für die neue Wertung): Prozentsatz-Aufgaben mit „%“ am Antwortfeld (tasks.unit = '%')
-- ohne acceptance.unit bekommen acceptance.unit = '%'. Sonst würde „3 %“ bei 2d5e6e81 (kanonisch „3“, ohne
-- Äquivalente) 'nicht' und „0,12“ bei f91618d9 über das Äquivalent „12 %“ 'voll'. Betroffen (Prod 21.10.2026):
-- 2d5e6e81, 86f705e2, e059539e, 9031703f (Zins), f91618d9 (Wachstumsrate), 52d18200 (Steigung in Prozent).
-- Alle im Entwurf, keine hat eine Ausgangsfassung. Compare-and-set: nur wo acceptance.unit fehlt; ein zweiter
-- Lauf ändert nichts, in der CI fehlen die Aufgaben.

do $rf1$
declare
  v_m integer;
begin
  update public.task_solutions s
     set acceptance = s.acceptance || '{"unit": "%"}'::jsonb
    from public.tasks t
   where t.id = s.task_id
     and t.id in ('2d5e6e81-1f81-462c-8b70-db43a7454bb4', '86f705e2-6364-4749-8faf-c031e6bf7110',
                  'e059539e-120d-428b-ba3d-c11ae9c4a83d', '9031703f-4b09-41be-a1a3-6a0b55bc0603',
                  'f91618d9-3bbf-4b57-8901-8f898829fdef', '52d18200-7696-4bed-bba7-352cbb35436c')
     and t.unit = '%'
     and jsonb_typeof(s.acceptance) = 'object' and s.acceptance ? 'canonical'
     and not s.acceptance ? 'unit';
  get diagnostics v_m = row_count;

  raise notice 'lsa_grade_prozent_faktor: Prozentsatz-Marker %', v_m;
end $rf1$;

CREATE OR REPLACE FUNCTION public.lsa_grade(p_input_type text, p_acceptance jsonb, p_correct_answers jsonb, p_response jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
declare
  v_rule      jsonb;
  v_given     text;
  v_parts     text[];
  v_g_num     text;
  v_g_unit    text;
  v_cand      text;
  v_c_parts   text[];
  v_c_num     text;
  v_c_unit    text;
  v_req_unit  text;
  v_tol       jsonb;
  v_unit_grad boolean;
  v_reduced   boolean;
  v_hit       boolean := false;
  v_unit_ok   boolean := false;
  v_pct_satz  boolean;
  v_frac      numeric[];
  v_g_cmp     text;
begin
  -- MC: unveraendert binaer, ueber die bestehende Mengengleichheit.
  if p_input_type = 'MC' then
    return case
      when coalesce(public.lsa_is_correct(p_input_type, p_correct_answers, p_response), false)
      then 'voll' else 'nicht' end;
  end if;

  -- TERM: nie ueber den Wert-Einheit-Pfad. Ein acceptance an dieser Stelle ist
  -- ein Pflegefehler und wird laut — der Trigger verhindert ihn in den Daten,
  -- hier faellt auf, wenn ihn doch jemand von Hand hereinreicht.
  if p_input_type = 'TERM' then
    if jsonb_typeof(p_acceptance) = 'object' and p_acceptance ? 'canonical' then
      raise exception
        'LSA: TERM-Aufgabe mit acceptance.canonical — der Wert-Einheit-Pfad kann Terme nicht bewerten'
        using errcode = 'P0001';
    end if;
    return case
      when coalesce(public.lsa_is_correct(p_input_type, p_correct_answers, p_response), false)
      then 'voll' else 'nicht' end;
  end if;

  -- Eine Regel ist ein Objekt MIT canonical. Alles andere (NULL, '{}', die
  -- Teilaufgaben-Abbildung) heisst: hier ist nichts gepflegt.
  v_rule := case
    when jsonb_typeof(p_acceptance) = 'object' and p_acceptance ? 'canonical'
    then p_acceptance else null end;

  if v_rule is null then
    return case
      when coalesce(public.lsa_is_correct(p_input_type, p_correct_answers, p_response), false)
      then 'voll' else 'nicht' end;
  end if;

  begin
    v_given := coalesce(p_response ->> 'text', p_response ->> 'value');
    if v_given is null or btrim(v_given) = '' then
      return 'nicht';
    end if;

    v_parts     := public.lsa_split_value_unit(v_given);
    v_g_num     := btrim(v_parts[1]);
    v_g_unit    := btrim(v_parts[2]);
    v_tol       := v_rule -> 'tolerance';
    v_unit_grad := coalesce((v_rule ->> 'unit_graded')::boolean, false);
    v_reduced   := coalesce((v_rule ->> 'require_reduced')::boolean, false);

    -- Die geforderte Einheit: explizit gepflegt, sonst die der kanonischen Antwort.
    v_req_unit := btrim(coalesce(
      v_rule ->> 'unit',
      (public.lsa_split_value_unit(v_rule ->> 'canonical'))[2],
      ''));
    v_req_unit := lower(v_req_unit);

    -- Die Antwort ist selbst ein Prozentsatz: nur, wenn acceptance.unit ausdruecklich '%' ist.
    v_pct_satz := btrim(coalesce(v_rule ->> 'unit', '')) = '%';

    -- Kandidaten: die kanonische Antwort und ihre Aequivalente. Reihenfolge
    -- zaehlt — der erste Treffer MIT passender Einheit gewinnt.
    for v_cand in
      select c from unnest(
        array[v_rule ->> 'canonical'] ||
        coalesce(
          (select array_agg(e #>> '{}')
             from jsonb_array_elements(
                    case when jsonb_typeof(v_rule -> 'equivalents') = 'array'
                         then v_rule -> 'equivalents' else '[]'::jsonb end) as e),
          '{}'::text[])
      ) as t(c)
    loop
      if v_cand is null or btrim(v_cand) = '' then
        continue;
      end if;

      v_c_parts := public.lsa_split_value_unit(v_cand);
      v_c_num   := btrim(v_c_parts[1]);
      v_c_unit  := lower(btrim(v_c_parts[2]));

      -- Ist die Einheit Teil der Kompetenz, zaehlen Aequivalente in ANDERER
      -- Einheit gar nicht mit (A10).
      if v_unit_grad and v_c_unit <> v_req_unit then
        continue;
      end if;

      if v_g_num <> '' and v_c_num <> ''
         and public.lsa_is_unit(v_g_unit) and public.lsa_is_unit(v_c_unit) then
        -- Prozent ist ein Faktor: 0,48 % ist nicht 0,48. Steht % (oder „Prozent“) nur auf einer
        -- Seite und die andere hat keine Einheit, rechnet die Eingabe in die Skala des Kandidaten um.
        v_g_cmp := v_g_num;
        if not v_pct_satz and (lower(v_g_unit) in ('%', 'prozent')) <> (v_c_unit in ('%', 'prozent'))
           and (v_g_unit = '' or v_c_unit = '') then
          v_frac := public.lsa_parse_fraction(v_g_num);
          if v_frac is null then
            continue;
          end if;
          v_g_cmp := case when v_c_unit in ('%', 'prozent')
                          then (v_frac[1] * 100)::text || '/' || v_frac[2]::text
                          else v_frac[1]::text || '/' || (v_frac[2] * 100)::text end;
        end if;
        -- Zahlen: mathematisch vergleichen. NUR wenn der Rest auf beiden Seiten
        -- plausibel eine Einheit ist — sonst waere "5x+9" gegen "5x+4" ein
        -- Treffer auf der 5 (Befund 1).
        if not public.lsa_values_equal(v_g_cmp, v_c_num, v_tol) then
          continue;
        end if;
      else
        -- Wortantworten und alles, was keine Zahl-mit-Einheit ist: der
        -- normalisierte Vergleich, den lsa_is_correct auch fuehrt.
        if public.lsa_normalize_answer(v_given) is distinct from
           public.lsa_normalize_answer(v_cand) then
          continue;
        end if;
      end if;

      v_hit := true;
      -- Bei ungewerteter Einheit ist die Form der Einheit kein Kriterium.
      if not v_unit_grad or v_g_unit = v_c_unit then
        v_unit_ok := true;
        exit;
      end if;
    end loop;

    if not v_hit then
      return 'nicht';
    end if;

    -- Richtig gerechnet, Form verfehlt — die diagnostisch teure Zwischenstufe.
    if v_unit_grad and not v_unit_ok then
      return 'teilweise';
    end if;
    if v_reduced and not public.lsa_is_reduced(v_given) then
      return 'teilweise';
    end if;

    return 'voll';
  exception
    when others then
      -- Eine Auswertung darf an einer kaputten Regel nicht sterben. Im Zweifel
      -- wie vorher: die bestehende Bewertung entscheidet.
      return case
        when coalesce(public.lsa_is_correct(p_input_type, p_correct_answers, p_response), false)
        then 'voll' else 'nicht' end;
  end;
end;
$function$;

-- pruef_einheit: dieselbe Regel für das Lena-Board. Bisher wurde „%“ aus der ersten Antwort mit Einheit
-- abgeleitet („48 %“). Beim Speichern hängte pruef_schreibweisen die Einheit dann an jeden Wert an; so kamen
-- „0,48 %“ und „0,5 %“ in correct_answers. Außerdem zeigte das Board „12/25 %“ als Schreibweise, die
-- automatisch zählt. Jetzt gilt: „%“ ist nur dann die Einheit der Aufgabe, wenn acceptance.unit es
-- ausdrücklich sagt (die Antwort ist ein Prozentsatz). Abgeleitete Einheiten wie cm oder € bleiben.
-- Ein Wert, der selbst „%“ trägt („48 %“), bekommt seine Schreibweisen weiter über pruef_einheit_von.

CREATE OR REPLACE FUNCTION public.pruef_einheit(p_acceptance jsonb, p_ca jsonb)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select coalesce(nullif(btrim(p_acceptance ->> 'unit'), ''),
                  (select case when lower(btrim(z.u)) in ('%', 'prozent') then null else z.u end
                     from (select coalesce(
                             public.pruef_einheit_von(p_acceptance ->> 'canonical'),
                             (select public.pruef_einheit_von(x) from jsonb_array_elements_text(
                                case when jsonb_typeof(p_ca) = 'array' then p_ca else '[]' end)
                                with ordinality e(x, i)
                               where public.pruef_einheit_von(x) is not null order by i limit 1)) as u) z))
$function$;
