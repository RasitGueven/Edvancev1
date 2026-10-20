// Namensmessung skalenfest (Bauauftrag R7-7, Entscheidung 4): BerichtAnsicht
// verkleinert den Bogen am Bildschirm per transform. getBoundingClientRect
// schrumpft dann mit, offsetHeight und die Zeilenhöhe nicht — die Entscheidung
// muss bei Skala 1 und 0,6 dieselbe sein.
import { afterEach, describe, expect, it } from 'vitest'

import { passtMitNamen } from './namensMessung'

const ZEILE = 40

/** Ein Bogen mit Titel auf Seite 2, wie er bei Skala `s` gemessen würde. */
function bogen(zeilen: number, s: number): HTMLElement {
  const el = document.createElement('div')
  el.innerHTML = `
    <section class="eb-seite" data-seite="2">
      <div class="eb-inhalt"><h1 class="eb-titel" style="line-height: ${ZEILE}px">Titel</h1></div>
    </section>`
  const titel = el.querySelector<HTMLElement>('.eb-titel')!
  const hoehe = zeilen * ZEILE
  Object.defineProperty(titel, 'offsetHeight', { value: hoehe })
  titel.getBoundingClientRect = () => ({ height: hoehe * s }) as DOMRect
  document.body.append(el)
  return el
}

afterEach(() => {
  document.body.innerHTML = ''
})

describe('passtMitNamen', () => {
  it.each([1, 0.6])('zweizeiliger Titel passt bei Skala %s', (s) => {
    expect(passtMitNamen(bogen(2, s))).toBe(true)
  })

  it.each([1, 0.6])('dreizeiliger Titel passt bei Skala %s nicht', (s) => {
    expect(passtMitNamen(bogen(3, s))).toBe(false)
  })

  it('trifft bei Skala 1 und 0,6 dieselbe Entscheidung', () => {
    for (const zeilen of [1, 2, 3, 4]) {
      expect(passtMitNamen(bogen(zeilen, 0.6)), `${zeilen} Zeilen`).toBe(
        passtMitNamen(bogen(zeilen, 1)),
      )
    }
  })
})
