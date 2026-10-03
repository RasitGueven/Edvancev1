-- K10-Rest, Thema exp — Substrat: 5 Knoten, 9 Kanten, 6 neue Fehlbilder. KEINE Aufgaben.
-- Erzeugt von tools/k10-rest-substrat.mjs aus docs/k10-rest/graph.json — nicht von Hand editieren.
--
-- Kernlehrplan Mathematik NRW G9, Fkt-10, Fkt-12, Ari-10, Ari-11 (Zweite Stufe): exponentielles Wachstum, f(x) = a·bˣ, Exponentialgleichungen bˣ = c durch Probieren und Logarithmieren.
-- klasse_herkunft = 10: Stoffjahrgang der Zweiten Stufe, in dem das Thema themen.exponentialfunktionen
-- an Koelner Gymnasien ueberwiegend unterrichtet wird (Schulplaene: docs/themen/schulplaene.csv); der Katalog
-- fuehrt das Thema unter klasse 9 (Zweite Stufe 9/10). Eine Bindung an ein Schuljahr ist damit nicht behauptet.
--
-- Einspiel-Reihenfolge: nach allen Migrationen von origin/dev
-- (Knoten der Kanten muessen stehen); vor 20261003121332_aufgaben_k10_exp.sql.
-- Alle Voraussetzungen ausserhalb dieses Laufs stehen in origin/dev UND in Prod (K8-Rest und K9-Rest
-- sind seit #193/#194 eingespielt). Deshalb keine eigene kanten_k10_k9.sql (docs/k10-rest/entscheidungen.md).
--
-- Kein begin/commit: `mig` spielt die Datei mit psql -1 in EINER Transaktion ein. Die
-- Knoten stehen vor den Kanten, weil skill_kante_tiefe die Tiefe beider Seiten schon beim
-- Insert liest. Idempotent: on conflict do nothing.


-- ── 1. Knoten ───────────────────────────────────────────────────────────────
--
-- Tiefe = 1 + tiefste direkte Voraussetzung (Plan: docs/k10-rest/phase1.md, Teil 1b):
--   fkt_exp_wachstum                   10  ueber prozent_zins_zinseszins, fkt_linear_gleichung
--   fkt_exp_term                       11  ueber fkt_exp_wachstum, zahl_potenz_negativ
--   fkt_exp_halbwert                   11  ueber fkt_exp_wachstum
--   fkt_exp_gleichung                  7  ueber zahl_potenz_negativ, runden_ueberschlag
--   fkt_exp_anwendung                  12  ueber fkt_exp_term, fkt_exp_gleichung

insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
values
  ('fkt_exp_wachstum', 'Lineares und exponentielles Wachstum, Wachstumsfaktor', 'mathematik', 10, 10),
  ('fkt_exp_term', 'Exponentialfunktion f(x) = a·bˣ aufstellen und auswerten', 'mathematik', 10, 11),
  ('fkt_exp_halbwert', 'Verdopplungszeit und Halbwertszeit', 'mathematik', 10, 11),
  ('fkt_exp_gleichung', 'Exponentialgleichungen bˣ = c lösen (Probieren, Logarithmus)', 'mathematik', 10, 7),
  ('fkt_exp_anwendung', 'Exponentielle Modelle: Zeitpunkte berechnen', 'mathematik', 10, 12)
on conflict (skill_key) do nothing;


-- ── 2. Kanten ───────────────────────────────────────────────────────────────
--
-- Nur direkte Voraussetzungen; gegen den Graphen in Prod (03.10.2026) geprueft, keine
-- transitiv redundante Kante (tools/k10-rest-graph-check.mjs).

insert into public.skill_kante (skill_key, voraussetzt_skill_key)
values
  -- Der Zinseszins ist der erste exponentielle Vorgang im Lehrgang: Wachstumsfaktor q = 1 +
  -- p/100 und Kₙ = K₀·qⁿ werden hier auf beliebige Zu- und Abnahmen verallgemeinert.
  ('fkt_exp_wachstum', 'prozent_zins_zinseszins'),
  -- Lineares Wachstum ist eine lineare Funktion mit konstanter Zunahme; der Vergleich linear
  -- gegen exponentiell setzt sie voraus. Nicht über den Zinseszins erreichbar.
  ('fkt_exp_wachstum', 'fkt_linear_gleichung'),
  -- a ist der Anfangswert, b der Wachstumsfaktor aus dem Wachstumsvorgang.
  ('fkt_exp_term', 'fkt_exp_wachstum'),
  -- Werte links der y-Achse (f(−2) = a·b⁻²) und das Zurückrechnen brauchen negative Hochzahlen;
  -- nicht über den Wachstumsknoten erreichbar.
  ('fkt_exp_term', 'zahl_potenz_negativ'),
  -- Verdopplungs- und Halbwertszeit beschreiben exponentielle Zu- und Abnahme über feste
  -- Zeitspannen.
  ('fkt_exp_halbwert', 'fkt_exp_wachstum'),
  -- bˣ = c durch Probieren heißt Potenzen mit ganzzahligen, auch negativen Hochzahlen ausrechnen
  -- (2ˣ = 1/8).
  ('fkt_exp_gleichung', 'zahl_potenz_negativ'),
  -- Logarithmus-Lösungen sind meist nicht abbrechend und werden auf vorgegebene Stellen
  -- gerundet; nicht über die Potenzen erreichbar.
  ('fkt_exp_gleichung', 'runden_ueberschlag'),
  -- Aus der Sachsituation wird zuerst f(x) = a·bˣ aufgestellt.
  ('fkt_exp_anwendung', 'fkt_exp_term'),
  -- Der gesuchte Zeitpunkt ist die Lösung von a·bˣ = c (Ari-11); nicht über den Term erreichbar.
  ('fkt_exp_anwendung', 'fkt_exp_gleichung')
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
  ('linear_statt_exponentiell', 'sachaufgaben',
   'Schreibt einen exponentiellen Vorgang linear fort: addiert in jedem Schritt denselben Betrag, statt mit demselben Faktor zu multiplizieren.',
   'Bei exponentiellem Wachstum wird in jedem Schritt mit demselben Faktor multipliziert; die Zunahme wird dadurch immer größer. Hier wurde die erste Zunahme einfach immer wieder addiert, als wäre der Vorgang linear. Bei einer Verdopplung wird so aus 100, 200, 400 die Folge 100, 200, 300. Geübt wird, zuerst zu prüfen, ob sich die Werte um denselben Betrag oder um denselben Faktor ändern.'),

  ('abnahmefaktor_falsch', 'einheiten_massstab',
   'Bildet bei einer prozentualen Abnahme den Faktor falsch: 0,2 oder 1,2 statt 0,8 bei 20 % Abnahme.',
   'Nimmt ein Wert um p % ab, bleiben (100 − p) % übrig. Bei 20 % Abnahme ist der Faktor deshalb 0,8. Wer mit 0,2 rechnet, rechnet mit dem Teil, der verschwindet; wer mit 1,2 rechnet, hat Zunahme und Abnahme verwechselt. Geübt wird, sich vor dem Rechnen zu fragen, wie viel Prozent nach einem Schritt noch da sind.'),

  ('rate_aus_faktor_falsch', 'einheiten_massstab',
   'Liest aus dem Wachstumsfaktor die Rate falsch ab: 1,05 als 105 % Zunahme oder 0,8 als 80 % Abnahme.',
   'Der Wachstumsfaktor enthält den alten Wert (1) und die Änderung. Bei 1,05 kommen 5 % dazu, nicht 105 %; bei 0,8 fallen 20 % weg, nicht 80 %. Die Rückrichtung vom Faktor zum Prozentsatz wird seltener geübt als die Hinrichtung. Geübt wird, zuerst die 1 abzuziehen und den Rest in Prozent zu lesen.'),

  ('zeit_statt_perioden', 'sachaufgaben',
   'Setzt die vergangene Zeit direkt als Hochzahl ein, statt sie durch die Verdopplungs- oder Halbwertszeit zu teilen.',
   'Bei einer Halbwertszeit von 5 Jahren halbiert sich die Menge in 20 Jahren nur viermal, nicht zwanzigmal. Die Hochzahl zählt die Halbierungen, also vergangene Zeit geteilt durch die Halbwertszeit. Geübt wird, vor dem Einsetzen auszurechnen, wie viele Verdopplungen oder Halbierungen in der Zeit stecken.'),

  ('anfangswert_faktor_vertauscht', null,
   'Vertauscht in f(x) = a·bˣ den Anfangswert und den Wachstumsfaktor.',
   'Im Term a·bˣ ist a der Wert zu Beginn (bei x = 0) und b der Faktor, mit dem in jedem Schritt multipliziert wird. Hier stand der Anfangswert in der Basis und der Faktor davor. Geübt wird, zuerst f(0) auszurechnen: Dort muss der Anfangswert herauskommen.'),

  ('log_falsch_geteilt', null,
   'Rechnet bei bˣ = c mit c : b oder log(c : b) statt mit log c : log b.',
   'Die Lösung von bˣ = c ist x = log c : log b. Beim Teilen der Logarithmen wird leicht c durch b geteilt oder der Logarithmus erst nach dem Teilen genommen; das gibt eine ganz andere Zahl. Geübt wird, die Probe zu machen: b hoch Ergebnis muss wieder c ergeben.')
on conflict (slug) do nothing;
