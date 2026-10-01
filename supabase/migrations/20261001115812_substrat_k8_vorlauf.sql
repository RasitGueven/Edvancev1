-- K8-/K9-Vorlauf, Migration 2 von 3 — zwei Fundament-Knoten, drei Kanten,
-- zwei Fehlbilder. KEINE Aufgaben (die stehen in Migration 3).
--
-- Einspiel-Reihenfolge: nach 20261001115718_tiefe_k8_vorlauf.sql (die Tiefen
-- hier liegen zwar unter 8, aber die Themen-Laeufe stapeln darauf), vor
-- <...>_aufgaben_k8_vorlauf.sql.
--
-- Beide Knoten fehlen im Graphen (43 Knoten am 2026-10-01) und werden von
-- mehreren Themen-Laeufen gebraucht — deshalb hier und nicht in den Laeufen:
--   geo_koordinaten  <- Lineare Funktionen
--   term_einsetzen   <- Lineare Funktionen, Zinsrechnung, Kreis
--
-- begin/commit in der Datei: scripts/db-migrate.sh laeuft ohne
-- --single-transaction. Ein Abbruch zwischen skills und skill_kante liesse
-- kantenlose Knoten stehen, die lsa_select_next_core als Blatt zieht.

begin;


-- ── 1. Zwei Knoten ──────────────────────────────────────────────────────────
--
-- Kuerzel nach Bestandskonvention <familie>_<thema>: geo_ wie geo_umfang /
-- geo_flaeche_rechteck, term_ wie term_zusammenfassen / term_ausmultiplizieren.
--
-- Tiefe = 1 + tiefste Voraussetzung, wie bei geo_umfang (3 ueber dezimal_mult
-- 2) und term_ausmultiplizieren (5 ueber term_zusammenfassen 4):
--   geo_koordinaten  2  ueber vorzeichen_add_sub (1)
--   term_einsetzen   5  ueber vorzeichen_vorrang (4) und potenzen (4)
--
-- geo_koordinaten — KLP NRW G9, Geometrie Erprobungsstufe (Geo-6: ebene
-- Figuren im kartesischen Koordinatensystem). Negative Koordinaten kommen erst
-- mit den rationalen Zahlen der Ersten Stufe (Ari-1) dazu; deshalb die Kante
-- auf vorzeichen_add_sub, obwohl dieser Knoten klasse_herkunft 7 traegt. Die
-- Herkunft des Knotens bleibt 6 (dort wird das Koordinatensystem eingefuehrt),
-- die Kante bildet ab, was die Vier-Quadranten-Aufgaben zusaetzlich brauchen.
--
-- term_einsetzen — KLP NRW G9, Arithmetik/Algebra Erste Stufe (Ari-4/Ari-5:
-- Variable als Platzhalter, Terme als Rechenvorschrift).

insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
values
  ('geo_koordinaten', 'Punkte im Koordinatensystem', 'mathematik', 6, 2),
  ('term_einsetzen',  'Werte in Terme einsetzen',    'mathematik', 7, 5)
on conflict (skill_key) do nothing;


-- ── 2. Drei Kanten ──────────────────────────────────────────────────────────
--
-- Nach den Knoten: skill_kante_tiefe (DEFERRABLE INITIALLY IMMEDIATE) liest
-- die Tiefe beider Seiten schon beim Insert.

insert into public.skill_kante (skill_key, voraussetzt_skill_key)
values
  -- Wer -3 nicht als "drei nach links" lesen kann, liest den zweiten bis
  -- vierten Quadranten falsch ab.
  ('geo_koordinaten', 'vorzeichen_add_sub'),
  -- Einsetzen ist Rechnen mit Vorrang: 5 - 3 · (-2) kippt ohne Punkt vor
  -- Strich und ohne Vorzeichenregeln.
  ('term_einsetzen',  'vorzeichen_vorrang'),
  -- 3 · x² fuer x = -2: ohne Potenzbegriff (und (-2)² = 4) kein Ergebnis.
  ('term_einsetzen',  'potenzen')
on conflict do nothing;


-- ── 3. Zwei neue Fehlbilder ─────────────────────────────────────────────────
--
-- Gegen den Bestand geprueft (85 Slugs am 2026-10-01, vollstaendig gelesen).
-- Wiederverwendet statt neu angelegt:
--   "Minus beim Einsetzen nicht geklammert" -> vorzeichen_potenz
--       (Bestand: (-3)^2 = -9, -2^2; genau der Denkfehler -2² statt (-2)²)
--   "Vorrang beim Einsetzen missachtet"    -> vorrang_ignoriert
--       ("Rechnet strikt von links nach rechts")
-- Neu, weil nichts passt:
--   koordinaten_vertauscht — groessen_vertauscht meint Grundbetrag/Rate im
--     Sachtext, basis_exponent_vertauscht die Potenz; beides ist ein anderer
--     Denkfehler mit anderer Foerderung.
--   koordinate_vorzeichen_verloren — betrag_fehler/vorzeichen_ignoriert sind
--     RECHENfehler ("Vorzeichen des Ergebnisses gekippt", "addiert die
--     Betraege"). Beim Ablesen wird nicht gerechnet: hier fehlt die Richtung der
--     Achse. Geuebt wird etwas anderes (Achse lesen statt Vorzeichenregel).
--
-- Familien (AF4), gegen die fuenf vorhandenen geprueft, keine neue erfunden:
--   koordinate_vorzeichen_verloren -> vorzeichen ("verliert ... das
--     Vorzeichen, das Ergebnis kippt ins Gegenteil").
--   koordinaten_vertauscht -> NULL. Keine der fuenf Familien beschreibt eine
--     vertauschte Reihenfolge beim Ablesen. NULL heisst: im Elternreport nicht
--     gebuendelt. Ob eine Familie dafuer kommt, entscheidet Lena (offener Punkt
--     im PR), nicht diese Migration.
--
-- freigegeben_am bleibt NULL (Muster Binom, AF3): Entwurf, wird nirgends
-- ausgeliefert, bis Lena abnimmt.

insert into public.fehlbild_labels (slug, familie, klartext, erklaerung)
values
  ('koordinaten_vertauscht', null,
   'Liest x- und y-Koordinate in vertauschter Reihenfolge ab.',
   'Der Punkt wird richtig gefunden, aber die beiden Werte stehen in der '
   'falschen Reihenfolge: zuerst der Wert an der senkrechten Achse, dann der an '
   'der waagerechten. Im Koordinatenpaar steht immer zuerst x (nach rechts '
   'oder links), dann y (nach oben oder unten). Geuebt wird die feste '
   'Reihenfolge beim Ablesen und beim Eintragen.'),

  ('koordinate_vorzeichen_verloren', 'vorzeichen',
   'Koordinate richtig abgelesen, aber das Minus fehlt.',
   'Der Abstand zum Ursprung stimmt, nur die Richtung ist verloren: ein Punkt '
   'links der y-Achse oder unterhalb der x-Achse bekommt eine positive '
   'Koordinate. Das ist kein Rechenfehler, sondern eine Frage der '
   'Achsenrichtung. Geuebt wird, die negativen Abschnitte der Achsen als '
   'eigene Richtung zu lesen.')
on conflict (slug) do nothing;


commit;
