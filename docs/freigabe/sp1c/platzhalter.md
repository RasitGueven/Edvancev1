# SP-1c C1 · Platzhalter in Kindtexten

Lauf `bash tools/bauform.sh --alle --platzhalter` (nur prüfen, schreibt nichts) am 12.11.2026 über alle 47 Bauformen,
vor der Änderung an NF-2. Geprüft: Aufgabentext, Hinweise, Lösungsweg, Teile und Bedienelemente jeder erzeugten
Instanz, aus dem Steckbrief die Rückmeldungen der Fehlbilder sowie `warum.frage` und `warum.bausteine[].text`.
Platzhalter = `{` + Bezeichner aus Buchstaben und Unterstrich + `}`; Mengenklammern („L = {0; 18}“) zählen nicht.

| Bauform | Ort | Text |
|---|---|---|
| NF-2 | `warum.frage` | „Warum zieht man ({h})² wieder ab?“ |

47 Bauformen, 1 Treffer — genau der erwartete (SP-1b B2). Kein weiterer Treffer, C2 behebt nur NF-2.

Gegenprobe Prod (dbread): aktive Bauform-Instanzen mit Platzhalter in Frage, Lösungsweg, Hinweisen, Payload oder Teilen: 0;
Steckbriefe mit Platzhalter im `warum` oder in einer Rückmeldung: 1 (NF-2).
