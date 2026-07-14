// B01 — Die Gegenprobe zur Datenmigration, gegen die ECHTE Quelle.
//
// Die Migration (supabase/migrations/20260714140000_b01_beleg_und_rls.sql) loest den
// Quellenbeleg aus `task_solutions.solution` heraus, wo C08 ihn mangels eigenem Feld
// abgelegt hat. Sie darf dabei nicht raten. Diese Suite beweist, dass sie es nicht
// muss — ohne DB:
//
//   1. Sie erzeugt aus data/vera8_v2.json exakt den Text, den C08 geschrieben HAT
//      (der alte Generator, hier nachgebaut — er ist mit dem Commit a255bfd fixiert).
//   2. Sie laesst darauf die Parser-Logik der Migration laufen (gleicher Split,
//      gleiche String-Zerlegung — kein Regex mit Greedy-Ueberraschungen).
//   3. Sie prueft beides, was die Migration selbst prueft: den zeichengenauen
//      Roundtrip und die Trennschaerfe des Kriteriums.
//
// Waere auch nur ein Item nicht verlustfrei trennbar, bricht die Migration ab
// (RAISE, kein Commit). Dieser Test sagt vorher, ob das passieren wuerde.

import { readFileSync } from 'node:fs'
import { describe, expect, it } from 'vitest'
import { buildItem, type V2Item } from './vera8Draft'

const ITEMS = JSON.parse(readFileSync('data/vera8_v2.json', 'utf8')) as V2Item[]
const ERW = 'Erwartungshorizont (Freitext, nicht auto-korrigierbar):'
const trim = (s: unknown): string => (typeof s === 'string' ? s.trim() : '')

type Beleg = { feld: string; gate?: string; quelle?: string; zitat: string; hinweis?: string }
type Grounding = Record<string, { zitat?: string; quelle?: string; gate?: string }>

/** Der ALTE Generator (C08), woertlich — so steht der Beleg heute in der DB. */
function c08SolutionText(item: V2Item): string | null {
  const g = ((item as { _grounding?: Grounding })._grounding ?? {}) as Grounding
  const bloecke: string[] = []
  for (const [feld, beleg] of Object.entries(g)) {
    if (!/correct_answers/.test(feld)) continue
    const zitat = trim(beleg?.zitat)
    if (!zitat) continue
    const gate = trim(beleg?.gate)
    bloecke.push(`[${feld}${gate ? ` · ${gate}` : ''}] ${trim(beleg?.quelle) || 'Quelle unbekannt'}:\n${zitat}`)
  }
  const erw =
    item.input_type === 'FREE_TEXT' && item.parts?.[0]?.correct_answers?.length
      ? `${ERW}\n${item.parts[0].correct_answers!.join('\n')}`
      : null
  return [erw, bloecke.length ? bloecke.join('\n\n') : null].filter(Boolean).join('\n\n') || null
}

/** Die Migration, 1:1 nachgebaut: Split am Blockanfang, Kopfzeile per String-Ops. */
function migriere(txt: string): { belege: Beleg[]; rebuilt: string } {
  const belege: Beleg[] = []
  const rebuilt: string[] = []
  for (const block of txt.split(/\n\n(?=\[[^\]\n]*correct_answers)/)) {
    if (block.startsWith(`${ERW}\n`)) {
      const zitat = block.slice(ERW.length + 1)
      belege.push({ feld: 'erwartungshorizont', hinweis: 'Freitext, nicht auto-korrigierbar', zitat })
      rebuilt.push(`${ERW}\n${zitat}`)
      continue
    }
    const kopf = block.split('\n')[0]
    const zitat = block.slice(kopf.length + 1)
    const ende = kopf.indexOf('] ')
    if (ende < 0 || !kopf.endsWith(':')) throw new Error(`Kopfzeile nicht parsebar: ${kopf}`)
    const [feld, gate] = kopf.slice(1, ende).split(' · ')
    const quelle = kopf.slice(ende + 2, -1)
    belege.push({ feld, quelle, ...(gate ? { gate } : {}), zitat })
    rebuilt.push(`[${feld}${gate ? ` · ${gate}` : ''}] ${quelle}:\n${zitat}`)
  }
  return { belege, rebuilt: rebuilt.join('\n\n') }
}

const MIT_BELEG = ITEMS.map((i) => ({ item: i, txt: c08SolutionText(i) })).filter(
  (x): x is { item: V2Item; txt: string } => x.txt !== null,
)

describe('B01 — der Beleg laesst sich aus solution herausloesen, ohne zu raten', () => {
  it('findet ueberhaupt Belege im Bestand (Anti-Vakuum)', () => {
    expect(MIT_BELEG.length).toBeGreaterThan(200)
  })

  // DAS KRITERIUM. Der Blockanfang "[…correct_answers" ist nur dann trennscharf,
  // wenn er in keinem Zitat vorkommt — sonst wuerde die Migration mitten in einem
  // Zitat schneiden. 31 Zitate enthalten "[Anm.: …]"; keines enthaelt das Wort.
  it('kein Zitat enthaelt selbst die Zeichenfolge correct_answers', () => {
    const kollision = MIT_BELEG.filter(({ item }) =>
      Object.values(((item as { _grounding?: Grounding })._grounding ?? {}) as Grounding).some((b) =>
        /correct_answers/.test(trim(b?.zitat)),
      ),
    )
    expect(kollision).toEqual([])
  })

  it('trennt jeden Beleg zeichengenau — der Roundtrip haelt fuer JEDES Item', () => {
    const kaputt = MIT_BELEG.filter(({ txt }) => migriere(txt).rebuilt !== txt).map(({ item }) => item.id)
    expect(kaputt).toEqual([])
  })

  it('kommt zum selben Ergebnis wie der neue Generator — ein Beleg, zwei Wege', () => {
    const abweichend = MIT_BELEG.filter(
      ({ item, txt }) => JSON.stringify(migriere(txt).belege) !== JSON.stringify(buildItem(item).belege),
    ).map(({ item }) => item.id)
    expect(abweichend).toEqual([])
  })

  it('laesst einen von Hand geschriebenen Loesungsweg unangetastet', () => {
    // Was das Muster nicht trifft, ruehrt die Migration nicht an. Ein Loesungsweg
    // faengt nicht mit "[…correct_answers" an — auch keiner, der eckige Klammern
    // benutzt.
    const weg = 'Erst 80 m · 0,2 rechnen [siehe Skizze], dann die Einheit angleichen.'
    expect(/^\[[^\]\n]*correct_answers/.test(weg)).toBe(false)
    expect(weg.startsWith(`${ERW}\n`)).toBe(false)
  })
})
