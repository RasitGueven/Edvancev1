-- K8 Lineare Funktionen, Migration 1 von 2 — fuenf Knoten, zwoelf Kanten,
-- drei Fehlbilder. KEINE Aufgaben (die stehen in Migration 2).
--
-- Voraussetzung: K8-Vorlauf eingespielt (20261001115718_tiefe_k8_vorlauf.sql,
-- 20261001115812_substrat_k8_vorlauf.sql). Die Kanten unten zeigen auf
-- geo_koordinaten (Tiefe 2) und term_einsetzen (Tiefe 5) aus dem Vorlauf.
--
-- Lehrplanbezug: KLP NRW G9 Mathematik, Inhaltsfeld Funktionen, Erste Stufe.
-- Kompetenzerwartungen:
--   Fkt-4  lineare Funktionen in Tabelle, Graph und Term darstellen und
--          zwischen den Darstellungen wechseln
--   Fkt-5  den Einfluss der Parameter m und b auf den Graphen deuten
--   Fkt-6  die Parameter in Sachsituationen deuten (Grundgebuehr, Preis je km)
--   Fkt-7  Nullstellen linearer Funktionen bestimmen
-- Die Erste Stufe umfasst die Klassen 7 und 8; der Lehrplan bindet die
-- Erwartungen an keine einzelne Klasse. klasse_herkunft = 8 folgt dem Bestand
-- (themen.lineare_funktionen steht auf 8, Muster k8_binomische_formeln) und
-- behauptet keine Schuljahr-Bindung.
--
-- Tiefen (fundament_tiefe = Stufe im Fundament, Guard: Voraussetzung ECHT
-- flacher). Je Knoten 1 + tiefste direkte Voraussetzung, wo es geht:
--   fkt_linear_steigung    5  ueber proportionalitaet (4)
--   fkt_linear_yabschnitt  6  ueber term_einsetzen (5)
--   fkt_linear_graph       7  ueber yabschnitt (6)
--   fkt_linear_gleichung   7  ueber yabschnitt (6)
--   fkt_linear_nullstelle  8  ueber gleichung (7) und gleichung_neg_koeffizient (7)
-- Graph und Gleichung sind Geschwister auf 7: beide setzen m und b voraus,
-- keiner den anderen.
--
-- begin/commit in der Datei: scripts/db-migrate.sh laeuft ohne
-- --single-transaction. Ein Abbruch zwischen skills und skill_kante liesse
-- kantenlose Knoten stehen, die lsa_select_next_core als Blatt zieht.

begin;


-- ── 1. Fuenf Knoten ─────────────────────────────────────────────────────────
--
-- Kuerzel nach Bestandsmuster <familie>_<unterfamilie>_<spezifikum>
-- (term_binom_quadrat, geo_flaeche_rechteck). Familie fkt_ ist neu.

insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
values
  ('fkt_linear_steigung',   'Steigung einer linearen Funktion',            'mathematik', 8, 5),
  ('fkt_linear_yabschnitt', 'y-Achsenabschnitt einer linearen Funktion',   'mathematik', 8, 6),
  ('fkt_linear_graph',      'Graph einer linearen Funktion',               'mathematik', 8, 7),
  ('fkt_linear_gleichung',  'Funktionsgleichung y = mx + b aufstellen',    'mathematik', 8, 7),
  ('fkt_linear_nullstelle', 'Nullstelle einer linearen Funktion',          'mathematik', 8, 8)
on conflict (skill_key) do nothing;


-- ── 2. Zwoelf Kanten ────────────────────────────────────────────────────────
--
-- Nach den Knoten: skill_kante_tiefe (DEFERRABLE INITIALLY IMMEDIATE) liest
-- die Tiefe beider Seiten schon beim Insert. Nur direkte Kanten; geprueft,
-- dass keine davon ueber eine andere schon transitiv erreicht wird.

insert into public.skill_kante (skill_key, voraussetzt_skill_key)
values
  -- Steigung
  -- Delta x und Delta y werden aus zwei Punkten abgelesen; wer Koordinaten
  -- nicht sicher liest, hat keine Differenzen.
  ('fkt_linear_steigung',   'geo_koordinaten'),
  -- m = Delta y / Delta x mit negativen Differenzen: das Vorzeichen des
  -- Quotienten entscheidet, ob der Graph steigt oder faellt.
  ('fkt_linear_steigung',   'vorzeichen_mult_div'),
  -- Die Steigung steht als Bruch da (2/4) und wird gekuerzt angegeben (1/2).
  ('fkt_linear_steigung',   'bruch_kuerzen'),
  -- y = m·x ist die proportionale Zuordnung aus Klasse 7; m ist der Wert je
  -- Einheit (Preis je km). Ohne diesen Begriff bleibt m eine Formelzahl.
  ('fkt_linear_steigung',   'proportionalitaet'),

  -- y-Achsenabschnitt
  -- b = f(0): x = 0 in den Term einsetzen.
  ('fkt_linear_yabschnitt', 'term_einsetzen'),
  -- b als Schnittpunkt (0 | b) mit der y-Achse ablesen.
  ('fkt_linear_yabschnitt', 'geo_koordinaten'),

  -- Graph
  -- Das Steigungsdreieck ist der zweite Schritt beim Zeichnen und Ablesen.
  ('fkt_linear_graph',      'fkt_linear_steigung'),
  -- Der Startpunkt (0 | b) ist der erste.
  ('fkt_linear_graph',      'fkt_linear_yabschnitt'),

  -- Gleichung
  -- m ist eine der zwei Groessen in y = mx + b ...
  ('fkt_linear_gleichung',  'fkt_linear_steigung'),
  -- ... b die andere.
  ('fkt_linear_gleichung',  'fkt_linear_yabschnitt'),

  -- Nullstelle
  -- 0 = mx + b setzt die Funktionsgleichung voraus.
  ('fkt_linear_nullstelle', 'fkt_linear_gleichung'),
  -- mx = -b aufloesen, oft mit negativem m: genau dieser Gleichungstyp.
  ('fkt_linear_nullstelle', 'gleichung_neg_koeffizient')
on conflict do nothing;


-- ── 3. Drei neue Fehlbilder ─────────────────────────────────────────────────
--
-- Gegen den Bestand geprueft (92 Slugs am 2026-10-01, vollstaendig gelesen,
-- inklusive Vorlauf und Zinsrechnung). Wiederverwendet statt neu angelegt:
--   "Vorzeichenfehler in der Differenz" -> seiten_verwechselt
--       ("Subtrahiert in umgekehrter Reihenfolge, Ergebnis mit falschem Vorzeichen")
--   "Nullstelle b/m statt -b/m"         -> betrag_fehler
--       ("Betrag richtig, Vorzeichen des Ergebnisses gekippt")
--   "m und b vertauscht" im Sachkontext -> groessen_vertauscht
--       ("Vertauscht Grundbetrag und Rate beim Aufstellen")
-- Nicht angelegt: "Kaestchen statt Einheiten gezaehlt". Der Generator
-- koordinatensystem zeichnet nur ein Einheitsraster, der Fehler ist damit
-- nicht ausloesbar.
-- umgekehrt_geteilt (Altbestand, ohne Familie) passt inhaltlich zum
-- Kehrwert, bleibt aber unangetastet (Entscheidung Rasit).
--
-- Neu:
--   steigung_kehrwert            Delta x / Delta y statt Delta y / Delta x
--   m_b_vertauscht               m und b aus y = mx + b vertauscht gelesen
--   achsenabschnitt_verwechselt  Nullstelle und y-Achsenabschnitt verwechselt
--
-- Familie (AF4), gegen die fuenf vorhandenen geprueft, keine neue erfunden:
-- gleichungen_umformen — "kennt das Verfahren, ... wendet sie in der falschen
-- Richtung an". Alle drei sind Strukturfehler mit richtigem Rechenweg; dieselbe
-- Familie traegt schon die Strukturfehler der Binom-Reihe.
--
-- klartext = Coach-Satz, erklaerung = Elterntext. Sprachregeln wie AF3/INV-4:
-- beschrieben wird der Denkschritt, nicht das Kind; kein Defizit-Vokabular,
-- kein Registry-Jargon.
-- freigegeben_am bleibt NULL: Entwurf, wird nirgends ausgeliefert, bis Lena
-- abnimmt:
--   update public.fehlbild_labels
--      set freigegeben_am = now(), freigegeben_von = '<profil-uuid>'
--    where slug in ('steigung_kehrwert','m_b_vertauscht','achsenabschnitt_verwechselt');

insert into public.fehlbild_labels (slug, familie, klartext, erklaerung)
values
  ('steigung_kehrwert', 'gleichungen_umformen',
   'Teilt die waagerechte durch die senkrechte Änderung – die Steigung steht auf dem Kopf.',
   'Die Steigung gibt an, um wie viel der Graph nach oben geht, wenn man einen '
   'Schritt nach rechts geht. Gerechnet wird also „hoch durch rüber“. Hier '
   'wurde umgekehrt geteilt: Beide Änderungen sind richtig abgelesen, nur steht '
   'der Bruch auf dem Kopf. Geübt wird die feste Reihenfolge am '
   'Steigungsdreieck.'),

  ('m_b_vertauscht', 'gleichungen_umformen',
   'Liest Steigung und y-Achsenabschnitt vertauscht aus der Gleichung ab.',
   'In y = mx + b steht die Steigung immer beim x, der y-Achsenabschnitt ist '
   'die Zahl ohne x. Hier wurden beide Zahlen richtig gefunden, aber die '
   'Rollen getauscht. Geübt wird, zuerst nach dem x zu suchen – die Zahl davor '
   'ist die Steigung.'),

  ('achsenabschnitt_verwechselt', 'gleichungen_umformen',
   'Gibt die Nullstelle als y-Achsenabschnitt an oder umgekehrt.',
   'Der y-Achsenabschnitt ist der Punkt, an dem der Graph die senkrechte Achse '
   'schneidet; die Nullstelle der Punkt auf der waagerechten Achse. Hier '
   'wurden die beiden Schnittpunkte verwechselt. Geübt wird, vor dem Ablesen '
   'zu klären, welche Achse gemeint ist.')
on conflict (slug) do nothing;


commit;
