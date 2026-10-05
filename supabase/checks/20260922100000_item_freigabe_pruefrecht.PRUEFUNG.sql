-- Pruefung zu 20260922100000_item_freigabe_pruefrecht, angepasst an das Lena-Board
-- (20261005071650_pruefung_rechte). Laeuft in begin/rollback NACH den Migrationen. Braucht einen
-- admin und einen coach im Bestand; der coach bekommt darf_pruefen nur innerhalb der Transaktion.
--
-- Seit dem Lena-Board schreibt ein Pruefer ausschliesslich ueber die pruef_*-Funktionen.
-- task_status_set, task_solution_upsert, lena_beanstande und das direkte UPDATE auf tasks sind
-- admin (und Systemaufrufen) vorbehalten. Der alte Stand (Pruefer setzt review per
-- task_status_set, pflegt Felder direkt) ist damit ueberholt.
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
  v_task uuid; v_ready uuid; v_luecke uuid; v_frei uuid; v_cluster uuid;
  v_n int; v_status text; v_wer uuid; v_fn text; v_version bigint;
begin
  select id into v_admin from public.profiles where role = 'admin' limit 1;
  select id into v_coach from public.profiles where role = 'coach' limit 1;
  if v_admin is null or v_coach is null then raise exception 'admin/coach fehlt im Bestand'; end if;
  -- Wiederholbar, auch wenn das Recht live schon vergeben ist.
  update public.profiles set darf_pruefen = false where id = v_coach;
  -- Laeuft der Pilot (nur_pilot, Datenpunkt 26), waere jede andere Aufgabe fuer den Pruefer gesperrt.
  update public.pruef_einstellungen set nur_pilot = false;

  -- Eine vollstaendige Board-Aufgabe (nicht VERA8, kein Ausschluss) auf draft gelegt.
  select id, cluster_id into v_task, v_cluster from public.tasks
   where public.pruef_ausschluss(id) is null and cluster_id is not null
   order by id limit 1;
  select id into v_ready from public.tasks where status = 'ready' and id <> v_task limit 1;
  if v_task is null or v_ready is null then raise exception 'Board- oder ready-Aufgabe fehlt im Bestand'; end if;
  update public.tasks set status = 'draft', reviewed_by = null, reviewed_at = null where id = v_task;

  -- ── P0: Grants — anon darf keine der Schreib-RPCs betreten ───────────────
  foreach v_fn in array array[
    'public.lena_text_aendern(uuid,text)',
    'public.lena_beanstande_muster(text,text,text,text)',
    'public.lena_beanstande(uuid,text,text)',
    'public.task_status_set(uuid,text)',
    'public.freigabe_cluster(uuid)',
    'public.darf_pruefen()',
    'public.ist_systemaufruf()',
    'public.pruef_board()',
    'public.pruef_aufgabe(uuid)',
    'public.pruef_speichern(uuid,bigint,jsonb)',
    'public.pruef_entscheiden(uuid,bigint,text,text[],text,text,integer)',
    'public.pruef_rueckgaengig(uuid,bigint)',
    'public.pruef_wertung_testen(uuid,integer,text,jsonb)',
    'public.pruef_rueckfrage_klaeren(uuid,text,text,text[])',
    'public.pruef_admin_liste()'] loop
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
    perform pg_temp.muss_scheitern('P1 board', 'select count(*) from public.pruef_board()', '42501');
    perform pg_temp.muss_scheitern('P1 aufgabe',
      format('select public.pruef_aufgabe(%L)', v_task), '42501');
  end loop;
  raise notice 'P1 ok: anon / ohne Profil / coach ohne Recht schreiben und pruefen nicht';

  -- ── P2: Pruefer nur ueber pruef_*; die alten Wege sind zu ────────────────
  update public.profiles set darf_pruefen = true where id = v_coach;
  perform pg_temp.als(v_coach, 'authenticated');
  perform pg_temp.muss_scheitern('P2 status_set review',
    format('select public.task_status_set(%L, %L)', v_task, 'review'), '42501');
  perform pg_temp.muss_scheitern('P2 status_set ready',
    format('select public.task_status_set(%L, %L)', v_task, 'ready'), '42501');
  perform pg_temp.muss_scheitern('P2 upsert',
    format('select public.task_solution_upsert(%L)', v_task), '42501');
  perform pg_temp.muss_scheitern('P2 beanstande',
    format('select public.lena_beanstande(%L, %L)', v_task, 'formulierung'), '42501');
  v_version := (public.pruef_aufgabe(v_task) -> 'aufgabe' ->> 'pruef_version')::bigint;
  perform public.pruef_entscheiden(v_task, v_version, 'passt');
  select status into v_status from public.tasks where id = v_task;
  if v_status <> 'review' then raise exception 'P2: Passt setzte nicht review (%)', v_status; end if;
  perform pg_temp.muss_scheitern('P2 speichern auf ready',
    format('select public.pruef_speichern(%L, %s, %L)', v_ready,
           (select pruef_version from public.tasks where id = v_ready), '{}'), 'ED422');
  raise notice 'P2 ok: Pruefer entscheidet ueber pruef_entscheiden, alte Wege 42501';

  -- ── P3: Gate gilt fuer review, auch fuer "Passt" ─────────────────────────
  update public.tasks set cluster_id = null where id = v_task;   -- als owner
  perform pg_temp.muss_scheitern('P3 Passt ohne Cluster',
    format('select public.pruef_entscheiden(%L, %s, %L)', v_task,
           (select pruef_version from public.tasks where id = v_task), 'passt'), 'ED422');
  perform pg_temp.als(v_admin, 'authenticated');
  perform pg_temp.muss_scheitern('P3 review ohne Cluster',
    format('select public.task_status_set(%L, %L)', v_task, 'review'), 'P0001');
  update public.tasks set cluster_id = v_cluster where id = v_task;
  raise notice 'P3 ok: review braucht die Pflichtfelder';

  -- ── P4: Beanstanden — admin ueber lena_beanstande, Pruefer ueber "Passt nicht" ─
  perform public.lena_beanstande(v_task, 'loesung_passt_nicht', 'Probe');
  select status into v_status from public.tasks where id = v_task;
  if v_status <> 'beanstandet' then raise exception 'P4: nicht beanstandet'; end if;
  -- Vom Team beanstandet: der Pruefer liest nur, bis der Admin ueberarbeitet hat (PR 208).
  perform pg_temp.als(v_coach, 'authenticated');
  perform pg_temp.muss_scheitern('P4 Team-Beanstandung neu bewerten',
    format('select public.pruef_entscheiden(%L, %s, %L)', v_task,
           (select pruef_version from public.tasks where id = v_task), 'passt'), 'ED422');
  perform pg_temp.als(v_admin, 'authenticated');
  perform public.task_status_set(v_task, 'draft');                  -- ueberarbeitet, wieder offen
  perform pg_temp.als(v_coach, 'authenticated');
  perform public.pruef_entscheiden(v_task, (select pruef_version from public.tasks where id = v_task),
                                   'passt_nicht', array['aufgabe_unklar'], 'Probe');
  if not exists (select 1 from public.task_reviews where task_id = v_task and kategorie = 'aufgabe_unklar') then
    raise exception 'P4: Grund aus "Passt nicht" fehlt in task_reviews';
  end if;
  perform public.pruef_entscheiden(v_task, (select pruef_version from public.tasks where id = v_task), 'passt');
  raise notice 'P4 ok: Team-Beanstandung gesperrt, nach Ueberarbeitung offen; eigenes Passt nicht -> review';

  -- ── P5: direktes UPDATE als authenticated ────────────────────────────────
  -- RLS verweigert ein UPDATE still (0 Zeilen) — deshalb row_count pruefen.
  execute 'set local role authenticated';
  update public.tasks set title = title where id = v_task;
  get diagnostics v_n = row_count;
  if v_n <> 0 then raise exception 'P5: Pruefer konnte tasks direkt aendern'; end if;
  update public.profiles set darf_pruefen = false where id = v_coach;   -- sich selbst: nein
  get diagnostics v_n = row_count;
  if v_n <> 0 then raise exception 'P5: darf_pruefen per authenticated aenderbar'; end if;
  execute 'reset role';
  raise notice 'P5 ok: kein direktes UPDATE fuer Pruefer';

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

  -- ── P8: freigabe_cluster nur admin; nur unveraenderte "Passt" ohne Admin-Beanstandung ─
  perform pg_temp.als(v_coach, 'authenticated');
  perform pg_temp.muss_scheitern('P8 Pruefer',
    format('select public.freigabe_cluster(%L)', v_cluster), '42501');
  select id into v_frei from public.tasks
   where cluster_id = v_cluster and id not in (v_task, v_ready) and status = 'draft'
     and public.pruef_ausschluss(id) is null
   order by id limit 1;
  perform public.pruef_entscheiden(v_frei,
    (public.pruef_aufgabe(v_frei) -> 'aufgabe' ->> 'pruef_version')::bigint, 'passt');
  select id into v_luecke from public.tasks
   where cluster_id = v_cluster and id not in (v_task, v_ready, v_frei) limit 1;
  update public.tasks set status = 'review', afb = null where id = v_luecke;  -- als owner
  perform pg_temp.als(v_admin, 'authenticated');
  v_n := public.freigabe_cluster(v_cluster);
  select status into v_status from public.tasks where id = v_frei;
  if v_n < 1 or v_status <> 'ready' then
    raise exception 'P8: freigabe_cluster hob % Aufgaben, Status %', v_n, v_status;
  end if;
  if (select reviewed_by from public.tasks where id = v_frei) is distinct from v_admin then
    raise exception 'P8: Freigabe-Stempel fehlt';
  end if;
  select status into v_status from public.tasks where id = v_luecke;
  if v_status <> 'review' then raise exception 'P8: unvollstaendige Aufgabe freigegeben'; end if;
  select status into v_status from public.tasks where id = v_task;
  if v_status <> 'review' then raise exception 'P8: vom Admin beanstandete Aufgabe sammelfreigegeben'; end if;
  raise notice 'P8 ok: freigabe_cluster hob %, Unvollstaendige und Admin-beanstandete blieben review', v_n;
end $$;
