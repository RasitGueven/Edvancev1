// Laedt die handgeprueften VERA-8-Abbildungen in den Storage-Bucket 'task-assets'
// und verknuepft sie mit den Tasks (tasks.assets).
//
// Nutzung:
//   npm run assets:upload                    # Dry-Run (Default, schreibt nichts)
//   npm run assets:upload -- --write         # laedt hoch + verknuepft
//   npm run assets:upload -- --cleanup       # loescht verwaiste Bucket-Objekte
//
// Idempotent: deterministischer Pfad vera8/<slug>.png. Ein zweiter Lauf laedt
// nicht erneut hoch und ueberschreibt kein bestehendes tasks.assets.
//
// WAS DIESES SCRIPT NICHT TUT: raten. Die Auswahl der Bilder steht in
// data/vera8_asset_selection.json und ist handgeprueft (von 34 PNGs sind nur 9
// eine Abbildung; der Rest ist Aufgabentext samt Antwortluecken). Weder
// manifest.typ noch lizenz_status taugen dafuer — siehe docs/LIZENZ-IQB.md.

import { readFileSync } from 'node:fs'
import { createClient, type SupabaseClient } from '@supabase/supabase-js'

const BUCKET = 'task-assets'
const SOURCE = 'VERA8_IQB'
const SELECTION = 'data/vera8_asset_selection.json'
const MANIFEST = 'data/vera8_assets_manifest.json'
const ITEMS = 'data/vera8_komplett_enriched.json'
const CROPPED = 'data/vera8_assets_cropped'

// Verwaiste Canva-Experimente (Task existiert nicht mehr). Nur mit --cleanup.
const ORPHAN_PREFIX = 'tasks/3f4ad68b-0788-475a-9799-4267d86d6351/'

type Selected = { slug: string; titel: string; alt: string; file: string }

/**
 * Rechte-Gate. Der eingebettete Lizenzhinweis pro Item (license-EMF) ist die
 * EINZIGE gueltige Quelle: Wortlaut mit "Grafik" = Grafik gedeckt, ohne =
 * fremd und nicht verwendbar. Das Feld lizenz_status im Item-JSON ist pauschal
 * und fuer Grafiken nachweislich falsch (docs/LIZENZ-IQB.md §2).
 *
 * Fail closed: fehlt der Lizenzhinweis, gilt die Grafik als ungeklaert.
 */
function grafikIsLicensed(slug: string, manifest: Record<string, { medien: { typ: string; pfad: string }[] }>) {
  const lic = manifest[slug]?.medien.find((m) => m.typ === 'license')
  if (!lic) return false
  const text = readFileSync(`data/${lic.pfad}`).toString('utf16le')
  return text.includes('Grafik')
}

/** Nur figure_stem + essenziell, ohne HALT-Vermerk. Alles andere ist kein Bild. */
function selectAssets(): Selected[] {
  const sel = JSON.parse(readFileSync(SELECTION, 'utf8'))
  const manifest = JSON.parse(readFileSync(MANIFEST, 'utf8'))
  const out: Selected[] = []

  for (const item of sel.items) {
    if (item.status === 'HALT') {
      console.log(`  ⊘ ${item.titel}: HALT (${item.assets[0]?.hinweis ?? 'siehe Auswahl'})`)
      continue
    }
    const fig = item.assets.find((a: { klasse: string; essenziell?: boolean }) => a.klasse === 'figure_stem' && a.essenziell)
    if (!fig) continue

    if (!grafikIsLicensed(item.slug, manifest)) {
      console.log(`  ⊘ ${item.titel}: Lizenzhinweis deckt die Grafik NICHT — uebersprungen`)
      continue
    }
    out.push({ slug: item.slug, titel: item.titel, alt: fig.alt, file: `${CROPPED}/${item.slug}.png` })
  }
  return out
}

/** slug -> tasks.source_ref (die Item-UUID aus dem Quell-JSON). */
function sourceRefByTitle(): Map<string, string> {
  const raw = JSON.parse(readFileSync(ITEMS, 'utf8'))
  const items: { id: string; titel: string }[] = Array.isArray(raw) ? raw : Object.values(raw)
  return new Map(items.map((i) => [i.titel, i.id]))
}

async function existingObjects(sb: SupabaseClient, prefix: string) {
  const { data, error } = await sb.storage.from(BUCKET).list(prefix, { limit: 1000 })
  if (error) throw new Error(`storage list "${prefix}": ${error.message}`)
  return new Set((data ?? []).map((o) => o.name))
}

async function cleanupOrphans(sb: SupabaseClient, write: boolean) {
  const objs = await existingObjects(sb, ORPHAN_PREFIX.replace(/\/$/, ''))
  if (objs.size === 0) {
    console.log('Keine verwaisten Objekte.')
    return
  }
  const paths = [...objs].map((n) => ORPHAN_PREFIX + n)
  console.log(`Verwaiste Objekte (Task existiert nicht): ${paths.length}`)
  paths.forEach((p) => console.log(`  - ${p}`))
  if (!write) {
    console.log('  (Dry-Run — mit --write --cleanup wirklich loeschen)')
    return
  }
  const { error } = await sb.storage.from(BUCKET).remove(paths)
  if (error) throw new Error(`storage remove: ${error.message}`)
  console.log(`  ✓ ${paths.length} geloescht`)
}

async function uploadAndLink(sb: SupabaseClient, write: boolean) {
  const selected = selectAssets()
  const refs = sourceRefByTitle()
  const present = await existingObjects(sb, 'vera8')

  console.log(`\n${selected.length} Abbildung(en) freigegeben.\n`)
  let uploaded = 0
  let skipped = 0
  let linked = 0
  let unimported = 0

  for (const a of selected) {
    const objectName = `${a.slug}.png`
    const path = `vera8/${objectName}`
    const url = `${process.env.VITE_SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${path}`

    if (present.has(objectName)) {
      console.log(`  = ${a.titel}: liegt schon im Bucket (${path})`)
      skipped += 1
    } else if (!write) {
      console.log(`  + ${a.titel}: wuerde hochladen -> ${path}`)
      uploaded += 1
    } else {
      const body = readFileSync(a.file)
      const { error } = await sb.storage.from(BUCKET).upload(path, body, {
        contentType: 'image/png',
        upsert: false,
      })
      if (error) throw new Error(`upload ${path}: ${error.message}`)
      console.log(`  + ${a.titel}: hochgeladen -> ${path}`)
      uploaded += 1
    }

    // Verknuepfung. Die Items sind zum Teil noch nicht importiert — dann gibt es
    // nichts zu verknuepfen, und das ist kein Fehler, sondern eine Meldung.
    const sourceRef = refs.get(a.titel)
    if (!sourceRef) {
      console.log(`     ! kein source_ref fuer "${a.titel}" im Quell-JSON`)
      continue
    }
    const { data: task, error: selErr } = await sb
      .from('tasks')
      .select('id, assets')
      .eq('source', SOURCE)
      .eq('source_ref', sourceRef)
      .maybeSingle()
    if (selErr) throw new Error(`tasks select: ${selErr.message}`)

    if (!task) {
      console.log(`     · Task noch nicht importiert — Verknuepfung offen`)
      unimported += 1
      continue
    }
    if (Array.isArray(task.assets) && task.assets.length > 0) {
      console.log(`     = tasks.assets bereits gesetzt — unveraendert`)
      continue
    }
    if (!write) {
      console.log(`     → wuerde tasks.assets setzen`)
      linked += 1
      continue
    }
    const { error: updErr } = await sb
      .from('tasks')
      .update({ assets: [{ url, alt: a.alt }] })
      .eq('id', task.id)
    if (updErr) throw new Error(`tasks update: ${updErr.message}`)
    console.log(`     ✓ tasks.assets gesetzt`)
    linked += 1
  }

  console.log(
    `\nHochgeladen: ${uploaded}  schon vorhanden: ${skipped}  verknuepft: ${linked}  noch nicht importiert: ${unimported}`,
  )
  if (unimported > 0) {
    console.log(
      `\nHinweis: ${unimported} Item(s) liegen im Bucket, aber es gibt noch keinen Task dazu.\n` +
        `Die Verknuepfung passiert beim Import (tasks.assets) — dieses Script erneut laufen lassen,\n` +
        `sobald die Items importiert sind. Es ist idempotent.`,
    )
  }
}

async function main() {
  const write = process.argv.includes('--write')
  const cleanup = process.argv.includes('--cleanup')

  const url = process.env.VITE_SUPABASE_URL
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY
  if (!url || !key) {
    console.error('VITE_SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY fehlen (.env).')
    process.exit(1)
  }
  const sb = createClient(url, key, { auth: { autoRefreshToken: false, persistSession: false } })

  console.log(write ? '=== SCHREIBLAUF ===' : '=== DRY-RUN (nichts wird geschrieben) ===')
  if (cleanup) await cleanupOrphans(sb, write)
  else await uploadAndLink(sb, write)
}

main().catch((e) => {
  console.error(e instanceof Error ? e.message : e)
  process.exit(1)
})
