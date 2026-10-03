-- K9-Rest, Thema quadrgl — Substrat: 4 Knoten, 7 Kanten, 5 neue Fehlbilder. KEINE Aufgaben.
-- Erzeugt von tools/k9-rest-substrat.mjs aus docs/k9-rest/graph.json — nicht von Hand editieren.
--
-- Kernlehrplan Mathematik NRW G9, Ari-8 (Zweite Stufe): quadratische Gleichungen lösen (Wurzelziehen, Faktorisieren, Lösungsformel).
-- klasse_herkunft = 9 folgt dem KLP (Zweite Stufe) und dem Thema themen.quadratische_gleichungen (Klasse 9);
-- eine Bindung an ein bestimmtes Schuljahr ist damit nicht behauptet.
--
-- Einspiel-Reihenfolge: nach allen Migrationen von origin/dev und nach substrat_k9_wurzel
-- (Knoten der Kanten muessen stehen); vor 20261003105903_aufgaben_k9_quadrgl.sql.
-- Keine Kante auf Knoten des parallelen Laufs feat/k8-rest (LGS, Wahrscheinlichkeit Kl. 8,
-- Flaechen, Winkel): beide Laeufe bleiben unabhaengig einspielbar (Befunde in docs/k9-rest/befunde.md).
--
-- Kein begin/commit: `mig` spielt die Datei mit psql -1 in EINER Transaktion ein. Die
-- Knoten stehen vor den Kanten, weil skill_kante_tiefe die Tiefe beider Seiten schon beim
-- Insert liest. Idempotent: on conflict do nothing.


-- ── 1. Knoten ───────────────────────────────────────────────────────────────
--
-- Tiefe = 1 + tiefste direkte Voraussetzung (Plan: docs/k9-rest/phase1.md, Teil 1b):
--   gleichung_quadr_wurzel             7  ueber zahl_wurzel_quadrat, gleichung_zweischrittig
--   gleichung_quadr_faktor             8  ueber term_ausklammern, gleichung_einschrittig
--   gleichung_quadr_formel             8  ueber gleichung_quadr_wurzel, term_einsetzen
--   gleichung_quadr_anzahl             9  ueber gleichung_quadr_formel

insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
values
  ('gleichung_quadr_wurzel', 'Quadratische Gleichungen durch Wurzelziehen', 'mathematik', 9, 7),
  ('gleichung_quadr_faktor', 'Quadratische Gleichungen durch Ausklammern (Nullprodukt)', 'mathematik', 9, 8),
  ('gleichung_quadr_formel', 'Lösungsformel (p-q- bzw. abc-Formel)', 'mathematik', 9, 8),
  ('gleichung_quadr_anzahl', 'Anzahl der Lösungen (Diskriminante)', 'mathematik', 9, 9)
on conflict (skill_key) do nothing;


-- ── 2. Kanten ───────────────────────────────────────────────────────────────
--
-- Nur direkte Voraussetzungen; gegen den Graphen in Prod (03.10.2026) geprueft, keine
-- transitiv redundante Kante (tools/k9-rest-graph-check.mjs).

insert into public.skill_kante (skill_key, voraussetzt_skill_key)
values
  -- x² = c wird durch Wurzelziehen gelöst, mit zwei Lösungen ±√c.
  ('gleichung_quadr_wurzel', 'zahl_wurzel_quadrat'),
  -- a·x² + b = c wird erst nach x² umgestellt (zwei Schritte).
  ('gleichung_quadr_wurzel', 'gleichung_zweischrittig'),
  -- x² − 5x = 0 wird zu x(x − 5) = 0 ausgeklammert.
  ('gleichung_quadr_faktor', 'term_ausklammern'),
  -- Jeder Faktor wird null gesetzt und einschrittig gelöst; nicht transitiv erreichbar.
  ('gleichung_quadr_faktor', 'gleichung_einschrittig'),
  -- Die Formel endet mit ±√(…), wie die Wurzelgleichung.
  ('gleichung_quadr_formel', 'gleichung_quadr_wurzel'),
  -- p und q (bzw. a, b, c) werden mit Vorzeichen in einen Term eingesetzt.
  ('gleichung_quadr_formel', 'term_einsetzen'),
  -- Die Anzahl entscheidet der Term unter der Wurzel der Lösungsformel.
  ('gleichung_quadr_anzahl', 'gleichung_quadr_formel')
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

  ('negative_loesung_vergessen', 'gleichungen_umformen',
   'Gibt bei x² = c nur die positive Lösung an und übersieht die negative.',
   'Sowohl 7² als auch (−7)² ergeben 49. Eine Gleichung wie x² = 49 hat deshalb zwei Lösungen, 7 und −7. Hier wurde nur die positive genannt. Geübt wird, beim Wurzelziehen in einer Gleichung immer ± mitzuschreiben.'),

  ('pq_vorzeichen', 'vorzeichen',
   'Setzt p in der p-q-Formel mit falschem Vorzeichen ein, beide Lösungen kippen ins Gegenteil.',
   'Die p-q-Formel beginnt mit −p/2. Ist p negativ, wird daraus eine positive Zahl. Hier wurde das Vorzeichen von p nicht umgedreht, die Lösungen haben deshalb das falsche Vorzeichen. Geübt wird, p und q mit Vorzeichen aufzuschreiben, bevor eingesetzt wird.'),

  ('vorzeichen_aus_klammer', 'vorzeichen',
   'Liest aus einer Klammer wie (x − 3) den Wert mit falschem Vorzeichen ab: −3 statt 3.',
   'In (x − 3) steckt die Zahl 3: Für x = 3 wird die Klammer null. Das gilt beim Scheitelpunkt von y = (x − 3)² + 1 genauso wie bei der Gleichung (x − 3)(x + 5) = 0. Hier wurde das Vorzeichen aus der Klammer übernommen statt umgedreht. Geübt wird die Frage: Für welches x wird die Klammer null?'),

  ('loesung_null_verloren', 'gleichungen_umformen',
   'Teilt durch x und verliert dabei die Lösung x = 0.',
   'Bei x² = 5x liegt es nahe, durch x zu teilen. Dabei geht aber die Lösung x = 0 verloren, denn durch null darf nicht geteilt werden. Richtig ist, alles auf eine Seite zu bringen und x auszuklammern: x(x − 5) = 0. Geübt wird, nie durch einen Term mit x zu teilen.')
on conflict (slug) do nothing;
