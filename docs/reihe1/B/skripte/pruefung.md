# B8 · Prüfung der Skripte V1–V8

Stand 27.10.2026. Skripte: `V1.json` … `V8.json` (nur Skelett, Welten später). Erzeugt mit `erzeugen.py`
(`python3 erzeugen.py docs/reihe1/B/skripte`); Änderungen bitte im Studio über „Skript einfügen“ oder dort.

## 1 · Importprüfung (automatisch)

`src/studio/skript/skripteReihe1.test.ts`, 40 Fälle, alle grün:
- Importprüfung ohne Sperre gegen den Fehlbild-Katalog von Auftrag A (`katalog-qf.json`, Stand Prod 27.10.).
- Sprechtext ohne Ziffern und ohne Formelzeichen; 6–12 Beats; 2–3 Mini-Checks, jeder mit Zwilling (andere Zahlen).
- Je Video das Fehlbild und der Rücksprung aus Konzept §8; Zwillinge mit denselben Fehlbildern wie die Hauptfrage.
- Gegen den echten Katalog in Prod (dbread, 27.10.): alle 23 verwendeten Schlüssel vorhanden.
- Alle Beats als Standbild gerendert (MathJax setzt jede Formel; zu breite Formeln gekürzt).

## 2 · Fachliche und sprachliche Prüfung

Frischer Subagent als Fachlehrkraft Klasse 9/10, ohne Kontext und nicht der Autor. Fragen: Stimmt jede Rechnung? Führt jeder Rücksprung an die Stelle, die das Fehlbild erklärt? Ist der Mini-Check ohne Video lösbar? Sprache für 14- bis 16-Jährige?

Ergebnis: Alle richtigen Optionen und alle Distraktor-Herleitungen stimmen; jeder Mini-Check ist ohne Video lösbar. Befunde und Umgang:

| Video | Befund | Umgang |
|---|---|---|
| V1 | b8 „Quadrieren macht nichts negativ“ missverständlich | „Ein Quadrat ist nie negativ“ |
| V1 | Zwilling von Check 2 (P(2 \| 4)) steht wörtlich in b7 | P(4 \| 16) |
| V1 | Option −8 ohne Rücksprung | bleibt ohne Fehlbild (kein passender Katalog-Schlüssel; Rücksprung braucht ein Fehlbild) |
| V1 | `qf_scheitel_koordinaten_vertauscht` für einen beliebigen Punkt | bleibt: Klartext im Katalog lautet „Vertauscht x- und y-Koordinate eines Punktes“ |
| V2 | b6 „alle y-Werte negativ“ falsch bei x = 0 | „wechseln das Vorzeichen“, dazu „Scheitel ist jetzt der höchste Punkt“ |
| V2 | Rückmeldung „Minus vor a“; Frage „geöffnet“ mit Antwort „enger“ | „a ist negativ …“; Frage „im Vergleich zur Normalparabel“ |
| V2 | Rücksprung 0,3x² → b3 | → b5 („weiter“); Check 2 behält → b3 (Konzept §8: „a = 2 im Vergleich“) |
| V2 | a erst in b7 benannt; „mit einem Halben“ | „Die Zahl davor nennen wir a“ in b3; „Steht ein Halb davor“ |
| V3 | Gleichungen fehlen im Bild (b2, b3, b5) | ergänzt |
| V3 | „Genau dort liegt der Scheitel“; „bei minus eins und minus drei“ | x-Wert bzw. x- und y-Wert ausdrücklich |
| V3 | Check nach der Endkarte | nach b8 |
| V3 | Scheitelpunktform ohne a | Merksatz „Ohne Streckfaktor (a = 1)“ |
| V4 | Rückmeldungen „Beim Quadrat einer Summe fehlt …“, „+ 16 − 16 + 10 = …“ | „Bei dir fehlt …“, vollständige Gleichung |
| V4 | b7: drei Gedanken, großer Sprung | geteilt in b7 (ausklammern, ergänzen) und b8 (auflösen, mal a, Zwischenzeile) |
| V4 | „x plus drei zum Quadrat“ hörbar als x + 3² | „die Klammer x plus drei zum Quadrat“ |
| V5 | b3 „minus drei hoch zwei ist neun“ (gehört −3² = −9) | „minus drei mal minus drei ist neun“ |
| V5 | b4: zwei Gedanken | geteilt: b4 (c = 0), b5 (c < 0) |
| V5 | `qf_e_vorzeichen` bzw. `qf_verschiebung_vorzeichen` für Gegenoperation | `qf_gegenoperation_vorzeichen` |
| V5 | Rücksprung Hälfte → b2 | → b3 |
| V5 | Merksatz-Formel ohne Bedingung; „Die meisten sagen: eine“ | „c > 0“; „Viele sagen sofort: drei“ |
| V6 | Buchstabe a schon Streckfaktor | u · v bzw. x − c |
| V6 | Check 2: Vorschlag `qf_durch_x_geteilt` → b6 | bleibt `qf_null_vergessen` → b5 (Konzept §8: „Ein Faktor ist x selbst“); Rückmeldung nennt „nicht durch x teilen“ |
| V6 | b1 kindlich; b6 ohne Begründung | umformuliert; „x könnte ja null sein“ |
| V7 | b1 „löst jede …“ | „sofern sie Lösungen haben“ |
| V7 | b6: −(−5) übersprungen, „Wurzel aus vier plus fünf“ | Zwischenzeile `\sqrt{4 - (-5)}`, gesprochen „vier minus minus fünf, also neun“ |
| V7 | Rückmeldung mischt q und Zahlen | „(p/2)² − q = 1 − 5 = −4“ |
| V8 | „Scheitel ist keine Nullstelle“ zu allgemein | „Hier ist der Scheitel keine Nullstelle“; Merksatz „verschiedene Dinge“ |
| V8 | f(x) neu | „F von x ist einfach der y-Wert“ |
| V8 | `qf_nur_eine_loesung` statt `qf_nur_positive_loesung` (wie V5) | vereinheitlicht |
| V8 | Vorschlag Rücksprung Scheitel → b5 | bleibt → b3 (Konzept §8: „f(x) = 0“) |
| V8 | b6: x = 0 nicht gezeigt | erste Zeile zeigt x(x − 5) = 0 |

## 3 · Offen

- Ein Video mit nur einer Kernidee (V1, V2) hat zwei Mini-Checks; in der Session spielt E1 je Kernidee den ersten Check (B6). Der zweite ist für eine spätere Rotation da.
- Welten (Fußball, Gaming, Musik) kommen später als reine Textvarianten.
