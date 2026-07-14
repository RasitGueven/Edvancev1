// Laedt die Abbildungen der pool-faehigen Items in den Bucket 'task-assets' und
// schreibt tasks.assets[].url von lokalen Dateipfaden auf oeffentliche URLs um.
//
// Nutzung:
//   npm run assets:upload                 # Dry-Run (Default, schreibt nichts)
//   npm run assets:upload -- --write      # laedt hoch + schreibt die URLs um
//
// WARUM DIESES SCRIPT EXISTIERT: C08 hat die Abbildungen als Verweis in
// tasks.assets gesetzt — aber als lokalen Dateipfad ("data/r01_render/<slug>/
// <datei>.png"). Der Browser kann den nicht aufloesen, im Autoren-Tool ist jedes
// Bild kaputt. Hier wird die Datei hochgeladen und der Verweis auf die Public URL
// gezogen. Der Bucket ist public (storage.buckets.public = true), es wird also
// nicht signiert.
//
// UMFANG: nur Items, die pool-faehig sind oder es nach Pflege werden koennen
// (poolReadyAfterCare aus scripts/content/vera8Draft.ts — dieselbe Definition,
// die C08 fuer seinen Bericht benutzt; hier wird sie NICHT zweitdefiniert).
// Items ohne Chance auf den Pool (FREE_TEXT, ohne Loesung, ohne Inhaltsfeld)
// bleiben ohne Bild — ihre Abbildungen liegen weiter nur lokal.
//
// LIZENZ (hart, fail closed): hochgeladen wird eine Abbildung nur, wenn der pro
// Item eingebettete Lizenzhinweis das Wort "Grafik" traegt (docs/LIZENZ-IQB.md).
// Das wird hier gegen die Quelle NEU geprueft, nicht dem DB-Stand geglaubt: eine
// URL, zu der sich in vera8_v2.json kein gedecktes Asset finden laesst, wird
// uebersprungen. Das pauschale Feld lizenz_status ist fuer Grafiken falsch und
// wird nirgends herangezogen.
//
// ALT-TEXTE: bleiben, wie sie sind (C08 hat sie leer gelassen). Ein Alt-Text ist
// Handarbeit im Autoren-Tool und blockiert die Freigabe — dieses Script erfindet
// keinen.
//
// IDEMPOTENZ: deterministischer Pfad lsa/<slug>/<datei>.png. Ein zweiter Lauf
// findet das Objekt im Bucket und laedt nicht erneut hoch; eine URL, die schon
// oeffentlich ist, wird nicht angefasst.

import { readFileSync, writeFileSync } from 'node:fs'
import { createClient, type SupabaseClient } from '@supabase/supabase-js'
import { buildItem, coveredAssets, type V2Item } from './content/vera8Draft'

const BUCKET = 'task-assets'
const SOURCE = 'VERA8_IQB'
const SOURCE_FILE = 'data/vera8_v2.json'
const REPORT_FILE = 'data/c09_assets_report.json'
const PREFIX = 'lsa'

type Planned = {
  titel: string
  taskId: string
  status: string
  /** Index in tasks.assets — die Reihenfolge bleibt erhalten. */
  idx: number
  localPath: string
  objectPath: string
  publicUrl: string
}

/** data/r01_render/<slug>/<datei>.png  →  lsa/<slug>/<datei>.png */
function objectPathFor(localPath: string): string | null {
  const m = /^data\/r01_render\/([^/]+)\/([^/]+)$/.exec(localPath)
  if (!m) return null
  return `${PREFIX}/${m[1]}/${m[2]}`
}

function publicUrlFor(objectPath: string, baseUrl: string): string {
  const encoded = objectPath.split('/').map(encodeURIComponent).join('/')
  return `${baseUrl}/storage/v1/object/public/${BUCKET}/${encoded}`
}

/** Objekte unter lsa/<slug>/ — pro Item ein list()-Aufruf, danach gecached. */
async function objectsIn(sb: SupabaseClient, folder: string, cache: Map<string, Set<string>>) {
  const hit = cache.get(folder)
  if (hit) return hit
  const { data, error } = await sb.storage.from(BUCKET).list(folder, { limit: 1000 })
  if (error) throw new Error(`storage list "${folder}": ${error.message}`)
  const names = new Set((data ?? []).map((o) => o.name))
  cache.set(folder, names)
  return names
}

async function main(): Promise<void> {
  const write = process.argv.includes('--write')

  const baseUrl = process.env.VITE_SUPABASE_URL
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY
  if (!baseUrl || !key) {
    console.error('VITE_SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY fehlen (.env).')
    process.exit(1)
  }
  const sb = createClient(baseUrl, key, { auth: { autoRefreshToken: false, persistSession: false } })

  // Der Bucket muss public sein — sonst laufen die URLs, die wir schreiben, ins Leere.
  const { data: buckets, error: bErr } = await sb.storage.listBuckets()
  if (bErr) throw new Error(`listBuckets: ${bErr.message}`)
  const bucket = buckets.find((b) => b.name === BUCKET)
  if (!bucket) throw new Error(`Bucket "${BUCKET}" existiert nicht.`)
  if (!bucket.public) {
    throw new Error(`Bucket "${BUCKET}" ist privat. Public URLs waeren tot — abgebrochen (kein Bucket-Umbau in diesem Script).`)
  }

  console.log(write ? '=== SCHREIBLAUF ===' : '=== DRY-RUN (nichts wird geschrieben) ===')

  // 1. Die Pool-Menge: aus dem Bestand gerechnet, nicht aus einer Zahl im Kopf.
  const items = JSON.parse(readFileSync(SOURCE_FILE, 'utf8')) as V2Item[]
  const built = items.map(buildItem)
  const pool = built.filter((b) => b.poolReadyAfterCare)
  const itemBySourceRef = new Map(items.map((i) => [i.id, i]))

  // 2. Die Tasks dazu.
  const { data: rows, error: tErr } = await sb.from('tasks').select('id,title,status,source_ref,assets').eq('source', SOURCE)
  if (tErr) throw new Error(`tasks select: ${tErr.message}`)
  const taskBySourceRef = new Map((rows ?? []).map((r) => [r.source_ref as string, r]))

  // 3. Der Plan — Bild fuer Bild, mit Lizenzpruefung gegen die Quelle.
  const plan: Planned[] = []
  const skippedLicense: { titel: string; datei: string }[] = []
  const alreadyPublic: string[] = []
  const unresolved: { titel: string; url: string }[] = []
  const missingLink: { titel: string; status: string; bilder: number }[] = []

  for (const b of pool) {
    const task = taskBySourceRef.get(b.sourceRef)
    if (!task) continue
    const assets = (task.assets as { url?: string; alt?: string }[] | null) ?? []

    // Ein Pool-Item, dessen Zeile gar kein Asset traegt, obwohl die Quelle eine
    // gedeckte Abbildung kennt: das ist keine kaputte URL, sondern eine fehlende
    // Verknuepfung an einem (teils schon freigegebenen) Item. Nicht still nachziehen
    // — melden, ein Mensch entscheidet.
    if (assets.length === 0 && b.row.assets.length > 0) {
      missingLink.push({ titel: b.titel, status: task.status as string, bilder: b.row.assets.length })
      continue
    }

    const src = itemBySourceRef.get(b.sourceRef)
    const covered = new Set(coveredAssets(src?.assets ?? []).kept.map((a) => a.verweis))

    assets.forEach((a, idx) => {
      const url = a.url ?? ''
      if (url.startsWith('http')) {
        alreadyPublic.push(url)
        return
      }
      // Lizenz-Gate, unabhaengig vom DB-Stand: nur was die Quelle als gedeckt
      // ausweist, geht in den Bucket. Fail closed.
      if (!covered.has(url)) {
        skippedLicense.push({ titel: b.titel, datei: url })
        return
      }
      const objectPath = objectPathFor(url)
      if (!objectPath) {
        unresolved.push({ titel: b.titel, url })
        return
      }
      plan.push({
        titel: b.titel,
        taskId: task.id as string,
        status: task.status as string,
        idx,
        localPath: url,
        objectPath,
        publicUrl: publicUrlFor(objectPath, baseUrl),
      })
    })
  }

  const itemsInPlan = new Set(plan.map((p) => p.taskId))
  console.log(`\nPool-faehig (poolReadyAfterCare): ${pool.length} Items`)
  console.log(`Davon mit Abbildung: ${itemsInPlan.size} Items, ${plan.length} Bilder\n`)

  // 4. Hochladen + URL umschreiben. Pro Task ein Update, damit die Reihenfolge
  //    in tasks.assets erhalten bleibt.
  const folderCache = new Map<string, Set<string>>()
  let uploaded = 0
  let present = 0
  let rewritten = 0

  const byTask = new Map<string, Planned[]>()
  for (const p of plan) {
    const list = byTask.get(p.taskId) ?? []
    list.push(p)
    byTask.set(p.taskId, list)
  }

  for (const [taskId, planned] of byTask) {
    for (const p of planned) {
      const folder = p.objectPath.slice(0, p.objectPath.lastIndexOf('/'))
      const name = p.objectPath.slice(p.objectPath.lastIndexOf('/') + 1)
      const existing = await objectsIn(sb, folder, folderCache)

      if (existing.has(name)) {
        present += 1
      } else if (!write) {
        uploaded += 1
      } else {
        const body = readFileSync(p.localPath)
        const { error } = await sb.storage.from(BUCKET).upload(p.objectPath, body, {
          contentType: 'image/png',
          upsert: false,
        })
        if (error) throw new Error(`upload ${p.objectPath}: ${error.message}`)
        existing.add(name)
        uploaded += 1
      }
    }

    // Die Zeile neu schreiben: nur die url, alt bleibt unangetastet.
    const task = (rows ?? []).find((r) => r.id === taskId)!
    const assets = (task.assets as { url?: string; alt?: string }[]).map((a, idx) => {
      const p = planned.find((x) => x.idx === idx)
      return p ? { ...a, url: p.publicUrl } : a
    })
    if (write) {
      const { error } = await sb.from('tasks').update({ assets }).eq('id', taskId)
      if (error) throw new Error(`tasks update ${taskId}: ${error.message}`)
    }
    rewritten += planned.length
    const t = planned[0]
    console.log(`  ${write ? '✓' : '→'} ${t.titel} [${t.status}]: ${planned.length} Bild(er) → ${PREFIX}/…`)
  }

  // 5. Was die Lizenz kostet — im Pool-Umfang, nicht im Gesamtbestand.
  let licenseDroppedImages = 0
  const licenseDroppedItems = new Set<string>()
  for (const b of pool) {
    const src = itemBySourceRef.get(b.sourceRef)
    const { dropped } = coveredAssets(src?.assets ?? [])
    const withFile = dropped.filter((a) => (a.verweis ?? '').trim() !== '')
    if (withFile.length) {
      licenseDroppedImages += withFile.length
      licenseDroppedItems.add(b.titel)
    }
  }

  const report = {
    modus: write ? 'write' : 'dry-run',
    bucket: BUCKET,
    bucket_public: bucket.public,
    pool_faehige_items: pool.length,
    items_mit_abbildung: itemsInPlan.size,
    bilder_geplant: plan.length,
    hochgeladen: uploaded,
    schon_im_bucket: present,
    urls_umgeschrieben: rewritten,
    schon_public: alreadyPublic.length,
    lizenz_uebersprungen_bilder: licenseDroppedImages,
    lizenz_uebersprungen_items: [...licenseDroppedItems].sort(),
    nicht_aufloesbare_pfade: unresolved,
    fehlende_verknuepfung: missingLink,
  }
  writeFileSync(REPORT_FILE, JSON.stringify(report, null, 2), 'utf8')

  console.log(`\n— Ergebnis —`)
  console.log(`  ${uploaded} Bild(er) ${write ? 'hochgeladen' : 'hochzuladen'}`)
  console.log(`  ${present} schon im Bucket (nicht erneut geladen)`)
  console.log(`  ${rewritten} URL(s) ${write ? 'umgeschrieben' : 'umzuschreiben'} auf Public URL`)
  console.log(`  ${itemsInPlan.size} Item(s) mit Bild, aus ${pool.length} pool-faehigen`)
  console.log(`\n— Lizenz (docs/LIZENZ-IQB.md) —`)
  console.log(`  ${licenseDroppedImages} Abbildung(en) in ${licenseDroppedItems.size} Pool-Item(s) NICHT gedeckt → nicht hochgeladen`)
  if (skippedLicense.length) console.log(`  ${skippedLicense.length} DB-Verweis(e) ohne Deckung in der Quelle → uebersprungen`)
  if (unresolved.length) {
    console.log(`\n  ! ${unresolved.length} Pfad(e) passen nicht auf data/r01_render/<slug>/<datei> — nicht angefasst:`)
    unresolved.forEach((u) => console.log(`      ${u.titel}: ${u.url}`))
  }
  if (missingLink.length) {
    console.log(`\n  ! ${missingLink.length} Pool-Item(s) ohne Asset in der Zeile, obwohl die Quelle eine gedeckte Abbildung kennt.`)
    console.log(`    Das ist eine fehlende Verknuepfung, keine kaputte URL — Handarbeit, dieses Script fasst sie nicht an:`)
    missingLink.forEach((m) => console.log(`      ${m.titel} [${m.status}]: ${m.bilder} Bild(er) in der Quelle`))
  }
  console.log(`\nBericht: ${REPORT_FILE}`)
  if (!write) console.log('\n(Dry-Run — mit `npm run assets:upload -- --write` anwenden)')
}

main().catch((err) => {
  console.error(err instanceof Error ? err.message : err)
  process.exit(1)
})
