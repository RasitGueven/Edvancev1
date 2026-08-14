import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'

import deParent from '@/i18n/locales/de/parent.json'
import deReport from '@/i18n/locales/de/report.json'

/**
 * INV-4 — Elternsprache.
 *
 * Drei Zusicherungen über alles, was Eltern zu sehen bekommen (Eltern-Dashboard
 * und LSA-Report). Sie sind Sprach- und Auslieferungsregeln, keine Rechenlogik —
 * deshalb prüft die Suite die i18n-Ressourcen und den Quelltext der beiden
 * Flächen direkt, statt React zu rendern. Ein Component-Test würde denselben
 * Satz über einen gemockten Supabase-/Router-/Auth-Kontext prüfen und dabei
 * genau das verdecken, worum es geht: dass die Strings überhaupt in der
 * i18n-Schicht liegen.
 *
 *   1. SIEZEN — die Fläche gehört den Eltern, nicht dem Kind.
 *   2. KEINE GAMIFICATION — XP, Level und Streaks bleiben im Schüler-Surface.
 *      Gegenüber Eltern werden sie zur Leistungskennzahl; ein gerissener Streak
 *      liest sich als Vorwurf, ein XP-Stand lädt zum Vergleich ein.
 *   3. KEIN ROHER SLUG — ein Fehlbild-Slug ist ein interner Schlüssel
 *      ('linearer_faktor'), kein Satz für Eltern. Ohne abgenommenen Klartext
 *      (fehlbild_labels.freigegeben_am) zeigt der Report seinen neutralen Text.
 */

const SRC = resolve(__dirname, '../..')
const read = (rel: string): string => readFileSync(resolve(SRC, rel), 'utf8')

/**
 * Quelltext OHNE Kommentare und ohne JSX-Kommentarblöcke.
 *
 * Die Invariante gilt für ausgelieferten Code, nicht für Prosa: die Datei
 * ERKLÄRT ja gerade, warum XP/Level/Streaks dort nichts zu suchen haben, und
 * dieser Satz darf den Test nicht rot machen.
 */
function code(rel: string): string {
  return read(rel)
    .replace(/\{\s*\/\*[\s\S]*?\*\/\s*\}/g, '') // {/* JSX-Kommentar */}
    .replace(/\/\*[\s\S]*?\*\//g, '') // /* Block */ und /** JSDoc */
    .replace(/^[ \t]*\/\/.*$/gm, '') // // ganze Zeile
    .replace(/([^:])\/\/.*$/gm, '$1') // // am Zeilenende (nicht in URLs)
}

const PARENT_DASHBOARD = 'pages/parent/ParentDashboard.tsx'
const REPORT_BODY = 'components/edvance/report/ReportBody.tsx'

// Alle Strings eines Übersetzungsbaums, Pfad → Text.
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

const parentStrings = flatten(deParent)
const reportStrings = flatten(deReport)

describe('INV-4.1 — Eltern werden gesiezt', () => {
  // Wortgrenzen, damit "durch", "Neudorf" oder "Dein" am Satzanfang sauber
  // getroffen bzw. nicht falsch getroffen werden.
  const DUZEN = /\b(du|dich|dir|dein|deine|deiner|deinem|deinen|deines)\b/i

  it('parent.json duzt nirgends', () => {
    const treffer = Object.entries(parentStrings).filter(([, text]) =>
      DUZEN.test(text),
    )
    expect(treffer).toEqual([])
  })

  it('report.json duzt nirgends', () => {
    const treffer = Object.entries(reportStrings).filter(([, text]) =>
      DUZEN.test(text),
    )
    expect(treffer).toEqual([])
  })

  it('der EmptyState des Eltern-Dashboards siezt', () => {
    expect(parentStrings['empty.description']).toContain('Ihr Kind')
    expect(parentStrings['empty.description']).not.toMatch(DUZEN)
  })
})

describe('INV-4.2 — keine Gamification auf Eltern-Flächen', () => {
  const GAMIFICATION = [
    'StreakPill',
    'XPBar',
    'xp_total',
    'presence_streak',
    'home_streak',
    'getStudentProgress',
    'StudentProgress',
  ]

  it('ParentDashboard importiert und rendert keine Gamification-Symbole', () => {
    const src = code(PARENT_DASHBOARD)
    for (const symbol of GAMIFICATION) {
      expect(src).not.toContain(symbol)
    }
  })

  it('ParentDashboard zeigt weder Level noch XP als Text', () => {
    const src = code(PARENT_DASHBOARD)
    expect(src).not.toMatch(/\bLevel\b/)
    expect(src).not.toMatch(/\bXP\b/)
  })

  it('parent.json kennt keine Gamification-Vokabel', () => {
    const alle = Object.values(parentStrings).join(' ')
    for (const wort of ['XP', 'Level', 'Streak', 'Abzeichen', 'Punkte']) {
      expect(alle).not.toContain(wort)
    }
  })
})

describe('INV-4.3 — Eltern sehen nie einen rohen Fehlbild-Slug', () => {
  it('ReportBody rendert klartext, niemals slug', () => {
    const src = code(REPORT_BODY)
    // Der Slug darf ausschliesslich als React-key dienen.
    const slugVerwendungen = [...src.matchAll(/fb\.slug/g)]
    expect(slugVerwendungen).toHaveLength(1)
    expect(src).toContain('key={fb.slug}')
  })

  it('für fehlenden Klartext existiert ein neutraler Fallback', () => {
    const src = code(REPORT_BODY)
    expect(src).toContain("fb.klartext ?? t('fehlbild.pending.title')")
    expect(reportStrings['fehlbild.pending.title']).toBeTruthy()
  })

  it('der neutrale Fallback behauptet nichts über den Denkschritt', () => {
    // Er darf sagen DASS ein Muster da ist, nicht WELCHES.
    const text = [
      reportStrings['fehlbild.pending.title'],
      reportStrings['fehlbild.pending.description_one'],
      reportStrings['fehlbild.pending.description_other'],
    ].join(' ')
    expect(text).toMatch(/Muster|Zwischenschritt/)
    expect(text).not.toMatch(/_/) // kein durchgerutschter Slug
  })

  it('kein Registry-Slug steht als Text in report.json', () => {
    // Slugs sind snake_case; in Elterntexten hat das nichts zu suchen.
    const treffer = Object.entries(reportStrings).filter(([, text]) =>
      /\b[a-z]+_[a-z_]+\b/.test(text),
    )
    expect(treffer).toEqual([])
  })
})
