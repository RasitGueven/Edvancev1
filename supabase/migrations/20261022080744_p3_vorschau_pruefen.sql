-- P3: Lenas Prüfansicht zeigt die Vorschau-Kandidaten aus LSA-V (docs/lsa/freigabeliste-vorschau.md) und zählt
-- sie richtig. pruef_einstellungen.nur_pilot bleibt true; das Board zeigt weiter nur Aufgaben mit pruef_pilot.
--
-- Entscheidungen Rasit 22.10.2026:
--   1. pruef_soll.einsatz ('lsa' | 'session'): für welchen Einsatz ein Anlass zählt. batu_session ist 'session',
--      alle übrigen Anlässe 'lsa'. pruef_board().anlaesse trägt je Aufgabe nur die Anlässe, deren einsatz in
--      tasks.einsatz steht; pruef_board_soll zählt je Knoten nur Aufgaben, die einen der abgefragten Anlässe tragen.
--      So zählt der LSA-Reiter nur Aufgaben mit 'lsa' in einsatz, der Session-Reiter nur Session-Aufgaben.
--   2. „Schon eine aktive Zeile" heißt eine aktive LSA-Zeile (einsatz 'lsa'). Eine batu_session-Zeile hindert
--      nicht: gleichung_zweischrittig und gleichung_einschrittig bekommen zusätzlich lsa_vorschau.
--   3. Die 14 Knoten der alten Stufe 3 aus P2 ruhen (aktiv = false), außer term_binom_quadrat (Rand von
--      Quadratische Funktionen). Ihre Aufgaben stehen danach in keinem Reiter; Prüfstand und Flags bleiben.
--
-- a) pilot_an über pruef_sammel_schreiben wie in P1 (task_admin_protokoll, von = null) für alle Aufgaben mit
--    'lsa' in einsatz der 24 Bereiche aus der Freigabeliste, die noch kein Flag haben. Nur Flags.
-- b) pruef_soll anlass 'lsa_vorschau', soll 2, min_ohne_mc 1, sort ab 610: term_einsetzen, geo_koordinaten,
--    gleichung_modellieren, gleichung_zweischrittig, dann die Ränder von Kreise, Prismen und Zylinder, zuletzt
--    die Bereiche „tiefer“, je Gruppe in der Reihenfolge der Freigabeliste. Bereiche mit aktiver LSA-Zeile
--    (term_binom_quadrat, zahl_wurzel_quadrat, dezimal_div, potenzen, runden_ueberschlag, dezimal_add_sub,
--    dezimal_mult, vorzeichen_add_sub, vorzeichen_mult_div) bekommen keine zweite.
-- c) batu_lsa-Zeilen der alten Stufe 3 auf aktiv = false. Nichts wird gelöscht, kein Flag entfernt.
-- Idempotent; fehlende Knoten und Aufgaben (CI-Neuaufbau) werden übersprungen. Kein begin/commit: mig klammert.

-- ── 1. pruef_soll.einsatz ──────────────────────────────────────────────────
alter table public.pruef_soll
  add column if not exists einsatz text not null default 'lsa' check (einsatz in ('lsa', 'session'));
comment on column public.pruef_soll.einsatz is
  'Fuer welchen Einsatz der Anlass zaehlt: nur Aufgaben mit diesem Wert in tasks.einsatz tragen ihn (P3). '
  'Default lsa: ein neuer Session-Anlass braucht ausdruecklich einsatz = session.';
update public.pruef_soll set einsatz = 'session' where anlass = 'batu_session' and einsatz <> 'session';

-- ── 2. pruef_board: Anlässe je Aufgabe nach einsatz ────────────────────────
create or replace function public.pruef_board()
returns table (task_id uuid, stufe text, thema_key text, thema_label text, thema_sort integer, skill_key text,
               skill_label text, kurztitel text, reihenfolge bigint, lena_status text, geaendert boolean,
               letzte_dauer_sek integer, anlaesse text[], hat_hinweise boolean)
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
begin
  if not public.darf_pruefen() then
    raise exception 'pruef_board: kein Pruefrecht' using errcode = '42501';
  end if;
  return query
  with b as (
    select t.id, t.title, t.status, t.source_ref, t.skill_key sk_jetzt, t.einsatz,
           coalesce(a.ausgang ->> 'skill_key', t.skill_key) sk,
           case when a.task_id is not null then (a.ausgang ->> 'sondierrang')::int else t.sondierrang end sr
      from public.tasks t
      left join public.task_pruefung_ausgang a on a.task_id = t.id
     where public.pruef_ausschluss(t.id) is null
       and (t.pruef_pilot or not coalesce((select e.nur_pilot from public.pruef_einstellungen e limit 1), false)))
  select b.id, th.stufe, th.thema_key, th.label, th.sort, b.sk_jetzt, sj.label,
         public.pruef_kurztitel(b.title),
         row_number() over (order by case th.stufe when 'erste' then 1 when 'zweite' then 2 else 3 end,
                                     th.sort nulls last, s.fundament_tiefe, b.sk, b.sr nulls last,
                                     b.source_ref, b.id),
         public.pruef_lena_status(b.status),
         coalesce(jsonb_array_length(lp.aenderungen) > 0, false),
         lp.dauer_sek,
         coalesce((select array_agg(ps.anlass order by ps.anlass) from public.pruef_soll ps
                    where ps.aktiv and ps.skill_key = b.sk_jetzt and ps.einsatz = any (b.einsatz)), '{}'::text[]),
         coalesce((select jsonb_array_length(ts.hints) > 0
                     from public.task_solutions ts where ts.task_id = b.id), false)
    from b
    join public.skills s on s.skill_key = b.sk
    join public.skill_thema st on st.skill_key = b.sk
    join public.themen th on th.thema_key = st.thema_key
    left join public.skills sj on sj.skill_key = b.sk_jetzt
    left join lateral (select p.aenderungen, p.dauer_sek from public.task_pruefungen p
                        where p.task_id = b.id order by p.geprueft_am desc limit 1) lp on true;
end $$;

-- ── 3. pruef_board_soll: nur Aufgaben mit einem der abgefragten Anlässe zählen ──
create or replace function public.pruef_board_soll(p_anlass text default null)
returns table (skill_key text, skill_label text, thema_key text, thema_label text, thema_sort integer,
               stufe text, sort integer, anlaesse text[], soll integer, min_ohne_mc integer, im_board integer,
               gezaehlt integer, gezaehlt_ohne_mc integer, rest integer, reicht boolean)
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
begin
  if not public.darf_pruefen() then
    raise exception 'pruef_board_soll: kein Pruefrecht' using errcode = '42501';
  end if;
  return query
  with s as (
    select p.skill_key sk, max(p.soll) so, max(p.min_ohne_mc) mo, min(p.sort) srt,
           array_agg(p.anlass order by p.sort, p.anlass) an
      from public.pruef_soll p
     where p.aktiv and (p_anlass is null or p.anlass = p_anlass)
     group by p.skill_key),
  b as (
    select s.sk, count(*)::int n,
           count(*) filter (where z.lena_status in ('passt', 'freigegeben'))::int g,
           count(*) filter (where z.lena_status in ('passt', 'freigegeben')
                              and t.input_type is distinct from 'MC')::int g_ohne
      from public.pruef_board() z
      join s on s.sk = z.skill_key and z.anlaesse && s.an
      join public.tasks t on t.id = z.task_id
     group by s.sk)
  select s.sk, k.label, th.thema_key, th.label, th.sort, th.stufe, s.srt, s.an, s.so, s.mo,
         coalesce(b.n, 0), coalesce(b.g, 0), coalesce(b.g_ohne, 0),
         greatest(s.so - coalesce(b.g, 0), s.mo - coalesce(b.g_ohne, 0), 0),
         coalesce(b.g, 0) >= s.so and coalesce(b.g_ohne, 0) >= s.mo
    from s
    join public.skills k on k.skill_key = s.sk
    left join public.skill_thema st on st.skill_key = s.sk
    left join public.themen th on th.thema_key = st.thema_key
    left join b on b.sk = s.sk
   order by s.srt, s.sk;
end $$;

-- ── 4. Daten: c) Stufe 3 ruht, a) Pilot-Flags, b) Sollzeilen lsa_vorschau ──
update public.pruef_soll
   set aktiv = false
 where anlass = 'batu_lsa' and aktiv
   and skill_key in ('fkt_linear_gleichung', 'fkt_linear_steigung', 'fkt_linear_yabschnitt',
                     'term_binom_faktorisieren', 'term_binom_gemischt', 'term_binom_quadratdifferenz',
                     'gleichung_lgs_addition', 'gleichung_lgs_einsetzen', 'gleichung_lgs_grafisch',
                     'geo_flaeche_drachen_raute', 'geo_flaeche_term', 'geo_flaeche_trapez', 'stoch_pfad_summe',
                     'geo_winkel_thales');

do $p3$
declare
  v_bereiche text[] := array[
    -- Rand, Quadratische Funktionen (term_einsetzen für beide Themen)
    'term_einsetzen', 'geo_koordinaten', 'gleichung_modellieren', 'gleichung_zweischrittig', 'term_binom_quadrat',
    'zahl_wurzel_quadrat',
    -- Rand, Kreise, Prismen und Zylinder
    'dezimal_div', 'geo_flaeche_dreieck', 'geo_flaeche_rechteck', 'geo_umfang', 'groessen_flaechen', 'potenzen',
    'proportionalitaet', 'runden_ueberschlag',
    -- tiefer
    'dezimal_add_sub', 'dezimal_mult', 'gleichung_beidseitig', 'gleichung_einschrittig', 'term_ausmultiplizieren',
    'term_zusammenfassen', 'vorzeichen_add_sub', 'vorzeichen_mult_div', 'vorzeichen_vorrang', 'groessen_laengen'];
  v_n integer := 0;
  v_soll integer;
  t public.tasks;
begin
  perform set_config('request.jwt.claim.role', 'service_role', true);

  for t in
    select * from public.tasks x
     where not x.pruef_pilot and x.skill_key = any (v_bereiche) and 'lsa' = any (x.einsatz)
     order by x.id
  loop
    perform public.pruef_sammel_schreiben('pilot_an', t,
      jsonb_build_object('grund', 'P3: Vorschau-Kandidaten aus LSA-V für Lena sichtbar (Rasit, 22.10.2026)'));
    v_n := v_n + 1;
  end loop;

  insert into public.pruef_soll (skill_key, anlass, soll, min_ohne_mc, sort)
  select v.skill_key, 'lsa_vorschau', 2, 1, v.sort
    from (values
      ('term_einsetzen',          610),
      ('geo_koordinaten',         620),
      ('gleichung_modellieren',   630),
      ('gleichung_zweischrittig', 640),
      -- Rand, Kreise, Prismen und Zylinder
      ('dezimal_div',             650),
      ('geo_flaeche_dreieck',     660),
      ('geo_flaeche_rechteck',    670),
      ('geo_umfang',              680),
      ('groessen_flaechen',       690),
      ('potenzen',                700),
      ('proportionalitaet',       710),
      ('runden_ueberschlag',      720),
      -- tiefer
      ('dezimal_add_sub',         730),
      ('dezimal_mult',            740),
      ('gleichung_beidseitig',    750),
      ('gleichung_einschrittig',  760),
      ('term_ausmultiplizieren',  770),
      ('term_zusammenfassen',     780),
      ('vorzeichen_add_sub',      790),
      ('vorzeichen_mult_div',     800),
      ('vorzeichen_vorrang',      810),
      ('groessen_laengen',        820)
    ) v (skill_key, sort)
    join public.skills s on s.skill_key = v.skill_key
   where not exists (select 1 from public.pruef_soll p
                      where p.skill_key = v.skill_key and p.aktiv and p.einsatz = 'lsa')
  on conflict (anlass, skill_key) do nothing;
  get diagnostics v_soll = row_count;

  raise notice 'p3: pruef_pilot neu fuer % Aufgabe(n), pruef_soll lsa_vorschau neu % Zeile(n)', v_n, v_soll;
end $p3$;
