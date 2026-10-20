// Slots W3: reine Logik des Stammplatz-Dialogs (ohne React). Ob ein Termin entsteht, entscheidet der Server
// (stammplatz_vorschau, slots_planbilanz_vorschau); hier wird nur abgebildet, was er liefert.

import { isoWeek } from '@/lib/datetime'
import type { SlotsEinstellungen, StammplatzVorschauZeile, Takt, VorschauErgebnis } from '@/types/slotplan'
import { PLAETZE } from '../wochenplan/wochenplan.model'

function utc(iso: string): Date {
  const [y, m, d] = iso.split('-').map(Number)
  return new Date(Date.UTC(y, m - 1, d))
}

function plusTage(iso: string, tage: number): string {
  const d = utc(iso)
  d.setUTCDate(d.getUTCDate() + tage)
  return d.toISOString().slice(0, 10)
}

/** ISO-Kalenderwoche eines Tages. */
export function kwVon(iso: string): number {
  const [y, m, d] = iso.split('-').map(Number)
  return isoWeek(y, m, d).week
}

/** A-Woche = ungerade ISO-KW (Datenvertrag 10.1). */
export function istAWoche(iso: string): boolean {
  return kwVon(iso) % 2 === 1
}

/** Erster Tag ab `ab` mit diesem Wochentag (1 = Montag), bei A/B-Takt in der passenden Woche: der erste Termin. */
export function ersterTermintag(ab: string, wochentag: number, takt: Takt): string {
  const heuteWt = ((utc(ab).getUTCDay() + 6) % 7) + 1
  let tag = plusTage(ab, (wochentag - heuteWt + 7) % 7)
  if (takt !== 'woechentlich' && istAWoche(tag) !== (takt === 'a_woche')) tag = plusTage(tag, 7)
  return tag
}

/** Aktive Räume bzw. Uhrzeiten an einem Tag (aktiv_ab ≤ Tag < inaktiv_ab). */
export function aktivAm<T extends { aktiv_ab: string; inaktiv_ab: string | null }>(liste: T[], tag: string): T[] {
  return liste.filter((x) => x.aktiv_ab <= tag && (x.inaktiv_ab === null || x.inaktiv_ab > tag))
}

export type StammRaum = SlotsEinstellungen['raeume'][number]

/** Kein Betrieb oder nicht die Woche des Takts: zählt für die Raum-Karte nicht. */
const OHNE_TERMIN: VorschauErgebnis[] = ['ferien', 'feiertag', 'andere_woche']

export type RaumStand = {
  /** Erster Termin im Takt mit Betrieb; null = in den sechs Wochen keiner (dann keine Aussage zum Coach). */
  datum: string | null
  coach_name: string | null
  /** Kinder im Raum ohne dieses Kind. */
  belegt: number
  frei: number
  /**
   * Nicht wählbar (S4 nicht freigegeben: ohne Coach gesperrt). voll = fünf Kinder im Raum; keinPlatz = Server sagt
   * „voll“ mit weniger als fünf (Termin insgesamt voll oder Kind der anderen Art, offene-punkte-w1 Nr. 5).
   */
  sperre: 'voll' | 'keinPlatz' | 'ohne_coach' | null
}

/** Liegt ein Datum in der Woche des Takts? (A-Woche = ungerade KW.) */
export function imTakt(iso: string, takt: Takt): boolean {
  return takt === 'woechentlich' || istAWoche(iso) === (takt === 'a_woche')
}

/**
 * Raum-Karte aus der Vorschau dieses Raums: Stand am ersten Termin im Takt mit Betrieb (Bauauftrag W3, Entscheidung 3).
 * Daten der anderen Woche zählen nicht, auch wenn der Server dort ein anderes Ergebnis meldet.
 */
export function raumStand(zeilen: StammplatzVorschauZeile[], takt: Takt): RaumStand {
  const erste = zeilen.find((z) => !OHNE_TERMIN.includes(z.ergebnis) && imTakt(z.datum, takt))
  if (!erste) return { datum: null, coach_name: null, belegt: 0, frei: PLAETZE, sperre: null }
  const belegt = erste.belegt ?? 0
  const sperre = erste.ergebnis === 'voll' ? (belegt >= PLAETZE ? 'voll' : 'keinPlatz') : erste.ergebnis === 'ohne_coach' ? 'ohne_coach' : null
  return { datum: erste.datum, coach_name: erste.coach_name, belegt, frei: Math.max(0, PLAETZE - belegt), sperre }
}

export type Kennzeichen = 'geplant' | 'entfaellt' | 'keinBetrieb' | 'andereWoche'

/** Bauauftrag W3, Entscheidung 5. */
export function kennzeichen(e: VorschauErgebnis): Kennzeichen {
  if (e === 'termin') return 'geplant'
  if (e === 'ferien' || e === 'feiertag') return 'keinBetrieb'
  if (e === 'andere_woche') return 'andereWoche'
  return 'entfaellt'
}

type T = (k: string, o?: Record<string, unknown>) => string

/** Der Grund einer Vorschau-Zeile als ein Satz (i18n kinder2.grund.*). */
export function vorschauSatz(z: StammplatzVorschauZeile, raum: string, takt: Takt, t: T): string {
  const max = PLAETZE
  const belegt = z.belegt ?? 0
  switch (z.ergebnis) {
    case 'termin':
      return z.coach_name
        ? t('kinder2.grund.termin', { raum, coach: z.coach_name, belegt: belegt + 1, max })
        : t('kinder2.grund.terminOhneName', { raum, belegt: belegt + 1, max })
    case 'ferien':
    case 'feiertag':
      return z.anlass ? t(`kinder2.grund.${z.ergebnis}`, { anlass: z.anlass }) : t('kinder2.grund.keinBetrieb')
    case 'andere_woche':
      return t('kinder2.grund.andereWoche', {
        woche: t(istAWoche(z.datum) ? 'takt.a_woche' : 'takt.b_woche'),
        kw: kwVon(z.datum),
        takt: t(`takt.${takt}`),
      })
    case 'voll':
      return belegt >= max ? t('kinder2.grund.voll', { raum, max }) : t('kinder2.grund.keinPlatz', { raum })
    case 'ohne_coach':
      return t('kinder2.grund.ohneCoach', { raum })
    case 'ohne_budget':
      return t('kinder2.grund.ohneBudget')
  }
}
