-- ============================================================================
-- skill_thema — Nachtrag fuer die K9-Rest-Knoten (W4, Teil 5)
-- ============================================================================
--
-- Nach dem Einspielen von feat/k8-rest und feat/k9-rest hatten 37 neue
-- K9-Knoten kein Heimat-Thema (die 19 K8-Knoten ordnet k8-rest selbst zu).
-- Zuordnung aus docs/k9-rest/skill_thema.md (Branch feat/k9-rest), alle
-- Themen der Zweiten Stufe, passend zu klasse_herkunft 9. Grenzfaelle dort
-- begruendet: fkt_quadr_nullstellen -> quadratische_funktionen,
-- stoch_bedingt_irrefuehrend -> statistik_beurteilen.
--
-- potenzen bleibt weiter ohne Zuordnung (docs/inhalte-themen/befunde.md).
--
-- Der Join auf skills und themen haelt die Datei in einer Datenbank ohne
-- diese Knoten lauffaehig (CI-Neuaufbau); on conflict laesst eine bereits
-- gesetzte Zuordnung stehen.

insert into public.skill_thema (skill_key, thema_key)
select v.skill_key, v.thema_key
  from (values
    ('zahl_wurzel_quadrat',             'reelle_zahlen'),
    ('zahl_wurzel_naeherung',           'reelle_zahlen'),
    ('zahl_wurzel_irrational',          'reelle_zahlen'),
    ('zahl_wurzel_gesetze',             'reelle_zahlen'),
    ('zahl_wurzel_teilweise',           'reelle_zahlen'),
    ('zahl_potenz_gesetze',             'potenzen'),
    ('zahl_potenz_negativ',             'potenzen'),
    ('zahl_potenz_zehner',              'potenzen'),
    ('zahl_potenz_rechnen',             'potenzen'),
    ('gleichung_quadr_wurzel',          'quadratische_gleichungen'),
    ('gleichung_quadr_faktor',          'quadratische_gleichungen'),
    ('gleichung_quadr_formel',          'quadratische_gleichungen'),
    ('gleichung_quadr_anzahl',          'quadratische_gleichungen'),
    ('fkt_quadr_parabel',               'quadratische_funktionen'),
    ('fkt_quadr_scheitel',              'quadratische_funktionen'),
    ('fkt_quadr_normalform',            'quadratische_funktionen'),
    ('fkt_quadr_nullstellen',           'quadratische_funktionen'),
    ('fkt_quadr_extrem',                'quadratische_funktionen'),
    ('geo_pythagoras_hypotenuse',       'pythagoras'),
    ('geo_pythagoras_kathete',          'pythagoras'),
    ('geo_pythagoras_umkehrung',        'pythagoras'),
    ('geo_pythagoras_abstand',          'pythagoras'),
    ('geo_pythagoras_anwendung',        'pythagoras'),
    ('geo_koerper_prisma',              'prismen_zylinder'),
    ('geo_koerper_zylinder',            'prismen_zylinder'),
    ('geo_koerper_pyramide',            'koerper_pyramide_kegel_kugel'),
    ('geo_koerper_kegel',               'koerper_pyramide_kegel_kugel'),
    ('geo_koerper_kugel',               'koerper_pyramide_kegel_kugel'),
    ('stoch_bedingt_vierfeld',          'bedingte_wahrscheinlichkeit'),
    ('stoch_bedingt_wkeit',             'bedingte_wahrscheinlichkeit'),
    ('stoch_bedingt_unabhaengig',       'bedingte_wahrscheinlichkeit'),
    ('stoch_bedingt_umkehr',            'bedingte_wahrscheinlichkeit'),
    ('stoch_bedingt_irrefuehrend',      'statistik_beurteilen'),
    ('geo_aehnlich_streckfaktor',       'aehnlichkeit'),
    ('geo_aehnlich_flaeche',            'aehnlichkeit'),
    ('geo_aehnlich_strahlen_abschnitt', 'aehnlichkeit'),
    ('geo_aehnlich_strahlen_parallel',  'aehnlichkeit')
  ) as v (skill_key, thema_key)
  join public.skills s on s.skill_key = v.skill_key
  join public.themen th on th.thema_key = v.thema_key
on conflict (skill_key) do nothing;
