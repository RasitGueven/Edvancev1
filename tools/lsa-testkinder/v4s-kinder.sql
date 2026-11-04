-- V4-S (docs/report/v4/Bauauftrag-V4-S.md, Prüfen 1): ein Kind mit anstehender Klassenarbeit im aktuellen Thema.
-- Eingebunden von erzeugen.sql mit -v kinder_zusatz=…/v4s-kinder.sql, nach kinder.sql; hängt an lsat.kinder an.
--
-- Ida: Klasse 9, Thema Ähnlichkeit und zentrische Streckung, Klassenarbeit dazu 'bevorstehend'. Schulplan des
--   Deutzer Gymnasiums Schaurtestraße, nicht FWG: Im FWG-Plan steht Ähnlichkeit erst in Klasse 10, und ohne
--   Halbjahr im Plan gäbe es dann gar keinen Fahrplan. Schaurte hat das Thema an Position 1 von Klasse 9.
--   Antwortprofil:
--     im Thema gemischt — Streckfaktor sicher, Erster und Zweiter Strahlensatz sowie Flächen/Volumen bei
--       Ähnlichkeit Übung,
--     Voraussetzungen teils sicher, teils Übung — Einschrittige Gleichungen und Maßstab sicher, Potenzen Übung,
--     sonst bis Klasse 8 sicher.
--   Die Fehler im Thema lassen die Auswahl zu den Voraussetzungen hinuntergehen; so werden Einschrittige
--   Gleichungen und Potenzen direkt geprüft (ein erster Lauf mit sicherem Ersten Strahlensatz leitete sie nur ab).
--   Die Aufgaben zum Thema sind noch Entwürfe: Das Kind zieht wie alle Testkinder aus dem Testkonto-Pool.
do $do$
begin
  perform set_config('lsat.kinder', (current_setting('lsat.kinder')::jsonb || jsonb_build_array(
    '{"kind": "Ida", "name": "Ida Testkind", "lead": "a5a7c41d-1ead-4000-8000-00000000000f",
      "schueler": "a5a7c41d-5c00-4000-8000-00000000000f",
      "klasse": 9, "schulform": "Gymnasium", "schule": "Deutzer Gymnasium Schaurtestraße", "thema": "aehnlichkeit",
      "behandelt": ["brueche", "daten_streumasse", "flaeche_umfang", "flaechen_vielecke", "ganze_zahlen_groessen",
                    "koerper_quader", "lineare_funktionen", "lineare_gleichungen_lgs", "natuerliche_zahlen",
                    "rationale_zahlen", "rechnen_brueche_dezimalzahlen", "rechnen_natuerliche_zahlen", "symmetrie",
                    "terme_binomische_formeln", "terme_gleichungen", "thales_konstruktionen", "winkel",
                    "winkel_dreiecke", "zinsrechnung", "zufallsexperimente", "zuordnungen"],
      "quelle_behandelt": "schulplan",
      "anliegen": ["Grundlagen fehlen"], "notiz": "Klassenarbeit über Ähnlichkeit steht noch an.",
      "goal": "EXAM_PREP", "letzte_note": "3", "trend": "stabil", "interessen": "Tanzen, Zeichnen",
      "grund": {"56": "sicher", "78": "sicher", "910": "sicher"},
      "ausnahmen": {"geo_aehnlich_strahlen_parallel": "uebung", "geo_aehnlich_flaeche": "uebung",
                    "potenzen": "uebung", "geo_massstab": "sicher", "gleichung_einschrittig": "sicher",
                    "geo_aehnlich_streckfaktor": "sicher", "geo_aehnlich_strahlen_abschnitt": "uebung"},
      "familie": null, "fehlbilder": [], "sekunden": 45, "ka_status": "bevorstehend"}'::jsonb))::text, false);
end $do$;
