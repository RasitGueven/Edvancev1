-- Stufen-Pruefung der Skills gegen den Kernlehrplan G9 NRW (W2-7, Teil 1).
-- Pruefung und Entscheidungen: docs/report/stufen-pruefung.md.
--
-- Kuerzel: Stufe-Inhaltsfeld (Nr. der Kompetenzerwartung), z. B. E-Fkt (2)
-- = Erprobungsstufe, Funktionen, Erwartung (2). E = Kl. 5/6, S1 = Kl. 7/8.
--
-- 1. geo_flaeche_dreieck 6 -> 7. E-Geo (12) kennt nur Rechteck und
--    rechtwinkliges Dreieck; die Aufgaben verlangen allgemeine Dreiecke und
--    Parallelogramme mit Grundseite und Hoehe (S1-Geo (8)). Wirkt auch auf die
--    LSA-Auswahl, sobald sie ueber klasse_herkunft <= Klasse filtert – gewollt.
-- 2. proportionalitaet: Stufe 7 bleibt, nur das Label. Die Haelfte der
--    Aufgaben ist antiproportional (S1-Fkt), das alte Label verschwieg das.
--
-- Die WHERE-Klauseln pruefen den Altwert: in einer Datenbank ohne diese
-- Knoten (oder mit schon geaendertem Stand) trifft die Datei 0 Zeilen.

begin;

update skills
   set klasse_herkunft = 7
 where skill_key = 'geo_flaeche_dreieck'
   and klasse_herkunft = 6;

update skills
   set label = 'Dreisatz, proportional und antiproportional'
 where skill_key = 'proportionalitaet'
   and label = 'Dreisatz, proportionale Zuordnung';

commit;
