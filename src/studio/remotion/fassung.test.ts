import { createHash } from 'node:crypto'
import { readdirSync, readFileSync, statSync } from 'node:fs'
import path from 'node:path'
import { describe, expect, it } from 'vitest'
import { RENDER_QUELLEN_HASH } from './fassung'

const ORDNER = 'src/studio/remotion'

/** Alle Quellen der Komposition außer Tests und dieser Fassungsdatei, sortiert. */
function quellen(dir: string): string[] {
  return readdirSync(dir)
    .flatMap((n) => {
      const p = path.join(dir, n)
      return statSync(p).isDirectory() ? quellen(p) : [p]
    })
    .filter((p) => !p.endsWith('.test.ts') && !p.endsWith('fassung.ts'))
    .sort()
}

describe('Renderer-Fassung', () => {
  it('Quellen unverändert — sonst studio_render_fassung() erhöhen und Hash nachziehen', () => {
    const h = createHash('sha256')
    for (const p of quellen(ORDNER)) h.update(p).update(readFileSync(p))
    expect(h.digest('hex')).toBe(RENDER_QUELLEN_HASH)
  })
})
