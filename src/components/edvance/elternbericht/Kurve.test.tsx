// Kurve skalenfest (Bauauftrag R7-7, Entscheidung 4): Kurve.tsx rechnet aus
// getBoundingClientRect, aber nur in Verhältnissen zur Breite des Bereichs.
// Verkleinert BerichtAnsicht den Bogen per transform, schrumpfen alle Rechtecke
// gleich — die Knoten müssen in pt der Seite gleich liegen.
import { render } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'

import { Kurve } from './Kurve'

/** Unskalierte Lagen in px: Bereich 507 pt = 676 px breit, ab y 100. */
const BEREICH = { top: 100, left: 40, width: 676, height: 960 }
const GRUND = [180, 320, 470]
const ZIEL = 700

function rechteck(top: number, height: number, s: number, versatz: number): DOMRect {
  // transform um die obere Mitte: alles skaliert, oben um `versatz` verschoben.
  const y = versatz + top * s
  return {
    top: y,
    bottom: y + height * s,
    left: BEREICH.left * s,
    right: (BEREICH.left + BEREICH.width) * s,
    width: BEREICH.width * s,
    height: height * s,
    x: BEREICH.left * s,
    y,
    toJSON: () => ({}),
  }
}

function knotenBei(s: number, versatz: number): number[] {
  const original = Element.prototype.getBoundingClientRect
  vi.spyOn(Element.prototype, 'getBoundingClientRect').mockImplementation(function (
    this: Element,
  ) {
    if (this.getAttribute('data-bereich') !== null) return rechteck(BEREICH.top, BEREICH.height, s, versatz)
    if (this.classList.contains('eb-s4-grund')) {
      const i = Number(this.getAttribute('data-i'))
      return rechteck(GRUND[i], 0, s, versatz)
    }
    if (this.hasAttribute('data-kurve-ziel')) return rechteck(ZIEL, 80, s, versatz)
    return original.call(this)
  })
  const { container, unmount } = render(
    <div data-bereich="">
      {GRUND.map((_, i) => (
        <span key={i} className="eb-s4-grund" data-i={i} />
      ))}
      <div data-kurve-ziel="" />
      <Kurve />
    </div>,
  )
  const cy = [...container.querySelectorAll('.eb-s4-knoten')].map((c) =>
    Number(c.getAttribute('cy')),
  )
  unmount()
  vi.restoreAllMocks()
  return cy
}

afterEach(() => vi.restoreAllMocks())

describe('Kurve', () => {
  it('legt die Knoten bei Skala 1 und 0,6 gleich', () => {
    const eins = knotenBei(1, 0)
    const klein = knotenBei(0.6, 37)
    expect(eins).toHaveLength(GRUND.length)
    expect(klein).toHaveLength(GRUND.length)
    klein.forEach((y, i) => expect(y).toBeCloseTo(eins[i], 6))
  })
})
