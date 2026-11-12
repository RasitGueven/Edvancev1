# SP-1b · Offene Befunde

## B1 · NS-4 Stufe 2 und 3 ohne Klartext (N1)

Die vorgegebene Beschreibung („… ihr Abstand ist gerade; der Scheitel hat ganze Koordinaten …“) ist nach der
Zweitprüfung (`klartext-pruefung.md`) unvollständig: Der Generator (`scripts/bauformen/bauformen/ns_4.py`,
`angenehm()` mit |e| ≤ 9) lässt nur Nullstellen-Abstände **2, 4 oder 6** zu; „Abstand gerade“ ließe z. B. −5 und 3
(Abstand 8) erwarten, das nie vorkommt. Weil der Text für Stufe 2 verbindlich vorgegeben war, ist er nicht geändert
und nicht eingespielt worden; die Ansicht zeigt für NS-4 weiter die Generator-Regel.

**Vorschlag:** in beiden Stufen „ihr Abstand ist 2, 4 oder 6“ statt „ihr Abstand ist gerade“; danach erneute Prüfung
und eine kleine Datenmigration.

## B2 · NF-2: Platzhalter in der „Warum?“-Frage des Lösungsbeispiels (N4, kindsichtbar)

`bauformen.steckbrief.warum.frage` von NF-2 lautet „Warum zieht man ({h})² wieder ab?“ – der Platzhalter `{h}` ist
nicht ersetzt. `aufgabe_payload` gibt `steckbrief.warum` unverändert als `loesungsbeispiel.warum` aus
(`supabase/schema-erwartet.sql`, Funktion `aufgabe_payload`), das Kind sieht im Lösungsbeispiel also „({h})“. Die
übrigen Bauformen haben keinen Platzhalter im `warum` (dbread). Beheben braucht eine Steckbrief-Änderung (neue
Version, Lena prüft NF-2 neu) oder eine Änderung an `aufgabe_payload` – beides in SP-1b verboten. Der Ansichtstest
`alle-47.spec.ts` hält den Fall fest und wird rot, sobald er behoben ist.

**Vorschlag:** im Generator `nf_2.py` die Frage ohne Zahl stellen („Warum zieht man das Quadrat der halben Zahl
wieder ab?“) oder je Instanz ersetzen; neue Version über `tools/bauform.sh`.

## B3 · Leere Stufenzeilen ohne Klartext (Korrektur zu SP-1)

Der SP-1-Bericht sagte, ohne Klartext zeige die Ansicht die Generator-Regel. Das stimmte nicht: Bei vorhandenen
`bauform_stufen`-Zeilen ohne Beschreibung blieb die Zeile leer (Foto `abnahme/n4-*-stufen-vorher.png`). Seit N4 fällt
die Anzeige je Stufe auf die Regel aus dem Steckbrief zurück (betrifft heute nur NS-4, B1).
