-- ml2-pruefung.sql — Prüfung aus docs/themen/pruefung-batu-inhalte.md (Hauptabfrage), auf Stufe 2 eingeschränkt.
-- tauglich = Musterlösung + Fehlbild + gültige Antworten + kein Befund (pruef_auffaelligkeiten) + nicht ausgeschlossen.
-- Soll je Knoten: 3 taugliche, davon mind. 1 ohne MC. Zeile "ML2" markiert die fünf Knoten dieses Pakets.
\pset footer off
with gruppen(skill_key, sort, ml2) as (values
 ('potenzen',210,false),('bruch_dezimal',220,true),('dezimal_div',230,false),('dezimal_mult',240,true),
 ('vorzeichen_mult_div',250,true),('runden_ueberschlag',260,false),('dezimal_add_sub',270,false),
 ('bruch_kuerzen',280,true),('vorzeichen_add_sub',290,true)),
pilot as (select t.*, t trow, s.solution, s.correct_answers ca, s.acceptance acc, public.pruef_ausschluss(t.id) ausschluss
            from public.tasks t left join public.task_solutions s on s.task_id = t.id where t.pruef_pilot),
je as (
  select g.skill_key, g.sort, g.ml2, p.id, p.input_type = 'MC' mc, p.ausschluss,
         nullif(btrim(coalesce(p.solution,'')), '') is not null loesung,
         exists (select 1 from public.pruef_fehler_gruppen(p.acc)) fehlbild,
         (select array_agg(distinct fg.slug) from public.pruef_fehler_gruppen(p.acc) fg
           where not exists (select 1 from public.fehlbild_labels l where l.slug = fg.slug and nullif(btrim(l.klartext),'') is not null)) slugs_ohne,
         case when p.ca is null then false
              when jsonb_typeof(p.ca) = 'array' then jsonb_array_length(p.ca) > 0
              when jsonb_typeof(p.ca) = 'object' then p.input_type = 'MULTI_PART'
                   and not exists (select 1 from jsonb_array_elements(p.parts) pt
                                    where jsonb_typeof(p.ca -> (pt ->> 'nr')) is distinct from 'array'
                                       or jsonb_array_length(p.ca -> (pt ->> 'nr')) = 0)
              else false end
         and public.lsa_answers_valid(p.ca) and (p.acc is null or public.lsa_acceptance_valid(p.acc)) antworten,
         (select coalesce(array_agg(b ->> 'code' order by b ->> 'code'), '{}')
            from jsonb_array_elements(public.pruef_auffaelligkeiten(p.trow, coalesce(p.ca, '[]'), p.acc, p.solution)) b) befunde
    from gruppen g join pilot p on p.skill_key = g.skill_key),
bew as (select je.*, (loesung and fehlbild and antworten and cardinality(befunde) = 0 and ausschluss is null) tauglich from je)
select case when ml2 then 'ML2' else '' end paket, skill_key knoten,
       count(*) || ' / ' || count(*) filter (where not mc) gesamt_ohne_mc,
       count(*) filter (where loesung) musterloesung,
       count(*) filter (where fehlbild) fehlbild,
       coalesce((select string_agg(distinct s, ', ') from bew b2, unnest(b2.slugs_ohne) s where b2.skill_key = bew.skill_key), '–') slugs_ohne_klartext,
       count(*) filter (where antworten) antworten_gueltig,
       count(*) filter (where cardinality(befunde) > 0) mit_befund,
       count(*) filter (where tauglich) || ' (' || count(*) filter (where tauglich and not mc) || ') / 3 (1)' tauglich_soll,
       case when count(*) filter (where tauglich) >= 3 and count(*) filter (where tauglich and not mc) >= 1 then 'ja' else 'NEIN' end reicht
  from bew group by ml2, skill_key, sort order by sort;

select slug, klartext, freigegeben_am is not null freigegeben from public.fehlbild_labels where slug = 'teilgekuerzt';
select t.status, count(*) aufgaben from public.tasks t
 where t.pruef_pilot and t.skill_key in ('bruch_dezimal','vorzeichen_mult_div','bruch_kuerzen','vorzeichen_add_sub','dezimal_mult')
 group by 1;
