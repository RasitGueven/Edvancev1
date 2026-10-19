// Seite 5 des Eltern-Berichts R7 (Nächste Schritte).
import { render, within } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { ElternberichtBogen } from '@/components/edvance/elternbericht/Bogen'
import { paketWahl } from '@/components/edvance/elternbericht/seite5Rechnung'
import { FAELLE, NOTIZEN, TIERS } from '@/lib/report/elternbericht/fixtures'
import type { ReportData, ReportNotes, TierPlan } from '@/types'

function seite5(fall: { data: ReportData; notes: ReportNotes | null; tiers: TierPlan[] }) {
  const { container } = render(<ElternberichtBogen {...fall} />)
  const el = container.querySelector<HTMLElement>('.eb-seite[data-seite="5"]')!
  return { ...within(el), el }
}

const vierter: TierPlan = { ...TIERS[2], id: 'vier', name: 'Intensiv', sort_order: 4 }

afterEach(() => vi.restoreAllMocks())

describe('paketWahl', () => {
  it('ordnet basis/standard/premium dem 1./2./3. aktiven Paket zu', () => {
    expect(paketWahl(TIERS, 'basis').vorschlag?.name).toBe('Basic')
    expect(paketWahl(TIERS, 'standard').vorschlag?.name).toBe('Standard')
    expect(paketWahl([...TIERS].reverse(), 'premium').vorschlag?.name).toBe('Premium')
  })

  it('nimmt nur aktive Pakete, nach sort_order', () => {
    const tiers = [{ ...TIERS[0], active: false }, ...TIERS.slice(1)]
    const w = paketWahl(tiers, 'basis')
    expect(w.pakete.map((p) => p.name)).toEqual(['Standard', 'Premium'])
    expect(w.vorschlag).toBeNull()
  })
})

describe('Seite 5', () => {
  it('mit Paket: Zeile mit Name und erstem Merkmal, Karte hervorgehoben', () => {
    const s = seite5(FAELLE.ilkay)
    expect(s.getByRole('heading', { level: 1 })).toHaveTextContent('Unsere Einschätzung für Ilkay.')
    expect(s.getByTestId('eb-vorschlag')).toHaveTextContent('Vorschlag')
    expect(s.getByTestId('eb-vorschlag')).toHaveTextContent(
      'Welcher Rhythmus zu Ilkay passt, legen wir gemeinsam im Gespräch fest.',
    )
    expect(s.getByTestId('eb-vorschlag-zeile')).toHaveTextContent(
      'Vorschlag des Coachs: Premium, 2 Sessions pro Woche. Vier Förderthemen, die regelmäßig Wiederholung brauchen.',
    )
    const karten = s.getAllByTestId('eb-paket')
    expect(karten.map((k) => k.querySelector('.eb-s5-karte-name')?.textContent)).toEqual([
      'Basic',
      'Standard',
      'Premium',
    ])
    expect(karten.map((k) => k.hasAttribute('data-vorschlag'))).toEqual([false, false, true])
    expect(karten[2]).toHaveTextContent('Coach-Vorschlag')
    expect(karten[2]).not.toHaveTextContent('Mitgliedschaft')
    expect(karten[0]).toHaveTextContent('Mitgliedschaft')
    expect(karten[0]).toHaveTextContent('1 Session pro Woche')
    expect(karten[0]).toHaveTextContent('1 Fach')
    expect(karten[0]).toHaveTextContent('Konditionen im Gespräch')
  })

  it('ohne Paket: nur die Empfehlung, keine Hervorhebung', () => {
    const s = seite5({ ...FAELLE.ilkay, notes: { ...NOTIZEN, paket: null } })
    expect(s.getByTestId('eb-vorschlag-zeile').textContent).toBe(NOTIZEN.empfehlung)
    expect(s.getAllByTestId('eb-paket').some((k) => k.hasAttribute('data-vorschlag'))).toBe(false)
  })

  it('ohneNotizen: keine Zeile im Navy-Kasten, keine Hervorhebung', () => {
    const s = seite5(FAELLE.ohneNotizen)
    expect(s.queryByTestId('eb-vorschlag-zeile')).toBeNull()
    expect(s.getAllByTestId('eb-paket').some((k) => k.hasAttribute('data-vorschlag'))).toBe(false)
  })

  it('zwei bzw. vier aktive Pakete: keine Hervorhebung, Warnung', () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined)
    for (const tiers of [TIERS.slice(0, 2), [...TIERS, vierter]]) {
      const s = seite5({ ...FAELLE.ilkay, tiers })
      const karten = s.getAllByTestId('eb-paket')
      expect(karten).toHaveLength(tiers.length)
      expect(karten.some((k) => k.hasAttribute('data-vorschlag'))).toBe(false)
      // Ohne eindeutiges Paket nur die Empfehlung.
      expect(s.getByTestId('eb-vorschlag-zeile').textContent).toBe(NOTIZEN.empfehlung)
    }
    expect(warn).toHaveBeenCalledTimes(2)
  })

  it('ohne Pakete entfällt der Abschnitt samt Hinweis', () => {
    const s = seite5({ ...FAELLE.ilkay, tiers: [] })
    expect(s.queryByTestId('eb-pakete')).toBeNull()
    expect(s.el).not.toHaveTextContent('Konditionen besprechen wir persönlich')
  })

  it('Ansprechpartner mit Name, Rolle und Mail-Link', () => {
    const k = within(seite5(FAELLE.ilkay).getByTestId('eb-kontakt'))
    expect(k.getByText('Rasit Güven')).toBeInTheDocument()
    expect(k.getByText('hat die Analyse begleitet')).toBeInTheDocument()
    expect(k.getByRole('link', { name: 'rasit@edvanceacademy.de' })).toHaveAttribute(
      'href',
      'mailto:rasit@edvanceacademy.de',
    )
    expect(k.getByText(/Sie können sich direkt entscheiden/)).toBeInTheDocument()
  })

  it('ohne Ansprechpartner: Team und allgemeine Adresse, keine Rolle', () => {
    const { data } = FAELLE.ilkay
    const s = seite5({
      ...FAELLE.ilkay,
      data: { ...data, erzaehlung: { ...data.erzaehlung, ansprechpartner: { name: null, email: null } } },
    })
    const k = within(s.getByTestId('eb-kontakt'))
    expect(k.getByText('Das Edvance-Team')).toBeInTheDocument()
    expect(k.queryByText('hat die Analyse begleitet')).toBeNull()
    expect(k.getByRole('link', { name: 'hello@edvanceacademy.de' })).toHaveAttribute(
      'href',
      'mailto:hello@edvanceacademy.de',
    )
  })

  it('nennt keinen Preis und keine Laufzeit', () => {
    const tiers = TIERS.map((p) => ({ ...p, price_cents: 9900 }))
    const s = seite5({ ...FAELLE.ilkay, tiers })
    expect(s.el).not.toHaveTextContent(/€|99|Monat|Laufzeit:/)
  })

  it('ohneName: Titel ohne Namen', () => {
    const s = seite5(FAELLE.ohneName)
    expect(s.getByRole('heading', { level: 1 })).toHaveTextContent('Unsere Einschätzung für Ihr Kind.')
    expect(s.getByTestId('eb-vorschlag')).toHaveTextContent(
      'Welcher Rhythmus passt, legen wir gemeinsam im Gespräch fest.',
    )
  })
})
