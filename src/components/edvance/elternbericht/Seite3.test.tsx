// Seite 3 des Eltern-Berichts (Bericht v2): Lücken und was im Schuljahr darauf aufbaut.
import { render, within } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { ElternberichtBogen } from '@/components/edvance/elternbericht/Bogen'
import { NamensMessungFertig } from '@/components/edvance/elternbericht/namensMessung'
import { Seite3 } from '@/components/edvance/elternbericht/Seite3'
import type { SeitenProps } from '@/components/edvance/elternbericht/seitenProps'
import { Bausteinsatz } from '@/lib/report/bausteine'
import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import type { ReportData } from '@/types'

function bogen(data: ReportData) {
  const { container } = render(<ElternberichtBogen data={data} notes={null} tiers={[]} />)
  const seite = (n: number) => container.querySelector<HTMLElement>(`.eb-seite[data-seite="${n}"]`)!
  return { container, seite, s3: within(seite(3)) }
}

const zeilenTexte = (el: HTMLElement): string[] =>
  [...el.querySelectorAll('[data-testid="eb-s3-zeile"]')].map((z) => z.textContent ?? '')

describe('Seite 3 — Lücken und kommende Themen (ilkay, Kernlehrplan)', () => {
  it('Kicker, Titel und Intro mit Quelle und Klasse', () => {
    const s = bogen(FAELLE.ilkay.data).seite(3)
    expect(s.querySelector('.eb-s3-kicker')).toHaveTextContent('Einordnung')
    expect(s.querySelector('h1')).toHaveTextContent('Wo es hakt und was darauf aufbaut.')
    expect(s.querySelector('.eb-s3-intro')).toHaveTextContent(
      'Links stehen Bereiche mit Übungsbedarf, rechts die Themen, die laut dem Kernlehrplan NRW in Klasse 10 noch kommen und direkt darauf aufbauen.',
    )
  })

  it('je kommendem Thema eine Zeile: Lücken links, Thema mit „voraussichtlich …“ rechts', () => {
    const { s3 } = bogen(FAELLE.ilkay.data)
    const zeilen = s3.getAllByTestId('eb-s3-zeile')
    expect(zeilen).toHaveLength(5)
    expect(zeilen[0].querySelector('.eb-s3v2-luecken')).toHaveTextContent('Ausklammern')
    expect(zeilen[0].querySelector('.eb-s3v2-kommt-titel')).toHaveTextContent('Quadratische Gleichungen')
    expect(zeilen[0].querySelector('.eb-s3v2-kommt-wann')).toHaveTextContent('voraussichtlich in Klasse 10')
    // Der Pfeil steht innerhalb der Zeile, nicht quer über die Seite.
    for (const z of zeilen) expect(z.querySelector('svg.eb-s3v2-pfeil')).not.toBeNull()
    expect(zeilen[1].querySelector('.eb-s3v2-kommt-sitzt')).toHaveTextContent('Sitzt schon: Potenzen und Quadratzahlen')
  })

  it('„Weitere Bereiche mit Übungsbedarf“ je Themenfeld, mit Hinweis, wenn es Zeilen gibt', () => {
    const w = bogen(FAELLE.ilkay.data).s3.getByTestId('eb-s3-weitere')
    expect(w.querySelector('.eb-kicker')).toHaveTextContent('Weitere Bereiche mit Übungsbedarf')
    expect(w.querySelector('.eb-s3v2-leise')).toHaveTextContent('baut im weiteren Schuljahr kein Thema direkt auf')
    const gruppen = [...w.querySelectorAll('.eb-s3v2-gruppe')].map((g) => g.querySelector('dt')?.textContent)
    expect(gruppen).toEqual([
      'Brüche & Dezimalzahlen',
      'Prozent & Dreisatz',
      'Terme & Gleichungen',
      'Geometrie',
      'Größen',
      'Zahlen & Rechnen',
    ])
    expect(w.querySelector('.eb-s3v2-gruppe dd')).toHaveTextContent('Brüche addieren · Brüche dividieren · Brüche multiplizieren')
  })

  it('Stärken-Kasten am Ende, mit den Themen, auf denen das Sichere aufbaut', () => {
    const { seite, s3 } = bogen(FAELLE.ilkay.data)
    const k = s3.getByTestId('eb-s3-staerken')
    expect(k.querySelector('.eb-kicker')).toHaveTextContent('Stärken')
    expect(k).toHaveTextContent('Das sitzt bereits und ist Grundlage für')
    expect(k).toHaveTextContent('Potenzen und Quadratzahlen')
    expect(seite(3).querySelector('.eb-s3-hinweis')).toHaveTextContent('Beides beschreibt den Lernstoff, keine Vorhersage.')
  })

  it('kein Lernweg mehr: keine Zonen, Linien, Legende, „Sie sind hier“, kein Skill-Schlüssel, kein „trägt“', () => {
    for (const name of ['ilkay', 'abgestuft', 'klasse7'] as const) {
      const s = bogen(FAELLE[name].data).seite(3)
      expect(s.querySelector('.eb-s3-zone-kopf, [data-legende], [data-spalte], [data-testid="eb-s3-hier"]'), name).toBeNull()
      expect(s.textContent, name).not.toMatch(/Sie sind hier|↳|Fundament|Ebene|\bLGS\b|tr(ä|ae)gt|Pyramide/)
      expect(s.innerHTML, name).not.toMatch(/bruch_dezimal|zahl_wurzel|gleichung_lgs|bruch_kuerzen/)
    }
  })
})

describe('Seite 3 — Schulplan und Halbjahr (abgestuft)', () => {
  it('Schulname im Genitiv in der Quellenangabe', () => {
    const s = bogen(FAELLE.abgestuft.data).seite(3)
    expect(s.querySelector('.eb-s3-hinweis')).toHaveTextContent(
      'die Reihenfolge der kommenden Themen aus dem Schulplan des Friedrich-Wilhelm-Gymnasiums.',
    )
  })

  it('ohne lesbaren Schulnamen: „dem Schulplan der Schule“', () => {
    const { data } = FAELLE.abgestuft
    const plan = data.erzaehlung.plan ? { ...data.erzaehlung.plan, schulname: null } : null
    const s = bogen({ ...data, erzaehlung: { ...data.erzaehlung, plan } }).seite(3)
    expect(s.querySelector('.eb-s3-hinweis')).toHaveTextContent('aus dem Schulplan der Schule.')
  })

  it('Lücken ohne Bezug zu einem kommenden Thema: nur „Weitere“, keine Zeilen, kein Intro, kein Hinweis darunter', () => {
    const { s3, seite } = bogen(FAELLE.abgestuft.data)
    expect(s3.queryByTestId('eb-s3-wege')).toBeNull()
    expect(seite(3).querySelector('.eb-s3-intro')).toBeNull()
    expect(seite(3).querySelector('.eb-s3v2-leise')).toBeNull()
    const gruppen = [...seite(3).querySelectorAll('.eb-s3v2-gruppe dt')].map((x) => x.textContent)
    expect(gruppen[0]).toBe('Aktuelles Thema Reelle Zahlen')
  })

  it('Halbjahr aus dem Schulplan: „voraussichtlich im n. Halbjahr“, sonst die Klasse', () => {
    const { seite } = bogen(FAELLE.abgestuftPlanrang.data)
    const wann = [...seite(3).querySelectorAll('.eb-s3v2-kommt-wann')].map((x) => x.textContent)
    expect(wann.length).toBeGreaterThan(0)
    for (const w of wann) expect(w).toMatch(/^voraussichtlich (im [12]\. Halbjahr|in Klasse 9)$/)
  })

  it('„und n weitere sichere Bereiche“ als Rest der Stärken', () => {
    expect(bogen(FAELLE.abgestuft.data).s3.getByTestId('eb-s3-staerken')).toHaveTextContent(
      'Dazu kommen 3 weitere sichere Bereiche (Seite 2).',
    )
  })
})

describe('Seite 3 — Sonderfälle', () => {
  it('allesSicher: Titel „Was sitzt …“, keine Zeilen, keine Weiteren, Stärken stehen', () => {
    const { s3, seite } = bogen(FAELLE.allesSicher.data)
    expect(seite(3).querySelector('h1')).toHaveTextContent('Was sitzt und was darauf aufbaut.')
    expect(s3.queryByTestId('eb-s3-wege')).toBeNull()
    expect(s3.queryByTestId('eb-s3-weitere')).toBeNull()
    expect(s3.getByTestId('eb-s3-staerken')).toBeInTheDocument()
  })

  it('nichtsSicher: kein Stärken-Kasten', () => {
    expect(bogen(FAELLE.nichtsSicher.data).s3.queryByTestId('eb-s3-staerken')).toBeNull()
  })

  it('ohne Lernweg-Quelle im Bericht rendert die Seite nichts', () => {
    const d = FAELLE.ilkay.data
    const bericht = baueElternbericht({ kompetenzen: d.erzaehlung.kompetenzen, katalog: d.erzaehlung.katalog, klasse: d.grade })!
    const props: SeitenProps = { data: d, bericht, satz: new Bausteinsatz([]), notes: null, tiers: [], name: null, wessen: null }
    expect(bericht.lueckenweg).toBeNull()
    const { container } = render(<Seite3 {...props} />)
    expect(container).toBeEmptyDOMElement()
  })
})

describe('Seite 3 — Ausdünnen bei Überlauf', () => {
  afterEach(() => vi.restoreAllMocks())

  function seite3(ueberlauf: (zeilen: number) => boolean, name: keyof typeof FAELLE = 'ilkay') {
    const d = FAELLE[name].data
    const bericht = baueElternbericht({
      kompetenzen: d.erzaehlung.kompetenzen,
      katalog: d.erzaehlung.katalog,
      klasse: d.grade,
      lernweg: { erzaehlung: d.erzaehlung, datum: d.analysedAt },
    })!
    const props: SeitenProps = { data: d, bericht, satz: new Bausteinsatz([]), notes: null, tiers: [], name: null, wessen: null }
    vi.spyOn(HTMLElement.prototype, 'scrollHeight', 'get').mockImplementation(function (this: HTMLElement) {
      return this.classList.contains('eb-inhalt') && ueberlauf(this.querySelectorAll('[data-testid="eb-s3-zeile"]').length) ? 977 : 960
    })
    vi.spyOn(HTMLElement.prototype, 'clientHeight', 'get').mockReturnValue(960)
    const r = render(
      <div className="eb-inhalt">
        <Seite3 {...props} />
      </div>,
    )
    return { ...r, s3: r.container.querySelector<HTMLElement>('.eb-s3')! }
  }

  it('passt die Seite, bleibt alles voll und es gibt kein data-stufe', () => {
    const { s3 } = seite3(() => false)
    expect(s3.hasAttribute('data-stufe')).toBe(false)
    expect(zeilenTexte(s3)).toHaveLength(5)
    expect(s3.querySelector('.eb-s3v2-kommt-sitzt')).not.toBeNull()
  })

  it('läuft sie bei mehr als vier Zeilen über, genügt Stufe 2: vier Zeilen, ohne „Sitzt schon“', () => {
    const { s3 } = seite3((zeilen) => zeilen > 4)
    expect(s3.getAttribute('data-stufe')).toBe('2')
    expect(zeilenTexte(s3)).toHaveLength(4)
    expect(s3.querySelector('.eb-s3v2-kommt-sitzt')).toBeNull()
  })

  it('läuft sie immer über, hält die letzte Stufe (5): drei Zeilen, Lücken nur als Zahl, Stärken nur als Zahl', () => {
    const { s3 } = seite3(() => true)
    expect(s3.getAttribute('data-stufe')).toBe('5')
    expect(zeilenTexte(s3)).toHaveLength(3)
    expect(s3.querySelector('.eb-s3v2-weitere')?.textContent).toMatch(/\d+ Bereiche?/)
    expect(s3.querySelector('.eb-s3v2-staerken')?.textContent).toMatch(/\d+ Bereiche sitzen bereits sicher/)
    // Nichts verschwindet still: die Lücken gekappter Zeilen stehen als Gruppe.
    expect(s3.querySelector('.eb-s3v2-weitere')).toHaveTextContent('Grundlage für spätere Themen')
    // Mit „spätere Themen“ entfällt der Satz „baut kein Thema direkt auf“.
    expect(s3.querySelector('.eb-s3v2-leise')).toBeNull()
  })

  it('misst erst, wenn der Bogen über den Namen entschieden hat', () => {
    vi.spyOn(HTMLElement.prototype, 'scrollHeight', 'get').mockReturnValue(977)
    vi.spyOn(HTMLElement.prototype, 'clientHeight', 'get').mockReturnValue(960)
    const d = FAELLE.ilkay.data
    const bericht = baueElternbericht({
      kompetenzen: d.erzaehlung.kompetenzen,
      katalog: d.erzaehlung.katalog,
      klasse: d.grade,
      lernweg: { erzaehlung: d.erzaehlung, datum: d.analysedAt },
    })!
    const props: SeitenProps = { data: d, bericht, satz: new Bausteinsatz([]), notes: null, tiers: [], name: null, wessen: null }
    const { container } = render(
      <NamensMessungFertig.Provider value={false}>
        <div className="eb-inhalt">
          <Seite3 {...props} />
        </div>
      </NamensMessungFertig.Provider>,
    )
    expect(container.querySelector('.eb-s3')!.hasAttribute('data-stufe')).toBe(false)
  })
})
