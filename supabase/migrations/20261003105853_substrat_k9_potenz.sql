-- K9-Rest, Thema potenz — Substrat: 4 Knoten, 5 Kanten, 3 neue Fehlbilder. KEINE Aufgaben.
-- Erzeugt von tools/k9-rest-substrat.mjs aus docs/k9-rest/graph.json — nicht von Hand editieren.
--
-- Kernlehrplan Mathematik NRW G9, Ari-1, Ari-3, Ari-4 (Zweite Stufe): Potenzgesetze, negative Exponenten, Zehnerpotenzen.
-- klasse_herkunft = 9 folgt dem KLP (Zweite Stufe) und dem Thema themen.potenzen (Klasse 9);
-- eine Bindung an ein bestimmtes Schuljahr ist damit nicht behauptet.
--
-- Einspiel-Reihenfolge: nach allen Migrationen von origin/dev
-- (Knoten der Kanten muessen stehen); vor 20261003105902_aufgaben_k9_potenz.sql.
-- Keine Kante auf Knoten des parallelen Laufs feat/k8-rest (LGS, Wahrscheinlichkeit Kl. 8,
-- Flaechen, Winkel): beide Laeufe bleiben unabhaengig einspielbar (Befunde in docs/k9-rest/befunde.md).
--
-- Kein begin/commit: `mig` spielt die Datei mit psql -1 in EINER Transaktion ein. Die
-- Knoten stehen vor den Kanten, weil skill_kante_tiefe die Tiefe beider Seiten schon beim
-- Insert liest. Idempotent: on conflict do nothing.


-- ── 1. Knoten ───────────────────────────────────────────────────────────────
--
-- Tiefe = 1 + tiefste direkte Voraussetzung (Plan: docs/k9-rest/phase1.md, Teil 1b):
--   zahl_potenz_gesetze                5  ueber potenzen
--   zahl_potenz_negativ                6  ueber zahl_potenz_gesetze, bruch_dezimal
--   zahl_potenz_zehner                 7  ueber zahl_potenz_negativ
--   zahl_potenz_rechnen                8  ueber zahl_potenz_zehner

insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
values
  ('zahl_potenz_gesetze', 'Potenzgesetze', 'mathematik', 9, 5),
  ('zahl_potenz_negativ', 'Negative Hochzahlen und Hochzahl null', 'mathematik', 9, 6),
  ('zahl_potenz_zehner', 'Zehnerpotenzen und wissenschaftliche Schreibweise', 'mathematik', 9, 7),
  ('zahl_potenz_rechnen', 'Rechnen in wissenschaftlicher Schreibweise', 'mathematik', 9, 8)
on conflict (skill_key) do nothing;


-- ── 2. Kanten ───────────────────────────────────────────────────────────────
--
-- Nur direkte Voraussetzungen; gegen den Graphen in Prod (03.10.2026) geprueft, keine
-- transitiv redundante Kante (tools/k9-rest-graph-check.mjs).

insert into public.skill_kante (skill_key, voraussetzt_skill_key)
values
  -- Potenzgesetze verallgemeinern das Rechnen mit Potenzen natürlicher Hochzahlen (Fundament
  -- potenzen, unverändert).
  ('zahl_potenz_gesetze', 'potenzen'),
  -- a⁻ⁿ = 1/aⁿ folgt aus dem Quotientengesetz.
  ('zahl_potenz_negativ', 'zahl_potenz_gesetze'),
  -- 1/8 = 0,125: Ergebnisse als Bruch oder Dezimalzahl.
  ('zahl_potenz_negativ', 'bruch_dezimal'),
  -- Kleine Zahlen brauchen negative Zehnerexponenten (0,0004 = 4·10⁻⁴).
  ('zahl_potenz_zehner', 'zahl_potenz_negativ'),
  -- Produkte und Quotienten werden in wissenschaftlicher Schreibweise angegeben; die
  -- Potenzgesetze sind über zahl_potenz_negativ erreichbar.
  ('zahl_potenz_rechnen', 'zahl_potenz_zehner')
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
  ('potenzgesetz_verwechselt', null,
   'Verwechselt die Potenzgesetze: multipliziert die Hochzahlen, wo sie addiert werden, oder umgekehrt.',
   'Bei gleicher Basis werden die Hochzahlen beim Malnehmen addiert (2³ · 2⁴ = 2⁷), beim Potenzieren einer Potenz multipliziert ((2³)⁴ = 2¹²). Hier wurden die beiden Regeln vertauscht. Geübt wird, kleine Beispiele auszuschreiben: 2³ · 2⁴ sind sieben Zweien.'),

  ('negativer_exponent_negativ', 'vorzeichen',
   'Liest eine negative Hochzahl als negatives Ergebnis: 2⁻³ = −8 statt 1/8.',
   'Eine negative Hochzahl bedeutet „Kehrwert“, nicht „Minus“: 2⁻³ ist 1 geteilt durch 2³, also 1/8. Das Ergebnis ist positiv. Geübt wird, negative Hochzahlen zuerst als Bruch hinzuschreiben.'),

  ('zehnerexponent_vorzeichen', 'vorzeichen',
   'Gibt bei kleinen Zahlen einen positiven Zehnerexponenten an, bei großen einen negativen.',
   'In der wissenschaftlichen Schreibweise zeigt die Hochzahl von 10, wie weit das Komma wandert: Große Zahlen haben eine positive Hochzahl, Zahlen kleiner als 1 eine negative (0,0004 = 4 · 10⁻⁴). Hier wurde das Vorzeichen vertauscht. Geübt wird die Probe: Ist die Zahl kleiner als 1, muss die Hochzahl negativ sein.')
on conflict (slug) do nothing;
