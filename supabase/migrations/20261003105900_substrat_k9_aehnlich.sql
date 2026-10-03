-- K9-Rest, Thema aehnlich — Substrat: 4 Knoten, 6 Kanten, 3 neue Fehlbilder. KEINE Aufgaben.
-- Erzeugt von tools/k9-rest-substrat.mjs aus docs/k9-rest/graph.json — nicht von Hand editieren.
--
-- Kernlehrplan Mathematik NRW G9, Geometrie, Zweite Stufe (Geo-2, Geo-9): zentrische Streckung, Ähnlichkeit, Strahlensätze.
-- klasse_herkunft = 9 folgt dem KLP (Zweite Stufe) und dem Thema themen.aehnlichkeit (Klasse 9);
-- eine Bindung an ein bestimmtes Schuljahr ist damit nicht behauptet.
--
-- Einspiel-Reihenfolge: nach allen Migrationen von origin/dev
-- (Knoten der Kanten muessen stehen); vor 20261003105909_aufgaben_k9_aehnlich.sql.
-- Keine Kante auf Knoten des parallelen Laufs feat/k8-rest (LGS, Wahrscheinlichkeit Kl. 8,
-- Flaechen, Winkel): beide Laeufe bleiben unabhaengig einspielbar (Befunde in docs/k9-rest/befunde.md).
--
-- Kein begin/commit: `mig` spielt die Datei mit psql -1 in EINER Transaktion ein. Die
-- Knoten stehen vor den Kanten, weil skill_kante_tiefe die Tiefe beider Seiten schon beim
-- Insert liest. Idempotent: on conflict do nothing.


-- ── 1. Knoten ───────────────────────────────────────────────────────────────
--
-- Tiefe = 1 + tiefste direkte Voraussetzung (Plan: docs/k9-rest/phase1.md, Teil 1b):
--   geo_aehnlich_streckfaktor          6  ueber geo_massstab
--   geo_aehnlich_flaeche               7  ueber geo_aehnlich_streckfaktor, potenzen
--   geo_aehnlich_strahlen_abschnitt    7  ueber geo_aehnlich_streckfaktor, gleichung_einschrittig
--   geo_aehnlich_strahlen_parallel     8  ueber geo_aehnlich_strahlen_abschnitt

insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
values
  ('geo_aehnlich_streckfaktor', 'Streckfaktor und zentrische Streckung', 'mathematik', 9, 6),
  ('geo_aehnlich_flaeche', 'Flächen und Volumen bei Ähnlichkeit', 'mathematik', 9, 7),
  ('geo_aehnlich_strahlen_abschnitt', 'Erster Strahlensatz', 'mathematik', 9, 7),
  ('geo_aehnlich_strahlen_parallel', 'Zweiter Strahlensatz', 'mathematik', 9, 8)
on conflict (skill_key) do nothing;


-- ── 2. Kanten ───────────────────────────────────────────────────────────────
--
-- Nur direkte Voraussetzungen; gegen den Graphen in Prod (03.10.2026) geprueft, keine
-- transitiv redundante Kante (tools/k9-rest-graph-check.mjs).

insert into public.skill_kante (skill_key, voraussetzt_skill_key)
values
  -- Der Streckfaktor ist ein Maßstab; proportionalitaet ist über geo_massstab erreichbar.
  ('geo_aehnlich_streckfaktor', 'geo_massstab'),
  -- Flächen wachsen mit k², Volumen mit k³.
  ('geo_aehnlich_flaeche', 'geo_aehnlich_streckfaktor'),
  -- k² und k³ berechnen; nicht über geo_massstab erreichbar.
  ('geo_aehnlich_flaeche', 'potenzen'),
  -- Die Abschnitte auf beiden Strahlen stehen im selben Verhältnis k.
  ('geo_aehnlich_strahlen_abschnitt', 'geo_aehnlich_streckfaktor'),
  -- Die Verhältnisgleichung wird nach der gesuchten Strecke aufgelöst.
  ('geo_aehnlich_strahlen_abschnitt', 'gleichung_einschrittig'),
  -- Der zweite Strahlensatz bezieht die Parallelstrecken auf die Scheitelabschnitte des ersten.
  ('geo_aehnlich_strahlen_parallel', 'geo_aehnlich_strahlen_abschnitt')
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
  ('streckfaktor_kehrwert', 'einheiten_massstab',
   'Rechnet mit dem Kehrwert des Streckfaktors: Bild und Original vertauscht.',
   'Der Streckfaktor k gibt an, wie viel mal so lang die Bildstrecke wie die Originalstrecke ist: k = Bild : Original. Hier wurde Original durch Bild geteilt oder beim Zurückrechnen mal k statt durch k gerechnet. Geübt wird die Probe: Bei einer Vergrößerung muss k größer als 1 sein.'),

  ('strahlensatz_falsch_zugeordnet', null,
   'Setzt beim Strahlensatz Strecken ins Verhältnis, die nicht zueinander gehören.',
   'Beim Strahlensatz stehen entsprechende Strecken im selben Verhältnis, zum Beispiel jeweils der Abschnitt vom Scheitel bis zur ersten Parallele zum Abschnitt bis zur zweiten. Hier wurde ein Teilstück mit einer ganzen Strecke verglichen oder eine Strecke vom falschen Strahl genommen. Geübt wird, die zusammengehörigen Strecken vor dem Rechnen gleichfarbig zu markieren.'),

  ('additiv_statt_multiplikativ', 'einheiten_massstab',
   'Vergrößert mit einem gleichen Zuwachs statt mit einem Faktor.',
   'Bei einer Vergrößerung werden alle Strecken mit demselben Faktor multipliziert. Hier wurde stattdessen zu jeder Strecke derselbe Betrag addiert, etwa „3 cm länger“ statt „1,5-mal so lang“. Die Figur wäre dann nicht mehr ähnlich. Geübt wird, zuerst den Faktor zu bestimmen und dann jede Strecke damit zu multiplizieren.')
on conflict (slug) do nothing;
