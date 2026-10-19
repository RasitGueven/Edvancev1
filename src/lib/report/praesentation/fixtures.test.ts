import { existsSync, readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'

import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import { PRAESENTATION_FAELLE } from '@/lib/report/praesentation/fixtures'

const SRC = resolve(__dirname, '../../..')

/** Alle Module, die von `start` aus über '@/…'-Importe erreichbar sind (ohne Typ-Importe). */
function erreichbar(start: string): string[] {
  const gesehen = new Set<string>()
  const offen = [start]
  while (offen.length > 0) {
    const datei = offen.pop()!
    if (gesehen.has(datei)) continue
    gesehen.add(datei)
    for (const [, art, ziel] of readFileSync(datei, 'utf8').matchAll(/^(?:import|export)\s+(type\s+)?[^;]*?from '@\/([^']+)'/gm)) {
      if (art) continue
      const k = [`${ziel}.ts`, `${ziel}.tsx`, `${ziel}/index.ts`].map((x) => resolve(SRC, x)).find((x) => existsSync(x))
      if (k) offen.push(k)
    }
  }
  return [...gesehen].map((d) => d.slice(SRC.length + 1))
}

const NEU = ['uebersprungen', 'einSchwerpunkt', 'zweiSchwerpunkte', 'dreiSchwerpunkte', 'laeuftNoch']

describe('Fixtures der Präsentation', () => {
  it('weder Fixtures noch Rechnung laden den Supabase-Client (Vorschau ohne .env)', () => {
    for (const start of ['fixtures.ts', 'praesentation.ts', 'kurve.ts']) {
      const module = erreichbar(resolve(__dirname, start))
      expect(module, start).toContain(`lib/report/praesentation/${start}`)
      expect(module.filter((m) => m.startsWith('lib/supabase/')), start).toEqual([])
    }
  })

  it('enthalten alle Fälle des Druckbogens und die fünf neuen', () => {
    expect(Object.keys(PRAESENTATION_FAELLE)).toEqual([...Object.keys(FAELLE), ...NEU])
    for (const name of Object.keys(FAELLE)) expect(PRAESENTATION_FAELLE[name]).toBe(FAELLE[name])
  })

  it('Sitzungs-IDs sind Platzhalter und eindeutig', () => {
    const ids = Object.values(PRAESENTATION_FAELLE).map((f) => f.data.sessionId)
    expect(new Set(ids).size).toBe(ids.length)
    for (const id of ids) expect(id).toMatch(/^00000000-0000-4000-8000-[0-9a-f]{12}$/)
  })

  it('neue Fälle mit Notizen und drei aktiven Paketen wie FAELLE', () => {
    for (const name of NEU) {
      const f = PRAESENTATION_FAELLE[name]
      expect(f.notes, name).toBe(FAELLE.ilkay.notes)
      expect(f.tiers, name).toBe(FAELLE.ilkay.tiers)
    }
  })

  it('uebersprungen: genau drei Bereiche nicht_angesetzt, Probe 2, nicht offen', () => {
    const k = PRAESENTATION_FAELLE.uebersprungen.data.erzaehlung.kompetenzen
    expect(k.filter((s) => s.zustand === 'nicht_angesetzt').map((s) => [s.skillKey, s.proben, s.offen])).toEqual([
      ['geo_winkel_summe', 2, false],
      ['prozent_prozentsatz', 2, false],
      ['term_ausklammern', 2, false],
    ])
    expect(k).toHaveLength(FAELLE.ilkay.data.erzaehlung.kompetenzen.length)
  })

  it('laeuftNoch: Ilkays Urteile mit status in_progress, nur dort', () => {
    for (const [name, f] of Object.entries(PRAESENTATION_FAELLE)) {
      expect(f.data.status === 'in_progress', name).toBe(name === 'laeuftNoch')
    }
    expect(PRAESENTATION_FAELLE.laeuftNoch.data.erzaehlung.kompetenzen).toEqual(
      FAELLE.ilkay.data.erzaehlung.kompetenzen,
    )
  })
})
