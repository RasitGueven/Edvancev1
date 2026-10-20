// Station 01 · Überblick (T3): Überschrift, Leitsatz, Fach und Klasse, die zwei
// Karten und die Fußzeile — für die Fälle aus PRAESENTATION_FAELLE.
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'

import { screen, within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import '@/i18n'

import { PRAESENTATION_FAELLE } from '@/lib/report/praesentation/fixtures'
import type { ReportBaustein, ReportData } from '@/types'

import { Station1 } from './Station1'
import { zeigeStation } from './testStation'

const KOPF: ReportBaustein[] = (['gemischt', 'sicher', 'uebung'] as const).map((fall) => ({
  schluessel: `kopf.${fall}.a`,
  slot: 'kopf',
  fall,
  variante: 'a',
  text: `{name} – Kopfsatz ${fall}.`,
}))

const mitKopf = (fall: string): ReportData => {
  const data = PRAESENTATION_FAELLE[fall].data
  return { ...data, erzaehlung: { ...data.erzaehlung, bausteine: [...data.erzaehlung.bausteine, ...KOPF] } }
}

const titel = (): HTMLElement => screen.getByRole('heading', { level: 1 })
const karte = (id: 'gelungen' | 'ueben'): HTMLElement => screen.getByTestId(`tp-s1-${id}`)

describe('Station 01 — Überschrift', () => {
  it('nimmt ohne freigegebenen Kopfsatz die Ersatzüberschrift (ilkay, ohneName)', () => {
    zeigeStation(Station1, 'ilkay')
    expect(titel()).toHaveTextContent('Was wir bei Ilkay gesehen haben')
    expect(document.querySelector('.tp-kicker')).toHaveTextContent(/^01Ilkays Ausgangspunkt$/)
  })

  it('ohne Namen: „Ihrem Kind", Kicker „Ausgangspunkt", Fußzeile ohne Namen', () => {
    zeigeStation(Station1, 'ohneName')
    expect(titel()).toHaveTextContent('Was wir bei Ihrem Kind gesehen haben')
    expect(document.querySelector('.tp-kicker')).toHaveTextContent(/^01Ausgangspunkt$/)
    expect(screen.getByText(/Weiterwischen zum Kompetenzprofil/)).toBeInTheDocument()
  })

  it('nimmt den freigegebenen Kopfsatz zum Fall wie der Druckbogen', () => {
    zeigeStation(Station1, 'ilkay', { data: mitKopf('ilkay') })
    expect(titel()).toHaveTextContent('Ilkay – Kopfsatz gemischt.')
  })

  it('mit Kopfsatz ohne Namen steht „Ihr Kind"', () => {
    zeigeStation(Station1, 'ohneName', { data: mitKopf('ohneName') })
    expect(titel()).toHaveTextContent('Ihr Kind – Kopfsatz gemischt.')
  })

  it('verkleinert lange Kopfsätze über eine Klasse, nie über Inline-Styles', () => {
    const lang = mitKopf('ilkay')
    lang.erzaehlung.bausteine = lang.erzaehlung.bausteine.map((b) =>
      b.slot === 'kopf' ? { ...b, text: '{name} zeigt sichere Ansätze in mehreren Themenfeldern und klaren Übungsbedarf bei Brüchen.' } : b,
    )
    zeigeStation(Station1, 'ilkay', { data: lang })
    expect(titel()).toHaveClass('tp-s1-sehr-lang')
    expect(titel()).not.toHaveAttribute('style')
  })
})

describe('Station 01 — Leitsatz und Zeile', () => {
  it.each([
    ['ilkay', 'Was schon gelingt und wo noch Übung nötig ist, sehen wir uns jetzt gemeinsam an.'],
    ['allesSicher', 'Was schon gelingt, sehen wir uns jetzt gemeinsam an.'],
    ['nichtsSicher', 'Wo noch Übung nötig ist und wo wir ansetzen, sehen wir uns jetzt gemeinsam an.'],
  ])('Leitsatz je kopfFall (%s)', (fall, satz) => {
    zeigeStation(Station1, fall)
    expect(screen.getByText(satz)).toBeInTheDocument()
  })

  it('nennt Fach, Klasse und das nächste Thema', () => {
    zeigeStation(Station1, 'ilkay')
    expect(screen.getByText('Mathematik · Klasse 10')).toBeInTheDocument()
    expect(screen.getByText('Im Blick: Algebra & Funktionen')).toBeInTheDocument()
    expect(screen.getByText(/Weiterwischen, um Ilkays Kompetenzprofil zu sehen/)).toBeInTheDocument()
  })

  it('lässt „Im Blick" ohne Thema still weg', () => {
    const data = { ...PRAESENTATION_FAELLE.ilkay.data, naechstesThema: null }
    zeigeStation(Station1, 'ilkay', { data })
    expect(screen.queryByText(/Im Blick/)).toBeNull()
  })
})

describe('Station 01 — Karten', () => {
  it('ilkay: Schon gelungen = Größen, Zahlen & Rechnen; Gezielt üben = Geometrie, Brüche & Dezimalzahlen', () => {
    zeigeStation(Station1, 'ilkay')
    expect(within(karte('gelungen')).getByText('Größen und Zahlen & Rechnen')).toBeInTheDocument()
    expect(within(karte('ueben')).getByText('Geometrie und Brüche & Dezimalzahlen')).toBeInTheDocument()
  })

  it('allesSicher: keine Übung', () => {
    zeigeStation(Station1, 'allesSicher')
    expect(within(karte('gelungen')).getByText('Geometrie und Brüche & Dezimalzahlen')).toBeInTheDocument()
    expect(within(karte('ueben')).getByText('Kein Bereich mit Übungsbedarf.')).toBeInTheDocument()
  })

  it('nichtsSicher: nichts sicher', () => {
    zeigeStation(Station1, 'nichtsSicher')
    expect(within(karte('gelungen')).getByText('Noch kein Bereich sicher.')).toBeInTheDocument()
    expect(within(karte('ueben')).getByText('Geometrie und Brüche & Dezimalzahlen')).toBeInTheDocument()
  })

  it('alleFelder: „Ein Bereich ist schon sicher: Brüche kürzen."', () => {
    zeigeStation(Station1, 'alleFelder')
    expect(within(karte('gelungen')).getByText('Ein Bereich ist schon sicher: Brüche kürzen.')).toBeInTheDocument()
    expect(within(karte('ueben')).getByText('Brüche & Dezimalzahlen und Prozent & Dreisatz')).toBeInTheDocument()
  })

  it('einSchwerpunkt: Übung in keinem Feld überwiegend → Plural mit Beispiel', () => {
    zeigeStation(Station1, 'einSchwerpunkt')
    expect(
      within(karte('ueben')).getByText('Einzelne Bereiche brauchen noch Übung, zum Beispiel Flächeneinheiten.'),
    ).toBeInTheDocument()
  })

  it('beide Karten sind Pflichtteile und nicht vor Vorleseprogrammen verborgen', () => {
    zeigeStation(Station1, 'ilkay')
    for (const id of ['gelungen', 'ueben'] as const) {
      expect(karte(id)).toHaveAttribute('data-tp-pflicht')
      expect(karte(id).closest('[aria-hidden="true"]')).toBeNull()
    }
  })

  it('bei 744 px Breite bleiben die Karten: unter 800 px entfällt nur das Bild', () => {
    const css = readFileSync(resolve(__dirname, '../../../styles/praesentation/station1.css'), 'utf8')
    const schmal = css.slice(css.indexOf('@media (max-width: 800px)'))
    const block = schmal.slice(0, schmal.indexOf('\n}\n'))
    expect(block).toMatch(/\.tp-s1-kreise\s*\{\s*display: none;/)
    expect(block).toMatch(/\.tp-s1-karte\s*\{\s*position: static;/)
    expect(css).not.toMatch(/\.tp-s1-(karte|bild)[^{]*\{[^}]*display: none/)
  })
})
