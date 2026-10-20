// Seite 2 des Eltern-Berichts R7 (Lernstand) für die Fixture-Fälle.
import { render, within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import '@/i18n'

import { ElternberichtBogen } from '@/components/edvance/elternbericht/Bogen'
import { Profil } from '@/components/edvance/elternbericht/Profil'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import type { ReportData, ThemenfeldKey } from '@/types'

function seite2(data: ReportData) {
  const { container } = render(<ElternberichtBogen data={data} notes={null} tiers={[]} />)
  const el = container.querySelector<HTMLElement>('.eb-seite[data-seite="2"]')!
  return { ...within(el), el }
}

describe('Seite 2 — ilkay', () => {
  const s = (): ReturnType<typeof seite2> => seite2(FAELLE.ilkay.data)

  it('Titel mit Genitiv, Intro nur mit Geprüftem', () => {
    expect(s().getByRole('heading', { level: 1 })).toHaveTextContent(
      'Ilkays Lernstand in den untersuchten Bereichen.',
    )
    expect(s().el.querySelector('.eb-s2-intro')?.textContent).toBe(
      'Geprüft: 27 Bereiche. Davon 11 sicher, 16 mit Übungsbedarf.',
    )
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
    expect(el.querySelector('.eb-s2-eng')).toBeNull()
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

  it('Fußnote: ein Kästchen je geprüftem Bereich, ohne Zusatz zu Abgeleitetem', () => {
    const fussnote = s().el.querySelector('.eb-s2-fussnote')
    expect(fussnote).toHaveTextContent(
      'Jedes Kästchen steht für einen geprüften Bereich. Das ist keine Note und kein Prozentwert.',
    )
    expect(fussnote).not.toHaveTextContent('Umrandete Kästchen')
  })

  it('Was die Grafik zeigt: zwei Sätze und der Coach', () => {
    expect(s().getByTestId('eb-deutung')).toHaveTextContent(
      'Überwiegend sicher waren die Themenfelder Größen und Zahlen & Rechnen. Den meisten Übungsbedarf zeigten die Themenfelder Geometrie und Brüche & Dezimalzahlen. Ob dahinter ein gemeinsames Muster liegt, prüft der Coach in den ersten Sitzungen.',
    )
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
    expect(d).not.toHaveTextContent('prüft der Coach')
    const teile = [...s.el.querySelectorAll('.eb-s2-teile')].map((x) => x.textContent)
    expect(teile.every((x) => x && /^\d+ sicher$/.test(x))).toBe(true)
  })

  it('nichtsSicher: nur der Übungs-Satz, Teile nur Übungsbedarf', () => {
    const s = seite2(FAELLE.nichtsSicher.data)
    const d = s.getByTestId('eb-deutung')
    expect(d).not.toHaveTextContent('Überwiegend sicher')
    expect(d).toHaveTextContent('Den meisten Übungsbedarf')
    const teile = [...s.el.querySelectorAll('.eb-s2-teile')].map((x) => x.textContent)
    expect(teile.every((x) => x && /^\d+ Übungsbedarf$/.test(x))).toBe(true)
  })

  it('ohneName: Titel und Fußnote ohne Namen', () => {
    const s = seite2(FAELLE.ohneName.data)
    expect(s.getByRole('heading', { level: 1 })).toHaveTextContent(
      'Der Lernstand in den untersuchten Bereichen.',
    )
    expect(s.el.querySelector('.eb-s2-profil-titel')).toHaveTextContent('Kompetenzprofil')
  })

  it('allesSicher: Profil nur mit geprüften Feldern', () => {
    const s = seite2(FAELLE.allesSicher.data)
    const zeilen = s.getAllByTestId('eb-profil-zeile')
    expect(zeilen).toHaveLength(6)
    for (const z of zeilen) expect(z.querySelector('.eb-s2-segment-uebung')).toBeNull()
  })
})

describe('Seite 2 — abgeleitete Bereiche und Klassen (R7-8)', () => {
  const umrisse = (el: HTMLElement): number => el.querySelectorAll('.eb-s2-segment-abgeleitet').length
  const profilVon = (el: HTMLElement): HTMLElement => el.querySelector('[data-testid="eb-profil"]')!

  it('Umrisse nur bei abgestufter LSA; Summe = Thema-Satz (9 bzw. 5)', () => {
    // Die Legende trägt ein eigenes Umriss-Kästchen; gezählt werden die Zeilen.
    const inZeilen = (data: ReportData): number =>
      seite2(data).getAllByTestId('eb-profil-zeile').reduce((n, z) => n + umrisse(z), 0)
    expect(inZeilen(FAELLE.abgestuft.data)).toBe(9)
    expect(inZeilen(FAELLE.abgestuftMitOffen.data)).toBe(5)
    expect(umrisse(profilVon(seite2(FAELLE.ilkay.data).el))).toBe(0)
  })

  it('Umrisse ohne Farbe, Zustand oder Label: hinter den farbigen, gleiche Lage im Raster', () => {
    const zeile = seite2(FAELLE.abgestuft.data).getAllByTestId('eb-profil-zeile')[0]
    const rects = [...zeile.querySelectorAll('rect')]
    expect(rects.map((r) => r.getAttribute('class'))).toEqual([
      'eb-s2-segment-sicher',
      ...Array(4).fill('eb-s2-segment-abgeleitet'),
    ])
    for (const r of rects.slice(1)) {
      expect(r.getAttribute('fill')).toBeNull()
      expect(r.getAttribute('aria-label')).toBeNull()
    }
    // Neun Kästchen in der längsten Zeile (Zahlen & Rechnen), mit abgeleiteten
    // Bereichen auf 206 pt Spur: (206 − 8 · 4) / 9.
    const breite = (206 - 8 * 4) / 9
    expect(Number(rects[0].getAttribute('width'))).toBeCloseTo(breite)
    expect(Number(rects[1].getAttribute('x'))).toBeCloseTo(breite + 4 + 0.35)
    expect(Number(rects[1].getAttribute('width'))).toBeCloseTo(breite - 0.7)
  })

  it('rechte Zeile mit „abgeleitet“, zweite Zeile nur direkt', () => {
    const zeilen = seite2(FAELLE.abgestuft.data).getAllByTestId('eb-profil-zeile')
    const rechts = (i: number): (string | null)[] =>
      [...zeilen[i].querySelectorAll('.eb-s2-geprueft, .eb-s2-teile')].map((x) => x.textContent)
    expect(rechts(0)).toEqual(['1 geprüft · 4 abgeleitet', '1 sicher'])
    expect(rechts(1)).toEqual(['3 geprüft', '2 sicher · 1 Übungsbedarf'])
    expect(rechts(3)).toEqual(['4 geprüft · 5 abgeleitet', '1 sicher · 3 Übungsbedarf'])
  })

  it('ein Feld nur mit abgeleiteten Bereichen: nur Umrisse, nur „abgeleitet“', () => {
    const zeile = seite2(FAELLE.abgestuftMitOffen.data).getAllByTestId('eb-profil-zeile')[0]
    expect(zeile).toHaveTextContent('Brüche & Dezimalzahlen')
    expect(zeile.querySelectorAll('rect')).toHaveLength(2)
    expect(umrisse(zeile)).toBe(2)
    expect(zeile.querySelector('.eb-s2-geprueft')).toHaveTextContent(/^2 abgeleitet$/)
    expect(zeile.querySelector('.eb-s2-teile')).toBeEmptyDOMElement()
    expect(zeile.querySelector('.sr-only')).toHaveTextContent(
      'Brüche & Dezimalzahlen: nicht einzeln geprüft, 2 Bereiche ergeben sich aus den Aufgaben.',
    )
  })

  it('Vorlesetext: wie bisher, bei abgeleiteten mit Zusatz', () => {
    const zeilen = seite2(FAELLE.abgestuft.data).getAllByTestId('eb-profil-zeile')
    expect(zeilen[3].querySelector('.sr-only')).toHaveTextContent(
      'Zahlen & Rechnen: 4 geprüft, davon 1 sicher und 3 mit Übungsbedarf. 5 weitere ergeben sich aus den Aufgaben.',
    )
    expect(zeilen[1].querySelector('.sr-only')?.textContent).toBe(
      'Terme & Gleichungen: 3 geprüft, davon 2 sicher und 1 mit Übungsbedarf.',
    )
  })

  it('Klasse je Zeile: eine Stufe oder Spanne aus allen Kästchen der Zeile', () => {
    const klassen = (data: ReportData): (string | null)[] =>
      seite2(data)
        .getAllByTestId('eb-profil-zeile')
        .map((z) => z.querySelector('[data-testid="eb-profil-klasse"]')?.textContent ?? null)
    expect(klassen(FAELLE.abgestuft.data)).toEqual([
      'Klasse 5–6',
      'Klasse 8',
      'Klasse 8',
      'Klasse 5–9',
      'Klasse 8',
    ])
    expect(klassen(FAELLE.ilkay.data)).toEqual([
      'Klasse 6',
      'Klasse 7',
      'Klasse 7–8',
      'Klasse 5–7',
      'Klasse 5–6',
      'Klasse 5–7',
    ])
  })

  it('Legende mit drittem Eintrag nur bei abgeleiteten', () => {
    const legende = (data: ReportData): HTMLElement => seite2(data).el.querySelector('.eb-s2-legende')!
    expect(legende(FAELLE.abgestuft.data).textContent).toBe('SicherÜbungsbedarfAus den Aufgaben abgeleitet')
    expect(umrisse(legende(FAELLE.abgestuft.data))).toBe(1)
    expect(legende(FAELLE.ilkay.data).textContent).toBe('SicherÜbungsbedarf')
  })

  it('Fußnote mit Zusatz nur bei abgeleiteten', () => {
    expect(seite2(FAELLE.abgestuft.data).el.querySelector('.eb-s2-fussnote')).toHaveTextContent(
      'Über Bereiche, die nicht geprüft wurden, sagt dieser Bericht nichts. Umrandete Kästchen sind Bereiche des Themas, die sich aus den geprüften Aufgaben ergeben. Sie wurden nicht einzeln geprüft und tragen deshalb keine Farbe.',
    )
  })

  it('Kopf: ein Kästchen je Bereich', () => {
    expect(seite2(FAELLE.ilkay.data).el.querySelector('.eb-s2-profil-hinweis')).toHaveTextContent(
      'Jedes Kästchen steht für einen Bereich',
    )
  })
})
