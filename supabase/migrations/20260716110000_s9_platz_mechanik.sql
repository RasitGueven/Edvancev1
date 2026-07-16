-- ============================================================================
-- S9 (Platz-Mechanik): Kiosk fuer die LSA — Option 3 aus docs/specs/PLATZ-analyse.md
-- (freigegeben durch Rasit).
--
-- Die Eingrenzung ist verbindlich: Die Platz-Mechanik ist AUSSCHLIESSLICH fuer
-- die LSA. Ein Platz-Kontext erreicht ausschliesslich die ihm aktuell
-- zugewiesene Session — NIEMALS Hub, XP, student_progress, fremde oder
-- vergangene Sessions. Der P01-Datenvertrag bleibt byte-identisch: KEIN
-- Eingriff in lsa_may_act_for / lsa_start / lsa_submit / lsa_hint / lsa_finish /
-- lsa_question_payload (einzige bewusste Ausnahme: das GRANT von
-- lsa_question_payload, §3.6(ii) der Analyse — siehe Abschnitt 7).
--
--   1. platz_devices — Kennzeichnung: Ein Platz ist ein normaler Auth-User mit
--      role='student' OHNE students-Zeile. So ein Konto ist strukturell
--      „nichts" (get_my_student_id() = null → alle lsa_* verweigern; keine
--      Studenten-RLS-Flaeche). Keine neue Rolle, kein CHECK-Umbau.
--   2. platz_assignments — kurzlebige, SESSION-scoped Zuweisung (nicht
--      schueler-scoped: vergangene/parallele Sessions desselben Kindes sind
--      nicht adressierbar). Ablauf ueber expires_at (2 h), Release durch
--      lsa_finish (Trigger), Ablauf oder Admin. Partial-Unique: eine aktive
--      Zuweisung je Platz.
--   3. platz_assign / platz_release — nur Admin.
--   4. platz_state / platz_next / platz_submit / platz_finish — die Tore nach
--      dem a02-Muster („Tor vor bestehender RPC, keine zweite Wahrheit").
--      KEINE session_id/task_id-Wahl von aussen, wo vermeidbar: jede Funktion
--      loest AUSSCHLIESSLICH ueber die aktive, nicht abgelaufene Zuweisung von
--      auth.uid() auf die EINE Session auf. Das Tablet KANN nicht nach einer
--      fremden Session fragen — es gibt keinen Parameter dafuer.
--   5. Release-Trigger auf lsa_sessions (analog lsa_session_lead_fertig_trg).
--   6. §3.6(ii): lsa_question_payload-GRANT fuer authenticated zurueckgezogen —
--      der Builder ist nur noch ueber seine Tore erreichbar.
--
-- ============================================================================
-- DIE AUFTRAGS-IDENTITAET — und warum platz_submit/platz_finish die JWT-Claims
-- transaktionslokal tauschen
--
--   lsa_submit/lsa_finish pruefen intern lsa_may_act_for(student_id):
--   coach/admin ODER students.profile_id = auth.uid(). Der Platz ist beides
--   nicht — GEWOLLT (ein dauerhaft im Raum liegendes Tablet darf nie
--   coach/admin tragen, und students.profile_id bleibt bei provisorischen
--   Zeilen NULL, A1-Leitplanke). Ein direkter interner Aufruf wuerde also mit
--   42501 scheitern. Die Alternativen waeren alle schlechter:
--     - lsa_may_act_for um die Zuweisung erweitern → Eingriff in die
--       eingefrorene P01-Autorisierung (Option 1a, abgelehnt).
--     - Die Submit-Logik duplizieren → zweite Wahrheit (der Fehler, den a02
--       gerade abgeschafft hat).
--   Deshalb: platz_assign schreibt die Identitaet des zuweisenden Admins in
--   platz_assignments.created_by fest. platz_submit/platz_finish validieren
--   ZUERST alles im Platz-Kontext (Zuweisung aktiv, nicht abgelaufen, Session
--   in_progress, p_task_id IST das aktuell offene Item) und rufen dann die
--   unveraenderte lsa_* mit dieser festgeschriebenen Admin-Identitaet auf —
--   set_config('request.jwt.claims', …, is_local=true), Aufruf, sofortiges
--   Zuruecksetzen. Der Platz handelt „im Auftrag" des Admins, der ihm genau
--   diese eine Session zugewiesen hat.
--
--   Warum das nichts oeffnet: Kein Parameter des Aufrufers erreicht den
--   erhoehten Block ungeprueft. session_id kommt aus der Zuweisung (nie vom
--   Client), p_task_id ist vorher gegen das aktuell offene Item der Session
--   geprueft, p_response/p_duration_ms sind Daten, keine Adressen. Das Fenster
--   ist zwei Statements lang und wird in derselben Funktion geschlossen; bei
--   einer Exception rollt die Transaktion die GUC-Aenderung mit zurueck
--   (transaktionale GUCs). pgTAP beweist, dass auth.uid() nach dem Aufruf
--   wieder der Platz ist (s9_platz_mechanik.test.sql).
--
--   Dasselbe Muster in diesem Repo: die GUC-Schleuse edvance.allow_provisional
--   (S7) und der Subtransaktions-Rollback in task_preview_payload (a02) —
--   kontrollierte, eng dokumentierte Maschinerie statt Vertragschirurgie.
-- ============================================================================

begin;

-- ============================================================================
-- 1. platz_devices — die Kennzeichnung (NICHT die Rolle)
-- ============================================================================

create table if not exists platz_devices (
  profile_id uuid primary key references profiles(id) on delete cascade,
  label      text not null,
  created_at timestamptz not null default now()
);

comment on table platz_devices is
  'Kiosk-Konten der LSA-Plaetze (PLATZ-Analyse Option 3). Ein Platz ist ein '
  'normaler Auth-User mit role=student OHNE students-Zeile — strukturell '
  '„nichts". Diese Tabelle ist die Kennzeichnung; die Rollen-Liste in '
  'profiles.role bleibt unangetastet. Angelegt durch Admin/service_role beim '
  'Einrichten des Tablets.';

alter table platz_devices enable row level security;

-- anon: nichts — auch nicht das Tabellen-Tor.
revoke all on table platz_devices from anon;

create policy "platz_devices_admin_all" on platz_devices
  for all
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');

-- Der Platz sieht seine eigene Kennzeichnung (Label am Kiosk) — eine Zeile,
-- sonst nichts.
create policy "platz_devices_select_self" on platz_devices
  for select using (profile_id = auth.uid());

-- ============================================================================
-- 2. platz_assignments — session-scoped, kurzlebig
-- ============================================================================

create table if not exists platz_assignments (
  id               uuid primary key default gen_random_uuid(),
  platz_profile_id uuid not null references platz_devices(profile_id) on delete cascade,
  session_id       uuid not null references lsa_sessions(id) on delete cascade,
  created_at       timestamptz not null default now(),
  -- Die Auftrags-Identitaet (Header oben): der Admin, der zugewiesen hat.
  -- on delete cascade: faellt der Admin, faellt die Zuweisung — der Platz
  -- faellt auf „wartet" zurueck, nie auf eine verwaiste Identitaet.
  created_by       uuid not null references profiles(id) on delete cascade,
  expires_at       timestamptz not null default (now() + interval '2 hours'),
  released_at      timestamptz
);

comment on table platz_assignments is
  'Kurzlebige Zuweisung Platz → LSA-Session (session-scoped, NICHT '
  'schueler-scoped). Aktiv = released_at null UND expires_at > now() — der '
  'Ablauf wird in JEDER platz_*-RPC geprueft, nicht nur beim Anlegen '
  '(PLATZ-Analyse §3.4). Release durch lsa_finish (Trigger), Ablauf oder '
  'platz_release (Admin).';
comment on column platz_assignments.created_by is
  'Auftrags-Identitaet: der zuweisende Admin. platz_submit/platz_finish rufen '
  'die unveraenderten lsa_submit/lsa_finish mit dieser Identitaet auf '
  '(transaktionslokaler Claims-Tausch) — lsa_may_act_for bleibt byte-identisch.';

-- Eine aktive Zuweisung je Platz. „Aktiv" heisst hier released_at null — eine
-- ABGELAUFENE, nie freigegebene Zeile blockiert den Index weiterhin; deshalb
-- raeumt platz_assign solche Zeilen beim Neuzuweisen auf (released_at setzen).
create unique index if not exists platz_assignments_active_unique
  on platz_assignments (platz_profile_id) where released_at is null;

create index if not exists platz_assignments_session_idx
  on platz_assignments (session_id);

alter table platz_assignments enable row level security;

revoke all on table platz_assignments from anon;

create policy "platz_assignments_admin_all" on platz_assignments
  for all
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');

-- Der Platz liest NUR die eigene aktive, nicht abgelaufene Zeile (macht
-- Realtime moeglich; Polling ueber platz_state reicht fuer den Start).
-- Vergangene, freigegebene und abgelaufene Zuweisungen sind unsichtbar.
create policy "platz_assignments_select_own_active" on platz_assignments
  for select using (
    platz_profile_id = auth.uid()
    and released_at is null
    and expires_at > now()
  );

-- ============================================================================
-- 3. Interner Aufloeser: die EINE aktive Zuweisung von auth.uid()
--    Jede platz_*-RPC geht ausschliesslich hierueber — es gibt keinen
--    Parameter, mit dem ein Aufrufer eine andere Zuweisung adressieren kann.
-- ============================================================================

create or replace function public.platz_current_assignment()
returns platz_assignments
language sql
stable
security definer
set search_path = public
as $$
  select a.*
    from platz_assignments a
   where a.platz_profile_id = auth.uid()
     and a.released_at is null
     and a.expires_at > now()
   limit 1
$$;

comment on function public.platz_current_assignment() is
  'Interner Helfer: aktive, nicht abgelaufene Zuweisung des Aufrufers — oder '
  'NULL-Record. expires_at wird hier bei JEDEM Aufruf geprueft (Analyse §3.4).';

-- ============================================================================
-- 4. platz_assign / platz_release — der Admin-Weg (ein Klick am Empfang)
-- ============================================================================

create or replace function public.platz_assign(
  p_platz_profile_id uuid,
  p_session_id       uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session lsa_sessions;
  v_id      uuid;
  v_expires timestamptz;
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'platz_assign: nur Admin' using errcode = '42501';
  end if;

  if not exists (select 1 from platz_devices where profile_id = p_platz_profile_id) then
    raise exception 'platz_assign: kein Platz-Konto (platz_devices)'
      using errcode = 'P0002';
  end if;

  select * into v_session from lsa_sessions where id = p_session_id;
  if not found then
    raise exception 'platz_assign: Session nicht gefunden' using errcode = 'P0002';
  end if;
  if v_session.status <> 'in_progress' then
    raise exception 'platz_assign: Session ist nicht in Durchfuehrung (status=%)',
      v_session.status using errcode = 'P0001';
  end if;

  -- Aktive Zuweisung → verweigern (bewusste Entscheidung am Empfang noetig).
  if exists (
    select 1 from platz_assignments
     where platz_profile_id = p_platz_profile_id
       and released_at is null
       and expires_at > now()
  ) then
    raise exception 'platz_assign: Platz hat bereits eine aktive Zuweisung'
      using errcode = 'P0001';
  end if;

  -- Abgelaufene, nie freigegebene Zeile aufraeumen — sonst blockierte der
  -- Partial-Unique-Index den Platz dauerhaft (siehe Kommentar am Index).
  update platz_assignments
     set released_at = now()
   where platz_profile_id = p_platz_profile_id
     and released_at is null;

  insert into platz_assignments (platz_profile_id, session_id, created_by)
  values (p_platz_profile_id, p_session_id, auth.uid())
  returning id, expires_at into v_id, v_expires;

  return jsonb_build_object('ok', true, 'assignment_id', v_id, 'expires_at', v_expires);
end;
$$;

comment on function public.platz_assign(uuid, uuid) is
  'Zuweisung Platz → LSA-Session. Nur Admin. Verweigert bei aktiver Zuweisung '
  '(P0001) und wenn die Session nicht in_progress ist (P0001). Schreibt '
  'created_by als Auftrags-Identitaet fest. Raeumt abgelaufene Alt-Zeilen des '
  'Platzes auf.';

create or replace function public.platz_release(p_assignment_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
begin
  if public.get_my_role() <> 'admin' then
    raise exception 'platz_release: nur Admin' using errcode = '42501';
  end if;

  update platz_assignments
     set released_at = now()
   where id = p_assignment_id
     and released_at is null;
  get diagnostics v_count = row_count;

  if v_count = 0 and not exists (
    select 1 from platz_assignments where id = p_assignment_id
  ) then
    raise exception 'platz_release: Zuweisung nicht gefunden' using errcode = 'P0002';
  end if;

  -- Bereits freigegeben → idempotent (released=false meldet das ehrlich).
  return jsonb_build_object('ok', true, 'released', v_count = 1);
end;
$$;

comment on function public.platz_release(uuid) is
  'Manuelle Freigabe einer Zuweisung. Nur Admin. Idempotent bei bereits '
  'freigegebenen Zeilen; P0002 wenn die Zuweisung nicht existiert.';

-- ============================================================================
-- 5. Die Platz-Tore — a02-Muster: Tor vor bestehender RPC, keine zweite Wahrheit
--
--    Rollenpruefung im Body: der Aufrufer MUSS in platz_devices stehen (auch
--    Admin/Coach kommen hier nicht durch — sie haben ihre eigenen Wege).
--    platz_state ist die einzige Funktion, die ohne Zuweisung antwortet
--    („wartet"); platz_next/platz_submit/platz_finish verweigern mit 42501.
-- ============================================================================

create or replace function public.platz_state()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_a          platz_assignments;
  v_session    lsa_sessions;
  v_first_name text;
  v_answered   integer;
begin
  if not exists (select 1 from platz_devices where profile_id = auth.uid()) then
    raise exception 'platz_state: kein Platz-Konto' using errcode = '42501';
  end if;

  v_a := public.platz_current_assignment();
  if v_a.id is null then
    return jsonb_build_object('status', 'wartet');
  end if;

  select * into v_session from lsa_sessions where id = v_a.session_id;
  -- Verteidigungslinie: eine aktive Zuweisung auf eine nicht mehr laufende
  -- Session (Trigger raeumt das normalerweise ab) zaehlt als „wartet".
  if not found or v_session.status <> 'in_progress' then
    return jsonb_build_object('status', 'wartet');
  end if;

  -- „Hi <Name>" ueber session → students.lead_id → leads.first_name (S7:
  -- der Name lebt am Lead). Der Platz erfaehrt NIE lead_id, student_id,
  -- session_id oder Auswertungsdaten — nur den Rufnamen und den Fortschritt.
  select l.first_name into v_first_name
    from students s
    join leads l on l.id = s.lead_id
   where s.id = v_session.student_id;

  select count(distinct r.task_id)::int into v_answered
    from lsa_responses r
   where r.session_id = v_session.id;

  return jsonb_build_object(
    'status',     'zugewiesen',
    'first_name', v_first_name,
    'progress',   jsonb_build_object(
                    'answered', v_answered,
                    'total',    coalesce(array_length(v_session.item_ids, 1), 0)),
    'expires_at', v_a.expires_at
  );
end;
$$;

comment on function public.platz_state() is
  'Kiosk-Poll: wartet | zugewiesen (+ Rufname ueber leads.first_name + '
  'Fortschritt + expires_at). Nur Platz-Konten (platz_devices). Traegt NIE '
  'session_id/student_id/lead_id/Auswertung — pgTAP pinnt die Schluesselmenge.';

create or replace function public.platz_next()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_a       platz_assignments;
  v_session lsa_sessions;
  v_next    uuid;
begin
  if not exists (select 1 from platz_devices where profile_id = auth.uid()) then
    raise exception 'platz_next: kein Platz-Konto' using errcode = '42501';
  end if;

  v_a := public.platz_current_assignment();
  if v_a.id is null then
    raise exception 'platz_next: keine aktive Zuweisung' using errcode = '42501';
  end if;

  select * into v_session from lsa_sessions where id = v_a.session_id;
  if not found or v_session.status <> 'in_progress' then
    raise exception 'platz_next: keine aktive Session' using errcode = '42501';
  end if;

  -- Das naechste offene Item — EXAKT die Ordnung aus lsa_submit (P01/P02):
  -- erstes item_id ohne Response-Zeile. Keine zweite Wahrheit.
  select i.id
    into v_next
    from unnest(v_session.item_ids) with ordinality as i(id, ord)
   where not exists (
           select 1 from lsa_responses r
            where r.session_id = v_session.id and r.task_id = i.id
         )
   order by i.ord
   limit 1;

  if v_next is null then
    return jsonb_build_object('item', null, 'done', true);
  end if;

  -- Der UNVERAENDERTE Builder — hier ist sein Tor fuer den Platz (§3.6(ii):
  -- das direkte authenticated-Grant ist zurueckgezogen, Abschnitt 7).
  return jsonb_build_object(
    'item', public.lsa_question_payload(v_next),
    'done', false
  );
end;
$$;

comment on function public.platz_next() is
  'Naechstes offenes Item der ZUGEWIESENEN Session — Payload aus dem '
  'unveraenderten lsa_question_payload. Kein Parameter: das Tablet kann nicht '
  'nach einer fremden Session oder task_id fragen.';

create or replace function public.platz_submit(
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
  v_a       platz_assignments;
  v_session lsa_sessions;
  v_open    uuid;
  v_claims  text;
  v_result  jsonb;
begin
  if not exists (select 1 from platz_devices where profile_id = auth.uid()) then
    raise exception 'platz_submit: kein Platz-Konto' using errcode = '42501';
  end if;

  v_a := public.platz_current_assignment();
  if v_a.id is null then
    raise exception 'platz_submit: keine aktive Zuweisung' using errcode = '42501';
  end if;

  select * into v_session from lsa_sessions where id = v_a.session_id;
  if not found or v_session.status <> 'in_progress' then
    raise exception 'platz_submit: keine aktive Session' using errcode = '42501';
  end if;

  -- p_task_id MUSS das aktuell offene Item sein — dieselbe Ordnung wie in
  -- platz_next/lsa_submit. Kein Vor-, kein Zurueckspringen, kein fremdes Item.
  select i.id
    into v_open
    from unnest(v_session.item_ids) with ordinality as i(id, ord)
   where not exists (
           select 1 from lsa_responses r
            where r.session_id = v_session.id and r.task_id = i.id
         )
   order by i.ord
   limit 1;

  if v_open is null or v_open <> p_task_id then
    raise exception 'platz_submit: nicht das aktuell offene Item'
      using errcode = 'P0001';
  end if;

  -- Durchreichen an die UNVERAENDERTE lsa_submit mit der Auftrags-Identitaet
  -- (Header oben). Alles Adressierende ist zu diesem Zeitpunkt geprueft:
  -- session_id aus der Zuweisung, p_task_id = offenes Item. p_duration_ms
  -- traegt die Zeit pro Aufgabe (Eltern-Report) — lsa_submit hat das Feld
  -- bereits, nichts wird erfunden.
  v_claims := current_setting('request.jwt.claims', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_a.created_by, 'role', 'authenticated')::text, true);

  v_result := public.lsa_submit(v_session.id, p_task_id, p_response, p_duration_ms);

  perform set_config('request.jwt.claims', coalesce(v_claims, ''), true);

  -- {ok, next}: kein correct, kein Score — die P01-Zusage der inneren RPC
  -- gilt unveraendert; next gehoert zur selben Session.
  return v_result;
end;
$$;

comment on function public.platz_submit(uuid, jsonb, integer) is
  'Antwort-Tor des Platzes: validiert p_task_id gegen das aktuell offene Item '
  'der ZUGEWIESENEN Session und reicht an die unveraenderte lsa_submit durch '
  '(Auftrags-Identitaet created_by, transaktionslokaler Claims-Tausch). '
  'Rueckgabe {ok, next} — kein Richtig/Falsch (CLAUDE §6).';

create or replace function public.platz_finish()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_a       platz_assignments;
  v_session lsa_sessions;
  v_claims  text;
begin
  if not exists (select 1 from platz_devices where profile_id = auth.uid()) then
    raise exception 'platz_finish: kein Platz-Konto' using errcode = '42501';
  end if;

  v_a := public.platz_current_assignment();
  if v_a.id is null then
    raise exception 'platz_finish: keine aktive Zuweisung' using errcode = '42501';
  end if;

  select * into v_session from lsa_sessions where id = v_a.session_id;
  if not found or v_session.status <> 'in_progress' then
    raise exception 'platz_finish: keine aktive Session' using errcode = '42501';
  end if;

  -- Die unveraenderte lsa_finish — ihr Rueckgabewert ist die AUSWERTUNG
  -- (result_summary) und wird hier bewusst VERWORFEN: der Platz erfaehrt nie
  -- Auswertungsdaten. Der Statuswechsel auf completed feuert den
  -- Release-Trigger (Abschnitt 6) — die Zuweisung endet im selben Moment.
  v_claims := current_setting('request.jwt.claims', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_a.created_by, 'role', 'authenticated')::text, true);

  perform public.lsa_finish(v_session.id);

  perform set_config('request.jwt.claims', coalesce(v_claims, ''), true);

  return jsonb_build_object('ok', true);
end;
$$;

comment on function public.platz_finish() is
  'Abschluss-Tor des Platzes: ruft die unveraenderte lsa_finish fuer die '
  'zugewiesene Session auf und VERWIRFT deren Auswertung — Rueckgabe ist exakt '
  '{ok:true}. Der completed-Status released die Zuweisung per Trigger.';

-- ============================================================================
-- 6. Release automatisch: Session zu Ende → Zuweisung zu Ende
--    Analog lsa_session_lead_fertig_trg (S7); lsa_finish bleibt byte-identisch.
--    'aborted' ist mit drin: eine abgebrochene Session soll den Platz genauso
--    freigeben — das macht den Release nur PROMPTER, nie einen Zugriff weiter
--    (alle Tore pruefen ohnehin status='in_progress').
-- ============================================================================

create or replace function public.lsa_session_platz_release()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update platz_assignments
     set released_at = now()
   where session_id = new.id
     and released_at is null;
  return new;
end;
$$;

drop trigger if exists lsa_session_platz_release_trg on lsa_sessions;
create trigger lsa_session_platz_release_trg
  after update of status on lsa_sessions
  for each row
  when (new.status in ('completed', 'aborted') and old.status is distinct from new.status)
  execute function public.lsa_session_platz_release();

-- ============================================================================
-- 7. §3.6(ii) der PLATZ-Analyse — der sauberere Schnitt, bewusst gewaehlt:
--    lsa_question_payload war an authenticated ge-grantet und traegt keine
--    Autorisierung — jedes eingeloggte Konto konnte fuer beliebige task_ids
--    das Frage-Payload ziehen (leakt beweisbar keine Loesung, aber es ist
--    nicht sessionsgebunden). Das Grant wird zurueckgezogen; erreichbar bleibt
--    der Builder ueber seine Tore: lsa_start/lsa_submit (Schueler, intern),
--    task_preview_payload (Coach/Admin, a02) und platz_next (Platz, oben).
--    Der Studenten-Client ruft die Funktion NICHT direkt (verifiziert: kein
--    .rpc('lsa_question_payload') in src/**). Funktionskoerper und uebrige
--    Grants (service_role) bleiben byte-identisch. Regression: inv2/inv3/
--    inv5/inv6/inv7/inv8 pruefen den Inhalts-Vertrag jetzt im Definer-Kontext;
--    die Nicht-Aufrufbarkeit pinnt s9_platz_mechanik.test.sql.
-- ============================================================================

revoke execute on function public.lsa_question_payload(uuid) from authenticated;

-- ============================================================================
-- 8. Execute-Grants (Postgres grantet neuen Funktionen automatisch an PUBLIC —
--    erst wegnehmen, dann gezielt geben; analog P01 §7 / a02 / S7)
-- ============================================================================

revoke execute on function public.platz_current_assignment()          from public;
revoke execute on function public.platz_assign(uuid, uuid)            from public;
revoke execute on function public.platz_release(uuid)                 from public;
revoke execute on function public.platz_state()                       from public;
revoke execute on function public.platz_next()                        from public;
revoke execute on function public.platz_submit(uuid, jsonb, integer)  from public;
revoke execute on function public.platz_finish()                      from public;
revoke execute on function public.lsa_session_platz_release()         from public;

grant execute on function public.platz_assign(uuid, uuid)           to authenticated, service_role;
grant execute on function public.platz_release(uuid)                to authenticated, service_role;
grant execute on function public.platz_state()                      to authenticated, service_role;
grant execute on function public.platz_next()                       to authenticated, service_role;
grant execute on function public.platz_submit(uuid, jsonb, integer) to authenticated, service_role;
grant execute on function public.platz_finish()                     to authenticated, service_role;

-- platz_current_assignment ist ein interner Helfer der SECURITY-DEFINER-Tore.
grant execute on function public.platz_current_assignment() to service_role;

commit;
