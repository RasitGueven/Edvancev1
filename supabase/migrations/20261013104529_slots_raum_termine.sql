-- Slots SL1, Teil 3: Raum-Termine, Kapazität, Raumzuteilung.
--
-- Bauauftrag Slots (Fassung 1), Entscheidungen 15 und 16, Anforderung B 9, D 19–21, H 47–50.
--
-- Inhalt:
--   1. slot_raeume      — Räume je Datum und Uhrzeit mit Coach (Stammschicht, Abweichung, Raum aktiv)
--   2. slot_kapazitaet  — geöffnete Räume × 5
--   3. slot_belegt      — Kind-Termine planned/present (späte Absage macht den Platz frei)
--   4. slot_zuteilung   — deterministische Raumzuteilung (Entscheidung 15)
-- Alle intern: kein EXECUTE für anon und authenticated.

begin;

-- ============================================================================
-- 1. slot_raeume
-- ============================================================================
--
-- Eine Zeile je Betriebstag, Uhrzeit und Raum, für den es eine Stammschicht oder eine Abweichung gibt.
--   art  stamm | vertretung | zusatz | faellt_aus
--   offen = ein Coach ist eingeteilt (Anforderung B 9). "Coach fehlt" = faellt_aus mit Stamm-Coach.
-- Raum und Uhrzeit müssen an dem Tag aktiv sein, sonst gibt es den Raum-Termin nicht.

create function public.slot_raeume(p_von date, p_bis date)
returns table(datum date, slot_zeit_id uuid, raum_id uuid, raum_name text, coach_id uuid,
              stamm_coach_id uuid, art text, offen boolean)
language sql stable security definer
set search_path = public, pg_temp
as $$
  with tage as (
    select g::date as d from generate_series(p_von, p_bis, interval '1 day') g
     where public.betriebstag(g::date)
  ),
  basis as (
    select t.d, z.id as z, r.id as r, r.name
      from tage t
      join public.slot_zeiten z on z.aktiv_ab <= t.d and (z.inaktiv_ab is null or t.d < z.inaktiv_ab)
      join public.raeume r on r.aktiv_ab <= t.d and (r.inaktiv_ab is null or t.d < r.inaktiv_ab)
  )
  select b.d, b.z, b.r, b.name,
         case when a.art = 'faellt_aus' then null when a.art is not null then a.coach_id else s.coach_id end,
         s.coach_id,
         coalesce(a.art, 'stamm'),
         case when a.art = 'faellt_aus' then false when a.art is not null then true else s.coach_id is not null end
    from basis b
    left join lateral (
      select x.coach_id from public.stammschichten x
       where x.raum_id = b.r and x.slot_zeit_id = b.z and x.wochentag = extract(isodow from b.d)
         and x.gueltig_ab <= b.d and (x.gueltig_bis is null or b.d <= x.gueltig_bis)
       order by x.gueltig_ab desc
       limit 1
    ) s on true
    left join public.schicht_abweichungen a on a.datum = b.d and a.slot_zeit_id = b.z and a.raum_id = b.r
   where s.coach_id is not null or a.id is not null;
$$;

comment on function public.slot_raeume(date, date) is
  'Raum-Termine je Betriebstag, Uhrzeit und Raum mit eingeteiltem Coach (Stammschicht bzw. Abweichung). offen = Coach da.';

-- ============================================================================
-- 2. / 3. Kapazität und Belegung (Entscheidung 16)
-- ============================================================================

create function public.slot_kapazitaet(p_datum date, p_slot_zeit_id uuid)
returns integer
language sql stable security definer
set search_path = public, pg_temp
as $$
  select 5 * count(*)::int from public.slot_raeume(p_datum, p_datum) r
   where r.slot_zeit_id = p_slot_zeit_id and r.offen;
$$;

create function public.slot_belegt(p_datum date, p_slot_zeit_id uuid, p_ohne_student uuid default null)
returns integer
language sql stable security definer
set search_path = public, pg_temp
as $$
  select count(*)::int from public.kind_termine kt
   where kt.datum = p_datum and kt.slot_zeit_id = p_slot_zeit_id
     and kt.zustand in ('planned', 'present')
     and kt.student_id is distinct from p_ohne_student;
$$;

-- ============================================================================
-- 4. slot_zuteilung (Entscheidung 15)
-- ============================================================================
--
--   0. Kinder in einer festgeschriebenen Session bleiben in deren Raum.
--   1. Geöffnete Räume nach Namen.
--   2. Kinder mit Raum-Stift zuerst in ihren Raum (wenn er geöffnet ist und Platz hat).
--   3. Die übrigen nach Fach gruppiert, größte Gruppe zuerst (bei Gleichstand nach Fach),
--      innerhalb der Gruppe nach Buchungszeit, dann nach id.
--   4. Je Kind: Raum mit demselben Fach, sonst ein leerer Raum, sonst irgendein Raum mit Platz; höchstens 5.
--   5. Wer übrig bleibt: raum_id NULL ("Ohne Raum").
-- Gespeichert wird nur der Raum-Stift; die Zuteilung landet erst beim Festschreiben in session_students.

create function public.slot_zuteilung(p_datum date, p_slot_zeit_id uuid)
returns table(termin_id uuid, student_id uuid, raum_id uuid, fach text, grund text)
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  r_ids   uuid[] := '{}';
  r_zahl  int[]  := '{}';
  r_fach  text[] := '{}';
  k       record;
  i       int;
  v_wahl  int;
  v_fach  text;
begin
  select coalesce(array_agg(x.raum_id order by x.raum_name), '{}') into r_ids
    from public.slot_raeume(p_datum, p_datum) x
   where x.slot_zeit_id = p_slot_zeit_id and x.offen;
  r_zahl := array_fill(0, array[greatest(cardinality(r_ids), 1)]);
  r_fach := array_fill(''::text, array[greatest(cardinality(r_ids), 1)]);

  -- Festgeschriebene Räume kommen dazu, auch wenn sie inzwischen nicht mehr als geöffnet gelten.
  for k in
    select distinct cs.raum_id from public.kind_termine kt join public.coaching_sessions cs on cs.id = kt.session_id
     where kt.datum = p_datum and kt.slot_zeit_id = p_slot_zeit_id and cs.raum_id is not null
       and not cs.raum_id = any (r_ids)
  loop
    r_ids := r_ids || k.raum_id; r_zahl := r_zahl || 0; r_fach := r_fach || ''::text;
  end loop;

  for k in
    select kt.id, kt.student_id, kt.raum_id as stift, kt.raum_fest, cs.raum_id as sess_raum,
           coalesce(nullif(btrim(v.fach), ''), '') as f,
           count(*) over (partition by coalesce(nullif(btrim(v.fach), ''), '')) as gruppe,
           kt.angelegt_am
      from public.kind_termine kt
      join public.vertraege v on v.id = kt.vertrag_id
      left join public.coaching_sessions cs on cs.id = kt.session_id
     where kt.datum = p_datum and kt.slot_zeit_id = p_slot_zeit_id and kt.zustand in ('planned', 'present')
     order by (cs.raum_id is not null) desc, (kt.raum_fest and kt.raum_id = any (r_ids)) desc,
              count(*) over (partition by coalesce(nullif(btrim(v.fach), ''), '')) desc,
              coalesce(nullif(btrim(v.fach), ''), ''), kt.angelegt_am, kt.id
  loop
    v_wahl := null; grund := null;
    v_fach := '|' || k.f || '|';
    if k.sess_raum is not null then
      v_wahl := array_position(r_ids, k.sess_raum); grund := 'session';
    elsif k.raum_fest and k.stift = any (r_ids) and r_zahl[array_position(r_ids, k.stift)] < 5 then
      v_wahl := array_position(r_ids, k.stift); grund := 'stift';
    else
      for i in 1 .. cardinality(r_ids) loop
        if r_zahl[i] < 5 and strpos(r_fach[i], v_fach) > 0 then v_wahl := i; exit; end if;
      end loop;
      if v_wahl is null then
        for i in 1 .. cardinality(r_ids) loop
          if r_zahl[i] = 0 then v_wahl := i; exit; end if;
        end loop;
      end if;
      if v_wahl is null then
        for i in 1 .. cardinality(r_ids) loop
          if r_zahl[i] < 5 then v_wahl := i; exit; end if;
        end loop;
      end if;
    end if;

    termin_id := k.id; student_id := k.student_id; fach := nullif(k.f, '');
    if v_wahl is null then
      raum_id := null;
    else
      raum_id := r_ids[v_wahl];
      r_zahl[v_wahl] := r_zahl[v_wahl] + 1;
      if strpos(r_fach[v_wahl], v_fach) = 0 then r_fach[v_wahl] := r_fach[v_wahl] || v_fach; end if;
    end if;
    return next;
  end loop;
end;
$$;

comment on function public.slot_zuteilung(date, uuid) is
  'Raumzuteilung eines Termins (Entscheidung 15), deterministisch. raum_id NULL = ohne Raum. grund: session (festgeschrieben), stift (von Hand), NULL (automatisch).';

revoke all on function public.slot_raeume(date, date) from public, anon, authenticated;
revoke all on function public.slot_kapazitaet(date, uuid) from public, anon, authenticated;
revoke all on function public.slot_belegt(date, uuid, uuid) from public, anon, authenticated;
revoke all on function public.slot_zuteilung(date, uuid) from public, anon, authenticated;

commit;
