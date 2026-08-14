-- PRUEFUNG zu AF4 (Fehlbild-Familien + Buendelung im Eltern-Pfad).
--
--   psql "postgresql:///edvance_neuaufbau" -v ON_ERROR_STOP=1 \
--        -f supabase/checks/fehlbild_familien.PRUEFUNG.sql
--
-- Dritte Datei neben fehlbild_auswertung.PRUEFUNG.sql (dort: wird richtig
-- gezaehlt und eingestuft) und fehlbild_klartext_abnahme.PRUEFUNG.sql (dort:
-- welcher COACH-Text die Datenbank verlaesst). Hier steht, welcher ELTERN-Text
-- sie verlaesst und ob die Buendelung traegt. Getrennt, weil die drei
-- unabhaengig brechen koennen — und weil ein durchgerutschter Elternsatz die
-- teuerste der drei Pannen ist.
--
-- Laeuft gegen eine bereits migrierte Datenbank (tools/neuaufbau-test.sh baut
-- sie) und faengt sich SELBST in begin/rollback.

begin;

do $$
declare
  v_coach   uuid := gen_random_uuid();
  v_student uuid := gen_random_uuid();
  v_sess    uuid := gen_random_uuid();
  v_t       uuid[];
  v_txt     text;
  v_fam     text;
  v_n       bigint;
  v_i       integer;
  v_ctrl    boolean;
begin
  -- ══ Testdaten ═════════════════════════════════════════════════════════════

  insert into auth.users (id, email) values (v_coach, 'af4-coach@edvance.test');
  insert into public.profiles (id, email, role)
    values (v_coach, 'af4-coach@edvance.test', 'coach');
  perform set_config('request.jwt.claim.sub', v_coach::text, true);

  insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
  values ('AF4_PROBE', 'AF4 Probe', 'mathematik', 8, 1);

  insert into public.students (id, class_level) values (v_student, 8);
  insert into public.lsa_sessions (id, student_id, subject, grade)
  values (v_sess, v_student, 'mathematik', 8);

  select array_agg(id order by nr) into v_t
    from (select gen_random_uuid() as id, nr from generate_series(1, 6) as nr) x;

  insert into public.tasks (id, content_type, skill_key, question)
  select v_t[i], 'exercise', 'AF4_PROBE', 'AF4 Probe ' || i
    from generate_series(1, 6) as i;

  -- Zwei Familien mit IDENTISCH aufgebautem Elterntext, nur die Abnahme trennt
  -- sie. Genau eine Variable — sonst belegt ein gruener Lauf nicht, dass es die
  -- Abnahme war und nicht der Text.
  insert into public.fehlbild_familien (schluessel, elterntext, freigegeben_am, freigegeben_von)
  values ('af4_fam_frei',    'abgenommener Elternsatz', now(), v_coach),
         ('af4_fam_entwurf', 'ENTWURF-Elternsatz',      null,  null);

  -- Vier Slugs: zwei in derselben freigegebenen Familie (das ist der
  -- Buendelfall), einer in der Entwurfsfamilie, einer ganz ohne Familie.
  --
  -- Alle vier Labels sind SELBST freigegeben (AF3-Schranke auf
  -- fehlbild_labels.freigegeben_am). Das ist Absicht und der Kern des Aufbaus:
  -- die zwei Schranken sind unabhaengig. Der Coach-Satz haengt an der Freigabe
  -- des LABELS, der Elternsatz an der Freigabe der FAMILIE. Waeren die Labels
  -- hier unabgenommen, wuerde Fall 8 die Coach-Sicht pruefen und immer null
  -- bekommen — und zwar aus dem falschen Grund.
  insert into public.fehlbild_labels (slug, klartext, familie, freigegeben_am, freigegeben_von)
  values ('af4_a',    'Coach-Satz A',            'af4_fam_frei',    now(), v_coach),
         ('af4_b',    'Coach-Satz B',            'af4_fam_frei',    now(), v_coach),
         ('af4_c',    'Coach-Satz C',            'af4_fam_entwurf', now(), v_coach),
         ('af4_ohne', 'Coach-Satz ohne Familie', null,              now(), v_coach);

  -- Je zwei Vorkommen in zwei Aufgaben -> alle werden 'befund'. Die Einstufung
  -- ist damit fuer alle gleich; unterschiedlich ist nur die Familie.
  insert into public.lsa_responses
    (session_id, task_id, part_nr, abgabeart, correct, response, fehlbild_slug)
  values
    (v_sess, v_t[1], 1, 'antwort', false, '{"text":"x"}'::jsonb, 'af4_a'),
    (v_sess, v_t[2], 1, 'antwort', false, '{"text":"x"}'::jsonb, 'af4_a'),
    (v_sess, v_t[3], 1, 'antwort', false, '{"text":"x"}'::jsonb, 'af4_b'),
    (v_sess, v_t[4], 1, 'antwort', false, '{"text":"x"}'::jsonb, 'af4_b'),
    (v_sess, v_t[5], 1, 'antwort', false, '{"text":"x"}'::jsonb, 'af4_c'),
    (v_sess, v_t[6], 1, 'antwort', false, '{"text":"x"}'::jsonb, 'af4_c'),
    (v_sess, v_t[1], 2, 'antwort', false, '{"text":"x"}'::jsonb, 'af4_ohne'),
    (v_sess, v_t[2], 2, 'antwort', false, '{"text":"x"}'::jsonb, 'af4_ohne');

  -- ══ Fall 1: abgenommener Elterntext wird ausgeliefert ═════════════════════

  select a.familie, a.familie_elterntext into v_fam, v_txt
    from public.lsa_fehlbild_auswertung(v_sess) a where a.fehlbild_slug = 'af4_a';
  if v_fam is distinct from 'af4_fam_frei' then
    raise exception 'F1: familie=%, erwartet af4_fam_frei', coalesce(v_fam, '<null>');
  end if;
  if v_txt is distinct from 'abgenommener Elternsatz' then
    raise exception 'F1: Elterntext fehlt (bekam %)', coalesce(v_txt, '<null>');
  end if;
  raise notice 'F1 ok: Familie und abgenommener Elterntext werden ausgeliefert';

  -- ══ Fall 2: unabgenommener Elterntext kommt NICHT heraus ══════════════════
  --
  -- DER KERN VON AF4. Die Zeile muss erscheinen und die FAMILIE muss kommen
  -- (sonst kann der Report nicht buendeln), nur der TEXT fehlt.

  select a.familie, a.familie_elterntext, a.anzahl into v_fam, v_txt, v_n
    from public.lsa_fehlbild_auswertung(v_sess) a where a.fehlbild_slug = 'af4_c';
  if v_n is distinct from 2 then
    raise exception 'F2: Entwurfs-Zeile fehlt oder zaehlt falsch (anzahl=%)',
      coalesce(v_n::text, '<keine Zeile>');
  end if;
  if v_fam is distinct from 'af4_fam_entwurf' then
    raise exception 'F2: familie=%, erwartet af4_fam_entwurf — die Buendelung '
                    'darf nicht an der Textabnahme haengen', coalesce(v_fam, '<null>');
  end if;
  if v_txt is not null then
    raise exception 'F2: unabgenommener Elterntext ausgeliefert: %', v_txt;
  end if;
  -- Und die Gegenprobe, die belegt dass die zwei Schranken unabhaengig sind:
  -- af4_c hat einen FREIGEGEBENEN Coach-Satz in einer NICHT freigegebenen
  -- Familie. Der Coach sieht seinen Satz, die Eltern sehen keinen. Haengt eine
  -- Schranke versehentlich an der anderen, kippt genau diese Zeile.
  select r.klartext into v_txt
    from public.lsa_fehlbild_report(v_sess) r where r.fehlbild_slug = 'af4_c';
  if v_txt is distinct from 'Coach-Satz C' then
    raise exception 'F2: Coach-Satz fehlt, obwohl das Label freigegeben ist (bekam %) '
                    '— die Familien-Schranke greift in die Label-Schranke',
      coalesce(v_txt, '<null>');
  end if;
  raise notice 'F2 ok: Familie kommt, Elterntext bleibt hinter der Schranke, Coach-Satz laeuft';

  -- ══ Fall 3: Abnahme wirkt sofort ══════════════════════════════════════════
  --
  -- Belegt, dass die Schranke an freigegeben_am haengt und nicht an etwas
  -- anderem, das zufaellig mitlaeuft (etwa dem Alter der Zeile).

  update public.fehlbild_familien
     set freigegeben_am = now(), freigegeben_von = v_coach
   where schluessel = 'af4_fam_entwurf';

  select a.familie_elterntext into v_txt
    from public.lsa_fehlbild_auswertung(v_sess) a where a.fehlbild_slug = 'af4_c';
  if v_txt is distinct from 'ENTWURF-Elternsatz' then
    raise exception 'F3: nach Abnahme kommt der Text nicht durch (bekam %)',
      coalesce(v_txt, '<null>');
  end if;
  raise notice 'F3 ok: Abnahme schaltet den Elterntext frei';

  -- ══ Fall 4: Ruecknahme sperrt wieder ══════════════════════════════════════

  update public.fehlbild_familien
     set freigegeben_am = null, freigegeben_von = null
   where schluessel = 'af4_fam_entwurf';

  select a.familie_elterntext into v_txt
    from public.lsa_fehlbild_auswertung(v_sess) a where a.fehlbild_slug = 'af4_c';
  if v_txt is not null then
    raise exception 'F4: nach Ruecknahme wird weiter ausgeliefert: %', v_txt;
  end if;
  raise notice 'F4 ok: Ruecknahme sperrt den Elterntext wieder';

  -- ══ Fall 5: die Buendelung traegt ═════════════════════════════════════════
  --
  -- Zwei verschiedene Slugs, eine Familie, EIN Elterntext. Das ist der Zweck
  -- der Ebene: der Report macht daraus eine Karte mit 4 Belegen, nicht zwei
  -- Karten mit je 2.

  select count(distinct a.familie_elterntext), sum(a.anzahl)
    into v_i, v_n
    from public.lsa_fehlbild_auswertung(v_sess) a
   where a.familie = 'af4_fam_frei';
  if v_i <> 1 then
    raise exception 'F5: % verschiedene Elterntexte in einer Familie, erwartet 1', v_i;
  end if;
  if v_n <> 4 then
    raise exception 'F5: Summe der Belege %, erwartet 4 (2 Slugs x 2)', v_n;
  end if;
  -- Und die Buendelung deckt sich mit der Einstufung: beide Zeilen sind
  -- 'befund'. Waere eine davon 'beobachtung', wuerde lsaReport.loadFehlbilder
  -- sie wegfiltern und der Buendelsatz stuende auf halber Belegzahl.
  if exists (
    select 1 from public.lsa_fehlbild_auswertung(v_sess) a
     where a.familie = 'af4_fam_frei' and a.einstufung <> 'befund'
  ) then
    raise exception 'F5: eine Zeile der Familie ist keine befund-Zeile';
  end if;
  raise notice 'F5 ok: zwei Slugs derselben Familie tragen EINEN Elterntext (4 Belege)';

  -- ══ Fall 6: Slug ohne Familie behaelt seine Zeile ═════════════════════════
  --
  -- NEGATIVKONTROLLE zum zweiten LEFT JOIN. 53 der 73 Registry-Slugs haben
  -- keine Familie. Wird der Join zum INNER JOIN vereinfacht, verschwinden sie
  -- alle aus dem Report und dieser Fall bricht ab.

  select count(*) into v_n from public.lsa_fehlbild_auswertung(v_sess) a
   where a.fehlbild_slug = 'af4_ohne';
  if v_n <> 1 then
    raise exception 'F6: Zeile ohne Familie fehlt (INNER JOIN?)';
  end if;
  select a.familie, a.familie_elterntext into v_fam, v_txt
    from public.lsa_fehlbild_auswertung(v_sess) a where a.fehlbild_slug = 'af4_ohne';
  if v_fam is not null or v_txt is not null then
    raise exception 'F6: familie=%, elterntext=% — beide erwartet null',
      coalesce(v_fam, '<null>'), coalesce(v_txt, '<null>');
  end if;
  raise notice 'F6 ok: Slug ohne Familie erscheint, familie und Elterntext null';

  -- ══ Fall 7: der COACH-Satz verlaesst den Eltern-Pfad NICHT ════════════════
  --
  -- Die Zusicherung, wegen der AF4 die Signatur ueberhaupt angetastet hat.
  -- Strukturprobe: gibt es die Spalte wieder, ist der Weg nach ReportBody.tsx
  -- offen und Fachsprache steht im Elterngespraech (INV-4.3).

  if exists (
    select 1 from pg_proc p
     join unnest(p.proallargtypes, p.proargnames) as a(atttype, attname) on true
    where p.proname = 'lsa_fehlbild_auswertung'
      and p.pronamespace = 'public'::regnamespace
      and a.attname = 'klartext'
  ) then
    raise exception 'F7: lsa_fehlbild_auswertung gibt wieder klartext aus — das '
                    'ist ab AF4 der Coach-Satz und gehoert nicht in den Eltern-Pfad';
  end if;
  raise notice 'F7 ok: kein Coach-Klartext im Eltern-Pfad';

  -- ══ Fall 8: die Coach-Sicht ist unberuehrt ════════════════════════════════
  --
  -- AF4 durfte lsa_fehlbild_report nicht anfassen. Traegt sie ploetzlich eine
  -- Familie oder verliert sie den Klartext, ist die Trennung kaputt.

  select r.klartext into v_txt
    from public.lsa_fehlbild_report(v_sess) r where r.fehlbild_slug = 'af4_a';
  if v_txt is distinct from 'Coach-Satz A' then
    raise exception 'F8: Coach-Sicht liefert klartext % statt "Coach-Satz A"',
      coalesce(v_txt, '<null>');
  end if;
  if exists (
    select 1 from pg_proc p
     join unnest(p.proallargtypes, p.proargnames) as a(atttype, attname) on true
    where p.proname = 'lsa_fehlbild_report'
      and p.pronamespace = 'public'::regnamespace
      and a.attname in ('familie', 'familie_elterntext')
  ) then
    raise exception 'F8: lsa_fehlbild_report hat eine Familien-Spalte bekommen — '
                    'die Coach-Sicht sollte unveraendert bleiben';
  end if;
  raise notice 'F8 ok: lsa_fehlbild_report unveraendert (klartext, keine Familie)';

  -- ══ Fall 9: der FK haelt ══════════════════════════════════════════════════

  v_ctrl := false;
  begin
    update public.fehlbild_labels set familie = 'af4_gibt_es_nicht' where slug = 'af4_ohne';
  exception when foreign_key_violation then v_ctrl := true;
  end;
  if not v_ctrl then
    raise exception 'F9: eine Familie ohne Eintrag in fehlbild_familien war zulaessig';
  end if;
  raise notice 'F9 ok: FK auf fehlbild_familien greift';

  -- ══ Fall 10: Spaltenliste, keine Loesungsdaten ════════════════════════════
  --
  -- Strukturprobe wie in fehlbild_auswertung.PRUEFUNG.sql: die Liste ist
  -- abschliessend benannt. Waechst die RPC um eine acceptance-/correct_answers-
  -- Spalte, schlaegt das hier an.

  if (select array_agg(a.attname::text order by a.attnum)
        from pg_proc p
        join unnest(p.proallargtypes, p.proargnames) with ordinality
             as a(atttype, attname, attnum) on true
       where p.proname = 'lsa_fehlbild_auswertung'
         and p.pronamespace = 'public'::regnamespace
         and a.attname <> 'p_session_id')
     is distinct from array['fehlbild_slug','familie','familie_elterntext','anzahl',
                            'aufgaben','skills','skill_uebergreifend','einstufung'] then
    raise exception 'FSpalten: Spaltenliste von lsa_fehlbild_auswertung weicht ab';
  end if;
  raise notice 'FSpalten ok: Rueckgabespalten wie vereinbart';

  -- ══ Fall 11: Grants nach dem drop wieder gesetzt ══════════════════════════
  --
  -- `drop function` nimmt die Grants mit. Wird das vergessen, faellt die RPC
  -- fuer jeden angemeldeten Nutzer aus — und zwar erst zur Laufzeit.

  if has_function_privilege('public', 'public.lsa_fehlbild_auswertung(uuid)', 'execute') then
    raise exception 'FGrant: PUBLIC darf lsa_fehlbild_auswertung ausfuehren';
  end if;
  if not has_function_privilege('authenticated', 'public.lsa_fehlbild_auswertung(uuid)', 'execute') then
    raise exception 'FGrant: authenticated darf lsa_fehlbild_auswertung NICHT ausfuehren '
                    '— nach dem drop nicht neu gegrantet?';
  end if;
  if not has_function_privilege('service_role', 'public.lsa_fehlbild_auswertung(uuid)', 'execute') then
    raise exception 'FGrant: service_role darf lsa_fehlbild_auswertung NICHT ausfuehren';
  end if;
  raise notice 'FGrant ok: kein PUBLIC, ja authenticated + service_role';

  -- ══ Fall 12: RLS auf fehlbild_familien ════════════════════════════════════

  if not (select relrowsecurity from pg_class
           where oid = 'public.fehlbild_familien'::regclass) then
    raise exception 'FRls: RLS auf fehlbild_familien ist aus';
  end if;
  if not exists (select 1 from pg_policies
                  where schemaname = 'public' and tablename = 'fehlbild_familien'
                    and policyname = 'fehlbild_familien_read' and cmd = 'SELECT') then
    raise exception 'FRls: Leseregel fehlbild_familien_read fehlt';
  end if;
  raise notice 'FRls ok: RLS aktiv, Leserecht admin/coach';

  -- ══ Fall 13: die Bestueckung aus der Migration steht ══════════════════════
  --
  -- Inhaltspruefung. Die Migration zaehlt selbst mit (Teil 6), aber sie laeuft
  -- einmal — diese Pruefung laeuft bei jedem Neuaufbau und faengt, wenn eine
  -- spaetere Migration die Bestueckung wegraeumt.

  select count(*) into v_i from public.fehlbild_familien
   where schluessel in ('vorzeichen', 'gleichungen_umformen', 'rechenreihenfolge',
                        'einheiten_massstab', 'sachaufgaben')
     and freigegeben_am is not null and elterntext is not null;
  if v_i <> 5 then
    raise exception 'F13: % der 5 AF4-Familien sind freigegeben und bestueckt', v_i;
  end if;

  select count(*) into v_i from public.fehlbild_labels
   where familie is not null and klartext is not null and freigegeben_am is not null
     and slug not like 'af4\_%';
  if v_i <> 20 then
    raise exception 'F13: % bestueckte Fehlbilder aus AF4, erwartet 20', v_i;
  end if;
  raise notice 'F13 ok: 5 Familien und 20 Fehlbilder stehen bestueckt';

  -- ══ Fall 14: teilgekuerzt bleibt bewusst offen ════════════════════════════
  --
  -- Haelt die Entscheidung fest. Der Slug beschreibt etwas anderes als er tut
  -- (alle belegten Faelle sind UNgekuerzt); ihn zu etikettieren wuerde den
  -- Befund verstecken statt ihn zu klaeren. Faellt dieser Fall, hat jemand ihn
  -- nebenbei bestueckt statt ihn zu reparieren.

  if exists (select 1 from public.fehlbild_labels
              where slug = 'teilgekuerzt'
                and (familie is not null or klartext is not null)) then
    raise exception 'F14: teilgekuerzt wurde bestueckt — erst umbenennen, dann etikettieren';
  end if;
  raise notice 'F14 ok: teilgekuerzt steht unbestueckt (offener Punkt, kein Versehen)';

  -- ══ Negativkontrolle des Harnischs selbst ═════════════════════════════════

  v_ctrl := false;
  begin
    if (select count(*) from public.lsa_fehlbild_auswertung(v_sess)) <> -1 then
      raise exception 'kontrolle: absichtlich falsche Erwartung';
    end if;
  exception when others then v_ctrl := true;
  end;
  if not v_ctrl then raise exception 'FKontrolle: der Harnisch loest nicht aus'; end if;
  raise notice 'FKontrolle ok: falsche Erwartung bricht den Lauf ab';

  raise notice 'AF4: ALLE PRUEFUNGEN BESTANDEN';
end $$;

rollback;
