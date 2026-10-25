-- ============================================================================
-- P4 Batus Freigabeliste (Migration 20261025210952): die 24 Bereiche aus docs/lsa/freigabeliste-batu-1025.md
-- haben eine aktive batu_lsa-Sollzeile (2, davon 1 ohne MC), in der Reihenfolge der Liste, und stehen damit in
-- Lenas Prüflauf. Je Knoten höchstens eine aktive LSA-Zeile. Am Ende rollback.
--
-- Lauf: npx supabase test db
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(6);

create temp table l (skill_key text, gruppe text) on commit drop;
insert into l values
  ('term_binom_faktorisieren', 'KA2'), ('term_binom_quadratdifferenz', 'KA2'), ('term_ausklammern', 'KA2'),
  ('gleichung_quadr_formel', 'KA2'),
  ('fkt_linear_gleichung', 'R'), ('fkt_linear_steigung', 'R'), ('fkt_linear_yabschnitt', 'R'),
  ('geo_flaeche_drachen_raute', 'R'), ('geo_flaeche_term', 'R'), ('geo_flaeche_trapez', 'R'),
  ('geo_winkel_dreieck', 'R'), ('geo_winkel_thales', 'R'), ('gleichung_lgs_addition', 'R'),
  ('gleichung_lgs_einsetzen', 'R'), ('gleichung_lgs_grafisch', 'R'), ('stoch_pfad_summe', 'R'),
  ('term_binom_gemischt', 'R'), ('prozent_zins_jahreszins', 'R'), ('prozent_zins_zinseszins', 'R'),
  ('fkt_quadr_normalform', 'A'), ('fkt_quadr_nullstellen', 'A'), ('geo_kreis_flaeche', 'A'),
  ('geo_kreis_umfang', 'A'), ('zahl_potenz_rechnen', 'A');

-- Im CI-Neuaufbau fehlen ggf. Knoten; geprüft wird jeder vorhandene.
select is((select count(*)::int from l join skills s using (skill_key)
            left join pruef_soll p on p.skill_key = l.skill_key and p.anlass = 'batu_lsa' and p.aktiv
           where p.skill_key is null), 0, 'jeder vorhandene Bereich hat eine aktive batu_lsa-Zeile');
select is((select count(*)::int from pruef_soll p join l using (skill_key)
           where p.anlass = 'batu_lsa' and (p.soll, p.min_ohne_mc, p.einsatz) <> (2, 1, 'lsa')), 0,
  'Soll 2, davon 1 ohne MC, Einsatz LSA');
select ok((select max(p.sort) from pruef_soll p join l using (skill_key) where p.anlass = 'batu_lsa' and l.gruppe = 'KA2')
        < (select min(p.sort) from pruef_soll p join l using (skill_key) where p.anlass = 'batu_lsa' and l.gruppe = 'R'),
  'KA2 vor Rückblick');
select ok((select max(p.sort) from pruef_soll p join l using (skill_key) where p.anlass = 'batu_lsa' and l.gruppe = 'R')
        < (select min(p.sort) from pruef_soll p join l using (skill_key) where p.anlass = 'batu_lsa' and l.gruppe = 'A'),
  'Rückblick vor Ausblick');
select is((select count(*)::int from (select p.skill_key from pruef_soll p where p.aktiv and p.einsatz = 'lsa'
            group by p.skill_key having count(*) > 1) x), 0, 'je Knoten höchstens eine aktive LSA-Zeile');
select is((select count(*)::int from tasks t join l using (skill_key)
           where 'lsa' = any (t.einsatz) and t.status in ('draft', 'review', 'rueckfrage') and not t.pruef_pilot), 0,
  'offene LSA-Aufgaben der Bereiche tragen das Pilot-Flag');

select * from finish();
rollback;
