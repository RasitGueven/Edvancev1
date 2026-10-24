// Bericht v3: Schwerpunkte nach Planrang, dann Klassenband; Grund mit Stelle; „spaeterGebraucht“.
import { describe, expect, it } from 'vitest'

import { schwerpunkteMitGrund, waehleSchwerpunkte, type ThemaKontext } from '@/lib/report/elternbericht/schwerpunkte'
import type { EbBereich, ThemenfeldKey } from '@/types'

const b = (skillKey: string, feld: ThemenfeldKey, klasse: number, sicher: boolean): EbBereich => ({
  skillKey,
  label: skillKey,
  feld,
  klasse,
  sicher,
})

const plan = (...titel: string[]) => titel.map((t, i) => ({ position: i + 1, themaKey: `k${i}`, titel: t, halbjahr: null }))

/** Das Skill `s<i>` gehört zum i-ten kommenden Thema und setzt die übergebenen Bereiche voraus. */
const kontext = (teil: Partial<ThemaKontext> = {}): ThemaKontext => ({
  thema: 'Thema',
  raum: new Set(),
  geprueft: new Set(),
  kanten: [],
  heimatThemen: [],
  kommt: [],
  ...teil,
})

describe('Schwerpunkte v3 — gleiches kommendes Thema: früheres Klassenband zuerst', () => {
  // Beide Felder bauen auf „Quadratische Gleichungen“ auf; Geometrie ist gemischt (sonst vorn).
  const bereiche = [
    b('geo_a', 'geometrie', 8, false),
    b('geo_s', 'geometrie', 8, true),
    b('bru_a', 'brueche', 5, false),
  ]
  const k = kontext({
    kommt: plan('Quadratische Gleichungen'),
    heimatThemen: [{ skillKey: 'q', themaKey: 'k0' }],
    kanten: [
      { skillKey: 'q', voraussetzt: 'geo_a' },
      { skillKey: 'q', voraussetzt: 'bru_a' },
    ],
  })

  it('das Feld mit Stoff aus Klasse 5/6 steht vor dem gemischten Feld aus 7/8', () => {
    expect(waehleSchwerpunkte(bereiche, k).schwerpunkte.map((s) => s.feld)).toEqual(['brueche', 'geometrie'])
  })

  it('der Grund trägt Band und Stelle: zuerst Klasse 5/6, danach Klasse 7/8', () => {
    const { schwerpunkte } = schwerpunkteMitGrund(bereiche, k)
    expect(schwerpunkte.map((s) => s.grund)).toEqual([
      { art: 'naechstesThema', titel: 'Quadratische Gleichungen', stufe: 'erprobung', reihe: 'zuerst' },
      { art: 'naechstesThema', titel: 'Quadratische Gleichungen', stufe: 'erste', reihe: 'danach' },
    ])
  })

  it('im selben Band keine Stelle, nur das Thema', () => {
    const gleich = [b('geo_a', 'geometrie', 8, false), b('bru_a', 'brueche', 7, false)]
    const { schwerpunkte } = schwerpunkteMitGrund(gleich, k)
    expect(schwerpunkte.map((s) => s.grund)).toEqual([
      { art: 'naechstesThema', titel: 'Quadratische Gleichungen' },
      { art: 'naechstesThema', titel: 'Quadratische Gleichungen' },
    ])
  })

  it('ein einzelnes Feld zum Thema: keine Stelle', () => {
    const { schwerpunkte } = schwerpunkteMitGrund([b('bru_a', 'brueche', 5, false)], k)
    expect(schwerpunkte[0].grund).toEqual({ art: 'naechstesThema', titel: 'Quadratische Gleichungen' })
  })

  it('verschiedene kommende Themen: der Planrang geht vor dem Klassenband', () => {
    const zwei = kontext({
      kommt: plan('Erstes', 'Zweites'),
      heimatThemen: [
        { skillKey: 'q0', themaKey: 'k0' },
        { skillKey: 'q1', themaKey: 'k1' },
      ],
      kanten: [
        { skillKey: 'q0', voraussetzt: 'geo_a' },
        { skillKey: 'q1', voraussetzt: 'bru_a' },
      ],
    })
    const { schwerpunkte } = schwerpunkteMitGrund([b('geo_a', 'geometrie', 9, false), b('bru_a', 'brueche', 5, false)], zwei)
    expect(schwerpunkte.map((s) => [s.feld, s.grund.art])).toEqual([
      ['geometrie', 'naechstesThema'],
      ['brueche', 'naechstesThema'],
    ])
    expect(schwerpunkte.every((s) => s.grund.art === 'naechstesThema' && s.grund.reihe === undefined)).toBe(true)
  })

  it('ohne kommendes Thema gilt die R7-Regel unverändert (gemischt zuerst)', () => {
    expect(waehleSchwerpunkte(bereiche).schwerpunkte.map((s) => s.feld)).toEqual(['geometrie', 'brueche'])
  })
})

describe('Schwerpunkte v3 — spaeterGebraucht (Klassenarbeit geschrieben)', () => {
  // Thema-Bereich t (Raum) ist Voraussetzung von q0 (Thema „Erstes“, Rang 0) bzw. q1 („Zweites“, Rang 1).
  const aufbau = (rangT: 0 | 1) =>
    kontext({
      raum: new Set(['t']),
      geprueft: new Set(['t']),
      kommt: plan('Erstes', 'Zweites'),
      heimatThemen: [
        { skillKey: 'q0', themaKey: 'k0' },
        { skillKey: 'q1', themaKey: 'k1' },
      ],
      kanten: [
        { skillKey: `q${rangT}`, voraussetzt: 't' },
        { skillKey: 'q0', voraussetzt: 'f0' },
        { skillKey: 'q1', voraussetzt: 'f1' },
      ],
    })
  const bereiche = [
    b('t', 'zahlen', 9, false),
    b('f0', 'brueche', 6, false),
    b('f1', 'prozent', 6, false),
    b('f2', 'zufall', 6, false), // kein kommendes Thema
  ]
  const reihe = (r: 0 | 1, ka: 'geschrieben' | 'bevorstehend' | null) =>
    schwerpunkteMitGrund(bereiche, aufbau(r), ka).schwerpunkte.map((s) => s.feld ?? 'thema')

  it('der Grund nennt das kommende Thema, das auf der Lücke aufbaut', () => {
    const t = schwerpunkteMitGrund(bereiche, aufbau(1), 'geschrieben').schwerpunkte.find((s) => s.thema !== null)
    expect(t?.grund).toEqual({ art: 'spaeterGebraucht', titel: 'Zweites' })
  })

  it('das Thema reiht sich nach seinem Planrang ein', () => {
    expect(reihe(1, 'geschrieben')).toEqual(['brueche', 'prozent', 'thema', 'zufall'])
    // Rang 0: nach dem Feld mit gleichem Rang, vor dem Feld mit Rang 1.
    expect(reihe(0, 'geschrieben')).toEqual(['brueche', 'thema', 'prozent', 'zufall'])
  })

  it('Klassenarbeit bevorstehend oder unbekannt: das Thema zuerst, Grund ohne Aufbau', () => {
    expect(reihe(1, 'bevorstehend')[0]).toBe('thema')
    expect(reihe(1, null)[0]).toBe('thema')
    const t = schwerpunkteMitGrund(bereiche, aufbau(1), 'bevorstehend').schwerpunkte[0]
    expect(t.grund).toEqual({ art: 'klassenarbeit' })
    expect(schwerpunkteMitGrund(bereiche, aufbau(1), null).schwerpunkte[0].grund).toEqual({ art: 'thema' })
  })

  it('geschrieben, aber nichts baut auf der Lücke auf: themaGeschrieben, Thema nach den Planrang-Feldern', () => {
    const k = kontext({
      raum: new Set(['t']),
      geprueft: new Set(['t']),
      kommt: plan('Erstes'),
      heimatThemen: [{ skillKey: 'q0', themaKey: 'k0' }],
      kanten: [{ skillKey: 'q0', voraussetzt: 'f0' }],
    })
    const { schwerpunkte } = schwerpunkteMitGrund(bereiche.slice(0, 2), k, 'geschrieben')
    expect(schwerpunkte.map((s) => s.feld ?? 'thema')).toEqual(['brueche', 'thema'])
    expect(schwerpunkte[1].grund).toEqual({ art: 'themaGeschrieben' })
  })

  it('das Thema bleibt unter den höchstens vier Schwerpunkten', () => {
    const viele = [
      b('t', 'zahlen', 9, false),
      b('f0', 'brueche', 6, false),
      b('f1', 'prozent', 6, false),
      b('f3', 'geometrie', 6, false),
      b('f4', 'terme', 6, false),
    ]
    const k = kontext({
      ...aufbau(1),
      kanten: [
        { skillKey: 'q0', voraussetzt: 'f0' },
        { skillKey: 'q0', voraussetzt: 'f1' },
        { skillKey: 'q0', voraussetzt: 'f3' },
        { skillKey: 'q0', voraussetzt: 'f4' },
        { skillKey: 'q1', voraussetzt: 't' },
      ],
    })
    const { schwerpunkte, danach } = schwerpunkteMitGrund(viele, k, 'geschrieben')
    expect(schwerpunkte).toHaveLength(4)
    expect(schwerpunkte.some((s) => s.thema !== null)).toBe(true)
    expect(danach).toHaveLength(1)
  })
})
