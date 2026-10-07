-- A2.2 Session-Engine: Bausteine der Auswahl (Entscheidungen A2 E bis J).
--
-- Alle Funktionen sind intern (kein EXECUTE fuer authenticated) und lesen nur.
--   session_aufgabe_stand   erledigt (alle Teile beantwortet), erfolg (beim ersten Versuch
--                           richtig ohne Hinweis), richtig.
--   session_niveau          Steuerung auf ziel_erfolgsquote (H): Startniveau aus der zuletzt
--                           richtig geloesten Aufgabe (fruehere Session oder LSA), sonst 2;
--                           danach je fuenf erledigte Aufgaben des Skills in dieser Session +1/-1.
--   session_modus           gefuehrt, bis eine Aufgabe des Skills ohne Hinweis geloest ist (G).
--   session_aufgabe_waehlen Pool (J), nie zweimal in einer Session, nie ein gezeigtes Beispiel;
--                           naechste Schwierigkeit zuerst, dann ungesehen vor gesehen, dann die
--                           am laengsten nicht gesehene.
--   session_sichere_skills  sichere Skills (Lernpfad), in der ersten Session die LSA-Urteile (E).
--   session_erklaer_stand   Stand der Erklaersequenz eines Skills in dieser Session (F).

-- Schwierigkeit einer Aufgabe fuer die Auswahl (Rasit 06.10., Annahme fuer Fatih): tasks.difficulty,
-- ohne Wert aus dem Anforderungsbereich (AFB I -> 2, II -> 3, III -> 4), sonst 2. Die Daten bleiben
-- unveraendert (dbread 06.10.: difficulty bei 0 von 1.183 gefuellt, afb bei 1.018).
create function public.session_schwierigkeit(p_difficulty int, p_afb text)
returns int
language sql
immutable
set search_path = public, pg_temp
as $$
  select coalesce(p_difficulty, case p_afb when 'I' then 2 when 'II' then 3 when 'III' then 4 else 2 end)
$$;

create function public.session_aufgabe_stand(p_session_id uuid, p_student_id uuid, p_task_id uuid,
  out erledigt boolean, out erfolg boolean, out richtig boolean, out zeit timestamptz)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with t as (
    select case when t.input_type = 'MULTI_PART' then greatest(jsonb_array_length(t.parts), 1) else 1 end as teile
      from public.tasks t where t.id = p_task_id
  ),
  je_teil as (
    select coalesce(a.teil, 0) as teil,
           bool_or(a.ergebnis = 'richtig') as r,
           bool_and(a.versuch_nr <> 1 or (a.ergebnis = 'richtig' and a.hinweisstufe_max = 0)) as e,
           max(a.zeit) as z
      from public.session_antworten a
     where a.session_id = p_session_id and a.student_id = p_student_id and a.task_id = p_task_id
     group by 1
  )
  select count(j.teil) >= t.teile,
         count(j.teil) >= t.teile and coalesce(bool_and(j.e), false),
         count(j.teil) >= t.teile and coalesce(bool_and(j.r), false),
         max(j.z)
    from t left join je_teil j on true
   group by t.teile
$$;

create function public.session_niveau(p_session_id uuid, p_student_id uuid, p_skill_key text,
  out niveau int, out start int, out aenderung int, out quote text, out haengt_bei timestamptz)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_ziel numeric := public.session_wert_zahl(p_session_id, 'ziel_erfolgsquote');
  v_buf  boolean[] := '{}';
  v_n    int := 0;
  v_q    numeric;
  r      record;
begin
  select x.difficulty into start from (
    select public.session_schwierigkeit(t.difficulty, t.afb) as difficulty, a.zeit
      from public.session_antworten a join public.tasks t on t.id = a.task_id
     where a.student_id = p_student_id and a.session_id <> p_session_id and t.skill_key = p_skill_key
       and a.ergebnis = 'richtig'
    union all
    select public.session_schwierigkeit(t.difficulty, t.afb), lr.created_at
      from public.lsa_responses lr
      join public.lsa_sessions ls on ls.id = lr.session_id
      join public.tasks t on t.id = lr.task_id
     where (ls.student_id = p_student_id or ls.uebernommen_zu_student_id = p_student_id)
       and not ls.testlauf and lr.correct and t.skill_key = p_skill_key
  ) x order by x.zeit desc limit 1;
  start := coalesce(start, 2);
  niveau := start;
  aenderung := 0;

  -- Fenster der letzten fuenf erledigten Aufgaben seit der letzten Auswertung (Annahme H).
  for r in
    select st.erfolg, st.zeit
      from public.session_ausgegeben a
      join public.tasks t on t.id = a.task_id
      cross join lateral public.session_aufgabe_stand(p_session_id, p_student_id, a.task_id) st
     where a.session_id = p_session_id and a.student_id = p_student_id and t.skill_key = p_skill_key
       and st.erledigt
     order by st.zeit
  loop
    v_buf := v_buf || r.erfolg;
    v_n := v_n + 1;
    aenderung := 0;
    quote := null;
    if v_n >= 5 then
      v_q := (select count(*) filter (where x) from unnest(v_buf[cardinality(v_buf) - 4:]) x)::numeric / 5;
      quote := (v_q * 5)::int || ' von 5';
      if v_q > v_ziel + 0.1 then
        if niveau < 5 then niveau := niveau + 1; aenderung := 1; end if;
        v_n := 0;
      elsif v_q < v_ziel - 0.1 then
        if niveau > 1 then niveau := niveau - 1; aenderung := -1;
        else haengt_bei := r.zeit; aenderung := -2;
        end if;
        v_n := 0;
      end if;
    end if;
  end loop;
end;
$$;

create function public.session_modus(p_student_id uuid, p_skill_key text)
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case when exists (
    select 1 from public.session_antworten a join public.tasks t on t.id = a.task_id
     where a.student_id = p_student_id and t.skill_key = p_skill_key
       and a.ergebnis = 'richtig' and a.hinweisstufe_max = 0)
  then 'selbststaendig' else 'gefuehrt' end
$$;

-- p_schwierigkeit: gewuenschte Stufe; verglichen wird mit session_schwierigkeit (difficulty, sonst AFB).
create function public.session_aufgabe_waehlen(p_session_id uuid, p_student_id uuid, p_skill_key text,
  p_schwierigkeit int, p_testlauf boolean, p_mit_loesungsweg boolean default false,
  out task_id uuid, out difficulty int)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with benutzt as (
    select a.task_id from public.session_ausgegeben a
     where a.session_id = p_session_id and a.student_id = p_student_id
    union
    select s.task_id from public.session_schritte s
     where s.student_id = p_student_id and s.task_id is not null
       and (s.session_id = p_session_id or s.art = 'beispiel')
  ),
  gesehen as (
    select x.task_id, max(x.zeit) as zuletzt from (
      select a.task_id, a.zeit from public.session_ausgegeben a where a.student_id = p_student_id
      union all
      select s.task_id, s.zeit from public.session_schritte s where s.student_id = p_student_id and s.task_id is not null
    ) x group by x.task_id
  )
  select t.id, public.session_schwierigkeit(t.difficulty, t.afb)
    from public.tasks t
    left join gesehen g on g.task_id = t.id
   where t.skill_key = p_skill_key
     and t.id not in (select b.task_id from benutzt b)
     and public.session_im_pool(t.id, p_testlauf)
     and (not p_mit_loesungsweg
          or exists (select 1 from public.task_solutions ts where ts.task_id = t.id
                      and nullif(btrim(ts.solution), '') is not null))
   order by abs(public.session_schwierigkeit(t.difficulty, t.afb) - p_schwierigkeit),
            (g.zuletzt is not null), g.zuletzt, t.id
   limit 1
$$;

create function public.session_sichere_skills(p_student_id uuid)
returns table (skill_key text, zuletzt timestamptz, quelle text)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with lp as (
    select l.skill_key, l.letzte_uebung_am from public.lernpfad l
     where l.student_id = p_student_id
       and (l.stand_system in ('sicher', 'kandidat') or l.stand_coach = 'gemeistert')
  )
  select lp.skill_key, lp.letzte_uebung_am, 'lernpfad' from lp
  union all
  select u.skill_key, null::timestamptz, 'lsa' from public.lernpfad_lsa_urteile(p_student_id) u
   where u.zustand = 'traegt' and not exists (select 1 from lp)
$$;

-- Erklaerinhalt sichtbar? freigegeben; im Testlauf auch entwurf und geprueft (Rasit 06.10., wie Aufgaben).
create function public.erklaer_status_ok(p_status text, p_testlauf boolean default false)
returns boolean
language sql
immutable
set search_path = public, pg_temp
as $$ select p_status = 'freigegeben' or (coalesce(p_testlauf, false) and p_status in ('entwurf', 'geprueft')) $$;

-- Stand der Erklaersequenz: null (nicht begonnen), laeuft (offener Check), fertig, signal
-- (Coach-Signal offen) oder signal_erledigt (Coach hat das haengt-Signal erledigt).
create function public.session_erklaer_stand(p_session_id uuid, p_student_id uuid, p_skill_key text,
  out stand text, out kernidee_nr int, out kernideen int, out runde int, out variante text,
  out fehlbild_slug text, out zeit timestamptz)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case f.ergebnis
           when 'richtig' then 'fertig'
           when 'signal' then case when exists (
               select 1 from public.session_ereignisse e
                where e.session_id = p_session_id and e.student_id = p_student_id and e.typ = 'signal_erledigt'
                  and e.payload ->> 'art' = 'haengt' and e.zeit > f.zeit) then 'signal_erledigt' else 'signal' end
           else 'laeuft' end,
         k.nr,
         (select count(*)::int from public.erklaer_kernidee k2 where k2.skill_key = p_skill_key
           and public.erklaer_status_ok(k2.status, (select cs.testlauf from public.coaching_sessions cs where cs.id = p_session_id))),
         f.runde, f.variante,
         (select f2.fehlbild_slug from public.erklaer_fortschritt f2 where f2.session_id = p_session_id
           and f2.student_id = p_student_id and f2.kernidee_id = f.kernidee_id and f2.ergebnis = 'falsch'
           order by f2.id desc limit 1),
         f.zeit
    from public.erklaer_fortschritt f
    join public.erklaer_kernidee k on k.id = f.kernidee_id
   where f.session_id = p_session_id and f.student_id = p_student_id and k.skill_key = p_skill_key
   order by f.id desc
   limit 1
$$;

-- Kandidaten fuers Mischen (I): sichere Skills ausser dem aktuellen, Voraussetzungen des Ziels
-- zuerst, dann am laengsten nicht dran (Lernpfad oder heute). Klassenarbeit: nur ihr Thema.
create function public.session_misch_kandidaten(p_session_id uuid, p_student_id uuid, p_skill_key text,
                                                p_ziel_skills text[], p_ka_thema text)
returns table (skill_key text, voraussetzung boolean, zuletzt timestamptz)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with voraus as (
    select distinct a.skill_key from unnest(p_ziel_skills) z(sk) cross join lateral public.lsa_abschluss(z.sk) a
  )
  select s.skill_key, s.skill_key in (select v.skill_key from voraus v),
         greatest(s.zuletzt, (select max(a.zeit) from public.session_antworten a join public.tasks t on t.id = a.task_id
                               where a.session_id = p_session_id and a.student_id = p_student_id
                                 and t.skill_key = s.skill_key)) as zuletzt
    from public.session_sichere_skills(p_student_id) s
   where s.skill_key <> p_skill_key
     and (p_ka_thema is null
          or s.skill_key in (select st.skill_key from public.skill_thema st where st.thema_key = p_ka_thema
                             union select te.skill_key from public.thema_einstieg te where te.thema_key = p_ka_thema))
   order by 2 desc, 3 nulls first, 1
$$;

-- Mastery-Kandidaten als Signal (M): je Kind und Skill einmal je Session, hoechstens
-- mastery_kandidaten_je_raum Signale je Raum und Session.
create function public.session_kandidat_signale(p_session_id uuid, p_student_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(jsonb_agg(jsonb_build_object('art', 'kandidat', 'skill_key', v.skill_key, 'label', v.label,
                                               'grund', 'Mastery-Prüfung möglich: ' || v.label,
                                               'grund_code', 'mastery_kandidat')), '[]')
    from (
      select m.skill_key, m.label
        from public.mastery_vorschlaege_core(p_student_id) m
       where not exists (select 1 from public.session_ereignisse e
                          where e.session_id = p_session_id and e.student_id = p_student_id and e.typ = 'signal'
                            and e.payload ->> 'art' = 'kandidat' and e.payload ->> 'skill_key' = m.skill_key)
       limit greatest(0, public.session_wert_zahl(p_session_id, 'mastery_kandidaten_je_raum')::int
                         - (select count(*) from public.session_ereignisse e
                             where e.session_id = p_session_id and e.typ = 'signal' and e.payload ->> 'art' = 'kandidat'))
    ) v
$$;

revoke all on function
  public.session_schwierigkeit(int, text), public.erklaer_status_ok(text, boolean), public.session_aufgabe_stand(uuid, uuid, uuid), public.session_niveau(uuid, uuid, text),
  public.session_modus(uuid, text), public.session_aufgabe_waehlen(uuid, uuid, text, int, boolean, boolean),
  public.session_sichere_skills(uuid), public.session_erklaer_stand(uuid, uuid, text),
  public.session_misch_kandidaten(uuid, uuid, text, text[], text), public.session_kandidat_signale(uuid, uuid)
  from public, anon, authenticated;
