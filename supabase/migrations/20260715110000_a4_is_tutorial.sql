-- ============================================================================
-- A4 (S5-Intake Ebene A): Tutorial-Pool — `tasks.is_tutorial`.
--
-- Ein kleiner Satz trivialer Aufgaben nur zum Formate-Zeigen (MC anklicken,
-- Zahl eintippen). Über `is_tutorial` markiert. NIE im LSA-Pool: das Tutorial
-- zeigt die Bedienung, es misst nicht.
--
-- Eingriff in `lsa_start`: ausschließlich ein ADDITIVER Filter im Pool-CTE
--   (`and coalesce(t.is_tutorial, false) = false`). KEINE Signatur-Änderung,
--   KEIN Lead-Session-Modell — das ist A1 (zweiter Lauf). Die 14 bestehenden
--   ready-Pool-Items haben is_tutorial=false (Default) und bleiben unberührt.
--
-- Der Rest der Funktion ist wortgleich zur Fassung aus
--   20260713100000_p02_multipart.sql — nur die eine WHERE-Zeile kommt hinzu.
-- ============================================================================

begin;

alter table tasks
  add column if not exists is_tutorial boolean not null default false;

comment on column tasks.is_tutorial is
  'Trivial-Aufgabe nur zum Formate-Zeigen (Bedienung, nicht Messung). '
  'NIE im LSA-Pool: lsa_start zieht ausschließlich is_tutorial=false. '
  'Tutorial-Antworten werden nicht in lsa_responses geschrieben und nie ausgewertet.';

-- Ein Teilindex hält den Pool-Filter günstig (die echten Items sind die kleine
-- Minderheit, die tatsächlich gezogen wird).
create index if not exists tasks_lsa_pool_idx
  on tasks (status)
  where is_tutorial = false;

-- --- lsa_start — additiver Tutorial-Ausschluss --------------------------------
create or replace function public.lsa_start(
  p_student_id uuid,
  p_grade      integer,
  p_subject    text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session_id uuid;
  v_items      uuid[];
begin
  if not public.lsa_may_act_for(p_student_id) then
    raise exception 'LSA: kein Zugriff auf diesen Schueler' using errcode = '42501';
  end if;
  if not exists (select 1 from students where id = p_student_id) then
    raise exception 'LSA: Schueler nicht gefunden' using errcode = 'P0002';
  end if;
  if exists (
    select 1 from lsa_sessions
     where student_id = p_student_id and subject = p_subject and status = 'in_progress'
  ) then
    raise exception 'LSA: fuer % laeuft bereits eine Session', p_subject
      using errcode = 'P0001';
  end if;

  with pool as (
    select t.id,
           coalesce(t.afb, 'II')                as afb,
           coalesce(t.competency_content, '?')  as comp,
           -- MULTI_PART hat est_duration_sec garantiert (CHECK). Der Fallback ist
           -- ausschliesslich die Bestandsregel fuer flache Items.
           coalesce(t.est_duration_sec, t.estimated_minutes * 60, 180) as secs
      from tasks t
      join task_solutions s on s.task_id = t.id
      join skill_clusters c on c.id = t.cluster_id
      join subjects sub     on sub.id = c.subject_id
     where t.status = 'ready'
       and coalesce(t.is_active, true)
       -- A4: das Tutorial zeigt die Bedienung, es misst nicht — nie in den Pool.
       and coalesce(t.is_tutorial, false) = false
       and t.input_type in ('MC','SHORT_TEXT','NUMERIC','MULTI_PART')
       and public.lsa_has_answers(t.input_type, t.parts, s.correct_answers)
       and sub.name = p_subject
       and coalesce(t.class_level, p_grade) <= p_grade
  ),
  mixed as (
    select id,
           secs,
           row_number() over (partition by afb, comp order by random()) as rn,
           row_number() over (order by random())                        as tiebreak
      from pool
  ),
  ordered as (
    select id,
           sum(secs) over (order by rn, tiebreak
                           rows between unbounded preceding and current row) as cum,
           secs,
           rn,
           tiebreak
      from mixed
  )
  select array_agg(id order by rn, tiebreak)
    into v_items
    from ordered
   where cum - secs < 1200;

  if v_items is null or array_length(v_items, 1) = 0 then
    raise exception 'LSA: kein freigegebener Item-Pool fuer % / Klasse %', p_subject, p_grade
      using errcode = 'P0002';
  end if;

  insert into lsa_sessions (student_id, subject, grade, item_ids, started_at)
  values (p_student_id, p_subject, p_grade, v_items, now())
  returning id into v_session_id;

  return jsonb_build_object(
    'session_id',  v_session_id,
    'total_items', array_length(v_items, 1),
    'item',        public.lsa_question_payload(v_items[1])
  );
end;
$$;

-- Grants: unveränderte Signatur → die P01-Grants gelten weiter. Sicherheitshalber
-- (create or replace grantet Postgres NICHT neu an PUBLIC) nichts weiter nötig.

commit;
