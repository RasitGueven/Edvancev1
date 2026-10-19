// Bogen und Seitenrahmen des Eltern-Berichts R7: fünf Seiten, Chip nur im
// Testlauf, Mikro-Navigation, Fuß mit und ohne Namen, Hinweis statt Bogen.
import { render, screen, within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
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
