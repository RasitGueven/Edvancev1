-- LSA-T: die Profile der Testkinder, eingebunden von erzeugen.sql (\ir kinder.sql).
-- Nur Daten: setzt lsat.kinder (JSON) und leert lsat.sitzungen und lsat.nicht_angenommen.
--
-- ── Die sieben Kinder ────────────────────────────────────────────────────────────────────────────
-- grund: Zustand je Klassenstufe (Herkunftsklasse des Skills: 56 = bis 6, 78 = 7/8, 910 = ab 9).
-- ausnahmen: je skill_key, überschreibt den Grundstand. Zustände: sicher | uebung | teilweise | nicht_angesetzt.
-- familie/fehlbilder: bevorzugtes Fehlbild bei falschen Antworten (erst die Slugs, dann die Familie).
-- anliegen: nur Werte aus PARENT_WEAK_TOPICS (src/pages/admin/intake/intakeConstants.ts), alles andere in notiz.
-- sekunden: Antwortdauer, je Aufgabe nach festem Muster variiert (c_muster in erzeugen.sql).
-- hoechstens: optional, so viele Aufgaben, dann lsa_finish (Tim: bei 3 s je Aufgabe wären 19 Minuten mehrere hundert).
do $do$ begin perform set_config('lsat.kinder', $kinder$[
 {"kind": "Lina", "name": "Lina Berger", "lead": "a5a7c41d-1ead-4000-8000-000000000001", "schueler": "a5a7c41d-5c00-4000-8000-000000000001",
  "klasse": 9, "schulform": "Gymnasium", "schule": "Friedrich-Wilhelm-Gymnasium", "thema": "quadratische_funktionen",
  "behandelt": ["reelle_zahlen", "lineare_funktionen", "terme_binomische_formeln"], "quelle_behandelt": "schulplan",
  "anliegen": ["Rechenwege"], "notiz": "Noten halten, Oberstufe vorbereiten.",
  "goal": "GENERAL", "letzte_note": "2+", "trend": "stabil", "interessen": "Volleyball, Fotografie",
  "grund": {"56": "sicher", "78": "sicher", "910": "sicher"}, "ausnahmen": {"geo_flaeche_dreieck": "uebung"},
  "familie": null, "fehlbilder": [], "sekunden": 40},
 {"kind": "Emre", "name": "Emre Kaya", "lead": "a5a7c41d-1ead-4000-8000-000000000002", "schueler": "a5a7c41d-5c00-4000-8000-000000000002",
  "klasse": 9, "schulform": "Gymnasium", "schule": "Friedrich-Wilhelm-Gymnasium", "thema": "reelle_zahlen",
  "behandelt": ["lineare_funktionen", "terme_binomische_formeln", "lineare_gleichungen_lgs"], "quelle_behandelt": "schulplan",
  "anliegen": ["Grundlagen fehlen"], "notiz": "Klassenarbeit über Wurzeln in drei Wochen.",
  "goal": "EXAM_PREP", "pruefung_tage": 21, "pruefung_thema": "Reelle Zahlen und Wurzeln", "letzte_note": "3", "trend": "schlechter",
  "interessen": "Fußball, Videospiele",
  "grund": {"56": "sicher", "78": "sicher", "910": "sicher"},
  "ausnahmen": {"zahl_wurzel_gesetze": "uebung", "zahl_wurzel_teilweise": "uebung"},
  "familie": "potenzen_wurzeln", "fehlbilder": ["wurzel_gliedweise"], "sekunden": 60},
 {"kind": "Sophie", "name": "Sophie Wagner", "lead": "a5a7c41d-1ead-4000-8000-000000000003", "schueler": "a5a7c41d-5c00-4000-8000-000000000003",
  "klasse": 8, "schulform": "Realschule", "schule": null, "thema": "lineare_funktionen",
  "behandelt": ["rationale_zahlen", "zuordnungen", "terme_gleichungen"], "quelle_behandelt": "gespraech",
  "anliegen": ["Textverständnis", "Konzentration"], "notiz": "Mathe-Note abgerutscht, wenig Motivation.",
  "goal": "IMPROVE_GRADES", "letzte_note": "4", "trend": "schlechter", "interessen": "Pferde, Zeichnen",
  "grund": {"56": "sicher", "78": "uebung", "910": "uebung"},
  "ausnahmen": {"geo_koordinaten": "teilweise", "fkt_linear_yabschnitt": "teilweise"},
  "familie": "geraden_schaubilder", "fehlbilder": ["steigung_kehrwert"], "sekunden": 80},
 {"kind": "Jonas", "name": "Jonas Richter", "lead": "a5a7c41d-1ead-4000-8000-000000000004", "schueler": "a5a7c41d-5c00-4000-8000-000000000004",
  "klasse": 8, "schulform": "Gesamtschule", "schule": null, "thema": "terme_gleichungen",
  "behandelt": ["rationale_zahlen", "zuordnungen"], "quelle_behandelt": "gespraech",
  "anliegen": ["Grundlagen fehlen", "Konzentration"], "notiz": "Versetzung gefährdet.",
  "goal": "CLOSE_GAPS", "letzte_note": "5", "trend": "schlechter", "interessen": "Skateboard, Minecraft",
  "grund": {"56": "uebung", "78": "nicht_angesetzt", "910": "nicht_angesetzt"},
  "ausnahmen": {"vorzeichen_add_sub": "uebung", "vorzeichen_mult_div": "uebung", "vorzeichen_vorrang": "uebung",
                "term_zusammenfassen": "uebung", "runden_ueberschlag": "sicher"},
  "familie": "vorzeichen", "fehlbilder": [], "sekunden": 110},
 {"kind": "Nele", "name": "Nele Schmitz", "lead": "a5a7c41d-1ead-4000-8000-000000000005", "schueler": "a5a7c41d-5c00-4000-8000-000000000005",
  "klasse": 7, "schulform": "Gymnasium", "schule": null, "thema": "zinsrechnung",
  "behandelt": ["rationale_zahlen", "zuordnungen"], "quelle_behandelt": "gespraech",
  "anliegen": ["Prüfungsangst"], "notiz": "Wenig Motivation, Mathe macht ihr gerade keinen Spaß.",
  "goal": "GENERAL", "letzte_note": "3-", "trend": "stabil", "interessen": "Tanzen, Tiere",
  "grund": {"56": "sicher", "78": "sicher", "910": "uebung"},
  "ausnahmen": {"prozent_grundwert": "uebung", "prozent_prozentsatz": "uebung", "prozent_veraenderung": "uebung",
                "prozent_zins_zinseszins": "uebung", "prozent_zins_rueckrechnung": "uebung",
                "bruch_add": "teilweise", "bruch_mult": "teilweise", "bruch_div": "teilweise", "bruch_dezimal": "teilweise"},
  "familie": "rechenart_formel", "fehlbilder": ["multipliziert_statt_dividiert", "grundwert_verwechselt", "falsche_richtung"],
  "sekunden": 70},
 {"kind": "Max", "name": "Max Hoffmann", "lead": "a5a7c41d-1ead-4000-8000-000000000006", "schueler": "a5a7c41d-5c00-4000-8000-000000000006",
  "klasse": 8, "schulform": "Gymnasium", "schule": "Friedrich-Wilhelm-Gymnasium", "thema": "lineare_funktionen",
  "behandelt": ["rationale_zahlen", "zuordnungen", "terme_gleichungen"], "quelle_behandelt": "schulplan",
  "anliegen": ["Rechenwege"], "notiz": "Möchte gefordert werden, langweilt sich im Unterricht.",
  "goal": "GENERAL", "letzte_note": "1-", "trend": "stabil", "interessen": "Schach, Programmieren",
  "grund": {"56": "sicher", "78": "sicher", "910": "sicher"}, "ausnahmen": {}, "familie": null, "fehlbilder": [], "sekunden": 35},
 {"kind": "Tim", "name": "Tim Schuster", "lead": "a5a7c41d-1ead-4000-8000-000000000007", "schueler": "a5a7c41d-5c00-4000-8000-000000000007",
  "klasse": 8, "schulform": "Gesamtschule", "schule": null, "thema": "terme_gleichungen",
  "behandelt": ["rationale_zahlen", "zuordnungen"], "quelle_behandelt": "gespraech",
  "anliegen": ["Konzentration"], "notiz": "Will schnell fertig sein, liest Aufgaben oft nicht zu Ende.",
  "goal": "IMPROVE_GRADES", "letzte_note": "4", "trend": "schlechter", "interessen": "Basketball, Musik",
  "grund": {"56": "uebung", "78": "uebung", "910": "uebung"}, "ausnahmen": {"runden_ueberschlag": "sicher"},
  "familie": null, "fehlbilder": [], "sekunden": 3, "hoechstens": 30}
]$kinder$, false);
  perform set_config('lsat.sitzungen', '{}', false); perform set_config('lsat.nicht_angenommen', '{}', false);
end $do$;
