# Zuordnung Skill → Heimat-Thema

Stand: 2026-10-03. Skills und Themen lesend aus Prod (`dbread`, 59 Skills, 37 Themen).
Umgesetzt in `supabase/migrations/20261003104647_skill_thema_daten.sql`.

Regel: genau ein Heimat-Thema je Skill = das Thema, in dem der Stoff im KLP G9 NRW
eingeführt wird. Plausibilität: Stufe des Themas passt zu `klasse_herkunft`
(5/6 → Erprobung, 7/8 → Erste, 9/10 → Zweite). **Bei allen 58 Zuordnungen passt sie.**

| skill_key | label | klasse_herkunft | thema_key | Thema-Label | Stufe | Begründung |
|---|---|---|---|---|---|---|
| dezimal_add_sub | Dezimalzahlen addieren/subtrahieren | 5 | rechnen_brueche_dezimalzahlen | Rechnen mit Brüchen und Dezimalzahlen | 5/6 |  |
| geo_flaeche_rechteck | Fläche von Rechteck und Quadrat | 5 | flaeche_umfang | Flächen und Umfang | 5/6 |  |
| geo_umfang | Umfang von Rechteck und Dreieck | 5 | flaeche_umfang | Flächen und Umfang | 5/6 |  |
| groessen_laengen | Längen umrechnen | 5 | natuerliche_zahlen | Natürliche Zahlen und Größen | 5/6 |  |
| groessen_massen | Massen umrechnen | 5 | natuerliche_zahlen | Natürliche Zahlen und Größen | 5/6 |  |
| groessen_zeit | Zeitspannen umrechnen | 5 | natuerliche_zahlen | Natürliche Zahlen und Größen | 5/6 |  |
| runden_ueberschlag | Runden und Überschlag | 5 | natuerliche_zahlen | Natürliche Zahlen und Größen | 5/6 |  |
| bruch_add | Brüche addieren | 6 | rechnen_brueche_dezimalzahlen | Rechnen mit Brüchen und Dezimalzahlen | 5/6 |  |
| bruch_dezimal | Bruch in Dezimalzahl | 6 | rechnen_brueche_dezimalzahlen | Rechnen mit Brüchen und Dezimalzahlen | 5/6 | Schlagworte „brüche in dezimalzahlen“, „brüche in dezimalschreibweise“ stehen bei rechnen_brueche_dezimalzahlen (Ari-8), nicht bei brueche. |
| bruch_div | Brüche dividieren | 6 | rechnen_brueche_dezimalzahlen | Rechnen mit Brüchen und Dezimalzahlen | 5/6 |  |
| bruch_kuerzen | Brüche kürzen | 6 | brueche | Brüche und Anteile | 5/6 | KLP E-AA (12) – kürzen/erweitern gehört zur Einführung der Brüche (Schlagwort „kürzen“), nicht zum Rechnen mit Brüchen. |
| bruch_mult | Brüche multiplizieren | 6 | rechnen_brueche_dezimalzahlen | Rechnen mit Brüchen und Dezimalzahlen | 5/6 |  |
| dezimal_div | Dezimalzahlen dividieren | 6 | rechnen_brueche_dezimalzahlen | Rechnen mit Brüchen und Dezimalzahlen | 5/6 |  |
| dezimal_mult | Dezimalzahlen multiplizieren | 6 | rechnen_brueche_dezimalzahlen | Rechnen mit Brüchen und Dezimalzahlen | 5/6 |  |
| geo_koordinaten | Punkte im Koordinatensystem | 6 | geometrische_grundbegriffe | Geometrische Grundbegriffe und Figuren | 5/6 | KLP E-Geo (6) – Koordinatensystem steht bei geometrische_grundbegriffe (Geo-6). |
| geo_massstab | Maßstab | 6 | ganze_zahlen_groessen | Negative Zahlen, Zuordnungen und Dreisatz | 5/6 | Grenzfall: KLP E-Fkt (4) – steht in ganze_zahlen_groessen (Fkt-4, Schlagwort „maßstab“). flaeche_umfang nennt „maßstab“ ebenfalls als Schlagwort, hat aber keinen Fkt-Bezug; die Aufgaben sind reine Zuordnungsaufgaben (Karte → Wirklichkeit). |
| geo_volumen_quader | Volumen und Oberfläche des Quaders | 6 | koerper_quader | Körper, Netze und Quadervolumen | 5/6 |  |
| groessen_flaechen | Flächeneinheiten | 6 | flaeche_umfang | Flächen und Umfang | 5/6 | Flächeneinheiten werden mit dem Flächeninhalt eingeführt (Schlagwort „flächeneinheiten“), nicht beim allgemeinen Größen-Kapitel. |
| groessen_gemischt | Gemischte Schreibweise | 6 | natuerliche_zahlen | Natürliche Zahlen und Größen | 5/6 | Grenzfall: Kommaschreibweise bei Größen (2,08 kg → g). Eingeführt im Größen-Kapitel Kl. 5 (Schlagworte „einheiten umrechnen“, „rechnen mit größen und einheiten“); KLP E-AA (8), (9). Alternative rechnen_brueche_dezimalzahlen (Ari-8) verworfen: die Aufgaben rechnen nicht mit Dezimalzahlen, sie rechnen Einheiten um. |
| groessen_volumen | Volumeneinheiten | 6 | koerper_quader | Körper, Netze und Quadervolumen | 5/6 | Volumeneinheiten werden mit dem Quadervolumen eingeführt (Schlagworte „rauminhalt“, „liter“, „kubikzentimeter“). |
| geo_flaeche_dreieck | Fläche von Dreieck und Parallelogramm | 7 | flaechen_vielecke | Flächen von Dreiecken und Vierecken | 7/8 | klasse_herkunft seit W2-7 = 7 (allgemeine Dreiecke, S1-Geo (8)) – flaechen_vielecke (Geo-8). |
| geo_winkel_summe | Winkelsummen im Dreieck und Viereck | 7 | winkel_dreiecke | Winkelsätze, Dreiecke und Konstruktionen | 7/8 |  |
| gleichung_beidseitig | Beidseitige Gleichungen | 7 | terme_gleichungen | Terme und Gleichungen | 7/8 |  |
| gleichung_einschrittig | Einschrittige Gleichungen | 7 | terme_gleichungen | Terme und Gleichungen | 7/8 |  |
| gleichung_neg_koeffizient | Gleichungen mit negativem Koeffizienten | 7 | terme_gleichungen | Terme und Gleichungen | 7/8 |  |
| gleichung_zweischrittig | Zweischrittige Gleichungen | 7 | terme_gleichungen | Terme und Gleichungen | 7/8 |  |
| potenzen | Potenzen und Quadratzahlen | 7 | – | – | – | **Ohne Zuordnung.** Kein Potenz-Thema unterhalb der Zweiten Stufe im Katalog; das Thema potenzen (Potenzgesetze, wissenschaftliche Schreibweise, 9/10) ist nicht der Ort, an dem Potenzen/Quadratzahlen eingeführt werden. Aufgaben gemischt (E/S1/S2, siehe stufen-pruefung.md). Befund. |
| proportionalitaet | Dreisatz, proportional und antiproportional | 7 | zuordnungen | Proportionale und antiproportionale Zuordnungen | 7/8 | Label seit W2-7 „proportional und antiproportional“; antiproportional ist Erste Stufe → zuordnungen. Der proportionale Dreisatz allein wäre ganze_zahlen_groessen (E-Fkt (2)); Teilung des Knotens ist offener Punkt aus W2-7. |
| prozent_grundwert | Grundwert berechnen | 7 | zinsrechnung | Prozent- und Zinsrechnung | 7/8 |  |
| prozent_prozentsatz | Prozentsatz berechnen | 7 | zinsrechnung | Prozent- und Zinsrechnung | 7/8 |  |
| prozent_prozentwert | Prozentwert berechnen | 7 | zinsrechnung | Prozent- und Zinsrechnung | 7/8 |  |
| prozent_veraenderung | Prozentuale Veränderung | 7 | zinsrechnung | Prozent- und Zinsrechnung | 7/8 |  |
| prozent_zins_jahreszins | Jahreszinsen berechnen | 7 | zinsrechnung | Prozent- und Zinsrechnung | 7/8 |  |
| prozent_zins_rueckrechnung | Kapital oder Zinssatz aus den Zinsen | 7 | zinsrechnung | Prozent- und Zinsrechnung | 7/8 |  |
| prozent_zins_teilzins | Zinsen für Monate und Tage | 7 | zinsrechnung | Prozent- und Zinsrechnung | 7/8 |  |
| prozent_zins_zinseszins | Zinseszins und Wachstumsfaktor | 7 | zinsrechnung | Prozent- und Zinsrechnung | 7/8 | Wachstumsfaktor (S1-Fkt (9)) – zinsrechnung; exponentialfunktionen (Zweite Stufe) wäre zu spät. |
| term_ausklammern | Ausklammern | 7 | terme_gleichungen | Terme und Gleichungen | 7/8 |  |
| term_ausmultiplizieren | Ausmultiplizieren | 7 | terme_gleichungen | Terme und Gleichungen | 7/8 |  |
| term_einsetzen | Werte in Terme einsetzen | 7 | terme_gleichungen | Terme und Gleichungen | 7/8 | E-AA (7) wäre Erprobung, alle Aufgaben setzen aber negative Zahlen ein (S1, siehe stufen-pruefung.md) → terme_gleichungen. |
| term_minusklammer | Minusklammer auflösen | 7 | terme_gleichungen | Terme und Gleichungen | 7/8 |  |
| term_zusammenfassen | Terme zusammenfassen | 7 | terme_gleichungen | Terme und Gleichungen | 7/8 |  |
| vorzeichen_add_sub | Negative Zahlen addieren/subtrahieren | 7 | rationale_zahlen | Rationale Zahlen | 7/8 | S1-AA (3) – negative Zahlen rechnen ist Erste Stufe (rationale_zahlen); ganze_zahlen_groessen (Kl. 6) kennt nur die Darstellung. |
| vorzeichen_mult_div | Negative Zahlen multiplizieren/dividieren | 7 | rationale_zahlen | Rationale Zahlen | 7/8 |  |
| vorzeichen_vorrang | Vorrangregeln mit Vorzeichen | 7 | rationale_zahlen | Rationale Zahlen | 7/8 |  |
| fkt_linear_gleichung | Funktionsgleichung y = mx + b aufstellen | 8 | lineare_funktionen | Lineare Funktionen | 7/8 |  |
| fkt_linear_graph | Graph einer linearen Funktion | 8 | lineare_funktionen | Lineare Funktionen | 7/8 |  |
| fkt_linear_nullstelle | Nullstelle einer linearen Funktion | 8 | lineare_funktionen | Lineare Funktionen | 7/8 |  |
| fkt_linear_steigung | Steigung einer linearen Funktion | 8 | lineare_funktionen | Lineare Funktionen | 7/8 |  |
| fkt_linear_yabschnitt | y-Achsenabschnitt einer linearen Funktion | 8 | lineare_funktionen | Lineare Funktionen | 7/8 |  |
| gleichung_modellieren | Gleichungen aufstellen (Sachkontext) | 8 | terme_gleichungen | Terme und Gleichungen | 7/8 | Einstiegsknoten von terme_gleichungen (thema_einstieg); „gleichungen aus sachsituationen“. |
| term_binom_faktorisieren | Faktorisieren mit binomischer Formel | 8 | terme_binomische_formeln | Terme mit mehreren Variablen und binomische Formeln | 7/8 |  |
| term_binom_gemischt | Binomische Formeln in Termumformungen | 8 | terme_binomische_formeln | Terme mit mehreren Variablen und binomische Formeln | 7/8 |  |
| term_binom_quadrat | Binomische Formeln (Quadrat einer Summe/Differenz) | 8 | terme_binomische_formeln | Terme mit mehreren Variablen und binomische Formeln | 7/8 |  |
| term_binom_quadratdifferenz | Binomische Formel (Differenz von Quadraten) | 8 | terme_binomische_formeln | Terme mit mehreren Variablen und binomische Formeln | 7/8 |  |
| geo_kreis_flaeche | Flächeninhalt des Kreises | 9 | kreis | Kreis: Umfang und Fläche | 9/10 |  |
| geo_kreis_rueck | Radius und Durchmesser aus dem Umfang | 9 | kreis | Kreis: Umfang und Fläche | 9/10 |  |
| geo_kreis_sektor | Kreisbogen und Kreisausschnitt | 9 | kreis | Kreis: Umfang und Fläche | 9/10 |  |
| geo_kreis_umfang | Umfang des Kreises | 9 | kreis | Kreis: Umfang und Fläche | 9/10 |  |
| geo_kreis_zusammen | Zusammengesetzte Figuren mit Kreisteilen | 9 | kreis | Kreis: Umfang und Fläche | 9/10 |  |

58 von 59 zugeordnet (98 %). Ohne Zuordnung: `potenzen` (siehe befunde.md).
