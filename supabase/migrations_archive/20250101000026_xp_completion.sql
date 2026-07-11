-- ============================================================================
-- Migration 026 – xp_rules + complete_task RPC
-- ----------------------------------------------------------------------------
-- Schliesst die XP-/Task-Abschluss-Luecke: TaskPlayer persistierte bisher nichts.
--   * xp_rules: admin-konfigurierbare XP-Gewichtung pro content_type
--   * complete_task(uuid): atomare, idempotente Abschluss-RPC (SECURITY DEFINER)
--     - upsert student_task_progress (nur Erst-Abschluss zaehlt)
--     - bei Erst-Abschluss: insert xp_events -> Trigger apply_xp_event rechnet
--       student_progress (xp_total/level/streak) server-seitig fort
-- Cheat-sicher: Client kann den XP-Betrag nicht setzen (Server leitet ihn aus
-- xp_rules + tasks ab). Idempotent: XP nur, wenn die Progress-Zeile NEU war.
-- ============================================================================

create table xp_rules (
  content_type text primary key,
  base_xp integer not null default 0,
  difficulty_multiplier integer not null default 0,
  updated_at timestamptz not null default now()
);
alter table xp_rules enable row level security;
create policy "xp_rules_admin_all" on xp_rules
  for all
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');
create policy "xp_rules_staff_read" on xp_rules
  for select using (public.get_my_role() in ('coach', 'admin'));

insert into xp_rules (content_type, base_xp, difficulty_multiplier) values
  ('exercise', 20, 5),
  ('video', 10, 0),
  ('article', 10, 0),
  ('exercise_group', 0, 0),
  ('course', 0, 0);

create or replace function public.complete_task(p_task_id uuid)
returns table (newly_completed boolean, awarded_xp integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_student uuid;
  v_ins integer;
  v_xp integer;
begin
  v_student := public.get_my_student_id();
  if v_student is null then
    return;
  end if;

  insert into student_task_progress (student_id, task_id)
  values (v_student, p_task_id)
  on conflict (student_id, task_id) do nothing;
  get diagnostics v_ins = row_count;

  if v_ins = 0 then
    return query select false, 0;
    return;
  end if;

  select r.base_xp + r.difficulty_multiplier * coalesce(t.difficulty, 0)
    into v_xp
    from tasks t
    join xp_rules r on r.content_type = t.content_type
   where t.id = p_task_id;

  v_xp := coalesce(v_xp, 0);

  if v_xp > 0 then
    insert into xp_events (student_id, task_id, xp, reason)
    values (v_student, p_task_id, v_xp, 'Aufgabe abgeschlossen');
  end if;

  return query select true, v_xp;
end;
$$;

grant execute on function public.complete_task(uuid) to authenticated;
