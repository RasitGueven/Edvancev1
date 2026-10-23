-- LSA-A1: lsa_question_payload liefert das Themenfeld der Aufgabe, damit die App beim Wechsel den Bereich
-- ansagen kann (Bauauftrag docs/lsa/Bauauftrag-LSA-A1.md, Entscheidungen 1, 2 und 5).
--
-- lsa_themenfeld(skill_key) bildet feldVon aus src/lib/report/elternbericht/themenfelder.ts nach:
--   1. AUSNAHMEN (inhaltsbereiche.ts) zuerst,
--   2. sonst der längste passende Präfix nach ganzen Segmenten — nur echte Präfixe, der volle Schlüssel
--      zählt nicht (wie die Schleife ab teile.length - 1 in inhaltsbereich()),
--   3. Inhaltsbereich → Themenfeld wie THEMENFELDER.
-- Unbekannt → 'weitere'. Rückgabe ist immer der Schlüssel, nie ein Text.
--
-- Gleichlauf: tools/themenfeld-fixture.ts schreibt aus feldVon die Paare nach
-- supabase/tests/fixtures/themenfeld.sql; Vitest hält die Datei aktuell, pgTAP
-- (supabase/tests/lsa_themenfeld.test.sql) prüft diese Funktion dagegen. Wer PRAEFIX, AUSNAHMEN oder
-- THEMENFELDER ändert, ändert diese Funktion mit (neue Migration).
--
-- lsa_question_payload: einzige Änderung ist 'themenfeld' in allen drei Arten. platz_next, lsa_start und
-- lsa_submit bauen den Payload über diese Funktion, das Feld kommt also überall an. Rechte bleiben
-- (create or replace behält die ACL).

create or replace function public.lsa_themenfeld(p_skill_key text)
returns text
language sql
immutable
set search_path = ''
as $function$
  with ausnahme(skill_key, bereich) as (
    values ('proportionalitaet', 'zuordnungen'),
           ('potenzen', 'potenzen'),
           ('runden_ueberschlag', 'zahlen')
  ),
  praefix(praefix, bereich) as (
    values ('bruch', 'brueche'),
           ('dezimal', 'dezimalzahlen'),
           ('vorzeichen', 'negative_zahlen'),
           ('groessen', 'groessen'),
           ('geo', 'geometrie'),
           ('geo_flaeche', 'geometrie'),
           ('geo_winkel', 'geometrie'),
           ('geo_koerper', 'geometrie'),
           ('geo_kreis', 'geometrie'),
           ('geo_aehnlich', 'geometrie'),
           ('geo_pythagoras', 'geometrie'),
           ('geo_trigo', 'geometrie'),
           ('term', 'terme'),
           ('gleichung', 'gleichungen'),
           ('gleichung_lgs', 'gleichungen'),
           ('gleichung_quadr', 'gleichungen'),
           ('prozent', 'prozent'),
           ('prozent_zins', 'prozent'),
           ('fkt', 'funktionen'),
           ('fkt_linear', 'funktionen'),
           ('fkt_quadr', 'funktionen'),
           ('fkt_exp', 'funktionen'),
           ('fkt_sinus', 'funktionen'),
           ('zahl', 'zahlen'),
           ('zahl_potenz', 'potenzen'),
           ('zahl_wurzel', 'wurzeln'),
           ('stoch', 'stochastik'),
           ('stoch_bedingt', 'stochastik'),
           ('stoch_pfad', 'stochastik')
  ),
  feld(bereich, feld) as (
    values ('brueche', 'brueche'), ('dezimalzahlen', 'brueche'),
           ('prozent', 'prozent'), ('zuordnungen', 'prozent'),
           ('terme', 'terme'), ('gleichungen', 'terme'),
           ('geometrie', 'geometrie'),
           ('groessen', 'groessen'),
           ('zahlen', 'zahlen'), ('negative_zahlen', 'zahlen'), ('potenzen', 'zahlen'), ('wurzeln', 'zahlen'),
           ('funktionen', 'funktionen'),
           ('stochastik', 'zufall')
  ),
  teile(t) as (
    select string_to_array(p_skill_key, '_')
  ),
  bereich(b) as (
    select coalesce(
      (select a.bereich from ausnahme a where a.skill_key = p_skill_key),
      (select p.bereich
         from teile, generate_series(cardinality(teile.t) - 1, 1, -1) as n, praefix p
        where p.praefix = array_to_string(teile.t[1:n], '_')
        order by n desc
        limit 1))
  )
  select coalesce((select f.feld from feld f, bereich where f.bereich = bereich.b), 'weitere')
$function$;

revoke all on function public.lsa_themenfeld(text) from public, anon, authenticated;

CREATE OR REPLACE FUNCTION public.lsa_question_payload(p_task_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select jsonb_strip_nulls(
    case
      when t.input_type = 'MULTI_PART' then jsonb_build_object(
        'task_id',    t.id,
        'kind',       'multi_part',
        'themenfeld', public.lsa_themenfeld(t.skill_key),
        'stem',       coalesce(t.question, ''),
        'assets',     public.lsa_task_assets(t.id),
        'table',      public.lsa_public_table(t.question_payload -> 'table'),
        'parts',      public.lsa_public_parts(t.parts, s.correct_answers)
      )
      when t.input_type = 'MC' then jsonb_build_object(
        'task_id',    t.id,
        'kind',       'mc',
        'themenfeld', public.lsa_themenfeld(t.skill_key),
        'prompt',     coalesce(t.question, ''),
        'assets',     public.lsa_task_assets(t.id),
        'table',      public.lsa_public_table(t.question_payload -> 'table'),
        'options',    coalesce((
          select jsonb_agg(
                   jsonb_build_object('id', o ->> 'id', 'label', o ->> 'label')
                   order by ord
                 )
            from jsonb_array_elements(
                   case
                     when jsonb_typeof(t.question_payload -> 'options') = 'array'
                       then t.question_payload -> 'options'
                     else '[]'::jsonb
                   end
                 ) with ordinality as e(o, ord)
        ), '[]'::jsonb)
      )
      else jsonb_build_object(
        'task_id',    t.id,
        'kind',       'short_input',
        'themenfeld', public.lsa_themenfeld(t.skill_key),
        'prompt',     coalesce(t.question, ''),
        'assets',     public.lsa_task_assets(t.id),
        'table',      public.lsa_public_table(t.question_payload -> 'table'),
        'unit',       t.unit,
        'input_hint', public.lsa_input_hint(t.input_type, t.bruch, s.correct_answers, t.unit)
      )
    end
  )
  from tasks t
  left join task_solutions s on s.task_id = t.id
  where t.id = p_task_id
$function$;
