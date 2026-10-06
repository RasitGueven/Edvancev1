-- Session-Rahmen P1, Paket A1 — Mastery-Entscheidung, Pruefgespraech, Sicht
-- des Kindes.
--
--   mastery_entscheiden   der vierte Schritt der Mastery-Pruefung
--                         (Entscheidung 16): der Coach bucht „gemeistert“ oder
--                         „vertagt“ (mit Grund). Nur der Coach einer Session, in
--                         der das Kind gebucht ist, oder ein Admin; nur bei
--                         vorgeschlagenem Kandidaten (lernpfad_pruefung_faellig:
--                         nach „vertagt“ erst wieder mit neuen Belegen aus einer
--                         spaeteren Session). „Gemeistert“ ist endgueltig; eine
--                         Ruecknahme durch den Coach kommt mit C2. Schreibt ausschliesslich
--                         stand_coach und die coach_*-Spalten, nie stand_system
--                         (Entscheidung 3). Protokoll in lernpfad_protokoll.
--                         Badges koppelt P2 an (offener Punkt A1-4).
--   mastery_vorschlaege   die zur Pruefung vorgeschlagenen Kandidaten eines Kindes
--                         (fuer die Warteschlange im Raum, P2).
--   skill_pruefung_lesen  Pruefgespraeche eines Skills, nur 'freigegeben', nur
--                         fuer Coach und Admin (die Erwartung ist Coach-Wissen).
--   mein_lernpfad         der eigene Stand fuer das Kind. „gemeistert“ nur aus
--                         stand_coach; ein Mastery-Kandidat erscheint als
--                         „sicher“, denn das System spricht nie von Meisterschaft
--                         (Entscheidung 6).

create function public.mastery_entscheiden(
  p_student_id   uuid,
  p_skill_key    text,
  p_entscheidung text,
  p_grund        text default null,
  p_session_id   uuid default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_alt public.lernpfad;
begin
  -- Kein Systemaufruf: „gemeistert“ entsteht nur durch einen Menschen (FernUSG).
  if not (coalesce(public.get_my_role(), '') = 'admin'
          or public.lernpfad_coach_der_session(p_session_id, p_student_id)) then
    raise exception 'mastery_entscheiden: nur Coach der Session oder Admin' using errcode = '42501';
  end if;
  if p_entscheidung is null or p_entscheidung not in ('gemeistert', 'vertagt') then
    raise exception 'mastery_entscheiden: Entscheidung muss gemeistert oder vertagt sein' using errcode = '22023';
  end if;

  select * into v_alt from public.lernpfad
   where student_id = p_student_id and skill_key = p_skill_key
   for update;
  if not found or v_alt.stand_system <> 'kandidat' then
    raise exception 'mastery_entscheiden: % ist kein Mastery-Kandidat', p_skill_key using errcode = 'P0001';
  end if;
  if v_alt.stand_coach = 'gemeistert' then
    raise exception 'mastery_entscheiden: % ist bereits gemeistert', p_skill_key using errcode = 'P0001';
  end if;
  if not public.lernpfad_pruefung_faellig(p_student_id, p_skill_key) then
    raise exception 'mastery_entscheiden: % ist vertagt; neu vorgeschlagen erst mit neuen Belegen aus einer spaeteren Session',
      p_skill_key using errcode = 'P0001';
  end if;
  if p_entscheidung = 'vertagt' and nullif(btrim(coalesce(p_grund, '')), '') is null then
    raise exception 'mastery_entscheiden: Vertagen braucht einen Grund' using errcode = '22023';
  end if;

  update public.lernpfad
     set stand_coach      = p_entscheidung,
         coach_grund      = nullif(btrim(coalesce(p_grund, '')), ''),
         coach_von        = auth.uid(),
         coach_am         = clock_timestamp(),
         coach_session_id = p_session_id,
         aktualisiert     = now()
   where id = v_alt.id;

  insert into public.lernpfad_protokoll (student_id, skill_key, aktion, anlass, alt, neu, grund, von, session_id)
  values (p_student_id, p_skill_key, 'mastery', 'pruefung',
          jsonb_build_object('stand_system', v_alt.stand_system, 'stand_coach', v_alt.stand_coach),
          jsonb_build_object('stand_coach', p_entscheidung),
          nullif(btrim(coalesce(p_grund, '')), ''), auth.uid(), p_session_id);

  return jsonb_build_object('ok', true, 'skill_key', p_skill_key,
                            'stand_system', v_alt.stand_system, 'stand_coach', p_entscheidung);
end;
$$;

comment on function public.mastery_entscheiden(uuid, text, text, text, uuid) is
  'Coach-Entscheidung zur Mastery (gemeistert | vertagt mit Grund). Nur Coach der Session mit gebuchtem Kind oder Admin, nur bei vorgeschlagenem Kandidaten (lernpfad_pruefung_faellig). Aendert stand_system nie; gemeistert ist endgueltig.';

create function public.mastery_vorschlaege(p_student_id uuid)
returns table (skill_key text, label text, stand_coach text, coach_grund text, letzte_uebung_am timestamptz)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
begin
  if not (public.ist_systemaufruf() or public.lernpfad_darf_lesen(p_student_id)) then
    raise exception 'mastery_vorschlaege: nur Admin oder Coach bei laufendem Vertrag' using errcode = '42501';
  end if;
  return query
    select l.skill_key, s.label, l.stand_coach, l.coach_grund, l.letzte_uebung_am
      from public.lernpfad l
      join public.skills s on s.skill_key = l.skill_key
     where l.student_id = p_student_id
       and public.lernpfad_pruefung_faellig(l.student_id, l.skill_key)
     order by l.stand_system_seit, l.skill_key;
end;
$$;

comment on function public.mastery_vorschlaege(uuid) is
  'Zur Mastery-Pruefung vorgeschlagene Kandidaten eines Kindes (ohne Entscheidung, oder vertagt mit neuen Belegen aus einer spaeteren Session). Admin oder Coach bei laufendem Vertrag.';

create function public.skill_pruefung_lesen(p_skill_key text)
returns table (id uuid, skill_key text, frage text, erwartung text, kriterium text, quelle text)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
begin
  if coalesce(public.get_my_role(), '') not in ('coach', 'admin') then
    raise exception 'skill_pruefung_lesen: nur Coach oder Admin' using errcode = '42501';
  end if;
  return query
    select p.id, p.skill_key, p.frage, p.erwartung, p.kriterium, p.quelle
      from public.skill_pruefung p
     where p.skill_key = p_skill_key
       and p.status = 'freigegeben'
     order by p.angelegt, p.id;
end;
$$;

comment on function public.skill_pruefung_lesen(text) is
  'Freigegebene Pruefgespraeche eines Skills (Frage, Erwartung, Kriterium). Nur Coach und Admin; Entwuerfe und geprueft-aber-nicht-freigegeben nie.';

create function public.mein_lernpfad()
returns table (skill_key text, label text, stand text, seit timestamptz)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  v_student uuid := public.get_my_student_id();
begin
  if v_student is null then
    raise exception 'mein_lernpfad: nur fuer Schuelerkonten' using errcode = '42501';
  end if;
  return query
    select l.skill_key, s.label,
           case when l.stand_coach = 'gemeistert' then 'gemeistert'
                when l.stand_system = 'kandidat'  then 'sicher'
                else l.stand_system end,
           case when l.stand_coach = 'gemeistert' then l.coach_am else l.stand_system_seit end
      from public.lernpfad l
      join public.skills s on s.skill_key = l.skill_key
     where l.student_id = v_student
     order by s.klasse_herkunft, s.fundament_tiefe, l.skill_key;
end;
$$;

comment on function public.mein_lernpfad() is
  'Eigener Lernpfad des Kindes. gemeistert nur mit stand_coach; Mastery-Kandidat erscheint als sicher (Entscheidung 6).';

revoke all on function public.mastery_entscheiden(uuid, text, text, text, uuid) from public, anon, authenticated;
revoke all on function public.mastery_vorschlaege(uuid) from public, anon, authenticated;
revoke all on function public.skill_pruefung_lesen(text) from public, anon, authenticated;
revoke all on function public.mein_lernpfad() from public, anon, authenticated;
grant execute on function public.mastery_entscheiden(uuid, text, text, text, uuid) to authenticated;
grant execute on function public.mastery_vorschlaege(uuid) to authenticated;
grant execute on function public.skill_pruefung_lesen(text) to authenticated;
grant execute on function public.mein_lernpfad() to authenticated;
