// Station 04 · Förderansatz (T4, Entscheidung 9; PS-1 Entscheidungen 16–18):
// Kurve mit 1–3 Punkten, Auswahl per Tippen und Pfeiltasten, Förderfokus nur mit
// „Hier üben wir", Empfehlung und darunter der Hinweis. Kontrollwerte aus Anhang C.
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
    ['ilkay', 3],
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

  it('ilkay: die ersten drei in der Reihenfolge von R7, Beschriftung mit Klassenangabe, Vorlesetext', () => {
    expect(daten(F.ilkay).schwerpunkte).toHaveLength(4)
    zeige(Station4, F.ilkay)
    expect(punkte().map((p) => p.getAttribute('aria-label'))).toEqual([
      'Geometrie, Stoff aus Klasse 5–8',
      'Brüche & Dezimalzahlen, Stoff aus Klasse 5/6',
      'Größen, Stoff aus Klasse 5/6',
    ])
    expect(punkte().map((p) => p.className.match(/tp-s4-seite-(\w+)/)?.[1])).toEqual(['unten', 'links', 'linksOben'])
  })

  it('Tippen und Pfeiltasten wechseln den Punkt, mit Umlauf', () => {
    zeige(Station4, F.ilkay)
    fireEvent.click(punkte()[2])
    expect(punkte()[2]).toHaveAttribute('aria-selected', 'true')
    expect(within(fokus()).getByRole('heading')).toHaveTextContent('Größen')

    fireEvent.keyDown(punkte()[2], { key: 'ArrowRight' })
    expect(punkte()[0]).toHaveAttribute('aria-selected', 'true')
    expect(document.activeElement).toBe(punkte()[0])
    fireEvent.keyDown(punkte()[0], { key: 'ArrowUp' })
    expect(punkte()[1]).toHaveAttribute('aria-selected', 'true')
    fireEvent.keyDown(punkte()[1], { key: 'ArrowLeft' })
    expect(punkte()[0]).toHaveAttribute('aria-selected', 'true')
    fireEvent.keyDown(punkte()[0], { key: 'ArrowDown' })
    expect(punkte()[2]).toHaveAttribute('aria-selected', 'true')
    expect(punkte().map((p) => p.tabIndex)).toEqual([-1, -1, 0])
    expect(fokus()).toHaveAttribute('aria-labelledby', punkte()[2].id)
  })
})

describe('Station 04 — Förderfokus', () => {
  it('ilkay Geometrie: „Stoff aus Klasse 5–8", nur „Hier üben wir" mit „+2 weitere"', () => {
    zeige(Station4, F.ilkay)
    const karte = fokus()
    expect(within(karte).getByText('Förderfokus')).toBeInTheDocument()
    expect(within(karte).getByText('Stoff aus Klasse 5–8')).toBeInTheDocument()
    expect(within(karte).getByRole('heading')).toHaveTextContent('Geometrie')
    expect(within(karte).getByText('Hier üben wir')).toBeInTheDocument()
    expect(within(karte).queryByText('Sicher im Test')).toBeNull()
    expect(karte).not.toHaveTextContent('Fläche von Rechteck und Quadrat')
    const [ueben] = within(karte).getAllByRole('list')
    expect(within(karte).getAllByRole('list')).toHaveLength(1)
    expect(within(ueben).getAllByRole('listitem').map((li) => li.textContent)).toEqual([
      'Umfang von Rechteck und Dreieck',
      'Maßstab',
      'Volumen und Oberfläche des Quaders',
      '+2 weitere',
    ])
  })

  it('ilkay Brüche: drei Bereiche mit Übungsbedarf, kein Sicheres', () => {
    zeige(Station4, F.ilkay)
    fireEvent.click(punkte()[1])
    expect(within(fokus()).getByText('Stoff aus Klasse 5/6')).toBeInTheDocument()
    expect(fokus()).toHaveTextContent('Brüche multiplizieren')
    expect(fokus()).not.toHaveTextContent('Bruch in Dezimalzahl')
    expect(fokus()).not.toHaveTextContent('weitere')
  })

  it('Thema: Schild „Ihr Thema", die Startstelle zuerst (abgestuft)', () => {
    const p = daten(F.abgestuft)
    zeige(Station4, F.abgestuft)
    expect(within(fokus()).getByTestId('tp-s4-chip-thema')).toBeInTheDocument()
    expect(within(fokus()).getAllByRole('listitem')[0]).toHaveTextContent(p.schwerpunkte[0].start!)
  })

  it.each(Object.keys(F).filter((f) => f !== 'ohneKatalog'))('%s: kein „Sicher im Test", höchstens 3 Punkte', (fall) => {
    zeige(Station4, F[fall])
    expect(screen.queryByText('Sicher im Test')).toBeNull()
    expect(punkte().length).toBeLessThanOrEqual(3)
  })
})

describe('Station 04 — kein „danach", Hinweis als Caption, ohne Schwerpunkt', () => {
  it('ilkay: keine Danach-Zeile, der Hinweis steht unter der Empfehlung', () => {
    const { container } = zeige(Station4, F.ilkay)
    expect(screen.queryByText(/^Danach nehmen wir/)).toBeNull()
    expect(container.querySelector('.tp-s4-danach')).toBeNull()
    const hinweis = screen.getByText(/pädagogischer Arbeitsvorschlag/)
    expect(screen.getByTestId('tp-empfehlung').nextElementSibling).toBe(hinweis)
  })

  it.each(['sechsFelderMitUebung', 'alleFelder'])('%s: „danach" bleibt in den Daten, steht aber nicht in der Station', (fall) => {
    expect(daten(F[fall]).danach.length).toBeGreaterThan(0)
    zeige(Station4, F[fall])
    expect(screen.queryByText(/^Danach nehmen wir/)).toBeNull()
  })

  it('einSchwerpunkt: der Hinweis bleibt', () => {
    zeige(Station4, F.einSchwerpunkt)
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
