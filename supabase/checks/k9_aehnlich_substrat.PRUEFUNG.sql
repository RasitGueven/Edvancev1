-- Pruefquery zu 20261003105900_substrat_k9_aehnlich.sql (nur lesend).
-- Erzeugt von tools/k9-rest-pruefung.mjs aus docs/k9-rest/graph.json — unabhaengig von der Migration.
-- Erwartung: jede Zeile ok = t.
\if :{?lokal}
\else
  \set lokal false
\endif

with soll(skill_key, label, tiefe) as (values
  ('geo_aehnlich_streckfaktor', 'Streckfaktor und zentrische Streckung', 6),
  ('geo_aehnlich_flaeche', 'Flächen und Volumen bei Ähnlichkeit', 7),
  ('geo_aehnlich_strahlen_abschnitt', 'Erster Strahlensatz', 7),
  ('geo_aehnlich_strahlen_parallel', 'Zweiter Strahlensatz', 8)
),
soll_kante(skill_key, voraussetzt) as (values
  ('geo_aehnlich_streckfaktor', 'geo_massstab'),
  ('geo_aehnlich_flaeche', 'geo_aehnlich_streckfaktor'),
  ('geo_aehnlich_flaeche', 'potenzen'),
  ('geo_aehnlich_strahlen_abschnitt', 'geo_aehnlich_streckfaktor'),
  ('geo_aehnlich_strahlen_abschnitt', 'gleichung_einschrittig'),
  ('geo_aehnlich_strahlen_parallel', 'geo_aehnlich_strahlen_abschnitt')
)
select 'knoten: 4, Klasse 9, Tiefe und Label wie geplant' as pruefung,
       (select count(*) from soll join public.skills s using (skill_key)
         where s.klasse_herkunft = 9 and s.fundament_tiefe = soll.tiefe and s.label = soll.label
           and s.fach = 'mathematik') = 4 as ok,
       (select string_agg(s.skill_key || ':' || s.klasse_herkunft || '/' || s.fundament_tiefe, ' ' order by s.skill_key)
          from public.skills s join soll using (skill_key)) as ist
union all
select 'kanten: genau die 6 geplanten',
       (select count(*) from soll_kante k join public.skill_kante x
           on x.skill_key = k.skill_key and x.voraussetzt_skill_key = k.voraussetzt) = 6
       and (select count(*) from public.skill_kante x where x.skill_key in (select skill_key from soll)) = 6,
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
 where slug in ('streckfaktor_kehrwert', 'strahlensatz_falsch_zugeordnet', 'additiv_statt_multiplikativ')
union all
select 'neue Fehlbilder: Familie wie geplant',
       count(*) = 3, ''
  from public.fehlbild_labels l
  join (values ('streckfaktor_kehrwert', 'einheiten_massstab'), ('strahlensatz_falsch_zugeordnet', null::text), ('additiv_statt_multiplikativ', 'einheiten_massstab')) f(slug, familie)
    on f.slug = l.slug and l.familie is not distinct from f.familie
;
