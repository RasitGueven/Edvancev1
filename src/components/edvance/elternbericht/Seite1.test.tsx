// Seite 1 des Eltern-Berichts R7 (Überblick) für die Fixture-Fälle.
import { render, within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import '@/i18n'

import { ElternberichtBogen } from '@/components/edvance/elternbericht/Bogen'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import type { ReportBaustein, ReportData } from '@/types'

function seite1(data: ReportData) {
  const { container } = render(
    <ElternberichtBogen data={data} notes={null} tiers={[]} />,
  )
  const el = container.querySelector<HTMLElement>('.eb-seite[data-seite="1"]')!
  return { ...within(el), el }
}

const KOPF: ReportBaustein[] = (['gemischt', 'sicher', 'uebung'] as const).map((fall) => ({
  schluessel: `kopf.${fall}.a`,
  slot: 'kopf',
  fall,
  variante: 'a',
  text: `{name} – Kopfsatz ${fall}.`,
}))

const mitKopf = (data: ReportData): ReportData => ({
  ...data,
  erzaehlung: { ...data.erzaehlung, bausteine: [...data.erzaehlung.bausteine, ...KOPF] },
})

describe('Seite 1 — Überschrift', () => {
  it('nimmt ohne abgenommenen Kopfsatz die Ersatzüberschrift', () => {
    expect(seite1(FAELLE.ilkay.data).getByRole('heading', { level: 1 })).toHaveTextContent(
      'Was wir bei Ilkay gesehen haben',
    )
    expect(seite1(FAELLE.ohneName.data).getByRole('heading', { level: 1 })).toHaveTextContent(
      'Was wir bei Ihrem Kind gesehen haben',
    )
  })

  it('nimmt den Kopfsatz zum Fall, mit Namen bzw. „Ihr Kind“', () => {
    expect(seite1(mitKopf(FAELLE.ilkay.data)).getByRole('heading', { level: 1 })).toHaveTextContent(
      'Ilkay – Kopfsatz gemischt.',
    )
    expect(seite1(mitKopf(FAELLE.allesSicher.data)).getByRole('heading', { level: 1 })).toHaveTextContent(
      'Ilkay – Kopfsatz sicher.',
    )
    expect(seite1(mitKopf(FAELLE.nichtsSicher.data)).getByRole('heading', { level: 1 })).toHaveTextContent(
      'Ilkay – Kopfsatz uebung.',
    )
    expect(seite1(mitKopf(FAELLE.ohneName.data)).getByRole('heading', { level: 1 })).toHaveTextContent(
      'Ihr Kind – Kopfsatz gemischt.',
    )
  })
})

describe('Seite 1 — Kopfdaten und Zählung (ilkay)', () => {
  const s = (): ReturnType<typeof seite1> => seite1(FAELLE.ilkay.data)

  it('nennt Klasse mit Schulform, Fach, Umfang und Datum', () => {
    const meta = s().el.querySelector('dl')!
    expect(meta).toHaveTextContent('Klasse10, Gesamtschule')
    expect(meta).toHaveTextContent('FachMathematik')
    expect(meta).toHaveTextContent('Umfang43 Aufgaben')
    expect(meta).toHaveTextContent('Datum20. September 2026')
  })

  it('nennt ohne Schulform nur die Klasse', () => {
    const ohne = seite1({ ...FAELLE.ilkay.data, schulform: null })
    expect(ohne.getByText('10')).toBeInTheDocument()
  })

  it('fasst die Zählung in einer Zeile zusammen', () => {
    expect(
      s().getByText(/von 130 Bereichen untersucht/).textContent,
    ).toBe('27 von 130 Bereichen untersucht  ·  11 sicher  ·  16 Übungsbedarf  ·  103 nicht untersucht')
  })
})

describe('Seite 1 — Auf einen Blick', () => {
  it('ilkay: je vier Einträge, darunter „+n weitere“, erster Ansatz gemischt', () => {
    const s = seite1(FAELLE.ilkay.data)
    const sicher = within(s.getByTestId('eb-liste-sicher'))
    const uebung = within(s.getByTestId('eb-liste-uebung'))
    expect(sicher.getAllByRole('listitem')).toHaveLength(4)
    expect(sicher.getByText('+7 weitere')).toBeInTheDocument()
    expect(uebung.getAllByRole('listitem')).toHaveLength(4)
    expect(uebung.getByText('+12 weitere')).toBeInTheDocument()

    const ansatz = s.getByTestId('eb-ansatz')
    expect(ansatz).toHaveTextContent('1')
    expect(ansatz).toHaveTextContent('Geometrie')
    expect(ansatz).toHaveTextContent('Dort liegen Sicheres und noch Unsicheres direkt nebeneinander.')
  })

  it('allesSicher: keine Übungsliste, kein Schwerpunkt', () => {
    const s = seite1(FAELLE.allesSicher.data)
    expect(within(s.getByTestId('eb-liste-uebung')).getByText('Kein Bereich mit Übungsbedarf.')).toBeInTheDocument()
    expect(within(s.getByTestId('eb-liste-uebung')).queryByRole('listitem')).toBeNull()
    const ansatz = s.getByTestId('eb-ansatz')
    expect(ansatz.querySelector('.eb-s1-ansatz-kreis')).toBeNull()
    expect(ansatz).toHaveTextContent('In den untersuchten Bereichen gibt es keinen Übungsbedarf.')
  })

  it('nichtsSicher: keine Sicher-Liste, Ansatz ohne Sicheres', () => {
    const s = seite1(FAELLE.nichtsSicher.data)
    expect(within(s.getByTestId('eb-liste-sicher')).getByText('Noch kein Bereich sicher.')).toBeInTheDocument()
    expect(s.getByTestId('eb-ansatz')).toHaveTextContent(
      'In diesem Themenfeld war noch nichts sicher. Hier setzen wir zuerst an.',
    )
  })

  it('ohne „+n weitere“ bei höchstens vier Einträgen', () => {
    const s = seite1(FAELLE.klasse7.data)
    for (const art of ['sicher', 'uebung']) {
      const karte = within(s.getByTestId(`eb-liste-${art}`))
      expect(karte.getAllByRole('listitem').length).toBeLessThanOrEqual(4)
      expect(karte.queryByText(/weitere/)).toBeNull()
    }
  })
})

describe('Seite 1 — Anliegen, Prüfweg und Weg', () => {
  it('ilkay: Anliegen mit Genitiv, Thema, ein Rückbezug, Weg steht', () => {
    const s = seite1(FAELLE.ilkay.data)
    const anliegen = s.getByTestId('eb-anliegen')
    expect(anliegen).toHaveTextContent('Sie machen sich Sorgen um Ilkays Konzentration.')
    expect(anliegen).toHaveTextContent('Als nächstes Thema steht Algebra & Funktionen an.')
    expect(within(anliegen).getAllByRole('listitem')).toHaveLength(1)
    expect(s.getByTestId('eb-geprueft')).toHaveTextContent(
      'So wurden 27 von 130 Bereichen des Katalogs bis Klasse 10 untersucht.',
    )
    expect(s.getByTestId('eb-geprueft')).toHaveTextContent(
      'Über die 103 nicht untersuchten Bereiche enthält dieser Bericht keine Aussage.',
    )
    expect(s.getByTestId('eb-weg')).toHaveTextContent('Sie sind hier')
  })

  it('ohneName: Anliegen ohne Namen, im Plural nach der Zahl der Punkte', () => {
    const s = seite1(FAELLE.ohneName.data)
    expect(s.getByTestId('eb-anliegen')).toHaveTextContent(
      'Sie sind zu uns gekommen, weil Sie Konzentration als Schwierigkeit sehen.',
    )
    const zwei = seite1({
      ...FAELLE.ohneName.data,
      erzaehlung: { ...FAELLE.ohneName.data.erzaehlung, anlassNamen: ['Konzentration', 'Rechenwege'] },
    })
    expect(zwei.getByTestId('eb-anliegen')).toHaveTextContent(
      'weil Sie Konzentration und Rechenwege als Schwierigkeiten sehen.',
    )
  })

  it('vieleRueckbezuege: vier Rückbezüge, der Weg entfällt', () => {
    const s = seite1(FAELLE.vieleRueckbezuege.data)
    expect(within(s.getByTestId('eb-anliegen')).getAllByRole('listitem')).toHaveLength(4)
    expect(s.queryByTestId('eb-weg')).toBeNull()
  })

  it('ohne Anlass, Thema und Rückbezug entfällt der linke Kasten', () => {
    const { data } = FAELLE.ilkay
    const s = seite1({
      ...data,
      naechstesThema: null,
      erzaehlung: { ...data.erzaehlung, anlassNamen: [], rueckbezuege: [] },
    })
    expect(s.queryByTestId('eb-anliegen')).toBeNull()
    expect(s.getByTestId('eb-geprueft').parentElement).toHaveClass('eb-s1-kaesten-voll')
  })
})
