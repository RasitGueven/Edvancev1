# Retro R7-11 · Erster Ansatz am Thema, Anliegen mit Antwort, 22.10.2026

## Gebaut
- **Rechnung:**
  - `schwerpunkte.ts`: Thema-Schwerpunkt, Thema-Reihenfolge (`themaReihenfolge`), Planrang
    (`planrangVon`), Breite außerhalb des Themenraums, Listen mit dem Thema zuerst (`themaZuerst`).
  - `anliegen.ts` (neu): feste Tabelle fachlich/überfachlich, `anliegenAus`, `rueckbezugZeigen`.
  - `lernweg.ts`: nur `kommtNoch` herausgezogen und exportiert.
  - `bericht.ts`: „mit Thema“ über dieselbe Bedingung wie `themaAbdeckung`.
- **Druck:** Seite 1 mit den Thema-Sätzen im Ansatz, „Ihr Anliegen“ als Frage und Antwort, der Kasten
  entfällt ohne Thema und ohne fachliches Anliegen. Seite 4 mit dem Schild „Aktuelles Thema“.
  `s2.fussnote` ohne den Halbsatz zur Bewertungsregel.
- **Präsentation:** Station 01 mit den Anliegen-Sätzen, Station 04 mit Titel und Schild aus derselben
  Rechnung.
- **Gemeinsam:** `liste.ts` (Aufzählung, Titel eines Schwerpunkts) und `seite1Saetze.ts` für Seite 1
  und Station 01.
- **Tests:**
  - Fälle `abgestuftThemaSicher`, `abgestuftPlanrang`, `anliegenGemischt`, `anliegenNurUeberfach`.
  - INV-4.13 (kein Grenzsatz auf Seite 1 und in Station 01).
  - Gerendert: Seite 1 ohne Grenzsatz für alle Fälle.

## Entscheidungen
- „Topologisch“ zählt nur direkt geprüfte Voraussetzungen als Stufe. Damit beginnt Batu bei den
  Wurzelgesetzen, wie die erste Session.
- Rückbezüge auf Seite 1 nur noch bestätigend oder entlastend und nur zu fachlichen Anliegen.
- Textverständnis gilt als fachlich, wie in `report_anlass_zuordnung` (messbar, Sachaufgaben).

## Offen
- `docs/report/r7/offene-punkte-r7-11.md`:
  - Wiederholungen auf Seite 1 aus der Zweitprüfung.
  - Dativ bei Labels.
  - Bestätigung der Tabelle.
  - Thema ohne Übungsbedarf auf Seite 4.

## Nachbesserung (22.10., aus der Zweitprüfung)
- **Ansatz:** Die Startstelle ist der Titel, darüber steht „Im Thema …“. Darunter ein Satz: „Darauf baut
  … auf.“ oder „Hier setzen wir zuerst an.“ Die Listen stehen nicht mehr im Ansatz.
- **Labels:** Kein Satz beugt mehr einen Bereichsnamen („Ihr Anlass: …“, „Dort hakt es: …“).
- **Thema ohne Übungsbedarf:** Das Thema ist dann kein Schwerpunkt (`Elternbericht.thema` trägt es
  weiter).
- **Präsens:** „Das klappt bereits“.
- **Zweitprüfung 2:** Alle drei Fragen sind beantwortet, auch das Warum des Starts.
