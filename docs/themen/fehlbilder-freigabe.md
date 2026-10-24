# Fehlbilder vor der Freigabe (Migration 20261016130500)

Stand 16.10.2026. Alle Texte wörtlich per `~/bin/dbread` aus Produktion (nur lesend). Nicht committet.

Umfang: alle Fehlbild-Slugs in den 257 Pilot-Aufgaben (`tasks.pruef_pilot`), die einen Klartext, aber kein `freigegeben_am` haben: **54**. „Session“ = kommt in mindestens einer der 49 Session-Aufgaben vor (`docs/prefill/hinweise-e3-snapshot.json`), dort zeigt der Coach-Live-Strom den Klartext erst nach Freigabe. „Nur LSA“ = betrifft nur den LSA-Report.

Beispiel = eine Pilot-Aufgabe, deren `known_errors` die genannte falsche Antwort diesem Slug zuordnet.

⚠ = Markierung mit Gegenvorschlag (17 von 54). Ohne ⚠ = Text aus meiner Sicht freigabefähig.

## Geänderte Texte (17), Migration 20261016130500

- `vorzeichen_potenz` (Session)
  - Klartext: „Beim Hochnehmen einer negativen Zahl wurde das Minuszeichen falsch behandelt.“ → „Behandelt das Minuszeichen beim Hochnehmen falsch: (−3)² = −9 statt 9, oder −2² wie (−2)² gerechnet, also 4 statt −4.“
  - Grund: Bei −2² wurde das Minus mitquadriert, nicht eine negative Zahl hochgenommen; der neue Text nennt beide Richtungen.
- `quadrat_gliedweise` (Session)
  - Klartext: „Quadriert die Klammer gliedweise – das mittlere Glied 2ab fehlt.“ → „Quadriert eine Klammer mit Plus oder Minus Teil für Teil und vergisst das mittlere Glied: (x + 3)² = x² + 9 statt x² + 6x + 9.“
  - Erklärung: „Aus (a+b)² wird a²+b² gemacht. Der Schritt, der fehlt, ist das doppelte Produkt der beiden Glieder. Das ist kein Rechenfehler, sondern eine Abkürzung, die naheliegt, weil sie beim Ausmultiplizieren einer Summe tatsächlich erlaubt wäre. Wir zeigen die Formel deshalb einmal als ausgeschriebene Doppelklammer – danach ist das mittlere Glied sichtbar und der Fehler verschwindet meist schnell.“ → „Aus (a + b)² wird a² + b² gemacht. Es fehlt das doppelte Produkt der beiden Glieder, 2ab. Die Abkürzung liegt nahe, weil sie bei einem Produkt tatsächlich stimmt: (a · b)² = a² · b². Bei einer Summe stimmt sie nicht. Geübt wird, die Klammer einmal als (a + b) · (a + b) auszuschreiben; dann ist das mittlere Glied sichtbar.“
  - Grund: „gliedweise“ und „2ab“ versteht kein Elternteil, und die alte Erklärung behauptete fälschlich, die Abkürzung sei bei einer Summe erlaubt.
- `pq_vorzeichen` (Session)
  - Klartext: „Setzt p in der p-q-Formel mit falschem Vorzeichen ein, beide Lösungen kippen ins Gegenteil.“ → „Setzt in der p-q-Formel die Zahl vor dem x mit falschem Vorzeichen ein; beide Lösungen bekommen dadurch das falsche Vorzeichen, etwa −1 und −5 statt 1 und 5.“
  - Grund: „p“ allein ist ohne Erklärung unverständlich, „kippen ins Gegenteil“ ist vage.
- `wurzel_vergessen` (Session)
  - Klartext: „Rechnet bis zum Quadrat richtig, zieht am Ende aber nicht die Wurzel.“ → „Vergisst am Ende das Wurzelziehen: Aus x² = 49 wird x = 49 statt x = 7 und x = −7.“
  - Grund: „Bis zum Quadrat richtig“ passt nicht zu den Aufgaben mit p-q-Formel.
- `loesung_null_verloren` (Session)
  - Klartext: „Teilt durch x und verliert dabei die Lösung x = 0.“ → „Übersieht die Lösung x = 0, etwa weil durch x geteilt wurde: Bei x² − 5x = 0 bleibt nur x = 5 übrig.“
  - Grund: Bei x · (2x − 7) = 0 wird nicht durch x geteilt, die Lösung x = 0 fehlt trotzdem.
- `achsenabschnitt_verwechselt`
  - Klartext: „Gibt die Nullstelle als y-Achsenabschnitt an oder umgekehrt.“ → „Verwechselt den Startwert, an dem der Graph die y-Achse schneidet, mit der Stelle, an der er die x-Achse schneidet: bei f(x) = 4x − 6 also 1,5 statt −6.“
  - Grund: „Nullstelle“ und „y-Achsenabschnitt“ sind Fachbegriffe.
- `basiswinkel_falsch_zugeordnet`
  - Klartext: „Verwechselt im gleichschenkligen Dreieck den Winkel an der Spitze mit einem Basiswinkel.“ → „Verwechselt im Dreieck mit zwei gleich langen Seiten den Winkel an der Spitze mit einem der beiden gleich großen Winkel an der Grundseite.“
  - Grund: „gleichschenklig“ und „Basiswinkel“ sind Fachbegriffe.
- `faktor_ohne_wurzel`
  - Klartext: „Zieht beim teilweisen Wurzelziehen den Faktor heraus, ohne aus ihm die Wurzel zu ziehen: √72 = 36·√2.“ → „Holt eine Quadratzahl aus der Wurzel, ohne aus ihr die Wurzel zu ziehen: √72 = 36 · √2 statt 6 · √2.“
  - Grund: „teilweises Wurzelziehen“ ist ein Fachbegriff; jetzt mit dem richtigen Ergebnis.
- `faktorisierung_unvollstaendig`
  - Klartext: „Klammert aus, erkennt die binomische Form darin aber nicht.“ → „Klammert richtig aus, zerlegt den Rest aber nicht weiter mit einer binomischen Formel: 2(x² − 9) statt 2(x + 3)(x − 3).“
  - Erklärung: „Der erste Schritt ist richtig: der gemeinsame Faktor steht vor der Klammer. Was in der Klammer übrig bleibt, ist aber noch einmal eine binomische Form und liesse sich weiter zerlegen. Das Ergebnis ist damit nicht falsch, nur nicht zu Ende geführt. Wir üben, nach dem Ausklammern ein zweites Mal hinzusehen.“ → „Der erste Schritt ist richtig: der gemeinsame Faktor steht vor der Klammer. Was in der Klammer übrig bleibt, ist aber noch einmal eine binomische Form und ließe sich weiter zerlegen. Gerechnet ist also richtig, nur nicht zu Ende. Geübt wird, nach dem Ausklammern ein zweites Mal hinzusehen.“
  - Grund: Der Klartext sagte nicht, was fehlt; die Erklärung hatte „liesse“ und „Wir üben“ und nannte das Ergebnis „nicht falsch“.
- `gegenereignis_nicht_abgezogen`
  - Klartext: „Gibt die Wahrscheinlichkeit des Gegenereignisses an statt der gesuchten.“ → „Rechnet die Wahrscheinlichkeit für das Gegenteil aus, etwa „keine Sechs“ statt „mindestens eine Sechs“, und zieht sie am Ende nicht von 1 ab.“
  - Grund: „Gegenereignis“ ist ein Fachbegriff.
- `koordinate_vorzeichen_verloren`
  - Erklärung: „Der Abstand zum Ursprung stimmt, nur die Richtung ist verloren: ein Punkt links der y-Achse oder unterhalb der x-Achse bekommt eine positive Koordinate. Das ist kein Rechenfehler, sondern eine Frage der Achsenrichtung. Geuebt wird, die negativen Abschnitte der Achsen als eigene Richtung zu lesen.“ → „Der Abstand zum Ursprung stimmt, nur die Richtung ist verloren: ein Punkt links der y-Achse oder unterhalb der x-Achse bekommt eine positive Koordinate. Das ist kein Rechenfehler, sondern eine Frage der Achsenrichtung. Geübt wird, die negativen Abschnitte der Achsen als eigene Richtung zu lesen.“
  - Grund: Tippfehler „Geuebt“ in der Erklärung.
- `koordinaten_vertauscht`
  - Erklärung: „Der Punkt wird richtig gefunden, aber die beiden Werte stehen in der falschen Reihenfolge: zuerst der Wert an der senkrechten Achse, dann der an der waagerechten. Im Koordinatenpaar steht immer zuerst x (nach rechts oder links), dann y (nach oben oder unten). Geuebt wird die feste Reihenfolge beim Ablesen und beim Eintragen.“ → „Der Punkt wird richtig gefunden, aber die beiden Werte stehen in der falschen Reihenfolge: zuerst der Wert an der senkrechten Achse, dann der an der waagerechten. Im Koordinatenpaar steht immer zuerst x (nach rechts oder links), dann y (nach oben oder unten). Geübt wird die feste Reihenfolge beim Ablesen und beim Eintragen.“
  - Grund: Tippfehler „Geuebt“ in der Erklärung.
- `mal_zwei_vergessen`
  - Klartext: „Ein nötiges Verdoppeln wurde weggelassen.“ → „Vergisst beim mittleren Glied das Verdoppeln: (x + 3)² = x² + 3x + 9 statt x² + 6x + 9.“
  - Erklärung: „Manche Formeln enthalten ein „mal 2“, etwa weil ein Quader jede Seitenfläche zweimal hat oder ein Zylinder zwei Deckel. Fehlt dieser Faktor, stimmt der Rest der Rechnung oft, ein Teil geht aber nur einfach statt doppelt ein, und das Ergebnis weicht entsprechend ab.“ → „In (a + b)² = a² + 2ab + b² kommt das Produkt ab zweimal vor, einmal als a · b und einmal als b · a. Hier wurde es nur einmal gezählt, das mittlere Glied ist deshalb nur halb so groß. Geübt wird, die Klammer einmal als (a + b) · (a + b) auszuschreiben.“
  - Grund: Alle 4 Aufgaben sind binomische Formeln, die Erklärung sprach von Quader und Zylinder.
- `nur_ein_pfad`
  - Klartext: „Berücksichtigt bei einem Ereignis nur einen von mehreren passenden Pfaden.“ → „Zählt nur einen von mehreren passenden Wegen, etwa nur „erst Kopf, dann Zahl“ und nicht auch „erst Zahl, dann Kopf“.“
  - Grund: „Pfad“ ist ein Fachbegriff aus dem Baumdiagramm.
- `pfadregel_addiert`
  - Klartext: „Addiert die Wahrscheinlichkeiten entlang eines Pfades, statt sie zu multiplizieren.“ → „Zählt Wahrscheinlichkeiten zusammen, wo sie malgenommen werden müssen, etwa bei „erst …, dann …“ oder bei mehreren Versuchen hintereinander.“
  - Grund: „Pfad“ ist ein Fachbegriff, und die Fehler in den Aufgaben entstehen nicht entlang eines Pfades.
- `quadratdifferenz_vorzeichen`
  - Klartext: „Vorzeichen im Ergebnis gekippt – a²+b² statt a²−b².“ → „Schreibt bei (a + b)(a − b) am Ende Plus statt Minus: (x + 4)(x − 4) = x² + 16 statt x² − 16.“
  - Grund: „a²+b² statt a²−b²“ ist ohne Bezug zur Aufgabe abstrakt.
- `stellenwert_ignoriert`
  - Klartext: „Beim Rechnen mit Kommazahlen wurden die Stellen nicht richtig miteinander verrechnet.“ → „Schreibt Kommazahlen nicht Stelle unter Stelle und rechnet so Zehntel mit Hundertsteln zusammen: 0,25 + 0,4 = 0,29 statt 0,65.“
  - Grund: „Nicht richtig miteinander verrechnet“ sagte nicht, was passiert ist.

## Übersicht

| # | Slug | Gruppe | Aufg. | Markierung | Entscheidung |
|---|---|---|---|---|---|
| 1 | `ausklammern_falsch_geteilt` | Session | 6 | – | |
| 2 | `ausklammern_glied_nicht_geteilt` | Session | 6 | – | |
| 3 | `halbieren_vergessen` | Session | 21 | – | |
| 4 | `loesung_null_verloren` | Session | 3 | ⚠ passt nicht ganz zur Beispielantwort | |
| 5 | `negative_loesung_vergessen` | Session | 4 | – | |
| 6 | `pq_vorzeichen` | Session | 6 | ⚠ Fachbegriff | |
| 7 | `quadrat_gliedweise` | Session | 18 | ⚠ Fachbegriff, Erklärung fachlich falsch | |
| 8 | `vorzeichen_aus_klammer` | Session | 6 | – | |
| 9 | `vorzeichen_potenz` | Session | 13 | ⚠ Fehler falsch beschrieben | |
| 10 | `wurzel_vergessen` | Session | 13 | ⚠ ungenau | |
| 11 | `abgeschnitten` | nur LSA | 14 | – | |
| 12 | `achsenabschnitt_verwechselt` | nur LSA | 4 | ⚠ Fachbegriff | |
| 13 | `additiv_gekuerzt` | nur LSA | 7 | – | |
| 14 | `basis_exponent_vertauscht` | nur LSA | 12 | – | |
| 15 | `basiswinkel_falsch_zugeordnet` | nur LSA | 2 | ⚠ Fachbegriff | |
| 16 | `differenz_vergessen` | nur LSA | 2 | – | |
| 17 | `faktor_ohne_wurzel` | nur LSA | 6 | ⚠ Fachbegriff | |
| 18 | `faktorisierung_unvollstaendig` | nur LSA | 4 | ⚠ Tippfehler, Tonfall, ungenau | |
| 19 | `falsche_hoehe` | nur LSA | 2 | – | |
| 20 | `falsche_operation` | nur LSA | 3 | – | |
| 21 | `falsche_stelle` | nur LSA | 13 | – | |
| 22 | `gegenereignis_nicht_abgezogen` | nur LSA | 2 | ⚠ Fachbegriff | |
| 23 | `immer_aufgerundet` | nur LSA | 5 | – | |
| 24 | `irrational_verwechselt` | nur LSA | 4 | – | |
| 25 | `komma_ignoriert` | nur LSA | 9 | – | |
| 26 | `komma_nicht_verschoben` | nur LSA | 9 | – | |
| 27 | `kommastellen_zu_viel` | nur LSA | 12 | – | |
| 28 | `kommastellen_zu_wenig` | nur LSA | 12 | – | |
| 29 | `koordinate_vorzeichen_verloren` | nur LSA | 1 | ⚠ Tippfehler | |
| 30 | `koordinaten_vertauscht` | nur LSA | 4 | ⚠ Tippfehler | |
| 31 | `loesungsanzahl_verwechselt` | nur LSA | 3 | – | |
| 32 | `m_b_vertauscht` | nur LSA | 6 | – | |
| 33 | `mal_exponent` | nur LSA | 23 | – | |
| 34 | `mal_zwei_vergessen` | nur LSA | 4 | ⚠ Erklärung passt nicht zu den Aufgaben | |
| 35 | `nicht_alle_glieder_multipliziert` | nur LSA | 3 | – | |
| 36 | `nur_ein_pfad` | nur LSA | 5 | ⚠ Fachbegriff | |
| 37 | `nur_eine_grundseite` | nur LSA | 6 | – | |
| 38 | `nur_einmal_addiert` | nur LSA | 1 | – | |
| 39 | `parallele_uebersehen` | nur LSA | 3 | – | |
| 40 | `pfadregel_addiert` | nur LSA | 3 | ⚠ Fachbegriff, passt nicht ganz zur Beispielantwort | |
| 41 | `plus_statt_mal` | nur LSA | 11 | – | |
| 42 | `quadratdifferenz_vorzeichen` | nur LSA | 13 | ⚠ Fachbegriff | |
| 43 | `rechter_winkel_falsche_ecke` | nur LSA | 3 | – | |
| 44 | `seiten_ungleich_verknuepft` | nur LSA | 4 | – | |
| 45 | `steigung_kehrwert` | nur LSA | 7 | – | |
| 46 | `stellenwert_ignoriert` | nur LSA | 8 | ⚠ ungenau | |
| 47 | `teilflaeche_vergessen` | nur LSA | 1 | – | |
| 48 | `uebertrag_vergessen` | nur LSA | 3 | – | |
| 49 | `umfang_statt_flaeche` | nur LSA | 7 | – | |
| 50 | `umgekehrt_geteilt` | nur LSA | 4 | – | |
| 51 | `wurzel_gliedweise` | nur LSA | 4 | – | |
| 52 | `wurzel_halbiert` | nur LSA | 23 | – | |
| 53 | `ziffern_gelesen` | nur LSA | 6 | – | |
| 54 | `zuruecklegen_ignoriert` | nur LSA | 3 | – | |

## Session (10)

### `ausklammern_falsch_geteilt`

6 Aufgaben · term_ausklammern

- **Klartext:** „Klammert den richtigen Faktor aus, teilt das zweite Glied aber durch eine andere Zahl: 6x + 12 = 6(x + 4).“
- **Erklärung:** „Vor der Klammer steht ein Faktor, in der Klammer muss jedes Glied durch genau diesen Faktor geteilt sein. Wer das zweite Glied durch eine andere Zahl teilt, etwa durch die Hälfte, bekommt beim Ausmultiplizieren einen anderen Term. Geübt wird die Probe durch Ausmultiplizieren.“
- **Beispiel:** `65841bd8` term_ausklammern · MC  
  Klammere so weit wie möglich aus. Welcher Term ist richtig? 6x + 12 = ?  
  richtig: **6(x + 2)** · falsch: **6(x + 4)**

### `ausklammern_glied_nicht_geteilt`

6 Aufgaben · term_ausklammern

- **Klartext:** „Klammert den Faktor aus, lässt das zweite Glied aber unverändert in der Klammer: 4x + 8 = 4(x + 8).“
- **Erklärung:** „Beim Ausklammern wird jedes Glied durch den ausgeklammerten Faktor geteilt. Wer das zweite Glied stehen lässt, bekommt beim Ausmultiplizieren nicht mehr den Ausgangsterm zurück. Geübt wird die Probe durch Ausmultiplizieren.“
- **Beispiel:** `4baeeda9` term_ausklammern · MC  
  Klammere so weit wie möglich aus. Welcher Term ist richtig? 4x + 8 = ?  
  richtig: **4(x + 2)** · falsch: **4(x + 8)**

### `halbieren_vergessen`

21 Aufgaben · geo_flaeche_drachen_raute, geo_flaeche_term, geo_flaeche_trapez, geo_winkel_thales, gleichung_quadr_anzahl, term_binom_faktorisieren

- **Klartext:** „Ein nötiger Schritt „geteilt durch 2“ wurde weggelassen.“
- **Erklärung:** „Viele Rechenwege enthalten ein Halbieren, etwa bei der Fläche eines Dreiecks oder einer Raute oder bei zwei gleich großen Winkeln. Fehlt dieser Schritt, stimmt die übrige Rechnung oft, nur dieser eine Teil geht doppelt so groß in das Ergebnis ein.“
- **Beispiel:** `56540a88` gleichung_quadr_anzahl · NUMERIC  
  Für welchen Wert von q hat die Gleichung x² + 6x + q = 0 genau eine Lösung? Gib q exakt an.  
  richtig: **9** · falsch: **36**

### ⚠ `loesung_null_verloren`

3 Aufgaben · gleichung_quadr_faktor

- **Klartext:** „Teilt durch x und verliert dabei die Lösung x = 0.“
- **Erklärung:** „Bei x² = 5x liegt es nahe, durch x zu teilen. Dabei geht aber die Lösung x = 0 verloren, denn durch null darf nicht geteilt werden. Richtig ist, alles auf eine Seite zu bringen und x auszuklammern: x(x − 5) = 0. Geübt wird, nie durch einen Term mit x zu teilen.“
- **Beispiel:** `b47ef7d3` gleichung_quadr_faktor · MULTI_PART (Teil 1: kleinere Lösung)  
  Löse die Gleichung x² − 5x = 0. Gib die Lösungen exakt an.  
  richtig: **0** · falsch: **5**
- ⚠ **passt nicht ganz zur Beispielantwort:** Bei x · (2x − 7) = 0 (`c3be2e88`, falsch 3,5) wird nicht durch x geteilt, x = 0 fehlt trotzdem. „Teilt durch x“ beschreibt nur eine von zwei Ursachen.
  - **Vorschlag Klartext:** „Übersieht die Lösung x = 0, etwa weil durch x geteilt wurde: Bei x² − 5x = 0 bleibt nur x = 5 übrig.“

### `negative_loesung_vergessen`

4 Aufgaben · gleichung_quadr_wurzel

- **Klartext:** „Gibt bei x² = c nur die positive Lösung an und übersieht die negative.“
- **Erklärung:** „Sowohl 7² als auch (−7)² ergeben 49. Eine Gleichung wie x² = 49 hat deshalb zwei Lösungen, 7 und −7. Hier wurde nur die positive genannt. Geübt wird, beim Wurzelziehen in einer Gleichung immer ± mitzuschreiben.“
- **Beispiel:** `9264f90a` gleichung_quadr_wurzel · MULTI_PART (Teil 1: kleinere Lösung)  
  Löse die Gleichung x² = 49. Gib die Lösungen exakt an.  
  richtig: **-7** · falsch: **7**

### ⚠ `pq_vorzeichen`

6 Aufgaben · gleichung_quadr_formel

- **Klartext:** „Setzt p in der p-q-Formel mit falschem Vorzeichen ein, beide Lösungen kippen ins Gegenteil.“
- **Erklärung:** „Die p-q-Formel beginnt mit −p/2. Ist p negativ, wird daraus eine positive Zahl. Hier wurde das Vorzeichen von p nicht umgedreht, die Lösungen haben deshalb das falsche Vorzeichen. Geübt wird, p und q mit Vorzeichen aufzuschreiben, bevor eingesetzt wird.“
- **Beispiel:** `43f39bc1` gleichung_quadr_formel · MULTI_PART (Teil 1: kleinere Lösung)  
  Löse die Gleichung x² − 6x + 5 = 0. Gib die Lösungen exakt an.  
  richtig: **1** · falsch: **-5**
- ⚠ **Fachbegriff:** „p“ ist für Eltern ohne Erklärung nicht verständlich, „kippen ins Gegenteil“ bleibt vage. Fachlich passt der Text zu allen Beispielen.
  - **Vorschlag Klartext:** „Setzt in der p-q-Formel die Zahl vor dem x mit falschem Vorzeichen ein; beide Lösungen bekommen dadurch das falsche Vorzeichen, etwa −1 und −5 statt 1 und 5.“

### ⚠ `quadrat_gliedweise`

18 Aufgaben · gleichung_quadr_wurzel, potenzen, term_binom_faktorisieren, term_binom_gemischt, term_binom_quadrat

- **Klartext:** „Quadriert die Klammer gliedweise – das mittlere Glied 2ab fehlt.“
- **Erklärung:** „Aus (a+b)² wird a²+b² gemacht. Der Schritt, der fehlt, ist das doppelte Produkt der beiden Glieder. Das ist kein Rechenfehler, sondern eine Abkürzung, die naheliegt, weil sie beim Ausmultiplizieren einer Summe tatsächlich erlaubt wäre. Wir zeigen die Formel deshalb einmal als ausgeschriebene Doppelklammer – danach ist das mittlere Glied sichtbar und der Fehler verschwindet meist schnell.“
- **Beispiel:** `3a42b89c` gleichung_quadr_wurzel · NUMERIC  
  Verlängert man jede Seite eines Quadrats um 3 cm, so hat das neue Quadrat einen Flächeninhalt von 121 cm². Wie lang war eine Seite des ursprünglichen Quadrats? Gib das Ergebnis exakt an.  
  richtig: **8** · falsch: **10,58**
- ⚠ **Fachbegriff, Erklärung fachlich falsch:** „gliedweise“ und „2ab“ verstehen Eltern nicht. Die Erklärung behauptet, die Abkürzung „wäre beim Ausmultiplizieren einer Summe tatsächlich erlaubt“. Das ist falsch, erlaubt ist sie bei einem Produkt: (a · b)² = a² · b². Außerdem steht dort „Wir zeigen“ statt der sonst üblichen Form „Geübt wird“.
  - **Vorschlag Klartext:** „Quadriert eine Klammer mit Plus oder Minus Teil für Teil und vergisst das mittlere Glied: (x + 3)² = x² + 9 statt x² + 6x + 9.“
  - **Vorschlag Erklärung:** „Aus (a + b)² wird a² + b² gemacht. Es fehlt das doppelte Produkt der beiden Glieder, 2ab. Die Abkürzung liegt nahe, weil sie bei einem Produkt tatsächlich stimmt: (a · b)² = a² · b². Bei einer Summe stimmt sie nicht. Geübt wird, die Klammer einmal als (a + b) · (a + b) auszuschreiben; dann ist das mittlere Glied sichtbar.“

### `vorzeichen_aus_klammer`

6 Aufgaben · gleichung_quadr_faktor, gleichung_quadr_wurzel

- **Klartext:** „Liest aus einer Klammer wie (x − 3) den Wert mit falschem Vorzeichen ab: −3 statt 3.“
- **Erklärung:** „In (x − 3) steckt die Zahl 3: Für x = 3 wird die Klammer null. Das gilt beim Scheitelpunkt von y = (x − 3)² + 1 genauso wie bei der Gleichung (x − 3)(x + 5) = 0. Hier wurde das Vorzeichen aus der Klammer übernommen statt umgedreht. Geübt wird die Frage: Für welches x wird die Klammer null?“
- **Beispiel:** `1c4a31af` gleichung_quadr_faktor · MULTI_PART (Teil 1: kleinere Lösung)  
  Löse die Gleichung (x − 3)(x + 5) = 0. Gib die Lösungen exakt an.  
  richtig: **-5** · falsch: **-3**

### ⚠ `vorzeichen_potenz`

13 Aufgaben · gleichung_quadr_anzahl, potenzen, term_binom_quadrat

- **Klartext:** „Beim Hochnehmen einer negativen Zahl wurde das Minuszeichen falsch behandelt.“
- **Erklärung:** „(−3)² bedeutet (−3) · (−3) und ergibt 9, weil Minus mal Minus Plus ergibt; −3² ohne Klammer ist dagegen −9. Wird aus dem Quadrat einer negativen Zahl eine negative Zahl, ist schon dieser Zwischenschritt falsch, und alles, was damit weitergerechnet wird, ebenfalls.“
- **Beispiel:** `a3343b39` potenzen · NUMERIC  
  Berechne. -2^2 = ?  
  richtig: **-4** · falsch: **4**
- ⚠ **Fehler falsch beschrieben:** Bekannter Fall: Bei −2² (falsch 4) wird keine negative Zahl hochgenommen, das Minus wurde mitquadriert. Der Slug deckt außerdem die Gegenrichtung ab: (−3)² = −9, (−2)³ = 8, (x − 5)² = x² − 10x − 25 und (p/2)² mit negativem p in der Diskriminante. Der Vorschlag nennt beide Richtungen. Alternative: für −2² einen eigenen Slug anlegen; das ändert aber die Akzeptanz der Aufgabe `a3343b39` und gehört nicht in 130500.
  - **Vorschlag Klartext:** „Behandelt das Minuszeichen beim Hochnehmen falsch: (−3)² = −9 statt 9, oder −2² wie (−2)² gerechnet, also 4 statt −4.“

### ⚠ `wurzel_vergessen`

13 Aufgaben · gleichung_quadr_formel, gleichung_quadr_wurzel, term_binom_faktorisieren, term_binom_quadrat

- **Klartext:** „Rechnet bis zum Quadrat richtig, zieht am Ende aber nicht die Wurzel.“
- **Erklärung:** „Beim Satz des Pythagoras steht nach dem Einsetzen zuerst c² da, bei x² = 49 zuerst die 49. Gesucht ist aber die Länge bzw. x selbst, also fehlt noch das Wurzelziehen. Das Ergebnis ist dann viel zu groß. Geübt wird, am Ende zu prüfen, ob die Antwort zur Frage passt: eine Länge, nicht ihr Quadrat.“
- **Beispiel:** `9264f90a` gleichung_quadr_wurzel · MULTI_PART (Teil 2: größere Lösung)  
  Löse die Gleichung x² = 49. Gib die Lösungen exakt an.  
  richtig: **7** · falsch: **49**
- ⚠ **ungenau:** „Rechnet bis zum Quadrat richtig“ trifft die p-q-Fälle nicht, etwa x² + 2x − 15 = 0 mit der falschen Antwort 15 (−1 + 16 statt −1 + 4). Gemeinsam ist allen Fällen nur das fehlende Wurzelziehen am Ende.
  - **Vorschlag Klartext:** „Vergisst am Ende das Wurzelziehen: Aus x² = 49 wird x = 49 statt x = 7 und x = −7.“

## Nur LSA (44)

### `abgeschnitten`

14 Aufgaben · runden_ueberschlag, zahl_wurzel_irrational, zahl_wurzel_naeherung

- **Klartext:** „Überzählige Nachkommastellen wurden einfach weggelassen.“
- **Erklärung:** „Beim Runden entscheidet die erste weggelassene Ziffer, ob aufgerundet wird; ist „mindestens“ gefragt, muss sogar immer aufgerundet werden. Wer die Stellen nur abschneidet, liegt knapp unter dem richtigen Wert, bei einer Zahl mit Periode wie 0,4545… entsteht so sogar ein anderer Bruch.“
- **Beispiel:** `0cd53103` runden_ueberschlag · NUMERIC  
  Runde auf eine Nachkommastelle. 2,85 = ?  
  richtig: **2,9** · falsch: **2,8**

### ⚠ `achsenabschnitt_verwechselt`

4 Aufgaben · fkt_linear_yabschnitt

- **Klartext:** „Gibt die Nullstelle als y-Achsenabschnitt an oder umgekehrt.“
- **Erklärung:** „Der y-Achsenabschnitt ist der Punkt, an dem der Graph die senkrechte Achse schneidet; die Nullstelle der Punkt auf der waagerechten Achse. Hier wurden die beiden Schnittpunkte verwechselt. Geübt wird, vor dem Ablesen zu klären, welche Achse gemeint ist.“
- **Beispiel:** `e4611c3d` fkt_linear_yabschnitt · NUMERIC  
  Gegeben ist die Funktion f(x) = 4x - 6. Gib den y-Achsenabschnitt des Graphen von f an.  
  richtig: **-6** · falsch: **1,5**
- ⚠ **Fachbegriff:** „Nullstelle“ und „y-Achsenabschnitt“ sind für Eltern schwer verständlich, besonders bei den Sachaufgaben (Grundpreis, Wasserstand zu Beginn).
  - **Vorschlag Klartext:** „Verwechselt den Startwert, an dem der Graph die y-Achse schneidet, mit der Stelle, an der er die x-Achse schneidet: bei f(x) = 4x − 6 also 1,5 statt −6.“

### `additiv_gekuerzt`

7 Aufgaben · bruch_kuerzen

- **Klartext:** „Beim Kürzen wurde von Zähler und Nenner jeweils 1 abgezogen, statt beide durch dieselbe Zahl zu teilen.“
- **Erklärung:** „Kürzen heißt, Zähler und Nenner durch dieselbe Zahl zu teilen; dann bleibt der Wert des Bruchs gleich. Wird stattdessen auf beiden Seiten etwas abgezogen, ändert sich der Wert, auch wenn das Ergebnis auf den ersten Blick ähnlich aussieht.“
- **Beispiel:** `1244b84c` bruch_kuerzen · NUMERIC  
  Kürze den Bruch vollständig. 18/24 = ?  
  richtig: **3/4** · falsch: **17/23**

### `basis_exponent_vertauscht`

12 Aufgaben · potenzen

- **Klartext:** „Grundzahl und Hochzahl wurden vertauscht, etwa 2⁵ als 5² gerechnet.“
- **Erklärung:** „Bei 2⁵ wird die 2 fünfmal malgenommen, bei 5² die 5 zweimal; die Ergebnisse 32 und 25 sind verschieden. Die Verwechslung liegt nahe, weil die kleine, hochgestellte Zahl leicht anders gelesen wird; ausgeschrieben als Malaufgabe fällt sie sofort auf.“
- **Beispiel:** `5c73a51d` potenzen · NUMERIC  
  Berechne. 2^5 = ?  
  richtig: **32** · falsch: **25**

### ⚠ `basiswinkel_falsch_zugeordnet`

2 Aufgaben · geo_winkel_thales

- **Klartext:** „Verwechselt im gleichschenkligen Dreieck den Winkel an der Spitze mit einem Basiswinkel.“
- **Erklärung:** „Im gleichschenkligen Dreieck sind die beiden Winkel an der Grundseite gleich groß, der dritte Winkel liegt an der Spitze zwischen den gleich langen Seiten. Hier wurde der gegebene Winkel der falschen Ecke zugeordnet. Geübt wird, zuerst die gleich langen Seiten zu markieren.“
- **Beispiel:** `9ca300e1` geo_winkel_thales · NUMERIC  
  Die Strecke AB ist ein Durchmesser eines Kreises mit dem Mittelpunkt M. Der Punkt C liegt auf dem Kreis (C ≠ A, B); so entsteht das Dreieck ABC mit den Winkeln α bei A, β bei B und γ bei C. Der Winkel ∠BMC zwischen den Strecken MB und MC ist 64° groß. Wie groß ist α?  
  richtig: **32** · falsch: **26**
- ⚠ **Fachbegriff:** „Basiswinkel“ und „gleichschenklig“ sind Schulbegriffe. Die Erklärung beschreibt sie zwar, der Klartext steht im Report aber allein.
  - **Vorschlag Klartext:** „Verwechselt im Dreieck mit zwei gleich langen Seiten den Winkel an der Spitze mit einem der beiden gleich großen Winkel an der Grundseite.“

### `differenz_vergessen`

2 Aufgaben · geo_winkel_thales

- **Klartext:** „Der letzte Abzug fehlt: angegeben wurde ein Zwischenergebnis statt des gesuchten Winkels.“
- **Erklärung:** „Gesuchte Winkel ergeben sich oft als Rest, also 180° oder 360° minus die bekannten Winkel. Hier stimmt die Rechnung bis zum Zwischenergebnis, nur der letzte Schritt, das Abziehen, fehlt.“
- **Beispiel:** `11aebc7c` geo_winkel_thales · NUMERIC  
  Ein Fenster hat oben einen Halbkreisbogen. Die waagerechte Unterkante AB des Bogens ist ein Durchmesser des Halbkreises. Eine gerade Strebe verläuft von A zu einem Punkt C auf dem Bogen, eine zweite von C zu B. Die Strebe AC bildet mit der Unterkante einen Winkel von 32°. Wie groß ist der Winkel zwischen der Strebe CB und der Unterkante?  
  richtig: **58** · falsch: **122**

### ⚠ `faktor_ohne_wurzel`

6 Aufgaben · zahl_wurzel_teilweise

- **Klartext:** „Zieht beim teilweisen Wurzelziehen den Faktor heraus, ohne aus ihm die Wurzel zu ziehen: √72 = 36·√2.“
- **Erklärung:** „√72 = √(36 · 2) = √36 · √2 = 6 · √2. Vor die Wurzel kommt die Wurzel des Quadratfaktors, nicht der Faktor selbst. Hier wurde 36 statt 6 vor die Wurzel geschrieben. Geübt wird die Probe durch Quadrieren: (36 · √2)² wäre viel zu groß.“
- **Beispiel:** `0bcc83c8` zahl_wurzel_teilweise · NUMERIC  
  Es gilt √72 = a · √2. Bestimme a. a ist eine natürliche Zahl. Gib a exakt an.  
  richtig: **6** · falsch: **36**
- ⚠ **Fachbegriff:** „teilweises Wurzelziehen“ ist ein Fachbegriff. Der Text passt fachlich; der Vorschlag nennt dazu das richtige Ergebnis.
  - **Vorschlag Klartext:** „Holt eine Quadratzahl aus der Wurzel, ohne aus ihr die Wurzel zu ziehen: √72 = 36 · √2 statt 6 · √2.“

### ⚠ `faktorisierung_unvollstaendig`

4 Aufgaben · term_binom_faktorisieren

- **Klartext:** „Klammert aus, erkennt die binomische Form darin aber nicht.“
- **Erklärung:** „Der erste Schritt ist richtig: der gemeinsame Faktor steht vor der Klammer. Was in der Klammer übrig bleibt, ist aber noch einmal eine binomische Form und liesse sich weiter zerlegen. Das Ergebnis ist damit nicht falsch, nur nicht zu Ende geführt. Wir üben, nach dem Ausklammern ein zweites Mal hinzusehen.“
- **Beispiel:** `e4a18d51` term_binom_faktorisieren · MC  
  Faktorisiere vollständig. Welcher Term ist richtig? 2x² - 18 = ?  
  richtig: **2(x + 3)(x - 3)** · falsch: **2(x² - 9)**
- ⚠ **Tippfehler, Tonfall, ungenau:** In der Erklärung steht „liesse“ statt „ließe“ und „Wir üben“ statt „Geübt wird“. Der Satz „Das Ergebnis ist damit nicht falsch“ widerspricht der Bewertung, denn die Aufgabe verlangt „vollständig“. Der Klartext sagt nicht, was fehlt.
  - **Vorschlag Klartext:** „Klammert richtig aus, zerlegt den Rest aber nicht weiter mit einer binomischen Formel: 2(x² − 9) statt 2(x + 3)(x − 3).“
  - **Vorschlag Erklärung:** „Der erste Schritt ist richtig: der gemeinsame Faktor steht vor der Klammer. Was in der Klammer übrig bleibt, ist aber noch einmal eine binomische Form und ließe sich weiter zerlegen. Gerechnet ist also richtig, nur nicht zu Ende. Geübt wird, nach dem Ausklammern ein zweites Mal hinzusehen.“

### `falsche_hoehe`

2 Aufgaben · geo_flaeche_drachen_raute, geo_flaeche_trapez

- **Klartext:** „Als Höhe wurde eine andere Strecke eingesetzt, zum Beispiel eine schräge Seite.“
- **Erklärung:** „Für Flächen und Körper zählt jeweils eine bestimmte Höhe, die senkrecht auf der Grundseite steht; bei Pyramide und Kegel gibt es zusätzlich die schräge Höhe der Seitenflächen. Wird eine andere gegebene Strecke eingesetzt, stimmt der Rechenweg, das Ergebnis aber nicht.“
- **Beispiel:** `5c219db6` geo_flaeche_trapez · NUMERIC  
  Ein gleichschenkliges Trapez hat die parallelen Seiten a = 11 cm und c = 5 cm. Die beiden Schenkel sind je 5 cm lang, die Höhe beträgt h = 4 cm. Wie groß ist sein Flächeninhalt?  
  richtig: **32** · falsch: **40**

### `falsche_operation`

3 Aufgaben · dezimal_add_sub

- **Klartext:** „Es wurde eine andere Rechenart gewählt, als die Aufgabe verlangt.“
- **Erklärung:** „Gerechnet wurde meist richtig, nur passt die Rechenart nicht zur Frage: Es wurde zum Beispiel zusammengezählt, wo der Unterschied gesucht ist, oder abgezogen, wo ein Verhältnis gefragt ist. Der Fehler liegt also beim Übersetzen des Textes in eine Rechnung, nicht beim Rechnen.“
- **Beispiel:** `20321d30` dezimal_add_sub · NUMERIC  
  Ein Rucksack wiegt leer 0,85 kg. Vollgepackt wiegt er 3,2 kg. Wie viele Kilogramm wiegt der Inhalt?  
  richtig: **2,35** · falsch: **4,05**

### `falsche_stelle`

13 Aufgaben · runden_ueberschlag

- **Klartext:** „Es wurde auf eine andere Stelle gerundet als verlangt oder gar nicht gerundet.“
- **Erklärung:** „Die Aufgabe gibt vor, wie viele Stellen nach dem Komma stehen bleiben. Hier wurde an einer anderen Stelle gerundet oder die Zahl unverändert abgeschrieben; das Runden selbst ist dabei oft richtig.“
- **Beispiel:** `17eff311` runden_ueberschlag · NUMERIC  
  Runde auf zwei Nachkommastellen. 7,152 = ?  
  richtig: **7,15** · falsch: **7,152**

### ⚠ `gegenereignis_nicht_abgezogen`

2 Aufgaben · stoch_pfad_summe

- **Klartext:** „Gibt die Wahrscheinlichkeit des Gegenereignisses an statt der gesuchten.“
- **Erklärung:** „Oft ist das Gegenteil leichter zu berechnen, etwa „keine Sechs“ statt „mindestens eine Sechs“. Danach muss das Ergebnis noch von 1 abgezogen werden. Hier fehlt dieser letzte Schritt, die Rechnung davor stimmt. Geübt wird, am Ende noch einmal nachzulesen, nach welchem Ereignis gefragt war.“
- **Beispiel:** `64091830` stoch_pfad_summe · NUMERIC  
  Ein fairer Würfel wird zweimal geworfen. Wie groß ist die Wahrscheinlichkeit, mindestens eine Sechs zu werfen? Gib die Wahrscheinlichkeit als Bruch an.  
  richtig: **11/36** · falsch: **25/36**
- ⚠ **Fachbegriff:** „Gegenereignis“ ist ein Fachbegriff.
  - **Vorschlag Klartext:** „Rechnet die Wahrscheinlichkeit für das Gegenteil aus, etwa „keine Sechs“ statt „mindestens eine Sechs“, und zieht sie am Ende nicht von 1 ab.“

### `immer_aufgerundet`

5 Aufgaben · runden_ueberschlag

- **Klartext:** „Es wurde aufgerundet, obwohl abgerundet werden muss.“
- **Erklärung:** „Ob auf- oder abgerundet wird, entscheidet die erste Ziffer, die wegfällt: bei 0 bis 4 wird abgerundet, bei 5 bis 9 aufgerundet. Hier wurde unabhängig davon aufgerundet, das Ergebnis liegt deshalb eine Einheit der letzten Stelle zu hoch.“
- **Beispiel:** `4ff59e5f` runden_ueberschlag · NUMERIC  
  Runde auf eine Nachkommastelle. 3,71 = ?  
  richtig: **3,7** · falsch: **3,8**

### `irrational_verwechselt`

4 Aufgaben · zahl_wurzel_irrational

- **Klartext:** „Hält Wurzeln aus Quadratzahlen oder periodische Dezimalzahlen für irrational, oder umgekehrt.“
- **Erklärung:** „Irrational sind Zahlen, die sich nicht als Bruch schreiben lassen, etwa √2 oder π. √16 = 4 und 0,333… = 1/3 sind dagegen rational. Hier wurde eine solche Zahl falsch eingeordnet. Geübt wird, jede Zahl erst zu vereinfachen und dann zu fragen: Gibt es einen Bruch dafür?“
- **Beispiel:** `0b7e781c` zahl_wurzel_irrational · NUMERIC  
  Für wie viele natürliche Zahlen n von 1 bis 60 (jeweils einschließlich) ist √n eine rationale Zahl? Gib die Anzahl als ganze Zahl an.  
  richtig: **7** · falsch: **0**

### `komma_ignoriert`

9 Aufgaben · dezimal_mult

- **Klartext:** „Beim Malnehmen von Kommazahlen wurde das Komma im Ergebnis weggelassen.“
- **Erklärung:** „Gerechnet wurde mit den Ziffern ohne Komma, etwa 6 · 4 = 24 für 0,6 · 0,4, und das Komma danach nicht wieder gesetzt. Die Ziffern stimmen also, nur die Größe nicht: Das Ergebnis ist um ein Vielfaches zu groß.“
- **Beispiel:** `0cbaacfd` dezimal_mult · NUMERIC  
  Berechne. 0,6 · 0,4 = ?  
  richtig: **0,24** · falsch: **24**

### `komma_nicht_verschoben`

9 Aufgaben · dezimal_div

- **Klartext:** „Beim Teilen durch eine Kommazahl wurde das Komma nicht bei beiden Zahlen verschoben.“
- **Erklärung:** „Um durch 0,6 zu teilen, verschiebt man das Komma bei beiden Zahlen um eine Stelle: Aus 4,8 : 0,6 wird 48 : 6 = 8. Geschieht das nur bei einer der beiden Zahlen, ist das Ergebnis zehnmal zu klein.“
- **Beispiel:** `1debff4f` dezimal_div · NUMERIC  
  Eine Schnur ist 4,8 m lang. Sie wird in Stücke von je 0,6 m geschnitten. Wie viele Stücke sind das?  
  richtig: **8** · falsch: **0,8**

### `kommastellen_zu_viel`

12 Aufgaben · dezimal_mult, zahl_wurzel_quadrat

- **Klartext:** „Das Komma steht im Ergebnis eine Stelle zu weit links, etwa 0,6 · 0,4 = 0,024 statt 0,24.“
- **Erklärung:** „Bei Kommazahlen hängt die Lage des Kommas im Ergebnis an einer Zählregel; 0,6 · 0,4 hat zwei Stellen nach dem Komma. Hier wurde eine Stelle zu viel gezählt, das Ergebnis ist zehnmal zu klein; ein kurzer Überschlag macht das sichtbar.“
- **Beispiel:** `0cbaacfd` dezimal_mult · NUMERIC  
  Berechne. 0,6 · 0,4 = ?  
  richtig: **0,24** · falsch: **0,024**

### `kommastellen_zu_wenig`

12 Aufgaben · dezimal_mult, potenzen, zahl_wurzel_naeherung, zahl_wurzel_quadrat

- **Klartext:** „Das Ergebnis hat zu wenige Stellen nach dem Komma, weil das Komma verrutscht ist oder zu grob gerundet wurde.“
- **Erklärung:** „Bei 0,6 · 0,4 = 2,4 statt 0,24 steht das Komma eine Stelle zu weit rechts, das Ergebnis ist zehnmal zu groß; ein Überschlag zeigt das, denn zwei Zahlen kleiner als 1 ergeben malgenommen wieder eine Zahl kleiner als 1. In anderen Fällen wurde auf weniger Stellen gerundet als verlangt, etwa 3,3 statt 3,32.“
- **Beispiel:** `0cbaacfd` dezimal_mult · NUMERIC  
  Berechne. 0,6 · 0,4 = ?  
  richtig: **0,24** · falsch: **2,4**

### ⚠ `koordinate_vorzeichen_verloren`

1 Aufgaben · gleichung_lgs_grafisch

- **Klartext:** „Koordinate richtig abgelesen, aber das Minus fehlt.“
- **Erklärung:** „Der Abstand zum Ursprung stimmt, nur die Richtung ist verloren: ein Punkt links der y-Achse oder unterhalb der x-Achse bekommt eine positive Koordinate. Das ist kein Rechenfehler, sondern eine Frage der Achsenrichtung. Geuebt wird, die negativen Abschnitte der Achsen als eigene Richtung zu lesen.“
- **Beispiel:** `6bc7dd64` gleichung_lgs_grafisch · MULTI_PART (Teil 1: x =)  
  Die Geraden f und g gehören zu einem linearen Gleichungssystem. Gib die Lösung des Gleichungssystems an. Lies dazu den Schnittpunkt der beiden Geraden ab.  
  richtig: **-2** · falsch: **2**
- ⚠ **Tippfehler:** In der Erklärung steht „Geuebt“ statt „Geübt“. Der Klartext passt.
  - **Vorschlag Erklärung:** „Der Abstand zum Ursprung stimmt, nur die Richtung ist verloren: ein Punkt links der y-Achse oder unterhalb der x-Achse bekommt eine positive Koordinate. Das ist kein Rechenfehler, sondern eine Frage der Achsenrichtung. Geübt wird, die negativen Abschnitte der Achsen als eigene Richtung zu lesen.“

### ⚠ `koordinaten_vertauscht`

4 Aufgaben · gleichung_lgs_grafisch

- **Klartext:** „Liest x- und y-Koordinate in vertauschter Reihenfolge ab.“
- **Erklärung:** „Der Punkt wird richtig gefunden, aber die beiden Werte stehen in der falschen Reihenfolge: zuerst der Wert an der senkrechten Achse, dann der an der waagerechten. Im Koordinatenpaar steht immer zuerst x (nach rechts oder links), dann y (nach oben oder unten). Geuebt wird die feste Reihenfolge beim Ablesen und beim Eintragen.“
- **Beispiel:** `635ae61a` gleichung_lgs_grafisch · MULTI_PART (Teil 1: x =)  
  Die Geraden f und g im Koordinatensystem gehören zu den beiden Gleichungen eines linearen Gleichungssystems. Lies die Lösung des Gleichungssystems am Schnittpunkt der Geraden ab.  
  richtig: **2** · falsch: **3**
- ⚠ **Tippfehler:** In der Erklärung steht „Geuebt“ statt „Geübt“. Der Klartext passt.
  - **Vorschlag Erklärung:** „Der Punkt wird richtig gefunden, aber die beiden Werte stehen in der falschen Reihenfolge: zuerst der Wert an der senkrechten Achse, dann der an der waagerechten. Im Koordinatenpaar steht immer zuerst x (nach rechts oder links), dann y (nach oben oder unten). Geübt wird die feste Reihenfolge beim Ablesen und beim Eintragen.“

### `loesungsanzahl_verwechselt`

3 Aufgaben · gleichung_lgs_addition, gleichung_lgs_grafisch

- **Klartext:** „Verwechselt „keine Lösung“ und „unendlich viele Lösungen“.“
- **Erklärung:** „Ein Gleichungssystem kann genau eine, keine oder unendlich viele Lösungen haben. Parallele Geraden schneiden sich nie: keine Lösung. Liegen beide Geraden aufeinander, ist jeder Punkt gemeinsam: unendlich viele. Hier wurden die beiden Sonderfälle vertauscht. Geübt wird, das Ende der Rechnung zu lesen: Eine falsche Aussage wie 0 = 5 heißt keine Lösung, eine wahre wie 0 = 0 heißt unendlich viele.“
- **Beispiel:** `4888b388` gleichung_lgs_grafisch · MC  
  Die Geraden f und g im Koordinatensystem gehören zu den beiden Gleichungen eines linearen Gleichungssystems. Wie viele Lösungen hat das Gleichungssystem?  
  richtig: **keine Lösung** · falsch: **unendlich viele Lösungen**

### `m_b_vertauscht`

6 Aufgaben · fkt_linear_gleichung, fkt_linear_yabschnitt

- **Klartext:** „Liest Steigung und y-Achsenabschnitt vertauscht aus der Gleichung ab.“
- **Erklärung:** „In y = mx + b steht die Steigung immer beim x, der y-Achsenabschnitt ist die Zahl ohne x. Hier wurden beide Zahlen richtig gefunden, aber die Rollen getauscht. Geübt wird, zuerst nach dem x zu suchen – die Zahl davor ist die Steigung.“
- **Beispiel:** `de54e58b` fkt_linear_yabschnitt · NUMERIC  
  Gegeben ist die Funktion f(x) = 3x + 5. Gib den y-Achsenabschnitt des Graphen von f an.  
  richtig: **5** · falsch: **3**

### `mal_exponent`

23 Aufgaben · potenzen, term_binom_quadrat, zahl_wurzel_teilweise

- **Klartext:** „Die Hochzahl wurde als Faktor genommen, etwa 3² als 3 · 2 = 6 statt 3 · 3 = 9.“
- **Erklärung:** „Eine Hochzahl gibt an, wie oft eine Zahl mit sich selbst malgenommen wird. Die Verwechslung mit einfachem Malnehmen liegt nahe, weil beide Zahlen direkt nebeneinanderstehen; sie zeigt sich auch dort, wo etwas über mehrere Schritte wächst oder schrumpft oder eine Formel ein Quadrat enthält.“
- **Beispiel:** `01f22500` potenzen · NUMERIC  
  Berechne. 3^2 = ?  
  richtig: **9** · falsch: **6**

### ⚠ `mal_zwei_vergessen`

4 Aufgaben · term_binom_quadrat

- **Klartext:** „Ein nötiges Verdoppeln wurde weggelassen.“
- **Erklärung:** „Manche Formeln enthalten ein „mal 2“, etwa weil ein Quader jede Seitenfläche zweimal hat oder ein Zylinder zwei Deckel. Fehlt dieser Faktor, stimmt der Rest der Rechnung oft, ein Teil geht aber nur einfach statt doppelt ein, und das Ergebnis weicht entsprechend ab.“
- **Beispiel:** `ae6fa0b8` term_binom_quadrat · MC  
  Multipliziere aus. Welcher Term ist richtig? (x + 3)² = ?  
  richtig: **x² + 6x + 9** · falsch: **x² + 3x + 9**
- ⚠ **Erklärung passt nicht zu den Aufgaben:** Alle 4 Aufgaben sind binomische Formeln (x² + 3x + 9 statt x² + 6x + 9; 49² = 2451). Die Erklärung spricht von Quader und Zylinder. Der Klartext ist so allgemein, dass Eltern den Fehler nicht wiedererkennen.
  - **Vorschlag Klartext:** „Vergisst beim mittleren Glied das Verdoppeln: (x + 3)² = x² + 3x + 9 statt x² + 6x + 9.“
  - **Vorschlag Erklärung:** „In (a + b)² = a² + 2ab + b² kommt das Produkt ab zweimal vor, einmal als a · b und einmal als b · a. Hier wurde es nur einmal gezählt, das mittlere Glied ist deshalb nur halb so groß. Geübt wird, die Klammer einmal als (a + b) · (a + b) auszuschreiben.“

### `nicht_alle_glieder_multipliziert`

3 Aufgaben · gleichung_lgs_addition

- **Klartext:** „Multipliziert beim Additionsverfahren nur einen Teil der Gleichung mit dem Faktor.“
- **Erklärung:** „Beim Additionsverfahren wird eine Gleichung mit einer Zahl malgenommen, damit sich danach eine Variable weghebt. Das muss für jedes Glied auf beiden Seiten gelten, sonst ist es nicht mehr dieselbe Gleichung. Hier wurde ein Glied vergessen, meist die Zahl auf der rechten Seite. Geübt wird, nach dem Malnehmen jedes Glied einzeln abzuhaken.“
- **Beispiel:** `b0a46ab7` gleichung_lgs_addition · MULTI_PART (Teil 1: x =)  
  Löse das Gleichungssystem mit dem Additionsverfahren. Multipliziere dazu Gleichung II mit 2. I: 2x + 3y = 13 II: x + y = 5  
  richtig: **2** · falsch: **-3**

### ⚠ `nur_ein_pfad`

5 Aufgaben · stoch_pfad_summe

- **Klartext:** „Berücksichtigt bei einem Ereignis nur einen von mehreren passenden Pfaden.“
- **Erklärung:** „Gehören zu einem Ereignis mehrere Pfade, etwa „einmal rot und einmal blau“ in beiden Reihenfolgen, werden ihre Wahrscheinlichkeiten addiert. Hier wurde nur ein Pfad gezählt, das Ergebnis ist deshalb zu klein. Geübt wird, vor dem Rechnen alle passenden Pfade aufzulisten.“
- **Beispiel:** `939baa76` stoch_pfad_summe · NUMERIC  
  Eine faire Münze wird zweimal geworfen. Wie groß ist die Wahrscheinlichkeit, genau einmal Kopf zu werfen? Gib die Wahrscheinlichkeit als Bruch, als Dezimalzahl oder in Prozent an.  
  richtig: **1/2** · falsch: **1/4**
- ⚠ **Fachbegriff:** „Pfad“ ist ein Fachbegriff aus dem Baumdiagramm.
  - **Vorschlag Klartext:** „Zählt nur einen von mehreren passenden Wegen, etwa nur „erst Kopf, dann Zahl“ und nicht auch „erst Zahl, dann Kopf“.“

### `nur_eine_grundseite`

6 Aufgaben · geo_flaeche_trapez

- **Klartext:** „Rechnet beim Trapez nur mit einer der beiden parallelen Seiten.“
- **Erklärung:** „Die Fläche eines Trapezes ist der Mittelwert der beiden parallelen Seiten mal der Höhe. Hier wurde nur eine der beiden Seiten verwendet, so als wäre das Trapez ein Parallelogramm. Geübt wird, zuerst beide parallelen Seiten zu markieren.“
- **Beispiel:** `4bfe5d6e` geo_flaeche_trapez · NUMERIC  
  Ein Trapez hat die parallelen Seiten a = 8 cm und c = 4 cm und die Höhe h = 5 cm. Wie groß ist sein Flächeninhalt?  
  richtig: **30** · falsch: **20**

### `nur_einmal_addiert`

1 Aufgaben · fkt_linear_steigung

- **Klartext:** „Ein Betrag wurde nur einmal dazugezählt, obwohl er mehrfach vorkommt.“
- **Erklärung:** „Ein Rechteck hat zwei lange und zwei kurze Seiten, und eine Gerade mit der Steigung 2 steigt bei drei Schritten nach rechts um dreimal 2. Hier wurde jeweils nur einmal addiert; das Ergebnis ist deshalb zu klein.“
- **Beispiel:** `7cd1b9af` fkt_linear_steigung · NUMERIC  
  Eine Gerade hat die Steigung 2 und geht durch den Punkt P(1 | 3). Welche y-Koordinate hat der Punkt der Geraden mit der x-Koordinate 4?  
  richtig: **9** · falsch: **5**

### `parallele_uebersehen`

3 Aufgaben · gleichung_lgs_addition, gleichung_lgs_grafisch

- **Klartext:** „Nimmt genau eine Lösung an, obwohl die Geraden parallel sind oder aufeinander liegen.“
- **Erklärung:** „Zwei Geraden schneiden sich genau dann in einem Punkt, wenn ihre Steigungen verschieden sind. Bei gleicher Steigung sind sie parallel oder liegen aufeinander. Hier wurde ein Schnittpunkt angenommen, ohne die Steigungen zu vergleichen. Geübt wird, beide Gleichungen in die Form y = mx + b zu bringen und zuerst die Steigungen zu vergleichen.“
- **Beispiel:** `4888b388` gleichung_lgs_grafisch · MC  
  Die Geraden f und g im Koordinatensystem gehören zu den beiden Gleichungen eines linearen Gleichungssystems. Wie viele Lösungen hat das Gleichungssystem?  
  richtig: **keine Lösung** · falsch: **genau eine Lösung**

### ⚠ `pfadregel_addiert`

3 Aufgaben · stoch_pfad_summe

- **Klartext:** „Addiert die Wahrscheinlichkeiten entlang eines Pfades, statt sie zu multiplizieren.“
- **Erklärung:** „Bei Zufallsversuchen in mehreren Stufen wird entlang eines Pfades multipliziert: Erst rot und dann noch einmal rot ist ein Anteil vom Anteil. Wer addiert, bekommt ein zu großes Ergebnis, manchmal sogar mehr als 1, und das kann keine Wahrscheinlichkeit sein. Geübt wird die Merkregel „erst …, dann … heißt mal“.“
- **Beispiel:** `64091830` stoch_pfad_summe · NUMERIC  
  Ein fairer Würfel wird zweimal geworfen. Wie groß ist die Wahrscheinlichkeit, mindestens eine Sechs zu werfen? Gib die Wahrscheinlichkeit als Bruch an.  
  richtig: **11/36** · falsch: **1/3**
- ⚠ **Fachbegriff, passt nicht ganz zur Beispielantwort:** „Pfad“ ist ein Fachbegriff. In allen 3 Aufgaben entsteht die falsche Antwort, weil die Einzelwahrscheinlichkeiten der Versuche addiert wurden (1/6 + 1/6 = 1/3 bei „mindestens eine Sechs“, 0,2 + 0,2 + 0,2). Das geschieht nicht „entlang eines Pfades“. Der Vorschlag ist deshalb allgemeiner.
  - **Vorschlag Klartext:** „Zählt Wahrscheinlichkeiten zusammen, wo sie malgenommen werden müssen, etwa bei „erst …, dann …“ oder bei mehreren Versuchen hintereinander.“

### `plus_statt_mal`

11 Aufgaben · geo_flaeche_drachen_raute, geo_flaeche_term, zahl_wurzel_gesetze

- **Klartext:** „Es wurde addiert, wo malgenommen werden muss.“
- **Erklärung:** „Bei Flächen und Rauminhalten werden Längen miteinander malgenommen, beim Umfang dagegen addiert. Werden die beiden Rechenarten verwechselt, ist das Ergebnis meist zu klein; dasselbe zeigt sich beim Rechnen mit Zehnerpotenzen oder Wurzeln.“
- **Beispiel:** `46192474` geo_flaeche_term · MC  
  Ein Rechteck ist x cm lang und 5 cm breit. Welcher Term beschreibt seinen Flächeninhalt in cm²?  
  richtig: **5x** · falsch: **x + 5**

### ⚠ `quadratdifferenz_vorzeichen`

13 Aufgaben · term_binom_faktorisieren, term_binom_gemischt, term_binom_quadratdifferenz

- **Klartext:** „Vorzeichen im Ergebnis gekippt – a²+b² statt a²−b².“
- **Erklärung:** „Bei (a+b)·(a−b) hebt sich das mittlere Glied auf, und das hintere Quadrat wird abgezogen, nicht addiert. Hier ist die Struktur erkannt, nur das Vorzeichen des letzten Glieds ist gekippt. Der Rechenweg stimmt also – geübt wird gezielt der Punkt, an dem Plus und Minus zusammentreffen.“
- **Beispiel:** `293413f8` term_binom_quadratdifferenz · MC  
  Multipliziere aus. Welcher Term ist richtig? (x + 4)(x - 4) = ?  
  richtig: **x² - 16** · falsch: **x² + 16**
- ⚠ **Fachbegriff:** „a²+b² statt a²−b²“ ohne Bezug zur Aufgabe ist für Eltern abstrakt.
  - **Vorschlag Klartext:** „Schreibt bei (a + b)(a − b) am Ende Plus statt Minus: (x + 4)(x − 4) = x² + 16 statt x² − 16.“

### `rechter_winkel_falsche_ecke`

3 Aufgaben · geo_winkel_thales

- **Klartext:** „Setzt beim Satz des Thales den rechten Winkel an die falsche Ecke.“
- **Erklärung:** „Liegt eine Dreiecksseite als Durchmesser in einem Kreis und die dritte Ecke auf dem Kreis, dann ist der Winkel an dieser dritten Ecke ein rechter. Hier wurde der rechte Winkel an einer Ecke des Durchmessers angenommen. Geübt wird, den Durchmesser zu suchen und den Winkel gegenüber zu markieren.“
- **Beispiel:** `11aebc7c` geo_winkel_thales · NUMERIC  
  Ein Fenster hat oben einen Halbkreisbogen. Die waagerechte Unterkante AB des Bogens ist ein Durchmesser des Halbkreises. Eine gerade Strebe verläuft von A zu einem Punkt C auf dem Bogen, eine zweite von C zu B. Die Strebe AC bildet mit der Unterkante einen Winkel von 32°. Wie groß ist der Winkel zwischen der Strebe CB und der Unterkante?  
  richtig: **58** · falsch: **90**

### `seiten_ungleich_verknuepft`

4 Aufgaben · gleichung_lgs_addition

- **Klartext:** „Verknüpft die beiden Gleichungen links und rechts unterschiedlich – links subtrahiert, rechts addiert oder umgekehrt.“
- **Erklärung:** „Beim Additionsverfahren werden zwei Gleichungen Seite für Seite verrechnet: Was links passiert, muss genauso rechts passieren. Hier wurden die linken Seiten voneinander abgezogen, die rechten aber zusammengezählt (oder umgekehrt). Die Variable fällt zwar weg, das Ergebnis stimmt aber nicht. Geübt wird, die Rechenart einmal für beide Seiten festzulegen und dazuzuschreiben.“
- **Beispiel:** `04167489` gleichung_lgs_addition · MULTI_PART (Teil 1: x =)  
  Löse das Gleichungssystem mit dem Additionsverfahren. I: x + 2y = 12 II: x - 2y = 4  
  richtig: **8** · falsch: **4**

### `steigung_kehrwert`

7 Aufgaben · fkt_linear_gleichung, fkt_linear_steigung

- **Klartext:** „Teilt die waagerechte durch die senkrechte Änderung – die Steigung steht auf dem Kopf.“
- **Erklärung:** „Die Steigung gibt an, um wie viel der Graph nach oben geht, wenn man einen Schritt nach rechts geht. Gerechnet wird also „hoch durch rüber“. Hier wurde umgekehrt geteilt: Beide Änderungen sind richtig abgelesen, nur steht der Bruch auf dem Kopf. Geübt wird die feste Reihenfolge am Steigungsdreieck.“
- **Beispiel:** `a0451e78` fkt_linear_steigung · NUMERIC  
  Eine Gerade geht durch die Punkte A(0 | 1) und B(2 | 5). Berechne die Steigung m der Geraden.  
  richtig: **2** · falsch: **1/2**

### ⚠ `stellenwert_ignoriert`

8 Aufgaben · dezimal_add_sub

- **Klartext:** „Beim Rechnen mit Kommazahlen wurden die Stellen nicht richtig miteinander verrechnet.“
- **Erklärung:** „Bei 0,25 + 0,4 gehört die 4 zu den Zehnteln, also unter die 2 und nicht unter die 5, und ein Übertrag von einer Stelle zur nächsten muss mitgenommen werden. Wird eine Ziffer der falschen Stelle zugeordnet oder ein Übertrag vergessen, ist das Ergebnis falsch, obwohl jede Einzelrechnung für sich stimmt.“
- **Beispiel:** `024143bf` dezimal_add_sub · NUMERIC  
  Berechne. 0,25 + 0,4 = ?  
  richtig: **0,65** · falsch: **0,29**
- ⚠ **ungenau:** „nicht richtig miteinander verrechnet“ sagt nicht, was passiert ist. In fast allen Aufgaben wurde nicht Stelle unter Stelle gerechnet (0,25 + 0,4 = 0,29).
  - **Vorschlag Klartext:** „Schreibt Kommazahlen nicht Stelle unter Stelle und rechnet so Zehntel mit Hundertsteln zusammen: 0,25 + 0,4 = 0,29 statt 0,65.“

### `teilflaeche_vergessen`

1 Aufgaben · geo_flaeche_term

- **Klartext:** „Lässt bei einer zusammengesetzten Figur eine Teilfläche weg.“
- **Erklärung:** „Zusammengesetzte Figuren werden in einfache Teile zerlegt, deren Flächen man addiert oder abzieht. Hier fehlt eine Teilfläche im Ergebnis. Geübt wird, die Zerlegung erst vollständig zu skizzieren und jede Teilfläche abzuhaken.“
- **Beispiel:** `11390e1a` geo_flaeche_term · MC  
  Eine Figur besteht aus einem Rechteck und einem Quadrat. Das Rechteck ist x cm lang und 4 cm breit. An eine 4 cm lange Seite des Rechtecks ist ein Quadrat mit der Seitenlänge 4 cm angesetzt. Welcher Term beschreibt den Flächeninhalt der ganzen Figur in cm²?  
  richtig: **4x + 16** · falsch: **4x**

### `uebertrag_vergessen`

3 Aufgaben · dezimal_add_sub

- **Klartext:** „Beim Addieren von Kommazahlen wurde der Übertrag vor das Komma vergessen.“
- **Erklärung:** „0,8 + 0,7 sind 15 Zehntel, also 1,5. Hier wurden die 15 Zehntel als 0,15 hingeschrieben, statt zehn davon als ganze Eins vor das Komma zu übertragen.“
- **Beispiel:** `0cb5d1f1` dezimal_add_sub · NUMERIC  
  Berechne. 0,8 + 0,7 = ?  
  richtig: **1,5** · falsch: **0,15**

### `umfang_statt_flaeche`

7 Aufgaben · geo_flaeche_drachen_raute, geo_flaeche_term, term_binom_quadrat, zahl_wurzel_gesetze

- **Klartext:** „Statt der Fläche wurde der Umfang berechnet.“
- **Erklärung:** „Fläche und Umfang werden aus denselben Längen berechnet, aber mit verschiedenen Formeln. Weil beide Formeln meist direkt nebeneinander gelernt werden, wird leicht die falsche gewählt; die Rechnung selbst stimmt dann oft.“
- **Beispiel:** `46192474` geo_flaeche_term · MC  
  Ein Rechteck ist x cm lang und 5 cm breit. Welcher Term beschreibt seinen Flächeninhalt in cm²?  
  richtig: **5x** · falsch: **2x + 10**

### `umgekehrt_geteilt`

4 Aufgaben · bruch_dezimal

- **Klartext:** „Beim Teilen wurde die Reihenfolge umgedreht, etwa 1/5 als 5 : 1 gerechnet.“
- **Erklärung:** „Ein Bruch wie 1/5 bedeutet 1 geteilt durch 5, also 0,2; auch eine Wahrscheinlichkeit ist „passende Fälle geteilt durch alle Fälle“. Wird umgekehrt geteilt, kommt das umgedrehte Verhältnis heraus, oft erkennbar an einem Ergebnis über 1 oder über 100 %.“
- **Beispiel:** `3768ecdc` bruch_dezimal · NUMERIC  
  Schreibe den Bruch als Dezimalzahl. 1/5 = ?  
  richtig: **0,2** · falsch: **5**

### `wurzel_gliedweise`

4 Aufgaben · term_binom_faktorisieren, zahl_wurzel_gesetze

- **Klartext:** „Zieht die Wurzel aus einer Summe Glied für Glied: √(9 + 16) als √9 + √16.“
- **Erklärung:** „Die Wurzel aus einer Summe ist nicht die Summe der Wurzeln: √(9 + 16) = √25 = 5, aber √9 + √16 = 7. Beim Satz des Pythagoras führt das zu c = a + b, also zu einer viel zu langen Seite. Geübt wird, unter der Wurzel zuerst auszurechnen und erst dann die Wurzel zu ziehen.“
- **Beispiel:** `88c99e21` zahl_wurzel_gesetze · NUMERIC  
  Zwei quadratische Beete haben die Flächeninhalte 9 m² und 16 m². Sie sollen durch ein einziges quadratisches Beet ersetzt werden, das genau so groß ist wie beide zusammen. Wie lang ist eine Seite des neuen Beets? Gib das Ergebnis exakt an.  
  richtig: **5** · falsch: **7**

### `wurzel_halbiert`

23 Aufgaben · potenzen, zahl_wurzel_gesetze, zahl_wurzel_naeherung, zahl_wurzel_quadrat, zahl_wurzel_teilweise

- **Klartext:** „Statt die Wurzel zu ziehen, wurde die Zahl halbiert, etwa √36 = 18 statt 6.“
- **Erklärung:** „Die Wurzel ist die Zahl, die mit sich selbst malgenommen den Wert unter dem Wurzelzeichen ergibt: √36 = 6, weil 6 · 6 = 36. Das Halbieren ist dieselbe Verwechslung wie 3² = 6, nur in umgekehrter Richtung.“
- **Beispiel:** `aef364ee` potenzen · NUMERIC  
  Berechne. √36 = ?  
  richtig: **6** · falsch: **18**

### `ziffern_gelesen`

6 Aufgaben · bruch_dezimal

- **Klartext:** „Zähler und Nenner wurden hinter das Komma geschrieben, etwa 1/5 als 0,15.“
- **Erklärung:** „Ein Bruch ist eine Teilung: 1/5 heißt 1 : 5 = 0,2. Werden die beiden Zahlen einfach hintereinander hinter das Komma geschrieben, wird der Bruch wie eine Schreibweise behandelt und nicht wie eine Rechnung.“
- **Beispiel:** `3768ecdc` bruch_dezimal · NUMERIC  
  Schreibe den Bruch als Dezimalzahl. 1/5 = ?  
  richtig: **0,2** · falsch: **0,15**

### `zuruecklegen_ignoriert`

3 Aufgaben · stoch_pfad_summe

- **Klartext:** „Rechnet beim Ziehen ohne Zurücklegen im zweiten Zug mit der alten Anzahl weiter (oder umgekehrt).“
- **Erklärung:** „Wird eine gezogene Kugel nicht zurückgelegt, liegt beim zweiten Zug eine Kugel weniger in der Urne, und von der gezogenen Farbe auch eine weniger. Hier wurde der zweite Zug so gerechnet, als wäre noch alles da (oder beim Zurücklegen so, als fehlte eine). Geübt wird, vor jedem Zug den neuen Inhalt der Urne kurz aufzuschreiben.“
- **Beispiel:** `2d6edc4b` stoch_pfad_summe · NUMERIC  
  In einer Lostrommel liegen 10 Lose, 3 davon sind Gewinne. Es werden nacheinander zwei Lose gezogen, ein gezogenes Los kommt nicht zurück. Wie groß ist die Wahrscheinlichkeit, genau ein Gewinnlos zu ziehen? Gib die Wahrscheinlichkeit als Bruch an.  
  richtig: **7/15** · falsch: **0,42**

## Zuordnung auffällig (kein Textproblem, nicht Teil von 130500)

Umgesetzt in PR fix/rasit-known-errors (Migration 20261016160100).

Bei diesen Fundstellen passt die falsche Antwort nicht zum Slug, unabhängig vom Text. Ändern ließe sich das nur in der
Akzeptanz der Aufgabe (`known_errors`), nicht in `fehlbild_labels`.

| Aufgabe | Knoten | falsche Antwort | Slug | Warum es nicht passt |
|---|---|---|---|---|
| `bb125765` | potenzen | 1,05³ → 1,1025 | basis_exponent_vertauscht | 1,1025 ist 1,05², nichts vertauscht |
| `88ca2551` | term_binom_faktorisieren | 47² − 43² → 90 | faktorisierung_unvollstaendig | 90 = 47 + 43, der Faktor (47 − 43) fehlt; nichts ausgeklammert |
| `21f1c9f4` | dezimal_mult | 0,25 · 12 → 30 | komma_ignoriert | ohne Komma wäre es 25 · 12 = 300 |
| `ef90a8ac` | zahl_wurzel_teilweise | 6 · √3 = √b → 36 | mal_exponent | **passt doch** (nachgerechnet 16.10.): 6² als 6 · 2 = 12, dann 12 · 3 = 36 |
| `b2bc0cfc`, `f54b2f2c` | term_binom_faktorisieren, term_binom_quadrat | x² + 8x + 16 → (x + 8)²; x² + 20x + 100 → (x + 20)² | quadrat_gliedweise | Die Zahl vor dem x wurde als b gelesen, gliedweise wurde nicht quadriert |
| `20321d30` | dezimal_add_sub | 3,2 − 0,85 → 2,45 | stellenwert_ignoriert | Fehler beim Entbündeln, die Stellen stehen richtig untereinander |
