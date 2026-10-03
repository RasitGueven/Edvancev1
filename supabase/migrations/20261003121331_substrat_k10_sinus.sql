-- K10-Rest, Thema sinus — Substrat: 5 Knoten, 7 Kanten, 5 neue Fehlbilder. KEINE Aufgaben.
-- Erzeugt von tools/k10-rest-substrat.mjs aus docs/k10-rest/graph.json — nicht von Hand editieren.
--
-- Kernlehrplan Mathematik NRW G9, Fkt-13, Fkt-14 (Zweite Stufe): Sinus und Kosinus am Einheitskreis, Sinusfunktion, periodische Vorgänge.
-- klasse_herkunft = 10: Stoffjahrgang der Zweiten Stufe, in dem das Thema themen.sinusfunktion
-- an Koelner Gymnasien ueberwiegend unterrichtet wird (Schulplaene: docs/themen/schulplaene.csv); der Katalog
-- fuehrt das Thema unter klasse 9 (Zweite Stufe 9/10). Eine Bindung an ein Schuljahr ist damit nicht behauptet.
--
-- Einspiel-Reihenfolge: nach allen Migrationen von origin/dev und nach substrat_k10_trigo
-- (Knoten der Kanten muessen stehen); vor 20261003121334_aufgaben_k10_sinus.sql.
-- Alle Voraussetzungen ausserhalb dieses Laufs stehen in origin/dev UND in Prod (K8-Rest und K9-Rest
-- sind seit #193/#194 eingespielt). Deshalb keine eigene kanten_k10_k9.sql (docs/k10-rest/entscheidungen.md).
--
-- Kein begin/commit: `mig` spielt die Datei mit psql -1 in EINER Transaktion ein. Die
-- Knoten stehen vor den Kanten, weil skill_kante_tiefe die Tiefe beider Seiten schon beim
-- Insert liest. Idempotent: on conflict do nothing.


-- ── 1. Knoten ───────────────────────────────────────────────────────────────
--
-- Tiefe = 1 + tiefste direkte Voraussetzung (Plan: docs/k10-rest/phase1.md, Teil 1b):
--   fkt_sinus_einheitskreis            8  ueber geo_trigo_verhaeltnis, geo_koordinaten
--   fkt_sinus_bogenmass                8  ueber geo_kreis_sektor
--   fkt_sinus_graph                    9  ueber fkt_sinus_einheitskreis, fkt_sinus_bogenmass
--   fkt_sinus_parameter                10  ueber fkt_sinus_graph
--   fkt_sinus_periodisch               11  ueber fkt_sinus_parameter

insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
values
  ('fkt_sinus_einheitskreis', 'Sinus und Kosinus am Einheitskreis', 'mathematik', 10, 8),
  ('fkt_sinus_bogenmass', 'Bogenmaß und Gradmaß', 'mathematik', 10, 8),
  ('fkt_sinus_graph', 'Graph der Sinusfunktion', 'mathematik', 10, 9),
  ('fkt_sinus_parameter', 'Amplitude und Periode bei a·sin(b·x)', 'mathematik', 10, 10),
  ('fkt_sinus_periodisch', 'Periodische Vorgänge mit Sinusfunktionen beschreiben', 'mathematik', 10, 11)
on conflict (skill_key) do nothing;


-- ── 2. Kanten ───────────────────────────────────────────────────────────────
--
-- Nur direkte Voraussetzungen; gegen den Graphen in Prod (03.10.2026) geprueft, keine
-- transitiv redundante Kante (tools/k10-rest-graph-check.mjs).

insert into public.skill_kante (skill_key, voraussetzt_skill_key)
values
  -- Fkt-13: Sinus und Kosinus am Einheitskreis verallgemeinern die Seitenverhältnisse im
  -- rechtwinkligen Dreieck.
  ('fkt_sinus_einheitskreis', 'geo_trigo_verhaeltnis'),
  -- Der Punkt auf dem Einheitskreis hat die Koordinaten (cos α | sin α), mit Vorzeichen je
  -- Quadrant; nicht über die Trigonometrie erreichbar.
  ('fkt_sinus_einheitskreis', 'geo_koordinaten'),
  -- Das Bogenmaß ist die Länge des Kreisbogens am Einheitskreis, proportional zum
  -- Mittelpunktswinkel.
  ('fkt_sinus_bogenmass', 'geo_kreis_sektor'),
  -- Die Funktionswerte sind die Sinuswerte am Einheitskreis.
  ('fkt_sinus_graph', 'fkt_sinus_einheitskreis'),
  -- Die x-Achse der Sinusfunktion ist im Bogenmaß skaliert (Periode 2π); nicht über den
  -- Einheitskreis erreichbar.
  ('fkt_sinus_graph', 'fkt_sinus_bogenmass'),
  -- a streckt den Graphen in y-Richtung, b staucht ihn in x-Richtung.
  ('fkt_sinus_parameter', 'fkt_sinus_graph'),
  -- Fkt-14: Amplitude und Periode werden aus einem zeitlich periodischen Vorgang bestimmt und
  -- gedeutet.
  ('fkt_sinus_periodisch', 'fkt_sinus_parameter')
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
  ('bogenmass_modus', null,
   'Rechnet mit dem Taschenrechner im falschen Winkelmodus: Bogenmaß statt Gradmaß oder umgekehrt.',
   'sin(30) ist im Gradmaß 0,5, im Bogenmaß dagegen etwa −0,99. Der Taschenrechner rechnet im eingestellten Modus, ohne zu warnen. Geübt wird, vor dem Rechnen auf die Anzeige DEG oder RAD zu achten und das Ergebnis grob zu überschlagen.'),

  ('periode_falsch', null,
   'Verwechselt bei a·sin(b·x) die Periode mit dem Faktor b: gibt b als Periode an oder rechnet 2π · b bzw. p : 2π statt 2π : b.',
   'Der Faktor b staucht die Sinuskurve: Je größer b, desto kürzer die Periode. Periode und b hängen über p = 2π : b und b = 2π : p zusammen, nicht über 2π · b oder p : 2π. Geübt wird, am Graphen nachzuzählen, wie oft die Kurve in 2π durchläuft.'),

  ('amplitude_verwechselt', null,
   'Verwechselt die Amplitude mit dem Abstand zwischen Hoch- und Tiefpunkt (doppelt so groß) oder halbiert sie.',
   'Die Amplitude ist der Abstand vom Hochpunkt zur Mittellinie, nicht vom Hochpunkt zum Tiefpunkt. Bei Werten zwischen −3 und 3 ist sie 3, nicht 6. Geübt wird, zuerst die Mittellinie einzuzeichnen.'),

  ('quadrant_vorzeichen', 'vorzeichen',
   'Übersieht das Vorzeichen von Sinus oder Kosinus im zweiten bis vierten Viertel des Einheitskreises.',
   'Am Einheitskreis ist der Kosinus die x-Koordinate und der Sinus die y-Koordinate. Links von der y-Achse ist der Kosinus negativ, unterhalb der x-Achse der Sinus. Wer nur den Wert des spitzen Winkels überträgt, verliert das Vorzeichen. Geübt wird, den Punkt am Kreis zuerst einzuzeichnen.'),

  ('grad_bogen_faktor_falsch', 'einheiten_massstab',
   'Rechnet beim Umrechnen zwischen Gradmaß und Bogenmaß mit dem umgekehrten Faktor: 180/π statt π/180 oder umgekehrt.',
   '180° entsprechen π. Vom Gradmaß ins Bogenmaß wird deshalb mit π/180 multipliziert, zurück mit 180/π. Wer den Faktor umdreht, erhält eine viel zu große oder zu kleine Zahl. Geübt wird, mit 180° = π zu überschlagen: 90° muss etwa 1,57 ergeben.')
on conflict (slug) do nothing;
