// Seite 5 des Eltern-Berichts (Bericht v2): Pakete, Vorschlag, Ziele, Kontakt.
import { render, within } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { ElternberichtBogen } from '@/components/edvance/elternbericht/Bogen'
import { paketWahl } from '@/components/edvance/elternbericht/seite5Rechnung'
import de from '@/i18n/locales/de/elternbericht.json'
import { KONTAKT, TABLET_LINK } from '@/lib/report/elternbericht/berichtKonfig'
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
      'Passend dazu schlagen wir Premium vor, weil 16 von 27 geprüften Bereichen Übungsbedarf zeigen, verteilt auf 4 Schwerpunkte.',
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
    expect(s.getByTestId('eb-vorschlag-zeile').textContent).toMatch(/^Passend dazu schlagen wir \w+ vor, weil /)
  })

  it('Basic nur ohne Übungsbedarf: Satz „nur wenige Bereiche“, ohne den Hinweis auf einen Start mit Basic', () => {
    const s = seite5(FAELLE.allesSicher)
    expect(vorgeschlagen(s)).toEqual(['Basic'])
    expect(s.getByTestId('eb-vorschlag-zeile').textContent).toBe(
      'Passend dazu schlagen wir Basic vor, weil nur wenige Bereiche Übungsbedarf zeigen.',
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
      'Passend dazu empfiehlt Ihr Coach Standard.',
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

describe('Seite 5 — Fazit', () => {
  const fazit = (fall: Parameters<typeof seite5>[0]): string | undefined =>
    seite5(fall).queryByTestId('eb-s5-fazit')?.textContent ?? undefined

  it('das Fazit ersetzt den Einleitungstext und fasst Seite 1 bis 4 zusammen', () => {
    const s = seite5(FAELLE.ilkay)
    const text = s.getByTestId('eb-s5-fazit').textContent!
    expect(text).toContain('Die Lücken liegen vor allem im Stoff von')
    expect(text).toContain('Wir beginnen mit')
    expect(s.el).not.toHaveTextContent('Der Bericht endet nicht mit einer Zahl')
  })

  it('das Fazit nutzt dieselben Daten wie Seite 1 (Startsatz)', () => {
    const { container } = render(<ElternberichtBogen {...FAELLE.ilkay} />)
    const start = container.querySelector('[data-seite="1"] [data-testid="eb-start"]')?.textContent
    expect(start).toBeTruthy()
    expect(fazit(FAELLE.ilkay)).toContain(start!.trim())
  })

  it('alles sicher: kein Lückensatz', () => {
    expect(fazit(FAELLE.allesSicher) ?? '').not.toContain('Die Lücken liegen')
  })
})

describe('Seite 5 — Ziele', () => {
  const liste = (fall: Parameters<typeof seite5>[0]): string[] | undefined => {
    const el = seite5(fall).queryByTestId('eb-ziele')
    return el ? [...el.querySelectorAll('.eb-s5-ziele-liste li')].map((x) => x.textContent ?? '') : undefined
  }
  const bestaetigt = (zielbild: string, paket: ReportNotes['paket'] = null): ReportNotes => ({
    ...NOTIZEN,
    zielbild,
    paket,
    zieleBestaetigt: true,
  })

  it('ohne Bestätigung keine Ziele, auch nicht das Zielbild des Coachs', () => {
    expect(liste(FAELLE.ilkay)).toBeUndefined()
    expect(liste({ ...FAELLE.ilkay, notes: { ...NOTIZEN, zieleBestaetigt: false } })).toBeUndefined()
    expect(liste({ ...FAELLE.ilkay, notes: null })).toBeUndefined()
    expect(seite5(FAELLE.ilkay).el).not.toHaveTextContent(NOTIZEN.zielbild)
  })

  it('bestätigt: das Zielbild des Coachs, Überschrift „Ziele für die nächsten 6 Monate“', () => {
    const fall = { ...FAELLE.ilkay, notes: bestaetigt(NOTIZEN.zielbild) }
    expect(seite5(fall).getByTestId('eb-ziele').querySelector('.eb-kicker')).toHaveTextContent('Ziele für die nächsten 6 Monate')
    expect(liste(fall)).toEqual([NOTIZEN.zielbild])
  })

  it('bestätigt ohne Zielbild: der Systemvorschlag, Anzahl nach Paket (2, 3, 4)', () => {
    const je = (paket: 'basis' | 'standard' | 'premium') => liste({ ...FAELLE.ilkay, notes: { ...bestaetigt('  ', paket), paketBestaetigt: true } })!
    expect(je('basis')).toEqual(['Flächen und Figuren sicher anwenden', 'Brüche und Dezimalzahlen sicher anwenden'])
    expect(je('standard')).toHaveLength(3)
    expect(je('premium')).toEqual([
      'Flächen und Figuren sicher anwenden',
      'Brüche und Dezimalzahlen sicher anwenden',
      'Größen und Einheiten sicher anwenden',
      'Prozent- und Dreisatzrechnung sicher anwenden',
    ])
  })

  it('das bestätigte Paket bestimmt die Anzahl; ohne Bestätigung gilt der Vorschlag des Systems', () => {
    // ilkay: Vorschlag Premium (4 Schwerpunkte), bestätigt Basic (2).
    const notes: ReportNotes = { ...NOTIZEN, zielbild: '', paket: 'basis', paketBestaetigt: true, zieleBestaetigt: true }
    expect(liste({ ...FAELLE.ilkay, notes })).toHaveLength(2)
    expect(liste({ ...FAELLE.ilkay, notes: { ...notes, paketBestaetigt: false } })).toHaveLength(4)
  })

  it('Feld mit kommendem Schulthema: „… sicher anwenden, bevor das Thema „…“ beginnt“', () => {
    const notes: ReportNotes = { ...NOTIZEN, zielbild: '', paket: null, zieleBestaetigt: true }
    const z = liste({ ...FAELLE.abgestuftPlanrang, notes })!
    expect(z).toContain('Flächen und Figuren sicher anwenden, bevor das Thema „Kreise, Prismen und Zylinder“ beginnt')
  })

  it('bestätigt, aber nichts zu tun (alles sicher) und ohne Zielbild: der Abschnitt entfällt', () => {
    expect(liste({ ...FAELLE.allesSicher, notes: bestaetigt('') })).toBeUndefined()
  })

  it('Ziele aus dem Erstgespräch erscheinen auf Seite 5 nicht mehr', () => {
    const data = { ...FAELLE.ilkay.data, erstgespraech: eg({ ziele: 'Versetzung sichern.' }) }
    expect(seite5({ ...FAELLE.ilkay, data, notes: bestaetigt('') }).el).not.toHaveTextContent('Versetzung sichern.')
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

  it('Fragen oder Entscheidung: ohne Telefon „schreiben Sie mir gern“, Vertragssatz', () => {
    const k = within(seite5(FAELLE.ilkay).getByTestId('eb-kontakt'))
    expect(k.getByText('Bei Fragen erreichen Sie mich jederzeit – schreiben Sie mir gern.')).toBeInTheDocument()
    expect(k.queryByText(/rufen Sie gern an/)).toBeNull()
    expect(k.getByText(de.s5.fragen.vertrag)).toBeInTheDocument()
  })

  it('mit Telefon der Satz mit „rufen Sie gern an“', () => {
    KONTAKT.telefon = '0221 123456'
    const k = within(seite5(FAELLE.ilkay).getByTestId('eb-kontakt'))
    expect(k.getByText('Bei Fragen erreichen Sie mich jederzeit – rufen Sie gern an oder schreiben Sie mir.')).toBeInTheDocument()
  })

  it('Hinweis auf die Tablet-Fassung entfällt, solange TABLET_LINK null ist', () => {
    expect(TABLET_LINK).toBeNull()
    const s = seite5(FAELLE.ilkay)
    expect(s.queryByTestId('eb-tablet')).toBeNull()
    expect(s.el).not.toHaveTextContent(/Tablet/)
  })

  it('ohneName: Titel ohne Namen', () => {
    expect(seite5(FAELLE.ohneName).getByRole('heading', { level: 1 })).toHaveTextContent('Unsere Einschätzung für Ihr Kind.')
  })
})
