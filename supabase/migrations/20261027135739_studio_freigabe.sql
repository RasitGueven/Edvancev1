-- Reihe 1 · Bauauftrag B5: Prüfung und Freigabe (Anforderung Studio §2, §3, §8).
--
-- studio_freigabe ist das Protokoll (append-only): verständlich (Gründer), fachlich (Lena/Rasit), variante je Welt
-- (Lena). Jede Zeile trägt die Version, auf die sie sich bezieht (Skelett bzw. Welt). Gültig ist eine Freigabe nur,
-- solange die letzte Zeile ihrer Art „passt“ sagt und die Version noch aktuell ist — jede Änderung setzt sie damit
-- von selbst zurück. Prüfer ≠ Autor steht als Trigger in der Datenbank.
--
-- Kinder lesen nur studio_ausgabe: der eingefrorene Stand einer freigegebenen Welt (Render, Kapitel, Bereiche,
-- Mini-Checks mit Rücksprüngen). Sie wird erst ersetzt, wenn die geänderte Fassung wieder freigegeben ist; bis
-- dahin sehen Kinder die alte. Mit der Freigabe des Skeletts werden die Mini-Check-Aufgaben 'ready'.
-- Eine Welt ohne eigene Freigabe zeigt das Skelett (B6).
--
-- Jede Prüfung trägt den Inhalts-Fingerabdruck ihrer Welt (studio_render_fingerabdruck: Renderer, Skelett, Welt,
-- Audio). Sie gilt nur, solange er gleich ist: eine Varianten-Freigabe fällt also auch bei einer Skelett-Änderung,
-- die fachliche bei neuer Stimme. Prüfer ist nie, wer die Sequenz geschrieben oder bearbeitet hat
-- (studio_bearbeiter), und verständlich und fachlich kommen von zwei Personen. Fachlich und verständlich prüfen
-- nur ausdrücklich eingetragene Personen (studio_rolle), nicht jeder Admin oder Prüfer.
-- Die Mini-Check-Aufgaben (tasks gehört Auftrag A) setzt die Skelett-Freigabe nur von 'draft' auf 'ready';
-- beanstandete bleiben, wie sie sind (siehe docs/reihe1/B/an-A.md).
--
-- Rollback: supabase/rollback/20261027135739_studio_freigabe.sql.

create table public.studio_freigabe (
  id         bigint generated always as identity primary key,
  sequenz_id uuid not null references public.studio_sequenz (id) on delete cascade,
  art        text not null check (art in ('verstaendlich', 'fachlich', 'variante')),
  welt       text not null default 'skelett' check (welt in ('skelett', 'fussball', 'gaming', 'musik')),
  person_id  uuid not null references public.profiles (id),
  ergebnis   text not null check (ergebnis in ('passt', 'passt_nicht')),
  beat_key   text,
  kommentar  text,
  version    bigint not null,
  fingerabdruck text not null,
  at         timestamptz not null default clock_timestamp(),
  check ((art = 'variante') = (welt <> 'skelett')),
  check (ergebnis = 'passt' or (beat_key is not null and btrim(coalesce(kommentar, '')) <> ''))
);
create index studio_freigabe_idx on public.studio_freigabe (sequenz_id, art, welt, id desc);

-- Wer eine Sequenz außer dem Autor bearbeitet hat (z. B. ein Admin); er prüft sie ebenfalls nicht.
create table public.studio_bearbeiter (
  sequenz_id uuid not null references public.studio_sequenz (id) on delete cascade,
  person_id  uuid not null references public.profiles (id),
  primary key (sequenz_id, person_id)
);
alter table public.studio_bearbeiter enable row level security;
revoke all on public.studio_bearbeiter from public, anon, authenticated;

create function public.studio_bearbeiter_merken() returns trigger
language plpgsql security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is not null and auth.uid() <> new.autor_id then
    insert into public.studio_bearbeiter (sequenz_id, person_id) values (new.id, auth.uid()) on conflict do nothing;
  end if;
  return new;
end;
$$;
create trigger studio_bearbeiter_merken after update of skript on public.studio_sequenz
  for each row execute function public.studio_bearbeiter_merken();

-- Fachlich und verständlich nur noch ausdrücklich (Anforderung §2: Gründer; Lena, Rasit als Vertretung).
create or replace function public.studio_hat_rolle(p_rolle text) returns boolean
language sql stable security definer
set search_path = public, pg_temp
as $$
  select (p_rolle = 'autor' and coalesce(public.get_my_role() = 'admin', false))
      or exists (select 1 from public.studio_rolle r where r.person_id = auth.uid() and r.rolle = p_rolle)
$$;

create table public.studio_ausgabe (
  sequenz_id        uuid not null references public.studio_sequenz (id) on delete cascade,
  welt              text not null check (welt in ('skelett', 'fussball', 'gaming', 'musik')),
  render_id         uuid not null references public.studio_render (id),
  version_skelett   bigint not null,
  version_welt      bigint not null,
  inhalt            jsonb not null,
  freigegeben_am    timestamptz not null default now(),
  zurueckgezogen_am timestamptz,
  primary key (sequenz_id, welt)
);

alter table public.studio_freigabe enable row level security;
alter table public.studio_ausgabe enable row level security;
revoke all on public.studio_freigabe, public.studio_ausgabe from public, anon, authenticated;
grant select on public.studio_freigabe, public.studio_ausgabe to authenticated;
create policy studio_freigabe_lesen on public.studio_freigabe for select to authenticated using (public.studio_darf_sehen());
create policy studio_ausgabe_lesen on public.studio_ausgabe for select to authenticated using (public.studio_darf_sehen());

create function public.studio_freigabe_regeln() returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'DELETE' and pg_trigger_depth() > 1 then
    return old;  -- Sequenz wird gelöscht (Kaskade)
  end if;
  if tg_op <> 'INSERT' then
    raise exception 'studio_freigabe ist append-only' using errcode = '42501';
  end if;
  if exists (select 1 from public.studio_sequenz s where s.id = new.sequenz_id and s.autor_id = new.person_id)
     or exists (select 1 from public.studio_bearbeiter b where b.sequenz_id = new.sequenz_id and b.person_id = new.person_id) then
    raise exception 'studio: der Autor prüft seine eigene Sequenz nicht' using errcode = '42501', hint = 'pruefer_ist_autor';
  end if;
  if new.art in ('verstaendlich', 'fachlich') and new.ergebnis = 'passt' and exists (
       select 1 from public.studio_freigabe f
        where f.sequenz_id = new.sequenz_id and f.art <> new.art and f.art in ('verstaendlich', 'fachlich')
          and f.person_id = new.person_id and f.ergebnis = 'passt' and f.fingerabdruck = new.fingerabdruck) then
    raise exception 'studio: verständlich und fachlich prüfen zwei verschiedene Personen' using errcode = '42501',
      hint = 'vier_augen';
  end if;
  return new;
end;
$$;
create trigger studio_freigabe_regeln before insert or update or delete on public.studio_freigabe
  for each row execute function public.studio_freigabe_regeln();

create function public.studio_version(p_sequenz_id uuid, p_welt text) returns bigint
language sql stable security definer
set search_path = public, pg_temp
as $$
  select case when p_welt = 'skelett' then (select version from public.studio_sequenz where id = p_sequenz_id)
              else (select version from public.studio_welt where sequenz_id = p_sequenz_id and welt = p_welt) end
$$;

create function public.studio_freigabe_gueltig(p_sequenz_id uuid, p_art text, p_welt text) returns boolean
language sql stable security definer
set search_path = public, pg_temp
as $$
  select coalesce((select f.ergebnis = 'passt' and f.version = public.studio_version(p_sequenz_id, p_welt)
                          and f.fingerabdruck = public.studio_render_fingerabdruck(p_sequenz_id, p_welt)
                     from public.studio_freigabe f
                    where f.sequenz_id = p_sequenz_id and f.art = p_art and f.welt = p_welt
                    order by f.id desc limit 1), false)
$$;

-- Was für die Ausgabe einer Welt noch fehlt (leer = freigabefähig).
create function public.studio_ausgabe_fehlt(p_sequenz_id uuid, p_welt text) returns text[]
language sql stable security definer
set search_path = public, pg_temp
as $$
  select array_remove(array[
    case when not public.studio_freigabe_gueltig(p_sequenz_id, 'verstaendlich', 'skelett') then 'verstaendlich' end,
    case when not public.studio_freigabe_gueltig(p_sequenz_id, 'fachlich', 'skelett') then 'fachlich' end,
    case when p_welt <> 'skelett' and not public.studio_freigabe_gueltig(p_sequenz_id, 'variante', p_welt) then 'variante' end,
    case when coalesce((select w.gesperrt from public.studio_welt w where w.sequenz_id = p_sequenz_id and w.welt = p_welt), true)
         then 'welt_gesperrt' end,
    case when exists (select 1 from public.studio_stimme_bedarf(p_sequenz_id) b
                       where b.welt = p_welt and (not b.vorhanden or b.platzhalter)) then 'stimme' end,
    case when not coalesce((select s.aktuell from public.studio_render_stand(p_sequenz_id) s where s.welt = p_welt), false)
         then 'render' end
  ], null)
$$;

-- Eingefrorener Inhalt einer Welt für die Ausspielung (B6): Render, Kapitel, Bereiche, Mini-Checks.
create function public.studio_ausgabe_inhalt(p_sequenz_id uuid, p_welt text, p_render public.studio_render) returns jsonb
language sql stable security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    'titel', s.titel, 'skill_key', s.skill_key, 'welt', p_welt,
    'mp4', p_render.mp4, 'untertitel', p_render.untertitel, 'poster', p_render.poster, 'kapitel', p_render.kapitel,
    'dauer_ms', p_render.dauer_ms,
    'bereiche', (select coalesce(jsonb_agg(jsonb_build_object('kernidee_id', r.kernidee_id, 'skill_key', k.skill_key,
                                   'nr', k.nr, 'von', r.von_beat, 'bis', r.bis_beat) order by k.skill_key, k.nr), '[]')
                   from public.studio_bereich r join public.erklaer_kernidee k on k.id = r.kernidee_id
                  where r.sequenz_id = p_sequenz_id),
    'minichecks', (select coalesce(jsonb_agg(jsonb_build_object(
                      'nach_beat', nb.beat_key, 'kernidee_id', m.kernidee_id,
                      'aufgaben', (select jsonb_agg(jsonb_build_object('nr', a.nr, 'task_id', a.task_id,
                                                      'frage', coalesce(a.frage ->> p_welt, a.frage ->> 'skelett'),
                                                      'optionen', a.optionen) order by a.nr)
                                     from public.studio_minicheck_aufgabe a where a.minicheck_id = m.id),
                      'ruecksprung', (select coalesce(jsonb_object_agg(r.fehlbild_key,
                                         jsonb_build_object('beat', rb.beat_key, 'rueckmeldung', r.rueckmeldung)), '{}')
                                        from public.studio_ruecksprung r join public.studio_beat rb on rb.id = r.beat_id
                                       where r.minicheck_id = m.id)) order by m.pos), '[]')
                     from public.studio_minicheck m join public.studio_beat nb on nb.id = m.nach_beat_id
                    where m.sequenz_id = p_sequenz_id))
    from public.studio_sequenz s where s.id = p_sequenz_id
$$;

-- Ausgabe aktualisieren: jede freigabefähige Welt (Skelett zuerst) bekommt den aktuellen Stand.
create function public.studio_veroeffentlichen(p_sequenz_id uuid) returns text[]
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  w      record;
  v_r    public.studio_render;
  v_neu  text[] := '{}';
  v_status text;
begin
  -- Gegen gleichzeitiges Speichern: der Stand der Sequenz bleibt während der Ausgabe fest.
  select status into v_status from public.studio_sequenz where id = p_sequenz_id for update;
  -- Entfernte Welten verschwinden aus der Ausgabe.
  update public.studio_ausgabe a set zurueckgezogen_am = now()
   where a.sequenz_id = p_sequenz_id and a.zurueckgezogen_am is null
     and not exists (select 1 from public.studio_welt sw where sw.sequenz_id = p_sequenz_id and sw.welt = a.welt);
  if v_status not in ('in_pruefung', 'freigegeben') then
    return v_neu;
  end if;
  for w in select sw.welt from public.studio_welt sw where sw.sequenz_id = p_sequenz_id
            order by sw.welt = 'skelett' desc, sw.welt loop
    continue when cardinality(public.studio_ausgabe_fehlt(p_sequenz_id, w.welt)) > 0;
    continue when w.welt <> 'skelett' and not exists (select 1 from public.studio_ausgabe a where a.sequenz_id = p_sequenz_id
                     and a.welt = 'skelett' and a.zurueckgezogen_am is null
                     and a.version_skelett = public.studio_version(p_sequenz_id, 'skelett'));
    select r.* into v_r from public.studio_render r
     where r.sequenz_id = p_sequenz_id and r.welt = w.welt and r.status = 'fertig'
     order by r.fertig_am desc limit 1;
    continue when exists (select 1 from public.studio_ausgabe a where a.sequenz_id = p_sequenz_id and a.welt = w.welt
                            and a.render_id = v_r.id and a.zurueckgezogen_am is null);
    insert into public.studio_ausgabe as a (sequenz_id, welt, render_id, version_skelett, version_welt, inhalt)
    values (p_sequenz_id, w.welt, v_r.id, public.studio_version(p_sequenz_id, 'skelett'),
            public.studio_version(p_sequenz_id, w.welt), public.studio_ausgabe_inhalt(p_sequenz_id, w.welt, v_r))
    on conflict (sequenz_id, welt) do update
      set render_id = excluded.render_id, version_skelett = excluded.version_skelett,
          version_welt = excluded.version_welt, inhalt = excluded.inhalt, freigegeben_am = now(), zurueckgezogen_am = null;
    v_neu := v_neu || w.welt;
    if w.welt = 'skelett' then
      update public.studio_sequenz set status = 'freigegeben' where id = p_sequenz_id;
      -- Die fachliche Freigabe deckt die Mini-Checks ab (Anforderung §8): ihre Aufgaben werden 'ready'.
      update public.tasks t set status = 'ready', reviewed_at = now()
        from public.studio_minicheck_aufgabe a join public.studio_minicheck m on m.id = a.minicheck_id
       where m.sequenz_id = p_sequenz_id and t.id = a.task_id and t.status = 'draft';
    end if;
  end loop;
  return v_neu;
end;
$$;

create function public.studio_einreichen(p_sequenz_id uuid) returns void
language plpgsql security definer
set search_path = public, pg_temp
as $$
begin
  if not exists (select 1 from public.studio_sequenz s where s.id = p_sequenz_id
                  and (s.autor_id = auth.uid() or coalesce(public.get_my_role(), '') = 'admin')) then
    raise exception 'studio_einreichen: nur der Autor oder ein Admin' using errcode = '42501';
  end if;
  update public.studio_sequenz set status = 'in_pruefung'
   where id = p_sequenz_id and status in ('entwurf', 'vertont', 'gerendert');
  if not found then
    raise exception 'studio_einreichen: Sequenz ist schon in Prüfung oder freigegeben' using errcode = '22023';
  end if;
end;
$$;

-- Eine Prüfung eintragen. „passt nicht“ bzw. eine Anmerkung (verständlich, fachlich) geht an den Autor zurück.
create function public.studio_pruefen(p_sequenz_id uuid, p_art text, p_welt text, p_ergebnis text,
                                      p_beat_key text default null, p_kommentar text default null) returns text[]
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_s public.studio_sequenz;
begin
  if not public.studio_hat_rolle(case when p_art = 'verstaendlich' then 'gruender' else 'fachlich' end) then
    raise exception 'studio_pruefen: keine Prüfrolle für %', p_art using errcode = '42501';
  end if;
  select * into v_s from public.studio_sequenz where id = p_sequenz_id for update;
  -- Varianten-Texte lassen sich auch prüfen, während das Skelett beim Autor liegt (Anforderung §8.4).
  if v_s.status not in ('in_pruefung', 'freigegeben') and p_art <> 'variante' then
    raise exception 'studio_pruefen: Sequenz ist nicht eingereicht' using errcode = '22023';
  end if;
  if p_beat_key is not null and not exists (select 1 from public.studio_beat b where b.sequenz_id = p_sequenz_id
                                              and b.beat_key = p_beat_key) then
    raise exception 'studio_pruefen: Beat % fehlt', p_beat_key using errcode = '22023';
  end if;
  insert into public.studio_freigabe (sequenz_id, art, welt, person_id, ergebnis, beat_key, kommentar, version, fingerabdruck)
  select p_sequenz_id, p_art, x.welt, auth.uid(), p_ergebnis, p_beat_key, p_kommentar,
         public.studio_version(p_sequenz_id, x.welt), public.studio_render_fingerabdruck(p_sequenz_id, x.welt)
    from (select case when p_art = 'variante' then p_welt else 'skelett' end as welt) x;
  -- Zurück an den Autor, auch aus „freigegeben“. Die bisherige Ausgabe bleibt, bis neu freigegeben oder zurückgezogen ist.
  if p_ergebnis = 'passt_nicht' and p_art in ('verstaendlich', 'fachlich') then
    update public.studio_sequenz set status = 'entwurf' where id = p_sequenz_id and status in ('in_pruefung', 'freigegeben');
  end if;
  return public.studio_veroeffentlichen(p_sequenz_id);
end;
$$;

-- Nach einem Render oder einer Stimme kann eine schon geprüfte Welt freigabefähig werden.
create function public.studio_ausgabe_pruefen(p_sequenz_id uuid) returns text[]
language plpgsql security definer
set search_path = public, pg_temp
as $$
begin
  if not public.studio_darf_sehen() then
    raise exception 'studio: kein Zugriff' using errcode = '42501';
  end if;
  return public.studio_veroeffentlichen(p_sequenz_id);
end;
$$;

-- Admin: alles zurückziehen. Kinder sehen die Sequenz nicht mehr, bis sie neu freigegeben ist.
create function public.studio_zurueckziehen(p_sequenz_id uuid) returns void
language plpgsql security definer
set search_path = public, pg_temp
as $$
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'studio_zurueckziehen: nur Admin' using errcode = '42501';
  end if;
  update public.studio_ausgabe set zurueckgezogen_am = now() where sequenz_id = p_sequenz_id and zurueckgezogen_am is null;
  -- Versionen erhöhen: alle bisherigen Freigaben fallen, eine neue Ausgabe braucht eine neue Prüfung.
  update public.studio_sequenz set status = 'entwurf', version = version + 1 where id = p_sequenz_id;
  update public.studio_welt set version = version + 1 where sequenz_id = p_sequenz_id;
end;
$$;

-- Stand der Prüfung für den Reiter Freigabe.
create function public.studio_freigabe_stand(p_sequenz_id uuid) returns jsonb
language sql stable security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    'autor', (select p.full_name from public.profiles p where p.id = s.autor_id),
    'autor_id', s.autor_id, 'geschrieben_am', s.angelegt_am, 'status', s.status,
    'ich_bin_autor', s.autor_id = auth.uid(),
    'darf', jsonb_build_object('verstaendlich', public.studio_hat_rolle('gruender') and s.autor_id <> auth.uid(),
                               'fachlich', public.studio_hat_rolle('fachlich') and s.autor_id <> auth.uid(),
                               'einreichen', s.autor_id = auth.uid() or coalesce(public.get_my_role(), '') = 'admin',
                               'zurueckziehen', coalesce(public.get_my_role(), '') = 'admin'),
    'pruefungen', (select coalesce(jsonb_agg(jsonb_build_object('art', f.art, 'welt', f.welt, 'person', p.full_name,
                     'ergebnis', f.ergebnis, 'beat_key', f.beat_key, 'kommentar', f.kommentar, 'at', f.at,
                     'aktuell', f.version = public.studio_version(s.id, f.welt)) order by f.id desc), '[]')
                     from public.studio_freigabe f join public.profiles p on p.id = f.person_id where f.sequenz_id = s.id),
    'welten', (select jsonb_agg(jsonb_build_object('welt', w.welt,
                 'gueltig', case when w.welt = 'skelett'
                                 then jsonb_build_object('verstaendlich', public.studio_freigabe_gueltig(s.id, 'verstaendlich', 'skelett'),
                                                         'fachlich', public.studio_freigabe_gueltig(s.id, 'fachlich', 'skelett'))
                                 else jsonb_build_object('variante', public.studio_freigabe_gueltig(s.id, 'variante', w.welt)) end,
                 'fehlt', to_jsonb(public.studio_ausgabe_fehlt(s.id, w.welt)),
                 'ausgabe', (select jsonb_build_object('freigegeben_am', a.freigegeben_am, 'version_skelett', a.version_skelett,
                                                        'version_welt', a.version_welt, 'zurueckgezogen', a.zurueckgezogen_am is not null)
                               from public.studio_ausgabe a where a.sequenz_id = s.id and a.welt = w.welt))
                 order by w.welt = 'skelett' desc, w.welt)
                 from public.studio_welt w where w.sequenz_id = s.id))
    from public.studio_sequenz s where s.id = p_sequenz_id and public.studio_darf_sehen()
$$;

revoke execute on function public.studio_bearbeiter_merken() from public, anon, authenticated;
revoke execute on function public.studio_freigabe_regeln(), public.studio_version(uuid, text),
  public.studio_freigabe_gueltig(uuid, text, text), public.studio_ausgabe_fehlt(uuid, text),
  public.studio_ausgabe_inhalt(uuid, text, public.studio_render), public.studio_veroeffentlichen(uuid),
  public.studio_einreichen(uuid), public.studio_pruefen(uuid, text, text, text, text, text),
  public.studio_ausgabe_pruefen(uuid), public.studio_zurueckziehen(uuid), public.studio_freigabe_stand(uuid)
  from public, anon;
revoke execute on function public.studio_version(uuid, text), public.studio_freigabe_gueltig(uuid, text, text),
  public.studio_ausgabe_fehlt(uuid, text), public.studio_ausgabe_inhalt(uuid, text, public.studio_render),
  public.studio_veroeffentlichen(uuid) from authenticated;
grant execute on function public.studio_einreichen(uuid), public.studio_pruefen(uuid, text, text, text, text, text),
  public.studio_ausgabe_pruefen(uuid), public.studio_zurueckziehen(uuid), public.studio_freigabe_stand(uuid) to authenticated;
