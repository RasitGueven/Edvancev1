-- K9 Kreis, Migration 1 von 2 — fuenf Knoten, sechzehn Kanten, drei neue
-- Fehlbilder (+ zu_frueh_gerundet idempotent). KEINE Aufgaben.
--
-- Kernlehrplan NRW G9, Inhaltsfeld Geometrie, ZWEITE Stufe (9/10), nicht die
-- Erste:
--   Geo-3  Laengen und Flaecheninhalte an Kreisen und Kreissektoren berechnen
--   Geo-4  Idee zur Herleitung der Kreisformeln
-- klasse_herkunft = 9 folgt dem KLP (themen.kreis steht ebenfalls auf 9).
--
-- Einspiel-Reihenfolge: nach dem Vorlauf (20261001115812_substrat_k8_vorlauf,
-- legt term_einsetzen auf Tiefe 5 an) und nach 20261001115718_tiefe_k8_vorlauf
-- (CHECK fundament_tiefe 1..12). Vor <...>_aufgaben_k9_kreis.sql.
--
-- begin/commit in der Datei: scripts/db-migrate.sh laeuft ohne
-- --single-transaction. Ein Abbruch zwischen skills und skill_kante liesse
-- kantenlose Knoten stehen, die lsa_select_next_core als Blatt zieht.

begin;


-- ── 1. Fuenf Knoten ─────────────────────────────────────────────────────────
--
-- Kuerzel nach Bestandskonvention <familie>_<unterfamilie>_<spezifikum>, wie
-- geo_flaeche_rechteck / geo_volumen_quader: geo_kreis_*.
--
-- Tiefe = 1 + tiefste direkte Voraussetzung:
--   umfang   6  ueber term_einsetzen (5)
--   flaeche  6  ueber term_einsetzen (5), groessen_flaechen (5)
--   rueck    7  ueber umfang (6)
--   sektor   7  ueber umfang (6), flaeche (6)
--   zusammen 7  ueber umfang (6), flaeche (6)
--
-- geo_kreis_rueck ist bewusst NUR die Rueckrichtung aus dem Umfang (r oder d
-- aus U). r aus A braeuchte die Quadratwurzel; dafuer gibt es keinen Knoten
-- (KLP Ari-6/7, selbst Zweite Stufe). Die Luecke bleibt offen, kein Ad-hoc-Knoten.
--
-- geo_kreis_zusammen bekommt in dieser Charge Knoten und Kanten, aber noch
-- KEINE Aufgaben: die brauchen Abbildungen, und der Generator dafuer
-- (specs/active/figur-kreis.md) ist noch nicht gebaut.

insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
values
  ('geo_kreis_umfang',   'Umfang des Kreises',                         'mathematik', 9, 6),
  ('geo_kreis_flaeche',  'Flächeninhalt des Kreises',                  'mathematik', 9, 6),
  ('geo_kreis_rueck',    'Radius und Durchmesser aus dem Umfang',      'mathematik', 9, 7),
  ('geo_kreis_sektor',   'Kreisbogen und Kreisausschnitt',             'mathematik', 9, 7),
  ('geo_kreis_zusammen', 'Zusammengesetzte Figuren mit Kreisteilen',   'mathematik', 9, 7)
on conflict (skill_key) do nothing;


-- ── 2. Sechzehn Kanten ──────────────────────────────────────────────────────
--
-- Nach den Knoten: skill_kante_tiefe (DEFERRABLE INITIALLY IMMEDIATE) liest
-- die Tiefe beider Seiten schon beim Insert.
--
-- Nur direkte Voraussetzungen. Gegen den Graphen vom 2026-10-01 geprueft und
-- deshalb NICHT gesetzt, obwohl fachlich beteiligt:
--   dezimal_mult    — haengt schon unter geo_umfang und potenzen
--   dezimal_add_sub — haengt unter dezimal_mult
--   groessen_laengen — haengt unter groessen_flaechen
-- Gesetzt, obwohl auch transitiv erreichbar: flaeche -> potenzen. r² ist der
-- Kern der Flaechenformel; der Abstieg soll bei einem Quadrierfehler direkt
-- dorthin fuehren und nicht ueber term_einsetzen oder groessen_flaechen.

insert into public.skill_kante (skill_key, voraussetzt_skill_key)
values
  -- U = 2·π·r ist ein Term, in den r eingesetzt wird.
  ('geo_kreis_umfang',   'term_einsetzen'),
  -- Umfang als Laenge der Randlinie ist am Vieleck eingefuehrt; der Kreis
  -- uebertraegt den Begriff auf eine krumme Linie.
  ('geo_kreis_umfang',   'geo_umfang'),
  -- Mit π entsteht ein nicht abbrechender Wert; jede Antwort verlangt Runden
  -- auf vorgegebene Stellen (Fehlbild zu_frueh_gerundet). Nicht transitiv
  -- erreichbar, deshalb direkt.
  ('geo_kreis_umfang',   'runden_ueberschlag'),

  -- A = π·r² ist ein Term, in den r eingesetzt wird.
  ('geo_kreis_flaeche',  'term_einsetzen'),
  -- r² muss als r·r gelesen werden; r·2 ist das haeufigste Fehlbild
  -- (mal_exponent).
  ('geo_kreis_flaeche',  'potenzen'),
  -- Flaechen werden in cm² und m² angegeben; der Unterschied zu cm und m traegt
  -- die Formel (Flaeche quadratisch, Umfang linear).
  ('geo_kreis_flaeche',  'groessen_flaechen'),
  -- Wie beim Umfang: π erzwingt das Runden.
  ('geo_kreis_flaeche',  'runden_ueberschlag'),

  -- Die Rueckrichtung ist die umgestellte Umfangsformel; ohne die Vorwaerts-
  -- richtung ist sie nicht lesbar.
  ('geo_kreis_rueck',    'geo_kreis_umfang'),
  -- d = U : π ist eine Division durch einen Dezimalwert.
  ('geo_kreis_rueck',    'dezimal_div'),

  -- Die Bogenlaenge ist der Anteil α/360° des Umfangs.
  ('geo_kreis_sektor',   'geo_kreis_umfang'),
  -- Die Sektorflaeche ist der Anteil α/360° der Kreisflaeche.
  ('geo_kreis_sektor',   'geo_kreis_flaeche'),
  -- Bogen und Sektor wachsen proportional zum Mittelpunktswinkel.
  ('geo_kreis_sektor',   'proportionalitaet'),

  -- Halbkreis, Viertelkreis, Kreisring: Anteile von Umfang und Flaeche.
  ('geo_kreis_zusammen', 'geo_kreis_umfang'),
  ('geo_kreis_zusammen', 'geo_kreis_flaeche'),
  -- Rechteck mit aufgesetztem Halbkreis: die Rechteckflaeche ist Teilsumme.
  ('geo_kreis_zusammen', 'geo_flaeche_rechteck'),
  -- Figuren mit dreieckigem Teil (z. B. Viertelkreis minus Dreieck).
  ('geo_kreis_zusammen', 'geo_flaeche_dreieck')
on conflict do nothing;


-- ── 3. Fehlbilder ───────────────────────────────────────────────────────────
--
-- Gegen den Bestand geprueft (92 Slugs am 2026-10-01, vollstaendig gelesen).
-- Wiederverwendet statt neu angelegt:
--   Umfangs- und Flaechenformel vertauscht -> flaeche_statt_umfang
--       (Bestand geo_umfang) und umfang_statt_flaeche (geo_flaeche_rechteck)
--   r² als 2r gerechnet                  -> mal_exponent
--       (Bestand potenzen: 3^4 -> 12; derselbe Denkfehler r·2 statt r·r)
--   Halbkreis nicht halbiert              -> halbieren_vergessen
--       (Bestand geo_flaeche_dreieck, term_einsetzen)
--   gerade Kante beim Halbkreisumfang     -> seite_vergessen
--       (Bestand geo_umfang: eine Seite der Figur fehlt im Umfang)
--   zu frueh gerundet                     -> zu_frueh_gerundet
--       (vom Zins-Lauf angelegt; hier idempotent mit vereinbartem Klartext)
-- Die fuenf Alt-Slugs ohne Klartext (flaeche_statt_umfang, umfang_statt_flaeche,
-- mal_exponent, halbieren_vergessen, seite_vergessen) bekommen hier KEINEN
-- Klartext: bestehende Zeilen werden nicht veraendert. Das ist der offene Punkt
-- aus specs/active/fehlbild-labels-eltern.md.
--
-- Neu, weil nichts passt:
--   radius_durchmesser_verwechselt — kein Slug fuer Radius/Durchmesser.
--   pi_vergessen — kein Slug fuer eine weggelassene Konstante.
--   NICHT angelegt: flaecheneinheit_nicht_quadriert. Die Einheit steht im
--     Bestand fest am Eingabefeld (tasks.unit), der Fehler ist so nicht
--     sichtbar; Flaecheneinheiten prueft das Fundament (groessen_flaechen).
--   kreisanteil_falsch — anteil_falsch_verteilt meint eine Summe von Anteilen
--     im Sachtext, nicht den Faktor α/360°.
--
-- Familien (AF4), gegen die fuenf vorhandenen geprueft, keine neue erfunden:
--   alle drei -> NULL. Keine Familie beschreibt eine falsch eingesetzte Groesse
--   in einer Formel ("einheiten_massstab" meint das Umwandeln). NULL heisst:
--   im Elternreport nicht gebuendelt. Ob eine Familie dafuer kommt,
--   entscheidet Lena.
--
-- freigegeben_am bleibt NULL (Muster Binom/Vorlauf, AF3): Entwurf, wird
-- nirgends ausgeliefert, bis Lena abnimmt.

insert into public.fehlbild_labels (slug, familie, klartext, erklaerung)
values
  ('radius_durchmesser_verwechselt', null,
   'Setzt den Durchmesser ein, wo der Radius gebraucht wird, oder umgekehrt.',
   'Der Radius reicht vom Mittelpunkt bis zum Rand, der Durchmesser einmal ganz '
   'durch den Kreis – er ist doppelt so lang. Wird die falsche der beiden '
   'Größen in die Formel eingesetzt, ist das Ergebnis doppelt oder halb so groß '
   '(bei der Fläche sogar viermal oder ein Viertel). Geübt wird, vor dem Rechnen '
   'zu klären, welche Größe gegeben ist und welche die Formel verlangt.'),

  ('pi_vergessen', null,
   'Lässt die Kreiszahl π in der Rechnung weg.',
   'Die Rechnung mit Radius oder Durchmesser stimmt, nur der Faktor π fehlt. '
   'Das Ergebnis ist dadurch rund ein Drittel so groß wie richtig. Geübt wird, '
   'die Formel vollständig hinzuschreiben, bevor eingesetzt wird.'),

  ('kreisanteil_falsch', null,
   'Rechnet beim Kreisausschnitt mit dem ganzen Kreis oder dreht den Anteil um.',
   'Ein Kreisausschnitt mit dem Mittelpunktswinkel α ist der Anteil α/360° des '
   'ganzen Kreises. Fehlt dieser Anteil, kommt der ganze Kreis heraus; wird er '
   'umgedreht (360° durch α), kommt ein Vielfaches heraus. Geübt wird, den '
   'Anteil zuerst als Bruch aufzuschreiben, etwa 90° von 360° = ein Viertel.'),

  ('zu_frueh_gerundet', 'sachaufgaben',
   'Rundet ein Zwischenergebnis und rechnet mit dem gerundeten Wert weiter – das Endergebnis weicht deshalb leicht ab.',
   null)
on conflict (slug) do nothing;


commit;
