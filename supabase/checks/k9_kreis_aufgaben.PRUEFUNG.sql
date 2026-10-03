-- Pruefquery zu 20261003092051_aufgaben_k9_kreis.sql — rein lesend.
-- Erwartung: jede Zeile ok = t. :cluster_pflicht = true in Prod (skill_clusters ist geseedet,
-- im CI-Neuaufbau bleibt cluster_id null).

\if :{?cluster_pflicht}
\else
  \set cluster_pflicht true
\endif

with
c as (select t.*, s.correct_answers ca, s.acceptance acc, s.solution weg, s.typical_errors te, s.hints
        from tasks t left join task_solutions s on s.task_id = t.id
       where t.source = 'edvance_k9_kreis'),
ke as (select c.id, c.skill_key, k.key wert, k.value slug, c.input_type, c.acc, c.ca
         from c, jsonb_each_text(c.acc -> 'known_errors') k),
neu(slug) as (values ('radius_durchmesser_verwechselt'), ('pi_vergessen'), ('kreisanteil_falsch'))
select 'vierundzwanzig Aufgaben, alle draft, NUMERIC, aktiv' pruefung,
       count(*) = 24 and bool_and(status = 'draft' and input_type = 'NUMERIC' and is_active) ok from c
union all select 'je sechs zu umfang, flaeche, rueck, sektor; keine zu zusammen',
       (select array_agg(n order by k) from (select skill_key k, count(*) n from c group by 1) x) = array[6,6,6,6]::bigint[]
       and not exists (select 1 from c where skill_key = 'geo_kreis_zusammen')
union all select 'Pflichtfelder am Item gesetzt',
       bool_and(afb in ('I','II','III') and est_duration_sec between 10 and 3600 and curriculum_grade = 9
                and class_level = 9
                and competency_content = 'geometrie' and competency_process is not null
                and needs_image = false and parts = '[]'::jsonb and source_ref is not null and unit is not null) from c
union all select 'cluster_id = Geometrie & Messen (Prod)',
       not :cluster_pflicht or bool_and(cluster_id = '3156b22e-ad3b-46c8-8c76-4155176cc52a') from c
union all select 'Loesung, Loesungsweg, typical_errors, keine Hinweise',
       bool_and(jsonb_typeof(ca) = 'array' and jsonb_array_length(ca) > 0 and nullif(btrim(weg), '') is not null
                and jsonb_array_length(te) > 0 and hints = '[]'::jsonb) from c
union all select 'acceptance gueltig: canonical, equivalents, known_errors in Objektform',
       bool_and(public.lsa_acceptance_valid(acc) and acc ? 'canonical'
                and jsonb_typeof(acc -> 'known_errors') = 'object') from c
union all select 'jede Variante: lsa_is_correct = true (Flag correct, Fehlbild-Erfassung)',
       (select bool_and(public.lsa_is_correct(c.input_type, c.ca, jsonb_build_object('value', v)))
          from c, jsonb_array_elements_text(c.ca) v)
union all select 'jede Variante: lsa_grade = voll (Skill-Urteil, auch der 3,14-Weg)',
       (select bool_and(public.lsa_grade(c.input_type, c.acc, c.ca, jsonb_build_object('value', v)) = 'voll')
          from c, jsonb_array_elements_text(c.ca) v)
union all select 'jeder falsche Wert: nicht richtig, nicht voll, trifft seinen Slug',
       (select bool_and(not public.lsa_is_correct(input_type, ca, jsonb_build_object('value', wert))
                        and public.lsa_grade(input_type, acc, ca, jsonb_build_object('value', wert)) <> 'voll'
                        and public.lsa_fehlbild_match('numeric', acc -> 'known_errors', jsonb_build_object('value', wert)) = slug)
          from ke)
union all select 'alle Slugs existieren',
       (select bool_and(exists (select 1 from fehlbild_labels l where l.slug = ke.slug)) from ke)
union all select 'flaecheneinheit_nicht_quadriert nirgends verwendet',
       not exists (select 1 from ke where slug = 'flaecheneinheit_nicht_quadriert')
union all select 'jedes neue Fehlbild in mindestens drei Aufgaben',
       (select bool_and((select count(distinct id) from ke where ke.slug = neu.slug) >= 3) from neu)
union all select 'sondierrang: je Knoten genau Rang 1 und 2',
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
union all select 'jede Aufgabe nennt π-Taste oder 3,14 und die Rundung',
       bool_and(question like '%π-Taste oder mit π ≈ 3,14%' and question ~ 'Runde|runde') from c
union all select 'keine Mastery-Sprache',
       not exists (select 1 from c where (question || coalesce(weg, '') || te::text) ~* 'gemeistert|meisterst|mastered|beherrscht');

-- Uebersicht
select source_ref, skill_key, afb, est_duration_sec sek, sondierrang rang,
       acc ->> 'canonical' antwort, acc -> 'equivalents' ->> 0 variante,
       (select string_agg(distinct v, ', ') from jsonb_each_text(acc -> 'known_errors') e(k, v)) fehlbilder
  from (select t.*, s.acceptance acc from tasks t join task_solutions s on s.task_id = t.id
         where t.source = 'edvance_k9_kreis') x
 order by skill_key, source_ref;
