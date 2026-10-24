// Seite 4 des Eltern-Berichts (Bericht v2): Fehlermuster, Schwerpunkte mit Grund, Kurve.
import { render } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { NamensMessungFertig } from '@/components/edvance/elternbericht/namensMessung'
import { Seite4 } from '@/components/edvance/elternbericht/Seite4'
import type { SeitenProps } from '@/components/edvance/elternbericht/seitenProps'
import { Bausteinsatz } from '@/lib/report/bausteine'
import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import de from '@/i18n/locales/de/elternbericht.json'
import { FAELLE, NOTIZEN } from '@/lib/report/elternbericht/fixtures'
import type { EbSchwerpunkt, Elternbericht, KlassenarbeitStatus, ReportData, ReportFehlbild } from '@/types'

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

const COACH = de.s4.coach

describe('Seite 4 — Fehlermuster', () => {
  const kicker = (c: HTMLElement): string | undefined => c.querySelector('.eb-s4-kicker')?.textContent ?? undefined

  it('ohne Fehlbilder: keine Überschrift „Fehlermuster“, kein Kasten, der Titel rückt nach oben', () => {
    const { container, queryByTestId } = seite4(props(FAELLE.ilkay.data))
    expect(queryByTestId('eb-fazit')).toBeNull()
    expect(container.textContent).not.toContain('Fehlermuster')
    expect(container.querySelector('.eb-s4')!.firstElementChild).toHaveClass('eb-s4-titel')
  })

  it('Sorgfalt gedeckt: Überschrift und fester Satz', () => {
    const { getByTestId, container } = seite4(props(mitFehlbildern([familie('vorzeichen', 'Egal.', 3)])))
    expect(kicker(container)).toBe('Fehlermuster')
    expect(getByTestId('eb-fazit').querySelector('.eb-s4-fazit')?.textContent).toBe(
      de.s4.muster.sorgfalt.replace('{{sorgfalt}}', '3').replace('{{eingeordnet}}', '3'),
    )
  })

  it('Sorgfalt nicht gedeckt, aber eindeutig häufigste Familie: ihr abgenommener Text mit Vornamen statt „Ihr Kind“', () => {
    const { getByTestId } = seite4(
      props(mitFehlbildern([familie('sachaufgaben', 'Ihr Kind liest die Aufgabe ungenau.', 4), familie('rest', 'Anderes.', 2)])),
    )
    expect(getByTestId('eb-fazit').querySelector('.eb-s4-fazit')?.textContent).toBe('Ilkay liest die Aufgabe ungenau.')
  })

  it('ohne Namen bleibt „Ihr Kind“ stehen', () => {
    const p = { ...props(mitFehlbildern([familie('sachaufgaben', 'Ihr Kind liest ungenau.', 4)])), name: null }
    expect(seite4(p).getByTestId('eb-fazit')).toHaveTextContent('Ihr Kind liest ungenau.')
  })

  it('Gleichstand der Familien, nur eine Aufgabe oder kein freigegebener Text: gar kein Muster', () => {
    for (const f of [
      [familie('a', 'Text A.', 3), familie('b', 'Text B.', 3)],
      [familie('a', 'Text A.', 1)],
      [familie('a', null, 5)],
    ]) {
      const { queryByTestId, container, unmount } = seite4(props(mitFehlbildern(f)))
      expect(queryByTestId('eb-fazit')).toBeNull()
      expect(container.textContent).not.toContain('Fehlermuster')
      unmount()
    }
  })

  it('nie ein Familienschlüssel im Text', () => {
    const { container } = seite4(props(mitFehlbildern([familie('schritt_vergessen', 'T.', 4)])))
    expect(container.textContent).not.toMatch(/schritt_vergessen/)
  })
})

describe('Seite 4 — Grund je Schwerpunkt und Coach-Satz', () => {
  it('jeder Schwerpunkt nennt „weil …“ aus den Daten', () => {
    const { container } = seite4(props(FAELLE.ilkay.data))
    const gruende = [...container.querySelectorAll('.eb-s4-grund-text')].map((g) => g.textContent)
    expect(gruende).toEqual([
      'weil hier schon Stoff aus Klasse 5/6 Übung braucht',
      'weil hier schon Stoff aus Klasse 5/6 Übung braucht',
      'weil hier schon Stoff aus Klasse 5/6 Übung braucht',
      'weil hier 3 Bereiche Übungsbedarf zeigen',
    ])
  })

  it('Thema-Schwerpunkt: Grund nach dem Stand der Klassenarbeit', () => {
    const grund = (k: KlassenarbeitStatus | null): string | null | undefined =>
      seite4(props(FAELLE.abgestuft.data, undefined, NOTIZEN, k)).container.querySelector('.eb-s4-grund-text')?.textContent
    expect(grund(null)).toBe('weil es das aktuelle Schulthema ist')
    expect(grund('bevorstehend')).toBe('weil die Klassenarbeit zu diesem Thema bevorsteht')
    expect(grund('geschrieben')).toBe('weil im aktuellen Schulthema noch eine Lücke offen ist')
  })

  it('Klassenarbeit „geschrieben“: Felder mit kommendem Schulthema zuerst, das Thema danach', () => {
    const titel = (k: KlassenarbeitStatus | null): (string | null)[] =>
      [...seite4(props(FAELLE.abgestuftPlanrang.data, undefined, NOTIZEN, k)).container.querySelectorAll('.eb-s4-punkt-titel')].map(
        (t) => t.textContent,
      )
    expect(titel('bevorstehend')[0]).toBe('Reelle ZahlenAktuelles Thema')
    expect(titel(null)[0]).toBe('Reelle ZahlenAktuelles Thema')
    const nach = titel('geschrieben')
    expect(nach[0]).toBe('Geometrie')
    expect(nach[1]).toBe('Reelle ZahlenAktuelles Thema')
    expect(nach.slice().sort()).toEqual(titel(null).slice().sort())
  })

  it('Feld mit kommendem Thema nennt dieses als Grund', () => {
    const { container } = seite4(props(FAELLE.abgestuftPlanrang.data, undefined, NOTIZEN, 'geschrieben'))
    expect(container.querySelector('.eb-s4-grund-text')?.textContent).toMatch(/^weil das kommende Schulthema .+ darauf aufbaut$/)
  })

  it('der Coach-Satz steht genau einmal, in der Fußnote', () => {
    const { container } = seite4(props(FAELLE.ilkay.data))
    expect(container.querySelector('.eb-s4-stand')?.textContent).toBe(COACH)
    expect(container.textContent!.split(COACH)).toHaveLength(2)
  })

  it('auch ohne Schwerpunkt steht der Coach-Satz, bündig an der Inhaltskante', () => {
    const { container } = seite4(props(FAELLE.allesSicher.data))
    expect(container.querySelector('.eb-s4-stand')).toHaveClass('eb-s4-stand', 'eb-s4-stand-voll')
    expect(container.querySelector('.eb-s4-stand')?.textContent).toBe(COACH)
  })

  it('mit Schwerpunkten ist die Fußnote nicht „voll“', () => {
    expect(seite4(props(FAELLE.ilkay.data)).container.querySelector('.eb-s4-stand')).not.toHaveClass('eb-s4-stand-voll')
  })

  it('kein Lernziel-Kasten mehr auf Seite 4, auch nicht mit Zielbild in den Notizen', () => {
    const notes = { ...NOTIZEN, zielbild: 'Erste Zeile.\nZweite Zeile.' }
    const { queryByTestId, container } = seite4(props(FAELLE.ilkay.data, undefined, notes))
    expect(queryByTestId('eb-lernziel')).toBeNull()
    expect(container.textContent).not.toMatch(/Erste Zeile|Lernziel/)
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

  // Geometrie fehlt hier mit Absicht: dort liegt nur Übungsbedarf bei Vorgriffen (LSA-V2), der nicht zählt.
  it('Titel ist das Themenfeld, Text nennt Sicheres nur, wenn es das gibt', () => {
    const { container } = seite4(props(FAELLE.klasse10neu.data))
    const punkte = [...container.querySelectorAll('.eb-s4-punkt')]
    expect(punkte.map((p) => p.querySelector('h3')!.textContent)).toEqual([
      'Brüche & Dezimalzahlen',
      'Prozent & Dreisatz',
      'Terme & Gleichungen',
    ])
    expect(punkte[0].querySelector('.eb-s4-punkt-text')!.textContent).toMatch(/^Sicher: .+\. Noch nicht sicher: .+\.$/)
    expect(punkte[2].querySelector('.eb-s4-punkt-text')!.textContent).toMatch(/^Noch nicht sicher: /)
  })

  const mitListe = (uebung: string[]): string => {
    const sp: EbSchwerpunkt = { feld: 'geometrie', thema: null, gemischt: false, sicher: [], uebung, start: null, naechster: null }
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

describe('Seite 4 — Thema-Schwerpunkt (R7-11)', () => {
  const titel = (c: HTMLElement): (string | null)[] => [...c.querySelectorAll('.eb-s4-punkt-titel')].map((t) => t.textContent)

  it('abgestuft: Reelle Zahlen an Platz 1 mit Schild, Geometrie nicht vorn', () => {
    const { container, getAllByTestId } = seite4(props(FAELLE.abgestuft.data))
    expect(titel(container).slice(0, 2)).toEqual(['Reelle ZahlenAktuelles Thema', 'Terme & Gleichungen'])
    expect(getAllByTestId('eb-s4-chip-thema')).toHaveLength(1)
  })

  it('abgestuftThemaSicher: das Thema ist kein Schwerpunkt, kein Schild', () => {
    const { container, queryByTestId } = seite4(props(FAELLE.abgestuftThemaSicher.data))
    expect(titel(container)).toEqual(['Terme & Gleichungen', 'Geometrie', 'Daten & Zufall'])
    expect(queryByTestId('eb-s4-chip-thema')).toBeNull()
  })

  it('Thema und Breite ohne Übungsbedarf: Titel „Kein Übungsbedarf“, ohne Schwerpunkte', () => {
    const { data } = FAELLE.abgestuftThemaSicher
    const alles = data.erzaehlung.kompetenzen.map((k) => ({ ...k, zustand: 'traegt' }))
    const { container, queryByTestId } = seite4(props({ ...data, erzaehlung: { ...data.erzaehlung, kompetenzen: alles } }))
    expect(container).toHaveTextContent('Kein Übungsbedarf in den untersuchten Bereichen.')
    expect(queryByTestId('eb-schwerpunkte')).toBeNull()
  })

  it('ilkay: ohne Schild', () => {
    expect(seite4(props(FAELLE.ilkay.data)).queryByTestId('eb-s4-chip-thema')).toBeNull()
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
