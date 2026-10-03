-- K8 Flaechen, Migration 1 von 2 — fuenf Knoten, neun Kanten, zwei neue
-- Fehlbilder. KEINE Aufgaben (die folgen in 20261003104949_aufgaben_k8_flaeche.sql).
--
-- Kernlehrplan Mathematik G9 NRW, Inhaltsfeld Geometrie, Erste Stufe (7/8):
--   Geo-8  Flaecheninhalte von Dreiecken, Parallelogrammen, Trapezen, Drachen,
--          Rauten und daraus zusammengesetzten Figuren berechnen; Terme fuer
--          Flaecheninhalte aufstellen.
-- Ueblich in Klasse 8; klasse_herkunft = 8 (Auftrag W4, phase1 a). themen.flaechen_vielecke
-- steht als Stufenbeginn auf 7 und bleibt unveraendert.
--
-- Einspiel-Reihenfolge: nach dem Bestand (geo_flaeche_dreieck, term_einsetzen,
-- term_ausmultiplizieren, gleichung_einschrittig muessen stehen), vor
-- 20261003104949_aufgaben_k8_flaeche.sql.
--
-- Kein begin/commit in der Datei: mig spielt jede Datei mit psql -1 in EINER
-- Transaktion ein. Idempotent ueber on conflict do nothing.


-- ── 1. Fuenf Knoten ─────────────────────────────────────────────────────────
--
-- Kuerzel nach Bestandsmuster geo_flaeche_rechteck / geo_flaeche_dreieck.
-- Das Parallelogramm hat KEINEN eigenen Knoten: geo_flaeche_dreieck (Kl. 7,
-- Tiefe 4) traegt Dreieck und Parallelogramm (Grundseite · Hoehe) schon.
-- "Parallelogramm als Erweiterung" heisst hier Rueckrichtung (geo_flaeche_rueck)
-- und Einbau in zusammengesetzte Figuren.
--
-- Tiefe = 1 + tiefste direkte Voraussetzung:
--   trapez           5  ueber geo_flaeche_dreieck (4)
--   drachen_raute    5  ueber geo_flaeche_dreieck (4)
--   zusammengesetzt  6  ueber trapez (5), drachen_raute (5)
--   term             6  ueber term_ausmultiplizieren (5), term_einsetzen (5)
--   rueck            6  ueber trapez (5), gleichung_einschrittig (5)

insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
values
  ('geo_flaeche_trapez',          'Flächeninhalt des Trapezes',                         'mathematik', 8, 5),
  ('geo_flaeche_drachen_raute',   'Flächeninhalt von Drachen und Raute',                'mathematik', 8, 5),
  ('geo_flaeche_zusammengesetzt', 'Zusammengesetzte Vielecke',                          'mathematik', 8, 6),
  ('geo_flaeche_term',            'Terme für Flächeninhalte',                           'mathematik', 8, 6),
  ('geo_flaeche_rueck',           'Seite oder Höhe aus dem Flächeninhalt',              'mathematik', 8, 6)
on conflict (skill_key) do nothing;


-- ── 2. Neun Kanten ──────────────────────────────────────────────────────────
--
-- Nach den Knoten: skill_kante_tiefe liest die Tiefe beider Seiten schon beim
-- Insert.
--
-- Nur direkte Voraussetzungen. Gegen den Live-Graphen vom 2026-10-03 (dbread)
-- geprueft und deshalb NICHT gesetzt, obwohl fachlich beteiligt:
--   geo_flaeche_rechteck  — haengt unter geo_flaeche_dreieck
--   dezimal_mult, dezimal_div — haengen unter geo_flaeche_dreieck bzw.
--                           gleichung_einschrittig
--   term_zusammenfassen   — haengt unter term_ausmultiplizieren
--   geo_flaeche_dreieck bei zusammengesetzt und rueck — haengt unter trapez
-- Keine bewusst gesetzte transitive Kante.

insert into public.skill_kante (skill_key, voraussetzt_skill_key)
values
  -- Das Trapez wird ueber eine Diagonale in zwei Dreiecke mit gleicher Hoehe
  -- zerlegt; A = (a + c) : 2 · h ist die Summe zweier Dreiecksflaechen.
  ('geo_flaeche_trapez',          'geo_flaeche_dreieck'),

  -- Drachen und Raute zerfallen entlang einer Diagonale in zwei Dreiecke; die
  -- andere Diagonale ist deren gemeinsame Grundseite: A = e · f : 2.
  ('geo_flaeche_drachen_raute',   'geo_flaeche_dreieck'),

  -- Zusammengesetzte Figuren in diesem Knoten enthalten Trapeze als Teilflaeche;
  -- Rechteck und Dreieck kommen transitiv ueber geo_flaeche_dreieck mit.
  ('geo_flaeche_zusammengesetzt', 'geo_flaeche_trapez'),
  -- Ausgeschnittene Rauten (Quadrat minus Raute) sind Teilflaechen; ohne diese
  -- Kante fuehrte der Abstieg nie zu Drachen und Raute.
  ('geo_flaeche_zusammengesetzt', 'geo_flaeche_drachen_raute'),

  -- Seitenlaengen wie x + 3 ergeben Flaechenterme wie 4 · (x + 3); die Klammer
  -- muss ausmultipliziert werden (Fehlbild klammer_vergessen).
  ('geo_flaeche_term',            'term_ausmultiplizieren'),
  -- Der aufgestellte Term wird fuer einen Wert von x ausgewertet.
  ('geo_flaeche_term',            'term_einsetzen'),
  -- Die Formeln fuer Rechteck, Dreieck und Parallelogramm sind der Inhalt der
  -- Terme; ueber die Term-Knoten ist geo_flaeche_dreieck nicht erreichbar.
  ('geo_flaeche_term',            'geo_flaeche_dreieck'),

  -- Die Rueckrichtung stellt die Flaechenformel um, auch die des Trapezes;
  -- Dreieck und Parallelogramm kommen transitiv ueber trapez mit.
  ('geo_flaeche_rueck',           'geo_flaeche_trapez'),
  -- Aus A = g · h wird h = A : g: eine einschrittige Gleichung.
  ('geo_flaeche_rueck',           'gleichung_einschrittig')
on conflict do nothing;


-- ── 3. Fehlbilder ───────────────────────────────────────────────────────────
--
-- Zentral festgelegt in docs/k8-rest/phase1.md d), Text woertlich.
-- Wiederverwendet (vorhanden, hier NICHT angefasst): halbieren_vergessen,
-- halbieren_faelschlich, falsche_hoehe, umfang_statt_flaeche, plus_statt_mal,
-- klammer_vergessen; dazu aus dem Bestand falsche_gegenoperation und
-- falsche_groesse_beantwortet (Rueckrichtung, docs/k8-rest/entscheidungen-flaeche.md).
-- Familie NULL (keine vorhandene Familie beschreibt eine Flaechenzerlegung).
-- freigegeben_am bleibt NULL: Entwurf, bis Lena abnimmt.

insert into public.fehlbild_labels (slug, familie, klartext, erklaerung)
values
  ('nur_eine_grundseite', null,
   'Rechnet beim Trapez nur mit einer der beiden parallelen Seiten.',
   'Die Fläche eines Trapezes ist der Mittelwert der beiden parallelen Seiten mal '
   'der Höhe. Hier wurde nur eine der beiden Seiten verwendet, so als wäre das '
   'Trapez ein Parallelogramm. Geübt wird, zuerst beide parallelen Seiten zu markieren.'),

  ('teilflaeche_vergessen', null,
   'Lässt bei einer zusammengesetzten Figur eine Teilfläche weg.',
   'Zusammengesetzte Figuren werden in einfache Teile zerlegt, deren Flächen man '
   'addiert oder abzieht. Hier fehlt eine Teilfläche im Ergebnis. Geübt wird, die '
   'Zerlegung erst vollständig zu skizzieren und jede Teilfläche abzuhaken.')
on conflict (slug) do nothing;
