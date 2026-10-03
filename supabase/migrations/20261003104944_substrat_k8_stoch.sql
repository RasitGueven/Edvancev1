-- K8 Daten und Wahrscheinlichkeit, Migration 1 von 2 — fuenf Knoten, neun Kanten,
-- sieben neue Fehlbilder. KEINE Aufgaben (die kommen mit
-- 20261003104948_aufgaben_k8_stoch.sql).
--
-- Kernlehrplan NRW G9, Inhaltsfeld Stochastik, ERSTE Stufe (7/8):
--   Sto-1/Sto-2  Daten erheben und auswerten: Median, Quartile, Spannweite einer
--                Datenreihe bestimmen und deuten (Boxplot-Kenngroessen)
--   Sto-3        Wahrscheinlichkeiten als relative Anteile (Laplace) bestimmen
--   Sto-4        mehrstufige Zufallsexperimente mit Pfadregeln (Produkt- und
--                Summenregel) auswerten, mit und ohne Zuruecklegen
--   Sto-5        Gegenereignis nutzen, auch fuer „mindestens einmal"
-- klasse_herkunft = 8: an Koelner Gymnasien ueblich in Klasse 8 (themen.klasse
-- steht fuer die Erste Stufe ueberall auf 7, Stufenbeginn). Thema-Key im Katalog:
-- zufallsexperimente; daten_streumasse (Kl. 5) und statistik_beurteilen (Kl. 9)
-- bleiben unveraendert.
--
-- Einspiel-Reihenfolge: nach 20261003101556 (letzte Prod-Migration, Tiefen-Guard
-- fundament_tiefe 1..12 steht). Vor 20261003104948_aufgaben_k8_stoch.sql.
--
-- KEIN begin/commit in der Datei: mig spielt jede Datei mit psql -1 in EINER
-- Transaktion ein. CI und Wegwerf-DB spielen ohne Klammer ein; jeder Schritt ist
-- mit on conflict do nothing idempotent.


-- ── 1. Fuenf Knoten ─────────────────────────────────────────────────────────
--
-- Kuerzel stoch_* nach Bestandsmuster <familie>_<spezifikum> (bruch_*, prozent_*).
--
-- Tiefe = 1 + tiefste direkte Voraussetzung:
--   kenngroessen   4  ueber dezimal_div (3)
--   laplace        5  ueber bruch_dezimal (4)
--   gegenereignis  6  ueber stoch_laplace (5)
--   pfad_produkt   6  ueber stoch_laplace (5)
--   pfad_summe     7  ueber stoch_pfad_produkt (6), stoch_gegenereignis (6)
--
-- „Mit und ohne Zuruecklegen" ist kein eigener Knoten: es veraendert nur die
-- Faktoren entlang eines Pfades und steckt deshalb in beiden Pfad-Knoten.
-- „Mindestens einmal" ist ein mehrstufiges Ereignis mit vielen Pfaden, das man
-- ueber das Gegenereignis rechnet; es liegt im Knoten pfad_summe (Tiefe 7), der
-- dafuer stoch_gegenereignis voraussetzt. stoch_gegenereignis selbst bleibt
-- einstufig und braucht keine Pfadregel.

insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
values
  ('stoch_kenngroessen',  'Median, Quartile und Spannweite',                       'mathematik', 8, 4),
  ('stoch_laplace',       'Laplace-Wahrscheinlichkeit',                            'mathematik', 8, 5),
  ('stoch_gegenereignis', 'Gegenereignis',                                         'mathematik', 8, 6),
  ('stoch_pfad_produkt',  'Mehrstufige Zufallsexperimente: Produktregel',          'mathematik', 8, 6),
  ('stoch_pfad_summe',    'Mehrstufige Zufallsexperimente: Summenregel',           'mathematik', 8, 7)
on conflict (skill_key) do nothing;

-- Heimat-Thema (skill_thema, PR #192): das Thema, in dem der Stoff im KLP
-- eingefuehrt wird. Ohne Zeile findet freigabe_thema die Aufgaben nicht.
-- Median, Spannweite und Quartile stehen im Katalog unter daten_streumasse
-- (Schlagworte median, quartile, spannweite, boxplot), nicht unter
-- zufallsexperimente. Join auf themen wie in 20261003104647_skill_thema_daten.
insert into public.skill_thema (skill_key, thema_key)
select v.skill_key, v.thema_key
  from (values
    ('stoch_kenngroessen',  'daten_streumasse'),
    ('stoch_laplace',       'zufallsexperimente'),
    ('stoch_gegenereignis', 'zufallsexperimente'),
    ('stoch_pfad_produkt',  'zufallsexperimente'),
    ('stoch_pfad_summe',    'zufallsexperimente')
  ) as v (skill_key, thema_key)
  join public.themen th on th.thema_key = v.thema_key
on conflict (skill_key) do nothing;


-- ── 2. Neun Kanten ──────────────────────────────────────────────────────────
--
-- Nach den Knoten: skill_kante_tiefe liest die Tiefe beider Seiten beim Insert.
--
-- Nur direkte Voraussetzungen. Gegen den Graphen vom 2026-10-03 geprueft und
-- deshalb NICHT gesetzt, obwohl fachlich beteiligt:
--   bruch_kuerzen  — haengt unter bruch_dezimal, bruch_add und bruch_mult
--   dezimal_mult   — haengt unter dezimal_div (und damit unter bruch_dezimal)
--   dezimal_add_sub — haengt unter dezimal_mult
--   bruch_add an pfad_summe — haengt schon unter stoch_gegenereignis
--   prozent_*      — Prozent ist hier nur die Schreibweise in Hundertsteln
--                    (bruch_dezimal), kein Prozentwert/Grundwert; ausserdem
--                    tiefer (6+) und wuerde die Knoten kuenstlich absenken.

insert into public.skill_kante (skill_key, voraussetzt_skill_key)
values
  -- Median bei gerader Anzahl ist (a + b) : 2 und ergibt oft eine Dezimalzahl;
  -- der Durchschnitt (Fehlbild mittelwert_statt_median) ist eine Division.
  ('stoch_kenngroessen',  'dezimal_div'),
  -- Spannweite an Messreihen mit negativen Werten (Temperaturen): 7 − (−5).
  -- Nicht transitiv erreichbar.
  ('stoch_kenngroessen',  'vorzeichen_add_sub'),

  -- Eine Laplace-Wahrscheinlichkeit ist ein Bruch, der gekuerzt und als Dezimal-
  -- zahl oder in Prozent geschrieben wird.
  ('stoch_laplace',       'bruch_dezimal'),

  -- Das Gegenereignis setzt den Begriff der Wahrscheinlichkeit voraus.
  ('stoch_gegenereignis', 'stoch_laplace'),
  -- 1 − p ist eine Bruchsubtraktion, bei zwei Ereignissen mit Hauptnenner.
  ('stoch_gegenereignis', 'bruch_add'),

  -- Jede Stufe eines Pfades ist eine Laplace-Wahrscheinlichkeit.
  ('stoch_pfad_produkt',  'stoch_laplace'),
  -- Entlang des Pfades werden Brueche multipliziert (Fehlbild pfadregel_addiert).
  ('stoch_pfad_produkt',  'bruch_mult'),

  -- Die Summenregel addiert Pfadwahrscheinlichkeiten, die erst mit der
  -- Produktregel entstehen.
  ('stoch_pfad_summe',    'stoch_pfad_produkt'),
  -- „Mindestens einmal" wird ueber das Gegenereignis gerechnet; die Bruch-
  -- addition kommt ueber diese Kante mit.
  ('stoch_pfad_summe',    'stoch_gegenereignis')
on conflict do nothing;


-- ── 3. Fehlbilder ───────────────────────────────────────────────────────────
--
-- Zentral festgelegt in docs/k8-rest/phase1.md d), Text woertlich. Familie NULL
-- (keine der vorhandenen Familien beschreibt Wahrscheinlichkeit oder Kenngroessen).
-- freigegeben_am bleibt NULL: Entwurf, bis Lena abnimmt.
--
-- Wiederverwendet (vorhanden, hier NICHT angefasst): umgekehrt_geteilt,
-- nenner_addiert, bedingung_unvollstaendig, falsche_groesse_beantwortet,
-- seiten_verwechselt, multipliziert_statt_dividiert.

insert into public.fehlbild_labels (slug, familie, klartext, erklaerung)
values
  ('verhaeltnis_statt_anteil', null,
   'Teilt die günstigen durch die übrigen statt durch alle möglichen Ergebnisse.',
   'Eine Wahrscheinlichkeit ist der Anteil der günstigen Ergebnisse an allen möglichen. '
   'Liegen 3 rote und 2 blaue Kugeln in einer Urne, ist „rot“ also 3 von 5, nicht 3 zu 2. '
   'Hier wurden die günstigen Ergebnisse mit den übrigen verglichen statt mit allen. '
   'Geübt wird, zuerst die Gesamtzahl aufzuschreiben.'),

  ('zuruecklegen_ignoriert', null,
   'Rechnet beim Ziehen ohne Zurücklegen im zweiten Zug mit der alten Anzahl weiter (oder umgekehrt).',
   'Wird eine gezogene Kugel nicht zurückgelegt, liegt beim zweiten Zug eine Kugel weniger '
   'in der Urne, und von der gezogenen Farbe auch eine weniger. Hier wurde der zweite Zug so '
   'gerechnet, als wäre noch alles da (oder beim Zurücklegen so, als fehlte eine). Geübt '
   'wird, vor jedem Zug den neuen Inhalt der Urne kurz aufzuschreiben.'),

  ('pfadregel_addiert', null,
   'Addiert die Wahrscheinlichkeiten entlang eines Pfades, statt sie zu multiplizieren.',
   'Bei Zufallsversuchen in mehreren Stufen wird entlang eines Pfades multipliziert: Erst '
   'rot und dann noch einmal rot ist ein Anteil vom Anteil. Wer addiert, bekommt ein zu '
   'großes Ergebnis, manchmal sogar mehr als 1, und das kann keine Wahrscheinlichkeit sein. '
   'Geübt wird die Merkregel „erst …, dann … heißt mal“.'),

  ('nur_ein_pfad', null,
   'Berücksichtigt bei einem Ereignis nur einen von mehreren passenden Pfaden.',
   'Gehören zu einem Ereignis mehrere Pfade, etwa „einmal rot und einmal blau“ in beiden '
   'Reihenfolgen, werden ihre Wahrscheinlichkeiten addiert. Hier wurde nur ein Pfad gezählt, '
   'das Ergebnis ist deshalb zu klein. Geübt wird, vor dem Rechnen alle passenden Pfade '
   'aufzulisten.'),

  ('gegenereignis_nicht_abgezogen', null,
   'Gibt die Wahrscheinlichkeit des Gegenereignisses an statt der gesuchten.',
   'Oft ist das Gegenteil leichter zu berechnen, etwa „keine Sechs“ statt „mindestens eine '
   'Sechs“. Danach muss das Ergebnis noch von 1 abgezogen werden. Hier fehlt dieser letzte '
   'Schritt, die Rechnung davor stimmt. Geübt wird, am Ende noch einmal nachzulesen, nach '
   'welchem Ereignis gefragt war.'),

  ('mittelwert_statt_median', null,
   'Berechnet den Durchschnitt, obwohl der Median gefragt ist.',
   'Der Median ist der Wert in der Mitte der geordneten Liste, der Durchschnitt die Summe '
   'geteilt durch die Anzahl. Bei einzelnen sehr großen oder sehr kleinen Werten liegen '
   'beide weit auseinander. Hier wurde der Durchschnitt berechnet. Geübt wird, den Median '
   'durch Ordnen und Abzählen zu finden.'),

  ('median_ohne_sortieren', null,
   'Nimmt den mittleren Wert der Liste, ohne sie vorher zu ordnen.',
   'Der Median ist nur in einer der Größe nach geordneten Liste der mittlere Wert. Wer die '
   'Werte in der gegebenen Reihenfolge abzählt, trifft eine zufällige Zahl. Geübt wird, die '
   'Liste immer zuerst zu ordnen und dann abzuzählen.')
on conflict (slug) do nothing;
