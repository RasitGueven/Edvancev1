-- Slots SL2b, Entscheidung 6: Testkonten aus den Slots räumen.
--
-- Aufruf über tools/slots-testkonten-raeumen.mjs (eine Transaktion, psql -1). Variable trocken (on|off):
--   on   nur Anzahlen, nichts ändern
--   off  1. jeden laufenden oder künftigen Stammplatz eines Testkontos ab heute beenden (stammplatz_beenden;
--           die Planung entfernt dabei die beweglichen Termine)
--        2. jeden übrigen künftigen, nicht festgeschriebenen geplanten Termin eines Testkontos ausfallen lassen
--           (termin_ausgefallen, "ausgefallen durch uns"; Zusatztermine und Umbuchungen löscht keine Slot-Funktion)
-- Kein direktes DELETE oder UPDATE: alles läuft über die Slot-Funktionen und ihre Regeln (Sperre, Planung).
-- Festgeschriebene Termine (mit Session) bleiben, sie gehören zum heutigen Tag.
-- Die pgTAP-Datei supabase/tests/slots_sl2b.test.sql bindet diese Datei ein (Test 5).

-- Aufruf aus dem Werkzeug (als_system gesetzt): ausdrücklich Systemaufruf, nur für diese Transaktion. In Prod
-- liefert auth.role() ohne JWT ohnehin NULL; die CI-Grundlage fällt dagegen auf 'anon' zurück.
\if :{?als_system}
select set_config('request.jwt.claim.role', 'service_role', true) \g /dev/null
\endif

create temp table if not exists slots_raeumen_stand (schritt text primary key, n integer) on commit drop;

create or replace view pg_temp.slots_raeumen_zahlen as
select
  (select count(*) from public.stammplaetze s join public.students st on st.id = s.student_id and st.ist_test
    where coalesce(s.gueltig_bis, 'infinity'::date) >= public.slots_berlin_tag(now())
      and s.gueltig_bis is distinct from s.gueltig_ab - 1)                                      as test_stammplaetze,
  (select count(*) from public.kind_termine kt join public.students st on st.id = kt.student_id and st.ist_test
    where kt.zustand = 'planned' and kt.session_id is null
      and public.slots_termin_beginn(kt.datum, kt.slot_zeit_id) > now())                        as test_termine_offen,
  (select count(*) from public.kind_termine kt join public.students st on st.id = kt.student_id and st.ist_test
    where kt.zustand = 'planned' and kt.session_id is not null
      and public.slots_termin_beginn(kt.datum, kt.slot_zeit_id) > now())                        as test_termine_festgeschrieben,
  (select count(*) from public.kind_termine kt join public.students st on st.id = kt.student_id and not st.ist_test
    where kt.zustand = 'planned' and public.slots_termin_beginn(kt.datum, kt.slot_zeit_id) > now()) as echte_termine_offen;

select 'ziel ' || current_database() || coalesce(' @ ' || host(inet_server_addr()), ' (Socket)');
select 'vorher ' || row_to_json(z)::text from pg_temp.slots_raeumen_zahlen z;

\if :trocken
select 'trocken: nichts geändert';
\else
do $$
declare
  r record;
  n integer := 0;
begin
  for r in
    select s.id from public.stammplaetze s join public.students st on st.id = s.student_id and st.ist_test
     where coalesce(s.gueltig_bis, 'infinity'::date) >= public.slots_berlin_tag(now())
       and s.gueltig_bis is distinct from s.gueltig_ab - 1
     order by s.student_id, s.gueltig_ab, s.id
  loop
    perform public.stammplatz_beenden(r.id, public.slots_berlin_tag(now()));
    n := n + 1;
  end loop;
  insert into slots_raeumen_stand values ('stammplaetze_beendet', n);

  n := 0;
  for r in
    select kt.id from public.kind_termine kt join public.students st on st.id = kt.student_id and st.ist_test
     where kt.zustand = 'planned' and kt.session_id is null
       and public.slots_termin_beginn(kt.datum, kt.slot_zeit_id) > now()
     order by kt.datum, kt.id
  loop
    -- Die Planung nach dem vorigen Aufruf kann den Termin schon entfernt haben.
    continue when not exists (select 1 from public.kind_termine x
                               where x.id = r.id and x.zustand = 'planned' and x.session_id is null);
    perform public.termin_ausgefallen(r.id);
    n := n + 1;
  end loop;
  insert into slots_raeumen_stand values ('termine_ausgefallen', n);
end;
$$;
select 'geaendert ' || json_object_agg(schritt, n)::text from slots_raeumen_stand;
\endif

select 'nachher ' || row_to_json(z)::text from pg_temp.slots_raeumen_zahlen z;
