-- Prozent-Gate (Teil 2 nach #294): zwei blockierende Regeln im Freigabe-Gate.
--
-- Seit 20261021073327_lsa_grade_prozent_faktor zählt „%“ in lsa_grade als Faktor 1/100. Ausnahme ist
-- acceptance.unit = '%': Dann ist die Antwort selbst ein Prozentsatz (Zinssatz, Prozentsatz). Zwei Stände
-- bewerten danach falsch, das Gate hält beide jetzt vor 'ready' auf:
--
--   prozent_ohne_marker       Das Antwortfeld zeigt „%“ (tasks.unit), die Wertungsregel trägt aber kein
--                             acceptance.unit = '%'. Dann gilt z. B. 0,12 über „12 %“ als richtig.
--   prozentzahl_ohne_zeichen  Eine richtige Antwort ohne Einheit ist das 100-Fache der kanonischen Antwort
--                             (bei kanonisch „20 %“ zählt diese als 0,2), und es gibt keinen Marker. Dann
--                             gilt z. B. „60“ bei 3/5 als richtig.
--
-- Beide Regeln gelten nur für eine flache Wertungsregel (acceptance mit canonical). Ohne Regel wertet
-- lsa_grade über lsa_is_correct, der Faktor wirkt dort nicht. Das betrifft auch Aufgaben mit „%“ am Feld ohne
-- Regel: d350fb95 (VERA8, ready, Antwort 10) bleibt bewusst unverändert und frei (Entscheidung Rasit, 21.10.2026).
-- Die zweite Regel prüft nur kanonische Antworten ohne Einheit oder mit „%“: Bei „0,5 m“ ist „50“ (cm) kein
-- Prozentfehler.
--
-- Rückgabe wie bisher „task_status_set: …“, hier mit festem Schlüssel statt Text. Das Frontend übersetzt
-- die beiden Schlüssel (pruefenAdmin:gate.*), alle anderen Gate-Texte zeigt es weiter wie geliefert.
-- Text von freigabe_gate_fehler sonst unverändert (Stand 20261005071059, pg_get_functiondef 21.10.2026).

create or replace function public.prozent_gate_fehler(p_unit text, p_acceptance jsonb, p_correct_answers jsonb)
returns text language sql immutable set search_path = public, pg_temp as $$
  -- Nur Aufgaben mit flacher Wertungsregel (acceptance mit canonical) werden geprüft. Ohne Regel wertet lsa_grade
  -- über lsa_is_correct, also über den exakten Vergleich mit correct_answers; der Prozent-Faktor wirkt dort nicht,
  -- und ein Marker ginge nur über eine neue Regel, die den Bewertungsweg ändert. Deshalb sind solche Aufgaben
  -- ausgenommen, auch mit „%“ am Feld (z. B. d350fb95, VERA8, ready). Entscheidung Rasit, 21.10.2026.
  with r as (
    select p_acceptance as acc,
           public.lsa_parse_fraction(p_acceptance ->> 'canonical') as cf,
           lower(coalesce(btrim((public.lsa_split_value_unit(p_acceptance ->> 'canonical'))[2]), '')) as cu
     where jsonb_typeof(p_acceptance) = 'object' and p_acceptance ? 'canonical'
       and (p_acceptance ->> 'unit') is distinct from '%'
  )
  select case
    when btrim(coalesce(p_unit, '')) = '%' then 'prozent_ohne_marker'
    when exists (
      select 1
        from (select x from jsonb_array_elements_text(
                case when jsonb_typeof(p_correct_answers) = 'array' then p_correct_answers else '[]' end) x
              union
              select x from jsonb_array_elements_text(
                case when jsonb_typeof(r.acc -> 'equivalents') = 'array' then r.acc -> 'equivalents' else '[]' end) x) w,
             lateral (select public.lsa_parse_fraction(w.x) as xf,
                             coalesce(btrim((public.lsa_split_value_unit(w.x))[2]), '') as xu) p
       where r.cf is not null and r.cf[1] <> 0 and r.cu in ('', '%', 'prozent')
         and p.xu = '' and p.xf is not null
         and p.xf[1] * r.cf[2] * (case when r.cu in ('%', 'prozent') then 100 else 1 end) = 100 * r.cf[1] * p.xf[2])
      then 'prozentzahl_ohne_zeichen'
  end
  from r
$$;

revoke all on function public.prozent_gate_fehler(text, jsonb, jsonb) from public, anon, authenticated;

create or replace function public.freigabe_gate_fehler(p_task_id uuid)
returns text language plpgsql stable set search_path = public, pg_temp as $$
declare v public.tasks%rowtype; v_prozent text;
begin
  select * into v from public.tasks where id = p_task_id;
  if not found then return null; end if;
  if coalesce(btrim(v.question), '') = '' then return 'task_status_set: Stamm fehlt'; end if;
  if v.input_type is null then return 'task_status_set: input_type fehlt'; end if;
  if v.afb is null then return 'task_status_set: AFB fehlt'; end if;
  if v.cluster_id is null then return 'task_status_set: Cluster fehlt (sonst nie im LSA-Pool)'; end if;
  if v.curriculum_grade is null then return 'task_status_set: Stoffanker (curriculum_grade) fehlt'; end if;
  if not exists (select 1 from public.task_solutions s
                  where s.task_id = p_task_id
                    and public.lsa_has_answers(v.input_type, v.parts, s.correct_answers)) then
    return 'task_status_set: Loesung unvollstaendig';
  end if;
  select public.prozent_gate_fehler(v.unit, s.acceptance, s.correct_answers) into v_prozent
    from public.task_solutions s where s.task_id = p_task_id;
  if v_prozent is not null then return 'task_status_set: ' || v_prozent; end if;
  return null;
end $$;
