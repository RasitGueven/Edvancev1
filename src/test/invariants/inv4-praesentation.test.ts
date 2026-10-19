// INV-4 für die Tablet-Präsentation der LSA (T1–T4): die Texte im Namespace
// `praesentation` gehorchen den Sprachregeln der Elternfläche (R7
// Entscheidung 9). Aufbau wie inv4-elternbericht.test.ts.
// T2 hat die Prüfungen der Komponenten und Styles ergänzt (INV-4.12).
import { readFileSync, readdirSync } from 'node:fs'
import { join, resolve } from 'node:path'
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

/**
 * INV-4.12 — Komponenten und Styles der Präsentation (T2, Entscheidung 11).
 *
 * Alle Dateien unter src/components/edvance/praesentation/ und
 * src/styles/praesentation/, ohne Tests und ohne Kommentare. Gilt auch für die
 * Stationen aus T3 und T4 — die Regeln sind so gefasst, dass sie nichts daran
 * ändern müssen.
 */
describe('INV-4.12 — die Präsentation rendert keine Schlüssel, Quoten oder freien Farben', () => {
  const ORDNER = ['src/components/edvance/praesentation', 'src/styles/praesentation']
  const dateien = ORDNER.flatMap((ordner) =>
    (readdirSync(resolve(ROOT, ordner), { recursive: true }) as string[])
      .filter((f) => /\.(tsx?|css)$/.test(f) && !/\.test\.tsx?$/.test(f))
      .map((f) => join(ordner, f)),
  )
  const ohneKommentare = (text: string): string =>
    text.replace(/\/\*[\s\S]*?\*\//g, '').replace(/(^|[^:])\/\/.*$/gm, '$1')
  const quelle = dateien.map((pfad) => ({ pfad, text: ohneKommentare(read(pfad)) }))
  const code = quelle.filter((d) => /\.tsx?$/.test(d.pfad))
  const css = quelle.filter((d) => d.pfad.endsWith('.css'))

  it('findet die Dateien des Rahmens und die vier Stationen', () => {
    for (const teil of [
      'Praesentation.tsx',
      'Kopf.tsx',
      'Leiste.tsx',
      'Intro.tsx',
      'Station1.tsx',
      'Station4.tsx',
      'useStationen.ts',
      'rahmen.css',
      'intro.css',
      'station1.css',
      'station4.css',
    ]) {
      expect(dateien.some((d) => d.endsWith(teil)), teil).toBe(true)
    }
  })

  it('nutzt skillKey nur als React-key (INV-4.3)', () => {
    for (const { pfad, text } of code) {
      for (const zeile of text.split('\n')) {
        if (!/\bskillKey\b/.test(zeile)) continue
        expect(zeile.replace(/key=\{[^}]*\}/g, ''), pfad).not.toMatch(/\bskillKey\b/)
      }
    }
  })

  it('rendert Feld- und Ebenenschlüssel nie roh, nur über i18n (feld.*, s3.ebene.*) oder als key', () => {
    // Roh gerendert wäre: {x.feld} als Kind, oder ${x.feld} in einem Text, der kein i18n-Schlüssel ist.
    const KIND = /(^|[^=\w])\{\s*[\w.?]*\.(feld|ebene)\s*\}/
    const VORLAGE = /`[^`]*\$\{[^}]*\.(feld|ebene)\}[^`]*`/g
    for (const { pfad, text } of code) {
      expect(text, pfad).not.toMatch(KIND)
      for (const [vorlage] of text.matchAll(VORLAGE)) {
        expect(vorlage, pfad).toMatch(/^`(elternbericht:)?(feld|s3\.ebene)\.\$\{[^}]*\}`$/)
      }
    }
  })

  it('rechnet keine Prozente und gibt kein % aus (CSS ausgenommen)', () => {
    const STRING_MIT_PROZENT = /(['"`])(?:(?!\1)[^\\\n]|\\.)*%(?:(?!\1)[^\\\n]|\\.)*\1/
    const JSX_TEXT_MIT_PROZENT = />[^<>{}]*%[^<>{}]*</
    for (const { pfad, text } of code) {
      expect(text, pfad).not.toMatch(/\*\s*100\b/)
      expect(text, pfad).not.toMatch(/\btoFixed\b/)
      expect(text, pfad).not.toMatch(STRING_MIT_PROZENT)
      expect(text, pfad).not.toMatch(JSX_TEXT_MIT_PROZENT)
    }
  })

  it('setzt Inline-Styles nur für berechnete Werte, nie als festen Text', () => {
    for (const { pfad, text } of code) {
      expect(text, pfad).not.toMatch(/style=\{\{[^}]*:\s*['"][^'"]*['"]/)
    }
  })

  it('nimmt Farben nur aus --color-eb-* und --color-tp-* und schreibt keine Hex-Werte', () => {
    for (const { pfad, text } of quelle) {
      expect(text, pfad).not.toMatch(/#[0-9a-fA-F]{3,8}\b/)
      expect(text, pfad).not.toMatch(/var\(--color-(?!eb-|tp-)/)
      expect(text, pfad).not.toMatch(/\b(rgba?|hsla?|oklch|lab|lch)\(/)
      expect(text, pfad).not.toMatch(
        /(:|=|\s|["'])(white|black|red|green|blue|gray|grey|navy|gold|orange|yellow)\s*[;"'}]/,
      )
      expect(text, pfad).not.toMatch(
        /\b(text|bg|border|fill|stroke|ring|from|to)-(white|black|slate|gray|zinc|red|rose|green|emerald|blue|amber|yellow)(-\d+)?\b/,
      )
    }
  })

  it('mischt in color-mix nur eb-/tp-Tokens mit transparent (Lichtschein, Schatten)', () => {
    for (const { pfad, text } of css) {
      for (const [mix] of text.matchAll(/color-mix\(in srgb,[^;]*?\)\s*\d*%?\s*,\s*[^)]*\)/g)) {
        expect(mix, pfad).toMatch(/^color-mix\(in srgb, var\(--color-(eb|tp)-[a-z-]+\) \d+%, transparent\)$/)
      }
    }
  })
})
