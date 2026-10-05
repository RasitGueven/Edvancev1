-- Admin-Pruefansicht, Migration 2a: admin_pruefen_funktionen (Bauauftrag G3 bis G6)
--
-- Einzelaktionen der Admin-Pruefansicht. Jede schreibt eine Zeile ins Admin-Protokoll.
--   G3  pruef_an_lena(task, nachricht)             Zurueck an Lena, fuer alle Status ausser ready.
--   G4  pruef_admin_freigeben(task)                ready ueber task_status_set (Gate, Stempel).
--       pruef_freigabe_zuruecknehmen(task)         ready -> draft.
--   G5  pruef_admin_zurueckweisen(task, gruende, notiz)  beanstandet, je Grund eine task_reviews-Zeile.
--   G6  pruef_rueckfrage_klaeren schreibt zusaetzlich Protokoll (rueckfrage_*). Signatur und Verhalten bleiben.
-- Interne Bausteine (kein Grant): pruef_nur_admin, pruef_protokoll, pruef_admin_gruende, pruef_lena_bewertet,
-- pruef_an_lena_schreiben. Sie laufen nur innerhalb der Definer-Funktionen dieser Migration und von 2b.
-- Muster 20261004001333_lead_thema_setzen: SECURITY DEFINER, search_path = public, pg_temp, Grant nur an
-- authenticated. Zugang nur fuer get_my_role() = 'admin', sonst 42501. Eingabefehler: ED422 mit HINT.

-- ── Bausteine ────────────────────────────────────────────────────────────────
create or replace function public.pruef_nur_admin(p_fn text)
returns void language plpgsql set search_path = public, pg_temp as $$
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception '%: nur admin', p_fn using errcode = '42501';
  end if;
end $$;

-- clock_timestamp(): mehrere Aktionen in einer Transaktion behalten ihre Reihenfolge (Lena-Board, Retro).
create or replace function public.pruef_protokoll(
  p_task_id uuid, p_aktion text, p_aenderungen jsonb, p_grund text, p_sammel boolean)
returns void language plpgsql set search_path = public, pg_temp as $$
begin
  insert into public.task_admin_protokoll (task_id, aktion, aenderungen, grund, sammel, von, am)
  values (p_task_id, p_aktion, coalesce(p_aenderungen, '[]'), nullif(btrim(p_grund), ''),
          coalesce(p_sammel, false), auth.uid(), clock_timestamp());
end $$;

-- Gruende fuer Zurueckweisen (task_reviews.kategorie): Lenas sieben und die bisherigen sieben.
create or replace function public.pruef_admin_gruende()
returns text[] language sql immutable as $$
  select array['aufgabe_fehlerhaft', 'aufgabe_unklar', 'bild_falsch', 'sprache_zu_schwer', 'tablet_umbauen',
               'passt_nicht_in_lsa', 'sonstiges', 'fehlbild_falsch', 'fehlbild_unrealistisch',
               'zahlen_unguenstig', 'formulierung', 'didaktisch', 'kontext', 'loesung_passt_nicht']
$$;

-- Hat Lena seit dem letzten "Zurueck an Lena" entschieden? Ihr eigenes Rueckgaengig zaehlt nicht.
create or replace function public.pruef_lena_bewertet(p_task_id uuid)
returns boolean language sql stable set search_path = public, pg_temp as $$
  select coalesce((
    select p.entscheidung <> 'zurueckgenommen'
       and p.geprueft_am > coalesce((select max(x.am) from public.task_admin_protokoll x
                                      where x.task_id = p_task_id
                                        and x.aktion in ('an_lena', 'rueckfrage_an_lena')), '-infinity')
      from public.task_pruefungen p where p.task_id = p_task_id
     order by p.geprueft_am desc limit 1), false)
$$;

-- Die Wirkung von "Zurueck an Lena": draft, Stempel leer, Ausgangsfassung weg; die Nachricht geht als
-- "Antwort vom Team" an Lenas juengste Entscheidung, wenn es eine gibt. Beim naechsten Oeffnen durch Lena
-- wird der jetzige Stand die neue Ausgangsfassung (keine "geaendert"-Marken fuer Aenderungen des Teams).
create or replace function public.pruef_an_lena_schreiben(
  p_task_id uuid, p_nachricht text, p_grund text, p_sammel boolean)
returns void language plpgsql set search_path = public, pg_temp as $$
declare v_id uuid; n text := nullif(btrim(p_nachricht), '');
begin
  update public.tasks set status = 'draft', reviewed_by = null, reviewed_at = null where id = p_task_id;
  delete from public.task_pruefung_ausgang where task_id = p_task_id;
  if n is not null then
    select p.id into v_id from public.task_pruefungen p where p.task_id = p_task_id
     order by p.geprueft_am desc limit 1;
    if v_id is not null then
      update public.task_pruefungen
         set antwort = n, beantwortet_von = auth.uid(), beantwortet_am = now()
       where id = v_id;
    end if;
  end if;
  perform public.pruef_protokoll(p_task_id, 'an_lena', '[]', coalesce(nullif(btrim(p_grund), ''), n), p_sammel);
end $$;

-- ── G3 · Zurueck an Lena ─────────────────────────────────────────────────────
-- Bei einer Rueckfrage ruft das Frontend weiter pruef_rueckfrage_klaeren (G6).
create or replace function public.pruef_an_lena(p_task_id uuid, p_nachricht text default null)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare t public.tasks;
begin
  perform public.pruef_nur_admin('pruef_an_lena');
  select * into t from public.tasks where id = p_task_id for update;
  if not found then
    raise exception 'pruef_an_lena: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if t.status = 'ready' then perform public.pruef_fehler('freigegeben'); end if;
  perform public.pruef_an_lena_schreiben(p_task_id, p_nachricht, null, false);
  return jsonb_build_object('status', 'draft');
end $$;

-- ── G4 · Freigeben und Freigabe zuruecknehmen ────────────────────────────────
-- task_status_set prueft das Gate (P0001) und lehnt beanstandet ab (ED422 erst_an_lena).
create or replace function public.pruef_admin_freigeben(p_task_id uuid)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare t public.tasks;
begin
  perform public.pruef_nur_admin('pruef_admin_freigeben');
  select * into t from public.tasks where id = p_task_id for update;
  if not found then
    raise exception 'pruef_admin_freigeben: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if t.status = 'ready' then perform public.pruef_fehler('freigegeben'); end if;
  perform public.task_status_set(p_task_id, 'ready');
  perform public.pruef_protokoll(p_task_id, 'freigeben', '[]', null, false);
  return jsonb_build_object('status', 'ready');
end $$;

create or replace function public.pruef_freigabe_zuruecknehmen(p_task_id uuid)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare t public.tasks;
begin
  perform public.pruef_nur_admin('pruef_freigabe_zuruecknehmen');
  select * into t from public.tasks where id = p_task_id for update;
  if not found then
    raise exception 'pruef_freigabe_zuruecknehmen: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if t.status <> 'ready' then perform public.pruef_fehler('nicht_freigegeben'); end if;
  perform public.task_status_set(p_task_id, 'draft');
  perform public.pruef_protokoll(p_task_id, 'freigabe_zurueck', '[]', null, false);
  return jsonb_build_object('status', 'draft');
end $$;

-- ── G5 · Zurueckweisen (ausserhalb der Rueckfrage) ──────────────────────────
create or replace function public.pruef_admin_zurueckweisen(
  p_task_id uuid, p_gruende text[], p_notiz text default null)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  t public.tasks; g text;
  notiz text := nullif(btrim(p_notiz), '');
  gruende text[] := array(select distinct btrim(x) from unnest(coalesce(p_gruende, '{}')) x where btrim(x) <> '');
begin
  perform public.pruef_nur_admin('pruef_admin_zurueckweisen');
  select * into t from public.tasks where id = p_task_id for update;
  if not found then
    raise exception 'pruef_admin_zurueckweisen: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if t.status = 'ready' then perform public.pruef_fehler('freigegeben'); end if;
  if cardinality(gruende) = 0 then perform public.pruef_fehler('grund_fehlt'); end if;
  if not gruende <@ public.pruef_admin_gruende() then perform public.pruef_fehler('grund_unbekannt'); end if;
  update public.tasks set status = 'beanstandet', reviewed_by = null, reviewed_at = null where id = p_task_id;
  foreach g in array gruende loop
    insert into public.task_reviews (task_id, kategorie, notiz, geprueft_von, geprueft_am)
    values (p_task_id, g, notiz, auth.uid(), clock_timestamp());
  end loop;
  perform public.pruef_protokoll(p_task_id, 'zurueckweisen', '[]', notiz, false);
  return jsonb_build_object('status', 'beanstandet');
end $$;

-- ── G6 · Rueckfrage klaeren, jetzt mit Protokoll ────────────────────────────
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
    if not gruende <@ public.pruef_admin_gruende() then perform public.pruef_fehler('grund_unbekannt'); end if;
    update public.tasks set status = 'beanstandet', reviewed_by = null, reviewed_at = null where id = p_task_id;
    foreach g in array gruende loop
      insert into public.task_reviews (task_id, kategorie, notiz, geprueft_von, geprueft_am)
      values (p_task_id, g, nullif(btrim(p_antwort), ''), auth.uid(), clock_timestamp());
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
  perform public.pruef_protokoll(p_task_id, 'rueckfrage_' || p_aktion, '[]', p_antwort, false);

  return jsonb_build_object('status', (select x.status from public.tasks x where x.id = p_task_id));
end $$;

revoke all on function public.pruef_nur_admin(text), public.pruef_protokoll(uuid, text, jsonb, text, boolean),
  public.pruef_admin_gruende(), public.pruef_lena_bewertet(uuid),
  public.pruef_an_lena_schreiben(uuid, text, text, boolean)
  from public, anon, authenticated;
revoke all on function public.pruef_an_lena(uuid, text), public.pruef_admin_freigeben(uuid),
  public.pruef_freigabe_zuruecknehmen(uuid), public.pruef_admin_zurueckweisen(uuid, text[], text),
  public.pruef_rueckfrage_klaeren(uuid, text, text, text[])
  from public, anon, authenticated;
grant execute on function public.pruef_an_lena(uuid, text), public.pruef_admin_freigeben(uuid),
  public.pruef_freigabe_zuruecknehmen(uuid), public.pruef_admin_zurueckweisen(uuid, text[], text),
  public.pruef_rueckfrage_klaeren(uuid, text, text, text[])
  to authenticated;
