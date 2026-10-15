-- ============================================================================
-- Slots S1 — Sofort-Session und Buchbarkeit mit Grund (Entscheidungen Rasit 1–8, 15.10.2026).
--
--   1) kinder_buchbar: jeder Code mindestens einmal, Detail-Datum, Name und Klasse aus dem Vertrag.
--   2) Gleichheit: Vertrags-Code ⇔ nicht session_platz_zugang; 'ok' ⇒ session_platz_zugang (alle Kinder, mehrere Tage).
--   3) sofort_session_anlegen am Ferientag, Feiertag, Sonntag; Einzel-Session mit Raumname, auf die Minute.
--   4) Einheiten: echtes Kind verbraucht eine (Planbilanz eins weniger, Stammplatz-Termine rücken nach),
--      nur Testkinder → testlauf, nichts verbraucht.
--   5) Abbrüche mit Hinweis: art_konflikt, keine_kinder, kein_kind, Vertrags-Code mit student_id, raum_inaktiv, kein_coach.
--   6) Leitung: Admin-Profil erlaubt, student/parent nicht; stammschicht_anlegen bleibt bei Rolle 'coach'.
--   7) Rechte: Coach bekommt 42501 bei allen vier Funktionen; anon hat kein EXECUTE.
--   8) session_leitung und stundenplan_woche.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

\ir slots_fixture.sql
select pg_temp.als(:'admin');

-- SQLSTATE/hint/detail eines Aufrufs, 'kein Fehler' sonst.
create or replace function pg_temp.fehler(p_sql text) returns text language plpgsql as $$
declare v_state text; v_hint text; v_detail text;
begin
  execute p_sql;
  return 'kein Fehler';
exception when others then
  get stacked diagnostics v_state = returned_sqlstate, v_hint = pg_exception_hint, v_detail = pg_exception_detail;
  return v_state || '/' || coalesce(v_hint, '') || '/' || coalesce(v_detail, '');
end $$;
-- Code (und Detail) eines Kindes an einem Tag.
create or replace function pg_temp.code(p_kind uuid, p_datum date, p_session uuid default null) returns text
language sql as $$
  select b.code || coalesce('/' || b.detail::text, '') from public.kinder_buchbar(p_datum, p_session) b
   where b.student_id = p_kind
$$;
create or replace function pg_temp.rest(p_kind uuid, p_datum date) returns int language sql as $$
  select v.einheiten - public.slots_fest_belegt(v.id, p_datum) from public.vertraege v where v.id = pg_temp.vertrag(p_kind)
$$;

-- Woche Mo 01.11.2027 (Allerheiligen, Herbstferien bis Sa 06.11.) bis So 07.11.2027.
\set ferientag '''2027-11-04 10:15:42 Europe/Berlin'''
\set feiertag  '''2027-11-01 09:05:00 Europe/Berlin'''
\set sonntag   '''2027-11-07 12:34:56 Europe/Berlin'''

-- ── Kinder ───────────────────────────────────────────────────────────────────
select pg_temp.kind('Vera Echt', 'Basic', 12, '2027-09-01', '2028-08-31') as kv \gset
select pg_temp.kind('Theo Test', 'Basic', 12, '2027-09-01', '2028-08-31') as kt \gset
update students set ist_test = true where id = :'kt';
select pg_temp.kind('Tina Test', 'Basic', 12, '2027-09-01', '2028-08-31') as kt2 \gset
update students set ist_test = true where id = :'kt2';
insert into students (class_level) values (7) returning id as kn \gset
select pg_temp.kind('Wim Widerruf', 'Basic', 12, '2027-10-01', '2028-09-30') as kw \gset
update vertraege set zugangscode = 'EDV-ABCD-EFGJ' where id = pg_temp.vertrag(:'kw');  -- Widerruf sperrt den Zugangscode
select vertrag_widerruf_erfassen(pg_temp.vertrag(:'kw'), '2027-10-05') is not null;
select pg_temp.kind('Ella Ende', 'Basic', 6, '2027-03-01', '2027-08-31') as ke \gset
select pg_temp.kind('Kai Kündigung', 'Basic', 12, '2027-09-01', '2028-08-31') as kk \gset
select vertrag_sonderkuendigung_erfassen(pg_temp.vertrag(:'kk'), '2027-10-15', 'Umzug') is not null;
-- Pilot ab Monatserstem in der Zukunft (wie V5: kein Tarif, Preis 0, Einheiten frei).
insert into leads (full_name, first_name, status, class_level) values ('Pia Pilot', 'Pia', 'vertrag', 9) returning id as lp \gset
insert into students (class_level) values (9) returning id as kp \gset
update leads set converted_student_id = :'kp' where id = :'lp';
insert into vertraege (lead_id, status, vertrag_status, abgeschlossen_at, abgeschlossen_am, abschluss_weg, student_id,
                       vertragsart, preis_cents, vertragsbeginn, vertrag_ende, einheiten, fach, klasse, kind_vorname, kind_nachname)
values (:'lp', 'abgeschlossen', 'aktiv', now(), '2027-10-20', 'vor_ort', :'kp',
        'pilot', 0, '2027-12-01', '2028-07-07', 30, 'Mathematik', 9, 'Pia', 'Pilot');
-- Wenig Einheiten (Pilot mit 2) und Stammplatz dienstags 16 Uhr.
insert into leads (full_name, first_name, status, class_level) values ('Lea Knapp', 'Lea', 'vertrag', 9) returning id as lq \gset
insert into students (class_level) values (9) returning id as kq \gset
update leads set converted_student_id = :'kq' where id = :'lq';
insert into vertraege (lead_id, status, vertrag_status, abgeschlossen_at, abgeschlossen_am, abschluss_weg, student_id,
                       vertragsart, preis_cents, vertragsbeginn, vertrag_ende, einheiten, fach, klasse, kind_vorname, kind_nachname)
values (:'lq', 'abgeschlossen', 'aktiv', now(), '2027-10-20', 'vor_ort', :'kq',
        'pilot', 0, '2027-11-01', '2028-07-07', 2, 'Mathematik', 9, 'Lea', 'Knapp');
-- Brücke: alter Vertrag bis 31.10., Folgevertrag (vorgaenger_id) ab 01.12. → Zugang dazwischen.
select pg_temp.kind('Bruno Brücke', 'Basic', 12, '2026-11-01', '2027-10-31') as kb \gset
update vertraege set verlaengerung_status = 'verlaengert' where id = pg_temp.vertrag(:'kb');
insert into vertraege (lead_id, status, vertrag_status, abgeschlossen_at, abgeschlossen_am, abschluss_weg, student_id,
                       vertragsbeginn, vertrag_ende, tier_id, laufzeit_monate, einheiten, fach, klasse, vorgaenger_id)
select v.lead_id, 'abgeschlossen', 'aktiv', now(), '2027-10-20', 'vor_ort', v.student_id, '2027-12-01', '2028-11-30',
       v.tier_id, 12, 38, 'Mathematik', 8, v.id
  from vertraege v where v.id = pg_temp.vertrag(:'kb');
-- Vorläufiges Kind (aus einem Lead) erscheint nie.
insert into leads (full_name, first_name, status, class_level) values ('Paul Provisorisch', 'Paul', 'lsa_fertig', 8) returning id as lpv \gset
select set_config('edvance.allow_provisional', '1', true);
insert into students (class_level, is_provisional, lead_id) values (8, true, :'lpv') returning id as kpv \gset
select set_config('edvance.allow_provisional', '', true);

-- ── 1) kinder_buchbar: jeder Code ────────────────────────────────────────────
select is(pg_temp.code(:'kn', '2027-11-07'), 'kein_vertrag', '1 kein_vertrag');
select is(pg_temp.code(:'kw', '2027-11-07'), 'widerrufen/2027-10-05', '1 widerrufen (Detail: Widerrufsdatum)');
select is(pg_temp.code(:'kp', '2027-11-07'), 'vertrag_ab/2027-12-01', '1 Pilot ab Monatserstem in der Zukunft: vertrag_ab mit Beginn');
select is(pg_temp.code(:'ke', '2027-11-07'), 'vertrag_beendet/2027-08-31', '1 vertrag_beendet mit Vertragsende');
select is(pg_temp.code(:'kk', '2027-11-07'), 'vertrag_beendet/2027-10-14', '1 gekündigt: vertrag_beendet am Tag vor gekuendigt_zum');
select is(pg_temp.code(:'kp', '2027-12-01'), 'ok', '1 Pilot ab Beginn: ok');
select is(pg_temp.code(:'kt', '2027-11-01'), 'ok', '1 Testkind mit Vertrag am Feiertag: ok');
select is(pg_temp.code(:'kv', '2027-11-07'), 'ok', '1 echtes Kind am Sonntag: ok');
select is(pg_temp.code(:'kb', '2027-11-07'), 'keine_einheit',
          '1 Brücke: Zugang ja, aber kein Vertrag zum Abrechnen → keine_einheit');
select is((select count(*)::int from kinder_buchbar('2027-11-07') where student_id = :'kpv'), 0, '1 vorläufige Kinder fehlen');
select is((select row(name, klasse, ist_test)::text from kinder_buchbar('2027-11-07') where student_id = :'kt'),
          row('Theo Test', 8, true)::text, '1 Name und Klasse aus dem Vertrag, Kennzeichen Test');

select stammplatz_vergeben(:'kq', pg_temp.zeilen('2:16:woechentlich'), '2027-11-01', '2027-11-01 08:00 Europe/Berlin') is not null;
select is((select count(*)::int from kind_termine where student_id = :'kq'), 2, '1 Knapp: zwei Einheiten, zwei Stammplatz-Termine');
select is(pg_temp.code(:'kq', '2027-11-09'), 'schon_termin', '1 schon_termin (Stammplatz-Termin am Tag)');

-- ── 2) Gleichheit mit session_platz_zugang ───────────────────────────────────
create temp table s1_tage (d date);
insert into s1_tage values ('2027-03-01'), ('2027-08-31'), ('2027-09-01'), ('2027-10-04'), ('2027-10-14'), ('2027-10-15'),
                           ('2027-11-01'), ('2027-11-07'), ('2027-11-09'), ('2027-12-01'), ('2028-08-31'), ('2028-09-01');
select is((select count(*)::int from s1_tage t, kinder_buchbar(t.d) b
            where (b.code in ('kein_vertrag', 'widerrufen', 'vertrag_ab', 'vertrag_beendet'))
                  is distinct from not session_platz_zugang(b.student_id, t.d)), 0,
          '2 Vertrags-Code genau dann, wenn session_platz_zugang nein sagt (alle Kinder, zwölf Tage)');
select is((select count(*)::int from s1_tage t, kinder_buchbar(t.d) b
            where (b.code = 'ok') is distinct from
                  (session_platz_zugang(b.student_id, t.d) and b.code not in ('keine_einheit', 'schon_termin', 'art_konflikt'))), 0,
          '2 ok ⇔ session_platz_zugang und keine Sperre');
select ok((select count(distinct b.code) from s1_tage t, kinder_buchbar(t.d) b) >= 7, '2 Stichprobe deckt alle Codes ohne Session ab');

-- ── 3/4) Anlegen am Ferientag, Feiertag, Sonntag ─────────────────────────────
select (slots_planbilanz(pg_temp.vertrag(:'kv'), '2027-11-04') ->> 'ohne_termin')::int as ot_vor \gset
select pg_temp.rest(:'kv', '2027-11-04') as rest_vor \gset
select sofort_session_anlegen(:'coach_a', pg_temp.raum('Raum 1'), array[:'kv'::uuid], :ferientag) as r_ferien \gset
select is((:'r_ferien'::jsonb ->> 'testlauf')::boolean, false, '3 Ferientag: echte Session');
select results_eq(format($$select room, scheduled_at, raum_id, slot_zeit_id, testlauf, coach_id, status
                            from coaching_sessions where id = %L$$, :'r_ferien'::jsonb ->> 'session_id'),
                  format($$values ('Raum 1'::text, '2027-11-04 10:15 Europe/Berlin'::timestamptz, null::uuid, null::uuid, false,
                                   %L::uuid, 'upcoming'::text)$$, :'coach_a'),
                  '3 Einzel-Session: Raumname, jetzt auf die Minute, raum_id/slot_zeit_id null');
select is((select count(*)::int from slots_einzelbuchungen(:'kv')), 1, '4 Buchung zählt als Einzelbuchung');
select is(pg_temp.rest(:'kv', '2027-11-04'), :rest_vor - 1, '4 slots_fest_belegt zählt die Einzelbuchung (eine Einheit weniger)');
select is((slots_planbilanz(pg_temp.vertrag(:'kv'), '2027-11-04') ->> 'ohne_termin')::int, :ot_vor - 1, '4 Planbilanz: eins weniger');
select is(pg_temp.code(:'kv', '2027-11-04'), 'schon_termin', '1 schon_termin (Einzelbuchung am Tag)');
select is(pg_temp.code(:'kv', '2027-11-04', (:'r_ferien'::jsonb ->> 'session_id')::uuid), 'ok',
          '1 mit p_session_id: die eigene Buchung zählt nicht');

select sofort_session_anlegen(:'admin', pg_temp.raum('Raum 2'), array[:'kt'::uuid, :'kt2'::uuid, :'kt'::uuid], :feiertag) as r_feier \gset
select is((:'r_feier'::jsonb ->> 'testlauf')::boolean, true, '3 Feiertag, nur Testkinder: testlauf true');
select is((select coach_id from coaching_sessions where id = (:'r_feier'::jsonb ->> 'session_id')::uuid), :'admin'::uuid,
          '6 Admin-Profil als Leitung erlaubt');
select is((select count(*)::int from session_students where session_id = (:'r_feier'::jsonb ->> 'session_id')::uuid), 2,
          '3 doppelte Kinder zählen einmal');
select is((select count(*)::int from slots_einzelbuchungen(:'kt')), 0, '4 Testlauf ist keine Einzelbuchung');
select is(pg_temp.rest(:'kt', '2027-11-01'), 38, '4 Testlauf verbraucht keine Einheit');
select is(pg_temp.code(:'kv', '2027-11-01', (:'r_feier'::jsonb ->> 'session_id')::uuid), 'art_konflikt',
          '1 art_konflikt: echtes Kind, Testlauf-Session');
select is(pg_temp.code(:'kt', '2027-11-04', (:'r_ferien'::jsonb ->> 'session_id')::uuid), 'art_konflikt',
          '1 art_konflikt: Testkind, echte Session');
select is(pg_temp.fehler(format($$select * from kinder_buchbar('2027-11-05', %L)$$, :'r_ferien'::jsonb ->> 'session_id')),
          '22023/datum_session/', '1 p_session_id: Datum muss der Tag der Session sein');

-- Knapp: zwei Einheiten, Stammplatz-Termine Di 09.11. und 16.11. (02.11. liegt in den Herbstferien). Sofort am Sonntag
-- verbraucht eine; termine_planen räumt den Termin ab, für den kein Budget mehr bleibt (16.11.).
select is(pg_temp.code(:'kq', '2027-11-07'), 'ok', '4 Knapp am Sonntag: noch eine Einheit frei');
select sofort_session_anlegen(:'coach_b', pg_temp.raum('Raum 3'), array[:'kq'::uuid, :'kv'::uuid], :sonntag) as r_sonntag \gset
select is((:'r_sonntag'::jsonb ->> 'testlauf')::boolean, false, '3 Sonntag: angelegt');
select is((select array_agg(datum order by datum)::text from kind_termine where student_id = :'kq'), '{2027-11-09}',
          '4 termine_planen: künftiger Stammplatz-Termin ohne Budget fällt weg');
select is((slots_planbilanz(pg_temp.vertrag(:'kq'), '2027-11-07') ->> 'ohne_termin')::int, 0, '4 Knapp: Planbilanz geht auf');
select is(pg_temp.code(:'kq', '2027-11-10'), 'keine_einheit', '1 keine_einheit');
-- Festgeschriebener Slot-Termin (Di 09.11.) mit Session: in genau dieser Session zählt er nicht gegen das Kind.
select termin_session_anlegen('2027-11-09', pg_temp.zeit(16), pg_temp.raum('Raum 1'), '2027-11-09 12:00 Europe/Berlin')
       ->> 'session_id' as s_slot \gset
select is(pg_temp.code(:'kq', '2027-11-09'), 'keine_einheit', '1 Slot-Session: ohne p_session_id zählt der Termin (keine_einheit vor schon_termin)');
select is(pg_temp.code(:'kq', '2027-11-09', :'s_slot'), 'ok', '1 Slot-Session: eigener Slot-Termin zählt weder als Termin noch als Einheit');
select is(pg_temp.fehler(format($$select sofort_session_anlegen(%L, %L, array[%L::uuid], '2027-11-10 10:00 Europe/Berlin')$$,
                                :'coach_a', pg_temp.raum('Raum 1'), :'kq')),
          '22023/keine_einheit/' || :'kq', '5 keine Einheit: Abbruch mit Code und Kind');

-- ── 5) Abbrüche ──────────────────────────────────────────────────────────────
select is(pg_temp.fehler(format($$select sofort_session_anlegen(%L, %L, array[%L, %L]::uuid[], %L)$$,
                                :'coach_a', pg_temp.raum('Raum 1'), :'kv', :'kt', :sonntag)),
          '22023/art_konflikt/', '5 gemischt: art_konflikt');
select is(pg_temp.fehler(format($$select sofort_session_anlegen(%L, %L, '{}'::uuid[], %L)$$, :'coach_a', pg_temp.raum('Raum 1'), :sonntag)),
          '22023/keine_kinder/', '5 leere Liste: keine_kinder');
select is(pg_temp.fehler(format($$select sofort_session_anlegen(%L, %L, null, %L)$$, :'coach_a', pg_temp.raum('Raum 1'), :sonntag)),
          '22023/keine_kinder/', '5 null: keine_kinder');
select is(pg_temp.fehler(format($$select sofort_session_anlegen(%L, %L, array[%L::uuid], %L)$$,
                                :'coach_a', pg_temp.raum('Raum 1'), :'kpv', :sonntag)),
          '22023/kein_kind/', '5 vorläufiges Kind: kein_kind');
select is(pg_temp.fehler(format($$select sofort_session_anlegen(%L, %L, array[%L, %L]::uuid[], %L)$$,
                                :'coach_a', pg_temp.raum('Raum 1'), :'kv', :'kp', '2027-11-08 10:00 Europe/Berlin')),
          '22023/vertrag_ab/' || :'kp', '5 Kind mit vertrag_ab: Abbruch mit Code und student_id');
insert into raeume (name, aktiv_ab, inaktiv_ab) values ('Raum alt', '2026-01-01', '2027-06-01'), ('Raum neu', '2028-01-01', null);
select is(pg_temp.fehler(format($$select sofort_session_anlegen(%L, %L, array[%L::uuid], %L)$$,
                                :'coach_a', pg_temp.raum('Raum alt'), :'kv', '2027-11-08 10:00 Europe/Berlin')),
          '22023/raum_inaktiv/', '5 Raum nicht mehr aktiv');
select is(pg_temp.fehler(format($$select sofort_session_anlegen(%L, %L, array[%L::uuid], %L)$$,
                                :'coach_a', pg_temp.raum('Raum neu'), :'kv', '2027-11-08 10:00 Europe/Berlin')),
          '22023/raum_inaktiv/', '5 Raum noch nicht aktiv');
select is(pg_temp.fehler(format($$select sofort_session_anlegen(%L, %L, array[%L::uuid], %L)$$,
                                :'schueler', pg_temp.raum('Raum 1'), :'kv', '2027-11-08 10:00 Europe/Berlin')),
          '22023/kein_coach/', '6 Leitung mit Rolle student abgelehnt');
select is(pg_temp.fehler(format($$select sofort_session_anlegen(%L, %L, array[%L::uuid], %L)$$,
                                :'eltern', pg_temp.raum('Raum 1'), :'kv', '2027-11-08 10:00 Europe/Berlin')),
          '22023/kein_coach/', '6 Leitung mit Rolle parent abgelehnt');
select is(pg_temp.fehler(format($$select stammschicht_anlegen(%L, 3, %L, %L, '2027-11-10', '2027-11-08 10:00 Europe/Berlin')$$,
                                :'admin', pg_temp.zeit(16), pg_temp.raum('Raum 3'))),
          '22023/kein_coach/', '6 stammschicht_anlegen mit Admin-Profil weiterhin kein_coach');
select is((select count(*)::int from coaching_sessions where scheduled_at >= '2027-11-08' and raum_id is null), 0,
          '5 kein Abbruch hat etwas angelegt');

-- ── 8) session_leitung, stundenplan_woche ────────────────────────────────────
select ok((select bool_and(rolle in ('coach', 'admin')) from session_leitung()), '8 session_leitung: nur Coach und Admin');
select is((select rolle from session_leitung() where id = :'admin'), 'admin', '8 session_leitung: Admin dabei');
select is((select name from session_leitung() where id = :'coach_a'), 'Coach Anna', '8 session_leitung: Name');
-- Eine Slot-Session derselben Woche gehört nicht in den Stundenplan.
insert into coaching_sessions (coach_id, room, scheduled_at, raum_id, slot_zeit_id)
values (:'coach_a', 'Raum 1', '2027-11-03 16:00 Europe/Berlin', pg_temp.raum('Raum 1'), pg_temp.zeit(16));
select stundenplan_woche('2027-11-03') as woche \gset
select is(:'woche'::jsonb ->> 'montag', '2027-11-01', '8 stundenplan_woche: beliebiger Tag → Montag');
select is((select jsonb_agg(s ->> 'session_id') from jsonb_array_elements(:'woche'::jsonb -> 'sessions') s),
          jsonb_build_array(:'r_feier'::jsonb ->> 'session_id', :'r_ferien'::jsonb ->> 'session_id', :'r_sonntag'::jsonb ->> 'session_id'),
          '8 stundenplan_woche: Einzel-Sessions Mo–So nach Beginn, ohne Slot-Session');
select is((select jsonb_build_array(s -> 'coach_rolle', s -> 'testlauf', s -> 'gestartet', jsonb_array_length(s -> 'kinder'))
             from jsonb_array_elements(:'woche'::jsonb -> 'sessions') s where s ->> 'session_id' = :'r_feier'::jsonb ->> 'session_id'),
          '["admin", true, false, 2]'::jsonb, '8 stundenplan_woche: Leitung Admin, Testlauf, nicht gestartet, zwei Kinder');
select is((select k from jsonb_array_elements(:'woche'::jsonb -> 'sessions') s, jsonb_array_elements(s -> 'kinder') k
            where s ->> 'session_id' = :'r_ferien'::jsonb ->> 'session_id'),
          jsonb_build_object('student_id', :'kv', 'name', 'Vera Echt', 'ist_test', false, 'attendance', 'planned'),
          '8 stundenplan_woche: Kind mit Name, Kennzeichen, Anwesenheit');
select is(jsonb_array_length(stundenplan_woche('2027-11-08') -> 'sessions'), 0, '8 stundenplan_woche: Folgewoche leer');

-- ── 7) Rechte ────────────────────────────────────────────────────────────────
select pg_temp.als(:'coach_a');
select is(pg_temp.fehler($$select * from kinder_buchbar('2027-11-07')$$), '42501//', '7 kinder_buchbar: Coach 42501');
select is(pg_temp.fehler($$select * from session_leitung()$$), '42501//', '7 session_leitung: Coach 42501');
select is(pg_temp.fehler($$select stundenplan_woche('2027-11-01')$$), '42501//', '7 stundenplan_woche: Coach 42501');
select is(pg_temp.fehler(format($$select sofort_session_anlegen(%L, %L, array[%L::uuid], %L)$$,
                                :'coach_a', pg_temp.raum('Raum 1'), :'kv', '2027-11-08 10:00 Europe/Berlin')),
          '42501//', '7 sofort_session_anlegen: Coach 42501');
select pg_temp.als(:'eltern');
select is(pg_temp.fehler($$select * from kinder_buchbar('2027-11-07')$$), '42501//', '7 kinder_buchbar: Eltern 42501');
select pg_temp.als(:'admin');
select ok(not has_function_privilege('anon', 'public.sofort_session_anlegen(uuid, uuid, uuid[], timestamptz)', 'execute')
          and not has_function_privilege('anon', 'public.kinder_buchbar(date, uuid)', 'execute')
          and not has_function_privilege('anon', 'public.session_leitung()', 'execute')
          and not has_function_privilege('anon', 'public.stundenplan_woche(date)', 'execute'), '7 anon: kein EXECUTE');
select ok(has_function_privilege('authenticated', 'public.sofort_session_anlegen(uuid, uuid, uuid[], timestamptz)', 'execute')
          and has_function_privilege('authenticated', 'public.kinder_buchbar(date, uuid)', 'execute')
          and has_function_privilege('authenticated', 'public.session_leitung()', 'execute')
          and has_function_privilege('authenticated', 'public.stundenplan_woche(date)', 'execute'), '7 authenticated: EXECUTE');

select * from finish();
rollback;
