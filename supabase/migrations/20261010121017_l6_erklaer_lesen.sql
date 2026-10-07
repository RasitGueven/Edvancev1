-- L6.1 Erklaersequenz pruefen, Teil 4: Lesefunktionen fuer Pruefer und Admin.
--
--   erklaer_pruef_liste()            eine Zeile je Kernidee mit Thema, Skill und Stand; offen zuerst
--   erklaer_pruef_detail(kernidee)   Kernidee, Schritte aller Varianten (mit Kinderansicht wie
--                                    erklaer_schritt_json), Fehlbilder des Skills (known_errors der
--                                    Aufgaben), Checks mit Pruefstand, was zur Freigabe fehlt, Protokoll
-- Nur mit darf_pruefen() (Admin oder Coach mit Pruefrecht), sonst 42501 — auch fuer ein Konto ohne Profil.

create function public.erklaer_pruef_liste()
returns table (
  kernidee_id    uuid,
  skill_key      text,
  skill_label    text,
  thema_key      text,
  thema_label    text,
  klasse         integer,
  nr             integer,
  titel          text,
  status         text,
  stand          text,
  rueckfrage     boolean,
  bereit         boolean,
  varianten      integer,
  schritte       integer,
  schritte_offen integer,
  checks         integer,
  checks_soll    integer,
  geaendert_am   timestamptz
)
language plpgsql stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.darf_pruefen() then
    raise exception 'erklaer_pruef_liste: kein Pruefrecht' using errcode = '42501';
  end if;
  return query
  with b as (
    select k.*, public.erklaer_lena_stand(k) as st, public.erklaer_freigabe_fehlt(k.id) as fehlt
      from public.erklaer_kernidee k
  )
  select b.id, b.skill_key, sk.label, th.thema_key, th.label, coalesce(th.klasse, sk.klasse_herkunft),
         b.nr, b.titel, b.status, b.st, public.erklaer_rueckfrage_offen(b.id),
         (b.status = 'geprueft'
          or (b.status = 'freigegeben' and exists (select 1 from public.erklaer_schritt s
                                                    where s.kernidee_id = b.id and s.status = 'geprueft')))
           and jsonb_array_length(b.fehlt) = 0,
         (select count(distinct s.variante)::int from public.erklaer_schritt s where s.kernidee_id = b.id),
         (select count(*)::int from public.erklaer_schritt s where s.kernidee_id = b.id),
         (select count(*)::int from public.erklaer_schritt s where s.kernidee_id = b.id and s.status = 'entwurf'),
         cardinality(public.erklaer_checks(b.id, false)),
         public.erklaer_check_soll(),
         b.geaendert_am
    from b
    join public.skills sk on sk.skill_key = b.skill_key
    left join lateral (
      select t.thema_key, t.label, t.klasse, t.sort from public.skill_thema st
        join public.themen t on t.thema_key = st.thema_key
       where st.skill_key = b.skill_key
       order by t.klasse, t.sort nulls last, t.thema_key limit 1) th on true
   order by case b.st when 'offen' then 1 when 'unsicher' then 2 when 'passt_nicht' then 3
                      when 'passt' then 4 else 5 end,
            coalesce(th.klasse, sk.klasse_herkunft), th.sort nulls last, th.thema_key, b.skill_key, b.nr;
end;
$$;

create function public.erklaer_pruef_detail(p_kernidee_id uuid)
returns jsonb
language plpgsql stable
security definer
set search_path = public, pg_temp
as $$
declare
  k public.erklaer_kernidee;
begin
  if not public.darf_pruefen() then
    raise exception 'erklaer_pruef_detail: kein Pruefrecht' using errcode = '42501';
  end if;
  select * into k from public.erklaer_kernidee where id = p_kernidee_id;
  if k.id is null then
    raise exception 'erklaer_pruef_detail: Kernidee nicht gefunden' using errcode = 'P0002';
  end if;

  return jsonb_build_object(
    'kernidee', jsonb_build_object(
      'id', k.id, 'skill_key', k.skill_key, 'nr', k.nr, 'titel', k.titel, 'status', k.status,
      'quelle', k.quelle, 'pruef_version', k.pruef_version, 'geaendert_am', k.geaendert_am,
      'stand', public.erklaer_lena_stand(k), 'rueckfrage', public.erklaer_rueckfrage_offen(k.id),
      'skill_label', (select sk.label from public.skills sk where sk.skill_key = k.skill_key),
      'klasse', (select sk.klasse_herkunft from public.skills sk where sk.skill_key = k.skill_key),
      'kernideen', (select count(*) from public.erklaer_kernidee x where x.skill_key = k.skill_key)),
    'schritte', (
      select coalesce(jsonb_agg(jsonb_build_object(
               'id', s.id, 'variante', s.variante, 'art', s.art, 'inhalt', s.inhalt, 'bild', s.bild,
               'fehlbild_slugs', to_jsonb(s.fehlbild_slugs), 'status', s.status,
               'formeln_soll', public.erklaer_formel_anzahl(s.inhalt), 'formeln_ist', cardinality(s.formeln),
               'geaendert_am', s.geaendert_am, 'kind', public.erklaer_schritt_json(s))
             order by s.variante, case s.art when 'erklaerung' then 1 else 2 end), '[]')
        from public.erklaer_schritt s where s.kernidee_id = k.id),
    -- Fehlbilder des Skills aus known_errors seiner Aufgaben, dazu die schon zugeordneten.
    'fehlbilder', (
      select coalesce(jsonb_agg(jsonb_build_object('slug', f.slug, 'klartext', l.klartext, 'aufgaben', f.n)
                                order by f.n desc, f.slug), '[]')
        from (select x.slug, count(distinct x.task_id)::int as n
                from (select t.id as task_id, g.slug
                        from public.tasks t
                        join public.task_solutions so on so.task_id = t.id
                        cross join lateral public.pruef_fehler_gruppen(so.acceptance) g
                       where t.skill_key = k.skill_key
                          or t.id in (select c.task_id from public.erklaer_check c where c.kernidee_id = k.id)
                      union all
                      select null, u.slug
                        from public.erklaer_schritt s, unnest(s.fehlbild_slugs) u(slug)
                       where s.kernidee_id = k.id) x
               group by x.slug) f
        left join public.fehlbild_labels l on l.slug = f.slug),
    'checks', (
      select coalesce(jsonb_agg(jsonb_build_object(
               'task_id', c.task_id, 'reihenfolge', c.reihenfolge,
               'titel', public.pruef_kurztitel(t.title), 'status', t.status,
               'lena_status', public.pruef_lena_status(t.status),
               'einsatz_check', 'check' = any (t.einsatz), 'aktiv', coalesce(t.is_active, true),
               'zaehlt', c.task_id = any (public.erklaer_checks(k.id, false)))
             order by c.reihenfolge), '[]')
        from public.erklaer_check c join public.tasks t on t.id = c.task_id
       where c.kernidee_id = k.id),
    'checks_soll', public.erklaer_check_soll(),
    'freigabe_fehlt', public.erklaer_freigabe_fehlt(k.id),
    'protokoll', (
      select coalesce(jsonb_agg(jsonb_build_object(
               'id', p.id, 'entscheidung', p.entscheidung, 'gruende', to_jsonb(p.gruende), 'notiz', p.notiz,
               'aenderungen', p.aenderungen, 'pruef_version', p.pruef_version,
               'von', pv.full_name, 'am', p.geprueft_am,
               'antwort', p.antwort, 'beantwortet_von', pb.full_name, 'beantwortet_am', p.beantwortet_am)
             order by p.id desc), '[]')
        from public.erklaer_pruefungen p
        left join public.profiles pv on pv.id = p.geprueft_von
        left join public.profiles pb on pb.id = p.beantwortet_von
       where p.kernidee_id = k.id));
end;
$$;

revoke all on function public.erklaer_pruef_liste() from public, anon, authenticated;
revoke all on function public.erklaer_pruef_detail(uuid) from public, anon, authenticated;
grant execute on function public.erklaer_pruef_liste() to authenticated;
grant execute on function public.erklaer_pruef_detail(uuid) to authenticated;
