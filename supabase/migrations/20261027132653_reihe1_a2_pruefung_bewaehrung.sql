-- Reihe 1 · A2.3–A2.5 Pruefung je Bauform, Sammelfreigabe, Meldungen, Bewaehrung (Konzept §6).
--
--   bauform_pruefen(p_bauform, p_version, p_entscheidung, p_gruende, p_notiz, p_dauer_sek)   Lena oder Admin
--       passt → zur_freigabe, unsicher → rueckfrage (Notiz Pflicht), passt_nicht → beanstandet (Grund Pflicht)
--   bauform_freigeben(p_reihe, p_thema_key)   Admin: alle Bauformen "zur_freigabe" der Reihe bzw. des Themas →
--       freigegeben; ihre gruenen Instanzen der aktuellen Version werden ready (Hinweise geprueft, protokolliert)
--   bauform_zur_ueberarbeitung(p_bauform, p_grund), aufgabe_reaktivieren(p_task), bauform_reaktivieren(p_bauform,
--       p_grund)   Lena oder Admin (Reiter Auffaellig)
--   aufgabe_melden(p_task, p_grund)   Coach oder Admin: pausiert die Instanz sofort; zwei gemeldete Instanzen einer
--       Bauform pausieren die Bauform
--   Bewaehrung: Trigger nach jeder gespeicherten Session-Antwort (kein pg_cron, A0 §8). Zaehler je Instanz; nach
--       bewaehrung_bearbeitungen Bearbeitungen: eine falsche Antwort ohne Fehlbild in mindestens
--       bewaehrung_unbekannt_anteil der Faelle → auffaellig (pausiert, im Board), sonst bewaehrt.
--   bauform_stufen_vorschlag(p_bauform)   Erfolgsquote je Stufe gegen das Erwartungsband; Lena entscheidet.
-- Die Wertungsfunktionen schreiben nie; Zaehler entstehen nur aus gespeicherten Session-Antworten.

-- Stellschrauben (Startwerte Konzept §6), im Muster session_einstellungen (Admins aendern mit Grund).
insert into public.session_einstellungen (schluessel, beschreibung, typ, wert, startwert, min, max, ganzzahl, einheit)
values
  ('bewaehrung_bearbeitungen', 'Bewährung: so viele Bearbeitungen, bevor eine Instanz als bewährt oder auffällig gilt',
   'zahl', '10', '10', 3, 50, true, 'anzahl'),
  ('bewaehrung_unbekannt_anteil', 'Bewährung: Anteil derselben falschen Antwort ohne Fehlbild, ab dem eine Instanz auffällig ist',
   'zahl', '0.30', '0.30', 0.10, 0.60, false, 'anteil'),
  ('bewaehrung_band_eins_min', 'Erwartungsband Stufe 1: Erfolgsquote mindestens', 'zahl', '0.85', '0.85', 0.50, 1, false, 'anteil'),
  ('bewaehrung_band_zwei_min', 'Erwartungsband Stufe 2: Erfolgsquote mindestens', 'zahl', '0.70', '0.70', 0.30, 1, false, 'anteil'),
  ('bewaehrung_band_zwei_max', 'Erwartungsband Stufe 2: Erfolgsquote höchstens', 'zahl', '0.95', '0.95', 0.50, 1, false, 'anteil'),
  ('bewaehrung_band_drei_min', 'Erwartungsband Stufe 3: Erfolgsquote mindestens', 'zahl', '0.55', '0.55', 0.20, 1, false, 'anteil'),
  ('bewaehrung_band_drei_max', 'Erwartungsband Stufe 3: Erfolgsquote höchstens', 'zahl', '0.90', '0.90', 0.40, 1, false, 'anteil'),
  ('bewaehrung_band_vier_min', 'Erwartungsband Stufe 4: Erfolgsquote mindestens', 'zahl', '0.40', '0.40', 0.10, 1, false, 'anteil'),
  ('bewaehrung_band_vier_max', 'Erwartungsband Stufe 4: Erfolgsquote höchstens', 'zahl', '0.85', '0.85', 0.30, 1, false, 'anteil'),
  ('bewaehrung_band_fuenf_min', 'Erwartungsband Stufe 5: Erfolgsquote mindestens', 'zahl', '0.25', '0.25', 0, 1, false, 'anteil'),
  ('bewaehrung_band_fuenf_max', 'Erwartungsband Stufe 5: Erfolgsquote höchstens', 'zahl', '0.75', '0.75', 0.20, 1, false, 'anteil')
on conflict (schluessel) do nothing;

create function public.reihe1_wert(p_schluessel text)
returns numeric language sql stable security definer set search_path = public, pg_temp as $$
  select (wert #>> '{}')::numeric from public.session_einstellungen where schluessel = p_schluessel
$$;

create function public.bauform_pruefen(p_bauform uuid, p_version int, p_entscheidung text, p_gruende text[] default '{}',
                                       p_notiz text default null, p_dauer_sek int default null)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  b public.bauformen;
  v_neu text;
begin
  if not public.darf_pruefen() then
    raise exception 'bauform_pruefen: kein Pruefrecht' using errcode = '42501';
  end if;
  select * into b from public.bauformen where id = p_bauform for update;
  if not found then
    raise exception 'bauform_pruefen: Bauform nicht gefunden' using errcode = 'P0002';
  end if;
  if b.version is distinct from p_version then
    raise exception 'bauform_pruefen: die Bauform hat sich geaendert (Version %)', b.version using errcode = 'ED409';
  end if;
  if b.status not in ('zur_pruefung', 'rueckfrage') then
    raise exception 'bauform_pruefen: Bauform steht nicht zur Pruefung (%)', b.status using errcode = 'P0001';
  end if;
  if b.verdacht is not null then
    raise exception 'bauform_pruefen: Bauform ist verdaechtig (%)', b.verdacht using errcode = 'P0001';
  end if;
  -- Konzept §6: ohne gruene Pruefmaschine und bestandenen Blindloeser der aktuellen Version sieht Lena sie nicht.
  if b.pruefprotokoll ->> 'lauf_am' is null or coalesce((b.pruefprotokoll ->> 'rot_anteil')::numeric, 1) > 0.30
     or coalesce(b.blindloeser ->> 'bestanden', '') <> 'true' then
    raise exception 'bauform_pruefen: Pruefmaschine oder Blindloeser fehlen fuer Version %', b.version
      using errcode = 'P0001', hint = 'pruefung_fehlt';
  end if;
  case p_entscheidung
    when 'passt' then v_neu := 'zur_freigabe';
    when 'unsicher' then
      if coalesce(btrim(p_notiz), '') = '' then
        raise exception 'bauform_pruefen: unsicher braucht eine Notiz' using errcode = '22023';
      end if;
      v_neu := 'rueckfrage';
    when 'passt_nicht' then
      if cardinality(coalesce(p_gruende, '{}')) = 0 then
        raise exception 'bauform_pruefen: passt nicht braucht einen Grund' using errcode = '22023';
      end if;
      v_neu := 'beanstandet';
    else
      raise exception 'bauform_pruefen: Entscheidung passt, unsicher oder passt_nicht' using errcode = '22023';
  end case;
  insert into public.bauform_pruefungen (bauform_id, version, entscheidung, gruende, notiz, dauer_sek, geprueft_von)
  values (b.id, b.version, p_entscheidung, coalesce(p_gruende, '{}'), nullif(btrim(p_notiz), ''), p_dauer_sek, auth.uid());
  update public.bauformen set status = v_neu where id = b.id;
  return jsonb_build_object('status', v_neu, 'version', b.version);
end $$;

create function public.bauform_freigeben(p_reihe text default null, p_thema_key text default null)
returns int
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  b record;
  t record;
  n int := 0;
begin
  perform public.pruef_nur_admin('bauform_freigeben');
  if (p_reihe is null) = (p_thema_key is null) then
    raise exception 'bauform_freigeben: genau eins von Reihe oder Thema' using errcode = '22023';
  end if;
  for b in
    select x.* from public.bauformen x
     where x.status = 'zur_freigabe'
       and (x.reihe = p_reihe
            or exists (select 1 from public.skill_thema st where st.skill_key = x.skill_key and st.thema_key = p_thema_key))
     for update
  loop
    update public.bauformen set status = 'freigegeben', freigegeben_am = now(), freigegeben_von = auth.uid()
     where id = b.id;
    for t in
      select k.id from public.tasks k
       where k.bauform_id = b.id and k.bauform_version = b.version and k.status in ('draft', 'review')
         and public.instanz_gruen(k.pruefmaschine)
    loop
      update public.tasks set status = 'ready', is_active = true, reviewed_by = auth.uid(), reviewed_at = now()
       where id = t.id;
      perform public.pruef_hinweise_setzen(t.id, 'geprueft');
      insert into public.aufgabe_bewaehrung (task_id) values (t.id) on conflict do nothing;
      insert into public.task_admin_protokoll (task_id, aktion, aenderungen, grund, sammel, von)
      values (t.id, 'freigeben', '[]'::jsonb, format('Bauform %s v%s', b.schluessel, b.version), true, auth.uid());
    end loop;
    n := n + 1;
  end loop;
  return n;
end $$;

create function public.bauform_zur_ueberarbeitung(p_bauform uuid, p_grund text)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.darf_pruefen() then
    raise exception 'bauform_zur_ueberarbeitung: kein Pruefrecht' using errcode = '42501';
  end if;
  if coalesce(btrim(p_grund), '') = '' then
    raise exception 'bauform_zur_ueberarbeitung: Grund fehlt' using errcode = '22023';
  end if;
  insert into public.bauform_pruefungen (bauform_id, version, entscheidung, gruende, notiz, geprueft_von)
  select id, version, 'passt_nicht', array['ueberarbeitung'], btrim(p_grund), auth.uid()
    from public.bauformen where id = p_bauform;
  update public.bauformen set status = 'beanstandet' where id = p_bauform;
end $$;

create function public.aufgabe_reaktivieren(p_task uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.darf_pruefen() then
    raise exception 'aufgabe_reaktivieren: kein Pruefrecht' using errcode = '42501';
  end if;
  -- Die Zaehler beginnen neu; die Antworten selbst bleiben in session_antworten.
  insert into public.aufgabe_bewaehrung (task_id) values (p_task)
  on conflict (task_id) do update set bearbeitungen = 0, richtig = 0, fehlbild_zaehler = '{}', unbekannt = '{}',
                                      haeufigste_unbekannte = null, status = 'in_bewaehrung', grund = null,
                                      geaendert_am = now();
end $$;

-- Eine pausierte Bauform wieder ziehbar machen (Meldung unberechtigt). War sie freigegeben, gilt die Freigabe wieder
-- (neue Zaehlung der Meldungen ab jetzt); sonst steht sie wieder zur Pruefung.
create function public.bauform_reaktivieren(p_bauform uuid, p_grund text)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  b public.bauformen;
  v_neu text;
begin
  if not public.darf_pruefen() then
    raise exception 'bauform_reaktivieren: kein Pruefrecht' using errcode = '42501';
  end if;
  if coalesce(btrim(p_grund), '') = '' then
    raise exception 'bauform_reaktivieren: Grund fehlt' using errcode = '22023';
  end if;
  select * into b from public.bauformen where id = p_bauform for update;
  if b.status is distinct from 'pausiert' then
    raise exception 'bauform_reaktivieren: Bauform ist nicht pausiert' using errcode = 'P0001';
  end if;
  v_neu := case when b.freigegeben_am is not null then 'freigegeben' else 'zur_pruefung' end;
  insert into public.bauform_pruefungen (bauform_id, version, entscheidung, notiz, geprueft_von)
  values (b.id, b.version, 'reaktiviert', btrim(p_grund), auth.uid());
  update public.bauformen set status = v_neu,
         freigegeben_am = case when v_neu = 'freigegeben' then now() else freigegeben_am end
   where id = b.id;
  return v_neu;
end $$;

create function public.aufgabe_melden(p_task uuid, p_grund text)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_bauform uuid;
begin
  if not (public.ist_systemaufruf() or coalesce(public.get_my_role(), '') in ('coach', 'admin')) then
    raise exception 'aufgabe_melden: nur Coach oder Admin' using errcode = '42501';
  end if;
  if coalesce(btrim(p_grund), '') = '' then
    raise exception 'aufgabe_melden: Grund fehlt' using errcode = '22023';
  end if;
  select bauform_id into v_bauform from public.tasks where id = p_task;
  if not found then
    raise exception 'aufgabe_melden: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  insert into public.aufgabe_meldungen (task_id, grund, von) values (p_task, btrim(p_grund), auth.uid());
  insert into public.aufgabe_bewaehrung (task_id, status, grund) values (p_task, 'pausiert', 'gemeldet')
  on conflict (task_id) do update set status = 'pausiert', grund = 'gemeldet', geaendert_am = now();
  if v_bauform is not null then
    -- Sperre gegen zwei gleichzeitige Meldungen (beide zaehlten sonst nur 1). Gezaehlt werden gemeldete Instanzen
    -- der aktuellen Version seit der letzten Freigabe.
    perform 1 from public.bauformen where id = v_bauform for update;
    if (select count(distinct m.task_id)
          from public.aufgabe_meldungen m
          join public.tasks t on t.id = m.task_id
          join public.bauformen b on b.id = t.bauform_id
         where t.bauform_id = v_bauform and t.bauform_version = b.version
           and m.am >= coalesce(b.freigegeben_am, '-infinity')) >= 2 then
      update public.bauformen set status = 'pausiert' where id = v_bauform and status <> 'pausiert';
    end if;
  end if;
end $$;

-- Bewaehrung nach jeder gespeicherten Session-Antwort einer Bauform-Instanz (nicht im Testlauf). Bei Mehrteilern zaehlt
-- der erste Teil als Bearbeitung.
create function public.bewaehrung_nach_antwort()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  w public.aufgabe_bewaehrung;
  v_antwort text;
  v_top text;
  v_top_n int;
begin
  if not exists (select 1 from public.tasks t where t.id = new.task_id and t.bauform_id is not null)
     or coalesce((select cs.testlauf from public.coaching_sessions cs where cs.id = new.session_id), false)
     or coalesce(new.teil, 1) <> 1 or new.versuch_nr <> 1 then
    return new;
  end if;
  -- Die Bewaehrung darf nie eine Antwort verhindern: jeder Fehler hier wird nur gemeldet (Befund 1).
  begin
  insert into public.aufgabe_bewaehrung (task_id) values (new.task_id) on conflict do nothing;
  select * into w from public.aufgabe_bewaehrung where task_id = new.task_id for update;
  w.bearbeitungen := w.bearbeitungen + 1;
  if new.ergebnis = 'richtig' then
    w.richtig := w.richtig + 1;
  elsif new.fehlbild_slug is not null and new.fehlbild_slug <> '__known__' then
    w.fehlbild_zaehler := jsonb_set(w.fehlbild_zaehler, array[new.fehlbild_slug],
                                    to_jsonb(coalesce((w.fehlbild_zaehler ->> new.fehlbild_slug)::int, 0) + 1));
  elsif new.ergebnis = 'falsch' and new.fehlbild_slug is null then
    -- Nur eine falsche Antwort ohne jedes Fehlbild ist "unbekannt"; teilweise und bekannte Fehler nicht (Befund 7).
    v_antwort := coalesce(public.lsa_normalize_answer(new.eingabe ->> 'text'), new.eingabe::text, '∅');
    w.unbekannt := jsonb_set(w.unbekannt, array[v_antwort],
                             to_jsonb(coalesce((w.unbekannt ->> v_antwort)::int, 0) + 1));
  end if;
  select e.key, (e.value #>> '{}')::int into v_top, v_top_n
    from jsonb_each(w.unbekannt) e order by (e.value #>> '{}')::int desc, e.key limit 1;
  w.haeufigste_unbekannte := v_top;
  if w.status in ('in_bewaehrung', 'bewaehrt')
     and w.bearbeitungen >= coalesce(public.reihe1_wert('bewaehrung_bearbeitungen'), 10) then
    if coalesce(v_top_n, 0)::numeric / w.bearbeitungen >= coalesce(public.reihe1_wert('bewaehrung_unbekannt_anteil'), 0.30) then
      w.status := 'auffaellig';
      w.grund := 'unbekannte_antwort';
    elsif w.status = 'in_bewaehrung' then
      w.status := 'bewaehrt';
    end if;
  end if;
  update public.aufgabe_bewaehrung
     set bearbeitungen = w.bearbeitungen, richtig = w.richtig, fehlbild_zaehler = w.fehlbild_zaehler,
         unbekannt = w.unbekannt, haeufigste_unbekannte = w.haeufigste_unbekannte, status = w.status,
         grund = w.grund, geaendert_am = now()
   where task_id = new.task_id;
  exception when others then
    raise warning 'bewaehrung_nach_antwort: % (Antwort % bleibt gespeichert)', sqlerrm, new.id;
  end;
  return new;
end $$;
create trigger session_antworten_bewaehrung after insert on public.session_antworten
  for each row execute function public.bewaehrung_nach_antwort();

create function public.bauform_stufen_vorschlag(p_bauform uuid)
returns table (stufe int, bearbeitungen int, quote numeric, band_min numeric, band_max numeric, vorschlag text)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.darf_pruefen() then
    raise exception 'bauform_stufen_vorschlag: kein Pruefrecht' using errcode = '42501';
  end if;
  return query
  with je as (
    select t.stufe::int s, sum(w.bearbeitungen)::int n, sum(w.richtig)::int r
      from public.tasks t join public.aufgabe_bewaehrung w on w.task_id = t.id
      join public.bauformen b on b.id = t.bauform_id
     where t.bauform_id = p_bauform and t.bauform_version = b.version
     group by t.stufe
  ), band as (
    select s, public.reihe1_wert('bewaehrung_band_' || w || '_min') lo,
           case when s = 1 then 1 else public.reihe1_wert('bewaehrung_band_' || w || '_max') end hi
      from (values (1, 'eins'), (2, 'zwei'), (3, 'drei'), (4, 'vier'), (5, 'fuenf')) v(s, w)
  )
  select je.s, je.n, round(je.r::numeric / nullif(je.n, 0), 2), band.lo, band.hi,
         case when je.n < coalesce(public.reihe1_wert('bewaehrung_bearbeitungen'), 10) then null
              when je.r::numeric / je.n < band.lo then 'leichter'
              when je.r::numeric / je.n > band.hi then 'schwerer' end
    from je join band on band.s = je.s
   order by je.s;
end $$;

do $$
declare f text;
begin
  foreach f in array array['reihe1_wert(text)', 'bewaehrung_nach_antwort()'] loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
  end loop;
  foreach f in array array[
    'bauform_pruefen(uuid,int,text,text[],text,int)', 'bauform_freigeben(text,text)',
    'bauform_zur_ueberarbeitung(uuid,text)', 'aufgabe_reaktivieren(uuid)', 'aufgabe_melden(uuid,text)',
    'bauform_stufen_vorschlag(uuid)', 'bauform_reaktivieren(uuid,text)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
    execute format('comment on function public.%s is %L', f, 'reihe1 fertig');
  end loop;
end $$;
