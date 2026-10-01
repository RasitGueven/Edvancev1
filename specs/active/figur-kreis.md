---
id: figur-kreis
type: code
repo: edvancev1
branch: spec/figur-kreis
depends_on: []
gates:
  - python3 -m pytest scripts/figures/test_kreis.py -q
  - python3 -c "import sys; sys.path.insert(0,'scripts/figures'); import kreis, pruefe_kreis"
  - bash -c 'test $(grep -c "^def pruefe_" scripts/figures/pruefe_kreis.py) -ge 5'
  - bash -c 'grep -q "negativkontrolle\|Negativkontrolle" scripts/figures/test_kreis.py'
  - bash tools/neuaufbau-test.sh
  - bash -c 'grep -rl "task_figures_generator" supabase/migrations/ | xargs grep -lq "kreis"'
---

## Ziel

Ein parametrischer SVG-Generator für **Kreisfiguren**, nach dem Muster von
`scripts/figures/winkel.py` und `scripts/figures/koordinatensystem.py`. Er trägt die
Aufgaben zu `geo_kreis_zusammen` (Klasse 9, KLP G9 NRW Geo-3): Halbkreis,
Viertelkreis, Kreisring, Rechteck mit aufgesetztem Halbkreis. Dazu kommt der
Kreisausschnitt, damit `geo_kreis_sektor` später ebenfalls Bildaufgaben bekommen kann.

## Kontext

**Erst `winkel.py`, `pruefe_winkel.py`, `koordinatensystem.py` und
`pruefe_koordinatensystem.py` lesen.** Das Muster steht dort vollständig. Es wird
übernommen, nicht neu erfunden.

Der Aufbau hat zwei Teile:

- **`scripts/figures/kreis.py`** mit `zeichne(params: dict, theme: str) -> str`
- **`scripts/figures/pruefe_kreis.py`** mit `pruefe(svg: str, params: dict) -> tuple[bool, str]`

`pruefe` ist der wichtigere Teil. Es **liest das erzeugte SVG zurück und misst nach**.
Mittelpunkte, Radien und Bogenendpunkte werden aus dem SVG-Text rekonstruiert und
gegen die Parameter gehalten. `bestanden == True` gilt nur bei leerer Befundliste.

Beim Kreis ist ein Fehler genauso unauffällig wie beim Winkel. Ein Halbkreis mit dem
Sweep-Flag auf der falschen Seite liegt im Rechteck statt darauf: Die Figur sieht
ordentlich aus, aber die Fläche ist Rechteck **minus** Halbkreis, nicht plus. Ein
Kreisausschnitt mit vertauschtem Large-Arc-Flag zeigt 270° statt 90°. Deshalb misst
`pruefe` den **überstrichenen** Bogen nach und nicht nur seine Endpunkte.

Weiteres:

- `svg_basis.py` liefert Zahlformatierung, Escaping und Element-Bau. Importieren,
  nicht nachbauen.
- `tokens.py` ist die **einzige** Quelle für Farbwerte. Keine Hex-Codes im Generator.
- `pruefungen.py` enthält die gemeinsamen Eingabeprüfungen. Parameter werden **vor**
  dem Zeichnen geprüft. Unbekannte Schlüssel sind ein Fehler, kein stiller Verzicht.
- Gerendert wird über react-native-svg: kein CSS, keine externen Schriften, kein
  `<foreignObject>`. Bögen als `<path d="M … A …">`. **Keine** `<circle>`-Kurzform
  für Teilkreise.
- **alt-Text:** kommt nicht aus dem Generator. `task_figures` trägt den CHECK
  `alt_text !~ '[0-9]'`, damit ein Screenreader nicht die Maße vorliest.

## Formen und Parameter

| Schlüssel | Typ | Pflicht bei | Bedeutung |
|---|---|---|---|
| `form` | str | immer | `kreis`, `halbkreis`, `viertelkreis`, `sektor`, `kreisring`, `rechteck_halbkreis` |
| `radius` | float > 0 | immer | Außenradius in der Aufgabeneinheit |
| `innenradius` | float, 0 < x < radius | `kreisring` | Radius des inneren Kreises |
| `winkel` | float, 1..359 | `sektor` | Mittelpunktswinkel in Grad |
| `rechteck_hoehe` | float > 0 | `rechteck_halbkreis` | Die andere Rechteckseite. Die Breite ist **immer** 2·radius, denn der Halbkreis sitzt auf der ganzen Seite. |
| `masse` | list[str] | optional | Welche Maße beschriftet werden: `r`, `d`, `ri`, `h`, `alpha`. Leer bedeutet, dass nichts beschriftet wird (für Aufgaben, die das Maß im Text nennen). |
| `einheit` | str | optional | `mm`, `cm`, `m`. Erscheint an den Maßen. |

Unbekannte Werte für `form` und unbekannte Schlüssel sind Fehler. `innenradius >=
radius` ist ein Fehler, und `winkel` außerhalb von 1..359 ist ein Fehler. Für einen
vollen Kreis gibt es `form: kreis`.

## Geometrie

- Fester Rahmen: Die viewBox hängt nicht von den Parametern ab. Die Figur wird so
  skaliert, dass sie hineinpasst. Ein Maßstab wird nicht behauptet, die Proportionen
  stimmen aber.
- Der Mittelpunkt wird als kleiner Punkt markiert, solange `r` oder `d` beschriftet ist.
- `r` ist eine Strecke vom Mittelpunkt zum Rand. `d` ist eine Strecke durch den
  Mittelpunkt von Rand zu Rand. Beide dürfen nie dieselbe Linie sein.
- `halbkreis`: Der Durchmesser liegt waagerecht unten, der Bogen oben. Die gerade
  Kante wird **gezeichnet**, denn sie gehört zum Umfang (Fehlbild „gerade Kante beim
  Halbkreisumfang vergessen").
- `viertelkreis`: Die zwei Radien liegen auf den Achsen, mit dem rechten Winkel als
  Zeichen am Mittelpunkt (wie bei `winkel.py` bei 90°).
- `sektor`: Der erste Schenkel liegt waagerecht nach rechts, der Bogen läuft gegen den
  Uhrzeigersinn über `winkel` Grad. Das Winkelzeichen sitzt innen am Mittelpunkt.
- `kreisring`: zwei konzentrische Kreise mit gefülltem Ring. Der Innenkreis bleibt
  ungefüllt.
- `rechteck_halbkreis`: Das Rechteck steht unten, der Halbkreis sitzt **außen** auf
  der oberen Seite. Die gemeinsame Kante wird nicht als Umfangslinie gezeichnet,
  sondern gestrichelt.

## Was `pruefe` messen muss

- **Rahmen:** Alles Gezeichnete liegt in der viewBox.
- **Radius:** Der Bogenradius aus dem `A`-Kommando stimmt mit dem Abstand zwischen
  Mittelpunkt und Bogenendpunkten überein (rx = ry, Kreis statt Ellipse).
- **Überstrichener Winkel (Kernprüfung):** Der aus Start, Ende, Large-Arc- und
  Sweep-Flag rekonstruierte Bogen überstreicht 180° (Halbkreis), 90° (Viertelkreis)
  oder `winkel` (Sektor).
- **Lage beim Rechteck mit Halbkreis:** Der Bogenmittelpunkt liegt **außerhalb** des
  Rechtecks, und die Bogenendpunkte fallen auf die beiden oberen Ecken.
- **Konzentrik beim Ring:** Beide Mittelpunkte fallen zusammen, und das gemessene
  Verhältnis innen zu außen ist `innenradius/radius`.
- **Proportion:** Beim Rechteck mit Halbkreis ist das Pixelverhältnis von
  Rechteckhöhe zu Radius gleich `rechteck_hoehe/radius`.
- **Beschriftung:** Jedes Maß in `masse` steht an seiner Strecke. Für ein Maß, das
  nicht in `masse` steht, gibt es keinen Text.

Wie im Vorbild braucht der Test eine **Negativkontrolle**. Ein absichtlich
verfälschtes SVG (Sweep-Flag gekippt, sodass der Halbkreis nach innen zeigt) muss von
`pruefe` abgelehnt werden.

## Akzeptanz

- `scripts/figures/kreis.py` mit `zeichne(params, theme)`, Signatur wie im Vorbild
- `scripts/figures/pruefe_kreis.py` mit `pruefe(svg, params) -> (bestanden, meldung)`
  und mindestens fünf `pruefe_*`-Einzelprüfungen
- gültiges SVG mit fester `viewBox`
- Gleiche Parameter ergeben byteweise gleiches SVG, damit `svg_hash` trägt.
- Ungültige Parameter lösen vor dem Zeichnen einen klaren Fehler aus.
- `scripts/figures/test_kreis.py` deckt jede Form ab, dazu Randwerte (winkel 1 und
  359, innenradius knapp unter radius), ungültige Parameter, Reproduzierbarkeit, beide
  Themes und die **Negativkontrolle**.
- **Migration**, die den CHECK `task_figures_generator_check` (heute
  `koordinatensystem`, `winkel`) um `'kreis'` erweitert. Die Historie ist append-only:
  Es kommt eine neue Datei mit sekundengenauer Version (`date -u +%Y%m%d%H%M%S`) dazu.
  Danach `bash tools/schema-snapshot.sh` laufen lassen und `supabase/schema-erwartet.sql`
  mitcommitten.
- **Nicht in Produktion einspielen.** Das übernimmt Rasit von Hand.

## Vorbehalt: `upload_figures.py`

Nach dem Muster müsste `kreis` in `upload_figures.py` in `_lade_generator`
eingetragen werden. Der Auftrag W1-3 sagt aber: **`upload_figures` nicht anfassen.**
Dieser Schritt ist deshalb **nicht** Teil der Spec. Er braucht eine eigene Freigabe von
Rasit, sobald der Generator steht. Bis dahin lässt sich der Generator testen, aber
nicht hochladen.

## Nicht-Ziele

- Keine TypeScript-Fassung (`rechteck.ts` und `svgBasis.ts` sind ein Irrläufer).
- Keine Farbwerte außerhalb von `tokens.py`
- Keine Änderung an `winkel.py`, `koordinatensystem.py`, ihren Prüfmodulen,
  `svg_basis.py`, `tokens.py`, `pruefungen.py` oder `upload_figures.py`
- Keine Anbindung an konkrete Aufgaben und keine `task_figures`-Zeilen
- Keine Interaktivität, keine Animation
