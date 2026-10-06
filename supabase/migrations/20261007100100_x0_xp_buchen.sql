-- X0.1 XP nur noch ueber eine Funktion (Entscheidung 24, Q0 Frage 5).
--
-- Bisher durfte jedes Schuelerkonto per Policy xp_events_insert_own beliebige
-- XP-Betraege fuer sich eintragen (awardXp in src/lib/supabase/progress.ts).
-- Ab hier:
--   - authenticated/anon haben kein INSERT/UPDATE/DELETE mehr auf xp_events
--     und student_progress (die XP-Tabellen; student_progress schreibt nur der
--     Trigger apply_xp_event),
--   - gebucht wird ueber xp_buchen (Admin oder Systemaufruf), idempotent ueber
--     einen Buchungsschluessel: derselbe Schluessel bucht genau einmal,
--   - Badges schreibt nur noch der Admin (Entscheidung 26: Coaches schreiben
--     XP und Badges nicht direkt).

alter table public.xp_events add column if not exists buchungs_schluessel text;
create unique index if not exists xp_events_buchungs_schluessel_key
  on public.xp_events (student_id, buchungs_schluessel);
comment on column public.xp_events.buchungs_schluessel is
  'Idempotenz-Schluessel von xp_buchen (z. B. quest:<id>). Je Kind bucht derselbe Schluessel genau einmal.';

drop policy if exists xp_events_insert_own on public.xp_events;
revoke insert, update, delete on public.xp_events from anon, authenticated;
revoke insert, update, delete on public.student_progress from anon, authenticated;

drop policy if exists student_badges_admin_write on public.student_badges;
create policy student_badges_admin_write on public.student_badges
  for all using (coalesce(public.get_my_role(), '') = 'admin')
  with check (coalesce(public.get_my_role(), '') = 'admin');

-- Kern ohne Rechtepruefung — nur fuer andere Server-Funktionen.
create function public.xp_buchen_intern(
  p_student_id  uuid,
  p_xp          integer,
  p_grund       text,
  p_schluessel  text,
  p_task_id     uuid default null
)
returns boolean
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_n integer;
begin
  if p_student_id is null or p_xp is null or p_xp < 1 or p_xp > 1000 then
    raise exception 'xp_buchen: Kind und Betrag 1..1000 sind Pflicht' using errcode = '22023';
  end if;
  if nullif(btrim(coalesce(p_grund, '')), '') is null
     or nullif(btrim(coalesce(p_schluessel, '')), '') is null then
    raise exception 'xp_buchen: Grund und Buchungsschluessel sind Pflicht' using errcode = '22023';
  end if;
  if not exists (select 1 from public.students where id = p_student_id) then
    raise exception 'xp_buchen: Kind nicht gefunden' using errcode = 'P0002';
  end if;

  insert into public.xp_events (student_id, task_id, xp, reason, buchungs_schluessel)
  values (p_student_id, p_task_id, p_xp, p_grund, p_schluessel)
  on conflict (student_id, buchungs_schluessel) do nothing;
  get diagnostics v_n = row_count;
  return v_n = 1;
end;
$$;

revoke all on function public.xp_buchen_intern(uuid, integer, text, text, uuid)
  from public, anon, authenticated;

comment on function public.xp_buchen_intern(uuid, integer, text, text, uuid) is
  'XP-Buchung ohne Rechtepruefung, nur fuer Server-Funktionen. true = gebucht, false = Schluessel schon gebucht.';

create function public.xp_buchen(
  p_student_id  uuid,
  p_xp          integer,
  p_grund       text,
  p_schluessel  text,
  p_task_id     uuid default null
)
returns boolean
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
begin
  if not (public.ist_systemaufruf() or coalesce(public.get_my_role(), '') = 'admin') then
    raise exception 'xp_buchen: nur Admin oder Systemaufruf' using errcode = '42501';
  end if;
  return public.xp_buchen_intern(p_student_id, p_xp, p_grund, p_schluessel, p_task_id);
end;
$$;

revoke all on function public.xp_buchen(uuid, integer, text, text, uuid) from public, anon, authenticated;
grant execute on function public.xp_buchen(uuid, integer, text, text, uuid) to authenticated;

comment on function public.xp_buchen(uuid, integer, text, text, uuid) is
  'Bucht XP genau einmal je Kind und Buchungsschluessel. Nur Admin oder Systemaufruf (X0, Entscheidung 24).';

-- complete_task (stillgelegt, siehe 20261007100000) bucht ueber denselben Kern.
create or replace function public.complete_task(p_task_id uuid)
returns table(newly_completed boolean, awarded_xp integer)
language plpgsql
security definer
set search_path = public, pg_temp
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
    perform public.xp_buchen_intern(v_student, least(v_xp, 1000), 'Aufgabe abgeschlossen',
                                    'task:' || v_student || ':' || p_task_id, p_task_id);
  end if;

  return query select true, v_xp;
end;
$$;

revoke all on function public.complete_task(uuid) from public, anon, authenticated;
