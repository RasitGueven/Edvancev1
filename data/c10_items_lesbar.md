### [0] 20 Prozent | NUMERIC | afb=I | status=ready | grade=7
Berechne 20% von 80m.
  => CA: ["16"]

### [1] 700 Milliarden | SHORT_TEXT | afb=I | status=draft | grade=None
Eric hört in den Nachrichten, dass in den USA über einen Kredit von 700 Milliarden Dollar zur Behebung einer akuten Finanzkrise diskutiert wird.

Schreibe diese Zahl in Ziffern.
  => CA: ["700 000 000 000"]

### [2] Abstand auf dem Wasser | NULL | afb=None | status=draft | grade=None
Ein Schiff fährt mit gleichbleibender Geschwindigkeit aus einem Hafen an einem Leuchtturm vorbei. Der nachstehenden Abbildung kann man entnehmen, wie viele Minuten es vom Ablegen bis zu den markierten Positionen braucht.

### [3] Adventskalender | MULTI_PART | afb=None | status=draft | grade=None
Die 24 Schülerinnen und Schüler einer achten Klasse haben für die Adventszeit einen gemeinsamen Adventskalender mit 24 Geschenken angefertigt.

Jeder legt ein Kärtchen mit seinem Namen in einen Lostopf. Ab dem ersten Dezember wird täglich ein Name gezogen, die zugehörige Person erhält das jeweilige Geschenk. Ihr Name kann nun nicht mehr gezogen werden.

Die Ziehungen für Samstag und Sonntag werden am Montag nachgeholt.
  - Teil 1 [mc] Jana hat bisher kein Geschenk erhalten. Am Morgen des 07.12., ihrem Geburtstag, überlegt sie, wie wahrscheinlich es ist, dass ihr Name an diesem Tag gezogen wird. Kreuze die passende Wahrscheinlichkeit an. || OPT: 1/24; 1/18; 7/24; 7/18
  - Teil 2 [mc] Am 22.12. ist der letzte Schultag. Deshalb werden die Geschenke vom 23. und 24.12. auch am 22.12. verlost. Simon hat bis zu diesem Tag noch kein Geschenk erhalten. Wie groß ist die Wahrscheinlichkeit, dass er am 22.12. ein Geschenk erhält? Kreuze an. || OPT: 1/3; 3/24; 22/24; 1

### [4] Ampelkarte | MULTI_PART | afb=None | status=draft | grade=None
Lebensmittel enthalten unter anderem Fett, gesättigte Fettsäuren, Zucker und Salz zu unterschiedlich hohen Anteilen. Die drei Farben der sogenannten Ampelkarte sollen helfen, die Höhe der jeweiligen Anteile einzustufen.
  - Teil 1 [short_input] Der folgenden Tabelle ist zu entnehmen, wann ein Anteil als gering, mittel oder hoch einzustufen ist. Alle Angaben beziehen sich auf 100 g des Lebensmittels. Sandra findet auf einer Dose Nüsse folgende Angaben (pro 100 g): Fett 50,8 g; davon gesättigte Fettsäuren 14 g; Zucker 5,8 g; Salz 0,13 g. Gib an, wie die Ampelkarte für die einzelnen Bestandteile dieser Nüsse gefärbt werden müsste. (Fett, gesättigte Fettsäure, Zucker, Salz)
  - Teil 2 [mc] Für Getränke gelten sogar nur halbe Werte im Vergleich zur Tabelle in Teilaufgabe 1. Alle Angaben beziehen sich auf 100 ml des Getränks. Prüfe, ob der Zuckeranteil der folgenden Getränke hoch ist. Kreuze jeweils an. (Orangensaft: 100 ml enthalten 9,3 g Zucker; Apfelschorle: 200 ml enthalten 10,6 g Zucker; Cola: ein Glas (250 ml) enthält 27 g Zucker) || OPT: ja; nein
  => CA: {"1": ["Fett\t\t\t\tFarbe: rot", "gesättigte Fettsäure\t\tFarbe: rot", "Zucker\t\t\t\tFarbe: gelb", "Salz\t\t\t\tFarbe: grün"]}

### [5] Andere Länder - andere Noten | NULL | afb=None | status=draft | grade=None
In der Schweiz wird - anders als in Deutschland - eine sehr gute Leistung mit 6 benotet, und für eine sehr schlechte Leistung bekommt man die Note 1.

So wird in einigen Schweizer Schulen die Note für eine Mathematikarbeit mit folgender Formel berechnet:

Note = (Erreichte Punktzahl / Maximalpunktzahl) · 5 + 1

Die berechnete Note wird auf eine Stelle nach dem Komma gerundet, d.h. es gibt beispielsweise auch die Note 3,6.

### [6] Ansichten eines Tischs | SHORT_TEXT | afb=I | status=draft | grade=None
Auf einem Tisch befinden sich die Gegenstände Teller, Gabel, Glas und Tasse mit Untertasse. Der Tisch wurde von verschiedenen seitlichen Kamerapositionen A bis D aus fotografiert. Abbildung 1 zeigt die Ansicht von oben.
  => CA: ["Abbildung 2: A", "UND", "Abbildung 3: D", "UND", "Abbildung 4: B"]

### [7] Anteile in geometrischen Objekten | SHORT_TEXT | afb=None | status=draft | grade=None
Welche Anteile sind grau gefärbt?

Trage jeweils einen passenden Bruch und einen passenden Prozentsatz in die Tabelle ein.

### [8] Anzahl von Nullen | NULL | afb=None | status=draft | grade=None


### [9] Apfelsaftschorle | NULL | afb=None | status=draft | grade=None
Zur Herstellung einer Apfelsaftschorle mischt man vier fünftel Liter Apfelsaft mit einem halben Liter Mineralwasser.

### [10] Aufgabenreihen | NULL | afb=None | status=draft | grade=None
Sandra schreibt aufeinanderfolgende ungerade Zahlen auf, beginnend bei 1, und macht diese Aufgabenreihe daraus.
1 = 1
1 + 3 = 4
1 + 3 + 5 = 9

### [11] Aussagen zur proportionalen Zuordnung | FREE_TEXT | afb=I | status=draft | grade=None
Die Abbildung zeigt den Graphen einer proportionalen Zuordnung.

### [12] Aussagen über Dreiecke | NULL | afb=None | status=draft | grade=None


### [13] Autokauf | MC | afb=II | status=draft | grade=None
Herr Berger möchte ein neues Auto kaufen. Nach Angabe des Händlers soll es ohne Mehrwertsteuer 19900 € kosten. Herrn Berger ist dies zu teuer, und so handelt er mit dem Händler eine Preisermäßigung von 12 % aus. Zu dem ermäßigten Preis kommen dann noch 19 % Mehrwertsteuer hinzu.

Herr Berger rechnet einfach: 19900 € zuzüglich 7 %.

Liefert diese Rechnung das richtige Ergebnis? Kreuze an. Begründe deine Antwort.
  => CA: ["Nein", "UND", "Richtige Begründung auf rechnerischer Ebene, indem Herrn Bergers Rechnung mit der korrekten Rechnung verglichen wird, oder auf inhaltlicher Ebene durch den Verweis auf die sich unters

### [14] Außenthermometer | NULL | afb=None | status=draft | grade=None


### [15] Bahncard | MULTI_PART | afb=None | status=draft | grade=None
Wenn man öfter längere Strecken mit dem Zug fährt, lohnt es sich, eine Bahncard zu kaufen. Mit einer Bahncard erhält man ein Jahr lang bei jedem Kauf einer Fahrkarte eine Ermäßigung auf den Normalpreis.
Der Normalpreis für eine Hin- und Rückfahrt auf der Strecke Hamburg-Berlin beträgt insgesamt 140,00 €.
  - Teil 1 [mc] Herr Krause besitzt eine Bahncard 25. Damit erhält er eine Ermäßigung von 25 % auf den Normalpreis.
Wie viel muss er für die Hin- und Rückfahrt auf der Strecke Hamburg-Berlin insgesamt bezahlen? || OPT: 25,00 €; 35,00 €; 70,00 €; 105,00 €; 175,00 €
  - Teil 2 [short_input] Frau Schnell kauft sich eine Bahncard 50. Damit erhält sie eine Ermäßigung von 50 % auf den Normalpreis. Für die Bahncard 50 bezahlt Frau Schnell 230,00 €.
Wie oft muss Frau Schnell die Strecke Hamburg-Berlin (Hin- und Rückfahrt) fahren, damit sich der Kauf der Bahncard 50 im Vergleich zum Normalpreis lohnt?
  => CA: {"2": ["4"]}

### [16] Berechne x | SHORT_TEXT | afb=I | status=draft | grade=None
Gegeben ist die Gleichung 8x = 72.

Berechne x.
  => CA: ["x = 9"]

### [17] Berechnungen am Rechteck | NULL | afb=None | status=draft | grade=None


### [18] Bernd und das Brot | SHORT_TEXT | afb=I | status=draft | grade=None
Fülle den Lückentext sinnvoll aus. Verwende 500 g, 5 kg sowie 55,5 kg jeweils einmal.

Bernd geht in die 6. Klasse. Seine volle Schultasche wiegt __________. Auf dem Heimweg von der Schule kauft er ein Brot, das __________ wiegt. Bernd stellt sich mit seiner vollen Schultasche und dem Brot auf die Waage. Die Waage zeigt __________ an.
  => CA: ["5 kg", "UND", "500 g", "UND", "55,5 kg"]

### [19] Besondere Vierecke | FREE_TEXT | afb=I | status=draft | grade=None
Es soll ein Rechteck gezeichnet werden. Eine Seite ist bereits eingezeichnet.

Vervollständige diese zu einem Rechteck. Zeichne mit Geodreieck, Lineal oder Zirkel.

### [20] Bestimme x | NUMERIC | afb=I | status=ready | grade=None
Es gilt x − 5 = 15.

Welchen Wert hat x?
  => CA: ["20"]

### [21] Bevölkerungsdichte | MULTI_PART | afb=None | status=draft | grade=None
Die Tabelle zeigt die Bevölkerungsdichte in den deutschen Bundesländern am 31.12.2009.
  - Teil 1 [short_input] Gib das Bundesland an, in dem die Bevölkerungsdichte am 31.12.2009 fast 400 Einwohner pro km² betrug.
  - Teil 2 [short_input] Gib die Differenz zwischen dem größten und dem kleinsten Wert der Bevölkerungsdichte an (Spannweite).
  => CA: {"1": ["Saarland"], "2": ["3790"]}

### [22] Bewege C | NULL | afb=None | status=draft | grade=None
Mit einer Geometrie-Software wurde Folgendes konstruiert:
eine Strecke AB, dazu die Mittelsenkrechte m und ein Punkt C auf m. C wird mit A und B verbunden, um das Dreieck ABC zu erhalten.
Der Punkt C wird auf der Mittelsenkrechten m nach unten bewegt. In der Zeichnung siehst du zwei Beispiele mit verschiedenen Positionen von C:

### [23] Bistroumfrage | NULL | afb=None | status=draft | grade=None
Die Klasse 8a plant eine statistische Untersuchung zum Kaufverhalten im Schulbistro.

### [24] Bonbons | MC | afb=I | status=draft | grade=None
In einer Tüte sind zwei grüne, ein gelbes, zwei weiße, ein orangefarbenes und vier rote Bonbons. Jan greift ohne hinzusehen ein Bonbon aus der Tüte.

Mit welcher Wahrscheinlichkeit ist es rot?
  => CA: ["[pic]"]

### [25] Brettspiel | FREE_TEXT | afb=I | status=draft | grade=None
Bei einem Brettspiel wird ein sechsseitiger Spielwürfel mit den Zahlen von 1 bis 6 verwendet. Der Spielstein darf immer um genau so viele Felder weitergeschoben werden, wie die Augenzahl beim einmaligen Werfen des Würfels anzeigt.

### [26] Briefmarkenschachteln | FREE_TEXT | afb=II | status=draft | grade=None
Martin sammelt neuerdings Briefmarken. Er will sie vorläufig in kleinen, selbst gebastelten Schachteln aufbewahren.

Hier sind Netze für weitere Schachteln. Vor dem Zusammenkleben beschriftet sie Martin. Vervollständige die Beschriftung.

### [27] Bruch und Prozentsatz | SHORT_TEXT | afb=I | status=draft | grade=None
In der Tabelle stehen Prozentsätze und zugehörige Dezimalbrüche.

Vervollständige die Tabelle.
  => CA: ["Prozentsatz: 30", "UND", "Dezimalbruch: 0,8"]

### [28] Brötchen | MULTI_PART | afb=None | status=draft | grade=None
Marcus hat im Sonderangebot 3 Brötchen für insgesamt 95 Cent gekauft.
Ein einzelnes Brötchen kostet 40 Cent.
  - Teil 1 [short_input] Gib an, wie viel Cent Marcus bei seinem Einkauf im Vergleich zu einem Kauf von drei einzelnen Brötchen gespart hat.
  - Teil 2 [mc] Frau Schwarz will 10 Brötchen kaufen. Bei welcher Variante zahlt sie am wenigsten? Kreuze an. Frau Schwarz kauft… || OPT: … 10 Brötchen zum Einzelpreis.; … 4 mal 3 Brötchen im Sonderangebot.; … 3 mal 3 Brötchen im Sonderangebot und 1 Brötchen zum Einzelpreis.; … 2 mal 3 Brötchen im Sonderangebot und 4 Brötchen zum Einzelpreis.
  => CA: {"1": ["25"], "2": ["c"]}

### [29] Butter | SHORT_TEXT | afb=I | status=draft | grade=None
Petra braucht ein kleines Stück Butter zum Kuchenbacken.

Gib an, wie viel Butter sie ungefähr von diesem 250-g-Stück abgeteilt hat.
  => CA: ["Ganzzahlige Antworten aus dem Intervall [70; 80]", "ODER", "Ganzzahlige Antworten aus dem Intervall [170; 180]."]

### [30] Chancen | NULL | afb=None | status=draft | grade=None
Für ein Schulfest baut eine Klasse Glücksräder. Die Besucher gewinnen beim Drehen der Glücksräder, wenn der Zeiger auf ein graues Feld zeigt.

### [31] Colakästen | MULTI_PART | afb=None | status=draft | grade=None
Ein Getränkemarkt hat Cola im Angebot: Ein Kasten mit 12 Flaschen kostet 6,66 €. Hinzu kommen 3,30 € Pfand. Man bekommt die 3,30 € Pfand zurück, wenn man einen Kasten mit 12 leeren Flaschen zurückbringt. Für eine einzelne leere Flasche erhält man 0,15 € zurück.
  - Teil 1 [short_input] Tom bringt nur den Kasten (ohne Flaschen) zurück. Gib an, wie viel Geld er zurückbekommt.
  - Teil 2 [mc] Herr Melzer bringt 3 Kästen mit jeweils 12 leeren Colaflaschen zum Getränkemarkt und nimmt einen vollen Kasten Cola aus dem Angebot mit. Welche Aussage ist richtig? Kreuze an. Begründe mit einer Rechnung. || OPT: Herr Melzer muss an der Kasse noch etwas bezahlen.; Herr Melzer bekommt noch Geld zurück.
  => CA: {"1": ["1,50 €"], "2": ["\"Herr Melzer muss an der Kasse noch etwas bezahlen.\" ist angekreuzt.", "UND", "Die Rechnung lässt einen Vergleich der beiden Beträge 9,90 € und 9,96 € erkennen.", "[Anm: Ans

### [32] Computerspielsucht | MC | afb=I | status=draft | grade=None
Nach einer Untersuchung der Universität Koblenz-Landau zeigt jeder neunte Jugendliche ein krankhaftes Computerspielverhalten.

Wie viel Prozent der Jugendlichen sind das? Kreuze den Prozentsatz an, der am besten passt.
  => CA: ["[pic]"]

### [33] Croissant | NUMERIC | afb=I | status=ready | grade=None
Marc tankt für 43,80€. Im Tankstellenladen kauft er noch ein Schoko-Croissant.
Er bezahlt beides mit einem 50€-Schein und bekommt 4,95€ zurück.
Gib an, wie teuer das Schoko-Croissant ist.
  => CA: ["1,25"]

### [34] Damenuhr | NULL | afb=None | status=draft | grade=None
Ein Versandhaus bietet eine Damenuhr an, deren Uhrengehäuse mit vier verschiedenen Wechselringen und vier verschiedenen Wechselarmbändern kombiniert werden kann (siehe Abbildung).

### [35] Darstellung in Diagrammen | SHORT_TEXT | afb=I | status=draft | grade=None
Die Firma Fruktia stellt die Umsätze ihres neuen Zitronengetränks in einem Diagramm dar.

In welchem Jahr sind 65 Millionen Flaschen verkauft worden? Vervollständige den Satz: Im Jahr ________ sind 65 Millionen Flaschen verkauft worden.
  => CA: ["Im Jahr 2009 sind 65 Millionen Flaschen verkauft worden."]

### [36] Das ist gerundet | NUMERIC | afb=I | status=ready | grade=None
Runde die Zahl 5,143 auf eine Stelle nach dem Komma.
  => CA: ["5,1"]

### [37] Deckungsgleiche Parallelogramme | FREE_TEXT | afb=I | status=draft | grade=None
Zeichne eine Gerade so durch das gegebene Parallelogramm, dass zwei zueinander deckungsgleiche Parallelogramme entstehen.

### [38] Der Riese | SHORT_TEXT | afb=III | status=draft | grade=None
In der Zeichnung ist ein Teil eines Kopfes zu sehen. Dieser Teil ist 3 m hoch.

Wie groß wäre ein Riese ungefähr, zu dem dieser Teil des Kopfes gehört? Schreibe deinen Lösungsweg auf.
  => CA: ["Angabe einer Größe aus dem Intervall [30 m; 60 m]", "UND", "Lösungsweg unter Berücksichtigung der (implizit )getroffenen Annahmen, die realistisch sein müssen. Der abgebildete Teil des Kopfes passt 

### [39] Der Stern | MC | afb=II | status=draft | grade=None
Wie groß ist der Flächeninhalt des abgebildeten Sterns? Kreuze an.
  => CA: ["c"]

### [40] Division von Zahlen | MC | afb=III | status=draft | grade=None
Eine ganze Zahl ist durch eine andere ganze Zahl teilbar, wenn bei der Division kein Rest bleibt.

Entscheide jeweils, ob die Aussage wahr oder falsch ist. Kreuze jeweils an.
  => CA: ["Alle Kreuze sind richtig gesetzt."]

### [41] Drehkörper | MC | afb=I | status=draft | grade=None
Ein Körper, der aus fünf gleich großen Würfeln besteht, wird gedreht.
  => CA: ["[pic]"]

### [42] Dreieck im Quadrat | MULTI_PART | afb=None | status=draft | grade=None
Auf gleichgroßen quadratischen Zeichenblättern wird ein Muster mit gleichschenkligen Dreiecken entworfen. Das jeweils nachfolgende Zeichenblatt entsteht dadurch, dass man jedes Teilquadrat des Vorgängerblattes durch vier gleichgroße Quadrate mit je einem gleichschenkligen Dreieck ersetzt. Die ersten beiden Blätter sind hier gezeichnet:
  - Teil 1 [short_input] Gib an, wie viele gleichschenklige graue Dreiecke sich auf Zeichenblatt 3 befinden.
  - Teil 2 [mc] Mit welchem Rechenschritt kann man die Anzahl der gleichschenkligen grauen Dreiecke auf einem beliebigen Zeichenblatt aus der Anzahl der gleichschenkligen grauen Dreiecke auf dem Vorgängerblatt berechnen? Kreuze an. Man rechnet: Neue Anzahl = Anzahl der grauen Dreiecke auf dem Vorgängerblatt … || OPT: + 3; · 3; + 4; · 4
  - Teil 3 [mc] Luca behauptet: „Je mehr gleichschenklige graue Dreiecke ein solches Zeichenblatt enthält, desto größer wird der Anteil der grauen Fläche an der Gesamtfläche.“ Stimmt diese Behauptung? Kreuze an. Begründe deine Entscheidung. || OPT: Ja; Nein
  => CA: {"1": ["16"], "2": ["d"], "3": ["Nein", "UND", "Begründung, dass die graue Fläche stets halb so groß ist wie die gesamte Quadratfläche", "ODER", "Begründung, dass die Summe der Flächeninhalte der Folg

### [43] Dreieck im Rechteck | NULL | afb=None | status=draft | grade=None


### [44] Dreiecke ergänzen | FREE_TEXT | afb=I | status=draft | grade=None
Ergänze das gegebene Dreieck zu zwei verschiedenen Parallelogrammen.

### [45] Dreieckszahlen | MULTI_PART | afb=None | status=draft | grade=None
Zahlen, die sich aus der Summe aufeinanderfolgender natürlicher Zahlen ergeben, heißen Dreieckszahlen.
Dreieckszahlen, beginnend mit der 1, lassen sich veranschaulichen, indem man Plättchen in Dreiecksform legt.
Abbildung 1 zeigt die Dreieckszahl 10, denn hierfür benötigt man 10 Plättchen.
Man rechnet so: 1 + 2 + 3 + 4 = 10.
Die Dreieckszahlen heißen D₁, D₂ … In der folgenden Tabelle sind die ersten vier dargestellt:
  - Teil 1 [short_input] Gib die beiden nächsten Dreieckszahlen D₅ und D₆ an.
  - Teil 2 [mc] Welche Zahl muss man zur Dreieckszahl D₁₀ addieren, um die Dreieckszahl D₁₁ zu erhalten? Kreuze an. || OPT: 6; 9; 10; 11; 12
  - Teil 3 [short_input] Gib eine Formel an, mit der man eine beliebige Dreieckszahl Dₙ aus deren Vorgängerdreieckszahl Dₙ₋₁ berechnen kann.
  - Teil 4 [short_input] Peter möchte eine Formel entwickeln, mit der man eine Dreieckszahl Dₙ berechnen kann, ohne den Vorgänger zu kennen. Hierzu legt er zwei Darstellungen der Dreieckszahl D₃ so nebeneinander, dass 3 Reihen mit jeweils 4 Plättchen entstehen. Er rechnet dann: D₃ = (3 · 4) / 2 = 6. Gib an, wie man die Dreieckszahl D₄ ebenso direkt berechnen kann.
  - Teil 5 [short_input] Gib eine Formel an, mit der man eine Dreieckszahl Dₙ direkt berechnen kann, ohne den Vorgänger zu kennen.
  => CA: {"1": ["D5 = 15", "D6 = 21"], "2": ["4tes Kästchen wurde angekreuzt."], "3": ["Dn = Dn-1 + n"], "4": ["D4 =  = 10"], "5": ["Dn ="]}

### [46] Druckmaschinen | MULTI_PART | afb=None | status=draft | grade=None
Eine moderne Druckmaschine kann in vier Stunden 60000 Bögen Papier bedrucken.
  - Teil 1 [short_input] Mit einer solchen Druckmaschine werden 90000 Bögen Papier bedruckt. Gib an, wie lange dies dauert.
  - Teil 2 [short_input] Bei einem Druckauftrag von insgesamt 60000 Bögen Papier drucken zwei solcher Druckmaschinen gleichzeitig. Gib an, wie lange dies dauert.
  => CA: {"1": ["6"], "2": ["2"]}

### [47] Durch 1001 teilbar | MC | afb=III | status=draft | grade=None
Peter behauptet: „Wenn man eine dreistellige Zahl zweimal hintereinander aufschreibt, dann entsteht eine sechsstellige Zahl, die immer durch 1001 teilbar ist."
Beispiel: 243243 : 1001 = 243

Welches Argument kann Peter verwenden, um seine Behauptung zu begründen?
Kreuze jeweils an, ob das Argument geeignet ist oder nicht.
  => CA: ["4 der 5 Kreuze sind richtig gesetzt."]

### [48] Ecken an Pyramiden | NUMERIC | afb=I | status=ready | grade=None
Die Abbildung zeigt eine Pyramide. Sie hat fünf Flächen:
eine viereckige Grundfläche und vier dreieckige
Seitenflächen.
Gib an, wie viele Ecken diese Pyramide hat.
  => CA: ["5"]

### [49] Ecken und Kanten | SHORT_TEXT | afb=I | status=draft | grade=None
Ergänze die Tabelle.
  => CA: ["Quader: 8 Ecken", "UND", "Pyramide: 8 Kanten"]

### [50] Eindeutig | NULL | afb=None | status=draft | grade=None
Selina und Jasmin üben das Lösen von Gleichungen.

### [51] Einfache Gleichung | NUMERIC | afb=I | status=ready | grade=None
Gegeben ist die Gleichung 18−3x=12.
Gib den Wert für x an.
  => CA: ["2"]

### [52] Eingefärbter Körper | NUMERIC | afb=II | status=draft | grade=None
Der dargestellte Körper besteht aus drei gleich großen Würfeln. Dieser Körper wird vollständig in Farbe getaucht.

Nach dem Färben wird der Körper wieder in die einzelnen Würfel zerlegt. Gib an, wie viele Seitenflächen insgesamt ungefärbt sind.
  => CA: ["4"]

### [53] Eiscafé | MULTI_PART | afb=None | status=draft | grade=None
Im Eiscafé Arnoldo kostet jede Kugel Eis 0,80 €.
Eine Portion Sahne kostet 0,50 €.
  - Teil 1 [short_input] Gina kauft vier Kugeln Eis mit einer Portion Sahne.
Wie viel muss Gina bezahlen?
  - Teil 2 [mc] Im Eiscafé Venezia bezahlt Max für fünf Kugeln Eis ohne Sahne 4,50 €.
In welchem Eiscafé ist eine Kugel Eis günstiger?
Kreuze an.
Notiere deinen Lösungsweg. || OPT: Eiscafé Arnoldo; Eiscafé Venezia
  => CA: {"1": ["3,70"], "2": ["Eiscafé Arnoldo ist angekreuzt", "UND", "Lösungsweg, bei dem der Preis für eine Kugel Eis im Eiscafé Venezia oder der Gesamtpreis für fünf Kugeln im Eiscafé Arnoldo berechnet wu

### [54] Fahrradcomputer | NULL | afb=None | status=draft | grade=None
Anna hat einen Fahrradcomputer an ihrem Fahrrad.

### [55] Fahrradtour | NULL | afb=None | status=draft | grade=None
Max und Julia haben in den Ferien eine Radtour von Passau nach Wien unternommen. Die Längen ihrer Tagesetappen hat Julia in diesem Säulendiagramm dargestellt. Max verrät einem Freund: „Weil Julia einen sportlichen Eindruck machen will, hat sie die Säule für den letzten Tag einfach weggelassen. Am letzten Tag sind wir nämlich nur 20 km gefahren.“

### [56] Fahrräder | NULL | afb=None | status=draft | grade=None
An einem Morgen notiert Marko in einer Strichliste, wie viele Frauen und wie viele Männer ihr Fahrrad am Bahnhof abstellen.

### [57] Fahrtrichtung geradeaus | NULL | afb=None | status=draft | grade=None
Dieses Verkehrszeichen zeigt an: „Vorgeschriebene Fahrtrichtung - geradeaus“.

### [58] Faschingsdeko | FREE_TEXT | afb=I | status=draft | grade=None
Die Schülerinnen und Schüler der Klasse 8a wollen für ihre Faschingsfeier Kreppband zur Dekoration verwenden. Das Kreppband wird in Packungen mit jeweils 4 verschiedenen Farben angeboten: weiß (w), rot (r), blau (b) und grün (g).

Es sollen immer 2 Kreppbänder verschiedener Farben zu Girlanden zusammengedreht werden. Schreibe alle möglichen Farbkombinationen auf.

### [59] Fehlende Zahlen | MULTI_PART | afb=None | status=draft | grade=None
Trage jeweils die fehlende Zahl in das Kästchen.
  - Teil 1 [short_input] ☐ + 9 = 4
  - Teil 2 [short_input] 4 + ☐ = -17
  => CA: {"1": ["-5"], "2": ["-21"]}

### [60] Fieberthermometer | NULL | afb=None | status=draft | grade=None
Die Abbildung zeigt ein Fieberthermometer. Die schwarze dicke Linie zeigt die gemessene Körpertemperatur in Grad Celsius an.

### [61] Figur aus zwei Dreiecken | MC | afb=III | status=draft | grade=None
Gegeben ist eine Figur aus zwei Dreiecken.

Sind die beiden Winkel a und d gleich groß?
Kreuze jeweils an, ob die Aussagen und deren Begründungen richtig oder falsch sind.
  => CA: ["4 der 5 Kreuze sind richtig gesetzt."]

### [62] Fische zählen | NUMERIC | afb=II | status=draft | grade=None
In einem großen Teich soll die Anzahl der Fische abgeschätzt werden. Dazu werden aus dem Teich 250 Fische gefangen, mit einem roten Punkt gekennzeichnet und wieder in den Teich freigelassen. Die Wahrscheinlichkeit, einen gekennzeichneten Fisch zu fangen, ist nun
p(Fisch mit rotem Punkt fangen) = Anzahl der Fische mit rotem Punkt / Anzahl aller Fische (markierte und nicht markierte) = 250/x
x: Gesamtzahl der Fische im Teich
  => CA: ["2000"]

### [63] Fliesen | NUMERIC | afb=II | status=draft | grade=None
Zum Fliesen eines Badezimmers werden 50 Platten mit einer Größe von jeweils 0,16 m² benötigt.

Der Besitzer entschließt sich dann aber doch, Fliesen der Größe 0,2 m² verlegen zu lassen. Gib an, wie viele Fliesen jetzt mindestens nötig sind.
  => CA: ["40"]

### [64] Fliesen für den Fußboden | MULTI_PART | afb=None | status=draft | grade=None
Eine 1 m² große Teilfläche eines Bades soll mit quadratischen Fliesen unterschiedlicher Größe ausgelegt werden (siehe Bild). Die Fliesen sollen so liegen, dass ihre Kanten direkt aneinanderstoßen.
  - Teil 1 [short_input] Gib die Seitenlänge jeder Fliesenart (groß, mittel, klein) an.
  - Teil 2 [mc] Der Rest des Bades soll mit quadratischen Fliesen ausgelegt werden, die alle dieselbe Größe haben. Dabei kann man zwischen zwei Fliesengrößen wählen. Die Seiten der kleineren Fliesen sind halb so lang wie die Seiten der größeren Fliesen. Welche der folgenden Aussagen ist richtig? Kreuze an. Verwendet man nur die kleineren Fliesen, so benötigt man im Vergleich zu den größeren Fliesen... || OPT: … halb so viele.; … genauso viele.; … doppelt so viele.; … viermal so viele.
  => CA: {"1": ["50", "UND", "25", "UND", "12,5"], "2": ["d"]}

### [65] Flächengleich oder nicht | NULL | afb=None | status=draft | grade=None


### [66] Flächeninhalt | NUMERIC | afb=I | status=draft | grade=None
Gib den Flächeninhalt dieser Figur an. Der Flächeninhalt beträgt __________ cm².
  => CA: ["15"]

### [67] Freibad | NULL | afb=None | status=draft | grade=None
Das Freibad in Burgdorf wurde am 1. Juni geöffnet. Am 1. Juli begannen die sechs Wochen dauernden Sommerferien. Insgesamt kamen vom 1. Juni bis zum Ende der Sommerferien 35 681 Besucherinnen und Besucher in das Freibad. Das Diagramm zeigt die Zahlen der Besucherinnen und Besucher für Juni und für jede Woche der Sommerferien.

### [68] Freizeitbeschäftigungen | NULL | afb=None | status=draft | grade=None
Bei einer Befragung in den Klassenstufen 7 und 8 gaben alle Schülerinnen und Schüler ihre beliebteste Freizeitbeschäftigung an. Abbildung 1 zeigt das Ergebnis dieser Befragung.

### [69] Freizeitkosten | MC | afb=II | status=draft | grade=None
Hat Dennis Recht? Kreuze an. Begründe deine Entscheidung.
  => CA: ["Nein", "UND", "Begründung, zum Beispiel durch Angabe eines Gegenbeispiels."]

### [70] Freunde | NULL | afb=None | status=draft | grade=None
Alex (A), Bastian (B), Can (C) und Daniel (D) sind Freunde. Das Diagramm zeigt Informationen zu ihrer Körpergröße und zu ihrem Alter.

### [71] Frühstücksbrötchen | NULL | afb=None | status=draft | grade=None
Angelika kauft sechs normale Brötchen zu je 0,35 € und vier Körnerbrötchen zu je 0,45 €.

### [72] fuehrerschein | MULTI_PART | afb=None | status=draft | grade=None
Einen Führerschein zu bekommen, ist nicht einfach. Die Tabelle gibt für die einzelnen Bundesländer an, wie viel Prozent der Theorie-Prüfungen und wie viel Prozent der Praxis-Prüfungen im Jahr 2009 nicht bestanden wurden.
  - Teil 1 [short_input] Gib an, wie viel Prozent der Praxis-Prüfungen im Saarland 2009 nicht bestanden wurden.
  - Teil 2 [mc] Überprüfe folgende Aussage anhand der Tabelle: „2009 war in jedem Bundesland die Durchfallquote in der Theorie-Prüfung höher als in der praktischen Prüfung.“ Kreuze an. Begründe deine Entscheidung. || OPT: Die Aussage ist korrekt.; Die Aussage ist falsch.
  => CA: {"1": ["27,9"], "2": ["Die Aussage ist falsch", "UND", "Begründung mit einem Gegenbeispiel (Bremen, Hamburg oder Saarland)."]}

### [73] Fußballtabelle | NULL | afb=None | status=draft | grade=None
Bei Fußball-Meisterschaftsspielen gilt:

Für einen Sieg erhält eine Mannschaft drei Punkte, für ein Unentschieden einen Punkt, für Niederlagen gibt es keinen Punkt.

Die Punkte aller Spiele einer Mannschaft werden addiert.

### [74] Fußleisten | NULL | afb=None | status=draft | grade=None
Ein Zimmer, das 4 m lang und 5 m breit ist, soll renoviert werden. Die Renovierung ist fast beendet und nur die Fußleisten fehlen noch.

### [75] Füllverhalten | NULL | afb=None | status=draft | grade=None


### [76] Fünfundvierzig | NUMERIC | afb=I | status=draft | grade=None
Bestimme die fehlende Zahl.
6 · ☐ + 3 = 45
  => CA: ["7"]

### [77] Geld anlegen | NULL | afb=None | status=draft | grade=None


### [78] Geometrische Körper erkennen | MC | afb=I | status=draft | grade=None
In der nachfolgenden Tabelle sind Körper benannt.

Prüfe, ob diese in der Abbildung zu sehen sind. Kreuze jeweils an.
  => CA: ["[pic]"]

### [79] Geraden im Koordinatensystem | MC | afb=I | status=draft | grade=None
Die Abbildung zeigt die Gerade mit der Gleichung y = ½x − 2

An welcher Stelle schneidet die Gerade die x-Achse? Kreuze an.
  => CA: ["c"]

### [80] Gesamtkantenlänge | MC | afb=I | status=draft | grade=None
Ein Quader hat die in der Abbildung angegebenen Maße.

Wie lang sind alle Kanten des Quaders zusammen? Kreuze an.

### [81] Geschichte zur Graphik | MC | afb=II | status=draft | grade=None
Eine der folgenden Beschreibungen wurde hier graphisch dargestellt. Kreuze die Beschreibung an, die zu der Graphik passt.
  => CA: ["[pic]"]

### [82] Geschwindigkeitsüberschreitung | MC | afb=I | status=draft | grade=None
Für Geschwindigkeitsüberschreitungen (d. h. für zu schnelles Fahren) innerhalb von Ortschaften gelten neue Bußgelder.

Jemand fährt in der Innenstadt mit einer Geschwindigkeit von 58 km/h, obwohl dort nur 30 km/h erlaubt sind. Mit welchem Bußgeld ist jetzt zu rechnen? Kreuze an.
  => CA: ["b"]

### [83] Gewerbezone | NUMERIC | afb=II | status=draft | grade=None
Neben einer Bundesstraße wird mit diesem Plakat für eine neue Gewerbezone geworben.
Hinweis: 1 ha = 10 000 m²

Gib an, in wie viele Grundstücke sich die noch verfügbare Fläche höchstens aufteilen lässt.
  => CA: ["6"]

### [84] Gewitter | MULTI_PART | afb=None | status=draft | grade=None
Bei einem Gewitter sieht man den Blitz sofort und hört den dazugehörigen Donner erst später. Der Schall des Donners braucht etwa drei Sekunden, um einen Kilometer zurückzulegen.
  - Teil 1 [short_input] Ein Blitz ist zu sehen. Den Donner hört man nach 4,5 Sekunden. Gib an, wie weit der Blitz ungefähr entfernt ist.
Der Blitz ist ungefähr ______ km entfernt.
  - Teil 2 [mc] Ein Blitz ist in einer Entfernung von 5,5 Kilometern zu sehen. Nach ungefähr wie vielen Sekunden hört man den Donner? Kreuze an. || OPT: 2,0 s; 5,5 s; 8,5 s; 16,5 s
  => CA: {"1": ["1,5"], "2": ["d"]}

### [85] Gleichung finden | MULTI_PART | afb=None | status=draft | grade=None
Eine Zahl n wird mit 5 multipliziert. Von diesem Produkt wird 7 subtrahiert. Die Differenz ist 38.
  - Teil 1 [mc] Welche der folgenden Gleichungen entspricht dieser Rechnung? Kreuze an. || OPT: 5n + 7 = 38; 5n – 7 = 38; 5n · 7 = 38; 5 (n – 7) = 38
  - Teil 2 [short_input] Gib an, wie groß n ist.
  => CA: {"1": ["b"], "2": ["9"]}

### [86] Gleichung lösen 1 | NUMERIC | afb=I | status=ready | grade=None
Löse die Gleichung 4+x=−6.
  => CA: ["-10"]

### [87] Gleichung lösen 2 | MC | afb=I | status=draft | grade=None
Welche Lösung hat die Gleichung 16 – 6x = 14? Kreuze an.
  => CA: ["c"]

### [88] Gleichung lösen 3 | MC | afb=I | status=draft | grade=None
Welche Zahl ist Lösung der Gleichung 2x - 4 = 6? Kreuze an.
  => CA: ["c"]

### [89] Gleichung verändern | MULTI_PART | afb=None | status=draft | grade=None
Gegeben ist die Gleichung 2 · x + 4 = 14
  - Teil 1 [mc] Welche Lösung hat die Gleichung? Kreuze an. || OPT: 3; 5; 7; 10; 12
  - Teil 2 [short_input] Verändere in der Gleichung genau eine der drei Zahlen 2, 4 oder 14 so, dass die veränderte Gleichung die Lösung x = 9 hat. Gib eine passende neue Gleichung an.
  => CA: {"1": ["b"], "2": ["ODER", "ODER"]}

### [90] Gleichungen lösen ist nicht schwierig | NULL | afb=None | status=draft | grade=None
Gleichungen können auf verschiedene Arten gelöst werden.

### [91] Glücksrad | NULL | afb=None | status=draft | grade=None
Ein Glücksrad besteht aus drei Feldern: einem roten, einem grünen und einem blauen Feld.
Bei 180 Drehungen wies der Zeiger nach dem Stillstand des Glücksrades 66-mal auf das rote Feld und 54-mal auf das grüne Feld.

### [92] Glücksrad drehen | NULL | afb=None | status=draft | grade=None
Für eine Verlosung wurde ein Glücksrad entworfen. Es hat sechs verschieden große Sektoren, die mit den Buchstaben A, B, C, D, E und F beschriftet sind.
Beim Drehen des Glücksrades treten diese Ergebnisse mit folgenden Wahrscheinlichkeiten p ein:

### [93] Glückssäckchen | MULTI_PART | afb=None | status=draft | grade=None
Bei einem Glücksspiel darf man sich von den drei Säckchen A, B, C eines auswählen. Unter den einzelnen Säckchen siehst du, mit welchen Kugeln sie gefüllt werden. In jedem Säckchen befinden sich dann schwarze und weiße Kugeln. Man zieht ohne hinzusehen aus seinem ausgewählten Säckchen eine Kugel; ist sie weiß, hat man gewonnen, ist sie schwarz, hat man verloren.
  - Teil 1 [mc] Bei welchem Säckchen ist die Wahrscheinlichkeit zu gewinnen am größten? Kreuze an. Begründe deine Entscheidung. || OPT: A; B; C
  - Teil 2 [short_input] Die Kugeln der drei Säckchen werden alle in einen größeren Sack zusammengeschüttet. Nun wird aus diesem größeren Sack eine Kugel gezogen. Wie groß ist jetzt die Wahrscheinlichkeit zu gewinnen?
  - Teil 3 [mc] Zwei andere Säckchen sind jeweils mit m Kugeln gefüllt. Im ersten Säckchen befinden sich n₁ weiße Kugeln, im zweiten Säckchen n₂ weiße Kugeln. Der Inhalt der beiden Säckchen wird wieder in einen großen Sack zusammengeschüttet und es wird aus dem großen Sack eine Kugel gezogen. Welcher Term gibt die Wahrscheinlichkeit an, mit der man gewinnt? Kreuze an. || OPT: (n₁ + n₂) / m; (n₁ · n₂) / m; (n₁ · n₂) / (2 · m); (n₁ + n₂) / (2 · m)
  => CA: {"1": ["A", "UND", "Begründung mit vergleichendem Bezug auf die Anteile weißer Kugeln in den Säckchen, der bei A am höchsten ist."], "3": ["d"]}

### [94] Großer Wagen | NULL | afb=None | status=draft | grade=None
Gregor zeichnet 6 Sterne, die zum Sternbild „Großer Wagen“ gehören, vereinfacht in ein Koordinatensystem.

### [95] Gummibären | MULTI_PART | afb=None | status=draft | grade=None
Nach Herstellerangaben werden vor dem Abfüllen von Gummibären in Tüten die Bären folgendermaßen durchgemischt:
Je ein Sechstel grüne, gelbe, weiße und orangefarbene Bären und ein Drittel rote Bären.
Die Hälfte der roten Bären schmeckt nach Erdbeere, die andere Hälfte nach Himbeere.
  - Teil 1 [short_input] Jan greift sich mit geschlossenen Augen einen Gummibären aus einer frisch geöffneten Tüte. Mit welcher Wahrscheinlichkeit hat er Himbeergeschmack?
  - Teil 2 [mc] Fünf Gummibären wiegen 10 g. Kreuze an, wie viele grüne Gummibären sich etwa in einer 1000 g-Dose befinden. || OPT: 20; 60; 80; 160; 330
  => CA: {"2": ["c"]}

### [96] Güterverkehr | MULTI_PART | afb=None | status=draft | grade=None
Das Diagramm stellt für verschiedene Transportmittel den Zusammenhang zwischen den Kosten einer transportierten Tonne Ware und der Länge des Transportweges dar. Die Graphen gehen auch für Transportwege über 500 km so weiter.
  - Teil 1 [short_input] Eine Tonne Ware soll 400 km transportiert werden. Gib an, wie teuer dieser Transport mit der Bahn ist.
  - Teil 2 [mc] Gib für einen Transportweg von 50 km das günstigste Transportmittel an. Kreuze an. || OPT: LKW; Bahn; Binnenschiff
  => CA: {"1": ["650"], "2": ["a"]}

### [97] Handygebühr | MULTI_PART | afb=None | status=draft | grade=None
Inas Handyanbieter verlangt eine Grundgebühr von 5 Euro im Monat und zusätzlich 9 Cent pro Gesprächsminute.
  - Teil 1 [short_input] Ina hatte im Januar 20 Gesprächsminuten.
Gib an, wie viel sie einschließlich der Grundgebühr bezahlen muss.
  - Teil 2 [mc] Die Höhe der monatlichen Telefonrechnung lässt sich mit einer Gleichung ermitteln. Dabei wird der Preis y (in Euro) in Abhängigkeit von der Anzahl x der Gesprächsminuten berechnet.
Kreuze die passende Gleichung an. || OPT: x = 0,09 · y + 5; x = 5 · y + 0,09; y = 0,09 · x + 5; y = 5 · x + 0,09
  => CA: {"1": ["6,80"], "2": ["c"]}

### [98] Harzwanderung | NULL | afb=None | status=draft | grade=None
Peter und Markus planen eine Wanderung durch den Harz.

### [99] Hauptstädte | MULTI_PART | afb=None | status=draft | grade=None
Die Karte zeigt die europäischen Hauptstädte. In der linken unteren Ecke ist der Maßstab dieser Karte angegeben.
  - Teil 1 [short_input] Gib an, wie lang die Strecke (Luftlinie) zwischen Berlin und Athen in der Wirklichkeit ist.
  - Teil 2 [mc] Welche der folgenden Hauptstädte ist etwa 1100 km von Berlin entfernt? Kreuze an. || OPT: Reykjavik; Luxemburg; Helsinki; Wilna
  => CA: {"1": ["Maßzahl aus dem Intervall [1750;1950]"], "2": ["c"]}

### [100] Hausaufgaben | MULTI_PART | afb=None | status=draft | grade=None
Alle zwölf Schülerinnen und Schüler eines Kurses haben die Zeit gemessen, die sie für die Hausaufgaben in Mathematik bzw. Deutsch benötigten. In der nächsten Unterrichtsstunde wird gefragt, wie viel Zeit jeder brauchte.
Dabei ergeben sich folgende Listen (Arbeitszeiten in Minuten):
Mathematik: 15; 20; 25; 20; 15; 17; 20; 20; 25; 20; 20; 15
Deutsch: 15; 18; 24; 20; 24; 24; 18; 24; 24; 18; 20; 24
  - Teil 1 [short_input] Die Arbeitszeiten für die Hausaufgaben in Mathematik sollen in einer Häufigkeitstabelle dargestellt werden. Ergänze die Tabelle.
  - Teil 2 [short_input] Das Kreisdiagramm zeigt die Häufigkeitsverteilung der Arbeitszeiten für die Hausaufgaben in Deutsch. Ordne die Arbeitszeiten den Kreisausschnitten zu.

### [101] Haushaltsabfälle | MULTI_PART | afb=None | status=draft | grade=None
Das Diagramm informiert über die Haushaltsabfälle, die im Jahr 2009 in den einzelnen Bundesländern pro Einwohner anfielen. Dabei ist im Diagramm jedem Bundesland eine Nummer zugeordnet (vgl. Tabelle).
  - Teil 1 [short_input] In welchem Bundesland gab es die wenigsten Haushaltsabfälle pro Einwohner? Ergänze: Das Bundesland heißt …
  - Teil 2 [short_input] Gib an, wie viele Haushaltsabfälle in Rheinland-Pfalz pro Einwohner anfielen.
  => CA: {"1": ["Sachsen"], "2": ["Jede Zahl im Bereich [505;520], auch wenn diese in der angegebenen Genauigkeit nicht ablesbar sein mag."]}

### [102] Heizkosten | MC | afb=II | status=draft | grade=None
Mit einer neuen Heizungsanlage kann man bis zu 40 % des Energieverbrauchs einsparen. Dieser verringerte Verbrauch kann durch sparsames Heizen um weitere 30 % reduziert werden.

Um wie viel Prozent kann der Verbrauch nach dem Einbau der neuen Anlage und dem anschließenden sparsamen Umgang mit Energie insgesamt höchstens gesenkt werden? Kreuze an.

### [103] Hochrad | NULL | afb=None | status=draft | grade=None
Bei einem Hochrad ist das Vorderrad (Durchmesser: d_V = 1,56 m) wesentlich größer als das Hinterrad (Durchmesser: d_H = 52 cm). Bei einer Umdrehung des Vorderrades legt man eine Strecke von etwa 4,90 m zurück.
Die Abbildung zeigt ein Hochrad (Abb. nicht maßstäblich).

### [104] Holzstab | NUMERIC | afb=I | status=draft | grade=None
Ein 3 m langer Holzstab wird in zwei gleich lange Teile zersägt. Gib an, wie lang jedes Teil ist.
  => CA: ["1,5"]

### [105] Holzwürfel | NUMERIC | afb=I | status=draft | grade=None
Ein gelber Holzwürfel, ein blauer Holzwürfel und ein roter Holzwürfel sollen zu einem Dreierturm aufeinander gelegt werden.

Gib an, wie viele verschiedene Möglichkeiten es gibt, aus diesen drei Holzwürfeln einen Dreierturm zu bauen.
  => CA: ["6"]

### [106] Honigbiene | MC | afb=I | status=draft | grade=None
Wie lang ist diese Biene ungefähr? Kreuze an.
  => CA: ["b"]

### [107] Hälfte | NUMERIC | afb=I | status=ready | grade=None
Wie viel ist die Hälfte von 1 Million?
Schreibe dein Ergebnis in Ziffern.
  => CA: ["500000", "500 000"]

### [108] Im Kreis laufen | MC | afb=II | status=draft | grade=None
Paul läuft im Abstand von ungefähr einem Meter um ein kreisrundes Iglu herum. Welcher Graph passt am besten, um diese Bewegung darzustellen? Kreuze an.
d: Entfernung zum Startpunkt (Luftlinie)
t: benötigte Zeit
  => CA: ["3. (links unten) Kästchen wurde angekreuzt"]

### [109] Inliner | NULL | afb=None | status=draft | grade=None
Lara umrundet auf Inline-Skates einen See. Sie startet vom Parkplatz aus und braucht für die 12 km bis zum Eiscafé 40 Minuten. Im Eiscafé macht Lara 30 min Pause. Anschließend fährt sie mit einer Geschwindigkeit von 12 km/h weiter und ist nach einer halben Stunde wieder am Parkplatz.

### [110] Innenwinkel | NULL | afb=None | status=draft | grade=None


### [111] Innenwinkel 2 | NULL | afb=None | status=draft | grade=None
Zur Erinnerung: In jedem Dreieck beträgt die Summe der drei Innenwinkelgrößen 180°.

### [112] Internetauktion | MULTI_PART | afb=None | status=draft | grade=None
Bei einer Internetauktion beobachtet Rolf die Preisentwicklung für Notebooks. Insgesamt werden neun Notebooks des gleichen Typs versteigert.

Rolf hat sich folgende Endpreise für die Notebooks aufgeschrieben:
  - Teil 1 [short_input] Wie groß ist der Preisunterschied zwischen dem teuersten und dem billigsten Notebook?
  - Teil 2 [short_input] Gib den durchschnittlichen Preis der neun Notebooks an.
  => CA: {"1": ["94 €"], "2": ["398 €"]}

### [113] Jeans mit Ermäßigung | MC | afb=I | status=draft | grade=None
In einem Kaufhaus wird eine Jeans mit 20 % Ermäßigung angeboten. Der neue Preis beträgt nun 48,00 €. Wie teuer war die Jeans vorher? Kreuze an.
  => CA: ["d"]

### [114] Joggen | NULL | afb=None | status=draft | grade=None
Die ideale Trainingsbelastung
Rechnen Sie 200 minus Lebensalter. Das ergibt den Maximalpuls. Beim Training sollte man mindestens 65 % vom Maximalpuls erreichen, aber auch nicht mehr als 85 %.

### [115] Jubiläumsgeschenk | MULTI_PART | afb=None | status=draft | grade=None
Frau Lehmann will ihrem Nachbarn zum Jubiläum einen Rosenstrauß schenken. Jede Rose kostet 3 €. Im Blumenladen will sie zusammen mit dem Strauß eine Glückwunschkarte für 2 € kaufen.
  - Teil 1 [short_input] x bezeichnet die Anzahl der Rosen, y bezeichnet den Gesamtpreis in € (Preis der Rosen plus Karte).
Gib eine Gleichung an, wie sich y aus x berechnen lässt.
  - Teil 2 [mc] Herr Meier will sich an dem Geschenk zum Jubiläum beteiligen. Er schlägt vor, einen Strauß mit der doppelten Anzahl an Rosen und dazu eine gemeinsame Glückwunschkarte zu kaufen.
Verdoppelt sich dann der Gesamtpreis? Kreuze an. Begründe deine Entscheidung. || OPT: Ja; Nein
  => CA: {"2": ["Nein", "UND", "Begründung, in welcher daraufhin hingewiesen wird, dass sich der Preis für die Rosen zwar verdoppelt, der Preis für die Karte jedoch nicht und sich deshalb auch die Summe nicht 

### [116] Judomatte | MC | afb=I | status=draft | grade=None
Bei den Olympischen Spielen wird der Judokampf innerhalb einer 8 m x 8 m großen quadratischen Kampfzone ausgetragen.

Wie groß ist diese?
  => CA: ["[pic]"]

### [117] Kauf eines DVD-Players | MULTI_PART | afb=None | status=draft | grade=None
In einem Online-Shop im Internet ist ein Angebot für einen tragbaren DVD-Player zu finden. Der ursprüngliche Preis dieses DVD-Players von 99,99 € wird um 20 % reduziert. Wenn man den Rechnungsbetrag vom Bankkonto abbuchen lässt, bekommt man auf diesen reduzierten Preis nochmal einen Rabatt von 5 %.
  - Teil 1 [short_input] Gib den Preis für den DVD-Player an, wenn man ihn ohne Abbuchung vom Bankkonto bezahlt. Runde auf ganze Cent.
  - Teil 2 [mc] Es wird behauptet: „Statt zunächst den Preisnachlass von 20 % und anschließend den Rabatt von 5 % abzuziehen, kann man auch einmalig 25 % vom Preis des DVD-Players abziehen!“ Ist diese Behauptung richtig? Kreuze an. Begründe deine Antwort. || OPT: Ja; Nein
  => CA: {"1": ["79,99", "80"], "2": ["Nein", "UND", "Richtige Begründung, in welcher darauf verwiesen wird, dass sich der Preisnachlass von 20 % und der Rabatt von 5 % auf unterschiedliche Grundwerte beziehen

### [118] Kaum eine Chance | MULTI_PART | afb=None | status=draft | grade=None
Enrico, Pauline und Tobias spielen ein Brettspiel, bei dem ein Spieler erst dann weitergehen darf, wenn er mit einem normalen Spielwürfel eine Sechs geworfen hat.
  - Teil 1 [short_input] Gib die Wahrscheinlichkeit an, mit der Enrico bei seinem ersten Wurf eine Sechs wirft:
  - Teil 2 [mc] Enrico prahlt, er habe ein System gefunden, mit dem beim Würfeln das Ergebnis des nächsten Wurfs vorhergesagt werden kann. Pauline widerspricht und sagt: „Das kann nicht sein. Es gibt kein System, mit dem man das Ergebnis des nächsten Wurfs vorhersagen kann.“ Wie kann Pauline argumentieren? Kreuze die richtige Aussage an. Das Ergebnis des nächsten Wurfs beim Würfeln lässt sich nicht ermitteln, weil … || OPT: … das Rechenverfahren dafür viel zu kompliziert ist.; … man nicht weiß, was vorher gewürfelt wurde.; … die Wahrscheinlichkeit für jedes Ergebnis bei jedem Wurf gleich groß ist.; … man nicht weiß, wie oft vorher schon gewürfelt wurde.
  => CA: {"2": ["c"]}

### [119] Kopf und Körper | MULTI_PART | afb=None | status=draft | grade=None
Als Faustregel sagt man, dass bei Babys die Länge des Kopfes zur gesamten Körpergröße ungefähr im Verhältnis 1:4 steht. Beim Erwachsenen dagegen ist dieses Verhältnis ungefähr 1:8.
  - Teil 1 [short_input] Ein Baby hat eine Kopflänge von 12 cm. Gib seine ungefähre Körpergröße an.
  - Teil 2 [short_input] Ein Erwachsener hat eine Körpergröße von 1,84 m. Gib die ungefähre Länge seines Kopfes an.
  => CA: {"1": ["48"], "2": ["23"]}

### [120] Kraftfutter | SHORT_TEXT | afb=I | status=draft | grade=None
Im Zoo bekommen die Nashörner Kraftfutter. Der Kraftfuttervorrat reicht für fünf Nashörner sechs Wochen.

Gib an, wie lange die gleiche Menge Kraftfutter für 10 Nashörner reicht.
  => CA: ["Das Kraftfutter reicht 21 Tage.", "Anm.: Auch die Antwort 3 Wochen wird akzeptiert."]

### [121] Kreise färben | FREE_TEXT | afb=I | status=draft | grade=None
Färbe 20 % dieser Kreise ein.

### [122] Kreise und Vierecke | NULL | afb=None | status=draft | grade=None
Gegeben ist jeweils ein Kreis mit dem Radius r = 3 cm.

### [123] Kreisfiguren | SHORT_TEXT | afb=II | status=draft | grade=None
In der Abbildung siehst du Figuren, die durch Kreislinien und Strecken begrenzt sind.

Zwei der vier Figuren haben denselben Flächeninhalt. Welche sind das?
  => CA: ["A UND B", "ODER", "B UND A"]

### [124] Kugeln ziehen | NUMERIC | afb=III | status=ready | grade=None
In einem Gefäß befinden sich gleich viele rote und blaue Kugeln, die sich nur durch ihre Farbe unterscheiden.

Es sollen zusätzlich so viele gelbe Kugeln hinzugefügt werden, dass die Wahrscheinlichkeit eine rote Kugel zu ziehen 20 % beträgt.

Wie viel mal so viele gelbe wie rote Kugeln müssen in dem Gefäß sein?
  => CA: ["3"]

### [125] Körper füllen | MC | afb=I | status=draft | grade=None
Ein Quader, dessen Kanten hier dick gezeichnet sind, ist mit einigen kleinen 1-cm³-Würfeln gefüllt.

Wie groß ist das Volumen des Quaders insgesamt? Kreuze an.
  => CA: ["d"]

### [126] Körper mit Seitenflächen | NULL | afb=None | status=draft | grade=None
Im Folgenden werden nur Körper betrachtet, deren Oberfläche aus ebenen Vielecken besteht. Es gibt also keine gebogenen oder gewölbten Flächen.

### [127] Lage der Würfel | SHORT_TEXT | afb=III | status=draft | grade=None
Die Abbildung zeigt vier Spielwürfel, die alle in der gleichen Weise beschriftet sind. Die Augenzahlen gegenüberliegender Seiten ergänzen sich immer zu 7. Daher liegen jeweils die Augenzahlen 1 und 6 einander räumlich gegenüber, die Augenzahlen 2 und 5 sowie 3 und 4 ebenfalls.

Diejenigen Seitenflächen dieser Spielwürfel, die sich vollständig berühren, haben immer die gleiche Augenzahl. Einige Augenzahlen fehlen in der Abbildung. Gib an, welche Augenzahl auf der grauen Seitenfläche fehlt. Schreibe die einzelnen Schritte auf, wie du zu deiner Lösung gekommen bist.
  => CA: ["Auf der grauen Seitenfläche fehlt die Augenzahl 1.", "ODER", "Auf der grauen Seitenfläche fehlt die Augenzahl 6.", "ODER", "Auf der grauen Seitenfläche fehlt die Augenzahl 1 oder 6.", "UND", "eine B

### [128] Lage von zwei Geraden | MC | afb=II | status=draft | grade=None
Gegeben sind zwei Geraden durch die folgenden Gleichungen:
1) y = 4x + 3
2) y = 4x − 3
Welche Lage haben diese Geraden zueinander? Kreuze an. Begründe deine Entscheidung.
  => CA: ["Die Geraden verlaufen parallel zueinander.", "UND", "Korrekte Begründung unter Bezug auf die identische Steigung und die voneinander abweichenden y-Achsenabschnitte. Dies kann auch durch einen rechn

### [129] Leistung des Motors | MC | afb=I | status=draft | grade=None
Die Leistung von Fahrzeugmotoren wurde früher in PS angegeben. Mittlerweile wird sie in kW angegeben. 1 kW sind etwa 1,36 PS.

Auto A hat eine Motorleistung von 89 kW. Auto B hat eine Motorleistung von 109 PS. Welches Auto hat eine größere Motorleistung? Kreuze an.
  => CA: ["a"]

### [130] Liebstes Schulfach | NULL | afb=None | status=draft | grade=None
Die Schülerinnen und Schüler einer Klassenstufe wurden gefragt, welches der folgenden vier Schulfächer sie am liebsten haben. Jeder durfte nur eines der vier Fächer nennen. Die Tabelle zeigt das Ergebnis der Umfrage.

### [131] Linear und proportional | NULL | afb=None | status=draft | grade=None
Eine proportionale Funktion kann im Koordinatensystem durch eine Gerade dargestellt werden, die durch den Punkt (0|0) verläuft. Jede lineare Funktion kann durch eine Funktionsgleichung der Form y = mx + b beschrieben werden.

### [132] Lineare Funktionen anwenden | FREE_TEXT | afb=II | status=draft | grade=None
Im Folgenden sind Sachsituationen beschrieben, bei denen jeweils eine Größe einer anderen zugeordnet ist. Diese Zuordnungen lassen sich durch Gleichungen darstellen.

### [133] Literberechnungen | SHORT_TEXT | afb=I | status=draft | grade=None
Gib an, wie viel ¾ von 10 Liter sind.
  => CA: ["7,5 Liter"]

### [134] Lohnerhöhung | NUMERIC | afb=I | status=ready | grade=None
Eine Werbefirma erhöht den Lohn für das Verteilen von 500 Werbeprospekten
von 5,00€ auf 5,50€.

Gib an, um wie viel Prozent der Lohn erhöht wird.
  => CA: ["10"]

### [135] Luftballons | MC | afb=I | status=draft | grade=None
In einem undurchsichtigen Beutel befinden sich 100 Luftballons. 60 davon sind rot, 40 sind blau.

Paul nimmt ohne hinzusehen einen Luftballon aus dem Beutel. Wie groß ist die Wahrscheinlichkeit, dass er einen roten Luftballon erhält? Kreuze an.
  => CA: ["d"]

### [136] Mathematikarbeit | MC | afb=I | status=draft | grade=None
Rolf sagt: „In der letzten Mathematikarbeit habe ich 48 von 60 Punkten erreicht, das sind ………… der Gesamtpunktzahl.“

Welcher der folgenden Prozentsätze muss eingesetzt werden? Kreuze an.
  => CA: ["[pic]"]

### [137] Mauer aus Zahlen | MULTI_PART | afb=None | status=draft | grade=None
Bei allen folgenden Zahlenmauern steht in jedem Stein das Produkt der beiden darunter liegenden Steine (siehe Abbildung). Man rechnet also 3·7 und erhält 21.
  - Teil 1 [short_input] Ergänze die folgende Zahlenmauer vollständig. (Zahlenmauer mit 3 Ebenen: oben 140, mittlere Ebene leer, unten leer, 2, 5)
  - Teil 2 [short_input] Gib an, welche Zahl man für x einsetzen muss. (Zahlenmauer: oben 48, mittlere Ebene leer, unten 3, -4, x)
  - Teil 3 [short_input] Gib an, welche Zahl man für x einsetzen kann. (Zahlenmauer: oben 256, mittlere Ebene leer, unten x, x, x)
  => CA: {"2": ["1"], "3": ["4", "-4"]}

### [138] Maus | MC | afb=I | status=draft | grade=None
Hier stimmt die Größenangabe nicht: „Mäuse wiegen im Durchschnitt 40 Tonnen.“ Welche der folgenden Maßeinheiten passt hier zur Maßzahl 40? Kreuze an.
  => CA: ["b"]

### [139] Maßstabsleiste | MC | afb=II | status=draft | grade=None
Auf einer Karte im Atlas befindet sich diese Maßstabsleiste.

Welcher Maßstab passt dazu? Kreuze an.
  => CA: ["c"]

### [140] Maßstabsrechner | NULL | afb=None | status=draft | grade=None
Ein Maßstab gibt das Größenverhältnis von Bild zu Original an. Solche Maßstäbe findet man z. B. auf Landkarten und in Modellzeichnungen.

### [141] Mensch ärgere dich nicht | MULTI_PART | afb=None | status=draft | grade=None
Beim Brettspiel „Mensch ärgere dich nicht“ muss ein Spieler mit einem Spielwürfel eine Sechs werfen, um eine Spielfigur auf den Startpunkt setzen zu dürfen.
  - Teil 1 [short_input] Meistens muss ein Spieler mehrmals würfeln, bevor er starten kann. Gib die Wahrscheinlichkeit an, dass ein Spieler gleich beim ersten Würfeln eine Sechs hat.
  - Teil 2 [mc] Tom meint, dass sehr selten eine Sechs gewürfelt wird, und möchte deshalb die Spielregeln abwandeln. Er schlägt vor, dass statt einer Sechs eine Eins gewürfelt werden muss, damit eine Spielfigur auf den Startpunkt gesetzt werden kann. Ändert sich durch Toms Vorschlag die Wahrscheinlichkeit dafür, eine Spielfigur auf den Startpunkt setzen zu können? Kreuze an. Begründe deine Entscheidung. || OPT: Ja; Nein
  => CA: {"2": ["Nein", "UND", "Begründung mit Bezug zur Gleichheit der Wahrscheinlichkeiten für 1 und 6."]}

### [142] Messzylinder | NUMERIC | afb=I | status=draft | grade=None
Gib an, wie viel Flüssigkeit sich in diesem Messzylinder befindet.
  => CA: ["280"]

### [143] Mitte zwischen Zahlen | NUMERIC | afb=I | status=draft | grade=None
Gib an, welche Zahl genau in der Mitte der beiden Zahlen 6,06 und 6,6 liegt.
  => CA: ["6,33"]

### [144] Muckibude | MULTI_PART | afb=None | status=draft | grade=None
Die Grafik zeigt die Mitgliederzahlen des Fitnessvereins „Muckibude“ in den Jahren 2012 bis 2016.
  - Teil 1 [short_input] Wie viele Mitglieder sind von 2013 bis 2014 hinzugekommen?
  - Teil 2 [short_input] In welchen Jahren lag die Anzahl der Mitglieder über 1000?
  => CA: {"1": ["400"], "2": ["2015 UND 2016"]}

### [145] Mädchenanteil | MC | afb=I | status=draft | grade=None
In der Klasse 7a sind 8 Mädchen und 15 Jungen.

Wie groß ist der Anteil der Mädchen in der gesamten Klasse 7a? Kreuze an.
  => CA: ["a"]

### [146] Mülltonne | FREE_TEXT | afb=III | status=draft | grade=None
Ermittle, welches Volumen diese Mülltonne etwa hat.
Diese Mülltonne hat etwa ein Volumen von ______.
Notiere deinen Lösungsweg.

### [147] Nachfolgerzahl | NULL | afb=None | status=draft | grade=None
Frank behauptet: „Wähle eine natürliche Zahl und bilde ihre Nachfolgerzahl. Quadriere beide Zahlen und ziehe das kleinere Ergebnis vom größeren ab. Dann erhältst du die Summe der beiden ursprünglich gewählten Zahlen.“

### [148] Nagelbrett | NULL | afb=None | status=draft | grade=None
Die Abbildung 1 zeigt ein Nagelbrett („Geobrett“).
Der Abstand der benachbarten Nägel auf dem Brett beträgt 2 cm.
Man kann mit Hilfe eines Gummirings verschiedene Figuren spannen. Dabei sollen jetzt nur Rechtecke gespannt werden, deren Seiten parallel zu den Brettkanten sind.
Die Abbildung 2 zeigt als Beispiel ein Quadrat mit einem Flächeninhalt von 16 cm².

### [149] Naschkatze | MC | afb=I | status=draft | grade=None
Kirsten hat mit ihrem neu eröffneten Café „Naschkatze“ Erfolg, denn der Umsatz steigert sich im ersten Geschäftsjahr von Quartal zu Quartal.

In welchem Quartal betrug der Umsatz 14 000 Euro? Kreuze an.
  => CA: ["c"]

### [150] Nashorn | SHORT_TEXT | afb=I | status=draft | grade=None
Dieses Foto wurde kurz nach der Geburt eines Nashornbabys im Budapester Zoo aufgenommen. Das Nashornbaby hatte zu diesem Zeitpunkt eine Schulterhöhe von 60 cm (im Bild als Doppelpfeil eingezeichnet).

Welche Länge hatte das Nashornbaby zu diesem Zeitpunkt (von der Nase bis zum Hinterteil)? Notiere deinen Lösungsweg.
  => CA: ["eine Länge aus dem Intervall [75 cm; 110 cm]", "UND", "Lösungsweg, bei dem aus dem Verhältnis von Schulterhöhe zu horizontalen Längen von der gegebenen Schulterhöhe von 60 cm auf die Gesamtlänge des

### [151] Nebenjob | NULL | afb=None | status=draft | grade=None
Leon hat einen Nebenjob. Er verdient in einer Stunde 12 Euro.
Leon bekommt seinen Verdienst wöchentlich ausgezahlt.

### [152] Niederschlag | MULTI_PART | afb=None | status=draft | grade=None
Die Abbildung zeigt ein Klimadiagramm für Halle an der Saale für das Jahr 2012. Die Säulen im Diagramm zeigen, wie viel Niederschlag in jedem Monat fiel. Die Punkte zeigen die durchschnittlichen Temperaturen für jeden Monat.
  - Teil 1 [short_input] Gib an, in welchem Monat die durchschnittliche Temperatur in Halle an der Saale am niedrigsten war.
  - Teil 2 [mc] Gib die Spannweite (das ist die Differenz des größten und kleinsten Wertes) der durchschnittlichen Temperaturen an.
Welcher Wert passt am besten? || OPT: 10 °C; 18 °C; 25 °C; 32 °C
  - Teil 3 [short_input] Gib an, in welchem Monat in Halle an der Saale am meisten Niederschlag fiel.
  - Teil 4 [mc] Kann man anhand dieses Diagramms sagen, dass für Halle an der Saale im Laufe des Monats Juli die höchste Tagestemperatur des Jahres 2012 gemessen wurde?
Begründe deine Antwort. || OPT: Ja; Nein
  => CA: {"1": ["Januar"], "2": ["b"], "3": ["Juni"], "4": ["Nein", "UND", "Begründung, auch beispielgebunden, dass man ausgehend von monatlichen Durchschnittswerten nicht auf die einzelnen Daten schließen kan

### [153] Niederschläge | MULTI_PART | afb=None | status=draft | grade=None
Diese Übersicht konnte man Anfang des Jahres 2012 der Zeitung entnehmen.
  - Teil 1 [short_input] Gib einen Monat an, in dem die Niederschlagsmenge unter der durchschnittlichen monatlichen Niederschlagsmenge lag.
  - Teil 2 [mc] Entscheide anhand des Diagramms, ob die folgenden Aussagen wahr oder falsch sind. Kreuze jeweils an.
1. Es gab einen Monat ohne Niederschlag.
2. In mehr als der Hälfte der Monate regnete es weniger als im Durchschnitt.
3. In den Monaten Juli, August und September regnete es zusammen mehr als im gesamten Rest des Jahres. || OPT: wahr; falsch
  - Teil 3 [short_input] Gib die Spannweite (den Unterschied zwischen größtem und kleinstem Wert) der monatlichen Niederschlagsmengen an.
  => CA: {"1": ["Es wird einer der Monate Januar, Februar, März, April, Mai, September, Oktober oder November genannt."], "3": ["142,7"]}

### [154] Null Komma Acht | NULL | afb=None | status=draft | grade=None


### [155] Ohrhänger | MULTI_PART | afb=None | status=draft | grade=None
Janina biegt Ohrhänger aus Silberdraht, die aus einem oberen und einem unteren Teil bestehen. Den oberen Teil macht Janina immer 3 cm lang, der untere Teil hat immer die Form eines gleichseitigen Dreiecks (siehe Abbildung).
  - Teil 1 [short_input] Das gleichseitige Dreieck hat eine Seitenlänge von 5 cm. Wie viele solche Ohrhänger kann Janina mit 90 cm Silberdraht herstellen? Schreibe deinen Lösungsweg auf.
  - Teil 2 [short_input] Aus weiteren 90 cm Silberdraht biegt Janina nun 6 andere Ohrhänger. Diese sind alle gleich groß. Der obere Teil ist wieder 3 cm lang und der untere Teil ist wieder ein gleichseitiges Dreieck. Wie lang ist eine Dreiecksseite, wenn kein Silberdraht übrig bleiben soll? Schreibe deinen Lösungsweg auf.
  => CA: {"1": ["5", "UND", "Lösungsweg, der den Drahtbedarf für einen Ohrhänger (18 cm) und die Gesamtlänge des Drahts (90 cm) berücksichtigt."], "2": ["4", "UND", "Lösungsweg, bei dem mittels des Drahtbedarf

### [156] Osterhase | MULTI_PART | afb=None | status=draft | grade=None
Das Bild zeigt drei unterschiedlich große Schokoladenosterhasen. Der kleine Osterhase wiegt 25 g, der mittlere Osterhase wiegt 100 g und der große Osterhase wiegt 1000 g.
  - Teil 1 [short_input] 1 cm³ Schokolade wiegt 1,3 g. Der große Osterhase wird geschmolzen. Gib an, wie viel cm³ Schokolade dabei ungefähr entstehen. Es entstehen ungefähr __________ cm³ Schokolade.
  - Teil 2 [mc] Die nachfolgende Tabelle enthält Aussagen über die drei Schokoladenosterhasen. Kreuze jeweils an, ob die Aussage wahr oder falsch ist. || OPT: Der kleine Osterhase wiegt ein Viertel des mittleren Osterhasen.; Der mittlere Osterhase wiegt das Vierfache des kleinen Osterhasen.; Das Gewicht des großen Osterhasen entspricht 400 % des Gewichts des kleinen Osterhasen.; Aus dem großen Osterhasen könnte man 10 mittlere Osterhasen machen.
  => CA: {"1": ["769", "769,2", "770"]}

### [157] Papier | NUMERIC | afb=I | status=ready | grade=None
500 Blatt einer Papiersorte sind 55mm hoch.
Gib an, wie hoch 200 Blatt dieser Papiersorte sind.
  => CA: ["22"]

### [158] Pappschachtel | MULTI_PART | afb=None | status=draft | grade=None
Eine Schachtel (siehe Abbildung 1) ist innen 2,5 cm hoch und je 8 cm breit und 8 cm lang.
  - Teil 1 [mc] Wie groß ist das Volumen der Schachtel? Kreuze an. || OPT: 18,5 cm³; 66,5 cm³; 160 cm³; 512 cm³
  - Teil 2 [mc] Man kann eine solche Schachtel aus einer quadratischen Pappe mit der Seitenlänge 13 cm falten. Hierzu muss an jeder der vier Ecken ein Quadrat mit der Seitenlänge x ausgeschnitten werden (siehe Abbildung 2). Dann müssen die Ränder an den gestrichelten Linien nach oben gefaltet und zusammengeklebt werden. Wie groß muss die Seitenlänge x sein, damit man die Schachtel aus Abbildung 1 erhält? Kreuze an. || OPT: x = 2,5 cm; x = 5 cm; x = 8 cm; x = 10,5 cm

### [159] Parfum | MULTI_PART | afb=None | status=draft | grade=None
Parfums werden meist in edlen Glasflaschen (siehe Abbildung 1) verkauft. Ein Pumpzerstäuber auf diesen Flaschen verteilt das Parfum in winzig kleine Tröpfchen (siehe Abbildung 2). Dabei werden mit jedem Pumpstoß durchschnittlich 0,2 ml Parfum verteilt.
  - Teil 1 [short_input] Gib an, wie viel Milliliter Parfum bei täglicher Verwendung eines Pumpstoßes nach zehn Tagen verbraucht sind.
  - Teil 2 [short_input] Sandra kauft eine Parfumflasche mit 100 ml Inhalt.
Gib an, wie lange diese Flasche wohl reicht, wenn Sandra täglich mehrere Pumpstöße Parfum verwendet.
Notiere deinen Lösungsweg.
  => CA: {"1": ["2"], "2": ["Angabe einer Zeitdauer mit mehr als null und mit höchstens 250 Tagen", "UND", "Lösungsweg, der eine Berücksichtigung der Grundmenge (100 ml) und die Menge des täglich verbrauchten 

### [160] Parkhaus | FREE_TEXT | afb=II | status=draft | grade=None
In einem Parkhaus gelten folgende Parkgebühren:
(Tabelle: Parkzeit | Gebühr — bis 2 Stunden | 4,00 €; bis 3 Stunden | 5,50 €; bis 4 Stunden | 7,00 €; jede weitere angefangene Stunde | 1,00 €; ab neun Stunden gleichbleibend | 13,00 €)

Die Parkgebühren für 0 bis 11 Stunden sollen grafisch dargestellt werden. Das Diagramm wurde schon begonnen.
Ergänze das Diagramm.

### [161] Parlamentswahl | NULL | afb=None | status=draft | grade=None
Bei einer Parlamentswahl wurden in einem Wahlbezirk 12 650 gültige Stimmen abgegeben. Davon fielen 42 % auf den Kandidaten Herrn Aal.

### [162] Passende Schuhe | MULTI_PART | afb=None | status=draft | grade=None
Das Deutsche Schuhinstitut hat genauso viele Frauen wie Männer befragt, ob ihre Schuhe zu klein, passend oder zu groß sind (siehe Abbildung 1). Die Befragungsergebnisse beziehen sich jeweils auf 100 Frauen und 100 Männer.
  - Teil 1 [mc] In einer Zeitung steht zu dieser Grafik: „80 Prozent aller Befragten tragen Schuhe, die ihnen nicht passen." Ist diese Aussage richtig? Kreuze an. Begründe deine Antwort. || OPT: Ja; Nein
  - Teil 2 [mc] Die im Balkendiagramm dargestellten Befragungsergebnisse der Frauen und Männer sollen in ein gemeinsames Kreisdiagramm übertragen werden (siehe Abbildung 2). Wie viel Grad muss der Kreisausschnitt für den Anteil der Männer haben, denen die Schuhe zu groß sind? Kreuze an. || OPT: 37,5°; 75°; 135°; 270°
  => CA: {"1": ["Nein ODER Ja", "UND", "richtige Begründung, in welcher nachgewiesen wird, dass der Anteil der Befragten ohne passende Schuhe nicht 80 % beträgt. Dieser Nachweis kann mittels einer Rechnung ode

### [163] Pflaumen | NUMERIC | afb=I | status=ready | grade=None
1kg Pflaumen kostet 1,90€.

Gib an, wie viel 500g Pflaumen kosten.
  => CA: ["0,95"]

### [164] Pinsel | MULTI_PART | afb=None | status=draft | grade=None
Der Pinsel in Abbildung 1 ist im Maßstab 1:3 abgebildet.
  - Teil 1 [short_input] Wie lang ist er in Wirklichkeit?
  - Teil 2 [mc] Ein anderer Pinsel ist in Wirklichkeit 20 cm lang. Er soll im Maßstab 1:4 abgebildet werden. Welche Abbildung passt am besten? Kreuze an. || OPT: Pinsel-Abbildung 1 (kürzeste); Pinsel-Abbildung 2; Pinsel-Abbildung 3; Pinsel-Abbildung 4 (längste)
  => CA: {"1": ["eine Zahl aus dem Intervall [17,4; 18,6]"]}

### [165] Plättchen ziehen | SHORT_TEXT | afb=I | status=draft | grade=None
In einem Gefäß sind – gut gemischt – 20 gleich große Plättchen. Zehn davon sind mit A, die anderen zehn sind mit B beschriftet.

Ellen zieht ohne hinzusehen ein Plättchen heraus. Gib die Wahrscheinlichkeit dafür an, dass Ellen ein Plättchen mit einem A zieht.

### [166] Prozentanteil schätzen | MC | afb=I | status=draft | grade=None
Wie viel Prozent der Kreisfläche sind grau gefärbt? Schätze und kreuze an.
  => CA: ["e"]

### [167] Punkt gesucht | FREE_TEXT | afb=II | status=draft | grade=None
Gegeben sind die Punkte A, B und D in dem abgebildeten Koordinatensystem.

Gesucht ist ein Punkt P, der
- von den Punkten A und B den gleichen Abstand hat und
- von dem Punkt D den Abstand d von 5 Längeneinheiten hat.

### [168] Punkte auf Geraden | NULL | afb=None | status=draft | grade=None


### [169] Punkte im Koordinatensystem | NULL | afb=None | status=draft | grade=None


### [170] Punktgenau | NULL | afb=None | status=draft | grade=None


### [171] Pyramidenbau | SHORT_TEXT | afb=I | status=draft | grade=None
In einem Magnetbaukasten befinden sich magnetische Stäbe und Kugeln. Mario baut damit Pyramiden und ihre Netze. Für jede Kante nimmt er einen Magnetstab. Abbildung 1 zeigt eine Pyramide mit dreieckiger Grundfläche. In Abbildung 2 wurde mit Stäben und Kugeln das Netz dieser Pyramide gelegt.

Das Netz aus Abbildung 2 soll zu der Pyramide aus Abbildung 1 „zusammengeklappt“ werden. Gib an, wie viele Stäbe und wie viele Kugeln dazu entfernt werden müssen.
  => CA: ["3 Stäbe", "2 Kugeln"]

### [172] Quader | NULL | afb=None | status=draft | grade=None
Die Abbildung zeigt einen Holzquader.

### [173] Quadernetz | MC | afb=II | status=draft | grade=None
Aus dem Netz eines Körpers kann man diesen zusammenfalten, ohne das Netz vorher auseinanderzuschneiden.

Kreuze jeweils an, ob es sich um das Netz eines Quaders handelt.
  => CA: ["b"]

### [174] Quadernetz 2 | MC | afb=I | status=draft | grade=None
Welche der folgenden Abbildungen zeigt das Netz eines Quaders?
Kreuze an.
  => CA: ["d"]

### [175] Quadernetz vervollständigen | FREE_TEXT | afb=II | status=draft | grade=None
Dieses Netz eines Quaders ist unvollständig. Es gibt mehrere Möglichkeiten, dieses unvollständige Netz zu einem vollständigen Quadernetz zu ergänzen.

Ergänze in der Zeichnung fehlende Flächen, so dass ein vollständiges Quadernetz entsteht.

### [176] Quadrat im Gitter | NUMERIC | afb=I | status=draft | grade=None
Auf das Gitterpapier ist ein Quadrat gezeichnet. 1 Kästchen entspricht dabei 1 cm².

Gib den Flächeninhalt des Quadrats an. Du darfst auch Hilfslinien einzeichnen.
  => CA: ["32"]

### [177] Quadrat im Koordinatensystem | MC | afb=I | status=draft | grade=None
In einem Koordinatensystem liegt ein Quadrat ABCD. Die Punkte B, C und D haben die Koordinaten B (4|-2), C (4|3) und D (-1|3).

Welches sind die Koordinaten des Punktes A? Kreuze an.
  => CA: ["b"]

### [178] Quadrat und Raute | NULL | afb=None | status=draft | grade=None
Gegeben ist eine Gerade, die durch den Ursprung eines Koordinatensystems verläuft.

### [179] Quadrat zeichnen | FREE_TEXT | afb=I | status=draft | grade=None
Zeichne ein Quadrat mit der Seitenlänge 5 cm.

### [180] Quadratdifferenz | NULL | afb=None | status=draft | grade=None
Hans und Karin wollen die Differenz 5² - 4² berechnen.
Karin sagt: „Das ist bei zwei aufeinanderfolgenden Zahlen ganz einfach. Das Ergebnis ist die Summe der beiden Zahlen 5 und 4. Und das ist 9."
Hans ist erstaunt: „Tatsächlich, es stimmt: 5² - 4² = 25 - 16 = 9."

### [181] Quadrate | SHORT_TEXT | afb=I | status=draft | grade=None
Im Koordinatensystem sind die drei Punkte A, B und D gegeben.

Wo muss der vierte Punkt C liegen, damit ein Quadrat ABCD entsteht? Zeichne den Punkt C ein.

### [182] Quadratfläche | SHORT_TEXT | afb=I | status=draft | grade=None
Bestimme den Flächeninhalt des gegebenen Quadrats. Gib dein Ergebnis an.
  => CA: ["Der ermittelte Flächeninhalt liegt im Intervall [25; 27,04] cm2.", "Die Einheit des Ergebnisses ist anzugeben. Angaben in anderen", "Einheiten mit passender Maßzahl sind zulässig.", "Anmerkungen:", 

### [183] Rabattaktion | MC | afb=II | status=draft | grade=None
Eine Firma plant eine Rabattaktion. Dabei sollen die Verkaufspreise (in denen 19 % Mehrwertsteuer enthalten ist) so gesenkt werden, dass die Kunden die Mehrwertsteuer von 19 % praktisch nicht bezahlen müssen.
Welches Schild passt am besten zu dieser Rabattaktion?
  => CA: ["[pic]"]

### [184] Raten beim Test | MULTI_PART | afb=None | status=draft | grade=None
Christian beantwortet in einem Test alle vier Fragen nur durch Raten. Zu jeder Frage gibt es vier Antworten, von denen immer nur eine richtig ist.
  - Teil 1 [short_input] Wie groß ist die Wahrscheinlichkeit dafür, dass Christian bei der ersten Frage die richtige Antwort ankreuzt? Gib dein Ergebnis an.
  - Teil 2 [mc] Wie groß ist die Wahrscheinlichkeit ungefähr, dass Christian bei allen vier Fragen des Tests die richtigen Antworten ankreuzt? Kreuze an. || OPT: ca. 25 %; ca. 4 %; ca. 2,5 %; ca. 0,4 %
  => CA: {"1": ["0,25"], "2": ["d"]}

### [185] Rathausuhr | NULL | afb=None | status=draft | grade=None
Die Rathausuhr hat einen hohen und einen tiefen Glockenton.
Der hohe Glockenton erklingt
· zur Viertelstunde einmal,
· zur halben Stunde zweimal,
· zur Dreiviertelstunde dreimal und
· zur ganzen Stunde viermal.
Der tiefe Glockenton gibt zusätzlich zu jeder vollen Stunde die Uhrzeit an, also um 1 Uhr (oder um 13 Uhr) mit einem Glockenschlag, um 2 Uhr (oder um 14 Uhr) mit zwei Glockenschlägen und so weiter.

### [186] Rauminhalt von Prismen | MC | afb=II | status=draft | grade=None
Die Rauminhalte der zwei Körper A und B sollen verglichen werden, ohne die beiden Rauminhalte jedoch konkret auszurechnen. Die Grundfläche von Körper A ist ein Quadrat mit 10 cm Kantenlänge, die Grundfläche G von Körper B ist ein Sechseck mit 100 cm² Flächeninhalt

Welche der folgenden Aussagen ist richtig?
  => CA: ["b"]

### [187] Rauten | MULTI_PART | afb=None | status=draft | grade=None
Die Eckpunkte Dx der Rauten AxBxCxDx wandern auf der Geraden g mit der Gleichung y = x. Dabei gilt immer:
· Die Diagonalen AxCx dieser Rauten sind 2 cm lang.
· Die Punkte Bx liegen auf der x-Achse und haben jeweils die gleiche x-Koordinate wie die Punkte Dx.
Im Koordinatensystem sind zwei solche Rauten dargestellt, zu x = 4 und zu x = 7.
  - Teil 1 [short_input] Wie groß ist der Flächeninhalt der Raute A₄B₄C₄D₄?
  - Teil 2 [short_input] Die Raute AxBxCxDx hat einen Flächeninhalt von 10 cm². Gib die Koordinaten des zugehörigen Punktes Dx an.
  - Teil 3 [short_input] Für welchen Wert von x ist die Raute AxBxCxDx gleichzeitig ein Quadrat? Gib den x-Wert an.
  - Teil 4 [mc] Wie groß ist allgemein der Flächeninhalt der Raute AxBxCxDx? Kreuze an. || OPT: 0,25x cm²; 0,5x cm²; x cm²; 2x cm²
  => CA: {"1": ["4"], "2": ["( 10 | 10 )"], "3": ["2"], "4": ["c"]}

### [188] Rechenvorteil | FREE_TEXT | afb=I | status=draft | grade=None
4 · 3,15 · 25 =

Wie kann Susanne einen Rechenvorteil nutzen, um diese Aufgabe ohne Nebenrechnung oder Taschenrechner zu lösen? Rechne vor.

### [189] Rechteck | FREE_TEXT | afb=I | status=draft | grade=None
Es soll ein vierter Punkt C so ergänzt werden, dass das Viereck ABCD ein Rechteck ist.
Zeichne diesen Punkt C in das Koordinatensystem ein.

### [190] Rechtskurve | NULL | afb=None | status=draft | grade=None


### [191] Regelmäßige Vielecke | FREE_TEXT | afb=I | status=draft | grade=None
Zeichne in dem gegebenen gleichseitigen Dreieck alle Symmetrieachsen ein.

### [192] Reiseverlauf | MULTI_PART | afb=None | status=draft | grade=None
Das Diagramm (siehe Abbildung) zeigt vereinfacht den Reiseverlauf von zwei Fahrzeugen A und B.
  - Teil 1 [mc] Welche Aussagen passen zu dem Diagramm? Kreuze jeweils an. || OPT: trifft zu; trifft nicht zu
  - Teil 2 [mc] Kann der Reiseverlauf eines Fahrzeugs in einem Weg-Zeit-Diagramm durch eine Gerade dargestellt werden, die parallel zur Weg-Achse verläuft? Kreuze an. Begründe deine Antwort. || OPT: Ja; Nein
  => CA: {"2": ["Nein", "UND", "Begründung, in der festgestellt wird, dass sich das Fahrzeug dann gleichzeitig an verschiedenen Orten befinden müsste."]}

### [193] Restaurantgewinnspiel | NULL | afb=None | status=draft | grade=None
Jedes Jahr in der Weihnachtszeit veranstaltet ein Restaurant ein Gewinnspiel. Der Wirt füllt dazu 100 Kugeln mit den Nummern 1 bis 100 in ein undurchsichtiges Gefäß und deckt dieses mit einem Tuch ab. Ein Gast, der die Rechnung bekommt, muss eine Zahl zwischen 1 und 100 nennen und dann, ohne hinzusehen, eine Kugel ziehen. Er zeigt dem Wirt die Nummer auf der Kugel und legt die Kugel wieder in das Gefäß zurück.

### [194] Richtig umgeformt | NULL | afb=None | status=draft | grade=None


### [195] Rollrasen | NULL | afb=None | status=draft | grade=None
Herr Klie hat eine Gartenbaufirma und gestaltet einen Teil seines Firmengeländes in eine Rasenfläche um. Diese neue Rasenfläche ist 11 m lang und 10,5 m breit.
Aus Zeitgründen verwendet Herr Klie Rollrasen (siehe Fotos 1 und 2). Als Rollrasen bezeichnet man fertigen Rasen, der in rechteckige Stücke geschnitten und dann zum Transport aufgerollt wird.

### [196] Rolltreppe | NULL | afb=None | status=draft | grade=None
In einer U-Bahn-Station befindet sich einer der Bahnsteige genau 21 m unter Straßenniveau. Nach oben gelangt man mit einer Rolltreppe.
Monika stellt sich unten auf diese Rolltreppe und lässt sich einfach hochfahren.
Das folgende Zeit-Höhen-Diagramm stellt dar, wie tief sie zu jedem Zeitpunkt noch unter der Erde (dem Straßenniveau) ist.

### [197] Rot, gelb, grün | NULL | afb=None | status=draft | grade=None
In einer Urne liegen drei rote, vier gelbe und fünf grüne Kugeln. Man zieht ohne Hinzusehen eine Kugel aus der Urne und legt sie anschließend wieder zurück.

### [198] Rubbellose | MULTI_PART | afb=None | status=draft | grade=None
Eine Bäckerei führt zur Fußball-EM eine Verlosung durch. Während der 25 Spieltage bekommt jeder Kunde beim Einkauf ein Los mit drei Rubbelfeldern.
Nach dem Freirubbeln sieht man auf jedem Feld entweder ein Fußballbild oder einen freien Kreis.
Es gilt folgender Gewinnplan:
Die Bäckerei lässt 7500 Lose drucken. 25 davon haben 3 Fußballbilder.
  - Teil 1 [mc] Der erste Kunde bekommt ein Los.
Mit welcher Wahrscheinlichkeit gewinnt er einen echten Fußball? || OPT: 1/3; 3/25; 1/25; 1/300; 1/7500
  - Teil 2 [short_input] Die Wahrscheinlichkeit für den ersten Kunden, eine Autofahne zu gewinnen, beträgt 1/25. 1/3 der Autofahnen sind Deutschlandfahnen, 2/3 sind Fahnen anderer Länder.
Gib an, wie viele Deutschlandfahnen verlost werden.
  => CA: {"1": ["d"], "2": ["100"]}

### [199] Rundfunkgebühren | NULL | afb=None | status=draft | grade=None
In der folgenden Abbildung ist die Entwicklung der monatlichen Rundfunkgebühren, die ein Haushalt bezahlen muss, seit dem Jahr 1953 dargestellt. Die Abbildung 1 zeigt, wann es Gebührenerhöhungen gab und wie hoch danach die Gebühren waren.
Herr Kunze hat sich genauer mit den Daten befasst und viel gerechnet. Seine Ergebnisse hat er in einer Tabelle aufgeschrieben. Allerdings hat er in der Kopfzeile nicht alle fünf Spalten inhaltlich beschriftet. Zudem stehen in einigen Feldern Fragezeichen statt Daten.

### [200] Räumungsverkauf | MULTI_PART | afb=None | status=draft | grade=None
Häufig wird ein Räumungsverkauf durchgeführt, wenn ein Geschäft umgebaut oder geschlossen wird. Dabei werden Waren billig angeboten und ihre Preise oft sogar mehrfach reduziert.
  - Teil 1 [mc] Der Preis der Jeans wird reduziert (siehe Abbildung 2). Tina hat 50 €. Kann sie sich davon diese Jeans kaufen? Kreuze an. Gib deinen Lösungsweg an. || OPT: Ja; Nein
  - Teil 2 [mc] In den letzten Tagen eines Räumungsverkaufs sagt der Geschäftsführer: „Um die Lager leer zu bekommen, senken wir die bereits um 25 % reduzierten Preise nochmals um 25 % gegenüber den schon reduzierten Preisen“ (siehe Abbildung 3). Überprüfe, ob der Endpreis der Jacke zur Aussage des Geschäftsführers passt. Kreuze an. Begründe deine Entscheidung. || OPT: Ja; Nein
  => CA: {"1": ["Ja", "UND", "Berechnung des neuen Preises."], "2": ["Nein", "UND", "Begründung, dass der Geschäftsführer nicht recht hat."]}

### [201] Sauerkraut | NULL | afb=None | status=draft | grade=None
Sauerkraut wird aus Weißkohl hergestellt. Während der Herstellung werden Milchsäurebakterien zugegeben, die sich täglich um 70 % gegenüber der Vortagsmenge vermehren. Zu Beginn der Produktion werden dem Weißkohl 50 g Bakterien zugegeben.

### [202] Schachteln packen | MULTI_PART | afb=None | status=draft | grade=None
Zu einer Verpackungsserie gehören verschieden große würfelförmige Schachteln. Die Kantenlänge der kleinen Schachtel beträgt 5 cm. Die Kanten der mittleren Schachtel sind 1 cm länger als die doppelte Kantenlänge der kleinen Schachtel, und die Kanten der großen Schachtel sind 1 cm länger als die doppelte Kantenlänge der mittleren Schachtel.
  - Teil 1 [short_input] Gib die Kantenlängen der beiden anderen Schachteln an. Mittlere Schachtel / Große Schachtel
  - Teil 2 [mc] Wie viele der kleinen Schachteln passen höchstens in die große Schachtel? Kreuze an. || OPT: 4; 12; 16; 27; 64
  - Teil 3 [mc] Die Serie wird um eine vierte Schachtel, eine „Riesenschachtel", erweitert. Ihre Kantenlänge ist 1 cm länger als die doppelte Kantenlänge der großen Schachtel. Es sollen so viele kleine Schachteln wie möglich in die Riesenschachtel gepackt werden. Drei Schülerinnen haben aufgeschrieben, wie sie deren Anzahl berechnet haben. Kreuze jeweils an, ob die Argumentation richtig ist. || OPT: Lisa: richtig; Lisa: falsch; Frieda: richtig; Frieda: falsch; Erika: richtig; Erika: falsch
  => CA: {"1": ["Mittlere Schachtel:  11", "Große Schachtel:  23"], "2": ["e"]}

### [203] Schlüssel | MC | afb=I | status=draft | grade=None
Andrea hat an ihrem Schlüsselbund vier Schlüssel, die sehr ähnlich aussehen. Nur einer dieser Schlüssel passt in das Schloss ihrer Haustür. Wie groß ist die Wahrscheinlichkeit, dass die Haustür mit dem ersten Schlüssel aufgeht, den sie zufällig probiert? Kreuze an.

### [204] Schneekristalle | MC | afb=I | status=draft | grade=None
Hier ist ein Schneekristall abgebildet.

Wie viele Symmetrieachsen hat dieser Schneekristall (von kleinen Abweichungen abgesehen)? Kreuze an.
  => CA: ["c"]

### [205] Schnittpunkt von Graphen | SHORT_TEXT | afb=I | status=draft | grade=None
Zwei lineare Funktionen g und f haben die Funktionsgleichungen g(x) = 2x − 1 und f(x) = −x + 2.

Gib die Koordinaten des Schnittpunkts der Graphen beider Funktionen an.
  => CA: ["Die beiden Graphen schneiden sich im Punkt S( 1", "Anmerkung:", "Der inhaltliche Kern dieses Items ist die Idee des Gleichsetzens.", "Ob dies rechnerisch oder zeichnerisch geschieht, ist unerheblich

### [206] Schokoladenbonbons | MULTI_PART | afb=None | status=draft | grade=None
In einer Bonbondose befinden sich 10 Schokoladenbonbons. Sie sehen von außen alle gleich aus. 5 dieser Bonbons sind mit Vollmilchschokolade, 3 mit dunkler Schokolade und 2 mit weißer Schokolade gefüllt.
  - Teil 1 [short_input] Gib die Wahrscheinlichkeit dafür an, bei der ersten Entnahme ein Bonbon mit weißer Schokoladenfüllung zu bekommen.
  - Teil 2 [mc] In einer zweiten Bonbondose sind 7 Bonbons mit Vollmilchschokolade, 3 mit dunkler Schokolade und 4 mit weißer Schokolade gefüllt.
Bei welcher Bonbondose ist die Wahrscheinlichkeit größer, bei der ersten Entnahme ein Bonbon mit dunkler Schokolade zu erhalten? Kreuze an. Begründe deine Antwort. || OPT: Bonbondose 1; Bonbondose 2; Die Wahrscheinlichkeit ist beide Male gleich.
  => CA: {"2": ["Bonbondose 1", "UND", "korrekte Begründung, bei der die Wahrscheinlichkeiten, ein Bonbon mit dunkler Schokolade aus einer der beiden Dosen zu ziehen, verglichen werden."]}

### [207] Schokoladenfiguren | NULL | afb=None | status=draft | grade=None
In der Zeitung war über die Produktion von Schokoladenfiguren zu lesen: „Der Osterhase liegt deutlich vor dem Weihnachtsmann: Schätzungsweise 100 Millionen Hasen wurden im Jahr 2008 zum Osterfest produziert." Das Kreisdiagramm zeigt die Anteile der Weihnachtsmänner und Osterhasen an der Produktion dieser Schokoladenfiguren.

### [208] Schokoladenpreis | MULTI_PART | afb=None | status=draft | grade=None
Ein Laden verkauft selbstgemachte Schokolade. Beispiele aus dem Angebot: Es gibt keine Sonderangebote.
  - Teil 1 [short_input] Für eine Schokoladensorte ist in diesem Schaubild die Zuordnung der zwei Größen Schokoladenmenge (in g) → Schokoladenpreis (in €) dargestellt. Das folgende Wertepaar ist mit zwei gestrichelten Linien gekennzeichnet: 200 g → 3,00 €. Ein weiteres Wertepaar ist ebenfalls mit einer gestrichelten Linie hervorgehoben. Ergänze die fehlenden Angaben.
  - Teil 2 [mc] Um welche Schokoladensorte aus dem Angebot des Schokoladenladens handelt es sich bei dem Schaubild aus Teilaufgabe 1? Kreuze an. || OPT: Dunkle Schokolade; Weiße Schokolade; Milchschokolade; Gefüllte Schokolade
  => CA: {"1": ["g"], "2": ["a"]}

### [209] Schokolinsen | FREE_TEXT | afb=III | status=draft | grade=None
Auf dem Foto siehst du sehr viele Schokolinsen.

### [210] Schrankbreiten | SHORT_TEXT | afb=II | status=draft | grade=None
Die Einzelschränke gibt es in fünf verschiedenen Breiten. Man kann sie in unterschiedlichen Kombinationen nebeneinander stellen und erhält so für jedes Zimmer den passenden Schrank.

Stelle eine Schrankkombination von 135 cm Breite zusammen. Trage in die Tabelle die Anzahl der benötigten Einzelschränke ein.
  => CA: ["Eine der folgenden drei Schrank-Kombinationen muss angegeben sein.", "1 x 40 cm, 1 x 45 cm, 1 x 50 cm", "ODER", "3 x 30 cm, 1 x 45 cm", "ODER", "3 x 45 cm"]

### [211] Schulgrundstück | NULL | afb=None | status=draft | grade=None
Die Abbildung zeigt das Luftbild einer Schule. Darauf sind das Schulgrundstück (schwarz umrandet) und die Schulgebäude zu sehen.

### [212] Schulkleidung | NULL | afb=None | status=draft | grade=None
An einer Schule wird über die Einführung einheitlicher Schulkleidung diskutiert. Lisa und Paul haben im Internet eine Studie der Fachhochschule Münster zu diesem Thema gefunden. Dort wurden insgesamt 17 812 Schülerinnen und Schüler befragt. Auf die Frage „Wärst du bereit, Schulkleidung zu tragen?“ haben 9018 (50,6 %) der Befragten mit „ja“ geantwortet, 8136 (45,7 %) mit „nein“, der Rest hat keine Angaben gemacht.

### [213] Schulstatistik | NULL | afb=None | status=draft | grade=None
Im Diagramm ist dargestellt, wie viele Schulen es im Schuljahr 2008/2009 in Sachsen-Anhalt gab. Es werden vier Schulformen unterschieden.

### [214] Schwarz-Weiß-Würfel | NULL | afb=None | status=draft | grade=None
Bei einem fairen Spielwürfel (siehe Abbildung) sind die Seiten mit den Augenzahlen 1 und 6 schwarz gefärbt, die anderen vier Seiten mit den Augenzahlen 2, 3, 4 und 5 sind weiß.

### [215] Skala und Zahlen | SHORT_TEXT | afb=II | status=draft | grade=None
Zwei Zahlen sind auf dem obigen Ausschnitt der Zahlengeraden mit einem Pfeil markiert. Trage die zwei Zahlen in die Kästchen ein.

### [216] Spielwürfel | MULTI_PART | afb=None | status=draft | grade=None
Man nennt einen Spielwürfel fair, wenn jede seiner Seitenflächen nach einem Wurf mit derselben Wahrscheinlichkeit oben liegen kann. Solche Würfel können unterschiedlich viele Seitenflächen haben.
  - Teil 1 [short_input] Die Abbildung zeigt einen fairen 20-seitigen Spielwürfel, dessen Seitenflächen mit den Zahlen von 1 bis 20 beschriftet sind. Gib die Wahrscheinlichkeit dafür an, dass die Zahl 11 geworfen wird.
  - Teil 2 [mc] Die folgenden Aussagen beziehen sich auf faire Spielwürfel, deren Seitenflächen alle mit verschiedenen Zahlen beschriftet sind. Es geht um die Wahrscheinlichkeit eine bestimmte Zahl zu würfeln. Prüfe die Aussagen und kreuze jeweils an. || OPT: wahr; falsch

### [217] Sprechstunde | MULTI_PART | afb=None | status=draft | grade=None
Ein Arzt notiert an einem Vormittag, wie viele Mädchen und Jungen zur Sprechstunde kamen. Das Ergebnis hält er in folgender Liste fest:
  - Teil 1 [short_input] Gib an, wie viele Mädchen insgesamt an diesem Vormittag zur Sprechstunde kamen.
  - Teil 2 [short_input] Gib an, wie viele Kinder von 10:00 Uhr bis 12:00 Uhr zur Sprechstunde kamen.
  => CA: {"1": ["7"], "2": ["10"]}

### [218] Stammbrüche untersuchen | MULTI_PART | afb=None | status=draft | grade=None
Ein Bruch mit einer 1 im Zähler und einer beliebigen natürlichen Zahl größer 0 im Nenner heißt Stammbruch. 1/17 ist ein Beispiel für einen Stammbruch.
  - Teil 1 [short_input] Stammbrüche sollen nun der Größe nach geordnet werden. Ergänze die folgende Tabelle. Ein Beispiel ist bereits eingetragen.
  - Teil 2 [mc] Wie viele Stammbrüche sind kleiner als 1/10? Kreuze an. || OPT: 8; 9; 10; unendlich viele
  => CA: {"2": ["d"]}

### [219] Steile Straße | MULTI_PART | afb=None | status=draft | grade=None
Das Verkehrszeichen in Abbildung 1 gibt an, dass die Straße dort ein Gefälle von 12 % hat. Ein Gefälle von 12 % bedeutet, dass zwischen zwei Orten ein Höhenunterschied von 12 m besteht, wenn die zugehörige Horizontalstrecke 100 m lang ist (siehe Abbildung 2).
  - Teil 1 [short_input] Die Straße „An der Steilen Wand" in der sächsischen Stadt Meerane hat ein Gefälle von 13 %. Die Horizontalstrecke zwischen dem Beginn dieses Gefälles und dessen Ende beträgt ca. 250 m. Wie groß ist der Höhenunterschied, der auf diesem Straßenstück überwunden wird?
  - Teil 2 [short_input] Die steilste Straße der Welt liegt in Neuseeland und heißt „Baldwin Street". Ein sehr steiler Abschnitt der Straße überwindet bei einer Horizontalstrecke von 154 m einen Höhenunterschied von 47 m. Wie viel Prozent Gefälle hat die Straße auf diesem Abschnitt?
  - Teil 3 [short_input] Steigungen oder Gefälle werden manchmal nicht in Prozent wie in Abbildung 1, sondern durch die Größe des Winkels (siehe Abbildung 3) beschrieben. Gib die Größe des Winkels a an, der zu 100 % Gefälle gehört. Notiere deinen Lösungsweg.
  => CA: {"1": ["eine Zahl aus dem Intervall [32; 33]"], "2": ["eine Zahl aus dem Intervall [30; 31]"], "3": ["45", "UND", "Lösungsweg, bei dem der Winkel 45 berechnet oder argumentativ bzw. zeichnerisch herge

### [220] Sterne und Sandkörner | MULTI_PART | afb=None | status=draft | grade=None
Für große Zahlen gibt es Zahlwörter. Diese heißen, der Reihe nach notiert: Tausend, Million, Milliarde, Billion, Billiarde, Trillion, Trilliarde, Quadrillion und so weiter. Der Faktor zum nächstgrößeren Zahlwort ist dabei immer 1000.
Im folgenden Artikel der Zeitung „Der Tagesspiegel" wird ein solches Zahlwort verwendet. Darin heißt es:
„Es gibt viel mehr Sterne im All als Sandkörner auf der Erde. Das haben australische Astronomen ausgerechnet. Sie schauten sich mit Fernrohren einen kleinen Teil des Himmels an und schätzten auf dieser Grundlage die Zahl der Sterne. Sie kamen auf 70 Trilliarden Sterne. Damit ist die Anzahl der Sterne im All zehnmal so groß wie die der Sandkörner auf der Erde."
  - Teil 1 [short_input] Gib an, wie viele Sterne es laut Zeitungsartikel gibt.
______ Sterne
Notiere, wie viele Nullen diese Zahl insgesamt hat.
______ Nullen
  - Teil 2 [short_input] Ein Ausschreiben sehr großer Zahlen in Ziffern kann unübersichtlich sein. Deshalb wird beim Schreiben solcher Zahlen oftmals eine Zehnerpotenz 10ⁿ verwendet. Der Wert der Hochzahl n gibt die Anzahl der Stellen an, um die das Komma des Faktors vor der Zehnerpotenz verschoben wird.
Beispiel: Es ist 1000 = 1 · 10³. Man kann also 5000 als 5 · 10³ schreiben. Entsprechend kann man die Zahl 3217 als 3,217 · 10³ schreiben.
Ergänze im folgenden Beispiel die in der Zehnerpotenz fehlende Hochzahl.
70 Trilliarden = 7 · 10^___
  => CA: {"1": ["70 Trilliarden UND 22"], "2": ["22"]}

### [221] Strecke im Koordinatenkreuz | MULTI_PART | afb=None | status=draft | grade=None
In einem Koordinatensystem ist die Strecke AD gegeben.
  - Teil 1 [short_input] Die Strecke AD soll eine Seite des Quadrats ABCD sein. Gib die Koordinaten der zwei Punkte B und C des Quadrats an.
  - Teil 2 [short_input] Die Strecke AD soll an der y-Achse gespiegelt werden. Gib die Koordinaten der beiden Spiegelpunkte an.
  => CA: {"1": ["B ( 4,5 | 2,5 )   C ( 3 | 4 )", "B ( 3 | 4 )   C ( 4,5 | 2,5 )", "B ( 1,5 | - 0,5 )   C ( 0 | 1 )", "B ( 0 | 1 )   C ( 1,5 | - 0,5 )"], "2": ["A' (- 3 | 1 )   D' ( - 1,5 | 2,5 )"]}

### [222] Streichholzziehen | MC | afb=I | status=draft | grade=None
Herr Peters hält fünf Streichhölzer in seiner Hand (siehe Foto). Vier dieser Streichhölzer haben eine normale Länge, eines ist gekürzt. Herr Peters sagt: „Wer das kurze Streichholz zieht, macht unser Auto sauber.“ Sein jüngster Sohn zieht als Erster ein Streichholz.

Wie groß ist die Wahrscheinlichkeit, dass er das kurze Streichholz zieht? Kreuze an.
  => CA: ["b"]

### [223] Suche die Zahl | SHORT_TEXT | afb=I | status=draft | grade=None
Schreibe die richtigen Zahlen in die Kästchen. 5 × ☐ = 10   3 × ☐ = 24   7 × ☐ = 21
  => CA: ["5   = 10  3     = 24  7   = 21"]

### [224] Säulenhöhe | MULTI_PART | afb=None | status=draft | grade=None
Das Diagramm zeigt drei Säulen mit unterschiedlicher Höhe.
  - Teil 1 [short_input] Gib die durchschnittliche Höhe dieser drei Säulen an.
  - Teil 2 [short_input] Eine weitere Säule wird in das Diagramm eingezeichnet. Die durchschnittliche Höhe der vier Säulen beträgt nun 7 cm. Wie hoch ist die vierte Säule?
  => CA: {"1": ["6"], "2": ["10"]}

### [225] Tabelle | MC | afb=II | status=draft | grade=None
Die Tabelle zeigt einen Zusammenhang zwischen a und b.

Welche der folgenden Gleichungen passt zu diesem Zusammenhang? Kreuze an.
  => CA: ["[pic]"]

### [226] Tabelle ausfüllen | SHORT_TEXT | afb=I | status=draft | grade=None
Die Tabelle zeigt eine proportionale Zuordnung.

Ergänze den fehlenden Wert.

### [227] Tankinhalt | SHORT_TEXT | afb=I | status=draft | grade=None
Der Bordcomputer eines Autos zeigt während der Fahrt den aktuellen Durchschnittsverbrauch in Liter pro 100 km an (l/100 km).

Er zeigt auch an, wie viele Kilometer man noch fahren kann, bis der Tank leer ist. Diese Entfernung errechnet der Bordcomputer fortlaufend neu. Er berücksichtigt dabei den aktuellen Durchschnittsverbrauch und den aktuellen Tankinhalt.

Berechne mithilfe der angezeigten Daten, wie viele Liter Kraftstoff in diesem Moment noch ungefähr im Tank sind.
  => CA: ["eine Zahl aus dem Intervall [49; 50]"]

### [228] Temperatur | MULTI_PART | afb=None | status=draft | grade=None
In Europa werden Temperaturen in Grad Celsius (°C) angegeben, in den USA in Grad Fahrenheit (°F). Es gibt eine Regel für die Umrechnung: Multipliziere die Temperatur in °C mit 1,8 und addiere zum Ergebnis 32, dann erhältst du die Temperatur in °F.
  - Teil 1 [short_input] Gib die Temperatur 5 °C in der Einheit °F an.
  - Teil 2 [short_input] Gib eine Formel für die Umrechnung von Temperaturen in °C nach °F an. Dabei soll C für Temperaturen in °C stehen und F für Temperaturen in °F.
  => CA: {"1": ["41"]}

### [229] Temperaturdifferenz | NUMERIC | afb=I | status=ready | grade=None
An einem Herbsttag misst Tim morgens im Garten eine Temperatur von -1°C.
Am Nachmittag beträgt die Temperatur an der gleichen Stelle 18°C.
Gib an, um wie viel Grad Celsius die Temperatur angestiegen ist.
  => CA: ["19"]

### [230] Temperaturen in Frankfurt am Main | NULL | afb=None | status=draft | grade=None
Die Tabelle und das Diagramm zeigen für Frankfurt am Main die langjährigen Durchschnittstemperaturen der einzelnen Monate in °C.

### [231] Thermometer | NULL | afb=None | status=draft | grade=None


### [232] Tombola zum Schulfest | NULL | afb=None | status=draft | grade=None
Bei einer Tombola auf einem Schulfest befinden sich 200 Lose in einem Gefäß. Davon sind 70 kleine Gewinne, 30 mittlere Gewinne und 10 Hauptgewinne. Der Rest sind Nieten.

### [233] Traktor | MC | afb=II | status=draft | grade=None
Von einem Traktor werden Spielzeugmodelle in den folgenden Maßstäben hergestellt: 1 : 120, 1 : 87, 1 : 50, 1 : 32

Bei welchem Maßstab ist das Modell am kleinsten? Kreuze an.
  => CA: ["a"]

### [234] Trapez ohne Symmetrie | MC | afb=II | status=draft | grade=None
Das dargestellte Trapez hat keine Symmetrieachse.

Entscheide jeweils, ob die folgenden Begründungen richtig sind. Kreuze an.

### [235] Trapezvariation | MULTI_PART | afb=None | status=draft | grade=None
Den Flächeninhalt A eines Trapezes kann man mit folgender Formel berechnen:
A = (a + c) · h / 2
(Skizze: Trapez ABCD mit Grundseite a, Parallelseite c und Höhe h)
  - Teil 1 [mc] Wie verändert sich der Flächeninhalt, wenn man die Höhe h verdoppelt (a und c aber konstant bleiben)? Kreuze an. || OPT: Der Flächeninhalt wird quadriert.; Der Flächeninhalt wird verdoppelt.; Der Flächeninhalt wird um 2 größer.; Ohne konkrete Werte kann man diese Frage nicht beantworten.
  - Teil 2 [mc] Die Höhe h soll sich nicht verändern. Kann man dann die Längen der Seiten a und c so verändern, dass der Flächeninhalt des Trapezes gleich bleibt? Kreuze an. Begründe deine Antwort. || OPT: Ja; Nein
  => CA: {"1": ["b"], "2": ["Ja", "UND", "Begründung (auch anhand eines Beispiels) über die gleichbleibende Summe der Seitenlängen a und c."]}

### [236] Treppenmaße | MULTI_PART | afb=None | status=draft | grade=None
Man muss jeden Tag viele verschiedenartige Treppen überwinden. Damit man das Treppensteigen als angenehm empfindet, orientieren sich Treppenbauer an der folgenden Schrittmaßregel (siehe Abbildung): Schrittmaßregel: 2 · h + b = 63 cm
  - Teil 1 [mc] In der folgenden Tabelle sind die Maße von zwei Treppen angegeben. Kreuze jeweils an, ob die Schrittmaßregel erfüllt ist. Begründe deine Antwort durch eine Rechnung. || OPT: Bei Treppe 1 ist die Schrittmaßregel erfüllt. — ja; Bei Treppe 1 ist die Schrittmaßregel erfüllt. — nein; Bei Treppe 2 ist die Schrittmaßregel erfüllt. — ja; Bei Treppe 2 ist die Schrittmaßregel erfüllt. — nein
  - Teil 2 [short_input] Eine Wohnhaustreppe hat einen Auftritt von b = 27 cm. Gib die Tritthöhe gemäß der Schrittmaßregel an.
  - Teil 3 [mc] Beim Bau einer Treppe soll die Schrittmaßregel 2 · h + b = 63 cm beachtet werden. Peter behauptet: „Es gilt dann: Je kleiner die Tritthöhe h, desto größer der Auftritt b." Hat Peter Recht? Kreuze an. Begründe deine Antwort. || OPT: Ja; Nein
  - Teil 4 [short_input] Eine Treppe hat eine Steigung von 45°. Die Schrittmaßregel 2 · h + b = 63 cm ist erfüllt. Gib an, welche Maße die Tritthöhe h und der Auftritt b dann haben müssen.
  => CA: {"1": ["ODER", "ODER"], "2": ["18"], "3": ["Ja", "UND", "richtige Begründung, in welcher darauf verwiesen wird, dass bei Verkleinerung von h der Summand b größer werden muss, um die Summe 63 zu erhalt

### [237] Tropfender Wasserhahn | NULL | afb=None | status=draft | grade=None
Bei Familie Rector tropft seit einigen Tagen ein undichter Wasserhahn.
Ben, der Sohn der Familie, will untersuchen, wie viel Wasser dabei verloren geht. Er fängt das gleichmäßig tropfende Wasser in einem Messbecher auf.

### [238] Tunnelbohrmaschine | NULL | afb=None | status=draft | grade=None
Die Tunnelbohrmaschine VERA (Von der Elbe Richtung Alster) begann am 15. Mai 2008 mit dem Ausbohren des Fahrtunnels für die neue Hamburger U-Bahnlinie U4. Diese Tunnelbohrmaschine schafft durchschnittlich 10 m Tunnellänge in 24 Stunden. Für den Bau dieses Tunnels sind bei pausenlosem Betrieb vierzig Wochen (also 280 Tage) angesetzt.

### [239] Umfang und Fläche | NULL | afb=None | status=draft | grade=None


### [240] Unfertiger Würfel | MULTI_PART | afb=None | status=draft | grade=None
Hier wurde begonnen, aus kleinen Würfeln der Kantenlänge 1 cm einen großen Würfel zusammenzusetzen, der die Kantenlänge 4 cm haben soll. Die in der Zeichnung verdeckten Würfel sind schon alle eingebaut.
  - Teil 1 [short_input] Peter will zuerst die beiden unteren Schichten vervollständigen. Gib an, wie viele Würfel er dafür noch benötigt.
  - Teil 2 [mc] Stell dir vor, du könntest um das Gebilde aus der Zeichnung herumgehen. Wie viele Seitenflächen der kleinen Würfel kannst du dann insgesamt von rechts, von hinten, von links und von vorne sehen? Kreuze an. || OPT: 19; 32; 38; 51
  => CA: {"1": ["12 (Würfel)"], "2": ["c"]}

### [241] Ungewöhnlicher Mittelwert | NULL | afb=None | status=draft | grade=None


### [242] Ungewöhnlicher Spielwürfel | NULL | afb=None | status=draft | grade=None
Dieser „Spielwürfel“ entstand, indem aus einem würfelförmigen Körper ein Viertel herausgeschnitten wurde. Er wurde aus verschiedenen Ansichten fotografiert.

### [243] Ungleichung erfüllen | SHORT_TEXT | afb=I | status=draft | grade=None
Gib drei natürliche Zahlen für z an, so dass die Ungleichung erfüllt ist.
  => CA: ["Angabe von drei der Zahlen 0, 1, 2, 3, 4, 5."]

### [244] Unregelmäßiges Viereck | FREE_TEXT | afb=III | status=draft | grade=None
Flächeninhalte von Rechtecken oder Dreiecken kann man leicht mit Formeln ausrechnen, wenn bestimmte Längen gegeben sind oder gemessen werden können. Hier ist ein Viereck abgebildet, für das es keine Formel zur direkten Berechnung des Flächeninhalts gibt.

Beschreibe möglichst genau, wie man den Flächeninhalt dieses Vierecks sehr genau bestimmen kann. Veranschauliche dein Vorgehen in der Abbildung, indem du z.B. die Strecken markierst oder einzeichnest, deren Länge du messen musst.

### [245] Verbindungsstrecken | MULTI_PART | afb=None | status=draft | grade=None
In der Abbildung sind fünf Punkte A, B, C, D und E gegeben. Jeder der vier Punkte A, B, C, D ist mit jedem anderen der vier Punkte A, B, C, D durch eine Strecke verbunden. So entstehen sechs verschiedene Verbindungsstrecken.
  - Teil 1 [short_input] Wie viele solcher Verbindungsstrecken entstehen zusätzlich, wenn man die Punkte A, B, C, D und E in gleicher Weise verbindet? Du kannst das in der Zeichnung oben ausprobieren.
  - Teil 2 [short_input] 20 Punkte liegen verteilt auf einem Kreis. Dann gibt es 190 verschiedene Verbindungsstrecken. Wie viele dieser Verbindungsstrecken gibt es insgesamt, wenn man einen 21. Punkt auf den Kreis hinzunimmt?
  => CA: {"1": ["4"], "2": ["210"]}

### [246] Verkehrszeichen | NULL | afb=None | status=draft | grade=None
Ist das Bild des Verkehrszeichens achsensymmetrisch? Kreuze jeweils an.

### [247] Verlauf des Graphen | NULL | afb=None | status=draft | grade=None


### [248] Verschiedene Rechtecke | MULTI_PART | afb=None | status=draft | grade=None
Das Diagramm zeigt Breiten und Längen von Rechtecken, die alle den Flächeninhalt 36 cm² haben. Beispielsweise gehört der Punkt B (2 | 18) zu einem Rechteck, das 2 cm breit und 18 cm lang ist.
  - Teil 1 [short_input] Gib an, wie breit und wie lang das Rechteck ist, das zum Punkt C gehört.
  - Teil 2 [short_input] Betrachte nun das Rechteck, das zum Punkt B gehört. Es gibt einen anderen Punkt, der zu einem deckungsgleichen Rechteck gehört. Welcher Punkt ist das?
  - Teil 3 [mc] Betrachte nun immer die beiden Punkte, die zu jeweils deckungsgleichen Rechtecken gehören. Entscheide, ob folgende Aussagen wahr oder falsch sind. Kreuze jeweils an. || OPT: Diese beiden Punkte haben vertauschte Koordinaten. — wahr; Diese beiden Punkte haben vertauschte Koordinaten. — falsch; Verbindet man jeweils diese beiden Punkte deckungsgleicher Rechtecke, so verlaufen alle entstehenden Geraden parallel zueinander. — wahr; Verbindet man jeweils diese beiden Punkte deckungsgleicher Rechtecke, so verlaufen alle entstehenden Geraden parallel zueinander. — falsch; Diese beiden Punkte liegen achsensymmetrisch zur Geraden mit der Gleichung y = x. — wahr; Diese beiden Punkte liegen achsensymmetrisch zur Geraden mit der Gleichung y = x. — falsch
  => CA: {"1": ["3", "UND", "12"], "2": ["H", "UND", "( 18 | 2 )"]}

### [249] Viele Brötchen | FREE_TEXT | afb=I | status=draft | grade=None
In der Bäckerei am Dorfplatz kostet ein Brötchen 0,30 €, egal wie viele Brötchen man kauft.

Schreibe die Bezeichnungen für die beiden Tabellenzeilen in die erste Spalte. Ergänze dann die fehlenden Werte, so dass man ablesen kann, was die jeweilige Anzahl Brötchen kostet.

### [250] Volumenverkleinerung | NULL | afb=None | status=draft | grade=None
Ein Würfel wird verkleinert. Das Volumen des neuen Würfels ist um ca. 27 % geringer als das Volumen des ursprünglichen Würfels.

### [251] Von links wie von rechts | MULTI_PART | afb=None | status=draft | grade=None
252 und 4774 sind natürliche Zahlen, die von links und rechts gelesen gleich sind. Zahlen mit dieser Eigenschaft heißen Palindromzahlen. Dabei darf die erste und letzte Ziffer keine Null sein. 252 ist zum Beispiel eine 3-stellige Palindromzahl und 4774 eine 4-stellige Palindromzahl.
  - Teil 1 [short_input] Ergänze die Zahl 38 zu einer 4-stelligen Palindromzahl und zu einer 5-stelligen Palindromzahl.
  - Teil 2 [mc] Wie viele verschiedene 4-stellige Palindromzahlen gibt es? Kreuze an. || OPT: 16; 72; 81; 90; 100
  => CA: {"1": ["Angabe einer 4-stelligen Palindromzahl:", "3883 ODER 8338", "UND", "Angabe einer 5-stelligen Palindromzahl:"], "2": ["d"]}

### [252] Waage | MULTI_PART | afb=None | status=draft | grade=None
Beim Wiegen von 9 Schülern einer Klasse wurden folgende Gewichte notiert:
  - Teil 1 [short_input] Die Gewichte sollen nach ihrer Größe geordnet werden. Ergänze: 54 kg   ___ kg   ___ kg   56 kg   57 kg   ___ kg   ___ kg   ___ kg   69 kg
  - Teil 2 [short_input] Gib den Gewichtsunterschied zwischen dem schwersten und dem leichtesten Schüler an.
  => CA: {"2": ["15"]}

### [253] Wahl | MULTI_PART | afb=None | status=draft | grade=None
Bei einer Wahl erreichten die Parteien A, B, C und D folgende Ergebnisse:
  - Teil 1 [short_input] Zur Wahl traten auch noch weitere Parteien an, die wegen ihrer geringen Stimmenzahl nicht im Diagramm auftauchen. Wie viel Prozent der Stimmen entfielen insgesamt auf diese weiteren Parteien?
  - Teil 2 [short_input] 24 Millionen Menschen gingen zur Wahl. Wie viele Menschen haben demnach die Partei A gewählt?
  => CA: {"1": ["3,6"], "2": ["eine Zahl aus dem Intervall [7 920 000; 8 160 000]"]}

### [254] Wahrscheinlicher | MC | afb=I | status=draft | grade=None
Welches der beiden Ereignisse hat die höhere Wahrscheinlichkeit? Kreuze an. Begründe deine Entscheidung.
  => CA: ["Beim einmaligen Werfen einer Münze liegt \"Kopf\" oben.", "UND", "Begründung mit", "- Verweis auf die Wahrscheinlichkeiten beider Ereignisse oder", "- Vergleich der Anzahlen der möglichen Ergebnisse

### [255] Weitsprung | NULL | afb=None | status=draft | grade=None
In der Klasse 8a wird im Sportunterricht Weitsprung trainiert. Jeder Schüler hat drei Versuche. Die Sportlehrerin gibt die drei Sprungweiten in ein Tabellenkalkulationsprogramm ein und lässt für jeden Schüler die mittlere Weite berechnen. So sieht die Tabelle für die zehn Mädchen der Klasse aus:

### [256] Werbelotterie | MULTI_PART | afb=None | status=draft | grade=None
Die Fluggesellschaft Trans American Airways (Kürzel TAA) veranstaltet eine Lotterie als Werbung. Aus einer Trommel werden zufällig nacheinander drei Kugeln mit Buchstaben gezogen. In der Trommel gibt es 9 Kugeln mit dem Buchstaben A, 4 Kugeln mit dem Buchstaben T und 7 Kugeln mit dem Buchstaben X.
  - Teil 1 [short_input] Wie groß ist die Wahrscheinlichkeit, das Kürzel TAA in der richtigen Reihenfolge zu ziehen, wenn die Kugeln nicht zurückgelegt werden? Gib diese Wahrscheinlichkeit an.
  - Teil 2 [short_input] Wie groß ist die Wahrscheinlichkeit, das Kürzel TAA in der richtigen Reihenfolge zu ziehen, wenn die Kugeln nach jedem Ziehen zurückgelegt werden? Gib diese Wahrscheinlichkeit an.

### [257] Werbemarkt | SHORT_TEXT | afb=III | status=draft | grade=None
Die folgende Grafik stellt die Gesamtausgaben für Werbung in den Jahren 2010 bis 2015 dar.

Nimm an, dass sich die Gesamtausgaben für Werbung in den nächsten Jahren ähnlich weiterentwickeln. Gib unter dieser Voraussetzung eine Prognose ab, wie hoch die Gesamtausgaben für Werbung im Jahr 2018 ungefähr sein werden. Notiere deinen Lösungsweg.
  => CA: ["eine Zahl aus dem Intervall [24; 28]", "UND", "Überlegungen, bei denen die kontinuierliche und fast gleichmäßige Zunahme der Werbeausgaben in den Jahren 2010 bis 2015 auf die folgenden drei Jahre bi

### [258] Wettkampf wählen | SHORT_TEXT | afb=I | status=draft | grade=None
Zum Sportfest werden in den 7. Klassen zwei Wettkämpfe organisiert, je einer für Mädchen und einer für Jungen. Die Jungen und die Mädchen entscheiden durch Abstimmung, in welcher Sportart ihr Wettkampf ausgetragen werden soll.
So stimmen die Jungen ab:
So stimmen die Mädchen ab:

In welcher Sportart soll der Wettkampf der Jungen bzw. der Wettkampf der Mädchen nun ausgetragen werden? Ergänze. Jungen: / Mädchen:
  => CA: ["Jungen: Fußball", "UND", "Mädchen: Volleyball"]

### [259] Winkel Gamma | SHORT_TEXT | afb=III | status=draft | grade=None
In diesem Dreieck sind die Strecken AM, MB und MC gleich lang. (nicht maßstabsgerecht) Niki behauptet: „Dann ist g = g1 + g2 ein rechter Winkel." Dazu will sie einen Beweis in der Klasse vortragen. Sie hat ihre Argumentationsschritte auf Karteikarten notiert, die sie der Reihe nach an die Tafel heften will. Hier sind die noch nicht sortierten Karten: K1: g = g1 + g2 | K2: AMC und MBC sind gleichschenklige Dreiecke. | K3: 2g1 + 2g2 = 180° ⇒ g1 + g2 = 90° ⇒ g = 90° | K4: Daraus folgt, dass die Basiswinkel gleich groß sind, also: | K5: Einsetzen in den Winkelsummensatz für Dreiecke: | K6: a + b + g = 180°; g1 + g2 + g1 + g2 = 180°; Zusammenfassen: | K7: MC ist genauso lang wie AM und wie BM, also gilt: | K8: a = g1 und b = g2

Bringe alle Argumentationskarten für Nikis Vortrag in eine logisch richtige Reihenfolge. Trage hierzu die restlichen Kartennummern in der Reihenfolge des Vortrags ein:
  => CA: ["Die korrekte Reihenfolge der Karten wird notiert:"]

### [260] Winkel im Dreieck | SHORT_TEXT | afb=II | status=draft | grade=None

  => CA: ["90°"]

### [261] Winkel im Parallelogramm | SHORT_TEXT | afb=III | status=draft | grade=None
Das dargestellte Viereck ABCD ist ein Parallelogramm. Die Seite CD dieses Parallelogramms wird gedanklich auf der Geraden h hin und her verschoben. Dabei bleibt die Seite CD immer auf der Geraden h. Die Lage der Seite AB verändert sich nicht.
  => CA: ["Der Umfang des Parallelogramms ist für ( = 90° am kleinsten.", "UND Angabe einer Begründung, in der die systematische Variation", "des Winkels ( deutlich wird und der Zusammenhang zwischen der", "Gr

### [262] Winkel messen | NUMERIC | afb=I | status=draft | grade=None
Miss die Größe des Winkels a. Runde auf ganze Grad.
  => CA: ["43"]

### [263] Winkelwürfel | MULTI_PART | afb=None | status=draft | grade=None
Um einen „Winkelwürfel" herzustellen, wurde aus einem Holzwürfel ein Viertel herausgeschnitten (siehe Abbildung). Als Ergebnis eines Wurfes gelten die Punkte, die oben liegen. Beim Würfeln treten die folgenden Ergebnisse auf: 1, 2, 3, 4, 5 (siehe Abbildung).
  - Teil 1 [mc] Einige Ergebnisse sind aufgrund der Form des Winkelwürfels sicherlich gleichwahrscheinlich. Kreuze jeweils an. Das Ergebnis 1 ist gleichwahrscheinlich mit … / Das Ergebnis 5 ist gleichwahrscheinlich mit … || OPT: 2; 3; 4; 5; 1; 2; 3; 4
  - Teil 2 [short_input] Mit diesem Winkelwürfel wurde 1000-mal gewürfelt. Aus der Tabelle kannst du entnehmen, wie oft welches Ergebnis vorkam. Schätze damit unter Berücksichtigung der Symmetrien des Winkelwürfels die Wahrscheinlichkeiten der einzelnen Ergebnisse und trage sie in die Tabelle ein.
  => CA: {"1": ["a"], "2": ["5 Zahlen, deren Summe 1 ergibt", "UND", "gleiche Wahrscheinlichkeiten für die Ergebnisse \"1\" und \"2\" bzw. für \"3\" und \"5\""]}

### [264] Wo liegt C | NULL | afb=None | status=draft | grade=None


### [265] Wo sind die Punkte | NULL | afb=None | status=draft | grade=None
In einem Koordinatensystem ist eine Gerade g eingezeichnet.

### [266] Wundersame Rechenergebnisse | NULL | afb=None | status=draft | grade=None
Simone multipliziert einstellige, zweistellige bzw. dreistellige Zahlen mit den Faktoren 11, 101 und 1001. Sie wundert sich über die Rechenergebnisse, die sie erhält:
(1) 7 · 11 = 77    5 · 11 = 55
(2) 38 · 101 = 3838    45 · 101 = 4545
(3) 306 · 1001 = 306306    692 · 1001 = 692692

### [267] Würfelbau | NULL | afb=None | status=draft | grade=None
Marco hat kleine Würfel aufgestapelt und dann so miteinander verklebt, dass dieser Körper entstanden ist. Die in der Zeichnung verdeckten Würfel sind alle schon eingebaut.

### [268] Würfelkörper | NULL | afb=None | status=draft | grade=None
Ein Würfel ist aus lauter kleinen Würfeln zusammengesetzt (siehe Bild). Jeder der kleinen Würfel hat ein Volumen von 1 cm³.

### [269] Würfeln mit Quader | NULL | afb=None | status=draft | grade=None
Auf die Seitenflächen eines Quaders werden die Augenzahlen 1 bis 6 geschrieben. Nach 1000-fachem Werfen des Quaders ergab sich folgende Häufigkeitstabelle für die oben liegenden Augenzahlen:

### [270] Würfeln mit zwei Würfeln | NULL | afb=None | status=draft | grade=None
Für eine Verlosung wurde das Glücksspiel „Würfeln mit zwei Würfeln“ ausgewählt. In der folgenden Liste sind alle möglichen Ergebnisse beim Würfeln mit zwei Würfeln angegeben:
(1,1) (1,2) (1,3) (1,4) (1,5) (1,6)
(2,1) (2,2) (2,3) (2,4) (2,5) (2,6)
(3,1) (3,2) (3,3) (3,4) (3,5) (3,6)
(4,1) (4,2) (4,3) (4,4) (4,5) (4,6)
(5,1) (5,2) (5,3) (5,4) (5,5) (5,6)
(6,1) (6,2) (6,3) (6,4) (6,5) (6,6)

### [271] Würfelnetze | MC | afb=I | status=draft | grade=None
Bei welcher Abbildung handelt es sich um das Netz (Abwicklung) eines Würfels? Kreuze an.

### [272] Würfeloberfläche | MC | afb=III | status=draft | grade=None
Verkleinert man die Kantenlänge eines Würfels, verkleinert sich auch die Größe seiner Oberfläche.

Die Kantenlänge eines Würfels wird halbiert. Um wie viel Prozent verkleinert sich die Größe seiner Oberfläche? Kreuze an. Begründe deine Antwort.
  => CA: ["um 75 %", "UND", "(Begründung der Antwort (algebraisch, zeichnerisch, paradigmatisch, iterativ, inhaltlich)", "ODER", "an einem konkreten Beispiel.)"]

### [273] Würfelturm | MULTI_PART | afb=None | status=draft | grade=None
Wenn man einen Würfel auf einen Tisch legt, sind fünf Seitenflächen sichtbar (vorne, hinten, links, rechts und oben).
  - Teil 1 [mc] Zwei Würfel werden übereinander gestapelt. Kreuze an, wie viele Würfelseitenflächen sichtbar sind. Die oberste Würfelseitenfläche wird dabei mitgezählt. || OPT: 5; 8; 9; 10; 12
  - Teil 2 [short_input] Wie viele Würfelseitenflächen sind sichtbar, wenn man 3 bzw. 4 bzw. 10 Würfel übereinander stapelt? Die oberste Würfelseitenfläche wird dabei mitgezählt. Ergänze die folgende Tabelle.
  - Teil 3 [short_input] Nun werden n Würfel übereinander gestapelt. Gib eine Vorschrift (Formel) an, mit der man die Anzahl A(n) der sichtbaren Würfelseitenflächen allgemein berechnen kann. Die oberste Würfelseitenfläche wird dabei mitgezählt.
  => CA: {"1": ["c"], "3": ["n  4 + 1"]}

### [274] Würfelturm 2 | MULTI_PART | afb=None | status=draft | grade=None
In der Abbildung siehst du einen Würfelturm. Der erste Würfel hat die Kantenlänge a. Die darüber stehenden Würfel haben immer die halbe Kantenlänge des jeweils darunter stehenden Würfels.
  - Teil 1 [short_input] Gib an, wie oft der zweite Würfel in den ersten passt.
  - Teil 2 [short_input] Ergänze die Formel für das Gesamtvolumen V dieses Würfelturms. Außer a sollen keine weiteren Variablen benutzt werden.
  - Teil 3 [mc] Zwei weitere kleinere Würfel werden auf die vorhandenen drei Würfel gestapelt. Das heißt, die Kantenlänge dieser Würfel ist ebenfalls jeweils halb so groß wie die des darunter liegenden Würfels. Wie oft passt der fünfte Würfel in den ersten? Kreuze an. || OPT: 16-mal; 64-mal; 512-mal; 4096-mal
  => CA: {"1": ["8"], "2": ["ODER"]}

### [275] Zahl gesucht | MC | afb=I | status=draft | grade=None
Wenn 9x = 6,3; dann ist x = ? Kreuze an.
  => CA: ["[pic]"]

### [276] Zahl gesucht 2 | SHORT_TEXT | afb=II | status=draft | grade=None
Gegeben ist ein Zahlenstrahl.

Auf welche Zahl zeigt der Pfeil ungefähr? Schreibe die Zahl in das Kästchen.
  => CA: ["Angabe einer Zahl aus dem Intervall [240 000; 260 000]"]

### [277] Zahlen addieren | NULL | afb=None | status=draft | grade=None


### [278] Zahlen gesucht | FREE_TEXT | afb=I | status=draft | grade=None
Schreibe alle dreistelligen Zahlen auf, die aus den Ziffern 1, 2 und 3 gebildet werden können. In keiner der Zahlen darf eine dieser Ziffern mehrfach vorkommen.

### [279] Zahlenmauer | NULL | afb=None | status=draft | grade=None
Zahlenmauern sind aus Steinen gebaut.
Dabei steht in jedem Stein die Summe der beiden darunter liegenden Steine.

### [280] Zahlenstrahl | NULL | afb=None | status=draft | grade=None


### [281] Zahlensuche | SHORT_TEXT | afb=I | status=draft | grade=None
In der Tabelle sind jeweils eine natürliche Zahl, ihr Vorgänger (die vorangehende natürliche Zahl) und das Doppelte dieses Vorgängers einander zugeordnet.

Vervollständige die Tabelle.

### [282] Zahlensumme | MC | afb=II | status=draft | grade=None
Lässt sich jede natürliche Zahl, die größer als 5 ist, als Summe aus drei aufeinanderfolgenden natürlichen Zahlen darstellen? Kreuze an. Begründe deine Entscheidung.
  => CA: ["Richtige Antwort (Nein) UND richtige Begründung, auch durch", "Angabe eines begründeten Gegenbeispiels.", "z. B.", "[pic]    [pic]    [pic]", "Wenn a ein Vielfaches von 3 ist, dann ist n eine natürl

### [283] Zahlenwürfel | MULTI_PART | afb=None | status=draft | grade=None
Der faire Würfel im Foto hat 30 gleich große Seitenflächen. Diese sind mit den Zahlen 1 bis 30 beschriftet.
  - Teil 1 [short_input] Wie groß ist die Wahrscheinlichkeit, dass die Zahl 9 geworfen wird? Ergänze: Die Wahrscheinlichkeit beträgt … .
  - Teil 2 [mc] Wie groß ist die Wahrscheinlichkeit, eine ungerade Zahl zu werfen? Kreuze an. || OPT: 1/30; 1/15; 1/2; Das kann man nicht berechnen, ohne zu wissen, wie häufig gewürfelt wird.
  - Teil 3 [mc] Stefan hat diesen Würfel 29-mal geworfen. Dabei ist kein einziges Mal die Zahl 2 gefallen. Er sagt: „Beim nächsten Wurf fällt mit Sicherheit die 2, da bei 30 Würfen jede Zahl einmal fallen muss.“ Hat Stefan Recht? Kreuze an. Begründe deine Entscheidung. || OPT: Ja; Nein
  => CA: {"1": ["(oder gleichwertige Angabe, wie z. B.  3, %)"], "2": ["c"], "3": ["Nein", "UND", "eine Antwort, in welcher auf einen der folgenden Aspekte Bezug genommen wird:", "- Unabhängigkeit der einzelne

### [284] Zeitangabe | MC | afb=I | status=draft | grade=None
Wie viele Minuten sind 2½ Stunden?
  => CA: ["c"]

### [285] Zeitumrechnung | NULL | afb=None | status=draft | grade=None
Meistens - z.B. auf einer Stoppuhr - gibt man eine Zeitspanne in Stunden, Minuten und Sekunden an. Zum Rechnen ist es aber oft praktischer, die Zeit als Dezimalzahl in Stunden anzugeben. Ein Beispiel: 1,5 Stunden bedeutet 1 Stunde und 30 Minuten.

### [286] Zoobesuch | MC | afb=I | status=draft | grade=None
Susann fährt mit dem Fahrrad zügig zum Zoo. Am Eingang muss sie einige Zeit warten, um eine Eintrittskarte zu kaufen. Dann geht sie zu Fuß weiter durch den Zoo.

Welches Diagramm passt am besten zu diesem Vorgang? Kreuze an.

### [287] Zufallsversuche | NULL | afb=None | status=draft | grade=None
Mit einem 12-seitigen Spielwürfel werden Zufallsversuche durchgeführt. Die Seiten dieses Würfels sind mit den Zahlen 1 bis 12 beschriftet.

### [288] Zuschauerzahlen | NULL | afb=None | status=draft | grade=None


### [289] Zwanzig Prozent | NUMERIC | afb=I | status=ready | grade=None
Gib 20% von 150€ an.
  => CA: ["30"]

### [290] Zwei Kreise | MULTI_PART | afb=None | status=draft | grade=None
In der Abbildung ist A der Mittelpunkt des Kreises K₁ und B der Mittelpunkt des Kreises K₂. Beide Kreise haben den gleichen Radius r = |AB|.
  - Teil 1 [mc] Prüfe jeweils, ob die folgenden Aussagen auf diese Figur zutreffen oder nicht. Kreuze an. || OPT: Alle Winkel im Dreieck ABH sind gleich groß. — wahr; Alle Winkel im Dreieck ABH sind gleich groß. — falsch; Das Dreieck BFH ist gleichseitig. — wahr; Das Dreieck BFH ist gleichseitig. — falsch; Das Dreieck DFH ist gleichschenklig. — wahr; Das Dreieck DFH ist gleichschenklig. — falsch; Im Dreieck AHD sind alle drei Winkel unterschiedlich groß. — wahr; Im Dreieck AHD sind alle drei Winkel unterschiedlich groß. — falsch
  - Teil 2 [mc] Sonja behauptet: „Der Flächeninhalt des großen Dreiecks DFH ist dreimal so groß wie der Flächeninhalt des kleinen Dreiecks ABH." Hat sie recht? Kreuze an. Begründe deine Antwort. || OPT: Ja; Nein
  => CA: {"2": ["Ja", "UND", "Begründung, die auf die gleiche Höhe beider Dreiecke und die dreifache Länge der Grundseite des Dreiecks  im Vergleich zur Grundseite des Dreiecks  abzielt."]}

### [291] Zwei Taschenrechner | NULL | afb=None | status=draft | grade=None
Yasmina und David lösen die Aufgabe „Werbeaktion“ mit dem Taschenrechner. Beide haben unterschiedliche Taschenrechner, aber beide drücken jeweils die gleiche Tastenfolge.
Trotzdem sehen sie unterschiedliche Ergebnisse:
Aufgabe: Werbeaktion
Werbeaktion: „20 % mehr zum gleichen Preis.“ Normalerweise sind in der Verpackung 250 g.
Wie viel ist jetzt in der Verpackung?
Tastenfolge: 2 5 0 + 2 0 % =
Yasminas Taschenrechner zeigt an: 300
Davids Taschenrechner zeigt an: 250+20% / 250,2

### [292] Zwei Thermometeranzeigen | NUMERIC | afb=I | status=draft | grade=None
Das linke Thermometer zeigt die Temperatur, die morgens gemessen wurde. Das rechte Thermometer zeigt die Temperatur, die mittags gemessen wurde.

Gib den Temperaturunterschied an.
  => CA: ["15"]

### [293] Zweite Gerade | FREE_TEXT | afb=I | status=draft | grade=None
Zeichne in dieses Koordinatensystem eine zweite Gerade ein, die eine größere Steigung als die dargestellte Gerade hat.

### [294] Zwischen zwei Zahlen | MC | afb=I | status=draft | grade=None
Welche der folgenden Zahlen liegt zwischen 0,06 und 0,07? Kreuze an.
  => CA: ["c"]

### [295] Zwischen zwei Zahlen 2 | NULL | afb=None | status=draft | grade=None


### [296] Zählung von Fahrzeugen | FREE_TEXT | afb=I | status=draft | grade=None
Eine Schülergruppe hat 500 Fahrzeuge beobachtet und gezählt. Ihre Ergebnisse haben die Schülerinnen und Schüler in folgender Tabelle dargestellt:

### [297] Überschlag doch mal | MC | afb=II | status=draft | grade=None
Max meint, dass er ziemlich viel Zeit in der Schule verbringt. Er fragt sich, wie viele Unterrichtsstunden es in acht Schuljahren wohl schon waren. Welche Zahl passt am besten? Kreuze an.
  => CA: ["b"]

### [298] Überschlagsrechnung | MC | afb=I | status=draft | grade=None
Das Ergebnis von 91 · 88 soll durch eine Überschlagsrechnung im Kopf annähernd ermittelt werden. Welche Überschlagsrechnung eignet sich dafür am besten? Kreuze an.
91 · 88 ≈
  => CA: ["b"]