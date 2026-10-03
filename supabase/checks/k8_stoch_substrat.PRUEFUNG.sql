-- Pruefquery zu 20261003104944_substrat_k8_stoch.sql — rein lesend (laeuft auch mit dbread).
-- Erwartung: 5 Knoten (Kl. 8, Tiefen 4/5/6/6/7), 9 Kanten, jede echt flacher, 7 neue
-- Fehlbild-Slugs mit Klartext und Erklaerung, alle unfreigegeben; jede Zeile ok = t.
--
--   psql <lokale-db> -X -P pager=off -v ON_ERROR_STOP=1 -v lokal=true -f supabase/checks/k8_stoch_substrat.PRUEFUNG.sql
--   ~/bin/dbread -f supabase/checks/k8_stoch_substrat.PRUEFUNG.sql                       (Prod, alles pruefen)
--
-- :lokal = true schaltet „wiederverwendete Alt-Slugs vorhanden" ab: die Alt-Slugs kommen
-- in Prod aus einem Datenimport, ein Neuaufbau aus Migrationen kennt sie nicht.

\if :{?lokal}
\else
  \set lokal false
\endif

select 'knoten' as pruefung,
       count(*) = 5 and bool_and(klasse_herkunft = 8 and fach = 'mathematik')
       and string_agg(skill_key || ':' || fundament_tiefe, ' ' order by skill_key)
           = 'stoch_gegenereignis:6 stoch_kenngroessen:4 stoch_laplace:5 stoch_pfad_produkt:6 stoch_pfad_summe:7' as ok,
       string_agg(skill_key || ':' || klasse_herkunft || '/' || fundament_tiefe, ' ' order by skill_key) as ist
  from public.skills where skill_key like 'stoch\_%'
union all
select 'kanten', count(*) = 9,
       string_agg(skill_key || '->' || voraussetzt_skill_key, ' ' order by skill_key, voraussetzt_skill_key)
  from public.skill_kante where skill_key like 'stoch\_%'
union all
select 'kanten_genau_wie_geplant',
       count(*) = 9 and bool_and((skill_key, voraussetzt_skill_key) in (
         ('stoch_kenngroessen', 'dezimal_div'), ('stoch_kenngroessen', 'vorzeichen_add_sub'),
         ('stoch_laplace', 'bruch_dezimal'),
         ('stoch_gegenereignis', 'stoch_laplace'), ('stoch_gegenereignis', 'bruch_add'),
         ('stoch_pfad_produkt', 'stoch_laplace'), ('stoch_pfad_produkt', 'bruch_mult'),
         ('stoch_pfad_summe', 'stoch_pfad_produkt'), ('stoch_pfad_summe', 'stoch_gegenereignis'))),
       ''
  from public.skill_kante where skill_key like 'stoch\_%'
union all
select 'kanten_echt_flacher', coalesce(bool_and(v.fundament_tiefe < s.fundament_tiefe), false),
       coalesce(string_agg(k.skill_key || '->' || k.voraussetzt_skill_key, ' ')
                filter (where v.fundament_tiefe >= s.fundament_tiefe), '')
  from public.skill_kante k
  join public.skills s on s.skill_key = k.skill_key
  join public.skills v on v.skill_key = k.voraussetzt_skill_key
 where k.skill_key like 'stoch\_%'
union all
select 'tiefe_gleich_1_plus_tiefste_voraussetzung',
       coalesce(bool_and(s.fundament_tiefe = 1 + x.maxv), false), ''
  from public.skills s
  join (select k.skill_key, max(v.fundament_tiefe) maxv from public.skill_kante k
          join public.skills v on v.skill_key = k.voraussetzt_skill_key group by 1) x on x.skill_key = s.skill_key
 where s.skill_key like 'stoch\_%'
union all
select 'kein_knoten_ohne_kante', not exists (
         select 1 from public.skills s where s.skill_key like 'stoch\_%'
            and not exists (select 1 from public.skill_kante k where k.skill_key = s.skill_key)), ''
union all
select 'fehlbilder_neu',
       count(*) = 7 and bool_and(freigegeben_am is null and familie is null
                                 and klartext <> '' and erklaerung <> ''),
       string_agg(slug, ' ' order by slug)
  from public.fehlbild_labels
 where slug in ('verhaeltnis_statt_anteil', 'zuruecklegen_ignoriert', 'pfadregel_addiert', 'nur_ein_pfad',
                'gegenereignis_nicht_abgezogen', 'mittelwert_statt_median', 'median_ohne_sortieren')
union all
select 'klartext_stichprobe_woertlich',
       (select klartext from public.fehlbild_labels where slug = 'verhaeltnis_statt_anteil')
         = 'Teilt die günstigen durch die übrigen statt durch alle möglichen Ergebnisse.'
       and (select klartext from public.fehlbild_labels where slug = 'median_ohne_sortieren')
         = 'Nimmt den mittleren Wert der Liste, ohne sie vorher zu ordnen.', ''
union all
select 'wiederverwendet_vorhanden (nur Prod)', :lokal or count(*) = 6, string_agg(slug, ' ' order by slug)
  from public.fehlbild_labels
 where slug in ('umgekehrt_geteilt', 'nenner_addiert', 'bedingung_unvollstaendig',
                'falsche_groesse_beantwortet', 'seiten_verwechselt', 'multipliziert_statt_dividiert');
