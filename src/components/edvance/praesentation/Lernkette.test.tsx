// Station 03 · die Kette (PS-1, Entscheidungen 10–15): Standardansicht, Umschalten
// auf die volle Karte und zurück, Satz beim Antippen, reduzierte Bewegung.
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'

import { fireEvent, render, screen } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { Bausteinsatz } from '@/lib/report/bausteine'
import { PRAESENTATION_FAELLE } from '@/lib/report/praesentation/fixtures'

import { Station3 } from './Station3'
import { daten } from './testStation34'

const F = PRAESENTATION_FAELLE

beforeEach(() => {
  vi.stubGlobal('matchMedia', () => ({ matches: false, addEventListener() {}, removeEventListener() {} }))
  vi.stubGlobal(
    'IntersectionObserver',
    class {
      observe(): void {}
      disconnect(): void {}
    },
  )
})
afterEach(() => {
  vi.unstubAllGlobals()
})

function station(fall: string, klassen = 'entered motion-complete') {
  return render(
    <section className={`tp-station ${klassen}`} data-station="3">
      <Station3 p={daten(F[fall])} anzeige="kombiniert" satz={new Bausteinsatz([])} sessionId="s" />
    </section>,
  )
}

const glieder = (): HTMLElement[] => screen.queryAllByTestId('tp-s3-glied')
const arten = (): (string | null)[] => glieder().map((g) => g.getAttribute('data-art'))
const info = (): HTMLElement => screen.getByTestId('tp-s3-kette-info')

describe('Station 03 — Kette ist Standard', () => {
  it('abgestuft: „Der Weg zum Thema." mit Sitzt schon → Hier hakt es → Baut darauf auf → Ihr Thema', () => {
    station('abgestuft')
    expect(screen.getByRole('heading', { level: 2 })).toHaveTextContent('Der Weg zum Thema.')
    expect(screen.getByTestId('tp-s3-kette')).toHaveAttribute('data-fall', 'thema')
    expect(screen.queryByTestId('tp-s3-scroller')).toBeNull()
    expect(glieder().map((g) => g.textContent)).toEqual([
      'Sitzt schonBruch in Dezimalzahl',
      'Hier hakt esWurzelgesetze für Produkt und Quotient',
      'Baut darauf aufTeilweise die Wurzel ziehen',
      'Ihr ThemaReelle Zahlen',
    ])
    expect(screen.getByRole('list')).toHaveAccessibleName('Der Weg zum Thema.')
  })

  it('ohne Thema (ilkay): der erste Schwerpunkt bis zum Themenfeld, dann das nächste Thema', () => {
    station('ilkay')
    expect(screen.getByRole('heading', { level: 2 })).toHaveTextContent('Der Weg zum Themenfeld.')
    expect(arten()).toEqual(['basis', 'start', 'feld', 'kommt'])
    expect(glieder()[2]).toHaveTextContent('ThemenfeldGeometrie')
    expect(glieder()[3]).toHaveTextContent('Kommt als NächstesAlgebra & Funktionen')
    expect(glieder()[3]).toHaveClass('tp-s3-glied-kommt')
  })

  it('Thema ohne Übungsbedarf (abgestuftThemaSicher): „Ihr Thema · sitzt"', () => {
    station('abgestuftThemaSicher')
    expect(arten()).toEqual(['themaSitzt'])
    expect(glieder()[0]).toHaveTextContent('Ihr Thema · sitztReelle Zahlen')
  })

  it('ohne Schwerpunkt und ohne Thema (allesSicher): die volle Karte wie bisher, kein Umschalter', () => {
    station('allesSicher')
    expect(screen.queryByTestId('tp-s3-kette')).toBeNull()
    expect(screen.getByTestId('tp-s3-scroller')).toBeInTheDocument()
    expect(screen.queryByTestId('tp-s3-ganz')).toBeNull()
    expect(screen.getByRole('heading', { level: 2 })).toHaveTextContent('Auf vorhandenen Stärken aufbauen.')
  })

  it.each(Object.keys(F).filter((f) => f !== 'ohneKatalog'))('%s: höchstens fünf Kästen, keine Unterpunkte', (fall) => {
    station(fall)
    expect(glieder().length).toBeLessThanOrEqual(5)
    for (const g of glieder()) expect(g.querySelectorAll('ul, li')).toHaveLength(0)
    // Inline-Styles nur für die berechneten Lagen (--glieder, --glied).
    const kette = screen.queryByTestId('tp-s3-kette')
    for (const el of kette ? [kette, ...kette.querySelectorAll<HTMLElement>('[style]')] : [])
      expect(el.getAttribute('style')).toMatch(/^--glied(er)?: \d+;?$/)
  })
})

describe('Station 03 — Umschalten', () => {
  it('„Ganzen Lernweg zeigen" öffnet die Bühne in derselben Station, „Zurück zum Weg" schließt sie', () => {
    station('abgestuft')
    fireEvent.click(screen.getByTestId('tp-s3-ganz'))
    expect(screen.queryByTestId('tp-s3-kette')).toBeNull()
    expect(screen.getByTestId('tp-s3-scroller')).toBeInTheDocument()
    expect(screen.getByTestId('tp-s3-legende')).toBeInTheDocument()
    const zurueck = screen.getByTestId('tp-s3-zurueck')
    expect(zurueck).toHaveTextContent('Zurück zum Weg')
    expect(document.activeElement).toBe(zurueck)

    fireEvent.click(zurueck)
    expect(screen.queryByTestId('tp-s3-scroller')).toBeNull()
    // Zurück ohne zweiten Aufbau.
    expect(screen.getByTestId('tp-s3-kette')).toHaveClass('tp-s3-kette-still')
    expect(document.activeElement).toBe(screen.getByTestId('tp-s3-ganz'))
  })

  it('beim ersten Betreten baut sich die Kette auf (nicht still)', () => {
    station('abgestuft', 'entered')
    expect(screen.getByTestId('tp-s3-kette')).not.toHaveClass('tp-s3-kette-still')
  })
})

describe('Station 03 — Antippen', () => {
  it('vorher steht der eine Hinweis als Caption', () => {
    station('abgestuft')
    expect(info()).toHaveTextContent(/^Tippen Sie auf einen Bereich/)
    expect(screen.getAllByText(/Tippen Sie/)).toHaveLength(1)
  })

  it('Hier hakt es: Stand und was darauf aufbaut, aus den Infotexten des Lernwegs', () => {
    station('abgestuft')
    fireEvent.click(glieder()[1])
    expect(glieder()[1]).toHaveAttribute('aria-pressed', 'true')
    expect(info()).toHaveTextContent(
      'Wurzelgesetze für Produkt und Quotient · Übungsbedarf. Darauf baut auf: Teilweise die Wurzel ziehen.',
    )
    fireEvent.click(glieder()[1])
    expect(info()).toHaveTextContent(/^Tippen Sie/)
  })

  it('Baut darauf auf, Ihr Thema, Kommt als Nächstes, Themenfeld', () => {
    station('abgestuft')
    fireEvent.click(glieder()[2])
    expect(info()).toHaveTextContent('Baut direkt auf Wurzelgesetze für Produkt und Quotient auf.')
    fireEvent.click(glieder()[3])
    expect(info()).toHaveTextContent('Reelle Zahlen Darauf arbeiten wir hin.')
    station('ilkay')
    const ilkay = screen.getAllByTestId('tp-s3-kette')[1]
    const [, , feld, kommt] = [...ilkay.querySelectorAll<HTMLElement>('[data-testid="tp-s3-glied"]')]
    fireEvent.click(kommt)
    expect(ilkay.querySelector('[data-testid="tp-s3-kette-info"]')).toHaveTextContent(
      'Algebra & Funktionen · kommt als Nächstes.',
    )
    fireEvent.click(feld)
    expect(ilkay.querySelector('[data-testid="tp-s3-kette-info"]')).toHaveTextContent(
      'Geometrie Die Bereiche davor gehören zu diesem Themenfeld.',
    )
  })
})

describe('Station 03 — Bewegung (station3-kette.css)', () => {
  const css = readFileSync(resolve(__dirname, '../../../styles/praesentation/station3-kette.css'), 'utf8')

  it('Kästen nacheinander je 250 ms, die Linie danach in höchstens 1,2 s', () => {
    expect(css).toMatch(/--tp-kette-takt: 250ms;/)
    const linie = Number(css.match(/--tp-kette-linie: (\d+)ms;/)?.[1])
    expect(linie).toBeLessThanOrEqual(1200)
    expect(css).toMatch(/var\(--tp-kette-start\) \+ var\(--glieder\) \* var\(--tp-kette-takt\)/)
  })

  it('bei reduzierter Bewegung steht alles sofort', () => {
    const ruhig = css.slice(css.indexOf('@media (prefers-reduced-motion: reduce)'))
    expect(ruhig).toMatch(/\.tp-s3-kette-platz,\s*\.tp \.tp-s3-kette-linie\s*\{\s*animation: none !important;\s*opacity: 1 !important;\s*transform: none !important;/)
  })

  it('Touch-Ziele mindestens 44 px', () => {
    expect(css).toMatch(/\.tp-s3-umschalten \{[^}]*min-height: 44px;/)
    const glied = Number(css.match(/\.tp \.tp-s3-glied \{[^}]*min-height: (\d+)px;/)?.[1])
    expect(glied).toBeGreaterThanOrEqual(44)
  })
})
