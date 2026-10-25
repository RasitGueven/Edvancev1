// Seite 3 des Eltern-Berichts (Bericht v3): Ausdünnen bei Überlauf.
import { render } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { NamensMessungFertig } from '@/components/edvance/elternbericht/namensMessung'
import { Seite3 } from '@/components/edvance/elternbericht/Seite3'
import type { SeitenProps } from '@/components/edvance/elternbericht/seitenProps'
import { Bausteinsatz } from '@/lib/report/bausteine'
import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import type { EinordnungLayout } from '@/lib/report/elternbericht/berichtKonfig'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import type { EbLueckenweg, Elternbericht, ReportData } from '@/types'


const bericht = (d: ReportData): Elternbericht =>
  baueElternbericht({
    kompetenzen: d.erzaehlung.kompetenzen,
    katalog: d.erzaehlung.katalog,
    klasse: d.grade,
    lernweg: { erzaehlung: d.erzaehlung, datum: d.analysedAt },
  })!

const propsFuer = (d: ReportData, lueckenweg?: EbLueckenweg, einordnung?: EinordnungLayout): SeitenProps => ({
  data: d,
  bericht: lueckenweg ? { ...bericht(d), lueckenweg } : bericht(d),
  satz: new Bausteinsatz([]),
  notes: null,
  tiers: [],
  name: null,
  vollerName: null,
  wessen: null,
  einordnung,
})

describe('Seite 3 — Ausdünnen bei Überlauf', () => {
  afterEach(() => vi.restoreAllMocks())

  function seite3(ueberlauf: (inhalt: HTMLElement) => boolean, lueckenweg?: EbLueckenweg) {
    const props = propsFuer(FAELLE.ilkay.data, lueckenweg, 'B')
    vi.spyOn(HTMLElement.prototype, 'scrollHeight', 'get').mockImplementation(function (this: HTMLElement) {
      return this.classList.contains('eb-inhalt') && ueberlauf(this) ? 977 : 960
    })
    vi.spyOn(HTMLElement.prototype, 'clientHeight', 'get').mockReturnValue(960)
    const r = render(
      <div className="eb-inhalt">
        <Seite3 {...props} />
      </div>,
    )
    return { ...r, s3: r.container.querySelector<HTMLElement>('.eb-s3')! }
  }
  const zeilen = (el: HTMLElement): number => el.querySelectorAll('[data-testid="eb-s3-zeile"]').length

  it('passt die Seite, bleibt alles voll und es gibt kein data-stufe', () => {
    const { s3 } = seite3(() => false)
    expect(s3.hasAttribute('data-stufe')).toBe(false)
    expect(zeilen(s3)).toBe(8)
    expect(s3.querySelector('.eb-s3v3-rest')).toBeNull()
  })

  it('läuft sie bei mehr als vier Zeilen über, genügt Stufe 2: vier Themenblöcke', () => {
    const { s3 } = seite3((el) => zeilen(el) > 4)
    expect(s3.getAttribute('data-stufe')).toBe('2')
    expect(zeilen(s3)).toBe(4)
    // Nichts verschwindet still: die Lücken der gekappten Blöcke stehen als Gruppe.
    expect(s3.querySelector('[data-testid="eb-s3-weitere"]')).toHaveTextContent('Grundlage für spätere Themen')
  })

  it('Stufe 1 kürzt zuerst die Kästen auf drei Bereiche mit „und n weitere“', () => {
    const viele = (p: string) => Array.from({ length: 5 }, (_, i) => ({ label: `${p}${i + 1}`, auch: [] }))
    const lw: EbLueckenweg = {
      themen: [{ titel: 'Kreis', halbjahr: null, sitzt: viele('S'), fehlt: viele('F') }],
      weitereStaerken: [],
      weitere: [],
      quelle: 'klp',
      schulname: null,
    }
    const mehrAlsDrei = (el: HTMLElement): boolean =>
      [...el.querySelectorAll('.eb-s3v3-bereiche')].some((k) => k.querySelectorAll('li:not(.eb-s3v3-rest)').length > 3)
    const { s3 } = seite3(mehrAlsDrei, lw)
    expect(s3.getAttribute('data-stufe')).toBe('1')
    expect(s3.querySelector('[data-testid="eb-s3-sitzt"]')?.textContent).toBe('S1S2S3und 2 weitere')
    expect(s3.querySelector('[data-testid="eb-s3-fehlt"]')?.textContent).toBe('F1F2F3und 2 weitere')
  })

  it('läuft sie immer über, hält die letzte Stufe (4): drei Blöcke, übrige Lücken und Stärken nur als Zahl', () => {
    const { s3 } = seite3(() => true)
    expect(s3.getAttribute('data-stufe')).toBe('4')
    expect(zeilen(s3)).toBe(3)
    expect(s3.querySelector('[data-testid="eb-s3-weitere"] dd')?.textContent).toMatch(/^\d+ Bereiche?$/)
    expect(s3.querySelector('[data-testid="eb-s3-weitere-staerken"] p')?.textContent).toMatch(/^\d+ Bereiche?$/)
    expect(s3.querySelector('[data-testid="eb-s3-weitere"]')).toHaveTextContent('Grundlage für spätere Themen')
  })

  it('misst erst, wenn der Bogen über den Namen entschieden hat', () => {
    vi.spyOn(HTMLElement.prototype, 'scrollHeight', 'get').mockReturnValue(977)
    vi.spyOn(HTMLElement.prototype, 'clientHeight', 'get').mockReturnValue(960)
    const { container } = render(
      <NamensMessungFertig.Provider value={false}>
        <div className="eb-inhalt">
          <Seite3 {...propsFuer(FAELLE.ilkay.data)} />
        </div>
      </NamensMessungFertig.Provider>,
    )
    expect(container.querySelector('.eb-s3')!.hasAttribute('data-stufe')).toBe(false)
  })
})
