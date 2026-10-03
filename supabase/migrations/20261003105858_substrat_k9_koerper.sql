-- K9-Rest, Thema koerper — Substrat: 5 Knoten, 10 Kanten, 3 neue Fehlbilder. KEINE Aufgaben.
-- Erzeugt von tools/k9-rest-substrat.mjs aus docs/k9-rest/graph.json — nicht von Hand editieren.
--
-- Kernlehrplan Mathematik NRW G9, Geo-5 (Zweite Stufe): Oberfläche und Volumen von Prisma, Zylinder, Pyramide, Kegel, Kugel.
-- klasse_herkunft = 9 folgt dem KLP (Zweite Stufe) und dem Thema themen.prismen_zylinder / themen.koerper_pyramide_kegel_kugel (Klasse 9);
-- eine Bindung an ein bestimmtes Schuljahr ist damit nicht behauptet.
--
-- Einspiel-Reihenfolge: nach allen Migrationen von origin/dev und nach substrat_k9_pythagoras
-- (Knoten der Kanten muessen stehen); vor 20261003105906_aufgaben_k9_koerper.sql.
-- Keine Kante auf Knoten des parallelen Laufs feat/k8-rest (LGS, Wahrscheinlichkeit Kl. 8,
-- Flaechen, Winkel): beide Laeufe bleiben unabhaengig einspielbar (Befunde in docs/k9-rest/befunde.md).
--
-- Kein begin/commit: `mig` spielt die Datei mit psql -1 in EINER Transaktion ein. Die
-- Knoten stehen vor den Kanten, weil skill_kante_tiefe die Tiefe beider Seiten schon beim
-- Insert liest. Idempotent: on conflict do nothing.


-- ── 1. Knoten ───────────────────────────────────────────────────────────────
--
-- Tiefe = 1 + tiefste direkte Voraussetzung (Plan: docs/k9-rest/phase1.md, Teil 1b):
--   geo_koerper_prisma                 5  ueber geo_volumen_quader, geo_flaeche_dreieck
--   geo_koerper_zylinder               7  ueber geo_koerper_prisma, geo_kreis_flaeche, geo_kreis_umfang
--   geo_koerper_pyramide               6  ueber geo_koerper_prisma
--   geo_koerper_kegel                  8  ueber geo_koerper_zylinder, geo_koerper_pyramide, geo_pythagoras_hypotenuse
--   geo_koerper_kugel                  7  ueber geo_kreis_flaeche

insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
values
  ('geo_koerper_prisma', 'Volumen und Oberfläche des Prismas', 'mathematik', 9, 5),
  ('geo_koerper_zylinder', 'Volumen und Oberfläche des Zylinders', 'mathematik', 9, 7),
  ('geo_koerper_pyramide', 'Volumen und Oberfläche der Pyramide', 'mathematik', 9, 6),
  ('geo_koerper_kegel', 'Volumen und Oberfläche des Kegels', 'mathematik', 9, 8),
  ('geo_koerper_kugel', 'Volumen und Oberfläche der Kugel', 'mathematik', 9, 7)
on conflict (skill_key) do nothing;


-- ── 2. Kanten ───────────────────────────────────────────────────────────────
--
-- Nur direkte Voraussetzungen; gegen den Graphen in Prod (03.10.2026) geprueft, keine
-- transitiv redundante Kante (tools/k9-rest-graph-check.mjs).

insert into public.skill_kante (skill_key, voraussetzt_skill_key)
values
  -- Grundfläche mal Höhe verallgemeinert das Quadervolumen.
  ('geo_koerper_prisma', 'geo_volumen_quader'),
  -- Dreiecksprismen: die Grundfläche ist ein Dreieck.
  ('geo_koerper_prisma', 'geo_flaeche_dreieck'),
  -- Der Zylinder ist ein Prisma mit Kreis als Grundfläche.
  ('geo_koerper_zylinder', 'geo_koerper_prisma'),
  -- Grundfläche π·r².
  ('geo_koerper_zylinder', 'geo_kreis_flaeche'),
  -- Die Mantelfläche ist ein Rechteck mit dem Kreisumfang als Länge.
  ('geo_koerper_zylinder', 'geo_kreis_umfang'),
  -- V = ⅓·G·h: ein Drittel des Prismas mit gleicher Grundfläche und Höhe.
  ('geo_koerper_pyramide', 'geo_koerper_prisma'),
  -- Ein Kegel ist ein Drittel des Zylinders mit gleicher Grundfläche und Höhe.
  ('geo_koerper_kegel', 'geo_koerper_zylinder'),
  -- Der Faktor ⅓ ist von der Pyramide bekannt.
  ('geo_koerper_kegel', 'geo_koerper_pyramide'),
  -- Die Mantellinie s = √(r² + h²) folgt aus dem Satz des Pythagoras.
  ('geo_koerper_kegel', 'geo_pythagoras_hypotenuse'),
  -- O = 4·π·r² ist das Vierfache der Kreisfläche; r² bzw. r³ über potenzen (transitiv).
  ('geo_koerper_kugel', 'geo_kreis_flaeche')
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
  ('wurzel_vergessen', 'gleichungen_umformen',
   'Rechnet bis zum Quadrat richtig, zieht am Ende aber nicht die Wurzel.',
   'Beim Satz des Pythagoras steht nach dem Einsetzen zuerst c² da, bei x² = 49 zuerst die 49. Gesucht ist aber die Länge bzw. x selbst, also fehlt noch das Wurzelziehen. Das Ergebnis ist dann viel zu groß. Geübt wird, am Ende zu prüfen, ob die Antwort zur Frage passt: eine Länge, nicht ihr Quadrat.'),

  ('hypotenuse_verwechselt', null,
   'Behandelt eine Kathete wie die Hypotenuse: addiert die Quadrate, wo subtrahiert werden muss, oder umgekehrt.',
   'Die Hypotenuse ist die längste Seite und liegt dem rechten Winkel gegenüber. Ist sie gegeben und eine Kathete gesucht, wird subtrahiert: a² = c² − b². Hier wurde trotzdem addiert (oder bei gesuchter Hypotenuse subtrahiert). Geübt wird, vor dem Rechnen die Hypotenuse zu markieren.'),

  ('drittel_vergessen', null,
   'Vergisst bei Pyramide oder Kegel den Faktor ⅓ im Volumen.',
   'Eine Pyramide fasst genau ein Drittel eines Prismas mit gleicher Grundfläche und Höhe, ein Kegel ein Drittel des passenden Zylinders. Hier fehlt der Faktor ⅓, das Volumen ist dreimal so groß wie richtig. Geübt wird, bei spitz zulaufenden Körpern immer an das Drittel zu denken.')
on conflict (slug) do nothing;
