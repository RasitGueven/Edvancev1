-- ============================================================================
-- Migration 024 – coaching_sessions: Eltern-Read-Policy
--
-- ⚠️  Auth/RLS-AENDERUNG – per CLAUDE.md §4/§7 mit Rasit explizit abstimmen
-- vor Ausfuehrung im Supabase SQL Editor.
--
-- Luecke aus Migration 017: Schueler duerfen coaching_sessions lesen
-- (coaching_sessions_student_read via get_my_student_id()), Eltern jedoch
-- nur session_students (session_students_parent_read), NICHT coaching_sessions.
-- get_my_student_id() liefert fuer Eltern-Profile null -> ein Join aus
-- Eltern-Kontext bringt die Verknuepfung, aber nicht scheduled_at/room/status.
--
-- Diese Policy schliesst die Luecke spiegelbildlich zur Schueler-Policy und
-- nutzt den vorhandenen Security-Definer-Helper is_parent_of_student
-- (migrations/011), der anhand der students-PK korrekt prueft.
-- Nur SELECT; kein Schreibzugriff fuer Eltern.
-- ============================================================================

create policy "coaching_sessions_parent_read" on coaching_sessions
  for select using (
    id in (
      select ss.session_id
      from session_students ss
      where public.is_parent_of_student(ss.student_id)
    )
  );
