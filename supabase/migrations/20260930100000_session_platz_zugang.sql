-- P5b "Session-Platz nur mit Zugang" (Nachtrag zu Bauauftrag Vertraege P5).
--
-- Ein Kind kommt nur dann in eine regulaere Session, wenn am Datum der Session
-- ein Vertrag laeuft. Gilt fuer Admin und Coach, durchgesetzt in der Datenbank.
--
-- Regel (Entscheidung Rasit, 30.09.2026): NICHT hat_zugang allein. hat_zugang
-- prueft nur den wirksamen Status und ist deshalb schon vor Vertragsbeginn
-- wahr (App-Zugang ab Abschluss). session_platz_zugang() verlangt zusaetzlich
-- den Zeitraum:
--   a) ein abgeschlossener Vertrag mit wirksamem Status aktiv/im_widerruf am
--      Datum UND vertragsbeginn <= Datum <= vertrag_ende, oder
--   b) die Bruecke vor einem unterschriebenen Folgevertrag — wortgleich zum
--      zweiten Zweig von hat_zugang (Vorgaenger beendet, Folgevertrag
--      abgeschlossen mit Beginn nach dem Datum).
-- hat_zugang selbst bleibt unveraendert.
--
-- Regulaer vs. LSA (belegt, nicht geraten):
--   session_students.session_id -> coaching_sessions(id)   (regulaere Sessions)
--   LSA laeuft getrennt: lsa_sessions (student_id), platz_assignments.session_id
--   -> lsa_sessions. session_students kennt keine LSA-Sitzungen. Der Trigger
--   sitzt deshalb auf session_students und trifft ausschliesslich regulaere
--   Sessions; LSA-Kiosk und platz_assign bleiben unberuehrt (Leads ohne
--   Vertrag koennen weiter eine LSA machen).
--
-- Sessiondatum = scheduled_at in Europe/Berlin (Datumsarithmetik nur ueber date).
-- Fehler: SQLSTATE ZG001, Meldung "Kein laufender Vertrag am <TT.MM.JJJJ> —
-- Platz kann nicht vergeben werden.", HINT "datum:<JJJJ-MM-TT>" fuer die UI.
--
-- session_students_coach_rw bleibt: Coach darf in EIGENE Sessions eintragen
-- (USING und WITH CHECK: session_id in session_ids_fuer_coach()). Fremde
-- Sessions und Sessions ohne Coach sind schon ausgeschlossen; die Policy ist
-- nicht weiter als noetig und wird nicht angefasst.
--
-- Bestehende Zeilen werden nicht geprueft und nicht bereinigt (der Trigger
-- greift nur bei INSERT und bei UPDATE von student_id / session_id).

begin;

create or replace function public.session_platz_zugang(p_student_id uuid, p_datum date)
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
       and v.vertragsbeginn is not null
       and v.vertrag_ende is not null
       and p_datum between v.vertragsbeginn and v.vertrag_ende
       and public.vertrag_wirksamer_status(
             v.widerrufen_am, v.gekuendigt_zum, v.vertrag_ende, v.widerruf_bis, p_datum
           ) in ('im_widerruf', 'aktiv')
  )
  or exists (
    -- Bruecke, wie hat_zugang (20260925181700_vertraege_menue_db.sql)
    select 1
      from public.vertraege alt
      join public.vertraege neu on neu.vorgaenger_id = alt.id
     where alt.student_id = p_student_id
       and alt.status = 'abgeschlossen'
       and alt.vertrag_ende is not null
       and alt.vertrag_ende < p_datum
       and neu.status = 'abgeschlossen'
       and neu.vertragsbeginn is not null
       and neu.vertragsbeginn > p_datum
  );
$$;

comment on function public.session_platz_zugang(uuid, date) is
  'true, wenn am Datum ein Vertrag laeuft (aktiv/im_widerruf, Beginn <= Datum <= Ende) oder die Bruecke vor einem unterschriebenen Folgevertrag greift. Regel fuer Plaetze in regulaeren Sessions.';

revoke all on function public.session_platz_zugang(uuid, date) from public, anon, authenticated;
grant execute on function public.session_platz_zugang(uuid, date) to authenticated;

create or replace function public.session_platz_zugang_pruefen()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_datum date;
begin
  select (cs.scheduled_at at time zone 'Europe/Berlin')::date
    into v_datum
    from public.coaching_sessions cs
   where cs.id = new.session_id;

  -- Keine Session: der Fremdschluessel meldet das selbst.
  if v_datum is null then
    return new;
  end if;

  if not public.session_platz_zugang(new.student_id, v_datum) then
    raise exception 'Kein laufender Vertrag am % — Platz kann nicht vergeben werden.',
                    to_char(v_datum, 'DD.MM.YYYY')
      using errcode = 'ZG001',
            hint    = 'datum:' || to_char(v_datum, 'YYYY-MM-DD');
  end if;

  return new;
end;
$$;

comment on function public.session_platz_zugang_pruefen() is
  'Trigger auf session_students: ein Kind nur mit session_platz_zugang(student_id, Sessiondatum Europe/Berlin), sonst SQLSTATE ZG001.';

revoke all on function public.session_platz_zugang_pruefen() from public, anon, authenticated;

create trigger session_students_zugang_trg
  before insert or update of student_id, session_id on public.session_students
  for each row execute function public.session_platz_zugang_pruefen();

-- Auswahlliste der Oberflaeche: alle Kinder, die am Datum der Session Zugang
-- haben. Admin fuer jede Session, Coach nur fuer eigene (wie die Policy).
create or replace function public.session_platz_kandidaten(p_session_id uuid)
returns setof uuid
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_rolle text := public.get_my_role();
  v_datum date;
begin
  if v_rolle = 'admin' then
    null;
  elsif v_rolle = 'coach' and p_session_id in (select public.session_ids_fuer_coach()) then
    null;
  else
    raise exception 'session_platz_kandidaten: keine Berechtigung fuer diese Session' using errcode = '42501';
  end if;

  select (cs.scheduled_at at time zone 'Europe/Berlin')::date into v_datum
    from public.coaching_sessions cs where cs.id = p_session_id;
  if v_datum is null then
    raise exception 'session_platz_kandidaten: Session nicht gefunden' using errcode = 'P0002';
  end if;

  return query
    select s.id
      from public.students s
     where not s.is_provisional
       and public.session_platz_zugang(s.id, v_datum);
end;
$$;

comment on function public.session_platz_kandidaten(uuid) is
  'Kinder, die am Datum der Session einen Platz bekommen duerfen (session_platz_zugang). Auswahlliste fuer regulaere Sessions. Admin; Coach nur fuer eigene Sessions.';

revoke all on function public.session_platz_kandidaten(uuid) from public, anon, authenticated;
grant execute on function public.session_platz_kandidaten(uuid) to authenticated;

commit;
