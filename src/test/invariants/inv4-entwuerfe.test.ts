// INV-4.6 / INV-4.7 — die Baustein-Entwürfe aus W5-d (Rückbezug, Ausgangspunkt,
// Fazit) gehorchen den Sprachregeln der Elternfläche. Ausgelagert aus
// inv4-eltern-sprache.test.ts, das sonst über die 400-Zeilen-Grenze (CLAUDE §4) wüchse.
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'

import deReport from '@/i18n/locales/de/report.json'

const SRC = resolve(__dirname, '../..')
const read = (rel: string): string => readFileSync(resolve(SRC, rel), 'utf8')

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

const reportStrings = flatten(deReport)

/**
 * INV-4.6 — die Rückbezug-Entwürfe (W5-d) sprechen die Sprache des Reports.
 *
 * Seit #189 sagt der Report „sicher / noch nicht sicher" und „Grundlagen, auf
 * denen das Thema aufbaut". Die Entwürfe ersetzen die Sätze, die noch von
 * „tragen", „Ebenen" und „unterhalb des aktuellen Themas" sprachen. Geprüft
 * wird die dritte Spalte jeder values-Zeile — die zweite ist der alte Wortlaut,
 * der nur als Schutzbedingung dasteht.
 */
describe('INV-4.6 — Rückbezug-Entwürfe ohne Trage- und Ebenensprache', () => {
  const roh = readFileSync(
    resolve(__dirname, '../../../supabase/migrations/20261004003310_rueckbezug_entwuerfe.sql'),
    'utf8',
  )
  const entwuerfe = [
    ...roh.matchAll(/\('(rueckbezug\.[a-z_]+\.(?:a|b))',\n\s*'(?:[^']|'')*',\n\s*'((?:[^']|'')*)'\)/g),
  ].map((m) => ({ key: m[1], text: m[2].replace(/''/g, "'") }))

  it('der Lesepfad liefert nie einen Entwurf aus', () => {
    // Die Abnahme-Schranke hängt daran, dass reportBausteine.ts die Spalten
    // einzeln nennt. Ein select('*') brächte entwurf auf die Elternfläche.
    const lesepfad = read('lib/supabase/reportBausteine.ts')
    expect(lesepfad).not.toMatch(/entwurf/)
    expect(lesepfad).not.toMatch(/select\(\s*'\*'/)
  })

  it('findet alle elf Entwürfe', () => {
    expect(entwuerfe).toHaveLength(11)
  })

  it('sagt nie „tragen", „Ebene" oder „Fundament"', () => {
    for (const { key, text } of entwuerfe) {
      expect(text, key).not.toMatch(/tr(ä|ae)gt|trug|getragen|tragen|Ebene|Fundament/i)
    }
  })

  it('nennt kein „aktuelles Thema" — grundlagen_offen gilt auch ohne Thema', () => {
    for (const { key, text } of entwuerfe) {
      expect(text, key).not.toMatch(/aktuellen Themas/)
    }
  })

  it('folgt den Regeln aus INV-4.5', () => {
    for (const { key, text } of entwuerfe) {
      expect(text, key).not.toMatch(/\b(du|dich|dir|dein\w*)\b/i)
      expect(text, key).not.toMatch(/\bNote\b|Zeugnis|gemeistert|wird .*(schaffen|k(ö|oe)nnen)/i)
      expect(text, key).not.toMatch(/Klasse\s*\d|\b[a-z]+_[a-z_]+\b/)
      for (const [, name] of text.matchAll(/\{(\w+)\}/g)) expect(name, key).toBe('belege')
    }
  })
})

/**
 * INV-4.7 — Ausgangspunkt statt Wahl (W5-d Teil 5).
 *
 * Für nachgetragene Themenräume darf kein Satz voraussetzen, dass das Thema im
 * Gespräch gewählt wurde. Geprüft: die neuen Bausteine (Slot 'ausgangspunkt'),
 * der Entwurf für fazit.keine.a und die i18n-Texte, die der Report bei
 * nachgetragenem Raum statt der „Wahl"-Texte zeigt.
 */
describe('INV-4.7 — Ausgangspunkt-Bausteine setzen keine Wahl voraus', () => {
  const roh = readFileSync(
    resolve(__dirname, '../../../supabase/migrations/20261004093449_report_ausgangspunkt_entwuerfe.sql'),
    'utf8',
  )
  const neu = [
    ...roh.matchAll(/\('([a-z_]+\.[a-z_]+\.(?:a|b))', '[a-z_]+', '[a-z_]+', '(?:a|b)',\n\s*'((?:[^']|'')*)'\)/g),
  ].map((m) => ({ key: m[1], text: m[2].replace(/''/g, "'") }))
  const entwurf = [
    ...roh.matchAll(/\('([a-z_]+\.[a-z_]+\.(?:a|b))',\n\s*'(?:[^']|'')*',\n\s*'((?:[^']|'')*)'\)/g),
  ].map((m) => ({ key: m[1], text: m[2].replace(/''/g, "'") }))
  const alle = [...neu, ...entwurf]

  it('findet vier Ausgangspunkt-Sätze und den Fazit-Entwurf', () => {
    expect(neu.map((x) => x.key).sort()).toEqual([
      'ausgangspunkt.thema.a',
      'ausgangspunkt.thema.b',
      'ausgangspunkt.ungeprueft.a',
      'ausgangspunkt.ungeprueft.b',
    ])
    expect(entwurf.map((x) => x.key)).toEqual(['fazit.keine.a'])
  })

  it('kein Satz setzt eine Wahl oder ein „aktuelles" Thema voraus', () => {
    const WAHL = /gew(ä|ae)hlt|ausgesucht|vereinbart|besprochen|gew(ü|ue)nscht|aktuell|angesetzt/i
    for (const { key, text } of alle) expect(text, key).not.toMatch(WAHL)
    expect(reportStrings['suche.block.ausgangspunkt']).not.toMatch(WAHL)
    expect(reportStrings['anlass.themaOhneAnsatz']).not.toMatch(WAHL)
  })

  it('folgt den übrigen Sprachregeln', () => {
    for (const { key, text } of alle) {
      expect(text, key).not.toMatch(/tr(ä|ae)gt|tragen|Ebene|Fundament|gemeistert/i)
      expect(text, key).not.toMatch(/\b(du|dich|dir|dein\w*)\b/i)
      for (const [, name] of text.matchAll(/\{(\w+)\}/g)) expect(['thema'], key).toContain(name)
    }
  })
})

/**
 * INV-4.8 — die übrigen Bausteine ohne „tragen" (W5-d, offener Punkt).
 *
 * befund_traegt, empfehlung.keine.b, fazit.mehrere.b und fazit.zwei.b sprachen
 * noch von „tragen". Die Entwürfe sagen „sicher" und behalten die Platzhalter,
 * die der Renderer für den Slot füllt.
 */
describe('INV-4.8 — Befund-, Fazit- und Empfehlungs-Entwürfe ohne „tragen"', () => {
  const roh = readFileSync(
    resolve(__dirname, '../../../supabase/migrations/20261004095314_bausteine_tragen_entwuerfe.sql'),
    'utf8',
  )
  const entwuerfe = [
    ...roh.matchAll(/\('([a-z_]+\.[a-z_]+\.(?:a|b))',\n\s*'((?:[^']|'')*)',\n\s*'((?:[^']|'')*)'\)/g),
  ].map((m) => ({ key: m[1], alt: m[2].replace(/''/g, "'"), text: m[3].replace(/''/g, "'") }))

  it('findet genau die fünf Sätze', () => {
    expect(entwuerfe.map((e) => e.key)).toEqual([
      'befund_traegt.standard.a',
      'befund_traegt.standard.b',
      'empfehlung.keine.b',
      'fazit.mehrere.b',
      'fazit.zwei.b',
    ])
  })

  it('sagt „sicher", nie „tragen"', () => {
    for (const { key, text } of entwuerfe) {
      // Platzhalter wie {traegt} sind interne Namen, kein sichtbarer Text.
      const sichtbar = text.replace(/\{\w+\}/g, '')
      expect(sichtbar, key).not.toMatch(/tr(ä|ae)gt|trug|getragen|\btragen|Ebene|Fundament/i)
      expect(sichtbar, key).toMatch(/sicher/)
    }
  })

  it('behält genau die Platzhalter des alten Satzes', () => {
    const namen = (s: string) => [...s.matchAll(/\{(\w+)\}/g)].map((m) => m[1]).sort()
    for (const { key, alt, text } of entwuerfe) expect(namen(text), key).toEqual(namen(alt))
  })

  it('folgt den übrigen Sprachregeln', () => {
    for (const { key, text } of entwuerfe) {
      expect(text, key).not.toMatch(/\b(du|dich|dir|dein\w*)\b/i)
      expect(text, key).not.toMatch(/\bNote\b|gemeistert|gew(ä|ae)hlt|aktuell/i)
    }
  })
})
