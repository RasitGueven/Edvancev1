# Retro R7-12 · Lernweg passt immer, 22.10.2026

Anlass: Tolunays LSA mit 70 Aufgaben, fast alles falsch. Seite 3 schnitt den Lernweg unten stumm ab,
die volle Karte in Station 03 auch. Bauauftrag `docs/report/r7/Bauauftrag-R7-12.md`.

## Gebaut
- **Rechnung:**
  - `lernwegKanten.ts`: `Grenzen` mit `eintraegeJeInsel` und `zusammenfassen`; `KUERZUNGEN` mit den
    Stufen 4–7; `STUFE_BEREICHE = 4`.
  - `lernwegKuerzen.ts` (neu): `kuerzeLernweg` aus `lernweg.ts` hierher verschoben (dort weiter
    exportiert), dazu `waehleZeilen` (Vorrang a–d) und das Zusammenfassen von Zonen.
  - Typen: `LwWeitere`, `LwZaehlzeile`, `LwZusammen`; `weggelassen` zählt `eintraege` und `zonen`.
- **Bogen:** Seite 3 geht alle acht Stufen durch. Danach `data-ueberlauf` und `console.warn`. Fußnote
  ab Stufe 4 bei Kürzung. „+ n weitere“ und die Zählzeilen in `Lernweg.tsx`, Maße wie Unterzeile bzw.
  Eintrag.
- **Bühne:** Station 03 zeigt die volle Karte ab Stufe 4. Ragt eine Insel bei S_MIN über die Fläche,
  nimmt sie beim ersten Messen die nächste Stufe, danach nicht mehr. „+ n weitere“ ist ein Knopf und
  füllt das Infofeld („Weitere Bereiche: …“). Zusammengefasste Zonen als Zählzeilen mit Anker für
  die Linien.
- **Fixture** `sehrViele`: 60 direkt geprüft (12 aus Klasse 5–6, je 24 aus 7–8 und 9–10), jeder achte
  sicher.
- **Tests:** `lernwegKuerzen.test.ts` (16), `Station3.weitere.test.tsx`;
  `e2e-druck/lernweg-grenzen.spec.ts` (Fotos aller Fälle, Fußnote, kein Überlauf);
  `e2e-praesentation/lernweg-grenzen.spec.ts` (keine Insel unter der Spur, keine Linie durch eine
  Insel, Infofeld).
- **Nebenbei:** `Station3.fluss.test.tsx` war auf dev rot (PF-1 und PS-1 parallel gemergt): Der Test
  öffnet jetzt erst die volle Karte.

## Ergebnisse
- `sehrViele`: Seite 3 auf Stufe 5, volle Karte auf Stufe 4 (iPad quer).
- Entscheidung 7: Seite 2 zeigt keine Liste der Bereiche, nur die Zahl je Themenfeld. Fußnote nach
  Rücksprache: „… Wie viele es je Themenfeld sind, steht auf Seite 2.“
- Seite 3 aller anderen Fälle pixelgleich, bis auf Kantenglättung im Kopf bei ohneKanten und
  planOhneThema.

## Gelernt
- Bei reduzierter Bewegung hat jedes Element eine Transition von .01ms (`rahmen.css`). Wer Layout
  synchron misst, nachdem er eine Größe gesetzt hat, sieht dann noch den alten Wert.

## Offen
`docs/report/r7/offene-punkte-r7-12.md`: Stufe 4 kürzt in der Bühne auch Linien und Kommt noch;
Seite 2 läuft bei 24 Bereichen in einem Feld über; Texte für Lena.
