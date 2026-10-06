-- Session-Rahmen P1, Paket A1 — Belege aus der Session buchen und den
-- Systemzustand des Lernpfads setzen.
--
--   lernpfad_beleg_core  ohne Rechtepruefung, nur fuer andere SECURITY
--                        DEFINER-Funktionen (P2 ruft sie aus der Session-Abgabe,
--                        die am Tablet unter dem Geraetekonto laeuft).
--   lernpfad_beleg       derselbe Weg fuer Coach der Session, Admin oder
--                        Systemaufruf.
--
-- Regel fuer stand_system (in dieser Reihenfolge):
--   1. kandidat  — es gibt eine Session, vor der schon mindestens
--                  mastery_abstand_sessions andere Sessions mit Belegen zu
--                  diesem Skill liegen, und in ihr wurde der Skill mindestens
--                  mastery_richtig_ohne_hinweis Mal richtig ohne Hinweis
--                  geloest (Entscheidung 16). Belege mit Hinweis zaehlen nicht.
--   2. sicher    — in der aktuellen Session mindestens
--                  mastery_richtig_ohne_hinweis Mal richtig ohne Hinweis.
--   3. war sicher: bleibt sicher, ausser die aktuelle Session hat mehr falsche
--                  als richtige Belege → noch_nicht_sicher.
--   4. sonst     aktiv (wird geuebt).
-- stand_coach wird hier nie gelesen oder geschrieben (Entscheidung 3).
-- Reihenfolge der Sessions: coaching_sessions.scheduled_at.

create function public.lernpfad_beleg_core(
  p_student_id      uuid,
  p_skill_key       text,
  p_session_id      uuid,
  p_ergebnis        text,
  p_hinweis_genutzt boolean
)
returns text
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_abstand  numeric := public.lernpfad_stellschraube('mastery_abstand_sessions', p_session_id);
  v_n        numeric := public.lernpfad_stellschraube('mastery_richtig_ohne_hinweis', p_session_id);
  v_alt      text;
  v_neu      text;
  v_kandidat boolean;
  v_heute    record;
  v_belege   jsonb;
begin
  if p_ergebnis is null or p_ergebnis not in ('richtig', 'teilweise', 'falsch') then
    raise exception 'lernpfad_beleg: ergebnis muss richtig, teilweise oder falsch sein' using errcode = '22023';
  end if;
  if p_hinweis_genutzt is null then
    raise exception 'lernpfad_beleg: hinweis_genutzt ist Pflicht' using errcode = '22023';
  end if;
  if not exists (select 1 from public.skills where skill_key = p_skill_key) then
    raise exception 'lernpfad_beleg: Skill % unbekannt', p_skill_key using errcode = 'P0002';
  end if;
  -- Nur Sessions vor Ort, in denen das Kind gebucht ist (Entscheidung 4).
  if not exists (select 1 from public.session_students ss
                  where ss.session_id = p_session_id and ss.student_id = p_student_id) then
    raise exception 'lernpfad_beleg: Kind ist in dieser Session nicht gebucht' using errcode = 'P0001';
  end if;

  insert into public.lernpfad_belege (student_id, skill_key, session_id, ergebnis, hinweis_genutzt)
  values (p_student_id, p_skill_key, p_session_id, p_ergebnis, p_hinweis_genutzt);

  insert into public.lernpfad (student_id, skill_key, quelle)
  values (p_student_id, p_skill_key, 'session')
  on conflict (student_id, skill_key) do nothing;

  select stand_system into v_alt
    from public.lernpfad
   where student_id = p_student_id and skill_key = p_skill_key
   for update;

  with je_session as (
    select b.session_id,
           cs.scheduled_at,
           min(b.zeit) as am,
           count(*)::int as gesamt,
           count(*) filter (where b.ergebnis = 'richtig' and not b.hinweis_genutzt)::int as ohne_hinweis,
           count(*) filter (where b.ergebnis = 'richtig')::int as richtig,
           count(*) filter (where b.ergebnis = 'falsch')::int as falsch
      from public.lernpfad_belege b
      join public.coaching_sessions cs on cs.id = b.session_id
     where b.student_id = p_student_id and b.skill_key = p_skill_key
     group by b.session_id, cs.scheduled_at
  ),
  nummeriert as (
    select *, row_number() over (order by scheduled_at, session_id) as nr
      from je_session
  )
  select bool_or(nr > v_abstand and ohne_hinweis >= v_n),
         jsonb_agg(jsonb_build_object('session_id', session_id, 'am', am, 'gesamt', gesamt,
                                      'richtig_ohne_hinweis', ohne_hinweis) order by nr)
    into v_kandidat, v_belege
    from nummeriert;

  select count(*) filter (where ergebnis = 'richtig' and not hinweis_genutzt) as ohne_hinweis,
         count(*) filter (where ergebnis = 'richtig') as richtig,
         count(*) filter (where ergebnis = 'falsch') as falsch
    into v_heute
    from public.lernpfad_belege
   where student_id = p_student_id and skill_key = p_skill_key and session_id = p_session_id;

  v_neu := case
             when v_kandidat then 'kandidat'
             when v_heute.ohne_hinweis >= v_n then 'sicher'
             when v_alt = 'sicher' and v_heute.falsch > v_heute.richtig then 'noch_nicht_sicher'
             when v_alt = 'sicher' then 'sicher'
             else 'aktiv'
           end;

  update public.lernpfad
     set stand_system      = v_neu,
         stand_system_seit = case when v_neu is distinct from v_alt then now() else stand_system_seit end,
         letzte_uebung_am  = now(),
         letzte_session_id = p_session_id,
         belege            = coalesce(v_belege, '[]'::jsonb),
         aktualisiert      = now()
   where student_id = p_student_id and skill_key = p_skill_key;

  return v_neu;
end;
$$;

comment on function public.lernpfad_beleg_core(uuid, text, uuid, text, boolean) is
  'Bucht einen Session-Beleg und setzt stand_system (Kandidat nach Entscheidung 16). Ohne Rechtepruefung: nur fuer andere SECURITY DEFINER-Funktionen.';

create function public.lernpfad_beleg(
  p_student_id      uuid,
  p_skill_key       text,
  p_session_id      uuid,
  p_ergebnis        text,
  p_hinweis_genutzt boolean
)
returns text
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
begin
  if not (public.ist_systemaufruf()
          or coalesce(public.get_my_role(), '') = 'admin'
          or public.lernpfad_coach_der_session(p_session_id, p_student_id)) then
    raise exception 'lernpfad_beleg: nur Coach der Session oder Admin' using errcode = '42501';
  end if;
  return public.lernpfad_beleg_core(p_student_id, p_skill_key, p_session_id, p_ergebnis, p_hinweis_genutzt);
end;
$$;

comment on function public.lernpfad_beleg(uuid, text, uuid, text, boolean) is
  'Bucht einen Session-Beleg (Coach der Session, Admin oder Systemaufruf) und liefert den neuen stand_system.';

revoke all on function public.lernpfad_beleg_core(uuid, text, uuid, text, boolean)
  from public, anon, authenticated;
revoke all on function public.lernpfad_beleg(uuid, text, uuid, text, boolean)
  from public, anon, authenticated;
grant execute on function public.lernpfad_beleg(uuid, text, uuid, text, boolean) to authenticated;
