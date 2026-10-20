-- ============================================================================
-- Slots W1 — Stammplatz am Raum, Planung je Raum, Funktionen für Wochenplan, Kinder und Coaches.
--
--   1) Stammplatz mit Raum: feste Termine in diesem Raum; Raum fehlt -> 22023 raum_fehlt.
--   2) Voller Raum: SL001 und Planung übersprungen, auch wenn der Nachbarraum frei ist.
--   3) Raum ohne Coach: SL002 (S4 nicht freigegeben).
--   4) zusatztermin_buchen mit Raum (fest, SL001/SL002 je Raum) und ohne Raum (wie bisher).
--   5) stammplatz_aendern mit und ohne p_raum_id.
--   6) stammplatz_vorschau: termin, ferien, feiertag, andere_woche, voll, ohne_coach, ohne_budget.
--   7) slots_kandidaten_alle: genau ein Code je Kind, null genau dann, wenn zusatztermin_buchen gelingt.
--   8) stammschicht_block_anlegen: alles oder nichts (SL009 mit Uhrzeit).
--   9) stammschicht_raum_wechseln ohne und mit Kindern; fester Termin im geschlossenen Raum bleibt ohne Raum.
--  10) slots_woche/slots_termin: Räume mit Kindern ohne Coach, Kennzahlen mit Testkonten; Coach fällt aus.
--  11) Rechte: Coach -> 42501.
-- Stammplätze ohne Raum (Altbestand) prüfen die übrigen slots_*-Tests; dort ist die Raumpflicht aus.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

\ir slots_fixture.sql
-- Die Fixture schaltet die Raumpflicht für die Altbestand-Tests ab; hier gilt sie.
create or replace function public.slots_raum_pflicht() returns boolean language plpgsql stable as $$
begin
  return true;
end $$;
select pg_temp.als(:'admin');
\set jetzt '''2027-10-11 08:00 Europe/Berlin'''

insert into public.raeume (name, aktiv_ab) values ('Raum 4', '2026-01-01');

-- Zeilen mit Raum: pg_temp.rzeilen('3:16:woechentlich:Raum 1')
create or replace function pg_temp.rzeilen(variadic p text[]) returns jsonb language sql as $$
  select jsonb_agg(jsonb_build_object('wochentag', split_part(x, ':', 1)::int,
                                      'slot_zeit_id', pg_temp.zeit(split_part(x, ':', 2)::int),
                                      'takt', split_part(x, ':', 3),
                                      'raum_id', pg_temp.raum(split_part(x, ':', 4))))
    from unnest(p) x
$$;
create or replace function pg_temp.k(p_name text) returns uuid language sql as $$
  select pg_temp.kind(p_name, 'Basic', 12, '2027-09-01', '2028-08-31')
$$;
-- Hinweis (hint) einer Ausnahme, sonst null.
create or replace function pg_temp.hint(p_sql text) returns text language plpgsql as $$
declare h text;
begin
  execute p_sql;
  return null;
exception when others then
  get stacked diagnostics h = pg_exception_hint;
  return h;
end $$;
-- Gelingt zusatztermin_buchen? Probe in einer Untertransaktion, die immer zurückrollt.
create or replace function pg_temp.bucht(p_student uuid, p_datum date, p_zeit uuid, p_raum uuid, p_jetzt timestamptz)
returns boolean language plpgsql as $$
begin
  begin
    perform public.zusatztermin_buchen(p_student, p_datum, p_zeit, p_jetzt, p_raum);
    raise exception using errcode = 'ZZ999';
  exception when sqlstate 'ZZ999' then
    return true;
  end;
exception when others then
  return false;
end $$;
create or replace function pg_temp.termin_raum(p_student uuid, p_datum date) returns text language sql as $$
  select r.name from public.kind_termine kt join public.raeume r on r.id = kt.raum_id
   where kt.student_id = p_student and kt.datum = p_datum and kt.zustand in ('planned', 'present')
$$;

-- ── 1) Stammplatz mit Raum ──────────────────────────────────────────────────────────────────────
select pg_temp.k('Mia Eins') as k1 \gset
select pg_temp.k('Mio Zwei') as k2 \gset
select pg_temp.k('Mila Drei') as k3 \gset
select pg_temp.k('Milo Vier') as k4 \gset
select pg_temp.k('Mira Fuenf') as k5 \gset
select pg_temp.k('Mats Sechs') as k6 \gset
select pg_temp.k('Malte Sieben') as k7 \gset

select throws_ok(format($f$select stammplatz_vergeben(%L, %L, '2027-10-13', %L)$f$, :'k1', pg_temp.zeilen('3:16:woechentlich'), :jetzt),
                 '22023', 'stammplatz_vergeben: Raum fehlt', '1 ohne Raum -> 22023');
select is(pg_temp.hint(format($f$select stammplatz_vergeben(%L, %L, '2027-10-13', %L)$f$, :'k1', pg_temp.zeilen('3:16:woechentlich'), :jetzt)),
          'raum_fehlt', '1 Hinweis raum_fehlt');

select is((select count(*)::int from (values (:'k1'::uuid), (:'k2'), (:'k3'), (:'k4'), (:'k5')) v(s),
                  lateral stammplatz_vergeben(v.s, pg_temp.rzeilen('3:16:woechentlich:Raum 1'), '2027-10-13', :jetzt) x),
          5, '1 fünf Kinder: Stammplatz Mi 16 Uhr in Raum 1');
select is((select raum_id from stammplaetze where student_id = :'k1'), pg_temp.raum('Raum 1'), '1 stammplaetze.raum_id = Raum 1');
select ok((select count(*) from kind_termine where student_id = :'k1' and herkunft = 'stammplatz') > 20,
          '1 Termine bis zum Stichtag geplant');
select is((select count(*)::int from kind_termine where student_id = :'k1' and herkunft = 'stammplatz'
             and (raum_id is distinct from pg_temp.raum('Raum 1') or not raum_fest)), 0,
          '1 jeder Stammplatz-Termin sitzt fest in Raum 1');
select is((select count(*)::int from slot_zuteilung('2027-10-13', pg_temp.zeit(16)) t
            where t.raum_id = pg_temp.raum('Raum 1') and t.grund = 'stift'), 5, '1 Zuteilung: fünf Kinder per Stift in Raum 1');

-- ── 2) Voller Raum ──────────────────────────────────────────────────────────────────────────────
select throws_ok(format($f$select stammplatz_vergeben(%L, %L, '2027-10-13', %L)$f$, :'k6', pg_temp.rzeilen('3:16:woechentlich:Raum 1'), :jetzt),
                 'SL001', null, '2 sechstes Kind in Raum 1 -> SL001 (Raum 2 wäre frei)');
select lives_ok(format($f$select stammplatz_vergeben(%L, %L, '2027-10-13', %L)$f$, :'k6', pg_temp.rzeilen('3:16:woechentlich:Raum 2'), :jetzt),
                '2 sechstes Kind in Raum 2');
select is(pg_temp.termin_raum(:'k6', '2027-10-20'), 'Raum 2', '2 Termin des sechsten Kindes in Raum 2');

-- Planung: Raum 1 ist Do 13.01.2028 17 Uhr durch einen Zusatztermin voll, Raum 2 frei -> übersprungen.
select pg_temp.k('Dora Eins') as d1 \gset
select pg_temp.k('Dirk Zwei') as d2 \gset
select pg_temp.k('Dana Drei') as d3 \gset
select pg_temp.k('Dino Vier') as d4 \gset
select pg_temp.k('Dalia Zusatz') as dz \gset
select pg_temp.k('Xaver Spaet') as dx \gset
select is((select count(*)::int from (values (:'d1'::uuid), (:'d2'), (:'d3'), (:'d4')) v(s),
                  lateral stammplatz_vergeben(v.s, pg_temp.rzeilen('4:17:woechentlich:Raum 1'), '2027-10-14', :jetzt) x),
          4, '2 vier Kinder Do 17 Uhr in Raum 1');
select lives_ok(format($f$select zusatztermin_buchen(%L, '2028-01-13', %L, %L, %L)$f$, :'dz', pg_temp.zeit(17), :jetzt, pg_temp.raum('Raum 1')),
                '2 Zusatztermin Do 13.01.2028 in Raum 1 (fünftes Kind)');
select lives_ok(format($f$select stammplatz_vergeben(%L, %L, '2027-10-14', %L)$f$, :'dx', pg_temp.rzeilen('4:17:woechentlich:Raum 1'), :jetzt),
                '2 Stammplatz Do 17 Uhr Raum 1 (die nächsten sechs Termine haben Platz)');
select is(pg_temp.termin_raum(:'dx', '2028-01-13'), null, '2 kein Termin am 13.01., Raum 1 voll');
select ok(slots_raum_offen('2028-01-13', pg_temp.zeit(17), pg_temp.raum('Raum 2'))
          and slots_raum_belegt('2028-01-13', pg_temp.zeit(17), pg_temp.raum('Raum 2')) = 0,
          '2 ... obwohl Raum 2 offen und leer ist');
select ok((slots_kind(:'dx', :jetzt) -> 'planbilanz' -> 'uebersprungen') ? '2028-01-13', '2 Planbilanz nennt den 13.01. als übersprungen');
select is(pg_temp.termin_raum(:'dx', '2028-01-20'), 'Raum 1', '2 eine Woche später wieder in Raum 1');

-- ── 3) Raum ohne Coach ──────────────────────────────────────────────────────────────────────────
select throws_ok(format($f$select stammplatz_vergeben(%L, %L, '2027-10-13', %L)$f$, :'k7', pg_temp.rzeilen('3:16:woechentlich:Raum 3'), :jetzt),
                 'SL002', null, '3 Raum 3 hat keine Schicht -> SL002');
select is((slots_planbilanz_vorschau(:'k7', pg_temp.rzeilen('3:16:woechentlich:Raum 3'), '2027-10-13', null, :jetzt) -> 'gruende' -> 0 ->> 'code'),
          'SL002', '3 Vorschau nennt SL002 für Raum 3');
select is((slots_planbilanz_vorschau(:'k7', pg_temp.rzeilen('3:16:woechentlich:Raum 1'), '2027-10-13', null, :jetzt) -> 'gruende' -> 0 ->> 'code'),
          'SL001', '3 Vorschau nennt SL001 für den vollen Raum 1');

-- ── 4) Zusatztermin mit und ohne Raum ───────────────────────────────────────────────────────────
select pg_temp.k('Zoe Raum') as z1 \gset
select pg_temp.k('Zeno Frei') as z2 \gset
select throws_ok(format($f$select zusatztermin_buchen(%L, '2027-10-20', %L, %L, %L)$f$, :'z1', pg_temp.zeit(16), :jetzt, pg_temp.raum('Raum 1')),
                 'SL001', null, '4 Zusatztermin in den vollen Raum 1 -> SL001');
select throws_ok(format($f$select zusatztermin_buchen(%L, '2027-10-20', %L, %L, %L)$f$, :'z1', pg_temp.zeit(16), :jetzt, pg_temp.raum('Raum 3')),
                 'SL002', null, '4 Zusatztermin in Raum 3 ohne Coach -> SL002');
select lives_ok(format($f$select zusatztermin_buchen(%L, '2027-10-20', %L, %L, %L)$f$, :'z1', pg_temp.zeit(16), :jetzt, pg_temp.raum('Raum 2')),
                '4 Zusatztermin in Raum 2');
select is((select array[raum_id::text, raum_fest::text] from kind_termine where student_id = :'z1' and datum = '2027-10-20'),
          array[pg_temp.raum('Raum 2')::text, 'true'], '4 Zusatztermin sitzt fest in Raum 2');
select lives_ok(format($f$select zusatztermin_buchen(%L, '2027-10-21', %L, %L)$f$, :'z2', pg_temp.zeit(16), :jetzt),
                '4 Zusatztermin ohne Raum wie bisher');
select is((select array[coalesce(raum_id::text, '-'), raum_fest::text] from kind_termine where student_id = :'z2' and datum = '2027-10-21'),
          array['-', 'false'], '4 ohne Raum: kein Stift, die Zuteilung verteilt');

-- ── 5) stammplatz_aendern ───────────────────────────────────────────────────────────────────────
select pg_temp.k('Anna Aendern') as a1 \gset
select lives_ok(format($f$select stammplatz_vergeben(%L, %L, '2027-10-15', %L)$f$, :'a1', pg_temp.rzeilen('5:18:woechentlich:Raum 1'), :jetzt),
                '5 Stammplatz Fr 18 Uhr Raum 1');
select lives_ok(format($f$select stammplatz_aendern(%L, '2027-11-12', 5, %L, 'woechentlich', %L, %L)$f$,
                       (select id from stammplaetze where student_id = :'a1'), pg_temp.zeit(18), :jetzt, pg_temp.raum('Raum 2')),
                '5 ändern ab 12.11.: Raum 2');
select is(pg_temp.termin_raum(:'a1', '2027-10-22'), 'Raum 1', '5 vorher in Raum 1');
select is(pg_temp.termin_raum(:'a1', '2027-11-12'), 'Raum 2', '5 ab dem 12.11. in Raum 2');
select is((select count(*)::int from stammplaetze where student_id = :'a1' and raum_id = pg_temp.raum('Raum 2') and vorgaenger_id is not null),
          1, '5 neuer Stammplatz mit Vorgänger');
select lives_ok(format($f$select stammplatz_aendern(%L, '2027-11-19', 5, %L, 'a_woche', %L)$f$,
                       (select id from stammplaetze where student_id = :'a1' and gueltig_bis is null), pg_temp.zeit(18), :jetzt),
                '5 ändern ohne p_raum_id (nur Takt)');
select is((select r.name from stammplaetze s join raeume r on r.id = s.raum_id where s.student_id = :'a1' and s.gueltig_bis is null),
          'Raum 2', '5 ohne p_raum_id bleibt der Raum');
insert into stammplaetze (student_id, vertrag_id, wochentag, slot_zeit_id, takt, gueltig_ab)
select :'z2', pg_temp.vertrag(:'z2'), 2, pg_temp.zeit(19), 'woechentlich', '2027-10-12';
select is(pg_temp.hint(format($f$select stammplatz_aendern(%L, '2027-11-16', 2, %L, 'woechentlich', %L)$f$,
                              (select id from stammplaetze where student_id = :'z2'), pg_temp.zeit(19), :jetzt)),
          'raum_fehlt', '5 Altbestand ohne Raum ändern ohne p_raum_id -> raum_fehlt');

-- ── 6) stammplatz_vorschau ──────────────────────────────────────────────────────────────────────
-- A-Takt montags ab 18.10.2027: KW 42 B, 25.10. Herbstferien, 01.11. Allerheiligen, 08.11. A, 15.11. B, 22.11. A.
create temp table vs as select * from stammplatz_vorschau(:'k7', 1, pg_temp.zeit(15), pg_temp.raum('Raum 1'), 'a_woche', '2027-10-18', :jetzt);
select is((select array_agg(ergebnis order by datum) from vs),
          array['andere_woche', 'ferien', 'feiertag', 'termin', 'andere_woche', 'termin'], '6 A-Takt: Gründe je Datum');
select is((select array_agg(datum order by datum) from vs),
          array['2027-10-18', '2027-10-25', '2027-11-01', '2027-11-08', '2027-11-15', '2027-11-22']::date[], '6 sechs Montage ab gültig ab');
select is((select anlass from vs where datum = '2027-11-01'), 'Allerheiligen', '6 Anlass Feiertag');
select is((select anlass from vs where datum = '2027-10-25'), 'Herbst 2027', '6 Anlass Ferien');
select is((select coach_name from vs where datum = '2027-11-08'), 'Coach Anna', '6 Coach aus der Schicht');
select is((select belegt from vs where datum = '2027-11-08'), 0, '6 belegt ohne dieses Kind');
select ok(exists (select 1 from stammplatz_vorschau(:'k7', 3, pg_temp.zeit(16), pg_temp.raum('Raum 1'), 'woechentlich', '2027-10-13', :jetzt)
                   where ergebnis = 'voll' and belegt = 5), '6 voll: Raum 1 Mi 16 Uhr');
select ok((select bool_and(ergebnis in ('ohne_coach', 'ferien', 'feiertag'))
             from stammplatz_vorschau(:'k7', 3, pg_temp.zeit(16), pg_temp.raum('Raum 3'), 'woechentlich', '2027-10-13', :jetzt))
          and exists (select 1 from stammplatz_vorschau(:'k7', 3, pg_temp.zeit(16), pg_temp.raum('Raum 3'), 'woechentlich', '2027-10-13', :jetzt)
                       where ergebnis = 'ohne_coach' and coach_id is null), '6 ohne_coach: Raum 3');
select pg_temp.k('Bea Budget') as kb \gset
-- Einheiten folgen sonst aus dem Paket (vertraege_guard); für den Test ohne Trigger auf zwei setzen.
set local session_replication_role = replica;
update vertraege set einheiten = 2 where student_id = :'kb';
set local session_replication_role = origin;
select is((select array_agg(ergebnis order by datum)
             from stammplatz_vorschau(:'kb', 5, pg_temp.zeit(14), pg_temp.raum('Raum 1'), 'woechentlich', '2027-10-15', :jetzt)),
          array['termin', 'termin', 'ferien', 'ferien', 'ohne_budget', 'ohne_budget'], '6 ohne_budget nach zwei Einheiten');

-- ── 7) slots_kandidaten_alle ────────────────────────────────────────────────────────────────────
select pg_temp.k('Tessa Test') as tk \gset
update students set ist_test = true where id = :'tk';
insert into students (class_level, ist_test) values (7, true) returning id as tohne \gset
set local session_replication_role = replica;  -- vorläufige Zeilen entstehen sonst nur über lead_lsa_freigeben
insert into leads (full_name, first_name, status, class_level) values ('Paul Vorlaeufig', 'Paul', 'vertrag', 7) returning id as lprov \gset
insert into students (class_level, is_provisional, lead_id) values (7, true, :'lprov') returning id as tprov \gset
set local session_replication_role = origin;
select pg_temp.kind('Fritz Frueh', 'Basic', 12, '2028-01-01', '2028-12-31') as kf \gset
create temp table ka as select * from slots_kandidaten_alle('2027-10-27', pg_temp.zeit(16), pg_temp.raum('Raum 2'), :jetzt);
create temp table kb as select * from slots_kandidaten_alle('2027-11-10', pg_temp.zeit(16), pg_temp.raum('Raum 2'), :jetzt);
select is((select count(*) from kb), (select count(distinct student_id) from kb), '7 genau eine Zeile (ein Code) je Kind');
select ok(not exists (select 1 from kb where student_id = :'tprov'), '7 vorläufige Schüler fehlen');
select is((select code from kb where student_id = :'tohne'), 'kein_vertrag', '7 Testkonto ohne Vertrag: kein_vertrag');
select is((select array[code, datum::text] from kb where student_id = :'kf'), array['vertrag_ab', '2028-01-01'], '7 Vertrag ab 01.01.2028');
select is((select code from kb where student_id = :'k6'), 'SL003', '7 schon im Termin: SL003');
select is((select code from kb where student_id = :'tk'), 'SL013', '7 Testkonto neben echten Kindern: SL013');
select is((select code from kb where student_id = :'k7'), null, '7 buchbar: null');
select is((select code from ka where student_id = :'k7'), 'SL002', '7 Ferientag (kein Betrieb): kein Raum offen, SL002');
select is((select code from slots_kandidaten_alle('2027-11-10', pg_temp.zeit(16), pg_temp.raum('Raum 1'), :jetzt) where student_id = :'k7'),
          'SL001', '7 voller Raum 1: SL001');
select is((select stammplatz_kurz from kb where student_id = :'k6'), 'Mi 16:00 · Raum 2', '7 Stammplatz kurz');
select is((select count(*)::int from kb where (code is null) <> pg_temp.bucht(student_id, '2027-11-10', pg_temp.zeit(16), pg_temp.raum('Raum 2'), :jetzt)),
          0, '7 code null genau dann, wenn zusatztermin_buchen gelingt');
select ok((select count(*) from kb where code is null) > 0 and (select count(*) from kb where code is not null) > 0,
          '7 beide Fälle kommen vor');

-- ── 8) stammschicht_block_anlegen ───────────────────────────────────────────────────────────────
select lives_ok(format($f$select stammschicht_anlegen(%L, 2, %L, %L, '2027-10-18', %L)$f$, :'coach_d', pg_temp.zeit(17), pg_temp.raum('Raum 3'), :jetzt),
                '8 Einzelschicht Coach Dana Di 17 Uhr Raum 3');
select throws_ok(format($f$select stammschicht_block_anlegen(%L, 2, %L, %L, %L, '2027-10-18', %L)$f$,
                        :'coach_c', pg_temp.zeit(15), pg_temp.zeit(18), pg_temp.raum('Raum 3'), :jetzt),
                 'SL009', null, '8 Block Di 15–19 Uhr Raum 3 kollidiert um 17 Uhr -> SL009');
select is(pg_temp.hint(format($f$select stammschicht_block_anlegen(%L, 2, %L, %L, %L, '2027-10-18', %L)$f$,
                              :'coach_c', pg_temp.zeit(15), pg_temp.zeit(18), pg_temp.raum('Raum 3'), :jetzt)),
          'raum:17:00', '8 Hinweis mit Uhrzeit (Raum)');
select is((select count(*)::int from stammschichten where coach_id = :'coach_c'), 0, '8 alles oder nichts: keine Schicht angelegt');
select is(pg_temp.hint(format($f$select stammschicht_block_anlegen(%L, 1, %L, %L, %L, '2027-10-18', %L)$f$,
                              :'coach_a', pg_temp.zeit(14), pg_temp.zeit(15), pg_temp.raum('Raum 3'), :jetzt)),
          'coach:14:00', '8 Coach Anna ist Mo 14 Uhr schon in Raum 1 -> Hinweis coach');
select is(pg_temp.hint(format($f$select stammschicht_block_anlegen(%L, 1, %L, %L, %L, '2027-10-18', %L)$f$,
                              :'coach_c', pg_temp.zeit(17), pg_temp.zeit(14), pg_temp.raum('Raum 3'), :jetzt)),
          'von_bis', '8 bis vor von -> von_bis');
select is((stammschicht_block_anlegen(:'coach_c', 1, pg_temp.zeit(14), pg_temp.zeit(17), pg_temp.raum('Raum 3'), '2027-10-18', :jetzt) ->> 'stunden')::int,
          4, '8 Block Mo 14–18 Uhr Raum 3: vier Stunden');
select is((select array_agg(public.slots_hhmm(z.beginn) order by z.beginn) from stammschichten s join slot_zeiten z on z.id = s.slot_zeit_id
            where s.coach_id = :'coach_c'), array['14:00', '15:00', '16:00', '17:00'], '8 eine Zeile je Stunde');

-- ── 9) stammschicht_raum_wechseln ───────────────────────────────────────────────────────────────
select pg_temp.k('Moritz Bleibt') as m1 \gset
select pg_temp.k('Merle Bleibt') as m2 \gset
select is((select count(*)::int from (values (:'m1'::uuid), (:'m2')) v(s),
                  lateral stammplatz_vergeben(v.s, pg_temp.rzeilen('1:15:woechentlich:Raum 3'), '2027-11-08', :jetzt) x),
          2, '9 zwei Kinder Mo 15 Uhr in Raum 3 (Coach Cem)');
select throws_ok(format($f$select stammschicht_raum_wechseln(%L, %L, '2027-11-22', false, %L)$f$,
                        (select array_agg(id) from stammschichten where coach_id = :'coach_c'), pg_temp.raum('Raum 1'), :jetzt),
                 'SL009', null, '9 Zielraum Raum 1 ist besetzt -> SL009');
select is(pg_temp.hint(format($f$select stammschicht_raum_wechseln(%L, %L, '2027-11-22', false, %L)$f$,
                              (select array_agg(id) from stammschichten where coach_id = :'coach_c'), pg_temp.raum('Raum 3'), :jetzt)),
          'gleicher_raum', '9 gleicher Raum -> gleicher_raum');
select is((stammschicht_raum_wechseln((select array_agg(id) from stammschichten where coach_id = :'coach_c'),
                                      pg_temp.raum('Raum 4'), '2027-11-22', false, :jetzt) ->> 'kinder')::int,
          0, '9 Coach Cem wechselt ab 22.11. nach Raum 4, ohne Kinder');
select is((select r.name from stammplaetze s join raeume r on r.id = s.raum_id where s.student_id = :'m1'), 'Raum 3',
          '9 ohne Häkchen: Stammplatz bleibt in Raum 3');
select is(pg_temp.termin_raum(:'m1', '2027-11-15'), 'Raum 3', '9 vor dem Wechsel in Raum 3');
select is(pg_temp.termin_raum(:'m1', '2027-11-29'), 'Raum 3', '9 nach dem Wechsel weiter eingeplant, Raum 3');
select is((select array[coalesce(t.raum_id::text, '-'), t.grund] from slot_zuteilung('2027-11-29', pg_temp.zeit(15)) t where t.student_id = :'m1'),
          array['-', 'raum_zu'], '9 fester Termin im Raum ohne Coach: ohne Raum, nicht still in Raum 4');
select ok(slots_raum_offen('2027-11-29', pg_temp.zeit(15), pg_temp.raum('Raum 4')), '9 ... obwohl Raum 4 offen ist');
select is((select jsonb_build_object('offen', r -> 'offen', 'belegt', r -> 'belegt', 'art', r -> 'art')
             from jsonb_array_elements(slots_woche('2027-11-29', :jetzt) -> 'zellen') c, jsonb_array_elements(c -> 'raeume') r
            where c ->> 'datum' = '2027-11-29' and c ->> 'zeit_id' = pg_temp.zeit(15)::text and r ->> 'name' = 'Raum 3'),
          '{"offen": false, "belegt": 2, "art": "ohne_schicht"}'::jsonb, '9 Wochenplan: Raum 3 mit zwei Kindern, ohne Coach');
select is((slots_woche('2027-11-29', :jetzt) -> 'kopf' ->> 'raeume_ohne_coach')::int, 1,
          '9 Kennzahl: ein Raum mit Kindern ohne Coach (Mo 15 Uhr, Raum 3)');
select is((select jsonb_array_length(r -> 'kinder') from jsonb_array_elements(slots_termin('2027-11-29', pg_temp.zeit(15), :jetzt) -> 'raeume') r
            where r ->> 'name' = 'Raum 3'), 2, '9 Slot-Panel: Raum 3 mit seinen zwei Kindern');
select is(jsonb_array_length(slots_termin('2027-11-29', pg_temp.zeit(15), :jetzt) -> 'ohne_raum'), 0, '9 Slot-Panel: nicht doppelt unter ohne Raum');
select ok(exists (select 1 from jsonb_array_elements(slots_tag('2027-11-29', :jetzt) -> 'raum_termine') r
                   where r ->> 'raum_name' = 'Raum 3' and r ->> 'beginn' = '15:00' and not (r ->> 'offen')::boolean
                     and (r ->> 'belegt')::int = 2), '9 Tagespanel: Raum 3 ohne Coach mit zwei Kindern');

select pg_temp.k('Nina Zieht') as n1 \gset
select lives_ok(format($f$select stammplatz_vergeben(%L, %L, '2027-11-09', %L)$f$, :'n1', pg_temp.rzeilen('2:17:woechentlich:Raum 3'), :jetzt),
                '9 Nina Di 17 Uhr Raum 3 (Coach Dana)');
select is((stammschicht_raum_wechseln((select array_agg(id) from stammschichten where coach_id = :'coach_d'),
                                      pg_temp.raum('Raum 4'), '2027-11-23', true, :jetzt) ->> 'kinder')::int,
          1, '9 Coach Dana wechselt ab 23.11. nach Raum 4, mit Kindern');
select is((select array[r.name, (s.vorgaenger_id is not null)::text] from stammplaetze s join raeume r on r.id = s.raum_id
            where s.student_id = :'n1' and s.gueltig_bis is null), array['Raum 4', 'true'], '9 neuer Stammplatz in Raum 4 mit Vorgänger');
select is((select gueltig_bis from stammplaetze where student_id = :'n1' and raum_id = pg_temp.raum('Raum 3')), '2027-11-22'::date,
          '9 alter Stammplatz endet am Vortag');
select is(pg_temp.termin_raum(:'n1', '2027-11-16'), 'Raum 3', '9 vor dem Wechsel in Raum 3');
select is(pg_temp.termin_raum(:'n1', '2027-11-30'), 'Raum 4', '9 nach dem Wechsel in Raum 4');
select is((select (s ->> 'kinder')::int from jsonb_array_elements(slots_coaches('2027-11-29', :jetzt) -> 'coaches') c,
                  jsonb_array_elements(c -> 'stammschichten') s
            where c ->> 'id' = :'coach_d' and s ->> 'raum_name' = 'Raum 4'), 1, '9 slots_coaches zählt die Kinder je Schicht');

-- ── 10) Coach fällt aus, Kennzahlen, Stammplatz mit Raum und Coach ────────────────────────────────
select (slots_woche('2027-11-08', :jetzt) -> 'kopf' ->> 'raeume_ohne_coach')::int as vorher \gset
select lives_ok(format($f$select termin_coach_setzen('2027-11-10', %L, %L, null, %L)$f$, pg_temp.zeit(16), pg_temp.raum('Raum 1'), :jetzt),
                '10 Coach Anna fällt Mi 10.11. 16 Uhr aus');
select is((slots_woche('2027-11-08', :jetzt) -> 'kopf' ->> 'raeume_ohne_coach')::int, :vorher + 1, '10 Kennzahl steigt um eins');
select is((select jsonb_build_object('offen', r -> 'offen', 'belegt', r -> 'belegt', 'coach', r -> 'coach_name')
             from jsonb_array_elements(slots_woche('2027-11-08', :jetzt) -> 'zellen') c, jsonb_array_elements(c -> 'raeume') r
            where c ->> 'datum' = '2027-11-10' and c ->> 'zeit_id' = pg_temp.zeit(16)::text and r ->> 'name' = 'Raum 1'),
          '{"offen": false, "belegt": 5, "coach": null}'::jsonb, '10 Raum 1 rot gefüllt: fünf Kinder, kein Coach');
select is((select r ->> 'coach_name' from jsonb_array_elements(slots_woche('2027-11-08', :jetzt) -> 'zellen') c, jsonb_array_elements(c -> 'raeume') r
            where c ->> 'datum' = '2027-11-10' and c ->> 'zeit_id' = pg_temp.zeit(16)::text and r ->> 'name' = 'Raum 2'),
          'Coach Ben', '10 coach_name je Raum');
select slots_woche('2027-11-08', :jetzt) -> 'kopf' as kopf \gset
select is((:'kopf'::jsonb ->> 'belegt_test')::int,
          (select sum((c ->> 'test')::int)::int from jsonb_array_elements(slots_woche('2027-11-08', :jetzt) -> 'zellen') c),
          '10 belegt_test = Testkonten der Woche');
select is((:'kopf'::jsonb ->> 'auslastung_mit_test')::numeric,
          round(((:'kopf'::jsonb ->> 'belegt')::int + (:'kopf'::jsonb ->> 'belegt_test')::int)::numeric / (:'kopf'::jsonb ->> 'plaetze')::int, 3),
          '10 Auslastung mit Testkonten');
select is((:'kopf'::jsonb ->> 'ohne_stammplatz_test')::int, 1, '10 ohne Stammplatz: ein Testkonto (Tessa)');
select is((select jsonb_build_object('raum', s -> 'raum_name', 'coach', s -> 'coach_name')
             from jsonb_array_elements(slots_kind(:'k6', :jetzt) -> 'stammplaetze') s),
          '{"raum": "Raum 2", "coach": "Coach Ben"}'::jsonb, '10 Stammplatz nennt Raum und Coach der Schicht');
select is((select s ->> 'coach_name' from jsonb_array_elements(slots_kind(:'m1', :jetzt) -> 'stammplaetze') s), 'Coach Cem',
          '10 Coach der Schicht am ersten Tag des Stammplatzes');
-- Stammplatz in einem Raum ohne Schicht (nur direkt anlegbar, die Funktionen sperren das mit SL002).
insert into stammplaetze (student_id, vertrag_id, wochentag, slot_zeit_id, takt, gueltig_ab, raum_id)
select :'z1', pg_temp.vertrag(:'z1'), 5, pg_temp.zeit(19), 'woechentlich', '2027-10-15', pg_temp.raum('Raum 3');
select is((select jsonb_build_object('raum', s -> 'raum_name', 'coach', s -> 'coach_id')
             from jsonb_array_elements(slots_kind(:'z1', :jetzt) -> 'stammplaetze') s),
          '{"raum": "Raum 3", "coach": null}'::jsonb, '10 Raum ohne Schicht: kein Coach');
select ok((select (z ->> 'laeuft')::boolean is not null from jsonb_array_elements(slots_woche('2027-11-08', :jetzt) -> 'zellen') z limit 1),
          '10 Zellen tragen laeuft');

-- ── 11) Rechte ──────────────────────────────────────────────────────────────────────────────────
select pg_temp.als(:'coach_a');
select throws_ok(format($f$select * from slots_kandidaten_alle('2027-11-10', %L, %L)$f$, pg_temp.zeit(16), pg_temp.raum('Raum 2')),
                 '42501', null, '11 Coach: slots_kandidaten_alle -> 42501');
select throws_ok(format($f$select * from stammplatz_vorschau(%L, 1, %L, %L, 'woechentlich', '2027-11-08')$f$, :'k7', pg_temp.zeit(15), pg_temp.raum('Raum 1')),
                 '42501', null, '11 Coach: stammplatz_vorschau -> 42501');
select throws_ok(format($f$select stammschicht_block_anlegen(%L, 5, %L, %L, %L)$f$, :'coach_a', pg_temp.zeit(14), pg_temp.zeit(15), pg_temp.raum('Raum 4')),
                 '42501', null, '11 Coach: stammschicht_block_anlegen -> 42501');
select throws_ok(format($f$select stammschicht_raum_wechseln(%L, %L, '2027-12-01', true)$f$,
                        (select array_agg(id) from stammschichten where coach_id = :'coach_a'), pg_temp.raum('Raum 4')),
                 '42501', null, '11 Coach: stammschicht_raum_wechseln -> 42501');
select throws_ok(format($f$select zusatztermin_buchen(%L, '2027-11-10', %L, null, %L)$f$, :'k7', pg_temp.zeit(16), pg_temp.raum('Raum 2')),
                 '42501', null, '11 Coach: zusatztermin_buchen mit Raum -> 42501');
select throws_ok(format($f$select stammplatz_aendern(%L, '2027-12-01', 3, %L, 'woechentlich', null, %L)$f$,
                        (select id from stammplaetze where student_id = :'k6'), pg_temp.zeit(16), pg_temp.raum('Raum 2')),
                 '42501', null, '11 Coach: stammplatz_aendern mit Raum -> 42501');

select * from finish();
rollback;
