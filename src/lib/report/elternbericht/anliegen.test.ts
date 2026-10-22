import { describe, expect, it } from 'vitest'

import {
  ANLIEGEN_ZUORDNUNG,
  anliegenAus,
  anliegenArt,
  rueckbezugZeigen,
} from '@/lib/report/elternbericht/anliegen'
import { ZUORDNUNGEN } from '@/lib/report/elternbericht/fixtures/bausteine'
import { PARENT_WEAK_TOPICS } from '@/pages/admin/intake/intakeConstants'
import type { EbSchwerpunkt } from '@/types'

const feld: EbSchwerpunkt = {
  feld: 'geometrie',
  thema: null,
  gemischt: true,
  sicher: ['A'],
  uebung: ['B'],
  start: null,
  naechster: null,
}
const thema: EbSchwerpunkt = {
  feld: null,
  thema: 'Reelle Zahlen',
  gemischt: true,
  sicher: ['S'],
  uebung: ['U1', 'U2'],
  start: 'U1',
  naechster: 'U2',
}
const T = { titel: 'Reelle Zahlen', uebung: ['U1', 'U2'] }

describe('anliegenArt — die feste Tabelle', () => {
  it('ordnet jede Intake-Option und jeden Anzeigenamen zu', () => {
    for (const { value } of PARENT_WEAK_TOPICS) expect(value.toLocaleLowerCase('de') in ANLIEGEN_ZUORDNUNG, value).toBe(true)
    for (const z of ZUORDNUNGEN) expect(z.anzeigename.toLocaleLowerCase('de') in ANLIEGEN_ZUORDNUNG, z.anzeigename).toBe(true)
  })

  it('fachlich: Stoff und Leistung; überfachlich: Verhalten und Organisation', () => {
    for (const w of ['Grundlagen fehlen', 'fehlende Grundlagen', 'Rechenwege', 'Textverständnis', 'Noten', 'Klassenarbeit'])
      expect(anliegenArt(w), w).toBe('fachlich')
    for (const w of ['Konzentration', 'Prüfungsangst', 'Zeiteinteilung', 'Motivation', 'Hausaufgaben', 'Selbstorganisation'])
      expect(anliegenArt(w), w).toBe('ueberfachlich')
  })

  it('ohne Rücksicht auf Groß/Klein und Leerzeichen; Unbekanntes ist überfachlich', () => {
    expect(anliegenArt('  RECHENWEGE ')).toBe('fachlich')
    expect(anliegenArt('Handyzeit')).toBe('ueberfachlich')
    expect(anliegenArt('')).toBe('ueberfachlich')
  })
})

describe('anliegenAus — Frage und Antwort', () => {
  it('gemischt: nur das fachliche Anliegen, mit Schwerpunkt 1 als Antwort und nächstem Thema', () => {
    expect(
      anliegenAus({ anlassNamen: ['Noten', 'Konzentration'], naechstesThema: 'Algebra', schwerpunkte: [feld], thema: null }),
    ).toEqual({ thema: null, themaUebung: [], punkte: ['Noten'], schwerpunkt: feld, naechstesThema: 'Algebra' })
  })

  it('ohne Thema und nur überfachlich: null (der Kasten entfällt), auch mit nächstem Thema', () => {
    expect(
      anliegenAus({ anlassNamen: ['Konzentration'], naechstesThema: 'Algebra', schwerpunkte: [feld], thema: null }),
    ).toBeNull()
    expect(anliegenAus({ anlassNamen: [], naechstesThema: null, schwerpunkte: [], thema: null })).toBeNull()
  })

  it('mit Thema als Schwerpunkt 1: Thema und Übungsbedarf darin; kein Schwerpunkt-Satz, kein nächstes Thema', () => {
    expect(
      anliegenAus({
        anlassNamen: ['Rechenwege', 'Rechenwege'],
        naechstesThema: 'Algebra',
        schwerpunkte: [thema, feld],
        thema: T,
      }),
    ).toEqual({ thema: 'Reelle Zahlen', themaUebung: ['U1', 'U2'], punkte: ['Rechenwege'], schwerpunkt: null, naechstesThema: null })
    expect(anliegenAus({ anlassNamen: [], naechstesThema: null, schwerpunkte: [thema], thema: T })?.thema).toBe('Reelle Zahlen')
  })

  it('Thema ohne Übungsbedarf (kein Schwerpunkt): Feld-Schwerpunkt 1 als Antwort auf das fachliche Anliegen', () => {
    const sicher = { titel: 'Reelle Zahlen', uebung: [] }
    expect(
      anliegenAus({ anlassNamen: ['Rechenwege'], naechstesThema: null, schwerpunkte: [feld], thema: sicher }),
    ).toEqual({ thema: 'Reelle Zahlen', themaUebung: [], punkte: ['Rechenwege'], schwerpunkt: feld, naechstesThema: null })
  })

  it('fachlich ohne Schwerpunkt (kein Übungsbedarf): kein Antwortsatz', () => {
    expect(
      anliegenAus({ anlassNamen: ['Rechenwege'], naechstesThema: null, schwerpunkte: [], thema: null })?.schwerpunkt,
    ).toBeNull()
  })
})

describe('rueckbezugZeigen', () => {
  it('nur fachlich und nur bestätigend oder entlastend, nie die schmale Fassung', () => {
    const r = (thema: string, fall: string, richtung: 'bestaetigend' | 'entlastend' | 'offen' | 'nicht_messbar') => ({
      thema,
      fall,
      richtung,
    })
    expect(rueckbezugZeigen(r('Rechenwege', 'rechenwege_bestaetigend', 'bestaetigend'))).toBe(true)
    expect(rueckbezugZeigen(r('Grundlagen fehlen', 'grundlagen_entlastend', 'entlastend'))).toBe(true)
    expect(rueckbezugZeigen(r('Grundlagen fehlen', 'grundlagen_entlastend_schmal', 'entlastend'))).toBe(false)
    expect(rueckbezugZeigen(r('Rechenwege', 'rechenwege_offen', 'offen'))).toBe(false)
    expect(rueckbezugZeigen(r('Konzentration', 'konzentration_nicht_messbar', 'nicht_messbar'))).toBe(false)
  })
})
