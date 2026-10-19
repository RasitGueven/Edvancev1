// Seite 3 des Eltern-Berichts R7 (Einordnung als Pyramide) für die Fixture-Fälle.
import { render, within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import '@/i18n'

import { ElternberichtBogen } from '@/components/edvance/elternbericht/Bogen'
import { Lesehilfe } from '@/components/edvance/elternbericht/Lesehilfe'
import { Pyramide } from '@/components/edvance/elternbericht/Pyramide'
import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import type { EbBereich, EbEbene, ReportData } from '@/types'

function seite3(data: ReportData) {
  const { container } = render(<ElternberichtBogen data={data} notes={null} tiers={[]} />)
  const el = container.querySelector<HTMLElement>('.eb-seite[data-seite="3"]')!
  return { ...within(el), el }
}

const ebenenVon = (el: HTMLElement): HTMLElement[] =>
  [...el.querySelectorAll<HTMLElement>('[data-testid="eb-ebene"]')]
const namen = (el: HTMLElement): string[] =>
  [...el.querySelectorAll('.eb-s3-ebene-name')].map((n) => n.textContent ?? '')

function pyramideVon(data: ReportData): EbEbene[] {
  const { kompetenzen, katalog } = data.erzaehlung
  return baueElternbericht({ kompetenzen, katalog, klasse: data.grade })!.pyramide
}

const bereich = (n: number, sicher: boolean): EbBereich => ({
  skillKey: `s${n}`,
  label: `Bereich ${n}`,
  feld: 'geometrie',
  klasse: 7,
  sicher,
})

describe('Seite 3 — Pyramide aus den Daten', () => {
  it('ilkay: so viele Ebenen wie bericht.pyramide, mit Klassenangabe und Zählung', () => {
    const erwartet = pyramideVon(FAELLE.ilkay.data)
    const { el } = seite3(FAELLE.ilkay.data)
    expect(ebenenVon(el)).toHaveLength(erwartet.length)
    expect(ebenenVon(el).map((e) => e.dataset.ebene)).toEqual(erwartet.map((e) => e.ebene))
    // Nach den Daten: alle Bereiche in Klasse 5 bis 8 (Bauauftrag, Entscheidung 6).
    expect(namen(el)).toEqual(['Weiterführende Themen', 'Grundlagen'])
    expect(within(ebenenVon(el)[0]).getByText('Klasse 7/8')).toBeInTheDocument()
    expect(within(ebenenVon(el)[0]).getByText('4 sicher · 8 Übungsbedarf')).toBeInTheDocument()
  })

  it('klasse10neu: drei Ebenen, das lange Intro', () => {
    const { el, getByText } = seite3(FAELLE.klasse10neu.data)
    expect(namen(el)).toEqual(['Aktueller Unterrichtsstoff', 'Weiterführende Themen', 'Grundlagen'])
    expect(getByText(/unten die Grundlagen aus früheren Klassen/)).toBeInTheDocument()
  })

  it('klasse7: zwei Ebenen, das kurze Intro', () => {
    const { el, queryByText } = seite3(FAELLE.klasse7.data)
    expect(namen(el)).toEqual(['Aktueller Unterrichtsstoff', 'Grundlagen'])
    expect(queryByText(/unten die Grundlagen/)).toBeNull()
    expect(el.querySelector('.eb-s3-intro')).toHaveTextContent(
      'Jeder untersuchte Bereich steht dort, wo er im Lernstoff liegt. So sehen Sie',
    )
  })

  it('spaeter: oberste Ebene „Stoff späterer Klassen“, Zählung nur mit dem, was es gibt', () => {
    const { el } = seite3(FAELLE.spaeter.data)
    expect(namen(el)[0]).toBe('Stoff späterer Klassen')
    const oben = ebenenVon(el)[0]
    expect(within(oben).getByText('Klasse 9/10')).toBeInTheDocument()
    expect(oben.querySelector('.eb-s3-ebene-zaehlung')).toHaveTextContent(/^1 Übungsbedarf$/)
  })

  it('Breitenklassen nach Position von unten: unten p0 (507), darüber p1, p2', () => {
    const { el } = seite3(FAELLE.spaeter.data)
    expect(ebenenVon(el).map((e) => e.className)).toEqual([
      'eb-s3-ebene eb-s3-ebene-p2',
      'eb-s3-ebene eb-s3-ebene-p1',
      'eb-s3-ebene eb-s3-ebene-p0',
    ])
    expect(ebenenVon(seite3(FAELLE.ilkay.data).el).map((e) => e.className)).toEqual([
      'eb-s3-ebene eb-s3-ebene-p1',
      'eb-s3-ebene eb-s3-ebene-p0',
    ])
  })

  it('Titel: ohne sicheren Bereich „Wo wir ansetzen.“', () => {
    expect(seite3(FAELLE.ilkay.data).getByRole('heading', { level: 1 })).toHaveTextContent(
      'Auf vorhandenen Stärken aufbauen.',
    )
    expect(seite3(FAELLE.nichtsSicher.data).getByRole('heading', { level: 1 })).toHaveTextContent(
      'Wo wir ansetzen.',
    )
  })

  it('Einträge tragen Punkt und Vorlesetext mit Zustand', () => {
    const { getByLabelText } = seite3(FAELLE.ilkay.data)
    expect(getByLabelText('Prozentwert berechnen: sicher')).toHaveClass('eb-s3-eintrag-sicher')
    expect(getByLabelText('Grundwert berechnen: Übungsbedarf')).toHaveClass('eb-s3-eintrag-uebung')
  })
})

describe('Pyramide — Reihen, Gruppen und Klassenangabe', () => {
  it('höchstens vier Themenfelder je Reihe, dann eine neue Reihe', () => {
    const { el } = seite3(FAELLE.alleFelder.data)
    const oben = ebenenVon(el)[0]
    const reihen = within(oben).getAllByTestId('eb-reihe')
    expect(reihen.map((r) => within(r).getAllByTestId('eb-gruppe').length)).toEqual([4, 1])
  })

  it('je Gruppe höchstens sechs Einträge, danach „+n weitere“', () => {
    const ebene: EbEbene = {
      ebene: 'weiterfuehrend',
      stufen: ['erste'],
      sicher: 3,
      uebung: 6,
      gruppen: [{ feld: 'geometrie', eintraege: [1, 2, 3, 4, 5, 6, 7, 8, 9].map((n) => bereich(n, n <= 3)) }],
    }
    const { container } = render(<Pyramide ebenen={[ebene]} />)
    expect(container.querySelectorAll('.eb-s3-eintrag')).toHaveLength(6)
    expect(container.querySelector('.eb-s3-weitere')).toHaveTextContent('+3 weitere')
  })

  it('genau sechs Einträge: kein „weitere“', () => {
    const ebene: EbEbene = {
      ebene: 'grundlagen',
      stufen: ['erprobung'],
      sicher: 0,
      uebung: 6,
      gruppen: [{ feld: 'geometrie', eintraege: [1, 2, 3, 4, 5, 6].map((n) => bereich(n, false)) }],
    }
    const { container } = render(<Pyramide ebenen={[ebene]} />)
    expect(container.querySelector('.eb-s3-weitere')).toBeNull()
    expect(container.querySelector('.eb-s3-ebene-zaehlung')).toHaveTextContent(/^6 Übungsbedarf$/)
  })

  it('über mehrere Stufen die Spanne „Klasse 7–10“', () => {
    const ebene: EbEbene = {
      ebene: 'weiterfuehrend',
      stufen: ['erste', 'zweite'],
      sicher: 1,
      uebung: 0,
      gruppen: [{ feld: 'geometrie', eintraege: [bereich(1, true)] }],
    }
    const { getByText } = render(<Pyramide ebenen={[ebene]} />)
    expect(getByText('Klasse 7–10')).toBeInTheDocument()
  })
})

describe('Lesehilfe', () => {
  const zeilen = (el: HTMLElement): string[] =>
    [...el.querySelectorAll('.eb-s3-lesen-zeile')].map((z) => z.textContent ?? '')

  it('eine Zeile je Ebene, mit Klassen bzw. zwei Themenfeldern als Beispiel', () => {
    const { el } = seite3(FAELLE.spaeter.data)
    expect(zeilen(el)).toEqual([
      'Stoff späterer Klassen: was laut Lehrplan erst in Klasse 9/10 kommt.',
      'Aktueller Unterrichtsstoff: was laut Lehrplan in Klasse 7/8 dran ist.',
      'Grundlagen: Stoff aus früheren Klassenstufen, zum Beispiel Brüche & Dezimalzahlen oder Geometrie.',
    ])
  })

  it('Mini-Pyramide: so viele Balken wie Ebenen, die eigene hervorgehoben', () => {
    const { el } = seite3(FAELLE.klasse10neu.data)
    const minis = [...el.querySelectorAll('[data-testid="eb-mini"]')]
    expect(minis).toHaveLength(3)
    minis.forEach((m, i) => {
      const balken = [...m.querySelectorAll('rect')]
      expect(balken.map((b) => b.getAttribute('width'))).toEqual(['8.4', '12.2', '16'])
      expect(balken.findIndex((b) => b.classList.contains('eb-s3-balken-eigen'))).toBe(i)
    })
  })

  it('ohne Themenfeld die Fassung ohne Beispiel', () => {
    const leer: EbEbene[] = [
      { ebene: 'weiterfuehrend', stufen: ['erste'], sicher: 0, uebung: 0, gruppen: [] },
      { ebene: 'grundlagen', stufen: ['erprobung'], sicher: 0, uebung: 0, gruppen: [] },
    ]
    const { container } = render(<Lesehilfe ebenen={leer} name="Ilkay" wessen="Ilkays" />)
    expect(zeilen(container)).toEqual([
      'Weiterführende Themen: der Stoff nach den Grundlagen.',
      'Grundlagen: Stoff aus früheren Klassenstufen.',
    ])
  })

  it('mit Namen „gilt nur für Ilkay“, ohne Namen „Ihr Kind“', () => {
    expect(seite3(FAELLE.ilkay.data).el.querySelector('.eb-s3-lesen-nur')).toHaveTextContent(
      'Die Pyramide gilt nur für Ilkay. Was oben steht, richtet sich nach Ilkays Klasse;',
    )
    expect(seite3(FAELLE.ohneName.data).el.querySelector('.eb-s3-lesen-nur')).toHaveTextContent(
      'Die Pyramide gilt nur für Ihr Kind. Was oben steht, richtet sich nach der Klasse Ihres Kindes;',
    )
  })

  it('Hinweis: bei einer Ebene die kurze Fassung', () => {
    const eine = pyramideVon(FAELLE.ilkay.data).slice(0, 1)
    const { container } = render(<Lesehilfe ebenen={eine} name={null} wessen={null} />)
    expect(container.querySelector('.eb-s3-lesen-hinweis')).toHaveTextContent(
      /^Die Pyramide zeigt, wo ein Bereich im Lernstoff liegt, keine feste Voraussetzung\.$/,
    )
    expect(seite3(FAELLE.ilkay.data).el.querySelector('.eb-s3-lesen-hinweis')).toHaveTextContent(
      /prüft der Coach im Unterricht\.$/,
    )
  })
})
