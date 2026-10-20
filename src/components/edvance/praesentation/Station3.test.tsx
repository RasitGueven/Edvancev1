// Station 03 · Einordnung (T4, Entscheidung 8): Pyramide aus p.pyramide mit
// Klassenangabe, Zählung je Zählweise, Breiten- und Lückenklassen, Lesehilfe.
// Kontrollwerte aus Anhang C der Anforderung.
import { screen, within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import '@/i18n'

import { PRAESENTATION_FAELLE } from '@/lib/report/praesentation/fixtures'

import { breitenKlasse, lueckenKlasse } from './Pyramide'
import { Station3 } from './Station3'
import { zeige } from './testStation34'

const { ilkay, klasse10neu, klasse7, spaeter, uebersprungen, ohneName } = PRAESENTATION_FAELLE

const ebenen = (): HTMLElement[] =>
  within(screen.getByRole('list', { name: 'Ergebnisse nach Stufen im Lernstoff' })).getAllByRole('listitem')

const titel = (li: HTMLElement): string => within(li).getByRole('heading', { level: 3 }).textContent ?? ''
const segmente = (li: HTMLElement, art: string): number => li.querySelectorAll(`.tp-s3-seg-${art}`).length

describe('Station 03 — Pyramide', () => {
  it('ilkay: zwei Ebenen nach Anhang C, von oben nach unten', () => {
    zeige(Station3, ilkay)
    const [oben, unten] = ebenen()
    expect(ebenen()).toHaveLength(2)

    expect(titel(oben)).toBe('Weiterführende Themen')
    expect(oben).toHaveTextContent('Klasse 7/8')
    expect(oben).toHaveTextContent('4 sicher')
    expect(oben).toHaveTextContent('8 Übungsbedarf')
    expect(oben).not.toHaveTextContent('übersprungen')
    expect(segmente(oben, 'sicher')).toBe(4)
    expect(segmente(oben, 'uebung')).toBe(8)

    expect(titel(unten)).toBe('Grundlagen')
    expect(unten).toHaveTextContent('Klasse 5/6')
    expect(segmente(unten, 'sicher')).toBe(7)
    expect(segmente(unten, 'uebung')).toBe(8)
    expect(within(unten).getByRole('img')).toHaveAccessibleName(
      'Grundlagen, Klasse 5/6: 7 sicher, 8 mit Übungsbedarf.',
    )
  })

  it('zeigt keine Namen von Bereichen', () => {
    zeige(Station3, ilkay)
    expect(screen.getByRole('list', { name: 'Ergebnisse nach Stufen im Lernstoff' })).not.toHaveTextContent(
      'Brüche',
    )
  })

  it('klasse10neu: drei Ebenen mit Klassenangaben', () => {
    zeige(Station3, klasse10neu)
    expect(ebenen().map(titel)).toEqual(['Aktueller Unterrichtsstoff', 'Weiterführende Themen', 'Grundlagen'])
    expect(ebenen().map((li) => li.querySelector('.tp-s3-pille')?.textContent)).toEqual([
      'Klasse 9/10',
      'Klasse 7/8',
      'Klasse 5/6',
    ])
  })

  it('klasse7: zwei Ebenen; spaeter: oben „Stoff späterer Klassen"', () => {
    const { unmount } = zeige(Station3, klasse7)
    expect(ebenen()).toHaveLength(2)
    unmount()
    zeige(Station3, spaeter)
    expect(titel(ebenen()[0])).toBe('Stoff späterer Klassen')
  })

  it('uebersprungen kombiniert: Übungsbedarf mit, „davon 3 übersprungen", Punktmuster', () => {
    zeige(Station3, uebersprungen, 'kombiniert')
    const [oben, unten] = ebenen()
    expect(oben).toHaveTextContent('4 sicher')
    expect(oben).toHaveTextContent('8 Übungsbedarf')
    expect(oben).toHaveTextContent('davon 3 übersprungen')
    expect(segmente(oben, 'uebung')).toBe(5)
    expect(segmente(oben, 'ueber')).toBe(3)
    expect(within(oben).getByRole('img')).toHaveAccessibleName(
      'Weiterführende Themen, Klasse 7/8: 4 sicher, 8 mit Übungsbedarf, davon 3 übersprungen.',
    )
    expect(unten).not.toHaveTextContent('übersprungen')
    expect(screen.getByRole('list', { name: 'Ergebnisse nach Stufen im Lernstoff' })).toHaveClass(
      'tp-s3-kombiniert',
    )
  })

  it('uebersprungen getrennt: 4 · 5 · 3 übersprungen', () => {
    zeige(Station3, uebersprungen, 'getrennt')
    const [oben] = ebenen()
    expect(oben).toHaveTextContent('5 Übungsbedarf')
    expect(oben).toHaveTextContent('3 übersprungen')
    expect(oben).not.toHaveTextContent('davon')
    expect(within(oben).getByRole('img')).toHaveAccessibleName(
      'Weiterführende Themen, Klasse 7/8: 4 sicher, 5 mit Übungsbedarf, 3 übersprungen.',
    )
    expect(screen.getByRole('list', { name: 'Ergebnisse nach Stufen im Lernstoff' })).toHaveClass(
      'tp-s3-getrennt',
    )
  })

  it('Breiten über feste Klassen: unten 100, darüber je 19 Punkte schmaler', () => {
    zeige(Station3, klasse10neu)
    const [oben, mitte, unten] = ebenen()
    expect(unten).toHaveClass('tp-s3-breite-0')
    expect(mitte).toHaveClass('tp-s3-breite-1')
    expect(oben).toHaveClass('tp-s3-breite-2')
    for (const li of ebenen()) expect(li.getAttribute('style') ?? '').not.toMatch(/width/)
    expect(breitenKlasse(5)).toBe('tp-s3-breite-3')
  })

  it('Lücke zwischen Segmenten: 4 px bis 16, 2 px bis 30, darüber 1 px', () => {
    expect(lueckenKlasse(16)).toBe('tp-s3-luecke-weit')
    expect(lueckenKlasse(17)).toBe('tp-s3-luecke-mittel')
    expect(lueckenKlasse(30)).toBe('tp-s3-luecke-mittel')
    expect(lueckenKlasse(31)).toBe('tp-s3-luecke-eng')
    zeige(Station3, ilkay)
    expect(ebenen()[1].querySelector('.tp-s3-spur')).toHaveClass('tp-s3-luecke-weit')
  })
})

describe('Station 03 — Texte', () => {
  it('Titel, Untertitel und Lesehilfe mit Namen', () => {
    zeige(Station3, ilkay)
    expect(screen.getByRole('heading', { level: 2 })).toHaveTextContent('Wo im Lernstoff die Themen liegen.')
    expect(screen.getByText(/Dieselben Ergebnisse/)).toBeInTheDocument()
    expect(screen.getByText('So ist die Pyramide aufgebaut')).toBeInTheDocument()
    expect(screen.getByText(/richtet sich nach Ilkays Klasse\./)).toBeInTheDocument()
    expect(
      screen.getByText('Die Pyramide zeigt, wo ein Bereich im Lernstoff liegt, keine feste Voraussetzung.'),
    ).toBeInTheDocument()
  })

  it('ohne Namen: „der Klasse Ihres Kindes"', () => {
    zeige(Station3, ohneName)
    expect(screen.getByText(/richtet sich nach der Klasse Ihres Kindes\./)).toBeInTheDocument()
  })

  it('sagt nirgends, dass eine Ebene auf einer anderen aufbaut', () => {
    const { container } = zeige(Station3, klasse10neu)
    expect(container).not.toHaveTextContent(/baut .*auf/)
  })
})
