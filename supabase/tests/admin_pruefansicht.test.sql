-- ============================================================================
-- Admin-Pruefansicht (Migrationen 20261005131059, 20261005131220, 20261005131306).
-- Rechte der neuen Funktionen, Admin-Zweig in pruef_sperren, Freigabe-Sperre bei beanstandet,
-- Sammelaktionen mit Vorschau, Ausschluss von Hand, Zurueck an Lena, Admin-Protokoll.
-- Eigene Fixtures (Quelle 'ap_test'), alles in einer Transaktion, am Ende rollback.
--
-- Lauf: npx supabase test db
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(66);

-- --- Fixtures --------------------------------------------------------------
\set admin_uid   '1c000000-0000-4000-8000-00000000000a'
\set lena_uid    '1c000000-0000-4000-8000-00000000000b'
\set student_uid '1c000000-0000-4000-8000-00000000000d'
\set parent_uid  '1c000000-0000-4000-8000-00000000000e'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid',   'ap-admin@test.local',   '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'lena_uid',    'ap-lena@test.local',    '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'student_uid', 'ap-student@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'parent_uid',  'ap-parent@test.local',  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');

insert into profiles (id, email, role, full_name, darf_pruefen) values
  (:'admin_uid',   'ap-admin@test.local',   'admin',   'AP Admin',   false),
  (:'lena_uid',    'ap-lena@test.local',    'coach',   'AP Lena',    true),
  (:'student_uid', 'ap-student@test.local', 'student', 'AP Schueler', false),
  (:'parent_uid',  'ap-parent@test.local',  'parent',  'AP Eltern',  false);
insert into parent_student (parent_id, student_id) values (:'parent_uid', :'student_uid');
-- Der Pilot laeuft (wie in Prod): Lena sieht nur markierte Aufgaben.
update pruef_einstellungen set nur_pilot = true;

-- Eine vollstaendige Kreis-Aufgabe (Gate erfuellt), wahlweise im Pilot, mit Status und Quelle.
create function pg_temp.aufgabe(p_ref text, p_status text default 'draft', p_pilot boolean default true,
                                p_quelle text default 'ap_test')
returns uuid language plpgsql as $$
declare v uuid;
begin
  insert into tasks (content_type, input_type, title, question, afb, cluster_id, curriculum_grade,
                     skill_key, sondierrang, source, source_ref, status, pruef_pilot)
  values ('exercise', 'NUMERIC', 'AFB II · ' || p_ref, 'Ein Kreis hat den Radius 3,6 m. Wie groß ist sein Umfang?',
          'II', (select id from skill_clusters order by id limit 1), 9, 'geo_kreis_umfang', 3,
          p_quelle, p_ref, p_status, p_pilot)
  returning id into v;
  insert into task_solutions (task_id, correct_answers, acceptance, solution)
  values (v, '["22,62", "22.62"]', '{"canonical": "22,62", "equivalents": ["22.62"], "known_errors": {"7,2": "pi_vergessen"}}',
          'U = 2 · π · 3,6 m ≈ 22,62 m');
  return v;
end $$;

-- Lenas letzte Entscheidung als Protokollzeile (wie pruef_entscheiden sie schreibt).
create function pg_temp.lena(p_id uuid, p_entscheidung text, p_aenderungen jsonb default '[]')
returns void language sql as $$
  insert into task_pruefungen (task_id, entscheidung, aenderungen, geprueft_von, geprueft_am)
  values (p_id, p_entscheidung, p_aenderungen, '1c000000-0000-4000-8000-00000000000b', clock_timestamp())
$$;

select pg_temp.aufgabe('ap-ausserhalb', p_pilot => false) as ausserhalb \gset
select pg_temp.aufgabe('ap-team') as team \gset
select pg_temp.aufgabe('ap-frei', 'review') as frei \gset
select pg_temp.aufgabe('ap-geaendert', 'review') as geaendert \gset
select pg_temp.aufgabe('ap-rueckfrage', 'rueckfrage') as rueckfrage \gset
select pg_temp.aufgabe('ap-vera', 'review', p_quelle => 'VERA8_IQB') as vera \gset
select pg_temp.aufgabe('ap-fert', 'review') as fert \gset
select pg_temp.aufgabe('ap-hand') as hand \gset
select pg_temp.aufgabe('ap-anlena') as anlena \gset
select pg_temp.aufgabe('ap-offen') as offen \gset
select pg_temp.aufgabe('ap-bremse', p_pilot => false) as bremse \gset
select pg_temp.aufgabe('ap-pilot1', p_pilot => false) as pilot1 \gset
select pg_temp.aufgabe('ap-pilot2', p_pilot => false) as pilot2 \gset
select pg_temp.lena(:'frei', 'passt');
select pg_temp.lena(:'geaendert', 'passt', '[{"feld": "anforderungsbereich", "teil": null, "vorher": "I", "nachher": "II"}]');
select pg_temp.lena(:'rueckfrage', 'unsicher');
select pg_temp.lena(:'vera', 'passt');
select pg_temp.lena(:'fert', 'passt');

-- Fertigkeiten: eine erlaubte (Thema oder Voraussetzung), eine fremde.
select o ->> 'key' as erlaubt from jsonb_array_elements(public.pruef_fertigkeit_optionen('geo_kreis_umfang')) o
 where o ->> 'key' <> 'geo_kreis_umfang' order by o ->> 'key' limit 1 \gset
select skill_key as fremd from skill_thema where thema_key <> 'kreis'
   and skill_key not in (select voraussetzt_skill_key from skill_kante where skill_key = 'geo_kreis_umfang')
 order by skill_key limit 1 \gset

create function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;
create function pg_temp.v(p_id uuid) returns bigint language sql as $$
  select pruef_version from tasks where id = p_id
$$;
create function pg_temp.fehler(p_sql text) returns text language plpgsql as $$
declare s text; h text;
begin
  execute p_sql;
  return 'kein Fehler';
exception when others then
  get stacked diagnostics s = returned_sqlstate, h = pg_exception_hint;
  return s || ':' || coalesce(h, '');
end $$;
create function pg_temp.status(p_id uuid) returns text language sql as $$ select status from tasks where id = p_id $$;
create function pg_temp.protokoll(p_id uuid, p_aktion text) returns bigint language sql as $$
  select count(*) from task_admin_protokoll where task_id = p_id and aktion = p_aktion
$$;
create function pg_temp.grund(p_ergebnis jsonb, p_id uuid) returns text language sql as $$
  select a ->> 'grund' from jsonb_array_elements(p_ergebnis -> 'ausgelassen') a where (a ->> 'task_id')::uuid = p_id
$$;

-- ============================================================================
-- 1 · Coach mit Pruefrecht: keine Admin-Funktion
-- ============================================================================
select pg_temp.act_as(:'lena_uid');
select is(pg_temp.fehler(format('select public.pruef_sammel(%L, array[%L]::uuid[], %L, true)', 'pilot_an', :'frei', '{}')),
  '42501:', '1: Lena → pruef_sammel 42501');
select is(pg_temp.fehler(format('select public.pruef_an_lena(%L)', :'frei')), '42501:', '1: Lena → pruef_an_lena 42501');
select is(pg_temp.fehler(format('select public.pruef_admin_freigeben(%L)', :'frei')), '42501:',
  '1: Lena → pruef_admin_freigeben 42501');
select is(pg_temp.fehler(format('select public.pruef_admin_zurueckweisen(%L, %L)', :'frei', '{formulierung}')), '42501:',
  '1: Lena → pruef_admin_zurueckweisen 42501');
select is(pg_temp.fehler(format('select public.pruef_freigabe_zuruecknehmen(%L)', :'frei')), '42501:',
  '1: Lena → pruef_freigabe_zuruecknehmen 42501');
select is(pg_temp.fehler('select * from public.pruef_admin_liste()'), '42501:', '1: Lena → pruef_admin_liste 42501');

-- ============================================================================
-- 2 · Admin speichert ausserhalb des Piloten und bei Team-Beanstandung; Lena nicht
-- ============================================================================
select pg_temp.act_as(:'admin_uid');
select is(public.pruef_admin_zurueckweisen(:'team', '{didaktisch}', 'Bitte mit x umbauen') ->> 'status', 'beanstandet',
  '2: Admin weist zurueck → beanstandet');
select ok(public.pruef_team_beanstandet(:'team'), '2: die Aufgabe gilt als vom Team beanstandet');
select is((select count(*) from task_reviews where task_id = :'team' and kategorie = 'didaktisch' and geprueft_von = :'admin_uid'),
  1::bigint, '2: je Grund eine task_reviews-Zeile vom Admin');
select is(pg_temp.protokoll(:'team', 'zurueckweisen'), 1::bigint, '2: Protokoll zurueckweisen');

select pg_temp.act_as(:'lena_uid');
select is(pg_temp.fehler(format('select public.pruef_speichern(%L, %s, %L)', :'ausserhalb', pg_temp.v(:'ausserhalb'), '{"afb": "I"}')),
  'ED422:ausgeschlossen', '2: Lena ausserhalb des Piloten → ED422 ausgeschlossen (wie bisher)');
select is(pg_temp.fehler(format('select public.pruef_speichern(%L, %s, %L)', :'team', pg_temp.v(:'team'), '{"afb": "I"}')),
  'ED422:team_beanstandet', '2: Lena bei Team-Beanstandung → ED422 team_beanstandet (wie bisher)');
select ok(public.pruef_aufgabe(:'ausserhalb') ->> 'ausgang' is null, '2: Lena legt ausserhalb des Piloten keine Ausgangsfassung an');

select pg_temp.act_as(:'admin_uid');
select ok(public.pruef_aufgabe(:'ausserhalb') ->> 'ausgang' is not null,
  '2: Admin oeffnet ausserhalb des Piloten → Ausgangsfassung angelegt');
select ok((public.pruef_speichern(:'ausserhalb', pg_temp.v(:'ausserhalb'), '{"afb": "I"}') ->> 'pruef_version') is not null,
  '2: Admin speichert ausserhalb des Piloten');
select is((select afb from tasks where id = :'ausserhalb'), 'I', '2: AFB geschrieben');
select ok((public.pruef_speichern(:'team', pg_temp.v(:'team'), '{"afb": "III"}') ->> 'pruef_version') is not null,
  '2: Admin speichert eine vom Team beanstandete Aufgabe');
select is(jsonb_array_length(public.pruef_aufgabe(:'team') -> 'aenderungen'), 1,
  '2: Admin-Aenderung erscheint gegen die Ausgangsfassung');
select is(pg_temp.fehler(format('select public.pruef_speichern(%L, %s, %L)', :'vera', pg_temp.v(:'vera'), '{"afb": "I"}')),
  'ED422:ausgeschlossen', '2: VERA8 bleibt auch fuer admin gesperrt');

-- ============================================================================
-- 3 · task_status_set(ready) bei beanstandet
-- ============================================================================
select is(pg_temp.fehler(format('select public.task_status_set(%L, %L)', :'team', 'ready')), 'ED422:erst_an_lena',
  '3: task_status_set(ready) bei beanstandet → ED422 erst_an_lena');
select is(pg_temp.fehler(format('select public.pruef_admin_freigeben(%L)', :'team')), 'ED422:erst_an_lena',
  '3: pruef_admin_freigeben bei beanstandet → ED422 erst_an_lena');
select is(pg_temp.fehler(format('select public.task_status_set(%L, %L)', :'team', 'review')), 'ED422:erst_an_lena',
  '3: auch der Umweg ueber review ist gesperrt');
select is(pg_temp.fehler(format('select public.pruef_entscheiden(%L, %s, %L)', :'team', pg_temp.v(:'team'), 'passt')),
  'ED422:team_beanstandet', '3: Admin kann nicht ueber Lenas Entscheidung (Passt) an der Beanstandung vorbei');
select is(pg_temp.fehler(format('select public.pruef_entscheiden(%L, %s, %L)', :'ausserhalb', pg_temp.v(:'ausserhalb'), 'passt')),
  'ED422:ausgeschlossen', '3: Lenas Entscheidung bleibt auch fuer admin an den Piloten gebunden');

-- ============================================================================
-- 4 · Sammelfreigabe: Vorschau schreibt nichts, Ausfuehrung genau 1
-- ============================================================================
select public.pruef_sammel('freigeben', array[:'frei', :'geaendert', :'rueckfrage', :'vera']::uuid[], '{}', true) as vorschau \gset
select is((:'vorschau'::jsonb) -> 'betrifft', jsonb_build_array(:'frei'), '4: Vorschau betrifft genau die freigebbare');
select is(pg_temp.grund(:'vorschau', :'geaendert'), 'geaendert', '4: geaendert ausgelassen');
select is(pg_temp.grund(:'vorschau', :'rueckfrage'), 'rueckfrage_offen', '4: Rueckfrage ausgelassen');
select is(pg_temp.grund(:'vorschau', :'vera'), 'vera8', '4: VERA8 ausgelassen');
select is(pg_temp.status(:'frei'), 'review', '4: nach der Vorschau ist nichts freigegeben');
select is((select count(*) from task_admin_protokoll where task_id in (:'frei', :'geaendert', :'rueckfrage', :'vera')),
  0::bigint, '4: nach der Vorschau kein Protokoll');
select is(jsonb_array_length(public.pruef_sammel('freigeben', array[:'frei', :'geaendert', :'rueckfrage', :'vera']::uuid[], '{}', false)
  -> 'betrifft'), 1, '4: Ausfuehrung betrifft 1');
select results_eq(format($q$select status from tasks where id in (%L, %L, %L, %L) order by source_ref$q$,
                         :'frei', :'geaendert', :'rueckfrage', :'vera'),
  $$values ('ready'), ('review'), ('rueckfrage'), ('review')$$, '4: genau eine Aufgabe ready');
select ok((select reviewed_by = :'admin_uid' from tasks where id = :'frei'), '4: Freigabe gestempelt');
select is((select count(*) from task_admin_protokoll where task_id = :'frei' and aktion = 'freigeben' and sammel),
  1::bigint, '4: Protokoll freigeben mit sammel = true');

-- ============================================================================
-- 5 · Fertigkeit per Sammelaktion
-- ============================================================================
select is(pg_temp.grund(public.pruef_sammel('fertigkeit', array[:'fert']::uuid[], jsonb_build_object('skill_key', :'fremd'), false), :'fert'),
  'nicht_erlaubt', '5: fremde Fertigkeit → nicht_erlaubt');
select is(pg_temp.fehler(format('select public.pruef_sammel(%L, array[%L]::uuid[], %L, true)', 'fertigkeit', :'fert', '{}')),
  'ED422:wert_fehlt', '5: ohne Fertigkeit → ED422 wert_fehlt');
select is(public.pruef_sammel('fertigkeit', array[:'fert']::uuid[], jsonb_build_object('skill_key', :'erlaubt', 'grund', 'Thema passt besser'), false)
  -> 'betrifft', jsonb_build_array(:'fert'), '5: erlaubte Fertigkeit → betroffen');
select results_eq(format('select skill_key, sondierrang from tasks where id = %L', :'fert'),
  format('values (%L::text, null::int)', :'erlaubt'), '5: skill_key gesetzt, sondierrang leer');
select ok((select a.ausgang ->> 'skill_key' = 'geo_kreis_umfang' from task_pruefung_ausgang a where a.task_id = :'fert'),
  '5: Ausgangsfassung vorher gesichert');
select is((select aenderungen -> 0 ->> 'feld' from task_admin_protokoll where task_id = :'fert' and aktion = 'fertigkeit' and sammel),
  'fertigkeit', '5: Protokoll mit vorher → nachher');
select is(pg_temp.grund(public.pruef_sammel('freigeben', array[:'fert']::uuid[], '{}', true), :'fert'), 'geaendert',
  '5: danach laesst die Sammelfreigabe sie mit geaendert aus');
select is(pg_temp.grund(public.pruef_sammel('afb', array[:'fert']::uuid[], '{"afb": "II"}', true), :'fert'), 'schon_gesetzt',
  '5: AFB unveraendert → schon_gesetzt');

-- ============================================================================
-- 6 · Aus Lenas Liste nehmen und wieder aufnehmen
-- ============================================================================
select is(pg_temp.fehler(format('select public.pruef_sammel(%L, array[%L]::uuid[], %L, false)', 'ausschliessen', :'hand', '{}')),
  'ED422:grund_fehlt', '6: ausschliessen ohne Grund → ED422 grund_fehlt');
select is(public.pruef_sammel('ausschliessen', array[:'hand']::uuid[], '{"grund": "wird neu geschrieben"}', false) -> 'betrifft',
  jsonb_build_array(:'hand'), '6: mit Grund → betroffen');
select is(public.pruef_ausschluss(:'hand'), 'hand', '6: pruef_ausschluss = hand');
select is((select ausschluss_grund from public.pruef_admin_liste() where task_id = :'hand'), 'wird neu geschrieben',
  '6: pruef_admin_liste gibt den Grund aus');
select is(pg_temp.grund(public.pruef_sammel('ausschliessen', array[:'hand']::uuid[], '{"grund": "x"}', true), :'hand'),
  'schon_ausgeschlossen', '6: zweites Mal → schon_ausgeschlossen');
select pg_temp.act_as(:'lena_uid');
select is((select count(*) from public.pruef_board() where task_id = :'hand'), 0::bigint, '6: fehlt in Lenas Board');
select is(pg_temp.fehler(format('select public.pruef_speichern(%L, %s, %L)', :'hand', pg_temp.v(:'hand'), '{"afb": "I"}')),
  'ED422:ausgeschlossen', '6: Lena-pruef_sperren → ausgeschlossen');
select pg_temp.act_as(:'admin_uid');
select is(pg_temp.grund(public.pruef_sammel('aufnehmen', array[:'offen']::uuid[], '{}', true), :'offen'), 'schon_drin',
  '6: aufnehmen ohne Ausschluss → schon_drin');
select is(public.pruef_sammel('aufnehmen', array[:'hand']::uuid[], '{}', false) -> 'betrifft', jsonb_build_array(:'hand'),
  '6: aufnehmen → betroffen');
select pg_temp.act_as(:'lena_uid');
select is((select count(*) from public.pruef_board() where task_id = :'hand'), 1::bigint, '6: wieder in Lenas Board');
select pg_temp.act_as(:'admin_uid');
update task_solutions set correct_answers = '[]' where task_id = :'offen';
select is(public.pruef_sammel('ausschliessen', array[:'offen']::uuid[], '{}', true) -> 'betrifft', jsonb_build_array(:'offen'),
  '6: eine berechnet ausgeschlossene Aufgabe (ohne Loesung) laesst sich von Hand herausnehmen');
update task_solutions set correct_answers = '["22,62", "22.62"]' where task_id = :'offen';

-- ============================================================================
-- 7 · Zurueck an Lena aus beanstandet
-- ============================================================================
select pg_temp.act_as(:'lena_uid');
select is(public.pruef_entscheiden(:'anlena', pg_temp.v(:'anlena'), 'passt_nicht', '{aufgabe_fehlerhaft}', 'Hinterlegt ist 3') ->> 'lena_status',
  'passt_nicht', '7: Lena: Passt nicht');
select pg_temp.act_as(:'admin_uid');
select is(public.pruef_an_lena(:'anlena', 'Ist korrigiert, bitte nochmal ansehen') ->> 'status', 'draft', '7: an Lena → draft');
select is(pg_temp.status(:'anlena'), 'draft', '7: Status draft');
select is((select count(*) from task_pruefung_ausgang where task_id = :'anlena'), 0::bigint, '7: Ausgangsfassung geloescht');
select results_eq(format($q$select antwort, beantwortet_von from task_pruefungen where task_id = %L
                             order by geprueft_am desc limit 1$q$, :'anlena'),
  format($q$values ('Ist korrigiert, bitte nochmal ansehen'::text, %L::uuid)$q$, :'admin_uid'),
  '7: Nachricht in der juengsten task_pruefungen-Zeile');
select is(pg_temp.protokoll(:'anlena', 'an_lena'), 1::bigint, '7: Protokoll an_lena');
select is(pg_temp.grund(public.pruef_sammel('an_lena', array[:'anlena', :'offen']::uuid[], '{}', true), :'anlena'), 'schon_offen',
  '7: danach ist sie schon offen und unbewertet');

-- ============================================================================
-- 8 · Schueler und Eltern lesen nichts aus den neuen Tabellen
-- ============================================================================
set local role authenticated;
select pg_temp.act_as(:'student_uid');
select is((select count(*) from task_admin_protokoll) + (select count(*) from task_pruef_ausschluss), 0::bigint,
  '8: Schueler liest keine Zeile');
select pg_temp.act_as(:'parent_uid');
select is((select count(*) from task_admin_protokoll) + (select count(*) from task_pruef_ausschluss), 0::bigint,
  '8: Eltern lesen keine Zeile');
select pg_temp.act_as(:'lena_uid');
select is((select count(*) from task_admin_protokoll), 0::bigint, '8: Lena liest das Admin-Protokoll nicht');
select pg_temp.act_as(:'admin_uid');
select ok((select count(*) from task_admin_protokoll) > 0, '8: Admin liest das Protokoll');
reset role;

-- ============================================================================
-- 9 · Fehler bei einer Aufgabe: sie wird ausgelassen, die anderen geschrieben
-- ============================================================================
create function public.ap_test_bremse() returns trigger language plpgsql as $$
begin
  if new.source_ref = 'ap-bremse' then raise exception 'Bremse fuer den Test'; end if;
  return new;
end $$;
create trigger ap_test_bremse before update on tasks for each row execute function public.ap_test_bremse();
select pg_temp.act_as(:'admin_uid');
select public.pruef_sammel('pilot_an', array[:'pilot1', :'bremse', :'pilot2']::uuid[], '{}', false) as neun \gset
select is(pg_temp.grund(:'neun', :'bremse'), 'fehler', '9: die Aufgabe mit Fehler ist ausgelassen');
select results_eq(format($q$select source_ref, pruef_pilot from tasks where id in (%L, %L, %L) order by source_ref$q$,
                         :'pilot1', :'bremse', :'pilot2'),
  $$values ('ap-bremse'::text, false), ('ap-pilot1', true), ('ap-pilot2', true)$$, '9: die anderen sind geschrieben');

select * from finish();
rollback;
