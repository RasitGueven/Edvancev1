-- ============================================================================
-- A18: Geometrie-Fundament — 6 Skills + 9 Kanten
--
-- SETZT A14 VORAUS (skills, skill_kante, Tiefen-Trigger skill_kante_tiefe).
--
-- KEIN begin/commit: Der Pending-Runner (bzw. der Dry-Run) klammert die Datei.
-- Ein eigenes begin/commit hier wuerde diese aeussere Transaktion brechen.
--
-- FUEGT NUR DATEN HINZU: sechs Zeilen in skills, neun in skill_kante. Keine
-- neue Struktur, keine Funktion, kein Trigger — die Tiefen-Invariante aus A14
-- greift fuer die neuen Kanten von selbst.
--
-- NICHT hier: geo_koordinatensystem, geo_winkel_messen. Beide brauchen eine
-- Abbildung (Generator existiert noch nicht); mit null Aufgaben blieben sie
-- dauerhaft 'ungeprueft' und wuerden die Pruefzahlen verwaessern. Sie kommen
-- additiv mit dem Generator-Lauf.
--
-- WIRKUNG AUF DIE PRUEFZAHLEN (in den Pruefdateien nachgezogen):
--   Skills 32 -> 38 · Kanten 41 -> 50 · Blaetter 14 -> 19 · P4 32/14 -> 38/19.
--   Fuenf der sechs neuen Skills sind Blaetter; geo_flaeche_rechteck nicht,
--   weil geo_flaeche_dreieck und geo_volumen_quader darauf sitzen.
--   P3 (erster gieriger Zug = prozent_veraenderung, groesster Abschluss) haelt:
--   kein Geometrie-Skill deckt mehr (im Dry-Run bestaetigt).
-- ============================================================================

-- ── 1. Die Skills ──────────────────────────────────────────────────────────

insert into public.skills (skill_key, label, klasse_herkunft, fundament_tiefe) values
  ('geo_umfang',           'Umfang von Rechteck und Dreieck',        5, 3),
  ('geo_flaeche_rechteck', 'Fläche von Rechteck und Quadrat',        5, 3),
  ('geo_winkel_summe',     'Winkelsummen im Dreieck und Viereck',    7, 3),
  ('geo_flaeche_dreieck',  'Fläche von Dreieck und Parallelogramm',  6, 4),
  ('geo_volumen_quader',   'Volumen und Oberfläche des Quaders',     6, 4),
  ('geo_massstab',         'Maßstab',                                6, 5)
on conflict (skill_key) do nothing;

-- ── 2. Die Kanten (skill <- voraussetzt) ───────────────────────────────────
--
-- Jede Kante muss die Tiefe ECHT verringern (A14-Trigger). Steht eine Tiefe
-- falsch, wirft der Trigger hier — dann ist die Tiefe zu korrigieren, nicht der
-- Trigger. Alle neun sind streng fallend:
--   geo_umfang(3)          <- dezimal_add_sub(1), dezimal_mult(2)
--   geo_flaeche_rechteck(3)<- dezimal_mult(2)
--   geo_winkel_summe(3)    <- dezimal_add_sub(1)
--   geo_flaeche_dreieck(4) <- geo_flaeche_rechteck(3), dezimal_div(3)
--   geo_volumen_quader(4)  <- geo_flaeche_rechteck(3)
--   geo_massstab(5)        <- groessen_laengen(3), proportionalitaet(4)

insert into public.skill_kante (skill_key, voraussetzt_skill_key) values
  ('geo_umfang',           'dezimal_add_sub'),
  ('geo_umfang',           'dezimal_mult'),
  ('geo_flaeche_rechteck', 'dezimal_mult'),
  ('geo_winkel_summe',     'dezimal_add_sub'),
  ('geo_flaeche_dreieck',  'geo_flaeche_rechteck'),
  ('geo_flaeche_dreieck',  'dezimal_div'),
  ('geo_volumen_quader',   'geo_flaeche_rechteck'),
  ('geo_massstab',         'groessen_laengen'),
  ('geo_massstab',         'proportionalitaet')
on conflict (skill_key, voraussetzt_skill_key) do nothing;

-- ── 3. Selbsttest ──────────────────────────────────────────────────────────
--
-- Rechnet die Pruefzahlen aus der Vorgabe nach. Weicht eine ab, wirft der Block
-- und die (aeussere) Transaktion rollt zurueck.

do $$
declare
  v_n int;
begin
  select count(*) into v_n from public.skills where skill_key like 'geo_%';
  if v_n <> 6 then raise exception 'A18: % Geometrie-Skills statt 6', v_n; end if;

  select count(*) into v_n from public.skills;
  if v_n <> 38 then raise exception 'A18: % Skills statt 38', v_n; end if;

  select count(*) into v_n from public.skill_kante;
  if v_n <> 50 then raise exception 'A18: % Kanten statt 50', v_n; end if;

  -- Blaetter: Skills, auf denen nichts aufbaut.
  select count(*) into v_n from public.skills s
   where not exists (select 1 from public.skill_kante k
                      where k.voraussetzt_skill_key = s.skill_key);
  if v_n <> 19 then raise exception 'A18: % Blaetter statt 19', v_n; end if;

  -- geo_flaeche_rechteck ist KEIN Blatt (zwei Geo-Skills sitzen darauf).
  if not exists (select 1 from public.skill_kante
                  where voraussetzt_skill_key = 'geo_flaeche_rechteck') then
    raise exception 'A18: geo_flaeche_rechteck haette Abhaengige haben muessen';
  end if;

  raise notice 'A18 ok: 6 Geo-Skills, 38 Skills, 50 Kanten, 19 Blaetter.';
end $$;
