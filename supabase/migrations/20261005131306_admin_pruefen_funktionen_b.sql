-- Admin-Pruefansicht, Migration 2b: Sammelaktionen (Bauauftrag G7)
--
-- pruef_sammel(p_aktion, p_task_ids, p_werte, p_nur_vorschau) -> {betrifft: uuid[], ausgelassen: [{task_id, grund, text}]}
--   Nur admin (42501). Vorschau und Ausfuehrung laufen durch denselben Code: pruef_sammel_grund entscheidet je
--   Aufgabe, ob sie betroffen ist; bei p_nur_vorschau wird nichts geschrieben. Je Aufgabe ein eigener
--   BEGIN ... EXCEPTION-Block: scheitert eine Aufgabe, landet sie mit Grund in "ausgelassen", der Rest laeuft
--   weiter. Die Gruende sind feste Schluessel, die Texte uebersetzt das Frontend.
--   Jede geaenderte Aufgabe bekommt dasselbe wie bei der Einzelaktion (Status-Stempel, Ausgangsfassung) und eine
--   Zeile im Admin-Protokoll mit sammel = true; grund aus p_werte.grund, sonst null (an_lena: sonst Nachricht).
-- Aktionen und Auslass-Gruende:
--   freigeben      schon_freigegeben, vera8, rueckfrage_offen, team_beanstandet, lena_passt_nicht,
--                  noch_nicht_bewertet, geaendert, befund (text = Gate-Text). Nimmt genau, was freigabe_thema
--                  nimmt: review, pruef_freigabe_erlaubt, ohne Gate-Befund, nicht VERA8.
--   an_lena        freigegeben, nicht_bei_lena (text = Grund), schon_offen. p_werte.nachricht wie G3.
--   pilot_an       nicht_bei_lena (text = Grund), schon_im_pilot.     pilot_aus  nicht_im_pilot.
--   ausschliessen  schon_ausgeschlossen (vera8, inaktiv, typ, hand; text = Grund), freigegeben. p_werte.grund Pflicht (ED422 grund_fehlt).
--   aufnehmen      nicht_von_hand (text = berechneter Grund), schon_drin.
--   fertigkeit     freigegeben, ausgeschlossen (text = Grund), schon_gesetzt, nicht_erlaubt. p_werte.skill_key.
--   afb            freigegeben, ausgeschlossen (text = Grund), schon_gesetzt. p_werte.afb in (I, II, III).
--   Fertigkeit und AFB schreiben ueber dieselben Bausteine wie pruef_speichern: Ausgangsfassung sichern,
--   pruef_entwurf_anwenden mit einem Teil-Entwurf ({skill_key} bzw. {afb}), sondierrang wie dort.
--   Fehler beim Schreiben: ED422 -> grund = HINT, beim Freigeben P0001 (Gate) -> befund, sonst fehler; text = Meldung.

-- ── Warum eine Aufgabe ausgelassen wird (NULL = betroffen). Schreibt nichts. ─
create or replace function public.pruef_sammel_grund(p_aktion text, t public.tasks, p_werte jsonb)
returns jsonb language plpgsql stable set search_path = public, pg_temp as $$
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
end $$;

-- ── Die Wirkung je Aufgabe, gleich der Einzelaktion ─────────────────────────
create or replace function public.pruef_sammel_schreiben(p_aktion text, t public.tasks, p_werte jsonb)
returns void language plpgsql set search_path = public, pg_temp as $$
declare
  grund text := nullif(btrim(p_werte ->> 'grund'), '');
  aus jsonb; jetzt jsonb; neu jsonb; danach public.tasks;
begin
  if p_aktion = 'freigeben' then
    perform public.task_status_set(t.id, 'ready');
    perform public.pruef_protokoll(t.id, 'freigeben', '[]', grund, true);
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
end $$;

-- ── G7 · Sammelaktion mit Vorschau ──────────────────────────────────────────
create or replace function public.pruef_sammel(
  p_aktion text, p_task_ids uuid[], p_werte jsonb default '{}', p_nur_vorschau boolean default true)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  w jsonb := coalesce(p_werte, '{}');
  betrifft uuid[] := '{}';
  ausgelassen jsonb := '[]';
  v_id uuid; t public.tasks; g jsonb; st text; h text; m text;
begin
  perform public.pruef_nur_admin('pruef_sammel');
  if p_aktion is null or p_aktion not in ('freigeben', 'an_lena', 'pilot_an', 'pilot_aus', 'ausschliessen',
                                          'aufnehmen', 'fertigkeit', 'afb') then
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
end $$;

revoke all on function public.pruef_sammel_grund(text, public.tasks, jsonb),
  public.pruef_sammel_schreiben(text, public.tasks, jsonb)
  from public, anon, authenticated;
revoke all on function public.pruef_sammel(text, uuid[], jsonb, boolean) from public, anon, authenticated;
grant execute on function public.pruef_sammel(text, uuid[], jsonb, boolean) to authenticated;
