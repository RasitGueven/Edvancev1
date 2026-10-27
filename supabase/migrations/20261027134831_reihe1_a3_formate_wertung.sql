-- Reihe 1 · A3 Formate: Wertung (Konzept §7, Datenvertrag §13.1 und §13.6).
--
-- Sechs neue Antwortformate als input_type: FELDMASKE, LOESUNGSMENGE, GRAPH_AUSWAHL, FEHLER_FINDEN, BAUSTEINE,
-- SCHRITTE_ORDNEN. Je Instanz:
--   tasks.question_payload          Kindersicht {format = lower(input_type), …}; CHECK tasks_format_passt haelt
--                                   input_type und format zusammen (beide Erkennungen sind damit gleichwertig)
--   task_solutions.correct_answers  [ {<Loesung des Formats>, "fehlbilder": [{"key": <qf_…>, <Antwort-Bedeutung>}]} ]
--                                   — eine Liste mit einem Objekt, damit lsa_has_answers und session_im_pool
--                                   unveraendert gelten; acceptance bleibt leer (lsa_acceptance_valid kennt nur den
--                                   Wert-Pfad)
--   tasks_question_payload_no_solution sperrt zusaetzlich die Loesungsschluessel der neuen Formate.
--
-- Wertung rein und ohne Aufgabe aufrufbar: format_werten_daten(format, payload, loesung, fehlbilder, antwort). Die
-- Pruefmaschine (A4, Pruefung 4) ruft genau diese Funktion per dbread; aufgabe_werten und session_bewerten rufen sie
-- ueber format_werten. Zahlen vergleicht format_bruch exakt als gekuerzter Bruch (Bruch, Dezimal, Komma,
-- typografisches Minus, "+3", negativer Nenner); pgTAP reihe1_a3_formate sichert, dass format_zahl_gleich auf den
-- Probefaellen dasselbe sagt wie lsa_grade.
--
-- Feldmaske: Aus den Feldern wird die Bedeutung gebildet — ein Vorzeichen-Feld wirkt auf das naechste Zahlfeld,
-- "leer heisst 1" je Feld. Verglichen wird je Zahlfeld der Wert mit Vorzeichen. [+][3] und [−][−3] sind gleich.
-- Loesungsmenge: Mengengleichheit (Reihenfolge egal, doppelte Werte einmal, leere Felder zaehlen nicht), "keine
-- Loesung" als eigener Wert. Passt ein Fehlbild, gilt es; sonst ist eine echte nicht leere Teilmenge der Loesung
-- "teilmenge": aufgabe_werten liefert die feste Rueckmeldung "Eine Lösung fehlt noch.", session_bewerten den Schluessel
-- qf_loesung_fehlt (damit antwort_abgeben und die Bewaehrung sie wie ein Fehlbild fuehren). Beides ist falsch.

alter table public.tasks drop constraint tasks_input_type_check;
alter table public.tasks add constraint tasks_input_type_check check (input_type = any (array[
  'MC', 'NUMERIC', 'SHORT_TEXT', 'TRUE_FALSE', 'FREE_TEXT', 'MATCHING', 'CLOZE', 'COORDINATE', 'MULTI_PART', 'TERM',
  'FELDMASKE', 'LOESUNGSMENGE', 'GRAPH_AUSWAHL', 'FEHLER_FINDEN', 'BAUSTEINE', 'SCHRITTE_ORDNEN']::text[]));
alter table public.tasks add constraint tasks_format_passt check (
  (input_type in ('FELDMASKE', 'LOESUNGSMENGE', 'GRAPH_AUSWAHL', 'FEHLER_FINDEN', 'BAUSTEINE', 'SCHRITTE_ORDNEN'))
  = coalesce(jsonb_typeof(question_payload) = 'object' and question_payload ? 'format', false)
  and (not coalesce(question_payload ? 'format', false) or question_payload ->> 'format' = lower(input_type)));
alter table public.tasks drop constraint tasks_question_payload_no_solution;
alter table public.tasks add constraint tasks_question_payload_no_solution check (
  question_payload is null or not (question_payload ?| array['correct', 'accepted', 'pairs', 'blanks', 'expected',
    'werte', 'menge', 'keine_loesung', 'option', 'reihenfolgen', 'fehlbilder', 'loesung', 'richtig']));

insert into public.fehlbild_labels (slug, klartext, familie)
values ('qf_loesung_fehlt', 'Gibt nur einen Teil der Lösungen an (keine bekannte Ursache).', 'gleichungen_umformen')
on conflict (slug) do nothing;

-- Zahl als gekuerzter Bruch "z/n" (n > 0): "−3", "-3", "+3", "3,5", "3.5", "7/2", "−7/2", "7/−2". Sonst null.
-- Leerzeichen nur am Rand (auch geschuetzte); ein Leerzeichen zwischen Ziffern ("3 1/2") ist unlesbar.
create function public.format_bruch(p text)
returns text
language plpgsql
immutable
as $$
declare
  s text := coalesce(p, '');
  m text[];
  z numeric;
  n numeric;
  g numeric;
begin
  s := regexp_replace(s, '^[\s   ]+|[\s   ]+$', '', 'g');
  s := translate(s, '−–,', '--.');
  if length(s) > 40 then
    return null;
  end if;
  m := regexp_match(s, '^([+-]?)([0-9]+)(?:\.([0-9]+))?(?:/([+-]?)([0-9]+))?$');
  if m is null or (m[3] is not null and m[5] is not null) then
    return null;
  end if;
  z := (m[2] || coalesce(m[3], ''))::numeric;
  n := case when m[3] is not null then power(10::numeric, length(m[3])) else 1 end;
  if m[5] is not null then
    n := m[5]::numeric;
    if n = 0 then
      return null;
    end if;
  end if;
  if (m[1] = '-') <> (coalesce(m[4], '') = '-') then
    z := -z;
  end if;
  g := gcd(z, n);
  if g = 0 then
    return '0/1';
  end if;
  return trunc(z / g)::text || '/' || trunc(n / g)::text;
end $$;

create function public.format_zahl_gleich(a text, b text)
returns boolean language sql immutable as $$
  select coalesce(public.format_bruch(a) = public.format_bruch(b), false)
$$;

create function public.format_wahr(p jsonb)
returns boolean language sql immutable as $$
  select coalesce(jsonb_typeof(p) = 'boolean' and p = 'true'::jsonb, false)
$$;

create function public.format_liste(p jsonb)
returns jsonb language sql immutable as $$
  select case when jsonb_typeof(p) = 'array' then p else '[]'::jsonb end
$$;

-- Bedeutung einer Feldmaske: {zahlfeld: gekuerzter Bruch mit Vorzeichen}. Fehlt ein Pflichtfeld, null.
create function public.format_feldmaske_bedeutung(p_schablone jsonb, p_felder jsonb)
returns jsonb
language plpgsql
immutable
as $$
declare
  teil jsonb;
  v_minus boolean := false;
  v_roh text;
  v_b text;
  v jsonb := '{}'::jsonb;
begin
  if jsonb_typeof(p_felder) is distinct from 'object' then
    return null;
  end if;
  for teil in select x from jsonb_array_elements(public.format_liste(p_schablone)) x loop
    continue when jsonb_typeof(teil) <> 'object' or not (teil ? 'feld');
    v_roh := btrim(coalesce(p_felder ->> (teil ->> 'feld'), ''));
    if teil ->> 'typ' = 'vorzeichen' then
      v_minus := v_roh in ('-', '−', '–');  -- Start "+"
      continue;
    end if;
    if v_roh = '' then
      if public.format_wahr(teil -> 'leer_heisst_eins') then
        v_roh := '1';
      else
        return null;
      end if;
    end if;
    v_b := public.format_bruch(v_roh);
    if v_b is null then
      return null;
    end if;
    if v_minus and v_b <> '0/1' then
      v_b := case when left(v_b, 1) = '-' then substr(v_b, 2) else '-' || v_b end;
    end if;
    v := v || jsonb_build_object(teil ->> 'feld', v_b);
    v_minus := false;
  end loop;
  return v;
end $$;

-- Gleiche Felder, je Feld derselbe Wert (Loesung und Fehlbilder duerfen jede Schreibweise nutzen).
create function public.format_werte_gleich(a jsonb, b jsonb)
returns boolean language sql immutable as $$
  select coalesce(jsonb_typeof(a) = 'object' and jsonb_typeof(b) = 'object'
     and (select coalesce(array_agg(k order by k), '{}') from jsonb_object_keys(a) k)
       = (select coalesce(array_agg(k order by k), '{}') from jsonb_object_keys(b) k)
     and not exists (select 1 from jsonb_each_text(a) x where not public.format_zahl_gleich(x.value, b ->> x.key)), false)
$$;

-- Menge aus Texten: distinct gekuerzte Brueche; leere Elemente zaehlen nicht; ein unlesbares Element → null.
create function public.format_menge(p jsonb)
returns text[]
language sql
immutable
as $$
  select case when bool_and(public.format_bruch(e) is not null) is false then null
              else coalesce(array_agg(distinct public.format_bruch(e) order by public.format_bruch(e)), '{}') end
    from jsonb_array_elements_text(public.format_liste(p)) e
   where btrim(e) <> ''
$$;

create function public.format_set(p jsonb)
returns text[] language sql immutable as $$
  select coalesce(array_agg(distinct e order by e), '{}') from jsonb_array_elements_text(public.format_liste(p)) e
$$;

create function public.format_werten_daten(p_format text, p_payload jsonb, p_loesung jsonb, p_fehlbilder jsonb,
                                           p_antwort jsonb)
returns table (richtig boolean, fehlbild_key text, teilmenge boolean)
language plpgsql
immutable
as $$
declare
  f jsonb;
  v_a jsonb;
  v_a_menge text[];
  v_l_menge text[];
  v_keine boolean;
begin
  teilmenge := false;
  fehlbild_key := null;
  richtig := false;
  p_fehlbilder := public.format_liste(p_fehlbilder);
  p_antwort := case when jsonb_typeof(p_antwort) = 'object' then p_antwort else '{}'::jsonb end;
  p_loesung := case when jsonb_typeof(p_loesung) = 'object' then p_loesung else '{}'::jsonb end;
  case p_format
    when 'feldmaske' then
      v_a := public.format_feldmaske_bedeutung(p_payload -> 'schablone', p_antwort -> 'felder');
      richtig := public.format_werte_gleich(v_a, p_loesung -> 'werte');
      if not richtig and v_a is not null then
        select x ->> 'key' into fehlbild_key from jsonb_array_elements(p_fehlbilder) x
         where public.format_werte_gleich(v_a, x -> 'werte') limit 1;
      end if;
    when 'loesungsmenge' then
      v_keine := public.format_wahr(p_antwort -> 'keine_loesung');
      v_a_menge := case when v_keine then null else public.format_menge(p_antwort -> 'werte') end;
      v_l_menge := public.format_menge(p_loesung -> 'menge');
      if public.format_wahr(p_loesung -> 'keine_loesung') then
        richtig := v_keine;
      else
        richtig := coalesce(not v_keine and cardinality(v_a_menge) > 0 and v_a_menge = v_l_menge, false);
      end if;
      if not richtig and (v_keine or cardinality(v_a_menge) > 0) then
        for f in select x from jsonb_array_elements(p_fehlbilder) x loop
          if (public.format_wahr(f -> 'keine_loesung') and v_keine)
             or (f ? 'menge' and not v_keine and v_a_menge = public.format_menge(f -> 'menge')) then
            fehlbild_key := f ->> 'key';
            exit;
          end if;
        end loop;
        teilmenge := fehlbild_key is null and not v_keine and coalesce(cardinality(v_a_menge), 0) > 0
                     and v_l_menge is not null and v_a_menge <@ v_l_menge
                     and cardinality(v_a_menge) < cardinality(v_l_menge);
      end if;
    when 'graph_auswahl' then
      richtig := coalesce(p_antwort ->> 'gewaehlt' = p_loesung ->> 'option', false);
      if not richtig then
        select x ->> 'key' into fehlbild_key from jsonb_array_elements(p_fehlbilder) x
         where x ->> 'option' = p_antwort ->> 'gewaehlt' limit 1;
      end if;
    when 'fehler_finden' then
      richtig := coalesce(p_antwort ->> 'zeile' = p_loesung ->> 'zeile' and p_antwort ->> 'warum' = p_loesung ->> 'warum', false);
      if not richtig then
        -- Das genaueste Fehlbild zuerst (Zeile und Warum vor nur einem von beiden).
        select x ->> 'key' into fehlbild_key from jsonb_array_elements(p_fehlbilder) x
         where (x ? 'zeile' or x ? 'warum')
           and (not x ? 'zeile' or x ->> 'zeile' = p_antwort ->> 'zeile')
           and (not x ? 'warum' or x ->> 'warum' = p_antwort ->> 'warum')
         order by (x ? 'zeile')::int + (x ? 'warum')::int desc limit 1;
      end if;
    when 'bausteine' then
      richtig := cardinality(public.format_set(p_antwort -> 'gewaehlt')) > 0
                 and public.format_set(p_antwort -> 'gewaehlt') = public.format_set(p_loesung -> 'gewaehlt');
      if not richtig then
        select x ->> 'key' into fehlbild_key from jsonb_array_elements(p_fehlbilder) x
         where x ? 'gewaehlt' and public.format_set(x -> 'gewaehlt') = public.format_set(p_antwort -> 'gewaehlt') limit 1;
      end if;
    when 'schritte_ordnen' then
      richtig := jsonb_typeof(p_antwort -> 'reihenfolge') = 'array'
                 and exists (select 1 from jsonb_array_elements(public.format_liste(p_loesung -> 'reihenfolgen')) r
                              where r = p_antwort -> 'reihenfolge');
      if not richtig then
        select x ->> 'key' into fehlbild_key from jsonb_array_elements(p_fehlbilder) x
         where x -> 'reihenfolge' = p_antwort -> 'reihenfolge' limit 1;
      end if;
    else
      raise exception 'format_werten_daten: unbekanntes Format %', p_format using errcode = '22023';
  end case;
  richtig := coalesce(richtig, false);
  return next;
end $$;

-- Wertung einer gespeicherten Instanz eines neuen Formats (ruft aufgabe_werten und session_bewerten).
create function public.format_werten(p_task uuid, p_antwort jsonb)
returns table (richtig boolean, fehlbild_key text, rueckmeldung text, teilmenge boolean)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  t public.tasks;
  s public.task_solutions;
  r record;
begin
  select * into t from public.tasks where id = p_task;
  select * into s from public.task_solutions where task_id = p_task;
  select * into r from public.format_werten_daten(lower(t.input_type), t.question_payload, s.correct_answers -> 0,
                                                  s.correct_answers -> 0 -> 'fehlbilder', p_antwort);
  richtig := r.richtig;
  fehlbild_key := r.fehlbild_key;
  teilmenge := r.teilmenge;
  rueckmeldung := case when r.fehlbild_key is not null then public.aufgabe_rueckmeldung(p_task, r.fehlbild_key)
                       when r.teilmenge then 'Eine Lösung fehlt noch.' end;
  return next;
end $$;

-- session_bewerten wertet die neuen Formate ueber format_werten (antwort_abgeben speichert damit Ergebnis und Fehlbild
-- wie bei jedem anderen Format; eine Teilmenge als qf_loesung_fehlt). Fuer alle bisherigen Formate Zeile fuer Zeile
-- die Fassung aus Prod (27.10.2026).
create or replace function public.session_bewerten(p_task_id uuid, p_teil integer, p_eingabe jsonb, OUT ergebnis text,
                                                   OUT fehlbild_slug text)
 RETURNS record
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  t      public.tasks;
  v_ca   jsonb;
  v_acc  jsonb;
  v_p    jsonb;
  v_kind text;
  v_resp jsonb;
  v_ok   boolean;
  v_st   text;
  v_f    record;
begin
  select * into t from public.tasks where id = p_task_id;
  if t.input_type in ('FELDMASKE', 'LOESUNGSMENGE', 'GRAPH_AUSWAHL', 'FEHLER_FINDEN', 'BAUSTEINE', 'SCHRITTE_ORDNEN') then
    select * into v_f from public.format_werten(p_task_id, p_eingabe);
    ergebnis := case when v_f.richtig then 'richtig' else 'falsch' end;
    fehlbild_slug := coalesce(v_f.fehlbild_key, case when v_f.teilmenge then 'qf_loesung_fehlt' end);
    return;
  end if;
  select s.correct_answers, s.acceptance into v_ca, v_acc from public.task_solutions s where s.task_id = p_task_id;
  if t.input_type = 'MULTI_PART' then
    select x into v_p from jsonb_array_elements(t.parts) x where (x ->> 'nr')::int = p_teil;
    if v_p is null then
      raise exception 'antwort_abgeben: Teil % gibt es nicht', p_teil using errcode = '22023';
    end if;
    v_kind := v_p ->> 'kind';
    v_resp := public.lsa_part_answer(v_kind, p_eingabe);
    v_ok := coalesce(public.lsa_is_correct(case when v_kind = 'mc' then 'MC' else 'SHORT_TEXT' end,
              case when jsonb_typeof(v_ca -> (v_p ->> 'nr')) = 'array' then v_ca -> (v_p ->> 'nr') else '[]' end,
              v_resp), false);
    v_st := case when v_ok then 'voll' else 'nicht' end;
    v_acc := coalesce(v_acc -> (v_p ->> 'nr') -> 'known_errors', v_acc -> 'known_errors');
  else
    v_kind := lower(t.input_type);
    v_resp := public.lsa_part_answer(v_kind, p_eingabe);
    v_ok := coalesce(public.lsa_is_correct(t.input_type, v_ca, v_resp), false);
    v_st := case when t.input_type in ('MC', 'TERM') then case when v_ok then 'voll' else 'nicht' end
                 else public.lsa_grade(t.input_type, v_acc, v_ca, v_resp) end;
    v_acc := v_acc -> 'known_errors';
  end if;
  ergebnis := case v_st when 'voll' then 'richtig' when 'teilweise' then 'teilweise' else 'falsch' end;
  if ergebnis <> 'richtig' then
    fehlbild_slug := public.lsa_fehlbild_match(v_kind, v_acc, v_resp);
  end if;
end;
$function$;

do $$
declare f text;
begin
  execute 'revoke all on function public.format_werten(uuid, jsonb) from public, anon, authenticated';
  foreach f in array array['format_bruch(text)', 'format_zahl_gleich(text,text)', 'format_wahr(jsonb)',
                           'format_liste(jsonb)', 'format_feldmaske_bedeutung(jsonb,jsonb)',
                           'format_werte_gleich(jsonb,jsonb)', 'format_menge(jsonb)', 'format_set(jsonb)',
                           'format_werten_daten(text,jsonb,jsonb,jsonb,jsonb)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
  execute $c$comment on function public.format_werten_daten(text,jsonb,jsonb,jsonb,jsonb) is 'reihe1 fertig'$c$;
  execute $c$comment on function public.format_werten(uuid,jsonb) is 'reihe1 fertig'$c$;
end $$;
