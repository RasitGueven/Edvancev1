# R7-11 · Texte alt → neu (Entwürfe für Lena)

Stand 22.10.2026 nach der Nachbesserung (Gründer, aus der Zweitprüfung), Branch
`feat/rasit-report-r7-ansatz`. Alle Texte stehen im Namespace `elternbericht`; die Präsentation nimmt
dieselben Schlüssel über `tb`. Neue oder geänderte Schlüssel in `praesentation.json` gibt es nicht.

**Regel der Nachbesserung:** Kein Satz beugt einen Bereichsnamen. Ein Label steht nach einem
Doppelpunkt oder als Subjekt im Nominativ.

## Neue Schlüssel

| Schlüssel | Text |
|---|---|
| `s1.blick.ansatzThema.kicker` | Im Thema {{thema}} |
| `s1.blick.ansatzThema.naechster` | Darauf baut {{naechster}} auf. |
| `s1.blick.ansatzThema.zuerst` | Hier setzen wir zuerst an. |
| `s1.blick.ansatzThemaSicher` | Was wir im Thema {{thema}} geprüft haben, sitzt. Wir arbeiten am aktuellen Stoff weiter. |
| `s1.anliegen.antwort` | Dort hakt es: {{liste}}. |
| `s1.anliegen.antwortSicher` | Was wir dazu geprüft haben, sitzt. |
| `s1.anliegen.antwortSchwerpunkt` | Dort setzen wir zuerst an: {{schwerpunkt}}. |
| `s1.anliegen.naechstesThema` | Als nächstes Thema steht {{thema}} an. (bisher `s1.anliegen.thema`, Wortlaut unverändert, nur noch ohne Thema der LSA) |
| `s4.chip.thema` | Aktuelles Thema |

**Der Ansatz-Kasten mit Thema:**
- Klein oben steht „Im Thema …“, darunter die Startstelle als Titel mit der „1“.
- Darunter steht genau ein Satz: „Darauf baut … auf.“, wenn ein Bereich mit Übungsbedarf im Thema direkt
  auf der Startstelle aufbaut, sonst „Hier setzen wir zuerst an.“
- Eine Liste der sicheren oder unsicheren Bereiche steht im Ansatz nicht mehr, nur noch im Anliegen.
- Ohne Übungsbedarf im Thema ist das Thema kein Schwerpunkt. Der Kasten zeigt dann nur
  `ansatzThemaSicher`.

Aus der ersten Fassung entfallen (nie auf dev): `s1.blick.ansatzThema.sicher_*`, `.uebung`,
`.uebungOhneName`, `.start_*`.

## Geänderte Anhang-A-Schlüssel (einzeln in INV-4.9, `R7_11_GEAENDERT`)

| Schlüssel | alt | neu |
|---|---|---|
| `s1.anliegen.thema` | Als nächstes Thema steht {{thema}} an. | Ihr Anlass: {{thema}}. |
| `s1.blick.sicher` | Das klappte bereits | Das klappt bereits |
| `s2.fussnote` | … Ein Bereich gilt als sicher, wenn die geprüften Aufgaben dazu gelangen; die Bewertungsregel ist noch nicht abschließend festgelegt. … | … Ein Bereich gilt als sicher, wenn die geprüften Aufgaben dazu gelangen. … |

`s1.blick.sicher` erscheint nur im Druck. Die Präsentation nennt die Karte „Schon gelungen“
(`praesentation.s1.gelungen`), dort war nichts zu ändern.

## Nicht mehr gezeigt (Daten bleiben)

- Überfachliche Anliegen (Konzentration, Prüfungsangst, Zeiteinteilung, Unbekanntes) in „Sie machen sich
  Sorgen um …“.
- Rückbezüge der Richtungen `nicht_messbar` und `offen` und die schmalen Fassungen (`*_schmal`):
  Sie sagen, was die Analyse nicht sagen kann oder erst später klärt (Entscheidung 14).

## Zusammengesetzte Sätze aller Testfälle (Seite 1 „Unser erster Ansatz“ und „Ihr Anliegen“, Seite 4 Titel)

Gerendert aus den Fixtures (FAELLE), alt = origin/dev 2e1d62d, neu = dieser Branch. Der Rufname der
Fixtures ist der des Musters („Ilkay“), auch in den abgestuften Fällen. In allen Fällen ohne Thema
bleiben Ansatz und Seite 4 wörtlich gleich.

#### ilkay
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

#### testlauf
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Sie hatten die Konzentration angesprochen. Dazu kann diese Analyse nichts beitragen: Ein einzelner Termin zeigt nicht, wie es über eine Woche aussieht. Der Coach beobachtet es in den ersten Sitzungen.
  - neu: — (Kasten entfällt)

#### klasse10neu
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

#### klasse7
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Sie hatten die Konzentration angesprochen. Dazu kann diese Analyse nichts beitragen: Ein einzelner Termin zeigt nicht, wie es über eine Woche aussieht. Der Coach beobachtet es in den ersten Sitzungen.
  - neu: — (Kasten entfällt)

#### spaeter
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

#### allesSicher
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Sie hatten die Konzentration angesprochen. Dazu kann diese Analyse nichts beitragen: Ein einzelner Termin zeigt nicht, wie es über eine Woche aussieht. Der Coach beobachtet es in den ersten Sitzungen.
  - neu: — (Kasten entfällt)

#### nichtsSicher
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

#### sechsFelderMitUebung
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Sie hatten die Konzentration angesprochen. Dazu kann diese Analyse nichts beitragen: Ein einzelner Termin zeigt nicht, wie es über eine Woche aussieht. Der Coach beobachtet es in den ersten Sitzungen.
  - neu: — (Kasten entfällt)

#### alleFelder
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

#### ohneName
- Anliegen
  - alt: Ihr Anliegen Sie sind zu uns gekommen, weil Sie Konzentration als Schwierigkeit sehen. Als nächstes Thema steht Algebra & Funktionen an. Sie hatten die Konzentration angesprochen. Dazu kann diese Analyse nichts beitragen: Ein einzelner Termin zeigt nicht, wie es über eine Woche aussieht. Der Coach beobachtet es in den ersten Sitzungen.
  - neu: — (Kasten entfällt)

#### vieleRueckbezuege
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration, Prüfungsangst, Zeiteinteilung und Rechenwege. Als nächstes Thema steht Algebra & Funktionen an. Sie hatten die Konzentration angesprochen. Dazu kann diese Analyse nichts beitragen: Ein einzelner Termin zeigt nicht, wie es über eine Woche aussieht. Der Coach beobachtet es in den ersten Sitzungen. Sie hatten die Prüfungsangst angesprochen. Dieser Termin war bewusst keine Prüfung — dazu kann er deshalb nichts zeigen. Der Coach nimmt den Punkt auf. Sie hatten die Zeiteinteilung angesprochen. Dazu kann ein einzelner Termin nichts beitragen — das wird über mehrere Wochen sichtbar. Der Coach hat es im Blick. Sie hatten die Rechenwege genannt. In dieser Analyse hat sich dazu kein wiederkehrendes Muster gezeigt — das heißt aber nicht, dass es keines gibt: Dafür waren es zu wenige Aufgaben. Der Coach schaut in den ersten Sitzungen gezielt darauf.
  - neu: Ihr Anliegen Sie machen sich Sorgen um Ilkays Rechenwege. Dort setzen wir zuerst an: Geometrie. Als nächstes Thema steht Algebra & Funktionen an.

#### ohneNotizen
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

#### mitFazit
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

#### fazitLang
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

#### langerName
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Anna-Katharina Henriettes Konzentration, Hausaufgaben und Motivation. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

#### zuLangerName
- Anliegen
  - alt: Ihr Anliegen Sie sind zu uns gekommen, weil Sie Konzentration, Hausaufgaben und Motivation als Schwierigkeiten sehen. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

#### breiterName
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Mohammed-Mustafa Wilhelms Konzentration, Hausaufgaben und Motivation. Als nächstes Thema steht Algebra & Funktionen an. Sie hatten die Konzentration angesprochen. Dazu kann diese Analyse nichts beitragen: Ein einzelner Termin zeigt nicht, wie es über eine Woche aussieht. Der Coach beobachtet es in den ersten Sitzungen.
  - neu: — (Kasten entfällt)

#### weitereBereiche
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

#### vieleAnliegen
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Textverständnis, Rechenwege, fehlende Grundlagen und Hausaufgaben. Als nächstes Thema steht Algebra & Funktionen an. Sie hatten das Textverständnis als Schwierigkeit genannt. Die eine Aufgabe mit Sachkontext, die in dieser Analyse vorkam, hat Ihr Kind richtig aus dem Text abgeleitet. Das ist ein schmaler Ausschnitt — der Coach sieht sich den Bereich in den ersten Sitzungen genauer an. Sie hatten die Rechenwege genannt. In dieser Analyse hat sich dazu kein wiederkehrendes Muster gezeigt — das heißt aber nicht, dass es keines gibt: Dafür waren es zu wenige Aufgaben. Der Coach schaut in den ersten Sitzungen gezielt darauf. Sie hatten vermutet, dass Grundlagen fehlen. Der eine Bereich unterhalb des aktuellen Themas, den wir geprüft haben, trägt. Das ist noch kein vollständiges Bild — der Coach geht die Ebenen darunter im Unterricht durch.
  - neu: Ihr Anliegen Sie machen sich Sorgen um Ilkays Textverständnis, Rechenwege und fehlende Grundlagen. Dort setzen wir zuerst an: Geometrie. Als nächstes Thema steht Algebra & Funktionen an.

#### keinSchwerpunktMitZiel
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

#### abgestuft
- Ansatz
  - alt: Unser erster Ansatz 1 Terme & Gleichungen Dort liegen Sicheres und noch Unsicheres direkt nebeneinander. Wir beginnen bei dem, was schon klappt.
  - neu: Unser erster Ansatz Im Thema Reelle Zahlen 1 Wurzelgesetze für Produkt und Quotient Darauf baut Teilweise die Wurzel ziehen auf.
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Sie hatten die Konzentration angesprochen. Dazu kann diese Analyse nichts beitragen: Ein einzelner Termin zeigt nicht, wie es über eine Woche aussieht. Der Coach beobachtet es in den ersten Sitzungen.
  - neu: Ihr Anliegen Ihr Anlass: Reelle Zahlen. Dort hakt es: Wurzelgesetze für Produkt und Quotient, Rationale und irrationale Zahlen und Teilweise die Wurzel ziehen.
- Seite 4
  - alt: Terme & Gleichungen · Zahlen & Rechnen · Geometrie · Daten & Zufall
  - neu: Reelle Zahlen Aktuelles Thema · Terme & Gleichungen · Geometrie · Daten & Zufall

#### abgestuftMitOffen
- Ansatz
  - alt: Unser erster Ansatz 1 Zahlen & Rechnen Dort liegen Sicheres und noch Unsicheres direkt nebeneinander. Wir beginnen bei dem, was schon klappt.
  - neu: Unser erster Ansatz Im Thema Reelle Zahlen 1 Runden und Überschlag Darauf baut Wurzeln abschätzen und Näherungswerte auf.
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: Ihr Anliegen Ihr Anlass: Reelle Zahlen. Dort hakt es: Runden und Überschlag, Rationale und irrationale Zahlen, Wurzelgesetze für Produkt und Quotient und 2 weitere.
- Seite 4
  - alt: Zahlen & Rechnen
  - neu: Reelle Zahlen Aktuelles Thema

#### abgestuftLang
- Ansatz
  - alt: Unser erster Ansatz 1 Zahlen & Rechnen Dort liegen Sicheres und noch Unsicheres direkt nebeneinander. Wir beginnen bei dem, was schon klappt.
  - neu: Unser erster Ansatz Im Thema Reelle Zahlen 1 Zahlbereich 11 Hier setzen wir zuerst an.
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Sie hatten die Konzentration angesprochen. Dazu kann diese Analyse nichts beitragen: Ein einzelner Termin zeigt nicht, wie es über eine Woche aussieht. Der Coach beobachtet es in den ersten Sitzungen.
  - neu: Ihr Anliegen Ihr Anlass: Reelle Zahlen. Dort hakt es: Zahlbereich 11, Zahlbereich 6, Zahlbereich 12 und 5 weitere.
- Seite 4
  - alt: Zahlen & Rechnen
  - neu: Reelle Zahlen Aktuelles Thema

#### ohneKanten
- Ansatz
  - alt: Unser erster Ansatz 1 Terme & Gleichungen Dort liegen Sicheres und noch Unsicheres direkt nebeneinander. Wir beginnen bei dem, was schon klappt.
  - neu: Unser erster Ansatz Im Thema Reelle Zahlen 1 Rationale und irrationale Zahlen Hier setzen wir zuerst an.
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: Ihr Anliegen Ihr Anlass: Reelle Zahlen. Dort hakt es: Rationale und irrationale Zahlen, Teilweise die Wurzel ziehen und Wurzelgesetze für Produkt und Quotient.
- Seite 4
  - alt: Terme & Gleichungen · Zahlen & Rechnen · Geometrie · Daten & Zufall
  - neu: Reelle Zahlen Aktuelles Thema · Terme & Gleichungen · Geometrie · Daten & Zufall

#### planOhneThema
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Sie hatten die Konzentration angesprochen. Dazu kann diese Analyse nichts beitragen: Ein einzelner Termin zeigt nicht, wie es über eine Woche aussieht. Der Coach beobachtet es in den ersten Sitzungen.
  - neu: — (Kasten entfällt)

#### vieleKanten
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Als nächstes Thema steht Algebra & Funktionen an. Zur Konzentration sagt eine Analyse dieser Länge nichts. Wie lange Ihr Kind bei einer Sache bleibt, zeigt sich über mehrere Sitzungen — der Coach hat das von der ersten an im Blick.
  - neu: — (Kasten entfällt)

#### langeLabels
- Ansatz
  - alt: Unser erster Ansatz 1 Terme & Gleichungen Dort liegen Sicheres und noch Unsicheres direkt nebeneinander. Wir beginnen bei dem, was schon klappt.
  - neu: Unser erster Ansatz Im Thema Reelle Zahlen 1 Wurzelgesetze für Produkt und Quotient Darauf baut Teilweise die Wurzel ziehen auf.
- Anliegen
  - alt: Ihr Anliegen Sie machen sich Sorgen um Ilkays Konzentration. Sie hatten die Konzentration angesprochen. Dazu kann diese Analyse nichts beitragen: Ein einzelner Termin zeigt nicht, wie es über eine Woche aussieht. Der Coach beobachtet es in den ersten Sitzungen.
  - neu: Ihr Anliegen Ihr Anlass: Reelle Zahlen. Dort hakt es: Wurzelgesetze für Produkt und Quotient, Rationale und irrationale Zahlen und Teilweise die Wurzel ziehen.
- Seite 4
  - alt: Terme & Gleichungen · Zahlen & Rechnen · Geometrie · Daten & Zufall
  - neu: Reelle Zahlen Aktuelles Thema · Terme & Gleichungen · Geometrie · Daten & Zufall

#### abgestuftThemaSicher (neu)
- Ansatz: Unser erster Ansatz Was wir im Thema Reelle Zahlen geprüft haben, sitzt. Wir arbeiten am aktuellen Stoff weiter.
- Anliegen: Ihr Anliegen Ihr Anlass: Reelle Zahlen. Was wir dazu geprüft haben, sitzt.
- Seite 4: Terme & Gleichungen · Geometrie · Daten & Zufall

#### abgestuftPlanrang (neu)
- Ansatz: Unser erster Ansatz Im Thema Reelle Zahlen 1 Wurzelgesetze für Produkt und Quotient Darauf baut Teilweise die Wurzel ziehen auf.
- Anliegen: Ihr Anliegen Ihr Anlass: Reelle Zahlen. Dort hakt es: Wurzelgesetze für Produkt und Quotient, Rationale und irrationale Zahlen und Teilweise die Wurzel ziehen.
- Seite 4: Reelle Zahlen Aktuelles Thema · Geometrie · Terme & Gleichungen

#### anliegenGemischt (neu)
- Ansatz: Unser erster Ansatz 1 Geometrie Dort liegen Sicheres und noch Unsicheres direkt nebeneinander. Wir beginnen bei dem, was schon klappt.
- Anliegen: Ihr Anliegen Sie machen sich Sorgen um Ilkays Noten. Dort setzen wir zuerst an: Geometrie. Als nächstes Thema steht Algebra & Funktionen an.
- Seite 4: Geometrie · Brüche & Dezimalzahlen · Größen · Prozent & Dreisatz

#### anliegenNurUeberfach (neu)
- Ansatz: Unser erster Ansatz 1 Geometrie Dort liegen Sicheres und noch Unsicheres direkt nebeneinander. Wir beginnen bei dem, was schon klappt.
- Anliegen: — (Kasten entfällt)
- Seite 4: Geometrie · Brüche & Dezimalzahlen · Größen · Prozent & Dreisatz


## Gegenrechnung Batu (Prod, 6220b7e8, Thema „Reelle Zahlen und Wurzeln“)

- **Ansatz:** „Im Thema Reelle Zahlen und Wurzeln“ · 1 **Wurzelgesetze für Produkt und Quotient** ·
  „Darauf baut Teilweise die Wurzel ziehen auf.“
- **Anliegen:** „Ihr Anlass: Reelle Zahlen und Wurzeln. Dort hakt es: Wurzelgesetze für Produkt und
  Quotient, Rationale und irrationale Zahlen und Teilweise die Wurzel ziehen.“ Batu hat keine
  Eltern-Einschätzung in `lead_assessments`.
