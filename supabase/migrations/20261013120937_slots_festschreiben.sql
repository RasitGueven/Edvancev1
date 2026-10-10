-- Slots SL1, Teil 6a: Festschreiben, Coach-Sicht, Spiegel der Anwesenheit.
--
-- Bauauftrag Slots (Fassung 1), Entscheidungen 14 und 20; Anforderung F 38–39, I 53–54.
--
-- Inhalt:
--   1. termin_session_anlegen — Raum-Termin wird coaching_session (Admin; Coach nur eigener Raum, nur am Tag)
--   2. meine_einsaetze        — eigene Raum-Termine der Woche (nur Coach; keine Absagen, kein Vertrag)
--   3. Spiegel-Trigger        — session_students.attendance -> kind_termine.zustand (der einzige Schreiber
--                               aus der Session), Buchung gelöscht -> session_id leer

begin;

-- ============================================================================
-- 1. termin_session_anlegen (Entscheidung 14)
-- ============================================================================
--
-- Idempotent: gibt es die Session schon, kommt ihre id zurück (neue Kinder der Zuteilung werden
-- nachgetragen). coach_id = eingeteilter Coach, room = Raumname (Live-Sicht und Listen lesen room),
-- scheduled_at = Datum + Beginn in Berlin. Ein Kind ohne Zugang an dem Tag (ZG001, z. B. ab
-- gekuendigt_zum) wird ausgelassen und "ausgefallen durch uns"; die Session entsteht trotzdem.

create function public.termin_session_anlegen(p_datum date, p_zeit_id uuid, p_raum_id uuid,
                                              p_jetzt timestamptz default now())
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_rolle text := coalesce(public.get_my_role(), '');
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  r       record;
  v_sess  public.coaching_sessions;
  v_neu   boolean := false;
  v_aus   jsonb;
  v_x     jsonb;
begin
  if not public.ist_systemaufruf() and v_rolle not in ('admin', 'coach') then
    raise exception 'termin_session_anlegen: nur Admin oder Coach' using errcode = '42501';
  end if;
  perform public.slots_sperren();

  select * into r from public.slot_raeume(p_datum, p_datum) x
   where x.slot_zeit_id = p_zeit_id and x.raum_id = p_raum_id;
  -- Coach: nur der eingeteilte Coach dieses Raums (Entscheidung 20), auch über die direkte Adresse.
  if v_rolle = 'coach' and not public.ist_systemaufruf()
     and (r.raum_id is null or r.coach_id is distinct from auth.uid()) then
    raise exception 'termin_session_anlegen: nur der eingeteilte Coach dieses Raums' using errcode = '42501';
  end if;
  if p_datum <> public.slots_berlin_tag(v_jetzt) then
    perform public.slots_fehler('22023', 'termin_session_anlegen: nur am Tag des Termins', 'nur_am_tag');
  end if;

  v_sess := public.slots_session(p_datum, p_zeit_id, p_raum_id);
  if v_sess.id is null then
    if r.raum_id is null or not r.offen then
      perform public.slots_fehler('SL002', 'termin_session_anlegen: kein Raum mit Coach');
    end if;
    insert into public.coaching_sessions (coach_id, room, scheduled_at, status, raum_id, slot_zeit_id)
    values (r.coach_id, r.raum_name, public.slots_termin_beginn(p_datum, p_zeit_id), 'upcoming', p_raum_id, p_zeit_id)
    returning * into v_sess;
    v_neu := true;
  end if;

  v_aus := public.slots_festschreibung_nachziehen(p_datum, p_zeit_id);
  for v_x in select * from jsonb_array_elements(v_aus) loop
    perform public.termine_planen((v_x ->> 'student_id')::uuid, v_jetzt);
  end loop;

  return jsonb_build_object(
    'session_id', v_sess.id, 'neu', v_neu,
    'ausgelassen', coalesce((select jsonb_agg(x || public.slots_kind_info((x ->> 'student_id')::uuid,
                                                (select kt.vertrag_id from public.kind_termine kt
                                                  where kt.id = (x ->> 'termin_id')::uuid)))
                               from jsonb_array_elements(v_aus) x), '[]'));
end;
$$;

-- ============================================================================
-- 2. meine_einsaetze(p_montag) (Anforderung I 53–54)
-- ============================================================================

create function public.meine_einsaetze(p_montag date)
returns jsonb
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
declare
  v_mo    date := p_montag - (extract(isodow from p_montag)::int - 1);
  v_heute date := public.slots_berlin_tag(now());
begin
  if coalesce(public.get_my_role(), '') <> 'coach' then
    raise exception 'meine_einsaetze: nur Coach' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'montag', v_mo, 'kw', extract(week from v_mo)::int, 'heute', v_heute,
    'einsaetze', coalesce((
      select jsonb_agg(jsonb_build_object(
               'datum', r.datum, 'zeit_id', r.slot_zeit_id, 'beginn', public.slots_hhmm(z.beginn),
               'ende', public.slots_hhmm(z.ende), 'raum_id', r.raum_id, 'raum_name', r.raum_name,
               'heute', r.datum = v_heute, 'session_id', s.id,
               'kinder', coalesce((select jsonb_agg(public.slots_kind_info(t.student_id, kt.vertrag_id)
                                                    order by public.slots_kind_info(t.student_id, kt.vertrag_id) ->> 'name')
                                     from public.slot_zuteilung(r.datum, r.slot_zeit_id) t
                                     join public.kind_termine kt on kt.id = t.termin_id
                                    where t.raum_id = r.raum_id), '[]'))
             order by r.datum, z.beginn)
        from public.slot_raeume(v_mo, v_mo + 4) r
        join public.slot_zeiten z on z.id = r.slot_zeit_id
        left join lateral (select * from public.slots_session(r.datum, r.slot_zeit_id, r.raum_id)) s on true
       where r.offen and r.coach_id = auth.uid()), '[]'));
end;
$$;

-- ============================================================================
-- 3. Spiegel-Trigger (Entscheidung 14)
-- ============================================================================

create function public.slots_anwesenheit_spiegeln()
returns trigger
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_n integer;
begin
  if tg_op = 'DELETE' then
    update public.kind_termine set session_id = null
     where session_id = old.session_id and student_id = old.student_id;
    return null;
  end if;
  update public.kind_termine kt
     set zustand = new.attendance,
         absage_eingang = case when new.attendance in ('cancelled', 'unexcused') then kt.absage_eingang end,
         absage_erfasst_von = case when new.attendance in ('cancelled', 'unexcused') then kt.absage_erfasst_von end,
         absage_erfasst_am = case when new.attendance in ('cancelled', 'unexcused') then kt.absage_erfasst_am end
   where kt.session_id = new.session_id and kt.student_id = new.student_id
     and kt.zustand is distinct from new.attendance;
  get diagnostics v_n = row_count;
  -- Belegt der Termin danach eine Einheit anders (z. B. Admin setzt "abgesagt"), gleicht die Planung ab.
  if v_n > 0 and (old.attendance in ('cancelled', 'cancelled_by_us')) <> (new.attendance in ('cancelled', 'cancelled_by_us')) then
    perform public.termine_planen(new.student_id);
  end if;
  return null;
end;
$$;

create trigger session_students_slots_spiegel_trg
  after update of attendance or delete on public.session_students
  for each row execute function public.slots_anwesenheit_spiegeln();

revoke all on function public.slots_anwesenheit_spiegeln() from public, anon, authenticated;
revoke all on function public.termin_session_anlegen(date, uuid, uuid, timestamptz) from public, anon;
revoke all on function public.meine_einsaetze(date) from public, anon;
grant execute on function public.termin_session_anlegen(date, uuid, uuid, timestamptz) to authenticated;
grant execute on function public.meine_einsaetze(date) to authenticated;

commit;
