// Baut den Quellenbeleg-Index fuer das Autoren-Tool.
//
//   data/vera8_v2.json                (Neuextraktion: _grounding, _flags)
//   data/vera8_komplett_enriched.json (Altlauf: iqb_urls, lizenz_status, Rohtext)
//        ↓  nur die Belege, keine abgeleiteten Felder
//   public/authoring/grounding-vera8.json   (nach `source_ref` gekeyt)
//
// WARUM nicht direkt die grosse Datei importieren: ein `import` wuerde sie in das
// Admin-Bundle backen. Der Index liegt in public/ und wird erst geladen, wenn
// jemand ein Item mit VERA-Quelle oeffnet (src/lib/authoring/grounding.ts).
//
// ============================================================================
// ⚠️  DIESE DATEI IST OEFFENTLICH. public/ wird statisch ausgeliefert — ohne Auth,
//     ohne RLS. Wer die URL kennt, liest sie. Auch ein Kind mitten in der LSA.
//
//     Der Index enthielt bis C08 die Auswertungs-Zitate ("RICHTIG-Zelle: 16") fuer
//     209 der 299 Items — die Loesungen, oeffentlich abrufbar. Das ist derselbe
//     Defekt, den T1/T1b gerade in `tasks` geschlossen haben (INV-6: keine Loesung
//     in einer Zone, die ein Schueler lesen darf), nur eine Schicht darueber.
//
//     Ab C08 gilt hier eine Regel, und die Gegenprobe am Ende erzwingt sie:
//     In den Index darf nur, was das Kind ohnehin sieht — Aufgabentext,
//     Teilaufgaben-Prompts, Tabellen, Lizenz, Quell-URLs, Flags.
//     Der LOESUNGSBELEG (akzeptierte Antworten, Kodieranweisung, typische Fehler)
//     geht NICHT hier durch. Er landet ueber scripts/import-vera8-draft.ts in
//     task_solutions.solution — der Server-Only-Zone, die nur Coach/Admin ueber
//     task_solution_get liest. Der Pfleger verliert nichts. Das Kind schon.
// ============================================================================
//
// Nutzung:  npx tsx scripts/build-grounding-index.ts

import { mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { dirname } from 'node:path'
import { buildItem, type V2Item } from './content/vera8Draft'

const V2 = 'data/vera8_v2.json'
const V1 = 'data/vera8_komplett_enriched.json'
const TARGET = 'public/authoring/grounding-vera8.json'

/** Feldnamen, deren Beleg die Loesung nennt. Sie kommen nicht in die oeffentliche
 *  Datei — egal, aus welchem Lauf sie stammen. */
const LOESUNG = /correct_answers|akzeptierte_antworten|loesung|kodierung|typische_fehler|antwort/i

type V1Item = {
  id: string
  titel?: string
  quelle?: string
  lizenz_status?: string
  iqb_urls?: Record<string, string>
  aufgabe_text?: string
  _problems?: string[]
}

const v2 = JSON.parse(readFileSync(V2, 'utf8')) as V2Item[]
const v1 = JSON.parse(readFileSync(V1, 'utf8')) as V1Item[]
const v1ById = new Map(v1.map((i) => [i.id, i]))

const index: Record<string, unknown> = {}
let mitBeleg = 0
let unterdrueckt = 0

for (const item of v2) {
  if (!item.id) continue
  const alt = v1ById.get(item.id)
  const built = buildItem(item)

  const belege: { feld: string; gate?: string; quelle?: string; zitat: string; hinweis?: string }[] = []
  for (const [feld, b] of Object.entries(item._grounding ?? {})) {
    if (LOESUNG.test(feld)) {
      unterdrueckt++
      continue
    }
    if (!b?.zitat) continue
    belege.push({ feld, gate: b.gate, quelle: b.quelle, zitat: b.zitat, hinweis: b.hinweis })
  }
  if (belege.length) mitBeleg++

  // Teilaufgaben, die der P02-Vertrag nicht halten konnte (Freitext, leerer Prompt,
  // MC ohne Optionen): read-only sichtbar, damit sie nicht verloren gehen — und
  // ohne correct_answers, denn die Datei ist oeffentlich.
  const teilaufgabenRoh = built.droppedParts.map((p) => ({
    nr: p.nr,
    kind: p.kind,
    prompt: p.prompt ?? '',
    unit: p.unit ?? undefined,
    options: p.options ?? undefined,
  }))

  // Eine Tabelle, die F01 abgewiesen hat (leere Header, ragged rows): roh zeigen,
  // damit der Pfleger sie nachbauen kann, statt sie zu suchen.
  const payloadTable = (built.row.question_payload as { table?: unknown } | null)?.table
  const tabelleRoh = item.stem?.table && !payloadTable ? item.stem.table : undefined

  index[item.id] = {
    id: item.id,
    titel: item.titel ?? alt?.titel,
    quelle: alt?.quelle ?? 'VERA8_IQB',
    lizenz_status: alt?.lizenz_status,
    iqb_urls: alt?.iqb_urls,
    aufgabe_text: alt?.aufgabe_text,
    problems: alt?._problems?.length ? alt._problems : undefined,
    // Was die Extraktion selbst unsicher fand …
    flags: item._flags?.length ? item._flags : undefined,
    // … und was der Import nicht abbilden konnte.
    import_flags: built.importFlags.length ? built.importFlags : undefined,
    belege: belege.length ? belege : undefined,
    teilaufgaben_roh: teilaufgabenRoh.length ? teilaufgabenRoh : undefined,
    tabelle_roh: tabelleRoh,
  }
}

mkdirSync(dirname(TARGET), { recursive: true })
writeFileSync(TARGET, JSON.stringify(index), 'utf8')

// Gegenprobe: nach dem Bau steht keine Loesung mehr in der oeffentlichen Datei.
const geschrieben = readFileSync(TARGET, 'utf8')
const leck = /"(correct_answers|akzeptierte_antworten)"/.test(geschrieben)
const kb = Math.round(Buffer.byteLength(geschrieben) / 1024)

console.log(`${Object.keys(index).length} Items → ${TARGET} (${kb} KB)`)
console.log(`  mit Quellenbeleg: ${mitBeleg}`)
console.log(`  Loesungsbelege unterdrueckt (→ task_solutions.solution): ${unterdrueckt}`)
console.log(`  Loesungsfeld im oeffentlichen Index: ${leck ? '✗ JA — STOP' : '0 ✓'}`)
if (leck) process.exit(1)
