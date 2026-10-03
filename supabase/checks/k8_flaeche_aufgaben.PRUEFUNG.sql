-- Pruefquery zu 20261003104949_aufgaben_k8_flaeche.sql — rein lesend.
-- Erwartung: jede Zeile ok = t.
-- -v lokal=true (Wegwerf-DB): cluster_id und "Alt-Slugs existieren" entfallen
-- (skill_clusters ist geseedet, die Alt-Slugs kommen aus einem Datenimport).

\if :{?lokal}
\else
  \set lokal false
\endif

with
c as (select t.*, s.correct_answers ca, s.acceptance acc, s.solution weg, s.typical_errors te, s.hints
        from public.tasks t left join public.task_solutions s on s.task_id = t.id
       where t.source = 'edvance_k8_flaeche'),
-- Antwort-Objekt je Format: NUMERIC {"value": …}, MC {"selected": [id]}
v as (select c.*, x.wert,
             case when c.input_type = 'MC' then jsonb_build_object('selected', jsonb_build_array(x.wert))
                  else jsonb_build_object('value', x.wert) end antwort
        from c, jsonb_array_elements_text(c.ca) x(wert)),
ke as (select c.id, c.skill_key, c.input_type, c.acc, c.ca, k.key wert, k.value slug,
              case when c.input_type = 'MC' then jsonb_build_object('selected', jsonb_build_array(k.key))
                   else jsonb_build_object('value', k.key) end antwort
         from c, jsonb_each_text(c.acc -> 'known_errors') k),
neu(slug) as (values ('nur_eine_grundseite'), ('teilflaeche_vergessen'))
select 'dreissig Aufgaben, alle draft und aktiv, 26 NUMERIC + 4 MC' pruefung,
       count(*) = 30 and bool_and(status = 'draft' and is_active)
       and count(*) filter (where input_type = 'NUMERIC') = 26
       and count(*) filter (where input_type = 'MC') = 4 ok from c
union all select 'je sechs zu trapez, drachen_raute, zusammengesetzt, term, rueck',
       (select array_agg(k || ':' || n order by k) from (select skill_key k, count(*) n from c group by 1) x)
       = array['geo_flaeche_drachen_raute:6', 'geo_flaeche_rueck:6', 'geo_flaeche_term:6',
               'geo_flaeche_trapez:6', 'geo_flaeche_zusammengesetzt:6']
union all select 'MC nur bei geo_flaeche_term',
       bool_and(input_type <> 'MC' or skill_key = 'geo_flaeche_term') from c
union all select 'Pflichtfelder am Item gesetzt (Klasse 8, geometrie, ohne Bild)',
       bool_and(afb in ('I','II','III') and est_duration_sec between 10 and 3600 and curriculum_grade = 8
                and class_level = 8 and competency_content = 'geometrie' and competency_process is not null
                and needs_image = false and parts = '[]'::jsonb and source_ref like 'flaeche-%'
                and (input_type = 'MC') = (unit is null)) from c
union all select 'MC: vier Optionen im Payload, genau eine richtige Options-ID',
       bool_and(jsonb_array_length(question_payload -> 'options') = 4
                and jsonb_array_length(ca) = 1
                and exists (select 1 from jsonb_array_elements(question_payload -> 'options') o where o ->> 'id' = ca ->> 0))
  from c where input_type = 'MC'
union all select 'cluster_id = Geometrie & Messen (nur Prod)',
       :lokal or bool_and(cluster_id = '3156b22e-ad3b-46c8-8c76-4155176cc52a') from c
union all select 'Loesung, Loesungsweg, typical_errors, keine Hinweise',
       bool_and(jsonb_typeof(ca) = 'array' and jsonb_array_length(ca) > 0 and nullif(btrim(weg), '') is not null
                and jsonb_array_length(te) > 0 and hints = '[]'::jsonb) from c
union all select 'acceptance gueltig: canonical, known_errors in Objektform',
       bool_and(public.lsa_acceptance_valid(acc) and acc ? 'canonical'
                and jsonb_typeof(acc -> 'known_errors') = 'object'
                and jsonb_typeof(acc -> 'known_errors') = 'object' and acc -> 'known_errors' <> '{}'::jsonb) from c
union all select 'jede richtige Variante: lsa_is_correct = true',
       (select bool_and(public.lsa_is_correct(input_type, ca, antwort)) from v)
union all select 'jede richtige Variante (NUMERIC): lsa_grade = voll',
       (select bool_and(public.lsa_grade(input_type, acc, ca, antwort) = 'voll') from v where input_type = 'NUMERIC')
union all select 'jeder falsche Wert: nicht richtig, nicht voll, trifft seinen Slug',
       (select bool_and(not public.lsa_is_correct(input_type, ca, antwort)
                        and public.lsa_grade(input_type, acc, ca, antwort) <> 'voll'
                        and public.lsa_fehlbild_match(case when input_type = 'MC' then 'mc' else 'numeric' end,
                                                      acc -> 'known_errors', antwort) = slug)
          from ke)
union all select 'neue Slugs existieren',
       (select bool_and(exists (select 1 from public.fehlbild_labels l where l.slug = ke.slug))
          from ke where slug in (select slug from neu))
union all select 'alle Slugs existieren (nur Prod)',
       :lokal or (select bool_and(exists (select 1 from public.fehlbild_labels l where l.slug = ke.slug)) from ke)
union all select 'jedes neue Fehlbild in mindestens drei Aufgaben',
       (select bool_and((select count(distinct id) from ke where ke.slug = neu.slug) >= 3) from neu)
union all select 'sondierrang: je Knoten genau Rang 1 und 2',
       (select bool_and(r = array[1,2]) from (select skill_key, array_agg(sondierrang order by sondierrang) r
          from c where sondierrang is not null group by 1) x)
       and (select count(distinct skill_key) from c where sondierrang is not null) = 5
union all select 'sondierrang: Rang 1 und 2 aus verschiedenen Fehlbildprofilen',
       (select bool_and(p1 <> p2) from (
          select skill_key,
                 max(p) filter (where sondierrang = 1) p1, max(p) filter (where sondierrang = 2) p2
            from (select c.skill_key, c.sondierrang,
                         (select string_agg(distinct e.v, ',' order by e.v) from jsonb_each_text(c.acc -> 'known_errors') e(k, v)) p
                    from c where c.sondierrang is not null) y group by 1) z)
union all select 'Kennzeichen vorbefuellt gesetzt',
       bool_and(vorbefuellt ? 'afb' and vorbefuellt -> 'hints' ->> 'art' = 'leer' and vorbefuellt_am is not null) from c
union all select 'keine Figuren (needs_image false, keine task_figures-Zeile)',
       not exists (select 1 from public.task_figures f join c on c.id = f.task_id)
union all select 'keine Mastery-Sprache',
       not exists (select 1 from c where (question || coalesce(weg, '') || te::text) ~* 'gemeistert|meisterst|mastered|beherrscht');

-- Uebersicht
select source_ref, skill_key, input_type typ, afb, est_duration_sec sek, sondierrang rang,
       acc ->> 'canonical' antwort,
       (select string_agg(distinct v, ', ') from jsonb_each_text(acc -> 'known_errors') e(k, v)) fehlbilder
  from (select t.*, s.acceptance acc from public.tasks t join public.task_solutions s on s.task_id = t.id
         where t.source = 'edvance_k8_flaeche') x
 order by skill_key, source_ref;
