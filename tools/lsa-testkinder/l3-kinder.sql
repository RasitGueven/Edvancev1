-- LSA-L3: Kinder nur für die Simulation (docs/lsa/Bauauftrag-L3.md, Schritt 1). Eingebunden von erzeugen.sql mit
-- -v kinder_zusatz=…/l3-kinder.sql, nach kinder.sql; hängt an lsat.kinder an. Nicht im pgTAP-Lauf der Testkinder.
--
-- Batu in vier Varianten, abgeleitet aus Batus Eintrag in kinder.sql (gleiches Profil, eigener Lead und Schüler):
--   BatuB   Klassenarbeit bevorstehend                  → 'thema_zuerst'
--   BatuG   geschrieben, Note offen                     → 'vorschau_zuerst', Thema kurz 4 Minuten
--   BatuN4  geschrieben, Note 4                         → 'vorschau_zuerst', Thema kurz 4 Minuten
--   BatuS2  „Batu stark“: Terme & Gleichungen sicher, geschrieben, Note 2 → Thema kurz 2 Minuten
-- Mia: Klasse 7 im 2. Halbjahr, FWG-Plan, Thema Terme und Gleichungen (Position 4 von 5): nach ihm kommt im
--   Schuljahr nur noch Winkel und Dreiecke, die Vorschau füllt aus Klasse 8 auf (Entscheidung 4). Klassenarbeit
--   geschrieben. Bis Klasse 6 sicher, Klasse 7/8 Übung bis auf Zuordnungen und Zinsrechnung.
-- MiaB: Mia mit bevorstehender Klassenarbeit ('thema_zuerst'): das Auffüllen gilt in beiden Modi.
do $do$
declare
  v_batu jsonb := (select k from jsonb_array_elements(current_setting('lsat.kinder')::jsonb) k
                    where k ->> 'kind' = 'Batu');
  v_stark jsonb;
  v_mia   jsonb;
begin
  if v_batu is null then
    raise exception 'LSA-L3: Batu fehlt in kinder.sql';
  end if;
  v_stark := v_batu -> 'ausnahmen';
  v_stark := v_stark - array(select x from jsonb_object_keys(v_stark) x where x ~ '^(term|gleichung)_');
  perform set_config('lsat.kinder', (current_setting('lsat.kinder')::jsonb || jsonb_build_array(
    v_batu || '{"kind": "BatuB", "name": "Batu Testkind B", "lead": "a5a7c41d-1ead-4000-8000-000000000009",
                "schueler": "a5a7c41d-5c00-4000-8000-000000000009", "ka_status": "bevorstehend"}',
    v_batu || '{"kind": "BatuG", "name": "Batu Testkind G", "lead": "a5a7c41d-1ead-4000-8000-00000000000a",
                "schueler": "a5a7c41d-5c00-4000-8000-00000000000a", "ka_status": "geschrieben"}',
    v_batu || '{"kind": "BatuN4", "name": "Batu Testkind N4", "lead": "a5a7c41d-1ead-4000-8000-00000000000b",
                "schueler": "a5a7c41d-5c00-4000-8000-00000000000b", "ka_status": "geschrieben", "ka_note": 4}',
    v_batu || jsonb_build_object('ausnahmen', v_stark) ||
      '{"kind": "BatuS2", "name": "Batu Testkind S2", "lead": "a5a7c41d-1ead-4000-8000-00000000000c",
        "schueler": "a5a7c41d-5c00-4000-8000-00000000000c", "ka_status": "geschrieben", "ka_note": 2}',
    '{"kind": "Mia", "name": "Mia Testkind", "lead": "a5a7c41d-1ead-4000-8000-00000000000d",
      "schueler": "a5a7c41d-5c00-4000-8000-00000000000d",
      "klasse": 7, "schulform": "Gymnasium", "schule": "Friedrich-Wilhelm-Gymnasium", "thema": "terme_gleichungen",
      "behandelt": ["natuerliche_zahlen", "rechnen_natuerliche_zahlen", "brueche", "rechnen_brueche_dezimalzahlen",
                    "ganze_zahlen_groessen", "flaeche_umfang", "winkel", "rationale_zahlen", "zuordnungen",
                    "zinsrechnung"], "quelle_behandelt": "schulplan",
      "anliegen": ["Grundlagen fehlen"], "notiz": "Klassenarbeit über Terme und Gleichungen geschrieben.",
      "goal": "IMPROVE_GRADES", "letzte_note": "3", "trend": "stabil", "interessen": "Handball, Lesen",
      "grund": {"56": "sicher", "78": "uebung", "910": "uebung"},
      "ausnahmen": {"proportionalitaet": "sicher", "prozent_grundwert": "sicher", "prozent_prozentwert": "sicher"},
      "familie": null, "fehlbilder": [], "sekunden": 45, "ka_status": "geschrieben"}'::jsonb))::text, false);
  v_mia := (select k from jsonb_array_elements(current_setting('lsat.kinder')::jsonb) k where k ->> 'kind' = 'Mia');
  perform set_config('lsat.kinder', (current_setting('lsat.kinder')::jsonb || jsonb_build_array(
    v_mia || '{"kind": "MiaB", "name": "Mia Testkind B", "lead": "a5a7c41d-1ead-4000-8000-00000000000e",
               "schueler": "a5a7c41d-5c00-4000-8000-00000000000e", "ka_status": "bevorstehend"}'))::text, false);
end $do$;
