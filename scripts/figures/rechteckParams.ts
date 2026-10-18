/**
 * Eingabepruefungen des Rechteck-Generators (Vorlage: pruefungen.py).
 *
 * Ausgelagert aus rechteck.ts, damit beide Dateien unter 400 Zeilen bleiben.
 * Kein stiller Verzicht: unbekannte Schluessel, Werte ausserhalb des Bereichs
 * und widerspruechliche Angaben (Zahl UND Text fuer dieselbe Seite) sind Fehler.
 */

/** Ab hier wird gestaucht statt massstaeblich gezeichnet (1:4 bzw. 4:1). */
export const VERHAELTNIS_MAX = 4

// Wertebereich der Seitenmasse. Unten: unter 0,1 rundet die Beschriftung (zwei
// Nachkommastellen) auf null und die Figur behauptete ein Mass, das sie nicht
// anzeigt. Oben: ueber 1000 sprengt die Beschriftung den linken Rand.
export const MASS_MIN = 0.1
export const MASS_MAX = 1000

const SCHLUESSEL = ['laenge', 'breite', 'einheit', 'diagonale', 'laenge_text', 'breite_text', 'verhaeltnis'] as const
// Text-Masse: "x cm", "(x + 3) cm". Hoechstens 16 Zeichen — die Breite steht links
// auf dem Rand der festen Buehne, laengeres laeuft aus dem Bild.
const TEXT_MAX = 16
/** Gezeichnetes Seitenverhaeltnis, wenn die Masse Terme sind (siehe pruefeParams). */
export const VERHAELTNIS_TEXT_STANDARD = 1.6
// Ein bis vier Buchstaben ('cm', 'm', 'km'). Ziffern und Sonderzeichen sind
// draussen: die Angabe steht am Rand der festen Buehne, laengeres passt nicht.
const EINHEIT_MUSTER = /^[A-Za-zÄÖÜäöüß]{1,4}$/


export interface RechteckParams {
  laenge?: number
  breite?: number
  einheit?: string
  diagonale?: boolean
  laenge_text?: string
  breite_text?: string
  verhaeltnis?: number
}

export interface GeprueftParams {
  laenge: number
  breite: number
  einheit: string
  diagonale: boolean
  /** Gesetzt, wenn die Masse Terme sind: dann steht DIESER Text an der Seite. */
  texte: { laenge: string; breite: string } | null
}

// ── Pruefungen (Vorlage: pruefungen.py) ──────────────────────────────────────

export function fehler(text: string): never {
  throw new Error(text)
}

export function zeige(wert: unknown): string {
  if (wert === undefined) return 'undefined'
  if (typeof wert === 'number' || typeof wert === 'boolean' || wert === null) return String(wert)
  try {
    return JSON.stringify(wert) ?? String(wert)
  } catch {
    return String(wert)
  }
}

function pruefeMass(wert: unknown, name: string): number {
  // NaN und Infinity sind `typeof 'number'` und wuerden sonst als Koordinate
  // durchlaufen — das SVG traegt dann 'NaN' im Attribut und zeigt nichts.
  if (typeof wert !== 'number' || !Number.isFinite(wert)) {
    fehler(`${name} muss eine endliche Zahl sein, nicht ${zeige(wert)}.`)
  }
  if (wert <= 0) {
    fehler(`${name} muss groesser als null sein, nicht ${zeige(wert)}.`)
  }
  if (wert < MASS_MIN || wert > MASS_MAX) {
    fehler(`${name} muss zwischen ${MASS_MIN} und ${MASS_MAX} liegen, nicht ${zeige(wert)}.`)
  }
  return wert
}

function pruefeEinheit(wert: unknown): string {
  if (wert === undefined) return ''
  if (typeof wert !== 'string') fehler(`einheit muss Text sein, nicht ${zeige(wert)}.`)
  if (!EINHEIT_MUSTER.test(wert)) {
    fehler(
      `einheit muss ein bis vier Buchstaben sein (z.B. "cm"), nicht ${zeige(wert)}. ` +
        'Die Angabe steht am Rand der Buehne — laengeres passt dort nicht hin.',
    )
  }
  return wert
}

function pruefeWahrheitswert(wert: unknown, name: string): boolean {
  if (wert === undefined) return false
  if (typeof wert !== 'boolean') fehler(`${name} muss true oder false sein, nicht ${zeige(wert)}.`)
  return wert
}

export function pruefeParams(roh: unknown): GeprueftParams {
  if (typeof roh !== 'object' || roh === null || Array.isArray(roh)) {
    fehler(`params muss ein Objekt sein, nicht ${zeige(roh)}.`)
  }
  const unbekannt = Object.keys(roh).filter((k) => !(SCHLUESSEL as readonly string[]).includes(k))
  if (unbekannt.length > 0) {
    // Kein stiller Verzicht: 'laenger' statt 'laenge' waere sonst eine Figur
    // ohne Mass statt eines Fehlers.
    fehler(`params: unbekannte Schluessel: ${unbekannt.sort().map(zeige).join(', ')}.`)
  }
  const p = roh as Record<string, unknown>
  if (p.laenge_text !== undefined || p.breite_text !== undefined) return pruefeTextParams(p)
  if (p.verhaeltnis !== undefined) fehler('verhaeltnis gibt es nur zusammen mit laenge_text und breite_text.')
  return {
    texte: null,
    laenge: pruefeMass(p.laenge, 'laenge'),
    breite: pruefeMass(p.breite, 'breite'),
    einheit: pruefeEinheit(p.einheit),
    diagonale: pruefeWahrheitswert(p.diagonale, 'diagonale'),
  }
}

/**
 * TEXT-MASSE: Die Aufgabe nennt eine Seite als Term ("x cm"). Dann gibt es keine
 * Zahl, aus der sich ein Seitenverhaeltnis ergaebe — die Skizze ist ausdruecklich
 * NICHT massstaeblich, und `verhaeltnis` legt nur fest, wie sie aussieht.
 * Zahlen-Masse (laenge, breite, einheit) daneben sind ein Fehler: Zwei Angaben fuer
 * dieselbe Seite koennten sich widersprechen. Die Einheit steht im Text selbst.
 */
function pruefeTextParams(p: Record<string, unknown>): GeprueftParams {
  for (const k of ['laenge', 'breite', 'einheit'] as const) {
    if (p[k] !== undefined) fehler(`${k} und Text-Masse schliessen sich aus — die Einheit steht im Text.`)
  }
  const text = (wert: unknown, name: string): string => {
    if (typeof wert !== 'string' || wert.trim() === '') fehler(`${name} muss ein nicht leerer Text sein, nicht ${zeige(wert)}.`)
    if (wert.length > TEXT_MAX) fehler(`${name} ist laenger als ${TEXT_MAX} Zeichen und passt nicht an den Rand.`)
    return wert
  }
  const verhaeltnis = p.verhaeltnis === undefined ? VERHAELTNIS_TEXT_STANDARD : p.verhaeltnis
  if (typeof verhaeltnis !== 'number' || !Number.isFinite(verhaeltnis)
      || verhaeltnis < 1 / VERHAELTNIS_MAX || verhaeltnis > VERHAELTNIS_MAX) {
    fehler(`verhaeltnis muss zwischen ${1 / VERHAELTNIS_MAX} und ${VERHAELTNIS_MAX} liegen, nicht ${zeige(verhaeltnis)}.`)
  }
  return {
    texte: { laenge: text(p.laenge_text, 'laenge_text'), breite: text(p.breite_text, 'breite_text') },
    laenge: verhaeltnis,
    breite: 1,
    einheit: '',
    diagonale: pruefeWahrheitswert(p.diagonale, 'diagonale'),
  }
}
