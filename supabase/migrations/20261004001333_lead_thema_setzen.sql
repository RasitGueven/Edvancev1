-- lead_thema_setzen — das aktuelle Thema eines Leads in einem Schritt.
--
-- Bisher setzte die Oberflaeche (src/lib/supabase/themen.ts) das Thema in zwei
-- Aufrufen: erst das alte 'aktuell' desselben Fachs loeschen, dann das neue
-- schreiben. Brach der zweite ab, stand der Lead ohne Thema da. Diese Funktion
-- tut genau dasselbe, nur in einer Transaktion:
--
--   - das bisherige 'aktuell' fuer Lead + Fach wird GELOESCHT (wie heute; es
--     wandert nicht nach 'behandelt' — das entscheidet die Oberflaeche ueber
--     den Schulplan-Abgleich, nicht dieser Schritt),
--   - das neue Thema wird 'aktuell'; war es schon als 'behandelt' erfasst,
--     wird diese Zeile umgestellt (wie der bisherige Upsert),
--   - p_thema_key null entfernt das aktuelle Thema nur. Die Oberflaeche kennt
--     das heute nicht; die Funktion kann es, damit "entfernen" nicht wieder
--     zwei Schritte braucht, sobald sie es kennt.
--
-- Rechte wie die RLS-Regel lead_themen_admin_all: nur Admin.

create function public.lead_thema_setzen(
  p_lead_id   uuid,
  p_fach      text,
  p_thema_key text,
  p_quelle    text default 'gespraech'
)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'lead_thema_setzen: nur Admin' using errcode = '42501';
  end if;
  if p_lead_id is null or nullif(btrim(coalesce(p_fach, '')), '') is null then
    raise exception 'lead_thema_setzen: Lead und Fach sind Pflicht' using errcode = '22023';
  end if;

  delete from public.lead_themen
   where lead_id = p_lead_id
     and fach = p_fach
     and status = 'aktuell'
     and thema_key is distinct from p_thema_key;

  if p_thema_key is null then
    return;
  end if;

  insert into public.lead_themen (lead_id, fach, thema_key, status, quelle, angelegt)
  values (p_lead_id, p_fach, p_thema_key, 'aktuell', p_quelle, now())
  on conflict (lead_id, thema_key) do update
     set fach     = excluded.fach,
         status   = 'aktuell',
         quelle   = excluded.quelle,
         angelegt = excluded.angelegt;
end;
$$;

comment on function public.lead_thema_setzen(uuid, text, text, text) is
  'Setzt das aktuelle Thema eines Leads je Fach atomar (altes aktuell faellt weg); null entfernt es. Nur Admin.';

revoke all on function public.lead_thema_setzen(uuid, text, text, text)
  from public, anon, authenticated;
grant execute on function public.lead_thema_setzen(uuid, text, text, text) to authenticated;
