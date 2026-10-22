// Station 02 · Lernstand (T3, PS-1 Entscheidungen 7–9): zwei Zahlen, „davon
// übersprungen" mit Erklärsatz beim Antippen, höchstens vier Profilzeilen mit
// zwei Anteilen und die Details — Kontrollwerte aus Anhang C.
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
const felder = (): string[] => zeilen().map((z) => z.querySelector('.tp-s2-feld')!.textContent ?? '')
const alleZeigen = (): void => {
  fireEvent.click(screen.getByTestId('tp-s2-alle'))
}

afterEach(() => {
  vi.useRealTimers()
})

describe('Station 02 — ilkay', () => {
  it('zeigt 11 sicher und 16 Übungsbedarf, keine dritte Zahl, keinen Untersucht-Satz', () => {
    zeigeStation(Station2, 'ilkay')
    expect(zahl('sicher')).toHaveTextContent('11sicher eingestuft')
    expect(zahl('uebung')).toHaveTextContent(/^16Übungsbedarf$/)
    expect(screen.queryByTestId('tp-s2-zahl-ueber')).toBeNull()
    expect(document.querySelectorAll('.tp-s2-zahl')).toHaveLength(2)
    expect(screen.queryByText(/Bereichen bis Klasse/)).toBeNull()
    expect(screen.queryByText(/Übersprungen heißt/)).toBeNull()
    expect(screen.queryByTestId('tp-s2-legende-ueber')).toBeNull()
    expect(document.querySelectorAll('.tp-s2-legende li')).toHaveLength(2)
  })

  it('höchstens vier Zeilen: Felder mit Übungsbedarf in der Schwerpunkt-Reihenfolge, der Rest hinter „Alle Themenfelder zeigen"', () => {
    zeigeStation(Station2, 'ilkay')
    expect(felder()).toEqual(['Geometrie', 'Brüche & Dezimalzahlen', 'Größen', 'Prozent & Dreisatz'])
    const alle = screen.getByTestId('tp-s2-alle')
    expect(alle).toHaveTextContent('Alle Themenfelder zeigen')
    expect(alle).toHaveAttribute('aria-expanded', 'false')
    alleZeigen()
    expect(felder()).toEqual([
      'Geometrie',
      'Brüche & Dezimalzahlen',
      'Größen',
      'Prozent & Dreisatz',
      'Terme & Gleichungen',
      'Zahlen & Rechnen',
    ])
    expect(alle).toHaveAttribute('aria-expanded', 'true')
    alleZeigen()
    expect(zeilen()).toHaveLength(4)
  })

  it('Brüche & Dezimalzahlen: „2 sicher · 3 Übungsbedarf", ein Balken mit zwei Anteilen, kein „x von y"', () => {
    zeigeStation(Station2, 'ilkay')
    const z = zeile('Brüche & Dezimalzahlen')
    expect(rechts(z)).toBe('2 sicher 3 Übungsbedarf')
    const anteile = within(z).getAllByTestId('tp-s2-anteil')
    expect(anteile).toHaveLength(2)
    expect(anteile[0]).toHaveClass('tp-s2-anteil-sicher')
    expect(anteile[0].style.getPropertyValue('--anteil')).toBe('2')
    expect(anteile[1]).toHaveClass('tp-s2-anteil-uebung')
    expect(anteile[1].style.getPropertyValue('--anteil')).toBe('3')
    expect(z.querySelector('.tp-s2-balken')).toHaveAttribute('aria-hidden', 'true')
    expect(z.querySelector('.tp-s2-zeile-zahl')).toBeNull()
    for (const sichtbar of z.querySelectorAll('[aria-hidden="true"]')) expect(sichtbar.textContent).not.toMatch(/\d+ von \d+/)
    expect(knopf(z)).toHaveAccessibleName(
      'Brüche & Dezimalzahlen: 5 von 8 untersucht, 2 sicher, 3 mit Übungsbedarf. Details anzeigen',
    )
  })

  it('setzt die Attribute der Ansichtstests (data-tp-liste, data-tp-zeile, data-tp-bereiche)', () => {
    zeigeStation(Station2, 'ilkay')
    expect(document.querySelectorAll('[data-tp-liste]')).toHaveLength(1)
    expect(document.querySelectorAll('[data-tp-liste] [data-tp-zeile]')).toHaveLength(4)
    expect(zeile('Geometrie')).toHaveAttribute('data-tp-bereiche', '6')
    expect(zeile('Geometrie').querySelector('[aria-expanded]')).not.toBeNull()
  })
})

describe('Station 02 — Reihenfolge mit Thema', () => {
  it('abgestuft: zuerst das Feld der Startstelle, dann die Schwerpunkte, dann die sicheren Felder', () => {
    zeigeStation(Station2, 'abgestuft')
    expect(felder()).toEqual(['Zahlen & Rechnen', 'Terme & Gleichungen', 'Geometrie', 'Daten & Zufall'])
    alleZeigen()
    expect(felder().at(-1)).toBe('Brüche & Dezimalzahlen')
  })

  it('ohne mehr als vier Felder kein „Alle Themenfelder zeigen" (dreiSchwerpunkte)', () => {
    zeigeStation(Station2, 'dreiSchwerpunkte')
    expect(zeilen()).toHaveLength(3)
    expect(screen.queryByTestId('tp-s2-alle')).toBeNull()
  })
})

describe('Station 02 — übersprungen', () => {
  it('kombiniert: 16 Übungsbedarf, darunter „davon 3 übersprungen", Erklärsatz erst beim Antippen', () => {
    zeigeStation(Station2, 'uebersprungen')
    expect(zahl('sicher')).toHaveTextContent('11')
    expect(document.querySelectorAll('.tp-s2-zahl')).toHaveLength(2)
    const klein = zahl('ueber')
    expect(zahl('uebung')).toContainElement(klein)
    expect(zahl('uebung').querySelector('strong')).toHaveTextContent('16')
    expect(klein).toHaveTextContent(/^davon 3 übersprungen$/)
    const erklaer = screen.getByTestId('tp-s2-erklaer')
    expect(erklaer).not.toBeVisible()
    expect(klein).toHaveAttribute('aria-expanded', 'false')
    fireEvent.click(klein)
    expect(erklaer).toBeVisible()
    expect(erklaer).toHaveTextContent(/Übersprungen heißt: Bei allen Aufgaben zu diesem Bereich hat Ilkay/)
    expect(klein).toHaveAttribute('aria-expanded', 'true')
    expect(screen.getByTestId('tp-s2-legende-ueber')).toHaveTextContent('Übersprungen („Weiß ich nicht“)')
    expect(document.querySelector('.tp-s2')).not.toHaveClass('tp-s2-getrennt')
  })

  it('übersprungen liegt als Punktmuster im Anteil Übungsbedarf, nie als dritter Anteil', () => {
    zeigeStation(Station2, 'uebersprungen')
    alleZeigen()
    const mitMuster = zeilen().filter((z) => z.querySelector('.tp-s2-anteil-ueber'))
    expect(mitMuster.map((z) => z.querySelector('.tp-s2-feld')!.textContent)).toEqual([
      'Geometrie',
      'Prozent & Dreisatz',
      'Terme & Gleichungen',
    ])
    for (const z of zeilen()) {
      expect(within(z).getAllByTestId('tp-s2-anteil').length).toBeLessThanOrEqual(2)
      const muster = z.querySelector('.tp-s2-anteil-ueber')
      if (muster) expect(muster.parentElement).toHaveClass('tp-s2-anteil-uebung')
    }
    const prozent = within(zeile('Prozent & Dreisatz')).getAllByTestId('tp-s2-anteil')[1]
    expect(prozent.style.getPropertyValue('--anteil')).toBe('3')
    expect(prozent.style.getPropertyValue('--ueber')).toBe('1')
  })

  it('kombiniert je Zeile: Übungsbedarf mit übersprungen, „davon 1 übersprungen"', () => {
    zeigeStation(Station2, 'uebersprungen')
    const z = zeile('Prozent & Dreisatz')
    expect(rechts(z)).toBe('1 sicher 3 Übungsbedarf davon 1 übersprungen')
    expect(knopf(z)).toHaveAccessibleName(
      'Prozent & Dreisatz: 4 von 9 untersucht, 1 sicher, 3 mit Übungsbedarf, davon 1 übersprungen. Details anzeigen',
    )
  })

  it('getrennt über die Prop: 11 · 13, „3 übersprungen", neutrales Muster', () => {
    zeigeStation(Station2, 'uebersprungen', { anzeige: 'getrennt' })
    expect(zahl('sicher')).toHaveTextContent('11')
    expect(zahl('uebung').querySelector('strong')).toHaveTextContent('13')
    expect(zahl('ueber')).toHaveTextContent(/^3 übersprungen$/)
    expect(document.querySelector('.tp-s2')).toHaveClass('tp-s2-getrennt')
    const z = zeile('Geometrie')
    expect(rechts(z)).toBe('1 sicher 4 Übungsbedarf 1 übersprungen')
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
  it('alleFelder: vier Zeilen, aufgeklappt acht', () => {
    zeigeStation(Station2, 'alleFelder')
    expect(zeilen()).toHaveLength(4)
    alleZeigen()
    expect(zeilen()).toHaveLength(8)
  })

  it('ohneName: Titel und Erklärsatz ohne Namen', () => {
    zeigeStation(Station2, 'ohneName')
    expect(screen.getByRole('heading', { level: 3 })).toHaveTextContent(/^Kompetenzprofil$/)
    zeigeStation(Station2, 'ilkay')
    expect(screen.getAllByRole('heading', { level: 3 })[1]).toHaveTextContent('Ilkays Kompetenzprofil')
  })

  it('ein Hinweis aufs Antippen, als Caption', () => {
    zeigeStation(Station2, 'ilkay')
    expect(screen.getAllByText(/Antippen/)).toHaveLength(1)
    expect(screen.queryByText(/Jedes Segment/)).toBeNull()
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

  it('je Liste höchstens drei Bereiche, dann „+n weitere" (ilkay Geometrie)', () => {
    zeigeStation(Station2, 'ilkay')
    const spalte = within(zeile('Geometrie')).getByTestId('tp-s2-spalte-uebung')
    const li = within(spalte).getAllByRole('listitem', { hidden: true }).map((l) => l.textContent)
    expect(li).toHaveLength(4)
    expect(li[3]).toBe('+2 weitere')
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
    alleZeigen()
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
