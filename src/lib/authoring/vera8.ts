// VERA8 — die EINE Definition (Nachtrag zu PR #176).
//
// VERA8-Aufgaben werden nicht vorbefuellt und erscheinen nicht im Lena-Board.
// Erkennbar sind sie ausschliesslich an der Herkunft: tasks.source = 'VERA8_IQB'
// (299 Aufgaben, Stand 30.09.2026; keine anderen VERA-Jahrgaenge, keine Grenzfaelle).
//
// Die Kennung steht in vera8.json, damit Board (dieses Modul), Prefill-Werkzeuge
// (tools/prefill-lib.mjs) und die SQL-Bedingungen in freigabe_cluster und
// freigabe_thema dieselbe Quelle haben — vera8.test.ts prueft den Gleichlauf.

import definition from './vera8.json'

export const VERA8_SOURCE: string = definition.source

export function istVera8(task: { source?: string | null }): boolean {
  return task.source === VERA8_SOURCE
}
