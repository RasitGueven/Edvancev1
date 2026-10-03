# K9-Rest – Heimat-Thema je neuem Knoten (Vorlage für `skill_thema_nachtrag.sql`)

Für den Lauf `feat/inhalte-themen` (Teil 5: Nachtrag für Knoten aus `feat/k9-rest`). Regel dort:
genau ein Heimat-Thema je Skill = das Thema, in dem der Stoff im Kernlehrplan eingeführt wird.
Alle Themen sind `stufe = 'zweite'`, `klasse = 9`, passend zu `klasse_herkunft = 9`.

| skill_key | label | thema_key | Begründung (nur bei Grenzfällen) |
|---|---|---|---|
| `zahl_wurzel_quadrat` | Quadratwurzel als Umkehrung des Quadrierens | `reelle_zahlen` | |
| `zahl_wurzel_naeherung` | Wurzeln abschätzen und Näherungswerte | `reelle_zahlen` | |
| `zahl_wurzel_irrational` | Rationale und irrationale Zahlen | `reelle_zahlen` | |
| `zahl_wurzel_gesetze` | Wurzelgesetze für Produkt und Quotient | `reelle_zahlen` | |
| `zahl_wurzel_teilweise` | Teilweise die Wurzel ziehen | `reelle_zahlen` | |
| `zahl_potenz_gesetze` | Potenzgesetze | `potenzen` | |
| `zahl_potenz_negativ` | Negative Hochzahlen und Hochzahl null | `potenzen` | |
| `zahl_potenz_zehner` | Zehnerpotenzen und wissenschaftliche Schreibweise | `potenzen` | |
| `zahl_potenz_rechnen` | Rechnen in wissenschaftlicher Schreibweise | `potenzen` | |
| `gleichung_quadr_wurzel` | Quadratische Gleichungen durch Wurzelziehen | `quadratische_gleichungen` | |
| `gleichung_quadr_faktor` | Quadratische Gleichungen durch Ausklammern (Nullprodukt) | `quadratische_gleichungen` | |
| `gleichung_quadr_formel` | Lösungsformel (p-q- bzw. abc-Formel) | `quadratische_gleichungen` | |
| `gleichung_quadr_anzahl` | Anzahl der Lösungen (Diskriminante) | `quadratische_gleichungen` | |
| `fkt_quadr_parabel` | Normalparabel verschieben und strecken | `quadratische_funktionen` | |
| `fkt_quadr_scheitel` | Scheitelpunkt aus der Scheitelpunktform | `quadratische_funktionen` | |
| `fkt_quadr_normalform` | Von der Normalform zur Scheitelpunktform | `quadratische_funktionen` | |
| `fkt_quadr_nullstellen` | Nullstellen quadratischer Funktionen | `quadratische_funktionen` | Grenzfall: rechnet mit der Lösungsformel, ist aber eine Funktionseigenschaft (Fkt-9) |
| `fkt_quadr_extrem` | Extremwertaufgaben mit quadratischen Funktionen | `quadratische_funktionen` | |
| `geo_pythagoras_hypotenuse` | Hypotenuse mit dem Satz des Pythagoras | `pythagoras` | |
| `geo_pythagoras_kathete` | Kathete mit dem Satz des Pythagoras | `pythagoras` | |
| `geo_pythagoras_umkehrung` | Rechtwinklig? Umkehrung des Satzes | `pythagoras` | |
| `geo_pythagoras_abstand` | Abstand zweier Punkte im Koordinatensystem | `pythagoras` | |
| `geo_pythagoras_anwendung` | Pythagoras in Figuren und Körpern | `pythagoras` | |
| `geo_koerper_prisma` | Volumen und Oberfläche des Prismas | `prismen_zylinder` | |
| `geo_koerper_zylinder` | Volumen und Oberfläche des Zylinders | `prismen_zylinder` | |
| `geo_koerper_pyramide` | Volumen und Oberfläche der Pyramide | `koerper_pyramide_kegel_kugel` | |
| `geo_koerper_kegel` | Volumen und Oberfläche des Kegels | `koerper_pyramide_kegel_kugel` | |
| `geo_koerper_kugel` | Volumen und Oberfläche der Kugel | `koerper_pyramide_kegel_kugel` | |
| `stoch_bedingt_vierfeld` | Vierfeldertafel ergänzen | `bedingte_wahrscheinlichkeit` | |
| `stoch_bedingt_wkeit` | Bedingte Wahrscheinlichkeit aus der Vierfeldertafel | `bedingte_wahrscheinlichkeit` | |
| `stoch_bedingt_unabhaengig` | Stochastische Unabhängigkeit prüfen | `bedingte_wahrscheinlichkeit` | |
| `stoch_bedingt_umkehr` | Bedingte Wahrscheinlichkeiten umkehren (Testsituationen) | `bedingte_wahrscheinlichkeit` | |
| `stoch_bedingt_irrefuehrend` | Irreführende Aussagen und Darstellungen erkennen | `statistik_beurteilen` | Grenzfall: abgeschnittene Achsen und absolute statt relative Zahlen sind Kern von „Statistische Erhebungen beurteilen" (Sto-1/2/6, Schlagworte „irreführende diagramme"); die Verwechslung der Bedingung gehört zur bedingten Wahrscheinlichkeit. Einstieg ist der Knoten für keines der beiden Themen. |
| `geo_aehnlich_streckfaktor` | Streckfaktor und zentrische Streckung | `aehnlichkeit` | |
| `geo_aehnlich_flaeche` | Flächen und Volumen bei Ähnlichkeit | `aehnlichkeit` | |
| `geo_aehnlich_strahlen_abschnitt` | Erster Strahlensatz | `aehnlichkeit` | |
| `geo_aehnlich_strahlen_parallel` | Zweiter Strahlensatz | `aehnlichkeit` | |

Die Kreis-Knoten (`geo_kreis_*`, schon in Prod) gehören zu `kreis` und sind nicht Teil dieser Liste.
