/**
 * SVG-Grundlagen und Farben fuer die TypeScript-Generatoren.
 *
 * Das TS-Gegenstueck zu `svg_basis.py` + `tokens.py` (PR #96) — gleiche
 * Zerlegung, gleiche Namen, gleiche Begruendungen. Es ist eine Uebersetzung,
 * keine Neuerfindung: weicht hier etwas von der Python-Seite ab, ist das ein
 * Fehler und keine Variante.
 *
 * HIER HAENGT DER DETERMINISMUS. Gleiche Parameter muessen ein byteidentisches
 * SVG ergeben, und die drei Stellen, an denen das kippt, sind alle hier:
 *
 * 1. ZAHLEN. `String(0.1 + 0.2)` ist '0.30000000000000004'. Jede Koordinate
 *    laeuft deshalb durch `zahl()`: feste Rundung, danach ein kanonischer String.
 * 2. MINUS NULL. `-0` ist ein voellig normales Rechenergebnis (etwa aus
 *    `0 * -1`) und wuerde als '-0' im Dokument landen — dieselbe Geometrie,
 *    anderes Byte. `zahl()` faengt es ab.
 * 3. REIHENFOLGE. Attribute werden als LISTE von Paaren gefuehrt, nie aus einem
 *    Objekt iteriert, das irgendwo unterwegs neu aufgebaut wurde.
 *
 * Was hier bewusst NICHT vorkommt: Zeitstempel, Zufalls-IDs, Hashes ueber
 * Speicheradressen. Ein Generator, dessen Ausgabe sich zwischen zwei Laeufen
 * unterscheidet, ist beim Diffen wertlos — und `task_figures.svg_hash` traegt
 * dann nichts.
 */

// Zwei Nachkommastellen sind feiner als ein Bildschirm- oder Druckpunkt. Mehr
// Stellen blaehen nur die Datei.
const STELLEN = 2

/** Kanonischer Zahlstring: gerundet, ohne Nullschwanz, ohne '-0'. */
export function zahl(wert: number): string {
  const gerundet = Math.round(wert * 10 ** STELLEN) / 10 ** STELLEN
  // Faengt -0 UND -0.001 ab: beide runden auf null, beide heissen '0'.
  if (gerundet === 0) return '0'
  const text = gerundet.toFixed(STELLEN)
  return text.includes('.') ? text.replace(/0+$/, '').replace(/\.$/, '') : text
}

/** Ein Mass fuer die Beschriftung — deutsches Dezimalkomma statt Punkt. */
export function mass(wert: number): string {
  return zahl(wert).replace('.', ',')
}

/**
 * Escaped Zeichendaten. Beschriftungen kommen aus Aufgabeninhalten, also aus
 * fremder Hand — ein '<' darf das Dokument nicht zerlegen.
 */
export function textEscape(roh: string): string {
  return roh.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
}

/** Wie `textEscape`, zusaetzlich die Anfuehrungszeichen des Attributwerts. */
export function attrEscape(roh: string): string {
  return textEscape(roh).replace(/"/g, '&quot;')
}

/**
 * Ein Farbwert plus Deckkraft — GETRENNT, und das ist der ganze Punkt.
 *
 * `stroke="rgba(247,245,238,0.55)"` ist in SVG 1.1 kein gueltiger
 * Praesentationsattribut-Wert. Renderer verwerfen ihn und fallen auf den
 * Vorgabewert zurueck: Schwarz. Auf der dunklen Buehne heisst das schwarze
 * Linien auf Navy — eine Abbildung, die fachlich stimmt und trotzdem unlesbar
 * ist. (Genau so gesehen, Inkscape-Probe 23.07.2026.) Richtig ist die Trennung
 * in Farbe und `*-opacity`; das versteht jeder Renderer, auch react-native-svg
 * und aeltere Druck-Pipelines.
 */
export interface Farbe {
  hex: string
  deckkraft: number
}

export function farbAttribute(rolle: 'stroke' | 'fill', farbe: Farbe): [string, string][] {
  const attribute: [string, string][] = [[rolle, farbe.hex]]
  if (farbe.deckkraft < 1) attribute.push([`${rolle}-opacity`, zahl(farbe.deckkraft)])
  return attribute
}

/**
 * Ein SVG-Element. Attribute als LISTE von Paaren — die Reihenfolge im Output
 * ist damit die Reihenfolge im Aufruf und nicht die Laune einer Objektliteral-
 * Umsortierung.
 */
export function element(name: string, attribute: [string, string][], inhalt?: string): string {
  const teile = attribute.map(([k, v]) => `${k}="${v}"`).join(' ')
  const kopf = teile ? `<${name} ${teile}` : `<${name}`
  return inhalt === undefined ? `${kopf}/>` : `${kopf}>${inhalt}</${name}>`
}

export function linie(
  x1: number,
  y1: number,
  x2: number,
  y2: number,
  farbe: Farbe,
  breite: number,
): string {
  return element('line', [
    ['x1', zahl(x1)],
    ['y1', zahl(y1)],
    ['x2', zahl(x2)],
    ['y2', zahl(y2)],
    ...farbAttribute('stroke', farbe),
    ['stroke-width', zahl(breite)],
    ['stroke-linecap', 'round'],
  ])
}

/**
 * Offener Streckenzug. `fill="none"` ist Pflicht: ohne das fuellt der Renderer
 * die aufgespannte Flaeche schwarz — der klassische Weg zu einem Bild, das
 * richtig gerechnet und trotzdem unbrauchbar ist.
 */
export function polylinie(punkte: [number, number][], farbe: Farbe, breite: number): string {
  return element('polyline', [
    ['points', punkte.map(([x, y]) => `${zahl(x)},${zahl(y)}`).join(' ')],
    ['fill', 'none'],
    ...farbAttribute('stroke', farbe),
    ['stroke-width', zahl(breite)],
    ['stroke-linecap', 'round'],
    ['stroke-linejoin', 'round'],
  ])
}

/**
 * Fallback-Kette statt blossem Familiennamen: Eine extern geladene SVG hat
 * keinen garantierten Zugriff auf die App-Fonts. Ohne Kette faellt der Renderer
 * auf eine Serife zurueck und die Abbildung sieht aus wie aus einem anderen
 * Produkt.
 */
export const SCHRIFT = 'Schibsted Grotesk, Helvetica, Arial, sans-serif'
export const SCHRIFTGROESSE = 13

/**
 * Ein Textknoten.
 *
 * `dominant-baseline` wird von aelteren Renderern unterschiedlich ausgelegt;
 * fuer Bildschirm und Druck reicht es. Wenn die Geraeteprobe zeigt, dass Zahlen
 * verrutschen, ist das die Stelle — dann wird die Grundlinie gerechnet statt
 * deklariert.
 */
export function beschriftung(
  x: number,
  y: number,
  inhalt: string,
  farbe: Farbe,
  anker: 'start' | 'middle' | 'end',
): string {
  return element(
    'text',
    [
      ['x', zahl(x)],
      ['y', zahl(y)],
      ...farbAttribute('fill', farbe),
      ['font-family', attrEscape(SCHRIFT)],
      ['font-size', zahl(SCHRIFTGROESSE)],
      ['text-anchor', anker],
      ['dominant-baseline', 'middle'],
    ],
    textEscape(inhalt),
  )
}

/**
 * Der Rahmen. OHNE Hintergrundrechteck — die Abbildung ist transparent und
 * liegt auf ihrem Traeger (dunkle Buehne oder weisses Papier), sie bringt
 * keinen eigenen mit.
 *
 * `viewBox` deckt exakt die Pixelmasse, damit 1 Nutzereinheit = 1 px bleibt und
 * die Figur auch nach dem Skalieren unverzerrt ist.
 */
export function dokument(breite: number, hoehe: number, inhalt: string[]): string {
  const kopf =
    `<svg xmlns="http://www.w3.org/2000/svg" ` +
    `width="${zahl(breite)}" height="${zahl(hoehe)}" ` +
    `viewBox="0 0 ${zahl(breite)} ${zahl(hoehe)}" ` +
    `role="img">`
  return [kopf, ...inhalt, '</svg>', ''].join('\n')
}

// ── Farben (gemessen, nicht erfunden) ────────────────────────────────────────
//
// Jeder Hexwert unten steht so in `src/styles/tokens.css` (Herkunft als
// Kommentar dahinter) und deckt sich mit `GEMESSEN` in tokens.py. Nichts hier
// ist eine Designentscheidung dieses Moduls; die einzige Entscheidung ist die
// ZUORDNUNG von Token zu Rolle.
//
// ZWEI THEMES, WEIL ZWEI TRAEGER: 'dunkel' ist die Schueler-Buehne (Navy),
// 'hell' der Eltern-Report auf Papier. Ein Schema kann beides nicht — was auf
// Navy traegt, ist auf Papier unsichtbar.

export type Theme = 'dunkel' | 'hell'
export const THEMES: readonly Theme[] = ['dunkel', 'hell']

/** Die drei Rollen, die eine Figur braucht. Mehr gibt es nicht. */
export interface Palette {
  /** Umriss und Bruchzeichen — die lauteste Ebene. */
  kontur: Farbe
  /** Seitenmasse und Winkelzeichen — leiser als der Umriss. */
  beschriftung: Farbe
  /** Hervorgehobene Hilfslinien (Diagonale) — Gold. */
  betont: Farbe
}

const PALETTEN: Record<Theme, Palette> = {
  dunkel: {
    kontur: { hex: '#F7F5EE', deckkraft: 1 }, // tokens.css:136 color-stage-text
    beschriftung: { hex: '#F7F5EE', deckkraft: 0.55 }, // dito, Stufe alpha.creamMuted
    betont: { hex: '#D4A843', deckkraft: 1 }, // tokens.css:56  color-gold-altgold
  },
  hell: {
    kontur: { hex: '#102038', deckkraft: 1 }, // tokens.css:65  color-report-navy
    beschriftung: { hex: '#4A4A47', deckkraft: 1 }, // tokens.css:46  color-text-secondary
    betont: { hex: '#DA9721', deckkraft: 1 }, // tokens.css:66  color-report-gold
  },
}

/** Palette zum Theme — und ein lauter Fehler bei einem unbekannten Namen. */
export function palette(theme: unknown): Palette {
  if (typeof theme !== 'string' || !THEMES.includes(theme as Theme)) {
    const erlaubt = THEMES.map((t) => JSON.stringify(t)).join(', ')
    throw new Error(`theme muss eines von ${erlaubt} sein, nicht ${JSON.stringify(theme) ?? String(theme)}.`)
  }
  return PALETTEN[theme as Theme]
}
