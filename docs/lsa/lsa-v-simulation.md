# LSA-V Simulation vorher/nachher

Erzeugt mit tools/lsa-v-simulation.sh am 2026-10-22. Grundlage und Annahmen: Kopf von
supabase/tests/lsa_v_simulation.test.sql. Grund nach Zugehörigkeit des Skills, nicht nach der Phase.

vorher = 20261021083026 (dev), nachher = 20261022065539 (LSA-V mit LSA-D Fix A/B). Minute = Abstand zum Start
der simulierten Sitzung.

Hinweis: Im Lauf „echt, vorher“ kam Nr. 8 (vorzeichen_vorrang) aus Breite b. Der Skill ist zufällig auch
Voraussetzung von Quadratische Funktionen und steht deshalb unter „Vorschau“.

Freigabeliste der Vorschau-Kandidaten: docs/lsa/freigabeliste-vorschau.md.

## Testpool (lsa_testinhalte = true, wie Testkonto B)

### vorher

16 Aufgaben · Themenraum 8 (50 %) · Vorschau 0 (0 %) · Rückblick 8 (50 %) · sonst 0 (0 %) · Themenraum direkt geprüft: 5 von 14

| Nr | Minute | Grund | Skill | Thema des Skills |
|---:|---|---|---|---|
| 1 | 00:00 | Thema | zahl_wurzel_irrational | reelle_zahlen |
| 2 | 01:15 | Thema | zahl_wurzel_irrational | reelle_zahlen |
| 3 | 02:30 | Thema | zahl_wurzel_teilweise | reelle_zahlen |
| 4 | 03:45 | Thema | zahl_wurzel_teilweise | reelle_zahlen |
| 5 | 05:00 | Thema | zahl_wurzel_naeherung | reelle_zahlen |
| 6 | 06:15 | Grundlage | zahl_wurzel_gesetze | reelle_zahlen |
| 7 | 07:30 | Grundlage | zahl_wurzel_gesetze | reelle_zahlen |
| 8 | 08:45 | Grundlage | bruch_dezimal | rechnen_brueche_dezimalzahlen |
| 9 | 10:00 | Rückblick | geo_winkel_thales | thales_konstruktionen |
| 10 | 11:15 | Rückblick | geo_winkel_thales | thales_konstruktionen |
| 11 | 12:30 | Rückblick | gleichung_lgs_addition | lineare_gleichungen_lgs |
| 12 | 13:45 | Rückblick | gleichung_lgs_addition | lineare_gleichungen_lgs |
| 13 | 15:00 | Rückblick | gleichung_lgs_grafisch | lineare_gleichungen_lgs |
| 14 | 16:15 | Rückblick | gleichung_lgs_einsetzen | lineare_gleichungen_lgs |
| 15 | 17:30 | Rückblick | geo_flaeche_term | flaechen_vielecke |
| 16 | 18:45 | Rückblick | geo_flaeche_term | flaechen_vielecke |

### nachher

16 Aufgaben · Themenraum 8 (50 %) · Vorschau 5 (31 %) · Rückblick 3 (19 %) · sonst 0 (0 %) · Themenraum direkt geprüft: 5 von 14

| Nr | Minute | Grund | Skill | Thema des Skills |
|---:|---|---|---|---|
| 1 | 00:00 | Thema | zahl_wurzel_irrational | reelle_zahlen |
| 2 | 01:15 | Thema | zahl_wurzel_irrational | reelle_zahlen |
| 3 | 02:30 | Thema | zahl_wurzel_teilweise | reelle_zahlen |
| 4 | 03:45 | Thema | zahl_wurzel_teilweise | reelle_zahlen |
| 5 | 05:00 | Thema | zahl_wurzel_naeherung | reelle_zahlen |
| 6 | 06:15 | Grundlage | zahl_wurzel_gesetze | reelle_zahlen |
| 7 | 07:30 | Grundlage | zahl_wurzel_gesetze | reelle_zahlen |
| 8 | 08:45 | Grundlage | bruch_dezimal | rechnen_brueche_dezimalzahlen |
| 9 | 10:00 | Vorschau | term_einsetzen | terme_gleichungen |
| 10 | 11:15 | Vorschau | gleichung_modellieren | terme_gleichungen |
| 11 | 12:30 | Vorschau | term_binom_quadrat | terme_binomische_formeln |
| 12 | 13:45 | Vorschau | term_binom_quadrat | terme_binomische_formeln |
| 13 | 15:00 | Vorschau | geo_koordinaten | geometrische_grundbegriffe |
| 14 | 16:15 | Rückblick | geo_winkel_thales | thales_konstruktionen |
| 15 | 17:30 | Rückblick | geo_winkel_thales | thales_konstruktionen |
| 16 | 18:45 | Rückblick | gleichung_lgs_grafisch | lineare_gleichungen_lgs |

## Pool eines echten Kindes (nur status ready)

### vorher

8 Aufgaben · Themenraum 7 (88 %) · Vorschau 1 (12 %) · Rückblick 0 (0 %) · sonst 0 (0 %) · Themenraum direkt geprüft: 4 von 14

| Nr | Minute | Grund | Skill | Thema des Skills |
|---:|---|---|---|---|
| 1 | 00:00 | Thema | zahl_wurzel_irrational | reelle_zahlen |
| 2 | 01:15 | Thema | zahl_wurzel_irrational | reelle_zahlen |
| 3 | 02:30 | Thema | zahl_wurzel_teilweise | reelle_zahlen |
| 4 | 03:45 | Thema | zahl_wurzel_teilweise | reelle_zahlen |
| 5 | 05:00 | Thema | zahl_wurzel_naeherung | reelle_zahlen |
| 6 | 06:15 | Grundlage | zahl_wurzel_gesetze | reelle_zahlen |
| 7 | 07:30 | Grundlage | zahl_wurzel_gesetze | reelle_zahlen |
| 8 | 08:45 | Vorschau | vorzeichen_vorrang | rationale_zahlen |

### nachher

7 Aufgaben · Themenraum 7 (100 %) · Vorschau 0 (0 %) · Rückblick 0 (0 %) · sonst 0 (0 %) · Themenraum direkt geprüft: 4 von 14

| Nr | Minute | Grund | Skill | Thema des Skills |
|---:|---|---|---|---|
| 1 | 00:00 | Thema | zahl_wurzel_irrational | reelle_zahlen |
| 2 | 01:15 | Thema | zahl_wurzel_irrational | reelle_zahlen |
| 3 | 02:30 | Thema | zahl_wurzel_teilweise | reelle_zahlen |
| 4 | 03:45 | Thema | zahl_wurzel_teilweise | reelle_zahlen |
| 5 | 05:00 | Thema | zahl_wurzel_naeherung | reelle_zahlen |
| 6 | 06:15 | Grundlage | zahl_wurzel_gesetze | reelle_zahlen |
| 7 | 07:30 | Grundlage | zahl_wurzel_gesetze | reelle_zahlen |
