-- ============================================================================
-- skill_thema — Heimat-Thema je Skill (W4, Migration 2 von 2 — Daten)
-- ============================================================================
--
-- Genau ein Heimat-Thema je Skill: das Thema, in dem der Stoff im
-- Kernlehrplan G9 NRW eingefuehrt wird (Brueche kuerzen -> Bruchrechnung der
-- Erprobungsstufe, nicht "Lineare Gleichungen"). Herleitung und Grenzfaelle:
-- docs/inhalte-themen/zuordnung.md, Entscheidungen:
-- docs/inhalte-themen/entscheidungen.md.
--
-- 58 von 59 Skills. Ohne Zuordnung bleibt potenzen ("Potenzen und
-- Quadratzahlen", klasse_herkunft 7): der Katalog hat kein Potenz-Thema
-- unterhalb der Zweiten Stufe, und das Thema potenzen (Potenzgesetze,
-- wissenschaftliche Schreibweise) ist nicht der Ort, an dem der Stoff
-- eingefuehrt wird. Befund in docs/inhalte-themen/befunde.md.
--
-- Der Join auf skills und themen haelt die Datei in einer Datenbank ohne
-- einzelne Knoten lauffaehig (CI-Neuaufbau); on conflict laesst eine bereits
-- gesetzte Zuordnung stehen.

insert into public.skill_thema (skill_key, thema_key)
select v.skill_key, v.thema_key
  from (values
    -- Erprobungsstufe (Klasse 5/6)
    ('runden_ueberschlag',          'natuerliche_zahlen'),
    ('groessen_laengen',            'natuerliche_zahlen'),
    ('groessen_massen',             'natuerliche_zahlen'),
    ('groessen_zeit',               'natuerliche_zahlen'),
    ('groessen_gemischt',           'natuerliche_zahlen'),
    ('geo_koordinaten',             'geometrische_grundbegriffe'),
    ('geo_flaeche_rechteck',        'flaeche_umfang'),
    ('geo_umfang',                  'flaeche_umfang'),
    ('groessen_flaechen',           'flaeche_umfang'),
    ('geo_volumen_quader',          'koerper_quader'),
    ('groessen_volumen',            'koerper_quader'),
    ('bruch_kuerzen',               'brueche'),
    ('bruch_add',                   'rechnen_brueche_dezimalzahlen'),
    ('bruch_mult',                  'rechnen_brueche_dezimalzahlen'),
    ('bruch_div',                   'rechnen_brueche_dezimalzahlen'),
    ('bruch_dezimal',               'rechnen_brueche_dezimalzahlen'),
    ('dezimal_add_sub',             'rechnen_brueche_dezimalzahlen'),
    ('dezimal_mult',                'rechnen_brueche_dezimalzahlen'),
    ('dezimal_div',                 'rechnen_brueche_dezimalzahlen'),
    ('geo_massstab',                'ganze_zahlen_groessen'),
    -- Erste Stufe (Klasse 7/8)
    ('vorzeichen_add_sub',          'rationale_zahlen'),
    ('vorzeichen_mult_div',         'rationale_zahlen'),
    ('vorzeichen_vorrang',          'rationale_zahlen'),
    ('proportionalitaet',           'zuordnungen'),
    ('prozent_prozentwert',         'zinsrechnung'),
    ('prozent_grundwert',           'zinsrechnung'),
    ('prozent_prozentsatz',         'zinsrechnung'),
    ('prozent_veraenderung',        'zinsrechnung'),
    ('prozent_zins_jahreszins',     'zinsrechnung'),
    ('prozent_zins_teilzins',       'zinsrechnung'),
    ('prozent_zins_rueckrechnung',  'zinsrechnung'),
    ('prozent_zins_zinseszins',     'zinsrechnung'),
    ('term_einsetzen',              'terme_gleichungen'),
    ('term_zusammenfassen',         'terme_gleichungen'),
    ('term_ausmultiplizieren',      'terme_gleichungen'),
    ('term_minusklammer',           'terme_gleichungen'),
    ('term_ausklammern',            'terme_gleichungen'),
    ('gleichung_einschrittig',      'terme_gleichungen'),
    ('gleichung_zweischrittig',     'terme_gleichungen'),
    ('gleichung_beidseitig',        'terme_gleichungen'),
    ('gleichung_neg_koeffizient',   'terme_gleichungen'),
    ('gleichung_modellieren',       'terme_gleichungen'),
    ('geo_winkel_summe',            'winkel_dreiecke'),
    ('fkt_linear_steigung',         'lineare_funktionen'),
    ('fkt_linear_yabschnitt',       'lineare_funktionen'),
    ('fkt_linear_graph',            'lineare_funktionen'),
    ('fkt_linear_gleichung',        'lineare_funktionen'),
    ('fkt_linear_nullstelle',       'lineare_funktionen'),
    ('term_binom_quadrat',          'terme_binomische_formeln'),
    ('term_binom_quadratdifferenz', 'terme_binomische_formeln'),
    ('term_binom_gemischt',         'terme_binomische_formeln'),
    ('term_binom_faktorisieren',    'terme_binomische_formeln'),
    ('geo_flaeche_dreieck',         'flaechen_vielecke'),
    -- Zweite Stufe (Klasse 9/10)
    ('geo_kreis_umfang',            'kreis'),
    ('geo_kreis_flaeche',           'kreis'),
    ('geo_kreis_rueck',             'kreis'),
    ('geo_kreis_sektor',            'kreis'),
    ('geo_kreis_zusammen',          'kreis')
  ) as v (skill_key, thema_key)
  join public.skills s on s.skill_key = v.skill_key
  join public.themen th on th.thema_key = v.thema_key
on conflict (skill_key) do nothing;
