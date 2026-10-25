// Bogen und Seitenrahmen des Eltern-Berichts (Bericht v2): fünf Seiten, Chip
// nur im Testlauf, beschriftete Navigation, Fuß mit und ohne Namen, Hinweis
// statt Bogen, der eine Coach-Satz auf Seite 4.
import { render, screen, within } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { ElternberichtBogen } from '@/components/edvance/elternbericht/Bogen'
import de from '@/i18n/locales/de/elternbericht.json'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import type { ReportData } from '@/types'

function bogen(name: keyof typeof FAELLE | ReportData) {
  const fall = typeof name === 'string' ? FAELLE[name] : { ...FAELLE.ilkay, data: name }
  return render(<ElternberichtBogen data={fall.data} notes={fall.notes} tiers={fall.tiers} />)
}

const seiten = (c: HTMLElement): HTMLElement[] => [...c.querySelectorAll<HTMLElement>('.eb-seite')]

describe('ElternberichtBogen', () => {
  it('rendert fünf Seiten, jede mit Kopf, Inhalt und Fuß', () => {
    const { container } = bogen('ilkay')
    const alle = seiten(container)
    expect(alle.map((s) => s.dataset.seite)).toEqual(['1', '2', '3', '4', '5'])
    for (const s of alle) {
      expect(s.querySelector('.eb-kopflinie')).not.toBeNull()
      expect(s.querySelector('.eb-inhalt')).not.toBeNull()
      expect(s.querySelector('.eb-fusslinie')).not.toBeNull()
    }
  })

  it('definiert das Schraffur-Pattern für Seite 2 genau einmal', () => {
    const { container } = bogen('ilkay')
    const pattern = container.querySelectorAll('pattern#eb-schraffur')
    expect(pattern).toHaveLength(1)
    expect(pattern[0]).toHaveAttribute('patternUnits', 'userSpaceOnUse')
    expect(pattern[0]).toHaveAttribute('width', '7')
    expect(pattern[0]).toHaveAttribute('patternTransform', 'rotate(45)')
  })

  it('zeigt den Chip „Testdaten“ nur im Testlauf, dann auf jeder Seite', () => {
    const { container, unmount } = bogen('testlauf')
    for (const s of seiten(container)) {
      expect(within(s).getByTestId('eb-chip')).toHaveTextContent('Testdaten')
    }
    unmount()
    const ohne = bogen('ilkay')
    expect(ohne.container.querySelector('[data-testid="eb-chip"]')).toBeNull()
  })

  it('zeigt auf jeder Seite fünf beschriftete Stationen, genau die eigene ist aktiv', () => {
    const { container } = bogen('ilkay')
    const namen = ['Überblick', 'Lernstand', 'Einordnung', 'Lernplan', 'Nächste Schritte']
    expect(Object.values(de.s1.weg.station)).toEqual(namen)
    seiten(container).forEach((s, i) => {
      const nav = within(s).getByTestId('eb-nav')
      expect(nav).toHaveAttribute('aria-label', 'Ihr Weg durch diesen Bericht')
      const stationen = [...nav.querySelectorAll('.eb-nav-station')]
      expect(stationen.map((x) => x.querySelector('.eb-nav-name')?.textContent)).toEqual(namen)
      expect(stationen.map((x) => x.querySelector('.eb-nav-nummer')?.textContent)).toEqual(['1', '2', '3', '4', '5'])
      const aktiv = stationen.flatMap((x, j) => (x.hasAttribute('data-aktiv') ? [j] : []))
      expect(aktiv).toEqual([i])
      expect(stationen[i]).toHaveAttribute('aria-current', 'page')
      expect(stationen.filter((x) => x.hasAttribute('aria-current'))).toHaveLength(1)
    })
  })

  it('setzt den Testlauf-Chip unter die Wortmarke, nicht mehr in die Navigation', () => {
    const { container } = bogen('testlauf')
    const kopf = within(seiten(container)[0]).getByTestId('eb-kopf')
    const wortmarke = kopf.querySelector('.eb-wortmarke')!
    const chip = kopf.querySelector('rect.eb-chip')!
    expect(chip.getAttribute('x')).toBe(wortmarke.getAttribute('x'))
    expect(Number(chip.getAttribute('y'))).toBeGreaterThan(Number(wortmarke.getAttribute('y')))
    expect(within(kopf).getByTestId('eb-nav')).not.toContainElement(within(kopf).getByTestId('eb-chip'))
  })

  it('nennt im Fuß den Namen und die Seitenzahl', () => {
    const { container } = bogen('ilkay')
    seiten(container).forEach((s, i) => {
      const fuss = within(s).getByTestId('eb-fuss')
      expect(fuss).toHaveTextContent('edvance · Köln · Lernstandsanalyse Ilkay')
      expect(fuss).toHaveTextContent(`${i + 1} / 5`)
    })
  })

  it('lässt den Namen im Fuß ohne Rufnamen weg', () => {
    const { container } = bogen('ohneName')
    const fuss = within(seiten(container)[0]).getByTestId('eb-fuss')
    expect(fuss.querySelector('.eb-fuss-text')?.textContent).toBe(
      'edvance  ·  Köln  ·  Lernstandsanalyse',
    )
  })

  it('nimmt Rufnamen bis 24 Zeichen, darüber überall die Fassungen ohne Namen', () => {
    const texte = (firstName: string) => {
      // Die Note im Erstgespräch nennt den Namen im „Anliegen“-Kasten (Bericht v2).
      const { data } = FAELLE.anliegenGemischt
      const { container, unmount } = bogen({
        ...data,
        firstName,
        erstgespraech: { note: '4', trend: null, seit: null, ziele: null, klassenarbeit: null, klassenarbeitDatum: null },
      })
      const s = seiten(container)
      const ergebnis = {
        fuss: s[0].querySelector('.eb-fuss-text')?.textContent,
        titel: s.map((x) => x.querySelector('.eb-titel')?.textContent),
        anliegen: s[0].querySelector('.eb-s1-anliegen-satz')?.textContent,
        kontaktTitel: s[4].querySelector('.eb-titel')?.textContent,
        alles: container.textContent ?? '',
        ohneFuss: (() => {
          const kopie = container.cloneNode(true) as HTMLElement
          kopie.querySelectorAll('[data-testid="eb-fuss"]').forEach((x) => x.remove())
          return kopie.textContent ?? ''
        })(),
      }
      unmount()
      return ergebnis
    }

    const mit = texte(' Anna-Katharina Henriette ') // 24 Zeichen nach trim
    expect(mit.fuss).toBe('edvance  ·  Köln  ·  Lernstandsanalyse Anna-Katharina Henriette')
    // Bericht v3: Titel von Seite 1 und Fußzeile tragen den vollen Namen, der Text den Vornamen.
    expect(mit.titel[0]).toBe('Was wir bei Anna-Katharina Henriette gesehen haben')
    expect(mit.titel[1]).toBe('Der Lernstand von Anna-Katharina in den geprüften Bereichen.')
    expect(mit.kontaktTitel).toBe('Unsere Einschätzung für Anna-Katharina.')
    expect(mit.anliegen).toContain('Letzte Zeugnisnote in Mathematik: 4.')
    expect(mit.ohneFuss.match(/Henriette/g)).toHaveLength(1) // nur der Titel von Seite 1

    const ohne = texte('Anna-Katharina Friederike') // 25 Zeichen
    const ohneName = texte('')
    expect(ohne.fuss).toBe('edvance  ·  Köln  ·  Lernstandsanalyse')
    expect(ohne.titel).toEqual(ohneName.titel)
    expect(ohne.anliegen).toBe(ohneName.anliegen)
    expect(ohne.anliegen).toContain('Letzte Zeugnisnote in Mathematik: 4.')
    expect(ohne.alles).not.toContain('Friederike')
  })

  it('zeigt ohne Katalog keinen Bogen, sondern den Hinweis', () => {
    const { container } = bogen('ohneKatalog')
    expect(seiten(container)).toHaveLength(0)
    expect(screen.getByTestId('eb-leer')).toHaveTextContent(
      'Der Aufgabenkatalog konnte nicht geladen werden.',
    )
  })

  it('zeigt ohne direkt geprüfte Bereiche keinen Bogen, sondern den Hinweis', () => {
    const { data } = FAELLE.ilkay
    const { container } = bogen({ ...data, erzaehlung: { ...data.erzaehlung, kompetenzen: [] } })
    expect(seiten(container)).toHaveLength(0)
    expect(screen.getByTestId('eb-leer')).toHaveTextContent(
      'Für diese Analyse gibt es keine direkt geprüften Bereiche.',
    )
  })
})

describe('ElternberichtBogen — Inhalt des Berichts v2', { timeout: 30_000 }, () => {
  const COACH = de.s4.coach
  const alle = Object.keys(FAELLE).filter((n) => n !== 'ohneKatalog')

  it('der Coach-Satz steht im ganzen Bogen genau einmal, und zwar auf Seite 4', () => {
    for (const n of alle) {
      const { container, unmount } = bogen(n)
      const s = seiten(container)
      const treffer = s.map((x) => (x.textContent ?? '').split(COACH).length - 1)
      expect(treffer, n).toEqual([0, 0, 0, 1, 0])
      unmount()
    }
  })

  it('kein „abgeleitet“ und kein „ergeben sich“ auf irgendeiner Seite, in keinem Fall', () => {
    for (const n of alle) {
      const { container, unmount } = bogen(n)
      expect(container.textContent, n).not.toMatch(/abgeleitet|ergeben sich|ergibt sich/i)
      unmount()
    }
  })

  it('keine Preise, Konditionen oder Lernpfad-Zeilen im Bogen', () => {
    const { container } = bogen('ilkay')
    expect(container.textContent).not.toMatch(/Konditionen|Preis|Laufzeit|€/)
  })
})

describe('ElternberichtBogen — Name nach der Messung', () => {
  afterEach(() => vi.restoreAllMocks())

  const seiteVon = (el: Element): number => Number(el.closest<HTMLElement>('.eb-seite')?.dataset.seite)

  /** Gemessene Lagen gemockt: Zeilen des Titels auf Seite 2 und überlaufende Seiten. */
  function gemessen(titelZeilen: number, ueberlauf: number[]) {
    vi.spyOn(window, 'getComputedStyle').mockImplementation(
      () => ({ lineHeight: '40px' }) as CSSStyleDeclaration,
    )
    // Layoutwert, nicht getBoundingClientRect: skalenfest seit R7-7.
    vi.spyOn(HTMLElement.prototype, 'offsetHeight', 'get').mockImplementation(function (this: HTMLElement) {
      return this.classList.contains('eb-titel') && seiteVon(this) === 2 ? 40 * titelZeilen : 0
    })
    vi.spyOn(HTMLElement.prototype, 'scrollHeight', 'get').mockImplementation(function (this: HTMLElement) {
      return this.classList.contains('eb-inhalt') && ueberlauf.includes(seiteVon(this)) ? 977 : 960
    })
    vi.spyOn(HTMLElement.prototype, 'clientHeight', 'get').mockReturnValue(960)

    const { container } = bogen('langerName')
    const s = seiten(container)
    return {
      ohneName: container.querySelector('.eb-bogen')!.hasAttribute('data-ohne-name'),
      fuesse: s.map((x) => x.querySelector('.eb-fuss-text')?.textContent),
      titel: [0, 1, 4].map((i) => s[i].querySelector('.eb-titel')?.textContent),
      stufe: container.querySelector('.eb-s4')!.getAttribute('data-stufe'),
    }
  }

  const MIT = 'edvance  ·  Köln  ·  Lernstandsanalyse Anna-Katharina Henriette'
  const OHNE = 'edvance  ·  Köln  ·  Lernstandsanalyse'

  it('passt alles, bleibt der Name', () => {
    const m = gemessen(2, [])
    expect(m.ohneName).toBe(false)
    expect(m.fuesse).toEqual(Array(5).fill(MIT))
  })

  it('Titel auf Seite 2 dreizeilig: der ganze Bogen ohne Namen', () => {
    const m = gemessen(3, [])
    expect(m.ohneName).toBe(true)
    expect(m.fuesse).toEqual(Array(5).fill(OHNE))
    expect(m.titel).toEqual([
      'Was wir bei Ihrem Kind gesehen haben',
      'Der Lernstand in den geprüften Bereichen.',
      'Unsere Einschätzung für Ihr Kind.',
    ])
  })

  it('läuft eine Seite mit Namen über (hier Seite 5), nie nur diese Seite ohne Namen', () => {
    const m = gemessen(2, [5])
    expect(m.ohneName).toBe(true)
    expect(m.fuesse).toEqual(Array(5).fill(OHNE))
  })

  it('Überlauf nur auf Seite 4 (ohne Namen) regeln die Stufen, der Name bleibt', () => {
    const m = gemessen(2, [4])
    expect(m.ohneName).toBe(false)
    expect(m.stufe).toBe('1')
  })
})
