# Konzept · Session-Ablauf und Session-Aufgaben

**Für:** Rasit, Tolunay, Ashkan, Lena · **Stand:** 27.10.2026, nachgezogen am Nachmittag (Quest-Tage entfallen, Warm-up ohne Hinweise, Bauformen) · **Dummy:** `claude/session-flow-dummy.html` (21.10.), `claude/schueler-app-dummy.html` (27.10.)
**Grundlage:** Session-Rahmen A2 (`session_naechster_schritt`, Entscheidungen A–H vom 06.10.), E1/E2a (Erklärsequenz), Gespräch Rasit 21.10. (Skelett und Varianten, Phasen, Modi), Anforderung Themenbaum, Anforderung Studio (27.10.)

**Leitplanken, die überall gelten**
- Das System schlägt vor, der Coach entscheidet. „Gemeistert“ gibt es nur nach Bestätigung durch den Coach vor Ort.
- Der Lernpfad bewegt sich nur in der Session vor Ort (FernUSG). Zuhause wird nur „erledigt“ gespeichert.
- Ein Beleg zählt nur, wenn die Aufgabe beim ersten Versuch und ohne Hinweis richtig gelöst ist (A2 H).
- Session-Aufgaben sind eigene Aufgaben. LSA-Aufgaben kommen in Sessions nicht vor, damit der LSA-Pool für die Re-LSA unverbraucht bleibt. Eine Aufgabe gehört genau einem Pool an; die Datenbank erzwingt das.
- Session-Aufgaben entstehen aus Bauformen. Lena prüft die Bauform, nicht jede einzelne Aufgabe. Einzelheiten: `Konzept-Sessionreihe-1-und-Bauformen.md`.

## 1 · Die Stunde (60 Minuten)

| Minute | Wer | Was |
|---|---|---|
| 0–5 | Coach | Ankommen, Platz zuweisen, Check-in: Wie lief die Woche, steht eine Klassenarbeit an? Der Coach bestätigt den Fall (Klassenarbeit, Schulthema, Lernfahrt) oder ändert ihn. |
| 5–50 | Kind am Tablet | Phasen aus Abschnitt 3; der Coach geht herum, reagiert auf Signale, führt Prüfgespräche für „gemeistert“ |
| 50–55 | Kind am Tablet | Check-out: was heute geschafft, Themenbaum, „Zuhause weiterüben“ (keine Quest-Tage, Quests sind jederzeit möglich) |
| 55–60 | Coach | Abschlusssatz je Kind, kurze Notiz für die Übergabe, Platz frei |

Die Tablet-Zeit von rund 45 Minuten ist der Rahmen. Die Uhr der Session bestimmt die Phase (A2 C). Wer später ein Tablet bekommt, steigt in der Kernarbeit ein.

## 2 · Worauf die Stunde zielt (Modi)

Der Fall kommt aus dem Check-in (A2 D), in dieser Rangfolge:

| Modus | Wann | Ziel der Stunde |
|---|---|---|
| **Klassenarbeit** | Eine Arbeit ist angekündigt. | Skills des Arbeitsthemas, Voraussetzungen zuerst. In der letzten Session vor der Arbeit: Generalprobe (Abschnitt 4). |
| **Schulthema** | Keine Arbeit in Sicht, aber ein laufendes Thema. | Skills des aktuellen Schulthemas, Voraussetzungen zuerst. |
| **Lernfahrt** | Schulthema sitzt oder ist unbekannt. | Die nächste Lücke im Kompetenzgraphen, bevorzugt Voraussetzungen der kommenden Klassenarbeiten (roter Faden aus dem Eltern-Bericht v4). |

In allen Modi gilt: **Erst der Boden, dann das Haus.** Fällt im Warm-up oder in der Kernarbeit eine Voraussetzung durch, schlägt das System dem Coach „eine Stufe tiefer“ vor (`pfad_tiefer`). Bestätigt er, wird zuerst die Voraussetzung gefestigt.

## 3 · Die Phasen am Tablet

| Phase | Minuten (Startwert) | Kommt wann | Aufgaben | Hinweise | Zählt als Beleg |
|---|---|---|---|---|---|
| Warm-up | 5 | immer | 3–4 Aufgaben AFB 1: fällige Abrufe aus früheren Sessions und Voraussetzungen des Ziels, eine Stufe leichter | nein (Entscheidung 07.10.) | ja, für den jeweiligen Skill |
| Erklärsequenz | 4–8 | nur bei neuem Skill (keine Belege) und freigegebenem Video oder Karten | Video oder Karten je Kernidee, dazu 2–3 Mini-Checks mit Rücksprung | nein, stattdessen Rücksprung | nein (Einstieg) |
| Geführt | 8–10 | neuer Skill, bis eine Aufgabe ohne Hinweis sitzt | Lösungsbeispiel zum Aufdecken mit Selbsterklärung, dann eine ähnliche Aufgabe | ja, gestuft | ja |
| Selbstständig | 10–15 | danach | Übungen AFB 1–2, Schwierigkeit 1–5 regelt sich über die Zielquote (A2 H), ab und zu eine eingemischte Aufgabe eines früheren Skills | ja | ja |
| Transfer | 5–8 | wenn der Skill auf Schwierigkeit 3 oder höher sitzt | AFB 3: begründen, Fehler finden, Sachaufgabe, zwei Wege vergleichen | ja, nur Stufe 1 | ja, als Transferbeleg |
| Recap | 3–5 | letzte Minuten vor dem Check-out | 2–3 Verständnisfragen zu den Skills der Stunde | nein | nein, Hinweis an den Coach |

**Feinheiten**
- **Warm-up ist Diagnose, nicht Einstieg.** Es prüft, was sitzen müsste. Der Einstieg ins neue Thema sind die Mini-Checks der Erklärsequenz.
- **Lösungsbeispiel mit Selbsterklärung.** Das Kind deckt Schritt für Schritt auf. Bei einem Schritt fragt die App: „Warum ist das richtig?“, und das Kind wählt einen von drei Begründungsbausteinen. Danach kommt eine ähnliche Aufgabe. Ein gezeigtes Beispiel bekommt das Kind nie als Aufgabe (A2 F).
- **Hinweisstufen.** Stufe 1 ist ein Denkanstoß als Frage, Stufe 2 die Strategie oder ein Teilschritt, Stufe 3 der erste Rechenschritt, nie die Lösung. Nach Stufe 3 bekommt der Coach ein Signal.
- **Rückmeldung je Fehlbild.** Bei einer falschen Antwort nennt die App den Denkfehler („Du hast die Hälfte genommen“), nicht die Lösung. Danach kommt ein zweiter Versuch.
- **Mehrere Skills in einer Stunde.** Sitzt ein Skill (Zielquote erreicht, Transfer gelöst), geht es zum nächsten Skill des Ziels, beginnend mit Erklärsequenz oder Geführt. Der Recap deckt alle Skills der Stunde ab.
- **Kandidat für „gemeistert“.** Hat ein Skill genug Belege einschließlich Transfer, markiert das System ihn für den Coach. Der Coach führt das Prüfgespräch vor Ort (Abschnitt 5, Coach-Prüffrage). Kommen mehrere Kandidaten zugleich, sortiert das Dashboard sie nach Wartezeit.

## 4 · Generalprobe (Modus Klassenarbeit)

- **Wann:** in der letzten Session vor dem Datum der Arbeit, sonst auf Wunsch des Coaches.
- **Was:** rund 20–25 Minuten mit gemischten Aufgaben aus dem Arbeitsthema im Format der Arbeit, AFB 1–3, ohne Hinweise und ohne Rückmeldung bis zum Ende (höchstens acht Skills, die schwächsten zuerst; Regeln im Konzept Sessionreihe 1 §2.5).
- **Danach:** Übersicht „sicher / noch üben“ je Skill. Ein Tipp auf „noch üben“ führt in eine kurze Übungsrunde zu genau diesem Skill.
- **Belege:** Es zählt wie normale Session-Arbeit, weil es vor Ort stattfindet.
- **Für die Eltern:** keine Note, keine Prognose. Im Monatsbericht steht höchstens „Generalprobe vor der Arbeit gemacht“.

## 5 · Was eine gute Session-Aufgabe ausmacht

**Inhaltspaket je Skill** (Skelett, von Lena geprüft; Varianten tauschen nur Text und Bild):

| Baustein | Menge | AFB | Wofür |
|---|---|---|---|
| Erklärsequenz (Studio) mit Mini-Checks | 1 Sequenz, 2–3 Checks | 1 | Einstieg |
| Lösungsbeispiele mit Selbsterklärung | 2 | 1–2 | Geführt |
| Übungsaufgaben | 10–12, über Schwierigkeit 1–5 verteilt (mindestens 2 je Stufe) | 1–2 | Selbstständig |
| Transferaufgaben | 3 | 3 | Transfer |
| Recap-Fragen | 2 | 2 | Recap |
| Coach-Prüffragen (mündlich) | 1–2 | 2–3 | „gemeistert“ |
| Home-Quest-Aufgaben | aus denselben Bauformen, Rolle home, Stufe 1–3 | 1–2 | Zuhause, nur „erledigt“ |

Jede Aufgabe hat drei Hinweisstufen, eine Rückmeldung je erwartetem Fehlbild und einen Lösungsweg für den Coach. Für das Warm-up braucht es keinen eigenen Inhalt, es greift auf die Übungen der Voraussetzungen zu.

**Prüfliste für Autor und Lena**
1. **Ein Skill je Aufgabe.** Ausnahme sind Transfer und Generalprobe.
2. **Falsche Antworten sind echte Fehlbilder** aus dem Katalog, keine Zufallszahlen. Die Zahlen sind so gewählt, dass jedes Fehlbild eine andere Antwort ergibt.
3. **Kein Hinweis verrät die Lösung**, auch Stufe 3 nicht.
4. **Die Rückmeldung nennt den Denkfehler**, nicht das Ergebnis.
5. **Kurze Sätze**, ein Gedanke je Satz, Fachwörter wie in der Schule, keine Verständnisfalle in der Sprache.
6. **Bearbeitungszeit:** Übung 1–3 Minuten, Transfer 3–6 Minuten.
7. **Der Kontext der Interessenswelt verändert die Mathematik nicht.** Ein Fußballfeld ist nicht quadratisch. Die Zahlen sind gesperrt.
8. **Automatisch auswertbar.** Freitext gibt es nur als Notiz für den Coach, nie als Beleg.

## 6 · Aufgabenformate

| Format | Gibt es | Gut für | Auswertung |
|---|---|---|---|
| Multiple Choice | ja | Mini-Check, Recap, Übung | automatisch, Fehlbild je Option |
| Zahl | ja | Übung | automatisch |
| Bruch | ja | Übung | automatisch, nach Wert |
| Term (`ax+b`) | ja | Übung | automatisch |
| Mehrteiler | ja | Übung, Generalprobe | automatisch je Teil |
| Tabelle | ja (Lena-Board) | Übung, Funktionen | automatisch je Zelle |
| Bereich | ja (Lena-Board) | Schätzen, Ablesen | automatisch |
| **Fehler finden** | neu | Transfer, Recap | das Kind tippt die falsche Zeile einer Rechnung an, dann gibt es eine MC zum Warum |
| **Begründungsbausteine** | neu | Transfer, Selbsterklärung | Auswahl aus 3–4 Bausteinen, eine richtige Kombination |
| **Schritte ordnen** | neu | Geführt, Transfer | richtige Reihenfolge |
| Punkt oder Graph setzen | später | Funktionen | Toleranz |
| Freitext | nur Coach-Notiz | – | kein Beleg |

Mit den drei neuen Formaten ist AFB 3 auswertbar, ohne Freitext und ohne Sprachmodell.

## 7 · Beispiel: ein Skill durchgespielt

**Skill „Teilweise die Wurzel ziehen“**, Klasse 9, Thema Reelle Zahlen und Wurzeln, Welt Fußball (wie im Session-Flow-Dummy)

| Phase | Aufgabe | Richtig | Fehlbilder als Antwortoptionen |
|---|---|---|---|
| Warm-up | Welche ist die größte Quadratzahl, die 72 teilt? | 36 | 4 (nicht die größte), 9 |
| Warm-up | √81 = ? | 9 | 40,5 (Hälfte) |
| Mini-Check | √12 = ? | 2√3 | 4√3 (Wurzel aus dem Quadratfaktor vergessen) → Rücksprung „Wurzel aus 4 ziehen“; 2 + √3 (Produkt zu Summe) → Rücksprung „Produktregel“; 6 (Hälfte) |
| Lösungsbeispiel | √72 = √(36 · 2) = 6√2 | Selbsterklärung: „Warum 36 und nicht 4?“ → „Die größte Quadratzahl, sonst muss man weiter vereinfachen.“ | – |
| Übung S1–S5 | √18, √50, √75, √200, √0,08 | 3√2, 5√2, 5√3, 10√2, 0,2√2 | je Aufgabe 2–3 Fehlbilder |
| Transfer | Lea rechnet √48 = √(4 · 12) = 2√12. Ist sie fertig? | „Nein, 12 enthält noch die Quadratzahl 4.“ → 4√3 (Fehler finden plus Baustein) | „Ja, die Wurzel ist gezogen.“ |
| Transfer | Ein quadratisches Trainingsfeld hat 50 m² Fläche. Gib die Seitenlänge exakt an. | 5√2 m | 25 m (Hälfte), 7,07 m (gerundet statt exakt) |
| Recap | Stimmt: √(a · b) = √a · √b (für a, b ≥ 0)? | wahr | – |
| Recap | Stimmt: √(a + b) = √a + √b? | falsch, Gegenbeispiel √(9 + 16) = 5 ≠ 7 | Begründung als Baustein |
| Coach-Prüffrage | „Erklär mir, warum man bei √72 die 36 sucht und nicht die 4.“ | – | – |

## 8 · Mengengerüst für den Soft Launch (April bis Juni 2027)

**Vorgehen:**
1. Aus den 34 Schulplänen die Themen der Klassen 8–10 ermitteln, die zwischen den Oster- und den Sommerferien laufen. Dazu deren Voraussetzungen aus dem Kompetenzgraphen.
2. Die Skills nach Häufigkeit über die Schulen sortieren. Die ersten 15–20 Ziel-Skills bekommen das volle Paket. Voraussetzungen bekommen nur Übungen und Hinweise, ohne Video und Transfer.

**Größenordnung:**
- 15–20 volle Pakete ergeben rund 300–400 Skelettaufgaben und 15–20 Videos.
- Dazu kommen Übungen für etwa 20–30 Voraussetzungs-Skills.
- Je Skelett kommen die Varianten der Welten hinzu, als reine Textprüfung.

**Herstellung über Bauformen** (ersetzt das Einzelprüfen, Entscheidung 27.10.):
1. Ein Claude-Code-Agent schreibt Bauform und Generator.
2. Die Prüfmaschine kontrolliert jede erzeugte Aufgabe, ein frischer Blindlöser jede Bauform (nie der erzeugende Agent).
3. Lena prüft im Board die Bauform mit sechs Beispielen. Erzeugte Aufgaben übernehmen ihre Prüfung, solange die Prüfmaschine grün ist.
4. Im Einsatz fängt die Bewährung auf, was durchrutscht (Melde-Knopf, Auswertung der Antworten).

**Zeitplan:**
- Inhalte fertig bis Mitte März 2027.
- Im Februar und März laufen die LSAs mit Interessenten. Dafür müssen die Session-Inhalte noch nicht stehen.

**Ausstattung:** Kopfhörer für jeden Platz (Videos laufen mit Ton), Untertitel als Schalter.

## 9 · Offene Entscheidungen

1. **Zeitbudgets:** Passen die Startwerte der Phasen? Fatih justiert nach dem ersten Testlauf.
2. **Generalprobe:** nur in der letzten Session vor der Arbeit oder auch früher?
3. **Recap:** Soll er eine kurze Selbsteinschätzung enthalten („Wie sicher fühlst du dich?“), die der Coach neben dem Ergebnis sieht?
4. **Transfer:** Erst ab Schwierigkeit 3 oder schon früher, wenn das Kind schnell ist?
5. **Neue Formate:** Reihenfolge Fehler finden → Begründungsbausteine → Schritte ordnen in Ordnung?
6. ~~Home-Quest-Pool~~ entschieden 27.10.: Home Quests kommen aus denselben Bauformen (Rolle home, Stufe 1–3).
7. **Lenas Zeit:** Lena arbeitet bis zum Launch auf Honorar, prüft Inhalte, leitet im Soft Launch Sessions und arbeitet didaktisch am Konzept mit (Entscheidung 27.10.). Mit Bauformen prüft sie je Reihe rund 45 Bauformen, 15 Prüffragen und 8 Videos (etwa 6–8 Stunden) statt 300–400 Einzelaufgaben.
