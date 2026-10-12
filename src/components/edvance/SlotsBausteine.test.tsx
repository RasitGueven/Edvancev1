// Slots SL1 (P8): die vier gemeinsamen Bausteine ohne Fachlogik.

import { describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import '@/i18n'
import { PlatzPunkte } from './PlatzPunkte'
import { Reiterleiste } from './Reiterleiste'
import { KennzahlenLeiste } from './admin/KennzahlenLeiste'
import { WochenNavigation } from './WochenNavigation'
import { dieseWoche, kalenderwoche, montagVon, wocheVerschieben, wochenSpanne } from './wochenNavigation.model'

describe('PlatzPunkte', () => {
  it('ein Raum mit Zahl wie in "Heute im Betrieb"', () => {
    const { container } = render(<PlatzPunkte raeume={[3]} mitZahl />)
    expect(screen.getByLabelText('3 von 5 Plätzen belegt')).toBeTruthy()
    expect(container.querySelectorAll('.rounded-full')).toHaveLength(5)
    expect(container.querySelectorAll('.bg-\\[var\\(--color-primary\\)\\]')).toHaveLength(3)
    expect(screen.getByText('3/5')).toBeTruthy()
  })

  it('mehrere Räume je fünf Punkte, Überhang als "+n"', () => {
    const { container } = render(<PlatzPunkte raeume={[5, 2]} ueberhang={2} />)
    expect(screen.getByLabelText('7 von 10 Plätzen belegt, 2 Kinder ohne Platz')).toBeTruthy()
    expect(container.querySelectorAll('.rounded-full')).toHaveLength(10)
    const plus = screen.getByText('+2')
    expect(plus.className).toContain('--color-error-coach')
    expect(screen.queryByText('7/10')).toBeNull()
  })

  it('mehr als fünf in einem Raum zählen als Überhang', () => {
    render(<PlatzPunkte raeume={[7]} />)
    expect(screen.getByLabelText('5 von 5 Plätzen belegt, 2 Kinder ohne Platz')).toBeTruthy()
  })
})

describe('Reiterleiste', () => {
  type K = 'woche' | 'kinder' | 'einstellungen'
  const reiter = [
    { key: 'woche' as K, titel: 'Wochenplan' },
    { key: 'kinder' as K, titel: 'Kinder', anzahl: 3, ton: 'handeln' as const },
    { key: 'einstellungen' as K, titel: 'Einstellungen', anzahl: 0, ton: 'handeln' as const },
  ]

  it('generischer Schlüssel, Zähler optional, Wechsel per Klick', () => {
    const onWechsel = vi.fn()
    render(<Reiterleiste reiter={reiter} aktiv="woche" onWechsel={onWechsel} label="Slots" />)
    expect(screen.getByRole('tablist', { name: 'Slots' })).toBeTruthy()
    expect(screen.getByRole('tab', { name: 'Wochenplan' }).getAttribute('aria-selected')).toBe('true')
    fireEvent.click(screen.getByRole('tab', { name: /Kinder/ }))
    expect(onWechsel).toHaveBeenCalledWith('kinder')
  })

  it('Ton "handeln" färbt nur einen Zähler über null', () => {
    render(<Reiterleiste reiter={reiter} aktiv="woche" onWechsel={() => undefined} />)
    expect(screen.getByText('3').className).toContain('--color-error-coach')
    expect(screen.getByText('0').className).not.toContain('--color-error-coach')
  })
})

describe('KennzahlenLeiste', () => {
  it('Feld mit Ziel ist ein Link, ohne Ziel nur Anzeige; Ton handeln färbt den Wert', () => {
    render(
      <MemoryRouter>
        <KennzahlenLeiste
          label="Kennzahlen der Woche"
          breite="slots-kpi"
          zahlen={[
            { key: 'p', label: 'Plätze', wert: '130' },
            { key: 'o', label: 'Ohne Raum', wert: '2', unterzeile: 'Do 16 Uhr', ziel: '/admin/slots/termin/x', ton: 'handeln' },
          ]}
        />
      </MemoryRouter>,
    )
    const nav = screen.getByRole('navigation', { name: 'Kennzahlen der Woche' })
    expect(nav.className).toContain('@slots-kpi:grid-cols-5')
    expect(screen.getByRole('link', { name: /Ohne Raum/ }).getAttribute('href')).toBe('/admin/slots/termin/x')
    expect(screen.queryByRole('link', { name: /Plätze/ })).toBeNull()
    expect(screen.getByText('2').className).toContain('--color-error-coach')
    expect(screen.getByText('130').className).toContain('--color-text-primary')
  })
})

describe('WochenNavigation', () => {
  it('rechnet Montage und Kalenderwochen über den Jahreswechsel', () => {
    expect(montagVon('2028-03-16')).toBe('2028-03-13')
    expect(montagVon('2028-03-13')).toBe('2028-03-13')
    expect(montagVon('2027-01-03')).toBe('2026-12-28')
    expect(wocheVerschieben('2026-12-21', 1)).toBe('2026-12-28')
    expect(wocheVerschieben('2026-12-28', 1)).toBe('2027-01-04')
    expect([kalenderwoche('2026-12-21'), kalenderwoche('2026-12-28'), kalenderwoche('2027-01-04')]).toEqual([52, 53, 1])
    expect(wocheVerschieben('2027-01-04', -2)).toBe('2026-12-21')
    expect(wochenSpanne('2028-03-13', 'de')).toBe('13.–17. März 2028')
    expect(dieseWoche(new Date('2028-03-16T10:00:00Z'))).toBe('2028-03-13')
    // Der Berliner Tag zählt: So 19.03. 23:30 (22:30 UTC) ist noch KW 11, Mo 00:30 (23:30 UTC) schon KW 12.
    expect(dieseWoche(new Date('2028-03-19T22:30:00Z'))).toBe('2028-03-13')
    expect(dieseWoche(new Date('2028-03-19T23:30:00Z'))).toBe('2028-03-20')
  })

  it('blättert per Knopf und Pfeiltaste, Montag rein und raus', () => {
    const onWechsel = vi.fn()
    render(<WochenNavigation montag="2028-03-13" onWechsel={onWechsel} />)
    expect(screen.getByText('KW 11 · 13.–17. März 2028')).toBeTruthy()
    fireEvent.click(screen.getByRole('button', { name: 'Vorige Woche' }))
    expect(onWechsel).toHaveBeenLastCalledWith('2028-03-06')
    fireEvent.click(screen.getByRole('button', { name: 'Nächste Woche' }))
    expect(onWechsel).toHaveBeenLastCalledWith('2028-03-20')
    fireEvent.click(screen.getByRole('button', { name: 'Diese Woche' }))
    expect(onWechsel).toHaveBeenLastCalledWith(dieseWoche())
    fireEvent.keyDown(window, { key: 'ArrowRight' })
    expect(onWechsel).toHaveBeenLastCalledWith('2028-03-20')
    fireEvent.keyDown(window, { key: 'ArrowLeft' })
    expect(onWechsel).toHaveBeenLastCalledWith('2028-03-06')
  })

  it('lässt Pfeiltasten in Eingabefeldern in Ruhe', () => {
    const onWechsel = vi.fn()
    render(
      <>
        <input aria-label="Suche" />
        <WochenNavigation montag="2028-03-13" onWechsel={onWechsel} />
      </>,
    )
    fireEvent.keyDown(screen.getByLabelText('Suche'), { key: 'ArrowRight' })
    expect(onWechsel).not.toHaveBeenCalled()
  })
})
