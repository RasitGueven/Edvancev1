-- ============================================================================
-- Slots SL1 — Rechte (Bauauftrag Slots, Test 11; Entscheidungen 20 und 24).
--
--  11) Coach, Schülerkonto, Elternteil und Konto ohne Profil bekommen 42501 auf allen Admin-Funktionen.
--      meine_einsaetze liefert nur den eigenen Raum und keine Absage. naechste_termine: Admin und Eltern
--      des Kindes. anon hat auf keine Slots-Funktion EXECUTE, authenticated auf keine interne.
--      Neue Tabellen: lesen nur Admin, schreiben niemand direkt. inv4_rls_coverage läuft eigenständig.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

\ir slots_fixture.sql
select pg_temp.als(:'admin');
\set jetzt '''2028-03-13 09:12 Europe/Berlin'''

-- Ausgangslage: Kind mit Profil (Elternteil verknüpft), Stammplatz Di 16 Uhr, eine Absage am Mi-Zusatztermin.
select pg_temp.kind('Rita Rechte', 'Basic', 12, '2027-09-01', '2028-08-31') as kr \gset
update students set profile_id = :'schueler' where id = :'kr';
insert into parent_student (parent_id, student_id) values (:'eltern', :'schueler');
select stammplatz_vergeben(:'kr', pg_temp.zeilen('2:16:woechentlich'), '2028-03-01', '2028-03-01 08:00 Europe/Berlin') is not null;
select zusatztermin_buchen(:'kr', '2028-03-15', pg_temp.zeit(16), :jetzt) is not null;
select termin_absagen(pg_temp.termin(:'kr', '2028-03-15'), '2028-03-13 09:00 Europe/Berlin', :jetzt) is not null;
select pg_temp.kind('Bo Raum Zwei', 'Basic', 12, '2027-09-01', '2028-08-31', 'Deutsch') as kb \gset
select stammplatz_vergeben(:'kb', pg_temp.zeilen('2:16:woechentlich'), '2028-03-01', '2028-03-01 08:00 Europe/Berlin') is not null;
select pg_temp.termin(:'kr', '2028-03-14') as t \gset

-- ── Admin-Funktionen: 42501 für alle anderen Rollen ──────────────────────────
create temp table aufrufe (name text, sql text);
insert into aufrufe values
  ('raum_anlegen', $$select raum_anlegen('X')$$),
  ('raum_deaktivieren', format('select raum_deaktivieren(%L, %L)', pg_temp.raum('Raum 3'), '2030-01-01')),
  ('slot_zeit_anlegen', $$select slot_zeit_anlegen('20:00')$$),
  ('slot_zeit_deaktivieren', format('select slot_zeit_deaktivieren(%L, %L)', pg_temp.zeit(19), '2030-01-01')),
  ('stammschicht_anlegen', format('select stammschicht_anlegen(%L, 1, %L, %L)', :'coach_c', pg_temp.zeit(14), pg_temp.raum('Raum 3'))),
  ('stammschicht_beenden', format('select stammschicht_beenden(%L, %L)', (select id from stammschichten limit 1), '2030-01-01')),
  ('stammplatz_vergeben', format('select stammplatz_vergeben(%L, %L, %L)', :'kr', pg_temp.zeilen('1:14:woechentlich'), '2028-04-24')),
  ('stammplatz_aendern', format($$select stammplatz_aendern(%L, '2028-04-24', 1, %L, 'woechentlich')$$,
                                (select id from stammplaetze where student_id = :'kr'), pg_temp.zeit(14))),
  ('stammplatz_beenden', format($$select stammplatz_beenden(%L, '2028-04-24')$$, (select id from stammplaetze where student_id = :'kr'))),
  ('stammplaetze_weiterfuehren', format('select stammplaetze_weiterfuehren(%L)', :'kr')),
  ('termin_absagen', format('select termin_absagen(%L, now())', :'t')),
  ('zusatztermin_buchen', format($$select zusatztermin_buchen(%L, '2028-03-16', %L)$$, :'kr', pg_temp.zeit(15))),
  ('termin_umbuchen', format($$select termin_umbuchen(%L, now(), '2028-03-16', %L)$$, :'t', pg_temp.zeit(15))),
  ('absage_zuruecknehmen', format('select absage_zuruecknehmen(%L)', pg_temp.termin(:'kr', '2028-03-15'))),
  ('termin_ausgefallen', format('select termin_ausgefallen(%L)', :'t')),
  ('termin_faellt_aus', format($$select termin_faellt_aus('2028-03-14', %L)$$, pg_temp.zeit(16))),
  ('termin_raum_setzen', format('select termin_raum_setzen(%L, %L)', :'t', pg_temp.raum('Raum 2'))),
  ('termin_coach_setzen', format($$select termin_coach_setzen('2028-03-14', %L, %L, null)$$, pg_temp.zeit(16), pg_temp.raum('Raum 1'))),
  ('termin_raum_oeffnen', format($$select termin_raum_oeffnen('2028-03-14', %L, %L, %L)$$, pg_temp.zeit(16), pg_temp.raum('Raum 3'), :'coach_c')),
  ('slots_woche', $$select slots_woche('2028-03-13')$$),
  ('slots_termin', format($$select slots_termin('2028-03-14', %L)$$, pg_temp.zeit(16))),
  ('slots_tag', $$select slots_tag('2028-03-14')$$),
  ('slots_zaehler', $$select slots_zaehler()$$),
  ('slots_coaches', $$select slots_coaches('2028-03-13')$$),
  ('slots_einstellungen', $$select slots_einstellungen()$$),
  ('slots_kinder', $$select slots_kinder()$$),
  ('slots_kind', format('select slots_kind(%L)', :'kr')),
  ('slots_frei', $$select slots_frei('woechentlich', '2028-03-13')$$),
  ('slots_planbilanz_vorschau', format($$select slots_planbilanz_vorschau(%L, %L, '2028-03-14')$$, :'kr', pg_temp.zeilen('1:14:woechentlich'))),
  ('slots_ziele', format($$select slots_ziele(%L, %L, now(), '2028-03-13')$$, :'kr', :'t')),
  ('slots_kandidaten', format($$select slots_kandidaten('2028-03-16', %L)$$, pg_temp.zeit(15)));

select pg_temp.als(:'coach_a');
select throws_ok(a.sql, '42501', null, '11 Coach: ' || a.name || ' -> 42501') from aufrufe a order by a.name;
select pg_temp.als(:'ohne_profil');
select throws_ok(a.sql, '42501', null, '11 Konto ohne Profil: ' || a.name || ' -> 42501') from aufrufe a order by a.name;
select pg_temp.als(:'schueler');
select throws_ok(a.sql, '42501', null, '11 Schülerkonto: ' || a.name || ' -> 42501') from aufrufe a order by a.name;
select pg_temp.als(:'eltern');
select throws_ok(a.sql, '42501', null, '11 Elternteil: ' || a.name || ' -> 42501') from aufrufe a order by a.name;

-- ── Coach-Funktionen ─────────────────────────────────────────────────────────
select pg_temp.als(:'ohne_profil');
select throws_ok($$select meine_einsaetze('2028-03-13')$$, '42501', null, '11 meine_einsaetze: Konto ohne Profil -> 42501');
select throws_ok(format($$select termin_session_anlegen('2028-03-14', %L, %L)$$, pg_temp.zeit(16), pg_temp.raum('Raum 1')),
                 '42501', null, '11 termin_session_anlegen: Konto ohne Profil -> 42501');
select pg_temp.als(:'admin');
select throws_ok($$select meine_einsaetze('2028-03-13')$$, '42501', null, '11 meine_einsaetze: nur Coach');

-- Welches Kind am Di 14.03. in Raum 1 (Coach Anna) sitzt, entscheidet die Zuteilung (Entscheidung 15).
select student_id as k_r1 from slot_zuteilung('2028-03-14', pg_temp.zeit(16)) where raum_id = pg_temp.raum('Raum 1') \gset
select student_id as k_r2 from slot_zuteilung('2028-03-14', pg_temp.zeit(16)) where raum_id = pg_temp.raum('Raum 2') \gset
select pg_temp.als(:'coach_a');
select meine_einsaetze('2028-03-13') as me \gset
select is((select count(*)::int from jsonb_array_elements(:'me'::jsonb -> 'einsaetze') e where e ->> 'raum_name' <> 'Raum 1'), 0,
          '11 meine_einsaetze: nur der eigene Raum (Coach Anna, Raum 1)');
select ok(exists (select 1 from jsonb_array_elements(:'me'::jsonb -> 'einsaetze') e, jsonb_array_elements(e -> 'kinder') k
                   where k ->> 'student_id' = :'k_r1' and e ->> 'datum' = '2028-03-14'), '11 meine_einsaetze: das Kind im eigenen Raum steht drin');
select ok(not exists (select 1 from jsonb_array_elements(:'me'::jsonb -> 'einsaetze') e, jsonb_array_elements(e -> 'kinder') k
                       where k ->> 'student_id' = :'k_r2' and e ->> 'datum' = '2028-03-14'), '11 meine_einsaetze: das Kind im anderen Raum fehlt');
select ok(not exists (select 1 from jsonb_array_elements(:'me'::jsonb -> 'einsaetze') e, jsonb_array_elements(e -> 'kinder') k
                       where e ->> 'datum' = '2028-03-15' and k ->> 'student_id' = :'kr'), '11 meine_einsaetze: keine Absage (Mi abgesagt)');
select is((select count(*)::int from jsonb_array_elements(:'me'::jsonb -> 'einsaetze') e, jsonb_array_elements(e -> 'kinder') k,
                  jsonb_object_keys(k) key where key not in ('student_id', 'name', 'klasse', 'fach')), 0,
          '11 meine_einsaetze: je Kind nur Name, Klasse, Fach (kein Vertrag, kein Zustand)');
select throws_ok(format($$select termin_session_anlegen('2028-03-14', %L, %L, '2028-03-14 12:00 Europe/Berlin')$$,
                        pg_temp.zeit(16), pg_temp.raum('Raum 1')),
                 '22023', null, '11 Coach mit p_jetzt eines anderen Tages kann keine Session festschreiben');

-- ── naechste_termine ────────────────────────────────────────────────────────
select pg_temp.als(:'eltern');
select lives_ok(format('select naechste_termine(%L)', :'kr'), '11 naechste_termine: Eltern des Kindes');
select throws_ok(format('select naechste_termine(%L)', :'kb'), '42501', null, '11 naechste_termine: fremdes Kind -> 42501');
select pg_temp.als(:'coach_a');
select throws_ok(format('select naechste_termine(%L)', :'kr'), '42501', null, '11 naechste_termine: Coach -> 42501');
select pg_temp.als(:'admin');
select lives_ok(format('select naechste_termine(%L)', :'kr'), '11 naechste_termine: Admin');

-- ── EXECUTE: anon nie, authenticated nur auf die Funktionen des Datenvertrags ─
create temp table api (name text);
insert into api values ('absage_zuruecknehmen'), ('meine_einsaetze'), ('naechste_termine'), ('raum_anlegen'), ('raum_deaktivieren'),
  ('slot_zeit_anlegen'), ('slot_zeit_deaktivieren'), ('slots_coaches'), ('slots_einstellungen'), ('slots_frei'), ('slots_kandidaten'),
  ('slots_kind'), ('slots_kinder'), ('slots_planbilanz_vorschau'), ('slots_tag'), ('slots_termin'), ('slots_woche'), ('slots_zaehler'),
  ('slots_ziele'), ('stammplaetze_weiterfuehren'), ('stammplatz_aendern'), ('stammplatz_beenden'), ('stammplatz_vergeben'),
  ('stammschicht_anlegen'), ('stammschicht_beenden'), ('termin_absagen'), ('termin_ausgefallen'), ('termin_coach_setzen'),
  ('termin_faellt_aus'), ('termin_raum_oeffnen'), ('termin_raum_setzen'), ('termin_session_anlegen'), ('termin_umbuchen'),
  ('zusatztermin_buchen');
create temp table slots_fkt as
select p.oid, p.proname::text as name from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public'
   and (p.proname like 'slot\_%' or p.proname like 'slots\_%' or p.proname in (select name from api)
        or p.proname in ('termine_planen', 'naechster_termin'))
   and p.proname not in ('slot_assign', 'slot_release');  -- S10-Altlast (Lead-Slots), nicht Teil von SL1
select ok((select count(*) from slots_fkt) >= 80, '11 alle Slots-Funktionen gefunden');
select is((select array_agg(name order by name) from slots_fkt where has_function_privilege('anon', oid, 'execute')), null,
          '11 anon hat auf keine Slots-Funktion EXECUTE');
select is((select array_agg(name order by name) from slots_fkt
            where has_function_privilege('authenticated', oid, 'execute') and name not in (select name from api)), null,
          '11 authenticated hat EXECUTE nur auf die Funktionen des Datenvertrags');
select is((select count(*)::int from api where name not in (select name from slots_fkt
                                                             where has_function_privilege('authenticated', oid, 'execute'))), 0,
          '11 authenticated hat EXECUTE auf alle Funktionen des Datenvertrags');

-- ── Tabellen: lesen nur Admin, schreiben niemand direkt ──────────────────────
select pg_temp.als(:'coach_a');
set local role authenticated;
select is((select count(*)::int from kind_termine), 0, '11 Coach liest kind_termine nicht (RLS)');
select is((select count(*)::int from stammschichten), 0, '11 Coach liest stammschichten nicht (RLS)');
reset role;
select pg_temp.als(:'admin');
set local role authenticated;
select ok((select count(*) from kind_termine) > 0, '11 Admin liest kind_termine');
select throws_ok($$insert into raeume (name, aktiv_ab) values ('Direkt', current_date)$$, '42501', null,
                 '11 Admin schreibt nicht direkt in die Tabellen (nur über die Funktionen)');
reset role;

select * from finish();
rollback;
