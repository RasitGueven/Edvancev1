// R7-11: „Unser erster Ansatz“ am Thema, „Ihr Anliegen“ mit Antwort, das Schild
// am Thema-Schwerpunkt auf Seite 4 und kein Grenzsatz auf Seite 1 — über den
// ganzen Bogen, damit die Rechnung dieselbe ist wie im Druck.
import { render, within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import '@/i18n'

import { ElternberichtBogen } from '@/components/edvance/elternbericht/Bogen'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import type { ReportData } from '@/types'

function seite(data: ReportData, n: 1 | 4) {
  const { container } = render(<ElternberichtBogen data={data} notes={null} tiers={[]} />)
  const el = container.querySelector<HTMLElement>(`.eb-seite[data-seite="${n}"]`)!
  return { ...within(el), el }
}

/** Seite 1 ohne den Kasten „So haben wir geprüft“ (Methodenhinweis, Ausnahme von INV-4.13). */
const ohneMethode = (el: HTMLElement): string => {
  const kopie = el.cloneNode(true) as HTMLElement
  kopie.querySelector('[data-testid="eb-geprueft"]')?.remove()
  return kopie.textContent ?? ''
}

const GRENZSATZ =
  /sagt nichts|sagt eine Analyse|sagt diese Analyse|erst nach|können wir noch nicht|nach mehreren Sitzungen|nichts beitragen|Konzentration/i

describe('Seite 1 — erster Ansatz mit Thema (R7-11)', () => {
  it('abgestuft (Batu): Thema, Übungsbedarf, Start Wurzelgesetze; keine Geometrie im Ansatz', () => {
    const s = seite(FAELLE.abgestuft.data, 1)
    const ansatz = s.getByTestId('eb-ansatz')
    expect(ansatz.querySelector('.eb-s1-ansatz-titel')).toHaveTextContent(/^Reelle Zahlen$/)
    expect(ansatz.querySelector('.eb-s1-ansatz-text')).toHaveTextContent(
      'Sicher sind schon Bruch in Dezimalzahl und Wurzeln abschätzen und Näherungswerte. ' +
        'Noch Übung braucht Ilkay bei Wurzelgesetze für Produkt und Quotient, Rationale und irrationale Zahlen und Teilweise die Wurzel ziehen. ' +
        'Wir beginnen bei Wurzelgesetze für Produkt und Quotient.',
    )
    expect(ansatz).not.toHaveTextContent('Geometrie')
    // Die Listen beginnen mit Bereichen aus dem Thema.
    expect(within(s.getByTestId('eb-liste-uebung')).getAllByRole('listitem')[0]).toHaveTextContent(
      'Wurzelgesetze für Produkt und Quotient',
    )
    expect(within(s.getByTestId('eb-liste-sicher')).getAllByRole('listitem')[0]).toHaveTextContent('Bruch in Dezimalzahl')
  })

  it('abgestuftThemaSicher: ansatzThemaSicher', () => {
    const s = seite(FAELLE.abgestuftThemaSicher.data, 1)
    expect(s.getByTestId('eb-ansatz')).toHaveTextContent(
      'Was wir im Thema Reelle Zahlen geprüft haben, sitzt. Wir arbeiten am aktuellen Stoff weiter.',
    )
  })

  it('ohne Namen und mit nur einem Bereich mit Übungsbedarf: „Dort setzen wir an.“', () => {
    const { data } = FAELLE.abgestuft
    const eins = data.erzaehlung.kompetenzen.map((k) =>
      k.skillKey === 'zahl_wurzel_irrational' || k.skillKey === 'zahl_wurzel_teilweise' ? { ...k, zustand: 'traegt' } : k,
    )
    const s = seite({ ...data, firstName: null, erzaehlung: { ...data.erzaehlung, kompetenzen: eins } }, 1)
    expect(s.getByTestId('eb-ansatz')).toHaveTextContent(
      'Noch Übung braucht es bei Wurzelgesetze für Produkt und Quotient. Dort setzen wir an.',
    )
  })

  it('ilkay: Ansatz wie bisher mit den Bausteinen', () => {
    const s = seite(FAELLE.ilkay.data, 1)
    expect(s.getByTestId('eb-ansatz')).toHaveTextContent(
      'GeometrieDort liegen Sicheres und noch Unsicheres direkt nebeneinander. Wir beginnen bei dem, was schon klappt.',
    )
  })
})

describe('Seite 1 — Anliegen (R7-11)', () => {
  it('anliegenNurUeberfach: kein Kasten, „So haben wir geprüft“ in voller Breite', () => {
    const s = seite(FAELLE.anliegenNurUeberfach.data, 1)
    expect(s.queryByTestId('eb-anliegen')).toBeNull()
    expect(s.getByTestId('eb-geprueft').parentElement).toHaveClass('eb-s1-kaesten-voll')
  })

  it.each(Object.keys(FAELLE).filter((n) => n !== 'ohneKatalog'))('%s: kein Grenzsatz außerhalb des Methodenhinweises', (n) => {
    expect(ohneMethode(seite(FAELLE[n].data, 1).el)).not.toMatch(GRENZSATZ)
  })
})

describe('Seite 4 — Thema-Schwerpunkt (R7-11)', () => {
  it('abgestuft: Reelle Zahlen an Platz 1 mit Schild, Geometrie nicht vorn', () => {
    const s = seite(FAELLE.abgestuft.data, 4)
    const titel = [...s.el.querySelectorAll('.eb-s4-punkt-titel')].map((t) => t.textContent)
    expect(titel[0]).toBe('Reelle ZahlenAktuelles Thema')
    expect(titel[1]).toBe('Terme & Gleichungen')
    expect(s.getAllByTestId('eb-s4-chip-thema')).toHaveLength(1)
  })

  it('abgestuftThemaSicher: nur „Sicher: …“ beim Thema', () => {
    const s = seite(FAELLE.abgestuftThemaSicher.data, 4)
    expect(s.el.querySelector('.eb-s4-punkt-text')!.textContent).toMatch(/^Sicher: [^.]+\. ?$/)
  })

  it('ilkay: ohne Schild', () => {
    expect(seite(FAELLE.ilkay.data, 4).queryByTestId('eb-s4-chip-thema')).toBeNull()
  })
})
