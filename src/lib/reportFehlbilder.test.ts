import { describe, expect, it } from 'vitest'

import {
  aufgabenUntergrenze,
  gruppiereFehlbilderNachFamilie,
} from '@/lib/reportFehlbilder'
import type { ReportFehlbild } from '@/types'

/**
 * Bündelung der Fehlbilder für die Elternsicht.
 *
 * Geprüft wird, WAS Eltern zu sehen bekommen — nicht wie es aussieht. Die
 * Weglass-Regeln (keine Familie, kein abgenommener Text) sind
 * Auslieferungsregeln: fällt eine davon, steht eine unbelegte oder
 * unabgenommene Aussage über das Denken eines Kindes im Elterngespräch.
 *
 * Seit R2 trägt diese Schicht zusätzlich die SCHWELLE. Sie greift NACH der
 * Bündelung, nicht davor — sonst geht der Fall verloren, für den die Bündelung
 * überhaupt gebaut wurde.
 */

// Ein Befund mit Vorgabewerten; jeder Fall überschreibt nur, worum es ihm geht.
// Die Vorgabe liegt bewusst ÜBER der Schwelle, damit Fälle, die etwas anderes
// prüfen, nicht daran scheitern.
function befund(over: Partial<ReportFehlbild> = {}): ReportFehlbild {
  return {
    slug: 'vorzeichen_ignoriert',
    familie: 'vorzeichen',
    familieElterntext: 'Ihr Kind verliert beim Rechnen das Vorzeichen.',
    anzahl: 2,
    aufgaben: 2,
    skills: ['vorzeichen_add_sub'],
    skillUebergreifend: false,
    einstufung: 'befund',
    ...over,
  }
}

describe('gruppiereFehlbilderNachFamilie — Bündelung', () => {
  it('fasst mehrere Slugs derselben Familie zu EINEM Block zusammen', () => {
    const blocks = gruppiereFehlbilderNachFamilie([
      befund({ slug: 'vorzeichen_ignoriert', anzahl: 2, aufgaben: 2 }),
      befund({ slug: 'betrag_fehler', anzahl: 3, aufgaben: 2 }),
      befund({ slug: 'seiten_verwechselt', anzahl: 1, aufgaben: 1 }),
    ])

    expect(blocks).toHaveLength(1)
    expect(blocks[0].familie).toBe('vorzeichen')
    expect(blocks[0].elterntext).toBe('Ihr Kind verliert beim Rechnen das Vorzeichen.')
  })

  it('summiert die Vorkommen über alle Slugs der Familie', () => {
    const blocks = gruppiereFehlbilderNachFamilie([
      befund({ slug: 'a', anzahl: 2, aufgaben: 2 }),
      befund({ slug: 'b', anzahl: 3, aufgaben: 2 }),
    ])
    expect(blocks[0].anzahl).toBe(5)
  })

  it('gibt den Elterntext wörtlich weiter, ohne Umformulierung', () => {
    const text =
      'Ihr Kind rechnet sauber, wählt bei Textaufgaben aber den falschen Rechenweg.'
    const blocks = gruppiereFehlbilderNachFamilie([
      befund({ familie: 'sachaufgaben', familieElterntext: text }),
    ])
    expect(blocks[0].elterntext).toBe(text)
  })
})

describe('gruppiereFehlbilderNachFamilie — Schwelle NACH der Bündelung', () => {
  // Der Kern von R2. Vorher filterte lsaReport auf einstufung='befund' und
  // bündelte erst danach — genau dieser Fall ging dabei verloren.
  it('rettet zwei Einzeltreffer derselben Familie aus VERSCHIEDENEN Skills', () => {
    const text = 'Ihr Kind rechnet der Reihe nach von links nach rechts.'
    const blocks = gruppiereFehlbilderNachFamilie([
      befund({
        slug: 'mult_add_verwechslung',
        familie: 'rechenreihenfolge',
        familieElterntext: text,
        anzahl: 1,
        aufgaben: 1,
        skills: ['vorzeichen_mult_div'],
        einstufung: 'beobachtung',
      }),
      befund({
        slug: 'vorrang_ignoriert',
        familie: 'rechenreihenfolge',
        familieElterntext: text,
        anzahl: 1,
        aufgaben: 1,
        skills: ['vorzeichen_vorrang'],
        einstufung: 'beobachtung',
      }),
    ])

    expect(blocks).toHaveLength(1)
    expect(blocks[0]).toMatchObject({
      familie: 'rechenreihenfolge',
      anzahl: 2,
      aufgaben: 2,
    })
  })

  it('lässt einen echten Einzeltreffer weiter weg', () => {
    expect(gruppiereFehlbilderNachFamilie([befund({ anzahl: 1, aufgaben: 1 })])).toEqual([])
  })

  it('lässt zwei Vorkommen in EINER Aufgabe weg', () => {
    // Zwei Teilaufgaben desselben Items sind eine Aufgabe.
    expect(
      gruppiereFehlbilderNachFamilie([
        befund({ slug: 'a', anzahl: 1, aufgaben: 1, skills: ['gleichung_modellieren'] }),
        befund({ slug: 'b', anzahl: 1, aufgaben: 1, skills: ['gleichung_modellieren'] }),
      ]),
    ).toEqual([])
  })

  it('nimmt eine Einstufung „beobachtung" nicht mehr als Ausschlussgrund', () => {
    const blocks = gruppiereFehlbilderNachFamilie([
      befund({ einstufung: 'beobachtung', anzahl: 2, aufgaben: 2 }),
    ])
    expect(blocks).toHaveLength(1)
  })
})

describe('aufgabenUntergrenze — überschätzt nie', () => {
  it('summiert über disjunkte Skill-Mengen', () => {
    // Eine Aufgabe hat genau einen skill_key -> verschiedene Skills, also
    // verschiedene Aufgaben. Bewiesen, nicht geschätzt.
    expect(
      aufgabenUntergrenze([
        befund({ aufgaben: 2, skills: ['a'] }),
        befund({ aufgaben: 3, skills: ['b'] }),
      ]),
    ).toBe(5)
  })

  it('nimmt bei gemeinsamem Skill nur das Maximum', () => {
    expect(
      aufgabenUntergrenze([
        befund({ aufgaben: 2, skills: ['a'] }),
        befund({ aufgaben: 3, skills: ['a'] }),
      ]),
    ).toBe(3)
  })

  it('verschmilzt Gruppen, die ein skill-übergreifender Slug verbindet', () => {
    expect(
      aufgabenUntergrenze([
        befund({ aufgaben: 2, skills: ['a'] }),
        befund({ aufgaben: 3, skills: ['b'] }),
        befund({ aufgaben: 4, skills: ['a', 'b'] }),
      ]),
    ).toBe(4)
  })

  it('fällt auf das Maximum zurück, wenn ein Slug keinen Skill trägt', () => {
    // Ohne Skill ist über Überlappung nichts beweisbar.
    expect(
      aufgabenUntergrenze([
        befund({ aufgaben: 2, skills: [] }),
        befund({ aufgaben: 3, skills: ['b'] }),
      ]),
    ).toBe(3)
  })

  it('ist 0 bei leerer Eingabe', () => {
    expect(aufgabenUntergrenze([])).toBe(0)
  })
})

describe('gruppiereFehlbilderNachFamilie — stilles Weglassen', () => {
  it('lässt Fehlbilder ohne Familienzuordnung weg', () => {
    expect(
      gruppiereFehlbilderNachFamilie([
        befund({ slug: 'teilgekuerzt', familie: null, familieElterntext: null }),
      ]),
    ).toEqual([])
  })

  it('lässt Familien ohne abgenommenen Elterntext weg', () => {
    expect(
      gruppiereFehlbilderNachFamilie([
        befund({ familie: 'rechenreihenfolge', familieElterntext: null }),
      ]),
    ).toEqual([])
  })

  it('behandelt einen leeren Elterntext wie einen fehlenden', () => {
    expect(gruppiereFehlbilderNachFamilie([befund({ familieElterntext: '   ' })])).toEqual([])
  })

  it('lässt nur die unvollständigen Befunde weg, nicht die vollständigen', () => {
    const blocks = gruppiereFehlbilderNachFamilie([
      befund({ slug: 'ohne_familie', familie: null, familieElterntext: null }),
      befund({ familie: 'vorzeichen', anzahl: 4, aufgaben: 2 }),
      befund({ slug: 'nicht_frei', familie: 'sachaufgaben', familieElterntext: null }),
    ])

    expect(blocks.map((b) => b.familie)).toEqual(['vorzeichen'])
    expect(blocks[0].anzahl).toBe(4)
  })

  it('liefert eine leere Liste, wenn kein Befund übrig bleibt', () => {
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
      befund({ familie: 'a', familieElterntext: 'A', anzahl: 2, aufgaben: 2 }),
      befund({ familie: 'b', familieElterntext: 'B', anzahl: 5, aufgaben: 2 }),
      befund({ familie: 'c', familieElterntext: 'C', anzahl: 3, aufgaben: 2 }),
    ])

    expect(blocks.map((b) => b.familie)).toEqual(['b', 'c', 'a'])
    expect(blocks.map((b) => b.anzahl)).toEqual([5, 3, 2])
  })

  it('sortiert nach der SUMME, nicht nach dem größten Einzelwert', () => {
    const blocks = gruppiereFehlbilderNachFamilie([
      befund({ slug: 'x', familie: 'gross', familieElterntext: 'G', anzahl: 4, aufgaben: 2 }),
      befund({
        slug: 'y', familie: 'viele', familieElterntext: 'V',
        anzahl: 3, aufgaben: 2, skills: ['p'],
      }),
      befund({
        slug: 'z', familie: 'viele', familieElterntext: 'V',
        anzahl: 3, aufgaben: 2, skills: ['q'],
      }),
    ])

    expect(blocks.map((b) => b.familie)).toEqual(['viele', 'gross'])
  })

  it('ist bei Gleichstand stabil und unabhängig von der Eingabereihenfolge', () => {
    const a = befund({
      familie: 'einheiten_massstab', familieElterntext: 'E', anzahl: 2, aufgaben: 2,
    })
    const b = befund({ familie: 'vorzeichen', familieElterntext: 'V', anzahl: 2, aufgaben: 2 })

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
    const eingabe = [
      befund({ familie: 'b', familieElterntext: 'B', anzahl: 2, aufgaben: 2 }),
    ]
    const kopie = structuredClone(eingabe)
    gruppiereFehlbilderNachFamilie(eingabe)

    expect(eingabe).toEqual(kopie)
  })
})
