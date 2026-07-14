# R01 — Diff: Altbestand gegen Neuextraktion

**Alt:** `data/vera8_komplett_enriched.json` · **Neu:** `data/vera8_v2.json` · **299 Items**, beide Seiten deckungsgleich.

Kein Import, kein DB-Schreibvorgang, kein Item auf `ready`. Alle 299 neuen Items stehen auf `draft`.

---

## Vorbehalt: der Lauf ist nicht vollstaendig

Bevor irgendeine Zahl hier gelesen wird — **106 der 299 Items haben keine Vision-Lesung** (`data/r01_vision/` enthaelt 193 Dateien), und **148 Items haben deshalb null Teilaufgaben**. Fuer diese Items ist die Neuextraktion leer — nicht schlecht, sondern *nicht gelaufen*.

Das faerbt jede Zahl unten. Der Topf *beide defekt* ist zu einem grossen Teil kein Qualitaetsbefund, sondern eine offene Pipeline-Stufe. Und die entscheidende Zahl (LSA-Pool) ist eine **Untergrenze**: sie kann nur steigen, wenn die Vision-Stufe fuer die restlichen Items nachlaeuft.

### Und der Bau ist aelter als die Vision-Lesungen

Schwerwiegender: **fuer 22 Items liegt eine brauchbare Vision-Lesung auf der Platte, die `vera8_v2.json` nicht enthaelt.** Die Vision-Stufe lief weiter, waehrend der Bau schon geschrieben war — `data/r01_vision/` enthaelt 27 Dateien, die juenger sind als `vera8_v2.json`. Der Bau hat sie nie gesehen.

Das ist **kein Extraktionsfehler**. Ein erneuter Lauf von `ground_all.py` holt sie herein — ohne dass eine einzige Datei neu extrahiert werden muss. Betroffen:

| Item | Teilaufgaben in der Vision-Lesung |
|---|---:|
| Bonbons | 1 |
| Division von Zahlen | 1 |
| Freunde | 4 |
| Hauptstädte | 2 |
| Judomatte | 1 |
| Nachfolgerzahl | 2 |
| Papier | 1 |
| Pyramidenbau | 1 |
| Quadrat zeichnen | 1 |
| Rubbellose | 2 |
| Schnittpunkt von Graphen | 1 |
| Schwarz-Weiß-Würfel | 2 |
| Sprechstunde | 2 |
| Tankinhalt | 1 |
| Temperaturdifferenz | 1 |
| Tombola zum Schulfest | 2 |
| Traktor | 1 |
| Trapezvariation | 2 |
| Ungewöhnlicher Spielwürfel | 2 |
| Verkehrszeichen | 5 |
| Verlauf des Graphen | 2 |
| Zahlenwürfel | 3 |

Darunter **`Papier`** und **`Temperaturdifferenz`** — zwei der vier importierten Items, die unten als "Abweichung" auftauchen. Ihre Vision-Lesung ist da und sauber (`22 mm`, `19 °C` — exakt die importierten Werte); sie steht nur nicht im Bau.

---

## Die vier Toepfe

| Topf | Items | Bedeutung |
|---|---:|---|
| identisch | 14 | beide Seiten sauber |
| neu besser | 38 | alt defekt, neu sauber |
| **neu schlechter** | 21 | alt sauber, neu defekt — **der wichtige Topf** |
| beide defekt | 226 | keine Version brauchbar |

*Defekt* heisst: fehlender Stamm, fehlende Loesung, nachweislich zerstoerter Stamm (S1–S4), blockierendes Gate-Flag oder unbenutzbarer Loesungsschluessel (N1–N3). *Defekt* heisst **nicht** "nicht auto-gradebar" — ein sauberes FREE_TEXT-Item ist nicht defekt.

## Der wichtige Topf: neu schlechter

21 Items — in zwei Gruppen, denn nur die zweite ist ein echter Rueckschritt.

### a) Vision-Stufe nie gelaufen (12)

Kein Rueckschritt der Extraktion, sondern eine **offene Pipeline-Stufe**: Der Altbestand hat hier einen brauchbaren Datensatz, die Neuextraktion (noch) nichts. Nachlaufen lassen, dann neu bewerten.

| Item | alter Status |
|---|---|
| Ecken an Pyramiden (`eckenanpyramiden`) | ready |
| Gleichung lösen 2 (`gleichungloesen2`) | ready |
| Quadrat im Koordinatensystem (`koordinatensystem`) | ready |
| Rauminhalt von Prismen (`rauminhaltvonprismen`) | ready |
| Schokoladenpreis (`schokoladenpreis`) | ready |
| Strecke im Koordinatenkreuz (`streckeimkoordinatenkreuz`) | ready |
| Säulenhöhe (`saeulenhoehe`) | ready |
| Umfang und Fläche (`umfangundflaeche`) | ready |
| Unfertiger Würfel (`unfertigerwuerfel`) | ready |
| Winkel im Dreieck (`winkelimdreieck`) | ready |
| Zwei Thermometeranzeigen (`thermometeranzeigen`) | ready |
| Zwischen zwei Zahlen (`zwischenzweizahlen`) | ready |

### b) Echter Rueckschritt (9)

Vision ist gelaufen, das Ergebnis ist trotzdem schlechter als der Altbestand. Jedes Item einzeln:

| Item | alter Status | was die Neuextraktion verliert |
|---|---|---|
| Anzahl von Nullen (`anzahlvonnullen`) | ready | G1b: part2.prompt: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat: '______' (Inhalt belegt, Zeichensetzung stammt aus der Lesung) |
| Aussagen über Dreiecke (`aussagendreiecke`) | ready | N3 Schluessel ist Kodierregel (Ta [2]) |
| Flächeninhalt (`flaecheninhalt`) | ready | G1b: part1.prompt: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat: '__________' (Inhalt belegt, Zeichensetzung stammt aus der Lesung) |
| Gewitter (`gewitter`) | ready | G1b: part1.prompt: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat: '______' (Inhalt belegt, Zeichensetzung stammt aus der Lesung) |
| Papier (`papier`) | ready | keine Teilaufgabe gelesen |
| Quadernetz (`quadernetz`) | ready | G5: Tabelle im Bild gesehen, aber keine strukturierte Tabelle rekonstruiert |
| Sterne und Sandkörner (`sterneundsandkoerner`) | ready | G1b: part1.prompt: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat: '____________' (Inhalt belegt, Zeichensetzung stammt aus der Lesung); G1b: part2.prompt: Inter |
| Suche die Zahl (`suchediezahl`) | ready | G1b: part1.prompt: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat: '☐☐☐' (Inhalt belegt, Zeichensetzung stammt aus der Lesung) |
| Temperaturdifferenz (`temperaturdifferenz`) | ready | keine Teilaufgabe gelesen |

---

## Der Altbestand zerstoert STAEMME, nicht Loesungen

### Der Mechanismus, belegt an `zeitangabe`

Der alte Stamm ist der Textinhalt der EMF-Zeichenlaeufe. Dieser Kanal kann Sonderzeichen nicht dekodieren:

```
Zeichenvorrat der Quelle : 'Wie viele Minuten sind 2    Stunden?'   <- kein ½
alter Stamm              : 'Wie viele Minuten sind 2 Stunden?'      <- 2 h = 120 min
alte Loesung             : '150min'                                 <- passt NICHT zu 2 h
neuer Stamm (Vision)     : 'Wie viele Minuten sind 2½ Stunden?'     <- 2,5 h = 150 min
```

Die Loesung war die ganze Zeit richtig — sie kommt aus der Auswertungs-Datei, einem anderen Kanal. Kaputt war der Stamm. **Ein Check "steht das Zeichen im Zeichenvorrat?" kann diese Klasse nie finden**, denn der Zeichenvorrat ist genau der Kanal, der das ½ verliert. Deshalb vergleicht dieser Diff alten gegen neuen Stamm.

Messbar ist das nur, wo **beide** Seiten einen Stamm haben (125 Items). Fuer die 148 Items ohne Vision-Lesung ist unbekannt, ob ihr alter Stamm beschaedigt ist.

### S1 — verlorene bedeutungstragende Zeichen im alten Stamm (7)

Zeichen, die der neue Stamm hat und der alte nicht: Brueche, Hoch- und Tiefstellungen, Malpunkt, echtes Minus. Jedes einzelne veraendert die Aufgabe.

| Item | verloren | alter Stamm (Auszug) | neuer Stamm (Auszug) |
|---|---|---|---|
| Dreieckszahlen | `₀₁₂₃₄₅₆ₙ` | Zahlen, die sich aus der Summe aufeinanderfolgender natürl | Zahlen, die sich aus der Summe aufeinanderfolgender natürl |
| Geraden im Koordinatensystem | `½` | 1 Die Abbildung zeigt die Gerade mit der Gleichung y=x-2.  | Die Abbildung zeigt die Gerade mit der Gleichung y = ½x -  |
| Körper füllen | `³` | Ein Q₃uader, dessen Kanten hier dick gezeichnet sind, ist  | Ein Quader, dessen Kanten hier dick gezeichnet sind, ist m |
| Osterhase | `³` | Das Bild zeigt drei unterschiedlich große Schokoladenoster | Das Bild zeigt drei unterschiedlich große Schokoladenoster |
| Punkte auf Geraden | `₁₂₃` | 3 Weise nach: Der Punkt A(4 / 3 )liegt auf der Geraden mit | Weise nach: Der Punkt A (4 / 3) liegt auf der Geraden mit  |
| Rauten | `²₄` | Die Eckpunkte Dx der Rauten AxBxCxDx wandern auf der Gerad | Die Eckpunkte Dx der Rauten AxBxCxDx wandern auf der Gerad |
| Zeitangabe | `½` | 1 Wie viele Minuten sind 2 Stunden? 2 60min / 90min / 150m | Wie viele Minuten sind 2½ Stunden? |

Daneben verlieren Items reine **Layoutzeichen** (`_`, `☐`, `…`) — Antwortlinien, Ankreuzkaestchen, Auslassungspunkte. Haesslich, aber nicht sinnentstellend, und darum hier nicht als Defekt gezaehlt.

### S2 — die alte Loesung passt nicht zum alten Stamm, zum neuen aber sehr wohl

S1 zu Ende gedacht: Wo der alte Stamm ein bedeutungstragendes Zeichen verloren hat, beschreibt er eine **andere Aufgabe** als die, zu der die unveraendert korrekte Loesung gehoert. Die Loesung ist der Zeuge dafuer, dass der Stamm luegt.

Zwei Faelle lassen sich **nachrechnen** — bei ihnen ist die alte Loesung aus dem alten Stamm nicht nur unwahrscheinlich, sondern *unmoeglich*:

| Item | alter Stamm | ergibt | alte Loesung | neuer Stamm | ergibt |
|---|---|---|---|---|---|
| Zeitangabe | `2 Stunden` | 120 min | **150 min** | `2½ Stunden` | **150 min** ✓ |
| Geraden im Koordinatensystem | `y = x − 2` | Nullstelle x = 2 | **x = 4** | `y = ½x − 2` | **x = 4** ✓ |

`Zeitangabe` war der Kalibrierungsfall. `Geraden im Koordinatensystem` ist derselbe Bug, unabhaengig gefunden: Der Faktor ½ vor dem x ist im alten Stamm verschwunden, damit wandert die Nullstelle von 4 auf 2 — und die gespeicherte Loesung `x = 4` passt nur noch zur *neuen* Fassung. Die Loesung war nie falsch. Der Stamm war es.

Die uebrigen S1-Faelle, jeweils mit alter Loesung:

- **Dreieckszahlen** — alte Loesung: `D5 = 15`
  - alter Stamm: `Zahlen, die sich aus der Summe aufeinanderfolgender natürlicher Zahlen ergeben, heißen Dreieckszahlen. Dreieckszahlen, b`
  - neuer Stamm: `Zahlen, die sich aus der Summe aufeinanderfolgender natürlicher Zahlen ergeben, heißen Dreieckszahlen. Dreieckszahlen, b`
- **Geraden im Koordinatensystem** — alte Loesung: `x= 4`
  - alter Stamm: `1 Die Abbildung zeigt die Gerade mit der Gleichung y=x-2. 2 y 1 x 0 1 | 5 An welcher Stelle schneidet die Gerade die x-A`
  - neuer Stamm: `Die Abbildung zeigt die Gerade mit der Gleichung y = ½x - 2 An welcher Stelle schneidet die Gerade die x-Achse? Kreuze a`
- **Körper füllen** — alte Loesung: `90cm3`
  - alter Stamm: `Ein Q₃uader, dessen Kanten hier dick gezeichnet sind, ist mit einigen kleinen 1-cm-Würfeln gefüllt. 1cm 1cm 1cm Grafik: `
  - neuer Stamm: `Ein Quader, dessen Kanten hier dick gezeichnet sind, ist mit einigen kleinen 1-cm³-Würfeln gefüllt. Wie groß ist das Vol`
- **Osterhase** — alte Loesung: `769 ODER 769,2 ODER 770`
  - alter Stamm: `Das Bild zeigt drei unterschiedlich große Schokoladenosterhasen. Der kleine Osterhase wiegt 25g, der mittlere Osterhase `
  - neuer Stamm: `Das Bild zeigt drei unterschiedlich große Schokoladenosterhasen. Der kleine Osterhase wiegt 25 g, der mittlere Osterhase`
- **Punkte auf Geraden** — alte Loesung: `—`
  - alter Stamm: `3 Weise nach: Der Punkt A(4 | 3 )liegt auf der Geraden mit der Gleichung y=x-3. 2 Gegeben sind die drei Punkte P1 (2 | 1`
  - neuer Stamm: `Weise nach: Der Punkt A (4 | 3) liegt auf der Geraden mit der Gleichung y = 3/2 x - 3. Gegeben sind die drei Punkte P₁ (`
- **Rauten** — alte Loesung: `4`
  - alter Stamm: `Die Eckpunkte Dx der Rauten AxBxCxDx wandern auf der Geraden g mit der Gleichung y=x. Dabei gilt immer: ·Die Diagonalen `
  - neuer Stamm: `Die Eckpunkte Dx der Rauten AxBxCxDx wandern auf der Geraden g mit der Gleichung y = x. Dabei gilt immer: · Die Diagonal`
- **Zeitangabe** — alte Loesung: `150min`
  - alter Stamm: `1 Wie viele Minuten sind 2 Stunden? 2 60min | 90min | 150min | 250min`
  - neuer Stamm: `Wie viele Minuten sind 2½ Stunden?`

### S3 — MC: die alte Loesung steht nicht unter den Optionen (7)

Die Optionen sind auf der *neuen* Seite gelesen: im alten Stamm sind Optionen, Tabellenzellen und Prosa zu einem `|`-Brei verschmolzen und nicht mehr auseinanderzuhalten — das ist der eigentliche Befund.

| Item | alte Loesung | neue Optionen | neu korrekt |
|---|---|---|---|
| Der Stern (Ta1) | `16cm2` | 7 cm², 12 cm², 16 cm², 20 cm² | 16 cm² |
| Geschichte zur Graphik (Ta1) | `[pic]` | Paula und Sepp mache, Herr Heuer kauft Akt, Lisa und Sven machen | [pic] |
| Körper füllen (Ta1) | `90cm3` | 14 cm³, 16 cm³, 74 cm³, 90 cm³, 126 cm³ | 90 cm³ |
| Mathematikarbeit (Ta1) | `[pic]` | 12 %, 12,5 %, 48 %, 60 %, 80 % | [pic] |
| Mädchenanteil (Ta1) | `8` | 8/23, 8/15, 15/8, 23/8 | 8/23 |
| Rabattaktion (Ta1) | `[pic]` | , , ,  | [pic] |
| Rauten (Ta4) | `xcm2` | 0,25x cm², 0,5x cm², x cm², 2x cm² | x cm² |

Drei Sorten, und sie sind verschieden schlimm:

- **Zeichen zerstoert, Wert richtig:** `16cm2` statt `16 cm²`, `90cm3` statt `90 cm³`, `xcm2` statt `x cm²`. Der Wert stimmt; als Vergleichsstring ist der Schluessel trotzdem unbrauchbar.
- **Wert FALSCH:** `Mädchenanteil` — alte Loesung **`8`**, richtig ist **`8/23`**. Der Bruchstrich ging verloren, uebrig blieb der Zaehler. Das ist keine Formatfrage mehr, sondern eine **falsche Loesung** im Altbestand.
- **Bildverweis:** `[pic]` — die Loesung war eine Grafik. Im Altbestand unbrauchbar, in der Neuextraktion **immer noch** unbrauchbar (siehe N1).

### S4 — verschraenkte Textlaeufe (2)

Zwei ineinandergeschobene Textlaeufe verdoppeln die Buchstaben:

- **Damenuhr** — z.B. 'mmiitt', 'wweeißißeemm', 'Ziiffffeerrnnbblalattt', 'ggaannggggeennaauueemm'
- **Wettkampf wählen** — z.B. 'BasketballFußballHandballVolleyball', 'FeldhockeyFußballHandballVolleyball'

---

## Was die Neuextraktion ihrerseits falsch macht (N1–N3)

Diese Klasse faellt durch die Gates: `grade()` in `ground_all.py` prueft nur, **dass** ein `correct_answers` da ist — nicht, ob es eine benutzbare Antwort **ist**. Darum ist die Pipeline-Zahl (63) zu hoch.

### N1 — MC-Schluessel ist keine Options-ID (25 Teilaufgaben)

Statt `"c"` steht im Schluessel die Kodierregel aus der Auswertung:

- **Aufgabenreihen** (Ta2): `['Nein', 'UND']`
- **Autokauf** (Ta1): `['Nein', 'UND']`
- **Colakästen** (Ta2): `['"Herr Melzer muss an der Kasse noch etwas bezahlen." ist angekreuzt.', 'UND']`
- **Dreieckszahlen** (Ta2): `['4tes Kästchen wurde angekreuzt.']`
- **Durch 1001 teilbar** (Ta1): `['4 der 5 Kreuze sind richtig gesetzt.']`
- **Eiscafé** (Ta2): `['Eiscafé Arnoldo ist angekreuzt', 'UND']`
- **Figur aus zwei Dreiecken** (Ta1): `['4 der 5 Kreuze sind richtig gesetzt.']`
- **Freizeitkosten** (Ta1): `['Nein', 'UND']`
- **Geld anlegen** (Ta2): `['Nein', 'UND']`
- **Geschichte zur Graphik** (Ta1): `['[pic]']`
- **Inliner** (Ta2): `['Ja', 'UND']`
- **Jubiläumsgeschenk** (Ta2): `['Nein', 'UND']`
- … und 13 weitere

Der Grossteil sind in Wahrheit **MC + Begruendung** — also gar keine reinen MC-Items, sondern coach-bewertete Items, die faelschlich als MC typisiert wurden.

### N2 — Optionen ohne Label (2)

- **Quadernetz 2** (Ta1): vier Optionen, alle Labels leer
- **Rabattaktion** (Ta1): vier Optionen, alle Labels leer

### N3 — SHORT_INPUT-Schluessel ist eine Kodierregel (44)

- **Andere Länder - andere Noten** (Ta1): `ODER`
- **Andere Länder - andere Noten** (Ta2): `Alle Punktzahlen, die größer oder gleich 89 und kleiner als 91 sind`
- **Ansichten eines Tischs** (Ta1): `UND`
- **Aussagen über Dreiecke** (Ta2): `Richtiger Term`
- **Außenthermometer** (Ta2): `10 ODER -10`
- **Bernd und das Brot** (Ta1): `UND`
- **Bruch und Prozentsatz** (Ta1): `UND`
- **Butter** (Ta1): `Ganzzahlige Antworten aus dem Intervall [70; 80]`
- **Darstellung in Diagrammen** (Ta1): `Im Jahr 2009 sind 65 Millionen Flaschen verkauft worden.`
- **Der Riese** (Ta1): `Angabe einer Größe aus dem Intervall [30 m; 60 m]`
- **Ecken und Kanten** (Ta1): `UND`
- **Fehlende Zahlen** (Ta2): `ODER`
- **Fliesen für den Fußboden** (Ta1): `UND`
- **Freizeitbeschäftigungen** (Ta2): `Musik ODER Sport ODER Kino`
- … und 30 weitere

Ein Teil davon ist mechanisch reparierbar — Intervalle und `ODER`-Alternativen lassen sich in einen Matcher uebersetzen. Aber **heute** kann LSA damit nicht bewerten.

---

## Die 14 bereits importierten Items

**10 von 14 werden von der Neuextraktion in Loesung und Einheit bestaetigt.** 4 weichen ab — nicht aufgeloest, gemeldet:

- **Ecken an Pyramiden** (`eckenanpyramiden`): Neuextraktion hat KEINE Teilaufgabe — nichts zu vergleichen: keine Vision-Lesung vorhanden
  - Flag: keine Teilaufgabe gelesen -> Item unbrauchbar
- **Papier** (`papier`): Neuextraktion hat KEINE Teilaufgabe — nichts zu vergleichen: Vision-Lesung (1 Ta) existiert, wurde aber nicht verbaut (Bau-Verzug)
  - Flag: keine Teilaufgabe gelesen -> Item unbrauchbar
- **Temperaturdifferenz** (`temperaturdifferenz`): Neuextraktion hat KEINE Teilaufgabe — nichts zu vergleichen: Vision-Lesung (1 Ta) existiert, wurde aber nicht verbaut (Bau-Verzug)
  - Flag: keine Teilaufgabe gelesen -> Item unbrauchbar
- **Zwanzig Prozent** (`zwanzigprozent`): Neuextraktion hat KEINE Teilaufgabe — nichts zu vergleichen: keine Vision-Lesung vorhanden
  - Flag: keine Teilaufgabe gelesen -> Item unbrauchbar

Alle vier Abweichungen sind vom selben Typ: Die Neuextraktion hat fuer diese Items **gar keine Teilaufgabe**. Das ist **kein Widerspruch** zwischen alter und neuer Loesung, sondern eine **Leerstelle** — die importierten Werte werden weder bestaetigt noch widerlegt.

**Kein einziges der 14 importierten Items wird von der Neuextraktion widerlegt.** 10 werden bestaetigt, 4 sind leer. Bei `Papier` und `Temperaturdifferenz` liegt die Bestaetigung sogar schon vor — sie steht in der Vision-Lesung (`22 mm`, `19 °C`), nur nicht im Bau (siehe Bau-Verzug oben). Bei `Ecken an Pyramiden` und `Zwanzig Prozent` fehlt die Vision-Lesung ganz.

Nichts davon ist aufgeloest worden — gemeldet, wie verlangt.

---

## Die entscheidende Zahl: der reale LSA-Pool

Kriterium: **auto-gradebar** (jede Teilaufgabe MC oder SHORT_INPUT, mit einem Schluessel, den ein Matcher **heute** vergleichen kann) **UND vollstaendig** (Stamm + Loesung + Beleg, kein blockierendes Flag).

# 37 von 299 Items

| Typ | Items |
|---|---:|
| MC | 15 |
| SHORT_INPUT | 15 |
| MULTI_PART | 7 |
| **Summe** | **37** |

### Warum nicht 63

Das Feld `lsa_pool_kandidat` in `vera8_v2.json` sagt **63**. Diese Zahl ist zu hoch: `grade()` akzeptiert jeden nicht-leeren Schluessel. 26 dieser Items tragen eine Kodierregel oder einen Bildverweis statt einer Antwort (N1–N3) und sind damit nicht maschinell bewertbar:

Aussagen über Dreiecke, Autokauf, Außenthermometer, Butter, Colakästen, Der Riese, Durch 1001 teilbar, Ecken und Kanten, Figur aus zwei Dreiecken, Fliesen für den Fußboden, Geschichte zur Graphik, Holzstab, Kauf eines DVD-Players, Kraftfutter, Lage der Würfel, Lage von zwei Geraden, Literberechnungen, Niederschlag, Parfum, Quadernetz 2, Quadratfläche, Rabattaktion, Räumungsverkauf, Wahrscheinlicher, Zahl gesucht 2, fuehrerschein

**63 − 26 = 37.**

Diese 26 zerfallen wiederum in zwei Gruppen:

- **16 brauchen wirklich einen Coach.** Der Schluessel verlangt eine Begruendung, einen Loesungsweg oder war eine Grafik — das repariert kein Matcher. Es sind Items, die als MC/SHORT_INPUT typisiert wurden, in Wahrheit aber **MC + Begruendung** sind: Aussagen über Dreiecke, Autokauf, Colakästen, Der Riese, Durch 1001 teilbar, Figur aus zwei Dreiecken, Geschichte zur Graphik, Kauf eines DVD-Players, Lage der Würfel, Lage von zwei Geraden, Niederschlag, Parfum, Rabattaktion, Räumungsverkauf, Wahrscheinlicher, fuehrerschein.
- **10 haben nur einen kaputten Schluessel.** Die Antwort steht da, nur verschuettet — unter einer `Anm.:`-Zeile (`Holzstab`: `['1,5', 'Anm.: Akzeptiert werden auch...']`), als Intervall (`Butter`: `[70; 80]`) oder als UND-Mehrfachantwort (`Fliesen`: `50 UND 25 UND 12,5`). Mit einem Aufraeumschritt am Schluessel kommen sie in den Pool: Außenthermometer, Butter, Ecken und Kanten, Fliesen für den Fußboden, Holzstab, Kraftfutter, Literberechnungen, Quadernetz 2, Quadratfläche, Zahl gesucht 2.

Damit: **37 heute**, **47 nach Schluessel-Aufraeumen** — ohne eine einzige Zeile neu zu extrahieren.

### Und das ist eine Untergrenze

37 ist kein Endstand: 106 Items haben keine Vision-Lesung und konnten gar nicht erst in die Bewertung. Laeuft die Vision-Stufe nach, kommen Kandidaten dazu — darunter 4 der 14 bereits importierten Items, die heute leer sind.

### Die Pool-Items

**MC (15):** Der Stern, Geraden im Koordinatensystem, Geschwindigkeitsüberschreitung, Gleichung lösen 3, Honigbiene, Jeans mit Ermäßigung, Körper füllen, Leistung des Motors, Maus, Maßstabsleiste, Naschkatze, Prozentanteil schätzen, Schneekristalle, Zeitangabe, Überschlagsrechnung

**SHORT_INPUT (15):** 20 Prozent, 700 Milliarden, Berechne x, Croissant, Das ist gerundet, Einfache Gleichung, Eingefärbter Körper, Fliesen, Gewerbezone, Gleichung lösen 1, Holzwürfel, Hälfte, Messzylinder, Mitte zwischen Zahlen, Pflaumen

**MULTI_PART (7):** Bevölkerungsdichte, Druckmaschinen, Gleichung finden, Güterverkehr, Internetauktion, Kopf und Körper, Rauten

---

## Topf-Details

### neu besser (38)

| Item | alt defekt weil | neu defekt weil |
|---|---|---|
| 700 Milliarden | kein Stamm; _problems: 1 | — |
| Berechne x | kein Stamm; _problems: 1 | — |
| Besondere Vierecke | _problems: 2 | — |
| Bestimme x | _problems: 1 | — |
| Briefmarkenschachteln | kein Stamm; _problems: 1 | — |
| Damenuhr | S4 verschraenkte Textlaeufe (14 Woerter); _problems: 1 | — |
| Deckungsgleiche Parallelogramme | keine Loesung; _problems: 1 | — |
| Der Stern | S3 MC-Loesung nicht unter den Optionen (1 Ta); _problems: 1 | — |
| Dreiecke ergänzen | _problems: 2 | — |
| Druckmaschinen | _problems: 1 | — |
| Eingefärbter Körper | _problems: 1 | — |
| Fliesen | kein Stamm; _problems: 1 | — |
| Geraden im Koordinatensystem | S1 verlorene Zeichen im Stamm: ½; _problems: 1 | — |
| Gleichung finden | _problems: 2 | — |
| Gleichung lösen 3 | _problems: 1 | — |
| Honigbiene | _problems: 1 | — |
| Internetauktion | _problems: 1 | — |
| Jeans mit Ermäßigung | _problems: 1 | — |
| Kopf und Körper | _problems: 1 | — |
| Kreise färben | kein Stamm; _problems: 2 | — |
| Körper füllen | S1 verlorene Zeichen im Stamm: ³; S3 MC-Loesung nicht unter den Optionen (1 Ta) | — |
| Leistung des Motors | keine Loesung; _problems: 2 | — |
| Maus | _problems: 1 | — |
| Maßstabsleiste | _problems: 1 | — |
| Mitte zwischen Zahlen | kein Stamm; _problems: 1 | — |
| Mülltonne | keine Loesung; _problems: 2 | — |
| Nebenjob | _problems: 1 | — |
| Pflaumen | _problems: 1 | — |
| Prozentanteil schätzen | _problems: 1 | — |
| Punkt gesucht | kein Stamm; _problems: 3 | — |
| Quadernetz vervollständigen | _problems: 1 | — |
| Quadrat und Raute | _problems: 3 | — |
| Rathausuhr | _problems: 2 | — |
| Rauten | S1 verlorene Zeichen im Stamm: ²₄; S3 MC-Loesung nicht unter den Optionen (1 Ta); _problems: 2 | — |
| Rechenvorteil | kein Stamm; keine Loesung; _problems: 2 | — |
| Regelmäßige Vielecke | kein Stamm; _problems: 4 | — |
| Schneekristalle | keine Loesung; _problems: 2 | — |
| Zeitangabe | S1 verlorene Zeichen im Stamm: ½; _problems: 1 | — |

### beide defekt (226)

Davon **94 ohne Vision-Lesung**: die neue Seite ist leer, weil die Stufe nicht gelaufen ist — nicht, weil sie gescheitert waere.

| Item | alt defekt weil | neu defekt weil |
|---|---|---|
| Abstand auf dem Wasser | kein Stamm; _problems: 1 | keine Teilaufgabe gelesen |
| Adventskalender | keine Loesung; _problems: 7 | Teilaufgabe ohne Loesung; G0: Stamm nur aus Rasterbild gelesen -> UNGEPRUEFT; G5: Tabelle im Bi |
| Ampelkarte | _problems: 3 | Teilaufgabe ohne Loesung; G1b: part1.prompt: Interpunktion/Layoutzeichen ohne Beleg im Zeichenv |
| Andere Länder - andere Noten | _problems: 3 | G1b: stem: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat: '()*/' (Inhalt belegt, Zeic |
| Ansichten eines Tischs | keine Loesung; _problems: 2 | Teilaufgabe ohne Prompt; G0: Stamm nur aus Rasterbild gelesen -> UNGEPRUEFT; N3 Schluessel ist  |
| Anteile in geometrischen Objekten | keine Loesung; _problems: 3 | Teilaufgabe ohne Loesung; G5: Tabelle im Bild gesehen, aber keine strukturierte Tabelle rekonst |
| Apfelsaftschorle | kein Stamm; keine Loesung; _problems: 2 | keine Teilaufgabe gelesen |
| Aufgabenreihen | keine Loesung; _problems: 3 | G0: Stamm nur aus Rasterbild gelesen -> UNGEPRUEFT; N1 MC-Schluessel ist keine Options-ID (Ta [ |
| Aussagen zur proportionalen Zuordnung | kein Stamm; _problems: 1 | keine Teilaufgabe gelesen |
| Autokauf | keine Loesung; _problems: 1 | N1 MC-Schluessel ist keine Options-ID (Ta [1]) |
| Außenthermometer | _problems: 1 | N3 Schluessel ist Kodierregel (Ta [2]) |
| Bahncard | _problems: 3 | Teilaufgabe ohne Loesung; G0: Stamm nur aus Rasterbild gelesen -> UNGEPRUEFT; G2: Teilaufgabe 1 |
| Berechnungen am Rechteck | _problems: 1 | keine Teilaufgabe gelesen |
| Bernd und das Brot | keine Loesung; _problems: 2 | G1b: part1.prompt: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat: '__________________ |
| Bewege C | kein Stamm; _problems: 2 | keine Teilaufgabe gelesen |
| Bistroumfrage | keine Loesung; _problems: 5 | Teilaufgabe ohne Loesung; G1b: part1.prompt: Interpunktion/Layoutzeichen ohne Beleg im Zeichenv |
| Bonbons | kein Stamm; _problems: 1 | keine Teilaufgabe gelesen |
| Brettspiel | kein Stamm; _problems: 1 | Teilaufgabe ohne Prompt |
| Bruch und Prozentsatz | keine Loesung; _problems: 2 | G5: Tabelle im Bild gesehen, aber keine strukturierte Tabelle rekonstruiert; N3 Schluessel ist  |
| Brötchen | _problems: 1 | keine Teilaufgabe gelesen |
| Butter | _problems: 3 | N3 Schluessel ist Kodierregel (Ta [1]) |
| Chancen | kein Stamm; _problems: 3 | keine Teilaufgabe gelesen |
| Colakästen | _problems: 1 | N1 MC-Schluessel ist keine Options-ID (Ta [2]) |
| Computerspielsucht | kein Stamm; _problems: 1 | keine Teilaufgabe gelesen |
| Darstellung in Diagrammen | kein Stamm; keine Loesung; _problems: 2 | G1b: part1.prompt: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat: ':________' (Inhalt |
| Der Riese | keine Loesung; _problems: 2 | N3 Schluessel ist Kodierregel (Ta [1]) |
| Division von Zahlen | keine Loesung; _problems: 2 | keine Teilaufgabe gelesen |
| Drehkörper | kein Stamm; _problems: 1 | Teilaufgabe ohne Prompt |
| Dreieck im Quadrat | _problems: 1 | keine Teilaufgabe gelesen |
| Dreieck im Rechteck | kein Stamm; keine Loesung; _problems: 2 | keine Teilaufgabe gelesen; keine Aufgaben-Datei; kein Inhaltsbild -> kein Stamm extrahierbar |
| Dreieckszahlen | S1 verlorene Zeichen im Stamm: ₀₁₂₃₄₅₆ₙ | G1b: stem: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat: '…' (Inhalt belegt, Zeichen |
| Durch 1001 teilbar | keine Loesung; _problems: 2 | N1 MC-Schluessel ist keine Options-ID (Ta [1]) |
| Ecken und Kanten | keine Loesung; _problems: 2 | N3 Schluessel ist Kodierregel (Ta [1]) |
| Eindeutig | _problems: 4 | Teilaufgabe ohne Loesung; G1b: part1.prompt: Interpunktion/Layoutzeichen ohne Beleg im Zeichenv |
| Eiscafé | _problems: 2 | G0: Stamm nur aus Rasterbild gelesen -> UNGEPRUEFT; N1 MC-Schluessel ist keine Options-ID (Ta [ |
| Fahrradcomputer | kein Stamm; _problems: 2 | keine Teilaufgabe gelesen |
| Fahrradtour | kein Stamm; _problems: 4 | keine Teilaufgabe gelesen |
| Fahrräder | _problems: 2 | G5: Tabelle im Bild gesehen, aber keine strukturierte Tabelle rekonstruiert |
| Fahrtrichtung geradeaus | _problems: 2 | Teilaufgabe ohne Loesung; G2: Teilaufgabe 1: Loesung ohne woertlichen Beleg -> NICHT geschriebe |
| Faschingsdeko | _problems: 2 | keine Teilaufgabe gelesen |
| Fehlende Zahlen | _problems: 1 | G1b: part1.prompt: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat: '☐' (Inhalt belegt, |
| Fieberthermometer | kein Stamm; _problems: 1 | keine Teilaufgabe gelesen |
| Figur aus zwei Dreiecken | keine Loesung; _problems: 2 | N1 MC-Schluessel ist keine Options-ID (Ta [1]) |
| Fische zählen | kein Stamm; _problems: 1 | Teilaufgabe ohne Prompt; G1b: stem: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat: '/ |
| Fliesen für den Fußboden | keine Loesung; _problems: 4 | N3 Schluessel ist Kodierregel (Ta [1]) |
| Flächengleich oder nicht | _problems: 2 | keine Teilaufgabe gelesen |
| Freibad | _problems: 3 | G0: Stamm nur aus Rasterbild gelesen -> UNGEPRUEFT |
| Freizeitbeschäftigungen | _problems: 3 | G1b: part2.prompt: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat: '__________________ |
| Freizeitkosten | keine Loesung; _problems: 2 | G1: Stamm ohne Beleg im Zeichenvorrat -> leer gelassen; G5: Tabelle im Bild gesehen, aber keine |
| Freunde | keine Loesung; _problems: 5 | keine Teilaufgabe gelesen |
| Frühstücksbrötchen | kein Stamm; _problems: 4 | N3 Schluessel ist Kodierregel (Ta [1]) |
| Fußballtabelle | _problems: 4 | G5: Tabelle im Bild gesehen, aber keine strukturierte Tabelle rekonstruiert; N3 Schluessel ist  |
| Fußleisten | kein Stamm; _problems: 1 | keine Teilaufgabe gelesen |
| Füllverhalten | keine Loesung; _problems: 4 | keine Teilaufgabe gelesen |
| Fünfundvierzig | kein Stamm; _problems: 1 | G1b: part1.prompt: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat: '*☐' (Inhalt belegt |
| Geld anlegen | keine Loesung; _problems: 4 | Teilaufgabe ohne Loesung; G2: Teilaufgabe 1: Loesung ohne woertlichen Beleg -> NICHT geschriebe |
| Geometrische Körper erkennen | kein Stamm; _problems: 2 | keine Teilaufgabe gelesen |
| Gesamtkantenlänge | keine Loesung; _problems: 3 | Teilaufgabe ohne Loesung; G0: Stamm nur aus Rasterbild gelesen -> UNGEPRUEFT; G2: Teilaufgabe 1 |
| Geschichte zur Graphik | kein Stamm; S3 MC-Loesung nicht unter den Optionen (1 Ta); _problems: 1 | N1 MC-Schluessel ist keine Options-ID (Ta [1]) |
| Gleichung verändern | _problems: 2 | G1b: stem: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat: '*' (Inhalt belegt, Zeichen |
| Gleichungen lösen ist nicht schwierig | kein Stamm; _problems: 3 | keine Teilaufgabe gelesen |
| Glücksrad | kein Stamm; _problems: 2 | keine Teilaufgabe gelesen |
| Glücksrad drehen | kein Stamm; _problems: 3 | Teilaufgabe ohne Prompt; G5: Tabelle im Bild gesehen, aber keine strukturierte Tabelle rekonstr |
| Glückssäckchen | _problems: 3 | keine Teilaufgabe gelesen |
| Großer Wagen | keine Loesung; _problems: 4 | Teilaufgabe ohne Loesung; G1b: part1.prompt: Interpunktion/Layoutzeichen ohne Beleg im Zeichenv |
| Gummibären | _problems: 2 | Teilaufgabe ohne Loesung; G2: Teilaufgabe 1: Loesung ohne woertlichen Beleg -> NICHT geschriebe |
| Handygebühr | _problems: 3 | G1b: part2.option[a]: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat: '*' (Inhalt bele |
| Harzwanderung | kein Stamm; _problems: 2 | keine Teilaufgabe gelesen |
| Hauptstädte | _problems: 2 | keine Teilaufgabe gelesen |
| Hausaufgaben | keine Loesung; _problems: 4 | Teilaufgabe ohne Loesung; G5: Tabelle im Bild gesehen, aber keine strukturierte Tabelle rekonst |
| Haushaltsabfälle | _problems: 1 | G1b: part1.prompt: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat: '…' (Inhalt belegt, |
| Heizkosten | keine Loesung; _problems: 3 | keine Teilaufgabe gelesen |
| Hochrad | kein Stamm; _problems: 2 | keine Teilaufgabe gelesen; G1b: stem: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat:  |
| Holzstab | kein Stamm; _problems: 1 | N3 Schluessel ist Kodierregel (Ta [1]) |
| Im Kreis laufen | keine Loesung; _problems: 2 | keine Teilaufgabe gelesen |
| Inliner | keine Loesung; _problems: 3 | G1b: stem: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat: '/' (Inhalt belegt, Zeichen |
| Innenwinkel | kein Stamm; keine Loesung; _problems: 2 | keine Teilaufgabe gelesen; keine Aufgaben-Datei; kein Inhaltsbild -> kein Stamm extrahierbar |
| Innenwinkel 2 | _problems: 5 | G0: Stamm nur aus Rasterbild gelesen -> UNGEPRUEFT; N3 Schluessel ist Kodierregel (Ta [1]) |
| Joggen | kein Stamm; _problems: 3 | keine Teilaufgabe gelesen |
| Jubiläumsgeschenk | keine Loesung; _problems: 3 | Teilaufgabe ohne Loesung; G0: Stamm nur aus Rasterbild gelesen -> UNGEPRUEFT; G2: Teilaufgabe 1 |
| Judomatte | kein Stamm; _problems: 1 | keine Teilaufgabe gelesen |
| Kauf eines DVD-Players | _problems: 1 | N1 MC-Schluessel ist keine Options-ID (Ta [2]); N3 Schluessel ist Kodierregel (Ta [1]) |
| Kaum eine Chance | _problems: 1 | Teilaufgabe ohne Loesung; G2: Teilaufgabe 1: Loesung ohne woertlichen Beleg -> NICHT geschriebe |
| Kraftfutter | kein Stamm; _problems: 2 | N3 Schluessel ist Kodierregel (Ta [1]) |
| Kreise und Vierecke | kein Stamm; _problems: 2 | Teilaufgabe ohne Prompt; N3 Schluessel ist Kodierregel (Ta [1, 2]) |
| Kreisfiguren | _problems: 1 | keine Teilaufgabe gelesen |
| Kugeln ziehen | _problems: 1 | G0: Stamm nur aus Rasterbild gelesen -> UNGEPRUEFT |
| Körper mit Seitenflächen | _problems: 1 | keine Teilaufgabe gelesen |
| Lage der Würfel | keine Loesung; _problems: 1 | N3 Schluessel ist Kodierregel (Ta [1]) |
| Lage von zwei Geraden | keine Loesung; _problems: 1 | N1 MC-Schluessel ist keine Options-ID (Ta [1]) |
| Liebstes Schulfach | keine Loesung; _problems: 4 | Teilaufgabe ohne Loesung; G0: Stamm nur aus Rasterbild gelesen -> UNGEPRUEFT; G5: Tabelle im Bi |
| Linear und proportional | kein Stamm; _problems: 2 | keine Teilaufgabe gelesen |
| Lineare Funktionen anwenden | kein Stamm; _problems: 1 | Teilaufgabe ohne Prompt; G1: Teilaufgabe 1: Prompt ohne Beleg -> leer gelassen |
| Literberechnungen | kein Stamm; _problems: 1 | N3 Schluessel ist Kodierregel (Ta [1]) |
| Lohnerhöhung | _problems: 1 | Teilaufgabe ohne Prompt; G1: Teilaufgabe 1: Prompt ohne Beleg -> leer gelassen |
| Luftballons | _problems: 1 | keine Teilaufgabe gelesen |
| Mathematikarbeit | kein Stamm; S3 MC-Loesung nicht unter den Optionen (1 Ta); _problems: 1 | G1b: stem: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat: '…………' (Inhalt belegt, Zeic |
| Mauer aus Zahlen | _problems: 3 | keine Teilaufgabe gelesen |
| Maßstabsrechner | kein Stamm; _problems: 1 | keine Teilaufgabe gelesen |
| Mensch ärgere dich nicht | keine Loesung; _problems: 3 | Teilaufgabe ohne Loesung; G2: Teilaufgabe 1: Loesung ohne woertlichen Beleg -> NICHT geschriebe |
| Muckibude | _problems: 1 | G0: Stamm nur aus Rasterbild gelesen -> UNGEPRUEFT; N3 Schluessel ist Kodierregel (Ta [2]) |
| Mädchenanteil | S3 MC-Loesung nicht unter den Optionen (1 Ta); _problems: 1 | G1b: part1.option[a]: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat: '/' (Inhalt bele |
| Nachfolgerzahl | keine Loesung; _problems: 2 | keine Teilaufgabe gelesen |
| Nagelbrett | _problems: 2 | Teilaufgabe ohne Loesung; G2: Teilaufgabe 1: Loesung ohne woertlichen Beleg -> NICHT geschriebe |
| Nashorn | keine Loesung; _problems: 2 | keine Teilaufgabe gelesen |
| Niederschlag | _problems: 2 | N1 MC-Schluessel ist keine Options-ID (Ta [4]) |
| Niederschläge | _problems: 4 | Teilaufgabe ohne Loesung; G2: Teilaufgabe 2: Loesung ohne woertlichen Beleg -> NICHT geschriebe |
| Null Komma Acht | _problems: 3 | G1b: part1.prompt: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat: '☐☐' (Inhalt belegt |
| Ohrhänger | keine Loesung; _problems: 2 | keine Teilaufgabe gelesen |
| Osterhase | S1 verlorene Zeichen im Stamm: ³; _problems: 2 | Teilaufgabe ohne Loesung; G1b: part1.prompt: Interpunktion/Layoutzeichen ohne Beleg im Zeichenv |
| Pappschachtel | keine Loesung; _problems: 4 | Teilaufgabe ohne Loesung; G0: Stamm nur aus Rasterbild gelesen -> UNGEPRUEFT; G2: Teilaufgabe 1 |
| Parfum | _problems: 3 | N3 Schluessel ist Kodierregel (Ta [2]) |
| Parkhaus | keine Loesung; _problems: 2 | Teilaufgabe ohne Loesung; G1b: stem: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat: ' |
| Parlamentswahl | _problems: 1 | keine Teilaufgabe gelesen |
| Passende Schuhe | _problems: 1 | keine Teilaufgabe gelesen |
| Pinsel | _problems: 4 | keine Teilaufgabe gelesen |
| Plättchen ziehen | keine Loesung; _problems: 1 | Teilaufgabe ohne Loesung; G2: Teilaufgabe 1: Loesung ohne woertlichen Beleg -> NICHT geschriebe |
| Punkte auf Geraden | keine Loesung; S1 verlorene Zeichen im Stamm: ₁₂₃; _problems: 3 | G1b: part1.prompt: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat: '/' (Inhalt belegt, |
| Punkte im Koordinatensystem | kein Stamm; _problems: 2 | Teilaufgabe ohne Prompt; N3 Schluessel ist Kodierregel (Ta [1, 2]) |
| Punktgenau | _problems: 1 | keine Teilaufgabe gelesen |
| Pyramidenbau | _problems: 1 | keine Teilaufgabe gelesen |
| Quader | kein Stamm; _problems: 1 | keine Teilaufgabe gelesen |
| Quadernetz 2 | keine Loesung; _problems: 3 | N2 Optionen ohne Label (Ta [1]) |
| Quadrat im Gitter | _problems: 1 | keine Teilaufgabe gelesen |
| Quadrat zeichnen | keine Loesung; _problems: 1 | keine Teilaufgabe gelesen |
| Quadratdifferenz | kein Stamm; _problems: 3 | keine Teilaufgabe gelesen |
| Quadrate | keine Loesung; _problems: 2 | keine Teilaufgabe gelesen |
| Quadratfläche | kein Stamm; keine Loesung; _problems: 2 | N3 Schluessel ist Kodierregel (Ta [1]) |
| Rabattaktion | kein Stamm; S3 MC-Loesung nicht unter den Optionen (1 Ta); _problems: 1 | N1 MC-Schluessel ist keine Options-ID (Ta [1]); N2 Optionen ohne Label (Ta [1]) |
| Raten beim Test | _problems: 1 | keine Teilaufgabe gelesen |
| Rechteck | keine Loesung; _problems: 2 | Teilaufgabe ohne Loesung; G2: Teilaufgabe 1: Loesung ohne woertlichen Beleg -> NICHT geschriebe |
| Rechtskurve | kein Stamm; keine Loesung; _problems: 4 | keine Teilaufgabe gelesen; kein Inhaltsbild -> kein Stamm extrahierbar |
| Reiseverlauf | keine Loesung; _problems: 4 | keine Teilaufgabe gelesen |
| Restaurantgewinnspiel | kein Stamm; _problems: 2 | keine Teilaufgabe gelesen |
| Richtig umgeformt | keine Loesung; _problems: 2 | Teilaufgabe ohne Loesung; G1b: part1.prompt: Interpunktion/Layoutzeichen ohne Beleg im Zeichenv |
| Rollrasen | kein Stamm; _problems: 3 | keine Teilaufgabe gelesen |
| Rolltreppe | kein Stamm; _problems: 5 | keine Teilaufgabe gelesen |
| Rot, gelb, grün | keine Loesung; _problems: 4 | keine Teilaufgabe gelesen |
| Rubbellose | _problems: 1 | keine Teilaufgabe gelesen |
| Rundfunkgebühren | _problems: 4 | G1b: part1.prompt: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat: '………' (Inhalt beleg |
| Räumungsverkauf | keine Loesung; _problems: 3 | N1 MC-Schluessel ist keine Options-ID (Ta [1, 2]) |
| Sauerkraut | _problems: 1 | keine Teilaufgabe gelesen |
| Schachteln packen | _problems: 2 | keine Teilaufgabe gelesen |
| Schlüssel | keine Loesung; _problems: 3 | Teilaufgabe ohne Loesung; G2: Teilaufgabe 1: Loesung ohne woertlichen Beleg -> NICHT geschriebe |
| Schnittpunkt von Graphen | kein Stamm; keine Loesung; _problems: 2 | keine Teilaufgabe gelesen |
| Schokoladenbonbons | keine Loesung; _problems: 2 | Teilaufgabe ohne Loesung; G2: Teilaufgabe 1: Loesung ohne woertlichen Beleg -> NICHT geschriebe |
| Schokoladenfiguren | kein Stamm; _problems: 1 | keine Teilaufgabe gelesen |
| Schokolinsen | keine Loesung; _problems: 2 | Teilaufgabe ohne Prompt; G1: Teilaufgabe 1: Prompt ohne Beleg -> leer gelassen |
| Schrankbreiten | keine Loesung; _problems: 1 | keine Teilaufgabe gelesen |
| Schulgrundstück | kein Stamm; keine Loesung; _problems: 3 | keine Teilaufgabe gelesen |
| Schulkleidung | _problems: 3 | keine Teilaufgabe gelesen |
| Schulstatistik | kein Stamm; _problems: 2 | keine Teilaufgabe gelesen |
| Schwarz-Weiß-Würfel | keine Loesung; _problems: 2 | keine Teilaufgabe gelesen |
| Skala und Zahlen | keine Loesung; _problems: 3 | keine Teilaufgabe gelesen |
| Spielwürfel | keine Loesung; _problems: 4 | keine Teilaufgabe gelesen |
| Sprechstunde | _problems: 1 | keine Teilaufgabe gelesen |
| Stammbrüche untersuchen | _problems: 3 | Teilaufgabe ohne Loesung; G1b: stem: Interpunktion/Layoutzeichen ohne Beleg im Zeichenvorrat: ' |
| Steile Straße | _problems: 6 | keine Teilaufgabe gelesen |
| Streichholzziehen | _problems: 1 | keine Teilaufgabe gelesen |
| Tabelle | kein Stamm; _problems: 1 | keine Teilaufgabe gelesen |
| Tabelle ausfüllen | keine Loesung; _problems: 3 | Teilaufgabe ohne Loesung; G5: Tabelle im Bild gesehen, aber keine strukturierte Tabelle rekonst |
| Tankinhalt | _problems: 3 | keine Teilaufgabe gelesen |
| Temperatur | _problems: 2 | keine Teilaufgabe gelesen |
| Temperaturen in Frankfurt am Main | kein Stamm; _problems: 2 | keine Teilaufgabe gelesen |
| Thermometer | _problems: 1 | keine Teilaufgabe gelesen |
| Tombola zum Schulfest | _problems: 2 | keine Teilaufgabe gelesen |
| Traktor | _problems: 1 | keine Teilaufgabe gelesen |
| Trapez ohne Symmetrie | keine Loesung; _problems: 3 | keine Teilaufgabe gelesen |
| Trapezvariation | keine Loesung; _problems: 4 | keine Teilaufgabe gelesen |
| Treppenmaße | _problems: 3 | keine Teilaufgabe gelesen |
| Tropfender Wasserhahn | _problems: 3 | keine Teilaufgabe gelesen |
| Tunnelbohrmaschine | kein Stamm; _problems: 3 | keine Teilaufgabe gelesen |
| Ungewöhnlicher Mittelwert | kein Stamm; keine Loesung; _problems: 2 | keine Teilaufgabe gelesen |
| Ungewöhnlicher Spielwürfel | _problems: 3 | keine Teilaufgabe gelesen |
| Ungleichung erfüllen | kein Stamm; keine Loesung; _problems: 2 | keine Teilaufgabe gelesen |
| Unregelmäßiges Viereck | kein Stamm; keine Loesung; _problems: 2 | keine Teilaufgabe gelesen |
| Verbindungsstrecken | _problems: 1 | keine Teilaufgabe gelesen |
| Verkehrszeichen | kein Stamm; _problems: 1 | keine Teilaufgabe gelesen |
| Verlauf des Graphen | keine Loesung; _problems: 4 | keine Teilaufgabe gelesen |
| Verschiedene Rechtecke | keine Loesung; _problems: 5 | keine Teilaufgabe gelesen |
| Viele Brötchen | keine Loesung; _problems: 1 | keine Teilaufgabe gelesen |
| Volumenverkleinerung | kein Stamm; _problems: 2 | keine Teilaufgabe gelesen |
| Von links wie von rechts | _problems: 2 | keine Teilaufgabe gelesen |
| Waage | _problems: 2 | Teilaufgabe ohne Loesung; G5: Tabelle im Bild gesehen, aber keine strukturierte Tabelle rekonst |
| Wahl | _problems: 3 | keine Teilaufgabe gelesen |
| Wahrscheinlicher | keine Loesung; _problems: 1 | N1 MC-Schluessel ist keine Options-ID (Ta [1]) |
| Weitsprung | kein Stamm; _problems: 4 | keine Teilaufgabe gelesen |
| Werbelotterie | keine Loesung; _problems: 3 | keine Teilaufgabe gelesen |
| Werbemarkt | keine Loesung; _problems: 2 | keine Teilaufgabe gelesen |
| Wettkampf wählen | keine Loesung; S4 verschraenkte Textlaeufe (2 Woerter); _problems: 2 | keine Teilaufgabe gelesen |
| Winkel Gamma | _problems: 1 | keine Teilaufgabe gelesen |
| Winkel im Parallelogramm | kein Stamm; keine Loesung; _problems: 2 | keine Teilaufgabe gelesen |
| Winkel messen | _problems: 1 | keine Teilaufgabe gelesen |
| Winkelwürfel | keine Loesung; _problems: 4 | keine Teilaufgabe gelesen |
| Wo liegt C | keine Loesung; _problems: 3 | keine Teilaufgabe gelesen |
| Wo sind die Punkte | _problems: 1 | keine Teilaufgabe gelesen |
| Wundersame Rechenergebnisse | kein Stamm; _problems: 2 | keine Teilaufgabe gelesen |
| Würfelbau | kein Stamm; _problems: 1 | keine Teilaufgabe gelesen |
| Würfelkörper | kein Stamm; _problems: 3 | keine Teilaufgabe gelesen |
| Würfeln mit Quader | keine Loesung; _problems: 2 | Teilaufgabe ohne Loesung; G5: Tabelle im Bild gesehen, aber keine strukturierte Tabelle rekonst |
| Würfeln mit zwei Würfeln | kein Stamm; _problems: 1 | keine Teilaufgabe gelesen |
| Würfelnetze | keine Loesung; _problems: 3 | keine Teilaufgabe gelesen |
| Würfeloberfläche | keine Loesung; _problems: 2 | keine Teilaufgabe gelesen |
| Würfelturm | _problems: 3 | keine Teilaufgabe gelesen |
| Würfelturm 2 | _problems: 4 | keine Teilaufgabe gelesen |
| Zahl gesucht | kein Stamm; _problems: 1 | keine Teilaufgabe gelesen |
| Zahl gesucht 2 | _problems: 3 | N3 Schluessel ist Kodierregel (Ta [1]) |
| Zahlen addieren | _problems: 1 | keine Teilaufgabe gelesen |
| Zahlen gesucht | kein Stamm; _problems: 1 | keine Teilaufgabe gelesen |
| Zahlenmauer | kein Stamm; _problems: 1 | keine Teilaufgabe gelesen |
| Zahlenstrahl | keine Loesung; _problems: 4 | keine Teilaufgabe gelesen |
| Zahlensuche | _problems: 1 | keine Teilaufgabe gelesen |
| Zahlensumme | kein Stamm; keine Loesung; _problems: 2 | keine Teilaufgabe gelesen |
| Zahlenwürfel | _problems: 1 | keine Teilaufgabe gelesen |
| Zeitumrechnung | _problems: 3 | keine Teilaufgabe gelesen |
| Zoobesuch | keine Loesung; _problems: 2 | keine Teilaufgabe gelesen |
| Zufallsversuche | kein Stamm; _problems: 3 | keine Teilaufgabe gelesen |
| Zuschauerzahlen | _problems: 1 | keine Teilaufgabe gelesen |
| Zwanzig Prozent | _problems: 1 | keine Teilaufgabe gelesen |
| Zwei Kreise | keine Loesung; _problems: 3 | keine Teilaufgabe gelesen |
| Zwei Taschenrechner | keine Loesung; _problems: 3 | keine Teilaufgabe gelesen |
| Zweite Gerade | _problems: 2 | keine Teilaufgabe gelesen |
| Zwischen zwei Zahlen 2 | keine Loesung; _problems: 4 | keine Teilaufgabe gelesen |
| Zählung von Fahrzeugen | kein Stamm; _problems: 1 | keine Teilaufgabe gelesen |
| fuehrerschein | _problems: 2 | N1 MC-Schluessel ist keine Options-ID (Ta [2]) |
| Überschlag doch mal | keine Loesung; _problems: 2 | keine Teilaufgabe gelesen |

### identisch (14)

20 Prozent, Bevölkerungsdichte, Croissant, Das ist gerundet, Einfache Gleichung, Geschwindigkeitsüberschreitung, Gewerbezone, Gleichung lösen 1, Güterverkehr, Holzwürfel, Hälfte, Messzylinder, Naschkatze, Überschlagsrechnung

