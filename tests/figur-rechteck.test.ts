// Tests fuer den Rechteck-Generator.
//
// Geprueft wird das, was ein Mensch an einer Abbildung NICHT nachsieht:
// Massstab, feste Buehne, Determinismus bis aufs Byte — und die Frage, ob der
// Generator laut wird, wenn etwas nicht darstellbar ist, statt still ein
// falsches Bild zu liefern. Ein falsches Bild ist schlimmer als kein Bild.
//
// Die Buehne ist fest (320 x 240) und die Raender stehen im Modul, darum sind
// die erwarteten Pixelorte hier AUSGERECHNET und nicht aus dem Generator
// zurueckgelesen: eine Pruefung, die ihre Sollwerte vom Prueflig holt, prueft
// nichts.

import { createHash } from 'node:crypto'
import { describe, expect, it } from 'vitest'
import {
  altText,
  BUEHNE_BREITE,
  BUEHNE_HOEHE,
  MASS_MAX,
  MASS_MIN,
  type RechteckParams,
  rechteck,
  VERHAELTNIS_MAX,
  zeichne,
} from '../scripts/figures/rechteck'

const KOPF = `<svg xmlns="http://www.w3.org/2000/svg" width="320" height="240" viewBox="0 0 320 240" role="img">`

const hash = (svg: string): string => createHash('sha256').update(svg, 'utf8').digest('hex')

/** Alle <line>-Elemente als Koordinaten-Vierling. */
function linien(svg: string): number[][] {
  return [...svg.matchAll(/<line x1="(-?[\d.]+)" y1="(-?[\d.]+)" x2="(-?[\d.]+)" y2="(-?[\d.]+)"/g)].map(
    (t) => [Number(t[1]), Number(t[2]), Number(t[3]), Number(t[4])],
  )
}

/** Umschliessendes Rechteck aller Linien — der gezeichnete Rahmen. */
function rahmen(svg: string): { breite: number; hoehe: number; x0: number; y0: number } {
  const x = linien(svg).flatMap(([x1, , x2]) => [x1, x2])
  const y = linien(svg).flatMap(([, y1, , y2]) => [y1, y2])
  const x0 = Math.min(...x)
  const y0 = Math.min(...y)
  return { x0, y0, breite: Math.max(...x) - x0, hoehe: Math.max(...y) - y0 }
}

/** Anzahl <polyline>: immer 1 fuer den rechten Winkel, +2 je Bruchzeichen-Paar. */
const polylinien = (svg: string): number => (svg.match(/<polyline /g) ?? []).length

/**
 * Wohlgeformtheit ohne Fremdparser: jedes Tag schliesst, jedes Attribut ist
 * gequotet, und es steht kein rohes '<' im Text. Das ist keine DTD-Pruefung,
 * aber es faengt genau die Fehler, die ein String-Bauer macht.
 */
function befunde(svg: string): string[] {
  const treffer = [...svg.matchAll(/<(\/?)([A-Za-z][A-Za-z0-9]*)([^>]*)>/g)]
  const meldungen: string[] = []
  if (treffer.length !== (svg.match(/</g) ?? []).length) meldungen.push('rohes < ausserhalb eines Tags')

  const stapel: string[] = []
  for (const [, schraege, name, rest] of treffer) {
    if (!/^(\s+[A-Za-z][A-Za-z0-9-]*="[^"<>]*")*\s*\/?$/.test(rest)) {
      meldungen.push(`${name}: Attribute nicht sauber gequotet (${rest.trim()})`)
    }
    if (schraege === '/') {
      if (stapel.pop() !== name) meldungen.push(`</${name}> ohne passendes offenes Tag`)
    } else if (!rest.trimEnd().endsWith('/')) {
      stapel.push(name)
    }
  }
  if (stapel.length > 0) meldungen.push(`nicht geschlossen: ${stapel.join(', ')}`)
  return meldungen
}

// ── Gueltige Parameter ───────────────────────────────────────────────────────

describe('gueltige Parameter', () => {
  it('zeichnet ein Quadrat an den ausgerechneten Pixelorten', () => {
    const svg = rechteck({ laenge: 5, breite: 5, einheit: 'cm' })
    // Flaeche 232 x 176, Verhaeltnis 1 -> h = 176, w = 176, zentriert:
    // x0 = 64 + (232-176)/2 = 92, y0 = 24, x1 = 268, y1 = 200.
    expect(rahmen(svg)).toEqual({ x0: 92, y0: 24, breite: 176, hoehe: 176 })
    expect(befunde(svg)).toEqual([])
    expect(linien(svg)).toHaveLength(4)
    expect(polylinien(svg)).toBe(1) // nur der rechte Winkel
  })

  it('setzt beide Masse mit Einheit an die Aussenseiten', () => {
    const svg = rechteck({ laenge: 8, breite: 4.5, einheit: 'cm' })
    // Laenge unter der unteren Seite (mittig), Breite links daneben (rechtsbuendig).
    expect(svg).toContain('text-anchor="middle" dominant-baseline="middle">8 cm</text>')
    expect(svg).toContain('text-anchor="end" dominant-baseline="middle">4,5 cm</text>')
  })

  it('laesst die Einheit weg, wenn keine angegeben ist', () => {
    const svg = rechteck({ laenge: 8, breite: 4 })
    expect(svg).toContain('>8</text>')
    expect(svg).toContain('>4</text>')
    expect(svg).not.toContain('cm')
  })

  it('zeichnet die Diagonale nur auf Verlangen, und nicht durch die markierte Ecke', () => {
    const ohne = rechteck({ laenge: 5, breite: 5 })
    const mit = rechteck({ laenge: 5, breite: 5, diagonale: true })
    expect(linien(ohne)).toHaveLength(4)
    expect(linien(mit)).toHaveLength(5)
    // Von oben links (92|24) nach unten rechts (268|200) — die markierte Ecke
    // unten links (92|200) liegt nicht darauf.
    expect(mit).toContain('<line x1="92" y1="24" x2="268" y2="200"')
  })

  it('markiert den rechten Winkel innen an der unteren linken Ecke', () => {
    const svg = rechteck({ laenge: 5, breite: 5 })
    expect(svg).toContain('<polyline points="92,188 104,188 104,200"')
  })

  it('bleibt react-native-tauglich: kein CSS, kein foreignObject, kein rgba', () => {
    const svg = rechteck({ laenge: 12, breite: 3, einheit: 'm', diagonale: true }, 'hell')
    for (const verboten of ['<foreignObject', '<style', ' style=', ' class=', 'rgba(', '@import', '<image']) {
      expect(svg).not.toContain(verboten)
    }
    // Deckkraft steht getrennt, nie als rgba() im Praesentationsattribut.
    expect(rechteck({ laenge: 5, breite: 5 }, 'dunkel')).toContain('stroke-opacity="0.55"')
  })

  it('kennt beide Themes und nur die', () => {
    expect(rechteck({ laenge: 5, breite: 5 }, 'dunkel')).toContain('#F7F5EE')
    expect(rechteck({ laenge: 5, breite: 5 }, 'hell')).toContain('#102038')
    expect(rechteck({ laenge: 5, breite: 5 }, 'dunkel')).not.toBe(rechteck({ laenge: 5, breite: 5 }, 'hell'))
  })
})

// ── Feste Buehne ─────────────────────────────────────────────────────────────

describe('feste viewBox', () => {
  const faelle: RechteckParams[] = [
    { laenge: MASS_MIN, breite: MASS_MIN },
    { laenge: 5, breite: 5 },
    { laenge: 1000, breite: 1 },
    { laenge: 1, breite: 1000 },
    { laenge: MASS_MAX, breite: MASS_MAX, einheit: 'km', diagonale: true },
  ]

  it.each(faelle)('haelt die Buehne bei %o', (params) => {
    const svg = rechteck(params)
    expect(svg.split('\n')[0]).toBe(KOPF)
    expect(svg.endsWith('</svg>\n')).toBe(true)
    expect(befunde(svg)).toEqual([])
    // Die Figur bleibt innerhalb der Buehne.
    const { x0, y0, breite, hoehe } = rahmen(svg)
    expect(x0).toBeGreaterThanOrEqual(0)
    expect(y0).toBeGreaterThanOrEqual(0)
    expect(x0 + breite).toBeLessThanOrEqual(BUEHNE_BREITE)
    expect(y0 + hoehe).toBeLessThanOrEqual(BUEHNE_HOEHE)
  })
})

// ── Massstab und Randwerte ───────────────────────────────────────────────────

describe('Massstab', () => {
  it.each([
    [5, 5, 1],
    [8, 4, 2],
    [4, 8, 0.5],
    [12, 3.5, 12 / 3.5],
    [MASS_MIN, MASS_MIN, 1],
  ])('zeichnet %s x %s massstaeblich', (laenge, breite, erwartet) => {
    const { breite: w, hoehe: h } = rahmen(rechteck({ laenge, breite }))
    expect(w / h).toBeCloseTo(erwartet, 2)
    expect(polylinien(rechteck({ laenge, breite }))).toBe(1) // kein Bruchzeichen
  })

  it.each([
    [40, 10],
    [10, 40],
  ])('zeichnet den Randwert %s:%s noch massstaeblich', (laenge, breite) => {
    const svg = rechteck({ laenge, breite })
    const { breite: w, hoehe: h } = rahmen(svg)
    expect(w / h).toBeCloseTo(laenge / breite, 2)
    expect(polylinien(svg)).toBe(1)
    expect(altText({ laenge, breite })).not.toContain('Bruchzeichen')
  })

  it.each([
    [50, 10, VERHAELTNIS_MAX],
    [10, 50, 1 / VERHAELTNIS_MAX],
    [MASS_MAX, MASS_MIN, VERHAELTNIS_MAX],
    [MASS_MIN, MASS_MAX, 1 / VERHAELTNIS_MAX],
  ])('staucht %s:%s auf den Bandrand und zeigt es an', (laenge, breite, gekappt) => {
    const svg = rechteck({ laenge, breite })
    const { breite: w, hoehe: h } = rahmen(svg)
    expect(w / h).toBeCloseTo(gekappt, 2)
    // Rechter Winkel + zwei Bruchzeichen auf dem gestauchten Seitenpaar.
    expect(polylinien(svg)).toBe(3)
    expect(altText({ laenge, breite })).toContain('Bruchzeichen')
    expect(befunde(svg)).toEqual([])
  })
})

// ── Ungueltige Parameter ─────────────────────────────────────────────────────

describe('ungueltige Parameter', () => {
  it.each([
    ['negative Laenge', { laenge: -5, breite: 3 }, /laenge/],
    ['null als Breite', { laenge: 5, breite: 0 }, /breite/],
    ['unter dem Wertebereich', { laenge: MASS_MIN / 2, breite: 3 }, /zwischen/],
    ['ueber dem Wertebereich', { laenge: MASS_MAX + 1, breite: 3 }, /zwischen/],
    ['NaN', { laenge: Number.NaN, breite: 3 }, /endliche Zahl/],
    ['Infinity', { laenge: Number.POSITIVE_INFINITY, breite: 3 }, /endliche Zahl/],
    ['Laenge fehlt', { breite: 3 }, /laenge/],
    ['Breite fehlt', { laenge: 3 }, /breite/],
    ['Zahl als Text', { laenge: '5', breite: 3 }, /endliche Zahl/],
    ['null', { laenge: null, breite: 3 }, /endliche Zahl/],
    ['unbekannter Schluessel', { laenge: 5, breite: 3, laenger: 7 }, /unbekannte Schluessel/],
    ['Einheit als Zahl', { laenge: 5, breite: 3, einheit: 12 }, /einheit/],
    ['Einheit zu lang', { laenge: 5, breite: 3, einheit: 'Zentimeter' }, /einheit/],
    ['Einheit leer', { laenge: 5, breite: 3, einheit: '' }, /einheit/],
    ['Einheit mit Ziffer', { laenge: 5, breite: 3, einheit: 'cm2' }, /einheit/],
    ['Diagonale als Text', { laenge: 5, breite: 3, diagonale: 'ja' }, /diagonale/],
  ])('weist %s ab', (_was, params, muster) => {
    expect(() => rechteck(params as unknown as RechteckParams)).toThrow(muster)
    expect(() => altText(params as unknown as RechteckParams)).toThrow(muster)
  })

  it.each([null, undefined, 42, 'rechteck', [5, 3]])('weist %o als params ab', (params) => {
    expect(() => rechteck(params as unknown as RechteckParams)).toThrow(/params muss ein Objekt sein/)
  })

  it('weist ein unbekanntes Theme ab, nimmt aber die Vorgabe an', () => {
    expect(() => rechteck({ laenge: 5, breite: 3 }, 'navy' as never)).toThrow(/theme/)
    expect(() => rechteck({ laenge: 5, breite: 3 }, null as never)).toThrow(/theme/)
    // Weggelassen heisst 'dunkel' — die Schueler-Buehne ist der Regelfall.
    expect(rechteck({ laenge: 5, breite: 3 })).toBe(rechteck({ laenge: 5, breite: 3 }, 'dunkel'))
  })

  it('nennt im Fehlertext den Parameter und den gesehenen Wert', () => {
    expect(() => rechteck({ laenge: -5, breite: 3 })).toThrow(
      'laenge muss groesser als null sein, nicht -5.',
    )
  })
})

// ── Determinismus / svg_hash ─────────────────────────────────────────────────

describe('Reproduzierbarkeit des Hashes', () => {
  const params: RechteckParams = { laenge: 12.5, breite: 3.25, einheit: 'cm', diagonale: true }

  it('liefert bei gleichen Parametern byteweise dasselbe SVG', () => {
    expect(hash(rechteck(params))).toBe(hash(rechteck({ ...params })))
  })

  it('ist unabhaengig von der Schluesselreihenfolge im params-Objekt', () => {
    const gedreht: RechteckParams = {
      diagonale: true,
      einheit: 'cm',
      breite: 3.25,
      laenge: 12.5,
    }
    expect(hash(rechteck(gedreht))).toBe(hash(rechteck(params)))
  })

  it('ueberlebt den Weg durch jsonb (params kommen aus der DB zurueck)', () => {
    const zurueck = JSON.parse(JSON.stringify(params)) as RechteckParams
    expect(hash(rechteck(zurueck))).toBe(hash(rechteck(params)))
  })

  it('behandelt weggelassene Vorgaben wie ausgeschriebene', () => {
    const knapp = rechteck({ laenge: 5, breite: 3 })
    const ausgeschrieben = rechteck({ laenge: 5, breite: 3, einheit: undefined, diagonale: false })
    expect(hash(knapp)).toBe(hash(ausgeschrieben))
  })

  it('aendert den Hash, sobald sich etwas an der Figur aendert', () => {
    const varianten = [
      rechteck({ laenge: 5, breite: 3 }),
      rechteck({ laenge: 3, breite: 5 }),
      rechteck({ laenge: 5, breite: 3, einheit: 'cm' }),
      rechteck({ laenge: 5, breite: 3, diagonale: true }),
      rechteck({ laenge: 5, breite: 3 }, 'hell'),
      rechteck({ laenge: 5.01, breite: 3 }),
    ].map(hash)
    expect(new Set(varianten).size).toBe(varianten.length)
  })

  it('enthaelt nichts Laufabhaengiges (kein Zeitstempel, keine Zufalls-ID)', () => {
    const svg = rechteck(params)
    expect(svg).not.toMatch(/\bid="/)
    expect(svg).not.toMatch(/20\d\d-\d\d-\d\d/)
  })
})

// ── alt-Text ─────────────────────────────────────────────────────────────────

describe('alt_text', () => {
  it('traegt keine Ziffer (CHECK task_figures_alt_no_digit) und ist nicht leer', () => {
    const faelle: RechteckParams[] = [
      { laenge: 5, breite: 5 },
      { laenge: 8, breite: 2, einheit: 'cm', diagonale: true },
      { laenge: 2, breite: 8 },
      { laenge: MASS_MAX, breite: MASS_MIN, diagonale: true },
    ]
    for (const params of faelle) {
      const text = altText(params)
      expect(text).not.toMatch(/[0-9]/)
      expect(text.trim().length).toBeGreaterThan(0)
    }
  })

  it('beschreibt die Figur in EINEM Satz', () => {
    const text = altText({ laenge: 8, breite: 2, einheit: 'cm', diagonale: true })
    expect(text.endsWith('.')).toBe(true)
    expect(text.slice(0, -1)).not.toContain('.')
  })

  it('kommt aus den Parametern: Quadrat, Lage, Diagonale, Stauchung', () => {
    expect(altText({ laenge: 5, breite: 5 })).toContain('Ein Quadrat')
    expect(altText({ laenge: 8, breite: 4 })).toContain('längeren Seite waagerecht')
    expect(altText({ laenge: 4, breite: 8 })).toContain('längeren Seite senkrecht')
    expect(altText({ laenge: 5, breite: 3, diagonale: true })).toContain('Diagonale')
    expect(altText({ laenge: 5, breite: 3 })).not.toContain('Diagonale')
    expect(altText({ laenge: 50, breite: 5 })).toContain('Bruchzeichen')
    expect(altText({ laenge: 5, breite: 5 })).not.toContain('Bruchzeichen')
  })

  it('nennt immer, wo die Masse stehen und wo der rechte Winkel markiert ist', () => {
    const text = altText({ laenge: 5, breite: 3 })
    expect(text).toContain('Seitenmaße stehen außen')
    expect(text).toContain('rechte Winkel')
  })
})

// ── Adapter fuer upload_figures.py ───────────────────────────────────────────

describe('zeichne(params, theme)', () => {
  it('ist byteidentisch mit dem direkten Aufruf', () => {
    const params = { laenge: 6, breite: 2, einheit: 'cm' }
    expect(zeichne(params, 'dunkel')).toBe(rechteck(params, 'dunkel'))
    expect(zeichne(params, 'hell')).toBe(rechteck(params, 'hell'))
  })

  it('weist ein theme IN params ab — es wird getrennt uebergeben', () => {
    expect(() => zeichne({ laenge: 5, breite: 3, theme: 'hell' }, 'hell')).toThrow(/theme gehoert nicht in params/)
  })

  it('weist Unfug in params und theme ab', () => {
    expect(() => zeichne('5x3', 'dunkel')).toThrow(/params muss ein Objekt sein/)
    expect(() => zeichne({ laenge: 5, breite: 3 }, 'navy')).toThrow(/theme/)
    // Kein stilles 'dunkel', wenn das theme fehlt: sonst waere das helle Bild
    // fuer den Eltern-Report unbemerkt das dunkle.
    expect(() => zeichne({ laenge: 5, breite: 3 }, undefined)).toThrow(/theme/)
  })
})
