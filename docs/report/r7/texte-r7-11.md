# R7-11 · Texte alt → neu (Entwürfe für Lena)

Stand 22.10.2026, Branch `feat/rasit-report-r7-ansatz`. Alle Texte im Namespace `elternbericht`;
die Präsentation nimmt dieselben Schlüssel über `tb`. Neue oder geänderte Schlüssel in
`praesentation.json` gibt es nicht.

## Neue Schlüssel

| Schlüssel | Text |
|---|---|
| `s1.blick.ansatzThema.sicher_one` | Sicher ist schon {{liste}}. |
| `s1.blick.ansatzThema.sicher_other` | Sicher sind schon {{liste}}. |
| `s1.blick.ansatzThema.uebung` | Noch Übung braucht {{name}} bei {{liste}}. |
| `s1.blick.ansatzThema.uebungOhneName` | Noch Übung braucht es bei {{liste}}. |
| `s1.blick.ansatzThema.start_one` | Dort setzen wir an. |
| `s1.blick.ansatzThema.start_other` | Wir beginnen bei {{start}}. |
| `s1.blick.ansatzThemaSicher` | Was wir im Thema {{thema}} geprüft haben, sitzt. Wir arbeiten am aktuellen Stoff weiter. |
| `s1.anliegen.antwort` | Dort hakt es bei {{liste}}. |
| `s1.anliegen.antwortSicher` | Was wir dazu geprüft haben, sitzt. |
| `s1.anliegen.antwortSchwerpunkt` | Dort setzen wir zuerst an: {{schwerpunkt}}. |
| `s1.anliegen.naechstesThema` | Als nächstes Thema steht {{thema}} an. (bisher `s1.anliegen.thema`, Wortlaut unverändert, nur noch ohne Thema der LSA) |
| `s4.chip.thema` | Aktuelles Thema |

`start` richtet sich nach der Zahl der Bereiche mit Übungsbedarf im Thema: einer → „Dort setzen wir an.“

## Geänderte Anhang-A-Schlüssel (einzeln in INV-4.9, `R7_11_GEAENDERT`)

| Schlüssel | alt | neu |
|---|---|---|
| `s1.anliegen.thema` | Als nächstes Thema steht {{thema}} an. | Sie sind wegen {{thema}} zu uns gekommen. |
| `s2.fussnote` | … Ein Bereich gilt als sicher, wenn die geprüften Aufgaben dazu gelangen; die Bewertungsregel ist noch nicht abschließend festgelegt. … | … Ein Bereich gilt als sicher, wenn die geprüften Aufgaben dazu gelangen. … |

## Nicht mehr gezeigt (Daten bleiben)

- Überfachliche Anliegen (Konzentration, Prüfungsangst, Zeiteinteilung, Unbekanntes) in „Sie machen sich
  Sorgen um …“.
- Rückbezüge (`report_bausteine`, Slot `rueckbezug`) der Richtungen `nicht_messbar` und `offen` und der
  schmalen Fassungen (`*_schmal`): Sie sagen, was die Analyse nicht sagen kann oder erst später klärt
  (Entscheidung 14). Bestätigende und entlastende Rückbezüge zu fachlichen Anliegen bleiben.

## Zusammengesetzte Sätze aller Testfälle (Seite 1 „Unser erster Ansatz“ und „Ihr Anliegen“, Seite 4 Titel)

Gerendert aus den Fixtures (FAELLE), alt = origin/dev 2e1d62d, neu = dieser Branch. Der Rufname der
Fixtures ist der des Musters („Ilkay“), auch in den abgestuften Fällen. Fälle ohne Abschnitt sind
wörtlich unverändert. In allen Fällen ohne Thema bleiben Ansatz und Seite 4 wörtlich gleich.

### ilkay
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

### testlauf
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Sie hatten die Konzentration angesprochen. Dazu kann diese Analyse nichts beitragen: Ein einzelner Termin zeigt nicht, wie es über eine Woche aussieht. Der Coach beobachtet es in den ersten Sitzungen.
  - neu: — (Kasten entfällt)

### klasse10neu
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

### klasse7
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Sie hatten die Konzentration angesprochen. Dazu kann diese Analyse nichts beitragen: Ein einzelner Termin zeigt nicht, wie es über eine Woche aussieht. Der Coach beobachtet es in den ersten Sitzungen.
  - neu: — (Kasten entfällt)

### spaeter
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

### allesSicher
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Sie hatten die Konzentration angesprochen. Dazu kann diese Analyse nichts beitragen: Ein einzelner Termin zeigt nicht, wie es über eine Woche aussieht. Der Coach beobachtet es in den ersten Sitzungen.
  - neu: — (Kasten entfällt)

### nichtsSicher
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

### sechsFelderMitUebung
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Sie hatten die Konzentration angesprochen. Dazu kann diese Analyse nichts beitragen: Ein einzelner Termin zeigt nicht, wie es über eine Woche aussieht. Der Coach beobachtet es in den ersten Sitzungen.
  - neu: — (Kasten entfällt)

### alleFelder
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

### ohneName
- Anliegen
  - alt: Ihr Anliegen Sie sind zu uns gekommen, weil Sie Konzentration als Schwierigkeit sehen. Als nächstes Thema steht Algebra & Funktionen an. Sie hatten die Konzentration angesprochen. Dazu kann diese Analyse nichts beitragen: Ein einzelner Termin zeigt nicht, wie es über eine Woche aussieht. Der Coach beobachtet es in den ersten Sitzungen.
  - neu: — (Kasten entfällt)

### vieleRueckbezuege
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration, Prüfungsangst, Zeiteinteilung und Rechenwege. Als nächstes Thema steht Algebra & Funktionen an. Sie hatten die Konzentration angesprochen. Dazu kann diese Analyse nichts beitragen: Ein einzelner Termin zeigt nicht, wie es über eine Woche aussieht. Der Coach beobachtet es in den ersten Sitzungen. Sie hatten die Prüfungsangst angesprochen. Dieser Termin war bewusst keine Prüfung — dazu kann er deshalb nichts zeigen. Der Coach nimmt den Punkt auf. Sie hatten die Zeiteinteilung angesprochen. Dazu kann ein einzelner Termin nichts beitragen — das wird über mehrere Wochen sichtbar. Der Coach hat es im Blick. Sie hatten die Rechenwege genannt. In dieser Analyse hat sich dazu kein wiederkehrendes Muster gezeigt — das heißt aber nicht, dass es keines gibt: Dafür waren es zu wenige Aufgaben. Der Coach schaut in den ersten Sitzungen gezielt darauf.
  - neu: Ihr Anliegen Sie machen sich Sorgen um Ilkays Rechenwege. Dort setzen wir zuerst an: Geometrie. Als nächstes Thema steht Algebra & Funktionen an.

### ohneNotizen
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

### mitFazit
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

### fazitLang
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

### langerName
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Anna-Katharina Henriettes Konzentration, Hausaufgaben und Motivation. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

### zuLangerName
- Anliegen
  - alt: Ihr Anliegen Sie sind zu uns gekommen, weil Sie Konzentration, Hausaufgaben und Motivation als Schwierigkeiten sehen. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

### breiterName
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Mohammed-Mustafa Wilhelms Konzentration, Hausaufgaben und Motivation. Als nächstes Thema steht Algebra & Funktionen an. Sie hatten die Konzentration angesprochen. Dazu kann diese Analyse nichts beitragen: Ein einzelner Termin zeigt nicht, wie es über eine Woche aussieht. Der Coach beobachtet es in den ersten Sitzungen.
  - neu: — (Kasten entfällt)

### weitereBereiche
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

### vieleAnliegen
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Textverständnis, Rechenwege, fehlende Grundlagen und Hausaufgaben. Als nächstes Thema steht Algebra & Funktionen an. Sie hatten das Textverständnis als Schwierigkeit genannt. Die eine Aufgabe mit Sachkontext, die in dieser Analyse vorkam, hat Ihr Kind richtig aus dem Text abgeleitet. Das ist ein schmaler Ausschnitt — der Coach sieht sich den Bereich in den ersten Sitzungen genauer an. Sie hatten die Rechenwege genannt. In dieser Analyse hat sich dazu kein wiederkehrendes Muster gezeigt — das heißt aber nicht, dass es keines gibt: Dafür waren es zu wenige Aufgaben. Der Coach schaut in den ersten Sitzungen gezielt darauf. Sie hatten vermutet, dass Grundlagen fehlen. Der eine Bereich unterhalb des aktuellen Themas, den wir geprüft haben, trägt. Das ist noch kein vollständiges Bild — der Coach geht die Ebenen darunter im Unterricht durch.
  - neu: Ihr Anliegen Sie machen sich Sorgen um Ilkays Textverständnis, Rechenwege und fehlende Grundlagen. Dort setzen wir zuerst an: Geometrie. Als nächstes Thema steht Algebra & Funktionen an.

### keinSchwerpunktMitZiel
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

### abgestuft
- Ansatz
  - alt: Unser erster Ansatz 1 Terme & Gleichungen Dort liegen Sicheres und noch Unsicheres direkt nebeneinander. Wir beginnen bei dem, was schon klappt.
  - neu: Unser erster Ansatz 1 Reelle Zahlen Sicher sind schon Bruch in Dezimalzahl und Wurzeln abschätzen und Näherungswerte. Noch Übung braucht Ilkay bei Wurzelgesetze für Produkt und Quotient, Rationale und irrationale Zahlen und Teilweise die Wurzel ziehen. Wir beginnen bei Wurzelgesetze für Produkt und Quotient.
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Sie hatten die Konzentration angesprochen. Dazu kann diese Analyse nichts beitragen: Ein einzelner Termin zeigt nicht, wie es über eine Woche aussieht. Der Coach beobachtet es in den ersten Sitzungen.
  - neu: Ihr Anliegen Sie sind wegen Reelle Zahlen zu uns gekommen. Dort hakt es bei Wurzelgesetze für Produkt und Quotient, Rationale und irrationale Zahlen und Teilweise die Wurzel ziehen.
- Seite 4
  - alt: Terme & Gleichungen · Zahlen & Rechnen · Geometrie · Daten & Zufall
  - neu: Reelle Zahlen Aktuelles Thema · Terme & Gleichungen · Geometrie · Daten & Zufall

### abgestuftMitOffen
- Ansatz
  - alt: Unser erster Ansatz 1 Zahlen & Rechnen Dort liegen Sicheres und noch Unsicheres direkt nebeneinander. Wir beginnen bei dem, was schon klappt.
  - neu: Unser erster Ansatz 1 Reelle Zahlen Sicher ist schon Quadratwurzel als Umkehrung des Quadrierens. Noch Übung braucht Ilkay bei Runden und Überschlag, Rationale und irrationale Zahlen, Wurzelgesetze für Produkt und Quotient und 2 weitere. Wir beginnen bei Runden und Überschlag.
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: Ihr Anliegen Sie sind wegen Reelle Zahlen zu uns gekommen. Dort hakt es bei Runden und Überschlag, Rationale und irrationale Zahlen, Wurzelgesetze für Produkt und Quotient und 2 weitere.
- Seite 4
  - alt: Zahlen & Rechnen
  - neu: Reelle Zahlen Aktuelles Thema

### abgestuftLang
- Ansatz
  - alt: Unser erster Ansatz 1 Zahlen & Rechnen Dort liegen Sicheres und noch Unsicheres direkt nebeneinander. Wir beginnen bei dem, was schon klappt.
  - neu: Unser erster Ansatz 1 Reelle Zahlen Sicher sind schon Zahlbereich 1, Zahlbereich 7, Zahlbereich 4 und ein weiterer. Noch Übung braucht Ilkay bei Zahlbereich 11, Zahlbereich 6, Zahlbereich 12 und 5 weitere. Wir beginnen bei Zahlbereich 11.
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Sie hatten die Konzentration angesprochen. Dazu kann diese Analyse nichts beitragen: Ein einzelner Termin zeigt nicht, wie es über eine Woche aussieht. Der Coach beobachtet es in den ersten Sitzungen.
  - neu: Ihr Anliegen Sie sind wegen Reelle Zahlen zu uns gekommen. Dort hakt es bei Zahlbereich 11, Zahlbereich 6, Zahlbereich 12 und 5 weitere.
- Seite 4
  - alt: Zahlen & Rechnen
  - neu: Reelle Zahlen Aktuelles Thema

### ohneKanten
- Ansatz
  - alt: Unser erster Ansatz 1 Terme & Gleichungen Dort liegen Sicheres und noch Unsicheres direkt nebeneinander. Wir beginnen bei dem, was schon klappt.
  - neu: Unser erster Ansatz 1 Reelle Zahlen Sicher sind schon Bruch in Dezimalzahl und Wurzeln abschätzen und Näherungswerte. Noch Übung braucht Ilkay bei Rationale und irrationale Zahlen, Teilweise die Wurzel ziehen und Wurzelgesetze für Produkt und Quotient. Wir beginnen bei Rationale und irrationale Zahlen.
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: Ihr Anliegen Sie sind wegen Reelle Zahlen zu uns gekommen. Dort hakt es bei Rationale und irrationale Zahlen, Teilweise die Wurzel ziehen und Wurzelgesetze für Produkt und Quotient.
- Seite 4
  - alt: Terme & Gleichungen · Zahlen & Rechnen · Geometrie · Daten & Zufall
  - neu: Reelle Zahlen Aktuelles Thema · Terme & Gleichungen · Geometrie · Daten & Zufall

### planOhneThema
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Sie hatten die Konzentration angesprochen. Dazu kann diese Analyse nichts beitragen: Ein einzelner Termin zeigt nicht, wie es über eine Woche aussieht. Der Coach beobachtet es in den ersten Sitzungen.
  - neu: — (Kasten entfällt)

### vieleKanten
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

### langeLabels
- Ansatz
  - alt: Unser erster Ansatz 1 Terme & Gleichungen Dort liegen Sicheres und noch Unsicheres direkt nebeneinander. Wir beginnen bei dem, was schon klappt.
  - neu: Unser erster Ansatz 1 Reelle Zahlen Sicher sind schon Bruch in Dezimalzahl und Wurzeln abschätzen und Näherungswerte. Noch Übung braucht Ilkay bei Wurzelgesetze für Produkt und Quotient, Rationale und irrationale Zahlen und Teilweise die Wurzel ziehen. Wir beginnen bei Wurzelgesetze für Produkt und Quotient.
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Sie hatten die Konzentration angesprochen. Dazu kann diese Analyse nichts beitragen: Ein einzelner Termin zeigt nicht, wie es über eine Woche aussieht. Der Coach beobachtet es in den ersten Sitzungen.
  - neu: Ihr Anliegen Sie sind wegen Reelle Zahlen zu uns gekommen. Dort hakt es bei Wurzelgesetze für Produkt und Quotient, Rationale und irrationale Zahlen und Teilweise die Wurzel ziehen.
- Seite 4
  - alt: Terme & Gleichungen · Zahlen & Rechnen · Geometrie · Daten & Zufall
  - neu: Reelle Zahlen Aktuelles Thema · Terme & Gleichungen · Geometrie · Daten & Zufall

### abgestuftThemaSicher (neu)
- Ansatz: Unser erster Ansatz 1 Reelle Zahlen Was wir im Thema Reelle Zahlen geprüft haben, sitzt. Wir arbeiten am aktuellen Stoff weiter.
- Anliegen: Ihr Anliegen Sie sind wegen Reelle Zahlen zu uns gekommen. Was wir dazu geprüft haben, sitzt.
- Seite 4: Reelle Zahlen Aktuelles Thema · Terme & Gleichungen · Geometrie · Daten & Zufall

### abgestuftPlanrang (neu)
- Ansatz: Unser erster Ansatz 1 Reelle Zahlen Sicher sind schon Bruch in Dezimalzahl und Wurzeln abschätzen und Näherungswerte. Noch Übung braucht Ilkay bei Wurzelgesetze für Produkt und Quotient, Rationale und irrationale Zahlen und Teilweise die Wurzel ziehen. Wir beginnen bei Wurzelgesetze für Produkt und Quotient.
- Anliegen: Ihr Anliegen Sie sind wegen Reelle Zahlen zu uns gekommen. Dort hakt es bei Wurzelgesetze für Produkt und Quotient, Rationale und irrationale Zahlen und Teilweise die Wurzel ziehen.
- Seite 4: Reelle Zahlen Aktuelles Thema · Geometrie · Terme & Gleichungen

### anliegenGemischt (neu)
- Ansatz: Unser erster Ansatz 1 Geometrie Dort liegen Sicheres und noch Unsicheres direkt nebeneinander. Wir beginnen bei dem, was schon klappt.
- Anliegen: Ihr Anliegen Sie machen sich Sorgen um Ilkays Noten. Dort setzen wir zuerst an: Geometrie. Als nächstes Thema steht Algebra & Funktionen an.
- Seite 4: Geometrie · Brüche & Dezimalzahlen · Größen · Prozent & Dreisatz

### anliegenNurUeberfach (neu)
- Ansatz: Unser erster Ansatz 1 Geometrie Dort liegen Sicheres und noch Unsicheres direkt nebeneinander. Wir beginnen bei dem, was schon klappt.
- Anliegen: — (Kasten entfällt)
- Seite 4: Geometrie · Brüche & Dezimalzahlen · Größen · Prozent & Dreisatz


## Gegenrechnung Batu (Prod, 6220b7e8, Thema „Reelle Zahlen und Wurzeln“)

- Ansatz: „Sicher sind schon Bruch in Dezimalzahl und Wurzeln abschätzen und Näherungswerte. Noch Übung
  braucht Batu bei Wurzelgesetze für Produkt und Quotient, Rationale und irrationale Zahlen und Teilweise
  die Wurzel ziehen. Wir beginnen bei Wurzelgesetze für Produkt und Quotient.“
- Anliegen: „Sie sind wegen Reelle Zahlen und Wurzeln zu uns gekommen. Dort hakt es bei Wurzelgesetze
  für Produkt und Quotient, Rationale und irrationale Zahlen und Teilweise die Wurzel ziehen.“
  (Batu hat keine Eltern-Einschätzung in `lead_assessments`.)
