# Befunde: Pilot Mathe 8 (Charge `mathe8-pilot`)

**Auswahl:** die ersten 25 offenen Aufgaben im Themengebiet „Algebra & Funktionen", in derselben Reihenfolge wie
Lenas Warteschlange (Titel, dann ID). Darunter sind 10 VERA-Aufgaben und 15 Eigenbau-Aufgaben (`edvance_k8_binom`).

**Wo Lena die Werte findet:**

- Die neuen Werte stehen mit Begründung in `mathe8-pilot.csv`.
- Das Prüfprotokoll steht in `mathe8-pilot-verifikation.md`.

## A – Gesetzte Werte, die falsch werten (nicht überschrieben, Lena bitte korrigieren)

| # | Aufgabe | Befund | Vorschlag |
|---|---|---|---|
| A1 | #18 Eiscafé, Teil 2 (mc) | `correct_answers["2"]` enthält den IQB-Kodiertext („Eiscafé Arnoldo ist angekreuzt", „UND", „Lösungsweg …") statt einer Options-ID. Die Teilaufgabe wird **nie** als richtig gewertet. | `["a"]`. Nachgerechnet: 4,50 € : 5 = 0,90 € > 0,80 €. Der Blind-Löser kommt ebenfalls auf a. |
| A2 | #18 Eiscafé, Teil 1 | Hinterlegt ist nur `"3,70"`. Die Normalisierung ersetzt lediglich das Komma, deshalb wird die Eingabe „3,7" als falsch gewertet. | Variante `"3,7"` ergänzen. |
| A3 | #3 Berechne x | Hinterlegt ist `"x = 9"`. Die Eingabe „9" wird als falsch gewertet, obwohl das Eingabefeld schon mit „x =" beschriftet ist. | `["9", "x = 9"]` |

## B – Strukturell unvollständig (nur Teilwerte vorbefüllt)

| # | Aufgabe | Befund | Vorbefüllt |
|---|---|---|---|
| B1 | #2 Aussagen zur proportionalen Zuordnung | MC ohne Optionen und ohne Graph. Die Abbildung wurde beim Import aus Lizenzgründen weggelassen, die IQB-Lösung liegt nur als Bild vor. | nur Zeitbudget |
| B2 | #17 Eindeutig | Kein Aufgabentyp, keine Teilaufgaben. Der Stamm endet nach dem ersten Satz. Laut IQB gehören dazu drei Gleichungen („eine oder keine Lösung", AFB II) und eine Gleichung mit unendlich vielen Lösungen (AFB III). | AFB III (belegt), Lösungsweg (nachgerechnet) als Hilfe für den Neuaufbau |
| B3 | #1 Andere Länder, Teil 3 | „Notiere deinen Lösungsweg" ist im Original keine eigene Teilaufgabe, sondern gehört zu TA2. Als `short_input` wird er nur bei wörtlicher Gleichheit gewertet. | Musterlösung als Erwartungshorizont. Vorschlag: Teil 3 streichen oder in Teil 2 aufgehen lassen. |
| B4 | #1 Andere Länder, Teil 4 | Eine Formel als Freitext wird ebenfalls nur bei wörtlicher Gleichheit gewertet. | Zwei Schreibweisen als Musterlösung. Das Skript prüft, dass beide der Formel P/M · 9 + 1 entsprechen. |

## C – Bewusst leer gelassen

| Feld | Aufgaben | Grund |
|---|---|---|
| Stoffanker `curriculum_grade` | #1, #17 | Nicht eindeutig zwischen Klasse 7 und 8. Das C10-Audit hat beide Aufgaben auch nicht als „sicher" eingestuft. Vorschlag an Lena: 7 oder 8. |
| `competency_process` | #2, #25 | Das IQB nennt keine K-Kompetenz. Bei #25 wären „Modellieren" und „Operieren" beide vertretbar. |
| `correct_answers` | #2, #17 | Siehe B1 und B2. |
| `hints`, `typical_errors` | #2, #17 | Die Aufgabe ist unvollständig, Hinweise dazu wären geraten. |
| Zeitbudget | #17 | Ohne Aufgabentyp nicht schätzbar. |
| `unit` | #3, #14, #22 | Reine Zahl, keine Einheit. |
| `coach_hints` | alle 25 | Kein Beleg, inhaltlich doppelt zu `typical_errors`. **Entscheidung Rasit/Lena**, ob das Feld überhaupt vorbefüllt werden soll. |
| `needs_image` | #16, #17, #18 | Laut Item-Pflege „eine Fachentscheidung, kein Automatismus". |
| `acceptance`, `option_scores` | alle | Ohne UI kann Lena diese Felder nicht prüfen (siehe Bestandsaufnahme). |

## D – Bitte kurz prüfen (gesetzt, aber unsicher)

- **#1, Teil 2:** Zusätzlich zu 90 ist 89 hinterlegt. 89/100 · 5 + 1 = 5,45 ergibt nur bei kaufmännischem Runden 5,5.
  Das IQB belegt TA2 nicht. Halbe Punkte (89,5 / 90,5) sind nicht berücksichtigt.
- **Zeitbudget der MULTI_PART-Aufgaben #1 (240 s), #16 und #18 (je 180 s):** Diese Werte waren schon gesetzt, laut
  Import-Flag sind es aber Platzhalter (90 s je Teilaufgabe). Sie wurden nicht überschrieben.
- **Zeitbudget der übrigen Aufgaben:** vergeben nach einer einheitlichen Regel (AFB I 45 s, II 60 s, III 90 s, +30 s bei
  Sachkontext). Die Regel ist eine Annahme und nicht gemessen.
- **Typische Fehler bei #3 und #25:** Sie folgen der IQB-Kommentierung. Das Zitat im Grounding ist jedoch abgeschnitten,
  das Beispiel ist ergänzt.
- **Typische Fehler bei #1, #16 und #18 sowie alle Hinweise:** generiert, ohne Beleg. Die typischen Fehler der
  Binom-Aufgaben sind aus `acceptance.known_errors` abgeleitet.

## E – Außerhalb des Piloten (Gesamtbestand)

- **Defekte Antworten:**
  - 64 Aufgaben mit Kodiertext in `correct_answers`
  - 20 mc-Teilaufgaben ohne Options-ID als Antwort
  - 38 Aufgaben ohne `input_type`
  - 56 Aufgaben ohne `task_solutions`-Zeile

  Werte wie diese überschreibt eine Vorbefüllung nicht. Sie brauchen eine eigene, beaufsichtigte Korrektur.
- **Themengebiet:** `cluster_id` fehlt bei 111 Aufgaben. Lena kann den Wert zurzeit nicht speichern (Lücke L1).
- **`skill_key`:** Bei allen VERA-Pilotaufgaben ist er leer, `verify-tasks --nur-struktur` meldet „wird nie gezogen".
  Das ist kein Lena-Feld und gehört ins Foundation-Fenster.
