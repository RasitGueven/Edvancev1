# R7-11 · Offene Punkte, Gegenrechnung, Zweitprüfung

Stand 22.10.2026, Branch `feat/rasit-report-r7-ansatz`, mit der Nachbesserung aus der ersten
Zweitprüfung (Gründer, 22.10.). „Unser erster Ansatz“ und die Schwerpunkte richten sich am Thema der
LSA aus. „Ihr Anliegen“ nennt nur noch fachliche Anliegen, als Frage und Antwort. Kein Satz beugt einen
Bereichsnamen. Texte alt → neu: `texte-r7-11.md`.

## Abnahme-Material

- Druck-Tests aller Fälle nach der Nachbesserung: `EB_PORT=5193 EB_AUSGABE=docs/report/r7/abnahme/r7-11
  npx playwright test -c playwright.elternbericht.config.ts`: 32 von 32 grün, PDFs unter `docs/report/r7/abnahme/r7-11/<fall>.pdf`
  (abgestuft, abgestuftThemaSicher, ilkay, anliegenGemischt, anliegenNurUeberfach u. a.).
- Ansichtstests der Präsentation: `TP_PORT=5194 TP_AUSGABE=docs/report/praesentation/abnahme/r7-11 npx
  playwright test -c playwright.praesentation.config.ts`: nach der Nachbesserung 343 von 343 grün in
  einem Gesamtlauf. Fotos unter
  `docs/report/praesentation/abnahme/r7-11/` (Station 01 und 04: `abgestuft_1180x820_01.png`, `_04.png`).

## Woher die Anliegen kommen (Entscheidung 9)

`{{punkte}}` in `s1.anliegen.genannt` = `ReportErzaehlung.anlassNamen` = `lead_assessments.weak_topics`
(source `parent`, über RPC `lsa_lead_kontext`), angezeigt mit dem Anzeigenamen aus
`report_anlass_zuordnung`. Im Intake sind die Werte feste Klick-Optionen (`PARENT_WEAK_TOPICS` in
`src/pages/admin/intake/intakeConstants.ts`). Prod, 22.10.: 17 Einschätzungen; Grundlagen fehlen 9,
Konzentration 6, Textverständnis 5, Rechenwege 3, Zeiteinteilung 1.

| Wert (Intake) | Anzeigename | Zuordnung (`anliegen.ts`) | `messbar` in der DB |
|---|---|---|---|
| Grundlagen fehlen | fehlende Grundlagen | fachlich | ja |
| Rechenwege | Rechenwege | fachlich | ja |
| Textverständnis | Textverständnis | fachlich (Sachaufgaben, Skill `gleichung_modellieren`) | ja |
| Konzentration | Konzentration | überfachlich | nein |
| Prüfungsangst | Prüfungsangst | überfachlich | nein |
| Zeiteinteilung | Zeiteinteilung | überfachlich | nein |
| (Freitext/spätere Optionen) Noten, Lücken, Klassenarbeit(en), Thema | – | fachlich | – |
| (Freitext/spätere Optionen) Motivation, Hausaufgaben, Selbstorganisation | – | überfachlich | – |
| jeder andere Wert | – | überfachlich | – |

**Textverständnis bleibt fachlich**, von den Gründern bestätigt (22.10.). Die übrige Tabelle steht zur
Abnahme.

## Gegenrechnung Batu (Prod, nur lesend über dbread, 6220b7e8)

Thema laut `themen.label`: „Reelle Zahlen und Wurzeln“ (die Fixtures sagen kürzer „Reelle Zahlen“).
Raum vom Abschluss, 14 Bereiche, davon 5 direkt geprüft.

**Themenraum, in der Thema-Reihenfolge** (Rang = die meisten direkt geprüften Voraussetzungen auf einem
Weg im Raum; Gleichstand nach Klasse, dann Label):

| Bereich | Klasse | Zustand | Stand | Rang |
|---|---|---|---|---|
| Bruch in Dezimalzahl | 6 | traegt | sicher | 0 |
| Wurzelgesetze für Produkt und Quotient | 9 | traegt_teilweise | Übungsbedarf | 0 |
| Wurzeln abschätzen und Näherungswerte | 9 | traegt | sicher | 0 |
| Rationale und irrationale Zahlen | 9 | traegt_nicht | Übungsbedarf | 1 (über Bruch in Dezimalzahl) |
| Teilweise die Wurzel ziehen | 9 | traegt_nicht | Übungsbedarf | 1 (über Wurzelgesetze) |

Startstelle: **Wurzelgesetze für Produkt und Quotient**.

**Kommt noch** (FWG, Klasse 9, nach Reelle Zahlen): 0 Quadratische Funktionen · 1 Kreise, Prismen und
Zylinder · 2 Potenzen und Potenzgesetze · 3 Der Satz des Pythagoras … · 4 Daten und Wahrscheinlichkeit.

**Breite** (Übungsbedarf außerhalb des Raums):

| Bereich | Themenfeld | Klasse | Zustand | Planrang |
|---|---|---|---|---|
| Additionsverfahren | Terme & Gleichungen | 8 | traegt_nicht | – |
| Flächeninhalt des Trapezes | Geometrie | 8 | nicht_angesetzt | – |
| Flächeninhalt von Drachen und Raute | Geometrie | 8 | traegt_nicht | – |
| Terme für Flächeninhalte | Geometrie | 8 | traegt_teilweise | – |
| Satz des Thales (Winkel berechnen) | Geometrie | 8 | traegt_nicht | – |
| Mehrstufige Zufallsexperimente: Summenregel | Daten & Zufall | 8 | traegt_nicht | – |

Kein Bereich der Breite wird für ein kommendes Plan-Thema gebraucht. Die Breite folgt deshalb der
alten Regel: Terme (gemischt), Geometrie (4 Bereiche), Daten & Zufall.

Direkt auf der Startstelle baut „Teilweise die Wurzel ziehen“ auf (Übungsbedarf). Der Ansatz sagt
deshalb „Darauf baut Teilweise die Wurzel ziehen auf.“

**Ergebnis Seite 4:** 1 Reelle Zahlen und Wurzeln [Aktuelles Thema] · 2 Terme & Gleichungen · 3 Geometrie ·
4 Daten & Zufall. Vorher: Terme & Gleichungen · Zahlen & Rechnen · Geometrie · Daten & Zufall.

**Ergebnis Seite 1:**
- **Das klappt bereits:** Bruch in Dezimalzahl, Wurzeln abschätzen …, Einsetzungsverfahren,
  Gleichungssysteme grafisch lösen.
- **Hier braucht es noch Übung:** Wurzelgesetze …, Rationale und irrationale Zahlen, Teilweise die
  Wurzel ziehen, Additionsverfahren, +5 weitere.
- **Unser erster Ansatz:** „Im Thema Reelle Zahlen und Wurzeln“ · 1 Wurzelgesetze für Produkt und
  Quotient · „Darauf baut Teilweise die Wurzel ziehen auf.“
- **Ihr Anliegen:** „Ihr Anlass: Reelle Zahlen und Wurzeln. Dort hakt es: Wurzelgesetze für Produkt und
  Quotient, Rationale und irrationale Zahlen und Teilweise die Wurzel ziehen.“

## Zweitprüfung 2 (nach der Nachbesserung; frische Instanz als Elternteil, nur Seite 1 von `abgestuft`)

Antworten wörtlich:
1. „Wir sind hier, weil Ilkay (Klasse 9, Gesamtschule) beim Mathe-Thema ‚Reelle Zahlen‘ Probleme hat;
   das war unser Anlass.“
2. „Es hakt bei den Wurzelgesetzen für Produkt und Quotient, bei rationalen und irrationalen Zahlen und
   beim teilweisen Wurzelziehen; dazu kommen das Additionsverfahren und vier weitere Bereiche, die nicht
   genannt werden.“
3. „Edvance fängt mit den Wurzelgesetzen für Produkt und Quotient an, weil das teilweise Wurzelziehen
   darauf aufbaut.“

Kein Grenzsatz und kein Fachkürzel. Alle drei Fragen sind beantwortet, die dritte jetzt mit Begründung.
Die dreifache Liste und der Widerspruch zwischen Titel und Start aus Zweitprüfung 1 sind weg. Weiter
gefunden (Fundstellen auf Seite 1):

- **Großschreibung mitten im Satz.** „Darauf baut Teilweise die Wurzel ziehen auf.“ (Ansatz) liest
  sich leicht als „baut teilweise … auf“. In „Dort hakt es: …“ (Anliegen) stehen „Rationale“ und
  „Teilweise“ groß. Die Labels sind Nominativ und ungebeugt, wie verlangt. Anführungszeichen um
  Labels im Satz würden helfen; Entscheidung bei Lena.
- **„Ihr Anlass: Reelle Zahlen.“** wiederholt die Überschrift „Ihr Anliegen“ und klingt nach
  Telegrammstil. Der Kasten wiederholt außerdem die Übungskarte.
- **„Im Thema Reelle Zahlen“** (Ansatz): Üblicher wäre „Zum Thema“ oder „Beim Thema“. Der Wortlaut ist
  vorgegeben; Entscheidung bei Lena.
- **„So haben wir geprüft“ (R7-6, nicht Teil dieses Pakets).** Die Zahlen 12 / 14 / 5 / 9 und „Die
  Farben … zeigen nur die direkt geprüften Bereiche“ wirken widersprüchlich. „das System“ klingt
  unpersönlich, und „ergeben sich aus diesen Aufgaben“ hat keinen Bezug.
- **Breite auf Seite 1.** Additionsverfahren, Einsetzungsverfahren und Gleichungssysteme stehen in den
  Listen, gehören aber erkennbar nicht zum Anlass. Eltern fragen sich, ob das zum Problem gehört.
  „+4 weitere“ bleibt ungenannt.
- **„8 Übungsbedarf“** in der Zeile „Auf einen Blick“ (R7-6) ist ungrammatisch; gemeint ist
  „8 mit Übungsbedarf“.
- **Fachwörter.** Die Skill-Labels (Reelle Zahlen, Wurzelgesetze, rationale und irrationale Zahlen,
  Additions-/Einsetzungsverfahren, Näherungswerte) und „Bereich“ als Zähleinheit sind für Eltern ohne
  Mathe-Hintergrund unklar. Abhilfe wäre eine Elternbezeichnung je Skill (siehe R7-9).

### Zweitprüfung 1 (vor der Nachbesserung), zur Nachverfolgung

1. „Wir sind hier, weil Ilkay (9. Klasse, Gesamtschule) Probleme mit dem Thema ‚Reelle Zahlen‘ hat und
   deshalb ein Test mit 24 Aufgaben gemacht wurde.“
2. „Es hakt vor allem bei Rechenregeln für Wurzeln, beim teilweisen Wurzelziehen, bei rationalen und
   irrationalen Zahlen und beim Additionsverfahren. Dazu kommen vier weitere Bereiche, die auf der Seite
   nicht genannt werden.“
3. „Edvance fängt mit den ‚Wurzelgesetzen für Produkt und Quotient‘ an.“

Die Funde daraus hat die Nachbesserung erledigt:
- dreifache Liste
- Titel „Reelle Zahlen“ neben „Wir beginnen bei …“
- Dativ bei Labels
- „Das klappte bereits“

## Entscheidungen beim Bau (bitte bestätigen)

- **Thema-Reihenfolge (Entscheidung 2).** „Topologisch“ ist so umgesetzt: Rang = die meisten direkt
  geprüften Voraussetzungen auf einem Weg im Themenraum. Nicht geprüfte Bereiche des Raums leiten den Weg
  weiter, zählen aber nicht als Stufe. Mit der reinen Weglänge über alle 14 Bereiche läge „Rationale und
  irrationale Zahlen“ gleichauf mit den Wurzelgesetzen und käme nach dem Label zuerst. Dann wäre die
  Startstelle nicht die Wurzelgesetze, anders als die erste Session im Session-Flow.
- **„Mit Thema“** nimmt genau die Bedingung des Thema-Satzes (`themaAbdeckung`): abgestuft, Raum vom
  Abschluss, Label, mindestens ein Bereich direkt im Raum. Ilkay (Prod `adaptiv`, aber Raum nachgetragen)
  bleibt so ohne Thema.
- **Rückbezüge.** Seite 1 zeigt nur noch bestätigende und entlastende Rückbezüge zu fachlichen
  Anliegen, keine „offen“, „nicht messbar“ oder „schmal“ (Entscheidung 14). In den Fixtures bleibt
  dadurch keiner übrig, und der Weg durch den Bericht steht jetzt auch bei `vieleRueckbezuege`. Lena
  könnte die offenen und schmalen Fassungen so neu fassen, dass sie antworten statt abzugrenzen.
- **Thema ohne Übungsbedarf** (Nachbesserung 3, ersetzt Entscheidung 3):
  - Das Thema ist dann kein Schwerpunkt; die Breite beginnt bei Platz 1.
  - Der Ansatz-Kasten zeigt `ansatzThemaSicher`, ohne Kreis und Titel.
  - Ohne Übungsbedarf auch in der Breite gilt Seite 4 wie bisher: `titelKeiner` mit `fazit.keine`.
  - Das Thema steht dafür in `Elternbericht.thema` (Titel und Übungsbedarf darin), auch wenn es kein
    Schwerpunkt ist.
  - Gibt es dann ein fachliches Anliegen, antwortet „Dort setzen wir zuerst an: …“ mit dem
    Feld-Schwerpunkt 1.
- **Ansatz-Kasten und Station 01** (Nachbesserung 1): Station 01 hat keinen Ansatz-Kasten. Sie zeigt
  den Anliegen-Satz (jetzt ohne gebeugte Labels) und die zwei Karten. Die Startstelle als Titel gilt
  deshalb nur auf Seite 1. Station 04 nennt den Thema-Schwerpunkt weiter mit dem Thema als Titel, dazu
  das Schild „Aktuelles Thema“. Soll Station 01 einen eigenen Ansatz bekommen, ist das ein neues
  Element (offen).
- **„Darauf baut … auf“:** Nur ein direkter Nachfolger der Startstelle (Kante in skill_kante) mit
  Übungsbedarf im Thema zählt, bei mehreren der erste in der Thema-Reihenfolge.
- **Station 01.** Die Präsentation zeigte bisher kein Anliegen und keinen Rückbezug. Den Satz „Zur
  Konzentration sagt eine Analyse dieser Länge nichts.“ gab es nur auf Seite 1 (Rückbezug
  `konzentration_nicht_messbar`), nicht in `praesentation.json`. Station 01 zeigt jetzt unter dem
  Leitsatz dieselben Anliegen-Sätze wie Seite 1, ohne Rückbezüge. „Im Blick: …“ steht nur noch, wenn
  es keinen Anliegen-Satz gibt.
- **Typen.** `EbSchwerpunkt.feld` und `TpSchwerpunkt.feld` sind jetzt `ThemenfeldKey | null` (null beim
  Thema). Neu sind `thema`, `start` und `naechster`, dazu `Elternbericht.thema`. Das ist eine Erweiterung,
  kein neues Feld im engen Sinn. Der Compiler findet so jede Stelle, die den Titel aus dem Feld nimmt.
- **lernweg.ts.** Die Kommt-noch-Zeile ist in die exportierte Funktion `kommtNoch` herausgezogen und wird
  in `baueLernweg` unverändert benutzt. Sonst ist nichts an der Datei geändert.

## Offen, nicht in diesem Paket

- Überfachliche Anliegen im ersten Zwischenbericht (Bauauftrag, „Offen, nicht blockierend“).
- Seite 4, Satz „Ob dahinter ein gemeinsames Muster liegt …“: nicht angefasst.
- Ansichtstest `lernweg.spec.ts` „Pfeil und Fläche laufen gemeinsam“ (Station 03, hier nicht geändert):
  Im ersten Gesamtlauf unter Last rot (größtes Wachstum einer Linie 92 > 40 px), allein und im zweiten
  Gesamtlauf grün. Das ist eine Bild-Zeitmessung, keine Folge dieses Pakets. Im zweiten Gesamtlauf
  waren fünf Fälle (abgestuftThemaSicher, anliegenGemischt) rot, während ich eine Hilfsdatei im
  Worktree angelegt hatte (Vite lädt dann neu). Einzeln wiederholt waren alle 18 grün.
