-- AF1 — Fehlbild-Erfassung (Baustein A der Spec lsa_fehlbild)
--
-- Zweck: Jede falsche (Teil-)Antwort trägt nach dem Insert den Slug des
-- gematchten Denkfehlers. Damit kann der Report sagen *welcher* Fehler vorliegt,
-- statt nur "falsch". Baustein B (Routing im adaptiven Abstieg) hängt daran,
-- ist aber NICHT Teil dieser Migration.
--
-- Additiv: keine bestehende Spalte, Funktion oder Policy wird geändert.
-- lsa_submit / a16 / a17 bleiben unberührt — der Capture läuft als Trigger und
-- ist damit unabhängig davon, welcher Submit-Pfad die Response geschrieben hat.
--
-- Verifiziert gegen Prod am 2026-07-26 (Schritt 0 der Spec):
--   * lsa_responses: keine Fehlbild-Spalte, keine Non-Internal-Trigger vorhanden
--   * lsa_normalize_answer(p_raw text) -> text, IMMUTABLE
--   * lsa_normalize_term(p_raw text)   -> text, IMMUTABLE
--   * task_solutions.acceptance jsonb, tasks.parts jsonb, tasks.input_type text
--   * tasks.id uuid = lsa_responses.task_id uuid (kein Typkonflikt)
--   * alle 232 acceptance-Zeilen tragen known_errors in Objektform (Entscheidung 1)

-- ---------------------------------------------------------------------------
-- A.1  Spalte — die Response-Zeile ist seit p02 bereits pro part_nr
-- ---------------------------------------------------------------------------

alter table public.lsa_responses
  add column if not exists fehlbild_slug text;

comment on column public.lsa_responses.fehlbild_slug is
  'Gematchtes Fehlbild dieser (Teil-)Antwort, NULL wenn korrekt oder kein Treffer. '
  'Gesetzt vom Capture-Trigger, nie vom Client.';

-- Der Report liest gezielt nur die getroffenen Fehlbilder einer Sitzung.
create index if not exists lsa_responses_fehlbild_idx
  on public.lsa_responses (session_id)
  where fehlbild_slug is not null;

-- ---------------------------------------------------------------------------
-- A.2  Match-Helfer — rein, Parameter-Disziplin nach A11
-- ---------------------------------------------------------------------------
-- Liest nie selbst aus task_solutions; known_errors und Antwort kommen als
-- Parameter. Die Antwort-Extraktion spiegelt lsa_is_correct exakt:
--   MC          -> p_response->'selected' ist ein Array von Option-Ids
--   sonst       -> coalesce(p_response->>'text', p_response->>'value')
--   TERM        -> lsa_normalize_term statt lsa_normalize_answer
-- Beide Seiten des Vergleichs laufen durch denselben Normalisierer, sonst
-- matcht '0,3' des Kindes nie gegen den Schlüssel '0,3' der Regel.

create or replace function public.lsa_fehlbild_match(
  p_kind          text,     -- 'mc' | 'short_input' | 'term' | Bestands-input_type (lower)
  p_known_errors  jsonb,    -- acceptance-Regel-Feld: object {wert: slug} ODER array [wert]
  p_response      jsonb
) returns text
language plpgsql
immutable
as $$
declare
  v_kind  text := lower(coalesce(p_kind, ''));
  v_term  boolean := (v_kind = 'term');
  v_given text;
  v_slug  text;
begin
  if p_known_errors is null or p_response is null then
    return null;
  end if;

  if v_kind = 'mc' then
    -- Ein known_errors-Schlüssel kann keine Auswahl-MENGE abbilden. Deshalb
    -- matcht MC nur bei genau einer gewählten Option; Mehrfachauswahl ist
    -- bewusst kein Fehlbild-Kandidat.
    if jsonb_typeof(p_response -> 'selected') <> 'array'
       or jsonb_array_length(p_response -> 'selected') <> 1 then
      return null;
    end if;
    v_given := public.lsa_normalize_answer(p_response -> 'selected' ->> 0);
  else
    v_given := coalesce(p_response ->> 'text', p_response ->> 'value');
    if v_given is null then
      return null;
    end if;
    v_given := case when v_term then public.lsa_normalize_term(v_given)
                    else public.lsa_normalize_answer(v_given) end;
  end if;

  if v_given is null or v_given = '' then
    return null;
  end if;

  case jsonb_typeof(p_known_errors)
    -- object {wert: slug}: labeled -> gibt den slug zurueck
    when 'object' then
      select ke.value #>> '{}'
        into v_slug
        from jsonb_each(p_known_errors) as ke(key, value)
       where case when v_term then public.lsa_normalize_term(ke.key)
                  else public.lsa_normalize_answer(ke.key) end = v_given
       limit 1;
    -- array [wert]: nur "bekannt-falsch", kein Label -> generischer Marker
    when 'array' then
      select '__known__'
        into v_slug
        from jsonb_array_elements_text(p_known_errors) as k(w)
       where case when v_term then public.lsa_normalize_term(k.w)
                  else public.lsa_normalize_answer(k.w) end = v_given
       limit 1;
    else
      v_slug := null;
  end case;

  return v_slug;
end;
$$;

revoke all on function public.lsa_fehlbild_match(text, jsonb, jsonb) from public;
grant execute on function public.lsa_fehlbild_match(text, jsonb, jsonb)
  to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- A.3  Capture-Trigger — pfad-agnostisch, rührt A16 nicht an
-- ---------------------------------------------------------------------------

create or replace function public.lsa_fehlbild_capture()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_kind text;
  v_ke   jsonb;
begin
  -- Nur echte, falsche Abgaben sind Fehlbild-Kandidaten.
  -- CHECK lsa_responses_correct_nur_bei_antwort haelt correct NULL fuer
  -- 'weiss_nicht' und 'leer' — ein "weiss nicht" ist kein Denkfehler und darf
  -- nie als einer gelabelt werden.
  if new.abgabeart <> 'antwort' or new.correct is not false then
    return null;
  end if;

  -- Fehlbild-Erfassung ist Diagnostik-Beiwerk. Ein Fehler hier darf die Abgabe
  -- eines Kindes NIE blockieren — deshalb faengt der Block alles und meldet per
  -- WARNING in die Logs, statt den Insert scheitern zu lassen.
  begin

  -- known_errors pro Teil aus acceptance ziehen.
  -- Multi-Part: acceptance -> '<nr>' -> 'known_errors'; flach: acceptance -> 'known_errors'.
  -- Der coalesce-Fallback auf die flache Form ist defensiv: in Prod sind heute
  -- ALLE acceptance-Zeilen flach und auf Ein-Teil-Items; schreibt ein kuenftiger
  -- Submit-Pfad part_nr auch dort, matcht die strikte Variante sonst stillschweigend nichts.
  select coalesce(
           ts.acceptance -> coalesce(new.part_nr::text, '') -> 'known_errors',
           ts.acceptance -> 'known_errors'
         ),
         coalesce(
           (select e.p ->> 'kind'
              from jsonb_array_elements(t.parts) as e(p)
             where (e.p ->> 'nr') = new.part_nr::text
             limit 1),
           lower(t.input_type)
         )
    into v_ke, v_kind
    from public.tasks t
    join public.task_solutions ts on ts.task_id = t.id
   where t.id = new.task_id;

  if v_ke is null then
    return null;
  end if;

  -- Auf die Primaerschluessel-Zeile schreiben. Kein Match ueber
  -- (session_id, task_id, part_nr): darauf existiert KEIN Unique-Constraint,
  -- eine Wiederholung derselben Aufgabe wuerde sonst fremde Zeilen treffen.
  update public.lsa_responses
     set fehlbild_slug = public.lsa_fehlbild_match(v_kind, v_ke, new.response)
   where id = new.id
     and fehlbild_slug is null;

  exception when others then
    raise warning 'lsa_fehlbild_capture: response=% task=% part=% -> %',
      new.id, new.task_id, new.part_nr, sqlerrm;
  end;

  return null;
end;
$$;

drop trigger if exists trg_lsa_fehlbild_capture on public.lsa_responses;
create trigger trg_lsa_fehlbild_capture
  after insert on public.lsa_responses
  for each row execute function public.lsa_fehlbild_capture();
