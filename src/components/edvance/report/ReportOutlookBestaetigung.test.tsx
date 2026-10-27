// L5 Teil D (Entscheidung 14): Schalter „Ziele/Paket im Gespräch bestätigt“ im Ausblick und in der Präsentation.
import { fireEvent, render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { Bestaetigung } from '@/components/edvance/praesentation/Bestaetigung'
import type { ReportNotes } from '@/types'

import { ReportOutlook } from './ReportOutlook'

const NOTES: ReportNotes = { zielbild: '', empfehlung: '', paket: 'standard', zieleBestaetigt: false, paketBestaetigt: true }

function ausblick(extra: Partial<Parameters<typeof ReportOutlook>[0]> = {}) {
  const onChange = vi.fn()
  render(
    <ReportOutlook name="Kind" notes={NOTES} onChange={onChange} onSave={vi.fn()} saving={false} saved={false} unavailable={false} {...extra} />,
  )
  return onChange
}

describe('Ausblick · Bestätigung', () => {
  it('ohne Spalten (bestaetigung false) keine Schalter', () => {
    ausblick()
    expect(screen.queryByTestId('report-bestaetigung')).toBeNull()
  })

  it('zwei Schalter, Stand aus den Notizen, Umschalten meldet die geänderten Notizen', () => {
    const onChange = ausblick({ bestaetigung: true })
    const ziele = screen.getByRole('switch', { name: 'Ziele im Gespräch bestätigt' })
    const paket = screen.getByRole('switch', { name: 'Paket im Gespräch bestätigt' })
    expect(ziele).toHaveAttribute('aria-checked', 'false')
    expect(paket).toHaveAttribute('aria-checked', 'true')
    fireEvent.click(ziele)
    expect(onChange).toHaveBeenCalledWith({ ...NOTES, zieleBestaetigt: true })
  })

  it('Paket-Schalter ohne gewähltes Paket gesperrt, mit Grund', () => {
    render(
      <ReportOutlook name="Kind" notes={{ ...NOTES, paket: null }} onChange={vi.fn()} onSave={vi.fn()} saving={false} saved={false} unavailable={false} bestaetigung />,
    )
    const paket = screen.getByRole('switch', { name: 'Paket im Gespräch bestätigt' })
    expect(paket).toBeDisabled()
    expect(paket).toHaveAttribute('title', 'Erst ein Paket wählen')
  })

  it('Coach (nurLesen): Schalter gesperrt', () => {
    ausblick({ bestaetigung: true, nurLesen: true })
    for (const s of screen.getAllByRole('switch')) expect(s).toBeDisabled()
  })
})

describe('Präsentation · Bestätigung', () => {
  it('zwei Schalter, nicht im Druck; Umschalten meldet Art und neuen Stand', () => {
    const onWechsel = vi.fn()
    render(<Bestaetigung notes={NOTES} bestaetigung={{ onWechsel }} />)
    expect(screen.getByTestId('tp-bestaetigung')).toHaveClass('print-hide')
    fireEvent.click(screen.getByRole('switch', { name: 'Ziele bestätigt' }))
    expect(onWechsel).toHaveBeenCalledWith('zieleBestaetigt', true)
    fireEvent.click(screen.getByRole('switch', { name: 'Paket bestätigt' }))
    expect(onWechsel).toHaveBeenCalledWith('paketBestaetigt', false)
  })
})
