-- Pruefung zu 20260922100000_item_freigabe_pruefrecht. Laeuft in begin/rollback
-- NACH der Migration. Braucht einen admin und einen coach im Bestand; der coach
-- bekommt darf_pruefen nur innerhalb der Transaktion.
--
-- Die Claims tragen immer eine Rolle wie bei PostgREST: ohne Rolle gilt ein
-- Aufruf als Systemaufruf (ist_systemaufruf) und jede Sperre waere wirkungslos.

create or replace function pg_temp.als(p_sub uuid, p_role text) returns void
language sql as $$
  select set_config('request.jwt.claims',
    case when p_role is null then ''
         else json_build_object('sub', p_sub, 'role', p_role)::text end, true)
$$;

-- Fuehrt p_sql aus und verlangt SQLSTATE p_state. Meldet p_fall bei Durchlauf.
create or replace function pg_temp.muss_scheitern(p_fall text, p_sql text, p_state text)
returns void language plpgsql as $$
begin
  execute p_sql;
  raise exception '%: lief durch, erwartet %', p_fall, p_state;
exception when others then
  if sqlstate <> p_state then
    raise exception '%: SQLSTATE % (%), erwartet %', p_fall, sqlstate, sqlerrm, p_state;
  end if;
end $$;

do $$
declare
  v_admin uuid; v_coach uuid; v_ghost uuid := gen_random_uuid();
  v_task uuid; v_ready uuid; v_luecke uuid; v_cluster uuid;
  v_n int; v_status text; v_wer uuid; v_fn text;
begin
  select id into v_admin from public.profiles where role = 'admin' limit 1;
  select id into v_coach from public.profiles where role = 'coach' limit 1;
  if v_admin is null or v_coach is null then raise exception 'admin/coach fehlt im Bestand'; end if;
  -- Wiederholbar, auch wenn das Recht live schon vergeben ist.
  update public.profiles set darf_pruefen = false where id = v_coach;

  -- Eine vollstaendige Aufgabe (ready im Bestand) fuer den Test auf draft gelegt.
  select id, cluster_id into v_task, v_cluster from public.tasks
   where status = 'ready' and cluster_id is not null limit 1;
  select id into v_ready from public.tasks where status = 'ready' and id <> v_task limit 1;
  update public.tasks set status = 'draft', reviewed_by = null, reviewed_at = null where id = v_task;

  -- ── P0: Grants — anon darf keine der Schreib-RPCs betreten ───────────────
  foreach v_fn in array array[
    'public.lena_text_aendern(uuid,text)',
    'public.lena_beanstande_muster(text,text,text,text)',
    'public.lena_beanstande(uuid,text,text)',
    'public.task_status_set(uuid,text)',
    'public.freigabe_cluster(uuid)',
    'public.darf_pruefen()',
    'public.ist_systemaufruf()'] loop
    if has_function_privilege('anon', v_fn, 'execute') then
      raise exception 'P0: anon darf % ausfuehren', v_fn;
    end if;
  end loop;
  raise notice 'P0 ok: kein anon-Execute';

  -- ── P1: anon, Login ohne Profil, coach ohne Recht — alle 42501 ───────────
  foreach v_wer in array array[null, v_ghost, v_coach] loop
    perform pg_temp.als(v_wer, case when v_wer is null then 'anon' else 'authenticated' end);
    perform pg_temp.muss_scheitern('P1 status_set',
      format('select public.task_status_set(%L, %L)', v_task, 'review'), '42501');
    perform pg_temp.muss_scheitern('P1 beanstande',
      format('select public.lena_beanstande(%L, %L)', v_task, 'formulierung'), '42501');
    perform pg_temp.muss_scheitern('P1 upsert',
      format('select public.task_solution_upsert(%L)', v_task), '42501');
    perform pg_temp.muss_scheitern('P1 muster',
      format('select public.lena_beanstande_muster(%L, %L, %L)', 'x', 'y', 'formulierung'), '42501');
    perform pg_temp.muss_scheitern('P1 text',
      format('select public.lena_text_aendern(%L, %L)', v_task, 'x'), '42501');
  end loop;
  raise notice 'P1 ok: anon / ohne Profil / coach ohne Recht schreiben nicht';

  -- ── P2: Pruefer setzt review und draft, nie ready ────────────────────────
  update public.profiles set darf_pruefen = true where id = v_coach;
  perform pg_temp.als(v_coach, 'authenticated');
  perform public.task_status_set(v_task, 'review');
  select status into v_status from public.tasks where id = v_task;
  if v_status <> 'review' then raise exception 'P2: review nicht gesetzt (%)', v_status; end if;
  perform pg_temp.muss_scheitern('P2 ready',
    format('select public.task_status_set(%L, %L)', v_task, 'ready'), '42501');
  perform public.task_status_set(v_task, 'draft');            -- Zur Freigabe zuruecknehmen
  perform pg_temp.muss_scheitern('P2 zuruecknehmen',
    format('select public.task_status_set(%L, %L)', v_ready, 'draft'), '42501');
  perform pg_temp.muss_scheitern('P2 upsert auf ready',
    format('select public.task_solution_upsert(%L)', v_ready), '42501');
  perform public.task_solution_upsert(v_task);                 -- Loesungspflege: ja
  raise notice 'P2 ok: Pruefer review/draft/Loesung ja, ready nein';

  -- ── P3: Gate gilt fuer review ────────────────────────────────────────────
  update public.tasks set cluster_id = null where id = v_task;   -- als owner
  perform pg_temp.muss_scheitern('P3 review ohne Cluster',
    format('select public.task_status_set(%L, %L)', v_task, 'review'), 'P0001');
  update public.tasks set cluster_id = v_cluster where id = v_task;
  raise notice 'P3 ok: review braucht die Pflichtfelder';

  -- ── P4: Beanstanden mit neuer Kategorie, nicht bei ready ─────────────────
  perform public.lena_beanstande(v_task, 'loesung_passt_nicht', 'Probe');
  select status into v_status from public.tasks where id = v_task;
  if v_status <> 'beanstandet' then raise exception 'P4: nicht beanstandet'; end if;
  perform pg_temp.muss_scheitern('P4 ready beanstanden',
    format('select public.lena_beanstande(%L, %L)', v_ready, 'formulierung'), '42501');
  perform public.task_status_set(v_task, 'review');            -- korrigiert, zur Freigabe
  raise notice 'P4 ok: Beanstandung + Rueckweg beanstandet -> review';

  -- ── P5: direktes UPDATE als authenticated ────────────────────────────────
  -- RLS verweigert ein UPDATE still (0 Zeilen) — deshalb row_count pruefen.
  execute 'set local role authenticated';
  update public.tasks set title = title where id = v_task;
  get diagnostics v_n = row_count;
  if v_n <> 1 then raise exception 'P5: Pruefer konnte das Feld nicht pflegen'; end if;
  perform pg_temp.muss_scheitern('P5 status',
    format('update public.tasks set status = %L where id = %L', 'ready', v_task), '42501');
  perform pg_temp.muss_scheitern('P5 stempel',
    format('update public.tasks set reviewed_at = now() where id = %L', v_task), '42501');
  perform pg_temp.muss_scheitern('P5 source',
    format('update public.tasks set source = %L where id = %L', 'x', v_task), '42501');
  perform pg_temp.muss_scheitern('P5 ready-Aufgabe',
    format('update public.tasks set title = title where id = %L', v_ready), '42501');
  update public.profiles set darf_pruefen = false where id = v_coach;   -- sich selbst: nein
  get diagnostics v_n = row_count;
  if v_n <> 0 then raise exception 'P5: darf_pruefen per authenticated aenderbar'; end if;
  execute 'reset role';
  update public.profiles set darf_pruefen = false where id = v_coach;
  execute 'set local role authenticated';
  update public.tasks set title = title where id = v_task;
  get diagnostics v_n = row_count;
  if v_n <> 0 then raise exception 'P5: coach ohne Pruefrecht konnte pflegen'; end if;
  execute 'reset role';
  update public.profiles set darf_pruefen = true where id = v_coach;
  raise notice 'P5 ok: Feldpflege ja; Status, Stempel, Herkunft, ready-Aufgaben nein';

  -- ── P6: admin direkt bleibt unberuehrt ───────────────────────────────────
  perform pg_temp.als(v_admin, 'authenticated');
  execute 'set local role authenticated';
  update public.tasks set title = title, source = source where id = v_ready;
  get diagnostics v_n = row_count;
  if v_n <> 1 then raise exception 'P6: admin konnte ready-Aufgabe nicht aendern'; end if;
  execute 'reset role';
  raise notice 'P6 ok: admin aendert ready-Aufgaben weiter direkt';

  -- ── P7: Systemaufrufe (Importe, Content-Migrationen) passieren ───────────
  perform pg_temp.als(null, 'service_role');
  perform public.task_solution_upsert(v_ready);
  perform pg_temp.als(null, null);                             -- ohne JWT = direkt
  perform public.task_solution_upsert(v_ready);
  perform public.task_status_set(v_ready, 'ready');
  raise notice 'P7 ok: service_role und direkte Verbindung passieren';

  -- ── P8: freigabe_cluster nur admin; ueberspringt Unvollstaendige ─────────
  perform pg_temp.als(v_coach, 'authenticated');
  perform pg_temp.muss_scheitern('P8 Pruefer',
    format('select public.freigabe_cluster(%L)', v_cluster), '42501');
  select id into v_luecke from public.tasks
   where cluster_id = v_cluster and id not in (v_task, v_ready) limit 1;
  update public.tasks set status = 'review', afb = null where id = v_luecke;  -- als owner
  perform pg_temp.als(v_admin, 'authenticated');
  v_n := public.freigabe_cluster(v_cluster);
  select status into v_status from public.tasks where id = v_task;
  if v_n < 1 or v_status <> 'ready' then
    raise exception 'P8: freigabe_cluster hob % Aufgaben, Status %', v_n, v_status;
  end if;
  if (select reviewed_by from public.tasks where id = v_task) is distinct from v_admin then
    raise exception 'P8: Freigabe-Stempel fehlt';
  end if;
  select status into v_status from public.tasks where id = v_luecke;
  if v_status <> 'review' then raise exception 'P8: unvollstaendige Aufgabe freigegeben'; end if;
  raise notice 'P8 ok: freigabe_cluster hob %, Unvollstaendige blieb review', v_n;
end $$;
