-- L6.1 Erklaersequenz pruefen, Teil 3: Lenas Pruefung und die Freigabe durch einen Admin
-- (Entscheidung 18: Alle Teile entstehen als KI-Entwurf; Lena prueft, ein Admin gibt frei).
--
--   erklaer_pruefen(kernidee, entscheidung, gruende, notiz, pruef_version)       Pruefer und Admin
--        passt            Kernidee und ihre Schritte im Entwurf -> geprueft
--        unsicher         Rueckfrage an den Admin (Notiz Pflicht); eine gepruefte Kernidee faellt auf entwurf
--        passt_nicht      bleibt bzw. faellt auf entwurf, Gruende Pflicht (sonstiges nur mit Notiz)
--        zurueckgenommen  Lenas letzte Entscheidung rueckgaengig: zurueck auf offen
--   erklaer_freigeben(kernidee, pruef_version)                       nur Admin, nur mit leerem erklaer_freigabe_fehlt
--   erklaer_freigabe_zuruecknehmen(kernidee, grund, pruef_version)   nur Admin, Grund Pflicht, zurueck an Lena
--   erklaer_rueckfrage_beantworten(kernidee, antwort)                nur Admin, beantwortet Lenas unsicher
--
-- Muster 20261004001333_lead_thema_setzen: SECURITY DEFINER, search_path = public, pg_temp, Grant nur an
-- authenticated. Rollenpruefungen NULL-sicher (X0b): ohne Profil liefern darf_pruefen() false und
-- coalesce(get_my_role(), '') '' -> 42501. Fehler fuer das Frontend ueber pruef_fehler (ED422, HINT = Schluessel);
-- eine veraltete Version ist ED422 'veraltet' wie in erklaer_status_setzen.
-- Neu (intern, kein Grant): erklaer_pruef_sperren, erklaer_schritte_status.

-- Zugang, Sperre, Version. Gibt die gesperrte Kernidee zurueck.
create function public.erklaer_pruef_sperren(p_kernidee_id uuid, p_pruef_version bigint, p_nur_admin boolean)
returns public.erklaer_kernidee
language plpgsql volatile
security definer
set search_path = public, pg_temp
as $$
declare
  k public.erklaer_kernidee;
begin
  if p_nur_admin and coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'erklaer: nur Admin' using errcode = '42501';
  end if;
  if not public.darf_pruefen() then
    raise exception 'erklaer: kein Pruefrecht' using errcode = '42501';
  end if;
  select * into k from public.erklaer_kernidee where id = p_kernidee_id for update;
  if k.id is null then
    raise exception 'erklaer: Kernidee nicht gefunden' using errcode = 'P0002';
  end if;
  if p_pruef_version is not null and k.pruef_version is distinct from p_pruef_version then
    perform public.pruef_fehler('veraltet', 'erklaer: inzwischen geaendert, neu laden');
  end if;
  return k;
end;
$$;

-- Setzt alle Schritte der Kernidee mit Status in p_von auf p_nach; liefert die Aenderungen.
create function public.erklaer_schritte_status(p_kernidee_id uuid, p_von text[], p_nach text)
returns jsonb
language sql volatile
security definer
set search_path = public, pg_temp
as $$
  with alt as (
    select id, variante, art, status from public.erklaer_schritt
     where kernidee_id = p_kernidee_id and status = any (p_von) and status <> p_nach
  ), neu as (
    -- Status erneut pruefen: ein gleichzeitig gespeicherter Schritt ist inzwischen wieder entwurf.
    update public.erklaer_schritt s set status = p_nach, geaendert_am = now()
      from alt where s.id = alt.id and s.status = any (p_von)
    returning alt.variante, alt.art, alt.status as vorher
  )
  select coalesce(jsonb_agg(public.erklaer_aenderung('schritt', variante, art, 'status', to_jsonb(vorher), to_jsonb(p_nach))
                            order by variante, art), '[]')
    from neu
$$;

create function public.erklaer_pruefen(
  p_kernidee_id   uuid,
  p_entscheidung  text,
  p_gruende       text[] default null,
  p_notiz         text   default null,
  p_pruef_version bigint default null
)
returns jsonb
language plpgsql volatile
security definer
set search_path = public, pg_temp
as $$
declare
  k        public.erklaer_kernidee;
  v_notiz  text := nullif(btrim(p_notiz), '');
  v_gruende text[] := array(select distinct btrim(x) from unnest(coalesce(p_gruende, '{}')) x where btrim(x) <> '');
  v_aend   jsonb;
  v_status text;
begin
  if p_pruef_version is null then
    raise exception 'erklaer_pruefen: pruef_version ist Pflicht' using errcode = '22023';
  end if;
  k := public.erklaer_pruef_sperren(p_kernidee_id, p_pruef_version, false);
  if p_entscheidung is null or p_entscheidung not in ('passt', 'unsicher', 'passt_nicht', 'zurueckgenommen') then
    raise exception 'erklaer_pruefen: unbekannte Entscheidung %', p_entscheidung using errcode = '22023';
  end if;

  -- Was sich seit Lenas letzter Entscheidung geaendert hat (Pflegezeilen dazwischen).
  select coalesce(jsonb_agg(e order by p.id, o), '[]') into v_aend
    from public.erklaer_pruefungen p, jsonb_array_elements(p.aenderungen) with ordinality x(e, o)
   where p.kernidee_id = k.id and p.entscheidung = 'geaendert'
     and p.id > coalesce((select d.id from public.erklaer_letzte_entscheidung(k.id) d), 0);

  if p_entscheidung = 'passt' then
    if not exists (select 1 from public.erklaer_schritt s where s.kernidee_id = k.id and s.art = 'erklaerung') then
      perform public.pruef_fehler('keine_erklaerung');
    end if;
    if k.status = 'freigegeben'
       and not exists (select 1 from public.erklaer_schritt s where s.kernidee_id = k.id and s.status = 'entwurf') then
      perform public.pruef_fehler('freigegeben');
    end if;
    v_gruende := '{}';
    v_aend := v_aend || public.erklaer_schritte_status(k.id, '{entwurf}', 'geprueft');
    v_status := case when k.status = 'entwurf' then 'geprueft' else k.status end;
  elsif p_entscheidung = 'unsicher' then
    if v_notiz is null then perform public.pruef_fehler('notiz_fehlt'); end if;
    v_gruende := '{}';
    v_status := case when k.status = 'geprueft' then 'entwurf' else k.status end;
  else
    if k.status = 'freigegeben' then perform public.pruef_fehler('freigegeben'); end if;
    if p_entscheidung = 'passt_nicht' then
      if cardinality(v_gruende) = 0 then perform public.pruef_fehler('grund_fehlt'); end if;
      if exists (select 1 from unnest(v_gruende) g where g not in (
                   'fachlich_falsch', 'unklar', 'zu_lang', 'sprache_klassenstufe', 'formel_bild_fehlerhaft',
                   'variante_fehlbild', 'check_passt_nicht', 'sonstiges')) then
        perform public.pruef_fehler('grund_unbekannt');
      end if;
      if 'sonstiges' = any (v_gruende) and v_notiz is null then perform public.pruef_fehler('notiz_fehlt'); end if;
    else
      if public.erklaer_lena_stand(k) = 'offen' then perform public.pruef_fehler('nicht_bewertet'); end if;
      v_gruende := '{}';
    end if;
    v_status := 'entwurf';
  end if;

  -- Eine gepruefte Kernidee, die zurueck auf entwurf faellt, nimmt ihre gepruefte Schritte mit.
  if k.status = 'geprueft' and v_status = 'entwurf' then
    v_aend := v_aend || public.erklaer_schritte_status(k.id, '{geprueft}', 'entwurf');
  end if;
  if v_status is distinct from k.status then
    update public.erklaer_kernidee set status = v_status where id = k.id;
    v_aend := v_aend || jsonb_build_array(
      public.erklaer_aenderung('kernidee', null, null, 'status', to_jsonb(k.status), to_jsonb(v_status)));
  end if;

  perform public.erklaer_version_hoch(k.id);
  perform public.erklaer_protokollieren(k.id, p_entscheidung, v_aend, v_gruende, v_notiz);
  select * into k from public.erklaer_kernidee where id = k.id;
  return jsonb_build_object('pruef_version', k.pruef_version, 'status', k.status,
                            'stand', public.erklaer_lena_stand(k));
end;
$$;

create function public.erklaer_freigeben(p_kernidee_id uuid, p_pruef_version bigint)
returns jsonb
language plpgsql volatile
security definer
set search_path = public, pg_temp
as $$
declare
  k       public.erklaer_kernidee;
  v_fehlt jsonb;
  v_aend  jsonb;
begin
  if p_pruef_version is null then
    raise exception 'erklaer_freigeben: pruef_version ist Pflicht' using errcode = '22023';
  end if;
  k := public.erklaer_pruef_sperren(p_kernidee_id, p_pruef_version, true);
  if k.status = 'freigegeben'
     and not exists (select 1 from public.erklaer_schritt s where s.kernidee_id = k.id and s.status <> 'freigegeben') then
    perform public.pruef_fehler('freigegeben');
  end if;
  v_fehlt := public.erklaer_freigabe_fehlt(k.id);
  if jsonb_array_length(v_fehlt) > 0 then
    raise exception 'erklaer_freigeben: Freigabe unvollstaendig: %', v_fehlt::text
      using errcode = 'ED422', hint = 'freigabe_unvollstaendig', detail = v_fehlt::text;
  end if;

  v_aend := public.erklaer_schritte_status(k.id, '{geprueft}', 'freigegeben');
  if k.status <> 'freigegeben' then
    update public.erklaer_kernidee set status = 'freigegeben' where id = k.id;
    v_aend := v_aend || jsonb_build_array(
      public.erklaer_aenderung('kernidee', null, null, 'status', to_jsonb(k.status), '"freigegeben"'));
  end if;
  perform public.erklaer_version_hoch(k.id);
  perform public.erklaer_protokollieren(k.id, 'freigegeben', v_aend);
  select * into k from public.erklaer_kernidee where id = k.id;
  return jsonb_build_object('pruef_version', k.pruef_version, 'status', k.status);
end;
$$;

-- Zurueck an Lena: Kernidee und alle Schritte auf entwurf, das Kind bekommt nichts mehr.
create function public.erklaer_freigabe_zuruecknehmen(p_kernidee_id uuid, p_grund text, p_pruef_version bigint)
returns jsonb
language plpgsql volatile
security definer
set search_path = public, pg_temp
as $$
declare
  k       public.erklaer_kernidee;
  v_grund text := nullif(btrim(p_grund), '');
  v_aend  jsonb;
begin
  if p_pruef_version is null then
    raise exception 'erklaer_freigabe_zuruecknehmen: pruef_version ist Pflicht' using errcode = '22023';
  end if;
  k := public.erklaer_pruef_sperren(p_kernidee_id, p_pruef_version, true);
  if k.status <> 'freigegeben' then perform public.pruef_fehler('nicht_freigegeben'); end if;
  if v_grund is null then perform public.pruef_fehler('grund_fehlt'); end if;

  v_aend := public.erklaer_schritte_status(k.id, '{geprueft,freigegeben}', 'entwurf');
  update public.erklaer_kernidee set status = 'entwurf' where id = k.id;
  v_aend := v_aend || jsonb_build_array(
    public.erklaer_aenderung('kernidee', null, null, 'status', '"freigegeben"', '"entwurf"'));
  perform public.erklaer_version_hoch(k.id);
  perform public.erklaer_protokollieren(k.id, 'freigabe_zurueck', v_aend, '{}', v_grund);
  select * into k from public.erklaer_kernidee where id = k.id;
  return jsonb_build_object('pruef_version', k.pruef_version, 'status', k.status);
end;
$$;

-- Antwort auf Lenas Rueckfrage. Aendert keinen Inhalt und keine Version; die Kernidee ist danach
-- wieder offen fuer Lena (erklaer_lena_stand).
create function public.erklaer_rueckfrage_beantworten(p_kernidee_id uuid, p_antwort text)
returns jsonb
language plpgsql volatile
security definer
set search_path = public, pg_temp
as $$
declare
  k         public.erklaer_kernidee;
  d         public.erklaer_pruefungen;
  v_antwort text := nullif(btrim(p_antwort), '');
begin
  k := public.erklaer_pruef_sperren(p_kernidee_id, null, true);
  if v_antwort is null then perform public.pruef_fehler('antwort_fehlt'); end if;
  d := public.erklaer_letzte_entscheidung(k.id);
  if d.id is null or d.entscheidung <> 'unsicher' or d.antwort is not null then
    perform public.pruef_fehler('keine_rueckfrage');
  end if;
  update public.erklaer_pruefungen
     set antwort = v_antwort, beantwortet_von = auth.uid(), beantwortet_am = clock_timestamp()
   where id = d.id;
  return jsonb_build_object('pruef_version', k.pruef_version, 'stand', public.erklaer_lena_stand(k));
end;
$$;

comment on function public.erklaer_pruefen(uuid, text, text[], text, bigint) is
  'Lenas Pruefung einer Kernidee als Ganzes (passt, unsicher, passt_nicht, zurueckgenommen). Pruefer und Admin. Protokolliert.';
comment on function public.erklaer_freigeben(uuid, bigint) is
  'Freigabe einer Kernidee mit ihren Schritten. Nur Admin, nur wenn erklaer_freigabe_fehlt leer ist. Protokolliert.';
comment on function public.erklaer_freigabe_zuruecknehmen(uuid, text, bigint) is
  'Nimmt die Freigabe einer Kernidee mit Grund zurueck (Kernidee und Schritte -> entwurf). Nur Admin. Protokolliert.';

revoke all on function public.erklaer_pruef_sperren(uuid, bigint, boolean) from public, anon, authenticated;
revoke all on function public.erklaer_schritte_status(uuid, text[], text) from public, anon, authenticated;
revoke all on function public.erklaer_pruefen(uuid, text, text[], text, bigint) from public, anon, authenticated;
revoke all on function public.erklaer_freigeben(uuid, bigint) from public, anon, authenticated;
revoke all on function public.erklaer_freigabe_zuruecknehmen(uuid, text, bigint) from public, anon, authenticated;
revoke all on function public.erklaer_rueckfrage_beantworten(uuid, text) from public, anon, authenticated;
grant execute on function public.erklaer_pruefen(uuid, text, text[], text, bigint) to authenticated;
grant execute on function public.erklaer_freigeben(uuid, bigint) to authenticated;
grant execute on function public.erklaer_freigabe_zuruecknehmen(uuid, text, bigint) to authenticated;
grant execute on function public.erklaer_rueckfrage_beantworten(uuid, text) to authenticated;
