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
    // Feste Breite 18 pt, linksbündig.
    const rects = [...erste.querySelectorAll('rect')]
    expect(rects.map((r) => r.getAttribute('width'))).toEqual(Array(5).fill('18'))
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

  it('Fußnote: ein Segment je geprüftem Bereich', () => {
    expect(s().el.querySelector('.eb-s2-fussnote')).toHaveTextContent(
      'Jedes Segment steht für einen geprüften Bereich. Das ist keine Note und kein Prozentwert.',
    )
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
            (feld) => ({ feld: feld as ThemenfeldKey, vorhanden: 4, sicher: 1, uebung: 1 }),
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
