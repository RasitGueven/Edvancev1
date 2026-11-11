-- Rollback zu 20261111191054_sp1_bauform_kommentare: Funktionen, Sicht und Trigger zurück auf den Stand vor SP-1.
-- Tabellen (bauform_stufen, bauform_zeit_aenderungen, bauform_kommentare) und die Spalte bauformen.titel bleiben mit
-- ihrem Inhalt stehen (nichts löschen); ohne die Funktionen schreibt niemand mehr hinein. Den Eintrag in
-- supabase_migrations.schema_migrations NICHT löschen (ein zweites Einspielen scheiterte an den Tabellen).
drop view if exists public.bauform_kommentar_auswertung;
drop trigger if exists bauformen_stufen_anlegen on public.bauformen;
drop function if exists public.bauform_pruefung_senden(uuid, integer, jsonb, jsonb, integer);
drop function if exists public.bauform_rueckfrage_erledigt(uuid, integer);
drop function if exists public.bauform_kommentar_erledigen(uuid, text);
drop function if exists public.bauform_zeit_setzen(uuid, integer, numeric);
drop function if exists public.bauform_zeit_aendern(uuid, integer, numeric, uuid);
drop function if exists public.aufgabe_zeit_sek(uuid);
drop function if exists public.bauform_stufen_anlegen();
drop function if exists public.bauform_pruef_detail(uuid, integer, uuid[]);
drop function if exists public.bauform_pruef_plan(uuid);
revoke insert on public.bauform_kommentare from authenticated;

CREATE OR REPLACE FUNCTION public.bauform_pruef_detail(p_bauform uuid, p_seed integer DEFAULT 0) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
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
       -- nur Instanzen mit Loesungszeile, sonst faellt nach dem limit ein Beispiel still weg (Zweitpruefung A5, 1)
       and exists (select 1 from public.task_solutions s where s.task_id = t.id)
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

CREATE OR REPLACE FUNCTION public.bauform_pruef_plan(p_student_id uuid DEFAULT NULL::uuid) RETURNS TABLE(bauform_id uuid, schluessel text, skill_key text, skill_label text, reihe text, format text, rollen text[], version integer, status text, gruen integer, letzte_entscheidung text, letzte_notiz text, geprueft_am timestamp with time zone, session_nr integer, session_titel text, kernidee_key text, kernidee_titel text, ist_voraussetzung boolean)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_reihe public.reihen;
  v_sess  jsonb;
begin
  if not public.darf_pruefen() then
    raise exception 'bauform_pruef_plan: kein Pruefrecht' using errcode = '42501';
  end if;
  if p_student_id is null then
    v_sess := public.bauform_plan_standard();
  else
    select * into v_reihe from public.reihe_aktiv(p_student_id);
    if v_reihe.id is null then
      raise exception 'bauform_pruef_plan: keine aktive Reihe' using errcode = 'P0002';
    end if;
    select coalesce(jsonb_agg(s order by o) filter (where s ->> 'art' = 'normal'), '[]') into v_sess
      from jsonb_array_elements(public.reihe_plan_wirksam(v_reihe.id) -> 'sessions') with ordinality x(s, o);
  end if;

  return query
  with ki as (
    select (s ->> 'nr')::int as nr, e ->> 'skill_key' as sk, e ->> 'kernidee_key' as kk
      from jsonb_array_elements(v_sess) s, jsonb_array_elements(s -> 'kernideen') e
  ), titel as (
    select x.nr, string_agg(sk.label, ' · ' order by x.ab) as t
      from (select ki.nr, ki.sk, min(rk.nr) as ab
              from ki join public.reihe_kernideen rk on rk.skill_key = ki.sk and rk.kernidee_key = ki.kk
             group by ki.nr, ki.sk) x
      join public.skills sk on sk.skill_key = x.sk
     group by x.nr
  ), zuordnung as (
    select b.id,
           case when b.kernidee_key is not null then
                  (select min(ki.nr) from ki where ki.sk || ':' || ki.kk = b.kernidee_key)
                else
                  (select min(ki.nr) from ki join public.skill_kante k on k.skill_key = ki.sk
                    where k.voraussetzt_skill_key = b.skill_key)
           end as nr
      from public.bauformen b
  )
  select l.bauform_id, l.schluessel, l.skill_key, l.skill_label, l.reihe, l.format, l.rollen, l.version, l.status,
         l.gruen, l.letzte_entscheidung, l.letzte_notiz, l.geprueft_am,
         z.nr, ti.t, b.kernidee_key, rk.titel, b.kernidee_key is null
    from public.bauform_pruef_liste() l
    join public.bauformen b on b.id = l.bauform_id
    join zuordnung z on z.id = b.id
    left join titel ti on ti.nr = z.nr
    left join public.reihe_kernideen rk on rk.skill_key || ':' || rk.kernidee_key = b.kernidee_key
   order by z.nr nulls last, b.kernidee_key is not null, b.schluessel;
end;
$$;

CREATE OR REPLACE FUNCTION public.bauform_versionswechsel() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  new.geaendert_am := now();
  if (new.steckbrief, new.format, new.rollen, new.skill_key, new.kernidee_key)
     is distinct from (old.steckbrief, old.format, old.rollen, old.skill_key, old.kernidee_key) then
    insert into public.bauform_versionen (bauform_id, version, steckbrief, status)
    values (old.id, old.version, old.steckbrief, old.status);
    new.version := old.version + 1;
    if coalesce(current_setting('edvance.bauform_export', true), '') <> '1' then
      new.pruefprotokoll := '{}'::jsonb;
      new.blindloeser := null;
      new.verdacht := null;
      if old.status <> 'entwurf' then
        new.status := 'zur_pruefung';
      end if;
    elsif new.status in ('zur_freigabe', 'freigegeben', 'pausiert', 'beanstandet', 'rueckfrage') then
      new.status := case when new.verdacht is null then 'zur_pruefung' else 'entwurf' end;
    end if;
    new.freigegeben_am := null;
    new.freigegeben_von := null;
  end if;
  return new;
end $$;

drop function if exists public.bauform_rueckfrage_pruefung(uuid);
do $$
declare f text;
begin
  foreach f in array array['bauform_pruef_detail(uuid,integer)', 'bauform_pruef_plan(uuid)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;
