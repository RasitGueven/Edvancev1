// Station 03 · Lernweg — die Linien werden nur vermessen, wenn ein Pfad dazukommt
// oder sein d sich ändert (PF-1, Entscheidungen 1 und 2).
import { render } from '@testing-library/react'
import { useLayoutEffect } from 'react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import type { FrontTabelle } from '@/lib/report/praesentation/lernwegFahrt'

import { useLinienZeichnen } from './useLinienZeichnen'

type Linien = ReturnType<typeof useLinienZeichnen>

let laenge: ReturnType<typeof vi.fn>
let punkt: ReturnType<typeof vi.fn>
const proto = SVGElement.prototype as unknown as Record<string, unknown>

beforeEach(() => {
  // jsdom kennt keine SVG-Geometrie: Länge 40, Punkt auf der Waagrechten.
  laenge = vi.fn(() => 40)
  punkt = vi.fn((l: number) => ({ x: l, y: 0 }))
  proto.getTotalLength = laenge
  proto.getPointAtLength = punkt
})
afterEach(() => {
  delete proto.getTotalLength
  delete proto.getPointAtLength
})

function Buehne({ d, zaehler, aus }: { d: string; zaehler: number; aus: (l: Linien) => void }): JSX.Element {
  const l = useLinienZeichnen()
  aus(l)
  useLayoutEffect(l.abgleichen, [d, l.abgleichen])
  return (
    <svg data-zaehler={zaehler}>
      <path ref={l.pfadRef('a-b', 'linie')} d={d} />
      <path ref={l.pfadRef('a-b', 'spitze')} d="M0 0" />
    </svg>
  )
}

function zeige(d: string) {
  let l!: Linien
  const aus = (x: Linien): void => {
    l = x
  }
  const r = render(<Buehne d={d} zaehler={0} aus={aus} />)
  return { ...r, l: () => l, aus }
}

describe('useLinienZeichnen (PF-1)', () => {
  it('pfadRef liefert je (key, art) über Renders hinweg dieselbe Funktion', () => {
    const s = zeige('M0 0 H40')
    const vorher = [s.l().pfadRef('a-b', 'linie'), s.l().pfadRef('a-b', 'spitze')]
    s.rerender(<Buehne d="M0 0 H40" zaehler={1} aus={s.aus} />)
    expect(s.l().pfadRef('a-b', 'linie')).toBe(vorher[0])
    expect(s.l().pfadRef('a-b', 'spitze')).toBe(vorher[1])
    expect(s.l().pfadRef('a-b', 'linie')).not.toBe(vorher[1])
  })

  it('ein Re-Render ohne neues d vermisst nicht erneut', () => {
    const s = zeige('M0 0 H40')
    expect(laenge).toHaveBeenCalledTimes(1)
    const proben = punkt.mock.calls.length
    expect(proben).toBeGreaterThan(0)
    for (let i = 1; i <= 5; i++) s.rerender(<Buehne d="M0 0 H40" zaehler={i} aus={s.aus} />)
    expect(laenge).toHaveBeenCalledTimes(1)
    expect(punkt).toHaveBeenCalledTimes(proben)
  })

  it('ein neues d wird neu vermessen', () => {
    const s = zeige('M0 0 H40')
    s.rerender(<Buehne d="M0 0 H80" zaehler={1} aus={s.aus} />)
    expect(laenge).toHaveBeenCalledTimes(2)
  })

  it('Front-Tabelle und Bereich sind gecacht und nur bei neuem d neu gebaut', () => {
    const s = zeige('M0 0 H40')
    const f: FrontTabelle = s.l().front()
    const b = s.l().bereich()
    expect(f.length).toBeGreaterThan(0)
    expect(b).toEqual({ start: 0, ende: 40 })
    s.l().zeichne(10)
    s.rerender(<Buehne d="M0 0 H40" zaehler={1} aus={s.aus} />)
    expect(s.l().front()).toBe(f)
    expect(s.l().bereich()).toBe(b)
    s.rerender(<Buehne d="M0 0 H80" zaehler={2} aus={s.aus} />)
    expect(s.l().front()).not.toBe(f)
  })

  it('zeichnet bis zur Laufkoordinate; die Spitze erscheint erst mit der fertigen Linie', () => {
    const s = zeige('M0 0 H40')
    const [linie, spitze] = [...s.container.querySelectorAll('path')]
    s.l().zeichne(20)
    expect(linie.style.strokeDashoffset).toBe('20')
    expect(spitze.classList.contains('tp-s3-an')).toBe(false)
    s.l().zeichne(Infinity)
    expect(linie.style.strokeDashoffset).toBe('0')
    expect(spitze.classList.contains('tp-s3-an')).toBe(true)
  })
})
