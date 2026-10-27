// V4-3: Station 04 Förderansatz — Punkte in Lernpfad-Reihenfolge von links
// unten nach rechts oben, Gruppenpunkt, Sorgfalt-Punkt, fester Kasten, zurück/
// weiter und Pfeiltasten, Ziel-Zeile nur bei bestätigten Zielen.
import { cleanup, fireEvent, screen, within } from '@testing-library/react'
import { afterEach, describe, expect, it } from 'vitest'
import '@/i18n'

import { StationFoerderansatz } from './StationFoerderansatz'
import { lagen } from './foerderPunkte'
import { zeigeV4 } from './testV4'

afterEach(cleanup)

const punkte = (): HTMLElement[] => screen.getAllByRole('tab')
const kasten = (): HTMLElement => screen.getByTestId('tp-s4v-kasten')
const zahl = (el: HTMLElement, name: string): number => Number(el.style.getPropertyValue(name))

/** Vier Lernpfad-Punkte plus Sorgfalt = fünf Punkte (Kernlehrplan-Fall); batuV4 hat drei plus Sorgfalt. */
const FUENF = 'fahrplanKlp'

describe('Station 04 · Punkte auf der Kurve', () => {
  it('batuV4: ein Punkt je Lernpfad-Punkt ohne „später“, dazu Sorgfalt', () => {
    const { v4 } = zeigeV4(StationFoerderansatz, 'batuV4')
    const lernpfad = (v4.bericht.lernpfad ?? []).filter((l) => l.art !== 'spaeter')
    expect(punkte()).toHaveLength(lernpfad.length + 1)
    expect(punkte()).toHaveLength(4)
    expect(punkte()[0]).toHaveAttribute('aria-selected', 'true')
  })

  it('fünf Punkte: Lage steigend von links unten nach rechts oben', () => {
    zeigeV4(StationFoerderansatz, FUENF)
    expect(punkte()).toHaveLength(5)
    expect(punkte()[0]).toHaveAttribute('aria-selected', 'true')
    const x = punkte().map((p) => zahl(p, '--x'))
    const y = punkte().map((p) => zahl(p, '--y'))
    expect(x).toEqual([...x].sort((a, b) => a - b))
    expect(y).toEqual([...y].sort((a, b) => b - a))
    expect(punkte().map((p) => zahl(p, '--anteil'))).toEqual([0.27, 0.47, 0.62, 0.76, 0.9])
    // Beschriftung: erster Punkt darunter, alle weiteren links (oberhalb der steigenden Kurve).
    expect(punkte().map((p) => p.className.match(/tp-s4-seite-(\w+)/)?.[1])).toEqual([
      'unten',
      'linksOben',
      'linksOben',
      'linksOben',
      'linksOben',
    ])
  })

  it('Gruppenpunkt „Grundlagen für …“, Zeile „Klassenarbeit n“, Sorgfalt als letzter, blauer Punkt', () => {
    zeigeV4(StationFoerderansatz, 'batuEigen')
    const namen = punkte().map((p) => p.textContent ?? '')
    expect(namen.some((n) => n.startsWith('Grundlagen für „'))).toBe(true)
    expect(namen[0]).toMatch(/Klassenarbeit \d/)
    const letzter = namen.length - 1
    expect(namen[letzter]).toContain('Sorgfalt')
    expect(namen[letzter]).toContain('in jeder Session')
    expect(punkte()[letzter].className).toContain('tp-s4-punkt-sorgfalt')
    for (const p of punkte().slice(0, letzter)) expect(p.className).not.toContain('tp-s4-punkt-sorgfalt')
  })

  it('weniger Punkte: die Tabelle aus der Anforderung, für n ≤ 4 unverändert', () => {
    expect(lagen(3).map((l) => l.anteil)).toEqual([0.3, 0.6, 0.9])
    expect(lagen(5).map((l) => l.anteil)).toEqual([0.27, 0.47, 0.62, 0.76, 0.9])
  })
})

describe('Station 04 · fester Kasten', () => {
  it('wechselt beim Tippen nur den Inhalt: dasselbe Element, dieselben Klassen und Ids', () => {
    zeigeV4(StationFoerderansatz, FUENF)
    const vorher = kasten()
    const klasse = vorher.className
    const id = vorher.id
    const titel: string[] = [within(vorher).getByRole('heading', { level: 3 }).textContent ?? '']
    for (const i of [1, 2, 3, 4]) {
      fireEvent.click(punkte()[i])
      expect(kasten()).toBe(vorher)
      expect(kasten().className).toBe(klasse)
      expect(kasten().id).toBe(id)
      expect(punkte()[i]).toHaveAttribute('aria-selected', 'true')
      expect(kasten()).toHaveAttribute('aria-labelledby', punkte()[i].id)
      titel.push(within(kasten()).getByRole('heading', { level: 3 }).textContent ?? '')
    }
    expect(new Set(titel).size).toBe(5)
  })

  it('L5, Folge unbekannt (batuV4): Zeile und Pille nennen das Thema, keine Nummer', () => {
    zeigeV4(StationFoerderansatz, 'batuV4')
    const namen = punkte().map((p) => p.textContent ?? '')
    for (const n of namen) expect(n).not.toMatch(/Klassenarbeit \d/)
    expect(namen[0]).toContain('Quadratische Funktionen')
    expect(kasten()).toHaveTextContent('Voraussetzung für „')
    expect(kasten().textContent).not.toMatch(/Klassenarbeit \d/)
  })

  it('zeigt Kicker „Förderfokus n von m“, Pille, Begründung und die zwei Spalten', () => {
    zeigeV4(StationFoerderansatz, 'batuEigen')
    expect(kasten()).toHaveTextContent('Förderfokus 1 von 4')
    expect(kasten()).toHaveTextContent('Voraussetzung für Klassenarbeit')
    expect(within(kasten()).getByTestId('tp-s4v-sitzt')).toHaveTextContent('Sitzt schon')
    expect(within(kasten()).getByTestId('tp-s4v-angehen')).toHaveTextContent('Das gehen wir an')
    // Sorgfalt: Pille „in jeder Session“, keine Bereichslisten.
    fireEvent.click(punkte()[3])
    expect(kasten()).toHaveTextContent('Förderfokus 4 von 4')
    expect(kasten()).toHaveTextContent('in jeder Session')
    expect(within(kasten()).queryByTestId('tp-s4v-angehen')).toBeNull()
    expect(kasten()).toHaveTextContent('Wir üben, die eigene Rechnung zu kontrollieren.')
  })

  it('zurück und weiter wechseln den Punkt, an den Enden gesperrt', () => {
    zeigeV4(StationFoerderansatz, 'batuV4')
    const zurueck = screen.getByRole('button', { name: 'zurück' })
    const weiter = screen.getByRole('button', { name: 'weiter' })
    expect(zurueck).toBeDisabled()
    fireEvent.click(weiter)
    expect(punkte()[1]).toHaveAttribute('aria-selected', 'true')
    expect(kasten()).toHaveTextContent('2 / 4')
    fireEvent.click(zurueck)
    expect(punkte()[0]).toHaveAttribute('aria-selected', 'true')
    for (let i = 0; i < 3; i++) fireEvent.click(weiter)
    expect(punkte()[3]).toHaveAttribute('aria-selected', 'true')
    expect(weiter).toBeDisabled()
  })

  it('Pfeiltasten wechseln den Punkt und führen den Fokus mit', () => {
    zeigeV4(StationFoerderansatz, 'batuV4')
    punkte()[0].focus()
    fireEvent.keyDown(punkte()[0], { key: 'ArrowRight' })
    expect(punkte()[1]).toHaveAttribute('aria-selected', 'true')
    expect(punkte()[1]).toHaveFocus()
    fireEvent.keyDown(punkte()[1], { key: 'ArrowUp' })
    expect(punkte()[2]).toHaveAttribute('aria-selected', 'true')
    fireEvent.keyDown(punkte()[2], { key: 'ArrowLeft' })
    fireEvent.keyDown(punkte()[1], { key: 'ArrowDown' })
    expect(punkte()[0]).toHaveAttribute('aria-selected', 'true')
    fireEvent.keyDown(punkte()[0], { key: 'ArrowLeft' })
    expect(punkte()[0]).toHaveAttribute('aria-selected', 'true')
  })

  it('batuV4: die Lücke im aktuellen Thema heißt wie auf Seite 4 nach ihrem Bereich, nicht nach dem Thema', () => {
    zeigeV4(StationFoerderansatz, 'batuV4')
    const namen = punkte().map((p) => p.textContent ?? '')
    expect(namen.some((n) => n.includes('Teilweise die Wurzel ziehen'))).toBe(true)
    expect(namen.some((n) => n.includes('Reelle Zahlen'))).toBe(false)
  })

  it('Ziel-Zeile nur bei bestätigten Zielen', () => {
    zeigeV4(StationFoerderansatz, 'batuV4', { zieleBestaetigt: false })
    expect(screen.queryByTestId('tp-s4v-ziel')).toBeNull()
    cleanup()
    zeigeV4(StationFoerderansatz, 'batuV4', { zieleBestaetigt: true })
    expect(screen.getByTestId('tp-s4v-ziel')).toHaveTextContent(/^Ziel: .*gut vorbereitet in die Arbeit zu „/)
    fireEvent.click(punkte()[3])
    expect(screen.getByTestId('tp-s4v-ziel')).toHaveTextContent('kontrolliert die eigenen Rechnungen selbst')
  })
})

describe('Station 04 · Empfehlung und Hinweis', () => {
  it('Empfehlung ohne Preis, darunter der Hinweis zum Arbeitsvorschlag', () => {
    zeigeV4(StationFoerderansatz, 'batuV4')
    expect(screen.getByTestId('tp-empfehlung')).toHaveTextContent('Unsere Empfehlung für')
    expect(document.body.textContent).not.toContain('€')
    expect(screen.getByText(/pädagogischer Arbeitsvorschlag/)).toBeInTheDocument()
  })

  it('allesErfuellt: ohne Übungsbedarf nur der Sorgfalt-Punkt bzw. der Hinweis ohne Kurve', () => {
    zeigeV4(StationFoerderansatz, 'allesErfuellt')
    const n = screen.queryAllByRole('tab').length
    expect(n).toBeLessThanOrEqual(5)
    if (n === 0) expect(screen.queryByTestId('tp-s4v-kasten')).toBeNull()
  })
})
