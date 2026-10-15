-- Slots S1: Sofort-Session und Buchbarkeit mit Grund.
--
-- Ein Admin legt jederzeit (auch Wochenende, Ferien, Feiertag) eine Session ab jetzt an: Coach oder
-- Admin als Leitung, ein Raum aus public.raeume, ein oder mehrere Kinder. Technisch ist das eine
-- Einzel-Session wie aus dem Stundenplan (raum_id und slot_zeit_id null), keine neue Termin-Art.
-- Einheiten zählen über den vorhandenen Weg slots_einzelbuchungen / slots_fest_belegt.
--
-- kinder_buchbar übersetzt nur bestehende Regeln in einen Grund je Kind, sie erfindet keine neue:
-- die Vertrags-Codes greifen genau dann, wenn session_platz_zugang (der Trigger ZG001) nein sagt.
--
-- Bestehende Funktionen und Trigger bleiben unverändert. Beschrieben in docs/api/DATENVERTRAG.md,
-- Abschnitt 12.

begin;

-- ============================================================================
-- Buchbarkeit je Kind an einem Datum
-- ============================================================================

create function public.kinder_buchbar(p_datum date, p_session_id uuid default null)
returns table (student_id uuid, name text, klasse int, ist_test boolean, code text, detail date)
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
declare
  v_testlauf boolean;
begin
  perform public.slots_admin_pruefen('kinder_buchbar');
  if p_datum is null then
    perform public.slots_fehler('22023', 'kinder_buchbar: Datum fehlt');
  end if;
  if p_session_id is not null then
    select cs.testlauf into v_testlauf from public.coaching_sessions cs where cs.id = p_session_id;
    if not found then
      perform public.slots_fehler('P0002', 'kinder_buchbar: Session nicht gefunden');
    end if;
    if not exists (select 1 from public.coaching_sessions cs
                    where cs.id = p_session_id and public.slots_berlin_tag(cs.scheduled_at) = p_datum) then
      perform public.slots_fehler('22023', 'kinder_buchbar: Datum passt nicht zur Session', 'datum_session');
    end if;
  end if;

  return query
  with k as (
    select s.id, s.ist_test,
           public.session_platz_zugang(s.id, p_datum) as zugang,
           -- "Letzter" Vertrag: spätester Beginn, bei Gleichstand zuletzt abgeschlossen.
           (select v.widerrufen_am from public.vertraege v
             where v.student_id = s.id and v.status = 'abgeschlossen'
             order by v.vertragsbeginn desc nulls last, v.abgeschlossen_at desc nulls last limit 1) as letzt_widerrufen,
           exists (select 1 from public.vertraege v
                    where v.student_id = s.id and v.status = 'abgeschlossen') as hat_vertrag,
           (select min(v.vertragsbeginn) from public.vertraege v
             where v.student_id = s.id and v.status = 'abgeschlossen' and v.widerrufen_am is null
               and v.vertragsbeginn > p_datum) as naechster_beginn,
           -- Wirksames Ende: Kündigung endet am Tag vor gekuendigt_zum (vertrag_wirksamer_status).
           (select max(least(v.vertrag_ende, v.gekuendigt_zum - 1)) from public.vertraege v
             where v.student_id = s.id and v.status = 'abgeschlossen' and v.widerrufen_am is null
               and least(v.vertrag_ende, v.gekuendigt_zum - 1) < p_datum) as letztes_ende,
           public.slots_vertrag_am(s.id, p_datum) as vertrag_id,
           -- Festgeschriebener Slot-Termin des Kindes in genau dieser Session (zählt nicht gegen das Kind).
           (select kt.id from public.kind_termine kt
             where kt.student_id = s.id and kt.session_id = p_session_id limit 1) as eigen_termin
      from public.students s
     where not s.is_provisional
  ),
  r as (
    select k.*,
           case
             when k.zugang then null
             when not k.hat_vertrag then 'kein_vertrag'
             when k.letzt_widerrufen is not null then 'widerrufen'
             when k.naechster_beginn is not null then 'vertrag_ab'
             when k.letztes_ende is not null then 'vertrag_beendet'
             -- Abgeschlossen, aber ohne Laufzeit: für die Session kein Vertrag.
             else 'kein_vertrag'
           end as vertrags_code,
           -- Eine Buchung in genau dieser Session zählt nicht gegen das Kind.
           (select count(*)::int from public.slots_einzelbuchungen(k.id) e
              join public.vertraege v on v.id = k.vertrag_id
             where e.session_id = p_session_id
               and e.datum between v.vertragsbeginn and v.vertrag_ende
               and e.attendance in ('planned', 'present', 'unexcused')) as eigen
      from k
  )
  select r.id,
         coalesce(nullif(btrim(p.full_name), ''),
                  (select nullif(btrim(concat_ws(' ', v.kind_vorname, v.kind_nachname)), '')
                     from public.vertraege v where v.student_id = r.id
                    order by v.vertragsbeginn desc nulls last limit 1)),
         coalesce(st.class_level,
                  (select v.klasse from public.vertraege v where v.student_id = r.id
                    order by v.vertragsbeginn desc nulls last limit 1)),
         r.ist_test,
         case
           when r.vertrags_code is not null then r.vertrags_code
           when not r.ist_test
                and (r.vertrag_id is null
                     or (select v.einheiten from public.vertraege v where v.id = r.vertrag_id)
                        - public.slots_fest_belegt(r.vertrag_id, p_datum, r.eigen_termin) + r.eigen < 1) then 'keine_einheit'
           when exists (select 1 from public.kind_termine kt
                         where kt.student_id = r.id and kt.datum = p_datum
                           and kt.zustand in ('planned', 'present', 'unexcused')
                           and (p_session_id is null or kt.session_id is distinct from p_session_id))
                or exists (select 1 from public.slots_einzelbuchungen(r.id) e
                            where e.datum = p_datum and e.attendance in ('planned', 'present', 'unexcused')
                              and (p_session_id is null or e.session_id <> p_session_id)) then 'schon_termin'
           when v_testlauf is not null and v_testlauf <> r.ist_test then 'art_konflikt'
           else 'ok'
         end,
         case r.vertrags_code
           when 'widerrufen' then r.letzt_widerrufen
           when 'vertrag_ab' then r.naechster_beginn
           when 'vertrag_beendet' then r.letztes_ende
         end
    from r
    join public.students st on st.id = r.id
    left join public.profiles p on p.id = st.profile_id;
end;
$$;

-- ============================================================================
-- Leitung einer Session: Coach oder Admin (Entscheidung Rasit 2)
-- ============================================================================

create function public.session_leitung()
returns table (id uuid, name text, rolle text)
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
begin
  perform public.slots_admin_pruefen('session_leitung');
  return query
  select p.id, coalesce(nullif(btrim(p.full_name), ''), p.email), p.role
    from public.profiles p
   where p.role in ('coach', 'admin')
   order by coalesce(nullif(btrim(p.full_name), ''), p.email), p.id;
end;
$$;

-- ============================================================================
-- Sofort-Session anlegen
-- ============================================================================

create function public.sofort_session_anlegen(p_coach_id uuid, p_raum_id uuid, p_student_ids uuid[],
                                              p_jetzt timestamptz default now())
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_jetzt    timestamptz := date_trunc('minute', public.slots_jetzt(p_jetzt));
  v_tag      date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  v_ids      uuid[];
  v_raum     text;
  v_testlauf boolean;
  v_session  uuid;
  v_kind     record;
begin
  perform public.slots_admin_pruefen('sofort_session_anlegen');
  perform public.slots_sperren();

  if not exists (select 1 from public.profiles p where p.id = p_coach_id and p.role in ('coach', 'admin')) then
    perform public.slots_fehler('22023', 'sofort_session_anlegen: kein Coach', 'kein_coach');
  end if;
  select r.name into v_raum from public.raeume r
   where r.id = p_raum_id and r.aktiv_ab <= v_tag and (r.inaktiv_ab is null or v_tag < r.inaktiv_ab);
  if v_raum is null then
    perform public.slots_fehler('22023', 'sofort_session_anlegen: Raum nicht aktiv', 'raum_inaktiv');
  end if;

  -- Reihenfolge der Eingabe bleibt (für die Fehlermeldung), doppelte und leere Einträge fallen weg.
  select coalesce(array_agg(x.id order by x.n), '{}') into v_ids
    from (select distinct on (u.id) u.id, u.n from unnest(p_student_ids) with ordinality u(id, n)
           where u.id is not null order by u.id, u.n) x;
  if cardinality(v_ids) = 0 then
    perform public.slots_fehler('22023', 'sofort_session_anlegen: keine Kinder', 'keine_kinder');
  end if;
  -- Höchstens 5 Kinder pro Raum (Live-Sicht hat 5 Tablet-Plätze).
  if cardinality(v_ids) > 5 then
    perform public.slots_fehler('22023', 'sofort_session_anlegen: mehr als 5 Kinder', 'zu_viele');
  end if;

  if exists (select 1 from unnest(v_ids) u(id)
              where not exists (select 1 from public.students s where s.id = u.id and not s.is_provisional)) then
    perform public.slots_fehler('22023', 'sofort_session_anlegen: unbekanntes Kind', 'kein_kind');
  end if;

  select bool_and(s.ist_test) into v_testlauf from public.students s where s.id = any(v_ids);
  -- Gemischt: nicht alle Testkonten, aber mindestens eins.
  if not v_testlauf and exists (select 1 from public.students s where s.id = any(v_ids) and s.ist_test) then
    perform public.slots_fehler('22023', 'sofort_session_anlegen: Testkonto und echtes Kind gemischt', 'art_konflikt');
  end if;

  for v_kind in
    select b.student_id, b.code
      from unnest(v_ids) with ordinality u(id, n)
      join public.kinder_buchbar(v_tag) b on b.student_id = u.id
     order by u.n
  loop
    if v_kind.code <> 'ok' then
      raise exception 'sofort_session_anlegen: Kind nicht buchbar (%)', v_kind.code
        using errcode = '22023', hint = v_kind.code, detail = v_kind.student_id::text;
    end if;
  end loop;

  -- Über die bestehenden Trigger: Testlauf nur Admin, nur Testkonten; Platz nur mit Vertrag (ZG001).
  insert into public.coaching_sessions (coach_id, room, scheduled_at, testlauf)
  values (p_coach_id, v_raum, v_jetzt, v_testlauf)
  returning id into v_session;
  insert into public.session_students (session_id, student_id)
  select v_session, u.id from unnest(v_ids) u(id);

  -- Entscheidung 7: Planbilanz und künftige Stammplatz-Termine sehen das verbrauchte Budget.
  if not v_testlauf then
    perform public.termine_planen(u.id, p_jetzt) from unnest(v_ids) u(id);
  end if;

  return jsonb_build_object('session_id', v_session, 'testlauf', v_testlauf);
end;
$$;

-- ============================================================================
-- Stundenplan einer Woche: alle Einzel-Sessions (raum_id is null), Mo–So
-- ============================================================================

create function public.stundenplan_woche(p_montag date)
returns jsonb
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
declare
  v_mo date;
begin
  perform public.slots_admin_pruefen('stundenplan_woche');
  if p_montag is null then
    perform public.slots_fehler('22023', 'stundenplan_woche: Datum fehlt');
  end if;
  v_mo := p_montag - (extract(isodow from p_montag)::int - 1);
  return jsonb_build_object(
    'montag', v_mo,
    'sessions', coalesce((select jsonb_agg(jsonb_build_object(
        'session_id', cs.id, 'scheduled_at', cs.scheduled_at, 'room', cs.room, 'status', cs.status,
        'testlauf', cs.testlauf, 'gestartet', cs.gestartet_am is not null,
        'coach_id', cs.coach_id, 'coach_name', coalesce(nullif(btrim(c.full_name), ''), c.email),
        'coach_rolle', c.role,
        'kinder', coalesce((select jsonb_agg(jsonb_build_object(
              'student_id', s.id,
              'name', coalesce(nullif(btrim(p.full_name), ''),
                               (select nullif(btrim(concat_ws(' ', v.kind_vorname, v.kind_nachname)), '')
                                  from public.vertraege v where v.student_id = s.id
                                 order by v.vertragsbeginn desc nulls last limit 1)),
              'ist_test', s.ist_test, 'attendance', ss.attendance)
            order by coalesce(nullif(btrim(p.full_name), ''), s.id::text))
            from public.session_students ss
            join public.students s on s.id = ss.student_id
            left join public.profiles p on p.id = s.profile_id
           where ss.session_id = cs.id), '[]'))
        order by cs.scheduled_at, cs.id)
      from public.coaching_sessions cs
      left join public.profiles c on c.id = cs.coach_id
     where cs.raum_id is null
       and public.slots_berlin_tag(cs.scheduled_at) between v_mo and v_mo + 6), '[]'));
end;
$$;

-- ============================================================================
-- Rechte: nur angemeldete Nutzer; die Rolle prüft die Funktion selbst (Muster slots_*).
-- ============================================================================

revoke all on function public.kinder_buchbar(date, uuid) from public, anon;
revoke all on function public.session_leitung() from public, anon;
revoke all on function public.sofort_session_anlegen(uuid, uuid, uuid[], timestamptz) from public, anon;
revoke all on function public.stundenplan_woche(date) from public, anon;
grant execute on function public.kinder_buchbar(date, uuid) to authenticated;
grant execute on function public.session_leitung() to authenticated;
grant execute on function public.sofort_session_anlegen(uuid, uuid, uuid[], timestamptz) to authenticated;
grant execute on function public.stundenplan_woche(date) to authenticated;

commit;
