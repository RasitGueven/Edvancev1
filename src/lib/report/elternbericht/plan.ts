// Eltern-Bericht R7-9 — was im Schuljahr noch kommt: Schule des Kindes, Plan
// der Klasse und die aktuelle Position darin (Entscheidungen 2, 3 und 9).
//
// Reine Funktionen: Der Lesepfad (src/lib/supabase/lsaReportPlan.ts) und die
// Fixtures bauen den Plan mit denselben Funktionen.

import type { LernPlan, PlanEintrag, Stufe } from '@/types'

/** Eine Zeile aus schul_themenplan (Fach Mathematik), schon umbenannt. */
export type SchulplanZeile = {
  klasse: number
  position: number
  themaKey: string | null
  titel: string
  halbjahr: 1 | 2 | null
}

/** Ein Thema des Kernlehrplans (themen). */
export type KlpThema = {
  themaKey: string
  klasse: number
  label: string
  stufe: Stufe
  sort: number | null
}

/** Woher die Schule des Kindes kommt (Entscheidung 2). */
export type Schulweg = 'schueler' | 'lead' | 'name'

export type SchulQuellen = {
  /** students.schule_id */
  schuelerSchule: string | null
  /** leads.schule_id über students.lead_id; null ohne Lead oder ohne Leserecht. */
  leadSchule: string | null
  /** students.school_name */
  schulname: string | null
  /** schulen (id, name); leer ohne Leserecht. */
  schulen: readonly { id: string; name: string }[]
}

/**
 * Die Schule des Kindes, in dieser Reihenfolge: students.schule_id, dann
 * leads.schule_id über students.lead_id, dann schulen.name gleich
 * students.school_name (ohne Groß/Klein, genau ein Treffer). null, wenn keiner
 * der drei Wege eine Schule liefert.
 */
export function findeSchule(q: SchulQuellen): { id: string; weg: Schulweg } | null {
  if (q.schuelerSchule) return { id: q.schuelerSchule, weg: 'schueler' }
  if (q.leadSchule) return { id: q.leadSchule, weg: 'lead' }
  const name = q.schulname?.trim().toLocaleLowerCase('de')
  if (!name) return null
  const treffer = q.schulen.filter((s) => s.name.trim().toLocaleLowerCase('de') === name)
  return treffer.length === 1 ? { id: treffer[0].id, weg: 'name' } : null
}

/** KLP-Stufe einer Klasse: 5/6 Erprobung, 7/8 erste, ab 9 zweite. */
export function stufeVon(klasse: number): Stufe {
  if (klasse <= 6) return 'erprobung'
  return klasse <= 8 ? 'erste' : 'zweite'
}

const nachPosition = (a: SchulplanZeile, b: SchulplanZeile): number => a.position - b.position

/**
 * Der Schulplan für die Klasse der Sitzung; null, wenn die Schule für diese
 * Klasse keinen Plan hat. naechsteKlasse nur, wenn es für Klasse + 1 einen gibt.
 */
export function schulPlan(
  zeilen: readonly SchulplanZeile[],
  klasse: number,
  schulname: string | null,
): LernPlan | null {
  const eintraege = zeilen.filter((z) => z.klasse === klasse).sort(nachPosition)
  if (eintraege.length === 0) return null
  const naechste = zeilen.filter((z) => z.klasse === klasse + 1).sort(nachPosition)
  return {
    quelle: 'schule',
    schulname,
    klasse,
    eintraege: eintraege.map(({ position, themaKey, titel, halbjahr }) => ({ position, themaKey, titel, halbjahr })),
    naechsteKlasse:
      naechste.length > 0
        ? {
            klasse: klasse + 1,
            eintraege: naechste.map(({ position, themaKey, titel }) => ({ position, themaKey, titel })),
          }
        : null,
  }
}

/**
 * Der Kernlehrplan NRW: die Themen der Stufe nach sort (themen.klasse ist die
 * erste Klasse der Stufe, nicht die des Themas). Kein Halbjahr, keine nächste
 * Klasse.
 */
export function klpPlan(themen: readonly KlpThema[], klasse: number): LernPlan {
  const stufe = stufeVon(klasse)
  const eintraege: PlanEintrag[] = themen
    .filter((t) => t.stufe === stufe)
    .sort((a, b) => (a.sort ?? Infinity) - (b.sort ?? Infinity) || a.themaKey.localeCompare(b.themaKey))
    .map((t, i) => ({ position: i + 1, themaKey: t.themaKey, titel: t.label, halbjahr: null }))
  return { quelle: 'klp', schulname: null, klasse, eintraege, naechsteKlasse: null }
}

/** Schulplan, wenn die Schule einen für die Klasse hat; sonst Kernlehrplan. */
export function planFuer({
  schulZeilen,
  schulname,
  themen,
  klasse,
}: {
  schulZeilen: readonly SchulplanZeile[] | null
  schulname: string | null
  themen: readonly KlpThema[]
  klasse: number
}): LernPlan {
  return (schulZeilen && schulPlan(schulZeilen, klasse, schulname)) ?? klpPlan(themen, klasse)
}

/** Monat (1–12) eines Zeitpunkts in Europe/Berlin. */
export function monatBerlin(datum: string): number {
  return Number(new Intl.DateTimeFormat('en', { month: 'numeric', timeZone: 'Europe/Berlin' }).format(new Date(datum)))
}

/** August–Januar erstes Halbjahr, Februar–Juli zweites. */
export const halbjahrVon = (monat: number): 1 | 2 => (monat >= 2 && monat <= 7 ? 2 : 1)

/**
 * Index des Eintrags, auf dem das Kind gerade steht (Entscheidung 9): das
 * Thema der Sitzung; sonst der erste Eintrag des Halbjahrs der Sitzung; hat der
 * Plan kein Halbjahr (oder fehlt das Datum), der Anfang (−1: alles kommt noch).
 */
export function aktuellePosition(
  eintraege: readonly PlanEintrag[],
  themaKey: string | null,
  datum: string | null,
): number {
  if (themaKey) {
    const i = eintraege.findIndex((e) => e.themaKey === themaKey)
    if (i >= 0) return i
  }
  if (!datum) return -1
  const hj = halbjahrVon(monatBerlin(datum))
  return eintraege.findIndex((e) => e.halbjahr === hj)
}
