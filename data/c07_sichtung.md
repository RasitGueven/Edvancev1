# C07 — Sichtungsliste MULTI_PART

Erzeugt aus `data/vera8_komplett_enriched.json` (`status='ready'`, `task_type='MULTI_PART'`) via `scripts/c07_sichtung.cjs`.

**Nichts hiervon ist importiert.** `status='ready'` heisst "Pipeline durchgelaufen", nicht "geprueft"
(`_derivation.review_durch_lena_erforderlich = true`). Der VORSCHLAG ist eine Maschinen-Empfehlung —
die Freigabe erfolgt durch einen Menschen. Defekte Texte sind markiert, nicht geraten.

**Bestand:** 86 Items · **ohne Flag:** 8 · **mit Flags:** 78

| Flag | Items | Bedeutung |
|---|---|---|
| Loesung unklar | 63 | Intervall, Mehrfachbedingung, Prosa, falsche Einheit oder fehlende Loesung statt eines Werts |
| nicht auto-gradebar | 51 | Zeichnen/Messen/Konstruieren/Freitext — oder die Auswertung beschreibt die Loesung nur |
| Asset fehlt | 31 | Abbildung/Tabelle noetig, aber kein verwendbares Asset |
| kein Stamm | 8 | Kein gemeinsamer Stamm von den Teilaufgaben abtrennbar |
| Text defekt | 5 | Zerfallene Extraktion: verschraenkte Zeichen, verdoppelte Buchstaben, zerfallene Brueche |
| Rechte unklar | 2 | Grafik vorhanden, aber vom eingebetteten Lizenzhinweis nicht gedeckt (C04) |
| Einheiten | 0 | Dieselbe Zahl in mehreren Einheiten (P01: keine Umrechnung) |

An den 8 flagfreien Items haengen **16 Teilaufgaben** und **31 Kompetenz-Datenpunkte** (TA x Kompetenz).

Flagfreie Items stehen zuerst — die sind am schnellsten durchzusehen. Danach steigt die Flag-Anzahl.

Zu pruefen ist bei jedem Item vor allem, **ob die Loesung stimmt** — das kann keine Maschine entscheiden.

---

===== 1/86 — Bevölkerungsdichte (id 1dfe444e)
STAMM:  Die Tabelle zeigt die Bevölkerungsdichte in den deutschen Bundesländern am 31.12.2009. Bevölkerungsdichte Bundesland (Einwohner pro km²) Baden-Württemberg | 301 Bayern | 177 Berlin | 3.861 Brandenburg | 85 Bremen | 1.637 Hamburg | 2.349 Hessen | 287 Mecklenburg-Vorpommern | 71 Niedersachsen | 166 Nordrhein-Westfalen | 524 Rheinland-Pfalz | 202 Saarland | 398 Sachsen | 226 Sachsen-Anhalt | 115 Sch…
TA 1:   [KURZTEXT] Gib das Bundesland an, in dem die Bevölkerungsdichte am 31.12.2009 fast 400 Einwohner pro km² betrug.  | Loesung: Saarland | AFB 1 | Kompetenzen: kom
TA 2:   [ZAHL] Gib die Differenz zwischen dem größten und dem kleinsten Wert der Bevölkerungsdichte an (Spannweite).  | Loesung: 3790 | AFB 1 | Kompetenzen: kom
FLAGS:  —
VORSCHLAG: rein   (Stamm sauber abtrennbar, alle Teilaufgaben mit eindeutiger Loesung, keine Defekte gefunden.)

===== 2/86 — Brötchen (id 2a0d3cca)
STAMM:  Marcus hat im Sonderangebot 3 Brötchen für insgesamt 95Cent gekauft. Ein einzelnes Brötchen kostet 40Cent.
TA 1:   [ZAHL] Gib an, wie viel Cent Marcus bei seinem Einkauf im Vergleich zu einem Kauf von drei einzelnen Brötchen gespart hat. Cent  | Loesung: 25 | AFB 1 | Kompetenzen: mod, ope
TA 2:   [MC] Frau Schwarz will 10 Brötchen kaufen. Bei welcher Variante zahlt sie am wenigsten? Kreuze an. Frau Schwarz kauft… … 10 Brötchen zum Einzelpreis. … 4 mal 3 Brötchen im Sonderangebot. … 3 mal 3 Brötchen im Sonderangebot u…  | Loesung: … 3 mal 3 Brötchen im Sonderangebot und 1 Brötchen zum Einzelpreis. | AFB 2 | Kompetenzen: ope, pro
FLAGS:  —
VORSCHLAG: rein   (Stamm sauber abtrennbar, alle Teilaufgaben mit eindeutiger Loesung, keine Defekte gefunden.)

===== 3/86 — Druckmaschinen (id 6148bd03)
STAMM:  Eine moderne Druckmaschine kann in vier Stunden 60000 Bögen Papier bedrucken.
TA 1:   [ZAHL] Mit einer solchen Druckmaschine werden 90000 Bögen Papier bedruckt. Gib an, wie lange dies dauert. Stunden  | Loesung: 6 | AFB 1 | Kompetenzen: mod, ope
TA 2:   [ZAHL] Bei einem Druckauftrag von insgesamt 60000 Bögen Papier drucken zwei solcher Druckmaschinen gleichzeitig. Gib an, wie lange dies dauert. Stunden  | Loesung: 2 | AFB 1 | Kompetenzen: mod, ope
FLAGS:  —
VORSCHLAG: rein   (Stamm sauber abtrennbar, alle Teilaufgaben mit eindeutiger Loesung, keine Defekte gefunden.)

===== 4/86 — Gewitter (id 0e7c507b)
STAMM:  Bei einem Gewitter sieht man den Blitz sofort und hört den dazugehörigen Donner erst später. Der Schall des Donners braucht etwa drei Sekunden, um einen Kilometer zurückzulegen.
TA 1:   [ZAHL] Ein Blitz ist zu sehen. Den Donner hört man nach 4,5 Sekunden. Gib an, wie weit der Blitz ungefähr entfernt ist. Der Blitz ist ungefähr km entfernt.  | Loesung: 1,5 | AFB 1 | Kompetenzen: kom, ope, pro
TA 2:   [MC] Ein Blitz ist in einer Entfernung von 5,5 Kilometern zu sehen. Nach ungefähr wie vielen Sekunden hört man den Donner? Kreuze an. 2,0s | 5,5s | 8,5s | 16,5s  | Loesung: 16,5s | AFB 1 | Kompetenzen: kom, ope, pro
FLAGS:  —
VORSCHLAG: rein   (Stamm sauber abtrennbar, alle Teilaufgaben mit eindeutiger Loesung, keine Defekte gefunden.)

===== 5/86 — Internetauktion (id ec7741ad)
STAMM:  Bei einer Internetauktion beobachtet Rolf die Preisentwicklung für Notebooks. Insgesamt werden neun Notebooks des gleichen Typs versteigert. Rolf hat sich folgende Endpreise für die Notebooks aufgeschrieben: Auktionsnummer | Endpreis 1 | 390€ 2 | 422€ 3 | 394€ 4 | 355€ 5 | 449€ 6 | 396€ 7 | 380€ 8 | 423€ 9 | 373€
TA 1:   [ZAHL] Wie groß ist der Preisunterschied zwischen dem teuersten und dem billigsten Notebook?  | Loesung: 94 € | AFB 1 | Kompetenzen: kom, ope
TA 2:   [ZAHL] Gib den durchschnittlichen Preis der neun Notebooks an.  | Loesung: 398 € | AFB 2 | Kompetenzen: mod, ope
FLAGS:  —
VORSCHLAG: rein   (Stamm sauber abtrennbar, alle Teilaufgaben mit eindeutiger Loesung, keine Defekte gefunden.)

===== 6/86 — Kopf und Körper (id cbcb88fb)
STAMM:  Als Faustregel sagt man, dass bei Babys die Länge des Kopfes zur | 1 gesamten Körpergröße ungefähr im Verhältnis 1:4 steht. Beim Erwachsenen dagegen ist dieses Verhältnis ungefähr 1:8. 4
TA 1:   [ZAHL] Ein Baby hat eine Kopflänge von 12cm. Gib seine ungefähre Körpergröße an. Körpergröße: | cm  | Loesung: 48 | AFB 1 | Kompetenzen: kom, ope
TA 2:   [ZAHL] Ein Erwachsener hat eine Körpergröße von 1,84m. Gib die ungefähre Länge seines Kopfes an. Länge des Kopfes: | cm  | Loesung: 23 | AFB 1 | Kompetenzen: kom, ope
FLAGS:  —
VORSCHLAG: rein   (Stamm sauber abtrennbar, alle Teilaufgaben mit eindeutiger Loesung, keine Defekte gefunden.)

===== 7/86 — Raten beim Test (id d0f547ce)
STAMM:  Christian beantwortet in einem Test alle vier Fragen nur durch Raten. Zu jeder Frage gibt es vier Antworten, von denen immer nur eine richtig ist.
TA 1:   [ZAHL] Wie groß ist die Wahrscheinlichkeit dafür, dass Christian bei der ersten Frage die richtige Antwort ankreuzt? Gib dein Ergebnis an.  | Loesung: 0,25 | AFB 1 | Kompetenzen: mod, ope
TA 2:   [MC] Wie groß ist die Wahrscheinlichkeit ungefähr, dass Christian bei allen vier Fragen des Tests die richtigen Antworten ankreuzt? Kreuze an. ca. 25% | ca. 4% | ca. 2,5% | ca. 0,4%  | Loesung: ca. 0,4% | AFB 2 | Kompetenzen: mod, ope
FLAGS:  —
VORSCHLAG: rein   (Stamm sauber abtrennbar, alle Teilaufgaben mit eindeutiger Loesung, keine Defekte gefunden.)

===== 8/86 — Verbindungsstrecken (id eade02ed)
STAMM:  In der Abbildung sind fünf Punkte A, B, C, D und E gegeben. Jeder der vier Punkte A, B, C, D ist mit jedem anderen der vier Punkte A, B, C, D durch eine Strecke verbunden. So entstehen sechs verschiedene Verbindungsstrecken.
TA 1:   [ZAHL] Wie viele solcher Verbindungsstrecken entstehen zusätzlich, wenn man die Punkte A, B, C, D und E in gleicher Weise verbindet? Du kannst das in der Zeichnung oben ausprobieren. Es gibt __________ zusätzliche Verbindungss…  | Loesung: 4 | AFB 1 | Kompetenzen: kom
TA 2:   [ZAHL] 20 Punkte liegen verteilt auf einem Kreis. Dann gibt es 190 verschiedene Verbindungsstrecken. Wie viele dieser Verbindungsstrecken gibt es insgesamt, wenn man einen 21. Punkt auf den Kreis hinzunimmt? Es gibt insgesamt …  | Loesung: 210 | AFB 3 | Kompetenzen: kom, pro
FLAGS:  —
VORSCHLAG: rein   (Stamm sauber abtrennbar, alle Teilaufgaben mit eindeutiger Loesung, keine Defekte gefunden.)

===== 9/86 — Anzahl von Nullen (id 6e8dba35)
STAMM:  — kein gemeinsamer Stamm abtrennbar —
TA 1:   [MC] Wie viele Nullen hat eine Milliarde, wenn man diese Zahl mit Ziffern schreibt? Kreuze an. 6 | 7 | 9 | 10 | 12  | Loesung: 9 | AFB 1 | Kompetenzen: ope
TA 2:   [ZAHL] Ergänze den fehlenden Wert. 1000 · = 1 Milliarde  | Loesung: 1 000 000 | AFB 1 | Kompetenzen: ope
FLAGS:  kein Stamm
        · kein Stamm: 2 Textteile = 2 Teilaufgaben — kein gemeinsamer Stamm abtrennbar
VORSCHLAG: raus   (Kein gemeinsamer Stamm abtrennbar — passt nicht auf den MULTI_PART-Vertrag.)

===== 10/86 — Dreieckszahlen (id d6ce757b)
STAMM:  Zahlen, die sich aus der Summe aufeinanderfolgender natürlicher Zahlen ergeben, heißen Dreieckszahlen. Dreieckszahlen, beginnend mit der 1, lassen sich veranschaulichen, indem man Plättchen in Dreiecksform legt. Abbildung 1 zeigt die Dreieckszahl 10, denn hierfür benötigt man 10 Plättchen. Man rechnet so: 1 + 2 + 3 + 4 = 10. Abbildung 1 Die Dreieckszahlen heißen D1, D2... In der folgenden Tabelle…
TA 1:   [KURZTEXT] Gib die beiden nächsten Dreieckszahlen D5und D6an. D5 = D6 =  | Loesung: D5 = 15 | AFB 2 | Kompetenzen: kom, pro
TA 2:   [MC] Welche Zahl muss man zur Dreieckszahl D10addieren, um die Dreieckszahl D11zu erhalten? Kreuze an. 6 | 9 | 10 | 11 | 12  | Loesung: 11 | AFB 2 | Kompetenzen: kom, pro
TA 3:   [FREITEXT] Gib eine Formel an, mit der man eine beliebige Dreieckszahl Dn aus deren Vorgängerdreieckszahl Dn-1berechnen kann. Dn=  | Loesung: Dn = Dn-1 + n | AFB 3 | Kompetenzen: kom, ope, pro
TA 4:   [FREITEXT] Peter möchte eine Formel entwickeln, mit der man eine Dreieckszahl Dn berechnen kann, ohne den Vorgänger zu kennen. Hierzu legt er zwei Darstellungen der Dreieckszahl D3so nebeneinander, dass 3 Reihen mit jeweils 4 Plät…  | Loesung: D4 = = 10 | AFB 2 | Kompetenzen: kom, ope, pro
TA 5:   [KURZTEXT] Gib eine Formel an, mit der man eine Dreieckszahl Dn direkt berechnen kann, ohne den Vorgänger zu kennen. Dn =  | Loesung: Dn = | AFB 3 | Kompetenzen: kom, ope, pro
FLAGS:  Asset fehlt
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: fixen   (Inhaltlich brauchbar, aber Asset fehlt muss vor dem Import haendisch geklaert werden.)

===== 11/86 — Eiscafé (id e31c7cc1)
STAMM:  Im Eiscafé Arnoldo kostet jede Kugel Eis 0,80 €. Eine Portion Sahne kostet 0,50 €.
TA 1:   [ZAHL] Gina kauft vier Kugeln Eis mit einer Portion Sahne. Wie viel muss Gina bezahlen? __________ €  | Loesung: 3,70 | AFB 1 | Kompetenzen: ope
TA 2:   [MC] Im Eiscafé Venezia bezahlt Max für fünf Kugeln Eis ohne Sahne 4,50 €. In welchem Eiscafé ist eine Kugel Eis günstiger? Kreuze an. ☐ Eiscafé Arnoldo ☐ Eiscafé Venezia Notiere deinen Lösungsweg.  | Loesung: Eiscafé Arnoldo | AFB 2 | Kompetenzen: kom, ope
FLAGS:  nicht auto-gradebar
        · nicht auto-gradebar: Pipeline-Befund: ta2_antwort_erfordert_begruendung
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 12/86 — Fehlende Zahlen (id 19763e5e)
STAMM:  Trage jeweils die fehlende Zahl in das Kästchen.
TA 1:   [ZAHL] + 9 = 4  | Loesung: -5 | AFB 1 | Kompetenzen: ope
TA 2:   [UNKLAR] 4 + | =-17  | Loesung: — | AFB 1 | Kompetenzen: ope
FLAGS:  Loesung unklar
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
VORSCHLAG: fixen   (Inhaltlich brauchbar, aber Loesung unklar muss vor dem Import haendisch geklaert werden.)

===== 13/86 — Gleichung verändern (id bf26638e)
STAMM:  Gegeben ist die Gleichung2⋅x+4=14.
TA 1:   [MC] Welche Lösung hat die Gleichung? Kreuze an. 3 | 5 | 7 | 10 | 12  | Loesung: 5 | AFB 1 | Kompetenzen: ope
TA 2:   [UNKLAR] Verändere in der Gleichung genau eine der drei Zahlen 2, 4 oder 14 so, dass die veränderte Gleichung die Lösung x= 9 hat. Gib eine passende neue Gleichung an.  | Loesung: — | AFB 2 | Kompetenzen: ope, pro
FLAGS:  Loesung unklar
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
VORSCHLAG: fixen   (Inhaltlich brauchbar, aber Loesung unklar muss vor dem Import haendisch geklaert werden.)

===== 14/86 — Gummibären (id 22ad5e1f)
STAMM:  Nach Herstellerangaben werden vor dem Abfüllen von Gummibären in Tüten die Bären folgendermaßen durchgemischt: Je ein Sechstel grüne, gelbe, weiße und orangefarbene Bären und ein Drittel rote Bären. Die Hälfte der roten Bären schmeckt nach Erdbeere, die andere Hälfte nach Himbeere.
TA 1:   [ZAHL] Jan greift sich mit geschlossenen Augen einen Gummibären aus einer frisch geöffneten Tüte. Mit welcher Wahrscheinlichkeit hat er Himbeergeschmack?  | Loesung: 80 | AFB 1 | Kompetenzen: kom, mod, ope
TA 2:   [MC] Fünf Gummibären wiegen 10g. Kreuze an, wie viele grüne Gummibären sich etwa in einer 1000g-Dose befinden. 20 | 60 | 80 | 160 | 330  | Loesung: 80 | AFB 2 | Kompetenzen: kom, mod, ope
FLAGS:  Loesung unklar
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
VORSCHLAG: fixen   (Inhaltlich brauchbar, aber Loesung unklar muss vor dem Import haendisch geklaert werden.)

===== 15/86 — Güterverkehr (id d4e47179)
STAMM:  Das Diagramm stellt für verschiedene Transportmittel den Zusammenhang zwischen den Kosten einer transportierten Tonne Ware und der Länge des Transportweges dar. Die Graphen gehen auch für Transportwege über 500km so weiter. Kosten je Tonne in € LKW 1000 Bahn Binnenschiff 500 100 | Länge des Transportweges in km 0 | 100 | 200 | 300 | 400 | 500
TA 1:   [ZAHL] Eine Tonne Ware soll 400km transportiert werden. Gib an, wie teuer dieser Transport mit der Bahn ist. €  | Loesung: 650 | AFB 1 | Kompetenzen: kom
TA 2:   [MC] Gib für einen Transportweg von 50km das günstigste Transportmittel an. Kreuze an. LKW | Bahn | Binnenschiff  | Loesung: LKW | AFB 1 | Kompetenzen: kom
FLAGS:  Asset fehlt
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: fixen   (Inhaltlich brauchbar, aber Asset fehlt muss vor dem Import haendisch geklaert werden.)

===== 16/86 — Muckibude (id b8d9b2c1)
STAMM:  Die Grafik zeigt die Mitgliederzahlen des Fitnessvereins „Muckibude“ in den Jahren 2012 bis 2016. [Säulendiagramm, x-Achse: Jahr, y-Achse: Anzahl der Mitglieder (0 bis 2000): 2012 200; 2013 400; 2014 800; 2015 1200; 2016 1800]
TA 1:   [ZAHL] Wie viele Mitglieder sind von 2013 bis 2014 hinzugekommen? __________ Mitglieder  | Loesung: 400 | AFB 1 | Kompetenzen: kom
TA 2:   [KURZTEXT] In welchen Jahren lag die Anzahl der Mitglieder über 1000? __________  | Loesung: 2015 UND 2016 | AFB 1 | Kompetenzen: kom
FLAGS:  Loesung unklar
        · Loesung unklar: TA 2: zwei Werte in einer Antwort ("2015 UND 2016") — als eine Eingabe nicht auswertbar
VORSCHLAG: fixen   (Inhaltlich brauchbar, aber Loesung unklar muss vor dem Import haendisch geklaert werden.)

===== 17/86 — Osterhase (id 5ab6a4b9)
STAMM:  Das Bild zeigt drei unterschiedlich große Schokoladenosterhasen. Der kleine Osterhase wiegt 25g, der mittlere Osterhase wiegt 100g und der große Osterhase wiegt 1000g.
TA 1:   [FREITEXT] 3 1cmSchokolade wiegt 1,3g. Der große Osterhase wird geschmolzen. 3 Gib an, wie viel cmSchokolade dabei ungefähr entstehen. 3 Es entstehen ungefähr cmSchokolade.  | Loesung: 769 ODER 769,2 ODER 770 | AFB 1 | Kompetenzen: kom, mod, ope
TA 2:   [MC] Die nachfolgende Tabelle enthält Aussagen über die drei Schokoladenosterhasen. Kreuze jeweils an, ob die Aussage wahr oder falsch ist. wahr | falsch Der kleine Osterhase wiegt ein Viertel des mittleren Osterhasen. Der m…  | Loesung: — | AFB 2 | Kompetenzen: kom, ope
FLAGS:  Loesung unklar
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
        · Loesung unklar: TA 1: zwei Werte in einer Antwort ("769 ODER 769,2 ODER 770") — als eine Eingabe nicht auswertbar
VORSCHLAG: fixen   (Inhaltlich brauchbar, aber Loesung unklar muss vor dem Import haendisch geklaert werden.)

===== 18/86 — Rathausuhr (id b55e40fd)
STAMM:  Die Rathausuhr hat einen hohen und einen tiefen Glockenton. Der hohe Glockenton erklingt · zur Viertelstunde einmal, · zur halben Stunde zweimal, · zur Dreiviertelstunde dreimal und · zur ganzen Stunde viermal. Der tiefe Glockenton gibt zusätzlich zu jeder vollen Stunde die Uhrzeit an, also um 1 Uhr (oder um 13 Uhr) mit einem Glockenschlag, um 2 Uhr (oder um 14 Uhr) mit zwei Glockenschlägen und s…
TA 1:   [MC] Wie oft erklingt der tiefe Glockenton im Zeitraum von kurz vor 1 Uhr bis kurz nach 4 Uhr? Kreuze an. 4-mal | 10-mal | 30-mal | 40-mal  | Loesung: 10-mal | AFB 1 | Kompetenzen: kom, ope
TA 2:   [FREITEXT] Denk dir eine kurze Aufgabe zu den Glockentönen der Rathausuhr aus, deren Ergebnis lautet: 10 Glockenschläge. In deiner Aufgabe sollen sowohl hohe als auch tiefe Glockentöne gezählt werden.  | Loesung: Aufgabe mit der Lösung 10 Glockenschläge | AFB 2 | Kompetenzen: kom, ope, pro
FLAGS:  nicht auto-gradebar
        · nicht auto-gradebar: Pipeline-Befund: ta2_antwort_ist_satz
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 19/86 — Rubbellose (id 05b40376)
STAMM:  Eine Bäckerei führt zur Fußball-EM eine Verlosung durch. Während der 25 Spieltage bekommt jeder Kunde beim Einkauf ein Los mit drei Rubbelfeldern. Nach dem Freirubbeln sieht man auf jedem Feld entweder ein Fußballbild oder einen freien Kreis. Es gilt folgender Gewinnplan: Rubbelfelder | Gewinn 3 Fußballbilder | ein echter Fußball 2 Fußballbilder, 1 freier Kreiseine Autofahne 1 Fußballbild, 2 frei…
TA 1:   [MC] Der erste Kunde bekommt ein Los. Mit welcher Wahrscheinlichkeit gewinnt er einen echten Fußball? Kreuze an. 1 | 3 | 1 | 1 | 1 3 | 25 | 25 | 300 | 7500  | Loesung: 1 | AFB 2 | Kompetenzen: kom, mod, ope
TA 2:   [ZAHL] Die Wahrscheinlichkeit für den ersten Kunden, eine Autofahne zu gewinnen, 11 | 2 beträgt . der Autofahnen sind Deutschlandfahnen, sind Fahnen anderer 253 | 3 Länder. Gib an, wie viele Deutschlandfahnen verlost werden. E…  | Loesung: 100 | AFB 2 | Kompetenzen: kom, mod, ope
FLAGS:  Text defekt
        · Text defekt: Bruchdarstellung zerfallen (Zaehler-/Nennerzeile getrennt): "1 | 3 | 1 | 1 | 1 / 3 | 25 | 25 | 300 | 7500"
VORSCHLAG: raus   (Quelltext ist zerfallen — nicht rekonstruierbar ohne Rueckgriff auf das Original.)

===== 20/86 — Schokoladenpreis (id 9730f1d5)
STAMM:  Ein Laden verkauft selbstgemachte Schokolade. Beispiele aus dem Angebot: Schokoladensorte | Preis für 100g Dunkle Schokolade | 1,50€ Weiße Schokolade | 1,40€ Milchschokolade | 1,10€ Gefüllte Schokolade | 2,10€ Es gibt keine Sonderangebote.
TA 1:   [ZUORDNUNG] Für eine Schokoladensorte ist in diesem Schaubild die Zuordnung der zwei Größen Schokoladenmenge (in g) à Schokoladenpreis (in €) dargestellt. Preis in € 10 9 8 7 6 5 4 3 2 1 0 | 1002003004005006007008009001000Menge in …  | Loesung: g | AFB 1 | Kompetenzen: kom
TA 2:   [MC] Um welche Schokoladensorte aus dem Angebot des Schokoladenladens handelt es sich bei dem Schaubild aus Teilaufgabe 1? Kreuze an. Dunkle Schokolade | Weiße Schokolade | Milchschokolade | Gefüllte Schokolade  | Loesung: Dunkle Schokolade | AFB 1 | Kompetenzen: kom
FLAGS:  Asset fehlt
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: fixen   (Inhaltlich brauchbar, aber Asset fehlt muss vor dem Import haendisch geklaert werden.)

===== 21/86 — Sprechstunde (id 7dbdbcae)
STAMM:  Ein Arzt notiert an einem Vormittag, wie viele Mädchen und Jungen zur Sprechstunde kamen. Das Ergebnis hält er in folgender Liste fest: Zeit | Mädchen | Jungen 9.00 –10.00Uhr 10.00 –11.00Uhr 11.00 –12.00Uhr
TA 1:   [ZAHL] Gib an, wie viele Mädchen insgesamt an diesem Vormittag zur Sprechstunde kamen. Mädchen  | Loesung: 7 | AFB 1 | Kompetenzen: kom
TA 2:   [ZAHL] Gib an, wie viele Kinder von 10:00Uhr bis 12:00Uhr zur Sprechstunde kamen. Kinder  | Loesung: 10 | AFB 1 | Kompetenzen: kom
FLAGS:  Asset fehlt
        · Asset fehlt: Text nennt eine Tabelle/Liste, die keine Datenzellen enthaelt — die Werte sind bei der Extraktion verloren gegangen
VORSCHLAG: fixen   (Inhaltlich brauchbar, aber Asset fehlt muss vor dem Import haendisch geklaert werden.)

===== 22/86 — Sterne und Sandkörner (id fa8efa54)
STAMM:  Für große Zahlen gibt es Zahlwörter. Diese heißen, der Reihe nach notiert: Tausend, Million, Milliarde, Billion, Billiarde, Trillion, Trilliarde, Quadrillion und so weiter. Der Faktor zum nächstgrößeren Zahlwort ist dabei immer 1000. Im folgenden Artikel der Zeitung „Der Tagesspiegel“ wird ein solches Zahlwort verwendet. Darin heißt es: „Es gibt viel mehr Sterne im All als Sandkörner auf der Erd.…
TA 1:   [FREITEXT] Gib an, wie viele Sterne es laut Zeitungsartikel gibt. Sterne Notiere, wie viele Nullen diese Zahl insgesamt hat. Nullen  | Loesung: 70 Trilliarden UND 22 | AFB 2 | Kompetenzen: kom, pro
TA 2:   [ZAHL] Ein Ausschreiben sehr großer Zahlen in Ziffern kann unübersichtlich sein. Deshalb wird beim Schreiben solcher Zahlen oftmals eine Zehnerpotenz 10ⁿverwendet. Der Wert der Hochzahl n gibt die Anzahl der Stellen an, um die…  | Loesung: 22 | AFB 2 | Kompetenzen: kom, ope, pro
FLAGS:  Loesung unklar
        · Loesung unklar: TA 1: zwei Werte in einer Antwort ("70 Trilliarden UND 22") — als eine Eingabe nicht auswertbar
VORSCHLAG: fixen   (Inhaltlich brauchbar, aber Loesung unklar muss vor dem Import haendisch geklaert werden.)

===== 23/86 — Thermometer (id a479369d)
STAMM:  — kein gemeinsamer Stamm abtrennbar —
TA 1:   [ZAHL] Gib an, welche Temperatur das Thermometer anzeigt. °C 40 30 20 10 0 -10 ° C  | Loesung: -8 | AFB 1 | Kompetenzen: kom, ope
TA 2:   [ZAHL] Später zeigt das Thermometer -3°C. Danach steigt die Temperatur um 15 Grad. Gib an, welche Temperatur das Thermometer nun anzeigt. Das Thermometer zeigt nun °C an.  | Loesung: 12 | AFB 1 | Kompetenzen: kom, mod
FLAGS:  kein Stamm
        · kein Stamm: 2 Textteile = 2 Teilaufgaben — kein gemeinsamer Stamm abtrennbar
VORSCHLAG: raus   (Kein gemeinsamer Stamm abtrennbar — passt nicht auf den MULTI_PART-Vertrag.)

===== 24/86 — Umfang und Fläche (id 63f59589)
STAMM:  1cm 1cm
TA 1:   [ZAHL] Gib an, wie lang der Umfang der dick umrandeten Figur ist. cm  | Loesung: 36 | AFB 1 | Kompetenzen: kom
TA 2:   [ZAHL] Gib den Flächeninhalt der dick umrandeten Figur an. cm²  | Loesung: 45 | AFB 2 | Kompetenzen: kom, pro
FLAGS:  Asset fehlt
        · Asset fehlt: der Stamm besteht nur noch aus Grafik-Bruchstuecken — die Aufgabe steckte in einer EMF-Zeichnung, die zu Text zerlegt wurde
VORSCHLAG: fixen   (Inhaltlich brauchbar, aber Asset fehlt muss vor dem Import haendisch geklaert werden.)

===== 25/86 — Unfertiger Würfel (id 79433e0c)
STAMM:  Hier wurde begonnen, aus kleinen Würfeln der Kantenlänge 1cm einen großen Würfel zusammenzusetzen, der die Kantenlänge 4cm haben soll. Die in der Zeichnung verdeckten Würfel sind schon alle eingebaut.
TA 1:   [KURZTEXT] Peter will zuerst die beiden unteren Schichten vervollständigen. Gib an, wie viele Würfel er dafür noch benötigt.  | Loesung: 12 (Würfel) | AFB 2 | Kompetenzen: kom, pro
TA 2:   [MC] Stell dir vor, du könntest um das Gebilde aus der Zeichnung herumgehen. Wie viele Seitenflächen der kleinen Würfel kannst du dann insgesamt von rechts, von hinten, von links und von vorne sehen? Kreuze an. 19 | 32 | 38 …  | Loesung: 38 | AFB 2 | Kompetenzen: kom, pro
FLAGS:  Asset fehlt
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: fixen   (Inhaltlich brauchbar, aber Asset fehlt muss vor dem Import haendisch geklaert werden.)

===== 26/86 — Waage (id 296c5cd3)
STAMM:  Beim Wiegen von 9 Schülern einer Klasse wurden folgende Gewichte notiert: Schüler | A | B | C | D | E | F | G | H | I Gewicht56kg65kg68kg56kg 69kg57kg56kg59kg54kg
TA 1:   [ZAHL] Die Gewichte sollen nach ihrer Größe geordnet werden. Ergänze. 54kg | kg | kg56kg | 57kg | kg | kg | kg69kg  | Loesung: 15 | AFB 1 | Kompetenzen: ope
TA 2:   [ZAHL] Gib den Gewichtsunterschied zwischen dem schwersten und dem leichtesten Schüler an. kg  | Loesung: 15 | AFB 1 | Kompetenzen: ope
FLAGS:  Loesung unklar
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
VORSCHLAG: fixen   (Inhaltlich brauchbar, aber Loesung unklar muss vor dem Import haendisch geklaert werden.)

===== 27/86 — Würfelturm 2 (id 26b5da96)
STAMM:  In der Abbildung siehst du einen Würfelturm. Der erste Würfel hat die Kantenlänge a. Die darüber stehenden Würfel haben immer die halbe Kantenlänge des jeweils darunter stehenden Würfels. [Dritter Würfel] [Zweiter Würfel] [Erster Würfel] [a] [a] [a]
TA 1:   [ZAHL] Gib an, wie oft der zweite Würfel in den ersten passt. __________ -mal  | Loesung: 8 | AFB 2 | Kompetenzen: kom, ope
TA 2:   [UNKLAR] Ergänze die Formel für das Gesamtvolumen V dieses Würfelturms. Außer a sollen keine weiteren Variablen benutzt werden. V = __________  | Loesung: — | AFB 2 | Kompetenzen: kom, ope
TA 3:   [MC] Zwei weitere kleinere Würfel werden auf die vorhandenen drei Würfel gestapelt. Das heißt, die Kantenlänge dieser Würfel ist ebenfalls jeweils halb so groß wie die des darunter liegenden Würfels. Wie oft passt der fünfte…  | Loesung: — | AFB 2 | Kompetenzen: ope, pro
FLAGS:  Loesung unklar
        · Loesung unklar: keine Loesung fuer TA 2,3
        · Loesung unklar: nur 1 Loesung(en) fuer 3 Teilaufgaben
VORSCHLAG: fixen   (Inhaltlich brauchbar, aber Loesung unklar muss vor dem Import haendisch geklaert werden.)

===== 28/86 — Ampelkarte (id 08681f3a)
STAMM:  Lebensmittel enthalten unter anderem Fett, gesättigte Fettsäuren, Zucker und Salz zu unterschiedlich hohen Anteilen. Die drei Farben der sogenannten Ampelkarte sollen helfen, die Höhe der jeweiligen Anteile einzustufen.
TA 1:   [KURZTEXT] Der folgenden Tabelle ist zu entnehmen, wann ein Anteil als gering, mittel oder hoch einzustufen ist. Alle Angaben beziehen sich auf 100g des Lebensmittels. Bestandteil | gering (grün)mittel (gelb)hoch (rot) Fett | < 3 …  | Loesung: Fett Farbe: rot | AFB 2 | Kompetenzen: kom, ope
TA 2:   [MC] Für Getränke gelten sogar nur halbe Werte im Vergleich zur Tabelle in Teilaufgabe 1. Alle Angaben beziehen sich auf 100ml des Getränks. Bestandteil | gering (grün)mittel (gelb)hoch (rot) Fett | < 1,5g | 1,5 –10g | > 10g…  | Loesung: — | AFB 2 | Kompetenzen: kom, ope
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: Pipeline-Befund: ta1_antwort_ist_satz
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 29/86 — Andere Länder - andere Noten (id 46c1b572)
STAMM:  In der Schweiz wird -anders als in Deutschland -eine sehr gute Leistung mit 6 benotet, und für eine sehr schlechte Leistung bekommt man die Note 1. So wird in einigen Schweizer Schulen die Note für eine Mathematikarbeit mit folgender Formel berechnet: Erreichte Punktzahl Note = | ⋅5+1 Maximalpunktzahl Die berechnete Note wird auf eine Stelle nach dem Komma gerundet, d.h. es gibt beispielsweise au…
TA 1:   [ZAHL] In einer Mathematikarbeit mit einer Maximalzahl von 50 Punkten wurden 30 Punkte erreicht. Gib an, welche Note in der Schweiz bei Anwendung der Formel erteilt wird. Note:  | Loesung: 4 | AFB 1 | Kompetenzen: kom, ope
TA 2:   [UNKLAR] In einer anderen Mathematikarbeit können maximal 100 Punkte erreicht werden. Ein Schüler bekommt nach der Formel die Note 5,5. Welche Punktzahl kann er erreicht haben? Gib eine mögliche Punktzahl an. Punkte Notiere dein…  | Loesung: — | AFB 2 | Kompetenzen: kom, ope
TA 3:   [UNKLAR] In den Niederlanden werden sogar die Noten 1 bis 10 vergeben. Die schlechteste Note ist die 1, die beste Note ist die 10. Stelle für die Niederlande eine Formel auf, mit der sich die Note aus der erreichten Punktzahl un…  | Loesung: — | AFB 2 | Kompetenzen: kom, mod, pro
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: Pipeline-Befund: ta2_antwort_erfordert_begruendung, ta3_loesung_ist_freitext
        · Loesung unklar: keine Loesung fuer TA 2,3
        · Loesung unklar: nur 1 Loesung(en) fuer 3 Teilaufgaben
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 30/86 — Aussagen über Dreiecke (id 867954dd)
STAMM:  C g a b b B a | c A (nicht maßstabsgerecht)
TA 1:   [MC] In einem Dreieck mit den Winkeln a, b undgsind b= 45° und g= 2 ×a. Wie groß ist a? Kreuze an. 45° | 67,5° | 90° | 135°  | Loesung: 45° | AFB 2 | Kompetenzen: ope, pro
TA 2:   [KURZTEXT] In einem Dreieck mit den Winkeln a, b undg gilt g= 2 ×a. Gib einen allgemeinen Term an, mit dessen Hilfe man die Größe von b in Abhängigkeit von a berechnen kann. b =  | Loesung: Richtiger Term | AFB 2 | Kompetenzen: kom, ope, pro
FLAGS:  nicht auto-gradebar, Asset fehlt
        · nicht auto-gradebar: TA 2: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Asset fehlt: der Stamm besteht nur noch aus Grafik-Bruchstuecken — die Aufgabe steckte in einer EMF-Zeichnung, die zu Text zerlegt wurde
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 31/86 — Außenthermometer (id 152f0961)
STAMM:  — kein gemeinsamer Stamm abtrennbar —
TA 1:   [MC] Ein Außenthermometer zeigt -4°C. Die Außentemperatur steigt um 6°Can. Wie hoch ist die Außentemperatur danach? Kreuze an. -10°C | -2°C | +2°C | +10°C  | Loesung: +2°C | AFB 1 | Kompetenzen: ope
TA 2:   [KURZTEXT] Ein Außenthermometer zeigt +8°Cund später -2°Can. Gib an, um wie viel Grad sich die Außentemperatur verändert hat. Grad  | Loesung: 10 ODER -10 | AFB 1 | Kompetenzen: ope
FLAGS:  kein Stamm, Loesung unklar
        · kein Stamm: 2 Textteile = 2 Teilaufgaben — kein gemeinsamer Stamm abtrennbar
        · Loesung unklar: TA 2: zwei Werte in einer Antwort ("10 ODER -10") — als eine Eingabe nicht auswertbar
VORSCHLAG: raus   (Kein gemeinsamer Stamm abtrennbar — passt nicht auf den MULTI_PART-Vertrag.)

===== 32/86 — Bahncard (id 7794c20d)
STAMM:  Wenn man öfter längere Strecken mit dem Zug fährt, lohnt es sich, eine Bahncard zu kaufen. Mit einer Bahncard erhält man ein Jahr lang bei jedem Kauf einer Fahrkarte eine Ermäßigung auf den Normalpreis. Der Normalpreis für eine Hin- und Rückfahrt auf der Strecke Hamburg-Berlin beträgt insgesamt 140,00 €.
TA 1:   [MC] Herr Krause besitzt eine Bahncard 25. Damit erhält er eine Ermäßigung von 25 % auf den Normalpreis. Wie viel muss er für die Hin- und Rückfahrt auf der Strecke Hamburg-Berlin insgesamt bezahlen? Kreuze an. ☐ 25,00 € ☐ 3…  | Loesung: 4 | AFB 1 | Kompetenzen: kom, mod, ope
TA 2:   [ZAHL] Frau Schnell kauft sich eine Bahncard 50. Damit erhält sie eine Ermäßigung von 50 % auf den Normalpreis. Für die Bahncard 50 bezahlt Frau Schnell 230,00 €. Wie oft muss Frau Schnell die Strecke Hamburg-Berlin (Hin- und …  | Loesung: 4 | AFB 2 | Kompetenzen: kom, mod, ope
FLAGS:  Loesung unklar, Rechte unklar
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
        · Rechte unklar: eingebetteter Lizenzhinweis nennt nur Text/Teilaufgaben, nicht "Grafik" — Grafik nicht gedeckt (C04)
VORSCHLAG: fixen   (Inhaltlich brauchbar, aber Loesung unklar + Rechte unklar muss vor dem Import haendisch geklaert werden.)

===== 33/86 — Berechnungen am Rechteck (id bf1a53fc)
STAMM:  3 mc (nicht maßstabsgerecht) 5cm
TA 1:   [ZAHL] Gib den Flächeninhalt des abgebildeten Rechtecks an.  | Loesung: 15 cm | AFB 1 | Kompetenzen: ope
TA 2:   [ZAHL] Gib den Umfang des abgebildeten Rechtecks an.  | Loesung: 16 cm | AFB 1 | Kompetenzen: ope
FLAGS:  Loesung unklar, Asset fehlt
        · Loesung unklar: TA 1: Flaeche mit Laengeneinheit ("15 cm") — Einheit falsch
        · Asset fehlt: der Stamm besteht nur noch aus Grafik-Bruchstuecken — die Aufgabe steckte in einer EMF-Zeichnung, die zu Text zerlegt wurde
VORSCHLAG: fixen   (Inhaltlich brauchbar, aber Loesung unklar + Asset fehlt muss vor dem Import haendisch geklaert werden.)

===== 34/86 — Colakästen (id 2db98053)
STAMM:  Ein Getränkemarkt hat Cola im Angebot: Ein Kasten mit 12 Flaschen kostet 6,66€. Hinzu kommen 3,30€ Pfand. Man bekommt die 3,30€ Pfand zurück, wenn man einen Kasten mit 12 leeren Flaschen zurückbringt. Für eine einzelne leere Flasche erhält man 0,15€ zurück.
TA 1:   [ZAHL] Tom bringt nur den Kasten (ohne Flaschen) zurück. Gib an, wie viel Geld er zurückbekommt. €  | Loesung: 1,50 € | AFB 2 | Kompetenzen: kom, mod, ope
TA 2:   [BEGRUENDUNG] Herr Melzer bringt 3 Kästen mit jeweils 12 leeren Colaflaschen zum Getränkemarkt und nimmt einen vollen Kasten Cola aus dem Angebot mit. Welche Aussage ist richtig? Kreuze an. Herr Melzer muss an der Kasse noch etwas be…  | Loesung: Herr Melzer muss an der Kasse noch etwas bezahlen. | AFB 1 | Kompetenzen: kom, mod, ope
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: TA 2: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Loesung unklar: TA 2: Intervall/Mehrfachbedingung/Prosa statt eines Werts
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 35/86 — Dreieck im Quadrat (id c49a3ed3)
STAMM:  Auf gleichgroßen quadratischen Zeichenblättern wird ein Muster mit gleichschenkligen Dreiecken entworfen. Das jeweils nachfolgende Zeichenblatt entsteht dadurch, dass man jedes Teilquadrat des Vorgängerblattes durch vier gleichgroße Quadrate mit je einem gleichschenkligen Dreieck ersetzt. Die ersten beiden Blätter sind hier gezeichnet: Zeichenblatt 1: | Zeichenblatt 2: a | a
TA 1:   [ZAHL] Gib an, wie viele gleichschenklige graue Dreiecke sich auf Zeichenblatt 3 befinden. Auf Zeichenblatt 3 befinden sich | gleichschenklige graue Dreiecke.  | Loesung: 16 | AFB 1 | Kompetenzen: kom, pro
TA 2:   [MC] Mit welchem Rechenschritt kann man die Anzahl der gleichschenkligen grauen Dreiecke auf einem beliebigen Zeichenblatt aus der Anzahl der gleichschenkligen grauen Dreiecke auf dem Vorgängerblatt berechnen? Kreuze an. Man…  | Loesung: · 4 | AFB 2 | Kompetenzen: kom, pro
TA 3:   [BEGRUENDUNG] Luca behauptet: „Je mehr gleichschenklige graue Dreiecke ein solches Zeichenblatt enthält, desto größer wird der Anteil der grauen Fläche an der Gesamtfläche.“ Stimmt diese Behauptung? Kreuze an. Ja | Nein Begründe dein…  | Loesung: — | AFB 3 | Kompetenzen: arg, kom, pro
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: TA 3: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Loesung unklar: keine Loesung fuer TA 3
        · Loesung unklar: nur 2 Loesung(en) fuer 3 Teilaufgaben
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 36/86 — Eindeutig (id bdf75f17)
STAMM:  Selina und Jasmin üben das Lösen von Gleichungen.
TA 1:   [MC] „Bei den folgenden Gleichungen sehe ich sofort, ohne zu rechnen, ob sie jeweils eine oder keine Lösung haben“, sagt Selina. Entscheide, ob die folgenden Gleichungen eine oder keine Lösung haben. Kreuze jeweils an. Es gi…  | Loesung: Angabe einer Gleichung, deren Lösungsmenge unendlich ist. | AFB 2 | Kompetenzen: ope, pro
TA 2:   [FREITEXT] Für eine weitere Gleichung finden beide Mädchen nicht nur eine, sondern unendlich viele Lösungen. Jasmin sagt: „Es gibt auch Gleichungen mit unendlich vielen Lösungen. In diese kann man für x jede beliebige Zahl einsetz…  | Loesung: Angabe einer Gleichung, deren Lösungsmenge unendlich ist. | AFB 3 | Kompetenzen: pro
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: Pipeline-Befund: ta2_antwort_ist_satz
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 37/86 — Fahrtrichtung geradeaus (id d110ce9b)
STAMM:  Dieses Verkehrszeichen zeigt an: „Vorgeschriebene Fahrtrichtung -geradeaus“.
TA 1:   [ZEICHNEN] Zeichne eine Symmetrieachse in das Bild ein.  | Loesung: 1 | AFB 1 | Kompetenzen: kom
TA 2:   [MC] Wie viele Symmetrieachsen hat dieses Verkehrszeichen insgesamt? Kreuze an. 1 | 2 | 3 | 4  | Loesung: 1 | AFB 1 | Kompetenzen: kom
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: TA 1: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 38/86 — Freibad (id a03f3371)
STAMM:  Das Freibad in Burgdorf wurde am 1. Juni geöffnet. Am 1. Juli begannen die sechs Wochen dauernden Sommerferien. Insgesamt kamen vom 1. Juni bis zum Ende der Sommerferien 35 681 Besucherinnen und Besucher in das Freibad. Das Diagramm zeigt die Zahlen der Besucherinnen und Besucher für Juni und für jede Woche der Sommerferien. [Säulendiagramm: Anzahl der Besucherinnen und Besucher — Juni 3845; 1. F…
TA 1:   [ZAHL] Gib an, wie viele Personen das Freibad während der 6 Wochen Sommerferien im Durchschnitt pro Woche besucht haben. __________ Personen  | Loesung: 5306 | AFB 2 | Kompetenzen: kom, ope
TA 2:   [BEGRUENDUNG] Im Juni war das Wetter schlecht und das Freibad war an vielen Tagen leer. Aber in den Sommerferien war das Wetter schön und das Freibad hatte viele Besucherinnen und Besucher. Die Betreiber des Freibads wollten die Zahl…  | Loesung: — | AFB 3 | Kompetenzen: kom
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: TA 2: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 39/86 — fuehrerschein (id 9d348884)
STAMM:  Einen Führerschein zu | Durchfallquoten Bundesland bekommen, ist nicht einfach. | Führerscheinprüfungen Die Tabelle gibt für die Theorie Praxis einzelnen Bundesländer an, (in %) | (in%) wie viel Prozent der Theorie- Baden-Württemberg | 30,1 | 21,6 Prüfungen und wie viel Prozent der Praxis-Prüfungen im Jahr | Bayern | 28,0 | 23,9 2009 nicht bestanden wurden. Berlin | 34,5 | 34,3 Brandenburg | 41,2…
TA 1:   [ZAHL] Gib an, wie viel Prozent der Praxis-Prüfungen im Saarland 2009 nicht bestanden wurden. %  | Loesung: 27,9 | AFB 1 | Kompetenzen: kom
TA 2:   [BEGRUENDUNG] Überprüfe folgende Aussage anhand der Tabelle: „2009 war in jedem Bundesland die Durchfallquote in der Theorie-Prüfung höher als in der praktischen Prüfung.“ Kreuze an. Die Aussage ist korrekt. | Die Aussage ist falsch.…  | Loesung: — | AFB 2 | Kompetenzen: arg, kom
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: TA 2: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 40/86 — Fußballtabelle (id 4454ccbf)
STAMM:  P | Verein | SpSUN | TD | P Bei Fußball-Meisterschaftsspielen gilt: 1Borussia MʼGladbach17123228 : 1039 2VfL Wolfsburg | 17105239 : 2135 Für einen Sieg erhält eine Mannschaft drei 3Bayern München | 17111539 : 1434 Punkte, für ein Unentschieden einen Punkt, | 4Bayer 04 Leverkusen17103434 : 1733 5Borussia Dortmund1794429 : 1631 für Niederlagen gibt es keinen Punkt. 6Werder Bremen | 1775524 : 2626 7…
TA 1:   [FREITEXT] Die Saison hat gerade begonnen. Eine Mannschaft hat bisher zweimal gespielt. Wie viele Punkte kann diese Mannschaft haben? Gib alle Möglichkeiten an.  | Loesung: Angabe aller Möglichkeiten: 0, 1, 2, 3, 4, 6 Punkte | AFB 1 | Kompetenzen: kom, mod, pro
TA 2:   [BEGRUENDUNG] Begründe, warum eine Mannschaft nach drei Spielen nicht acht Punkte haben kann.  | Loesung: Angabe aller Möglichkeiten: 6, 7, 8 Spiele | AFB 2 | Kompetenzen: arg, kom, mod, pro
TA 3:   [FREITEXT] Nach 14 Spielen hat eine Mannschaft 26 Punkte. Wie viele Spiele könnte diese Mannschaft gewonnen haben? Nenne alle Möglichkeiten.  | Loesung: Angabe aller Möglichkeiten: 6, 7, 8 Spiele | AFB 2 | Kompetenzen: kom, mod, pro
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: TA 2: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Loesung unklar: nur 2 Loesung(en) fuer 3 Teilaufgaben
        · Loesung unklar: TA 1: Intervall/Mehrfachbedingung/Prosa statt eines Werts
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 41/86 — Gleichung finden (id 0e987d7c)
STAMM:  Eine Zahl n wird mit 5 multipliziert. Von diesem Produkt wird 7 subtrahiert. Die Differenz ist 38.
TA 1:   [MC] Welche der folgenden Gleichungen entspricht dieser Rechnung? Kreuze an. 5n+7 = 38 5n–7 = 38 5n· 7 = 38 5 (n–7) = 38  | Loesung: 9 | AFB 1 | Kompetenzen: kom, ope
TA 2:   [ZAHL] Gib an, wie groß n ist. n=  | Loesung: 9 | AFB 1 | Kompetenzen: ope
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: Pipeline-Befund: ta1_antwort_ist_satz
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 42/86 — Glückssäckchen (id 206ec868)
STAMM:  A | B | C Bei einem Glücksspiel darf man sich von den drei Säckchen A, B, C eines auswählen. Unter den einzelnen Säckchen siehst du, mit welchen Kugeln sie gefüllt werden. In jedem Säckchen befinden sich dann schwarze und weiße Kugeln. Man zieht ohne hinzusehen aus seinem ausgewählten Säckchen eine Kugel; ist sie weiß, hat man gewonnen, ist sie schwarz, hat man verloren.
TA 1:   [BEGRUENDUNG] Bei welchem Säckchen ist die Wahrscheinlichkeit zu gewinnen am größten? Kreuze an. A | B | C Begründe deine Entscheidung.  | Loesung: n1+n2 | AFB 2 | Kompetenzen: mod, ope
TA 2:   [UNKLAR] Die Kugeln der drei Säckchen werden alle in einen größeren Sack zusammengeschüttet. Nun wird aus diesem größeren Sack eine Kugel gezogen. Wie groß ist jetzt die Wahrscheinlichkeit zu gewinnen?  | Loesung: — | AFB 2 | Kompetenzen: mod, ope
TA 3:   [MC] Zwei andere Säckchen sind jeweils mit mKugeln gefüllt. Im ersten Säckchen befinden sich n1weiße Kugeln, im zweiten Säckchen n2weiße Kugeln. Der Inhalt der beiden Säckchen wird wieder in einen großen Sack zusammengeschüt…  | Loesung: n1+n2 | AFB 3 | Kompetenzen: arg, kom, ope, pro
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: TA 1: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 3 Teilaufgaben
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 43/86 — Handygebühr (id a1306454)
STAMM:  Inas Handyanbieter verlangt eine Grundgebühr von 5 Euro im Monat und zusätzlich 9 Cent pro Gesprächsminute.
TA 1:   [ZAHL] Ina hatte im Januar 20 Gesprächsminuten. Gib an, wie viel sie einschließlich der Grundgebühr bezahlen muss. €  | Loesung: 6,80 | AFB 1 | Kompetenzen: mod, ope
TA 2:   [MC] Die Höhe der monatlichen Telefonrechnung lässt sich mit einer Gleichung ermitteln. Dabei wird der Preis y(in Euro) in Abhängigkeit von der Anzahl x der Gesprächsminuten berechnet. Kreuze die passende Gleichung an. x=0,0…  | Loesung: — | AFB 1 | Kompetenzen: mod, ope
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: Pipeline-Befund: ta2_antwort_ist_satz
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 44/86 — Innenwinkel 2 (id 982a1e41)
STAMM:  Zur Erinnerung: In jedem Dreieck beträgt die Summe der drei Innenwinkelgrößen 180°.
TA 1:   [FREITEXT] Bei einem rechtwinkligen Dreieck ist die Größe des Innenwinkels α gegeben. Ergänze in der Tabelle eine Möglichkeit für die Größen der beiden anderen Innenwinkel β und γ des Dreiecks. α | β | γ 20° | |  | Loesung: Zwei der folgenden Möglichkeiten: | AFB 1 | Kompetenzen: ope
TA 2:   [FREITEXT] Von einem gleichschenkligen Dreieck ist die Größe des Innenwinkels α mit 50° gegeben. Es gibt verschiedene Möglichkeiten, wie groß jeweils die beiden anderen Innenwinkel sein können. Notiere zwei verschiedene Möglichkei…  | Loesung: Zwei der folgenden Möglichkeiten: | AFB 2 | Kompetenzen: ope
TA 3:   [BEGRUENDUNG] Es gibt keine gleichseitigen Dreiecke, die rechtwinklig sind. Begründe die Aussage. __________  | Loesung: — | AFB 3 | Kompetenzen: arg, ope
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: TA 3: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Loesung unklar: keine Loesung fuer TA 3
        · Loesung unklar: nur 1 Loesung(en) fuer 3 Teilaufgaben
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 45/86 — Kauf eines DVD-Players (id 57bc3b19)
STAMM:  In einem Online-Shop im Internet ist ein Angebot für einen tragbaren DVD-Player zu finden. Der ursprüngliche Preis dieses DVD-Players von 99,99€ wird um 20% reduziert. Wenn man den Rechnungsbetrag vom Bankkonto abbuchen lässt, bekommt man auf diesen reduzierten Preis nochmal einen Rabatt von 5%.
TA 1:   [ZAHL] Gib den Preis für den DVD-Player an, wenn man ihn ohne Abbuchung vom Bankkonto bezahlt. Runde auf ganze Cent. €  | Loesung: 79,99 | AFB 1 | Kompetenzen: kom, mod, ope
TA 2:   [BEGRUENDUNG] Es wird behauptet: „Statt zunächst den Preisnachlass von 20% und anschließend den Rabatt von 5% abzuziehen, kann man auch einmalig 25% vom Preis des DVD-Players abziehen!“ Ist diese Behauptung richtig? Kreuze an. Ja | N…  | Loesung: — | AFB 2 | Kompetenzen: arg, kom, mod, ope
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: TA 2: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 46/86 — Kaum eine Chance (id ad69c9f7)
STAMM:  Enrico, Pauline und Tobias spielen ein Brettspiel, bei dem ein Spieler erst dann weitergehen darf, wenn er mit einem normalen Spielwürfel eine Sechs geworfen hat.
TA 1:   [FREITEXT] Gib die Wahrscheinlichkeit an, mit der Enrico bei seinem ersten Wurf eine Sechs wirft:  | Loesung: … die Wahrscheinlichkeit für jedes Ergebnis bei jedem Wurf gleich groß ist. | AFB 1 | Kompetenzen: mod, ope
TA 2:   [BEGRUENDUNG] Enrico prahlt, er habe ein System gefunden, mit dem beim Würfeln das Ergebnis des nächsten Wurfs vorhergesagt werden kann. Pauline widerspricht und sagt: „Das kann nicht sein. Es gibt kein System, mit dem man das Ergebn…  | Loesung: … die Wahrscheinlichkeit für jedes Ergebnis bei jedem Wurf gleich groß ist. | AFB 2 | Kompetenzen: arg, kom, mod
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: TA 2: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
        · Loesung unklar: TA 1,2: Intervall/Mehrfachbedingung/Prosa statt eines Werts
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 47/86 — Mauer aus Zahlen (id 9b15f9f4)
STAMM:  Bei allen folgenden Zahlenmauern steht in jedem Stein das Produkt der beiden darunter liegenden Steine (siehe Abbildung). 21 3 | 7 Man rechnet also 3⋅7und erhält 21.
TA 1:   [ZAHL] Ergänze die folgende Zahlenmauer vollständig. 140 2 | 5  | Loesung: 1 | AFB 1 | Kompetenzen: pro
TA 2:   [ZAHL] Gib an, welche Zahl man für xeinsetzen muss. 48 3 | -4 | x x=  | Loesung: 1 | AFB 2 | Kompetenzen: ope, pro
TA 3:   [KURZTEXT] Gib an, welche Zahl man für xeinsetzen kann. 256 x | x | x x=  | Loesung: 4 ODER -4 | AFB 2 | Kompetenzen: ope, pro
FLAGS:  Loesung unklar, Asset fehlt
        · Loesung unklar: nur 2 Loesung(en) fuer 3 Teilaufgaben
        · Loesung unklar: TA 3: zwei Werte in einer Antwort ("4 ODER -4") — als eine Eingabe nicht auswertbar
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: fixen   (Inhaltlich brauchbar, aber Loesung unklar + Asset fehlt muss vor dem Import haendisch geklaert werden.)

===== 48/86 — Nebenjob (id ded6f9d0)
STAMM:  Leon hat einen Nebenjob. Er verdient in einer Stunde 12 Euro. Leon bekommt seinen Verdienst wöchentlich ausgezahlt.
TA 1:   [ZAHL] Im Monat Juli hat Leon folgende Auszahlungen erhalten: 1. Woche: 168 Euro 2. Woche: 132 Euro 3. Woche: 180 Euro 4. Woche: 144 Euro Gib an, wie viel Euro er im Juli durchschnittlich pro Woche erhalten hat. Leon hat durch…  | Loesung: 156 | AFB 1 | Kompetenzen: mod, ope
TA 2:   [UNKLAR] In seinem letzten Nebenjob bekam Leon bei gleichem Stundenlohn 5-mal seinen Verdienst ausgezahlt. Alle Auszahlungen waren unterschiedlich. Stelle eine Liste mit möglichen Arbeitsstunden zusammen, sodass Leon in diesen 5…  | Loesung: — | AFB 2 | Kompetenzen: kom, mod, ope, pro
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: Pipeline-Befund: ta2_loesung_ist_freitext
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 49/86 — Null Komma Acht (id 27b77f61)
STAMM:  — kein gemeinsamer Stamm abtrennbar —
TA 1:   [FREITEXT] Ergänze jeweils die fehlende Zahl so, dass die Gleichung stimmt. 8: | =0,8 0,8: | =0,8  | Loesung: von oben nach unten: | AFB 1 | Kompetenzen: ope
TA 2:   [FREITEXT] Ergänze jeweils die fehlende Zahl so, dass die Gleichung stimmt. :8=0,8 :0,8=0,8  | Loesung: von oben nach unten: | AFB 1 | Kompetenzen: ope
FLAGS:  kein Stamm, nicht auto-gradebar
        · kein Stamm: 2 Textteile = 2 Teilaufgaben — kein gemeinsamer Stamm abtrennbar
        · nicht auto-gradebar: Pipeline-Befund: ta1_antwort_ist_satz, ta2_antwort_ist_satz
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 50/86 — Parlamentswahl (id 5c2eebe8)
STAMM:  Bei einer Parlamentswahl wurden in einem Wahlbezirk 12650 gültige Stimmen abgegeben. Davon fielen 42% auf den Kandidaten Herrn Aal.
TA 1:   [KURZTEXT] Gib die Anzahl der Stimmen an, die Herr Aal bei dieser Wahl bekam. Stimmen  | Loesung: 5313 Stimmen | AFB 1 | Kompetenzen: ope
TA 2:   [BEGRUENDUNG] Herr Aal kandidiert vier Jahre später auch bei der nächsten Wahl. Diesmal bekommt er allerdings weniger Stimmen als vor vier Jahren. Trotzdem hat sich sein Stimmanteil auf 44% erhöht. Nenne eine mögliche Ursache, warum …  | Loesung: — | AFB 2 | Kompetenzen: kom, pro
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: TA 2: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 51/86 — Pinsel (id fd2192ac)
STAMM:  Der Pinsel in Abbildung 1 ist im Maßstab 1 : 3 abgebildet. Abbildung 1
TA 1:   [FREITEXT] Wie lang ist er in Wirklichkeit? __________ cm  | Loesung: eine Zahl aus dem Intervall [17,4; 18,6] | AFB 2 | Kompetenzen: ope
TA 2:   [MC] Ein anderer Pinsel ist in Wirklichkeit 20 cm lang. Er soll im Maßstab 1 : 4 abgebildet werden. Welche Abbildung passt am besten? Kreuze an. ☐ ☐ ☐ ☐  | Loesung: — | AFB 2 | Kompetenzen: ope
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: Pipeline-Befund: ta1_antwort_ist_satz
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
        · Loesung unklar: TA 1: Intervall/Mehrfachbedingung/Prosa statt eines Werts
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 52/86 — Rauten (id 359d559a)
STAMM:  Die Eckpunkte Dx der Rauten AxBxCxDx wandern auf der Geraden g mit der Gleichung y=x. Dabei gilt immer: ·Die Diagonalen AxCx dieser Rauten sind 2cm lang. ·Die Punkte Bx liegen auf der x-Achse und haben jeweils die gleiche x-Koordinate wie die Punkte Dx. Im Koordinatensystem sind zwei solche Rauten dargestellt, zu x= 4 und zu x= 7. y 10 g D7 5 D4 A7 | C7 A4 | C4 1cm 1 x B4 | B7 0 | 1 | 5 | 10
TA 1:   [ZAHL] Wie groß ist der Flächeninhalt der Raute A4B4C4D4? 2 cm  | Loesung: 4 | AFB 1 | Kompetenzen: kom, pro
TA 2:   [ZAHL] 2 Die Raute AxBxCxDx hat einen Flächeninhalt von 10cm. Gib die Koordinaten des zugehörigen Punktes Dx an. Dx( | )  | Loesung: 2 | AFB 2 | Kompetenzen: kom, pro
TA 3:   [ZAHL] Für welchen Wert von x ist die Raute AxBxCxDx gleichzeitig ein Quadrat? Gib den x-Wert an. x=  | Loesung: 2 | AFB 2 | Kompetenzen: kom, pro
TA 4:   [MC] Wie groß ist allgemein der Flächeninhalt der Raute AxBxCxDx? Kreuze an. 0,25xcm2 | 0,5xcm2 | xcm2 | 2xcm2  | Loesung: xcm2 | AFB 3 | Kompetenzen: kom, ope, pro
FLAGS:  Loesung unklar, Asset fehlt
        · Loesung unklar: nur 3 Loesung(en) fuer 4 Teilaufgaben
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: fixen   (Inhaltlich brauchbar, aber Loesung unklar + Asset fehlt muss vor dem Import haendisch geklaert werden.)

===== 53/86 — Sauerkraut (id 5e248bec)
STAMM:  Sauerkraut wird aus Weißkohl hergestellt. Während der Herstellung werden Milchsäure- bakterien zugegeben, die sich täglich um 70% gegenüber der Vortagsmenge vermehren. Zu Beginn der Produktion werden dem Weißkohl 50g Bakterien zugegeben.
TA 1:   [KURZTEXT] Felix sagt: „Also kommen täglich 35g Bakterien dazu.“ Nimm Stellung zu dieser Aussage.  | Loesung: C | AFB 2 | Kompetenzen: kom, mod
TA 2:   [MC] Ulla möchte für verschiedene Tage die Bakterienmenge mit Hilfe eines Tabellenkalkulationsprogramms errechnen. Für diese Berechnungen trägt sie in einzelne Zellen der Tabelle Formeln ein. Dabei verwendet sie für jede Zel…  | Loesung: C | AFB 2 | Kompetenzen: kom, mod, ope
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: Pipeline-Befund: ta1_loesung_ist_freitext
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 54/86 — Säulenhöhe (id ac90dbea)
STAMM:  cm 10 9 8 7 6 5 4 3 2 1 Das Diagramm zeigt drei Säulen mit unterschiedlicher Höhe.
TA 1:   [ZAHL] Gib die durchschnittliche Höhe dieser drei Säulen an. Die durchschnittliche Höhe beträgt cm.  | Loesung: 6 | AFB 1 | Kompetenzen: kom, ope
TA 2:   [ZEICHNEN] Eine weitere Säule wird in das Diagramm eingezeichnet. Die durchschnittliche Höhe der vier Säulen beträgt nun 7cm. Wie hoch ist die vierte Säule? Die vierte Säule ist cm hoch.  | Loesung: 10 | AFB 2 | Kompetenzen: kom, ope, pro
FLAGS:  nicht auto-gradebar, Asset fehlt
        · nicht auto-gradebar: TA 2: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 55/86 — Schachteln packen (id 3d754790)
STAMM:  kleine Schachtel mittlere Schachtel große Schachtel (nicht maßstabsgerecht) Zu einer Verpackungsserie gehören verschieden große würfelförmige Schachteln. Die Kantenlänge der kleinen Schachtel beträgt 5cm. Die Kanten der mittleren Schachtel sind 1cm länger als die doppelte Kantenlänge der kleinen Schachtel, und die Kanten der großen Schachtel sind 1cm länger als die doppelte Kantenlänge der mittle…
TA 1:   [KURZTEXT] Gib die Kantenlängen der beiden anderen Schachteln an. Mittlere Schachtel: cm Große Schachtel: cm  | Loesung: Mittlere Schachtel: 11 | AFB 1 | Kompetenzen: kom
TA 2:   [MC] Wie viele der kleinen Schachteln passen höchstens in die große Schachtel? Kreuze an. 4 | 12 | 16 | 27 | 64  | Loesung: 64 | AFB 2 | Kompetenzen: kom, pro
TA 3:   [MC] Die Serie wird um eine vierte Schachtel, eine „Riesenschachtel“, erweitert. Ihre Kantenlänge ist 1cm länger als die doppelte Kantenlänge der großen Schachtel. Es sollen so viele kleine Schachteln wie möglich in die Ries…  | Loesung: — | AFB 2 | Kompetenzen: arg, kom, pro
FLAGS:  Loesung unklar, Asset fehlt
        · Loesung unklar: keine Loesung fuer TA 3
        · Loesung unklar: nur 2 Loesung(en) fuer 3 Teilaufgaben
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: fixen   (Inhaltlich brauchbar, aber Loesung unklar + Asset fehlt muss vor dem Import haendisch geklaert werden.)

===== 56/86 — Schulkleidung (id 48c467b7)
STAMM:  An einer Schule wird über die Einführung einheitlicher Schulkleidung diskutiert. Lisa und Paul haben im Internet eine Studie der Fachhochschule Münster zu diesem Thema gefunden. Dort wurden insgesamt 17 812 Schülerinnen und Schüler befragt. Auf die Frage „Wärst du bereit, Schulkleidung zu tragen?“ haben 9018 (50,6 %) der Befragten mit „ja“ geantwortet, 8136 (45,7 %) mit „nein“, der Rest hat keine…
TA 1:   [FREITEXT] Stelle die Ergebnisse der Befragung („ja“ / „nein“ / „keine Angaben“) in einem Säulendiagramm dar.  | Loesung: Ein Säulendiagramm ist gezeichnet, in dem: | AFB 2 | Kompetenzen: kom
TA 2:   [BEGRUENDUNG] Lisa hat die Ergebnisse der Befragung etwas auffälliger dargestellt und dabei ihre persönliche Meinung zu dem Thema einfließen lassen. Lisa ist gegen die Einführung einheitlicher Schulkleidung. Erläutere, warum Lisas Di…  | Loesung: — | AFB 3 | Kompetenzen: kom
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: TA 2: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 57/86 — Stammbrüche untersuchen (id 604064f0)
STAMM:  Ein Bruch mit einer 1 im Zähler und einer beliebigen natürlichen Zahl größer 0 im 1 Nenner heißt Stammbruch. ist ein Beispiel für einen Stammbruch. 17
TA 1:   [KURZTEXT] Stammbrüche sollen nun der Größe nach geordnet werden. Ergänze die folgende Tabelle. Ein Beispiel ist bereits eingetragen. nächstkleinerer | nächstgrößerer Stammbruch Stammbruch | Stammbruch 1 | 1 | 1 4 | 3 | 2 1 4 1 100  | Loesung: unendlich viele | AFB 1 | Kompetenzen: kom, ope
TA 2:   [MC] 1 Wie viele Stammbrüche sind kleinerals ? 10 Kreuze an. 8 | 9 | 10 | unendlich viele  | Loesung: unendlich viele | AFB 2 | Kompetenzen: ope, pro
FLAGS:  Text defekt, Loesung unklar
        · Text defekt: Bruchdarstellung zerfallen (Zaehler-/Nennerzeile getrennt): "1 | 1 | 1 / 4 | 3 | 2"
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
VORSCHLAG: raus   (Quelltext ist zerfallen — nicht rekonstruierbar ohne Rueckgriff auf das Original.)

===== 58/86 — Strecke im Koordinatenkreuz (id 8525f6de)
STAMM:  In einem Koordinatensystem ist die StreckeADgegeben. y 5 4 3 D 2 1 A x -1 | 12345 -1
TA 1:   [FREITEXT] Die StreckeADsoll eine Seite des Quadrats ABCD sein. Gib die Koordinaten der zwei Punkte B und C des Quadrats an. B ( | ) | C( | )  | Loesung: B ( 4,5 | 2,5 ) C ( 3 | 4 ) | AFB 1 | Kompetenzen: kom, pro
TA 2:   [FREITEXT] Die StreckeADsoll an der y-Achse gespiegelt werden. Gib die Koordinaten der beiden Spiegelpunkte an. A’ ( | ) | D’ ( | )  | Loesung: A' (- 3 | 1 ) D' ( - 1,5 | 2,5 ) | AFB 1 | Kompetenzen: kom, pro
FLAGS:  Loesung unklar, Asset fehlt
        · Loesung unklar: TA 1,2: Intervall/Mehrfachbedingung/Prosa statt eines Werts
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: fixen   (Inhaltlich brauchbar, aber Loesung unklar + Asset fehlt muss vor dem Import haendisch geklaert werden.)

===== 59/86 — Temperatur (id d97db3b5)
STAMM:  In Europa werden Temperaturen in Grad Celsius (°C) angegeben, in den USA in Grad Fahrenheit (°F). Es gibt eine Regel für die Umrechnung: Multipliziere die Temperatur in °C mit 1,8 und addiere zum Ergebnis 32, dann erhältst du die Temperatur in °F.
TA 1:   [ZAHL] Gib die Temperatur 5 °C in der Einheit °F an. __________ °F  | Loesung: 41 | AFB 1 | Kompetenzen: kom, ope
TA 2:   [UNKLAR] Gib eine Formel für die Umrechnung von Temperaturen in °C nach °F an. Dabei soll C für Temperaturen in °C stehen und F für Temperaturen in °F. F = __________  | Loesung: — | AFB 2 | Kompetenzen: kom, ope
FLAGS:  Loesung unklar, Rechte unklar
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
        · Rechte unklar: eingebetteter Lizenzhinweis nennt nur Text/Teilaufgaben, nicht "Grafik" — Grafik nicht gedeckt (C04)
VORSCHLAG: fixen   (Inhaltlich brauchbar, aber Loesung unklar + Rechte unklar muss vor dem Import haendisch geklaert werden.)

===== 60/86 — Tombola zum Schulfest (id 636e9c21)
STAMM:  Bei einer Tombola auf einem Schulfest befinden sich 200 Lose in einem Gefäß. Davon sind 70 kleine Gewinne, 30 mittlere Gewinne und 10 Hauptgewinne. Der Rest sind Nieten.
TA 1:   [ZAHL] Gib an, bei wie vielen Losen es sich um Nieten handelt. Es gibt | Nieten.  | Loesung: 90 | AFB 1 | Kompetenzen: kom
TA 2:   [ZEICHNEN] Zeichne die Anteile der vier Losarten in dieses Streifendiagramm ein. Beschrifte die Anteile.  | Loesung: — | AFB 1 | Kompetenzen: kom
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: TA 2: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 61/86 — Ungewöhnlicher Spielwürfel (id 001084f0)
STAMM:  Dieser „Spielwürfel“ entstand, indem aus einem würfelförmigen Körper ein Viertel herausgeschnitten wurde. Er wurde aus verschiedenen Ansichten fotografiert.
TA 1:   [ZEICHNEN] Hier ist ein Netz dieses „Spielwürfels“ skizziert. Man sieht die Außenfläche des Würfels. Wenn das Netz zusammengefaltet ist, soll es so aussehen wie der fotografierte „Spielwürfel“. Zeichne die Punkte, die sich auf den…  | Loesung: Eines der folgenden Netze liegt vor. | AFB 2 | Kompetenzen: kom, pro
TA 2:   [ZEICHNEN] Hier wurde noch ein anderes Netz dieses „Spielwürfels“ skizziert. Es fehlt noch die Seitenfläche mit den drei Punkten. Zeichne die fehlende Seitenfläche passend an das Netz.  | Loesung: — | AFB 2 | Kompetenzen: kom, pro
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: TA 1,2: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 62/86 — Von links wie von rechts (id 12aa2728)
STAMM:  252 und 4774 sind natürliche Zahlen, die von links und rechts gelesen gleich sind. Zahlen mit dieser Eigenschaft heißen Palindromzahlen. Dabei darf die erste und letzte Ziffer keine Null sein. 252 ist zum Beispiel eine 3-stellige Palindromzahl und 4774 eine 4-stellige Palindromzahl.
TA 1:   [ZAHL] Ergänze die Zahl 38 zu einer 4-stelligen Palindromzahl: und zu einer 5-stelligen Palindromzahl: | .  | Loesung: 90 | AFB 1 | Kompetenzen: pro
TA 2:   [MC] Wie viele verschiedene 4-stellige Palindromzahlen gibt es? Kreuze an. 16 | 72 | 81 | 90 | 100  | Loesung: 90 | AFB 2 | Kompetenzen: pro
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: Pipeline-Befund: ta1_antwort_erfordert_begruendung
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 63/86 — Wahl (id a0d37f31)
STAMM:  Bei einer Wahl erreichten die Parteien A, B, C und D folgende Ergebnisse: [Säulendiagramm „Wahlergebnisse“: A 33,4 %; B 36,8 %; C 19,8 %; D 6,4 %]
TA 1:   [ZAHL] Zur Wahl traten auch noch weitere Parteien an, die wegen ihrer geringen Stimmenzahl nicht im Diagramm auftauchen. Wie viel Prozent der Stimmen entfielen insgesamt auf diese weiteren Parteien? Stimmenanteil der weiteren …  | Loesung: 3,6 | AFB 1 | Kompetenzen: kom, ope
TA 2:   [FREITEXT] 24 Millionen Menschen gingen zur Wahl. Wie viele Menschen haben demnach die Partei A gewählt? Ungefähre Anzahl der Wählerinnen und Wähler der Partei A: __________  | Loesung: eine Zahl aus dem Intervall [7 920 000; 8 160 000] | AFB 1 | Kompetenzen: ope
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: Pipeline-Befund: ta2_antwort_ist_satz
        · Loesung unklar: TA 2: Intervall/Mehrfachbedingung/Prosa statt eines Werts
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 64/86 — Wo sind die Punkte (id 26c7c4af)
STAMM:  In einem Koordinatensystem ist eine Gerade geingezeichnet. y g 5 1 0 | x 01 | 5
TA 1:   [MC] Prüfe, welcher der vorgegebenen Punkte auf der Geraden gliegt. Kreuze an. A ( 4 | 0 ) | B ( 3 | 4 ) | C ( 4 | 3 ) | D ( 0 | 4 )  | Loesung: B ( 3 | AFB 1 | Kompetenzen: kom
TA 2:   [ZEICHNEN] Der Punkt Q (2 | 5 ) liegt nicht auf der Geraden g. Zeichne diesen Punkt in das Koordinatensystem ein.  | Loesung: Markierung ( 2 | 5 ) | AFB 1 | Kompetenzen: kom
FLAGS:  nicht auto-gradebar, Asset fehlt
        · nicht auto-gradebar: TA 2: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 65/86 — Würfelturm (id f3d089db)
STAMM:  Whinetnenn ,m liannk se, irneecnh tWs üurnfedl oabuef ne)i.nen Tisch legt, sind fünf Seitenflächen sichtbar (vorne, ...
TA 1:   [MC] Zwei Würfel werden übereinander gestapelt. Kreuze an, wie viele Würfelseitenflächen sichtbar sind. Die oberste Würfelseitenfläche wird dabei mitgezählt. 5 | 8 | 9 | 10 | 12  | Loesung: 9 | AFB 1 | Kompetenzen: kom, pro
TA 2:   [FREITEXT] Wie viele Würfelseitenflächen sind sichtbar, wenn man 3 bzw. 4 bzw. 10 Würfel übereinander stapelt? Die oberste Würfelseitenfläche wird dabei mitgezählt. Ergänze die folgende Tabelle. Anzahl der übereinander | Anzahl de…  | Loesung: n 4 + 1 | AFB 2 | Kompetenzen: kom, pro
TA 3:   [FREITEXT] Nun werden nWürfel übereinander gestapelt. Gib eine Vorschrift (Formel) an, mit der man die Anzahl A(n)der sichtbaren Würfelseitenflächen allgemein berechnen kann. Die oberste Würfelseitenfläche wird dabei mitgezählt. A…  | Loesung: n 4 + 1 | AFB 3 | Kompetenzen: kom, ope, pro
FLAGS:  Text defekt, Loesung unklar
        · Text defekt: zerschossene Tokens: irneecnh, üurnfedl
        · Loesung unklar: nur 2 Loesung(en) fuer 3 Teilaufgaben
VORSCHLAG: raus   (Quelltext ist zerfallen — nicht rekonstruierbar ohne Rueckgriff auf das Original.)

===== 66/86 — Zahlenwürfel (id 6d249449)
STAMM:  Der faire Würfel im Foto hat 30 gleich große Seitenflächen. Diese sind mit den Zahlen 1 bis 30 beschriftet.
TA 1:   [FREITEXT] Wie groß ist die Wahrscheinlichkeit, dass die Zahl 9 geworfen wird? Die Wahrscheinlichkeit beträgt .  | Loesung: (oder gleichwertige Angabe, wie z. B. 3, %) | AFB 1 | Kompetenzen: mod
TA 2:   [MC] Wie groß ist die Wahrscheinlichkeit, eine ungerade Zahl zu werfen? Kreuze an. 1 | 1 | 1 Das kann man nicht 30 | 15 | 2 | berechnen, ohne zu wissen, wie häufig gewürfelt wird.  | Loesung: 1 | AFB 1 | Kompetenzen: mod
TA 3:   [BEGRUENDUNG] Stefan hat diesen Würfel 29-mal geworfen. Dabei ist kein einziges Mal die Zahl 2 gefallen. Er sagt: „Beim nächsten Wurf fällt mit Sicherheit die 2, da bei 30 Würfen jede Zahl einmal fallen muss.“ Hat Stefan Recht? Kreuz…  | Loesung: — | AFB 2 | Kompetenzen: kom, mod
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: TA 1,3: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Loesung unklar: keine Loesung fuer TA 3
        · Loesung unklar: nur 2 Loesung(en) fuer 3 Teilaufgaben
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 67/86 — Zeitumrechnung (id a79e072b)
STAMM:  Meistens -z.B. auf einer Stoppuhr -gibt man eine Zeitspanne in Stunden, Minutenund Sekunden an. Zum Rechnen ist es aber oft praktischer, die Zeit als Dezimalzahl in Stunden anzugeben. Ein Beispiel: 1,5 Stunden bedeutet 1 Stunde und 30 Minuten.
TA 1:   [MC] Wie lautet das Ergebnis der Umwandlung für die Zeitspanne „1 Stunde und 45 Minuten“? Kreuze an. 1,45 Stunden | 1,65 Stunden | 1,75 Stunden | 1,85 Stunden  | Loesung: 1,75 Stunden | AFB 2 | Kompetenzen: ope
TA 2:   [FREITEXT] Hier wird eine Zeitspanne als Dezimalzahl in Stunden angegeben: t= 3,65 Stunden Rechne diese Zeitspanne in Stunden und Minuten um. Gib das Ergebnis an. t= | Stunden und | Minuten  | Loesung: t = 3 Stunden und 39 Minuten | AFB 2 | Kompetenzen: ope, pro
TA 3:   [BEGRUENDUNG] Gegeben ist allgemein eine Zeitspanne als Dezimalzahl in Stunden: t= a,b Stunden. Zum Beispiel hat dann bei t= 23,71 Stunden a den Wert 23 und b den Wert 71. Jede Angabe t= a,b Stunden kann dann in Stunden und Minuten u…  | Loesung: — | AFB 3 | Kompetenzen: kom, pro
FLAGS:  nicht auto-gradebar, Loesung unklar
        · nicht auto-gradebar: TA 3: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Loesung unklar: keine Loesung fuer TA 3
        · Loesung unklar: nur 2 Loesung(en) fuer 3 Teilaufgaben
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 68/86 — Fahrräder (id 647b89a0)
STAMM:  An einem Morgen notiert Marko in einer Strichliste, wie viele Frauen und wie viele Männer ihr Fahrrad am Bahnhof abstellen. Frauen | Männer
TA 1:   [ZAHL] Wie viele Frauen und Männer sind es insgesamt, die ihr Fahrrad abstellen? Es sind insgesamt | Frauen und Männer.  | Loesung: 69 | AFB 2 | Kompetenzen: kom
TA 2:   [UNKLAR] Formuliere selbst eine Aufgabe, die man mit den Angaben in der Tabelle lösen kann. Du musst die Aufgabe nicht lösen.  | Loesung: — | AFB 3 | Kompetenzen: kom, mod
FLAGS:  nicht auto-gradebar, Loesung unklar, Asset fehlt
        · nicht auto-gradebar: Pipeline-Befund: ta2_loesung_ist_freitext
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
        · Asset fehlt: Text nennt eine Tabelle/Liste, die keine Datenzellen enthaelt — die Werte sind bei der Extraktion verloren gegangen
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 69/86 — Hauptstädte (id 6c0764f8)
STAMM:  Die Karte zeigt die europäischen Hauptstädte. In der linken unteren Ecke ist der Maßstab dieser Karte angegeben. Reykjavik Helsinki OsloStockholm Tallinn Riga | Moskau Dublin | Kopenhagen Wilna Amsterdam London | Minsk Berlin | Warschau Brüssel Kiew Paris | Luxemburg | Prag Bratislava Wien | Chişinău Bern | Vaduz | Budapest Ljubliana Zagreb BelgradBukarest San Marino Andorra La | Monaco Lissabon …
TA 1:   [FREITEXT] Gib an, wie lang die Strecke (Luftlinie) zwischen Berlin und Athen in der Wirklichkeit ist. km  | Loesung: Maßzahl aus dem Intervall [1750;1950] | AFB 2 | Kompetenzen: kom, mod, ope
TA 2:   [MC] Welche der folgenden Hauptstädte ist etwa 1100km von Berlin entfernt? Kreuze an. Reykjavik | Luxemburg | Helsinki | Wilna  | Loesung: Helsinki | AFB 2 | Kompetenzen: kom, mod, ope, pro
FLAGS:  nicht auto-gradebar, Loesung unklar, Asset fehlt
        · nicht auto-gradebar: Pipeline-Befund: ta1_antwort_ist_satz
        · Loesung unklar: TA 1: Intervall/Mehrfachbedingung/Prosa statt eines Werts
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 70/86 — Haushaltsabfälle (id 79d5a2cc)
STAMM:  Das Diagramm informiert über die Haushaltsabfälle, die im Jahr 2009 in den einzelnen Bundesländern pro Einwohner anfielen. Dabei ist im Diagramm jedem Bundesland eine Nummer zugeordnet (vgl. Tabelle). 600 1Baden-Württemberg g | 2Bayern k 500 | 3Berlin ni r | 4Brandenburg e n h | 5Bremen o 400 | 6Hamburg w ni E | 7Hessen o | 8Mecklenburg-Vorpommern r p300 e | 9Niedersachsen ll ä | 10Nordrhein-West…
TA 1:   [KURZTEXT] In welchem Bundesland gab es die wenigsten Haushaltsabfälle pro Einwohner? Ergänze. Das Bundesland heißt | .  | Loesung: Sachsen | AFB 1 | Kompetenzen: kom
TA 2:   [UNKLAR] Gib an, wie viele Haushaltsabfälle in Rheinland-Pfalz pro Einwohner anfielen. kg  | Loesung: — | AFB 1 | Kompetenzen: kom
FLAGS:  nicht auto-gradebar, Loesung unklar, Asset fehlt
        · nicht auto-gradebar: Pipeline-Befund: ta2_loesung_ist_freitext
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 71/86 — Körper mit Seitenflächen (id ffc1a999)
STAMM:  Im Folgenden werden nur Körper betrachtet, deren Oberfläche aus ebenen Vielecken besteht. Es gibt also keine gebogenen oder gewölbten Flächen.
TA 1:   [ZAHL] Aus wie vielen Flächen besteht die Oberfläche eines Quaders? Die Oberfläche eines Quaders besteht aus Flächen.  | Loesung: 6 | AFB 1 | Kompetenzen: ope
TA 2:   [ZEICHNEN] Nenne einen Körper, dessen Oberfläche aus genau fünf Flächen besteht. Wenn du die Bezeichnung des Körpers nicht kennst, kannst du ihn auch skizzieren. oder Skizze:  | Loesung: … dreieckig. | AFB 1 | Kompetenzen: pro
TA 3:   [ZEICHNEN] Es soll ein Körper konstruiert werden, dessen Oberfläche aus genau vier Flächen besteht. Welche Form haben diese Flächen? Kreuze an. Alle vier Flächen sind... … dreieckig. | … rechteckig. | … quadratisch. | … fünfeckig.  | Loesung: … dreieckig. | AFB 1 | Kompetenzen: pro
FLAGS:  nicht auto-gradebar, Loesung unklar, Asset fehlt
        · nicht auto-gradebar: TA 2,3: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Loesung unklar: nur 2 Loesung(en) fuer 3 Teilaufgaben
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 72/86 — Nagelbrett (id 61159d5f)
STAMM:  Die Abbildung 1 zeigt ein Nagelbrett („Geobrett“). Der Abstand der benachbarten Nägel auf dem Brett beträgt 2cm. Man kann mit Hilfe eines Gummirings verschiedene Figuren spannen. Dabei sollen jetzt nur Rechtecke gespannt werden, deren Seiten parallel zu den Brettkanten sind. Die Abbildung 2 zeigt als Beispiel ein Quadrat mit einem Flächeninhalt von 16cm². Foto: © IQB | Foto: © IQB Abbildung 1 | A…
TA 1:   [KURZTEXT] Foto: © IQB Abbildung 3  | Loesung: Beispiel(e) | AFB 1 | Kompetenzen: kom, pro
TA 2:   [BEGRUENDUNG] Kann man auf diesem Nagelbrett ein Rechteck von 18cm² spannen? Kreuze an. Ja | Nein Begründe deine Antwort.  | Loesung: — | AFB 2 | Kompetenzen: arg, kom, pro
FLAGS:  nicht auto-gradebar, Loesung unklar, Asset fehlt
        · nicht auto-gradebar: TA 2: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
        · Asset fehlt: Pipeline-Befund: grafik_als_emf_nicht_renderbar
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 73/86 — Niederschlag (id e4c891be)
STAMM:  Die Abbildung zeigt ein Klimadiagramm für Halle an der Saale für das Jahr 2012. Die Säulen im Diagramm zeigen, wie viel Niederschlag in jedem Monat fiel. Die Punkte zeigen die durchschnittlichen Temperaturen für jeden Monat. Klimadiagramm Halle an der Saale 80 40 70 | 36 32 60 T m | 28e m m50 p ni | 24 e r g | a a40 l | 20t u h | r c | i s | n r30 | 16 e | ° d | C e | 12 i N20 8 10 4 0 | 0 JanFeb…
TA 1:   [KURZTEXT] Gib an, in welchem Monat die durchschnittliche Temperatur in Halle an der Saale am niedrigsten war.  | Loesung: Januar | AFB 1 | Kompetenzen: kom
TA 2:   [MC] Gib die Spannweite (das ist die Differenz des größten und kleinsten Wertes) der durchschnittlichen Temperaturen an. Welcher Wert passt am besten? Kreuze an. 10°C | 18°C | 25°C | 32°C  | Loesung: 18°C | AFB 2 | Kompetenzen: kom
TA 3:   [KURZTEXT] Gib an, in welchem Monat in Halle an der Saale am meisten Niederschlag fiel.  | Loesung: Juni | AFB 1 | Kompetenzen: kom
TA 4:   [BEGRUENDUNG] Kann man anhand dieses Diagramms sagen, dass für Halle an der Saale im Laufe des Monats Juli die höchste Tagestemperatur des Jahres 2012 gemessen wurde? Kreuze an. Ja | Nein Begründe deine Antwort.  | Loesung: — | AFB 3 | Kompetenzen: arg, kom
FLAGS:  nicht auto-gradebar, Loesung unklar, Asset fehlt
        · nicht auto-gradebar: TA 4: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Loesung unklar: keine Loesung fuer TA 4
        · Loesung unklar: nur 3 Loesung(en) fuer 4 Teilaufgaben
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 74/86 — Niederschläge (id acfe5698)
STAMM:  Diese Übersicht konnte man Anfang des Jahres 2012 der Zeitung entnehmen. Niederschlagsmenge im Jahr 2011 in Schwerin 160 | Durchschnittliche monatliche 146,5 Niederschlagsmenge: 137 140 | 58,5 Liter pro Quadratmeter nir e120 et ge | 103,2 nm et100 a mr sd ga | 76,9 alu80 hQ c so rr p60 | 52,6 e dr | 46,2 ee iti 38,2 NL4034,4 28,6 19,2 20 | 15 3,8 0 r | r | l | i | i | i | t | r | r | r | r z | i …
TA 1:   [ZAHL] Gib einen Monat an, in dem die Niederschlagsmenge unter der durchschnittlichen monatlichen Niederschlagsmenge lag.  | Loesung: 142,7 | AFB 1 | Kompetenzen: kom
TA 2:   [MC] Entscheide anhand des Diagramms, ob die folgenden Aussagen wahr oder falsch sind. Kreuze jeweils an. wahr | falsch Es gab einen Monat ohne Niederschlag. In mehr als der Hälfte der Monate regnete es weniger als im Durchs…  | Loesung: — | AFB 1 | Kompetenzen: kom, ope, pro
TA 3:   [ZAHL] Gib die Spannweite (den Unterschied zwischen größtem und kleinstem Wert) der monatlichen Niederschlagsmengen an. Die Spannweite beträgt | Liter pro Quadratmeter.  | Loesung: 142,7 | AFB 1 | Kompetenzen: kom, ope
FLAGS:  nicht auto-gradebar, Loesung unklar, Asset fehlt
        · nicht auto-gradebar: Pipeline-Befund: ta1_loesung_ist_freitext
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 3 Teilaufgaben
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 75/86 — Parfum (id 82c5c075)
STAMM:  Parfums werden meist in edlen Glasflaschen (siehe Abbildung 1) verkauft. Ein Pumpzerstäuber auf diesen Flaschen verteilt das Parfum in winzig kleine Tröpfchen (sieheAbbildung 2). Dabei werden mit jedem Pumpstoß durchschnittlich 0,2ml Parfum verteilt. Abbildung 1 | Abbildung 2
TA 1:   [ZAHL] Gib an, wie viel Milliliter Parfum bei täglicher Verwendung eines Pumpstoßes nach zehn Tagen verbraucht sind. ml  | Loesung: 2 | AFB 1 | Kompetenzen: mod
TA 2:   [UNKLAR] Sandra kauft eine Parfumflasche mit 100ml Inhalt. Gib an, wie lange diese Flasche wohl reicht, wenn Sandra täglich mehrere Pumpstöße Parfum verwendet. Tage Notiere deinen Lösungsweg.  | Loesung: — | AFB 2 | Kompetenzen: kom, mod, ope
FLAGS:  nicht auto-gradebar, Loesung unklar, Asset fehlt
        · nicht auto-gradebar: Pipeline-Befund: ta2_antwort_erfordert_begruendung
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 76/86 — Passende Schuhe (id 4665b85e)
STAMM:  Das Deutsche Schuhinstitut hat Die Schuhe sind... genauso viele Frauen wie Männer befragt, ob ihre Schuhe zu klein, passend oder zu groß sind (siehe zu klein Abbildung 1). Die Befragungs- ergebnisse beziehen sich jeweils Frauen auf 100 Frauen und 100 Männer.passend Männer zu groß 0 | 20 | 40 | 60 | 80 Abbildung 1
TA 1:   [BEGRUENDUNG] In einer Zeitung steht zu dieser Grafik: „80 Prozent aller Befragten tragen Schuhe, die ihnen nicht passen.“ Ist diese Aussage richtig? Kreuze an. Ja | Nein Begründe deine Antwort.  | Loesung: 135° | AFB 2 | Kompetenzen: arg, kom, ope
TA 2:   [MC] Die im Balkendiagramm dargestellten | zu Befragungsergebnisse der Frauen und | klein pas- Männer sollen in ein gemeinsames send Kreisdiagramm übertragen werden (siehe Abbildung 2). zu groß Wie viel Grad muss der Kreisau…  | Loesung: 135° | AFB 2 | Kompetenzen: kom, ope
FLAGS:  nicht auto-gradebar, Loesung unklar, Asset fehlt
        · nicht auto-gradebar: TA 1: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 77/86 — Punktgenau (id 80b5820c)
STAMM:  y 3 2 P 1 -3-2-1 | 1 | 2 | 3x -1 -2 -3
TA 1:   [MC] Welche Koordinaten hat der Punkt P? Kreuze an. P (1 | -2 ) | P (2 | 1 ) | P (-2 | 1 ) | P (-1 | 2 )  | Loesung: P (2 | AFB 1 | Kompetenzen: kom
TA 2:   [ZEICHNEN] Zeichne den Punkt Q (1 | 3 )in das Koordinatensystem ein.  | Loesung: — | AFB 1 | Kompetenzen: kom
FLAGS:  nicht auto-gradebar, Loesung unklar, Asset fehlt
        · nicht auto-gradebar: TA 2: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 78/86 — Steile Straße (id 5abcbc6c)
STAMM:  Das Verkehrszeichen in Abbildung1 gibt an, dass die Straße dort ein Gefälle von 12% hat. Ein Gefälle von 12% bedeutet, dass zwischen zwei Orten ein Höhenunterschied von 12m besteht, wenn die zugehörige Horizontalstrecke 100m lang ist (siehe Abbildung2). Abbildung 1 Ort A 12 % G efä 12m | lle Ort B | Abbildung 2 100m Horizontalstrecke | (nicht maßstabsgerecht)
TA 1:   [FREITEXT] Die Straße „An der Steilen Wand“ in der sächsischen Stadt Meerane hat ein Gefälle von 13%. Die Horizontalstrecke zwischen dem Beginn dieses Gefälles und dessen Ende beträgt ca. 250m. Wie groß ist der Höhenunterschied, d…  | Loesung: eine Zahl aus dem Intervall [32; 33] | AFB 2 | Kompetenzen: kom, mod
TA 2:   [FREITEXT] Die steilste Straße der Welt liegt in Neuseeland und heißt „Baldwin Street“. Ein sehr steiler Abschnitt der Straße überwindet bei einer Horizontalstrecke von 154m einen Höhenunterschied von 47m. Wie viel Prozent Gefälle…  | Loesung: eine Zahl aus dem Intervall [30; 31] | AFB 2 | Kompetenzen: kom, mod, ope
TA 3:   [UNKLAR] Steigungen oder Gefälle werden manchmal nicht in Prozent wie in Abbildung1, sondern durch die Größe des Winkels (siehe Abbildung3) beschrieben. Ort A a | Ort B | Abbildung 3 (nicht maßstabsgerecht) Gib die Größe des Win…  | Loesung: — | AFB 2 | Kompetenzen: kom, pro
FLAGS:  nicht auto-gradebar, Loesung unklar, Asset fehlt
        · nicht auto-gradebar: Pipeline-Befund: ta1_antwort_ist_satz, ta2_antwort_ist_satz, ta3_antwort_erfordert_begruendung
        · Loesung unklar: keine Loesung fuer TA 3
        · Loesung unklar: nur 2 Loesung(en) fuer 3 Teilaufgaben
        · Loesung unklar: TA 1,2: Intervall/Mehrfachbedingung/Prosa statt eines Werts
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 79/86 — Treppenmaße (id 72f309fe)
STAMM:  Man muss jeden Tag viele verschiedenartige Treppen überwinden. Damit man das Treppensteigen als angenehm empfindet, orientieren sich Treppenbauer an der folgenden Schrittmaßregel (siehe Abbildung): Schrittmaßregel:2⋅h+b=63cm Tritthöhe h Auftrittb (nicht maßstabsgerecht)
TA 1:   [BEGRUENDUNG] In der folgenden Tabelle sind die Maße von zwei Treppen angegeben. Treppe 1 | Treppe 2 Tritthöhe h | 19cm | 12cm Auftritt b | 44cm | 39cm Kreuze jeweils an, ob die Schrittmaßregel erfüllt ist. Begründe deine Antwort dur…  | Loesung: 18 | AFB 2 | Kompetenzen: kom, mod, ope
TA 2:   [ZAHL] Eine Wohnhaustreppe hat einen Auftritt von b= 27cm. Gib die Tritthöhe gemäß der Schrittmaßregel an. h= cm  | Loesung: 18 | AFB 2 | Kompetenzen: mod, ope
TA 3:   [BEGRUENDUNG] Beim Bau einer Treppe soll die Schrittmaßregel 2⋅h+b=63cmbeachtet werden. Peter behauptet: „Es gilt dann: Je kleiner die Tritthöhe h, desto größer der Auftritt b.“ Hat Peter Recht? Kreuze an. Ja | Nein Begründe deine An…  | Loesung: — | AFB 2 | Kompetenzen: arg, kom, mod, ope
TA 4:   [FREITEXT] Eine Treppe hat eine Steigung von 45°. Die Schrittmaßregel 2⋅h+b=63cmist erfüllt. Gib an, welche Maße die Tritthöhe h und der Auftritt b dann haben müssen. Tritthöhe h: | cm Auftritt b: | cm  | Loesung: Tritthöhe h: 21 cm | AFB 2 | Kompetenzen: kom, mod, ope, pro
FLAGS:  nicht auto-gradebar, Loesung unklar, Asset fehlt
        · nicht auto-gradebar: TA 1,3: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Loesung unklar: keine Loesung fuer TA 3
        · Loesung unklar: nur 2 Loesung(en) fuer 4 Teilaufgaben
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 80/86 — Tropfender Wasserhahn (id 91167d8d)
STAMM:  Bei Familie Rector tropft seit einigen Tagen ein undichter Wasserhahn. Ben, der Sohn der Familie, will untersuchen, wie viel Wasser dabei verloren geht. Er fängt das gleichmäßig tropfende Wasser in einem Messbecher auf.
TA 1:   [ZAHL] Ben sieht ab und zu nach, wie viel Wasser inzwischen im Messbecher ist. Die Tabelle zeigt Bens Messergebnisse. Zeit in Stunden | 0,5 | 4 Wassermenge in cm³ | 150 | 1200 Gib an, wie viel Wasser nach zwei Stunden im Messb…  | Loesung: 600 | AFB 1 | Kompetenzen: kom, mod
TA 2:   [MC] Welches Diagramm stellt die verlorene Wassermenge in Abhängigkeit von der Zeit am besten dar? Kreuze an. Wasserme₃nge | Wasserme₃nge in cm | in cm Zeit in h | Zeit in h Wasserme₃nge | Wasserme₃nge in cm | in cm Zeit in …  | Loesung: — | AFB 2 | Kompetenzen: kom, mod
FLAGS:  nicht auto-gradebar, Loesung unklar, Asset fehlt
        · nicht auto-gradebar: Pipeline-Befund: ta2_antwort_ist_satz
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 81/86 — Zahlen addieren (id bfa55025)
STAMM:  — kein gemeinsamer Stamm abtrennbar —
TA 1:   [ZAHL] Die Summe von zwei ganzen Zahlen, die beide größer als 0 sind, soll 8 ergeben. Schreibe alle Möglichkeiten auf, wie diese Summe gebildet werden kann.  | Loesung: 1 + 7; 2 + 6; 3 + 5; 4 + 4 | AFB 1 | Kompetenzen: pro
TA 2:   [FREITEXT] Nun geht es um Bruchzahlen, die größer als 0 sind. 1 Die Summe von zwei solchen Bruchzahlen soll ergeben. 8 Schreibe ein Beispiel auf, wie die Summe gebildet werden kann. Die Brüche müssen dabei vollständig gekürzt sein.  | Loesung: Bruchzahlen, deren Summe ergibt. | AFB 1 | Kompetenzen: ope, pro
FLAGS:  kein Stamm, nicht auto-gradebar, Loesung unklar
        · kein Stamm: 2 Textteile = 2 Teilaufgaben — kein gemeinsamer Stamm abtrennbar
        · nicht auto-gradebar: Pipeline-Befund: ta2_antwort_ist_satz
        · Loesung unklar: TA 1: Intervall/Mehrfachbedingung/Prosa statt eines Werts
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 82/86 — Zuschauerzahlen (id 912a1f31)
STAMM:  — kein gemeinsamer Stamm abtrennbar —
TA 1:   [ZAHL] Zu einem Fußballspiel kamen 48548 Zuschauer. Runde diese Zahl auf Tausender.  | Loesung: 49 000 | AFB 1 | Kompetenzen: ope
TA 2:   [UNKLAR] An einem bestimmten Bundesliga-Spieltag wurden für die 9 Spiele die folgenden Zuschauerzahlen gemeldet: 24000, 61673, 39000, 24487, 51500, 29313, 54057, 31000 und 48548. Günther sagt: „An diesem Spieltag waren insgesamt…  | Loesung: — | AFB 3 | Kompetenzen: arg, kom
FLAGS:  kein Stamm, nicht auto-gradebar, Loesung unklar
        · kein Stamm: 2 Textteile = 2 Teilaufgaben — kein gemeinsamer Stamm abtrennbar
        · nicht auto-gradebar: Pipeline-Befund: ta2_antwort_erfordert_begruendung
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 83/86 — Damenuhr (id 255a7d35)
STAMM:  Ein Versandhaus bietet eine Damenuhr Ein goldfarbenes Uhrengehäuse Ein goldfarbenes Uhrengehäuse an, deren Uhrengehäuse mit vier mmiitt wweeißißeemm Z Ziiffffeerrnnbblalattt tu unndd verschiedenen Wechselringen und vier ggaannggggeennaauueemm QQuuaarrttzzwweerrkk.. verschiedenen Wechselarmbändern kombiniert werden kann (siehe Abbildung). 44 sscchhmmuucckkvvoolllele WWeecchhsseellrriinnggee zzuumm…
TA 1:   [MC] Auf wie viele verschiedene Arten kann das Uhrengehäuse mit den vier verschiedenen Wechselringen und den vier verschiedenen Wechselarmbändern kombiniert werden? Kreuze an. 4 | 8 | 9 | 16 | unendlich viele  | Loesung: 16 | AFB 2 | Kompetenzen: kom, mod, ope, pro
TA 2:   [UNKLAR] Bei einer anderen Damenuhr soll das Uhrengehäuse ebenfalls mit verschiedenen Wechselringen und verschiedenen Wechselarmbändern kombiniert werden. Dabei sollen genau 12 Kombinationen möglich sein. Wie viele Wechselringe …  | Loesung: — | AFB 2 | Kompetenzen: mod, ope, pro
FLAGS:  Text defekt, nicht auto-gradebar, Loesung unklar, Asset fehlt
        · Text defekt: zerschossene Tokens: mmiitt, wweeißißeemm, ziiffffeerrnnbblalattt, ggaannggggeennaauueemm, qquuaarrttzzwweerrkk …
        · nicht auto-gradebar: Pipeline-Befund: ta2_loesung_ist_freitext
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: raus   (Quelltext ist zerfallen — nicht rekonstruierbar ohne Rueckgriff auf das Original.)

===== 84/86 — Flächengleich oder nicht (id 8f1fb6b7)
STAMM:  — kein gemeinsamer Stamm abtrennbar —
TA 1:   [ZAHL] 4cm | 4,5cm 5cm | (nicht maßstabsgerecht) Gib an, wie groß der Flächeninhalt dieses Parallelogramms ist. Der Flächeninhalt des Parallelogramms beträgt | cm².  | Loesung: 20 | AFB 1 | Kompetenzen: kom, ope
TA 2:   [BEGRUENDUNG] In der Abbildung sind zwei Parallelogramme dargestellt. a a || b b Ist der Flächeninhalt der beiden Parallelogramme gleich groß? Kreuze an. Ja | Nein Begründe deine Antwort.  | Loesung: — | AFB 3 | Kompetenzen: arg, kom
FLAGS:  kein Stamm, nicht auto-gradebar, Loesung unklar, Asset fehlt
        · kein Stamm: 2 Textteile = 2 Teilaufgaben — kein gemeinsamer Stamm abtrennbar
        · nicht auto-gradebar: TA 2: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Loesung unklar: keine Loesung fuer TA 2
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 85/86 — Quadrat und Raute (id 5495e54b)
STAMM:  — kein gemeinsamer Stamm abtrennbar —
TA 1:   [ZEICHNEN] Gegeben ist eine Gerade, die durch den Ursprung eines Koordinatensystems verläuft. Ein Stück dieser Geraden soll eine Diagonale in einem Quadrat ABCD sein. A und C sollen auf der Geraden liegen. Zeichne ein solches Quad…  | Loesung: Eine eingezeichnete Raute (Rhombus) | AFB 2 | Kompetenzen: kom
TA 2:   [ZEICHNEN] Gegeben ist eine Gerade, die durch den Ursprung eines Koordinatensystems verläuft. Es soll eine Raute (Rhombus) APCQ gezeichnet werden, die kein Quadrat ist. A und C sollen wieder auf der Geraden liegen. Zeichne eine so…  | Loesung: Eine eingezeichnete Raute (Rhombus) | AFB 2 | Kompetenzen: kom
FLAGS:  kein Stamm, nicht auto-gradebar, Loesung unklar, Asset fehlt
        · kein Stamm: 2 Textteile = 2 Teilaufgaben — kein gemeinsamer Stamm abtrennbar
        · nicht auto-gradebar: TA 1,2: verlangt Zeichnen/Konstruieren/Begruendung oder die Auswertung beschreibt die Loesung nur ("Richtiger Term"), statt sie anzugeben
        · Loesung unklar: nur 1 Loesung(en) fuer 2 Teilaufgaben
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: raus   (Teilaufgaben verlangen Zeichnen/Begruendung — im Selbstlernpfad nicht automatisch bewertbar.)

===== 86/86 — Rundfunkgebühren (id 66a3406c)
STAMM:  InderfolgendenAbbildungistdieEntwicklungdermonatlichenRundfunkgebühren, dieeinHaushaltbezahlenmuss,seitdemJahr1953dargestellt.DieAbbildung 1 zeigt,wannesGebührenerhöhungengabundwiehochdanachdieGebührenwaren. Rundfunkgebühren in Deutschland 20 € 18 € 16 € 14 € 12 € 10 € 8 € 6 € 4 € 2 € 0 € 195319701974197919831988199019921997200120052009 Abbildung 1 Grafik: © IQB HerrKunzehatsichgenauermitdenDaten…
TA 1:   [FREITEXT] Gib die Daten an, die in den Spalten 1, 2 und 3 fehlen. In der Spalte 1 fehlt | . In der Spalte 2 fehlt | . In der Spalte 3 fehlt | .  | Loesung: In Spalte 1 fehlt 1992. | AFB 2 | Kompetenzen: kom, mod, pro
TA 2:   [FREITEXT] Die Daten in den Spalten 4 und 5 lassen sich nicht direkt aus der Abbildung ablesen. Sie müssen erst errechnet werden. Gib die Daten an, die in diesen beiden Spalten fehlen. In der Spalte 4 fehlt | . In der Spalte 5 feh…  | Loesung: In Spalte 4 fehlt 1,70 Euro. | AFB 2 | Kompetenzen: kom, mod, pro
TA 3:   [UNKLAR] Herr Kunze hat die Daten aus Abbildung 1 in einer zweiten Abbildung dargestellt. 20€ 18€ 16€ 14€ 12€ 10€ 8€ 6€ 4€ 2€ 0€ Abbildung 2 1950 | 1960 | 1970 | 1980 | 1990 | 2000 | 2010 | 2020 Grafik: © IQB Nenne zwei Untersch…  | Loesung: — | AFB 3 | Kompetenzen: kom, mod
FLAGS:  Text defekt, nicht auto-gradebar, Loesung unklar, Asset fehlt
        · Text defekt: zerschossene Tokens: inderfolgendenabbildungistdieentwicklungdermonatlichenrundfunkgebühren, dieeinhaushaltbezahlenmuss, wannesgebührenerhöhungengabundwiehochdanachdiegebührenwaren, herrkunzehatsichgenauermitdendatenbefasstundvielgerechnet, haterineinertabelleaufgeschrieben …
        · nicht auto-gradebar: Pipeline-Befund: ta1_antwort_ist_satz, ta2_antwort_ist_satz, ta3_loesung_ist_freitext
        · Loesung unklar: keine Loesung fuer TA 3
        · Loesung unklar: nur 2 Loesung(en) fuer 3 Teilaufgaben
        · Asset fehlt: Text verweist auf eine Abbildung, es gibt aber kein verwendbares Asset (nur EMF-Textrecords, kein Bild)
VORSCHLAG: raus   (Quelltext ist zerfallen — nicht rekonstruierbar ohne Rueckgriff auf das Original.)

