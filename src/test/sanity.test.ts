import { describe, expect, it } from 'vitest'

// Sanity test: guarantees the vitest pipeline always has at least one real test,
// so a green run never means "no tests were found".
describe('vitest sanity', () => {
  it('runs the test pipeline', () => {
    expect(1 + 1).toBe(2)
  })
})
