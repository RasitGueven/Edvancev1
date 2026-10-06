-- Q1 Home Quests — Benachrichtigung als Endpunkt (Entscheidung 21). Kein Versand in P1.
--
--   push_token_registrieren     das Konto des Kindes meldet ein Geraete-Token an
--   quest_erinnerungen_faellig  Admin oder System: offene Quests mit Termin im Fenster,
--                               fuer den spaeteren Versand (Scheduler fehlt, offener Punkt)
--   eltern_quest_wochenstand    Admin oder System: je Kind erledigt und offen einer Woche,
--                               mit der Eltern-Adresse des laufenden Vertrags. Den Versand
--                               ueber graph_mail.ts baut P2.

create function public.push_token_registrieren(
  p_token     text,
  p_plattform text,
  p_geraet    text default null
)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_student uuid := public.get_my_student_id();
  v_id      uuid;
begin
  if v_student is null then
    raise exception 'push_token_registrieren: nur fuer ein Schuelerkonto' using errcode = '42501';
  end if;
  if nullif(btrim(coalesce(p_token, '')), '') is null or length(p_token) > 4096 then
    raise exception 'push_token_registrieren: Token fehlt oder ist zu lang' using errcode = '22023';
  end if;
  if p_plattform is null or p_plattform not in ('ios', 'android', 'web') then
    raise exception 'push_token_registrieren: Plattform ios, android oder web' using errcode = '22023';
  end if;

  -- Ein Token gehoert immer dem Konto, das es zuletzt angemeldet hat (Geraetewechsel).
  insert into public.push_tokens as pt (student_id, geraet, plattform, token)
  values (v_student, nullif(btrim(coalesce(p_geraet, '')), ''), p_plattform, btrim(p_token))
  on conflict (token) do update
     set student_id  = excluded.student_id,
         geraet      = excluded.geraet,
         plattform   = excluded.plattform,
         angelegt_am = now()
  returning pt.id into v_id;
  return v_id;
end;
$$;

comment on function public.push_token_registrieren(text, text, text) is
  'Meldet ein Push-Token fuer das eigene Schuelerkonto an. Kein Versand in P1.';

create function public.quest_erinnerungen_faellig(
  p_bis timestamptz,
  p_von timestamptz default now()
)
returns table (student_id uuid, quest_id uuid, termin timestamptz)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not coalesce(public.ist_systemaufruf() or public.get_my_role() = 'admin', false) then
    raise exception 'quest_erinnerungen_faellig: nur Admin oder Systemaufruf' using errcode = '42501';
  end if;
  if p_bis is null or p_von is null or p_bis < p_von then
    raise exception 'quest_erinnerungen_faellig: Fenster ungueltig' using errcode = '22023';
  end if;

  return query
    select q.student_id, q.id, q.termin
      from public.quests q
     where q.status = 'offen'
       and q.termin is not null
       and q.termin >  p_von
       and q.termin <= p_bis
     order by q.termin, q.id;
end;
$$;

comment on function public.quest_erinnerungen_faellig(timestamptz, timestamptz) is
  'Offene Quests mit Termin im Fenster (von, bis] fuer den spaeteren Versand. Nur Admin oder System.';

create function public.eltern_quest_wochenstand(p_woche date)
returns table (student_id uuid, woche_ab date, erledigt integer, offen integer, eltern_email text)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_montag date;
begin
  if not coalesce(public.ist_systemaufruf() or public.get_my_role() = 'admin', false) then
    raise exception 'eltern_quest_wochenstand: nur Admin oder Systemaufruf' using errcode = '42501';
  end if;
  if p_woche is null then
    raise exception 'eltern_quest_wochenstand: Woche ist Pflicht' using errcode = '22023';
  end if;
  v_montag := date_trunc('week', p_woche)::date;

  -- Eltern sehen nur "erledigt" oder "offen"; verfallene Quests zaehlen als offen.
  return query
    select q.student_id, v_montag,
           count(*) filter (where q.status = 'erledigt')::integer,
           count(*) filter (where q.status <> 'erledigt')::integer,
           (select va.eltern_email from public.vertraege_aktuell va
             where va.student_id = q.student_id and va.wirksamer_status in ('im_widerruf', 'aktiv')
             order by va.vertragsbeginn desc nulls last limit 1)
      from public.quests q
     where q.faellig_ab >= v_montag and q.faellig_ab < v_montag + 7
     group by q.student_id
     order by q.student_id;
end;
$$;

comment on function public.eltern_quest_wochenstand(date) is
  'Je Kind erledigte und offene Quests der Kalenderwoche von p_woche (faellig_ab), mit Eltern-Adresse des laufenden Vertrags. Nur Admin oder System.';

revoke all on function public.push_token_registrieren(text, text, text)            from public, anon, authenticated;
revoke all on function public.quest_erinnerungen_faellig(timestamptz, timestamptz) from public, anon, authenticated;
revoke all on function public.eltern_quest_wochenstand(date)                       from public, anon, authenticated;
grant execute on function public.push_token_registrieren(text, text, text)            to authenticated;
grant execute on function public.quest_erinnerungen_faellig(timestamptz, timestamptz) to authenticated;
grant execute on function public.eltern_quest_wochenstand(date)                       to authenticated;
