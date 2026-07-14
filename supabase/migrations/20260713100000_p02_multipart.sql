-- ============================================================================
-- P02: Multi-Part-Aufgabentyp
--
-- Eine Aufgabe, mehrere Teilaufgaben — jede mit eigenem Antworttyp, eigener
-- Kompetenz, eigenem AFB. Ausgewertet wird PRO TEILAUFGABE, nicht pro Item:
-- ein Item mit drei Teilaufgaben liefert drei Kompetenz-Datenpunkte, kein
-- zusammengefasstes "2 von 3". Ein Item-Gesamtergebnis gibt es nicht — es waere
-- diagnostisch wertlos.
--
-- Der Kern in vier Aenderungen:
--   1. tasks.input_type erlaubt 'MULTI_PART'; die oeffentliche Struktur der
--      Teilaufgaben liegt in der neuen Spalte tasks.parts.
--   2. task_solutions.correct_answers wird bei Multi-Part zum OBJEKT, Schluessel
--      ist die Teilaufgaben-Nummer: {"1":["20"],"2":["b"]}. Die Array-Form der
--      flachen Bestandsitems bleibt gueltig — beide koexistieren.
--   3. lsa_responses bekommt part_nr. Eine Zeile pro Teilaufgabe. Der
--      Unique-Constraint unique(session_id, task_id) haette Multi-Part hart
--      blockiert und wird durch (session_id, task_id, coalesce(part_nr,0)) ersetzt.
--   4. lsa_question_payload / lsa_submit / lsa_finish kennen den neuen Typ.
--
-- WARUM tasks.parts (und nicht tasks.question_payload): die Teilaufgabe traegt
--   ihre eigene Kompetenz und ihr eigenes AFB. Das ist Diagnostik-Metadatum, kein
--   Frage-Payload — und das Schema hatte dafuer bisher KEINEN Platz (tasks hat
--   competency_content/_process/afb nur skalar, also einmal pro Item). Ohne diese
--   Spalte waere §6 der Spec nicht baubar.
--
-- WARUM keine Loesung in tasks.parts: die Whitelist von lsa_question_payload gilt
--   REKURSIV. lsa_public_parts baut jede Teilaufgabe einzeln aus nr/kind/prompt/
--   unit/options(id,label) — es kopiert nie ein bestehendes jsonb durch. Zusaetzlich
--   verbietet lsa_parts_valid() Loesungsfelder in tasks.parts schon per CHECK.
--
-- Nicht in diesem Lauf: der Import der 86 MULTI_PART-Items (das ist C07).
-- Erst der Vertrag, dann die Daten.
-- ============================================================================

begin;

-- ============================================================================
-- 1. Struktur-Validatoren (immutable — sie stehen in CHECK-Constraints)
-- ============================================================================

-- Die oeffentliche Struktur einer Teilaufgabe. Was hier durchfaellt, kommt gar
-- nicht erst in die Tabelle: "Import verweigern und melden" (Spec §2) ist hier
-- eine Datenbank-Zusage, keine Bitte an das Import-Skript.
create or replace function public.lsa_parts_valid(p_parts jsonb)
returns boolean
language sql
immutable
as $$
  select jsonb_typeof(p_parts) = 'array'
     -- eine einzelne "Teilaufgabe" ist ein flaches Item, kein Multi-Part
     and jsonb_array_length(p_parts) >= 2
     and not exists (
       select 1
         from jsonb_array_elements(p_parts) as e(p)
        where -- nr: Ganzzahl >= 1
              coalesce(p ->> 'nr', '') !~ '^[1-9][0-9]*$'
              -- kind: nur auto-gradebar (Spec §2). Freitext/Handschrift/Foto
              -- gehoeren nicht in die LSA.
           or coalesce(p ->> 'kind', '') not in ('short_input', 'mc')
           or coalesce(btrim(p ->> 'prompt'), '') = ''
              -- MC ohne Optionen ist keine MC
           or (p ->> 'kind' = 'mc' and coalesce(jsonb_array_length(
                case when jsonb_typeof(p -> 'options') = 'array'
                     then p -> 'options' else '[]'::jsonb end), 0) < 2)
              -- Die Loesung hat in der oeffentlichen Struktur nichts zu suchen.
              -- Sie liegt in task_solutions, sonst nirgends.
           or p ?| array['correct', 'accepted', 'solution', 'correct_answers',
                         'hints', 'coach_hints', 'typical_errors']
     )
     -- nr ist eindeutig
     and (select count(distinct (p ->> 'nr')) from jsonb_array_elements(p_parts) as e(p))
         = jsonb_array_length(p_parts)
$$;

comment on function public.lsa_parts_valid(jsonb) is
  'Strukturvertrag fuer tasks.parts: >=2 Teilaufgaben, eindeutige nr, kind in '
  '(short_input|mc), nicht-leerer prompt, MC mit >=2 Optionen, KEIN Loesungsfeld. '
  'Steht im CHECK auf tasks.';

-- correct_answers: Array (flach, Bestand) ODER Objekt mit Teilaufgaben-Nummer
-- als Schluessel (Multi-Part). Beide Formen muessen koexistieren — die 14
-- importierten Bestandsitems duerfen nicht brechen.
create or replace function public.lsa_answers_valid(p_answers jsonb)
returns boolean
language sql
immutable
as $$
  select case jsonb_typeof(p_answers)
    when 'array'  then true
    when 'object' then not exists (
      select 1
        from jsonb_each(p_answers) as e(k, v)
       where k !~ '^[1-9][0-9]*$' or jsonb_typeof(v) <> 'array'
    )
    else false
  end
$$;

comment on function public.lsa_answers_valid(jsonb) is
  'task_solutions.correct_answers: Array (flach) oder {"<nr>": [...]} (Multi-Part).';

-- ============================================================================
-- 2. tasks: MULTI_PART + die Teilaufgaben-Struktur
-- ============================================================================

-- Der bestehende Constraint (aus Migration 042) kennt MULTI_PART nicht.
-- Nicht geraten — vorher nachgesehen: MC, NUMERIC, SHORT_TEXT, TRUE_FALSE,
-- FREE_TEXT, MATCHING, CLOZE, COORDINATE.
alter table tasks drop constraint if exists tasks_input_type_check;
alter table tasks
  add constraint tasks_input_type_check check (
    input_type in (
      'MC', 'NUMERIC', 'SHORT_TEXT', 'TRUE_FALSE',
      'FREE_TEXT', 'MATCHING', 'CLOZE', 'COORDINATE',
      'MULTI_PART'
    )
  );

-- Die oeffentliche Struktur der Teilaufgaben. Pro Element:
--   { nr, kind, prompt, unit?, options?,            ← geht ans Kind (Whitelist)
--     competency_content?, competency_process?, afb? }  ← Diagnostik, bleibt hier
alter table tasks
  add column if not exists parts jsonb not null default '[]'::jsonb;

alter table tasks drop constraint if exists tasks_multipart_check;
alter table tasks
  add constraint tasks_multipart_check check (
    case
      when input_type = 'MULTI_PART' then
        public.lsa_parts_valid(parts)
        -- Stamm und Teilaufgaben-Prompt sind getrennt (Spec §2). Ein Multi-Part
        -- ohne sauber abtrennbaren Stamm ist kein Multi-Part — Import verweigern.
        and coalesce(btrim(question), '') <> ''
        -- Zeitbudget ist Pflicht (Spec §5). Vier Teilaufgaben kosten die Zeit von
        -- vier Aufgaben; lsa_start darf das nicht schaetzen muessen.
        and est_duration_sec is not null
      else parts = '[]'::jsonb
    end
  );

create index if not exists tasks_parts_idx on tasks using gin (parts)
  where input_type = 'MULTI_PART';

comment on column tasks.parts is
  'Multi-Part: [{nr, kind(short_input|mc), prompt, unit?, options?, '
  'competency_content?, competency_process?, afb?}]. Leer bei flachen Items. '
  'Die Teilaufgaben-Kompetenz ist der Kern der Diagnostik — tasks.competency_* ist '
  'skalar und kann sie nicht halten. KEINE Loesung hier (CHECK tasks_multipart_check).';

-- ============================================================================
-- 3. task_solutions: correct_answers wird bei Multi-Part zum Objekt
-- ============================================================================

alter table task_solutions drop constraint if exists task_solutions_correct_answers_check;
alter table task_solutions
  add constraint task_solutions_correct_answers_check
  check (public.lsa_answers_valid(correct_answers));

comment on column task_solutions.correct_answers is
  'Flach: ["0,3 m","30 cm"]. Multi-Part: {"1":["20"],"2":["b"]} — Schluessel ist die '
  'Teilaufgaben-Nummer. Beide Formen koexistieren.';

-- ============================================================================
-- 4. lsa_responses: eine Zeile PRO TEILAUFGABE
-- ============================================================================

alter table lsa_responses
  add column if not exists part_nr integer;

alter table lsa_responses drop constraint if exists lsa_responses_part_nr_check;
alter table lsa_responses
  add constraint lsa_responses_part_nr_check check (part_nr is null or part_nr >= 1);

-- DER Constraint aus Spec §3: unique(session_id, task_id) haette die zweite
-- Teilaufgabe desselben Items abgewiesen. Bestandszeilen bekommen part_nr = null
-- (Default) und bleiben durch coalesce(...,0) weiterhin eindeutig.
alter table lsa_responses drop constraint if exists lsa_responses_once_per_item;
create unique index if not exists lsa_responses_once_per_part
  on lsa_responses (session_id, task_id, coalesce(part_nr, 0));

comment on column lsa_responses.part_nr is
  'Teilaufgaben-Nummer (Multi-Part). NULL bei flachen Items. '
  'duration_ms ist bei Multi-Part die Dauer des GESAMTEN Items — der Client misst '
  'nicht pro Teilaufgabe. Sie steht deshalb auf jeder Teilaufgaben-Zeile gleich.';

-- ============================================================================
-- 5. Der Payload-Builder — Whitelist, jetzt rekursiv
-- ============================================================================

-- Baut jede Teilaufgabe FELDWEISE neu. Weder competency_* noch afb noch
-- irgendein Loesungsfeld koennen mitrutschen: sie werden schlicht nicht gelesen.
create or replace function public.lsa_public_parts(p_parts jsonb)
returns jsonb
language sql
immutable
as $$
  select coalesce((
    select jsonb_agg(
             jsonb_strip_nulls(jsonb_build_object(
               'nr',     (p ->> 'nr')::int,
               'kind',   p ->> 'kind',
               'prompt', p ->> 'prompt',
               'unit',   p ->> 'unit',
               'options', case when p ->> 'kind' = 'mc' then coalesce((
                   select jsonb_agg(
                            jsonb_build_object('id', o ->> 'id', 'label', o ->> 'label')
                            order by ord
                          )
                     from jsonb_array_elements(
                            case when jsonb_typeof(p -> 'options') = 'array'
                                 then p -> 'options' else '[]'::jsonb end
                          ) with ordinality as oe(o, ord)
                 ), '[]'::jsonb) end
             ))
             order by (p ->> 'nr')::int
           )
      from jsonb_array_elements(
             case when jsonb_typeof(p_parts) = 'array' then p_parts else '[]'::jsonb end
           ) as e(p)
     where p ->> 'kind' in ('short_input', 'mc')
  ), '[]'::jsonb)
$$;

comment on function public.lsa_public_parts(jsonb) is
  'Whitelist fuer Teilaufgaben: nr/kind/prompt/unit/options(id,label). '
  'Kein competency_*, kein afb, keine Loesung — nichts wird durchkopiert.';

create or replace function public.lsa_question_payload(p_task_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_strip_nulls(
    case
      when t.input_type = 'MULTI_PART' then jsonb_build_object(
        'task_id', t.id,
        'kind',    'multi_part',
        -- Stamm und Teilaufgaben-Prompts sind getrennt: das Kind sieht ein Blatt,
        -- der Stamm gilt fuer alle Teilaufgaben.
        'stem',    coalesce(t.question, ''),
        'assets',  public.lsa_public_assets(t.assets),
        'parts',   public.lsa_public_parts(t.parts)
      )
      when t.input_type = 'MC' then jsonb_build_object(
        'task_id', t.id,
        'kind',    'mc',
        'prompt',  coalesce(t.question, ''),
        'assets',  public.lsa_public_assets(t.assets),
        'options', coalesce((
          select jsonb_agg(
                   jsonb_build_object('id', o ->> 'id', 'label', o ->> 'label')
                   order by ord
                 )
            from jsonb_array_elements(
                   case
                     when jsonb_typeof(t.question_payload -> 'options') = 'array'
                       then t.question_payload -> 'options'
                     else '[]'::jsonb
                   end
                 ) with ordinality as e(o, ord)
        ), '[]'::jsonb)
      )
      else jsonb_build_object(
        'task_id', t.id,
        'kind',    'short_input',
        'prompt',  coalesce(t.question, ''),
        'assets',  public.lsa_public_assets(t.assets),
        'unit',    t.unit
      )
    end
  )
  from tasks t
  where t.id = p_task_id
$$;

comment on function public.lsa_question_payload(uuid) is
  'Baut das Client-Payload aus einer Whitelist (kind/stem/prompt/assets/options/unit/parts). '
  'Die Whitelist gilt REKURSIV — auch Teilaufgaben werden feldweise gebaut. '
  'Liefert beweisbar keine Loesungsfelder — siehe pgTAP inv2/inv3.';

-- ============================================================================
-- 6. Bewertung je Teilaufgabe — dieselbe Konvention, keine zweite
-- ============================================================================

-- Der Client sendet Teilantworten als Skalare: {"1":"20","2":"b"}. lsa_is_correct
-- erwartet die StudentAnswer-Form ({text}/{value}/{selected}). Diese Funktion
-- uebersetzt — sie bewertet NICHT. Damit bleibt lsa_is_correct die einzige
-- Bewertungskonvention (Spec §4).
create or replace function public.lsa_part_answer(p_kind text, p_value jsonb)
returns jsonb
language sql
immutable
as $$
  select case
    when p_value is null or jsonb_typeof(p_value) = 'null' then null
    when p_kind = 'mc' then case jsonb_typeof(p_value)
      when 'object' then p_value                                     -- {"selected":[…]}
      when 'array'  then jsonb_build_object('selected', p_value)     -- ["b"]
      else jsonb_build_object('selected', jsonb_build_array(p_value #>> '{}'))  -- "b"
    end
    else case jsonb_typeof(p_value)
      when 'object' then p_value                                     -- {"text":…}/{"value":…}
      else jsonb_build_object('text', p_value #>> '{}')              -- "20" / 20
    end
  end
$$;

-- Pool-Eignung: hat das Item ueberhaupt eine hinterlegte Loesung? Bei Multi-Part
-- muss JEDE Teilaufgabe eine haben — ein halb gepflegtes Item gehoert nicht in
-- eine Diagnose.
create or replace function public.lsa_has_answers(
  p_input_type      text,
  p_parts           jsonb,
  p_correct_answers jsonb
)
returns boolean
language sql
immutable
as $$
  select case
    when p_input_type = 'MULTI_PART' then
      jsonb_typeof(p_correct_answers) = 'object'
      and jsonb_typeof(p_parts) = 'array'
      and jsonb_array_length(p_parts) > 0
      and not exists (
        select 1
          from jsonb_array_elements(p_parts) as e(p)
         where coalesce(jsonb_array_length(
                 case when jsonb_typeof(p_correct_answers -> (p ->> 'nr')) = 'array'
                      then p_correct_answers -> (p ->> 'nr') else '[]'::jsonb end
               ), 0) = 0
      )
    else
      jsonb_typeof(p_correct_answers) = 'array'
      and jsonb_array_length(p_correct_answers) > 0
  end
$$;

-- ============================================================================
-- 7. lsa_start — Zeitbudget statt Item-Anzahl
--
--    Der Ziehalgorithmus zog schon ueber die Summe von est_duration_sec; neu ist,
--    dass MULTI_PART in den Pool darf. Das ist genau der Punkt aus Spec §5: ein
--    Item mit vier Teilaufgaben kostet vier Aufgaben Zeit, und weil
--    tasks_multipart_check est_duration_sec fuer MULTI_PART erzwingt, muss hier
--    NICHTS geschaetzt werden.
--
--    Der coalesce-Fallback unten greift nur noch fuer FLACHE Bestandsitems (die
--    15 C03-Items tragen kein est_duration_sec — gemeldet, nicht stillschweigend
--    weggeschaetzt: siehe docs/retros/2026-07-13-P02-multipart.md).
-- ============================================================================

create or replace function public.lsa_start(
  p_student_id uuid,
  p_grade      integer,
  p_subject    text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session_id uuid;
  v_items      uuid[];
begin
  if not public.lsa_may_act_for(p_student_id) then
    raise exception 'LSA: kein Zugriff auf diesen Schueler' using errcode = '42501';
  end if;
  if not exists (select 1 from students where id = p_student_id) then
    raise exception 'LSA: Schueler nicht gefunden' using errcode = 'P0002';
  end if;
  if exists (
    select 1 from lsa_sessions
     where student_id = p_student_id and subject = p_subject and status = 'in_progress'
  ) then
    raise exception 'LSA: fuer % laeuft bereits eine Session', p_subject
      using errcode = 'P0001';
  end if;

  with pool as (
    select t.id,
           coalesce(t.afb, 'II')                as afb,
           coalesce(t.competency_content, '?')  as comp,
           -- MULTI_PART hat est_duration_sec garantiert (CHECK). Der Fallback ist
           -- ausschliesslich die Bestandsregel fuer flache Items.
           coalesce(t.est_duration_sec, t.estimated_minutes * 60, 180) as secs
      from tasks t
      join task_solutions s on s.task_id = t.id
      join skill_clusters c on c.id = t.cluster_id
      join subjects sub     on sub.id = c.subject_id
     where t.status = 'ready'
       and coalesce(t.is_active, true)
       and t.input_type in ('MC','SHORT_TEXT','NUMERIC','MULTI_PART')
       and public.lsa_has_answers(t.input_type, t.parts, s.correct_answers)
       and sub.name = p_subject
       and coalesce(t.class_level, p_grade) <= p_grade
  ),
  mixed as (
    select id,
           secs,
           row_number() over (partition by afb, comp order by random()) as rn,
           row_number() over (order by random())                        as tiebreak
      from pool
  ),
  ordered as (
    select id,
           sum(secs) over (order by rn, tiebreak
                           rows between unbounded preceding and current row) as cum,
           secs,
           rn,
           tiebreak
      from mixed
  )
  select array_agg(id order by rn, tiebreak)
    into v_items
    from ordered
   where cum - secs < 1200;

  if v_items is null or array_length(v_items, 1) = 0 then
    raise exception 'LSA: kein freigegebener Item-Pool fuer % / Klasse %', p_subject, p_grade
      using errcode = 'P0002';
  end if;

  insert into lsa_sessions (student_id, subject, grade, item_ids, started_at)
  values (p_student_id, p_subject, p_grade, v_items, now())
  returning id into v_session_id;

  return jsonb_build_object(
    'session_id',  v_session_id,
    'total_items', array_length(v_items, 1),
    'item',        public.lsa_question_payload(v_items[1])
  );
end;
$$;

-- ============================================================================
-- 8. lsa_submit — eine Anfrage, eine Zeile pro Teilaufgabe
--
--    Multi-Part: p_response = {"1":"20","2":"b","3":"16"}.
--    Flach:      p_response = {"text":"20"} / {"selected":["b"]} — unveraendert.
--    Unterschieden wird am input_type der TASK, nicht an der Form des Payloads
--    (Spec §4). Die Antwort bleibt {ok, next} — kein correct, kein Score, kein
--    Zaehler, auf keiner Ebene.
-- ============================================================================

create or replace function public.lsa_submit(
  p_session_id  uuid,
  p_task_id     uuid,
  p_response    jsonb,
  p_duration_ms integer default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session lsa_sessions;
  v_task    tasks;
  v_answers jsonb;
  v_next    uuid;
begin
  select * into v_session from lsa_sessions where id = p_session_id;
  if not found then
    raise exception 'LSA: Session nicht gefunden' using errcode = 'P0002';
  end if;
  if not public.lsa_may_act_for(v_session.student_id) then
    raise exception 'LSA: kein Zugriff auf diese Session' using errcode = '42501';
  end if;
  if v_session.status <> 'in_progress' then
    raise exception 'LSA: Session ist nicht aktiv' using errcode = 'P0001';
  end if;
  if not (p_task_id = any (v_session.item_ids)) then
    raise exception 'LSA: Item gehoert nicht zu dieser Session' using errcode = 'P0001';
  end if;

  select * into v_task from tasks where id = p_task_id;
  select s.correct_answers into v_answers from task_solutions s where s.task_id = p_task_id;

  if v_task.input_type = 'MULTI_PART' then
    if p_response is not null and jsonb_typeof(p_response) <> 'object' then
      raise exception 'LSA: Multi-Part erwartet ein Objekt {"<nr>": <antwort>}'
        using errcode = 'P0001';
    end if;

    -- Eine Zeile je Teilaufgabe — getrieben von tasks.parts, nicht vom Client.
    -- Eine fehlende Teilantwort wird als unbeantwortet (response null, correct
    -- false) festgehalten, nicht verschwiegen: sonst waere die Kompetenz still
    -- aus der Auswertung gefallen.
    insert into lsa_responses (session_id, task_id, part_nr, response, correct, duration_ms)
    select p_session_id,
           p_task_id,
           (p ->> 'nr')::int,
           p_response -> (p ->> 'nr'),
           coalesce(public.lsa_is_correct(
             case when p ->> 'kind' = 'mc' then 'MC' else 'SHORT_TEXT' end,
             case when jsonb_typeof(v_answers -> (p ->> 'nr')) = 'array'
                  then v_answers -> (p ->> 'nr') else '[]'::jsonb end,
             public.lsa_part_answer(p ->> 'kind', p_response -> (p ->> 'nr'))
           ), false),
           p_duration_ms
      from jsonb_array_elements(v_task.parts) as e(p)
    on conflict (session_id, task_id, coalesce(part_nr, 0)) do nothing;
  else
    insert into lsa_responses (session_id, task_id, part_nr, response, correct, duration_ms)
    values (
      p_session_id, p_task_id, null, p_response,
      coalesce(public.lsa_is_correct(v_task.input_type, v_answers, p_response), false),
      p_duration_ms
    )
    on conflict (session_id, task_id, coalesce(part_nr, 0)) do nothing;
  end if;

  select i.id
    into v_next
    from unnest(v_session.item_ids) with ordinality as i(id, ord)
   where not exists (
           select 1 from lsa_responses r
            where r.session_id = v_session.id and r.task_id = i.id
         )
   order by i.ord
   limit 1;

  return jsonb_build_object(
    'ok',   true,
    'next', case when v_next is null then null
                 else public.lsa_question_payload(v_next) end
  );
end;
$$;

-- ============================================================================
-- 9. lsa_finish — aggregiert ueber TEILAUFGABEN nach Kompetenz
--
--    Ein Item mit drei Teilaufgaben zu drei Kompetenzen erzeugt drei unabhaengige
--    Datenpunkte. Es gibt kein Item-Gesamtergebnis, keine "2 von 3"-Quote, keinen
--    Item-Score (Spec §6).
-- ============================================================================

create or replace function public.lsa_finish(p_session_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session lsa_sessions;
  v_summary jsonb;
begin
  select * into v_session from lsa_sessions where id = p_session_id;
  if not found then
    raise exception 'LSA: Session nicht gefunden' using errcode = 'P0002';
  end if;
  if not public.lsa_may_act_for(v_session.student_id) then
    raise exception 'LSA: kein Zugriff auf diese Session' using errcode = '42501';
  end if;
  if v_session.status = 'completed' then
    return v_session.result_summary;
  end if;

  with answered as (
    -- Die Einheit der Auswertung ist die ZEILE in lsa_responses — also die
    -- Teilaufgabe, wo es eine gibt, sonst das flache Item. Kompetenz und AFB
    -- kommen bei Multi-Part aus der Teilaufgabe (tasks.parts), nicht aus dem Item.
    select r.correct,
           r.duration_ms,
           r.task_id,
           r.part_nr,
           coalesce(part.competency, t.competency_content, '?') as competency,
           coalesce(part.afb,        t.afb,                'II') as afb,
           t.cluster_id
      from lsa_responses r
      join tasks t on t.id = r.task_id
      left join lateral (
        select p ->> 'competency_content' as competency,
               p ->> 'afb'                as afb
          from jsonb_array_elements(t.parts) as e(p)
         where r.part_nr is not null
           and (p ->> 'nr')::int = r.part_nr
         limit 1
      ) part on true
     where r.session_id = p_session_id
  ),
  by_competency as (
    select competency,
           count(*)                                          as total,
           count(*) filter (where correct)                   as correct_count,
           round(avg(duration_ms)::numeric, 0)               as avg_duration_ms,
           round(
             count(*) filter (where correct)::numeric / nullif(count(*), 0), 2
           )                                                 as hit_rate
      from answered
     group by competency
  ),
  by_afb as (
    select afb,
           count(*)                        as total,
           count(*) filter (where correct) as correct_count
      from answered
     group by afb
  ),
  weak_clusters as (
    select cluster_id,
           round(
             count(*) filter (where correct)::numeric / nullif(count(*), 0), 2
           ) as hit_rate
      from answered
     where cluster_id is not null
     group by cluster_id
    having count(*) filter (where correct)::numeric / nullif(count(*), 0) < 0.6
  )
  select jsonb_build_object(
           -- 'answered' zaehlt ITEMS (Fortschritt gegen 'planned'),
           -- 'answered_parts' die Datenpunkte. Kein Score, keine Quote.
           'answered',       (select count(distinct task_id) from answered),
           'answered_parts', (select count(*) from answered),
           'planned',        array_length(v_session.item_ids, 1),
           'competencies', coalesce((
             select jsonb_agg(jsonb_build_object(
                      'competency',      competency,
                      'total',           total,
                      'correct',         correct_count,
                      'hit_rate',        hit_rate,
                      'avg_duration_ms', avg_duration_ms
                    ) order by hit_rate nulls first)
               from by_competency), '[]'::jsonb),
           'afb', coalesce((
             select jsonb_agg(jsonb_build_object(
                      'afb', afb, 'total', total, 'correct', correct_count
                    ) order by afb)
               from by_afb), '[]'::jsonb),
           'proposal', jsonb_build_object(
             'is_proposal', true,
             'applied',     false,
             'focus_cluster_ids', coalesce((
               select jsonb_agg(cluster_id order by hit_rate) from weak_clusters
             ), '[]'::jsonb),
             'clusters', coalesce((
               select jsonb_agg(jsonb_build_object(
                        'cluster_id', w.cluster_id,
                        'name',       c.name,
                        'hit_rate',   w.hit_rate
                      ) order by w.hit_rate)
                 from weak_clusters w
                 join skill_clusters c on c.id = w.cluster_id
             ), '[]'::jsonb),
             'note', 'Vorschlag. Der Lernpfad wird erst durch die Coach-Bestaetigung aktiv (lsa_confirm_focus).'
           )
         )
    into v_summary;

  update lsa_sessions
     set status         = 'completed',
         completed_at   = now(),
         result_summary = v_summary
   where id = p_session_id;

  return v_summary;
end;
$$;

-- ============================================================================
-- 10. Execute-Grants (Postgres grantet neuen Funktionen automatisch an PUBLIC)
-- ============================================================================

revoke execute on function public.lsa_parts_valid(jsonb)                from public;
revoke execute on function public.lsa_answers_valid(jsonb)              from public;
revoke execute on function public.lsa_public_parts(jsonb)               from public;
revoke execute on function public.lsa_part_answer(text, jsonb)          from public;
revoke execute on function public.lsa_has_answers(text, jsonb, jsonb)   from public;

-- lsa_parts_valid / lsa_answers_valid stehen in CHECK-Constraints. Ein CHECK wird
-- mit den Rechten des SCHREIBENDEN ausgewertet — ohne dieses Grant koennte ein
-- Admin ueber PostgREST keine Aufgabe mehr anlegen. Sie sind reine
-- Strukturpruefer und leaken nichts.
grant execute on function public.lsa_parts_valid(jsonb)   to authenticated, service_role;
grant execute on function public.lsa_answers_valid(jsonb) to authenticated, service_role;

-- Die uebrigen sind interne Helfer der SECURITY-DEFINER-RPCs.
grant execute on function public.lsa_public_parts(jsonb)             to service_role;
grant execute on function public.lsa_part_answer(text, jsonb)        to service_role;
grant execute on function public.lsa_has_answers(text, jsonb, jsonb) to service_role;

commit;
