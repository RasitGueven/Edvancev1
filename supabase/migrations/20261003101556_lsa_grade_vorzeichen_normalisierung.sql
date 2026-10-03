-- ============================================================================
-- Skill-Urteil: Vorzeichen-Schreibweisen im Zahlenparser (K12)
-- ============================================================================
--
-- Befund (docs/prefill/befunde-k9-kreis.md, K12): lsa_is_correct wertet "+11",
-- "- 3" und "−3" (U+2212) als richtig, weil diese Schreibweisen in
-- correct_answers stehen. lsa_grade liest die Zahl ueber lsa_split_value_unit,
-- und dessen Muster '^-?[0-9]+…' faengt keine dieser Formen. Der Zahlteil bleibt
-- leer, lsa_grade faellt auf den Textvergleich gegen canonical zurueck, und das
-- Urteil lautet "nicht", obwohl correct = true ist.
--
-- Abhilfe an der Ursache, nicht in den Daten: Der Zahlenparser normalisiert vor
-- dem Vergleich das Vorzeichen.
--   - U+2212 (Minuszeichen), U+2013 und U+2014 (Gedankenstriche) -> "-"
--   - fuehrendes "+" vor einer Zahl entfaellt
--   - Leerraum zwischen Vorzeichen und Zahl entfaellt, aussen getrimmt
--   - Dezimalkomma, Kleinschreibung, Leerraum wie bisher (lsa_normalize_answer)
--
-- Einzige Stelle ist lsa_split_value_unit: lsa_parse_fraction, lsa_is_reduced
-- und lsa_grade lesen die Zahl nur darueber (pg_proc, Prod 03.10.2026). Die
-- Normalisierung steht trotzdem in einer eigenen Hilfsfunktion, damit
-- lsa_split_value_unit sie nicht dreimal ausschreibt und der Test sie direkt
-- pruefen kann.
--
-- Unveraendert: lsa_normalize_answer und damit lsa_is_correct und
-- lsa_fehlbild_match, alle Signaturen und Grants (create or replace),
-- task_solutions. lsa_split_value_unit wird nur in der Normalisierung
-- geaendert; das Muster bleibt Zeichen fuer Zeichen gleich.

create or replace function public.lsa_normalize_number(p_raw text)
returns text
language sql
immutable
as $$
  -- Auf lsa_normalize_answer aufgesetzt, nicht daneben: was dort gilt
  -- (trimmen, Leerraum zusammenfassen, Komma -> Punkt, klein), gilt hier auch.
  -- Die Vorzeichenregeln greifen nur unmittelbar vor einer Ziffer — "+ x" oder
  -- ein Wort mit Bindestrich bleiben, wie sie sind.
  select case
    when p_raw is null then null
    else btrim(
      regexp_replace(
        regexp_replace(
          translate(public.lsa_normalize_answer(p_raw),
                    chr(8722) || chr(8211) || chr(8212), '---'),
          '^\+ ?(?=[0-9])', ''),
        '^- (?=[0-9])', '-'))
  end
$$;

-- Auswertungs-Interna wie die Geschwister (A11 §7): erst PUBLIC weg, dann
-- service_role. Ergibt dieselbe ACL wie lsa_split_value_unit in Prod.
revoke execute on function public.lsa_normalize_number(text) from public;
grant execute on function public.lsa_normalize_number(text) to service_role;

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
        substring(public.lsa_normalize_number(p_raw)
                  from '^(-?[0-9]+(?:[[:space:]]+[0-9]+/[0-9]+|/[0-9]+|\.[0-9]+)?)'),
        ''),
      btrim(coalesce(
        substring(public.lsa_normalize_number(p_raw)
                  from '^-?[0-9]+(?:[[:space:]]+[0-9]+/[0-9]+|/[0-9]+|\.[0-9]+)?[[:space:]]*(.*)$'),
        public.lsa_normalize_number(p_raw)))
    ]
  end
$$;
