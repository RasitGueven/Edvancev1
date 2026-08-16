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
 *   3. KEIN ROHER SCHLÜSSEL — ein Fehlbild-Slug ('linearer_faktor') und ein
 *      Familienschlüssel ('einheiten_massstab') sind interne Bezeichner, keine
 *      Sätze für Eltern. Angezeigt wird nur ein abgenommener Text; fehlt er,
 *      entfällt der Befund still (AF5-Bündelung).
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
const REPORT_FEHLBILDER = 'components/edvance/report/ReportFehlbilder.tsx'
const FEHLBILD_GRUPPIERUNG = 'lib/reportFehlbilder.ts'
const SKILLBEFUNDE = 'components/edvance/report/ReportSkillbefunde.tsx'
const REPORT_TOPIC_BAR = 'components/edvance/report/ReportTopicBar.tsx'
const REPORT_SCHLUSS = 'components/edvance/report/ReportSchluss.tsx'
const PRINT_CSS = 'styles/print.css'

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

describe('INV-4.3 — Eltern sehen nie einen rohen Fehlbild-Schlüssel', () => {
  // Seit der Bündelung (AF5) rendert der Abschnitt Familien, nicht Slugs. Die
  // Invariante ist dieselbe geblieben, ihre Angriffsfläche ist gewachsen: es
  // gibt jetzt ZWEI interne Schlüssel (slug, familie) und einen Text, der nicht
  // für Eltern gedacht ist (den Coach-Klartext).

  it('ReportBody rendert den Fehlbild-Abschnitt nicht mehr selbst', () => {
    // Er delegiert. Zieht jemand die Liste zurück in den Body, greifen die
    // Proben unten nicht mehr — deshalb wird die Delegation selbst geprüft.
    const src = code(REPORT_BODY)
    expect(src).toContain('<ReportFehlbilder')
    expect(src).not.toMatch(/\bfb\./)
  })

  it('die Fehlbild-Komponente rendert weder Slug noch Familienschlüssel', () => {
    const src = code(REPORT_FEHLBILDER)
    // Der Familienschlüssel darf ausschliesslich als React-key dienen.
    expect([...src.matchAll(/familie\.familie/g)]).toHaveLength(1)
    expect(src).toContain('key={familie.familie}')
    // Der Slug taucht in der Elternsicht überhaupt nicht auf.
    expect(src).not.toMatch(/\.slug\b/)
  })

  it('die Fehlbild-Komponente rendert keinen Coach-Klartext', () => {
    // klartext ist ab AF4 der Coach-Satz. Er kommt über die Eltern-RPC gar
    // nicht mehr an; taucht der Bezeichner hier auf, hat ihn jemand zurückgeholt.
    expect(code(REPORT_FEHLBILDER)).not.toMatch(/klartext/i)
    expect(code(FEHLBILD_GRUPPIERUNG)).not.toMatch(/klartext/i)
  })

  it('ohne abgenommenen Elterntext entfällt der Befund, statt ersetzt zu werden', () => {
    // Kein Platzhalter: ein Ersatztext an dieser Stelle wäre genau die
    // Behauptung über das Denken eines Kindes, die die Abnahme verhindern soll.
    const src = code(FEHLBILD_GRUPPIERUNG)
    expect(src).toContain('if (!familie || !elterntext) continue')
    // Und die Komponente rendert nichts, wenn nichts übrig bleibt.
    expect(code(REPORT_FEHLBILDER)).toContain('return null')
  })

  it('der angezeigte Satz kommt wörtlich aus der Datenbank', () => {
    // Nicht aus i18n: der Elterntext ist Inhalt, keine Oberflächensprache
    // (CLAUDE §12). Gerendert wird das Feld, unverändert.
    expect(code(REPORT_FEHLBILDER)).toContain('{familie.elterntext}')
  })

  it('der Skill-Abschnitt rendert das Label, niemals den skill_key', () => {
    const src = code(SKILLBEFUNDE)
    // skillKey darf ausschliesslich als React-key dienen.
    expect([...src.matchAll(/skill\.skillKey/g)]).toHaveLength(1)
    expect(src).toContain('key={skill.skillKey}')
    expect(src).toContain('{skill.label}')
  })

  it('der Skill-Abschnitt entfaellt, statt Leere zu behaupten', () => {
    const src = code(SKILLBEFUNDE)
    expect(src).toContain('return null')
  })

  it('der Skill-Abschnitt zeigt keine Fundamenttiefe als Zahl', () => {
    // Eine Stufenzahl waere fuer Eltern bedeutungslos und laese sich wie eine Note.
    const src = code(SKILLBEFUNDE)
    expect(src).not.toMatch(/\{\s*skill\.fundamentTiefe\s*\}/)
  })

  it('der Skill-Abschnitt traegt seine Vorlaeufigkeit in der Sprache', () => {
    // Ein Befund aus zwei Aufgaben ist eine Beobachtung, kein Urteil.
    const text = [
      reportStrings['skillbefunde.title'],
      reportStrings['skillbefunde.description'],
    ].join(' ')
    expect(text).toMatch(/genauer an|nach|Momentaufnahme/)
    // Kein Defizit-Vokabular ueber das Kind.
    expect(text).not.toMatch(/L(ü|ue)cke|Schw(ä|ae)che|kann das nicht|Defizit/i)
  })

  it('kein Registry-Slug steht als Text in report.json', () => {
    // Slugs sind snake_case; in Elterntexten hat das nichts zu suchen.
    const treffer = Object.entries(reportStrings).filter(([, text]) =>
      /\b[a-z]+_[a-z_]+\b/.test(text),
    )
    expect(treffer).toEqual([])
  })
})

/**
 * INV-4.4 — der Eltern-Report sieht nicht aus wie ein Zeugnis (R3).
 *
 * Die Gestaltungsentscheidung von R3 ist eine inhaltliche: der Bereichsbalken
 * zeigt, WAS gelöst wurde, nicht WIE GUT. Sobald jemand daraus eine Quote, eine
 * Ampel oder einen Fortschrittsbalken macht, ist es eine Note — und der Report
 * behauptet etwas, das aus zwei Proben je Skill nicht folgt. Deshalb steht die
 * Grenze hier und nicht nur im Kommentar.
 */
describe('INV-4.4 — der Report zeigt Koennen, keine Note', () => {
  const REPORT_FLAECHEN = [
    REPORT_BODY,
    REPORT_TOPIC_BAR,
    REPORT_FEHLBILDER,
    SKILLBEFUNDE,
    REPORT_SCHLUSS,
  ]

  it('keine Quote und keine Prozentzahl als Aussage', () => {
    for (const datei of REPORT_FLAECHEN) {
      const src = code(datei)
      // Prozentrechnung im Renderpfad — der klassische Weg zur Note.
      expect(src, datei).not.toMatch(/\*\s*100\b/)
      expect(src, datei).not.toMatch(/toFixed/)
      // Ein Prozentzeichen im ausgegebenen Text.
      expect(src, datei).not.toMatch(/%\s*(<\/|\{|'|"|`)/)
    }
    const prozent = Object.entries(reportStrings).filter(([, text]) =>
      text.includes('%'),
    )
    expect(prozent).toEqual([])
  })

  it('keine Ampelfarben auf den Eltern-Flaechen', () => {
    // Der Report kennt drei Farben: Navy, Gold, Creme. Rot/Gelb/Gruen tragen
    // hier eine Wertung, die niemand belegt hat.
    for (const datei of REPORT_FLAECHEN) {
      const src = code(datei)
      expect(src, datei).not.toMatch(
        /--color-(error|success|warning|danger)|\b(bg|text|border)-(red|green|amber|yellow|emerald|rose)-/,
      )
    }
  })

  it('der Bereichsbalken ist eine Zaehlung, keine Skala', () => {
    const src = code(REPORT_TOPIC_BAR)
    // Kein gefuellter Balken: eine variable Breite ist immer ein Maximum,
    // auf das man zulaeuft — also eine Skala von schlecht nach gut.
    expect(src).not.toMatch(/width:/)
    // Gezaehlt wird gegen die gestellten Aufgaben, nicht gegen ein Soll.
    expect(src).toMatch(/evidence\.solved/)
  })

  it('der Schluss rendert nichts ohne Daten', () => {
    // Fazit und Empfehlung kommen aus abgenommenen Bausteinen. Solange die
    // fehlen, steht dort kein leerer Kasten und kein Platzhaltersatz.
    expect(code(REPORT_SCHLUSS)).toMatch(/return null/)
  })

  it('der aufklappbare Befund steht im Druck offen', () => {
    // Am Bildschirm zugeklappt, auf Papier vollstaendig: ein ausgedruckter
    // Report darf nicht weniger sagen als der gleiche Report am Bildschirm.
    expect(read(PRINT_CSS)).toMatch(
      /details:not\(\[open\]\)\s*>\s*\.report-details-body/,
    )
  })
})
