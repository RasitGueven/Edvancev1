# Bauauftrag LSA-T · Fünf Testkinder mit fertiger LSA und Report

Stand 22.10.2026. Anlass: Rasit möchte Reports für sehr verschiedene Kinder sehen, nicht nur Batu.
Fünf erfundene Kinder (Klasse 7, 8 und 9) durchlaufen die echte LSA-Auswahl und Wertung mit einem
festen Antwortprofil, von „sehr gut“ bis „sehr, sehr schwach“. Danach liegt für jedes Kind ein Report
in der Admin-Ansicht.

Wichtig: Das ist ein Werkzeug, kein einmaliger Lauf. Es soll nach LSA-V (neue Auswahl) und nach R7-11
(neuer Report) erneut laufen, damit man die Wirkung direkt an denselben fünf Kindern sieht.

## Die fünf Kinder (Phantasiedaten, nie echte Namen)

| Kind | Klasse | Schule | Thema der LSA | Profil | Anliegen im Erstgespräch | Was der Report zeigen soll |
| --- | --- | --- | --- | --- | --- | --- |
| Lina Berger | 9, Gymnasium | FWG (Schulplan) | Quadratische Funktionen | sehr gut: fast alles sicher, ein einzelner Ausrutscher in der Vorschau | fachlich: „Noten halten, Oberstufe vorbereiten“ | Fall „alles sicher“: Was sagt der Report, wenn es kaum etwas zu tun gibt? |
| Emre Kaya | 9, Gymnasium | FWG (Schulplan) | Reelle Zahlen und Wurzeln | gut mit einer Lücke im Thema: Grundlagen sicher, Wurzelgesetze und teilweise Wurzel ziehen falsch (immer dasselbe Fehlbild) | fachlich: „Klassenarbeit in drei Wochen“ | Ein klares Muster im Thema, Vorschau überwiegend sicher |
| Sophie Wagner | 8, Realschule | ohne Schulplan (Kernlehrplan) | Lineare Funktionen | schwach: Steigung falsch (vertauscht Δx und Δy), Koordinaten unsicher, Bruchrechnen sicher | fachlich + überfachlich: „Mathe-Note“, „Motivation“ | Mehrere Lücken, Abstieg bis Klasse 6 |
| Jonas Richter | 8, Gesamtschule | ohne Schulplan | Terme und Gleichungen | sehr, sehr schwach: fast nichts sicher, Fehler bis in Klasse 5/6 (Vorzeichen, Dezimalzahlen), oft „Weiß ich nicht“ | überfachlich: „Konzentration“, fachlich: „Versetzung gefährdet“ | Fall „nichts sicher“: Bleibt der Report ermutigend und konkret? |
| Nele Schmitz | 7, Gymnasium | ohne Schulplan | Prozent- und Zinsrechnung | gemischt: Prozentwert sicher, Grundwert und Prozentsatz falsch (rechnet in die falsche Richtung), Brüche teils | nur überfachlich: „Motivation“ | Anliegen ohne fachlichen Punkt, gemischter Befund |

Hat ein Thema für seine Einstiegsknoten weniger als 2 Aufgaben im Pool: STOPP für dieses Kind, ein anderes Thema derselben Klasse vorschlagen und im PR nennen.

## Prompt

```
Du arbeitest im Repo Edvancev1 (WSL). Paket LSA-T: ein wiederholbares Werkzeug, das fünf erfundene Testkinder anlegt und für jedes eine vollständige LSA mit festem Antwortprofil durch die ECHTE Auswahl und Wertung spielt. Danach hat jedes Kind einen Report unter /admin/report/<session>?fassung=r7. Ein Paket, ein PR.

Lies zuerst diesen Bauauftrag ganz (lege ihn als docs/lsa/Bauauftrag-LSA-T.md im PR ab), dann supabase/tests/lsa_l1_fixture.sql, s7_lead_lsa.test.sql, lsa_pool_testkonten.test.sql, die Migration 20261011140200_f1_lsa_pool_testkonten.sql und die RPCs, über die die App eine LSA startet, Aufgaben holt, Antworten bucht und abschließt.

## Entscheidungen (nicht neu verhandeln)

### A. Daten
1. Fünf Kinder wie in der Tabelle des Bauauftrags: Lead mit Erstgespräch (Klasse, Schulform, Schule oder keine, aktuelles Thema in lead_themen, zwei bis drei behandelte Themen passend zur Klasse, Anliegen, Interessenswelt), dazu ein Schülerdatensatz mit students.ist_test = true. Eltern-E-Mail immer <vorname>@example.invalid. Keine Verträge, keine Zahlungsdaten.
2. Feste UUIDs für Leads und Schüler (im Skript als Konstanten), damit ein zweiter Lauf dieselben Kinder findet. Ein zweiter Lauf legt NEUE LSA-Sitzungen an und löscht nichts (Rohdaten bleiben append-only). Die Ausgabe nennt immer die neueste Sitzung je Kind.
3. Pool: Testkonto-Pool (lsa_testinhalte = true), weil noch wenig auf „ready“ steht. Im Bericht des Laufs je Kind zusätzlich: wie viele der gezogenen Aufgaben schon „ready“ waren.

### B. Antwortprofil
4. Jedes Kind hat ein Profil als Daten im Skript (keine Zufallszahlen):
   - Grundstand je Klassenstufe (5/6, 7/8, 9/10): sicher | uebung | teilweise | nicht_angesetzt.
   - Ausnahmen je skill_key, die den Grundstand überschreiben.
   - Je Kind EINE Fehlbild-Familie, die es bei falschen Antworten bevorzugt (Emre: Wurzel einer Summe; Sophie: Steigung vertauscht; Jonas: Vorzeichen; Nele: Prozent in falscher Richtung).
   - Antwortdauer je Kind (Lina ca. 40 s, Emre 60 s, Sophie 80 s, Jonas 110 s, Nele 70 s), leicht variiert nach festem Muster.
5. Antworten:
   - sicher: die kanonisch richtige Antwort im verlangten Eingabeformat (LSA-Erlebnis L1).
   - uebung: eine falsche Antwort, die das Fehlbild der Familie des Kindes auslöst, wenn die Aufgabe eins dafür hat (aus task_solutions bzw. typical_errors mit fehlbild); sonst ein anderes hinterlegtes Fehlbild; sonst ein plausibel falscher Wert, der keiner richtigen Antwort gleicht.
   - teilweise: erste Aufgabe zum Skill richtig, Zweitbeleg falsch.
   - nicht_angesetzt: der Weg, den die App für „Weiß ich nicht“ nimmt.
6. Die Wertung macht ausschließlich die echte Logik. Das Skript bucht Antworten nur über dieselben RPCs wie die App und schreibt nie direkt in lsa_skill_urteil, lsa_responses oder result_summary.
7. Die Uhr wird simuliert, damit 19 Minuten Diagnosezeit realistisch abgedeckt sind (Antwortdauer aus dem Profil), ohne Wertung oder Auswahl zu umgehen. Wie (z. B. Zeitstempel der Sitzung zurücksetzen, p_jetzt), entscheidest du; beschreibe den Weg im PR und begründe, warum er die Auswahl nicht verfälscht.
8. Rechte: Läuft eine RPC nur mit angemeldetem Admin oder Coach, setze im Skript die Claims wie die bestehenden Tests (request.jwt.claims) auf ein bestehendes Admin-Profil. Kein service_role-Key im Code, kein Umgehen von RLS über neue Funktionen.
9. Abschluss wie in der App, sodass result_summary, Themenraum, Fehlbilder und Report entstehen.

### C. Form
10. Das Werkzeug ist reines SQL ohne DDL: tools/lsa-testkinder/erzeugen.sql (eine Transaktion, DO-Blöcke erlaubt, keine CREATE FUNCTION/TABLE). Bricht etwas, wird alles zurückgerollt.
11. Am Ende gibt das Skript eine Tabelle aus: Kind · Klasse · Thema · Sitzung · Aufgaben gesamt · davon ready · sicher · Übungsbedarf · Fehlbilder · Report-Pfad.
12. tools/lsa-testkinder/README.md: was es tut, wie man es startet, wie man es nach LSA-V und R7-11 erneut laufen lässt.
13. Test supabase/tests/lsa_testkinder.test.sql: läuft das Skript im CI-Neuaufbau und prüft je Kind, dass die Sitzung abgeschlossen ist, die Zustände in lsa_skill_urteil zum Profil passen (sicher, wo sicher vorgesehen, usw.) und Lina mindestens 80 % sicher, Jonas höchstens 20 % sicher hat.

## Testfälle, die der Report damit abdeckt
- alles sicher (Lina), Lücke im Thema mit Muster (Emre), mehrere Lücken mit Abstieg (Sophie), nichts sicher (Jonas), gemischt ohne fachliches Anliegen (Nele)
- mit Schulplan (Lina, Emre) und ohne (Sophie, Jonas, Nele)
- Klassen 7, 8 und 9

## Umfang
- tools/lsa-testkinder/erzeugen.sql, tools/lsa-testkinder/README.md
- supabase/tests/lsa_testkinder.test.sql
- docs/lsa/Bauauftrag-LSA-T.md, docs/lsa/offene-punkte-lsa-t.md, Retro
- Nicht anfassen: supabase/migrations/**, lsa_select_next_core und jede andere Funktion, src/**, Report, Präsentation. Läuft LSA-V parallel in einem anderen Worktree: dort nichts anfassen.

## Leitplanken
- Worktree ../Edvancev1-lsat auf feat/rasit-lsa-testkinder von origin/dev. PR gegen dev, nie main.
- Kein DDL. Prod nur lesend über dbread (z. B. um Themen, Pool und Fehlbilder zu prüfen). Das Skript auf Prod startet Rasit selbst.
- Im PR steht der Startbefehl für Rasit, &&-verkettet:
  dbcheck && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f tools/lsa-testkinder/erzeugen.sql
- Keine echten Namen, keine echten Schulen außer dem FWG-Plan, der schon in der Datenbank steht.
- STOPP nach dem PR.

## Melden
- PR-Link und Startbefehl
- Die Ausgabetabelle aus dem CI-Lauf
- Je Kind die gewählten Themen (aktuell und behandelt), Profil und welche Fehlbilder ausgelöst wurden
- offene Punkte (Themen ohne genug Aufgaben, Fehlbild-Familien ohne passende Aufgabe)
```

## Ablauf mit den anderen Aufträgen
1. LSA-T kann sofort parallel zu LSA-V und R7-11 gebaut werden.
2. Erster Lauf auf Prod: nach dem Einspielen von LSA-V. Davor würde er die alte, beliebige Breite zeigen.
3. Danach die fünf Reports im Admin ansehen, mit der alten Fassung des Reports.
4. Nach dem Merge von R7-11: dieselben fünf Reports erneut öffnen (der Report rechnet beim Öffnen neu, ein neuer Lauf ist dafür nicht nötig) und vergleichen.
