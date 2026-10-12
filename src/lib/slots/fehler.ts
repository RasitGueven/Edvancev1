// Slots (Bauauftrag Slots, Entscheidung 23): Fehler der Slot-Funktionen auf i18n-Schlüssel abbilden.
// Die Oberfläche zeigt nur t(slotsFehlerSchluessel(res)) aus dem Namespace 'slots', nie den Rohtext
// der Datenbank. Reihenfolge: SL-Code vor Hinweis vor SQLSTATE; Unbekanntes wird 'fehler.allgemein'.

import type { RpcFehler } from '@/lib/supabase/sessionRpc'
import type { SlotsCode } from '@/types/slotplan'

export const SLOTS_CODES: readonly SlotsCode[] = [
  'SL001', 'SL002', 'SL003', 'SL004', 'SL005', 'SL006', 'SL007', 'SL008', 'SL009', 'SL010', 'SL011', 'SL012',
] as const

/** Hinweise (hint) der Slot-Funktionen, die mehr sagen als ihr SQLSTATE. */
const HINWEIS: Record<string, string> = {
  nur_am_tag: 'nurAmTag',
  testkonto: 'testkonto',
  eingang: 'eingang',
  zustand: 'zustand',
  name_doppelt: 'nameDoppelt',
  zeit_doppelt: 'zeitDoppelt',
  kein_coach: 'keinCoach',
  kein_vorschlag: 'keinVorschlag',
}

const SQLSTATE: Record<string, string> = {
  '42501': 'keinRecht',
  P0002: 'nichtGefunden',
  '22023': 'eingabe',
  ZG001: 'keinZugang',
}

export function istSlotsCode(code: string | null | undefined): code is SlotsCode {
  return !!code && (SLOTS_CODES as readonly string[]).includes(code)
}

/** i18n-Schlüssel (Namespace 'slots') für einen Fehler einer Slot-Funktion. */
export function slotsFehlerSchluessel(f: RpcFehler | null | undefined): string {
  if (!f) return 'fehler.allgemein'
  if (istSlotsCode(f.code)) return `fehler.${f.code}`
  const hint = f.hint?.split(':')[0] ?? ''
  if (hint && HINWEIS[hint]) return `fehler.${HINWEIS[hint]}`
  const code = f.code ?? ''
  return SQLSTATE[code] ? `fehler.${SQLSTATE[code]}` : 'fehler.allgemein'
}
