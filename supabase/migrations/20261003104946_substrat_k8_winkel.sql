-- K8 Thales und Winkelsaetze, Migration 1 von 2 — vier Knoten, fuenf Kanten,
-- vier neue Fehlbilder. KEINE Aufgaben (die stehen in 20261003104950_aufgaben_k8_winkel.sql).
--
-- Kernlehrplan NRW G9, Inhaltsfeld Geometrie, ERSTE Stufe (7/8):
--   Geo-1  Winkelbeziehungen: Neben-, Scheitel-, Stufen- und Wechselwinkel
--          begruenden und zur Winkelberechnung nutzen
--   Geo-2  Winkelsummen und Basiswinkelsatz im Dreieck (inkl. Aussenwinkel)
--   Geo-7  Satz des Thales (hier nur als Winkelberechnung, KEINE Konstruktion)
-- klasse_herkunft = 8: in Koelner Gymnasien ueblich in Klasse 8 (Auftrag W4);
-- der Katalog fuehrt die Erste Stufe unter themen.klasse = 7 (Stufenbeginn).
--
-- Einspiel-Reihenfolge: nach dem Bestand (geo_winkel_summe, dezimal_add_sub
-- muessen stehen), vor 20261003104950_aufgaben_k8_winkel.sql.
--
-- Kein begin/commit in der Datei: mig spielt jede Datei mit psql -1 in EINER
-- Transaktion ein; CI und Wegwerf-DB ohne Klammer. Idempotent ueber
-- on conflict do nothing.


-- ── 1. Vier Knoten ──────────────────────────────────────────────────────────
--
-- Kuerzel nach Bestandsmuster geo_winkel_* (wie geo_winkel_summe).
-- geo_winkel_summe (Kl. 7, Tiefe 3, reine Winkelsumme mit gegebenen Winkeln)
-- bleibt unveraendert; keine Kante von einem Fundament-Knoten auf die neuen.
--
-- Tiefe = 1 + tiefste direkte Voraussetzung:
--   neben_scheitel  2  ueber dezimal_add_sub (1)
--   parallelen      3  ueber neben_scheitel (2)
--   dreieck         4  ueber geo_winkel_summe (3), parallelen (3)
--   thales          5  ueber dreieck (4)
--
-- Knotenschnitt: Neben-/Scheitelwinkel an EINEM Schnittpunkt sind die Grundlage
-- jeder weiteren Winkelkette; Stufen-/Wechselwinkel brauchen zusaetzlich die
-- Parallelitaet. "dreieck" buendelt Basiswinkel, Aussenwinkel und kombinierte
-- Winkelsaetze (Dreieck + Parallele); Thales ist der Spezialfall mit Kreis,
-- dessen Rechnung (rechter Winkel bei C, gleichschenklige Teildreiecke AMC/BMC)
-- genau diese Dreieckssaetze voraussetzt.

insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
values
  ('geo_winkel_neben_scheitel', 'Neben- und Scheitelwinkel',                    'mathematik', 8, 2),
  ('geo_winkel_parallelen',     'Stufen- und Wechselwinkel an Parallelen',      'mathematik', 8, 3),
  ('geo_winkel_dreieck',        'Winkel in Dreiecken (Basiswinkel, Außenwinkel, Winkelsätze kombiniert)', 'mathematik', 8, 4),
  ('geo_winkel_thales',         'Satz des Thales (Winkel berechnen)',           'mathematik', 8, 5)
on conflict (skill_key) do nothing;


-- ── 2. Fuenf Kanten ─────────────────────────────────────────────────────────
--
-- Nach den Knoten: skill_kante_tiefe (DEFERRABLE INITIALLY IMMEDIATE) liest
-- die Tiefe beider Seiten schon beim Insert.
--
-- Nur direkte Voraussetzungen. Gegen den Live-Graphen vom 2026-10-03 geprueft
-- (geo_winkel_summe hat genau eine Kante: -> dezimal_add_sub) und deshalb NICHT
-- gesetzt, obwohl fachlich beteiligt:
--   parallelen -> dezimal_add_sub   — ueber neben_scheitel erreichbar
--   dreieck    -> dezimal_add_sub   — ueber geo_winkel_summe erreichbar
--   dreieck    -> neben_scheitel    — ueber parallelen erreichbar (Aussenwinkel
--                                     = Nebenwinkel; der Abstieg findet ihn dort)
--   thales     -> geo_winkel_summe  — ueber dreieck erreichbar
-- Keine Kante zu geo_kreis_* (Kl. 9, Tiefe 6/7): Thales braucht nur den Begriff
-- Durchmesser/Radius, nicht Umfang oder Flaeche — und die Kante waere nicht
-- echt flacher.

insert into public.skill_kante (skill_key, voraussetzt_skill_key)
values
  -- Nebenwinkel = 180° minus Winkel: eine Subtraktion; mehr Rechnen steckt
  -- nicht darin.
  ('geo_winkel_neben_scheitel', 'dezimal_add_sub'),
  -- Jeder Winkel an der zweiten Parallele entsteht aus Stufen-/Wechselwinkel
  -- plus Neben- oder Scheitelwinkel am selben Schnittpunkt.
  ('geo_winkel_parallelen',     'geo_winkel_neben_scheitel'),
  -- Basiswinkel und Aussenwinkel werden ueber die Winkelsumme 180° gerechnet.
  ('geo_winkel_dreieck',        'geo_winkel_summe'),
  -- Kombinierte Winkelsaetze (Parallele durch eine Dreiecksecke, Wechselwinkel)
  -- und der Aussenwinkel als Nebenwinkel; die Winkelsumme selbst wird an
  -- Parallelen begruendet.
  ('geo_winkel_dreieck',        'geo_winkel_parallelen'),
  -- Thales liefert den rechten Winkel bei C; alles Weitere (dritter Winkel,
  -- gleichschenklige Teildreiecke AMC und BMC) sind Dreieckssaetze.
  ('geo_winkel_thales',         'geo_winkel_dreieck')
on conflict do nothing;


-- ── 3. Fehlbilder ───────────────────────────────────────────────────────────
--
-- Slugs und Texte WOERTLICH aus docs/k8-rest/phase1.md d) (zentral festgelegt).
-- Alle vier neuen in mindestens drei Aufgaben (aussenwinkel_verwechselt wird
-- angelegt, weil die Charge Aussenwinkel-Aufgaben stellt).
-- Wiederverwendet, NICHT angefasst: summe_360_statt_180, differenz_vergessen
-- (Bestand geo_winkel_summe) und halbieren_vergessen (Bestand
-- geo_flaeche_dreieck; hier: Rest fuer zwei Basiswinkel nicht halbiert).
-- summe_180_statt_360 ist in dieser Charge nicht noetig (keine Vollwinkel-
-- Aufgabe mit 360°).
-- Familie NULL (keine vorhandene Familie beschreibt Winkelbeziehungen);
-- freigegeben_am NULL: Entwurf bis zur Abnahme durch Lena.

insert into public.fehlbild_labels (slug, familie, klartext, erklaerung)
values
  ('winkelbeziehung_verwechselt', null,
   'Hält zwei Winkel für gleich groß, die sich zu 180° ergänzen, oder umgekehrt.',
   'Scheitelwinkel sowie Stufen- und Wechselwinkel an Parallelen sind gleich groß, '
   'Nebenwinkel ergänzen sich zu 180°. Hier wurde die eine Beziehung mit der anderen '
   'verwechselt. Das Ergebnis passt dann oft nicht zur Lage: Aus einem spitzen Winkel '
   'wird ein stumpfer. Geübt wird, vor dem Rechnen zu benennen, welche '
   'Winkelbeziehung vorliegt.'),

  ('basiswinkel_falsch_zugeordnet', null,
   'Verwechselt im gleichschenkligen Dreieck den Winkel an der Spitze mit einem Basiswinkel.',
   'Im gleichschenkligen Dreieck sind die beiden Winkel an der Grundseite gleich groß, '
   'der dritte Winkel liegt an der Spitze zwischen den gleich langen Seiten. Hier wurde '
   'der gegebene Winkel der falschen Ecke zugeordnet. Geübt wird, zuerst die gleich '
   'langen Seiten zu markieren.'),

  ('rechter_winkel_falsche_ecke', null,
   'Setzt beim Satz des Thales den rechten Winkel an die falsche Ecke.',
   'Liegt eine Dreiecksseite als Durchmesser in einem Kreis und die dritte Ecke auf dem '
   'Kreis, dann ist der Winkel an dieser dritten Ecke ein rechter. Hier wurde der rechte '
   'Winkel an einer Ecke des Durchmessers angenommen. Geübt wird, den Durchmesser zu '
   'suchen und den Winkel gegenüber zu markieren.'),

  ('aussenwinkel_verwechselt', null,
   'Rechnet mit dem Innenwinkel, wo der Außenwinkel gefragt ist, oder umgekehrt.',
   'Der Außenwinkel an einer Dreiecksecke ergänzt den Innenwinkel dort zu 180°. Er ist '
   'so groß wie die beiden anderen Innenwinkel zusammen. Hier wurde der Innenwinkel '
   'statt des Außenwinkels angegeben (oder umgekehrt). Geübt wird, den gefragten Winkel '
   'in einer Skizze einzuzeichnen.')
on conflict (slug) do nothing;
