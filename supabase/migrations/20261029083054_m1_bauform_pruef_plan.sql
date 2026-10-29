-- M1 Phase 2 · Session-Muster nach Sessions ordnen (Auftrag M1, Konzept Sessionreihe 1 §2.2, §4)
--
-- 1. Stellschraube reihe_standard_sessions (Vorgabe 8): so viele Sessions hat der Standardplan ohne Kind.
-- 2. bauform_plan_standard(): Standardplan ohne Kind. Kernideen in der Reihenfolge reihe_kernideen.nr, jede als
--    „neu“ (reihe_min_neu), dazu der Transferblock, verteilt wie reihe_plan_rechnen im Modus Klassenarbeit:
--    reihe_verteilen über n − 1 Sessions (die letzte ist die Generalprobe), Kapazität reihe_kapazitaet_min mal
--    (1 + reihe_spielraum). Passt es nicht, kürzt es wie dort Regel 5: erst die Kernideen, deren Skill entfallen kann,
--    dann der Transferblock, danach je Schritt der letzte Posten (Schritt „gesehen knapp“ entfällt, alles ist neu).
--    Liefert die normalen Sessions als [{nr, kernideen: [{skill_key, kernidee_key}]}].
-- 3. bauform_pruef_plan(p_student_id): Zeilen von bauform_pruef_liste plus Session, Kernidee und
--    ist_voraussetzung. Mit Kind: wirksamer Plan der aktiven Reihe (reihe_plan_wirksam). Muster mit Kernidee:
--    Session der Kernidee. Voraussetzungs-Muster: erste Session, deren Kernidee-Skill den Skill laut skill_kante
--    direkt braucht; ohne Treffer session_nr null. Im Kinderplan ebenfalls null: Kernideen, die das Kind schon sicher
--    kann, die gekürzt wurden oder deren Session vorbei ist (reihe_plan_wirksam zeigt nur Sessions ab heute).
-- 4. bauform_freigeben(p_reihe, p_thema_key, p_schluessel): mit p_schluessel nur diese Muster (Status
--    zur_freigabe), sonst wie bisher. Ein leeres Array oder ein unbekannter Schlüssel ist ein Fehler (22023). Ersetzt die Fassung mit zwei Parametern; Aufrufe mit p_reihe oder
--    p_thema_key bleiben gültig (Defaults). Aufrufer laut pg_proc: keine (nur das Frontend).
--
-- Rollback: supabase/rollback/20261029083054_m1_bauform_pruef_plan.sql.

insert into public.session_einstellungen
  (schluessel, beschreibung, typ, wert, startwert, min, max, ganzzahl, werte, einheit)
values ('reihe_standard_sessions', 'Reihe: Sessions im Standardplan der Muster-Prüfung (ohne Kind)', 'zahl',
        '8'::jsonb, '8'::jsonb, 3, 16, true, null, 'sessions')
on conflict (schluessel) do nothing;

create function public.bauform_plan_standard()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_n      int := coalesce(public.reihe_wert('reihe_standard_sessions'), 8)::int;
  v_cap    numeric := public.reihe_wert('reihe_kapazitaet_min') * (1 + public.reihe_wert('reihe_spielraum'));
  v_neu    numeric := public.reihe_wert('reihe_min_neu');
  v_trans  numeric := public.reihe_wert('reihe_transfer_min');
  v_items  jsonb;
  v_kosten numeric[];
  v_idx    int[];
  v_sess   jsonb := '[]';
  v_teil   jsonb;
  v_schritt int := 0;
  i        int;
begin
  select coalesce(jsonb_agg(jsonb_build_object('skill_key', k.skill_key, 'kernidee_key', k.kernidee_key,
                                               'minuten', v_neu) order by k.nr), '[]')
    into v_items from public.reihe_kernideen k;
  if v_trans > 0 then
    v_items := v_items || jsonb_build_object('minuten', v_trans);
  end if;

  -- Kürzen nach Regel 5 wie reihe_plan_rechnen, bis es in die Sessions vor der Generalprobe passt.
  loop
    select coalesce(array_agg((e ->> 'minuten')::numeric order by o), '{}') into v_kosten
      from jsonb_array_elements(v_items) with ordinality x(e, o);
    v_idx := public.reihe_verteilen(v_kosten, v_n - 1, v_cap);
    exit when v_idx is not null or jsonb_array_length(v_items) = 0;
    v_schritt := v_schritt + 1;
    if v_schritt = 1 then
      select coalesce(jsonb_agg(e order by o) filter (where not (e ? 'skill_key'
               and public.reihe_kann_entfallen_pruefen(e ->> 'skill_key'))), '[]')
        into v_items from jsonb_array_elements(v_items) with ordinality x(e, o);
    elsif v_schritt = 2 then
      select coalesce(jsonb_agg(e order by o) filter (where e ? 'skill_key'), '[]')
        into v_items from jsonb_array_elements(v_items) with ordinality x(e, o);
    else
      v_items := v_items - (jsonb_array_length(v_items) - 1);
    end if;
  end loop;
  v_idx := coalesce(v_idx, '{}');

  for i in 1 .. v_n - 1 loop
    v_sess := v_sess || jsonb_build_object('nr', i, 'kernideen',
      coalesce((select jsonb_agg((v_items -> (o - 1)) - 'minuten' order by o)
                  from generate_series(1, coalesce(cardinality(v_idx), 0)) o
                 where v_idx[o] = i and (v_items -> (o - 1)) ? 'skill_key'), '[]'));
  end loop;
  return v_sess;
end;
$$;

comment on function public.bauform_plan_standard() is
  'M1: Standardplan der Reihe ohne Kind (alle Kernideen neu, Verteilung wie reihe_plan_rechnen). Nur intern für bauform_pruef_plan.';
revoke all on function public.bauform_plan_standard() from public, anon, authenticated;

create function public.bauform_pruef_plan(p_student_id uuid default null)
returns table(bauform_id uuid, schluessel text, skill_key text, skill_label text, reihe text, format text,
              rollen text[], version integer, status text, gruen integer, letzte_entscheidung text,
              letzte_notiz text, geprueft_am timestamptz, session_nr integer, session_titel text,
              kernidee_key text, kernidee_titel text, ist_voraussetzung boolean)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_reihe public.reihen;
  v_sess  jsonb;
begin
  if not public.darf_pruefen() then
    raise exception 'bauform_pruef_plan: kein Pruefrecht' using errcode = '42501';
  end if;
  if p_student_id is null then
    v_sess := public.bauform_plan_standard();
  else
    select * into v_reihe from public.reihe_aktiv(p_student_id);
    if v_reihe.id is null then
      raise exception 'bauform_pruef_plan: keine aktive Reihe' using errcode = 'P0002';
    end if;
    select coalesce(jsonb_agg(s order by o) filter (where s ->> 'art' = 'normal'), '[]') into v_sess
      from jsonb_array_elements(public.reihe_plan_wirksam(v_reihe.id) -> 'sessions') with ordinality x(s, o);
  end if;

  return query
  with ki as (
    select (s ->> 'nr')::int as nr, e ->> 'skill_key' as sk, e ->> 'kernidee_key' as kk
      from jsonb_array_elements(v_sess) s, jsonb_array_elements(s -> 'kernideen') e
  ), titel as (
    select x.nr, string_agg(sk.label, ' · ' order by x.ab) as t
      from (select ki.nr, ki.sk, min(rk.nr) as ab
              from ki join public.reihe_kernideen rk on rk.skill_key = ki.sk and rk.kernidee_key = ki.kk
             group by ki.nr, ki.sk) x
      join public.skills sk on sk.skill_key = x.sk
     group by x.nr
  ), zuordnung as (
    select b.id,
           case when b.kernidee_key is not null then
                  (select min(ki.nr) from ki where ki.sk || ':' || ki.kk = b.kernidee_key)
                else
                  (select min(ki.nr) from ki join public.skill_kante k on k.skill_key = ki.sk
                    where k.voraussetzt_skill_key = b.skill_key)
           end as nr
      from public.bauformen b
  )
  select l.bauform_id, l.schluessel, l.skill_key, l.skill_label, l.reihe, l.format, l.rollen, l.version, l.status,
         l.gruen, l.letzte_entscheidung, l.letzte_notiz, l.geprueft_am,
         z.nr, ti.t, b.kernidee_key, rk.titel, b.kernidee_key is null
    from public.bauform_pruef_liste() l
    join public.bauformen b on b.id = l.bauform_id
    join zuordnung z on z.id = b.id
    left join titel ti on ti.nr = z.nr
    left join public.reihe_kernideen rk on rk.skill_key || ':' || rk.kernidee_key = b.kernidee_key
   order by z.nr nulls last, b.kernidee_key is not null, b.schluessel;
end;
$$;

comment on function public.bauform_pruef_plan(uuid) is 'reihe1 fertig';
revoke all on function public.bauform_pruef_plan(uuid) from public, anon;
grant execute on function public.bauform_pruef_plan(uuid) to authenticated;

drop function public.bauform_freigeben(text, text);

create function public.bauform_freigeben(p_reihe text default null, p_thema_key text default null,
                                         p_schluessel text[] default null)
returns integer
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
  if p_schluessel is null and (p_reihe is null) = (p_thema_key is null) then
    raise exception 'bauform_freigeben: genau eins von Reihe oder Thema' using errcode = '22023';
  end if;
  if p_schluessel is not null and (cardinality(p_schluessel) = 0
      or exists (select 1 from unnest(p_schluessel) k where k is null
                   or not exists (select 1 from public.bauformen x where x.schluessel = k))) then
    raise exception 'bauform_freigeben: Muster-Schluessel leer oder unbekannt' using errcode = '22023';
  end if;
  for b in
    select x.* from public.bauformen x
     where x.status = 'zur_freigabe'
       and (p_schluessel is null or x.schluessel = any (p_schluessel))
       and (p_reihe is null or x.reihe = p_reihe)
       and (p_thema_key is null
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

comment on function public.bauform_freigeben(text, text, text[]) is 'reihe1 fertig';
revoke all on function public.bauform_freigeben(text, text, text[]) from public, anon;
grant execute on function public.bauform_freigeben(text, text, text[]) to authenticated;
