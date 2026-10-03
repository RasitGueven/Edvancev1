# Stufen-Prüfung der Skills (W2-7, Teil 1)

Stand: 2026-10-03. `skills` ist lesend aus Prod gezogen (54 Skills, über `dbread`).
Geprüft gegen den Kernlehrplan Mathematik G9 NRW (Heft 3401, 2019).

## Stufen und Kürzel

| klasse_herkunft | Stufe | KLP-Kapitel |
|---|---|---|
| 5, 6 | Erprobungsstufe (E) | 2.3 |
| 7, 8 | Erste Stufe (S1) | 2.4.1 |
| 9, 10 | Zweite Stufe (S2) | 2.4.2 |

**KLP-Kürzel** = Stufe-Inhaltsfeld (Nr. der Kompetenzerwartung), z. B. `E-Fkt (2)`
= Erprobungsstufe, Funktionen, Erwartung (2) „wenden das Dreisatzverfahren … an“.
Inhaltsfelder: `AA` Arithmetik/Algebra, `Fkt` Funktionen, `Geo` Geometrie.
„SP“ heißt: steht nur in den inhaltlichen Schwerpunkten, nicht in einer
nummerierten Erwartung. Die Kürzel im KLP selbst (`Ope-4`, `Mod-3` …) sind
prozessbezogene Kompetenzen und hier nicht gemeint.

## Tabelle

Die Stufe „laut KLP“ bezieht sich auf das, was die Aufgaben mit Status `ready`
tatsächlich verlangen, nicht nur auf das Label.

| skill_key | label | klasse_herkunft heute | Stufe heute | Stufe laut KLP | KLP-Kürzel | Vorschlag |
|---|---|---|---|---|---|---|
| dezimal_add_sub | Dezimalzahlen addieren/subtrahieren | 5 | E | E | E-AA (14) | passt |
| geo_flaeche_rechteck | Fläche von Rechteck und Quadrat | 5 | E | E | E-Geo (12) | passt |
| geo_umfang | Umfang von Rechteck und Dreieck | 5 | E | E | E-Geo (12), (1) | passt – (12) nennt nur Vierecke, der Dreiecksumfang (Seiten addieren) ist aber mit (1) abgedeckt |
| groessen_laengen | Längen umrechnen | 5 | E | E | E-AA (9) | passt |
| groessen_massen | Massen umrechnen | 5 | E | E | E-AA (9) | passt |
| groessen_zeit | Zeitspannen umrechnen | 5 | E | E | E-AA (9) | passt |
| runden_ueberschlag | Runden und Überschlag | 5 | E | E | E-AA (10) | passt |
| bruch_add | Brüche addieren | 6 | E | E | E-AA (14) | passt |
| bruch_dezimal | Bruch in Dezimalzahl | 6 | E | E | E-AA (8) | passt |
| bruch_div | Brüche dividieren | 6 | E | E | E-AA (14) | passt |
| bruch_kuerzen | Brüche kürzen | 6 | E | E | E-AA (12) | passt |
| bruch_mult | Brüche multiplizieren | 6 | E | E | E-AA (14) | passt |
| dezimal_div | Dezimalzahlen dividieren | 6 | E | E | E-AA (14) | passt |
| dezimal_mult | Dezimalzahlen multiplizieren | 6 | E | E | E-AA (14) | passt |
| **geo_flaeche_dreieck** | Fläche von Dreieck und Parallelogramm | 6 | E | **S1** | S1-Geo SP „Höhe und Grundseite“, S1-Geo (8) | **Stufe wechselt: 6 → 7.** E-Geo (12) kennt nur Rechteck und *rechtwinkliges* Dreieck. Die 7 ready-Aufgaben sind allgemeine Dreiecke (4) und Parallelogramme (3) mit Grundseite und Höhe – das ist Erste Stufe. Alternative: Label und Aufgaben auf rechtwinklige Dreiecke einschränken, dann bliebe 6. |
| geo_koordinaten | Punkte im Koordinatensystem | 6 | E | E | E-Geo (6), E-AA (15) | passt |
| geo_massstab | Maßstab | 6 | E | E | E-Fkt (4) | passt |
| geo_volumen_quader | Volumen und Oberfläche des Quaders | 6 | E | E | E-Geo (12) | passt |
| groessen_flaechen | Flächeneinheiten | 6 | E | E | E-AA (9) | passt |
| groessen_gemischt | Gemischte Schreibweise | 6 | E | E | E-AA (8), (9) | passt |
| groessen_volumen | Volumeneinheiten | 6 | E | E | E-AA (9) | passt |
| geo_winkel_summe | Winkelsummen im Dreieck und Viereck | 7 | S1 | S1 | S1-Geo (1), (2) | passt |
| gleichung_beidseitig | Beidseitige Gleichungen | 7 | S1 | S1 | S1-AA (9) | passt |
| gleichung_einschrittig | Einschrittige Gleichungen | 7 | S1 | S1 | S1-AA (9) | passt (E-AA (5) „kehren Rechenanweisungen um“ ist verwandt, aber keine Gleichung mit Variable) |
| gleichung_neg_koeffizient | Gleichungen mit negativem Koeffizienten | 7 | S1 | S1 | S1-AA (9), (3) | passt |
| gleichung_zweischrittig | Zweischrittige Gleichungen | 7 | S1 | S1 | S1-AA (9) | passt |
| potenzen | Potenzen und Quadratzahlen | 7 | S1 | S1 (gemischt) | E-AA (1); S1-AA (3); S2-AA (7), (9) | Stufe bleibt. **Label passt nicht zu den Aufgaben:** die 3 ready-Aufgaben sind √36, √144 (Wurzeln = S2-AA SP) und −2² (Vorzeichen/Vorrang = S1). Die reinen Potenzaufgaben (2⁵, 7² … = E) stehen auf `beanstandet`/`draft`. Vorschlag: Aufgabenauswahl oder Label klären, separat von dieser Migration. |
| **proportionalitaet** | Dreisatz, proportionale Zuordnung | 7 | S1 | **E und S1 gemischt** | E-Fkt (2); S1-Fkt SP „proportionale und antiproportionale Zuordnung … Dreisatz“, S1-Fkt (1) | Stufe bleibt 7, **Label anpassen**. Von 14 ready-Aufgaben sind 7 proportionaler Dreisatz (E-Fkt (2)) und 7 antiproportional („2 Maler … 9 Stunden. Wie lange brauchen 3 Maler?“) – antiproportionale Zuordnung steht erst in der Ersten Stufe. Das Label verschweigt den antiproportionalen Teil. Vorschlag A (empfohlen): Label „Dreisatz, proportional und antiproportional“, Stufe 7. Vorschlag B: Knoten teilen in `dreisatz_proportional` (6) und `dreisatz_antiproportional` (7) – Graph- und Aufgabenarbeit, gehört nicht in diesen Lauf. Vorschlag C: nur proportionale Aufgaben behalten, Stufe 6. |
| prozent_grundwert | Grundwert berechnen | 7 | S1 | S1 | S1-Fkt SP, (8) | passt |
| prozent_prozentsatz | Prozentsatz berechnen | 7 | S1 | S1 | S1-Fkt SP, (8) | passt |
| prozent_prozentwert | Prozentwert berechnen | 7 | S1 | S1 | S1-Fkt SP, (8) | passt |
| prozent_veraenderung | Prozentuale Veränderung | 7 | S1 | S1 | S1-Fkt SP, (9) | passt |
| term_ausklammern | Ausklammern | 7 | S1 | S1 | S1-AA (7) | passt |
| term_ausmultiplizieren | Ausmultiplizieren | 7 | S1 | S1 | S1-AA (7) | passt |
| term_einsetzen | Werte in Terme einsetzen | 7 | S1 | S1 | E-AA (7); S1-AA (3) | passt. E-AA (7) wäre Erprobungsstufe, aber alle Aufgaben setzen negative Zahlen ein (x = −4, −2, −3) – Vorzeichenregeln sind S1. Hinweis: der Skill hat keine ready-Aufgabe (6 draft). |
| term_minusklammer | Minusklammer auflösen | 7 | S1 | S1 | S1-AA (7), (3) | passt |
| term_zusammenfassen | Terme zusammenfassen | 7 | S1 | S1 | S1-AA (7) | passt |
| vorzeichen_add_sub | Negative Zahlen addieren/subtrahieren | 7 | S1 | S1 | S1-AA (3) | passt (E-AA SP nennt nur die *Darstellung* ganzer Zahlen) |
| vorzeichen_mult_div | Negative Zahlen multiplizieren/dividieren | 7 | S1 | S1 | S1-AA (3) | passt |
| vorzeichen_vorrang | Vorrangregeln mit Vorzeichen | 7 | S1 | S1 | S1-AA (3) | passt |
| gleichung_modellieren | Gleichungen aufstellen (Sachkontext) | 8 | S1 | S1 | S1-AA (6) | passt |
| term_binom_faktorisieren | Faktorisieren mit binomischer Formel | 8 | S1 | S1 | S1-AA SP „binomische Formeln“, (7) | passt |
| term_binom_gemischt | Binomische Formeln in Termumformungen | 8 | S1 | S1 | S1-AA SP, (7) | passt |
| term_binom_quadrat | Binomische Formeln (Quadrat einer Summe/Differenz) | 8 | S1 | S1 | S1-AA SP, (7) | passt |
| term_binom_quadratdifferenz | Binomische Formel (Differenz von Quadraten) | 8 | S1 | S1 | S1-AA SP, (7) | passt |

### Nicht angefasst (laufende Themen-Läufe)

Nur der Vollständigkeit halber gegen den KLP gelesen, kein Vorschlag:

| skill_key | klasse_herkunft | Stufe heute | Stufe laut KLP | KLP-Kürzel |
|---|---|---|---|---|
| fkt_linear_gleichung | 8 | S1 | S1 | S1-Fkt SP, (4) |
| fkt_linear_graph | 8 | S1 | S1 | S1-Fkt (4) |
| fkt_linear_nullstelle | 8 | S1 | S1 | S1-Fkt SP „Achsenabschnitte“ |
| fkt_linear_steigung | 8 | S1 | S1 | S1-Fkt SP, (5) |
| fkt_linear_yabschnitt | 8 | S1 | S1 | S1-Fkt SP, (5) |
| prozent_zins_jahreszins | 7 | S1 | S1 | S1-Fkt SP, (8) |
| prozent_zins_rueckrechnung | 7 | S1 | S1 | S1-Fkt (8) |
| prozent_zins_teilzins | 7 | S1 | S1 | S1-Fkt (8) |
| prozent_zins_zinseszins | 7 | S1 | S1 | S1-Fkt SP „Wachstumsfaktor“, (9); S1-AA (8) |

`geo_kreis_*` gibt es in Prod noch nicht.

## Entscheidungen (Rasit, 2026-10-03)

Umgesetzt in `supabase/migrations/20261003092318_skills_stufen_klp.sql`:

1. `geo_flaeche_dreieck`: `klasse_herkunft` 6 → 7. `klasse_herkunft` wird heute in
   keiner SQL-Funktion ausgewertet. Die LSA-Auswahl (feat/lsa-thema-einstieg)
   filtert aber künftig über `klasse_herkunft <= Klasse des Kindes`. Ein Kind der
   Klasse 6 bekommt den Knoten dann nicht mehr. Das ist gewollt.
2. `proportionalitaet`: Variante A. Stufe 7 bleibt, Label wird
   „Dreisatz, proportional und antiproportional“. Sonst nichts an dem Knoten.
3. `term_einsetzen`, `geo_umfang`: bleiben bei der heutigen Stufe.

## Offene Punkte

- **proportionalitaet, Variante B:** Knoten teilen in `dreisatz_proportional`
  (Erprobungsstufe, E-Fkt (2), Klasse 6) und `dreisatz_antiproportional`
  (Erste Stufe, S1-Fkt SP, Klasse 7). Braucht neue Kanten und eine Aufteilung
  der Aufgaben. Gehört in einen eigenen Lauf, nicht in diese Migration.

## Befund für Lena (Item-Pflege, nicht per Migration)

**potenzen** – Stufe bleibt 7.
- Die ready-Aufgaben **√36** und **√144** sind Wurzelaufgaben. Wurzeln stehen im
  KLP in der Zweiten Stufe (S2-AA SP „Wurzeln“, S2-AA (7), (9)) und gehören nicht
  zu `potenzen`. Bitte in der Item-Pflege mit diesem Grund zurückweisen.
- Die echten Potenzaufgaben prüfen: 13 × `beanstandet` (2⁵, 5³, (−3)² …),
  8 × `draft` (2,5², 1,05³, Würfelvolumen …) und die 6 neuen aus dem Zins-Lauf.
  Erst danach hat der Knoten wieder ready-Aufgaben, die zum Label passen.
- −2² (ready) ist eine Vorrang-/Vorzeichenaufgabe (S1-AA (3)). Sie passt zur
  Stufe, prüft aber eher `vorzeichen_vorrang` als Potenzen.
