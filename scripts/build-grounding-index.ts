// Baut den Quellenbeleg-Index fuer das Autoren-Tool.
//
//   data/vera8_komplett_enriched.json  (1,5 MB, 299 Items, die volle Extraktion)
//        ↓  nur die Belege, keine abgeleiteten Felder
//   public/authoring/grounding-vera8.json  (~700 KB, nach `source_ref` gekeyt)
//
// WARUM nicht direkt die grosse Datei importieren: ein `import` wuerde sie in das
// Admin-Bundle backen — 1,5 MB, die jede Admin-Seite mitschleppt. Der Index liegt
// in public/ und wird erst geladen, wenn jemand ein Item mit VERA-Quelle oeffnet
// (src/lib/authoring/grounding.ts).
//
// WARUM ueberhaupt eine Datei und keine DB-Spalte: der Beleg ist Read-Only-
// Kontext fuer den Pfleger ("worauf stuetze ich mich?"), kein Produktivdatum.
// Er gehoert nicht in `tasks` — er gehoert neben den Editor.
//
// Der Join laeuft ueber tasks.source_ref = <id aus dem JSON> (so schreibt es
// scripts/import-lsa-items.ts).
//
// Nutzung:  npx tsx scripts/build-grounding-index.ts

import { mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { dirname } from 'node:path'

const SOURCE = 'data/vera8_komplett_enriched.json'
const TARGET = 'public/authoring/grounding-vera8.json'

type RawItem = {
  id: string
  titel?: string
  quelle?: string
  lizenz_status?: string
  iqb_urls?: Record<string, string>
  aufgabe_text?: string
  _problems?: string[]
  _grounding?: unknown
}

const raw = JSON.parse(readFileSync(SOURCE, 'utf8')) as RawItem[]

const index: Record<string, unknown> = {}
let withGrounding = 0

for (const item of raw) {
  if (!item.id) continue
  if (item._grounding) withGrounding++
  index[item.id] = {
    id: item.id,
    titel: item.titel,
    quelle: item.quelle,
    lizenz_status: item.lizenz_status,
    iqb_urls: item.iqb_urls,
    aufgabe_text: item.aufgabe_text,
    problems: item._problems?.length ? item._problems : undefined,
    grounding: item._grounding,
  }
}

mkdirSync(dirname(TARGET), { recursive: true })
writeFileSync(TARGET, JSON.stringify(index), 'utf8')

const kb = Math.round(Buffer.byteLength(JSON.stringify(index)) / 1024)
console.log(`${TARGET}: ${raw.length} Items (${withGrounding} mit Beleg), ${kb} KB`)
