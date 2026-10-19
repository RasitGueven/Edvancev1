# R7-3 · Offene Punkte und Abweichungen

Stand 19.10.2026, Branch `feat/rasit-report-r7-seiten25`. Seite 2 (Lernstand) und Seite 5 (Nächste
Schritte); Seiten 3 und 4 baut R7-4 parallel.

## Abnahme-Material

- PDFs aller Fälle: `docs/report/r7/abnahme/r7-3/<fall>.pdf` (Seiten 2 und 5 gefüllt, 3 und 4 leer).
- Druck-Tests: `EB_PORT=5183 EB_AUSGABE=docs/report/r7/abnahme/r7-3 npx playwright test -c
  playwright.elternbericht.config.ts`, 13 von 13 grün.

## Gemessen

- Seite 5 (`testlauf`): alle Grundlinien höchstens 0,2 pt neben dem Muster.
- Seite 2 mit sechs Profilzeilen (`klasse7`): Kicker „Was die Grafik zeigt“ 0,6 pt neben dem Muster.
- Untere Kante des Inhalts auf Seite 2 (Druckmedium): `ohneName` 783,7 pt (knappster Fall),
  `ilkay` 773,7, `allesSicher` 736,8. Grenze 800.

## Abweichungen vom Muster

| Stelle | Muster E7 | R7-3 | Grund |
|---|---|---|---|
| Profilzeilen | sechs Familien, Abstand 40,8 | acht Themenfelder, ab sieben Zeilen 33,4 | Entscheidung 5 und Paket-Entscheidung 1 |
| Seite 2 ab sieben Zeilen | – | Abstände um die Zahlen, unter der Karte, Legende und Fußnote enger (`.eb-s2-eng`) | Sonst läuft Ilkay (acht Zeilen, zweizeiliges Intro) über; so bleiben mindestens 16 pt Luft |
| Intro Seite 2 | einzeilig | bei Ilkay zweizeilig („27 von 130 … 103 Bereiche“) | längere Zahlen |
| Trennlinie bei 33,4 pt | – | 27,6 pt unter der Spur-Oberkante (mittig zwischen Unterzeile und nächster Spur) | „entsprechend“ im Auftrag, im Muster nicht belegt |
| „Was die Grafik zeigt“ | freier Text | Sätze aus der Regel (Entscheidung 1) | Bauauftrag |
| Chip Navy-Kasten | „Vorschlag, noch nicht freigegeben“ | „Vorschlag“, Breite folgt dem Text | Bauauftrag, Entscheidung 11 |
| Rolle | „Mitgründer, hat die Analyse begleitet“ | „hat die Analyse begleitet“ | Rolle steht nicht in den Daten |
| Titel Navy-Kasten | Umbruch nach „passt,“ | `text-wrap: balance` | kein fester Umbruch im Text |
| Ab neun Profilzeilen | – | Zeilenabstand 30 pt, Trennlinie 25,8 pt | Neunte Zeile „Weitere Bereiche“ (nur falls belegt) liefe sonst über; im Auftrag nicht vorgesehen, bitte bestätigen |
| Intro Seite 5 | Zeile 1 endet bei x 550,9 | Spalte 1 pt breiter (`margin-right: -1pt`) | sonst rutscht „besprechen“ in Zeile 2 |

## Offene Punkte

1. **Pakete in Prod:** Merkmale lauten „1 Session/Woche“, „Basis-Lernpfad“ …, das Muster zeigt „1
   Session pro Woche“ / „1 Fach“. Premium hat „Woechentlicher Report“ (ae/oe statt Umlaut) — erscheint
   so nicht, solange nur Merkmal 1 und 2 gedruckt werden, steht aber in den Daten. Pflege in
   `/admin` (Tarife), nicht im Bericht.
2. **Lange Paketnamen oder Merkmale:** Die Karten sind SVG und brechen nicht um. Die heutigen Werte
   passen (längstes Merkmal etwa 25 Zeichen, Innenbreite 135 pt). Längere Texte werden am
   Kartenrand abgeschnitten (clipPath), nicht umbrochen. Bei vier aktiven Paketen (Innenbreite
   92 pt) betrifft das schon „1,5 Sessions pro Woche“ — dann ohnehin keine Hervorhebung.
3. **Nicht genau drei aktive Pakete:** keine Hervorhebung, im Navy-Kasten nur die Empfehlung,
   `console.warn` im Browser. In Prod sind es heute genau drei.
4. **Ansprechpartner mit Namen, aber ohne Mail:** Name und Rolle stehen, die Mail-Zeile entfällt
   (kein Rückfall auf hello@, damit nicht eine fremde Adresse unter einem Namen steht).
5. **Grenze Seite 2:** Mit acht Zeilen bleiben bei `ilkay` 26 pt und bei `ohneName` 16 pt Luft.
   Ein Rufname ab etwa 30 Zeichen (Titel dreizeilig) zusammen mit acht Zeilen passt nicht mehr;
   der Druck-Test fängt das nur für die vorhandenen Fixtures. Ein Fixture mit „Weitere Bereiche“
   und eines mit sehr langem Namen gehören ins Foundation-Fenster (`src/lib/**`).

## Zweitprüfung

Frische Instanz: nichts blockierend; Seite 5 und die Rechnung abnahmefähig. Umgesetzt: Regel für
neun Profilzeilen (gemessen liefe `ohneName` sonst 17 pt über), Clip für Paketnamen und Merkmale,
Intro Seite 5 wie im Muster, Vorlesetext ohne „davon 0 sicher …“ bei null untersuchten Bereichen
(neuer Schlüssel `s2.profil.ariaKeiner`), Coach-Satz unabhängig von den beiden anderen Sätzen.
