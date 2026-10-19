-- l1-wertung.sql — L1: Wertung jedes neuen bzw. umgehängten Fehlerwerts und der richtigen Antworten.
-- Läuft in der Wegwerf-DB nach M1 (tools/l1-wegwerf-db.sh). Aufruf wie im Fehlbild-Trigger:
-- lsa_fehlbild_match(lower(input_type), acceptance -> 'known_errors', response), dazu lsa_is_correct und lsa_grade.

do $w$
declare
  r record;
  v_fb text; v_ok boolean; v_gr text; v_n integer := 0;
begin
  for r in
    select e.id, e.wert, e.slug, t.input_type, s.correct_answers, s.acceptance
      from (values
        ('e96cd37d-0254-4051-bf2d-71a6f7fa2aaf'::uuid, '2',   'plus_minus_vertauscht'),
        ('e96cd37d-0254-4051-bf2d-71a6f7fa2aaf'::uuid, '8',   'betrag_fehler'),
        ('e96cd37d-0254-4051-bf2d-71a6f7fa2aaf'::uuid, '-2',  'vorzeichen_ignoriert'),
        ('17674b19-fe14-42ca-98db-6598fa8c5a3a'::uuid, '-13', 'plus_minus_vertauscht'),
        ('27f51c08-6a47-4ceb-b189-f5f07cbcf1cf'::uuid, '-4',  'plus_minus_vertauscht'),
        ('27f51c08-6a47-4ceb-b189-f5f07cbcf1cf'::uuid, '8',   'betrag_fehler'),
        ('27f51c08-6a47-4ceb-b189-f5f07cbcf1cf'::uuid, '4',   'vorzeichen_ignoriert'),
        ('c92aa7e8-1e2d-4c80-a1fc-0fe4fedd86b0'::uuid, '-11', 'plus_minus_vertauscht'),
        ('3b44eada-3589-4bdb-a33b-2fb2ca0a1726'::uuid, '-14', 'plus_minus_vertauscht'),
        ('2e8ce53f-1357-48b2-8d76-0633ae836980'::uuid, '2',   'merksatz_als_addition'),
        ('e58cb290-db86-40df-b60b-03aee393107b'::uuid, '-5',  'merksatz_als_addition'),
        -- Schreibweise: Leerraum wird normalisiert, das Wertungsurteil bleibt „nicht“
        ('17674b19-fe14-42ca-98db-6598fa8c5a3a'::uuid, ' -13 ', 'plus_minus_vertauscht')
      ) e(id, wert, slug)
      join public.tasks t on t.id = e.id join public.task_solutions s on s.task_id = e.id
  loop
    v_fb := public.lsa_fehlbild_match(lower(r.input_type), r.acceptance -> 'known_errors', jsonb_build_object('value', r.wert));
    v_ok := public.lsa_is_correct(r.input_type, r.correct_answers, jsonb_build_object('value', r.wert));
    v_gr := public.lsa_grade(r.input_type, r.acceptance, r.correct_answers, jsonb_build_object('value', r.wert));
    if v_fb is distinct from r.slug or v_ok is distinct from false or v_gr is distinct from 'nicht' then
      raise exception 'W % „%“: Fehlbild %, richtig %, Urteil % (erwartet %, false, nicht)', r.id, r.wert, v_fb, v_ok, v_gr, r.slug;
    end if;
    raise notice 'W ok % „%“ → % / falsch / nicht', left(r.id::text, 8), r.wert, v_fb;
    v_n := v_n + 1;
  end loop;
  if v_n <> 12 then raise exception 'W nur % von 12 Fehlerwerten geprüft', v_n; end if;

  v_n := 0;
  for r in
    select t.id, t.input_type, s.correct_answers, s.acceptance, a.wert
      from public.tasks t join public.task_solutions s on s.task_id = t.id,
           jsonb_array_elements_text(s.correct_answers) a(wert)
     where t.skill_key in ('vorzeichen_add_sub', 'vorzeichen_mult_div')
        or t.id = '0b7e781c-60ae-4a93-afb8-2ee2b400b15a'
  loop
    v_fb := public.lsa_fehlbild_match(lower(r.input_type), r.acceptance -> 'known_errors', jsonb_build_object('value', r.wert));
    v_ok := public.lsa_is_correct(r.input_type, r.correct_answers, jsonb_build_object('value', r.wert));
    v_gr := public.lsa_grade(r.input_type, r.acceptance, r.correct_answers, jsonb_build_object('value', r.wert));
    if v_ok is distinct from true or v_gr is distinct from 'voll' or v_fb is not null then
      raise exception 'W richtig % „%“: richtig %, Urteil %, Fehlbild %', r.id, r.wert, v_ok, v_gr, v_fb;
    end if;
    v_n := v_n + 1;
  end loop;
  raise notice 'W ok: % richtige Antworten bleiben richtig (voll, kein Fehlbild)', v_n;
end $w$;
