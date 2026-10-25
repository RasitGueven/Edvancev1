// Eltern-Bericht v4 — der Fahrplan der Klassenarbeiten (Bauauftrag V4,
// Entscheidungen 1–3). Reine Rechnung für Seite 1, die Leiste der Seiten 2–5 und
// die Präsentation.
//
// Erste Station = das aktuelle Thema (Plan-Eintrag an der aktuellen Position,
// dieselbe Quelle wie kommtNoch). Danach die kommenden Themen dieses Schuljahrs,
// jedes Thema einmal, höchstens vier; gibt es weniger, wird aus dem Plan der
// nächsten Klasse aufgefüllt (Trenner „Klasse k“). Signal je kommender Station:
// fehlt (ein Bereich mit Übungsbedarf betrifft das Thema), erfuellt (nur sichere),
// ohne (keiner). Ohne Plan oder ohne aktuelles Thema: null — die Seiten fallen
// dann auf v3 zurück.

import { kommtNoch } from '@/lib/report/elternbericht/lernweg'
import { aktuellePosition } from '@/lib/report/elternbericht/plan'
import type {
  EbBereich,
  EbFahrplan,
  EbFahrtStand,
  EbSignal,
  EbStation,
  KlassenarbeitStatus,
  LernPlan,
} from '@/types'

/** Höchstens so viele kommende Stationen. */
export const KOMMENDE_MAX = 4

export type FahrplanEingabe = {
  plan: LernPlan | null
  /** Thema der Sitzung (lsa_sessions.thema_key); null ohne Thema. */
  themaKey: string | null
  /** Datum der Sitzung, für die Position ohne Thema. */
  datum: string | null
  klassenarbeitStatus: KlassenarbeitStatus | null
  /** signaleJeThema(...) aus lueckenweg.ts. */
  signale: ReadonlyMap<string, { sitzt: readonly EbBereich[]; fehlt: readonly EbBereich[] }>
  /** leads.letzte_klassenarbeit_note; nur bei 'geschrieben' gezeigt. */
  note?: number | null
}

export function signalVon(
  signale: FahrplanEingabe['signale'],
  themaKey: string,
): EbSignal {
  const s = signale.get(themaKey)
  if (s && s.fehlt.length > 0) return 'fehlt'
  return s && s.sitzt.length > 0 ? 'erfuellt' : 'ohne'
}

export function baueFahrplan(e: FahrplanEingabe): EbFahrplan | null {
  const plan = e.plan
  if (!plan) return null
  const pos = aktuellePosition(plan.eintraege, e.themaKey, e.datum)
  const aktuell = pos >= 0 ? plan.eintraege[pos] : null
  if (!aktuell?.themaKey) return null

  const status = e.klassenarbeitStatus
  const erste: EbStation = {
    nummer: 1,
    themaKey: aktuell.themaKey,
    titel: aktuell.titel,
    halbjahr: aktuell.halbjahr,
    schuljahr: 'dieses',
    stand: status === 'geschrieben' ? 'geschrieben' : status === 'bevorstehend' ? 'naechste' : 'aktuell',
    signal: null,
    note: status === 'geschrieben' ? (e.note ?? null) : null,
  }

  // Kommende Themen dieses Schuljahrs, jedes einmal und nicht das aktuelle.
  const gesehen = new Set([aktuell.themaKey])
  const dieses: { themaKey: string; titel: string; halbjahr: 1 | 2 | null }[] = []
  for (const p of kommtNoch({ plan, themaKey: e.themaKey, datum: e.datum })) {
    if (!p.themaKey || gesehen.has(p.themaKey)) continue
    gesehen.add(p.themaKey)
    dieses.push({ themaKey: p.themaKey, titel: p.titel, halbjahr: p.halbjahr })
  }
  const gezeigt = dieses.slice(0, KOMMENDE_MAX)

  // Auffüllen aus dem Plan der nächsten Klasse, bis es vier sind.
  const naechstes: typeof gezeigt = []
  for (const p of plan.naechsteKlasse?.eintraege ?? []) {
    if (gezeigt.length + naechstes.length >= KOMMENDE_MAX) break
    if (!p.themaKey || gesehen.has(p.themaKey)) continue
    gesehen.add(p.themaKey)
    naechstes.push({ themaKey: p.themaKey, titel: p.titel, halbjahr: null })
  }

  // Die erste kommende heißt „nächste Arbeit“, außer die aktuelle steht schon an.
  const kommende: EbStation[] = [
    ...gezeigt.map((p) => ({ ...p, schuljahr: 'dieses' as const })),
    ...naechstes.map((p) => ({ ...p, schuljahr: 'naechstes' as const })),
  ].map((p, i) => {
    const stand: EbFahrtStand = i === 0 && status !== 'bevorstehend' ? 'naechste' : 'voraussichtlich'
    return { ...p, nummer: i + 2, stand, signal: signalVon(e.signale, p.themaKey), note: null }
  })

  const stationen = [erste, ...kommende]
  const halbjahre = new Set(stationen.filter((s) => s.schuljahr === 'dieses').map((s) => s.halbjahr))
  const signale = kommende.map((s) => s.signal)
  return {
    stationen,
    weitere: Math.max(0, dieses.length - KOMMENDE_MAX),
    halbjahrTrenner: halbjahre.has(1) && halbjahre.has(2),
    klassenTrenner: naechstes.length > 0 ? (plan.naechsteKlasse?.klasse ?? null) : null,
    quelle: plan.quelle,
    schulname: plan.schulname,
    satz: signale.includes('fehlt') ? 'fehlt' : signale.includes('erfuellt') ? 'erfuellt' : null,
  }
}
