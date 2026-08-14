-- PRUEFUNG zu AF2 (lsa_fehlbild_report / lsa_fehlbild_auswertung).
--
--   psql "postgresql:///edvance_neuaufbau" -v ON_ERROR_STOP=1 \
--        -f supabase/checks/fehlbild_auswertung.PRUEFUNG.sql
--
-- KEIN Zeitstempel im Dateinamen: bei a21_freigabe_muster trugen Migration und
-- Pruefskript dieselbe Version — und wurden verwechselt. Der Name sagt, was
-- geprueft wird, nicht wann es gebaut wurde.
--
-- KEIN \ir auf die Migration. Das Skript laeuft gegen eine bereits migrierte
-- Datenbank (tools/neuaufbau-test.sh baut sie).
--
-- Legt seine Testdaten SELBST an: die Neuaufbau-Datenbank ist leer, dort gibt
-- es keine Sitzungen, keine Aufgaben und keine Labels zum Anlehnen.
--
-- Faengt sich SELBST in begin/rollback. Die Datenbank ueberlebt zwischen
-- Laeufen und einen Runner, der die Klammer setzt, gibt es nicht — ohne
-- Rollback kollidiert der zweite Lauf mit den Daten des ersten.

begin;

do $$
declare
  v_student uuid := gen_random_uuid();
  v_stud2   uuid := gen_random_uuid();
  v_sess    uuid := gen_random_uuid();  -- Sitzung mit Fehlbildern
  v_leer    uuid := gen_random_uuid();  -- Sitzung ohne Falschantworten (Fall 8)
  v_t       uuid[];                     -- T1..T6
  v_n       bigint;
  v_txt     text;
  v_txt2    text;
  v_bool    boolean;
  v_num     numeric;
  v_arr     text[];
  v_ctrl    boolean;
  v_coach   uuid := gen_random_uuid();
begin
  -- ══ Testdaten ═════════════════════════════════════════════════════════════

  -- Identitaet setzen: ohne Rolle liefert get_my_role() null, lsa_may_act_for
  -- gibt null zurueck und coalesce(...,false) in AF2 sperrt alles weg.
  insert into auth.users (id, email) values (v_coach, 'pruef-coach@edvance.test');
  insert into public.profiles (id, email, role)
    values (v_coach, 'pruef-coach@edvance.test', 'coach');
  perform set_config('request.jwt.claim.sub', v_coach::text, true);

  -- Zwei Skills — Fall 5 braucht ein Fehlbild, das ueber beide laeuft.
  insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
  values ('AF2_BRUCH',  'AF2 Probe Brueche',   'mathematik', 8, 1),
         ('AF2_GLEICH', 'AF2 Probe Gleichungen','mathematik', 8, 1);

  -- students.profile_id/lead_id bleiben leer: is_provisional=false passiert den
  -- students_guard_provisional-Trigger, und mehr braucht die Sitzung nicht.
  -- Zwei Kinder, weil lsa_sessions_active_unique nur EINE laufende Sitzung je
  -- (student_id, subject) zulaesst — die leere Sitzung (Fall 8) braucht ein
  -- eigenes Kind statt einen Statuswechsel, der Platz-/Lead-Trigger auslöst.
  insert into public.students (id, class_level) values (v_student, 8), (v_stud2, 8);

  insert into public.lsa_sessions (id, student_id, subject, grade)
  values (v_sess, v_student, 'mathematik', 8),
         (v_leer, v_stud2,   'mathematik', 8);

  -- T1..T4 auf AF2_BRUCH, T5..T6 auf AF2_GLEICH.
  select array_agg(id order by nr) into v_t
    from (select gen_random_uuid() as id, nr from generate_series(1, 6) as nr) x;

  insert into public.tasks (id, content_type, skill_key, question)
  values (v_t[1], 'exercise', 'AF2_BRUCH',  'AF2 Probe 1'),
         (v_t[2], 'exercise', 'AF2_BRUCH',  'AF2 Probe 2'),
         (v_t[3], 'exercise', 'AF2_BRUCH',  'AF2 Probe 3'),
         (v_t[4], 'exercise', 'AF2_BRUCH',  'AF2 Probe 4'),
         (v_t[5], 'exercise', 'AF2_GLEICH', 'AF2 Probe 5'),
         (v_t[6], 'exercise', 'AF2_GLEICH', 'AF2 Probe 6');

  -- Registry: vier von fuenf Slugs bekommen einen Klartext. 'af2_unbekannt'
  -- fehlt ABSICHTLICH — das ist Fall 6.
  insert into public.fehlbild_labels (slug, klartext, erklaerung)
  values ('af2_einmal',     'einmal gesehen',      'Probe'),
         ('af2_eine_aufg',  'zweimal, ein Item',   'Probe'),
         ('af2_zwei_aufg',  'zweimal, zwei Items', 'Probe'),
         ('af2_ueber',      'skilluebergreifend',  'Probe');

  -- Die Abgaben. fehlbild_slug wird direkt gesetzt: der AF1-Trigger
  -- (trg_lsa_fehlbild_capture) findet ohne task_solutions keine known_errors,
  -- steigt aus und ueberschreibt nichts (er schreibt nur, wo der Slug null ist).
  -- Der Unique-Index lsa_responses_once_per_part erzwingt verschiedene part_nr
  -- je Aufgabe — deshalb traegt Fall 3 zwei Teilaufgaben desselben Items.
  insert into public.lsa_responses
    (session_id, task_id, part_nr, abgabeart, correct, response, fehlbild_slug)
  values
    -- Fall 2: ein einziges Vorkommen
    (v_sess, v_t[1], 1, 'antwort', false, '{"text":"x"}'::jsonb, 'af2_einmal'),
    -- Fall 3: zwei Vorkommen in DERSELBEN Aufgabe
    (v_sess, v_t[2], 1, 'antwort', false, '{"text":"x"}'::jsonb, 'af2_eine_aufg'),
    (v_sess, v_t[2], 2, 'antwort', false, '{"text":"x"}'::jsonb, 'af2_eine_aufg'),
    -- Fall 4: zwei Vorkommen in ZWEI Aufgaben
    (v_sess, v_t[3], 1, 'antwort', false, '{"text":"x"}'::jsonb, 'af2_zwei_aufg'),
    (v_sess, v_t[4], 1, 'antwort', false, '{"text":"x"}'::jsonb, 'af2_zwei_aufg'),
    -- Fall 5: drei Vorkommen ueber beide Skills (1x BRUCH, 2x GLEICH)
    (v_sess, v_t[1], 2, 'antwort', false, '{"text":"x"}'::jsonb, 'af2_ueber'),
    (v_sess, v_t[5], 1, 'antwort', false, '{"text":"x"}'::jsonb, 'af2_ueber'),
    (v_sess, v_t[6], 1, 'antwort', false, '{"text":"x"}'::jsonb, 'af2_ueber'),
    -- Fall 6: Slug ohne Eintrag in fehlbild_labels
    (v_sess, v_t[3], 2, 'antwort', false, '{"text":"x"}'::jsonb, 'af2_unbekannt'),
    -- Fall 7: falsche Antwort ohne Slug
    (v_sess, v_t[4], 2, 'antwort', false, '{"text":"x"}'::jsonb, null),
    -- richtige Antwort — darf nirgends auftauchen
    (v_sess, v_t[5], 2, 'antwort', true,  '{"text":"x"}'::jsonb, null),
    -- Fall 10: weiss_nicht/leer. Sie tragen hier ABSICHTLICH einen Slug,
    -- obwohl AF1 das nie erzeugen wuerde — ohne Slug pruefte der Fall nichts,
    -- weil eine Zeile ohne Slug schon an jedem anderen Filter haengen bleibt.
    -- Nachgemessen: die abgabeart-Bedingung allein aus den RPCs zu streichen
    -- aendert das Ergebnis NICHT, denn der CHECK
    -- lsa_responses_correct_nur_bei_antwort haelt correct hier zwingend NULL,
    -- und `correct is false` sortiert die Zeilen schon aus. Die beiden
    -- Bedingungen sind per Schema redundant. Geprueft wird deshalb das
    -- Ergebnis, nicht der Weg dahin: die Zeilen duerfen nirgends auftauchen —
    -- egal welche der beiden Bedingungen sie faengt.
    (v_sess, v_t[6], 2, 'weiss_nicht', null, null, 'af2_zwei_aufg'),
    (v_sess, v_t[1], 3, 'leer',        null, null, 'af2_ueber');

  -- Fall 8: Sitzung mit ausschliesslich richtigen Antworten.
  insert into public.lsa_responses
    (session_id, task_id, part_nr, abgabeart, correct, response, fehlbild_slug)
  values (v_leer, v_t[1], 1, 'antwort', true, '{"text":"x"}'::jsonb, null),
         (v_leer, v_t[5], 1, 'antwort', true, '{"text":"x"}'::jsonb, null);

  -- ══ Fall 1: Summe anzahl je Skill == Zahl der Falschantworten des Skills ══
  --
  -- Nicht gegen eine ausgerechnete Zahl geprueft, sondern gegen die Quelle:
  -- so haelt der Fall auch, wenn oben eine Zeile dazukommt.
  select count(*) into v_n
    from (select r.skill_key, sum(r.anzahl) as summe
            from public.lsa_fehlbild_report(v_sess) r
           group by r.skill_key) rep
    join (select t.skill_key, count(*) as ist
            from public.lsa_responses x
            join public.tasks t on t.id = x.task_id
           where x.session_id = v_sess
             and x.abgabeart = 'antwort' and x.correct is false
           group by t.skill_key) roh using (skill_key)
   where rep.summe <> roh.ist;
  if v_n <> 0 then
    raise exception 'F1: % Skill(s) mit abweichender Summe', v_n;
  end if;
  -- ... und keine Seite hat Skills, die die andere nicht kennt.
  if (select count(distinct r.skill_key) from public.lsa_fehlbild_report(v_sess) r) <> 2 then
    raise exception 'F1: erwartet 2 Skills im Report';
  end if;
  -- Konkret: AF2_BRUCH hat 8 Falschantworten, AF2_GLEICH 2.
  select sum(r.anzahl) into v_n from public.lsa_fehlbild_report(v_sess) r
   where r.skill_key = 'AF2_BRUCH';
  if v_n <> 8 then raise exception 'F1: AF2_BRUCH Summe %, erwartet 8', v_n; end if;
  select sum(r.anzahl) into v_n from public.lsa_fehlbild_report(v_sess) r
   where r.skill_key = 'AF2_GLEICH';
  if v_n <> 2 then raise exception 'F1: AF2_GLEICH Summe %, erwartet 2', v_n; end if;
  raise notice 'F1 ok: Summe anzahl je Skill == Falschantworten des Skills (8 / 2)';

  -- Sortierung: Skill aufsteigend, darin Anzahl absteigend.
  select count(*) into v_n from (
    select r.skill_key, r.anzahl,
           lag(r.skill_key) over () as vor_skill,
           lag(r.anzahl)    over () as vor_anzahl
      from public.lsa_fehlbild_report(v_sess) r) x
   where x.vor_skill is not null
     and (x.skill_key < x.vor_skill
          or (x.skill_key = x.vor_skill and x.anzahl > x.vor_anzahl));
  if v_n <> 0 then raise exception 'FSort: % Bruch/Brueche in der Sortierung', v_n; end if;
  raise notice 'FSort ok: Skill aufsteigend, darin Anzahl absteigend';

  -- anteil ist der Anteil an den Falschantworten DES SKILLS, nicht der Sitzung.
  select r.anteil into v_num from public.lsa_fehlbild_report(v_sess) r
   where r.skill_key = 'AF2_BRUCH' and r.fehlbild_slug = 'af2_eine_aufg';
  if v_num <> 0.25 then raise exception 'FAnteil: %, erwartet 0.25 (2 von 8)', v_num; end if;
  select r.anteil into v_num from public.lsa_fehlbild_report(v_sess) r
   where r.skill_key = 'AF2_GLEICH' and r.fehlbild_slug = 'af2_ueber';
  if v_num <> 1 then raise exception 'FAnteil: %, erwartet 1 (2 von 2)', v_num; end if;
  raise notice 'FAnteil ok: Nenner ist der Skill, nicht die Sitzung';

  -- ══ Fall 2: ein Vorkommen -> beobachtung ═════════════════════════════════
  select a.einstufung, a.anzahl, a.aufgaben
    into v_txt, v_n, v_num
    from public.lsa_fehlbild_auswertung(v_sess) a where a.fehlbild_slug = 'af2_einmal';
  if v_txt is distinct from 'beobachtung' or v_n <> 1 or v_num <> 1 then
    raise exception 'F2: einstufung=%, anzahl=%, aufgaben=% — erwartet beobachtung/1/1',
      v_txt, v_n, v_num;
  end if;
  raise notice 'F2 ok: ein Vorkommen -> beobachtung';

  -- ══ Fall 3: zwei Vorkommen, DIESELBE Aufgabe -> beobachtung, aufgaben=1 ══
  --
  -- NEGATIVKONTROLLE. Verkuerzt jemand die Einstufung auf `anzahl >= 2`,
  -- kippt genau diese Zeile auf 'befund' und der Lauf bricht ab.
  select a.einstufung, a.anzahl, a.aufgaben
    into v_txt, v_n, v_num
    from public.lsa_fehlbild_auswertung(v_sess) a where a.fehlbild_slug = 'af2_eine_aufg';
  if v_txt is distinct from 'beobachtung' or v_n <> 2 or v_num <> 1 then
    raise exception 'F3: einstufung=%, anzahl=%, aufgaben=% — erwartet beobachtung/2/1',
      v_txt, v_n, v_num;
  end if;
  raise notice 'F3 ok: zwei Vorkommen in EINER Aufgabe bleiben beobachtung (aufgaben=1)';

  -- ══ Fall 4: zwei Vorkommen, zwei Aufgaben -> befund ══════════════════════
  select a.einstufung, a.anzahl, a.aufgaben, a.skill_uebergreifend
    into v_txt, v_n, v_num, v_bool
    from public.lsa_fehlbild_auswertung(v_sess) a where a.fehlbild_slug = 'af2_zwei_aufg';
  if v_txt is distinct from 'befund' or v_n <> 2 or v_num <> 2 then
    raise exception 'F4: einstufung=%, anzahl=%, aufgaben=% — erwartet befund/2/2',
      v_txt, v_n, v_num;
  end if;
  -- Fall 10, Teil 1: die weiss_nicht-Zeile trug denselben Slug. Zaehlte sie
  -- mit, waere anzahl 3 — der Fall oben haette es schon gemeldet.
  if v_bool is distinct from false then
    raise exception 'F4: skill_uebergreifend=%, erwartet false (nur AF2_BRUCH)', v_bool;
  end if;
  raise notice 'F4 ok: zwei Vorkommen in zwei Aufgaben -> befund';

  -- ══ Fall 5: drei Vorkommen ueber zwei Skills -> skill_uebergreifend ══════
  select a.anzahl, a.skill_uebergreifend, a.skills, a.einstufung
    into v_n, v_bool, v_arr, v_txt
    from public.lsa_fehlbild_auswertung(v_sess) a where a.fehlbild_slug = 'af2_ueber';
  if v_n <> 3 then raise exception 'F5: anzahl %, erwartet 3 (leer-Zeile zaehlt nicht)', v_n; end if;
  if v_bool is distinct from true then raise exception 'F5: skill_uebergreifend %', v_bool; end if;
  if v_arr is distinct from array['AF2_BRUCH', 'AF2_GLEICH'] then
    raise exception 'F5: skills %, erwartet {AF2_BRUCH,AF2_GLEICH}', v_arr;
  end if;
  if v_txt is distinct from 'befund' then raise exception 'F5: einstufung %', v_txt; end if;
  raise notice 'F5 ok: drei Vorkommen ueber zwei Skills -> skill_uebergreifend, befund';

  -- ══ Fall 6: Slug ohne Registry-Eintrag ═══════════════════════════════════
  --
  -- NEGATIVKONTROLLE. Vereinfacht jemand den Registry-Join auf INNER JOIN,
  -- verschwindet diese Zeile aus BEIDEN RPCs und der Lauf bricht ab.
  select count(*) into v_n from public.lsa_fehlbild_auswertung(v_sess) a
   where a.fehlbild_slug = 'af2_unbekannt';
  if v_n <> 1 then raise exception 'F6: Zeile fehlt in lsa_fehlbild_auswertung (INNER JOIN?)'; end if;
  -- Ab AF4 gibt die Auswertung keinen klartext mehr aus (das ist der Coach-Satz
  -- und bleibt in lsa_fehlbild_report). Geprueft wird hier stattdessen, dass
  -- auch die Familie null bleibt — derselbe LEFT-JOIN-Befund, eine Spalte
  -- weiter: ein Slug ohne Registry-Eintrag hat auch keine Familie.
  select a.familie into v_txt from public.lsa_fehlbild_auswertung(v_sess) a
   where a.fehlbild_slug = 'af2_unbekannt';
  if v_txt is not null then raise exception 'F6: familie %, erwartet null', v_txt; end if;
  select count(*) into v_n from public.lsa_fehlbild_report(v_sess) r
   where r.fehlbild_slug = 'af2_unbekannt' and r.klartext is null;
  if v_n <> 1 then raise exception 'F6: Zeile fehlt in lsa_fehlbild_report (INNER JOIN?)'; end if;
  raise notice 'F6 ok: unbekannter Slug erscheint, klartext null (kein INNER JOIN)';

  -- ══ Fall 7: falsche Antwort ohne Slug -> eigene Zeile ════════════════════
  select r.klartext, r.anzahl, r.skill_key into v_txt, v_n, v_txt2
    from public.lsa_fehlbild_report(v_sess) r
   where r.fehlbild_slug is null;
  if v_txt is distinct from 'nicht zugeordnet' or v_n <> 1 then
    raise exception 'F7: klartext=%, anzahl=% — erwartet ''nicht zugeordnet''/1', v_txt, v_n;
  end if;
  if v_txt2 is distinct from 'AF2_BRUCH' then
    raise exception 'F7: skill_key %, erwartet AF2_BRUCH', v_txt2;
  end if;
  -- In der Sitzungssicht hat "nicht zugeordnet" nichts verloren.
  if (select count(*) from public.lsa_fehlbild_auswertung(v_sess) a
       where a.fehlbild_slug is null) <> 0 then
    raise exception 'F7: lsa_fehlbild_auswertung stuft eine Zeile ohne Slug ein';
  end if;
  raise notice 'F7 ok: Falschantwort ohne Slug als eigene Zeile ''nicht zugeordnet''';

  -- ══ Fall 8: Sitzung ohne Falschantworten -> leer, kein Fehler ════════════
  if (select count(*) from public.lsa_fehlbild_report(v_leer)) <> 0
     or (select count(*) from public.lsa_fehlbild_auswertung(v_leer)) <> 0 then
    raise exception 'F8: Sitzung ohne Falschantworten liefert Zeilen';
  end if;
  raise notice 'F8 ok: Sitzung ohne Falschantworten -> leeres Ergebnis';

  -- ══ Fall 9: unbekannte Sitzungs-ID -> leer, kein Fehler ══════════════════
  if (select count(*) from public.lsa_fehlbild_report(gen_random_uuid())) <> 0
     or (select count(*) from public.lsa_fehlbild_auswertung(gen_random_uuid())) <> 0 then
    raise exception 'F9: unbekannte Sitzungs-ID liefert Zeilen';
  end if;
  raise notice 'F9 ok: unbekannte Sitzungs-ID -> leeres Ergebnis, kein Fehler';

  -- ══ Fall 10: weiss_nicht / leer zaehlen nicht als falsch ═════════════════
  --
  -- Beide Kunstzeilen tragen einen Slug (s.o.). Der Vergleich gegen die
  -- Rohzahl deckt jeden Weg auf, auf dem sie doch mitgezaehlt werden.
  select count(*) into v_n from public.lsa_responses x
   where x.session_id = v_sess and x.abgabeart in ('weiss_nicht', 'leer');
  if v_n <> 2 then raise exception 'F10: Testdaten fehlen (% statt 2)', v_n; end if;
  select coalesce(sum(a.anzahl), 0) into v_n from public.lsa_fehlbild_auswertung(v_sess) a;
  if v_n <> 9 then
    raise exception 'F10: Summe anzahl % ueber die Sitzung, erwartet 9 '
                    '(weiss_nicht/leer zaehlen mit?)', v_n;
  end if;
  select coalesce(sum(r.anzahl), 0) into v_n from public.lsa_fehlbild_report(v_sess) r;
  if v_n <> 10 then
    raise exception 'F10: Summe anzahl % im Report, erwartet 10 '
                    '(9 mit Slug + 1 nicht zugeordnet)', v_n;
  end if;
  raise notice 'F10 ok: weiss_nicht/leer zaehlen nicht als falsche Antwort';

  -- ══ Sicherheit: keine Loesungsdaten in der Rueckgabe ═════════════════════
  --
  -- Strukturprobe statt Wortprobe: die Spaltenlisten sind abschliessend
  -- benannt. Waechst eine RPC um eine acceptance-/correct_answers-Spalte,
  -- schlaegt das hier an.
  if (select array_agg(a.attname::text order by a.attnum)
        from pg_proc p
        join unnest(p.proallargtypes, p.proargnames) with ordinality
             as a(atttype, attname, attnum) on true
       where p.proname = 'lsa_fehlbild_report'
         and p.pronamespace = 'public'::regnamespace
         and a.attname <> 'p_session_id')
     is distinct from array['skill_key','fehlbild_slug','klartext','anzahl','anteil'] then
    raise exception 'FSec: Spaltenliste von lsa_fehlbild_report weicht ab';
  end if;
  if (select array_agg(a.attname::text order by a.attnum)
        from pg_proc p
        join unnest(p.proallargtypes, p.proargnames) with ordinality
             as a(atttype, attname, attnum) on true
       where p.proname = 'lsa_fehlbild_auswertung'
         and p.pronamespace = 'public'::regnamespace
         and a.attname <> 'p_session_id')
     -- Stand AF4: klartext ist raus (Coach-Satz, nur noch in
     -- lsa_fehlbild_report), familie + familie_elterntext sind dazugekommen.
     is distinct from array['fehlbild_slug','familie','familie_elterntext','anzahl',
                            'aufgaben','skills','skill_uebergreifend','einstufung'] then
    raise exception 'FSec: Spaltenliste von lsa_fehlbild_auswertung weicht ab';
  end if;
  raise notice 'FSec ok: Rueckgabespalten unveraendert, keine Loesungsdaten';

  -- ══ Grants: nicht an PUBLIC, ja an authenticated + service_role ══════════
  --
  -- PUBLIC ist keine Rolle in pg_roles — die ACL traegt sie als grantee 0.
  -- Deshalb aclexplode statt has_function_privilege fuer diese Haelfte.
  select count(*) into v_n
    from pg_proc p, aclexplode(p.proacl) acl
   where p.pronamespace = 'public'::regnamespace
     and p.proname in ('lsa_fehlbild_report', 'lsa_fehlbild_auswertung')
     and acl.grantee = 0
     and acl.privilege_type = 'EXECUTE';
  if v_n <> 0 then raise exception 'FGrant: PUBLIC darf noch ausfuehren (% Eintrag/Eintraege)', v_n; end if;

  select count(*) into v_n
    from (values ('lsa_fehlbild_report'), ('lsa_fehlbild_auswertung')) f(fn)
   where not has_function_privilege('authenticated', 'public.' || f.fn || '(uuid)', 'execute')
      or not has_function_privilege('service_role',  'public.' || f.fn || '(uuid)', 'execute');
  if v_n <> 0 then raise exception 'FGrant: % RPC(s) ohne authenticated/service_role', v_n; end if;
  raise notice 'FGrant ok: PUBLIC entzogen, authenticated + service_role duerfen';

  -- ══ Negativkontrolle des Harnischs selbst ════════════════════════════════
  v_ctrl := false;
  begin
    if (select count(*) from public.lsa_fehlbild_auswertung(v_sess)) <> -1 then
      raise exception 'kontrolle: absichtlich falsche Erwartung';
    end if;
  exception when others then v_ctrl := true;
  end;
  if not v_ctrl then raise exception 'FKontrolle: der Harnisch loest nicht aus'; end if;
  raise notice 'FKontrolle ok: falsche Erwartung bricht den Lauf ab';

  raise notice 'AF2: ALLE PRUEFUNGEN BESTANDEN';
end $$;

rollback;
