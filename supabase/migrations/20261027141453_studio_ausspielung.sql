-- Reihe 1 · Bauauftrag B6: Ausspielung der Erklärvideos (Anforderung Studio §9, Konzept Sessionreihe 1 §9).
--
-- Session: Eine Kernidee mit freigegebenem Video (studio_ausgabe, nicht zurückgezogen) gilt im E1-Ablauf als
-- auslieferbar, auch ohne Karten-Variante. erklaer_start bzw. erklaer_zeigen liefern dann zusätzlich `video` (Welt des
-- Kindes, sonst Skelett; Datei-Pfade im Bucket studio, Kapitel, Beat-Bereich der Kernidee, Anker des Mini-Checks). Die
-- Check-Aufgabe kommt aus der Ausgabe: Runde 1 die Hauptfrage, jede weitere Runde die nächste Fassung mit anderen
-- Zahlen (Zwilling). erklaer_check_abgeben kennt die Antwortart `ruecksprung` (Beat, Rückmeldung, danach dieselbe
-- Frage mit anderen Zahlen); ohne Rücksprung zum Fehlbild gilt die bestehende Variantenlogik, nach
-- erklaerrunden_bis_signal falschen Runden kommt wie bisher das Signal an den Coach.
-- Zuhause: mediathek_kind (freigegebene Videos der offenen Kompetenzen, kompetenz_offen von Auftrag D, späte Bindung),
-- mediathek_angesehen (höchstens „angesehen“), eddie_index (Sprungmarken freigegebener Sequenzen).
-- Die Welt des Kindes steht in studio_kind_welt (Standard Skelett).
-- Alles, was Kinder sehen, kommt aus der eingefrorenen Ausgabe (studio_ausgabe.inhalt: Bereiche, Mini-Checks), nie aus
-- dem Entwurf. Eine Kernidee gilt nur als Video-Kernidee, wenn die Ausgabe zu ihr einen Mini-Check mit mindestens einer
-- auslieferbaren Aufgabe trägt (ready, aktiv, Einsatz check — derselbe Filter wie erklaer_checks); sonst gilt der
-- Kartenweg wie bisher. Freigegebene Dateien darf jeder Angemeldete lesen (Lerninhalt ohne Personenbezug).
--
-- pg_proc-Scan 27.10.2026 (dbread): erklaer_start und erklaer_check_abgeben rufen erklaer_zeigen und
-- erklaer_naechste_kernidee; session_plan_kern ruft erklaer_naechste_kernidee. Keine weiteren Aufrufer; Signaturen
-- bleiben gleich. Kein anderer Auftrag ändert diese Funktionen.
--
-- Rollback: supabase/rollback/20261027141453_studio_ausspielung.sql.

create table public.studio_kind_welt (
  student_id   uuid primary key references public.students (id) on delete cascade,
  welt         text not null check (welt in ('skelett', 'fussball', 'gaming', 'musik')),
  geaendert_am timestamptz not null default now()
);
create table public.studio_angesehen (
  student_id  uuid not null references public.students (id) on delete cascade,
  sequenz_id  uuid not null references public.studio_sequenz (id) on delete cascade,
  erstmals_am timestamptz not null default now(),
  zuletzt_am  timestamptz not null default now(),
  primary key (student_id, sequenz_id)
);
alter table public.studio_kind_welt enable row level security;
alter table public.studio_angesehen enable row level security;
revoke all on public.studio_kind_welt, public.studio_angesehen from public, anon, authenticated;
grant select on public.studio_kind_welt, public.studio_angesehen to authenticated;
create policy studio_kind_welt_lesen on public.studio_kind_welt for select to authenticated
  using (student_id = public.get_my_student_id() or coalesce(public.get_my_role() = 'admin', false));
create policy studio_angesehen_lesen on public.studio_angesehen for select to authenticated
  using (student_id = public.get_my_student_id() or coalesce(public.get_my_role() = 'admin', false));

-- Dateien freigegebener Videos dürfen alle Angemeldeten signieren und lesen (Kinder, Tablets, Eltern-Ansicht).
create function public.studio_datei_freigegeben(p_name text) returns boolean
language sql stable security definer
set search_path = public, pg_temp
as $$
  select exists (select 1 from public.studio_ausgabe a
                  where a.zurueckgezogen_am is null
                    and p_name in (a.inhalt ->> 'mp4', a.inhalt ->> 'untertitel', a.inhalt ->> 'poster'))
$$;
create policy studio_storage_freigegeben_lesen on storage.objects for select to authenticated
  using (bucket_id = 'studio' and public.studio_datei_freigegeben(name));

-- Die Welt des Kindes setzen: das Kind selbst, ein Coach, der das Kind in einer Session hat, Admin.
create function public.studio_welt_setzen(p_kind uuid, p_welt text) returns void
language plpgsql security definer
set search_path = public, pg_temp
as $$
begin
  if not coalesce(public.get_my_student_id() = p_kind or coalesce(public.get_my_role(), '') = 'admin'
                  or exists (select 1 from public.coaching_sessions cs join public.session_students ss on ss.session_id = cs.id
                              where cs.coach_id = auth.uid() and ss.student_id = p_kind), false) then
    raise exception 'studio_welt_setzen: kein Zugriff' using errcode = '42501';
  end if;
  insert into public.studio_kind_welt (student_id, welt) values (p_kind, p_welt)
  on conflict (student_id) do update set welt = excluded.welt, geaendert_am = now();
end;
$$;

-- Aktive Ausgabe einer Kernidee für ein Kind: Welt des Kindes, wenn sie zum aktuellen Skelett freigegeben ist,
-- sonst Skelett. null ohne Video.
create function public.studio_ausgabe_fuer(p_kernidee_id uuid, p_kind uuid) returns public.studio_ausgabe
language sql stable security definer
set search_path = public, pg_temp
as $$
  select a.* from public.studio_ausgabe s
    join public.studio_ausgabe a on a.sequenz_id = s.sequenz_id and a.zurueckgezogen_am is null
   where s.welt = 'skelett' and s.zurueckgezogen_am is null
     and exists (select 1 from jsonb_array_elements(s.inhalt -> 'bereiche') b where b ->> 'kernidee_id' = p_kernidee_id::text)
     and (a.welt = 'skelett' or (a.welt = (select kw.welt from public.studio_kind_welt kw where kw.student_id = p_kind)
                                  and a.version_skelett = s.version_skelett))
   order by a.welt = 'skelett' limit 1
$$;

-- Mini-Check der Kernidee aus der Ausgabe (erster Check im Bereich) und seine Fassungen.
create function public.studio_video_check(p_ausgabe public.studio_ausgabe, p_kernidee_id uuid) returns jsonb
language sql stable
set search_path = public, pg_temp
as $$
  select m from jsonb_array_elements(p_ausgabe.inhalt -> 'minichecks') m
   where m ->> 'kernidee_id' = p_kernidee_id::text limit 1
$$;

-- Auslieferbare Fassungen des Video-Checks (Hauptfrage zuerst), gefiltert wie erklaer_checks.
create function public.studio_video_aufgaben(p_ausgabe public.studio_ausgabe, p_kernidee_id uuid) returns uuid[]
language sql stable security definer
set search_path = public, pg_temp
as $$
  select coalesce(array_agg(t.id order by (a ->> 'nr')::int), '{}')
    from jsonb_array_elements(coalesce(public.studio_video_check(p_ausgabe, p_kernidee_id) -> 'aufgaben', '[]')) a
    join public.tasks t on t.id = (a ->> 'task_id')::uuid
   where coalesce(t.is_active, true) and t.status = 'ready' and 'check' = any (t.einsatz)
$$;

-- Video-Kernidee: freigegebene Ausgabe mit auslieferbarem Mini-Check zu ihr (sonst Kartenweg).
create function public.studio_kernidee_hat_video(p_kernidee_id uuid) returns boolean
language sql stable security definer
set search_path = public, pg_temp
as $$
  select exists (select 1 from public.studio_ausgabe a
                  where a.welt = 'skelett' and a.zurueckgezogen_am is null
                    and cardinality(public.studio_video_aufgaben(a, p_kernidee_id)) > 0)
$$;

-- Videoteil der Antwort: Dateien, Kapitel, Beat-Bereich, Anker und Rücksprung-Ziele des Checks.
create function public.studio_video_json(p_ausgabe public.studio_ausgabe, p_kernidee_id uuid, p_check_task uuid) returns jsonb
language sql stable
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    'sequenz_id', p_ausgabe.sequenz_id, 'welt', p_ausgabe.welt,
    'mp4', p_ausgabe.inhalt ->> 'mp4', 'untertitel', p_ausgabe.inhalt ->> 'untertitel', 'poster', p_ausgabe.inhalt ->> 'poster',
    'kapitel', p_ausgabe.inhalt -> 'kapitel',
    'bereich', (select jsonb_build_object('von', b ->> 'von', 'bis', b ->> 'bis')
                  from jsonb_array_elements(p_ausgabe.inhalt -> 'bereiche') b where b ->> 'kernidee_id' = p_kernidee_id::text),
    'minichecks', coalesce((select jsonb_agg(jsonb_build_object('nach_beat', m ->> 'nach_beat', 'task_id', p_check_task))
                              from (select public.studio_video_check(p_ausgabe, p_kernidee_id) m) x where m is not null), '[]'))
$$;

-- Payload einer Check-Aufgabe mit dem Fragetext in der Welt des Videos (Zahlen gleich, siehe Importprüfung).
create function public.studio_check_payload(p_ausgabe public.studio_ausgabe, p_kernidee_id uuid, p_task uuid) returns jsonb
language sql stable security definer
set search_path = public, pg_temp
as $$
  select case when f.frage is null then p.payload else jsonb_set(p.payload, '{prompt}', to_jsonb(f.frage)) end
    from (select public.lsa_question_payload(p_task) as payload) p
    left join lateral (select a ->> 'frage' as frage
                         from jsonb_array_elements(coalesce(public.studio_video_check(p_ausgabe, p_kernidee_id) -> 'aufgaben', '[]')) a
                        where (a ->> 'task_id')::uuid = p_task) f on true
$$;

-- Kernideen mit Video zählen im E1-Ablauf als freigegeben (auch ohne Karten-Variante).
create or replace function public.erklaer_naechste_kernidee(p_skill_key text, p_nach_nr integer, p_testlauf boolean default false)
returns public.erklaer_kernidee
language sql stable security definer
set search_path = public, pg_temp
as $$
  select k.* from public.erklaer_kernidee k
   where k.skill_key = p_skill_key and k.nr > p_nach_nr
     and ((public.erklaer_status_ok(k.status, p_testlauf)
           and cardinality(public.erklaer_varianten(k.id, p_testlauf)) > 0
           and cardinality(public.erklaer_checks(k.id, p_testlauf)) > 0)
          or public.studio_kernidee_hat_video(k.id))
   order by k.nr limit 1
$$;

create or replace function public.erklaer_zeigen(p_session_id uuid, p_student_id uuid, p_kernidee public.erklaer_kernidee,
  p_variante text, p_runde integer, p_aktion text, p_testlauf boolean default false)
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_checks  uuid[];
  v_check   uuid;
  v_video   public.studio_ausgabe := public.studio_ausgabe_fuer(p_kernidee.id, p_student_id);
  v_aufgabe jsonb;
begin
  if v_video.sequenz_id is not null then
    -- Video: Fassungen des Mini-Checks reihum (Runde 1 Hauptfrage, danach andere Zahlen).
    v_checks := public.studio_video_aufgaben(v_video, p_kernidee.id);
  end if;
  if cardinality(coalesce(v_checks, '{}')) = 0 then
    -- Ohne auslieferbaren Video-Check: Kartenweg wie bisher (auch das Video fällt dann weg).
    v_video := null;
    v_checks := public.erklaer_checks(p_kernidee.id, p_testlauf);
  end if;
  if cardinality(v_checks) = 0 or (p_variante is null and v_video.sequenz_id is null) then
    raise exception 'erklaer: Kernidee % hat keine freigegebene Variante oder Check-Aufgabe', p_kernidee.nr
      using errcode = 'P0002';
  end if;
  v_check := v_checks[((p_runde - 1) % cardinality(v_checks)) + 1];
  insert into public.erklaer_fortschritt
    (session_id, student_id, kernidee_id, runde, variante, check_task_id, ergebnis)
  values (p_session_id, p_student_id, p_kernidee.id, p_runde, p_variante, v_check, 'gezeigt');

  v_aufgabe := case when v_video.sequenz_id is not null then public.studio_check_payload(v_video, p_kernidee.id, v_check)
                    else public.lsa_question_payload(v_check) end;

  return jsonb_build_object(
    'aktion',   p_aktion,
    'kernidee', jsonb_build_object(
                  'nr', p_kernidee.nr, 'titel', p_kernidee.titel,
                  'von', (select count(*) from public.erklaer_kernidee k
                           where k.skill_key = p_kernidee.skill_key
                             and (public.erklaer_status_ok(k.status, p_testlauf) or public.studio_kernidee_hat_video(k.id)))),
    'variante', p_variante,
    'runde',    p_runde,
    'schritte', case when p_variante is null then '[]'::jsonb
                     else public.erklaer_schritte_json(p_kernidee.id, p_variante, p_testlauf) end,
    'check',    jsonb_build_object('task_id', v_check, 'aufgabe', v_aufgabe),
    'video',    case when v_video.sequenz_id is not null then public.studio_video_json(v_video, p_kernidee.id, v_check) end);
end;
$$;

create or replace function public.erklaer_start(p_session_id uuid, p_student_id uuid, p_skill_key text) returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_letzt public.erklaer_fortschritt;
  v_k     public.erklaer_kernidee;
  v_tl    boolean;
  v_video boolean;
begin
  -- A2c: ohne Kind das Kind des Tablets (42501 ohne Platz).
  if p_student_id is null then
    p_student_id := (public.session_tablet_platz(p_session_id, 'erklaer_start')).student_id;
  end if;
  perform public.erklaer_zugang(p_session_id, p_student_id);
  perform public.erklaer_sperren(p_session_id, p_student_id);
  v_tl := coalesce((select cs.testlauf from public.coaching_sessions cs where cs.id = p_session_id), false);

  select f.* into v_letzt from public.erklaer_fortschritt f
    join public.erklaer_kernidee k on k.id = f.kernidee_id
   where f.session_id = p_session_id and f.student_id = p_student_id and k.skill_key = p_skill_key
   order by f.id desc limit 1;

  if v_letzt.id is not null then
    -- Wiederaufnahme: dasselbe Paket, derselbe offene Check, ohne neue Zeile.
    select * into v_k from public.erklaer_kernidee where id = v_letzt.kernidee_id;
    if v_letzt.ergebnis = 'signal' then
      return jsonb_build_object('aktion', 'signal');
    elsif v_letzt.ergebnis = 'richtig' then
      return jsonb_build_object('aktion', 'weiter', 'uebergang', 'ueben');
    end if;
    v_video := v_letzt.check_task_id = any (public.studio_video_aufgaben(public.studio_ausgabe_fuer(v_k.id, p_student_id), v_k.id));
    -- Inzwischen nicht mehr freigegeben (Kernidee, Variante oder Check): nicht ausliefern.
    if not v_video and (not public.erklaer_status_ok(v_k.status, v_tl)
       or not (v_letzt.variante = any (public.erklaer_varianten(v_k.id, v_tl)))
       or not (v_letzt.check_task_id = any (public.erklaer_checks(v_k.id, v_tl)))) then
      -- B6: Ist die Kernidee weiter auslieferbar (z. B. Video zurückgezogen, Karten da), neue Runde statt Stillstand.
      if (public.erklaer_naechste_kernidee(p_skill_key, v_k.nr - 1, v_tl)).id = v_k.id then
        return public.erklaer_zeigen(p_session_id, p_student_id, v_k, (public.erklaer_varianten(v_k.id, v_tl))[1],
                                     v_letzt.runde + 1, 'start', v_tl);
      end if;
      raise exception 'erklaer_start: Erklaerung inzwischen nicht mehr freigegeben' using errcode = 'P0002';
    end if;
    return jsonb_build_object(
      'aktion', 'start',
      'kernidee', jsonb_build_object('nr', v_k.nr, 'titel', v_k.titel,
                    'von', (select count(*) from public.erklaer_kernidee k
                             where k.skill_key = p_skill_key
                               and (public.erklaer_status_ok(k.status, v_tl) or public.studio_kernidee_hat_video(k.id)))),
      'variante', v_letzt.variante, 'runde', v_letzt.runde,
      'schritte', case when v_letzt.variante is null then '[]'::jsonb
                       else public.erklaer_schritte_json(v_k.id, v_letzt.variante, v_tl) end,
      'check', jsonb_build_object('task_id', v_letzt.check_task_id,
                                  'aufgabe', case when v_video then public.studio_check_payload(
                                               public.studio_ausgabe_fuer(v_k.id, p_student_id), v_k.id, v_letzt.check_task_id)
                                             else public.lsa_question_payload(v_letzt.check_task_id) end),
      'video', case when v_video then public.studio_video_json(public.studio_ausgabe_fuer(v_k.id, p_student_id), v_k.id,
                                                               v_letzt.check_task_id) end);
  end if;

  v_k := public.erklaer_naechste_kernidee(p_skill_key, 0, v_tl);
  if v_k.id is null then
    raise exception 'erklaer_start: keine freigegebene Erklaerung fuer %', p_skill_key using errcode = 'P0002';
  end if;
  return public.erklaer_zeigen(p_session_id, p_student_id, v_k,
                               (public.erklaer_varianten(v_k.id, v_tl))[1], 1, 'start', v_tl);
end;
$$;

create or replace function public.erklaer_check_abgeben(p_session_id uuid, p_student_id uuid, p_check_task_id uuid, p_eingabe jsonb)
returns jsonb
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_letzt    public.erklaer_fortschritt;
  v_k        public.erklaer_kernidee;
  v_naechste public.erklaer_kernidee;
  v_urteil   jsonb;
  v_fb       text;
  v_var      text[];
  v_gezeigt  text[];
  v_wahl     text;
  v_tl       boolean;
  v_ausgabe  public.studio_ausgabe;
  v_sprung   jsonb;
  v_antwort  jsonb;
begin
  -- A2c: ohne Kind das Kind des Tablets (42501 ohne Platz).
  if p_student_id is null then
    p_student_id := (public.session_tablet_platz(p_session_id, 'erklaer_check_abgeben')).student_id;
  end if;
  perform public.erklaer_zugang(p_session_id, p_student_id);
  perform public.erklaer_sperren(p_session_id, p_student_id);
  v_tl := coalesce((select cs.testlauf from public.coaching_sessions cs where cs.id = p_session_id), false);

  select * into v_letzt from public.erklaer_fortschritt
   where session_id = p_session_id and student_id = p_student_id
   order by id desc limit 1;
  if v_letzt.id is null or v_letzt.ergebnis <> 'gezeigt'
     or v_letzt.check_task_id is distinct from p_check_task_id then
    raise exception 'erklaer_check_abgeben: nicht der offene Check' using errcode = 'P0001';
  end if;
  select * into v_k from public.erklaer_kernidee where id = v_letzt.kernidee_id;
  v_ausgabe := public.studio_ausgabe_fuer(v_k.id, p_student_id);
  if v_ausgabe.sequenz_id is not null and not (p_check_task_id = any (public.studio_video_aufgaben(v_ausgabe, v_k.id))) then
    v_ausgabe := null;  -- der offene Check gehört nicht (mehr) zum Video: Kartenweg
  end if;
  if v_ausgabe.sequenz_id is null
     and (not public.erklaer_status_ok(v_k.status, v_tl) or not (p_check_task_id = any (public.erklaer_checks(v_k.id, v_tl)))) then
    raise exception 'erklaer_check_abgeben: Check inzwischen nicht mehr freigegeben' using errcode = 'P0002';
  end if;

  v_urteil := public.erklaer_bewerten(p_check_task_id, p_eingabe);
  v_fb := v_urteil ->> 'fehlbild';
  insert into public.erklaer_fortschritt
    (session_id, student_id, kernidee_id, runde, variante, check_task_id, ergebnis, fehlbild_slug)
  values (p_session_id, p_student_id, v_k.id, v_letzt.runde, v_letzt.variante, p_check_task_id,
          case when (v_urteil ->> 'richtig')::boolean then 'richtig' else 'falsch' end, v_fb);
  -- A2: Ereignis fuer raum_signale (Signal nach erklaerrunden_bis_signal falschen Checks je Kernidee).
  perform public.session_ereignis(p_session_id, p_student_id, 'check',
    jsonb_build_object('kernidee', v_k.id, 'ergebnis',
                       case when (v_urteil ->> 'richtig')::boolean then 'richtig' else 'falsch' end,
                       'runde', v_letzt.runde, 'skill_key', v_k.skill_key));

  -- Richtig: naechste Kernidee, sonst Uebergang ins Ueben. Kein Mastery-Signal.
  if (v_urteil ->> 'richtig')::boolean then
    v_naechste := public.erklaer_naechste_kernidee(v_k.skill_key, v_k.nr, v_tl);
    if v_naechste.id is null then
      return jsonb_build_object('aktion', 'weiter', 'uebergang', 'ueben');
    end if;
    return public.erklaer_zeigen(p_session_id, p_student_id, v_naechste,
                                 (public.erklaer_varianten(v_naechste.id, v_tl))[1], 1, 'weiter', v_tl);
  end if;

  -- Falsch: nach erklaerrunden_bis_signal Runden ein Signal an den Coach.
  if (select count(*) from public.erklaer_fortschritt
       where session_id = p_session_id and student_id = p_student_id
         and kernidee_id = v_k.id and ergebnis = 'falsch') >= public.erklaer_runden_bis_signal(p_session_id) then
    insert into public.erklaer_fortschritt
      (session_id, student_id, kernidee_id, runde, variante, check_task_id, ergebnis, fehlbild_slug)
    values (p_session_id, p_student_id, v_k.id, v_letzt.runde, v_letzt.variante, p_check_task_id,
            'signal', v_fb);
    return jsonb_build_object('aktion', 'signal');
  end if;

  -- B6: Video mit Rücksprung zum erkannten Fehlbild → Beat, Rückmeldung, dieselbe Frage mit anderen Zahlen.
  if v_ausgabe.sequenz_id is not null and v_fb is not null then
    v_sprung := public.studio_video_check(v_ausgabe, v_k.id) -> 'ruecksprung' -> v_fb;
    if v_sprung is not null then
      v_antwort := public.erklaer_zeigen(p_session_id, p_student_id, v_k, v_letzt.variante, v_letzt.runde + 1, 'ruecksprung', v_tl);
      return v_antwort || jsonb_build_object('ruecksprung',
        jsonb_build_object('beat', v_sprung ->> 'beat', 'rueckmeldung', v_sprung ->> 'rueckmeldung', 'fehlbild', v_fb));
    end if;
  end if;

  -- Sonst eine andere Variante: passend zum Fehlbild, sonst die naechste ungezeigte.
  v_var := public.erklaer_varianten(v_k.id, v_tl);
  select coalesce(array_agg(distinct variante), '{}') into v_gezeigt
    from public.erklaer_fortschritt
   where session_id = p_session_id and student_id = p_student_id
     and kernidee_id = v_k.id and ergebnis = 'gezeigt';

  select s.variante into v_wahl from public.erklaer_schritt s
   where s.kernidee_id = v_k.id and s.art = 'erklaerung' and public.erklaer_status_ok(s.status, v_tl)
     and s.variante is distinct from v_letzt.variante and v_fb is not null and v_fb = any (s.fehlbild_slugs)
   order by (s.variante = any (v_gezeigt)), s.variante limit 1;
  if v_wahl is null then
    select v into v_wahl from unnest(v_var) v
     where v is distinct from v_letzt.variante
     order by (v = any (v_gezeigt)), (v < v_letzt.variante), v limit 1;
  end if;

  return public.erklaer_zeigen(p_session_id, p_student_id, v_k,
                               coalesce(v_wahl, v_letzt.variante), v_letzt.runde + 1, 'variante', v_tl);
end;
$$;

-- Mediathek zuhause: freigegebene Videos der offenen Kompetenzen (kompetenz_offen von D prüft auch den Zugriff).
create function public.mediathek_kind(p_kind uuid)
returns table (skill_key text, kernidee_key text, sequenz_id uuid, titel text, welt text, mp4_url text, kapitel jsonb,
               untertitel_url text, poster_url text, von_beat text, bis_beat text)
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
begin
  return query
  -- „Offen“ = nicht gesperrt (Anforderung Themenbaum §3; auch „sicher“ ist offen).
  with offen as (select o.skill_key from public.kompetenz_offen(p_kind) o where coalesce(o.zustand, 'gesperrt') <> 'gesperrt'),
  bereiche as (select (b ->> 'kernidee_id')::uuid as kernidee_id, b ->> 'von' as von, b ->> 'bis' as bis
                 from public.studio_ausgabe s cross join lateral jsonb_array_elements(s.inhalt -> 'bereiche') b
                where s.welt = 'skelett' and s.zurueckgezogen_am is null)
  select k.skill_key, k.skill_key || ':k' || k.nr, a.sequenz_id, k.titel, a.welt, a.inhalt ->> 'mp4', a.inhalt -> 'kapitel',
         a.inhalt ->> 'untertitel', a.inhalt ->> 'poster', b.von, b.bis
    from bereiche b
    join public.erklaer_kernidee k on k.id = b.kernidee_id
    join offen o on o.skill_key = k.skill_key
    cross join lateral (select * from public.studio_ausgabe_fuer(b.kernidee_id, p_kind)) a
   where a.sequenz_id is not null
   order by k.skill_key, k.nr;
end;
$$;

-- Zuhause wird höchstens „angesehen“ gespeichert (FernUSG), nur vom Kind selbst.
create function public.mediathek_angesehen(p_kind uuid, p_sequenz uuid) returns void
language plpgsql security definer
set search_path = public, pg_temp
as $$
begin
  if p_kind is null or public.get_my_student_id() is distinct from p_kind then
    raise exception 'mediathek_angesehen: nur das Kind selbst' using errcode = '42501';
  end if;
  if not exists (select 1 from public.studio_ausgabe a where a.sequenz_id = p_sequenz and a.zurueckgezogen_am is null) then
    raise exception 'mediathek_angesehen: Video nicht freigegeben' using errcode = 'P0002';
  end if;
  insert into public.studio_angesehen (student_id, sequenz_id) values (p_kind, p_sequenz)
  on conflict (student_id, sequenz_id) do update set zuletzt_am = now();
end;
$$;

-- Eddie: Sprungmarken freigegebener Sequenzen (nie Entwurf; Zugriff wie die Mediathek).
create function public.eddie_index(p_kind uuid)
returns table (skill_key text, sequenz_id uuid, beat_key text, titel text)
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
begin
  -- Zugriff wie die Mediathek: kompetenz_offen (Auftrag D) wirft 42501 für fremde Kinder. Eddie kennt alle freigegebenen
  -- Sequenzen (Sprungmarken aus der Ausgabe); nach einer Änderung bleibt die freigegebene Fassung, ein nie
  -- freigegebener Entwurf erscheint nie.
  perform 1 from public.kompetenz_offen(p_kind) limit 1;
  return query
  select s.skill_key, a.sequenz_id, k ->> 'beat', k ->> 'titel'
    from public.studio_ausgabe a
    join public.studio_sequenz s on s.id = a.sequenz_id
    cross join lateral jsonb_array_elements(a.inhalt -> 'kapitel') k
   where a.welt = 'skelett' and a.zurueckgezogen_am is null
   order by s.skill_key, a.sequenz_id, (k ->> 'start')::numeric;
end;
$$;

comment on function public.mediathek_kind(uuid) is 'reihe1 fertig';
comment on function public.mediathek_angesehen(uuid, uuid) is 'reihe1 fertig';
comment on function public.eddie_index(uuid) is 'reihe1 fertig';
comment on function public.erklaer_start(uuid, uuid, text) is 'reihe1 fertig';
comment on function public.erklaer_check_abgeben(uuid, uuid, uuid, jsonb) is 'reihe1 fertig';

revoke execute on function public.studio_datei_freigegeben(text), public.studio_welt_setzen(uuid, text),
  public.studio_ausgabe_fuer(uuid, uuid), public.studio_kernidee_hat_video(uuid),
  public.studio_video_check(public.studio_ausgabe, uuid), public.studio_video_json(public.studio_ausgabe, uuid, uuid),
  public.studio_check_payload(public.studio_ausgabe, uuid, uuid), public.studio_video_aufgaben(public.studio_ausgabe, uuid),
  public.mediathek_kind(uuid), public.mediathek_angesehen(uuid, uuid), public.eddie_index(uuid) from public, anon;
revoke execute on function public.studio_ausgabe_fuer(uuid, uuid), public.studio_kernidee_hat_video(uuid),
  public.studio_video_check(public.studio_ausgabe, uuid), public.studio_video_json(public.studio_ausgabe, uuid, uuid),
  public.studio_check_payload(public.studio_ausgabe, uuid, uuid), public.studio_video_aufgaben(public.studio_ausgabe, uuid)
  from authenticated;
grant execute on function public.studio_datei_freigegeben(text), public.studio_welt_setzen(uuid, text),
  public.mediathek_kind(uuid), public.mediathek_angesehen(uuid, uuid), public.eddie_index(uuid) to authenticated;
