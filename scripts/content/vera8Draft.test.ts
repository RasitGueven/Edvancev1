// Der Bau gegen die DB-Vertraege. Was hier gruen ist, faellt nicht am CHECK um.
//
// Die drei Zusagen, die diese Suite haelt:
//   1. Keine Loesung in tasks (question_payload, parts) — T1b/INV-6.
//   2. Kein Item wird 'ready', kein curriculum_grade wird geraten — A01.
//   3. Was P02/F01 nicht halten koennen, wird ABGEWIESEN und geflaggt, nicht
//      wohlmeinend repariert.

import { describe, expect, it } from 'vitest'
import { buildItem, coveredAssets, partsValid, toTable, type V2Item } from './vera8Draft'

const CC_BY_MIT_GRAFIK =
  'Copyright Grafik, Text und Teilaufgaben: IQB e. V., Lizenz: Creative Commons (CC BY).'
const CC_BY_OHNE_GRAFIK = 'Copyright Text und Teilaufgaben: IQB e. V., Lizenz: Creative Commons (CC BY).'

const item = (over: Partial<V2Item>): V2Item => ({
  id: 'id-1',
  titel: 'Testitem',
  klasse: 8,
  input_type: 'SHORT_INPUT',
  stem: { text: '', table: null },
  parts: [],
  assets: [],
  ...over,
})

const shortPart = (over = {}) => ({
  nr: 1,
  kind: 'short_input',
  prompt: 'Berechne 20 % von 80 m.',
  unit: 'm',
  correct_answers: ['16'],
  afb_raw: 'I',
  kompetenzen: ['K5'],
  leitidee: 'Zahl (L1)',
  ...over,
})

describe('flache Items', () => {
  it('setzt NUMERIC bei numerischer Loesung und traegt die Loesung NICHT ins Item', () => {
    const b = buildItem(item({ parts: [shortPart()] }))
    expect(b.row.input_type).toBe('NUMERIC')
    expect(b.row.question).toBe('Berechne 20 % von 80 m.')
    expect(b.row.unit).toBe('m')
    expect(b.row.afb).toBe('I')
    expect(b.answers).toEqual(['16'])
    // Die Loesung lebt in task_solutions — nirgends sonst.
    expect(JSON.stringify(b.row)).not.toContain('16')
  })

  it('setzt SHORT_TEXT bei nicht-numerischer Loesung', () => {
    const b = buildItem(item({ parts: [shortPart({ correct_answers: ['Montag'] })] }))
    expect(b.row.input_type).toBe('SHORT_TEXT')
  })

  it('flaggt ein SHORT_INPUT ohne belegte Loesung, statt einen Typ zu raten', () => {
    const b = buildItem(item({ parts: [shortPart({ correct_answers: [] })] }))
    expect(b.answers).toBeNull()
    expect(b.importFlags.join(' ')).toContain('keine Loesung belegt')
    expect(b.poolReadyAfterCare).toBe(false)
  })

  it('legt MC-Optionen ins question_payload — ohne die Loesung', () => {
    const b = buildItem(
      item({
        input_type: 'MC',
        parts: [
          shortPart({
            kind: 'mc',
            options: [
              { id: 'a', label: '60 min' },
              { id: 'b', label: '150 min' },
            ],
            correct_answers: ['b'],
          }),
        ],
      }),
    )
    expect(b.row.input_type).toBe('MC')
    expect(b.row.question_payload).toMatchObject({ input_type: 'MC' })
    expect(b.answers).toEqual(['b'])
    expect(Object.keys(b.row.question_payload ?? {})).not.toContain('correct')
  })

  it('fuehrt den Freitext-Erwartungshorizont als Beleg, nicht als correct_answers', () => {
    const b = buildItem(
      item({ input_type: 'FREE_TEXT', parts: [shortPart({ kind: 'free_text', correct_answers: ['Begruendung: …'] })] }),
    )
    expect(b.row.input_type).toBe('FREE_TEXT')
    // lsa_is_correct wuerde sonst versuchen, Freitext zu messen.
    expect(b.answers).toBeNull()
    expect(b.belege[0]?.feld).toBe('erwartungshorizont')
    expect(b.belege[0]?.zitat).toContain('Begruendung')
    expect(b.poolReadyAfterCare).toBe(false)
  })
})

describe('Multi-Part (P02)', () => {
  const zweiTeile = [shortPart({ nr: 1 }), shortPart({ nr: 2, prompt: 'Und nun?', correct_answers: ['48'] })]

  it('speichert konforme Teilaufgaben und schluesselt die Loesung nach nr', () => {
    const b = buildItem(item({ input_type: 'MULTI_PART', stem: { text: 'Ein Stamm.' }, parts: zweiTeile }))
    expect(b.row.input_type).toBe('MULTI_PART')
    expect(b.row.parts).toHaveLength(2)
    expect(b.answers).toEqual({ '1': ['16'], '2': ['48'] })
    // tasks_multipart_check verlangt est_duration_sec — der Platzhalter wird geflaggt.
    expect(b.row.est_duration_sec).toBe(180)
    expect(b.importFlags.join(' ')).toContain('Platzhalter')
    // lsa_parts_valid: kein Loesungsfeld in der oeffentlichen Struktur.
    expect(JSON.stringify(b.row.parts)).not.toContain('correct_answers')
  })

  it('weist Freitext-Teilaufgaben ab (P02 kennt nur short_input|mc) und verliert sie nicht', () => {
    const b = buildItem(
      item({
        input_type: 'MULTI_PART',
        stem: { text: 'Ein Stamm.' },
        parts: [zweiTeile[0], shortPart({ nr: 2, kind: 'free_text' })],
      }),
    )
    expect(b.row.input_type).toBeNull()
    expect(b.row.parts).toEqual([])
    expect(b.droppedParts).toHaveLength(2)
    expect(b.importFlags.join(' ')).toContain('Freitext-Teilaufgabe')
  })

  it('weist Multi-Part ohne Stamm ab — tasks_multipart_check verlangt einen', () => {
    const b = buildItem(item({ input_type: 'MULTI_PART', stem: { text: '' }, parts: zweiTeile }))
    expect(b.row.input_type).toBeNull()
    expect(b.importFlags.join(' ')).toContain('kein Stamm')
  })

  it('partsValid spiegelt lsa_parts_valid', () => {
    expect(partsValid([shortPart()])).toBe(false) // <2
    expect(partsValid(zweiTeile)).toBe(true)
    expect(partsValid([shortPart({ nr: 1 }), shortPart({ nr: 1 })])).toBe(false) // nr doppelt
    expect(partsValid([shortPart({ nr: 1 }), shortPart({ nr: 2, kind: 'mc', options: [{ id: 'a', label: 'A' }] })])).toBe(
      false,
    ) // MC mit 1 Option
  })
})

describe('Tabellen (F01)', () => {
  it('uebernimmt eine gueltige Tabelle und benennt header → headers um', () => {
    const b = buildItem(
      item({
        parts: [shortPart()],
        stem: { text: 'Stamm', table: { header: ['A', 'B'], rows: [['1', '2']] } },
      }),
    )
    expect(b.row.question_payload).toEqual({ table: { headers: ['A', 'B'], rows: [['1', '2']] } })
  })

  it('weist ein Layout-Raster mit leeren Kopfzellen ab, statt es zu reparieren', () => {
    const b = buildItem(
      item({
        parts: [shortPart()],
        stem: { text: 'Stamm', table: { header: ['', 'y', ''], rows: [['80', '', '']] } },
      }),
    )
    expect(b.row.question_payload).toBeNull()
    expect(b.importFlags.join(' ')).toContain('F01-Vertrag')
  })

  it('toTable weist ragged rows und Nicht-Strings ab', () => {
    expect(toTable({ header: ['A', 'B'], rows: [['1']] })).toBeNull()
    expect(toTable({ header: ['A'], rows: [[1]] })).toBeNull()
    expect(toTable({ header: ['A'], rows: [] })).toBeNull()
  })
})

describe('Assets & Lizenz', () => {
  it('nimmt nur Grafiken, deren Lizenzzeile das Wort "Grafik" nennt', () => {
    const { kept, dropped } = coveredAssets([
      { kind: 'image', verweis: 'a.png', lizenz_hinweis: CC_BY_MIT_GRAFIK },
      { kind: 'image', verweis: 'b.png', lizenz_hinweis: CC_BY_OHNE_GRAFIK },
    ])
    expect(kept.map((a) => a.verweis)).toEqual(['a.png'])
    expect(dropped).toHaveLength(1)
  })

  it('flaggt die weggelassene Abbildung am Item', () => {
    const b = buildItem(
      item({ parts: [shortPart()], assets: [{ kind: 'image', verweis: 'b.png', lizenz_hinweis: CC_BY_OHNE_GRAFIK }] }),
    )
    expect(b.row.assets).toEqual([])
    expect(b.importFlags.join(' ')).toContain('CC BY deckt sie damit nicht')
  })

  it('setzt einen leeren Alt-Text — den schreibt ein Mensch, nicht der Import', () => {
    const b = buildItem(
      item({ parts: [shortPart()], assets: [{ kind: 'image', verweis: 'a.png', lizenz_hinweis: CC_BY_MIT_GRAFIK }] }),
    )
    expect(b.row.assets).toEqual([{ url: 'a.png', alt: '' }])
  })
})

describe('Was der Import NICHT tut', () => {
  it('setzt keinen Stoffanker und kein ready', () => {
    const b = buildItem(item({ parts: [shortPart()] }))
    expect(b.row.status).toBe('draft')
    expect(b.row).not.toHaveProperty('curriculum_grade')
    // class_level ist die Herkunft (VERA-8), nicht der Stoff.
    expect(b.row.class_level).toBe(8)
  })

  it('haengt den Loesungsbeleg an die Loesung, nicht an das Item', () => {
    const b = buildItem(
      item({
        parts: [shortPart()],
        _grounding: {
          'part1.correct_answers': { gate: 'G2', quelle: 'Auswertung.docx', zitat: '16' },
          'part1.prompt': { gate: 'G1', quelle: 'Aufgabe.docx', zitat: 'Berechne 20 % von 80 m.' },
        },
      }),
    )
    expect(b.belege).toEqual([
      { feld: 'part1.correct_answers', quelle: 'Auswertung.docx', gate: 'G2', zitat: '16' },
    ])
    // Der Prompt-Beleg ist kein Loesungsbeleg — er bleibt im oeffentlichen Index.
    expect(JSON.stringify(b.belege)).not.toContain('Aufgabe.docx')
  })

  // B01: der Beleg hat ein eigenes Feld. Landete er wieder in `solution`, wuerde der
  // erste von Hand geschriebene Loesungsweg ihn ueberschreiben — genau der Defekt,
  // den C08 offen gelassen hat.
  it('traegt den Beleg strukturiert, nie als Loesungstext', () => {
    const b = buildItem(
      item({
        parts: [shortPart()],
        _grounding: { 'part1.correct_answers': { quelle: 'Auswertung.docx', zitat: '16' } },
      }),
    )
    expect(b).not.toHaveProperty('solutionBeleg')
    expect(b.belege[0]).toEqual({ feld: 'part1.correct_answers', quelle: 'Auswertung.docx', zitat: '16' })
  })
})
