// Slots W2: reine Logik des Wochenplans und seiner Panels (ohne React). Was der Server entscheidet
// (Kapazität, Coach, Buchbarkeit), wird hier nicht nachgerechnet, nur dargestellt.

import type { SlotsWoche, SlotZeit, TagRaumTermin, TagSessionOhneRaum, WocheZelle, ZelleRaum } from '@/types/slotplan'
import type { StundenplanSession } from '@/types/stundenplan'
import { berlinLocalParts } from '@/lib/datetime'

/** Plätze je Raum (Kleingruppe). */
export const PLAETZE = 5

// ── Farbe je Raum (Bauauftrag W, Entscheidung 4) ──────────────────────────────

/**
 * leer = 0 Kinder (grau), rot = 1–2 („schwach belegt“, kein Fehler), gelb = 3, gruen = 4–5,
 * keinCoach = Kinder im Raum, aber kein Coach (rot gefüllt mit „kein Coach“).
 */
export type RaumFarbe = 'leer' | 'rot' | 'gelb' | 'gruen' | 'keinCoach'

export function raumFarbe(belegt: number, mitCoach: boolean): RaumFarbe {
  if (belegt > 0 && !mitCoach) return 'keinCoach'
  if (belegt <= 0) return 'leer'
  if (belegt <= 2) return 'rot'
  if (belegt === 3) return 'gelb'
  return 'gruen'
}

/** Räume einer Zelle, die im Raster stehen: mit Coach oder mit Kindern. Geschlossen und leer fällt weg. */
export function zellRaeume(z: WocheZelle): ZelleRaum[] {
  return z.raeume.filter((r) => r.offen || r.belegt > 0)
}

/** Freie Plätze in Räumen mit Coach. */
export function freiePlaetze(raeume: { offen: boolean; belegt: number }[]): number {
  return raeume.filter((r) => r.offen).reduce((s, r) => s + Math.max(0, PLAETZE - r.belegt), 0)
}

// ── Kennzahlen (Entscheidung 2 und 7) ────────────────────────────────────────

export type WochenKennzahlen = {
  plaetze: number
  /** Belegt mit Testkonten; echt und test getrennt für „x Kinder · y Testkonten“. */
  belegt: number
  echt: number
  test: number
  /** Anteil 0–1 mit Testkonten, ohne Testkonten; null ohne Plätze. */
  auslastung: number | null
  auslastungOhneTest: number | null
  raeumeOhneCoach: number
  /** Ohne Stammplatz: echte Kinder, dazu Testkonten. handeln = ein Vertrag läuft schon. */
  ohneStammplatz: number
  ohneStammplatzTest: number
  ohneStammplatzHandeln: boolean
}

export function wochenKennzahlen(kopf: SlotsWoche['kopf']): WochenKennzahlen {
  return {
    plaetze: kopf.plaetze,
    belegt: kopf.belegt + kopf.belegt_test,
    echt: kopf.belegt,
    test: kopf.belegt_test,
    auslastung: kopf.auslastung_mit_test,
    auslastungOhneTest: kopf.auslastung,
    raeumeOhneCoach: kopf.raeume_ohne_coach,
    ohneStammplatz: kopf.ohne_stammplatz,
    ohneStammplatzTest: kopf.ohne_stammplatz_test,
    ohneStammplatzHandeln: kopf.ohne_stammplatz_laufend > 0,
  }
}

// ── Panel in der URL (?slot=, ?tag=, ?einzel=) ───────────────────────────────

export type Panel =
  | { art: 'slot'; datum: string; zeitId: string }
  | { art: 'tag'; datum: string }
  | { art: 'einzel'; datum: string; sessionId: string }

const PANEL_PARAMETER = ['slot', 'tag', 'einzel'] as const
const ISO_TAG = /^\d{4}-\d{2}-\d{2}$/

function teilen(wert: string): [string, string] | null {
  const i = wert.indexOf('_')
  if (i < 0) return null
  const [datum, rest] = [wert.slice(0, i), wert.slice(i + 1)]
  return ISO_TAG.test(datum) && rest ? [datum, rest] : null
}

export function panelAusSuche(suche: URLSearchParams): Panel | null {
  const slot = suche.get('slot')
  if (slot) {
    const t = teilen(slot)
    if (t) return { art: 'slot', datum: t[0], zeitId: t[1] }
  }
  const tag = suche.get('tag')
  if (tag && ISO_TAG.test(tag)) return { art: 'tag', datum: tag }
  const einzel = suche.get('einzel')
  if (einzel) {
    const t = teilen(einzel)
    if (t) return { art: 'einzel', datum: t[0], sessionId: t[1] }
  }
  return null
}

/** Suchparameter mit genau diesem Panel (oder ohne Panel); Reiter und Woche bleiben. */
export function sucheMitPanel(suche: URLSearchParams, panel: Panel | null): URLSearchParams {
  const neu = new URLSearchParams(suche)
  for (const p of PANEL_PARAMETER) neu.delete(p)
  if (panel?.art === 'slot') neu.set('slot', `${panel.datum}_${panel.zeitId}`)
  if (panel?.art === 'tag') neu.set('tag', panel.datum)
  if (panel?.art === 'einzel') neu.set('einzel', `${panel.datum}_${panel.sessionId}`)
  return neu
}

/** Ziel der alten Termin-Adresse /admin/slots/termin/:datum/:zeitId. */
export function slotZiel(datum: string, zeitId: string): string {
  return `/admin/slots?${sucheMitPanel(new URLSearchParams(), { art: 'slot', datum, zeitId }).toString()}`
}

/**
 * Entscheidung 1: Den Reiter Stundenplan gibt es nicht mehr. ?reiter=stundenplan (und /admin/schedule) landen im
 * Wochenplan; alles andere, auch die Woche, bleibt.
 */
export function sucheOhneStundenplan(suche: URLSearchParams): URLSearchParams {
  const neu = new URLSearchParams(suche)
  if (neu.get('reiter') === 'stundenplan') neu.delete('reiter')
  return neu
}

/** ISO-Wochentag (Montag = 1) eines ISO-Tags. */
export function isoWochentag(datum: string): number {
  const [y, m, d] = datum.split('-').map(Number)
  return new Date(Date.UTC(y, m - 1, d)).getUTCDay() || 7
}

// ── Einzel-Sessions (Zeile „Einzel“, Tagespanel) ─────────────────────────────

/** Einzel- und Sofort-Sessions eines Berliner Tags, nach Beginn. */
export function einzelAmTag(sessions: StundenplanSession[], datum: string): StundenplanSession[] {
  return sessions
    .filter((s) => berlinLocalParts(s.scheduled_at).date === datum)
    .sort((a, b) => a.scheduled_at.localeCompare(b.scheduled_at))
}

export type TagZeile =
  | { art: 'slot'; zeit: SlotZeit; raeume: TagRaumTermin[]; frei: number }
  | { art: 'einzel'; uhr: string; s: TagSessionOhneRaum }

/**
 * Tagespanel (Entscheidung 5): je Uhrzeit die Räume mit Coach oder Kindern und die freien Plätze; Einzel-Sessions
 * an ihrer Uhrzeit dazwischen (vor dem ersten Slot, der danach beginnt).
 */
export function tagZeilen(zeiten: SlotZeit[], raumTermine: TagRaumTermin[], einzel: TagSessionOhneRaum[]): TagZeile[] {
  const slots: TagZeile[] = [...zeiten]
    .sort((a, b) => a.beginn.localeCompare(b.beginn))
    .map((zeit) => {
      const raeume = raumTermine
        .filter((r) => r.zeit_id === zeit.id && (r.offen || r.belegt > 0))
        .sort((a, b) => a.raum_name.localeCompare(b.raum_name, 'de'))
      return { art: 'slot', zeit, raeume, frei: freiePlaetze(raeume) }
    })
  const einzelZeilen: TagZeile[] = [...einzel]
    .map((s) => ({ art: 'einzel' as const, uhr: berlinLocalParts(s.scheduled_at).time, s }))
    .sort((a, b) => a.uhr.localeCompare(b.uhr))
  const sortier = (z: TagZeile): string => (z.art === 'slot' ? `${z.zeit.beginn}|1` : `${z.uhr}|0`)
  return [...slots, ...einzelZeilen].sort((a, b) => sortier(a).localeCompare(sortier(b)))
}
