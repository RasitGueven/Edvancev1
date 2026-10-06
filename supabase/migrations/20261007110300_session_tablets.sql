-- R1.2 Tablets in der Session.
--
-- Entscheidung (Begruendung im PR): eigene Tabelle session_tablets statt
-- platz_assignments zu erweitern. platz_assignments.session_id ist NOT NULL mit
-- FK auf lsa_sessions, und platz_assign/platz_state/platz_current_assignment
-- und der Release-Trigger der LSA lesen sie (R0 Frage 2). Die LSA-Wege bleiben
-- so unveraendert. Gemeinsam bleibt das Geraet: platz_devices bekommt eine
-- Tablet-Nummer, ueber die der Coach "Tablet 1..5" waehlt.
--
-- Zuordnung ohne Identitaetstausch (R0 Frage 3): Jede Tablet-Funktion ermittelt
-- das Kind aus der aktiven Zeile in session_tablets fuer auth.uid() = Geraet.
-- Antworten tragen student_id (wer sass), geraet_id und angemeldet_als getrennt.

alter table public.platz_devices
  add column tablet_nr smallint
    constraint platz_devices_tablet_nr_check check (tablet_nr between 1 and 99);
create unique index platz_devices_tablet_nr_key on public.platz_devices (tablet_nr);

comment on column public.platz_devices.tablet_nr is
  'R1: Nummer, unter der der Coach das Geraet in der Session zuweist (Tablet 1..5).';

-- Bestand: "Platz 1" ist Tablet 1 (dbread 06.10.: genau ein Geraet).
update public.platz_devices
   set tablet_nr = substring(label from '^Platz ([1-9][0-9]?)$')::smallint
 where tablet_nr is null and label ~ '^Platz [1-9][0-9]?$';

create table public.session_tablets (
  id             uuid primary key default gen_random_uuid(),
  session_id     uuid not null,
  student_id     uuid not null,
  tablet_nr      smallint not null check (tablet_nr between 1 and 5),
  geraet_id      uuid not null references public.platz_devices(profile_id) on delete cascade,
  zugewiesen_von uuid references public.profiles(id) on delete set null,
  zugewiesen_am  timestamptz not null default clock_timestamp(),
  geloest_am     timestamptz,
  geloest_von    uuid references public.profiles(id) on delete set null,
  -- nur gebuchte Kinder dieser Session
  foreign key (session_id, student_id)
    references public.session_students(session_id, student_id) on delete cascade
);

create unique index session_tablets_kind_aktiv on public.session_tablets (session_id, student_id)
  where geloest_am is null;
create unique index session_tablets_nr_aktiv on public.session_tablets (session_id, tablet_nr)
  where geloest_am is null;
create unique index session_tablets_geraet_aktiv on public.session_tablets (geraet_id)
  where geloest_am is null;

comment on table public.session_tablets is
  'R1: Tablet-Zuweisung Kind <-> Geraet in einer coaching_session (hoechstens 5 aktiv). Schreiben nur ueber tablet_zuweisen/tablet_loesen.';

alter table public.session_tablets enable row level security;
revoke all on public.session_tablets from public, anon, authenticated;

-- Aktiver Platz des aufrufenden Geraets in einer laufenden Session; wirft 42501.
create function public.session_tablet_platz(p_session_id uuid, p_wer text)
returns public.session_tablets
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  t public.session_tablets;
begin
  select st.* into t
    from public.session_tablets st
    join public.coaching_sessions cs on cs.id = st.session_id
   where st.session_id = p_session_id
     and st.geraet_id = auth.uid()
     and st.geloest_am is null
     and cs.status = 'active';
  if not found then
    raise exception '%: kein zugewiesener Platz an diesem Tablet', p_wer using errcode = '42501';
  end if;
  return t;
end;
$$;

-- Kind -> Lead (fuer lead_themen): provisorische Kinder ueber students.lead_id,
-- konvertierte ueber leads.converted_student_id (S0-Befund; dbread 06.10.:
-- 14 bzw. 11 Kinder, kein Widerspruch, hoechstens ein Lead je Kind).
create function public.session_lead_von_kind(p_student_id uuid)
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(
    (select s.lead_id from public.students s where s.id = p_student_id),
    (select l.id from public.leads l where l.converted_student_id = p_student_id
      order by l.konvertiert_am desc nulls last, l.created_at desc limit 1))
$$;

create function public.session_kind_name(p_student_id uuid)
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(
    (select l.full_name from public.leads l where l.id = public.session_lead_von_kind(p_student_id)),
    (select p.full_name from public.students s join public.profiles p on p.id = s.profile_id
      where s.id = p_student_id))
$$;

create function public.tablet_zuweisen(p_session_id uuid, p_student_id uuid, p_tablet_nr int)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  s      public.coaching_sessions;
  v_ger  uuid;
  v_id   uuid;
begin
  s := public.session_coach_pruefen(p_session_id, 'tablet_zuweisen');
  if s.status <> 'active' then
    raise exception 'tablet_zuweisen: Session laeuft nicht (erst session_starten)' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.session_students
                  where session_id = p_session_id and student_id = p_student_id) then
    raise exception 'tablet_zuweisen: Kind ist in dieser Session nicht gebucht' using errcode = 'P0001',
      hint = 'nicht_gebucht';
  end if;
  if exists (select 1 from public.session_tablets
              where session_id = p_session_id and student_id = p_student_id and geloest_am is null) then
    raise exception 'tablet_zuweisen: Kind hat schon ein Tablet (erst loesen)' using errcode = 'P0001',
      hint = 'schon_zugewiesen';
  end if;
  if (select count(*) from public.session_tablets
       where session_id = p_session_id and geloest_am is null) >= 5 then
    raise exception 'tablet_zuweisen: hoechstens 5 Kinder im Raum' using errcode = 'P0001', hint = 'raum_voll';
  end if;

  select profile_id into v_ger from public.platz_devices where tablet_nr = p_tablet_nr;
  if v_ger is null then
    raise exception 'tablet_zuweisen: Tablet % ist nicht eingerichtet', p_tablet_nr using errcode = 'P0002',
      hint = 'tablet_unbekannt';
  end if;
  if exists (select 1 from public.session_tablets where geraet_id = v_ger and geloest_am is null)
     or exists (select 1 from public.platz_assignments a where a.platz_profile_id = v_ger
                 and a.released_at is null and a.expires_at > now()) then
    raise exception 'tablet_zuweisen: Tablet % ist belegt', p_tablet_nr using errcode = 'P0001',
      hint = 'tablet_belegt';
  end if;

  insert into public.session_tablets (session_id, student_id, tablet_nr, geraet_id, zugewiesen_von)
  values (p_session_id, p_student_id, p_tablet_nr, v_ger, auth.uid())
  returning id into v_id;

  -- Entscheidung 2: die Zuweisung setzt die Anwesenheit.
  update public.session_students set attendance = 'present'
   where session_id = p_session_id and student_id = p_student_id;

  if public.session_phase(p_session_id, p_student_id) is null then
    perform public.session_ereignis(p_session_id, p_student_id, 'phase_wechsel',
                                    jsonb_build_object('phase', 'checkin'));
  end if;
  return v_id;
end;
$$;

-- Loest den Platz. Die Anwesenheit bleibt (das Kind war da); eine falsche
-- Zuweisung korrigiert der Coach durch Loesen und neues Zuweisen.
create function public.tablet_loesen(p_session_id uuid, p_student_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.session_coach_pruefen(p_session_id, 'tablet_loesen');
  update public.session_tablets
     set geloest_am = clock_timestamp(), geloest_von = auth.uid()
   where session_id = p_session_id and student_id = p_student_id and geloest_am is null;
  if not found then
    raise exception 'tablet_loesen: Kind hat kein Tablet' using errcode = 'P0002';
  end if;
end;
$$;

-- Phase eines Kindes wechseln: vom Tablet des Kindes oder vom Coach.
create function public.phase_setzen(p_session_id uuid, p_student_id uuid, p_phase text)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_kind uuid := p_student_id;
begin
  if p_phase is null or p_phase not in ('checkin', 'warmup', 'kern', 'checkout') then
    raise exception 'phase_setzen: unbekannte Phase %', p_phase using errcode = '22023';
  end if;
  if public.session_ist_coach(p_session_id) then
    if not exists (select 1 from public.session_tablets where session_id = p_session_id
                    and student_id = p_student_id and geloest_am is null) then
      raise exception 'phase_setzen: Kind hat kein Tablet' using errcode = 'P0001';
    end if;
  else
    v_kind := (public.session_tablet_platz(p_session_id, 'phase_setzen')).student_id;
    if p_student_id is not null and p_student_id <> v_kind then
      raise exception 'phase_setzen: nur der eigene Platz' using errcode = '42501';
    end if;
  end if;
  if public.session_phase(p_session_id, v_kind) is distinct from p_phase then
    perform public.session_ereignis(p_session_id, v_kind, 'phase_wechsel', jsonb_build_object('phase', p_phase));
  end if;
end;
$$;

revoke all on function
  public.session_tablet_platz(uuid, text), public.session_lead_von_kind(uuid), public.session_kind_name(uuid),
  public.tablet_zuweisen(uuid, uuid, int), public.tablet_loesen(uuid, uuid), public.phase_setzen(uuid, uuid, text)
  from public, anon, authenticated;
grant execute on function
  public.tablet_zuweisen(uuid, uuid, int), public.tablet_loesen(uuid, uuid), public.phase_setzen(uuid, uuid, text)
  to authenticated;
