-- ============================================================================
-- Session-P1 Paket L6: Erklaersequenzen pruefen und freigeben (Tests 1 bis 7).
--
-- Fixture: session_e1_fixture.sql (Konten, Session mit Jonas, Steigung aus dem Graphen),
-- dazu ein eigener Skill fkt_l6_achsenabschnitt mit einer Kernidee im Entwurf (KI), Lena als
-- Coach mit Pruefrecht, ein Konto ohne Profil und zwei Check-Aufgaben (eine ready, eine draft).
-- Alles in einer Transaktion, am Ende rollback.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(61);

\ir session_e1_fixture.sql

\o /dev/null
\set lena_uid '16000000-0000-4000-8000-00000000001e'
\set ohne_uid '16000000-0000-4000-8000-0000000000ff'
insert into auth.users (id, email, instance_id, aud, role) values
  (:'lena_uid', 'l6-lena@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'ohne_uid', 'l6-ohne@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name, darf_pruefen) values
  (:'lena_uid', 'l6-lena@test.local', 'coach', 'Lena L6', true);

insert into skills (skill_key, label, klasse_herkunft, fundament_tiefe)
values ('fkt_l6_achsenabschnitt', 'L6 Achsenabschnitt ablesen', 8, 1);
insert into skill_thema (skill_key, thema_key)
select 'fkt_l6_achsenabschnitt', thema_key from themen order by klasse, thema_key limit 1;

insert into tasks (cluster_id, content_type, input_type, status, question, afb, competency_content,
                   est_duration_sec, class_level, source, source_ref, einsatz, skill_key)
select c.id, 'exercise', 'NUMERIC', q.st, q.frage, 'I', 'Funktionen', 120, 8, 'test', q.ref, '{check}',
       'fkt_l6_achsenabschnitt'
  from (select id from skill_clusters order by sort_order limit 1) c,
       (values ('l6-check-ready', 'ready', 'Wo schneidet y = 2x + 3 die y-Achse?'),
               ('l6-check-draft', 'draft', 'Wo schneidet y = -x + 1 die y-Achse?')) q(ref, st, frage);
select (select id from tasks where source_ref = 'l6-check-ready') as chk_ready,
       (select id from tasks where source_ref = 'l6-check-draft') as chk_draft
\gset
insert into task_solutions (task_id, correct_answers, solution, acceptance, hints) values
  (:'chk_ready', '["3"]', 'LOESUNG-L6', '{"canonical":"3","known_errors":{"2":"steigung_kehrwert"}}', '[]'),
  (:'chk_draft', '["1"]', 'LOESUNG-L6', '{"canonical":"1"}', '[]');

create or replace function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;
-- SQLSTATE:HINT eines Aufrufs (ok, wenn er durchlaeuft).
create or replace function pg_temp.fehler(q text) returns text language plpgsql as $$
declare s text; h text;
begin
  execute q;
  return 'ok';
exception when others then
  get stacked diagnostics s = returned_sqlstate, h = pg_exception_hint;
  return s || coalesce(':' || nullif(h, ''), '');
end $$;
create or replace function pg_temp.detail(q text) returns text language plpgsql as $$
declare d text;
begin
  execute q;
  return null;
exception when others then
  get stacked diagnostics d = pg_exception_detail;
  return d;
end $$;
create or replace function pg_temp.v(p_id uuid) returns bigint language sql as $$
  select pruef_version from erklaer_kernidee where id = p_id $$;

-- Die Kernidee entsteht wie in E2b als KI-Entwurf, Variante A mit einer Formel.
select pg_temp.act_as(:'admin_uid');
select erklaer_kernidee_speichern(null, 'fkt_l6_achsenabschnitt', 1, 'Achsenabschnitt: wo die Gerade die y-Achse schneidet', 'ki') as kid
\gset
select erklaer_schritt_speichern(:'kid', 'A', 'erklaerung', 'Bei $y = mx + b$ ist b der Achsenabschnitt.', null, '{}');
select erklaer_schritt_speichern(:'kid', 'A', 'beispiel', 'y = 2x + 3 schneidet die y-Achse bei 3.', null, '{}');
select erklaer_check_setzen(:'kid', :'chk_draft', 1);
\o

-- --- 1  Rechte ---------------------------------------------------------------------
select pg_temp.act_as(:'coach_uid');
select is(pg_temp.fehler(format('select erklaer_pruefen(%L, ''passt'', null, null, %s)', :'kid', pg_temp.v(:'kid'))),
          '42501', '1a Coach ohne Pruefrecht: erklaer_pruefen 42501');
select is(pg_temp.fehler('select * from erklaer_pruef_liste()'), '42501', '1b Coach ohne Pruefrecht: Liste 42501');
select is(pg_temp.fehler(format('select erklaer_pruef_detail(%L)', :'kid')), '42501', '1c Coach ohne Pruefrecht: Detail 42501');
select pg_temp.act_as(:'kind_uid');
select is(pg_temp.fehler(format('select erklaer_pruefen(%L, ''passt'', null, null, %s)', :'kid', pg_temp.v(:'kid'))),
          '42501', '1d Schuelerkonto: erklaer_pruefen 42501');
select is(pg_temp.fehler(format('select erklaer_freigeben(%L, %s)', :'kid', pg_temp.v(:'kid'))),
          '42501', '1e Schuelerkonto: erklaer_freigeben 42501');
select is(pg_temp.fehler(format('select erklaer_pruef_detail(%L)', :'kid')), '42501', '1f Schuelerkonto: Detail 42501');
select pg_temp.act_as(:'ohne_uid');
select is(pg_temp.fehler(format('select erklaer_pruefen(%L, ''passt'', null, null, %s)', :'kid', pg_temp.v(:'kid'))),
          '42501', '1g Konto ohne Profil: erklaer_pruefen 42501');
select is(pg_temp.fehler(format('select erklaer_freigeben(%L, %s)', :'kid', pg_temp.v(:'kid'))),
          '42501', '1h Konto ohne Profil: erklaer_freigeben 42501');
select is(pg_temp.fehler('select * from erklaer_pruef_liste()'), '42501', '1i Konto ohne Profil: Liste 42501');
select is(pg_temp.fehler(format('select erklaer_schritt_speichern(%L, ''B'', ''erklaerung'', ''x'', null, ''{}'')', :'kid')),
          '42501', '1j Konto ohne Profil: erklaer_schritt_speichern 42501');
select is(pg_temp.fehler(format('select erklaer_rueckfrage_beantworten(%L, ''x'')', :'kid')),
          '42501', '1k Konto ohne Profil: Rueckfrage beantworten 42501');

select pg_temp.act_as(:'lena_uid');
select is((select stand from erklaer_pruef_liste() where kernidee_id = :'kid'), 'offen', '1l Lena sieht die Kernidee als offen');
select is((select count(*)::int from erklaer_pruef_liste() l where l.kernidee_id = :'kid' and l.thema_key is not null),
          1, '1m Liste nennt das Thema des Skills');

-- --- 2  passt, passt_nicht -------------------------------------------------------------
select is(pg_temp.fehler(format('select erklaer_pruefen(%L, ''passt_nicht'', null, null, %s)', :'kid', pg_temp.v(:'kid'))),
          'ED422:grund_fehlt', '2a passt_nicht ohne Grund nicht moeglich');
select is(pg_temp.fehler(format('select erklaer_pruefen(%L, ''passt_nicht'', ''{aufgabe_unklar}'', null, %s)', :'kid', pg_temp.v(:'kid'))),
          'ED422:grund_unbekannt', '2b unbekannter Grund abgelehnt');
select is(pg_temp.fehler(format('select erklaer_pruefen(%L, ''passt_nicht'', ''{sonstiges}'', null, %s)', :'kid', pg_temp.v(:'kid'))),
          'ED422:notiz_fehlt', '2c sonstiges ohne Notiz abgelehnt');
select is(pg_temp.fehler(format('select erklaer_pruefen(%L, ''unsicher'', null, '' '', %s)', :'kid', pg_temp.v(:'kid'))),
          'ED422:notiz_fehlt', '2d unsicher ohne Frage abgelehnt');

select is((erklaer_pruefen(:'kid', 'passt_nicht', '{zu_lang,sprache_klassenstufe}', 'Beispiel zu knapp', pg_temp.v(:'kid'))) ->> 'stand',
          'passt_nicht', '2e passt_nicht mit Gruenden');
select is((select status from erklaer_kernidee where id = :'kid'), 'entwurf', '2f passt_nicht: Kernidee bleibt entwurf');
select is((select gruende from erklaer_pruefungen where kernidee_id = :'kid' order by id desc limit 1),
          '{sprache_klassenstufe,zu_lang}'::text[], '2g Gruende im Protokoll');

-- Lena bessert das Beispiel im Entwurf nach: Pflege schreibt vorher/nachher, der Stand wird wieder offen.
select ok(erklaer_schritt_speichern(:'kid', 'A', 'beispiel', 'y = 2x + 3 schneidet die y-Achse im Punkt (0|3).', null, '{steigung_kehrwert}') is not null,
          '2h Lena speichert einen Schritt im Entwurf');
select is((select a ->> 'nachher' from erklaer_pruefungen p, jsonb_array_elements(p.aenderungen) a
            where p.kernidee_id = :'kid' and p.entscheidung = 'geaendert' and a ->> 'feld' = 'inhalt'
            order by p.id desc limit 1),
          'y = 2x + 3 schneidet die y-Achse im Punkt (0|3).', '2i Protokoll: nachher je Schritt');
select is((select stand from erklaer_pruef_liste() where kernidee_id = :'kid'), 'offen', '2j nach der Aenderung wieder offen');

select is((erklaer_pruefen(:'kid', 'passt', null, null, pg_temp.v(:'kid'))) ->> 'status', 'geprueft', '2k passt -> geprueft');
select is((select array_agg(distinct status) from erklaer_schritt where kernidee_id = :'kid'), '{geprueft}'::text[],
          '2l passt setzt alle Schritte auf geprueft');
select is((select entscheidung from erklaer_pruefungen where kernidee_id = :'kid' order by id desc limit 1), 'passt',
          '2m passt steht im Protokoll');
select is((select geprueft_von from erklaer_pruefungen where kernidee_id = :'kid' order by id desc limit 1), :'lena_uid'::uuid,
          '2n mit Pruefer');
select ok((select jsonb_array_length(aenderungen) > 0 from erklaer_pruefungen where kernidee_id = :'kid' order by id desc limit 1),
          '2o passt nimmt Lenas Aenderungen seit der letzten Entscheidung mit');

-- --- 1 (Fortsetzung)  Lena kann nicht freigeben ------------------------------------------
select is(pg_temp.fehler(format('select erklaer_freigeben(%L, %s)', :'kid', pg_temp.v(:'kid'))),
          '42501', '1n Lena kann nicht freigeben');
select is(pg_temp.fehler(format('select erklaer_status_setzen(''kernidee'', %L, ''freigegeben'', %s)', :'kid', pg_temp.v(:'kid'))),
          '42501', '1o Lena kann auch ueber erklaer_status_setzen nicht freigeben');

-- unsicher -> Rueckfrage an den Admin, Antwort -> wieder offen
select is((erklaer_pruefen(:'kid', 'unsicher', null, 'Ist b hier eindeutig?', pg_temp.v(:'kid'))) ->> 'stand',
          'unsicher', '2p unsicher -> Rueckfrage');
select is((select status from erklaer_kernidee where id = :'kid'), 'entwurf', '2q unsicher: gepruefte Kernidee faellt auf entwurf');
select ok((select rueckfrage from erklaer_pruef_liste() where kernidee_id = :'kid'), '2r Rueckfrage in der Liste');
select pg_temp.act_as(:'admin_uid');
select is((erklaer_rueckfrage_beantworten(:'kid', 'Ja, b ist der y-Wert bei x = 0.')) ->> 'stand', 'offen',
          '2s Admin beantwortet: wieder offen');
select pg_temp.act_as(:'lena_uid');
select is((erklaer_pruefen(:'kid', 'passt', null, null, pg_temp.v(:'kid'))) ->> 'stand', 'passt', '2t erneut passt');

-- --- 5  Veraltete Version ------------------------------------------------------------------
select is(pg_temp.fehler(format('select erklaer_pruefen(%L, ''passt'', null, null, %s)', :'kid', pg_temp.v(:'kid') - 1)),
          'ED422:veraltet', '5a erklaer_pruefen mit alter Version -> veraltet');

-- --- 3  Freigabe nur, wenn alles da ist ---------------------------------------------------
select pg_temp.act_as(:'admin_uid');
select is(pg_temp.fehler(format('select erklaer_freigeben(%L, %s)', :'kid', pg_temp.v(:'kid') - 1)),
          'ED422:veraltet', '5b erklaer_freigeben mit alter Version -> veraltet');
select is(pg_temp.fehler(format('select erklaer_freigeben(%L, %s)', :'kid', pg_temp.v(:'kid'))),
          'ED422:freigabe_unvollstaendig', '3a Freigabe ohne SVG und ohne freigegebene Check-Aufgabe abgelehnt');
select is(pg_temp.detail(format('select erklaer_freigeben(%L, %s)', :'kid', pg_temp.v(:'kid')))::jsonb,
          '[{"was":"formeln_fehlen","art":"erklaerung","variante":"A"},{"was":"checks","ist":0,"soll":1}]'::jsonb,
          '3b Fehler nennt, was fehlt (Formel-SVG, Check-Aufgaben)');
select is((select l.bereit from erklaer_pruef_liste() l where l.kernidee_id = :'kid'), false, '3c nicht bereit zur Freigabe');

-- Formeln wie von tools/formeln-svg.mjs, Check-Aufgabe freigegeben ergaenzt (Kernidee faellt auf entwurf).
select lives_ok(format($$select erklaer_formeln_setzen(s.id, s.inhalt, array[repeat('a', 64)])
                          from erklaer_schritt s where s.kernidee_id = %L and s.art = 'erklaerung'$$, :'kid'),
                '3d Formeln eingetragen');
select lives_ok(format('select erklaer_check_setzen(%L, %L, 2)', :'kid', :'chk_ready'), '3e freigegebene Check-Aufgabe ergaenzt');
select is((select status from erklaer_kernidee where id = :'kid'), 'entwurf', '3f andere Checks: Kernidee wieder entwurf');
select is(pg_temp.detail(format('select erklaer_freigeben(%L, %s)', :'kid', pg_temp.v(:'kid')))::jsonb,
          '[{"was":"kernidee_ungeprueft"}]'::jsonb, '3g ungepruefte Kernidee: Fehler nennt es');

-- --- 4  Vorher liefert erklaer_start nichts ----------------------------------------------
select pg_temp.act_as(:'kind_uid');
select throws_ok(format($f$select erklaer_start(%L, %L, 'fkt_l6_achsenabschnitt')$f$, :'session_id', :'kind_id'),
                 'P0002', null, '4a vor der Freigabe: erklaer_start liefert nichts');

select pg_temp.act_as(:'lena_uid');
select is((erklaer_pruefen(:'kid', 'passt', null, null, pg_temp.v(:'kid'))) ->> 'status', 'geprueft', '3h Lena prueft erneut');
select pg_temp.act_as(:'admin_uid');
select ok((select l.bereit from erklaer_pruef_liste() l where l.kernidee_id = :'kid'), '3i jetzt bereit zur Freigabe');
select is(pg_temp.fehler(format('select erklaer_status_setzen(''kernidee'', %L, ''freigegeben'', %s)', :'kid', pg_temp.v(:'kid'))),
          'ED422:freigabe_unvollstaendig', '3i2 erklaer_status_setzen gibt keine Kernidee mit nur geprueften Schritten frei');
select is((erklaer_freigeben(:'kid', pg_temp.v(:'kid'))) ->> 'status', 'freigegeben', '3j Admin gibt frei');
select is((select array_agg(distinct status) from erklaer_schritt where kernidee_id = :'kid'), '{freigegeben}'::text[],
          '3k Freigabe setzt die Schritte auf freigegeben');
select is((select entscheidung from erklaer_pruefungen where kernidee_id = :'kid' order by id desc limit 1),
          'freigegeben', '3l Freigabe im Protokoll');

select pg_temp.act_as(:'kind_uid');
select is((erklaer_start(:'session_id', :'kind_id', 'fkt_l6_achsenabschnitt')) -> 'check' ->> 'task_id', :'chk_ready',
          '4b nach der Freigabe: erklaer_start liefert die Sequenz mit der freigegebenen Check-Aufgabe');

-- --- 6  Ruecknahme mit Grund ---------------------------------------------------------------
select pg_temp.act_as(:'lena_uid');
select is(pg_temp.fehler(format('select erklaer_freigabe_zuruecknehmen(%L, ''x'', %s)', :'kid', pg_temp.v(:'kid'))),
          '42501', '6a Lena kann die Freigabe nicht zuruecknehmen');
select pg_temp.act_as(:'admin_uid');
select is(pg_temp.fehler(format('select erklaer_freigabe_zuruecknehmen(%L, '' '', %s)', :'kid', pg_temp.v(:'kid'))),
          'ED422:grund_fehlt', '6b Ruecknahme ohne Grund abgelehnt');
select is((erklaer_freigabe_zuruecknehmen(:'kid', 'Beispiel passt nicht zu Klasse 8', pg_temp.v(:'kid'))) ->> 'status',
          'entwurf', '6c Ruecknahme mit Grund');
select is((select notiz from erklaer_pruefungen where kernidee_id = :'kid' and entscheidung = 'freigabe_zurueck'),
          'Beispiel passt nicht zu Klasse 8', '6d Grund im Protokoll');
select is((select array_agg(distinct status) from erklaer_schritt where kernidee_id = :'kid'), '{entwurf}'::text[],
          '6e Schritte zurueck auf entwurf');
select pg_temp.act_as(:'kind_uid');
select throws_ok(format($f$select erklaer_start(%L, %L, 'fkt_l6_achsenabschnitt')$f$, :'session_id', :'kind_id'),
                 'P0002', null, '6f nach der Ruecknahme liefert erklaer_start nichts');

-- --- Protokoll: jede Pflege- und Statusaenderung eine Zeile -------------------------------
select pg_temp.act_as(:'lena_uid');
select is((select array_agg(entscheidung order by id) from erklaer_pruefungen where kernidee_id = :'kid'),
          '{geaendert,geaendert,geaendert,geaendert,passt_nicht,geaendert,passt,unsicher,passt,geaendert,geaendert,passt,freigegeben,freigabe_zurueck}'::text[],
          'P Protokoll vollstaendig und in Reihenfolge');
select is(pg_temp.fehler(format('update erklaer_pruefungen set notiz = ''x'' where kernidee_id = %L', :'kid')),
          '42501', 'P Protokoll nicht aenderbar');

-- --- 7  X0b-Waechter fuer die Erklaer-Funktionen --------------------------------------------
select is(array(select p.oid::regprocedure::text from pg_proc p join pg_namespace n on n.oid = p.pronamespace
                 where n.nspname = 'public' and p.proname ~ '^erklaer_'
                   and (regexp_replace(p.prosrc, '--[^\n]*', '', 'g') ~* '(?<!coalesce\()(public\.)?get_my_role\(\)\s*(not\s+in\M|<>|!=)'
                        or regexp_replace(p.prosrc, '--[^\n]*', '', 'g') ~* '\mnot\s*\(\s*(public\.)?get_my_role\(\)\s*=')
                 order by 1),
          '{}'::text[], '7 Waechter: keine Rollenpruefung der Erklaer-Funktionen bleibt bei NULL offen');

select * from finish();
rollback;
