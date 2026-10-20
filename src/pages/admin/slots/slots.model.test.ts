import { describe, expect, it } from 'vitest'
import { dieseWoche, montagVon, wocheVerschieben } from '@/components/edvance/wochenNavigation.model'
import type { SlotsKinderZeile } from '@/types/slotplan'
import {
  anzahlJeFilter, filterAusSuche, kinderGefiltert, kinderSortiert, planbilanzVariante,
  rechtzeitigVorschau, reiterAusSuche, sucheMitReiter,
} from './slots.model'

const kind = (name: string, art: SlotsKinderZeile['planbilanz']['art'], vertrag_laeuft = true, beginn = '2028-03-01'): SlotsKinderZeile =>
  ({ student_id: name, name, planbilanz: { art }, vertrag_laeuft, beginn } as unknown as SlotsKinderZeile)

describe('Kinder: Sortierung nach Handlungsbedarf, Filter, Suche', () => {
  const kinder = [kind('Zoe', 'passt'), kind('Ali', 'passt'), kind('Mia', 'kein_stammplatz'), kind('Ben', 'reicht_bis'),
    kind('Ida', 'aufgebraucht'), kind('Eva', 'ohne_termin')]
  it('kein Stammplatz, reicht bis, ohne Termin, aufgebraucht, passt — dann nach Namen', () => {
    expect(kinderSortiert(kinder).map((k) => k.name)).toEqual(['Mia', 'Ben', 'Eva', 'Ida', 'Ali', 'Zoe'])
  })
  it('gleiche Stufe: laufender Vertrag vor kommendem, dann frühester Beginn', () => {
    const ohne = [kind('Efe', 'kein_stammplatz', false, '2028-04-01'), kind('Mara', 'kein_stammplatz', false, '2028-03-20'),
      kind('Jonas', 'kein_stammplatz', true, '2028-03-01')]
    expect(kinderSortiert(ohne).map((k) => k.name)).toEqual(['Jonas', 'Mara', 'Efe'])
  })
  it('Filter-Chips und Suche', () => {
    expect(kinderGefiltert(kinder, 'reicht_nicht', '').map((k) => k.name)).toEqual(['Ben'])
    expect(kinderGefiltert(kinder, 'einheiten_uebrig', '').map((k) => k.name)).toEqual(['Eva'])
    expect(kinderGefiltert(kinder, 'passt', 'zo').map((k) => k.name)).toEqual(['Zoe'])
    expect(kinderGefiltert(kinder, 'alle', 'I').map((k) => k.name)).toEqual(['Mia', 'Ida', 'Ali'])
    expect(anzahlJeFilter(kinder)).toEqual({ alle: 6, kein_stammplatz: 1, reicht_nicht: 1, einheiten_uebrig: 1, aufgebraucht: 1, passt: 2 })
  })
  it('Farbe: kein Stammplatz ist Handeln nur bei laufendem Vertrag', () => {
    expect(planbilanzVariante('kein_stammplatz', true)).toBe('coach-emergency')
    expect(planbilanzVariante('kein_stammplatz', false)).toBe('warning')
    expect(planbilanzVariante('passt', true)).toBe('strength')
    expect(planbilanzVariante('aufgebraucht', true)).toBe('muted')
  })
})

describe('Reiter und Woche in der URL', () => {
  it('Reiter aus der Suche, Wochenplan als Standard, Unbekanntes fällt zurück', () => {
    expect(reiterAusSuche(new URLSearchParams(''))).toBe('wochenplan')
    expect(reiterAusSuche(new URLSearchParams('reiter=kinder'))).toBe('kinder')
    // W2: Den Reiter Stundenplan gibt es nicht mehr; die alte Adresse zeigt den Wochenplan.
    expect(reiterAusSuche(new URLSearchParams('reiter=stundenplan'))).toBe('wochenplan')
    expect(reiterAusSuche(new URLSearchParams('reiter=quatsch'))).toBe('wochenplan')
    expect(filterAusSuche(new URLSearchParams('reiter=kinder&filter=kein_stammplatz'))).toBe('kein_stammplatz')
  })
  it('Wechsel behält die Woche, der Filter gilt nur für Kinder', () => {
    const s = new URLSearchParams('woche=2028-03-13&reiter=kinder&filter=passt')
    expect(sucheMitReiter(s, 'coaches').toString()).toBe('woche=2028-03-13&reiter=coaches')
    expect(sucheMitReiter(s, 'wochenplan').toString()).toBe('woche=2028-03-13')
  })
  it('Wochenwechsel über den Jahreswechsel', () => {
    expect(wocheVerschieben('2027-12-27', 1)).toBe('2028-01-03')
    expect(wocheVerschieben('2028-01-03', -1)).toBe('2027-12-27')
    expect(montagVon('2028-01-01')).toBe('2027-12-27')
    expect(montagVon(dieseWoche())).toBe(dieseWoche())
  })
})

describe('10-Uhr-Regel als Vorschau (K 61)', () => {
  it('vor 10:00 am Termintag rechtzeitig, ab 10:00 nicht; Vortag immer rechtzeitig', () => {
    expect(rechtzeitigVorschau('2028-03-15', '18:40', '2028-03-16')).toBe(true)
    expect(rechtzeitigVorschau('2028-03-16', '09:59', '2028-03-16')).toBe(true)
    expect(rechtzeitigVorschau('2028-03-16', '10:00', '2028-03-16')).toBe(false)
  })
})
