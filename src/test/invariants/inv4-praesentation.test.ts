// INV-4 für die Tablet-Präsentation der LSA (T1–T4): die Texte im Namespace
// `praesentation` gehorchen den Sprachregeln der Elternfläche (R7
// Entscheidung 9). Aufbau wie inv4-elternbericht.test.ts.
// T2 erweitert diese Datei um die Prüfungen der Komponenten und Styles.
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'

import deElternbericht from '@/i18n/locales/de/elternbericht.json'
import dePraesentation from '@/i18n/locales/de/praesentation.json'

const ROOT = resolve(__dirname, '../../..')
const read = (rel: string): string => readFileSync(resolve(ROOT, rel), 'utf8')

function flatten(
  node: unknown,
  prefix = '',
  out: Record<string, string> = {},
): Record<string, string> {
  if (typeof node === 'string') {
    out[prefix] = node
    return out
  }
  if (node && typeof node === 'object') {
    for (const [k, v] of Object.entries(node)) {
      flatten(v, prefix ? `${prefix}.${k}` : k, out)
    }
  }
  return out
}

const texte = flatten(dePraesentation)
/** Der sichtbare Text: i18n-Platzhalter und <b> sind kein Wortlaut. */
const sichtbar = (s: string): string => s.replace(/\{\{\s*\w+\s*\}\}/g, '').replace(/<\/?b>/g, '')

const DUZEN = /\b(du|dich|dir|dein|deine|deiner|deinem|deinen|deines)\b/i
const TRAEGT = /tr(ä|ae)gt/i
const SNAKE = /\b[a-z]+_[a-z_]+\b/

const ANFORDERUNG = read('docs/report/praesentation/Anforderung.md')
const ANHANG_A = ANFORDERUNG.slice(ANFORDERUNG.indexOf('## Anhang A'), ANFORDERUNG.indexOf('## Anhang B'))

/**
 * INV-4.11 — der Namespace `praesentation` (Anhang A der Anforderung).
 */
describe('INV-4.11 — praesentation.json spricht Elternsprache', () => {
  it('ist nicht leer und wörtlich aus Anhang A übernommen', () => {
    // Spätere Pakete (T2–T4) dürfen Schlüssel ergänzen; die aus Anhang A bleiben wörtlich.
    const start = ANHANG_A.indexOf('```json')
    const ende = ANHANG_A.indexOf('```', start + 7)
    const anhang = flatten(JSON.parse(ANHANG_A.slice(start + 7, ende)))
    expect(Object.keys(anhang)).toHaveLength(84)
    for (const [key, text] of Object.entries(anhang)) expect(texte[key], key).toBe(text)
  })

  it('die aus elternbericht übernommenen Schlüssel gibt es dort', () => {
    const eb = flatten(deElternbericht)
    const zeile = ANHANG_A.split('\n').find((z) => z.startsWith('Aus `elternbericht`'))!
    const keys = [...zeile.matchAll(/`([a-zA-Z0-9.*]+)`/g)].map((m) => m[1]).filter((k) => k !== 'elternbericht')
    expect(keys.length).toBeGreaterThan(15)
    for (const k of keys) {
      const treffer = k.endsWith('.*')
        ? Object.keys(eb).some((e) => e.startsWith(k.slice(0, -1)))
        : k in eb
      expect(treffer, k).toBe(true)
    }
  })

  it('duzt nirgends', () => {
    for (const [key, s] of Object.entries(texte)) expect(sichtbar(s), key).not.toMatch(DUZEN)
  })

  it('nennt keinen Prozentwert (kein %)', () => {
    for (const [key, s] of Object.entries(texte)) expect(s, key).not.toMatch(/%/)
  })

  it('trägt keinen rohen Schlüssel im Text', () => {
    for (const [key, s] of Object.entries(texte)) expect(sichtbar(s), key).not.toMatch(SNAKE)
  })

  it('sagt nie „trägt" und nie „gemeistert"', () => {
    for (const [key, s] of Object.entries(texte)) {
      expect(s, key).not.toMatch(TRAEGT)
      expect(s, key).not.toMatch(/gemeistert/i)
    }
  })

  it('Schlüssel sind dot-notation ohne snake_case — außer den Plural-Endungen', () => {
    for (const key of Object.keys(texte)) {
      expect(key.replace(/_(one|other)$/, ''), key).not.toMatch(/_/)
    }
  })
})
