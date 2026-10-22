// Station 03 · Lernweg — Sichtbarkeit während der Fahrt ohne React-State (PF-1,
// Entscheidungen 3 und 5): je Bild nur Klassen und hidden über Refs.
import { act, render } from '@testing-library/react'
import { useLayoutEffect, useRef } from 'react'
import { describe, expect, it } from 'vitest'

import { useLernwegSicht, type Sicht } from './useLernwegSicht'

const XS = [0, 300, 600, 900]

function Spur({ aus, renders }: { aus: (s: Sicht) => void; renders: { n: number } }): JSX.Element {
  const s = useLernwegSicht()
  const spur = useRef<HTMLDivElement>(null)
  renders.n++
  aus(s)
  const { erfassen } = s
  useLayoutEffect(() => {
    const els = [...spur.current!.querySelectorAll<HTMLElement>('[data-insel]')]
    erfassen(
      els.map((el, i) => ({ el, x: XS[i] })),
      600,
    )
  }, [erfassen])
  return (
    <div ref={spur}>
      {XS.map((x) => (
        <div key={x} data-insel={x} className={s.sicht === null || s.sicht.has(String(x)) ? 'tp-s3-da' : undefined} />
      ))}
      <p ref={s.hierRef} hidden={!s.hier} data-testid="hier" />
    </div>
  )
}

function zeige() {
  let s!: Sicht
  const renders = { n: 0 }
  const r = render(<Spur aus={(x) => (s = x)} renders={renders} />)
  const da = (): number => r.container.querySelectorAll('.tp-s3-da').length
  return { ...r, s: () => s, renders, da, hier: () => r.getByTestId('hier') }
}

describe('useLernwegSicht (PF-1)', () => {
  it('am Anfang alles sichtbar (reduzierte Bewegung, motion-complete)', () => {
    const t = zeige()
    expect(t.da()).toBe(4)
    expect(t.hier().hidden).toBe(false)
  })

  it('während der Fahrt: Klassen je Bild, kein Render', () => {
    const t = zeige()
    act(() => t.s().leer())
    expect(t.da()).toBe(0)
    expect(t.hier().hidden).toBe(true)
    const n = t.renders.n
    t.s().bis(350, 0)
    expect(t.da()).toBe(2)
    t.s().bis(650, 400)
    expect(t.da()).toBe(3)
    expect(t.hier().hidden).toBe(true) // die Front ist noch nicht bei „Kommt noch“
    t.s().bis(650, 600)
    expect(t.hier().hidden).toBe(false)
    expect(t.renders.n).toBe(n)
  })

  it('setzt die Klasse wieder, wenn React sie zwischendurch neu geschrieben hat', () => {
    const t = zeige()
    act(() => t.s().leer())
    t.s().bis(100, 0)
    const erste = t.container.querySelector('[data-insel="0"]')!
    erste.className = ''
    t.s().bis(100, 0)
    expect(erste.classList.contains('tp-s3-da')).toBe(true)
  })

  it('am Ende zieht der State einmal nach; React und DOM stimmen überein', () => {
    const t = zeige()
    act(() => t.s().leer())
    t.s().bis(350, 0)
    const n = t.renders.n
    act(() => t.s().bis(Infinity, Infinity))
    expect(t.s().sicht).toBeNull()
    expect(t.s().hier).toBe(true)
    expect(t.da()).toBe(4)
    expect(t.hier().hidden).toBe(false)
    const danach = t.renders.n
    expect(danach).toBeGreaterThan(n)
    act(() => t.s().bis(Infinity, Infinity))
    act(() => t.s().alles())
    expect(t.renders.n).toBe(danach)
  })
})
