-- ============================================================================
-- K9-Rest, Teil 3: thema_einstieg fuer die neun Themen-Keys dieses Laufs
-- ============================================================================
--
-- Einspiel-Reihenfolge: nach ALLEN substrat_k9_*-Dateien dieses Laufs
-- (20261003105852 … 20261003105900) und sinnvollerweise nach den Aufgaben
-- (20261003105901 … 20261003105909). Fehlt ein Knoten oder Thema, scheitert
-- der Fremdschluessel laut, statt still nichts einzutragen (Muster W3-6).
-- Solange die Aufgaben nur als Entwurf vorliegen, laeuft lsa_select_next_core
-- fuer diese Themen wie ohne Thema (v_mit_thema verlangt Aufgaben im Status
-- ready) — die Zeilen schaden vorher nicht.
--
-- Regel wie 20261003092850_lsa_thema_einstieg.sql: hoechstens drei Einstiege je
-- Thema. Phase T prueft "groesster offener Abschluss zuerst"; ein Knoten, der
-- dabei schon mitbelegt wurde, faellt heraus. Ein Einstieg, dessen Abschluss
-- ein anderer Einstieg schon enthaelt, braechte nichts Neues. Sach- und
-- Anwendungsknoten sind keine Einstiege (die Breite erreicht sie als Blatt).
-- Abschlussgroessen (lsa_abschluss, lokal aus allen Migrationen) in Klammern.
--
-- reelle_zahlen:
--   zahl_wurzel_irrational (9) — groesster Abschluss: Wurzelbegriff, Brueche
--                                und Dezimalzahlen, Potenzen
--   zahl_wurzel_teilweise  (7) — Kern der Wurzelrechnung, traegt die
--                                Wurzelgesetze mit
--   zahl_wurzel_naeherung  (7) — eigener Ast ueber das Runden
--   Nicht: zahl_wurzel_quadrat (in allen drei Abschluessen enthalten),
--   zahl_wurzel_gesetze (im Abschluss von teilweise).
-- potenzen:
--   zahl_potenz_rechnen  (11) — einziger Einstieg: Die vier Knoten bilden eine
--                               Kette (gesetze -> negativ -> zehner -> rechnen),
--                               jeder andere Einstieg laege im Abschluss von
--                               rechnen und fiele in Phase T heraus; bricht
--                               rechnen, fuehrt der Abstieg die Kette hinunter.
-- quadratische_gleichungen:
--   gleichung_quadr_formel (12) — Kern: Loesungsformel, traegt das
--                                 Wurzelziehen mit
--   gleichung_quadr_faktor  (9) — eigener Ast ueber das Ausklammern
--   Nicht: gleichung_quadr_anzahl (setzt die Formel voraus und fragt nur
--   deren Wurzelterm ab; Blatt der Breite), gleichung_quadr_wurzel (im
--   Abschluss der Formel).
-- quadratische_funktionen:
--   fkt_quadr_nullstellen (15) — groesster Abschluss ohne Sachkontext:
--                                Parabel und Loesungsformel
--   fkt_quadr_normalform  (13) — eigener Ast: Scheitelpunkt und
--                                quadratische Ergaenzung (binomische Formel)
--   Nicht: fkt_quadr_extrem (Sachaufgabe; Abschluss 19, aber Anwendung statt
--   Kern), fkt_quadr_parabel/_scheitel (in den Abschluessen enthalten).
-- pythagoras:
--   geo_pythagoras_kathete   (7) — beide Richtungen des Satzes
--   geo_pythagoras_abstand   (8) — Satz im Koordinatensystem
--   geo_pythagoras_umkehrung (7) — eigener Ast: rechtwinklig pruefen
--   Nicht: geo_pythagoras_anwendung (Anwendung), _hypotenuse (in allen
--   Abschluessen enthalten).
-- prismen_zylinder (eigenes Thema neben kreis, deshalb hier die Koerper):
--   geo_koerper_zylinder (18) — enthaelt Prisma, Kreisflaeche und -umfang;
--                               ein Prisma-Einstieg waere darin enthalten
-- koerper_pyramide_kegel_kugel:
--   geo_koerper_kegel (22) — groesster Abschluss: Zylinder, Pyramide,
--                            Pythagoras, Prisma, Kreis
--   geo_koerper_kugel (11) — eigener Ast ueber die Kreisflaeche
-- bedingte_wahrscheinlichkeit:
--   stoch_bedingt_umkehr      (9) — Kern: Bedingung umkehren, mit
--                                   Prozentwerten
--   stoch_bedingt_unabhaengig (7) — eigener Ast: Unabhaengigkeit
--   Nicht: stoch_bedingt_irrefuehrend (Beurteilen von Darstellungen, eher
--   Thema statistik_beurteilen; Blatt der Breite), _wkeit/_vierfeld (in
--   beiden Abschluessen enthalten).
-- aehnlichkeit:
--   geo_aehnlich_strahlen_parallel (10) — Strahlensaetze, traegt den
--                                         ersten Strahlensatz und den
--                                         Streckfaktor mit
--   geo_aehnlich_flaeche           (10) — eigener Ast: k² und k³
--
-- Alle Knoten tragen klasse_herkunft 9. Die Klassengrenze (klasse_herkunft <=
-- grade) gilt fuer Einstiege und den Abstieg darunter NICHT
-- (20261003094451_lsa_thema_einstieg_entscheidungen.sql): eine Sitzung der
-- Klasse 8 mit Thema pythagoras bekommt Phase T; in der Breite ohne Thema
-- bleiben die Knoten Klasse-9-Sitzungen vorbehalten.
-- Kein begin/commit: `mig` spielt die Datei mit psql -1 ein.

insert into public.thema_einstieg (thema_key, skill_key) values
  ('reelle_zahlen',                'zahl_wurzel_irrational'),
  ('reelle_zahlen',                'zahl_wurzel_teilweise'),
  ('reelle_zahlen',                'zahl_wurzel_naeherung'),
  ('potenzen',                     'zahl_potenz_rechnen'),
  ('quadratische_gleichungen',     'gleichung_quadr_formel'),
  ('quadratische_gleichungen',     'gleichung_quadr_faktor'),
  ('quadratische_funktionen',      'fkt_quadr_nullstellen'),
  ('quadratische_funktionen',      'fkt_quadr_normalform'),
  ('pythagoras',                   'geo_pythagoras_kathete'),
  ('pythagoras',                   'geo_pythagoras_abstand'),
  ('pythagoras',                   'geo_pythagoras_umkehrung'),
  ('prismen_zylinder',             'geo_koerper_zylinder'),
  ('koerper_pyramide_kegel_kugel', 'geo_koerper_kegel'),
  ('koerper_pyramide_kegel_kugel', 'geo_koerper_kugel'),
  ('bedingte_wahrscheinlichkeit',  'stoch_bedingt_umkehr'),
  ('bedingte_wahrscheinlichkeit',  'stoch_bedingt_unabhaengig'),
  ('aehnlichkeit',                 'geo_aehnlich_strahlen_parallel'),
  ('aehnlichkeit',                 'geo_aehnlich_flaeche')
on conflict (thema_key, skill_key) do nothing;
