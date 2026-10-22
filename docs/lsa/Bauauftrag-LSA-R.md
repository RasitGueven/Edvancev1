# Bauauftrag LSA-R · Durchklicken erkennen: Schritt 1 Auswertung

Stand 22.10.2026. Anlass: Tolunay hat eine LSA mit 70 Aufgaben zufällig beantwortet, fast alles falsch.
Der Report sagt dann „Übungsbedarf bis Klasse 5“. Das stimmt nicht: Das Kind hat nicht mitgemacht.
Vor Eltern ist so ein Report gefährlich.

Dieser Auftrag hat zwei Schritte. **Schritt 1** misst nur und schlägt Schwellen vor; danach STOPP.
Erst wenn Rasit die Schwellen bestätigt, folgt Schritt 2 (Bau) als eigener Auftrag.

## Vorschlag Rasit/Claude (wird in Schritt 1 gegen echte Daten geprüft)

- „Schnell falsch“: eine falsche Antwort (correct = false) mit duration_ms unter **8 s**.
- **Nicht auswertbar**: mindestens **5 schnelle falsche in Folge** ODER mindestens **40 %** aller Antworten schnell falsch (ab 10 Antworten).
- **Deckel**: höchstens **40 Aufgaben** je LSA. Normales Tempo erreicht das in 19 Minuten nicht.
- **Während der LSA**: Nach 3 schnellen falschen Antworten in Folge erscheint ein ruhiger Hinweis für das Kind, einmal je LSA. Der Coach sieht im Live-Bild eine Markierung.
- **Danach**: Der Report einer nicht auswertbaren LSA lässt sich nicht als Präsentation öffnen. Auf dem Bogen stehen statt der Seiten 2–4 ein sachlicher Hinweis und „LSA wiederholen“.

## Prompt (Schritt 1)

```
Du arbeitest im Repo Edvancev1 (WSL). Paket LSA-R, SCHRITT 1 – nur Auswertung, kein Bau: Wir wollen erkennen, wenn ein Kind eine LSA durchklickt (schnell und falsch), und schlagen dafür Schwellen vor. Lies diesen Bauauftrag ganz und lege ihn als docs/lsa/Bauauftrag-LSA-R.md ab. Lies supabase/schema-erwartet.sql zu lsa_responses (duration_ms, abgabeart, correct), lsa_sessions (testlauf, status) und students.ist_test, die Funktionen lsa_submit und lsa_select_next_core (wo das Ende einer LSA entschieden wird) und tools/lsa-testkinder/erzeugen.sql.

## Auswertung (Prod nur lesend über dbread, Ergebnisse ohne Namen, ohne IDs von Kindern)
1. Je abgeschlossene LSA (status completed), getrennt nach echte Kinder / Testkonto / Testlauf:
   - Aufgaben gesamt
   - Median, 10. und 90. Perzentil von duration_ms getrennt für richtig, falsch und „Weiß ich nicht“
   - Anteil „schnell falsch“ bei 5, 8 und 12 s
   - längste Folge „schnell falsch“ bei 5, 8 und 12 s
2. Über alle echten Kinder: Verteilung der Antwortzeiten je input_type (MC, Zahl, Term usw.). Unter welcher Zeit antwortet praktisch niemand richtig? Das ist die Grenze, ab der Raten wahrscheinlich ist.
3. Die Kombinationen aus Schwelle (5/8/12 s) und Regel (3, 4 oder 5 in Folge; 30/40/50 %) als Tabelle: Wie viele echte LSAs würden als nicht auswertbar markiert? Wie viele Testkonto-LSAs? Tolunays 70-Aufgaben-LSA muss markiert werden. Die Testkinder Lina, Emre, Sophie, Nele, Max dürfen nicht markiert werden. Bei Jonas (sehr schwach, langsam, oft „Weiß ich nicht“) ebenfalls nicht.
4. Tolunays LSA (die mit den meisten Aufgaben unter den Testkonten der letzten Tage) im Detail: Zeitverlauf der Antworten, ab welcher Aufgabe die Regel greifen würde.
5. Wie viele Aufgaben haben echte Kinder höchstens? Passt der Deckel von 40, oder braucht es einen anderen Wert?
6. Wo im Code entsteht das Ende einer LSA, und wo würde der Deckel greifen? Wo stünde die Markierung „nicht auswertbar“ am besten (Spalte an lsa_sessions oder Teil von result_summary)? Begründe es kurz, aber schreib keine Migration.

## Melden (Bericht als docs/lsa/durchklicken-auswertung.md im PR)
- Die Tabellen aus 1–5
- Empfehlung: Schwelle, Regel und Deckel, mit der Zahl der Fehlalarme bei echten Kindern
- Vorschlag für Schritt 2: welche Dateien in Edvancev1 (Migration, Report, Präsentation, Coach-Live-Bild) und welche in edvance-app (Hinweis für das Kind), jeweils mit grobem Umfang
- Offene Fragen an Rasit

## Leitplanken
- Worktree ../Edvancev1-lsar auf docs/rasit-lsa-durchklicken von origin/dev. PR nur mit Doku, gegen dev.
- Kein DDL, keine Migration, keine Codeänderung. Prod nur lesend über dbread.
- Keine echten Namen, keine Antworttexte, keine Zeitstempel oder IDs echter Kinder im Repo (das Repo ist öffentlich). Zahlen nur aggregiert.
- STOPP nach dem PR.
```

## Danach (Schritt 2, nach Rasits Bestätigung)
Bauauftrag mit den festgelegten Schwellen. Er umfasst: Markierung und Deckel in der Datenbank,
Report und Präsentation für nicht auswertbare LSAs, Markierung im Coach-Live-Bild und den Hinweis in der
Kinder-App (edvance-app, eigener PR).
