// Eltern-Bericht — Vorgriffe (LSA-V2, Entscheidungen 11–14, Gründer 22.10.2026).
//
// Starke Kinder bekommen in der LSA einen Ausblick auf den Stoff, der als
// Nächstes kommt. Was dort noch nicht sitzt, ist kein Übungsbedarf: Es wurde
// noch nicht unterrichtet. Ein direkt geprüfter Bereich ist ein Vorgriff, wenn
//   - eines seiner Heimat-Themen in „Kommt noch“ liegt (kommtNoch aus
//     lernweg.ts, Klasse oder Klasse + 1),
//   - er nicht im Themenraum liegt
//   - und er kein Randknoten der Vorschau ist (wie lsa_select_next_core, LSA-V).
// Nur aus Plan, Graph und Raum, ohne DB-Feld. Druckbogen und Präsentation
// rechnen beide über baueElternbericht und damit über diese Funktion.

import type { EbBereich, HeimatThema, LwKante } from '@/types'

/** So viele kommende Plan-Themen nimmt die Vorschau (c_vorschau_themen in lsa_select_next_core). */
export const VORSCHAU_THEMEN = 2

export type VorgriffEingabe = {
  /** Direkt geprüfte Bereiche. */
  bereiche: readonly EbBereich[]
  /** Themenraum (Einstieg ∪ darunter); leer ohne Thema. */
  raum: ReadonlySet<string>
  kanten: readonly LwKante[]
  heimatThemen: readonly HeimatThema[]
  /** Thema-Schlüssel in „Kommt noch“ der Klasse, in Plan-Reihenfolge (kommtNoch). */
  kommt: readonly (string | null)[]
  /** Thema-Schlüssel des Plans der Klasse + 1 (LernPlan.naechsteKlasse). */
  naechsteKlasse: readonly (string | null)[]
  /** Thema der Sitzung. */
  themaKey: string | null
}

const gruppiere = <T>(liste: readonly T[], schluessel: (x: T) => string, wert: (x: T) => string) => {
  const m = new Map<string, string[]>()
  for (const x of liste) m.set(schluessel(x), [...(m.get(schluessel(x)) ?? []), wert(x)])
  return m
}

/**
 * Der Rand der Vorschau wie in lsa_select_next_core: Voraussetzungen von
 * Skills der nächsten VORSCHAU_THEMEN Themen, die nicht zum Thema gehören. Gehört
 * eine zu einem Thema, das noch kommt, tritt ihr eigener Rand an ihre Stelle.
 */
export function vorschauRand(e: Omit<VorgriffEingabe, 'bereiche' | 'raum'>): Set<string> {
  const ohneThema = (keys: readonly (string | null)[]) =>
    keys.filter((k): k is string => k !== null && k !== e.themaKey)
  const kommend = ohneThema(e.kommt).slice(0, VORSCHAU_THEMEN)
  const spaeter = new Set([...ohneThema(e.kommt), ...ohneThema(e.naechsteKlasse)])
  const themenVon = gruppiere(e.heimatThemen, (h) => h.skillKey, (h) => h.themaKey)
  const skillsVon = gruppiere(e.heimatThemen, (h) => h.themaKey, (h) => h.skillKey)
  const voraus = gruppiere(e.kanten, (k) => k.skillKey, (k) => k.voraussetzt)
  const in_ = (sk: string, themen: ReadonlySet<string>) => (themenVon.get(sk) ?? []).some((t) => themen.has(t))

  const rand = new Set<string>()
  const gesehen = new Set<string>()
  const offen: string[] = []
  for (const u of kommend) {
    for (const sk of skillsVon.get(u) ?? []) {
      for (const v of voraus.get(sk) ?? []) if (!(themenVon.get(v) ?? []).includes(u)) offen.push(v)
    }
  }
  while (offen.length > 0) {
    const sk = offen.pop()!
    if (gesehen.has(sk)) continue
    gesehen.add(sk)
    if (in_(sk, spaeter)) offen.push(...(voraus.get(sk) ?? []))
    else rand.add(sk)
  }
  return rand
}

/** Schlüssel der direkt geprüften Bereiche, die Vorgriffe sind. */
export function vorgriffe(e: VorgriffEingabe): Set<string> {
  const kommt = new Set([...e.kommt, ...e.naechsteKlasse].filter((k): k is string => k !== null && k !== e.themaKey))
  if (kommt.size === 0) return new Set()
  const themenVon = gruppiere(e.heimatThemen, (h) => h.skillKey, (h) => h.themaKey)
  const rand = vorschauRand(e)
  return new Set(
    e.bereiche
      .filter((b) => (themenVon.get(b.skillKey) ?? []).some((t) => kommt.has(t)))
      .filter((b) => !e.raum.has(b.skillKey) && !rand.has(b.skillKey))
      .map((b) => b.skillKey),
  )
}

/** Die Bereiche, die zählen: alle außer den Vorgriffen, die noch nicht sicher sind (Entscheidung 13). */
export const gezaehlt = (bereiche: readonly EbBereich[], vorgriff: ReadonlySet<string>): EbBereich[] =>
  bereiche.filter((b) => b.sicher || !vorgriff.has(b.skillKey))
