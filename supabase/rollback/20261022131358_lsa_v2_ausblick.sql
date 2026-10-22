-- Rollback zu 20261022131358_lsa_v2_ausblick: lsa_select_next_core wieder in der Fassung aus
-- 20261022065539_lsa_v_vorschau (kein Ausblick, kein Deckel), lsa_urteil_buchen_core wieder in der Fassung aus
-- 20261021083001_lsa_urteil_eingabeformat („Weiß ich nicht“ und jede falsche erste Probe mit Zweitbeleg), danach
-- lsa_ist_ausblick und lsa_ausblick_knoten entfernen.
--
-- Einspielen wie eine Migration (-v ON_ERROR_STOP=1 -1), danach die Zeile 20261022131358 aus
-- supabase_migrations.schema_migrations loeschen und tools/schema-snapshot.sh.
-- Urteile, die unter LSA-V2 entstanden sind (nicht_angesetzt oder Ausblick-Fehler mit einer Probe, final), bleiben
-- stehen; der Rollback schreibt keine Daten um.

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

CREATE OR REPLACE FUNCTION public.lsa_urteil_buchen_core(p_session_id uuid, p_task_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_task    tasks;
  v_resp    lsa_responses;
  v_sk      text;
  v_is_mc   boolean;
  v_res     text;   -- voll | teilweise | nicht | weiss_nicht | leer
  v_row     lsa_skill_urteil;
  v_prov    text;
  v_a       text;
  v_b       text;
  v_final   text;
  -- AF7, nur fuer den Multi-Part-Zweig
  v_teile   integer;
  v_zeilen  integer;
  v_falsch  integer;
  v_richtig integer;
  v_wn      integer;
begin
  select * into v_task from tasks where id = p_task_id;
  v_sk := v_task.skill_key;
  if v_sk is null then
    return null;  -- Nicht-Fundament-Aufgabe: kein Skill-Urteil.
  end if;

  if v_task.input_type = 'MULTI_PART' then
    -- ── AF7: Urteil aus den Teilzeilen ────────────────────────────────────
    --
    -- Gezaehlt wird ueber ALLE Teile der Aufgabe, nicht ueber die gefundenen
    -- Zeilen: nur so faellt auf, wenn eine Teilzeile fehlt.
    select jsonb_array_length(v_task.parts) into v_teile;

    select count(*),
           count(*) filter (where r.abgabeart = 'antwort' and r.correct is false),
           count(*) filter (where r.abgabeart = 'antwort' and r.correct is true),
           count(*) filter (where r.abgabeart = 'weiss_nicht')
      into v_zeilen, v_falsch, v_richtig, v_wn
      from lsa_responses r
     where r.session_id = p_session_id and r.task_id = p_task_id
       and r.part_nr is not null;

    if v_zeilen = 0 then
      return null;  -- ohne Antwort kein Urteil (wie im flachen Pfad).
    end if;

    -- UNVOLLSTAENDIG ERFASST: weniger Zeilen als Teile.
    -- lsa_submit legt normalerweise JE Teil eine Zeile an, auch fuer leere und
    -- fuer "weiss nicht" — dieser Fall entsteht also nur durch eine Reparatur
    -- von Hand oder einen kuenftigen Submit-Pfad. Dann gibt es KEIN Urteil:
    -- die Verdichtungsregel fragt "sind ALLE Teile richtig", und diese Frage
    -- ist bei unbekanntem Nenner nicht beantwortbar. Lieber kein Beleg als ein
    -- Beleg auf halber Grundlage — dieselbe Haltung wie beim `return null`
    -- oben, wenn gar keine Antwort vorliegt.
    if v_zeilen < v_teile then
      return null;
    end if;

    v_res := case
      -- Ein falscher Teil genuegt. Das ist die Verdichtungsregel, und sie steht
      -- VOR allem anderen: ein belegter Fehler wiegt schwerer als eine
      -- ausgelassene Teilaufgabe daneben.
      when v_falsch > 0 then 'nicht'
      -- Kein Fehler und alle Teile beantwortet -> alle richtig.
      when v_richtig = v_teile then 'voll'
      -- Kein Fehler, aber nicht alle beantwortet: kein Beleg, kein Negativbeleg.
      -- Beide Werte fliessen ohnehin gleich weiter (nicht_angesetzt bzw.
      -- v_b = 'weiss_nicht'); unterschieden wird nur, was naeher an der Wahrheit
      -- ist — hat das Kind "weiss nicht" gedrueckt oder das Feld leer gelassen.
      when v_wn > 0 then 'weiss_nicht'
      else 'leer'
    end;

    -- v_is_mc steuert unten NUR die Abkuerzung in Probe 1: bei MC wird ein
    -- 'voll' nicht sofort final, weil eine einzelne MC-Antwort geraten sein
    -- kann. Genau diese Begruendung traegt bei Multi-Part nur, wenn ALLE Teile
    -- MC sind. Sobald ein Teil eine freie Eingabe ist, ist das Gesamtergebnis
    -- nicht mehr ratbar — ein 'voll' heisst dann, dass das Kind modelliert UND
    -- gerechnet hat, und das ist mindestens so tragfaehig wie ein 'voll' auf
    -- einem flachen NUMERIC-Item.
    select not exists (
             select 1 from jsonb_array_elements(v_task.parts) as e(p)
              where coalesce(p ->> 'kind', '') <> 'mc')
      into v_is_mc;
  else
    -- ── Flacher Pfad, unveraendert ────────────────────────────────────────
    -- Die flache Antwortzeile dieser Aufgabe.
    select * into v_resp
      from lsa_responses
     where session_id = p_session_id and task_id = p_task_id and part_nr is null
     order by created_at desc limit 1;
    if not found then
      return null;  -- ohne Antwort kein Urteil.
    end if;

    v_is_mc := (v_task.input_type = 'MC');

    -- Regel 6: Ergebnis aus abgabeart ableiten.
    if v_resp.abgabeart = 'weiss_nicht' then
      v_res := 'weiss_nicht';
    elsif v_resp.abgabeart = 'leer' then
      v_res := 'leer';
    elsif v_is_mc then
      v_res := case when coalesce(v_resp.correct, false) then 'voll' else 'nicht' end;
    else
      -- NUMERIC/TERM: die dreistufige Bewertung.
      -- L1: mit Eingabeformat (Bruch nach Wert, Term kanonisch), wie correct in lsa_submit.
      select public.lsa_grade(v_task.input_type, s.acceptance, s.correct_answers, v_resp.response,
                              public.lsa_input_hint(v_task.input_type, v_task.bruch, s.correct_answers, v_task.unit))
        into v_res
        from task_solutions s where s.task_id = p_task_id;
      v_res := coalesce(v_res, 'nicht');
    end if;
  end if;

  select * into v_row from lsa_skill_urteil
   where session_id = p_session_id and skill_key = v_sk;

  -- Vorhandenes FINALES Urteil wird nie ueberschrieben.
  if found and not v_row.offen then
    return v_row.zustand;
  end if;

  if not found then
    -- PROBE 1
    if not v_is_mc and v_res = 'voll' then
      insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl)
        values (p_session_id, v_sk, 'traegt', true, false, 1);
      perform public.lsa_mitbelegung(p_session_id, v_sk);
      return 'traegt';
    end if;
    -- Zweitprobe faellig -> provisorisch schreiben. Der provisorische Zustand
    -- kodiert die erste Probe: traegt=mc_ja, traegt_nicht=nicht, nicht_angesetzt=weiss_nicht.
    v_prov := case
      when v_res = 'voll' then 'traegt'                         -- nur MC richtig
      when v_res in ('nicht','teilweise') then 'traegt_nicht'
      else 'nicht_angesetzt' end;                               -- weiss_nicht/leer
    insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl)
      values (p_session_id, v_sk, v_prov, true, true, 1);
    return v_prov;
  else
    -- PROBE 2 (offen=true)
    v_a := case v_row.zustand
             when 'traegt' then 'mc_ja'
             when 'traegt_nicht' then 'nicht'
             else 'weiss_nicht' end;               -- nicht_angesetzt
    v_b := case
             when v_res = 'voll' then 'voll'
             when v_res in ('weiss_nicht','leer') then 'weiss_nicht'
             else 'nicht' end;                     -- nicht/teilweise
    v_final := public.lsa_urteil_aufloesung(v_a, v_b);
    update lsa_skill_urteil
       set zustand = v_final, proben_anzahl = 2, offen = false, aktualisiert = now()
     where session_id = p_session_id and skill_key = v_sk;
    if v_final = 'traegt' then
      perform public.lsa_mitbelegung(p_session_id, v_sk);
    end if;
    return v_final;
  end if;
end;
$function$;


drop function public.lsa_ist_ausblick(uuid, text);
drop function public.lsa_ausblick_knoten(uuid, boolean);
