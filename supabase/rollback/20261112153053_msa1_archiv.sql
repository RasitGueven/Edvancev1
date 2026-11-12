-- Rollback zu 20261112153053_msa1_archiv: Funktionen zurück auf den Stand davor, Archiv-Funktionen und -Spalten weg.
-- Nur ausführen, solange keine Aufgabe archiviert ist (sonst zuerst den Rollback der Datenmigration M2): Der Wächter
-- bricht sonst ab, damit kein Archiv-Kennzeichen verloren geht. Der erweiterte CHECK von task_admin_protokoll bleibt
-- stehen, falls schon Zeilen 'archivieren'/'wiederherstellen' existieren (Protokoll wird nie gekürzt).
-- Den Eintrag in supabase_migrations.schema_migrations danach von Hand entfernen.
do $$
begin
  if exists (select 1 from public.tasks where archiviert_am is not null) then
    raise exception 'Rollback MSA-1 M1: es gibt archivierte Aufgaben — zuerst M2 zurückrollen';
  end if;
end $$;
drop function if exists public.task_archiv(text);
drop function if exists public.task_wiederherstellen(uuid[]);
drop function if exists public.task_archivieren(uuid[], text);
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
                        where s.task_id = t.id) hz on true;
end;
$$;

do $$
begin
  if not exists (select 1 from public.task_admin_protokoll where aktion in ('archivieren', 'wiederherstellen')) then
    alter table public.task_admin_protokoll drop constraint task_admin_protokoll_aktion_check;
    alter table public.task_admin_protokoll add constraint task_admin_protokoll_aktion_check
      check (aktion = any (array['freigeben', 'an_lena', 'zurueckweisen', 'freigabe_zurueck', 'ausschliessen', 'aufnehmen',
                                 'pilot_an', 'pilot_aus', 'fertigkeit', 'afb', 'rueckfrage_freigeben', 'rueckfrage_an_lena',
                                 'rueckfrage_zurueckweisen', 'hinweise_bestaetigen']));
  end if;
end $$;
drop index if exists public.tasks_archiviert_idx;
alter table public.tasks drop constraint if exists tasks_archiv_inaktiv_check,
                         drop constraint if exists tasks_archiv_vollstaendig_check,
                         drop constraint if exists tasks_archiv_grund_check;
alter table public.tasks drop column if exists archiviert_von, drop column if exists archiviert_grund,
                         drop column if exists archiviert_am;
