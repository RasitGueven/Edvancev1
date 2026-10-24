// Seite 3 des Eltern-Berichts (Bericht v3): erst was sitzt, dann was fehlt, je kommendem Thema.
import { render, within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import '@/i18n'

import { ElternberichtBogen } from '@/components/edvance/elternbericht/Bogen'
import { Seite3 } from '@/components/edvance/elternbericht/Seite3'
import type { SeitenProps } from '@/components/edvance/elternbericht/seitenProps'
import { Bausteinsatz } from '@/lib/report/bausteine'
import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import { EINORDNUNG_LAYOUT, type EinordnungLayout } from '@/lib/report/elternbericht/berichtKonfig'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import type { EbLueckenweg, Elternbericht, ReportData } from '@/types'

function bogen(data: ReportData, einordnung?: EinordnungLayout) {
  const { container } = render(<ElternberichtBogen data={data} notes={null} tiers={[]} einordnung={einordnung} />)
  const seite = (n: number) => container.querySelector<HTMLElement>(`.eb-seite[data-seite="${n}"]`)!
  return { container, seite, s3: within(seite(3)) }
}

/** Alle Bereichsnamen, die auf Seite 3 stehen: Kästen, weitere Stärken, weitere Lücken. */
function bereicheAuf(el: HTMLElement): string[] {
  const kaesten = [...el.querySelectorAll('.eb-s3v3-bereiche > li:not(.eb-s3v3-rest)')].map(
    (li) => li.firstChild?.textContent ?? '',
  )
  const staerken = el.querySelector('[data-testid="eb-s3-weitere-staerken"] p')?.textContent?.split(' · ') ?? []
  const luecken = [...el.querySelectorAll('[data-testid="eb-s3-weitere"] dd')].flatMap((dd) => dd.textContent?.split(' · ') ?? [])
  return [...kaesten, ...staerken, ...luecken]
}

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

describe('Seite 3 — Layout B (Standard): je Thema eine Zeile grün · rot → blau', () => {
  it('Kicker, Titel und Intro mit Quelle, ohne Klasse', () => {
    const s = bogen(FAELLE.ilkay.data, 'B').seite(3)
    expect(s.querySelector('.eb-s3-kicker')).toHaveTextContent('Einordnung')
    expect(s.querySelector('h1')).toHaveTextContent('Was sitzt und was noch fehlt.')
    expect(s.querySelector('.eb-s3-intro')?.textContent).toBe(
      'Zuerst steht, was schon sitzt, dann, was noch fehlt – jeweils für die Themen, die laut dem Kernlehrplan NRW noch kommen und direkt darauf aufbauen.',
    )
    expect(s.textContent).not.toMatch(/in Klasse \d+ noch kommen/)
  })

  it('der Standard ist EINORDNUNG_LAYOUT aus der Konfiguration', () => {
    const s = bogen(FAELLE.ilkay.data).seite(3)
    expect(s.querySelector('.eb-s3')).toHaveAttribute('data-layout', EINORDNUNG_LAYOUT)
  })

  it('eine Zeile je Thema in Planreihenfolge mit Pfeil in der Zeile', () => {
    const { s3 } = bogen(FAELLE.ilkay.data, 'B')
    const zeilen = s3.getAllByTestId('eb-s3-zeile')
    expect(zeilen.map((z) => z.querySelector('[data-testid="eb-s3-thema"] p')?.textContent)).toEqual([
      'Reelle Zahlen und Wurzeln',
      'Quadratische Funktionen',
      'Quadratische Gleichungen',
      'Ähnlichkeit und zentrische Streckung',
      'Kreis: Umfang und Fläche',
      'Prismen und Zylinder',
      'Bedingte Wahrscheinlichkeit',
      'Statistische Erhebungen beurteilen',
    ])
    for (const z of zeilen) expect(z.querySelector('svg.eb-s3v3-pfeil')).not.toBeNull()
    // Die Spaltenköpfe stehen einmal über allen Zeilen.
    expect(s3.getByTestId('eb-s3-wege').querySelector('.eb-s3v3-kopf')).toHaveTextContent('Sitzt schon')
    expect(s3.getByTestId('eb-s3-wege').querySelector('.eb-s3v3-kopf')).toHaveTextContent('Fehlt noch')
    expect(s3.getByTestId('eb-s3-wege').querySelector('.eb-s3v3-kopf')).toHaveTextContent('Kommt noch')
  })

  it('Kasten nur, wenn es etwas gibt; sonst leere Zelle; der Pfeil folgt dem roten Kasten', () => {
    const zeilen = bogen(FAELLE.ilkay.data, 'B').s3.getAllByTestId('eb-s3-zeile')
    // Reelle Zahlen: nur Sitzt. Quadratische Gleichungen: nur Fehlt. Kreis: beides.
    const [zahlen, , gleichungen, , kreis] = zeilen
    expect(zahlen.querySelector('.eb-s3v3-sitzt')).not.toBeNull()
    expect(zahlen.querySelector('.eb-s3v3-fehlt')).toBeNull()
    expect(zahlen.querySelector('[data-testid="eb-s3-fehlt"]')).toHaveClass('eb-s3v3-leer')
    expect(zahlen.querySelector('svg')).toHaveClass('eb-s3v3-pfeil-sitzt')
    expect(gleichungen.querySelector('[data-testid="eb-s3-sitzt"]')).toHaveClass('eb-s3v3-leer')
    expect(gleichungen.querySelector('[data-testid="eb-s3-fehlt"]')).toHaveTextContent('Ausklammern')
    expect(gleichungen.querySelector('svg')).toHaveClass('eb-s3v3-pfeil-fehlt')
    expect(kreis.querySelector('[data-testid="eb-s3-sitzt"]')).toHaveTextContent('Fläche von Rechteck und Quadrat')
    expect(kreis.querySelector('[data-testid="eb-s3-fehlt"]')).toHaveTextContent('Flächeneinheiten')
  })

  it('„betrifft auch …“ nennt die übrigen Themen in Anführungszeichen; der Bereich steht nur einmal', () => {
    const { s3, container } = bogen(FAELLE.ilkay.data, 'B')
    const zeilen = s3.getAllByTestId('eb-s3-zeile')
    expect(zeilen[0].querySelector('[data-testid="eb-s3-sitzt"]')).toHaveTextContent(
      'Runden und Überschlagbetrifft auch „Kreis: Umfang und Fläche“ und „Exponentielles Wachstum“',
    )
    expect(container.textContent?.match(/Runden und Überschlag/g)).toHaveLength(1)
    // Ein Bereich ohne weiteres Thema trägt keinen Hinweis.
    expect(zeilen[1].querySelector('.eb-s3v3-auch')).toBeNull()
  })
})

describe('Seite 3 — Layout A: erst alle grünen, dann alle roten Kästen, Themen rechts nummeriert', () => {
  it('Reihenfolge Sitzt-Kästen vor Fehlt-Kästen, keine Zeilen', () => {
    const { s3, seite } = bogen(FAELLE.ilkay.data, 'A')
    expect(seite(3).querySelector('.eb-s3')).toHaveAttribute('data-layout', 'A')
    expect(s3.queryByTestId('eb-s3-zeile')).toBeNull()
    const arten = [...seite(3).querySelectorAll('[data-testid="eb-s3-sitzt"], [data-testid="eb-s3-fehlt"]')].map((k) =>
      k.getAttribute('data-testid'),
    )
    const letztesSitzt = arten.lastIndexOf('eb-s3-sitzt')
    const erstesFehlt = arten.indexOf('eb-s3-fehlt')
    expect(letztesSitzt).toBeGreaterThanOrEqual(0)
    expect(erstesFehlt).toBeGreaterThan(letztesSitzt)
    expect(arten.filter((a) => a === 'eb-s3-sitzt')).toHaveLength(4)
    expect(arten.filter((a) => a === 'eb-s3-fehlt')).toHaveLength(5)
  })

  it('die Themen stehen einmal rechts, mit Nummer 1 … n; die Kästen tragen dieselbe Nummer', () => {
    const { s3, seite } = bogen(FAELLE.ilkay.data, 'A')
    const themen = s3.getAllByTestId('eb-s3-thema')
    expect(themen).toHaveLength(8)
    expect(themen.map((t) => t.querySelector('.eb-s3v3-nr')?.textContent)).toEqual(['1', '2', '3', '4', '5', '6', '7', '8'])
    // Kreis (5) hat grünen und roten Kasten mit derselben Nummer und demselben Titel.
    const kreis = [...seite(3).querySelectorAll('.eb-s3v3-fuer')].filter((p) => p.textContent === '5Kreis: Umfang und Fläche')
    expect(kreis).toHaveLength(2)
    expect(themen[4]).toHaveTextContent('Kreis: Umfang und Fläche')
    // Spaltenköpfe
    expect(seite(3).querySelector('.eb-s3v3-links')).toHaveTextContent('Sitzt schon')
    expect(seite(3).querySelector('.eb-s3v3-links')).toHaveTextContent('Fehlt noch')
    expect(seite(3).querySelector('.eb-s3v3-rechts')).toHaveTextContent('Kommt noch')
  })

  it('nur Fehlt-Kästen: keine Spaltenüberschrift „Sitzt schon“ im Layout A', () => {
    const { s3 } = bogen(FAELLE.nichtsSicher.data, 'A')
    expect(s3.queryByTestId('eb-s3-sitzt')).toBeNull()
    expect(s3.getAllByTestId('eb-s3-fehlt').length).toBeGreaterThan(0)
    expect(s3.queryByText('Sitzt schon')).toBeNull()
  })
})

describe('Seite 3 — jeder geprüfte Bereich genau einmal (beide Layouts)', () => {
  const faelle = Object.entries(FAELLE).filter(([n]) => n !== 'ohneKatalog' && FAELLE[n as keyof typeof FAELLE].data.auswertbar !== false)

  it.each(['A', 'B'] as const)('Layout %s: nichts doppelt, nichts fehlt', (layout) => {
    let geprueft = 0
    for (const [name, { data }] of faelle) {
      const b = bericht(data)
      if (!b.lueckenweg) continue
      const erwartet = [...b.sicherListe, ...b.uebungListe].map((x) => x.label).sort()
      const { seite, container } = bogen(data, layout)
      expect(bereicheAuf(seite(3)).sort(), `${name} (${layout})`).toEqual(erwartet)
      container.remove()
      geprueft += 1
    }
    expect(geprueft).toBeGreaterThan(5)
  })

  it('Abstufung abgestuft (Schulplan): ein Thema, drei weitere Stärken, Lücken nur in den Gruppen', () => {
    const { s3, seite } = bogen(FAELLE.abgestuft.data, 'B')
    expect(s3.getAllByTestId('eb-s3-zeile')).toHaveLength(1)
    expect(s3.getByTestId('eb-s3-weitere-staerken')).toHaveTextContent(
      'Einsetzungsverfahren · Gleichungssysteme grafisch lösen (Schnittpunkt) · Wurzeln abschätzen und Näherungswerte',
    )
    const gruppen = [...seite(3).querySelectorAll('.eb-s3v2-gruppe dt')].map((x) => x.textContent)
    expect(gruppen[0]).toBe('Aktuelles Thema Reelle Zahlen')
  })
})

describe('Seite 3 — Weitere Stärken und Weitere Bereiche', () => {
  it('„Weitere Stärken“ als kurze Liste mit Mittelpunkt, vor den weiteren Bereichen', () => {
    const { s3, seite } = bogen(FAELLE.ilkay.data, 'B')
    const w = s3.getByTestId('eb-s3-weitere-staerken')
    expect(w.querySelector('.eb-kicker')).toHaveTextContent('Weitere Stärken')
    expect(w.querySelector('p')?.textContent).toBe(
      'Längen umrechnen · Massen umrechnen · Brüche kürzen · Gemischte Schreibweise · Gleichungen mit negativem Koeffizienten',
    )
    const reihe = [...seite(3).querySelectorAll('[data-testid]')].map((x) => x.getAttribute('data-testid'))
    expect(reihe.indexOf('eb-s3-weitere-staerken')).toBeLessThan(reihe.indexOf('eb-s3-weitere'))
  })

  it('„Weitere Bereiche mit Übungsbedarf“ je Themenfeld, mit dem neuen Einleitungssatz', () => {
    const w = bogen(FAELLE.ilkay.data, 'B').s3.getByTestId('eb-s3-weitere')
    expect(w.querySelector('.eb-kicker')).toHaveTextContent('Weitere Bereiche mit Übungsbedarf')
    expect(w.querySelector('.eb-s3v2-leise')?.textContent).toBe(
      'Diese Bereiche werden in späteren Themen und Schuljahren wichtig. Wir nehmen sie dazu, sobald sie anstehen.',
    )
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

  it('allesSicher: keine Weiteren Bereiche; nichtsSicher: keine Weiteren Stärken', () => {
    const alle = bogen(FAELLE.allesSicher.data, 'B').s3
    expect(alle.queryByTestId('eb-s3-weitere')).toBeNull()
    expect(alle.getByTestId('eb-s3-weitere-staerken')).toBeInTheDocument()
    expect(alle.queryAllByTestId('eb-s3-fehlt').every((k) => k.classList.contains('eb-s3v3-leer'))).toBe(true)
    expect(bogen(FAELLE.nichtsSicher.data, 'B').s3.queryByTestId('eb-s3-weitere-staerken')).toBeNull()
  })

  it('ohne Themenzeilen entfallen Intro und Spalten, die Weiteren bleiben', () => {
    const d = FAELLE.abgestuft.data
    const lw: EbLueckenweg = {
      themen: [],
      weitereStaerken: [],
      weitere: [{ feld: 'geometrie', thema: null, labels: ['Satz des Thales'] }],
      quelle: 'klp',
      schulname: null,
    }
    const { container } = render(<Seite3 {...propsFuer(d, lw, 'B')} />)
    expect(container.querySelector('.eb-s3-intro')).toBeNull()
    expect(container.querySelector('[data-testid="eb-s3-wege"]')).toBeNull()
    expect(container.querySelector('[data-testid="eb-s3-weitere"]')).toHaveTextContent('Satz des Thales')
  })
})

describe('Seite 3 — Schulplan und Halbjahr', () => {
  it('Schulname im Genitiv in der Quellenangabe und im Intro', () => {
    const s = bogen(FAELLE.abgestuft.data).seite(3)
    expect(s.querySelector('.eb-s3-hinweis')).toHaveTextContent(
      'die Reihenfolge der kommenden Themen aus dem Schulplan des Friedrich-Wilhelm-Gymnasiums.',
    )
    expect(s.querySelector('.eb-s3-intro')).toHaveTextContent('laut dem Schulplan des Friedrich-Wilhelm-Gymnasiums noch kommen')
  })

  it('ohne lesbaren Schulnamen: „dem Schulplan der Schule“', () => {
    const { data } = FAELLE.abgestuft
    const plan = data.erzaehlung.plan ? { ...data.erzaehlung.plan, schulname: null } : null
    const s = bogen({ ...data, erzaehlung: { ...data.erzaehlung, plan } }).seite(3)
    expect(s.querySelector('.eb-s3-hinweis')).toHaveTextContent('aus dem Schulplan der Schule.')
  })

  it('Halbjahr nur, wenn der Plan es kennt: „voraussichtlich n. Halbjahr“, nie „in Klasse …“', () => {
    for (const layout of ['A', 'B'] as const) {
      const mit = bogen(FAELLE.planOhneThema.data, layout).seite(3)
      const wann = [...mit.querySelectorAll('.eb-s3v3-wann')].map((x) => x.textContent)
      expect(wann.length, layout).toBeGreaterThan(0)
      for (const w of wann) expect(w, layout).toMatch(/^voraussichtlich [12]\. Halbjahr$/)
      expect(mit.textContent).not.toMatch(/voraussichtlich in Klasse|voraussichtlich im/)
    }
    // Kernlehrplan und Plan ohne Halbjahr: keine Zeitangabe.
    const ohne = bogen(FAELLE.ilkay.data, 'B').seite(3)
    expect(ohne.querySelector('.eb-s3v3-wann')).toBeNull()
    expect(ohne.textContent).not.toMatch(/voraussichtlich/)
  })

  it('Halbjahr direkt aus dem Modell: 1, 2 und null', () => {
    const lw: EbLueckenweg = {
      themen: [
        { titel: 'Eins', halbjahr: 1, sitzt: [{ label: 'A', auch: [] }], fehlt: [] },
        { titel: 'Zwei', halbjahr: 2, sitzt: [], fehlt: [{ label: 'B', auch: [] }] },
        { titel: 'Drei', halbjahr: null, sitzt: [], fehlt: [{ label: 'C', auch: [] }] },
      ],
      weitereStaerken: [],
      weitere: [],
      quelle: 'schule',
      schulname: 'Gymnasium Nord',
    }
    const { container } = render(<Seite3 {...propsFuer(FAELLE.abgestuft.data, lw, 'B')} />)
    expect([...container.querySelectorAll('[data-testid="eb-s3-thema"]')].map((t) => t.textContent)).toEqual([
      'Einsvoraussichtlich 1. Halbjahr',
      'Zweivoraussichtlich 2. Halbjahr',
      'Drei',
    ])
  })

  it('kein Lernweg mehr: keine Zonen, Linien, „Sie sind hier“, kein Skill-Schlüssel, kein „trägt“', () => {
    for (const name of ['ilkay', 'abgestuft', 'klasse7'] as const) {
      const s = bogen(FAELLE[name].data).seite(3)
      expect(s.querySelector('.eb-s3-zone-kopf, [data-legende], [data-spalte], [data-testid="eb-s3-hier"]'), name).toBeNull()
      expect(s.textContent, name).not.toMatch(/Sie sind hier|↳|Fundament|Ebene|\bLGS\b|tr(ä|ae)gt|Pyramide/)
      expect(s.innerHTML, name).not.toMatch(/bruch_dezimal|zahl_wurzel|gleichung_lgs|bruch_kuerzen/)
    }
  })
})

describe('Seite 3 — Restzahlen und Sonderfälle', () => {
  it('„und n weitere“ im Kasten und bei den Weiteren Stärken, nur Zahl ohne Namen', () => {
    const lw: EbLueckenweg = {
      themen: [
        {
          titel: 'Kreis',
          halbjahr: null,
          sitzt: [{ label: 'A', auch: [] }],
          fehlt: [{ label: 'B', auch: [] }],
          restSitzt: 2,
          restFehlt: 1,
        },
      ],
      weitereStaerken: ['S1'],
      weitereStaerkenRest: 3,
      weitere: [{ feld: null, thema: null, spaeter: true, labels: [], rest: 4 }],
      quelle: 'klp',
      schulname: null,
    }
    const { container } = render(<Seite3 {...propsFuer(FAELLE.abgestuft.data, lw, 'B')} />)
    const rest = [...container.querySelectorAll('.eb-s3v3-rest')].map((x) => x.textContent)
    expect(rest).toEqual(['und 2 weitere', 'und ein weiterer'])
    expect(container.querySelector('[data-testid="eb-s3-weitere-staerken"] p')?.textContent).toBe('S1 · und 3 weitere')
    expect(container.querySelector('[data-testid="eb-s3-weitere"] dd')?.textContent).toBe('4 Bereiche')
    expect(container.querySelector('[data-testid="eb-s3-weitere"] dt')?.textContent).toBe('Grundlage für spätere Themen')
  })

  it('ohne Lernweg-Quelle im Bericht rendert die Seite nichts', () => {
    const d = FAELLE.ilkay.data
    const b = baueElternbericht({ kompetenzen: d.erzaehlung.kompetenzen, katalog: d.erzaehlung.katalog, klasse: d.grade })!
    expect(b.lueckenweg).toBeNull()
    const { container } = render(<Seite3 {...{ ...propsFuer(d), bericht: b }} />)
    expect(container).toBeEmptyDOMElement()
  })
})
