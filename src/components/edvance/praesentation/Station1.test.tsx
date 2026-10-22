// Station 01 · Überblick (T3, PS-1 Entscheidungen 4–6): Überschrift, Anliegen und
// die zwei Karten mit höchstens zwei Zeilen — für die Fälle aus PRAESENTATION_FAELLE.
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

  it('ohne Namen: „Ihrem Kind", Kicker „Ausgangspunkt"', () => {
    zeigeStation(Station1, 'ohneName')
    expect(titel()).toHaveTextContent('Was wir bei Ihrem Kind gesehen haben')
    expect(document.querySelector('.tp-kicker')).toHaveTextContent(/^01Ausgangspunkt$/)
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

const zeilenIn = (id: 'gelungen' | 'ueben'): string[] =>
  within(karte(id))
    .queryAllByRole('listitem')
    .map((li) => li.textContent ?? '')

describe('Station 01 — nur Titel, Anliegen und Karten (PS-1)', () => {
  it.each(['ilkay', 'allesSicher', 'nichtsSicher', 'abgestuft'])('%s: kein Leitsatz, keine Notiz, keine Fußzeile', (fall) => {
    const { container } = zeigeStation(Station1, fall)
    expect(container.querySelector('.tp-s1-lead, .tp-s1-notiz, .tp-s1-fuss')).toBeNull()
    expect(screen.queryByText(/sehen wir uns jetzt gemeinsam an/)).toBeNull()
    expect(screen.queryByText(/Klasse 10$/)).toBeNull()
    expect(screen.queryByText(/Im Blick/)).toBeNull()
    expect(screen.queryByText(/Weiterwischen/)).toBeNull()
  })

  it('das Anliegen hat höchstens zwei Sätze: Frage und Antwort zum Thema (abgestuft)', () => {
    zeigeStation(Station1, 'abgestuft')
    const satz = screen.getByTestId('tp-s1-anliegen').textContent ?? ''
    expect(satz.match(/[.?!](\s|$)/g)?.length ?? 0).toBeLessThanOrEqual(2)
    expect(satz).toMatch(/Reelle Zahlen/)
  })
})

describe('Station 01 — Karten', () => {
  it('ilkay: je Karte zwei Zeilen untereinander, dann „+2 weitere"', () => {
    zeigeStation(Station1, 'ilkay')
    expect(zeilenIn('gelungen')).toEqual(['Größen', 'Zahlen & Rechnen'])
    expect(zeilenIn('ueben')).toEqual(['Geometrie', 'Brüche & Dezimalzahlen', '+2 weitere'])
  })

  it('allesSicher: zwei sichere Felder und „+4 weitere", keine Übung', () => {
    zeigeStation(Station1, 'allesSicher')
    expect(zeilenIn('gelungen')).toEqual(['Geometrie', 'Brüche & Dezimalzahlen', '+4 weitere'])
    expect(within(karte('ueben')).getByText('Kein Bereich mit Übungsbedarf.')).toBeInTheDocument()
  })

  it('nichtsSicher: nichts sicher', () => {
    zeigeStation(Station1, 'nichtsSicher')
    expect(within(karte('gelungen')).getByText('Noch kein Bereich sicher.')).toBeInTheDocument()
    expect(zeilenIn('ueben')).toEqual(['Geometrie', 'Brüche & Dezimalzahlen', '+4 weitere'])
  })

  it('alleFelder: „Ein Bereich ist schon sicher: Brüche kürzen."', () => {
    zeigeStation(Station1, 'alleFelder')
    expect(within(karte('gelungen')).getByText('Ein Bereich ist schon sicher: Brüche kürzen.')).toBeInTheDocument()
    expect(zeilenIn('ueben')).toEqual(['Brüche & Dezimalzahlen', 'Prozent & Dreisatz', '+6 weitere'])
  })

  it('mit Thema-Schwerpunkt steht die Startstelle in „Gezielt üben" zuerst (abgestuft)', () => {
    zeigeStation(Station1, 'abgestuft')
    expect(zeilenIn('ueben')).toEqual(['Wurzelgesetze für Produkt und Quotient', 'Geometrie', '+2 weitere'])
  })

  it.each(Object.keys(PRAESENTATION_FAELLE).filter((f) => f !== 'ohneKatalog'))(
    '%s: höchstens zwei Einträge je Karte plus „+n weitere"',
    (fall) => {
      zeigeStation(Station1, fall)
      for (const id of ['gelungen', 'ueben'] as const) {
        const z = zeilenIn(id)
        expect(z.filter((t) => !/^\+\d+ weitere$/.test(t)).length, id).toBeLessThanOrEqual(2)
      }
    },
  )

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
