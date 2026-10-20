// Bogen und Seitenrahmen des Eltern-Berichts R7: fünf Seiten, Chip nur im
// Testlauf, Mikro-Navigation, Fuß mit und ohne Namen, Hinweis statt Bogen.
import { render, screen, within } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { ElternberichtBogen } from '@/components/edvance/elternbericht/Bogen'
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

  it('markiert in der Mikro-Navigation die eigene Seite, und nur sie', () => {
    const { container } = bogen('ilkay')
    seiten(container).forEach((s, i) => {
      const punkte = [...s.querySelectorAll('.eb-nav-punkt')]
      expect(punkte).toHaveLength(5)
      const aktiv = punkte.flatMap((p, j) => (p.hasAttribute('data-aktiv') ? [j] : []))
      expect(aktiv).toEqual([i])
      expect(punkte[i]).toHaveClass('eb-nav-punkt-aktiv')
    })
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
      const { container, unmount } = bogen({ ...FAELLE.ilkay.data, firstName })
      const s = seiten(container)
      const ergebnis = {
        fuss: s[0].querySelector('.eb-fuss-text')?.textContent,
        titel: s.map((x) => x.querySelector('.eb-titel')?.textContent),
        anliegen: s[0].querySelector('.eb-s1-anliegen-satz')?.textContent,
        alles: container.textContent ?? '',
      }
      unmount()
      return ergebnis
    }

    const mit = texte(' Anna-Katharina Henriette ') // 24 Zeichen nach trim
    expect(mit.fuss).toBe('edvance  ·  Köln  ·  Lernstandsanalyse Anna-Katharina Henriette')
    expect(mit.titel[0]).toBe('Was wir bei Anna-Katharina Henriette gesehen haben')
    expect(mit.titel[1]).toContain('Anna-Katharina Henriettes')
    expect(mit.anliegen).toContain('Anna-Katharina Henriettes')

    const ohne = texte('Anna-Katharina Friederike') // 25 Zeichen
    const ohneName = texte('')
    expect(ohne.fuss).toBe('edvance  ·  Köln  ·  Lernstandsanalyse')
    expect(ohne.titel).toEqual(ohneName.titel)
    expect(ohne.anliegen).toBe(ohneName.anliegen)
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
      'Der Lernstand in den untersuchten Bereichen.',
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
