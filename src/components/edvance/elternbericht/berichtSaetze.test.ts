// Bericht v2: die Satzbausteine für Seite 1, 3, 4 und 5 als reine Funktionen.
import { describe, expect, it } from 'vitest'
import i18n from '@/i18n'

import {
  anliegenSaetzeV2,
  grundText,
  lueckenFelder,
  schuleGenitiv,
  startSatz,
  stufenKlasse,
  stufenUrteil,
  ursachenSaetze,
} from '@/components/edvance/elternbericht/berichtSaetze'
import type { UrsachenAntwort } from '@/lib/report/elternbericht/ursache'
import type { EbProfilZeile, EbSchwerpunkt, EbStufenZeile, ReportErstgespraech, ThemenfeldKey } from '@/types'

const t = i18n.getFixedT('de', 'elternbericht')
const liste = (s: readonly string[]): string => new Intl.ListFormat('de', { style: 'long', type: 'conjunction' }).format(s)

const zeile = (stufe: EbStufenZeile['stufe'], urteil: EbStufenZeile['urteil'], von = 5, bis = 6): EbStufenZeile => ({
  stufe,
  urteil,
  von,
  bis,
  sicher: 1,
  uebung: 1,
})
const STUFEN = [zeile('grundlagen', 'weitgehend', 5, 6), zeile('weiterfuehrend', 'luecken', 7, 8), zeile('aktuell', 'gemischt', 9, 10)]

describe('stufenKlasse und stufenUrteil', () => {
  it('Grundlagen und Weiterführend haben feste Klassen, Aktuell die der Zeile', () => {
    expect(stufenKlasse(t, STUFEN[0])).toBe('Klasse 5/6')
    expect(stufenKlasse(t, STUFEN[1])).toBe('Klasse 7/8')
    expect(stufenKlasse(t, STUFEN[2])).toBe('Klasse 9/10')
    expect(stufenKlasse(t, zeile('aktuell', 'sicher', 9, 9))).toBe('Klasse 9')
  })

  it('Kurzsatz je Urteil; „weitgehend“ heißt beim aktuellen Stoff „fast sicher“', () => {
    expect(stufenUrteil(t, STUFEN[0])).toBe('sitzen weitgehend')
    expect(stufenUrteil(t, STUFEN[1])).toBe('hier liegen die Lücken')
    expect(stufenUrteil(t, STUFEN[2])).toBe('teils sicher, teils Übungsbedarf')
    expect(stufenUrteil(t, zeile('aktuell', 'weitgehend'))).toBe('fast sicher')
    expect(stufenUrteil(t, zeile('grundlagen', 'sicher'))).toBe('sicher')
  })
})

describe('anliegenSaetzeV2', () => {
  const ohne = { erstgespraech: null, ursachen: [], name: 'Ilkay', fach: 'Mathematik', liste }
  const eg = (teil: Partial<ReportErstgespraech>): ReportErstgespraech => ({
    note: null,
    trend: null,
    seit: null,
    ziele: null,
    klassenarbeit: null,
    klassenarbeitDatum: null,
    ...teil,
  })

  it('ohne Erstgespräch und Ursache keine Sätze', () => {
    expect(anliegenSaetzeV2(t, ohne)).toEqual([])
  })

  it('Note, Trend, Seit und Ursache in dieser Reihenfolge', () => {
    const s = anliegenSaetzeV2(t, {
      ...ohne,
      erstgespraech: eg({ note: '4', trend: 'schlechter', seit: 'letztes_schuljahr' }),
      ursachen: ['Grundlagen fehlen', 'Rechenwege'],
    })
    expect(s).toEqual([
      'Die letzte Zeugnisnote von Ilkay in Mathematik war eine 4.',
      'Zuletzt ist sie schlechter geworden.',
      'Die Schwierigkeiten gibt es seit dem letzten Schuljahr.',
      'Als Ursache vermuten Sie Grundlagen fehlen und Rechenwege.',
    ])
  })

  it('ohne Namen: Fassung ohne Namen', () => {
    const s = anliegenSaetzeV2(t, { ...ohne, name: null, erstgespraech: eg({ note: '3' }) })
    expect(s).toEqual(['Die letzte Zeugnisnote in Mathematik war eine 3.'])
  })

  it('Trend ohne Note entfällt (er bezöge sich auf nichts)', () => {
    expect(anliegenSaetzeV2(t, { ...ohne, erstgespraech: eg({ trend: 'besser' }) })).toEqual([])
  })

  it.each([
    ['dieses_halbjahr', 'Die Schwierigkeiten gibt es seit diesem Halbjahr.'],
    ['letztes_schuljahr', 'Die Schwierigkeiten gibt es seit dem letzten Schuljahr.'],
    ['laenger', 'Die Schwierigkeiten bestehen schon länger.'],
  ] as const)('Seit %s', (seit, satz) => {
    expect(anliegenSaetzeV2(t, { ...ohne, erstgespraech: eg({ seit }) })).toEqual([satz])
  })

  it.each([
    ['besser', 'Zuletzt ist sie besser geworden.'],
    ['stabil', 'Sie ist zuletzt gleich geblieben.'],
    ['schlechter', 'Zuletzt ist sie schlechter geworden.'],
  ] as const)('Trend %s', (trend, satz) => {
    expect(anliegenSaetzeV2(t, { ...ohne, erstgespraech: eg({ note: '2', trend }) })[1]).toBe(satz)
  })
})

describe('ursachenSaetze', () => {
  const a = (key: string, variante: UrsachenAntwort['variante'], rest: Partial<UrsachenAntwort> = {}): UrsachenAntwort => ({
    key,
    variante,
    ...rest,
  })

  it('Bausteine je Ursache und Variante, mit dem Namen', () => {
    expect(ursachenSaetze(t, [a('textverstaendnis', 'eherNicht')], STUFEN, 'Ilkay')).toEqual([
      'Aufgaben mit längerem Text löste Ilkay sicher. Die Schwierigkeiten liegen eher an anderer Stelle.',
    ])
    expect(ursachenSaetze(t, [a('textverstaendnis', 'eherNicht')], STUFEN, null)[0]).toContain('löste Ihr Kind sicher')
    expect(ursachenSaetze(t, [a('pruefungsangst', 'offen')], STUFEN, null)).toEqual([
      'Prüfungsangst lässt sich in einer Analyse ohne Notendruck nicht messen.',
    ])
  })

  it('Grundlagen bestätigt, Lücken in 7/8 und Basis sitzt: zwei Sätze', () => {
    const s = ursachenSaetze(
      t,
      [a('grundlagen', 'bestaetigt', { lueckenIn: 'weiterfuehrend', grundlagenSitzen: true })],
      STUFEN,
      null,
    )
    expect(s).toEqual([
      'Die Grundlagen aus Klasse 5/6 sitzen weitgehend.',
      'Die Lücken liegen vor allem im Stoff von Klasse 7/8.',
    ])
  })

  it('Grundlagen bestätigt, Basis sitzt nicht: nur der Lückensatz', () => {
    const s = ursachenSaetze(t, [a('grundlagen', 'bestaetigt', { lueckenIn: 'aktuell', grundlagenSitzen: false })], STUFEN, null)
    expect(s).toEqual(['Die Lücken liegen vor allem im Stoff von Klasse 9/10.'])
  })

  it('Grundlagen bestätigt mit Lücken bis in Klasse 5/6: fester Satz', () => {
    const s = ursachenSaetze(t, [a('grundlagen', 'bestaetigt', { lueckenIn: 'grundlagen', grundlagenSitzen: false })], STUFEN, null)
    expect(s).toEqual(['Die Lücken reichen bis in den Stoff von Klasse 5/6.'])
  })

  it('Grundlagen eher nicht: mit Lücken im aktuellen Stoff ein zweiter Satz', () => {
    expect(
      ursachenSaetze(t, [a('grundlagen', 'eherNicht', { lueckenIn: 'aktuell', grundlagenSitzen: true })], STUFEN, null),
    ).toEqual([
      'Die Grundlagen aus früheren Klassen sitzen weitgehend.',
      'Die Lücken liegen vor allem im aktuellen Stoff von Klasse 9/10.',
    ])
    expect(ursachenSaetze(t, [a('grundlagen', 'eherNicht')], STUFEN, null)).toEqual([
      'Die Grundlagen aus früheren Klassen sitzen weitgehend.',
    ])
  })

  it('keine Antworten, keine Sätze', () => {
    expect(ursachenSaetze(t, [], STUFEN, 'Ilkay')).toEqual([])
  })
})

describe('lueckenFelder', () => {
  const p = (feld: ThemenfeldKey, uebung: number): EbProfilZeile => ({ feld, vorhanden: 5, sicher: 1, uebung })

  it('nur Felder ab zwei Bereichen mit Übungsbedarf, höchstens zwei, meiste zuerst', () => {
    expect(lueckenFelder([p('brueche', 2), p('prozent', 5), p('terme', 3), p('geometrie', 1)])).toEqual(['prozent', 'terme'])
  })

  it('Gleichstand: Reihenfolge des Profils', () => {
    expect(lueckenFelder([p('zahlen', 3), p('brueche', 3), p('terme', 3)])).toEqual(['zahlen', 'brueche'])
  })

  it('kein Feld mit mindestens zwei → leer; leeres Profil → leer', () => {
    expect(lueckenFelder([p('brueche', 1), p('terme', 0)])).toEqual([])
    expect(lueckenFelder([])).toEqual([])
  })
})

describe('grundText, startSatz', () => {
  it('der halbe Satz nach „weil“ je Grund', () => {
    expect(grundText(t, { art: 'klassenarbeit' })).toBe('die Klassenarbeit zu diesem Thema bevorsteht')
    expect(grundText(t, { art: 'thema' })).toBe('es das aktuelle Schulthema ist')
    expect(grundText(t, { art: 'themaGeschrieben' })).toBe('im aktuellen Schulthema noch eine Lücke offen ist')
    expect(grundText(t, { art: 'grundlagen' })).toBe('hier schon Stoff aus Klasse 5/6 Übung braucht')
    expect(grundText(t, { art: 'naechstesThema', titel: 'Kreis' })).toBe('das kommende Schulthema Kreis darauf aufbaut')
  })

  it('Anzahl im Singular und Plural', () => {
    expect(grundText(t, { art: 'anzahl', count: 1 })).toBe('hier ein Bereich Übungsbedarf zeigt')
    expect(grundText(t, { art: 'anzahl', count: 4 })).toBe('hier 4 Bereiche Übungsbedarf zeigen')
  })

  const sp = (feld: ThemenfeldKey | null, thema: string | null): EbSchwerpunkt => ({
    feld,
    thema,
    gemischt: false,
    sicher: [],
    uebung: ['x'],
    start: null,
    naechster: null,
  })

  it('„Wir beginnen mit …, weil …“ für ein Feld und für das Thema', () => {
    expect(startSatz(t, sp('geometrie', null), { art: 'grundlagen' })).toBe(
      'Wir beginnen mit der Geometrie, weil hier schon Stoff aus Klasse 5/6 Übung braucht.',
    )
    expect(startSatz(t, sp(null, 'Reelle Zahlen'), { art: 'thema' })).toBe(
      'Wir beginnen mit dem Thema Reelle Zahlen, weil es das aktuelle Schulthema ist.',
    )
  })

  it('ohne Schwerpunkt oder ohne Grund kein Satz', () => {
    expect(startSatz(t, undefined, { art: 'thema' })).toBeNull()
    expect(startSatz(t, sp('geometrie', null), undefined)).toBeNull()
  })
})

describe('schuleGenitiv', () => {
  it('Gymnasium und Kolleg: „des …s“', () => {
    expect(schuleGenitiv(t, 'Friedrich-Wilhelm-Gymnasium')).toBe('des Friedrich-Wilhelm-Gymnasiums')
    expect(schuleGenitiv(t, 'Rhein-Kolleg')).toBe('des Rhein-Kollegs')
  })

  it('Schule und Akademie: „der …“', () => {
    expect(schuleGenitiv(t, 'Realschule')).toBe('der Realschule')
    expect(schuleGenitiv(t, 'Schule am Park')).toBe('der Schule am Park')
    expect(schuleGenitiv(t, 'Rheinakademie')).toBe('der Rheinakademie')
  })

  it('sonst „der Schule …“', () => {
    expect(schuleGenitiv(t, 'Holweide')).toBe('der Schule Holweide')
  })
})
