-- Pruefquery zu 20261003105856_substrat_k9_quadrfkt.sql (nur lesend).
-- Erzeugt von tools/k9-rest-pruefung.mjs aus docs/k9-rest/graph.json — unabhaengig von der Migration.
-- Erwartung: jede Zeile ok = t.
\if :{?lokal}
\else
  \set lokal false
\endif

with soll(skill_key, label, tiefe) as (values
  ('fkt_quadr_parabel', 'Normalparabel verschieben und strecken', 6),
  ('fkt_quadr_scheitel', 'Scheitelpunkt aus der Scheitelpunktform', 7),
  ('fkt_quadr_normalform', 'Von der Normalform zur Scheitelpunktform', 8),
  ('fkt_quadr_nullstellen', 'Nullstellen quadratischer Funktionen', 9),
  ('fkt_quadr_extrem', 'Extremwertaufgaben mit quadratischen Funktionen', 9)
),
soll_kante(skill_key, voraussetzt) as (values
  ('fkt_quadr_parabel', 'term_einsetzen'),
  ('fkt_quadr_parabel', 'geo_koordinaten'),
  ('fkt_quadr_scheitel', 'fkt_quadr_parabel'),
  ('fkt_quadr_normalform', 'fkt_quadr_scheitel'),
  ('fkt_quadr_normalform', 'term_binom_quadrat'),
  ('fkt_quadr_nullstellen', 'gleichung_quadr_formel'),
  ('fkt_quadr_nullstellen', 'fkt_quadr_parabel'),
  ('fkt_quadr_extrem', 'fkt_quadr_normalform'),
  ('fkt_quadr_extrem', 'gleichung_modellieren')
)
select 'knoten: 5, Klasse 9, Tiefe und Label wie geplant' as pruefung,
       (select count(*) from soll join public.skills s using (skill_key)
         where s.klasse_herkunft = 9 and s.fundament_tiefe = soll.tiefe and s.label = soll.label
           and s.fach = 'mathematik') = 5 as ok,
       (select string_agg(s.skill_key || ':' || s.klasse_herkunft || '/' || s.fundament_tiefe, ' ' order by s.skill_key)
          from public.skills s join soll using (skill_key)) as ist
union all
select 'kanten: genau die 9 geplanten',
       (select count(*) from soll_kante k join public.skill_kante x
           on x.skill_key = k.skill_key and x.voraussetzt_skill_key = k.voraussetzt) = 9
       and (select count(*) from public.skill_kante x where x.skill_key in (select skill_key from soll)) = 9,
       (select count(*)::text from public.skill_kante x where x.skill_key in (select skill_key from soll))
union all
select 'kanten echt flacher (Tiefen-Guard)',
       coalesce(bool_and(v.fundament_tiefe < s.fundament_tiefe), false),
       coalesce(string_agg(k.skill_key || '->' || k.voraussetzt_skill_key, ' ')
                filter (where v.fundament_tiefe >= s.fundament_tiefe), '')
  from public.skill_kante k
  join public.skills s on s.skill_key = k.skill_key
  join public.skills v on v.skill_key = k.voraussetzt_skill_key
 where k.skill_key in (select skill_key from soll)
union all
select 'Tiefe = 1 + tiefste Voraussetzung',
       coalesce(bool_and(s.fundament_tiefe = 1 + m.t), false), coalesce(string_agg(s.skill_key, ' ') filter (where s.fundament_tiefe <> 1 + m.t), '')
  from public.skills s
  join (select k.skill_key, max(v.fundament_tiefe) t from public.skill_kante k
          join public.skills v on v.skill_key = k.voraussetzt_skill_key group by 1) m using (skill_key)
 where s.skill_key in (select skill_key from soll)
union all
select 'neue Fehlbilder: 3, Klartext + Erklaerung, nicht freigegeben',
       count(*) = 3 and coalesce(bool_and(freigegeben_am is null and klartext <> '' and erklaerung <> ''), false),
       coalesce(string_agg(slug, ' ' order by slug), '')
  from public.fehlbild_labels
 where slug in ('pq_vorzeichen', 'vorzeichen_aus_klammer', 'ergaenzung_vorzeichen')
union all
select 'neue Fehlbilder: Familie wie geplant',
       count(*) = 3, ''
  from public.fehlbild_labels l
  join (values ('pq_vorzeichen', 'vorzeichen'), ('vorzeichen_aus_klammer', 'vorzeichen'), ('ergaenzung_vorzeichen', 'gleichungen_umformen')) f(slug, familie)
    on f.slug = l.slug and l.familie is not distinct from f.familie
;
