-- E1.1 Erklaersequenz: Pflege- und Statusfunktionen (Muster 20261004001333_lead_thema_setzen).
--
-- Schreiben duerfen nur Pruefer und Admin (darf_pruefen()) bzw. Systemaufrufe
-- (Importe, Migrationen; ist_systemaufruf()). Freigeben darf nur ein Admin, und nur
-- was vorher geprueft ist (Entscheidung 18: Lena prueft, ein Admin gibt frei).
--
-- Jede inhaltliche Aenderung setzt das geaenderte Objekt auf 'entwurf' zurueck und
-- erhoeht pruef_version der Kernidee. erklaer_status_setzen verlangt die Version,
-- die der Pruefer gesehen hat (optimistische Sperre wie tasks.pruef_version).
-- Fehler laufen ueber pruef_fehler (ED422 + Hinweis-Code) wie im Lena-Board.

create function public.erklaer_darf_schreiben(p_fn text) returns void
language plpgsql stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not (public.darf_pruefen() or public.ist_systemaufruf()) then
    raise exception '%: nur Pruefer oder Admin', p_fn using errcode = '42501';
  end if;
end;
$$;

create function public.erklaer_version_hoch(p_kernidee_id uuid) returns bigint
language sql volatile
security definer
set search_path = public, pg_temp
as $$
  update public.erklaer_kernidee
     set pruef_version = pruef_version + 1, geaendert_am = now()
   where id = p_kernidee_id
  returning pruef_version
$$;

create function public.erklaer_kernidee_speichern(
  p_id        uuid,
  p_skill_key text,
  p_nr        integer,
  p_titel     text,
  p_quelle    text default 'ki'
)
returns uuid
language plpgsql volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_id uuid;
begin
  perform public.erklaer_darf_schreiben('erklaer_kernidee_speichern');
  if p_id is null then
    insert into public.erklaer_kernidee (skill_key, nr, titel, quelle)
    values (p_skill_key, p_nr, btrim(p_titel), p_quelle)
    returning id into v_id;
    return v_id;
  end if;

  update public.erklaer_kernidee
     set skill_key = p_skill_key, nr = p_nr, titel = btrim(p_titel), quelle = p_quelle,
         status = 'entwurf', pruef_version = pruef_version + 1, geaendert_am = now()
   where id = p_id
     and (skill_key, nr, titel, quelle) is distinct from (p_skill_key, p_nr, btrim(p_titel), p_quelle)
  returning id into v_id;
  if v_id is null and not exists (select 1 from public.erklaer_kernidee where id = p_id) then
    raise exception 'erklaer_kernidee_speichern: Kernidee nicht gefunden' using errcode = 'P0002';
  end if;
  return p_id;
end;
$$;

create function public.erklaer_schritt_speichern(
  p_kernidee_id    uuid,
  p_variante       text,
  p_art            text,
  p_inhalt         text,
  p_bild           jsonb  default null,
  p_fehlbild_slugs text[] default '{}'
)
returns uuid
language plpgsql volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_alt public.erklaer_schritt;
  v_id  uuid;
begin
  perform public.erklaer_darf_schreiben('erklaer_schritt_speichern');
  if exists (select 1 from unnest(coalesce(p_fehlbild_slugs, '{}')) s(slug)
              where not exists (select 1 from public.fehlbild_labels l where l.slug = s.slug)) then
    perform public.pruef_fehler('fehlbild_unbekannt');
  end if;

  select * into v_alt from public.erklaer_schritt
   where kernidee_id = p_kernidee_id and variante = p_variante and art = p_art
   for update;

  if v_alt.id is null then
    insert into public.erklaer_schritt (kernidee_id, variante, art, inhalt, bild, fehlbild_slugs)
    values (p_kernidee_id, p_variante, p_art, p_inhalt, p_bild, coalesce(p_fehlbild_slugs, '{}'))
    returning id into v_id;
  elsif (v_alt.inhalt, v_alt.bild, v_alt.fehlbild_slugs)
        is distinct from (p_inhalt, p_bild, coalesce(p_fehlbild_slugs, '{}')) then
    update public.erklaer_schritt
       set inhalt = p_inhalt, bild = p_bild, fehlbild_slugs = coalesce(p_fehlbild_slugs, '{}'),
           -- Neuer Text heisst neue Formeln: tools/formeln-svg.mjs erzeugt sie neu.
           formeln = case when inhalt = p_inhalt then formeln else '{}' end,
           status = 'entwurf', geaendert_am = now()
     where id = v_alt.id
    returning id into v_id;
  else
    return v_alt.id;
  end if;

  perform public.erklaer_version_hoch(p_kernidee_id);
  return v_id;
end;
$$;

-- p_reihenfolge null nimmt die Aufgabe aus der Kernidee.
create function public.erklaer_check_setzen(
  p_kernidee_id uuid,
  p_task_id     uuid,
  p_reihenfolge integer
)
returns void
language plpgsql volatile
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.erklaer_darf_schreiben('erklaer_check_setzen');
  if p_reihenfolge is null then
    delete from public.erklaer_check where kernidee_id = p_kernidee_id and task_id = p_task_id;
  else
    insert into public.erklaer_check (kernidee_id, task_id, reihenfolge)
    values (p_kernidee_id, p_task_id, p_reihenfolge)
    on conflict (kernidee_id, task_id) do update set reihenfolge = excluded.reihenfolge;
  end if;
  perform public.erklaer_version_hoch(p_kernidee_id);
end;
$$;

-- p_objekt: 'kernidee' oder 'schritt'. p_pruef_version: die Version der Kernidee,
-- die der Pruefer gesehen hat. Liefert die neue Version.
create function public.erklaer_status_setzen(
  p_objekt       text,
  p_id           uuid,
  p_status       text,
  p_pruef_version bigint
)
returns bigint
language plpgsql volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_kernidee public.erklaer_kernidee;
  v_schritt  public.erklaer_schritt;
  v_alt      text;
begin
  perform public.erklaer_darf_schreiben('erklaer_status_setzen');
  if p_status not in ('entwurf', 'geprueft', 'freigegeben') or p_objekt not in ('kernidee', 'schritt') then
    raise exception 'erklaer_status_setzen: ungueltiger Status oder Objekt' using errcode = '22023';
  end if;

  if p_objekt = 'schritt' then
    select * into v_schritt from public.erklaer_schritt where id = p_id for update;
    if v_schritt.id is null then
      raise exception 'erklaer_status_setzen: Schritt nicht gefunden' using errcode = 'P0002';
    end if;
    select * into v_kernidee from public.erklaer_kernidee where id = v_schritt.kernidee_id for update;
    v_alt := v_schritt.status;
  else
    select * into v_kernidee from public.erklaer_kernidee where id = p_id for update;
    if v_kernidee.id is null then
      raise exception 'erklaer_status_setzen: Kernidee nicht gefunden' using errcode = 'P0002';
    end if;
    v_alt := v_kernidee.status;
  end if;

  if v_kernidee.pruef_version is distinct from p_pruef_version then
    perform public.pruef_fehler('veraltet', 'erklaer_status_setzen: inzwischen geaendert, neu laden');
  end if;
  if p_status = 'freigegeben' then
    if coalesce(public.get_my_role(), '') <> 'admin' and not public.ist_systemaufruf() then
      raise exception 'erklaer_status_setzen: freigeben nur Admin' using errcode = '42501';
    end if;
    if v_alt <> 'geprueft' then
      perform public.pruef_fehler('erst_pruefen', 'erklaer_status_setzen: erst pruefen, dann freigeben');
    end if;
    if p_objekt = 'schritt'
       and cardinality(v_schritt.formeln) <> public.erklaer_formel_anzahl(v_schritt.inhalt) then
      perform public.pruef_fehler('formeln_fehlen', 'erklaer_status_setzen: Formeln noch nicht als SVG erzeugt');
    end if;
  end if;

  if p_objekt = 'schritt' then
    update public.erklaer_schritt set status = p_status, geaendert_am = now() where id = p_id;
  else
    update public.erklaer_kernidee set status = p_status where id = p_id;
  end if;
  return public.erklaer_version_hoch(v_kernidee.id);
end;
$$;

-- Fuer tools/formeln-svg.mjs: traegt die SVG-Hashes ein, aber nur, wenn der Text
-- noch derselbe ist, aus dem sie erzeugt wurden, und die Anzahl stimmt. Aendert
-- keinen Status: die Formeln sind aus dem Text abgeleitet.
create function public.erklaer_formeln_setzen(
  p_schritt_id uuid,
  p_inhalt     text,
  p_formeln    text[]
)
returns void
language plpgsql volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_schritt public.erklaer_schritt;
begin
  perform public.erklaer_darf_schreiben('erklaer_formeln_setzen');
  select * into v_schritt from public.erklaer_schritt where id = p_schritt_id for update;
  if v_schritt.id is null then
    raise exception 'erklaer_formeln_setzen: Schritt nicht gefunden' using errcode = 'P0002';
  end if;
  if v_schritt.inhalt is distinct from p_inhalt then
    perform public.pruef_fehler('veraltet', 'erklaer_formeln_setzen: Text hat sich geaendert');
  end if;
  if cardinality(p_formeln) <> public.erklaer_formel_anzahl(p_inhalt)
     or exists (select 1 from unnest(p_formeln) h where h is null or h !~ '^[0-9a-f]{64}$') then
    raise exception 'erklaer_formeln_setzen: Anzahl oder Form der Hashes passt nicht' using errcode = '22023';
  end if;
  update public.erklaer_schritt set formeln = p_formeln where id = p_schritt_id;
end;
$$;

comment on function public.erklaer_status_setzen(text, uuid, text, bigint) is
  'Status einer Kernidee oder eines Schritts: entwurf/geprueft (Pruefer, Admin), freigegeben (nur Admin, nur aus geprueft).';

revoke all on function public.erklaer_darf_schreiben(text) from public, anon, authenticated;
revoke all on function public.erklaer_version_hoch(uuid) from public, anon, authenticated;

revoke all on function public.erklaer_kernidee_speichern(uuid, text, integer, text, text) from public, anon, authenticated;
revoke all on function public.erklaer_schritt_speichern(uuid, text, text, text, jsonb, text[]) from public, anon, authenticated;
revoke all on function public.erklaer_check_setzen(uuid, uuid, integer) from public, anon, authenticated;
revoke all on function public.erklaer_status_setzen(text, uuid, text, bigint) from public, anon, authenticated;
revoke all on function public.erklaer_formeln_setzen(uuid, text, text[]) from public, anon, authenticated;
grant execute on function public.erklaer_kernidee_speichern(uuid, text, integer, text, text) to authenticated;
grant execute on function public.erklaer_schritt_speichern(uuid, text, text, text, jsonb, text[]) to authenticated;
grant execute on function public.erklaer_check_setzen(uuid, uuid, integer) to authenticated;
grant execute on function public.erklaer_status_setzen(text, uuid, text, bigint) to authenticated;
grant execute on function public.erklaer_formeln_setzen(uuid, text, text[]) to authenticated;
