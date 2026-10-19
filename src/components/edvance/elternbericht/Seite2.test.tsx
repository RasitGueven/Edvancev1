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

  it('Titel mit Genitiv, Intro mit nicht untersuchten Bereichen', () => {
    expect(s().getByRole('heading', { level: 1 })).toHaveTextContent(
      'Ilkays Lernstand in den untersuchten Bereichen.',
    )
    expect(s().el.querySelector('.eb-s2-intro')).toHaveTextContent(
      'Untersucht: 27 von 130 Bereichen des Katalogs. Davon 11 sicher, 16 mit Übungsbedarf. 103 Bereiche wurden nicht untersucht.',
    )
  })

  it('drei Zahlen sicher, Übungsbedarf, nicht untersucht', () => {
    const zahlen = [...s().el.querySelectorAll('.eb-s2-zahl')].map((z) => z.textContent)
    expect(zahlen).toEqual(['11', '16', '103'])
  })

  it('eine Profilzeile je Feld, Segmente je Kompetenz, enge Zeilen ab sieben', () => {
    const { el, getAllByTestId } = s()
    const zeilen = getAllByTestId('eb-profil-zeile')
    expect(zeilen).toHaveLength(8)
    expect(el.querySelector('.eb-s2-eng')).not.toBeNull()
    const erste = zeilen[0]
    expect(erste.querySelectorAll('.eb-s2-segment-sicher')).toHaveLength(2)
    expect(erste.querySelectorAll('.eb-s2-segment-uebung')).toHaveLength(3)
    expect(erste.querySelectorAll('.eb-s2-segment-offen')).toHaveLength(3)
    expect(erste.querySelector('.eb-s2-segment-schraffur')).toHaveAttribute('fill', 'url(#eb-schraffur)')
    expect(erste.querySelector('svg')).toHaveAttribute('aria-hidden', 'true')
    expect(erste.querySelector('svg')).toHaveAttribute('height', '33.4pt')
  })

  it('Vorlesetext und rechte Zeile je Feld', () => {
    const zeilen = s().getAllByTestId('eb-profil-zeile')
    expect(zeilen[0].querySelector('.sr-only')).toHaveTextContent(
      'Brüche & Dezimalzahlen: 5 von 8 untersucht, davon 2 sicher und 3 mit Übungsbedarf.',
    )
    const rechts = (i: number): (string | null)[] =>
      [...zeilen[i].querySelectorAll('.eb-s2-untersucht, .eb-s2-teile')].map((x) => x.textContent)
    expect(rechts(0)).toEqual(['5 von 8 untersucht', '2 sicher · 3 Übungsbedarf'])
    // Funktionen: nichts untersucht, nur die erste Zeile.
    expect(rechts(6)).toEqual(['0 von 20 untersucht'])
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

  it('Vorlesetext ohne untersuchten Bereich', () => {
    const zeilen = seite2(FAELLE.ilkay.data).getAllByTestId('eb-profil-zeile')
    expect(zeilen[6].querySelector('.sr-only')).toHaveTextContent('Funktionen: 0 von 20 untersucht.')
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
    expect(s.el.querySelector('.eb-s2-fussnote')).toHaveTextContent('sagen nichts über Ihr Kind aus.')
  })

  it('ohne nicht untersuchte Bereiche entfällt der Satz dazu', () => {
    const { data } = FAELLE.ilkay
    const katalog = data.erzaehlung.kompetenzen.map((k) => ({ skillKey: k.skillKey, klasse: 5 }))
    const s = seite2({ ...data, erzaehlung: { ...data.erzaehlung, katalog } })
    expect(s.el.querySelector('.eb-s2-intro')).not.toHaveTextContent('nicht untersucht')
  })
})
