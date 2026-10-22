// Station 03 · Lernweg — flüssiger Aufbau (PF-1): reduzierte Bewegung zeigt alles
// sofort, Unterbrechen deckt alles auf (Inseln, Zonen, „Sie sind hier“, Linien).
import { act, fireEvent, render, screen } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { Bausteinsatz } from '@/lib/report/bausteine'
import { PRAESENTATION_FAELLE } from '@/lib/report/praesentation/fixtures'

import { Station3 } from './Station3'
import { daten } from './testStation34'

let ruhig = false

beforeEach(() => {
  ruhig = false
  vi.stubGlobal('matchMedia', (q: string) => ({ matches: q.includes('reduce') && ruhig, addEventListener() {}, removeEventListener() {} }))
  vi.stubGlobal('IntersectionObserver', class {
    observe(): void {}
    disconnect(): void {}
  })
  vi.useFakeTimers({ toFake: ['requestAnimationFrame', 'cancelAnimationFrame', 'performance', 'setTimeout', 'clearTimeout'] })
})
afterEach(() => {
  vi.useRealTimers()
  vi.unstubAllGlobals()
})

function station() {
  const r = render(
    <section className="tp-station" data-station="3">
      <Station3 p={daten(PRAESENTATION_FAELLE.abgestuft)} anzeige="kombiniert" satz={new Bausteinsatz([])} sessionId="s" />
    </section>,
  )
  const section = r.container.querySelector('section')!
  const alle = () => [...r.container.querySelectorAll('.tp-s3-insel, .tp-s3-zone')]
  const fehlt = () => alle().filter((e) => !e.classList.contains('tp-s3-da')).length
  return { ...r, section, alle, fehlt, hier: () => screen.getByTestId('tp-s3-hier') }
}

const betreten = (section: HTMLElement) =>
  act(async () => {
    section.classList.add('entered')
  })

describe('Station 03 — flüssiger Aufbau (PF-1)', () => {
  it('reduzierte Bewegung: Inseln, Zonen und „Sie sind hier“ stehen sofort da', async () => {
    ruhig = true
    const s = station()
    await betreten(s.section)
    expect(s.alle().length).toBeGreaterThan(4)
    expect(s.fehlt()).toBe(0)
    expect(s.hier().hidden).toBe(false)
  })

  it('vor dem Betreten nichts, Unterbrechen deckt alles auf', async () => {
    const s = station()
    expect(s.fehlt()).toBe(s.alle().length)
    expect(s.hier().hidden).toBe(true)
    await betreten(s.section)
    act(() => vi.advanceTimersByTime(300))
    // Ohne Maß (jsdom) zeigt die Kamera beim Warten nichts: noch ist nichts da.
    expect(s.container.querySelector('[data-testid="tp-s3-scroller"]')!.getAttribute('data-phase')).toBe('warten')
    expect(s.fehlt()).toBeGreaterThan(0)
    fireEvent.click(screen.getByRole('button', { name: /^Bruch in Dezimalzahl/ }))
    expect(s.fehlt()).toBe(0)
    expect(s.hier().hidden).toBe(false)
  })

  it('keine Zeile hat eine eigene Folge (--tp-i): Inseln erscheinen als Ganzes', () => {
    const s = station()
    expect(s.container.querySelector('[style*="--tp-i"]')).toBeNull()
  })
})
