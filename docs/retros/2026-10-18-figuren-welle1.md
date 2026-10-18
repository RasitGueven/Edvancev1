# Retro 18.10.2026 · Figuren Welle 1 (F2)

## Gebaut

**PR 1 – Generatoren + Schema**
- `thales.py` + `pruefe_thales.py` (7 Pruefungen) + `test_thales.py`: Kreis/Halbkreis ueber AB, C auf dem Bogen,
  Winkelboegen mit Text. `c_grad` und `wahre_lage_grad` sind Pflicht und muessen mind. 10° auseinander liegen;
  ein Rechter-Winkel-Zeichen gibt es nicht. `pruefe` misst die Lage von C nach und meldet, wenn C an der wahren Lage sitzt.
- `rechtecke.py` + `pruefe_rechtecke.py` (5 Pruefungen) + `test_rechtecke.py`: zusammengesetzte Rechtecke in
  Skizzen-Einheiten (nicht massstaeblich), Masslinien nur fuer `masse`, Texte nur aus params, kein Gitter.
- `rechteck.ts` kann Masse als Text (`laenge_text`, `breite_text`, `verhaeltnis`). Pruefteil nach `rechteckParams.ts`
  ausgelagert (Dateigrenze 400). Fuer den Upload: `rechteck.py` ruft `rechteck_cli.ts` ueber tsx, `pruefe_rechteck.py`
  misst das SVG in Python nach.
- `GENERATOREN` in `upload_figures.py` + Migration `20261018170100` (CHECK); ein Test vergleicht beide Listen.
- Zusatz aus der Pruefung der App-Darstellung: Schrift 20, Striche Achse 2 / Kurve 4 / betont 5, Rand 44, Palette
  dunkel Gitter 0.30 / Beschriftung 0.80, jede zweite Funktion Gold. Groessen zentral in `tokens.py`, dieselben Werte in
  `svgBasis.ts`/`rechteck.ts`.
- `PreviewStage`: Abbildungen liegen auf der dunklen Buehnenflaeche.

## Entscheidungen
- **Vorschau-Fehler gefunden und behoben:** Die Pruef-Vorschau legte die Figur auf die weisse Aufgabenkarte. Die Figuren
  sind fuer die dunkle Tablet-Buehne gezeichnet (Creme), dort waren sie kaum sichtbar, auch die fuenf LGS-Figuren.
  Auf dem Tablet liegt die Abbildung ohne Karte auf der Buehne (`Buehne.tsx`, Text in Creme). Fix in PR 1, weil Lena
  Stufe 3 am 22.–23.10. in genau dieser Vorschau prueft.
- `rechteck.ts` bleibt TypeScript; der Python-Adapter vermeidet eine zweite Implementierung derselben Figur.
- Groessen auch fuer `rechteck.ts` uebernommen (nicht ausdruecklich verlangt), damit die zwei Rechteck-Aufgaben nicht
  kleiner und duenner aussehen als ihre Nachbarn.

## Offen
- `svg_hash` haengt nur an generator + params. Ein `--force`-Upload ueberschreibt die Dateien unter derselben URL;
  Clients mit gecachter Datei sehen die alte Fassung, bis der Cache verfaellt.
- Koordinatensystem: An der Ecke unten links stehen „-1“ der x-Achse, „0“ und „-1“ der y-Achse eng beieinander (z. B.
  0315634a). War vorher genauso, mit Schrift 20 faellt es mehr auf.
- `scripts/figures/` hat keinen CI-Job; die Python-Tests laufen nur lokal.

## PR 2 – Daten
- `docs/figuren/welle1.json`: 13 Figuren-Specs (6 thales, 5 rechtecke, 2 rechteck), Quelle `bedarf.json` aus F1.
  Abweichungen zur Spec: 5b36238f mit Texten innen an den Beetkanten statt Masslinien (Masslinien kreuzten sich),
  3a42b89c mit dem Flaecheninhalt ueber der Figur statt in der Mitte; alt-Texte entsprechend angepasst.
- `tools/figuren-welle1.py`: Konsistenz (pruefe in beiden Themes, Zahlen und Bezeichnungen der Figur stehen im
  Aufgabentext, keine Loesungszahl in der Figur, alt-Text ohne Ziffern) und Migration aus derselben Quelle.
- Migration `20261018170200`: je Aufgabe nur bei gleichem Aufgabentext (md5) und ohne vorhandene Figur;
  `svg_hash` bleibt leer, sichtbar wird die Figur erst nach `upload_figures.py`.
- Im Neuaufbau wie die CI legt die Migration 11 von 13 an: f8364853 und 113aea0a gibt es dort nicht (nur in Prod).
