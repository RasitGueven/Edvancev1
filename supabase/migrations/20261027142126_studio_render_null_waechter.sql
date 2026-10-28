-- Reihe 1 · B4 Nachtrag: studio_render_melden NULL-sicher (Wächter X0c). Nur `angelegt_von <> auth.uid()` wird
-- `is distinct from`. Gleiche Signatur, gleiche Rechte.
--
-- Rollback: supabase/rollback/20261027142126_studio_render_null_waechter.sql.

create or replace function public.studio_render_melden(p_id uuid, p_status text, p_ergebnis jsonb default '{}', p_fehler text default null)
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
  if v_r.angelegt_von is distinct from auth.uid() and coalesce(public.get_my_role(), '') <> 'admin' then
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
