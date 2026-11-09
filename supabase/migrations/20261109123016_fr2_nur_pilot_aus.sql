-- FR-2 F2 (09.11.2026): Lenas Board zeigt alle prüfbaren Aufgaben, nicht nur den Pilot.
-- Entscheidung Rasit 09.11.2026 (docs/freigabe/fr2/offen.md O2): pruef_einstellungen.nur_pilot = false.
-- Nur Daten, eine Zeile. pruef_pilot an den Aufgaben bleibt stehen (wirkt nur, wenn nur_pilot wieder an ist).
-- Kein begin/commit: mig klammert. Rollback: supabase/rollback/20261109123016_fr2_nur_pilot_aus.sql

update public.pruef_einstellungen set nur_pilot = false where nur_pilot;
