-- K9-Rest, Thema pythagoras — Substrat: 5 Knoten, 6 Kanten, 3 neue Fehlbilder. KEINE Aufgaben.
-- Erzeugt von tools/k9-rest-substrat.mjs aus docs/k9-rest/graph.json — nicht von Hand editieren.
--
-- Kernlehrplan Mathematik NRW G9, Geo-1, Geo-2 (Zweite Stufe): Satz des Pythagoras, Umkehrung, Längen in Figuren und Körpern.
-- klasse_herkunft = 9 folgt dem KLP (Zweite Stufe) und dem Thema themen.pythagoras (Klasse 9);
-- eine Bindung an ein bestimmtes Schuljahr ist damit nicht behauptet.
--
-- Einspiel-Reihenfolge: nach allen Migrationen von origin/dev und nach substrat_k9_wurzel
-- (Knoten der Kanten muessen stehen); vor 20261003105905_aufgaben_k9_pythagoras.sql.
-- Keine Kante auf Knoten des parallelen Laufs feat/k8-rest (LGS, Wahrscheinlichkeit Kl. 8,
-- Flaechen, Winkel): beide Laeufe bleiben unabhaengig einspielbar (Befunde in docs/k9-rest/befunde.md).
--
-- Kein begin/commit: `mig` spielt die Datei mit psql -1 in EINER Transaktion ein. Die
-- Knoten stehen vor den Kanten, weil skill_kante_tiefe die Tiefe beider Seiten schon beim
-- Insert liest. Idempotent: on conflict do nothing.


-- ── 1. Knoten ───────────────────────────────────────────────────────────────
--
-- Tiefe = 1 + tiefste direkte Voraussetzung (Plan: docs/k9-rest/phase1.md, Teil 1b):
--   geo_pythagoras_hypotenuse          6  ueber zahl_wurzel_quadrat
--   geo_pythagoras_kathete             7  ueber geo_pythagoras_hypotenuse
--   geo_pythagoras_umkehrung           7  ueber geo_pythagoras_hypotenuse
--   geo_pythagoras_abstand             7  ueber geo_pythagoras_hypotenuse, geo_koordinaten
--   geo_pythagoras_anwendung           8  ueber geo_pythagoras_kathete

insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
values
  ('geo_pythagoras_hypotenuse', 'Hypotenuse mit dem Satz des Pythagoras', 'mathematik', 9, 6),
  ('geo_pythagoras_kathete', 'Kathete mit dem Satz des Pythagoras', 'mathematik', 9, 7),
  ('geo_pythagoras_umkehrung', 'Rechtwinklig? Umkehrung des Satzes', 'mathematik', 9, 7),
  ('geo_pythagoras_abstand', 'Abstand zweier Punkte im Koordinatensystem', 'mathematik', 9, 7),
  ('geo_pythagoras_anwendung', 'Pythagoras in Figuren und Körpern', 'mathematik', 9, 8)
on conflict (skill_key) do nothing;


-- ── 2. Kanten ───────────────────────────────────────────────────────────────
--
-- Nur direkte Voraussetzungen; gegen den Graphen in Prod (03.10.2026) geprueft, keine
-- transitiv redundante Kante (tools/k9-rest-graph-check.mjs).

insert into public.skill_kante (skill_key, voraussetzt_skill_key)
values
  -- c = √(a² + b²): Quadrieren und Wurzelziehen.
  ('geo_pythagoras_hypotenuse', 'zahl_wurzel_quadrat'),
  -- a = √(c² − b²) ist der umgestellte Satz.
  ('geo_pythagoras_kathete', 'geo_pythagoras_hypotenuse'),
  -- Die Umkehrung prüft dieselbe Gleichung a² + b² = c² an der längsten Seite.
  ('geo_pythagoras_umkehrung', 'geo_pythagoras_hypotenuse'),
  -- Der Abstand ist die Hypotenuse des Steigungsdreiecks.
  ('geo_pythagoras_abstand', 'geo_pythagoras_hypotenuse'),
  -- Koordinatendifferenzen werden aus den Punkten gebildet.
  ('geo_pythagoras_abstand', 'geo_koordinaten'),
  -- Diagonalen, Höhen und Raumdiagonalen verlangen beide Richtungen des Satzes; die Hypotenuse
  -- ist über die Kathete erreichbar.
  ('geo_pythagoras_anwendung', 'geo_pythagoras_kathete')
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

  ('wurzel_vergessen', 'gleichungen_umformen',
   'Rechnet bis zum Quadrat richtig, zieht am Ende aber nicht die Wurzel.',
   'Beim Satz des Pythagoras steht nach dem Einsetzen zuerst c² da, bei x² = 49 zuerst die 49. Gesucht ist aber die Länge bzw. x selbst, also fehlt noch das Wurzelziehen. Das Ergebnis ist dann viel zu groß. Geübt wird, am Ende zu prüfen, ob die Antwort zur Frage passt: eine Länge, nicht ihr Quadrat.'),

  ('hypotenuse_verwechselt', null,
   'Behandelt eine Kathete wie die Hypotenuse: addiert die Quadrate, wo subtrahiert werden muss, oder umgekehrt.',
   'Die Hypotenuse ist die längste Seite und liegt dem rechten Winkel gegenüber. Ist sie gegeben und eine Kathete gesucht, wird subtrahiert: a² = c² − b². Hier wurde trotzdem addiert (oder bei gesuchter Hypotenuse subtrahiert). Geübt wird, vor dem Rechnen die Hypotenuse zu markieren.')
on conflict (slug) do nothing;
