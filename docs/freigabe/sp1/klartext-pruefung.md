# Prüfung der Klartexte (klartext-entwurf.json)

Geprüft am 12.11.2026, unabhängig vom Entwurf. Quellen: `scripts/bauformen/bauformen/<key>.py` (`stufen`, `text`,
`parameter()`, `angenehm()`, `fehlbild_steckbrief`) und `docs/reihe1/A/bauformen/<KEY>.json` (`instanzen[]`) im
Worktree `Edvancev1-SP1`. Die geprüfte Datei wurde nicht verändert.

## Zusammenfassung

- **47 Bauformen geprüft: 41 bestätigt, 6 strittig** (EIN-1, EX-2, KO-1, NP-4, NS-4, NS-5).
- Titel: alle 47 verschieden, ohne Kürzel, ohne „Voraussetzung:“. Keiner ist strittig; ein Vorschlag ist freiwillig (SCH-3).
- Platzhalter: Die Schlüssel stimmen bei allen 47 Bauformen genau mit den `{…}` in `text` überein. Ein Wort ist strittig (PAR-4).
- Fehlbilder: alle 50 Schlüssel sind abgedeckt, keiner fehlt und keiner ist zu viel. **4 Kurznamen sind strittig.**
- Verbotenes (Mengenschreibweise, ∈, geschweifte Klammern, Platzhalter) kommt in `beschreibung`/`beispiel` nicht vor.
  Ausnahme ist das Auslassungszeichen in EX-2 Stufe 3, siehe dort.
- Beispiele: Alle Beispiele kommen wörtlich als `frage` ihrer Stufe vor, außer bei EX-0, EX-1, KO-1, NS-4, PAR-1, PAR-2,
  PAR-3 und SCH-2. Dort ist das Beispiel aus `frage` plus Teilfragen, Figur oder Wertetabelle zusammengesetzt. Bei
  diesen Bauformen wurden die Parameter gegengeprüft (z. B. KO-1 P(2|3) in S1, P(3|−5) in S2, P(−1|−3) in S3; PAR-1
  3x² mit x = −3, −2, −1, 2 in S2). Jedes Beispiel gehört zu seiner Stufe.

**Maßstab für „strittig“:** Eine Aussage ist falsch, oder die Beschreibung lässt eine Einschränkung weg, die der
Generator ausdrücklich nennt (im `stufen`-Text oder als harte Regel in `parameter()`/`angenehm()`) und die den Charakter
der Aufgabe ändert. Fehlende Kleinigkeiten (z. B. „ohne 0“ steht nur im Code, nicht im Stufentext) sind unten als
Anmerkung vermerkt. Sie machen eine Bauform nicht strittig.

## Tabelle

| Bauform | Ergebnis | Befund |
|---|---|---|
| AUS-1 | bestätigt | – (S2/S3: Zahl vor x bzw. x² immer positiv, nicht erwähnt, unkritisch) |
| BIN-1 | bestätigt | – |
| BIN-2 | bestätigt | – (Fehlbild-Name siehe Liste) |
| DI-1 | bestätigt | S2: „meist von −20 bis 20“ stimmt. Im Fall „genau eine Lösung“ ist q = (p/2)² und reicht bis 100, so wie im `hinweis` steht. `hinweis` ist ein Zusatzfeld außerhalb des Schemas, inhaltlich richtig. |
| DI-2 | bestätigt | – |
| DI-3 | bestätigt | Anmerkung: S4 ohne 0 und ±2, S5 ohne ±1. Steckt in „gerade/ungerade“ plus Beispiel, unkritisch. |
| EIN-1 | **strittig** | **S1:** „x … 1 bis 6“ ist falsch. Der Generator lässt 2 aus (Stufentext „ohne 2“, `angenehm` verwirft \|x\| = 2), weil bei x = 2 gilt x² = 2x und das Fehlbild „Quadrat als Verdopplung“ nicht mehr zu unterscheiden ist. Vorschlag: „x ist 1, 3, 4, 5 oder 6 (nie 2). Vor x² steht keine Zahl.“ **S2:** ebenso; Vorschlag: „x ist −1, −3, −4, −5 oder −6 (nie −2).“ **S3:** Vorschlag: „x ist −1, −3, −4 oder −5 (nie −2).“ |
| EX-0 | bestätigt | Beispiele sind aus Text und drei Teilfragen zusammengesetzt; Parameter in der Stufe vorhanden. |
| EX-1 | bestätigt | Anmerkung: S5 ohne „in Viererschritten“, das in S4 steht (gilt im Code für beide). Ergänzen wäre sauberer. |
| EX-2 | **strittig** | **S3:** „h(t) = −5t² + … ;“ ist eine unvollständige Formel, das Auslassungszeichen steht für fehlende Glieder (Platzhalter-Ersatz), dazu ein loses Semikolon. Zahlen sonst richtig (b = 10/20/30, c = 1–20, Scheitel ganze Sekunde). Vorschlag: „Wurf vom Turm: Vor t² steht −5, vor t steht 10, 20 oder 30, die Starthöhe ist 1 bis 20 m. Der höchste Punkt liegt bei einer ganzen Sekunde.“ S4 bestätigt. |
| EX-3 | bestätigt | – |
| GL-1 | bestätigt | – |
| KO-1 | **strittig** | **S2:** „Werte −5 bis 5“ lässt 0 zu, also Punkte auf einer Achse (etwa (0 \| −3) erfüllt „genau eine negativ“). Der Generator schließt 0 aus (Stufentext „ohne 0“) und verlangt verschiedene Beträge. Vorschlag: „Genau eine Koordinate ist negativ (Beträge 1 bis 5, verschieden, nie 0).“ S1 und S3 bestätigt. |
| NF-1 | bestätigt | – |
| NF-2 | bestätigt | S2 „bis ±10“ stimmt im Ergebnis: Der Code zieht bis ±16, aber e > 0 bei c ≤ 30 begrenzt auf ±10. |
| NF-3 | bestätigt | Anmerkung: Scheitel-x und -y nie 0, nicht erwähnt. |
| NF-4 | bestätigt | Schrittfolge geprüft (Ergänzung, zusammenfassen, Scheitelpunktform, Scheitel). |
| NF-5 | bestätigt | – (Fehlbild-Namen siehe Liste) |
| NF-6 | bestätigt | – |
| NP-1 | bestätigt | Anmerkung: S2 Beträge verschieden, nicht erwähnt. |
| NP-2 | bestätigt | – |
| NP-3 | bestätigt | – |
| NP-4 | **strittig** | **S4:** „Vielfaches von x (−15 bis 15)“ lässt 0 zu. Dann hieße die Gleichung a·x² = 0 und hätte nur die Lösung 0, eine andere Aufgabe. Der Stufentext sagt „ohne 0“; außerdem ist die zweite Lösung im Betrag höchstens 12. Vorschlag: „x² mit einer Zahl davor (1 bis 4) ist gleich einem Vielfachen von x (−15 bis 15, nie 0). Die zweite Lösung ist ganzzahlig oder ein Bruch, höchstens 12 vom Nullpunkt entfernt.“ |
| NS-1 | bestätigt | S4 „etwa jede vierte ohne Nullstelle“ stimmt (25 %). |
| NS-2 | bestätigt | Anmerkung: Nullstellen nie 0 und nie Gegenzahlen, nicht erwähnt. |
| NS-3 | bestätigt | – |
| NS-4 | **strittig** | **S2 (und S3 über „wie Stufe 2“):** Es fehlt, dass der Abstand der Nullstellen gerade ist (Stufentext „Abstand gerade“), sodass der Scheitel ganzzahlig im Gitter liegt. Außerdem sind die Nullstellen nie 0 und nie Gegenzahlen (Scheitel nicht auf der y-Achse), und der Scheitel liegt höchstens 9 von der x-Achse entfernt. Vorschlag S2: „Zwei ganzzahlige Nullstellen zwischen −5 und 5 (nie 0, nie Gegenzahlen), ihr Abstand ist gerade; der Scheitel hat ganze Koordinaten. Nach oben geöffnet wie die Normalparabel, drei Parabeln zur Auswahl.“ Beispiele passen (−4/2 kommt in S2 und S3 vor). |
| NS-5 | **strittig** | **S3:** Der Generator schließt e = 0 aus (Stufentext „e ≠ 0“). Der Scheitel liegt also nie auf der x-Achse, richtig ist immer „keine“ oder „zwei“. Das ist prüfrelevant, denn „eine“ kommt nur als falscher Baustein vor. Auch d ≠ 0. Vorschlag: „Scheitelpunktform, vor der Klammer −2, −1, 1 oder 2; der Scheitel liegt nie auf einer Achse, die Antwort ist also keine oder zwei Nullstellen. Ohne Rechnen aus Öffnung und Lage des Scheitels entscheiden; eine richtige Begründung, drei falsche.“ |
| PAR-1 | bestätigt | Anmerkung: x = 0 kommt nie vor (Pool ohne 0); „mindestens zwei negativ“ gilt auch in S4, dort nicht erwähnt. |
| PAR-2 | bestätigt | – |
| PAR-3 | bestätigt | – |
| PAR-4 | bestätigt | Beschreibungen richtig (Platzhalter siehe Liste). |
| PAR-5 | bestätigt | – |
| PQ-1 | bestätigt | – |
| PQ-2 | bestätigt | Der `hinweis` zu S2 stimmt: DREIER (5,1)/(10,2) ergibt p = 10, q = 24 bzw. p = 20, q = 96, das ist 0,35 · 0,5 ≈ 1/6. Zusatzfeld außerhalb des Schemas. |
| PQ-3 | bestätigt | – |
| PQ-4 | bestätigt | Schritte geprüft (Normalform, einsetzen, Wurzel, Lösungsmenge). Anmerkung: Das Wort „Lösungsmenge“ ist keine Mengenschreibweise, könnte aber „bis zu den Lösungen“ heißen. |
| QW-1 | bestätigt | – |
| SCH-1 | bestätigt | – |
| SCH-2 | bestätigt | – |
| SCH-3 | bestätigt | Titel siehe Liste (freiwillig). |
| SCH-4 | bestätigt | – |
| WZ-1 | bestätigt | – |
| WZ-2 | bestätigt | – |
| WZ-3 | bestätigt | – |
| WZ-4 | bestätigt | – |
| WZ-5 | bestätigt | – |

## Strittige Fehlbild-Kurznamen

| Schlüssel | Entwurf | Problem | Vorschlag |
|---|---|---|---|
| `qf_binom_vorzeichen` | Vorzeichen im Mittelglied falsch | Passt zu BIN-1 und NF-1. In BIN-2 lautet die Regel „(x − d)² statt (x + d)²“, das falsche Vorzeichen steht in der **Klammer**, nicht im Mittelglied. | „Vorzeichen bei der binomischen Formel falsch“ |
| `qf_oeffnung_aus_e` | Öffnung am Absolutglied abgelesen | In NS-5 und SCH-3 steht die Scheitelpunktform; e ist dort die y-Koordinate des Scheitels („Zahl hinten“), kein Absolutglied. In SCH-3 geht es zudem um Hoch- oder Tiefpunkt. | „Öffnung am Vorzeichen der Zahl hinten abgelesen“ |
| `qf_ergaenzung_nicht_abgezogen` | Ergänzung nicht abgezogen | Passt zu NF-2 und NF-6 (e = c bzw. y = c). In NF-5 heißt die Regel „richtige Zeile, falsche Begründung (a = 1)“: Das Kind hat den Fehler gefunden und falsch begründet, es hat nicht selbst vergessen abzuziehen. | Für NF-5 einen eigenen Schlüssel, Name etwa „Fehlerzeile richtig, Begründung falsch“; sonst den Namen allgemeiner fassen |
| `qf_ergaenzung_ohne_a` | Ergänzung ohne Vorfaktor | Gleiches Problem: passt zu NF-3, aber NF-5 (S4) hat „richtige Zeile, falsche Begründung (a ≠ 1)“. | wie oben |

Weich: Bei `qf_nullprodukt_vorzeichen` („Nullstellen mit falschem Vorzeichen“) stimmt das Wort in NS-3 und NS-4.
NP-1, NP-2 und NP-4 fragen aber nach **Lösungen** einer Gleichung. Vorschlag: „Lösungen mit falschem Vorzeichen“ oder
„Nullstellen/Lösungen mit falschem Vorzeichen“.

Alle übrigen 45 Kurznamen treffen ihre Regel.

## Titel und Platzhalter

- **Titel:** keiner strittig. Freiwillig: SCH-3 „Hoch- oder Tiefpunkt bestimmen und verorten“. „Verorten“ ist
  ungewohnt; besser „Hoch- oder Tiefpunkt bestimmen und angeben, wo er liegt“ oder „Hoch- oder Tiefpunkt und seine Lage
  bestimmen“.
- **Platzhalter, strittig:** PAR-4 `wie` = „Verschiebung“. In S4 enthält der Platzhalter auch die Streckung bzw.
  Stauchung („mit dem Faktor 3 gestreckt und dann um …“). Vorschlag: „Veränderung“ oder „Streckung und Verschiebung“.
