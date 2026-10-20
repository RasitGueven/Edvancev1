// Station 03 · Lernweg (R7-9, Entscheidungen 19–25): derselbe Lernweg wie Seite
// 3, Fahrt nur beim ersten Betreten, Antippen, Ziehen, Pfeiltasten.
import { act, fireEvent, render, screen, within } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { Bausteinsatz } from '@/lib/report/bausteine'
import { PRAESENTATION_FAELLE } from '@/lib/report/praesentation/fixtures'
import { fahrtDauer } from '@/lib/report/praesentation/lernwegFahrt'

import { Station3 } from './Station3'
import { daten } from './testStation34'

const { abgestuft, ilkay, ohneKanten } = PRAESENTATION_FAELLE

let ruhig = false
let sichtbar: ((e: { intersectionRatio: number }[]) => void)[] = []

beforeEach(() => {
  ruhig = false
  sichtbar = []
  vi.stubGlobal('matchMedia', (q: string) => ({ matches: q.includes('reduce') && ruhig, addEventListener() {}, removeEventListener() {} }))
  vi.stubGlobal(
    'IntersectionObserver',
    class {
      constructor(cb: (e: { intersectionRatio: number }[]) => void) {
        sichtbar.push(cb)
      }
      observe(): void {}
      disconnect(): void {}
    },
  )
})
afterEach(() => {
  vi.useRealTimers()
  vi.unstubAllGlobals()
  vi.restoreAllMocks()
})

/** Station 03 in ihrer <section> wie im Rahmen, mit den Klassen der Bewegung. */
function station(fall = abgestuft, klassen = '') {
  const p = daten(fall)
  const r = render(
    <section className={`tp-station ${klassen}`} data-station="3">
      <Station3 p={p} anzeige="kombiniert" satz={new Bausteinsatz([])} sessionId="s" />
    </section>,
  )
  const section = r.container.querySelector('section')!
  const inseln = () => [...r.container.querySelectorAll('.tp-s3-insel')]
  const da = () => inseln().filter((i) => i.classList.contains('tp-s3-da')).length
  return { ...r, p, section, inseln, da, scroller: screen.getByTestId('tp-s3-scroller') }
}

/** Die Klasse entered setzen; der MutationObserver meldet sich als Mikroaufgabe. */
async function betreten(section: HTMLElement): Promise<void> {
  await act(async () => {
    section.classList.add('entered')
  })
}

const knopf = (label: string) => screen.getByRole('button', { name: new RegExp(`^${label}`) })

describe('Station 03 — Inhalt', () => {
  it('Kopf, Satz mit Schulplan, Legende wie im Druck, Infofeld ohne Auswahl', () => {
    station(abgestuft, 'entered motion-complete')
    expect(screen.getByRole('heading', { level: 2 })).toHaveTextContent('Auf vorhandenen Stärken aufbauen.')
    expect(screen.getByText(/was laut Schulplan der Schule Friedrich-Wilhelm-Gymnasium noch kommt/)).toBeInTheDocument()
    const legende = within(screen.getByTestId('tp-s3-legende')).getAllByRole('listitem').map((l) => l.getAttribute('data-legende'))
    expect(legende).toEqual(['sicher', 'uebung', 'offen', 'linie', 'unter', 'broeckelt', 'kommt'])
    expect(screen.getByTestId('tp-s3-info')).toHaveTextContent(
      'Tippen Sie auf einen Bereich, um zu sehen, worauf er aufbaut und was darauf aufbaut.',
    )
  })

  it('derselbe Lernweg wie Seite 3; Kommt noch mit Klasse 10 als eigener Spalte', () => {
    const { container } = station(abgestuft, 'entered motion-complete')
    expect(container.querySelectorAll('[data-zone]')).toHaveLength(4)
    expect(container.querySelector('[data-spalte="kommt-naechste"]')).toHaveTextContent('Klasse 10')
    expect(container.querySelector('[data-zone="kommt"] .tp-s3-zone-klasse')).toHaveTextContent('Klasse 9 und 10, Schulplan')
  })

  it('ilkay: Kernlehrplan, keine Spalte der nächsten Klasse', () => {
    const { container } = station(ilkay, 'entered motion-complete')
    expect(container.querySelector('[data-spalte="kommt-naechste"]')).toBeNull()
    expect(screen.getByText(/was laut Kernlehrplan NRW noch kommt/)).toBeInTheDocument()
  })

  it('keine Ebene, keine Pyramide, kein „trägt“, keine Skill-Schlüssel im DOM', () => {
    const { container } = station(abgestuft, 'entered motion-complete')
    expect(container.textContent).not.toMatch(/tr(ä|ae)gt|Pyramide|Ebene|\bLGS\b/)
    expect(container.innerHTML).not.toMatch(/bruch_dezimal|zahl_wurzel|gleichung_lgs/)
  })
})

describe('Station 03 — Fahrt (Entscheidung 24)', () => {
  beforeEach(() => {
    vi.useFakeTimers({ toFake: ['requestAnimationFrame', 'cancelAnimationFrame', 'performance', 'setTimeout', 'clearTimeout'] })
  })

  it('läuft nur beim ersten Betreten (entered) und endet fertig', async () => {
    const s = station(abgestuft)
    // Vor dem Betreten: nichts aufgedeckt, keine Fahrt.
    expect(s.da()).toBe(0)
    expect(s.scroller.hasAttribute('data-phase')).toBe(false)
    await betreten(s.section)
    act(() => vi.advanceTimersByTime(100))
    expect(s.scroller.getAttribute('data-phase')).toBe('warten')
    // Ohne Maß (jsdom) liegen alle Linien bei x 0: Schieben dauert das Minimum.
    act(() => vi.advanceTimersByTime(fahrtDauer({ start: 0, ende: 0, s: 1, breite: 0, max: 0 }) + 100))
    expect(s.scroller.getAttribute('data-phase')).toBe('fertig')
    expect(s.da()).toBe(s.inseln().length)
  })

  it('bei motion-complete: fertiger Weg, keine Fahrt', () => {
    const s = station(abgestuft, 'entered motion-complete')
    act(() => vi.advanceTimersByTime(3000))
    expect(s.scroller.hasAttribute('data-phase')).toBe(false)
    expect(s.da()).toBe(s.inseln().length)
  })

  it('bei reduzierter Bewegung: fertiger Weg, keine Fahrt, auch nach entered', async () => {
    ruhig = true
    const s = station(abgestuft)
    await betreten(s.section)
    act(() => vi.advanceTimersByTime(3000))
    expect(s.scroller.hasAttribute('data-phase')).toBe(false)
    expect(s.da()).toBe(s.inseln().length)
    expect(s.scroller.scrollLeft).toBe(0)
  })

  it('Antippen während der Fahrt beendet sie: alles steht fertig da', async () => {
    const s = station(abgestuft)
    await betreten(s.section)
    act(() => vi.advanceTimersByTime(2000))
    fireEvent.click(knopf('Bruch in Dezimalzahl'))
    act(() => vi.advanceTimersByTime(20000))
    expect(s.da()).toBe(s.inseln().length)
    expect(s.scroller.getAttribute('data-phase')).not.toBe('fertig') // nicht weitergelaufen
  })

  it('ohneKanten: keine Linien, die Fahrt endet trotzdem bei den Grundlagen', async () => {
    const s = station(ohneKanten)
    expect(s.container.querySelectorAll('.tp-s3-linie')).toHaveLength(0)
    await betreten(s.section)
    act(() => vi.advanceTimersByTime(30000))
    expect(s.scroller.getAttribute('data-phase')).toBe('fertig')
    expect(s.scroller.scrollLeft).toBe(0)
  })
})

describe('Station 03 — Bedienung (Entscheidungen 22 und 25)', () => {
  it('Antippen hebt den Eintrag und alles Verbundene hervor, der Rest wird blass', () => {
    station(abgestuft, 'entered motion-complete')
    const bruch = knopf('Bruch in Dezimalzahl')
    fireEvent.click(bruch)
    expect(bruch).toHaveAttribute('aria-pressed', 'true')
    expect(knopf('Rationale und irrationale Zahlen')).not.toHaveClass('tp-s3-blass')
    expect(knopf('Laplace-Wahrscheinlichkeit')).not.toHaveClass('tp-s3-blass')
    expect(knopf('Einsetzungsverfahren')).toHaveClass('tp-s3-blass')
    expect(screen.getByTestId('tp-s3-info')).toHaveTextContent('Bruch in Dezimalzahl · sicher.')
    expect(screen.getByTestId('tp-s3-info')).toHaveTextContent('Darauf baut auf:')
    // Erneut antippen nimmt es zurück.
    fireEvent.click(bruch)
    expect(bruch).toHaveAttribute('aria-pressed', 'false')
    expect(knopf('Einsetzungsverfahren')).not.toHaveClass('tp-s3-blass')
  })

  it('ein nicht geprüftes Ziel: baut auf, was sitzt; klären wir in den ersten Sitzungen', () => {
    station(abgestuft, 'entered motion-complete')
    fireEvent.click(knopf('Laplace-Wahrscheinlichkeit'))
    expect(screen.getByTestId('tp-s3-info')).toHaveTextContent(
      'Laplace-Wahrscheinlichkeit · noch nicht geprüft. Baut auf Bruch in Dezimalzahl auf, und das sitzt. Das klären wir in den ersten Sitzungen.',
    )
  })

  it('↳ mit zwei Basen hebt beide Verfahren hervor', () => {
    station(abgestuft, 'entered motion-complete')
    fireEvent.click(knopf('Gleichungssysteme aus Sachaufgaben'))
    expect(knopf('Einsetzungsverfahren')).not.toHaveClass('tp-s3-blass')
    expect(knopf('Additionsverfahren')).not.toHaveClass('tp-s3-blass')
    expect(knopf('Gleichungssysteme grafisch lösen')).toHaveClass('tp-s3-blass')
  })

  it('eine Insel in Kommt noch wird klar und zeigt ihren Text', () => {
    const { container } = station(abgestuft, 'entered motion-complete')
    const quad = screen.getByRole('button', { name: 'Quadratische Funktionen' })
    fireEvent.click(quad)
    expect(quad).toHaveAttribute('aria-pressed', 'true')
    expect(quad.closest('.tp-s3-insel')).toHaveClass('tp-s3-klar')
    expect(screen.getByTestId('tp-s3-info')).toHaveTextContent('Quadratische Funktionen · kommt als Nächstes.')
    fireEvent.click(screen.getByRole('button', { name: 'Potenzen und Potenzgesetze' }))
    expect(screen.getByTestId('tp-s3-info')).toHaveTextContent(
      'Potenzen und Potenzgesetze · kommt in Klasse 9. Baut auf, was schon sitzt: Bruch in Dezimalzahl.',
    )
    fireEvent.click(within(container.querySelector('[data-spalte="kommt-naechste"]')!).getByRole('button', { name: 'Ähnlichkeit' }))
    expect(screen.getByTestId('tp-s3-info')).toHaveTextContent('Ähnlichkeit · kommt in Klasse 10.')
  })

  it('Ziehen mit der Maus löst kein Antippen aus', () => {
    const s = station(abgestuft, 'entered motion-complete')
    const bruch = knopf('Bruch in Dezimalzahl')
    fireEvent.pointerDown(s.scroller, { pointerType: 'mouse', clientX: 400 })
    fireEvent.pointerMove(s.scroller, { pointerType: 'mouse', clientX: 330 })
    fireEvent.pointerUp(s.scroller, { pointerType: 'mouse', clientX: 330 })
    fireEvent.click(bruch)
    expect(bruch).toHaveAttribute('aria-pressed', 'false')
  })

  it('← und → wechseln die Zone, solange Station 03 im Bild ist', () => {
    ruhig = true // ohne Gleiten: scrollLeft springt
    // Lage im Entwurf: Spur 1600 breit, Zonen bei 0 / 400 / 800 / 1200.
    vi.spyOn(HTMLElement.prototype, 'offsetWidth', 'get').mockImplementation(function (this: HTMLElement) {
      return this.classList.contains('tp-s3-spur') ? 1600 : 0
    })
    vi.spyOn(HTMLElement.prototype, 'clientHeight', 'get').mockReturnValue(516)
    vi.spyOn(HTMLElement.prototype, 'clientWidth', 'get').mockReturnValue(500)
    vi.spyOn(HTMLElement.prototype, 'scrollWidth', 'get').mockReturnValue(1600)
    const zonen = ['grundlagen', 'weiterfuehrend', 'aktuell', 'kommt']
    vi.spyOn(Element.prototype, 'getBoundingClientRect').mockImplementation(function (this: Element) {
      const z = this.getAttribute('data-zone')
      const x = z ? zonen.indexOf(z) * 400 : this.getAttribute('data-spalte') === 'kommt-naechste' ? 1450 : 0
      const b = this.classList.contains('tp-s3-spur') ? 1600 : 10
      return { left: x, right: x + b, width: b, top: 0, bottom: 10, height: 10, x, y: 0, toJSON: () => ({}) } as DOMRect
    })
    const s = station(abgestuft, 'entered motion-complete')
    act(() => sichtbar.forEach((cb) => cb([{ intersectionRatio: 1 }])))
    fireEvent.keyDown(document, { key: 'ArrowRight' })
    expect(s.scroller.scrollLeft).toBe(400)
    fireEvent.scroll(s.scroller)
    fireEvent.keyDown(document, { key: 'ArrowRight' })
    expect(s.scroller.scrollLeft).toBe(800)
    fireEvent.scroll(s.scroller)
    fireEvent.keyDown(document, { key: 'ArrowLeft' })
    expect(s.scroller.scrollLeft).toBe(400)
    // Außer Bild: Tasten gehören dem Fluss.
    act(() => sichtbar.forEach((cb) => cb([{ intersectionRatio: 0.1 }])))
    fireEvent.scroll(s.scroller)
    fireEvent.keyDown(document, { key: 'ArrowRight' })
    expect(s.scroller.scrollLeft).toBe(400)
  })
})
