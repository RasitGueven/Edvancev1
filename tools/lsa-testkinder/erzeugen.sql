-- LSA-T: fünf erfundene Testkinder mit vollständiger LSA (Bauauftrag docs/lsa/Bauauftrag-LSA-T.md).
--
-- Start (eine Transaktion, bricht etwas, wird alles zurückgerollt):
--   dbcheck && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f tools/lsa-testkinder/erzeugen.sql
--
-- Was passiert, je Kind:
--   1. Lead mit Erstgespräch (feste UUID, Phantasiedaten, ist_test) und provisorischer Schülerdatensatz
--      (feste UUID, wie lead_lsa_freigeben ihn anlegt). Ein zweiter Lauf aktualisiert nur die Lead-Angaben.
--   2. Aktuelles Thema über lead_thema_setzen, behandelte Themen wie die Erstgesprächs-Maske,
--      Anliegen über lead_assessment_upsert.
--   3. LSA über lead_lsa_freigeben (→ lsa_start), jede Antwort über lsa_submit, Abschluss über lsa_finish —
--      dieselben RPCs wie die App, als bestehender Admin (request.jwt.claims). Das Skript schreibt nie in
--      lsa_skill_urteil, lsa_responses oder result_summary.
--   4. Die Uhr: Nach der Freigabe wird lsa_sessions.started_at einmal um 20 Minuten zurückgesetzt, noch vor
--      der ersten Antwort. Jede Antwort geht mit p_jetzt = Beginn + Summe der bisherigen Antwortdauern und
--      p_duration_ms an lsa_submit. Die Auswahl liest die Zeit nur als Abstand p_jetzt − Beginn
--      (19 Minuten, Tiefe bis 12, LSA-V Vorschau bis 16); der Abstand ist derselbe wie bei einem Kind, das
--      wirklich so lange braucht. Die erste Aufgabe zog lsa_start beim Abstand 0 — auch das bleibt gleich.
--
-- Ein zweiter Lauf legt neue Sitzungen an und löscht nichts. Die Tabelle am Ende nennt die neueste Sitzung
-- je Kind. Kein DDL, keine Funktionen, keine Tabellen.

\set ON_ERROR_STOP on

-- ── Die fünf Kinder ──────────────────────────────────────────────────────────────────────────────
-- grund: Zustand je Klassenstufe (Herkunftsklasse des Skills: 56 = bis 6, 78 = 7/8, 910 = ab 9).
-- ausnahmen: je skill_key, überschreibt den Grundstand. Zustände: sicher | uebung | teilweise | nicht_angesetzt.
-- familie/fehlbilder: bevorzugtes Fehlbild bei falschen Antworten (erst die Slugs, dann die Familie).
-- anliegen: nur Werte aus PARENT_WEAK_TOPICS (src/pages/admin/intake/intakeConstants.ts), alles andere in notiz.
-- sekunden: Antwortdauer, je Aufgabe nach festem Muster variiert (unten c_muster).
do $do$ begin perform set_config('lsat.kinder', $kinder$[
 {"kind": "Lina", "name": "Lina Berger", "lead": "a5a7c41d-1ead-4000-8000-000000000001", "schueler": "a5a7c41d-5c00-4000-8000-000000000001",
  "klasse": 9, "schulform": "Gymnasium", "schule": "Friedrich-Wilhelm-Gymnasium", "thema": "quadratische_funktionen",
  "behandelt": ["reelle_zahlen", "lineare_funktionen", "terme_binomische_formeln"], "quelle_behandelt": "schulplan",
  "anliegen": ["Rechenwege"], "notiz": "Noten halten, Oberstufe vorbereiten.",
  "goal": "GENERAL", "letzte_note": "2+", "trend": "stabil", "interessen": "Volleyball, Fotografie",
  "grund": {"56": "sicher", "78": "sicher", "910": "sicher"}, "ausnahmen": {"geo_flaeche_dreieck": "uebung"},
  "familie": null, "fehlbilder": [], "sekunden": 40},
 {"kind": "Emre", "name": "Emre Kaya", "lead": "a5a7c41d-1ead-4000-8000-000000000002", "schueler": "a5a7c41d-5c00-4000-8000-000000000002",
  "klasse": 9, "schulform": "Gymnasium", "schule": "Friedrich-Wilhelm-Gymnasium", "thema": "reelle_zahlen",
  "behandelt": ["lineare_funktionen", "terme_binomische_formeln", "lineare_gleichungen_lgs"], "quelle_behandelt": "schulplan",
  "anliegen": ["Grundlagen fehlen"], "notiz": "Klassenarbeit über Wurzeln in drei Wochen.",
  "goal": "EXAM_PREP", "pruefung_tage": 21, "pruefung_thema": "Reelle Zahlen und Wurzeln", "letzte_note": "3", "trend": "schlechter",
  "interessen": "Fußball, Videospiele",
  "grund": {"56": "sicher", "78": "sicher", "910": "sicher"},
  "ausnahmen": {"zahl_wurzel_gesetze": "uebung", "zahl_wurzel_teilweise": "uebung"},
  "familie": "potenzen_wurzeln", "fehlbilder": ["wurzel_gliedweise"], "sekunden": 60},
 {"kind": "Sophie", "name": "Sophie Wagner", "lead": "a5a7c41d-1ead-4000-8000-000000000003", "schueler": "a5a7c41d-5c00-4000-8000-000000000003",
  "klasse": 8, "schulform": "Realschule", "schule": null, "thema": "lineare_funktionen",
  "behandelt": ["rationale_zahlen", "zuordnungen", "terme_gleichungen"], "quelle_behandelt": "gespraech",
  "anliegen": ["Textverständnis", "Konzentration"], "notiz": "Mathe-Note abgerutscht, wenig Motivation.",
  "goal": "IMPROVE_GRADES", "letzte_note": "4", "trend": "schlechter", "interessen": "Pferde, Zeichnen",
  "grund": {"56": "sicher", "78": "uebung", "910": "uebung"},
  "ausnahmen": {"geo_koordinaten": "teilweise", "fkt_linear_yabschnitt": "teilweise"},
  "familie": "geraden_schaubilder", "fehlbilder": ["steigung_kehrwert"], "sekunden": 80},
 {"kind": "Jonas", "name": "Jonas Richter", "lead": "a5a7c41d-1ead-4000-8000-000000000004", "schueler": "a5a7c41d-5c00-4000-8000-000000000004",
  "klasse": 8, "schulform": "Gesamtschule", "schule": null, "thema": "terme_gleichungen",
  "behandelt": ["rationale_zahlen", "zuordnungen"], "quelle_behandelt": "gespraech",
  "anliegen": ["Grundlagen fehlen", "Konzentration"], "notiz": "Versetzung gefährdet.",
  "goal": "CLOSE_GAPS", "letzte_note": "5", "trend": "schlechter", "interessen": "Skateboard, Minecraft",
  "grund": {"56": "uebung", "78": "nicht_angesetzt", "910": "nicht_angesetzt"},
  "ausnahmen": {"vorzeichen_add_sub": "uebung", "vorzeichen_mult_div": "uebung", "vorzeichen_vorrang": "uebung",
                "term_zusammenfassen": "uebung", "runden_ueberschlag": "sicher"},
  "familie": "vorzeichen", "fehlbilder": [], "sekunden": 110},
 {"kind": "Nele", "name": "Nele Schmitz", "lead": "a5a7c41d-1ead-4000-8000-000000000005", "schueler": "a5a7c41d-5c00-4000-8000-000000000005",
  "klasse": 7, "schulform": "Gymnasium", "schule": null, "thema": "zinsrechnung",
  "behandelt": ["rationale_zahlen", "zuordnungen"], "quelle_behandelt": "gespraech",
  "anliegen": ["Prüfungsangst"], "notiz": "Wenig Motivation, Mathe macht ihr gerade keinen Spaß.",
  "goal": "GENERAL", "letzte_note": "3-", "trend": "stabil", "interessen": "Tanzen, Tiere",
  "grund": {"56": "sicher", "78": "sicher", "910": "uebung"},
  "ausnahmen": {"prozent_grundwert": "uebung", "prozent_prozentsatz": "uebung", "prozent_veraenderung": "uebung",
                "prozent_zins_zinseszins": "uebung", "prozent_zins_rueckrechnung": "uebung",
                "bruch_add": "teilweise", "bruch_mult": "teilweise", "bruch_div": "teilweise", "bruch_dezimal": "teilweise"},
  "familie": "rechenart_formel", "fehlbilder": ["multipliziert_statt_dividiert", "grundwert_verwechselt", "falsche_richtung"],
  "sekunden": 70}
]$kinder$, false);
  perform set_config('lsat.sitzungen', '{}', false);
end $do$;

-- Ein bestehender Admin; seine Claims gelten für alle RPCs (wie die bestehenden Tests). Kein service_role.
do $$
declare v_admin uuid := (select id from profiles where role = 'admin' order by created_at nulls last, id limit 1);
begin
  if v_admin is null then
    raise exception 'LSA-T: kein Admin-Profil';
  end if;
  perform set_config('lsat.admin', v_admin::text, false);
  perform set_config('request.jwt.claims', json_build_object('sub', v_admin, 'role', 'authenticated')::text, false);
end $$;

-- ── 1. Leads, Schüler, Erstgespräch ──────────────────────────────────────────────────────────────
do $$
declare
  k        jsonb;
  v_admin  uuid := current_setting('lsat.admin')::uuid;
  v_lead   uuid;
  v_schule uuid;
  v_th     text;
begin
  for k in select * from jsonb_array_elements(current_setting('lsat.kinder')::jsonb) loop
    v_lead := (k ->> 'lead')::uuid;
    v_schule := (select s.id from schulen s where s.name = k ->> 'schule');
    if k ->> 'schule' is not null and v_schule is null then
      raise exception 'LSA-T: Schule % fehlt', k ->> 'schule';
    end if;

    insert into leads (id, full_name, first_name, contact_email, class_level, school_type, school_name, schule_id,
                       subjects, goal, last_grade, grade_trend, next_exam_date, next_exam_topic, source, status,
                       notes, erstgespraech_at, erstgespraech_standort, consent_dsgvo_at, consent_dsgvo_by, ist_test)
    values (v_lead, k ->> 'name', k ->> 'kind', lower(k ->> 'kind') || '@example.invalid', (k ->> 'klasse')::int,
            k ->> 'schulform', k ->> 'schule', v_schule, '{Mathematik}', k ->> 'goal', k ->> 'letzte_note', k ->> 'trend',
            current_date + (k ->> 'pruefung_tage')::int, k ->> 'pruefung_thema', 'lsa-testkinder', 'contacted',
            'Testkind LSA-T (Phantasiedaten). Interessenswelt: ' || (k ->> 'interessen'),
            now() - interval '7 days', 'koeln', now(), v_admin, true)
    on conflict (id) do update
       set full_name = excluded.full_name, first_name = excluded.first_name, contact_email = excluded.contact_email,
           class_level = excluded.class_level, school_type = excluded.school_type, school_name = excluded.school_name,
           schule_id = excluded.schule_id, goal = excluded.goal, last_grade = excluded.last_grade,
           grade_trend = excluded.grade_trend, next_exam_date = excluded.next_exam_date,
           next_exam_topic = excluded.next_exam_topic, notes = excluded.notes;

    -- Der provisorische Schüler, wie lead_lsa_freigeben ihn anlegt — nur mit fester id.
    perform set_config('edvance.allow_provisional', '1', true);
    insert into students (id, profile_id, class_level, school_name, school_type, is_provisional, lead_id)
    values ((k ->> 'schueler')::uuid, null, (k ->> 'klasse')::int, k ->> 'schule', k ->> 'schulform', true, v_lead)
    on conflict (id) do nothing;
    perform set_config('edvance.allow_provisional', '', true);
    if not exists (select 1 from students where id = (k ->> 'schueler')::uuid and lead_id = v_lead and ist_test) then
      raise exception 'LSA-T: Schüler % hängt nicht als Testkonto am Lead %', k ->> 'schueler', v_lead;
    end if;

    perform public.lead_thema_setzen(v_lead, 'mathematik', k ->> 'thema', 'gespraech');
    for v_th in select jsonb_array_elements_text(k -> 'behandelt') loop
      insert into lead_themen (lead_id, fach, thema_key, status, quelle)
      values (v_lead, 'mathematik', v_th, 'behandelt', k ->> 'quelle_behandelt')
      on conflict (lead_id, thema_key) do nothing;
    end loop;
    perform public.lead_assessment_upsert(v_lead, 'parent', k ->> 'notiz',
                                          array(select jsonb_array_elements_text(k -> 'anliegen')));
  end loop;
end $$;

-- ── 2. Die LSA je Kind ───────────────────────────────────────────────────────────────────────────
do $$
declare
  c_muster constant numeric[] := array[1.0, 1.25, 0.8, 1.1, 0.9, 1.3, 0.75, 1.05];
  k        jsonb;
  v_s      uuid;
  v_t      timestamptz;
  v_task   tasks;
  v_sol    task_solutions;
  v_zust   text;
  v_resp   jsonb;
  v_dauer  int;
  v_i      int;
  v_teil   jsonb;
  v_nr     text;
  v_ke     jsonb;
  v_kind   text;
  v_typ    text;
  v_antw   jsonb;
  v_hint   text;
  v_falsch text;
  v_richt  jsonb;
  v_wert   text;
  v_falsch_nr text;
begin
  for k in select * from jsonb_array_elements(current_setting('lsat.kinder')::jsonb) loop
    v_s := (public.lead_lsa_freigeben((k ->> 'lead')::uuid, (k ->> 'klasse')::int, 'Mathematik') ->> 'session_id')::uuid;
    update lsa_sessions set started_at = started_at - interval '20 minutes' where id = v_s
    returning started_at into v_t;
    -- Die Sitzung dieses Laufs (der Bericht unten liest sie von hier, nicht über Zeitstempel: in einer
    -- Transaktion tragen alle Sitzungen dasselbe now()).
    perform set_config('lsat.sitzungen', (coalesce(nullif(current_setting('lsat.sitzungen', true), ''), '{}')::jsonb
                                          || jsonb_build_object(k ->> 'kind', v_s))::text, false);

    v_i := 0;
    loop
      -- Die offene Aufgabe, wie platz_next sie liest.
      select t.* into v_task
        from lsa_ausgegeben a join tasks t on t.id = a.task_id
       where a.session_id = v_s
         and not exists (select 1 from lsa_responses r where r.session_id = v_s and r.task_id = a.task_id)
       order by a.ausgegeben_am
       limit 1;
      exit when not found;
      v_i := v_i + 1;
      if v_i > 200 then
        raise exception 'LSA-T: % — mehr als 200 Aufgaben, Abbruch', k ->> 'kind';
      end if;
      select * into v_sol from task_solutions where task_id = v_task.id;

      -- Zustand laut Profil: Ausnahme, sonst Grundstand der Klassenstufe.
      v_zust := coalesce(k -> 'ausnahmen' ->> v_task.skill_key,
                         k -> 'grund' ->> (select case when s.klasse_herkunft <= 6 then '56'
                                                       when s.klasse_herkunft <= 8 then '78' else '910' end
                                             from skills s where s.skill_key = v_task.skill_key),
                         k -> 'grund' ->> '78');
      -- teilweise: die erste Aufgabe zum Skill richtig, der Zweitbeleg falsch.
      if v_zust = 'teilweise' then
        v_zust := case when exists (select 1 from lsa_responses r join tasks t on t.id = r.task_id
                                     where r.session_id = v_s and t.skill_key = v_task.skill_key)
                       then 'uebung' else 'sicher' end;
      end if;

      if v_zust = 'nicht_angesetzt' then
        v_resp := '{"dont_know": true}';
      else
        -- Je Teil (flach: ein Teil ohne Nummer) die richtige Antwort; bei uebung wird ein Teil falsch.
        v_resp := '{}';
        v_falsch_nr := null;
        for v_teil in
          select p from jsonb_array_elements(case when v_task.input_type = 'MULTI_PART' then v_task.parts
                                                  else jsonb_build_array(jsonb_build_object('nr', null)) end) e(p)
        loop
          v_nr := v_teil ->> 'nr';
          if v_nr is null then
            v_typ   := v_task.input_type;
            v_kind  := lower(v_task.input_type);
            v_richt := v_sol.correct_answers;
            v_ke    := v_sol.acceptance -> 'known_errors';
            v_hint  := public.lsa_input_hint(v_task.input_type, v_task.bruch, v_sol.correct_answers, v_task.unit);
          else
            v_typ   := case when v_teil ->> 'kind' = 'mc' then 'MC'
                            when v_teil ->> 'input_type' = 'TERM' then 'TERM' else 'SHORT_TEXT' end;
            v_kind  := lower(v_typ);
            v_richt := coalesce(v_sol.correct_answers -> v_nr, '[]');
            v_ke    := v_sol.acceptance -> v_nr -> 'known_errors';
            v_hint  := public.lsa_teil_input_hint(v_teil, v_richt);
          end if;

          v_falsch := null;
          if v_zust = 'uebung' and v_falsch_nr is null then
            -- 1. ein hinterlegtes Fehlbild: erst die Slugs des Kindes, dann seine Familie, dann beschriftete,
            --    dann unbeschriftete (known_errors als Liste). Nie ein Wert, der als richtig zählt — weder für
            --    correct (lsa_antwort_korrekt) noch, bei flachen Aufgaben, für das Urteil (lsa_grade mit Toleranz).
            select x.wert into v_falsch
              from (select ke.key as wert, ke.value #>> '{}' as slug
                      from jsonb_each(case when jsonb_typeof(v_ke) = 'object' then v_ke else '{}' end) ke
                    union all
                    select w, null from jsonb_array_elements_text(case when jsonb_typeof(v_ke) = 'array' then v_ke
                                                                       else '[]' end) w) x
              left join fehlbild_labels fl on fl.slug = x.slug
             where not coalesce(public.lsa_antwort_korrekt(v_typ, v_hint, v_richt,
                         case when v_kind = 'mc' then jsonb_build_object('selected', jsonb_build_array(x.wert))
                              else jsonb_build_object('text', x.wert) end), false)
               and (v_nr is not null or v_kind = 'mc'
                    or coalesce(public.lsa_grade(v_typ, v_sol.acceptance, v_richt, jsonb_build_object('text', x.wert),
                                                 v_hint), 'nicht') <> 'voll')
             order by coalesce(array_position(array(select jsonb_array_elements_text(k -> 'fehlbilder')), x.slug), 99),
                      (fl.familie is not distinct from (k ->> 'familie') and fl.familie is not null) desc,
                      (x.slug is not null) desc, (fl.familie is not null) desc, x.wert
             limit 1;
            -- 2. sonst plausibel falsch: MC eine andere Option, Zahl + 1, sonst „+ 1“ angehängt.
            if v_falsch is null and v_kind = 'mc' then
              select o ->> 'id' into v_falsch
                from jsonb_array_elements(coalesce(case when v_nr is null then v_task.question_payload -> 'options'
                                                        else v_teil -> 'options' end, '[]')) o
               where not (v_richt ? (o ->> 'id'))
               order by o ->> 'id' limit 1;
            elsif v_falsch is null then
              v_wert := v_richt ->> 0;
              v_falsch := case
                when v_wert ~ '^\s*[+−–-]?\s*[0-9]+([.,][0-9]+)?\s*$' then
                  replace((replace(regexp_replace(translate(v_wert, '−–', '--'), '[\s+]', '', 'g'), ',', '.')::numeric
                           + 1)::text, '.', ',')
                else v_wert || ' + 1' end;
            end if;
            if v_falsch is not null then
              v_falsch_nr := coalesce(v_nr, '-');
            end if;
          end if;

          v_antw := case
            when v_falsch is not null and v_kind = 'mc' then jsonb_build_object('selected', jsonb_build_array(v_falsch))
            when v_falsch is not null then jsonb_build_object('text', v_falsch)
            when v_kind = 'mc' then jsonb_build_object('selected', v_richt)
            else jsonb_build_object('text', v_richt ->> 0) end;
          v_resp := case when v_nr is null then v_antw else v_resp || jsonb_build_object(v_nr, v_antw) end;
        end loop;
      end if;

      v_dauer := round((k ->> 'sekunden')::numeric * 1000 * c_muster[1 + (v_i - 1) % array_length(c_muster, 1)]
                       * case when v_zust = 'nicht_angesetzt' then 0.5 else 1 end);
      v_t := v_t + make_interval(secs => v_dauer / 1000.0);
      perform public.lsa_submit(v_s, v_task.id, v_resp, v_dauer, v_t);
    end loop;

    perform public.lsa_finish(v_s);
  end loop;
end $$;

-- ── 3. Bericht des Laufs ─────────────────────────────────────────────────────────────────────────
-- Je Kind die Sitzung dieses Laufs (= die neueste). sicher und Übungsbedarf zählen direkt geprüfte Bereiche
-- (Übungsbedarf = traegt_nicht + traegt_teilweise, ohne Ansatz = nicht_angesetzt).
-- Abweichungen vom Profil (etwa eine richtige Antwort, die die Wertung nicht annimmt) als NOTICE.
do $$
declare
  k     jsonb;
  v_s   uuid;
  v_abw text;
begin
  for k in select * from jsonb_array_elements(current_setting('lsat.kinder')::jsonb) loop
    v_s := (current_setting('lsat.sitzungen')::jsonb ->> (k ->> 'kind'))::uuid;
    select string_agg(u.skill_key || ' ' || u.zustand || ' statt ' || p.soll, ', ' order by u.skill_key) into v_abw
      from lsa_skill_urteil u
      join skills s on s.skill_key = u.skill_key
      cross join lateral (select coalesce(k -> 'ausnahmen' ->> u.skill_key,
                                          k -> 'grund' ->> case when s.klasse_herkunft <= 6 then '56'
                                                                when s.klasse_herkunft <= 8 then '78' else '910' end) as soll) p
     where u.session_id = v_s and u.belegt_direkt and u.zustand <> 'ungeprueft'
       and u.zustand <> all (case p.soll when 'sicher' then array['traegt']
                                         when 'uebung' then array['traegt_nicht']
                                         when 'teilweise' then array['traegt', 'traegt_teilweise']
                                         else array['nicht_angesetzt'] end);
    raise notice 'LSA-T % (%): Sitzung %, Profil grund=% ausnahmen=% familie=%; Abweichungen: %',
      k ->> 'kind', k ->> 'thema', v_s, k -> 'grund', k -> 'ausnahmen', coalesce(k ->> 'familie', '–'),
      coalesce(v_abw, 'keine');
  end loop;
end $$;

with kind as (
  select e.ord, e.k, (current_setting('lsat.sitzungen')::jsonb ->> (e.k ->> 'kind'))::uuid as sid
    from jsonb_array_elements(current_setting('lsat.kinder')::jsonb) with ordinality e(k, ord)
)
select k ->> 'name'                                                    as "Kind",
       (k ->> 'klasse')::int                                           as "Klasse",
       th.label                                                        as "Thema",
       ls.id                                                           as "Sitzung",
       ls.status                                                       as "Status",
       (select count(distinct r.task_id) from lsa_responses r where r.session_id = ls.id) as "Aufgaben gesamt",
       (select count(distinct r.task_id) from lsa_responses r join tasks t on t.id = r.task_id
         where r.session_id = ls.id and t.status = 'ready')            as "davon ready",
       (select count(*) from lsa_skill_urteil u where u.session_id = ls.id and u.belegt_direkt
           and u.zustand = 'traegt')                                   as "sicher",
       (select count(*) from lsa_skill_urteil u where u.session_id = ls.id and u.belegt_direkt
           and u.zustand in ('traegt_nicht', 'traegt_teilweise'))      as "Übungsbedarf",
       (select count(*) from lsa_skill_urteil u where u.session_id = ls.id and u.belegt_direkt
           and u.zustand = 'nicht_angesetzt')                          as "ohne Ansatz",
       coalesce((select string_agg(f.slug || ' ×' || f.n, ', ' order by f.n desc, f.slug)
                   from (select r.fehlbild_slug as slug, count(*) as n from lsa_responses r
                          where r.session_id = ls.id and r.fehlbild_slug is not null group by 1) f), '–') as "Fehlbilder",
       '/admin/report/' || ls.id || '?fassung=r7'                      as "Report-Pfad"
  from kind
  join lsa_sessions ls on ls.id = kind.sid
  left join themen th on th.thema_key = ls.thema_key
 order by kind.ord;
