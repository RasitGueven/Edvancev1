-- K8 Lineare Gleichungssysteme, Migration 1 von 2 — fuenf Knoten, dreizehn Kanten,
-- vier neue Fehlbilder. KEINE Aufgaben (die folgen in 20261003104947_aufgaben_k8_lgs.sql).
--
-- Kernlehrplan NRW G9, Inhaltsfeld Arithmetik/Algebra, ERSTE Stufe (7/8):
--   Ari-9   lineare Gleichungssysteme mit zwei Variablen loesen (Gleichsetzungs-,
--           Einsetzungs-, Additionsverfahren, grafisch) und ihre Loesbarkeit untersuchen
--   Ari-10  Sachsituationen mit linearen Gleichungssystemen modellieren
-- klasse_herkunft = 8: an Koelner Gymnasien ueblich in Klasse 8 (themen.lineare_gleichungen_lgs
-- steht als Stufenbeginn auf 7). Keine Bindung an ein Schuljahr.
--
-- Einspiel-Reihenfolge: nach dem Linear-Lauf (20261001124808_substrat_k8_linfkt, legt
-- fkt_linear_graph auf Tiefe 7 an) und nach 20261001115718_tiefe_k8_vorlauf (CHECK
-- fundament_tiefe 1..12). Vor 20261003104947_aufgaben_k8_lgs.sql.
--
-- KEIN begin/commit in der Datei: mig spielt jede Datei mit psql -1 in EINER Transaktion
-- ein (Auftrag K8-Rest). Idempotent ueber on conflict do nothing.


-- ── 1. Fuenf Knoten ─────────────────────────────────────────────────────────
--
-- Kuerzel nach Bestandskonvention <familie>_<unterfamilie>_<spezifikum>, wie
-- gleichung_zweischrittig / gleichung_modellieren: gleichung_lgs_*.
--
-- Tiefe = 1 + tiefste direkte Voraussetzung:
--   einsetzen     7  ueber term_minusklammer (6), gleichung_zweischrittig (6)
--   gleichsetzen  8  ueber gleichung_beidseitig (7), gleichung_neg_koeffizient (7)
--   addition      8  ueber gleichung_neg_koeffizient (7)
--   grafisch      8  ueber fkt_linear_graph (7)
--   sachaufgabe   9  ueber gleichung_modellieren (8), gleichung_lgs_addition (8)
--
-- Die Loesbarkeit (keine / unendlich viele Loesungen) ist kein eigener Knoten: Sie
-- zeigt sich in jedem Verfahren am Ende der Rechnung (0 = 5 bzw. 0 = 0) und grafisch an
-- der Lage der Geraden. Die Aufgaben dazu haengen an gleichsetzen, addition und grafisch.

insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
values
  ('gleichung_lgs_einsetzen',   'Einsetzungsverfahren',                              'mathematik', 8, 7),
  ('gleichung_lgs_gleichsetzen', 'Gleichsetzungsverfahren',                          'mathematik', 8, 8),
  ('gleichung_lgs_addition',    'Additionsverfahren',                                'mathematik', 8, 8),
  ('gleichung_lgs_grafisch',    'LGS grafisch lösen (Schnittpunkt)',                 'mathematik', 8, 8),
  ('gleichung_lgs_sachaufgabe', 'LGS aus Sachsituationen aufstellen und lösen',      'mathematik', 8, 9)
on conflict (skill_key) do nothing;

-- Heimat-Thema (skill_thema, PR #192): das Thema, in dem der Stoff im KLP
-- eingefuehrt wird. Ohne Zeile findet freigabe_thema die Aufgaben nicht.
-- Join auf themen wie in 20261003104647_skill_thema_daten.
insert into public.skill_thema (skill_key, thema_key)
select v.skill_key, v.thema_key
  from (values
    ('gleichung_lgs_einsetzen',    'lineare_gleichungen_lgs'),
    ('gleichung_lgs_gleichsetzen', 'lineare_gleichungen_lgs'),
    ('gleichung_lgs_addition',     'lineare_gleichungen_lgs'),
    ('gleichung_lgs_grafisch',     'lineare_gleichungen_lgs'),
    ('gleichung_lgs_sachaufgabe',  'lineare_gleichungen_lgs')
  ) as v (skill_key, thema_key)
  join public.themen th on th.thema_key = v.thema_key
on conflict (skill_key) do nothing;


-- ── 2. Dreizehn Kanten ──────────────────────────────────────────────────────
--
-- Nach den Knoten: skill_kante_tiefe (DEFERRABLE INITIALLY IMMEDIATE) liest die
-- Tiefe beider Seiten schon beim Insert.
--
-- Nur direkte Voraussetzungen. Gegen den Graphen vom 2026-10-03 geprueft (dbread) und
-- deshalb NICHT gesetzt, obwohl fachlich beteiligt:
--   term_ausmultiplizieren, term_zusammenfassen — haengen unter term_minusklammer
--       (einsetzen) bzw. sind bei addition ueber term_ausmultiplizieren erreichbar
--   gleichung_zweischrittig, vorzeichen_mult_div — haengen unter gleichung_neg_koeffizient
--       und gleichung_beidseitig (gleichsetzen, addition)
--   fkt_linear_steigung, fkt_linear_yabschnitt, geo_koordinaten — haengen unter
--       fkt_linear_graph (grafisch)
--   gleichung_lgs_gleichsetzen als Voraussetzung von sachaufgabe — Gleichsetzen ist der
--       Sonderfall des Einsetzens (beide Gleichungen nach derselben Variablen aufgeloest);
--       die Sachaufgaben verlangen Einsetzen oder Addieren.
-- Gesetzt, obwohl nicht aus dem Hub-Vorschlag: term_einsetzen bei den drei Rechenverfahren.
-- Das Rueckeinsetzen des ersten Werts in eine Ausgangsgleichung ist der zweite Teil jedes
-- Verfahrens; term_einsetzen ist von keinem der uebrigen Voraussetzungen aus erreichbar.

insert into public.skill_kante (skill_key, voraussetzt_skill_key)
values
  -- Beim Einsetzen wird ein Term mit zwei Gliedern fuer eine Variable eingesetzt; steht
  -- davor ein Faktor oder ein Minus, muss die Klammer aufgeloest werden (klammer_vergessen).
  ('gleichung_lgs_einsetzen',    'term_minusklammer'),
  -- Nach dem Einsetzen bleibt eine Gleichung mit einer Variablen: ax + b = c.
  ('gleichung_lgs_einsetzen',    'gleichung_zweischrittig'),
  -- Den ersten Wert in eine Ausgangsgleichung einsetzen und die zweite Variable ausrechnen.
  ('gleichung_lgs_einsetzen',    'term_einsetzen'),

  -- Gleichsetzen erzeugt eine Gleichung mit x auf beiden Seiten.
  ('gleichung_lgs_gleichsetzen', 'gleichung_beidseitig'),
  -- Zusammenfassen fuehrt oft auf -3x = -12: Division durch eine negative Zahl
  -- (vorzeichen_beim_umstellen).
  ('gleichung_lgs_gleichsetzen', 'gleichung_neg_koeffizient'),
  -- Rueckeinsetzen wie oben.
  ('gleichung_lgs_gleichsetzen', 'term_einsetzen'),

  -- Subtrahieren zweier Gleichungen erzeugt negative Koeffizienten und Konstanten.
  ('gleichung_lgs_addition',     'gleichung_neg_koeffizient'),
  -- Eine Gleichung mit einem Faktor multiplizieren heisst: jedes Glied auf beiden Seiten
  -- ausmultiplizieren (nicht_alle_glieder_multipliziert).
  ('gleichung_lgs_addition',     'term_ausmultiplizieren'),
  -- Rueckeinsetzen wie oben.
  ('gleichung_lgs_addition',     'term_einsetzen'),

  -- Die Loesung ist der Schnittpunkt zweier Geraden y = mx + b; der Graph traegt Steigung,
  -- y-Achsenabschnitt und das Ablesen von Koordinaten (Kante zu einem Draft-Knoten des
  -- Linear-Laufs; dessen Aufgaben fasst dieser Lauf nicht an).
  ('gleichung_lgs_grafisch',     'fkt_linear_graph'),

  -- Aus dem Text zwei Gleichungen aufstellen: Variablen festlegen, Bedingungen uebersetzen.
  ('gleichung_lgs_sachaufgabe',  'gleichung_modellieren'),
  -- Die aufgestellten Systeme werden durch Einsetzen geloest (eine Gleichung ist oft schon
  -- nach einer Variablen aufgeloest: x + y = 50 -> x = 50 - y) ...
  ('gleichung_lgs_sachaufgabe',  'gleichung_lgs_einsetzen'),
  -- ... oder durch Addieren (zwei Preisangaben mit verschiedenen Mengen).
  ('gleichung_lgs_sachaufgabe',  'gleichung_lgs_addition')
on conflict do nothing;


-- ── 3. Fehlbilder ───────────────────────────────────────────────────────────
--
-- Zentral festgelegt in docs/k8-rest/phase1.md d), Text woertlich. Wiederverwendet (nicht
-- angefasst): klammer_vergessen, vorzeichen_beim_umstellen, falsches_vorzeichen_beim_
-- zusammenfuehren, variablen_nicht_zusammengefuehrt, koordinaten_vertauscht,
-- groessen_vertauscht, bedingung_unvollstaendig, division_vergessen; dazu aus dem Bestand
-- falsche_groesse_beantwortet, koordinate_vorzeichen_verloren, klammer_falsch_gesetzt,
-- umfang_falsch_modelliert (Begruendung in docs/k8-rest/entscheidungen-lgs.md).
--
-- Familie gleichungen_umformen (vorhanden). freigegeben_am bleibt NULL: Entwurf, wird nicht
-- ausgeliefert, bis Lena abnimmt.

insert into public.fehlbild_labels (slug, familie, klartext, erklaerung)
values
  ('nicht_alle_glieder_multipliziert', 'gleichungen_umformen',
   'Multipliziert beim Additionsverfahren nur einen Teil der Gleichung mit dem Faktor.',
   'Beim Additionsverfahren wird eine Gleichung mit einer Zahl malgenommen, damit sich danach '
   'eine Variable weghebt. Das muss für jedes Glied auf beiden Seiten gelten, sonst ist es nicht '
   'mehr dieselbe Gleichung. Hier wurde ein Glied vergessen, meist die Zahl auf der rechten Seite. '
   'Geübt wird, nach dem Malnehmen jedes Glied einzeln abzuhaken.'),

  ('seiten_ungleich_verknuepft', 'gleichungen_umformen',
   'Verknüpft die beiden Gleichungen links und rechts unterschiedlich – links subtrahiert, rechts addiert oder umgekehrt.',
   'Beim Additionsverfahren werden zwei Gleichungen Seite für Seite verrechnet: Was links passiert, '
   'muss genauso rechts passieren. Hier wurden die linken Seiten voneinander abgezogen, die rechten '
   'aber zusammengezählt (oder umgekehrt). Die Variable fällt zwar weg, das Ergebnis stimmt aber '
   'nicht. Geübt wird, die Rechenart einmal für beide Seiten festzulegen und dazuzuschreiben.'),

  ('loesungsanzahl_verwechselt', 'gleichungen_umformen',
   'Verwechselt „keine Lösung“ und „unendlich viele Lösungen“.',
   'Ein Gleichungssystem kann genau eine, keine oder unendlich viele Lösungen haben. Parallele '
   'Geraden schneiden sich nie: keine Lösung. Liegen beide Geraden aufeinander, ist jeder Punkt '
   'gemeinsam: unendlich viele. Hier wurden die beiden Sonderfälle vertauscht. Geübt wird, das '
   'Ende der Rechnung zu lesen: Eine falsche Aussage wie 0 = 5 heißt keine Lösung, eine wahre wie '
   '0 = 0 heißt unendlich viele.'),

  ('parallele_uebersehen', 'gleichungen_umformen',
   'Nimmt genau eine Lösung an, obwohl die Geraden parallel sind oder aufeinander liegen.',
   'Zwei Geraden schneiden sich genau dann in einem Punkt, wenn ihre Steigungen verschieden sind. '
   'Bei gleicher Steigung sind sie parallel oder liegen aufeinander. Hier wurde ein Schnittpunkt '
   'angenommen, ohne die Steigungen zu vergleichen. Geübt wird, beide Gleichungen in die Form '
   'y = mx + b zu bringen und zuerst die Steigungen zu vergleichen.')
on conflict (slug) do nothing;
