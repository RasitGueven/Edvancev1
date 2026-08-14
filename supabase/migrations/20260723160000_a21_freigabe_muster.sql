-- A21 — Freigabe je Skill (Ergaenzung zu A20).
--
-- A20 gab die Sammel-BEANSTANDUNG (lena_beanstande_muster): ein Befund gilt fuer
-- alle Aufgaben eines Skills mit einem Fehlbild. A21 ist das Gegenstueck, die
-- Sammel-FREIGABE. Aufgaben einer Skill-Gruppe stammen aus demselben
-- didaktischen Muster — wer eins gruendlich prueft und den Rest ueberfliegt, gibt
-- die Gruppe frei, nicht 28 Aufgaben einzeln.
--
-- Version 20260723160000. Nach supabase/pending/ — Rasit spielt selbst ein.
-- Diese Migration mutiert bei Anwendung KEINE Aufgabendaten (bewusst anders als
-- A20, dort stand der Test inline). Die PRUEFUNG steht in der Schwesterdatei
-- 20260723160000_a21_freigabe_muster.PRUEFUNG.sql und laeuft in begin/rollback.


-- ── freigabe_muster: draft -> ready fuer eine Skill-Gruppe ───────────────────
--
-- Ohne p_task_ids: alle 'draft'-Aufgaben des Skills. Mit p_task_ids: nur diese
-- (fuer "alle ausser diesen dreien"). 'beanstandet' und 'review' werden NIE
-- mitgehoben — ein Befund ueberlebt jede Sammelfreigabe, und 'review' hat einen
-- eigenen Weg.
--
-- DAS GATE BLEIBT: Eine Freigabe auf 'ready' laeuft ueber task_status_set (A01),
-- das die Pflichtfelder (Stamm, input_type, AFB, Cluster, Stoffanker,
-- vollstaendige Loesung) prueft und reviewed_by/reviewed_at stempelt. Ein direktes
-- `update ... set status='ready'` wuerde dieses Gate umgehen und ein strukturell
-- unvollstaendiges Item in den LSA-Pool schieben. Die Sammelfreigabe hebt
-- Vollstaendigkeit nicht auf: faellt ein Item durchs Gate (SQLSTATE P0001), wird
-- es uebersprungen statt die ganze Gruppe scheitern zu lassen. Rueckgabe ist die
-- Anzahl TATSAECHLICH freigegebener Aufgaben.

create or replace function public.freigabe_muster(
  p_skill_key text,
  p_task_ids  uuid[] default null
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_n  integer := 0;
begin
  -- `is distinct from` statt `<>`: get_my_role() ist NULL fuer einen nicht
  -- angemeldeten Aufrufer, und `NULL <> 'admin'` waere NULL — die Pruefung
  -- feuerte dann nicht. `is distinct from` liefert bei NULL true.
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'A21: nur die fachliche Freigabe (admin) darf freigeben'
      using errcode = '42501';
  end if;

  for v_id in
    select id from public.tasks
     where skill_key = p_skill_key
       and status = 'draft'
       and (p_task_ids is null or id = any (p_task_ids))
  loop
    begin
      perform public.task_status_set(v_id, 'ready');
      v_n := v_n + 1;
    exception
      -- P0001 = Pflichtfeld oder Loesung unvollstaendig (task_status_set-Gate).
      -- Das Item bleibt 'draft', die Gruppe laeuft weiter.
      when sqlstate 'P0001' then null;
    end;
  end loop;

  return v_n;
end $$;


-- ── freigabe_zuruecknehmen: ready -> draft fuer eine Skill-Gruppe ────────────
--
-- Das Gegenstueck. Nur die 'ready'-Aufgaben der Gruppe fallen auf 'draft'
-- zurueck; 'beanstandet', 'review' und 'draft' bleiben unberuehrt. Der
-- Freigabe-Stempel wird geloescht (wie task_status_set ihn bei Nicht-ready leert),
-- damit kein Item als "freigegeben von X" gilt, das es nicht mehr ist.

create or replace function public.freigabe_zuruecknehmen(
  p_skill_key text
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_n integer;
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'A21: nur die fachliche Freigabe (admin) darf Freigaben zuruecknehmen'
      using errcode = '42501';
  end if;

  update public.tasks
     set status      = 'draft',
         reviewed_by = null,
         reviewed_at = null
   where skill_key = p_skill_key
     and status    = 'ready';

  get diagnostics v_n = row_count;
  return v_n;
end $$;


-- ── Grants ──────────────────────────────────────────────────────────────────
-- Postgres grantet neuen Funktionen automatisch an PUBLIC. Erst wegnehmen, dann
-- gezielt geben (wie task_status_set, A01 §4): sonst koennte ein anon-Aufruf die
-- Funktion ueberhaupt betreten. Zwei Schloesser — der Grant und der
-- Rollen-Check — statt einem.

revoke execute on function public.freigabe_muster(text, uuid[]) from public;
revoke execute on function public.freigabe_zuruecknehmen(text)  from public;

grant execute on function public.freigabe_muster(text, uuid[]) to authenticated, service_role;
grant execute on function public.freigabe_zuruecknehmen(text)  to authenticated, service_role;

comment on function public.freigabe_muster(text, uuid[]) is
  'A21 Sammelfreigabe: draft->ready fuer eine Skill-Gruppe ueber das '
  'task_status_set-Gate (Pflichtfelder + reviewed_by-Stempel). beanstandet/review '
  'bleiben. Rueckgabe: Anzahl tatsaechlich freigegebener Aufgaben.';
comment on function public.freigabe_zuruecknehmen(text) is
  'A21 Gegenstueck: ready->draft fuer eine Skill-Gruppe, ohne beanstandet/review '
  'anzufassen. Rueckgabe: Anzahl zurueckgenommener Aufgaben.';
