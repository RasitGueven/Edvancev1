-- ============================================================================
-- A10: Akzeptanz-Set + AFB-III-Option-Scoring
--
-- Zwei Luecken im Aufgaben-Datenmodell, die die auto-gradbare Diagnostik
-- braucht. Beide sind LOESUNGSDATEN und liegen deshalb ausnahmslos in der
-- Server-Only-Zone `task_solutions` (P01 §4) — nicht an `tasks`, nicht in
-- `tasks.parts`.
--
-- ----------------------------------------------------------------------------
-- BESTANDSAUFNAHME (was es schon gibt — hier wird NICHTS davon doppelt angelegt)
-- ----------------------------------------------------------------------------
--   tasks:            afb ('I'|'II'|'III'), competency_content,
--                     competency_process, competency_id, input_type (Enum inkl.
--                     MULTI_PART), unit, needs_image, parts, question_payload,
--                     assets, status, curriculum_grade, licence_text.
--   tasks.parts:      [{nr, kind(short_input|mc), prompt, unit?, options?,
--                       competency_content?, competency_process?, afb?,
--                       needs_image?}] — pro Teilaufgabe eigene Kompetenz und
--                     eigenes AFB. OEFFENTLICH: jede eingeloggte Rolle liest
--                     `tasks` (Policy read_tasks_by_role), Schueler:innen alles
--                     mit status='ready'.
--   options:          ueberall nur {id, label} — bei MC flach in
--                     tasks.question_payload.options, bei MULTI_PART in
--                     parts[].options. KEIN Feld fuer richtig/falsch und KEINES
--                     fuer eine Bewertungsstufe. lsa_parts_valid() verbietet
--                     Loesungsschluessel in parts per CHECK,
--                     tasks_question_payload_no_solution verbietet u.a. den
--                     Schluessel `accepted` in question_payload.
--   Die Loesung:      ausschliesslich task_solutions.correct_answers —
--                     flach ["0,3 m","30 cm"] oder {"<nr>":[...]} bei
--                     MULTI_PART (CHECK lsa_answers_valid). Bewertet wird mit
--                     lsa_is_correct(): normalisieren (lsa_normalize_answer:
--                     trim, Whitespace, ERSTES Komma zu Punkt, lowercase) und
--                     exakt gegen die Liste vergleichen.
--
-- ES FEHLT:
--   (A) Eine STRUKTUR hinter der Antwortliste. correct_answers ist eine flache
--       Aufzaehlung von Strings: sie sagt, WAS zaehlt, aber nicht WARUM —
--       welche Form kanonisch ist, welche Varianten blosse Notation sind, wie
--       gerundet werden darf, und ob die Einheit ueberhaupt bewertungsrelevant
--       ist. Genau das braucht ein Generator, um Varianten zu erzeugen, und ein
--       Pfleger, um sie zu pruefen. Heute steht es nur im Kopf.
--   (B) Eine BEWERTUNGSSTUFE je Antwortoption. AFB III (Urteil + Begruendung)
--       kennt kein binaeres richtig/falsch: eine Option trifft das Urteil UND
--       traegt die richtige Begruendung ('voll'), eine trifft das Urteil mit
--       schwacher Begruendung ('teilweise'), der Rest ist 'nicht'. Das Schema
--       kann bis heute nur "in correct_answers oder nicht".
--
-- ----------------------------------------------------------------------------
-- ENTSCHEIDUNG 1: beides nach `task_solutions`, nicht an tasks/parts
-- ----------------------------------------------------------------------------
--   Das Akzeptanz-Set nennt die kanonische Antwort, das Option-Scoring nennt
--   die richtige Option. Beides IST die Loesung. `tasks` ist fuer jede
--   eingeloggte Rolle lesbar, und PostgREST bietet select=* an — ein
--   Bewertungsfeld an parts[].options waere fuer jedes Schuelergeraet abrufbar.
--   Genau so ist der Altbestand-Leak entstanden (T1). Deshalb: die neuen Felder
--   liegen in der Tabelle, die KEIN Grant fuer anon/authenticated hat.
--
--   Folge fuer (B): die Stufe haengt fachlich an der Option, technisch aber
--   nicht IM options-Array. Verbunden wird ueber die Option-ID —
--   task_solutions.option_scores ist eine Abbildung `option_id -> Stufe`. Die
--   oeffentliche Option behaelt exakt {id, label}.
--
-- ----------------------------------------------------------------------------
-- ENTSCHEIDUNG 2: JSONB-Spalte, keine eigene Tabelle
-- ----------------------------------------------------------------------------
--   Eine Zeile je Teilaufgabe/Option waere relational sauberer, aber sie
--   braeuchte eigene RLS, eigene Grants und eigene RPCs — und die Server-Only-
--   Zusage muesste ein zweites Mal bewiesen werden. task_solutions traegt die
--   Loesung heute schon als JSONB mit derselben Doppelform (flach | pro
--   Teilaufgabe). Die neuen Felder folgen dieser Konvention statt eine zweite
--   danebenzustellen: eine Zeile pro Aufgabe, ein Schutzwall, ein Lesepfad.
--   Der Strukturvertrag steht dafuer im CHECK, nicht in der Hoffnung.
--
-- ----------------------------------------------------------------------------
-- ENTSCHEIDUNG 3: pro Teilaufgabe, gespiegelt an correct_answers
-- ----------------------------------------------------------------------------
--   Bei MULTI_PART hat jede Teilaufgabe ihre eigene Antwort — also auch ihr
--   eigenes Akzeptanz-Set und ihre eigene Options-Skala. Beide neuen Spalten
--   tragen deshalb dieselbe Doppelform wie correct_answers:
--     flach       → das Objekt IST die Regel bzw. die Skala
--     MULTI_PART  → {"<nr>": Regel} bzw. {"<nr>": Skala}, Schluessel = parts.nr
--   Kein drittes Format, keine dritte Konvention.
--
-- ----------------------------------------------------------------------------
-- KEIN LEAK: was diese Migration NICHT anfasst
-- ----------------------------------------------------------------------------
--   lsa_question_payload() baut den Schueler-Payload aus einer WHITELIST
--   (kind/prompt/assets/options(id,label)/unit/stem/parts) und reicht nie ein
--   bestehendes jsonb durch; lsa_public_parts() baut jede Teilaufgabe einzeln.
--   Die neuen Felder liegen ausserdem in einer Tabelle, die der Builder gar
--   nicht liest. Sie koennen strukturell nicht mitrutschen — und diese
--   Migration aendert am Payload-Bau bewusst KEINE Zeile.
--   Erreichbar sind sie nur ueber task_solution_get / task_solution_upsert
--   (SECURITY DEFINER, coach/admin bzw. admin).
--
-- ----------------------------------------------------------------------------
-- KEINE BEWERTUNGSAENDERUNG IN DIESEM LAUF
-- ----------------------------------------------------------------------------
--   lsa_is_correct() bleibt byte-identisch: geltende Bewertungsgrundlage ist
--   weiterhin correct_answers. `acceptance` ist heute DEKLARATIV — die
--   maschinenlesbare Begruendung der Liste, Eingabe fuer Generator und Pflege.
--   Ein spaeterer Lauf kann den Evaluator darauf umstellen; bis dahin gilt:
--   was zaehlen soll, steht (auch) in correct_answers.
-- ============================================================================

begin;

-- ============================================================================
-- 1. Strukturvertrag Akzeptanz-Set (immutable — steht im CHECK)
-- ============================================================================

-- EINE Akzeptanzregel — die Antwort einer Aufgabe oder einer Teilaufgabe:
--   {
--     "canonical":    "1,5 m",                     -- Pflicht, nicht leer
--     "equivalents":  ["150 cm", "1500 mm"],       -- andere Groessenordnung/Einheit
--     "notation":     { "decimal_comma": true,     -- 1,5 == 1.5
--                       "unit_optional": true,     -- "1,5" zaehlt wie "1,5 m"
--                       "ignore_case":   true,
--                       "ignore_space":  true },
--     "tolerance":    { "mode": "exact" }
--                   | { "mode": "absolute", "value": 0.05 }
--                   | { "mode": "decimals", "value": 2 },
--     "unit":         "m",
--     "unit_graded":  false                        -- s.u.
--   }
--
-- WARUM notation als FLAGS und equivalents als LISTE: Notationsvarianten sind
--   eine Regel (jede Zahl mit Komma ist auch mit Punkt richtig) — die als
--   Einzelstrings aufzuzaehlen ist Kombinatorik und laeuft auseinander. Ein
--   Wechsel der EINHEIT ist dagegen eine fachliche Aussage ("150 cm ist
--   dieselbe Laenge") und keine Schreibweise; die gehoert einzeln benannt.
--
-- WARUM unit_graded: manchmal IST die geforderte Einheit Teil der Kompetenz
--   ("Gib das Ergebnis in Metern an"). Dann darf "150 cm" NICHT zaehlen,
--   obwohl es dieselbe Laenge ist. Das kann keine Umrechnung entscheiden, das
--   entscheidet die Aufgabe. unit_graded=true verbietet deshalb zugleich
--   notation.unit_optional=true — wer die Einheit bewertet, darf sie nicht
--   weglassen lassen. Der Widerspruch ist im CHECK unrepraesentierbar, nicht
--   nur unerwuenscht.
create or replace function public.lsa_acceptance_rule_valid(p_rule jsonb)
returns boolean
language sql
immutable
as $$
  select jsonb_typeof(p_rule) = 'object'
     -- kanonische Antwort: Pflicht, String, nicht leer
     and jsonb_typeof(p_rule -> 'canonical') = 'string'
     and btrim(p_rule ->> 'canonical') <> ''
     -- equivalents: optional, Array aus nicht-leeren Strings
     and (p_rule -> 'equivalents' is null
          or (jsonb_typeof(p_rule -> 'equivalents') = 'array'
              and not exists (
                select 1 from jsonb_array_elements(p_rule -> 'equivalents') as e(v)
                 where jsonb_typeof(v) <> 'string' or btrim(v #>> '{}') = ''
              )))
     -- notation: optional, nur die vier bekannten Flags, nur Booleans
     and (p_rule -> 'notation' is null
          or (jsonb_typeof(p_rule -> 'notation') = 'object'
              and not exists (
                select 1 from jsonb_each(p_rule -> 'notation') as e(k, v)
                 where k not in ('decimal_comma', 'unit_optional',
                                 'ignore_case', 'ignore_space')
                    or jsonb_typeof(v) <> 'boolean'
              )))
     -- tolerance: optional; exact ohne Wert, absolute/decimals mit Wert
     and (p_rule -> 'tolerance' is null
          or (jsonb_typeof(p_rule -> 'tolerance') = 'object'
              and (p_rule #>> '{tolerance,mode}') in ('exact', 'absolute', 'decimals')
              and case p_rule #>> '{tolerance,mode}'
                    when 'exact' then p_rule -> 'tolerance' -> 'value' is null
                    when 'absolute' then
                      jsonb_typeof(p_rule -> 'tolerance' -> 'value') = 'number'
                      and (p_rule #>> '{tolerance,value}')::numeric > 0
                    else -- decimals: Nachkommastellen, ganzzahlig 0..6
                      jsonb_typeof(p_rule -> 'tolerance' -> 'value') = 'number'
                      and (p_rule #>> '{tolerance,value}') ~ '^[0-6]$'
                  end))
     -- unit: optional, String
     and (p_rule -> 'unit' is null or jsonb_typeof(p_rule -> 'unit') = 'string')
     -- unit_graded: optional, Boolean; default false
     and (p_rule -> 'unit_graded' is null
          or jsonb_typeof(p_rule -> 'unit_graded') = 'boolean')
     -- Der Widerspruch: bewertete Einheit + weglassbare Einheit
     and not (coalesce((p_rule ->> 'unit_graded')::boolean, false)
              and coalesce((p_rule #>> '{notation,unit_optional}')::boolean, false))
$$;

comment on function public.lsa_acceptance_rule_valid(jsonb) is
  'Strukturvertrag EINER Akzeptanzregel: canonical (Pflicht), equivalents[], '
  'notation-Flags (decimal_comma|unit_optional|ignore_case|ignore_space), '
  'tolerance (exact|absolute+value|decimals+0..6), unit, unit_graded. '
  'Verbietet unit_graded=true zusammen mit notation.unit_optional=true.';

-- Die Doppelform, gespiegelt an lsa_answers_valid:
--   flach       → eine Regel (erkennbar an `canonical`)
--   MULTI_PART  → {"<nr>": Regel}
create or replace function public.lsa_acceptance_valid(p_acceptance jsonb)
returns boolean
language sql
immutable
as $$
  select case
    when jsonb_typeof(p_acceptance) <> 'object' then false
    -- leer = "noch nicht gepflegt"; die Spalte ist nullable, '{}' ist der
    -- gleichwertige Zwischenstand eines Entwurfs
    when p_acceptance = '{}'::jsonb then true
    when p_acceptance ? 'canonical' then public.lsa_acceptance_rule_valid(p_acceptance)
    else not exists (
      select 1 from jsonb_each(p_acceptance) as e(k, v)
       where k !~ '^[1-9][0-9]*$' or not public.lsa_acceptance_rule_valid(v)
    )
  end
$$;

comment on function public.lsa_acceptance_valid(jsonb) is
  'task_solutions.acceptance: eine Regel (flach, erkennbar an canonical) oder '
  '{"<nr>": Regel} je Teilaufgabe (MULTI_PART). Spiegelt die Doppelform von '
  'correct_answers.';

-- ============================================================================
-- 2. Strukturvertrag Option-Scoring (immutable — steht im CHECK)
-- ============================================================================

-- EINE Skala — die Optionen EINER Aufgabe/Teilaufgabe:
--   { "a": "nicht", "b": "voll", "c": "teilweise", "d": "nicht" }
--
-- KONSTRUKTIONSREGEL (die eigentliche Zusage dieses Abschnitts):
--   Pro Aufgabe/Teilaufgabe gibt es GENAU EINE Option 'voll' und GENAU EINE
--   Option 'teilweise', alle uebrigen sind 'nicht'. Die Stufe haengt an der
--   EINZELNEN Option, nicht am Urteil: mehrere Optionen duerfen dasselbe
--   Ja/Nein-Urteil tragen (sie unterscheiden sich in der Begruendung), aber nur
--   EINE davon ist 'teilweise'.
--
-- Der CHECK erzwingt hier HOECHSTENS eine je Stufe — nie zwei. Die
-- Vollstaendigkeit ("genau eine") ist eine FREIGABE-Regel, kein
-- Speicher-Verbot: ein halb gepflegter Entwurf muss speicherbar bleiben.
-- Sie steht in lsa_option_scores_complete() (§4).
create or replace function public.lsa_option_scores_scale_valid(p_scale jsonb)
returns boolean
language sql
immutable
as $$
  select jsonb_typeof(p_scale) = 'object'
     and not exists (
       select 1 from jsonb_each(p_scale) as e(k, v)
        where btrim(k) = ''
           or jsonb_typeof(v) <> 'string'
           or (v #>> '{}') not in ('voll', 'teilweise', 'nicht')
     )
     and (select count(*) from jsonb_each_text(p_scale) as e(k, v)
           where v = 'voll') <= 1
     and (select count(*) from jsonb_each_text(p_scale) as e(k, v)
           where v = 'teilweise') <= 1
$$;

comment on function public.lsa_option_scores_scale_valid(jsonb) is
  'Eine Options-Skala: {option_id: voll|teilweise|nicht}. Hoechstens eine '
  '''voll'' und hoechstens eine ''teilweise'' — Vollstaendigkeit prueft erst '
  'lsa_option_scores_complete (Freigabe, nicht Speichern).';

-- Doppelform wie oben. Unterschieden wird an der Form der WERTE: Strings =
-- flache Skala, Objekte = Skala je Teilaufgabe. Gemischt ist ungueltig.
create or replace function public.lsa_option_scores_valid(p_scores jsonb)
returns boolean
language sql
immutable
as $$
  select case
    when jsonb_typeof(p_scores) <> 'object' then false
    when p_scores = '{}'::jsonb then true
    when (select bool_and(jsonb_typeof(v) = 'object')
            from jsonb_each(p_scores) as e(k, v)) then
      not exists (
        select 1 from jsonb_each(p_scores) as e(k, v)
         where k !~ '^[1-9][0-9]*$'
            or not public.lsa_option_scores_scale_valid(v)
      )
    else public.lsa_option_scores_scale_valid(p_scores)
  end
$$;

comment on function public.lsa_option_scores_valid(jsonb) is
  'task_solutions.option_scores: flache Skala {option_id: stufe} oder '
  '{"<nr>": Skala} je Teilaufgabe (MULTI_PART). Mischformen sind ungueltig.';

-- ============================================================================
-- 3. Die zwei Spalten in der Server-Only-Zone
-- ============================================================================

alter table task_solutions
  add column if not exists acceptance    jsonb,
  add column if not exists option_scores jsonb;

alter table task_solutions drop constraint if exists task_solutions_acceptance_check;
alter table task_solutions
  add constraint task_solutions_acceptance_check
  check (acceptance is null or public.lsa_acceptance_valid(acceptance));

alter table task_solutions drop constraint if exists task_solutions_option_scores_check;
alter table task_solutions
  add constraint task_solutions_option_scores_check
  check (option_scores is null or public.lsa_option_scores_valid(option_scores));

comment on column task_solutions.acceptance is
  'AKZEPTANZ-SET (Loesungsdatum!). Warum eine Antwort zaehlt, maschinenlesbar: '
  '{canonical, equivalents[], notation{decimal_comma,unit_optional,ignore_case,'
  'ignore_space}, tolerance{mode:exact|absolute|decimals,value}, unit, '
  'unit_graded}. Flach eine Regel, bei MULTI_PART {"<nr>": Regel} — dieselbe '
  'Doppelform wie correct_answers. NULL = nicht gepflegt. Relevant fuer '
  'Zahleneingabe/Freitext; reine MC braucht es nicht. unit_graded=true heisst: '
  'die geforderte Einheit ist Teil der Kompetenz, eine andere Einheit zaehlt '
  'NICHT. DEKLARATIV — bewertet wird bis auf Weiteres gegen correct_answers '
  '(lsa_is_correct unveraendert).';

comment on column task_solutions.option_scores is
  'AFB-III-OPTION-SCORING (Loesungsdatum!). Bewertungsstufe je Antwortoption: '
  '{option_id: voll|teilweise|nicht}, bei MULTI_PART {"<nr>": {...}}. '
  'KONSTRUKTIONSREGEL: genau EINE Option ''voll'', genau EINE ''teilweise'', '
  'Rest ''nicht''. Die Stufe haengt an der OPTION, nicht am Urteil — mehrere '
  'Optionen duerfen dasselbe Ja/Nein-Urteil tragen, nur eine ist ''teilweise''. '
  'Der CHECK erzwingt hoechstens eine je Stufe; genau eine prueft '
  'lsa_option_scores_complete beim Freigeben. Bei AFB I/II bleibt es binaer — '
  'dort ist die Spalte NULL. Steht hier und nicht an parts[].options, weil '
  'tasks fuer jede eingeloggte Rolle lesbar ist.';

-- ============================================================================
-- 4. Vollstaendigkeit als Freigabe-Regel (nicht als Speicher-Verbot)
--
--    Muster wie lsa_has_answers (P02): eine reine Funktion, die die Loesung als
--    PARAMETER bekommt und nie selbst liest — sie leakt deshalb nichts, egal
--    wer sie aufruft. Geprueft wird EIN Scope (eine flache Aufgabe oder eine
--    Teilaufgabe) gegen SEINE Optionen.
--
--    NICHT in task_status_set verdrahtet: das Gate wuerde damit fuer bestehende
--    AFB-III-Items sofort zuschlagen, obwohl noch kein einziges eine Skala hat.
--    Der Anschluss gehoert in den Lauf, der die AFB-III-Aufgaben baut (dann
--    zusammen mit dem Flag in src/lib/authoring/flags.ts).
-- ============================================================================

create or replace function public.lsa_option_scores_complete(
  p_afb     text,
  p_options jsonb,
  p_scale   jsonb
)
returns boolean
language sql
immutable
as $$
  select case
    -- Nur AFB III kennt Abstufung. I/II bleibt binaer (correct_answers).
    when coalesce(p_afb, '') <> 'III' then true
    when not public.lsa_option_scores_scale_valid(p_scale) then false
    when jsonb_typeof(p_options) <> 'array' or jsonb_array_length(p_options) < 2
      then false
    else
      (select count(*) from jsonb_each_text(p_scale) as e(k, v) where v = 'voll') = 1
      and (select count(*) from jsonb_each_text(p_scale) as e(k, v)
            where v = 'teilweise') = 1
      -- jede Option ist bewertet …
      and not exists (
        select 1 from jsonb_array_elements(p_options) as o(opt)
         where not (p_scale ? (opt ->> 'id'))
      )
      -- … und die Skala kennt keine Option, die es nicht gibt
      and not exists (
        select 1 from jsonb_object_keys(p_scale) as k(id)
         where not exists (
           select 1 from jsonb_array_elements(p_options) as o(opt)
            where opt ->> 'id' = k.id
         )
      )
  end
$$;

comment on function public.lsa_option_scores_complete(text, jsonb, jsonb) is
  'Freigabe-Regel fuer EINEN Scope (flache Aufgabe oder Teilaufgabe): bei '
  'afb=III genau eine ''voll'', genau eine ''teilweise'', jede Option bewertet '
  'und keine fremde Option in der Skala. Bei AFB I/II immer true. Bekommt alles '
  'als Parameter, liest nie selbst — leakt nichts. Noch NICHT in task_status_set '
  'verdrahtet (A10).';

-- ============================================================================
-- 5. Lesepfad: task_solution_get liefert die neuen Felder mit
--    (Haertung aus A01/B01 unveraendert: nur coach/admin)
-- ============================================================================

create or replace function public.task_solution_get(p_task_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_row task_solutions%rowtype;
begin
  if public.get_my_role() not in ('coach', 'admin') then
    raise exception 'task_solution_get: nur Coach/Admin' using errcode = '42501';
  end if;

  select * into v_row from task_solutions where task_id = p_task_id;

  if not found then
    return jsonb_build_object('exists', false, 'task_id', p_task_id);
  end if;

  return jsonb_build_object(
    'exists',          true,
    'task_id',         v_row.task_id,
    'correct_answers', v_row.correct_answers,
    'acceptance',      v_row.acceptance,
    'option_scores',   v_row.option_scores,
    'solution',        v_row.solution,
    'beleg',           v_row.beleg,
    'hints',           v_row.hints,
    'coach_hints',     v_row.coach_hints,
    'typical_errors',  v_row.typical_errors,
    'updated_at',      v_row.updated_at
  );
end;
$$;

comment on function public.task_solution_get(uuid) is
  'Lesepfad zu task_solutions fuer die Item-Pflege (inkl. Quellenbeleg, '
  'Akzeptanz-Set und Option-Scoring). Gegenstueck zu task_solution_upsert. '
  'Nur coach/admin — nie fuer Schueler erreichbar.';

-- ============================================================================
-- 6. Schreibpfad: task_solution_upsert bekommt die zwei Parameter
--
--    PATCH-Semantik aus B01 unveraendert: SQL-NULL = "nicht mitgeschickt" =
--    unveraendert. Explizit geleert wird mit 'null'::jsonb (wie beim Beleg).
--    Die alte 7-stellige Signatur wird GEDROPPT statt ueberladen — PostgREST
--    kann zwei Ueberladungen mit Default-Parametern nicht eindeutig aufloesen
--    ("could not choose the best candidate function"). Bestehende Aufrufe mit
--    benannten Parametern (src/lib/supabase/taskAuthoring.ts,
--    scripts/import-lsa-items.ts) treffen die neue Signatur unveraendert.
-- ============================================================================

drop function if exists public.task_solution_upsert(uuid, jsonb, text, jsonb, jsonb, jsonb, jsonb);

create or replace function public.task_solution_upsert(
  p_task_id         uuid,
  p_correct_answers jsonb default null,
  p_solution        text  default null,
  p_hints           jsonb default null,
  p_coach_hints     jsonb default null,
  p_typical_errors  jsonb default null,
  p_beleg           jsonb default null,
  p_acceptance      jsonb default null,
  p_option_scores   jsonb default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'task_solution_upsert: nur Admin' using errcode = '42501';
  end if;
  if not exists (select 1 from tasks where id = p_task_id) then
    raise exception 'task_solution_upsert: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if p_beleg is not null and jsonb_typeof(p_beleg) not in ('array', 'null') then
    raise exception 'task_solution_upsert: beleg muss ein Array sein (oder JSON-null zum Leeren)'
      using errcode = '22023';
  end if;
  -- Frueh und mit Klartext statt erst im CHECK: der Editor soll wissen, WAS
  -- nicht stimmt, nicht nur dass ein Constraint gefeuert hat.
  if p_acceptance is not null and jsonb_typeof(p_acceptance) <> 'null'
     and not public.lsa_acceptance_valid(p_acceptance) then
    raise exception 'task_solution_upsert: acceptance verletzt den Strukturvertrag '
                    '(canonical fehlt, unbekanntes notation-Flag, tolerance ungueltig '
                    'oder unit_graded zusammen mit unit_optional)'
      using errcode = '22023';
  end if;
  if p_option_scores is not null and jsonb_typeof(p_option_scores) <> 'null'
     and not public.lsa_option_scores_valid(p_option_scores) then
    raise exception 'task_solution_upsert: option_scores verletzt den Strukturvertrag '
                    '(nur voll|teilweise|nicht, hoechstens eine ''voll'' und eine '
                    '''teilweise'' je Aufgabe/Teilaufgabe)'
      using errcode = '22023';
  end if;

  insert into task_solutions as s
    (task_id, correct_answers, solution, hints, coach_hints, typical_errors, beleg,
     acceptance, option_scores, updated_at)
  values
    (p_task_id,
     coalesce(p_correct_answers, '[]'::jsonb),
     nullif(p_solution, ''),
     coalesce(p_hints, '[]'::jsonb),
     coalesce(p_coach_hints, '[]'::jsonb),
     coalesce(p_typical_errors, '[]'::jsonb),
     case when p_beleg is null or jsonb_typeof(p_beleg) = 'null' then null else p_beleg end,
     case when p_acceptance is null or jsonb_typeof(p_acceptance) = 'null'
          then null else p_acceptance end,
     case when p_option_scores is null or jsonb_typeof(p_option_scores) = 'null'
          then null else p_option_scores end,
     now())
  on conflict (task_id) do update
     set correct_answers = coalesce(p_correct_answers, s.correct_answers),
         solution        = case when p_solution is null then s.solution
                                else nullif(p_solution, '') end,
         hints           = coalesce(p_hints, s.hints),
         coach_hints     = coalesce(p_coach_hints, s.coach_hints),
         typical_errors  = coalesce(p_typical_errors, s.typical_errors),
         beleg           = case when p_beleg is null then s.beleg
                                when jsonb_typeof(p_beleg) = 'null' then null
                                else p_beleg end,
         acceptance      = case when p_acceptance is null then s.acceptance
                                when jsonb_typeof(p_acceptance) = 'null' then null
                                else p_acceptance end,
         option_scores   = case when p_option_scores is null then s.option_scores
                                when jsonb_typeof(p_option_scores) = 'null' then null
                                else p_option_scores end,
         updated_at      = now();

  return jsonb_build_object('ok', true, 'task_id', p_task_id);
end;
$$;

comment on function public.task_solution_upsert(uuid, jsonb, text, jsonb, jsonb, jsonb, jsonb, jsonb, jsonb) is
  'Schreibpfad in die Server-Only-Zone. Nur Admin. PATCH-Semantik: ein Parameter, '
  'der NULL bleibt, laesst sein Feld unveraendert. Explizit geleert wird mit '''' '
  '(solution), ''null''::jsonb (beleg, acceptance, option_scores) bzw. ''[]'' '
  '(Arrays). acceptance/option_scores werden vor dem Schreiben gegen ihren '
  'Strukturvertrag geprueft (Klartext statt CHECK-Fehler).';

-- ============================================================================
-- 7. Execute-Grants (Postgres grantet neuen Funktionen automatisch an PUBLIC —
--    also erst wegnehmen, dann gezielt geben; analog P01 §7 / P02 §10)
-- ============================================================================

revoke execute on function public.lsa_acceptance_rule_valid(jsonb)          from public;
revoke execute on function public.lsa_acceptance_valid(jsonb)               from public;
revoke execute on function public.lsa_option_scores_scale_valid(jsonb)      from public;
revoke execute on function public.lsa_option_scores_valid(jsonb)            from public;
revoke execute on function public.lsa_option_scores_complete(text, jsonb, jsonb) from public;
revoke execute on function
  public.task_solution_upsert(uuid, jsonb, text, jsonb, jsonb, jsonb, jsonb, jsonb, jsonb)
  from public;

-- Die Validatoren stehen in CHECKs auf task_solutions und sind reine
-- Struktur-Funktionen ueber ihre Parameter — sie lesen nichts und koennen
-- nichts verraten (dasselbe Argument wie bei lsa_parts_valid/lsa_answers_valid).
grant execute on function public.lsa_acceptance_rule_valid(jsonb)     to authenticated, service_role;
grant execute on function public.lsa_acceptance_valid(jsonb)          to authenticated, service_role;
grant execute on function public.lsa_option_scores_scale_valid(jsonb) to authenticated, service_role;
grant execute on function public.lsa_option_scores_valid(jsonb)       to authenticated, service_role;
grant execute on function public.lsa_option_scores_complete(text, jsonb, jsonb)
  to authenticated, service_role;
grant execute on function
  public.task_solution_upsert(uuid, jsonb, text, jsonb, jsonb, jsonb, jsonb, jsonb, jsonb)
  to authenticated, service_role;

-- task_solution_get behaelt seine Grants (create or replace aendert sie nicht).

commit;

-- ============================================================================
-- NACHLAUF (bewusst NICHT hier — es sind eigene Fenster):
--
--   1. Freigabe-Gate: lsa_option_scores_complete in task_status_set verdrahten
--      und ein blockierendes Flag in src/lib/authoring/flags.ts ergaenzen,
--      sobald die ersten AFB-III-Items existieren. Heute wuerde es den
--      Bestand blockieren.
--   2. Evaluator: lsa_is_correct gegen `acceptance` statt gegen die flache
--      Liste rechnen (Notation, Toleranz, unit_graded). Das aendert die
--      Bewertung und braucht pgTAP-Regression gegen inv2/inv3.
--   3. Autoren-Tool: Wizard-Schritt fuer Akzeptanz-Set und Options-Skala
--      (StepSolution) inkl. i18n. src/types/authoring.ts ist mit A10 schon
--      vorbereitet.
--   4. pgTAP: eigener Test, dass acceptance/option_scores ueber KEINEN Weg beim
--      Schueler landen (Muster inv8) und dass die CHECKs greifen.
-- ============================================================================
