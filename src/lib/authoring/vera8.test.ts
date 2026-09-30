// Die VERA8-Definition gibt es einmal (vera8.json). Board, Prefill-Werkzeuge und
// die SQL-Bedingung in freigabe_cluster muessen dieselbe Kennung benutzen.

import fs from 'node:fs'
import { describe, expect, it } from 'vitest'
import { VERA8_SOURCE, istVera8 } from './vera8'

describe('VERA8-Definition', () => {
  it('erkennt VERA8 nur an der Herkunft', () => {
    expect(VERA8_SOURCE).toBe('VERA8_IQB')
    expect(istVera8({ source: 'VERA8_IQB' })).toBe(true)
    expect(istVera8({ source: 'edvance_fundament' })).toBe(false)
    expect(istVera8({ source: null })).toBe(false)
  })

  it('freigabe_cluster schliesst dieselbe Kennung aus', () => {
    const sql = fs.readFileSync('supabase/migrations/20260930130000_freigabe_cluster_ohne_vera8.sql', 'utf8')
    expect(sql).toContain(`and source is distinct from '${VERA8_SOURCE}'`)
  })

  it('jede Prefill-Migration traegt den Ausschluss in jeder Anweisung', () => {
    const dir = 'supabase/migrations'
    const dateien = fs.readdirSync(dir).filter((f) => /_prefill_.*\.sql$/.test(f))
    expect(dateien.length).toBeGreaterThan(0)
    for (const f of dateien) {
      const anweisungen = fs.readFileSync(`${dir}/${f}`, 'utf8').split(/;\s*\n/)
        .map((s) => s.replace(/^(\s*--[^\n]*\n)+/, '').trim())
        .filter((s) => /^(update|insert)\b/i.test(s))
      for (const s of anweisungen) expect(s).toMatch(new RegExp(`source is distinct from '${VERA8_SOURCE}'`))
    }
  })
})
