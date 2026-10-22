// Seite 1 des Eltern-Berichts R7 (Überblick) für die Fixture-Fälle.
import { render, within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import '@/i18n'

import { ElternberichtBogen } from '@/components/edvance/elternbericht/Bogen'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import type { ReportBaustein, ReportData, Rueckbezug } from '@/types'

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

  it('fasst die Zählung in einer Zeile zusammen, ohne Katalog-Nenner', () => {
    expect(s().el.querySelector('.eb-s1-zeile')?.textContent).toBe(
      '27 Bereiche geprüft  ·  11 sicher  ·  16 Übungsbedarf',
    )
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
  it('ilkay: nur „Konzentration“ (überfachlich) → kein Anliegen-Kasten, kein Grenzsatz, Weg steht (R7-11)', () => {
    const s = seite1(FAELLE.ilkay.data)
    expect(s.queryByTestId('eb-anliegen')).toBeNull()
    expect(s.el).not.toHaveTextContent(/Konzentration/)
    expect(s.getByTestId('eb-geprueft').parentElement).toHaveClass('eb-s1-kaesten-voll')
    expect(s.getByTestId('eb-geprueft')).toHaveTextContent(
      'Ausgehend vom Thema Terme und Gleichungen hat das System je nach Antwort die nächste Aufgabe gewählt. So wurden 27 Bereiche gezielt geprüft.',
    )
    expect(s.getByTestId('eb-geprueft')).toHaveTextContent(
      'Dieser Bericht sagt nur etwas über die geprüften Bereiche. Weitere Bereiche lernen wir in den ersten Sitzungen kennen.',
    )
    expect(s.queryByTestId('eb-thema-satz')).toBeNull()
    expect(s.getByTestId('eb-weg')).toHaveTextContent('Sie sind hier')
  })

  it('anliegenGemischt: nur „Noten“, mit Genitiv, Antwort Schwerpunkt 1 und nächstem Thema', () => {
    const s = seite1(FAELLE.anliegenGemischt.data)
    expect(s.getByTestId('eb-anliegen')).toHaveTextContent(
      'Sie machen sich Sorgen um Ilkays Noten. Dort setzen wir zuerst an: Geometrie. Als nächstes Thema steht Algebra & Funktionen an.',
    )
    expect(s.el).not.toHaveTextContent(/Konzentration/)
  })

  it('ohneName: fachliche Anliegen ohne Namen, im Plural nach der Zahl der Punkte', () => {
    const mit = (anlassNamen: string[]) =>
      seite1({ ...FAELLE.ohneName.data, erzaehlung: { ...FAELLE.ohneName.data.erzaehlung, anlassNamen } })
    expect(mit(['Rechenwege', 'Konzentration']).getByTestId('eb-anliegen')).toHaveTextContent(
      'Sie sind zu uns gekommen, weil Sie Rechenwege als Schwierigkeit sehen.',
    )
    expect(mit(['Textverständnis', 'Rechenwege']).getByTestId('eb-anliegen')).toHaveTextContent(
      'weil Sie Textverständnis und Rechenwege als Schwierigkeiten sehen.',
    )
  })

  it('abgestuft: Frage und Antwort zum Thema, kein Schwerpunkt-Satz, kein nächstes Thema', () => {
    const s = seite1(FAELLE.abgestuft.data)
    expect(s.getByTestId('eb-anliegen')).toHaveTextContent(
      'Sie sind wegen Reelle Zahlen zu uns gekommen. Dort hakt es bei Wurzelgesetze für Produkt und Quotient, Rationale und irrationale Zahlen und Teilweise die Wurzel ziehen.',
    )
    expect(s.getByTestId('eb-anliegen')).not.toHaveTextContent('Dort setzen wir zuerst an')
    expect(seite1(FAELLE.abgestuftThemaSicher.data).getByTestId('eb-anliegen')).toHaveTextContent(
      'Sie sind wegen Reelle Zahlen zu uns gekommen. Was wir dazu geprüft haben, sitzt.',
    )
  })

  it('Rückbezüge nur zu fachlichen Anliegen und nur die, die antworten (R7-11, Entscheidung 14)', () => {
    const { data } = FAELLE.vieleRueckbezuege
    const rb = (thema: string, fall: string, richtung: Rueckbezug['richtung']): Rueckbezug => ({
      thema,
      fall,
      richtung,
      belege: 2,
    })
    const s = seite1({
      ...data,
      erzaehlung: {
        ...data.erzaehlung,
        rueckbezuege: [
          rb('Konzentration', 'konzentration_nicht_messbar', 'nicht_messbar'),
          rb('Rechenwege', 'rechenwege_bestaetigend', 'bestaetigend'),
          rb('Textverständnis', 'textverstaendnis_offen', 'offen'),
          rb('Grundlagen fehlen', 'grundlagen_entlastend_schmal', 'entlastend'),
        ],
      },
    })
    const eintraege = within(s.getByTestId('eb-anliegen')).getAllByRole('listitem')
    expect(eintraege).toHaveLength(1)
    expect(eintraege[0]).toHaveTextContent(/Rechenweg/)
    expect(s.getByTestId('eb-weg')).toBeInTheDocument()
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
