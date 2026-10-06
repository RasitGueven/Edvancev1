-- R1.2 Check-in je Kind (Entscheidungen 8 und 9).
--
-- Das Kind fuellt am Tablet Stimmung, Klassenarbeit und "Macht ihr noch dasselbe
-- Thema?" aus (checkin_kind_speichern). Das System schlaegt den Fall vor
-- (fall_vorschlag), der Coach entscheidet getrennt davon (fall_coach,
-- Entscheidung 3: eine Entscheidung ueberschreibt nie den Vorschlag).
--
-- Fall-Rangfolge (Entscheidung 9): Klassenarbeit (innerhalb ka_tage ab dem
-- Session-Datum) vor Schulthema (lead_themen 'aktuell') vor Lernpfad.
-- Ziel der Stunde: Klassenarbeit -> deren Thema, Schulthema -> das aktuelle
-- Thema, Lernpfad -> offen bis A1 (naechste_luecke, offener Punkt).

create table public.session_checkin (
  session_id              uuid not null references public.coaching_sessions(id) on delete restrict,
  student_id              uuid not null references public.students(id) on delete cascade,
  stimmung                text check (stimmung in ('gut', 'geht_so', 'angespannt')),
  klassenarbeit_datum     date,
  klassenarbeit_thema_key text references public.themen(thema_key),
  thema_antwort           text check (thema_antwort in ('noch_dran', 'neu')),
  thema_stichwort         text check (thema_stichwort is null or nullif(btrim(thema_stichwort), '') is not null),
  fall_vorschlag          text check (fall_vorschlag in ('klassenarbeit', 'schulthema', 'lernpfad')),
  fall_coach              text check (fall_coach in ('klassenarbeit', 'schulthema', 'lernpfad')),
  ziel_thema_key          text references public.themen(thema_key),
  kind_am                 timestamptz,
  coach_am                timestamptz,
  coach_von               uuid references public.profiles(id) on delete set null,
  primary key (session_id, student_id),
  -- nur gebuchte Kinder (no action: eine Buchung mit Verlauf bleibt)
  foreign key (session_id, student_id)
    references public.session_students(session_id, student_id),
  constraint session_checkin_stichwort_nur_bei_neu check (thema_stichwort is null or thema_antwort = 'neu')
);

comment on table public.session_checkin is
  'R1: Check-in je Kind. fall_vorschlag (System) und fall_coach (Entscheidung) getrennt. Schreiben nur ueber checkin_kind_speichern/checkin_coach_setzen.';

alter table public.session_checkin enable row level security;
revoke all on public.session_checkin from public, anon, authenticated;

-- Aktuelles Schulthema eines Kindes (ueber den Lead), das juengste 'aktuell'.
create function public.session_schulthema(p_student_id uuid)
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select lt.thema_key from public.lead_themen lt
   where lt.lead_id = public.session_lead_von_kind(p_student_id) and lt.status = 'aktuell'
   order by lt.angelegt desc limit 1
$$;

create function public.session_fall_berechnen(p_session_id uuid, p_student_id uuid)
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
    when c.klassenarbeit_datum is not null
         and c.klassenarbeit_datum >= (cs.scheduled_at at time zone 'Europe/Berlin')::date
         and c.klassenarbeit_datum - (cs.scheduled_at at time zone 'Europe/Berlin')::date
             <= public.session_wert_zahl(p_session_id, 'ka_tage')
      then 'klassenarbeit'
    when public.session_schulthema(p_student_id) is not null then 'schulthema'
    else 'lernpfad'
  end
    from public.coaching_sessions cs
    left join public.session_checkin c on c.session_id = cs.id and c.student_id = p_student_id
   where cs.id = p_session_id
$$;

-- Schreibt Vorschlag und Ziel neu (nach jeder Aenderung am Check-in).
create function public.session_checkin_ableiten(p_session_id uuid, p_student_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_fall text := public.session_fall_berechnen(p_session_id, p_student_id);
begin
  update public.session_checkin c
     set fall_vorschlag = v_fall,
         ziel_thema_key = case coalesce(c.fall_coach, v_fall)
                            when 'klassenarbeit' then c.klassenarbeit_thema_key
                            when 'schulthema' then public.session_schulthema(p_student_id)
                            else null end
   where c.session_id = p_session_id and c.student_id = p_student_id;
end;
$$;

create function public.fall_vorschlag(p_session_id uuid, p_student_id uuid)
returns text
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.session_coach_pruefen(p_session_id, 'fall_vorschlag');
  if not exists (select 1 from public.session_students where session_id = p_session_id and student_id = p_student_id) then
    raise exception 'fall_vorschlag: Kind ist in dieser Session nicht gebucht' using errcode = 'P0002';
  end if;
  return public.session_fall_berechnen(p_session_id, p_student_id);
end;
$$;

-- Vom Tablet: das Kind ergibt sich aus dem Platz. Danach beginnt das Warm-up
-- von selbst (Dummy Check-in: "Das Warm-up startet von selbst").
create function public.checkin_kind_speichern(
  p_session_id              uuid,
  p_stimmung                text,
  p_klassenarbeit_datum     date,
  p_klassenarbeit_thema_key text,
  p_thema_antwort           text,
  p_thema_stichwort         text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  t public.session_tablets := public.session_tablet_platz(p_session_id, 'checkin_kind_speichern');
begin
  if p_stimmung is null or p_thema_antwort is null then
    raise exception 'checkin_kind_speichern: Stimmung und Thema-Antwort sind Pflicht' using errcode = '22023';
  end if;
  insert into public.session_checkin as c (session_id, student_id, stimmung, klassenarbeit_datum,
         klassenarbeit_thema_key, thema_antwort, thema_stichwort, kind_am)
  values (p_session_id, t.student_id, p_stimmung, p_klassenarbeit_datum, p_klassenarbeit_thema_key,
          p_thema_antwort, case when p_thema_antwort = 'neu' then nullif(btrim(p_thema_stichwort), '') end,
          clock_timestamp())
  on conflict (session_id, student_id) do update
     set stimmung = excluded.stimmung, klassenarbeit_datum = excluded.klassenarbeit_datum,
         klassenarbeit_thema_key = excluded.klassenarbeit_thema_key, thema_antwort = excluded.thema_antwort,
         thema_stichwort = excluded.thema_stichwort, kind_am = excluded.kind_am;

  perform public.session_checkin_ableiten(p_session_id, t.student_id);
  if public.session_phase(p_session_id, t.student_id) = 'checkin' then
    perform public.session_ereignis(p_session_id, t.student_id, 'phase_wechsel', jsonb_build_object('phase', 'warmup'));
  end if;
  return jsonb_build_object('fertig', true);
end;
$$;

-- Vom Coach: Fall waehlen und/oder ein neues Schulthema setzen.
-- Neues Schulthema: das bisherige 'aktuell' desselben Fachs wird 'behandelt',
-- das neue 'aktuell' (Entscheidung 9). Geschrieben wird lead_themen wie im
-- Erstgespraech (Upsert auf (lead_id, thema_key), quelle 'gespraech').
-- Abweichung: lead_thema_setzen loescht das alte 'aktuell' und ist nur fuer
-- Admins -> offene-punkte-r1.md, Punkt 3.
create function public.checkin_coach_setzen(
  p_session_id uuid,
  p_student_id uuid,
  p_fall       text default null,
  p_thema_key  text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_lead uuid;
  v_fach text;
begin
  perform public.session_coach_pruefen(p_session_id, 'checkin_coach_setzen');
  if not exists (select 1 from public.session_students where session_id = p_session_id and student_id = p_student_id) then
    raise exception 'checkin_coach_setzen: Kind ist in dieser Session nicht gebucht' using errcode = 'P0002';
  end if;
  if p_fall is not null and p_fall not in ('klassenarbeit', 'schulthema', 'lernpfad') then
    raise exception 'checkin_coach_setzen: unbekannter Fall %', p_fall using errcode = '22023';
  end if;

  if p_thema_key is not null then
    select fach into v_fach from public.themen where thema_key = p_thema_key;
    if v_fach is null then
      raise exception 'checkin_coach_setzen: unbekanntes Thema %', p_thema_key using errcode = '22023';
    end if;
    v_lead := public.session_lead_von_kind(p_student_id);
    if v_lead is null then
      raise exception 'checkin_coach_setzen: zum Kind gibt es keinen Lead (lead_themen)' using errcode = 'P0002',
        hint = 'kein_lead';
    end if;
    update public.lead_themen set status = 'behandelt'
     where lead_id = v_lead and fach = v_fach and status = 'aktuell' and thema_key <> p_thema_key;
    insert into public.lead_themen (lead_id, fach, thema_key, status, quelle, angelegt)
    values (v_lead, v_fach, p_thema_key, 'aktuell', 'gespraech', now())
    on conflict (lead_id, thema_key) do update
       set fach = excluded.fach, status = 'aktuell', quelle = excluded.quelle, angelegt = excluded.angelegt;
  end if;

  insert into public.session_checkin as c (session_id, student_id, fall_coach, coach_am, coach_von)
  values (p_session_id, p_student_id, p_fall, clock_timestamp(), auth.uid())
  on conflict (session_id, student_id) do update
     set fall_coach = coalesce(excluded.fall_coach, c.fall_coach),
         coach_am = excluded.coach_am, coach_von = excluded.coach_von;

  perform public.session_checkin_ableiten(p_session_id, p_student_id);
  return (select jsonb_build_object('fall_vorschlag', c.fall_vorschlag, 'fall_coach', c.fall_coach,
                                    'ziel_thema_key', c.ziel_thema_key)
            from public.session_checkin c where c.session_id = p_session_id and c.student_id = p_student_id);
end;
$$;

revoke all on function
  public.session_schulthema(uuid), public.session_fall_berechnen(uuid, uuid),
  public.session_checkin_ableiten(uuid, uuid), public.fall_vorschlag(uuid, uuid),
  public.checkin_kind_speichern(uuid, text, date, text, text, text),
  public.checkin_coach_setzen(uuid, uuid, text, text)
  from public, anon, authenticated;
grant execute on function
  public.fall_vorschlag(uuid, uuid), public.checkin_kind_speichern(uuid, text, date, text, text, text),
  public.checkin_coach_setzen(uuid, uuid, text, text)
  to authenticated;
