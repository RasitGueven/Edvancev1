// Bildschirmansicht des Eltern-Berichts (Bauauftrag R7-7): Einpassen per
// --eb-skala (ResizeObserver gemockt, nie über 1) und die Seitenleiste.
import { act, fireEvent, render, screen } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { FAELLE } from '@/lib/report/elternbericht/fixtures'

import { BerichtAnsicht } from './BerichtAnsicht'

const fall = FAELLE.testlauf
/** 595,28 pt in px. */
const SEITE_PX = 794

let groessen: (() => void)[] = []
let sichtbar: ((eintraege: Partial<IntersectionObserverEntry>[]) => void)[] = []
const scroll = vi.fn()

beforeEach(() => {
  groessen = []
  sichtbar = []
  scroll.mockReset()
  vi.stubGlobal(
    'ResizeObserver',
    class {
      constructor(cb: () => void) {
        groessen.push(cb)
      }
      observe(): void {}
      disconnect(): void {}
    },
  )
  vi.stubGlobal(
    'IntersectionObserver',
    class {
      constructor(cb: (e: Partial<IntersectionObserverEntry>[]) => void) {
        sichtbar.push(cb)
      }
      observe(): void {}
      disconnect(): void {}
    },
  )
  Element.prototype.scrollIntoView = scroll
  vi.spyOn(HTMLElement.prototype, 'offsetWidth', 'get').mockImplementation(function (
    this: HTMLElement,
  ) {
    return this.classList.contains('eb-seite') ? SEITE_PX : 0
  })
  vi.spyOn(HTMLElement.prototype, 'offsetHeight', 'get').mockImplementation(function (
    this: HTMLElement,
  ) {
    return this.dataset.testid === 'eb-skaliert' ? 5000 : 0
  })
})

afterEach(() => {
  vi.unstubAllGlobals()
  vi.restoreAllMocks()
})

function ansicht() {
  return render(
    <BerichtAnsicht
      data={fall.data}
      notes={fall.notes!}
      tiers={fall.tiers}
      bogenKey="s1"
      ausblick={<p>Ausblick</p>}
    />,
  )
}

/** Spaltenbreite setzen und den ResizeObserver feuern lassen. */
function spalte(breite: number): HTMLElement {
  const huelle = screen.getByTestId('eb-huelle')
  Object.defineProperty(huelle, 'clientWidth', { value: breite, configurable: true })
  act(() => groessen.forEach((cb) => cb()))
  return huelle
}

describe('BerichtAnsicht — Einpassen', () => {
  it('verkleinert bei schmaler Spalte und kürzt die Höhe mit', () => {
    ansicht()
    const huelle = spalte(SEITE_PX * 0.6)
    expect(Number(huelle.style.getPropertyValue('--eb-skala'))).toBeCloseTo(0.6, 6)
    expect(parseFloat(huelle.style.height)).toBeCloseTo(3000, 3)
  })

  it('vergrößert nie über 100 %', () => {
    ansicht()
    const huelle = spalte(SEITE_PX * 2)
    expect(huelle.style.getPropertyValue('--eb-skala')).toBe('1')
    expect(huelle.style.height).toBe('5000px')
  })

  it('stellt Leiste und Ausblick nur am Bildschirm dar', () => {
    ansicht()
    expect(screen.getByRole('navigation').classList.contains('print-hide')).toBe(true)
    expect(screen.getByText('Ausblick').closest('aside')?.classList.contains('print-hide')).toBe(
      true,
    )
  })
})

describe('Seitenleiste', () => {
  it('nennt die fünf Stationen und scrollt zur gewählten Seite', () => {
    const { container } = ansicht()
    const knoepfe = screen.getAllByRole('button')
    expect(knoepfe.map((k) => k.textContent)).toEqual([
      'Überblick',
      'Lernstand',
      'Einordnung',
      'Lernplan',
      'Nächste Schritte',
    ])
    expect(knoepfe[0]).toHaveAttribute('aria-current', 'true')

    fireEvent.click(screen.getByRole('button', { name: 'Lernstand' }))
    expect(scroll).toHaveBeenCalledTimes(1)
    expect(scroll.mock.contexts[0]).toBe(container.querySelector('.eb-seite[data-seite="2"]'))
    expect(scroll.mock.calls[0][0]).toMatchObject({ block: 'start' })
    expect(screen.getByRole('button', { name: 'Lernstand' })).toHaveAttribute('aria-current', 'true')
    expect(knoepfe[0]).not.toHaveAttribute('aria-current')
  })

  it('markiert die Seite, die im Fenster steht', () => {
    const { container } = ansicht()
    const vier = container.querySelector('.eb-seite[data-seite="4"]')!
    act(() => sichtbar.forEach((cb) => cb([{ target: vier, isIntersecting: true }])))
    expect(screen.getByRole('button', { name: 'Lernplan' })).toHaveAttribute('aria-current', 'true')
  })
})
