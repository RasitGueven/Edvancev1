-- batu-inhalte-tabelle.sql — Tabelle je Knoten wie in docs/themen/pruefung-batu-inhalte.md (Spalten 1–8),
-- für die Knoten in :'knoten' (text[]-Literal). Nur Pilot-Aufgaben. Dieselben Funktionen wie Lenas Board:
-- pruef_fehler_gruppen, pruef_auffaelligkeiten, pruef_ausschluss. Nur lesend.
\pset footer off
with pilot as (
  select t.*, t trow, s.solution, s.correct_answers ca, s.acceptance acc, s.hints sh, public.pruef_ausschluss(t.id) ausschluss
    from public.tasks t left join public.task_solutions s on s.task_id = t.id
   where t.pruef_pilot and t.skill_key = any (:'knoten'::text[])),
je as (
  select p.skill_key, p.id, p.input_type = 'MC' mc, p.ausschluss,
         nullif(btrim(coalesce(p.solution, '')), '') is not null loesung,
         exists (select 1 from public.pruef_fehler_gruppen(p.acc)) fehlbild,
         (select array_agg(distinct fg.slug) from public.pruef_fehler_gruppen(p.acc) fg
           where not exists (select 1 from public.fehlbild_labels l
                              where l.slug = fg.slug and nullif(btrim(l.klartext), '') is not null)) slugs_ohne,
         case when p.ca is null then false
              when jsonb_typeof(p.ca) = 'array' then jsonb_array_length(p.ca) > 0
              when jsonb_typeof(p.ca) = 'object' then p.input_type = 'MULTI_PART'
                   and not exists (select 1 from jsonb_array_elements(p.parts) pt
                                    where jsonb_typeof(p.ca -> (pt ->> 'nr')) is distinct from 'array'
                                       or jsonb_array_length(p.ca -> (pt ->> 'nr')) = 0)
              else false end
         and public.lsa_answers_valid(p.ca) and (p.acc is null or public.lsa_acceptance_valid(p.acc)) antworten,
         (select coalesce(array_agg(b ->> 'code' order by b ->> 'code'), '{}')
            from jsonb_array_elements(public.pruef_auffaelligkeiten(p.trow, coalesce(p.ca, '[]'), p.acc, p.solution)) b) befunde,
         (select count(distinct h ->> 'level') from jsonb_array_elements(case when jsonb_typeof(p.sh) = 'array' then p.sh else '[]' end) h
           where nullif(btrim(coalesce(h ->> 'text', '')), '') is not null) hinweise
    from pilot p),
t as (select je.*, (loesung and fehlbild and antworten and cardinality(befunde) = 0 and ausschluss is null) tauglich from je),
codes as (select skill_key, c, count(*) n, count(distinct id) a from t, unnest(befunde) c group by 1, 2)
select t.skill_key knoten,
       count(*) || ' / ' || count(*) filter (where not mc) "1 gesamt / ohne MC",
       count(*) filter (where loesung) "2 Musterl.",
       count(*) filter (where fehlbild) "3 Fehlbild",
       coalesce((select string_agg(distinct s, ', ') from t t2, unnest(t2.slugs_ohne) s where t2.skill_key = t.skill_key), '–') "4 ohne Klartext",
       count(*) filter (where antworten) "5 gültig",
       coalesce((select string_agg(c || ' ' || n || ' in ' || a || ' Aufg.', '; ') from codes where codes.skill_key = t.skill_key), '–') "6 Befunde",
       count(*) filter (where hinweise < 3) "7 <3 Hinw.",
       count(*) filter (where tauglich) || ' (' || count(*) filter (where tauglich and not mc) || ')' "8 tauglich (ohne MC)"
  from t group by t.skill_key order by array_position(:'knoten'::text[], t.skill_key);
