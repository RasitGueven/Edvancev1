# Zweitprüfung A3 (Migrationen 20261027134831_reihe1_a3_formate_wertung, 20261027134927_reihe1_a3_formate_figuren)

Frischer Subagent ohne Kontext: nur die zwei Migrationen, Konzept §3–7 und §9, die Frage „Was ist falsch, was fehlt, was bricht?“ (27.10.2026). Die Migrationen waren noch nirgends eingespielt; alle Befunde sind darin abgearbeitet.

| # | Befund | Abarbeitung |
|---|---|---|
| 1 | „Eine Lösung fehlt noch.“ ging in der Session verloren | `session_bewerten` liefert bei einer Teilmenge `qf_loesung_fehlt` (neuer Katalogschlüssel); `aufgabe_werten` liefert den Satz |
| 2 | Erkennung über `question_payload.format` statt `input_type` | CHECK `tasks_format_passt`: neues `input_type` genau dann, wenn `format = lower(input_type)`; `session_bewerten`/`format_werten` gehen über `input_type`. Prod: 0 Aufgaben mit `format` (dbread). `session_bewerten` sonst Zeile für Zeile die Prod-Fassung |
| 3 | CHECK sperrte die Lösungsschlüssel der neuen Formate nicht | `tasks_question_payload_no_solution` erweitert um `werte, menge, keine_loesung, option, reihenfolgen, fehlbilder, loesung, richtig` (Prod: 0 Treffer). Verschachtelte Schlüssel prüft die Prüfmaschine (Prüfung 5) |
| 4 | Antwort ohne Liste bzw. `"ja"` als Boolean wirft | `format_liste`, `format_wahr`; pgTAP-Fälle |
| 5 | Sehr lange Eingaben | `format_bruch`: über 40 Zeichen → unlesbar |
| 6 | Leerzeichen zwischen Ziffern, geschützte Leerzeichen, Gedankenstrich | nur am Rand entfernt (auch U+00A0, U+2009, U+202F); „3 1/2“ unlesbar; „–“ als Minus |
| 7 | Negativer Nenner | „3/−4“ = −3/4 (toleranter als `lsa_grade`, pgTAP hält es fest) |
| 8 | Genauigkeit bei 1/3 | exakt: gekürzter Bruch `z/n` statt Dezimalzahl; 1/3 ≠ 0,333… |
| 9 | Leeres Zusatzfeld macht die Menge unlesbar; leere Antwort traf Fehlbilder ohne Menge | leere Elemente zählen nicht; Fehlbilder nur mit `menge` bzw. `keine_loesung` |
| 10 | Feldmaske vergleicht Felder statt Term (2√12 vs. 4√3) | gewollt nach §7 (Bedeutung je Feld mit Vorzeichen); welche Form gilt, steht je Bauform im Steckbrief (gekürzt), Prüfung 4 testet die Schreibweisen |
| 11 | Graph-Auswahl ohne Bilder ziehbar | `aufgabe_ziehbar`: erst wenn jede Option ein hochgeladenes Bild hat |
| 12 | Rechte für dbread | dbread ist Eigentümer-Rolle; die reinen Funktionen sind für `authenticated` freigegeben (keine Daten) |
| 13 | `aufgabe_rueckmeldung` in der Kindersitzung | reine SQL-Funktion ohne Rechteprüfung, wirft nicht |
| 14 | `richtig` NULL überspringt Fehlbilder; Fehler finden ohne Ordnung | überall `coalesce`; genauestes Fehlbild zuerst |
| 15 | `tasks_input_type_check` | gegen Prod verglichen: alte zehn Werte + sechs neue |
| 16 | Figur für „Graph + Feldmaske“ | `lsa_task_assets` liefert `task_figures` auch für neue Formate |
