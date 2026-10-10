// Gemeinsames fuer tools/szenario-lsa.mjs und tools/szenario-zuruecksetzen.mjs (Paket F1, Umfang B3).
// Verbindung: --db <conninfo> (Wegwerf-DB) oder DATABASE_URL aus der Umgebung bzw. der .env im Arbeitsverzeichnis.
// Die Verbindungszeichenkette erscheint nie in der Ausgabe (redigiert).

import { spawnSync } from 'node:child_process'
import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'

export function argumente(argv) {
  const a = { dryRun: false, db: null, kind: null, admin: null, muster: 'docs/szenario/batu.json', protokoll: null }
  for (let i = 0; i < argv.length; i++) {
    const x = argv[i]
    if (x === '--dry-run') a.dryRun = true
    else if (['--db', '--kind', '--admin', '--muster', '--protokoll'].includes(x)) a[x.slice(2)] = argv[++i]
    else throw new Error(`Unbekanntes Argument: ${x}`)
  }
  return a
}

export function verbindung(db) {
  if (db) return db
  if (process.env.DATABASE_URL) return process.env.DATABASE_URL
  const env = path.join(process.cwd(), '.env')
  if (fs.existsSync(env)) {
    const zeile = fs.readFileSync(env, 'utf8').split('\n').find((z) => z.startsWith('DATABASE_URL='))
    if (zeile) return zeile.slice('DATABASE_URL='.length).trim().replace(/^['"]|['"]$/g, '')
  }
  throw new Error('Keine Datenbank: --db angeben oder DATABASE_URL setzen (.env im Arbeitsverzeichnis).')
}

export const redigieren = (s) => String(s ?? '').replace(/postgres(ql)?:\/\/\S*/g, '[REDACTED]')

/** SQL-Text als Literal ($tag$…$tag$), damit Muster-JSON keine Anfuehrungszeichen-Probleme macht. */
export const literal = (s) => `$lit$${s}$lit$`

/** Fuehrt eine SQL-Datei in einer Transaktion aus (psql -1); gibt die NOTICE-Zeilen zurueck. */
export function sqlAusfuehren(conn, sql) {
  const datei = path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'szenario-')), 'lauf.sql')
  fs.writeFileSync(datei, sql)
  const r = spawnSync('psql', [conn, '-X', '-q', '-1', '-v', 'ON_ERROR_STOP=1', '-f', datei], { encoding: 'utf8' })
  fs.rmSync(path.dirname(datei), { recursive: true, force: true })
  if (r.error) throw new Error(`psql nicht startbar: ${redigieren(r.error.message)}`)
  const meldungen = redigieren(r.stderr).split('\n').filter(Boolean)
  const hinweise = meldungen
    .map((z) => z.replace(/^psql:[^:]*:\d+: /, ''))
    .filter((z) => /^(NOTICE|HINWEIS):/.test(z))
    .map((z) => z.replace(/^(NOTICE|HINWEIS):\s*/, ''))
  if (r.status !== 0) {
    const fehler = meldungen.filter((z) => /ERROR|FEHLER/.test(z)).join('\n') || meldungen.join('\n')
    const e = new Error(fehler)
    e.hinweise = hinweise
    throw e
  }
  return hinweise
}

/** Claims als Admin, transaktionslokal (wie docs/session/trockenlauf.md Schritt 6). */
export function adminClaims(admin) {
  const wer = admin
    ? `${literal(admin)}::uuid`
    : `(select p.id from public.profiles p where p.role = 'admin' and p.full_name = 'Rasit Güven')`
  return `do $c$
declare v uuid := ${wer};
begin
  if v is null or not exists (select 1 from public.profiles where id = v and role = 'admin') then
    raise exception 'szenario: kein Admin-Profil gefunden';
  end if;
  perform set_config('request.jwt.claims', json_build_object('sub', v, 'role', 'authenticated')::text, true);
end $c$;
`
}
