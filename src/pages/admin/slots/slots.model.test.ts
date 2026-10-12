import { describe, expect, it } from 'vitest'
import { dieseWoche, montagVon, wocheVerschieben } from '@/components/edvance/wochenNavigation.model'
import type { SlotsKinderZeile, SlotsWoche, WocheZelle } from '@/types/slotplan'
import {
  anzahlJeFilter, filterAusSuche, kinderGefiltert, kinderSortiert, leereZeiten, planbilanzVariante, raumBelegung,
  rechtzeitigVorschau, reiterAusSuche, sucheMitReiter, zellZustand,
} from './slots.model'

const zelle = (teil: Partial<WocheZelle>): WocheZelle => ({
  datum: '2028-03-16', zeit_id: 'z16', kapazitaet: 10, belegt: 4, ohne_raum: 0, coach_fehlt: 0, raeume: [], faecher: [], vergangen: false, ...teil,
})

describe('Zellzustand (Bauauftrag SL2, Test 1)', () => {
  it('normal, ab 90 %, überbucht, Coach fehlt, kein Raum', () => {
    expect(zellZustand(zelle({ belegt: 4 }))).toBe('normal')
    expect(zellZustand(zelle({ belegt: 9 }))).toBe('achtung')
    expect(zellZustand(zelle({ belegt: 10 }))).toBe('achtung')
    expect(zellZustand(zelle({ belegt: 7, kapazitaet: 5, ohne_raum: 2 }))).toBe('handeln')
    expect(zellZustand(zelle({ belegt: 3, kapazitaet: 5, coach_fehlt: 1 }))).toBe('handeln')
    expect(zellZustand(zelle({ belegt: 0, kapazitaet: 0 }))).toBe('leer')
  })

  it('vergangen ändert den Zustand nicht (die Zelle ist nur gedämpft)', () => {
    expect(zellZustand(zelle({ belegt: 9, vergangen: true }))).toBe('achtung')
  })

  it('Platz-Punkte je geöffnetem Raum', () => {
    const z = zelle({
      raeume: [
        { raum_id: 'r1', name: 'Raum 1', offen: true, art: 'stamm', coach_id: 'c1', belegt: 5 },
        { raum_id: 'r2', name: 'Raum 2', offen: false, art: 'faellt_aus', coach_id: null, belegt: 0 },
        { raum_id: 'r3', name: 'Raum 3', offen: true, art: 'zusatz', coach_id: 'c3', belegt: 2 },
      ],
    })
    expect(raumBelegung(z)).toEqual([5, 2])
  })
})

describe('leere Zeitzeilen fallen zusammen', () => {
  const woche = {
    montag: '2028-03-13', kw: 11, a_woche: true, heute: '2028-03-13', tage: [],
    zeiten: [{ id: 'z14', beginn: '14:00', ende: '15:00' }, { id: 'z16', beginn: '16:00', ende: '17:00' }, { id: 'z19', beginn: '19:00', ende: '20:00' }],
    zellen: [
      zelle({ zeit_id: 'z14', kapazitaet: 0, belegt: 0 }),
      zelle({ zeit_id: 'z16' }),
      zelle({ zeit_id: 'z19', kapazitaet: 0, belegt: 0, datum: '2028-03-13' }),
      zelle({ zeit_id: 'z19', kapazitaet: 0, belegt: 1, datum: '2028-03-14' }),
    ],
    kopf: { plaetze: 0, belegt: 0, auslastung: null, ohne_raum: 0, erster_ohne_raum: null, ohne_stammplatz: 0, ohne_stammplatz_laufend: 0 },
  } satisfies SlotsWoche
  it('nur Uhrzeiten ohne geöffneten Raum und ohne Kind in der ganzen Woche', () => {
    expect([...leereZeiten(woche)]).toEqual(['z14'])
  })
})

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
