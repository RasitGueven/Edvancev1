// Station 02 · Lernstand (T3): Zahlen je Zählweise, Erklärtext, Kompetenzprofil
// mit Zählung je Zeile und die Details — Kontrollwerte aus Anhang C.
import { act, fireEvent, screen, within } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { Station2 } from './Station2'
import { zeigeStation } from './testStation'

const zeilen = (): HTMLElement[] => screen.getAllByRole('article')
const zeile = (feld: string): HTMLElement => zeilen().find((z) => within(z).queryByText(feld, { selector: '.tp-s2-feld' }))!
const zahl = (id: string): HTMLElement => screen.getByTestId(`tp-s2-zahl-${id}`)
const knopf = (z: HTMLElement): HTMLElement => within(z).getByRole('button')
const rechts = (z: HTMLElement): string => z.querySelector('.tp-s2-rechts')!.textContent ?? ''

afterEach(() => {
  vi.useRealTimers()
})

describe('Station 02 — ilkay', () => {
  it('zeigt 11 sicher und 16 Übungsbedarf, keine dritte Zahl', () => {
    zeigeStation(Station2, 'ilkay')
    expect(zahl('sicher')).toHaveTextContent('11sicher eingestuft')
    expect(zahl('uebung')).toHaveTextContent('16Übungsbedarf')
    expect(screen.queryByTestId('tp-s2-zahl-ueber')).toBeNull()
    expect(screen.getByText('27 von 130 Bereichen bis Klasse 10 untersucht.')).toBeInTheDocument()
    expect(screen.queryByText(/Übersprungen heißt/)).toBeNull()
    expect(screen.queryByTestId('tp-s2-legende-ueber')).toBeNull()
  })

  it('hat sechs Zeilen in der Reihenfolge der Themenfelder', () => {
    zeigeStation(Station2, 'ilkay')
    expect(zeilen().map((z) => z.querySelector('.tp-s2-feld')!.textContent)).toEqual([
      'Brüche & Dezimalzahlen',
      'Prozent & Dreisatz',
      'Terme & Gleichungen',
      'Geometrie',
      'Größen',
      'Zahlen & Rechnen',
    ])
  })

  it('Brüche & Dezimalzahlen: „5 von 8" und „2 sicher · 3 Übungsbedarf"', () => {
    zeigeStation(Station2, 'ilkay')
    const z = zeile('Brüche & Dezimalzahlen')
    expect(rechts(z)).toBe('5 von 82 sicher 3 Übungsbedarf')
    expect(z.querySelectorAll('.tp-s2-segment-sicher')).toHaveLength(2)
    expect(z.querySelectorAll('.tp-s2-segment-uebung')).toHaveLength(3)
    expect(z.querySelector('.tp-s2-spur')).toHaveAttribute('aria-hidden', 'true')
    expect(knopf(z)).toHaveAccessibleName(
      'Brüche & Dezimalzahlen: 5 von 8 untersucht, 2 sicher, 3 mit Übungsbedarf. Details anzeigen',
    )
  })

  it.each([
    ['Prozent & Dreisatz', '4 von 9'],
    ['Terme & Gleichungen', '4 von 23'],
    ['Geometrie', '6 von 40'],
    ['Größen', '5 von 6'],
    ['Zahlen & Rechnen', '3 von 14'],
  ])('%s: %s', (feld, text) => {
    zeigeStation(Station2, 'ilkay')
    expect(zeile(feld).querySelector('.tp-s2-zeile-zahl')).toHaveTextContent(text)
  })

  it('setzt die Attribute der Ansichtstests (data-tp-liste, data-tp-zeile, data-tp-bereiche)', () => {
    zeigeStation(Station2, 'ilkay')
    expect(document.querySelectorAll('[data-tp-liste]')).toHaveLength(1)
    expect(document.querySelectorAll('[data-tp-liste] [data-tp-zeile]')).toHaveLength(6)
    expect(zeile('Geometrie')).toHaveAttribute('data-tp-bereiche', '6')
    expect(zeile('Geometrie').querySelector('[aria-expanded]')).not.toBeNull()
  })
})

describe('Station 02 — übersprungen', () => {
  it('kombiniert: 16 Übungsbedarf, „davon 3 übersprungen", Punktmuster in drei Zeilen', () => {
    zeigeStation(Station2, 'uebersprungen')
    expect(zahl('sicher')).toHaveTextContent('11')
    expect(zahl('uebung')).toHaveTextContent('16Übungsbedarf')
    expect(zahl('ueber')).toHaveTextContent('3davon übersprungen')
    expect(screen.getByText(/Übersprungen heißt: Bei allen Aufgaben zu diesem Bereich hat Ilkay/)).toBeInTheDocument()
    expect(screen.getByTestId('tp-s2-legende-ueber')).toHaveTextContent('Übersprungen („Weiß ich nicht“)')
    const mitMuster = zeilen().filter((z) => z.querySelector('.tp-s2-segment-ueber'))
    expect(mitMuster.map((z) => z.querySelector('.tp-s2-feld')!.textContent)).toEqual([
      'Prozent & Dreisatz',
      'Terme & Gleichungen',
      'Geometrie',
    ])
    expect(document.querySelector('.tp-s2')).not.toHaveClass('tp-s2-getrennt')
  })

  it('kombiniert je Zeile: Übungsbedarf mit übersprungen, „davon 1 übersprungen"', () => {
    zeigeStation(Station2, 'uebersprungen')
    const z = zeile('Prozent & Dreisatz')
    expect(rechts(z)).toBe('4 von 91 sicher 3 Übungsbedarf davon 1 übersprungen')
    expect(knopf(z)).toHaveAccessibleName(
      'Prozent & Dreisatz: 4 von 9 untersucht, 1 sicher, 3 mit Übungsbedarf, davon 1 übersprungen. Details anzeigen',
    )
  })

  it('getrennt über die Prop: 11 · 13 · 3, neutrales Muster', () => {
    zeigeStation(Station2, 'uebersprungen', { anzeige: 'getrennt' })
    expect(zahl('sicher')).toHaveTextContent('11')
    expect(zahl('uebung')).toHaveTextContent('13Übungsbedarf')
    expect(zahl('ueber')).toHaveTextContent('3übersprungen')
    expect(document.querySelector('.tp-s2')).toHaveClass('tp-s2-getrennt')
    const z = zeile('Geometrie')
    expect(rechts(z)).toBe('6 von 401 sicher 4 Übungsbedarf 1 übersprungen')
    expect(knopf(z)).toHaveAccessibleName(
      'Geometrie: 6 von 40 untersucht, 1 sicher, 4 mit Übungsbedarf, 1 übersprungen. Details anzeigen',
    )
  })

  it('nennt die übersprungenen Bereiche im Detail beim Namen', () => {
    zeigeStation(Station2, 'uebersprungen')
    const spalte = within(zeile('Geometrie')).getByTestId('tp-s2-spalte-ueber')
    expect(spalte).toHaveTextContent('Übersprungen · „Weiß ich nicht“')
    expect(within(spalte).getAllByRole('listitem', { hidden: true }).map((li) => li.textContent)).toEqual([
      'Winkelsummen im Dreieck und Viereck',
    ])
  })
})

describe('Station 02 — weitere Fälle', () => {
  it('alleFelder: acht Zeilen', () => {
    zeigeStation(Station2, 'alleFelder')
    expect(zeilen()).toHaveLength(8)
  })

  it('ohneName: Titel und Erklärsatz ohne Namen', () => {
    zeigeStation(Station2, 'ohneName')
    expect(screen.getByRole('heading', { level: 3 })).toHaveTextContent(/^Kompetenzprofil$/)
    zeigeStation(Station2, 'ilkay')
    expect(screen.getAllByRole('heading', { level: 3 })[1]).toHaveTextContent('Ilkays Kompetenzprofil')
  })
})

describe('Station 02 — Details', () => {
  it('höchstens eins offen; erneutes Antippen schließt', () => {
    zeigeStation(Station2, 'ilkay')
    const [a, b] = zeilen()
    fireEvent.click(knopf(a))
    expect(knopf(a)).toHaveAttribute('aria-expanded', 'true')
    expect(knopf(a)).toHaveAccessibleName(/Details schließen$/)
    fireEvent.click(knopf(b))
    expect(knopf(a)).toHaveAttribute('aria-expanded', 'false')
    expect(knopf(b)).toHaveAttribute('aria-expanded', 'true')
    expect(document.querySelectorAll('[aria-expanded="true"]')).toHaveLength(1)
    fireEvent.click(knopf(b))
    expect(document.querySelectorAll('[aria-expanded="true"]')).toHaveLength(0)
  })

  it('Spalten nur, wenn nicht leer; alle Bereiche nach Klasse und Label', () => {
    zeigeStation(Station2, 'ilkay')
    const z = zeile('Brüche & Dezimalzahlen')
    expect(within(z).getByTestId('tp-s2-spalte-sicher')).toHaveTextContent('Sicher im Test')
    expect(within(z).getByTestId('tp-s2-spalte-uebung')).toHaveTextContent('Hier weiterüben')
    expect(within(z).queryByTestId('tp-s2-spalte-ueber')).toBeNull()
    expect(within(z).queryByTestId('tp-s2-keine-uebung')).toBeNull()
    const uebung = within(within(z).getByTestId('tp-s2-spalte-uebung')).getAllByRole('listitem', { hidden: true })
    expect(uebung.map((li) => li.textContent)).toEqual(['Brüche addieren', 'Brüche dividieren', 'Brüche multiplizieren'])
  })

  it('keineUebung nur ohne Übungsbedarf und ohne Übersprungenes (allesSicher)', () => {
    zeigeStation(Station2, 'allesSicher')
    for (const z of zeilen()) {
      expect(within(z).getByTestId('tp-s2-keine-uebung')).toHaveTextContent('Kein Übungsbedarf in diesem Themenfeld.')
      expect(within(z).queryByTestId('tp-s2-spalte-uebung')).toBeNull()
    }
  })

  it('ohne Sicheres steht keinSicher (nichtsSicher)', () => {
    zeigeStation(Station2, 'nichtsSicher')
    const spalte = within(zeilen()[0]).getByTestId('tp-s2-spalte-sicher')
    expect(spalte).toHaveTextContent('In diesem Themenfeld war noch nichts sicher.')
    expect(within(zeilen()[0]).queryByTestId('tp-s2-keine-uebung')).toBeNull()
  })

  it('das geschlossene Detail ist vor Vorleseprogrammen verborgen', () => {
    zeigeStation(Station2, 'ilkay')
    const z = zeilen()[0]
    expect(z.querySelector('.tp-s2-detail')).toHaveAttribute('aria-hidden', 'true')
    fireEvent.click(knopf(z))
    expect(z.querySelector('.tp-s2-detail')).toHaveAttribute('aria-hidden', 'false')
  })

  it('holt die geöffnete Zeile in den sichtbaren Bereich der Liste — nur die Liste scrollt', () => {
    vi.useFakeTimers()
    zeigeStation(Station2, 'ilkay')
    const liste = document.querySelector<HTMLElement>('[data-tp-liste]')!
    const z = zeilen()[5]
    const scrollBy = vi.fn()
    liste.scrollBy = scrollBy
    liste.getBoundingClientRect = () => ({ top: 100, bottom: 400 }) as DOMRect
    z.getBoundingClientRect = () => ({ top: 350, bottom: 520 }) as DOMRect
    fireEvent.click(knopf(z))
    act(() => {
      vi.runAllTimers()
    })
    expect(scrollBy).toHaveBeenCalledWith({ top: 130, behavior: 'smooth' })
  })
})
