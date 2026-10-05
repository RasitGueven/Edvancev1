-- Ruecknahme von Migration 3 (20261005071650_pruefung_rechte) — NICHT im Migrationsordner.
--
-- Stellt den Stand nach Migration 2 her: Policy pruefer_update_tasks wieder da, und
-- task_status_set, task_solution_upsert, lena_beanstande lassen wieder Pruefer (darf_pruefen())
-- durch. task_status_set und task_solution_upsert entsprechen Migration 2c (Gate ausgelagert,
-- Sicherheitsnetz fuer acceptance), lena_beanstande dem Stand vor dem Lena-Board
-- (20260922100000_item_freigabe_pruefrecht).
--
-- Einspielen nur auf Anweisung von Rasit, in einer Transaktion:
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f docs/lena-board/rollback_rechte.sql
-- Danach den Eintrag 20261005071650 aus supabase_migrations.schema_migrations entfernen, damit die
-- Migrationshistorie stimmt, und tools/schema-snapshot.sh laufen lassen.

create policy pruefer_update_tasks on public.tasks
  for update to authenticated
  using (public.darf_pruefen())
  with check (public.darf_pruefen());

create or replace function public.task_status_set(p_task_id uuid, p_status text)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_task  tasks%rowtype;
  v_admin boolean := public.get_my_role() is not distinct from 'admin'
                     or public.ist_systemaufruf();
  v_gate  text;
begin
  if not (v_admin or public.darf_pruefen()) then
    raise exception 'task_status_set: kein Pruefrecht' using errcode = '42501';
  end if;
  if p_status not in ('draft', 'review', 'ready') then
    raise exception 'task_status_set: unbekannter Status %', p_status using errcode = '22023';
  end if;
  -- for update: sonst liest ein Pruefer 'review', waehrend admin gerade freigibt.
  select * into v_task from tasks where id = p_task_id for update;
  if not found then
    raise exception 'task_status_set: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if not v_admin and (p_status = 'ready' or v_task.status = 'ready') then
    raise exception 'task_status_set: freigeben und zuruecknehmen nur admin' using errcode = '42501';
  end if;
  if p_status in ('review', 'ready') then
    v_gate := public.freigabe_gate_fehler(p_task_id);
    if v_gate is not null then
      raise exception '%', v_gate using errcode = 'P0001';
    end if;
  end if;

  update tasks
     set status      = p_status,
         reviewed_by = case when p_status = 'ready' then auth.uid() else null end,
         reviewed_at = case when p_status = 'ready' then now()      else null end
   where id = p_task_id;

  if v_admin and p_status = 'draft' and v_task.status in ('review', 'rueckfrage', 'beanstandet') then
    delete from task_pruefung_ausgang where task_id = p_task_id;
  end if;

  return jsonb_build_object('ok', true, 'task_id', p_task_id, 'status', p_status);
end $$;

create or replace function public.task_solution_upsert(
  p_task_id uuid, p_correct_answers jsonb default null, p_solution text default null,
  p_hints jsonb default null, p_coach_hints jsonb default null, p_typical_errors jsonb default null,
  p_beleg jsonb default null, p_acceptance jsonb default null, p_option_scores jsonb default null)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_admin  boolean := public.get_my_role() is not distinct from 'admin'
                      or public.ist_systemaufruf();
  v_status text;
  v_typ    text;
  v_alt    jsonb;
begin
  if not (v_admin or public.darf_pruefen()) then
    raise exception 'task_solution_upsert: kein Pruefrecht' using errcode = '42501';
  end if;
  select status, input_type into v_status, v_typ from tasks where id = p_task_id for update;
  if not found then
    raise exception 'task_solution_upsert: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if not v_admin and v_status = 'ready' then
    raise exception 'task_solution_upsert: eine freigegebene Aufgabe aendert nur admin'
      using errcode = '42501';
  end if;
  if p_beleg is not null and jsonb_typeof(p_beleg) not in ('array', 'null') then
    raise exception 'task_solution_upsert: beleg muss ein Array sein (oder JSON-null zum Leeren)'
      using errcode = '22023';
  end if;
  if p_correct_answers is not null and p_acceptance is null and v_typ is distinct from 'TERM' then
    select acceptance into v_alt from task_solutions where task_id = p_task_id;
    if v_alt is not null and public.pruef_acceptance_angleichen(v_alt, p_correct_answers) is distinct from v_alt then
      p_acceptance := public.pruef_acceptance_angleichen(v_alt, p_correct_answers);
    end if;
  end if;
  if p_acceptance is not null and jsonb_typeof(p_acceptance) <> 'null'
     and not public.lsa_acceptance_valid(p_acceptance) then
    raise exception 'task_solution_upsert: acceptance verletzt den Strukturvertrag '
                    '(canonical fehlt, unbekanntes notation-Flag, tolerance ungueltig '
                    'oder unit_graded zusammen mit unit_optional)'
      using errcode = '22023';
  end if;
  if p_option_scores is not null and jsonb_typeof(p_option_scores) <> 'null'
     and not public.lsa_option_scores_valid(p_option_scores) then
    raise exception 'task_solution_upsert: option_scores verletzt den Strukturvertrag '
                    '(nur voll|teilweise|nicht, hoechstens eine ''voll'' und eine '
                    '''teilweise'' je Aufgabe/Teilaufgabe)'
      using errcode = '22023';
  end if;

  insert into task_solutions as s
    (task_id, correct_answers, solution, hints, coach_hints, typical_errors, beleg,
     acceptance, option_scores, updated_at)
  values
    (p_task_id, coalesce(p_correct_answers, '[]'::jsonb), nullif(p_solution, ''),
     coalesce(p_hints, '[]'::jsonb), coalesce(p_coach_hints, '[]'::jsonb),
     coalesce(p_typical_errors, '[]'::jsonb),
     case when p_beleg is null or jsonb_typeof(p_beleg) = 'null' then null else p_beleg end,
     case when p_acceptance is null or jsonb_typeof(p_acceptance) = 'null' then null else p_acceptance end,
     case when p_option_scores is null or jsonb_typeof(p_option_scores) = 'null' then null else p_option_scores end,
     now())
  on conflict (task_id) do update
     set correct_answers = coalesce(p_correct_answers, s.correct_answers),
         solution        = case when p_solution is null then s.solution else nullif(p_solution, '') end,
         hints           = coalesce(p_hints, s.hints),
         coach_hints     = coalesce(p_coach_hints, s.coach_hints),
         typical_errors  = coalesce(p_typical_errors, s.typical_errors),
         beleg           = case when p_beleg is null then s.beleg
                                when jsonb_typeof(p_beleg) = 'null' then null else p_beleg end,
         acceptance      = case when p_acceptance is null then s.acceptance
                                when jsonb_typeof(p_acceptance) = 'null' then null else p_acceptance end,
         option_scores   = case when p_option_scores is null then s.option_scores
                                when jsonb_typeof(p_option_scores) = 'null' then null else p_option_scores end,
         updated_at      = now();

  return jsonb_build_object('ok', true, 'task_id', p_task_id);
end $$;

create or replace function public.lena_beanstande(p_task_id uuid, p_kategorie text, p_notiz text default null)
returns integer language plpgsql security definer set search_path = public, pg_temp as $$
declare v_status text;
begin
  if not public.darf_pruefen() then
    raise exception 'A20: kein Pruefrecht fuer Beanstandungen' using errcode = '42501';
  end if;
  select status into v_status from public.tasks where id = p_task_id for update;
  if not found then
    raise exception 'A20: Aufgabe % nicht gefunden', p_task_id using errcode = 'P0002';
  end if;
  if v_status = 'ready' and public.get_my_role() is distinct from 'admin' then
    raise exception 'A20: eine freigegebene Aufgabe beanstandet nur admin'
      using errcode = '42501';
  end if;
  update public.tasks
     set status = 'beanstandet', reviewed_by = null, reviewed_at = null
   where id = p_task_id;
  insert into public.task_reviews (task_id, kategorie, notiz, geprueft_von)
    values (p_task_id, p_kategorie, p_notiz, auth.uid());
  return 1;
end $$;
