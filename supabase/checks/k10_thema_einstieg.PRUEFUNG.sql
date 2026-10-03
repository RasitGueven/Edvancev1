-- Pruefquery zu 20261003121335_thema_einstieg_k10.sql (K10-Rest) — rein lesend.
-- Erwartung: jede Zeile ok = t.

with soll(thema_key, skill_key) as (values
  ('exponentialfunktionen', 'fkt_exp_term'), ('exponentialfunktionen', 'fkt_exp_halbwert'),
  ('exponentialfunktionen', 'fkt_exp_gleichung'),
  ('trigonometrie', 'geo_trigo_kosinussatz'), ('trigonometrie', 'geo_trigo_seite'),
  ('sinusfunktion', 'fkt_sinus_parameter')),
themen(thema_key) as (select distinct thema_key from soll)
select '6 Einstiege fuer 3 Themen eingetragen' pruefung,
       (select count(*) from soll join public.thema_einstieg e using (thema_key, skill_key)) = 6 ok
union all select 'keine weiteren Einstiege fuer diese Themen',
       (select count(*) from public.thema_einstieg e where e.thema_key in (select thema_key from themen)) = 6
union all select 'hoechstens drei Einstiege je Thema dieses Laufs',
       (select coalesce(max(n), 0) <= 3 from (select thema_key, count(*) n from public.thema_einstieg
          where thema_key in (select thema_key from themen) group by 1) x)
union all select 'kein Einstieg im Abschluss eines anderen Einstiegs desselben Themas',
       not exists (select 1 from soll a join soll b on a.thema_key = b.thema_key and a.skill_key <> b.skill_key
                    where b.skill_key in (select x.skill_key from public.lsa_abschluss(a.skill_key) x))
union all select 'jeder Einstieg hat sein Thema als Heimat-Thema (nach skill_thema_k10)',
       not exists (select 1 from soll left join public.skill_thema st using (skill_key)
                    where st.thema_key is distinct from soll.thema_key)
union all select 'Bestand unveraendert: 39 Einstiege anderer Themen',
       (select count(*) from public.thema_einstieg where thema_key not in (select thema_key from themen)) = 39
union all select 'jeder Einstiegsknoten hat Aufgaben (draft oder ready)',
       not exists (select 1 from soll where not exists (select 1 from public.tasks t where t.skill_key = soll.skill_key and t.is_active));
