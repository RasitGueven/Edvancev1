// Seite 5 des Eltern-Berichts (Bericht v2): Pakete, Vorschlag, Ziele, Kontakt.
import { render, within } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { ElternberichtBogen } from '@/components/edvance/elternbericht/Bogen'
import { paketWahl } from '@/components/edvance/elternbericht/seite5Rechnung'
import de from '@/i18n/locales/de/elternbericht.json'
import { KONTAKT } from '@/lib/report/elternbericht/berichtKonfig'
import { FAELLE, NOTIZEN, TIERS } from '@/lib/report/elternbericht/fixtures'
import type { ReportData, ReportErstgespraech, ReportNotes, TierPlan } from '@/types'

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

const karte = (s: ReturnType<typeof seite5>, i: number): HTMLElement => s.getAllByTestId('eb-paket')[i]
const vorgeschlagen = (s: ReturnType<typeof seite5>): string[] =>
  s.getAllByTestId('eb-paket').flatMap((k) => (k.hasAttribute('data-vorschlag') ? [k.querySelector('.eb-s5-karte-name')!.textContent!] : []))
const eg = (teil: Partial<ReportErstgespraech>): ReportErstgespraech => ({
  note: null,
  trend: null,
  seit: null,
  ziele: null,
  klassenarbeit: null,
  klassenarbeitDatum: null,
  ...teil,
})

describe('Seite 5 — Pakete', () => {
  it('nur Basic, Standard, Premium, je mit Name und Rhythmus (erstes Merkmal)', () => {
    const s = seite5(FAELLE.ilkay)
    expect(s.getByRole('heading', { level: 1 })).toHaveTextContent('Unsere Einschätzung für Ilkay.')
    const karten = s.getAllByTestId('eb-paket')
    expect(karten.map((k) => k.querySelector('.eb-s5-karte-name')?.textContent)).toEqual(['Basic', 'Standard', 'Premium'])
    expect(karten.map((k) => k.querySelector('.eb-s5-merkmal-1')?.textContent)).toEqual([
      '1 Session pro Woche',
      '1,5 Sessions pro Woche',
      '2 Sessions pro Woche',
    ])
    // Weitere Merkmale, Konditionen und Preise stehen nirgends.
    expect(s.el).not.toHaveTextContent(/1 Fach|bis zu 2 Fächer|Konditionen|Preis|Laufzeit|€/)
    for (const k of karten) expect(k.querySelector('.eb-s5-merkmal-2')).toBeNull()
  })

  it('nennt auch bei hinterlegtem Preis keinen Preis', () => {
    const tiers = TIERS.map((p) => ({ ...p, price_cents: 9900 }))
    expect(seite5({ ...FAELLE.ilkay, tiers }).el).not.toHaveTextContent(/€|\b99\b|\bPreis|Laufzeit/)
  })

  it('ohne Pakete entfällt der Abschnitt, und mit ihm der Vorschlagssatz', () => {
    const s = seite5({ ...FAELLE.ilkay, tiers: [] })
    expect(s.queryByTestId('eb-pakete')).toBeNull()
    expect(s.queryByTestId('eb-vorschlag')).toBeNull()
  })

  it('zwei bzw. vier aktive Pakete: keine Hervorhebung, kein Satz, Warnung', () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined)
    for (const tiers of [TIERS.slice(0, 2), [...TIERS, vierter]]) {
      const s = seite5({ ...FAELLE.ilkay, tiers })
      expect(s.getAllByTestId('eb-paket')).toHaveLength(tiers.length)
      expect(vorgeschlagen(s)).toEqual([])
      expect(s.queryByTestId('eb-vorschlag')).toBeNull()
    }
    expect(warn).toHaveBeenCalledTimes(2)
  })
})

describe('Seite 5 — Vorschlag des Systems', () => {
  it('ilkay: Premium hervorgehoben mit Schild „Vorschlag“, Satz mit Begründung und „nicht verpflichtend“', () => {
    const s = seite5(FAELLE.ilkay)
    expect(vorgeschlagen(s)).toEqual(['Premium'])
    expect(karte(s, 2)).toHaveTextContent('Vorschlag')
    expect(karte(s, 2)).not.toHaveTextContent('Empfehlung Ihres Coachs')
    expect(karte(s, 0)).toHaveTextContent('Mitgliedschaft')
    expect(s.getByTestId('eb-vorschlag-zeile').textContent).toBe(
      'Auf Grundlage der Lernstandsanalyse schlagen wir Premium vor, weil 16 von 27 geprüften Bereichen Übungsbedarf zeigen, verteilt auf 4 Schwerpunkte.',
    )
    expect(s.getByTestId('eb-vorschlag')).toHaveTextContent('nicht verpflichtend')
    expect(s.getByTestId('eb-vorschlag')).toHaveTextContent('Ein Start mit Basic ist möglich.')
  })

  it('der Vorschlag kommt aus den Daten, nicht aus den Coach-Notizen (ohneNotizen, notes.paket „basis“)', () => {
    expect(vorgeschlagen(seite5(FAELLE.ohneNotizen))).toEqual(['Premium'])
    expect(vorgeschlagen(seite5({ ...FAELLE.ilkay, notes: { ...NOTIZEN, paket: 'basis' } }))).toEqual(['Premium'])
    expect(vorgeschlagen(seite5({ ...FAELLE.ilkay, notes: { ...NOTIZEN, paket: null } }))).toEqual(['Premium'])
  })

  it('Standard bei verteiltem Übungsbedarf, mit dem passenden Grund', () => {
    const s = seite5(FAELLE.klasse7)
    expect(vorgeschlagen(s).length).toBe(1)
    expect(s.getByTestId('eb-vorschlag-zeile').textContent).toMatch(/^Auf Grundlage der Lernstandsanalyse schlagen wir \w+ vor, weil /)
  })

  it('Basic nur ohne Übungsbedarf: Satz „nur wenige Bereiche“, ohne den Hinweis auf einen Start mit Basic', () => {
    const s = seite5(FAELLE.allesSicher)
    expect(vorgeschlagen(s)).toEqual(['Basic'])
    expect(s.getByTestId('eb-vorschlag-zeile').textContent).toBe(
      'Auf Grundlage der Lernstandsanalyse schlagen wir Basic vor, weil nur wenige Bereiche Übungsbedarf zeigen.',
    )
    expect(s.getByTestId('eb-vorschlag').querySelector('.eb-s5-vorschlag-frei')?.textContent).toBe(
      'Das ist ein Vorschlag und nicht verpflichtend.',
    )
  })
})

describe('Seite 5 — Bestätigung durch den Coach', () => {
  const bestaetigt = (paket: ReportNotes['paket']): ReportNotes => ({ ...NOTIZEN, paket, paketBestaetigt: true })

  it('bestätigtes Paket gilt: Schild „Empfehlung Ihres Coachs“ und eigener Satz', () => {
    const s = seite5({ ...FAELLE.ilkay, notes: bestaetigt('standard') })
    expect(vorgeschlagen(s)).toEqual(['Standard'])
    expect(karte(s, 1)).toHaveTextContent('Empfehlung Ihres Coachs')
    expect(s.getByTestId('eb-vorschlag-zeile').textContent).toBe(
      'Auf Grundlage der Lernstandsanalyse empfiehlt Ihr Coach Standard.',
    )
    expect(s.el).not.toHaveTextContent('schlagen wir')
  })

  it('bestätigt der Coach, was das System vorschlägt: Schild „Empfehlung Ihres Coachs“, Begründung bleibt', () => {
    const s = seite5({ ...FAELLE.ilkay, notes: bestaetigt('premium') })
    expect(vorgeschlagen(s)).toEqual(['Premium'])
    expect(karte(s, 2)).toHaveTextContent('Empfehlung Ihres Coachs')
    expect(s.getByTestId('eb-vorschlag-zeile')).toHaveTextContent('schlagen wir Premium vor, weil 16 von 27')
  })

  it('bestätigt ohne Paket: es bleibt beim Vorschlag des Systems', () => {
    const s = seite5({ ...FAELLE.ilkay, notes: bestaetigt(null) })
    expect(vorgeschlagen(s)).toEqual(['Premium'])
    expect(karte(s, 2)).not.toHaveTextContent('Empfehlung Ihres Coachs')
  })

  it('nicht bestätigt (paketBestaetigt fehlt oder false): die Wahl in den Notizen wird nicht übernommen', () => {
    for (const notes of [{ ...NOTIZEN, paket: 'basis' as const }, { ...NOTIZEN, paket: 'basis' as const, paketBestaetigt: false }]) {
      const s = seite5({ ...FAELLE.ilkay, notes })
      expect(vorgeschlagen(s)).toEqual(['Premium'])
      expect(s.el).not.toHaveTextContent('empfiehlt Ihr Coach')
    }
  })
})

describe('Seite 5 — Ziele', () => {
  const ziele = (fall: Parameters<typeof seite5>[0]): string | undefined =>
    seite5(fall).queryByTestId('eb-ziele')?.querySelector('.eb-s5-ziele-text')?.textContent ?? undefined

  it('Zielbild des Coachs, Überschrift „Ziele für die nächsten 6 Monate“', () => {
    const s = seite5(FAELLE.ilkay)
    expect(s.getByTestId('eb-ziele').querySelector('.eb-kicker')).toHaveTextContent('Ziele für die nächsten 6 Monate')
    expect(ziele(FAELLE.ilkay)).toBe(NOTIZEN.zielbild)
  })

  it('ohne Zielbild die Ziele aus dem Erstgespräch; das Zielbild geht vor', () => {
    const data = { ...FAELLE.ilkay.data, erstgespraech: eg({ ziele: 'Versetzung sichern.' }) }
    expect(ziele({ ...FAELLE.ilkay, data, notes: { ...NOTIZEN, zielbild: '  ' } })).toBe('Versetzung sichern.')
    expect(ziele({ ...FAELLE.ilkay, data, notes: null })).toBe('Versetzung sichern.')
    expect(ziele({ ...FAELLE.ilkay, data })).toBe(NOTIZEN.zielbild)
  })

  it('weder Zielbild noch Erstgespräch: der Abschnitt entfällt', () => {
    expect(ziele(FAELLE.ohneNotizen)).toBeUndefined()
    expect(ziele({ ...FAELLE.ilkay, notes: { ...NOTIZEN, zielbild: '' } })).toBeUndefined()
    const leer = { ...FAELLE.ilkay.data, erstgespraech: eg({ ziele: null }) }
    expect(ziele({ ...FAELLE.ilkay, data: leer, notes: null })).toBeUndefined()
  })
})

describe('Seite 5 — Kontakt', () => {
  afterEach(() => {
    KONTAKT.telefon = null
  })

  it('Ansprechpartner mit Name, „Ihr persönlicher Ansprechpartner“ und Mail-Link', () => {
    const k = within(seite5(FAELLE.ilkay).getByTestId('eb-kontakt'))
    expect(k.getByText('Rasit Güven')).toBeInTheDocument()
    expect(k.getByText('Ihr persönlicher Ansprechpartner')).toBeInTheDocument()
    expect(k.getByRole('link', { name: 'rasit@edvanceacademy.de' })).toHaveAttribute('href', 'mailto:rasit@edvanceacademy.de')
  })

  it('ohne Ansprechpartner: Team und allgemeine Adresse, keine Rolle', () => {
    const { data } = FAELLE.ilkay
    const s = seite5({
      ...FAELLE.ilkay,
      data: { ...data, erzaehlung: { ...data.erzaehlung, ansprechpartner: { name: null, email: null } } },
    })
    const k = within(s.getByTestId('eb-kontakt'))
    expect(k.getByText('Das Edvance-Team')).toBeInTheDocument()
    expect(k.queryByText('Ihr persönlicher Ansprechpartner')).toBeNull()
    expect(k.getByRole('link', { name: 'hello@edvanceacademy.de' })).toHaveAttribute('href', 'mailto:hello@edvanceacademy.de')
  })

  it('Telefonzeile entfällt, solange KONTAKT.telefon null ist', () => {
    expect(KONTAKT.telefon).toBeNull()
    const s = seite5(FAELLE.ilkay)
    expect(s.queryByTestId('eb-telefon')).toBeNull()
    expect(s.el).not.toHaveTextContent(/Telefon/)
  })

  it('mit hinterlegter Nummer steht die Zeile', () => {
    KONTAKT.telefon = '0221 123456'
    expect(seite5(FAELLE.ilkay).getByTestId('eb-telefon')).toHaveTextContent('Telefon 0221 123456')
  })

  it('Fragen oder Entscheidung: Antwortversprechen und Vertragssatz', () => {
    const k = within(seite5(FAELLE.ilkay).getByTestId('eb-kontakt'))
    expect(k.getByText(/Sie können sich direkt entscheiden/)).toBeInTheDocument()
    expect(k.getByText(de.s5.fragen.vertrag)).toBeInTheDocument()
  })

  it('ohneName: Titel ohne Namen', () => {
    expect(seite5(FAELLE.ohneName).getByRole('heading', { level: 1 })).toHaveTextContent('Unsere Einschätzung für Ihr Kind.')
  })
})
