-- ============================================================================
-- W4 K8-Rest, Teil 3: thema_einstieg fuer LGS, Wahrscheinlichkeit, Flaechen,
-- Winkelsaetze und Thales
-- ============================================================================
--
-- Einspiel-Reihenfolge: nach allen vier Substraten (20261003104943 … 104946)
-- und allen vier Aufgaben-Dateien (20261003104947 … 104950). Fehlt ein Knoten,
-- scheitert der Fremdschluessel laut, statt still nichts einzutragen.
-- Kein begin/commit: mig spielt die Datei mit psql -1 ein.
--
-- Auswahl nach "groesster Abschluss" (Zahl der transitiven Voraussetzungen,
-- gemessen in der Wegwerf-DB aus allen Migrationen) und fachlichem Kern.
-- Sachaufgaben- und Anwendungsknoten sind keine Einstiege; die Breite
-- erreicht sie als Blaetter. Hoechstens drei Einstiege je Thema.
--
-- Wirkung erst mit ready-Aufgaben: lsa_select_next_core nimmt ein Thema nur,
-- wenn ein Einstiegsknoten Aufgaben im Status-Filter hat. Solange Lena die
-- Entwuerfe nicht freigibt, laeuft die Auswahl ohne Thema wie bisher.
-- Die Knoten tragen klasse_herkunft 8, die Themen klasse 7 (Stufenbeginn);
-- Einstiege und Abstieg sind von der Klassengrenze ausgenommen
-- (20261003094451_lsa_thema_einstieg_entscheidungen).
--
-- lineare_gleichungen_lgs:
--   gleichung_lgs_einsetzen   (Abschluss 13) — algebraischer Grundweg, traegt
--                               auch die Sachaufgaben
--   gleichung_lgs_addition    (Abschluss 13) — zweiter algebraischer Weg, eigene
--                               Fehlbilder (Faktor, Verknuepfen der Seiten)
--   gleichung_lgs_grafisch    (Abschluss 14) — Schnittpunkt; Abstieg in die
--                               linearen Funktionen
--   Nicht: gleichsetzen (Sonderfall des Einsetzens, Breite), sachaufgabe
--   (Anwendung, Abschluss 18 ueber einsetzen + addition).
--
-- zufallsexperimente:
--   stoch_pfad_summe (Abschluss 10) — umfasst Produktregel, Gegenereignis und
--   Laplace; ein gebrochener Befund steigt dorthin ab. Ein zweiter Einstieg
--   wuerde nur Knoten aus diesem Abschluss wiederholen.
--   stoch_kenngroessen (Median, Quartile) ist Daten, nicht Zufall; im Katalog
--   gehoert das zu daten_streumasse (Kl. 5) bzw. statistik_beurteilen (Kl. 9).
--   Kein Einstieg dort in diesem Lauf (Befund).
--
-- flaechen_vielecke:
--   geo_flaeche_trapez, geo_flaeche_drachen_raute — die beiden Grundfaelle,
--   tragen sich nicht gegenseitig (Muster Kreis: Umfang + Flaeche)
--   geo_flaeche_term (Abschluss 12) — eigener Strang ueber die Termknoten
--   Nicht: zusammengesetzt, rueck (Anwendung bzw. Rueckrichtung, Breite).
--
-- winkel_dreiecke:
--   geo_winkel_dreieck (Abschluss 4) — enthaelt Neben-/Scheitel-, Stufen-/
--   Wechselwinkel und geo_winkel_summe; ein Einstieg genuegt.
--
-- thales_konstruktionen:
--   geo_winkel_thales — der einzige rechnerische Knoten des Themas; die
--   Konstruktionen (Umkreis, Inkreis, Mittelsenkrechte …) haben keine Knoten.

insert into public.thema_einstieg (thema_key, skill_key) values
  ('lineare_gleichungen_lgs', 'gleichung_lgs_einsetzen'),
  ('lineare_gleichungen_lgs', 'gleichung_lgs_addition'),
  ('lineare_gleichungen_lgs', 'gleichung_lgs_grafisch'),
  ('zufallsexperimente',      'stoch_pfad_summe'),
  ('flaechen_vielecke',       'geo_flaeche_trapez'),
  ('flaechen_vielecke',       'geo_flaeche_drachen_raute'),
  ('flaechen_vielecke',       'geo_flaeche_term'),
  ('winkel_dreiecke',         'geo_winkel_dreieck'),
  ('thales_konstruktionen',   'geo_winkel_thales')
on conflict (thema_key, skill_key) do nothing;
