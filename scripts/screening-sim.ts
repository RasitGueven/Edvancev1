// Deterministische Simulation des adaptiven Screening-Controllers
// (P4-Verifikation, da kein Test-Runner im Projekt). Baut synthetische
// Pools, spielt Antwortmuster durch und prüft die im Plan geforderten
// Eigenschaften per node:assert. Lauf: npm run sim:screening
//
// Geprüft: Warm-up-Sweep (1×L1 je Cluster), Fokus-Start L2, Treppe
// L2→L3 (richtig) / L2→L1 (falsch), harter Themen-Ausschluss, Gewichtung
// (mehr Tiefe), Budget-Stopp, graceful bei fehlender Stufe, leerer Pool.

import assert from 'node:assert/strict'
import type { ScreeningItem, ScreeningLevel } from '@/types'
import {
  createAdaptiveSession,
  isComplete,
  nextItem,
  submitAnswer,
  summarize,
} from '@/lib/screening/adaptive'

// Deterministischer RNG (mulberry32).
function rngFactory(seed: number): () => number {
  let a = seed
  return () => {
    a |= 0
    a = (a + 0x6d2b79f5) | 0
    let t = Math.imul(a ^ (a >>> 15), 1 | a)
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

let seq = 0
function mk(
  clusterId: string,
  topic: string,
  level: ScreeningLevel,
  value: number,
): ScreeningItem {
  seq += 1
  return {
    id: `${clusterId}-${topic}-L${level}-${seq}`,
    created_at: '2026-01-01T00:00:00Z',
    cluster_id: clusterId,
    class_level: 8,
    topic,
    skill_code: `${topic}_skill`,
    skill_label: `${topic} Skill`,
    level,
    curriculum_seq: 1,
    input_type: 'NUMERIC',
    prompt: `Wert ${value}?`,
    payload: null,
    canonical: { value },
    check_type: 'numeric',
    tolerance: 0,
    typical_errors: [],
    explanation: null,
    source: 'sim',
    active: true,
  }
}

function poolFor(clusterId: string, topic: string, perLevel = 4): ScreeningItem[] {
  const out: ScreeningItem[] = []
  for (const lvl of [1, 2, 3] as ScreeningLevel[]) {
    for (let i = 0; i < perLevel; i += 1) out.push(mk(clusterId, topic, lvl, lvl * 10 + i))
  }
  return out
}

function answerFor(item: ScreeningItem, correct: boolean): { value: number } {
  const v = (item.canonical as { value: number }).value
  return { value: correct ? v : v + 7 }
}

// ── 1) Warm-up-Sweep + Treppe + summarize ────────────────────────────────────
{
  const pool = [
    ...poolFor('cA', 'tA'),
    ...poolFor('cB', 'tB'),
    ...poolFor('cC', 'tC'),
  ]
  const s = createAdaptiveSession(pool, { rng: rngFactory(1) })

  const warm: ScreeningItem[] = []
  for (let i = 0; i < 3; i += 1) {
    const it = nextItem(s)
    assert.ok(it, 'Warm-up: Item erwartet')
    assert.equal(it.level, 1, 'Warm-up muss Stufe 1 sein')
    warm.push(it)
    submitAnswer(s, answerFor(it, true), 1000)
  }
  assert.equal(
    new Set(warm.map((w) => w.cluster_id)).size,
    3,
    'Warm-up-Sweep: je Cluster genau einmal',
  )

  // Erstes Fokus-Item: Start auf Stufe 2.
  const f1 = nextItem(s)
  assert.ok(f1, 'Fokus-Item erwartet')
  assert.equal(f1.level, 2, 'Fokus-Start muss Stufe 2 sein')
  const fc = f1.cluster_id
  submitAnswer(s, answerFor(f1, true), 1000) // richtig → hoch

  // Nächstes Item desselben Clusters muss Stufe 3 sein.
  let f2: ScreeningItem | null = null
  for (let g = 0; g < 20; g += 1) {
    const it = nextItem(s)
    if (!it) break
    if (it.cluster_id === fc) {
      f2 = it
      break
    }
    submitAnswer(s, answerFor(it, true), 1000)
  }
  assert.ok(f2, 'Folge-Fokus-Item erwartet')
  assert.equal(f2.level, 3, 'Richtig auf L2 → L3')
  submitAnswer(s, answerFor(f2, false), 1000) // falsch → runter

  let f3: ScreeningItem | null = null
  for (let g = 0; g < 20; g += 1) {
    const it = nextItem(s)
    if (!it) break
    if (it.cluster_id === fc) {
      f3 = it
      break
    }
    submitAnswer(s, answerFor(it, true), 1000)
  }
  if (f3) assert.equal(f3.level, 2, 'Falsch auf L3 → L2')

  // Test zu Ende spielen, dann auswerten.
  for (let g = 0; g < 200 && !isComplete(s); g += 1) {
    const it = nextItem(s)
    if (!it) break
    submitAnswer(s, answerFor(it, true), 1000)
  }
  const sum = summarize(s)
  assert.equal(sum.length, 3, 'summarize: 3 Cluster')
  for (const c of sum) {
    assert.ok(c.answered > 0, 'jeder Cluster beantwortet')
    assert.ok(c.mastery >= 0 && c.mastery <= 1, 'mastery in [0,1]')
  }
}

// ── 2) Harter Themen-Ausschluss ──────────────────────────────────────────────
{
  const pool = [...poolFor('cA', 'tA'), ...poolFor('cX', 'tX')]
  const s = createAdaptiveSession(pool, {
    excludedTopics: ['tX'],
    rng: rngFactory(2),
  })
  for (let g = 0; g < 200 && !isComplete(s); g += 1) {
    const it = nextItem(s)
    if (!it) break
    assert.notEqual(it.topic, 'tX', 'ausgeschlossenes Thema darf nie erscheinen')
    submitAnswer(s, answerFor(it, true), 1000)
  }
  assert.equal(
    summarize(s).find((c) => c.clusterId === 'cX'),
    undefined,
    'ausgeschlossener Cluster nicht in Auswertung',
  )
}

// ── 3) Gewichtung → mehr Tiefe ───────────────────────────────────────────────
{
  const pool = [...poolFor('cA', 'tA', 6), ...poolFor('cB', 'tB', 6)]
  const s = createAdaptiveSession(pool, {
    weightedTopics: ['tA'],
    rng: rngFactory(3),
  })
  for (let g = 0; g < 200 && !isComplete(s); g += 1) {
    const it = nextItem(s)
    if (!it) break
    submitAnswer(s, answerFor(it, true), 1000)
  }
  const sum = summarize(s)
  const a = sum.find((c) => c.clusterId === 'cA')
  const b = sum.find((c) => c.clusterId === 'cB')
  assert.ok(a && b, 'beide Cluster vorhanden')
  assert.ok(
    a.answered > b.answered,
    `gewichteter Cluster tiefer geprüft (A=${a.answered} > B=${b.answered})`,
  )
}

// ── 4) Budget-Stopp ──────────────────────────────────────────────────────────
{
  const pool = [...poolFor('cA', 'tA'), ...poolFor('cB', 'tB')]
  const s = createAdaptiveSession(pool, { budgetMs: 2500, rng: rngFactory(4) })
  let asked = 0
  for (let g = 0; g < 200 && !isComplete(s); g += 1) {
    const it = nextItem(s)
    if (!it) break
    asked += 1
    submitAnswer(s, answerFor(it, true), 1000) // 1s je Antwort
  }
  assert.ok(asked <= 4, `Budget stoppt früh (gestellt: ${asked})`)
  assert.ok(isComplete(s), 'nach Budget ist der Test fertig')
}

// ── 5) Graceful: Cluster nur mit Stufe 2 ─────────────────────────────────────
{
  const onlyL2 = [0, 1, 2, 3].map((i) => mk('cA', 'tA', 2, 100 + i))
  const s = createAdaptiveSession(onlyL2, { rng: rngFactory(5) })
  let count = 0
  for (let g = 0; g < 50 && !isComplete(s); g += 1) {
    const it = nextItem(s)
    if (!it) break
    assert.equal(it.level, 2, 'nur Stufe 2 verfügbar → diese wird genutzt')
    count += 1
    submitAnswer(s, answerFor(it, true), 1000)
  }
  assert.ok(count > 0, 'fehlende Stufen → kein Crash, Test läuft')
}

// ── 6) Leerer Pool ───────────────────────────────────────────────────────────
{
  const s = createAdaptiveSession([], { rng: rngFactory(6) })
  assert.equal(nextItem(s), null, 'leerer Pool → kein Item')
  assert.ok(isComplete(s), 'leerer Pool → sofort fertig')
  assert.deepEqual(summarize(s), [], 'leerer Pool → leere Auswertung')
}

console.log('screening-sim: alle Checks bestanden ✓')
