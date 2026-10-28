-- Reihe 1 · C2 Phasen und Auswahl, Teil 1: Bausteine (Bauauftrag C2, Konzept Sessionreihe 1 §2.4–2.5 und §9,
-- Konzept Session-Ablauf §1–4). Setzt C1 (20261027130023, 20261027130145) voraus.
--
--   session_schritte: neue Arten recap | generalprobe | gp_ergebnis, Spalten rolle und hinweise_max
--   session_ereignisse: Typ gp_ueben („noch üben“ nach der Generalprobe)
--   Stellschrauben: Warm-up-Mischung, Abruf-Abstand, Transfer, Recap, Generalprobe (Startwerte aus dem Konzept)
--   session_stufe, session_stufe_sicher      Stufe einer Aufgabe bzw. zuletzt sichere Stufe eines Skills
--   session_ziehen, session_zwilling         Auswahl über aufgabe_ziehen / aufgabe_zwilling von Auftrag A (späte
--                                            Bindung); solange A fehlt, für warmup/uebung/recap/beispiel der bisherige
--                                            Pool (session_aufgabe_waehlen), für transfer/generalprobe nichts
--   session_abruf_faellig                    Fälligkeit „letzte Session mit Beleg plus Abstand“ (1 → 2 → 4)
-- Rollback: supabase/rollback/20261027133007_reihe1_c2_bausteine.sql.

alter table public.session_schritte drop constraint session_schritte_art_check;
alter table public.session_schritte add constraint session_schritte_art_check check (art = any (array[
  'erklaerung', 'beispiel', 'aufgabe', 'erklaerung_angebot', 'exit', 'termin', 'fertig', 'warten',
  'recap', 'generalprobe', 'gp_ergebnis']));
alter table public.session_schritte
  add column rolle text check (rolle in ('warmup', 'uebung', 'transfer', 'recap', 'beispiel', 'generalprobe')),
  add column hinweise_max smallint check (hinweise_max between 0 and 3);
comment on column public.session_schritte.rolle is 'Reihe 1 C2: Rolle, mit der die Aufgabe gezogen wurde (Konzept §3.1).';
comment on column public.session_schritte.hinweise_max is
  'Reihe 1 C2: höchste erlaubte Hinweisstufe (0 = kein Hinweis-Knopf); null = Stellschraube hinweisstufen.';

alter table public.session_ereignisse drop constraint session_ereignisse_typ_check;
alter table public.session_ereignisse add constraint session_ereignisse_typ_check check (typ = any (array[
  'phase_wechsel', 'hinweis', 'erklaerschritt', 'check', 'signal', 'signal_erledigt', 'eingriff',
  'entscheidung_pfad', 'pruefung', 'gp_ueben']));

insert into public.session_einstellungen
  (schluessel, beschreibung, typ, wert, startwert, min, max, ganzzahl, werte, einheit)
select k, b, 'zahl', w, w, mi, ma, true, null, e
  from (values
    ('warmup_abruf_max', 'Warm-up: fällige Abrufe höchstens', '2'::jsonb, 0, 4, 'anzahl'),
    ('warmup_voraus_max', 'Warm-up: Voraussetzungen des heutigen Ziels höchstens', '2', 0, 4, 'anzahl'),
    ('abruf_abstand_max', 'Abruf: größter Abstand (1 → 2 → 4 Sessions)', '4', 1, 8, 'sessions'),
    ('transfer_ab_stufe', 'Transfer ab sicherer Stufe', '3', 1, 5, 'stufen'),
    ('transfer_hinweisstufen', 'Hinweisstufen im Transfer', '1', 0, 3, 'stufen'),
    ('recap_aufgaben', 'Recap-Aufgaben', '3', 1, 4, 'anzahl'),
    ('recap_min', 'Recap: Minuten vor dem Check-out', '4', 2, 8, 'minuten'),
    ('gp_skills_max', 'Generalprobe: Kern-Skills höchstens', '8', 1, 10, 'anzahl'),
    ('gp_stufe', 'Generalprobe: Stufe', '3', 1, 5, 'stufen'),
    ('gp_transfer', 'Generalprobe: Transferaufgaben', '2', 0, 3, 'anzahl'),
    ('gp_ueben_aufgaben', 'Generalprobe: Aufgaben je „noch üben“', '3', 1, 5, 'anzahl')
  ) as v(k, b, w, mi, ma, e);

-- Stufe einer Aufgabe: aus der Bauform (aufgabe_meta, Auftrag A), sonst aus Schwierigkeit/AFB.
create function public.session_stufe(p_task_id uuid)
returns int
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v int;
begin
  if p_task_id is null then return null; end if;
  -- Zweitprüfung C2-2: nur Bauform-Instanzen; das Tablet darf alte (LSA-)Aufgaben bei A nicht lesen.
  if to_regprocedure('public.aufgabe_meta(uuid)') is not null
     and (select to_jsonb(t) ->> 'bauform_id' from public.tasks t where t.id = p_task_id) is not null then
    begin
      execute 'select stufe from public.aufgabe_meta($1)' into v using p_task_id;
    exception when insufficient_privilege then v := null;
    end;
  end if;
  return coalesce(v, (select public.session_schwierigkeit(t.difficulty, t.afb) from public.tasks t where t.id = p_task_id));
end;
$$;

-- Zuletzt sichere Stufe: Stufe der jüngsten Aufgabe des Skills, die beim ersten Versuch ohne Hinweis richtig war.
create function public.session_stufe_sicher(p_student_id uuid, p_skill_key text)
returns int
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.session_stufe(a.task_id)
    from public.session_antworten a join public.tasks t on t.id = a.task_id
   where a.student_id = p_student_id and t.skill_key = p_skill_key
     and a.versuch_nr = 1 and a.hinweisstufe_max = 0 and a.ergebnis = 'richtig'
   order by a.zeit desc limit 1
$$;

-- Aufgaben, die das Kind in dieser Session schon hatte, plus jedes je gezeigte Lösungsbeispiel; mit p_alle alles,
-- was das Kind je vor Ort gesehen hat (Generalprobe: nur ungesehene).
create function public.session_ausschluss(p_session_id uuid, p_student_id uuid, p_alle boolean default false)
returns uuid[]
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(array_agg(distinct x.task_id), '{}') from (
    select a.task_id from public.session_ausgegeben a
     where a.student_id = p_student_id and (p_alle or a.session_id = p_session_id)
    union all
    select s.task_id from public.session_schritte s
     where s.student_id = p_student_id and s.task_id is not null
       and (p_alle or s.session_id = p_session_id or s.art = 'beispiel')
  ) x
$$;

-- Eine Aufgabe ziehen: Skill, Rolle, Stufe (dort keine Instanz: darunter, dann darüber). Konzept §9, späte Bindung.
create function public.session_ziehen(p_session_id uuid, p_student_id uuid, p_skill_key text, p_rolle text,
                                      p_stufe int, p_testlauf boolean, p_nur_ungesehen boolean default false,
                                      out task_id uuid, out difficulty int)
returns record
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_aus  uuid[] := public.session_ausschluss(p_session_id, p_student_id, p_nur_ungesehen);
  v_s    int;
  w      record;
begin
  if to_regprocedure('public.aufgabe_ziehen(uuid,text,text,integer,uuid[])') is not null then
    for v_s in
      select x from (select p_stufe as x, 0 as o where p_stufe is not null
                     union all select g, 1 + p_stufe - g from generate_series(1, coalesce(p_stufe, 1) - 1) g
                     union all select g, 10 + g from generate_series(coalesce(p_stufe, 5) + 1, 5) g
                     union all select null::int, 99 where p_stufe is null) s order by o
    loop
      begin
        execute 'select public.aufgabe_ziehen($1, $2, $3, $4, $5)' into task_id
          using p_student_id, p_skill_key, p_rolle, v_s, v_aus;
      exception when insufficient_privilege then
        -- Zweitprüfung C2-3: z. B. Coach-Vorschau ohne Akte; dann nichts ziehen statt abbrechen.
        task_id := null; return;
      end;
      if task_id is not null then
        difficulty := public.session_stufe(task_id);
        return;
      end if;
    end loop;
    return;
  end if;
  -- Ohne Auftrag A: bisheriger Session-Pool, nur für Rollen, die es dort schon gibt.
  if p_rolle in ('warmup', 'uebung', 'recap', 'beispiel') then
    select * into w from public.session_aufgabe_waehlen(p_session_id, p_student_id, p_skill_key, coalesce(p_stufe, 2),
                                                        p_testlauf, p_rolle = 'beispiel');
    if w.task_id is not null and not (w.task_id = any (v_aus)) then
      task_id := w.task_id;
      difficulty := w.difficulty;
    end if;
  end if;
end;
$$;

-- Zwilling nach einer falschen Antwort: andere Instanz derselben Bauform, Rolle und Stufe (aufgabe_zwilling von A).
create function public.session_zwilling(p_session_id uuid, p_student_id uuid, p_task_id uuid, p_rolle text)
returns uuid
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v uuid;
begin
  if to_regprocedure('public.aufgabe_zwilling(uuid,uuid,text)') is null then return null; end if;
  begin
    execute 'select public.aufgabe_zwilling($1, $2, $3)' into v using p_student_id, p_task_id, p_rolle;
  exception when insufficient_privilege then return null;
  end;
  if v = any (public.session_ausschluss(p_session_id, p_student_id)) then return null; end if;
  return v;
end;
$$;

-- Fälligkeit (Konzept §2.4): je Skill mit Beleg der Abstand 1, 2 oder 4 Sessions; fällig in „letzte Session mit
-- Beleg plus Abstand“. Ein richtiger Abruf im Warm-up hebt den Abstand (1 → 2 → 4), ein Fehler setzt ihn auf 1.
-- Sessions = die Sessions vor Ort des Kindes (anwesend, kein Testlauf) in zeitlicher Reihenfolge, dazu diese.
create function public.session_abruf_faellig(p_session_id uuid, p_student_id uuid)
returns table (skill_key text, ueberfaellig int, abstand int, stufe int)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  v_max   int := public.session_wert_zahl(p_session_id, 'abruf_abstand_max')::int;
  v_sess  uuid[];
  v_jetzt int;
  k       record;
  b       record;
  v_ab    int;
  v_letzt int;
begin
  select array_agg(x.id order by x.am, x.id) into v_sess from (
    select cs.id, cs.scheduled_at as am from public.coaching_sessions cs
      join public.session_students ss on ss.session_id = cs.id
     where ss.student_id = p_student_id and ss.attendance = 'present' and not coalesce(cs.testlauf, false)
       and cs.id <> p_session_id and cs.scheduled_at < (select c.scheduled_at from public.coaching_sessions c where c.id = p_session_id)
    union all select p_session_id, (select c.scheduled_at from public.coaching_sessions c where c.id = p_session_id)) x;
  v_jetzt := array_position(v_sess, p_session_id);

  for k in
    select distinct lb.skill_key from public.lernpfad_belege lb
     where lb.student_id = p_student_id and lb.session_id = any (v_sess[1:v_jetzt - 1])
  loop
    v_ab := null;
    for b in
      select array_position(v_sess, lb.session_id) as nr, lb.session_id
        from public.lernpfad_belege lb
       where lb.student_id = p_student_id and lb.skill_key = k.skill_key and lb.session_id = any (v_sess[1:v_jetzt - 1])
       group by lb.session_id order by 1
    loop
      if v_ab is null then
        v_ab := 1;
      elsif exists (select 1 from public.session_antworten a join public.tasks t on t.id = a.task_id
                     where a.session_id = b.session_id and a.student_id = p_student_id and a.phase = 'warmup'
                       and t.skill_key = k.skill_key) then
        v_ab := case when not exists (select 1 from public.session_antworten a join public.tasks t on t.id = a.task_id
                                       where a.session_id = b.session_id and a.student_id = p_student_id
                                         and a.phase = 'warmup' and t.skill_key = k.skill_key
                                         and (a.ergebnis <> 'richtig' or a.versuch_nr <> 1))
                     then least(v_max, v_ab * 2) else 1 end;
      end if;
      v_letzt := b.nr;
    end loop;
    if v_letzt + v_ab <= v_jetzt then
      skill_key := k.skill_key;
      ueberfaellig := v_jetzt - (v_letzt + v_ab);
      abstand := v_ab;
      stufe := greatest(1, coalesce(public.session_stufe_sicher(p_student_id, k.skill_key), 2) - 1);
      return next;
    end if;
  end loop;
end;
$$;

revoke all on function public.session_stufe(uuid), public.session_stufe_sicher(uuid, text),
  public.session_ausschluss(uuid, uuid, boolean), public.session_ziehen(uuid, uuid, text, text, int, boolean, boolean),
  public.session_zwilling(uuid, uuid, uuid, text), public.session_abruf_faellig(uuid, uuid)
  from public, anon, authenticated;
