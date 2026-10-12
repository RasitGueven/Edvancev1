-- Slots SL1, Teil 6b: nächster Termin, Einheiten-Verbrauch, Umstellung der vier SQL-Stellen.
--
-- Bauauftrag Slots (Fassung 1), Entscheidungen 13 und 14.
--
-- Künftige Sessions entstehen erst am Tag des Termins (termin_session_anlegen). Wer "die nächste Session"
-- über session_students × coaching_sessions sucht, findet vorher nichts. Deshalb:
--   1. slots_kommende_termine / naechster_termin — über kind_termine ∪ session_students
--   2. naechste_termine — für ParentDashboard und Akte (Admin, Eltern des Kindes)
--   3. einheiten_stand_intern zählt kind_termine plus Buchungen ohne Kind-Termin (Entscheidung 13)
-- Die vier SQL-Stellen, die den nächsten Termin suchen, stellt Teil 6c um.
-- einheiten_stand_intern: Ausgangspunkt ist der Stand in Produktion (pg_get_functiondef, 10.10.2026);
-- Signatur, SECURITY, search_path und Rechte bleiben (create or replace mit gleicher Signatur).

begin;

-- ============================================================================
-- 1. naechster_termin
-- ============================================================================
--
-- Kommende Termine nach p_nach: geplante Kind-Termine ohne Session und Buchungen in session_students, die
-- nicht abgesagt sind (festgeschriebene Slot-Termine, Einzel-Sessions; Testläufe wie bisher mit).

create function public.slots_kommende_termine(p_student_id uuid, p_nach timestamptz)
returns table(beginn timestamptz, datum date, slot_zeit_id uuid, session_id uuid, festgeschrieben boolean)
language sql stable security definer
set search_path = public, pg_temp
as $$
  select public.slots_termin_beginn(kt.datum, kt.slot_zeit_id), kt.datum, kt.slot_zeit_id, null::uuid, false
    from public.kind_termine kt
   where kt.student_id = p_student_id and kt.zustand = 'planned' and kt.session_id is null
     and public.slots_termin_beginn(kt.datum, kt.slot_zeit_id) > p_nach
  union all
  select cs.scheduled_at, public.slots_berlin_tag(cs.scheduled_at), cs.slot_zeit_id, cs.id, true
    from public.session_students ss
    join public.coaching_sessions cs on cs.id = ss.session_id
   where ss.student_id = p_student_id and ss.attendance not in ('cancelled', 'cancelled_by_us')
     and cs.scheduled_at > p_nach;
$$;

create function public.naechster_termin(p_student_id uuid, p_nach timestamptz)
returns timestamptz
language sql stable security definer
set search_path = public, pg_temp
as $$
  select min(t.beginn) from public.slots_kommende_termine(p_student_id, p_nach) t;
$$;

comment on function public.naechster_termin(uuid, timestamptz) is
  'Beginn des nächsten Termins eines Kindes nach p_nach: Slot-Termin (auch vor dem Festschreiben) oder gebuchte Session. NULL = keiner.';

-- ============================================================================
-- 2. naechste_termine (Admin, Eltern des Kindes)
-- ============================================================================

create function public.naechste_termine(p_student_id uuid, p_anzahl integer default 3)
returns jsonb
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
begin
  if not public.ist_systemaufruf() and coalesce(public.get_my_role(), '') <> 'admin'
     and not (coalesce(public.get_my_role(), '') = 'parent' and public.is_parent_of_student(p_student_id)) then
    raise exception 'naechste_termine: keine Berechtigung' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'beginn', t.beginn, 'datum', t.datum,
             'uhrzeit', to_char(t.beginn at time zone 'Europe/Berlin', 'HH24:MI'),
             'ende', to_char((t.beginn + interval '60 minutes') at time zone 'Europe/Berlin', 'HH24:MI'),
             'festgeschrieben', t.festgeschrieben, 'session_id', t.session_id) order by t.beginn)
      from (select * from public.slots_kommende_termine(p_student_id, now())
             order by beginn limit greatest(coalesce(p_anzahl, 3), 1)) t), '[]');
end;
$$;

revoke all on function public.slots_kommende_termine(uuid, timestamptz) from public, anon, authenticated;
revoke all on function public.naechster_termin(uuid, timestamptz) from public, anon, authenticated;
revoke all on function public.naechste_termine(uuid, integer) from public, anon;
grant execute on function public.naechste_termine(uuid, integer) to authenticated;

-- ============================================================================
-- 3. einheiten_stand_intern (Entscheidung 13)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.einheiten_stand_intern(p_student_id uuid, p_heute date)
 RETURNS TABLE(art text, einheiten integer, beginn date, stichtag date, verbraucht integer, offen integer, soll numeric, rueckstand numeric, ampel text, wochen_rest numeric, noetig_pro_woche numeric, gleichmaessig_pro_woche numeric)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  with vertrag as (
    select v.einheiten, v.vertragsbeginn, v.vertrag_ende
      from public.vertraege_aktuell v
     where v.student_id = p_student_id
       and v.wirksamer_status in ('aktiv', 'im_widerruf')
       and v.einheiten is not null
       and v.vertragsbeginn is not null
       and v.vertrag_ende is not null
       and v.vertrag_ende >= p_heute
     order by (v.vertragsbeginn <= p_heute) desc,
              case when v.vertragsbeginn <= p_heute then v.vertragsbeginn end desc nulls last,
              v.vertragsbeginn asc
     limit 1
  ),
  -- SL1 (Entscheidung 13): kind_termine ist die eine Wahrheit; dazu Buchungen ohne Kind-Termin
  -- (Einzel-Sessions, Uebergang). Keine Buchung doppelt, Testlaeufe nie (slots_einzelbuchungen).
  zaehlung as (
    select (select count(*)::integer
              from public.kind_termine kt
             where kt.student_id = p_student_id
               and public.einheit_verbraucht(kt.zustand)
               and kt.datum between vt.vertragsbeginn and vt.vertrag_ende)
         + (select count(*)::integer
              from public.slots_einzelbuchungen(p_student_id) eb
             where public.einheit_verbraucht(eb.attendance)
               and eb.datum between vt.vertragsbeginn and vt.vertrag_ende) as verbraucht
      from vertrag vt
  )
  select coalesce(r.art, 'keiner'),
         vt.einheiten,
         vt.vertragsbeginn,
         vt.vertrag_ende,
         case when r.art = 'laufend' then z.verbraucht end,
         r.offen,
         r.soll,
         r.rueckstand,
         r.ampel,
         r.wochen_rest,
         r.noetig_pro_woche,
         r.gleichmaessig_pro_woche
    from (select 1) eins
    left join vertrag vt on true
    left join zaehlung z on true
    left join lateral public.einheiten_rechnung(
      vt.einheiten, vt.vertragsbeginn, vt.vertrag_ende, z.verbraucht, p_heute
    ) r on true;
$function$;

commit;
