-- R1.3 Signale und Eingriffe (Entscheidungen 14 und 15).
--
-- Signale werden nicht gespeichert, sondern aus Antworten, Ereignissen und
-- Stellschrauben berechnet (C0-Empfehlung). Gespeichert wird nur, was ein
-- Mensch oder eine spaetere Funktion meldet bzw. erledigt:
--   - 'signal'-Ereignisse fuer kandidat / entscheidung / hinweis (gemeldet von
--     A1/E1 in P2 ueber signal_melden),
--   - 'signal_erledigt' (signal_erledigen) setzt die Uhr je (Kind, Art) neu.
-- Berechnet:
--   - haengt: signal_fehlversuche Fehlversuche in Folge (seit dem letzten
--     Richtig bzw. Erledigt), signal_minuten_ohne_fortschritt ohne Eingabe bei
--     offener Aufgabe, erklaerrunden_bis_signal falsche Checks je Kernidee
--     ('check'-Ereignisse, verdrahtet E1 in P2).
--   - hinweis: Stimmung "angespannt" im Check-in (Dummy: "kurz ansprechen").
-- Warteschlange: kandidat (0) vor entscheidung (1) vor haengt (2) vor hinweis
-- (3), bei gleicher Art das aelteste zuerst. Hoechstens
-- mastery_kandidaten_je_raum Mastery-Pruefungen je Session (erledigte zaehlen mit).

create function public.session_signale_intern(p_session_id uuid)
returns table (student_id uuid, art text, rang int, grund text, seit timestamptz, details jsonb)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with
  par as (
    select public.session_wert_zahl(p_session_id, 'signal_fehlversuche')::int as n_fehl,
           make_interval(mins => public.session_wert_zahl(p_session_id, 'signal_minuten_ohne_fortschritt')::int) as ohne,
           public.session_wert_zahl(p_session_id, 'erklaerrunden_bis_signal')::int as n_runden,
           public.session_wert_zahl(p_session_id, 'mastery_kandidaten_je_raum')::int as n_kand
  ),
  erl as (
    select e.student_id, e.payload ->> 'art' as art, max(e.zeit) as z
      from public.session_ereignisse e
     where e.session_id = p_session_id and e.typ = 'signal_erledigt'
     group by 1, 2
  ),
  kinder as (
    select ss.student_id,
           coalesce((select z from erl where erl.student_id = ss.student_id and erl.art = 'haengt'), '-infinity') as erl_h
      from public.session_students ss where ss.session_id = p_session_id
  ),
  gemeldet as (
    select e.student_id, e.payload ->> 'art' as art, coalesce(e.payload ->> 'grund', e.payload ->> 'art') as grund,
           e.zeit as seit, e.payload as details
      from public.session_ereignisse e
      left join erl on erl.student_id = e.student_id and erl.art = e.payload ->> 'art'
     where e.session_id = p_session_id and e.typ = 'signal' and e.zeit > coalesce(erl.z, '-infinity')
  ),
  fehl as (
    select a.student_id, a.zeit, a.task_id,
           row_number() over (partition by a.student_id order by a.zeit, a.id) as n,
           count(*) over (partition by a.student_id) as gesamt
      from public.session_antworten a join kinder k on k.student_id = a.student_id
     where a.session_id = p_session_id and a.ergebnis <> 'richtig'
       and a.zeit > greatest(k.erl_h, coalesce((select max(r.zeit) from public.session_antworten r
                     where r.session_id = p_session_id and r.student_id = a.student_id and r.ergebnis = 'richtig'),
                     '-infinity'))
  ),
  offen as (
    select k.student_id, k.erl_h, a.task_id, a.zeit as ausgabe_zeit
      from kinder k
      join public.session_tablets st on st.session_id = p_session_id and st.student_id = k.student_id
                                    and st.geloest_am is null
      cross join lateral public.session_aktuelle_ausgabe(p_session_id, k.student_id) a
     where a.id is not null
       and public.session_phase(p_session_id, k.student_id) in ('warmup', 'kern', 'checkout')
       and not exists (select 1 from public.session_antworten r where r.session_id = p_session_id
                        and r.student_id = k.student_id and r.task_id = a.task_id and r.ergebnis = 'richtig'
                        and r.zeit >= a.zeit)
  ),
  still as (
    select o.student_id, o.task_id,
           greatest(o.ausgabe_zeit, o.erl_h,
             coalesce((select max(r.zeit) from public.session_antworten r
                        where r.session_id = p_session_id and r.student_id = o.student_id), '-infinity'),
             coalesce((select max(e.zeit) from public.session_ereignisse e where e.session_id = p_session_id
                        and e.student_id = o.student_id and e.typ = 'hinweis'), '-infinity')) as zuletzt
      from offen o
  ),
  checks as (
    select e.student_id, e.payload ->> 'kernidee' as kernidee, e.zeit,
           row_number() over (partition by e.student_id, e.payload ->> 'kernidee' order by e.zeit, e.id) as n
      from public.session_ereignisse e join kinder k on k.student_id = e.student_id
     where e.session_id = p_session_id and e.typ = 'check' and e.payload ->> 'ergebnis' = 'falsch'
       and e.zeit > k.erl_h
  ),
  alle as (
    select g.student_id, g.art, g.grund, g.seit, g.details from gemeldet g
    union all
    select f.student_id, 'haengt', 'fehlversuche', f.zeit,
           jsonb_build_object('anzahl', f.gesamt, 'task_id',
             (select f2.task_id from fehl f2 where f2.student_id = f.student_id order by f2.n desc limit 1))
      from fehl f, par where f.n = par.n_fehl
    union all
    select s.student_id, 'haengt', 'ohne_eingabe', s.zuletzt + par.ohne,
           jsonb_build_object('task_id', s.task_id, 'minuten',
             floor(extract(epoch from clock_timestamp() - s.zuletzt) / 60)::int)
      from still s, par where clock_timestamp() - s.zuletzt >= par.ohne
    union all
    select c.student_id, 'haengt', 'erklaerrunden', c.zeit, jsonb_build_object('kernidee', c.kernidee)
      from checks c, par where c.n = par.n_runden
    union all
    select c.student_id, 'hinweis', 'stimmung', c.kind_am, jsonb_build_object('stimmung', c.stimmung)
      from public.session_checkin c
      left join erl on erl.student_id = c.student_id and erl.art = 'hinweis'
     where c.session_id = p_session_id and c.stimmung = 'angespannt' and c.kind_am > coalesce(erl.z, '-infinity')
  ),
  je_art as (
    select distinct on (a.student_id, a.art) a.*
      from alle a where a.art in ('kandidat', 'entscheidung', 'haengt', 'hinweis')
     order by a.student_id, a.art, a.seit
  ),
  gerankt as (
    select j.*, case j.art when 'kandidat' then 0 when 'entscheidung' then 1 when 'haengt' then 2 else 3 end as rang,
           row_number() over (partition by j.art = 'kandidat' order by j.seit) as kand_nr
      from je_art j
  )
  select g.student_id, g.art, g.rang, g.grund, g.seit, g.details
    from gerankt g, par
   where g.art <> 'kandidat'
      or g.kand_nr <= par.n_kand - (select count(*) from public.session_ereignisse e where e.session_id = p_session_id
                                     and e.typ = 'signal_erledigt' and e.payload ->> 'art' = 'kandidat')
   order by g.rang, g.seit, g.student_id
$$;

create function public.raum_signale(p_session_id uuid)
returns table (student_id uuid, art text, rang int, grund text, seit timestamptz, details jsonb)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.session_coach_pruefen(p_session_id, 'raum_signale');
  return query select * from public.session_signale_intern(p_session_id);
end;
$$;

create function public.session_kind_pruefen(p_session_id uuid, p_student_id uuid, p_wer text)
returns void
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.session_coach_pruefen(p_session_id, p_wer);
  if not exists (select 1 from public.session_students where session_id = p_session_id and student_id = p_student_id) then
    raise exception '%: Kind ist in dieser Session nicht gebucht', p_wer using errcode = 'P0002';
  end if;
end;
$$;

-- Meldet ein Signal, das nicht aus Antworten folgt (Mastery-Kandidat aus A1,
-- Entscheidung "eine Stufe tiefer" nach dem Warm-up, Hinweis). Coach, Admin
-- oder Systemaufruf (P2-Funktionen).
create function public.signal_melden(p_session_id uuid, p_student_id uuid, p_art text, p_payload jsonb default '{}')
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.ist_systemaufruf() then
    perform public.session_kind_pruefen(p_session_id, p_student_id, 'signal_melden');
  end if;
  if p_art is null or p_art not in ('kandidat', 'entscheidung', 'hinweis') then
    raise exception 'signal_melden: unbekannte Art %', p_art using errcode = '22023';
  end if;
  perform public.session_ereignis(p_session_id, p_student_id, 'signal',
                                  coalesce(p_payload, '{}'::jsonb) || jsonb_build_object('art', p_art));
end;
$$;

create function public.signal_erledigen(p_session_id uuid, p_student_id uuid, p_art text)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.session_kind_pruefen(p_session_id, p_student_id, 'signal_erledigen');
  if p_art is null or p_art not in ('kandidat', 'entscheidung', 'haengt', 'hinweis') then
    raise exception 'signal_erledigen: unbekannte Art %', p_art using errcode = '22023';
  end if;
  perform public.session_ereignis(p_session_id, p_student_id, 'signal_erledigt', jsonb_build_object('art', p_art));
end;
$$;

-- Interventionsleiter (Entscheidung 14): 1 und 2 werden gezaehlt, ab 3 mit
-- Fehlbild (Pflicht, aus fehlbild_labels) fuer die Akte; 4 schreibt zusaetzlich
-- entscheidung_pfad (das Umsetzen im Lernpfad verdrahtet P2 mit A1).
create function public.eingriff_notieren(p_session_id uuid, p_student_id uuid, p_stufe int,
                                         p_fehlbild_slug text default null)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_slug text := nullif(btrim(coalesce(p_fehlbild_slug, '')), '');
begin
  perform public.session_kind_pruefen(p_session_id, p_student_id, 'eingriff_notieren');
  if p_stufe is null or p_stufe not between 1 and 4 then
    raise exception 'eingriff_notieren: Stufe 1 bis 4' using errcode = '22023';
  end if;
  if p_stufe >= 3 and v_slug is null then
    raise exception 'eingriff_notieren: ab Stufe 3 ist das Fehlbild Pflicht' using errcode = '22023',
      hint = 'fehlbild_pflicht';
  end if;
  if v_slug is not null and not exists (select 1 from public.fehlbild_labels where slug = v_slug) then
    raise exception 'eingriff_notieren: unbekanntes Fehlbild %', v_slug using errcode = '22023';
  end if;
  perform public.session_ereignis(p_session_id, p_student_id, 'eingriff',
    jsonb_strip_nulls(jsonb_build_object('stufe', p_stufe, 'fehlbild_slug', v_slug)));
  if p_stufe = 4 then
    perform public.session_ereignis(p_session_id, p_student_id, 'entscheidung_pfad',
      jsonb_build_object('entscheidung', 'tiefer', 'quelle', 'eingriff', 'fehlbild_slug', v_slug));
  end if;
end;
$$;

-- Entscheidung auf ein 'entscheidung'-Signal (Dummy: Emir nach dem Warm-up).
-- Schreibt entscheidung_pfad und erledigt das Signal. Umsetzen: P2 mit A1.
create function public.pfad_entscheiden(p_session_id uuid, p_student_id uuid, p_entscheidung text,
                                        p_skill_key text default null)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.session_kind_pruefen(p_session_id, p_student_id, 'pfad_entscheiden');
  if p_entscheidung is null or p_entscheidung not in ('tiefer', 'plan') then
    raise exception 'pfad_entscheiden: tiefer oder plan' using errcode = '22023';
  end if;
  perform public.session_ereignis(p_session_id, p_student_id, 'entscheidung_pfad',
    jsonb_strip_nulls(jsonb_build_object('entscheidung', p_entscheidung, 'quelle', 'coach', 'skill_key', p_skill_key)));
  perform public.session_ereignis(p_session_id, p_student_id, 'signal_erledigt',
                                  jsonb_build_object('art', 'entscheidung'));
end;
$$;

revoke all on function
  public.session_signale_intern(uuid), public.raum_signale(uuid), public.session_kind_pruefen(uuid, uuid, text),
  public.signal_melden(uuid, uuid, text, jsonb), public.signal_erledigen(uuid, uuid, text),
  public.eingriff_notieren(uuid, uuid, int, text), public.pfad_entscheiden(uuid, uuid, text, text)
  from public, anon, authenticated;
grant execute on function
  public.raum_signale(uuid), public.signal_melden(uuid, uuid, text, jsonb), public.signal_erledigen(uuid, uuid, text),
  public.eingriff_notieren(uuid, uuid, int, text), public.pfad_entscheiden(uuid, uuid, text, text)
  to authenticated;
