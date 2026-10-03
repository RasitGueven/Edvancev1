-- Pruefquery zu 20261003121329_substrat_k10_trigo.sql (nur lesend).
-- Erzeugt von tools/k10-rest-pruefung.mjs aus docs/k10-rest/graph.json — unabhaengig von der Migration.
-- Erwartung: jede Zeile ok = t.
\if :{?lokal}
\else
  \set lokal false
\endif

with soll(skill_key, label, tiefe) as (values
  ('geo_trigo_verhaeltnis', 'Sinus, Kosinus und Tangens als Seitenverhältnisse', 7),
  ('geo_trigo_seite', 'Seiten im rechtwinkligen Dreieck berechnen', 8),
  ('geo_trigo_winkel', 'Winkel im rechtwinkligen Dreieck berechnen', 8),
  ('geo_trigo_anwendung', 'Trigonometrie in Sachsituationen (Steigung, Höhe, Entfernung)', 9),
  ('geo_trigo_kosinussatz', 'Kosinussatz im allgemeinen Dreieck', 9)
),
soll_kante(skill_key, voraussetzt) as (values
  ('geo_trigo_verhaeltnis', 'geo_aehnlich_streckfaktor'),
  ('geo_trigo_verhaeltnis', 'geo_pythagoras_hypotenuse'),
  ('geo_trigo_seite', 'geo_trigo_verhaeltnis'),
  ('geo_trigo_seite', 'gleichung_einschrittig'),
  ('geo_trigo_winkel', 'geo_trigo_verhaeltnis'),
  ('geo_trigo_anwendung', 'geo_trigo_seite'),
  ('geo_trigo_anwendung', 'geo_trigo_winkel'),
  ('geo_trigo_anwendung', 'fkt_linear_steigung'),
  ('geo_trigo_kosinussatz', 'geo_trigo_winkel'),
  ('geo_trigo_kosinussatz', 'term_einsetzen')
)
select 'knoten: 5, Klasse 10, Tiefe und Label wie geplant' as pruefung,
       (select count(*) from soll join public.skills s using (skill_key)
         where s.klasse_herkunft = 10 and s.fundament_tiefe = soll.tiefe and s.label = soll.label
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
select 'neue Fehlbilder: 6, Klartext + Erklaerung, nicht freigegeben',
       count(*) = 6 and coalesce(bool_and(freigegeben_am is null and klartext <> '' and erklaerung <> ''), false),
       coalesce(string_agg(slug, ' ' order by slug), '')
  from public.fehlbild_labels
 where slug in ('sin_cos_vertauscht', 'tangens_verwechselt', 'umkehrfunktion_vergessen', 'bogenmass_modus', 'kosinussatz_vorzeichen', 'pythagoras_ohne_rechten_winkel')
union all
select 'neue Fehlbilder: Familie wie geplant',
       count(*) = 6, ''
  from public.fehlbild_labels l
  join (values ('sin_cos_vertauscht', null::text), ('tangens_verwechselt', null::text), ('umkehrfunktion_vergessen', null::text), ('bogenmass_modus', null::text), ('kosinussatz_vorzeichen', 'vorzeichen'), ('pythagoras_ohne_rechten_winkel', null::text)) f(slug, familie)
    on f.slug = l.slug and l.familie is not distinct from f.familie
;
