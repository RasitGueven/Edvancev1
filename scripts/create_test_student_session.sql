-- ============================================================================
-- Edvance · Test-Schüler:in anlegen UND ihm/ihr eine Präsenz-Session zuweisen
-- ----------------------------------------------------------------------------
-- ZWECK: Erweitert scripts/create_test_student.sql um genau das, was die
--        Session-Route /student/session/:id zusätzlich braucht:
--          · student_subjects  → sonst liefert getClustersForStudent() [] und
--            die Aufgaben-Queue bleibt LEER (src/lib/supabase/tasks.ts:81-88)
--          · coaching_sessions → braucht einen coach_id (NOT NULL)
--          · session_students  → die eigentliche Zuweisung
--
-- VORAUSSETZUNG (unverändert, siehe create_test_student.sql):
--   Der auth-User muss existieren. Supabase Dashboard > Authentication >
--   Users > "Add user" (E-Mail + Passwort, "Auto Confirm User" AN), DANN
--   dieses Skript im SQL Editor ausführen.
--   Direktes INSERT in auth.users wird bewusst vermieden (kaputter Login).
--
-- VORAUSSETZUNG 2: Es muss mindestens ein Profil mit role='coach' existieren.
--   Ohne Coach kann keine coaching_sessions-Zeile angelegt werden
--   (coach_id ist NOT NULL). Das Skript bricht sonst mit klarer Meldung ab.
--
-- IDEMPOTENT: mehrfach ausführbar. Legt pro Lauf KEINE zweite Session an,
--   solange eine zukünftige Session für diese:n Schüler:in existiert.
--
-- ANPASSEN: die v_*-Werte im Kopf des Blocks.
-- ============================================================================

do $$
declare
  v_email        text := 'Student@edvance.de';   -- MUSS als auth-User existieren
  v_full_name    text := 'Test Schüler';
  v_class_level  int  := 8;                       -- 8..10 = geseedete Cluster
  v_school_type  text := 'Gymnasium';             -- Gymnasium|Gesamtschule|Realschule|Hauptschule
  v_school_name  text := 'Testschule';
  v_session_at   timestamptz := now() + interval '1 hour';  -- MUSS in der Zukunft liegen
  v_room         text := 'Raum 1';

  v_uid          uuid;
  v_student_id   uuid;
  v_coach_id     uuid;
  v_session_id   uuid;
  v_subj_count   int;
  v_playable     int;
begin
  ---------------------------------------------------------------------------
  -- 1) Auth-User finden (Supabase speichert E-Mails klein)
  ---------------------------------------------------------------------------
  select id into v_uid
    from auth.users
   where lower(email) = lower(v_email)
   limit 1;

  if v_uid is null then
    raise exception
      'Kein auth.users-Eintrag für "%". Bitte den User zuerst unter '
      'Authentication > Users anlegen (Auto Confirm), dann erneut ausführen.',
      v_email;
  end if;

  ---------------------------------------------------------------------------
  -- 2) profiles (role=student) + students
  ---------------------------------------------------------------------------
  insert into public.profiles (id, email, role, full_name)
  values (v_uid, v_email, 'student', v_full_name)
  on conflict (id) do update
    set role      = 'student',
        email     = excluded.email,
        full_name = coalesce(public.profiles.full_name, excluded.full_name);

  select id into v_student_id
    from public.students
   where profile_id = v_uid
   limit 1;

  if v_student_id is null then
    insert into public.students (profile_id, class_level, school_type, school_name)
    values (v_uid, v_class_level, v_school_type, v_school_name)
    returning id into v_student_id;
    raise notice 'students-Row angelegt: student_id=%', v_student_id;
  else
    update public.students
       set class_level = v_class_level,
           school_type = v_school_type,
           school_name = v_school_name
     where id = v_student_id;
    raise notice 'students-Row aktualisiert: student_id=%', v_student_id;
  end if;

  ---------------------------------------------------------------------------
  -- 3) student_subjects — OHNE das bleibt die Session-Queue leer.
  --    Es werden nur Fächer verknüpft, die für diese Klassenstufe tatsächlich
  --    Cluster haben; sonst lädt die Session zwar, zeigt aber 0 Aufgaben.
  ---------------------------------------------------------------------------
  insert into public.student_subjects (student_id, subject_id)
  select distinct v_student_id, sc.subject_id
    from public.skill_clusters sc
   where sc.class_level_min <= v_class_level
     and sc.class_level_max >= v_class_level
  on conflict do nothing;

  select count(*) into v_subj_count
    from public.student_subjects where student_id = v_student_id;

  if v_subj_count = 0 then
    raise exception
      'Keine Fächer verknüpft: es gibt keine skill_clusters, die Klassenstufe % '
      'abdecken. Erst Cluster seeden (npm run seed:clusters).', v_class_level;
  end if;
  raise notice 'student_subjects: % Fach/Fächer verknüpft', v_subj_count;

  ---------------------------------------------------------------------------
  -- 4) Coach bestimmen (irgendein vorhandener Coach; coach_id ist NOT NULL)
  ---------------------------------------------------------------------------
  select id into v_coach_id
    from public.profiles
   where role = 'coach'
   order by created_at
   limit 1;

  if v_coach_id is null then
    raise exception
      'Kein Profil mit role=''coach'' vorhanden. coaching_sessions.coach_id ist '
      'NOT NULL — bitte zuerst einen Coach anlegen (Admin > Coaches, oder '
      'einen auth-User anlegen und dessen profiles.role auf ''coach'' setzen).';
  end if;

  -- Coach dem Schüler zuordnen (nicht zwingend für die Session, aber konsistent)
  insert into public.student_coach (student_id, coach_id, active)
  values (v_student_id, v_coach_id, true)
  on conflict (student_id, coach_id) do update set active = true;

  ---------------------------------------------------------------------------
  -- 5) Session anlegen + zuweisen.
  --    WICHTIG: scheduled_at MUSS in der Zukunft liegen. Die Route löst die
  --    Session über listUpcomingSessionsForStudent() auf, die nach
  --    `scheduled_at >= now()` filtert (src/lib/supabase/sessions.ts:104).
  --    Eine Session in der Vergangenheit → Seite zeigt "nicht gefunden".
  ---------------------------------------------------------------------------
  select cs.id into v_session_id
    from public.coaching_sessions cs
    join public.session_students ss on ss.session_id = cs.id
   where ss.student_id = v_student_id
     and cs.scheduled_at >= now()
   order by cs.scheduled_at
   limit 1;

  if v_session_id is null then
    insert into public.coaching_sessions (coach_id, room, scheduled_at, status)
    values (v_coach_id, v_room, v_session_at, 'upcoming')
    returning id into v_session_id;

    insert into public.session_students (session_id, student_id, attendance)
    values (v_session_id, v_student_id, 'unknown')
    on conflict do nothing;

    raise notice 'Session angelegt: session_id=% um %', v_session_id, v_session_at;
  else
    raise notice 'Zukünftige Session existiert bereits: session_id=%', v_session_id;
  end if;

  ---------------------------------------------------------------------------
  -- 6) Wird die Session überhaupt Aufgaben zeigen?
  --    Spielbar ist nur: content_type='exercise' + question + input_type +
  --    passendes question_payload (src/pages/student/session/sessionQueue.ts:24-30).
  ---------------------------------------------------------------------------
  select count(*) into v_playable
    from public.tasks t
    join public.skill_clusters sc on sc.id = t.cluster_id
    join public.student_subjects ssub
      on ssub.subject_id = sc.subject_id and ssub.student_id = v_student_id
   where t.content_type = 'exercise'
     and t.question is not null
     and t.input_type is not null
     and t.question_payload is not null
     and coalesce(t.is_active, true)
     and sc.class_level_min <= v_class_level
     and sc.class_level_max >= v_class_level;

  if v_playable = 0 then
    raise warning
      'Session ist zugewiesen, aber es gibt 0 spielbare Aufgaben (exercise + '
      'question + input_type + question_payload). Die Session lädt, zeigt aber '
      'keine Aufgabe. Ursache: question_payload-Lücke im Bestand.';
  else
    raise notice '% spielbare Aufgabe(n) verfügbar', v_playable;
  end if;

  raise notice '--------------------------------------------------------------';
  raise notice 'FERTIG. Login: %  ·  student_id=%', v_email, v_student_id;
  raise notice 'Route:  /student/session/%', v_session_id;
  raise notice '--------------------------------------------------------------';
end $$;

-- ============================================================================
-- VERIFIKATION
-- ============================================================================
select p.email,
       p.role,
       s.id            as student_id,
       s.class_level,
       cs.id           as session_id,
       cs.scheduled_at,
       cs.status,
       ss.attendance,
       cs.scheduled_at >= now() as sichtbar_fuer_student
  from public.profiles p
  join public.students s          on s.profile_id = p.id
  left join public.session_students ss on ss.student_id = s.id
  left join public.coaching_sessions cs on cs.id = ss.session_id
 where lower(p.email) = lower('Student@edvance.de')
 order by cs.scheduled_at desc nulls last;
