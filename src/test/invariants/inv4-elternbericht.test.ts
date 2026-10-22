// INV-4 für den Eltern-Bericht R7 (Druckbogen nach Muster E7): die Texte im
// Namespace `elternbericht` und die Kopfsätze aus der R7-Migration gehorchen
// den Sprachregeln der Elternfläche. Eigene Datei, weil
// inv4-eltern-sprache.test.ts schon über 400 Zeilen hat (CLAUDE §4).
// Seit R7-2 dazu die Komponenten und Styles des Bogens (INV-4.11), per Glob —
// neue Seitendateien aus R7-3/R7-4 werden ohne Änderung hier mitgeprüft.
import { readdirSync, readFileSync } from 'node:fs'
import { join, resolve } from 'node:path'
import { describe, expect, it } from 'vitest'

import deElternbericht from '@/i18n/locales/de/elternbericht.json'

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

const texte = flatten(deElternbericht)
/** Der sichtbare Text: i18n-Platzhalter sind interne Namen, kein Wortlaut. */
const sichtbar = (s: string): string => s.replace(/\{\{\s*\w+\s*\}\}/g, '')

const DUZEN = /\b(du|dich|dir|dein|deine|deiner|deinem|deinen|deines)\b/i
const TRAEGT = /tr(ä|ae)gt/i
const SNAKE = /\b[a-z]+_[a-z_]+\b/

/** Anhang-A-Schlüssel, die R7-6 neu fasst (docs/report/r7/Bauauftrag-R7-6.md). */
const R7_6_GEAENDERT: Record<string, string> = {
  's1.blick.zeile': '{{untersucht}} Bereiche geprüft  ·  {{sicher}} sicher  ·  {{uebung}} Übungsbedarf',
  's1.geprueft.text':
    'Ausgehend vom Thema {{thema}} hat das System je nach Antwort die nächste Aufgabe gewählt. So wurden {{untersucht}} Bereiche gezielt geprüft.',
  's2.intro': 'Geprüft: {{untersucht}} Bereiche. Davon {{sicher}} sicher, {{uebung}} mit Übungsbedarf.',
  's2.profil.aria': '{{feld}}: {{untersucht}} geprüft, davon {{sicher}} sicher und {{uebung}} mit Übungsbedarf.',
  's2.fussnote':
    'Jedes Segment steht für einen geprüften Bereich. Das ist keine Note und kein Prozentwert. Ein Bereich gilt als sicher, wenn die geprüften Aufgaben dazu gelangen; die Bewertungsregel ist noch nicht abschließend festgelegt. Über Bereiche, die nicht geprüft wurden, sagt dieser Bericht nichts.',
}

/**
 * Anhang-A-Schlüssel, die R7-8 neu fasst (docs/report/r7/Bauauftrag-R7-8.md,
 * Entscheidung 3). `s2.fussnote` hatte schon R7-6 geändert; dort wird jetzt
 * der R7-8-Wortlaut erwartet.
 */
const R7_8_GEAENDERT: Record<string, string> = {
  's2.profil.hinweis': 'Jedes Kästchen steht für einen Bereich',
  's2.fussnote':
    'Jedes Kästchen steht für einen geprüften Bereich. Das ist keine Note und kein Prozentwert. Ein Bereich gilt als sicher, wenn die geprüften Aufgaben dazu gelangen; die Bewertungsregel ist noch nicht abschließend festgelegt. Über Bereiche, die nicht geprüft wurden, sagt dieser Bericht nichts.',
}

/** Anhang-A-Schlüssel, die R7-9 neu fasst (docs/report/r7/Bauauftrag-R7-9.md, Entscheidung 12). */
const R7_9_GEAENDERT: Record<string, string> = {
  's3.kicker': '{{wessen}} Lernweg',
}

/**
 * Anhang-A-Schlüssel, die R7-11 neu fasst (docs/report/r7/Bauauftrag-R7-11.md):
 * `s1.anliegen.thema` ist jetzt die Frage nach dem Thema der LSA (Entscheidung
 * 12; der alte Satz steht als `s1.anliegen.naechstesThema`), `s2.fussnote`
 * verliert den Halbsatz zur Bewertungsregel (Entscheidung 15).
 */
const R7_11_GEAENDERT: Record<string, string> = {
  's1.anliegen.thema': 'Sie sind wegen {{thema}} zu uns gekommen.',
  's2.fussnote':
    'Jedes Kästchen steht für einen geprüften Bereich. Das ist keine Note und kein Prozentwert. Ein Bereich gilt als sicher, wenn die geprüften Aufgaben dazu gelangen. Über Bereiche, die nicht geprüft wurden, sagt dieser Bericht nichts.',
}

/**
 * INV-4.13 (R7-11, Entscheidung 14): Seite 1 und Station 01 sagen nicht, was die
 * Analyse nicht sagen kann oder erst später klärt. Mindestens diese Wörter.
 */
const GRENZSATZ =
  /sagt nichts|sagt eine Analyse|sagt diese Analyse|erst nach|können wir noch nicht|nach mehreren Sitzungen|nichts beitragen|nicht abschließend/i

/**
 * Ausnahme von INV-4.13: der Methodenhinweis im Kasten „So haben wir geprüft“
 * (R7-6). Er beschreibt die Methode, nicht eine Grenze zu einem Anliegen.
 */
const GRENZSATZ_AUSNAHMEN = [
  's1.geprueft.hinweis',
  's1.geprueft.hinweisThema',
  's1.thema.offen_one',
  's1.thema.offen_other',
]

/** Anhang-A-Schlüssel, die R7-6 streicht. */
const R7_6_ENTFALLEN = [
  's1.geprueft.hinweis_one',
  's1.geprueft.hinweis_other',
  's2.introOffen_one',
  's2.introOffen_other',
  's2.zahl.offen',
  's2.profil.untersucht',
  's2.profil.legende.offen',
]

/**
 * INV-4.9 — der Namespace `elternbericht` (Anhang A des Bauauftrags R7).
 */
describe('INV-4.9 — elternbericht.json spricht Elternsprache', () => {
  it('ist nicht leer und wörtlich aus Anhang A übernommen', () => {
    // Spätere Pakete dürfen Schlüssel ergänzen; die aus Anhang A bleiben wörtlich.
    const bauauftrag = read('docs/report/r7/Bauauftrag-R7.md')
    const start = bauauftrag.indexOf('```json', bauauftrag.indexOf('## Anhang A'))
    const ende = bauauftrag.indexOf('```', start + 7)
    const anhang = flatten(JSON.parse(bauauftrag.slice(start + 7, ende)))
    expect(Object.keys(anhang)).toHaveLength(148)
    for (const [key, text] of Object.entries(anhang)) {
      if (
        key in R7_6_GEAENDERT ||
        key in R7_8_GEAENDERT ||
        key in R7_9_GEAENDERT ||
        key in R7_11_GEAENDERT ||
        R7_6_ENTFALLEN.includes(key)
      )
        continue
      expect(texte[key], key).toBe(text)
    }
  })

  it('R7-6: die ersetzten Schlüssel aus Anhang A wörtlich neu, die entfallenen fehlen', () => {
    // Bauauftrag R7-6, Entscheidungen 2 und 3: kein Katalog-Nenner, kein
    // „nicht untersucht“. Jeder Schlüssel steht hier einzeln, damit keiner still
    // aus der Prüfung fällt.
    const bauauftrag = read('docs/report/r7/Bauauftrag-R7.md')
    const start = bauauftrag.indexOf('```json', bauauftrag.indexOf('## Anhang A'))
    const anhang = flatten(JSON.parse(bauauftrag.slice(start + 7, bauauftrag.indexOf('```', start + 7))))
    for (const [key, text] of Object.entries(R7_6_GEAENDERT)) {
      expect(anhang[key], key).toBeDefined()
      expect(texte[key], key).toBe(R7_11_GEAENDERT[key] ?? R7_8_GEAENDERT[key] ?? text)
    }
    for (const key of R7_6_ENTFALLEN) {
      expect(anhang[key], key).toBeDefined()
      expect(texte[key], key).toBeUndefined()
    }
    // Nach Anhang A ergänzt (R7-3), mit R7-6 ebenfalls gestrichen.
    expect(texte['s2.profil.ariaKeiner']).toBeUndefined()
  })

  it('R7-9: die neu gefassten Schlüssel aus Anhang A wörtlich', () => {
    const bauauftrag = read('docs/report/r7/Bauauftrag-R7.md')
    const start = bauauftrag.indexOf('```json', bauauftrag.indexOf('## Anhang A'))
    const anhang = flatten(JSON.parse(bauauftrag.slice(start + 7, bauauftrag.indexOf('```', start + 7))))
    for (const [key, text] of Object.entries(R7_9_GEAENDERT)) {
      expect(anhang[key], key).toBeDefined()
      expect(texte[key], key).toBe(text)
    }
  })

  it('R7-8: die neu gefassten Schlüssel aus Anhang A wörtlich', () => {
    const bauauftrag = read('docs/report/r7/Bauauftrag-R7.md')
    const start = bauauftrag.indexOf('```json', bauauftrag.indexOf('## Anhang A'))
    const anhang = flatten(JSON.parse(bauauftrag.slice(start + 7, bauauftrag.indexOf('```', start + 7))))
    for (const [key, text] of Object.entries(R7_8_GEAENDERT)) {
      expect(anhang[key], key).toBeDefined()
      expect(texte[key], key).toBe(R7_11_GEAENDERT[key] ?? text)
    }
  })

  it('R7-11: die neu gefassten Schlüssel aus Anhang A wörtlich, der alte Thema-Satz unter neuem Schlüssel', () => {
    const bauauftrag = read('docs/report/r7/Bauauftrag-R7.md')
    const start = bauauftrag.indexOf('```json', bauauftrag.indexOf('## Anhang A'))
    const anhang = flatten(JSON.parse(bauauftrag.slice(start + 7, bauauftrag.indexOf('```', start + 7))))
    for (const [key, text] of Object.entries(R7_11_GEAENDERT)) {
      expect(anhang[key], key).toBeDefined()
      expect(texte[key], key).toBe(text)
    }
    expect(texte['s1.anliegen.naechstesThema']).toBe(anhang['s1.anliegen.thema'])
  })

  it('INV-4.13: kein Text auf Seite 1 sagt, was die Analyse nicht sagen kann (außer dem Methodenhinweis)', () => {
    const seite1 = Object.entries(texte).filter(([key]) => key.startsWith('s1.'))
    expect(seite1.length).toBeGreaterThan(40)
    for (const [key, s] of seite1) {
      if (GRENZSATZ_AUSNAHMEN.includes(key)) continue
      expect(s, key).not.toMatch(GRENZSATZ)
    }
    // Die Ausnahmen gibt es wirklich, keine steht still für einen entfallenen Schlüssel.
    for (const key of GRENZSATZ_AUSNAHMEN) expect(texte[key], key).toBeDefined()
    // Und auf Seite 2 entfällt der Halbsatz zur Bewertungsregel (Entscheidung 15).
    expect(texte['s2.fussnote']).not.toMatch(/Bewertungsregel/)
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
 * INV-4.10 — die Kopfsätze (Slot 'kopf', Anhang B) nach den Regeln aus INV-4.5.
 *
 * Geprüft wird die Migrationsdatei, ohne SQL-Kommentare: dort steht der
 * Wortlaut, dort geht er durch das Review.
 */
describe('INV-4.10 — Kopfsätze des Eltern-Berichts sprechen Elternsprache', () => {
  const roh = read('supabase/migrations/20261019080220_r7_kopf_entwuerfe.sql')
    .split('\n')
    .filter((z) => !z.trimStart().startsWith('--'))
    .join('\n')
  const saetze = [
    ...roh.matchAll(/\('(kopf\.[a-z]+\.(?:a|b))', 'kopf', '([a-z]+)', '(?:a|b)',\n\s*'((?:[^']|'')*)'\)/g),
  ].map((m) => ({ key: m[1], fall: m[2], text: m[3].replace(/''/g, "'") }))

  it('findet alle sechs Sätze, je Fall zwei', () => {
    expect(saetze.map((s) => s.key)).toEqual([
      'kopf.gemischt.a',
      'kopf.gemischt.b',
      'kopf.sicher.a',
      'kopf.sicher.b',
      'kopf.uebung.a',
      'kopf.uebung.b',
    ])
    for (const { key, fall } of saetze) expect(key.split('.')[1], key).toBe(fall)
  })

  it('legt nur Entwürfe an: keine Freigabe, nichts überschrieben', () => {
    expect(roh).not.toMatch(/freigegeben_am\s*=|now\(\)/)
    expect(roh).toMatch(/on conflict \(schluessel\) do nothing/)
    expect(roh).not.toMatch(/\b(create|alter|drop)\b/i)
  })

  it('folgt den Regeln aus INV-4.5', () => {
    for (const { key, text } of saetze) {
      expect(text, key).not.toMatch(/pro Woche|\/Woche|w(ö|oe)chentlich/i)
      expect(text, key).not.toMatch(DUZEN)
      expect(text, key).not.toMatch(/\bNote\b|Zeugnis|Durchschnitt|Klassenschnitt/i)
      expect(text, key).not.toMatch(/andere Kinder|Mitsch(ü|ue)ler|im Vergleich zu/i)
      expect(text, key).not.toMatch(/wird .*(schaffen|k(ö|oe)nnen|beherrschen)/i)
      expect(text, key).not.toMatch(/garantier|sicher erreichen|in \w+ Wochen/i)
      expect(text, key).not.toMatch(/gemeistert|Meilenstein erreicht/i)
      expect(text, key).not.toMatch(/\bXP\b|Badge|Streak|Level\b|Punkte gesammelt/i)
      expect(text, key).not.toMatch(/Klasse\s*\d/i)
      expect(text, key).not.toMatch(SNAKE)
    }
  })

  it('sagt nie „tragen", nennt keinen Prozentwert und kein Pronomen für das Kind', () => {
    for (const { key, text } of saetze) {
      expect(text, key).not.toMatch(/tr(ä|ae)gt|trug|getragen|\btragen|Ebene|Fundament/i)
      expect(text, key).not.toMatch(/%|Prozent/)
      expect(text, key).not.toMatch(/\b(er|sie|es|ihm|ihn|sein|seine|ihre)\b/)
    }
  })

  it('nutzt nur den Platzhalter {name}, und zwar genau einmal', () => {
    for (const { key, text } of saetze) {
      const namen = [...text.matchAll(/\{(\w+)\}/g)].map((m) => m[1])
      expect(namen, key).toEqual(['name'])
    }
  })
})

/**
 * INV-4.11 — Komponenten und Styles des Druckbogens (Bauauftrag R7, Entscheidung 10).
 *
 * Alle Dateien unter src/components/edvance/elternbericht/ und
 * src/styles/elternbericht/, ohne Tests (die erzeugen keinen Bogen) und ohne
 * Kommentare (dort darf ein Schlüssel oder ein Farbwert erklärt werden).
 */
describe('INV-4.11 — der Druckbogen rendert keine Schlüssel, Quoten oder freien Farben', () => {
  const ORDNER = ['src/components/edvance/elternbericht', 'src/styles/elternbericht']
  const dateien = ORDNER.flatMap((ordner) =>
    (readdirSync(resolve(ROOT, ordner), { recursive: true }) as string[])
      .filter((f) => /\.(tsx?|css)$/.test(f) && !/\.test\.tsx?$/.test(f))
      .map((f) => join(ordner, f)),
  )
  const ohneKommentare = (text: string): string =>
    text.replace(/\/\*[\s\S]*?\*\//g, '').replace(/(^|[^:])\/\/.*$/gm, '$1')
  const quelle = dateien.map((pfad) => ({ pfad, text: ohneKommentare(read(pfad)) }))
  const code = quelle.filter((d) => /\.tsx?$/.test(d.pfad))

  it('findet die Dateien des Bogens, auch die Seiten-Hüllen', () => {
    for (const teil of ['Bogen.tsx', 'Seite.tsx', 'Seite1.tsx', 'Seite5.tsx', 'rahmen.css', 'seite5.css']) {
      expect(dateien.some((d) => d.endsWith(teil)), teil).toBe(true)
    }
  })

  it('nutzt skillKey, Familien- und Fehlbild-Schlüssel nur als React-key (INV-4.3)', () => {
    for (const { pfad, text } of code) {
      for (const zeile of text.split('\n')) {
        if (!/\bskillKey\b|\.familie\b|\.slug\b/.test(zeile)) continue
        expect(zeile, pfad).toMatch(/key=\{[^}]*(\bskillKey\b|\.familie\b|\.slug\b)[^}]*\}/)
        expect(zeile.replace(/key=\{[^}]*\}/g, ''), pfad).not.toMatch(/\bskillKey\b|\.familie\b|\.slug\b/)
      }
    }
  })

  it('setzt keine statischen Inline-Styles', () => {
    for (const { pfad, text } of code) expect(text, pfad).not.toMatch(/style=\{\{/)
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

  it('nimmt Farben nur aus --color-eb-* und schreibt keine Hex-Werte', () => {
    for (const { pfad, text } of quelle) {
      expect(text, pfad).not.toMatch(/#[0-9a-fA-F]{3,8}\b/)
      expect(text, pfad).not.toMatch(/var\(--color-(?!eb-)/)
      expect(text, pfad).not.toMatch(/\b(rgba?|hsla?|oklch|lab|lch|color-mix)\(/)
      expect(text, pfad).not.toMatch(
        /(:|=|\s|["'])(white|black|red|green|blue|gray|grey|navy|gold|orange|yellow)\s*[;"'}]/,
      )
      expect(text, pfad).not.toMatch(
        /\b(text|bg|border|fill|stroke|ring|from|to)-(white|black|slate|gray|zinc|red|rose|green|emerald|blue|amber|yellow)(-\d+)?\b/,
      )
    }
  })
})
