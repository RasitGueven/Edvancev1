// Bericht v4, V4-2: Seite 4 — Lernpfad nach Klassenarbeiten.
import { within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import '@/i18n'

import de from '@/i18n/locales/de/elternbericht.json'
import { bogenV4, MIT_FAHRPLAN } from '@/test/elternberichtV4'

describe('Seite 4 mit Fahrplan', () => {
  for (const fall of MIT_FAHRPLAN) {
    it(`${fall}: ohne Fehlermuster, ohne Kurve, ohne „bis“ vor „Klassenarbeit“`, () => {
      const b = bogenV4(fall)
      const s4 = b.seite(4)
      const text = s4.textContent ?? ''
      expect(text, fall).not.toContain(de.s4.muster.kicker)
      expect(text, fall).not.toMatch(/Rechenweg stimmte|fehlende Sorgfalt|Fehler/)
      expect(text, fall).not.toMatch(/bis\s+(zur\s+|zu\s+|zum\s+)?(der\s+)?Klassenarbeit/i)
      expect(s4.querySelector('.eb-s4-kurve'), fall).toBeNull()
      expect(within(s4).queryByTestId('eb-fazit'), fall).toBeNull()
    })
  }

  it('batuEigen: ein Punkt je Eintrag aus bericht.lernpfad, Marke mit Nummer und Kurztitel', () => {
    const b = bogenV4('batuEigen')
    const f = b.bericht.fahrplan!
    const lernpfad = b.bericht.lernpfad!
    const s4 = within(b.seite(4))
    const punkte = s4.getAllByTestId('eb-lernpfad-punkt')
    expect(punkte).toHaveLength(lernpfad.filter((p) => p.art !== 'spaeter').length)
    punkte.forEach((el, i) => {
      const p = lernpfad[i]
      const marke = el.querySelector('.eb-s4v4-marke')!
      if (p.ziele.length > 0) {
        const station = f.stationen.find((s) => s.nummer === p.ziele[0])!
        expect(marke.querySelector('b')).toHaveTextContent(String(station.ka))
        expect(marke).toHaveTextContent(station.titel)
        expect(marke).toHaveTextContent(de.v4.s4.fuer)
      }
      expect(el.querySelector('.eb-s4v4-zeile')!.textContent).toContain(`Schritt ${i + 1}`)
    })
  })

  it('batuV4 (L5, Folge unbekannt): Marke ohne Nummer, „Voraussetzung für „Thema““', () => {
    const b = bogenV4('batuV4')
    const s4 = b.seite(4)
    expect(s4.querySelector('[data-testid="eb-lernpfad-punkt"] .eb-s4v4-marke b')).toBeNull()
    const zeilen = [...s4.querySelectorAll('.eb-s4v4-zeile')].map((z) => z.textContent)
    expect(zeilen.some((z) => /Voraussetzung für „[^“]+“ und „[^“]+“/.test(z!))).toBe(true)
    expect(zeilen.some((z) => /Voraussetzung für „[^“]+“$/.test(z!))).toBe(true)
    expect(s4.textContent).not.toMatch(/Klassenarbeit \d/)
    expect(within(s4).getByText(de.v4.s4.titelThema)).toBeInTheDocument()
  })

  it('batuEigen: „Voraussetzung für Klassenarbeit n“, bei zwei Zielen „n und m“, Gruppe „Grundlagen für …“', () => {
    const b = bogenV4('batuEigen')
    const s4 = b.seite(4)
    const zeilen = [...s4.querySelectorAll('.eb-s4v4-zeile')].map((z) => z.textContent)
    expect(zeilen.some((z) => /Voraussetzung für Klassenarbeit \d+ und \d+/.test(z!))).toBe(true)
    expect(zeilen.some((z) => /Voraussetzung für Klassenarbeit \d+$/.test(z!))).toBe(true)
    expect(s4.textContent).toContain('Grundlagen für „Kreise, Prismen und Zylinder“')
  })

  it('„Das üben wir“ nennt höchstens vier Bereiche, danach „+n weitere“', () => {
    const b = bogenV4('batuV4')
    const lernpfad = b.bericht.lernpfad!.filter((p) => p.art !== 'spaeter')
    within(b.seite(4))
      .getAllByTestId('eb-uebt')
      .forEach((kasten, i) => {
        const chips = [...kasten.querySelectorAll('li:not(.eb-s4v4-chips-mehr)')]
        expect(chips.length).toBeLessThanOrEqual(4)
        expect(chips.map((c) => c.textContent)).toEqual(lernpfad[i].teile)
        const mehr = kasten.querySelector('.eb-s4v4-chips-mehr')
        if (lernpfad[i].rest > 0) expect(mehr).toHaveTextContent(`+${lernpfad[i].rest} weitere`)
        else expect(mehr).toBeNull()
      })
  })

  it('der letzte Punkt ist grau: „Wenn der Schulstoff sitzt“ mit den Feldern aus „danach“', () => {
    const b = bogenV4('batuV4')
    const spaeter = within(b.seite(4)).getByTestId('eb-lernpfad-spaeter')
    expect(spaeter).toHaveTextContent(de.v4.s4.spaeter)
    expect(spaeter).toHaveTextContent(de.v4.s4.spaeterTitel)
    expect(spaeter).toHaveTextContent('Daten & Zufall')
    expect(spaeter.parentElement!.lastElementChild).toBe(spaeter)
  })

  it('die Reihenfolge der Punkte entspricht der Reihenfolge der Schwerpunkte (v3)', () => {
    const b = bogenV4('batuV4')
    const titel = [...b.seite(4).querySelectorAll('[data-testid="eb-lernpfad-punkt"] h3')].map((h) => h.textContent)
    const lernpfad = b.bericht.lernpfad!.filter((p) => p.art !== 'spaeter')
    expect(titel).toHaveLength(lernpfad.length)
    // Das erste Thema ist das Feld des ersten Schwerpunkts (v3-Reihenfolge).
    expect(titel[0]).toBe(de.feld[b.bericht.schwerpunkte[0].feld ?? 'weitere'])
  })

  it('das Intro richtet sich nach dem Stand der Klassenarbeit', () => {
    const thema = (fall: string): string => bogenV4(fall).bericht.fahrplan!.stationen[0].titel
    expect(within(bogenV4('batuV4').seite(4)).getByTestId('eb-s4-intro').textContent).toBe(
      `Die Arbeit zu „${thema('batuV4')}“ ist geschrieben. Deshalb beginnen wir mit den Voraussetzungen für das nächste Thema und arbeiten uns dann zu den folgenden vor.`,
    )
    expect(within(bogenV4('batuBevorstehend').seite(4)).getByTestId('eb-s4-intro').textContent).toContain('steht noch an')
    expect(within(bogenV4('batuOhneStatus').seite(4)).getByTestId('eb-s4-intro').textContent).toBe(
      'Wir beginnen mit dem aktuellen Thema und nehmen danach die Voraussetzungen für die folgenden Themen.',
    )
    expect(within(bogenV4('batuEigen').seite(4)).getByTestId('eb-s4-intro').textContent).toContain('für die nächste Arbeit')
  })

  it('„Unser Ansatz“ und „Was dazu gehört“ nebeneinander, die Coach-Fußnote bleibt', () => {
    const b = bogenV4('batuV4')
    const s4 = within(b.seite(4))
    const ansatz = s4.getByTestId('eb-ansatz')
    expect(ansatz).toHaveTextContent(de.v4.s4.ansatzTitel)
    expect(ansatz).toHaveTextContent(de.v4.s4.ansatz)
    expect(ansatz).toHaveTextContent(de.v4.s4.dazuTitel)
    expect(ansatz.querySelectorAll('li')).toHaveLength(4)
    expect(ansatz).toHaveTextContent('Ilkays Stärken und Lücken')
    expect(ansatz).toHaveTextContent(de.v4.s4.dazu4)
    expect(ansatz.textContent).not.toMatch(/Wir verstehen/)
    expect(b.seite(4).querySelector('.eb-s4-stand')).toHaveTextContent(de.s4.coach)
  })

  it('ohnePlan: Seite 4 wie v3 (Kurve, kein Lernpfad nach Klassenarbeiten)', () => {
    const b = bogenV4('ohnePlan')
    expect(within(b.seite(4)).queryByTestId('eb-lernpfad')).toBeNull()
    expect(within(b.seite(4)).queryByTestId('eb-ansatz')).toBeNull()
  })
})
