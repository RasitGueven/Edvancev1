-- ============================================================================
-- S7 (Lead→LSA): Provisorisches Schülerkonto pro Lead (A1 Option 1, freigegeben)
-- + Intake-Felder für das Erstgespräch (Teil B).
--
-- Grundlage: docs/specs/A1-analyse.md — Option 1. Der P01-Datenvertrag bleibt
-- byte-identisch: KEIN Eingriff in lsa_start/lsa_submit/lsa_finish/
-- lsa_question_payload, kein lsa_sessions/lsa_responses-Schema-Umbau, keine
-- RLS-Änderung an den LSA-Tabellen. Alles hier ist ADDITIV:
--
--   A1. students.is_provisional + students.lead_id (Löschanker, on delete cascade)
--   A2. lead_lsa_freigeben(p_lead_id, p_grade, p_subject) — nur Admin:
--       legt idempotent den provisorischen Schüler an und startet die LSA über
--       das UNVERÄNDERTE public.lsa_start (kein Duplikat der Kernlogik).
--   A3. lead_delete: der TODO-Block aus A2 (S5) ist hiermit eingelöst — die
--       FK-Kaskade leads → students(lead_id) → lsa_sessions → lsa_responses
--       räumt die LSA-Daten mit ab. Funktionslogik unverändert, Doku aktualisiert.
--   A4. lead_convert(p_lead_id) — nur Admin: Datensatz-Flip (is_provisional=false,
--       lead_id=null, leads.status='converted', converted_student_id). Das echte
--       Auth-Konto ist NICHT Teil dieses Laufs.
--   A5. Guards (Leitplanken aus der A1-Analyse):
--       - Einziger Erzeuger provisorischer Zeilen ist lead_lsa_freigeben
--         (GUC-Schleuse edvance.allow_provisional).
--       - Ein provisorischer Schüler trägt NIE ein Abo (Trigger auf
--         student_subscriptions).
--       - is_provisional ⇔ lead_id gesetzt (CHECK) + genau ein provisorischer
--         Schüler pro Lead (Unique).
--   A6. leads.status um 'lsa_freigegeben' und 'lsa_fertig' erweitert; ein
--       AFTER-UPDATE-Trigger auf lsa_sessions setzt 'lsa_fertig', wenn die
--       Session eines provisorischen Schülers abgeschlossen wird (lsa_finish
--       selbst bleibt unangetastet).
--
--   B.  Intake-Felder am Lead (Fragenkatalog der Gründerrunde) inkl.
--       DSGVO-Einwilligung — lead_lsa_freigeben verweigert ohne consent_dsgvo_at.
--       BEWUSST KEINE Diagnose-Felder (ADHS etc. wird nicht erfasst).
--       + lead_assessment_upsert (coach/admin) als sauberer Schreibweg für
--       lead_assessments. Die A3-Invariante bleibt: lsa_start liest das nie.
--
-- Hinweis „Name aus dem Lead": students trägt keine Namensspalte (Namen leben
-- in profiles bzw. leads). Der provisorische Schüler erreicht seinen Rufnamen
-- über lead_id → leads.first_name/full_name — keine Duplizierung, ein Löschort.
-- ============================================================================

begin;

-- ============================================================================
-- A1. students: Herkunfts-Markierung + Löschanker
-- ============================================================================

alter table students
  add column if not exists is_provisional boolean not null default false;
alter table students
  add column if not exists lead_id uuid references leads(id) on delete cascade;

comment on column students.is_provisional is
  'Provisorischer Schülerdatensatz eines Leads (A1 Option 1): profile_id NULL, '
  'kein Auth-Konto, kein Abo. Zählt NIRGENDS als Schüler — jedes Aggregat '
  'filtert is_provisional=false. Erzeugt ausschließlich durch lead_lsa_freigeben.';
comment on column students.lead_id is
  'Löschanker des provisorischen Schülers: on delete cascade — lead_delete räumt '
  'über leads → students → lsa_sessions → lsa_responses restlos ab (DSGVO). '
  'Bei Konversion (lead_convert) wird lead_id genullt, damit eine spätere '
  'Lead-Löschung nie einen echten Schüler kaskadiert.';

-- Provisorisch ⇔ am Lead verankert — nie das eine ohne das andere.
alter table students drop constraint if exists students_provisional_lead_ck;
alter table students add constraint students_provisional_lead_ck
  check (is_provisional = (lead_id is not null));

-- Genau ein provisorischer Schüler pro Lead (Idempotenz-Anker für
-- lead_lsa_freigeben).
create unique index if not exists students_lead_unique
  on students (lead_id) where lead_id is not null;

-- ============================================================================
-- A6a. leads.status: bestehende Werte behalten, LSA-Stationen ergänzen
-- ============================================================================

alter table leads drop constraint if exists leads_status_check;
alter table leads add constraint leads_status_check check (
  status in ('new','contacted','onboarding_scheduled','converted','rejected',
             'lsa_freigegeben','lsa_fertig')
);

-- ============================================================================
-- B. Intake-Felder (Erstgespräch) — Fragenkatalog der Gründerrunde.
--    Bewusst KEINE Diagnose-Felder.
-- ============================================================================

alter table leads
  add column if not exists first_name       text,
  add column if not exists birth_date       date,
  add column if not exists last_grade       text,
  add column if not exists grade_trend      text,
  add column if not exists struggling_since text,
  add column if not exists tried_before     text[],
  add column if not exists next_exam_date   date,
  add column if not exists next_exam_topic  text,
  add column if not exists consent_dsgvo_at timestamptz,
  add column if not exists consent_dsgvo_by uuid references profiles(id) on delete set null;

alter table leads drop constraint if exists leads_grade_trend_check;
alter table leads add constraint leads_grade_trend_check
  check (grade_trend is null or grade_trend in ('besser','stabil','schlechter'));

alter table leads drop constraint if exists leads_struggling_since_check;
alter table leads add constraint leads_struggling_since_check
  check (struggling_since is null
         or struggling_since in ('dieses_halbjahr','letztes_schuljahr','laenger'));

comment on column leads.first_name is
  'Der Rufname des Kindes — erscheint auf dem Tablet als „Hi <Name>", muss exakt '
  'stimmen. full_name bleibt der volle Name.';
comment on column leads.last_grade is
  'Letzte Zeugnisnote im Fach (Freitext, z.B. „4+").';
comment on column leads.tried_before is
  'Was schon versucht wurde (z.B. nachhilfe, lernvideos, elternhilfe, nichts). '
  'Offene Liste, bewusst ohne CHECK.';
comment on column leads.consent_dsgvo_at is
  'DSGVO-Einwilligung der Eltern — PFLICHT vor der LSA-Freigabe: '
  'lead_lsa_freigeben verweigert, wenn dieses Feld null ist.';

-- ============================================================================
-- A5a. Guard: provisorische Zeilen entstehen NUR über lead_lsa_freigeben.
--      Die RPC öffnet die Schleuse per transaktionslokalem GUC; jeder direkte
--      INSERT/UPDATE mit is_provisional=true wird abgewiesen — auch von Admins.
-- ============================================================================

create or replace function public.students_guard_provisional()
returns trigger
language plpgsql
as $$
begin
  if new.is_provisional
     and (tg_op = 'INSERT' or old.is_provisional is distinct from new.is_provisional)
     and coalesce(current_setting('edvance.allow_provisional', true), '') <> '1'
  then
    raise exception
      'students: provisorische Zeilen entstehen nur ueber lead_lsa_freigeben'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists students_guard_provisional_trg on students;
create trigger students_guard_provisional_trg
  before insert or update of is_provisional on students
  for each row execute function public.students_guard_provisional();

-- ============================================================================
-- A5b. Guard: ein provisorischer Schüler trägt NIE ein Abo/Vertrag.
--      (Erst lead_convert flippt is_provisional=false — danach ist das Abo frei.)
-- ============================================================================

create or replace function public.subscriptions_guard_provisional()
returns trigger
language plpgsql
as $$
begin
  if exists (select 1 from students where id = new.student_id and is_provisional) then
    raise exception
      'student_subscriptions: provisorischer Schueler traegt kein Abo (erst lead_convert)'
      using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists subscriptions_guard_provisional_trg on student_subscriptions;
create trigger subscriptions_guard_provisional_trg
  before insert or update of student_id on student_subscriptions
  for each row execute function public.subscriptions_guard_provisional();

-- ============================================================================
-- A6b. 'lsa_fertig': wenn die LSA-Session eines PROVISORISCHEN Schülers
--      abgeschlossen wird, rückt sein Lead vor. Additiver Trigger —
--      lsa_finish selbst bleibt byte-identisch (Datenvertrag unberührt).
--      Für echte Schüler (is_provisional=false) ist das ein No-op.
-- ============================================================================

create or replace function public.lsa_session_lead_fertig()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update leads l
     set status = 'lsa_fertig'
    from students s
   where s.id = new.student_id
     and s.is_provisional
     and l.id = s.lead_id
     and l.status = 'lsa_freigegeben';
  return new;
end;
$$;

drop trigger if exists lsa_session_lead_fertig_trg on lsa_sessions;
create trigger lsa_session_lead_fertig_trg
  after update of status on lsa_sessions
  for each row
  when (new.status = 'completed' and old.status is distinct from new.status)
  execute function public.lsa_session_lead_fertig();

-- ============================================================================
-- A2. lead_lsa_freigeben — nur Admin. Idempotent im Schüler-Teil; die Session
--     startet über das UNVERÄNDERTE public.lsa_start (läuft bereits eine
--     in_progress-Session für das Fach, propagiert dessen P0001).
-- ============================================================================

create or replace function public.lead_lsa_freigeben(
  p_lead_id uuid,
  p_grade   integer,
  p_subject text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_lead       leads%rowtype;
  v_student_id uuid;
  v_result     jsonb;
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'lead_lsa_freigeben: nur Admin' using errcode = '42501';
  end if;

  select * into v_lead from leads where id = p_lead_id;
  if not found then
    raise exception 'lead_lsa_freigeben: Lead nicht gefunden' using errcode = 'P0002';
  end if;

  if v_lead.status = 'converted' then
    raise exception 'lead_lsa_freigeben: Lead ist bereits konvertiert'
      using errcode = 'P0001';
  end if;

  -- DSGVO-Gate: ohne dokumentierte Einwilligung keine Freigabe.
  if v_lead.consent_dsgvo_at is null then
    raise exception
      'lead_lsa_freigeben: DSGVO-Einwilligung fehlt (consent_dsgvo_at ist null)'
      using errcode = 'P0001';
  end if;

  -- Provisorischen Schüler idempotent anlegen (Unique students_lead_unique).
  -- Name bleibt am Lead (first_name/full_name) — erreichbar über lead_id.
  select id into v_student_id from students where lead_id = p_lead_id;
  if v_student_id is null then
    perform set_config('edvance.allow_provisional', '1', true);
    insert into students (profile_id, class_level, school_name, school_type,
                          is_provisional, lead_id)
    values (null, coalesce(v_lead.class_level, p_grade), v_lead.school_name,
            v_lead.school_type, true, p_lead_id)
    returning id into v_student_id;
    perform set_config('edvance.allow_provisional', '', true);
  end if;

  -- Die BESTEHENDE lsa_start-Logik — kein Duplikat. Der Aufrufer ist Admin,
  -- lsa_may_act_for lässt ihn für jeden Schüler handeln.
  v_result := public.lsa_start(v_student_id, p_grade, p_subject);

  update leads set status = 'lsa_freigegeben' where id = p_lead_id;

  return jsonb_build_object(
    'session_id',  v_result -> 'session_id',
    'student_id',  to_jsonb(v_student_id),
    'total_items', v_result -> 'total_items'
  );
end;
$$;

comment on function public.lead_lsa_freigeben(uuid, integer, text) is
  'LSA-Freigabe für einen Lead (A1 Option 1). Nur Admin. Verweigert ohne '
  'DSGVO-Einwilligung. Legt idempotent den provisorischen Schüler an '
  '(profile_id NULL, is_provisional, lead_id) und startet die Session über das '
  'unveränderte lsa_start. Setzt leads.status=lsa_freigegeben.';

-- ============================================================================
-- A4. lead_convert — nur Admin. Der Datensatz-Flip: der provisorische Schüler
--     WIRD der echte (Sessions hängen schon richtig, nichts wandert).
--     Auth-Konto/profile_id ist bewusst NICHT Teil dieses Laufs.
-- ============================================================================

create or replace function public.lead_convert(p_lead_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_lead       leads%rowtype;
  v_student_id uuid;
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'lead_convert: nur Admin' using errcode = '42501';
  end if;

  select * into v_lead from leads where id = p_lead_id;
  if not found then
    raise exception 'lead_convert: Lead nicht gefunden' using errcode = 'P0002';
  end if;

  if v_lead.status = 'converted' then
    raise exception 'lead_convert: Lead ist bereits konvertiert'
      using errcode = 'P0001';
  end if;

  select id into v_student_id
    from students where lead_id = p_lead_id and is_provisional;
  if v_student_id is null then
    raise exception 'lead_convert: kein provisorischer Schueler zu diesem Lead'
      using errcode = 'P0002';
  end if;

  -- lead_id nullen: eine spätere Lead-Löschung darf NIE den echten Schüler
  -- kaskadieren. Die Verbindung hält ab jetzt leads.converted_student_id.
  update students
     set is_provisional = false, lead_id = null
   where id = v_student_id;

  update leads
     set status = 'converted', converted_student_id = v_student_id
   where id = p_lead_id;

  return jsonb_build_object('ok', true, 'student_id', v_student_id);
end;
$$;

comment on function public.lead_convert(uuid) is
  'Konversion Lead → Schüler (Datensatz-Flip, A1 Option 1). Nur Admin. Setzt '
  'is_provisional=false + lead_id=null am Schüler, leads.status=converted + '
  'converted_student_id. Das Anlegen des Auth-Kontos (profile_id) folgt separat.';

-- ============================================================================
-- A3. lead_delete — der TODO-Block aus A2 (S5) ist eingelöst. Die Logik ist
--     unverändert: das delete from leads kaskadiert jetzt zusätzlich über
--     students(lead_id) → lsa_sessions(student_id) → lsa_responses. Ein
--     konvertierter Lead fällt weiterhin NICHT über diesen Weg — und sein
--     Schüler hängt nach lead_convert ohnehin nicht mehr an lead_id.
-- ============================================================================

create or replace function public.lead_delete(p_lead_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_lead leads%rowtype;
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'lead_delete: nur Admin' using errcode = '42501';
  end if;

  select * into v_lead from leads where id = p_lead_id;
  if not found then
    raise exception 'lead_delete: Lead nicht gefunden' using errcode = 'P0002';
  end if;

  -- Aufbewahrungspflicht: ein konvertierter Lead wird nicht über diesen Weg
  -- gelöscht.
  if v_lead.status = 'converted' then
    raise exception 'lead_delete: konvertierter Lead — Aufbewahrungspflicht'
      using errcode = 'P0001';
  end if;

  -- Kaskade (S7): leads → lead_assessments (A3) UND
  -- leads → students(lead_id) → lsa_sessions → lsa_responses (A1 Option 1).
  -- Der provisorische Schüler und seine LSA-Daten fallen restlos mit.
  delete from leads where id = p_lead_id;

  return jsonb_build_object('ok', true, 'lead_id', p_lead_id);
end;
$$;

comment on function public.lead_delete(uuid) is
  'DSGVO-Vollständige Löschung eines Leads. Nur Admin. Entfernt Lead + '
  'lead_assessments + provisorischen Schüler + dessen LSA-Sessions/-Responses '
  '(FK-Kaskaden). Verweigert bei status=converted (Aufbewahrungspflicht).';

-- ============================================================================
-- B. lead_assessment_upsert — der saubere Schreibweg für lead_assessments.
--    coach/admin. Upsert auf (lead_id, source). Die A3-Invariante bleibt:
--    lsa_start liest lead_assessments NIE (Regression in s7-pgTAP + inv_a3).
-- ============================================================================

create or replace function public.lead_assessment_upsert(
  p_lead_id     uuid,
  p_source      text,
  p_note        text,
  p_weak_topics text[]
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  if public.get_my_role() not in ('coach','admin') then
    raise exception 'lead_assessment_upsert: nur Coach/Admin' using errcode = '42501';
  end if;

  if p_source not in ('parent','child') then
    raise exception 'lead_assessment_upsert: source muss parent oder child sein'
      using errcode = '23514';
  end if;

  if not exists (select 1 from leads where id = p_lead_id) then
    raise exception 'lead_assessment_upsert: Lead nicht gefunden' using errcode = 'P0002';
  end if;

  insert into lead_assessments (lead_id, source, note, weak_topics)
  values (p_lead_id, p_source, p_note, coalesce(p_weak_topics, '{}'))
  on conflict (lead_id, source) do update
     set note = excluded.note, weak_topics = excluded.weak_topics
  returning id into v_id;

  return jsonb_build_object('ok', true, 'assessment_id', v_id);
end;
$$;

comment on function public.lead_assessment_upsert(uuid, text, text, text[]) is
  'Upsert der Eltern-/Kind-Einschätzung eines Leads auf (lead_id, source). '
  'Coach/Admin. Reveal-Metadatum — NIE Input für lsa_start (A3-Invariante).';

-- ============================================================================
-- Grants (Postgres grantet neuen Funktionen automatisch an PUBLIC — erst
-- wegnehmen, dann gezielt geben; analog P01 §7 / a01 §4 / a02).
-- Die Trigger-Funktionen laufen nur als Trigger und brauchen kein Grant.
-- ============================================================================

revoke execute on function public.lead_lsa_freigeben(uuid, integer, text)      from public;
revoke execute on function public.lead_convert(uuid)                           from public;
revoke execute on function public.lead_assessment_upsert(uuid, text, text, text[]) from public;
revoke execute on function public.students_guard_provisional()                 from public;
revoke execute on function public.subscriptions_guard_provisional()            from public;
revoke execute on function public.lsa_session_lead_fertig()                    from public;

grant execute on function public.lead_lsa_freigeben(uuid, integer, text) to authenticated, service_role;
grant execute on function public.lead_convert(uuid)                      to authenticated, service_role;
grant execute on function public.lead_assessment_upsert(uuid, text, text, text[]) to authenticated, service_role;

commit;
