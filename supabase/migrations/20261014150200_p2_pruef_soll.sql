-- P2 · M2: Sollzahlen je Knoten für Lenas Board (Tabelle pruef_soll).
--
-- Entscheidung Rasit 14.10.2026: Wie viele Aufgaben je Knoten Lena für einen Anlass geprüft haben muss, steht als
-- Daten in der DB, nicht im Code. Eine Zeile je (Anlass, Knoten):
--   soll         so viele Aufgaben müssen auf review („passt“) oder ready stehen,
--   min_ohne_mc  davon mindestens so viele ohne Multiple Choice (input_type <> 'MC'),
--   sort         Reihenfolge im Board (Themen und Knoten), wie in Batus Freigabeliste,
--   aktiv        nur aktive Zeilen zählen.
-- Gelten für einen Knoten mehrere aktive Anlässe, zählt der höhere Wert (pruef_board_soll, M3).
--
-- Rechte: lesen alle mit Prüfrecht (darf_pruefen: admin oder coach mit darf_pruefen), schreiben nur admin, anon
-- nichts. Befüllt für zwei Anlässe:
--   batu_lsa      Stufe 1 je 6, Stufe 2 je 3, Stufe 3 je 2; min_ohne_mc je 1.
--   batu_session  die E3-Session-Aufgaben je Knoten (49; Anzahl per dbread 14.10.2026), min_ohne_mc 0.
-- sort: Stufe 1 (1xx), Stufe 2 mit potenzen zuerst (2xx), Session (3xx), Stufe 3 (4xx). Die Reihenfolge der
-- Session-Knoten ist nicht vorgegeben; gewählt: Klasse 7/8 vor 9/10, einfache Gleichungen vor quadratischen.
-- Fehlt ein Knoten in skills (CI-Neuaufbau), wird seine Zeile übersprungen; wie skill_thema hängt die Zeile am
-- Knoten (on delete cascade). Kein begin/commit: mig klammert.

create table public.pruef_soll (
  skill_key   text        not null references public.skills (skill_key) on update cascade on delete cascade,
  anlass      text        not null check (anlass ~ '^[a-z][a-z0-9_]*$'),
  soll        integer     not null check (soll > 0),
  min_ohne_mc integer     not null default 0 check (min_ohne_mc >= 0 and min_ohne_mc <= soll),
  sort        integer     not null,
  aktiv       boolean     not null default true,
  angelegt_am timestamptz not null default now(),
  primary key (anlass, skill_key)
);

comment on table public.pruef_soll is
  'Sollzahlen je Knoten und Anlass fuer Lenas Board (P2). Gezaehlt werden Aufgaben auf review oder ready; '
  'mehrere aktive Anlaesse je Knoten: der hoehere Wert zaehlt (pruef_board_soll).';

alter table public.pruef_soll enable row level security;
create policy pruef_soll_lesen on public.pruef_soll
  for select to authenticated using (public.darf_pruefen());
create policy pruef_soll_admin on public.pruef_soll
  for all to authenticated
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');
revoke all on public.pruef_soll from anon, authenticated;
grant select, insert, update, delete on public.pruef_soll to authenticated;
grant all on public.pruef_soll to service_role;

insert into public.pruef_soll (skill_key, anlass, soll, min_ohne_mc, sort)
select v.skill_key, v.anlass, v.soll, v.min_ohne_mc, v.sort
  from (values
    -- batu_lsa · Stufe 1
    ('zahl_wurzel_irrational',      'batu_lsa',     6, 1, 110),
    ('zahl_wurzel_naeherung',       'batu_lsa',     6, 1, 120),
    ('zahl_wurzel_teilweise',       'batu_lsa',     6, 1, 130),
    ('zahl_wurzel_gesetze',         'batu_lsa',     6, 1, 140),
    ('zahl_wurzel_quadrat',         'batu_lsa',     6, 1, 150),
    -- batu_lsa · Stufe 2 (potenzen zuerst)
    ('potenzen',                    'batu_lsa',     3, 1, 210),
    ('bruch_dezimal',               'batu_lsa',     3, 1, 220),
    ('dezimal_div',                 'batu_lsa',     3, 1, 230),
    ('dezimal_mult',                'batu_lsa',     3, 1, 240),
    ('vorzeichen_mult_div',         'batu_lsa',     3, 1, 250),
    ('runden_ueberschlag',          'batu_lsa',     3, 1, 260),
    ('dezimal_add_sub',             'batu_lsa',     3, 1, 270),
    ('bruch_kuerzen',               'batu_lsa',     3, 1, 280),
    ('vorzeichen_add_sub',          'batu_lsa',     3, 1, 290),
    -- batu_session · E3
    ('vorzeichen_add_sub',          'batu_session', 7, 0, 310),
    ('term_ausklammern',            'batu_session', 6, 0, 320),
    ('gleichung_einschrittig',      'batu_session', 6, 0, 330),
    ('gleichung_zweischrittig',     'batu_session', 6, 0, 340),
    ('gleichung_quadr_wurzel',      'batu_session', 6, 0, 350),
    ('gleichung_quadr_faktor',      'batu_session', 6, 0, 360),
    ('gleichung_quadr_formel',      'batu_session', 6, 0, 370),
    ('gleichung_quadr_anzahl',      'batu_session', 6, 0, 380),
    -- batu_lsa · Stufe 3 (die 15 Knoten aus P1)
    ('fkt_linear_gleichung',        'batu_lsa',     2, 1, 410),
    ('fkt_linear_steigung',         'batu_lsa',     2, 1, 420),
    ('fkt_linear_yabschnitt',       'batu_lsa',     2, 1, 430),
    ('term_binom_faktorisieren',    'batu_lsa',     2, 1, 440),
    ('term_binom_gemischt',         'batu_lsa',     2, 1, 450),
    ('term_binom_quadrat',          'batu_lsa',     2, 1, 460),
    ('term_binom_quadratdifferenz', 'batu_lsa',     2, 1, 470),
    ('gleichung_lgs_addition',      'batu_lsa',     2, 1, 480),
    ('gleichung_lgs_einsetzen',     'batu_lsa',     2, 1, 490),
    ('gleichung_lgs_grafisch',      'batu_lsa',     2, 1, 500),
    ('geo_flaeche_drachen_raute',   'batu_lsa',     2, 1, 510),
    ('geo_flaeche_term',            'batu_lsa',     2, 1, 520),
    ('geo_flaeche_trapez',          'batu_lsa',     2, 1, 530),
    ('stoch_pfad_summe',            'batu_lsa',     2, 1, 540),
    ('geo_winkel_thales',           'batu_lsa',     2, 1, 550)
  ) v (skill_key, anlass, soll, min_ohne_mc, sort)
  join public.skills s on s.skill_key = v.skill_key
on conflict (anlass, skill_key) do nothing;

do $p2m2$
begin
  raise notice 'p2_m2: pruef_soll % Zeile(n)', (select count(*) from public.pruef_soll);
end $p2m2$;
