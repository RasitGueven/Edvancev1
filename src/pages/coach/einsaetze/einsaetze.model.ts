// Coach „Meine Einsätze“ und „Heute“ (Bauauftrag Slots, SL3). Reine Logik ohne Aufrufe: gruppieren,
// zusammenführen mit festgeschriebenen Sessions, nächster Termin. Der Coach sieht nie Absagen,
// Umbuchungen, Stammplätze, Planbilanz, Paket oder Vertrag (Anforderung I 54): Das Modell übernimmt
// deshalb nur die Felder, die die Karte braucht, auch wenn der Server einmal mehr liefern sollte.

import { naechsteSession } from '@/lib/coachKennzahlen'
import { berlinLocalToIso } from '@/lib/datetime'
import type { CoachingSession } from '@/types'
import type { KindKurz, MeinEinsatz } from '@/types/slotplan'

export type EinsatzKind = Pick<KindKurz, 'student_id' | 'name' | 'klasse' | 'fach'>

export type EinsatzVM = {
  /** Schlüssel datum|zeit|raum, eindeutig je Einsatz. */
  key: string
  datum: string
  zeit_id: string
  raum_id: string
  beginn: string
  ende: string
  raum_name: string
  heute: boolean
  session_id: string | null
  kinder: EinsatzKind[]
}

export type EinsatzTag = { datum: string; heute: boolean; einsaetze: EinsatzVM[] }

/** Nur die erlaubten Felder (I 54); Kinder nach Namen. */
export function einsatzVM(e: MeinEinsatz): EinsatzVM {
  return {
    key: `${e.datum}|${e.zeit_id}|${e.raum_id}`,
    datum: e.datum,
    zeit_id: e.zeit_id,
    raum_id: e.raum_id,
    beginn: e.beginn,
    ende: e.ende,
    raum_name: e.raum_name,
    heute: e.heute,
    session_id: e.session_id,
    kinder: (e.kinder ?? [])
      .map((k) => ({ student_id: k.student_id, name: k.name, klasse: k.klasse, fach: k.fach }))
      .sort((a, b) => (a.name ?? '').localeCompare(b.name ?? '', 'de')),
  }
}

/** Einsätze nach Tagen, Tage und Einsätze aufsteigend. */
export function nachTagen(einsaetze: MeinEinsatz[]): EinsatzTag[] {
  const tage = new Map<string, EinsatzTag>()
  const sortiert = [...einsaetze].sort((a, b) => `${a.datum} ${a.beginn} ${a.raum_name}`.localeCompare(`${b.datum} ${b.beginn} ${b.raum_name}`))
  for (const e of sortiert) {
    const tag = tage.get(e.datum) ?? { datum: e.datum, heute: false, einsaetze: [] }
    tag.heute = tag.heute || e.heute
    tag.einsaetze.push(einsatzVM(e))
    tage.set(e.datum, tag)
  }
  return [...tage.values()]
}

/** Zahl der verschiedenen Kinder der Woche (Seitenkopf „12 Kinder“). */
export function kinderZahl(einsaetze: MeinEinsatz[]): number {
  return new Set(einsaetze.flatMap((e) => (e.kinder ?? []).map((k) => k.student_id))).size
}

/** Beginn eines Einsatzes als Zeitpunkt (Datum und Uhrzeit sind Berliner Ortszeit). */
export function einsatzBeginnIso(e: Pick<MeinEinsatz, 'datum' | 'beginn'>): string {
  return berlinLocalToIso(e.datum, e.beginn)
}

export type HeuteEintrag =
  | { art: 'plan'; key: string; sortier: number; einsatz: EinsatzVM }
  | { art: 'session'; key: string; sortier: number; session: CoachingSession }

/**
 * „Heute“ beim Coach: die Einsätze von heute aus dem Plan und die festgeschriebenen bzw. Einzel-Sessions
 * von heute. Eine Session-ID erscheint nur einmal: Ist ein Einsatz schon festgeschrieben und die Session
 * in der Liste, steht nur die Session da (mit Start und Live-Sicht).
 */
export function heuteEintraege(einsaetze: MeinEinsatz[], sessionsHeute: CoachingSession[]): HeuteEintrag[] {
  const sessionIds = new Set(sessionsHeute.map((s) => s.id))
  const plan: HeuteEintrag[] = einsaetze
    .filter((e) => e.heute && !(e.session_id && sessionIds.has(e.session_id)))
    .map((e) => ({ art: 'plan', key: `p-${e.datum}|${e.zeit_id}|${e.raum_id}`, sortier: Date.parse(einsatzBeginnIso(e)), einsatz: einsatzVM(e) }))
  const sessions: HeuteEintrag[] = sessionsHeute.map((s) => ({
    art: 'session',
    key: `s-${s.id}`,
    sortier: Date.parse(s.scheduled_at),
    session: s,
  }))
  return [...plan, ...sessions].sort((a, b) => a.sortier - b.sortier)
}

/**
 * Nächster Termin ab jetzt für die Kennzahl „nächste Session“: der früheste aus offenen Sessions und
 * Einsätzen, auch wenn der Einsatz noch nicht festgeschrieben ist (Entscheidung 14).
 */
export function naechsterBeginn(einsaetze: MeinEinsatz[], sessions: CoachingSession[], nowMs: number): string | null {
  const session = naechsteSession(sessions, nowMs)?.scheduled_at
  const kandidaten = [...(session ? [session] : []), ...einsaetze.map(einsatzBeginnIso).filter((iso) => Date.parse(iso) >= nowMs)]
  return kandidaten.sort((a, b) => Date.parse(a) - Date.parse(b))[0] ?? null
}
