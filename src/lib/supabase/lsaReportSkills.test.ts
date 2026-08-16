import { describe, expect, it, vi, beforeEach } from 'vitest'

/**
 * Die Skill-Ebene des Eltern-Reports (R2).
 *
 * Geprüft wird die AUSWAHL- und Verdichtungslogik, nicht Supabase: welche
 * Urteile in den Abschnitt kommen, welche stillschweigend nicht, und wann der
 * Abschnitt ganz entfällt. Der Client ist deshalb gemockt — er ist hier nur
 * Zulieferer.
 */

type Row = Record<string, unknown>
let urteilRows: Row[] = []
let skillRows: Row[] = []
let urteilError: unknown = null
let skillError: unknown = null

vi.mock('@/lib/supabase/client', () => {
  const bauUrteil = () => {
    const q = {
      select: () => q,
      eq: () => q,
      then: (res: (v: unknown) => unknown) =>
        Promise.resolve({ data: urteilRows, error: urteilError }).then(res),
    }
    return q
  }
  const bauSkills = () => {
    const q = {
      select: () => q,
      in: () => Promise.resolve({ data: skillRows, error: skillError }),
    }
    return q
  }
  return {
    supabase: {
      from: (tabelle: string) =>
        tabelle === 'lsa_skill_urteil' ? bauUrteil() : bauSkills(),
    },
  }
})

const { loadSkillbefunde } = await import('@/lib/supabase/lsaReportSkills')

beforeEach(() => {
  urteilRows = []
  skillRows = []
  urteilError = null
  skillError = null
})

describe('loadSkillbefunde — welche Urteile in den Abschnitt kommen', () => {
  it('nimmt traegt_nicht auf und nennt es beim Label', async () => {
    urteilRows = [{ skill_key: 'term_ausklammern', zustand: 'traegt_nicht' }]
    skillRows = [{ skill_key: 'term_ausklammern', label: 'Ausklammern', fundament_tiefe: 7 }]

    const b = await loadSkillbefunde('s1')
    expect(b?.nichtTragend).toEqual([
      { skillKey: 'term_ausklammern', label: 'Ausklammern', fundamentTiefe: 7 },
    ])
  })

  it('nimmt traegt_teilweise ebenfalls auf', async () => {
    urteilRows = [{ skill_key: 'bruch_add', zustand: 'traegt_teilweise' }]
    skillRows = [{ skill_key: 'bruch_add', label: 'Brüche addieren', fundament_tiefe: 2 }]

    const b = await loadSkillbefunde('s1')
    expect(b?.nichtTragend.map((s) => s.label)).toEqual(['Brüche addieren'])
  })

  it('zählt tragende Bereiche, ohne sie aufzuzählen', async () => {
    urteilRows = [
      { skill_key: 'a', zustand: 'traegt' },
      { skill_key: 'b', zustand: 'traegt' },
      { skill_key: 'c', zustand: 'traegt_nicht' },
    ]
    skillRows = [{ skill_key: 'c', label: 'Ausklammern', fundament_tiefe: 7 }]

    const b = await loadSkillbefunde('s1')
    expect(b?.tragendAnzahl).toBe(2)
    expect(b?.nichtTragend).toHaveLength(1)
  })

  it('zählt nicht_angesetzt weder als Befund noch als tragend', async () => {
    // Das Kind hat dort nichts versucht — fehlende Evidenz ist kein Befund.
    urteilRows = [
      { skill_key: 'a', zustand: 'nicht_angesetzt' },
      { skill_key: 'b', zustand: 'ungeprueft' },
      { skill_key: 'c', zustand: 'traegt' },
    ]
    const b = await loadSkillbefunde('s1')
    expect(b?.tragendAnzahl).toBe(1)
    expect(b?.nichtTragend).toEqual([])
  })

  it('lässt einen Skill ohne Label weg, statt den Schlüssel zu zeigen', async () => {
    // skill_key ist snake_case und kein Satz für Eltern (INV-4.3).
    urteilRows = [{ skill_key: 'ohne_label', zustand: 'traegt_nicht' }]
    skillRows = [{ skill_key: 'ohne_label', label: null, fundament_tiefe: 3 }]

    const b = await loadSkillbefunde('s1')
    expect(b?.nichtTragend).toEqual([])
  })
})

describe('loadSkillbefunde — Reihenfolge und Fundamenttiefe', () => {
  it('sortiert absteigend nach Fundamenttiefe', async () => {
    urteilRows = [
      { skill_key: 'tief', zustand: 'traegt_nicht' },
      { skill_key: 'hoch', zustand: 'traegt_nicht' },
    ]
    skillRows = [
      { skill_key: 'tief', label: 'Negative Zahlen', fundament_tiefe: 2 },
      { skill_key: 'hoch', label: 'Gleichungen aufstellen', fundament_tiefe: 8 },
    ]

    const b = await loadSkillbefunde('s1')
    expect(b?.nichtTragend.map((s) => s.label)).toEqual([
      'Gleichungen aufstellen',
      'Negative Zahlen',
    ])
  })

  it('meldet zurueckgegangen, wenn die Befunde über mehrere Stufen streuen', async () => {
    urteilRows = [
      { skill_key: 'a', zustand: 'traegt_nicht' },
      { skill_key: 'b', zustand: 'traegt_nicht' },
    ]
    skillRows = [
      { skill_key: 'a', label: 'A', fundament_tiefe: 8 },
      { skill_key: 'b', label: 'B', fundament_tiefe: 2 },
    ]

    expect((await loadSkillbefunde('s1'))?.zurueckgegangen).toBe(true)
  })

  it('meldet es NICHT, wenn alle Befunde auf einer Stufe liegen', async () => {
    urteilRows = [
      { skill_key: 'a', zustand: 'traegt_nicht' },
      { skill_key: 'b', zustand: 'traegt_nicht' },
    ]
    skillRows = [
      { skill_key: 'a', label: 'A', fundament_tiefe: 5 },
      { skill_key: 'b', label: 'B', fundament_tiefe: 5 },
    ]

    expect((await loadSkillbefunde('s1'))?.zurueckgegangen).toBe(false)
  })
})

describe('loadSkillbefunde — wann der Abschnitt entfällt', () => {
  it('liefert null, wenn kein Skill direkt geprüft wurde', async () => {
    urteilRows = []
    expect(await loadSkillbefunde('s1')).toBeNull()
  })

  it('liefert eine leere Befundliste, wenn alles trägt', async () => {
    // Die Komponente rendert dann nichts — kein „keine Auffälligkeiten".
    urteilRows = [
      { skill_key: 'a', zustand: 'traegt' },
      { skill_key: 'b', zustand: 'traegt' },
    ]
    const b = await loadSkillbefunde('s1')
    expect(b?.nichtTragend).toEqual([])
    expect(b?.tragendAnzahl).toBe(2)
  })

  it('kippt den Report nicht, wenn die Abfrage scheitert', async () => {
    urteilError = { message: 'boom' }
    expect(await loadSkillbefunde('s1')).toBeNull()
  })
})
