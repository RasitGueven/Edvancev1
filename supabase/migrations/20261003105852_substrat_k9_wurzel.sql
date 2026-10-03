-- K9-Rest, Thema wurzel — Substrat: 5 Knoten, 7 Kanten, 3 neue Fehlbilder. KEINE Aufgaben.
-- Erzeugt von tools/k9-rest-substrat.mjs aus docs/k9-rest/graph.json — nicht von Hand editieren.
--
-- Kernlehrplan Mathematik NRW G9, Ari-2, Ari-6, Ari-7 (Zweite Stufe): Quadratwurzeln, reelle Zahlen, Näherungswerte.
-- klasse_herkunft = 9 folgt dem KLP (Zweite Stufe) und dem Thema themen.reelle_zahlen (Klasse 9);
-- eine Bindung an ein bestimmtes Schuljahr ist damit nicht behauptet.
--
-- Einspiel-Reihenfolge: nach allen Migrationen von origin/dev
-- (Knoten der Kanten muessen stehen); vor 20261003105901_aufgaben_k9_wurzel.sql.
-- Keine Kante auf Knoten des parallelen Laufs feat/k8-rest (LGS, Wahrscheinlichkeit Kl. 8,
-- Flaechen, Winkel): beide Laeufe bleiben unabhaengig einspielbar (Befunde in docs/k9-rest/befunde.md).
--
-- Kein begin/commit: `mig` spielt die Datei mit psql -1 in EINER Transaktion ein. Die
-- Knoten stehen vor den Kanten, weil skill_kante_tiefe die Tiefe beider Seiten schon beim
-- Insert liest. Idempotent: on conflict do nothing.


-- ── 1. Knoten ───────────────────────────────────────────────────────────────
--
-- Tiefe = 1 + tiefste direkte Voraussetzung (Plan: docs/k9-rest/phase1.md, Teil 1b):
--   zahl_wurzel_quadrat                5  ueber potenzen
--   zahl_wurzel_naeherung              6  ueber zahl_wurzel_quadrat, runden_ueberschlag
--   zahl_wurzel_irrational             6  ueber zahl_wurzel_quadrat, bruch_dezimal
--   zahl_wurzel_gesetze                6  ueber zahl_wurzel_quadrat
--   zahl_wurzel_teilweise              7  ueber zahl_wurzel_gesetze

insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
values
  ('zahl_wurzel_quadrat', 'Quadratwurzel als Umkehrung des Quadrierens', 'mathematik', 9, 5),
  ('zahl_wurzel_naeherung', 'Wurzeln abschätzen und Näherungswerte', 'mathematik', 9, 6),
  ('zahl_wurzel_irrational', 'Rationale und irrationale Zahlen', 'mathematik', 9, 6),
  ('zahl_wurzel_gesetze', 'Wurzelgesetze für Produkt und Quotient', 'mathematik', 9, 6),
  ('zahl_wurzel_teilweise', 'Teilweise die Wurzel ziehen', 'mathematik', 9, 7)
on conflict (skill_key) do nothing;


-- ── 2. Kanten ───────────────────────────────────────────────────────────────
--
-- Nur direkte Voraussetzungen; gegen den Graphen in Prod (03.10.2026) geprueft, keine
-- transitiv redundante Kante (tools/k9-rest-graph-check.mjs).

insert into public.skill_kante (skill_key, voraussetzt_skill_key)
values
  -- √a ist die nichtnegative Zahl, deren Quadrat a ist; Quadratzahlen (potenzen) sind die
  -- Grundlage.
  ('zahl_wurzel_quadrat', 'potenzen'),
  -- Abschätzen zwischen benachbarten Quadratzahlen setzt den Wurzelbegriff voraus.
  ('zahl_wurzel_naeherung', 'zahl_wurzel_quadrat'),
  -- Näherungswerte werden auf vorgegebene Stellen gerundet; nicht transitiv erreichbar.
  ('zahl_wurzel_naeherung', 'runden_ueberschlag'),
  -- √2 ist das Standardbeispiel einer irrationalen Zahl.
  ('zahl_wurzel_irrational', 'zahl_wurzel_quadrat'),
  -- Rational heißt: als Bruch bzw. abbrechende oder periodische Dezimalzahl darstellbar.
  ('zahl_wurzel_irrational', 'bruch_dezimal'),
  -- √a·√b = √(a·b) und √a : √b = √(a:b) rechnen mit dem Wurzelbegriff.
  ('zahl_wurzel_gesetze', 'zahl_wurzel_quadrat'),
  -- √72 = √36·√2 = 6√2 ist die Anwendung des Produktgesetzes.
  ('zahl_wurzel_teilweise', 'zahl_wurzel_gesetze')
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
  ('wurzel_gliedweise', 'rechenreihenfolge',
   'Zieht die Wurzel aus einer Summe Glied für Glied: √(9 + 16) als √9 + √16.',
   'Die Wurzel aus einer Summe ist nicht die Summe der Wurzeln: √(9 + 16) = √25 = 5, aber √9 + √16 = 7. Beim Satz des Pythagoras führt das zu c = a + b, also zu einer viel zu langen Seite. Geübt wird, unter der Wurzel zuerst auszurechnen und erst dann die Wurzel zu ziehen.'),

  ('irrational_verwechselt', null,
   'Hält Wurzeln aus Quadratzahlen oder periodische Dezimalzahlen für irrational, oder umgekehrt.',
   'Irrational sind Zahlen, die sich nicht als Bruch schreiben lassen, etwa √2 oder π. √16 = 4 und 0,333… = 1/3 sind dagegen rational. Hier wurde eine solche Zahl falsch eingeordnet. Geübt wird, jede Zahl erst zu vereinfachen und dann zu fragen: Gibt es einen Bruch dafür?'),

  ('faktor_ohne_wurzel', null,
   'Zieht beim teilweisen Wurzelziehen den Faktor heraus, ohne aus ihm die Wurzel zu ziehen: √72 = 36·√2.',
   '√72 = √(36 · 2) = √36 · √2 = 6 · √2. Vor die Wurzel kommt die Wurzel des Quadratfaktors, nicht der Faktor selbst. Hier wurde 36 statt 6 vor die Wurzel geschrieben. Geübt wird die Probe durch Quadrieren: (36 · √2)² wäre viel zu groß.')
on conflict (slug) do nothing;
