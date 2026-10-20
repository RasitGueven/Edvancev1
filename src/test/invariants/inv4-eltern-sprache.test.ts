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
const FEHLBILD_GRUPPIERUNG = 'lib/reportFehlbilder.ts'

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

  // R7-7: Die Komponenten der Fassung R6 (ReportBody, ReportFehlbilder,
  // ReportSkillbefunde …) sind gelöscht, mit ihnen die Prüfungen ihres
  // Quelltexts. Was in src/lib und report.json bleibt, wird weiter geprüft.

  it('die Fehlbild-Gruppierung kennt keinen Coach-Klartext', () => {
    // klartext ist ab AF4 der Coach-Satz. Er kommt über die Eltern-RPC gar
    // nicht mehr an; taucht der Bezeichner hier auf, hat ihn jemand zurückgeholt.
    expect(code(FEHLBILD_GRUPPIERUNG)).not.toMatch(/klartext/i)
  })

  it('ohne abgenommenen Elterntext entfällt der Befund, statt ersetzt zu werden', () => {
    // Kein Platzhalter: ein Ersatztext an dieser Stelle wäre genau die
    // Behauptung über das Denken eines Kindes, die die Abnahme verhindern soll.
    const src = code(FEHLBILD_GRUPPIERUNG)
    expect(src).toContain('if (!familie || !elterntext) continue')
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
  // R7-7: Die Quelltext-Prüfungen der R6-Flächen (Quote, Ampelfarben, Profil,
  // Schluss, Befund im Druck) sind mit den Komponenten entfallen; der Bogen R7
  // hat seine eigenen in inv4-elternbericht.test.ts.

  it('keine Prozentzahl in report.json', () => {
    const prozent = Object.entries(reportStrings).filter(([, text]) =>
      text.includes('%'),
    )
    expect(prozent).toEqual([])
  })

  it('die Suche nennt beide Summanden im Klartext', () => {
    expect(reportStrings['suche.zaehlung']).toBe('{{sicher}} von {{geprueft}} sicher')
  })

  it('der Suchabschnitt sagt „sicher", nie „trägt" oder „gemeistert"', () => {
    const suche = Object.entries(reportStrings).filter(([k]) => k.startsWith('suche.'))
    expect(suche.length).toBeGreaterThan(0)
    for (const [k, text] of suche) {
      expect(text, k).not.toMatch(/trägt|trug|gemeistert|Ebene/i)
    }
  })

})

/**
 * INV-4.5 — die Erzählbausteine gehorchen denselben Sprachregeln (R4).
 *
 * Mit R4 sind die Sätze des Reports aus dem Renderer in die Datenbank gewandert
 * (report_bausteine, Abnahme-Schranke wie fehlbild_familien). Damit fielen sie
 * aus dem Blick dieser Suite: INV-4.1 prüft die i18n-Ressourcen, und in denen
 * stehen sie nicht mehr.
 *
 * Geprüft wird deshalb die MIGRATIONSDATEI — dort steht der Wortlaut, dort geht
 * er durch das Review, und dort ist er statisch lesbar. Ein Satz, der später in
 * der Datenbank geändert wird, ist damit nicht abgedeckt; genau dafür gibt es
 * die Abnahme-Schranke, die eine Änderung ohne erneute Freigabe unwirksam macht.
 */
describe('INV-4.5 — die Erzaehlbausteine sprechen Elternsprache', () => {
  const MIGRATIONEN = [
    '20260818120000_r4_report_bausteine.sql',
    '20260818160000_r5_bausteine_verteilung.sql',
  ].map((f) => resolve(__dirname, '../../../supabase/migrations/', f))

  /**
   * Die Satz-Literale der insert-Zeilen, ohne SQL-Kommentare.
   *
   * Die Datei ERKLÄRT in ihren Kommentaren, warum bestimmte Formulierungen
   * verboten sind — diese Erklärungen dürfen den Test nicht rot machen.
   */
  const saetze: string[] = MIGRATIONEN.flatMap((datei) => {
    const roh = readFileSync(datei, 'utf8')
      .split('\n')
      .filter((z) => !z.trimStart().startsWith('--'))
      .join('\n')
    // Nur der Textblock der Bausteine: die Zeilen zwischen Variante und now().
    return [...roh.matchAll(/'(a|b)',\n\s*'((?:[^']|'')*)',\n\s*now\(\)/g)].map((m) =>
      m[2].replace(/''/g, "'"),
    )
  })

  it('findet ueberhaupt Bausteine (sonst prueft der Rest nichts)', () => {
    expect(saetze.length).toBeGreaterThanOrEqual(50)
  })

  it('nennt keine Terminzahl — die steht in der freq-Zeile aus tiers', () => {
    // R5: Die Empfehlungstexte nannten die Frequenz ein zweites Mal („Drei
    // Termine geben dafuer genug Raum"). Als die Tarife korrigiert wurden,
    // widersprach das Dokument sich selbst. Eine Zahl an zwei Orten driftet.
    for (const satz of saetze) {
      expect(satz, satz).not.toMatch(/pro Woche|\/Woche|w(ö|oe)chentlich/i)
      expect(satz, satz).not.toMatch(
        /\b(ein|eine|einen|zwei|drei|vier|f(ü|ue)nf)\s+(Termin|Termine|Sitzung|Sitzungen|Session|Sessions)\b/i,
      )
    }
  })

  it('duzt nirgends', () => {
    const DUZEN = /\b(du|dich|dir|dein|deine|deiner|deinem|deinen|deines)\b/i
    expect(saetze.filter((s) => DUZEN.test(s))).toEqual([])
  })

  it('nennt keine Note und keinen Vergleich mit anderen Kindern', () => {
    for (const s of saetze) {
      expect(s, s).not.toMatch(/\bNote\b|Zeugnis|Durchschnitt|Klassenschnitt/i)
      expect(s, s).not.toMatch(/andere Kinder|Mitsch(ü|ue)ler|im Vergleich zu/i)
    }
  })

  it('verspricht nichts — Handlungsrichtung ja, Erfolgszusage nein', () => {
    for (const s of saetze) {
      expect(s, s).not.toMatch(/wird .*(schaffen|k(ö|oe)nnen|beherrschen)/i)
      expect(s, s).not.toMatch(/garantier|sicher erreichen|in \w+ Wochen/i)
      // „gemeistert" behauptet einen Abschluss, den nur der Coach-Gate setzt.
      expect(s, s).not.toMatch(/gemeistert|Meilenstein erreicht/i)
    }
  })

  it('bringt keine Gamification auf die Elternflaeche', () => {
    for (const s of saetze) {
      expect(s, s).not.toMatch(/\bXP\b|Badge|Streak|Level\b|Punkte gesammelt/i)
    }
  })

  it('nennt keine Klassenstufe an einer Fundamentebene', () => {
    // fundament_tiefe ist die Position im Voraussetzungsgraphen, nicht der
    // Lehrplan — „Stoff aus Klasse 6" an einer Ebene waere schlicht falsch.
    for (const s of saetze) {
      expect(s, s).not.toMatch(/Klasse\s*\d/i)
    }
  })

  it('traegt keinen rohen Registry-Schluessel im Satz', () => {
    for (const s of saetze) {
      expect(s, s).not.toMatch(/\b[a-z]+_[a-z_]+\b/)
    }
  })

  it('nutzt nur Platzhalter, die der Renderer auch fuellt', () => {
    // Ein unbekannter Platzhalter bliebe im Dokument stehen (bewusst sichtbar,
    // siehe setzePlatzhalter) — hier faellt er schon im Test auf.
    const ERLAUBT = new Set(['traegt', 'geprueft', 'ebene', 'ebenen', 'belege'])
    for (const s of saetze) {
      for (const [, name] of s.matchAll(/\{(\w+)\}/g)) {
        expect(ERLAUBT.has(name), `${name} in: ${s}`).toBe(true)
      }
    }
  })
})
