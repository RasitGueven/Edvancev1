-- Pruefquery zu 20261003105906_aufgaben_k9_koerper.sql — rein lesend.
-- Erzeugt von tools/k9-rest-pruefung.mjs aus docs/prefill/k9-koerper.json. Erwartung: jede Zeile ok = t.
-- -v lokal=true in der Wegwerf-DB (keine skill_clusters, keine Alt-Slugs aus dem Datenimport).
\if :{?lokal}
\else
  \set lokal false
\endif

with
c as (select t.*, s.correct_answers ca, s.acceptance acc, s.solution weg, s.typical_errors te, s.hints
        from public.tasks t left join public.task_solutions s on s.task_id = t.id
       where t.source = 'edvance_k9_koerper'),
-- eine Zeile je Pruefeinheit: flache Aufgabe (nr null) oder Teilaufgabe
e as (select c.id, c.skill_key, c.input_type, null::text nr, c.ca eca, c.acc eacc from c where c.input_type <> 'MULTI_PART'
      union all
      select c.id, c.skill_key, c.input_type, p ->> 'nr', c.ca -> (p ->> 'nr'), c.acc -> (p ->> 'nr')
        from c, jsonb_array_elements(c.parts) p where c.input_type = 'MULTI_PART'),
v as (select e.*, x antwort from e, jsonb_array_elements_text(e.eca) x),
ke as (select e.*, k.key wert, k.value slug from e, jsonb_each_text(e.eacc -> 'known_errors') k),
neu(slug) as (values ('drittel_vergessen')),
neu_mit(slug) as (values ('wurzel_vergessen'), ('hypotenuse_verwechselt'), ('drittel_vergessen'))
select '30 Aufgaben, alle draft, aktiv, NUMERIC oder MULTI_PART' pruefung,
       count(*) = 30 and bool_and(status = 'draft' and is_active and input_type in ('NUMERIC','MULTI_PART')) ok from c
union all select 'je sechs Aufgaben zu geo_koerper_prisma, geo_koerper_zylinder, geo_koerper_pyramide, geo_koerper_kegel, geo_koerper_kugel',
       (select count(*) = 5 and bool_and(n = 6) from (select skill_key, count(*) n from c group by 1) x)
       and not exists (select 1 from c where skill_key not in ('geo_koerper_prisma', 'geo_koerper_zylinder', 'geo_koerper_pyramide', 'geo_koerper_kegel', 'geo_koerper_kugel'))
union all select 'Pflichtfelder am Item (afb, Zeit, Stoffanker 9, class_level 9, Inhaltsfeld geometrie)',
       bool_and(afb in ('I','II','III') and est_duration_sec between 10 and 3600 and curriculum_grade = 9 and class_level = 9
                and competency_content = 'geometrie' and competency_process is not null and needs_image is not null
                and source_ref is not null and vorbefuellt_am is not null) from c
union all select 'needs_image genau bei den 0 Aufgaben mit task_figures-Zeile',
       (select count(*) from c where needs_image) = 0
       and (select count(*) from public.task_figures f join c on c.id = f.task_id where c.needs_image) = 0
       and not exists (select 1 from public.task_figures f join c on c.id = f.task_id where not c.needs_image)
union all select 'cluster_id wie geplant (nur Prod)',
       :lokal or bool_and(cluster_id = '3156b22e-ad3b-46c8-8c76-4155176cc52a') from c
union all select 'Loesung, Loesungsweg, typical_errors, keine Hinweise',
       bool_and(public.lsa_answers_valid(ca) and public.lsa_has_answers(input_type, parts, ca)
                and nullif(btrim(weg), '') is not null and jsonb_array_length(te) > 0 and hints = '[]'::jsonb) from c
union all select 'acceptance gueltig, je Pruefeinheit canonical + known_errors in Objektform',
       (select bool_and(public.lsa_acceptance_valid(acc)) from c)
       and (select bool_and(eacc ? 'canonical' and jsonb_typeof(eacc -> 'known_errors') = 'object') from e)
union all select 'jede Variante richtig (lsa_is_correct, Flag correct und Fehlbild-Erfassung)',
       (select bool_and(case when nr is null
                  then public.lsa_is_correct(input_type, eca, jsonb_build_object('value', antwort))
                  else public.lsa_is_correct('SHORT_TEXT', eca, public.lsa_part_answer('short_input', to_jsonb(antwort))) end) from v)
union all select 'jede Variante flacher Aufgaben: Skill-Urteil voll (lsa_grade)',
       coalesce((select bool_and(public.lsa_grade(input_type, eacc, eca, jsonb_build_object('value', antwort)) = 'voll')
          from v where nr is null), true)
union all select 'jeder falsche Wert: nicht richtig und trifft seinen Slug',
       (select bool_and(case when nr is null
                  then not public.lsa_is_correct(input_type, eca, jsonb_build_object('value', wert))
                       and public.lsa_grade(input_type, eacc, eca, jsonb_build_object('value', wert)) <> 'voll'
                       and public.lsa_fehlbild_match('numeric', eacc -> 'known_errors', jsonb_build_object('value', wert)) = slug
                  else not public.lsa_is_correct('SHORT_TEXT', eca, public.lsa_part_answer('short_input', to_jsonb(wert)))
                       and public.lsa_fehlbild_match('short_input', eacc -> 'known_errors',
                             public.lsa_part_answer('short_input', to_jsonb(wert))) = slug end) from ke)
union all select 'alle Slugs existieren (lokal nur die neuen)',
       (select bool_and(exists (select 1 from public.fehlbild_labels l where l.slug = ke.slug)) from ke
         where not :lokal or ke.slug in (select slug from neu_mit))
union all select 'jedes neue Fehlbild in mindestens drei Aufgaben',
       (select coalesce(bool_and((select count(distinct id) from ke where ke.slug = neu.slug) >= 3), true) from neu where slug <> '')
union all select 'sondierrang: je Knoten genau Rang 1 und 2',
       (select bool_and(r = array[1,2]) from (select skill_key, array_agg(sondierrang order by sondierrang) r
          from c where sondierrang is not null group by 1) x)
       and (select count(distinct skill_key) from c where sondierrang is not null) = 5
union all select 'sondierrang: Rang 1 und 2 aus verschiedenen Fehlbildprofilen',
       (select bool_and(p1 <> p2) from (
          select skill_key, max(p) filter (where sondierrang = 1) p1, max(p) filter (where sondierrang = 2) p2
            from (select c.skill_key, c.sondierrang,
                         (select string_agg(distinct k.slug, ',' order by k.slug) from ke k where k.id = c.id) p
                    from c where c.sondierrang is not null) y group by 1) z)
union all select 'Kennzeichen vorbefuellt, hints bewusst leer',
       bool_and(vorbefuellt ? 'afb' and vorbefuellt -> 'hints' ->> 'art' = 'leer') from c
union all select 'keine Mastery-Sprache',
       not exists (select 1 from c where (question || coalesce(weg, '') || te::text) ~* 'gemeistert|meisterst|mastered|beherrscht');

-- Uebersicht
select source_ref, skill_key, input_type typ, afb, est_duration_sec sek, sondierrang rang, needs_image bild,
       coalesce(acc ->> 'canonical', acc -> '1' ->> 'canonical') antwort
  from (select t.*, s.acceptance acc from public.tasks t join public.task_solutions s on s.task_id = t.id
         where t.source = 'edvance_k9_koerper') x
 order by skill_key, source_ref;
