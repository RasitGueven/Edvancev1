import { describe, expect, it } from 'vitest'

import { gruppiereFehlbilderNachFamilie } from '@/lib/reportFehlbilder'
import type { ReportFehlbild } from '@/types'

/**
 * Bündelung der Fehlbilder für die Elternsicht.
 *
 * Geprüft wird, WAS Eltern zu sehen bekommen — nicht wie es aussieht. Die
 * beiden Weglass-Regeln (keine Familie, kein abgenommener Text) sind
 * Auslieferungsregeln: fällt eine davon, steht eine unbelegte oder
 * unabgenommene Aussage über das Denken eines Kindes im Elterngespräch.
 */

// Ein Befund mit Vorgabewerten; jeder Fall überschreibt nur, worum es ihm geht.
function befund(over: Partial<ReportFehlbild> = {}): ReportFehlbild {
  return {
    slug: 'vorzeichen_ignoriert',
    familie: 'vorzeichen',
    familieElterntext: 'Ihr Kind verliert beim Rechnen das Vorzeichen.',
    anzahl: 1,
    aufgaben: 1,
    skillUebergreifend: false,
    einstufung: 'befund',
    ...over,
  }
}

describe('gruppiereFehlbilderNachFamilie — Bündelung', () => {
  it('fasst mehrere Slugs derselben Familie zu EINEM Block zusammen', () => {
    const blocks = gruppiereFehlbilderNachFamilie([
      befund({ slug: 'vorzeichen_ignoriert', anzahl: 2 }),
      befund({ slug: 'betrag_fehler', anzahl: 3 }),
      befund({ slug: 'seiten_verwechselt', anzahl: 1 }),
    ])

    expect(blocks).toHaveLength(1)
    expect(blocks[0].familie).toBe('vorzeichen')
    expect(blocks[0].elterntext).toBe(
      'Ihr Kind verliert beim Rechnen das Vorzeichen.',
    )
  })

  it('summiert die Vorkommen, nicht die Aufgaben', () => {
    // aufgaben darf NICHT aufsummiert werden: zwei Slugs können auf derselben
    // Aufgabe auftreten, die Summe zeigte Eltern eine zu große Zahl.
    const blocks = gruppiereFehlbilderNachFamilie([
      befund({ slug: 'a', anzahl: 2, aufgaben: 2 }),
      befund({ slug: 'b', anzahl: 3, aufgaben: 2 }),
    ])

    expect(blocks[0].anzahl).toBe(5)
    expect(blocks[0]).not.toHaveProperty('aufgaben')
  })

  it('gibt den Elterntext wörtlich weiter, ohne Umformulierung', () => {
    const text = 'Ihr Kind rechnet sauber, wählt bei Textaufgaben aber den falschen Rechenweg.'
    const blocks = gruppiereFehlbilderNachFamilie([
      befund({ familie: 'sachaufgaben', familieElterntext: text }),
    ])

    expect(blocks[0].elterntext).toBe(text)
  })
})

describe('gruppiereFehlbilderNachFamilie — stilles Weglassen', () => {
  it('lässt Fehlbilder ohne Familienzuordnung weg', () => {
    // 53 der 73 Registry-Slugs haben keine Familie.
    const blocks = gruppiereFehlbilderNachFamilie([
      befund({ slug: 'teilgekuerzt', familie: null, familieElterntext: null }),
    ])

    expect(blocks).toEqual([])
  })

  it('lässt Familien ohne abgenommenen Elterntext weg', () => {
    // fehlbild_familien.freigegeben_am ist null -> die RPC liefert null.
    const blocks = gruppiereFehlbilderNachFamilie([
      befund({ familie: 'rechenreihenfolge', familieElterntext: null }),
    ])

    expect(blocks).toEqual([])
  })

  it('behandelt einen leeren Elterntext wie einen fehlenden', () => {
    expect(
      gruppiereFehlbilderNachFamilie([befund({ familieElterntext: '   ' })]),
    ).toEqual([])
  })

  it('lässt nur die unvollständigen Befunde weg, nicht die vollständigen', () => {
    const blocks = gruppiereFehlbilderNachFamilie([
      befund({ slug: 'ohne_familie', familie: null, familieElterntext: null }),
      befund({ familie: 'vorzeichen', anzahl: 4 }),
      befund({ slug: 'nicht_frei', familie: 'sachaufgaben', familieElterntext: null }),
    ])

    expect(blocks.map((b) => b.familie)).toEqual(['vorzeichen'])
    expect(blocks[0].anzahl).toBe(4)
  })

  it('liefert eine leere Liste, wenn kein Befund übrig bleibt', () => {
    // Der Abschnitt entfällt dann vollständig — die Komponente rendert nichts.
    expect(gruppiereFehlbilderNachFamilie([])).toEqual([])
    expect(
      gruppiereFehlbilderNachFamilie([
        befund({ familie: null, familieElterntext: null }),
        befund({ familieElterntext: null }),
      ]),
    ).toEqual([])
  })
})

describe('gruppiereFehlbilderNachFamilie — Reihenfolge', () => {
  it('sortiert nach Summe der Vorkommen, absteigend', () => {
    const blocks = gruppiereFehlbilderNachFamilie([
      befund({ familie: 'a', familieElterntext: 'A', anzahl: 1 }),
      befund({ familie: 'b', familieElterntext: 'B', anzahl: 5 }),
      befund({ familie: 'c', familieElterntext: 'C', anzahl: 3 }),
    ])

    expect(blocks.map((b) => b.familie)).toEqual(['b', 'c', 'a'])
    expect(blocks.map((b) => b.anzahl)).toEqual([5, 3, 1])
  })

  it('sortiert nach der SUMME, nicht nach dem größten Einzelwert', () => {
    const blocks = gruppiereFehlbilderNachFamilie([
      befund({ slug: 'x', familie: 'gross', familieElterntext: 'G', anzahl: 4 }),
      befund({ slug: 'y', familie: 'viele', familieElterntext: 'V', anzahl: 3 }),
      befund({ slug: 'z', familie: 'viele', familieElterntext: 'V', anzahl: 3 }),
    ])

    expect(blocks.map((b) => b.familie)).toEqual(['viele', 'gross'])
  })

  it('ist bei Gleichstand stabil und unabhängig von der Eingabereihenfolge', () => {
    const a = befund({ familie: 'einheiten_massstab', familieElterntext: 'E', anzahl: 2 })
    const b = befund({ familie: 'vorzeichen', familieElterntext: 'V', anzahl: 2 })

    expect(gruppiereFehlbilderNachFamilie([a, b]).map((x) => x.familie)).toEqual([
      'einheiten_massstab',
      'vorzeichen',
    ])
    expect(gruppiereFehlbilderNachFamilie([b, a]).map((x) => x.familie)).toEqual([
      'einheiten_massstab',
      'vorzeichen',
    ])
  })

  it('verändert die Eingabeliste nicht', () => {
    const eingabe = [befund({ familie: 'b', familieElterntext: 'B', anzahl: 1 })]
    const kopie = structuredClone(eingabe)
    gruppiereFehlbilderNachFamilie(eingabe)

    expect(eingabe).toEqual(kopie)
  })
})
