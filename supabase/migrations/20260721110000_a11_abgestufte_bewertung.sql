-- ============================================================================
-- A11: Abgestufte Bewertung (voll | teilweise | nicht) mit Wertgleichheit
--
-- SETZT A10 VORAUS (20260721100000). Diese Migration ersetzt
-- lsa_acceptance_rule_valid und liest task_solutions.acceptance — beides gibt
-- es erst nach A10. Reihenfolge: A10, dann A11.
--
-- ----------------------------------------------------------------------------
-- BESTANDSAUFNAHME
-- ----------------------------------------------------------------------------
--   lsa_normalize_answer(text)  – trim → Whitespace kollabieren → ERSTES Komma
--       zu Punkt → lowercase. Eine Konvention, ein Ort (P01 §3).
--   lsa_is_correct(input_type, correct_answers, response) → boolean
--       MC: Mengengleichheit der Option-Ids. Sonst: die normalisierte Antwort
--       ({text} bzw. {value}) muss EIN Element von correct_answers TREFFEN —
--       ein reiner STRING-Vergleich. "22/24" ist damit falsch, auch wenn die
--       Loesung "11/12" ist: dieselbe Zahl, andere Zeichen.
--   Aufrufer von lsa_is_correct: AUSSCHLIESSLICH lsa_submit — einmal im
--       MULTI_PART-Zweig (je Teilaufgabe, mit lsa_part_answer uebersetzt) und
--       einmal flach (P02 §7). Sonst niemand: kein View, kein Trigger, kein
--       Frontend (task_solutions hat kein Grant, lsa_is_correct nur
--       service_role). Die Bewertung landet als BOOLEAN in
--       lsa_responses.correct, und lsa_finish/der Eltern-Report zaehlen
--       ausschliesslich diese Spalte.
--   acceptance (A10, task_solutions): {canonical, equivalents[],
--       notation{decimal_comma,unit_optional,ignore_case,ignore_space},
--       tolerance{mode,value}, unit, unit_graded} — flach EINE Regel, bei
--       MULTI_PART {"<nr>": Regel}. Bisher rein DEKLARATIV: es rechnet niemand
--       damit.
--   response: {"text": "..."} (SHORT_TEXT) bzw. {"value": "..."} (NUMERIC);
--       bei MULTI_PART baut lsa_part_answer die skalare Teilantwort in dieselbe
--       Form um.
--
-- ES FEHLT: die Zwischenstufe. "11/12" und "22/24" sind DIESELBE ZAHL — das
--   Kind hat richtig gerechnet und nur nicht gekuerzt. Heute faellt das auf
--   `false`, genau wie ein echter Rechenfehler. Diagnostisch ist das der
--   teuerste Informationsverlust im ganzen Auswertungspfad: die haeufigste
--   Foerderentscheidung ("Rechenweg sitzt, Darstellung fehlt") ist aus den
--   Daten nicht ablesbar.
--
-- ----------------------------------------------------------------------------
-- ENTSCHEIDUNG 1: lsa_grade ADDITIV, lsa_is_correct bleibt unangetastet
-- ----------------------------------------------------------------------------
--   lsa_is_correct behaelt Signatur, Rumpf und Verhalten — byte-identisch.
--   lsa_grade tritt DANEBEN, nicht davor. Warum der vorsichtigere Weg:
--     * lsa_responses.correct ist boolean, und lsa_finish + der Eltern-Report
--       rechnen darauf. Eine Stufe kann dort erst ankommen, wenn die Spalte sie
--       halten kann — das ist ein eigener Schnitt (siehe NACHLAUF).
--     * inv2/inv3 pinnen das heutige Bewertungsverhalten fest. Ein Umbau in
--       derselben Migration wuerde Datenmodell UND gruene Beweise gleichzeitig
--       bewegen.
--   lsa_submit wird deshalb NICHT angefasst. lsa_grade ist ab heute
--   aufrufbar und getestet, aber noch nicht verdrahtet.
--
-- ----------------------------------------------------------------------------
-- ENTSCHEIDUNG 2: exakte Bruchrechnung ueber numeric-Paare, NICHT ueber float
-- ----------------------------------------------------------------------------
--   lsa_parse_fraction liefert {Zaehler, Nenner} als `numeric[]`. Verglichen
--   wird per KREUZPRODUKT (a*d = c*b) — exakt, ohne je zu dividieren. 1/3
--   hat keine endliche Dezimaldarstellung; jeder Weg ueber double precision
--   waere eine Naeherung, die genau bei den Aufgaben kippt, um die es geht.
--   numeric statt bigint: numeric-Ganzzahlarithmetik ist beliebig gross und
--   kann nicht ueberlaufen. "0,9166666666" wird zu 9166666666/10000000000 —
--   mit bigint waere der Nenner bei genug Nachkommastellen ein Absturz, hier
--   ist er nur eine grosse Zahl.
--
-- ----------------------------------------------------------------------------
-- ENTSCHEIDUNG 3: der Bruch wird gespeichert WIE GESCHRIEBEN, nicht gekuerzt
-- ----------------------------------------------------------------------------
--   lsa_parse_fraction kuerzt NICHT. Fuer die Wertgleichheit ist das egal (das
--   Kreuzprodukt braucht keine gekuerzte Form) — aber genau diese Information
--   ist es, die `require_reduced` beurteilt. Wer beim Parsen kuerzt, wirft weg,
--   was er gleich messen will.
--
-- ----------------------------------------------------------------------------
-- ENTSCHEIDUNG 4: `require_reduced` steht OBEN, nicht in `notation`
-- ----------------------------------------------------------------------------
--   Alle notation-Flags LOCKERN ("diese Schreibweise gilt auch"). Eine
--   Kuerzungspflicht VERSCHAERFT. Sie gehoert deshalb neben `unit_graded` —
--   die beiden sind die Formanforderungen der Regel, notation.* sind die
--   Nachsichten.
--   Praktisch dazu: der A10-CHECK whitelistet die notation-Schluessel. Ein
--   `notation.require_reduced` waere von jeder Datenbank mit A10 und ohne A11
--   ABGEWIESEN worden; oben ist das Feld vorwaerts- und rueckwaertsvertraeglich.
--   Default (fehlt/false): keine Kuerzungspflicht — wertgleich = 'voll', also
--   exakt das Verhalten von vorher.
--
-- ----------------------------------------------------------------------------
-- ENTSCHEIDUNG 5: die vier notation-Flags bleiben DOKUMENTIEREND
-- ----------------------------------------------------------------------------
--   decimal_comma, ignore_case, ignore_space beschreiben, was
--   lsa_normalize_answer ohnehin und immer tut (Komma zu Punkt, lowercase,
--   Whitespace kollabieren). Sie stehen in acceptance, aber sie SCHALTEN hier
--   nichts: ein `decimal_comma: false` wuerde eine zweite
--   Normalisierungskonvention verlangen, und die Zusage aus P01 §3 ist "eine
--   Konvention, ein Ort". Sie festzuhalten hat trotzdem Wert — sie sagt dem
--   Pfleger, was das System zusichert.
--   unit_optional ist unter A10 nur zusammen mit unit_graded=false erlaubt, und
--   dort ist die Einheit ohnehin kein Kriterium. Auch das ist heute Dokumentation.
--   Wirksam sind genau zwei Flags: `unit_graded` und `require_reduced` — die
--   beiden Verschaerfungen. Wer eine der Nachsichten wirklich abschalten will,
--   braucht dafuer einen eigenen Schnitt, nicht ein stilles Verhalten hier.
--
-- ----------------------------------------------------------------------------
-- KEIN LEAK
-- ----------------------------------------------------------------------------
--   Alle neuen Funktionen bekommen acceptance/correct_answers als PARAMETER und
--   lesen NIE selbst aus task_solutions — dasselbe Muster wie lsa_is_correct
--   (P01) und lsa_has_answers (P02). Sie koennen nichts verraten, egal wer sie
--   aufruft; gegrantet sind sie ohnehin nur an service_role.
--   lsa_grade ist AUSWERTUNGS-Logik und laeuft serverseitig. Weder acceptance
--   noch eine Stufe gehen je in den Schueler-Payload: lsa_question_payload und
--   lsa_public_parts bauen aus einer Whitelist und lesen task_solutions nicht.
--   Diese Migration aendert am Payload-Bau KEINE Zeile.
-- ============================================================================

begin;

-- ============================================================================
-- 1. Zahl und Einheit trennen
--
--    "1,5 m" → {"1.5", "m"} · "11/12" → {"11/12", ""} · "1 1/2 kg" → {"1 1/2","kg"}
--    Erkannte Zahlformen: ganze Zahl, Dezimal, Bruch, gemischter Bruch — jeweils
--    mit optionalem Vorzeichen. Was danach kommt, ist Einheit; passt vorne keine
--    Zahl, ist der ganze Rest Einheit (und die Zahl leer).
-- ============================================================================

create or replace function public.lsa_split_value_unit(p_raw text)
returns text[]
language sql
immutable
as $$
  -- Ein Muster, zweimal verwendet: einmal faengt es die Zahl, einmal ueberspringt
  -- es sie. Die inneren Gruppen sind bewusst nicht-fangend, damit `substring`
  -- die gemeinte Gruppe liefert.
  select case
    when p_raw is null then null
    else array[
      coalesce(
        substring(public.lsa_normalize_answer(p_raw)
                  from '^(-?[0-9]+(?:[[:space:]]+[0-9]+/[0-9]+|/[0-9]+|\.[0-9]+)?)'),
        ''),
      btrim(coalesce(
        substring(public.lsa_normalize_answer(p_raw)
                  from '^-?[0-9]+(?:[[:space:]]+[0-9]+/[0-9]+|/[0-9]+|\.[0-9]+)?[[:space:]]*(.*)$'),
        public.lsa_normalize_answer(p_raw)))
    ]
  end
$$;

comment on function public.lsa_split_value_unit(text) is
  'Zerlegt eine Antwort in [Zahlteil, Einheit] — nach lsa_normalize_answer. '
  'Erkennt ganze Zahl, Dezimal, Bruch und gemischten Bruch. Ohne erkennbare '
  'Zahl ist der Zahlteil leer und alles Einheit.';

-- ============================================================================
-- 2. Der Bruch-Parser — WIE GESCHRIEBEN, nicht gekuerzt
--
--    "3/4"      → {3, 4}
--    "1 1/2"    → {3, 2}     (gemischt: 1·2+1)
--    "0.75"     → {75, 100}  (Dezimal ist exakt in einen Bruch ueberfuehrbar)
--    "-2"       → {-2, 1}
--    "elf"      → NULL
--
--    Nenner immer > 0, Vorzeichen im Zaehler. Muell gibt NULL zurueck statt zu
--    werfen — die Funktion sitzt spaeter in einem Auswertungspfad, der nicht
--    abbrechen darf, nur weil jemand "keine Ahnung" ins Feld getippt hat.
--
--    GRENZE MIT ANSAGE: "1.234" ist als Tausendertrennung gemeint oder als
--    Dezimalzahl — das ist im Zeichenstrom nicht entscheidbar. Gelesen wird
--    Dezimal (1,234). Zwei Punkte ("1.234.5") faellt durch das Muster und wird
--    NULL statt still falsch.
-- ============================================================================

create or replace function public.lsa_parse_fraction(p_raw text)
returns numeric[]
language plpgsql
immutable
as $$
declare
  v_val   text;
  v_sign  numeric := 1;
  v_body  text;
  v_whole numeric;
  v_num   numeric;
  v_den   numeric;
  v_frac  text;
begin
  v_val := btrim(coalesce((public.lsa_split_value_unit(p_raw))[1], ''));
  if v_val = '' then
    return null;
  end if;

  if left(v_val, 1) = '-' then
    v_sign := -1;
    v_body := substr(v_val, 2);
  else
    v_body := v_val;
  end if;

  -- gemischter Bruch: "1 1/2"
  if v_body ~ '^[0-9]+[[:space:]]+[0-9]+/[0-9]+$' then
    v_whole := split_part(v_body, ' ', 1)::numeric;
    v_frac  := split_part(v_body, ' ', 2);
    v_num   := split_part(v_frac, '/', 1)::numeric;
    v_den   := split_part(v_frac, '/', 2)::numeric;
    if v_den = 0 then return null; end if;
    return array[v_sign * (v_whole * v_den + v_num), v_den];

  -- echter Bruch: "11/12"
  elsif v_body ~ '^[0-9]+/[0-9]+$' then
    v_num := split_part(v_body, '/', 1)::numeric;
    v_den := split_part(v_body, '/', 2)::numeric;
    if v_den = 0 then return null; end if;
    return array[v_sign * v_num, v_den];

  -- Dezimal: "0.75" → 75/100 (die Nachkommastellen bleiben als Nenner stehen,
  -- weil `require_reduced` spaeter nur Bruecke prueft, nie Dezimalzahlen)
  elsif v_body ~ '^[0-9]+\.[0-9]+$' then
    v_den := power(10::numeric, length(split_part(v_body, '.', 2)));
    v_num := (split_part(v_body, '.', 1) || split_part(v_body, '.', 2))::numeric;
    return array[v_sign * v_num, v_den];

  -- ganze Zahl
  elsif v_body ~ '^[0-9]+$' then
    return array[v_sign * v_body::numeric, 1];
  end if;

  return null;
exception
  when others then
    -- Ein Parser darf die Auswertung nicht abschiessen. Unlesbar = NULL.
    return null;
end;
$$;

comment on function public.lsa_parse_fraction(text) is
  'Parst ganze Zahl / Dezimal / Bruch / gemischten Bruch in [Zaehler, Nenner] '
  '(numeric, Nenner > 0, Vorzeichen im Zaehler). KUERZT NICHT — die '
  'geschriebene Form ist genau das, was require_reduced beurteilt. NULL bei '
  'allem, was nicht parsebar ist.';

-- ============================================================================
-- 3. Ist der Bruch vollstaendig gekuerzt?
--
--    Nur eine FRAGE AN DIE SCHREIBWEISE: ohne '/' gibt es nichts zu kuerzen
--    (ganze Zahl, Dezimal) → true. Sonst ggT(|Zaehler|, Nenner) = 1, wobei bei
--    "1 2/4" der geschriebene Bruchteil zaehlt, nicht der unechte Gesamtwert.
--
--    "gekuerzt" ist NICHT "echt": 3/2 ist gekuerzt (und unecht). Wer die echte
--    Bruchform verlangen will, braucht ein eigenes Kriterium — bewusst nicht
--    hier hineingemischt.
-- ============================================================================

create or replace function public.lsa_is_reduced(p_raw text)
returns boolean
language plpgsql
immutable
as $$
declare
  v_val  text;
  v_frac text;
  v_num  numeric;
  v_den  numeric;
begin
  v_val := btrim(coalesce((public.lsa_split_value_unit(p_raw))[1], ''));
  if v_val = '' then return true; end if;
  if position('/' in v_val) = 0 then return true; end if;

  -- gemischt: der geschriebene Bruchteil ist der, der gekuerzt sein muss
  v_frac := case when v_val ~ '[[:space:]]' then split_part(v_val, ' ', 2) else v_val end;
  v_num  := abs(replace(split_part(v_frac, '/', 1), '-', '')::numeric);
  v_den  := split_part(v_frac, '/', 2)::numeric;
  if v_den = 0 then return true; end if;

  return gcd(v_num, v_den) = 1;
exception
  when others then
    -- Unlesbares wird nicht als "ungekuerzt" bestraft — die Wertgleichheit hat
    -- es dann ohnehin schon abgewiesen.
    return true;
end;
$$;

comment on function public.lsa_is_reduced(text) is
  'Ist die GESCHRIEBENE Bruchform vollstaendig gekuerzt (ggT = 1)? Ganze Zahlen '
  'und Dezimalzahlen: true (nichts zu kuerzen). Prueft Kuerzung, nicht Echtheit '
  '— 3/2 ist gekuerzt.';

-- ============================================================================
-- 4. Wertgleichheit — mit Toleranz
--
--    exact (Default): Kreuzprodukt, exakt. 11/12 = 22/24, 1/2 = 0,5.
--    absolute:        |a − b| <= value
--    decimals:        beide auf `value` Nachkommastellen gerundet gleich
--
--    ABWEICHUNG vom Auftrag (bewusst): die Funktion nimmt die Toleranz als
--    dritten Parameter statt sie zu erraten. Eine Wertgleichheit ohne Toleranz
--    waere entweder immer exakt (dann traegt acceptance.tolerance nichts) oder
--    haette eine eingebaute Unschaerfe (dann traegt sie zu viel).
-- ============================================================================

create or replace function public.lsa_values_equal(
  p_a         text,
  p_b         text,
  p_tolerance jsonb default null
)
returns boolean
language plpgsql
immutable
as $$
declare
  v_a    numeric[];
  v_b    numeric[];
  v_mode text;
  v_val  numeric;
begin
  v_a := public.lsa_parse_fraction(p_a);
  v_b := public.lsa_parse_fraction(p_b);
  if v_a is null or v_b is null then
    return false;
  end if;

  v_mode := coalesce(p_tolerance ->> 'mode', 'exact');

  if v_mode = 'exact' then
    -- Kreuzprodukt statt Division: keine Rundung, kein Genauigkeitsverlust.
    return v_a[1] * v_b[2] = v_b[1] * v_a[2];
  end if;

  v_val := (p_tolerance ->> 'value')::numeric;
  if v_val is null then
    return v_a[1] * v_b[2] = v_b[1] * v_a[2];
  end if;

  if v_mode = 'absolute' then
    return abs(v_a[1] / v_a[2] - v_b[1] / v_b[2]) <= v_val;
  elsif v_mode = 'decimals' then
    return round(v_a[1] / v_a[2], v_val::int) = round(v_b[1] / v_b[2], v_val::int);
  end if;

  return v_a[1] * v_b[2] = v_b[1] * v_a[2];
exception
  when others then
    return false;
end;
$$;

comment on function public.lsa_values_equal(text, text, jsonb) is
  'Mathematische Wertgleichheit zweier Antworten (11/12 = 22/24 = 0,91666… je '
  'nach Toleranz). exact vergleicht per Kreuzprodukt ohne zu dividieren; '
  'absolute/decimals nach acceptance.tolerance. false, sobald eine Seite nicht '
  'parsebar ist.';

-- ============================================================================
-- 5. acceptance darf jetzt `require_reduced` tragen
--
--    Ersetzt den A10-Validator um GENAU einen Zweig. Additiv und lockernd (ein
--    bisher untypisiertes Feld wird typisiert) — bestehende Zeilen koennen
--    dadurch nicht ungueltig werden, weil noch keine das Feld traegt.
--    notation bleibt auf seinen vier Nachsicht-Flags: die Kuerzungspflicht ist
--    eine Verschaerfung und steht oben (siehe Kopf, Entscheidung 4).
-- ============================================================================

create or replace function public.lsa_acceptance_rule_valid(p_rule jsonb)
returns boolean
language sql
immutable
as $$
  select jsonb_typeof(p_rule) = 'object'
     and jsonb_typeof(p_rule -> 'canonical') = 'string'
     and btrim(p_rule ->> 'canonical') <> ''
     and (p_rule -> 'equivalents' is null
          or (jsonb_typeof(p_rule -> 'equivalents') = 'array'
              and not exists (
                select 1 from jsonb_array_elements(p_rule -> 'equivalents') as e(v)
                 where jsonb_typeof(v) <> 'string' or btrim(v #>> '{}') = ''
              )))
     and (p_rule -> 'notation' is null
          or (jsonb_typeof(p_rule -> 'notation') = 'object'
              and not exists (
                select 1 from jsonb_each(p_rule -> 'notation') as e(k, v)
                 where k not in ('decimal_comma', 'unit_optional',
                                 'ignore_case', 'ignore_space')
                    or jsonb_typeof(v) <> 'boolean'
              )))
     and (p_rule -> 'tolerance' is null
          or (jsonb_typeof(p_rule -> 'tolerance') = 'object'
              and (p_rule #>> '{tolerance,mode}') in ('exact', 'absolute', 'decimals')
              and case p_rule #>> '{tolerance,mode}'
                    when 'exact' then p_rule -> 'tolerance' -> 'value' is null
                    when 'absolute' then
                      jsonb_typeof(p_rule -> 'tolerance' -> 'value') = 'number'
                      and (p_rule #>> '{tolerance,value}')::numeric > 0
                    else
                      jsonb_typeof(p_rule -> 'tolerance' -> 'value') = 'number'
                      and (p_rule #>> '{tolerance,value}') ~ '^[0-6]$'
                  end))
     and (p_rule -> 'unit' is null or jsonb_typeof(p_rule -> 'unit') = 'string')
     and (p_rule -> 'unit_graded' is null
          or jsonb_typeof(p_rule -> 'unit_graded') = 'boolean')
     -- NEU (A11): Kuerzungspflicht. Fehlt/false = keine — dann ist wertgleich
     -- weiterhin 'voll', also das Verhalten von vor A11.
     and (p_rule -> 'require_reduced' is null
          or jsonb_typeof(p_rule -> 'require_reduced') = 'boolean')
     and not (coalesce((p_rule ->> 'unit_graded')::boolean, false)
              and coalesce((p_rule #>> '{notation,unit_optional}')::boolean, false))
$$;

comment on function public.lsa_acceptance_rule_valid(jsonb) is
  'Strukturvertrag EINER Akzeptanzregel: canonical (Pflicht), equivalents[], '
  'notation-Flags (decimal_comma|unit_optional|ignore_case|ignore_space), '
  'tolerance (exact|absolute+value|decimals+0..6), unit, unit_graded, '
  'require_reduced (A11). Verbietet unit_graded=true zusammen mit '
  'notation.unit_optional=true.';

-- ============================================================================
-- 6. lsa_grade — die abgestufte Bewertung
--
--    RUECKGABE 'voll' | 'teilweise' | 'nicht' — dieselben drei Woerter wie
--    task_solutions.option_scores (A10). Ein Vokabular fuer beide Mechanismen,
--    auch wenn sie verschieden entscheiden.
--
--    p_acceptance ist die Regel EINES Scopes (eine flache Aufgabe oder EINE
--    Teilaufgabe) — genau wie p_correct_answers bei lsa_is_correct die Liste
--    eines Scopes ist. Bei MULTI_PART schneidet der Aufrufer zu
--    (acceptance -> nr), er reicht nicht die ganze Abbildung durch.
--
--    DIE LEITER:
--      nicht      – nicht wertgleich, leer oder unlesbar (echter Fehler)
--      teilweise  – wertgleich, aber die geforderte FORM verfehlt:
--                     · unit_graded und die Einheit stimmt nicht
--                     · require_reduced und der Bruch ist nicht gekuerzt
--      voll       – wertgleich und formgerecht
--
--    KEINE REGRESSION: ohne acceptance-Regel (NULL, leer, oder eine
--    Teilaufgaben-Abbildung statt einer Regel) faellt lsa_grade auf
--    lsa_is_correct zurueck und kennt nur 'voll'/'nicht'. Bestandsaufgaben
--    werden also exakt so bewertet wie vorher — 'teilweise' kann gar nicht
--    entstehen, solange niemand eine Regel gepflegt hat.
--
--    MC bleibt binaer. Die Abstufung bei Auswahlaufgaben ist ein ANDERER
--    Mechanismus (option_scores, A10) und gehoert nicht hierher.
-- ============================================================================

create or replace function public.lsa_grade(
  p_input_type      text,
  p_acceptance      jsonb,
  p_correct_answers jsonb,
  p_response        jsonb
)
returns text
language plpgsql
immutable
as $$
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
begin
  -- MC: unveraendert binaer, ueber die bestehende Mengengleichheit.
  if p_input_type = 'MC' then
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

  v_given := coalesce(p_response ->> 'text', p_response ->> 'value');
  if v_given is null or btrim(v_given) = '' then
    return 'nicht';
  end if;

  v_parts    := public.lsa_split_value_unit(v_given);
  v_g_num    := btrim(v_parts[1]);
  v_g_unit   := btrim(v_parts[2]);
  v_tol      := v_rule -> 'tolerance';
  v_unit_grad := coalesce((v_rule ->> 'unit_graded')::boolean, false);
  v_reduced   := coalesce((v_rule ->> 'require_reduced')::boolean, false);

  -- Die geforderte Einheit: explizit gepflegt, sonst die der kanonischen Antwort.
  v_req_unit := btrim(coalesce(
    v_rule ->> 'unit',
    (public.lsa_split_value_unit(v_rule ->> 'canonical'))[2],
    ''));
  v_req_unit := lower(v_req_unit);

  -- Kandidaten: die kanonische Antwort und ihre Aequivalente. Reihenfolge zaehlt
  -- — der erste Treffer MIT passender Einheit gewinnt, damit "1,5 m" bei
  -- unit_graded nicht an einem frueher gelisteten "150 cm" haengenbleibt.
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
    -- Einheit gar nicht mit (A10: "dann darf cm nicht zaehlen, wenn m gefordert
    -- war"). Sie bleiben in der Regel stehen — sie gelten hier nur nicht.
    if v_unit_grad and v_c_unit <> v_req_unit then
      continue;
    end if;

    if v_g_num <> '' and v_c_num <> '' then
      -- Zahlen: mathematisch vergleichen.
      if not public.lsa_values_equal(v_g_num, v_c_num, v_tol) then
        continue;
      end if;
    else
      -- Wortantworten (SHORT_TEXT ohne Zahl): der normalisierte Vergleich, den
      -- lsa_is_correct auch fuehrt. Keine zweite Konvention.
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
$$;

comment on function public.lsa_grade(text, jsonb, jsonb, jsonb) is
  'Abgestufte Bewertung EINES Scopes: voll | teilweise | nicht. teilweise = '
  'wertgleich, aber Form verfehlt (unit_graded mit falscher Einheit, '
  'require_reduced mit ungekuerztem Bruch). Ohne acceptance-Regel faellt sie auf '
  'lsa_is_correct zurueck (nur voll/nicht) — Bestandsaufgaben werden dadurch '
  'exakt wie vorher bewertet. MC bleibt binaer (Abstufung dort: option_scores). '
  'Bekommt alles als Parameter, liest nie selbst. NOCH NICHT in lsa_submit '
  'verdrahtet (A11).';

-- ============================================================================
-- 7. Execute-Grants
--
--    Auswertungs-Interna, kein Client ruft sie. Muster wie lsa_is_correct
--    (P01 §7): erst PUBLIC wegnehmen, dann service_role. Ausgenommen
--    lsa_acceptance_rule_valid — sie steht in einem CHECK auf task_solutions
--    und behaelt ihre A10-Grants (create or replace ruehrt die ACL nicht an).
-- ============================================================================

revoke execute on function public.lsa_split_value_unit(text)                from public;
revoke execute on function public.lsa_parse_fraction(text)                  from public;
revoke execute on function public.lsa_is_reduced(text)                      from public;
revoke execute on function public.lsa_values_equal(text, text, jsonb)       from public;
revoke execute on function public.lsa_grade(text, jsonb, jsonb, jsonb)      from public;

grant execute on function public.lsa_split_value_unit(text)           to service_role;
grant execute on function public.lsa_parse_fraction(text)             to service_role;
grant execute on function public.lsa_is_reduced(text)                 to service_role;
grant execute on function public.lsa_values_equal(text, text, jsonb)  to service_role;
grant execute on function public.lsa_grade(text, jsonb, jsonb, jsonb) to service_role;

commit;

-- ============================================================================
-- NACHLAUF (bewusst NICHT hier — jeder Punkt ist ein eigener Schnitt):
--
--   1. lsa_responses braucht eine Spalte, die eine Stufe halten kann
--      (z.B. `grade text check in (voll|teilweise|nicht)`, nullable, additiv
--      neben `correct`). Erst dann kann lsa_submit lsa_grade aufrufen —
--      `correct` bleibt dabei was es ist (grade='voll'), damit lsa_finish und
--      der Eltern-Report unveraendert weiterrechnen.
--   2. lsa_finish / result_summary: 'teilweise' als eigene Groesse ausweisen
--      statt sie in eine Quote zu mitteln. Eine halbe Antwort ist kein halber
--      Datenpunkt, sondern ein anderer.
--   3. Autoren-Tool: require_reduced als Schalter im Akzeptanz-Set (StepSolution),
--      inkl. i18n.
--   4. pgTAP im CI: supabase/tests/ laeuft heute weder lokal (kein Docker) noch
--      in .github/workflows/ci.yml. a11_abgestufte_bewertung.test.sql ist
--      geschrieben, aber bis dahin unbewiesen.
-- ============================================================================
