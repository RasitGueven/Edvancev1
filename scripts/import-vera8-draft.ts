// C08 — Import der Neuextraktion als DRAFT ins Autoren-Tool.
//
//   data/vera8_v2.json (299 Items)  →  tasks (status='draft') + task_solutions
//
// Nutzung:
//   npm run import:vera8-draft             # Dry-Run (Default, schreibt nichts)
//   npm run import:vera8-draft -- --write  # schreibt
//   npm run import:vera8-draft -- --verify # nur Kontrolle gegen die DB
//
// WARUM ALLE 299 und nicht nur die pool-faehigen: das Autoren-Tool ist genau dafuer
// da, unfertige Items zu pflegen. Ein Item mit fehlender Loesung gehoert ins Tool,
// nicht in eine JSON-Datei, die niemand oeffnet. Der Rest ist Arbeitsvorrat.
//
// KEIN Item wird 'ready'. Die Freigabe laeuft ausschliesslich ueber task_status_set
// — durch einen Menschen, mit Stempel (A01).
//
// IDEMPOTENZ: Match ueber (source, source_ref). Ein vorhandenes Item wird NICHT
// angefasst — weder Zeile noch Loesung. Damit ueberschreibt ein zweiter Lauf keine
// Handarbeit, und die 14 bereits importierten (status='ready') bleiben, wie sie sind.

import { readFileSync, writeFileSync } from 'node:fs'
import { createClient, type SupabaseClient } from '@supabase/supabase-js'
import { buildItem, CLUSTER_BY_INHALTSFELD, type Built, type V2Item } from './content/vera8Draft'

const SOURCE_FILE = 'data/vera8_v2.json'
const REPORT_FILE = 'data/c08_import_report.json'
const SOURCE = 'VERA8_IQB'

type Lookups = {
  clusterIdByName: Map<string, string>
  competencyByCode: Map<string, { id: string; name: string }>
}

async function loadLookups(sb: SupabaseClient): Promise<Lookups> {
  const { data: subject, error: subErr } = await sb
    .from('subjects')
    .select('id')
    .eq('name', 'Mathematik')
    .maybeSingle()
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

/** Die fertige tasks-Zeile. curriculum_grade fehlt bewusst — Handarbeit (A01). */
function taskRow(b: Built, lk: Lookups): Record<string, unknown> {
  const comps = b.processCodes.map((code) => lk.competencyByCode.get(code)).filter(Boolean) as {
    id: string
    name: string
  }[]
  const clusterName = b.inhaltsfeld ? CLUSTER_BY_INHALTSFELD[b.inhaltsfeld] : null
  return {
    ...b.row,
    source: SOURCE,
    cluster_id: clusterName ? (lk.clusterIdByName.get(clusterName) ?? null) : null,
    // Bei Multi-Part traegt die Teilaufgabe die Kompetenz (P02) — am Item waere sie
    // eine zweite, konkurrierende Wahrheit.
    competency_process: b.row.input_type === 'MULTI_PART' ? null : comps.map((c) => c.name).join(', ') || null,
    competency_id: b.row.input_type !== 'MULTI_PART' && comps.length === 1 ? comps[0].id : null,
  }
}

type Stats = {
  created: number
  existing: number
  solutions: number
  errors: number
}

async function importOne(
  sb: SupabaseClient,
  b: Built,
  lk: Lookups,
  write: boolean,
  stats: Stats,
): Promise<'created' | 'existing'> {
  const { data: existing, error: selErr } = await sb
    .from('tasks')
    .select('id,status')
    .eq('source', SOURCE)
    .eq('source_ref', b.sourceRef)
    .maybeSingle()
  if (selErr) throw new Error(`tasks select: ${selErr.message}`)

  if (existing) {
    // Nicht anfassen. Weder die 14 auf 'ready' noch ein Item, das jemand im Tool
    // schon bearbeitet hat. Der Import ist eine Erstbefuellung, kein Sync.
    stats.existing += 1
    return 'existing'
  }

  if (!write) {
    stats.created += 1
    if (b.answers || b.belege.length) stats.solutions += 1
    return 'created'
  }

  const { data: created, error: insErr } = await sb.from('tasks').insert(taskRow(b, lk)).select('id').single()
  if (insErr) throw new Error(`tasks insert: ${insErr.message}`)
  const taskId = created.id as string
  stats.created += 1

  // Loesung ausschliesslich ueber die RPC — task_solutions hat bewusst kein Grant.
  //
  // p_solution wird NICHT mitgeschickt: seit B01 traegt `solution` den didaktischen
  // Loesungsweg (Handarbeit), und der Beleg hat mit `beleg` sein eigenes Feld. Die
  // RPC patcht pro Feld — ein Parameter, der fehlt, bleibt unveraendert. Der Import
  // kann einen von Hand geschriebenen Loesungsweg also nicht mehr ueberschreiben.
  if (b.answers || b.belege.length) {
    const { error: rpcErr } = await sb.rpc('task_solution_upsert', {
      p_task_id: taskId,
      p_correct_answers: b.answers ?? [],
      p_beleg: b.belege,
    })
    if (rpcErr) throw new Error(`task_solution_upsert: ${rpcErr.message}`)
    stats.solutions += 1
  }
  return 'created'
}

async function verify(sb: SupabaseClient): Promise<void> {
  const { data: rows, error } = await sb
    .from('tasks')
    .select('id,status,input_type,question_payload,curriculum_grade')
    .eq('source', SOURCE)
  if (error) throw new Error(`verify: ${error.message}`)
  const byStatus = new Map<string, number>()
  for (const r of rows ?? []) byStatus.set(r.status as string, (byStatus.get(r.status as string) ?? 0) + 1)

  console.log('\n— Kontrolle —')
  for (const [s, n] of byStatus) console.log(`  status=${s}: ${n}`)
  const leaky = (rows ?? []).filter((r) =>
    /"(correct|accepted|pairs|blanks|expected)"/.test(JSON.stringify(r.question_payload ?? {})),
  )
  console.log(`  Loesung im question_payload: ${leaky.length} (muss 0 sein)`)
  const withGrade = (rows ?? []).filter((r) => r.curriculum_grade != null).length
  console.log(`  mit Stoffanker (Handarbeit): ${withGrade}`)
  if (leaky.length) process.exitCode = 1
}

async function main(): Promise<void> {
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

  const items = JSON.parse(readFileSync(SOURCE_FILE, 'utf8')) as V2Item[]
  const built = items.map(buildItem)
  console.log(`Quelle: ${SOURCE_FILE} (${items.length} Items, alle status='draft')`)
  console.log(`Modus:  ${write ? 'WRITE' : 'DRY-RUN (schreibt nichts, --write zum Anwenden)'}\n`)

  const lk = await loadLookups(sb)
  const stats: Stats = { created: 0, existing: 0, solutions: 0, errors: 0 }
  const skipped: string[] = []
  const failed: { item: string; error: string }[] = []

  for (const b of built) {
    try {
      const outcome = await importOne(sb, b, lk, write, stats)
      if (outcome === 'existing') skipped.push(b.titel)
    } catch (err) {
      stats.errors += 1
      const msg = err instanceof Error ? err.message : String(err)
      failed.push({ item: b.titel, error: msg })
      console.error(`  ✗ ${b.titel}: ${msg}`)
    }
  }

  // Der Bericht: was drin ist, was fehlt, was nach der Pflege pool-faehig waere.
  const flagCounts = new Map<string, number>()
  for (const b of built) {
    for (const f of b.importFlags) {
      const key = f.split('—')[0].trim()
      flagCounts.set(key, (flagCounts.get(key) ?? 0) + 1)
    }
  }
  const poolReady = built.filter((b) => b.poolReadyAfterCare)

  // Der Bestand, nicht nur die Differenz dieses Laufs: ein zweiter Lauf legt nichts
  // an, und ein Bericht mit "0 angelegt" ohne Bestand liest sich wie ein Fehlschlag.
  const { data: bestandRows } = await sb.from('tasks').select('status').eq('source', SOURCE)
  const bestand: Record<string, number> = {}
  for (const r of bestandRows ?? []) bestand[r.status as string] = (bestand[r.status as string] ?? 0) + 1

  const report = {
    quelle: SOURCE_FILE,
    modus: write ? 'write' : 'dry-run',
    bestand_in_db: bestand,
    items_gesamt: items.length,
    angelegt: stats.created,
    uebersprungen_vorhanden: stats.existing,
    loesungen_gesetzt: stats.solutions,
    fehler: failed,
    nach_pflege_pool_faehig: poolReady.length,
    nach_pflege_pool_faehig_items: poolReady.map((b) => b.titel).sort(),
    typen: [...new Set(built.map((b) => b.row.input_type ?? 'null'))].map((t) => ({
      input_type: t,
      n: built.filter((b) => (b.row.input_type ?? 'null') === t).length,
    })),
    import_flags: [...flagCounts.entries()].sort((a, b) => b[1] - a[1]).map(([flag, n]) => ({ flag, n })),
    items_mit_extraktions_flags: built.filter((b) => b.importFlags.length).length,
    assets_uebernommen: built.reduce((n, b) => n + b.row.assets.length, 0),
  }
  writeFileSync(REPORT_FILE, JSON.stringify(report, null, 2), 'utf8')

  console.log(`\n— Ergebnis —`)
  console.log(`  ${stats.created} ${write ? 'angelegt' : 'anzulegen'}`)
  console.log(`  ${stats.existing} uebersprungen (bereits vorhanden — nicht angefasst)`)
  console.log(`  ${stats.solutions} Loesungen ${write ? 'gesetzt' : 'zu setzen'} (via task_solution_upsert)`)
  console.log(`  ${stats.errors} Fehler`)
  console.log(`\n  Typen: ${report.typen.map((t) => `${t.input_type}=${t.n}`).join(', ')}`)
  console.log(`  Nach Pflege pool-faehig: ${poolReady.length} (es fehlt nur noch Handarbeit: Stoffanker, Alt-Texte)`)
  console.log(`\n— Import-Flags —`)
  for (const { flag, n } of report.import_flags) console.log(`  ${String(n).padStart(3)}× ${flag}`)
  console.log(`\nBericht: ${REPORT_FILE}`)

  if (skipped.length) console.log(`\nUebersprungen: ${skipped.join(', ')}`)
  if (stats.errors) process.exitCode = 1
  if (write && !stats.errors) await verify(sb)
}

main().catch((err) => {
  console.error(err)
  process.exit(1)
})
