-- Pruefquery zu 20261003105858_substrat_k9_koerper.sql (nur lesend).
-- Erzeugt von tools/k9-rest-pruefung.mjs aus docs/k9-rest/graph.json — unabhaengig von der Migration.
-- Erwartung: jede Zeile ok = t.
\if :{?lokal}
\else
  \set lokal false
\endif

with soll(skill_key, label, tiefe) as (values
  ('geo_koerper_prisma', 'Volumen und Oberfläche des Prismas', 5),
  ('geo_koerper_zylinder', 'Volumen und Oberfläche des Zylinders', 7),
  ('geo_koerper_pyramide', 'Volumen und Oberfläche der Pyramide', 6),
  ('geo_koerper_kegel', 'Volumen und Oberfläche des Kegels', 8),
  ('geo_koerper_kugel', 'Volumen und Oberfläche der Kugel', 7)
),
soll_kante(skill_key, voraussetzt) as (values
  ('geo_koerper_prisma', 'geo_volumen_quader'),
  ('geo_koerper_prisma', 'geo_flaeche_dreieck'),
  ('geo_koerper_zylinder', 'geo_koerper_prisma'),
  ('geo_koerper_zylinder', 'geo_kreis_flaeche'),
  ('geo_koerper_zylinder', 'geo_kreis_umfang'),
  ('geo_koerper_pyramide', 'geo_koerper_prisma'),
  ('geo_koerper_kegel', 'geo_koerper_zylinder'),
  ('geo_koerper_kegel', 'geo_koerper_pyramide'),
  ('geo_koerper_kegel', 'geo_pythagoras_hypotenuse'),
  ('geo_koerper_kugel', 'geo_kreis_flaeche')
)
select 'knoten: 5, Klasse 9, Tiefe und Label wie geplant' as pruefung,
       (select count(*) from soll join public.skills s using (skill_key)
         where s.klasse_herkunft = 9 and s.fundament_tiefe = soll.tiefe and s.label = soll.label
           and s.fach = 'mathematik') = 5 as ok,
       (select string_agg(s.skill_key || ':' || s.klasse_herkunft || '/' || s.fundament_tiefe, ' ' order by s.skill_key)
          from public.skills s join soll using (skill_key)) as ist
union all
select 'kanten: genau die 10 geplanten',
       (select count(*) from soll_kante k join public.skill_kante x
           on x.skill_key = k.skill_key and x.voraussetzt_skill_key = k.voraussetzt) = 10
       and (select count(*) from public.skill_kante x where x.skill_key in (select skill_key from soll)) = 10,
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
 where slug in ('wurzel_vergessen', 'hypotenuse_verwechselt', 'drittel_vergessen')
union all
select 'neue Fehlbilder: Familie wie geplant',
       count(*) = 3, ''
  from public.fehlbild_labels l
  join (values ('wurzel_vergessen', 'gleichungen_umformen'), ('hypotenuse_verwechselt', null::text), ('drittel_vergessen', null::text)) f(slug, familie)
    on f.slug = l.slug and l.familie is not distinct from f.familie
;
