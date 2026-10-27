# Zweitprüfung B5 · Migration 20261027135739_studio_freigabe

Frischer Subagent ohne Kontext. Frage: „Was ist falsch, was fehlt, was bricht?“

| # | Befund | Schwere | Umgang |
|---|---|---|---|
| 1 | Zurückziehen per `studio_ausgabe_pruefen` umgehbar | kritisch | Zurückziehen erhöht die Versionen (alle Freigaben fallen); Ausgabe nur in Status in_pruefung/freigegeben; Test |
| 2 | „Prüfer ≠ Autor“ über Admin-Bearbeitung umgehbar; eine Person kann alles | kritisch | `studio_bearbeiter` (Trigger), Prüfer ist nie Bearbeiter; verständlich und fachlich zwei Personen; Prüfrollen nur ausdrücklich; Tests |
| 3 | Fremde `tasks` auf ready, auch beanstandete | kritisch | nur `draft → ready`; Bedarf an A in `an-A.md` (Funktion von A wäre besser) |
| 4 | Variante gilt gegen altes Skelett | mittel | Freigaben tragen den Inhalts-Fingerabdruck der Welt (enthält das Skelett), Test |
| 5 | Fachliche Freigabe nicht am Video | mittel | derselbe Fingerabdruck enthält Stimme und Renderer-Fassung |
| 6 | Wettlauf in `veroeffentlichen` | mittel | `for update` auf die Sequenz |
| 7 | „passt nicht“ auf freigegebene Sequenz folgenlos | mittel | Status geht auch aus „freigegeben“ an den Autor; Ausgabe bleibt bis neu freigegeben oder zurückgezogen |
| 8 | Sequenz nicht löschbar | mittel | Kaskade im Trigger erlaubt |
| 9 | Jeder mit `darf_pruefen` prüft fachlich | mittel | nur `studio_rolle 'fachlich'` |
| 10 | Entfernte Welt bleibt ausgegeben | gering | wird bei der nächsten Ausgabe zurückgezogen |
| 11 | Titel nicht im Hash | gering | offen (Titel ändert sich mit neuem Render ohnehin) |
| 12 | Aufgaben nach Zurückziehen weiter ready | gering | offen: B6 spielt Video-Checks nur aus der Ausgabe aus |
| 13 | Varianten nach „passt nicht“ nicht prüfbar | gering | Varianten jederzeit prüfbar |
