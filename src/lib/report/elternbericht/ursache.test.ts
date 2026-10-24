// Bericht v2, Seite 1: die Antwort auf die vermutete Ursache.
import { describe, expect, it } from 'vitest'

import { URSACHEN } from '@/lib/report/elternbericht/berichtKonfig'
import { fehlermusterAus } from '@/lib/report/elternbericht/fehlermuster'
import { baueStufen } from '@/lib/report/elternbericht/stufenBlick'
import { ursachenAntworten } from '@/lib/report/elternbericht/ursache'
import type { EbBereich, EbStufenZeile, ReportFehlbild } from '@/types'

const b = (skillKey: string, klasse: number, sicher: boolean): EbBereich => ({
  skillKey,
  label: skillKey,
  feld: 'zahlen',
  klasse,
  sicher,
})
const fb = (familie: string, aufgaben = 2): ReportFehlbild => ({
  slug: `${familie}-slug`,
  familie,
  familieElterntext: null,
  anzahl: aufgaben,
  aufgaben,
  skills: [],
  skillUebergreifend: false,
  einstufung: 'befund',
})

const antwort = (
  genannt: string[],
  bereiche: EbBereich[] = [],
  fehlbilder: ReportFehlbild[] = [],
  stufen: readonly EbStufenZeile[] = baueStufen(bereiche, 10),
) => ursachenAntworten({ genannt, stufen, bereiche, fehlbilder, muster: fehlermusterAus(fehlbilder) })

/** Viele Bereiche einer Klasse mit n Übungsbedarf. */
const klasse = (k: number, sicher: number, uebung: number): EbBereich[] => [
  ...Array.from({ length: sicher }, (_, i) => b(`s${k}_${i}`, k, true)),
  ...Array.from({ length: uebung }, (_, i) => b(`u${k}_${i}`, k, false)),
]

describe('ursachenAntworten — Allgemeines', () => {
  it('kennt alle sechs Ursachen aus dem Elternfragebogen', () => {
    expect(Object.keys(URSACHEN)).toEqual([
      'Grundlagen fehlen',
      'Textverständnis',
      'Rechenwege',
      'Konzentration',
      'Prüfungsangst',
      'Zeiteinteilung',
    ])
  })

  it('ohne Nennung keine Antwort; unbekannte Werte (z. B. „Noten“) werden übergangen', () => {
    expect(antwort([])).toEqual([])
    expect(antwort(['Noten', 'Hausaufgaben'])).toEqual([])
  })

  it('doppelte Nennung nur einmal, Reihenfolge der Eltern bleibt', () => {
    const a = antwort(['Prüfungsangst', 'Konzentration', 'Prüfungsangst'])
    expect(a.map((x) => x.key)).toEqual(['pruefungsangst', 'konzentration'])
  })
})

describe('ursachenAntworten — nicht messbar', () => {
  it('Prüfungsangst und Zeiteinteilung: immer „offen“, auch bei vielen Daten', () => {
    const daten = [...klasse(5, 0, 5), ...klasse(9, 5, 0)]
    expect(antwort(['Prüfungsangst', 'Zeiteinteilung'], daten)).toEqual([
      { key: 'pruefungsangst', variante: 'offen' },
      { key: 'zeiteinteilung', variante: 'offen' },
    ])
  })
})

describe('ursachenAntworten — Konzentration (Sorgfalt)', () => {
  it('bestätigt nur mit gedecktem Fehlermuster', () => {
    expect(antwort(['Konzentration'], [], [fb('vorzeichen', 3)])).toEqual([
      { key: 'konzentration', variante: 'bestaetigt' },
    ])
  })

  it('ohne Muster oder bei zu wenig Sorgfalt-Aufgaben: offen, nie „eher nicht“', () => {
    expect(antwort(['Konzentration'])[0].variante).toBe('offen')
    expect(antwort(['Konzentration'], [], [fb('vorzeichen', 2)])[0].variante).toBe('offen')
    expect(antwort(['Konzentration'], [], [fb('sachaufgaben', 6)])[0].variante).toBe('offen')
  })
})

describe('ursachenAntworten — Textverständnis (Skill gleichung_modellieren, Familie sachaufgaben)', () => {
  it('Fehlbild-Familie sachaufgaben → bestätigt', () => {
    expect(antwort(['Textverständnis'], [], [fb('sachaufgaben')])[0].variante).toBe('bestaetigt')
  })

  it('geprüfter Skill mit Übungsbedarf → bestätigt', () => {
    expect(antwort(['Textverständnis'], [b('gleichung_modellieren', 9, false)])[0].variante).toBe('bestaetigt')
  })

  it('geprüfter Skill sicher und keine Fehlbilder → eher nicht', () => {
    expect(antwort(['Textverständnis'], [b('gleichung_modellieren', 9, true)])[0].variante).toBe('eherNicht')
  })

  it('weder Skill geprüft noch Familie → offen, auch wenn andere Fehlbilder da sind', () => {
    expect(antwort(['Textverständnis'], [b('bruch_kuerzen', 6, false)], [fb('vorzeichen')])[0].variante).toBe('offen')
  })
})

describe('ursachenAntworten — Rechenwege (nur Familien)', () => {
  it('gleichungen_umformen oder rechenreihenfolge → bestätigt', () => {
    expect(antwort(['Rechenwege'], [], [fb('gleichungen_umformen')])[0].variante).toBe('bestaetigt')
    expect(antwort(['Rechenwege'], [], [fb('rechenreihenfolge')])[0].variante).toBe('bestaetigt')
  })

  it('Fehlbilder anderer Familien → eher nicht (es gab etwas zu sehen, aber nicht das)', () => {
    expect(antwort(['Rechenwege'], [], [fb('sachaufgaben')])[0].variante).toBe('eherNicht')
  })

  it('gar keine Fehlbilder → offen', () => {
    expect(antwort(['Rechenwege'], klasse(9, 3, 3))[0].variante).toBe('offen')
  })

  it('ein geprüfter Skill mit Übungsbedarf belegt Rechenwege nicht (skills ist leer)', () => {
    expect(antwort(['Rechenwege'], [b('gleichung_modellieren', 9, false)])[0].variante).toBe('offen')
  })
})

describe('ursachenAntworten — Grundlagen fehlen', () => {
  it('Lücken in Klasse 5/6 → bestätigt, Basis sitzt nicht', () => {
    const [a] = antwort(['Grundlagen fehlen'], [...klasse(5, 0, 4), ...klasse(9, 4, 0)])
    expect(a).toEqual({ key: 'grundlagen', variante: 'bestaetigt', lueckenIn: 'grundlagen', grundlagenSitzen: false })
  })

  it('Lücken vor allem in Klasse 7/8, Klasse 5/6 weitgehend sicher → bestätigt, Basis sitzt', () => {
    const [a] = antwort(['Grundlagen fehlen'], [...klasse(5, 9, 1), ...klasse(7, 1, 4), ...klasse(9, 3, 0)])
    expect(a).toEqual({ key: 'grundlagen', variante: 'bestaetigt', lueckenIn: 'weiterfuehrend', grundlagenSitzen: true })
  })

  it('Lücken im aktuellen Stoff → eher nicht', () => {
    const [a] = antwort(['Grundlagen fehlen'], [...klasse(5, 5, 0), ...klasse(9, 1, 4)])
    expect(a).toEqual({ key: 'grundlagen', variante: 'eherNicht', lueckenIn: 'aktuell', grundlagenSitzen: true })
  })

  it('keine Lückenstufe (alles sicher) → eher nicht, ohne Ort', () => {
    const [a] = antwort(['Grundlagen fehlen'], [...klasse(5, 3, 0), ...klasse(9, 3, 0)])
    expect(a).toMatchObject({ variante: 'eherNicht', grundlagenSitzen: true })
    expect(a.lueckenIn).toBeUndefined()
  })

  it('ohne Klasse-5/6-Daten gilt die Basis nicht als sitzend', () => {
    const [a] = antwort(['Grundlagen fehlen'], klasse(9, 1, 4))
    expect(a.grundlagenSitzen).toBe(false)
  })

  it('ohne jede Stufe: eher nicht', () => {
    expect(antwort(['Grundlagen fehlen'], [], [], [])[0]).toMatchObject({ variante: 'eherNicht', grundlagenSitzen: false })
  })
})
