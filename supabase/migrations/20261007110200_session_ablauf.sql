-- R1.1 Ablauf der Session: Laufzustand an coaching_sessions, Ereignisprotokoll,
-- gemeinsame Rechte-Helfer und session_starten.
--
-- Status: Die Werte von coaching_sessions.status bleiben erhalten
-- (dbread 06.10.: done 65, upcoming 7, active 0; gelesen in
-- src/types/session.ts:14 und src/lib/coachKennzahlen.ts:15). Sie tragen die
-- Bedeutung aus dem Bauauftrag: upcoming = geplant, active = laeuft,
-- done = abgeschlossen. Ein Umbenennen wuerde bestehende Leser brechen.
--
-- Neue Spalten: gestartet_am, beendet_am, einstellungen (Snapshot der
-- Stellschrauben beim Start). Ein Schutz-Trigger laesst Status, Start, Ende und
-- Snapshot nur ueber die Session-Funktionen (oder einen Systemaufruf) aendern —
-- die bestehende RLS-Regel coaching_sessions_coach_rw (ALL fuer den eigenen
-- Coach) bleibt dafuer unangetastet.

alter table public.coaching_sessions
  add column gestartet_am  timestamptz,
  add column beendet_am    timestamptz,
  add column einstellungen jsonb
    constraint coaching_sessions_einstellungen_objekt
    check (einstellungen is null or jsonb_typeof(einstellungen) = 'object');

comment on column public.coaching_sessions.einstellungen is
  'R1: Snapshot aller session_einstellungen beim Start (session_starten). Spaetere Aenderungen der Stellschrauben aendern ihn nicht.';

-- Markiert die laufende Transaktion als Session-Funktion (nur fuer den Trigger).
create function public.session_rpc_markieren()
returns void
language sql
volatile
set search_path = public, pg_temp
as $$
  select set_config('edvance.session_rpc', '1', true);
$$;

create function public.coaching_sessions_laufzustand_guard()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if coalesce(current_setting('edvance.session_rpc', true), '') = '1'
     or public.ist_systemaufruf() then
    return new;
  end if;
  if tg_op = 'INSERT' then
    if new.gestartet_am is not null or new.beendet_am is not null or new.einstellungen is not null then
      raise exception 'coaching_sessions: Laufzustand nur ueber session_starten/session_abschliessen'
        using errcode = '42501';
    end if;
  elsif new.status is distinct from old.status
     or new.gestartet_am is distinct from old.gestartet_am
     or new.beendet_am is distinct from old.beendet_am
     or new.einstellungen is distinct from old.einstellungen then
    raise exception 'coaching_sessions: Status und Laufzustand nur ueber session_starten/session_abschliessen'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger coaching_sessions_laufzustand_trg
  before insert or update on public.coaching_sessions
  for each row execute function public.coaching_sessions_laufzustand_guard();

-- Ereignisprotokoll, nur anhaengen (Entscheidung 13/14/15, R0 Frage 4).
create table public.session_ereignisse (
  id         bigint generated always as identity primary key,
  session_id uuid not null references public.coaching_sessions(id) on delete cascade,
  student_id uuid references public.students(id) on delete cascade,
  typ        text not null check (typ in ('phase_wechsel', 'hinweis', 'erklaerschritt', 'check', 'signal',
                                          'signal_erledigt', 'eingriff', 'entscheidung_pfad')),
  payload    jsonb not null default '{}'::jsonb check (jsonb_typeof(payload) = 'object'),
  zeit       timestamptz not null default clock_timestamp(),
  von        uuid references public.profiles(id) on delete set null
);

create index session_ereignisse_kind_idx on public.session_ereignisse (session_id, student_id, typ, zeit);

comment on table public.session_ereignisse is
  'R1: Ereignisse einer Session (append-only). Schreiben nur ueber Session-Funktionen; Lesen nur ueber coach_raum_live/coach_kind_detail.';

-- Nur anhaengen: kein UPDATE, kein direktes DELETE. Kaskaden beim Loeschen der
-- Session oder des Kindes (DSGVO) laufen ueber RI-Trigger, also mit Tiefe > 1.
create function public.session_nur_anhaengen()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'DELETE' and pg_trigger_depth() > 1 then
    return old;
  end if;
  raise exception '%: Rohdaten werden nur angehaengt', tg_table_name using errcode = '42501';
end;
$$;

create trigger session_ereignisse_nur_anhaengen
  before update or delete on public.session_ereignisse
  for each row execute function public.session_nur_anhaengen();

alter table public.session_ereignisse enable row level security;
revoke all on public.session_ereignisse from public, anon, authenticated;

-- ── Helfer ────────────────────────────────────────────────────────────────

-- Darf der Aufrufer die Session als Coach fuehren? Admin oder ihr Coach.
create function public.session_ist_coach(p_session_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case public.get_my_role()
    when 'admin' then exists (select 1 from public.coaching_sessions where id = p_session_id)
    when 'coach' then exists (select 1 from public.coaching_sessions
                               where id = p_session_id and coach_id = auth.uid())
    else false
  end
$$;

-- Wie oben, aber wirft: P0002 ohne Session, 42501 ohne Recht.
create function public.session_coach_pruefen(p_session_id uuid, p_wer text)
returns public.coaching_sessions
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  s public.coaching_sessions;
begin
  select * into s from public.coaching_sessions where id = p_session_id;
  if not found then
    raise exception '%: Session nicht gefunden', p_wer using errcode = 'P0002';
  end if;
  if not public.session_ist_coach(p_session_id) then
    raise exception '%: nur der Coach der Session oder ein Admin', p_wer using errcode = '42501';
  end if;
  return s;
end;
$$;

-- Stellschraube einer Session: aus dem Snapshot, vor dem Start aus der Tabelle.
create function public.session_wert(p_session_id uuid, p_schluessel text)
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(
    (select cs.einstellungen -> p_schluessel from public.coaching_sessions cs where cs.id = p_session_id),
    (select e.wert from public.session_einstellungen e where e.schluessel = p_schluessel))
$$;

create function public.session_wert_zahl(p_session_id uuid, p_schluessel text)
returns numeric
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select (public.session_wert(p_session_id, p_schluessel) #>> '{}')::numeric
$$;

create function public.session_ereignis(p_session_id uuid, p_student_id uuid, p_typ text, p_payload jsonb)
returns void
language sql
volatile
security definer
set search_path = public, pg_temp
as $$
  insert into public.session_ereignisse (session_id, student_id, typ, payload, von)
  values (p_session_id, p_student_id, p_typ, coalesce(p_payload, '{}'::jsonb), auth.uid());
$$;

-- Aktuelle Phase eines Kindes: das letzte phase_wechsel-Ereignis.
create function public.session_phase(p_session_id uuid, p_student_id uuid)
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select e.payload ->> 'phase'
    from public.session_ereignisse e
   where e.session_id = p_session_id and e.student_id = p_student_id and e.typ = 'phase_wechsel'
   order by e.zeit desc, e.id desc
   limit 1
$$;

-- ── session_starten ───────────────────────────────────────────────────────
create function public.session_starten(p_session_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  s    public.coaching_sessions;
  v_sn jsonb;
begin
  s := public.session_coach_pruefen(p_session_id, 'session_starten');
  if s.status <> 'upcoming' then
    raise exception 'session_starten: Session ist nicht geplant (Status %)', s.status using errcode = 'P0001';
  end if;

  select jsonb_object_agg(schluessel, wert order by schluessel) into v_sn from public.session_einstellungen;

  perform public.session_rpc_markieren();
  update public.coaching_sessions
     set status = 'active', gestartet_am = now(), einstellungen = v_sn
   where id = p_session_id;
  perform set_config('edvance.session_rpc', '', true);
  return v_sn;
end;
$$;

comment on function public.session_starten(uuid) is
  'R1: Coach der Session oder Admin startet eine geplante Session (upcoming -> active) und friert die Stellschrauben ein.';

-- Consensus-Check Befund 1: Die bestehenden Regeln coaching_sessions_coach_rw
-- und session_students_coach_rw (FOR ALL) erlauben dem Coach DELETE. Ueber die
-- Kaskade wuerden sonst Antworten und Ereignisse verschwinden. Deshalb loeschen
-- eine Session mit Rohdaten nur Admin oder Systemaufruf (z. B. DSGVO-Loeschung).
-- Den Schutz fuer session_students legt 20261007110500 an (braucht session_antworten).
create function public.coaching_sessions_loeschschutz()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.ist_systemaufruf() and coalesce(public.get_my_role(), '') <> 'admin'
     and (old.status <> 'upcoming'
          or exists (select 1 from public.session_ereignisse e where e.session_id = old.id)) then
    raise exception 'coaching_sessions: eine gestartete Session loescht nur ein Admin' using errcode = '42501';
  end if;
  return old;
end;
$$;

create trigger coaching_sessions_loeschschutz_trg
  before delete on public.coaching_sessions
  for each row execute function public.coaching_sessions_loeschschutz();

revoke all on function
  public.session_rpc_markieren(), public.coaching_sessions_laufzustand_guard(),
  public.coaching_sessions_loeschschutz(),
  public.session_nur_anhaengen(), public.session_ist_coach(uuid), public.session_coach_pruefen(uuid, text),
  public.session_wert(uuid, text), public.session_wert_zahl(uuid, text),
  public.session_ereignis(uuid, uuid, text, jsonb), public.session_phase(uuid, uuid),
  public.session_starten(uuid)
  from public, anon, authenticated;
grant execute on function public.session_starten(uuid) to authenticated;
