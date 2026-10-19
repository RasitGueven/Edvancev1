# E7 · Maßblatt zum Eltern-Bericht R7

Stand 18.10.2026. Ausgelesen aus `Edvance_Elternreport_E7.pdf` (Seiten 1, 2, 5 = E6 unverändert, Seiten 3, 4 neu). Gehört nach `docs/report/r7/E7-Masse.md`.

Einheit pt, Ursprung oben links, A4 = 595,28 × 841,89. „y“ heißt in diesem Blatt immer **Grundlinie** der Textzeile, nicht Oberkante. Die Werte gelten für das Muster mit seinen Beispieltexten. R7 baut die Seiten im Fluss (Abstände wie hier), damit längere oder kürzere Texte nach unten schieben statt zu überlappen; fest stehen nur Kopf und Fuß.

Teil 1 fasst die Bauteile zusammen (gerundet). Teil 2 listet jede Textzeile und jede Zeichnung des PDFs, gemessen. **Bei Abweichungen gilt Teil 2.**

---

## Teil 1 · Bauteile

### Farben (werden Tokens `--color-eb-*`, siehe Bauauftrag)

| Token | Wert | Verwendung |
|---|---|---|
| papier | #F8F7F2 | Seitenfläche |
| navy | #304969 | Überschriften, Kicker, Pfad, Knoten, Navy-Kasten |
| tinte | #24313D | Fließtext stark, Listen |
| text | #52616F | Fließtext normal |
| leise | #8795A0 | Fuß, Labels, Zählungen |
| linie | #DEE4E1 | Ränder, Trennlinien |
| linie-zart | #E8EDEB | Zeilentrenner Seite 2 |
| mint | #EAF5F0 | Anliegen-Kasten, Fazit-Kasten, Streifen der Pyramide, Chip Coach-Vorschlag |
| mint-karte | #EFF7F4 | hervorgehobene Mitgliedschaft |
| sicher | #087F70 | Fläche/Punkt „sicher“, Rand der Vorschlagskarte |
| sicher-text | #08665C | Schrift in Sicher-Farbe |
| uebung | #CA8275 | Fläche/Punkt „Übungsbedarf“ |
| uebung-text | #9D5349 | Schrift in Übungs-Farbe |
| offen | #C4D0D4 | Balken über „nicht untersucht“ (Seite 2) |
| schraffur-rand | #CAD7DC | Rand der Segmente „nicht untersucht“ |
| schraffur | #D3DEE1 | Schraffurlinien |
| gold | #E4A132 | Chevron im Logo, Pfeilspitze Seite 4 |
| nav-linie | #B9C5CC | Linien der Mikro-Navigation |
| nav-punkt | #AEBCC4 | Rand der inaktiven Navigationspunkte |
| weg | #B6C6CD | Pfad „Ihr Weg durch diesen Bericht“ |
| weg-ring | #A9BCC7 | Ring der inaktiven Stationen |
| navy-chip | #456281 | Chip im Navy-Kasten Seite 5 |
| auf-navy | #E4ECF0 | Fließtext im Navy-Kasten |
| weiss | #FFFFFF | Karten, Schrift auf Navy |

### Schrift

- **Fraunces**, Gewicht 500, `font-variation-settings: 'opsz' 48` (SOFT und WONK 0): Wortmarke, Seitentitel, große Zahlen, Paketnamen, Name des Ansprechpartners, Titel im Navy-Kasten.
- **Schibsted Grotesk** 400: alles andere.
- Am ganzen Bogen: `font-kerning: none; font-feature-settings: 'kern' 0; font-synthesis: none` (das Muster ist ohne Unterschneidung gesetzt, sonst brechen Zeilen anders um).
- Kicker (Abschnittsmarken): 8,3 pt navy, Versalien per CSS, Sperrung 0,95 pt.

### Alle Seiten · Kopf und Fuß (fest, absolut)

- Chevron: Polylinie (44,37) → (50,31) → (62,42), gold, 2,2 pt, Enden gerade, Ecke spitz.
- Wortmarke „edvance“: Fraunces 17,4 navy, x 70, y 43,4.
- Chip TESTDATEN (nur bei Testlauf): (381,30), 82 × 21, Radius 10,5, weiß, Rand linie 0,8; Text 8,4 pt leise, Versalien, x 394, y 43,4.
- Mikro-Navigation: fünf Punkte r 3,4 bei x 484 / 497 / 510 / 523 / 536, y 39, Rand 0,9; aktuelle Seite navy gefüllt mit navy Rand, sonst weiß mit Rand nav-punkt; dazwischen Linien nav-linie 0,85.
- Linie oben y 78 (x 44–551, linie 0,85), Linie unten y 810 (linie 0,8).
- Fuß: 8,1 pt leise, y 828,1. Links ab x 44 „edvance␣␣·␣␣Köln␣␣·␣␣Lernstandsanalyse {Name}“ (je zwei Leerzeichen um die Punkte, `white-space: pre`). Rechts „n / 5“, rechtsbündig bis 551.

### Seite 1 · Überblick

- Kicker y 111,3. Überschrift Fraunces navy ab y ≈ 160,7; im Muster drei Zeilen mit 27,7 / 25,7 / 24,4 pt (Grundlinien 160,7 / 193,7 / 224,4). **R7:** eine Größe 26 pt, Zeilenabstand 32 pt, höchstens drei Zeilen, `text-wrap: balance`, Breite 507.
- Kopfdaten-Kasten (44,250)–(551,304), weiß, Radius 12, Rand linie 0,75; senkrechte Trenner bei x 174,8 / 301,5 / 428,2 (y 263–289, linie 0,7). Je Spalte Label 7,6 pt leise (y 266,6) und Wert 9,15 pt tinte (y 284,1); Spaltenanfang x 60 / 186,8 / 313,5 / 440,2.
- Kicker „Auf einen Blick“ y 331,3; Zeile 8,7 pt text, y 349,7, Trennpunkte mit je zwei Leerzeichen.
- Drei Karten nebeneinander: x 44–206,3 / 216,3–378,7 / 388,7–551, y 366–517, weiß, Radius 11, Rand linie 0,7, oben ein 3 pt hoher Streifen (sicher / uebung / navy) in der Kartenbreite.
  - Kopf 7,15 pt Versalien in sicher-text / uebung-text / navy, y 387,1, x Karte + 12.
  - Einträge 7,75 pt tinte, y 413,7 + n · 23, Text ab x Karte + 23; Punkt Ø 5,4 (sicher bzw. uebung) bei x Karte + 12,3, mittig zur Zeile.
  - „+n weitere“ 8,1 pt in sicher-text bzw. uebung-text, y 508,1, x Karte + 13.
  - Erster Ansatz: Kreis Ø 24 navy bei (400,7–424,7 × 403–427), „1“ 10 pt weiß mittig; Titel 9,1 pt tinte ab x 432,7, y 410,1, Zeilenabstand 12,3; Text 8,2 pt text ab x 401,7, y 466,2, Zeilenabstand 11,1, Breite ≈ 137.
- Zwei Kästen nebeneinander, y 533–656, gleich hoch, wachsen gemeinsam: links (44–291,5) mint ohne Rand, rechts (303,5–551) weiß mit Rand linie 0,7, beide Radius 11.
  - Kicker y 553,3 bei x 57 bzw. 316,5.
  - Links: Anliegen-Satz 9,4 pt tinte (y 572,4), Thema-Satz 8,45 pt tinte (y 605,5), Rückbezüge 7,5 pt text (y 631,5, Zeilenabstand 10,2), Breite ≈ 222.
  - Rechts: Text 8,45 pt tinte (y 571,4, Zeilenabstand 11,8), Hinweis 7,6 pt text (y 628,6, Zeilenabstand 10,5), Breite ≈ 222.
- Weg durch den Bericht: Kicker y 693,3.
  - Pfad `M 69,720 C 117.3,720 135.7,712 184,712 C 232.3,712 250.7,723 299,723 C 347.3,723 365.7,713 414,713 C 454.7,713 470.3,720 511,720`, weg, 1,2 pt.
  - Stationen r 11,4 bei (69,720) (184,712) (299,723) (414,713) (511,720), Rand 1,0. Station 1: navy gefüllt, „01“ 8,4 pt weiß. Übrige: papier gefüllt, Ring weg-ring, „02“–„05“ 8,4 pt navy.
  - Beschriftung 8,4 pt mittig unter der Station, y = Stationsmitte + 26,4 (Muster: 746,4 / 738,4 / 749,4 / 739,4 / 746,4); Station 1 navy, übrige text.
  - „Sie sind hier“ 7 pt sicher, Versalien, x 44, y 754.

### Seite 2 · Lernstand

- Kicker y 112,3. Titel Fraunces 26,8 navy, y 154,8 / 184,8 (Zeilenabstand 30). Intro 8,9 pt text, y 207,9, Breite 507.
- Drei Zahlen in Spalten ab x 44 / 218 / 392: oben Balken 158 × 2,6 (y 236, Radius 1,3) in sicher / uebung / offen; Zahl Fraunces 32,6 in sicher / uebung-text / tinte (y 277,6); Label 8,4 pt text (y 294,4).
- Profil-Karte (44,323)–(551,663), weiß, Radius 16, Rand linie 0,9.
  - Titel 11,8 pt navy, x 64, y 352,8. Hinweis 7,8 pt leise, rechtsbündig bis 531, y 350,8. Linie y 376 (x 64–531, linie 0,65).
  - Zeilen im Abstand 40,8 (Oberkante der ersten Spur 387). Label 9,1 pt tinte, x 64, y = Spur-Oberkante + 9,1.
  - Spur x 229–455 (226 pt), Höhe 13,5. Ein Segment je Kompetenz, Lücke 4, Radius 3,5. Reihenfolge: sicher, Übungsbedarf, nicht untersucht.
  - „Nicht untersucht“: weiß, Rand schraffur-rand 0,7, Schraffur schraffur 1,3 pt unter 45° im Abstand 7 pt, auf das Segment beschnitten.
  - Rechts, rechtsbündig bis 532: „x von y untersucht“ 7,5 pt text (y = Oberkante + 5,5), darunter „s sicher · u Übungsbedarf“ 7,05 pt leise (y = Oberkante + 20).
  - Trennlinie zwischen den Zeilen bei Oberkante + 31,8 (x 64–531, linie-zart 0,55).
  - Legende: Quadrate 10 × 10, Radius 2,6, bei x 65 / 123,9 / 211,8, y 640–650; Text 8,1 pt text, y 646,1, bei x 81 / 139,9 / 227,8.
- „Was die Grafik zeigt“: Kicker x 44, y 688,3. Text 8,7 pt tinte, x 193, Breite 358, Zeilenabstand 12,3, erste Zeile y 687,7. Fußnote 7,35 pt text, x 193, Breite 358, Zeilenabstand 10, y 752,3.

### Seite 3 · Einordnung (neu)

- Kicker y 111,3. Titel Fraunces 26,1 navy, y 155,1. Intro 9 pt text, Zeilenabstand 13,5, Breite 507, erste Zeile y 183,9.
- Zwischenzeile „Wo die untersuchten Bereiche im Lernstoff liegen“ 11 pt tinte, y 234,9. Legende auf derselben Grundlinie (y 237), rechtsbündig bis 551: Quadrate 10 × 10, Radius 2,6, Abstand Quadrat–Wort 6, zwischen den Paaren 19; Wörter 8,1 pt text.
- Pyramide ab y 250, Spalte zentriert auf 507, Abstand der Stufen 8. Breiten von unten nach oben 507 / 451 / 395 (je Stufe darüber 56 schmaler).
  - Stufe: weiß, Rand linie 0,6, Radius 11, Innenabstand oben 10 / rechts 13 / unten 11,5 / links 14,2, links ein 3,2 pt breiter Streifen mint über die volle Höhe.
  - Kopfzeile auf einer Grundlinie: Titel 10,1 pt navy (Zeilenhöhe 12,5); Klassen 8 pt leise, 7 pt Abstand; Zählung 7,4 pt leise, rechtsbündig.
  - Gruppen: nebeneinander (flex, Abstand 10, `flex: 1 1 auto`), 7,5 unter der Kopfzeile. Gruppenname 6,6 pt leise, Versalien, Sperrung 0,55, Zeilenhöhe 8, 3,6 Abstand nach unten.
  - Einträge 7,8 pt tinte, Zeilenhöhe 10, 2,6 Abstand zwischen Einträgen, `text-wrap: balance`, Einzug 11; Punkt Ø 6,6 (sicher / uebung) bei Einzug 0, 3,7 unter der Zeilenoberkante.
- Lesehilfe 34 unter der Pyramide: links Kicker „So lesen Sie die Pyramide“ (Spalte 149, Zeilenhöhe 12,3), rechts Spalte 358 ab x 193.
  - Je Stufe eine Zeile: Mini-Pyramide 16 × 11 (Balken 8,4 / 12,2 / 16 breit, 2,9 hoch, Radius 0,9, 3,9 Zeilenabstand; der Balken der eigenen Stufe navy, die anderen linie), 8 Abstand, Text 8,7 pt tinte (Zeilenhöhe 12,3), Stufenname davor in navy mit Doppelpunkt; 5,5 zwischen den Zeilen.
  - Text „gilt nur für …“ 8,7 pt tinte, 9 darunter. Hinweis 7,35 pt text, Zeilenhöhe 10, 13 darunter.

### Seite 4 · Lernplan (neu)

- Kicker „Unser Fazit“ y 111,3. Fazit-Kasten (44,132)–(551,246) mint, Radius 13, ohne Rand; Text 11 pt tinte, Zeilenabstand 16,1, x 64, Breite 467, erste Zeile y 160,9.
- Titel Fraunces 18,1 navy, y 296,1. Hinweis 8,75 pt text, Zeilenabstand 12,7, Breite 507, y 318,6.
- Schwerpunkte: Titel 11,4 pt tinte, x 93, y 380,2 (Muster: Abstand 79,5 zwischen den Titeln); Text 9,15 pt text, Zeilenabstand 13,2, Breite 458, erste Zeile 19,7 unter dem Titel. Trennlinie zwischen zwei Schwerpunkten (x 94–551, linie 0,6) bei max(Titel-Grundlinie + 55,8; letzte Textzeile + 22,8); der nächste Titel steht 23,8 unter der Trennlinie. So entsteht bei ein- und zweizeiligen Texten genau der Abstand des Musters, längere Texte schieben nach unten.
- Knoten: Kreis r 6, weiß, Rand navy 1,3, Mitte x 61, y = Grundlinie des Titels − 3,4.
- Kurve (SVG, Linienstärke navy 1,4, Enden und Ecken rund) durch die Knotenmitten. Zwischen Knoten i und i+1 (Höhe h = y₁ − y₀, s = +1 für i = 0, 2 …, −1 für i = 1, 3 …):
  `C (61 + s·12, y₀ + 0,25h) (61 + s·12, y₀ + 0,75h) (61, y₁)`.
- Auslauf in das Lernziel (nur wenn es ein Lernziel gibt): Ziel (84,5 | yk) mit yk = Mitte der Kicker-Zeile im Lernziel-Kasten (Kasten-Oberkante + 16,3); H = yk − y_letzter Knoten;
  `C (61 − 15, y_letzter + 0,55H) (59, yk + 7) (84,5, yk)`.
  Pfeilspitze gold 1,9 pt, Enden rund: zwei Arme der Länge 7,2 unter ±0,6 rad um die Endrichtung (Richtung = vom zweiten Kontrollpunkt (59, yk + 7) zum Ziel).
- Lernziel-Kasten x 93–551, im Muster y 695–772, weiß, Radius 11, Rand linie 0,8; Kicker x Kasten + 16, y Kasten + 19,2; Text 9,1 pt text, Zeilenabstand 13, Breite 426, erste Zeile y Kasten + 39,8.
- Fußnote 7,8 pt leise, x 93, y Kasten-Unterkante + 16,8.

### Seite 5 · Nächste Schritte

- Kicker y 112,3. Titel Fraunces 27 navy, y 156,0. Intro 9,6 pt text, Zeilenabstand 14, Breite 507, y 187,6.
- Navy-Kasten (44,236)–(551,363), Radius 13.
  - Chip (62,252)–(227,1,269,3), Radius 8,7, navy-chip; Text 7,3 pt weiß, Versalien, x 72, y 263,3.
  - Titel Fraunces weiß, x 62, y 302,0 / 324,6 (im Muster 18 / 17,6 pt). **R7:** 17,8 pt einheitlich, Zeilenabstand 22,6.
  - Zeile 8,65 pt auf-navy, x 63, y 346,6, Breite 469.
- Kicker „Unsere Mitgliedschaften“ y 402,3.
  - Karten 161 × 152 bei x 44 / 217 / 390, y 422–574, weiß, Radius 12, Rand linie 0,75. Innen x Karte + 13.
  - Kopf 7,1 pt leise Versalien, y 445,1. Vorschlagskarte: Fläche mint-karte, Rand sicher 1,05; statt des Kopfs ein Chip (Karte + 13, 432)–(+100, 447), Radius 7,5, mint, Text 7 pt sicher-text, Versalien, y 442.
  - Name Fraunces 17 navy, y 482,0. Linie y 499 (Karte + 13 bis Karte − 13, linie 0,7).
  - Merkmal 1 8,5 pt tinte (y 516,5), Merkmal 2 8,5 pt text (y 536,5), „Konditionen im Gespräch“ 7,4 pt leise (y 561,4).
- Hinweis 8,5 pt text, x 44, y 598,5.
- Kontakt-Kasten (44,636)–(551,768), weiß, Radius 12, Rand linie 0,8; senkrechte Linie x 307,6 (y 654–751, linie 0,75).
  - Links ab x 60: Kicker y 661,3; Name Fraunces 16 navy, y 694,0; Rolle 8,5 pt text, y 714,5; Mail 9,25 pt sicher-text, y 738,2.
  - Rechts ab x 323,6: Kicker y 661,3; Text 9,2 pt text, Zeilenabstand 13,7, Breite 200, y 689,2.

---

## Teil 2 · Alle Textzeilen und Zeichnungen

Text: x = linke Kante, rechts = rechte Kante der Zeile, y = Grundlinie. Zeichnung: Rechteck (x₀, y₀)–(x₁, y₁); „rund“ = abgerundete Ecken, „Pfad“ = Kurve oder Kreis aus Bézierkurven. Kopf und Fuß sind nur bei Seite 1 aufgeführt.

### Seite 1

#### Text

| y (Grundlinie) | x | rechts | Größe | Schrift | Farbe | Text |
|---:|---:|---:|---:|---|---|---|
| 43.4 | 70.0 | 135.6 | 17.40 | Fraunces | #304969 | edvance |
| 43.4 | 394.0 | 443.1 | 8.40 | Schibsted | #8795A0 | TESTDATEN |
| 111.3 | 44.0 | 218.9 | 8.30 | Schibsted | #304969 | LERNSTANDSANALYSE MATHEMATIK |
| 160.7 | 44.0 | 385.9 | 27.70 | Fraunces | #304969 | Ilkay zeigt sichere Ansätze. |
| 193.7 | 44.0 | 378.3 | 25.70 | Fraunces | #304969 | Bei einigen weiterführenden |
| 224.4 | 44.0 | 497.2 | 24.40 | Fraunces | #304969 | Rechenschritten braucht er noch Übung. |
| 266.6 | 60.0 | 83.3 | 7.60 | Schibsted | #8795A0 | Klasse |
| 266.6 | 186.8 | 203.7 | 7.60 | Schibsted | #8795A0 | Fach |
| 266.6 | 313.5 | 340.7 | 7.60 | Schibsted | #8795A0 | Umfang |
| 266.6 | 440.2 | 463.4 | 7.60 | Schibsted | #8795A0 | Datum |
| 284.1 | 60.0 | 123.6 | 9.15 | Schibsted | #24313D | 10, Gymnasium |
| 284.1 | 186.8 | 236.7 | 9.15 | Schibsted | #24313D | Mathematik |
| 284.1 | 313.5 | 367.3 | 9.15 | Schibsted | #24313D | 43 Aufgaben |
| 284.1 | 440.2 | 526.7 | 9.15 | Schibsted | #24313D | 20. September 2026 |
| 331.3 | 44.0 | 126.4 | 8.30 | Schibsted | #304969 | AUF EINEN BLICK |
| 349.7 | 44.0 | 380.1 | 8.70 | Schibsted | #52616F | 25 von 41 Bereichen untersucht  ·  9 sicher  ·  16 Übungsbedarf  ·  16 nicht untersucht |
| 387.1 | 56.0 | 134.2 | 7.15 | Schibsted | #08665C | DAS KLAPPTE BEREITS |
| 387.1 | 228.3 | 339.8 | 7.15 | Schibsted | #9D5349 | HIER BRAUCHT ES NOCH ÜBUNG |
| 387.1 | 400.7 | 482.3 | 7.15 | Schibsted | #304969 | UNSER ERSTER ANSATZ |
| 410.1 | 432.7 | 538.5 | 9.10 | Schibsted | #24313D | Flächen- und Raummaße |
| 413.7 | 67.0 | 119.4 | 7.75 | Schibsted | #24313D | Brüche kürzen |
| 413.7 | 239.3 | 298.8 | 7.75 | Schibsted | #24313D | Brüche addieren |
| 418.0 | 411.0 | 414.4 | 10.00 | Schibsted | #FFFFFF | 1 |
| 422.4 | 432.7 | 480.7 | 9.10 | Schibsted | #24313D | umrechnen |
| 436.7 | 67.0 | 141.9 | 7.75 | Schibsted | #24313D | Bruch in Dezimalzahl |
| 436.7 | 239.3 | 315.6 | 7.75 | Schibsted | #24313D | Brüche multiplizieren |
| 459.7 | 67.0 | 152.1 | 7.75 | Schibsted | #24313D | Prozentwert berechnen |
| 459.7 | 239.3 | 302.6 | 7.75 | Schibsted | #24313D | Brüche dividieren |
| 466.2 | 401.7 | 515.8 | 8.20 | Schibsted | #52616F | Dort liegen Sicheres und noch |
| 477.3 | 401.7 | 530.1 | 8.20 | Schibsted | #52616F | Unsicheres direkt nebeneinander. |
| 482.7 | 67.0 | 188.5 | 7.75 | Schibsted | #24313D | Gleichungen mit negativen Zahlen |
| 482.7 | 239.3 | 318.7 | 7.75 | Schibsted | #24313D | Grundwert berechnen |
| 488.4 | 401.7 | 528.9 | 8.20 | Schibsted | #52616F | Wir beginnen bei dem, was schon |
| 499.5 | 401.7 | 427.6 | 8.20 | Schibsted | #52616F | klappt. |
| 508.1 | 57.0 | 97.4 | 8.10 | Schibsted | #08665C | +5 weitere |
| 508.1 | 229.3 | 272.4 | 8.10 | Schibsted | #9D5349 | +12 weitere |
| 553.3 | 57.0 | 124.8 | 8.30 | Schibsted | #304969 | IHR ANLIEGEN |
| 553.3 | 316.5 | 433.1 | 8.30 | Schibsted | #304969 | SO HABEN WIR GEPRÜFT |
| 571.4 | 316.5 | 525.2 | 8.45 | Schibsted | #24313D | Je nach Antwort hat das System die nächste Aufgabe |
| 572.4 | 57.0 | 272.3 | 9.40 | Schibsted | #24313D | Sie machen sich Sorgen um Ilkays Konzentration. |
| 583.2 | 316.5 | 527.2 | 8.45 | Schibsted | #24313D | gewählt. So wurden 25 von 41 Bereichen des Katalogs |
| 595.0 | 316.5 | 413.0 | 8.45 | Schibsted | #24313D | für Klasse 10 untersucht. |
| 605.5 | 57.0 | 259.0 | 8.45 | Schibsted | #24313D | Als nächstes Thema steht Algebra & Funktionen an. |
| 628.6 | 316.5 | 534.0 | 7.60 | Schibsted | #52616F | Über die 16 nicht untersuchten Bereiche enthält dieser Bericht |
| 631.5 | 57.0 | 269.6 | 7.50 | Schibsted | #52616F | Zur Konzentration sagt eine Analyse dieser Länge nichts. Das |
| 639.1 | 316.5 | 450.3 | 7.60 | Schibsted | #52616F | keine Aussage. Mehr dazu auf Seite 2. |
| 641.7 | 57.0 | 193.0 | 7.50 | Schibsted | #52616F | zeigt sich erst über mehrere Sitzungen. |
| 693.3 | 44.0 | 204.4 | 8.30 | Schibsted | #304969 | IHR WEG DURCH DIESEN BERICHT |
| 714.2 | 179.0 | 189.0 | 8.40 | Schibsted | #304969 | 02 |
| 715.2 | 409.0 | 419.0 | 8.40 | Schibsted | #304969 | 04 |
| 722.2 | 65.0 | 73.0 | 8.40 | Schibsted | #FFFFFF | 01 |
| 722.2 | 506.0 | 516.0 | 8.40 | Schibsted | #304969 | 05 |
| 725.2 | 294.0 | 304.0 | 8.40 | Schibsted | #304969 | 03 |
| 738.4 | 164.4 | 203.6 | 8.40 | Schibsted | #52616F | Lernstand |
| 739.4 | 396.8 | 431.1 | 8.40 | Schibsted | #52616F | Lernplan |
| 746.4 | 50.4 | 87.6 | 8.40 | Schibsted | #304969 | Überblick |
| 746.4 | 478.6 | 543.4 | 8.40 | Schibsted | #52616F | Nächste Schritte |
| 749.4 | 276.8 | 321.2 | 8.40 | Schibsted | #52616F | Einordnung |
| 754.0 | 44.0 | 91.2 | 7.00 | Schibsted | #087F70 | SIE SIND HIER |
| 828.1 | 44.0 | 205.6 | 8.10 | Schibsted | #8795A0 | edvance  ·  Köln  ·  Lernstandsanalyse Ilkay |
| 828.1 | 535.8 | 551.0 | 8.10 | Schibsted | #8795A0 | 1 / 5 |

#### Zeichnung

| x₀ | y₀ | x₁ | y₁ | Form | Füllung | Kontur | Strich |
|---:|---:|---:|---:|---|---|---|---:|
| 44.0 | 31.0 | 62.0 | 42.0 | Linie | – | #E4A132 | 2.20 |
| 381.0 | 30.0 | 463.0 | 51.0 | rund | #FFFFFF | #DEE4E1 | 0.80 |
| 484.0 | 39.0 | 497.0 | 39.0 | Linie | – | #B9C5CC | 0.85 |
| 480.6 | 35.6 | 487.4 | 42.4 | Kreis | #304969 | #304969 | 0.90 |
| 497.0 | 39.0 | 510.0 | 39.0 | Linie | – | #B9C5CC | 0.85 |
| 493.6 | 35.6 | 500.4 | 42.4 | Kreis | #FFFFFF | #AEBCC4 | 0.90 |
| 510.0 | 39.0 | 523.0 | 39.0 | Linie | – | #B9C5CC | 0.85 |
| 506.6 | 35.6 | 513.4 | 42.4 | Kreis | #FFFFFF | #AEBCC4 | 0.90 |
| 523.0 | 39.0 | 536.0 | 39.0 | Linie | – | #B9C5CC | 0.85 |
| 519.6 | 35.6 | 526.4 | 42.4 | Kreis | #FFFFFF | #AEBCC4 | 0.90 |
| 532.6 | 35.6 | 539.4 | 42.4 | Kreis | #FFFFFF | #AEBCC4 | 0.90 |
| 44.0 | 78.0 | 551.0 | 78.0 | Linie | – | #DEE4E1 | 0.85 |
| 44.0 | 810.0 | 551.0 | 810.0 | Linie | – | #DEE4E1 | 0.80 |
| 44.0 | 250.0 | 551.0 | 304.0 | rund | #FFFFFF | #DEE4E1 | 0.75 |
| 174.8 | 263.0 | 174.8 | 289.0 | Linie | – | #DEE4E1 | 0.70 |
| 301.5 | 263.0 | 301.5 | 289.0 | Linie | – | #DEE4E1 | 0.70 |
| 428.2 | 263.0 | 428.2 | 289.0 | Linie | – | #DEE4E1 | 0.70 |
| 44.0 | 366.0 | 206.3 | 517.0 | rund | #FFFFFF | #DEE4E1 | 0.70 |
| 44.0 | 366.0 | 206.3 | 369.0 | rund | #087F70 | – | 0.00 |
| 216.3 | 366.0 | 378.7 | 517.0 | rund | #FFFFFF | #DEE4E1 | 0.70 |
| 216.3 | 366.0 | 378.7 | 369.0 | rund | #CA8275 | – | 0.00 |
| 388.7 | 366.0 | 551.0 | 517.0 | rund | #FFFFFF | #DEE4E1 | 0.70 |
| 388.7 | 366.0 | 551.0 | 369.0 | rund | #304969 | – | 0.00 |
| 56.3 | 410.3 | 61.7 | 415.7 | Kreis | #087F70 | – | 0.00 |
| 56.3 | 433.3 | 61.7 | 438.7 | Kreis | #087F70 | – | 0.00 |
| 56.3 | 456.3 | 61.7 | 461.7 | Kreis | #087F70 | – | 0.00 |
| 56.3 | 479.3 | 61.7 | 484.7 | Kreis | #087F70 | – | 0.00 |
| 228.6 | 410.3 | 234.0 | 415.7 | Kreis | #CA8275 | – | 0.00 |
| 228.6 | 433.3 | 234.0 | 438.7 | Kreis | #CA8275 | – | 0.00 |
| 228.6 | 456.3 | 234.0 | 461.7 | Kreis | #CA8275 | – | 0.00 |
| 228.6 | 479.3 | 234.0 | 484.7 | Kreis | #CA8275 | – | 0.00 |
| 400.7 | 403.0 | 424.7 | 427.0 | Kreis | #304969 | – | 0.00 |
| 44.0 | 533.0 | 291.5 | 656.0 | rund | #EAF5F0 | – | 0.00 |
| 303.5 | 533.0 | 551.0 | 656.0 | rund | #FFFFFF | #DEE4E1 | 0.70 |
| 69.0 | 712.0 | 511.0 | 723.0 | Pfad | – | #B6C6CD | 1.20 |
| 57.6 | 708.6 | 80.4 | 731.4 | Kreis | #304969 | #304969 | 1.00 |
| 172.6 | 700.6 | 195.4 | 723.4 | Kreis | #F8F7F2 | #A9BCC7 | 1.00 |
| 287.6 | 711.6 | 310.4 | 734.4 | Kreis | #F8F7F2 | #A9BCC7 | 1.00 |
| 402.6 | 701.6 | 425.4 | 724.4 | Kreis | #F8F7F2 | #A9BCC7 | 1.00 |
| 499.6 | 708.6 | 522.4 | 731.4 | Kreis | #F8F7F2 | #A9BCC7 | 1.00 |

### Seite 2

#### Text

| y (Grundlinie) | x | rechts | Größe | Schrift | Farbe | Text |
|---:|---:|---:|---:|---|---|---|
| 112.3 | 44.0 | 172.2 | 8.30 | Schibsted | #304969 | LERNSTAND IM ÜBERBLICK |
| 154.8 | 44.0 | 332.0 | 26.80 | Fraunces | #304969 | Ilkays Lernstand in den |
| 184.8 | 44.0 | 345.7 | 26.80 | Fraunces | #304969 | untersuchten Bereichen. |
| 207.9 | 44.0 | 545.1 | 8.90 | Schibsted | #52616F | Untersucht: 25 von 41 Bereichen des Katalogs. Davon 9 sicher, 16 mit Übungsbedarf. 16 Bereiche wurden nicht untersucht. |
| 277.6 | 44.0 | 63.6 | 32.60 | Fraunces | #087F70 | 9 |
| 277.6 | 218.0 | 251.8 | 32.60 | Fraunces | #9D5349 | 16 |
| 277.6 | 392.0 | 425.8 | 32.60 | Fraunces | #24313D | 16 |
| 294.4 | 44.0 | 109.0 | 8.40 | Schibsted | #52616F | sicher eingestuft |
| 294.4 | 218.0 | 272.9 | 8.40 | Schibsted | #52616F | Übungsbedarf |
| 294.4 | 392.0 | 455.5 | 8.40 | Schibsted | #52616F | nicht untersucht |
| 350.8 | 382.2 | 531.0 | 7.80 | Schibsted | #8795A0 | Jedes Segment steht für eine Kompetenz |
| 352.8 | 64.0 | 190.9 | 11.80 | Schibsted | #304969 | Ilkays Kompetenzprofil |
| 392.5 | 466.9 | 532.0 | 7.50 | Schibsted | #52616F | 5 von 8 untersucht |
| 396.1 | 64.0 | 166.4 | 9.10 | Schibsted | #24313D | Brüche & Dezimalzahlen |
| 407.0 | 448.6 | 532.0 | 7.05 | Schibsted | #8795A0 | 2 sicher · 3 Übungsbedarf |
| 433.3 | 466.9 | 532.0 | 7.50 | Schibsted | #52616F | 4 von 5 untersucht |
| 436.9 | 64.0 | 137.5 | 9.10 | Schibsted | #24313D | Prozent & Anteile |
| 447.8 | 450.2 | 532.0 | 7.05 | Schibsted | #8795A0 | 1 sicher · 3 Übungsbedarf |
| 474.1 | 466.9 | 532.0 | 7.50 | Schibsted | #52616F | 2 von 5 untersucht |
| 477.7 | 64.0 | 116.6 | 9.10 | Schibsted | #24313D | Gleichungen |
| 488.6 | 506.1 | 532.0 | 7.05 | Schibsted | #8795A0 | 2 sicher |
| 514.9 | 467.0 | 532.0 | 7.50 | Schibsted | #52616F | 2 von 8 untersucht |
| 518.5 | 64.0 | 91.9 | 9.10 | Schibsted | #24313D | Terme |
| 529.4 | 480.1 | 532.0 | 7.05 | Schibsted | #8795A0 | 2 Übungsbedarf |
| 555.7 | 463.6 | 532.0 | 7.50 | Schibsted | #52616F | 11 von 12 untersucht |
| 559.3 | 64.0 | 150.9 | 9.10 | Schibsted | #24313D | Geometrie & Größen |
| 570.2 | 448.8 | 532.0 | 7.05 | Schibsted | #8795A0 | 4 sicher · 7 Übungsbedarf |
| 596.5 | 468.7 | 532.0 | 7.50 | Schibsted | #52616F | 1 von 3 untersucht |
| 600.1 | 64.0 | 111.9 | 9.10 | Schibsted | #24313D | Vorzeichen |
| 611.0 | 481.7 | 532.0 | 7.05 | Schibsted | #8795A0 | 1 Übungsbedarf |
| 646.1 | 81.0 | 104.9 | 8.10 | Schibsted | #52616F | Sicher |
| 646.1 | 139.9 | 192.8 | 8.10 | Schibsted | #52616F | Übungsbedarf |
| 646.1 | 227.8 | 290.3 | 8.10 | Schibsted | #52616F | Nicht untersucht |
| 687.7 | 193.0 | 524.1 | 8.70 | Schibsted | #24313D | In den geprüften Aufgaben gelangen Ilkay die Gleichungen und die grundlegenden |
| 688.3 | 44.0 | 154.7 | 8.30 | Schibsted | #304969 | WAS DIE GRAFIK ZEIGT |
| 700.0 | 193.0 | 531.4 | 8.70 | Schibsted | #24313D | Umrechnungen. Unsicher wurde es dort, wo eine bekannte Rechnung in eine andere |
| 712.3 | 193.0 | 517.6 | 8.70 | Schibsted | #24313D | Richtung oder mit einem anderen Faktor geführt werden musste. Ob dahinter ein |
| 724.6 | 193.0 | 466.2 | 8.70 | Schibsted | #24313D | gemeinsames Muster liegt, prüft der Coach in den ersten Sitzungen. |
| 752.3 | 193.0 | 543.6 | 7.35 | Schibsted | #52616F | Die Streifen zeigen die Verteilung der Katalogbereiche, keine Note und keinen Prozentwert. Ein Bereich |
| 762.3 | 193.0 | 515.2 | 7.35 | Schibsted | #52616F | gilt als sicher, wenn die geprüften Aufgaben dazu gelangen; die Bewertungsregel ist noch nicht |
| 772.3 | 193.0 | 547.7 | 7.35 | Schibsted | #52616F | abschließend festgelegt. Schraffierte Bereiche wurden nicht untersucht und sagen nichts über Ilkay aus. |

#### Zeichnung

| x₀ | y₀ | x₁ | y₁ | Form | Füllung | Kontur | Strich |
|---:|---:|---:|---:|---|---|---|---:|
| 44.0 | 236.0 | 202.0 | 238.6 | rund | #087F70 | – | 0.00 |
| 218.0 | 236.0 | 376.0 | 238.6 | rund | #CA8275 | – | 0.00 |
| 392.0 | 236.0 | 550.0 | 238.6 | rund | #C4D0D4 | – | 0.00 |
| 44.0 | 323.0 | 551.0 | 663.0 | rund | #FFFFFF | #DEE4E1 | 0.90 |
| 64.0 | 376.0 | 531.0 | 376.0 | Linie | – | #DEE4E1 | 0.65 |
| 229.0 | 387.0 | 253.8 | 400.5 | rund | #087F70 | – | 0.00 |
| 257.8 | 387.0 | 282.5 | 400.5 | rund | #087F70 | – | 0.00 |
| 286.5 | 387.0 | 311.2 | 400.5 | rund | #CA8275 | – | 0.00 |
| 315.2 | 387.0 | 340.0 | 400.5 | rund | #CA8275 | – | 0.00 |
| 344.0 | 387.0 | 368.8 | 400.5 | rund | #CA8275 | – | 0.00 |
| 372.8 | 387.0 | 397.5 | 400.5 | rund | #FFFFFF | #CAD7DC | 0.70 |
| 401.5 | 387.0 | 426.2 | 400.5 | rund | #FFFFFF | #CAD7DC | 0.70 |
| 430.2 | 387.0 | 455.0 | 400.5 | rund | #FFFFFF | #CAD7DC | 0.70 |
| 64.0 | 418.8 | 531.0 | 418.8 | Linie | – | #E8EDEB | 0.55 |
| 229.0 | 427.8 | 271.0 | 441.3 | rund | #087F70 | – | 0.00 |
| 275.0 | 427.8 | 317.0 | 441.3 | rund | #CA8275 | – | 0.00 |
| 321.0 | 427.8 | 363.0 | 441.3 | rund | #CA8275 | – | 0.00 |
| 367.0 | 427.8 | 409.0 | 441.3 | rund | #CA8275 | – | 0.00 |
| 413.0 | 427.8 | 455.0 | 441.3 | rund | #FFFFFF | #CAD7DC | 0.70 |
| 64.0 | 459.6 | 531.0 | 459.6 | Linie | – | #E8EDEB | 0.55 |
| 229.0 | 468.6 | 271.0 | 482.1 | rund | #087F70 | – | 0.00 |
| 275.0 | 468.6 | 317.0 | 482.1 | rund | #087F70 | – | 0.00 |
| 321.0 | 468.6 | 363.0 | 482.1 | rund | #FFFFFF | #CAD7DC | 0.70 |
| 367.0 | 468.6 | 409.0 | 482.1 | rund | #FFFFFF | #CAD7DC | 0.70 |
| 413.0 | 468.6 | 455.0 | 482.1 | rund | #FFFFFF | #CAD7DC | 0.70 |
| 64.0 | 500.4 | 531.0 | 500.4 | Linie | – | #E8EDEB | 0.55 |
| 229.0 | 509.4 | 253.8 | 522.9 | rund | #CA8275 | – | 0.00 |
| 257.8 | 509.4 | 282.5 | 522.9 | rund | #CA8275 | – | 0.00 |
| 286.5 | 509.4 | 311.2 | 522.9 | rund | #FFFFFF | #CAD7DC | 0.70 |
| 315.2 | 509.4 | 340.0 | 522.9 | rund | #FFFFFF | #CAD7DC | 0.70 |
| 344.0 | 509.4 | 368.8 | 522.9 | rund | #FFFFFF | #CAD7DC | 0.70 |
| 372.8 | 509.4 | 397.5 | 522.9 | rund | #FFFFFF | #CAD7DC | 0.70 |
| 401.5 | 509.4 | 426.2 | 522.9 | rund | #FFFFFF | #CAD7DC | 0.70 |
| 430.2 | 509.4 | 455.0 | 522.9 | rund | #FFFFFF | #CAD7DC | 0.70 |
| 64.0 | 541.2 | 531.0 | 541.2 | Linie | – | #E8EDEB | 0.55 |
| 229.0 | 550.2 | 244.2 | 563.7 | rund | #087F70 | – | 0.00 |
| 248.2 | 550.2 | 263.3 | 563.7 | rund | #087F70 | – | 0.00 |
| 267.3 | 550.2 | 282.5 | 563.7 | rund | #087F70 | – | 0.00 |
| 286.5 | 550.2 | 301.7 | 563.7 | rund | #087F70 | – | 0.00 |
| 305.7 | 550.2 | 320.8 | 563.7 | rund | #CA8275 | – | 0.00 |
| 324.8 | 550.2 | 340.0 | 563.7 | rund | #CA8275 | – | 0.00 |
| 344.0 | 550.2 | 359.2 | 563.7 | rund | #CA8275 | – | 0.00 |
| 363.2 | 550.2 | 378.3 | 563.7 | rund | #CA8275 | – | 0.00 |
| 382.3 | 550.2 | 397.5 | 563.7 | rund | #CA8275 | – | 0.00 |
| 401.5 | 550.2 | 416.7 | 563.7 | rund | #CA8275 | – | 0.00 |
| 420.7 | 550.2 | 435.8 | 563.7 | rund | #CA8275 | – | 0.00 |
| 439.8 | 550.2 | 455.0 | 563.7 | rund | #FFFFFF | #CAD7DC | 0.70 |
| 64.0 | 582.0 | 531.0 | 582.0 | Linie | – | #E8EDEB | 0.55 |
| 229.0 | 591.0 | 301.7 | 604.5 | rund | #CA8275 | – | 0.00 |
| 305.7 | 591.0 | 378.3 | 604.5 | rund | #FFFFFF | #CAD7DC | 0.70 |
| 382.3 | 591.0 | 455.0 | 604.5 | rund | #FFFFFF | #CAD7DC | 0.70 |
| 65.0 | 640.0 | 75.0 | 650.0 | rund | #087F70 | – | 0.00 |
| 123.9 | 640.0 | 133.9 | 650.0 | rund | #CA8275 | – | 0.00 |
| 211.8 | 640.0 | 221.8 | 650.0 | rund | #FFFFFF | #BAC7CC | 0.70 |
| 211.8 | 640.0 | 217.8 | 649.0 | Linie | – | #D2DDE0 | 1.30 |
| 215.8 | 640.0 | 221.8 | 649.0 | Linie | – | #D2DDE0 | 1.30 |
| 219.8 | 640.0 | 221.8 | 649.0 | Linie | – | #D2DDE0 | 1.30 |

Dazu 149 Schraffurlinien #D3DEE1, 1,3 pt, unter 45°, im Abstand von 7 pt, auf die Segmente „nicht untersucht“ beschnitten.

### Seite 3

#### Text

| y (Grundlinie) | x | rechts | Größe | Schrift | Farbe | Text |
|---:|---:|---:|---:|---|---|---|
| 111.2 | 44.0 | 180.9 | 8.30 | Schibsted | #304969 | EINORDNUNG IM LERNSTOFF |
| 155.1 | 44.0 | 477.0 | 26.10 | Fraunces | #304969 | Auf vorhandenen Stärken aufbauen. |
| 183.9 | 44.0 | 529.6 | 9.00 | Schibsted | #52616F | Jeder untersuchte Bereich steht dort, wo er im Lernstoff liegt: unten die Grundlagen, darüber die Themen, die darauf |
| 197.4 | 44.0 | 388.8 | 9.00 | Schibsted | #52616F | aufbauen, oben der aktuelle Stoff. So sehen Sie, wo es gut läuft und wo noch nicht. |
| 234.9 | 44.0 | 295.9 | 11.00 | Schibsted | #24313D | Wo die untersuchten Bereiche im Lernstoff liegen |
| 237.0 | 440.0 | 463.1 | 8.10 | Schibsted | #52616F | sicher |
| 237.0 | 498.1 | 551.0 | 8.10 | Schibsted | #52616F | Übungsbedarf |
| 270.4 | 114.8 | 234.1 | 10.10 | Schibsted | #304969 | Aktueller Unterrichtsstoff |
| 270.4 | 241.1 | 275.3 | 8.00 | Schibsted | #8795A0 | Klasse 10 |
| 270.4 | 393.9 | 481.5 | 7.40 | Schibsted | #8795A0 | 2 sicher · 4 Übungsbedarf |
| 286.7 | 114.8 | 187.2 | 6.60 | Schibsted | #8795A0 | BRÜCHE & PROZENT |
| 286.7 | 288.4 | 374.6 | 6.60 | Schibsted | #8795A0 | TERME & GLEICHUNGEN |
| 299.8 | 125.8 | 205.6 | 7.80 | Schibsted | #24313D | Grundwert berechnen |
| 299.8 | 299.4 | 421.7 | 7.80 | Schibsted | #24313D | Gleichungen mit negativen Zahlen |
| 312.4 | 125.8 | 209.7 | 7.80 | Schibsted | #24313D | Prozentsatz berechnen |
| 312.4 | 299.4 | 382.1 | 7.80 | Schibsted | #24313D | Gleichungen aufstellen |
| 325.1 | 125.8 | 218.6 | 7.80 | Schibsted | #24313D | Prozentuale Veränderung |
| 325.1 | 299.4 | 349.7 | 7.80 | Schibsted | #24313D | Ausklammern |
| 367.7 | 86.8 | 201.3 | 10.10 | Schibsted | #304969 | Weiterführende Themen |
| 367.7 | 208.3 | 273.9 | 8.00 | Schibsted | #8795A0 | darauf aufbauend |
| 367.7 | 422.3 | 509.5 | 7.40 | Schibsted | #8795A0 | 2 sicher · 7 Übungsbedarf |
| 384.2 | 86.8 | 159.2 | 6.60 | Schibsted | #8795A0 | BRÜCHE & PROZENT |
| 384.2 | 193.4 | 265.9 | 6.60 | Schibsted | #8795A0 | ZAHLEN & GRÖSSEN |
| 384.2 | 280.1 | 322.3 | 6.60 | Schibsted | #8795A0 | GEOMETRIE |
| 384.2 | 408.2 | 494.4 | 6.60 | Schibsted | #8795A0 | TERME & GLEICHUNGEN |
| 397.3 | 97.8 | 173.1 | 7.80 | Schibsted | #24313D | Bruch in Dezimalzahl |
| 397.3 | 204.4 | 266.2 | 7.80 | Schibsted | #24313D | Flächeneinheiten |
| 397.3 | 291.1 | 345.0 | 7.80 | Schibsted | #24313D | Fläche Dreieck |
| 397.3 | 419.2 | 471.5 | 7.80 | Schibsted | #24313D | Vorrangregeln |
| 407.2 | 291.1 | 363.9 | 7.80 | Schibsted | #24313D | und Parallelogramm |
| 407.2 | 419.2 | 473.6 | 7.80 | Schibsted | #24313D | mit Vorzeichen |
| 409.9 | 97.8 | 183.4 | 7.80 | Schibsted | #24313D | Prozentwert berechnen |
| 409.9 | 204.4 | 270.1 | 7.80 | Schibsted | #24313D | Volumeneinheiten |
| 419.8 | 291.1 | 339.0 | 7.80 | Schibsted | #24313D | Volumen und |
| 419.8 | 419.2 | 505.8 | 7.80 | Schibsted | #24313D | Minusklammer auflösen |
| 422.4 | 204.4 | 235.7 | 7.80 | Schibsted | #24313D | Maßstab |
| 429.9 | 291.1 | 360.4 | 7.80 | Schibsted | #24313D | Oberfläche Quader |
| 472.5 | 58.8 | 113.2 | 10.10 | Schibsted | #304969 | Grundlagen |
| 472.5 | 120.2 | 202.4 | 8.00 | Schibsted | #8795A0 | frühere Klassenstufen |
| 472.5 | 449.9 | 537.5 | 7.40 | Schibsted | #8795A0 | 5 sicher · 5 Übungsbedarf |
| 489.0 | 58.8 | 131.2 | 6.60 | Schibsted | #8795A0 | BRÜCHE & PROZENT |
| 489.0 | 207.7 | 280.1 | 6.60 | Schibsted | #8795A0 | ZAHLEN & GRÖSSEN |
| 489.0 | 365.9 | 408.2 | 6.60 | Schibsted | #8795A0 | GEOMETRIE |
| 502.1 | 69.8 | 122.5 | 7.80 | Schibsted | #24313D | Brüche kürzen |
| 502.1 | 218.7 | 304.7 | 7.80 | Schibsted | #24313D | Runden und Überschlag |
| 502.1 | 376.9 | 483.8 | 7.80 | Schibsted | #24313D | Fläche Rechteck und Quadrat |
| 514.7 | 69.8 | 129.6 | 7.80 | Schibsted | #24313D | Brüche addieren |
| 514.7 | 218.7 | 288.3 | 7.80 | Schibsted | #24313D | Längen umrechnen |
| 514.7 | 376.9 | 486.3 | 7.80 | Schibsted | #24313D | Umfang Rechteck und Dreieck |
| 527.2 | 69.8 | 146.5 | 7.80 | Schibsted | #24313D | Brüche multiplizieren |
| 527.2 | 218.7 | 289.9 | 7.80 | Schibsted | #24313D | Massen umrechnen |
| 527.2 | 376.9 | 432.6 | 7.80 | Schibsted | #24313D | Winkelsummen |
| 539.8 | 69.8 | 133.4 | 7.80 | Schibsted | #24313D | Brüche dividieren |
| 597.4 | 217.0 | 509.5 | 8.70 | Schibsted | #24313D/#304969 | Aktueller Unterrichtsstoff: was in Klasse 10 gerade im Unterricht dran ist. |
| 600.0 | 44.0 | 180.6 | 8.30 | Schibsted | #304969 | SO LESEN SIE DIE PYRAMIDE |
| 615.2 | 217.0 | 547.1 | 8.70 | Schibsted | #24313D/#304969 | Weiterführende Themen: Themen, die auf den Grundlagen aufbauen, zum Beispiel |
| 627.6 | 217.0 | 464.9 | 8.70 | Schibsted | #24313D | Flächen- und Volumeneinheiten oder Brüche als Dezimalzahl. |
| 645.4 | 217.0 | 541.8 | 8.70 | Schibsted | #24313D/#304969 | Grundlagen: Stoff aus früheren Klassenstufen, zum Beispiel Bruchrechnung oder |
| 657.6 | 217.0 | 382.7 | 8.70 | Schibsted | #24313D | das Umrechnen von Längen und Massen. |
| 678.9 | 193.0 | 532.5 | 8.70 | Schibsted | #24313D | Die Pyramide gilt nur für Ilkay. Welche Themen oben stehen und welche Grundlagen |
| 691.3 | 193.0 | 530.9 | 8.70 | Schibsted | #24313D | darunter liegen, richtet sich nach seiner Klasse und dem Lehrplan seiner Schule. Bei |
| 703.5 | 193.0 | 358.2 | 8.70 | Schibsted | #24313D | einem anderen Kind sieht sie anders aus. |
| 727.1 | 193.0 | 528.3 | 7.35 | Schibsted | #52616F | Die Pyramide zeigt, wo ein Bereich im Lernstoff liegt, keine feste Voraussetzung. Ob Übungsbedarf |
| 737.1 | 193.0 | 431.1 | 7.35 | Schibsted | #52616F | weiter unten etwas weiter oben erklärt, prüft der Coach im Unterricht. |

#### Zeichnung

| x₀ | y₀ | x₁ | y₁ | Form | Füllung | Kontur | Strich |
|---:|---:|---:|---:|---|---|---|---:|
| 424.0 | 228.9 | 434.1 | 238.9 | rund | #087F70 | – | 0.00 |
| 482.1 | 228.9 | 492.0 | 238.9 | rund | #CA8275 | – | 0.00 |
| 196.7 | 589.1 | 205.1 | 592.0 | rund | #304969 | – | 0.00 |
| 194.8 | 593.0 | 207.0 | 595.9 | rund | #DEE4E1 | – | 0.00 |
| 192.9 | 596.9 | 208.9 | 599.8 | rund | #DEE4E1 | – | 0.00 |
| 196.7 | 606.8 | 205.1 | 609.6 | rund | #DEE4E1 | – | 0.00 |
| 194.8 | 610.6 | 207.0 | 613.5 | rund | #304969 | – | 0.00 |
| 192.9 | 614.5 | 208.9 | 617.4 | rund | #DEE4E1 | – | 0.00 |
| 196.7 | 636.9 | 205.1 | 639.8 | rund | #DEE4E1 | – | 0.00 |
| 194.8 | 640.8 | 207.0 | 643.7 | rund | #DEE4E1 | – | 0.00 |
| 192.9 | 644.7 | 208.9 | 647.6 | rund | #304969 | – | 0.00 |
| 100.2 | 250.2 | 494.7 | 339.1 | rund | #FFFFFF | #DEE4E1 | 0.56 |
| 100.5 | 250.5 | 103.7 | 338.8 | Rechteck | #EAF5F0 | – | 0.00 |
| 114.8 | 295.9 | 121.3 | 302.4 | Pfad | #CA8275 | – | 0.00 |
| 114.8 | 308.4 | 121.3 | 315.0 | Pfad | #CA8275 | – | 0.00 |
| 114.8 | 321.0 | 121.3 | 327.6 | Pfad | #CA8275 | – | 0.00 |
| 288.4 | 295.9 | 294.9 | 302.4 | Pfad | #087F70 | – | 0.00 |
| 288.4 | 308.4 | 294.9 | 315.0 | Pfad | #087F70 | – | 0.00 |
| 288.4 | 321.0 | 294.9 | 327.6 | Pfad | #CA8275 | – | 0.00 |
| 72.3 | 347.7 | 522.7 | 443.9 | rund | #FFFFFF | #DEE4E1 | 0.56 |
| 72.6 | 348.0 | 75.8 | 443.6 | Rechteck | #EAF5F0 | – | 0.00 |
| 86.8 | 393.2 | 93.4 | 399.9 | rund | #087F70 | – | 0.00 |
| 86.8 | 405.9 | 93.4 | 412.5 | Pfad | #087F70 | – | 0.00 |
| 193.5 | 393.2 | 200.1 | 399.9 | rund | #CA8275 | – | 0.00 |
| 193.5 | 405.9 | 200.1 | 412.5 | Pfad | #CA8275 | – | 0.00 |
| 193.5 | 418.5 | 200.1 | 425.1 | Pfad | #CA8275 | – | 0.00 |
| 280.1 | 393.2 | 286.7 | 399.9 | rund | #CA8275 | – | 0.00 |
| 280.1 | 415.9 | 286.7 | 422.4 | Pfad | #CA8275 | – | 0.00 |
| 408.2 | 393.2 | 414.8 | 399.9 | rund | #CA8275 | – | 0.00 |
| 408.2 | 415.9 | 414.8 | 422.4 | Pfad | #CA8275 | – | 0.00 |
| 44.3 | 452.5 | 550.8 | 554.0 | rund | #FFFFFF | #DEE4E1 | 0.56 |
| 44.6 | 452.8 | 47.8 | 553.7 | Rechteck | #EAF5F0 | – | 0.00 |
| 58.7 | 498.0 | 65.4 | 504.8 | rund | #087F70 | – | 0.00 |
| 58.7 | 510.8 | 65.4 | 517.3 | rund | #CA8275 | – | 0.00 |
| 58.7 | 523.3 | 65.4 | 529.9 | rund | #CA8275 | – | 0.00 |
| 58.7 | 535.9 | 65.4 | 542.4 | rund | #CA8275 | – | 0.00 |
| 207.8 | 498.0 | 214.3 | 504.8 | rund | #087F70 | – | 0.00 |
| 207.8 | 510.8 | 214.3 | 517.3 | Pfad | #087F70 | – | 0.00 |
| 207.8 | 523.3 | 214.3 | 529.9 | Pfad | #087F70 | – | 0.00 |
| 366.0 | 498.0 | 372.6 | 504.8 | rund | #087F70 | – | 0.00 |
| 366.0 | 510.8 | 372.6 | 517.3 | Pfad | #CA8275 | – | 0.00 |
| 366.0 | 523.3 | 372.6 | 529.9 | Pfad | #CA8275 | – | 0.00 |

### Seite 4

#### Text

| y (Grundlinie) | x | rechts | Größe | Schrift | Farbe | Text |
|---:|---:|---:|---:|---|---|---|
| 111.2 | 44.0 | 106.1 | 8.30 | Schibsted | #304969 | UNSER FAZIT |
| 160.9 | 64.0 | 482.7 | 11.00 | Schibsted | #24313D | In den geprüften Aufgaben gelangen Ilkay die Gleichungen und die grundlegenden |
| 177.0 | 64.0 | 491.9 | 11.00 | Schibsted | #24313D | Umrechnungen. Unsicher wurde es dort, wo eine bekannte Rechnung in eine andere |
| 192.9 | 64.0 | 474.4 | 11.00 | Schibsted | #24313D | Richtung oder mit einem anderen Faktor geführt werden musste. Ob dahinter ein |
| 209.1 | 64.0 | 409.4 | 11.00 | Schibsted | #24313D | gemeinsames Muster liegt, prüft der Coach in den ersten Sitzungen. |
| 296.1 | 44.0 | 391.7 | 18.10 | Fraunces | #304969 | Vier Schwerpunkte, in dieser Reihenfolge. |
| 318.6 | 44.0 | 532.8 | 8.75 | Schibsted | #52616F | In dieser Reihenfolge beginnen wir. Die Reihenfolge ist eine Planung, keine Aussage darüber, dass ein Thema das andere |
| 331.3 | 44.0 | 94.3 | 8.75 | Schibsted | #52616F | voraussetzt. |
| 380.2 | 93.0 | 288.7 | 11.40 | Schibsted | #24313D | Flächen- und Raummaße umrechnen |
| 399.9 | 93.0 | 541.3 | 9.15 | Schibsted | #52616F | Längen und Massen gelangen. Flächen- und Volumeneinheiten schließen daran an und wurden noch nicht |
| 413.2 | 93.0 | 149.9 | 9.15 | Schibsted | #52616F | sicher gelöst. |
| 459.8 | 93.0 | 285.9 | 11.40 | Schibsted | #24313D | Prozent: Grundwert und Prozentsatz |
| 479.4 | 93.0 | 513.4 | 9.15 | Schibsted | #52616F | Der Prozentwert gelang. Die beiden anderen Grundaufgaben der Prozentrechnung üben wir gezielt. |
| 539.2 | 93.0 | 206.1 | 11.40 | Schibsted | #24313D | Rechnen mit Brüchen |
| 558.9 | 93.0 | 506.8 | 9.15 | Schibsted | #52616F | Kürzen und Umwandeln gelangen. Addieren, Multiplizieren und Dividieren üben wir nacheinander. |
| 618.8 | 93.0 | 185.8 | 11.40 | Schibsted | #24313D | Terme umformen |
| 638.4 | 93.0 | 516.2 | 9.15 | Schibsted | #52616F | Ausklammern und Minusklammer. Wichtig für Algebra & Funktionen, das nächste Klausurthema. Die |
| 651.8 | 93.0 | 348.1 | 9.15 | Schibsted | #52616F | Reihenfolge stimmen wir mit Blick auf den Klausurtermin ab. |
| 714.2 | 109.0 | 261.6 | 8.30 | Schibsted | #304969 | UNSER GEMEINSAMES LERNZIEL |
| 734.8 | 109.0 | 529.3 | 9.10 | Schibsted | #52616F | Ilkay löst Umrechnungen und Prozentaufgaben in beide Richtungen, rechnet mit Brüchen sicher und |
| 747.9 | 109.0 | 526.7 | 9.10 | Schibsted | #52616F | hat die Grundlagen für Algebra & Funktionen gefestigt. Wir überprüfen den Stand regelmäßig in den |
| 760.9 | 109.0 | 255.3 | 9.10 | Schibsted | #52616F | Sitzungen und passen den Plan an. |
| 788.6 | 93.0 | 535.0 | 7.80 | Schibsted | #8795A0 | Das ist der Stand nach dieser Analyse. Der Coach überprüft ihn in den ersten Sitzungen und passt den Plan an, wenn nötig. |

#### Zeichnung

| x₀ | y₀ | x₁ | y₁ | Form | Füllung | Kontur | Strich |
|---:|---:|---:|---:|---|---|---|---:|
| 44.0 | 132.0 | 551.0 | 246.0 | rund | #EAF5F0 | – | 0.00 |
| 94.0 | 436.0 | 551.0 | 436.0 | Linie | – | #DEE4E1 | 0.60 |
| 94.0 | 515.5 | 551.0 | 515.5 | Linie | – | #DEE4E1 | 0.60 |
| 94.0 | 595.0 | 551.0 | 595.0 | Linie | – | #DEE4E1 | 0.60 |
| 93.0 | 695.0 | 551.0 | 772.0 | rund | #FFFFFF | #DEE4E1 | 0.80 |
| 46.0 | 376.8 | 84.5 | 718.3 | Pfad | – | #304969 | 1.40 |
| 77.7 | 708.9 | 84.5 | 716.8 | Linie | – | #E4A132 | 1.90 |
| 55.0 | 370.8 | 67.0 | 382.8 | Pfad | #FFFFFF | #304969 | 1.30 |
| 55.0 | 450.3 | 67.0 | 462.3 | Pfad | #FFFFFF | #304969 | 1.30 |
| 55.0 | 529.8 | 67.0 | 541.8 | Pfad | #FFFFFF | #304969 | 1.30 |
| 55.0 | 609.3 | 67.0 | 621.3 | Pfad | #FFFFFF | #304969 | 1.30 |

### Seite 5

#### Text

| y (Grundlinie) | x | rechts | Größe | Schrift | Farbe | Text |
|---:|---:|---:|---:|---|---|---|
| 112.3 | 44.0 | 142.1 | 8.30 | Schibsted | #304969 | WIE ES WEITERGEHT |
| 156.0 | 44.0 | 424.2 | 27.00 | Fraunces | #304969 | Unsere Einschätzung für Ilkay. |
| 187.6 | 44.0 | 550.9 | 9.60 | Schibsted | #52616F | Der Bericht endet nicht mit einer Zahl, sondern mit einem Vorschlag. Was er bedeutet und ob er passt, besprechen |
| 201.6 | 44.0 | 105.0 | 9.60 | Schibsted | #52616F | wir mit Ihnen. |
| 263.3 | 72.0 | 217.1 | 7.30 | Schibsted | #FFFFFF | VORSCHLAG, NOCH NICHT FREIGEGEBEN |
| 302.0 | 62.0 | 342.4 | 18.00 | Fraunces | #FFFFFF | Welcher Rhythmus zu Ilkay passt, |
| 324.6 | 62.0 | 376.5 | 17.60 | Fraunces | #FFFFFF | legen wir gemeinsam im Gespräch fest. |
| 346.6 | 63.0 | 531.4 | 8.65 | Schibsted | #E4ECF0 | Vorschlag des Coachs: Premium, 2 Sessions pro Woche. Vier Förderthemen, die regelmäßig Wiederholung brauchen. |
| 402.3 | 44.0 | 181.9 | 8.30 | Schibsted | #304969 | UNSERE MITGLIEDSCHAFTEN |
| 442.0 | 411.0 | 482.1 | 7.00 | Schibsted | #08665C | COACH-VORSCHLAG |
| 445.1 | 57.0 | 118.8 | 7.10 | Schibsted | #8795A0 | MITGLIEDSCHAFT |
| 445.1 | 230.0 | 291.8 | 7.10 | Schibsted | #8795A0 | MITGLIEDSCHAFT |
| 482.0 | 57.0 | 98.9 | 17.00 | Fraunces | #304969 | Basic |
| 482.0 | 230.0 | 302.3 | 17.00 | Fraunces | #304969 | Standard |
| 482.0 | 403.0 | 476.8 | 17.00 | Fraunces | #304969 | Premium |
| 516.5 | 57.0 | 138.2 | 8.50 | Schibsted | #24313D | 1 Session pro Woche |
| 516.5 | 230.0 | 322.7 | 8.50 | Schibsted | #24313D | 1,5 Sessions pro Woche |
| 516.5 | 403.0 | 490.5 | 8.50 | Schibsted | #24313D | 2 Sessions pro Woche |
| 536.5 | 57.0 | 81.0 | 8.50 | Schibsted | #52616F | 1 Fach |
| 536.5 | 230.0 | 289.2 | 8.50 | Schibsted | #52616F | bis zu 2 Fächer |
| 536.5 | 403.0 | 462.2 | 8.50 | Schibsted | #52616F | bis zu 2 Fächer |
| 561.4 | 57.0 | 143.4 | 7.40 | Schibsted | #8795A0 | Konditionen im Gespräch |
| 561.4 | 230.0 | 316.4 | 7.40 | Schibsted | #8795A0 | Konditionen im Gespräch |
| 561.4 | 403.0 | 489.4 | 7.40 | Schibsted | #8795A0 | Konditionen im Gespräch |
| 598.5 | 44.0 | 474.0 | 8.50 | Schibsted | #52616F | Preise, Laufzeiten und Konditionen besprechen wir persönlich. Dieser Bericht enthält keine Vertragsangaben. |
| 661.3 | 60.0 | 251.6 | 8.30 | Schibsted | #304969 | IHR PERSÖNLICHER ANSPRECHPARTNER |
| 661.3 | 323.6 | 468.9 | 8.30 | Schibsted | #304969 | FRAGEN ODER ENTSCHEIDUNG |
| 689.2 | 323.6 | 514.1 | 9.20 | Schibsted | #52616F | Sie können sich direkt entscheiden oder sich |
| 694.0 | 60.0 | 149.0 | 16.00 | Fraunces | #304969 | Rasit Güven |
| 702.9 | 323.6 | 498.4 | 9.20 | Schibsted | #52616F | später mit Fragen melden. Wir antworten |
| 714.5 | 60.0 | 204.9 | 8.50 | Schibsted | #52616F | Mitgründer, hat die Analyse begleitet |
| 716.6 | 323.6 | 493.4 | 9.20 | Schibsted | #52616F | persönlich, ohne Termin und ohne Frist. |
| 738.2 | 60.0 | 176.4 | 9.25 | Schibsted | #08665C | rasit@edvanceacademy.de |

#### Zeichnung

| x₀ | y₀ | x₁ | y₁ | Form | Füllung | Kontur | Strich |
|---:|---:|---:|---:|---|---|---|---:|
| 44.0 | 236.0 | 551.0 | 363.0 | rund | #304969 | – | 0.00 |
| 62.0 | 252.0 | 227.1 | 269.3 | rund | #456281 | – | 0.00 |
| 44.0 | 422.0 | 205.0 | 574.0 | rund | #FFFFFF | #DEE4E1 | 0.75 |
| 57.0 | 499.0 | 192.0 | 499.0 | Linie | – | #DEE4E1 | 0.70 |
| 217.0 | 422.0 | 378.0 | 574.0 | rund | #FFFFFF | #DEE4E1 | 0.75 |
| 230.0 | 499.0 | 365.0 | 499.0 | Linie | – | #DEE4E1 | 0.70 |
| 390.0 | 422.0 | 551.0 | 574.0 | rund | #EFF7F4 | #087F70 | 1.05 |
| 403.0 | 432.0 | 490.1 | 447.0 | rund | #EAF5F0 | – | 0.00 |
| 403.0 | 499.0 | 538.0 | 499.0 | Linie | – | #DEE4E1 | 0.70 |
| 44.0 | 636.0 | 551.0 | 768.0 | rund | #FFFFFF | #DEE4E1 | 0.80 |
| 307.6 | 654.0 | 307.6 | 751.0 | Linie | – | #DEE4E1 | 0.75 |

