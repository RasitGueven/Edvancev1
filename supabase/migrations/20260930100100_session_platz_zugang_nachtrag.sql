-- P5b Nachtrag — Auflagen aus dem Consensus-Check, Entscheidungen Rasit 30.09.2026.
-- Setzt 20260930100000_session_platz_zugang.sql voraus; beide gehoeren zum Paket
-- P5b und werden nacheinander eingespielt. (Die erste Datei ist committet und
-- durch guard-paths.sh gesperrt, deshalb ein Nachtrag statt einer Aenderung.)
--
-- 1. hat_zugang: Die Bruecke vor einem Folgevertrag gilt nur, wenn weder der
--    alte noch der neue Vertrag widerrufen ist. Bisher gab ein widerrufener
--    Folgevertrag dem Kind bis zu seinem (nie erreichten) Beginn weiter Zugang.
--    Sonst wortgleich zu 20260925181700_vertraege_menue_db.sql.
-- 2. session_platz_zugang: keine eigene Bruecke mehr, sondern hat_zugang plus
--    Zeitraum: am Datum hat das Kind einen schon begonnenen, nicht widerrufenen
--    Vertrag. hat_zugang ist vor Vertragsbeginn schon wahr (App-Zugang ab
--    Abschluss); fuer einen Session-Platz muss der Vertrag laufen oder die
--    Bruecke greifen (Entscheidung "laufender Vertrag").
--    Nicht mehr an authenticated freigegeben: Trigger und
--    session_platz_kandidaten laufen als SECURITY DEFINER und brauchen das nicht.
-- 3. Verschieben: Aendert sich das Datum (Europe/Berlin) einer Session, muessen
--    alle eingetragenen Kinder am neuen Datum einen Platz bekommen duerfen,
--    sonst ZG001 mit dem neuen Datum. Eine Uhrzeitaenderung am selben Tag prueft
--    nichts. Bestandszeilen ohne Zugang (Prod: 2 Testzeilen) verhindern damit das
--    Verschieben genau ihrer Sessions.

begin;

-- ============================================================================
-- 1. hat_zugang — Bruecke nur ohne Widerruf
-- ============================================================================

create or replace function public.hat_zugang(p_student_id uuid, p_datum date default current_date)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
      from public.vertraege v
     where v.student_id = p_student_id
       and v.status = 'abgeschlossen'
       and public.vertrag_wirksamer_status(
             v.widerrufen_am, v.gekuendigt_zum, v.vertrag_ende, v.widerruf_bis, p_datum
           ) in ('im_widerruf', 'aktiv')
  )
  or exists (
    select 1
      from public.vertraege alt
      join public.vertraege neu on neu.vorgaenger_id = alt.id
     where alt.student_id = p_student_id
       and alt.status = 'abgeschlossen'
       and alt.widerrufen_am is null
       and alt.vertrag_ende is not null
       and alt.vertrag_ende < p_datum
       and neu.status = 'abgeschlossen'
       and neu.widerrufen_am is null
       and neu.vertragsbeginn is not null
       and neu.vertragsbeginn > p_datum
  );
$$;

-- ============================================================================
-- 2. session_platz_zugang — hat_zugang + begonnener Vertrag
-- ============================================================================

create or replace function public.session_platz_zugang(p_student_id uuid, p_datum date)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.hat_zugang(p_student_id, p_datum)
     and exists (
       select 1
         from public.vertraege v
        where v.student_id = p_student_id
          and v.status = 'abgeschlossen'
          and v.widerrufen_am is null
          and v.vertragsbeginn is not null
          and v.vertragsbeginn <= p_datum
     );
$$;

comment on function public.session_platz_zugang(uuid, date) is
  'Platz in einer regulaeren Session: hat_zugang am Datum UND ein schon begonnener, nicht widerrufener Vertrag (vor dem ersten Beginn kein Platz, in der Bruecke vor einem Folgevertrag schon).';

revoke all on function public.session_platz_zugang(uuid, date) from public, anon, authenticated;

-- ============================================================================
-- 3. Verschieben einer Session
-- ============================================================================

create or replace function public.session_verschieben_zugang_pruefen()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_neu date := (new.scheduled_at at time zone 'Europe/Berlin')::date;
begin
  if v_neu = (old.scheduled_at at time zone 'Europe/Berlin')::date then
    return new;
  end if;

  if exists (
    select 1 from public.session_students ss
     where ss.session_id = new.id
       and not public.session_platz_zugang(ss.student_id, v_neu)
  ) then
    raise exception 'Kein laufender Vertrag am % — Platz kann nicht vergeben werden.',
                    to_char(v_neu, 'DD.MM.YYYY')
      using errcode = 'ZG001',
            hint    = 'datum:' || to_char(v_neu, 'YYYY-MM-DD');
  end if;

  return new;
end;
$$;

comment on function public.session_verschieben_zugang_pruefen() is
  'Trigger auf coaching_sessions: neues Sessiondatum nur, wenn alle eingetragenen Kinder dort session_platz_zugang haben, sonst SQLSTATE ZG001.';

revoke all on function public.session_verschieben_zugang_pruefen() from public, anon, authenticated;

create trigger coaching_sessions_verschieben_zugang_trg
  before update of scheduled_at on public.coaching_sessions
  for each row execute function public.session_verschieben_zugang_pruefen();

commit;
