// Seite 2 des Eltern-Berichts R7 (Lernstand) für die Fixture-Fälle.
import { render, within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import '@/i18n'

import { ElternberichtBogen } from '@/components/edvance/elternbericht/Bogen'
import { Profil } from '@/components/edvance/elternbericht/Profil'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import { datenAus } from '@/lib/report/elternbericht/fixtures/basis'
import { ILKAY_ROH, ILKAY_URTEILE } from '@/lib/report/elternbericht/fixtures/ilkay'
import type { ReportData, ThemenfeldKey } from '@/types'

function seite2(data: ReportData) {
  const { container } = render(<ElternberichtBogen data={data} notes={null} tiers={[]} />)
  const el = container.querySelector<HTMLElement>('.eb-seite[data-seite="2"]')!
  return { ...within(el), el }
}

describe('Seite 2 — ilkay', () => {
  const s = (): ReturnType<typeof seite2> => seite2(FAELLE.ilkay.data)

  it('Titel ohne Genitiv, keine Intro-Zeile mehr', () => {
    expect(s().getByRole('heading', { level: 1 })).toHaveTextContent('Der Lernstand von Ilkay in den geprüften Bereichen.')
    expect(s().el.querySelector('.eb-s2-intro')).toBeNull()
  })

  it('drei Zahlen sicher, Übungsbedarf, geprüft', () => {
    const zahlen = [...s().el.querySelectorAll('.eb-s2-zahl')].map((z) => z.textContent)
    expect(zahlen).toEqual(['11', '16', '27'])
    const labels = [...s().el.querySelectorAll('.eb-s2-zahl-label')].map((z) => z.textContent)
    expect(labels).toEqual(['sicher eingestuft', 'Übungsbedarf', 'Bereiche geprüft'])
    expect(s().el.querySelector('.eb-s2-zahl-geprueft rect')).not.toBeNull()
  })

  it('nur Felder mit geprüften Bereichen, ein Segment je geprüftem Bereich, keine Schraffur', () => {
    const { el, getAllByTestId } = s()
    const zeilen = getAllByTestId('eb-profil-zeile')
    // Funktionen und Zufall: nichts geprüft, keine Zeile.
    expect(zeilen).toHaveLength(6)
    expect(el).not.toHaveTextContent('Funktionen')
    const erste = zeilen[0]
    expect(erste.querySelectorAll('.eb-s2-segment-sicher')).toHaveLength(2)
    expect(erste.querySelectorAll('.eb-s2-segment-uebung')).toHaveLength(3)
    expect(erste.querySelectorAll('rect')).toHaveLength(5)
    expect(el.querySelector('[fill^="url("]')).toBeNull()
    expect(el.querySelector('.eb-s2-segment-offen, .eb-s2-segment-schraffur')).toBeNull()
    expect(erste.querySelector('svg')).toHaveAttribute('aria-hidden', 'true')
    expect(erste.querySelector('svg')).toHaveAttribute('height', '40.8pt')
    // Ein Maßstab für alle Zeilen: höchstens sechs Kästchen, also 28 pt (R7-8).
    const rects = [...erste.querySelectorAll('rect')]
    expect(rects.map((r) => r.getAttribute('width'))).toEqual(Array(5).fill('28'))
    expect(rects[0]).toHaveAttribute('x', '0')
  })

  it('Vorlesetext und rechte Zeile je Feld', () => {
    const zeilen = s().getAllByTestId('eb-profil-zeile')
    expect(zeilen[0].querySelector('.sr-only')).toHaveTextContent(
      'Brüche & Dezimalzahlen: 5 geprüft, davon 2 sicher und 3 mit Übungsbedarf.',
    )
    const rechts = (i: number): (string | null)[] =>
      [...zeilen[i].querySelectorAll('.eb-s2-geprueft, .eb-s2-teile')].map((x) => x.textContent)
    expect(rechts(0)).toEqual(['5 geprüft', '2 sicher · 3 Übungsbedarf'])
    // Zahlen & Rechnen: 2 sicher, 1 Übungsbedarf.
    expect(rechts(5)).toEqual(['3 geprüft', '2 sicher · 1 Übungsbedarf'])
  })

  it('Legende nur Sicher und Übungsbedarf', () => {
    const legende = s().el.querySelector('.eb-s2-legende')!
    expect(legende.textContent).toBe('SicherÜbungsbedarf')
    expect(legende).not.toHaveTextContent('Nicht untersucht')
  })

  it('Fußnote: „gelungen“, keine Note, nichts zu Umrissen', () => {
    const fussnote = s().el.querySelector('.eb-s2-fussnote')
    expect(fussnote).toHaveTextContent(
      'Jedes Kästchen steht für einen geprüften Bereich. Das ist keine Note und kein Prozentwert. Ein Bereich gilt als sicher, wenn die Aufgaben dazu gelungen sind. Über Bereiche, die nicht geprüft wurden, sagt dieser Bericht nichts.',
    )
    expect(fussnote).not.toHaveTextContent(/abgeleitet|Umrandete|ergeben sich/i)
  })

  it('Was die Grafik zeigt: Sicher-Satz und Übungsbedarf mit Anteil, kein Coach-Satz', () => {
    expect(s().getByTestId('eb-deutung')).toHaveTextContent(
      'Überwiegend sicher waren die Themenfelder Größen und Zahlen & Rechnen. Den meisten Übungsbedarf zeigte das Themenfeld Geometrie: 5 von 6 geprüften Bereichen.',
    )
    expect(s().el).not.toHaveTextContent(/prüft der Coach|Der Coach/)
  })
})

describe('Seite 2 — Sonderfälle', () => {
  it('neun Profilzeilen (mit „Weitere Bereiche“): Abstand 30 pt', () => {
    const { container } = render(
      <Profil
        wessen="Ilkays"
        profil={[
          ...['brueche', 'prozent', 'terme', 'geometrie', 'groessen', 'zahlen', 'funktionen', 'zufall', 'weitere'].map(
            (feld) => ({ feld: feld as ThemenfeldKey, sicher: 1, uebung: 1, abgeleitet: 0, klasse: null }),
          ),
        ]}
      />,
    )
    const zeilen = container.querySelectorAll('[data-testid="eb-profil-zeile"] svg')
    expect(zeilen).toHaveLength(9)
    expect(zeilen[0]).toHaveAttribute('height', '30pt')
    expect(container).toHaveTextContent('Weitere Bereiche')
  })

  it('weitereBereiche: „Weitere Bereiche“ als letzte Zeile, Abstand nach Zahl der Zeilen', () => {
    const s = seite2(FAELLE.weitereBereiche.data)
    const zeilen = s.getAllByTestId('eb-profil-zeile')
    expect(zeilen.at(-1)).toHaveTextContent('Weitere Bereiche')
    expect(zeilen[0].querySelector('svg')).toHaveAttribute('height', `${zeilen.length <= 6 ? 40.8 : zeilen.length <= 8 ? 33.4 : 30}pt`)
  })

  it('allesSicher: nur der Sicher-Satz, kein Coach-Satz, Teile nur sicher', () => {
    const s = seite2(FAELLE.allesSicher.data)
    const d = s.getByTestId('eb-deutung')
    expect(d).toHaveTextContent('Überwiegend sicher')
    expect(d).not.toHaveTextContent('Übungsbedarf zeigte')
    const teile = [...s.el.querySelectorAll('.eb-s2-teile')].map((x) => x.textContent)
    expect(teile.every((x) => x && /^\d+ sicher$/.test(x))).toBe(true)
  })

  it('nichtsSicher: nur der Übungs-Satz, Teile nur Übungsbedarf', () => {
    const s = seite2(FAELLE.nichtsSicher.data)
    const d = s.getByTestId('eb-deutung')
    expect(d).not.toHaveTextContent('Überwiegend sicher')
    expect(d).toHaveTextContent('Den meisten Übungsbedarf')
    expect(d).toHaveTextContent(/von \d+ geprüften Bereichen/)
    const teile = [...s.el.querySelectorAll('.eb-s2-teile')].map((x) => x.textContent)
    expect(teile.every((x) => x && /^\d+ Übungsbedarf$/.test(x))).toBe(true)
  })

  it('ohneName: Titel und Fußnote ohne Namen', () => {
    const s = seite2(FAELLE.ohneName.data)
    expect(s.getByRole('heading', { level: 1 })).toHaveTextContent('Der Lernstand in den geprüften Bereichen.')
    expect(s.el.querySelector('.eb-s2-profil-titel')).toHaveTextContent('Kompetenzprofil')
  })

  it('allesSicher: Profil nur mit geprüften Feldern', () => {
    const s = seite2(FAELLE.allesSicher.data)
    const zeilen = s.getAllByTestId('eb-profil-zeile')
    expect(zeilen).toHaveLength(6)
    for (const z of zeilen) expect(z.querySelector('.eb-s2-segment-uebung')).toBeNull()
  })
})

describe('Seite 2 — keine abgeleiteten Bereiche, Klassen je Zeile', () => {
  it('auch bei abgestufter LSA nur farbige Kästchen: keine Umrisse, keine Legende dazu, kein „abgeleitet“', () => {
    for (const name of ['abgestuft', 'abgestuftMitOffen', 'abgestuftLang'] as const) {
      const s = seite2(FAELLE[name].data)
      expect(s.el.querySelector('.eb-s2-segment-abgeleitet'), name).toBeNull()
      expect(s.el.querySelector('.eb-s2-legende')?.textContent, name).toBe('SicherÜbungsbedarf')
      expect(s.el.textContent, name).not.toMatch(/abgeleitet|ergeben sich|ergibt sich/i)
    }
  })

  it('rechte Zeile nur mit „geprüft“ und den Teilen', () => {
    const zeilen = seite2(FAELLE.abgestuft.data).getAllByTestId('eb-profil-zeile')
    const rechts = (i: number): (string | null)[] =>
      [...zeilen[i].querySelectorAll('.eb-s2-geprueft, .eb-s2-teile')].map((x) => x.textContent)
    expect(rechts(0)).toEqual(['1 geprüft', '1 sicher'])
    expect(rechts(1)).toEqual(['3 geprüft', '2 sicher · 1 Übungsbedarf'])
  })

  it('Vorlesetext ohne Zusatz zu Abgeleitetem', () => {
    const zeilen = seite2(FAELLE.abgestuft.data).getAllByTestId('eb-profil-zeile')
    for (const z of zeilen) expect(z.querySelector('.sr-only')?.textContent).not.toMatch(/ergeben sich|abgeleitet/)
    expect(zeilen[1].querySelector('.sr-only')?.textContent).toBe(
      'Terme & Gleichungen: 3 geprüft, davon 2 sicher und 1 mit Übungsbedarf.',
    )
  })

  it('Klasse je Zeile: eine Stufe oder Spanne aus den geprüften Kästchen der Zeile', () => {
    const klassen = (data: ReportData): (string | null)[] =>
      seite2(data)
        .getAllByTestId('eb-profil-zeile')
        .map((z) => z.querySelector('[data-testid="eb-profil-klasse"]')?.textContent ?? null)
    expect(klassen(FAELLE.ilkay.data)).toEqual([
      'Klasse 6',
      'Klasse 7',
      'Klasse 7–8',
      'Klasse 5–7',
      'Klasse 5–6',
      'Klasse 5–7',
    ])
  })

  it('Kopf: ein Kästchen je Bereich', () => {
    expect(seite2(FAELLE.ilkay.data).el.querySelector('.eb-s2-profil-hinweis')).toHaveTextContent(
      'Jedes Kästchen steht für einen Bereich',
    )
  })

  it('Zeilen mit zehn oder mehr Kästchen rücken die Spur zusammen (206 pt), kürzere nicht', () => {
    const breite = (data: ReportData): number =>
      Number(seite2(data).getAllByTestId('eb-profil-zeile')[0].querySelector('rect')!.getAttribute('width'))
    // sehrViele: Zeilen mit weit über zehn Bereichen.
    expect(breite(FAELLE.sehrViele.data)).toBeLessThan(breite(FAELLE.klasse7.data))
  })
})

describe('Seite 2 — Warum auch frühere Klassen?', () => {
  const warum = (data: ReportData) => seite2(data).queryByTestId('eb-warum')

  it('ab Klasse 6 (frühere Klassen ab 5) mit der Obergrenze Klasse − 1', () => {
    expect(warum(FAELLE.ilkay.data)).toHaveTextContent('Warum auch frühere Klassen?')
    expect(warum(FAELLE.ilkay.data)).toHaveTextContent('Bereiche aus Klasse 5 bis 9 geprüft')
    expect(warum(FAELLE.klasse7.data)).toHaveTextContent('Bereiche aus Klasse 5 bis 6 geprüft')
    expect(warum(FAELLE.abgestuft.data)).toHaveTextContent('Klasse 5 bis 8')
  })

  it('Klasse 5 hat keine früheren Klassen: Kasten entfällt', () => {
    expect(warum({ ...FAELLE.klasse7.data, grade: 5 })).toBeNull()
  })
})

describe('Seite 2 — Was die Grafik zeigt (Bericht v2)', () => {
  const text = (data: ReportData): string | undefined =>
    seite2(data).el.querySelector('.eb-s2-deutung-text')?.textContent ?? undefined

  it('abgestuft (Batu): Anteil Übungsbedarf statt Anzahl, ohne Coach-Satz', () => {
    expect(text(FAELLE.abgestuft.data)).toBe(
      'Überwiegend sicher war das Themenfeld Terme & Gleichungen. Den meisten Übungsbedarf zeigte das Themenfeld Geometrie: 3 von 3 geprüften Bereichen.',
    )
  })

  it('in keinem Fall ein Coach-Satz auf Seite 2', () => {
    for (const [fall, { data }] of Object.entries(FAELLE).filter(([f]) => f !== 'ohneKatalog')) {
      expect(text(data) ?? '', fall).not.toMatch(/Coach/)
    }
  })

  it('je Feld nur ein geprüfter Bereich: kein Satz, Absatz entfällt, Kicker und Fußnote bleiben', () => {
    const urteile = ['bruch_kuerzen', 'geo_umfang', 'prozent_grundwert'].map((k) => ({
      ...ILKAY_URTEILE.find((x) => x.skillKey === k)!,
      zustand: 'traegt_nicht',
    }))
    const s = seite2(datenAus({ ...ILKAY_ROH, urteile }))
    expect(s.getAllByTestId('eb-profil-zeile')).toHaveLength(3)
    expect(s.el.querySelector('.eb-s2-zahl-uebung .eb-s2-zahl')).toHaveTextContent('3')
    const d = s.getByTestId('eb-deutung')
    expect(d.querySelector('.eb-s2-deutung-text')).toBeNull()
    expect(d.querySelector('.eb-s2-deutung-kicker')).toHaveTextContent('Was die Grafik zeigt')
    expect(d.querySelector('.eb-s2-fussnote')).not.toBeNull()
  })
})
