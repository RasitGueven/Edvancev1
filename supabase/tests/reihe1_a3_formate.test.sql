-- ============================================================================
-- Reihe 1 · A3 Formate (Migrationen 20261027134831, 20261027134927): Wertung der neuen Formate.
--   0 format_zahl_gleich sagt auf den Probefaellen dasselbe wie lsa_grade (echte Wertungslogik)
--   1 Loesungsmenge: Reihenfolge, doppelte Werte, Vorzeichen, Bruch/Dezimal, Fehlbild vor Teilmenge, keine Loesung
--     (Abnahme 3 mit x² = 9)
--   2 Feldmaske: (x + 3)² − 1, Bedeutung statt Eingabe, leer heisst 1 (Abnahme 4)
--   3 Graph-Auswahl, Fehler finden, Bausteine, Schritte ordnen
--   4 Instanz Ende zu Ende: aufgabe_werten und session_bewerten, Rueckmeldungen, Kindersicht mit Optionsbildern
-- Am Ende rollback.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(44);

create function pg_temp.w(p_format text, p_payload jsonb, p_loesung jsonb, p_fehlbilder jsonb, p_antwort jsonb)
returns text language sql as $$
  select r.richtig || '/' || coalesce(r.fehlbild_key, '-') || '/' || r.teilmenge
    from public.format_werten_daten(p_format, p_payload, p_loesung, p_fehlbilder, p_antwort) r
$$;

-- ── 0) Zahlen wie lsa_grade ─────────────────────────────────────────────────
select is((select count(*)::int from (values ('3','3'),('-3','−3'),('−3','-3'),('1,5','3/2'),('3/2','1,5'),('6/4','3/2'),
                                            ('+3','3'),(' 3 ','3'),('3,0','3'),('0','-0'),('3','-3'),('2,50','2,5'),('7','x'),
                                            ('0,5','1/2'),('7','3 1/2')) v(a, b)
            where public.format_zahl_gleich(a, b)
                  is distinct from (lsa_grade('NUMERIC', jsonb_build_object('canonical', b), jsonb_build_array(b),
                                              jsonb_build_object('text', a)) = 'voll')), 0,
          '0 format_zahl_gleich = lsa_grade auf allen Probefaellen');

select ok(format_zahl_gleich('3/−4', '-3/4') and format_zahl_gleich('−3/−4', '3/4') and not format_zahl_gleich('3 1/2', '7/2'),
          '0 toleranter als lsa_grade nur beim negativen Nenner; "3 1/2" bleibt unlesbar');

-- ── 1) Loesungsmenge, x² = 9 ────────────────────────────────────────────────
\set lm_p '{"format":"loesungsmenge","element":"zahl","max_felder":3,"variable":"x"}'
\set lm_l '{"menge":["3","−3"]}'
\set lm_f '[{"key":"qf_nur_positive_loesung","menge":["3"]},{"key":"qf_wurzel_als_haelfte","menge":["4,5","−4,5"]},{"key":"qf_wurzel_aus_negativ","keine_loesung":true}]'
select is(pg_temp.w('loesungsmenge', :'lm_p', :'lm_l', :'lm_f', '{"werte":["3","-3"]}'), 'true/-/false', '1 {3; −3} richtig');
select is(pg_temp.w('loesungsmenge', :'lm_p', :'lm_l', :'lm_f', '{"werte":["−3","3"]}'), 'true/-/false', '1 andere Reihenfolge richtig');
select is(pg_temp.w('loesungsmenge', :'lm_p', :'lm_l', :'lm_f', '{"werte":["3","-3","3"]}'), 'true/-/false', '1 doppelte Werte zaehlen einmal');
select is(pg_temp.w('loesungsmenge', :'lm_p', :'lm_l', :'lm_f', '{"werte":["+3","−3,0"]}'), 'true/-/false', '1 Schreibweisen +3 und −3,0');
select is(pg_temp.w('loesungsmenge', :'lm_p', :'lm_l', :'lm_f', '{"werte":["3"]}'), 'false/qf_nur_positive_loesung/false',
          '1 {3} zeigt das Fehlbild nur die positive Loesung (vor der Teilmenge) und ist falsch');
select is(pg_temp.w('loesungsmenge', :'lm_p', :'lm_l', :'lm_f', '{"keine_loesung":true}'), 'false/qf_wurzel_aus_negativ/false',
          '1 keine Loesung ist falsch');
select is(pg_temp.w('loesungsmenge', :'lm_p', :'lm_l', '[]', '{"werte":["-3"]}'), 'false/-/true',
          '1 echte Teilmenge ohne passendes Fehlbild: teilmenge');
select is(pg_temp.w('loesungsmenge', :'lm_p', :'lm_l', :'lm_f', '{"werte":["3","-3","9"]}'), 'false/-/false',
          '1 Obermenge ist falsch, keine Teilmenge');
select is(pg_temp.w('loesungsmenge', :'lm_p', :'lm_l', :'lm_f', '{"werte":[]}'), 'false/-/false', '1 leere Menge ist falsch');
select is(pg_temp.w('loesungsmenge', :'lm_p', :'lm_l', '[]', '{"werte":["-3",""]}'), 'false/-/true',
          '1 ein leeres Zusatzfeld zaehlt nicht: weiter Teilmenge');
select is(pg_temp.w('loesungsmenge', :'lm_p', '{"menge":["1/3"]}', '[]', '{"werte":["0,33333333333333333333"]}'), 'false/-/false',
          '1 exakt: 1/3 ist nicht 0,333…');
select is(pg_temp.w('loesungsmenge', :'lm_p', :'lm_l', :'lm_f', '{"keine_loesung":"ja"}'), 'false/-/false',
          '1 kaputte Antwort wirft nicht');
select is(pg_temp.w('loesungsmenge', :'lm_p', :'lm_l', :'lm_f', '{"werte":["3","drei"]}'), 'false/-/false', '1 Unlesbares ist falsch');
select is(pg_temp.w('loesungsmenge', :'lm_p', '{"menge":["3/2","−1"]}', '[]', '{"werte":["1,5","-1"]}'), 'true/-/false',
          '1 Bruch und Dezimal gleich');
select is(pg_temp.w('loesungsmenge', :'lm_p', '{"keine_loesung":true}', '[]', '{"keine_loesung":true}'), 'true/-/false',
          '1 keine Loesung, wo es keine gibt: richtig');
select is(pg_temp.w('loesungsmenge', :'lm_p', '{"keine_loesung":true}', '[]', '{"werte":["2"]}'), 'false/-/false',
          '1 eine Zahl, wo es keine Loesung gibt: falsch');

-- ── 2) Feldmaske f(x) = (x + 3)² − 1 ────────────────────────────────────────
\set fm_p '{"format":"feldmaske","schablone":[{"text":"f(x) = "},{"feld":"a","typ":"zahl","leer_heisst_eins":true},{"text":"(x "},{"feld":"vd","typ":"vorzeichen"},{"feld":"d","typ":"zahl"},{"text":")² "},{"feld":"ve","typ":"vorzeichen"},{"feld":"e","typ":"zahl"}]}'
\set fm_l '{"werte":{"a":"1","d":"3","e":"-1"}}'
\set fm_f '[{"key":"qf_verschiebung_vorzeichen","werte":{"a":"1","d":"-3","e":"-1"}}]'
select is(pg_temp.w('feldmaske', :'fm_p', :'fm_l', :'fm_f', '{"felder":{"a":"","vd":"+","d":"3","ve":"−","e":"1"}}'), 'true/-/false',
          '2 [+][3] und [−][1] richtig, leeres a heisst 1');
select is(pg_temp.w('feldmaske', :'fm_p', :'fm_l', :'fm_f', '{"felder":{"a":"1","vd":"−","d":"−3","ve":"+","e":"-1"}}'), 'true/-/false',
          '2 dieselbe Bedeutung anders eingegeben ([−][−3], [+][−1]) richtig');
select is(pg_temp.w('feldmaske', :'fm_p', :'fm_l', :'fm_f', '{"felder":{"a":"1","d":"3","ve":"-","e":"1"}}'), 'true/-/false',
          '2 ohne Vorzeichen-Angabe gilt +');
select is(pg_temp.w('feldmaske', :'fm_p', :'fm_l', :'fm_f', '{"felder":{"a":"","vd":"−","d":"3","ve":"−","e":"1"}}'),
          'false/qf_verschiebung_vorzeichen/false', '2 Vorzeichen in der Klammer falsch: Fehlbild ueber die Bedeutung');
select is(pg_temp.w('feldmaske', :'fm_p', :'fm_l', :'fm_f', '{"felder":{"a":"","vd":"+","d":"","ve":"−","e":"1"}}'), 'false/-/false',
          '2 leeres Pflichtfeld ist falsch');
select is(pg_temp.w('feldmaske', :'fm_p', '{"werte":{"a":"1","d":"1,5","e":"0"}}', '[]', '{"felder":{"vd":"+","d":"3/2","e":"0"}}'),
          'true/-/false', '2 Bruchfeld: 3/2 = 1,5');

-- ── 3) Weitere Formate ──────────────────────────────────────────────────────
select is(pg_temp.w('graph_auswahl', '{}', '{"option":"b"}', '[{"key":"qf_oeffnung_vertauscht","option":"a"}]', '{"gewaehlt":"b"}'),
          'true/-/false', '3 Graph-Auswahl richtig');
select is(pg_temp.w('graph_auswahl', '{}', '{"option":"b"}', '[{"key":"qf_oeffnung_vertauscht","option":"a"}]', '{"gewaehlt":"a"}'),
          'false/qf_oeffnung_vertauscht/false', '3 Graph-Auswahl: Fehlbild je Option');
select is(pg_temp.w('fehler_finden', '{}', '{"zeile":3,"warum":"w2"}', '[]', '{"zeile":3,"warum":"w2"}'), 'true/-/false',
          '3 Fehler finden: Zeile und Begruendung richtig');
select is(pg_temp.w('fehler_finden', '{}', '{"zeile":3,"warum":"w2"}', '[]', '{"zeile":3,"warum":"w1"}'), 'false/-/false',
          '3 Fehler finden: richtige Zeile, falsche Begruendung ist falsch');
select is(pg_temp.w('bausteine', '{}', '{"gewaehlt":["a","c"]}', '[]', '{"gewaehlt":["c","a"]}'), 'true/-/false',
          '3 Bausteine: genau die Kombination, Reihenfolge egal');
select is(pg_temp.w('bausteine', '{}', '{"gewaehlt":["a","c"]}', '[]', '{"gewaehlt":["a"]}'), 'false/-/false',
          '3 Bausteine: nur einer ist falsch');
select is(pg_temp.w('bausteine', '{}', '{"gewaehlt":["a"]}', '[]', '{"gewaehlt":"a"}'), 'false/-/false',
          '3 Bausteine: Antwort ohne Liste wirft nicht');
select is(pg_temp.w('schritte_ordnen', '{}', '{"reihenfolgen":[["s1","s2","s3"],["s2","s1","s3"]]}', '[]',
                    '{"reihenfolge":["s2","s1","s3"]}'), 'true/-/false', '3 Schritte ordnen: eine zulaessige Reihenfolge');
select is(pg_temp.w('schritte_ordnen', '{}', '{"reihenfolgen":[["s1","s2","s3"]]}', '[]', '{"reihenfolge":["s3","s2","s1"]}'),
          'false/-/false', '3 Schritte ordnen: andere Reihenfolge falsch');
select throws_ok($$select * from format_werten_daten('unbekannt', '{}', '{}', '[]', '{}')$$, '22023', null,
                 '3 unbekanntes Format scheitert laut');

-- ── 4) Instanz Ende zu Ende ─────────────────────────────────────────────────
select set_config('request.jwt.claims', json_build_object('role', 'service_role')::text, true);
insert into skills (skill_key, label, klasse_herkunft, fundament_tiefe) values ('zz_r1a3', 'ZZ R1 A3', 9, 1);
insert into bauformen (schluessel, skill_key, format, rollen, steckbrief, status)
values ('ZZ-3', 'zz_r1a3', 'loesungsmenge', '{uebung}',
        '{"fehlbilder":[{"key":"qf_nur_positive_loesung","rueckmeldung":"ZZ: Auch eine negative Zahl ins Quadrat gibt 9."}]}',
        'freigegeben');
insert into tasks (content_type, input_type, status, is_active, question, question_payload, skill_key, source, source_ref,
                   einsatz, bauform_id, bauform_version, stufe, rolle, pruefmaschine)
select 'exercise', 'LOESUNGSMENGE', 'ready', true, 'Löse x² = 9.', :'lm_p', 'zz_r1a3', 'reihe1_a3_test', 'zz-3-1',
       '{session}', b.id, 1, 1, 'uebung', '{"1":{"ok":true}}'
  from bauformen b where b.schluessel = 'ZZ-3'
returning id as t3 \gset
insert into task_solutions (task_id, correct_answers)
values (:'t3', jsonb_build_array(:'lm_l'::jsonb || jsonb_build_object('fehlbilder', :'lm_f'::jsonb)));
select ok(session_im_pool(:'t3', false), '4 eine Instanz eines neuen Formats steht im Session-Pool');
select is((select row(richtig, fehlbild_key, rueckmeldung)::text from aufgabe_werten(:'t3', '{"werte":["3"]}')),
          '(f,qf_nur_positive_loesung,"ZZ: Auch eine negative Zahl ins Quadrat gibt 9.")',
          '4 aufgabe_werten: Fehlbild mit der Rueckmeldung des Steckbriefs');
select is((select rueckmeldung from aufgabe_werten(:'t3', '{"werte":["-3"]}')), 'Eine Lösung fehlt noch.',
          '4 aufgabe_werten: Teilmenge zeigt "Eine Lösung fehlt noch."');
select is((select ergebnis || '/' || coalesce(fehlbild_slug, '-') from session_bewerten(:'t3', null, '{"werte":["−3","3"]}')),
          'richtig/-', '4 session_bewerten wertet das neue Format');
select is((select ergebnis || '/' || fehlbild_slug from session_bewerten(:'t3', null, '{"werte":["-3"]}')),
          'falsch/qf_loesung_fehlt', '4 session_bewerten: Teilmenge als qf_loesung_fehlt');
select throws_like($$insert into tasks (content_type, input_type, question_payload, source, source_ref, einsatz)
                     values ('exercise', 'NUMERIC', '{"format":"feldmaske"}', 'reihe1_a3_test', 'x', '{session}')$$,
                   '%tasks_format_passt%', '4 Format und input_type gehoeren zusammen');
select throws_like($$insert into tasks (content_type, input_type, question_payload, source, source_ref, einsatz)
                     values ('exercise', 'LOESUNGSMENGE', '{"format":"loesungsmenge","menge":["3"]}', 'reihe1_a3_test', 'y', '{session}')$$,
                   '%tasks_question_payload_no_solution%', '4 die Loesung darf nie in der Kindersicht stehen');
update tasks set input_type = 'GRAPH_AUSWAHL',
       question_payload = '{"format":"graph_auswahl","optionen":[{"id":"a","alt":"Parabel nach oben"},{"id":"b","alt":"Parabel nach unten"}]}'
 where id = :'t3';
insert into task_figur_optionen (task_id, option_id, generator, params, alt_text, svg_hash)
values (:'t3', 'a', 'parabel', '{"a":1,"d":0,"e":0}', 'Parabel nach oben geöffnet', 'h');
select is((select jsonb_path_query_array(aufgabe_payload(:'t3'), '$.payload.optionen[*].bild') ->> 0 like '%generiert/'
                  || :'t3' || '/option-a-dunkel.svg'), true, '4 Kindersicht: Optionsbild aus task_figur_optionen');
select ok(not aufgabe_ziehbar(:'t3'), '4 Graph-Auswahl ohne Bild fuer jede Option ist nicht ziehbar');
insert into task_figur_optionen (task_id, option_id, generator, params, alt_text, svg_hash)
values (:'t3', 'b', 'parabel', '{"a":-1,"d":0,"e":0}', 'Parabel nach unten geöffnet', 'h');
select ok(aufgabe_ziehbar(:'t3'), '4 mit allen Bildern ziehbar');

select * from finish();
rollback;
