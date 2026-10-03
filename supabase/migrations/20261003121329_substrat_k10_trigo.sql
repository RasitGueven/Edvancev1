-- K10-Rest, Thema trigo — Substrat: 5 Knoten, 10 Kanten, 6 neue Fehlbilder. KEINE Aufgaben.
-- Erzeugt von tools/k10-rest-substrat.mjs aus docs/k10-rest/graph.json — nicht von Hand editieren.
--
-- Kernlehrplan Mathematik NRW G9, Geo-7, Geo-8, Geo-9, Geo-10 (Zweite Stufe): Sinus, Kosinus, Tangens im rechtwinkligen Dreieck, Kosinussatz, Berechnungen in Sachsituationen.
-- klasse_herkunft = 10: Stoffjahrgang der Zweiten Stufe, in dem das Thema themen.trigonometrie
-- an Koelner Gymnasien ueberwiegend unterrichtet wird (Schulplaene: docs/themen/schulplaene.csv); der Katalog
-- fuehrt das Thema unter klasse 9 (Zweite Stufe 9/10). Eine Bindung an ein Schuljahr ist damit nicht behauptet.
--
-- Einspiel-Reihenfolge: nach allen Migrationen von origin/dev
-- (Knoten der Kanten muessen stehen); vor 20261003121333_aufgaben_k10_trigo.sql.
-- Alle Voraussetzungen ausserhalb dieses Laufs stehen in origin/dev UND in Prod (K8-Rest und K9-Rest
-- sind seit #193/#194 eingespielt). Deshalb keine eigene kanten_k10_k9.sql (docs/k10-rest/entscheidungen.md).
--
-- Kein begin/commit: `mig` spielt die Datei mit psql -1 in EINER Transaktion ein. Die
-- Knoten stehen vor den Kanten, weil skill_kante_tiefe die Tiefe beider Seiten schon beim
-- Insert liest. Idempotent: on conflict do nothing.


-- ── 1. Knoten ───────────────────────────────────────────────────────────────
--
-- Tiefe = 1 + tiefste direkte Voraussetzung (Plan: docs/k10-rest/phase1.md, Teil 1b):
--   geo_trigo_verhaeltnis              7  ueber geo_aehnlich_streckfaktor, geo_pythagoras_hypotenuse
--   geo_trigo_seite                    8  ueber geo_trigo_verhaeltnis, gleichung_einschrittig
--   geo_trigo_winkel                   8  ueber geo_trigo_verhaeltnis
--   geo_trigo_anwendung                9  ueber geo_trigo_seite, geo_trigo_winkel, fkt_linear_steigung
--   geo_trigo_kosinussatz              9  ueber geo_trigo_winkel, term_einsetzen

insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
values
  ('geo_trigo_verhaeltnis', 'Sinus, Kosinus und Tangens als Seitenverhältnisse', 'mathematik', 10, 7),
  ('geo_trigo_seite', 'Seiten im rechtwinkligen Dreieck berechnen', 'mathematik', 10, 8),
  ('geo_trigo_winkel', 'Winkel im rechtwinkligen Dreieck berechnen', 'mathematik', 10, 8),
  ('geo_trigo_anwendung', 'Trigonometrie in Sachsituationen (Steigung, Höhe, Entfernung)', 'mathematik', 10, 9),
  ('geo_trigo_kosinussatz', 'Kosinussatz im allgemeinen Dreieck', 'mathematik', 10, 9)
on conflict (skill_key) do nothing;


-- ── 2. Kanten ───────────────────────────────────────────────────────────────
--
-- Nur direkte Voraussetzungen; gegen den Graphen in Prod (03.10.2026) geprueft, keine
-- transitiv redundante Kante (tools/k10-rest-graph-check.mjs).

insert into public.skill_kante (skill_key, voraussetzt_skill_key)
values
  -- Geo-7: Sinus, Kosinus und Tangens sind Seitenverhältnisse, die in ähnlichen rechtwinkligen
  -- Dreiecken gleich bleiben.
  ('geo_trigo_verhaeltnis', 'geo_aehnlich_streckfaktor'),
  -- Hypotenuse und Katheten im rechtwinkligen Dreieck benennen; nicht über die Ähnlichkeit
  -- erreichbar.
  ('geo_trigo_verhaeltnis', 'geo_pythagoras_hypotenuse'),
  -- Eine Seite folgt aus einem Winkel und einer zweiten Seite über das passende Verhältnis.
  ('geo_trigo_seite', 'geo_trigo_verhaeltnis'),
  -- Steht die gesuchte Seite im Nenner (sin α = a/c), wird die Gleichung umgestellt; nicht über
  -- die Verhältnisse erreichbar.
  ('geo_trigo_seite', 'gleichung_einschrittig'),
  -- Der Winkel folgt aus einem Seitenverhältnis über sin⁻¹, cos⁻¹ oder tan⁻¹.
  ('geo_trigo_winkel', 'geo_trigo_verhaeltnis'),
  -- Höhen und Entfernungen sind gesuchte Seiten eines rechtwinkligen Dreiecks.
  ('geo_trigo_anwendung', 'geo_trigo_seite'),
  -- Steigungs- und Sehwinkel sind gesuchte Winkel; nicht über die Seiten erreichbar.
  ('geo_trigo_anwendung', 'geo_trigo_winkel'),
  -- Eine Steigung in Prozent ist Höhenunterschied durch waagerechte Strecke, also tan α; nicht
  -- über die Trigonometrie erreichbar.
  ('geo_trigo_anwendung', 'fkt_linear_steigung'),
  -- Der Kosinussatz liefert einen Winkel über cos⁻¹ und verallgemeinert den Pythagoras (Geo-8),
  -- der über die Verhältnisse schon erreicht ist.
  ('geo_trigo_kosinussatz', 'geo_trigo_winkel'),
  -- c² = a² + b² − 2ab·cos γ ist eine Formel, in die eingesetzt wird; nicht über die
  -- Trigonometrie erreichbar.
  ('geo_trigo_kosinussatz', 'term_einsetzen')
on conflict do nothing;


-- ── 3. Fehlbilder ───────────────────────────────────────────────────────────
--
-- Zentral festgelegt in docs/k10-rest/phase1.md (Teil 1d), gegen den Bestand (98 Slugs) und
-- gegen docs/k8-rest/phase1.md geprueft: keiner der Slugs hat dort eine gleichbedeutende
-- Entsprechung. Ein Slug, den mehrere Themen brauchen, steht in jedem dieser Substrate mit
-- wortgleichem Text; on conflict do nothing haelt das idempotent. freigegeben_am bleibt NULL
-- (Entwurf, wird nirgends ausgeliefert, bis Lena abnimmt). Familie nur aus den fuenf
-- vorhandenen, sonst NULL (Muster Kreis).

insert into public.fehlbild_labels (slug, familie, klartext, erklaerung)
values
  ('sin_cos_vertauscht', null,
   'Verwechselt Gegenkathete und Ankathete: nimmt den Sinus statt des Kosinus oder umgekehrt, beim Tangens den Kehrwert.',
   'Gegenkathete und Ankathete hängen vom Winkel ab, um den es geht: Die Gegenkathete liegt ihm gegenüber, die Ankathete liegt an ihm an. Wer die beiden vertauscht, rechnet mit dem Sinus, wo der Kosinus gilt, und umgekehrt; beim Tangens steht das Verhältnis dann auf dem Kopf. Geübt wird, vor dem Rechnen am Winkel die drei Seiten zu benennen.'),

  ('tangens_verwechselt', null,
   'Nimmt den Tangens, wo Sinus oder Kosinus gebraucht wird, oder umgekehrt: Hypotenuse und Kathete verwechselt.',
   'Sinus und Kosinus haben die Hypotenuse im Nenner, der Tangens nicht: Er setzt die beiden Katheten ins Verhältnis. Wer hier die Hypotenuse für eine Kathete hält, greift zum falschen Verhältnis. Geübt wird, zuerst zu klären, welche zwei Seiten gegeben oder gesucht sind.'),

  ('umkehrfunktion_vergessen', null,
   'Gibt den Sinus-, Kosinus- oder Tangenswert als Winkel an, statt mit sin⁻¹, cos⁻¹ oder tan⁻¹ den Winkel zu bestimmen.',
   'Das Seitenverhältnis ist noch nicht der Winkel: Aus sin α = 0,5 folgt α = 30°, nicht α = 0,5. Der letzte Schritt mit der Umkehrtaste fehlt. Geübt wird, am Ende zu prüfen, ob das Ergebnis als Winkel überhaupt passt.'),

  ('bogenmass_modus', null,
   'Rechnet mit dem Taschenrechner im falschen Winkelmodus: Bogenmaß statt Gradmaß oder umgekehrt.',
   'sin(30) ist im Gradmaß 0,5, im Bogenmaß dagegen etwa −0,99. Der Taschenrechner rechnet im eingestellten Modus, ohne zu warnen. Geübt wird, vor dem Rechnen auf die Anzeige DEG oder RAD zu achten und das Ergebnis grob zu überschlagen.'),

  ('kosinussatz_vorzeichen', 'vorzeichen',
   'Addiert im Kosinussatz den Term 2ab·cos γ, statt ihn abzuziehen.',
   'Im Kosinussatz c² = a² + b² − 2ab·cos γ wird der Korrekturterm abgezogen. Mit Plus wird die dritte Seite bei spitzem γ zu lang. Geübt wird, den Satz am rechten Winkel zu prüfen: Bei γ = 90° ist cos γ = 0, und es bleibt der Satz des Pythagoras.'),

  ('pythagoras_ohne_rechten_winkel', null,
   'Wendet den Satz des Pythagoras an, obwohl das Dreieck keinen rechten Winkel hat.',
   'Der Satz des Pythagoras gilt nur im rechtwinkligen Dreieck. In jedem anderen Dreieck fehlt der Korrekturterm 2ab·cos γ des Kosinussatzes. Geübt wird, vor der Rechnung nach dem rechten Winkel zu suchen.')
on conflict (slug) do nothing;
