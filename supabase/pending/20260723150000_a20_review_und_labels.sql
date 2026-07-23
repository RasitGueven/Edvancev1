-- ============================================================================
-- A20: Freigabe-Fundament — Label-Registry, Beanstandung, Textschutz
--
-- KEIN begin/commit (der Runner / der Dry-Run klammert).
--
-- ----------------------------------------------------------------------------
-- MESSERGEBNIS (vor dem Bau, im PR zusammengefasst)
-- ----------------------------------------------------------------------------
--  * LABEL-REGISTRY: existiert NICHT. Es gibt KEINE Tabelle fuer known_errors-
--    Slugs — sie leben ausschliesslich als Werte in
--    task_solutions.acceptance->'known_errors' ({wert: slug}). Auftrag 1
--    "erweitern" ist deshalb "ANLEGEN", geseedet aus den benutzten Slugs.
--  * status='review': LEBT. Der Pflege-Wizard setzt es (onReview ->
--    task_status_set), ReleaseGate/HealthOverview/AuthoringFilters lesen es.
--    Kein toter Zustand — bleibt.
--  * AUFGABENLISTE: AuthoringItemsPage + AuthoringFilters (A05) existieren; ein
--    Klick oeffnet die Pflege-Ansicht (A07). Teil 6 baut DARAUF auf.
--  * ZAHLEN-SCHREIBFLAECHE: tasks.question aendert der Editor per DIREKTEM
--    authenticated-UPDATE (taskAuthoring.ts). correct_answers/acceptance haben
--    KEIN direktes authenticated-Grant — sie laufen nur ueber
--    task_solution_upsert (SECURITY DEFINER, authenticated-ausfuehrbar). Daraus
--    folgt die Enforcement-Wahl (Teil 5): ein TRIGGER auf tasks.question (die
--    real offene Hand-Edit-Flaeche) + die RPC lena_text_aendern; ein
--    Spaltenrecht-Revoke waere zu grob (braeche jede legitime Text-Pflege).
--
-- Die tatsaechlichen Bestandszahlen weichen von der Vorlage ab (543 draft /
-- 14 ready statt 258/0) — die Mechanik aendert das nicht.
-- ============================================================================


-- ── Teil 1: Label-Registry ──────────────────────────────────────────────────
--
-- Drei Dinge je Label. klartext + erklaerung nullable (der Bestand hat sie
-- nicht); im Autorentool als "fehlt noch" sichtbar. Bestehende Slugs bleiben
-- unveraendert — geseedet, nicht umbenannt.

create table if not exists public.fehlbild_labels (
  slug        text primary key,
  klartext    text,
  erklaerung  text,
  erstellt_am timestamptz not null default now()
);

comment on table public.fehlbild_labels is
  'Registry der known_errors-Slugs. klartext (Lena-Name) + erklaerung (was das '
  'Kind falsch macht) sind nullable — ohne die erklaerung kann Lena nicht '
  'beurteilen, ob ein Label zum Fehlbild einer Aufgabe passt.';

-- Seed: die tatsaechlich benutzten Slugs (Werte in known_errors-OBJEKTEN).
-- Array-Form-known_errors tragen nur Werte, keine Slugs — sie liefern nichts.
insert into public.fehlbild_labels (slug)
select distinct kv.value
  from public.task_solutions s
  cross join lateral jsonb_each_text(
    case when jsonb_typeof(s.acceptance -> 'known_errors') = 'object'
         then s.acceptance -> 'known_errors' else '{}'::jsonb end) as kv(key, value)
 where s.acceptance ? 'known_errors'
on conflict (slug) do nothing;

alter table public.fehlbild_labels enable row level security;
drop policy if exists fehlbild_labels_read on public.fehlbild_labels;
create policy fehlbild_labels_read on public.fehlbild_labels
  for select using (public.get_my_role() = any (array['admin', 'coach']));
grant select on public.fehlbild_labels to authenticated;


-- ── Teil 2: status 'beanstandet' ────────────────────────────────────────────
--
-- Kein Endzustand, ein Rueckweg: geprueft, Mangel gefunden. 'review' bleibt
-- (lebt, s. Messung). Ein spaeterer Test-Freigabe-Umschalter hebt nur 'draft'
-- auf 'ready' — 'beanstandet' bleibt liegen, Lenas Befund ueberlebt.

alter table public.tasks drop constraint if exists tasks_status_check;
alter table public.tasks add constraint tasks_status_check
  check (status = any (array['draft', 'review', 'ready', 'beanstandet']));


-- ── Teil 3: task_reviews ────────────────────────────────────────────────────
--
-- Eigene Tabelle, keine Spalte auf tasks: eine Aufgabe kann mehrfach
-- beanstandet, korrigiert und erneut beanstandet werden — die Spur will man
-- haben. Die kategorie traegt die Automatisierung (wer behebt, ist ein
-- Content-Lauf), der Freitext ergaenzt.

create table if not exists public.task_reviews (
  id           uuid primary key default gen_random_uuid(),
  task_id      uuid not null references public.tasks(id) on delete cascade,
  kategorie    text not null check (kategorie in (
                 'fehlbild_falsch',        -- Label passt nicht zum Fehler
                 'fehlbild_unrealistisch', -- Fehler, den kein Achtklaessler macht
                 'zahlen_unguenstig',      -- Kollision, untippbar, zu gross
                 'formulierung',           -- unklar, mehrdeutig
                 'didaktisch',             -- falscher Skill, falsches AFB
                 'kontext')),              -- Sachkontext liefert die Antwort mit
  notiz        text,
  geprueft_von uuid references public.profiles(id),
  geprueft_am  timestamptz not null default now()
);

create index if not exists task_reviews_task_idx on public.task_reviews(task_id);

alter table public.task_reviews enable row level security;
drop policy if exists task_reviews_read on public.task_reviews;
create policy task_reviews_read on public.task_reviews
  for select using (public.get_my_role() = any (array['admin', 'coach']));
grant select on public.task_reviews to authenticated;


-- ── Teil 5 (zuerst — Teil 4 braucht die Helfer): Text ja, Zahlen nein ───────
--
-- Die Ziffernfolge eines Textes: die geordnete Liste seiner Zahl-Token.
-- "3 m = ? cm" -> {3}; "Wandle um. 3 m = ? cm" -> {3}. Text aendern aendert
-- sie nicht, eine Zahl aendern schon.

create or replace function public.lsa_ziffernfolge(p_text text)
returns text[] language sql immutable as $$
  select coalesce(
    array(select m[1] from regexp_matches(coalesce(p_text, ''), '\d+', 'g') as m),
    '{}'::text[])
$$;

-- Trigger auf tasks.question: ein authenticated-Aktor (Lena, jeder UI-Pfleger)
-- darf den Text aendern, aber nicht die Zahlen. Eine von Hand geaenderte Zahl
-- ist nicht mehr gegen lsa_grade geprueft und umgeht das ganze Sieb.
-- Content-Laeufe (service_role) und SECURITY-DEFINER-RPCs (Aktor = owner)
-- passieren.

create or replace function public.tasks_zahlen_guard()
returns trigger language plpgsql as $$
begin
  if current_user = 'authenticated'
     and public.lsa_ziffernfolge(new.question)
         is distinct from public.lsa_ziffernfolge(old.question) then
    raise exception
      'A20: Zahlen im Aufgabentext duerfen nicht von Hand geaendert werden — nur der Text. Eine geaenderte Zahl umgeht das Sieb.'
      using errcode = '23514';
  end if;
  return new;
end $$;

drop trigger if exists tasks_zahlen_guard on public.tasks;
create trigger tasks_zahlen_guard
  before update of question on public.tasks
  for each row execute function public.tasks_zahlen_guard();

-- Defensive Zwillingssperre auf task_solutions: authenticated darf
-- correct_answers/acceptance nicht direkt aendern. HEUTE hat authenticated dort
-- kein Grant (Schreiben laeuft nur ueber task_solution_upsert, DEFINER) — der
-- Trigger ist Guertel-und-Hosentraeger fuer den Fall eines spaeteren Grants.
-- Die RPC-Flaeche (task_solution_upsert) bleibt offen; sie gegen Hand-Zahlen
-- zu sperren ist ein eigener Schritt (sie ist zugleich der Content-Pfad) — im
-- PR als Grenze benannt.

create or replace function public.task_solutions_zahlen_guard()
returns trigger language plpgsql as $$
begin
  if current_user = 'authenticated'
     and (new.correct_answers is distinct from old.correct_answers
          or new.acceptance is distinct from old.acceptance) then
    raise exception
      'A20: Loesungszahlen (correct_answers/acceptance) duerfen nicht von Hand geaendert werden.'
      using errcode = '23514';
  end if;
  return new;
end $$;

drop trigger if exists task_solutions_zahlen_guard on public.task_solutions;
create trigger task_solutions_zahlen_guard
  before update of correct_answers, acceptance on public.task_solutions
  for each row execute function public.task_solutions_zahlen_guard();

-- Der gangbare Text-Weg fuer Lena: aendert NUR question, prueft die
-- Ziffern-Invarianz selbst, und setzt bewusst KEINEN Status — eine
-- Textaenderung ist keine Freigabe (Fall fuer erneute Sichtung).

create or replace function public.lena_text_aendern(p_task_id uuid, p_question text)
returns void language plpgsql security definer set search_path = public as $$
declare v_alt text;
begin
  if public.get_my_role() <> 'admin' then
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


-- ── Teil 4: Beanstandung — einzeln und als Muster ───────────────────────────
--
-- Beide setzen status='beanstandet' und schreiben je eine task_reviews-Zeile.
-- Rueckgabe: Anzahl betroffener Aufgaben.

create or replace function public.lena_beanstande(
  p_task_id uuid, p_kategorie text, p_notiz text default null)
returns integer language plpgsql security definer set search_path = public as $$
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'A20: nur die fachliche Freigabe (admin) darf beanstanden'
      using errcode = '42501';
  end if;
  update public.tasks set status = 'beanstandet' where id = p_task_id;
  if not found then
    raise exception 'A20: Aufgabe % nicht gefunden', p_task_id using errcode = 'P0002';
  end if;
  insert into public.task_reviews (task_id, kategorie, notiz, geprueft_von)
    values (p_task_id, p_kategorie, p_notiz, auth.uid());
  return 1;
end $$;

-- Muster: alle Aufgaben eines Skills, die dieses Fehlbild-Label tragen. Ohne
-- Status-Filter — auch ein bereits freigegebenes 'ready' mit dem Muster gehoert
-- beanstandet (Lenas Befund gilt fuer das Muster, nicht fuer den Status).

create or replace function public.lena_beanstande_muster(
  p_skill_key text, p_fehlbild_label text, p_kategorie text, p_notiz text default null)
returns integer language plpgsql security definer set search_path = public as $$
declare v_n integer;
begin
  if public.get_my_role() <> 'admin' then
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

grant execute on function public.lena_beanstande(uuid, text, text) to authenticated;
grant execute on function public.lena_beanstande_muster(text, text, text, text) to authenticated;
grant execute on function public.lena_text_aendern(uuid, text) to authenticated;


-- ── Teil 6-Stuetze: Label-Metadaten je Aufgabe fuer die Liste ───────────────
--
-- Die Liste laedt bewusst keine Loesungen (185 RPCs). Diese eine Abfrage
-- liefert kompakt, was die neuen Filter brauchen: je Aufgabe ihre
-- Fehlbild-Slugs und ob eines davon noch unvollstaendig ist (klartext ODER
-- erklaerung fehlt). Admin/Coach only — die Slugs sind Diagnostik, kein
-- Schuelerdatum.

create or replace function public.authoring_review_meta()
returns table (task_id uuid, labels text[], has_incomplete boolean)
language sql stable security definer set search_path = public as $$
  select t.id,
         coalesce(array_agg(distinct kv.value) filter (where kv.value is not null), '{}'::text[]),
         coalesce(bool_or(fl.klartext is null or fl.erklaerung is null), false)
    from public.tasks t
    join public.task_solutions s on s.task_id = t.id
    left join lateral jsonb_each_text(
      case when jsonb_typeof(s.acceptance -> 'known_errors') = 'object'
           then s.acceptance -> 'known_errors' else '{}'::jsonb end) as kv(key, value) on true
    left join public.fehlbild_labels fl on fl.slug = kv.value
   where public.get_my_role() = any (array['admin', 'coach'])
   group by t.id
$$;

grant execute on function public.authoring_review_meta() to authenticated;


-- ── PRUEFUNG (bricht bei Abweichung ab; die Transaktion rollt zurueck) ──────

do $$
declare
  v_admin   uuid := '35e4f9ac-d9aa-421c-8ba8-3948b1575f41';
  v_skill   text; v_label text;
  v_soll    int; v_ist int; v_n int;
  v_task    uuid; v_alt_q text; v_status text;
  v_ready   uuid[]; v_ctrl boolean;
begin
  perform set_config('request.jwt.claims', json_build_object('sub', v_admin)::text, true);

  -- 1. status='beanstandet' angenommen, Altwerte weiter gueltig.
  select id into v_task from public.tasks where status = 'draft' limit 1;
  update public.tasks set status = 'beanstandet' where id = v_task;
  update public.tasks set status = 'draft' where id = v_task;   -- Altwert weiter gueltig
  update public.tasks set status = 'ready' where id = v_task;
  update public.tasks set status = 'review' where id = v_task;
  update public.tasks set status = 'draft' where id = v_task;
  raise notice 'P1 ok: beanstandet + draft/ready/review weiter gueltig';

  -- Ein Muster mit garantiert mehreren Treffern: Skill + Label mit >=2 Aufgaben.
  select t.skill_key, kv.value, count(*)
    into v_skill, v_label, v_soll
    from public.tasks t
    join public.task_solutions s on s.task_id = t.id
    cross join lateral jsonb_each_text(
      case when jsonb_typeof(s.acceptance -> 'known_errors') = 'object'
           then s.acceptance -> 'known_errors' else '{}'::jsonb end) as kv(key, value)
   where t.skill_key is not null
   group by t.skill_key, kv.value
   having count(*) >= 2
   order by count(*) desc
   limit 1;
  if v_skill is null then raise exception 'kein Muster mit >=2 Treffern gefunden'; end if;

  -- ready-Aufgaben VOR dem Muster festhalten (fuer P6).
  select array_agg(id) into v_ready from public.tasks where status = 'ready';

  -- 2. Muster trifft genau Skill UND Label; Rueckgabe == Anzahl.
  v_ist := public.lena_beanstande_muster(v_skill, v_label, 'fehlbild_falsch', 'Probe');
  if v_ist <> v_soll then
    raise exception 'P2 Rueckgabe %, erwartet % Treffer', v_ist, v_soll;
  end if;
  -- keine anderen: jede beanstandete Aufgabe MIT Review 'Probe' traegt Skill+Label.
  select count(*) into v_n
    from public.task_reviews r
    join public.tasks t on t.id = r.task_id
   where r.notiz = 'Probe'
     and (t.skill_key is distinct from v_skill
          or not exists (
            select 1 from public.task_solutions s
            cross join lateral jsonb_each_text(coalesce(s.acceptance -> 'known_errors','{}'::jsonb)) kv
             where s.task_id = t.id and kv.value = v_label));
  if v_n <> 0 then raise exception 'P2 % Beanstandungen ausserhalb Skill+Label', v_n; end if;
  raise notice 'P2 ok: Muster trifft genau %, Rueckgabe %', v_soll, v_ist;

  -- 3. Jede betroffene Aufgabe: genau eine task_reviews-Zeile (aus diesem Aufruf).
  select count(*) into v_n from (
    select r.task_id, count(*) c from public.task_reviews r
     where r.notiz = 'Probe' group by r.task_id having count(*) <> 1) x;
  if v_n <> 0 then raise exception 'P3 % Aufgaben mit != 1 Review-Zeile', v_n; end if;
  select count(*) into v_n from public.tasks
   where skill_key = v_skill and status = 'beanstandet';
  if v_n < v_soll then raise exception 'P3 nicht alle betroffenen beanstandet'; end if;
  raise notice 'P3 ok: je betroffene Aufgabe genau eine Review-Zeile';

  -- 4. Zahlenaenderung abgewiesen, Textaenderung geht durch.
  select id, question into v_task, v_alt_q from public.tasks
   where question ~ '\d' and status = 'draft' limit 1;
  v_ctrl := false;
  begin
    perform public.lena_text_aendern(v_task, v_alt_q || ' 999');   -- neue Zahl
    raise warning 'P4 Zahlenaenderung NICHT abgewiesen';
  exception when sqlstate '23514' then v_ctrl := true;
  end;
  if not v_ctrl then raise exception 'P4 Zahlenaenderung ging durch'; end if;
  perform public.lena_text_aendern(v_task, v_alt_q || ' (bitte genau lesen)');  -- nur Text
  select question into v_status from public.tasks where id = v_task;
  if v_status <> v_alt_q || ' (bitte genau lesen)' then
    raise exception 'P4 Textaenderung nicht uebernommen';
  end if;
  raise notice 'P4 ok: Zahl abgewiesen, Text durch';

  -- 5. Textaenderung setzt status NICHT auf ready.
  select status into v_status from public.tasks where id = v_task;
  if v_status = 'ready' then raise exception 'P5 Textaenderung hat auf ready gesetzt'; end if;
  raise notice 'P5 ok: Text aendert Status nicht (%)', v_status;

  -- 6. Ein 'ready' ausserhalb des Filters bleibt unberuehrt.
  select count(*) into v_n from public.tasks
   where id = any (v_ready) and status <> 'ready'
     and (skill_key is distinct from v_skill
          or not exists (
            select 1 from public.task_solutions s
            cross join lateral jsonb_each_text(coalesce(s.acceptance -> 'known_errors','{}'::jsonb)) kv
             where s.task_id = tasks.id and kv.value = v_label));
  if v_n <> 0 then raise exception 'P6 % ready-Aufgaben ausserhalb Filter veraendert', v_n; end if;
  raise notice 'P6 ok: nicht passende ready-Aufgaben unberuehrt';

  -- 7. Negativkontrolle: der Harness MUSS bei falscher Erwartung abbrechen.
  v_ctrl := false;
  begin
    if (select count(*) from public.fehlbild_labels) <> -1 then
      raise exception 'kontrolle: absichtlich falsche Erwartung';
    end if;
  exception when others then v_ctrl := true;
  end;
  if not v_ctrl then raise exception 'P7 Negativkontrolle hat nicht ausgeloest'; end if;
  raise notice 'P7 ok: Negativkontrolle greift';

  raise notice 'A20: ALLE 7 PRUEFUNGEN BESTANDEN';
end $$;
