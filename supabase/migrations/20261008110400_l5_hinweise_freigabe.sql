-- L5.1 Kinder-Hinweise pruefen und freigeben, Teil 4: Freigabewege und "Hinweise bestaetigen".
--
-- Grundlage jeder ersetzten Funktion ist die Prod-Fassung (pg_get_functiondef, dbread 06.10.2026).
-- Entscheidung 2: Die Freigabe einer Aufgabe durch einen Admin setzt alle ihre Kinder-Hinweise auf
-- geprueft (pruef_admin_freigeben, pruef_rueckfrage_klaeren 'freigeben', pruef_sammel 'freigeben').
-- Die Ruecknahme setzt sie zurueck auf entwurf (pruef_freigabe_zuruecknehmen, freigabe_zuruecknehmen).
-- Entscheidung 5: hinweise_bestaetigen(task_id) fuer schon freigegebene Aufgaben (nur admin,
-- protokolliert), dazu die Sammelaktion pruef_sammel('hinweise_bestaetigen', …) mit Vorschau.
-- Nicht beruehrt (offene Punkte L5): task_status_set aus dem Editor, freigabe_thema/_cluster/_muster.
-- Dort bleiben die Hinweise, wie sie sind; "Hinweise bestaetigen" holt sie nach.

create function public.hinweise_bestaetigen(p_task_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  t public.tasks;
  v_aend jsonb;
begin
  perform public.pruef_nur_admin('hinweise_bestaetigen');
  select * into t from public.tasks where id = p_task_id for update;
  if not found then
    raise exception 'hinweise_bestaetigen: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if t.status <> 'ready' then perform public.pruef_fehler('nicht_freigegeben'); end if;
  if not public.hinweise_offen(p_task_id) then perform public.pruef_fehler('keine_hinweise_offen'); end if;
  v_aend := public.pruef_hinweise_setzen(p_task_id, 'geprueft');
  perform public.pruef_protokoll(p_task_id, 'hinweise_bestaetigen', v_aend, null, false);
  return jsonb_build_object('status', t.status, 'aenderungen', v_aend);
end;
$$;

comment on function public.hinweise_bestaetigen(uuid) is
  'L5: Kinder-Hinweise einer freigegebenen Aufgabe auf geprueft setzen. Nur admin, protokolliert.';

-- Prod-Fassung + Hinweise geprueft (L5). Rolle: pruef_nur_admin (is distinct from, NULL-sicher).
CREATE OR REPLACE FUNCTION public.pruef_admin_freigeben(p_task_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare t public.tasks;
begin
  perform public.pruef_nur_admin('pruef_admin_freigeben');
  select * into t from public.tasks where id = p_task_id for update;
  if not found then
    raise exception 'pruef_admin_freigeben: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if t.status = 'ready' then perform public.pruef_fehler('freigegeben'); end if;
  perform public.task_status_set(p_task_id, 'ready');
  perform public.pruef_hinweise_setzen(p_task_id, 'geprueft');  -- L5 Entscheidung 2
  perform public.pruef_protokoll(p_task_id, 'freigeben', '[]', null, false);
  return jsonb_build_object('status', 'ready');
end $function$;

-- Prod-Fassung + Hinweise zurueck auf entwurf (L5). Rolle: pruef_nur_admin.
CREATE OR REPLACE FUNCTION public.pruef_freigabe_zuruecknehmen(p_task_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare t public.tasks;
begin
  perform public.pruef_nur_admin('pruef_freigabe_zuruecknehmen');
  select * into t from public.tasks where id = p_task_id for update;
  if not found then
    raise exception 'pruef_freigabe_zuruecknehmen: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if t.status <> 'ready' then perform public.pruef_fehler('nicht_freigegeben'); end if;
  perform public.task_status_set(p_task_id, 'draft');
  perform public.pruef_hinweise_setzen(p_task_id, 'entwurf');  -- L5 Entscheidung 2
  perform public.pruef_protokoll(p_task_id, 'freigabe_zurueck', '[]', null, false);
  return jsonb_build_object('status', 'draft');
end $function$;

-- Prod-Fassung + Hinweise zurueck auf entwurf (L5). Rolle: is distinct from 'admin' (NULL-sicher).
CREATE OR REPLACE FUNCTION public.freigabe_zuruecknehmen(p_skill_key text)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_n   integer;
  v_ids uuid[];
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'A21: nur die fachliche Freigabe (admin) darf Freigaben zuruecknehmen'
      using errcode = '42501';
  end if;

  with z as (
    update public.tasks
       set status      = 'draft',
           reviewed_by = null,
           reviewed_at = null
     where skill_key = p_skill_key
       and status    = 'ready'
    returning id)
  select array_agg(id) into v_ids from z;

  v_n := coalesce(cardinality(v_ids), 0);
  -- L5 Entscheidung 2: die Ruecknahme setzt die Kinder-Hinweise zurueck auf entwurf.
  perform public.pruef_hinweise_setzen(x, 'entwurf') from unnest(coalesce(v_ids, '{}')) x;
  return v_n;
end $function$;

-- Prod-Fassung + Hinweise geprueft bei Freigabe (L5). Rolle: is distinct from 'admin'.
CREATE OR REPLACE FUNCTION public.pruef_rueckfrage_klaeren(p_task_id uuid, p_aktion text, p_antwort text, p_gruende text[] DEFAULT NULL::text[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
    perform public.pruef_hinweise_setzen(p_task_id, 'geprueft');  -- L5 Entscheidung 2
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
end $function$;

-- Prod-Fassung + Aktion hinweise_bestaetigen (L5). Rolle: pruef_nur_admin.
CREATE OR REPLACE FUNCTION public.pruef_sammel(p_aktion text, p_task_ids uuid[], p_werte jsonb DEFAULT '{}'::jsonb, p_nur_vorschau boolean DEFAULT true)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  w jsonb := coalesce(p_werte, '{}');
  betrifft uuid[] := '{}';
  ausgelassen jsonb := '[]';
  v_id uuid; t public.tasks; g jsonb; st text; h text; m text;
begin
  perform public.pruef_nur_admin('pruef_sammel');
  if p_aktion is null or p_aktion not in ('freigeben', 'an_lena', 'pilot_an', 'pilot_aus', 'ausschliessen',
                                          'aufnehmen', 'fertigkeit', 'afb', 'hinweise_bestaetigen') then
    raise exception 'pruef_sammel: unbekannte Aktion %', p_aktion using errcode = '22023';
  end if;
  -- Eingaben, ohne die die Aktion fuer keine Aufgabe Sinn ergibt: Fehler fuer den ganzen Aufruf.
  if p_aktion = 'fertigkeit' and coalesce(btrim(w ->> 'skill_key'), '') = '' then
    perform public.pruef_fehler('wert_fehlt');
  end if;
  if p_aktion = 'afb' and coalesce(w ->> 'afb', '') not in ('I', 'II', 'III') then
    perform public.pruef_fehler('afb_ungueltig');
  end if;
  -- Der Grund wird erst zum Schreiben gebraucht; die Vorschau zeigt schon vorher, was die Aktion trifft.
  if p_aktion = 'ausschliessen' and not coalesce(p_nur_vorschau, true)
     and coalesce(btrim(w ->> 'grund'), '') = '' then
    perform public.pruef_fehler('grund_fehlt');
  end if;

  for v_id in select u.x from unnest(coalesce(p_task_ids, '{}')) with ordinality u(x, i)
               where u.x is not null group by u.x order by min(u.i) loop
    begin
      select * into t from public.tasks where id = v_id for update;
      if not found then
        g := jsonb_build_object('grund', 'nicht_gefunden');
      else
        g := public.pruef_sammel_grund(p_aktion, t, w);
        if g is null and not coalesce(p_nur_vorschau, true) then
          perform public.pruef_sammel_schreiben(p_aktion, t, w);
        end if;
      end if;
    exception when others then
      get stacked diagnostics st = returned_sqlstate, h = pg_exception_hint, m = message_text;
      g := jsonb_build_object(
        'grund', case when st = 'ED422' and coalesce(h, '') <> '' then h
                      when st = 'P0001' and p_aktion = 'freigeben' then 'befund' else 'fehler' end,
        'text', m);
    end;
    if g is null then
      betrifft := betrifft || v_id;
    else
      ausgelassen := ausgelassen || jsonb_build_array(jsonb_build_object('task_id', v_id) || g);
    end if;
  end loop;

  return jsonb_build_object('betrifft', to_jsonb(betrifft), 'ausgelassen', ausgelassen);
end $function$;

-- Prod-Fassung + hinweise_bestaetigen (L5).
CREATE OR REPLACE FUNCTION public.pruef_sammel_grund(p_aktion text, t tasks, p_werte jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  aus text := public.pruef_ausschluss(t.id);
  lp public.task_pruefungen;
  gate text;
  basis text;
begin
  if p_aktion = 'freigeben' then
    if t.status = 'ready' then return jsonb_build_object('grund', 'schon_freigegeben'); end if;
    if t.source = 'VERA8_IQB' then return jsonb_build_object('grund', 'vera8'); end if;
    if t.status = 'rueckfrage' then return jsonb_build_object('grund', 'rueckfrage_offen'); end if;
    if t.status = 'beanstandet' then
      return jsonb_build_object('grund', case when public.pruef_team_beanstandet(t.id)
                                              then 'team_beanstandet' else 'lena_passt_nicht' end);
    end if;
    select * into lp from public.task_pruefungen p where p.task_id = t.id order by p.geprueft_am desc limit 1;
    if t.status <> 'review' or lp.id is null or lp.entscheidung <> 'passt' then
      return jsonb_build_object('grund', 'noch_nicht_bewertet');
    end if;
    -- Eine fruehere Admin-Beanstandung ueberstimmt Lenas spaeteres "Passt" nicht still (Lena-Board OP-9).
    if exists (select 1 from public.task_reviews r left join public.profiles pr on pr.id = r.geprueft_von
                where r.task_id = t.id and (r.geprueft_von is null or pr.role = 'admin')) then
      return jsonb_build_object('grund', 'team_beanstandet');
    end if;
    if not public.pruef_freigabe_erlaubt(t.id) then return jsonb_build_object('grund', 'geaendert'); end if;
    gate := public.freigabe_gate_fehler(t.id);
    if gate is not null then return jsonb_build_object('grund', 'befund', 'text', gate); end if;
  elsif p_aktion = 'hinweise_bestaetigen' then
    if t.status <> 'ready' then return jsonb_build_object('grund', 'nicht_freigegeben'); end if;
    if not public.hinweise_offen(t.id) then return jsonb_build_object('grund', 'keine_hinweise_offen'); end if;
  elsif p_aktion = 'an_lena' then
    if t.status = 'ready' then return jsonb_build_object('grund', 'freigegeben'); end if;
    if aus is not null then return jsonb_build_object('grund', 'nicht_bei_lena', 'text', aus); end if;
    if t.status = 'draft' and not public.pruef_lena_bewertet(t.id) then
      return jsonb_build_object('grund', 'schon_offen');
    end if;
  elsif p_aktion = 'pilot_an' then
    if aus is not null then return jsonb_build_object('grund', 'nicht_bei_lena', 'text', aus); end if;
    if t.pruef_pilot then return jsonb_build_object('grund', 'schon_im_pilot'); end if;
  elsif p_aktion = 'pilot_aus' then
    if not t.pruef_pilot then return jsonb_build_object('grund', 'nicht_im_pilot'); end if;
  elsif p_aktion = 'ausschliessen' then
    -- Ein berechneter Grund (ohne Loesung, Gate …) haelt die Aufgabe nur, bis er behoben ist; von Hand
    -- herausnehmen geht deshalb trotzdem (Consensus-Check G-b). Nur feste Ausschluesse sperren.
    if aus in ('vera8', 'inaktiv', 'typ', 'hand') then
      return jsonb_build_object('grund', 'schon_ausgeschlossen', 'text', aus);
    end if;
    if t.status = 'ready' then return jsonb_build_object('grund', 'freigegeben'); end if;
  elsif p_aktion = 'aufnehmen' then
    if exists (select 1 from public.task_pruef_ausschluss h where h.task_id = t.id) then return null; end if;
    if aus is not null then return jsonb_build_object('grund', 'nicht_von_hand', 'text', aus); end if;
    return jsonb_build_object('grund', 'schon_drin');
  elsif p_aktion in ('fertigkeit', 'afb') then
    if t.status = 'ready' then return jsonb_build_object('grund', 'freigegeben'); end if;
    -- Wie pruef_sperren fuer admin: VERA8, inaktiv und fremde Typen nur ueber den Editor.
    if aus in ('vera8', 'inaktiv', 'typ') then return jsonb_build_object('grund', 'ausgeschlossen', 'text', aus); end if;
    if p_aktion = 'afb' then
      if t.afb is not distinct from p_werte ->> 'afb' then return jsonb_build_object('grund', 'schon_gesetzt'); end if;
    else
      if t.skill_key is not distinct from p_werte ->> 'skill_key' then
        return jsonb_build_object('grund', 'schon_gesetzt');
      end if;
      -- Dieselbe Auswahl wie in der Pruefkarte: Thema der Ausgangsfassung plus direkte Voraussetzungen.
      basis := coalesce((select a.ausgang ->> 'skill_key' from public.task_pruefung_ausgang a where a.task_id = t.id),
                        t.skill_key);
      if not exists (select 1 from jsonb_array_elements(public.pruef_fertigkeit_optionen(basis)) o
                      where o ->> 'key' = p_werte ->> 'skill_key') then
        return jsonb_build_object('grund', 'nicht_erlaubt');
      end if;
    end if;
  end if;
  return null;
end $function$;

-- Prod-Fassung + Freigabe mit Hinweisen und hinweise_bestaetigen (L5).
CREATE OR REPLACE FUNCTION public.pruef_sammel_schreiben(p_aktion text, t tasks, p_werte jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  grund text := nullif(btrim(p_werte ->> 'grund'), '');
  aus jsonb; jetzt jsonb; neu jsonb; danach public.tasks;
begin
  if p_aktion = 'freigeben' then
    perform public.task_status_set(t.id, 'ready');
    perform public.pruef_hinweise_setzen(t.id, 'geprueft');  -- L5 Entscheidung 2
    perform public.pruef_protokoll(t.id, 'freigeben', '[]', grund, true);
  elsif p_aktion = 'hinweise_bestaetigen' then
    perform public.pruef_protokoll(t.id, 'hinweise_bestaetigen', public.pruef_hinweise_setzen(t.id, 'geprueft'),
                                   grund, true);
  elsif p_aktion = 'an_lena' then
    perform public.pruef_an_lena_schreiben(t.id, p_werte ->> 'nachricht', grund, true);
  elsif p_aktion in ('pilot_an', 'pilot_aus') then
    update public.tasks set pruef_pilot = (p_aktion = 'pilot_an') where id = t.id;
    perform public.pruef_protokoll(t.id, p_aktion, '[]', grund, true);
  elsif p_aktion = 'ausschliessen' then
    insert into public.task_pruef_ausschluss (task_id, grund, von, am)
    values (t.id, grund, auth.uid(), clock_timestamp());
    perform public.pruef_protokoll(t.id, 'ausschliessen', '[]', grund, true);
  elsif p_aktion = 'aufnehmen' then
    delete from public.task_pruef_ausschluss where task_id = t.id;
    perform public.pruef_protokoll(t.id, 'aufnehmen', '[]', grund, true);
  elsif p_aktion in ('fertigkeit', 'afb') then
    aus := public.pruef_ausgang_sichern(t.id);
    jetzt := public.pruef_fassung(t.id);
    neu := public.pruef_entwurf_anwenden(t, jetzt, aus,
             case when p_aktion = 'fertigkeit' then jsonb_build_object('skill_key', p_werte ->> 'skill_key')
                  else jsonb_build_object('afb', p_werte ->> 'afb') end,
             (select s.option_scores from public.task_solutions s where s.task_id = t.id));
    update public.tasks
       set skill_key = neu ->> 'skill_key', afb = neu ->> 'afb', sondierrang = (neu ->> 'sondierrang')::int
     where id = t.id;
    select * into danach from public.tasks where id = t.id;
    perform public.pruef_protokoll(t.id, p_aktion,
      public.pruef_aenderungen(public.pruef_sicht(t, jetzt), public.pruef_sicht(danach, public.pruef_fassung(t.id))),
      grund, true);
  end if;
end $function$;

revoke all on function public.hinweise_bestaetigen(uuid) from public, anon, authenticated;
grant execute on function public.hinweise_bestaetigen(uuid) to authenticated;
