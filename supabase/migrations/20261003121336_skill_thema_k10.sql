-- ============================================================================
-- skill_thema — Heimat-Themen fuer die 15 K10-Knoten (W4 K10-Rest, Teil 3)
-- ============================================================================
--
-- Seit #192 findet freigabe_thema (Lenas Board) Aufgaben nur ueber
-- skill_thema. Jeder neue Knoten bekommt genau ein Heimat-Thema: das Thema,
-- in dem der Stoff im KLP eingefuehrt wird (Tabelle und Grenzfaelle in
-- docs/k10-rest/skill_thema.md):
--   fkt_exp_*    -> exponentialfunktionen (Fkt-10, Fkt-12, Ari-10, Ari-11;
--                   fkt_exp_gleichung ist Ari-10 und steht im Katalog dort)
--   geo_trigo_*  -> trigonometrie (Geo-7 bis Geo-10, auch der Kosinussatz)
--   fkt_sinus_*  -> sinusfunktion (Fkt-13, Fkt-14; der Einheitskreis ist
--                   Fkt-13, nicht Trigonometrie)
--
-- Einspiel-Reihenfolge: nach den drei substrat_k10_*-Dateien. Der Join auf
-- skills und themen haelt die Datei in einer Datenbank ohne diese Knoten
-- lauffaehig (CI-Neuaufbau); on conflict laesst eine bereits gesetzte
-- Zuordnung stehen. Kein begin/commit: `mig` spielt mit psql -1 ein.

insert into public.skill_thema (skill_key, thema_key)
select v.skill_key, v.thema_key
  from (values
    ('fkt_exp_wachstum',        'exponentialfunktionen'),
    ('fkt_exp_term',            'exponentialfunktionen'),
    ('fkt_exp_halbwert',        'exponentialfunktionen'),
    ('fkt_exp_gleichung',       'exponentialfunktionen'),
    ('fkt_exp_anwendung',       'exponentialfunktionen'),
    ('geo_trigo_verhaeltnis',   'trigonometrie'),
    ('geo_trigo_seite',         'trigonometrie'),
    ('geo_trigo_winkel',        'trigonometrie'),
    ('geo_trigo_anwendung',     'trigonometrie'),
    ('geo_trigo_kosinussatz',   'trigonometrie'),
    ('fkt_sinus_einheitskreis', 'sinusfunktion'),
    ('fkt_sinus_bogenmass',     'sinusfunktion'),
    ('fkt_sinus_graph',         'sinusfunktion'),
    ('fkt_sinus_parameter',     'sinusfunktion'),
    ('fkt_sinus_periodisch',    'sinusfunktion')
  ) v(skill_key, thema_key)
  join public.skills s on s.skill_key = v.skill_key
  join public.themen t on t.thema_key = v.thema_key
on conflict (skill_key) do nothing;
