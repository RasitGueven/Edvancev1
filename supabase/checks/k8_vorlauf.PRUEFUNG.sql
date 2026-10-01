-- PRUEFUNG zum K8-/K9-Vorlauf (Tiefengrenze, zwei Fundament-Knoten, zwoelf Aufgaben).
-- Laeuft in begin/rollback und mutiert NICHTS dauerhaft.
--
--   psql "$DATABASE_URL" -P pager=off -v ON_ERROR_STOP=1 -f supabase/checks/k8_vorlauf.PRUEFUNG.sql
--
-- Bindet die Migrationen NICHT per \ir ein: sie klammern sich selbst mit
-- begin/commit, ein \ir hier wuerde mittendrin committen. Sie laeuft gegen den
-- eingespielten Stand (nach allen drei *_k8_vorlauf.sql).

begin;

do $$
declare
  v_quelle text := 'edvance_fundament_vorlauf';
  v_ist    integer;
  v_text   text;
  v_ok     boolean;
begin
  -- ── Vorbedingung ──────────────────────────────────────────────────────────
  if not exists (select 1 from public.skills where skill_key = 'term_einsetzen') then
    raise exception 'Vorlauf-Migrationen nicht eingespielt — erst einspielen, dann pruefen.';
  end if;

  -- ── V1: Tiefengrenze 1..12, Guard unveraendert ───────────────────────────
  select pg_get_constraintdef(oid) into v_text
    from pg_constraint where conname = 'skills_fundament_tiefe_check';
  if v_text not like '%<= 12%' then
    raise exception 'V1: skills_fundament_tiefe_check ist %', v_text;
  end if;
  begin
    insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
      values ('zz_vorlauf_probe_13', 'Probe', 'mathematik', 9, 13);
    raise exception 'V1: Tiefe 13 wurde angenommen';
  exception when check_violation then null;
  end;
  insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
    values ('zz_vorlauf_probe_9', 'Probe', 'mathematik', 9, 9);
  insert into public.skill_kante (skill_key, voraussetzt_skill_key)
    values ('zz_vorlauf_probe_9', 'prozent_veraenderung');   -- 9 ueber 8: jetzt erlaubt
  begin
    insert into public.skill_kante (skill_key, voraussetzt_skill_key)
      values ('prozent_veraenderung', 'zz_vorlauf_probe_9');  -- 8 ueber 9: Guard
    raise exception 'V1: Guard hat eine tiefere Voraussetzung angenommen';
  exception when check_violation then null;
  end;
  select count(*) into v_ist
    from public.skill_kante k
    join public.skills s on s.skill_key = k.skill_key
    join public.skills v on v.skill_key = k.voraussetzt_skill_key
   where v.fundament_tiefe >= s.fundament_tiefe;
  if v_ist <> 0 then raise exception 'V1: % Kanten verletzen den Guard', v_ist; end if;
  raise notice 'V1 ok: Grenze 1..12, Tiefe 9 ueber 8 erlaubt, 13 abgewiesen, Guard greift, 0 Kanten verletzt';

  -- ── V2: zwei Knoten, drei Kanten ─────────────────────────────────────────
  select count(*) into v_ist from public.skills
   where (skill_key, klasse_herkunft, fundament_tiefe) in (('geo_koordinaten', 6, 2), ('term_einsetzen', 7, 5));
  if v_ist <> 2 then raise exception 'V2: Knoten fehlen oder abweichend (%)', v_ist; end if;
  select count(*) into v_ist from public.skill_kante
   where (skill_key, voraussetzt_skill_key) in (('geo_koordinaten', 'vorzeichen_add_sub'),
          ('term_einsetzen', 'vorzeichen_vorrang'), ('term_einsetzen', 'potenzen'));
  if v_ist <> 3 then raise exception 'V2: % von 3 Kanten', v_ist; end if;
  raise notice 'V2 ok: geo_koordinaten (6/2), term_einsetzen (7/5), 3 Kanten';

  -- ── V3: zwei neue Fehlbilder, Entwurf ────────────────────────────────────
  select count(*) into v_ist from public.fehlbild_labels
   where slug in ('koordinaten_vertauscht', 'koordinate_vorzeichen_verloren')
     and freigegeben_am is null and btrim(klartext) <> '' and btrim(erklaerung) <> '';
  if v_ist <> 2 then raise exception 'V3: % von 2 Fehlbildern als Entwurf', v_ist; end if;
  raise notice 'V3 ok: 2 Fehlbilder, freigegeben_am NULL';

  -- ── V4: zwoelf Aufgaben, draft, alle Lena-Felder gesetzt ─────────────────
  select count(*) into v_ist from public.tasks t
   where t.source = v_quelle and t.status = 'draft'
     and t.afb in ('I', 'II', 'III') and t.est_duration_sec is not null
     and t.curriculum_grade = case t.skill_key when 'geo_koordinaten' then 6 else 7 end
     and t.competency_content is not null and t.competency_process is not null
     and t.needs_image = (t.skill_key = 'geo_koordinaten')
     and (t.cluster_id is not null or not exists (select 1 from public.skill_clusters))
     and t.vorbefuellt ? 'afb' and t.vorbefuellt -> 'hints' ->> 'art' = 'leer';
  if v_ist <> 12 then raise exception 'V4: % von 12 Aufgaben vollstaendig', v_ist; end if;
  select count(*) into v_ist from public.tasks t
   where t.source = v_quelle and t.input_type = 'MULTI_PART'
     and public.lsa_parts_valid(t.parts)
     and not exists (select 1 from jsonb_array_elements(t.parts) p
                      where p ->> 'afb' is null or p ->> 'competency_content' is null);
  if v_ist <> 6 then raise exception 'V4: % von 6 MULTI_PART mit Teil-AFB/-Inhaltsfeld', v_ist; end if;
  raise notice 'V4 ok: 12 Aufgaben draft, Lena-Felder gesetzt, 6 MULTI_PART gueltig';

  -- ── V5: Loesungen ────────────────────────────────────────────────────────
  select count(*) into v_ist from public.tasks t join public.task_solutions s on s.task_id = t.id
   where t.source = v_quelle
     and public.lsa_has_answers(t.input_type, t.parts, s.correct_answers)
     and public.lsa_answers_valid(s.correct_answers)
     and public.lsa_acceptance_valid(s.acceptance)
     and btrim(s.solution) <> '' and s.hints = '[]'::jsonb
     and jsonb_array_length(s.typical_errors) > 0;
  if v_ist <> 12 then raise exception 'V5: % von 12 Loesungen gueltig', v_ist; end if;
  raise notice 'V5 ok: 12 Loesungen (Antworten, acceptance, Loesungsweg, keine Hinweise)';

  -- ── V6: Bewertung und Fehlbild-Erkennung an Stichproben ──────────────────
  v_ok := public.lsa_is_correct('NUMERIC',
            (select correct_answers from public.task_solutions where task_id = 'dea9fea4-6976-4632-a33d-547693f1fbc9'),
            '{"value": "−3"}'::jsonb)
      and public.lsa_is_correct('SHORT_TEXT',
            (select correct_answers -> '2' from public.task_solutions where task_id = 'e0daa32b-4d16-49ae-82b4-ece970facc2f'),
            '{"text": "-2,5"}'::jsonb)
      and public.lsa_fehlbild_match('short_input',
            (select acceptance -> '1' -> 'known_errors' from public.task_solutions where task_id = 'a1fa4311-c631-47ba-a4a7-15e12149db4c'),
            '{"text": "4"}'::jsonb) = 'koordinate_vorzeichen_verloren'
      and public.lsa_fehlbild_match('short_input',
            (select acceptance -> 'known_errors' from public.task_solutions where task_id = '16352abe-36f9-482c-972d-a7b10493919d'),
            '{"value": "-12"}'::jsonb) = 'vorzeichen_potenz';
  if not v_ok then raise exception 'V6: Bewertung/Fehlbild-Erkennung an einer Stichprobe falsch'; end if;
  raise notice 'V6 ok: Unicode-Minus und Komma gewertet, Fehlbilder erkannt';

  -- ── V7: jedes neue Fehlbild in mindestens drei Aufgaben ──────────────────
  for v_text in select unnest(array['koordinaten_vertauscht', 'koordinate_vorzeichen_verloren']) loop
    select count(distinct t.id) into v_ist
      from public.tasks t join public.task_solutions s on s.task_id = t.id
     where t.source = v_quelle
       and s.acceptance::text like '%"' || v_text || '"%';
    if v_ist < 3 then raise exception 'V7: % nur in % Aufgaben', v_text, v_ist; end if;
  end loop;
  raise notice 'V7 ok: beide neuen Fehlbilder in mindestens drei Aufgaben';

  -- ── V8: Sondierrang 1 und 2 je Knoten, Rest NULL ─────────────────────────
  select count(*) into v_ist from (
    select skill_key from public.tasks where source = v_quelle
     group by skill_key
    having count(*) filter (where sondierrang = 1) = 1
       and count(*) filter (where sondierrang = 2) = 1
       and count(*) filter (where sondierrang is null) = count(*) - 2) x;
  if v_ist <> 2 then raise exception 'V8: Sondierrang nicht je Knoten 1/2/Rest NULL'; end if;
  raise notice 'V8 ok: je Knoten Rang 1 und 2, Rest NULL';

  -- ── V9: Figuren und Payload ──────────────────────────────────────────────
  select count(*) into v_ist from public.task_figures f join public.tasks t on t.id = f.task_id
   where t.source = v_quelle and f.generator = 'koordinatensystem' and f.svg_hash is null;
  if v_ist <> 6 then raise exception 'V9: % von 6 Figurauftraegen', v_ist; end if;
  if public.lsa_question_payload('650eed2a-79e5-4a6f-9ed2-a51053fe75c8')::text
     ~ '"(correct_answers|acceptance|params|known_errors)"' then
    raise exception 'V9: Loesungsdaten im Payload';
  end if;
  raise notice 'V9 ok: 6 Figurauftraege (noch nicht hochgeladen), Payload ohne Loesung';
end $$;

rollback;
