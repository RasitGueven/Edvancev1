-- C3: Coach-Beispiele (echtes JSON) fuer Vitest und Bildschirmfotos der Schublade (Pfad-Vorschlag, Heute,
-- Grund mit Zahl, Erklaersequenz, Warm-up-Beleg). Erzeugt src/lib/session/coachLiveFixturesC3.json.
--
-- Nur fuer eine Wegwerf-DB (alle Migrationen + supabase/seed.sql), nie gegen Produktion. Laeuft in
-- begin … rollback und legt alle Daten selbst an; Namen und Labels sind fiktiv. Aufruf aus dem Repo-Wurzelverzeichnis:
--
--   PGOPTIONS='-c search_path=public,extensions' psql -X -q -t -A -v ON_ERROR_STOP=1 -d <wegwerf-db> \
--     -f docs/session/c3-coach-beispiele.sql | sed -n '/^{/,/^}$/p' > src/lib/session/coachLiveFixturesC3.json
\set QUIET on
begin;
\ir ../../supabase/tests/session_a2_fixture.sql
-- Fiktive, lesbare Labels statt der Test-Praefixe.
update skills set label = v.l from (values ('zz_a2_v1', 'Minus vor der Klammer'), ('zz_a2_v2', 'Proportionale Zuordnung'),
  ('zz_a2_s1', 'Klammern ausmultiplizieren'), ('zz_a2_s2', 'Ausklammern'), ('zz_a2_n1', 'Steigung')) v(k, l)
 where skill_key = v.k;
update themen set label = v.l from (values ('zz_a2_terme', 'Terme und Gleichungen'), ('zz_a2_linear', 'Lineare Funktionen'),
  ('zz_a2_basis', 'Grundlagen')) v(k, l) where thema_key = v.k;
insert into skill_pruefung (skill_key, frage, erwartung, kriterium, status, quelle) values
  ('zz_a2_v1', 'Rechne −(3x − 5) aus und erklär mir, was mit jedem Vorzeichen passiert.',
   'Jedes Vorzeichen in der Klammer dreht sich: −3x + 5.', 'Richtig gerechnet und den Weg ohne Hilfe erklärt', 'freigegeben', 'mensch');
insert into fehlbild_labels (slug, klartext, freigegeben_am) values ('zz_c3_vz', 'Nur das erste Vorzeichen geändert', now());
update task_solutions set acceptance = '{"canonical":"7","known_errors":{"0":"zz_c3_vz"}}'
 where task_id in (select id from tasks where skill_key in ('zz_a2_v1', 'zz_a2_v2') or source_ref like 'a2-check-%');

-- Zweite Kernidee und Variante B fuer die Steigung (wie session_c3.test.sql 1X).
select pg_temp.aufgaben('zz_a2_n1', 1, 'ready', '{check}', 'c3-check');
update task_solutions set acceptance = '{"canonical":"7","known_errors":{"0":"zz_c3_vz"}}'
 where task_id in (select id from tasks where source_ref like 'c3-check-%');
select pg_temp.act_as(:'admin');
update erklaer_kernidee set titel = 'Steigung pro Schritt nach rechts' where skill_key = 'zz_a2_n1' and nr = 1;
select public.erklaer_schritt_speichern(:'kern_n1', 'B', a.art, 'Variante B: ' || a.art, null, '{}')
  from (values ('erklaerung'), ('beispiel')) a(art);
select public.erklaer_kernidee_speichern(null, 'zz_a2_n1', 2, 'y-Achsenabschnitt ablesen', 'mensch') as kern_2 \gset
select public.erklaer_schritt_speichern(:'kern_2', 'A', a.art, 'Kernidee 2: ' || a.art, null, '{}')
  from (values ('erklaerung'), ('beispiel')) a(art);
select public.erklaer_check_setzen(:'kern_2', (select id from tasks where source_ref = 'c3-check-1'), 1);
do $$
declare r record;
begin
  for r in select s.id, s.kernidee_id, s.status from erklaer_schritt s join erklaer_kernidee k on k.id = s.kernidee_id
            where k.skill_key = 'zz_a2_n1' and s.status <> 'freigegeben' loop
    if r.status = 'entwurf' then
      perform public.erklaer_status_setzen('schritt', r.id, 'geprueft', (select pruef_version from erklaer_kernidee where id = r.kernidee_id));
    end if;
    perform public.erklaer_status_setzen('schritt', r.id, 'freigegeben', (select pruef_version from erklaer_kernidee where id = r.kernidee_id));
  end loop;
  for r in select id, status from erklaer_kernidee where skill_key = 'zz_a2_n1' and status <> 'freigegeben' loop
    if r.status = 'entwurf' then
      perform public.erklaer_status_setzen('kernidee', r.id, 'geprueft', (select pruef_version from erklaer_kernidee where id = r.id));
    end if;
    perform public.erklaer_status_setzen('kernidee', r.id, 'freigegeben', (select pruef_version from erklaer_kernidee where id = r.id));
  end loop;
end $$;
select set_config('request.jwt.claims', '', true);

select pg_temp.kind_mit('Emir Beispiel', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}') as k_e,
       pg_temp.kind_mit('Mila Beispiel', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}') as k_m,
       pg_temp.kind_mit('Jonas Beispiel', 'zz_a2_linear', '{zz_a2_v2}') as k_j,
       pg_temp.kind_mit('Lea Beispiel', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}') as k_l
\gset
-- Emir: dasselbe Fehlbild schon vor 9 Tagen.
insert into session_students (session_id, student_id) values (:'s_alt', :'k_e');
insert into session_antworten (session_id, student_id, task_id, versuch_nr, eingabe, ergebnis, fehlbild_slug, phase, zeit)
select :'s_alt', :'k_e', (select id from tasks where skill_key = sk order by source_ref desc limit 1), 1, '"0"', 'falsch',
       'zz_c3_vz', 'kern', now() - interval '9 days'
  from unnest(array['zz_a2_v1', 'zz_a2_v2']) sk;

create temp table aus (name text primary key, j jsonb);
create function pg_temp.zeig(p_name text, p_j jsonb) returns void language sql as $$
  insert into aus (name, j) values (p_name, p_j) $$;
create function pg_temp.szene(p_name text, p_s uuid, p_kinder uuid[]) returns void language plpgsql as $$
declare k uuid;
begin
  perform pg_temp.act_as('a2a2a2a2-0001-4000-8000-000000000002');
  perform pg_temp.zeig('raum_' || p_name, public.coach_raum_live(p_s));
  perform pg_temp.zeig('briefing_' || p_name, public.session_briefing(p_s));
  foreach k in array p_kinder loop
    perform pg_temp.zeig('detail_' || p_name || '_' || (select split_part(full_name, ' ', 1) from leads
                                                          where converted_student_id = k), public.coach_kind_detail(p_s, k));
  end loop;
  -- Fuer die Bildschirmfotos: Ziel der Stunde, Pruefgespraech und Lernpfad (wie ladeDetail in coachLive.ts).
  for k in select ss.student_id from session_students ss where ss.session_id = p_s loop
    perform pg_temp.zeig('ziel_' || k, coalesce((select jsonb_agg(to_jsonb(x)) from public.ziel_fertigkeiten(k,
      coalesce((select c.ziel_thema_key from session_checkin c where c.session_id = p_s and c.student_id = k),
               public.session_schulthema(k))) x), '[]'))
      where not exists (select 1 from aus where name = 'ziel_' || k);
    perform pg_temp.zeig('lernpfad_' || k, coalesce((select jsonb_agg(to_jsonb(l)) from lernpfad l where l.student_id = k), '[]'))
      where not exists (select 1 from aus where name = 'lernpfad_' || k);
  end loop;
end $$;

-- ── Szene warmup: Emir mit offenem Signal, Mila mit Kandidat, Jonas fertig mit dem Warm-up ─────────────
select pg_temp.neue_session(array[:'k_e', :'k_m', :'k_j']::uuid[], 6) as s \gset
select pg_temp.act_as(:'admin');
update coaching_sessions set room = 'Raum 1' where id = :'s';
select pg_temp.checkin(:'s', 1), pg_temp.checkin(:'s', 2), pg_temp.checkin(:'s', 3);
select pg_temp.act_as(:'coach_a');
select public.checkin_coach_setzen(:'s', :'k_j', 'schulthema') is not null;
select count(*) from (select pg_temp.loese(:'s', 1, n = 2) from generate_series(1, 4) n) x;
select count(*) from pg_temp.lauf(:'s', 2, 3, true);
-- Mila: nach dem Warm-up wird ein Warm-up-Skill Mastery-Kandidat (Signal mit dem naechsten Schritt).
update lernpfad set stand_system = 'kandidat', stand_coach = null
 where student_id = :'k_m' and skill_key = (select t.skill_key from session_antworten a join tasks t on t.id = a.task_id
                                             where a.session_id = :'s' and a.student_id = :'k_m' limit 1);
select pg_temp.schritt(:'s', 2) is not null;
select count(*) from pg_temp.lauf(:'s', 3, 3, true);
select pg_temp.szene('warmup', :'s', array[:'k_e', :'k_m']::uuid[]);

-- ── Szene kern: Emir beim Plan, drei Kernaufgaben und eine eingemischte; Jonas in der Erklaersequenz ──────
select pg_temp.act_as(:'coach_a');
select public.pfad_entscheiden(:'s', :'k_e', 'plan') is not null;
select pg_temp.uhr(:'s', 20);
select pg_temp.loese(:'s', 1, true) is not null, pg_temp.loese(:'s', 1, true, true) is not null,
       pg_temp.loese(:'s', 1, false) is not null, pg_temp.loese(:'s', 1, true) is not null;
select pg_temp.schritt_tablet(:'s', 3) ->> 'art';
select (public.erklaer_start(:'s', null, 'zz_a2_n1')) -> 'check' ->> 'task_id' as chk \gset
select public.erklaer_check_abgeben(:'s', null, :'chk', '{"text":"0"}') ->> 'aktion';
select pg_temp.szene('kern', :'s', array[:'k_e', :'k_j', :'k_m']::uuid[]);

-- ── Szene grund: Lea, ohne Mischen, fuenf Kernaufgaben falsch -> Fenster ausgewertet ──────────────────────
select pg_temp.stell('mischanteil', '0');
select pg_temp.neue_session(array[:'k_l']::uuid[], 1) as s_l \gset
select pg_temp.act_as(:'admin');
update coaching_sessions set room = 'Raum 2' where id = :'s_l';
select pg_temp.checkin(:'s_l', 1);
select pg_temp.act_as(:'coach_a');
select public.checkin_coach_setzen(:'s_l', :'k_l', 'schulthema') is not null;
select pg_temp.uhr(:'s_l', 20);
select count(*) from pg_temp.lauf(:'s_l', 1, 5, false);
select pg_temp.schritt(:'s_l', 1) is not null;
select pg_temp.szene('grund', :'s_l', array[:'k_l']::uuid[]);

-- ── Signal von vor A2d (ohne Zahlen) ───────────────────────────────────────────────────────────────────
reset role;
insert into session_ereignisse (session_id, student_id, typ, payload)
values (:'s_l', :'k_l', 'signal', '{"art": "entscheidung", "skill_key": "zz_a2_v2", "ziel_skill_key": "zz_a2_s1",
        "grund": "Entscheidung: eine Stufe tiefer?", "grund_code": "entscheidung_tiefer"}');
select pg_temp.act_as(:'coach_a');
select pg_temp.zeig('detail_alt_signal', public.coach_kind_detail(:'s_l', :'k_l'));

select pg_temp.zeig('pruefung_zz_a2_v1', (select jsonb_agg(to_jsonb(x)) from public.skill_pruefung_lesen('zz_a2_v1') x));

\unset QUIET
select jsonb_pretty(jsonb_object_agg(name, j)) from aus;
rollback;
