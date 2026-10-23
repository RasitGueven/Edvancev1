// LSA-A1 — Gleichlauf Themenfeld zwischen Report (TS) und LSA-Payload (SQL).
//
// Schreibt aus feldVon (src/lib/report/elternbericht/themenfelder.ts) die Paare
// (skill_key, feld) nach supabase/tests/fixtures/themenfeld.sql. pgTAP
// (supabase/tests/lsa_themenfeld.test.sql) prüft public.lsa_themenfeld dagegen,
// themenfeld-fixture.test.ts hält die Datei aktuell.
//
//   npx tsx --tsconfig tsconfig.app.json tools/themenfeld-fixture.ts
//
// Nach jeder Änderung an PRAEFIX, AUSNAHMEN, THEMENFELDER oder SKILL_BESTAND neu
// erzeugen — und lsa_themenfeld per neuer Migration nachziehen, wenn pgTAP rot wird.

import { writeFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { feldVon } from '../src/lib/report/elternbericht/themenfelder'
import { SKILL_BESTAND } from '../src/lib/report/skillBestand'

export const FIXTURE_PFAD = 'supabase/tests/fixtures/themenfeld.sql'

/**
 * Randfälle zusätzlich zum Bestand: der volle Schlüssel zählt nicht als Präfix
 * (`zahl`, `zahl_potenz`), nur ganze Segmente (`bruchrechnen`), Ausnahmen nur
 * wörtlich (`proportionalitaet_neu`), Unbekanntes und Leeres fallen auf `weitere`.
 */
export const RANDFAELLE: readonly string[] = [
  '',
  'bruchrechnen',
  'geo',
  'proportionalitaet_neu',
  'prozent_zins',
  'zahl',
  'zahl_potenz',
  'zahl_potenz_neu',
  'zahl_wurzel_neu',
  'zz_l1_s1',
]

const sqlText = (s: string): string => `'${s.replace(/'/g, "''")}'`

export function themenfeldFixture(): string {
  const keys = [...new Set([...SKILL_BESTAND, ...RANDFAELLE])].sort()
  const zeilen = keys.map((k) => `  (${sqlText(k)}, ${sqlText(feldVon(k))})`)
  return [
    '-- Erzeugt von tools/themenfeld-fixture.ts aus feldVon (themenfelder.ts). Nicht von Hand ändern.',
    'create temp table themenfeld_soll (skill_key text primary key, feld text not null);',
    'insert into themenfeld_soll (skill_key, feld) values',
    zeilen.join(',\n') + ';',
    '',
  ].join('\n')
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  writeFileSync(resolve(process.cwd(), FIXTURE_PFAD), themenfeldFixture())
  console.log(`wrote ${FIXTURE_PFAD}`)
}
