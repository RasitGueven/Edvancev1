-- ============================================================================
-- K10-Rest, Teil 3: thema_einstieg fuer exponentialfunktionen, trigonometrie,
-- sinusfunktion
-- ============================================================================
--
-- Einspiel-Reihenfolge: nach den drei substrat_k10_*-Dateien dieses Laufs
-- (20261003121328 … 20261003121331) und sinnvollerweise nach den Aufgaben
-- (20261003121332 … 20261003121334). Fehlt ein Knoten oder Thema, scheitert der Fremdschluessel
-- laut, statt still nichts einzutragen (Muster W3-6). Solange die Aufgaben nur
-- als Entwurf vorliegen, laeuft lsa_select_next_core fuer diese Themen wie ohne
-- Thema (v_mit_thema verlangt Aufgaben im Status ready) — die Zeilen schaden
-- vorher nicht.
--
-- Regel wie 20261003092850_lsa_thema_einstieg.sql und K9-Rest: hoechstens drei
-- Einstiege je Thema. Phase T prueft "groesster offener Abschluss zuerst"; ein
-- Knoten, der dabei schon mitbelegt wurde, faellt heraus. Ein Einstieg, dessen
-- Abschluss ein anderer Einstieg schon enthaelt, braechte nichts Neues. Sach-
-- und Anwendungsknoten sind keine Einstiege (die Breite erreicht sie als Blatt).
-- Abschlussgroessen (lsa_abschluss, lokal aus allen Migrationen) in Klammern.
--
-- exponentialfunktionen:
--   fkt_exp_term     (24) — groesster Abschluss ohne Sachkontext: Wachstum,
--                           Zinseszins, lineare Funktion, negative Hochzahlen
--   fkt_exp_halbwert (21) — eigener Ast: Verdopplungs- und Halbwertszeit
--   fkt_exp_gleichung (11) — eigener Ast ueber Potenzen und Runden (Ari-10),
--                           liegt in keinem anderen Abschluss
--   Nicht: fkt_exp_anwendung (Sachaufgabe; Abschluss 27, aber Anwendung statt
--   Kern), fkt_exp_wachstum (in term und halbwert enthalten).
-- trigonometrie:
--   geo_trigo_kosinussatz (16) — groesster Abschluss ohne Sachkontext: Winkel,
--                                Seitenverhaeltnisse, Pythagoras, Aehnlichkeit
--   geo_trigo_seite       (14) — eigener Ast: Seiten berechnen, Gleichung
--                                umstellen
--   Nicht: geo_trigo_anwendung (Sachaufgabe; Abschluss 19),
--   geo_trigo_winkel (im Abschluss des Kosinussatzes), geo_trigo_verhaeltnis
--   (in beiden Abschluessen enthalten).
-- sinusfunktion:
--   fkt_sinus_parameter (25) — einziger Einstieg: Die Knoten bilden bis auf das
--                              Blatt eine Kette (Einheitskreis/Bogenmass ->
--                              Graph -> Parameter); jeder andere Einstieg laege
--                              im Abschluss von parameter und fiele in Phase T
--                              heraus. Bricht parameter, fuehrt der Abstieg zu
--                              Graph, Einheitskreis und Bogenmass.
--   Nicht: fkt_sinus_periodisch (Sachaufgabe, Fkt-14; Abschluss 26).
--
-- Alle Knoten tragen klasse_herkunft 10. Die Klassengrenze (klasse_herkunft <=
-- grade) gilt fuer Einstiege und den Abstieg darunter NICHT
-- (20261003094451_lsa_thema_einstieg_entscheidungen.sql).
-- Kein begin/commit: `mig` spielt die Datei mit psql -1 ein.

insert into public.thema_einstieg (thema_key, skill_key) values
  ('exponentialfunktionen', 'fkt_exp_term'),
  ('exponentialfunktionen', 'fkt_exp_halbwert'),
  ('exponentialfunktionen', 'fkt_exp_gleichung'),
  ('trigonometrie',         'geo_trigo_kosinussatz'),
  ('trigonometrie',         'geo_trigo_seite'),
  ('sinusfunktion',         'fkt_sinus_parameter')
on conflict (thema_key, skill_key) do nothing;
