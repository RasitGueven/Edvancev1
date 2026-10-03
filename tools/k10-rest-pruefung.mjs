#!/usr/bin/env node
/**
 * k10-rest-pruefung.mjs — erzeugt die Pruefskripte eines Themas aus dem zentralen Plan
 * (docs/k10-rest/graph.json) und der Charge (docs/prefill/k10-<kurz>.json):
 *
 *   node tools/k10-rest-pruefung.mjs <kurz>     # z. B. wurzel
 *
 *   supabase/checks/k10_<kurz>_substrat.PRUEFUNG.sql   Knoten, Tiefen, Kanten, neue Fehlbilder
 *   supabase/checks/k10_<kurz>_aufgaben.PRUEFUNG.sql   Aufgaben, Loesungen, Bewertungspfad
 *
 * Beide Skripte sind rein lesend (nur select, nur IMMUTABLE-Funktionen) und laufen per
 * dbread gegen Prod. Erwartung: jede Zeile ok = t.
 * Lokal (Wegwerf-DB aus den Migrationen) fehlen die Alt-Slugs aus dem Datenimport und die
 * geseedeten skill_clusters; diese zwei Pruefungen schaltet `-v lokal=true` ab.
 * Die Substrat-Pruefung entsteht aus graph.json, NICHT aus der Migration: sie prueft die von
 * Hand geschriebene Datei unabhaengig gegen den Plan.
 */
import fs from 'node:fs';

const kurz = process.argv[2];
const plan = JSON.parse(fs.readFileSync('docs/k10-rest/graph.json', 'utf8'));
const thema = plan.themen.find((t) => t.kurz === kurz);
if (!thema) { console.error(`Thema ${kurz} nicht in graph.json`); process.exit(2); }
const q = (s) => `'${String(s).replace(/'/g, "''")}'`;
const liste = (xs) => xs.map(q).join(', ');
const LOKAL = `\\if :{?lokal}
\\else
  \\set lokal false
\\endif
`;

// ── Substrat ──
const knoten = thema.knoten;
const kanten = knoten.flatMap((k) => k.kanten.map(([v]) => [k.key, v]));
const slugsThema = plan.fehlbilder_neu.filter((f) => f.themen.includes(kurz));
const sub = `-- Pruefquery zu ${fs.readdirSync('supabase/migrations').find((f) => f.endsWith(`_substrat_k10_${kurz}.sql`))} (nur lesend).
-- Erzeugt von tools/k10-rest-pruefung.mjs aus docs/k10-rest/graph.json — unabhaengig von der Migration.
-- Erwartung: jede Zeile ok = t.
${LOKAL}
with soll(skill_key, label, tiefe) as (values
${knoten.map((k) => `  (${q(k.key)}, ${q(k.label)}, ${k.tiefe})`).join(',\n')}
),
soll_kante(skill_key, voraussetzt) as (values
${kanten.map(([s, v]) => `  (${q(s)}, ${q(v)})`).join(',\n')}
)
select 'knoten: ${knoten.length}, Klasse 10, Tiefe und Label wie geplant' as pruefung,
       (select count(*) from soll join public.skills s using (skill_key)
         where s.klasse_herkunft = 10 and s.fundament_tiefe = soll.tiefe and s.label = soll.label
           and s.fach = 'mathematik') = ${knoten.length} as ok,
       (select string_agg(s.skill_key || ':' || s.klasse_herkunft || '/' || s.fundament_tiefe, ' ' order by s.skill_key)
          from public.skills s join soll using (skill_key)) as ist
union all
select 'kanten: genau die ${kanten.length} geplanten',
       (select count(*) from soll_kante k join public.skill_kante x
           on x.skill_key = k.skill_key and x.voraussetzt_skill_key = k.voraussetzt) = ${kanten.length}
       and (select count(*) from public.skill_kante x where x.skill_key in (select skill_key from soll)) = ${kanten.length},
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
select 'neue Fehlbilder: ${slugsThema.length}, Klartext + Erklaerung, nicht freigegeben',
       count(*) = ${slugsThema.length} and coalesce(bool_and(freigegeben_am is null and klartext <> '' and erklaerung <> ''), ${slugsThema.length === 0}),
       coalesce(string_agg(slug, ' ' order by slug), '')
  from public.fehlbild_labels
 where slug in (${slugsThema.length ? liste(slugsThema.map((f) => f.slug)) : "''"})
union all
select 'neue Fehlbilder: Familie wie geplant',
       ${slugsThema.length ? `count(*) = ${slugsThema.length}` : 'true'}, ''
  from public.fehlbild_labels l
  join (values ${slugsThema.length ? slugsThema.map((f) => `(${q(f.slug)}, ${f.familie ? q(f.familie) : 'null::text'})`).join(', ') : "('', null::text)"}) f(slug, familie)
    on f.slug = l.slug and l.familie is not distinct from f.familie
;
`;
fs.writeFileSync(`supabase/checks/k10_${kurz}_substrat.PRUEFUNG.sql`, sub);

// ── Aufgaben ──
const chargePfad = `docs/prefill/k10-${kurz}.json`;
if (!fs.existsSync(chargePfad)) { console.log(`substrat-Pruefung geschrieben; ${chargePfad} fehlt noch`); process.exit(0); }
const charge = JSON.parse(fs.readFileSync(chargePfad, 'utf8'));
const n = charge.aufgaben.length;
const skills = knoten.map((k) => k.key);
const mitFigur = charge.aufgaben.filter((a) => a.basis.figur).length;
const verwendet = new Set(charge.aufgaben.flatMap((a) => (a.basis.input_type === 'MULTI_PART'
  ? Object.values(a.basis.known_errors).flatMap((ke) => Object.values(ke)) : Object.values(a.basis.known_errors))));
// "jedes neue Fehlbild in mindestens drei Aufgaben" gilt im Thema, das den Slug als erstes einfuehrt
// (themen[0]); andere Themen duerfen ihn mitbenutzen, ohne die Schwelle erneut zu erfuellen.
const neuHier = plan.fehlbilder_neu.filter((f) => f.themen[0] === kurz).map((f) => f.slug);
const neuMit = plan.fehlbilder_neu.map((f) => f.slug).filter((s) => verwendet.has(s));
const auf = `-- Pruefquery zu ${fs.readdirSync('supabase/migrations').find((f) => f.endsWith(`_aufgaben_k10_${kurz}.sql`))} — rein lesend.
-- Erzeugt von tools/k10-rest-pruefung.mjs aus ${chargePfad}. Erwartung: jede Zeile ok = t.
-- -v lokal=true in der Wegwerf-DB (keine skill_clusters, keine Alt-Slugs aus dem Datenimport).
${LOKAL}
with
c as (select t.*, s.correct_answers ca, s.acceptance acc, s.solution weg, s.typical_errors te, s.hints
        from public.tasks t left join public.task_solutions s on s.task_id = t.id
       where t.source = ${q(charge.source)}),
-- eine Zeile je Pruefeinheit: flache Aufgabe (nr null) oder Teilaufgabe
e as (select c.id, c.skill_key, c.input_type, null::text nr, c.ca eca, c.acc eacc from c where c.input_type <> 'MULTI_PART'
      union all
      select c.id, c.skill_key, c.input_type, p ->> 'nr', c.ca -> (p ->> 'nr'), c.acc -> (p ->> 'nr')
        from c, jsonb_array_elements(c.parts) p where c.input_type = 'MULTI_PART'),
v as (select e.*, x antwort from e, jsonb_array_elements_text(e.eca) x),
ke as (select e.*, k.key wert, k.value slug from e, jsonb_each_text(e.eacc -> 'known_errors') k),
neu(slug) as (values ${neuHier.length ? neuHier.map((s) => `(${q(s)})`).join(', ') : "('')"}),
neu_mit(slug) as (values ${neuMit.length ? neuMit.map((s) => `(${q(s)})`).join(', ') : "('')"})
select '${n} Aufgaben, alle draft, aktiv, NUMERIC oder MULTI_PART' pruefung,
       count(*) = ${n} and bool_and(status = 'draft' and is_active and input_type in ('NUMERIC','MULTI_PART')) ok from c
union all select 'je sechs Aufgaben zu ${skills.join(', ')}',
       (select count(*) = ${skills.length} and bool_and(n = 6) from (select skill_key, count(*) n from c group by 1) x)
       and not exists (select 1 from c where skill_key not in (${liste(skills)}))
union all select 'Pflichtfelder am Item (afb, Zeit, Stoffanker 10, class_level 10, Inhaltsfeld ${thema.inhalt})',
       bool_and(afb in ('I','II','III') and est_duration_sec between 10 and 3600 and curriculum_grade = 10 and class_level = 10
                and competency_content = ${q(thema.inhalt)} and competency_process is not null and needs_image is not null
                and source_ref is not null and vorbefuellt_am is not null) from c
union all select 'needs_image genau bei den ${mitFigur} Aufgaben mit task_figures-Zeile',
       (select count(*) from c where needs_image) = ${mitFigur}
       and (select count(*) from public.task_figures f join c on c.id = f.task_id where c.needs_image) = ${mitFigur}
       and not exists (select 1 from public.task_figures f join c on c.id = f.task_id where not c.needs_image)
union all select 'cluster_id wie geplant (nur Prod)',
       :lokal or bool_and(cluster_id = ${q({ zahl: 'e7108c9a-d19e-4021-8499-55b4f3d5d70c', algebra: 'edbb548a-54d9-4a8f-8be4-3052f9025524', geo: '3156b22e-ad3b-46c8-8c76-4155176cc52a', daten: '9fdfed01-ebda-4c79-89ea-5accacefee93' }[thema.cluster])}) from c
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
       and (select count(distinct skill_key) from c where sondierrang is not null) = ${skills.length}
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
         where t.source = ${q(charge.source)}) x
 order by skill_key, source_ref;
`;
fs.writeFileSync(`supabase/checks/k10_${kurz}_aufgaben.PRUEFUNG.sql`, auf);
console.log(`supabase/checks/k10_${kurz}_{substrat,aufgaben}.PRUEFUNG.sql geschrieben`);
