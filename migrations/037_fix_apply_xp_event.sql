-- ============================================================================
-- Migration 037 – fix apply_xp_event (D-01): streak_days-Bezug entfernen
--
-- ⚠️  Auth/RLS-AENDERUNG – per CLAUDE.md mit Rasit explizit abstimmen
-- vor Ausfuehrung im Supabase SQL Editor.
--
-- Manueller Schritt: Im Supabase SQL Editor ausfuehren.
--
-- Bug D-01: apply_xp_event (Migration 019) liest/schreibt
-- student_progress.streak_days. Migration 036 hat diese Spalte gedroppt;
-- keine spaetere Migration hat die Funktion neu definiert -> jeder INSERT in
-- xp_events (und damit die RPC complete_task) schlaegt im Endzustand fehl
-- (column "streak_days" does not exist). Siehe docs/DRIFT_REPORT.md (D-01).
--
-- Diese Migration schreibt apply_xp_event 1:1 wie 019 neu, NUR ohne jede
-- streak_days-/Datums-Streak-Logik. Das Zwei-Streak-Modell (presence/home aus
-- Migration 032) wird hier bewusst NICHT gepflegt – nur D-01 wird entschaerft.
-- Trigger xp_events_apply bleibt unveraendert (create or replace genuegt).
-- ============================================================================

create or replace function public.apply_xp_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform 1 from student_progress where student_id = new.student_id;

  if not found then
    insert into student_progress
      (student_id, xp_total, level, last_activity)
    values
      (new.student_id, new.xp, 1 + (new.xp / 500), now());
    return new;
  end if;

  update student_progress
     set xp_total = xp_total + new.xp,
         level = 1 + ((xp_total + new.xp) / 500),
         last_activity = now()
   where student_id = new.student_id;

  return new;
end;
$$;
