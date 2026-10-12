-- T2 (Session-Rahmen): kein Lernpfad im Testlauf (Entscheidung 27, offene-punkte-t1 Befund 3).
--
-- In den Lernpfad schreiben aus der Session genau zwei Funktionen: pfad_tiefer und
-- mastery_entscheiden. pfad_entscheiden ("Eine Stufe tiefer") und eingriff_notieren
-- (Stufe 4) schreiben nur ueber pfad_tiefer; ihre eigenen Schreibzugriffe gehen in
-- session_ereignisse und bleiben. Deshalb werden nur diese beiden ersetzt:
--
-- - pfad_tiefer: Tor, Pruefungen und Zielwahl wie bisher. In einer Testlauf-Session
--   (coaching_sessions.testlauf) endet die Funktion danach und gibt das Ziel zurueck,
--   ohne lernpfad oder lernpfad_protokoll zu schreiben. Das Session-Ereignis
--   entscheidung_pfad der Aufrufer traegt dasselbe Ziel wie in einer echten Session.
-- - mastery_entscheiden: Tor und Pruefungen wie bisher; im Testlauf kommt dieselbe
--   Antwort, aber ohne update auf lernpfad und ohne Protokollzeile.
--
-- Nicht umgebaut (Auftrag): Der Planer liest "eine Stufe tiefer" aus lernpfad und
-- lernpfad_protokoll (session_zielliste -> ziel_fertigkeiten_core). Im Testlauf
-- aendert "Tiefer gehen" den naechsten Schritt deshalb nicht. Offener Punkt, siehe
-- docs/session/offene-punkte-t2.md.
--
-- Signatur, SECURITY DEFINER, search_path und Grants wie in Prod (pg_get_functiondef);
-- create or replace behaelt die ACL.

create or replace function public.mastery_entscheiden(p_student_id uuid, p_skill_key text, p_entscheidung text, p_grund text DEFAULT NULL::text, p_session_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_alt public.lernpfad;
  -- T2: im Testlauf schreibt die Entscheidung nichts in lernpfad/lernpfad_protokoll.
  v_test boolean := coalesce((select cs.testlauf from public.coaching_sessions cs where cs.id = p_session_id), false);
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

  if v_test then
    return jsonb_build_object('ok', true, 'skill_key', p_skill_key,
                              'stand_system', v_alt.stand_system, 'stand_coach', p_entscheidung);
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
$function$;

create or replace function public.pfad_tiefer(p_student_id uuid, p_skill_key text, p_session_id uuid DEFAULT NULL::uuid, p_voraussetzung text DEFAULT NULL::text, p_anlass text DEFAULT 'warmup'::text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_ziel     text;
  v_alt      public.lernpfad;
  -- T2: im Testlauf bleibt der Lernpfad unberuehrt; geprueft und gewaehlt wird wie sonst.
  v_test     boolean := coalesce((select cs.testlauf from public.coaching_sessions cs where cs.id = p_session_id), false);
begin
  if not (public.ist_systemaufruf()
          or coalesce(public.get_my_role(), '') = 'admin'
          or public.lernpfad_coach_der_session(p_session_id, p_student_id)) then
    raise exception 'pfad_tiefer: nur Coach der Session oder Admin' using errcode = '42501';
  end if;
  if p_anlass is null or p_anlass not in ('warmup', 'eingriff') then
    raise exception 'pfad_tiefer: Anlass muss warmup oder eingriff sein' using errcode = '22023';
  end if;
  if not exists (select 1 from public.skills where skill_key = p_skill_key) then
    raise exception 'pfad_tiefer: Skill % unbekannt', p_skill_key using errcode = 'P0002';
  end if;

  if p_voraussetzung is not null then
    if p_voraussetzung not in (select a.skill_key from public.lsa_abschluss(p_skill_key) a) then
      raise exception 'pfad_tiefer: % ist keine Voraussetzung von %', p_voraussetzung, p_skill_key
        using errcode = '22023';
    end if;
    v_ziel := p_voraussetzung;
  else
    -- Direkte Voraussetzung, die noch nicht sicher ist: zuerst belegte
    -- Luecken, dann aktive, dann unbekannte; bei Gleichstand die hoehere Klasse.
    select k.voraussetzt_skill_key into v_ziel
      from public.skill_kante k
      join public.skills s on s.skill_key = k.voraussetzt_skill_key
      left join public.lernpfad l on l.student_id = p_student_id and l.skill_key = k.voraussetzt_skill_key
     where k.skill_key = p_skill_key
       and coalesce(l.stand_system, 'offen') not in ('sicher', 'kandidat')
       and l.stand_coach is distinct from 'gemeistert'
     order by case coalesce(l.stand_system, 'offen')
                when 'noch_nicht_sicher' then 0 when 'aktiv' then 1 else 2 end,
              s.klasse_herkunft desc, k.voraussetzt_skill_key
     limit 1;
    if v_ziel is null then
      raise exception 'pfad_tiefer: % hat keine offene Voraussetzung', p_skill_key using errcode = 'P0002';
    end if;
  end if;

  select * into v_alt from public.lernpfad
   where student_id = p_student_id and skill_key = v_ziel
   for update;
  if v_alt.stand_system = 'kandidat' or v_alt.stand_coach = 'gemeistert' then
    raise exception 'pfad_tiefer: % ist Mastery-Kandidat oder gemeistert', v_ziel using errcode = 'P0001';
  end if;

  if v_test then
    return v_ziel;
  end if;

  insert into public.lernpfad (student_id, skill_key, stand_system, quelle)
  values (p_student_id, v_ziel, 'aktiv', 'coach')
  on conflict (student_id, skill_key) do update
     set stand_system      = 'aktiv',
         stand_system_seit = case when public.lernpfad.stand_system = 'aktiv'
                                  then public.lernpfad.stand_system_seit else now() end,
         aktualisiert      = now();

  -- Der bisherige Skill wartet, bis die Voraussetzung sitzt.
  insert into public.lernpfad (student_id, skill_key, stand_system, quelle)
  values (p_student_id, p_skill_key, 'offen', 'coach')
  on conflict (student_id, skill_key) do update
     set stand_system      = 'offen',
         stand_system_seit = now(),
         aktualisiert      = now()
   where public.lernpfad.stand_system = 'aktiv';

  -- Jeder Aufruf wird protokolliert: wer, wann, Session, Anlass (Rasit 06.10.).
  insert into public.lernpfad_protokoll (student_id, skill_key, aktion, anlass, alt, neu, von, session_id)
  values (p_student_id, v_ziel, 'pfad_tiefer', p_anlass,
          jsonb_build_object('stand_system', v_alt.stand_system),
          jsonb_build_object('stand_system', 'aktiv', 'statt', p_skill_key),
          auth.uid(), p_session_id);

  return v_ziel;
end;
$function$;
