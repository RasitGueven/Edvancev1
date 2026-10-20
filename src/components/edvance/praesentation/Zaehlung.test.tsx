// Die gemeinsame Zählung der Stationen 02 und 03 (T5): nur Teile ≠ 0, dritte
// Zahl je Zählweise, farbig nur auf Wunsch.
import { render } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import '@/i18n'

import type { TpAnteile } from '@/lib/report/praesentation/praesentation'
import type { TpAnzeige } from '@/types'

import { Zaehlung } from './Zaehlung'

function teile(anteile: TpAnteile, anzeige: TpAnzeige, farbig?: boolean) {
  const { container } = render(<Zaehlung anteile={anteile} anzeige={anzeige} className="tp-s3-zaehlung" farbig={farbig} />)
  const wurzel = container.firstElementChild as HTMLElement
  const spans = [...wurzel.children] as HTMLElement[]
  return { wurzel, texte: spans.map((s) => s.textContent), klassen: spans.map((s) => s.className) }
}

describe('Zaehlung', () => {
  it('ohne Übersprungene: nur sicher und Übungsbedarf', () => {
    for (const anzeige of ['kombiniert', 'getrennt'] as const) {
      expect(teile({ sicher: 2, uebung: 3, uebersprungen: 0 }, anzeige).texte).toEqual(['2 sicher', '3 Übungsbedarf'])
    }
  })

  it('kombiniert: Übungsbedarf mit übersprungen, dritte Zahl „davon"', () => {
    const z = teile({ sicher: 4, uebung: 5, uebersprungen: 3 }, 'kombiniert')
    expect(z.texte).toEqual(['4 sicher', '8 Übungsbedarf', 'davon 3 übersprungen'])
    expect(z.klassen).toEqual(['tp-zaehlung-sicher', 'tp-zaehlung-uebung', 'tp-zaehlung-davon'])
  })

  it('getrennt: Übungsbedarf ohne, dritte Zahl eigen', () => {
    const z = teile({ sicher: 4, uebung: 5, uebersprungen: 3 }, 'getrennt')
    expect(z.texte).toEqual(['4 sicher', '5 Übungsbedarf', '3 übersprungen'])
    expect(z.klassen[2]).toBe('tp-zaehlung-eigen')
  })

  it('nur Teile ungleich null', () => {
    expect(teile({ sicher: 0, uebung: 2, uebersprungen: 0 }, 'kombiniert').texte).toEqual(['2 Übungsbedarf'])
    expect(teile({ sicher: 3, uebung: 0, uebersprungen: 0 }, 'getrennt').texte).toEqual(['3 sicher'])
    expect(teile({ sicher: 0, uebung: 0, uebersprungen: 1 }, 'getrennt').texte).toEqual(['1 übersprungen'])
    expect(teile({ sicher: 0, uebung: 0, uebersprungen: 1 }, 'kombiniert').texte).toEqual([
      '1 Übungsbedarf',
      'davon 1 übersprungen',
    ])
  })

  it('farbig nur auf Wunsch; Klasse der Station immer', () => {
    const leise = teile({ sicher: 1, uebung: 1, uebersprungen: 0 }, 'kombiniert')
    expect(leise.wurzel).toHaveClass('tp-zaehlung', 'tp-s3-zaehlung')
    expect(leise.wurzel).not.toHaveClass('tp-zaehlung-farbig')
    expect(teile({ sicher: 1, uebung: 1, uebersprungen: 0 }, 'kombiniert', true).wurzel).toHaveClass(
      'tp-zaehlung-farbig',
    )
  })

  it('Teile durch Leerzeichen getrennt; der Trenner „·" kommt aus dem CSS', () => {
    const { wurzel } = teile({ sicher: 2, uebung: 3, uebersprungen: 1 }, 'kombiniert')
    expect(wurzel.textContent).toBe('2 sicher 4 Übungsbedarf davon 1 übersprungen')
  })
})
