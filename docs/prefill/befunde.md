# Befunde: Pilot Mathe 8 (Charge `mathe8-pilot`)

**Auswahl:** die ersten 18 offenen Aufgaben im Themengebiet „Algebra & Funktionen", in der Reihenfolge von Lenas
Warteschlange (Titel, dann ID). Alle stammen aus dem Eigenbau `edvance_k8_binom`.

**VERA8 ist ausgeschlossen** (Entscheidung zu PR #176). Die ursprüngliche Auswahl hatte 25 Aufgaben, darunter
7 VERA8-Aufgaben. Diese sind entfernt, aufgefüllt wurde nicht. Die Definition steht in `src/lib/authoring/vera8.ts`.

**Wo Lena die Werte findet:**

- Die neuen Werte stehen mit Begründung in `mathe8-pilot.csv`.
- Das Prüfprotokoll steht in `mathe8-pilot-verifikation.md`.

## A – Gesetzte Werte, die falsch werten

Keine. Alle 18 gespeicherten Antworten hat das Skript per Termvergleich bzw. exakter Rechnung bestätigt, und der
Blind-Löser kommt jedes Mal auf dieselbe Antwort.

## B – Bewusst leer gelassen

| Feld | Aufgaben | Grund |
|---|---|---|
| `unit` | #11 (102 · 98), #16 (47² - 43²) | Reine Zahl, keine Einheit. |
| `coach_hints` | alle 18 | Kein Beleg, inhaltlich doppelt zu `typical_errors`. **Entscheidung Rasit/Lena**, ob das Feld überhaupt vorbefüllt werden soll. |
| `acceptance`, `option_scores` | alle | Ohne UI kann Lena diese Felder nicht prüfen. Die Binom-Aufgaben haben `acceptance` ohnehin schon. |

AFB, Stoffanker, Themengebiet, Inhaltsfeld, Prozesskompetenz und `needs_image` waren bei allen 18 Aufgaben schon
gesetzt.

## C – Bitte kurz prüfen (gesetzt, aber unsicher)

- **Zeitbudget:** für alle 18 nach einer einheitlichen Regel (AFB I 45 s, II 60 s, III 90 s, +30 s bei Sachkontext).
  Die Regel ist eine Annahme und nicht gemessen.
- **Typische Fehler:** abgeleitet aus `acceptance.known_errors` der Aufgabe, also aus den Distraktoren. Die
  Formulierung und die sokratische Rückfrage sind generiert.
- **Hinweise (2 Stufen):** generiert, ohne Beleg. Der Prüfer stellt sicher, dass Stufe 1 die Antwort nicht verrät.

## D – Außerhalb des Piloten

- **Themengebiet:** `cluster_id` fehlt bei 70 Aufgaben außerhalb von VERA. Lena kann den Wert zurzeit nicht speichern
  (Lücke L1 in der Bestandsaufnahme).
- **VERA8-Mängel** (Kodiertext in `correct_answers`, mc-Antworten ohne Options-ID, Aufgaben ohne Typ) betreffen nur
  VERA8. Laut Entscheidung bleiben diese Daten unverändert und gehören nicht zu Lenas Prüfung. Die Zahlen stehen zur
  Information in der Bestandsaufnahme.
