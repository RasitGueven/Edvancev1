-- Pruefquery zu 20261003104945_substrat_k8_flaeche.sql (nur lesend).
-- Erwartung: 5 Knoten (Kl. 8, Tiefen trapez 5, drachen_raute 5, zusammengesetzt 6,
-- term 6, rueck 6), 9 Kanten, jede echt flacher, 2 neue Fehlbilder unfreigegeben mit
-- Klartext, die wiederverwendeten Alt-Slugs vorhanden. Jede Zeile ok = t.
--
-- -v lokal=true (Wegwerf-DB): "wiederverwendet vorhanden" entfaellt — die Alt-Slugs
-- kommen in Prod aus einem Datenimport, nicht aus Migrationen.

\if :{?lokal}
\else
  \set lokal false
\endif

select 'knoten: fuenf, Klasse 8, Tiefen 5/5/6/6/6' as pruefung,
       count(*) = 5 and bool_and(klasse_herkunft = 8 and fach = 'mathematik')
       and string_agg(skill_key || ':' || fundament_tiefe, ' ' order by skill_key)
           = 'geo_flaeche_drachen_raute:5 geo_flaeche_rueck:6 geo_flaeche_term:6 geo_flaeche_trapez:5 geo_flaeche_zusammengesetzt:6' as ok,
       string_agg(skill_key || ':' || klasse_herkunft || '/' || fundament_tiefe, ' ' order by skill_key) as ist
  from public.skills
 where skill_key in ('geo_flaeche_trapez', 'geo_flaeche_drachen_raute', 'geo_flaeche_zusammengesetzt',
                     'geo_flaeche_term', 'geo_flaeche_rueck')
union all
select 'kanten: neun, genau die geplanten', count(*) = 9
       and string_agg(k.skill_key || '->' || k.voraussetzt_skill_key, ' ' order by k.skill_key, k.voraussetzt_skill_key)
           = 'geo_flaeche_drachen_raute->geo_flaeche_dreieck geo_flaeche_rueck->geo_flaeche_trapez '
             'geo_flaeche_rueck->gleichung_einschrittig geo_flaeche_term->geo_flaeche_dreieck '
             'geo_flaeche_term->term_ausmultiplizieren geo_flaeche_term->term_einsetzen '
             'geo_flaeche_trapez->geo_flaeche_dreieck geo_flaeche_zusammengesetzt->geo_flaeche_drachen_raute '
             'geo_flaeche_zusammengesetzt->geo_flaeche_trapez',
       count(*)::text
  from public.skill_kante k
 where k.skill_key in ('geo_flaeche_trapez', 'geo_flaeche_drachen_raute', 'geo_flaeche_zusammengesetzt',
                       'geo_flaeche_term', 'geo_flaeche_rueck')
union all
select 'kanten echt flacher', bool_and(v.fundament_tiefe < s.fundament_tiefe),
       coalesce(string_agg(k.skill_key || '->' || k.voraussetzt_skill_key, ' ')
                filter (where v.fundament_tiefe >= s.fundament_tiefe), '')
  from public.skill_kante k
  join public.skills s on s.skill_key = k.skill_key
  join public.skills v on v.skill_key = k.voraussetzt_skill_key
 where k.skill_key like 'geo_flaeche_%' and s.klasse_herkunft = 8
union all
select 'keine Kante auf die neuen Knoten von aussen', count(*) = 0, coalesce(string_agg(skill_key, ' '), '')
  from public.skill_kante
 where voraussetzt_skill_key in ('geo_flaeche_trapez', 'geo_flaeche_drachen_raute', 'geo_flaeche_zusammengesetzt',
                                 'geo_flaeche_term', 'geo_flaeche_rueck')
   and skill_key not like 'geo_flaeche_%'
union all
select 'fehlbilder neu: zwei, unfreigegeben, Klartext woertlich, Familie NULL',
       count(*) = 2 and bool_and(freigegeben_am is null and familie is null and erklaerung <> '')
       and bool_and(klartext = case slug
             when 'nur_eine_grundseite' then 'Rechnet beim Trapez nur mit einer der beiden parallelen Seiten.'
             when 'teilflaeche_vergessen' then 'Lässt bei einer zusammengesetzten Figur eine Teilfläche weg.' end),
       string_agg(slug, ' ' order by slug)
  from public.fehlbild_labels
 where slug in ('nur_eine_grundseite', 'teilflaeche_vergessen')
union all
select 'wiederverwendet vorhanden (nur Prod)',
       :lokal or count(*) = 8, string_agg(slug, ' ' order by slug)
  from public.fehlbild_labels
 where slug in ('halbieren_vergessen', 'halbieren_faelschlich', 'falsche_hoehe', 'umfang_statt_flaeche',
                'plus_statt_mal', 'klammer_vergessen', 'falsche_gegenoperation', 'falsche_groesse_beantwortet');
