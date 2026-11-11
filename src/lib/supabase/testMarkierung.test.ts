import { describe, expect, it } from 'vitest'
import { istTestVertrag } from './testMarkierung'

describe('istTestVertrag', () => {
  const m = { leads: new Set(['lt']), schueler: new Set(['st']) }
  it('trifft über Lead oder Kind, sonst nicht', () => {
    expect(istTestVertrag({ lead_id: 'lt', student_id: null }, m)).toBe(true)
    expect(istTestVertrag({ lead_id: 'le', student_id: 'st' }, m)).toBe(true)
    expect(istTestVertrag({ lead_id: 'le', student_id: 'se' }, m)).toBe(false)
    expect(istTestVertrag({ lead_id: 'le', student_id: null }, m)).toBe(false)
  })
})
