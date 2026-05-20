// Seedet VERA-8 IQB-Aufgaben aus vera8_komplett.json in screening_items.
//
// Voraussetzung:
//   - Migration 029 ausgefuehrt (lockert NOT-NULLs, fuegt iqb_titel UNIQUE +
//     VERA-Spalten + meta jsonb hinzu).
//   - ENV: SUPABASE_URL (oder VITE_SUPABASE_URL) + SUPABASE_SERVICE_ROLE_KEY.
//
// Nutzung:
//   npm run seed:vera8 -- --file path/to/vera8_komplett.json
//   npm run seed:vera8 -- --file ... --write    (sonst Dry-Run)
//
// Idempotenz:
//   - iqb_titel ist UNIQUE.
//   - Neue Titel  -> INSERT mit active=false (QS-Gate gilt).
//   - Bestehende  -> UPDATE aller Felder AUSSER active (Freigaben bleiben).
//
// VERA-Mapping:
//   - Alle Items kommen als input_type='OPEN' + check_type='manual' rein
//     (Coach-Kodierung via screening_item_ratings, vgl. Migration 028).
//   - afb_ki in {1,2,3}  -> afb='I'/'II'/'III' + level=1/2/3, sonst NULL.
//   - canonical = { accepted: akzeptierte_antworten ?? [] }.
//   - alles weitere als eigene Spalten; Rohwerte zusaetzlich in meta jsonb.

import { readFileSync } from 'node:fs'
import { createClient } from '@supabase/supabase-js'

type Vera8Item = {
  iqb_titel: string
  klasse?: number
  leitidee_raw?: string
  kompetenzfelder?: string[]
  fix_anker?: boolean
  quelle?: string
  aktiv?: boolean
  datei_ext?: string
  urls?: Record<string, string>
  teilaufgaben?: unknown[]
  aufgabe_typ?: string | null
  aufgabe_text_clean?: string | null
  aufgabe_text_roh?: string | null
  kontext?: string | null
  loesung_pro_ta?: unknown[]
  akzeptierte_antworten?: string[]
  kodierung?: string | null
  kommentar_highlights?: {
    typische_fehler?: string | string[]
    didaktischer_hinweis?: string
    schwierigkeit_einschaetzung?: string
  } | null
  kompetenzfeld_ki?: string | null
  afb_ki?: number | number[] | null
}

type ScreeningItemRow = {
  iqb_titel: string
  class_level: number
  input_type: 'OPEN'
  check_type: 'manual'
  source: string
  quelle: string
  prompt: string | null
  canonical: { accepted: string[] }
  topic: string | null
  skill_code: string | null
  skill_label: string | null
  level: number | null
  afb: 'I' | 'II' | 'III' | null
  kompetenzfelder: string[] | null
  aufgabe_typ: string | null
  teilaufgaben: unknown[] | null
  kontext: string | null
  loesung_pro_ta: unknown[] | null
  akzeptierte_antworten: string[] | null
  kodierung: string | null
  kommentar_highlights: unknown | null
  urls: unknown | null
  datei_ext: string | null
  fix_anker: boolean
  typical_errors: string[]
  explanation: string | null
  meta: Record<string, unknown>
}

const LEITIDEE_BY_CODE: Record<string, string> = {
  L1: 'Zahl',
  L2: 'Messen',
  L3: 'Raum und Form',
  L4: 'Funktionaler Zusammenhang',
  L5: 'Daten und Zufall',
}

function afbToRoman(v: Vera8Item['afb_ki']): 'I' | 'II' | 'III' | null {
  if (v === 1) return 'I'
  if (v === 2) return 'II'
  if (v === 3) return 'III'
  return null
}

function afbToLevel(v: Vera8Item['afb_ki']): 1 | 2 | 3 | null {
  if (v === 1 || v === 2 || v === 3) return v
  return null
}

function splitTypischeFehler(s: unknown): string[] {
  if (!s) return []
  const parts = Array.isArray(s)
    ? s.flatMap((v) => (typeof v === 'string' ? v.split(/;\s*|\n+/) : []))
    : typeof s === 'string'
      ? s.split(/;\s*|\n+/)
      : []
  return parts.map((p) => p.replace(/^\d+\)\s*/, '').trim()).filter(Boolean)
}

function mapItem(item: Vera8Item): ScreeningItemRow {
  const code = item.kompetenzfeld_ki ?? item.kompetenzfelder?.[0] ?? null
  const topic = item.leitidee_raw ?? (code ? LEITIDEE_BY_CODE[code] ?? null : null)
  const accepted = item.akzeptierte_antworten ?? []
  const highlights = item.kommentar_highlights ?? null
  return {
    iqb_titel: item.iqb_titel,
    class_level: item.klasse ?? 8,
    input_type: 'OPEN',
    check_type: 'manual',
    source: 'VERA8_IQB',
    quelle: item.quelle ?? 'VERA8_IQB',
    prompt: item.aufgabe_text_clean ?? item.aufgabe_text_roh ?? null,
    canonical: { accepted },
    topic,
    skill_code: code,
    skill_label: topic,
    level: afbToLevel(item.afb_ki),
    afb: afbToRoman(item.afb_ki),
    kompetenzfelder: item.kompetenzfelder ?? null,
    aufgabe_typ: item.aufgabe_typ ?? null,
    teilaufgaben: item.teilaufgaben ?? null,
    kontext: item.kontext ?? null,
    loesung_pro_ta: item.loesung_pro_ta ?? null,
    akzeptierte_antworten: accepted.length ? accepted : null,
    kodierung: item.kodierung ?? null,
    kommentar_highlights: highlights,
    urls: item.urls ?? null,
    datei_ext: item.datei_ext ?? null,
    fix_anker: item.fix_anker ?? false,
    typical_errors: splitTypischeFehler(highlights?.typische_fehler),
    explanation: highlights?.didaktischer_hinweis ?? null,
    meta: {
      afb_ki_raw: item.afb_ki ?? null,
      kompetenzfeld_ki: item.kompetenzfeld_ki ?? null,
      aufgabe_text_roh: item.aufgabe_text_roh ?? null,
      schwierigkeit: highlights?.schwierigkeit_einschaetzung ?? null,
    },
  }
}

function getArg(name: string): string | undefined {
  const i = process.argv.indexOf(name)
  return i >= 0 ? process.argv[i + 1] : undefined
}

async function main(): Promise<void> {
  const file = getArg('--file')
  const write = process.argv.includes('--write')
  if (!file) {
    console.error('Bitte --file <pfad-zu-vera8_komplett.json> angeben.')
    process.exit(1)
  }
  const url = process.env.SUPABASE_URL ?? process.env.VITE_SUPABASE_URL
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY
  if (!url || !key) {
    console.error('Fehlende ENV: SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY.')
    process.exit(1)
  }
  const supabase = createClient(url, key, {
    auth: { autoRefreshToken: false, persistSession: false },
  })

  const raw = JSON.parse(readFileSync(file, 'utf-8'))
  const items: Vera8Item[] = Array.isArray(raw) ? raw : (raw.aufgaben ?? [])
  if (!items.length) {
    console.error('Keine Items im JSON gefunden (erwartet: top-level Array oder { aufgaben: [...] }).')
    process.exit(1)
  }
  console.log(`Geladen: ${items.length} VERA-8 Items aus ${file}`)
  console.log(`Modus:   ${write ? 'WRITE (DB wird geaendert)' : 'DRY-RUN (nur Vorschau)'}`)

  const rows = items.filter((it) => it.iqb_titel).map(mapItem)
  const skippedNoTitle = items.length - rows.length
  if (skippedNoTitle) console.warn(`! ${skippedNoTitle} Items ohne iqb_titel ignoriert.`)

  const titles = rows.map((r) => r.iqb_titel)
  const { data: existingRows, error: selErr } = await supabase
    .from('screening_items')
    .select('iqb_titel')
    .in('iqb_titel', titles)
  if (selErr) {
    console.error('Lese-Fehler:', selErr.message)
    process.exit(1)
  }
  const existing = new Set((existingRows ?? []).map((r) => r.iqb_titel as string))

  const toInsert = rows.filter((r) => !existing.has(r.iqb_titel))
  const toUpdate = rows.filter((r) => existing.has(r.iqb_titel))
  console.log(`Geplant: ${toInsert.length} INSERT (active=false), ${toUpdate.length} UPDATE (active bleibt).`)

  if (!write) {
    console.log('Dry-Run beendet. Mit --write erneut ausfuehren.')
    return
  }

  let inserted = 0
  let updated = 0
  const failed: Array<{ titel: string; reason: string }> = []

  if (toInsert.length) {
    const insertPayload = toInsert.map((r) => ({ ...r, active: false }))
    const batchSize = 50
    for (let i = 0; i < insertPayload.length; i += batchSize) {
      const batch = insertPayload.slice(i, i + batchSize)
      const { error } = await supabase.from('screening_items').insert(batch)
      if (error) {
        for (const r of batch) failed.push({ titel: r.iqb_titel, reason: error.message })
      } else {
        inserted += batch.length
        console.log(`  INSERT ${Math.min(i + batchSize, insertPayload.length)}/${insertPayload.length}`)
      }
    }
  }

  for (let i = 0; i < toUpdate.length; i++) {
    const r = toUpdate[i]
    const { error } = await supabase
      .from('screening_items')
      .update(r)
      .eq('iqb_titel', r.iqb_titel)
    if (error) failed.push({ titel: r.iqb_titel, reason: error.message })
    else updated++
    if ((i + 1) % 25 === 0 || i === toUpdate.length - 1) {
      console.log(`  UPDATE ${i + 1}/${toUpdate.length}`)
    }
  }

  console.log('\n=== Zusammenfassung ===')
  console.log(`  eingefuegt: ${inserted}`)
  console.log(`  aktualisiert: ${updated}`)
  console.log(`  uebersprungen (kein iqb_titel): ${skippedNoTitle}`)
  console.log(`  fehlgeschlagen: ${failed.length}`)
  if (failed.length) {
    console.log('\nFehler:')
    for (const f of failed.slice(0, 20)) console.log(`  - ${f.titel}: ${f.reason}`)
    if (failed.length > 20) console.log(`  ... und ${failed.length - 20} weitere`)
    process.exit(1)
  }
}

main().catch((err) => {
  console.error('Unerwarteter Fehler:', err)
  process.exit(1)
})
