// Bericht v2: die Satzbausteine für Seite 1, 3, 4 und 5 als reine Funktionen.
import { describe, expect, it } from 'vitest'
import i18n from '@/i18n'

import {
  anliegenSaetzeV2,
  fazitSaetze,
  grundText,
  lueckenFelder,
  schuleGenitiv,
  startSatz,
  stufenKlasse,
  stufenUrteil,
  ursachenSaetze,
  zieleSaetze,
} from '@/components/edvance/elternbericht/berichtSaetze'
import type { UrsachenAntwort } from '@/lib/report/elternbericht/ursache'
import type { EbGrund, EbProfilZeile, EbSchwerpunkt, EbStufenZeile, ReportErstgespraech, ThemenfeldKey } from '@/types'

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
  const ohne = { erstgespraech: null, ursachen: [], fach: 'Mathematik', liste }
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

  it('Note mit Trend in einer Zeile, dann Seit und Ursache', () => {
    const s = anliegenSaetzeV2(t, {
      ...ohne,
      erstgespraech: eg({ note: '4', trend: 'schlechter', seit: 'letztes_schuljahr' }),
      ursachen: ['Grundlagen fehlen', 'Rechenwege'],
    })
    expect(s).toEqual([
      'Letzte Zeugnisnote in Mathematik: 4, zuletzt schlechter geworden.',
      'Die Schwierigkeiten gibt es seit dem letzten Schuljahr.',
      'Als Ursache vermuten Sie Grundlagen fehlen und Rechenwege.',
    ])
  })

  it('Note ohne Trend: „Letzte Zeugnisnote in {fach}: {note}.“, nie mit Namen', () => {
    const s = anliegenSaetzeV2(t, { ...ohne, erstgespraech: eg({ note: '3' }) })
    expect(s).toEqual(['Letzte Zeugnisnote in Mathematik: 3.'])
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
    ['besser', 'Letzte Zeugnisnote in Mathematik: 2, zuletzt besser geworden.'],
    ['stabil', 'Letzte Zeugnisnote in Mathematik: 2, zuletzt unverändert.'],
    ['schlechter', 'Letzte Zeugnisnote in Mathematik: 2, zuletzt schlechter geworden.'],
  ] as const)('Trend %s steht in der Notenzeile', (trend, satz) => {
    expect(anliegenSaetzeV2(t, { ...ohne, erstgespraech: eg({ note: '2', trend }) })).toEqual([satz])
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
    expect(grundText(t, { art: 'naechstesThema', titel: 'Kreis' })).toBe('das kommende Schulthema „Kreis“ darauf aufbaut')
  })

  it('naechstesThema mit Band und Stelle: zuerst bzw. danach', () => {
    expect(grundText(t, { art: 'naechstesThema', titel: 'Kreis', stufe: 'erprobung', reihe: 'zuerst' })).toBe(
      'das kommende Schulthema „Kreis“ darauf aufbaut – zuerst, weil es Stoff aus Klasse 5/6 ist',
    )
    expect(grundText(t, { art: 'naechstesThema', titel: 'Kreis', stufe: 'erste', reihe: 'danach' })).toBe(
      'auch „Kreis“ darauf aufbaut – danach, weil es Stoff aus Klasse 7/8 ist',
    )
    // Band ohne Stelle (oder umgekehrt) fällt auf den einfachen Satz zurück.
    expect(grundText(t, { art: 'naechstesThema', titel: 'Kreis', stufe: 'erste' })).toBe(
      'das kommende Schulthema „Kreis“ darauf aufbaut',
    )
  })

  it('spaeterGebraucht nennt das Thema, das die Lücke wieder braucht', () => {
    expect(grundText(t, { art: 'spaeterGebraucht', titel: 'Kreis' })).toBe('es im Thema „Kreis“ wieder gebraucht wird')
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

describe('fazitSaetze (Seite 5)', () => {
  const st = (stufe: EbStufenZeile['stufe'], sicher: number, uebung: number, urteil: EbStufenZeile['urteil']): EbStufenZeile => ({
    stufe,
    urteil,
    von: 5,
    bis: 6,
    sicher,
    uebung,
  })
  const BASIS_OK = [st('grundlagen', 8, 2, 'weitgehend'), st('weiterfuehrend', 2, 6, 'luecken'), st('aktuell', 3, 3, 'gemischt')]

  it('Grundlagen sitzen, Lücken in 7/8 und in zwei Feldern, dann der Startsatz', () => {
    expect(fazitSaetze(t, { stufen: BASIS_OK, felder: ['brueche', 'prozent'], sorgfalt: false, start: 'Wir beginnen.' })).toEqual([
      'Die Grundlagen aus Klasse 5/6 sitzen weitgehend.',
      'Die Lücken liegen vor allem im Stoff von Klasse 7/8, besonders bei Brüchen und Dezimalzahlen sowie bei Prozent und Dreisatz.',
      'Wir beginnen.',
    ])
  })

  it('ein Feld, Sorgfaltsmuster vor dem Startsatz', () => {
    const s = fazitSaetze(t, { stufen: BASIS_OK, felder: ['geometrie'], sorgfalt: true, start: 'Start.' })
    expect(s).toHaveLength(4)
    expect(s[1]).toContain('besonders bei der Geometrie.')
    expect(s[2]).toBe(t('s1.blick.muster'))
    expect(s[3]).toBe('Start.')
  })

  it('ohne Feld: nur die Stufe der Lücken', () => {
    const s = fazitSaetze(t, { stufen: BASIS_OK, felder: [], sorgfalt: false, start: null })
    expect(s[1]).toBe('Die Lücken liegen vor allem im Stoff von Klasse 7/8.')
  })

  it('ohne Lückenstufe, aber mit Feld: „Die Lücken liegen vor allem bei …“', () => {
    const alleSicher = [st('grundlagen', 4, 0, 'sicher'), st('aktuell', 4, 0, 'sicher')]
    expect(fazitSaetze(t, { stufen: alleSicher, felder: ['terme'], sorgfalt: false, start: null })).toEqual([
      'Die Grundlagen aus Klasse 5/6 sitzen weitgehend.',
      'Die Lücken liegen vor allem bei Termen und Gleichungen.',
    ])
  })

  it('sitzen die Grundlagen nicht, fehlt der Basissatz; ohne Daten bleibt der Startsatz oder nichts', () => {
    const tief = [st('grundlagen', 1, 5, 'luecken'), st('aktuell', 3, 3, 'gemischt')]
    expect(fazitSaetze(t, { stufen: tief, felder: [], sorgfalt: false, start: null })[0]).not.toContain('sitzen weitgehend')
    expect(fazitSaetze(t, { stufen: [], felder: [], sorgfalt: false, start: null })).toEqual([])
    expect(fazitSaetze(t, { stufen: [], felder: [], sorgfalt: false, start: 'Start.' })).toEqual(['Start.'])
  })
})

describe('zieleSaetze (Seite 5)', () => {
  const sp = (feld: ThemenfeldKey | null, thema: string | null = null, uebung = ['A', 'B']): EbSchwerpunkt => ({
    feld,
    thema,
    gemischt: false,
    sicher: [],
    uebung,
    start: null,
    naechster: null,
  })
  const vier = [sp('brueche'), sp('prozent'), sp('terme'), sp('geometrie')]
  const z = (paket: 'basis' | 'standard' | 'premium', sorgfalt = false, gruende: EbGrund[] = []) =>
    zieleSaetze(t, { schwerpunkte: vier, gruende, paket, sorgfalt, liste })

  it('das Paket bestimmt, wie viele Schwerpunkte vorkommen: 2, 3, 4', () => {
    expect(z('basis')).toEqual(['Brüche und Dezimalzahlen sicher anwenden', 'Prozent- und Dreisatzrechnung sicher anwenden'])
    expect(z('standard')).toHaveLength(3)
    expect(z('premium')).toHaveLength(4)
    expect(z('premium')[3]).toBe('Flächen und Figuren sicher anwenden')
  })

  it('Sorgfaltsziel als letztes, zusätzlich zu den Schwerpunkten', () => {
    const s = z('basis', true)
    expect(s).toHaveLength(3)
    expect(s[2]).toBe('Rechenwege sorgfältig zu Ende führen und Ergebnisse selbst kontrollieren')
  })

  it('der Grund bestimmt den Satz: kommendes Thema, Klassenarbeit, allgemein', () => {
    const s = zieleSaetze(t, {
      schwerpunkte: [sp('brueche'), sp('prozent'), sp('terme')],
      gruende: [{ art: 'naechstesThema', titel: 'Kreis' }, { art: 'klassenarbeit' }, { art: 'anzahl', count: 2 }],
      paket: 'standard',
      sorgfalt: false,
      liste,
    })
    expect(s).toEqual([
      'Brüche und Dezimalzahlen sicher anwenden, bevor das Thema „Kreis“ beginnt',
      'Prozent- und Dreisatzrechnung für die Klassenarbeit sicher anwenden',
      'Terme und Gleichungen sicher anwenden',
    ])
  })

  it('Thema-Schwerpunkt heißt wie das Thema; bei Lücke (geschrieben/spaeterGebraucht) nach seinen Lücken', () => {
    const thema = sp(null, 'Reelle Zahlen', ['Wurzeln', 'Brüche'])
    const mk = (g: EbGrund) => zieleSaetze(t, { schwerpunkte: [thema], gruende: [g], paket: 'basis', sorgfalt: false, liste })
    expect(mk({ art: 'thema' })).toEqual(['Reelle Zahlen sicher anwenden'])
    expect(mk({ art: 'themaGeschrieben' })).toEqual(['Wurzeln und Brüche sicher anwenden'])
    expect(mk({ art: 'spaeterGebraucht', titel: 'Kreis' })).toEqual([
      'Wurzeln und Brüche sicher anwenden, bevor das Thema „Kreis“ beginnt',
    ])
  })

  it('ohne Schwerpunkte nur das Sorgfaltsziel oder nichts', () => {
    expect(zieleSaetze(t, { schwerpunkte: [], gruende: [], paket: 'premium', sorgfalt: false, liste })).toEqual([])
    expect(zieleSaetze(t, { schwerpunkte: [], gruende: [], paket: 'premium', sorgfalt: true, liste })).toHaveLength(1)
  })
})
