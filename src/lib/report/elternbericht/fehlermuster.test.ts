// Bericht v2, Seite 1 und 4: das Fehlermuster aus den Fehlbild-Aufgaben.
import { describe, expect, it } from 'vitest'

import { SORGFALT } from '@/lib/report/elternbericht/berichtKonfig'
import { fehlermusterAus } from '@/lib/report/elternbericht/fehlermuster'
import type { ReportFehlbild } from '@/types'

const fb = (familie: string | null, aufgaben: number, text: string | null = `Text ${familie}.`): ReportFehlbild => ({
  slug: `${familie ?? 'ohne'}-${aufgaben}`,
  familie,
  familieElterntext: text,
  anzahl: aufgaben,
  aufgaben,
  skills: [],
  skillUebergreifend: false,
  einstufung: 'befund',
})

describe('fehlermusterAus', () => {
  it('ohne Fehlbilder oder ohne Familie → null', () => {
    expect(fehlermusterAus([])).toBeNull()
    expect(fehlermusterAus([fb(null, 5)])).toBeNull()
  })

  it('Schwellen kommen aus berichtKonfig', () => {
    expect(SORGFALT.minAufgaben).toBe(3)
    expect(SORGFALT.minAnteil).toBe(0.5)
    expect(SORGFALT.familien).toEqual(['vorzeichen', 'schritt_vergessen', 'figuren'])
  })

  it('Sorgfalt, wenn genug Aufgaben aus den Sorgfalt-Familien stammen und sie die Hälfte ausmachen', () => {
    const m = fehlermusterAus([fb('vorzeichen', 2), fb('schritt_vergessen', 1), fb('sachaufgaben', 3)])
    expect(m).toMatchObject({ sorgfalt: true, aufgaben: 6, sorgfaltAufgaben: 3, haeufigste: null })
  })

  it('zählt Aufgaben, nicht Fehlbild-Slugs', () => {
    // Drei Slugs derselben Familie mit je einer Aufgabe = drei Aufgaben.
    expect(fehlermusterAus([fb('figuren', 1), fb('figuren', 1), fb('figuren', 1)])).toMatchObject({
      sorgfalt: true,
      sorgfaltAufgaben: 3,
    })
  })

  it('zu wenige Sorgfalt-Aufgaben (2 statt 3): keine Kernaussage', () => {
    expect(fehlermusterAus([fb('vorzeichen', 2)])).toMatchObject({ sorgfalt: false, sorgfaltAufgaben: 2 })
  })

  it('Anteil genau 50 % reicht, knapp darunter nicht', () => {
    expect(fehlermusterAus([fb('vorzeichen', 3), fb('sachaufgaben', 3)])?.sorgfalt).toBe(true)
    expect(fehlermusterAus([fb('vorzeichen', 3), fb('sachaufgaben', 4)])?.sorgfalt).toBe(false)
  })

  it('Sorgfalt-Familien verschiedener Art addieren sich', () => {
    expect(fehlermusterAus([fb('vorzeichen', 1), fb('schritt_vergessen', 1), fb('figuren', 1)])?.sorgfalt).toBe(true)
  })

  it('ohne Kernaussage: Elterntext der eindeutig häufigsten Familie mit mindestens zwei Aufgaben', () => {
    const m = fehlermusterAus([fb('sachaufgaben', 4, 'Ihr Kind liest ungenau.'), fb('bruchrechnen', 2)])
    expect(m).toMatchObject({ sorgfalt: false, haeufigste: 'Ihr Kind liest ungenau.' })
  })

  it('Gleichstand der häufigsten Familien: keine häufigste', () => {
    expect(fehlermusterAus([fb('a', 3), fb('b', 3)])?.haeufigste).toBeNull()
  })

  it('häufigste Familie mit nur einer Aufgabe: kein Text', () => {
    expect(fehlermusterAus([fb('a', 1)])?.haeufigste).toBeNull()
  })

  it('häufigste Familie ohne abgenommenen Elterntext: null', () => {
    expect(fehlermusterAus([fb('a', 4, null)])?.haeufigste).toBeNull()
  })

  it('mit Kernaussage entfällt der Text der häufigsten Familie', () => {
    expect(fehlermusterAus([fb('vorzeichen', 5, 'Vorzeichen.')])).toMatchObject({ sorgfalt: true, haeufigste: null })
  })

  it('führt Slugs derselben Familie zusammen und nimmt den ersten vorhandenen Elterntext', () => {
    const m = fehlermusterAus([fb('a', 1, null), fb('a', 2, 'Erster Text.'), fb('b', 1)])
    expect(m?.haeufigste).toBe('Erster Text.')
  })
})
