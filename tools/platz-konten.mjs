#!/usr/bin/env node
/**
 * platz-konten.mjs — legt Platz-Konten (Tablets) an, genau wie das vorhandene Gerät.
 *
 * Ein Platz-Konto ist ein Auth-User mit Rolle student OHNE students-Zeile, gekennzeichnet
 * in platz_devices (Migrationen 20260716110000_s9_platz_mechanik, 20261007110300_session_tablets).
 * Je Tablet-Nummer n entstehen:
 *   1. Auth-User über die Admin-API (E-Mail platz<n>@edvance.invalid, bestätigt, Passwort zufällig)
 *   2. profiles (id, email, role = 'student', full_name leer)
 *   3. platz_devices (profile_id, label = 'Tablet <n>', tablet_nr = n)
 * Scheitert 2 oder 3, wird der Auth-User wieder gelöscht (profiles hängt per Cascade daran).
 *
 * Idempotent: Eine belegte tablet_nr wird übersprungen. Gibt es den Auth-User schon, aber
 * keine tablet_nr dazu (halb angelegt), bricht das Werkzeug ab, statt zu raten.
 *
 * Lesen nur über ~/bin/dbread (read-only). Geschrieben wird nur ohne --dry-run, mit
 * SUPABASE_SERVICE_ROLE_KEY aus der Umgebung (wie tools/verify-tasks.mjs).
 * Zugangsdaten gehen ausschließlich nach ~/platz-konten/zugaenge.txt (chmod 600), nie in die Ausgabe.
 *
 *   node tools/platz-konten.mjs --dry-run 2-5
 *   node tools/platz-konten.mjs 2 3 4 5
 */
import { execFileSync } from 'node:child_process'
import { randomBytes } from 'node:crypto'
import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { pathToFileURL } from 'node:url'

export const DOMAIN = 'edvance.invalid'
export const mailFuer = (nr) => `platz${nr}@${DOMAIN}`
export const labelFuer = (nr) => `Tablet ${nr}`
export const ZUGAENGE = path.join(os.homedir(), 'platz-konten', 'zugaenge.txt')

/** "2-5", "2,3", "2 3" → sortierte, eindeutige Nummern 1..99. Wirft bei allem anderen. */
export function nummernLesen(args) {
  const nummern = new Set()
  for (const teil of args.flatMap((a) => String(a).split(',')).map((s) => s.trim()).filter(Boolean)) {
    const m = /^(\d{1,2})(?:-(\d{1,2}))?$/.exec(teil)
    if (!m) throw new Error(`Ungültige Tablet-Nummer: ${teil}`)
    const von = Number(m[1])
    const bis = m[2] === undefined ? von : Number(m[2])
    if (von < 1 || bis > 99 || von > bis) throw new Error(`Tablet-Nummern liegen zwischen 1 und 99: ${teil}`)
    for (let n = von; n <= bis; n++) nummern.add(n)
  }
  if (nummern.size === 0) throw new Error('Keine Tablet-Nummer angegeben (z. B. 2-5).')
  return [...nummern].sort((a, b) => a - b)
}

/**
 * bestand.belegt: tablet_nr in platz_devices; bestand.mails: n mit vorhandenem Auth-User platz<n>@….
 * Ergebnis je Nummer: anlegen | ueberspringen | konflikt.
 */
export function planen(nummern, bestand) {
  return nummern.map((nr) => {
    if (bestand.belegt.has(nr)) return { nr, aktion: 'ueberspringen', grund: 'tablet_nr schon vergeben' }
    if (bestand.mails.has(nr)) return { nr, aktion: 'konflikt', grund: 'Auth-User vorhanden, aber ohne tablet_nr' }
    return { nr, aktion: 'anlegen', grund: `Auth-User, profiles, platz_devices „${labelFuer(nr)}“` }
  })
}

export const passwortErzeugen = () => randomBytes(18).toString('base64url')

/** Führt den Plan aus. anlegen/notieren sind eingespritzt (Test ohne Netz, ohne Datei). */
export async function lauf({ plan, dryRun, anlegen, notieren, log = console.log }) {
  const stand = { angelegt: 0, uebersprungen: 0, konflikt: 0 }
  for (const p of plan) log(`Tablet ${p.nr}: ${dryRun && p.aktion === 'anlegen' ? 'würde anlegen' : p.aktion} (${p.grund})`)
  stand.uebersprungen = plan.filter((p) => p.aktion === 'ueberspringen').length
  stand.konflikt = plan.filter((p) => p.aktion === 'konflikt').length
  if (stand.konflikt > 0) {
    log('Abbruch: halb angelegte Konten zuerst klären. Nichts geschrieben.')
    return stand
  }
  if (dryRun) return stand
  for (const p of plan.filter((x) => x.aktion === 'anlegen')) {
    const passwort = passwortErzeugen()
    await anlegen({ nr: p.nr, email: mailFuer(p.nr), label: labelFuer(p.nr), passwort })
    notieren({ nr: p.nr, email: mailFuer(p.nr), passwort })
    stand.angelegt++
    log(`Tablet ${p.nr}: angelegt, Zugang in ${ZUGAENGE}`)
  }
  return stand
}

// ---------------------------------------------------------------------------
// Effekte: dbread (lesen), Admin-API (schreiben), Zugangsdatei
// ---------------------------------------------------------------------------

function dbread(sql) {
  try {
    return String(execFileSync(path.join(os.homedir(), 'bin', 'dbread'), ['-tAc', sql], { encoding: 'utf8' }))
  } catch (e) {
    throw new Error(`dbread fehlgeschlagen (Exit ${e.status ?? '?'})`)
  }
}

const zahlen = (out) => new Set(out.split('\n').map((s) => s.trim()).filter(Boolean).map(Number))

export function bestandLesen() {
  return {
    belegt: zahlen(dbread('select tablet_nr from public.platz_devices where tablet_nr is not null')),
    mails: zahlen(dbread(String.raw`select substring(email from '^platz([0-9]+)@edvance\.invalid$') from auth.users where email ~ '^platz[0-9]+@edvance\.invalid$'`)),
  }
}

function zugangsdateiVorbereiten() {
  fs.mkdirSync(path.dirname(ZUGAENGE), { recursive: true, mode: 0o700 })
  fs.appendFileSync(ZUGAENGE, '', { mode: 0o600 })
  fs.chmodSync(ZUGAENGE, 0o600)
}

function notierenDatei({ nr, email, passwort }) {
  fs.appendFileSync(ZUGAENGE, `${labelFuer(nr)}\t${email}\t${passwort}\t${new Date().toISOString()}\n`, { mode: 0o600 })
  fs.chmodSync(ZUGAENGE, 0o600)
}

async function adminClient() {
  try { process.loadEnvFile('.env') } catch { /* keine .env — dann nur echte Umgebung */ }
  const url = process.env.SUPABASE_URL ?? process.env.VITE_SUPABASE_URL
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY
  if (!url || !key) return null
  const { createClient } = await import('@supabase/supabase-js')
  return createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } })
}

function anlegenMit(sb) {
  return async ({ nr, email, label, passwort }) => {
    const { data, error } = await sb.auth.admin.createUser({ email, password: passwort, email_confirm: true })
    if (error || !data?.user) throw new Error(`Tablet ${nr}: Auth-User nicht angelegt (${error?.message ?? 'leer'})`)
    const id = data.user.id
    try {
      const p = await sb.from('profiles').insert({ id, email, role: 'student', full_name: null })
      if (p.error) throw new Error(`profiles: ${p.error.message}`)
      const d = await sb.from('platz_devices').insert({ profile_id: id, label, tablet_nr: nr })
      if (d.error) throw new Error(`platz_devices: ${d.error.message}`)
    } catch (e) {
      const r = await sb.auth.admin.deleteUser(id)
      throw new Error(`Tablet ${nr}: ${e.message}; Auth-User ${r.error ? 'NICHT zurückgenommen' : 'zurückgenommen'}`)
    }
  }
}

async function main(argv = process.argv.slice(2)) {
  const dryRun = argv.includes('--dry-run')
  const nummern = nummernLesen(argv.filter((a) => a !== '--dry-run'))
  const plan = planen(nummern, bestandLesen())
  let anlegen = null
  if (!dryRun && plan.some((p) => p.aktion === 'anlegen')) {
    const sb = await adminClient()
    if (!sb) {
      console.error('SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY fehlen in der Umgebung. Nichts geschrieben.')
      return 2
    }
    zugangsdateiVorbereiten()
    anlegen = anlegenMit(sb)
  }
  const stand = await lauf({ plan, dryRun, anlegen, notieren: notierenDatei })
  console.log(`${dryRun ? 'Trockenlauf' : 'Ergebnis'}: ${JSON.stringify(stand)}`)
  if (!dryRun) {
    const b = bestandLesen()
    console.log(`dbread danach: ${b.belegt.size} Platz-Konten mit tablet_nr, belegt: ${[...b.belegt].sort((x, y) => x - y).join(', ')}`)
  }
  return stand.konflikt ? 1 : 0
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
