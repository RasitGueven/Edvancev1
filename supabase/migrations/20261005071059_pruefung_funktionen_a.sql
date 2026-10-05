-- Lena-Board, Migration 2a: Bausteine (Entscheidungen 12, 13, 15, 16, 19)
--
-- Reine Hilfsfunktionen. Keine davon ist fuer Clients freigegeben: Aufrufer sind die
-- SECURITY-DEFINER-Funktionen aus 2b/2c, die als Eigentuemer laufen.
-- Begriffe: "Fassung" = {skill_key, afb, sondierrang, correct_answers, acceptance, typical_errors}
-- einer Aufgabe; "Sicht" = dieselbe Fassung so, wie Lena sie sieht (Werte zusammengefasst, typische
-- Fehler je Fehlbild). Ausgangsfassung und jetziger Stand werden immer ueber ihre Sicht verglichen.

-- ── 12 · Das Freigabe-Gate, ausgelagert aus task_status_set ─────────────────
-- Gleiche Pruefungen, gleiche Texte wie bisher. NULL = alles da.
create or replace function public.freigabe_gate_fehler(p_task_id uuid)
returns text language plpgsql stable set search_path = public, pg_temp as $$
declare v public.tasks%rowtype;
begin
  select * into v from public.tasks where id = p_task_id;
  if not found then return null; end if;
  if coalesce(btrim(v.question), '') = '' then return 'task_status_set: Stamm fehlt'; end if;
  if v.input_type is null then return 'task_status_set: input_type fehlt'; end if;
  if v.afb is null then return 'task_status_set: AFB fehlt'; end if;
  if v.cluster_id is null then return 'task_status_set: Cluster fehlt (sonst nie im LSA-Pool)'; end if;
  if v.curriculum_grade is null then return 'task_status_set: Stoffanker (curriculum_grade) fehlt'; end if;
  if not exists (select 1 from public.task_solutions s
                  where s.task_id = p_task_id
                    and public.lsa_has_answers(v.input_type, v.parts, s.correct_answers)) then
    return 'task_status_set: Loesung unvollstaendig';
  end if;
  return null;
end $$;

-- ── 13 · Warum eine Aufgabe nicht bei Lena erscheint (NULL = im Board) ──────
create or replace function public.pruef_ausschluss(p_task_id uuid)
returns text language sql stable set search_path = public, pg_temp as $$
  select case
    when t.source = 'VERA8_IQB' then 'vera8'
    when not coalesce(t.is_active, false) or t.is_tutorial or t.content_type <> 'exercise' then 'inaktiv'
    when t.input_type is null
      or t.input_type not in ('MC', 'NUMERIC', 'SHORT_TEXT', 'MULTI_PART', 'TERM') then 'typ'
    when t.skill_key is null
      or not exists (select 1 from public.skill_thema st where st.skill_key = t.skill_key) then 'ohne_fertigkeit'
    when not exists (select 1 from public.task_solutions s where s.task_id = t.id
                        and public.lsa_has_answers(t.input_type, t.parts, s.correct_answers)) then 'ohne_loesung'
    when public.freigabe_gate_fehler(t.id) is not null then 'gate'
    when (coalesce(t.needs_image, false)
          or exists (select 1 from jsonb_array_elements(t.parts) p where p -> 'needs_image' = 'true'::jsonb))
     and jsonb_array_length(t.assets) = 0
     and not exists (select 1 from public.task_figures f where f.task_id = t.id and f.svg_hash is not null)
      then 'bild_fehlt'
  end
  from public.tasks t where t.id = p_task_id
$$;

-- ── Kleine Bausteine ────────────────────────────────────────────────────────
create or replace function public.pruef_lena_status(p_status text)
returns text language sql immutable as $$
  select case p_status when 'draft' then 'offen' when 'review' then 'passt'
    when 'rueckfrage' then 'unsicher' when 'beanstandet' then 'passt_nicht'
    when 'ready' then 'freigegeben' end
$$;

create or replace function public.pruef_kurztitel(p_title text)
returns text language sql immutable as $$
  select regexp_replace(coalesce(p_title, ''), '^AFB (I|II|III) · ', '')
$$;

-- ED422 mit Schluessel im HINT; das Frontend uebersetzt den Schluessel.
create or replace function public.pruef_fehler(p_hint text, p_text text default null)
returns void language plpgsql as $$
begin
  raise exception '%', coalesce(p_text, 'pruefen: ' || p_hint) using errcode = 'ED422', hint = p_hint;
end $$;

-- Zahl mit hoechstens einer Einheit dahinter (dieselbe Lesart wie lsa_grade)?
create or replace function public.pruef_ist_zahl(p_wert text)
returns boolean language sql immutable as $$
  select coalesce(public.lsa_parse_fraction(p_wert) is not null
                  and public.lsa_is_unit((public.lsa_split_value_unit(p_wert))[2]), false)
$$;

-- Zahl- und Einheitsteil in der Schreibweise des Originals (lsa_split_value_unit normalisiert).
create or replace function public.pruef_zahl_von(p_wert text)
returns text language sql immutable as $$
  select case when public.pruef_ist_zahl(p_wert) then
    (regexp_match(btrim(p_wert), '^([-+−–]?\s?[0-9]+(?:\s+[0-9]+/[0-9]+|/[0-9]+|[.,][0-9]+)?)'))[1] end
$$;

create or replace function public.pruef_einheit_von(p_wert text)
returns text language sql immutable as $$
  select case when public.pruef_ist_zahl(p_wert) then nullif(btrim(regexp_replace(btrim(p_wert),
    '^[-+−–]?\s?[0-9]+(?:\s+[0-9]+/[0-9]+|/[0-9]+|[.,][0-9]+)?', '')), '') end
$$;

-- Dieselbe Antwort? Gleicher Text nach lsa_normalize_answer, oder gleicher Zahlenwert bei
-- gleicher (oder fehlender) Einheit.
create or replace function public.pruef_gleich(p_a text, p_b text)
returns boolean language sql immutable as $$
  select public.lsa_normalize_answer(p_a) = public.lsa_normalize_answer(p_b)
      or (public.pruef_ist_zahl(p_a) and public.pruef_ist_zahl(p_b)
          and public.lsa_values_equal(p_a, p_b)
          and (coalesce(public.pruef_einheit_von(p_a), '') = ''
               or coalesce(public.pruef_einheit_von(p_b), '') = ''
               or lower(public.pruef_einheit_von(p_a)) = lower(public.pruef_einheit_von(p_b))))
$$;

-- Werte zusammenfassen: ["22,62","22.62","22,61"] → [["22,62","22.62"],["22,61"]].
-- Reihenfolge der ersten Vorkommen bleibt; gezeigt wird je Gruppe der erste Eintrag.
create or replace function public.pruef_gruppen(p_liste jsonb)
returns jsonb language plpgsql immutable as $$
declare g jsonb := '[]'; x text; i int; hit boolean;
begin
  if jsonb_typeof(p_liste) <> 'array' then return '[]'; end if;
  for x in select e from jsonb_array_elements_text(p_liste) e loop
    hit := false;
    for i in 0 .. jsonb_array_length(g) - 1 loop
      if public.pruef_gleich(g -> i ->> 0, x) then
        g := jsonb_set(g, array[i::text], (g -> i) || to_jsonb(x)); hit := true; exit;
      end if;
    end loop;
    if not hit then g := g || jsonb_build_array(jsonb_build_array(x)); end if;
  end loop;
  return g;
end $$;

-- Schreibweisen eines Werts: Komma und Punkt, "+" bei positiven Zahlen, Unicode-Minus, mit und
-- ohne Einheit, jeweils mit und ohne Leerzeichen. Der Wert selbst steht vorn. Kein Zahlwert → nur er.
create or replace function public.pruef_schreibweisen(p_wert text, p_einheit text)
returns text[] language plpgsql immutable as $$
declare
  w text := btrim(p_wert); n text; body text; e text; f text; basis text[]; formen text[]; aus text[];
begin
  if w is null or w = '' then return '{}'; end if;
  if not public.pruef_ist_zahl(w) then return array[w]; end if;
  n := (public.lsa_split_value_unit(w))[1];
  body := ltrim(n, '-');
  basis := case when position('.' in body) > 0 then array[replace(body, '.', ','), body]
                else array[body] end;
  formen := case when left(n, 1) = '-'
    then array(select s || b from unnest(basis) b, unnest(array['-', '−']) s)
    else basis || array(select '+' || b from unnest(basis) b) end;
  e := coalesce(public.pruef_einheit_von(w), nullif(btrim(p_einheit), ''));
  aus := array[w];
  foreach f in array formen loop
    aus := aus || f;
    if e is not null then aus := aus || (f || ' ' || e) || (f || e); end if;
  end loop;
  return array(select x from unnest(aus) with ordinality u(x, i)
                group by x order by min(i));
end $$;

-- Werte schreiben: Ein Wert, der eine bestehende Gruppe anfuehrt (p_alt: Liste von Gruppen),
-- behaelt deren Original-Schreibweisen. Neue oder geaenderte Werte werden erweitert (p_erweitern)
-- oder bleiben genau so. Leere Werte fallen weg, Doppelte auch.
create or replace function public.pruef_werte_schreiben(
  p_werte jsonb, p_alt jsonb, p_einheit text, p_erweitern boolean)
returns jsonb language plpgsql immutable as $$
declare aus text[] := '{}'; w text; g jsonb;
begin
  for w in select btrim(e) from jsonb_array_elements_text(coalesce(p_werte, '[]')) e loop
    continue when w = '';
    select x into g from jsonb_array_elements(coalesce(p_alt, '[]')) x where x ->> 0 = w limit 1;
    if g is not null then
      aus := aus || array(select jsonb_array_elements_text(g));
    elsif p_erweitern then
      aus := aus || public.pruef_schreibweisen(w, p_einheit);
    else
      aus := aus || w;
    end if;
  end loop;
  return coalesce((select jsonb_agg(x order by i) from (
    select x, min(i) i from unnest(aus) with ordinality u(x, i) group by x) d), '[]');
end $$;

-- "Flach mit Regel": nur dort wertet die Engine nach dem Zahlenwert (lsa_grade).
create or replace function public.pruef_flach_regel(p_input_type text, p_acceptance jsonb)
returns boolean language sql immutable as $$
  select coalesce(p_input_type not in ('MULTI_PART', 'MC', 'TERM')
                  and jsonb_typeof(p_acceptance) = 'object' and p_acceptance ? 'canonical', false)
$$;

-- "Gewertet wird" gibt es nur bei NUMERIC oder SHORT_TEXT mit lauter Zahlwerten.
create or replace function public.pruef_regel_erlaubt(p_input_type text, p_ca jsonb, p_acceptance jsonb)
returns boolean language sql immutable as $$
  select public.pruef_flach_regel(p_input_type, p_acceptance)
     and (p_input_type = 'NUMERIC'
          or (p_input_type = 'SHORT_TEXT' and jsonb_typeof(p_ca) = 'array'
              and jsonb_array_length(p_ca) > 0
              and not exists (select 1 from jsonb_array_elements_text(p_ca) x
                               where not public.pruef_ist_zahl(x))))
$$;

-- Die Einheit der Aufgabe: acceptance.unit, sonst die im canonical, sonst die erste in der Liste.
create or replace function public.pruef_einheit(p_acceptance jsonb, p_ca jsonb)
returns text language sql immutable as $$
  select coalesce(nullif(btrim(p_acceptance ->> 'unit'), ''),
                  public.pruef_einheit_von(p_acceptance ->> 'canonical'),
                  (select public.pruef_einheit_von(x) from jsonb_array_elements_text(
                     case when jsonb_typeof(p_ca) = 'array' then p_ca else '[]' end)
                     with ordinality e(x, i)
                    where public.pruef_einheit_von(x) is not null order by i limit 1))
$$;

-- Eine Regel auf eine Liste setzen: canonical = erster Eintrag, equivalents = uebrige, alles
-- andere bleibt. Leere Eintraege zaehlen nicht; eine leere Liste aendert nichts. Ein leeres
-- equivalents wird nur geschrieben, wenn der Schluessel schon da war.
create or replace function public.pruef_liste_setzen(p_scope jsonb, p_liste jsonb)
returns jsonb language sql immutable as $$
  with l as (
    select coalesce(jsonb_agg(to_jsonb(btrim(x)) order by i), '[]') l
      from jsonb_array_elements_text(case when jsonb_typeof(p_liste) = 'array' then p_liste else '[]' end)
           with ordinality e(x, i)
     where btrim(x) <> '')
  select case when jsonb_array_length(l) = 0 then p_scope
    else coalesce(p_scope, '{}') || jsonb_build_object('canonical', l ->> 0)
         || case when jsonb_array_length(l) > 1 or coalesce(p_scope ? 'equivalents', false)
                 then jsonb_build_object('equivalents', l - 0) else '{}' end end
  from l
$$;

-- acceptance an correct_answers angleichen, flach und je Teil ("1", "2" …), nur wo schon ein
-- canonical steht (Sicherheitsnetz fuer den Editor, Entscheidung 23).
create or replace function public.pruef_acceptance_angleichen(p_acc jsonb, p_ca jsonb)
returns jsonb language sql immutable as $$
  select case
    when jsonb_typeof(p_acc) is distinct from 'object' then p_acc
    when p_acc ? 'canonical' then public.pruef_liste_setzen(p_acc, p_ca)
    when jsonb_typeof(p_ca) = 'object' then coalesce((
      select jsonb_object_agg(k, case when jsonb_typeof(v) = 'object' and v ? 'canonical'
                                      then public.pruef_liste_setzen(v, p_ca -> k) else v end)
        from jsonb_each(p_acc) e(k, v)), p_acc)
    else p_acc end
$$;

-- Die pruefbaren Felder einer Aufgabe, so wie sie jetzt in der Datenbank stehen.
create or replace function public.pruef_fassung(p_task_id uuid)
returns jsonb language sql stable set search_path = public, pg_temp as $$
  select jsonb_build_object(
    'skill_key', t.skill_key, 'afb', t.afb, 'sondierrang', t.sondierrang,
    'correct_answers', coalesce(s.correct_answers, '[]'), 'acceptance', s.acceptance,
    'typical_errors', coalesce(s.typical_errors, '[]'))
  from public.tasks t left join public.task_solutions s on s.task_id = t.id
  where t.id = p_task_id
$$;

-- Ausgangsfassung anlegen, falls sie fehlt, und zurueckgeben.
create or replace function public.pruef_ausgang_sichern(p_task_id uuid)
returns jsonb language plpgsql set search_path = public, pg_temp as $$
declare v jsonb;
begin
  insert into public.task_pruefung_ausgang (task_id, ausgang)
  values (p_task_id, public.pruef_fassung(p_task_id))
  on conflict (task_id) do nothing;
  select ausgang into v from public.task_pruefung_ausgang where task_id = p_task_id;
  return v;
end $$;

-- known_errors als Zeilen: Fehlbild, Teil (NULL = flach), Gruppen gleicher Werte.
create or replace function public.pruef_fehler_gruppen(p_acc jsonb)
returns table (slug text, teil int, gruppen jsonb) language sql immutable as $$
  with ke(teil, k, slug) as (
    select null::int, e.key, e.value #>> '{}'
      from jsonb_each(case when jsonb_typeof(p_acc -> 'known_errors') = 'object'
                           then p_acc -> 'known_errors' else '{}' end) e
    union all
    select p.key::int, e.key, e.value #>> '{}'
      from jsonb_each(case when jsonb_typeof(p_acc) = 'object' and not (p_acc ? 'canonical')
                           then p_acc else '{}' end) p,
           jsonb_each(case when jsonb_typeof(p.value -> 'known_errors') = 'object'
                           then p.value -> 'known_errors' else '{}' end) e
     where p.key ~ '^[1-9][0-9]*$')
  select slug, teil, public.pruef_gruppen(jsonb_agg(k order by length(k), k))
    from ke group by slug, teil
$$;

revoke all on function public.freigabe_gate_fehler(uuid), public.pruef_ausschluss(uuid),
  public.pruef_lena_status(text), public.pruef_kurztitel(text), public.pruef_fehler(text, text),
  public.pruef_ist_zahl(text), public.pruef_zahl_von(text), public.pruef_einheit_von(text),
  public.pruef_gleich(text, text), public.pruef_gruppen(jsonb), public.pruef_schreibweisen(text, text),
  public.pruef_werte_schreiben(jsonb, jsonb, text, boolean), public.pruef_flach_regel(text, jsonb),
  public.pruef_regel_erlaubt(text, jsonb, jsonb), public.pruef_einheit(jsonb, jsonb),
  public.pruef_liste_setzen(jsonb, jsonb), public.pruef_acceptance_angleichen(jsonb, jsonb),
  public.pruef_fassung(uuid),
  public.pruef_ausgang_sichern(uuid), public.pruef_fehler_gruppen(jsonb)
  from public, anon, authenticated;
