// Eltern-Report — der Themenraum einer Sitzung (W5-d).
//
// Reine Rechnung, keine Datenbank. Lesepfad: src/lib/supabase/
// lsaReportErzaehlung.ts; Entwurfs-Generator: scripts/report/.
//
// ----------------------------------------------------------------------------
// Warum gespeichert statt berechnet
// ----------------------------------------------------------------------------
// #189 rechnete den Themenraum (Einstiegsknoten des Themas + ihr
// Voraussetzungsabschluss) bei jedem Öffnen aus den HEUTIGEN Tabellen
// thema_einstieg und skill_kante. Seit K8–K10 ändern die sich laufend — ein
// Report vom Gesprächstag sähe eine Woche später anders aus. Seit
// 20261004001437 hält lsa_finish den Raum in result_summary.themenraum fest;
// ältere Sitzungen trägt 20261004001517 nach (stand = 'nachgetragen').
//
// Nur wenn das Feld fehlt (oder kaputt ist), wird wie bisher gerechnet.
// Begründung: docs/report/themenraum-entscheidungen.md.

import type { Themenraum } from '@/types'

/** Eine Kante aus skill_kante: `skillKey` setzt `voraussetzt` voraus. */
export type SucheKante = { skillKey: string; voraussetzt: string }

/**
 * Alle Skills, die `start` transitiv voraussetzt — dieselbe Rekursion wie
 * public.lsa_abschluss. Nachgerechnet statt per RPC, weil lsa_abschluss nur
 * für service_role ausführbar ist.
 */
export function abschluss(start: readonly string[], kanten: readonly SucheKante[]): Set<string> {
  const nach = new Map<string, string[]>()
  for (const k of kanten) {
    const liste = nach.get(k.skillKey)
    if (liste) liste.push(k.voraussetzt)
    else nach.set(k.skillKey, [k.voraussetzt])
  }
  const gesehen = new Set<string>()
  const offen = start.flatMap((s) => nach.get(s) ?? [])
  while (offen.length > 0) {
    const sk = offen.pop()!
    if (gesehen.has(sk)) continue
    gesehen.add(sk)
    offen.push(...(nach.get(sk) ?? []))
  }
  return gesehen
}

const sortiert = (xs: Iterable<string>) => [...new Set(xs)].sort()

/**
 * Der Raum aus dem heutigen Stand — dieselbe Definition wie
 * public.lsa_themenraum: darunter ohne die Einstiege selbst.
 */
export function berechneThemenraum(
  themaKey: string,
  einstieg: readonly string[],
  kanten: readonly SucheKante[],
): Themenraum {
  const e = new Set(einstieg)
  return {
    themaKey,
    einstieg: sortiert(e),
    darunter: sortiert([...abschluss([...e], kanten)].filter((sk) => !e.has(sk))),
    herkunft: 'berechnet',
  }
}

const istTextliste = (x: unknown): x is string[] =>
  Array.isArray(x) && x.every((v) => typeof v === 'string')

/**
 * Liest result_summary.themenraum. Null, wenn das Feld fehlt, nicht zur
 * Sitzung passt oder nicht die erwartete Form hat — dann rechnet der Aufrufer.
 */
export function gespeicherterThemenraum(roh: unknown, themaKey: string): Themenraum | null {
  if (roh == null) return null
  const r = roh as Record<string, unknown>
  if (
    typeof roh !== 'object' ||
    r.thema_key !== themaKey ||
    !istTextliste(r.einstieg) ||
    !istTextliste(r.darunter) ||
    typeof r.stand !== 'string'
  ) {
    console.warn('report: stored themenraum ignored (shape/thema mismatch)')
    return null
  }
  return {
    themaKey,
    einstieg: [...r.einstieg],
    darunter: [...r.darunter],
    herkunft: r.stand === 'nachgetragen' ? 'nachgetragen' : 'abschluss',
  }
}

export type ThemenraumQuellen = {
  /** lsa_sessions.thema_key; null bei Sitzungen ohne Thema. */
  themaKey: string | null
  /** result_summary.themenraum, roh. */
  gespeichert: unknown
  /** Heutiger Stand — nur gebraucht, wenn nichts gespeichert ist. */
  einstieg: readonly string[]
  kanten: readonly SucheKante[]
}

/** Der Raum der Sitzung: gespeichert bevorzugt, sonst berechnet. Ohne Thema null. */
export function themenraumFuer(q: ThemenraumQuellen): Themenraum | null {
  if (!q.themaKey) return null
  return (
    gespeicherterThemenraum(q.gespeichert, q.themaKey) ??
    berechneThemenraum(q.themaKey, q.einstieg, q.kanten)
  )
}
