-- Pruefquery zu 20261003104947_aufgaben_k8_lgs.sql — rein lesend (laeuft auch mit dbread).
-- Erwartung: jede Zeile ok = t.
-- psql -v lokal=true (Wegwerf-DB): cluster_id (skill_clusters wird geseedet, nicht migriert) und
-- "alle Slugs existieren" (Alt-Slugs aus dem Datenimport) entfallen. Ohne Variable alles pruefen.
--
-- Formate: MULTI_PART x | y (Teil 1 = x, Teil 2 = y), Sachknoten MULTI_PART mc | x | y,
-- Loesungsanzahl als MC. Antworten: Zahlteile {"value": …}, MC und mc-Teile {"selected": [id]}.

\if :{?lokal}
\else
  \set lokal false
\endif

with
c as (select t.*, s.correct_answers ca, s.acceptance acc, s.solution weg, s.typical_errors te, s.hints
        from public.tasks t left join public.task_solutions s on s.task_id = t.id
       where t.source = 'edvance_k8_lgs'),
-- Bewertungseinheiten: MC als Ganzes, MULTI_PART je Teil (mit Art des Teils).
teil as (
  select c.id, c.skill_key, 'MC'::text itype, 'mc'::text kind, c.ca tca, c.acc tacc from c where c.input_type = 'MC'
  union all
  select c.id, c.skill_key, case when p ->> 'kind' = 'mc' then 'MC' else 'NUMERIC' end,
         case when p ->> 'kind' = 'mc' then 'mc' else 'short_input' end,
         c.ca -> (p ->> 'nr'), c.acc -> (p ->> 'nr')
    from c, jsonb_array_elements(c.parts) p where c.input_type = 'MULTI_PART'),
antwort as (select t.*, case when t.itype = 'MC' then jsonb_build_object('selected', jsonb_build_array(v))
                             else jsonb_build_object('value', v) end resp
              from teil t, jsonb_array_elements_text(t.tca) v),
ke as (select t.*, k.key wert, k.value slug,
              case when t.itype = 'MC' then jsonb_build_object('selected', jsonb_build_array(k.key))
                   else jsonb_build_object('value', k.key) end resp
         from teil t, jsonb_each_text(t.tacc -> 'known_errors') k),
neu(slug) as (values ('nicht_alle_glieder_multipliziert'), ('seiten_ungleich_verknuepft'),
                     ('loesungsanzahl_verwechselt'), ('parallele_uebersehen'))
select 'dreissig Aufgaben, alle draft, aktiv, MULTI_PART oder MC' pruefung,
       count(*) = 30 and bool_and(status = 'draft' and is_active and input_type in ('MULTI_PART', 'MC')) ok from c
union all select 'je sechs zu einsetzen, gleichsetzen, addition, grafisch, sachaufgabe',
       (select array_agg(skill_key || ':' || n order by skill_key) from (select skill_key, count(*) n from c group by 1) x)
       = array['gleichung_lgs_addition:6', 'gleichung_lgs_einsetzen:6', 'gleichung_lgs_gleichsetzen:6',
               'gleichung_lgs_grafisch:6', 'gleichung_lgs_sachaufgabe:6']
union all select 'Formate: 4 MC (Loesungsanzahl), 4 mit mc-Teil, 22 nur x | y',
       count(*) filter (where input_type = 'MC') = 4
       and count(*) filter (where input_type = 'MULTI_PART' and jsonb_array_length(parts) = 3
                              and parts -> 0 ->> 'kind' = 'mc' and parts -> 1 ->> 'kind' = 'short_input'
                              and parts -> 2 ->> 'kind' = 'short_input') = 4
       and count(*) filter (where input_type = 'MULTI_PART' and jsonb_array_length(parts) = 2
                              and parts -> 0 ->> 'kind' = 'short_input' and parts -> 1 ->> 'kind' = 'short_input') = 22
  from c
union all select 'Pflichtfelder am Item gesetzt (Stoffanker 8, arithmetik_algebra)',
       bool_and(afb in ('I','II','III') and est_duration_sec between 10 and 3600 and curriculum_grade = 8
                and class_level = 8 and competency_content = 'arithmetik_algebra' and competency_process is not null
                and needs_image is not null and source_ref like 'lgs-%' and unit is null) from c
union all select 'Teile: afb und competency_content gesetzt; MC mit drei Optionen im Payload',
       bool_and(case when input_type = 'MC'
                     then parts = '[]'::jsonb and jsonb_array_length(question_payload -> 'options') = 3
                     else not exists (select 1 from jsonb_array_elements(parts) p
                                       where p ->> 'afb' is null or p ->> 'competency_content' <> 'arithmetik_algebra'
                                          or (p ->> 'kind' = 'mc' and jsonb_array_length(p -> 'options') < 2)) end) from c
union all select 'cluster_id = Algebra & Funktionen (Prod)',
       :lokal or bool_and(cluster_id = 'edbb548a-54d9-4a8f-8be4-3052f9025524') from c
union all select 'Loesung, Loesungsweg, typical_errors, keine Hinweise',
       bool_and(public.lsa_has_answers(input_type, parts, ca) and public.lsa_answers_valid(ca)
                and nullif(btrim(weg), '') is not null and jsonb_array_length(te) > 0 and hints = '[]'::jsonb) from c
union all select 'acceptance gueltig: je Bewertungseinheit canonical + known_errors in Objektform',
       (select bool_and(public.lsa_acceptance_valid(c.acc)) from c)
       and (select bool_and(t.tacc ? 'canonical' and jsonb_typeof(t.tacc -> 'known_errors') = 'object'
                            and t.tacc -> 'known_errors' <> '{}'::jsonb) from teil t)
union all select 'jede richtige Variante: lsa_is_correct = true',
       (select bool_and(public.lsa_is_correct(a.itype, a.tca, a.resp)) from antwort a)
union all select 'jede richtige Variante (Zahlteile): lsa_grade = voll',
       (select bool_and(public.lsa_grade(a.itype, a.tacc, a.tca, a.resp) = 'voll') from antwort a where a.itype <> 'MC')
union all select 'jeder falsche Wert: nicht richtig, nicht voll, trifft seinen Slug',
       (select bool_and(not public.lsa_is_correct(k.itype, k.tca, k.resp)
                        and public.lsa_grade(k.itype, k.tacc, k.tca, k.resp) <> 'voll'
                        and public.lsa_fehlbild_match(k.kind, k.tacc -> 'known_errors', k.resp) = k.slug)
          from ke k)
union all select 'Unicode-Minus und Einheit als richtige Variante (Stichprobe)',
       (select count(*) from antwort a where a.resp ->> 'value' like '−%') > 0
       and (select count(*) from antwort a where a.resp ->> 'value' like '% €') > 0
union all select 'alle Slugs existieren (Prod)',
       :lokal or (select bool_and(exists (select 1 from public.fehlbild_labels l where l.slug = ke.slug)) from ke)
union all select 'die vier neuen Slugs existieren',
       (select count(*) = 4 from public.fehlbild_labels l join neu using (slug))
union all select 'jedes neue Fehlbild in mindestens drei Aufgaben',
       (select bool_and((select count(distinct id) from ke where ke.slug = neu.slug) >= 3) from neu)
union all select 'sondierrang: je Knoten genau Rang 1 und 2, Rest NULL',
       (select bool_and(r = array[1,2]) from (select skill_key, array_agg(sondierrang order by sondierrang) r
          from c where sondierrang is not null group by 1) x)
       and (select count(distinct skill_key) from c where sondierrang is not null) = 5
union all select 'sondierrang: Rang 1 und 2 aus verschiedenen Fehlbildprofilen (ueber alle Teile)',
       (select bool_and(p1 <> p2) from (
          select skill_key, max(p) filter (where sondierrang = 1) p1, max(p) filter (where sondierrang = 2) p2
            from (select c.skill_key, c.sondierrang,
                         (select string_agg(distinct k.slug, ',' order by k.slug) from ke k where k.id = c.id) p
                    from c where c.sondierrang is not null) y group by 1) z)
union all select 'Kennzeichen vorbefuellt gesetzt',
       bool_and(vorbefuellt ? 'afb' and vorbefuellt -> 'hints' ->> 'art' = 'leer' and vorbefuellt_am is not null) from c
union all select 'keine Loesung im Payload',
       not exists (select 1 from c where question_payload ?| array['correct', 'accepted', 'pairs', 'blanks', 'expected'])
union all select 'Figuren: fuenf, nur grafisch, koordinatensystem mit zwei Geraden, alt_text ohne Ziffer',
       (select count(*) = 5 and bool_and(f.generator = 'koordinatensystem' and f.alt_text !~ '[0-9]'
                                         and jsonb_array_length(f.params -> 'funktionen') = 2
                                         and t.skill_key = 'gleichung_lgs_grafisch')
          from public.task_figures f join c t on t.id = f.task_id)
union all select 'needs_image genau bei Aufgaben mit Figur',
       bool_and(needs_image = exists (select 1 from public.task_figures f where f.task_id = c.id)) from c
union all select 'keine Mastery-Sprache',
       not exists (select 1 from c where (title || question || coalesce(weg, '') || te::text || parts::text)
                                         ~* 'gemeistert|meisterst|mastered|beherrscht');

-- Uebersicht
select t.source_ref, t.skill_key, t.input_type, t.afb, t.est_duration_sec sek, t.sondierrang rang,
       coalesce(s.correct_answers ->> 0,
                (select string_agg(p ->> 'nr' || '=' || (s.correct_answers -> (p ->> 'nr') ->> 0), ' ')
                   from jsonb_array_elements(t.parts) p)) antwort
  from public.tasks t join public.task_solutions s on s.task_id = t.id
 where t.source = 'edvance_k8_lgs'
 order by t.skill_key, t.source_ref;
