-- Schuelerakte S2b: Stammdaten aendern und Sessions der Akte.
--
-- Entscheidungen Rasit (30.09.2026) zu den Grenzen aus #177:
--   1. akte_stammdaten_aendern — Name (profiles.full_name), Klasse und Schule
--      (students) in einem Aufruf; nur Admin; protokolliert.
--   2. akte_sessions — alle Sessions des Kindes seit Beginn der Akte; Admin
--      immer, Coach nur bei aktiver Akte (wie einheiten_stand). KEINE
--      RLS-Aenderung an coaching_sessions / session_students.
--
-- Rueckwaertskompatibel: nur neue Funktionen, keine Aenderung an Tabellen,
-- Policies oder bestehenden Funktionen. Das live Frontend (#177) ruft sie nicht
-- auf und laeuft unveraendert weiter.

begin;

-- ============================================================================
-- 1. akte_stammdaten_aendern
-- ============================================================================

create or replace function public.akte_stammdaten_aendern(
  p_student_id uuid,
  p_name       text,
  p_klasse     integer,
  p_schule_id  uuid
)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_profil uuid;
  v_name   text := nullif(btrim(coalesce(p_name, '')), '');
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'akte_stammdaten_aendern: nur Admin' using errcode = '42501';
  end if;

  select s.profile_id into v_profil from public.students s where s.id = p_student_id for update;
  if not found then
    raise exception 'akte_stammdaten_aendern: Kind nicht gefunden' using errcode = 'P0002';
  end if;
  if not exists (select 1 from public.vertraege v where v.student_id = p_student_id and v.status = 'abgeschlossen') then
    raise exception 'akte_stammdaten_aendern: keine Akte zu diesem Kind' using errcode = 'P0002';
  end if;
  if v_name is null then
    raise exception 'akte_stammdaten_aendern: der Name ist leer' using errcode = '22023';
  end if;
  if p_klasse is not null and (p_klasse < 5 or p_klasse > 13) then
    raise exception 'akte_stammdaten_aendern: Klasse % ist nicht 5 bis 13', p_klasse using errcode = '22023';
  end if;
  if p_schule_id is not null and not exists (select 1 from public.schulen where id = p_schule_id) then
    raise exception 'akte_stammdaten_aendern: Schule nicht gefunden' using errcode = 'P0002';
  end if;

  -- Der Name lebt am Profil. Eine Akte ohne Profil (Kind ohne Konto, etwa
  -- Testdaten) zeigt den Namen aus dem Vertrag; aendern laesst er sich dann
  -- nicht — der Aufruf meldet das, statt still nichts zu tun. Bleibt der Name
  -- gleich, gehen Klasse und Schule trotzdem durch.
  if v_profil is null then
    if v_name is distinct from (
      select nullif(btrim(concat_ws(' ', v.kind_vorname, v.kind_nachname)), '')
        from public.vertraege v
       where v.student_id = p_student_id and v.status = 'abgeschlossen'
       order by v.vertragsbeginn desc nulls last
       limit 1
    ) then
      raise exception 'akte_stammdaten_aendern: das Kind hat kein Profil, der Name steht nur im Vertrag'
        using errcode = 'P0001';
    end if;
  else
    update public.profiles set full_name = v_name where id = v_profil;
  end if;

  update public.students
     set class_level = p_klasse,
         schule_id   = p_schule_id
   where id = p_student_id;

  perform public.audit_log_schreiben('akte_stammdaten_aendern', 'student', p_student_id);
end;
$$;

comment on function public.akte_stammdaten_aendern(uuid, text, integer, uuid) is
  'Stammdaten der Akte: Name (profiles.full_name), Klasse und Schule (students). Nur Admin, sonst 42501. Protokolliert in audit_log.';

revoke all on function public.akte_stammdaten_aendern(uuid, text, integer, uuid) from public, anon, authenticated;
grant execute on function public.akte_stammdaten_aendern(uuid, text, integer, uuid) to authenticated;

-- ============================================================================
-- 2. akte_sessions
-- ============================================================================
--
-- Seit Beginn der Akte = Sessions ab abgeschlossen_am des ersten Vertrags
-- (Datum Europe/Berlin). Coach-Name aus profiles.

create or replace function public.akte_sessions(p_student_id uuid)
returns table (
  session_id   uuid,
  scheduled_at timestamptz,
  coach_id     uuid,
  coach_name   text,
  attendance   text
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_rolle text := public.get_my_role();
  v_seit  date;
begin
  if v_rolle = 'admin' then
    null;
  elsif v_rolle = 'coach' and public.akte_aktiv(p_student_id) then
    null;
  else
    raise exception 'akte_sessions: keine Berechtigung fuer diese Akte' using errcode = '42501';
  end if;

  select min(v.abgeschlossen_am) into v_seit
    from public.vertraege v
   where v.student_id = p_student_id and v.status = 'abgeschlossen';

  return query
    select cs.id, cs.scheduled_at, cs.coach_id, p.full_name, ss.attendance
      from public.session_students ss
      join public.coaching_sessions cs on cs.id = ss.session_id
      left join public.profiles p on p.id = cs.coach_id
     where ss.student_id = p_student_id
       and v_seit is not null
       and (cs.scheduled_at at time zone 'Europe/Berlin')::date >= v_seit
     order by cs.scheduled_at desc;
end;
$$;

comment on function public.akte_sessions(uuid) is
  'Alle Sessions des Kindes seit Beginn der Akte, neueste zuerst. Admin immer, Coach nur bei aktiver Akte, sonst 42501.';

revoke all on function public.akte_sessions(uuid) from public, anon, authenticated;
grant execute on function public.akte_sessions(uuid) to authenticated;

commit;
