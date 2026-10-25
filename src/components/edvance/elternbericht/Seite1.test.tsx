// Seite 1 des Eltern-Berichts (Bericht v2): Kopf, „So gehen wir vor“, „Auf einen Blick".
import { within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import '@/i18n'
import { renderOhneFahrplan } from '@/test/elternberichtOhneFahrplan'

import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import de from '@/i18n/locales/de/elternbericht.json'
import type { ReportBaustein, ReportData, ReportFehlbild } from '@/types'

function seite1(data: ReportData) {
  const { container } = renderOhneFahrplan(data)
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

const fehlbild = (familie: string, aufgaben: number): ReportFehlbild => ({
  slug: `${familie}-slug`,
  familie,
  familieElterntext: null,
  anzahl: aufgaben,
  aufgaben,
  skills: [],
  skillUebergreifend: false,
  einstufung: 'befund',
})

const punkte = (el: HTMLElement, art: 'sicher' | 'uebung'): number => el.querySelectorAll(`.eb-s1-punkt-${art}`).length

describe('Seite 1 — So gehen wir vor', () => {
  it('fester Text für alle Berichte, ohne „abgeleitet“ und „ergeben sich“', () => {
    for (const [name, { data }] of Object.entries(FAELLE).filter(([n]) => n !== 'ohneKatalog')) {
      const kasten = seite1(data).getByTestId('eb-geprueft')
      expect(kasten, name).toHaveTextContent(de.s1.systematik.start)
      expect(kasten, name).toHaveTextContent(de.s1.systematik.seiten)
      expect(kasten.textContent, name).not.toMatch(/abgeleitet|ergeben sich|ergibt sich/i)
      expect(within(kasten).queryByTestId('eb-thema-satz'), name).toBeNull()
    }
  })

  it('der Stufensatz folgt der Klasse des Kindes', () => {
    const text = (grade: number): string | null | undefined =>
      seite1({ ...FAELLE.klasse7.data, grade }).getByTestId('eb-geprueft').querySelector('.eb-s1-geprueft-text')?.textContent
    expect(text(10)).toContain('Klasse 5/6 steht für die Grundlagen, Klasse 7/8 für weiterführenden Stoff, Klasse 10 für den aktuellen Stoff.')
    expect(text(7)).toContain('Klasse 5/6 steht für die Grundlagen, Klasse 7 für den aktuellen Stoff.')
    expect(text(5)).toContain('Im Mittelpunkt steht der Stoff aus Klasse 5.')
  })
})

describe('Seite 1 — Auf einen Blick', () => {
  it('keine Listen einzelner Bereiche, kein „+n weitere“, keine Weg-Grafik, kein Ansatz-Kasten mehr', () => {
    for (const [name, { data }] of Object.entries(FAELLE).filter(([n]) => n !== 'ohneKatalog')) {
      const s = seite1(data)
      expect(s.queryByTestId('eb-liste-sicher'), name).toBeNull()
      expect(s.queryByTestId('eb-liste-uebung'), name).toBeNull()
      expect(s.queryByTestId('eb-weg'), name).toBeNull()
      expect(s.queryByTestId('eb-ansatz'), name).toBeNull()
      expect(s.el.textContent, name).not.toMatch(/\+\d+ weitere|Sie sind hier/)
    }
  })

  it('ilkay: je Klassenstufe eine Zeile mit Punkten und Kurzsatz', () => {
    const s = seite1(FAELLE.ilkay.data)
    const zeilen = [...s.getByTestId('eb-stufen').querySelectorAll('li')]
    expect(zeilen.map((z) => z.querySelector('.eb-s1-stufe-name')?.textContent)).toEqual([
      'GrundlagenKlasse 5/6',
      'WeiterführendKlasse 7/8',
    ])
    expect(zeilen.map((z) => [punkte(z, 'sicher'), punkte(z, 'uebung')])).toEqual([
      [7, 8],
      [4, 8],
    ])
    expect(zeilen.map((z) => z.querySelector('.eb-s1-stufe-urteil')?.textContent)).toEqual([
      'hier liegen die Lücken',
      'hier liegen die Lücken',
    ])
    expect(zeilen[0]).toHaveAttribute('aria-label', 'Klasse 5/6: 7 sicher, 8 mit Übungsbedarf')
  })

  it('abgestuft: drei Stufen, Kurzsätze sicher und Lücken; aktuell mit seiner Klasse', () => {
    const zeilen = [...seite1(FAELLE.abgestuft.data).getByTestId('eb-stufen').querySelectorAll('li')]
    expect(zeilen.map((z) => z.querySelector('.eb-s1-stufe-urteil')?.textContent)).toEqual([
      'sicher',
      'hier liegen die Lücken',
      'hier liegen die Lücken',
    ])
    expect(zeilen[2].querySelector('.eb-s1-stufe-name')).toHaveTextContent('Aktueller StoffKlasse 9')
  })

  it('klasse7: Gemischtes heißt „teils sicher, teils Übungsbedarf“', () => {
    const zeilen = [...seite1(FAELLE.klasse7.data).getByTestId('eb-stufen').querySelectorAll('li')]
    expect(zeilen.map((z) => z.querySelector('.eb-s1-stufe-urteil')?.textContent)).toEqual([
      'hier liegen die Lücken',
      'teils sicher, teils Übungsbedarf',
    ])
  })

  it('die Punkte aller Zeilen ergeben die Zählung der Zusammenfassung, in allen Fällen', () => {
    for (const [name, { data }] of Object.entries(FAELLE).filter(([n]) => n !== 'ohneKatalog')) {
      const { el } = seite1(data)
      const [geprueft, sicher, uebung] = [...el.querySelector('.eb-s1-zeile')!.textContent!.matchAll(/\d+/g)].map((m) => Number(m[0]))
      expect(punkte(el, 'sicher'), name).toBe(sicher)
      expect(punkte(el, 'uebung'), name).toBe(uebung)
      expect(sicher + uebung, name).toBe(geprueft)
    }
  })

  it('Zusammenfassung in einer Zeile', () => {
    expect(seite1(FAELLE.ilkay.data).el.querySelector('.eb-s1-zeile')?.textContent).toBe(
      '27 Bereiche geprüft  ·  11 sicher  ·  16 Übungsbedarf',
    )
  })

  it('Lücken-Satz: die zwei Themenfelder mit dem meisten Übungsbedarf', () => {
    expect(seite1(FAELLE.ilkay.data).getByTestId('eb-luecken-satz')).toHaveTextContent(
      'Die Lücken liegen vor allem bei der Geometrie sowie bei Brüchen und Dezimalzahlen.',
    )
  })

  it('Lücken-Satz entfällt, wenn kein Feld zwei Bereiche mit Übungsbedarf hat und kein Muster da ist', () => {
    expect(seite1(FAELLE.allesSicher.data).queryByTestId('eb-luecken-satz')).toBeNull()
  })

  it('Sorgfalts-Muster: Satz zusätzlich zu den Lücken, nie ohne Datengrundlage', () => {
    const mit = seite1({ ...FAELLE.ilkay.data, fehlbilder: [fehlbild('vorzeichen', 3)] })
    expect(mit.getByTestId('eb-luecken-satz')).toHaveTextContent(de.s1.blick.muster)
    expect(mit.getByTestId('eb-luecken-satz')).toHaveTextContent('Die Lücken liegen vor allem bei')
    const zuWenig = seite1({ ...FAELLE.ilkay.data, fehlbilder: [fehlbild('vorzeichen', 2)] })
    expect(zuWenig.getByTestId('eb-luecken-satz')).not.toHaveTextContent(de.s1.blick.muster)
    // Nur Muster, keine Lücken-Felder.
    const nurMuster = seite1({ ...FAELLE.allesSicher.data, fehlbilder: [fehlbild('figuren', 4)] })
    expect(nurMuster.getByTestId('eb-luecken-satz').textContent).toBe(de.s1.blick.muster)
  })

  it('„Wir beginnen mit …, weil …“ nennt den ersten Schwerpunkt und seinen Grund', () => {
    expect(seite1(FAELLE.ilkay.data).getByTestId('eb-start')).toHaveTextContent(
      'Wir beginnen mit der Geometrie, weil hier schon Stoff aus Klasse 5/6 Übung braucht.',
    )
    expect(seite1(FAELLE.abgestuft.data).getByTestId('eb-start')).toHaveTextContent(
      'Wir beginnen mit dem Thema Reelle Zahlen, weil es das aktuelle Schulthema ist.',
    )
  })

  it('ohne Schwerpunkt: stattdessen der Satz „kein Übungsbedarf“', () => {
    const start = seite1(FAELLE.allesSicher.data).getByTestId('eb-start')
    expect(start.textContent).toBe(de.s1.blick.ansatzKeiner)
    expect(start).not.toHaveTextContent('Wir beginnen')
  })
})
