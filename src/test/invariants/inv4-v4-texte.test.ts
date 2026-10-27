// INV-4 für die Texte des Berichts v4 (Klassenarbeiten als roter Faden, Bauauftrag
// V4, Entscheidung 9 und V4-1): Abschnitt `v4` in elternbericht.json und
// praesentation.json. Eigene Datei, weil inv4-elternbericht.test.ts schon über
// 400 Zeilen hat (CLAUDE §4).
import { describe, expect, it } from 'vitest'

import deElternbericht from '@/i18n/locales/de/elternbericht.json'
import dePraesentation from '@/i18n/locales/de/praesentation.json'

function flatten(node: unknown, prefix = '', out: Record<string, string> = {}): Record<string, string> {
  if (typeof node === 'string') {
    out[prefix] = node
    return out
  }
  if (node && typeof node === 'object') {
    for (const [k, v] of Object.entries(node)) flatten(v, prefix ? `${prefix}.${k}` : k, out)
  }
  return out
}

/** Platzhalter und <b> sind kein Wortlaut. */
const sichtbar = (s: string): string => s.replace(/\{\{\s*\w+\s*\}\}/g, '').replace(/<\/?b>/g, '')

const NAMESPACES = {
  elternbericht: flatten((deElternbericht as { v4?: unknown }).v4, 'v4'),
  praesentation: flatten((dePraesentation as { v4?: unknown }).v4, 'v4'),
}

const VERBOTEN: [string, RegExp][] = [
  ['Klassenband', /Klassenband/i],
  ['wirkt auf', /wirkt auf/i],
  ['trägt', /tr(ä|ae)gt/i],
  ['gemeistert', /gemeistert/i],
  ['Prozent', /%|Prozent(?!rechnung)/],
  ['bis Klassenarbeit', /bis (zur |zu der |zu )?Klassenarbeit/i],
  ['Notenversprechen', /garanti|Note[n]?\s+(verbessert|verbessern|steigt|steigen|von \d)|(bessere|gute) Note/i],
  ['Zeugnisnote', /Zeugnisnote/i],
]

/** Nur diese Texte sprechen von Noten: die gemeldete Note und die Absage an Notenversprechen. */
const NOTE_ERLAUBT = [
  'v4.stand.note',
  'v4.s2.intro',
  'v4.s2.introThema',
  'v4.s5.keineNoten',
  'v4.s5.keineNotenOhneName',
  // LSA-L4 Teil D: die gemeldete Note und der Abgleich, sobald sie bekannt ist (keine erwartete Note).
  'v4.s3.ka.note',
  'v4.s3.ka.abgleich',
]

describe.each(Object.entries(NAMESPACES))('INV-4 · v4-Texte in %s', (_ns, texte) => {
  it('hat Texte', () => {
    expect(Object.keys(texte).length).toBeGreaterThan(10)
  })

  it.each(VERBOTEN)('kein „%s“', (_name, muster) => {
    for (const [key, s] of Object.entries(texte)) expect(sichtbar(s), key).not.toMatch(muster)
  })

  it('Noten nur dort, wo sie eine Tatsache melden oder kein Versprechen geben', () => {
    for (const [key, s] of Object.entries(texte)) {
      if (/\bNote[n]?\b/.test(sichtbar(s))) expect(NOTE_ERLAUBT, key).toContain(key)
    }
  })

  // LSA-L4 Teil D (Entscheidung 14): Die Sätze zum Stand der Klassenarbeit behaupten keine Ursache („dazu passt“,
  // nie „weil“), nennen keine erwartete Note und kein „trägt“.
  it('Sätze zum Stand der Klassenarbeit: keine Ursache, keine erwartete Note', () => {
    const ka = Object.entries(texte).filter(([key]) => key.startsWith('v4.s3.ka.'))
    expect(ka.length).toBeGreaterThanOrEqual(12)
    for (const [key, s] of ka) {
      expect(sichtbar(s), key).not.toMatch(/\b(weil|deshalb|wegen|daher|darum)\b/i)
      expect(sichtbar(s), key).not.toMatch(/erwart|voraussichtlich|prognos|wird (eine )?Note|Note wird/i)
      expect(sichtbar(s), key).not.toMatch(/tr(ä|ae)gt|tragen/i)
    }
    expect(texte['v4.s3.ka.dazu_one']).toMatch(/^Dazu passt/)
  })

  it('kein Duzen, keine Schlüssel-Reste im Text', () => {
    for (const [key, s] of Object.entries(texte)) {
      expect(sichtbar(s), key).not.toMatch(/\b(du|dich|dir|dein|deine|deiner|deinem|deinen|deines)\b/i)
      expect(sichtbar(s), key).not.toMatch(/\b[a-z]+_[a-z_]+\b/)
    }
  })
})
