#!/usr/bin/env node
// Formeln der Erklaerschritte als SVG (Bauauftrag Session-P1, Entscheidung 19).
//
//   node tools/formeln-svg.mjs --dry-run              offene Schritte aus der DB, nichts laden/schreiben
//   node tools/formeln-svg.mjs                        erzeugen, hochladen, Hashes eintragen
//   node tools/formeln-svg.mjs --dry-run --aus-datei schritte.json   [{id, inhalt}] statt DB
//   node tools/formeln-svg.mjs --tex '\frac{1}{2}'    eine Formel als SVG auf stdout
//   Zusatz: --force (auch Schritte, deren Formeln schon vollstaendig sind), --schritt <uuid>
//
// WIRD VON RASIT AUSGEFUEHRT, wie scripts/figures/upload_figures.py. Zugaenge aus der Umgebung:
//   DATABASE_URL          Lesen der Schritte, Schreiben ueber erklaer_formeln_setzen
//   SUPABASE_URL          z. B. https://<ref>.supabase.co (nicht im --dry-run)
//   SUPABASE_SERVICE_KEY  service_role-Key fuer den Storage-Upload (nicht im --dry-run)
//
// Ablauf je Schritt: alle $…$ finden (dieselbe Regel wie erklaer_formel_anzahl in SQL),
// jede Formel mit mathjax-full in ein eigenstaendiges SVG setzen (fontCache 'none',
// Farbe currentColor) und pruefen. Faellt eine Formel durch, wird fuer diesen Schritt
// nichts geladen und nichts geschrieben. Sonst nach task-assets/erklaer/formeln/<sha256>.svg
// laden und die Hashes ueber erklaer_formeln_setzen eintragen; die Funktion lehnt ab,
// wenn sich der Text inzwischen geaendert hat. Gleiches SVG -> gleicher Hash -> idempotent.

import { createHash } from 'node:crypto'
import { execFileSync } from 'node:child_process'
import { readFileSync } from 'node:fs'
import { createRequire } from 'node:module'
import { pathToFileURL } from 'node:url'

const require = createRequire(import.meta.url)
const { mathjax } = require('mathjax-full/js/mathjax.js')
const { TeX } = require('mathjax-full/js/input/tex.js')
const { SVG } = require('mathjax-full/js/output/svg.js')
const { liteAdaptor } = require('mathjax-full/js/adaptors/liteAdaptor.js')
const { RegisterHTMLHandler } = require('mathjax-full/js/handlers/html.js')
const { AllPackages } = require('mathjax-full/js/input/tex/AllPackages.js')

export const BUCKET = 'task-assets'
export const PFAD = 'erklaer/formeln'

const adaptor = liteAdaptor()
RegisterHTMLHandler(adaptor)
const dokument = mathjax.document('', {
  InputJax: new TeX({ packages: AllPackages }),
  OutputJax: new SVG({ fontCache: 'none' }),
})

/** Alle Formeln $…$ eines Markdown-Texts, in Reihenfolge (wie SQL '\$[^$]+\$'). */
export function formelnFinden(inhalt) {
  return [...String(inhalt ?? '').matchAll(/\$([^$]+)\$/g)].map((m) => m[1])
}

/** Eine TeX-Formel als eigenstaendiges SVG. Wirft bei TeX-Fehlern. */
export function texZuSvg(tex) {
  const knoten = dokument.convert(tex, { display: false })
  const svg = adaptor.innerHTML(knoten)
  const fehler = pruefeSvg(svg)
  if (fehler) throw new Error(`Formel "${tex}": ${fehler}`)
  return svg
}

/** null wenn das SVG brauchbar ist, sonst der Grund. */
export function pruefeSvg(svg) {
  if (!/^<svg[\s>]/.test(svg) || !svg.endsWith('</svg>')) return 'kein SVG'
  if (svg.includes('data-mml-node="merror"')) return 'TeX-Fehler'
  if (/<(script|foreignObject)\b/i.test(svg) || /\son\w+=/i.test(svg)) return 'unerlaubter Inhalt'
  if (!svg.includes('<path')) return 'leer'
  return null
}

export function svgHash(svg) {
  return createHash('sha256').update(svg, 'utf8').digest('hex')
}

/** Alle Formeln eines Schritts: [{tex, svg, hash, pfad}]. Wirft, wenn eine durchfaellt. */
export function schrittFormeln(inhalt) {
  return formelnFinden(inhalt).map((tex) => {
    const svg = texZuSvg(tex)
    const hash = svgHash(svg)
    return { tex, svg, hash, pfad: `${PFAD}/${hash}.svg` }
  })
}

/**
 * Verarbeitet Schritte. hochladen(pfad, svg) und eintragen(id, inhalt, hashes) werden
 * nur ausserhalb des Trockenlaufs gerufen. Liefert {geladen, uebersprungen, fehler}.
 */
export async function lauf({ schritte, dryRun, hochladen, eintragen, log = console.log }) {
  const stand = { geladen: 0, uebersprungen: 0, fehler: 0 }
  for (const s of schritte) {
    let formeln
    try {
      formeln = schrittFormeln(s.inhalt)
    } catch (e) {
      log(`  FEHLER ${s.id}: ${e.message} — nichts geladen`)
      stand.fehler += 1
      continue
    }
    if (formeln.length === 0 && (s.formeln ?? []).length === 0) {
      stand.uebersprungen += 1
      continue
    }
    for (const f of formeln) {
      if (dryRun) log(`  [dry-run] wuerde laden: ${f.pfad} (${f.svg.length} B)  ${f.tex}`)
      else await hochladen(f.pfad, f.svg)
    }
    const hashes = formeln.map((f) => f.hash)
    if (dryRun) log(`  [dry-run] wuerde formeln setzen: ${s.id} -> ${hashes.map((h) => h.slice(0, 12)).join(', ')}`)
    else await eintragen(s.id, s.inhalt, hashes)
    stand.geladen += 1
  }
  log(`\ngeladen=${stand.geladen} uebersprungen=${stand.uebersprungen} fehler=${stand.fehler}${dryRun ? ' (dry-run)' : ''}`)
  return stand
}

// ── Anbindung (nur CLI) ─────────────────────────────────────────────────────

function env(name) {
  const v = process.env[name]
  if (!v) throw new Error(`Umgebungsvariable ${name} fehlt.`)
  return v
}

// psql ueber execFileSync; Fehler ohne Kommandozeile melden (sie traegt das Passwort).
function psql(sql, vars = {}) {
  const args = [env('DATABASE_URL'), '-X', '-q', '-tA', '-v', 'ON_ERROR_STOP=1']
  for (const [k, v] of Object.entries(vars)) args.push('-v', `${k}=${v}`)
  try {
    return execFileSync('psql', args, { input: sql, encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] })
  } catch (e) {
    throw new Error(`psql fehlgeschlagen (exit ${e.status}): ${String(e.stderr).replace(/postgres(ql)?:\/\/\S+/g, '[R]')}`)
  }
}

function ladeSchritte({ force, schritt }) {
  const roh = psql(
    `select coalesce(json_agg(json_build_object('id', id, 'inhalt', inhalt, 'formeln', formeln) order by id), '[]')
       from public.erklaer_schritt
      where (:'force' = 'ja' or cardinality(formeln) <> public.erklaer_formel_anzahl(inhalt))
        and (:'schritt' = '' or id::text = :'schritt')`,
    { force: force ? 'ja' : 'nein', schritt: schritt ?? '' },
  )
  return JSON.parse(roh.trim() || '[]')
}

async function hochladenStorage(pfad, svg) {
  const res = await fetch(`${env('SUPABASE_URL')}/storage/v1/object/${BUCKET}/${pfad}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${env('SUPABASE_SERVICE_KEY')}`,
      'Content-Type': 'image/svg+xml',
      'x-upsert': 'true',
    },
    body: svg,
  })
  if (!res.ok) throw new Error(`Upload ${pfad} fehlgeschlagen: HTTP ${res.status}`)
}

function eintragenDb(id, inhalt, hashes) {
  psql(`select public.erklaer_formeln_setzen(:'id'::uuid, :'inhalt', :'formeln'::text[])`, {
    id,
    inhalt,
    formeln: `{${hashes.join(',')}}`,
  })
}

function argument(argv, name) {
  const i = argv.indexOf(name)
  return i >= 0 ? argv[i + 1] : undefined
}

export async function main(argv = process.argv.slice(2)) {
  const tex = argument(argv, '--tex')
  if (tex !== undefined) {
    process.stdout.write(texZuSvg(tex) + '\n')
    return 0
  }
  const dryRun = argv.includes('--dry-run')
  const datei = argument(argv, '--aus-datei')
  if (datei && !dryRun) throw new Error('--aus-datei nur mit --dry-run')
  const schritte = datei
    ? JSON.parse(readFileSync(datei, 'utf8'))
    : ladeSchritte({ force: argv.includes('--force'), schritt: argument(argv, '--schritt') })
  const stand = await lauf({ schritte, dryRun, hochladen: hochladenStorage, eintragen: eintragenDb })
  return stand.fehler ? 1 : 0
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  main().then(
    (code) => process.exit(code),
    (e) => {
      console.error(e.message)
      process.exit(1)
    },
  )
}
