# R6 — Die App zeigt die abgestimmte Erzählung

**Datum:** 2026-08-19
**Branch:** `feature/r6-reportbody-v3` (von `dev`)
**Anlass:** R4 und R5 haben die Erzählung gebaut, aber nur der HTML-Generator
nutzte sie. `ReportBody.tsx` stand seit R3 unverändert — der größte Abstand
zwischen Entwurf und Produkt.

---

## Was jetzt in der App steht

```
01 Warum wir geschaut haben   was die Eltern genannt haben, wörtlich
02 Wie wir gesucht haben      Abstieg durch die Fundamentebenen
03 Was wir gefunden haben     Profil über die Themen, dann die zwei Listen
04 Wie es sich zeigt          wiederkehrende Denkschritte
   Aufklappbereich            was der Coach zuerst nachprüft
05 So geht es weiter          Fazit, Aufgriff der Eltern-Punkte, Empfehlung
   Fußzeile                   wer die Analyse begleitet hat
```

Gerechnet wird mit **denselben reinen Funktionen** wie im Generator
(`src/lib/report/*`). Der Lesepfad liegt in `lsaReportErzaehlung.ts`, damit
`lsaReport.ts` unter der 400-Zeilen-Grenze bleibt.

## Zwei Entscheidungen, die Rasit getroffen hat

### Struktur: ersetzt, nicht ergänzt

Entfallen sind: die Erzählung aus Bearbeitungsdauern (`reportNarrative.ts`),
der Stärke-Abschnitt, die Belege je Themenfeld (`ReportTopicBar`), der
Themen-Anhang und der eigene Block mit der Eltern-Einschätzung.

Zwei Erzählungen nebeneinander — eine aus Bearbeitungszeiten, eine aus
Trag-Urteilen — hätten sich gegenseitig relativiert. Die Zeit-Erzählung war
ohnehin als Platzhalter angelegt; in ihrem eigenen Kopf stand: *„Die spätere
System-Erzählung mit Voraussetzungs-Kausalkette ersetzt diese Datei
vollständig."*

Die Eltern-Einschätzung ist nicht verschwunden, sondern an zwei bessere Stellen
gewandert: Schritt 01 als Anlass, Schritt 05 als Antwort.

### Farben: Navy/Gold/Creme statt Grün/Rot

Der HTML-Entwurf nutzt Ampelfarben. **INV-4.4 verbietet sie auf Elternflächen**
— *„Rot/Gelb/Grün tragen hier eine Wertung, die niemand belegt hat."*

Man hätte argumentieren können, dass die Begründung bei einem Trag-Urteil nicht
greift: Die Wertung IST belegt, das ist die Ausgabe der LSA. Rasit hat anders
entschieden, und das trägt weiter: Die Sprache des Reports vermeidet die harte
Wertung durchgehend („trägt noch nicht", nicht „Lücke"), und Rot hätte
zurückgeholt, was der Text sorgfältig vermeidet.

Folge: **App und HTML-Entwurf sehen unterschiedlich aus.** Bewusst.

## Wo INV-4.4 nachgezogen werden musste

Der Test prüfte `ReportTopicBar` — die Datei gibt es nicht mehr. Statt die
Zusicherung zu streichen, ist sie auf die Nachfolger übergegangen, und der
interessante Teil hat einen eigenen Test bekommen:

R3 verbot dem Themenbalken **jede** variable Breite: *„eine variable Breite ist
immer ein Maximum, auf das man zuläuft — also eine Skala von schlecht nach
gut."* Die Ebenenspur hat eine variable Breite und ist trotzdem keine Skala: Sie
zeigt, wie sich die geprüften Bereiche EINER Ebene aufteilen, und beide
Summanden stehen als Text daneben.

Damit das so bleibt, hält der Test jetzt fest, was den Unterschied ausmacht:

- genau **ein** `* 100` in der Datei, und es fließt in einen `style`-Wert
- `ebenen.zaehlung` wird gerendert und lautet wörtlich `{{traegt}} von {{geprueft}}`
- der Balken trägt `aria-hidden` — für Vorlesewerkzeuge reicht die Zahl

Dazu neu: das Profil darf keine Zahl an die Achsen schreiben.

## Beweis

- `npm run build && typecheck && lint && test` — **373 Tests grün** (30 Dateien).
- **Neu: `ReportBody.test.tsx`**, 9 Rendertests mit den Daten der echten Sitzung
  d8b0d885. Typecheck sagt nichts darüber, ob die Abschnitte erscheinen und die
  Bausteine an der richtigen Stelle landen — genau dort lag der Aufwand.
  Geprüft werden unter anderem: geglättete Anzeigenamen im Anlass, die
  Ebenenspur mit Untertiteln, eingesetzte Platzhalter, die Trennung von „nicht
  geprüft" und echtem Nullwert im Profil, kein roher Registry-Schlüssel im
  gesamten Dokument, und dass **jeder Abschnitt still entfällt**, wenn seine
  Daten fehlen.
- Die Fläche wurde zusätzlich statisch gerendert und mit dem gebauten CSS im
  Browser angesehen — Zwischenstand, keine Datei im Repo.

## Offen

1. **Die „0 von n"-Ausnahme beim Einbruch-Satz** (aus R5) — Tolunays „0 von 2"
   scheitert an der Drei-Bereiche-Regel und verstummt mit.
2. **Der Paketblock fehlt in der App.** Der HTML-Entwurf zeigt Paketname und
   Frequenz aus `tiers`; in der App wählt der Coach das Paket im Ausblick
   (`ReportOutlook` → `lsa_report_notes`). Beides zusammenzuführen ist eine
   eigene Entscheidung — die Empfehlungsregel würde sonst am Coach-Gate
   vorbeilaufen.
3. **Lint-Altlast in `scripts/`** (83 Fehler in Altskripten) — liegt schon auf
   `dev`, `npm run lint` deckt nur `src`.
