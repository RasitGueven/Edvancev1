// Bericht v4, V4-2: Rahmen (Kopf mit Stationsnamen, Leiste), Fahrplan-Fälle, Preise.
import { within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import '@/i18n'

import de from '@/i18n/locales/de/elternbericht.json'
import { TIERS } from '@/lib/report/elternbericht/fixtures'
import { bogenV4, MIT_FAHRPLAN } from '@/test/elternberichtV4'
import type { TierPlan } from '@/types'

import { monatspreis } from './seite5Rechnung'

const NAMEN = Object.values(de.s1.weg.station)

describe('Kopf und Leiste', () => {
  for (const fall of [...MIT_FAHRPLAN, 'ohnePlan']) {
    it(`${fall}: der Kopf nennt auf allen fünf Seiten die fünf Stationen, die Leiste steht auf Seite 2–5`, () => {
      const b = bogenV4(fall)
      for (let n = 1; n <= 5; n++) {
        const nav = b.seite(n).querySelector('[data-testid="eb-nav"]')!
        expect([...nav.querySelectorAll('.eb-nav-name')].map((x) => x.textContent), `${fall} Seite ${n}`).toEqual(NAMEN)
        expect(nav.querySelectorAll('.eb-nav-aktiv')).toHaveLength(1)
        const leiste = b.seite(n).querySelector('[data-testid="eb-leiste"]')
        expect(leiste !== null, `${fall} Seite ${n}`).toBe(n > 1 && b.bericht.fahrplan !== null)
      }
      // Der Chip „Testdaten“ bleibt, wo es ihn in v3 gab.
      expect(b.seite(1).querySelector('[data-testid="eb-chip"]') !== null).toBe(b.data.testlauf)
    })
  }

  it('ohnePlan hat keinen Fahrplan und keine Leiste', () => {
    const b = bogenV4('ohnePlan')
    expect(b.bericht.fahrplan).toBeNull()
    expect(b.container.querySelector('[data-testid="eb-leiste"]')).toBeNull()
    expect(b.container.querySelector('.eb-seite-leiste')).toBeNull()
  })

  it('batuV4: je Station ein Chip, volle Bezeichnung als Vorlesetext, Titel mit Ellipse', () => {
    const b = bogenV4('batuV4')
    const stationen = b.bericht.fahrplan!.stationen
    const chips = within(b.seite(2)).getAllByTestId('eb-leiste-chip')
    expect(chips).toHaveLength(stationen.length)
    chips.forEach((chip, i) => {
      expect(chip.querySelector('.sr-only')!.textContent).toContain(stationen[i].titel)
      expect(chip.querySelector('.eb-leiste-titel')).toHaveAttribute('aria-hidden', 'true')
    })
    // Erste Station: geschrieben, Haken statt Nummer.
    expect(chips[0].querySelector('.eb-leiste-punkt svg')).not.toBeNull()
    expect(chips[0]).toHaveClass('eb-ton-geschrieben')
    expect(chips[1]).toHaveClass('eb-ton-fehlt')
  })

  it('Hervorhebung: Seite 2 und 5 alle Chips, Seite 3 und 4 nur die kommenden', () => {
    const b = bogenV4('batuV4')
    const an = (n: number): boolean[] =>
      within(b.seite(n)).getAllByTestId('eb-leiste-chip').map((c) => c.classList.contains('eb-leiste-an'))
    expect(an(2).every(Boolean)).toBe(true)
    expect(an(5).every(Boolean)).toBe(true)
    for (const n of [3, 4]) {
      const a = an(n)
      expect(a[0]).toBe(false)
      expect(a.slice(1).every(Boolean)).toBe(true)
    }
  })

  it('der Inhalt rückt auf den Seiten mit Leiste nach unten (Klasse eb-seite-leiste)', () => {
    const b = bogenV4('batuV4')
    expect(b.seite(1)).not.toHaveClass('eb-seite-leiste')
    for (const n of [2, 3, 4, 5]) expect(b.seite(n)).toHaveClass('eb-seite-leiste')
  })
})

describe('Fahrplan auf Seite 1: Trenner, Note, Quelle', () => {
  it('fahrplanAuffuellen: Trenner „Klasse 8“ vor der ersten Station des nächsten Schuljahrs', () => {
    const b = bogenV4('fahrplanAuffuellen')
    const trenner = within(b.seite(1)).getAllByTestId('eb-fp-trenner')
    expect(trenner).toHaveLength(1)
    expect(trenner[0]).toHaveAttribute('data-art', 'klasse')
    expect(trenner[0]).toHaveTextContent('Klasse 8')
    expect(b.bericht.fahrplan!.klassenTrenner).toBe(8)
  })

  it('fahrplanHalbjahr: Trenner „Halbjahreszeugnis“ und das Halbjahr an den Stationen', () => {
    const b = bogenV4('fahrplanHalbjahr')
    const s1 = within(b.seite(1))
    expect(s1.getAllByTestId('eb-fp-trenner').some((t) => t.getAttribute('data-art') === 'halbjahr')).toBe(true)
    expect(s1.getByTestId('eb-fahrplan')).toHaveTextContent('Halbjahreszeugnis')
    expect(s1.getByTestId('eb-fahrplan')).toHaveTextContent(/[12]\. Halbjahr/)
  })

  it('batuV4: kein Trenner ohne Halbjahre und ohne Auffüllen', () => {
    expect(within(bogenV4('batuV4').seite(1)).queryAllByTestId('eb-fp-trenner')).toHaveLength(0)
  })

  it('batuMitNote zeigt „geschrieben · Note 4“, batuV4 keine Note', () => {
    expect(within(bogenV4('batuMitNote').seite(1)).getByTestId('eb-fahrplan')).toHaveTextContent('geschrieben · Note 4')
    expect(within(bogenV4('batuV4').seite(1)).getByTestId('eb-fahrplan')).not.toHaveTextContent(/Note \d/)
    expect(within(bogenV4('batuMitNote').seite(2)).getAllByTestId('eb-leiste-chip')[0].textContent).toContain('Note 4')
  })

  it('fahrplanLang: „+n weitere Themen bis zum Schuljahresende“', () => {
    const b = bogenV4('fahrplanLang')
    const n = b.bericht.fahrplan!.weitere
    expect(n).toBeGreaterThan(0)
    expect(within(b.seite(1)).getByTestId('eb-fp-weitere')).toHaveTextContent(`+${n} weitere`)
    expect(within(b.seite(1)).getAllByTestId('eb-fp-station')).toHaveLength(5)
  })

  it('batuV4: Schulplan als Quelle, fahrplanKlp: Kernlehrplan', () => {
    expect(within(bogenV4('batuV4').seite(1)).getByTestId('eb-fp-quelle').textContent).toContain(
      'Die Reihenfolge stammt aus dem Schulplan des Friedrich-Wilhelm-Gymnasiums. Wann genau eine Arbeit geschrieben wird, legt die Lehrkraft fest.',
    )
    expect(within(bogenV4('fahrplanKlp').seite(1)).getByTestId('eb-fp-quelle').textContent).toContain(
      'Die Reihenfolge folgt dem Kernlehrplan NRW.',
    )
  })
})

describe('Preise auf Seite 5: nur mit ?preise=an (Schalter in der Ansicht)', () => {
  const tiers: TierPlan[] = TIERS.map((p, i) => ({
    ...p,
    price_cents: [19990, 26990, 34990][i],
    laufzeiten: [
      { laufzeit_monate: 6, preis_cents: [21990, 29990, 38990][i], einheiten: 19 },
      { laufzeit_monate: 12, preis_cents: [19990, 26990, 34990][i], einheiten: 38 },
    ],
  }))

  it('ohne den Schalter steht nirgends ein Preis', () => {
    const b = bogenV4('batuV4', { tiers })
    expect(b.seite(5).textContent).not.toMatch(/€|im Monat/)
    expect(within(b.seite(5)).queryAllByTestId('eb-preis')).toHaveLength(0)
  })

  it('mit dem Schalter: Monatspreis je Paket, de-DE, EUR', () => {
    const b = bogenV4('batuV4', { tiers, preise: true })
    const preise = within(b.seite(5))
      .getAllByTestId('eb-preis')
      .map((p) => p.textContent?.replace(/\s/g, ' '))
    expect(preise).toEqual(['199,90 € im Monat', '269,90 € im Monat', '349,90 € im Monat'])
  })

  it('der Monatspreis ist der niedrigste aus den Laufzeiten, sonst der Referenzpreis', () => {
    expect(monatspreis(tiers[1])).toBe(26990)
    expect(monatspreis({ price_cents: 12345 })).toBe(12345)
    expect(monatspreis({ price_cents: 12345, laufzeiten: [] })).toBe(12345)
  })

  it('der Preis gilt für ohnePlan genauso (v3-Seite 5)', () => {
    const b = bogenV4('ohnePlan', { tiers, preise: true })
    expect(within(b.seite(5)).getAllByTestId('eb-preis')).toHaveLength(3)
  })
})

describe('Rufname bleibt', () => {
  for (const fall of ['batuV4', 'batuMitNote', 'fahrplanLang']) {
    it(`${fall}: der Bogen behält den Rufnamen (Fuß und Texte)`, () => {
      const b = bogenV4(fall)
      expect(b.container.querySelector('.eb-bogen')).not.toHaveAttribute('data-ohne-name')
      expect(b.seite(1).querySelector('[data-testid="eb-fahrplan"] h2')!.textContent).toContain('Ilkays')
    })
  }
})
