-- C2.3 Offene Sessions (offene-punkte-a2 Befund 16, Rasit 06.10.): Sessions, die nach ihrem geplanten
-- Ende (scheduled_at + 60 Minuten, Entscheidung 1) plus 30 Minuten Nachbereitung noch nicht
-- abgeschlossen sind. Dieselbe Grenze wie die Zeitbindung der Coach-Entscheidungen
-- (20261008124412_a2_verdrahtung_a1_e1.sql). Gezeigt auf der Admin-Startseite und der Coach-Startseite.
--
-- sessions_offen(): Admin alle, Coach nur die eigenen; sonst 42501 (NULL-sicher, Konto ohne Profil 42501).
-- Testlaeufe erscheinen mit Kennzeichen: auch ein vergessener Testlauf muss abgeschlossen werden.

create function public.sessions_offen()
returns table (session_id uuid, scheduled_at timestamptz, room text, status text, coach_id uuid,
               coach_name text, testlauf boolean, kinder int)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_rolle text := coalesce(public.get_my_role(), '');
begin
  if v_rolle not in ('admin', 'coach') then
    raise exception 'sessions_offen: nur Admin oder Coach' using errcode = '42501';
  end if;
  return query
    select cs.id, cs.scheduled_at, cs.room, cs.status, cs.coach_id,
           (select p.full_name from public.profiles p where p.id = cs.coach_id),
           cs.testlauf,
           (select count(*)::int from public.session_students ss where ss.session_id = cs.id)
      from public.coaching_sessions cs
     where cs.status <> 'done'
       and now() > cs.scheduled_at + interval '60 minutes' + interval '30 minutes'
       and (v_rolle = 'admin' or cs.coach_id = auth.uid())
     order by cs.scheduled_at;
end;
$$;

comment on function public.sessions_offen() is
  'C2: Sessions nach scheduled_at + 60 + 30 Minuten, die nicht abgeschlossen sind. Admin alle, Coach eigene.';

revoke all on function public.sessions_offen() from public, anon, authenticated;
grant execute on function public.sessions_offen() to authenticated;
