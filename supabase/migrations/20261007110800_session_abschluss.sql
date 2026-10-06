-- R1.4 Check-out und Abschluss (Entscheidungen 12 und 13).
--
-- session_kind_abschluss: Satz an das Kind, Coach-Notiz, Flags, Quest-Termin,
-- Exit-Ergebnis. Setzen per abschluss_setzen (Coach) bzw. quest_termin_setzen
-- (Coach oder Tablet des Kindes).
-- session_abschliessen: Anwesenheit final (planned -> unexcused; verbraucht die
-- Einheit wie einheit_verbraucht), Tablets frei, Notiz und Flags als Notizen
-- der Schuelerakte (notiz_anlegen: Wortliste, Coach nur in aktive Akten,
-- audit_log), Zusammenfassung je Kind (Eingriffe ab Stufe 3 mit Fehlbild,
-- Aufgaben, Hinweise), Status done. Der Einstellungs-Snapshot steht seit dem
-- Start an coaching_sessions.einstellungen.

create table public.session_kind_abschluss (
  session_id             uuid not null,
  student_id             uuid not null,
  satz_text              text check (satz_text is null or nullif(btrim(satz_text), '') is not null),
  satz_gesagt            boolean not null default false,
  notiz                  text check (notiz is null or nullif(btrim(notiz), '') is not null),
  flag_eltern            boolean not null default false,
  flag_pfad              boolean not null default false,
  quest_termin           timestamptz,
  quest_termin_von       uuid references public.profiles(id) on delete set null,
  exit_ergebnis          jsonb check (exit_ergebnis is null or (jsonb_typeof(exit_ergebnis -> 'richtig') = 'number'
                                       and jsonb_typeof(exit_ergebnis -> 'gesamt') = 'number')),
  zusammenfassung        jsonb,
  notiz_id               uuid references public.schueler_notizen(id) on delete set null,
  in_akte_am             timestamptz,
  flag_eltern_erledigt_am  timestamptz,
  flag_eltern_erledigt_von uuid references public.profiles(id) on delete set null,
  flag_pfad_erledigt_am    timestamptz,
  flag_pfad_erledigt_von   uuid references public.profiles(id) on delete set null,
  aktualisiert_am        timestamptz not null default clock_timestamp(),
  aktualisiert_von       uuid references public.profiles(id) on delete set null,
  primary key (session_id, student_id),
  foreign key (session_id, student_id)
    references public.session_students(session_id, student_id) on delete cascade
);

comment on table public.session_kind_abschluss is
  'R1: Check-out je Kind und Zusammenfassung fuer die Akte. Schreiben nur ueber abschluss_setzen/quest_termin_setzen/session_abschliessen/session_flag_erledigen.';

alter table public.session_kind_abschluss enable row level security;
revoke all on public.session_kind_abschluss from public, anon, authenticated;

-- Felder mit null bleiben unveraendert. Die Notiz wird schon hier gegen die
-- Wortliste geprueft, damit der Abschluss nicht daran scheitert.
create function public.abschluss_setzen(
  p_session_id uuid, p_student_id uuid,
  p_satz_text text default null, p_satz_gesagt boolean default null, p_notiz text default null,
  p_flag_eltern boolean default null, p_flag_pfad boolean default null, p_exit_ergebnis jsonb default null
)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_treffer text;
begin
  perform public.session_kind_pruefen(p_session_id, p_student_id, 'abschluss_setzen');
  if (select status from public.coaching_sessions where id = p_session_id) = 'done' then
    raise exception 'abschluss_setzen: Session ist abgeschlossen' using errcode = 'P0001';
  end if;
  v_treffer := public.akte_wortliste_treffer('gesundheit', coalesce(p_notiz, ''));
  if v_treffer is not null then
    raise exception 'abschluss_setzen: Die Notiz enthaelt "%". Das deutet auf eine Gesundheitsangabe hin. Bitte umformulieren.', v_treffer
      using errcode = '22023', hint = 'gesundheitsbegriff:' || v_treffer;
  end if;

  insert into public.session_kind_abschluss as k (session_id, student_id, satz_text, satz_gesagt, notiz,
         flag_eltern, flag_pfad, exit_ergebnis, aktualisiert_von)
  values (p_session_id, p_student_id, nullif(btrim(p_satz_text), ''), coalesce(p_satz_gesagt, false),
          nullif(btrim(p_notiz), ''), coalesce(p_flag_eltern, false), coalesce(p_flag_pfad, false),
          p_exit_ergebnis, auth.uid())
  on conflict (session_id, student_id) do update
     set satz_text = coalesce(nullif(btrim(p_satz_text), ''), k.satz_text),
         satz_gesagt = coalesce(p_satz_gesagt, k.satz_gesagt),
         notiz = coalesce(nullif(btrim(p_notiz), ''), k.notiz),
         flag_eltern = coalesce(p_flag_eltern, k.flag_eltern),
         flag_pfad = coalesce(p_flag_pfad, k.flag_pfad),
         exit_ergebnis = coalesce(p_exit_ergebnis, k.exit_ergebnis),
         aktualisiert_am = clock_timestamp(), aktualisiert_von = auth.uid();
end;
$$;

-- Quest-Termin: das Kind waehlt ihn am Tablet (p_student_id dann null oder
-- der eigene Platz), der Coach kann ihn setzen. Quests selbst: Paket Q1.
create function public.quest_termin_setzen(p_session_id uuid, p_student_id uuid, p_termin timestamptz)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_kind uuid := p_student_id;
begin
  if public.session_ist_coach(p_session_id) then
    perform public.session_kind_pruefen(p_session_id, p_student_id, 'quest_termin_setzen');
  else
    v_kind := (public.session_tablet_platz(p_session_id, 'quest_termin_setzen')).student_id;
    if p_student_id is not null and p_student_id <> v_kind then
      raise exception 'quest_termin_setzen: nur der eigene Platz' using errcode = '42501';
    end if;
  end if;
  if p_termin is null or p_termin <= now() or p_termin > now() + interval '14 days' then
    raise exception 'quest_termin_setzen: Termin in den naechsten 14 Tagen' using errcode = '22023';
  end if;
  insert into public.session_kind_abschluss as k (session_id, student_id, quest_termin, quest_termin_von, aktualisiert_von)
  values (p_session_id, v_kind, p_termin, auth.uid(), auth.uid())
  on conflict (session_id, student_id) do update
     set quest_termin = excluded.quest_termin, quest_termin_von = excluded.quest_termin_von,
         aktualisiert_am = clock_timestamp(), aktualisiert_von = auth.uid();
end;
$$;

create function public.session_abschliessen(p_session_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  s       public.coaching_sessions := public.session_coach_pruefen(p_session_id, 'session_abschliessen');
  k       record;
  v_datum text;
  v_nid   uuid;
  v_n     int := 0;
  v_ohne  jsonb := '[]'::jsonb;
  v_text  text;
begin
  select * into s from public.coaching_sessions where id = p_session_id for update;
  if s.status <> 'active' then
    raise exception 'session_abschliessen: Session laeuft nicht (Status %)', s.status using errcode = 'P0001';
  end if;
  v_datum := to_char(s.scheduled_at at time zone 'Europe/Berlin', 'DD.MM.YYYY');

  -- Anwesenheit final: wer nie ein Tablet bekam und noch geplant ist, war nicht da.
  update public.session_students set attendance = 'unexcused'
   where session_id = p_session_id and attendance = 'planned';
  update public.session_tablets set geloest_am = clock_timestamp(), geloest_von = auth.uid()
   where session_id = p_session_id and geloest_am is null;

  for k in
    select ss.student_id, ss.attendance from public.session_students ss where ss.session_id = p_session_id
  loop
    insert into public.session_kind_abschluss (session_id, student_id, aktualisiert_von)
    values (p_session_id, k.student_id, auth.uid())
    on conflict (session_id, student_id) do nothing;

    -- Consensus-Check Befund 2: Notiz und Flags je Kind in eigenem Block. Hat ein
    -- Kind keine (aktive) Akte mehr, scheitert nicht der ganze Abschluss; das Kind
    -- steht dann in 'nicht_in_akte' und die Werte bleiben in session_kind_abschluss.
    v_nid := null;
    begin
      v_text := (select notiz from public.session_kind_abschluss where session_id = p_session_id and student_id = k.student_id);
      if v_text is not null then
        v_nid := public.notiz_anlegen(k.student_id, 'lernen', v_text);
      end if;
      if (select flag_eltern from public.session_kind_abschluss where session_id = p_session_id and student_id = k.student_id) then
        perform public.notiz_anlegen(k.student_id, 'organisatorisch', 'Session ' || v_datum || ': Elternkontakt nötig');
      end if;
      if (select flag_pfad from public.session_kind_abschluss where session_id = p_session_id and student_id = k.student_id) then
        perform public.notiz_anlegen(k.student_id, 'lernen', 'Session ' || v_datum || ': Pfad passt nicht');
      end if;
    exception when insufficient_privilege or no_data_found then
      v_nid := null;
      v_ohne := v_ohne || to_jsonb(k.student_id);
    end;

    update public.session_kind_abschluss a
       set notiz_id = v_nid,
           in_akte_am = case when v_ohne @> to_jsonb(k.student_id) then null else clock_timestamp() end,
           exit_ergebnis = coalesce(a.exit_ergebnis, (
             select jsonb_build_object('richtig', count(distinct r.task_id) filter (where r.ergebnis = 'richtig'),
                                       'gesamt', count(distinct r.task_id))
               from public.session_antworten r where r.session_id = p_session_id and r.student_id = k.student_id
                and r.phase = 'checkout' having count(*) > 0)),
           zusammenfassung = jsonb_build_object(
             'anwesenheit', (select attendance from public.session_students
                              where session_id = p_session_id and student_id = k.student_id),
             'aufgaben', (select count(distinct r.task_id) from public.session_antworten r
                           where r.session_id = p_session_id and r.student_id = k.student_id),
             'antworten', (select count(*) from public.session_antworten r
                            where r.session_id = p_session_id and r.student_id = k.student_id),
             'richtig', (select count(*) from public.session_antworten r where r.session_id = p_session_id
                          and r.student_id = k.student_id and r.ergebnis = 'richtig'),
             'hinweise', (select count(*) from public.session_ereignisse e where e.session_id = p_session_id
                           and e.student_id = k.student_id and e.typ = 'hinweis' and (e.payload ->> 'geliefert')::boolean),
             'eingriffe_ab_3', coalesce((select jsonb_agg(e.payload || jsonb_build_object('zeit', e.zeit) order by e.zeit)
                from public.session_ereignisse e where e.session_id = p_session_id and e.student_id = k.student_id
                 and e.typ = 'eingriff' and (e.payload ->> 'stufe')::int >= 3), '[]'),
             'entscheidungen_pfad', coalesce((select jsonb_agg(e.payload || jsonb_build_object('zeit', e.zeit) order by e.zeit)
                from public.session_ereignisse e where e.session_id = p_session_id and e.student_id = k.student_id
                 and e.typ = 'entscheidung_pfad'), '[]'),
             'mastery_entscheidungen', '[]'::jsonb),
           aktualisiert_am = clock_timestamp(), aktualisiert_von = auth.uid()
     where a.session_id = p_session_id and a.student_id = k.student_id;
    v_n := v_n + 1;
  end loop;

  perform public.session_rpc_markieren();
  update public.coaching_sessions set status = 'done', beendet_am = now() where id = p_session_id;
  perform set_config('edvance.session_rpc', '', true);

  return jsonb_build_object(
    'kinder', v_n,
    'nicht_in_akte', v_ohne,
    'anwesend', (select count(*) from public.session_students where session_id = p_session_id and attendance = 'present'),
    'einheit_verbraucht', (select count(*) from public.session_students where session_id = p_session_id
                            and public.einheit_verbraucht(attendance)));
end;
$$;

-- Offene Flags fuer die Admin-Startseite (spaeter). Nur Admin.
create function public.session_flags_offen()
returns table (session_id uuid, student_id uuid, name text, flag text, scheduled_at timestamptz, notiz text)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'session_flags_offen: nur Admin' using errcode = '42501';
  end if;
  return query
    select a.session_id, a.student_id, public.session_kind_name(a.student_id), f.flag, cs.scheduled_at, a.notiz
      from public.session_kind_abschluss a
      join public.coaching_sessions cs on cs.id = a.session_id
      cross join lateral (values ('eltern', a.flag_eltern and a.flag_eltern_erledigt_am is null),
                                 ('pfad', a.flag_pfad and a.flag_pfad_erledigt_am is null)) as f(flag, offen)
     where a.in_akte_am is not null and f.offen
     order by cs.scheduled_at, a.student_id, f.flag;
end;
$$;

create function public.session_flag_erledigen(p_session_id uuid, p_student_id uuid, p_flag text)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'session_flag_erledigen: nur Admin' using errcode = '42501';
  end if;
  if p_flag = 'eltern' then
    update public.session_kind_abschluss set flag_eltern_erledigt_am = now(), flag_eltern_erledigt_von = auth.uid()
     where session_id = p_session_id and student_id = p_student_id and flag_eltern and flag_eltern_erledigt_am is null;
  elsif p_flag = 'pfad' then
    update public.session_kind_abschluss set flag_pfad_erledigt_am = now(), flag_pfad_erledigt_von = auth.uid()
     where session_id = p_session_id and student_id = p_student_id and flag_pfad and flag_pfad_erledigt_am is null;
  else
    raise exception 'session_flag_erledigen: eltern oder pfad' using errcode = '22023';
  end if;
  if not found then
    raise exception 'session_flag_erledigen: kein offenes Flag' using errcode = 'P0002';
  end if;
end;
$$;

revoke all on function
  public.abschluss_setzen(uuid, uuid, text, boolean, text, boolean, boolean, jsonb),
  public.quest_termin_setzen(uuid, uuid, timestamptz), public.session_abschliessen(uuid),
  public.session_flags_offen(), public.session_flag_erledigen(uuid, uuid, text)
  from public, anon, authenticated;
grant execute on function
  public.abschluss_setzen(uuid, uuid, text, boolean, text, boolean, boolean, jsonb),
  public.quest_termin_setzen(uuid, uuid, timestamptz), public.session_abschliessen(uuid),
  public.session_flags_offen(), public.session_flag_erledigen(uuid, uuid, text)
  to authenticated;
