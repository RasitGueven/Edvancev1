-- Pruefquery zu 20261003104950_aufgaben_k8_winkel.sql — rein lesend (laeuft auch mit dbread).
-- Erwartung: jede Zeile ok = t.
--
--   psql … -v ON_ERROR_STOP=1 [-v lokal=true] -f supabase/checks/k8_winkel_aufgaben.PRUEFUNG.sql
-- lokal=true (Wegwerf-DB / CI-Neuaufbau): skill_clusters ist dort nicht geseedet
-- (cluster_id bleibt null), und die wiederverwendeten Alt-Slugs (Datenimport) fehlen.
-- Ohne Variable wird beides streng geprueft (Prod).

\if :{?lokal}
\else
  \set lokal false
\endif

with
c as (select t.*, s.correct_answers ca, s.acceptance acc, s.solution weg, s.typical_errors te, s.hints
        from public.tasks t left join public.task_solutions s on s.task_id = t.id
       where t.source = 'edvance_k8_winkel'),
ke as (select c.id, c.skill_key, k.key wert, k.value slug, c.input_type, c.acc, c.ca
         from c, jsonb_each_text(c.acc -> 'known_errors') k),
neu(slug) as (values ('winkelbeziehung_verwechselt'), ('basiswinkel_falsch_zugeordnet'),
                     ('rechter_winkel_falsche_ecke'), ('aussenwinkel_verwechselt')),
alt(slug) as (values ('summe_360_statt_180'), ('differenz_vergessen'), ('halbieren_vergessen'))
select 'vierundzwanzig Aufgaben, alle draft, NUMERIC, aktiv, Einheit °' pruefung,
       count(*) = 24 and bool_and(status = 'draft' and input_type = 'NUMERIC' and is_active and unit = '°') ok from c
union all select 'je sechs zu neben_scheitel, parallelen, dreieck, thales',
       (select array_agg(k || ':' || n order by k) from (select skill_key k, count(*) n from c group by 1) x)
       = array['geo_winkel_dreieck:6', 'geo_winkel_neben_scheitel:6', 'geo_winkel_parallelen:6', 'geo_winkel_thales:6']
union all select 'Pflichtfelder am Item gesetzt (class_level 8, Stoffanker 8, geometrie)',
       bool_and(afb in ('I','II','III') and est_duration_sec between 10 and 3600 and curriculum_grade = 8
                and class_level = 8 and competency_content = 'geometrie' and competency_process is not null
                and needs_image is not null and parts = '[]'::jsonb and source_ref like 'winkel-%') from c
union all select 'Zeitregel: AFB I 45, II 60, III 90 (+30 Sachkontext)',
       bool_and(est_duration_sec in (45, 60, 90, 75, 120)) from c
union all select 'cluster_id = Geometrie & Messen (nur Prod)',
       :lokal or bool_and(cluster_id = '3156b22e-ad3b-46c8-8c76-4155176cc52a') from c
union all select 'Loesung, Loesungsweg, typical_errors, keine Hinweise',
       bool_and(jsonb_typeof(ca) = 'array' and jsonb_array_length(ca) > 0 and nullif(btrim(weg), '') is not null
                and jsonb_array_length(te) > 0 and hints = '[]'::jsonb) from c
union all select 'acceptance gueltig: canonical, equivalents, known_errors in Objektform',
       bool_and(public.lsa_acceptance_valid(acc) and acc ? 'canonical' and acc ? 'equivalents'
                and jsonb_typeof(acc -> 'known_errors') = 'object') from c
union all select 'jede richtige Variante: lsa_is_correct = true',
       (select bool_and(public.lsa_is_correct(c.input_type, c.ca, jsonb_build_object('value', v)))
          from c, jsonb_array_elements_text(c.ca) v)
union all select 'jede richtige Variante: lsa_grade = voll',
       (select bool_and(public.lsa_grade(c.input_type, c.acc, c.ca, jsonb_build_object('value', v)) = 'voll')
          from c, jsonb_array_elements_text(c.ca) v)
union all select 'jeder falsche Wert: nicht richtig, nicht voll, trifft seinen Slug',
       (select bool_and(not public.lsa_is_correct(input_type, ca, jsonb_build_object('value', wert))
                        and public.lsa_grade(input_type, acc, ca, jsonb_build_object('value', wert)) <> 'voll'
                        and public.lsa_fehlbild_match('numeric', acc -> 'known_errors', jsonb_build_object('value', wert)) = slug)
          from ke)
union all select 'nur erlaubte Slugs (vier neue + drei wiederverwendete)',
       (select bool_and(slug in (select slug from neu union all select slug from alt)) from ke)
union all select 'neue Slugs existieren',
       (select bool_and(exists (select 1 from public.fehlbild_labels l where l.slug = neu.slug)) from neu)
union all select 'wiederverwendete Slugs existieren (nur Prod)',
       :lokal or (select bool_and(exists (select 1 from public.fehlbild_labels l where l.slug = alt.slug)) from alt)
union all select 'jedes neue Fehlbild in mindestens drei Aufgaben',
       (select bool_and((select count(distinct id) from ke where ke.slug = neu.slug) >= 3) from neu)
union all select 'sondierrang: je Knoten genau Rang 1 und 2, Rest NULL',
       (select bool_and(r = array[1,2]) from (select skill_key, array_agg(sondierrang order by sondierrang) r
          from c where sondierrang is not null group by 1) x)
       and (select count(distinct skill_key) from c where sondierrang is not null) = 4
union all select 'sondierrang: Rang 1 und 2 aus verschiedenen Fehlbildprofilen',
       (select bool_and(p1 <> p2) from (
          select skill_key,
                 max(p) filter (where sondierrang = 1) p1, max(p) filter (where sondierrang = 2) p2
            from (select c.skill_key, c.sondierrang,
                         (select string_agg(distinct v, ',' order by v) from jsonb_each_text(c.acc -> 'known_errors') e(k, v)) p
                    from c where c.sondierrang is not null) y group by 1) z)
union all select 'Kennzeichen vorbefuellt gesetzt',
       bool_and(vorbefuellt ? 'afb' and vorbefuellt -> 'hints' ->> 'art' = 'leer' and vorbefuellt_am is not null) from c
union all select 'Figuren: genau zwei, Generator winkel, nur neben_scheitel, alt_text ohne Ziffer',
       (select count(*) = 2 and bool_and(f.generator = 'winkel' and f.alt_text !~ '[0-9]'
                                         and c.skill_key = 'geo_winkel_neben_scheitel' and c.needs_image)
          from public.task_figures f join c on c.id = f.task_id)
       and (select count(*) from c where needs_image) = 2
union all select 'keine Loesung im question_payload',
       not exists (select 1 from c where question_payload ?| array['correct', 'accepted', 'pairs', 'blanks', 'expected'])
union all select 'keine Mastery-Sprache',
       not exists (select 1 from c where (title || question || coalesce(weg, '') || te::text) ~* 'gemeistert|meisterst|mastered|beherrscht')
union all select 'keine Konstruktionsaufgabe',
       not exists (select 1 from c where question ~* 'konstruier');

-- Uebersicht
select source_ref, skill_key, afb, est_duration_sec sek, sondierrang rang, needs_image bild,
       acc ->> 'canonical' antwort,
       (select string_agg(distinct v, ', ') from jsonb_each_text(acc -> 'known_errors') e(k, v)) fehlbilder
  from (select t.*, s.acceptance acc from public.tasks t join public.task_solutions s on s.task_id = t.id
         where t.source = 'edvance_k8_winkel') x
 order by skill_key, source_ref;
