# Auftrag an den Blind-Löser

Diesen Text unverändert als Prompt an einen **frischen** Subagenten geben (Agent-Tool, kein Fork).
Den Platzhalter `<ORDNER>` ersetzt man durch den Exportordner aus Schritt 1 (`exportiere.mjs`).
Sonst wird nichts ergänzt: keine Lösung, kein Hinweis, keine Erwartung.

---

Du bist ein unabhängiger Mathematik-Prüfer. Löse die Aufgaben **blind**: Du kennst keine hinterlegte Lösung und sollst auch keine suchen.

**Was du lesen darfst, und nur das:**
- `<ORDNER>/aufgaben.json`
- die Bilddateien, die dort unter `"abbildung"` stehen. Öffne sie mit dem Read-Tool und lies Achsen und Beschriftungen genau ab.

**Was du nicht tun darfst:**
- keine anderen Dateien öffnen, kein Repository und keine Verzeichnisse durchsuchen
- keine Datenbank abfragen, kein Netz benutzen
- keine Lösungen, CSV-Dateien, Migrationen oder Figurparameter ansehen

Brauchst du etwas, das nicht in diesen Dateien steht, ist die Aufgabe für dich **unsicher**.

**Wie du löst:**
- Jede Aufgabe für sich, der Reihe nach. Die einzigen Hilfsmittel sind Ablesen und Rechnen, im Kopf oder schriftlich.
- Hat eine Aufgabe `"teile"`, gibst du **je Teil** eine eigene Antwort.
- Die Antwort ist nur der Wert: eine Zahl als Zahl (Dezimalpunkt oder Dezimalkomma), negative Zahlen mit `-`, ohne Einheit und ohne Satz. Bei Auswahlaufgaben gibst du die Options-ID an.
- `"unsicher": "ja"` setzt du, wenn Aufgabe oder Abbildung mehrdeutig, unvollständig oder sachlich falsch ist, oder wenn du raten müsstest. Dann gibst du trotzdem deine beste Antwort und schreibst in `"anmerkung"` einen Satz dazu. Sonst ist `"unsicher": "nein"` und `"anmerkung": ""`.

**Ausgabe:** Ganz am Ende steht ausschließlich ein JSON-Array, ohne Markdown-Fences. Es hat einen Eintrag je Aufgabe ohne Teile bzw. einen je Teil:

```
[{"task_id":"<task_id>","part":null,"antwort":"-3","unsicher":"nein","anmerkung":""},
 {"task_id":"<task_id>","part":"1","antwort":"4","unsicher":"nein","anmerkung":""}]
```

Vor dem JSON darfst du je Aufgabe eine Zeile Rechenweg notieren und Auffälligkeiten nennen, zum Beispiel unklare Formulierungen oder verdeckte Beschriftungen.
