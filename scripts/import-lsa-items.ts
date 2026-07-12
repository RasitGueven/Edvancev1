// Import der 15 manuell gesichteten VERA-8 SHORT_INPUT-Items in den LSA-Pool
// (tasks.status='ready' + task_solutions). Spec: prompts/content/SPEC-C03-lsa-items-import.md
//
// Nutzung:
//   npm run import:lsa-items            # Dry-Run (Default, schreibt nichts)
//   npm run import:lsa-items -- --write # schreibt
//   npm run import:lsa-items -- --verify# nur Verifikations-Queries (Spec §7)
//
// Idempotent: Match ueber (source, source_ref). Ein zweiter Lauf legt nichts
// doppelt an und ueberschreibt bestehende Zeilen NICHT (manuelle Korrekturen
// bleiben stehen).
//
// Der Lauf raet nicht: Titel, Aufgabentyp, AFB, Matrix und die zu entfernende
// Feld-Label-Zeile werden gegen die Quelle geprueft. Weicht etwas ab, bricht das
// Item mit Fehler ab, statt einen verstuemmelten Prompt zu schreiben (Spec §2).

import { readFileSync } from 'node:fs'
import { createClient, type SupabaseClient } from '@supabase/supabase-js'

const SOURCE_FILE = 'data/vera8_komplett_enriched.json'
const SOURCE = 'VERA8_IQB'

type ItemSpec = {
  prefix: string
  titel: string
  /** Verbindlich aus Spec §1 — ersetzt `akzeptierte_antworten` aus dem JSON. */
  answers: string[]
  unit: string | null
  /**
   * Die abschliessende Zeile von `aufgabe_text`, die das Label des Eingabefelds
   * ist und nicht zur Frage gehoert (Spec §2). Muss exakt matchen, sonst STOP.
   * `null` = dieses Item hat keine Feld-Label-Zeile.
   */
  dropTrailing: string | null
  /** Gesetzt = Item wird NICHT importiert, sondern gemeldet. */
  blocked?: string
}

// Genau diese 15 — keine Ausweitung, kein Filter ueber `status` (Spec §0/§6).
const ITEMS: ItemSpec[] = [
  { prefix: '1a518b4b', titel: 'Bestimme x', answers: ['20'], unit: null, dropTrailing: 'x = __________' },
  { prefix: 'a880daf0', titel: 'Das ist gerundet', answers: ['5,1'], unit: null, dropTrailing: '5,143 ≈' },
  { prefix: '4d8811de', titel: 'Einfache Gleichung', answers: ['2'], unit: null, dropTrailing: 'x=' },
  { prefix: '17f4df4b', titel: 'Gleichung lösen 1', answers: ['-10'], unit: null, dropTrailing: null },
  {
    prefix: '7ab3cfad',
    titel: 'Kugeln ziehen',
    answers: ['3'],
    unit: null,
    dropTrailing: '__________-mal so viele gelbe Kugeln',
  },
  { prefix: '82e6559f', titel: 'Papier', answers: ['22'], unit: 'mm', dropTrailing: 'mm' },
  { prefix: 'b3c8ade1', titel: 'Pflaumen', answers: ['0,95'], unit: '€', dropTrailing: '€' },
  {
    prefix: 'e9a54ab8',
    titel: 'Temperaturdifferenz',
    answers: ['19'],
    unit: '°C',
    // Einheit steckt mitten im Feld-Satz; die Frage davor ist vollstaendig.
    dropTrailing: 'Die Temperatur ist um | °C gestiegen.',
  },
  // Nur `16` — die Umrechnungen aus dem JSON (0,016 km / 160 dm / 1600 cm)
  // wuerden mit unit='m' auch `160` durchgehen lassen (Spec §1).
  { prefix: '9c72e62c', titel: '20 Prozent', answers: ['16'], unit: 'm', dropTrailing: 'm' },
  { prefix: '37337edb', titel: 'Croissant', answers: ['1,25'], unit: '€', dropTrailing: '€' },
  { prefix: 'f464ecf3', titel: 'Ecken an Pyramiden', answers: ['5'], unit: 'Ecken', dropTrailing: 'Ecken' },
  // `lsa_normalize_answer` kollabiert Whitespace, entfernt ihn aber nicht:
  // "500 000" bleibt "500 000". Beide Schreibweisen also explizit (Spec §1).
  { prefix: 'ad736c2a', titel: 'Hälfte', answers: ['500000', '500 000'], unit: null, dropTrailing: null },
  { prefix: 'df59c706', titel: 'Lohnerhöhung', answers: ['10'], unit: '%', dropTrailing: 'Der Lohn wird um % erhöht.' },
  {
    prefix: 'e29bc024',
    titel: 'Winkel im Dreieck',
    answers: ['90'],
    unit: '°',
    dropTrailing: 'g =',
    // Quelltext ist PDF-/EMF-verstuemmelt: die griechischen Winkelnamen sind zu
    // "a, b, g" plattgedrueckt UND die Wortgrenzen sind weg ("Es gilt:bist
    // doppelt so gross wie a.", "gist dreimal so gross wie a."). Auch das
    // _grounding-Zitat ist identisch kaputt — es gibt keine saubere Quelle.
    // Reparatur waere Raten am Aufgabentext -> Spec §2: melden, nicht raten.
    blocked: 'Prompt verstuemmelt (EMF-Extraktion): "Es gilt:bist ...", "gist ..." — Reparatur braucht Freigabe.',
  },
  { prefix: 'a833826c', titel: 'Zwanzig Prozent', answers: ['30'], unit: '€', dropTrailing: '€' },
]

// Inhaltsfeld (edvance_matrix) -> skill_cluster.name. lsa_start joint INNER auf
// skill_clusters — ohne cluster_id landet ein Item nie im LSA-Pool.
const CLUSTER_BY_INHALTSFELD: Record<string, string> = {
  arithmetik_algebra: 'Zahl & Rechnen',
  funktionen: 'Algebra & Funktionen',
  geometrie: 'Geometrie & Messen',
  stochastik: 'Daten & Zufall',
}

type SourceItem = {
  id: string
  titel: string
  task_type: string
  klasse?: number
  quelle?: string
  lizenz_status?: string
  is_diagnostic?: boolean
  aufgabe_text: string
  edvance_matrix: { inhaltsfelder: string[]; prozesskompetenzen: string[] }
  teilaufgaben: { afb_raw?: string }[]
}

class ItemError extends Error {}

/** Entfernt die Feld-Label-Zeile am Ende. Matcht sie nicht exakt: STOP. */
function buildPrompt(spec: ItemSpec, raw: string): string {
  const lines = raw.split('\n')
  if (spec.dropTrailing !== null) {
    const lastIdx = lines.map((l) => l.trim()).findLastIndex((l) => l !== '')
    const last = lines[lastIdx]?.trim()
    if (last !== spec.dropTrailing) {
      throw new ItemError(
        `Feld-Label-Zeile weicht ab. Erwartet ${JSON.stringify(spec.dropTrailing)}, ` +
          `gefunden ${JSON.stringify(last)}. Quelle geaendert -> Spec §2 pruefen.`,
      )
    }
    lines.splice(lastIdx, 1)
  }
  const prompt = lines.join('\n').trim()
  if (!prompt) throw new ItemError('Prompt nach Bereinigung leer.')
  if (spec.unit && prompt.split('\n').at(-1)?.trim() === spec.unit) {
    throw new ItemError('Prompt endet weiterhin auf die Einheit.')
  }
  return prompt
}

type Resolved = {
  spec: ItemSpec
  src: SourceItem
  prompt: string
  afb: string
  inhaltsfeld: string
  prozesskompetenzen: string[]
}

/** Prueft die Quell-Annahmen. Jede Abweichung -> ItemError (kein Default, kein Raten). */
function resolve(spec: ItemSpec, all: SourceItem[]): Resolved {
  const matches = all.filter((i) => i.id.startsWith(spec.prefix))
  if (matches.length !== 1) {
    throw new ItemError(`Praefix ${spec.prefix} trifft ${matches.length} Items (erwartet: genau 1).`)
  }
  const src = matches[0]
  if (src.titel !== spec.titel) throw new ItemError(`Titel weicht ab: "${src.titel}" statt "${spec.titel}".`)
  if (src.task_type !== 'SHORT_INPUT') throw new ItemError(`task_type ist ${src.task_type}, erwartet SHORT_INPUT.`)
  if (src.quelle !== SOURCE) throw new ItemError(`quelle ist "${src.quelle}", erwartet "${SOURCE}".`)

  const teilaufgaben = src.teilaufgaben ?? []
  if (teilaufgaben.length !== 1) throw new ItemError(`${teilaufgaben.length} Teilaufgaben — kein SHORT_INPUT-Single.`)
  const afb = teilaufgaben[0].afb_raw ?? ''
  if (!['I', 'II', 'III'].includes(afb)) throw new ItemError(`afb_raw "${afb}" ist nicht I/II/III.`)

  const inhaltsfelder = src.edvance_matrix?.inhaltsfelder ?? []
  if (inhaltsfelder.length !== 1) {
    throw new ItemError(`${inhaltsfelder.length} Inhaltsfelder (${inhaltsfelder.join(',')}) — Zuordnung uneindeutig.`)
  }
  const inhaltsfeld = inhaltsfelder[0]
  if (!CLUSTER_BY_INHALTSFELD[inhaltsfeld]) throw new ItemError(`Inhaltsfeld "${inhaltsfeld}" hat kein Cluster-Mapping.`)

  const prozesskompetenzen = src.edvance_matrix?.prozesskompetenzen ?? []
  if (!prozesskompetenzen.length) throw new ItemError('Keine Prozesskompetenz in edvance_matrix.')

  return { spec, src, prompt: buildPrompt(spec, src.aufgabe_text ?? ''), afb, inhaltsfeld, prozesskompetenzen }
}

type Lookups = {
  clusterIdByName: Map<string, string>
  competencyByCode: Map<string, { id: string; name: string }>
}

async function loadLookups(sb: SupabaseClient): Promise<Lookups> {
  const { data: subject, error: subErr } = await sb.from('subjects').select('id').eq('name', 'Mathematik').maybeSingle()
  if (subErr) throw new Error(`subjects: ${subErr.message}`)
  if (!subject?.id) throw new Error('Fach "Mathematik" fehlt. Erst `npm run seed:clusters`.')

  const { data: clusters, error: clErr } = await sb
    .from('skill_clusters')
    .select('id,name')
    .eq('subject_id', subject.id)
  if (clErr) throw new Error(`skill_clusters: ${clErr.message}`)

  const clusterIdByName = new Map<string, string>((clusters ?? []).map((c) => [c.name as string, c.id as string]))
  for (const name of new Set(Object.values(CLUSTER_BY_INHALTSFELD))) {
    if (!clusterIdByName.has(name)) throw new Error(`Cluster "${name}" fehlt in skill_clusters (Mathematik).`)
  }

  const { data: comps, error: cmErr } = await sb.from('process_competencies').select('id,code,name')
  if (cmErr) throw new Error(`process_competencies: ${cmErr.message}`)
  const competencyByCode = new Map<string, { id: string; name: string }>(
    (comps ?? []).map((c) => [(c.code as string).toLowerCase(), { id: c.id as string, name: c.name as string }]),
  )
  return { clusterIdByName, competencyByCode }
}

/** tasks-Zeile. Enthaelt bewusst KEINE Loesung — weder in Spalten noch im Payload. */
function taskRow(r: Resolved, lk: Lookups) {
  const comps = r.prozesskompetenzen.map((code) => {
    const hit = lk.competencyByCode.get(code.toLowerCase())
    if (!hit) throw new ItemError(`Prozesskompetenz "${code}" unbekannt in process_competencies.`)
    return hit
  })
  return {
    source: SOURCE,
    source_ref: r.src.id,
    content_type: 'exercise',
    // 'short_input' ist der Payload-*kind* aus lsa_question_payload, kein
    // erlaubter Spaltenwert (tasks_input_type_check). Kanonisch: NUMERIC.
    input_type: 'NUMERIC',
    status: 'ready',
    is_active: true,
    is_diagnostic: r.src.is_diagnostic ?? false,
    title: r.src.titel,
    question: r.prompt,
    unit: r.spec.unit,
    afb: r.afb,
    class_level: r.src.klasse ?? null,
    cluster_id: lk.clusterIdByName.get(CLUSTER_BY_INHALTSFELD[r.inhaltsfeld])!,
    competency_content: r.inhaltsfeld,
    competency_process: comps.map((c) => c.name).join(', '),
    // Single-FK: nur bei eindeutiger Prozesskompetenz. Sonst null — der
    // Klartext oben haelt alle, lsa_start gruppiert ohnehin ueber
    // competency_content.
    competency_id: comps.length === 1 ? comps[0].id : null,
    question_payload: { kind: 'short_input', prompt: r.prompt, ...(r.spec.unit ? { unit: r.spec.unit } : {}) },
  }
}

type Stats = { created: number; existing: number; solutions: number; skipped: number; errors: number }

async function importItem(sb: SupabaseClient, r: Resolved, lk: Lookups, write: boolean, stats: Stats) {
  const row = taskRow(r, lk)
  const { data: existing, error: selErr } = await sb
    .from('tasks')
    .select('id')
    .eq('source', SOURCE)
    .eq('source_ref', r.src.id)
    .maybeSingle()
  if (selErr) throw new Error(`tasks select: ${selErr.message}`)

  let taskId = existing?.id as string | undefined
  if (taskId) {
    stats.existing += 1
    console.log(`  • vorhanden (unveraendert): ${r.spec.titel}`)
  } else if (!write) {
    stats.created += 1
    console.log(`  + wuerde anlegen: ${r.spec.titel} [afb ${row.afb}, unit ${row.unit ?? '—'}]`)
    console.log(`      prompt: ${JSON.stringify(row.question)}`)
    console.log(`      loesung -> task_solutions: ${JSON.stringify(r.spec.answers)}`)
    return
  } else {
    const { data: created, error: insErr } = await sb.from('tasks').insert(row).select('id').single()
    if (insErr) throw new Error(`tasks insert: ${insErr.message}`)
    taskId = created.id as string
    stats.created += 1
    console.log(`  ✓ angelegt: ${r.spec.titel} [afb ${row.afb}, unit ${row.unit ?? '—'}]`)
  }

  // task_solutions: bestehende Zeile NICHT ueberschreiben (Spec §4).
  const { data: sol, error: solErr } = await sb
    .from('task_solutions')
    .select('task_id')
    .eq('task_id', taskId)
    .maybeSingle()
  if (solErr) throw new Error(`task_solutions select: ${solErr.message}`)
  if (sol) {
    console.log(`      Loesung bereits gepflegt — nicht angefasst.`)
    return
  }
  if (!write) {
    console.log(`  + wuerde Loesung setzen: ${JSON.stringify(r.spec.answers)}`)
    return
  }
  // Schreibpfad in die Server-Only-Zone ist ausschliesslich die RPC.
  const { error: rpcErr } = await sb.rpc('task_solution_upsert', {
    p_task_id: taskId,
    p_correct_answers: r.spec.answers,
    p_solution: r.spec.answers[0],
  })
  if (rpcErr) throw new Error(`task_solution_upsert: ${rpcErr.message}`)
  stats.solutions += 1
  console.log(`      Loesung gesetzt: ${JSON.stringify(r.spec.answers)}`)
}

/** Spec §7 — inkl. der Gegenprobe, dass keine Loesung im Payload steckt. */
async function verify(sb: SupabaseClient) {
  const { data: tasks, error } = await sb
    .from('tasks')
    .select('id,status,input_type,question,unit,afb,title,question_payload,source')
  if (error) throw new Error(`verify tasks: ${error.message}`)
  const { count: solCount, error: solErr } = await sb
    .from('task_solutions')
    .select('*', { count: 'exact', head: true })
  if (solErr) throw new Error(`verify task_solutions: ${solErr.message}`)

  const byGroup = new Map<string, number>()
  for (const t of tasks ?? []) {
    const k = `${t.status} / ${t.input_type}`
    byGroup.set(k, (byGroup.get(k) ?? 0) + 1)
  }
  console.log('\n— Verifikation (Spec §7) —')
  for (const [k, n] of byGroup) console.log(`  tasks  ${k}: ${n}`)
  console.log(`  task_solutions: ${solCount}`)

  const leaky = (tasks ?? []).filter((t) => /correct|accepted|loesung|lösung/i.test(JSON.stringify(t.question_payload)))
  console.log(`  Loesung im question_payload: ${leaky.length}  ${leaky.length === 0 ? '(muss 0 sein ✓)' : '✗'}`)
  if (leaky.length) {
    for (const t of leaky) console.log(`    ✗ ${t.title}`)
    process.exitCode = 1
  }

  const mine = (tasks ?? []).filter((t) => t.source === SOURCE)
  console.log('\n— Importierte Items —')
  console.log('  Titel                      | AFB | unit  | Loesung')
  for (const t of mine.sort((a, b) => String(a.title).localeCompare(String(b.title)))) {
    const { data: s } = await sb.from('task_solutions').select('correct_answers').eq('task_id', t.id).maybeSingle()
    const answers = ((s?.correct_answers as string[]) ?? []).join(' | ')
    console.log(`  ${String(t.title).padEnd(26)} | ${String(t.afb).padEnd(3)} | ${(t.unit ?? '—').padEnd(5)} | ${answers}`)
  }
}

async function main() {
  const write = process.argv.includes('--write')
  const verifyOnly = process.argv.includes('--verify')

  const url = process.env.VITE_SUPABASE_URL
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY
  if (!url || !key) {
    console.error('VITE_SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY fehlen (.env).')
    process.exit(1)
  }
  const sb = createClient(url, key, { auth: { autoRefreshToken: false, persistSession: false } })

  if (verifyOnly) {
    await verify(sb)
    return
  }

  const all: SourceItem[] = JSON.parse(readFileSync(SOURCE_FILE, 'utf-8'))
  console.log(`Quelle:  ${SOURCE_FILE} (${all.length} Items)`)
  console.log(`Auswahl: ${ITEMS.length} manuell gesichtete Items (Spec §1 — keine Ausweitung)`)
  console.log(`Modus:   ${write ? 'WRITE' : 'DRY-RUN (schreibt nichts, --write zum Anwenden)'}\n`)

  const lk = await loadLookups(sb)
  const stats: Stats = { created: 0, existing: 0, solutions: 0, skipped: 0, errors: 0 }
  const blocked: string[] = []

  for (const spec of ITEMS) {
    if (spec.blocked) {
      stats.skipped += 1
      blocked.push(`${spec.titel} (${spec.prefix}): ${spec.blocked}`)
      console.log(`  ⏸ NICHT importiert: ${spec.titel} — ${spec.blocked}`)
      continue
    }
    try {
      await importItem(sb, resolve(spec, all), lk, write, stats)
    } catch (err) {
      stats.errors += 1
      const msg = err instanceof Error ? err.message : String(err)
      console.error(`  ✗ ${spec.titel} (${spec.prefix}): ${msg}`)
    }
  }

  console.log(
    `\nErgebnis: ${stats.created} ${write ? 'angelegt' : 'anzulegen'}, ${stats.existing} vorhanden, ` +
      `${stats.solutions} Loesungen gesetzt, ${stats.skipped} zurueckgehalten, ${stats.errors} Fehler`,
  )
  if (blocked.length) {
    console.log('\n⏸ Zurueckgehalten — brauchen eine Entscheidung, bevor sie in den Pool duerfen:')
    for (const b of blocked) console.log(`  - ${b}`)
  }
  if (stats.errors) process.exitCode = 1
  if (write && !stats.errors) await verify(sb)
}

main().catch((err) => {
  console.error(err)
  process.exit(1)
})
