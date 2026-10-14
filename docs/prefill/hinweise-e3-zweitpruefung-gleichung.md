# Zweitprüfung Hinweise E3 · gleichung_einschrittig / gleichung_zweischrittig

Grundlage: `scratchpad/e3/vorschau-gleichung.md`, known_errors gegengelesen in
`/home/rasit/Edvancev1-e3/docs/prefill/hinweise-e3-snapshot.json` (nur gelesen).

**Gesamturteil: 12 × ok, kein „muss“.** Alle Zahlen stimmen, kein Hinweis verrät das Endergebnis,
Stufenfolge steigt sauber an, Sprache und Schreibweise (−, :) regelkonform, je Stufe ≤ 2 Sätze.
Es gibt nur „kann“-Befunde an den Schablonen.

## 1. Nachrechnung

| Aufgabe | Ergebnis | Stufe 2/3 Zahlen | known_errors (Wert → Herleitung) | Zuordnung |
|---|---|---|---|---|
| 3x = 18 | 6 ✓ | x = 18 : 3 ✓ | 15 = 18 − 3 → falsche_gegenoperation | passt |
| 4x = 24 | 6 ✓ | x = 24 : 4 ✓ | 20 = 24 − 4 → falsche_gegenoperation | passt |
| x + 12 = 20 | 8 ✓ | x = 20 − 12 ✓ | 32 = 20 + 12 → falsche_gegenoperation; −8 = 12 − 20 → seiten_verwechselt | passt |
| x + 7 = 12 | 5 ✓ | x = 12 − 7 ✓ | 19 = 12 + 7 → falsche_gegenoperation; −5 = 7 − 12 → seiten_verwechselt | passt |
| x − 4 = 9 | 13 ✓ | x = 9 + 4 ✓ | 5 = 9 − 4 → falsche_gegenoperation; −5 = 4 − 9 → seiten_verwechselt | passt (siehe K4) |
| x − 9 = 6 | 15 ✓ | x = 6 + 9 ✓ | −3 = 6 − 9 → falsche_gegenoperation; 3 = 9 − 6 → seiten_verwechselt | passt (siehe K4) |
| 2x + 4 = 20 | 8 ✓ | 2x = 16 ✓, x = 16 : 2 ✓ | 10 = 20 : 2 b_ignoriert; 12 = 24 : 2 addiert_statt_subtrahiert; 16 division_vergessen | passt |
| 3x + 6 = 24 | 6 ✓ | 3x = 18 ✓, x = 18 : 3 ✓ | 8 = 24 : 3; 10 = 30 : 3; 18 | passt |
| 3x + 9 = 30 | 7 ✓ | 3x = 21 ✓, x = 21 : 3 ✓ | 10 = 30 : 3; 13 = 39 : 3; 21 | passt |
| 4x + 8 = 40 | 8 ✓ | 4x = 32 ✓, x = 32 : 4 ✓ | 10 = 40 : 4; 12 = 48 : 4; 32 | passt |
| 5x + 10 = 45 | 7 ✓ | 5x = 35 ✓, x = 35 : 5 ✓ | 9 = 45 : 5; 11 = 55 : 5; 35 | passt |
| 6x + 12 = 42 | 5 ✓ | 6x = 30 ✓, x = 30 : 6 ✓ | 7 = 42 : 6; 9 = 54 : 6; 30 | passt |

Die erschlossene Slug-Bedeutung trifft auf alle 24 Einträge zu. Präzisierung: Bei x − b = c ist
`seiten_verwechselt` (4 − 9, 9 − 6) zugleich falsche Gegenoperation **und** vertauschte Reihenfolge;
`falsche_gegenoperation` ist dort „c − b in richtiger Reihenfolge“. Die Codierung ist über beide
Subtraktionsaufgaben konsistent.

## 2. Befunde

Keine „muss“-Befunde.

### Schablone einschrittig (6 Aufgaben)

- **K1 · Stufe 2 Additionsaufgaben, Stil.** „Auf x wird 12 addiert. Rechne deshalb auf beiden Seiten − 12.“
  „Zu x“ ist das übliche Deutsch, „Ziehe … ab“ passt zum Verb-Muster von „Teile …“.
  Vorschlag: „Zu x wird 12 addiert. Ziehe deshalb auf beiden Seiten 12 ab.“
  (analog Subtraktion: „Von x wird 4 abgezogen. Addiere deshalb auf beiden Seiten 4.“)
- **K2 · Stufe 3 Additionsaufgaben, Stil.** „… achte auf die Reihenfolge“ steht hinter einem
  schon hingeschriebenen x = 20 − 12; der Hinweis wird konkreter, wenn er die Reihenfolge benennt.
  Vorschlag: „Wir rechnen auf beiden Seiten − 12: x = 20 − 12. Rechne die Differenz genau in dieser Reihenfolge aus.“
- **K3 · Stufe 1, kann.** Für alle 6 wortgleich. Das ist als Denkanstoß zulässig (keine Lösungszahl),
  passt aber auf jede Gleichung. Wer stärker an die Aufgabe binden will, ohne Stufe 2 vorwegzunehmen:
  „Gesucht ist die Zahl für x. Schau, was in der Gleichung mit x passiert, und überlege, wie du das rückgängig machst.“
  (nur sprachlich; inhaltlich ok, daher optional)
- **K4 · Metadaten, nicht kindsichtbar.** Bei x − 4 = 9 und x − 9 = 6 hängt `seiten_verwechselt`
  an Stufe 3 („x = 9 + 4. Rechne die Summe aus.“). Eine Summe hat keine Reihenfolge; der Fehler
  (4 − 9) entsteht bei der Wahl der Gegenoperation, also in Stufe 2. Vorschlag: Fehlbild-Tag
  `seiten_verwechselt` bei Subtraktionsaufgaben an Stufe 2 hängen (dort zusätzlich zu
  `falsche_gegenoperation`). Der Text selbst hilft dem Kind trotzdem, daher nur „kann“.

### Schablone zweischrittig (6 Aufgaben)

- **K5 · Stufe 2, kann.** „Rechne zuerst auf beiden Seiten − 4: 2x = 16.“ Die Zwischenzahl 16 ist
  zugleich der known_error `division_vergessen`; ein Kind kann nach Stufe 2 „16“ eintippen. Stufe 3
  fängt das auf, regelwidrig ist es nicht. Optional die Restaufgabe benennen:
  „Rechne zuerst auf beiden Seiten − 4: 2x = 16. Links steht jetzt noch 2x, nicht x.“
- **K6 · Stufe 3, kann.** Stufe 3 setzt ohne Rückbezug an; „der Weg bis kurz vor das Ergebnis“
  wird lesbarer mit Zwischenstand. Vorschlag: „Aus 2x = 16 teilen wir beide Seiten durch 2: x = 16 : 2. Rechne die Division aus.“
- Stufe 1 („das Plus oder das Mal“) ist ein guter, aufgabenpassender Denkanstoß – ok.

## 3. Nebenbefunde (außerhalb der Hinweise)

- `solution` ist für alle 12 Aufgaben `null`; die Hinweise lassen sich daher gegen keinen
  gespeicherten Lösungsweg abgleichen. Sie folgen dem Standardweg und sind in sich stimmig.
- Negative known_errors-Schlüssel (−8, −5, −5, −3) existieren nur mit ASCII-Bindestrich (`-8`).
  Tippt ein Kind „−8“ (Unicode-Minus) oder „- 8“, greift die Fehlbild-Diagnose nicht (andere
  Skills führen dafür `−…`/`- …`-Varianten). Betrifft acceptance, nicht die Hinweise.
