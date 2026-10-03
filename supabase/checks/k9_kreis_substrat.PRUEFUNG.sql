-- Pruefquery zu 20261003091339_substrat_k9_kreis.sql (nur lesend).
-- Erwartung: 5 Knoten (Kl. 9, Tiefen 6/6/7/7/7), 16 Kanten, jede Kante echt
-- flacher, 3 neue + 1 geteilter Fehlbild-Slug, alle neuen unfreigegeben.
select 'knoten' as pruefung, count(*) = 5 as ok,
       string_agg(skill_key || ':' || klasse_herkunft || '/' || fundament_tiefe, ' ' order by skill_key) as ist
  from public.skills where skill_key like 'geo_kreis_%'
union all
select 'kanten', count(*) = 16, count(*)::text
  from public.skill_kante where skill_key like 'geo_kreis_%'
union all
select 'kanten_echt_flacher', bool_and(v.fundament_tiefe < s.fundament_tiefe),
       coalesce(string_agg(k.skill_key || '->' || k.voraussetzt_skill_key, ' ')
                filter (where v.fundament_tiefe >= s.fundament_tiefe), '')
  from public.skill_kante k
  join public.skills s on s.skill_key = k.skill_key
  join public.skills v on v.skill_key = k.voraussetzt_skill_key
 where k.skill_key like 'geo_kreis_%'
union all
select 'fehlbilder_neu', count(*) = 3 and bool_and(freigegeben_am is null) and bool_and(klartext <> ''),
       string_agg(slug, ' ' order by slug)
  from public.fehlbild_labels
 where slug in ('radius_durchmesser_verwechselt', 'pi_vergessen',
                'kreisanteil_falsch')
union all
select 'zu_frueh_gerundet', count(*) = 1, max(klartext)
  from public.fehlbild_labels where slug = 'zu_frueh_gerundet'
union all
select 'wiederverwendet_vorhanden', count(*) = 5, string_agg(slug, ' ' order by slug)
  from public.fehlbild_labels
 where slug in ('flaeche_statt_umfang', 'umfang_statt_flaeche', 'mal_exponent',
                'halbieren_vergessen', 'seite_vergessen')
union all
select 'flaecheneinheit_nicht_angelegt', count(*) = 0, ''
  from public.fehlbild_labels where slug = 'flaecheneinheit_nicht_quadriert';
