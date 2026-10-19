// Rahmen der Tablet-Präsentation (T2): Portal, Laden, Kopf, Leiste, Intro,
// Escape und der Hinweis ohne Rechnung. Daten aus PRAESENTATION_FAELLE.
import { act, fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { PRAESENTATION_FAELLE } from '@/lib/report/praesentation/fixtures'
import type { ElternberichtFall } from '@/lib/report/elternbericht/fixtures'

import { Praesentation, type PraesentationProps } from './Praesentation'

function oeffne(fall: ElternberichtFall, extra: Partial<PraesentationProps> = {}) {
  const onSchliessen = vi.fn()
  const r = render(
    <Praesentation
      data={fall.data}
      notes={fall.notes}
      tiers={fall.tiers}
      tiersFehler={false}
      sessionId={fall.data.sessionId}
      laden={false}
      onSchliessen={onSchliessen}
      {...extra}
    />,
  )
  return { ...r, onSchliessen }
}

const { ilkay, testlauf, laeuftNoch, ohneKatalog, ohneName } = PRAESENTATION_FAELLE
const dialog = (): HTMLElement => screen.getByRole('dialog')
const leiste = (): HTMLElement => screen.getByRole('navigation', { name: 'Stationen direkt anwählen' })

afterEach(() => {
  document.documentElement.classList.remove('tp-offen')
})

describe('Präsentation — Vollbild', () => {
  it('hängt per Portal direkt unter document.body, nicht im eigenen Container', () => {
    const { container } = oeffne(ilkay)
    expect(container.querySelector('.tp')).toBeNull()
    expect(dialog().parentElement).toBe(document.body)
    expect(dialog()).toHaveClass('tp')
    expect(dialog()).toHaveAttribute('aria-label', 'Lernstandspräsentation Ilkay')
  })

  it('setzt tp-offen an <html> nur, solange sie offen ist', () => {
    const { unmount } = oeffne(ilkay)
    expect(document.documentElement).toHaveClass('tp-offen')
    unmount()
    expect(document.documentElement).not.toHaveClass('tp-offen')
  })

  it('schließt mit Escape', () => {
    const { onSchliessen } = oeffne(ilkay)
    fireEvent.keyDown(document, { key: 'Escape' })
    expect(onSchliessen).toHaveBeenCalledTimes(1)
  })

  it('nennt ohne Namen keinen Namen', () => {
    oeffne(ohneName)
    expect(dialog()).toHaveAttribute('aria-label', 'Lernstandspräsentation')
    expect(screen.getByRole('heading', { level: 1, name: 'Ihr Kind' })).toBeInTheDocument()
  })
})

describe('Präsentation — Laden und ohne Rechnung', () => {
  it('zeigt LoadingPulse, solange geladen wird, und noch keine Station', () => {
    oeffne(ilkay, { laden: true })
    expect(screen.getByTestId('tp-laden')).toBeInTheDocument()
    expect(document.querySelector('.tp-station')).toBeNull()
  })

  it('zeigt LoadingPulse auch ohne Daten', () => {
    oeffne(ilkay, { data: null, laden: true })
    expect(screen.getByTestId('tp-laden')).toBeInTheDocument()
  })

  it('zeigt ohne Katalog den EmptyState mit Schließen', () => {
    const { onSchliessen } = oeffne(ohneKatalog)
    const leer = screen.getByTestId('tp-leer')
    expect(leer).toHaveTextContent('Der Aufgabenkatalog konnte nicht geladen werden.')
    expect(document.querySelector('.tp-station')).toBeNull()
    fireEvent.click(within(leer).getByRole('button', { name: 'Präsentation schließen' }))
    expect(onSchliessen).toHaveBeenCalledTimes(1)
  })

  it('zeigt ohne Kompetenzen den Hinweis „leer"', () => {
    const data = { ...ilkay.data, erzaehlung: { ...ilkay.data.erzaehlung, kompetenzen: [] } }
    oeffne({ ...ilkay, data })
    expect(screen.getByTestId('tp-leer')).toHaveTextContent('keine direkt geprüften Bereiche')
  })
})

describe('Präsentation — Kopf', () => {
  it('zeigt den Chip „Testdaten" nur im Testlauf', () => {
    oeffne(testlauf)
    expect(within(dialog()).getByText('Testdaten')).toBeInTheDocument()
  })

  it('zeigt keinen Chip bei einer echten, abgeschlossenen Analyse', () => {
    oeffne(ilkay)
    expect(within(dialog()).queryByText('Testdaten')).toBeNull()
    expect(within(dialog()).queryByText('Analyse läuft noch')).toBeNull()
  })

  it('zeigt „Analyse läuft noch" nur bei laufender Analyse', () => {
    oeffne(laeuftNoch)
    expect(within(dialog()).getByText('Analyse läuft noch')).toBeInTheDocument()
    expect(within(dialog()).queryByText('Testdaten')).toBeNull()
  })

  it('zeigt die Station zweistellig und schließt per Knopf', () => {
    const { onSchliessen } = oeffne(ilkay)
    expect(within(dialog()).getByText('01 / 04 · Überblick')).toBeInTheDocument()
    fireEvent.click(within(leiste()).getByRole('button', { name: /Einordnung/ }))
    expect(within(dialog()).getByText('03 / 04 · Einordnung')).toBeInTheDocument()
    fireEvent.click(within(dialog()).getByRole('button', { name: 'Präsentation schließen' }))
    expect(onSchliessen).toHaveBeenCalledTimes(1)
  })

  it('führt über das Logo zu 01', () => {
    oeffne(ilkay)
    fireEvent.click(within(leiste()).getByRole('button', { name: /Förderansatz/ }))
    fireEvent.click(within(dialog()).getByRole('button', { name: 'Zum Überblick' }))
    expect(within(leiste()).getByRole('button', { name: /Überblick/ })).toHaveAttribute('aria-current', 'step')
  })
})

describe('Präsentation — Leiste', () => {
  it('hat vier Einträge und springt per Tippen; aria-current wandert mit', () => {
    oeffne(ilkay)
    const eintraege = within(leiste()).getAllByRole('button')
    expect(eintraege.map((e) => e.textContent)).toEqual([
      '01Überblick',
      '02Lernstand',
      '03Einordnung',
      '04Förderansatz',
    ])
    expect(eintraege.filter((e) => e.hasAttribute('aria-current'))).toHaveLength(0)

    fireEvent.click(eintraege[1])
    expect(eintraege[1]).toHaveAttribute('aria-current', 'step')
    fireEvent.click(eintraege[3])
    expect(eintraege[3]).toHaveAttribute('aria-current', 'step')
    expect(eintraege[1]).not.toHaveAttribute('aria-current')
  })

  it('setzt entered beim Sprung und motion-complete beim Verlassen', () => {
    oeffne(ilkay)
    const station = (n: number) => document.querySelector(`.tp-station[data-station="${n}"]`)!
    fireEvent.click(within(leiste()).getByRole('button', { name: /Lernstand/ }))
    expect(station(2)).toHaveClass('entered')
    expect(station(2)).not.toHaveClass('motion-complete')
    fireEvent.click(within(leiste()).getByRole('button', { name: /Einordnung/ }))
    expect(station(2)).toHaveClass('motion-complete')
    expect(station(3)).toHaveClass('entered')
  })
})

describe('Präsentation — Intro', () => {
  // Per Klasse: eine ausgeblendete Region hat für getByRole keinen Namen mehr.
  const intro = (): HTMLElement => document.querySelector<HTMLElement>('.tp-intro')!

  it('ist eine Region „Einführung"', () => {
    oeffne(ilkay)
    expect(screen.getByRole('region', { name: 'Einführung' })).toBe(intro())
  })


  it('erscheint genau einmal je Öffnen', async () => {
    const { unmount } = oeffne(ilkay)
    expect(intro()).toBeVisible()
    expect(within(intro()).getByText('Lernstandsanalyse Mathematik')).toBeInTheDocument()
    expect(within(intro()).getByRole('heading', { level: 1, name: 'Ilkay' })).toBeInTheDocument()
    expect(dialog().querySelector('.tp-buehne')).toHaveClass('tp-am-intro')

    fireEvent.click(within(intro()).getByRole('button', { name: /Gemeinsam ansehen/ }))
    expect(within(leiste()).getByRole('button', { name: /Überblick/ })).toHaveAttribute('aria-current', 'step')
    expect(dialog().querySelector('.tp-buehne')).not.toHaveClass('tp-am-intro')

    // Nach der Ruhe verlässt das Intro den Fluss und kommt nicht wieder.
    await waitFor(() => expect(intro()).not.toBeVisible(), { timeout: 2000 })
    fireEvent.click(within(leiste()).getByRole('button', { name: /Lernstand/ }))
    await act(() => new Promise((r) => setTimeout(r, 1200)))
    expect(intro()).not.toBeVisible()

    // Erneut öffnen: wieder mit Intro.
    unmount()
    oeffne(ilkay)
    expect(intro()).toBeVisible()
  })
})
