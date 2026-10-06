-- Session-Rahmen P1, Paket A1 — Uebernahme aus der LSA und naechste Luecke.
--
--   lernpfad_lsa_urteile  intern: das juengste Urteil je Skill aus den
--                         abgeschlossenen LSA-Sitzungen des Kindes, ohne
--                         Testlaeufe (X0) und ohne 'ungeprueft'.
--   lernpfad_aus_lsa      legt den Lernpfad aus diesen Urteilen und aus
--                         student_focus_areas (skill_key, nicht verworfen) an
--                         (Entscheidung 23). Microskill-Tabellen bleiben
--                         unberuehrt.
--   naechste_luecke       Ziel fuer den Fall „Lernpfad“ (Entscheidung 9). In
--                         der ersten Session nach der LSA kommt es aus deren
--                         Urteilen, also derselben Grundlage wie der Report.
--
-- Abbildung Urteil → stand_system:
--   traegt                                         → sicher
--   traegt_teilweise, traegt_nicht, nicht_angesetzt → noch_nicht_sicher
--   ungeprueft                                     → keine Zeile (gehoert in
--                                                    den Report, nicht in den
--                                                    Pfad; wie lsa_uebernahme)

create function public.lernpfad_lsa_urteile(p_student_id uuid)
returns table (skill_key text, zustand text, lsa_session_id uuid)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select distinct on (u.skill_key) u.skill_key, u.zustand, u.session_id
    from public.lsa_skill_urteil u
    join public.lsa_sessions ls on ls.id = u.session_id
   where (ls.student_id = p_student_id or ls.uebernommen_zu_student_id = p_student_id)
     and ls.status = 'completed'
     -- Testlauf-Spalte kommt mit X0; ueber to_jsonb, damit A1 auch ohne sie laeuft.
     and not coalesce((to_jsonb(ls) ->> 'testlauf')::boolean, false)
     and u.zustand <> 'ungeprueft'
   order by u.skill_key, ls.completed_at desc nulls last, u.aktualisiert desc;
$$;

comment on function public.lernpfad_lsa_urteile(uuid) is
  'Intern: juengstes Skill-Urteil je Skill aus abgeschlossenen LSA-Sitzungen des Kindes, ohne Testlaeufe und ohne ungeprueft.';

create function public.lernpfad_aus_lsa(p_student_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_angelegt     int;
  v_aktualisiert int;
begin
  if not (public.ist_systemaufruf() or public.lernpfad_darf_lesen(p_student_id)) then
    raise exception 'lernpfad_aus_lsa: nur Admin oder Coach bei laufendem Vertrag' using errcode = '42501';
  end if;
  if not exists (select 1 from public.students where id = p_student_id) then
    raise exception 'lernpfad_aus_lsa: Kind nicht gefunden' using errcode = 'P0002';
  end if;

  with quelle as (
    select u.skill_key,
           case when u.zustand = 'traegt' then 'sicher' else 'noch_nicht_sicher' end as stand,
           u.lsa_session_id
      from public.lernpfad_lsa_urteile(p_student_id) u
    union all
    -- Fokus-Zeilen auf Skill-Ebene ohne eigenes Urteil (z. B. von Hand angelegt).
    select * from (
      select distinct on (f.skill_key) f.skill_key, 'noch_nicht_sicher', f.herkunfts_session_id
        from public.student_focus_areas f
       where f.student_id = p_student_id
         and f.skill_key is not null
         and f.status <> 'verworfen'
         and f.skill_key not in (select u.skill_key from public.lernpfad_lsa_urteile(p_student_id) u)
       order by f.skill_key, f.created_at desc
    ) fokus
  ),
  geschrieben as (
    insert into public.lernpfad as l (student_id, skill_key, stand_system, quelle, lsa_session_id)
    select p_student_id, q.skill_key, q.stand, 'lsa', q.lsa_session_id
      from quelle q
    on conflict (student_id, skill_key) do update
       set stand_system      = excluded.stand_system,
           stand_system_seit = now(),
           lsa_session_id    = excluded.lsa_session_id,
           aktualisiert      = now()
     -- Nur reine LSA-Zeilen auffrischen: nie nach Session-Belegen, nie nach
     -- einer Coach-Entscheidung, nie ohne Aenderung.
     where l.quelle = 'lsa'
       and l.belege = '[]'::jsonb
       and l.stand_coach is null
       and (l.stand_system, l.lsa_session_id) is distinct from (excluded.stand_system, excluded.lsa_session_id)
    returning l.skill_key, l.stand_system, l.lsa_session_id, (xmax = 0) as angelegt
  ),
  protokolliert as (
    insert into public.lernpfad_protokoll (student_id, skill_key, aktion, neu, von)
    select p_student_id, g.skill_key, 'uebernahme',
           jsonb_build_object('stand_system', g.stand_system, 'lsa_session_id', g.lsa_session_id,
                              'angelegt', g.angelegt),
           auth.uid()
      from geschrieben g
  )
  select count(*) filter (where g.angelegt), count(*) filter (where not g.angelegt)
    into v_angelegt, v_aktualisiert
    from geschrieben g;

  return jsonb_build_object('ok', true, 'angelegt', v_angelegt, 'aktualisiert', v_aktualisiert);
end;
$$;

comment on function public.lernpfad_aus_lsa(uuid) is
  'Uebernimmt Skill-Urteile der LSA und Fokus-Zeilen (skill_key) in den Lernpfad. Idempotent; aendert keine Zeile mit Session-Belegen oder Coach-Entscheidung. Admin oder Coach bei laufendem Vertrag.';

-- Naechste Luecke. Reihenfolge:
--   1. ein Skill mit stand_system 'aktiv' (zuletzt gesetzt zuerst)
--   2. die unterste Luecke im Lernpfad (noch_nicht_sicher): die mit den
--      wenigsten anderen Luecken unter sich (lsa_abschluss); bei Gleichstand
--      die hoehere Klasse, dann fundament_tiefe absteigend, dann skill_key
--   3. ohne Lernpfad: dieselbe Regel direkt auf den LSA-Urteilen (erste
--      Session nach der LSA, noch keine Uebernahme)
-- Gemeisterte Skills sind nie eine Luecke. quelle: 'lernpfad' oder 'lsa'
-- (Zeile stammt aus der LSA und hat noch keinen Session-Beleg).
create function public.naechste_luecke(p_student_id uuid)
returns table (skill_key text, label text, thema_key text, stand_system text, quelle text)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
begin
  if not (public.ist_systemaufruf() or public.lernpfad_darf_lesen(p_student_id)) then
    raise exception 'naechste_luecke: nur Admin oder Coach bei laufendem Vertrag' using errcode = '42501';
  end if;

  return query
    select l.skill_key, s.label, st.thema_key, l.stand_system,
           case when l.quelle = 'lsa' and l.belege = '[]'::jsonb then 'lsa' else 'lernpfad' end
      from public.lernpfad l
      join public.skills s on s.skill_key = l.skill_key
      left join public.skill_thema st on st.skill_key = l.skill_key
     where l.student_id = p_student_id
       and l.stand_system = 'aktiv'
       and l.stand_coach is distinct from 'gemeistert'
     order by l.stand_system_seit desc, l.skill_key
     limit 1;
  if found then
    return;
  end if;

  return query
    with luecke as (
      select l.skill_key, l.stand_system, l.quelle, l.belege
        from public.lernpfad l
       where l.student_id = p_student_id
         and l.stand_system = 'noch_nicht_sicher'
         and l.stand_coach is distinct from 'gemeistert'
    )
    select g.skill_key, s.label, st.thema_key, g.stand_system,
           case when g.quelle = 'lsa' and g.belege = '[]'::jsonb then 'lsa' else 'lernpfad' end
      from luecke g
      join public.skills s on s.skill_key = g.skill_key
      left join public.skill_thema st on st.skill_key = g.skill_key
     order by (select count(*) from public.lsa_abschluss(g.skill_key) a
                where a.skill_key in (select skill_key from luecke)),
              s.klasse_herkunft desc, s.fundament_tiefe desc, g.skill_key
     limit 1;
  if found then
    return;
  end if;

  -- Erste Session nach der LSA, Lernpfad noch nicht uebernommen.
  if not exists (select 1 from public.lernpfad l where l.student_id = p_student_id) then
    return query
      with luecke as (
        select u.skill_key from public.lernpfad_lsa_urteile(p_student_id) u where u.zustand <> 'traegt'
      )
      select g.skill_key, s.label, st.thema_key, 'noch_nicht_sicher'::text, 'lsa'::text
        from luecke g
        join public.skills s on s.skill_key = g.skill_key
        left join public.skill_thema st on st.skill_key = g.skill_key
       order by (select count(*) from public.lsa_abschluss(g.skill_key) a
                  where a.skill_key in (select skill_key from luecke)),
                s.klasse_herkunft desc, s.fundament_tiefe desc, g.skill_key
       limit 1;
  end if;
end;
$$;

comment on function public.naechste_luecke(uuid) is
  'Ziel fuer den Fall Lernpfad: aktiver Skill, sonst unterste Luecke im Lernpfad, ohne Lernpfad aus den LSA-Urteilen. Admin oder Coach bei laufendem Vertrag.';

revoke all on function public.lernpfad_lsa_urteile(uuid) from public, anon, authenticated;
revoke all on function public.lernpfad_aus_lsa(uuid) from public, anon, authenticated;
revoke all on function public.naechste_luecke(uuid) from public, anon, authenticated;
grant execute on function public.lernpfad_aus_lsa(uuid) to authenticated;
grant execute on function public.naechste_luecke(uuid) to authenticated;
