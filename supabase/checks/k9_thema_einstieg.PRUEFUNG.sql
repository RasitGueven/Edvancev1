-- Pruefquery zu 20261003105910_thema_einstieg_k9_rest.sql — rein lesend.
-- Erwartung: jede Zeile ok = t.

with soll(thema_key, skill_key) as (values
  ('reelle_zahlen', 'zahl_wurzel_irrational'), ('reelle_zahlen', 'zahl_wurzel_teilweise'),
  ('reelle_zahlen', 'zahl_wurzel_naeherung'),
  ('potenzen', 'zahl_potenz_rechnen'),
  ('quadratische_gleichungen', 'gleichung_quadr_formel'), ('quadratische_gleichungen', 'gleichung_quadr_faktor'),
  ('quadratische_funktionen', 'fkt_quadr_nullstellen'), ('quadratische_funktionen', 'fkt_quadr_normalform'),
  ('pythagoras', 'geo_pythagoras_kathete'), ('pythagoras', 'geo_pythagoras_abstand'),
  ('pythagoras', 'geo_pythagoras_umkehrung'),
  ('prismen_zylinder', 'geo_koerper_zylinder'),
  ('koerper_pyramide_kegel_kugel', 'geo_koerper_kegel'), ('koerper_pyramide_kegel_kugel', 'geo_koerper_kugel'),
  ('bedingte_wahrscheinlichkeit', 'stoch_bedingt_umkehr'), ('bedingte_wahrscheinlichkeit', 'stoch_bedingt_unabhaengig'),
  ('aehnlichkeit', 'geo_aehnlich_strahlen_parallel'), ('aehnlichkeit', 'geo_aehnlich_flaeche')),
themen(thema_key) as (select distinct thema_key from soll)
select '18 Einstiege fuer 9 Themen eingetragen' pruefung,
       (select count(*) from soll join public.thema_einstieg e using (thema_key, skill_key)) = 18 ok
union all select 'keine weiteren Einstiege fuer diese Themen',
       (select count(*) from public.thema_einstieg e where e.thema_key in (select thema_key from themen)) = 18
union all select 'hoechstens drei Einstiege je Thema dieses Laufs',
       (select coalesce(max(n), 0) <= 3 from (select thema_key, count(*) n from public.thema_einstieg
          where thema_key in (select thema_key from themen) group by 1) x)
union all select 'kein Einstieg im Abschluss eines anderen Einstiegs desselben Themas',
       not exists (select 1 from soll a join soll b on a.thema_key = b.thema_key and a.skill_key <> b.skill_key
                    where b.skill_key in (select x.skill_key from public.lsa_abschluss(a.skill_key) x))
union all select 'Bestand unveraendert: kreis 2, lineare_funktionen 3, zinsrechnung 2, Binom 4, Gleichungen 1',
       (select count(*) from public.thema_einstieg
         where thema_key in ('kreis','lineare_funktionen','zinsrechnung','terme_binomische_formeln','terme_gleichungen')) = 12
union all select 'jeder Einstiegsknoten hat Aufgaben (draft oder ready)',
       not exists (select 1 from soll where not exists (select 1 from public.tasks t where t.skill_key = soll.skill_key and t.is_active));
