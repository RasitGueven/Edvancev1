// Session-Rahmen C1: reine Regeln der Coach-Live-Sicht. Ohne Supabase, ohne
// React; die Seite und die Datenquelle rufen sie, die Tests pruefen sie.

import type { CoachLiveKind, LiveSignal, LiveZiel, LiveZeitpunkt, ZeitleistenSegment } from '@/types/coachLive'
import type { EingriffStufe, SessionFall, SignalArt, StellschraubeWert } from '@/types/sessionLive'

/** Eine Session dauert 60 Minuten (Entscheidung 1). */
export const SESSION_MINUTEN = 60

/** Rang in der Warteschlange (Entscheidung 15): Mastery vor Entscheidung vor haengt vor Hinweis. */
export const SIGNAL_RANG: Record<SignalArt, number> = { kandidat: 0, entscheidung: 1, haengt: 2, hinweis: 3 }

function zahl(einstellungen: Record<string, StellschraubeWert>, schluessel: string, standard: number): number {
  const w = einstellungen[schluessel]
  return typeof w === 'number' && Number.isFinite(w) ? w : standard
}

/**
 * Sortiert offene Signale: nach Art, bei gleicher Art das aelteste zuerst.
 * Mastery-Pruefungen nur so viele, wie `mastery_kandidaten_je_raum` nach den
 * schon entschiedenen noch erlaubt.
 */
export function sortiereWarteschlange(
  signale: LiveSignal[],
  grenze: { masteryJeRaum: number; masteryEntschieden: number },
): LiveSignal[] {
  const sortiert = [...signale].sort(
    (a, b) => SIGNAL_RANG[a.art] - SIGNAL_RANG[b.art] || Date.parse(a.seit) - Date.parse(b.seit),
  )
  let frei = Math.max(0, grenze.masteryJeRaum - grenze.masteryEntschieden)
  return sortiert.filter((s) => {
    if (s.art !== 'kandidat') return true
    if (frei === 0) return false
    frei -= 1
    return true
  })
}

/** Phasen aus dem Stellschrauben-Snapshot; die Kernarbeit ist der Rest der 60 Minuten. */
export function zeitleisteAusSnapshot(
  einstellungen: Record<string, StellschraubeWert>,
  dauer = SESSION_MINUTEN,
): ZeitleistenSegment[] {
  const checkin = zahl(einstellungen, 'phase_checkin_min', 5)
  const warmup = zahl(einstellungen, 'phase_warmup_min', 10)
  const checkout = zahl(einstellungen, 'phase_checkout_min', 5)
  return [
    { phase: 'checkin', minuten: checkin },
    { phase: 'warmup', minuten: warmup },
    { phase: 'kern', minuten: Math.max(0, dauer - checkin - warmup - checkout) },
    { phase: 'checkout', minuten: checkout },
  ]
}

/** Minute im Ablauf (negativ vor Beginn, ueber 60 danach). */
export function minuteImAblauf(beginn: string, jetzt: string): number {
  return Math.floor((Date.parse(jetzt) - Date.parse(beginn)) / 60_000)
}

/** Segment-Zustand fuer die Zeitleiste. */
export function segmentZustand(
  zeitleiste: ZeitleistenSegment[],
  index: number,
  minute: number,
): 'vorbei' | 'jetzt' | 'kommt' {
  const start = zeitleiste.slice(0, index).reduce((s, z) => s + z.minuten, 0)
  const ende = start + zeitleiste[index].minuten
  if (minute >= ende) return 'vorbei'
  return minute >= start ? 'jetzt' : 'kommt'
}

/** Fall, der gilt: die Wahl des Coaches vor dem Vorschlag des Systems (Entscheidung 3). */
export function geltenderFall(ziel: LiveZiel): SessionFall | null {
  return ziel.fallCoach ?? ziel.fallVorschlag
}

/** i18n-Schluessel und Werte des Stundenziel-Satzes (Dummy: zielText). */
export function zielSatz(ziel: LiveZiel): { key: string; werte: Record<string, string> } {
  const fall = geltenderFall(ziel)
  if (fall === 'klassenarbeit') {
    const thema = ziel.klassenarbeit?.themaLabel ?? (ziel.klassenarbeit ? ziel.themaLabel : null)
    return thema ? { key: 'ziel.klassenarbeit', werte: { thema } } : { key: 'ziel.klassenarbeitFehlt', werte: {} }
  }
  if (fall === 'schulthema') {
    return ziel.themaLabel ? { key: 'ziel.schulthema', werte: { thema: ziel.themaLabel } } : { key: 'ziel.schulthemaFehlt', werte: {} }
  }
  if (fall === 'lernpfad') {
    return ziel.lsaLuecke ? { key: 'ziel.lernpfadLsa', werte: { luecke: ziel.lsaLuecke } } : { key: 'ziel.lernpfad', werte: {} }
  }
  return { key: 'ziel.offen', werte: {} }
}

/** Ab Stufe 3 ist das Fehlbild Pflicht (Entscheidung 14, R1: 22023). */
export function eingriffAbsendbar(stufe: EingriffStufe, fehlbildSlug: string | null): boolean {
  return stufe < 3 || (fehlbildSlug !== null && fehlbildSlug.trim() !== '')
}

/** Vertagen braucht einen Grund (Entscheidung 16). */
export function vertagenAbsendbar(grund: string | null): boolean {
  return grund !== null && grund.trim() !== ''
}

/** Kinder ohne Tablet: vor dem Abschluss bestaetigt der Coach „nicht erschienen“. */
export function kinderOhneTablet(kinder: CoachLiveKind[]): CoachLiveKind[] {
  return kinder.filter((k) => k.tablet === null)
}

export function abschlussMoeglich(kinder: CoachLiveKind[]): boolean {
  return kinderOhneTablet(kinder).every((k) => k.nichtErschienen)
}

/** Schulthema aelter als `thema_alt_tage`: im Briefing zum Nachfragen markieren. */
export function themaAltWochen(seit: string | null, jetzt: string, altTage: number): number | null {
  if (seit === null) return null
  const tage = Math.floor((Date.parse(jetzt) - Date.parse(seit)) / 86_400_000)
  return tage > altTage ? Math.floor(tage / 7) : null
}

/** Ganze Tage bis zu einem Datum (YYYY-MM-DD) ab dem Tag von `jetzt`. */
export function tageBis(datum: string, jetzt: string): number {
  const [y, m, d] = datum.split('-').map(Number)
  const heute = new Date(jetzt)
  const a = Date.UTC(heute.getUTCFullYear(), heute.getUTCMonth(), heute.getUTCDate())
  return Math.round((Date.UTC(y, m - 1, d) - a) / 86_400_000)
}

/** Reihenfolge der Zeitpunkte (Beispielleiste, Schublade nur in Warm-up und Kernarbeit). */
export const ZEITPUNKTE: LiveZeitpunkt[] = ['vorher', 'checkin', 'warmup', 'kern', 'checkout', 'danach']

export function istArbeitsphase(z: LiveZeitpunkt): z is 'warmup' | 'kern' {
  return z === 'warmup' || z === 'kern'
}

/** Kennzahlen „Geht in die Akten“. */
export function akteZahlen(kinder: CoachLiveKind[]): {
  anwesend: number
  gesamt: number
  einheitVerbraucht: number
  aufgaben: number
  eingriffeAb3: number
  masteryBestaetigt: number
  masteryVertagt: number
  satzGesagt: number
  notizen: number
  questTermine: number
} {
  const anwesend = kinder.filter((k) => k.tablet !== null).length
  const m = kinder.map((k) => k.masteryKandidat?.entscheidung?.art ?? null)
  return {
    anwesend,
    gesamt: kinder.length,
    // Anwesend oder bestaetigt nicht erschienen: beides verbraucht die Einheit (R1 Punkt 6).
    einheitVerbraucht: anwesend + kinder.filter((k) => k.tablet === null && k.nichtErschienen).length,
    aufgaben: kinder.reduce((s, k) => s + (k.tablet !== null ? k.checkout.aufgaben : 0), 0),
    eingriffeAb3: kinder.reduce((s, k) => s + k.eingreifen.eingriffe.filter((e) => e.stufe >= 3).length, 0),
    masteryBestaetigt: m.filter((x) => x === 'gemeistert').length,
    masteryVertagt: m.filter((x) => x === 'vertagt').length,
    satzGesagt: kinder.filter((k) => k.checkout.gesagt).length,
    notizen: kinder.filter((k) => k.checkout.notiz.trim() !== '').length,
    questTermine: kinder.filter((k) => k.checkout.questA.termin !== null).length,
  }
}
