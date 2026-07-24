-- PRUEFUNG zu A21 — laeuft in begin/rollback, mutiert NICHTS dauerhaft.
--
--   psql "$DATABASE_URL" -P pager=off -v ON_ERROR_STOP=1 \
--        -f supabase/pending/20260723160000_a21_freigabe_muster.PRUEFUNG.sql
--
-- Bindet die Migration im selben Transaktionsblock ein (\ir), prueft gegen echte
-- Daten und rollt am Ende alles zurueck. Die Probe-Gruppe wird transaktionslokal
-- aus vorhandenen, vollstaendigen 'ready'-Aufgaben gebaut (sie bestehen das
-- task_status_set-Gate garantiert), auf einen synthetischen Skill 'A21_PROBE'
-- umgehaengt und in die Zustaende draft/beanstandet/review gesetzt.

begin;

\ir 20260723160000_a21_freigabe_muster.sql

do $$
declare
  v_admin uuid;
  v_ids   uuid[];
  v_ist   integer;
  v_ctrl  boolean;
begin
  select id into v_admin from public.profiles where role = 'admin' limit 1;
  if v_admin is null then raise exception 'kein admin-Profil gefunden'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub', v_admin)::text, true);

  -- 6 vollstaendige ready-Aufgaben als Probe-Gruppe (alle Gate-Felder + Loesung).
  select array_agg(id) into v_ids from (
    select t.id from public.tasks t
     where t.status = 'ready'
       and coalesce(btrim(t.question), '') <> '' and t.input_type is not null
       and t.afb is not null and t.cluster_id is not null
       and exists (select 1 from public.task_solutions s where s.task_id = t.id
                   and public.lsa_has_answers(t.input_type, t.parts, s.correct_answers))
     order by t.id
     limit 6) x;
  if coalesce(array_length(v_ids, 1), 0) < 6 then
    raise exception 'zu wenige vollstaendige ready-Aufgaben fuer die Probe (%).',
      coalesce(array_length(v_ids, 1), 0);
  end if;

  -- Probe-Skill anlegen (tasks.skill_key hat einen FK auf skills) — rollback raeumt ihn weg.
  insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
    values ('A21_PROBE', 'A21 Probe', 'mathematik', 8, 1);

  -- Umhaengen: gemeinsamer Skill, Stoffanker sicherstellen (Gate braucht ihn).
  update public.tasks
     set skill_key = 'A21_PROBE', curriculum_grade = coalesce(curriculum_grade, 8)
   where id = any (v_ids);

  -- v_ids[1..4] draft (freizugeben), [5] beanstandet, [6] review.
  update public.tasks set status = 'draft', reviewed_by = null, reviewed_at = null
   where id = any (v_ids[1:4]);
  update public.tasks set status = 'beanstandet' where id = v_ids[5];
  update public.tasks set status = 'review'      where id = v_ids[6];

  -- ── 1+3. Sammelfreigabe hebt nur draft; Rueckgabe == Anzahl ────────────────
  v_ist := public.freigabe_muster('A21_PROBE');
  if v_ist <> 4 then raise exception 'P1/P3 Rueckgabe %, erwartet 4', v_ist; end if;
  if (select count(*) from public.tasks where id = any (v_ids[1:4]) and status = 'ready') <> 4 then
    raise exception 'P1 nicht alle vier draft wurden ready';
  end if;
  if (select status from public.tasks where id = v_ids[5]) <> 'beanstandet' then
    raise exception 'P1 beanstandet wurde mitgehoben';
  end if;
  if (select status from public.tasks where id = v_ids[6]) <> 'review' then
    raise exception 'P1 review wurde mitgehoben';
  end if;
  if (select count(*) from public.tasks where id = any (v_ids[1:4]) and reviewed_by is null) <> 0 then
    raise exception 'P1 reviewed_by nicht gestempelt';
  end if;
  raise notice 'P1+P3 ok: nur draft gehoben (4), beanstandet/review bleiben, Rueckgabe=Anzahl, reviewed_by gestempelt';

  -- ── 2. Mit p_task_ids trifft es genau diese ───────────────────────────────
  update public.tasks set status = 'draft', reviewed_by = null, reviewed_at = null
   where id = any (v_ids[1:4]);
  v_ist := public.freigabe_muster('A21_PROBE', array[v_ids[1], v_ids[2]]);
  if v_ist <> 2 then raise exception 'P2 Rueckgabe %, erwartet 2', v_ist; end if;
  if (select count(*) from public.tasks where id in (v_ids[1], v_ids[2]) and status = 'ready') <> 2 then
    raise exception 'P2 die zwei benannten sind nicht ready';
  end if;
  if (select count(*) from public.tasks where id in (v_ids[3], v_ids[4]) and status = 'draft') <> 2 then
    raise exception 'P2 nicht benannte Aufgaben wurden angetastet';
  end if;
  raise notice 'P2 ok: p_task_ids trifft genau die zwei benannten';

  -- ── Gate: ein unvollstaendiges draft wird NICHT freigegeben (uebersprungen) ─
  -- Der Punkt dieses Laufs: eine Sammelfreigabe hebt Vollstaendigkeit nicht auf.
  update public.tasks set status = 'draft', reviewed_by = null, reviewed_at = null
   where id = any (v_ids[1:4]);
  update public.tasks set curriculum_grade = null where id = v_ids[4];  -- Stoffanker weg -> Gate P0001
  v_ist := public.freigabe_muster('A21_PROBE');
  if v_ist <> 3 then raise exception 'PGate Rueckgabe %, erwartet 3 (unvollstaendiges uebersprungen)', v_ist; end if;
  if (select status from public.tasks where id = v_ids[4]) <> 'draft' then
    raise exception 'PGate unvollstaendiges Item wurde freigegeben';
  end if;
  raise notice 'PGate ok: unvollstaendiges draft bleibt draft, Gruppe laeuft weiter (3 frei)';

  -- ── 4. Zuruecknehmen setzt nur eigene 'ready' zurueck ──────────────────────
  -- Stand: [1..3] ready, [4] draft, [5] beanstandet, [6] review.
  v_ist := public.freigabe_zuruecknehmen('A21_PROBE');
  if v_ist <> 3 then raise exception 'P4 Rueckgabe %, erwartet 3', v_ist; end if;
  if (select count(*) from public.tasks where id = any (v_ids[1:4]) and status = 'draft') <> 4 then
    raise exception 'P4 nicht alle vier sind draft';
  end if;
  if (select status from public.tasks where id = v_ids[5]) <> 'beanstandet' then
    raise exception 'P4 beanstandet wurde angetastet';
  end if;
  if (select status from public.tasks where id = v_ids[6]) <> 'review' then
    raise exception 'P4 review wurde angetastet';
  end if;
  if (select count(*) from public.tasks where id = any (v_ids[1:4]) and reviewed_by is not null) <> 0 then
    raise exception 'P4 Freigabe-Stempel nicht geloescht';
  end if;
  raise notice 'P4 ok: nur ready->draft, beanstandet/review bleiben, Stempel geloescht';

  -- ── Sicherheit: Nicht-Admin wird abgewiesen (null-sicherer Rollen-Check) ───
  perform set_config('request.jwt.claims', json_build_object('sub', gen_random_uuid())::text, true);
  v_ctrl := false;
  begin perform public.freigabe_muster('A21_PROBE');
  exception when sqlstate '42501' then v_ctrl := true; end;
  if not v_ctrl then raise exception 'PSec Nicht-Admin wurde NICHT abgewiesen'; end if;
  perform set_config('request.jwt.claims', json_build_object('sub', v_admin)::text, true);
  raise notice 'PSec ok: Nicht-Admin (get_my_role NULL) abgewiesen mit 42501';

  -- ── 5. Negativkontrolle: der Harness MUSS bei falscher Erwartung abbrechen ─
  v_ctrl := false;
  begin
    if (select count(*) from public.tasks where skill_key = 'A21_PROBE') <> -1 then
      raise exception 'kontrolle: absichtlich falsche Erwartung';
    end if;
  exception when others then v_ctrl := true;
  end;
  if not v_ctrl then raise exception 'P5 Negativkontrolle hat nicht ausgeloest'; end if;
  raise notice 'P5 ok: Negativkontrolle greift';

  raise notice 'A21: ALLE PRUEFUNGEN BESTANDEN';
end $$;

rollback;
