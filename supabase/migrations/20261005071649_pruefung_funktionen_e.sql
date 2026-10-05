-- Lena-Board, Migration 2e: Admin-Seite (Entscheidungen 21, 22, 39 bis 42)

-- ── 21 · Rueckfrage klaeren (nur admin) ─────────────────────────────────────
-- freigeben: ueber task_status_set('ready'), also durch das Gate (P0001 bei Luecken).
-- zurueckweisen: status beanstandet, je Grund eine task_reviews-Zeile.
-- an_lena: status draft, Ausgangsfassung geloescht (die naechste entsteht beim naechsten Oeffnen).
-- Die Antwort an Lena steht danach in der letzten task_pruefungen-Zeile.
create or replace function public.pruef_rueckfrage_klaeren(
  p_task_id uuid, p_aktion text, p_antwort text, p_gruende text[] default null)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  t public.tasks; v_id uuid; g text;
  gruende text[] := array(select distinct btrim(x) from unnest(coalesce(p_gruende, '{}')) x where btrim(x) <> '');
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'pruef_rueckfrage_klaeren: nur admin' using errcode = '42501';
  end if;
  if p_aktion is null or p_aktion not in ('freigeben', 'zurueckweisen', 'an_lena') then
    raise exception 'pruef_rueckfrage_klaeren: unbekannte Aktion %', p_aktion using errcode = '22023';
  end if;
  select * into t from public.tasks where id = p_task_id for update;
  if not found then
    raise exception 'pruef_rueckfrage_klaeren: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if t.status <> 'rueckfrage' then perform public.pruef_fehler('keine_rueckfrage'); end if;

  if p_aktion = 'freigeben' then
    perform public.task_status_set(p_task_id, 'ready');
  elsif p_aktion = 'zurueckweisen' then
    if cardinality(gruende) = 0 then perform public.pruef_fehler('grund_fehlt'); end if;
    if exists (select 1 from unnest(gruende) x where x not in (
         'aufgabe_fehlerhaft', 'aufgabe_unklar', 'bild_falsch', 'sprache_zu_schwer', 'tablet_umbauen',
         'passt_nicht_in_lsa', 'sonstiges', 'fehlbild_falsch', 'fehlbild_unrealistisch',
         'zahlen_unguenstig', 'formulierung', 'didaktisch', 'kontext', 'loesung_passt_nicht')) then
      perform public.pruef_fehler('grund_unbekannt');
    end if;
    update public.tasks set status = 'beanstandet', reviewed_by = null, reviewed_at = null where id = p_task_id;
    foreach g in array gruende loop
      insert into public.task_reviews (task_id, kategorie, notiz, geprueft_von)
      values (p_task_id, g, nullif(btrim(p_antwort), ''), auth.uid());
    end loop;
  else
    update public.tasks set status = 'draft', reviewed_by = null, reviewed_at = null where id = p_task_id;
    delete from public.task_pruefung_ausgang where task_id = p_task_id;
  end if;

  select p.id into v_id from public.task_pruefungen p where p.task_id = p_task_id
   order by p.geprueft_am desc limit 1;
  if v_id is not null then
    update public.task_pruefungen
       set antwort = nullif(btrim(p_antwort), ''), beantwortet_von = auth.uid(), beantwortet_am = now()
     where id = v_id;
  end if;

  return jsonb_build_object('status', (select x.status from public.tasks x where x.id = p_task_id));
end $$;

-- ── 39/42 · Lenas Ergebnis fuer die Item-Pflege und die Expertenliste ───────
create or replace function public.pruef_admin_liste()
returns table (task_id uuid, lena_status text, ausschluss text, pilot boolean, entscheidung text,
               gruende text[], notiz text, aenderungen jsonb, aenderung_grund text, dauer_sek int,
               geprueft_von text, geprueft_am timestamptz, antwort text, beantwortet_am timestamptz,
               geaendert boolean)
language plpgsql stable security definer set search_path = public, pg_temp as $$
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'pruef_admin_liste: nur admin' using errcode = '42501';
  end if;
  return query
  select t.id, public.pruef_lena_status(t.status), public.pruef_ausschluss(t.id), t.pruef_pilot,
         lp.entscheidung, lp.gruende, lp.notiz, lp.aenderungen, lp.aenderung_grund, lp.dauer_sek,
         pr.full_name, lp.geprueft_am, lp.antwort, lp.beantwortet_am,
         coalesce(jsonb_array_length(lp.aenderungen) > 0, false)
    from public.tasks t
    left join lateral (select p.* from public.task_pruefungen p where p.task_id = t.id
                        order by p.geprueft_am desc limit 1) lp on true
    left join public.profiles pr on pr.id = lp.geprueft_von;
end $$;

-- ── 22 · Sammelfreigaben nur fuer unveraenderte "Passt"-Aufgaben ────────────
-- Letzte Entscheidung "passt" ohne Aenderungen, seitdem nichts geaendert, und kein Admin hat die
-- Aufgabe je beanstandet (Lena darf neu bewerten, eine Admin-Beanstandung ueberstimmt sie damit aber
-- nicht still: solche Aufgaben gibt ein Admin einzeln frei).
create or replace function public.pruef_freigabe_erlaubt(p_task_id uuid)
returns boolean language sql stable set search_path = public, pg_temp as $$
  select coalesce((select p.entscheidung = 'passt' and p.aenderungen = '[]'::jsonb
                     from public.task_pruefungen p where p.task_id = t.id
                    order by p.geprueft_am desc limit 1), false)
     and not exists (select 1 from public.task_reviews r
                      left join public.profiles pr on pr.id = r.geprueft_von
                     where r.task_id = t.id and (r.geprueft_von is null or pr.role = 'admin'))
     and (a.task_id is null
          or public.pruef_aenderungen(public.pruef_sicht(t, a.ausgang),
                                      public.pruef_sicht(t, public.pruef_fassung(t.id))) = '[]'::jsonb)
    from public.tasks t left join public.task_pruefung_ausgang a on a.task_id = t.id
   where t.id = p_task_id
$$;

create or replace function public.freigabe_thema(p_thema_key text, p_klasse integer)
returns integer language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_id uuid;
  v_n  integer := 0;
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'freigabe_thema: nur admin darf freigeben' using errcode = '42501';
  end if;
  for v_id in
    select t.id
      from public.tasks t
      join public.skill_thema st on st.skill_key = t.skill_key
     where st.thema_key = p_thema_key
       and t.status = 'review'
       and t.source is distinct from 'VERA8_IQB'
       and (t.class_level is null or t.class_level <= p_klasse)
       and public.pruef_freigabe_erlaubt(t.id)
  loop
    begin
      perform public.task_status_set(v_id, 'ready');
      v_n := v_n + 1;
    exception
      when sqlstate 'P0001' then null;
    end;
  end loop;
  return v_n;
end $$;

create or replace function public.freigabe_cluster(p_cluster_id uuid)
returns integer language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_id uuid;
  v_n  integer := 0;
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'freigabe_cluster: nur admin darf freigeben' using errcode = '42501';
  end if;
  for v_id in
    select id from public.tasks
     where cluster_id = p_cluster_id and status = 'review'
       and source is distinct from 'VERA8_IQB'
       and public.pruef_freigabe_erlaubt(id)
  loop
    begin
      perform public.task_status_set(v_id, 'ready');
      v_n := v_n + 1;
    exception
      when sqlstate 'P0001' then null;
    end;
  end loop;
  return v_n;
end $$;

-- freigabe_muster nimmt draft: nur Aufgaben, zu denen es noch keine Lena-Entscheidung gibt.
-- Admin-Werkzeug ausserhalb von Lenas Ablauf.
create or replace function public.freigabe_muster(p_skill_key text, p_task_ids uuid[] default null)
returns integer language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_id uuid;
  v_n  integer := 0;
begin
  -- `is distinct from` statt `<>`: get_my_role() ist NULL fuer einen nicht angemeldeten Aufrufer.
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'A21: nur die fachliche Freigabe (admin) darf freigeben' using errcode = '42501';
  end if;
  for v_id in
    select t.id from public.tasks t
     where t.skill_key = p_skill_key
       and t.status = 'draft'
       and (p_task_ids is null or t.id = any (p_task_ids))
       and not exists (select 1 from public.task_pruefungen p where p.task_id = t.id)
  loop
    begin
      perform public.task_status_set(v_id, 'ready');
      v_n := v_n + 1;
    exception
      -- P0001 = Pflichtfeld oder Loesung unvollstaendig (task_status_set-Gate).
      when sqlstate 'P0001' then null;
    end;
  end loop;
  return v_n;
end $$;

revoke all on function public.pruef_freigabe_erlaubt(uuid) from public, anon, authenticated;
revoke all on function public.pruef_rueckfrage_klaeren(uuid, text, text, text[]),
  public.pruef_admin_liste() from public, anon, authenticated;
grant execute on function public.pruef_rueckfrage_klaeren(uuid, text, text, text[]),
  public.pruef_admin_liste() to authenticated;
