// INV-4 · L5 (docs/report/Bauauftrag-L5.md, Entscheidung 12): Ist die Folge der Klassenarbeiten unbekannt, nennt
// kein Text eine Nummer „Klassenarbeit n“ — weder im Bericht v4 (alle fünf Seiten) noch in der Präsentation (alle
// Stationen mit Fahrplan). Seite 1 und Station 01 zeigen dann keine Ziffer im Fahrplan und nicht das Wort
// „Klassenarbeiten“ in dessen Überschrift. Geprüft über alle Fixtures mit Fahrplan.
import { cleanup, fireEvent, render } from '@testing-library/react'
import { afterEach, describe, expect, it } from 'vitest'
import '@/i18n'

import deElternbericht from '@/i18n/locales/de/elternbericht.json'
import dePraesentation from '@/i18n/locales/de/praesentation.json'
import { Station1V4 } from '@/components/edvance/praesentation/Station1V4'
import { Station2 } from '@/components/edvance/praesentation/Station2'
import { StationFoerderansatz } from '@/components/edvance/praesentation/StationFoerderansatz'
import { StationKlassenarbeiten } from '@/components/edvance/praesentation/StationKlassenarbeiten'
import { datenV4 } from '@/components/edvance/praesentation/testV4'
import { PRAESENTATION_FAELLE } from '@/lib/report/praesentation/fixtures'
import { berichtV4, bogenV4 } from '@/test/elternberichtV4'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'

afterEach(cleanup)

/** „Klassenarbeit 2“, „Klassenarbeit 2 und 3“, auch ohne Leerzeichen. */
const NUMMER = /Klassenarbeit\s*\d/

const folge = (name: string, faelle: typeof FAELLE): string | null => {
  const d = faelle[name].data
  if (d.erzaehlung.kompetenzen.length === 0) return null
  return berichtV4(d)?.fahrplan?.folge ?? null
}
const OHNE = Object.keys(FAELLE).filter((n) => folge(n, FAELLE) === 'unbekannt')
const OHNE_TP = Object.keys(PRAESENTATION_FAELLE).filter((n) => {
  try {
    return datenV4(n).v4.fahrplan.folge === 'unbekannt'
  } catch {
    return false
  }
})

describe('INV-4 · L5 · keine Nummer ohne bekannte Folge', () => {
  it('es gibt Fälle mit und ohne Folge', () => {
    expect(OHNE.length).toBeGreaterThan(8)
    expect(OHNE).toContain('batuV4')
    expect(OHNE).not.toContain('batuEigen')
    expect(OHNE_TP.length).toBeGreaterThan(8)
  })

  it.each(OHNE)('Bericht %s: keine „Klassenarbeit n“, keine Ziffer im Fahrplan, Überschrift ohne „Klassenarbeiten“', (name) => {
    const b = bogenV4(name)
    const text = b.container.textContent ?? ''
    expect(text).not.toMatch(NUMMER)
    const fp = b.seite(1).querySelector('[data-testid="eb-fahrplan"]')!
    expect(fp.querySelectorAll('.eb-fp-nr')).toHaveLength(0)
    // Ziffern nur im Trenner („Klasse 10“), nie in einem Kreis.
    const kreise = [...fp.querySelectorAll('[data-testid="eb-fp-punkt"]')]
    expect(kreise.length).toBeGreaterThan(1)
    for (const k of kreise) expect(k.textContent).toBe('')
    expect(fp.querySelector('h2')!.textContent).not.toMatch(/Klassenarbeiten/)
    for (const chip of b.container.querySelectorAll('.eb-leiste-punkt')) expect(chip.textContent).toBe('')
    for (const nr of b.container.querySelectorAll('.eb-s3v4-nr')) expect(nr.textContent).toBe('')
    for (const m of b.container.querySelectorAll('[data-testid="eb-marke"] b')) expect(m).toBeNull()
    expect(b.container.querySelector('[data-testid="eb-legende-nummer"]')).toBeNull()
    for (const sr of b.container.querySelectorAll('.sr-only')) expect(sr.textContent).not.toMatch(NUMMER)
  })

  it.each(OHNE_TP)('Präsentation %s: keine „Klassenarbeit n“, Station 01 ohne Ziffer und ohne „Klassenarbeiten“', (name) => {
    const { props } = datenV4(name)
    for (const Station of [Station1V4, Station2, StationKlassenarbeiten, StationFoerderansatz]) {
      const r = render(
        <section className="tp-station entered">
          <Station {...props} />
        </section>,
      )
      // Station 02: alle Details aufklappen; Station 04: jeden Punkt anwählen.
      for (const k of r.container.querySelectorAll<HTMLElement>('[data-tp-zeile] [aria-expanded], [role="tab"]')) {
        fireEvent.click(k)
        expect(r.container.textContent, `${name}`).not.toMatch(NUMMER)
      }
      expect(r.container.textContent, name).not.toMatch(NUMMER)
      if (Station === Station1V4) {
        for (const p of r.container.querySelectorAll('[data-testid="tp-fp-punkt"]')) expect(p.textContent).toBe('')
        expect(r.container.querySelector('[data-testid="tp-fahrplan"] h2')!.textContent).not.toMatch(/Klassenarbeiten/)
      }
      r.unmount()
    }
  })

  it('die neuen Texte: keine Note, keine Prognose, kein „weil“, kein „trägt/tragen“', () => {
    const neu = [
      ...Object.entries(deElternbericht.v4.quelle),
      ['leiste.labelThema', deElternbericht.v4.leiste.labelThema],
      ['s1.fahrplanKickerThema', deElternbericht.v4.s1.fahrplanKickerThema],
      ['s1.satzFehltThema', deElternbericht.v4.s1.satzFehltThema],
      ['s1.satzErfuelltThema', deElternbericht.v4.s1.satzErfuelltThema],
      ['s3.kickerThema', deElternbericht.v4.s3.kickerThema],
      ['s3.titelThema', deElternbericht.v4.s3.titelThema],
      ['s3.rest.geschriebenThema', deElternbericht.v4.s3.rest.geschriebenThema],
      ['s3.rest.stehtThema', deElternbericht.v4.s3.rest.stehtThema],
      ['s3.ka.wiederThema_one', deElternbericht.v4.s3.ka.wiederThema_one],
      ['s4.titelThema', deElternbericht.v4.s4.titelThema],
      ['s4.voraussetzungThema', deElternbericht.v4.s4.voraussetzungThema],
      ['s5.fazit.fahrplanThema_other', deElternbericht.v4.s5.fazit.fahrplanThema_other],
      ['tp.s3.titelThema', dePraesentation.v4.s3.titelThema],
      ['tp.s3.karteThema', dePraesentation.v4.s3.karteThema],
      ['tp.s3.karteZu', dePraesentation.v4.s3.karteZu],
      ['tp.s4.descThema', dePraesentation.v4.s4.descThema],
    ] as [string, string][]
    for (const [key, s] of neu) {
      expect(s, key).not.toMatch(NUMMER)
      expect(s, key).not.toMatch(/\bweil\b|tr(ä|ae)gt|tragen|\bNote\b|erwart|prognos|voraussichtlich/i)
    }
  })
})
