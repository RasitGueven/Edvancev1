-- MSA-1 M1 · Archiv für Aufgaben (Gründerentscheidung 12.11.2026: nicht notwendige LSA-Aufgaben archivieren, nicht löschen).
--
-- Archiviert heißt: tasks.archiviert_am gesetzt, immer zusammen mit is_active = false (CHECK). Pool (lsa_im_pool),
-- Lena-Board (pruef_ausschluss → „inaktiv“) und die gezielte Liste (pruef_ziel_roh) schließen inaktive Aufgaben schon
-- heute aus; sie bleiben unverändert. Nachgezogen werden die zwei Stellen, die is_active nicht beachten:
--   - pruef_ziel_liste, Abschnitt 'nachpruefen' (ready ohne letztes „passt“)
--   - pruef_admin_liste (Admin-Item-Pflege)
-- Aufrufer-Scan (pg_proc, Prod 12.11.2026): beide Funktionen haben keine SQL-Aufrufer, nur die Frontend-Wrapper
-- src/lib/supabase/lsaAbdeckung.ts (pruef_ziel_liste) und src/lib/supabase/pruefung.ts (pruef_admin_liste).
--
-- Neu: task_archivieren, task_wiederherstellen (nur admin oder Systemaufruf), task_archiv (Archiv-Seite, nur admin).
-- Jede Aktion hängt eine Zeile an task_admin_protokoll an (Aktionen 'archivieren', 'wiederherstellen').
-- Gelöscht wird nichts. Antworten, Prüfprotokoll und Lösungen bleiben unberührt.
--
-- Prüfabfrage: select count(*) filter (where archiviert_am is not null), count(*) from tasks;   → 0 | n
--              select proname from pg_proc where proname in ('task_archivieren','task_wiederherstellen','task_archiv');

-- ── Spalten ─────────────────────────────────────────────────────────────────────────────────────────────────────
alter table public.tasks
  add column archiviert_am timestamptz,
  add column archiviert_grund text,
  add column archiviert_von uuid references public.profiles (id) on delete set null;

alter table public.tasks
  add constraint tasks_archiv_grund_check
    check (archiviert_grund is null or archiviert_grund in ('nicht_notwendig', 'zu_schwer', 'sonstiges')),
  add constraint tasks_archiv_vollstaendig_check
    check ((archiviert_am is null) = (archiviert_grund is null)),
  -- Eine archivierte Aufgabe ist nie aktiv: Pool und Board schließen sie damit ohne weitere Änderung aus.
  add constraint tasks_archiv_inaktiv_check
    check (archiviert_am is null or is_active is false);

create index tasks_archiviert_idx on public.tasks (archiviert_am) where archiviert_am is not null;

comment on column public.tasks.archiviert_am is
  'MSA-1: archiviert (nicht gelöscht). Gesetzt nur über task_archivieren, zurück über task_wiederherstellen.';

-- ── Protokoll: zwei neue Aktionen ───────────────────────────────────────────────────────────────────────────────
alter table public.task_admin_protokoll drop constraint task_admin_protokoll_aktion_check;
alter table public.task_admin_protokoll add constraint task_admin_protokoll_aktion_check
  check (aktion = any (array['freigeben', 'an_lena', 'zurueckweisen', 'freigabe_zurueck', 'ausschliessen', 'aufnehmen',
                             'pilot_an', 'pilot_aus', 'fertigkeit', 'afb', 'rueckfrage_freigeben', 'rueckfrage_an_lena',
                             'rueckfrage_zurueckweisen', 'hinweise_bestaetigen', 'archivieren', 'wiederherstellen']));

-- ── task_archivieren ────────────────────────────────────────────────────────────────────────────────────────────
-- Archiviert die Aufgaben p_ids mit Grund. Schon archivierte werden übersprungen (idempotent). Eine Aufgabe, die aus
-- anderem Grund inaktiv ist, wird nicht archiviert (Wiederherstellen setzt is_active auf true und träfe sonst nicht
-- den Stand davor). Bauform-Instanzen werden abgelehnt. Status, Lösungen, Antworten und Prüfprotokoll bleiben unverändert. Rückgabe: Zahl archiviert.
create function public.task_archivieren(p_ids uuid[], p_grund text)
  returns integer
  language plpgsql security definer
  set search_path to 'public', 'pg_temp'
as $$
declare
  v_von uuid := auth.uid();
  v_fehlt uuid[];
  v_inaktiv uuid[];
  n integer;
begin
  if not (public.get_my_role() is not distinct from 'admin' or public.ist_systemaufruf()) then
    raise exception 'task_archivieren: nur admin' using errcode = '42501';
  end if;
  if p_grund is null or p_grund not in ('nicht_notwendig', 'zu_schwer', 'sonstiges') then
    raise exception 'task_archivieren: unbekannter Grund %', p_grund using errcode = '22023';
  end if;
  if coalesce(cardinality(p_ids), 0) = 0 then
    return 0;
  end if;
  select array_agg(x) into v_fehlt
    from unnest(p_ids) x where not exists (select 1 from public.tasks t where t.id = x);
  if v_fehlt is not null then
    raise exception 'task_archivieren: % Aufgaben nicht gefunden', cardinality(v_fehlt) using errcode = 'P0002';
  end if;
  select array_agg(t.id) into v_inaktiv
    from public.tasks t where t.id = any (p_ids) and t.archiviert_am is null and not coalesce(t.is_active, false);
  if v_inaktiv is not null then
    raise exception 'task_archivieren: % Aufgaben sind aus anderem Grund inaktiv', cardinality(v_inaktiv)
      using errcode = '22023';
  end if;
  -- Bauform-Instanzen nie: bauform_freigeben setzt ihre Instanzen aktiv und brach sonst am CHECK (Zweitprüfung M1).
  if exists (select 1 from public.tasks t where t.id = any (p_ids) and t.bauform_id is not null) then
    raise exception 'task_archivieren: Bauform-Instanzen werden über die Bauform-Version gesteuert, nicht archiviert'
      using errcode = '22023';
  end if;

  with u as (
    update public.tasks t
       set is_active = false, archiviert_am = now(), archiviert_grund = p_grund, archiviert_von = v_von
     where t.id = any (p_ids) and t.archiviert_am is null and coalesce(t.is_active, false)
    returning t.id)
  insert into public.task_admin_protokoll (task_id, aktion, aenderungen, grund, sammel, von)
  select u.id, 'archivieren',
         jsonb_build_array(jsonb_build_object('feld', 'is_active', 'teil', null, 'vorher', true, 'nachher', false)),
         p_grund, cardinality(p_ids) > 1, v_von
    from u;
  get diagnostics n = row_count;
  return n;
end $$;

-- ── task_wiederherstellen ───────────────────────────────────────────────────────────────────────────────────────
-- Holt archivierte Aufgaben zurück: is_active = true, Archiv-Felder leer. Der Status bleibt, wie er ist (eine
-- wiederhergestellte Aufgabe wird nie dadurch ready). Nicht archivierte ids werden übersprungen.
create function public.task_wiederherstellen(p_ids uuid[])
  returns integer
  language plpgsql security definer
  set search_path to 'public', 'pg_temp'
as $$
declare
  v_von uuid := auth.uid();
  n integer;
begin
  if not (public.get_my_role() is not distinct from 'admin' or public.ist_systemaufruf()) then
    raise exception 'task_wiederherstellen: nur admin' using errcode = '42501';
  end if;
  if coalesce(cardinality(p_ids), 0) = 0 then
    return 0;
  end if;
  with u as (
    update public.tasks t
       set is_active = true, archiviert_am = null, archiviert_grund = null, archiviert_von = null
     where t.id = any (p_ids) and t.archiviert_am is not null
    returning t.id)
  insert into public.task_admin_protokoll (task_id, aktion, aenderungen, grund, sammel, von)
  select u.id, 'wiederherstellen',
         jsonb_build_array(jsonb_build_object('feld', 'is_active', 'teil', null, 'vorher', false, 'nachher', true)),
         null, cardinality(p_ids) > 1, v_von
    from u;
  get diagnostics n = row_count;
  return n;
end $$;

-- ── task_archiv ─────────────────────────────────────────────────────────────────────────────────────────────────
-- Archiv-Seite (nur admin): archivierte Aufgaben, optional je Skill, neueste zuerst.
create function public.task_archiv(p_skill text default null)
  returns table (id uuid, kurztext text, skill_key text, skill_label text, status text, input_type text,
                 einsatz text[], grund text, archiviert_am timestamptz, archiviert_von text)
  language plpgsql stable security definer
  set search_path to 'public', 'pg_temp'
as $$
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'task_archiv: nur admin' using errcode = '42501';
  end if;
  return query
  select t.id, coalesce(nullif(btrim(t.title), ''), left(regexp_replace(coalesce(t.question, ''), '\s+', ' ', 'g'), 120)),
         t.skill_key, s.label, t.status, t.input_type, t.einsatz, t.archiviert_grund, t.archiviert_am, p.full_name
    from public.tasks t
    left join public.skills s on s.skill_key = t.skill_key
    left join public.profiles p on p.id = t.archiviert_von
   where t.archiviert_am is not null and (p_skill is null or t.skill_key = p_skill)
   order by t.archiviert_am desc, t.skill_key, t.id;
end $$;

revoke all on function public.task_archivieren(uuid[], text) from public, anon, authenticated;
revoke all on function public.task_wiederherstellen(uuid[]) from public, anon, authenticated;
revoke all on function public.task_archiv(text) from public, anon, authenticated;
grant execute on function public.task_archivieren(uuid[], text) to authenticated;
grant execute on function public.task_wiederherstellen(uuid[]) to authenticated;
grant execute on function public.task_archiv(text) to authenticated;

-- ── Nachpruefen und Admin-Liste ohne Archiv ─────────────────────────────────────────────────────────────────────
create or replace function public.pruef_ziel_liste(p_nur_fokus boolean DEFAULT false, p_quartal integer DEFAULT NULL::integer, p_schuljahr text DEFAULT NULL::text) RETURNS TABLE(abschnitt text, skill_key text, skill_label text, thema_key text, thema_label text, fehlende_texte integer, rest integer, hebel_pakete integer, hebel_schulen integer, fokus_treffer integer, sort integer, task_ids uuid[], freigabe_ids uuid[], pilot_fehlt uuid[])
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
#variable_conflict use_column
declare
  v_sj text := coalesce(p_schuljahr, public.lsa_schuljahr_heute());
  v_q  integer := coalesce(p_quartal, (select g.fokus_quartal from public.lsa_regel() g));
begin
  if not public.darf_pruefen() then
    raise exception 'pruef_ziel_liste: kein Pruefrecht' using errcode = '42501';
  end if;
  return query
  with p as (
    select x.*, f.schule_id is not null fokus from public.lsa_pakete_basis(v_sj) x
      left join public.schule_fokus f on f.schule_id = x.schule_id
     where (not coalesce(p_nur_fokus, false) or f.schule_id is not null)
       and (p_quartal is null or x.quartal = p_quartal)),
  ps as (
    select distinct s.schule_id, s.klasse, s.paket_nr, s.skill_key, p.fokus, p.quartal
      from public.lsa_paket_skills_basis(v_sj) s join p using (schule_id, klasse, paket_nr)),
  hebel as (
    select ps.skill_key, count(*)::int pakete, count(distinct ps.schule_id)::int schulen,
           (count(*) filter (where ps.fokus and ps.quartal = v_q))::int fokus
      from ps group by 1),
  thema as (
    select distinct on (st.skill_key) st.skill_key, th.thema_key, th.label
      from public.skill_thema st join public.themen th on th.thema_key = st.thema_key
     order by st.skill_key, th.sort nulls last, th.thema_key),
  nach as (
    select t.skill_key, array_agg(t.id order by t.sondierrang nulls last, t.id) ids
      from public.tasks t
     where 'lsa' = any (t.einsatz) and t.status = 'ready'
       and t.archiviert_am is null   -- MSA-1 M1: archivierte Aufgaben nicht nachpruefen
       and coalesce((select p2.entscheidung from public.task_pruefungen p2 where p2.task_id = t.id
                      order by p2.geprueft_am desc limit 1), '') <> 'passt'
     group by t.skill_key),
  zeilen as (
    select 'gezielt'::text ab, z.skill_key sk, z.bedarf, z.rest r, h.pakete, h.schulen, h.fokus, z.task_ids ids,
           z.freigabe_ids fids, z.pilot_fehlt pf
      from public.pruef_ziel_roh() z join hebel h on h.skill_key = z.skill_key
     where cardinality(z.task_ids) > 0 or cardinality(z.freigabe_ids) > 0
    union all
    select 'nachpruefen', n.skill_key, 0, 0, coalesce(h.pakete, 0), coalesce(h.schulen, 0), coalesce(h.fokus, 0),
           n.ids, '{}'::uuid[], '{}'::uuid[]
      from nach n left join hebel h on h.skill_key = n.skill_key)
  select zl.ab, zl.sk, k.label, th.thema_key, th.label, zl.bedarf, zl.r, zl.pakete, zl.schulen, zl.fokus,
         (row_number() over (partition by zl.ab order by zl.fokus desc, zl.schulen desc, zl.pakete desc, zl.sk))::int,
         zl.ids, zl.fids, zl.pf
    from zeilen zl
    join public.skills k on k.skill_key = zl.sk
    left join thema th on th.skill_key = zl.sk
   order by zl.ab, 11;
end;
$$;

create or replace function public.pruef_admin_liste() RETURNS TABLE(task_id uuid, lena_status text, ausschluss text, pilot boolean, entscheidung text, gruende text[], notiz text, aenderungen jsonb, aenderung_grund text, dauer_sek integer, geprueft_von text, geprueft_am timestamp with time zone, antwort text, beantwortet_am timestamp with time zone, geaendert boolean, ausschluss_grund text, ausschluss_von text, ausschluss_am timestamp with time zone, hinweise integer, hinweise_ungeprueft integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'pruef_admin_liste: nur admin' using errcode = '42501';
  end if;
  return query
  select t.id, public.pruef_lena_status(t.status), public.pruef_ausschluss(t.id), t.pruef_pilot,
         lp.entscheidung, lp.gruende, lp.notiz, lp.aenderungen, lp.aenderung_grund, lp.dauer_sek,
         pr.full_name, lp.geprueft_am, lp.antwort, lp.beantwortet_am,
         coalesce(jsonb_array_length(lp.aenderungen) > 0, false),
         h.grund, hv.full_name, h.am,
         coalesce(hz.n, 0), coalesce(hz.offen, 0)
    from public.tasks t
    left join lateral (select p.* from public.task_pruefungen p where p.task_id = t.id
                        order by p.geprueft_am desc limit 1) lp on true
    left join public.profiles pr on pr.id = lp.geprueft_von
    left join public.task_pruef_ausschluss h on h.task_id = t.id
    left join public.profiles hv on hv.id = h.von
    left join lateral (select count(*)::int n,
                              (count(*) filter (where coalesce(x ->> 'status', 'entwurf') <> 'geprueft'))::int offen
                         from public.task_solutions s,
                              jsonb_array_elements(case when jsonb_typeof(s.hints) = 'array' then s.hints else '[]' end) x
                        where s.task_id = t.id) hz on true
   where t.archiviert_am is null;   -- MSA-1 M1: archivierte Aufgaben nur ueber task_archiv
end;
$$;
