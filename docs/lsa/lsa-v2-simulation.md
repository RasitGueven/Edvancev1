# LSA-V2 · Simulation vorher/nachher, Laufzeit, Pool

Stand 22.10.2026. Bauauftrag `docs/lsa/Bauauftrag-LSA-V2.md`, Migration `20261022131358_lsa_v2_ausblick`.

## 1. Testkinder im CI-Neuaufbau

Erzeugt mit `bash tools/lsa-testkinder/simulation.sh`: zwei Wegwerf-DBs aus allen Migrationen, „vorher“ ohne,
„nachher“ mit der Migration, je mit `tools/lsa-testkinder/neuaufbau-fixture.sql` (drei Aufgaben je Skill, alle
ready) und den Profilen aus `kinder.sql` (für beide Läufe dieselben, also schon mit dem erweiterten Profil von
Max und Lina). Ausblick-Knoten zählt die Auswertung in beiden Läufen mit derselben Definition
(`lsa_ausblick_knoten`, für „vorher“ erst nach dem Lauf eingespielt).

Ende: **Zeit** = über 19 Minuten, **leer** = die Auswahl lieferte nichts mehr, **Deckel** = 40 Aufgaben ausgegeben.

### vorher (dev mit LSA-R2, 20261022131037)

| Kind | Kl. | Aufgaben | Dauer | Ende | Ausblick | davon sicher | tiefste Kl. | Zweitbelege |
| --- | ---: | ---: | ---: | --- | ---: | ---: | ---: | ---: |
| Lina | 9 | 18 | 12:22 | leer | 0 | 0 | 5 | 3 |
| Emre | 9 | 19 | 19:21 | Zeit | 0 | 0 | 6 | 6 |
| Sophie | 8 | 14 | 19:20 | Zeit | 0 | 0 | 6 | 6 |
| Jonas | 8 | 16 | 20:21 | Zeit | 0 | 0 | 5 | 8 |
| Nele | 7 | 13 | 15:24 | leer | 0 | 0 | 7 | 6 |
| Max | 8 | 10 | 06:04 | leer | 0 | 0 | 6 | 3 |
| Tim | 8 | 36 | 01:50 | leer | 0 | 0 | 5 | 18 |

### nachher (mit 20261022131358)

| Kind | Kl. | Aufgaben | Dauer | Ende | Ausblick | davon sicher | tiefste Kl. | Zweitbelege |
| --- | ---: | ---: | ---: | --- | ---: | ---: | ---: | ---: |
| Lina | 9 | 27 | 18:20 | leer | 4 | 2 | 5 | 8 |
| Emre | 9 | 19 | 19:21 | Zeit | 3 | 3 | 5 | 4 |
| Sophie | 8 | 14 | 19:20 | Zeit | 0 | 0 | 6 | 5 |
| Jonas | 8 | 14 | 20:56 | Zeit | 0 | 0 | 5 | 4 |
| Nele | 7 | 11 | 13:04 | leer | 0 | 0 | 7 | 4 |
| Max | 8 | 16 | 09:30 | leer | 6 | 4 | 6 | 3 |
| Tim | 8 | 36 | 01:50 | leer | 0 | 0 | 5 | 18 |

Tim läuft in beiden Ständen ohne `hoechstens` (aus kinder.sql entfernt), damit die Auswahl allein sein Ende
bestimmt.

Ausblick in der Reihenfolge der Ausgabe (nachher):

| Kind | Ausblick-Knoten und Urteil |
| --- | --- |
| Lina | geo_kreis_flaeche traegt, geo_kreis_umfang traegt, zahl_potenz_rechnen traegt_nicht, geo_pythagoras_abstand traegt_nicht → Stopp |
| Emre | fkt_quadr_normalform traegt, fkt_quadr_nullstellen traegt, geo_kreis_flaeche traegt → Zeit |
| Max | term_binom_quadrat, term_binom_quadratdifferenz, term_binom_faktorisieren, term_binom_gemischt traegt, stoch_pfad_summe traegt_nicht, geo_flaeche_drachen_raute traegt_nicht → Stopp |

### Gegen die Erwartung aus dem Bauauftrag

| Erwartung | Ergebnis |
| --- | --- |
| Max und Lina deutlich länger, mit Ausblick | ja: Max 10 → 16 Aufgaben, 6:04 → 9:30; Lina 18 → 27, 12:22 → 18:20. Beide mit Ausblick und sichtbarem Stopp. |
| Jonas erreicht Klasse 5/6 | ja, aber auch vorher schon: Im Neuaufbau mit drei Aufgaben je Skill kommt Jonas in beiden Läufen bis Klasse 5. Neu: halb so viele Zweitbelege (8 → 4), weil „Weiß ich nicht“ keinen mehr auslöst. Der Befund aus dem Anlass (Prod-Testpool) lässt sich hier nicht nachstellen, siehe offene Punkte. |
| Emre, Sophie, Nele ändern sich wenig | ja: Sophie gleich, Nele 13 → 11 Aufgaben (weniger Zweitbelege), Emre gleich viele Aufgaben, davon 3 im Ausblick (Emre ist mit 2 Übungsbereichen stark genug). |
| Kein Kind über 40 | ja, höchstens 36 (Tim). |
| Bei Tim greift der Deckel | **nein**: Tim hat ein Thema (Terme und Gleichungen). Mit Thema endet die Auswahl seit LSA-V nach Thema, Vorschau und Rückblick von selbst, hier nach 36 Aufgaben (1:50 Minuten), vorher wie nachher. Der Deckel ist im pgTAP-Test `lsa_v2_ausblick` (Fall e) mit einem Durchklicker ohne Thema belegt: genau 40 Aufgaben, dann null nach knapp 4 Minuten. Siehe offene Punkte. |

Die Folgen hängen über `md5(Sitzung || Aufgabe)` an der zufälligen Sitzungs-ID; zwischen Läufen schwanken Lina
(nachher 16:58–19:04), Max (8:53–11:17) und Nele (12:08–14:21). Die Zusicherungen in `lsa_testkinder.test.sql`
gelten für jeden Lauf.

## 2. Laufzeit „Weiter“ (wie LSA-D)

`tools/lsa-weiter-messung.sql` unverändert, Seed 0.42, je Fassung eine frische Kopie. Gemessen vor dem Rebase auf LSA-R2; R2 ersetzt
`lsa_finish` und `platz_submit`, nicht `lsa_submit`, `lsa_select_next_core` oder `lsa_urteil_buchen_core`. Datenbank: CI-Neuaufbau plus
851 synthetische Aufgaben nach dem Prod-Bestand aus `supabase/tests/lsa_v_daten.sql` (Skill, Sondierrang, MC,
ready/Entwurf; 72 ready, 851 im Testpool; Pool-Prüfung über alle 194 ms, in LSA-V 270 ms). Zeiten in ms, lokal.

Fälle: **schwach** = Kind aus #297 (Klasse 8, Thema Reelle Zahlen, 15 Themen behandelt), 10 % richtig.
**stark** = dasselbe Kind, 95 % richtig. **ohne Thema** = dasselbe Kind, Reelle Zahlen „behandelt“. **wie Max** =
Klasse 8, FWG-Plan, Lineare Funktionen, 3 Themen behandelt, 100 % bzw. 90 % richtig (der Fall mit Ausblick).

| Fall | Pool | Fassung | Abgaben | submit Ø | p90 | max | core Ø | core max | Ausblick |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| schwach | Test | vorher | 21 | 6,8 | 9,1 | 49,1 | 3,1 | 10,8 | – |
| schwach | Test | nachher | 21 | 4,7 | 6,6 | 11,9 | 3,1 | 5,7 | 0 |
| schwach | echt | vorher | 7 | 7,7 | 13,4 | 22,1 | 4,1 | 11,8 | – |
| schwach | echt | nachher | 7 | 5,1 | 7,1 | 10,2 | 2,6 | 5,1 | 0 |
| stark | Test | vorher | 6 | 6,9 | 11,6 | 13,7 | 3,8 | 4,6 | – |
| stark | Test | nachher | 6 | 8,0 | 11,6 | 13,4 | 5,2 | 9,1 | 0 |
| stark | echt | vorher | 3 | 6,2 | 8,6 | 9,4 | 4,5 | 8,4 | – |
| stark | echt | nachher | 3 | 8,2 | 11,8 | 13,3 | 4,3 | 5,8 | 0 |
| ohne Thema | Test | vorher | 111 | 1,9 | 2,8 | 13,7 | 1,0 | 8,4 | – |
| ohne Thema | Test | nachher | **40** | 1,8 | 2,6 | 13,5 | 1,0 | 5,0 | – |
| ohne Thema | echt | vorher | 9 | 5,9 | 9,7 | 23,5 | 2,6 | 11,9 | – |
| ohne Thema | echt | nachher | 8 | 5,6 | 10,2 | 10,3 | 2,4 | 5,5 | – |
| wie Max 100 % | Test | vorher | 8 | 5,8 | 8,1 | 10,8 | 3,5 | 4,8 | – |
| wie Max 100 % | Test | nachher | **21** | 3,7 | 5,6 | 8,9 | 2,9 | 6,4 | 8 |
| wie Max 100 % | echt | vorher | 4 | 4,9 | 6,2 | 6,4 | 2,9 | 4,2 | – |
| wie Max 100 % | echt | nachher | 3 | 5,2 | 6,3 | 6,7 | 4,1 | 5,5 | 0 |
| wie Max 90 % | Test | vorher | 8 | 4,6 | 7,4 | 9,7 | 2,5 | 3,3 | – |
| wie Max 90 % | Test | nachher | **20** | 4,0 | 4,6 | 14,4 | 2,8 | 4,3 | 8 |
| wie Max 90 % | echt | vorher | 4 | 4,6 | 6,4 | 7,1 | 3,1 | 6,0 | – |
| wie Max 90 % | echt | nachher | 5 | 5,0 | 6,9 | 8,4 | 2,6 | 4,2 | 0 |

`lsa_select_next_core` bleibt in jedem Fall unter 20 ms (höchstens 9,1 ms nachher, 11,8 ms vorher). Der
Ausblick kostet je Aufruf einmal `lsa_ausblick_knoten` (Plan, Themenraum, Einstiege); im Fall „wie Max“ mit
8 Ausblick-Knoten liegt der Mittelwert bei 2,9 ms. Der Deckel beendet „ohne Thema, Testpool“ nach 40 statt 111
Abgaben. Einzelne Ausreißer bei submit (vorher bis 49 ms) sind Rauschen der lokalen Maschine; core blieb dabei
klein. Nach dem Faktor 4–6 aus #297 entspricht core max in Prod etwa 25–55 ms je „Weiter“.

## 3. Prod: Aufgaben der Ausblick-Kandidaten (dbread, 22.10.2026)

Ausblick-Kandidaten sind Einstiegsknoten (`thema_einstieg`) kommender Plan-Themen. Gezählt je Einstiegsknoten:
Aufgaben im Pool echter Kinder (`lsa_im_pool(id, false)`, ready) und im Testkonto-Pool (`lsa_im_pool(id, true)`).

Nach Herkunftsklasse des Knotens (alle 45 Einstiegsknoten):

| Klasse | Einstiegsknoten | mit ready | ready-Aufgaben | mit Testpool | Testpool-Aufgaben |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 7 | 2 | 0 | 0 | 2 | 12 |
| 8 | 17 | 0 | 0 | 17 | 102 |
| 9 | 20 | 3 | 18 | 20 | 120 |
| 10 | 6 | 0 | 0 | 6 | 33 |

Nach Klasse im Schulplan (Mathematik, alle 32 Schulen mit Plan; ein Knoten zählt je Planklasse einmal):

| Planklasse | Einstiegsknoten | mit ready | ready-Aufgaben | mit Testpool | Testpool-Aufgaben |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 7 | 13 | 0 | 0 | 13 | 81 |
| 8 | 25 | 3 | 18 | 25 | 150 |
| 9 | 18 | 3 | 18 | 18 | 108 |
| 10 | 15 | 0 | 0 | 15 | 87 |

Ready sind nur die drei Einstiege von Reelle Zahlen (je 6 Aufgaben). Für echte Kinder bleibt der Ausblick
deshalb fast immer leer, bis Lena Einstiege kommender Themen freigibt (offener Punkt 1). Testkonten haben für
jeden Einstiegsknoten Aufgaben.
