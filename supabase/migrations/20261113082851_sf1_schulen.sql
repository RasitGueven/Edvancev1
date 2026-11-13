-- ============================================================================
-- SF-1 · S1 Daten: Realschulen, Gesamtschulen und Sekundarschulen in Köln, Gesamtschulen in Kerpen
-- ============================================================================
-- Erzeugt von scripts/schulformen/schulen_sql.py — nicht von Hand ändern.
-- Fundstelle: Schulverzeichnis NRW (Open Data des MSB),
--   https://www.schulministerium.nrw.de/BiPo/OpenData/Schuldaten/schuldaten.csv, abgerufen 13.11.2026 08:22 UTC,
--   SHA-256 8732daec4f1b67df090280fa415407858a251449ddbfaa010a378df116502c59.
--   Auszug: docs/schulformen/sf1/quellen/schulverzeichnis-auszug.csv (Schulform 10/14/15, Gemeinde Köln 05315000;
--   Schulform 15, Gemeinde Kerpen 05362032). Köln: 20 Realschulen, 25 Gesamtschulen, keine Sekundarschule;
--   Kerpen: 1 Gesamtschule. Alle mit Schulbetriebsschlüssel 1.
-- Felder wie bei den Gymnasien (20261001125708): name, ort, schulform, traeger, website; stadtteil steht nicht im
-- Verzeichnis und bleibt leer. Neu: schulnummer. Eine Schule, deren Schulnummer schon da ist, wird übersprungen;
-- ein Namensgleicher am selben Ort ebenfalls (die Prüfabfrage zählt die Schulnummern nach).
-- Rollback: supabase/rollback/20261113082851_sf1_schulen.sql

insert into public.schulen (schulnummer, name, ort, schulform, traeger, website)
select v.schulnummer, v.name, v.ort, v.schulform, v.traeger, v.website
  from (values
  ('160064', 'Henry-Ford-Realschule', 'Köln', 'Realschule', 'öffentlich', 'http://www.henry-ford-realschule.de'),
  ('160076', 'Geschwister-Scholl-Schule', 'Köln', 'Realschule', 'öffentlich', 'http://www.geschwisterschollrealschule.de'),
  ('160090', 'Ferdinand-Lassalle-Realschule', 'Köln', 'Realschule', 'öffentlich', 'http://rs-lassallestrasse.koeln'),
  ('160106', 'Elly-Heuss-Knapp-Realschule', 'Köln', 'Realschule', 'öffentlich', 'http://www.ehk-koeln.de'),
  ('160118', 'Realschule Im Hasental', 'Köln', 'Realschule', 'öffentlich', 'http://www.hasental.de'),
  ('160120', 'Edith-Stein-Realschule', 'Köln', 'Realschule', 'öffentlich', 'http://www.edith-stein-realschule.de'),
  ('160131', 'Peter-Ustinov-Schule', 'Köln', 'Realschule', 'öffentlich', 'http://www.peter-ustinov-realschule.de'),
  ('160155', 'Erzbischöfliche Ursulinenschule Köln (Realschule)', 'Köln', 'Realschule', 'privat', 'https://www.ursulinenrealschule-koeln.de/aktuell/'),
  ('160179', 'Theodor-Heuss-Schule', 'Köln', 'Realschule', 'öffentlich', 'http://www.thr-koeln.de'),
  ('160180', 'Johann-Bendel-Schule', 'Köln', 'Realschule', 'öffentlich', 'http://www.johann-bendel-realschule.de'),
  ('160192', 'Albert-Schweitzer-Schule', 'Köln', 'Realschule', 'öffentlich', 'https://asronline.de'),
  ('160209', 'Käthe-Kollwitz-Schule', 'Köln', 'Realschule', 'öffentlich', 'http://www.kaethe-kollwitz-realschule.de'),
  ('160210', 'Bertha-von-Suttner-Schule', 'Köln', 'Realschule', 'öffentlich', 'https://suttnerschule-koeln.de/'),
  ('160222', 'Eichendorff-Schule', 'Köln', 'Realschule', 'öffentlich', 'http://www.rseichen-koeln.de'),
  ('160260', 'Realschule am Rhein', 'Köln', 'Realschule', 'öffentlich', 'http://www.rsamrhein.de'),
  ('160430', 'Johannes-Gutenberg-Schule', 'Köln', 'Realschule', 'öffentlich', 'http://www.rsgodorf.de'),
  ('160568', 'Wilhelm-Busch-Realschule', 'Köln', 'Realschule', 'öffentlich', 'http://www.wilhelm-busch-realschule.de'),
  ('160570', 'Max-Planck-Realschule', 'Köln', 'Realschule', 'öffentlich', 'http://www.max-planck-realschule-koeln.de/'),
  ('160581', 'Otto-Lilienthal-Schule', 'Köln', 'Realschule', 'öffentlich', 'http://www.ols-koeln.de'),
  ('197567', 'Werner Heisenberg Realschule', 'Köln', 'Realschule', 'privat', 'http://www.wh-rs.de'),
  ('100036', 'Gesamtschule Helios', 'Köln', 'Gesamtschule', 'öffentlich', 'https://heliosschule.de/'),
  ('100041', 'Gesamtschule Wasseramselweg', 'Köln', 'Gesamtschule', 'öffentlich', 'http://www.gesamtschule-wasseramselweg.de'),
  ('100068', 'Gesamtschule Berrenrather Straße', 'Köln', 'Gesamtschule', 'öffentlich', 'https://www.ge-lindenthal.de'),
  ('100071', 'Gesamtschule Dellbrücker Mauspfad', 'Köln', 'Gesamtschule', 'öffentlich', 'https://ge-dellbrueck.de/'),
  ('100169', 'Freie Naturschulen Köln, Gesamtschule', 'Köln', 'Gesamtschule', 'privat', 'http://www.freie-naturschulen-koeln.com/Unsere-Schulen/Gesamtschule/'),
  ('100208', 'Sieben Brücken Schule', 'Köln', 'Gesamtschule', 'privat', 'https://www.7bruecken.com/'),
  ('100210', 'Gesamtschule Am Wassermann', 'Köln', 'Gesamtschule', 'öffentlich', 'https://www.amwassermann.de/'),
  ('100211', 'Ernst-Simons-Gesamtschule', 'Köln', 'Gesamtschule', 'öffentlich', 'https://www.gesamtschule-weidenpesch.de'),
  ('100212', 'Gesamtschule Ossendorf', 'Köln', 'Gesamtschule', 'öffentlich', 'https://gesamtschule-ossendorf.de'),
  ('100219', 'Erzbischöfliche Gesamtschule am Bildungscampus Köln-Kalk', 'Köln', 'Gesamtschule', 'privat', null),
  ('100235', 'Gesamtschule Kalk', 'Köln', 'Gesamtschule', 'öffentlich', 'https://www.gesamtschule-kalk.de'),
  ('164161', 'Gesamtschule Köln-Rodenkirchen', 'Köln', 'Gesamtschule', 'öffentlich', 'http://www.gesamtschule-rodenkirchen.de'),
  ('183726', 'Gesamtschule Köln-Holweide', 'Köln', 'Gesamtschule', 'öffentlich', 'http://www.gesamtschule-holweide.de'),
  ('184287', 'Heinrich-Böll-Schule', 'Köln', 'Gesamtschule', 'öffentlich', 'http://www.hbg-koeln.de'),
  ('184913', 'Lise-Meitner-Gesamtschule', 'Köln', 'Gesamtschule', 'öffentlich', 'http://www.lmgporz.de'),
  ('184937', 'Willy-Brandt-Gesamtschule', 'Köln', 'Gesamtschule', 'öffentlich', 'http://www.wbgs-koeln.de'),
  ('185176', 'Europaschule Köln, Gesamtschule Zollstock', 'Köln', 'Gesamtschule', 'öffentlich', 'http://www.europaschulekoeln.eu/'),
  ('187902', 'Max-Ernst-Gesamtschule', 'Köln', 'Gesamtschule', 'öffentlich', 'http://www.max-ernst-gesamtschule-koeln.de'),
  ('188165', 'Katharina-Henoth-Schule', 'Köln', 'Gesamtschule', 'öffentlich', 'http://www.igs-kathi.de'),
  ('193021', 'Freie Schule Köln, Gesamtschule', 'Köln', 'Gesamtschule', 'privat', 'https://www.freie-schule-koeln.de'),
  ('195959', 'Carl-von-Ossietzky-Gesamtschule', 'Köln', 'Gesamtschule', 'öffentlich', 'https://cvo-gesamtschule.de'),
  ('196459', 'BilinGO Campus Gesamtschule', 'Köln', 'Gesamtschule', 'privat', 'http://www.bilingo-campus.eu'),
  ('197488', 'Offene Schule Köln', 'Köln', 'Gesamtschule', 'privat', 'http://www.offene-schule-koeln.de'),
  ('198742', 'Trude-Herr-Gesamtschule', 'Köln', 'Gesamtschule', 'öffentlich', 'http://www.thg-koeln.de/'),
  ('198912', 'igis Köln, Integrierte Gesamtschule Innenstadt', 'Köln', 'Gesamtschule', 'öffentlich', 'http://www.igis-koeln.de/'),
  ('191942', 'Willy-Brandt-Gesamtschule Kerpen', 'Kerpen', 'Gesamtschule', 'öffentlich', 'http://www.gesamtschule-kerpen.de')
  ) as v (schulnummer, name, ort, schulform, traeger, website)
 where not exists (select 1 from public.schulen s where s.schulnummer = v.schulnummer)
on conflict do nothing;
