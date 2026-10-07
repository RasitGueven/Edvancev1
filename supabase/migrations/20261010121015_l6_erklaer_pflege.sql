-- L6.1 Erklaersequenz pruefen, Teil 2: Pflege- und Statusfunktionen schreiben ins Pruefprotokoll.
--
-- Ersetzt (gleiche Signatur, create or replace), Grundlage die Prod-Definitionen aus
-- 20261007135025_erklaer_pflege (pg_get_functiondef, 07.10.2026):
--   erklaer_kernidee_speichern, erklaer_schritt_speichern, erklaer_check_setzen,
--   erklaer_status_setzen, erklaer_formeln_setzen
-- Verhalten wie bisher, dazu:
--   - jede wirksame Aenderung schreibt eine Zeile in erklaer_pruefungen ('geaendert' bzw. 'status')
--     mit vorher/nachher je Feld;
--   - erklaer_schritt_speichern: aendert sich ein Schritt einer geprueften (nicht freigegebenen)
--     Kernidee, faellt auch die Kernidee auf entwurf (Lenas passt galt dem alten Stand);
--   - erklaer_status_setzen: eine Kernidee freigeben geht nur, wenn erklaer_freigabe_fehlt leer ist
--     (gleiche Regel wie erklaer_freigeben); 'freigegeben' verlassen darf nur ein Admin.
-- Neu (intern, kein Grant): erklaer_aenderung.

create function public.erklaer_aenderung(
  p_objekt text, p_variante text, p_art text, p_feld text, p_vorher jsonb, p_nachher jsonb
)
returns jsonb
language sql immutable
set search_path = public, pg_temp
as $$
  select jsonb_build_object('objekt', p_objekt, 'feld', p_feld, 'vorher', p_vorher, 'nachher', p_nachher)
         || case when p_variante is null then '{}'::jsonb
                 else jsonb_build_object('variante', p_variante, 'art', p_art) end
$$;

create or replace function public.erklaer_kernidee_speichern(
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
  v_alt  public.erklaer_kernidee;
  v_id   uuid;
  v_aend jsonb;
begin
  perform public.erklaer_darf_schreiben('erklaer_kernidee_speichern');
  if p_id is null then
    insert into public.erklaer_kernidee (skill_key, nr, titel, quelle)
    values (p_skill_key, p_nr, btrim(p_titel), p_quelle)
    returning id into v_id;
    perform public.erklaer_protokollieren(v_id, 'geaendert', jsonb_build_array(
      public.erklaer_aenderung('kernidee', null, null, 'angelegt', null, to_jsonb(btrim(p_titel)))));
    return v_id;
  end if;

  select * into v_alt from public.erklaer_kernidee where id = p_id for update;
  if v_alt.id is null then
    raise exception 'erklaer_kernidee_speichern: Kernidee nicht gefunden' using errcode = 'P0002';
  end if;
  if (v_alt.skill_key, v_alt.nr, v_alt.titel, v_alt.quelle)
     is not distinct from (p_skill_key, p_nr, btrim(p_titel), p_quelle) then
    return p_id;
  end if;

  update public.erklaer_kernidee
     set skill_key = p_skill_key, nr = p_nr, titel = btrim(p_titel), quelle = p_quelle,
         status = 'entwurf', pruef_version = pruef_version + 1, geaendert_am = now()
   where id = p_id;

  select coalesce(jsonb_agg(public.erklaer_aenderung('kernidee', null, null, f.feld, f.vorher, f.nachher) order by f.o), '[]')
    into v_aend
    from (values (1, 'skill_key', to_jsonb(v_alt.skill_key), to_jsonb(p_skill_key)),
                 (2, 'nr',        to_jsonb(v_alt.nr),        to_jsonb(p_nr)),
                 (3, 'titel',     to_jsonb(v_alt.titel),     to_jsonb(btrim(p_titel))),
                 (4, 'quelle',    to_jsonb(v_alt.quelle),    to_jsonb(p_quelle)),
                 (5, 'status',    to_jsonb(v_alt.status),    '"entwurf"'::jsonb)) f(o, feld, vorher, nachher)
   where f.vorher is distinct from f.nachher;
  perform public.erklaer_protokollieren(p_id, 'geaendert', v_aend);
  return p_id;
end;
$$;

create or replace function public.erklaer_schritt_speichern(
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
  v_alt    public.erklaer_schritt;
  v_neu    public.erklaer_schritt;
  v_kstat  text;
  v_aend   jsonb;
begin
  perform public.erklaer_darf_schreiben('erklaer_schritt_speichern');
  if exists (select 1 from unnest(coalesce(p_fehlbild_slugs, '{}')) s(slug)
              where not exists (select 1 from public.fehlbild_labels l where l.slug = s.slug)) then
    perform public.pruef_fehler('fehlbild_unbekannt');
  end if;

  -- Sperrreihenfolge wie erklaer_pruefen/erklaer_freigeben: erst die Kernidee, dann der Schritt.
  perform 1 from public.erklaer_kernidee where id = p_kernidee_id for update;
  select * into v_alt from public.erklaer_schritt
   where kernidee_id = p_kernidee_id and variante = p_variante and art = p_art
   for update;

  if v_alt.id is null then
    insert into public.erklaer_schritt (kernidee_id, variante, art, inhalt, bild, fehlbild_slugs)
    values (p_kernidee_id, p_variante, p_art, p_inhalt, p_bild, coalesce(p_fehlbild_slugs, '{}'))
    returning * into v_neu;
    v_aend := jsonb_build_array(public.erklaer_aenderung('schritt', p_variante, p_art, 'angelegt', null, to_jsonb(p_inhalt)));
  elsif (v_alt.inhalt, v_alt.bild, v_alt.fehlbild_slugs)
        is distinct from (p_inhalt, p_bild, coalesce(p_fehlbild_slugs, '{}')) then
    update public.erklaer_schritt
       set inhalt = p_inhalt, bild = p_bild, fehlbild_slugs = coalesce(p_fehlbild_slugs, '{}'),
           -- Neuer Text heisst neue Formeln: tools/formeln-svg.mjs erzeugt sie neu.
           formeln = case when inhalt = p_inhalt then formeln else '{}' end,
           status = 'entwurf', geaendert_am = now()
     where id = v_alt.id
    returning * into v_neu;
    select coalesce(jsonb_agg(public.erklaer_aenderung('schritt', p_variante, p_art, f.feld, f.vorher, f.nachher)
                              order by f.o), '[]')
      into v_aend
      from (values (1, 'inhalt',         to_jsonb(v_alt.inhalt),         to_jsonb(v_neu.inhalt)),
                   (2, 'bild',           v_alt.bild,                     v_neu.bild),
                   (3, 'fehlbild_slugs', to_jsonb(v_alt.fehlbild_slugs), to_jsonb(v_neu.fehlbild_slugs)),
                   (4, 'formeln',        to_jsonb(v_alt.formeln),        to_jsonb(v_neu.formeln)),
                   (5, 'status',         to_jsonb(v_alt.status),         to_jsonb(v_neu.status))) f(o, feld, vorher, nachher)
     where f.vorher is distinct from f.nachher;
  else
    return v_alt.id;
  end if;

  -- Lenas passt galt dem alten Stand: eine gepruefte Kernidee faellt auf entwurf. Eine freigegebene
  -- Kernidee bleibt freigegeben; nur der geaenderte Schritt ist entwurf und geht erst nach Pruefung und
  -- Freigabe wieder ans Kind. (Andere Checks oder ein geaenderter Titel setzen dagegen auch eine
  -- freigegebene Kernidee auf entwurf, Regel aus E1, offene-punkte-e1 17.)
  update public.erklaer_kernidee set status = 'entwurf'
   where id = p_kernidee_id and status = 'geprueft'
  returning 'geprueft' into v_kstat;
  if v_kstat is not null then
    v_aend := v_aend || jsonb_build_array(
      public.erklaer_aenderung('kernidee', null, null, 'status', '"geprueft"', '"entwurf"'));
  end if;

  perform public.erklaer_version_hoch(p_kernidee_id);
  perform public.erklaer_protokollieren(p_kernidee_id, 'geaendert', v_aend);
  return v_neu.id;
end;
$$;

-- p_reihenfolge null nimmt die Aufgabe aus der Kernidee.
create or replace function public.erklaer_check_setzen(
  p_kernidee_id uuid,
  p_task_id     uuid,
  p_reihenfolge integer
)
returns void
language plpgsql volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_vorher integer;
  v_kstat  text;
begin
  perform public.erklaer_darf_schreiben('erklaer_check_setzen');
  select reihenfolge into v_vorher from public.erklaer_check
   where kernidee_id = p_kernidee_id and task_id = p_task_id;
  select status into v_kstat from public.erklaer_kernidee where id = p_kernidee_id for update;
  if p_reihenfolge is null then
    delete from public.erklaer_check where kernidee_id = p_kernidee_id and task_id = p_task_id;
  else
    insert into public.erklaer_check (kernidee_id, task_id, reihenfolge)
    values (p_kernidee_id, p_task_id, p_reihenfolge)
    on conflict (kernidee_id, task_id) do update set reihenfolge = excluded.reihenfolge;
  end if;
  -- Andere Checks heissen neu pruefen: die Kernidee faellt auf entwurf.
  update public.erklaer_kernidee set status = 'entwurf' where id = p_kernidee_id;
  perform public.erklaer_version_hoch(p_kernidee_id);
  perform public.erklaer_protokollieren(p_kernidee_id, 'geaendert',
    jsonb_build_array(jsonb_build_object('objekt', 'check', 'task_id', p_task_id, 'feld', 'reihenfolge',
                                         'vorher', v_vorher, 'nachher', p_reihenfolge))
    || case when v_kstat is distinct from 'entwurf'
            then jsonb_build_array(public.erklaer_aenderung('kernidee', null, null, 'status',
                                                            to_jsonb(v_kstat), '"entwurf"'))
            else '[]'::jsonb end);
end;
$$;

-- p_objekt: 'kernidee' oder 'schritt'. p_pruef_version: die Version der Kernidee,
-- die der Pruefer gesehen hat. Liefert die neue Version.
create or replace function public.erklaer_status_setzen(
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
  v_fehlt    jsonb;
  v_version  bigint;
  v_admin    boolean := coalesce(public.get_my_role(), '') = 'admin' or public.ist_systemaufruf();
begin
  perform public.erklaer_darf_schreiben('erklaer_status_setzen');
  if p_status not in ('entwurf', 'geprueft', 'freigegeben') or p_objekt not in ('kernidee', 'schritt') then
    raise exception 'erklaer_status_setzen: ungueltiger Status oder Objekt' using errcode = '22023';
  end if;

  if p_objekt = 'schritt' then
    -- Sperrreihenfolge: erst die Kernidee, dann der Schritt.
    select * into v_kernidee from public.erklaer_kernidee
     where id = (select s.kernidee_id from public.erklaer_schritt s where s.id = p_id) for update;
    select * into v_schritt from public.erklaer_schritt where id = p_id for update;
    if v_schritt.id is null then
      raise exception 'erklaer_status_setzen: Schritt nicht gefunden' using errcode = 'P0002';
    end if;
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
  -- Freigeben und eine Freigabe zuruecknehmen: nur Admin (L6, Entscheidung 18).
  if (p_status = 'freigegeben' or (v_alt = 'freigegeben' and p_status <> 'freigegeben')) and not v_admin then
    raise exception 'erklaer_status_setzen: freigeben nur Admin' using errcode = '42501';
  end if;
  if p_status = 'freigegeben' then
    if v_alt <> 'geprueft' then
      perform public.pruef_fehler('erst_pruefen', 'erklaer_status_setzen: erst pruefen, dann freigeben');
    end if;
    if p_objekt = 'schritt'
       and cardinality(v_schritt.formeln) <> public.erklaer_formel_anzahl(v_schritt.inhalt) then
      perform public.pruef_fehler('formeln_fehlen', 'erklaer_status_setzen: Formeln noch nicht als SVG erzeugt');
    end if;
    if p_objekt = 'kernidee' then
      -- Anders als erklaer_freigeben hebt dieser Weg keine Schritte mit an: gepruefte Schritte muessen
      -- vorher einzeln freigegeben sein, sonst stuende eine freigegebene Kernidee ohne Inhalt da.
      v_fehlt := public.erklaer_freigabe_fehlt(p_id)
        || coalesce((select jsonb_agg(jsonb_build_object('was', 'schritt_nicht_freigegeben',
                                                         'variante', s.variante, 'art', s.art)
                                      order by s.variante, s.art)
                       from public.erklaer_schritt s where s.kernidee_id = p_id and s.status = 'geprueft'), '[]');
      if jsonb_array_length(v_fehlt) > 0 then
        raise exception 'erklaer_status_setzen: Freigabe unvollstaendig: %', v_fehlt::text
          using errcode = 'ED422', hint = 'freigabe_unvollstaendig', detail = v_fehlt::text;
      end if;
    end if;
  end if;

  if p_objekt = 'schritt' then
    update public.erklaer_schritt set status = p_status, geaendert_am = now() where id = p_id;
  else
    update public.erklaer_kernidee set status = p_status where id = p_id;
  end if;
  v_version := public.erklaer_version_hoch(v_kernidee.id);
  if v_alt is distinct from p_status then
    perform public.erklaer_protokollieren(v_kernidee.id, 'status', jsonb_build_array(
      public.erklaer_aenderung(p_objekt, v_schritt.variante, v_schritt.art, 'status', to_jsonb(v_alt), to_jsonb(p_status))));
  end if;
  return v_version;
end;
$$;

-- Fuer tools/formeln-svg.mjs: traegt die SVG-Hashes ein, aber nur, wenn der Text
-- noch derselbe ist, aus dem sie erzeugt wurden, und die Anzahl stimmt. Aendert
-- keinen Status: die Formeln sind aus dem Text abgeleitet.
create or replace function public.erklaer_formeln_setzen(
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
  v_neu     text;
begin
  perform public.erklaer_darf_schreiben('erklaer_formeln_setzen');
  -- Sperrreihenfolge: erst die Kernidee, dann der Schritt.
  perform 1 from public.erklaer_kernidee
   where id = (select s.kernidee_id from public.erklaer_schritt s where s.id = p_schritt_id) for update;
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
  if v_schritt.formeln is not distinct from p_formeln then
    return;
  end if;
  -- Neue SVGs an einem freigegebenen Schritt gehen erst nach erneuter Freigabe ans Kind.
  update public.erklaer_schritt
     set formeln = p_formeln,
         status  = case when status = 'freigegeben' then 'geprueft' else status end
   where id = p_schritt_id
  returning status into v_neu;
  perform public.erklaer_protokollieren(v_schritt.kernidee_id, 'geaendert',
    jsonb_build_array(public.erklaer_aenderung('schritt', v_schritt.variante, v_schritt.art, 'formeln',
                                               to_jsonb(v_schritt.formeln), to_jsonb(p_formeln)))
    || case when v_neu is distinct from v_schritt.status
            then jsonb_build_array(public.erklaer_aenderung('schritt', v_schritt.variante, v_schritt.art, 'status',
                                                            to_jsonb(v_schritt.status), to_jsonb(v_neu)))
            else '[]'::jsonb end);
end;
$$;

comment on function public.erklaer_status_setzen(text, uuid, text, bigint) is
  'Status einer Kernidee oder eines Schritts: entwurf/geprueft (Pruefer, Admin), freigegeben und zurueck nur Admin; Kernidee nur mit leerem erklaer_freigabe_fehlt. Protokolliert.';

revoke all on function public.erklaer_aenderung(text, text, text, text, jsonb, jsonb) from public, anon, authenticated;
