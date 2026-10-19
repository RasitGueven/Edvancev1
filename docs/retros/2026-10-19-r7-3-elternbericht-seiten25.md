# Retro 19.10.2026 – R7-3 · Seite 2 (Lernstand) und Seite 5 (Nächste Schritte)

## Gebaut
- Seite 2: Kicker, Titel mit Genitiv, Intro, drei Zahlen mit Farbbalken (ein SVG in
  Seitenkoordinaten), Kompetenzprofil je Themenfeld (`Profil.tsx`), Legende, „Was die Grafik
  zeigt“ und Fußnote.
- Reine Rechnung `seite2Rechnung.ts`: Segmente (Spur 226 pt, Lücke 4/2/1, Radius ≤ Breite/3),
  Zeilenabstand, rechte Unterzeile, Auswahl der Felder für „Was die Grafik zeigt“.
- Seite 5: Navy-Kasten mit Chip, Titel und Vorschlagszeile; Mitgliedschaften als SVG-Karten
  (`Mitgliedschaften.tsx`), Zuordnung des Coach-Vorschlags in `seite5Rechnung.ts`; Kontakt-Kasten
  mit Ansprechpartner oder Team-Adresse.
- Zwei neue Schlüssel: `s2.profil.trenner`, `s2.profil.ariaKeiner`.

## Entscheidungen
- Profilzeilen und Karten als SVG (1 Einheit = 1 pt): Grundlinien, Spur und Segmente liegen exakt,
  berechnete Werte stehen als Attribute, nicht als Inline-Style (INV-4.11).
- Die Schraffur liegt als zweite Fläche über einer weißen; eine CSS-Füllung hätte das
  `fill="url(#eb-schraffur)"` überschrieben (erster Versuch zeigte deshalb keine Schraffur).
- Enger Modus ab sieben Profilzeilen statt kleinerer Schrift: Ilkay lief mit Muster-Abständen über
  (Fußnote bis y 806).

## Ergebnis
- Seite 5 auf 0,2 pt am Muster; Seite 2 überall mit mindestens 16 pt Luft bis y 800.
- Vitest 1419 grün, Druck-Tests 13/13.

## Offen
- `docs/report/r7/offene-punkte-r7-3.md`: Merkmale der Pakete in Prod, lange Texte in den Karten.
