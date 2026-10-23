// LSA-A1 — die pgTAP-Paare für lsa_themenfeld müssen aus dem aktuellen feldVon stammen.

import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'
import { FIXTURE_PFAD, themenfeldFixture } from '../../../../tools/themenfeld-fixture'

const ROOT = resolve(__dirname, '../../../..')

describe('supabase/tests/fixtures/themenfeld.sql', () => {
  it('ist aus feldVon erzeugt und aktuell (sonst: npx tsx --tsconfig tsconfig.app.json tools/themenfeld-fixture.ts)', () => {
    expect(readFileSync(resolve(ROOT, FIXTURE_PFAD), 'utf8')).toBe(themenfeldFixture())
  })

  it('deckt alle acht Felder und weitere ab', () => {
    const felder = new Set([...themenfeldFixture().matchAll(/, '([a-z]+)'\)/g)].map((m) => m[1]))
    expect([...felder].sort()).toEqual(
      ['brueche', 'funktionen', 'geometrie', 'groessen', 'prozent', 'terme', 'weitere', 'zahlen', 'zufall'],
    )
  })
})
