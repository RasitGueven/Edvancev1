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
- Achsenzahlen ohne Ueberlappung (`achsenzahlen.py`): Stammplatz, sonst andere Achsenseite, sonst weglassen; die 0
  einmal links unter dem Ursprung (Ausweichplaetze, wenn eine Gerade durch den Ursprung geht); Titel weichen aus.
  `pruefe_koordinatensystem.pruefe_beschriftung_frei` prueft Ueberlappung und Zahlen auf Kurven, mit zwei
  Negativkontrollen.
- Knappe viewBox fuer winkel, thales, rechtecke (Rasit, 18.10.): Umriss alles Gezeichneten plus 16 px Rand
  (`svg_basis.dokument_knapp`), geprueft von `pruefe_knapper_rahmen` (nichts ragt hinaus, kein Rand groesser als 16).

## Entscheidungen
- **Vorschau:** Die Figuren lagen in der Pruef-Vorschau auf der weissen Karte und waren kaum sichtbar. Mein Fix in
  PreviewStage ist wieder raus; #270 (fix/vorschau-figuren) loest das, PR 1 setzt darauf auf.
- `rechteck.ts` bleibt TypeScript; der Python-Adapter vermeidet eine zweite Implementierung derselben Figur.
- Groessen auch fuer `rechteck.ts` uebernommen (nicht ausdruecklich verlangt), damit die zwei Rechteck-Aufgaben nicht
  kleiner und duenner aussehen als ihre Nachbarn.

## Offen
- `svg_hash` haengt nur an generator + params. Ein `--force`-Upload ueberschreibt die Dateien unter derselben URL;
  Clients mit gecachter Datei sehen die alte Fassung, bis der Cache verfaellt.
- Achsenzahlen (achsenzahlen.py): Wo eine Gerade durch den Platz einer Zahl laeuft und auch die andere Achsenseite
  belegt ist, entfaellt die Zahl; das Gitter zeigt den Massstab weiter. In den LGS-Figuren fehlen dadurch einzelne Zahlen.
- `koordinatensystem.py` hat 412 Zeilen (vorher 431), die Grenze von 400 ist weiter ueberschritten.
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
