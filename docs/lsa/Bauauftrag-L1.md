Du arbeitest im Repo Edvancev1 (WSL). Paket L1: Lenas Rückmeldungen zu den freigegebenen LSA-Aufgaben auswerten, die nötigen Änderungen umsetzen und jede Rückfrage beantworten.

FREIGABE RASIT (25.10.2026, gilt nur für diesen Auftrag): Du spielst deine Daten-Migration selbst gegen Prod ein (Muster CLAUDE.md §10, eine &&-Kette, Nachweis per dbread danach) und merged selbst über PR nach dev (nie Push auf dev oder main, nie Force-Push). Du beantwortest Lenas Rückfragen im System als Rasit (siehe Schritt 4).

## Schritt 0 · Lesen
- CLAUDE.md, neueste Retro, docs/lsa/lena-reihenfolge-vorschau.md, docs/lsa/freigabeliste-vorschau.md.
- Datenmodell der Prüfung: supabase/migrations/20261005071058_pruefung_basis.sql (task_pruefungen: entscheidung, gruende, notiz, aenderungen, antwort; task_pruefung_ausgang), 20261005071649_pruefung_funktionen_e.sql (pruef_rueckfrage_klaeren), 20261022080744_p3_vorschau_pruefen.sql (pruef_board, Anlässe).
- Format der Lösungen und Fehlbilder: acceptance (inkl. known_errors, A12), typical_errors, correct_answers; Migrationen a10 (Akzeptanz und Scoring), A11/A12, af4 (Fehlbild-Familien). Wie sie in bestehenden Content-Migrationen geschrieben werden (z. B. k8_binomische_formeln), übernimmst du genau.

## Schritt 1 · Bestand per dbread (nur lesend)
1. Zahl der freigegebenen Aufgaben (status, wie das Lena-Board sie zählt) und Abgleich mit Rasits Zahl 123. Weicht es ab: nennen, weiterarbeiten.
2. Alle Prüfprotokolle mit Rückmeldung: letzte Zeile je Aufgabe aus task_pruefungen mit notiz oder gruende ≠ '{}' oder entscheidung in ('unsicher','passt_nicht'), dazu antwort/beantwortet_am. Erwartet: 11 Aufgaben. Je Aufgabe: task_id, skill_key, Kurztitel, Entscheidung, Gründe, Notiz, Änderungen (aenderungen), Status jetzt.
3. Je dieser Aufgaben den vollständigen Inhalt: Aufgabentext, Assets, input_type, correct_answers, acceptance (inkl. known_errors), typical_errors, Hinweise, Musterlösung.

## Schritt 2 · Auswertung (docs/lsa/lena-rueckmeldungen-2026-10-25.md, ohne Personennamen außer „Lena“)
Je Rückmeldung eine Zeile in einer Tabelle:
| Aufgabe (skill_key · Kurztitel) | Was Lena schreibt (wörtlich) | Art | Vorschlag | Umsetzen? |
Art ist genau eine von:
- Fehlbild fehlt (eine typische falsche Antwort soll als known_error mit Fehlbild erkannt werden)
- weitere richtige Antwort fehlt (Akzeptanz zu eng, z. B. andere Schreibweise, Bruch statt Dezimal, Einheit)
- Text/Darstellung (Formulierung, Umbruch, Einheit, abgeschnittener Text)
- Fachlich falsch (Lösung oder Aufgabe stimmt nicht)
- Rückfrage ohne Änderungsbedarf (nur Antwort)
Für „Fehlbild fehlt“: rechne die falsche Antwort selbst nach (welcher Fehler führt genau zu diesem Wert?) und ordne sie einem vorhandenen Fehlbild bzw. einer Familie zu (af4). Kein neues Fehlbild erfinden, wenn ein vorhandenes passt. Gibt es keins: neues mit Klartext für Eltern und Coach nach dem Muster der vorhandenen, als „neu“ markieren.
Für „weitere richtige Antwort“: Akzeptanz erweitern, dabei prüfen, dass keine falsche Antwort dadurch richtig wird (Gegenbeispiele nennen).
Zusätzlich, ohne dass Lena es geschrieben hat: Prüfe alle 123 freigegebenen Aufgaben auf zwei Dinge und liste Treffer getrennt (nicht automatisch ändern):
- Aufgaben, bei denen das Ergebnis mit erlaubtem Taschenrechner ohne die geprüfte Methode erreichbar ist (Beispiel 47² − 43²).
- Aufgaben ohne einen einzigen known_error.

## Schritt 3 · Umsetzen
1. Alles mit „Umsetzen = ja“ in EINER Daten-Migration supabase/migrations/<V>_lena_rueckmeldungen_1025.sql (Version sekundengenau), idempotent, je Aufgabe über die task_id, mit Kommentar je Block (Lenas Notiz in einer Zeile, was geändert wird). Rollback unter supabase/rollback/ mit den alten Werten.
2. Vorher klären und im PR beschreiben: Was passiert mit dem Prüfstand einer freigegebenen Aufgabe, wenn acceptance/known_errors/typical_errors/Text sich ändern (tasks_pruef_version, task_solutions_pruef_version, „geaendert ↺“ im Board)? Ziel: Lena sieht im Board, was nach ihrer Rückmeldung geändert wurde (vorher → nachher). Der Status „freigegeben“ bleibt bei reinen Ergänzungen von known_errors und Akzeptanz. Wird eine Aufgabe fachlich geändert (Lösung, Aufgabentext), geht sie zurück an Lena (ihr Status wie bei jeder geänderten Aufgabe); das ist gewollt.
3. Tests: pgTAP bzw. vorhandene Prüfskripte (tools/verify-tasks.mjs o. ä.) für jede geänderte Aufgabe: richtige Antwort(en) voll, jede neue falsche Antwort ergibt das erwartete Fehlbild, die Gegenbeispiele bleiben falsch. lsa_grade direkt aufrufen, wie in A11 verifiziert.
4. Zweitprüfung durch einen frischen Subagenten: rechnet jede geänderte Aufgabe blind nach (ohne die Migration zu kennen: Aufgabe → eigene Lösung → eigene typische Fehler) und vergleicht mit der Migration. Tabelle „Aufgabe | geändert | blind gerechnet | ok?“ im PR.
5. Migration einspielen (Muster CLAUDE.md §10), per dbread nachweisen, Schema-Snapshot nur falls nötig.

## Schritt 4 · Lenas Rückfragen beantworten
Für jede der 11 Rückmeldungen eine Antwort in der Sprache, die Lena versteht (kurz, freundlich, konkret: was geändert wurde bzw. warum nicht). Eintragen über pruef_rueckfrage_klaeren, als Rasit:
- Rasits profiles.id per dbread (Rolle admin, E-Mail rasit@edvanceacademy.de).
- Aufruf in einer Transaktion mit gesetztem JWT-Claim wie in den Tests (request.jwt.claim.sub = Rasits id, Rolle authenticated), damit beantwortet_von stimmt. Kein direktes UPDATE auf task_pruefungen.
- Die Antworten vorher in der Auswertungsdatei aus Schritt 2 als Spalte „Antwort an Lena“.

## Schritt 5 · PR und Merge
PR gegen dev mit: Auswertungstabelle, Migration, Prüfstand-Verhalten, Testergebnis, Zweitprüfung, eingetragene Antworten. gh pr checks --watch (nur session_a2 rot = bekannt, vermerken), gh pr merge --merge. Retro docs/retros/2026-10-25-lena-rueckmeldungen.md.

## Leitplanken
- Worktree ../Edvancev1-l1 auf feat/rasit-lena-rueckmeldungen-1025 von origin/dev.
- Nur die 11 Aufgaben ändern; die Treffer aus der Zusatzprüfung nur auflisten.
- Kein Schreiben gegen Prod außer der einen Migration und den 11 Antworten über pruef_rueckfrage_klaeren.
- Keine Schülerdaten im Repo. Dateien ≤ 400 Zeilen.

## Melden
PR-Link, Tabelle der 11 Rückmeldungen mit Art, Änderung und Antwort, Ergebnis der Zweitprüfung, die Liste „mit Taschenrechner lösbar“ und „ohne known_error“, offene Punkte.
