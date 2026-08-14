-- AF6 — die Fehlbild-Erfassung wird formunabhaengig.
--
-- BEFUND
--   Bei MULTI_PART bekam KEINE falsche Antwort einen fehlbild_slug. Bewertet
--   wurde korrekt, nur das Label fehlte — still, ohne Fehler, ohne Warnung.
--
--   Ursache ist eine Asymmetrie in lsa_submit: fuer die BEWERTUNG normalisiert
--   es die Teilantwort ueber lsa_part_answer(kind, …), das alle drei Formen
--   versteht (Objekt, Array, Skalar). GESPEICHERT wird in
--   lsa_responses.response aber die Rohantwort des Clients:
--
--     select …, p_response -> (p ->> 'nr'), …                       -- roh
--            lsa_is_correct(…, lsa_part_answer(p ->> 'kind',
--                                p_response -> (p ->> 'nr')))       -- normalisiert
--
--   lsa_fehlbild_capture reicht new.response unveraendert an
--   lsa_fehlbild_match weiter, und das versteht nur die Objektform:
--     mc          -> p_response -> 'selected' muss ein Array sein
--     short_input -> coalesce(p_response ->> 'text', p_response ->> 'value')
--   Bei einem JSON-Skalar liefern beide NULL und die Funktion gibt still null
--   zurueck.
--
--   Der Schuelerclient sendet bei MULTI_PART Skalare — und zwar vertragsgemaess.
--   edvance-app, src/types/content.ts:
--     "Antwort auf ein MULTI_PART-Item: Teilaufgaben-Nummer → skalare
--      Teilantwort, also {"1":"20","2":"b"} (DATENVERTRAG §6). Kein
--      {text}/{selected} pro Teil — lsa_part_answer baut serverseitig um."
--   Der Client haelt den Vertrag. Der Trigger wendet die Normalisierung nur
--   nicht an, auf die der Vertrag verweist.
--
-- ENTSCHEIDUNG
--   Der Fehler ist nicht die konkrete Antwortform, sondern die stille Kopplung
--   zwischen Clientformat und Diagnosefaehigkeit. Ein Format-Wechsel im Client
--   wuerde die Fehlbild-Erfassung sonst jederzeit wieder lautlos abschalten.
--   Deshalb normalisiert der Trigger selbst — mit derselben Funktion, die
--   lsa_submit fuer die Bewertung benutzt.
--
-- NACHWEIS DER UNSCHAEDLICHKEIT (gegen Produktion, 2026-08-14)
--   lsa_part_answer gibt Objekte UNVERAENDERT zurueck; nur Skalare und Arrays
--   werden umgebaut. In lsa_responses liegen 129 Antworten, ausnahmslos
--   Objekte (text 95, dont_know 30, selected 4):
--
--     select count(*) filter (where lsa_part_answer(kind, response)
--                               is distinct from response) …
--     -> NUMERIC 119: 0   TERM 6: 0   MC 4: 0
--
--   Und ueber alle 42 falschen Antworten des Bestands:
--     heute match 3, nachher match 3, Abweichungen 0.
--
--   Der Eingriff ist fuer den gesamten Altbestand nachweislich ein No-op und
--   erweitert ausschliesslich um die Skalarform.
--
-- begin/commit steht IN der Datei: scripts/db-migrate.sh ruft psql ohne
-- --single-transaction. Ein einzelnes `create or replace function` waere zwar
-- fuer sich atomar, die Kontrollzaehlung unten soll aber mit ihm zusammen
-- fallen koennen. Beim Apply deshalb KEIN --single-transaction.

begin;


-- ── Der Trigger, eine Zeile geaendert ───────────────────────────────────────
--
-- Woertlich die Fassung aus AF1 (20260726100000); EINZIGE Aenderung ist der
-- Aufruf am Ende:
--   vorher   lsa_fehlbild_match(v_kind, v_ke, new.response)
--   nachher  lsa_fehlbild_match(v_kind, v_ke, lsa_part_answer(v_kind, new.response))
-- Der Rest steht hier nur, weil `create or replace function` den ganzen Koerper
-- braucht.

create or replace function public.lsa_fehlbild_capture()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
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
  --
  -- AF6: die Antwort wird VOR dem Matchen normalisiert — dieselbe Funktion, die
  -- lsa_submit fuer die Bewertung benutzt. Damit haengt die Diagnosefaehigkeit
  -- nicht mehr daran, in welcher der drei zulaessigen Formen der Client die
  -- Antwort geschickt hat. Objekte gibt lsa_part_answer unveraendert zurueck.
  update public.lsa_responses
     set fehlbild_slug = public.lsa_fehlbild_match(
                           v_kind, v_ke,
                           public.lsa_part_answer(v_kind, new.response))
   where id = new.id
     and fehlbild_slug is null;

  exception when others then
    raise warning 'lsa_fehlbild_capture: response=% task=% part=% -> %',
      new.id, new.task_id, new.part_nr, sqlerrm;
  end;

  return null;
end;
$function$;

comment on function public.lsa_fehlbild_capture() is
  'AF1/AF6: labelt eine falsche Abgabe mit dem passenden Fehlbild-Slug aus '
  'acceptance->known_errors (bei MULTI_PART unter der part_nr). Die Antwort '
  'wird vor dem Matchen ueber lsa_part_answer normalisiert — sonst haengt die '
  'Erfassung an der Antwortform des Clients und faellt bei Skalaren still aus.';


-- ── Kontrolle ───────────────────────────────────────────────────────────────
--
-- Die Aenderung ist eine Zeile in einem 60-Zeilen-Koerper. Ohne Probe faellt
-- ein `create or replace`, das versehentlich die alte Fassung schreibt, erst
-- im Betrieb auf — und zwar als AUSBLEIBENDES Label, also gar nicht.

do $$
begin
  if pg_get_functiondef('public.lsa_fehlbild_capture'::regproc) !~ 'lsa_part_answer' then
    raise exception 'AF6: der Trigger normalisiert die Antwort nicht — alte Fassung aktiv?';
  end if;

  -- Und die Normalisierung selbst tut, was sie soll: Skalar wird matchbar,
  -- Objekt bleibt unveraendert.
  if public.lsa_fehlbild_match('mc', '{"c":"probe"}'::jsonb,
       public.lsa_part_answer('mc', '"c"'::jsonb)) is distinct from 'probe' then
    raise exception 'AF6: mc-Skalar wird nach der Normalisierung nicht gematcht';
  end if;
  if public.lsa_part_answer('mc', '{"selected":["c"]}'::jsonb)
     is distinct from '{"selected":["c"]}'::jsonb then
    raise exception 'AF6: lsa_part_answer veraendert die Objektform';
  end if;

  raise notice 'AF6: Fehlbild-Erfassung normalisiert die Antwort';
end $$;

commit;
