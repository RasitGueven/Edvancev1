-- T2 (Session-Rahmen): Testlauf-Schalter im Stundenplan.
--
-- session_testlauf_setzen gab es seit X0 (20261007100200), aber ohne Oberflaeche
-- (offene-punkte-t1, Befund 1). Der Schalter auf /admin/schedule ruft diese
-- Funktion. Neu ist nur eine Pruefung: Umschalten geht nur, solange die Session
-- nicht gestartet ist (gestartet_am leer und Status 'upcoming'). Sonst haette ein
-- halber Lauf schon Belege, XP oder Einheiten gebucht, die der Testlauf nie
-- haette schreiben duerfen (oder umgekehrt). Fehlercode 55000
-- (object_not_in_prerequisite_state), Hinweis 'session_gestartet'.
--
-- Unveraendert: Admin-Tor (42501), Session fehlt (P0002), echtes Kind gebucht
-- (Trigger coaching_sessions_testlauf_pruefen, 22023). Signatur, SECURITY
-- DEFINER, search_path und Grants wie in Prod; create or replace behaelt die ACL.

create or replace function public.session_testlauf_setzen(p_session_id uuid, p_testlauf boolean)
 returns void
 language plpgsql
 security definer
 set search_path to 'public', 'pg_temp'
as $function$
declare
  v_sess public.coaching_sessions;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'session_testlauf_setzen: nur Admin' using errcode = '42501';
  end if;
  -- T2: Zeile sperren, damit kein Start zwischen Pruefung und Update faellt.
  select * into v_sess from public.coaching_sessions where id = p_session_id for update;
  if not found then
    raise exception 'session_testlauf_setzen: Session nicht gefunden' using errcode = 'P0002';
  end if;
  if v_sess.gestartet_am is not null or v_sess.status is distinct from 'upcoming' then
    raise exception 'session_testlauf_setzen: Session ist schon gestartet' using errcode = '55000',
      hint = 'session_gestartet';
  end if;
  update public.coaching_sessions set testlauf = coalesce(p_testlauf, false) where id = p_session_id;
end;
$function$;

comment on function public.session_testlauf_setzen(uuid, boolean) is
  'Markiert eine Coaching-Session als Testlauf. Nur Admin, nur vor dem Start (55000), nur wenn alle gebuchten Kinder Testkonten sind.';
