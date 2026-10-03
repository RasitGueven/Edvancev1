-- Pruefquery zu 20261003104951_thema_einstieg_k8_rest.sql — rein lesend.
-- Erwartung: jede Zeile ok = t.
with soll(thema_key, skill_key) as (values
  ('lineare_gleichungen_lgs', 'gleichung_lgs_einsetzen'),
  ('lineare_gleichungen_lgs', 'gleichung_lgs_addition'),
  ('lineare_gleichungen_lgs', 'gleichung_lgs_grafisch'),
  ('zufallsexperimente',      'stoch_pfad_summe'),
  ('flaechen_vielecke',       'geo_flaeche_trapez'),
  ('flaechen_vielecke',       'geo_flaeche_drachen_raute'),
  ('flaechen_vielecke',       'geo_flaeche_term'),
  ('winkel_dreiecke',         'geo_winkel_dreieck'),
  ('thales_konstruktionen',   'geo_winkel_thales')),
themen(k) as (select distinct thema_key from soll)
select 'neun Einstiege vorhanden' pruefung,
       (select count(*) from soll s join public.thema_einstieg e using (thema_key, skill_key)) = 9 ok
union all select 'keine weiteren Einstiege in den fuenf Themen',
       (select count(*) from public.thema_einstieg e where e.thema_key in (select k from themen)) = 9
union all select 'hoechstens drei je Thema',
       (select bool_and(n <= 3) from (select thema_key, count(*) n from public.thema_einstieg
          where thema_key in (select k from themen) group by 1) x)
union all select 'jeder Einstiegsknoten hat Aufgaben (draft oder ready)',
       (select bool_and(exists (select 1 from public.tasks t where t.skill_key = s.skill_key and t.status in ('draft', 'ready')))
          from soll s)
union all select 'kein Einstieg ist ein Sachknoten',
       not exists (select 1 from soll where skill_key like '%sachaufgabe%')
union all select 'uebrige Einstiege unveraendert (12)',
       (select count(*) from public.thema_einstieg e where e.thema_key not in (select k from themen)) = 12;
