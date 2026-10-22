# Bauauftrag LSA-T2 · Sechstes Testkind: macht nichts falsch

Stand 22.10.2026. Anlass: Rasit möchte sehen, was LSA und Report zeigen, wenn ein Kind wirklich alles
richtig beantwortet. Lina hat absichtlich einen Ausrutscher, das ist also ein anderer Fall.
Nebennutzen: Jede Aufgabe, deren richtige Antwort die Wertung nicht annimmt, fällt dabei auf. Das ist
ein Inhaltsfehler für Lena.

## Prompt

```
Du arbeitest im Repo Edvancev1 (WSL). Paket LSA-T2: ein sechstes Testkind im Werkzeug tools/lsa-testkinder (aus LSA-T, PR #298), das jede Aufgabe richtig beantwortet. Dazu ein Schalter, um nur einzelne Kinder laufen zu lassen. Lies zuerst tools/lsa-testkinder/README.md, tools/lsa-testkinder/erzeugen.sql, supabase/tests/lsa_testkinder.test.sql und docs/lsa/Bauauftrag-LSA-T.md. Lege diesen Bauauftrag als docs/lsa/Bauauftrag-LSA-T2.md im PR ab.

## Entscheidungen (nicht neu verhandeln)
1. Neues Kind in lsat.kinder (Phantasiedaten):
   - kind "Max", name "Max Hoffmann", lead a5a7c41d-1ead-4000-8000-000000000006, schueler a5a7c41d-5c00-4000-8000-000000000006
   - Klasse 8, Gymnasium, Schule Friedrich-Wilhelm-Gymnasium, wenn es dort einen Schulplan für Klasse 8 gibt (prüf per dbread). Sonst ohne Schule, quelle_behandelt "gespraech".
   - Thema lineare_funktionen. Behandelt: drei Themen passend zu Klasse 8 wie bei Sophie.
   - anliegen ["Rechenwege"], notiz "Möchte gefordert werden, langweilt sich im Unterricht.", goal GENERAL, letzte_note "1-", trend stabil, interessen "Schach, Programmieren"
   - grund {"56": "sicher", "78": "sicher", "910": "sicher"}, keine ausnahmen, familie null, fehlbilder [], sekunden 35
   - E-Mail max@example.invalid wie bei den anderen
2. „Nichts falsch“ heißt: Jede gezogene Aufgabe, auch Vorschau, Rückblick und Zweitbeleg, bekommt die kanonisch richtige Antwort im verlangten Format. Kein „Weiß ich nicht“, keine Teilantwort.
3. Abweichungen: Nimmt die Wertung eine kanonisch richtige Antwort nicht als richtig an, bricht der Lauf NICHT ab. Er meldet je Fall eine NOTICE mit task_id, skill_key, input_type und der gesendeten Antwort, ohne Kindername. Am Ende gibt er für Max zusätzlich die Liste dieser Aufgaben aus („richtig beantwortet, nicht angenommen“). Diese Liste ist ein Arbeitsauftrag für Lena.
4. Schalter: Mit psql -v nur=Max (oder einer Komma-Liste, z. B. nur=Max,Lina) laufen nur diese Kinder. Ohne -v nur laufen alle sechs wie bisher. Unbekannte Namen: Abbruch mit klarer Meldung. Die Ausgabetabelle zeigt nur die gelaufenen Kinder.
5. Sonst gilt alles aus LSA-T unverändert: echte RPCs, keine direkten Schreibzugriffe auf Wertungstabellen, simulierte Uhr, Testkonto-Pool, kein DDL, append-only.

## Umfang
- tools/lsa-testkinder/erzeugen.sql, tools/lsa-testkinder/README.md (sechstes Kind, Schalter, Startbefehl)
- supabase/tests/lsa_testkinder.test.sql
- docs/lsa/Bauauftrag-LSA-T2.md, Retro
- Nicht anfassen: supabase/migrations/**, Funktionen, src/**

## Tests (CI-Neuaufbau)
- Max: Sitzung abgeschlossen, 100 % der gewerteten Skills sicher, 0 Übungsbedarf, 0 nicht angesetzt.
- Max: Die Liste aus Entscheidung 3 ist im Neuaufbau leer, denn dort sind die Lösungen konsistent. Ist sie es nicht, schlägt der Test fehl.
- Max: Die LSA endet über leere Auswahl oder über die Zeit. Melde, welches von beiden und nach wie vielen Minuten.
- Schalter: Ein Lauf mit nur=Max legt genau eine neue Sitzung an (für Max). Ein unbekannter Name bricht ab.
- Die bisherigen Zusicherungen für die fünf Kinder bleiben grün.

## Leitplanken
- Worktree ../Edvancev1-lsat2 auf feat/rasit-lsa-testkind-max von origin/dev. PR gegen dev, nie main.
- Kein DDL. Prod nur lesend über dbread.
- Im PR steht der Startbefehl für Rasit (NICHT dbcheck, das prüft nichts):
  [[ "$DATABASE_URL" == *pooler.supabase.com* ]] && \
  psql "$DATABASE_URL" -tAc "select current_database()" | grep -qx postgres && \
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -v nur=Max -1 -f tools/lsa-testkinder/erzeugen.sql
- STOPP nach dem PR. Auf Prod startet nur Rasit oder ein Agent auf seine ausdrückliche Anweisung.

## Melden
- PR-Link und Startbefehl
- Ausgabetabelle aus dem CI-Lauf für Max (Aufgaben gesamt, davon ready, sicher, Dauer, Ende durch Zeit oder leere Auswahl)
- Ob es auf dem FWG einen Schulplan für Klasse 8 gibt
- offene Punkte
```

## Danach
1. PR mergen, Startbefehl ausführen (nur Max).
2. Prüfen: die Liste „richtig beantwortet, nicht angenommen“ auf Prod. Jeder Eintrag geht an Lena.
3. Report und Präsentation von Max neben Lina legen. Was sagt Seite 1, wenn nichts zu üben ist? Wie
   wirken Station 04 und die Paket-Empfehlung ohne Schwerpunkt?
