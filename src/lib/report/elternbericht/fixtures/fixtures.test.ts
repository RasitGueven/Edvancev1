import { existsSync, readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'

import { FAELLE } from '@/lib/report/elternbericht/fixtures'

const SRC = resolve(__dirname, '../../../..')

/** Alle Module, die von `start` aus über '@/…'-Importe erreichbar sind (ohne Typ-Importe). */
function erreichbar(start: string): Set<string> {
  const gesehen = new Set<string>()
  const offen = [start]
  while (offen.length > 0) {
    const datei = offen.pop()!
    if (gesehen.has(datei)) continue
    gesehen.add(datei)
    const text = readFileSync(datei, 'utf8')
    for (const [, art, ziel] of text.matchAll(/^(?:import|export)\s+(type\s+)?[^;]*?from '@\/([^']+)'/gm)) {
      if (art) continue
      const kandidat = [`${ziel}.ts`, `${ziel}.tsx`, `${ziel}/index.ts`]
        .map((k) => resolve(SRC, k))
        .find((k) => existsSync(k))
      if (kandidat) offen.push(kandidat)
    }
  }
  return gesehen
}

describe('Fixtures des Eltern-Berichts', () => {
  it('kein Modul lädt den Supabase-Client, auch nicht über Umwege (Vorschau ohne .env)', () => {
    const module = [...erreichbar(resolve(__dirname, 'index.ts'))].map((d) => d.slice(SRC.length + 1))
    expect(module).toContain('lib/report/familien.ts')
    expect(module.filter((m) => m.startsWith('lib/supabase/'))).toEqual([])
  })

  it('vieleRueckbezuege hat vier Rückbezüge, ilkay einen', () => {
    expect(FAELLE.vieleRueckbezuege.data.erzaehlung.rueckbezuege).toHaveLength(4)
    expect(FAELLE.ilkay.data.erzaehlung.rueckbezuege.map((r) => r.fall)).toEqual([
      'konzentration_nicht_messbar',
    ])
  })

  it('jeder Rückbezug hat einen abgenommenen Baustein', () => {
    for (const { data } of Object.values(FAELLE)) {
      const faelle = new Set(data.erzaehlung.bausteine.filter((b) => b.slot === 'rueckbezug').map((b) => b.fall))
      for (const r of data.erzaehlung.rueckbezuege) expect(faelle, r.fall).toContain(r.fall)
    }
  })

  it('Sitzungs-IDs sind Platzhalter und eindeutig', () => {
    const ids = Object.entries(FAELLE)
      .filter(([n]) => n !== 'ilkay')
      .map(([, f]) => f.data.sessionId)
    expect(new Set(ids).size).toBe(ids.length)
    for (const { data } of Object.values(FAELLE)) expect(data.sessionId).toMatch(/^00000000-0000-4000-8000-/)
  })

  it('testlauf nur im Fall testlauf, ohne Namen nur in ohneName, ohne Notizen nur in ohneNotizen', () => {
    for (const [name, f] of Object.entries(FAELLE)) {
      expect(f.data.testlauf, name).toBe(name === 'testlauf')
      expect(f.data.firstName === null, name).toBe(name === 'ohneName')
      expect(f.notes === null, name).toBe(name === 'ohneNotizen')
      expect(f.tiers.filter((t) => t.active)).toHaveLength(3)
    }
  })
})
