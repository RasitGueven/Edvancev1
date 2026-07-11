-- 036_drop_streak_days.sql
-- Final-Cleanup: streak_days wird durch das Zwei-Streak-Modell ersetzt
-- (presence_streak_weeks + home_streak_sessions, eingeführt in 032).
-- Frontend nutzt seit Phase 5/7 nicht mehr streak_days.

alter table public.student_progress
  drop column if exists streak_days;

-- Falls auch ein streak_last_at-Feld bestand:
alter table public.student_progress
  drop column if exists streak_last_at;
