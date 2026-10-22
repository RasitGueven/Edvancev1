// Station 03 · volle Karte gekürzt (R7-12, Entscheidungen 9 und 11): ab Stufe 4,
// „+ n weitere“ antippbar, das Infofeld zeigt die weggelassenen Bereiche.
import { fireEvent, render, screen } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { Bausteinsatz } from '@/lib/report/bausteine'
import { PRAESENTATION_FAELLE } from '@/lib/report/praesentation/fixtures'

import { Station3 } from './Station3'
import { daten } from './testStation34'

beforeEach(() => {
  vi.stubGlobal('matchMedia', (q: string) => ({ matches: q.includes('reduce'), addEventListener() {}, removeEventListener() {} }))
  vi.stubGlobal('IntersectionObserver', class {
    observe(): void {}
    disconnect(): void {}
  })
})
afterEach(() => vi.unstubAllGlobals())

describe('Station 03 · volle Karte, sehrViele (R7-12)', () => {
  it('beginnt bei Stufe 4, „+ n weitere“ füllt das Infofeld und leert es wieder', () => {
    const p = daten(PRAESENTATION_FAELLE.sehrViele)
    const { container } = render(
      <section className="tp-station" data-station="3">
        <Station3 p={p} anzeige="kombiniert" satz={new Bausteinsatz([])} sessionId="s" />
      </section>,
    )
    fireEvent.click(screen.getByTestId('tp-s3-ganz'))
    expect(container.querySelector('.tp-s3-kopfzeile')!.getAttribute('data-stufe')).toBe('4')
    // Höchstens 6 Zeilen je Insel außer Linienenden; die Zeile ist kein Eintrag.
    const weitere = [...container.querySelectorAll<HTMLButtonElement>('.tp-s3-weitere')]
    expect(weitere.length).toBeGreaterThan(0)
    expect(weitere[0].querySelector('[data-anker], [data-eintrag]')).toBeNull()
    expect(weitere[0].textContent).toMatch(/^\+ \d+ weitere/)

    const info = screen.getByTestId('tp-s3-info')
    fireEvent.click(weitere[0])
    expect(info.textContent).toMatch(/^Weitere Bereiche: .+/)
    expect(weitere[0].getAttribute('aria-pressed')).toBe('true')
    fireEvent.click(weitere[0])
    expect(info.textContent).not.toMatch(/Weitere Bereiche/)
  })
})
