-- PRUEFUNG zu K8 Lineare Funktionen, Migration 2 (30 Aufgaben).
-- Laeuft in begin/rollback und mutiert NICHTS dauerhaft.
--
--   psql "$DATABASE_URL" -P pager=off -v ON_ERROR_STOP=1 -f supabase/checks/k8_linfkt_aufgaben.PRUEFUNG.sql
--
-- Bindet die Migration NICHT per \ir ein: sie klammert sich selbst mit
-- begin/commit. Laeuft gegen den eingespielten Stand (nach 20261001133106).

begin;

do $$
declare
  v_quelle text := 'edvance_k8_linfkt';
  v_ist    integer;
  v_text   text;
  v_ok     boolean;
begin
  -- ── Vorbedingung ──────────────────────────────────────────────────────────
  if not exists (select 1 from public.tasks where source = v_quelle) then
    raise exception 'Migration 20261001133106_aufgaben_k8_linfkt.sql nicht eingespielt.';
  end if;

  -- ── A1: 30 Aufgaben, je sechs pro Knoten ─────────────────────────────────
  select count(*) into v_ist from (
    select skill_key from public.tasks where source = v_quelle
     group by skill_key having count(*) = 6) x
   where x.skill_key in ('fkt_linear_steigung', 'fkt_linear_yabschnitt', 'fkt_linear_graph',
                         'fkt_linear_gleichung', 'fkt_linear_nullstelle');
  if v_ist <> 5 then raise exception 'A1: nur % von 5 Knoten mit genau 6 Aufgaben', v_ist; end if;
  select count(*) into v_ist from public.tasks where source = v_quelle;
  if v_ist <> 30 then raise exception 'A1: % statt 30 Aufgaben', v_ist; end if;
  raise notice 'A1 ok: 30 Aufgaben, je 6 zu den fuenf fkt_linear_*-Knoten';

  -- ── A2: draft, alle Lena-Felder gesetzt, nur erlaubte Werte ──────────────
  select count(*) into v_ist from public.tasks t
   where t.source = v_quelle and t.status = 'draft' and t.input_type = 'NUMERIC'
     and t.afb in ('I', 'II', 'III') and t.est_duration_sec between 10 and 3600
     and t.curriculum_grade = 8 and t.competency_content = 'funktionen'
     and t.competency_process is not null and t.source_ref like 'linfkt-%'
     and t.needs_image = (t.skill_key = 'fkt_linear_graph')
     and (t.cluster_id is not null or not exists (select 1 from public.skill_clusters))
     and t.parts = '[]'::jsonb
     and t.vorbefuellt ? 'afb' and t.vorbefuellt -> 'hints' ->> 'art' = 'leer';
  if v_ist <> 30 then raise exception 'A2: % von 30 Aufgaben vollstaendig', v_ist; end if;
  if exists (select 1 from public.tasks where source = v_quelle
              and (question ~* 'gemeistert|meisterst' or title ~* 'gemeistert|meisterst')) then
    raise exception 'A2: Mastery-Sprache in einer Aufgabe';
  end if;
  raise notice 'A2 ok: 30 draft, NUMERIC, Lena-Felder gesetzt, Stoffanker 8, Inhaltsfeld funktionen';

  -- ── A3: Loesungen ────────────────────────────────────────────────────────
  select count(*) into v_ist from public.tasks t join public.task_solutions s on s.task_id = t.id
   where t.source = v_quelle
     and public.lsa_has_answers(t.input_type, t.parts, s.correct_answers)
     and public.lsa_answers_valid(s.correct_answers)
     and public.lsa_acceptance_valid(s.acceptance)
     and jsonb_typeof(s.acceptance -> 'known_errors') = 'object'
     and btrim(s.solution) <> '' and s.hints = '[]'::jsonb
     and jsonb_array_length(s.typical_errors) > 0;
  if v_ist <> 30 then raise exception 'A3: % von 30 Loesungen gueltig', v_ist; end if;
  raise notice 'A3 ok: 30 Loesungen (Antworten, acceptance in Objektform, Loesungsweg, keine Hinweise)';

  -- ── A4: jeder known_errors-Slug existiert ────────────────────────────────
  -- Altbestand-Slugs (ohne Familie und Klartext, z. B. nur_einmal_addiert) hat
  -- A20 aus Prod-Daten geseedet; ein Neuaufbau aus Migrationen kennt sie nicht.
  -- Streng geprueft wird deshalb nur, wo der Altbestand da ist (Prod: 53 Zeilen).
  select count(distinct kv.slug) into v_ist
    from public.tasks t join public.task_solutions s on s.task_id = t.id
    cross join lateral jsonb_each_text(s.acceptance -> 'known_errors') kv(wert, slug)
   where t.source = v_quelle
     and not exists (select 1 from public.fehlbild_labels l where l.slug = kv.slug);
  if (select count(*) from public.fehlbild_labels where familie is null and klartext is null) >= 10 then
    if v_ist <> 0 then raise exception 'A4: % unbekannte known_errors-Slugs', v_ist; end if;
    raise notice 'A4 ok: alle known_errors-Slugs in fehlbild_labels';
  else
    raise notice 'A4 uebersprungen: kein Altbestand (Neuaufbau), % Slug(s) nur in Prod', v_ist;
  end if;

  -- ── A5: Bewertung und Fehlbild-Erkennung an Stichproben ──────────────────
  v_ok := public.lsa_is_correct('NUMERIC',
            (select correct_answers from public.task_solutions where task_id = 'ffc758dc-dcdb-4b66-9281-4563b18c2dc8'),
            '{"value": "1/2"}'::jsonb)                                   -- steigung-04: Bruch
      and public.lsa_is_correct('NUMERIC',
            (select correct_answers from public.task_solutions where task_id = 'ffc758dc-dcdb-4b66-9281-4563b18c2dc8'),
            '{"value": "0,5"}'::jsonb)                                   -- steigung-04: Dezimal
      and public.lsa_is_correct('NUMERIC',
            (select correct_answers from public.task_solutions where task_id = 'e4611c3d-02b9-4a0b-8e42-795f8a15a925'),
            '{"value": "−6"}'::jsonb)                                    -- yabschnitt-03: Unicode-Minus
      and public.lsa_is_correct('NUMERIC',
            (select correct_answers from public.task_solutions where task_id = '55d52e3e-cdd5-4e3c-9929-fb82aac16d33'),
            '{"value": "11 €"}'::jsonb)                                  -- gleichung-05: mit Einheit
      and public.lsa_fehlbild_match('short_input',
            (select acceptance -> 'known_errors' from public.task_solutions where task_id = '305c5063-1e7a-4919-a8ba-b97128fc0367'),
            '{"value": "−2,5"}'::jsonb) = 'vorzeichen_beim_umstellen'    -- nullstelle-03
      and public.lsa_fehlbild_match('short_input',
            (select acceptance -> 'known_errors' from public.task_solutions where task_id = 'ffc758dc-dcdb-4b66-9281-4563b18c2dc8'),
            '{"value": "2"}'::jsonb) = 'steigung_kehrwert'               -- steigung-04
      and public.lsa_fehlbild_match('short_input',
            (select acceptance -> 'known_errors' from public.task_solutions where task_id = '24a633b2-ca0b-4909-9907-26bb0e6c163b'),
            '{"value": "0.5"}'::jsonb) = 'koordinaten_vertauscht';       -- graph-04
  if not v_ok then raise exception 'A5: Bewertung/Fehlbild-Erkennung an einer Stichprobe falsch'; end if;
  raise notice 'A5 ok: Bruch, Dezimal, Unicode-Minus, Einheit gewertet; Fehlbilder erkannt';

  -- ── A6: jedes neue Fehlbild in mindestens drei Aufgaben ──────────────────
  for v_text in select unnest(array['steigung_kehrwert', 'm_b_vertauscht', 'achsenabschnitt_verwechselt']) loop
    select count(distinct t.id) into v_ist
      from public.tasks t join public.task_solutions s on s.task_id = t.id
      cross join lateral jsonb_each_text(s.acceptance -> 'known_errors') kv(wert, slug)
     where t.source = v_quelle and kv.slug = v_text;
    if v_ist < 3 then raise exception 'A6: % nur in % Aufgaben', v_text, v_ist; end if;
  end loop;
  raise notice 'A6 ok: alle drei neuen Fehlbilder in mindestens drei Aufgaben';

  -- ── A7: Sondierrang 1 und 2 je Knoten, Rest NULL ─────────────────────────
  select count(*) into v_ist from (
    select skill_key from public.tasks where source = v_quelle
     group by skill_key
    having count(*) filter (where sondierrang = 1) = 1
       and count(*) filter (where sondierrang = 2) = 1
       and count(*) filter (where sondierrang is null) = count(*) - 2) x;
  if v_ist <> 5 then raise exception 'A7: Sondierrang nicht je Knoten 1/2/Rest NULL (% von 5)', v_ist; end if;
  raise notice 'A7 ok: je Knoten Rang 1 und 2, Rest NULL';

  -- ── A8: Figuren nur bei fkt_linear_graph, alt_text ohne Ziffern ──────────
  select count(*) into v_ist from public.task_figures f join public.tasks t on t.id = f.task_id
   where t.source = v_quelle and t.skill_key = 'fkt_linear_graph'
     and f.generator = 'koordinatensystem' and f.alt_text !~ '[0-9]';
  if v_ist <> 6 then raise exception 'A8: % von 6 Figurauftraegen', v_ist; end if;
  select count(*) into v_ist from public.task_figures f join public.tasks t on t.id = f.task_id
   where t.source = v_quelle and t.skill_key <> 'fkt_linear_graph';
  if v_ist <> 0 then raise exception 'A8: % Figuren ausserhalb fkt_linear_graph', v_ist; end if;
  raise notice 'A8 ok: 6 Figuren (koordinatensystem) nur bei fkt_linear_graph';

  -- ── A9: keine Loesung im Payload ─────────────────────────────────────────
  select count(*) into v_ist from public.tasks
   where source = v_quelle
     and question_payload ?| array['correct', 'accepted', 'pairs', 'blanks', 'expected'];
  if v_ist <> 0 then raise exception 'A9: % Payloads mit Loesungsschluessel', v_ist; end if;
  raise notice 'A9 ok: kein Loesungsschluessel im question_payload';

  -- ── A10: Bruchprobe — A6 schlaegt an, wenn ein Slug fehlt ────────────────
  begin
    update public.task_solutions s
       set acceptance = jsonb_set(s.acceptance, '{known_errors}',
             (select coalesce(jsonb_object_agg(k, v), '{}'::jsonb)
                from jsonb_each(s.acceptance -> 'known_errors') e(k, v)
               where v <> '"m_b_vertauscht"'::jsonb))
      from public.tasks t
     where t.id = s.task_id and t.source = v_quelle;
    select count(distinct t.id) into v_ist
      from public.tasks t join public.task_solutions s on s.task_id = t.id
      cross join lateral jsonb_each_text(s.acceptance -> 'known_errors') kv(wert, slug)
     where t.source = v_quelle and kv.slug = 'm_b_vertauscht';
    if v_ist <> 0 then raise exception 'A10-Bruchprobe: Ist = %, Soll = 0', v_ist; end if;
    raise sqlstate 'P0099';
  exception when sqlstate 'P0099' then null;
  end;
  raise notice 'A10 ok: Bruchprobe — ohne m_b_vertauscht faellt die Zaehlung auf 0 (A6 wuerde anschlagen)';
end $$;

rollback;
