-- K9-Rest, Thema bedingt — Substrat: 5 Knoten, 7 Kanten, 5 neue Fehlbilder. KEINE Aufgaben.
-- Erzeugt von tools/k9-rest-substrat.mjs aus docs/k9-rest/graph.json — nicht von Hand editieren.
--
-- Kernlehrplan Mathematik NRW G9, Stochastik, Zweite Stufe (Sto-3, Sto-4, Sto-5): Vierfeldertafel, bedingte Wahrscheinlichkeit, Unabhängigkeit, Darstellungen beurteilen.
-- klasse_herkunft = 9 folgt dem KLP (Zweite Stufe) und dem Thema themen.bedingte_wahrscheinlichkeit (Klasse 9);
-- eine Bindung an ein bestimmtes Schuljahr ist damit nicht behauptet.
--
-- Einspiel-Reihenfolge: nach allen Migrationen von origin/dev
-- (Knoten der Kanten muessen stehen); vor 20261003105907_aufgaben_k9_bedingt.sql.
-- Keine Kante auf Knoten des parallelen Laufs feat/k8-rest (LGS, Wahrscheinlichkeit Kl. 8,
-- Flaechen, Winkel): beide Laeufe bleiben unabhaengig einspielbar (Befunde in docs/k9-rest/befunde.md).
--
-- Kein begin/commit: `mig` spielt die Datei mit psql -1 in EINER Transaktion ein. Die
-- Knoten stehen vor den Kanten, weil skill_kante_tiefe die Tiefe beider Seiten schon beim
-- Insert liest. Idempotent: on conflict do nothing.


-- ── 1. Knoten ───────────────────────────────────────────────────────────────
--
-- Tiefe = 1 + tiefste direkte Voraussetzung (Plan: docs/k9-rest/phase1.md, Teil 1b):
--   stoch_bedingt_vierfeld             5  ueber bruch_dezimal
--   stoch_bedingt_wkeit                6  ueber stoch_bedingt_vierfeld
--   stoch_bedingt_unabhaengig          7  ueber stoch_bedingt_wkeit
--   stoch_bedingt_umkehr               7  ueber stoch_bedingt_wkeit, prozent_prozentwert
--   stoch_bedingt_irrefuehrend         8  ueber stoch_bedingt_wkeit, prozent_prozentsatz

insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
values
  ('stoch_bedingt_vierfeld', 'Vierfeldertafel ergänzen', 'mathematik', 9, 5),
  ('stoch_bedingt_wkeit', 'Bedingte Wahrscheinlichkeit aus der Vierfeldertafel', 'mathematik', 9, 6),
  ('stoch_bedingt_unabhaengig', 'Stochastische Unabhängigkeit prüfen', 'mathematik', 9, 7),
  ('stoch_bedingt_umkehr', 'Bedingte Wahrscheinlichkeiten umkehren (Testsituationen)', 'mathematik', 9, 7),
  ('stoch_bedingt_irrefuehrend', 'Irreführende Aussagen und Darstellungen erkennen', 'mathematik', 9, 8)
on conflict (skill_key) do nothing;


-- ── 2. Kanten ───────────────────────────────────────────────────────────────
--
-- Nur direkte Voraussetzungen; gegen den Graphen in Prod (03.10.2026) geprueft, keine
-- transitiv redundante Kante (tools/k9-rest-graph-check.mjs).

insert into public.skill_kante (skill_key, voraussetzt_skill_key)
values
  -- Relative Häufigkeiten als Anteil bzw. Dezimalzahl; Addieren/Subtrahieren über
  -- dezimal_add_sub transitiv.
  ('stoch_bedingt_vierfeld', 'bruch_dezimal'),
  -- P(A|B) wird aus einer vollständigen Tafel gelesen: Zellwert durch Randsumme.
  ('stoch_bedingt_wkeit', 'stoch_bedingt_vierfeld'),
  -- Unabhängig heißt P(A|B) = P(A).
  ('stoch_bedingt_unabhaengig', 'stoch_bedingt_wkeit'),
  -- P(B|A) aus P(A|B) über eine Tafel mit natürlichen Häufigkeiten.
  ('stoch_bedingt_umkehr', 'stoch_bedingt_wkeit'),
  -- Die Tafel wird aus Prozentangaben einer Grundgesamtheit gefüllt; nicht transitiv erreichbar.
  ('stoch_bedingt_umkehr', 'prozent_prozentwert'),
  -- Viele irreführende Aussagen verwechseln P(A|B) mit P(B|A) oder mit P(A und B).
  ('stoch_bedingt_irrefuehrend', 'stoch_bedingt_wkeit'),
  -- Anteile statt absoluter Zahlen vergleichen; Prozentsatz aus Teil und Ganzem.
  ('stoch_bedingt_irrefuehrend', 'prozent_prozentsatz')
on conflict do nothing;


-- ── 3. Fehlbilder ───────────────────────────────────────────────────────────
--
-- Zentral festgelegt in docs/k9-rest/phase1.md (Teil 1d), gegen den Bestand (98 Slugs) und
-- gegen docs/k8-rest/phase1.md geprueft: keiner der Slugs hat dort eine gleichbedeutende
-- Entsprechung. Ein Slug, den mehrere Themen brauchen, steht in jedem dieser Substrate mit
-- wortgleichem Text; on conflict do nothing haelt das idempotent. freigegeben_am bleibt NULL
-- (Entwurf, wird nirgends ausgeliefert, bis Lena abnimmt). Familie nur aus den fuenf
-- vorhandenen, sonst NULL (Muster Kreis).

insert into public.fehlbild_labels (slug, familie, klartext, erklaerung)
values
  ('bedingung_vertauscht', 'sachaufgaben',
   'Verwechselt die Wahrscheinlichkeit von A unter der Bedingung B mit der von B unter der Bedingung A.',
   '„Wie viele der Kranken haben einen positiven Test?“ ist eine andere Frage als „Wie viele der positiv Getesteten sind krank?“. Beide Anteile teilen durch eine andere Gruppe und können sehr verschieden sein. Hier wurde die eine Frage mit der anderen beantwortet. Geübt wird, zuerst zu klären: Von welcher Gruppe ist die Rede? Diese Gruppe steht im Nenner.'),

  ('gesamtheit_statt_bedingung', 'sachaufgaben',
   'Teilt durch die Gesamtzahl statt durch die Größe der Gruppe, auf die sich die Frage bezieht.',
   'Bei einer bedingten Wahrscheinlichkeit zählt nur eine Teilgruppe, zum Beispiel nur die Mädchen. Hier wurde durch alle Befragten geteilt. Das ergibt den Anteil an allen, nicht den Anteil innerhalb der Gruppe. Geübt wird, den Nenner aus der passenden Zeile oder Spalte der Vierfeldertafel zu nehmen.'),

  ('randsumme_verwechselt', 'sachaufgaben',
   'Zieht beim Ergänzen der Vierfeldertafel von der falschen Summe ab (Zeile statt Spalte).',
   'In einer Vierfeldertafel gehört jede Zahl zu einer Zeile und zu einer Spalte. Ein fehlendes Feld ergibt sich aus der Summe seiner eigenen Zeile oder Spalte. Hier wurde von einer Summe abgezogen, zu der das Feld nicht gehört. Geübt wird, beim Ergänzen mit dem Finger Zeile und Spalte des Feldes nachzufahren.'),

  ('achse_abgeschnitten_uebersehen', 'sachaufgaben',
   'Vergleicht Säulenhöhen, ohne zu bemerken, dass die Achse nicht bei null beginnt.',
   'Beginnt die Hochachse eines Diagramms zum Beispiel bei 90 statt bei 0, wirken kleine Unterschiede riesig: Eine Säule kann doppelt so hoch aussehen, obwohl der Wert nur wenig größer ist. Hier wurde das Verhältnis der Säulenhöhen statt das der Werte genommen. Geübt wird, zuerst die Beschriftung der Achse zu lesen.'),

  ('absolut_statt_relativ', 'sachaufgaben',
   'Vergleicht absolute Anzahlen, wo Anteile verglichen werden müssen.',
   'Wenn zwei Gruppen verschieden groß sind, sagt die reine Anzahl wenig: 30 von 200 ist ein kleinerer Anteil als 20 von 80. Hier wurden die Anzahlen verglichen statt der Anteile. Geübt wird, jede Anzahl erst durch die Größe ihrer Gruppe zu teilen.')
on conflict (slug) do nothing;
