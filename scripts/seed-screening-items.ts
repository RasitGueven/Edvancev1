// Seedet Screening-Item-Entwürfe (active=false) idempotent in die DB.
// Quelle = versionierte Daten-Files unter scripts/screening-items/*.
// Review/Freigabe danach via /admin/screening-items.
//
// Nutzung:
//   npm run seed:screening-items            (Dry-Run, zeigt nur was passieren würde)
//   npm run seed:screening-items -- --write (schreibt wirklich)
//
// Voraussetzung: Migration 022 ausgeführt; ENV SUPABASE_URL +
// SUPABASE_SERVICE_ROLE_KEY (service-role; umgeht RLS für den Seed).
//
// Idempotenz: pro (skill_code, level) → vorhanden? update (active bleibt
// unverändert!) sonst insert mit active=false.

import { createClient } from '@supabase/supabase-js'
import { ZAHL_RECHNEN_ITEMS, type SeedItem } from './screening-items/zahl-rechnen'
import { ALGEBRA_FUNKTIONEN_ITEMS } from './screening-items/algebra-funktionen'
import { GEOMETRIE_MESSEN_ITEMS } from './screening-items/geometrie-messen'
import { DATEN_ZUFALL_ITEMS } from './screening-items/daten-zufall'
import { SACHRECHNEN_MODELLIEREN_ITEMS } from './screening-items/sachrechnen-modellieren'

const ALL_ITEMS: SeedItem[] = [
  ...ZAHL_RECHNEN_ITEMS,
  ...ALGEBRA_FUNKTIONEN_ITEMS,
  ...GEOMETRIE_MESSEN_ITEMS,
  ...DATEN_ZUFALL_ITEMS,
  ...SACHRECHNEN_MODELLIEREN_ITEMS,
]

async function main(): Promise<void> {
  const write = process.argv.includes('--write')
  const url = process.env.SUPABASE_URL ?? process.env.VITE_SUPABASE_URL
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY
  if (!url || !key) {
    console.error('Fehlende ENV-Vars: SUPABASE_URL und SUPABASE_SERVICE_ROLE_KEY')
    process.exit(1)
  }
  const supabase = createClient(url, key, {
    auth: { autoRefreshToken: false, persistSession: false },
  })

  // Cluster-Namen → cluster_id (Fach Mathematik) auflösen
  const { data: subj } = await supabase
    .from('subjects')
    .select('id')
    .eq('name', 'Mathematik')
    .maybeSingle()
  if (!subj) {
    console.error('Fach "Mathematik" nicht gefunden – seed:taxonomy/clusters laufen lassen.')
    process.exit(1)
  }
  const { data: clusters, error: cErr } = await supabase
    .from('skill_clusters')
    .select('id, name')
    .eq('subject_id', subj.id)
  if (cErr || !clusters) {
    console.error('Cluster konnten nicht geladen werden:', cErr?.message)
    process.exit(1)
  }
  const clusterIdByName = new Map(
    clusters.map((c: { id: string; name: string }) => [c.name, c.id]),
  )

  let ins = 0
  let upd = 0
  let skip = 0
  const missingClusters = new Set<string>()

  for (const it of ALL_ITEMS) {
    const clusterId = clusterIdByName.get(it.cluster_name)
    if (!clusterId) {
      missingClusters.add(it.cluster_name)
      skip += 1
      continue
    }
    const { data: existing } = await supabase
      .from('screening_items')
      .select('id')
      .eq('skill_code', it.skill_code)
      .eq('level', it.level)
      .maybeSingle()

    const row = {
      cluster_id: clusterId,
      class_level: it.class_level,
      topic: it.topic,
      skill_code: it.skill_code,
      skill_label: it.skill_label,
      level: it.level,
      curriculum_seq: it.curriculum_seq,
      input_type: it.input_type,
      prompt: it.prompt,
      payload: it.payload,
      canonical: it.canonical,
      check_type: it.check_type,
      tolerance: it.tolerance,
      typical_errors: it.typical_errors,
      explanation: it.explanation,
      source: 'edvance_original',
    }

    if (existing) {
      console.log(`~ update ${it.skill_code} L${it.level}`)
      if (write) {
        await supabase.from('screening_items').update(row).eq('id', existing.id)
      }
      upd += 1
    } else {
      console.log(`+ insert ${it.skill_code} L${it.level} (active=false)`)
      if (write) {
        await supabase
          .from('screening_items')
          .insert({ ...row, active: false })
      }
      ins += 1
    }
  }

  if (missingClusters.size > 0) {
    console.warn('Cluster nicht gefunden (übersprungen):', [...missingClusters].join(', '))
  }
  console.log(
    `\n${write ? 'GESCHRIEBEN' : 'DRY-RUN'} — insert:${ins} update:${upd} skip:${skip} / total:${ALL_ITEMS.length}`,
  )
  if (!write) console.log('Mit -- --write tatsächlich anwenden.')
}

void main()
