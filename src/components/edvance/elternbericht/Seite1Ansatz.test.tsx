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
  it('abgestuft (Batu): Startstelle als Titel, „Im Thema …“ darüber, ein Satz; keine Liste, keine Geometrie', () => {
    const s = seite(FAELLE.abgestuft.data, 1)
    const ansatz = s.getByTestId('eb-ansatz')
    expect(ansatz.querySelector('.eb-s1-ansatz-thema')).toHaveTextContent(/^Im Thema Reelle Zahlen$/)
    expect(ansatz.querySelector('.eb-s1-ansatz-titel')).toHaveTextContent(/^Wurzelgesetze für Produkt und Quotient$/)
    expect(ansatz.querySelector('.eb-s1-ansatz-text')).toHaveTextContent(/^Darauf baut Teilweise die Wurzel ziehen auf\.$/)
    expect(ansatz).not.toHaveTextContent('Geometrie')
    expect(ansatz).not.toHaveTextContent('Rationale')
    // Die Listen beginnen mit Bereichen aus dem Thema.
    expect(within(s.getByTestId('eb-liste-uebung')).getAllByRole('listitem')[0]).toHaveTextContent(
      'Wurzelgesetze für Produkt und Quotient',
    )
    expect(within(s.getByTestId('eb-liste-sicher')).getAllByRole('listitem')[0]).toHaveTextContent('Bruch in Dezimalzahl')
    expect(s.getByTestId('eb-liste-sicher')).toHaveTextContent('Das klappt bereits')
  })

  it('abgestuftThemaSicher: ansatzThemaSicher, ohne Kreis und Titel', () => {
    const s = seite(FAELLE.abgestuftThemaSicher.data, 1)
    const ansatz = s.getByTestId('eb-ansatz')
    expect(ansatz).toHaveTextContent(
      'Was wir im Thema Reelle Zahlen geprüft haben, sitzt. Wir arbeiten am aktuellen Stoff weiter.',
    )
    expect(ansatz.querySelector('.eb-s1-ansatz-titel')).toBeNull()
  })

  it('nichts baut mit Übungsbedarf auf der Startstelle auf: „Hier setzen wir zuerst an.“', () => {
    const { data } = FAELLE.abgestuft
    const ohne = data.erzaehlung.kompetenzen.filter((k) => k.skillKey !== 'zahl_wurzel_teilweise')
    const s = seite({ ...data, erzaehlung: { ...data.erzaehlung, kompetenzen: ohne } }, 1)
    expect(s.getByTestId('eb-ansatz').querySelector('.eb-s1-ansatz-text')).toHaveTextContent(
      /^Hier setzen wir zuerst an\.$/,
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

  it('abgestuftThemaSicher: das Thema ist kein Schwerpunkt, kein Schild', () => {
    const s = seite(FAELLE.abgestuftThemaSicher.data, 4)
    const titel = [...s.el.querySelectorAll('.eb-s4-punkt-titel')].map((t) => t.textContent)
    expect(titel).toEqual(['Terme & Gleichungen', 'Geometrie', 'Daten & Zufall'])
    expect(s.queryByTestId('eb-s4-chip-thema')).toBeNull()
  })

  it('Thema und Breite ohne Übungsbedarf: Seite 4 wie bisher ohne Schwerpunkt', () => {
    const { data } = FAELLE.abgestuftThemaSicher
    const alles = data.erzaehlung.kompetenzen.map((k) => ({ ...k, zustand: 'traegt' }))
    const s = seite({ ...data, erzaehlung: { ...data.erzaehlung, kompetenzen: alles } }, 4)
    expect(s.el).toHaveTextContent('Kein Übungsbedarf in den untersuchten Bereichen.')
    expect(s.queryByTestId('eb-schwerpunkte')).toBeNull()
  })

  it('ilkay: ohne Schild', () => {
    expect(seite(FAELLE.ilkay.data, 4).queryByTestId('eb-s4-chip-thema')).toBeNull()
  })
})
