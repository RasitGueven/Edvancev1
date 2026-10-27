-- Reihe 1 · A5 Lena-Board fuer Bauformen (Konzept §6): Lesefunktionen fuer die Pruefansicht, den Reiter „Auffaellig“
-- und die Coach-Pruefgespraeche. Alle nur fuer Lena und Admins (darf_pruefen). Schreiben laeuft ueber die Funktionen
-- aus A2 (bauform_pruefen, bauform_freigeben, aufgabe_reaktivieren, bauform_zur_ueberarbeitung, bauform_reaktivieren)
-- und neu skill_pruefung_entscheiden.
--
--   bauform_pruef_liste()                 → je Bauform Stand, Zahl gruener Instanzen, letzte Entscheidung; Bauformen mit
--                                           Verdacht oder ohne Pruefmaschinen-Lauf stehen nicht drin (Konzept §6)
--   bauform_pruef_detail(p_bauform, p_seed) → Steckbrief, Befund von Pruefmaschine und Blindloeser, sechs Beispiele der
--                                           aktuellen Version (je Stufe mindestens eines) wie auf dem Tablet samt Loesung,
--                                           Fehlbildern, Hinweisen; ein anderer p_seed zieht andere Beispiele
--   bauform_auffaellig()                  → pausierte/auffaellige Instanzen mit Meldungen und haeufigsten Antworten
--   skill_pruefung_liste(), skill_pruefung_entscheiden(p_id, p_entscheidung, p_notiz)   Coach-Pruefgespraeche

create function public.bauform_pruef_liste()
returns table (bauform_id uuid, schluessel text, skill_key text, skill_label text, reihe text, format text, rollen text[],
               version int, status text, gruen int, letzte_entscheidung text, letzte_notiz text, geprueft_am timestamptz)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.darf_pruefen() then
    raise exception 'bauform_pruef_liste: kein Pruefrecht' using errcode = '42501';
  end if;
  return query
  select b.id, b.schluessel, b.skill_key, s.label, b.reihe, b.format, b.rollen, b.version, b.status,
         (select count(*)::int from public.tasks t where t.bauform_id = b.id and t.bauform_version = b.version
             and public.instanz_gruen(t.pruefmaschine)),
         p.entscheidung, p.notiz, p.geprueft_am
    from public.bauformen b
    join public.skills s on s.skill_key = b.skill_key
    left join lateral (select x.entscheidung, x.notiz, x.geprueft_am from public.bauform_pruefungen x
                        where x.bauform_id = b.id and x.version = b.version order by x.geprueft_am desc limit 1) p on true
   where b.verdacht is null and b.pruefprotokoll ? 'lauf_am'
   order by case b.status when 'zur_pruefung' then 0 when 'rueckfrage' then 1 when 'zur_freigabe' then 2
                          when 'pausiert' then 3 when 'beanstandet' then 4 else 5 end, b.schluessel;
end $$;

create function public.bauform_pruef_detail(p_bauform uuid, p_seed int default 0)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  b public.bauformen;
  v_beispiele jsonb;
begin
  if not public.darf_pruefen() then
    raise exception 'bauform_pruef_detail: kein Pruefrecht' using errcode = '42501';
  end if;
  select * into b from public.bauformen where id = p_bauform;
  if not found then
    raise exception 'bauform_pruef_detail: Bauform nicht gefunden' using errcode = 'P0002';
  end if;
  -- Sechs Beispiele: zuerst je Stufe eines, dann auffuellen; die Reihenfolge streut ueber p_seed.
  with kand as (
    select t.id, t.stufe, t.rolle,
           row_number() over (partition by t.stufe order by md5(p_seed::text || t.id::text)) as je_stufe,
           md5(p_seed::text || t.id::text) as zufall
      from public.tasks t
     where t.bauform_id = b.id and t.bauform_version = b.version and public.instanz_gruen(t.pruefmaschine)
  ), wahl as (
    select k.* from kand k order by (k.je_stufe > 1), k.zufall limit 6
  )
  select coalesce(jsonb_agg(jsonb_build_object(
           'task_id', w.id, 'stufe', w.stufe, 'rolle', w.rolle,
           'payload', public.aufgabe_payload(w.id),
           'loesung', s.correct_answers -> 0,
           'known_errors', s.acceptance -> 'known_errors',
           'loesungsweg', s.solution,
           'hinweise', s.hints)
         order by w.stufe, w.zufall), '[]'::jsonb)
    into v_beispiele
    from wahl w join public.task_solutions s on s.task_id = w.id;
  return jsonb_build_object(
    'bauform_id', b.id, 'schluessel', b.schluessel, 'skill_key', b.skill_key,
    'skill_label', (select label from public.skills where skill_key = b.skill_key),
    'kernidee_key', b.kernidee_key, 'format', b.format, 'rollen', b.rollen, 'version', b.version, 'status', b.status,
    'steckbrief', b.steckbrief, 'pruefprotokoll', b.pruefprotokoll, 'blindloeser', b.blindloeser - 'antworten',
    'verdacht', b.verdacht,
    'fehlbild_texte', (select coalesce(jsonb_object_agg(fl.slug, fl.klartext), '{}'::jsonb) from public.fehlbild_labels fl
                        where fl.slug in (select f ->> 'key' from jsonb_array_elements(
                          case when jsonb_typeof(b.steckbrief -> 'fehlbilder') = 'array' then b.steckbrief -> 'fehlbilder'
                               else '[]'::jsonb end) f)),
    'instanzen', (select count(*) from public.tasks t where t.bauform_id = b.id and t.bauform_version = b.version),
    'beispiele', v_beispiele,
    'pruefungen', (select coalesce(jsonb_agg(jsonb_build_object('version', p.version, 'entscheidung', p.entscheidung,
                     'gruende', p.gruende, 'notiz', p.notiz, 'am', p.geprueft_am) order by p.geprueft_am desc), '[]'::jsonb)
                     from public.bauform_pruefungen p where p.bauform_id = b.id));
end $$;

create function public.bauform_auffaellig()
returns table (task_id uuid, bauform_id uuid, schluessel text, bauform_status text, frage text, stufe int, rolle text,
               status text, grund text, bearbeitungen int, richtig int, haeufigste_unbekannte text, unbekannt jsonb,
               fehlbild_zaehler jsonb, meldungen jsonb)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.darf_pruefen() then
    raise exception 'bauform_auffaellig: kein Pruefrecht' using errcode = '42501';
  end if;
  return query
  select t.id, b.id, b.schluessel, b.status, t.question, t.stufe::int, t.rolle, w.status, w.grund, w.bearbeitungen,
         w.richtig, w.haeufigste_unbekannte, w.unbekannt, w.fehlbild_zaehler,
         (select coalesce(jsonb_agg(jsonb_build_object('grund', m.grund, 'am', m.am,
                    'von', (select pr.full_name from public.profiles pr where pr.id = m.von)) order by m.am desc), '[]'::jsonb)
            from public.aufgabe_meldungen m where m.task_id = t.id)
    from public.aufgabe_bewaehrung w
    join public.tasks t on t.id = w.task_id
    left join public.bauformen b on b.id = t.bauform_id
   where w.status in ('auffaellig', 'pausiert')
   order by w.geaendert_am desc;
end $$;

create function public.skill_pruefung_liste()
returns table (id uuid, skill_key text, skill_label text, frage text, erwartung text, kriterium text, status text,
               geprueft_von text, geprueft_am timestamptz, pruef_notiz text)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.darf_pruefen() then
    raise exception 'skill_pruefung_liste: kein Pruefrecht' using errcode = '42501';
  end if;
  return query
  select p.id, p.skill_key, s.label, p.frage, p.erwartung, p.kriterium, p.status,
         (select pr.full_name from public.profiles pr where pr.id = p.geprueft_von), p.geprueft_am, p.pruef_notiz
    from public.skill_pruefung p join public.skills s on s.skill_key = p.skill_key
   order by (p.status = 'entwurf') desc, p.skill_key, p.angelegt;
end $$;

-- Lena prueft eine Pruefgespraechsfrage einzeln: passt → geprueft (ein Admin gibt sie frei wie bisher),
-- passt_nicht → bleibt entwurf, Lenas Notiz steht in skill_pruefung.pruef_notiz (Grundlage der Ueberarbeitung).
alter table public.skill_pruefung add column pruef_notiz text;

create function public.skill_pruefung_entscheiden(p_id uuid, p_entscheidung text, p_notiz text default null)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_status text;
begin
  if not public.darf_pruefen() then
    raise exception 'skill_pruefung_entscheiden: kein Pruefrecht' using errcode = '42501';
  end if;
  if p_entscheidung not in ('passt', 'passt_nicht') then
    raise exception 'skill_pruefung_entscheiden: passt oder passt_nicht' using errcode = '22023';
  end if;
  if p_entscheidung = 'passt_nicht' and coalesce(btrim(p_notiz), '') = '' then
    raise exception 'skill_pruefung_entscheiden: passt nicht braucht eine Notiz' using errcode = '22023';
  end if;
  update public.skill_pruefung
     set status = case when p_entscheidung = 'passt' then 'geprueft' else 'entwurf' end,
         geprueft_von = auth.uid(), geprueft_am = now(), aktualisiert = now(), pruef_notiz = nullif(btrim(p_notiz), '')
   where id = p_id and status <> 'freigegeben'
  returning status into v_status;
  if v_status is null then
    raise exception 'skill_pruefung_entscheiden: Frage nicht gefunden oder schon freigegeben' using errcode = 'P0002';
  end if;
  return v_status;
end $$;

do $$
declare f text;
begin
  foreach f in array array['bauform_pruef_liste()', 'bauform_pruef_detail(uuid,int)', 'bauform_auffaellig()',
                           'skill_pruefung_liste()', 'skill_pruefung_entscheiden(uuid,text,text)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
    execute format('comment on function public.%s is %L', f, 'reihe1 fertig');
  end loop;
end $$;
