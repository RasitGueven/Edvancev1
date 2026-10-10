-- Slots SL1, Teil 7: Nachbesserungen aus dem Consensus-Check (CLAUDE.md §8).
--
-- Befunde der zweiten Instanz (PR-Text, Abschnitt Consensus-Check):
--   1  termin_coach_setzen (fällt aus): Session nur löschen, wenn sie upcoming ist und keine Daten trägt,
--      die per CASCADE/SET NULL an ihr hängen (interventions, quests, lernpfad, lernpfad_protokoll,
--      session_ereignisse); sonst SL011.
--   2  absage_zuruecknehmen: zusätzlich Einzel-Session am Tag, Wochengrenze und Budget prüfen (SL010).
--   3  slots_festschreibung_nachziehen: ausgelassene Kinder (ZG001) werden neu geplant.
--   4  absage_zuruecknehmen: eine festgeschriebene Umbuchungszeile wird nicht gelöscht, sondern cancelled_by_us.
--   5  termin_coach_setzen, termin_raum_oeffnen, termin_faellt_aus: SL012 hinter der Ferientabelle.
--   6  termine_planen: auch Verträge mit vorverlegtem Stichtag und künftigen Zeilen werden abgeglichen.
--   7  Spiegel-Trigger auch bei geänderter session_id/student_id.
--   8  service_role schreibt nicht direkt in die Slot-Tabellen.
--   9  Beide Trigger nehmen zuerst die Slots-Sperre (Entscheidung 16).
--  12  slot_zeit_anlegen: keine zweite Uhrzeit mit gleichem Beginn, solange die erste noch gilt.
-- Die übrigen Funktionen bleiben, wie Teil 1–6 sie anlegen. Signaturen, SECURITY und Rechte unverändert.

begin;

create or replace function public.termin_coach_setzen(p_datum date, p_zeit_id uuid, p_raum_id uuid, p_coach_id uuid,
                                           p_jetzt timestamptz default now())
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  v_stamm uuid;
  v_sess  public.coaching_sessions;
  v_raum  public.raeume;
begin
  perform public.slots_admin_pruefen('termin_coach_setzen');
  perform public.slots_sperren();
  if p_datum < public.slots_berlin_tag(v_jetzt) then
    perform public.slots_code_werfen('SL011', 'termin_coach_setzen');
  end if;
  if p_datum > public.slots_planungsgrenze() then
    perform public.slots_code_werfen('SL012', 'termin_coach_setzen');
  end if;
  select * into v_raum from public.raeume r
   where r.id = p_raum_id and r.aktiv_ab <= p_datum and (r.inaktiv_ab is null or p_datum < r.inaktiv_ab);
  if not found or not public.betriebstag(p_datum) or not public.slots_zeit_aktiv(p_zeit_id, p_datum) then
    perform public.slots_fehler('22023', 'termin_coach_setzen: Raum, Tag oder Uhrzeit nicht aktiv');
  end if;
  v_sess := public.slots_session(p_datum, p_zeit_id, p_raum_id);
  if v_sess.gestartet_am is not null then
    perform public.slots_code_werfen('SL011', 'termin_coach_setzen');
  end if;
  if p_coach_id is not null then
    if not exists (select 1 from public.profiles p where p.id = p_coach_id and p.role = 'coach') then
      perform public.slots_fehler('22023', 'termin_coach_setzen: kein Coach', 'kein_coach');
    end if;
    if exists (select 1 from public.slot_raeume(p_datum, p_datum) r
                where r.slot_zeit_id = p_zeit_id and r.coach_id = p_coach_id and r.raum_id <> p_raum_id) then
      perform public.slots_fehler('SL009', 'Schicht doppelt (Raum oder Coach)');
    end if;
  end if;

  select s.coach_id into v_stamm from public.stammschichten s
   where s.raum_id = p_raum_id and s.slot_zeit_id = p_zeit_id and s.wochentag = extract(isodow from p_datum)
     and s.gueltig_ab <= p_datum and (s.gueltig_bis is null or p_datum <= s.gueltig_bis)
   order by s.gueltig_ab desc limit 1;

  if p_coach_id is not distinct from v_stamm then
    delete from public.schicht_abweichungen where datum = p_datum and slot_zeit_id = p_zeit_id and raum_id = p_raum_id;
  else
    insert into public.schicht_abweichungen (datum, slot_zeit_id, raum_id, art, coach_id, erfasst_von)
    values (p_datum, p_zeit_id, p_raum_id,
            case when p_coach_id is null then 'faellt_aus' when v_stamm is null then 'zusatz' else 'vertretung' end,
            p_coach_id, auth.uid())
    on conflict (datum, slot_zeit_id, raum_id) do update
       set art = excluded.art, coach_id = excluded.coach_id, erfasst_von = excluded.erfasst_von, erfasst_am = now();
  end if;

  -- Nach dem Festschreiben (Entscheidung 14): coach_id nachziehen, bei "fällt aus" die Session löschen,
  -- solange sie keine Session-Daten hat; ihre Kinder gehen in die Zuteilung zurück.
  if v_sess.id is not null then
    if p_coach_id is not null then
      update public.coaching_sessions set coach_id = p_coach_id where id = v_sess.id;
    else
      -- Nachbesserung: nur eine Session ohne jede Session-Daten. interventions und quests hängen per
      -- CASCADE, lernpfad/lernpfad_protokoll per SET NULL an coaching_sessions; ohne diese Prüfung gingen
      -- sie still verloren (Consensus-Befund 1).
      if v_sess.status <> 'upcoming'
         or exists (select 1 from public.interventions i where i.session_id = v_sess.id)
         or exists (select 1 from public.quests q where q.session_id = v_sess.id)
         or exists (select 1 from public.lernpfad l where l.coach_session_id = v_sess.id or l.letzte_session_id = v_sess.id)
         or exists (select 1 from public.lernpfad_protokoll l where l.session_id = v_sess.id)
         or exists (select 1 from public.session_ereignisse e where e.session_id = v_sess.id) then
        perform public.slots_code_werfen('SL011', 'termin_coach_setzen');
      end if;
      begin
        update public.kind_termine set session_id = null where session_id = v_sess.id;
        delete from public.coaching_sessions where id = v_sess.id;
      exception when foreign_key_violation or restrict_violation then
        perform public.slots_code_werfen('SL011', 'termin_coach_setzen');
      end;
    end if;
  end if;
  perform public.slots_festschreibung_nachziehen(p_datum, p_zeit_id);
  perform public.slots_planen_slot(extract(isodow from p_datum)::int, p_zeit_id, v_jetzt);
  return jsonb_build_object('art', (select a.art from public.schicht_abweichungen a
                                     where a.datum = p_datum and a.slot_zeit_id = p_zeit_id and a.raum_id = p_raum_id));
end;
$$;


create or replace function public.termin_faellt_aus(p_datum date, p_zeit_id uuid, p_jetzt timestamptz default now())
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  v_ids   uuid[];
  v_st    uuid;
begin
  perform public.slots_admin_pruefen('termin_faellt_aus');
  perform public.slots_sperren();
  if p_datum < public.slots_berlin_tag(v_jetzt)
     or exists (select 1 from public.coaching_sessions cs
                 where cs.slot_zeit_id = p_zeit_id and cs.scheduled_at = public.slots_termin_beginn(p_datum, p_zeit_id)
                   and cs.gestartet_am is not null) then
    perform public.slots_code_werfen('SL011', 'termin_faellt_aus');
  end if;
  if p_datum > public.slots_planungsgrenze() then
    perform public.slots_code_werfen('SL012', 'termin_faellt_aus');
  end if;
  with weg as (
    update public.kind_termine kt set zustand = 'cancelled_by_us'
     where kt.datum = p_datum and kt.slot_zeit_id = p_zeit_id and kt.zustand = 'planned'
    returning kt.id, kt.student_id
  )
  select array_agg(weg.id) into v_ids from weg;
  update public.session_students ss set attendance = 'cancelled_by_us'
    from public.kind_termine kt
   where kt.id = any (coalesce(v_ids, '{}')) and ss.session_id = kt.session_id and ss.student_id = kt.student_id;
  for v_st in select distinct kt.student_id from public.kind_termine kt where kt.id = any (coalesce(v_ids, '{}')) loop
    perform public.termine_planen(v_st, v_jetzt);
  end loop;
  return jsonb_build_object('betroffen', coalesce(cardinality(v_ids), 0));
end;
$$;


create or replace function public.absage_zuruecknehmen(p_termin_id uuid, p_jetzt timestamptz default now())
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_jetzt timestamptz := public.slots_jetzt(p_jetzt);
  kt      public.kind_termine;
  neu     public.kind_termine;
begin
  perform public.slots_admin_pruefen('absage_zuruecknehmen');
  perform public.slots_sperren();
  select * into kt from public.kind_termine where id = p_termin_id for update;
  if not found then
    perform public.slots_fehler('P0002', 'absage_zuruecknehmen: Termin nicht gefunden');
  end if;
  if kt.absage_eingang is null or kt.zustand not in ('cancelled', 'unexcused')
     or public.slots_termin_beginn(kt.datum, kt.slot_zeit_id) <= v_jetzt
     or exists (select 1 from public.coaching_sessions cs where cs.id = kt.session_id and cs.gestartet_am is not null) then
    perform public.slots_code_werfen('SL010', 'absage_zuruecknehmen');
  end if;

  select * into neu from public.kind_termine where umgebucht_von = kt.id for update;
  if found then
    if neu.zustand <> 'planned'
       or exists (select 1 from public.coaching_sessions cs where cs.id = neu.session_id and cs.gestartet_am is not null) then
      perform public.slots_code_werfen('SL010', 'absage_zuruecknehmen');
    end if;
    if neu.session_id is not null then
      -- Festgeschrieben: nicht löschen (Entscheidung 10), sondern ausfallen lassen (Consensus-Befund 4).
      update public.kind_termine set zustand = 'cancelled_by_us' where id = neu.id;
      perform public.slots_buchung_setzen(neu.id);
    else
      delete from public.kind_termine where id = neu.id;
    end if;
  end if;

  -- Platz inzwischen vergeben oder schon ein anderer Termin an dem Tag: keine Rücknahme.
  if public.slot_belegt(kt.datum, kt.slot_zeit_id, kt.student_id) >= public.slot_kapazitaet(kt.datum, kt.slot_zeit_id)
     or exists (select 1 from public.kind_termine x
                 where x.student_id = kt.student_id and x.datum = kt.datum and x.id <> kt.id
                   and x.zustand in ('planned', 'present', 'unexcused')
                   and not (x.herkunft = 'stammplatz' and x.session_id is null))
     -- Nachbesserung (Consensus-Befund 2): Einzel-Session am Tag, Wochengrenze, Budget.
     or exists (select 1 from public.slots_einzelbuchungen(kt.student_id) e
                 where e.datum = kt.datum and e.attendance in ('planned', 'present', 'unexcused'))
     or public.slots_woche_aktiv(kt.student_id, kt.datum, kt.id) + 1 > public.slots_wochengrenze(kt.student_id, kt.datum)
     or (select v.einheiten from public.vertraege v where v.id = kt.vertrag_id)
        - public.slots_fest_belegt(kt.vertrag_id, public.slots_berlin_tag(v_jetzt), kt.id) < 1 then
    perform public.slots_code_werfen('SL010', 'absage_zuruecknehmen');
  end if;
  -- Ein beweglicher Stammplatz-Termin, den die Planung inzwischen auf den Tag gelegt hat, weicht.
  delete from public.kind_termine x
   where x.student_id = kt.student_id and x.datum = kt.datum and x.id <> kt.id
     and x.herkunft = 'stammplatz' and x.zustand = 'planned' and x.session_id is null;

  update public.kind_termine
     set zustand = 'planned', absage_eingang = null, absage_erfasst_von = null, absage_erfasst_am = null
   where id = kt.id;
  perform public.slots_buchung_setzen(kt.id);
  perform public.slots_festschreibung_nachziehen(kt.datum, kt.slot_zeit_id);
  perform public.termine_planen(kt.student_id, v_jetzt);
  return jsonb_build_object('termin_id', kt.id, 'zustand', 'planned', 'umbuchung_entfernt', neu.id);
end;
$$;


create or replace function public.slots_festschreibung_nachziehen(p_datum date, p_slot_zeit_id uuid)
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  z        record;
  v_sess   uuid;
  v_aus    jsonb := '[]';
begin
  if not exists (select 1 from public.coaching_sessions cs
                  where cs.slot_zeit_id = p_slot_zeit_id
                    and cs.scheduled_at = public.slots_termin_beginn(p_datum, p_slot_zeit_id)) then
    return v_aus;
  end if;
  for z in
    select t.termin_id, t.student_id, t.raum_id from public.slot_zuteilung(p_datum, p_slot_zeit_id) t
      join public.kind_termine kt on kt.id = t.termin_id
     where t.raum_id is not null and kt.session_id is null
  loop
    v_sess := (public.slots_session(p_datum, p_slot_zeit_id, z.raum_id)).id;
    continue when v_sess is null;
    if public.session_platz_zugang(z.student_id, p_datum) then
      insert into public.session_students (session_id, student_id, attendance)
      values (v_sess, z.student_id, 'planned')
      on conflict (session_id, student_id) do update set attendance = 'planned';
      update public.kind_termine set session_id = v_sess where id = z.termin_id;
    else
      update public.kind_termine set zustand = 'cancelled_by_us' where id = z.termin_id;
      v_aus := v_aus || jsonb_build_object('termin_id', z.termin_id, 'student_id', z.student_id, 'grund', 'ZG001');
      -- Nachbesserung (Consensus-Befund 3): jedes ausgelassene Kind wird neu geplant.
      perform public.termine_planen(z.student_id);
    end if;
  end loop;
  return v_aus;
end;
$$;


create or replace function public.termine_planen(p_student_id uuid, p_jetzt timestamptz default now())
returns void
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_heute date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  v       record;
begin
  perform public.slots_sperren();
  if not public.slots_kind_zugelassen(p_student_id) then
    return;
  end if;

  for v in
    select x.id, public.slots_vertrag_planende(x.id) as ende
      from public.vertraege x
     where x.student_id = p_student_id and x.status = 'abgeschlossen'
       and x.vertrag_ende is not null
       -- Nachbesserung (Consensus-Befund 6): auch ein vorverlegter Stichtag räumt künftige Zeilen ab.
       and (x.vertrag_ende >= v_heute
            or exists (select 1 from public.kind_termine k where k.vertrag_id = x.id and k.datum >= v_heute))
  loop
    -- Künftige Termine hinter dem Planende (Widerruf, Kündigung): geplante ohne Session fallen weg,
    -- festgeschriebene werden "ausgefallen durch uns" (Entscheidung 22).
    delete from public.kind_termine kt
     where kt.vertrag_id = v.id and kt.datum >= v_heute and kt.datum > v.ende
       and kt.zustand = 'planned' and kt.session_id is null;
    with weg as (
      update public.kind_termine kt set zustand = 'cancelled_by_us'
       where kt.vertrag_id = v.id and kt.datum >= v_heute and kt.datum > v.ende
         and kt.zustand = 'planned' and kt.session_id is not null
      returning kt.session_id, kt.student_id
    )
    update public.session_students ss set attendance = 'cancelled_by_us'
      from weg where ss.session_id = weg.session_id and ss.student_id = weg.student_id;

    if to_regclass('pg_temp.slots_plan_tmp') is null then
      create temp table slots_plan_tmp (datum date, slot_zeit_id uuid, stammplatz_id uuid, ergebnis text) on commit drop;
    end if;
    truncate slots_plan_tmp;
    insert into slots_plan_tmp select * from public.slots_plan_rechnen(v.id, v_heute)
     where ergebnis in ('vorhanden', 'neu');

    -- Bewegliche Zeilen ohne Platz im Plan fallen weg; die übrigen behalten id und Raum-Stift.
    delete from public.kind_termine kt
     where kt.vertrag_id = v.id and kt.herkunft = 'stammplatz' and kt.zustand = 'planned'
       and kt.session_id is null and kt.datum >= v_heute
       and not exists (select 1 from slots_plan_tmp p where p.datum = kt.datum and p.slot_zeit_id = kt.slot_zeit_id);
    update public.kind_termine kt set stammplatz_id = p.stammplatz_id
      from slots_plan_tmp p
     where kt.vertrag_id = v.id and kt.herkunft = 'stammplatz' and kt.zustand = 'planned'
       and kt.session_id is null and kt.datum = p.datum and kt.slot_zeit_id = p.slot_zeit_id
       and kt.stammplatz_id is distinct from p.stammplatz_id;
    insert into public.kind_termine (student_id, vertrag_id, datum, slot_zeit_id, herkunft, stammplatz_id, angelegt_von)
    select p_student_id, v.id, p.datum, p.slot_zeit_id, 'stammplatz', p.stammplatz_id, auth.uid()
      from slots_plan_tmp p where p.ergebnis = 'neu';
  end loop;
end;
$$;


create or replace function public.slots_vertrag_geaendert()
returns trigger
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_ende date;
begin
  if new.student_id is null then
    return null;
  end if;
  perform public.slots_sperren();
  if new.widerrufen_am is not null then
    v_ende := new.widerrufen_am;
  elsif new.gekuendigt_zum is not null then
    v_ende := new.gekuendigt_zum - 1;
  end if;
  if v_ende is not null then
    update public.stammplaetze s
       set gueltig_bis = greatest(s.gueltig_ab - 1, v_ende),
           beendet_am = coalesce(s.beendet_am, now()), beendet_von = coalesce(s.beendet_von, auth.uid())
     where s.vertrag_id = new.id
       and coalesce(s.gueltig_bis, 'infinity'::date) > v_ende;
  end if;
  perform public.termine_planen(new.student_id);
  return null;
end;
$$;


create or replace function public.slots_anwesenheit_spiegeln()
returns trigger
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_n integer;
begin
  perform public.slots_sperren();
  -- Nachbesserung (Consensus-Befund 7): Buchung umgehängt (andere Session oder anderes Kind).
  if tg_op = 'UPDATE' and (new.session_id is distinct from old.session_id or new.student_id is distinct from old.student_id) then
    update public.kind_termine set session_id = null
     where session_id = old.session_id and student_id = old.student_id;
    return null;
  end if;
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


create or replace function public.slot_zeit_anlegen(p_beginn time, p_aktiv_ab date default null, p_jetzt timestamptz default now())
returns uuid
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_heute date := public.slots_berlin_tag(public.slots_jetzt(p_jetzt));
  v_id    uuid;
begin
  perform public.slots_admin_pruefen('slot_zeit_anlegen');
  perform public.slots_sperren();
  if p_beginn is null or p_beginn < time '06:00' or p_beginn > time '22:00' then
    perform public.slots_fehler('22023', 'slot_zeit_anlegen: Beginn zwischen 06:00 und 22:00');
  end if;
  -- Nachbesserung (Consensus-Befund 12): auch eine Uhrzeit, die erst künftig endet, ist doppelt.
  if exists (select 1 from public.slot_zeiten z where z.beginn = p_beginn
              and (z.inaktiv_ab is null or z.inaktiv_ab > coalesce(p_aktiv_ab, v_heute))) then
    perform public.slots_fehler('22023', 'slot_zeit_anlegen: Uhrzeit gibt es schon', 'zeit_doppelt');
  end if;
  if coalesce(p_aktiv_ab, v_heute) < v_heute then
    perform public.slots_fehler('SL007', 'slot_zeit_anlegen: aktiv ab liegt in der Vergangenheit');
  end if;
  insert into public.slot_zeiten (beginn, aktiv_ab, angelegt_von)
  values (p_beginn, coalesce(p_aktiv_ab, v_heute), auth.uid())
  returning id into v_id;
  return v_id;
end;
$$;

drop trigger session_students_slots_spiegel_trg on public.session_students;
create trigger session_students_slots_spiegel_trg
  after update of attendance, session_id, student_id or delete on public.session_students
  for each row execute function public.slots_anwesenheit_spiegeln();

do $$
declare
  t text;
begin
  foreach t in array array['slot_zeiten', 'raeume', 'stammschichten', 'schicht_abweichungen',
                           'slot_rhythmus', 'stammplaetze', 'kind_termine'] loop
    execute format('revoke insert, update, delete, truncate on public.%I from service_role', t);
  end loop;
end;
$$;

commit;
