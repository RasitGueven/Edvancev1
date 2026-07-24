import { describe, expect, it } from 'vitest'
import { blockingFlags, canRelease, computeFlags, hasTable } from './flags'
import type { AuthoringTask, TaskSolution } from '@/types'

const baseTask: AuthoringTask = {
  id: 't1',
  title: 'Zwanzig Prozent',
  question: 'Berechne 20 % von 80 m.',
  status: 'draft',
  input_type: 'SHORT_TEXT',
  afb: 'I',
  competency_content: 'arithmetik_algebra',
  competency_process: 'ope',
  cluster_id: 'c1',
  unit: 'm',
  est_duration_sec: 120,
  skill_key: null,
  class_level: 8,
  curriculum_grade: 7,
  parts: [],
  assets: [],
  needs_image: null,
  licence_text: null,
  question_payload: null,
  source: 'VERA8_IQB',
  source_ref: 'abc',
  is_active: true,
  created_at: '2026-07-01T00:00:00Z',
}

const baseSolution: TaskSolution = {
  exists: true,
  correct_answers: ['16'],
  solution: '80 m · 0,2 = 16 m',
  beleg: [],
  hints: [],
  coach_hints: [],
  typical_errors: [{ error: 'Grundwert und Prozentwert vertauscht' }],
}

const task = (over: Partial<AuthoringTask> = {}): AuthoringTask => ({ ...baseTask, ...over })
const sol = (over: Partial<TaskSolution> = {}): TaskSolution => ({ ...baseSolution, ...over })
const codes = (t: AuthoringTask, s: TaskSolution, hasField = true): string[] =>
  computeFlags(t, s, hasField).map((f) => f.code)

describe('computeFlags — flaches Item', () => {
  it('meldet nichts bei einem vollstaendigen Item', () => {
    expect(codes(task(), sol())).toEqual([])
  })

  it('blockiert ohne Stamm, Typ, AFB, Kompetenz, Cluster', () => {
    const t = task({
      question: '   ',
      input_type: null,
      afb: null,
      competency_content: null,
      cluster_id: null,
    })
    const found = codes(t, sol())
    expect(found).toContain('stemMissing')
    expect(found).toContain('inputTypeMissing')
    expect(found).toContain('afbMissing')
    expect(found).toContain('competencyMissing')
    expect(found).toContain('clusterMissing')
    expect(canRelease(computeFlags(t, sol(), true))).toBe(false)
  })

  it('blockiert ohne Loesung — leere Strings zaehlen nicht', () => {
    expect(codes(task(), sol({ correct_answers: [] }))).toContain('solutionMissing')
    expect(codes(task(), sol({ correct_answers: ['  '] }))).toContain('solutionMissing')
  })

  it('blockiert MC ohne mindestens zwei Optionen', () => {
    const mc = task({ input_type: 'MC', question_payload: { options: [{ id: 'a', label: 'A' }] } })
    expect(codes(mc, sol())).toContain('mcOptionsMissing')

    const ok = task({
      input_type: 'MC',
      question_payload: { options: [{ id: 'a', label: 'A' }, { id: 'b', label: 'B' }] },
    })
    expect(codes(ok, sol())).not.toContain('mcOptionsMissing')
  })

  it('blockiert parts an einem flachen Item (tasks_multipart_check)', () => {
    const t = task({ parts: [{ nr: 1, kind: 'short_input', prompt: 'x' }] })
    expect(codes(t, sol())).toContain('partsOnFlatItem')
  })

  it('blockiert ein Bild ohne Alt-Text und nennt die Position', () => {
    const t = task({
      assets: [
        { url: 'a.png', alt: 'Ein Diagramm' },
        { url: 'b.png', alt: '' },
      ],
    })
    const flags = computeFlags(t, sol(), true)
    const alt = flags.find((f) => f.code === 'assetAltMissing')
    expect(alt?.blocking).toBe(true)
    expect(alt?.vars).toEqual({ index: 2 })
  })

  it('blockiert ein Bild ohne Lizenz-/Quellenangabe (A09)', () => {
    const t = task({ assets: [{ url: 'a.png', alt: 'Ein Diagramm' }], licence_text: null })
    const licence = computeFlags(t, sol(), true).find((f) => f.code === 'licenceMissing')
    expect(licence?.blocking).toBe(true)
  })

  it('schweigt zum Lizenztext, wenn ein Bild ihn traegt', () => {
    const t = task({
      assets: [{ url: 'a.png', alt: 'Ein Diagramm' }],
      licence_text: 'Quelle: IQB, VERA-8. Lizenz: CC BY 4.0.',
    })
    expect(computeFlags(t, sol(), true).some((f) => f.code === 'licenceMissing')).toBe(false)
  })

  it('verlangt keinen Lizenztext ohne Bild', () => {
    const t = task({ assets: [], licence_text: null })
    expect(computeFlags(t, sol(), true).some((f) => f.code === 'licenceMissing')).toBe(false)
  })

  it('meldet Extraktions-Artefakte im Stamm, ohne zu blockieren', () => {
    const flags = computeFlags(task({ question: 'x = __________' }), sol(), true)
    const artifact = flags.find((f) => f.code === 'stemFieldLabel')
    expect(artifact?.blocking).toBe(false)
  })

  it('meldet fehlende Musterloesung und typische Fehler als Hinweis', () => {
    const flags = computeFlags(task(), sol({ solution: null, typical_errors: [] }), true)
    expect(blockingFlags(flags)).toEqual([])
    expect(flags.map((f) => f.code)).toEqual(['solutionTextMissing', 'typicalErrorsMissing'])
  })
})

describe('computeFlags — Stoffanker', () => {
  it('blockiert, wenn das Feld existiert und leer ist', () => {
    const flags = computeFlags(task({ curriculum_grade: null }), sol(), true)
    expect(flags.find((f) => f.code === 'stoffankerMissing')?.blocking).toBe(true)
  })

  it('blockiert NICHT, wenn die Spalte in der DB noch fehlt', () => {
    const flags = computeFlags(task({ curriculum_grade: undefined }), sol(), false)
    expect(flags.find((f) => f.code === 'stoffankerNoField')?.blocking).toBe(false)
    expect(canRelease(flags)).toBe(true)
  })
})

describe('computeFlags — MULTI_PART', () => {
  const multi = (over: Partial<AuthoringTask> = {}): AuthoringTask =>
    task({
      input_type: 'MULTI_PART',
      afb: null,
      competency_content: null,
      parts: [
        { nr: 1, kind: 'short_input', prompt: 'Wie viel Prozent?', afb: 'I', competency_content: 'arithmetik_algebra' },
        {
          nr: 2,
          kind: 'mc',
          prompt: 'Welche Aussage stimmt?',
          afb: 'II',
          competency_content: 'arithmetik_algebra',
          options: [
            { id: 'a', label: 'A' },
            { id: 'b', label: 'B' },
          ],
        },
      ],
      ...over,
    })

  const multiSol = (answers: Record<string, string[]>): TaskSolution =>
    sol({ correct_answers: answers })

  it('meldet nichts bei vollstaendigem Multi-Part', () => {
    expect(codes(multi(), multiSol({ '1': ['20'], '2': ['b'] }))).toEqual([])
  })

  it('verlangt AFB und Kompetenz je Teilaufgabe, nicht am Item', () => {
    const t = multi({
      parts: [
        { nr: 1, kind: 'short_input', prompt: 'a' },
        { nr: 2, kind: 'short_input', prompt: 'b' },
      ],
    })
    const found = codes(t, multiSol({ '1': ['1'], '2': ['2'] }))
    expect(found).toContain('partAfbMissing')
    expect(found).toContain('partCompetencyMissing')
    // Das Item selbst braucht sie dann nicht.
    expect(found).not.toContain('afbMissing')
    expect(found).not.toContain('competencyMissing')
  })

  it('blockiert, wenn auch nur EINER Teilaufgabe die Loesung fehlt', () => {
    const flags = computeFlags(multi(), multiSol({ '1': ['20'] }), true)
    const missing = flags.find((f) => f.code === 'partSolutionMissing')
    expect(missing?.vars).toEqual({ nr: 2 })
    expect(canRelease(flags)).toBe(false)
  })

  it('erkennt die flache Antwortform als fehlende Teilloesungen', () => {
    const flags = computeFlags(multi(), sol({ correct_answers: ['20', 'b'] }), true)
    expect(flags.filter((f) => f.code === 'partSolutionMissing')).toHaveLength(2)
  })

  it('blockiert bei weniger als zwei Teilaufgaben', () => {
    const t = multi({ parts: [{ nr: 1, kind: 'short_input', prompt: 'a', afb: 'I' }] })
    expect(codes(t, multiSol({ '1': ['1'] }))).toContain('partsTooFew')
  })

  it('blockiert doppelte Teilaufgaben-Nummern', () => {
    const t = multi({
      parts: [
        { nr: 1, kind: 'short_input', prompt: 'a', afb: 'I', competency_content: 'x' },
        { nr: 1, kind: 'short_input', prompt: 'b', afb: 'I', competency_content: 'x' },
      ],
    })
    expect(codes(t, multiSol({ '1': ['1'] }))).toContain('partNrDuplicate')
  })

  it('blockiert MC-Teilaufgabe mit weniger als zwei Optionen', () => {
    const t = multi({
      parts: [
        { nr: 1, kind: 'short_input', prompt: 'a', afb: 'I', competency_content: 'x' },
        { nr: 2, kind: 'mc', prompt: 'b', afb: 'I', competency_content: 'x', options: [{ id: 'a', label: 'A' }] },
      ],
    })
    expect(codes(t, multiSol({ '1': ['1'], '2': ['a'] }))).toContain('partMcOptionsMissing')
  })

  it('macht das Zeitbudget zur Pflicht (DB-CHECK), beim flachen Item nur zum Hinweis', () => {
    const m = computeFlags(multi({ est_duration_sec: null }), multiSol({ '1': ['20'], '2': ['b'] }), true)
    expect(m.find((f) => f.code === 'estDurationMissing')?.blocking).toBe(true)

    const f = computeFlags(task({ est_duration_sec: null }), sol(), true)
    expect(f.find((f2) => f2.code === 'estDurationMissing')?.blocking).toBe(false)
  })
})

describe('hasTable', () => {
  it('erkennt eine GFM-Tabelle im Stamm', () => {
    expect(hasTable('Text\n\n| a | b |\n| --- | --- |\n| 1 | 2 |')).toBe(true)
  })
  it('haelt normalen Text und Betraege nicht fuer eine Tabelle', () => {
    expect(hasTable('Der Preis liegt bei 3 | 4 Euro')).toBe(false)
    expect(hasTable('Berechne 20 % von 80 m.')).toBe(false)
    expect(hasTable(null)).toBe(false)
  })
})
