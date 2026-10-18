/**
 * Parametrischer Generator: ein Rechteck oder Quadrat.
 *
 * VORLAGE IST `koordinatensystem.py` (PR #96) — dieselbe Ablage
 * (scripts/figures/), dieselbe Zerlegung (Grundlagen/Farben in svgBasis,
 * Pruefungen vor dem Zeichnen, `zeichne(params, theme)` als Adapter fuer
 * upload_figures.py / A19). ANDERE SPRACHE, und das ist eine bewusste
 * Abweichung: die Gates dieser Aufgabe sind `npm run typecheck` und
 * `npm test -- figur-rechteck` mit den Tests in `tests/figur-rechteck.test.ts`.
 * Ein Python-Modul bedient beides nicht. Die Schnittstelle nach aussen bleibt
 * die der Vorlage, damit der Adapter in upload_figures.py nur einen Aufrufweg
 * mehr braucht und keine neue Form. Der Koordinatensystem-Generator selbst
 * bleibt unberuehrt.
 *
 * WARUM SORGFALT: Ein falsches Bild ist schlimmer als kein Bild. Bei Text
 * faellt ein Fehler in der fachlichen Pruefung auf; einen Zahlendreher in der
 * Skalierung sieht niemand. Darum faellt hier alles durch, was sich nicht
 * sauber darstellen laesst — laut, mit Klartext und der Stelle im Aufruf. Es
 * gibt keinen stillen Verzicht: ein unbekannter Schluessel ('laenger' statt
 * 'laenge') ist ein Fehler und kein Rechteck mit fehlendem Mass.
 *
 * MASSSTAEBLICH, SOLANGE ES EHRLICH GEHT: Das gezeichnete Seitenverhaeltnis IST
 * das echte, solange es zwischen 1:4 und 4:1 liegt. Darueber hinaus wird auf
 * den Bandrand gekappt — ein 1:40-Rechteck waere auf einer festen Buehne ein
 * Strich. Die Kappung wird NICHT verschwiegen: die verkuerzt gezeichneten
 * Seiten tragen ein Bruchzeichen (Zickzack), und der alt-Text sagt es. Eine
 * stille Stauchung waere genau der Fall, den niemand nachsieht.
 *
 * FESTE BUEHNE: `viewBox` ist immer "0 0 320 240", unabhaengig von den
 * Parametern. Der Client bekommt eine Abbildung mit vorhersagbarem Platzbedarf;
 * die Figur skaliert INNERHALB der Buehne.
 *
 * REACT-NATIVE-TAUGLICH: nur <line>, <polyline>, <text>. Kein CSS, keine
 * class/style-Attribute, kein <foreignObject>, keine Schrift ohne
 * Fallback-Kette, kein rgba() (siehe `Farbe` in svgBasis).
 *
 * KEIN i18n: Der Generator laeuft serverseitig und schreibt nach
 * `task_figures.alt_text` — Datenbankinhalt, und der ist in CLAUDE.md §12
 * ausdruecklich von der i18n-Schicht ausgenommen. Uebersetzt wird eine
 * Abbildung spaeter ueber einen zweiten alt-Text in der DB, nicht ueber einen
 * Key im Frontend.
 */

import {
  beschriftung,
  dokument,
  type Farbe,
  linie,
  mass,
  palette,
  polylinie,
  type Theme,
} from './svgBasis'
import { fehler, pruefeParams, type RechteckParams, VERHAELTNIS_MAX, zeige } from './rechteckParams'

export { MASS_MAX, MASS_MIN, type RechteckParams, VERHAELTNIS_MAX, VERHAELTNIS_TEXT_STANDARD } from './rechteckParams'

// ── Buehne ───────────────────────────────────────────────────────────────────
// Fest, nicht aus den Parametern gerechnet. Die Raender tragen die Masse: links
// die Breite (rechtsbuendig, laengster Fall "1000 cm" bei Schrift 20), unten die Laenge.
export const BUEHNE_BREITE = 320
export const BUEHNE_HOEHE = 240
const RAND_LINKS = 104
const RAND_RECHTS = 24
const RAND_OBEN = 24
const RAND_UNTEN = 48
const FLAECHE_BREITE = BUEHNE_BREITE - RAND_LINKS - RAND_RECHTS // 192
const FLAECHE_HOEHE = BUEHNE_HOEHE - RAND_OBEN - RAND_UNTEN // 168

// Wie tokens.py: STARK_KURVE, STARK_BETONT, STARK_ACHSE.
const STARK_KONTUR = 4
const STARK_BETONT = 5
const STARK_WINKEL = 2

// ── Geometrie ────────────────────────────────────────────────────────────────

interface Lage {
  x0: number
  y0: number
  x1: number
  y1: number
  gestauchtWaagerecht: boolean
  gestauchtSenkrecht: boolean
}

/**
 * Ort und Groesse des Rechtecks auf der festen Buehne.
 *
 * Das gezeichnete Verhaeltnis IST das echte, solange es im Band [1:4, 4:1]
 * liegt; sonst wird es auf den Bandrand gekappt. Gekappt wird immer die Seite,
 * die zu lang waere — die traegt dann das Bruchzeichen. Weil die Kappung genau
 * dann greift, wenn das gezeigte Verhaeltnis 4 oder 0,25 ist, ist die gebrochene
 * Seite immer die lange (232 px bzw. 176 px): fuer ein Zickzack reicht das
 * sicher, es braucht keinen Sonderfall fuer kurze Seiten.
 *
 * Die Figur wird in der Zeichenflaeche ZENTRIERT, nicht linksbuendig gesetzt:
 * sonst wanderte sie bei jedem Verhaeltnis woanders hin und zwei Abbildungen
 * untereinander staenden versetzt.
 */
function lage(laenge: number, breite: number): Lage {
  const echt = laenge / breite
  const gezeigt = Math.min(Math.max(echt, 1 / VERHAELTNIS_MAX), VERHAELTNIS_MAX)

  let w: number
  let h: number
  if (gezeigt >= FLAECHE_BREITE / FLAECHE_HOEHE) {
    w = FLAECHE_BREITE
    h = FLAECHE_BREITE / gezeigt
  } else {
    h = FLAECHE_HOEHE
    w = FLAECHE_HOEHE * gezeigt
  }

  const x0 = RAND_LINKS + (FLAECHE_BREITE - w) / 2
  const y0 = RAND_OBEN + (FLAECHE_HOEHE - h) / 2
  return {
    x0,
    y0,
    x1: x0 + w,
    y1: y0 + h,
    gestauchtWaagerecht: gezeigt < echt,
    gestauchtSenkrecht: gezeigt > echt,
  }
}

const BRUCH_LUECKE = 9 // halbe Breite der Unterbrechung
const BRUCH_ZACKE = 5 // Ausschlag quer zur Seite

/**
 * Eine Seite des Rechtecks. Ungebrochen eine Linie; gebrochen zwei Linien mit
 * einem Zickzack dazwischen — das Zeichen dafuer, dass diese Seite verkuerzt
 * gezeichnet ist und ihre Laenge nur an der Beschriftung abzulesen ist.
 */
function seite(
  ax: number,
  ay: number,
  bx: number,
  by: number,
  gebrochen: boolean,
  farbe: Farbe,
): string[] {
  if (!gebrochen) return [linie(ax, ay, bx, by, farbe, STARK_KONTUR)]

  const len = Math.hypot(bx - ax, by - ay)
  const dx = (bx - ax) / len
  const dy = (by - ay) / len
  const mx = (ax + bx) / 2
  const my = (ay + by) / 2
  // Normale zur Seitenrichtung: der Ausschlag steht immer quer zur Seite,
  // gleich ob sie waagerecht oder senkrecht laeuft.
  const punkt = (laengs: number, quer: number): [number, number] => [
    mx + dx * laengs - dy * quer,
    my + dy * laengs + dx * quer,
  ]
  const [ex, ey] = punkt(-BRUCH_LUECKE, 0)
  const [fx, fy] = punkt(BRUCH_LUECKE, 0)

  return [
    linie(ax, ay, ex, ey, farbe, STARK_KONTUR),
    polylinie(
      [
        punkt(-BRUCH_LUECKE, 0),
        punkt(-BRUCH_LUECKE / 3, -BRUCH_ZACKE),
        punkt(BRUCH_LUECKE / 3, BRUCH_ZACKE),
        punkt(BRUCH_LUECKE, 0),
      ],
      farbe,
      STARK_KONTUR,
    ),
    linie(fx, fy, bx, by, farbe, STARK_KONTUR),
  ]
}

// ── alt-Text ─────────────────────────────────────────────────────────────────

/**
 * Beschreibt, WAS ZU SEHEN IST — nie, was die Antwort ist.
 *
 * KEINE ZIFFERN, und das ist kein Stilwunsch: `task_figures` traegt den CHECK
 * `alt_text !~ '[0-9]'` (A19). Ein Screenreader, der "Rechteck, fuenf mal drei
 * Zentimeter" vorliest, hat bei "Berechne den Flaecheninhalt" die Aufgabe
 * geloest. Die Masse stehen im BILD; der alt-Text sagt nur, WO sie stehen.
 */
export function altText(params: RechteckParams): string {
  const { laenge, breite, diagonale } = pruefeParams(params)
  const { gestauchtWaagerecht, gestauchtSenkrecht } = lage(laenge, breite)

  const teile: string[] = [
    laenge === breite
      ? 'Ein Quadrat'
      : laenge > breite
        ? 'Ein Rechteck mit der längeren Seite waagerecht'
        : 'Ein Rechteck mit der längeren Seite senkrecht',
  ]
  if (diagonale) {
    teile.push('mit eingezeichneter Diagonale von der oberen linken zur unteren rechten Ecke')
  }
  teile.push('die Seitenmaße stehen außen an den Seiten')
  teile.push('der rechte Winkel ist an der unteren linken Ecke markiert')
  if (gestauchtWaagerecht || gestauchtSenkrecht) {
    teile.push('die verkürzt gezeichneten Seiten tragen ein Bruchzeichen')
  }
  return `${teile.join(', ')}.`
}

// ── Hauptfunktion ────────────────────────────────────────────────────────────

/**
 * Baut ein vollstaendiges SVG als String.
 *
 * laenge    — waagerechte Seite, im Bereich [MASS_MIN, MASS_MAX].
 * breite    — senkrechte Seite, gleicher Bereich. laenge === breite ist das
 *             Quadrat; es braucht keinen eigenen Generator.
 * einheit   — Einheitenkuerzel an den Massen ('cm', 'm', …). Weglassen heisst
 *             blosse Zahl — dann steht die Einheit im Aufgabentext.
 * diagonale — Diagonale von oben links nach unten rechts. Sie beruehrt die
 *             markierte Ecke (unten links) NICHT; laege sie darauf, verdeckte
 *             die Linie das Winkelzeichen.
 * theme     — 'dunkel' (Schueler-Buehne) oder 'hell' (Eltern-Report, Druck).
 */
export function rechteck(params: RechteckParams, theme: Theme = 'dunkel'): string {
  const { laenge, breite, einheit, diagonale, texte } = pruefeParams(params)
  const farben = palette(theme)
  const { x0, y0, x1, y1, gestauchtWaagerecht, gestauchtSenkrecht } = lage(laenge, breite)

  const inhalt: string[] = [
    ...seite(x0, y1, x1, y1, gestauchtWaagerecht, farben.kontur), // unten
    ...seite(x0, y0, x1, y0, gestauchtWaagerecht, farben.kontur), // oben
    ...seite(x0, y0, x0, y1, gestauchtSenkrecht, farben.kontur), // links
    ...seite(x1, y0, x1, y1, gestauchtSenkrecht, farben.kontur), // rechts
  ]

  if (diagonale) {
    inhalt.push(linie(x0, y0, x1, y1, farben.betont, STARK_BETONT))
  }

  // Rechter Winkel, unten links, INNEN. Die Kantenlaenge ist an der kleineren
  // Seite gedeckelt, damit das Zeichen bei einem flachen Rechteck nicht ueber
  // die gegenueberliegende Kante hinauslaeuft.
  const eck = Math.min(12, (x1 - x0) / 4, (y1 - y0) / 4)
  inhalt.push(
    polylinie(
      [
        [x0, y1 - eck],
        [x0 + eck, y1 - eck],
        [x0 + eck, y1],
      ],
      farben.beschriftung,
      STARK_WINKEL,
    ),
  )

  // Masse AUSSEN an den Seiten: die Laenge unter der unteren Seite, die Breite
  // links neben der linken. Keine Massbemassung mit Hilfslinien — die Geometrie
  // verlangt sie nicht, und jede zusaetzliche Linie ist eine Behauptung mehr.
  const angabe = (wert: number): string => (einheit ? `${mass(wert)} ${einheit}` : mass(wert))
  inhalt.push(beschriftung((x0 + x1) / 2, y1 + 20, texte?.laenge ?? angabe(laenge), farben.beschriftung, 'middle'))
  inhalt.push(beschriftung(x0 - 12, (y0 + y1) / 2, texte?.breite ?? angabe(breite), farben.beschriftung, 'end'))

  return dokument(BUEHNE_BREITE, BUEHNE_HOEHE, inhalt)
}

// ── Adapter fuer den Upload (upload_figures.py: zeichne(params, theme)) ───────

/**
 * Baut ein SVG aus einem params-Objekt — die Schnittstelle, die A19 erwartet.
 *
 * `theme` kommt GETRENNT, weil der Aufrufer beide Themes aus DENSELBEN params
 * erzeugt; ein 'theme' IN params waere doppelt vergeben und wird abgewiesen.
 */
export function zeichne(params: unknown, theme: unknown): string {
  if (typeof params !== 'object' || params === null || Array.isArray(params)) {
    fehler(`params muss ein Objekt sein, nicht ${zeige(params)}.`)
  }
  if ('theme' in params) {
    fehler('theme gehoert nicht in params — es wird getrennt uebergeben.')
  }
  // KEIN Vorgabewert an dieser Stelle, anders als bei `rechteck`: der Aufrufer
  // erzeugt beide Themes aus denselben params und muss sagen, welches er
  // gerade meint. Ein fehlendes theme waere sonst stillschweigend 'dunkel' —
  // und das helle Bild fuer den Eltern-Report waere unbemerkt das dunkle.
  palette(theme)
  return rechteck(params as RechteckParams, theme as Theme)
}
