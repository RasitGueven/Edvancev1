-- Rollback zu 20261025144025_lsa_l2_wiederholung: lsa_select_next_core wieder in der Fassung aus
-- 20261022131358_lsa_v2_ausblick (Vorschau auf zwei Themen, Schritt 5 ohne Text-Schlüssel), lsa_freie_aufgabe wieder
-- in der Fassung aus 20261022065539_lsa_v_vorschau (ohne Text-Schlüssel), danach lsa_ausgegebene_schluessel und
-- lsa_text_schluessel entfernen.
--
-- Einspielen wie eine Migration (-v ON_ERROR_STOP=1 -1), danach die Zeile 20261025144025 aus
-- supabase_migrations.schema_migrations loeschen und tools/schema-snapshot.sh.
-- Der Rollback schreibt keine Daten um (L2 hat keine Daten geschrieben).

create or replace function public.lsa_freie_aufgabe(p_session_id uuid, p_skill_key text, p_pool boolean,
                                                    p_nonmc_zuerst boolean default false)
returns uuid
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  v_id uuid;
begin
  for v_id in
    select t.id
      from tasks t
     where t.skill_key = p_skill_key
       and not exists (select 1 from lsa_ausgegeben a where a.session_id = p_session_id and a.task_id = t.id)
       and not exists (select 1 from lsa_responses r  where r.session_id = p_session_id and r.task_id = t.id)
     order by (case when p_nonmc_zuerst and t.input_type <> 'MC' then 0 else 1 end),
              t.sondierrang nulls last,
              md5(p_session_id::text || t.id::text)
  loop
    if public.lsa_im_pool(v_id, p_pool) then
      return v_id;
    end if;
  end loop;
  return null;
end;
$$;

revoke all on function public.lsa_freie_aufgabe(uuid, text, boolean, boolean) from public, anon, authenticated;

CREATE OR REPLACE FUNCTION public.lsa_select_next_core(p_session_id uuid, p_status_filter text[] DEFAULT ARRAY['ready'::text], p_jetzt timestamp with time zone DEFAULT now())
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  -- Phase Tiefe endet spaetestens so lange nach Sitzungsbeginn. Die Restzeit
  -- bis zum 19-Minuten-Fenster gehoert der Breite: lieber ein Befund fuer
  -- viele Bereiche als eine Ursachensuche, die die ganze Sitzung frisst.
  c_tiefe_bis constant interval := interval '12 minutes';
  -- LSA-V: Die Vorschau (Voraussetzungen der naechsten Schulthemen) laeuft bis
  -- so lange nach Sitzungsbeginn; danach Thema vertiefen und Rueckblick.
  c_vorschau_bis constant interval := interval '16 minutes';
  -- LSA-V: So viele kommende Plan-Themen nimmt die Vorschau.
  c_vorschau_themen constant int := 2;
  -- LSA-V2: Deckel. Nach so vielen ausgegebenen Aufgaben endet die Sitzung, mit und ohne Thema.
  c_max_aufgaben constant int := 40;
  -- LSA-V2: Der Ausblick laeuft nur fuer starke Kinder: mindestens so viele direkt belegte, finale Urteile ...
  c_ausblick_min_urteile constant int := 6;
  -- ... davon mindestens dieser Anteil traegt.
  c_ausblick_anteil constant numeric := 0.75;

  v_sess    lsa_sessions;
  v_pool    boolean;  -- F1 (E2): Testlauf-Pool fuer Testlauf oder Testkonto
  v_open    text;
  v_prefer_nonmc boolean;
  v_desc    text;
  v_leaf    text;
  v_task    uuid;
  v_iter    int := 0;
  v_beginn  timestamptz;
  v_fach    text;
  v_lead    uuid;
  v_schule  uuid;
  v_einstieg   text[];  -- Einstiegsknoten des Sitzungsthemas
  v_themenraum text[];  -- Einstiegsknoten + ihr Abschluss = "unter dem Thema"
  v_mit_thema  boolean; -- Thema mit Einstiegsknoten, die Aufgaben haben
  -- LSA-V
  v_aktuell    int;     -- Position des Kindes im Schulplan (0 = vor dem ersten Eintrag)
  v_kommend    text[];  -- die naechsten Plan-Themen, naechstes zuerst
  v_spaeter    text[];  -- alle Themen, die laut Plan (auch naechste Klasse) bzw. Kernlehrplan noch kommen
  v_rand_sk    text[];  -- Rand der kommenden Themen ...
  v_rand_rang  int[];   -- ... Rang des ersten kommenden Themas, zu dem der Knoten gehoert
  v_rand_n     int[];   -- ... Zahl der kommenden Themen, zu denen er gehoert
  v_tief_sk    text[];  -- Abschluss des Randes (Abstieg in der Vorschau) ...
  v_tief_rang  int[];   -- ... Rang wie beim Randknoten darueber
  v_kand       uuid;    -- LSA-D: Kandidat in Schritt 5
  -- LSA-V2
  v_ausblick   text[];  -- Ausblick-Knoten der Sitzung in Ausblick-Reihenfolge (lsa_ausblick_knoten)
  v_urteile    int;     -- direkt belegte, finale Urteile ...
  v_traegt     int;     -- ... davon traegt
begin
  select * into v_sess from lsa_sessions where id = p_session_id;
  if not found or v_sess.status <> 'in_progress' then
    return null;
  end if;

  -- F1 (E2, Rasit 08.10.2026): Testkonten (students.ist_test) bekommen auch ausserhalb eines Testlaufs den
  -- Testlauf-Pool. lsa_sessions.testlauf bleibt, wie es ist: Eine solche LSA ist kein Testlauf und wird wie
  -- jede echte LSA in Lernpfad und Report uebernommen. Echte Kinder sehen weiter nur 'ready'.
  -- T4: dieselbe Regel ueber lsa_testinhalte (Testlauf oder Testkonto).
  v_pool := public.lsa_testinhalte(p_session_id);

  -- L1: Diagnosezeit ab „Los geht’s“ (platz_los), sonst wie bisher ab lsa_start.
  v_beginn := coalesce(v_sess.diagnose_ab, v_sess.started_at, v_sess.created_at);
  if p_jetzt > v_beginn + interval '19 minutes' then
    return null;
  end if;
  -- LSA-V2 Deckel (docs/lsa/durchklicken-auswertung.md, Abschnitt 6): ausgegebene Aufgaben, nicht Antwortzeilen.
  if (select count(*) from lsa_ausgegeben a where a.session_id = p_session_id) >= c_max_aufgaben then
    return null;
  end if;

  v_fach   := lower(v_sess.subject);
  v_lead   := public.lsa_lead_von_schueler(v_sess.student_id);
  -- LSA-V: Schule wie im Report (R7-9), nicht mehr nur ueber den Lead.
  v_schule := public.lsa_schule_von_sitzung(p_session_id);

  -- Ohne Thema (kein aktuell-Thema, oder keine Einstiegsknoten mit Aufgaben
  -- im Status-Filter) laeuft die bisherige Auswahl: Abstieg unter jedem
  -- gebrochenen Knoten, ohne Zeitgrenze, keine Breite a.
  v_mit_thema := exists (
    select 1 from thema_einstieg te join tasks t on t.skill_key = te.skill_key
     where te.thema_key = v_sess.thema_key and public.lsa_im_pool(t.id, v_pool));

  if v_mit_thema then
    v_einstieg := array(
      select te.skill_key from thema_einstieg te where te.thema_key = v_sess.thema_key);
    v_themenraum := v_einstieg || array(
      select distinct a.skill_key
        from unnest(v_einstieg) e(sk)
        cross join lateral public.lsa_abschluss(e.sk) a);
  else
    v_einstieg   := '{}';
    v_themenraum := '{}';
  end if;

  -- LSA-V2: Ausblick-Knoten, einmal je Aufruf (haengen nur an Thema, Plan und Graph).
  v_ausblick := case when v_mit_thema then public.lsa_ausblick_knoten(p_session_id, true) else '{}' end;

  -- LSA-V: Kommende Themen und der Rand. Haengt nur an Plan und Graph, nicht an
  -- den Urteilen der Sitzung — einmal je Aufruf.
  if v_mit_thema then
    if exists (select 1 from schul_themenplan p
                where p.schule_id = v_schule and lower(p.fach) = v_fach and p.klasse = v_sess.grade) then
      -- Aktuelle Position wie lernweg.ts (aktuellePosition, R7-9 Entscheidung 9):
      -- das Thema der Sitzung; sonst der erste Eintrag des Halbjahrs der Sitzung
      -- (Europe/Berlin, August–Januar 1, Februar–Juli 2); sonst der Anfang.
      v_aktuell := coalesce(
        (select min(p.position) from schul_themenplan p
          where p.schule_id = v_schule and lower(p.fach) = v_fach and p.klasse = v_sess.grade
            and p.thema_key = v_sess.thema_key),
        (select min(p.position) from schul_themenplan p
          where p.schule_id = v_schule and lower(p.fach) = v_fach and p.klasse = v_sess.grade
            and p.halbjahr = case when extract(month from coalesce(v_sess.completed_at, v_sess.started_at,
                                                                   v_sess.created_at) at time zone 'Europe/Berlin')
                                       between 2 and 7 then 2 else 1 end),
        0);
      v_kommend := array(
        select p.thema_key from schul_themenplan p
         where p.schule_id = v_schule and lower(p.fach) = v_fach and p.klasse = v_sess.grade
           and p.position > v_aktuell and p.thema_key is not null
           and p.thema_key is distinct from v_sess.thema_key  -- steht das Thema spaeter noch einmal im Plan
         order by p.position
         limit c_vorschau_themen);
      v_spaeter := array(
        select distinct p.thema_key from schul_themenplan p
         where p.schule_id = v_schule and lower(p.fach) = v_fach and p.thema_key is not null
           and ((p.klasse = v_sess.grade and p.position > v_aktuell) or p.klasse = v_sess.grade + 1));
    else
      -- Ohne Schule oder ohne Plan fuer die Klasse: Kernlehrplan, die Themen der
      -- Klasse nach sort (wie klpPlan in plan.ts: die Stufe der Klasse, ab der
      -- Klasse, sonst die ganze Stufe — themen.klasse steht je Stufe auf dem
      -- ersten Jahr). Nach dem Thema der Sitzung; liegt es nicht darin, von vorn.
      with klp as (
        select th.thema_key, th.sort from themen th
         where lower(th.fach) = v_fach
           and th.stufe = case when v_sess.grade <= 6 then 'erprobung'
                               when v_sess.grade <= 8 then 'erste' else 'zweite' end
      ), k as (
        select * from klp
         where not exists (select 1 from themen th join klp using (thema_key) where th.klasse >= v_sess.grade)
            or thema_key in (select th.thema_key from themen th join klp using (thema_key)
                              where th.klasse >= v_sess.grade)
      )
      select array(select k.thema_key from k
                    where k.sort > coalesce((select k2.sort from k k2 where k2.thema_key = v_sess.thema_key), -1)
                    order by k.sort nulls last, k.thema_key
                    limit c_vorschau_themen),
             array(select th.thema_key from themen th
                    where lower(th.fach) = v_fach
                      and th.sort > coalesce((select k2.sort from k k2 where k2.thema_key = v_sess.thema_key),
                                             (select min(k3.sort) from k k3) - 1))
        into v_kommend, v_spaeter;
    end if;
    v_spaeter := array_remove(v_spaeter, v_sess.thema_key);

    -- Rand je kommendem Thema u: Voraussetzungen von Skills aus u, die nicht zu u
    -- gehoeren. Gehoert eine zu einem Thema, das ebenfalls noch kommt, tritt ihr
    -- eigener Rand an ihre Stelle (rekursiv). Skills kommender Themen werden nie
    -- gezogen.
    with recursive u as (
      select x.thema_key, x.rang::int as rang
        from unnest(v_kommend) with ordinality x(thema_key, rang)
    ), r(rang, sk, pfad) as (
      select u.rang, k.voraussetzt_skill_key, array[k.voraussetzt_skill_key]
        from u
        join skill_thema st on st.thema_key = u.thema_key
        join skill_kante k  on k.skill_key = st.skill_key
       where not exists (select 1 from skill_thema x
                          where x.skill_key = k.voraussetzt_skill_key and x.thema_key = u.thema_key)
      union
      select r.rang, k.voraussetzt_skill_key, r.pfad || k.voraussetzt_skill_key
        from r
        join skill_thema x on x.skill_key = r.sk and x.thema_key = any (v_spaeter)
        join skill_kante k on k.skill_key = r.sk
       where not k.voraussetzt_skill_key = any (r.pfad)
    ), rand as (
      select r.sk, min(r.rang) as rang, count(distinct r.rang)::int as n
        from r
       where not exists (select 1 from skill_thema x
                          where x.skill_key = r.sk
                            and (x.thema_key = any (v_spaeter) or x.thema_key = any (v_kommend)))
       group by r.sk
    )
    select array_agg(sk order by sk), array_agg(rang order by sk), array_agg(n order by sk)
      into v_rand_sk, v_rand_rang, v_rand_n
      from rand;

    select array_agg(t.sk order by t.sk), array_agg(t.rang order by t.sk)
      into v_tief_sk, v_tief_rang
      from (select a.skill_key as sk, min(x.rang) as rang
              from unnest(v_rand_sk, v_rand_rang) x(sk, rang)
              cross join lateral public.lsa_abschluss(x.sk) a
             where not a.skill_key = any (coalesce(v_rand_sk, '{}'))
               and not exists (select 1 from skill_thema st
                                where st.skill_key = a.skill_key
                                  and (st.thema_key = any (v_spaeter) or st.thema_key = any (v_kommend)))
             group by a.skill_key) t;
  end if;

  -- LSA-D Fix A/B (docs/lsa/diagnose-weiter.md, Abschnitte 2 und 7): Jede Phase filtert und sortiert erst nach
  -- Urteil und Ausgabe; lsa_im_pool (im Testpool teuer: pruef_ausschluss, freigabe_gate_fehler) wird zuletzt
  -- und nur bis zum ersten Treffer geprueft — ueber lsa_freie_aufgabe bzw. die Schleife in Schritt 5. Die
  -- Auswahl ist dieselbe: der erste Kandidat der Reihenfolge, der eine freie Aufgabe im Pool hat.
  loop
    v_iter := v_iter + 1;
    if v_iter > 100 then
      return null;
    end if;

    -- Schritt 2: offener Zweitbeleg, immer Vorrang.
    select u.skill_key into v_open
      from lsa_skill_urteil u
     where u.session_id = p_session_id and u.offen = true
     order by u.skill_key
     limit 1;

    if v_open is not null then
      select (zustand = 'traegt') into v_prefer_nonmc
        from lsa_skill_urteil where session_id = p_session_id and skill_key = v_open;

      v_task := public.lsa_freie_aufgabe(p_session_id, v_open, v_pool, coalesce(v_prefer_nonmc, false));

      if v_task is not null then
        return v_task;
      end if;
      update lsa_skill_urteil set offen = false, aktualisiert = now()
        where session_id = p_session_id and skill_key = v_open;
      continue;
    end if;

    -- Phase T: naechster ungepruefter Einstiegsknoten des Themas, groesster
    -- offener Abschluss zuerst. Nur Knoten mit einer noch freien Aufgabe —
    -- ein Thema ohne Aufgaben laesst Phase T einfach aus. KEINE Klassengrenze:
    -- das Thema hat das Erstgespraech gewaehlt.
    v_task := null;
    for v_leaf in
      select s.skill_key
        from skills s
       where s.skill_key = any (v_einstieg)
         and not exists (
               select 1 from lsa_skill_urteil u
                where u.session_id = p_session_id and u.skill_key = s.skill_key)
       order by 1 + (select count(*) from public.lsa_abschluss(s.skill_key) a
                      where not exists (
                        select 1 from lsa_skill_urteil u
                         where u.session_id = p_session_id and u.skill_key = a.skill_key)) desc,
                s.fundament_tiefe desc, s.skill_key
    loop
      v_task := public.lsa_freie_aufgabe(p_session_id, v_leaf, v_pool);
      exit when v_task is not null;
    end loop;
    if v_task is not null then
      return v_task;
    end if;

    -- Phase Tiefe (alter Schritt 3). Mit Thema: nur unter Knoten des
    -- Themenraums, nur bis c_tiefe_bis nach Sitzungsbeginn, ohne Klassengrenze.
    -- Ohne Thema: wie bisher unter jedem gebrochenen Knoten, ohne Zeitgrenze,
    -- mit Klassengrenze.
    v_desc := null;
    if not v_mit_thema or p_jetzt < v_beginn + c_tiefe_bis then
      select x.q into v_desc from (
        select k.voraussetzt_skill_key as q, s.fundament_tiefe as tf
          from lsa_skill_urteil u
          join skill_kante k on k.skill_key = u.skill_key
          join skills s on s.skill_key = k.voraussetzt_skill_key
         where u.session_id = p_session_id
           and u.offen = false
           and u.zustand in ('traegt_nicht','nicht_angesetzt')
           and (not v_mit_thema or u.skill_key = any (v_themenraum))
           and not u.skill_key = any (v_ausblick)  -- LSA-V2: kein Abstieg unter Ausblick-Knoten
           and (v_mit_thema or s.klasse_herkunft <= v_sess.grade)
           and not exists (
                 select 1 from lsa_skill_urteil d
                  where d.session_id = p_session_id and d.skill_key = k.voraussetzt_skill_key)
         order by s.fundament_tiefe desc, k.voraussetzt_skill_key
         limit 1
      ) x;
    end if;

    if v_desc is not null then
      v_task := public.lsa_freie_aufgabe(p_session_id, v_desc, v_pool);
      if v_task is not null then
        return v_task;
      end if;
      insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl)
        values (p_session_id, v_desc, 'ungeprueft', false, false, 0)
        on conflict (session_id, skill_key) do nothing;
      continue;
    end if;

    -- LSA-V Vorschau: der Rand der naechsten Plan-Themen, bis c_vorschau_bis.
    -- Randknoten immer; tiefere Knoten aus ihrem Abschluss nur direkt unter
    -- einem in dieser Sitzung gebrochenen Knoten (eine Stufe je Bruch).
    -- Klassengrenze, kein Urteil in der Sitzung, freie Aufgabe im Pool.
    -- Reihenfolge: Randknoten mehrerer kommender Themen, naechstes Thema
    -- zuerst, Rand vor Tiefe, groesster offener Abschluss, Tiefe, Schluessel.
    -- Ein Kandidat ohne freie Aufgabe wird uebersprungen (Entscheidung 9; das
    -- Urteil 'ungeprueft' brauchte es nur, wenn die Kandidatenwahl die Aufgabe
    -- nicht schon prueft).
    v_task := null;
    if v_mit_thema and p_jetzt < v_beginn + c_vorschau_bis then
      for v_desc in
        select c.sk
          from (select x.sk, x.rang, x.n, true as rand
                  from unnest(v_rand_sk, v_rand_rang, v_rand_n) x(sk, rang, n)
                union all
                select x.sk, x.rang, 1, false
                  from unnest(v_tief_sk, v_tief_rang) x(sk, rang)
                 where exists (
                         select 1 from lsa_skill_urteil u
                           join skill_kante k on k.skill_key = u.skill_key
                          where u.session_id = p_session_id
                            and u.offen = false
                            and u.zustand in ('traegt_nicht','nicht_angesetzt')
                            and k.voraussetzt_skill_key = x.sk
                            and (u.skill_key = any (v_rand_sk) or u.skill_key = any (v_tief_sk)))) c
          join skills s on s.skill_key = c.sk
         where s.klasse_herkunft <= v_sess.grade
           and not exists (
                 select 1 from lsa_skill_urteil u
                  where u.session_id = p_session_id and u.skill_key = c.sk)
         order by case when c.rand and c.n > 1 then 0 else 1 end,
                  c.rang,
                  case when c.rand then 0 else 1 end,
                  1 + (select count(*) from public.lsa_abschluss(c.sk) a
                        where not exists (
                          select 1 from lsa_skill_urteil u
                           where u.session_id = p_session_id and u.skill_key = a.skill_key)) desc,
                  s.fundament_tiefe desc, c.sk
      loop
        v_task := public.lsa_freie_aufgabe(p_session_id, v_desc, v_pool);
        exit when v_task is not null;
      end loop;
    end if;
    if v_task is not null then
      return v_task;
    end if;

    -- LSA-V Thema vertiefen: ungepruefte Knoten des Themenraums, ohne
    -- Zeitgrenze und ohne Klassengrenze (wie Phase T).
    v_task := null;
    if v_mit_thema then
      for v_leaf in
        select s.skill_key
          from skills s
         where s.skill_key = any (v_themenraum)
           and not exists (
                 select 1 from lsa_skill_urteil u
                  where u.session_id = p_session_id and u.skill_key = s.skill_key)
         order by 1 + (select count(*) from public.lsa_abschluss(s.skill_key) a
                        where not exists (
                          select 1 from lsa_skill_urteil u
                           where u.session_id = p_session_id and u.skill_key = a.skill_key)) desc,
                  s.fundament_tiefe desc, s.skill_key
      loop
        v_task := public.lsa_freie_aufgabe(p_session_id, v_leaf, v_pool);
        exit when v_task is not null;
      end loop;
    end if;
    if v_task is not null then
      return v_task;
    end if;

    -- LSA-V2 Ausblick: die Einstiegsknoten der naechsten Plan-Themen, in der
    -- Reihenfolge von lsa_ausblick_knoten. Nur fuer starke Kinder (bei jedem
    -- Aufruf geprueft). Haben die letzten zwei Ausblick-Knoten nicht traegt
    -- ergeben, endet der Ausblick. Die Knoten werden in ihrer Reihenfolge
    -- beurteilt, die letzten zwei Urteile sind also die zwei hoechsten
    -- Stellen (die Uhr der Urteile taugt dafuer nicht: in einer Transaktion
    -- tragen alle dasselbe now()).
    v_task := null;
    if cardinality(v_ausblick) > 0 then
      select count(*), count(*) filter (where u.zustand = 'traegt')
        into v_urteile, v_traegt
        from lsa_skill_urteil u
       where u.session_id = p_session_id and u.belegt_direkt and not u.offen;
      if v_urteile >= c_ausblick_min_urteile and v_traegt >= c_ausblick_anteil * v_urteile
         and not coalesce((select count(*) = 2 and bool_and(y.zustand <> 'traegt')
                             from (select u.zustand
                                     from unnest(v_ausblick) with ordinality x(sk, nr)
                                     join lsa_skill_urteil u on u.session_id = p_session_id and u.skill_key = x.sk
                                    where u.belegt_direkt and not u.offen
                                    order by x.nr desc
                                    limit 2) y), false) then
        for v_leaf in
          select x.sk
            from unnest(v_ausblick) with ordinality x(sk, nr)
           where not exists (
                   select 1 from lsa_skill_urteil u
                    where u.session_id = p_session_id and u.skill_key = x.sk)
           order by x.nr
        loop
          v_task := public.lsa_freie_aufgabe(p_session_id, v_leaf, v_pool);
          exit when v_task is not null;
        end loop;
      end if;
    end if;
    if v_task is not null then
      return v_task;
    end if;

    -- Breite a: Einstiegsknoten der schon behandelten Themen, zuletzt
    -- behandelt zuerst — nach der Stellung im Schulplan der Schule des Leads
    -- (Klasse, dann Position; die Position beginnt je Klasse neu), ohne Plan
    -- nach themen.sort absteigend.
    -- LSA-V: als Rueckblick nach Vorschau und Thema vertiefen; Schule ueber
    -- lsa_schule_von_sitzung.
    v_task := null;
    if v_mit_thema then
      for v_leaf in
        select te.skill_key
          from lead_themen lt
          join themen th         on th.thema_key = lt.thema_key
          join thema_einstieg te on te.thema_key = lt.thema_key
          join skills s          on s.skill_key  = te.skill_key
         where lt.lead_id = v_lead
           and lt.status = 'behandelt'
           and lower(lt.fach) = v_fach
           and s.klasse_herkunft <= v_sess.grade
           and not exists (
                 select 1 from lsa_skill_urteil u
                  where u.session_id = p_session_id and u.skill_key = te.skill_key)
         order by (select max(p.klasse * 1000 + p.position)
                     from schul_themenplan p
                    where p.schule_id = v_schule
                      and p.thema_key = lt.thema_key
                      and lower(p.fach) = v_fach) desc nulls last,
                  th.sort desc nulls last,
                  1 + (select count(*) from public.lsa_abschluss(te.skill_key) a
                        where not exists (
                          select 1 from lsa_skill_urteil u
                           where u.session_id = p_session_id and u.skill_key = a.skill_key)) desc,
                  s.fundament_tiefe desc, te.skill_key
      loop
        v_task := public.lsa_freie_aufgabe(p_session_id, v_leaf, v_pool);
        exit when v_task is not null;
      end loop;
    end if;
    if v_task is not null then
      return v_task;
    end if;

    -- LSA-V: Mit Thema endet die Sitzung hier — keine Breite b, keine
    -- Restzeit-Fuellung. Lieber frueher fertig als ein Bereich ohne Grund.
    if v_mit_thema then
      return null;
    end if;

    -- Breite b (alter Schritt 4): neues Blatt nach gieriger Deckung. Mit Thema
    -- ohne Abstieg (die Tiefe oben greift nur im Themenraum), ohne Thema mit.
    select y.leaf into v_leaf from (
      select b.skill_key as leaf, s.fundament_tiefe as tf,
             1 + (select count(*) from public.lsa_abschluss(b.skill_key) a
                   where not exists (
                     select 1 from lsa_skill_urteil u
                      where u.session_id = p_session_id and u.skill_key = a.skill_key)) as neu
        from skills b join skills s on s.skill_key = b.skill_key
       where not exists (select 1 from skill_kante k where k.voraussetzt_skill_key = b.skill_key)
         and b.klasse_herkunft <= v_sess.grade
         and not exists (
               select 1 from lsa_skill_urteil u
                where u.session_id = p_session_id and u.skill_key = b.skill_key)
       order by neu desc, s.fundament_tiefe desc, b.skill_key
       limit 1
    ) y;

    if v_leaf is not null then
      v_task := public.lsa_freie_aufgabe(p_session_id, v_leaf, v_pool);
      if v_task is not null then
        return v_task;
      end if;
      insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl)
        values (p_session_id, v_leaf, 'ungeprueft', false, false, 0)
        on conflict (session_id, skill_key) do nothing;
      continue;
    end if;

    -- Schritt 5: Restzeit. Erst nach Klasse, Ausgabe und Urteil sortieren,
    -- dann lsa_im_pool bis zum ersten Treffer (LSA-D: hier lagen alle
    -- langsamen Aufrufe, der Pool-Test lief vor dem Ausschluss ueber die Urteile).
    for v_kand in
      select t.id
        from tasks t
        join skills s on s.skill_key = t.skill_key
       where s.klasse_herkunft <= v_sess.grade
         and not exists (select 1 from lsa_ausgegeben a where a.session_id = p_session_id and a.task_id = t.id)
         and not exists (select 1 from lsa_responses r  where r.session_id = p_session_id and r.task_id = t.id)
         and not exists (
               select 1 from lsa_skill_urteil u
                where u.session_id = p_session_id and u.skill_key = t.skill_key)
       order by t.sondierrang nulls last, md5(p_session_id::text || t.id::text)
    loop
      if public.lsa_im_pool(v_kand, v_pool) then
        return v_kand;
      end if;
    end loop;

    return null;
  end loop;
end;
$function$;

drop function public.lsa_ausgegebene_schluessel(uuid);
drop function public.lsa_text_schluessel(text, jsonb);
