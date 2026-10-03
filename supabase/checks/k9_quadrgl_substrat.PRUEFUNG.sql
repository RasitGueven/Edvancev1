-- Pruefquery zu 20261003105854_substrat_k9_quadrgl.sql (nur lesend).
-- Erzeugt von tools/k9-rest-pruefung.mjs aus docs/k9-rest/graph.json — unabhaengig von der Migration.
-- Erwartung: jede Zeile ok = t.
\if :{?lokal}
\else
  \set lokal false
\endif

with soll(skill_key, label, tiefe) as (values
  ('gleichung_quadr_wurzel', 'Quadratische Gleichungen durch Wurzelziehen', 7),
  ('gleichung_quadr_faktor', 'Quadratische Gleichungen durch Ausklammern (Nullprodukt)', 8),
  ('gleichung_quadr_formel', 'Lösungsformel (p-q- bzw. abc-Formel)', 8),
  ('gleichung_quadr_anzahl', 'Anzahl der Lösungen (Diskriminante)', 9)
),
soll_kante(skill_key, voraussetzt) as (values
  ('gleichung_quadr_wurzel', 'zahl_wurzel_quadrat'),
  ('gleichung_quadr_wurzel', 'gleichung_zweischrittig'),
  ('gleichung_quadr_faktor', 'term_ausklammern'),
  ('gleichung_quadr_faktor', 'gleichung_einschrittig'),
  ('gleichung_quadr_formel', 'gleichung_quadr_wurzel'),
  ('gleichung_quadr_formel', 'term_einsetzen'),
  ('gleichung_quadr_anzahl', 'gleichung_quadr_formel')
)
select 'knoten: 4, Klasse 9, Tiefe und Label wie geplant' as pruefung,
       (select count(*) from soll join public.skills s using (skill_key)
         where s.klasse_herkunft = 9 and s.fundament_tiefe = soll.tiefe and s.label = soll.label
           and s.fach = 'mathematik') = 4 as ok,
       (select string_agg(s.skill_key || ':' || s.klasse_herkunft || '/' || s.fundament_tiefe, ' ' order by s.skill_key)
          from public.skills s join soll using (skill_key)) as ist
union all
select 'kanten: genau die 7 geplanten',
       (select count(*) from soll_kante k join public.skill_kante x
           on x.skill_key = k.skill_key and x.voraussetzt_skill_key = k.voraussetzt) = 7
       and (select count(*) from public.skill_kante x where x.skill_key in (select skill_key from soll)) = 7,
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
select 'neue Fehlbilder: 5, Klartext + Erklaerung, nicht freigegeben',
       count(*) = 5 and coalesce(bool_and(freigegeben_am is null and klartext <> '' and erklaerung <> ''), false),
       coalesce(string_agg(slug, ' ' order by slug), '')
  from public.fehlbild_labels
 where slug in ('wurzel_vergessen', 'negative_loesung_vergessen', 'pq_vorzeichen', 'vorzeichen_aus_klammer', 'loesung_null_verloren')
union all
select 'neue Fehlbilder: Familie wie geplant',
       count(*) = 5, ''
  from public.fehlbild_labels l
  join (values ('wurzel_vergessen', 'gleichungen_umformen'), ('negative_loesung_vergessen', 'gleichungen_umformen'), ('pq_vorzeichen', 'vorzeichen'), ('vorzeichen_aus_klammer', 'vorzeichen'), ('loesung_null_verloren', 'gleichungen_umformen')) f(slug, familie)
    on f.slug = l.slug and l.familie is not distinct from f.familie
;
