-- K9-Rest, Thema quadrfkt — Substrat: 5 Knoten, 9 Kanten, 3 neue Fehlbilder. KEINE Aufgaben.
-- Erzeugt von tools/k9-rest-substrat.mjs aus docs/k9-rest/graph.json — nicht von Hand editieren.
--
-- Kernlehrplan Mathematik NRW G9, Fkt-8, Fkt-9 (Zweite Stufe): Parabeln, Scheitelpunktform, Nullstellen, Extremwertprobleme.
-- klasse_herkunft = 9 folgt dem KLP (Zweite Stufe) und dem Thema themen.quadratische_funktionen (Klasse 9);
-- eine Bindung an ein bestimmtes Schuljahr ist damit nicht behauptet.
--
-- Einspiel-Reihenfolge: nach allen Migrationen von origin/dev und nach substrat_k9_quadrgl
-- (Knoten der Kanten muessen stehen); vor 20261003105904_aufgaben_k9_quadrfkt.sql.
-- Keine Kante auf Knoten des parallelen Laufs feat/k8-rest (LGS, Wahrscheinlichkeit Kl. 8,
-- Flaechen, Winkel): beide Laeufe bleiben unabhaengig einspielbar (Befunde in docs/k9-rest/befunde.md).
--
-- Kein begin/commit: `mig` spielt die Datei mit psql -1 in EINER Transaktion ein. Die
-- Knoten stehen vor den Kanten, weil skill_kante_tiefe die Tiefe beider Seiten schon beim
-- Insert liest. Idempotent: on conflict do nothing.


-- ── 1. Knoten ───────────────────────────────────────────────────────────────
--
-- Tiefe = 1 + tiefste direkte Voraussetzung (Plan: docs/k9-rest/phase1.md, Teil 1b):
--   fkt_quadr_parabel                  6  ueber term_einsetzen, geo_koordinaten
--   fkt_quadr_scheitel                 7  ueber fkt_quadr_parabel
--   fkt_quadr_normalform               8  ueber fkt_quadr_scheitel, term_binom_quadrat
--   fkt_quadr_nullstellen              9  ueber gleichung_quadr_formel, fkt_quadr_parabel
--   fkt_quadr_extrem                   9  ueber fkt_quadr_normalform, gleichung_modellieren

insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
values
  ('fkt_quadr_parabel', 'Normalparabel verschieben und strecken', 'mathematik', 9, 6),
  ('fkt_quadr_scheitel', 'Scheitelpunkt aus der Scheitelpunktform', 'mathematik', 9, 7),
  ('fkt_quadr_normalform', 'Von der Normalform zur Scheitelpunktform', 'mathematik', 9, 8),
  ('fkt_quadr_nullstellen', 'Nullstellen quadratischer Funktionen', 'mathematik', 9, 9),
  ('fkt_quadr_extrem', 'Extremwertaufgaben mit quadratischen Funktionen', 'mathematik', 9, 9)
on conflict (skill_key) do nothing;


-- ── 2. Kanten ───────────────────────────────────────────────────────────────
--
-- Nur direkte Voraussetzungen; gegen den Graphen in Prod (03.10.2026) geprueft, keine
-- transitiv redundante Kante (tools/k9-rest-graph-check.mjs).

insert into public.skill_kante (skill_key, voraussetzt_skill_key)
values
  -- Funktionswerte f(x) = a(x − d)² + e entstehen durch Einsetzen.
  ('fkt_quadr_parabel', 'term_einsetzen'),
  -- Punkte der Parabel werden im Koordinatensystem gelesen.
  ('fkt_quadr_parabel', 'geo_koordinaten'),
  -- S(d|e) ist die Verschiebung der Normalparabel.
  ('fkt_quadr_scheitel', 'fkt_quadr_parabel'),
  -- Ziel der Umformung ist der Scheitelpunkt.
  ('fkt_quadr_normalform', 'fkt_quadr_scheitel'),
  -- Quadratische Ergänzung = binomische Formel rückwärts.
  ('fkt_quadr_normalform', 'term_binom_quadrat'),
  -- f(x) = 0 ist eine quadratische Gleichung (Lösungsformel).
  ('fkt_quadr_nullstellen', 'gleichung_quadr_formel'),
  -- Nullstelle = Schnittpunkt der Parabel mit der x-Achse; nicht transitiv über die Gleichung
  -- erreichbar.
  ('fkt_quadr_nullstellen', 'fkt_quadr_parabel'),
  -- Das Maximum oder Minimum ist der Scheitelpunkt.
  ('fkt_quadr_extrem', 'fkt_quadr_normalform'),
  -- Die Zielfunktion wird aus einem Sachtext aufgestellt.
  ('fkt_quadr_extrem', 'gleichung_modellieren')
on conflict do nothing;


-- ── 3. Fehlbilder ───────────────────────────────────────────────────────────
--
-- Zentral festgelegt in docs/k9-rest/phase1.md (Teil 1d), gegen den Bestand (98 Slugs) und
-- gegen docs/k8-rest/phase1.md geprueft: keiner der Slugs hat dort eine gleichbedeutende
-- Entsprechung. Ein Slug, den mehrere Themen brauchen, steht in jedem dieser Substrate mit
-- wortgleichem Text; on conflict do nothing haelt das idempotent. freigegeben_am bleibt NULL
-- (Entwurf, wird nirgends ausgeliefert, bis Lena abnimmt). Familie nur aus den fuenf
-- vorhandenen, sonst NULL (Muster Kreis).

insert into public.fehlbild_labels (slug, familie, klartext, erklaerung)
values
  ('pq_vorzeichen', 'vorzeichen',
   'Setzt p in der p-q-Formel mit falschem Vorzeichen ein, beide Lösungen kippen ins Gegenteil.',
   'Die p-q-Formel beginnt mit −p/2. Ist p negativ, wird daraus eine positive Zahl. Hier wurde das Vorzeichen von p nicht umgedreht, die Lösungen haben deshalb das falsche Vorzeichen. Geübt wird, p und q mit Vorzeichen aufzuschreiben, bevor eingesetzt wird.'),

  ('vorzeichen_aus_klammer', 'vorzeichen',
   'Liest aus einer Klammer wie (x − 3) den Wert mit falschem Vorzeichen ab: −3 statt 3.',
   'In (x − 3) steckt die Zahl 3: Für x = 3 wird die Klammer null. Das gilt beim Scheitelpunkt von y = (x − 3)² + 1 genauso wie bei der Gleichung (x − 3)(x + 5) = 0. Hier wurde das Vorzeichen aus der Klammer übernommen statt umgedreht. Geübt wird die Frage: Für welches x wird die Klammer null?'),

  ('ergaenzung_vorzeichen', 'gleichungen_umformen',
   'Addiert bei der quadratischen Ergänzung das Quadrat, statt es danach wieder abzuziehen.',
   'Bei der quadratischen Ergänzung wird eine Zahl hinzugefügt, damit eine binomische Formel entsteht. Damit der Term gleich bleibt, muss dieselbe Zahl wieder abgezogen werden. Hier wurde sie stattdessen ein zweites Mal addiert, der y-Wert des Scheitelpunkts stimmt deshalb nicht. Geübt wird, ergänzte und abgezogene Zahl direkt nebeneinander zu schreiben.')
on conflict (slug) do nothing;
