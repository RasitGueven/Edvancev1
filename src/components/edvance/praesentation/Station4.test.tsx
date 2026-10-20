// Station 04 · Förderansatz (T4, Entscheidung 9): Kurve mit 1–4 Punkten,
// Auswahl per Tippen und Pfeiltasten, Förderfokus, Danach-Zeile, Hinweis und
// Empfehlung. Kontrollwerte aus Anhang C der Anforderung.
import { fireEvent, render, screen, within } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import type { ElternberichtFall } from '@/lib/report/elternbericht/fixtures'
import { Bausteinsatz } from '@/lib/report/bausteine'
import { PRAESENTATION_FAELLE } from '@/lib/report/praesentation/fixtures'
import type { ReportPaket } from '@/types'

import { Station4 } from './Station4'
import { daten, zeige } from './testStation34'

const F = PRAESENTATION_FAELLE
const punkte = (): HTMLElement[] => screen.queryAllByRole('tab')
const fokus = (): HTMLElement => screen.getByRole('tabpanel')

afterEach(() => {
  vi.restoreAllMocks()
})

describe('Station 04 — Kurve', () => {
  it.each([
    ['einSchwerpunkt', 1],
    ['zweiSchwerpunkte', 2],
    ['dreiSchwerpunkte', 3],
    ['ilkay', 4],
  ])('%s: %i Punkte ohne Zahlen, der erste vorgewählt', (fall, n) => {
    const { container } = zeige(Station4, F[fall])
    expect(punkte()).toHaveLength(n)
    expect(punkte()[0]).toHaveAttribute('aria-selected', 'true')
    for (const p of punkte().slice(1)) expect(p).toHaveAttribute('aria-selected', 'false')
    for (const k of container.querySelectorAll('.tp-s4-kugel')) expect(k.textContent).toBe('')
    for (const b of container.querySelectorAll('.tp-s4-label b')) expect(b.textContent).not.toMatch(/\d/)
    // Für die Ansichtstests: Kurve und alle Beschriftungen samt Karte markiert.
    expect(container.querySelectorAll('path[data-tp-kurve]')).toHaveLength(1)
    expect(container.querySelectorAll('[data-tp-beschriftung]')).toHaveLength(n + 1)
    expect(screen.getByText(n === 1 ? 'Ein Ansatzpunkt aus dem Test.' : `${n} Ansatzpunkte aus dem Test, in dieser Reihenfolge.`)).toBeInTheDocument()
  })

  it('ilkay: Reihenfolge wie R7, Beschriftung mit Klassenangabe, Vorlesetext', () => {
    zeige(Station4, F.ilkay)
    expect(punkte().map((p) => p.getAttribute('aria-label'))).toEqual([
      'Geometrie, Stoff aus Klasse 5–8',
      'Brüche & Dezimalzahlen, Stoff aus Klasse 5/6',
      'Größen, Stoff aus Klasse 5/6',
      'Prozent & Dreisatz, Stoff aus Klasse 7/8',
    ])
    expect(punkte().map((p) => p.className.match(/tp-s4-seite-(\w+)/)?.[1])).toEqual([
      'unten',
      'links',
      'linksOben',
      'linksOben',
    ])
  })

  it('Tippen und Pfeiltasten wechseln den Punkt, mit Umlauf', () => {
    zeige(Station4, F.ilkay)
    fireEvent.click(punkte()[2])
    expect(punkte()[2]).toHaveAttribute('aria-selected', 'true')
    expect(within(fokus()).getByRole('heading')).toHaveTextContent('Größen')

    fireEvent.keyDown(punkte()[2], { key: 'ArrowRight' })
    expect(punkte()[3]).toHaveAttribute('aria-selected', 'true')
    expect(document.activeElement).toBe(punkte()[3])
    fireEvent.keyDown(punkte()[3], { key: 'ArrowUp' })
    expect(punkte()[0]).toHaveAttribute('aria-selected', 'true')
    fireEvent.keyDown(punkte()[0], { key: 'ArrowLeft' })
    expect(punkte()[3]).toHaveAttribute('aria-selected', 'true')
    fireEvent.keyDown(punkte()[3], { key: 'ArrowDown' })
    expect(punkte()[2]).toHaveAttribute('aria-selected', 'true')
    expect(punkte().map((p) => p.tabIndex)).toEqual([-1, -1, 0, -1])
    expect(fokus()).toHaveAttribute('aria-labelledby', punkte()[2].id)
  })
})

describe('Station 04 — Förderfokus', () => {
  it('ilkay Geometrie: „Stoff aus Klasse 5–8", Listen mit „+2 weitere"', () => {
    zeige(Station4, F.ilkay)
    const karte = fokus()
    expect(within(karte).getByText('Förderfokus')).toBeInTheDocument()
    expect(within(karte).getByText('Stoff aus Klasse 5–8')).toBeInTheDocument()
    expect(within(karte).getByRole('heading')).toHaveTextContent('Geometrie')
    const [sicher, ueben] = within(karte).getAllByRole('list')
    expect(within(sicher).getAllByRole('listitem').map((li) => li.textContent)).toEqual([
      'Fläche von Rechteck und Quadrat',
    ])
    expect(within(ueben).getAllByRole('listitem').map((li) => li.textContent)).toEqual([
      'Umfang von Rechteck und Dreieck',
      'Maßstab',
      'Volumen und Oberfläche des Quaders',
      '+2 weitere',
    ])
  })

  it('ilkay Brüche: drei sichere Bereiche nach Anhang C', () => {
    zeige(Station4, F.ilkay)
    fireEvent.click(punkte()[1])
    expect(within(fokus()).getByText('Stoff aus Klasse 5/6')).toBeInTheDocument()
    expect(fokus()).toHaveTextContent('Bruch in Dezimalzahl')
    expect(fokus()).toHaveTextContent('Brüche multiplizieren')
    expect(fokus()).not.toHaveTextContent('weitere')
  })

  it('keinSicher: ohne Sicheres im Feld steht der Satz statt einer Liste', () => {
    zeige(Station4, F.nichtsSicher)
    expect(within(fokus()).getByText('In diesem Themenfeld war noch nichts sicher.')).toBeInTheDocument()
    expect(within(fokus()).getAllByRole('list')).toHaveLength(1)
  })
})

describe('Station 04 — Danach, Hinweis, ohne Schwerpunkt', () => {
  it('ilkay: Danach-Zeile und Hinweis', () => {
    zeige(Station4, F.ilkay)
    expect(screen.getByText('Danach nehmen wir Terme & Gleichungen und Zahlen & Rechnen dazu.')).toBeInTheDocument()
    expect(screen.getByText(/pädagogischer Arbeitsvorschlag/)).toBeInTheDocument()
  })

  it.each(['sechsFelderMitUebung', 'alleFelder'])('%s: Danach-Zeile mit allen übrigen Feldern', (fall) => {
    const p = daten(F[fall])
    expect(p.danach.length).toBeGreaterThan(0)
    zeige(Station4, F[fall])
    expect(screen.getByText(/^Danach nehmen wir .+ dazu\.$/)).toBeInTheDocument()
  })

  it('ohne „danach" keine Danach-Zeile', () => {
    zeige(Station4, F.einSchwerpunkt)
    expect(screen.queryByText(/^Danach nehmen wir/)).toBeNull()
    expect(screen.getByText(/pädagogischer Arbeitsvorschlag/)).toBeInTheDocument()
  })

  it('allesSicher: Titel und Satz ohne Übungsbedarf, keine Kurve, kein Hinweis, Empfehlung bleibt', () => {
    const { container } = zeige(Station4, F.allesSicher)
    expect(screen.getByRole('heading', { level: 2 })).toHaveTextContent(
      'Kein Übungsbedarf in den untersuchten Bereichen.',
    )
    expect(screen.getByText(/keinen Übungsbedarf\. Wir arbeiten am aktuellen Stoff weiter\./)).toBeInTheDocument()
    expect(container.querySelector('path[data-tp-kurve]')).toBeNull()
    expect(screen.queryByRole('tabpanel')).toBeNull()
    expect(screen.queryByText(/pädagogischer Arbeitsvorschlag/)).toBeNull()
    expect(screen.getByTestId('tp-empfehlung')).toHaveTextContent('Paket Premium')
  })
})

describe('Station 04 — Empfehlung', () => {
  const mitPaket = (paket: ReportPaket | null, fall: ElternberichtFall = F.ilkay): ElternberichtFall => ({
    ...fall,
    notes: fall.notes ? { ...fall.notes, paket } : null,
    tiers: fall.tiers.map((t) => ({ ...t, price_cents: 4900 + t.sort_order })),
  })

  it('premium: Paket fett, dahinter „Basic ist ebenfalls möglich."', () => {
    zeige(Station4, mitPaket('premium'))
    const zeile = screen.getByTestId('tp-empfehlung')
    expect(zeile).toHaveTextContent('Unsere Empfehlung für Ilkay: Paket PremiumBasic ist ebenfalls möglich.')
    expect(zeile.querySelector('b')).toHaveTextContent('Paket Premium')
  })

  it('basis: ohne Basic-Satz', () => {
    zeige(Station4, mitPaket('basis'))
    expect(screen.getByTestId('tp-empfehlung')).toHaveTextContent('Unsere Empfehlung für Ilkay: Paket Basic')
    expect(screen.getByTestId('tp-empfehlung')).not.toHaveTextContent('ebenfalls')
  })

  it('ohne Namen: „Unsere Empfehlung:"', () => {
    zeige(Station4, mitPaket('standard', F.ohneName))
    expect(screen.getByTestId('tp-empfehlung')).toHaveTextContent('Unsere Empfehlung: Paket Standard')
  })

  it('ohne Paket keine Zeile', () => {
    zeige(Station4, mitPaket(null))
    expect(screen.queryByTestId('tp-empfehlung')).toBeNull()
  })

  it('zwei aktive Pakete: keine Zeile', () => {
    vi.spyOn(console, 'warn').mockImplementation(() => {})
    const fall = mitPaket('premium')
    zeige(Station4, { ...fall, tiers: fall.tiers.map((t, i) => (i === 1 ? { ...t, active: false } : t)) })
    expect(screen.queryByTestId('tp-empfehlung')).toBeNull()
  })

  it('kein Preis und kein „€" im DOM', () => {
    const { container } = render(
      <Station4
        p={daten(mitPaket('premium'))}
        anzeige="kombiniert"
        satz={new Bausteinsatz([])}
        sessionId={F.ilkay.data.sessionId}
      />,
    )
    expect(container.innerHTML).not.toMatch(/€|EUR|49\d\d|\b49\b/)
  })
})
