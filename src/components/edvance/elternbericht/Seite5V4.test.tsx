// Bericht v4, V4-2: Seite 5 — Fazit, Ziele in Elternsprache, keine Noten.
import { within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import '@/i18n'

import de from '@/i18n/locales/de/elternbericht.json'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import { bogenV4, MIT_FAHRPLAN, NOTIZEN_ZIELE } from '@/test/elternberichtV4'

const ziele = (el: HTMLElement): string[] =>
  [...el.querySelectorAll('[data-testid="eb-ziele"] li')].map((li) => li.textContent!.replace(/^\d+/, ''))

describe('Seite 5 mit Fahrplan', () => {
  it('batuV4: Fazit aus Stufen, Lückenfeldern, Fahrplan und Start', () => {
    const b = bogenV4('batuV4')
    const fazit = within(b.seite(5)).getByTestId('eb-s5-fazit').textContent!
    expect(fazit).toContain('Ilkays Grundlagen aus Klasse 5/6 sitzen weitgehend.')
    expect(fazit).toContain('Die Lücken stammen vor allem aus Klasse 7/8, besonders bei Termen und Gleichungen sowie bei der Geometrie.')
    expect(fazit).toContain('Sie werden in den nächsten 3 Themen wieder gebraucht.')
    expect(within(bogenV4('batuEigen').seite(5)).getByTestId('eb-s5-fazit').textContent).toContain(
      'Sie werden in den nächsten 3 Klassenarbeiten wieder gebraucht.',
    )
    expect(fazit).toContain(de.v4.s5.fazit.sorgfalt)
    expect(fazit).toContain('Wir beginnen mit den Voraussetzungen für „Quadratische Funktionen“.')
    expect(within(b.seite(5)).getByTestId('eb-s5-fazit')).toHaveClass('eb-s5-fazit-v4')
  })

  it('batuV4: vier Ziele in Elternsprache aus zieleV4, nummeriert, darunter „Wir versprechen keine Noten“', () => {
    const b = bogenV4('batuV4', { notes: NOTIZEN_ZIELE })
    expect(ziele(b.seite(5))).toEqual([
      'Ilkay geht gut vorbereitet in das Thema „Quadratische Funktionen“, weil die Grundlagen dafür vorher sitzen.',
      'Wenn in der Schule „Kreise, Prismen und Zylinder“ und „Der Satz des Pythagoras und Berechnungen in Körpern“ drankommen, fängt Ilkay nicht bei null an, sondern baut auf sicherem Stoff auf.',
      'Ilkay kontrolliert die eigenen Rechnungen selbst und verliert weniger Punkte durch Flüchtigkeitsfehler.',
      de.v4.s5.ziele.weitere,
    ])
    expect([...b.seite(5).querySelectorAll('.eb-s5-ziel-nr')].map((n) => n.textContent)).toEqual(['1', '2', '3', '4'])
    expect(within(b.seite(5)).getByTestId('eb-keine-noten').textContent).toBe(
      'Wir versprechen keine Noten. Uns geht es darum, zu verstehen, woran es hakt, und Ilkay Schritt für Schritt voranzubringen.',
    )
  })

  it('L5 Teil D: ohne Bestätigung dieselben Ziele als „Unser Vorschlag“, „keine Noten“ darunter', () => {
    const notes = { ...NOTIZEN_ZIELE, zieleBestaetigt: false, zielbild: 'Ein Satz des Coachs.' }
    const b = bogenV4('batuV4', { notes })
    expect(ziele(b.seite(5))).toHaveLength(4)
    expect(ziele(b.seite(5))).not.toContain('Ein Satz des Coachs.')
    expect(within(b.seite(5)).getByTestId('eb-ziele-kicker')).toHaveTextContent('Unser Vorschlag: Ziele für die nächsten 6 Monate')
    expect(within(b.seite(5)).getByTestId('eb-keine-noten')).toBeInTheDocument()
  })

  it('L5 Teil D: das Zielbild des Coachs kommt bestätigt als fünftes Ziel dazu', () => {
    const b = bogenV4('batuV4', { notes: { ...NOTIZEN_ZIELE, zielbild: 'Ein Satz des Coachs.' } })
    const z = ziele(b.seite(5))
    expect(z).toHaveLength(5)
    expect(z[4]).toBe('Ein Satz des Coachs.')
    expect(within(b.seite(5)).getByTestId('eb-ziele-kicker')).toHaveTextContent('im Gespräch vereinbart')
  })

  it('L5: Folge bekannt → Ziel 1 „in Klassenarbeit 2 zu „Quadratische Funktionen““', () => {
    const b = bogenV4('batuEigen', { notes: NOTIZEN_ZIELE })
    expect(ziele(b.seite(5))[0]).toBe(
      'Ilkay geht gut vorbereitet in Klassenarbeit 2 zu „Quadratische Funktionen“, weil die Grundlagen dafür vorher sitzen.',
    )
  })

  it('ohne Namen die Fassungen mit „Ihr Kind“ (Ziele, keine Noten, Fazit)', () => {
    const b = bogenV4('batuV4', { notes: NOTIZEN_ZIELE, data: { ...FAELLE.batuV4.data, firstName: null } })
    const z = ziele(b.seite(5))
    expect(z).toHaveLength(4)
    expect(z[0]).toBe('Ihr Kind geht gut vorbereitet in das Thema „Quadratische Funktionen“, weil die Grundlagen dafür vorher sitzen.')
    expect(z[2]).toContain('Ihr Kind kontrolliert')
    expect(within(b.seite(5)).getByTestId('eb-keine-noten').textContent).toContain('und Ihr Kind Schritt für Schritt voranzubringen.')
    expect(within(b.seite(5)).getByTestId('eb-s5-fazit').textContent).not.toContain('Ilkay')
  })

  for (const fall of MIT_FAHRPLAN) {
    it(`${fall}: höchstens vier Ziele, nie Note, Prozent oder Prognose`, () => {
      const b = bogenV4(fall, { notes: NOTIZEN_ZIELE })
      const z = ziele(b.seite(5))
      expect(z.length, fall).toBeLessThanOrEqual(4)
      for (const satz of z) expect(satz, fall).not.toMatch(/%|Note\b|Prozent|sicher bestehen|\bbis\b/)
    })
  }

  it('allesErfuellt: kein „vorbereitet“-Ziel, stattdessen „baut auf dem auf, was schon sicher ist“', () => {
    const b = bogenV4('allesErfuellt', { notes: NOTIZEN_ZIELE })
    expect(ziele(b.seite(5)).join(' ')).not.toContain('geht gut vorbereitet')
    expect(ziele(b.seite(5))[0]).toContain('baut auf dem auf, was schon sicher ist')
  })

  it('Vorschlag, Mitgliedschaften und Kontakt wie v3, kein Preis ohne Schalter', () => {
    const b = bogenV4('batuV4', { notes: NOTIZEN_ZIELE })
    const s5 = within(b.seite(5))
    expect(s5.getAllByTestId('eb-paket')).toHaveLength(3)
    expect(s5.getByTestId('eb-vorschlag')).toBeInTheDocument()
    expect(s5.getByTestId('eb-kontakt')).toBeInTheDocument()
    expect(b.seite(5).textContent).not.toMatch(/€|Preis/)
  })
})
