-- A2.4 Verdrahtung R1 (Entscheidungen A2 J, K, L, M; offene-punkte-r1 13, 14, 15, 27).
--
-- Grundlage jeder Funktion ist ihre Definition in Prod (pg_get_functiondef, 06.10.; identisch mit
-- der R1-Migration). Geaendert ist nur, was die Kommentare an der Stelle nennen.
--   antwort_abgeben     bucht lernpfad_beleg (A1) aus Warm-up, Kernarbeit, Check-out; Testlauf nie (L).
--   aufgabe_ausgeben    Pool der Session statt nur 'ready' (J, offene-punkte-r1 14).
--   hinweis_abrufen     keine Hinweise zu Exit-Aufgaben (K).
--   phase_setzen        nur Coach der Session oder Admin; die Phase des Kindes kommt aus der Uhr (C).
--   eingriff_notieren   Stufe 4 ruft pfad_tiefer(..., anlass = eingriff) (M).
--   pfad_entscheiden    "tiefer" ruft pfad_tiefer(..., anlass = warmup) mit dem Skill aus dem Signal (E).
--   session_checkin_ableiten  Fall Lernpfad: Thema der naechsten Luecke als ziel_thema_key (D).

create or replace function public.antwort_abgeben(p_session_id uuid, p_task_id uuid, p_teil int, p_eingabe jsonb,
                                       p_dauer_ms int default null)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  t     public.session_tablets := public.session_tablet_platz(p_session_id, 'antwort_abgeben');
  a     public.session_ausgegeben;
  b     record;
  v_nr  int;
  v_hin int;
  v_skill text;
begin
  select * into a from public.session_ausgegeben
   where session_id = p_session_id and student_id = t.student_id and task_id = p_task_id
   order by zeit desc limit 1;
  if not found then
    raise exception 'antwort_abgeben: Aufgabe wurde diesem Kind nicht gegeben' using errcode = 'P0001';
  end if;
  if p_eingabe is null or jsonb_typeof(p_eingabe) = 'null' or btrim(p_eingabe #>> '{}') = '' then
    raise exception 'antwort_abgeben: leere Eingabe' using errcode = '22023';
  end if;
  if exists (select 1 from public.session_antworten where session_id = p_session_id and student_id = t.student_id
              and task_id = p_task_id and teil is not distinct from p_teil and ergebnis = 'richtig') then
    raise exception 'antwort_abgeben: schon richtig geloest' using errcode = 'P0001';
  end if;

  select * into b from public.session_bewerten(p_task_id, p_teil, p_eingabe);

  select count(*) + 1 into v_nr from public.session_antworten
   where session_id = p_session_id and student_id = t.student_id and task_id = p_task_id
     and teil is not distinct from p_teil;
  select coalesce(max((e.payload ->> 'stufe')::int), 0) into v_hin from public.session_ereignisse e
   where e.session_id = p_session_id and e.student_id = t.student_id and e.typ = 'hinweis'
     and e.payload ->> 'task_id' = p_task_id::text and (e.payload ->> 'geliefert')::boolean;

  insert into public.session_antworten (session_id, student_id, task_id, teil, versuch_nr, eingabe, ergebnis,
         fehlbild_slug, hinweisstufe_max, dauer_ms, phase, eingemischt, geraet_id, angemeldet_als)
  values (p_session_id, t.student_id, p_task_id, p_teil, v_nr, p_eingabe, b.ergebnis, b.fehlbild_slug, v_hin,
          p_dauer_ms, public.session_phase(p_session_id, t.student_id), a.eingemischt, t.geraet_id, auth.uid());

  -- A2 (L): jede Antwort aus Warm-up, Kernarbeit und Check-out bucht einen Lernpfad-Beleg mit
  -- Ergebnis und Hinweis-Nutzung. Testlaeufe buchen nie Belege (Entscheidung 27).
  select tk.skill_key into v_skill from public.tasks tk where tk.id = p_task_id;
  if v_skill is not null
     and not coalesce((select cs.testlauf from public.coaching_sessions cs where cs.id = p_session_id), false)
     and public.session_phase(p_session_id, t.student_id) in ('warmup', 'kern', 'checkout') then
    perform public.lernpfad_beleg_core(t.student_id, v_skill, p_session_id, b.ergebnis, v_hin > 0);
  end if;

  return jsonb_build_object(
    'ergebnis', b.ergebnis,
    'versuch_nr', v_nr,
    'fehlbild_klartext', (select fl.klartext from public.fehlbild_labels fl
                           where fl.slug = b.fehlbild_slug and fl.freigegeben_am is not null));
end;
$$;

create or replace function public.aufgabe_ausgeben(p_session_id uuid, p_student_id uuid, p_task_id uuid,
                                        p_eingemischt boolean default false)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_id uuid;
begin
  if not public.ist_systemaufruf() then
    perform public.session_coach_pruefen(p_session_id, 'aufgabe_ausgeben');
  end if;
  if not exists (select 1 from public.session_tablets where session_id = p_session_id
                  and student_id = p_student_id and geloest_am is null) then
    raise exception 'aufgabe_ausgeben: Kind hat kein Tablet' using errcode = 'P0001';
  end if;
  -- A2 (J): Pool der Session (Einsatz session, ready; im Testlauf auch ungepruefte ohne pruef_ausschluss).
  if not public.session_im_pool(p_task_id,
           coalesce((select cs.testlauf from public.coaching_sessions cs where cs.id = p_session_id), false)) then
    raise exception 'aufgabe_ausgeben: Aufgabe nicht im Pool der Session' using errcode = 'P0001',
      hint = 'nicht_ready';
  end if;
  insert into public.session_ausgegeben (session_id, student_id, task_id, phase, eingemischt, von)
  values (p_session_id, p_student_id, p_task_id, public.session_phase(p_session_id, p_student_id),
          coalesce(p_eingemischt, false), auth.uid())
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.hinweis_abrufen(p_session_id uuid, p_task_id uuid, p_stufe int)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  t      public.session_tablets := public.session_tablet_platz(p_session_id, 'hinweis_abrufen');
  v_text text;
begin
  if not exists (select 1 from public.session_ausgegeben where session_id = p_session_id
                  and student_id = t.student_id and task_id = p_task_id) then
    raise exception 'hinweis_abrufen: Aufgabe wurde diesem Kind nicht gegeben' using errcode = 'P0001';
  end if;
  -- A2 (K): Exit-Aufgaben im Check-out ohne Hinweise.
  if exists (select 1 from public.session_schritte x where x.session_id = p_session_id
              and x.student_id = t.student_id and x.task_id = p_task_id and x.art = 'exit') then
    raise exception 'hinweis_abrufen: Exit-Aufgaben ohne Hinweise' using errcode = '22023', hint = 'exit_ohne_hinweis';
  end if;
  if p_stufe is null or p_stufe < 1 or p_stufe > public.session_wert_zahl(p_session_id, 'hinweisstufen') then
    raise exception 'hinweis_abrufen: Stufe % ist nicht freigeschaltet', p_stufe using errcode = '22023';
  end if;
  -- Prinzip der minimalen Hilfe (Entscheidung 11): Stufe n erst nach Stufe n-1.
  if p_stufe > 1 and not exists (select 1 from public.session_ereignisse e
       where e.session_id = p_session_id and e.student_id = t.student_id and e.typ = 'hinweis'
         and e.payload ->> 'task_id' = p_task_id::text and (e.payload ->> 'stufe')::int = p_stufe - 1) then
    raise exception 'hinweis_abrufen: erst Stufe %', p_stufe - 1 using errcode = '22023', hint = 'hinweis_reihenfolge';
  end if;

  select h ->> 'text' into v_text
    from public.task_solutions s, jsonb_array_elements(s.hints) as e(h)
   where s.task_id = p_task_id and h ->> 'level' = p_stufe::text and h ->> 'status' = 'geprueft'
   order by h ->> 'text'
   limit 1;

  perform public.session_ereignis(p_session_id, t.student_id, 'hinweis',
    jsonb_build_object('task_id', p_task_id, 'stufe', p_stufe, 'geliefert', v_text is not null));
  return jsonb_build_object('stufe', p_stufe, 'text', v_text, 'verfuegbar', v_text is not null);
end;
$$;

create or replace function public.phase_setzen(p_session_id uuid, p_student_id uuid, p_phase text)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_kind uuid := p_student_id;
begin
  if p_phase is null or p_phase not in ('checkin', 'warmup', 'kern', 'checkout') then
    raise exception 'phase_setzen: unbekannte Phase %', p_phase using errcode = '22023';
  end if;
  -- A2 (C): die Phase eines Kindes ergibt sich aus der Uhr der Session; das Tablet setzt sie nicht
  -- mehr selbst (offene-punkte-r1 27). Der Coach kann ein Phasen-Ereignis setzen, die Engine
  -- richtet sich beim naechsten Schritt aber nach der Uhr (offene-punkte-a2).
  perform public.session_coach_pruefen(p_session_id, 'phase_setzen');
  if not exists (select 1 from public.session_tablets where session_id = p_session_id
                  and student_id = p_student_id and geloest_am is null) then
    raise exception 'phase_setzen: Kind hat kein Tablet' using errcode = 'P0001';
  end if;
  if public.session_phase(p_session_id, v_kind) is distinct from p_phase then
    perform public.session_ereignis(p_session_id, v_kind, 'phase_wechsel', jsonb_build_object('phase', p_phase));
  end if;
end;
$$;

create or replace function public.eingriff_notieren(p_session_id uuid, p_student_id uuid, p_stufe int,
                                         p_fehlbild_slug text default null)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_slug text := nullif(btrim(coalesce(p_fehlbild_slug, '')), '');
  v_skill text;
  v_neu   text;
  v_fehler text;
begin
  perform public.session_kind_pruefen(p_session_id, p_student_id, 'eingriff_notieren');
  if p_stufe is null or p_stufe not between 1 and 4 then
    raise exception 'eingriff_notieren: Stufe 1 bis 4' using errcode = '22023';
  end if;
  if p_stufe >= 3 and v_slug is null then
    raise exception 'eingriff_notieren: ab Stufe 3 ist das Fehlbild Pflicht' using errcode = '22023',
      hint = 'fehlbild_pflicht';
  end if;
  -- A2 (Rasit 06.10.): Stufe 4 setzt den Pfad; das darf der Coach nur in der laufenden Session oder
  -- am selben Tag nach dem Abschluss (wie pfad_tiefer / lernpfad_coach_der_session).
  if p_stufe = 4 and coalesce(public.get_my_role(), '') <> 'admin'
     and not coalesce(public.lernpfad_coach_der_session(p_session_id, p_student_id), false) then
    raise exception 'eingriff_notieren: Stufe 4 nur in der laufenden Session oder am selben Tag danach'
      using errcode = '42501';
  end if;
  if v_slug is not null and not exists (select 1 from public.fehlbild_labels where slug = v_slug) then
    raise exception 'eingriff_notieren: unbekanntes Fehlbild %', v_slug using errcode = '22023';
  end if;
  perform public.session_ereignis(p_session_id, p_student_id, 'eingriff',
    jsonb_strip_nulls(jsonb_build_object('stufe', p_stufe, 'fehlbild_slug', v_slug)));
  if p_stufe = 4 then
    -- A2 (M): Stufe 4 setzt den Pfad sofort tiefer, am Skill der aktuellen Aufgabe (bei einer
    -- eingemischten Aufgabe am aktuellen Skill des Ziels). Findet pfad_tiefer keine offene
    -- Voraussetzung, bleibt der Eingriff notiert und das Ereignis traegt den Grund.
    select tk.skill_key into v_skill
      from public.session_aktuelle_ausgabe(p_session_id, p_student_id) a
      join public.tasks tk on tk.id = a.task_id
     where not a.eingemischt;
    v_skill := coalesce(v_skill, (select z.skill_key from public.session_zielliste(p_session_id, p_student_id) z
                                   where z.offen order by z.reihenfolge limit 1));
    begin
      if v_skill is null then
        raise exception 'kein aktueller Skill' using errcode = 'P0002';
      end if;
      v_neu := public.pfad_tiefer(p_student_id, v_skill, p_session_id, null, 'eingriff');
    exception when sqlstate 'P0001' or sqlstate 'P0002' or sqlstate '22023' then
      v_fehler := sqlerrm;
    end;
    perform public.session_ereignis(p_session_id, p_student_id, 'entscheidung_pfad',
      jsonb_strip_nulls(jsonb_build_object('entscheidung', 'tiefer', 'quelle', 'eingriff', 'fehlbild_slug', v_slug,
                                           'skill_key', v_skill, 'voraussetzung', v_neu, 'fehler', v_fehler)));
  end if;
end;
$$;

create or replace function public.pfad_entscheiden(p_session_id uuid, p_student_id uuid, p_entscheidung text,
                                        p_skill_key text default null)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_sig  jsonb;
  v_ziel text;
  v_neu  text;
begin
  perform public.session_kind_pruefen(p_session_id, p_student_id, 'pfad_entscheiden');
  if p_entscheidung is null or p_entscheidung not in ('tiefer', 'plan') then
    raise exception 'pfad_entscheiden: tiefer oder plan' using errcode = '22023';
  end if;
  -- A2 (E): "tiefer" setzt den Pfad ueber pfad_tiefer (anlass warmup). Ziel-Skill und
  -- Voraussetzung kommen aus dem juengsten Entscheidungssignal; p_skill_key waehlt eine andere
  -- Voraussetzung. Ohne Signal: der aktuelle Skill des Ziels.
  if p_entscheidung = 'tiefer' then
    select e.payload into v_sig from public.session_ereignisse e
     where e.session_id = p_session_id and e.student_id = p_student_id and e.typ = 'signal'
       and e.payload ->> 'art' = 'entscheidung'
     order by e.zeit desc, e.id desc limit 1;
    v_ziel := coalesce(v_sig ->> 'ziel_skill_key',
                       (select z.skill_key from public.session_zielliste(p_session_id, p_student_id) z
                         where z.offen order by z.reihenfolge limit 1));
    if v_ziel is null then
      raise exception 'pfad_entscheiden: kein aktueller Skill' using errcode = 'P0002';
    end if;
    v_neu := public.pfad_tiefer(p_student_id, v_ziel, p_session_id, coalesce(p_skill_key, v_sig ->> 'skill_key'), 'warmup');
  end if;
  perform public.session_ereignis(p_session_id, p_student_id, 'entscheidung_pfad',
    jsonb_strip_nulls(jsonb_build_object('entscheidung', p_entscheidung, 'quelle', 'coach',
                                         'skill_key', coalesce(v_neu, p_skill_key), 'statt', v_ziel)));
  perform public.session_ereignis(p_session_id, p_student_id, 'signal_erledigt',
                                  jsonb_build_object('art', 'entscheidung'));
end;
$$;

create or replace function public.session_checkin_ableiten(p_session_id uuid, p_student_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_fall text := public.session_fall_berechnen(p_session_id, p_student_id);
begin
  update public.session_checkin c
     set fall_vorschlag = v_fall,
         ziel_thema_key = case coalesce(c.fall_coach, v_fall)
                            when 'klassenarbeit' then c.klassenarbeit_thema_key
                            when 'schulthema' then public.session_schulthema(p_student_id)
                            -- A2 (D): Lernpfad -> Thema der naechsten Luecke (nur Anzeige; die
                            -- Engine nimmt im Fall Lernpfad naechste_luecke selbst).
                            else (select n.thema_key from public.naechste_luecke_core(p_student_id) n limit 1) end
   where c.session_id = p_session_id and c.student_id = p_student_id;
end;
$$;
