-- Reihe 1 · VERA8 entfernen (Entscheidung Rasit 2 vom 27.10.2026, Anweisung vom 28.10.2026). Fuer genau diesen
-- Schritt ist die Leitplanke „keine loeschenden Anweisungen“ aufgehoben.
--
-- VERA8 = tasks.source = 'VERA8_IQB' (299 Aufgaben in Prod, 243 Loesungszeilen). Die 66 LSA-Antworten darauf stammen
-- aus 9 LSA-Sitzungen vom Juli 2026 und sind Testdaten mit Phantasiedaten (Rasit); sie werden mitgeloescht.
-- Sicherung ausserhalb des Repos: ~/backups/vera8-2026-10-28.sql (tasks, task_solutions, lsa_responses als COPY),
-- Figuren ~/backups/vera8-figuren/ (urheberrechtlich geschuetzt, nie ins Repo).
--
-- Reihenfolge der Abhaengigkeiten: lsa_responses → task_solutions → tasks. Alle uebrigen Tabellen mit FK auf tasks
-- haben 0 Zeilen auf VERA8 (Scan 28.10.2026); der Waechter bricht ab, wenn sich das geaendert hat — dann STOPP.
-- Nicht geloescht: die 10 LSA-Sitzungen (alle completed/aborted), deren item_ids nur VERA8-Aufgaben nennen; die IDs
-- bleiben als Verweis ohne Ziel stehen (uuid[] ohne FK).
--
-- Neuaufbau (CI): die Prefill-Migrationen legen VERA8 an, diese Migration entfernt es wieder; ohne LSA-Antworten.
--
-- Pruefabfrage: select count(*) from tasks where source = 'VERA8_IQB';   vorher 299   nachher 0
do $$
declare
  v_ids uuid[] := array(select id from public.tasks where source = 'VERA8_IQB');
  v_sitzungen uuid[] := array['e78bd3a0-3edf-4318-9fae-711459296f18', 'bdc38e6b-3966-49a2-b5d9-5e1e1a6392d2',
    '74a1d807-22dd-4ba3-92c5-d193b105ed2f', 'a8ff43dc-6d2d-4306-901e-f03dc81d59f3', '142bcebb-76d9-427b-8c71-e4df2089d8fe',
    'f0a0ac0f-c5ba-4505-80e0-5c2c94e1556d', 'da10ca1b-15dd-4484-95b5-a815dffd9a8f', '73217031-0fa2-44cd-b2d4-d0c33a21dd52',
    '2b796028-b35c-4fe1-8bb3-14606e992050']::uuid[];
  r record;
  n bigint;
begin
  -- Waechter: ausser task_solutions und den Antworten der neun Testsitzungen darf nichts auf VERA8 zeigen.
  if exists (select 1 from public.lsa_responses where task_id = any (v_ids) and session_id <> all (v_sitzungen)) then
    raise exception 'VERA8 entfernen: LSA-Antworten ausserhalb der neun Testsitzungen verweisen auf VERA8 — STOPP';
  end if;
  for r in select c.conrelid::regclass as tab, a.attname as spalte
             from pg_constraint c join pg_attribute a on a.attrelid = c.conrelid and a.attnum = c.conkey[1]
            where c.contype = 'f' and c.confrelid = 'public.tasks'::regclass
              and c.conrelid not in ('public.task_solutions'::regclass, 'public.lsa_responses'::regclass) loop
    execute format('select count(*) from %s where %I = any ($1)', r.tab, r.spalte) into n using v_ids;
    if n > 0 then
      raise exception 'VERA8 entfernen: % Zeilen in % verweisen auf VERA8 — STOPP', n, r.tab;
    end if;
  end loop;

  delete from public.lsa_responses where task_id = any (v_ids) and session_id = any (v_sitzungen);
  delete from public.task_solutions where task_id = any (v_ids);
  delete from public.tasks where id = any (v_ids);
end $$;
