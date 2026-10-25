-- P4: Lenas Prüflauf fragt die 24 Bereiche aus Batus Freigabeliste (docs/lsa/freigabeliste-batu-1025.md, Stand
-- nach LSA-L2) wieder nacheinander ab. Rasit 25.10.2026: „Sie sollen, wenn man Enter drückt, wieder nacheinander
-- abgefragt werden, die die nötig sind.“ Der Lauf folgt pruef_board_soll (rest > 0, ohne MC zuerst); dafür
-- brauchen die Bereiche eine aktive LSA-Sollzeile und ihre Entwürfe das Pilot-Flag.
--
-- a) pruef_soll anlass 'batu_lsa', soll 2, min_ohne_mc 1: die 13 in P3 ruhenden Zeilen der alten Stufe 3 wieder
--    aktiv, dazu neue Zeilen für die übrigen Bereiche der Liste. sort in der Reihenfolge der Liste: KA2 (310–340)
--    vor dem Rückblick (410–570) vor dem Ausblick (910–950). term_binom_faktorisieren und
--    term_binom_quadratdifferenz rücken als Voraussetzung von KA2 nach vorn, ebenso term_binom_quadrat (460 → 305).
--    Die Blöcke nach sort (unter 300 Thema/Grundlagen, 300–399 KA2, 400–899 Rückblick, ab 900 Ausblick) liest die
--    Admin-Übersicht „Batus Freigabeliste“ auf /admin.
-- b) pilot_an über pruef_sammel_schreiben wie in P1/P3 für die Aufgaben mit 'lsa' in einsatz dieser Bereiche, die
--    noch kein Flag haben (geo_winkel_dreieck, Zinsen, Ausblick). Nur Flags; Status, Texte, Lösungen bleiben.
-- Keiner der Bereiche hat eine aktive lsa_vorschau-Zeile; je Knoten bleibt höchstens eine aktive LSA-Zeile.
-- Idempotent; fehlende Knoten und Aufgaben (CI-Neuaufbau) werden übersprungen. Kein begin/commit: mig klammert.

do $p4$
declare
  v_n integer := 0;
  v_soll integer;
  t public.tasks;
begin
  perform set_config('request.jwt.claim.role', 'service_role', true);

  insert into public.pruef_soll (skill_key, anlass, soll, min_ohne_mc, sort, aktiv)
  select v.skill_key, 'batu_lsa', 2, 1, v.sort, true
    from (values
      -- KA2 Quadratische Funktionen: Voraussetzungen (gleichung_quadr_formel prüft die LSA nicht selbst, zuletzt);
      -- term_binom_quadrat ist schon aktiv und erfüllt, rückt nur in den KA2-Block (Admin-Übersicht nach sort)
      ('term_binom_quadrat',          305),
      ('term_binom_faktorisieren',    310),
      ('term_binom_quadratdifferenz', 320),
      ('term_ausklammern',            330),
      ('gleichung_quadr_formel',      340),
      -- Rückblick, behandelte Themen Klasse 7/8
      ('fkt_linear_gleichung',        410),
      ('fkt_linear_steigung',         420),
      ('fkt_linear_yabschnitt',       430),
      ('term_binom_gemischt',         450),
      ('gleichung_lgs_addition',      480),
      ('gleichung_lgs_einsetzen',     490),
      ('gleichung_lgs_grafisch',      500),
      ('geo_flaeche_drachen_raute',   510),
      ('geo_flaeche_term',            520),
      ('geo_flaeche_trapez',          530),
      ('stoch_pfad_summe',            540),
      ('geo_winkel_dreieck',          545),
      ('geo_winkel_thales',           550),
      ('prozent_zins_jahreszins',     560),
      ('prozent_zins_zinseszins',     570),
      -- Ausblick, nur für starke Kinder
      ('fkt_quadr_normalform',        910),
      ('fkt_quadr_nullstellen',       920),
      ('geo_kreis_flaeche',           930),
      ('geo_kreis_umfang',            940),
      ('zahl_potenz_rechnen',         950)
    ) v (skill_key, sort)
    join public.skills s on s.skill_key = v.skill_key
  on conflict (anlass, skill_key) do update
    set aktiv = true, sort = excluded.sort, soll = excluded.soll, min_ohne_mc = excluded.min_ohne_mc;
  get diagnostics v_soll = row_count;

  for t in
    select * from public.tasks x
     where not x.pruef_pilot and 'lsa' = any (x.einsatz)
       and x.skill_key in (select p.skill_key from public.pruef_soll p
                            where p.anlass = 'batu_lsa' and p.aktiv and p.sort between 310 and 950
                              and p.skill_key <> 'term_binom_quadrat')
     order by x.id
  loop
    perform public.pruef_sammel_schreiben('pilot_an', t,
      jsonb_build_object('grund', 'P4: Batus Freigabeliste wieder im Prüflauf (Rasit, 25.10.2026)'));
    v_n := v_n + 1;
  end loop;

  raise notice 'p4: pruef_soll batu_lsa aktiv gesetzt/neu % Zeile(n), pruef_pilot neu fuer % Aufgabe(n)', v_soll, v_n;
end $p4$;
