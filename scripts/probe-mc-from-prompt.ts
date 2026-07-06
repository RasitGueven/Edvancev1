// ============================================================================
// READ-ONLY MC-Probe: lassen sich die mc_single/mc_multi-Items doch noch zu
// MC-canonical_payloads bauen, wenn man die Optionen aus dem `prompt` parst
// und den Korrekt-Index aus `akzeptierte_antworten` zieht?
//
// Lauf: tsx --env-file=.env scripts/probe-mc-from-prompt.ts
//
// Output (Vorschau, KEIN Apply):
//   - docs/SCREENING_MC_PROBE.md                 (zur menschlichen Verifikation)
//   - scripts/out/screening_mc_probe.json        (Kandidaten-Payloads, Review)
//
// ⚠️  ABSOLUT READ-ONLY (nur SELECT). Konservativ: ein Item gilt nur als
//     „baubar", wenn Optionen UND Korrekt-Index eindeutig+konsistent sind.
//     Geparste Optionen MÜSSEN von Rasit/Lena gegengeprüft werden, bevor
//     irgendetwas auto-bewertet wird (Fehlparse = Falsch-Auto).
// ============================================================================

import { createClient } from '@supabase/supabase-js'
import { mkdirSync, writeFileSync } from 'node:fs'

const url = process.env.SUPABASE_URL ?? process.env.VITE_SUPABASE_URL
const key = process.env.SUPABASE_SERVICE_ROLE_KEY
if (!url || !key) {
  console.error('Fehlende ENV-Vars: SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY')
  process.exit(1)
}
const supabase = createClient(url, key, {
  auth: { autoRefreshToken: false, persistSession: false },
})

type Row = {
  id: string
  aufgabe_typ: string | null
  prompt: string | null
  akzeptierte_antworten: unknown
  payload: unknown
  meta: unknown
  kontext: string | null
}

function isObj(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null
}
function asStringArray(v: unknown): string[] {
  if (Array.isArray(v)) {
    return v.map((e) => (typeof e === 'string' ? e : typeof e === 'number' ? String(e) : '')).map((s) => s.trim()).filter(Boolean)
  }
  if (typeof v === 'string') return v.trim() ? [v.trim()] : []
  if (isObj(v)) return Object.values(v).map((e) => (typeof e === 'string' ? e.trim() : '')).filter(Boolean)
  return []
}
function norm(s: string): string {
  return s.trim().toLowerCase().replace(/\s+/g, ' ').replace(',', '.')
}
function keysOf(v: unknown): string[] {
  return isObj(v) ? Object.keys(v) : Array.isArray(v) ? ['<array>'] : []
}

const LETTERS = ['A', 'B', 'C', 'D', 'E', 'F']

// Label-basiertes Parsen (A) … B) … oder 1) … 2) …). Verlangt aufsteigende,
// lückenlose Label-Folge ab dem ersten gültigen Label → reduziert Fehlmatches.
function matchLabeled(text: string, labelClass: string): string[] | null {
  const re = new RegExp(`(?:^|[\\s(])\\(?([${labelClass}])[).:]\\s+`, 'g')
  const marks: { label: string; idx: number; len: number }[] = []
  let m: RegExpExecArray | null
  while ((m = re.exec(text)) !== null) {
    marks.push({ label: m[1].toUpperCase(), idx: m.index + m[0].indexOf(m[1]), len: m[0].length - m[0].indexOf(m[1]) })
  }
  if (marks.length < 2) return null
  // Erwartete Folge A,B,C… bzw. 1,2,3… ab dem ersten Treffer prüfen.
  const seq = labelClass.includes('A') ? LETTERS : ['1', '2', '3', '4', '5', '6']
  const startPos = seq.indexOf(marks[0].label)
  if (startPos < 0) return null
  for (let i = 0; i < marks.length; i++) {
    if (marks[i].label !== seq[startPos + i]) return null // nicht lückenlos/aufsteigend → verwerfen
  }
  const opts: string[] = []
  for (let i = 0; i < marks.length; i++) {
    const start = marks[i].idx + marks[i].len
    const end = i + 1 < marks.length ? marks[i + 1].idx : text.length
    const seg = text.slice(start, end).trim().replace(/\s+/g, ' ')
    if (seg) opts.push(seg)
  }
  return opts.length >= 2 ? opts : null
}

function parseOptionsFromPrompt(prompt: string | null): { strategy: string; options: string[] } | null {
  if (!prompt) return null
  const letter = matchLabeled(prompt, 'A-Fa-f')
  if (letter) return { strategy: 'letter', options: letter }
  const num = matchLabeled(prompt, '1-6')
  if (num) return { strategy: 'number', options: num }
  // Zeilen mit Bullet/Kästchen-Markern.
  const lines = prompt.split(/\r?\n/).map((s) => s.trim()).filter(Boolean)
  const bulleted = lines
    .filter((l) => /^[□☐▢◻○●•\-*]\s+/.test(l))
    .map((l) => l.replace(/^[□☐▢◻○●•\-*]\s+/, '').trim())
  if (bulleted.length >= 2) return { strategy: 'bullet', options: bulleted }
  return null
}

// Korrekt-Index(e) aus akzeptierte_antworten bestimmen — entweder als explizite
// Positionsangabe ("Antwort 3"/"Kästchen 3"/"3. Alternative") oder per
// Literal-Match einer aa-Antwort gegen die geparsten Optionen.
function extractCorrect(
  aa: string[],
  options: string[],
): { indices: number[]; how: string } | null {
  const idx = new Set<number>()
  for (const a of aa) {
    const m1 = a.match(/(?:antwort(?:alternative)?|k[aä]stchen|option|alternative|auswahl|feld)\s*(?:nr\.?\s*)?(\d+)/i)
    const m2 = a.match(/\b(\d+)\.\s*(?:antwort|alternative|option|m[oö]glichkeit)/i)
    const n = m1 ? parseInt(m1[1], 10) : m2 ? parseInt(m2[1], 10) : NaN
    if (Number.isFinite(n)) idx.add(n)
  }
  if (idx.size > 0) return { indices: [...idx], how: 'index-reference' }

  // Literal-Match: aa-Eintrag == geparste Option (normalisiert).
  const lit = new Set<number>()
  const normOpts = options.map(norm)
  for (const a of aa) {
    const i = normOpts.indexOf(norm(a))
    if (i >= 0) lit.add(i + 1) // 1-basiert wie die Positionsangaben
  }
  if (lit.size > 0) return { indices: [...lit], how: 'literal-match' }
  return null
}

type Probe = {
  id: string
  aufgabe_typ: string
  multi: boolean
  optionStrategy: string | null
  options: string[]
  correct: number[] // 1-basiert
  correctHow: string | null
  buildable: boolean
  reason: string
  optionSource: 'prompt' | 'none'
  payloadKeys: string[]
  metaKeys: string[]
  accepted: string[]
  candidate?: Record<string, unknown>
}

function probe(row: Row): Probe {
  const at = (row.aufgabe_typ ?? '').toLowerCase().trim()
  const multi = /multi/.test(at)
  const aa = asStringArray(row.akzeptierte_antworten)
  const parsed = parseOptionsFromPrompt(row.prompt)
  const base: Probe = {
    id: row.id,
    aufgabe_typ: at,
    multi,
    optionStrategy: parsed?.strategy ?? null,
    options: parsed?.options ?? [],
    correct: [],
    correctHow: null,
    buildable: false,
    reason: '',
    optionSource: parsed ? 'prompt' : 'none',
    payloadKeys: keysOf(row.payload),
    metaKeys: keysOf(row.meta),
    accepted: aa,
  }

  if (!parsed) {
    return { ...base, reason: 'keine Optionen im prompt parsbar (A)/Nummer/Bullet)' }
  }
  const corr = extractCorrect(aa, parsed.options)
  if (!corr) {
    return { ...base, reason: 'Optionen ok, aber Korrekt-Index nicht aus akzeptierte_antworten ableitbar' }
  }
  // Konsistenz: alle Indizes im Bereich?
  const inRange = corr.indices.every((n) => n >= 1 && n <= parsed.options.length)
  if (!inRange) {
    return {
      ...base,
      correct: corr.indices,
      correctHow: corr.how,
      reason: `Korrekt-Index ${JSON.stringify(corr.indices)} außerhalb der ${parsed.options.length} geparsten Optionen → unsicher`,
    }
  }
  if (!multi && corr.indices.length !== 1) {
    return {
      ...base,
      correct: corr.indices,
      correctHow: corr.how,
      reason: `mc_single, aber ${corr.indices.length} Korrekt-Indizes → unsicher`,
    }
  }
  const candidate = {
    input_type: 'MC',
    options: parsed.options.map((label, i) => ({ id: String(i), label })),
    correct: corr.indices.map((n) => String(n - 1)), // 1-basiert → 0-basierte id
  }
  return {
    ...base,
    correct: corr.indices,
    correctHow: corr.how,
    buildable: true,
    reason: `baubar via ${parsed.strategy}-Optionen + ${corr.how}`,
    candidate,
  }
}

function trunc(s: string, n: number): string {
  const one = s.replace(/\s+/g, ' ').trim()
  return one.length > n ? `${one.slice(0, n)}…` : one
}

function buildReport(rows: Row[], probes: Probe[]): string {
  const total = probes.length
  const withOptions = probes.filter((p) => p.optionStrategy).length
  const withCorrect = probes.filter((p) => p.correctHow).length
  const buildable = probes.filter((p) => p.buildable)
  const byStrategy = new Map<string, number>()
  for (const p of probes) if (p.optionStrategy) byStrategy.set(p.optionStrategy, (byStrategy.get(p.optionStrategy) ?? 0) + 1)
  const single = buildable.filter((p) => !p.multi).length
  const multi = buildable.filter((p) => p.multi).length

  const L: string[] = []
  L.push('# MC-Probe — Optionen aus prompt + Korrekt aus akzeptierte_antworten (READ-ONLY)')
  L.push('')
  L.push('Erzeugt von `scripts/probe-mc-from-prompt.ts` · **keine** DB-Mutation · **Vorschau, kein Apply**.')
  L.push(`MC-Items (mc_single/mc_multi) gesamt: **${total}**.`)
  L.push('')
  L.push('## Zusammenfassung')
  L.push('')
  L.push('| Kriterium | Anzahl |')
  L.push('|---|--:|')
  L.push(`| Optionen aus prompt parsbar | ${withOptions} / ${total} |`)
  for (const [s, n] of byStrategy) L.push(`| &nbsp;&nbsp;davon Strategie \`${s}\` | ${n} |`)
  L.push(`| Korrekt-Index bestimmbar | ${withCorrect} / ${total} |`)
  L.push(`| **VOLL baubar (Optionen + Korrekt, konsistent)** | **${buildable.length} / ${total}** |`)
  L.push(`| &nbsp;&nbsp;davon mc_single / mc_multi | ${single} / ${multi} |`)
  L.push('')
  L.push(`> Würde der Auto-Pool **um bis zu ${buildable.length}** wachsen — **erst nach** menschlicher`)
  L.push('> Verifikation der geparsten Optionen unten (Fehlparse = Falsch-Auto).')
  L.push('')

  // Wo liegen die Optionen NICHT im prompt? payload/meta-Keys zur Orientierung.
  const noOpt = probes.filter((p) => !p.optionStrategy)
  if (noOpt.length > 0) {
    L.push(`## „Keine Optionen im prompt" (${noOpt.length}) — wo könnten sie stecken?`)
    L.push('')
    const payloadKeyFreq = new Map<string, number>()
    const metaKeyFreq = new Map<string, number>()
    for (const p of noOpt) {
      for (const k of p.payloadKeys) payloadKeyFreq.set(k, (payloadKeyFreq.get(k) ?? 0) + 1)
      for (const k of p.metaKeys) metaKeyFreq.set(k, (metaKeyFreq.get(k) ?? 0) + 1)
    }
    L.push(`- **payload**-Keys: ${[...payloadKeyFreq.entries()].map(([k, n]) => `\`${k}\`(${n})`).join(', ') || '— (leer/null)'}`)
    L.push(`- **meta**-Keys: ${[...metaKeyFreq.entries()].map(([k, n]) => `\`${k}\`(${n})`).join(', ') || '— (leer/null)'}`)
    L.push('')
  }

  // Baubare Kandidaten zur Verifikation.
  L.push(`## Baubare Kandidaten (${buildable.length}) — BITTE GEGENPRÜFEN`)
  if (buildable.length === 0) {
    L.push('')
    L.push('_keine_ — die MC-Optionen lassen sich nicht verlässlich aus prompt+aa rekonstruieren.')
  }
  for (const p of buildable.slice(0, 30)) {
    L.push('')
    L.push(`### \`${p.id.slice(0, 8)}\` · ${p.aufgabe_typ} · via ${p.optionStrategy}+${p.correctHow}`)
    p.options.forEach((o, i) => {
      const mark = p.correct.includes(i + 1) ? ' ✅' : ''
      L.push(`- (${LETTERS[i] ?? i + 1}) ${trunc(o, 120)}${mark}`)
    })
    L.push(`- _akzeptierte_antworten:_ ${trunc(JSON.stringify(p.accepted), 160)}`)
  }
  L.push('')

  // Nicht-baubar: Stichproben mit Grund.
  const notBuildable = probes.filter((p) => !p.buildable)
  L.push(`## Nicht (sicher) baubar (${notBuildable.length}) — Stichprobe`)
  L.push('')
  L.push('| item_id | Grund | prompt (Auszug) | akzeptierte_antworten |')
  L.push('|---|---|---|---|')
  for (const p of notBuildable.slice(0, 15)) {
    const pr = trunc(rows.find((r) => r.id === p.id)?.prompt ?? '', 60).replace(/\|/g, '\\|')
    const aa = trunc(JSON.stringify(p.accepted), 50).replace(/\|/g, '\\|')
    L.push(`| \`${p.id.slice(0, 8)}\` | ${p.reason.replace(/\|/g, '\\|')} | ${pr} | ${aa} |`)
  }
  L.push('')
  L.push('## Fazit')
  L.push('')
  L.push(`- **${buildable.length}** der ${total} MC-Items sind aus \`prompt\`+\`akzeptierte_antworten\` rekonstruierbar`)
  L.push(`  (mc_single ${single}, mc_multi ${multi}) — **nach Sichtprüfung** der Optionen oben.`)
  L.push(`- **${total - buildable.length}** bleiben Lena/Tool (Optionen nicht im prompt oder Korrekt nicht ableitbar).`)
  L.push('- Kandidaten-Payloads liegen in `scripts/out/screening_mc_probe.json` — **nur für Review**, nicht für Apply.')
  L.push('')
  return L.join('\n')
}

async function main(): Promise<void> {
  console.log('▶ Lade MC-Items (read-only) …')
  const { data, error } = await supabase
    .from('screening_items')
    .select('id, aufgabe_typ, prompt, akzeptierte_antworten, payload, meta, kontext')
    .in('aufgabe_typ', ['mc_single', 'mc_multi'])
  if (error) {
    console.error('Query fehlgeschlagen:', error.message)
    process.exit(1)
  }
  const rows = (data ?? []) as Row[]
  console.log(`  ${rows.length} MC-Items.`)

  const probes = rows.map(probe)
  const buildable = probes.filter((p) => p.buildable)

  const candidates = buildable.map((p) => ({
    item_id: p.id,
    aufgabe_typ: p.aufgabe_typ,
    correct_how: p.correctHow,
    option_strategy: p.optionStrategy,
    candidate_payload: p.candidate,
    raw_accepted: p.accepted,
  }))

  mkdirSync('scripts/out', { recursive: true })
  writeFileSync('scripts/out/screening_mc_probe.json', JSON.stringify(candidates, null, 2))
  writeFileSync('docs/SCREENING_MC_PROBE.md', buildReport(rows, probes))

  const withOpt = probes.filter((p) => p.optionStrategy).length
  const withCorr = probes.filter((p) => p.correctHow).length
  console.log('\n── MC-Probe ──')
  console.log(`  Optionen aus prompt parsbar : ${withOpt} / ${rows.length}`)
  console.log(`  Korrekt-Index bestimmbar    : ${withCorr} / ${rows.length}`)
  console.log(`  VOLL baubar (zu verifizieren): ${buildable.length} / ${rows.length}`)
  console.log('\n✔ geschrieben:')
  console.log('  docs/SCREENING_MC_PROBE.md')
  console.log('  scripts/out/screening_mc_probe.json')
}

void main()
