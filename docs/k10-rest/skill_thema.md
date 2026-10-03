# K10-Rest – Heimat-Themen (`skill_thema`)

Stand 03.10.2026. Jeder der 15 neuen Knoten bekommt **genau ein** Heimat-Thema: das Thema, in dem der
Stoff im KLP G9 NRW eingeführt wird. Migration `skill_thema_k10.sql` (Join auf `skills` und `themen`,
`on conflict (skill_key) do nothing`, Muster `20261003113055_skill_thema_nachtrag.sql`).
Prüfung: `supabase/checks/k10_skill_thema.PRUEFUNG.sql`.

| skill_key | Label | Heimat-Thema | KLP | Begründung |
|---|---|---|---|---|
| `fkt_exp_wachstum` | Lineares und exponentielles Wachstum, Wachstumsfaktor | `exponentialfunktionen` | Fkt-10 | Kern des Themas „Exponentielles Wachstum". |
| `fkt_exp_term` | Exponentialfunktion f(x) = a·bˣ aufstellen und auswerten | `exponentialfunktionen` | Fkt-12 | |
| `fkt_exp_halbwert` | Verdopplungszeit und Halbwertszeit | `exponentialfunktionen` | Fkt-10 | |
| `fkt_exp_gleichung` | Exponentialgleichungen bˣ = c lösen (Probieren, Logarithmus) | `exponentialfunktionen` | Ari-10 | Grenzfall: arithmetisch (Tiefe 7), aber der Katalog führt Ari-10 nur bei `exponentialfunktionen`; `potenzen` (Ari-1/3/4/5) kennt keine Exponentialgleichungen. |
| `fkt_exp_anwendung` | Exponentielle Modelle: Zeitpunkte berechnen | `exponentialfunktionen` | Ari-11, Fkt-12 | |
| `geo_trigo_verhaeltnis` | Sinus, Kosinus und Tangens als Seitenverhältnisse | `trigonometrie` | Geo-7 | Nicht `aehnlichkeit`: Die Ähnlichkeit ist Voraussetzung, eingeführt werden sin/cos/tan. |
| `geo_trigo_seite` | Seiten im rechtwinkligen Dreieck berechnen | `trigonometrie` | Geo-9 | |
| `geo_trigo_winkel` | Winkel im rechtwinkligen Dreieck berechnen | `trigonometrie` | Geo-9 | |
| `geo_trigo_anwendung` | Trigonometrie in Sachsituationen | `trigonometrie` | Geo-10 | |
| `geo_trigo_kosinussatz` | Kosinussatz im allgemeinen Dreieck | `trigonometrie` | Geo-8 | Nicht `pythagoras`: Der Kosinussatz verallgemeinert ihn, eingeführt wird er in der Trigonometrie. |
| `fkt_sinus_einheitskreis` | Sinus und Kosinus am Einheitskreis | `sinusfunktion` | Fkt-13 | Grenzfall: Der Katalog führt den Einheitskreis als Schlagwort bei `sinusfunktion`, Fkt-13 ist dort. |
| `fkt_sinus_bogenmass` | Bogenmaß und Gradmaß | `sinusfunktion` | Fkt-13 | Schlagwort „bogenmaß" bei `sinusfunktion`; nicht `kreis` (dort nur Bogenlänge in Grad). |
| `fkt_sinus_graph` | Graph der Sinusfunktion | `sinusfunktion` | Fkt-13 | |
| `fkt_sinus_parameter` | Amplitude und Periode bei a·sin(b·x) | `sinusfunktion` | Fkt-13, Fkt-5 | |
| `fkt_sinus_periodisch` | Periodische Vorgänge mit Sinusfunktionen beschreiben | `sinusfunktion` | Fkt-14 | |

Nach dem Einspielen hat weiterhin nur `potenzen` kein Heimat-Thema (Bestand, `docs/inhalte-themen/befunde.md`).
