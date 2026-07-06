-- ============================================================================
-- Edvance · Test-Schülerprofil anlegen (Supabase SQL Editor)
-- ----------------------------------------------------------------------------
-- ZWECK: Hängt an einen BEREITS existierenden auth-User ein profiles-Row
--        (role='student') + einen students-Row. Idempotent (mehrfach lauffähig).
--
-- VORAUSSETZUNG: Der auth-User muss existieren (profiles.id → auth.users.id).
--   Falls noch nicht vorhanden: Supabase Dashboard > Authentication > Users >
--   "Add user" (E-Mail + Passwort, "Auto Confirm User" an), DANN dieses Skript.
--   Direktes INSERT in auth.users wird bewusst vermieden (kaputter Login).
--
-- ANPASSEN: die fünf v_*-Werte unten (E-Mail, Name, Klassenstufe, Schultyp).
-- ============================================================================

do $$
declare
  v_email       text := 'Student@edvance.de';     -- Test-User E-Mail
  v_full_name   text := 'Test Schüler';
  v_class_level int  := 8;                          -- 5..13 (8–10 = geseedete Cluster)
  v_school_type text := 'Gymnasium';                -- Gymnasium|Gesamtschule|Realschule|Hauptschule
  v_school_name text := 'Testschule';
  v_uid         uuid;
  v_student_id  uuid;
begin
  -- 1) Auth-User finden (case-insensitive – Supabase speichert E-Mails klein)
  select id into v_uid
    from auth.users
   where lower(email) = lower(v_email)
   limit 1;

  if v_uid is null then
    raise exception
      'Kein auth.users-Eintrag für "%" gefunden. Bitte den User zuerst unter '
      'Authentication > Users anlegen (Auto Confirm), dann erneut ausführen.',
      v_email;
  end if;

  -- 2) profiles upsert (role=student); deckt einen evtl. handle_new_user-Trigger mit ab
  insert into public.profiles (id, email, role, full_name)
  values (v_uid, v_email, 'student', v_full_name)
  on conflict (id) do update
    set role      = 'student',
        email     = excluded.email,
        full_name = coalesce(public.profiles.full_name, excluded.full_name);

  -- 3) students-Row anlegen, falls noch keiner an diesem Profil hängt
  select id into v_student_id
    from public.students
   where profile_id = v_uid
   limit 1;

  if v_student_id is null then
    insert into public.students (profile_id, class_level, school_type, school_name)
    values (v_uid, v_class_level, v_school_type, v_school_name)
    returning id into v_student_id;
    raise notice 'students-Row angelegt: student_id=% (profile_id=%)', v_student_id, v_uid;
  else
    update public.students
       set class_level = v_class_level,
           school_type = v_school_type,
           school_name = v_school_name
     where id = v_student_id;
    raise notice 'students-Row existierte bereits, aktualisiert: student_id=% (profile_id=%)', v_student_id, v_uid;
  end if;

  raise notice 'Fertig. Schülerprofil für % → auth/profile_id=%, student_id=%', v_email, v_uid, v_student_id;
end $$;

-- ============================================================================
-- VERIFIKATION
-- ============================================================================
select p.id   as profile_id,
       p.email,
       p.role,
       p.full_name,
       s.id   as student_id,
       s.class_level,
       s.school_type,
       s.school_name
  from public.profiles p
  left join public.students s on s.profile_id = p.id
 where lower(p.email) = lower('Student@edvance.de');
