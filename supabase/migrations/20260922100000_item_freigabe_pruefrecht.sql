-- Item-Freigabe: Pruefrecht je Person, zweistufige Freigabe, Rueckweisungsgrund.
--
-- KEIN begin/commit (der Runner klammert; beim Hand-Apply --single-transaction).
--
-- Ausgangslage (gemessen 22.09.2026): Freigabe, Beanstandung, Feldpflege und
-- Loesungspflege waren ausschliesslich admin. Die Pruef-Strecke fuer Coaches
-- ("Als geprueft markieren") scheiterte an task_status_set — ein Coach konnte
-- in der Item-Pflege nichts schreiben.
--
-- Entscheidung (Anforderung Item-Pflege, 13.09. + Klaerung 22.09.):
--   * Pruefen ist ein Recht einer PERSON, nicht der Coach-Rolle. Sonst bekaeme
--     jeder kuenftige Coach, der Kinder betreut, Schreibzugriff auf den
--     Aufgabenbestand. -> profiles.darf_pruefen.
--   * Zwei Stufen: Pruefer setzen 'review' ("Zur Freigabe") oder 'beanstandet',
--     admin hebt 'review' auf 'ready'. Alles, was 'ready' beruehrt (freigeben,
--     zuruecknehmen, eine freigegebene Aufgabe beanstanden), bleibt admin.
--   * 'review' verlangt dieselben Pflichtfelder wie 'ready' — "Zur Freigabe"
--     heisst: aus Pruefersicht fertig.
--   * Rueckweisungsgrund 'loesung_passt_nicht' kommt zu den sechs A20-Kategorien.
--   * freigabe_cluster: admin hebt alle 'review'-Aufgaben eines Clusters.


-- ── 1. Pruefrecht je Person ─────────────────────────────────────────────────
--
-- Gesetzt wird es von Hand (SQL-Editor). profiles hat keine UPDATE-Policy fuer
-- authenticated — niemand kann sich das Recht selbst geben.

alter table public.profiles
  add column if not exists darf_pruefen boolean not null default false;

comment on column public.profiles.darf_pruefen is
  'Darf Aufgaben der Item-Pflege einordnen, korrigieren, beanstanden und auf '
  '"Zur Freigabe" (review) setzen. Freigeben (ready) bleibt admin. Fuer admin '
  'ohne Bedeutung (admin darf immer).';

create or replace function public.darf_pruefen()
returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(
    (select p.role = 'admin' or (p.role = 'coach' and p.darf_pruefen)
       from public.profiles p where p.id = auth.uid()),
    false)
$$;

-- Content-Pfade ohne Login: Importe mit service_role-Key (scripts/import-*.ts)
-- und SQL direkt als postgres (Content-Migrationen, SQL-Editor). Bisher kamen
-- sie nur durch die NULL-Falle von `get_my_role() <> 'admin'` durch — jetzt
-- ausdruecklich. PostgREST setzt die JWT-Rolle bei JEDEM API-Aufruf (auch
-- 'anon'); ohne JWT-Kontext (auth.role() null) ist es eine direkte
-- DB-Verbindung — die hat ohnehin Owner-Rechte.
create or replace function public.ist_systemaufruf()
returns boolean
language sql stable set search_path = public as $$
  select coalesce(auth.role(), 'service_role') = 'service_role'
$$;

revoke all on function public.darf_pruefen() from public, anon;
grant execute on function public.darf_pruefen() to authenticated;
revoke all on function public.ist_systemaufruf() from public, anon;
grant execute on function public.ist_systemaufruf() to authenticated, service_role;


-- ── 2. Schreibrecht auf tasks fuer Pruefer ──────────────────────────────────
--
-- Nur UPDATE — anlegen und loeschen bleiben admin (admin_write_tasks).

drop policy if exists pruefer_update_tasks on public.tasks;
create policy pruefer_update_tasks on public.tasks
  for update to authenticated
  using (public.darf_pruefen()) with check (public.darf_pruefen());

-- Das direkte UPDATE umginge sonst das Gate: status und der Freigabe-Stempel
-- laufen fuer Nicht-Admins ausschliesslich ueber task_status_set /
-- lena_beanstande. Und eine freigegebene Aufgabe aendert nur admin — sonst
-- aendert sich unter einer Freigabe der Inhalt, den admin freigegeben hat.
-- current_user = 'authenticated' wie beim tasks_zahlen_guard (A20): die
-- SECURITY-DEFINER-RPCs laufen als owner und passieren.

create or replace function public.tasks_pruefer_guard()
returns trigger language plpgsql as $$
begin
  if current_user = 'authenticated'
     and public.get_my_role() is distinct from 'admin' then
    if new.status      is distinct from old.status
       or new.reviewed_by is distinct from old.reviewed_by
       or new.reviewed_at is distinct from old.reviewed_at then
      raise exception 'Freigabe: Status nur ueber task_status_set / lena_beanstande'
        using errcode = '42501';
    end if;
    -- Herkunft und Steuerung des Bestands pflegt der Pruefer nicht: sie
    -- entscheiden, woher eine Aufgabe kommt und ob/wie die LSA sie zieht.
    if new.id is distinct from old.id
       or new.source        is distinct from old.source
       or new.source_ref    is distinct from old.source_ref
       or new.created_at    is distinct from old.created_at
       or new.content_type  is distinct from old.content_type
       or new.is_active     is distinct from old.is_active
       or new.is_diagnostic is distinct from old.is_diagnostic
       or new.is_tutorial   is distinct from old.is_tutorial
       or new.skill_key     is distinct from old.skill_key
       or new.sondierrang   is distinct from old.sondierrang then
      raise exception 'Freigabe: Herkunfts- und Steuerfelder aendert nur admin'
        using errcode = '42501';
    end if;
    if old.status = 'ready' then
      raise exception 'Freigabe: eine freigegebene Aufgabe aendert nur admin'
        using errcode = '42501';
    end if;
  end if;
  return new;
end $$;

drop trigger if exists tasks_pruefer_guard on public.tasks;
create trigger tasks_pruefer_guard
  before update on public.tasks
  for each row execute function public.tasks_pruefer_guard();


-- ── 3. task_status_set: zwei Stufen ─────────────────────────────────────────
--
--   admin    : jeder Uebergang (wie bisher).
--   Pruefer  : nur zwischen draft / review / beanstandet, Ziel draft oder
--              review. 'ready' als Quelle oder Ziel bleibt admin.
-- Das Pflichtfeld-Gate gilt jetzt fuer 'review' UND 'ready'. Der Stempel
-- reviewed_by/at bleibt die FREIGABE (nur 'ready').

create or replace function public.task_status_set(p_task_id uuid, p_status text)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_task  tasks%rowtype;
  v_admin boolean := public.get_my_role() is not distinct from 'admin'
                     or public.ist_systemaufruf();
begin
  if not (v_admin or public.darf_pruefen()) then
    raise exception 'task_status_set: kein Pruefrecht' using errcode = '42501';
  end if;
  if p_status not in ('draft', 'review', 'ready') then
    raise exception 'task_status_set: unbekannter Status %', p_status
      using errcode = '22023';
  end if;

  -- for update: sonst liest ein Pruefer 'review', waehrend admin gerade
  -- freigibt, und ueberschreibt danach das 'ready'.
  select * into v_task from tasks where id = p_task_id for update;
  if not found then
    raise exception 'task_status_set: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;

  if not v_admin and (p_status = 'ready' or v_task.status = 'ready') then
    raise exception 'task_status_set: freigeben und zuruecknehmen nur admin'
      using errcode = '42501';
  end if;

  -- Das Gate. Was hier durchfaellt, kommt nicht in den LSA-Pool — unabhaengig
  -- davon, was das Frontend meint. Es sind dieselben Pflichtfelder, die
  -- src/lib/authoring/flags.ts prueft; hier stehen die, die die DB selbst
  -- beantworten kann (das Tool prueft zusaetzlich Alt-Texte u.a.).
  if p_status in ('review', 'ready') then
    if coalesce(btrim(v_task.question), '') = '' then
      raise exception 'task_status_set: Stamm fehlt' using errcode = 'P0001';
    end if;
    if v_task.input_type is null then
      raise exception 'task_status_set: input_type fehlt' using errcode = 'P0001';
    end if;
    if v_task.afb is null then
      raise exception 'task_status_set: AFB fehlt' using errcode = 'P0001';
    end if;
    if v_task.cluster_id is null then
      raise exception 'task_status_set: Cluster fehlt (sonst nie im LSA-Pool)'
        using errcode = 'P0001';
    end if;
    -- Der Stoffanker ist der Grund, warum es dieses Tool gibt. Ohne ihn zieht die
    -- LSA das Item auf dem falschen Jahrgang.
    if v_task.curriculum_grade is null then
      raise exception 'task_status_set: Stoffanker (curriculum_grade) fehlt'
        using errcode = 'P0001';
    end if;
    -- Loesung: lsa_has_answers (P02) kennt beide Formen — flach + Multi-Part — und
    -- verlangt bei MULTI_PART eine Loesung JE Teilaufgabe. Kein zweites Regelwerk.
    if not exists (
      select 1 from task_solutions s
       where s.task_id = p_task_id
         and public.lsa_has_answers(v_task.input_type, v_task.parts, s.correct_answers)
    ) then
      raise exception 'task_status_set: Loesung unvollstaendig' using errcode = 'P0001';
    end if;
  end if;

  update tasks
     set status      = p_status,
         reviewed_by = case when p_status = 'ready' then auth.uid() else null end,
         reviewed_at = case when p_status = 'ready' then now()      else null end
   where id = p_task_id;

  return jsonb_build_object('ok', true, 'task_id', p_task_id, 'status', p_status);
end;
$function$;


-- ── 4. Beanstanden fuer Pruefer ─────────────────────────────────────────────
--
-- Eine freigegebene Aufgabe beanstanden heisst, die Freigabe zurueckzunehmen —
-- das bleibt admin. lena_beanstande_muster bleibt unveraendert admin (es trifft
-- ohne Status-Filter auch 'ready').

alter table public.task_reviews drop constraint if exists task_reviews_kategorie_check;
alter table public.task_reviews add constraint task_reviews_kategorie_check
  check (kategorie in (
    'fehlbild_falsch', 'fehlbild_unrealistisch', 'zahlen_unguenstig',
    'formulierung', 'didaktisch', 'kontext',
    'loesung_passt_nicht'));   -- akzeptierte Antwort oder Loesungsweg passt nicht zur Aufgabe

create or replace function public.lena_beanstande(
  p_task_id uuid, p_kategorie text, p_notiz text default null)
returns integer language plpgsql security definer set search_path = public as $$
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


-- ── 5. Loesungspflege fuer Pruefer ──────────────────────────────────────────
--
-- Nur der Rollen-Check aendert sich; der Rest ist task_solution_upsert wie
-- eingespielt. Grenze wie in A20 benannt: diese RPC laeuft als owner, der
-- task_solutions_zahlen_guard greift hier nicht.

create or replace function public.task_solution_upsert(
  p_task_id uuid, p_correct_answers jsonb default null::jsonb, p_solution text default null::text,
  p_hints jsonb default null::jsonb, p_coach_hints jsonb default null::jsonb,
  p_typical_errors jsonb default null::jsonb, p_beleg jsonb default null::jsonb,
  p_acceptance jsonb default null::jsonb, p_option_scores jsonb default null::jsonb)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_admin  boolean := public.get_my_role() is not distinct from 'admin'
                      or public.ist_systemaufruf();
  v_status text;
begin
  if not (v_admin or public.darf_pruefen()) then
    raise exception 'task_solution_upsert: kein Pruefrecht' using errcode = '42501';
  end if;
  select status into v_status from tasks where id = p_task_id for update;
  if not found then
    raise exception 'task_solution_upsert: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  -- Wie beim tasks_pruefer_guard: unter einer Freigabe aendert nur admin.
  if not v_admin and v_status = 'ready' then
    raise exception 'task_solution_upsert: eine freigegebene Aufgabe aendert nur admin'
      using errcode = '42501';
  end if;
  if p_beleg is not null and jsonb_typeof(p_beleg) not in ('array', 'null') then
    raise exception 'task_solution_upsert: beleg muss ein Array sein (oder JSON-null zum Leeren)'
      using errcode = '22023';
  end if;
  -- Frueh und mit Klartext statt erst im CHECK: der Editor soll wissen, WAS
  -- nicht stimmt, nicht nur dass ein Constraint gefeuert hat.
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
    (p_task_id,
     coalesce(p_correct_answers, '[]'::jsonb),
     nullif(p_solution, ''),
     coalesce(p_hints, '[]'::jsonb),
     coalesce(p_coach_hints, '[]'::jsonb),
     coalesce(p_typical_errors, '[]'::jsonb),
     case when p_beleg is null or jsonb_typeof(p_beleg) = 'null' then null else p_beleg end,
     case when p_acceptance is null or jsonb_typeof(p_acceptance) = 'null'
          then null else p_acceptance end,
     case when p_option_scores is null or jsonb_typeof(p_option_scores) = 'null'
          then null else p_option_scores end,
     now())
  on conflict (task_id) do update
     set correct_answers = coalesce(p_correct_answers, s.correct_answers),
         solution        = case when p_solution is null then s.solution
                                else nullif(p_solution, '') end,
         hints           = coalesce(p_hints, s.hints),
         coach_hints     = coalesce(p_coach_hints, s.coach_hints),
         typical_errors  = coalesce(p_typical_errors, s.typical_errors),
         beleg           = case when p_beleg is null then s.beleg
                                when jsonb_typeof(p_beleg) = 'null' then null
                                else p_beleg end,
         acceptance      = case when p_acceptance is null then s.acceptance
                                when jsonb_typeof(p_acceptance) = 'null' then null
                                else p_acceptance end,
         option_scores   = case when p_option_scores is null then s.option_scores
                                when jsonb_typeof(p_option_scores) = 'null' then null
                                else p_option_scores end,
         updated_at      = now();

  return jsonb_build_object('ok', true, 'task_id', p_task_id);
end;
$function$;


-- ── 6. freigabe_cluster: review -> ready fuer einen Cluster ──────────────────
--
-- Gegenstueck zu freigabe_muster (A21), aber auf dem Cluster und nur fuer
-- 'review': admin gibt frei, was die Pruefer als fertig gemeldet haben. Jede
-- Aufgabe laeuft durch das Gate; faellt eine durch (P0001), bleibt sie 'review'
-- und der Rest laeuft weiter. Rueckgabe: Anzahl tatsaechlich freigegebener.

create or replace function public.freigabe_cluster(p_cluster_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_n  integer := 0;
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'freigabe_cluster: nur admin darf freigeben' using errcode = '42501';
  end if;

  for v_id in
    select id from public.tasks
     where cluster_id = p_cluster_id and status = 'review'
  loop
    begin
      perform public.task_status_set(v_id, 'ready');
      v_n := v_n + 1;
    exception
      when sqlstate 'P0001' then null;
    end;
  end loop;

  return v_n;
end $$;


-- ── 7. A20-Nachtrag: NULL-Falle und anon-Execute schliessen ─────────────────
--
-- Befund 22.09.: A20 grantete nur an authenticated, nahm PUBLIC/anon aber nie
-- weg — anon konnte lena_text_aendern, lena_beanstande_muster und
-- lena_beanstande ausfuehren. Und `get_my_role() <> 'admin'` ist fuer einen
-- Aufrufer ohne Profil NULL, die Sperre feuerte nicht. Beide Funktionen bleiben
-- admin-only; nur der Check wird NULL-fest. Koerper sonst wie A20.

create or replace function public.lena_text_aendern(p_task_id uuid, p_question text)
returns void language plpgsql security definer set search_path = public as $$
declare v_alt text;
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'A20: nur die fachliche Freigabe (admin) darf den Text aendern'
      using errcode = '42501';
  end if;
  select question into v_alt from public.tasks where id = p_task_id;
  if not found then
    raise exception 'A20: Aufgabe % nicht gefunden', p_task_id using errcode = 'P0002';
  end if;
  if public.lsa_ziffernfolge(p_question) is distinct from public.lsa_ziffernfolge(v_alt) then
    raise exception 'A20: Der Text darf geaendert werden, die Zahlen nicht.'
      using errcode = '23514';
  end if;
  update public.tasks set question = p_question where id = p_task_id;
  -- Status bewusst unberuehrt: wer den Text aendert, setzt KEINE Freigabe.
end $$;

create or replace function public.lena_beanstande_muster(
  p_skill_key text, p_fehlbild_label text, p_kategorie text, p_notiz text default null)
returns integer language plpgsql security definer set search_path = public as $$
declare v_n integer;
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'A20: nur die fachliche Freigabe (admin) darf beanstanden'
      using errcode = '42501';
  end if;

  create temporary table _betroffen on commit drop as
    select t.id
      from public.tasks t
      join public.task_solutions s on s.task_id = t.id
     where t.skill_key = p_skill_key
       and jsonb_typeof(s.acceptance -> 'known_errors') = 'object'
       and exists (
         select 1 from jsonb_each_text(s.acceptance -> 'known_errors') as kv(key, value)
          where kv.value = p_fehlbild_label);

  update public.tasks set status = 'beanstandet'
   where id in (select id from _betroffen);

  insert into public.task_reviews (task_id, kategorie, notiz, geprueft_von)
    select id, p_kategorie, p_notiz, auth.uid() from _betroffen;

  select count(*) into v_n from _betroffen;
  return v_n;
end $$;


-- ── Grants ──────────────────────────────────────────────────────────────────
-- create or replace behaelt bestehende Grants. Supabase grantet anon direkt
-- (default privileges) — deshalb anon ausdruecklich, nicht nur PUBLIC.

revoke all on function public.lena_text_aendern(uuid, text) from public, anon;
revoke all on function public.lena_beanstande_muster(text, text, text, text) from public, anon;
revoke all on function public.lena_beanstande(uuid, text, text) from public, anon;
grant execute on function public.lena_text_aendern(uuid, text) to authenticated;
grant execute on function public.lena_beanstande_muster(text, text, text, text) to authenticated;
grant execute on function public.lena_beanstande(uuid, text, text) to authenticated;

revoke all on function public.freigabe_cluster(uuid) from public, anon;
grant execute on function public.freigabe_cluster(uuid) to authenticated;
