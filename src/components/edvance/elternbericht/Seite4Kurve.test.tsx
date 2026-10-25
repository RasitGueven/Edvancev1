// Seite 4 des Eltern-Berichts (Bericht v3): Kurve und Verdichtung bei Überlauf.
import { render } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { NamensMessungFertig } from '@/components/edvance/elternbericht/namensMessung'
import { Seite4 } from '@/components/edvance/elternbericht/Seite4'
import type { SeitenProps } from '@/components/edvance/elternbericht/seitenProps'
import { Bausteinsatz } from '@/lib/report/bausteine'
import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import { FAELLE, NOTIZEN } from '@/lib/report/elternbericht/fixtures'
import type { Elternbericht, KlassenarbeitStatus, ReportData, ReportFehlbild } from '@/types'

function props(
  data: ReportData,
  anpassen: (b: Elternbericht) => Partial<Elternbericht> = () => ({}),
  notes = NOTIZEN,
  klassenarbeit: KlassenarbeitStatus | null = null,
): SeitenProps {
  const { kompetenzen, katalog, bausteine } = data.erzaehlung
  const bericht = baueElternbericht({
    kompetenzen,
    katalog,
    klasse: data.grade,
    lernweg: { erzaehlung: data.erzaehlung, datum: data.analysedAt },
    klassenarbeit,
  })!
  const name = data.firstName?.trim() || null
  return {
    data,
    bericht: { ...bericht, ...anpassen(bericht) },
    satz: new Bausteinsatz(bausteine),
    notes,
    tiers: [],
    name,
    vollerName: name,
    wessen: name ? `${name}s` : null,
  }
}

const seite4 = (p: SeitenProps) => render(<Seite4 {...p} />)

const familie = (familie: string, text: string | null, aufgaben: number): ReportFehlbild => ({
  slug: `${familie}-slug`,
  familie,
  familieElterntext: text,
  anzahl: aufgaben,
  aufgaben,
  skills: [`${familie}-a`],
  skillUebergreifend: false,
  einstufung: 'befund',
})

const mitFehlbildern = (fehlbilder: ReportFehlbild[]): ReportData => ({
  ...FAELLE.ilkay.data,
  fehlbilder,
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

  it('je Schwerpunkt ein Knoten, die Kurve endet am letzten Knoten (ein Pfad, keine Spitze)', () => {
    mitLayout()
    const { getByTestId } = seite4(props(FAELLE.ilkay.data))
    const kurve = getByTestId('eb-kurve')
    expect(kurve).toHaveAttribute('aria-hidden', 'true')
    expect(kurve.querySelectorAll('circle')).toHaveLength(4)
    expect(kurve.querySelectorAll('.eb-s4-pfad')).toHaveLength(1)
    expect(kurve.querySelector('.eb-s4-spitze')).toBeNull()
    expect(kurve.textContent).toBe('')
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

  /**
   * „Gemessene“ Höhe: Der Kasten läuft über, solange das Fazit länger als
   * `grenze` Zeichen ist. Die Verdichtung allein ändert den Text nicht.
   */
  const stufe = (fehlbilder: ReportFehlbild[], grenze: number) => {
    vi.spyOn(HTMLElement.prototype, 'scrollHeight', 'get').mockImplementation(function (this: HTMLElement) {
      return (this.querySelector('.eb-s4-fazit')?.textContent ?? '').length > grenze ? 977 : 960
    })
    vi.spyOn(HTMLElement.prototype, 'clientHeight', 'get').mockReturnValue(960)
    const { container, unmount } = render(
      <div className="eb-inhalt">
        <Seite4 {...props(mitFehlbildern(fehlbilder))} />
      </div>,
    )
    const s4 = container.querySelector('.eb-s4')!
    const ergebnis = {
      stufe: s4.getAttribute('data-stufe'),
      dicht: s4.hasAttribute('data-dicht'),
      fazit: s4.querySelector('.eb-s4-fazit')!.textContent,
    }
    unmount()
    vi.restoreAllMocks()
    return ergebnis
  }
  // Das Fehlermuster mit Text der häufigsten Familie (Sorgfalt ist hier nicht gedeckt).
  const lang = [familie('eins', 'Ihr Kind liest ungenau und ein langer Satz folgt hier.', 5)]

  it('läuft der Kasten wegen des Musters über, rückt die Seite eine Stufe zusammen und bleibt dabei', () => {
    expect(stufe(lang, 1000)).toMatchObject({ stufe: null, dicht: false })
    const ueber = stufe(lang, 0)
    expect(ueber).toMatchObject({ stufe: '1', dicht: true })
    // Text wird nie gekürzt, nur verdichtet.
    expect(ueber.fazit).toBe('Ilkay liest ungenau und ein langer Satz folgt hier.')
  })

  it('misst erst, wenn der Bogen über den Namen entschieden hat', () => {
    vi.spyOn(HTMLElement.prototype, 'scrollHeight', 'get').mockReturnValue(977)
    vi.spyOn(HTMLElement.prototype, 'clientHeight', 'get').mockReturnValue(960)
    const { container } = render(
      <NamensMessungFertig.Provider value={false}>
        <div className="eb-inhalt">
          <Seite4 {...props(mitFehlbildern(lang))} />
        </div>
      </NamensMessungFertig.Provider>,
    )
    expect(container.querySelector('.eb-s4')!.hasAttribute('data-stufe')).toBe(false)
    vi.restoreAllMocks()
  })
})
