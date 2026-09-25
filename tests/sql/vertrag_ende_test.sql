-- Abnahme fuer vertrag_ende_berechnen() und vertrag_widerruf_bis()
-- (Migration 20260925120000_vertraege_erweiterung.sql).
--
-- Ausfuehren:  psql "$DATABASE_URL" -f tests/sql/vertrag_ende_test.sql
--
-- Die Datei schreibt keine Daten. Sie besteht aus zwei Teilen:
--
--   1. Ein DO-Block, der den erwarteten Tabellen-Fehler abfaengt. Exceptions
--      sind in reinem SQL nicht fangbar; set_config() legt das Ergebnis in den
--      Sitzungszustand, nicht in eine Tabelle.
--   2. EINE lesende Abfrage, die jeden Fall als ist/soll gegenueberstellt und
--      OK oder FEHLER ausgibt. Die Zeilen I pruefen die EXECUTE-Rechte der neuen
--      Funktionen: Supabase vergibt sie per Default Privileges direkt an anon
--      und authenticated, und ein Grant, den niemand prueft, faellt erst auf,
--      wenn er ausgenutzt wird.
--
-- Abnahme: die Spalte `ergebnis` enthaelt ausschliesslich OK.

do $$
begin
  perform * from public.vertrag_ende_berechnen(date '2030-03-01', 6);
  perform set_config('edvance.test_tabellenende', 'kein Fehler geworfen', false);
exception
  when others then
    perform set_config('edvance.test_tabellenende', 'Fehler ' || sqlstate, false);
end;
$$;

with faelle (nr, fall, beginn, laufzeit, soll_nominal, soll_tage, soll_ende) as (
  values
    (1, 'A  01.11.2027 Halbjahr', date '2027-11-01',  6, date '2028-04-30', 35, date '2028-06-15'),
    (2, 'B  01.01.2027 Halbjahr', date '2027-01-01',  6, date '2027-06-30', 63, date '2027-09-15'),
    (3, 'C  01.04.2027 Halbjahr', date '2027-04-01',  6, date '2027-09-30', 62, date '2027-12-15'),
    (4, 'D  01.09.2027 Halbjahr', date '2027-09-01',  6, date '2028-02-29', 31, date '2028-03-31'),
    (5, 'E  01.10.2027 Jahr',     date '2027-10-01', 12, date '2028-09-30',  0, date '2028-09-30')
),
einzelfaelle as (
  select f.nr, f.fall, r.nominal, r.ferientage, r.ende,
         f.soll_nominal, f.soll_tage, f.soll_ende
    from faelle f
    cross join lateral public.vertrag_ende_berechnen(f.beginn, f.laufzeit) r
),
monatserste as (
  select d::date as beginn
    from generate_series(date '2026-10-01', date '2029-06-01', interval '1 month') d
),
sweep as (
  select m.beginn,
         r.ende,
         extract(day from r.ende)::integer as tag,
         extract(day from (date_trunc('month', r.ende) + interval '1 month')::date - 1)::integer as monatsletzter,
         exists (select 1 from public.ferien_nrw f where r.ende between f.von and f.bis) as in_ferien
    from monatserste m
    cross join lateral public.vertrag_ende_berechnen(m.beginn, 6) r
),
rechte_soll (fname, sig, rolle, soll) as (
  values
    ('vertrag_ende_berechnen', 'public.vertrag_ende_berechnen(date,integer)', 'anon',          false),
    ('vertrag_ende_berechnen', 'public.vertrag_ende_berechnen(date,integer)', 'authenticated', true),
    ('vertrag_widerruf_bis',   'public.vertrag_widerruf_bis(date)',           'anon',          false),
    ('vertrag_widerruf_bis',   'public.vertrag_widerruf_bis(date)',           'authenticated', true),
    ('audit_log_schreiben',    'public.audit_log_schreiben(text,text,uuid)',  'anon',          false),
    ('audit_log_schreiben',    'public.audit_log_schreiben(text,text,uuid)',  'authenticated', true),
    ('zugangscode_erzeugen',   'public.zugangscode_erzeugen()',               'anon',          false),
    ('zugangscode_erzeugen',   'public.zugangscode_erzeugen()',               'authenticated', false)
),
rechte as (
  -- LEFT JOIN statt has_function_privilege('anon', ...): fehlt die Rolle, gibt
  -- es eine FEHLER-Zeile statt einer Exception, die den ganzen Test abbricht.
  select rs.fname, rs.rolle, rs.soll,
         case when r.oid is null
              then null
              else has_function_privilege(r.oid, rs.sig::regprocedure::oid, 'execute')
         end as ist
    from rechte_soll rs
    left join pg_roles r on r.rolname = rs.rolle
),
zeilen as (
  -- A-E: nominal, Ferientage und Ende gegen die Referenzwerte
  select e.nr,
         e.fall,
         format('nominal=%s  ferientage=%s  ende=%s', e.nominal, e.ferientage, e.ende) as ist,
         format('nominal=%s  ferientage=%s  ende=%s', e.soll_nominal, e.soll_tage, e.soll_ende) as soll,
         case when e.nominal = e.soll_nominal
               and e.ferientage = e.soll_tage
               and e.ende = e.soll_ende then 'OK' else 'FEHLER' end as ergebnis
    from einzelfaelle e

  union all

  -- F: jeder Monatserste 01.10.2026 .. 01.06.2029 als Halbjahr
  select 100 + (row_number() over (order by s.beginn))::integer,
         'F  Halbjahr ab ' || to_char(s.beginn, 'DD.MM.YYYY'),
         format('ende=%s  tag=%s  monatsletzter=%s  in_ferien=%s',
                s.ende, s.tag, s.monatsletzter, s.in_ferien),
         'ende nicht in Ferien, Tag = 15 oder Monatsletzter',
         case when not s.in_ferien and (s.tag = 15 or s.tag = s.monatsletzter)
              then 'OK' else 'FEHLER' end
    from sweep s

  union all

  -- G: jenseits der Ferientabelle wird geworfen, nicht gerechnet
  select 200,
         'G  01.03.2030 Halbjahr wirft Tabellen-Fehler',
         coalesce(current_setting('edvance.test_tabellenende', true), 'nicht ausgefuehrt'),
         'Fehler P0001',
         case when current_setting('edvance.test_tabellenende', true) = 'Fehler P0001'
              then 'OK' else 'FEHLER' end

  union all

  -- H: Widerrufsfrist, inklusive Schaltjahr
  select 201,
         'H  vertrag_widerruf_bis 01.11.2027',
         public.vertrag_widerruf_bis(date '2027-11-01')::text,
         '2027-11-30',
         case when public.vertrag_widerruf_bis(date '2027-11-01') = date '2027-11-30'
              then 'OK' else 'FEHLER' end

  union all

  select 202,
         'H  vertrag_widerruf_bis 01.02.2028 (Schaltjahr)',
         public.vertrag_widerruf_bis(date '2028-02-01')::text,
         '2028-03-01',
         case when public.vertrag_widerruf_bis(date '2028-02-01') = date '2028-03-01'
              then 'OK' else 'FEHLER' end

  union all

  -- I: EXECUTE-Rechte. Nur vertrag_ende_berechnen und vertrag_widerruf_bis
  --    gehoeren dem Frontend; audit_log_schreiben zusaetzlich mit Admin-Gate im
  --    Rumpf; zugangscode_erzeugen keiner Rolle.
  select 300 + (row_number() over (order by r.fname, r.rolle))::integer,
         format('I  EXECUTE %s fuer %s', r.fname, r.rolle),
         case when r.ist is null then 'Rolle nicht vorhanden' else r.ist::text end,
         r.soll::text,
         case when r.ist is not distinct from r.soll then 'OK' else 'FEHLER' end
    from rechte r
)
select nr, fall, ist, soll, ergebnis
  from zeilen
 order by nr;
