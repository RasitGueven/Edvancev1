-- K8 Zinsrechnung, Migration 1 von 2: vier Knoten, elf Kanten, fuenf
-- Fehlbilder. KEINE Aufgaben (die stehen in Migration 2).
--
-- Kernlehrplan NRW G9, Erste Stufe, Inhaltsfeld Funktionen (nicht Arithmetik):
--   Fkt-8  Prozent- und Zinsrechnung in Konsumsituationen
--   Fkt-9  Wachstumsfaktoren, prozentuale Veraenderungen kombinieren
--   Ari-8  Exponenten in der Zinsrechnung durch systematisches Probieren
-- Die Erste Stufe umfasst die Klassen 7 und 8; der KLP bindet sie an kein
-- Schuljahr. klasse_herkunft = 7 folgt der frueheren Schnittfuehrung (Koelner
-- Gymnasien behandeln Zinsrechnung in Klasse 7, Real- und Gesamtschulen in 8),
-- nicht einer Lehrplanbindung.
--
-- Voraussetzung: der K8-Vorlauf ist eingespielt
--   20261001115718_tiefe_k8_vorlauf      skills_fundament_tiefe_check 1..12
--                                        (prozent_zins_zinseszins liegt auf 9)
--   20261001115812_substrat_k8_vorlauf   term_einsetzen (Kantenziel)
-- Ohne beide scheitert diese Datei am CHECK bzw. am Kanten-Guard.
--
-- begin/commit in der Datei: scripts/db-migrate.sh laeuft ohne
-- --single-transaction. Ein Abbruch zwischen skills und skill_kante liesse
-- kantenlose Knoten stehen, die lsa_select_next_core als Blatt zieht.
--
-- Bericht und Entscheidungen: docs/k8/zins-phase0.md.

begin;


-- ── 1. Vier Knoten ──────────────────────────────────────────────────────────
--
-- Kuerzel prozent_zins_<thema>: Zinsen SIND Prozentwerte, alle Knoten haengen
-- am prozent_-Ast. Unterfamilie wie geo_flaeche_* und term_binom_*.
--
-- Tiefe = 1 + tiefste direkte Voraussetzung:
--   jahreszins     7  ueber prozent_prozentwert (6)
--   teilzins       8  ueber jahreszins (7)
--   rueckrechnung  8  ueber jahreszins / prozent_grundwert / prozent_prozentsatz (7)
--   zinseszins     9  ueber prozent_veraenderung (8)
-- teilzins und rueckrechnung sind Geschwister: beide bauen auf den
-- Jahreszinsen auf, nicht aufeinander.

insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
values
  ('prozent_zins_jahreszins',    'Jahreszinsen berechnen',               'mathematik', 7, 7),
  ('prozent_zins_teilzins',      'Zinsen für Monate und Tage',           'mathematik', 7, 8),
  ('prozent_zins_rueckrechnung', 'Kapital oder Zinssatz aus den Zinsen', 'mathematik', 7, 8),
  ('prozent_zins_zinseszins',    'Zinseszins und Wachstumsfaktor',       'mathematik', 7, 9)
on conflict (skill_key) do nothing;


-- ── 2. Elf Kanten ───────────────────────────────────────────────────────────
--
-- Nur direkte Kanten (jahreszins 1 · teilzins 4 · rueckrechnung 3 ·
-- zinseszins 3). Nach den Knoten: skill_kante_tiefe (DEFERRABLE INITIALLY
-- IMMEDIATE) liest die Tiefe beider Seiten schon beim Insert.

insert into public.skill_kante (skill_key, voraussetzt_skill_key)
values
  -- Jahreszinsen sind der Prozentwert des Kapitals zum Zinssatz.
  ('prozent_zins_jahreszins',    'prozent_prozentwert'),

  -- Teilzinsen sind Jahreszinsen mal Zeitanteil.
  ('prozent_zins_teilzins',      'prozent_zins_jahreszins'),
  -- Monate und Tage muessen in Anteile eines Jahres umgerechnet werden.
  ('prozent_zins_teilzins',      'groessen_zeit'),
  -- Z = K · p/100 · t/360: mehrere Werte zugleich in eine Formel einsetzen.
  ('prozent_zins_teilzins',      'term_einsetzen'),
  -- Der Zeitanteil 7/12 oder 45/360 ist ein Bruch, der mit einem Betrag
  -- multipliziert wird; groessen_zeit prueft im Bestand nur min <-> h.
  ('prozent_zins_teilzins',      'bruch_mult'),

  -- Rueckrichtung derselben Beziehung Z = K · p/100.
  ('prozent_zins_rueckrechnung', 'prozent_zins_jahreszins'),
  -- Kapital gesucht ist Grundwert gesucht.
  ('prozent_zins_rueckrechnung', 'prozent_grundwert'),
  -- Zinssatz gesucht ist Prozentsatz gesucht.
  ('prozent_zins_rueckrechnung', 'prozent_prozentsatz'),

  -- Jedes Jahr ist eine Jahreszins-Rechnung auf dem neuen Kapital.
  ('prozent_zins_zinseszins',    'prozent_zins_jahreszins'),
  -- Der Wachstumsfaktor 1 + p/100 ist die prozentuale Veraenderung als
  -- Faktor; kombinierte Veraenderungen (Fkt-9) bauen darauf auf.
  ('prozent_zins_zinseszins',    'prozent_veraenderung'),
  -- n Jahre heissen Faktor hoch n; die Laufzeit wird durch Probieren mit
  -- Potenzen gefunden (Ari-8).
  ('prozent_zins_zinseszins',    'potenzen')
on conflict do nothing;


-- ── 3. Fuenf neue Fehlbilder ────────────────────────────────────────────────
--
-- Gegen den Bestand geprueft (87 Slugs am 2026-10-01, vollstaendig gelesen).
-- Wiederverwendet statt neu angelegt:
--   "p statt p/100 gerechnet"                  -> dezimalverschiebung
--   "Zinsen statt Endkapital angegeben"        -> nur_prozentwert
--   "Endkapital statt Zinsen angegeben"        -> falsche_groesse_beantwortet
--   "Rueckrechnung multipliziert statt dividiert" -> multipliziert_statt_dividiert
--   (Zinssatz) Faktor 100 fehlt / Bezug vertauscht
--                                              -> faktor_100_vergessen / bezug_vertauscht
-- Zusammengelegt (Entscheidung Rasit): "Zinseszins linear gerechnet" und
-- "Veraenderungen addiert statt Faktoren multipliziert" sind derselbe
-- Denkkern -> ein Slug prozente_addiert.
--
-- zu_frueh_gerundet wird auch vom Kreis-Lauf gebraucht. Slug und Klartext sind
-- zwischen beiden Laeufen verbindlich abgestimmt; on conflict (slug) do
-- nothing, damit die Reihenfolge des Einspielens egal ist.
--
-- Familien gegen die fuenf vorhandenen geprueft, keine neue erfunden:
--   einheiten_massstab ("rechnet beim Umwandeln mit dem falschen Faktor"):
--     zinszeit_falsch_umgerechnet, wachstumsfaktor_falsch
--   sachaufgaben ("waehlt den falschen Rechenweg fuer die Situation"):
--     zeitfaktor_vergessen, prozente_addiert, zu_frueh_gerundet
--
-- freigegeben_am bleibt NULL (Muster Binom, AF3): Entwurf, wird nirgends
-- ausgeliefert, bis Lena abnimmt.

insert into public.fehlbild_labels (slug, familie, klartext, erklaerung)
values
  ('zeitfaktor_vergessen', 'sachaufgaben',
   'Rechnet die Zinsen für ein ganzes Jahr, obwohl das Geld nur einige Monate oder Tage angelegt ist.',
   'Der Zinssatz gilt immer für ein Jahr. Liegt das Geld kürzer, gibt es nur '
   'den passenden Teil der Jahreszinsen – für 3 Monate also ein Viertel. Geübt '
   'wird, die Jahreszinsen mit dem Zeitanteil zu multiplizieren.'),

  ('zinszeit_falsch_umgerechnet', 'einheiten_massstab',
   'Rechnet Monate oder Tage mit dem falschen Teiler in Jahre um, zum Beispiel durch 100 statt durch 12 oder 360.',
   'Ein Jahr hat 12 Monate; in der Zinsrechnung zählt man es mit 360 Tagen '
   '(jeder Monat 30 Tage). Wer durch 100 teilt, behandelt die Zeit wie einen '
   'Prozentsatz. Geübt wird, den Zeitanteil als Bruch zu schreiben: '
   'Monate durch 12, Tage durch 360.'),

  ('prozente_addiert', 'sachaufgaben',
   'Zählt Prozentsätze einfach zusammen, statt die Änderungen nacheinander auszurechnen.',
   'Beim Zinseszins bringen auch die Zinsen des Vorjahres wieder Zinsen; zwei '
   'Jahre zu 5 % sind deshalb mehr als 10 %. Ebenso landet man nach plus 20 % '
   'und danach minus 20 % nicht wieder beim Anfangswert. Geübt wird, jede '
   'Änderung auf den neuen Wert zu beziehen – also Faktoren zu multiplizieren.'),

  ('wachstumsfaktor_falsch', 'einheiten_massstab',
   'Bildet den Faktor für eine prozentuale Zunahme falsch, zum Beispiel 1,5 statt 1,05 bei 5 %.',
   'Eine Zunahme um p % bedeutet: der alte Wert bleibt ganz erhalten (1) und '
   'p Hundertstel kommen dazu. Bei 5 % ist der Faktor 1,05, nicht 1,5 und '
   'nicht 0,05. Geübt wird, den Faktor aus dem Prozentsatz sicher zu bilden.'),

  ('zu_frueh_gerundet', 'sachaufgaben',
   'Rundet ein Zwischenergebnis und rechnet mit dem gerundeten Wert weiter – das Endergebnis weicht deshalb leicht ab.',
   'Gerundet wird erst am Ende. Wer zwischendurch rundet und mit dem '
   'gerundeten Wert weiterrechnet, trägt den kleinen Fehler in jeden weiteren '
   'Schritt. Geübt wird, Zwischenergebnisse genau stehen zu lassen.')
on conflict (slug) do nothing;


commit;
