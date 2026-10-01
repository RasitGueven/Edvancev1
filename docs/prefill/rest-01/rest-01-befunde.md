# Befunde: Charge `rest-01` (erste Charge Restbestand) — eingespielt als `20260930150100`

**Auswahl (28 Aufgaben, kein VERA8):**
- die restlichen 6 offenen Binom-Aufgaben (Algebra & Funktionen)
- alle 22 offenen Aufgaben `edvance_fundament_afb1` (bisher ohne Themengebiet)

Es sind die nächsten 28 Aufgaben ohne VERA8. Gezielt Überschreibungskandidaten zu wählen war nicht möglich, weil es
im Restbestand keine gibt (siehe Überschreibungen).

**Wo Lena die Werte findet:**

- Die neuen Werte mit Begründung stehen in `rest-01.csv`.
- Das Prüfprotokoll steht in `rest-01-verifikation.md`.
- Den Abgleich mit Prod (nur gelesen) enthält `rest-01-prod-abgleich.md`.

## Überschreibungen: 0

Alle 75 offenen Aufgaben ohne VERA8 habe ich vorab geprüft:

- Die gespeicherten Antworten stimmen. Für diese Charge hat das Skript alle 28 exakt nachgerechnet, der Blind-Löser
  kommt 28 von 28 Mal auf dieselbe Antwort.
- Das Antwortformat passt zum Aufgabentyp.
- NUMERIC-Aufgaben werten über `acceptance` numerisch. Zusätzliche Varianten wie „3,5“ neben „3,50“ hätten deshalb
  keine Wirkung.
- Die Zeitbudgets der `afb1`-Aufgaben (30–60 s) sind je Aufgabentyp gestaffelt und keine Pauschal-Platzhalter.

Pauschale Import-Platzhalter (180/240 s) gibt es nur in VERA8 und im `ready`-Bestand. Beide sind ausgeschlossen.

## Was die Migration setzt

| Feld | neu | Grundlage |
|---|---|---|
| Themengebiet (`cluster_id`) | 22 | Datenbelegt über `skill_key`: Jeder der 11 Skills liegt bei allen bereits zugeordneten Aufgaben in genau einem Themengebiet, zum Beispiel `potenzen` → Zahl & Rechnen (16 von 16). |
| Bildbedarf (`needs_image`) | 22 | `false`. Der Aufgabentext enthält alle Angaben und verweist auf keine Abbildung. |
| Zeitbudget | 6 | Zeitregel (AFB I 45 s, II 60 s, III 90 s, +30 s bei Sachkontext). Nur bei den Binom-Aufgaben, bei `afb1` war es schon gesetzt. |
| Lösungsweg, Hinweise, typische Fehler | je 28 | Lösungsweg nachgerechnet, Hinweise generiert, typische Fehler aus `acceptance.known_errors` abgeleitet. |

**Bewusst leer:** keine Felder. Coach-Hinweise (LSA) und die Einheit bei reinen Zahlen bleiben nach Entscheidung leer
und gelten nicht als Befund.

## Bitte kurz prüfen

- **Themengebiet:** `gleichung_beidseitig` liegt laut Bestand unter „Zahl & Rechnen“ und nicht unter „Algebra &
  Funktionen“. Ich habe den Bestand übernommen, nicht umsortiert.
- **Version:** eingespielt als `20260930150100_prefill_rest_01` (fortlaufende Version nach Auftrag), Nachweis in `rest-01-nachweis.md`.
