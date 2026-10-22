# R7-11 · Offene Punkte, Gegenrechnung, Zweitprüfung

Stand 22.10.2026, Branch `feat/rasit-report-r7-ansatz`. „Unser erster Ansatz“ und die Schwerpunkte
richten sich am Thema der LSA aus; „Ihr Anliegen“ nennt nur noch fachliche Anliegen, als Frage und
Antwort. Texte alt → neu: `texte-r7-11.md`.

## Abnahme-Material

- Druck-Tests aller Fälle: `EB_PORT=5193 EB_AUSGABE=docs/report/r7/abnahme/r7-11 npx playwright test -c
  playwright.elternbericht.config.ts`: 32 von 32 grün, PDFs unter `docs/report/r7/abnahme/r7-11/<fall>.pdf`
  (abgestuft, abgestuftThemaSicher, ilkay, anliegenGemischt, anliegenNurUeberfach u. a.).
- Ansichtstests der Präsentation: `TP_PORT=5194 TP_AUSGABE=docs/report/praesentation/abnahme/r7-11 npx
  playwright test -c playwright.praesentation.config.ts`, Fotos unter
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

**Zur Bestätigung durch die Gründer.** Strittig ist nur Textverständnis: Es ist Lesekompetenz, die
Datenbank ordnet es aber den Sachaufgaben zu und hält es für messbar. Ich habe es deshalb fachlich gesetzt.

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

**Ergebnis Seite 4:** 1 Reelle Zahlen und Wurzeln [Aktuelles Thema] · 2 Terme & Gleichungen · 3 Geometrie ·
4 Daten & Zufall. Vorher: Terme & Gleichungen · Zahlen & Rechnen · Geometrie · Daten & Zufall.

**Ergebnis Seite 1:**
- Listen: Das klappte bereits = Bruch in Dezimalzahl, Wurzeln abschätzen …, Einsetzungsverfahren,
  Gleichungssysteme grafisch lösen. Hier braucht es noch Übung = Wurzelgesetze …, Rationale und
  irrationale Zahlen, Teilweise die Wurzel ziehen, Additionsverfahren, +5 weitere.
- Ansatz und Anliegen: wörtlich in `texte-r7-11.md`, Abschnitt „Gegenrechnung“.

## Zweitprüfung (frische Instanz als Elternteil, nur Seite 1 von `abgestuft`)

Antworten wörtlich:
1. „Wir sind hier, weil Ilkay (9. Klasse, Gesamtschule) Probleme mit dem Thema ‚Reelle Zahlen‘ hat und
   deshalb ein Test mit 24 Aufgaben gemacht wurde.“
2. „Es hakt vor allem bei Rechenregeln für Wurzeln, beim teilweisen Wurzelziehen, bei rationalen und
   irrationalen Zahlen und beim Additionsverfahren. Dazu kommen vier weitere Bereiche, die auf der Seite
   nicht genannt werden.“
3. „Edvance fängt mit den ‚Wurzelgesetzen für Produkt und Quotient‘ an.“

Kein Grenzsatz gefunden. Alle drei Fragen sind beantwortet. Diese Sätze wurden für die Antworten nicht
gebraucht oder waren unklar (Fundstellen auf Seite 1):

- **Dieselbe Liste dreimal.** Sie steht in „Hier braucht es noch Übung“, in „Unser erster Ansatz“
  („Noch Übung braucht …“) und in „Ihr Anliegen“ („Dort hakt es bei …“). Dazu wiederholt der Ansatz die
  sicheren Bereiche („Sicher sind schon …“) aus „Das klappte bereits“. Vorschlag für die Gründer: Im
  Ansatz nur den Start-Satz zeigen, oder im Anliegen nur das Thema nennen.
- **Titel „1 Reelle Zahlen“ vs. „Wir beginnen bei Wurzelgesetze …“.** Es ist unklar, womit begonnen
  wird. Außerdem deutet die „1“ einen Schritt 2 an, den Seite 1 nicht zeigt.
- **Grammatik (Dativ).** „bei Wurzelgesetze für Produkt und Quotient“, „wegen Reelle Zahlen“: Die Labels
  stehen im Nominativ, und „Teilweise …“ ist mitten im Satz groß geschrieben. Das lässt sich ohne
  Beugung der Labels nicht lösen. Möglich wären Anführungszeichen („bei ‚Wurzelgesetze …‘“), eine
  Elternbezeichnung im Dativ je Skill (Migration, siehe R7-9), oder die Liste aus dem Satz nehmen.
  Entscheidung bei Lena.
- **„So haben wir geprüft“.** Die Zahlen 12 / 14 / 5 / 9 passen für Eltern nicht zusammen: „das System“
  klingt technisch, und „Die Farben … zeigen nur die direkt geprüften Bereiche“ verwirrt, weil auch
  Bereiche außerhalb des Themas farbig sind. Das ist R7-6 und war nicht Teil dieses Pakets.
- **Fachwörter.** Kein Fachkürzel, aber Fachbegriffe als Bereichsnamen (Reelle Zahlen, rationale und
  irrationale Zahlen, Additions-/Einsetzungsverfahren, Näherungswerte). Das sind die Skill-Labels. Eine
  Elternbezeichnung je Skill wäre die Abhilfe (siehe R7-9).
- **„Das klappte bereits“** (Anhang A) klingt nach Vergangenheit; „Das klappt bereits“ wäre klarer.

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
- **Thema ohne Übungsbedarf.** Das Thema bleibt Schwerpunkt 1 (Entscheidung 3), auch wenn sonst nirgends
  Übungsbedarf ist. Seite 4 heißt dann „Ein Schwerpunkt.“ und zeigt beim Thema nur „Sicher: …“, statt
  „Kein Übungsbedarf …“ mit `fazit.keine`. Bitte prüfen, ob das so gewollt ist.
- **Station 01.** Die Präsentation zeigte bisher kein Anliegen und keinen Rückbezug. Den Satz „Zur
  Konzentration sagt eine Analyse dieser Länge nichts.“ gab es nur auf Seite 1 (Rückbezug
  `konzentration_nicht_messbar`), nicht in `praesentation.json`. Station 01 zeigt jetzt unter dem
  Leitsatz dieselben Anliegen-Sätze wie Seite 1, ohne Rückbezüge. „Im Blick: …“ steht nur noch, wenn
  es keinen Anliegen-Satz gibt.
- **Typen.** `EbSchwerpunkt.feld` und `TpSchwerpunkt.feld` sind jetzt `ThemenfeldKey | null` (null beim
  Thema). Neu sind `thema` und `start`. Das ist eine Erweiterung, kein neues Feld im engen Sinn. Der
  Compiler findet so jede Stelle, die den Titel aus dem Feld nimmt.
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
