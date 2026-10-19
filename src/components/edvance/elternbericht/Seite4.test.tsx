// Seite 4 des Eltern-Berichts R7 (Lernplan als Kurve) für die Fixture-Fälle.
import { render } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { Seite4 } from '@/components/edvance/elternbericht/Seite4'
import type { SeitenProps } from '@/components/edvance/elternbericht/seitenProps'
import { Bausteinsatz } from '@/lib/report/bausteine'
import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import { FAELLE, NOTIZEN } from '@/lib/report/elternbericht/fixtures'
import type { EbSchwerpunkt, Elternbericht, ReportData, ReportFehlbild } from '@/types'

function props(
  data: ReportData,
  anpassen: (b: Elternbericht) => Partial<Elternbericht> = () => ({}),
  notes = NOTIZEN,
): SeitenProps {
  const { kompetenzen, katalog, bausteine } = data.erzaehlung
  const bericht = baueElternbericht({ kompetenzen, katalog, klasse: data.grade })!
  const name = data.firstName?.trim() || null
  return {
    data,
    bericht: { ...bericht, ...anpassen(bericht) },
    satz: new Bausteinsatz(bausteine),
    notes,
    tiers: [],
    name,
    wessen: name ? `${name}s` : null,
  }
}

const seite4 = (p: SeitenProps) => render(<Seite4 {...p} />)

const familie = (familie: string, text: string, anzahl: number): ReportFehlbild => ({
  slug: `${familie}-slug`,
  familie,
  familieElterntext: text,
  anzahl,
  aufgaben: 2,
  skills: [`${familie}-a`],
  skillUebergreifend: false,
  einstufung: 'befund',
})

const mitFehlbildern = (fehlbilder: ReportFehlbild[]): ReportData => ({
  ...FAELLE.ilkay.data,
  fehlbilder,
})

const COACH = 'Der Coach prüft in den ersten Sitzungen, ob sich das bestätigt.'

describe('Seite 4 — Fazit', () => {
  it('ohne Elterntext: kein Kicker, kein Kasten, der Titel rückt nach oben', () => {
    const { container, queryByTestId } = seite4(props(FAELLE.ilkay.data))
    expect(queryByTestId('eb-fazit')).toBeNull()
    expect(container.querySelector('.eb-s4')!.firstElementChild).toHaveClass('eb-s4-titel')
  })

  it('ein Elterntext: wörtlich, danach der Satz zum Coach', () => {
    const { getByTestId } = seite4(props(mitFehlbildern([familie('richtung', 'Satz A.', 3)])))
    expect(getByTestId('eb-fazit')).toHaveTextContent('Unser Fazit')
    expect(getByTestId('eb-fazit').querySelector('.eb-s4-fazit')).toHaveTextContent(`Satz A. ${COACH}`)
  })

  it('drei Elterntexte: nur die ersten zwei (nach Vorkommen), nie der Familienschlüssel', () => {
    const { getByTestId } = seite4(
      props(
        mitFehlbildern([
          familie('drei', 'Satz C.', 2),
          familie('eins', 'Satz A.', 5),
          familie('zwei', 'Satz B.', 4),
        ]),
      ),
    )
    const text = getByTestId('eb-fazit').querySelector('.eb-s4-fazit')!
    expect(text).toHaveTextContent(`Satz A. Satz B. ${COACH}`)
    expect(text.textContent).not.toMatch(/Satz C|eins|zwei|drei/)
  })
})

describe('Seite 4 — Titel und Schwerpunkte', () => {
  const titel = (n: number): string => {
    const p = props(FAELLE.ilkay.data, (b) => ({ schwerpunkte: b.schwerpunkte.slice(0, n) }))
    const { getByRole, unmount, container } = seite4(p)
    const t = getByRole('heading', { level: 1 }).textContent ?? ''
    const hinweis = container.querySelector('.eb-s4-hinweis') !== null
    unmount()
    return `${t}${hinweis ? ' +' : ''}`
  }

  it('Titel je Anzahl, der Reihenfolge-Hinweis ab zwei', () => {
    expect([1, 2, 3, 4].map(titel)).toEqual([
      'Ein Schwerpunkt.',
      'Zwei Schwerpunkte, in dieser Reihenfolge. +',
      'Drei Schwerpunkte, in dieser Reihenfolge. +',
      'Vier Schwerpunkte, in dieser Reihenfolge. +',
    ])
  })

  it('Titel ist das Themenfeld, Text nennt Sicheres nur, wenn es das gibt', () => {
    const { container } = seite4(props(FAELLE.klasse10neu.data))
    const punkte = [...container.querySelectorAll('.eb-s4-punkt')]
    expect(punkte.map((p) => p.querySelector('h3')!.textContent)).toEqual([
      'Brüche & Dezimalzahlen',
      'Prozent & Dreisatz',
      'Terme & Gleichungen',
      'Geometrie',
    ])
    expect(punkte[0].querySelector('.eb-s4-punkt-text')!.textContent).toMatch(/^Sicher: .+\. Noch nicht sicher: .+\.$/)
    expect(punkte[2].querySelector('.eb-s4-punkt-text')!.textContent).toMatch(/^Noch nicht sicher: /)
  })

  const mitListe = (uebung: string[]): string => {
    const sp: EbSchwerpunkt = { feld: 'geometrie', gemischt: false, sicher: [], uebung }
    const { container, unmount } = seite4(props(FAELLE.ilkay.data, () => ({ schwerpunkte: [sp], danach: [] })))
    const text = container.querySelector('.eb-s4-punkt-text')!.textContent ?? ''
    unmount()
    return text
  }

  it('Listen: bis drei Labels als Aufzählung, mehr als „A, B, C und n weitere“', () => {
    expect(mitListe(['A', 'B', 'C'])).toBe('Noch nicht sicher: A, B und C.')
    expect(mitListe(['A', 'B', 'C', 'D', 'E'])).toBe('Noch nicht sicher: A, B, C und 2 weitere.')
    expect(mitListe(['A', 'B', 'C', 'D'])).toBe('Noch nicht sicher: A, B, C und ein weiterer.')
  })

  it('mehr als vier Felder mit Übungsbedarf: „Danach …“ unter dem letzten', () => {
    const { container } = seite4(props(FAELLE.alleFelder.data))
    const danach = container.querySelector('.eb-s4-danach')!
    expect(danach.closest('.eb-s4-punkt')).toBe(container.querySelector('.eb-s4-punkt:last-child'))
    expect(danach).toHaveTextContent(
      'Danach nehmen wir Terme & Gleichungen, Zahlen & Rechnen, Funktionen und ein weiterer dazu.',
    )
    expect(seite4(props(FAELLE.klasse10neu.data)).container.querySelector('.eb-s4-danach')).toBeNull()
  })

  it('kein Schwerpunkt: eigener Titel, der Baustein fazit/keine, keine Kurve', () => {
    const { getByRole, container } = seite4(props(FAELLE.allesSicher.data))
    expect(getByRole('heading', { level: 1 })).toHaveTextContent(
      'Kein Übungsbedarf in den untersuchten Bereichen.',
    )
    const keine = FAELLE.allesSicher.data.erzaehlung.bausteine
      .filter((b) => b.slot === 'fazit' && b.fall === 'keine')
      .map((b) => b.text)
    expect(keine).toContain(container.querySelector('.eb-s4-keine')!.textContent)
    expect(container.querySelector('.eb-s4-liste')).toBeNull()
    expect(container.querySelector('.eb-s4-hinweis')).toBeNull()
  })
})

describe('Seite 4 — Lernziel und Fußnote', () => {
  it('Lernziel mit erhaltenen Zeilenumbrüchen, Fußnote immer', () => {
    const notes = { ...NOTIZEN, zielbild: 'Erste Zeile.\nZweite Zeile.' }
    const { getByTestId, container } = seite4(props(FAELLE.ilkay.data, undefined, notes))
    expect(getByTestId('eb-lernziel')).toHaveTextContent('Unser gemeinsames Lernziel')
    expect(getByTestId('eb-lernziel').querySelector('.eb-s4-lernziel-text')!.textContent).toBe(
      'Erste Zeile.\nZweite Zeile.',
    )
    expect(container.querySelector('.eb-s4-stand')).toHaveTextContent(/^Das ist der Stand nach dieser Analyse\./)
  })

  it('ohne Zielbild entfällt der Kasten', () => {
    const leer = seite4(props(FAELLE.ilkay.data, undefined, { ...NOTIZEN, zielbild: '  ' }))
    expect(leer.queryByTestId('eb-lernziel')).toBeNull()
    expect(leer.container.querySelector('.eb-s4-stand')).not.toBeNull()
    const ohne = render(<Seite4 {...{ ...props(FAELLE.ilkay.data), notes: null }} />)
    expect(ohne.queryByTestId('eb-lernziel')).toBeNull()
  })
})

describe('Seite 4 — Kurve', () => {
  afterEach(() => vi.restoreAllMocks())

  /** jsdom hat kein Layout: 507 pt breit, Titel und Kasten je 100 px tiefer. */
  function mitLayout(): void {
    let y = 0
    vi.spyOn(HTMLElement.prototype, 'getBoundingClientRect').mockImplementation(function (this: HTMLElement) {
      const top = this.classList.contains('eb-s4') ? 0 : (y += 100)
      return { top, bottom: top, left: 0, right: 676, width: 676, height: 0, x: 0, y: top } as DOMRect
    })
  }

  it('je Schwerpunkt ein Knoten, mit Lernziel Auslauf und Spitze', () => {
    mitLayout()
    const { getByTestId } = seite4(props(FAELLE.ilkay.data))
    const kurve = getByTestId('eb-kurve')
    expect(kurve).toHaveAttribute('aria-hidden', 'true')
    expect(kurve.querySelectorAll('circle')).toHaveLength(4)
    expect(kurve.querySelectorAll('.eb-s4-pfad')).toHaveLength(2)
    expect(kurve.querySelector('.eb-s4-spitze')).not.toBeNull()
    expect(kurve.textContent).toBe('')
  })

  it('ohne Lernziel endet die Kurve am letzten Knoten, ohne Spitze', () => {
    mitLayout()
    const { getByTestId } = seite4({ ...props(FAELLE.ilkay.data), notes: null })
    expect(getByTestId('eb-kurve').querySelectorAll('.eb-s4-pfad')).toHaveLength(1)
    expect(getByTestId('eb-kurve').querySelector('.eb-s4-spitze')).toBeNull()
  })

  it('ohne Schwerpunkt keine Kurve', () => {
    mitLayout()
    expect(seite4(props(FAELLE.allesSicher.data)).queryByTestId('eb-kurve')).toBeNull()
  })
})

describe('Seite 4 — Verdichtung bei Überlauf', () => {
  afterEach(() => vi.restoreAllMocks())

  it('läuft der Inhaltskasten über, rückt die Seite enger zusammen; sonst nicht', () => {
    const inBogen = (ueber: boolean) => {
      vi.spyOn(HTMLElement.prototype, 'scrollHeight', 'get').mockReturnValue(ueber ? 977 : 960)
      vi.spyOn(HTMLElement.prototype, 'clientHeight', 'get').mockReturnValue(960)
      const { container, unmount } = render(
        <div className="eb-inhalt">
          <Seite4 {...props(FAELLE.ilkay.data)} />
        </div>,
      )
      const dicht = container.querySelector('.eb-s4')!.hasAttribute('data-dicht')
      unmount()
      vi.restoreAllMocks()
      return dicht
    }
    expect(inBogen(false)).toBe(false)
    expect(inBogen(true)).toBe(true)
  })
})
