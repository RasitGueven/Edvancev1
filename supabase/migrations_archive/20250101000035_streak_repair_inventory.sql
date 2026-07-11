-- 035_streak_repair_inventory.sql
-- Inventory für Streak-Repair-Token (Lila Power-Up, kein Status-Badge).

create table if not exists public.streak_repair_inventory (
  student_id   uuid primary key references public.students(id) on delete cascade,
  tokens       int not null default 0,
  earned_total int not null default 0,
  used_total   int not null default 0,
  updated_at   timestamptz not null default now()
);

alter table public.streak_repair_inventory enable row level security;

drop policy if exists "streak_repair_self_read"   on public.streak_repair_inventory;
drop policy if exists "streak_repair_admin_write" on public.streak_repair_inventory;

create policy "streak_repair_self_read"
  on public.streak_repair_inventory for select
  using (
    student_id in (select id from public.students where profile_id = auth.uid())
    or public.get_my_role() in ('coach','admin')
  );

create policy "streak_repair_admin_write"
  on public.streak_repair_inventory for all
  using (public.get_my_role() in ('admin'))
  with check (public.get_my_role() in ('admin'));
