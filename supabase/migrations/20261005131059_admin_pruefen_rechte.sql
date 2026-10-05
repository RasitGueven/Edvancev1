-- Admin-Pruefansicht, Migration 1: admin_pruefen_rechte (Bauauftrag G1, G2)
--
-- Admins pruefen auf demselben Bildschirm wie Lena und speichern ueber dieselben pruef_*-Funktionen.
--   G1  pruef_sperren: fuer admin entfallen "nicht im Pilot" und "vom Team beanstandet". freigegeben und die
--       Ausschluesse vera8, typ, inaktiv bleiben fuer alle. Lena unveraendert; neu sperrt fuer sie nur der
--       Ausschluss von Hand. pruef_aufgabe legt die Ausgangsfassung fuer admin ebenso unabhaengig von Pilot und
--       Team an. pruef_entscheiden und pruef_rueckgaengig behalten Lenas Sperren auch fuer admin
--       (pruef_lena_sperren, Consensus-Check W1). pruef_speichern (ueber pruef_sperren) legt eine fehlende
--       Ausgangsfassung dann auch fuer admin an (pruef_ausgang_sichern); pruef_wertung_testen kennt keine Pilot-
--       oder Team-Sperre (Ist-Analyse 3).
--   G2  task_status_set(..., 'ready' oder 'review') lehnt bei status beanstandet ab: ED422 erst_an_lena. Die
--       freigabe_*-Schleifen nehmen nur review bzw. draft, nie beanstandet (Ist-Analyse 4).
--       Neue Tabelle task_pruef_ausschluss (von Hand aus Lenas Liste genommen, mit Pflichtgrund),
--       pruef_ausschluss liefert dafuer 'hand'. Neue Tabelle task_admin_protokoll (nur anhaengen).
--       pruef_admin_liste gibt zusaetzlich ausschluss_grund, ausschluss_von, ausschluss_am zurueck.
-- Muster 20261004001333_lead_thema_setzen: SECURITY DEFINER, set search_path = public, pg_temp, Grants nur an
-- authenticated. Fehler ueber pruef_fehler (ED422, HINT = Schluessel fuers Frontend).
-- Ersetzt (gleiche Signatur): pruef_ausschluss, pruef_sperren, pruef_entscheiden, pruef_rueckgaengig, pruef_aufgabe,
-- task_status_set. Neu (intern, kein Grant): pruef_lena_sperren.
-- Ersetzt (neuer Rueckgabetyp, drop + create): pruef_admin_liste.

-- ── Von Hand aus Lenas Liste genommen ───────────────────────────────────────
create table public.task_pruef_ausschluss (
  task_id uuid primary key references public.tasks (id) on delete cascade,
  grund   text not null check (btrim(grund) <> ''),
  von     uuid references public.profiles (id),
  am      timestamptz not null default now()
);

alter table public.task_pruef_ausschluss enable row level security;
create policy task_pruef_ausschluss_lesen on public.task_pruef_ausschluss
  for select to authenticated using (public.darf_pruefen());
revoke all on public.task_pruef_ausschluss from anon, authenticated;
grant select on public.task_pruef_ausschluss to authenticated;

-- ── Admin-Protokoll: eine Zeile je Admin-Aktion, einzeln wie gesammelt ──────
-- aenderungen im Format von task_pruefungen.aenderungen ({feld, teil, vorher, nachher}).
create table public.task_admin_protokoll (
  id          uuid primary key default gen_random_uuid(),
  task_id     uuid not null references public.tasks (id) on delete cascade,
  aktion      text not null check (aktion in (
                'freigeben', 'an_lena', 'zurueckweisen', 'freigabe_zurueck', 'ausschliessen', 'aufnehmen',
                'pilot_an', 'pilot_aus', 'fertigkeit', 'afb',
                'rueckfrage_freigeben', 'rueckfrage_an_lena', 'rueckfrage_zurueckweisen')),
  aenderungen jsonb not null default '[]' check (jsonb_typeof(aenderungen) = 'array'),
  grund       text,
  sammel      boolean not null default false,
  von         uuid references public.profiles (id),
  am          timestamptz not null default now()
);

create index task_admin_protokoll_task_idx on public.task_admin_protokoll (task_id, am desc);

alter table public.task_admin_protokoll enable row level security;
create policy task_admin_protokoll_lesen on public.task_admin_protokoll
  for select to authenticated using (public.get_my_role() = 'admin');
revoke all on public.task_admin_protokoll from anon, authenticated;
grant select on public.task_admin_protokoll to authenticated;

-- ── Warum eine Aufgabe nicht bei Lena erscheint: neu 'hand' nach typ ────────
create or replace function public.pruef_ausschluss(p_task_id uuid)
returns text language sql stable set search_path = public, pg_temp as $$
  select case
    when t.source = 'VERA8_IQB' then 'vera8'
    when not coalesce(t.is_active, false) or t.is_tutorial or t.content_type <> 'exercise' then 'inaktiv'
    when t.input_type is null
      or t.input_type not in ('MC', 'NUMERIC', 'SHORT_TEXT', 'MULTI_PART', 'TERM') then 'typ'
    when exists (select 1 from public.task_pruef_ausschluss h where h.task_id = t.id) then 'hand'
    when t.skill_key is null
      or not exists (select 1 from public.skill_thema st where st.skill_key = t.skill_key) then 'ohne_fertigkeit'
    when not exists (select 1 from public.task_solutions s where s.task_id = t.id
                        and public.lsa_has_answers(t.input_type, t.parts, s.correct_answers)) then 'ohne_loesung'
    when public.freigabe_gate_fehler(t.id) is not null then 'gate'
    when (coalesce(t.needs_image, false)
          or exists (select 1 from jsonb_array_elements(t.parts) p where p -> 'needs_image' = 'true'::jsonb))
     and jsonb_array_length(t.assets) = 0
     and not exists (select 1 from public.task_figures f where f.task_id = t.id and f.svg_hash is not null)
      then 'bild_fehlt'
  end
  from public.tasks t where t.id = p_task_id
$$;

-- ── G1 · Zugang, Sperre, Version, Status; Admin-Zweig ───────────────────────
-- Lenas Sperren ueber VERA8/inaktiv/typ hinaus: von Hand herausgenommen, ausserhalb des Piloten, vom Team
-- beanstandet. pruef_sperren wendet sie fuer Nicht-Admins an; pruef_entscheiden und pruef_rueckgaengig fuer alle
-- (Consensus-Check W1): Admins entscheiden ueber ihre eigene Leiste, nicht ueber Lenas Bewertung.
create or replace function public.pruef_lena_sperren(t public.tasks)
returns void language plpgsql set search_path = public, pg_temp as $$
begin
  if public.pruef_ausschluss(t.id) = 'hand' or not public.pruef_im_pilot(t) then
    perform public.pruef_fehler('ausgeschlossen');
  end if;
  -- Vom Team beanstandet, wird ueberarbeitet (Rasit, PR 208).
  if public.pruef_team_beanstandet(t.id) then perform public.pruef_fehler('team_beanstandet'); end if;
end $$;

create or replace function public.pruef_sperren(p_task_id uuid, p_version bigint)
returns public.tasks language plpgsql set search_path = public, pg_temp as $$
declare t public.tasks;
begin
  if not public.darf_pruefen() then
    raise exception 'pruefen: kein Pruefrecht' using errcode = '42501';
  end if;
  select * into t from public.tasks where id = p_task_id for update;
  if not found then
    raise exception 'pruefen: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  if t.pruef_version is distinct from p_version then
    raise exception 'pruefen: Die Aufgabe wurde inzwischen geaendert. Bitte neu laden.'
      using errcode = 'ED409', hint = 'version';
  end if;
  if t.status = 'ready' then perform public.pruef_fehler('freigegeben'); end if;
  -- Fuer alle: VERA8, inaktiv und fremde Antworttypen bearbeitet nur der Editor.
  if public.pruef_ausschluss(p_task_id) in ('vera8', 'inaktiv', 'typ') then
    perform public.pruef_fehler('ausgeschlossen');
  end if;
  if public.get_my_role() is distinct from 'admin' then perform public.pruef_lena_sperren(t); end if;
  return t;
end $$;

-- ── Lenas Entscheidung: ihre Sperren gelten hier auch fuer admin (gleiche Koerper, eine Zeile mehr) ─
create or replace function public.pruef_entscheiden(
  p_task_id uuid, p_version bigint, p_entscheidung text, p_gruende text[] default null,
  p_notiz text default null, p_aenderung_grund text default null, p_dauer_sek int default null)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  t public.tasks; aus jsonb; aend jsonb; neu text; g text;
  notiz text := nullif(btrim(p_notiz), '');
  grund text := nullif(btrim(p_aenderung_grund), '');
  gruende text[] := array(select distinct btrim(x) from unnest(coalesce(p_gruende, '{}')) x where btrim(x) <> '');
begin
  t := public.pruef_sperren(p_task_id, p_version);
  perform public.pruef_lena_sperren(t);
  if p_entscheidung is null or p_entscheidung not in ('passt', 'unsicher', 'passt_nicht') then
    raise exception 'pruef_entscheiden: unbekannte Entscheidung %', p_entscheidung using errcode = '22023';
  end if;
  aus := public.pruef_ausgang_sichern(p_task_id);
  aend := public.pruef_aenderungen(public.pruef_sicht(t, aus), public.pruef_sicht(t, public.pruef_fassung(p_task_id)));
  if jsonb_array_length(aend) > 0 and grund is null
     and coalesce((select e.grund_pflicht from public.pruef_einstellungen e limit 1), false) then
    perform public.pruef_fehler('aenderung_grund_fehlt');
  end if;

  if p_entscheidung = 'passt' then
    if not exists (select 1 from public.task_solutions s where s.task_id = p_task_id
                      and public.lsa_has_answers(t.input_type, t.parts, s.correct_answers)) then
      perform public.pruef_fehler('antwort_fehlt');
    end if;
    if public.freigabe_gate_fehler(p_task_id) is not null then
      perform public.pruef_fehler('gate', public.freigabe_gate_fehler(p_task_id));
    end if;
    neu := 'review';
    gruende := '{}';
  elsif p_entscheidung = 'unsicher' then
    if notiz is null then perform public.pruef_fehler('notiz_fehlt'); end if;
    neu := 'rueckfrage';
    gruende := '{}';
  else
    if cardinality(gruende) = 0 then perform public.pruef_fehler('grund_fehlt'); end if;
    if exists (select 1 from unnest(gruende) x where x not in ('aufgabe_fehlerhaft', 'aufgabe_unklar',
                 'bild_falsch', 'sprache_zu_schwer', 'tablet_umbauen', 'passt_nicht_in_lsa', 'sonstiges')) then
      perform public.pruef_fehler('grund_unbekannt');
    end if;
    if 'sonstiges' = any (gruende) and notiz is null then perform public.pruef_fehler('notiz_fehlt'); end if;
    neu := 'beanstandet';
    foreach g in array gruende loop
      insert into public.task_reviews (task_id, kategorie, notiz, geprueft_von, geprueft_am)
      values (p_task_id, g, notiz, auth.uid(), clock_timestamp());
    end loop;
  end if;

  -- Lena gibt nie frei: reviewed_by/at bleiben leer, die Freigabe stempelt task_status_set.
  update public.tasks set status = neu, reviewed_by = null, reviewed_at = null where id = p_task_id;
  insert into public.task_pruefungen (task_id, entscheidung, gruende, notiz, aenderungen, aenderung_grund,
                                      dauer_sek, geprueft_von, geprueft_am)
  values (p_task_id, p_entscheidung, gruende, notiz, aend, grund,
          least(greatest(p_dauer_sek, 0), 86400), auth.uid(), clock_timestamp());

  select * into t from public.tasks where id = p_task_id;
  return jsonb_build_object('pruef_version', t.pruef_version, 'lena_status', public.pruef_lena_status(t.status));
end $$;

create or replace function public.pruef_rueckgaengig(p_task_id uuid, p_version bigint)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare t public.tasks; aus jsonb;
begin
  t := public.pruef_sperren(p_task_id, p_version);
  perform public.pruef_lena_sperren(t);
  if t.status not in ('review', 'rueckfrage', 'beanstandet') then
    perform public.pruef_fehler('nicht_bewertet');
  end if;
  select a.ausgang into aus from public.task_pruefung_ausgang a where a.task_id = p_task_id;
  update public.tasks set status = 'draft', reviewed_by = null, reviewed_at = null where id = p_task_id;
  insert into public.task_pruefungen (task_id, entscheidung, aenderungen, geprueft_von, geprueft_am)
  values (p_task_id, 'zurueckgenommen',
          case when aus is null then '[]'::jsonb
               else public.pruef_aenderungen(public.pruef_sicht(t, aus), public.pruef_sicht(t, public.pruef_fassung(p_task_id))) end,
          auth.uid(), clock_timestamp());
  select * into t from public.tasks where id = p_task_id;
  return jsonb_build_object('pruef_version', t.pruef_version, 'lena_status', public.pruef_lena_status(t.status));
end $$;

-- ── G1 · Pruefkarte: Ausgangsfassung fuer admin unabhaengig von Pilot und Team ─
create or replace function public.pruef_aufgabe(p_task_id uuid)
returns jsonb language plpgsql volatile security definer set search_path = public, pg_temp as $$
declare
  t public.tasks; s public.task_solutions; aus jsonb; sicht jsonb; sicht_aus jsonb;
  ausschluss text; sk_aus text; th record; lp record;
  admin boolean := public.get_my_role() is not distinct from 'admin';
begin
  if not public.darf_pruefen() then
    raise exception 'pruef_aufgabe: kein Pruefrecht' using errcode = '42501';
  end if;
  select * into t from public.tasks where id = p_task_id;
  if not found then
    raise exception 'pruef_aufgabe: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  ausschluss := public.pruef_ausschluss(p_task_id);
  if t.status <> 'ready' and coalesce(ausschluss, '') not in ('vera8', 'inaktiv', 'typ')
     and (admin or (ausschluss is distinct from 'hand' and public.pruef_im_pilot(t)
                    and not public.pruef_team_beanstandet(p_task_id))) then
    aus := public.pruef_ausgang_sichern(p_task_id);
  else
    select a.ausgang into aus from public.task_pruefung_ausgang a where a.task_id = p_task_id;
  end if;
  select * into s from public.task_solutions where task_id = p_task_id;
  sicht := public.pruef_sicht(t, public.pruef_fassung(p_task_id));
  sicht_aus := case when aus is not null then public.pruef_sicht(t, aus) end;
  sk_aus := coalesce(aus ->> 'skill_key', t.skill_key);
  select x.thema_key, x.label, x.stufe into th
    from public.skill_thema st join public.themen x on x.thema_key = st.thema_key
   where st.skill_key = sk_aus;
  select * into lp from public.task_pruefungen where task_id = p_task_id order by geprueft_am desc limit 1;

  return jsonb_build_object(
    'task_id', t.id,
    'kopf', jsonb_build_object('kurztitel', public.pruef_kurztitel(t.title), 'stufe', th.stufe,
              'thema_key', th.thema_key, 'thema_label', th.label,
              'hilfsmittel', (select e.hilfsmittel from public.pruef_einstellungen e limit 1)),
    'aufgabe', jsonb_build_object(
      'input_type', t.input_type, 'unit', t.unit, 'status', t.status,
      'lena_status', public.pruef_lena_status(t.status), 'pruef_version', t.pruef_version,
      'ausschluss', ausschluss, 'pilot', t.pruef_pilot,
      'team_beanstandet', public.pruef_team_beanstandet(p_task_id),
      'parts', coalesce((select jsonb_agg(jsonb_build_object('nr', (p ->> 'nr')::int, 'kind', p ->> 'kind',
                 'prompt', p ->> 'prompt', 'unit', p ->> 'unit',
                 'options', coalesce((select jsonb_agg(jsonb_build_object('id', o ->> 'id', 'label', o ->> 'label') order by i)
                                        from jsonb_array_elements(coalesce(p -> 'options', '[]')) with ordinality z(o, i)), '[]'))
                 order by k) from jsonb_array_elements(t.parts) with ordinality q(p, k)), '[]'),
      'optionen', coalesce((select jsonb_agg(jsonb_build_object('id', o ->> 'id', 'label', o ->> 'label') order by i)
                              from jsonb_array_elements(case when t.input_type = 'MC'
                                     then coalesce(t.question_payload -> 'options', '[]') else '[]' end)
                                   with ordinality z(o, i)), '[]'),
      'bild_vorhanden', jsonb_array_length(t.assets) > 0
                        or exists (select 1 from public.task_figures f where f.task_id = t.id and f.svg_hash is not null)),
    'werte', sicht -> 'werte', 'mc', sicht -> 'mc', 'regel', sicht -> 'regel',
    'fehler', coalesce((select jsonb_agg(f || jsonb_build_object('klartext', fl.klartext) order by f ->> 'slug')
                          from jsonb_array_elements(sicht -> 'fehler') f
                          left join public.fehlbild_labels fl on fl.slug = f ->> 'slug'), '[]'),
    'weitere_hinweise', sicht -> 'weitere_hinweise',
    'flach_regel', sicht -> 'flach_regel', 'ohne_erkennung', sicht -> 'ohne_erkennung',
    'loesungsweg', s.solution,
    'fertigkeit', (select jsonb_build_object('key', k.skill_key, 'label', k.label, 'thema_key', x.thema_key,
                     'thema_label', x.label, 'stufe', x.stufe,
                     'voraussetzungen', coalesce((select jsonb_agg(v.label order by v.fundament_tiefe, v.skill_key)
                                                    from public.skill_kante sk join public.skills v on v.skill_key = sk.voraussetzt_skill_key
                                                   where sk.skill_key = k.skill_key), '[]'))
                     from public.skills k
                     left join public.skill_thema st on st.skill_key = k.skill_key
                     left join public.themen x on x.thema_key = st.thema_key
                    where k.skill_key = t.skill_key),
    'fertigkeit_optionen', public.pruef_fertigkeit_optionen(sk_aus),
    'afb', t.afb, 'afb_sicher', t.vorbefuellt #>> '{afb,sicher}',
    'ausgang', sicht_aus,
    'aenderungen', case when sicht_aus is not null then public.pruef_aenderungen(sicht_aus, sicht) else '[]'::jsonb end,
    'letzte_pruefung', case when lp.id is not null then jsonb_build_object(
      'entscheidung', lp.entscheidung, 'gruende', to_jsonb(lp.gruende), 'notiz', lp.notiz,
      'antwort', lp.antwort, 'beantwortet_am', lp.beantwortet_am, 'geprueft_am', lp.geprueft_am) end,
    'auffaelligkeiten', public.pruef_auffaelligkeiten(t, coalesce(s.correct_answers, '[]'), s.acceptance, s.solution));
end $$;

-- ── G2 · Statuswechsel: beanstandet geht erst zurueck an Lena ───────────────
create or replace function public.task_status_set(p_task_id uuid, p_status text)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_task tasks%rowtype;
  v_gate text;
begin
  if not (public.get_my_role() is not distinct from 'admin' or public.ist_systemaufruf()) then
    raise exception 'task_status_set: nur admin' using errcode = '42501';
  end if;
  if p_status not in ('draft', 'review', 'ready') then
    raise exception 'task_status_set: unbekannter Status %', p_status using errcode = '22023';
  end if;
  select * into v_task from tasks where id = p_task_id for update;
  if not found then
    raise exception 'task_status_set: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  -- "Passt nicht" und "Vom Team beanstandet" werden nicht freigegeben, auch nicht ueber review: erst
  -- ueberarbeiten, dann zurueck an Lena (Entscheidung Rasit, 05.10.2026; Consensus-Check W2).
  if p_status in ('review', 'ready') and v_task.status = 'beanstandet' then
    perform public.pruef_fehler('erst_an_lena', 'task_status_set: erst zurueck an Lena');
  end if;
  -- Das Gate (Migration 2c). Was hier durchfaellt, kommt nicht in den LSA-Pool.
  if p_status in ('review', 'ready') then
    v_gate := public.freigabe_gate_fehler(p_task_id);
    if v_gate is not null then
      raise exception '%', v_gate using errcode = 'P0001';
    end if;
  end if;

  update tasks
     set status      = p_status,
         reviewed_by = case when p_status = 'ready' then auth.uid() else null end,
         reviewed_at = case when p_status = 'ready' then now()      else null end
   where id = p_task_id;

  if p_status = 'draft' and v_task.status in ('review', 'rueckfrage', 'beanstandet') then
    delete from task_pruefung_ausgang where task_id = p_task_id;
  end if;

  return jsonb_build_object('ok', true, 'task_id', p_task_id, 'status', p_status);
end $$;

-- ── Lenas Ergebnis fuer Item-Pflege und Expertenliste, mit Hand-Ausschluss ──
drop function public.pruef_admin_liste();

create function public.pruef_admin_liste()
returns table (task_id uuid, lena_status text, ausschluss text, pilot boolean, entscheidung text,
               gruende text[], notiz text, aenderungen jsonb, aenderung_grund text, dauer_sek int,
               geprueft_von text, geprueft_am timestamptz, antwort text, beantwortet_am timestamptz,
               geaendert boolean, ausschluss_grund text, ausschluss_von text, ausschluss_am timestamptz)
language plpgsql stable security definer set search_path = public, pg_temp as $$
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'pruef_admin_liste: nur admin' using errcode = '42501';
  end if;
  return query
  select t.id, public.pruef_lena_status(t.status), public.pruef_ausschluss(t.id), t.pruef_pilot,
         lp.entscheidung, lp.gruende, lp.notiz, lp.aenderungen, lp.aenderung_grund, lp.dauer_sek,
         pr.full_name, lp.geprueft_am, lp.antwort, lp.beantwortet_am,
         coalesce(jsonb_array_length(lp.aenderungen) > 0, false),
         h.grund, hv.full_name, h.am
    from public.tasks t
    left join lateral (select p.* from public.task_pruefungen p where p.task_id = t.id
                        order by p.geprueft_am desc limit 1) lp on true
    left join public.profiles pr on pr.id = lp.geprueft_von
    left join public.task_pruef_ausschluss h on h.task_id = t.id
    left join public.profiles hv on hv.id = h.von;
end $$;

revoke all on function public.pruef_admin_liste() from public, anon, authenticated;
grant execute on function public.pruef_admin_liste() to authenticated;

revoke all on function public.pruef_lena_sperren(public.tasks) from public, anon, authenticated;
