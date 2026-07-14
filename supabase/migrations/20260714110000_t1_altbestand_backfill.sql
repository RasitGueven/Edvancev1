-- ============================================================================
-- T1 (Schritt 1 von 2): Altbestand nach `task_solutions` ueberfuehren
--
-- KONTEXT: P01 hat `task_solutions` als Server-Only-Zone eingefuehrt, aber der
--   Altbestand wurde nie saniert. `tasks.solution` und die Loesungsfelder in
--   `tasks.question_payload` (correct/accepted/pairs/blanks/expected) sind fuer
--   die Rolle `authenticated` weiterhin lesbar — die Policy
--   "authenticated_read_tasks" (Baseline) gibt die ganze Zeile frei, und
--   PostgREST bietet `select=*` an. Ein eingeloggter Schueler kann die
--   Loesungen direkt abfragen.
--
-- WAS DIESE MIGRATION TUT: Sie ueberfuehrt den Bestand — mehr nicht. Sie
--   DROPPT NICHTS. Nach ihr ist `task_solutions` die vollstaendige Quelle der
--   Wahrheit; `tasks.solution`/`question_payload` sind Duplikate, die entfernt
--   werden koennen, sobald der letzte Leser umgestellt ist.
--
-- WARUM NICHT SOFORT DROPPEN: Die Schueler-Session (`/student/session/:id`)
--   bewertet HEUTE im Browser. `sessionQueue.ts` reicht `question_payload` an
--   den Client durch, `SessionWork.tsx:46` ruft `evaluate(task.payload, …)`.
--   Der kanonische `AnswerPayload` (src/types/answerPayload.ts) IST die
--   Loesung: MC traegt `correct`, NUMERIC/SHORT_TEXT `accepted`, MATCHING
--   `pairs`, CLOZE `blanks[].accepted`, COORDINATE `expected`. Wer die Felder
--   entfernt, nimmt der Session das Einzige, wogegen sie pruefen kann. Die
--   Session muss zuerst auf `lsa_start`/`lsa_submit` (serverseitiges Grading)
--   portiert werden — eigener Branch. Erst DANN kommt der Drop (Schritt 2).
--
-- WARUM `legacy_payload`: `task_solutions.correct_answers` ist ein flaches
--   Text-Array, und `lsa_is_correct` kennt nur zwei Zweige (MC ueber
--   Option-Ids, short_input ueber text/value). MATCHING, CLOZE und COORDINATE
--   sind darin strukturell NICHT abbildbar. Ohne eine verlustfreie Ablage
--   waere der spaetere Drop ein Datenverlust. `legacy_payload` konserviert die
--   Loesungsstruktur roh — in der Server-Only-Zone, also unerreichbar fuer
--   `authenticated`. Der Port kann sie spaeter sauber uebersetzen.
-- ============================================================================

begin;

-- ============================================================================
-- 1. Konservierungs-Spalte in der Server-Only-Zone
-- ============================================================================

alter table task_solutions
  add column if not exists legacy_payload jsonb;

comment on column task_solutions.legacy_payload is
  'Roh konservierte Loesungsstruktur aus dem Altbestand (tasks.question_payload: '
  'correct/accepted/pairs/blanks/expected). Existiert, weil correct_answers ein '
  'flaches Text-Array ist und MATCHING/CLOZE/COORDINATE dort nicht abbildbar sind. '
  'Nur Migrationsgut — die LSA liest es NICHT; lsa_question_payload baut aus einer '
  'Whitelist und kann es strukturell nicht mitschleppen.';

-- ============================================================================
-- 2. Backfill
--
--    on conflict do nothing: Zeilen, die Lena bereits ueber
--    task_solution_upsert gepflegt hat (z.B. scripts/import-lsa-items.ts),
--    sind kuratiert und gewinnen. Der Altbestand fuellt nur die Luecken.
-- ============================================================================

insert into task_solutions (
  task_id, correct_answers, solution, typical_errors, legacy_payload, updated_at
)
select
  t.id,

  -- correct_answers: nur die Typen, die lsa_is_correct auch bewerten kann.
  -- Alles andere bleibt bewusst leer und lebt in legacy_payload weiter — ein
  -- halb geratenes correct_answers waere schlimmer als ein leeres.
  case
    when t.input_type = 'MC'
         and jsonb_typeof(t.question_payload -> 'correct') = 'array'
      then t.question_payload -> 'correct'

    when t.input_type in ('NUMERIC', 'SHORT_TEXT')
         and jsonb_typeof(t.question_payload -> 'accepted') = 'array'
      then (
        select coalesce(jsonb_agg(to_jsonb(x)), '[]'::jsonb)
          from jsonb_array_elements_text(t.question_payload -> 'accepted') as e(x)
      )

    when t.input_type = 'TRUE_FALSE'
         and jsonb_typeof(t.question_payload -> 'correct') = 'boolean'
      then jsonb_build_array(t.question_payload ->> 'correct')

    else '[]'::jsonb
  end,

  t.solution,

  -- tasks.typical_errors ist text[]; task_solutions.typical_errors ist das
  -- Dialog-Format [{"error":…,"socratic_question":…}]. Die sokratische Frage
  -- gibt es im Altbestand nicht — sie wird NICHT erfunden.
  (
    select coalesce(jsonb_agg(jsonb_build_object('error', te)), '[]'::jsonb)
      from unnest(coalesce(t.typical_errors, '{}'::text[])) as te
  ),

  -- legacy_payload: ausschliesslich die loesungstragenden Schluessel. Prompt,
  -- Optionen-Labels, Grid usw. sind oeffentlich und bleiben in tasks.
  nullif(
    (
      select coalesce(jsonb_object_agg(k, v), '{}'::jsonb)
        from jsonb_each(coalesce(t.question_payload, '{}'::jsonb)) as e(k, v)
       where k in ('correct', 'accepted', 'pairs', 'blanks', 'expected')
    ),
    '{}'::jsonb
  ),

  now()

from tasks t
where t.solution is not null
   or (t.typical_errors is not null and array_length(t.typical_errors, 1) > 0)
   or (
        t.question_payload is not null
        and t.question_payload ?| array['correct', 'accepted', 'pairs', 'blanks', 'expected']
      )
on conflict (task_id) do nothing;

-- ============================================================================
-- 3. Kontrolle — der Backfill muss vollstaendig sein, sonst ist der spaetere
--    Drop ein Datenverlust. Lieber hier laut scheitern als still verlieren.
-- ============================================================================

do $$
declare
  v_missing integer;
begin
  select count(*)
    into v_missing
    from tasks t
   where (
           t.solution is not null
           or (
                t.question_payload is not null
                and t.question_payload ?| array['correct', 'accepted', 'pairs', 'blanks', 'expected']
              )
         )
     and not exists (select 1 from task_solutions s where s.task_id = t.id);

  if v_missing > 0 then
    raise exception
      'T1-Backfill unvollstaendig: % Aufgabe(n) tragen eine Loesung, haben aber keine task_solutions-Zeile.',
      v_missing;
  end if;
end;
$$;

commit;
