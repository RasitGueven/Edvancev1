-- Pruefquery zu 20261003121336_skill_thema_k10.sql (K10-Rest) — rein lesend.
-- Erwartung: jede Zeile ok = t.

with soll(skill_key, thema_key) as (values
  ('fkt_exp_wachstum', 'exponentialfunktionen'), ('fkt_exp_term', 'exponentialfunktionen'),
  ('fkt_exp_halbwert', 'exponentialfunktionen'), ('fkt_exp_gleichung', 'exponentialfunktionen'),
  ('fkt_exp_anwendung', 'exponentialfunktionen'),
  ('geo_trigo_verhaeltnis', 'trigonometrie'), ('geo_trigo_seite', 'trigonometrie'),
  ('geo_trigo_winkel', 'trigonometrie'), ('geo_trigo_anwendung', 'trigonometrie'),
  ('geo_trigo_kosinussatz', 'trigonometrie'),
  ('fkt_sinus_einheitskreis', 'sinusfunktion'), ('fkt_sinus_bogenmass', 'sinusfunktion'),
  ('fkt_sinus_graph', 'sinusfunktion'), ('fkt_sinus_parameter', 'sinusfunktion'),
  ('fkt_sinus_periodisch', 'sinusfunktion'))
select '15 K10-Knoten mit Heimat-Thema wie geplant' pruefung,
       (select count(*) from soll join public.skill_thema st using (skill_key, thema_key)) = 15 ok
union all select 'kein Skill ohne Heimat-Thema (ausser potenzen)',
       not exists (select 1 from public.skills s left join public.skill_thema st using (skill_key)
                    where st.skill_key is null and s.skill_key <> 'potenzen')
union all select 'freigabe-Sicht: jede K10-Aufgabe ueber skill_thema einem der drei Themen zugeordnet',
       not exists (select 1 from public.tasks t left join public.skill_thema st using (skill_key)
                    where t.source in ('edvance_k10_exp', 'edvance_k10_trigo', 'edvance_k10_sinus')
                      and st.thema_key is distinct from (select thema_key from soll where soll.skill_key = t.skill_key));
