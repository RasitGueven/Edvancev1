-- ============================================================================
-- P01: Datenvertrag + LSA-Logik
--
-- Drei Dinge:
--   1. Lenas Aufgaben-Metadaten — oeffentliche Felder auf `tasks`, GEHEIME
--      Felder (Loesung, Hinweise, typische Fehler) in der 1:1-Extension-Tabelle
--      `task_solutions`.
--   2. Der `question_payload`-Vertrag: ein Builder, der das Client-Payload aus
--      einer WHITELIST baut (kind/prompt/assets/options/unit) — er kopiert nie
--      ein bestehendes jsonb durch. Eine Loesung kann strukturell nicht
--      mitrutschen.
--   3. Die LSA (Lernstandsanalyse): eigene Session-Tabellen + drei RPCs.
--
-- WARUM Extension-Tabelle statt Column-Grants:
--   Spaltenweise Grants sind in Postgres nicht additiv verlaesslich (ein
--   `grant select on tasks` an anderer Stelle hebt sie wieder auf), und
--   PostgREST wuerde `select=*` weiterhin anbieten. `task_solutions` hat
--   schlicht KEIN Grant fuer anon/authenticated. Erreichbar ist der Inhalt nur
--   ueber die SECURITY-DEFINER-RPCs unten. Das ist die Sicherheitszusage aus
--   Spec §4 — und sie ist per pgTAP beweisbar
--   (supabase/tests/inv2_lsa_datenvertrag.test.sql).
--
-- WICHTIG: Die default privileges aus 20260711120000_api_role_grants.sql
--   geben JEDER neuen Tabelle automatisch DML an authenticated. Der REVOKE
--   unten ist deshalb nicht kosmetisch, sondern der eigentliche Schutz.
--
-- Diskriminator ist `input_type` (kanonischer Enum aus Migration 042,
-- src/types/answerPayload.ts). `content_type` ist das Medienformat und
-- gleichzeitig PK von xp_rules — bewusst nicht angefasst.
-- ============================================================================

begin;

-- ============================================================================
-- 1. Lenas Metadaten auf `tasks` (oeffentlich: darf das Kind sehen/impliziert
--    keine Loesung)
-- ============================================================================

alter table tasks
  -- Redaktions-Status. `is_active` bleibt, was es war (Sichtbarkeit im
  -- Lernpfad); `status` ist der Freigabe-Zustand von Lenas Redaktion. Nur
  -- 'ready' kommt in den LSA-Pool.
  add column if not exists status text not null default 'draft'
    check (status in ('draft','review','ready')),
  add column if not exists competency_content text,
  add column if not exists competency_process text,
  add column if not exists afb text check (afb in ('I','II','III')),
  add column if not exists est_duration_sec integer
    check (est_duration_sec is null or est_duration_sec between 10 and 3600),
  -- Einheit fuer short_input ("m", "cm", "€"). Rein deklarativ — es wird
  -- NICHTS umgerechnet (Spec §2: Content ist die Wahrheit, nicht Code-Magie).
  add column if not exists unit text,
  add column if not exists dialog_enabled boolean not null default false;

-- Bestand: was aktiv ist, war de facto freigegeben. Ohne diesen Backfill
-- stuende jede Bestandsaufgabe auf 'draft'. Fuer den LSA-Pool reicht das
-- allein nicht — dort ist zusaetzlich eine task_solutions-Zeile Pflicht.
update tasks set status = 'ready' where coalesce(is_active, true);

create index if not exists tasks_lsa_pool_idx
  on tasks (status, input_type, afb)
  where status = 'ready';

comment on column tasks.status is
  'Redaktions-Freigabe (draft|review|ready). Nur ready kommt in den LSA-Pool.';
comment on column tasks.competency_content is 'Inhaltliche Kompetenz (Inhaltsfeld), Lena-gepflegt.';
comment on column tasks.competency_process is 'Prozesskompetenz als Klartext; strukturiert siehe competency_id.';
comment on column tasks.dialog_enabled is
  'Ob der spaetere Fehler-Dialog bei dieser Aufgabe greift. P01 legt nur das Feld an, keine Logik.';

-- ============================================================================
-- 2. task_solutions — die Server-Only-Zone
-- ============================================================================

create table if not exists task_solutions (
  task_id        uuid primary key references tasks(id) on delete cascade,
  -- ALLE akzeptierten Varianten, explizit gepflegt: ["0,3 m","30 cm","0.3m"].
  -- Keine Einheiten-Umrechnung im Code.
  correct_answers jsonb not null default '[]'::jsonb
    check (jsonb_typeof(correct_answers) = 'array'),
  solution       text,
  -- gestufte Hinweise: [{"level":1,"text":"…"}, …]
  hints          jsonb not null default '[]'::jsonb
    check (jsonb_typeof(hints) = 'array'),
  -- bis zu 3 Zusatz-Hinweise, die der Coach live nachschicken kann
  coach_hints    jsonb not null default '[]'::jsonb
    check (jsonb_typeof(coach_hints) = 'array' and jsonb_array_length(coach_hints) <= 3),
  -- [{"error":"…","socratic_question":"…"}, …] — Feld fuer den spaeteren
  -- Fehler-Dialog. P01 baut die Logik nicht.
  typical_errors jsonb not null default '[]'::jsonb
    check (jsonb_typeof(typical_errors) = 'array'),
  updated_at     timestamptz not null default now()
);

alter table task_solutions enable row level security;

-- DAS ist die Sicherheitszusage: kein Tabellen-Tor fuer die API-Rollen.
-- (RLS ohne Policy waere schon dicht; der REVOKE macht es zusaetzlich
-- unabhaengig davon, dass jemand spaeter versehentlich eine Policy anlegt.)
revoke all on table task_solutions from anon, authenticated;
grant select, insert, update, delete on table task_solutions to service_role;

comment on table task_solutions is
  'Server-Only: Loesungen/Hinweise/typische Fehler. KEIN Grant fuer anon/authenticated. '
  'Zugriff ausschliesslich ueber die SECURITY-DEFINER-RPCs (lsa_*, task_solution_upsert).';

-- ============================================================================
-- 3. Antwort-Normalisierung — Spiegel von src/lib/answer/evaluators.ts
--    (normText, Zweig SHORT_TEXT). Bewusst identische Reihenfolge und bewusst
--    NUR das erste Komma (regexp_replace ohne 'g'), damit DB und TS dieselbe
--    Konvention haben. Keine zweite Wahrheit, keine Einheiten-Umrechnung.
-- ============================================================================

create or replace function public.lsa_normalize_answer(p_raw text)
returns text
language sql
immutable
as $$
  select case
    when p_raw is null then null
    else lower(regexp_replace(regexp_replace(btrim(p_raw), '\s+', ' ', 'g'), ',', '.'))
  end
$$;

comment on function public.lsa_normalize_answer(text) is
  'trim -> Whitespace kollabieren -> erstes Komma zu Punkt -> lowercase. '
  'Spiegelt normText() aus src/lib/answer/evaluators.ts.';

-- Auto-Bewertung gegen correct_answers. Nimmt die Loesung als Parameter
-- entgegen (liest nie selbst aus task_solutions) — dadurch leakt die Funktion
-- nichts, egal wer sie aufruft.
create or replace function public.lsa_is_correct(
  p_input_type text,
  p_correct_answers jsonb,
  p_response jsonb
)
returns boolean
language plpgsql
immutable
as $$
declare
  v_accepted text[];
  v_given    text[];
  v_answer   text;
begin
  if p_correct_answers is null
     or jsonb_typeof(p_correct_answers) <> 'array'
     or jsonb_array_length(p_correct_answers) = 0 then
    return false;
  end if;

  select array_agg(public.lsa_normalize_answer(x))
    into v_accepted
    from jsonb_array_elements_text(p_correct_answers) as t(x);

  if p_input_type = 'MC' then
    -- StudentAnswer: { selected: string[] } (Option-Ids). Mengengleichheit.
    if p_response is null or jsonb_typeof(p_response -> 'selected') <> 'array' then
      return false;
    end if;
    select array_agg(public.lsa_normalize_answer(x))
      into v_given
      from jsonb_array_elements_text(p_response -> 'selected') as t(x);
    if v_given is null then
      return false;
    end if;
    return not exists (
      select 1 from unnest(v_accepted) a where a <> all (v_given)
    ) and not exists (
      select 1 from unnest(v_given) g where g <> all (v_accepted)
    );
  end if;

  -- short_input (SHORT_TEXT: {text}, NUMERIC: {value}) — vgl. StudentAnswer.
  v_answer := coalesce(p_response ->> 'text', p_response ->> 'value');
  if v_answer is null then
    return false;
  end if;
  v_answer := public.lsa_normalize_answer(v_answer);
  if v_answer = '' then
    return false;
  end if;
  return v_answer = any (v_accepted);
end;
$$;

-- ============================================================================
-- 4. Der question_payload-Builder (Spec §1)
--
--    WHITELIST, kein Durchreichen: jedes Feld wird einzeln gebaut. tasks.
--    question_payload (Bestand) enthaelt bei alten Zeilen die Loesung im
--    kanonischen AnswerPayload — hier wird daraus AUSSCHLIESSLICH options[].id
--    und options[].label gelesen. `correct` / `accepted` kommen strukturell
--    nicht mit.
-- ============================================================================

create or replace function public.lsa_public_assets(p_assets jsonb)
returns jsonb
language sql
immutable
as $$
  select coalesce((
    select jsonb_agg(
             jsonb_strip_nulls(jsonb_build_object('url', a ->> 'url', 'alt', a ->> 'alt'))
             order by ord
           )
      from jsonb_array_elements(
             case when jsonb_typeof(p_assets) = 'array' then p_assets else '[]'::jsonb end
           ) with ordinality as e(a, ord)
     where a ->> 'url' is not null
  ), '[]'::jsonb)
$$;

-- SECURITY DEFINER, damit der Client die Funktion direkt aufrufen kann, ohne
-- dass lsa_public_assets an authenticated gegrantet werden muss. Kein
-- zusaetzliches Risiko: gelesen werden nur die oeffentlichen tasks-Spalten,
-- die authenticated ohnehin per RLS sehen darf.
create or replace function public.lsa_question_payload(p_task_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_strip_nulls(
    case
      when t.input_type = 'MC' then jsonb_build_object(
        'task_id', t.id,
        'kind',    'mc',
        'prompt',  coalesce(t.question, ''),
        'assets',  public.lsa_public_assets(t.assets),
        'options', coalesce((
          select jsonb_agg(
                   jsonb_build_object('id', o ->> 'id', 'label', o ->> 'label')
                   order by ord
                 )
            from jsonb_array_elements(
                   case
                     when jsonb_typeof(t.question_payload -> 'options') = 'array'
                       then t.question_payload -> 'options'
                     else '[]'::jsonb
                   end
                 ) with ordinality as e(o, ord)
        ), '[]'::jsonb)
      )
      else jsonb_build_object(
        'task_id', t.id,
        'kind',    'short_input',
        'prompt',  coalesce(t.question, ''),
        'assets',  public.lsa_public_assets(t.assets),
        'unit',    t.unit
      )
    end
  )
  from tasks t
  where t.id = p_task_id
$$;

comment on function public.lsa_question_payload(uuid) is
  'Baut das Client-Payload aus einer Whitelist (kind/prompt/assets/options/unit). '
  'Liefert beweisbar keine Loesungsfelder — siehe pgTAP inv2.';

-- ============================================================================
-- 5. LSA-Sessions
--
--    Bewusst NICHT screening_tests wiederverwendet: dessen result_summary hat
--    ein festes Format, das generate_parent_report liest. Eine LSA-Auswertung
--    dort hineinzuschreiben wuerde den Eltern-Report kaputtmachen.
--    student_focus_areas wird dagegen wiederverwendet (siehe lsa_confirm_focus).
-- ============================================================================

create table if not exists lsa_sessions (
  id             uuid primary key default gen_random_uuid(),
  created_at     timestamptz not null default now(),
  student_id     uuid not null references students(id) on delete cascade,
  subject        text not null,
  grade          integer not null check (grade between 5 and 13),
  status         text not null default 'in_progress'
                   check (status in ('in_progress','completed','aborted')),
  item_ids       uuid[] not null default '{}',
  started_at     timestamptz,
  completed_at   timestamptz,
  -- Auswertung aus lsa_finish. Immer ein VORSCHLAG: applied bleibt false, bis
  -- ein Coach ueber lsa_confirm_focus bestaetigt (FernUSG).
  result_summary jsonb
);

create index if not exists lsa_sessions_student_idx on lsa_sessions (student_id);
create unique index if not exists lsa_sessions_active_unique
  on lsa_sessions (student_id, subject)
  where status = 'in_progress';

alter table lsa_sessions enable row level security;

-- KEIN Schueler-SELECT: result_summary enthaelt die Auswertung (Trefferquoten).
-- Das Kind bekommt in der LSA kein Feedback (CLAUDE §6) — es sieht seine
-- Session ausschliesslich durch die RPCs, die nur die naechste Frage liefern.
create policy "lsa_sessions_coach_admin_all" on lsa_sessions
  for all
  using (public.get_my_role() in ('coach','admin'))
  with check (public.get_my_role() in ('coach','admin'));
create policy "lsa_sessions_parent_read" on lsa_sessions
  for select using (public.is_parent_of_student(student_id));

-- Append-only, analog behavior_snapshots.
create table if not exists lsa_responses (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  session_id  uuid not null references lsa_sessions(id) on delete cascade,
  task_id     uuid not null references tasks(id) on delete cascade,
  response    jsonb,
  correct     boolean,
  duration_ms integer,
  constraint lsa_responses_once_per_item unique (session_id, task_id)
);

create index if not exists lsa_responses_session_idx on lsa_responses (session_id);

alter table lsa_responses enable row level security;

-- Ebenfalls kein Schueler-SELECT: die Zeile enthaelt `correct`.
-- Kein update-, kein delete-Policy → append-only.
create policy "lsa_responses_coach_admin_read" on lsa_responses
  for select using (public.get_my_role() in ('coach','admin'));
create policy "lsa_responses_parent_read" on lsa_responses
  for select using (
    session_id in (
      select id from lsa_sessions where public.is_parent_of_student(student_id)
    )
  );

-- ============================================================================
-- 6. Die RPCs
-- ============================================================================

-- Interner Autorisierungs-Helfer: darf der Aufrufer fuer diesen Schueler
-- handeln? (Der Schueler selbst, oder Coach/Admin.)
create or replace function public.lsa_may_act_for(p_student_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.get_my_role() in ('coach','admin')
      or public.get_my_student_id() = p_student_id
$$;

-- --- lsa_start ---------------------------------------------------------------
-- Waehlt aus dem Lena-freigegebenen Pool (status='ready' + task_solutions mit
-- mindestens einer akzeptierten Antwort), zielt auf ~20 Minuten und mischt
-- ueber AFB × Kompetenzfeld.
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
  -- Der Unique-Index wuerde das ohnehin abfangen, aber mit einer 23505, die im
  -- Frontend nichts erklaert.
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
           coalesce(t.est_duration_sec, t.estimated_minutes * 60, 180) as secs
      from tasks t
      join task_solutions s on s.task_id = t.id
      join skill_clusters c on c.id = t.cluster_id
      join subjects sub     on sub.id = c.subject_id
     where t.status = 'ready'
       and coalesce(t.is_active, true)
       and t.input_type in ('MC','SHORT_TEXT','NUMERIC')
       and jsonb_array_length(s.correct_answers) > 0
       and sub.name = p_subject
       and coalesce(t.class_level, p_grade) <= p_grade
  ),
  -- Round-Robin ueber (AFB × Kompetenzfeld): erst je eines aus jeder Gruppe,
  -- dann das zweite usw. So ist die Mischung auch bei kurzem Test gegeben.
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
   -- alles aufnehmen, was VOR Erreichen der 20 Minuten beginnt: ~1200 s
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

-- --- lsa_submit --------------------------------------------------------------
-- Bewertet SERVER-SEITIG und gibt dem Kind KEIN Richtig/Falsch zurueck.
-- Die LSA ist eine Diagnose, kein Uebungsmodus.
create or replace function public.lsa_submit(
  p_session_id  uuid,
  p_task_id     uuid,
  p_response    jsonb,
  p_duration_ms integer default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session    lsa_sessions;
  v_input_type text;
  v_correct    boolean;
  v_next       uuid;
begin
  select * into v_session from lsa_sessions where id = p_session_id;
  if not found then
    raise exception 'LSA: Session nicht gefunden' using errcode = 'P0002';
  end if;
  if not public.lsa_may_act_for(v_session.student_id) then
    raise exception 'LSA: kein Zugriff auf diese Session' using errcode = '42501';
  end if;
  if v_session.status <> 'in_progress' then
    raise exception 'LSA: Session ist nicht aktiv' using errcode = 'P0001';
  end if;
  if not (p_task_id = any (v_session.item_ids)) then
    raise exception 'LSA: Item gehoert nicht zu dieser Session' using errcode = 'P0001';
  end if;

  select t.input_type into v_input_type from tasks t where t.id = p_task_id;

  select public.lsa_is_correct(v_input_type, s.correct_answers, p_response)
    into v_correct
    from task_solutions s
   where s.task_id = p_task_id;

  insert into lsa_responses (session_id, task_id, response, correct, duration_ms)
  values (p_session_id, p_task_id, p_response, coalesce(v_correct, false), p_duration_ms)
  on conflict on constraint lsa_responses_once_per_item do nothing;

  select i.id
    into v_next
    from unnest(v_session.item_ids) with ordinality as i(id, ord)
   where not exists (
           select 1 from lsa_responses r
            where r.session_id = v_session.id and r.task_id = i.id
         )
   order by i.ord
   limit 1;

  -- Bewusst nur ok + naechste Frage. Kein `correct`, kein Score, kein Hinweis
  -- auf die Loesung.
  return jsonb_build_object(
    'ok',   true,
    'next', case when v_next is null then null
                 else public.lsa_question_payload(v_next) end
  );
end;
$$;

-- --- lsa_hint ----------------------------------------------------------------
-- Hinweise kommen EINZELN auf Anfrage (Spec §1) — nie vorab im Payload, sonst
-- liest das Kind sie im Netzwerk-Tab.
create or replace function public.lsa_hint(
  p_session_id uuid,
  p_task_id    uuid,
  p_level      integer default 1
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session lsa_sessions;
  v_hint    jsonb;
begin
  select * into v_session from lsa_sessions where id = p_session_id;
  if not found then
    raise exception 'LSA: Session nicht gefunden' using errcode = 'P0002';
  end if;
  if not public.lsa_may_act_for(v_session.student_id) then
    raise exception 'LSA: kein Zugriff auf diese Session' using errcode = '42501';
  end if;
  if not (p_task_id = any (v_session.item_ids)) then
    raise exception 'LSA: Item gehoert nicht zu dieser Session' using errcode = 'P0001';
  end if;

  select h
    into v_hint
    from task_solutions s,
         lateral jsonb_array_elements(s.hints) as e(h)
   where s.task_id = p_task_id
     and (h ->> 'level')::int = p_level
   limit 1;

  if v_hint is null then
    return jsonb_build_object('level', p_level, 'text', null, 'available', false);
  end if;

  return jsonb_build_object(
    'level',     p_level,
    'text',      v_hint ->> 'text',
    'available', true
  );
end;
$$;

-- --- lsa_finish --------------------------------------------------------------
-- Wertet aus und erzeugt einen VORSCHLAG. Schreibt KEINEN Lernpfad, KEIN
-- student_focus_areas, KEIN mastered. Das ist die FernUSG-Leitplanke.
create or replace function public.lsa_finish(p_session_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session lsa_sessions;
  v_summary jsonb;
begin
  select * into v_session from lsa_sessions where id = p_session_id;
  if not found then
    raise exception 'LSA: Session nicht gefunden' using errcode = 'P0002';
  end if;
  if not public.lsa_may_act_for(v_session.student_id) then
    raise exception 'LSA: kein Zugriff auf diese Session' using errcode = '42501';
  end if;
  -- Idempotent: eine bereits ausgewertete Session wird NICHT neu berechnet.
  -- Sonst wuerde ein zweiter Aufruf nach der Coach-Bestaetigung das
  -- proposal.applied=true wieder auf false zuruecksetzen — der Lernpfad waere
  -- geschrieben, die Session behauptete das Gegenteil.
  if v_session.status = 'completed' then
    return v_session.result_summary;
  end if;

  with answered as (
    select r.correct,
           r.duration_ms,
           coalesce(t.competency_content, '?') as competency,
           coalesce(t.afb, 'II')               as afb,
           t.cluster_id
      from lsa_responses r
      join tasks t on t.id = r.task_id
     where r.session_id = p_session_id
  ),
  by_competency as (
    select competency,
           count(*)                                          as total,
           count(*) filter (where correct)                   as correct_count,
           round(avg(duration_ms)::numeric, 0)               as avg_duration_ms,
           round(
             count(*) filter (where correct)::numeric / nullif(count(*), 0), 2
           )                                                 as hit_rate
      from answered
     group by competency
  ),
  by_afb as (
    select afb,
           count(*)                        as total,
           count(*) filter (where correct) as correct_count
      from answered
     group by afb
  ),
  -- Vorschlag: die Cluster, in denen weniger als 60 % sitzen. Reiner
  -- Vorschlag — er wird hier NICHT angewendet.
  weak_clusters as (
    select cluster_id,
           round(
             count(*) filter (where correct)::numeric / nullif(count(*), 0), 2
           ) as hit_rate
      from answered
     where cluster_id is not null
     group by cluster_id
    having count(*) filter (where correct)::numeric / nullif(count(*), 0) < 0.6
  )
  select jsonb_build_object(
           'answered',    (select count(*) from answered),
           'planned',     array_length(v_session.item_ids, 1),
           'competencies', coalesce((
             select jsonb_agg(jsonb_build_object(
                      'competency',      competency,
                      'total',           total,
                      'correct',         correct_count,
                      'hit_rate',        hit_rate,
                      'avg_duration_ms', avg_duration_ms
                    ) order by hit_rate nulls first)
               from by_competency), '[]'::jsonb),
           'afb', coalesce((
             select jsonb_agg(jsonb_build_object(
                      'afb', afb, 'total', total, 'correct', correct_count
                    ) order by afb)
               from by_afb), '[]'::jsonb),
           'proposal', jsonb_build_object(
             -- ausdrueckliche Selbstbeschreibung: das hier ist NICHTS Gesetztes.
             'is_proposal', true,
             'applied',     false,
             'focus_cluster_ids', coalesce((
               select jsonb_agg(cluster_id order by hit_rate) from weak_clusters
             ), '[]'::jsonb),
             'clusters', coalesce((
               select jsonb_agg(jsonb_build_object(
                        'cluster_id', w.cluster_id,
                        'name',       c.name,
                        'hit_rate',   w.hit_rate
                      ) order by w.hit_rate)
                 from weak_clusters w
                 join skill_clusters c on c.id = w.cluster_id
             ), '[]'::jsonb),
             'note', 'Vorschlag. Der Lernpfad wird erst durch die Coach-Bestaetigung aktiv (lsa_confirm_focus).'
           )
         )
    into v_summary;

  update lsa_sessions
     set status         = 'completed',
         completed_at   = now(),
         result_summary = v_summary
   where id = p_session_id;

  return v_summary;
end;
$$;

-- --- lsa_confirm_focus -------------------------------------------------------
-- Der eigene Schritt, der aus dem Vorschlag Realitaet macht. NUR Coach/Admin.
-- Schreibt in student_focus_areas (bestehende Tabelle — nichts doppelt gebaut).
create or replace function public.lsa_confirm_focus(
  p_session_id  uuid,
  p_cluster_ids uuid[] default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session  lsa_sessions;
  v_clusters uuid[];
  v_written  integer := 0;
begin
  if public.get_my_role() not in ('coach','admin') then
    raise exception 'LSA: Lernpfad-Freigabe nur durch Coach (FernUSG)' using errcode = '42501';
  end if;

  select * into v_session from lsa_sessions where id = p_session_id;
  if not found then
    raise exception 'LSA: Session nicht gefunden' using errcode = 'P0002';
  end if;
  if v_session.status <> 'completed' then
    raise exception 'LSA: Session ist noch nicht ausgewertet' using errcode = 'P0001';
  end if;

  v_clusters := coalesce(
    p_cluster_ids,
    (select array_agg((x)::uuid)
       from jsonb_array_elements_text(
              coalesce(v_session.result_summary -> 'proposal' -> 'focus_cluster_ids',
                       '[]'::jsonb)
            ) as t(x))
  );

  if v_clusters is null or array_length(v_clusters, 1) is null then
    return jsonb_build_object('applied', true, 'focus_areas_written', 0);
  end if;

  insert into student_focus_areas (student_id, cluster_id, coach_id, source, note)
  select v_session.student_id, c, auth.uid(), 'lsa',
         'Aus LSA-Vorschlag bestaetigt (' || p_session_id::text || ')'
    from unnest(v_clusters) as c
   where not exists (
           select 1 from student_focus_areas f
            where f.student_id = v_session.student_id
              and f.cluster_id = c
              and f.active
         );
  get diagnostics v_written = row_count;

  update lsa_sessions
     set result_summary = jsonb_set(
           result_summary,
           '{proposal,applied}',
           'true'::jsonb,
           true
         )
   where id = p_session_id;

  return jsonb_build_object('applied', true, 'focus_areas_written', v_written);
end;
$$;

-- --- task_solution_upsert ----------------------------------------------------
-- Lenas Schreibpfad in die Server-Only-Zone. Ohne diese RPC koennte selbst ein
-- Admin task_solutions nicht befuellen (kein Grant) — ausser ueber service_role
-- (Seed-Skripte).
create or replace function public.task_solution_upsert(
  p_task_id        uuid,
  p_correct_answers jsonb default '[]'::jsonb,
  p_solution       text  default null,
  p_hints          jsonb default '[]'::jsonb,
  p_coach_hints    jsonb default '[]'::jsonb,
  p_typical_errors jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'task_solution_upsert: nur Admin' using errcode = '42501';
  end if;
  if not exists (select 1 from tasks where id = p_task_id) then
    raise exception 'task_solution_upsert: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;

  insert into task_solutions as s
    (task_id, correct_answers, solution, hints, coach_hints, typical_errors, updated_at)
  values
    (p_task_id, p_correct_answers, p_solution, p_hints, p_coach_hints, p_typical_errors, now())
  on conflict (task_id) do update
     set correct_answers = excluded.correct_answers,
         solution        = excluded.solution,
         hints           = excluded.hints,
         coach_hints     = excluded.coach_hints,
         typical_errors  = excluded.typical_errors,
         updated_at      = now();

  return jsonb_build_object('ok', true, 'task_id', p_task_id);
end;
$$;

-- ============================================================================
-- 7. Execute-Grants
--    Postgres gibt neuen Funktionen automatisch EXECUTE an PUBLIC — das waere
--    auch anon. Also erst wegnehmen, dann gezielt geben.
-- ============================================================================

revoke execute on function public.lsa_is_correct(text, jsonb, jsonb)   from public;
revoke execute on function public.lsa_may_act_for(uuid)                from public;
revoke execute on function public.lsa_start(uuid, integer, text)       from public;
revoke execute on function public.lsa_submit(uuid, uuid, jsonb, integer) from public;
revoke execute on function public.lsa_hint(uuid, uuid, integer)        from public;
revoke execute on function public.lsa_finish(uuid)                     from public;
revoke execute on function public.lsa_confirm_focus(uuid, uuid[])      from public;
revoke execute on function public.task_solution_upsert(uuid, jsonb, text, jsonb, jsonb, jsonb) from public;
revoke execute on function public.lsa_question_payload(uuid)           from public;
revoke execute on function public.lsa_public_assets(jsonb)             from public;
revoke execute on function public.lsa_normalize_answer(text)           from public;

grant execute on function public.lsa_start(uuid, integer, text)          to authenticated, service_role;
grant execute on function public.lsa_submit(uuid, uuid, jsonb, integer)  to authenticated, service_role;
grant execute on function public.lsa_hint(uuid, uuid, integer)           to authenticated, service_role;
grant execute on function public.lsa_finish(uuid)                        to authenticated, service_role;
grant execute on function public.lsa_confirm_focus(uuid, uuid[])         to authenticated, service_role;
grant execute on function public.task_solution_upsert(uuid, jsonb, text, jsonb, jsonb, jsonb)
  to authenticated, service_role;
grant execute on function public.lsa_question_payload(uuid)              to authenticated, service_role;

-- lsa_is_correct / lsa_public_assets / lsa_normalize_answer / lsa_may_act_for
-- sind interne Helfer. Sie werden INNERHALB der SECURITY-DEFINER-RPCs
-- aufgerufen und laufen dort mit den Rechten des Owners — ein Grant an
-- authenticated ist unnoetig.
grant execute on function public.lsa_is_correct(text, jsonb, jsonb) to service_role;
grant execute on function public.lsa_normalize_answer(text)         to service_role;
grant execute on function public.lsa_public_assets(jsonb)           to service_role;
grant execute on function public.lsa_may_act_for(uuid)              to service_role;

commit;
