-- Reihe 1 · Bauauftrag B4: Render-Aufträge (Anforderung Studio §7).
--
-- Je Welt ein Auftrag mit Status (wartet, laeuft, fertig, fehler) und dem Fingerabdruck der Inhalte, aus
-- denen er entsteht: Skelett-Inhalt, Welt-Inhalt, Audiodateien der Welt (studio_stimme_bedarf) und die
-- Fassung des Renderers. Weicht der aktuelle Fingerabdruck vom letzten fertigen Render ab, ist der Render
-- veraltet. Ergebnisse liegen im privaten Bucket studio unter render/<sequenz>/<welt>/<fingerabdruck>/<auftrag>/.
-- Gerendert wird in der Vercel Sandbox (api/studio/render.ts) oder lokal (npm run studio:render); beide melden
-- mit dem JWT des Autors über studio_render_melden — nur der Anleger (oder ein Admin), nur vorwärts, „fertig“
-- nur, wenn die Dateien im Bucket liegen und sich der Inhalt während des Renderns nicht geändert hat.
-- Je Welt läuft höchstens ein Auftrag; ein Auftrag, der länger als 60 Minuten wartet oder läuft, gilt als
-- abgebrochen (das Token der Sandbox lebt höchstens so lange).
-- Die Renderer-Fassung (studio_render_fassung) steigt, wenn sich die Bausteine sichtbar ändern; der Test
-- src/studio/remotion/fassung.test.ts erinnert daran.
--
-- Rollback: supabase/rollback/20261027134813_studio_render.sql.

create table public.studio_render (
  id            uuid primary key default gen_random_uuid(),
  sequenz_id    uuid not null references public.studio_sequenz (id) on delete cascade,
  welt          text not null check (welt in ('skelett', 'fussball', 'gaming', 'musik')),
  fingerabdruck text not null check (fingerabdruck ~ '^[0-9a-f]{64}$'),
  status        text not null default 'wartet' check (status in ('wartet', 'laeuft', 'fertig', 'fehler')),
  ort           text not null default 'server' check (ort in ('server', 'lokal')),
  mp4           text,
  kapitel       jsonb,
  untertitel    text,
  poster        text,
  dauer_ms      integer check (dauer_ms is null or dauer_ms > 0),
  fehler        text,
  angelegt_von  uuid not null references public.profiles (id),
  angelegt_am   timestamptz not null default clock_timestamp(),
  fertig_am     timestamptz,
  check (status <> 'fertig' or (mp4 is not null and kapitel is not null and untertitel is not null and poster is not null
                                and dauer_ms is not null and fertig_am is not null))
);
create index studio_render_sequenz_idx on public.studio_render (sequenz_id, welt, angelegt_am desc);
create unique index studio_render_ein_lauf on public.studio_render (sequenz_id, welt) where status in ('wartet', 'laeuft');

alter table public.studio_render enable row level security;
revoke all on public.studio_render from public, anon, authenticated;
grant select on public.studio_render to authenticated;
create policy studio_render_lesen on public.studio_render for select to authenticated using (public.studio_darf_sehen());

-- Fassung des Renderers (Komposition, Auflösung, Codec). Steigt, wenn sich die Bausteine sichtbar ändern.
create function public.studio_render_fassung() returns text
language sql immutable
set search_path = public, pg_temp
as $$ select 'r1:1920x1080:30:h264-veryfast' $$;

-- Aktueller Inhalts-Fingerabdruck einer Welt.
create function public.studio_render_fingerabdruck(p_sequenz_id uuid, p_welt text) returns text
language sql stable security definer
set search_path = public, pg_temp
as $$
  select encode(sha256(convert_to(concat_ws(E'\n',
           public.studio_render_fassung(),
           public.studio_inhalt_hash(p_sequenz_id, 'skelett'),
           case when p_welt = 'skelett' then '' else public.studio_inhalt_hash(p_sequenz_id, p_welt) end,
           (select string_agg(b.beat_key || '=' || b.fingerabdruck || ':' || b.vorhanden, ',' order by b.beat_key)
              from public.studio_stimme_bedarf(p_sequenz_id) b where b.welt = p_welt)), 'UTF8')), 'hex')
$$;

-- Stand je Welt: letzter Auftrag, letzter fertiger Render und ob er aktuell ist.
create function public.studio_render_stand(p_sequenz_id uuid)
returns table (welt text, fingerabdruck text, letzter_id uuid, letzter_status text, letzter_fehler text,
               fertig_id uuid, fertig_am timestamptz, aktuell boolean, stimme_vollstaendig boolean)
language sql stable security definer
set search_path = public, pg_temp
as $$
  select w.welt, fp.wert, l.id,
         case when l.status in ('wartet', 'laeuft') and l.angelegt_am < clock_timestamp() - interval '60 minutes'
              then 'fehler' else l.status end,
         case when l.status in ('wartet', 'laeuft') and l.angelegt_am < clock_timestamp() - interval '60 minutes'
              then 'zeitueberschreitung' else l.fehler end,
         f.id, f.fertig_am,
         coalesce(f.fingerabdruck = fp.wert, false),
         not exists (select 1 from public.studio_stimme_bedarf(p_sequenz_id) b
                      where b.welt = w.welt and (not b.vorhanden or b.platzhalter))
    from public.studio_welt w
    cross join lateral (select public.studio_render_fingerabdruck(p_sequenz_id, w.welt) as wert) fp
    left join lateral (select r.* from public.studio_render r where r.sequenz_id = w.sequenz_id and r.welt = w.welt
                        order by r.angelegt_am desc limit 1) l on true
    left join lateral (select r.* from public.studio_render r where r.sequenz_id = w.sequenz_id and r.welt = w.welt
                          and r.status = 'fertig' order by r.fertig_am desc limit 1) f on true
   where w.sequenz_id = p_sequenz_id and public.studio_darf_sehen()
   order by w.welt = 'skelett' desc, w.welt
$$;

-- Auftrag anlegen (Autor/Admin). Gesperrte Welten werden nicht gerendert.
create function public.studio_render_anlegen(p_sequenz_id uuid, p_welt text, p_ort text default 'server') returns uuid
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_id uuid;
begin
  if not public.studio_hat_rolle('autor') then
    raise exception 'studio: nur Autor oder Admin' using errcode = '42501';
  end if;
  if not exists (select 1 from public.studio_welt w where w.sequenz_id = p_sequenz_id and w.welt = p_welt and not w.gesperrt) then
    raise exception 'studio_render_anlegen: Welt % fehlt oder ist gesperrt', p_welt using errcode = '22023';
  end if;
  -- Abgebrochene Aufträge (Sandbox-Timeout, abgelaufenes Token) räumen.
  update public.studio_render set status = 'fehler', fehler = 'zeitueberschreitung'
   where sequenz_id = p_sequenz_id and welt = p_welt and status in ('wartet', 'laeuft')
     and angelegt_am < clock_timestamp() - interval '60 minutes';
  if exists (select 1 from public.studio_render r where r.sequenz_id = p_sequenz_id and r.welt = p_welt
               and r.status in ('wartet', 'laeuft')) then
    raise exception 'studio_render_anlegen: für % läuft schon ein Render', p_welt using errcode = '23505';
  end if;
  insert into public.studio_render (sequenz_id, welt, fingerabdruck, ort, angelegt_von)
  values (p_sequenz_id, p_welt, public.studio_render_fingerabdruck(p_sequenz_id, p_welt), p_ort, auth.uid())
  returning id into v_id;
  return v_id;
end;
$$;

-- Stand melden (Sandbox oder lokaler Render). Nur vorwärts: wartet → laeuft → fertig | fehler.
create function public.studio_render_melden(p_id uuid, p_status text, p_ergebnis jsonb default '{}', p_fehler text default null)
returns void
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_r public.studio_render;
  v_basis text;
begin
  if not public.studio_hat_rolle('autor') then
    raise exception 'studio: nur Autor oder Admin' using errcode = '42501';
  end if;
  select * into v_r from public.studio_render where id = p_id for update;
  if v_r.id is null then
    raise exception 'studio_render_melden: Auftrag fehlt' using errcode = 'P0002';
  end if;
  if v_r.angelegt_von <> auth.uid() and coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'studio_render_melden: nur wer den Auftrag angelegt hat' using errcode = '42501';
  end if;
  if not ((v_r.status = 'wartet' and p_status in ('laeuft', 'fehler')) or (v_r.status = 'laeuft' and p_status in ('fertig', 'fehler'))) then
    raise exception 'studio_render_melden: % → % nicht erlaubt', v_r.status, p_status using errcode = '22023';
  end if;
  -- Inhalt geändert, seit der Auftrag angelegt wurde: dieser Render gilt nicht.
  if p_status in ('laeuft', 'fertig') and public.studio_render_fingerabdruck(v_r.sequenz_id, v_r.welt) <> v_r.fingerabdruck then
    update public.studio_render set status = 'fehler', fehler = 'inhalt_geaendert' where id = p_id;
    return;
  end if;
  v_basis := 'render/' || v_r.sequenz_id || '/' || v_r.welt || '/' || v_r.fingerabdruck || '/' || v_r.id || '/';
  if p_status = 'fertig' and not coalesce(p_ergebnis ->> 'mp4' like v_basis || '%' and p_ergebnis ->> 'untertitel' like v_basis || '%'
                                  and p_ergebnis ->> 'poster' like v_basis || '%'
                                  and jsonb_typeof(p_ergebnis -> 'kapitel') = 'array'
                                  and jsonb_typeof(p_ergebnis -> 'dauer_ms') = 'number'
                                  and (p_ergebnis ->> 'dauer_ms')::numeric >= 1, false) then
    raise exception 'studio_render_melden: Ergebnis unvollständig oder falscher Pfad' using errcode = '22023';
  end if;
  if p_status = 'fertig' and (select count(*) from storage.objects o where o.bucket_id = 'studio'
                               and o.name in (p_ergebnis ->> 'mp4', p_ergebnis ->> 'untertitel', p_ergebnis ->> 'poster')) <> 3 then
    raise exception 'studio_render_melden: Dateien fehlen im Bucket' using errcode = '22023';
  end if;
  update public.studio_render
     set status = p_status,
         mp4 = p_ergebnis ->> 'mp4', kapitel = p_ergebnis -> 'kapitel', untertitel = p_ergebnis ->> 'untertitel',
         poster = p_ergebnis ->> 'poster', dauer_ms = round((p_ergebnis ->> 'dauer_ms')::numeric)::int,
         fehler = left(p_fehler, 500),
         fertig_am = case when p_status = 'fertig' then clock_timestamp() end
   where id = p_id;
end;
$$;

revoke execute on function public.studio_render_fassung(), public.studio_render_fingerabdruck(uuid, text),
  public.studio_render_stand(uuid), public.studio_render_anlegen(uuid, text, text),
  public.studio_render_melden(uuid, text, jsonb, text) from public, anon;
revoke execute on function public.studio_render_fingerabdruck(uuid, text) from authenticated;
grant execute on function public.studio_render_stand(uuid), public.studio_render_anlegen(uuid, text, text),
  public.studio_render_melden(uuid, text, jsonb, text), public.studio_render_fassung() to authenticated;
