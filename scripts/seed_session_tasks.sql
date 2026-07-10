-- ============================================================================
-- Edvance · Spielbare Demo-Aufgaben für die Präsenz-Session seeden
-- ----------------------------------------------------------------------------
-- ZWECK: Legt Aufgaben mit KORREKTEM `question_payload` an, damit
--        /student/session/:id tatsächlich Aufgaben ausspielt.
--
-- WARUM nötig: Kein Seed, kein Importer und auch `createDiagnosticTask`
--   (src/lib/supabase/tasks.ts) schreibt jemals `tasks.question_payload`.
--   Ohne Payload filtert `toSessionTask`
--   (src/pages/student/session/sessionQueue.ts:24-30) jede Aufgabe still
--   heraus → die Session lädt, zeigt aber nichts.
--
-- ACHTUNG (Falle): `isAnswerPayload` (src/types/answerPayload.ts) prüft NUR,
--   ob ein Objekt vorliegt und ob ein evtl. gesetztes `input_type` passt — es
--   validiert die STRUKTUR NICHT. Ein `'{}'::jsonb` gilt daher als „spielbar",
--   erzeugt bei MC aber eine Aufgabe ohne Optionen. Die Payloads unten sind
--   deshalb exakt nach dem kanonischen Vertrag gebaut.
--
-- FernUSG: Diese Aufgaben tragen NUR question_payload/solution. Es wird KEINE
--   Mastery gesetzt — Mastery bleibt Coach-only (Gate-Trigger, P03c).
--
-- IDEMPOTENT: über den UNIQUE-Constraint tasks_source_ref_unique (source,
--   source_ref, schema.sql:319). Mehrfaches Ausführen aktualisiert, dupliziert
--   nicht.
--
-- ⚠️ VORAUSSETZUNG P03b: Diese Aufgaben werden erst ausgespielt, wenn der
--   P03b-Branch (`auto/P03b-session-persist-*`) in `dev` gemergt ist. Solange
--   `src/pages/student/session/warmup.ts` existiert und `sessionQueue.ts`
--   fehlt, lädt /student/session/:id weiterhin die 5 hartcodierten Warmups
--   und ignoriert die DB. Das Seeding bleibt dann wirkungslos (aber harmlos).
--
-- REIHENFOLGE: erst scripts/create_test_student_session.sql, dann dieses.
-- ENTFERNEN:   siehe CLEANUP am Dateiende.
-- ============================================================================

do $$
declare
  v_class_level int  := 8;                  -- muss zur Klassenstufe des Test-Schülers passen
  v_source      text := 'seed-session-demo';
  v_cluster_id  uuid;
  v_cluster_nm  text;
  v_count       int;
begin
  ---------------------------------------------------------------------------
  -- 1) Ziel-Cluster wählen: erster Cluster (sort_order), der die Klassenstufe
  --    abdeckt und nicht deprecated ist.
  ---------------------------------------------------------------------------
  select sc.id, sc.name into v_cluster_id, v_cluster_nm
    from public.skill_clusters sc
   where sc.class_level_min <= v_class_level
     and sc.class_level_max >= v_class_level
     and not sc.is_deprecated
   order by sc.sort_order, sc.name
   limit 1;

  if v_cluster_id is null then
    raise exception
      'Kein skill_clusters-Eintrag deckt Klassenstufe % ab. Erst Cluster seeden '
      '(npm run seed:clusters).', v_class_level;
  end if;
  raise notice 'Ziel-Cluster: % (%)', v_cluster_nm, v_cluster_id;

  ---------------------------------------------------------------------------
  -- 2) Aufgaben upserten. `difficulty` steuert die Reihenfolge in der Queue
  --    (getTasksByClusterOrdered: content_type → difficulty → id).
  ---------------------------------------------------------------------------

  -- (1) MC, Single-Select
  insert into public.tasks (
    cluster_id, content_type, is_active, is_diagnostic, source, source_ref,
    class_level, difficulty, estimated_minutes, input_type, cognitive_type,
    question, solution, hint, question_payload
  ) values (
    v_cluster_id, 'exercise', true, false, v_source, 'demo-mc-1',
    v_class_level, 1, 3, 'MC', 'FACT',
    'Welche Steigung hat die Gerade $y = 2x + 3$?',
    'Die Steigung ist 2 (der Faktor vor x).',
    'Die Steigung steht als Faktor vor dem x.',
    jsonb_build_object(
      'input_type', 'MC',
      'options', jsonb_build_array(
        jsonb_build_object('id', 'a', 'label', '3'),
        jsonb_build_object('id', 'b', 'label', '2'),
        jsonb_build_object('id', 'c', 'label', '-2')
      ),
      'correct', jsonb_build_array('b')
    )
  )
  on conflict (source, source_ref) do update set
    cluster_id       = excluded.cluster_id,
    question         = excluded.question,
    solution         = excluded.solution,
    hint             = excluded.hint,
    input_type       = excluded.input_type,
    question_payload = excluded.question_payload,
    is_active        = true;

  -- (2) NUMERIC mit Toleranz
  insert into public.tasks (
    cluster_id, content_type, is_active, is_diagnostic, source, source_ref,
    class_level, difficulty, estimated_minutes, input_type, cognitive_type,
    question, solution, hint, question_payload
  ) values (
    v_cluster_id, 'exercise', true, false, v_source, 'demo-numeric-1',
    v_class_level, 2, 3, 'NUMERIC', 'TRANSFER',
    'Berechne den y-Achsenabschnitt von $y = 2x + 3$ an der Stelle $x = 2$.',
    'y = 2·2 + 3 = 7',
    'Setze x = 2 in die Gleichung ein.',
    jsonb_build_object(
      'input_type', 'NUMERIC',
      'accepted', jsonb_build_array(7),
      'tolerance', 0
    )
  )
  on conflict (source, source_ref) do update set
    cluster_id       = excluded.cluster_id,
    question         = excluded.question,
    solution         = excluded.solution,
    hint             = excluded.hint,
    input_type       = excluded.input_type,
    question_payload = excluded.question_payload,
    is_active        = true;

  -- (3) TRUE_FALSE
  insert into public.tasks (
    cluster_id, content_type, is_active, is_diagnostic, source, source_ref,
    class_level, difficulty, estimated_minutes, input_type, cognitive_type,
    question, solution, hint, question_payload
  ) values (
    v_cluster_id, 'exercise', true, false, v_source, 'demo-tf-1',
    v_class_level, 3, 2, 'TRUE_FALSE', 'FACT',
    'Die Gerade $y = -x + 1$ fällt.',
    'Wahr — die Steigung ist negativ (-1).',
    'Schau auf das Vorzeichen der Steigung.',
    jsonb_build_object('input_type', 'TRUE_FALSE', 'correct', true)
  )
  on conflict (source, source_ref) do update set
    cluster_id       = excluded.cluster_id,
    question         = excluded.question,
    solution         = excluded.solution,
    hint             = excluded.hint,
    input_type       = excluded.input_type,
    question_payload = excluded.question_payload,
    is_active        = true;

  -- (4) SHORT_TEXT, case-insensitive
  insert into public.tasks (
    cluster_id, content_type, is_active, is_diagnostic, source, source_ref,
    class_level, difficulty, estimated_minutes, input_type, cognitive_type,
    question, solution, hint, question_payload
  ) values (
    v_cluster_id, 'exercise', true, false, v_source, 'demo-shorttext-1',
    v_class_level, 4, 3, 'SHORT_TEXT', 'FACT',
    'Wie heißt der Faktor vor dem $x$ in einer linearen Funktion?',
    'Steigung',
    'Er beschreibt, wie stark die Gerade steigt oder fällt.',
    jsonb_build_object(
      'input_type', 'SHORT_TEXT',
      'accepted', jsonb_build_array('Steigung', 'Steigungsfaktor'),
      'caseInsensitive', true
    )
  )
  on conflict (source, source_ref) do update set
    cluster_id       = excluded.cluster_id,
    question         = excluded.question,
    solution         = excluded.solution,
    hint             = excluded.hint,
    input_type       = excluded.input_type,
    question_payload = excluded.question_payload,
    is_active        = true;

  -- (5) MC, Multiple-Select (correct.length > 1)
  insert into public.tasks (
    cluster_id, content_type, is_active, is_diagnostic, source, source_ref,
    class_level, difficulty, estimated_minutes, input_type, cognitive_type,
    question, solution, hint, question_payload
  ) values (
    v_cluster_id, 'exercise', true, false, v_source, 'demo-mc-2',
    v_class_level, 5, 4, 'MC', 'ANALYSIS',
    'Welche Geraden sind steigend? (Mehrfachauswahl)',
    'y = 3x und y = 0.5x + 4 — beide haben positive Steigung.',
    'Steigend bedeutet: Steigung größer als 0.',
    jsonb_build_object(
      'input_type', 'MC',
      'options', jsonb_build_array(
        jsonb_build_object('id', 'a', 'label', '$y = 3x$'),
        jsonb_build_object('id', 'b', 'label', '$y = -2x + 1$'),
        jsonb_build_object('id', 'c', 'label', '$y = 0{,}5x + 4$')
      ),
      'correct', jsonb_build_array('a', 'c')
    )
  )
  on conflict (source, source_ref) do update set
    cluster_id       = excluded.cluster_id,
    question         = excluded.question,
    solution         = excluded.solution,
    hint             = excluded.hint,
    input_type       = excluded.input_type,
    question_payload = excluded.question_payload,
    is_active        = true;

  select count(*) into v_count
    from public.tasks where source = v_source;

  raise notice '--------------------------------------------------------------';
  raise notice 'FERTIG. % Demo-Aufgabe(n) in Cluster "%".', v_count, v_cluster_nm;
  raise notice 'Die Session spielt max. SESSION_TASK_LIMIT (=5) offene Aufgaben aus.';
  raise notice 'Bereits geloeste Aufgaben fallen aus der Queue (student_task_progress).';
  raise notice '--------------------------------------------------------------';
end $$;

-- ============================================================================
-- VERIFIKATION — was die Session-Queue tatsächlich sehen wird
-- (Filter gespiegelt aus sessionQueue.ts: exercise + question + input_type +
--  question_payload, sortiert wie getTasksByClusterOrdered)
-- ============================================================================
select t.source_ref,
       t.input_type,
       t.difficulty,
       left(t.question, 44) as frage,
       (t.question_payload is not null) as hat_payload,
       sc.name                          as cluster
  from public.tasks t
  join public.skill_clusters sc on sc.id = t.cluster_id
 where t.source = 'seed-session-demo'
   and t.content_type = 'exercise'
   and t.question is not null
   and t.input_type is not null
   and t.question_payload is not null
   and coalesce(t.is_active, true)
 order by t.difficulty, t.id;

-- ============================================================================
-- CLEANUP — Demo-Aufgaben wieder entfernen
-- ----------------------------------------------------------------------------
--   delete from public.tasks where source = 'seed-session-demo';
--
-- student_task_progress.task_id ist `on delete cascade` (schema.sql), der
-- Fortschritt zu diesen Aufgaben verschwindet also mit. Bereits vergebene XP
-- bleiben dagegen in xp_events/student_progress bestehen (append-only,
-- CLAUDE.md §6) und werden NICHT zurueckgebucht — der XP-Stand des Testkontos
-- bleibt also erhoeht.
-- ============================================================================
