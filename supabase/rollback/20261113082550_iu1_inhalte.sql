-- Rollback zu 20261113082550_iu1_inhalte (IU-1 U1).
--
-- Einspielen wie eine Migration (-v ON_ERROR_STOP=1 -1), danach die Zeile 20261113082550 aus
-- supabase_migrations.schema_migrations löschen und tools/schema-snapshot.sh laufen lassen.
-- Vorher den Rollback der Datenmigration iu1_pruefziel_msa einspielen (oder dieser löscht die Tabellen mit).
-- Stellt lsa_skill_bereit_roh, pruef_ziel_roh und pruef_ziel_liste byte-gleich wie vor IU-1 her (Körper aus
-- schema-erwartet.sql, Stand 75489322). lsa_paket_cache_auffrischen und lsa_paket_cache_trigger behalten bewusst
-- ihr WHERE (safeupdate, offen.md O1); sonst kommt der Fehler zurück. Sonst ist das Schema wie vor IU-1.

drop trigger if exists inhalte_cache_tasks on public.tasks;
drop trigger if exists inhalte_cache_task_solutions on public.task_solutions;
drop trigger if exists inhalte_cache_task_pruefungen on public.task_pruefungen;
drop trigger if exists inhalte_cache_session_einstellungen on public.session_einstellungen;
drop trigger if exists inhalte_cache_skills on public.skills;
drop trigger if exists inhalte_cache_task_pruef_ausschluss on public.task_pruef_ausschluss;
drop trigger if exists inhalte_cache_task_pruefung_ausgang on public.task_pruefung_ausgang;
drop trigger if exists inhalte_cache_task_reviews on public.task_reviews;
drop trigger if exists inhalte_cache_task_figures on public.task_figures;
drop trigger if exists inhalte_cache_pruef_einstellungen on public.pruef_einstellungen;
drop trigger if exists inhalte_cache_skill_thema on public.skill_thema;
drop trigger if exists inhalte_cache_pruefziele on public.pruefziele;
drop trigger if exists inhalte_cache_pruefziel_skills on public.pruefziel_skills;
drop trigger if exists inhalte_cache_pruefziel_ausschluss on public.pruefziel_ausschluss;

drop function if exists public.pruef_ziel_liste(boolean, integer, text, text, text);
drop function if exists public.pruef_ziel_stand(text);
drop function if exists public.inhalte_themen_ohne_reihe(integer);
drop function if exists public.inhalte_session_reihe(text);
drop function if exists public.inhalte_session_reihen(integer);
drop function if exists public.inhalte_reihe_themen();
drop function if exists public.inhalte_reihe_videos();
drop function if exists public.inhalte_lsa_pruefziel(text);
drop function if exists public.inhalte_lsa_thema(text);
drop function if exists public.inhalte_lsa_themen(integer);
drop function if exists public.inhalte_admin_pruefen(text);
drop function if exists public.inhalte_themen_basis(text, integer);
drop function if exists public.inhalte_thema_raum(text);
drop function if exists public.inhalte_auffrischen();
drop function if exists public.inhalte_cache_neu();
drop function if exists public.inhalte_cache_trigger();
drop function if exists public.inhalte_cache_frisch();
drop function if exists public.inhalte_skill_stand(text);
drop function if exists public.inhalte_skill_stand_roh(text);
drop table if exists public.inhalte_skill_cache;
drop table if exists public.inhalte_cache_stand;
drop sequence if exists public.inhalte_cache_gen;

drop function if exists public.pruef_ziel_roh(uuid[]);
drop function if exists public.lsa_skill_bereit_roh(text, uuid[]);
drop function if exists public.pruefziel_ohne(text);
drop table if exists public.pruefziel_ausschluss;
drop table if exists public.pruefziel_skills;
drop table if exists public.pruefziele;

-- ── alte Fassungen ──────────────────────────────────────────────────────────────────────────────────────────────
CREATE FUNCTION public.lsa_skill_bereit_roh(p_skill text DEFAULT NULL::text) RETURNS TABLE(skill_key text, texte_im_pool integer, ohne_mc_im_pool integer, erfuellt boolean, fehlende_texte integer, fehlende_ohne_mc integer, schluessel text[])
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  with pool as (
    select t.skill_key, t.input_type, coalesce(public.lsa_text_schluessel(t.question, t.parts), t.id::text) ts
      from public.tasks t
     where 'lsa' = any (t.einsatz) and (p_skill is null or t.skill_key = p_skill)
       and public.lsa_im_pool(t.id, false)),
  je as (
    select s.skill_key, count(distinct p.ts)::int texte, (count(p.ts) filter (where p.input_type <> 'MC'))::int ohne_mc,
           coalesce(array_agg(distinct p.ts) filter (where p.ts is not null), '{}') schluessel
      from public.skills s left join pool p on p.skill_key = s.skill_key
     where p_skill is null or s.skill_key = p_skill
     group by s.skill_key)
  select je.skill_key, je.texte, je.ohne_mc, je.texte >= g.texte and je.ohne_mc >= g.ohne_mc,
         greatest(g.texte - je.texte, 0), greatest(g.ohne_mc - je.ohne_mc, 0), je.schluessel
    from je cross join public.lsa_regel() g
$$;

CREATE FUNCTION public.pruef_ziel_roh() RETURNS TABLE(skill_key text, bedarf integer, rest integer, task_ids uuid[], freigabe_ids uuid[], pilot_fehlt uuid[])
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
  with g as (select * from public.lsa_regel()),
  fehlt as (select r.* from public.lsa_skill_bereit_roh(null) r where not r.erfuellt),
  kand0 as materialized (
    select t.id, t.skill_key, t.status, t.input_type <> 'MC' ohne_mc, t.sondierrang, public.pruef_im_pilot(t) pilot,
           coalesce(public.lsa_text_schluessel(t.question, t.parts), t.id::text) ts
      from public.tasks t
      join fehlt f on f.skill_key = t.skill_key
      join public.task_solutions s on s.task_id = t.id
     where 'lsa' = any (t.einsatz) and t.status in ('draft', 'review')
       and coalesce(t.is_active, false) and not coalesce(t.is_tutorial, false) and t.content_type = 'exercise'
       and public.lsa_has_answers(t.input_type, t.parts, s.correct_answers)
       and public.lsa_eingabeformat_eindeutig(t.input_type, t.bruch, t.unit, t.parts, s.correct_answers)
       and not coalesce(public.lsa_text_schluessel(t.question, t.parts), t.id::text) = any (f.schluessel)
       -- Fehlt nur der Beleg ohne MC, bringt eine MC-Aufgabe nichts.
       and (t.input_type <> 'MC' or f.fehlende_texte > 0)),
  kand as materialized (
    select k.* from kand0 k
     where public.pruef_ausschluss(k.id) is null
       and (k.status = 'draft' or public.pruef_freigabe_erlaubt(k.id))),
  je_schluessel as (   -- ein Vertreter je neuem Schlüssel: Geprüftes vor Entwurf, Nicht-MC, sondierrang
    select distinct on (k.skill_key, k.ts) k.*
      from kand k
     order by k.skill_key, k.ts, (k.status = 'review') desc, k.ohne_mc desc, k.pilot desc, k.sondierrang nulls last,
              k.id),
  geprueft as (
    select f.skill_key, greatest(f.fehlende_texte, f.fehlende_ohne_mc) bedarf,
           coalesce(array_agg(j.id order by j.ohne_mc desc, j.sondierrang nulls last, j.id)
                    filter (where j.status = 'review'), '{}') ids,
           (count(*) filter (where j.status = 'review'))::int n,
           (count(*) filter (where j.status = 'review' and j.ohne_mc))::int n_ohne
      from fehlt f left join je_schluessel j on j.skill_key = f.skill_key
     group by f.skill_key, f.fehlende_texte, f.fehlende_ohne_mc),
  rest as (
    select gp.skill_key, gp.bedarf, gp.ids[1:gp.bedarf] freigabe_ids,
           greatest(f.fehlende_texte - gp.n, f.fehlende_ohne_mc - gp.n_ohne, 0) rest
      from geprueft gp join fehlt f on f.skill_key = gp.skill_key),
  vorschlag as (
    select r.skill_key, x.id, x.pilot, x.rn
      from rest r
      cross join lateral (
        select j.id, j.pilot,
               row_number() over (order by j.ohne_mc desc, j.pilot desc, j.sondierrang nulls last, j.id) rn
          from je_schluessel j where j.skill_key = r.skill_key and j.status = 'draft') x
     where r.rest > 0 and x.rn <= r.rest + 1)
  select r.skill_key, r.bedarf, r.rest,
         coalesce((select array_agg(v.id order by v.rn) from vorschlag v where v.skill_key = r.skill_key), '{}'),
         coalesce(r.freigabe_ids, '{}'),
         coalesce((select array_agg(v.id order by v.rn) from vorschlag v where v.skill_key = r.skill_key and not v.pilot),
                  '{}')
    from rest r
$$;

CREATE FUNCTION public.pruef_ziel_liste(p_nur_fokus boolean DEFAULT false, p_quartal integer DEFAULT NULL::integer, p_schuljahr text DEFAULT NULL::text) RETURNS TABLE(abschnitt text, skill_key text, skill_label text, thema_key text, thema_label text, fehlende_texte integer, rest integer, hebel_pakete integer, hebel_schulen integer, fokus_treffer integer, sort integer, task_ids uuid[], freigabe_ids uuid[], pilot_fehlt uuid[])
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

CREATE OR REPLACE FUNCTION public.lsa_paket_cache_auffrischen() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
declare
  v_sj  text := public.ka_schuljahr((now() at time zone 'Europe/Berlin')::date);
  v_gen bigint;
begin
  -- Zwei gleichzeitige Neuberechnungen warten aufeinander statt an 23505 zu scheitern.
  perform pg_advisory_xact_lock(hashtext('lsa_paket_cache'));
  -- Stand vor der Rechnung; schreibt währenddessen jemand, ist gen danach größer und der Speicher bleibt veraltet.
  select s.gen into v_gen from public.lsa_paket_cache_stand s;
  delete from public.lsa_paket_cache where schuljahr is not null;
  insert into public.lsa_paket_cache (schuljahr, schule_id, klasse, paket_nr, thema_keys, quelle, datum, quartal, lage,
                                      hat_einstieg)
  select v_sj, p.schule_id, p.klasse, p.paket_nr, p.thema_keys, p.quelle, p.datum, p.quartal, p.lage,
         coalesce(p.hat_einstieg, false)
    from public.lsa_pakete_roh(v_sj) p;
  insert into public.lsa_paket_skill_cache (schuljahr, schule_id, klasse, paket_nr, skill_key, fall, teil, pflicht)
  select v_sj, s.schule_id, s.klasse, s.paket_nr, s.skill_key, s.fall, s.teil, s.pflicht
    from public.lsa_paket_skills_roh(v_sj) s;
  insert into public.lsa_paket_cache_stand (id, schuljahr, berechnet_am, fehler) values (true, v_sj, now(), null)
  on conflict (id) do update set schuljahr = excluded.schuljahr, berechnet_am = excluded.berechnet_am, fehler = null,
                                 veraltet = public.lsa_paket_cache_stand.gen is distinct from coalesce(v_gen, 0);
end;
$$;

CREATE OR REPLACE FUNCTION public.lsa_paket_cache_trigger() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
begin
  update public.lsa_paket_cache_stand set veraltet = true, gen = gen + 1 where id;
  return null;
end;
$$;

revoke all on function public.lsa_skill_bereit_roh(text) from public, anon, authenticated;
revoke all on function public.pruef_ziel_roh() from public, anon, authenticated;
revoke all on function public.pruef_ziel_liste(boolean, integer, text) from public, anon;
grant execute on function public.pruef_ziel_liste(boolean, integer, text) to authenticated;
