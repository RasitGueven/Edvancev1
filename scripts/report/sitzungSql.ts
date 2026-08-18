// Die Leseabfrage des Report-Generators (R4).
//
// Eigene Datei, damit build-eltern-report.ts unter der 400-Zeilen-Grenze
// bleibt (CLAUDE §4) und das SQL am Stück lesbar ist.
//
// AUSSCHLIESSLICH lesend. Der Aufrufer klammert die Abfrage in eine
// Transaktion, in der zuvor die R4-Migration nachgestellt wurde, und rollt
// danach zurück — Begründung im Kopf von build-eltern-report.ts.
//
// `$IDS$` wird vom Aufrufer durch die quotierten Sitzungs-IDs ersetzt.

export const SITZUNG_SQL = `
with sess as (
  select s.id, s.student_id, s.subject, s.grade, s.started_at,
         st.lead_id, l.first_name, l.next_exam_topic
    from lsa_sessions s
    join students st on st.id = s.student_id
    left join leads l on l.id = st.lead_id
   where s.id in ($IDS$)
),
urteil as (
  -- NUR direkt geprüfte Skills. Mitbelegte Urteile sind aus dem
  -- Voraussetzungsgraphen gefolgert — eine Schlussfolgerung, keine
  -- Beobachtung — und gehören nicht in ein Elterngespräch.
  select u.session_id, u.skill_key, sk.label, sk.fundament_tiefe as tiefe,
         u.zustand, u.proben_anzahl
    from lsa_skill_urteil u
    join skills sk on sk.skill_key = u.skill_key
   where u.belegt_direkt
     and u.session_id in ($IDS$)
     and sk.label is not null
     and sk.fundament_tiefe is not null
)
select coalesce(jsonb_agg(x order by x->>'session_id'), '[]'::jsonb) from (
  select jsonb_build_object(
    'session_id',      se.id,
    'vorname',         se.first_name,
    'klasse',          se.grade,
    'fach',            se.subject,
    'gestartet',       se.started_at,

    -- AUFGABEN, nicht Antwortzeilen: zwei Teilaufgaben desselben Items sind
    -- eine Aufgabe. Dieselbe Zählweise nutzt lsa_fehlbild_auswertung.
    'aufgaben',        (select count(distinct r.task_id)
                          from lsa_responses r where r.session_id = se.id),

    -- leads trägt keine Spalte 'leitthema'. next_exam_topic ist das, was
    -- belegt ist — der Report formuliert entsprechend vorsichtiger.
    'next_exam_topic', se.next_exam_topic,

    'weak_topics',     (select la.weak_topics from lead_assessments la
                         where la.lead_id = se.lead_id and la.source = 'parent'),

    'urteile',         coalesce((select jsonb_agg(jsonb_build_object(
                            'skill_key', u.skill_key, 'label', u.label,
                            'tiefe', u.tiefe, 'zustand', u.zustand,
                            'proben', u.proben_anzahl)
                          order by u.tiefe desc, u.skill_key)
                          from urteil u where u.session_id = se.id), '[]'::jsonb),

    -- Ungefiltert: die Schwelle greift erst NACH der Bündelung je Familie
    -- (src/lib/reportFehlbilder.ts). Vorher zu filtern verliert genau den
    -- Fall, für den die Bündelung gebaut wurde.
    'fehlbilder',      coalesce((select jsonb_agg(jsonb_build_object(
                            'slug', f.fehlbild_slug, 'familie', f.familie,
                            'elterntext', f.familie_elterntext,
                            'anzahl', f.anzahl, 'aufgaben', f.aufgaben,
                            'skills', f.skills))
                          from public.lsa_fehlbild_auswertung(se.id) f), '[]'::jsonb),

    -- Nur ABGENOMMENE Bausteine. Dieselbe Schranke wie im App-Lesepfad
    -- (src/lib/supabase/reportBausteine.ts).
    'bausteine',       coalesce((select jsonb_agg(jsonb_build_object(
                            'schluessel', b.schluessel, 'slot', b.slot,
                            'fall', b.fall, 'variante', b.variante, 'text', b.text))
                          from public.report_bausteine b
                         where b.freigegeben_am is not null), '[]'::jsonb),

    'zuordnungen',     coalesce((select jsonb_agg(jsonb_build_object(
                            'thema', z.thema, 'skill_keys', z.skill_keys,
                            'fehlbild_familien', z.fehlbild_familien,
                            'strukturell', z.strukturell))
                          from public.report_anlass_zuordnung z), '[]'::jsonb),

    -- Wer die Analyse begleitet hat: die erste Platzvergabe der Sitzung.
    -- lsa_sessions trägt kein created_by, leads.owner_id ist bei den
    -- Pilot-Leads null, student_coach für provisorische Schüler leer.
    'ansprechpartner', (select jsonb_build_object('name', p.full_name, 'email', p.email)
                          from platz_assignments pa
                          join profiles p on p.id = pa.created_by
                         where pa.session_id = se.id
                         order by pa.created_at asc limit 1),

    'tiers',           coalesce((select jsonb_agg(jsonb_build_object(
                            'name', t.name, 'features', t.features)
                          order by t.sort_order)
                          from tiers t where t.active), '[]'::jsonb)
  ) as x
  from sess se
) q;
`
