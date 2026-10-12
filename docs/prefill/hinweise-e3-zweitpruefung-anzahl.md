# Zweitprüfung Hinweise E3 · gleichung_quadr_anzahl

Grundlage: `vorschau-anzahl.md`, Rohdaten `docs/prefill/hinweise-e3-snapshot.json` (typical_errors, known_errors).
Alle Aufgaben selbst gerechnet, jede Zahl in jedem Hinweis nachgerechnet. Keine falsche Zahl gefunden, kein Hinweis verrät das Endergebnis, kein Hinweis rechnet D bei einer Anzahl-Aufgabe aus.

| Aufgabe | Urteil | Befunde |
|---|---|---|
| quadrgl-anzahl-04 (2x² − 8x + 8 = 0, Antwort 1) | ok mit kann | kann: Stufe 3 ist mit `vorzeichen_potenz` getaggt, spricht das Fehlbild aber nicht an |
| quadrgl-anzahl-01 (x² + 4x + 5 = 0, Antwort 0) | ok | – |
| quadrgl-anzahl-05 (Zaun, Antwort 1) | ok mit kann | kann: Stufe 2 „auf die Seite mit x²“ ist nach dem Ausmultiplizieren mehrdeutig |
| quadrgl-anzahl-03 (D von x² − 5x − 6 = 0, Antwort 12,25) | ok mit kann | kann: Stufe 2 „Achte beim Ablesen auf die Vorzeichen“ läuft ins Leere, weil p und q schon genannt sind |
| quadrgl-anzahl-02 (D von x² − 6x + 8 = 0, Antwort 1) | ok mit kann | kann: wie 03, Stufe 2 |
| quadrgl-anzahl-06 (q rückwärts, Antwort 9) | ok mit kann | kann: Stufe 3 „achte auf das Vorzeichen“ ist vage für `betrag_fehler` |

Kein „muss“-Befund.

## Einzelheiten

### quadrgl-anzahl-04 · 2x² − 8x + 8 = 0

Nachgerechnet: : 2 → x² − 4x + 4 = 0, p = −4, q = 4, p/2 = −2, D = 4 − 4 = 0 → genau eine Lösung (x = 2). Stufe 2 (x² − 4x + 4 = 0) und Stufe 3 (D = (−2)² − 4) stimmen. Stufe 3 nennt D nicht ausgerechnet, nur angesetzt; die Anzahl bleibt beim Kind. Stufe 1 lenkt passend auf die Normalform (`division_vergessen`), Steigerung 1 → 2 → 3 ist sauber.

- **kann** (Stufe 3): Getaggt mit `vorzeichen_potenz` (known_error „0“: (−2)² als −4 gerechnet), der Text geht darauf aber nicht ein; die Geschwister 05/03/02 haben dafür einen Satz. Vorschlag (2 Sätze, 151 Zeichen):
  „Jetzt ist p = −4 und q = 4, also D = (−2)² − 4. Denk daran, dass das Quadrat einer negativen Zahl positiv ist, und überlege, was D für die Anzahl bedeutet.“

### quadrgl-anzahl-01 · x² + 4x + 5 = 0

Nachgerechnet: p = 4, q = 5, p/2 = 2, D = 4 − 5 = −1 < 0 → keine Lösung. Stufe 2 (p = 4, q = 5, Formel) und Stufe 3 (D = 2² − 5) stimmen; D wird nicht ausgerechnet, die Entscheidung positiv/null/negativ bleibt beim Kind. Stufe 3 adressiert `halbieren_vergessen` durch „Wir halbieren p“. Urteil: ok.

### quadrgl-anzahl-05 · Zaun 20 m, Fläche 25 m²

Nachgerechnet: x(10 − x) = 10x − x² = 25 → 0 = x² − 10x + 25, p = −10, q = 25, p/2 = −5, D = 25 − 25 = 0 → eine Lösung (x = 5). Alle Zahlen stimmen. Stufe 3 adressiert beide Fehlbilder (p/2 explizit, Quadrat positiv).

- **kann** (Stufe 2): Nach dem Ausmultiplizieren steht −x² links; „auf die Seite mit x²“ kann zu −x² + 10x − 25 = 0 führen, was nicht der Normalform entspricht. Vorschlag (2 Sätze, 128 Zeichen):
  „Multipliziere aus: 10x − x² = 25. Bring alles nach rechts, damit x² mit Plus dasteht: 0 = x² − 10x + 25.“

### quadrgl-anzahl-03 · Diskriminante x² − 5x − 6 = 0

Nachgerechnet: p = −5, q = −6, p/2 = −2,5, D = 6,25 + 6 = 12,25. Stufe 3 führt bis (−2,5)² − (−6) samt „Quadrat positiv“ und „minus (−6) heißt plus 6“; es bleibt 2,5² und die Addition, das ist „kurz vor dem Ergebnis“, ohne 12,25 zu nennen. Beide known_errors (`halbieren_vergessen` → 31, `vorzeichen_potenz` → −0,25) werden adressiert.

- **kann** (Stufe 2): „Achte beim Ablesen auf die Vorzeichen“ steht nach den bereits genannten Werten und hat so keine Funktion. Vorschlag (2 Sätze, 96 Zeichen):
  „Lies p und q mit ihren Vorzeichen ab: p = −5 und q = −6. Setze beide in D = (p/2)² − q ein.“

### quadrgl-anzahl-02 · Diskriminante x² − 6x + 8 = 0

Nachgerechnet: p = −6, q = 8, p/2 = −3, D = 9 − 8 = 1. Stufe 3 (D = (−3)² − 8, Quadrat positiv) stimmt und nennt D nicht. Beide Fehlbilder (28 bzw. −17) adressiert.

- **kann** (Stufe 2): wie 03. Vorschlag (2 Sätze, 94 Zeichen):
  „Lies p und q mit ihren Vorzeichen ab: p = −6 und q = 8. Setze beide in D = (p/2)² − q ein.“

### quadrgl-anzahl-06 · x² + 6x + q = 0 mit genau einer Lösung

Nachgerechnet: eine Lösung ⇔ D = 0; D = 3² − q = 9 − q = 0 → q = 9 (Probe (x + 3)², x = −3). Stufe 2 (D = 0, D = (6/2)² − q) stimmt, Stufe 3 verrät q nicht. `halbieren_vergessen` (36) ist durch (6/2)² abgedeckt.

- **kann** (Stufe 3): „achte auf das Vorzeichen“ trifft `betrag_fehler` (q = −9) nur vage; die Probe aus der socratic_question der Aufgabe ist konkreter und verrät nichts. Vorschlag (2 Sätze, 134 Zeichen):
  „Wir rechnen (6/2)² aus; diese Zahl minus q muss null ergeben. Stell nach q um und setz dein q zur Probe ein: Ergibt sich wirklich null?“
