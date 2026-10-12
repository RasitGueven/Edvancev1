#!/usr/bin/env node
// Testkonten aus den Slots räumen (Bauauftrag Slots, Paket SL2b, Entscheidung 6).
//
//   node tools/slots-testkonten-raeumen.mjs --dry-run       nur Anzahlen, nichts ändern
//   node tools/slots-testkonten-raeumen.mjs --ausfuehren    Stammplätze beenden, künftige Termine ausfallen lassen
//
// WIRD ERST NACH „Testkonten räumen“ VON RASIT AUSGEFÜHRT, spätestens bevor das erste echte Kind einen
// Stammplatz bekommt. Zugang aus der Umgebung: DATABASE_URL (Systemaufruf, wie die Migrationen).
// Die Arbeit macht tools/slots-testkonten-raeumen.sql in einer Transaktion (psql -1) über die vorhandenen
// Slot-Funktionen (stammplatz_beenden, termin_ausgefallen); kein direktes DELETE an den Regeln vorbei.
// Entfernt werden die beweglichen Stammplatz-Termine (über die Planung). Zusatztermine und Umbuchungen löscht keine
// Slot-Funktion; sie werden „ausgefallen durch uns“ und belegen nichts mehr. Heute schon festgeschriebene Termine
// (mit Session, auch Testläufe) bleiben stehen, bis der Tag vorbei ist.
// Ausgabe: Zieldatenbank, Anzahlen vorher, Änderungen, Anzahlen nachher. Ein Fehler rollt alles zurück.
// Vorher immer --dry-run gegen dasselbe Ziel und die Zeile „ziel …“ prüfen.

import { execFileSync } from 'node:child_process'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const SQL = join(dirname(fileURLToPath(import.meta.url)), 'slots-testkonten-raeumen.sql')

function main(argv) {
  const trocken = argv.includes('--dry-run')
  const ausfuehren = argv.includes('--ausfuehren')
  if (trocken === ausfuehren) {
    console.error('Genau eine Option angeben: --dry-run oder --ausfuehren')
    return 2
  }
  const url = process.env.DATABASE_URL
  if (!url) {
    console.error('Umgebungsvariable DATABASE_URL fehlt.')
    return 2
  }
  let out
  try {
    out = execFileSync(
      'psql',
      [url, '-X', '-q', '-tA', '-1', '-v', 'ON_ERROR_STOP=1', '-v', 'als_system=1', '-v', `trocken=${trocken ? 'on' : 'off'}`,
        '-f', SQL],
      { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] },
    )
  } catch (e) {
    // Die Kommandozeile trägt das Passwort: nur stderr ausgeben, Verbindungsangaben geschwärzt.
    console.error(`psql fehlgeschlagen (exit ${e.status}), nichts geändert:`)
    console.error(String(e.stderr ?? '').replace(/postgres(ql)?:\/\/\S+/g, '[R]'))
    return 1
  }
  for (const zeile of out.split('\n').filter(Boolean)) console.log(zeile)
  console.log(trocken ? '\n(dry-run: nichts geändert)' : '\n(ausgeführt, eine Transaktion)')
  return 0
}

process.exit(main(process.argv.slice(2)))
