# Sachkontext-Aufgaben — zum Durchsehen

48 neue Aufgaben zu 16 Fundament-Skills, je drei. Sie messen etwas anderes als
die nackten Rechnungen im Bestand: ob ein Kind eine Situation in eine Rechnung
übersetzen kann. Sie ersetzen nichts, sie kommen dazu.

| | |
|---|---|
| `source` | `edvance_fundament_kontext` |
| `status` | `draft` — nichts ist freigegeben, die LSA zieht nichts davon |
| `sondierrang` | überall `null` |
| Bestand `edvance_fundament` | unangetastet: 245 auf `ready`, 76 mit Rang |
| Erzeugt von | `scripts/sql/sachkontext_aufgaben.sql` |
| Geprüft von | `scripts/sql/sachkontext_pruefung.sql` (S1–S6 grün) |

## Offener Punkt vor der Freigabe

Der unabhängige Prüfer (`tools/verify-tasks.mjs`) konnte nur seine Struktur-Stufe
laufen lassen — 48 von 48 ohne Beanstandung: Lösung vorhanden, `skill_key`
gesetzt, Antwortformat gültig, keine Dubletten.

Die beiden LLM-Stufen (Aufgabe blind lösen, Kontext auf Realitätsnähe prüfen)
sind **nicht** gelaufen: der `ANTHROPIC_API_KEY` in `.env` wird von der API mit
`401 authentication_error — API key is invalid` abgewiesen, in jedem einzelnen
Batch. Das ist kein Befund über die Aufgaben, sondern ein fehlender Zugang.

Mit gültigem Schlüssel nachholen:

```bash
node tools/verify-tasks.mjs --source edvance_fundament_kontext --min-pass 1.0
```

Bis dahin ruht die Rechnung jeder Aufgabe auf einer einzigen Quelle statt auf
zweien. Für eine Freigabe sollte der Lauf vorher grün sein.

---

## Größen · Längen — `groessen_laengen`

| # | Aufgabe | Lösung |
|---|---|---|
| `sk-groessen-laengen-01` | Auf dem Schulhof wird eine Laufstrecke von 3,5 km markiert. Für die Urkunde soll die Länge in Metern stehen. — Wie viele Meter sind das? | **3500** m |
| `sk-groessen-laengen-02` | Jonas misst die Breite eines Fensters und liest 145 cm ab. Im Bauplan wird die Breite in Metern eingetragen. — Wie viele Meter sind das? | **1,45** m |
| `sk-groessen-laengen-04` | Ein Wanderweg ist 1250 m lang. Auf dem Wegweiser steht die Länge in Kilometern. — Wie viele Kilometer sind das? | **1,25** km |

AFB I · `NUMERIC`

## Größen · Massen — `groessen_massen`

| # | Aufgabe | Lösung |
|---|---|---|
| `sk-groessen-massen-01` | Für ein Rezept werden 1,5 kg Mehl abgewogen. Die Küchenwaage zeigt Gramm an. — Wie viele Gramm sind das? | **1500** g |
| `sk-groessen-massen-02` | Ein Paket wiegt 3200 g. Auf dem Versandschein wird die Masse in Kilogramm eingetragen. — Wie viele Kilogramm sind das? | **3,2** kg |
| `sk-groessen-massen-03` | Ein kleiner Transporter darf 2,5 t laden. Die Ladeliste ist in Kilogramm geführt. — Wie viele Kilogramm sind das? | **2500** kg |

AFB I · `NUMERIC`

## Größen · Zeit — `groessen_zeit`

| # | Aufgabe | Lösung |
|---|---|---|
| `sk-groessen-zeit-01` | Ein Fußballturnier dauert 210 min. Im Ablaufplan steht die Dauer in Stunden. — Wie viele Stunden sind das? | **3,5** h |
| `sk-groessen-zeit-02` | Eine Zugfahrt dauert 135 min. Auf dem Ticket ist die Fahrzeit in Stunden angegeben. — Wie viele Stunden sind das? | **2,25** h |
| `sk-groessen-zeit-04` | Ein Film läuft 144 min. Im Programmheft steht die Länge in Stunden. — Wie viele Stunden sind das? | **2,4** h |

AFB I · `NUMERIC` · Der typische Fehler ist hier `3,3` statt `3,5` — 210 min als
"3 Stunden 30" gelesen und das Komma dezimal gesetzt.

## Größen · Flächen — `groessen_flaechen`

| # | Aufgabe | Lösung |
|---|---|---|
| `sk-groessen-flaechen-01` | Ein Beet im Schulgarten ist 5 m² groß. Im Pflanzplan wird die Fläche in Quadratdezimetern angegeben. — Wie viele Quadratdezimeter sind das? | **500** dm² |
| `sk-groessen-flaechen-02` | Ein Fliesenrest bedeckt 350 cm². Auf dem Lieferschein steht die Fläche in Quadratdezimetern. — Wie viele Quadratdezimeter sind das? | **3,5** dm² |
| `sk-groessen-flaechen-03` | Ein Sportgelände ist 20000 m² groß. In der Stadtkarte steht die Fläche in Hektar. — Wie viele Hektar sind das? | **2** ha |

AFB II · `NUMERIC`

## Größen · Volumen — `groessen_volumen`

| # | Aufgabe | Lösung |
|---|---|---|
| `sk-groessen-volumen-02` | Ein Aquarium fasst 45 dm³. Im Datenblatt steht das Volumen in Litern. — Wie viele Liter sind das? | **45** l |
| `sk-groessen-volumen-03` | In eine Gießkanne passen 2,5 l. Für eine Berechnung wird das Volumen in Kubikzentimetern gebraucht. — Wie viele Kubikzentimeter sind das? | **2500** cm³ |
| `sk-groessen-volumen-04` | Ein Messbecher fasst 750 ml. Im Rezept steht die Menge in Litern. — Wie viele Liter sind das? | **0,75** l |

AFB II · `NUMERIC` · Die erste Aufgabe sieht trivial aus und ist es nicht:
`1 dm³ = 1 l` ist genau die Stelle, an der viele Kinder aussteigen.

## Größen · gemischt — `groessen_gemischt`

| # | Aufgabe | Lösung |
|---|---|---|
| `sk-groessen-gemischt-01` | Ein Regal ist 2,06 m hoch. In der Bauanleitung steht die Höhe in Zentimetern. — Wie viele Zentimeter sind das? | **206** cm |
| `sk-groessen-gemischt-02` | Eine Wanderung dauert 3,25 h. Im Tagesplan steht die Dauer in Minuten. — Wie viele Minuten sind das? | **195** min |
| `sk-groessen-gemischt-03` | Ein Beutel Vogelfutter wiegt 1,04 kg. Auf dem Etikett steht die Masse in Gramm. — Wie viele Gramm sind das? | **1040** g |

AFB II · `NUMERIC` · Die führende Null hinter dem Komma ist Absicht: `2,06 m`
wird oft zu `260 cm`.

## Proportionalität — `proportionalitaet`

| # | Aufgabe | Lösung |
|---|---|---|
| `sk-proportionalitaet-02` | Für 4 Portionen Suppe braucht Elif 600 g Kartoffeln. — Wie viele Gramm braucht sie für 10 Portionen? | **1500** g |
| `sk-proportionalitaet-03` | Ein Drucker druckt 5 Seiten in 20 Sekunden. — Wie viele Sekunden braucht er für 12 Seiten? | **48** Sekunden |
| `sk-proportionalitaet-04` | Sechs gleich schnelle Helferinnen und Helfer bauen eine Bühne in 4 Stunden auf. — Wie lange brauchen 8 von ihnen? | **3** Stunden |

AFB I / II · `NUMERIC` · Die dritte Aufgabe ist antiproportional — sie trennt
"Dreisatz verstanden" von "Dreisatz auswendig".

## Prozent · Prozentwert — `prozent_prozentwert`

| # | Aufgabe | Lösung |
|---|---|---|
| `sk-prozent-wert-01` | An einer Schule lernen 250 Kinder. 12 % von ihnen fahren mit dem Rad zur Schule. — Wie viele Kinder sind das? | **30** Kinder |
| `sk-prozent-wert-02` | Ein Chor hat 80 Mitglieder. 35 % von ihnen singen im Bass. — Wie viele Mitglieder sind das? | **28** Mitglieder |
| `sk-prozent-wert-03` | Eine Karte für das Schulkonzert kostet 24 €. Der Preis wird um 25 % gesenkt. — Um wie viel Euro wird der Preis gesenkt? | **6** € |

AFB I · `NUMERIC`

## Prozent · Grundwert — `prozent_grundwert`

| # | Aufgabe | Lösung |
|---|---|---|
| `sk-prozent-grundwert-01` | In einer Bücherei sind 36 Bücher ausgeliehen. Das sind 15 % des Bestands. — Wie viele Bücher hat die Bücherei insgesamt? | **240** |
| `sk-prozent-grundwert-03` | In einem Chor singen 21 Personen im Sopran. Das sind 35 % des Chores. — Wie viele Personen singen im Chor? | **60** |
| `sk-prozent-grundwert-04` | Von einer Bestellung sind bisher 45 Stühle geliefert. Das sind 25 % der Bestellung. — Wie viele Stühle wurden bestellt? | **180** |

AFB II · `NUMERIC` · ohne Einheit, wie im Bestand

## Prozent · Prozentsatz — `prozent_prozentsatz`

| # | Aufgabe | Lösung |
|---|---|---|
| `sk-prozent-satz-01` | In einer Klasse mit 25 Kindern spielen 15 ein Instrument. — Wie viel Prozent sind das? | **60** % |
| `sk-prozent-satz-02` | Von 200 abgegebenen Fragebögen sind 24 unvollständig. — Wie viel Prozent sind das? | **12** % |
| `sk-prozent-satz-03` | Ein Regenmesser fasst 50 ml. Nach einem Schauer stehen 8 ml darin. — Wie viel Prozent des Fassungsvermögens sind das? | **16** % |

AFB I · `NUMERIC`

## Prozent · Veränderung — `prozent_veraenderung`

| # | Aufgabe | Lösung |
|---|---|---|
| `sk-prozent-veraenderung-01` | Ein Verein hatte im vergangenen Jahr 240 Mitglieder. In diesem Jahr sind es 15 % mehr. — Wie viele Mitglieder sind es jetzt? | **276** Mitglieder |
| `sk-prozent-veraenderung-03` | Ein Fahrrad kostet 320 €. Der Preis sinkt um 25 %. — Wie viel Euro kostet es danach? | **240** € |
| `sk-prozent-veraenderung-04` | In einem Teich lebten 80 Fische. Ihre Zahl nimmt um 10 % ab. — Wie viele Fische sind es dann? | **72** Fische |

AFB II · `NUMERIC` · Der häufigste Fehler ist, den Prozentwert statt des neuen
Werts hinzuschreiben.

## Dezimal · addieren und subtrahieren — `dezimal_add_sub`

| # | Aufgabe | Lösung |
|---|---|---|
| `sk-dezimal-add-sub-01` | Nele läuft am Montag 2,4 km und am Dienstag 1,85 km. — Wie viele Kilometer läuft sie an beiden Tagen zusammen? | **4,25** km |
| `sk-dezimal-add-sub-02` | Ein Rucksack wiegt leer 0,85 kg. Vollgepackt wiegt er 3,2 kg. — Wie viele Kilogramm wiegt der Inhalt? | **2,35** kg |
| `sk-dezimal-add-sub-04` | In einer Kanne sind 1,25 l Wasser und 0,4 l Saft. — Wie viele Liter Flüssigkeit sind in der Kanne? | **1,65** l |

AFB I · `NUMERIC` · Ungleiche Stellenzahl ist Absicht: `2,4 + 1,85` deckt den
Stellenwertfehler auf, `2,40 + 1,85` nicht.

## Dezimal · multiplizieren — `dezimal_mult`

| # | Aufgabe | Lösung |
|---|---|---|
| `sk-dezimal-mult-01` | Ein Kilogramm Äpfel kostet 2,40 €. Yusuf kauft 1,5 kg. — Wie viel Euro zahlt er? | **3,6** € |
| `sk-dezimal-mult-02` | Eine rechteckige Fliese ist 0,3 m breit und 0,4 m hoch. — Wie viele Quadratmeter beträgt ihre Fläche? | **0,12** m² |
| `sk-dezimal-mult-03` | Aus einem Hahn fließen 0,25 l Wasser pro Sekunde. Er läuft 12 Sekunden lang. — Wie viele Liter fließen in dieser Zeit? | **3** l |

AFB I · `NUMERIC`

## Dezimal · dividieren — `dezimal_div`

| # | Aufgabe | Lösung |
|---|---|---|
| `sk-dezimal-div-01` | Eine Schnur ist 4,8 m lang. Sie wird in Stücke von je 0,6 m geschnitten. — Wie viele Stücke sind das? | **8** Stücke |
| `sk-dezimal-div-02` | In einer Flasche sind 1,5 l Saft. Er wird gleichmäßig in Gläser zu je 0,25 l gefüllt. — Wie viele Gläser sind das? | **6** Gläser |
| `sk-dezimal-div-04` | Für ein Hochbeet stehen 7,5 kg Blumenerde bereit. Sie wird in Eimer zu je 2,5 kg gefüllt. — Wie viele Eimer sind das? | **3** Eimer |

AFB I · `NUMERIC` · Alle drei sind Aufteilaufgaben — das ist die Lesart der
Division, die im Sachkontext trägt.

## Runden und Überschlag — `runden_ueberschlag`

| # | Aufgabe | Lösung |
|---|---|---|
| `sk-runden-01` | Auf einem Kassenbon steht ein Betrag von 47,38 €. Im Haushaltsbuch wird auf ganze Euro gerundet. — Welche Zahl wird eingetragen? | **47** |
| `sk-runden-02` | Ein Sprint wird mit 12,47 s gestoppt. Für die Urkunde wird auf eine Nachkommastelle gerundet. — Welche Zahl steht auf der Urkunde? | **12,5** |
| `sk-runden-03` | Eine Waage zeigt 3,456 kg an. Im Protokoll wird auf zwei Nachkommastellen gerundet. — Welche Zahl wird notiert? | **3,46** |

AFB I · `NUMERIC`

## Geometrie · Maßstab — `geo_massstab`

| # | Aufgabe | Lösung |
|---|---|---|
| `sk-geo-massstab-01` | Lea plant eine Radtour mit einer Karte im Maßstab 1:50000. Die Strecke ist auf der Karte 9 cm lang. — Wie viele Kilometer ist die Strecke in Wirklichkeit? | **4,5** km |
| `sk-geo-massstab-02` | In einem Grundriss im Maßstab 1:100 ist eine Wand 4 cm lang gezeichnet. — Wie viele Meter ist die Wand in Wirklichkeit lang? | **4** m |
| `sk-geo-massstab-03` | Auf einem Lageplan im Maßstab 1:200 ist ein Weg 18 cm lang. — Wie viele Meter ist der Weg in Wirklichkeit lang? | **36** m |

AFB II · `NUMERIC` · Zwei Schritte in einem: mit dem Maßstab multiplizieren und
danach die Einheit wechseln.

---

## Freigabe

Einzeln oder in Gruppen, nach dem Durchsehen:

```sql
update tasks set status = 'ready'
 where source = 'edvance_fundament_kontext' and skill_key = '…';
```

Rückweg, solange nichts freigegeben ist:

```sql
delete from tasks where source = 'edvance_fundament_kontext';
```

## Anmerkungen zum Zuschnitt

- **Die Nummern haben Lücken.** Erzeugt wurden vier Kandidaten je Skill, stehen
  geblieben sind drei. Die `source_ref` der gelöschten wurde nicht nachvergeben,
  damit eine Nummer immer dieselbe Aufgabe meint.
- **`class_level` bleibt `null`**, wie im gesamten Bestand `edvance_fundament`.
- **`unit` ist gesetzt, wo die Antwort eine Einheit trägt.** Bei `dezimal_*` und
  `runden_ueberschlag` ist die Spalte im Bestand leer, weil dort nackte Zahlen
  stehen; im Sachkontext hat die Antwort eine Einheit, und die Spalte wird
  entsprechend gefüllt. Das ist dieselbe Regel, nicht eine andere.
- **Kein Mangel als Thema.** Keine Aufgabe handelt davon, dass jemand zu wenig
  hat oder sich etwas nicht leisten kann. Preise kommen vor, Knappheit nicht.
