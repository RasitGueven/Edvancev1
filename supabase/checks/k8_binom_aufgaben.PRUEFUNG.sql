-- PRUEFUNG zur K8-Binom-Aufgabencharge.
-- Laeuft in begin/rollback und mutiert NICHTS dauerhaft.
--
--   psql "$DATABASE_URL" -P pager=off -v ON_ERROR_STOP=1 \
--        -f supabase/checks/k8_binom_aufgaben.PRUEFUNG.sql
--
-- Ohne Migrations-Zeitstempel im Dateinamen (Verwechslungsfalle a21).
--
-- Bindet die Migration NICHT per \ir ein: sie klammert sich selbst mit
-- begin/commit, ein \ir wuerde mittendrin committen und das abschliessende
-- rollback liefe ins Leere. Laeuft gegen den eingespielten Stand.

begin;

do $$
declare
  v_quelle  text   := 'edvance_k8_binom';
  v_skills  text[] := array['term_binom_quadrat', 'term_binom_quadratdifferenz',
                            'term_binom_faktorisieren', 'term_binom_gemischt'];
  v_ist       integer;
  v_soll      integer;
  v_liste     text;
  v_probe     uuid;
  v_gebrochen boolean;
begin

  -- ── Vorbedingung ──────────────────────────────────────────────────────────
  select count(*) into v_ist from public.tasks where source = v_quelle;
  if v_ist = 0 then
    raise exception 'Migration 20260830140000_k8_binom_aufgaben ist nicht eingespielt — erst einspielen, dann pruefen.';
  end if;

  -- ── A1: 24 Aufgaben an den vier Skills, sechs je Skill ────────────────────
  if v_ist <> 24 then
    raise exception 'A1 gebrochen: % Aufgaben mit source %, erwartet 24', v_ist, v_quelle;
  end if;
  select string_agg(skill_key || '=' || n, ', ' order by skill_key) into v_liste
    from (select skill_key, count(*) as n from public.tasks
           where source = v_quelle group by skill_key) x
   where n <> 6;
  if v_liste is not null then
    raise exception 'A1 gebrochen: nicht sechs je Skill (%), erwartet 6 je Skill', v_liste;
  end if;
  select count(distinct skill_key) into v_ist from public.tasks where source = v_quelle;
  if v_ist <> 4 then
    raise exception 'A1 gebrochen: % verschiedene Skills, erwartet 4', v_ist;
  end if;
  select string_agg(skill_key, ', ') into v_liste
    from public.tasks where source = v_quelle and not (skill_key = any (v_skills));
  if v_liste is not null then
    raise exception 'A1 gebrochen: fremder Skill in der Charge: %', v_liste;
  end if;
  raise notice 'A1 ok: 24 Aufgaben, sechs je Skill, genau die vier K8-Binom-Skills';

  -- ── A2: competency_content AM ITEM, skill_key, input_type, afb ────────────
  -- Der Punkt ist competency_content am Item selbst: bei den zehn P5-Items
  -- blieb genau diese Spalte leer, und der Eltern-Report zeigte sie als
  -- "Ohne Zuordnung".
  select string_agg(source_ref, ', ' order by source_ref) into v_liste
    from public.tasks
   where source = v_quelle
     and (coalesce(btrim(competency_content), '') = ''
          or coalesce(btrim(skill_key), '') = ''
          or coalesce(btrim(input_type), '') = ''
          or coalesce(btrim(afb), '') = '');
  if v_liste is not null then
    raise exception 'A2 gebrochen: unvollstaendige Pflichtfelder bei: %', v_liste;
  end if;
  -- afb ist 'I'|'II'|'III' (tasks_afb_check), nicht 1|2|3.
  select string_agg(distinct afb, ', ') into v_liste
    from public.tasks where source = v_quelle and afb not in ('I', 'II', 'III');
  if v_liste is not null then
    raise exception 'A2 gebrochen: unzulaessige afb-Werte: %', v_liste;
  end if;
  select count(distinct competency_content) into v_ist
    from public.tasks where source = v_quelle;
  if v_ist <> 1 or (select distinct competency_content from public.tasks where source = v_quelle)
                   <> 'arithmetik_algebra' then
    raise exception 'A2 gebrochen: competency_content ist nicht durchgaengig arithmetik_algebra';
  end if;
  raise notice 'A2 ok: competency_content (arithmetik_algebra) am Item, skill_key, input_type, afb (I/II/III) ueberall gesetzt';

  -- ── A3: jede Aufgabe hat eine Loesung ─────────────────────────────────────
  select string_agg(t.source_ref, ', ' order by t.source_ref) into v_liste
    from public.tasks t
   where t.source = v_quelle
     and not exists (select 1 from public.task_solutions s
                      where s.task_id = t.id
                        -- CASE statt AND: Postgres garantiert bei AND keine
                        -- Auswertungsreihenfolge, jsonb_array_length wuerde
                        -- sonst auf einer Nicht-Array-Zeile hart scheitern.
                        and case when jsonb_typeof(s.correct_answers) = 'array'
                                 then jsonb_array_length(s.correct_answers) > 0
                                 else false end);
  if v_liste is not null then
    raise exception 'A3 gebrochen: ohne verwertbare Loesung: %', v_liste;
  end if;
  raise notice 'A3 ok: alle 24 haben eine nichtleere Loesung in task_solutions';

  -- ── A4: known_errors ausnahmslos Objektform ───────────────────────────────
  -- Arrayform waere nicht bloss unschoen: lsa_fehlbild_match gibt dafuer nur
  -- den generischen Marker '__known__' zurueck, das Label ginge verloren.
  select string_agg(t.source_ref || '=' ||
                    coalesce(jsonb_typeof(s.acceptance -> 'known_errors'), 'fehlt'),
                    ', ' order by t.source_ref) into v_liste
    from public.tasks t join public.task_solutions s on s.task_id = t.id
   where t.source = v_quelle
     and coalesce(jsonb_typeof(s.acceptance -> 'known_errors'), 'fehlt') <> 'object';
  if v_liste is not null then
    raise exception 'A4 gebrochen: known_errors nicht in Objektform bei: %', v_liste;
  end if;
  select count(*) into v_ist
    from public.tasks t join public.task_solutions s on s.task_id = t.id
   where t.source = v_quelle and s.acceptance -> 'known_errors' = '{}'::jsonb;
  if v_ist <> 0 then
    raise exception 'A4 gebrochen: % Aufgabe(n) mit leerem known_errors', v_ist;
  end if;
  raise notice 'A4 ok: known_errors ueberall Objektform und nichtleer';

  -- ── A5: jeder Slug existiert in fehlbild_labels ───────────────────────────
  select string_agg(distinct ke.value #>> '{}', ', ') into v_liste
    from public.tasks t
    join public.task_solutions s on s.task_id = t.id
    cross join lateral jsonb_each(s.acceptance -> 'known_errors') as ke(key, value)
   where t.source = v_quelle
     and not exists (select 1 from public.fehlbild_labels l
                      where l.slug = ke.value #>> '{}');
  if v_liste is not null then
    raise exception 'A5 gebrochen: Slug(s) ohne Eintrag in fehlbild_labels: %', v_liste;
  end if;
  -- Und die drei neuen Slugs aus #150 muessen von mindestens drei Aufgaben
  -- sichtbar gemacht werden koennen, sonst sind sie tot.
  select string_agg(s2.slug || '=' || s2.n, ', ' order by s2.slug) into v_liste
    from (select ke.value #>> '{}' as slug, count(distinct t.id) as n
            from public.tasks t
            join public.task_solutions s on s.task_id = t.id
            cross join lateral jsonb_each(s.acceptance -> 'known_errors') as ke(key, value)
           where t.source = v_quelle
             and ke.value #>> '{}' in ('quadrat_gliedweise', 'quadratdifferenz_vorzeichen',
                                       'faktorisierung_unvollstaendig')
           group by 1) s2
   where s2.n < 3;
  if v_liste is not null then
    raise exception 'A5 gebrochen: neue Slugs von weniger als drei Aufgaben getragen: %', v_liste;
  end if;
  raise notice 'A5 ok: alle Slugs existieren, jeder neue Slug haengt an mindestens drei Aufgaben';

  -- ── A6: genau Rang 1 und 2 je Skill, sonst NULL ───────────────────────────
  select string_agg(x.skill_key || ' (r1=' || x.r1 || ', r2=' || x.r2 || ', sonstige=' || x.rest || ')',
                    ', ' order by x.skill_key) into v_liste
    from (select skill_key,
                 count(*) filter (where sondierrang = 1) as r1,
                 count(*) filter (where sondierrang = 2) as r2,
                 count(*) filter (where sondierrang is not null and sondierrang > 2) as rest
            from public.tasks where source = v_quelle group by skill_key) x
   where x.r1 <> 1 or x.r2 <> 1 or x.rest <> 0;
  if v_liste is not null then
    raise exception 'A6 gebrochen: %', v_liste;
  end if;
  select count(*) into v_ist
    from public.tasks where source = v_quelle and sondierrang is null;
  if v_ist <> 16 then
    raise exception 'A6 gebrochen: % Aufgaben ohne Rang, erwartet 16 (24 minus 4x2)', v_ist;
  end if;
  raise notice 'A6 ok: je Skill genau ein Rang 1 und ein Rang 2, die uebrigen 16 NULL';

  -- ── A7: Negativkontrolle — erfundener Slug MUSS A5 brechen ────────────────
  -- Der Probe-Slug faellt in denselben Suchraum wie A5. Das aeussere rollback
  -- raeumt ihn weg.
  select t.id into v_probe from public.tasks t
   where t.source = v_quelle and t.input_type = 'MC' order by t.source_ref limit 1;

  update public.task_solutions
     set acceptance = jsonb_set(acceptance, '{known_errors,zzz_erfundener_slug}',
                                to_jsonb('gibt_es_nicht'::text))
   where task_id = v_probe;

  v_soll := 0;
  select count(distinct ke.value #>> '{}') into v_ist
    from public.tasks t
    join public.task_solutions s on s.task_id = t.id
    cross join lateral jsonb_each(s.acceptance -> 'known_errors') as ke(key, value)
   where t.source = v_quelle
     and not exists (select 1 from public.fehlbild_labels l
                      where l.slug = ke.value #>> '{}');

  v_gebrochen := false;
  begin
    if v_ist <> v_soll then
      raise exception 'A5 gebrochen: % Slug(s) ohne Eintrag in fehlbild_labels, erwartet %', v_ist, v_soll;
    end if;
  exception when others then
    v_gebrochen := true;
    raise notice 'A7 ok: A5 hat gebrochen — Ist = % unbekannte(r) Slug(s), Soll = %. Meldung: %',
      v_ist, v_soll, sqlerrm;
  end;

  if not v_gebrochen then
    raise exception 'A7 gebrochen: A5 hat den erfundenen Slug NICHT bemerkt (Ist = %, Soll = %). Die Zusicherung ist wertlos.',
      v_ist, v_soll;
  end if;

  raise notice 'K8-Binom-Aufgaben: ALLE PRUEFUNGEN BESTANDEN (A1-A7)';
end $$;

rollback;
