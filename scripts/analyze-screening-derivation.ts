// ============================================================================
// READ-ONLY Ableitungs-Analyse für screening_items — v2 (payload-aware).
//
// Lauf: tsx --env-file=.env scripts/analyze-screening-derivation.ts
// (braucht SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY — Service-Role, weil VERA-
//  Items i.d.R. active=false und sonst per RLS unsichtbar sind.)
//
// Ermittelt, welche screening_items sich VERLÄSSLICH auto-prüfbar typisieren
// lassen (→ kanonischer input_type + canonical-Payload) und welche FREE_TEXT
// bleiben müssen. Schreibt:
//   - docs/SCREENING_DERIVATION.md                    (Report für Rasit/Lena)
//   - scripts/out/screening_derivation_proposal.json  (Input für Apply-Migration)
//
// v2-Verschärfungen:
//   (a) mehrteilig/sonstige → FREE_TEXT bekommen KEIN Lena-Flag (korrekt coach,
//       kein Review); nur echte strukturierte Typen + Koordinaten werden geflaggt.
//   (b) `payload`-Feld wird mitgelesen; für mc_single/mc_multi wird ein MC-
//       canonical_payload gebaut, WENN payload.options {text,correct} trägt.
//       MATCHING/CLOZE bleiben bewusst Lena-Flag (Auto-Bau wäre Falsch-Auto-Risiko).
//
// ⚠️  ABSOLUT READ-ONLY: nur SELECT, KEINE Mutation, KEINE Migration.
//     Im Zweifel wird ein Item lieber FREE_TEXT / Lena-Flag als falsch auto.
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
  input_type: string | null
  aufgabe_typ: string | null
  akzeptierte_antworten: unknown
  loesung_pro_ta: unknown
  kontext: string | null
  prompt: string | null
  payload: unknown
}

type Category =
  | 'AUTO_SHORT_TEXT'
  | 'RUBRIK_FREE_TEXT'
  | 'COORDINATE_FLAG'
  | 'OTHER_TYPE'
  | 'NO_KEY'

type CanonicalInputType =
  | 'MC' | 'NUMERIC' | 'SHORT_TEXT' | 'TRUE_FALSE'
  | 'FREE_TEXT' | 'MATCHING' | 'CLOZE' | 'COORDINATE'

type Decision = {
  item_id: string
  category: Category
  proposed_input_type: CanonicalInputType
  reason: string
  lena_flag?: 'COORDINATE' | 'OTHER_TYPE_UNBUILDABLE'
  subtype?: string // aufgabe_typ bei OTHER_TYPE
  canonical_payload?: Record<string, unknown>
  accepted?: string[] // Rohdaten zur Stichprobe (nur Report)
}

// ── Normalisierung ───────────────────────────────────────────────────────────
function isObj(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null
}

function asStringArray(v: unknown): string[] {
  if (Array.isArray(v)) {
    return v
      .map((e) => (typeof e === 'string' ? e : typeof e === 'number' ? String(e) : ''))
      .map((s) => s.trim())
      .filter(Boolean)
  }
  if (typeof v === 'string') {
    const s = v.trim()
    return s ? [s] : []
  }
  if (isObj(v)) {
    return Object.values(v)
      .map((e) => (typeof e === 'string' ? e.trim() : ''))
      .filter(Boolean)
  }
  return []
}

function hasUsableLoesung(v: unknown): boolean {
  if (Array.isArray(v)) return v.length > 0
  if (isObj(v)) return Object.keys(v).length > 0
  if (typeof v === 'string') return v.trim().length > 0
  return false
}

// Begründungs-/Rubrik-Schlüsselwörter → NIE auto (String-Match wäre falsch).
const JUSTIFY = [
  'weil', 'korrekt', 'begründ', 'begrund', 'lösung', 'loesung', 'anwendung',
  'richtig', 'sodass', 'damit', 'erklär', 'erklar', 'beschreib', 'nenne',
  'vorteil', 'nachteil', 'grund', 'aussage', 'weshalb', 'inhaltlich',
]
function isJustification(s: string): boolean {
  const t = s.toLowerCase()
  return JUSTIFY.some((k) => t.includes(k))
}
function wordCount(s: string): number {
  return s.trim().split(/\s+/).filter(Boolean).length
}
// kurz/tokenartig: ≤25 Zeichen UND ≤3 Wörter UND keine Begründungsmuster.
function isShort(s: string): boolean {
  return s.trim().length <= 25 && wordCount(s) <= 3 && !isJustification(s)
}
// langer Satz / Begründung.
function isLong(s: string): boolean {
  return s.trim().length > 40 || wordCount(s) > 6 || isJustification(s)
}

function coordinateHint(row: Row, aa: string[]): boolean {
  const text = [row.kontext ?? '', row.prompt ?? '', ...aa].join(' ').toLowerCase()
  if (/koordinatensystem|eckpunkt|koordinaten/.test(text)) return true
  return /punkt[^.]{0,40}(eingetragen|eingezeichnet|einzutragen|eintragen|einzeichnen|markier)/.test(
    text,
  )
}

function mapAufgabeTyp(at: string): CanonicalInputType | null {
  if (/(^|[^a-z])mc([^a-z]|$)|multiple.?choice|ankreuz/.test(at)) return 'MC'
  if (/zuordn|matching|verbind/.test(at)) return 'MATCHING'
  if (/l(ü|ue)ckentext|cloze|l(ü|ue)cke/.test(at)) return 'CLOZE'
  if (/wahr.?falsch|richtig.?falsch|true.?false|ja.?nein/.test(at)) return 'TRUE_FALSE'
  return null
}

function trueFalseFromAccepted(aa: string[]): boolean | null {
  if (aa.length !== 1) return null
  const t = aa[0].toLowerCase().trim()
  if (/^(wahr|richtig|stimmt|ja|true)$/.test(t)) return true
  if (/^(falsch|nicht richtig|nein|false)$/.test(t)) return false
  return null
}

// (b) MC-canonical_payload aus dem screening payload bauen — NUR wenn die
// Optionen + ein korrekt-Flag eindeutig drinstehen. Sonst null → Lena-Flag.
function buildMcFromPayload(payload: unknown, multi: boolean): Record<string, unknown> | null {
  if (!isObj(payload) || !Array.isArray(payload.options)) return null
  const opts = payload.options
  if (opts.length < 2) return null
  const options: { id: string; label: string }[] = []
  const correct: string[] = []
  for (let i = 0; i < opts.length; i++) {
    const o = opts[i]
    if (!isObj(o)) return null
    const label = typeof o.text === 'string' ? o.text : typeof o.label === 'string' ? o.label : null
    if (!label || !label.trim()) return null
    const id = String(i)
    options.push({ id, label: label.trim() })
    if (o.correct === true) correct.push(id)
  }
  if (correct.length === 0) return null // kein korrekt-Flag → nicht raten
  if (!multi && correct.length !== 1) return null // mc_single muss genau 1 haben
  return { input_type: 'MC', options, correct }
}

// ── Klassifikation ───────────────────────────────────────────────────────────
function classify(row: Row): Decision {
  const at = (row.aufgabe_typ ?? '').toLowerCase().trim()
  const aa = asStringArray(row.akzeptierte_antworten)
  const hasKey = aa.length > 0 || hasUsableLoesung(row.loesung_pro_ta)
  const base = { item_id: row.id, accepted: aa, subtype: at || undefined }

  // 1) OTHER_TYPE — aufgabe_typ ist explizit KEIN Kurzantwort-Typ.
  const isKurz = at === '' || /kurzantwort|kurz|freie?antwort|offen/.test(at)
  if (!isKurz) {
    const mapped = mapAufgabeTyp(at)

    if (mapped === 'MC') {
      const multi = /multi/.test(at)
      const mc = buildMcFromPayload(row.payload, multi)
      if (mc) {
        return {
          ...base,
          category: 'OTHER_TYPE',
          proposed_input_type: 'MC',
          reason: 'MC: options + correct-Flag aus payload baubar → auto',
          canonical_payload: mc,
        }
      }
      return {
        ...base,
        category: 'OTHER_TYPE',
        proposed_input_type: 'MC',
        reason: `aufgabe_typ=${at}; payload.options/correct fehlt → Anreicherung (Lena/Tool)`,
        lena_flag: 'OTHER_TYPE_UNBUILDABLE',
      }
    }

    if (mapped === 'TRUE_FALSE') {
      const tf = trueFalseFromAccepted(aa)
      if (tf !== null) {
        return {
          ...base,
          category: 'OTHER_TYPE',
          proposed_input_type: 'TRUE_FALSE',
          reason: 'correct aus akzeptierte_antworten ableitbar → auto',
          canonical_payload: { input_type: 'TRUE_FALSE', correct: tf },
        }
      }
      return {
        ...base,
        category: 'OTHER_TYPE',
        proposed_input_type: 'TRUE_FALSE',
        reason: `aufgabe_typ=${at}; correct nicht eindeutig ableitbar → Lena`,
        lena_flag: 'OTHER_TYPE_UNBUILDABLE',
      }
    }

    if (mapped === 'MATCHING' || mapped === 'CLOZE') {
      return {
        ...base,
        category: 'OTHER_TYPE',
        proposed_input_type: mapped,
        reason: `aufgabe_typ=${at}; Struktur nicht sicher aus Daten baubar → Lena`,
        lena_flag: 'OTHER_TYPE_UNBUILDABLE',
      }
    }

    // mapped === null → mehrteilig / unvollstaendig / unbekannt → reiner FREE_TEXT,
    // KEIN Review-Flag (Mehrschritt ist im MVP-Enum bewusst coach-bewertet).
    return {
      ...base,
      category: 'OTHER_TYPE',
      proposed_input_type: 'FREE_TEXT',
      reason: `aufgabe_typ=${at || '∅'}: kein kanonischer Auto-Typ (z.B. mehrteilig) → coach`,
    }
  }

  // 2) COORDINATE_FLAG — Punkt/Koordinatensystem (Payload nicht aus Daten baubar).
  if (coordinateHint(row, aa)) {
    return {
      ...base,
      category: 'COORDINATE_FLAG',
      proposed_input_type: 'FREE_TEXT',
      reason: 'Koordinaten-/Punkt-Indikatoren → COORDINATE-Kandidat (Lena)',
      lena_flag: 'COORDINATE',
    }
  }

  // 3) NO_KEY — keine verwertbare Lösung.
  if (!hasKey) {
    return {
      ...base,
      category: 'NO_KEY',
      proposed_input_type: 'FREE_TEXT',
      reason: 'kein akzeptierte_antworten und kein verwertbares loesung_pro_ta',
    }
  }

  // 4) RUBRIK_FREE_TEXT — mind. ein langer/Begründungs-Eintrag.
  if (aa.some(isLong)) {
    return {
      ...base,
      category: 'RUBRIK_FREE_TEXT',
      proposed_input_type: 'FREE_TEXT',
      reason: 'mind. ein Eintrag ist Satz/Begründung → coach-bewertet',
    }
  }

  // 5) AUTO_SHORT_TEXT — alle Einträge kurz/tokenartig.
  if (aa.length > 0 && aa.every(isShort)) {
    return {
      ...base,
      category: 'AUTO_SHORT_TEXT',
      proposed_input_type: 'SHORT_TEXT',
      reason: 'alle akzeptierte_antworten kurz/tokenartig → auto-prüfbar',
      canonical_payload: { input_type: 'SHORT_TEXT', accepted: aa, caseInsensitive: true },
    }
  }

  // 6) Unsicher (mittellang, kein klares Muster) → sicher FREE_TEXT.
  return {
    ...base,
    category: 'RUBRIK_FREE_TEXT',
    proposed_input_type: 'FREE_TEXT',
    reason: 'unklar (mittellange Antworten) → sicher FREE_TEXT',
  }
}

// ── Report-Bau ───────────────────────────────────────────────────────────────
function pct(n: number, total: number): string {
  return total === 0 ? '0%' : `${((n / total) * 100).toFixed(1)}%`
}

function buildReport(rows: Row[], decisions: Decision[]): string {
  const total = rows.length

  // aufgabe_typ-Verteilung
  const byTyp = new Map<string, { count: number; withAa: number; withLpt: number }>()
  for (const r of rows) {
    const t = (r.aufgabe_typ ?? '∅').trim() || '∅'
    const e = byTyp.get(t) ?? { count: 0, withAa: 0, withLpt: 0 }
    e.count++
    if (asStringArray(r.akzeptierte_antworten).length > 0) e.withAa++
    if (hasUsableLoesung(r.loesung_pro_ta)) e.withLpt++
    byTyp.set(t, e)
  }

  const catCount = new Map<Category, number>()
  for (const d of decisions) catCount.set(d.category, (catCount.get(d.category) ?? 0) + 1)
  const cat = (c: Category) => catCount.get(c) ?? 0

  // OTHER_TYPE-Subtypen mit Auto/Flagged/FREE_TEXT-Ausgang
  const otherBySub = new Map<string, number>()
  for (const d of decisions) {
    if (d.category !== 'OTHER_TYPE') continue
    const outcome = d.canonical_payload ? '✓auto' : d.lena_flag ? '⚑Lena' : '→FREE_TEXT'
    const k = `${d.subtype ?? '∅'} → ${d.proposed_input_type} (${outcome})`
    otherBySub.set(k, (otherBySub.get(k) ?? 0) + 1)
  }

  // Aktions-Buckets
  const autoByType = new Map<string, number>()
  for (const d of decisions) {
    if (d.canonical_payload) autoByType.set(d.proposed_input_type, (autoByType.get(d.proposed_input_type) ?? 0) + 1)
  }
  const autoTotal = [...autoByType.values()].reduce((a, b) => a + b, 0)
  const flaggedStructured = decisions.filter((d) => d.lena_flag === 'OTHER_TYPE_UNBUILDABLE').length
  const coordCount = decisions.filter((d) => d.lena_flag === 'COORDINATE').length
  const otherFreeText = decisions.filter((d) => d.category === 'OTHER_TYPE' && !d.canonical_payload && !d.lena_flag).length
  const rubrik = cat('RUBRIK_FREE_TEXT')
  const noKey = cat('NO_KEY')
  const coachTotal = total - autoTotal

  const L: string[] = []
  L.push('# Screening-Items — Ableitungs-Analyse (READ-ONLY, v2 payload-aware)')
  L.push('')
  L.push('Erzeugt von `scripts/analyze-screening-derivation.ts` · **keine** DB-Mutation.')
  L.push(`Gesamt: **${total}** screening_items.`)
  L.push('')
  L.push('## 1. aufgabe_typ-Verteilung')
  L.push('')
  L.push('| aufgabe_typ | Anzahl | mit akzeptierte_antworten | mit loesung_pro_ta |')
  L.push('|---|--:|--:|--:|')
  for (const [t, e] of [...byTyp.entries()].sort((a, b) => b[1].count - a[1].count)) {
    L.push(`| \`${t}\` | ${e.count} | ${e.withAa} | ${e.withLpt} |`)
  }
  L.push('')
  L.push('## 2. Kategorie-Counts')
  L.push('')
  L.push('| Kategorie | Anzahl | Anteil |')
  L.push('|---|--:|--:|')
  for (const c of ['AUTO_SHORT_TEXT', 'RUBRIK_FREE_TEXT', 'COORDINATE_FLAG', 'OTHER_TYPE', 'NO_KEY'] as Category[]) {
    L.push(`| ${c} | ${cat(c)} | ${pct(cat(c), total)} |`)
  }
  L.push('')
  if (otherBySub.size > 0) {
    L.push('### OTHER_TYPE nach Subtyp (Ausgang)')
    L.push('')
    L.push('| aufgabe_typ → Vorschlag (Ausgang) | Anzahl |')
    L.push('|---|--:|')
    for (const [s, n] of [...otherBySub.entries()].sort((a, b) => b[1] - a[1])) {
      L.push(`| ${s} | ${n} |`)
    }
    L.push('')
  }

  L.push('## 3. Aktions-Buckets (was ist real zu tun)')
  L.push('')
  L.push('| Aktion | Items |')
  L.push('|---|--:|')
  L.push(`| **Auto JETZT übernehmen** (${[...autoByType.entries()].map(([k, v]) => `${k} ${v}`).join(', ') || '—'}) | **${autoTotal}** |`)
  L.push(`| Anreicherung/Lena: Payload bauen (strukturierte Typen) | ${flaggedStructured} |`)
  L.push(`| Lena: COORDINATE-Payload | ${coordCount} |`)
  L.push(`| bleibt coach: mehrteilig/sonstige → FREE_TEXT (kein Review) | ${otherFreeText} |`)
  L.push(`| bleibt coach: RUBRIK/offen → FREE_TEXT | ${rubrik} |`)
  L.push(`| bleibt coach: kein Schlüssel → FREE_TEXT | ${noKey} |`)
  L.push('')

  // Stichproben (10–15 IDs je Kategorie)
  L.push('## 4. Stichproben (je Kategorie, akzeptierte_antworten zur Prüfung)')
  for (const c of ['AUTO_SHORT_TEXT', 'RUBRIK_FREE_TEXT', 'COORDINATE_FLAG', 'OTHER_TYPE', 'NO_KEY'] as Category[]) {
    const samples = decisions.filter((d) => d.category === c).slice(0, 15)
    L.push('')
    L.push(`### ${c} (${cat(c)})`)
    if (samples.length === 0) {
      L.push('_keine_')
      continue
    }
    L.push('')
    L.push('| item_id | Vorschlag | akzeptierte_antworten / Grund |')
    L.push('|---|---|---|')
    for (const d of samples) {
      const tag = d.canonical_payload ? ' ✓auto' : d.lena_flag ? ` ⚑${d.lena_flag}` : ''
      const aa = d.accepted && d.accepted.length > 0 ? JSON.stringify(d.accepted) : `_(${d.reason})_`
      const cell = aa.length > 90 ? `${aa.slice(0, 90)}…` : aa
      L.push(`| \`${d.item_id.slice(0, 8)}\` | ${d.proposed_input_type}${tag} | ${cell.replace(/\|/g, '\\|')} |`)
    }
  }

  L.push('')
  L.push('## 5. Fazit')
  L.push('')
  L.push(`- **Auto-prüfbar nach Anwendung (Screening-Pool):** ${autoTotal} Items ` +
    `(${[...autoByType.entries()].map(([k, v]) => `${k} ${v}`).join(', ') || '—'}).`)
  L.push(`- **Bleibt coach-bewertet (FREE_TEXT):** ${coachTotal} Items.`)
  L.push(`- **Echter Anreicherungs-Aufwand (Lena/Tool):** ${flaggedStructured} strukturierte ` +
    `+ ${coordCount} Koordinaten = ${flaggedStructured + coordCount} Items ` +
    `— NICHT die ${otherFreeText} mehrteiligen (die sind korrekt coach).`)
  L.push('')
  L.push('> Vorschlag ist konservativ: im Zweifel FREE_TEXT/Lena-Flag statt falsch auto.')
  L.push('> SHORT_TEXT/MC/TRUE_FALSE-Items brauchen in der Apply-Migration check_type ≠ manual')
  L.push('> (normalized bzw. mc_index). Apply-Migration erst nach Prüfung durch Rasit/Lena.')
  L.push('')
  return L.join('\n')
}

// ── Main ─────────────────────────────────────────────────────────────────────
async function main(): Promise<void> {
  console.log('▶ Lade screening_items (read-only) …')
  const { data, error } = await supabase
    .from('screening_items')
    .select('id, input_type, aufgabe_typ, akzeptierte_antworten, loesung_pro_ta, kontext, prompt, payload')
  if (error) {
    console.error('Query fehlgeschlagen:', error.message)
    process.exit(1)
  }
  const rows = (data ?? []) as Row[]
  console.log(`  ${rows.length} Items geladen.`)

  const decisions = rows.map(classify)

  const proposal = decisions.map((d) => ({
    item_id: d.item_id,
    category: d.category,
    proposed_input_type: d.proposed_input_type,
    reason: d.reason,
    ...(d.lena_flag ? { lena_flag: d.lena_flag } : {}),
    ...(d.canonical_payload ? { canonical_payload: d.canonical_payload } : {}),
  }))

  mkdirSync('scripts/out', { recursive: true })
  writeFileSync('scripts/out/screening_derivation_proposal.json', JSON.stringify(proposal, null, 2))
  writeFileSync('docs/SCREENING_DERIVATION.md', buildReport(rows, decisions))

  const catCount = new Map<Category, number>()
  for (const d of decisions) catCount.set(d.category, (catCount.get(d.category) ?? 0) + 1)
  const autoByType = new Map<string, number>()
  for (const d of decisions) if (d.canonical_payload) autoByType.set(d.proposed_input_type, (autoByType.get(d.proposed_input_type) ?? 0) + 1)
  const autoTotal = [...autoByType.values()].reduce((a, b) => a + b, 0)

  console.log('\n── Kategorie-Counts ──')
  for (const c of ['AUTO_SHORT_TEXT', 'RUBRIK_FREE_TEXT', 'COORDINATE_FLAG', 'OTHER_TYPE', 'NO_KEY'] as Category[]) {
    console.log(`  ${c.padEnd(18)} ${catCount.get(c) ?? 0}`)
  }
  console.log('\n── Auto-Pool nach Typ ──')
  for (const [k, v] of autoByType) console.log(`  ${k.padEnd(12)} ${v}`)
  console.log(`\n  → auto-prüfbar: ${autoTotal}   coach-bewertet: ${rows.length - autoTotal}`)
  console.log('\n✔ geschrieben:')
  console.log('  docs/SCREENING_DERIVATION.md')
  console.log('  scripts/out/screening_derivation_proposal.json')
}

void main()
