-- ============================================================================
-- W3-6, Teil 4b: thema_einstieg fuer das Thema Kreis
-- ============================================================================
--
-- Eigene Datei, weil die geo_kreis_*-Knoten in Produktion erst mit dem
-- Kreis-Substrat (feat/k9-kreis) ankommen. Erst einspielen, wenn alle
-- geo_kreis_*-Knoten existieren; fehlt einer, scheitert der Fremdschluessel
-- laut, statt still nichts einzutragen.
--
-- kreis:
--   geo_kreis_umfang  — Umfang, Grundfall des Themas
--   geo_kreis_flaeche — Flaecheninhalt, zweiter Grundfall
--   Beide liegen auf Tiefe 6 und tragen sich nicht gegenseitig; Sektor,
--   Rueckrechnung und zusammengesetzte Figuren haengen an ihnen und bleiben
--   Blaetter der Breite. Ein dritter Einstieg wuerde nur den Befund der
--   beiden Grundfaelle wiederholen.
--
-- Die Knoten tragen klasse_herkunft 9: Phase T greift fuer dieses Thema
-- erst ab einer Sitzung mit grade >= 9.

insert into public.thema_einstieg (thema_key, skill_key) values
  ('kreis', 'geo_kreis_umfang'),
  ('kreis', 'geo_kreis_flaeche')
on conflict (thema_key, skill_key) do nothing;
