// Spiegel von prozent_gate_fehler (Migration 20261021081417): die zwei Prozent-Regeln des Freigabe-Gates.
// Seit #294 zaehlt „%“ in lsa_grade als Faktor 1/100; Ausnahme ist acceptance.unit = '%' (die Antwort ist
// selbst ein Prozentsatz). Beide Regeln gelten nur fuer eine flache Wertungsregel (acceptance mit canonical).
// Reine Funktionen, kein Supabase — getestet in flags.test.ts.

import type { AcceptanceRule, AcceptanceSet } from '@/types/authoring'

export type ProzentBefund = 'prozentOhneMarker' | 'prozentzahlOhneZeichen'

/** Zahl und Einheit wie lsa_split_value_unit: "3/5", "0,6", "1 1/2", "+60 %", "−2". */
export function zahlUndEinheit(roh: string): { wert: number; einheit: string } | null {
  const s = roh.trim().toLowerCase().replace(/[−–—]/g, '-').replace(/,/g, '.')
    .replace(/^\+ ?(?=\d)/, '').replace(/^- (?=\d)/, '-')
  const m = s.match(/^(-?)(\d+)(?:\s+(\d+)\/(\d+)|\/(\d+)|\.(\d+))?\s*(.*)$/)
  if (!m) return null
  const [, vz, ganz, gz, gn, n, dez] = m
  let wert: number
  if (gz !== undefined) wert = Number(ganz) + Number(gz) / Number(gn)
  else if (n !== undefined) wert = Number(ganz) / Number(n)
  else if (dez !== undefined) wert = Number(`${ganz}.${dez}`)
  else wert = Number(ganz)
  if (!Number.isFinite(wert)) return null
  return { wert: vz ? -wert : wert, einheit: m[7].trim() }
}

const istProzent = (einheit: string): boolean => einheit === '%' || einheit === 'prozent'
const gleich = (a: number, b: number): boolean => Math.abs(a - b) <= 1e-9 * Math.max(1, Math.abs(a), Math.abs(b))

function flacheRegel(acc: AcceptanceSet | null | undefined): AcceptanceRule | null {
  return acc && typeof (acc as AcceptanceRule).canonical === 'string' ? (acc as AcceptanceRule) : null
}

/** Der Befund wie im Gate (erste Regel zuerst), oder null. */
export function prozentBefund(
  unit: string | null,
  acceptance: AcceptanceSet | null | undefined,
  antworten: string[],
): ProzentBefund | null {
  const regel = flacheRegel(acceptance)
  if (!regel || regel.unit === '%') return null
  if (unit?.trim() === '%') return 'prozentOhneMarker'
  const c = zahlUndEinheit(regel.canonical)
  if (!c || c.wert === 0 || !(c.einheit === '' || istProzent(c.einheit))) return null
  const ziel = 100 * (istProzent(c.einheit) ? c.wert / 100 : c.wert)
  const treffer = [...antworten, ...(regel.equivalents ?? [])].some((x) => {
    const z = zahlUndEinheit(x)
    return z !== null && z.einheit === '' && gleich(z.wert, ziel)
  })
  return treffer ? 'prozentzahlOhneZeichen' : null
}
